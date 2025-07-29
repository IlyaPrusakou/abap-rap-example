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

ENDCLASS.


CLASS zpru_cl_utility_function IMPLEMENTATION.
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

ENDCLASS.
