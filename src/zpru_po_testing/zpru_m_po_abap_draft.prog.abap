*&---------------------------------------------------------------------*
*& Report zpru_m_po_abap_draft
*&---------------------------------------------------------------------*
*&
*&---------------------------------------------------------------------*
REPORT zpru_m_po_abap_draft.

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
  DATA lt_prepare_input TYPE TABLE FOR ACTION IMPORT zpru_purcorderhdr_odata_int\\orderint~prepare.
  DATA lt_activate_input TYPE TABLE FOR ACTION IMPORT zpru_purcorderhdr_odata_int\\orderint~activate.

  IF p_itmid IS NOT INITIAL.
    DATA(lv_item) = abap_true.
  ENDIF.

  IF p_itmid2 IS NOT INITIAL.
    DATA(lv_item2) = abap_true.
  ENDIF.


  lt_create_po_in = VALUE #( headercurrency = 'USD'
                             %cid       = 'ORDER_1'
                             %is_draft  = if_abap_behv=>mk-on
                             ( purchaseorderid = p_poid
                               orderdate       = p_podat
                               supplierid      = p_sup
                               buyerid         = p_buy
                               deliverydate    = p_dlvdat
                               paymentterms    = p_pmeth
                               shippingmethod  = p_ship ) ).

  " SHOW MAPPING TABLE HAS VALUES AND FAILED DOESN'T HAVE
  " DRAFT TABLES DON'T HAVE VALUES
  " DRAFT PO IN DRAFT BUFFER
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
         MAPPED DATA(ls_po_mapped)
         REPORTED DATA(ls_po_reported)
         FAILED DATA(ls_po_failed).

  IF lv_item = abap_true OR lv_item2 = abap_true.

    APPEND INITIAL LINE TO lt_create_itm_in ASSIGNING FIELD-SYMBOL(<ls_create_itm_in>).
    <ls_create_itm_in>-purchaseorderid = p_poid.
    <ls_create_itm_in>-%is_draft       = if_abap_behv=>mk-on.
    <ls_create_itm_in>-%pid            = VALUE #( ls_po_mapped-orderint[ KEY entity
                                                                COMPONENTS purchaseorderid = p_poid ]-%pid  OPTIONAL ).

    IF lv_item = abap_true.
      APPEND INITIAL LINE TO <ls_create_itm_in>-%target ASSIGNING FIELD-SYMBOL(<ls_target_itm>).
      <ls_target_itm>-%cid            = 'ORDER_1_ITEM_1'.
      <ls_target_itm>-%is_draft       = if_abap_behv=>mk-on.
      <ls_target_itm>-purchaseorderid = p_poid.
      <ls_target_itm>-itemid       = p_itmid.
      <ls_target_itm>-productid    = p_prod .
      <ls_target_itm>-quantity     = p_quan .
      <ls_target_itm>-unitprice    = p_price.
      <ls_target_itm>-deliverydate = p_itdld.
      <ls_target_itm>-itemcurrency = 'USD'.
    ENDIF.

    IF lv_item2 = abap_true.
      APPEND INITIAL LINE TO <ls_create_itm_in>-%target ASSIGNING <ls_target_itm>.
      <ls_target_itm>-%cid            = 'ORDER_1_ITEM_2'.
      <ls_target_itm>-%is_draft       = if_abap_behv=>mk-on.
      <ls_target_itm>-purchaseorderid = p_poid.
      <ls_target_itm>-itemid       = p_itmid2.
      <ls_target_itm>-productid    = p_prod2 .
      <ls_target_itm>-quantity     = p_quan2 .
      <ls_target_itm>-unitprice    = p_price2.
      <ls_target_itm>-deliverydate = p_itdld2.
      <ls_target_itm>-itemcurrency = 'USD'.
    ENDIF.

    " SHOW MAPPING TABLE HAS VALUES AND FAILED DOESN'T HAVE
    " DRAFT TABLES DON'T HAVE VALUES
    " DRAFT PO IN DRAFT BUFFER
    MODIFY ENTITIES OF zpru_purcorderhdr_odata_int
           ENTITY orderint
           CREATE BY \_items_tp AUTO FILL CID FIELDS ( itemid
                                                       purchaseorderid
                                                       productid
                                                       quantity
                                                       unitprice
                                                       deliverydate
                                                       itemcurrency ) WITH lt_create_itm_in
           MAPPED DATA(ls_itm_mapped)
           REPORTED DATA(ls_itm_reported)
           FAILED DATA(ls_itm_failed).

  ENDIF.

  ASSIGN ls_po_mapped-orderint[ 1 ] TO FIELD-SYMBOL(<ls_created_po>).
  IF sy-subrc <> 0.
    ROLLBACK ENTITIES.
    RETURN.
  ENDIF.

  IF sy-uname = 'IPRUSAKOU'.
    BREAK-POINT.
  ENDIF.

  " READ PO FROM DRAFT BUFFER
  " DRAFT TABLES HAVEN'T HAD PO DATA YET
  READ ENTITIES OF zpru_purcorderhdr_odata_int
       ENTITY orderint
       ALL FIELDS WITH VALUE #( FOR <ls_r1>
                                IN ls_po_mapped-orderint
                                ( %is_draft       = <ls_r1>-%is_draft
                                  %pid            = <ls_r1>-%pid
                                  purchaseorderid = <ls_r1>-purchaseorderid ) )
       RESULT DATA(lt_roots_drft).

  IF lv_item = abap_true OR lv_item2 = abap_true.
    " READ PO FROM DRAFT BUFFER
    " DRAFT TABLES HAVEN'T HAD PO DATA YET
    READ ENTITIES OF zpru_purcorderhdr_odata_int
         ENTITY itemint
         ALL FIELDS WITH VALUE #( FOR <ls_r2>
                                IN ls_itm_mapped-itemint
                                ( %is_draft       = <ls_r2>-%is_draft
                                  %pid            = <ls_r2>-%pid
                                  purchaseorderid = <ls_r2>-purchaseorderid
                                  itemid          = <ls_r2>-itemid ) )
         RESULT DATA(lt_items_drft).
  ENDIF.

  " SAVE DRAFT BUFFER TO DRAFT TABLES
  " PO WILL APPEAR IN DRAFT DATA BASE TABLES
  COMMIT ENTITIES RESPONSE OF zpru_purcorderhdr_odata_int
  FAILED DATA(ls_save_draft_failed)
  REPORTED DATA(ls_save_draft_report).
  IF sy-subrc <> 0.
    ROLLBACK ENTITIES.
    RETURN.
  ENDIF.

  APPEND INITIAL LINE TO lt_prepare_input ASSIGNING FIELD-SYMBOL(<ls_prepare_input>).
  <ls_prepare_input>-purchaseorderid = <ls_created_po>-purchaseorderid.
  <ls_prepare_input>-%pid            = <ls_created_po>-%pid.

  " CHECK DRAFT CONSISTENCY
  " EXECUTE ALL DETERMINATION AND VALIDATION IN DRAFT ACTION PREPARE
  MODIFY ENTITIES OF zpru_purcorderhdr_odata_int
  ENTITY orderint
  EXECUTE prepare FROM lt_prepare_input
  REPORTED DATA(ls_prep_report)
  FAILED   DATA(ls_prep_failed).

  IF ls_prep_failed IS NOT INITIAL.
    ROLLBACK ENTITIES.
    RETURN.
  ENDIF.

  APPEND INITIAL LINE TO lt_activate_input ASSIGNING FIELD-SYMBOL(<ls_activate_input>).
  <ls_activate_input>-%cid            = 'ACTIVATE_1'.
  <ls_activate_input>-purchaseorderid = <ls_created_po>-purchaseorderid.
  <ls_activate_input>-%pid            = <ls_created_po>-%pid.

  " CREATE PO IN ACTIVE BUFFER FROM DRAFT TABLES/DRAFT BUFFER
  " ENTRIES IN DRAFT TABLES STILL PERSISTED
  " ACTIVE DATA BASE TABLES HAVEN'T HAD PO YET
  MODIFY ENTITIES OF zpru_purcorderhdr_odata_int
  ENTITY orderint
  EXECUTE activate FROM lt_activate_input
  MAPPED   DATA(ls_act_mapped)
  REPORTED DATA(ls_act_report)
  FAILED   DATA(ls_act_failed).

  IF ls_act_failed IS NOT INITIAL.
    ROLLBACK ENTITIES.
    RETURN.
  ENDIF.

  " READ ACTIVE PO FROM ACTIVE BUFFER
  READ ENTITIES OF zpru_purcorderhdr_odata_int
       ENTITY orderint
       ALL FIELDS WITH VALUE #( FOR <ls_r3>
                                IN ls_act_mapped-orderint
                                ( %is_draft       = <ls_r3>-%is_draft
                                  %pid            = <ls_r3>-%pid
                                  purchaseorderid = <ls_r3>-purchaseorderid ) )
       RESULT DATA(lt_roots_act).

  IF lv_item = abap_true OR lv_item2 = abap_true.
    " READ ACTIVE PO ITEMS FROM ACTIVE BUFFER
    READ ENTITIES OF zpru_purcorderhdr_odata_int
         ENTITY orderint BY \_items_tp
         ALL FIELDS WITH VALUE #( FOR <ls_r4>
                                IN ls_act_mapped-orderint
                                ( %is_draft       = <ls_r4>-%is_draft
                                  %pid            = <ls_r4>-%pid
                                  purchaseorderid = <ls_r4>-purchaseorderid ) )
         RESULT DATA(lt_items_act).
  ENDIF.

  " CLEAR DRAFT TABLES/DRAFT BUFFER AND SAVE PO FROM ACTIVE BUFFER INTO ACTIVE DATABASE TABLES
  COMMIT ENTITIES BEGIN RESPONSE OF zpru_purcorderhdr_odata_int FAILED DATA(ls_failed_commit) REPORTED DATA(ls_reported_commit).

  IF ls_failed_commit IS INITIAL.
    LOOP AT ls_act_mapped-orderint ASSIGNING FIELD-SYMBOL(<ls_order_mapped_act>).

      APPEND INITIAL LINE TO lt_root_k ASSIGNING FIELD-SYMBOL(<ls_order_k>).
      CONVERT KEY OF zpru_purcorderhdr_odata_int\\orderint
              FROM TEMPORARY VALUE #( %pid                 = <ls_order_mapped_act>-%pky-%pid
                                      %tmp-purchaseorderid = <ls_order_mapped_act>-%pky-purchaseorderid ) TO <ls_order_k>.
    ENDLOOP.

    IF lv_item = abap_true OR lv_item2 = abap_true.

      LOOP AT lt_items_act ASSIGNING FIELD-SYMBOL(<ls_item_read_act>).

        APPEND INITIAL LINE TO lt_item_k ASSIGNING FIELD-SYMBOL(<ls_item_k>).
        CONVERT KEY OF zpru_purcorderhdr_odata_int\\itemint
                FROM TEMPORARY VALUE #( %pid                 = <ls_item_read_act>-%pid
                                        %tmp-purchaseorderid = <ls_item_read_act>-purchaseorderid
                                        %tmp-itemid          = <ls_item_read_act>-itemid ) TO <ls_item_k>.
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
