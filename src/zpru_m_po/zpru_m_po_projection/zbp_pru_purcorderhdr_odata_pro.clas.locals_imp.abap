CLASS lhc_OrderTP DEFINITION INHERITING FROM cl_abap_behavior_handler.
  PRIVATE SECTION.
    METHODS augment_create FOR MODIFY
      IMPORTING entities FOR CREATE OrderProj.
    METHODS precheck_create FOR PRECHECK
      IMPORTING entities FOR CREATE Orderproj.
    METHODS augment_cba_Items_tp FOR MODIFY
      IMPORTING entities FOR CREATE OrderProj\_Items_tp.
    METHODS precheck_cba_Items_tp FOR PRECHECK
      IMPORTING entities FOR CREATE OrderProj\_Items_tp.
    METHODS precheck_ChangeStatus FOR PRECHECK
      IMPORTING keys FOR ACTION OrderProj~ChangeStatus.
    METHODS sendToIDOC FOR MODIFY
      IMPORTING keys FOR ACTION OrderProj~sendToIDOC.
    METHODS calculateOpenOrderValue FOR READ
      IMPORTING keys FOR FUNCTION OrderProj~calculateOpenOrderValue RESULT result.

ENDCLASS.


CLASS lhc_OrderTP IMPLEMENTATION.
  METHOD augment_create.
  ENDMETHOD.

  METHOD precheck_create.
  ENDMETHOD.

  METHOD augment_cba_Items_tp.
  ENDMETHOD.

  METHOD precheck_cba_Items_tp.
  ENDMETHOD.

  METHOD precheck_ChangeStatus.
  ENDMETHOD.

  METHOD sendToIDOC.
    DATA ls_payload TYPE zpru_if_m_po=>ts_abstract_root_bo.

    READ ENTITIES OF Zpru_PurcOrderHdr_tp
         ENTITY OrderTP
         FROM CORRESPONDING #( keys )
         RESULT DATA(lt_roots).

    IF lt_roots IS INITIAL.
      RETURN.
    ENDIF.

    READ ENTITIES OF Zpru_PurcOrderHdr_tp
         ENTITY OrderTP BY \_items_tp
         FROM CORRESPONDING #( keys )
         RESULT DATA(lt_items).

    LOOP AT keys ASSIGNING FIELD-SYMBOL(<ls_key>).

      ASSIGN lt_roots[ KEY id COMPONENTS %tky = <ls_key>-%tky ] TO FIELD-SYMBOL(<ls_order>).
      IF sy-subrc <> 0.
        CONTINUE.
      ENDIF.

      " read data from cross bo
      DATA(ls_history) = zpru_cl_utility_function=>fetch_history( CORRESPONDING #( <ls_order> ) ).

      ls_payload-purchaseorderid2 = <ls_order>-purchaseorderid.
      ls_payload-orderdate2       = <ls_order>-orderdate.
      ls_payload-supplierid2      = <ls_order>-supplierid.
      ls_payload-suppliername2    = <ls_order>-suppliername.
      ls_payload-buyerid2         = <ls_order>-buyerid.
      ls_payload-buyername2       = <ls_order>-buyername.
      ls_payload-totalamount2     = <ls_order>-totalamount.
      ls_payload-headercurrency2  = <ls_order>-headercurrency.
      ls_payload-deliverydate2    = <ls_order>-deliverydate.
      ls_payload-status2          = <ls_order>-status.
      ls_payload-paymentterms2    = <ls_order>-paymentterms.
      ls_payload-shippingmethod2  = <ls_order>-shippingmethod.

      ls_payload-%control-purchaseorderid2 = if_abap_behv=>mk-on.
      ls_payload-%control-orderdate2       = if_abap_behv=>mk-on.
      ls_payload-%control-supplierid2      = if_abap_behv=>mk-on.
      ls_payload-%control-suppliername2    = if_abap_behv=>mk-on.
      ls_payload-%control-buyerid2         = if_abap_behv=>mk-on.
      ls_payload-%control-buyername2       = if_abap_behv=>mk-on.
      ls_payload-%control-totalamount2     = if_abap_behv=>mk-on.
      ls_payload-%control-headercurrency2  = if_abap_behv=>mk-on.
      ls_payload-%control-deliverydate2    = if_abap_behv=>mk-on.
      ls_payload-%control-status2          = if_abap_behv=>mk-on.
      ls_payload-%control-paymentterms2    = if_abap_behv=>mk-on.
      ls_payload-%control-shippingmethod2  = if_abap_behv=>mk-on.
      ls_payload-%control-_cross_bo        = if_abap_behv=>mk-on.
      ls_payload-%control-_items_abs       = if_abap_behv=>mk-on.

      LOOP AT lt_items ASSIGNING FIELD-SYMBOL(<ls_item>)
           WHERE purchaseorderid = <ls_order>-purchaseorderid.
        APPEND INITIAL LINE TO ls_payload-_items_abs ASSIGNING FIELD-SYMBOL(<ls_item_payload>).
        <ls_item_payload>-itemid2            = <ls_item>-itemid.
        <ls_item_payload>-itemnumber2        = <ls_item>-itemnumber.
        <ls_item_payload>-productid2         = <ls_item>-productid.
        <ls_item_payload>-productname2       = <ls_item>-productname.
        <ls_item_payload>-quantity2          = <ls_item>-quantity.
        <ls_item_payload>-unitprice2         = <ls_item>-unitprice.
        <ls_item_payload>-totalprice2        = <ls_item>-totalprice.
        <ls_item_payload>-deliverydate2      = <ls_item>-deliverydate.
        <ls_item_payload>-warehouselocation2 = <ls_item>-warehouselocation.
        <ls_item_payload>-itemcurrency2      = <ls_item>-itemcurrency.
        <ls_item_payload>-isurgent2          = <ls_item>-isurgent.
        <ls_item_payload>-%control-itemid2            = if_abap_behv=>mk-on.
        <ls_item_payload>-%control-itemnumber2        = if_abap_behv=>mk-on.
        <ls_item_payload>-%control-productid2         = if_abap_behv=>mk-on.
        <ls_item_payload>-%control-productname2       = if_abap_behv=>mk-on.
        <ls_item_payload>-%control-quantity2          = if_abap_behv=>mk-on.
        <ls_item_payload>-%control-unitprice2         = if_abap_behv=>mk-on.
        <ls_item_payload>-%control-totalprice2        = if_abap_behv=>mk-on.
        <ls_item_payload>-%control-deliverydate2      = if_abap_behv=>mk-on.
        <ls_item_payload>-%control-warehouselocation2 = if_abap_behv=>mk-on.
        <ls_item_payload>-%control-itemcurrency2      = if_abap_behv=>mk-on.
        <ls_item_payload>-%control-isurgent2          = if_abap_behv=>mk-on.

      ENDLOOP.

      " fill cross bo data in payload
      ls_payload-_cross_bo-purchaseOrderId = ls_history-%param-purchaseOrderId.
      LOOP AT ls_history-%param-records ASSIGNING FIELD-SYMBOL(<ls_record>).
        APPEND INITIAL LINE TO ls_payload-_cross_bo-records ASSIGNING FIELD-SYMBOL(<ls_record_payload>).
        <ls_record_payload>-StartTimestamp = <ls_record>-StartTimestamp.
        <ls_record_payload>-EndTimestamp   = <ls_record>-EndTimestamp.
      ENDLOOP.

      zpru_cl_utility_function=>send_to_idoc( iv_idoc_adress = <ls_key>-%param-idoc
                                              is_po          = ls_payload ).

    ENDLOOP.
  ENDMETHOD.

  METHOD calculateOpenOrderValue.
  ENDMETHOD.
ENDCLASS.
