*&---------------------------------------------------------------------*
*& Report zpru_m_po_interface
*&---------------------------------------------------------------------*
*&
*&---------------------------------------------------------------------*
REPORT zpru_m_po_interface2.

SELECTION-SCREEN BEGIN OF BLOCK po WITH FRAME TITLE TEXT-001.
  PARAMETERS p_poid TYPE zpru_de_po_id.
  PARAMETERS p_podat TYPE zpru_purcorderhdr_odata_int-orderdate.
  PARAMETERS p_sup TYPE zpru_de_supplier.
  PARAMETERS p_buy TYPE zpru_de_buyer.
  PARAMETERS p_dlvdat   TYPE zpru_purcorderhdr_odata_int-deliverydate.
  PARAMETERS p_pmeth TYPE zpru_de_payment_method.
  PARAMETERS p_ship TYPE zpru_de_shipping_meth.
SELECTION-SCREEN END OF BLOCK po.

SELECTION-SCREEN BEGIN OF BLOCK itm1 WITH FRAME TITLE TEXT-002.
  PARAMETERS p_itmid TYPE zpru_de_po_itm_id.
  PARAMETERS p_quan TYPE i.
  PARAMETERS p_prod TYPE char10.
  PARAMETERS p_price TYPE zpru_purcorderitem_odata_int-unitprice.
  PARAMETERS p_itdld TYPE zpru_purcorderitem_odata_int-deliverydate.
SELECTION-SCREEN END OF BLOCK itm1.

SELECTION-SCREEN BEGIN OF BLOCK itm2 WITH FRAME TITLE TEXT-003.
  PARAMETERS p_itmid2 TYPE zpru_de_po_itm_id.
  PARAMETERS p_quan2 TYPE i.
  PARAMETERS p_prod2 TYPE char10.
  PARAMETERS p_price2 TYPE zpru_purcorderitem_odata_int-unitprice.
  PARAMETERS p_itdld2 TYPE zpru_purcorderitem_odata_int-deliverydate.
SELECTION-SCREEN END OF BLOCK itm2.


