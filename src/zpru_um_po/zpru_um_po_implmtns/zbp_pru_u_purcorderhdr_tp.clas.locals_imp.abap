INTERFACE lif_business_object.

  CONSTANTS: BEGIN OF cs_state_area,
               BEGIN OF order,
                 checkDates          TYPE string VALUE `checkdates`,
                 checkQuantity       TYPE string VALUE `checkQuantity`,
                 checkHeaderCurrency TYPE string VALUE `checkHeaderCurrency`,
                 checkSupplier       TYPE string VALUE `checkSupplier`,
                 checkBuyer          TYPE string VALUE `checkBuyer`,
               END OF order,
               BEGIN OF item,
                 checkQuantity     TYPE string VALUE `checkquantity`,
                 checkItemCurrency TYPE string VALUE `checkItemCurrency`,
               END OF item,
             END OF cs_state_area.

ENDINTERFACE.


CLASS lcl_buffer DEFINITION.
  PUBLIC SECTION.
    TYPES: BEGIN OF gty_buffer,
             instance      TYPE zpru_u_purcorderhdr_tp, " qqq use your Transactional CDS
             cid           TYPE string,
             newly_created TYPE abap_bool,
             changed       TYPE abap_bool,
             deleted       TYPE abap_bool,
             is_draft      TYPE abp_behv_flag,
           END OF gty_buffer.

    TYPES: BEGIN OF gty_buffer_child,
             instance   TYPE zpru_u_purcorderitem_tp, " qqq use your Transactional CDS
             cid_ref    TYPE string,
             cid_target TYPE string,
             changed    TYPE abap_bool,
             deleted    TYPE abap_bool,
             is_draft   TYPE abp_behv_flag,
           END OF gty_buffer_child.

    TYPES gtt_buffer       TYPE TABLE OF gty_buffer WITH EMPTY KEY.
    TYPES gtt_buffer_child TYPE TABLE OF gty_buffer_child WITH EMPTY KEY.

    CLASS-DATA root_buffer  TYPE STANDARD TABLE OF gty_buffer WITH EMPTY KEY.
    CLASS-DATA child_buffer TYPE STANDARD TABLE OF gty_buffer_child WITH EMPTY KEY.

    TYPES: BEGIN OF root_db_keys,
             purchase_order_id TYPE zpru_de_po_id, " qqq use your data element
           END OF root_db_keys.

    TYPES: BEGIN OF child_db_keys,
             purchase_order_id TYPE zpru_de_po_id,
             item_Id           TYPE zpru_de_po_itm_id, " qqq use your data element
           END OF child_db_keys.

    TYPES: BEGIN OF root_keys,
             purchaseOrderID TYPE zpru_u_purcorderhdr_tp-purchaseOrderId, " qqq use your key fields
             is_draft        TYPE abp_behv_flag,
           END OF root_keys.
    TYPES: BEGIN OF child_keys,
             purchaseOrderId TYPE zpru_u_purcorderitem_tp-purchaseOrderId, " qqq use your key fields
             itemId          TYPE zpru_u_purcorderitem_tp-itemId,
             is_draft        TYPE abp_behv_flag,
             full_key        TYPE abap_bool,
           END OF child_keys.
    TYPES tt_root_keys     TYPE TABLE OF root_keys WITH EMPTY KEY.
    TYPES tt_root_db_keys  TYPE TABLE OF root_db_keys WITH EMPTY KEY.
    TYPES tt_child_keys    TYPE TABLE OF child_keys WITH EMPTY KEY.
    TYPES tt_child_db_keys TYPE TABLE OF child_db_keys WITH EMPTY KEY.

    CLASS-METHODS prep_root_buffer
      IMPORTING !keys TYPE tt_root_keys.

    CLASS-METHODS prep_child_buffer
      IMPORTING !keys TYPE tt_child_keys.

ENDCLASS.


CLASS lcl_buffer IMPLEMENTATION.
  METHOD prep_root_buffer.
    DATA ls_line TYPE zpru_u_purcorderhdr_tp. " qqq use your Transactional CDS

    READ ENTITIES OF zpru_u_purcorderhdr_tp " qqq use your base BDEF
         ENTITY OrderTP
         ALL FIELDS WITH VALUE #( FOR <ls_drf>
                                  IN keys
                                  WHERE ( is_draft = if_abap_behv=>mk-on )
                                  ( purchaseOrderId = <ls_drf>-purchaseorderid
                                    %is_draft       = <ls_drf>-is_draft  ) )
         RESULT DATA(lt_draft_buffer).

    LOOP AT keys ASSIGNING FIELD-SYMBOL(<ls_buffer>).

      IF line_exists( lcl_buffer=>root_buffer[ instance-purchaseOrderId = <ls_buffer>-purchaseorderid
                                               is_draft                 = <ls_buffer>-is_draft ] ).
        " do nothing
      ELSE.
        IF <ls_buffer>-is_draft = if_abap_behv=>mk-on.
          SELECT SINGLE @abap_true FROM @lt_draft_buffer AS draft_buffer
            WHERE purchaseorderid = @<ls_buffer>-purchaseorderid
            INTO @DATA(lv_exists_d).
          IF lv_exists_d = abap_true.
            SELECT SINGLE * FROM @lt_draft_buffer AS draft_buffer
              WHERE purchaseorderid = @<ls_buffer>-purchaseorderid
              INTO CORRESPONDING FIELDS OF @ls_line.
            IF sy-subrc = 0.
              APPEND VALUE #( instance = ls_line ) TO lcl_buffer=>root_buffer ASSIGNING FIELD-SYMBOL(<ls_just_inserted>).
              <ls_just_inserted>-is_draft = if_abap_behv=>mk-on.
            ENDIF.
          ENDIF.
        ELSE.
          SELECT SINGLE @abap_true FROM Zpru_PurcOrderHdr  " use your base CDS or Transactional CDS
            WHERE purchaseorderid = @<ls_buffer>-purchaseorderid
            INTO @DATA(lv_exists).
          IF lv_exists = abap_true.
            SELECT SINGLE * FROM Zpru_PurcOrderHdr " use your base CDS or Transactional CDS
              WHERE purchaseorderid = @<ls_buffer>-purchaseorderid
              INTO CORRESPONDING FIELDS OF @ls_line.
            IF sy-subrc = 0.
              APPEND VALUE #( instance = ls_line ) TO lcl_buffer=>root_buffer ASSIGNING <ls_just_inserted>.
              <ls_just_inserted>-is_draft = if_abap_behv=>mk-off.
            ENDIF.
          ENDIF.
        ENDIF.
      ENDIF.
    ENDLOOP.
  ENDMETHOD.

  METHOD prep_child_buffer.
    DATA lt_ch_tab  TYPE TABLE OF zpru_u_purcorderitem_tp WITH EMPTY KEY. " qqq use your Transactional CDS
    DATA ls_line_ch TYPE zpru_u_purcorderitem_tp. " qqq use your Transactional CDS

    READ ENTITIES OF zpru_u_purcorderhdr_tp " qqq use your base bdef
         ENTITY OrderTP BY \_items_tp
         ALL FIELDS WITH VALUE #( FOR <ls_drf>
                                  IN keys
                                  WHERE ( is_draft = if_abap_behv=>mk-on )
                                  ( purchaseOrderId = <ls_drf>-purchaseorderid
                                    %is_draft       = <ls_drf>-is_draft  ) )
         RESULT DATA(lt_draft_buffer).

    LOOP AT keys ASSIGNING FIELD-SYMBOL(<ls_buffer_ch>).

      IF <ls_buffer_ch>-full_key = abap_true.
        IF line_exists( lcl_buffer=>child_buffer[ instance-purchaseOrderId = <ls_buffer_ch>-purchaseOrderId
                                                  instance-itemId          = <ls_buffer_ch>-itemId
                                                  is_draft                 = <ls_buffer_ch>-is_draft ] ).
          " do nothing
        ELSE.
          IF <ls_buffer_ch>-is_draft = if_abap_behv=>mk-on.
            SELECT SINGLE @abap_true FROM @lt_draft_buffer AS draft_buffer
              WHERE purchaseOrderId = @<ls_buffer_ch>-purchaseOrderId
                AND itemId          = @<ls_buffer_ch>-itemId
              INTO @DATA(lv_exists_d).
            IF lv_exists_d = abap_true.

              SELECT SINGLE * FROM @lt_draft_buffer AS draft_buffer
                WHERE purchaseOrderId = @<ls_buffer_ch>-purchaseOrderId
                  AND itemId          = @<ls_buffer_ch>-itemId
                INTO CORRESPONDING FIELDS OF @ls_line_ch.

              IF sy-subrc = 0.
                APPEND VALUE #( instance = ls_line_ch ) TO lcl_buffer=>child_buffer ASSIGNING FIELD-SYMBOL(<ls_just_inserted>).
                <ls_just_inserted>-is_draft = if_abap_behv=>mk-on.
              ENDIF.
            ENDIF.
          ELSE.
            SELECT SINGLE @abap_true FROM Zpru_PurcOrderItem  " qqq use your base CDS or Transactional CDS
              WHERE purchaseOrderId = @<ls_buffer_ch>-purchaseOrderId
                AND itemId          = @<ls_buffer_ch>-itemId
              INTO @DATA(lv_exists).
            IF lv_exists = abap_true.
              SELECT SINGLE * FROM Zpru_PurcOrderItem " qqq use your base CDS or Transactional CDS
                WHERE purchaseOrderId = @<ls_buffer_ch>-purchaseOrderId
                  AND itemId          = @<ls_buffer_ch>-itemId
                INTO CORRESPONDING FIELDS OF @ls_line_ch.

              IF sy-subrc = 0.
                APPEND VALUE #( instance = ls_line_ch ) TO lcl_buffer=>child_buffer ASSIGNING <ls_just_inserted>.
                <ls_just_inserted>-is_draft = if_abap_behv=>mk-off.
              ENDIF.
            ENDIF.
          ENDIF.
        ENDIF.

      ELSE.
        IF     line_exists( lcl_buffer=>root_buffer[ instance-purchaseOrderId = <ls_buffer_ch>-purchaseorderid
                                                     is_draft                 = <ls_buffer_ch>-is_draft ] )
           AND VALUE #( lcl_buffer=>root_buffer[ instance-purchaseOrderId = <ls_buffer_ch>-purchaseOrderId
                                                 is_draft                 = <ls_buffer_ch>-is_draft ]-deleted OPTIONAL ) IS NOT INITIAL.
          " do nothing
        ELSE.
          IF <ls_buffer_ch>-is_draft = if_abap_behv=>mk-on.
            SELECT SINGLE @abap_true FROM @lt_draft_buffer AS draft_buffer
              WHERE purchaseOrderId = @<ls_buffer_ch>-purchaseOrderId
              INTO @DATA(lv_exists_ch_D).
            IF lv_exists_ch_D = abap_true.
              SELECT * FROM @lt_draft_buffer AS draft_buffer
                WHERE purchaseOrderId = @<ls_buffer_ch>-purchaseOrderId
                INTO CORRESPONDING FIELDS OF TABLE @lt_ch_tab.
              IF sy-subrc = 0.
                LOOP AT lt_ch_tab ASSIGNING FIELD-SYMBOL(<ls_ch>).
                  IF NOT line_exists( lcl_buffer=>child_buffer[ instance-purchaseOrderId = <ls_ch>-purchaseOrderId
                                                                instance-itemId          = <ls_ch>-itemId
                                                                is_draft                 = if_abap_behv=>mk-on ] ).
                    APPEND VALUE #( instance = <ls_ch> ) TO lcl_buffer=>child_buffer ASSIGNING <ls_just_inserted>.
                    <ls_just_inserted>-is_draft = if_abap_behv=>mk-on.
                  ENDIF.
                ENDLOOP.
              ENDIF.
            ENDIF.
          ELSE.

            SELECT SINGLE @abap_true FROM Zpru_PurcOrderItem " qqq use your base or Transactional CDS
              WHERE purchaseOrderId = @<ls_buffer_ch>-purchaseOrderId
              INTO @DATA(lv_exists_ch).
            IF lv_exists_ch = abap_true.
              SELECT * FROM Zpru_PurcOrderItem   " qqq use your base or Transactional CDS
                WHERE purchaseOrderId = @<ls_buffer_ch>-purchaseOrderId
                INTO CORRESPONDING FIELDS OF TABLE @lt_ch_tab.
              IF sy-subrc = 0.
                LOOP AT lt_ch_tab ASSIGNING <ls_ch>.
                  IF NOT line_exists( lcl_buffer=>child_buffer[ instance-purchaseOrderId = <ls_ch>-purchaseOrderId
                                                                instance-itemId          = <ls_ch>-itemId
                                                                is_draft                 = if_abap_behv=>mk-off ] ).
                    APPEND VALUE #( instance = <ls_ch> ) TO lcl_buffer=>child_buffer ASSIGNING <ls_just_inserted>.
                    <ls_just_inserted>-is_draft = if_abap_behv=>mk-off.
                  ENDIF.
                ENDLOOP.
              ENDIF.
            ENDIF.
          ENDIF.
        ENDIF.
      ENDIF.
    ENDLOOP.
  ENDMETHOD.
ENDCLASS.


