*&---------------------------------------------------------------------*
*& Report zpru_m_po_interface
*&---------------------------------------------------------------------*
*&
*&---------------------------------------------------------------------*
REPORT zpru_m_po_interface.

SELECTION-SCREEN BEGIN OF BLOCK po WITH FRAME TITLE TEXT-001.
  PARAMETERS p_poid TYPE zpru_de_po_id.
  PARAMETERS p_podat TYPE Zpru_PurcOrderHdr_ODATA_Int-orderDate.
  PARAMETERS p_sup TYPE zpru_de_supplier.
  PARAMETERS p_buy TYPE zpru_de_buyer.
  PARAMETERS p_dlvdat   TYPE Zpru_PurcOrderHdr_ODATA_Int-DeliveryDate.
  PARAMETERS p_pmeth TYPE zpru_de_payment_method.
  PARAMETERS p_ship TYPE zpru_de_shipping_meth.
SELECTION-SCREEN END OF BLOCK po.

SELECTION-SCREEN BEGIN OF BLOCK itm1 WITH FRAME TITLE TEXT-002.
  PARAMETERS P_itmid TYPE zpru_de_po_itm_id.
  PARAMETERS P_quan TYPE i.
  PARAMETERS p_prod TYPE char10.
  PARAMETERS p_price TYPE Zpru_PurcOrderItem_ODATA_Int-unitPrice.
  PARAMETERS p_ITDLD TYPE Zpru_PurcOrderItem_ODATA_Int-DeliveryDate.
SELECTION-SCREEN END OF BLOCK itm1.

SELECTION-SCREEN BEGIN OF BLOCK itm2 WITH FRAME TITLE TEXT-003.
  PARAMETERS P_itmid2 TYPE zpru_de_po_itm_id.
  PARAMETERS P_quan2 TYPE i.
  PARAMETERS p_prod2 TYPE char10.
  PARAMETERS p_price2 TYPE Zpru_PurcOrderItem_ODATA_Int-unitPrice.
  PARAMETERS p_ITDLD2 TYPE Zpru_PurcOrderItem_ODATA_Int-DeliveryDate.
SELECTION-SCREEN END OF BLOCK itm2.