START-OF-SELECTION.

  DATA lt_create_po_in  TYPE TABLE FOR CREATE zpru_purcorderhdr_odata_int\\orderint.
  DATA lt_create_itm_in TYPE TABLE FOR CREATE zpru_purcorderhdr_odata_int\\orderint\_items_tp.
  DATA lt_root_k        TYPE TABLE FOR KEY OF zpru_purcorderhdr_odata_int\\orderint.
  DATA lt_item_k        TYPE TABLE FOR KEY OF zpru_purcorderhdr_odata_int\\itemint.

  IF p_itmid IS NOT INITIAL.
    DATA(lv_item) = abap_true.
  ENDIF.

  IF p_itmid2 IS NOT INITIAL.
    DATA(lv_item2) = abap_true.
  ENDIF.


  lt_create_po_in = VALUE #( headercurrency = 'USD'
                             ( %cid            = 'ORDER_1'
*                               purchaseOrderId = p_poid
                               orderdate       = p_podat
                               supplierid      = 'SUP1'
                               buyerid         = p_buy
                               deliverydate    = p_dlvdat
                               paymentterms    = p_pmeth
                               shippingmethod  = p_ship )
                             ( %cid            = 'ORDER_2'
*                               purchaseOrderId = p_poid
                               orderdate       = p_podat
                               supplierid      = 'SUP2'
                               buyerid         = p_buy
                               deliverydate    = p_dlvdat
                               paymentterms    = p_pmeth
                               shippingmethod  = p_ship ) ).

  IF lv_item = abap_true OR lv_item2 = abap_true.

    APPEND INITIAL LINE TO lt_create_itm_in ASSIGNING FIELD-SYMBOL(<ls_create_itm_in>).
    <ls_create_itm_in>-%cid_ref = VALUE #( lt_create_po_in[ 1 ]-%cid OPTIONAL ).

    IF lv_item = abap_true.
      APPEND INITIAL LINE TO <ls_create_itm_in>-%target ASSIGNING FIELD-SYMBOL(<ls_target_itm>).
      <ls_target_itm>-%cid       = 'ORDER_1_ITEM_1'.
      <ls_target_itm>-productid    = 'PROD1'.
      <ls_target_itm>-quantity     = p_quan .
      <ls_target_itm>-unitprice    = p_price.
      <ls_target_itm>-deliverydate = p_itdld.
      <ls_target_itm>-itemcurrency = 'USD'.
    ENDIF.

    IF lv_item2 = abap_true.
      APPEND INITIAL LINE TO <ls_create_itm_in>-%target ASSIGNING <ls_target_itm>.
      <ls_target_itm>-%cid       = 'ORDER_1_ITEM_2'.
      <ls_target_itm>-productid    = 'PROD2'.
      <ls_target_itm>-quantity     = p_quan2 .
      <ls_target_itm>-unitprice    = p_price2.
      <ls_target_itm>-deliverydate = p_itdld2.
      <ls_target_itm>-itemcurrency = 'USD'.
    ENDIF.

    APPEND INITIAL LINE TO lt_create_itm_in ASSIGNING FIELD-SYMBOL(<ls_create_itm_in2>).
    <ls_create_itm_in2>-%cid_ref = VALUE #( lt_create_po_in[ 2 ]-%cid OPTIONAL ).

    IF lv_item = abap_true.
      APPEND INITIAL LINE TO <ls_create_itm_in2>-%target ASSIGNING FIELD-SYMBOL(<ls_target_itm2>).
      <ls_target_itm2>-%cid       = 'ORDER_2_ITEM_1'.
      <ls_target_itm2>-productid    = 'PROD3'.
      <ls_target_itm2>-quantity     = p_quan .
      <ls_target_itm2>-unitprice    = p_price.
      <ls_target_itm2>-deliverydate = p_itdld.
      <ls_target_itm2>-itemcurrency = 'USD'.
    ENDIF.

    IF lv_item2 = abap_true.
      APPEND INITIAL LINE TO <ls_create_itm_in2>-%target ASSIGNING <ls_target_itm2>.
      <ls_target_itm2>-%cid       = 'ORDER_2_ITEM_2'.
      <ls_target_itm2>-productid    = 'PROD4'.
      <ls_target_itm2>-quantity     = p_quan2 .
      <ls_target_itm2>-unitprice    = p_price2.
      <ls_target_itm2>-deliverydate = p_itdld2.
      <ls_target_itm2>-itemcurrency = 'USD'.
    ENDIF.

    MODIFY ENTITIES OF zpru_purcorderhdr_odata_int
           ENTITY orderint
           CREATE AUTO FILL CID FIELDS ( purchaseorderid
                                         orderdate
                                         supplierid
                                         buyerid
                                         headercurrency
                                         deliverydate
                                         paymentterms
                                         shippingmethod ) WITH lt_create_po_in
             ENTITY orderint
             CREATE BY \_items_tp AUTO FILL CID FIELDS ( itemid
                                                         purchaseorderid
                                                         productid
                                                         quantity
                                                         unitprice
                                                         deliverydate
                                                         itemcurrency ) WITH lt_create_itm_in
           MAPPED DATA(ls_po_mapped)
           REPORTED DATA(ls_po_reported)
           FAILED DATA(ls_po_failed).

  ELSE.
    MODIFY ENTITIES OF zpru_purcorderhdr_odata_int
           ENTITY orderint
           CREATE AUTO FILL CID FIELDS ( purchaseorderid
                                         orderdate
                                         supplierid
                                         buyerid
                                         headercurrency
                                         deliverydate
                                         paymentterms
                                         shippingmethod ) WITH lt_create_po_in
           MAPPED ls_po_mapped
           REPORTED ls_po_reported
           FAILED ls_po_failed.
  ENDIF.

  COMMIT ENTITIES BEGIN RESPONSE OF zpru_purcorderhdr_odata_int FAILED DATA(ls_failed_commit) REPORTED DATA(ls_reported_commit).

  IF ls_failed_commit IS INITIAL.
    LOOP AT ls_po_mapped-orderint ASSIGNING FIELD-SYMBOL(<ls_order_mapped_early>).

      APPEND INITIAL LINE TO lt_root_k ASSIGNING FIELD-SYMBOL(<ls_order_k>).
      CONVERT KEY OF zpru_purcorderhdr_odata_int\\orderint
              FROM TEMPORARY VALUE #( %pid                 = <ls_order_mapped_early>-%pky-%pid
                                      %tmp-purchaseorderid = <ls_order_mapped_early>-%pky-purchaseorderid ) TO <ls_order_k>.
    ENDLOOP.

    IF lv_item = abap_true OR lv_item2 = abap_true.

      LOOP AT ls_po_mapped-itemint ASSIGNING FIELD-SYMBOL(<ls_item_mapped_early>).

        APPEND INITIAL LINE TO lt_item_k ASSIGNING FIELD-SYMBOL(<ls_item_k>).
        CONVERT KEY OF zpru_purcorderhdr_odata_int\\itemint
                FROM TEMPORARY VALUE #( %pid                 = <ls_item_mapped_early>-%pid
                                        %tmp-purchaseorderid = <ls_item_mapped_early>-purchaseorderid
                                        %tmp-itemid          = <ls_item_mapped_early>-itemid ) TO <ls_item_k>.
      ENDLOOP.

    ENDIF.
  ENDIF.

  COMMIT ENTITIES END.
  IF sy-subrc <> 0 OR ls_failed_commit IS NOT INITIAL.
    WRITE: 'Commit failed'.
    ROLLBACK ENTITIES.
    RETURN.
  ENDIF.

  READ ENTITIES OF zpru_purcorderhdr_odata_int
       ENTITY orderint
       ALL FIELDS WITH CORRESPONDING #( lt_root_k )
       RESULT DATA(lt_roots).

  IF lv_item = abap_true OR lv_item2 = abap_true.

    READ ENTITIES OF zpru_purcorderhdr_odata_int
         ENTITY itemint
         ALL FIELDS WITH CORRESPONDING #( lt_item_k )
         RESULT DATA(lt_items).

  ENDIF.

  ASSIGN  lt_roots[ 1 ] TO FIELD-SYMBOL(<ls_new_order>).
  IF sy-subrc <> 0.
    WRITE: 'No Order has been found'.
    RETURN.
  ENDIF.

  WRITE: 'Order create:', <ls_new_order>-purchaseorderid.