CLASS lhc_OrderTP DEFINITION INHERITING FROM cl_abap_behavior_handler.
  PRIVATE SECTION.
    METHODS get_instance_features FOR INSTANCE FEATURES
      IMPORTING keys REQUEST requested_features FOR OrderTP RESULT result.

    METHODS get_instance_authorizations FOR INSTANCE AUTHORIZATION
      IMPORTING keys REQUEST requested_authorizations FOR OrderTP RESULT result.

    METHODS get_global_authorizations FOR GLOBAL AUTHORIZATION
      IMPORTING REQUEST requested_authorizations FOR OrderTP RESULT result.

    METHODS create FOR MODIFY
      IMPORTING entities FOR CREATE OrderTP.

    METHODS precheck_create FOR PRECHECK
      IMPORTING entities FOR CREATE OrderTP.

    METHODS update FOR MODIFY
      IMPORTING entities FOR UPDATE OrderTP.

    METHODS precheck_update FOR PRECHECK
      IMPORTING entities FOR UPDATE OrderTP.

    METHODS delete FOR MODIFY
      IMPORTING keys FOR DELETE OrderTP.

    METHODS precheck_delete FOR PRECHECK
      IMPORTING keys FOR DELETE OrderTP.

    METHODS read FOR READ
      IMPORTING keys FOR READ OrderTP RESULT result.

    METHODS lock FOR LOCK
      IMPORTING keys FOR LOCK OrderTP.

    METHODS rba_Items_tp FOR READ
      IMPORTING keys_rba FOR READ OrderTP\_Items_tp FULL result_requested RESULT result LINK association_links.

    METHODS cba_Items_tp FOR MODIFY
      IMPORTING entities_cba FOR CREATE OrderTP\_Items_tp.

    METHODS getAllItems FOR READ
      IMPORTING keys FOR FUNCTION OrderTP~getAllItems REQUEST requested_fields RESULT result.

    METHODS getMajorSupplier FOR READ
      IMPORTING keys FOR FUNCTION OrderTP~getMajorSupplier RESULT result.

    METHODS getStatusHistory FOR READ
      IMPORTING keys FOR FUNCTION OrderTP~getStatusHistory RESULT result.

    METHODS isSupplierBlacklisted FOR READ
      IMPORTING keys FOR FUNCTION OrderTP~isSupplierBlacklisted RESULT result.

    METHODS Activate FOR MODIFY
      IMPORTING keys FOR ACTION OrderTP~Activate.

    METHODS ChangeStatus FOR MODIFY
      IMPORTING keys FOR ACTION OrderTP~ChangeStatus.

    METHODS precheck_ChangeStatus FOR PRECHECK
      IMPORTING keys FOR ACTION OrderTP~ChangeStatus.

    METHODS createFromTemplate FOR MODIFY
      IMPORTING keys FOR ACTION OrderTP~createFromTemplate.

    METHODS Discard FOR MODIFY
      IMPORTING keys FOR ACTION OrderTP~Discard.

    METHODS Edit FOR MODIFY
      IMPORTING keys FOR ACTION OrderTP~Edit.

    METHODS Resume FOR MODIFY
      IMPORTING keys FOR ACTION OrderTP~Resume.

    METHODS revalidatePricingRules FOR MODIFY
      IMPORTING keys FOR ACTION OrderTP~revalidatePricingRules RESULT result.

    METHODS sendOrderStatisticToAzure FOR MODIFY
      IMPORTING keys FOR ACTION OrderTP~sendOrderStatisticToAzure.

    METHODS determineNames FOR DETERMINE ON MODIFY
      IMPORTING keys FOR OrderTP~determineNames.

    METHODS recalculateShippingMethod FOR DETERMINE ON MODIFY
      IMPORTING keys FOR OrderTP~recalculateShippingMethod.

    METHODS calcTotalAmount FOR DETERMINE ON SAVE
      IMPORTING keys FOR OrderTP~calcTotalAmount.

    METHODS setControlTimestamp FOR DETERMINE ON SAVE
      IMPORTING keys FOR OrderTP~setControlTimestamp.

    METHODS checkBuyer FOR VALIDATE ON SAVE
      IMPORTING keys FOR OrderTP~checkBuyer.

    METHODS checkDates FOR VALIDATE ON SAVE
      IMPORTING keys FOR OrderTP~checkDates.

    METHODS checkHeaderCurrency FOR VALIDATE ON SAVE
      IMPORTING keys FOR OrderTP~checkHeaderCurrency.

    METHODS checkSupplier FOR VALIDATE ON SAVE
      IMPORTING keys FOR OrderTP~checkSupplier.
    METHODS precheck_cba_Items_tp FOR PRECHECK
      IMPORTING entities FOR CREATE OrderTP\_Items_tp.

ENDCLASS.


