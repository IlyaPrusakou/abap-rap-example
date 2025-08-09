CLASS lhc_OrderTP DEFINITION INHERITING FROM cl_abap_behavior_handler.
  PRIVATE SECTION.
    METHODS augment FOR MODIFY
      IMPORTING entities_create FOR CREATE OrderProj
                entities_update FOR UPDATE OrderProj.
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

      ASSIGN lt_roots[ KEY id COMPONENTS %tky-%is_draft       = <ls_key>-%tky-%is_draft
                                         %tky-%pid            = <ls_key>-%pid
                                         %tky-purchaseOrderId = <ls_key>-purchaseOrderId ] TO FIELD-SYMBOL(<ls_order>).
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
    DATA lv_total_amount TYPE p LENGTH 15 DECIMALS 2.

    IF keys IS INITIAL.
      RETURN.
    ENDIF.

    SELECT purchaseOrderId FROM Zpru_PurcOrderHdr_tp
      FOR ALL ENTRIES IN @keys
      WHERE supplierId = @keys-%param-supplierid
      INTO TABLE @DATA(lt_po_for_suppliers).

    IF lt_po_for_suppliers IS INITIAL.
      RETURN.
    ENDIF.

    READ ENTITIES OF Zpru_PurcOrderHdr_tp
         ENTITY OrderTP
         FIELDS ( supplierId
                  totalamount
                  headerCurrency )
         WITH VALUE #( FOR <ls_k>
                       IN lt_po_for_suppliers
                       ( %tky-purchaseOrderId = <ls_k>-purchaseOrderId ) )
         RESULT DATA(lt_read_result).

    LOOP AT lt_read_result ASSIGNING FIELD-SYMBOL(<ls_supplier>)
         GROUP BY <ls_supplier>-supplierId
         ASSIGNING FIELD-SYMBOL(<lv_supplier>).

      lv_total_amount = 0.
      LOOP AT GROUP <lv_supplier> ASSIGNING FIELD-SYMBOL(<ls_member>).
        lv_total_amount = lv_total_amount + <ls_member>-totalAmount.
      ENDLOOP.

      APPEND INITIAL LINE TO result ASSIGNING FIELD-SYMBOL(<ls_result>).
      <ls_result>-%param-supplierId  = <lv_supplier>.
      <ls_result>-%param-totalAmount = lv_total_amount.
      <ls_result>-%param             = 'USD'.

    ENDLOOP.
  ENDMETHOD.

  METHOD augment.
    DATA: lt_ordertext_for_new_order     TYPE TABLE FOR CREATE Zpru_PurcOrderHdr_tp\_text_tp,
          lt_ordertext_for_existing_ordr TYPE TABLE FOR CREATE Zpru_PurcOrderHdr_tp\_text_tp,
          lt_ordertext_update            TYPE TABLE FOR UPDATE Zpru_PurcOrderHdr_T_TP.
    DATA: lt_relates_create TYPE abp_behv_relating_tab,
          lt_relates_update TYPE abp_behv_relating_tab,
          lt_relates_cba    TYPE abp_behv_relating_tab.
    DATA: ls_order_text_tky_link TYPE STRUCTURE FOR READ LINK Zpru_PurcOrderHdr_tp\\OrderTP\_text_tp,
          ls_order_text_tky      LIKE ls_order_text_tky_link-target.

    "Handle create requests including SupplementDescription
    LOOP AT entities_create ASSIGNING FIELD-SYMBOL(<ls_order_create>).
      "Count Table index for uniquely identifiably %cid on creating supplementtext
      APPEND sy-tabix TO lt_relates_create.

      "Direct the Order Create to the corresponding OrderText Create-By-Association using the current language
      APPEND VALUE #( %cid_ref           = <ls_order_create>-%cid
                      %is_draft          = <ls_order_create>-%is_draft
                      purchaseorderid    = <ls_order_create>-purchaseorderid
                      %target            = VALUE #( ( %cid              = |CREATETEXTCID{ sy-tabix }|
                                                      %is_draft         = <ls_order_create>-%is_draft
                                                      purchaseorderid   = <ls_order_create>-purchaseorderid
                                                      language          = sy-langu
                                                      TextContent       = <ls_order_create>-orderDescription
                                                      %control          = VALUE #( purchaseorderid = if_abap_behv=>mk-on
                                                                                   language = if_abap_behv=>mk-on
                                                                                   TextContent  = <ls_order_create>-%control-orderDescription )
                                                   ) )
                     ) TO lt_ordertext_for_new_order.
    ENDLOOP.

    MODIFY AUGMENTING ENTITIES OF Zpru_PurcOrderHdr_tp
    ENTITY OrderTP
    CREATE BY \_text_tp
    FROM lt_ordertext_for_new_order
    RELATING TO entities_create BY lt_relates_create.



    IF entities_update IS NOT INITIAL.

      READ ENTITIES OF Zpru_PurcOrderHdr_tp
      ENTITY OrderTP BY \_text_tp
      FROM CORRESPONDING #( entities_update )
      LINK DATA(link)
      FAILED DATA(link_failed).

      "Handle update requests
      LOOP AT entities_update ASSIGNING FIELD-SYMBOL(<ls_order_update>)
                              WHERE %control-orderDescription = if_abap_behv=>mk-on.

        CHECK NOT line_exists( link_failed-ordertp[ KEY draft
                                                    %tky = CORRESPONDING #( <ls_order_update>-%tky ) ] )
          OR line_exists( lt_ordertext_for_new_order[ KEY cid
                                                      %cid_ref = <ls_order_update>-%cid_ref
                                                      %is_draft = <ls_order_update>-%is_draft ] ).


        DATA(tabix) = sy-tabix.

        "Create variable for %tky for target entity instances
        ls_order_text_tky = CORRESPONDING #( <ls_order_update>-%tky )  .
        ls_order_text_tky-Language = sy-langu.

        "If a order_text with sy-langu already exists, perform an update. Else perform a create-by-association.
        IF line_exists( link[ KEY draft source-%tky  = CORRESPONDING #( <ls_order_update>-%tky )
                                        target-%tky  = CORRESPONDING #( ls_order_text_tky ) ] ).

          APPEND tabix TO lt_relates_update.

          APPEND VALUE #( %tky             = ls_order_text_tky
                          %cid_ref         = <ls_order_update>-%cid_ref
                          TextContent      = <ls_order_update>-orderDescription
                          %control         = VALUE #( TextContent = <ls_order_update>-%control-orderDescription )
                        ) TO lt_ordertext_update.

          "If order_text was created in the current MODIFY, perform an update based on %cid
        ELSEIF line_exists(  lt_ordertext_for_new_order[ KEY cid %is_draft = <ls_order_update>-%is_draft
                                                          %cid_ref  = <ls_order_update>-%cid_ref ] ).
          APPEND tabix TO lt_relates_update.

          APPEND VALUE #( %tky             = ls_order_text_tky
                          %cid_ref         = lt_ordertext_for_new_order[ %is_draft = <ls_order_update>-%is_draft
                                                                  %cid_ref  = <ls_order_update>-%cid_ref ]-%target[ 1 ]-%cid
                           TextContent    = <ls_order_update>-orderDescription
                          %control         = VALUE #( TextContent = <ls_order_update>-%control-orderDescription )
                        ) TO lt_ordertext_update.

          "If order_text with sy-langu does not exist yet for corresponding order
        ELSE.
          APPEND tabix TO lt_relates_cba.

          "Direct the order Update to the corresponding orderText Create-By-Association using the current language
          APPEND VALUE #( %tky     = CORRESPONDING #( <ls_order_update>-%tky )
                          %cid_ref = <ls_order_update>-%cid_ref
                          %target  = VALUE #( ( %cid          = |UPDATETEXTCID{ tabix }|
                                                language  = sy-langu
                                                %is_draft     = ls_order_text_tky-%is_draft
                                                TextContent   = <ls_order_update>-orderDescription
                                                %control      = VALUE #( language = if_abap_behv=>mk-on
                                                                         TextContent   = <ls_order_update>-%control-orderDescription )
                                             ) )
                         ) TO lt_ordertext_for_existing_ordr.
        ENDIF.

      ENDLOOP.
    ENDIF.

    MODIFY AUGMENTING ENTITIES OF Zpru_PurcOrderHdr_tp
      ENTITY TextTP
        UPDATE FROM lt_ordertext_update
        RELATING TO entities_update BY lt_relates_update
      ENTITY OrderTP
        CREATE BY \_text_tp
        FROM lt_ordertext_for_existing_ordr
        RELATING TO entities_update BY lt_relates_cba.

  ENDMETHOD.
ENDCLASS.
