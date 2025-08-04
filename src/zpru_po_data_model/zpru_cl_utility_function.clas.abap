CLASS zpru_cl_utility_function DEFINITION
  PUBLIC FINAL
  CREATE PUBLIC.

  PUBLIC SECTION.
    CLASS-METHODS get_preferred_ship_method
      IMPORTING iv_supplier_id      TYPE char10
      RETURNING VALUE(rv_ship_meth) TYPE char20.

    CLASS-METHODS fetch_history
      IMPORTING is_instance       TYPE zpru_if_m_po=>ts_order_read_res
      RETURNING VALUE(rs_history) TYPE zpru_if_m_po=>ts_getstatushistory_res.

    CLASS-METHODS get_major_supplier
      RETURNING VALUE(rs_major_supplier) TYPE zpru_if_m_po=>ts_approved_suppliers.

    CLASS-METHODS send_stat_to_azure
      IMPORTING
        iv_serverName   TYPE  char40
        iv_serverAdress TYPE  char11
        iv_statistic    TYPE i
      RETURNING
        VALUE(rv_error) TYPE boole_d.

    CLASS-METHODS get_inventory_status
      IMPORTING
        iv_product_id              TYPE char10
      RETURNING
        VALUE(rs_inventory_status) TYPE Zpru_D_InventoryStatus.

    CLASS-METHODS get_last_po_number
      RETURNING
        VALUE(rv_po_number) TYPE i.

    CLASS-METHODS get_supplier_name
      IMPORTING iv_supplier_id          TYPE char10
      RETURNING VALUE(rv_supplier_name) TYPE char50.

    CLASS-METHODS get_buyer_name
      IMPORTING iv_buyer_id          TYPE char10
      RETURNING VALUE(rv_buyer_name) TYPE char50.

    CLASS-METHODS send_to_idoc
      IMPORTING
        iv_idoc_adress TYPE char20
        is_po          TYPE  zpru_if_m_po=>ts_abstract_root_bo.

ENDCLASS.