CLASS lhc_OrderTP IMPLEMENTATION.
  METHOD get_instance_features.
    IF keys IS INITIAL.
      APPEND INITIAL LINE TO reported-%other ASSIGNING FIELD-SYMBOL(<lo_reported>).
      <lo_reported> = new_message( id       = zpru_if_m_po=>gc_po_message_class
                                   number   = '001'
                                   severity = if_abap_behv_message=>severity-error ).
      RETURN.
    ENDIF.

    READ ENTITIES OF zpru_u_purcorderhdr_tp
         IN LOCAL MODE
         ENTITY OrderTP
         FIELDS ( status )
         WITH CORRESPONDING #( keys )
         RESULT DATA(lt_roots).

    IF lt_roots IS INITIAL.
      APPEND INITIAL LINE TO reported-%other ASSIGNING <lo_reported>.
      <lo_reported> = new_message( id       = zpru_if_m_po=>gc_po_message_class
                                   number   = '002'
                                   severity = if_abap_behv_message=>severity-error ).
      RETURN.
    ENDIF.

    LOOP AT keys ASSIGNING FIELD-SYMBOL(<ls_key>).

      ASSIGN lt_roots[ KEY id COMPONENTS %tky = <ls_key>-%tky ] TO FIELD-SYMBOL(<ls_instance>).
      IF sy-subrc <> 0.
        APPEND INITIAL LINE TO failed-ordertp ASSIGNING FIELD-SYMBOL(<ls_failed>).
        <ls_failed>-%tky = <ls_instance>-%tky.
        <ls_failed>-%fail-cause = if_abap_behv=>cause-not_found.
        CONTINUE.
      ENDIF.

      IF <ls_instance>-status = zpru_if_m_po=>cs_status-completed.
        APPEND INITIAL LINE TO result ASSIGNING FIELD-SYMBOL(<ls_result>).
        <ls_result>-%is_draft       = <ls_key>-%is_draft.
        <ls_result>-purchaseorderid = <ls_key>-purchaseOrderId.
        <ls_result>-%features-%field-PaymentTerms = if_abap_behv=>fc-f-read_only.
        <ls_result>-%features-%delete             = if_abap_behv=>fc-o-disabled.
      ENDIF.
    ENDLOOP.
  ENDMETHOD.

  METHOD get_instance_authorizations.
    DATA lt_order_read_in TYPE TABLE FOR READ IMPORT zpru_u_purcorderhdr_tp\\OrderTP. " qqq change to your type

    IF keys IS INITIAL.
      APPEND INITIAL LINE TO reported-%other ASSIGNING FIELD-SYMBOL(<lo_reported>).
      <lo_reported> = new_message( id       = zpru_if_m_po=>gc_po_message_class
                                   number   = '001'
                                   severity = if_abap_behv_message=>severity-error ).
      RETURN.
    ENDIF.

    lt_order_read_in = CORRESPONDING #( keys ).

    READ ENTITIES OF zpru_u_purcorderhdr_tp
         IN LOCAL MODE
         ENTITY OrderTP
         FIELDS ( status )
         WITH lt_order_read_in
         RESULT DATA(lt_roots).

    IF lt_roots IS INITIAL.
      APPEND INITIAL LINE TO reported-%other ASSIGNING <lo_reported>.
      <lo_reported> = new_message( id       = zpru_if_m_po=>gc_po_message_class
                                   number   = '002'
                                   severity = if_abap_behv_message=>severity-error ).
      RETURN.
    ENDIF.

    LOOP AT keys ASSIGNING FIELD-SYMBOL(<ls_key>).

      ASSIGN lt_roots[ KEY id COMPONENTS %tky = <ls_key>-%tky ] TO FIELD-SYMBOL(<ls_instance>).
      IF sy-subrc <> 0.
        APPEND INITIAL LINE TO failed-ordertp ASSIGNING FIELD-SYMBOL(<ls_failed>).
        <ls_failed>-%tky = <ls_instance>-%tky.
        <ls_failed>-%fail-cause = if_abap_behv=>cause-not_found.
        CONTINUE.
      ENDIF.

      IF <ls_instance>-status = zpru_if_m_po=>cs_status-archived.
        APPEND INITIAL LINE TO result ASSIGNING FIELD-SYMBOL(<ls_result>).
        <ls_result>-%is_draft       = <ls_key>-%is_draft.
        <ls_result>-purchaseorderid = <ls_key>-purchaseOrderId.
        <ls_result>-%update         = if_abap_behv=>auth-unauthorized.
        <ls_result>-%delete         = if_abap_behv=>auth-unauthorized.
        <ls_result>-%action-edit               = if_abap_behv=>auth-unauthorized.
        <ls_result>-%action-createfromtemplate = if_abap_behv=>auth-unauthorized.

        IF    requested_authorizations-%action-Edit = if_abap_behv=>mk-on
           OR requested_authorizations-%delete      = if_abap_behv=>mk-on.
          APPEND INITIAL LINE TO failed-ordertp ASSIGNING <ls_failed>.
          <ls_failed>-%tky = <ls_instance>-%tky.
          <ls_failed>-%fail-cause = if_abap_behv=>cause-unauthorized.

          APPEND INITIAL LINE TO reported-ordertp ASSIGNING FIELD-SYMBOL(<lo_order>).
          <lo_order>-%tky = <ls_instance>-%tky.
          <lo_order>-%msg = new_message( id       = zpru_if_m_po=>gc_po_message_class
                                         number   = '004'
                                         severity = if_abap_behv_message=>severity-error ).
        ENDIF.

      ELSE.
        APPEND INITIAL LINE TO result ASSIGNING <ls_result>.
        <ls_result>-%is_draft       = <ls_key>-%is_draft.
        <ls_result>-purchaseorderid = <ls_key>-purchaseOrderId.
        <ls_result>-%update         = if_abap_behv=>auth-allowed.
        <ls_result>-%delete         = if_abap_behv=>auth-allowed.
        <ls_result>-%action-edit               = if_abap_behv=>auth-allowed.
        <ls_result>-%action-changestatus       = if_abap_behv=>auth-allowed.
        <ls_result>-%action-createfromtemplate = if_abap_behv=>auth-allowed.
      ENDIF.
    ENDLOOP.
  ENDMETHOD.

  METHOD get_global_authorizations.
  ENDMETHOD.

  METHOD create.
    lcl_buffer=>prep_root_buffer( CORRESPONDING #( entities MAPPING is_draft = %is_draft
                                                                    purchaseorderid = purchaseOrderId ) ).

    LOOP AT entities ASSIGNING FIELD-SYMBOL(<ls_create>).

      IF    NOT line_exists( lcl_buffer=>root_buffer[ instance-purchaseOrderId = <ls_create>-purchaseOrderId
                                                      is_draft                 = <ls_create>-%is_draft ] )
         OR     line_exists( lcl_buffer=>root_buffer[ instance-purchaseOrderId = <ls_create>-purchaseOrderId
                                                      is_draft                 = <ls_create>-%is_draft
                                                      deleted                  = abap_true ] ).

        DELETE lcl_buffer=>root_buffer WHERE     instance-purchaseOrderId = VALUE #( lcl_buffer=>root_buffer[
                                                                                         instance-purchaseOrderId = <ls_create>-purchaseOrderId
                                                                                         is_draft                 = <ls_create>-%is_draft ]-instance-purchaseOrderId OPTIONAL )
                                             AND is_draft                 = <ls_create>-%is_draft
                                             AND deleted                  = abap_true.

        APPEND VALUE #(
            cid                       = <ls_create>-%cid
            is_draft                  = <ls_create>-%is_draft
            instance-purchaseOrderId  = <ls_create>-purchaseOrderId
            instance-orderDate        = COND #( WHEN <ls_create>-%control-orderDate <> if_abap_behv=>mk-off
                                                THEN <ls_create>-orderDate )
            instance-supplierId       = COND #( WHEN <ls_create>-%control-supplierId <> if_abap_behv=>mk-off
                                                THEN <ls_create>-supplierId )
            instance-supplierName     = COND #( WHEN <ls_create>-%control-supplierName <> if_abap_behv=>mk-off
                                                THEN <ls_create>-supplierName )
            instance-buyerId          = COND #( WHEN <ls_create>-%control-buyerId <> if_abap_behv=>mk-off
                                                THEN <ls_create>-buyerId )
            instance-buyerName        = COND #( WHEN <ls_create>-%control-buyerName <> if_abap_behv=>mk-off
                                                THEN <ls_create>-buyerName )
            instance-totalAmount      = COND #( WHEN <ls_create>-%control-totalAmount <> if_abap_behv=>mk-off
                                                THEN <ls_create>-totalAmount )
            instance-headerCurrency   = COND #( WHEN <ls_create>-%control-headerCurrency <> if_abap_behv=>mk-off
                                                THEN <ls_create>-headerCurrency )
            instance-deliveryDate     = COND #( WHEN <ls_create>-%control-deliveryDate <> if_abap_behv=>mk-off
                                                THEN <ls_create>-deliveryDate )
            instance-status           = COND #( WHEN <ls_create>-%control-status <> if_abap_behv=>mk-off
                                                THEN <ls_create>-status )
            instance-paymentTerms     = COND #( WHEN <ls_create>-%control-paymentTerms <> if_abap_behv=>mk-off
                                                THEN <ls_create>-paymentTerms )
            instance-shippingMethod   = COND #( WHEN <ls_create>-%control-shippingMethod <> if_abap_behv=>mk-off
                                                THEN <ls_create>-shippingMethod )
            instance-controlTimestamp = COND #( WHEN <ls_create>-%control-controlTimestamp <> if_abap_behv=>mk-off
                                                THEN <ls_create>-controlTimestamp )
            instance-createdBy        = COND #( WHEN <ls_create>-%control-createdBy <> if_abap_behv=>mk-off
                                                THEN <ls_create>-createdBy )
            instance-createOn         = COND #( WHEN <ls_create>-%control-createOn <> if_abap_behv=>mk-off
                                                THEN <ls_create>-createOn )
            instance-changedBy        = COND #( WHEN <ls_create>-%control-changedBy <> if_abap_behv=>mk-off
                                                THEN <ls_create>-changedBy )
            instance-changedOn        = COND #( WHEN <ls_create>-%control-changedOn <> if_abap_behv=>mk-off
                                                THEN <ls_create>-changedOn )
            " qqq make sure that your made you admin fields managed by RAP framework
            " it is expected that createOn already have been filled by time value
            " otherwise check semantic annotation on your transactional CDS
            instance-lastChanged      = <ls_create>-createOn

            newly_created             = abap_true " qqq to raise event on order creation I must distinct created and updated instances
            " alternatively we can check db via select, but flag is likely be easier.

            changed                   = abap_true
            deleted                   = abap_false ) TO lcl_buffer=>root_buffer.

        INSERT VALUE #( %cid      = <ls_create>-%cid
                        %key      = <ls_create>-%key
                        %is_draft = <ls_create>-%is_draft ) INTO TABLE mapped-ordertp.

        APPEND VALUE #( %msg            = new_message_with_text( severity = if_abap_behv_message=>severity-success
                                                                 text     = 'create: Ok!' )
                        purchaseOrderId = <ls_create>-purchaseOrderId
                        %cid            = <ls_create>-%cid
                        %is_draft       = <ls_create>-%is_draft ) TO reported-ordertp.

      ELSE.

        APPEND VALUE #( %cid        = <ls_create>-%cid
                        %key        = <ls_create>-%key
                        %is_draft   = <ls_create>-%is_draft
                        %create     = if_abap_behv=>mk-on
                        %fail-cause = if_abap_behv=>cause-unspecific )
               TO failed-ordertp.

        APPEND VALUE #( %cid      = <ls_create>-%cid
                        %key      = <ls_create>-%key
                        %is_draft = <ls_create>-%is_draft
                        %create   = if_abap_behv=>mk-on
                        %msg      = new_message_with_text( severity = if_abap_behv_message=>severity-error
                                                           text     = 'Create operation failed.' ) )
               TO reported-ordertp.

      ENDIF.
    ENDLOOP.
  ENDMETHOD.

  METHOD precheck_create.
    SELECT purchaseOrderId FROM zpru_u_purcorderhdr_tp " qqq use your transactional CDS
      FOR ALL ENTRIES IN @entities
      WHERE purchaseOrderId = @entities-purchaseOrderId
      INTO TABLE @DATA(lt_existing_po).

    LOOP AT entities ASSIGNING FIELD-SYMBOL(<ls_entity>).
      IF NOT line_exists( lt_existing_po[ table_line = <ls_entity>-purchaseOrderId ] ).
        CONTINUE.
      ENDIF.

      APPEND INITIAL LINE TO failed-ordertp ASSIGNING FIELD-SYMBOL(<ls_order_failed>).
      <ls_order_failed>-%cid      = <ls_entity>-%cid.
      <ls_order_failed>-%key      = <ls_entity>-%key.
      <ls_order_failed>-%is_draft = <ls_entity>-%is_draft.
      <ls_order_failed>-%create   = if_abap_behv=>mk-on.

      APPEND VALUE #( %cid      = <ls_entity>-%cid
                      %key      = <ls_entity>-%key
                      %is_draft = <ls_entity>-%is_draft
                      %create   = if_abap_behv=>mk-on
                      %msg      = new_message_with_text( severity = if_abap_behv_message=>severity-error
                                                         text     = 'Duplicate in DB' ) )
             TO reported-ordertp.
    ENDLOOP.
  ENDMETHOD.

  METHOD update.
    lcl_buffer=>prep_root_buffer( CORRESPONDING #( entities MAPPING purchaseorderid = purchaseOrderId
                                                                    is_draft        = %is_draft ) ).

    LOOP AT entities ASSIGNING FIELD-SYMBOL(<ls_update>).

      READ TABLE lcl_buffer=>root_buffer
           WITH KEY instance-purchaseOrderId = <ls_update>-purchaseOrderId
                    is_draft                 = <ls_update>-%is_draft
                    deleted                  = abap_false ASSIGNING FIELD-SYMBOL(<ls_up>).
      IF sy-subrc = 0.
        <ls_up>-instance-orderDate        = COND #( WHEN <ls_update>-%control-orderDate <> if_abap_behv=>mk-off
                                                    THEN <ls_update>-orderDate
                                                    ELSE <ls_up>-instance-orderDate ).
        <ls_up>-instance-supplierId       = COND #( WHEN <ls_update>-%control-supplierId <> if_abap_behv=>mk-off
                                                    THEN <ls_update>-supplierId
                                                    ELSE <ls_up>-instance-supplierId ).
        <ls_up>-instance-supplierName     = COND #( WHEN <ls_update>-%control-supplierName <> if_abap_behv=>mk-off
                                                    THEN <ls_update>-supplierName
                                                    ELSE <ls_up>-instance-supplierName ).
        <ls_up>-instance-buyerId          = COND #( WHEN <ls_update>-%control-buyerId <> if_abap_behv=>mk-off
                                                    THEN <ls_update>-buyerId
                                                    ELSE <ls_up>-instance-buyerId ).
        <ls_up>-instance-buyerName        = COND #( WHEN <ls_update>-%control-buyerName <> if_abap_behv=>mk-off
                                                    THEN <ls_update>-buyerName
                                                    ELSE <ls_up>-instance-buyerName ).
        <ls_up>-instance-totalAmount      = COND #( WHEN <ls_update>-%control-totalAmount <> if_abap_behv=>mk-off
                                                    THEN <ls_update>-totalAmount
                                                    ELSE <ls_up>-instance-totalAmount ).
        <ls_up>-instance-headerCurrency   = COND #( WHEN <ls_update>-%control-headerCurrency <> if_abap_behv=>mk-off
                                                    THEN <ls_update>-headerCurrency
                                                    ELSE <ls_up>-instance-headerCurrency ).
        <ls_up>-instance-deliveryDate     = COND #( WHEN <ls_update>-%control-deliveryDate <> if_abap_behv=>mk-off
                                                    THEN <ls_update>-deliveryDate
                                                    ELSE <ls_up>-instance-deliveryDate ).
        <ls_up>-instance-status           = COND #( WHEN <ls_update>-%control-status <> if_abap_behv=>mk-off
                                                    THEN <ls_update>-status
                                                    ELSE <ls_up>-instance-status ).
        <ls_up>-instance-paymentTerms     = COND #( WHEN <ls_update>-%control-paymentTerms <> if_abap_behv=>mk-off
                                                    THEN <ls_update>-paymentTerms
                                                    ELSE <ls_up>-instance-paymentTerms ).
        <ls_up>-instance-shippingMethod   = COND #( WHEN <ls_update>-%control-shippingMethod <> if_abap_behv=>mk-off
                                                    THEN <ls_update>-shippingMethod
                                                    ELSE <ls_up>-instance-shippingMethod ).
        <ls_up>-instance-controlTimestamp = COND #( WHEN <ls_update>-%control-controlTimestamp <> if_abap_behv=>mk-off
                                                    THEN <ls_update>-controlTimestamp
                                                    ELSE <ls_up>-instance-controlTimestamp ).
        <ls_up>-instance-createdBy        = COND #( WHEN <ls_update>-%control-createdBy <> if_abap_behv=>mk-off
                                                    THEN <ls_update>-createdBy
                                                    ELSE <ls_up>-instance-createdBy ).
        <ls_up>-instance-createOn         = COND #( WHEN <ls_update>-%control-createOn <> if_abap_behv=>mk-off
                                                    THEN <ls_update>-createOn
                                                    ELSE <ls_up>-instance-createOn ).
        <ls_up>-instance-changedBy        = COND #( WHEN <ls_update>-%control-changedBy <> if_abap_behv=>mk-off
                                                    THEN <ls_update>-changedBy
                                                    ELSE <ls_up>-instance-changedBy ).
        <ls_up>-instance-changedOn        = COND #( WHEN <ls_update>-%control-changedOn <> if_abap_behv=>mk-off
                                                    THEN <ls_update>-changedOn
                                                    ELSE <ls_up>-instance-changedOn ).
        " qqq make sure that your made you admin fields managed by RAP framework
        " it is expected that createOn already have been filled by time value
        " otherwise check semantic annotation on your transactional CDS
        <ls_up>-instance-lastChanged      = COND #( WHEN <ls_update>-changedOn IS NOT INITIAL
                                                    THEN <ls_update>-changedOn
                                                    ELSE <ls_up>-instance-lastChanged ).
        <ls_up>-changed = abap_true.
        <ls_up>-deleted = abap_false.
      ELSE.

        APPEND VALUE #( %tky        = <ls_update>-%tky
                        %cid        = <ls_update>-%cid_ref
                        %fail-cause = if_abap_behv=>cause-not_found
                        %update     = if_abap_behv=>mk-on )
               TO failed-ordertp.

        APPEND VALUE #( %tky = <ls_update>-%tky
                        %cid = <ls_update>-%cid_ref
                        %msg = new_message_with_text( severity = if_abap_behv_message=>severity-error
                                                      text     = 'Update operation failed.' ) )
               TO reported-ordertp.

      ENDIF.
    ENDLOOP.
  ENDMETHOD.

  METHOD precheck_update.
  ENDMETHOD.

  METHOD delete.
    lcl_buffer=>prep_root_buffer( CORRESPONDING #( keys MAPPING purchaseorderid = purchaseOrderId
                                                                is_draft        = %is_draft ) ).

    lcl_buffer=>prep_child_buffer( CORRESPONDING #( keys MAPPING purchaseorderid = purchaseOrderId
                                                                 is_draft        = %is_draft ) ).

    LOOP AT keys ASSIGNING FIELD-SYMBOL(<ls_delete>).
      READ TABLE lcl_buffer=>root_buffer
           WITH KEY instance-purchaseOrderId = <ls_delete>-purchaseOrderId
                    is_draft                 = <ls_delete>-%is_draft
                    deleted                  = abap_false ASSIGNING FIELD-SYMBOL(<ls_del>).

      IF sy-subrc = 0.

        <ls_del>-newly_created = abap_false. " qqq for event on created order

        <ls_del>-changed       = abap_false.
        <ls_del>-deleted       = abap_true.
        " qqq cascade delete
        LOOP AT lcl_buffer=>child_buffer ASSIGNING FIELD-SYMBOL(<ls_child_del>)
             WHERE     instance-purchaseOrderId = <ls_del>-instance-purchaseOrderId
                   AND is_draft                 = <ls_del>-is_draft
                   AND deleted                  = abap_false.
          <ls_child_del>-changed = abap_false.
          <ls_child_del>-deleted = abap_true.
        ENDLOOP.
      ELSE.
        APPEND VALUE #( %tky        = <ls_delete>-%tky
                        %cid        = <ls_delete>-%cid_ref
                        %fail-cause = if_abap_behv=>cause-not_found
                        %delete     = if_abap_behv=>mk-on ) TO failed-ordertp.

        APPEND VALUE #( %tky = <ls_delete>-%tky
                        %cid = <ls_delete>-%cid_ref
                        %msg = new_message_with_text( severity = if_abap_behv_message=>severity-error
                                                      text     = 'Delete operation failed.' ) ) TO reported-ordertp.
      ENDIF.
    ENDLOOP.
  ENDMETHOD.

  METHOD precheck_delete.
  ENDMETHOD.

  METHOD read.
    lcl_buffer=>prep_root_buffer( CORRESPONDING #( keys MAPPING purchaseorderid = purchaseOrderId
                                                                is_draft        = %is_draft ) ).

    LOOP AT keys ASSIGNING FIELD-SYMBOL(<ls_read>) GROUP BY <ls_read>-%tky.
      READ TABLE lcl_buffer=>root_buffer
           WITH KEY instance-purchaseOrderId = <ls_read>-purchaseOrderId
                    is_draft                 = <ls_read>-%is_draft
                    deleted                  = abap_false ASSIGNING FIELD-SYMBOL(<ls_r>).
      IF sy-subrc = 0.

        APPEND VALUE #( %tky             = <ls_read>-%tky
                        orderDate        = COND #( WHEN <ls_read>-%control-orderDate <> if_abap_behv=>mk-off
                                                   THEN <ls_r>-instance-orderDate )
                        supplierId       = COND #( WHEN <ls_read>-%control-supplierId <> if_abap_behv=>mk-off
                                                   THEN <ls_r>-instance-supplierId )
                        supplierName     = COND #( WHEN <ls_read>-%control-supplierName <> if_abap_behv=>mk-off
                                                   THEN <ls_r>-instance-supplierName )
                        buyerId          = COND #( WHEN <ls_read>-%control-buyerId <> if_abap_behv=>mk-off
                                                   THEN <ls_r>-instance-buyerId )
                        buyerName        = COND #( WHEN <ls_read>-%control-buyerName <> if_abap_behv=>mk-off
                                                   THEN <ls_r>-instance-buyerName )
                        totalAmount      = COND #( WHEN <ls_read>-%control-totalAmount <> if_abap_behv=>mk-off
                                                   THEN <ls_r>-instance-totalAmount )
                        headerCurrency   = COND #( WHEN <ls_read>-%control-headerCurrency <> if_abap_behv=>mk-off
                                                   THEN <ls_r>-instance-headerCurrency )
                        deliveryDate     = COND #( WHEN <ls_read>-%control-deliveryDate <> if_abap_behv=>mk-off
                                                   THEN <ls_r>-instance-deliveryDate )
                        status           = COND #( WHEN <ls_read>-%control-status <> if_abap_behv=>mk-off
                                                   THEN <ls_r>-instance-status )
                        paymentTerms     = COND #( WHEN <ls_read>-%control-paymentTerms <> if_abap_behv=>mk-off
                                                   THEN <ls_r>-instance-paymentTerms )
                        shippingMethod   = COND #( WHEN <ls_read>-%control-shippingMethod <> if_abap_behv=>mk-off
                                                   THEN <ls_r>-instance-shippingMethod )
                        controlTimestamp = COND #( WHEN <ls_read>-%control-controlTimestamp <> if_abap_behv=>mk-off
                                                   THEN <ls_r>-instance-controlTimestamp )
                        createdBy        = COND #( WHEN <ls_read>-%control-createdBy <> if_abap_behv=>mk-off
                                                   THEN <ls_r>-instance-createdBy )
                        createOn         = COND #( WHEN <ls_read>-%control-createOn <> if_abap_behv=>mk-off
                                                   THEN <ls_r>-instance-createOn )
                        changedBy        = COND #( WHEN <ls_read>-%control-changedBy <> if_abap_behv=>mk-off
                                                   THEN <ls_r>-instance-changedBy )
                        changedOn        = COND #( WHEN <ls_read>-%control-changedOn <> if_abap_behv=>mk-off
                                                   THEN <ls_r>-instance-changedOn )
                        " qqq you must return the value, otherwise update will not work
                        lastChanged      = COND #( WHEN <ls_read>-%control-lastChanged <> if_abap_behv=>mk-off
                                                   THEN <ls_r>-instance-lastChanged ) ) TO result.

      ELSE.
        APPEND VALUE #( %tky        = <ls_read>-%tky
                        %fail-cause = if_abap_behv=>cause-not_found )
               TO failed-ordertp.

        APPEND VALUE #( %tky = <ls_read>-%tky
                        %msg = new_message_with_text( severity = if_abap_behv_message=>severity-error
                                                      text     = 'Read operation failed.' ) )
               TO reported-ordertp.

      ENDIF.
    ENDLOOP.
  ENDMETHOD.

  METHOD lock.
  ENDMETHOD.

  METHOD rba_Items_tp.
    lcl_buffer=>prep_root_buffer( CORRESPONDING #( keys_rba MAPPING purchaseorderid = purchaseOrderId
                                                                    is_draft        = %is_draft ) ).
    lcl_buffer=>prep_child_buffer( CORRESPONDING #( keys_rba MAPPING purchaseorderid = purchaseOrderId
                                                                    is_draft        = %is_draft ) ).

    LOOP AT keys_rba ASSIGNING FIELD-SYMBOL(<ls_rba>) GROUP BY <ls_rba>-%tky.
      IF     line_exists( lcl_buffer=>root_buffer[ instance-purchaseOrderId = <ls_rba>-purchaseOrderId
                                                   is_draft                 = <ls_rba>-%is_draft
                                                   deleted                  = abap_false ] )
         AND line_exists( lcl_buffer=>child_buffer[ instance-purchaseOrderId = <ls_rba>-purchaseOrderId
                                                    is_draft                 = <ls_rba>-%is_draft
                                                    deleted                  = abap_false ] ).

        LOOP AT lcl_buffer=>child_buffer ASSIGNING FIELD-SYMBOL(<ls_ch>) WHERE     instance-purchaseOrderId = <ls_rba>-purchaseOrderId
                                                                               AND is_draft                 = <ls_rba>-%is_draft
                                                                               AND deleted                  = abap_false.
          INSERT VALUE #( source-%tky = <ls_rba>-%tky
                          target-%tky = VALUE #( purchaseOrderId = <ls_ch>-instance-purchaseOrderId
                                                 itemId          = <ls_ch>-instance-itemId
                                                 %is_draft       = <ls_ch>-is_draft ) ) INTO TABLE association_links.
          IF result_requested = abap_false.
            CONTINUE.
          ENDIF.

          APPEND VALUE #( %tky              = CORRESPONDING #( <ls_rba>-%tky )
                          itemId            = <ls_ch>-instance-itemId
                          itemNumber        = COND #( WHEN <ls_rba>-%control-itemNumber <> if_abap_behv=>mk-off
                                                      THEN <ls_ch>-instance-itemNumber )
                          productId         = COND #( WHEN <ls_rba>-%control-productId <> if_abap_behv=>mk-off
                                                      THEN <ls_ch>-instance-productId )
                          productName       = COND #( WHEN <ls_rba>-%control-productName <> if_abap_behv=>mk-off
                                                      THEN <ls_ch>-instance-productName )
                          quantity          = COND #( WHEN <ls_rba>-%control-quantity <> if_abap_behv=>mk-off
                                                      THEN <ls_ch>-instance-quantity )
                          unitPrice         = COND #( WHEN <ls_rba>-%control-unitPrice <> if_abap_behv=>mk-off
                                                      THEN <ls_ch>-instance-unitPrice )
                          totalPrice        = COND #( WHEN <ls_rba>-%control-totalPrice <> if_abap_behv=>mk-off
                                                      THEN <ls_ch>-instance-totalPrice )
                          deliveryDate      = COND #( WHEN <ls_rba>-%control-deliveryDate <> if_abap_behv=>mk-off
                                                      THEN <ls_ch>-instance-deliveryDate )
                          warehouseLocation = COND #( WHEN <ls_rba>-%control-warehouseLocation <> if_abap_behv=>mk-off
                                                      THEN <ls_ch>-instance-warehouseLocation )
                          itemCurrency      = COND #( WHEN <ls_rba>-%control-itemCurrency <> if_abap_behv=>mk-off
                                                      THEN <ls_ch>-instance-itemCurrency )
                          isUrgent          = COND #( WHEN <ls_rba>-%control-isUrgent <> if_abap_behv=>mk-off
                                                      THEN <ls_ch>-instance-isUrgent )
                          createdBy         = COND #( WHEN <ls_rba>-%control-createdBy <> if_abap_behv=>mk-off
                                                      THEN <ls_ch>-instance-createdBy )
                          createOn          = COND #( WHEN <ls_rba>-%control-createOn <> if_abap_behv=>mk-off
                                                      THEN <ls_ch>-instance-createOn )
                          changedBy         = COND #( WHEN <ls_rba>-%control-changedBy <> if_abap_behv=>mk-off
                                                      THEN <ls_ch>-instance-changedBy )
                          changedOn         = COND #( WHEN <ls_rba>-%control-changedOn <> if_abap_behv=>mk-off
                                                      THEN <ls_ch>-instance-changedOn ) ) TO result.
        ENDLOOP.

      ELSE.

        APPEND VALUE #( %tky             = <ls_rba>-%tky
                        %fail-cause      = if_abap_behv=>cause-not_found
                        %assoc-_items_tp = if_abap_behv=>mk-on )
               TO failed-ordertp.

        APPEND VALUE #( %tky = <ls_rba>-%tky
                        %msg = new_message_with_text( severity = if_abap_behv_message=>severity-error
                                                      text     = 'RBA operation (parent to child) failed.' ) )
               TO reported-ordertp.

      ENDIF.
    ENDLOOP.

    " Removing potential duplicate entries
    SORT association_links BY target ASCENDING.
    DELETE ADJACENT DUPLICATES FROM association_links COMPARING ALL FIELDS.

    SORT result BY %tky ASCENDING.
    DELETE ADJACENT DUPLICATES FROM result COMPARING ALL FIELDS.
  ENDMETHOD.

  METHOD cba_Items_tp.
    DATA lt_root_update TYPE TABLE FOR UPDATE zpru_u_purcorderhdr_tp\\OrderTP. " qqq change names on your BDEF

    lcl_buffer=>prep_root_buffer( CORRESPONDING #( entities_cba MAPPING purchaseorderid = purchaseorderid
                                                                        is_draft        = %is_draft ) ).
    lcl_buffer=>prep_child_buffer( CORRESPONDING #( entities_cba MAPPING purchaseorderid = purchaseorderid
                                                                        is_draft        = %is_draft ) ).
    LOOP AT entities_cba ASSIGNING FIELD-SYMBOL(<ls_cba>) GROUP BY <ls_cba>-%tky.
      IF line_exists( lcl_buffer=>root_buffer[ instance-purchaseOrderId = <ls_cba>-purchaseOrderId
                                               is_draft                 = <ls_cba>-%is_draft
                                               deleted                  = abap_false ] ).

        LOOP AT <ls_cba>-%target ASSIGNING FIELD-SYMBOL(<ls_ch>).

          IF     (    NOT line_exists( lcl_buffer=>child_buffer[ instance-purchaseOrderId = <ls_cba>-purchaseOrderId
                                                                 is_draft                 = <ls_cba>-%is_draft
                                                                 instance-itemId          = <ls_ch>-itemId ] )
                   OR
                          line_exists( lcl_buffer=>child_buffer[ instance-purchaseOrderId = <ls_cba>-purchaseOrderId
                                                                 instance-itemId          = <ls_ch>-itemId
                                                                 is_draft                 = <ls_cba>-%is_draft
                                                                 deleted                  = abap_true ] ) )

             AND <ls_ch>-itemId IS NOT INITIAL.

            ASSIGN lcl_buffer=>child_buffer[ instance-purchaseOrderId = <ls_cba>-purchaseOrderId
                                             is_draft                 = <ls_cba>-%is_draft
                                             instance-itemId          = <ls_ch>-itemId
                                             deleted                  = abap_true ] TO FIELD-SYMBOL(<ls_deleted_item>).
            IF sy-subrc = 0.
              DELETE lcl_buffer=>child_buffer
                     WHERE     instance-purchaseOrderId = <ls_deleted_item>-instance-purchaseOrderId
                           AND instance-itemId          = <ls_deleted_item>-instance-itemId
                           AND is_draft                 = <ls_deleted_item>-is_draft
                           AND deleted                  = abap_true.
            ENDIF.

            APPEND VALUE #(
                cid_ref                    = <ls_cba>-%cid_ref
                cid_target                 = <ls_ch>-%cid
                is_draft                   = <ls_cba>-%is_draft
                instance-purchaseOrderId   = <ls_cba>-purchaseOrderId
                instance-itemId            = <ls_ch>-itemId
                instance-itemNumber        = COND #( WHEN <ls_ch>-%control-itemNumber <> if_abap_behv=>mk-off
                                                     THEN <ls_ch>-itemNumber )
                instance-productId         = COND #( WHEN <ls_ch>-%control-productId <> if_abap_behv=>mk-off
                                                     THEN <ls_ch>-productId )
                instance-productName       = COND #( WHEN <ls_ch>-%control-productName <> if_abap_behv=>mk-off
                                                     THEN <ls_ch>-productName )
                instance-quantity          = COND #( WHEN <ls_ch>-%control-quantity <> if_abap_behv=>mk-off
                                                     THEN <ls_ch>-quantity )
                instance-unitPrice         = COND #( WHEN <ls_ch>-%control-unitPrice <> if_abap_behv=>mk-off
                                                     THEN <ls_ch>-unitPrice )
                instance-totalPrice        = COND #( WHEN <ls_ch>-%control-totalPrice <> if_abap_behv=>mk-off
                                                     THEN <ls_ch>-totalPrice )
                instance-deliveryDate      = COND #( WHEN <ls_ch>-%control-deliveryDate <> if_abap_behv=>mk-off
                                                     THEN <ls_ch>-deliveryDate )
                instance-warehouseLocation = COND #( WHEN <ls_ch>-%control-warehouseLocation <> if_abap_behv=>mk-off
                                                     THEN <ls_ch>-warehouseLocation )
                instance-itemCurrency      = COND #( WHEN <ls_ch>-%control-itemCurrency <> if_abap_behv=>mk-off
                                                     THEN <ls_ch>-itemCurrency )
                instance-isUrgent          = COND #( WHEN <ls_ch>-%control-isUrgent <> if_abap_behv=>mk-off
                                                     THEN <ls_ch>-isUrgent )
                instance-createdBy         = COND #( WHEN <ls_ch>-%control-createdBy <> if_abap_behv=>mk-off
                                                     THEN <ls_ch>-createdBy )
                instance-createOn          = COND #( WHEN <ls_ch>-%control-createOn <> if_abap_behv=>mk-off
                                                     THEN <ls_ch>-createOn )
                instance-changedBy         = COND #( WHEN <ls_ch>-%control-changedBy <> if_abap_behv=>mk-off
                                                     THEN <ls_ch>-changedBy )
                instance-changedOn         = COND #( WHEN <ls_ch>-%control-changedOn <> if_abap_behv=>mk-off
                                                     THEN <ls_ch>-changedOn )
                changed                    = abap_true ) TO lcl_buffer=>child_buffer.

            APPEND INITIAL LINE TO lt_root_update ASSIGNING FIELD-SYMBOL(<ls_root_update>).
            <ls_root_update>-purchaseOrderId = <ls_cba>-purchaseOrderId.
            <ls_root_update>-%is_draft       = <ls_cba>-%is_draft.

            INSERT VALUE #( %cid      = <ls_ch>-%cid
                            %is_draft = <ls_cba>-%is_draft
                            %key      = VALUE #( purchaseOrderId = <ls_cba>-purchaseOrderId
                                                 itemId          = <ls_ch>-itemId ) ) INTO TABLE mapped-itemtp.

          ELSE.

            APPEND VALUE #( %cid             = <ls_cba>-%cid_ref
                            %tky             = <ls_cba>-%tky
                            %assoc-_items_tp = if_abap_behv=>mk-on
                            %fail-cause      = if_abap_behv=>cause-unspecific ) TO failed-ordertp.

            APPEND VALUE #( %cid = <ls_cba>-%cid_ref
                            %tky = <ls_cba>-%tky
                            %msg = new_message_with_text( severity = if_abap_behv_message=>severity-error
                                                          text     = 'CBA operatoion (root to child) failed.' ) )
                   TO reported-ordertp.

            APPEND VALUE #( %cid        = <ls_ch>-%cid
                            %key        = VALUE #( purchaseOrderId = <ls_cba>-purchaseOrderId
                                                   itemId          = <ls_ch>-itemId )
                            %fail-cause = if_abap_behv=>cause-dependency ) TO failed-itemtp.

            APPEND VALUE #( %cid = <ls_ch>-%cid
                            %key = VALUE #( purchaseOrderId = <ls_cba>-purchaseOrderId
                                            itemId          = <ls_ch>-itemId )
                            %msg = new_message_with_text( severity = if_abap_behv_message=>severity-error
                                                          text     = 'CBA operation (root to child) failed.' ) )
                   TO reported-itemtp.

          ENDIF.
        ENDLOOP.

        SORT lt_root_update BY purchaseOrderId
                               %is_draft.
        DELETE ADJACENT DUPLICATES FROM lt_root_update COMPARING purchaseOrderId %is_draft.

        GET TIME STAMP FIELD DATA(lv_now). " qqq if added item -- update etag field
        LOOP AT lt_root_update ASSIGNING <ls_root_update>.
          <ls_root_update>-changedOn = lv_now.
          <ls_root_update>-%control-changedOn = if_abap_behv=>mk-on.
        ENDLOOP.

        IF lt_root_update IS NOT INITIAL.
          MODIFY ENTITIES OF zpru_u_purcorderhdr_tp  " qqq change on your BDEF
                 IN LOCAL MODE
                 ENTITY OrderTP UPDATE FROM lt_root_update.
        ENDIF.

      ELSE.

        APPEND VALUE #( %cid             = <ls_cba>-%cid_ref
                        %tky             = <ls_cba>-%tky
                        %assoc-_items_tp = if_abap_behv=>mk-on
                        %fail-cause      = if_abap_behv=>cause-not_found )
               TO failed-ordertp.

        APPEND VALUE #( %cid = <ls_cba>-%cid_ref
                        %tky = <ls_cba>-%tky
                        %msg = new_message_with_text( severity = if_abap_behv_message=>severity-error
                                                      text     = 'CBA operation (root to child) failed.' ) )
               TO reported-ordertp.

        LOOP AT <ls_cba>-%target ASSIGNING FIELD-SYMBOL(<ls_target>).
          APPEND VALUE #( %cid        = <ls_target>-%cid
                          %key        = <ls_target>-%key
                          %fail-cause = if_abap_behv=>cause-dependency )
                 TO failed-itemtp.

          APPEND VALUE #( %cid = <ls_target>-%cid
                          %key = <ls_target>-%key
                          %msg = new_message_with_text( severity = if_abap_behv_message=>severity-error
                                                        text     = 'CBA operation (root to child) failed.' ) )
                 TO reported-itemtp.
        ENDLOOP.
      ENDIF.
    ENDLOOP.
  ENDMETHOD.

  METHOD getAllItems.
  ENDMETHOD.

  METHOD getMajorSupplier.
  ENDMETHOD.

  METHOD getStatusHistory.
  ENDMETHOD.

  METHOD isSupplierBlacklisted.
  ENDMETHOD.

  METHOD Activate.
    READ ENTITIES OF zpru_u_purcorderhdr_tp " use your base BDEF
         IN LOCAL MODE
         ENTITY OrderTP
         ALL FIELDS WITH VALUE #( FOR <ls_k1>
                                  IN keys
                                  ( purchaseOrderId = <ls_k1>-purchaseOrderId
                                    %is_draft       = if_abap_behv=>mk-on ) )
         RESULT DATA(lt_order_draft).

    READ ENTITIES OF zpru_u_purcorderhdr_tp " use your base BDEF
         IN LOCAL MODE
         ENTITY OrderTP BY \_items_tp
         ALL FIELDS WITH VALUE #( FOR <ls_k2>
                                  IN keys
                                  ( purchaseOrderId = <ls_k2>-purchaseOrderId
                                    %is_draft       = if_abap_behv=>mk-on ) )
         RESULT DATA(lt_items_draft).

    lcl_buffer=>prep_root_buffer( VALUE #( FOR <ls_k3>
                                           IN keys
                                           ( purchaseOrderId = <ls_k3>-purchaseOrderId
                                             is_draft        = if_abap_behv=>mk-off ) ) ).

    lcl_buffer=>prep_child_buffer( VALUE #( FOR <ls_k4>
                                            IN keys
                                            ( purchaseOrderId = <ls_k4>-purchaseOrderId
                                              is_draft        = if_abap_behv=>mk-off ) ) ).

    LOOP AT lt_order_draft ASSIGNING FIELD-SYMBOL(<ls_order_draft>).

      DELETE lcl_buffer=>root_buffer WHERE     instance-purchaseOrderId = <ls_order_draft>-purchaseOrderId
                                           AND is_draft                 = if_abap_behv=>mk-on
                                           AND deleted                  = abap_false.

      LOOP AT lt_items_draft ASSIGNING FIELD-SYMBOL(<ls_item_draft>)
           WHERE purchaseOrderId = <ls_order_draft>-purchaseOrderId.

        DELETE lcl_buffer=>child_buffer WHERE     instance-purchaseOrderId = <ls_item_draft>-purchaseOrderId
                                              AND instance-itemId          = <ls_item_draft>-itemId
                                              AND is_draft                 = if_abap_behv=>mk-on
                                              AND deleted                  = abap_false.
      ENDLOOP.
    ENDLOOP.
  ENDMETHOD.

  METHOD ChangeStatus.
    DATA lt_po_update TYPE TABLE FOR UPDATE zpru_u_purcorderhdr_tp\\OrderTP. " qqq change on your type

    IF keys IS INITIAL.
      APPEND INITIAL LINE TO reported-%other ASSIGNING FIELD-SYMBOL(<lo_reported>).
      <lo_reported> = new_message( id       = zpru_if_m_po=>gc_po_message_class
                                   number   = '001'
                                   severity = if_abap_behv_message=>severity-error ).
      RETURN.
    ENDIF.

    READ ENTITIES OF zpru_u_purcorderhdr_tp
         IN LOCAL MODE
         ENTITY OrderTP
         ALL FIELDS
         WITH CORRESPONDING #( keys )
         RESULT DATA(lt_roots).

    IF lt_roots IS INITIAL.
      APPEND INITIAL LINE TO reported-%other ASSIGNING <lo_reported>.
      <lo_reported> = new_message( id       = zpru_if_m_po=>gc_po_message_class
                                   number   = '002'
                                   severity = if_abap_behv_message=>severity-error ).
      RETURN.
    ENDIF.

    LOOP AT keys ASSIGNING FIELD-SYMBOL(<ls_key>).

      ASSIGN lt_roots[ KEY id COMPONENTS %tky = <ls_key>-%tky ] TO FIELD-SYMBOL(<ls_instance>).
      IF sy-subrc <> 0.
        APPEND INITIAL LINE TO failed-ordertp ASSIGNING FIELD-SYMBOL(<ls_failed>).
        <ls_failed>-%tky = <ls_instance>-%tky.
        <ls_failed>-%fail-cause = if_abap_behv=>cause-not_found.
        <ls_failed>-%action-ChangeStatus = if_abap_behv=>mk-on.
        CONTINUE.
      ENDIF.

      APPEND INITIAL LINE TO lt_po_update ASSIGNING FIELD-SYMBOL(<ls_order_update>).
      <ls_order_update>-%tky = <ls_instance>-%tky.
      <ls_order_update>-%data-Status = <ls_key>-%param-newstatus.
      <ls_order_update>-%control-Status = if_abap_behv=>mk-on.

    ENDLOOP.

    " update status
    IF lt_po_update IS NOT INITIAL.
      MODIFY ENTITIES OF zpru_u_purcorderhdr_tp
             IN LOCAL MODE
             ENTITY OrderTP
             UPDATE FROM lt_po_update.
    ENDIF.
  ENDMETHOD.

  METHOD precheck_ChangeStatus.
  ENDMETHOD.

  METHOD createFromTemplate.
  ENDMETHOD.

  METHOD Discard.
    lcl_buffer=>prep_root_buffer( VALUE #( FOR <ls_k3>
                                           IN keys
                                           ( purchaseOrderId = <ls_k3>-purchaseOrderId
                                             is_draft        = if_abap_behv=>mk-off ) ) ).

    lcl_buffer=>prep_child_buffer( VALUE #( FOR <ls_k4>
                                            IN keys
                                            ( purchaseOrderId = <ls_k4>-purchaseOrderId
                                              is_draft        = if_abap_behv=>mk-off ) ) ).

    LOOP AT keys ASSIGNING FIELD-SYMBOL(<ls_key>).

      DELETE lcl_buffer=>root_buffer WHERE     instance-purchaseOrderId = <ls_key>-purchaseOrderId
                                           AND is_draft                 = if_abap_behv=>mk-on
                                           AND deleted                  = abap_false.

      DELETE lcl_buffer=>child_buffer
             WHERE     instance-purchaseOrderId = <ls_key>-purchaseOrderId
                   AND is_draft                 = if_abap_behv=>mk-on
                   AND deleted                  = abap_false.
    ENDLOOP.
  ENDMETHOD.

  METHOD Edit.
    READ ENTITIES OF zpru_u_purcorderhdr_tp " use your base BDEF
         IN LOCAL MODE
         ENTITY OrderTP
         ALL FIELDS WITH VALUE #( FOR <ls_k1>
                                  IN keys
                                  ( purchaseOrderId = <ls_k1>-purchaseOrderId
                                    %is_draft       = if_abap_behv=>mk-off ) )
         RESULT DATA(lt_order_active).

    READ ENTITIES OF zpru_u_purcorderhdr_tp " use your base BDEF
         IN LOCAL MODE
         ENTITY OrderTP BY \_items_tp
         ALL FIELDS WITH VALUE #( FOR <ls_k2>
                                  IN keys
                                  ( purchaseOrderId = <ls_k2>-purchaseOrderId
                                    %is_draft       = if_abap_behv=>mk-off ) )
         RESULT DATA(lt_items_active).

    LOOP AT lt_order_active ASSIGNING FIELD-SYMBOL(<ls_order_active>).

      DELETE lcl_buffer=>root_buffer WHERE     instance-purchaseOrderId = <ls_order_active>-purchaseOrderId
                                           AND is_draft                 = if_abap_behv=>mk-off
                                           AND deleted                  = abap_false.

      LOOP AT lt_items_active ASSIGNING FIELD-SYMBOL(<ls_item_active>)
           WHERE purchaseOrderId = <ls_order_active>-purchaseOrderId.

        DELETE lcl_buffer=>child_buffer WHERE     instance-purchaseOrderId = <ls_item_active>-purchaseOrderId
                                              AND instance-itemId          = <ls_item_active>-itemId
                                              AND is_draft                 = if_abap_behv=>mk-off
                                              AND deleted                  = abap_false.
      ENDLOOP.
    ENDLOOP.
  ENDMETHOD.

  METHOD Resume.
    lcl_buffer=>prep_root_buffer( VALUE #( FOR <ls_k1>
                                           IN keys
                                           ( purchaseOrderId = <ls_k1>-purchaseOrderId
                                             is_draft        = if_abap_behv=>mk-on ) ) ).

    lcl_buffer=>prep_child_buffer( VALUE #( FOR <ls_k1>
                                            IN keys
                                            ( purchaseOrderId = <ls_k1>-purchaseOrderId
                                              is_draft        = if_abap_behv=>mk-on ) ) ).
  ENDMETHOD.

  METHOD revalidatePricingRules.
  ENDMETHOD.

  METHOD sendOrderStatisticToAzure.
  ENDMETHOD.

  METHOD determineNames.
  ENDMETHOD.

  METHOD recalculateShippingMethod.
  ENDMETHOD.

  METHOD calctotalamount.
    DATA lt_order_update     TYPE TABLE FOR UPDATE zpru_u_purcorderhdr_tp\\ordertp.
    DATA lv_new_total_amount TYPE zpru_u_purcorderhdr_tp-totalAmount.

    IF keys IS INITIAL.
      APPEND INITIAL LINE TO reported-%other ASSIGNING FIELD-SYMBOL(<lo_reported>).
      <lo_reported> = new_message( id       = zpru_if_m_po=>gc_po_message_class
                                   number   = '001'
                                   severity = if_abap_behv_message=>severity-error ).
      RETURN.
    ENDIF.

    READ ENTITIES OF zpru_u_purcorderhdr_tp
         IN LOCAL MODE
         ENTITY OrderTP
         ALL FIELDS WITH CORRESPONDING #( keys )
         RESULT DATA(lt_roots).

    IF lt_roots IS INITIAL.
      APPEND INITIAL LINE TO reported-%other ASSIGNING <lo_reported>.
      <lo_reported> = new_message( id       = zpru_if_m_po=>gc_po_message_class
                                   number   = '002'
                                   severity = if_abap_behv_message=>severity-error ).
      RETURN.
    ENDIF.

    READ ENTITIES OF zpru_u_purcorderhdr_tp
         IN LOCAL MODE
         ENTITY OrderTP BY \_items_tp
         ALL FIELDS WITH CORRESPONDING #( lt_roots )
         RESULT DATA(lt_items).

    LOOP AT lt_roots ASSIGNING FIELD-SYMBOL(<ls_instance>).

      CLEAR lv_new_total_amount.
      LOOP AT lt_items ASSIGNING FIELD-SYMBOL(<ls_item>)
           WHERE purchaseOrderId = <ls_instance>-purchaseOrderId.
        lv_new_total_amount = lv_new_total_amount + <ls_item>-%data-totalPrice.
      ENDLOOP.
      " prevent auto triggering
      IF <ls_instance>-totalAmount <> lv_new_total_amount.
        APPEND INITIAL LINE TO lt_order_update ASSIGNING FIELD-SYMBOL(<ls_order_update>).
        <ls_order_update>-%tky        = <ls_instance>-%tky.
        <ls_order_update>-totalAmount = lv_new_total_amount.
        <ls_order_update>-%control-totalAmount = if_abap_behv=>mk-on.
      ENDIF.

    ENDLOOP.

    IF lt_order_update IS INITIAL.
      RETURN.
    ENDIF.

    MODIFY ENTITIES OF zpru_u_purcorderhdr_tp
           IN LOCAL MODE
           ENTITY OrderTP
           UPDATE FROM lt_order_update.
  ENDMETHOD.

  METHOD setControlTimestamp.
  ENDMETHOD.

  METHOD checkBuyer.
  ENDMETHOD.

  METHOD checkDates.
    IF keys IS INITIAL.
      APPEND INITIAL LINE TO reported-%other ASSIGNING FIELD-SYMBOL(<lo_reported>).
      <lo_reported> = new_message( id       = zpru_if_m_po=>gc_po_message_class
                                   number   = '001'
                                   severity = if_abap_behv_message=>severity-error ).
      RETURN.
    ENDIF.

    READ ENTITIES OF zpru_u_purcorderhdr_tp
         IN LOCAL MODE
         ENTITY OrderTP
         FIELDS ( orderDate deliveryDate )
         WITH CORRESPONDING #( keys )
         RESULT DATA(lt_roots).

    IF lt_roots IS INITIAL.
      APPEND INITIAL LINE TO reported-%other ASSIGNING <lo_reported>.
      <lo_reported> = new_message( id       = zpru_if_m_po=>gc_po_message_class
                                   number   = '002'
                                   severity = if_abap_behv_message=>severity-error ).
      RETURN.
    ENDIF.

    LOOP AT keys ASSIGNING FIELD-SYMBOL(<ls_key>).

      ASSIGN lt_roots[ KEY id COMPONENTS %tky = <ls_key>-%tky ] TO FIELD-SYMBOL(<ls_instance>).
      IF sy-subrc <> 0.
        APPEND INITIAL LINE TO failed-ordertp ASSIGNING FIELD-SYMBOL(<ls_failed>).
        <ls_failed>-%tky = <ls_instance>-%tky.
        <ls_failed>-%fail-cause = if_abap_behv=>cause-not_found.
        CONTINUE.
      ENDIF.

      APPEND INITIAL LINE TO reported-ordertp ASSIGNING FIELD-SYMBOL(<ls_order_reported>).
      <ls_order_reported>-%tky        = <ls_instance>-%tky.
      <ls_order_reported>-%state_area = lif_business_object=>cs_state_area-order-checkdates.

      IF <ls_instance>-orderDate > <ls_instance>-DeliveryDate.
        APPEND INITIAL LINE TO failed-ordertp ASSIGNING <ls_failed>.
        <ls_failed>-%tky = <ls_instance>-%tky.

        APPEND INITIAL LINE TO reported-ordertp ASSIGNING <ls_order_reported>.
        <ls_order_reported>-%tky        = <ls_instance>-%tky.
        <ls_order_reported>-%state_area = lif_business_object=>cs_state_area-order-checkdates.
        <ls_order_reported>-%msg        = new_message( id       = zpru_if_m_po=>gc_po_message_class
                                                       number   = '005'
                                                       severity = if_abap_behv_message=>severity-error ).
      ENDIF.
    ENDLOOP.
  ENDMETHOD.

  METHOD checkHeaderCurrency.
  ENDMETHOD.

  METHOD checkSupplier.
  ENDMETHOD.

  METHOD precheck_cba_Items_tp.
    SELECT purchaseOrderId, itemId FROM zpru_u_purcorderitem_tp " qqq use your transactional CDS
      FOR ALL ENTRIES IN @entities
      WHERE purchaseOrderId = @entities-purchaseOrderId
      INTO TABLE @DATA(lt_existing_items).

    LOOP AT entities ASSIGNING FIELD-SYMBOL(<ls_entity>).
      LOOP AT <ls_entity>-%target ASSIGNING FIELD-SYMBOL(<ls_item>).
        IF NOT line_exists( lt_existing_items[ purchaseOrderId = <ls_entity>-purchaseOrderId
                                               itemId          = <ls_item>-itemId ] ).
          CONTINUE.
        ENDIF.

        APPEND VALUE #( %cid             = <ls_entity>-%cid_ref
                        %tky             = <ls_entity>-%tky
                        %assoc-_items_tp = if_abap_behv=>mk-on
                        %fail-cause      = if_abap_behv=>cause-unspecific ) TO failed-ordertp.

        APPEND VALUE #( %cid = <ls_entity>-%cid_ref
                        %tky = <ls_entity>-%tky
                        %msg = new_message_with_text( severity = if_abap_behv_message=>severity-error
                                                      text     = 'root to child failed - already exists.' ) )
               TO reported-ordertp.

        APPEND VALUE #( %cid        = <ls_item>-%cid
                        %key        = VALUE #( purchaseOrderId = <ls_entity>-purchaseOrderId
                                               itemId          = <ls_item>-itemId )
                        %fail-cause = if_abap_behv=>cause-dependency ) TO failed-itemtp.

        APPEND VALUE #( %cid = <ls_item>-%cid
                        %key = VALUE #( purchaseOrderId = <ls_entity>-purchaseOrderId
                                        itemId          = <ls_item>-itemId )
                        %msg = new_message_with_text( severity = if_abap_behv_message=>severity-error
                                                      text     = 'root to child failed - already exists2.' ) )
               TO reported-itemtp.
      ENDLOOP.
    ENDLOOP.
  ENDMETHOD.
