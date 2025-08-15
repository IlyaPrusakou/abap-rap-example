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
    " Structure and internal table types for the internal table serving
    " as transactional buffers for the root and child entities
    TYPES: BEGIN OF gty_buffer,
             instance TYPE zpru_u_purcorderhdr_tp,
             cid      TYPE string,
             changed  TYPE abap_bool,
             deleted  TYPE abap_bool,
           END OF gty_buffer.

    TYPES: BEGIN OF gty_buffer_child,
             instance   TYPE zpru_u_purcorderitem_tp,
             cid_ref    TYPE string,
             cid_target TYPE string,
             changed    TYPE abap_bool,
           END OF gty_buffer_child.

    TYPES gtt_buffer       TYPE TABLE OF gty_buffer WITH EMPTY KEY.
    TYPES gtt_buffer_child TYPE TABLE OF gty_buffer_child WITH EMPTY KEY.

    " Internal tables serving as transactional buffers for the root and child entities
    CLASS-DATA root_buffer  TYPE STANDARD TABLE OF gty_buffer WITH EMPTY KEY.
    CLASS-DATA child_buffer TYPE STANDARD TABLE OF gty_buffer_child WITH EMPTY KEY.

    " Structure and internal table types to include the keys for buffer preparation methods
    TYPES: BEGIN OF root_keys,
             purchaseOrderID TYPE zpru_u_purcorderhdr_tp-purchaseOrderId,
           END OF root_keys.
    TYPES: BEGIN OF child_keys,
             purchaseOrderId TYPE zpru_u_purcorderitem_tp-purchaseOrderId,
             itemId          TYPE zpru_u_purcorderitem_tp-itemId,
             full_key        TYPE abap_bool,
           END OF child_keys.
    TYPES tt_root_keys  TYPE TABLE OF root_keys WITH EMPTY KEY.
    TYPES tt_child_keys TYPE TABLE OF child_keys WITH EMPTY KEY.

    " Buffer preparation methods
    CLASS-METHODS prep_root_buffer
      IMPORTING !keys TYPE tt_root_keys.

    CLASS-METHODS prep_child_buffer
      IMPORTING !keys TYPE tt_child_keys.

ENDCLASS.


