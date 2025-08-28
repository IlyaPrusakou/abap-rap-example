CLASS lcl_local_event_consumption DEFINITION
INHERITING FROM cl_abap_behavior_event_handler.

  PRIVATE SECTION.
    METHODS on_order_created_unmng
        FOR ENTITY EVENT it_purchase_order
          FOR OrderInt~orderCreated.

ENDCLASS.

CLASS lcl_local_event_consumption IMPLEMENTATION.

  METHOD on_order_created_unmng.
   DATA lt_event_order TYPE STANDARD TABLE OF zpru_event_order WITH EMPTY KEY.
    DATA lt_event_item  TYPE STANDARD TABLE OF zpru_event_item WITH EMPTY KEY.

    LOOP AT it_purchase_order ASSIGNING FIELD-SYMBOL(<ls_order_payload>).

      APPEND INITIAL LINE TO lt_event_order ASSIGNING FIELD-SYMBOL(<ls_event_order>).
      <ls_event_order>-purchase_order_id = <ls_order_payload>-%param-purchaseorderid3.
      <ls_event_order>-order_date        = <ls_order_payload>-%param-orderdate3.
      <ls_event_order>-supplier_id       = <ls_order_payload>-%param-supplierid3.
      <ls_event_order>-supplier_name     = <ls_order_payload>-%param-suppliername3.
      <ls_event_order>-buyer_id          = <ls_order_payload>-%param-buyerid3.
      <ls_event_order>-buyer_name        = <ls_order_payload>-%param-buyername3.
      <ls_event_order>-total_amount      = <ls_order_payload>-%param-totalamount3.
      <ls_event_order>-header_currency   = <ls_order_payload>-%param-headercurrency3.
      <ls_event_order>-delivery_date     = <ls_order_payload>-%param-deliverydate3.
      <ls_event_order>-status            = <ls_order_payload>-%param-status3.
      <ls_event_order>-payment_terms     = <ls_order_payload>-%param-paymentterms3.
      <ls_event_order>-shipping_method   = <ls_order_payload>-%param-shippingmethod3.
      LOOP AT <ls_order_payload>-%param-_items_abs3 ASSIGNING FIELD-SYMBOL(<ls_item_payload>).
        APPEND INITIAL LINE TO lt_event_item ASSIGNING FIELD-SYMBOL(<ls_event_item>).
        <ls_event_item>-item_id            = <ls_item_payload>-itemid3.
        <ls_event_item>-purchase_order_id  = <ls_order_payload>-%param-purchaseorderid3.
        <ls_event_item>-item_number        = <ls_item_payload>-itemnumber3.
        <ls_event_item>-product_id         = <ls_item_payload>-productid3.
        <ls_event_item>-product_name       = <ls_item_payload>-productname3.
        <ls_event_item>-quantity           = <ls_item_payload>-quantity3.
        <ls_event_item>-unit_price         = <ls_item_payload>-unitprice3.
        <ls_event_item>-total_price        = <ls_item_payload>-totalprice3.
        <ls_event_item>-delivery_date      = <ls_item_payload>-deliverydate3.
        <ls_event_item>-warehouse_location = <ls_item_payload>-warehouselocation3.
        <ls_event_item>-item_currency      = <ls_item_payload>-itemcurrency3.
        <ls_event_item>-is_urgent          = <ls_item_payload>-isurgent3.
      ENDLOOP.
    ENDLOOP.

    IF lt_event_order IS NOT INITIAL.
      MODIFY zpru_event_order FROM TABLE @lt_event_order.
    ENDIF.

    IF lt_event_item IS NOT INITIAL.
      MODIFY zpru_event_item FROM TABLE @lt_event_item.
    ENDIF.
  ENDMETHOD.

ENDCLASS.