ENDCLASS.


CLASS lhc_ItemTP DEFINITION INHERITING FROM cl_abap_behavior_handler.
  PRIVATE SECTION.
    METHODS get_instance_authorizations FOR INSTANCE AUTHORIZATION
      IMPORTING keys REQUEST requested_authorizations FOR ItemTP RESULT result.

    METHODS get_global_authorizations FOR GLOBAL AUTHORIZATION
      IMPORTING REQUEST requested_authorizations FOR ItemTP RESULT result.

    METHODS update FOR MODIFY
      IMPORTING entities FOR UPDATE ItemTP.

    METHODS delete FOR MODIFY
      IMPORTING keys FOR DELETE ItemTP.

    METHODS read FOR READ
      IMPORTING keys FOR READ ItemTP RESULT result.

    METHODS rba_Header_tp FOR READ
      IMPORTING keys_rba FOR READ ItemTP\_Header_tp FULL result_requested RESULT result LINK association_links.

    METHODS getInventoryStatus FOR READ
      IMPORTING keys FOR FUNCTION ItemTP~getInventoryStatus RESULT result.

    METHODS markAsUrgent FOR MODIFY
      IMPORTING keys FOR ACTION ItemTP~markAsUrgent.

    METHODS calculateTotalPrice FOR DETERMINE ON MODIFY
      IMPORTING keys FOR ItemTP~calculateTotalPrice.

    METHODS findWarehouseLocation FOR DETERMINE ON SAVE
      IMPORTING keys FOR ItemTP~findWarehouseLocation.

    METHODS writeItemNumber FOR DETERMINE ON SAVE
      IMPORTING keys FOR ItemTP~writeItemNumber.

    METHODS checkItemCurrency FOR VALIDATE ON SAVE
      IMPORTING keys FOR ItemTP~checkItemCurrency.

    METHODS checkQuantity FOR VALIDATE ON SAVE
      IMPORTING keys FOR ItemTP~checkQuantity.