CLASS lcl_buffer IMPLEMENTATION.
  " Buffer preparation for the root entity based on the requested key values
  METHOD prep_root_buffer.
    DATA ls_line TYPE zpru_u_purcorderhdr_tp.

    LOOP AT keys ASSIGNING FIELD-SYMBOL(<ls_buffer>).
      " Logic:
      "- Line with the specific key values exists in the buffer for the root entity
      "- If it is true: Do nothing, buffer is prepared for the specific instance.
      "- Note: If the line is marked as deleted, the buffer should not be filled anew with the data.
      IF line_exists( lcl_buffer=>root_buffer[ instance-purchaseOrderId = <ls_buffer>-purchaseorderid ] ).
        " do nothing
      ELSE.
        " Checking if entry exists in the database table of the root entity based on the key value
        SELECT SINGLE @abap_true FROM Zpru_PurcOrderHdr
          WHERE purchaseorderid = @<ls_buffer>-purchaseorderid
          INTO @DATA(lv_exists).
        IF lv_exists = abap_true.
          " If entry exists, retrieve it based on the shared key value
          SELECT SINGLE * FROM Zpru_PurcOrderHdr
            WHERE purchaseorderid = @<ls_buffer>-purchaseorderid
            INTO CORRESPONDING FIELDS OF @ls_line.
          IF sy-subrc = 0.
            " Adding line to the root buffer
            APPEND VALUE #( instance = ls_line ) TO lcl_buffer=>root_buffer.
          ENDIF.
        ENDIF.
      ENDIF.
    ENDLOOP.
  ENDMETHOD.

  " Buffer preparation for the child entity based on the requested key values
  METHOD prep_child_buffer.
    LOOP AT keys ASSIGNING FIELD-SYMBOL(<ls_buffer_ch>).

      DATA lt_ch_tab  TYPE TABLE OF zpru_u_purcorderitem_tp WITH EMPTY KEY.
      DATA ls_line_ch TYPE zpru_u_purcorderitem_tp.

      " The full_key flag is in this example only relevant if a read operation is executed on the child entity directly
      " and all key values should be considered for the data retrieval from the database table.
      IF <ls_buffer_ch>-full_key = abap_true.
        " Logic:
        "- Line with specific key values exists in the buffer for the child entity
        "- If it is true: Do nothing, buffer is prepared for the specific instance.
        IF line_exists( lcl_buffer=>child_buffer[ instance-purchaseOrderId = <ls_buffer_ch>-purchaseOrderId
                                                  instance-itemId          = <ls_buffer_ch>-itemId ] ).
          " do nothing
        ELSE.
          " Checking if entry exists in the database table of the child entity based on the shared key value
          SELECT SINGLE @abap_true FROM Zpru_PurcOrderItem
            WHERE purchaseOrderId = @<ls_buffer_ch>-purchaseOrderId
              AND itemId          = @<ls_buffer_ch>-itemId
            INTO @DATA(lv_exists).
          " If entry exists, retrieve all entries based on the key values
          IF lv_exists = abap_true.

            SELECT SINGLE * FROM Zpru_PurcOrderItem
              WHERE purchaseOrderId = @<ls_buffer_ch>-purchaseOrderId
                AND itemId          = @<ls_buffer_ch>-itemId
              INTO CORRESPONDING FIELDS OF @ls_line_ch.

            IF sy-subrc = 0.
              " Adding line to the child buffer if no line exists with all key values
              APPEND VALUE #( instance = ls_line_ch ) TO lcl_buffer=>child_buffer.
            ENDIF.
          ENDIF.
        ENDIF.

      ELSE.

        " Logic:
        "- Line with specific keys exists in the buffer for the root entity and is marked for deletion
        "- If all is true: Doing nothing, buffer is prepared for the specific instance.
        "- Else: Retrieving all lines from the database table of the child entity having the shared key
        IF     line_exists( lcl_buffer=>root_buffer[ instance-purchaseOrderId = <ls_buffer_ch>-purchaseorderid ] )
           AND VALUE #( lcl_buffer=>root_buffer[ instance-purchaseOrderId = <ls_buffer_ch>-purchaseOrderId ]-deleted OPTIONAL ) IS NOT INITIAL.
          " do nothing
        ELSE.
          " Checking if entry exists in the database table of the child entity based on the shared key value
          SELECT SINGLE @abap_true FROM Zpru_PurcOrderItem
            WHERE purchaseOrderId = @<ls_buffer_ch>-purchaseOrderId
            INTO @DATA(lv_exists_ch).
          " If entry exists, retrieve all entries based on the shared key value
          IF lv_exists_ch = abap_true.
            SELECT * FROM Zpru_PurcOrderItem
              WHERE purchaseOrderId = @<ls_buffer_ch>-purchaseOrderId
              INTO CORRESPONDING FIELDS OF TABLE @lt_ch_tab.

            IF sy-subrc = 0.

              LOOP AT lt_ch_tab ASSIGNING FIELD-SYMBOL(<ls_ch>).
                " Adding line to the child buffer if no line exists with all key values
                IF NOT line_exists( lcl_buffer=>child_buffer[ instance-purchaseOrderId = <ls_ch>-purchaseOrderId
                                                              instance-itemId          = <ls_ch>-itemId ] ).
                  APPEND VALUE #( instance = <ls_ch> ) TO lcl_buffer=>child_buffer.
                ENDIF.
              ENDLOOP.
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

ENDCLASS.