CLASS zpru_cl_utility_function IMPLEMENTATION.

  METHOD send_to_idoc.


  ENDMETHOD.

  METHOD get_buyer_name.
    CASE iv_buyer_id.
      WHEN zpru_if_m_po=>cs_buyer-buy1.
        rv_buyer_name = zpru_if_m_po=>cs_buyer_names-buy1.
      WHEN zpru_if_m_po=>cs_buyer-buy2.
        rv_buyer_name = zpru_if_m_po=>cs_buyer_names-buy2.
      WHEN zpru_if_m_po=>cs_buyer-buy3.
        rv_buyer_name = zpru_if_m_po=>cs_buyer_names-buy3.
      WHEN zpru_if_m_po=>cs_buyer-buy4.
        rv_buyer_name = zpru_if_m_po=>cs_buyer_names-buy4.
      WHEN zpru_if_m_po=>cs_buyer-buy5.
        rv_buyer_name = zpru_if_m_po=>cs_buyer_names-buy5.
      WHEN OTHERS.
        RETURN.
    ENDCASE.
  ENDMETHOD.

  METHOD get_supplier_name.
    CASE iv_supplier_id.
      WHEN zpru_if_m_po=>cs_supplier-sup1.
        rv_supplier_name = zpru_if_m_po=>cs_supplier_names-sup1.
      WHEN zpru_if_m_po=>cs_supplier-sup2.
        rv_supplier_name = zpru_if_m_po=>cs_supplier_names-sup2.
      WHEN zpru_if_m_po=>cs_supplier-sup3.
        rv_supplier_name = zpru_if_m_po=>cs_supplier_names-sup3.
      WHEN zpru_if_m_po=>cs_supplier-sup4.
        rv_supplier_name = zpru_if_m_po=>cs_supplier_names-sup4.
      WHEN zpru_if_m_po=>cs_supplier-banned_sup5.
        rv_supplier_name = zpru_if_m_po=>cs_supplier_names-banned_sup5.
      WHEN zpru_if_m_po=>cs_supplier-banned_sup6.
        rv_supplier_name = zpru_if_m_po=>cs_supplier_names-banned_sup6.
      WHEN OTHERS.
        RETURN.
    ENDCASE.
  ENDMETHOD.

  METHOD get_preferred_ship_method.
    CASE iv_supplier_id.
      WHEN 'SUP1'.
        rv_ship_meth = zpru_if_m_po=>cs_shipping_method-air.
      WHEN 'SUP2'.
        rv_ship_meth = zpru_if_m_po=>cs_shipping_method-rail.
      WHEN 'SUP3'.
        rv_ship_meth = zpru_if_m_po=>cs_shipping_method-road.
      WHEN 'SUP4'.
        rv_ship_meth = zpru_if_m_po=>cs_shipping_method-sea.
      WHEN OTHERS.
        rv_ship_meth = zpru_if_m_po=>cs_shipping_method-air.
    ENDCASE.
  ENDMETHOD.

  METHOD fetch_history.
    CONVERT DATE is_instance-orderDate TIME sy-timlo INTO TIME STAMP DATA(lv_start) TIME ZONE 'CET'.
    CONVERT DATE is_instance-DeliveryDate TIME sy-timlo INTO TIME STAMP DATA(lv_end) TIME ZONE 'CET'.

    rs_history = VALUE #( %tky   = is_instance-%tky
                          %param = VALUE #( purchaseOrderId = is_instance-purchaseOrderId
                                            pid             = is_instance-%pid
                                            records         = VALUE #( ( startTimestamp = lv_start
                                                                         endTimestamp   = lv_end ) ) ) ).
    TRY.
        DATA(lv_start2) = cl_abap_tstmp=>subtractsecs( tstmp = lv_start
                                                       secs  = 86000  ).
      CATCH cx_parameter_invalid_range
            cx_parameter_invalid_type.
        RETURN.
    ENDTRY.

    TRY.
        DATA(lv_end2) = cl_abap_tstmp=>subtractsecs( tstmp = lv_end
                                                     secs  = 86000  ).
      CATCH cx_parameter_invalid_range
            cx_parameter_invalid_type.
        RETURN.
    ENDTRY.

    APPEND INITIAL LINE TO rs_history-%param-records ASSIGNING FIELD-SYMBOL(<ls_record>).
    <ls_record>-startTimestamp = lv_start2.
    <ls_record>-endTimestamp   = lv_end2.
  ENDMETHOD.

  METHOD get_major_supplier.
    rs_major_supplier = VALUE #( supplierId = 'SUP1' SupplierName = 'Supplier1'  ).
  ENDMETHOD.
  METHOD send_stat_to_azure.

  ENDMETHOD.

  METHOD get_inventory_status.

    IF iv_product_id = zpru_if_m_po=>cs_products-product_1.
      rs_inventory_status = VALUE #( InventoryStatus = zpru_if_m_po=>cs_inventory_status-active
                                     InventoryDate   = sy-datlo ).
    ELSE.
      rs_inventory_status = VALUE #( InventoryStatus = zpru_if_m_po=>cs_inventory_status-await
                                     InventoryDate   = sy-datlo ).
    ENDIF.

  ENDMETHOD.

  METHOD get_last_po_number.

    SELECT purchaseOrderId
    FROM Zpru_PurcOrderHdr
    ORDER BY purchaseOrderId DESCENDING
    INTO TABLE @DATA(lt_last_id) UP TO 1 ROWS.
    IF sy-subrc <> 0.
      rv_po_number = 0.
    ELSE.
      DATA(lv_last_id) = VALUE #( lt_last_id[ 1 ]-purchaseOrderId OPTIONAL ).
      REPLACE PCRE '^0+' IN lv_last_id WITH ''. " Remove leading zeros
      rv_po_number = CONV i( lv_last_id ). " Convert to int
    ENDIF.

  ENDMETHOD.

ENDCLASS.