ENDCLASS.


CLASS lhc_ItemTP IMPLEMENTATION.
  METHOD get_instance_authorizations.
  ENDMETHOD.

  METHOD get_global_authorizations.
  ENDMETHOD.

  METHOD update.
    DATA lt_root_upd TYPE TABLE FOR UPDATE zpru_u_purcorderhdr_tp. " use your base BDEF

    lcl_buffer=>prep_child_buffer( VALUE #( FOR <ls_k>
                                            IN entities
                                            ( purchaseOrderId = <ls_k>-purchaseOrderId
                                              itemId          = <ls_k>-itemId
                                              is_draft        = <ls_k>-%is_draft
                                              full_key        = abap_true  ) ) ).

    LOOP AT entities ASSIGNING FIELD-SYMBOL(<ls_update>).

      READ TABLE lcl_buffer=>child_buffer
           WITH KEY instance-purchaseOrderId = <ls_update>-purchaseOrderId
                    instance-itemId          = <ls_update>-itemId
                    is_draft                 = <ls_update>-%is_draft
                    deleted                  = abap_false
           ASSIGNING FIELD-SYMBOL(<ls_up>).

      IF sy-subrc = 0.
        <ls_up>-instance-itemnumber        = COND #( WHEN <ls_update>-%control-itemnumber <> if_abap_behv=>mk-off
                                                     THEN <ls_update>-itemnumber
                                                     ELSE <ls_up>-instance-itemnumber ).
        <ls_up>-instance-productId         = COND #( WHEN <ls_update>-%control-productId <> if_abap_behv=>mk-off
                                                     THEN <ls_update>-productId
                                                     ELSE <ls_up>-instance-productId ).
        <ls_up>-instance-productName       = COND #( WHEN <ls_update>-%control-productName <> if_abap_behv=>mk-off
                                                     THEN <ls_update>-productName
                                                     ELSE <ls_up>-instance-productName ).
        <ls_up>-instance-quantity          = COND #( WHEN <ls_update>-%control-quantity <> if_abap_behv=>mk-off
                                                     THEN <ls_update>-quantity
                                                     ELSE <ls_up>-instance-quantity ).
        <ls_up>-instance-unitPrice         = COND #( WHEN <ls_update>-%control-unitPrice <> if_abap_behv=>mk-off
                                                     THEN <ls_update>-unitPrice
                                                     ELSE <ls_up>-instance-unitPrice ).
        <ls_up>-instance-totalPrice        = COND #( WHEN <ls_update>-%control-totalPrice <> if_abap_behv=>mk-off
                                                     THEN <ls_update>-totalPrice
                                                     ELSE <ls_up>-instance-totalPrice ).
        <ls_up>-instance-deliveryDate      = COND #( WHEN <ls_update>-%control-deliveryDate <> if_abap_behv=>mk-off
                                                     THEN <ls_update>-deliveryDate
                                                     ELSE <ls_up>-instance-deliveryDate ).
        <ls_up>-instance-warehouseLocation = COND #( WHEN <ls_update>-%control-warehouseLocation <> if_abap_behv=>mk-off
                                                     THEN <ls_update>-warehouseLocation
                                                     ELSE <ls_up>-instance-warehouseLocation ).
        <ls_up>-instance-itemCurrency      = COND #( WHEN <ls_update>-%control-itemCurrency <> if_abap_behv=>mk-off
                                                     THEN <ls_update>-itemCurrency
                                                     ELSE <ls_up>-instance-itemCurrency ).
        <ls_up>-instance-isUrgent          = COND #( WHEN <ls_update>-%control-isUrgent <> if_abap_behv=>mk-off
                                                     THEN <ls_update>-isUrgent
                                                     ELSE <ls_up>-instance-isUrgent ).
        <ls_up>-instance-createdBy         = COND #( WHEN <ls_update>-%control-createdBy <> if_abap_behv=>mk-off
                                                     THEN <ls_update>-createdBy
                                                     ELSE <ls_up>-instance-createdBy ).
        <ls_up>-instance-createOn          = COND #( WHEN <ls_update>-%control-createOn <> if_abap_behv=>mk-off
                                                     THEN <ls_update>-createOn
                                                     ELSE <ls_up>-instance-createOn ).
        <ls_up>-instance-changedBy         = COND #( WHEN <ls_update>-%control-changedBy <> if_abap_behv=>mk-off
                                                     THEN <ls_update>-changedBy
                                                     ELSE <ls_up>-instance-changedBy ).
        <ls_up>-instance-changedOn         = COND #( WHEN <ls_update>-%control-changedOn <> if_abap_behv=>mk-off
                                                     THEN <ls_update>-changedOn
                                                     ELSE <ls_up>-instance-changedOn ).

        " QQQ you must update changeOn( last changed on will be taken from value of changed on)
        " in case of update field on item. Otherwise ETAG will not work!!!
        APPEND INITIAL LINE TO lt_root_upd ASSIGNING FIELD-SYMBOL(<ls_root_upd>).
        <ls_root_upd>-purchaseOrderId = <ls_update>-purchaseOrderId.
        <ls_root_upd>-%is_draft       = <ls_update>-%is_draft.

        <ls_up>-changed = abap_true.
        <ls_up>-deleted = abap_false.
      ELSE.

        APPEND VALUE #( %tky        = <ls_update>-%tky
                        %cid        = <ls_update>-%cid_ref
                        %fail-cause = if_abap_behv=>cause-not_found
                        %update     = if_abap_behv=>mk-on )
               TO failed-itemtp.

        APPEND VALUE #( %tky = <ls_update>-%tky
                        %cid = <ls_update>-%cid_ref
                        %msg = new_message_with_text( severity = if_abap_behv_message=>severity-error
                                                      text     = 'Update operation failed.' ) )
               TO reported-itemtp.

      ENDIF.
    ENDLOOP.

    SORT lt_root_upd BY purchaseOrderId
                        %is_draft.
    DELETE ADJACENT DUPLICATES FROM lt_root_upd COMPARING purchaseOrderId %is_draft.

    GET TIME STAMP FIELD DATA(lv_now).
    LOOP AT lt_root_upd ASSIGNING <ls_root_upd>.
      <ls_root_upd>-changedOn = lv_now.
      <ls_root_upd>-%control-changedOn = if_abap_behv=>mk-on. " qqq update ETAG + total ETAG
    ENDLOOP.

    IF lt_root_upd IS NOT INITIAL.
      MODIFY ENTITIES OF zpru_u_purcorderhdr_tp  " qqq change on your BDEF
             IN LOCAL MODE
             ENTITY OrderTP UPDATE FROM lt_root_upd.
    ENDIF.
  ENDMETHOD.

  METHOD delete.
    DATA lt_root_upd TYPE TABLE FOR UPDATE zpru_u_purcorderhdr_tp. " qqq use your BDEF

    lcl_buffer=>prep_child_buffer( VALUE #( FOR <ls_k>
                                            IN keys
                                            ( purchaseOrderId = <ls_k>-purchaseOrderId
                                              itemId          = <ls_k>-itemId
                                              is_draft        = <ls_k>-%is_draft
                                              full_key        = abap_true  ) ) ).

    LOOP AT keys ASSIGNING FIELD-SYMBOL(<ls_delete>).
      READ TABLE lcl_buffer=>child_buffer
           WITH KEY instance-purchaseOrderId = <ls_delete>-purchaseOrderId
                    instance-itemId          = <ls_delete>-itemId
                    is_draft                 = <ls_delete>-%is_draft
                    deleted                  = abap_false ASSIGNING FIELD-SYMBOL(<ls_del>).

      IF sy-subrc = 0.
        " QQQ you must update changeOn( last changed on will be taken from value of changed on)
        " in case of deletion of item. Otherwise ETAG will not work!!!
        APPEND INITIAL LINE TO lt_root_upd ASSIGNING FIELD-SYMBOL(<ls_root_upd>).
        <ls_root_upd>-purchaseOrderId = <ls_DELETE>-purchaseOrderId.
        <ls_root_upd>-%is_draft       = <ls_DELETE>-%is_draft.

        <ls_del>-changed = abap_false.
        <ls_del>-deleted = abap_true.
      ELSE.
        APPEND VALUE #( %tky        = <ls_delete>-%tky
                        %cid        = <ls_delete>-%cid_ref
                        %fail-cause = if_abap_behv=>cause-not_found
                        %delete     = if_abap_behv=>mk-on ) TO failed-itemtp.

        APPEND VALUE #( %tky = <ls_delete>-%tky
                        %cid = <ls_delete>-%cid_ref
                        %msg = new_message_with_text( severity = if_abap_behv_message=>severity-error
                                                      text     = 'Delete operation failed.' ) ) TO reported-itemtp.
      ENDIF.
    ENDLOOP.

    SORT lt_root_upd BY purchaseOrderId
                        %is_draft.
    DELETE ADJACENT DUPLICATES FROM lt_root_upd COMPARING purchaseOrderId %is_draft.

    GET TIME STAMP FIELD DATA(lv_now).
    LOOP AT lt_root_upd ASSIGNING <ls_root_upd>.
      <ls_root_upd>-changedOn = lv_now. " qqq update ETAG and total ETAG
      <ls_root_upd>-%control-changedOn = if_abap_behv=>mk-on.
    ENDLOOP.

    IF lt_root_upd IS NOT INITIAL.
      MODIFY ENTITIES OF zpru_u_purcorderhdr_tp  " qqq change on your BDEF
             IN LOCAL MODE
             ENTITY OrderTP UPDATE FROM lt_root_upd.
    ENDIF.
  ENDMETHOD.

  METHOD read.
    lcl_buffer=>prep_child_buffer( VALUE #( FOR <ls_k>
                                            IN keys
                                            ( purchaseOrderId = <ls_k>-purchaseOrderId
                                              itemId          = <ls_k>-itemId
                                              is_draft        = <ls_k>-%is_draft
                                              full_key        = abap_true  ) ) ).

    LOOP AT keys ASSIGNING FIELD-SYMBOL(<ls_read>) GROUP BY <ls_read>-%tky.

      READ TABLE lcl_buffer=>child_buffer
           WITH KEY instance-purchaseOrderId = <ls_read>-purchaseOrderId
                    instance-itemId          = <ls_read>-itemId
                    is_draft                 = <ls_read>-%is_draft
                    deleted                  = abap_false ASSIGNING FIELD-SYMBOL(<ls_rc>).

      IF sy-subrc = 0.
        APPEND VALUE #( %tky              = <ls_read>-%tky
                        itemNumber        = COND #( WHEN <ls_read>-%control-itemNumber <> if_abap_behv=>mk-off
                                                    THEN <ls_rc>-instance-itemNumber )
                        productId         = COND #( WHEN <ls_read>-%control-productId <> if_abap_behv=>mk-off
                                                    THEN <ls_rc>-instance-productId )
                        productName       = COND #( WHEN <ls_read>-%control-productName <> if_abap_behv=>mk-off
                                                    THEN <ls_rc>-instance-productName )
                        quantity          = COND #( WHEN <ls_read>-%control-quantity <> if_abap_behv=>mk-off
                                                    THEN <ls_rc>-instance-quantity )
                        unitPrice         = COND #( WHEN <ls_read>-%control-unitPrice <> if_abap_behv=>mk-off
                                                    THEN <ls_rc>-instance-unitPrice )
                        totalPrice        = COND #( WHEN <ls_read>-%control-totalPrice <> if_abap_behv=>mk-off
                                                    THEN <ls_rc>-instance-totalPrice )
                        deliveryDate      = COND #( WHEN <ls_read>-%control-deliveryDate <> if_abap_behv=>mk-off
                                                    THEN <ls_rc>-instance-deliveryDate )
                        warehouseLocation = COND #( WHEN <ls_read>-%control-warehouseLocation <> if_abap_behv=>mk-off
                                                    THEN <ls_rc>-instance-warehouseLocation )
                        itemCurrency      = COND #( WHEN <ls_read>-%control-itemCurrency <> if_abap_behv=>mk-off
                                                    THEN <ls_rc>-instance-itemCurrency )
                        isUrgent          = COND #( WHEN <ls_read>-%control-isUrgent <> if_abap_behv=>mk-off
                                                    THEN <ls_rc>-instance-isUrgent )
                        createdBy         = COND #( WHEN <ls_read>-%control-createdBy <> if_abap_behv=>mk-off
                                                    THEN <ls_rc>-instance-createdBy )
                        createOn          = COND #( WHEN <ls_read>-%control-createOn <> if_abap_behv=>mk-off
                                                    THEN <ls_rc>-instance-createOn )
                        changedBy         = COND #( WHEN <ls_read>-%control-changedBy <> if_abap_behv=>mk-off
                                                    THEN <ls_rc>-instance-changedBy )
                        changedOn         = COND #( WHEN <ls_read>-%control-changedOn <> if_abap_behv=>mk-off
                                                    THEN <ls_rc>-instance-changedOn ) ) TO result.

      ELSE.

        APPEND VALUE #( %tky        = <ls_read>-%tky
                        %fail-cause = if_abap_behv=>cause-not_found )
               TO failed-itemtp.

        APPEND VALUE #( %tky = <ls_read>-%tky
                        %msg = new_message_with_text( severity = if_abap_behv_message=>severity-error
                                                      text     = 'Read operation failed (child entity).' ) )
               TO reported-itemtp.

      ENDIF.
    ENDLOOP.
  ENDMETHOD.

  METHOD rba_Header_tp.
    lcl_buffer=>prep_root_buffer( CORRESPONDING #( keys_rba MAPPING purchaseorderid = purchaseOrderId
                                                                    is_draft        = %is_draft ) ).
    lcl_buffer=>prep_child_buffer( CORRESPONDING #( keys_rba MAPPING purchaseorderid = purchaseOrderId
                                                                     is_draft        = %is_draft ) ).

    LOOP AT keys_rba ASSIGNING FIELD-SYMBOL(<ls_rba>) GROUP BY <ls_rba>-%tky.
      IF     line_exists( lcl_buffer=>root_buffer[ instance-purchaseOrderId = <ls_rba>-purchaseOrderId
                                                   is_draft                 = <ls_rba>-%is_draft
                                                   deleted                  = abap_false ] )
         AND line_exists( lcl_buffer=>child_buffer[ instance-purchaseOrderId = <ls_rba>-purchaseOrderId
                                                    is_draft                 = <ls_rba>-%is_draft
                                                    instance-itemId          = <ls_rba>-itemId
                                                    deleted                  = abap_false ] ).

        INSERT VALUE #( target-%tky = CORRESPONDING #( <ls_rba>-%tky )
                        source-%tky = VALUE #( purchaseOrderId = <ls_rba>-purchaseOrderId
                                               itemId          = <ls_rba>-itemId
                                               %is_draft       = <ls_rba>-%is_draft ) ) INTO TABLE association_links.

        IF result_requested = abap_true.
          READ TABLE lcl_buffer=>root_buffer
               WITH KEY instance-purchaseOrderId = <ls_rba>-purchaseOrderId
                        is_draft                 = <ls_rba>-%is_draft ASSIGNING FIELD-SYMBOL(<ls_rp>).
          IF sy-subrc = 0.
            APPEND VALUE #( %tky             = CORRESPONDING #( <ls_rba>-%tky )
                            orderDate        = COND #( WHEN <ls_rba>-%control-orderDate <> if_abap_behv=>mk-off
                                                       THEN <ls_rp>-instance-orderDate )
                            supplierId       = COND #( WHEN <ls_rba>-%control-supplierId <> if_abap_behv=>mk-off
                                                       THEN <ls_rp>-instance-supplierId )
                            supplierName     = COND #( WHEN <ls_rba>-%control-supplierName <> if_abap_behv=>mk-off
                                                       THEN <ls_rp>-instance-supplierName )
                            buyerId          = COND #( WHEN <ls_rba>-%control-buyerId <> if_abap_behv=>mk-off
                                                       THEN <ls_rp>-instance-buyerId )
                            buyerName        = COND #( WHEN <ls_rba>-%control-buyerName <> if_abap_behv=>mk-off
                                                       THEN <ls_rp>-instance-buyerName )
                            totalAmount      = COND #( WHEN <ls_rba>-%control-totalAmount <> if_abap_behv=>mk-off
                                                       THEN <ls_rp>-instance-totalAmount )
                            headerCurrency   = COND #( WHEN <ls_rba>-%control-headerCurrency <> if_abap_behv=>mk-off
                                                       THEN <ls_rp>-instance-headerCurrency )
                            deliveryDate     = COND #( WHEN <ls_rba>-%control-deliveryDate <> if_abap_behv=>mk-off
                                                       THEN <ls_rp>-instance-deliveryDate )
                            status           = COND #( WHEN <ls_rba>-%control-status <> if_abap_behv=>mk-off
                                                       THEN <ls_rp>-instance-status )
                            paymentTerms     = COND #( WHEN <ls_rba>-%control-paymentTerms <> if_abap_behv=>mk-off
                                                       THEN <ls_rp>-instance-paymentTerms )
                            shippingMethod   = COND #( WHEN <ls_rba>-%control-shippingMethod <> if_abap_behv=>mk-off
                                                       THEN <ls_rp>-instance-shippingMethod )
                            controlTimestamp = COND #( WHEN <ls_rba>-%control-controlTimestamp <> if_abap_behv=>mk-off
                                                       THEN <ls_rp>-instance-controlTimestamp )
                            createdBy        = COND #( WHEN <ls_rba>-%control-createdBy <> if_abap_behv=>mk-off
                                                       THEN <ls_rp>-instance-createdBy )
                            createOn         = COND #( WHEN <ls_rba>-%control-createOn <> if_abap_behv=>mk-off
                                                       THEN <ls_rp>-instance-createOn )
                            changedBy        = COND #( WHEN <ls_rba>-%control-changedBy <> if_abap_behv=>mk-off
                                                       THEN <ls_rp>-instance-changedBy )
                            changedOn        = COND #( WHEN <ls_rba>-%control-changedOn <> if_abap_behv=>mk-off
                                                       THEN <ls_rp>-instance-changedOn )
                            lastChanged      = COND #( WHEN <ls_rba>-%control-lastChanged <> if_abap_behv=>mk-off
                                                       THEN <ls_rp>-instance-lastChanged ) ) TO result.
          ENDIF.
        ENDIF.

      ELSE.

        APPEND VALUE #( %tky              = <ls_rba>-%tky
                        %assoc-_header_tp = if_abap_behv=>mk-on
                        %fail-cause       = if_abap_behv=>cause-not_found )
               TO failed-ItemTP.

        APPEND VALUE #( %tky = <ls_rba>-%tky
                        %msg = new_message_with_text( severity = if_abap_behv_message=>severity-error
                                                      text     = 'RBA operation (child to parent) failed.' ) )
               TO reported-ItemTP.

      ENDIF.
    ENDLOOP.

    " Removing potential duplicate entries.
    SORT association_links BY target ASCENDING.
    DELETE ADJACENT DUPLICATES FROM association_links COMPARING ALL FIELDS.

    SORT result BY %tky ASCENDING.
    DELETE ADJACENT DUPLICATES FROM result COMPARING ALL FIELDS.
  ENDMETHOD.

  METHOD getInventoryStatus.
  ENDMETHOD.

  METHOD markAsUrgent.
  ENDMETHOD.

  METHOD calculateTotalPrice.
    DATA lt_item_update TYPE TABLE FOR UPDATE zpru_u_purcorderhdr_tp\\itemtp.

    IF keys IS INITIAL.
      APPEND INITIAL LINE TO reported-%other ASSIGNING FIELD-SYMBOL(<lo_reported>).
      <lo_reported> = new_message( id       = zpru_if_m_po=>gc_po_message_class
                                   number   = '001'
                                   severity = if_abap_behv_message=>severity-error ).
      RETURN.
    ENDIF.

    READ ENTITIES OF zpru_u_purcorderhdr_tp
         IN LOCAL MODE
         ENTITY ItemTP
         FIELDS ( quantity
                  unitprice )
         WITH CORRESPONDING #( keys )
         RESULT DATA(lt_items).

    IF lt_items IS INITIAL.
      APPEND INITIAL LINE TO reported-%other ASSIGNING <lo_reported>.
      <lo_reported> = new_message( id       = zpru_if_m_po=>gc_po_message_class
                                   number   = '002'
                                   severity = if_abap_behv_message=>severity-error ).
      RETURN.
    ENDIF.

    LOOP AT lt_items ASSIGNING FIELD-SYMBOL(<ls_instance>).

      APPEND INITIAL LINE TO lt_item_update ASSIGNING FIELD-SYMBOL(<ls_item_update>).
      <ls_item_update>-%tky = <ls_instance>-%tky.
      <ls_item_update>-%data-totalPrice = <ls_instance>-quantity * <ls_instance>-unitprice.
      <ls_item_update>-%control-totalPrice = if_abap_behv=>mk-on.

    ENDLOOP.

    IF lt_item_update IS INITIAL.
      RETURN.
    ENDIF.

    MODIFY ENTITIES OF zpru_u_purcorderhdr_tp
           IN LOCAL MODE
           ENTITY ItemTP
           UPDATE FROM lt_item_update.
  ENDMETHOD.

  METHOD findWarehouseLocation.
  ENDMETHOD.

  METHOD writeItemNumber.
    DATA lt_item_update    TYPE TABLE FOR UPDATE zpru_u_purcorderhdr_tp\\itemtp.
    DATA lt_EXISTING_items TYPE TABLE FOR READ RESULT zpru_u_purcorderhdr_tp\\itemtp.

    IF keys IS INITIAL.
      APPEND INITIAL LINE TO reported-%other ASSIGNING FIELD-SYMBOL(<lo_reported>).
      <lo_reported> = new_message( id       = zpru_if_m_po=>gc_po_message_class
                                   number   = '001'
                                   severity = if_abap_behv_message=>severity-error ).
      RETURN.
    ENDIF.

    READ ENTITIES OF zpru_u_purcorderhdr_tp
         IN LOCAL MODE
         ENTITY ItemTP
         ALL FIELDS
         WITH CORRESPONDING #( keys )
         RESULT DATA(lt_items).

    IF lt_items IS INITIAL.
      APPEND INITIAL LINE TO reported-%other ASSIGNING <lo_reported>.
      <lo_reported> = new_message( id       = zpru_if_m_po=>gc_po_message_class
                                   number   = '002'
                                   severity = if_abap_behv_message=>severity-error ).
      RETURN.
    ENDIF.

    READ ENTITIES OF zpru_u_purcorderhdr_tp
         IN LOCAL MODE
         ENTITY ItemTP BY \_header_tp
         ALL FIELDS
         WITH VALUE #( FOR <ls_i> IN keys
                       ( %tky-%is_draft       = <ls_i>-%is_draft
                         %tky-purchaseOrderId = <ls_i>-purchaseOrderId
                         %tky-itemId          = <ls_i>-itemId  ) )
         LINK DATA(lt_item_to_order).

    READ ENTITIES OF zpru_u_purcorderhdr_tp
         IN LOCAL MODE
         ENTITY OrderTP BY \_items_tp
         ALL FIELDS
         WITH VALUE #( FOR <ls_ord> IN lt_item_to_order
                       ( CORRESPONDING #( <ls_ord>-target ) ) )
         RESULT DATA(lt_ALL_items).

    LOOP AT lt_items ASSIGNING FIELD-SYMBOL(<ls_GROUP>)
         GROUP BY ( is_draft        = <ls_GROUP>-%is_draft
                    purchaseorderid = <ls_GROUP>-purchaseorderid ) ASSIGNING FIELD-SYMBOL(<ls_GROUP_key>).

      LOOP AT lt_ALL_items ASSIGNING FIELD-SYMBOL(<ls_ALL_ITEMS>).
        IF line_exists( keys[ KEY id COMPONENTS %tky = <ls_ALL_ITEMS>-%tky ] ).
          CONTINUE.
        ENDIF.
        APPEND INITIAL LINE TO lt_EXISTING_items ASSIGNING FIELD-SYMBOL(<ls_existing_item>).
        <ls_existing_item> = CORRESPONDING #( <ls_ALL_ITEMS> ).
      ENDLOOP.

      SORT lt_EXISTING_items BY itemNumber DESCENDING.
      DATA(lv_count) = COND i( WHEN lines( lt_EXISTING_items ) > 0
                               THEN VALUE #( lt_EXISTING_items[ 1 ]-itemNumber OPTIONAL )
                               ELSE 0 ).

      LOOP AT GROUP <ls_GROUP_key> ASSIGNING FIELD-SYMBOL(<ls_MEMBER>).

        lv_count = lv_count + 1.
        APPEND INITIAL LINE TO lt_item_update ASSIGNING FIELD-SYMBOL(<ls_item_update>).
        <ls_item_update>-%tky = <ls_member>-%tky.
        <ls_item_update>-%data-itemNumber = lv_count.
        <ls_item_update>-%control-itemNumber = if_abap_behv=>mk-on.
      ENDLOOP.

    ENDLOOP.

    IF lt_item_update IS INITIAL.
      RETURN.
    ENDIF.

    MODIFY ENTITIES OF zpru_u_purcorderhdr_tp
           IN LOCAL MODE
           ENTITY ItemTP
           UPDATE FROM lt_item_update.
  ENDMETHOD.

  METHOD checkItemCurrency.
  ENDMETHOD.

  METHOD checkQuantity.
  ENDMETHOD.
ENDCLASS.


CLASS lsc_ZPRU_U_PURCORDERHDR_TP DEFINITION INHERITING FROM cl_abap_behavior_saver.
  PROTECTED SECTION.
    METHODS finalize          REDEFINITION.

    METHODS check_before_save REDEFINITION.

    METHODS save              REDEFINITION.

    METHODS cleanup           REDEFINITION.

    METHODS cleanup_finalize  REDEFINITION.

ENDCLASS.


CLASS lsc_ZPRU_U_PURCORDERHDR_TP IMPLEMENTATION.
  METHOD finalize.
    " TODO: variable is assigned but never used (ABAP cleaner)
    DATA(lt_root) = lcl_buffer=>root_buffer.
  ENDMETHOD.

  METHOD check_before_save.
    " TODO: variable is assigned but never used (ABAP cleaner)
    DATA(lt_root) = lcl_buffer=>root_buffer.
  ENDMETHOD.

  METHOD save.
    DATA lt_mod_tab       TYPE TABLE OF zpru_purc_order WITH EMPTY KEY. " qqq use on your  database tables
    DATA lt_del_tab       TYPE lcl_buffer=>tt_root_db_keys.
    DATA lt_mod_child_tab TYPE TABLE OF zpru_po_item WITH EMPTY KEY. " qqq use on your  database tables
    DATA lt_del_child_tab TYPE lcl_buffer=>tt_child_db_keys.
    " variables for event
    DATA lt_payload       TYPE TABLE FOR EVENT zpru_u_purcorderhdr_tp\\ordertp~ordercreated. " qqq use your BDEF

    IF line_exists( lcl_buffer=>root_buffer[ changed = abap_true ] ).
      LOOP AT lcl_buffer=>root_buffer ASSIGNING FIELD-SYMBOL(<ls_cr>) WHERE     changed  = abap_true
                                                                            AND deleted  = abap_false
                                                                            AND is_draft = if_abap_behv=>mk-off.
        APPEND CORRESPONDING #( <ls_cr>-instance MAPPING FROM ENTITY ) TO lt_mod_tab.
      ENDLOOP.
      MODIFY zpru_purc_order FROM TABLE @( CORRESPONDING #( lt_mod_tab ) ). " qqq use on your  database tables
    ENDIF.

    IF line_exists( lcl_buffer=>root_buffer[ deleted = abap_true ] ).
      LOOP AT lcl_buffer=>root_buffer ASSIGNING FIELD-SYMBOL(<ls_del>) WHERE     deleted  = abap_true
                                                                             AND is_draft = if_abap_behv=>mk-off.
        APPEND VALUE #( purchase_order_id = <ls_del>-instance-purchaseOrderId ) TO lt_del_tab.
      ENDLOOP.
      DELETE zpru_purc_order FROM TABLE @( CORRESPONDING #( lt_del_tab ) ). " qqq use on your  database tables
    ENDIF.

    IF line_exists( lcl_buffer=>child_buffer[ changed = abap_true ] ).
      LOOP AT lcl_buffer=>child_buffer ASSIGNING FIELD-SYMBOL(<ls_mod_child>) WHERE     changed  = abap_true
                                                                                    AND is_draft = if_abap_behv=>mk-off.
        APPEND CORRESPONDING #( <ls_mod_child>-instance MAPPING FROM ENTITY ) TO lt_mod_child_tab.
      ENDLOOP.

      MODIFY zpru_po_item FROM TABLE @( CORRESPONDING #( lt_mod_child_tab ) ). " qqq use on your  database tables
    ENDIF.

    IF line_exists( lcl_buffer=>child_buffer[ deleted = abap_true ] ).
      LOOP AT lcl_buffer=>child_buffer ASSIGNING FIELD-SYMBOL(<ls_del_child>) WHERE     deleted  = abap_true
                                                                                    AND is_draft = if_abap_behv=>mk-off.
        APPEND VALUE #( purchase_order_id = <ls_del_child>-instance-purchaseOrderId
                        item_id           = <ls_del_child>-instance-itemId  ) TO lt_del_child_tab.
      ENDLOOP.
      DELETE zpru_po_item FROM TABLE @( CORRESPONDING #( lt_del_child_tab ) ). " qqq use on your  database tables
    ENDIF.

    "qqq logic below is relevant for raising event
    LOOP AT lcl_buffer=>root_buffer ASSIGNING FIELD-SYMBOL(<ls_order>)
                                    WHERE newly_created = abap_true.

      "   After save raise corresponding event
      APPEND INITIAL LINE TO lt_payload ASSIGNING FIELD-SYMBOL(<ls_PO_payload>).
      <ls_PO_payload>-%key-purchaseOrderId    = <ls_order>-instance-purchaseOrderId.
      <ls_PO_payload>-%param-purchaseorderid2 = <ls_order>-instance-purchaseorderid.
      <ls_PO_payload>-%param-orderdate2       = <ls_order>-instance-orderdate.
      <ls_PO_payload>-%param-supplierid2      = <ls_order>-instance-supplierid.
      <ls_PO_payload>-%param-suppliername2    = <ls_order>-instance-suppliername.
      <ls_PO_payload>-%param-buyerid2         = <ls_order>-instance-buyerid.
      <ls_PO_payload>-%param-buyername2       = <ls_order>-instance-buyername.
      <ls_PO_payload>-%param-totalamount2     = <ls_order>-instance-totalamount.
      <ls_PO_payload>-%param-headercurrency2  = <ls_order>-instance-headercurrency.
      <ls_PO_payload>-%param-deliverydate2    = <ls_order>-instance-deliverydate.
      <ls_PO_payload>-%param-status2          = <ls_order>-instance-status.
      <ls_PO_payload>-%param-paymentterms2    = <ls_order>-instance-paymentterms.
      <ls_PO_payload>-%param-shippingmethod2  = <ls_order>-instance-shippingmethod.

      <ls_PO_payload>-%control-purchaseorderid2 = if_abap_behv=>mk-on.
      <ls_PO_payload>-%control-orderdate2       = if_abap_behv=>mk-on.
      <ls_PO_payload>-%control-supplierid2      = if_abap_behv=>mk-on.
      <ls_PO_payload>-%control-suppliername2    = if_abap_behv=>mk-on.
      <ls_PO_payload>-%control-buyerid2         = if_abap_behv=>mk-on.
      <ls_PO_payload>-%control-buyername2       = if_abap_behv=>mk-on.
      <ls_PO_payload>-%control-totalamount2     = if_abap_behv=>mk-on.
      <ls_PO_payload>-%control-headercurrency2  = if_abap_behv=>mk-on.
      <ls_PO_payload>-%control-deliverydate2    = if_abap_behv=>mk-on.
      <ls_PO_payload>-%control-status2          = if_abap_behv=>mk-on.
      <ls_PO_payload>-%control-paymentterms2    = if_abap_behv=>mk-on.
      <ls_PO_payload>-%control-shippingmethod2  = if_abap_behv=>mk-on.
      <ls_PO_payload>-%control-_cross_bo        = if_abap_behv=>mk-on.
      <ls_PO_payload>-%control-_items_abs       = if_abap_behv=>mk-on.

      LOOP AT lcl_buffer=>child_buffer ASSIGNING FIELD-SYMBOL(<ls_item>)
           WHERE instance-purchaseorderid = <ls_order>-instance-purchaseorderid.
        APPEND INITIAL LINE TO <ls_PO_payload>-%param-_items_abs ASSIGNING FIELD-SYMBOL(<ls_item_payload>).
        <ls_item_payload>-itemid2            = <ls_item>-instance-itemid.
        <ls_item_payload>-itemnumber2        = <ls_item>-instance-itemnumber.
        <ls_item_payload>-productid2         = <ls_item>-instance-productid.
        <ls_item_payload>-productname2       = <ls_item>-instance-productname.
        <ls_item_payload>-quantity2          = <ls_item>-instance-quantity.
        <ls_item_payload>-unitprice2         = <ls_item>-instance-unitprice.
        <ls_item_payload>-totalprice2        = <ls_item>-instance-totalprice.
        <ls_item_payload>-deliverydate2      = <ls_item>-instance-deliverydate.
        <ls_item_payload>-warehouselocation2 = <ls_item>-instance-warehouselocation.
        <ls_item_payload>-itemcurrency2      = <ls_item>-instance-itemcurrency.
        <ls_item_payload>-isurgent2          = <ls_item>-instance-isurgent.
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
    ENDLOOP.

    IF lt_payload IS INITIAL.
      RETURN.
    ENDIF.

    RAISE ENTITY EVENT zpru_u_purcorderhdr_tp~orderCreated " qqq use your BDEF
          FROM lt_payload.
  ENDMETHOD.

  METHOD cleanup.
    CLEAR lcl_buffer=>root_buffer.
    CLEAR lcl_buffer=>child_buffer.
  ENDMETHOD.

  METHOD cleanup_finalize.
    CLEAR lcl_buffer=>root_buffer.
    CLEAR lcl_buffer=>child_buffer.
  ENDMETHOD.
ENDCLASS.