CLASS lhc_OrderTP IMPLEMENTATION.
  METHOD get_instance_features.
  ENDMETHOD.

  METHOD get_instance_authorizations.
  ENDMETHOD.

  METHOD get_global_authorizations.
  ENDMETHOD.

  METHOD create.
    " Preparing the transactional buffer based on the input BDEF derived type.
    lcl_buffer=>prep_root_buffer( CORRESPONDING #( entities ) ).

    " Processing requested entities sequentially
    LOOP AT entities ASSIGNING FIELD-SYMBOL(<ls_create>).
      " Logic:
      "- Line with the specific key does not exist in the buffer for the root entity
      "- Line with the specific key exists in the buffer but it is marked as deleted
      "- If it is true: Add new instance to the buffer and, if needed, remove the instance marked as deleted beforehand
      IF    NOT line_exists( lcl_buffer=>root_buffer[ instance-purchaseOrderId = <ls_create>-purchaseOrderId ] )
         OR     line_exists( lcl_buffer=>root_buffer[ instance-purchaseOrderId = <ls_create>-purchaseOrderId
                                                      deleted                  = abap_true ] ).

        " If it exists, removing instance that is marked for deletion from the transactional buffer since it gets replaced by a new one.
        DELETE lcl_buffer=>root_buffer WHERE instance-purchaseOrderId = VALUE #( lcl_buffer=>root_buffer[
                                                                                     instance-purchaseOrderId = <ls_create>-purchaseOrderId ]-instance-purchaseOrderId OPTIONAL ) AND deleted = abap_true.

        " Adding new instance to the transactional buffer by considering %control values
        APPEND VALUE #(
            cid                       = <ls_create>-%cid
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
            instance-lastChanged      = COND #( WHEN <ls_create>-%control-lastChanged <> if_abap_behv=>mk-off
                                                THEN <ls_create>-lastChanged )
            changed                   = abap_true
            deleted                   = abap_false ) TO lcl_buffer=>root_buffer.

        " Filling the MAPPED response parameter for the root entity
        INSERT VALUE #( %cid = <ls_create>-%cid
                        %key = <ls_create>-%key ) INTO TABLE mapped-ordertp.

      ELSE.

        " Filling FAILED and REPORTED response parameters
        APPEND VALUE #( %cid        = <ls_create>-%cid
                        %key        = <ls_create>-%key
                        %create     = if_abap_behv=>mk-on
                        %fail-cause = if_abap_behv=>cause-unspecific )
               TO failed-ordertp.

        APPEND VALUE #( %cid    = <ls_create>-%cid
                        %key    = <ls_create>-%key
                        %create = if_abap_behv=>mk-on
                        %msg    = new_message_with_text( severity = if_abap_behv_message=>severity-error
                                                         text     = 'Create operation failed.' ) )
               TO reported-ordertp.

      ENDIF.
    ENDLOOP.
  ENDMETHOD.

  METHOD precheck_create.
  ENDMETHOD.

  METHOD update.
    " Preparing the transactional buffer based on the input BDEF derived type.
    lcl_buffer=>prep_root_buffer( CORRESPONDING #( entities ) ).

    " Processing requested entities sequentially
    LOOP AT entities ASSIGNING FIELD-SYMBOL(<ls_update>).

      " Logic:
      "- Line with the specific key exists in the buffer for the root entity
      "- Line with the specific key must not be marked as deleted
      "- If it is true: Updating the buffer based on the input BDEF derived type and considering %control values
      READ TABLE lcl_buffer=>root_buffer
           WITH KEY instance-purchaseOrderId = <ls_update>-purchaseOrderId
                    deleted                  = abap_false
           ASSIGNING FIELD-SYMBOL(<ls_up>).

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
        <ls_up>-instance-lastChanged      = COND #( WHEN <ls_update>-%control-lastChanged <> if_abap_behv=>mk-off
                                                    THEN <ls_update>-lastChanged
                                                    ELSE <ls_up>-instance-lastChanged ).
        <ls_up>-changed = abap_true.
        <ls_up>-deleted = abap_false.
      ELSE.

        " Filling FAILED and REPORTED response parameters
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
    " Preparing the transactional buffer based on the input BDEF derived type.
    lcl_buffer=>prep_root_buffer( CORRESPONDING #( keys ) ).

    " Processing requested keys sequentially
    LOOP AT keys ASSIGNING FIELD-SYMBOL(<ls_delete>).
      " Logic:
      "- Line exists in the buffer and it is not marked as deleted
      "- If it is true: Flag the instance as deleted
      READ TABLE lcl_buffer=>root_buffer
           WITH KEY instance-purchaseOrderId = <ls_delete>-purchaseOrderId
                    deleted                  = abap_false
           ASSIGNING FIELD-SYMBOL(<ls_del>).

      IF sy-subrc = 0.

        <ls_del>-changed = abap_false.
        <ls_del>-deleted = abap_true.
      ELSE.
        " Filling FAILED and REPORTED response parameters
        APPEND VALUE #( %tky        = <ls_delete>-%tky
                        %cid        = <ls_delete>-%cid_ref
                        %fail-cause = if_abap_behv=>cause-not_found
                        %delete     = if_abap_behv=>mk-on )
               TO failed-ordertp.

        APPEND VALUE #( %tky = <ls_delete>-%tky
                        %cid = <ls_delete>-%cid_ref
                        %msg = new_message_with_text( severity = if_abap_behv_message=>severity-error
                                                      text     = 'Delete operation failed.' ) )
               TO reported-ordertp.
      ENDIF.
    ENDLOOP.
  ENDMETHOD.

  METHOD precheck_delete.
  ENDMETHOD.

  METHOD read.
    " Preparing the transactional buffer based on the input BDEF derived type.
    lcl_buffer=>prep_root_buffer( CORRESPONDING #( keys ) ).

    " Processing requested keys sequentially
    LOOP AT keys ASSIGNING FIELD-SYMBOL(<ls_read>) GROUP BY <ls_read>-%tky.
      " Logic:
      "- Line exists in the buffer and it is not marked as deleted
      "- If it is true: Adding the entries to the buffer based on the input BDEF derived type and considering %control values
      READ TABLE lcl_buffer=>root_buffer
           WITH KEY instance-purchaseOrderId = <ls_read>-purchaseOrderId
                    deleted                  = abap_false
           ASSIGNING FIELD-SYMBOL(<ls_r>).
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
                        lastChanged      = COND #( WHEN <ls_read>-%control-lastChanged <> if_abap_behv=>mk-off
                                                   THEN <ls_r>-instance-lastChanged ) ) TO result.

      ELSE.
        " Filling FAILED and REPORTED response parameters
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
    " Preparing the transactional buffers for both the root and child entity based on the input BDEF derived type.
    lcl_buffer=>prep_root_buffer( CORRESPONDING #( keys_rba ) ).
    lcl_buffer=>prep_child_buffer( CORRESPONDING #( keys_rba ) ).

    " Processing requested keys sequentially
    LOOP AT keys_rba ASSIGNING FIELD-SYMBOL(<ls_rba>) GROUP BY <ls_rba>-purchaseOrderId.
      " Logic:
      "- Line with the shared key value exists in the buffer for the root entity and it is not marked as deleted
      "- Line with the shared key value exists in the child buffer
      "- If it is true: Sequentially processing the child buffer entries (the example is set up in a way that there can be multiple entries)
      IF     line_exists( lcl_buffer=>root_buffer[ instance-purchaseOrderId = <ls_rba>-purchaseOrderId
                                                   deleted                  = abap_false ] )
         AND line_exists( lcl_buffer=>child_buffer[ instance-purchaseOrderId = <ls_rba>-purchaseOrderId ] ).

        LOOP AT lcl_buffer=>child_buffer ASSIGNING FIELD-SYMBOL(<ls_ch>) WHERE instance-purchaseOrderId = <ls_rba>-purchaseOrderId.

          " Filling the table for the LINK parameter
          INSERT VALUE #( source-%tky = <ls_rba>-%tky
                          target-%tky = VALUE #( purchaseOrderId = <ls_ch>-instance-purchaseOrderId
                                                 itemId          = <ls_ch>-instance-itemId ) ) INTO TABLE association_links.

          " Filling the table for the RESULT parameter based on the FULL parameter
          " Note: If the FULL parameter is initial, only the LINK parameter should be provided
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

        " Filling FAILED and REPORTED response parameters
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
  ENDMETHOD.

  METHOD ChangeStatus.
  ENDMETHOD.

  METHOD precheck_ChangeStatus.
  ENDMETHOD.

  METHOD createFromTemplate.
  ENDMETHOD.

  METHOD Discard.
  ENDMETHOD.

  METHOD Edit.
  ENDMETHOD.

  METHOD Resume.
  ENDMETHOD.

  METHOD revalidatePricingRules.
  ENDMETHOD.

  METHOD sendOrderStatisticToAzure.
  ENDMETHOD.

  METHOD determineNames.
  ENDMETHOD.

  METHOD recalculateShippingMethod.
  ENDMETHOD.

  METHOD calcTotalAmount.
  ENDMETHOD.

  METHOD setControlTimestamp.
  ENDMETHOD.

  METHOD checkBuyer.
  ENDMETHOD.

  METHOD checkDates.
  ENDMETHOD.

  METHOD checkHeaderCurrency.
  ENDMETHOD.

  METHOD checkSupplier.
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
  ENDMETHOD.

  METHOD delete.
  ENDMETHOD.

  METHOD read.
    " Preparing the transactional buffer for child entity based on the input BDEF derived type.
    " Here, the full_key flag is set to consider all key values.
    " Purpose: The preparation method is set up to also consider the entries in the root buffer
    " when dealing with by-association operations which is not relevant in this case.
    lcl_buffer=>prep_child_buffer( VALUE #( FOR <ls_k>
                                            IN keys
                                            ( purchaseOrderId = <ls_k>-purchaseOrderId
                                              itemId          = <ls_k>-itemId
                                              full_key        = abap_true  ) ) ).

    " Processing the requested keys sequentially
    LOOP AT keys ASSIGNING FIELD-SYMBOL(<ls_read>) GROUP BY <ls_read>-%tky.

      " Logic:
      "- Line with the requested key values exists in the child buffer
      "- If it is true: Adding the line to the RESULT parameter considering %control values.
      READ TABLE lcl_buffer=>child_buffer
           WITH KEY instance-purchaseOrderId = <ls_read>-purchaseOrderId
                    instance-itemId          = <ls_read>-itemId
           ASSIGNING FIELD-SYMBOL(<ls_rc>).
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

        " Filling FAILED and REPORTED response parameters
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
    " Preparing the transactional buffers for both the root and child entity based on the input BDEF derived type.
    lcl_buffer=>prep_root_buffer( CORRESPONDING #( keys_rba ) ).
    lcl_buffer=>prep_child_buffer( CORRESPONDING #( keys_rba ) ).

    LOOP AT keys_rba ASSIGNING FIELD-SYMBOL(<ls_rba>) GROUP BY <ls_rba>-%tky.
      " Logic:
      "- Line with the shared key value exists in buffer for the root entity and is not marked as deleted
      "- Line with the full key exists in the child buffer
      "- If it is true: Adding the instance to the RESULT parameter considering %control values
      IF     line_exists( lcl_buffer=>root_buffer[ instance-purchaseOrderId = <ls_rba>-purchaseOrderId
                                                   deleted                  = abap_false ] )
         AND line_exists( lcl_buffer=>child_buffer[ instance-purchaseOrderId = <ls_rba>-purchaseOrderId
                                                    instance-itemId          = <ls_rba>-itemId ] ).

        " Filling the LINK parameter
        INSERT VALUE #( target-%tky = CORRESPONDING #( <ls_rba>-%tky )
                        source-%tky = VALUE #( purchaseOrderId = <ls_rba>-purchaseOrderId
                                               itemId          = <ls_rba>-itemId ) ) INTO TABLE association_links.

        IF result_requested = abap_true.
          READ TABLE lcl_buffer=>root_buffer
               WITH KEY instance-purchaseOrderId = <ls_rba>-purchaseOrderId
               ASSIGNING FIELD-SYMBOL(<ls_rp>).

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

        " Filling FAILED and REPORTED response parameters
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
  ENDMETHOD.

  METHOD findWarehouseLocation.
  ENDMETHOD.

  METHOD writeItemNumber.
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
  ENDMETHOD.

  METHOD check_before_save.
  ENDMETHOD.

  METHOD save.
  ENDMETHOD.

  METHOD cleanup.
  ENDMETHOD.

  METHOD cleanup_finalize.
  ENDMETHOD.
ENDCLASS.