START-OF-SELECTION.

  DATA lt_create_PO_in  TYPE TABLE FOR CREATE Zpru_PurcOrderHdr_ODATA_Int\\OrderInt.
  DATA lt_create_ITM_in TYPE TABLE FOR CREATE Zpru_PurcOrderHdr_ODATA_Int\\OrderInt\_items_tp.
  DATA lT_root_k        TYPE TABLE FOR KEY OF Zpru_PurcOrderHdr_ODATA_Int\\OrderInt.
  DATA lT_item_k        TYPE TABLE FOR KEY OF Zpru_PurcOrderHdr_ODATA_Int\\ItemInt.

  IF P_itmid IS NOT INITIAL.
    DATA(lv_item) = abap_true.
  ENDIF.

  IF P_itmid2 IS NOT INITIAL.
    DATA(lv_item2) = abap_true.
  ENDIF.


  lt_create_PO_in = VALUE #( headerCurrency = 'USD'
                             ( purchaseOrderId = p_poid
                               orderDate       = p_podat
                               supplierId      = p_sup
                               buyerId         = p_buy
                               deliveryDate    = p_dlvdat
                               paymentTerms    = p_pmeth
                               shippingMethod  = p_ship ) ).

  MODIFY ENTITIES OF Zpru_PurcOrderHdr_ODATA_Int
         ENTITY OrderInt
         CREATE AUTO FILL CID FIELDS ( purchaseOrderId
                                       orderDate
                                       supplierId
                                       buyerId
                                       headerCurrency
                                       deliveryDate
                                       paymentTerms
                                       shippingMethod ) WITH lt_create_PO_in
         MAPPED DATA(ls_PO_mapped)
         REPORTED DATA(ls_PO_reported)
         FAILED DATA(ls_PO_failed).

  IF lv_item = abap_true OR lv_item2 = abap_true.

    APPEND INITIAL LINE TO lt_create_ITM_in ASSIGNING FIELD-SYMBOL(<ls_create_ITM_in>).
    <ls_create_ITM_in>-purchaseorderid = p_poid.
    <ls_create_ITM_in>-%pid            = VALUE #( ls_PO_mapped-orderint[ KEY entity
                                                                COMPONENTS purchaseOrderId = p_poid ]-%pid  OPTIONAL ).

    IF lv_item = abap_true.
      APPEND INITIAL LINE TO <ls_create_ITM_in>-%target ASSIGNING FIELD-SYMBOL(<ls_target_ITM>).
      <ls_target_ITM>-purchaseOrderId = p_poid.
      <ls_target_ITM>-itemId       = P_itmid.
      <ls_target_ITM>-productId    = p_prod .
      <ls_target_ITM>-quantity     = P_quan .
      <ls_target_ITM>-unitPrice    = p_price.
      <ls_target_ITM>-deliveryDate = p_ITDLD.
      <ls_target_ITM>-itemcurrency = 'USD'.
    ENDIF.

    IF lv_item2 = abap_true.
      APPEND INITIAL LINE TO <ls_create_ITM_in>-%target ASSIGNING <ls_target_ITM>.
      <ls_target_ITM>-purchaseOrderId = p_poid.
      <ls_target_ITM>-itemId       = P_itmid2.
      <ls_target_ITM>-productId    = p_prod2 .
      <ls_target_ITM>-quantity     = P_quan2 .
      <ls_target_ITM>-unitPrice    = p_price2.
      <ls_target_ITM>-deliveryDate = p_ITDLD2.
      <ls_target_ITM>-itemcurrency = 'USD'.
    ENDIF.

    MODIFY ENTITIES OF Zpru_PurcOrderHdr_ODATA_Int
           ENTITY OrderInt
           CREATE BY \_items_tp AUTO FILL CID FIELDS ( itemId
                                                       purchaseOrderId
                                                       productId
                                                       quantity
                                                       unitPrice
                                                       deliveryDate
                                                       itemCurrency ) WITH lt_create_ITM_in
           MAPPED DATA(ls_ITM_mapped)
           REPORTED DATA(ls_ITM_reported)
           FAILED DATA(ls_ITM_failed).

  ENDIF.

  COMMIT ENTITIES BEGIN RESPONSE OF Zpru_PurcOrderHdr_ODATA_Int FAILED DATA(ls_failed_commit) REPORTED DATA(ls_reported_commit).

  IF ls_failed_commit IS INITIAL.
    LOOP AT ls_PO_mapped-orderint ASSIGNING FIELD-SYMBOL(<LS_ORDER_mapped_early>).

      APPEND INITIAL LINE TO lT_root_k ASSIGNING FIELD-SYMBOL(<ls_order_K>).
      CONVERT KEY OF Zpru_PurcOrderHdr_ODATA_Int\\OrderInt
              FROM TEMPORARY VALUE #( %pid                 = <LS_ORDER_mapped_early>-%pky-%pid
                                      %tmp-purchaseOrderId = <LS_ORDER_mapped_early>-%pky-purchaseOrderId ) TO <ls_order_K>.
    ENDLOOP.

    IF lv_item = abap_true OR lv_item2 = abap_true.

      LOOP AT ls_ITM_mapped-itemint ASSIGNING FIELD-SYMBOL(<LS_ITEM_mapped_early>).

        APPEND INITIAL LINE TO lT_item_k ASSIGNING FIELD-SYMBOL(<ls_item_k>).
        CONVERT KEY OF Zpru_PurcOrderHdr_ODATA_Int\\ItemINT
                FROM TEMPORARY VALUE #( %pid                 = <LS_ITEM_mapped_early>-%pid
                                        %tmp-purchaseOrderId = <LS_ITEM_mapped_early>-purchaseOrderId
                                        %tmp-itemId          = <LS_ITEM_mapped_early>-itemId ) TO <ls_item_k>.
      ENDLOOP.

    ENDIF.
  ENDIF.

  COMMIT ENTITIES END.
  IF sy-subrc <> 0 OR ls_failed_commit IS NOT INITIAL.
    WRITE: 'Commit failed'.
    ROLLBACK ENTITIES.
    RETURN.
  ENDIF.

  READ ENTITIES OF Zpru_PurcOrderHdr_ODATA_Int
       ENTITY OrderInt
       ALL FIELDS WITH CORRESPONDING #( lT_root_k )
       RESULT DATA(lt_roots).

  IF lv_item = abap_true OR lv_item2 = abap_true.

    READ ENTITIES OF Zpru_PurcOrderHdr_ODATA_Int
         ENTITY ItemInt
         ALL FIELDS WITH CORRESPONDING #( lT_item_k )
         RESULT DATA(lt_items).

  ENDIF.

  ASSIGN  lt_roots[ 1 ] TO FIELD-SYMBOL(<ls_new_order>).
  IF sy-subrc <> 0.
    WRITE: 'No Order has been found'.
    RETURN.
  ENDIF.

  WRITE: 'Order create:', <ls_new_order>-purchaseOrderId.
