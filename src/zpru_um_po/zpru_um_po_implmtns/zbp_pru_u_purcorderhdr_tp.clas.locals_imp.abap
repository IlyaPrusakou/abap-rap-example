INTERFACE lif_business_object.

  CONSTANTS: BEGIN OF cs_state_area,
               BEGIN OF order,
                 checkdates          TYPE string VALUE `checkdates`,
                 checkquantity       TYPE string VALUE `checkQuantity`,
                 checkheadercurrency TYPE string VALUE `checkHeaderCurrency`,
                 checksupplier       TYPE string VALUE `checkSupplier`,
                 checkbuyer          TYPE string VALUE `checkBuyer`,
               END OF order,
               BEGIN OF item,
                 checkquantity     TYPE string VALUE `checkquantity`,
                 checkitemcurrency TYPE string VALUE `checkItemCurrency`,
               END OF item,
             END OF cs_state_area.
  TYPES tt_setcontroltimestamp_d       TYPE TABLE FOR DETERMINATION zpru_u_purcorderhdr_tp\\ordertp~setcontroltimestamp.
  TYPES tt_calctotalamount_d           TYPE TABLE FOR DETERMINATION zpru_u_purcorderhdr_tp\\ordertp~calctotalamount.
  TYPES tt_checkdates_v                TYPE TABLE FOR VALIDATION zpru_u_purcorderhdr_tp\\ordertp~checkdates.
  TYPES tt_checkheadercurrency_v       TYPE TABLE FOR VALIDATION zpru_u_purcorderhdr_tp\\ordertp~checkheadercurrency.
  TYPES tt_checksupplier_v             TYPE TABLE FOR VALIDATION zpru_u_purcorderhdr_tp\\ordertp~checksupplier.
  TYPES tt_checkbuyer_v                TYPE TABLE FOR VALIDATION zpru_u_purcorderhdr_tp\\ordertp~checkbuyer.
  TYPES tt_findwarehouselocation_d     TYPE TABLE FOR DETERMINATION zpru_u_purcorderhdr_tp\\itemtp~findwarehouselocation.
  TYPES tt_writeitemnumber_d           TYPE TABLE FOR DETERMINATION zpru_u_purcorderhdr_tp\\itemtp~writeitemnumber.
  TYPES tt_checkquantity_v             TYPE TABLE FOR VALIDATION zpru_u_purcorderhdr_tp\\itemtp~checkquantity.
  TYPES tt_checkitemcurrency_v         TYPE TABLE FOR VALIDATION zpru_u_purcorderhdr_tp\\itemtp~checkitemcurrency.
  TYPES tt_calculatetotalprice_d       TYPE TABLE FOR DETERMINATION zpru_u_purcorderhdr_tp\\itemtp~calculatetotalprice.
  TYPES tt_recalculateshippingmethod_d TYPE TABLE FOR DETERMINATION zpru_u_purcorderhdr_tp\\ordertp~recalculateshippingmethod.
  TYPES tt_determinenames_d            TYPE TABLE FOR DETERMINATION zpru_u_purcorderhdr_tp\\ordertp~determinenames.


  TYPES ts_reported_late               TYPE RESPONSE FOR REPORTED LATE zpru_u_purcorderhdr_tp.
  TYPES ts_failed_late                 TYPE RESPONSE FOR FAILED LATE zpru_u_purcorderhdr_tp.

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
             item_id           TYPE zpru_de_po_itm_id, " qqq use your data element
           END OF child_db_keys.

    TYPES: BEGIN OF root_keys,
             purchaseorderid TYPE zpru_u_purcorderhdr_tp-purchaseorderid, " qqq use your key fields
             is_draft        TYPE abp_behv_flag,
           END OF root_keys.
    TYPES: BEGIN OF child_keys,
             purchaseorderid TYPE zpru_u_purcorderitem_tp-purchaseorderid, " qqq use your key fields
             itemid          TYPE zpru_u_purcorderitem_tp-itemid,
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
         ENTITY ordertp
         ALL FIELDS WITH VALUE #( FOR <ls_drf>
                                  IN keys
                                  WHERE ( is_draft = if_abap_behv=>mk-on )
                                  ( purchaseorderid = <ls_drf>-purchaseorderid
                                    %is_draft       = <ls_drf>-is_draft  ) )
         RESULT DATA(lt_draft_buffer).

    LOOP AT keys ASSIGNING FIELD-SYMBOL(<ls_buffer>).

      IF line_exists( lcl_buffer=>root_buffer[ instance-purchaseorderid = <ls_buffer>-purchaseorderid
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
          SELECT SINGLE @abap_true FROM zpru_purcorderhdr  " use your base CDS or Transactional CDS
            WHERE purchaseorderid = @<ls_buffer>-purchaseorderid
            INTO @DATA(lv_exists).
          IF lv_exists = abap_true.
            SELECT SINGLE * FROM zpru_purcorderhdr " use your base CDS or Transactional CDS
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
         ENTITY ordertp BY \_items_tp
         ALL FIELDS WITH VALUE #( FOR <ls_drf>
                                  IN keys
                                  WHERE ( is_draft = if_abap_behv=>mk-on )
                                  ( purchaseorderid = <ls_drf>-purchaseorderid
                                    %is_draft       = <ls_drf>-is_draft  ) )
         RESULT DATA(lt_draft_buffer).

    LOOP AT keys ASSIGNING FIELD-SYMBOL(<ls_buffer_ch>).

      IF <ls_buffer_ch>-full_key = abap_true.
        IF line_exists( lcl_buffer=>child_buffer[ instance-purchaseorderid = <ls_buffer_ch>-purchaseorderid
                                                  instance-itemid          = <ls_buffer_ch>-itemid
                                                  is_draft                 = <ls_buffer_ch>-is_draft ] ).
          " do nothing
        ELSE.
          IF <ls_buffer_ch>-is_draft = if_abap_behv=>mk-on.
            SELECT SINGLE @abap_true FROM @lt_draft_buffer AS draft_buffer
              WHERE purchaseorderid = @<ls_buffer_ch>-purchaseorderid
                AND itemid          = @<ls_buffer_ch>-itemid
              INTO @DATA(lv_exists_d).
            IF lv_exists_d = abap_true.

              SELECT SINGLE * FROM @lt_draft_buffer AS draft_buffer
                WHERE purchaseorderid = @<ls_buffer_ch>-purchaseorderid
                  AND itemid          = @<ls_buffer_ch>-itemid
                INTO CORRESPONDING FIELDS OF @ls_line_ch.

              IF sy-subrc = 0.
                APPEND VALUE #( instance = ls_line_ch ) TO lcl_buffer=>child_buffer ASSIGNING FIELD-SYMBOL(<ls_just_inserted>).
                <ls_just_inserted>-is_draft = if_abap_behv=>mk-on.
              ENDIF.
            ENDIF.
          ELSE.
            SELECT SINGLE @abap_true FROM zpru_purcorderitem  " qqq use your base CDS or Transactional CDS
              WHERE purchaseorderid = @<ls_buffer_ch>-purchaseorderid
                AND itemid          = @<ls_buffer_ch>-itemid
              INTO @DATA(lv_exists).
            IF lv_exists = abap_true.
              SELECT SINGLE * FROM zpru_purcorderitem " qqq use your base CDS or Transactional CDS
                WHERE purchaseorderid = @<ls_buffer_ch>-purchaseorderid
                  AND itemid          = @<ls_buffer_ch>-itemid
                INTO CORRESPONDING FIELDS OF @ls_line_ch.

              IF sy-subrc = 0.
                APPEND VALUE #( instance = ls_line_ch ) TO lcl_buffer=>child_buffer ASSIGNING <ls_just_inserted>.
                <ls_just_inserted>-is_draft = if_abap_behv=>mk-off.
              ENDIF.
            ENDIF.
          ENDIF.
        ENDIF.

      ELSE.
        IF     line_exists( lcl_buffer=>root_buffer[ instance-purchaseorderid = <ls_buffer_ch>-purchaseorderid
                                                     is_draft                 = <ls_buffer_ch>-is_draft ] )
           AND VALUE #( lcl_buffer=>root_buffer[ instance-purchaseorderid = <ls_buffer_ch>-purchaseorderid
                                                 is_draft                 = <ls_buffer_ch>-is_draft ]-deleted OPTIONAL ) IS NOT INITIAL.
          " do nothing
        ELSE.
          IF <ls_buffer_ch>-is_draft = if_abap_behv=>mk-on.
            SELECT SINGLE @abap_true FROM @lt_draft_buffer AS draft_buffer
              WHERE purchaseorderid = @<ls_buffer_ch>-purchaseorderid
              INTO @DATA(lv_exists_ch_d).
            IF lv_exists_ch_d = abap_true.
              SELECT * FROM @lt_draft_buffer AS draft_buffer
                WHERE purchaseorderid = @<ls_buffer_ch>-purchaseorderid
                INTO CORRESPONDING FIELDS OF TABLE @lt_ch_tab.
              IF sy-subrc = 0.
                LOOP AT lt_ch_tab ASSIGNING FIELD-SYMBOL(<ls_ch>).
                  IF NOT line_exists( lcl_buffer=>child_buffer[ instance-purchaseorderid = <ls_ch>-purchaseorderid
                                                                instance-itemid          = <ls_ch>-itemid
                                                                is_draft                 = if_abap_behv=>mk-on ] ).
                    APPEND VALUE #( instance = <ls_ch> ) TO lcl_buffer=>child_buffer ASSIGNING <ls_just_inserted>.
                    <ls_just_inserted>-is_draft = if_abap_behv=>mk-on.
                  ENDIF.
                ENDLOOP.
              ENDIF.
            ENDIF.
          ELSE.

            SELECT SINGLE @abap_true FROM zpru_purcorderitem " qqq use your base or Transactional CDS
              WHERE purchaseorderid = @<ls_buffer_ch>-purchaseorderid
              INTO @DATA(lv_exists_ch).
            IF lv_exists_ch = abap_true.
              SELECT * FROM zpru_purcorderitem   " qqq use your base or Transactional CDS
                WHERE purchaseorderid = @<ls_buffer_ch>-purchaseorderid
                INTO CORRESPONDING FIELDS OF TABLE @lt_ch_tab.
              IF sy-subrc = 0.
                LOOP AT lt_ch_tab ASSIGNING <ls_ch>.
                  IF NOT line_exists( lcl_buffer=>child_buffer[ instance-purchaseorderid = <ls_ch>-purchaseorderid
                                                                instance-itemid          = <ls_ch>-itemid
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


CLASS lcl_det_val_manager DEFINITION INHERITING FROM cl_abap_behv FINAL CREATE PUBLIC. " rrr
  PUBLIC SECTION.
    METHODS determinenames_in
      IMPORTING !keys     TYPE lif_business_object=>tt_determinenames_d
      CHANGING  !reported TYPE lif_business_object=>ts_reported_late.

    METHODS recalculateshippingmethod_in
      IMPORTING !keys     TYPE lif_business_object=>tt_recalculateshippingmethod_d
      CHANGING  !reported TYPE lif_business_object=>ts_reported_late.

    METHODS calctotalamount_in
      IMPORTING !keys     TYPE lif_business_object=>tt_calctotalamount_d
      CHANGING  !reported TYPE lif_business_object=>ts_reported_late.

    METHODS setcontroltimestamp_in
      IMPORTING !keys     TYPE lif_business_object=>tt_setcontroltimestamp_d
      CHANGING  !reported TYPE lif_business_object=>ts_reported_late.

    METHODS checkbuyer_in
      IMPORTING !keys     TYPE lif_business_object=>tt_checkbuyer_v
      CHANGING  !failed   TYPE lif_business_object=>ts_failed_late
                !reported TYPE lif_business_object=>ts_reported_late.

    METHODS checkdates_in
      IMPORTING !keys     TYPE lif_business_object=>tt_checkdates_v
      CHANGING  !failed   TYPE lif_business_object=>ts_failed_late
                !reported TYPE lif_business_object=>ts_reported_late.

    METHODS checkheadercurrency_in
      IMPORTING !keys     TYPE lif_business_object=>tt_checkheadercurrency_v
      CHANGING  !failed   TYPE lif_business_object=>ts_failed_late
                !reported TYPE lif_business_object=>ts_reported_late.

    METHODS checksupplier_in
      IMPORTING !keys     TYPE lif_business_object=>tt_checksupplier_v
      CHANGING  !failed   TYPE lif_business_object=>ts_failed_late
                !reported TYPE lif_business_object=>ts_reported_late.

    METHODS calculatetotalprice_in
      IMPORTING !keys     TYPE lif_business_object=>tt_calculatetotalprice_d
      CHANGING  !reported TYPE lif_business_object=>ts_reported_late.

    METHODS findwarehouselocation_in
      IMPORTING !keys     TYPE lif_business_object=>tt_findwarehouselocation_d
      CHANGING  !reported TYPE lif_business_object=>ts_reported_late.

    METHODS writeitemnumber_in
      IMPORTING !keys     TYPE lif_business_object=>tt_writeitemnumber_d
      CHANGING  !reported TYPE lif_business_object=>ts_reported_late.

    METHODS checkitemcurrency_in
      IMPORTING !keys     TYPE lif_business_object=>tt_checkitemcurrency_v
      CHANGING  !failed   TYPE lif_business_object=>ts_failed_late
                !reported TYPE lif_business_object=>ts_reported_late.

    METHODS checkquantity_in
      IMPORTING !keys     TYPE lif_business_object=>tt_checkquantity_v
      CHANGING  !failed   TYPE lif_business_object=>ts_failed_late
                !reported TYPE lif_business_object=>ts_reported_late.
ENDCLASS.


CLASS lcl_det_val_manager IMPLEMENTATION.
  METHOD checkquantity_in.
  ENDMETHOD.

  METHOD checkitemcurrency_in.
  ENDMETHOD.

  METHOD writeitemnumber_in.
    DATA lt_item_update    TYPE TABLE FOR UPDATE zpru_u_purcorderhdr_tp\\itemtp.
    DATA lt_existing_items TYPE TABLE FOR READ RESULT zpru_u_purcorderhdr_tp\\itemtp.

    IF keys IS INITIAL.
      APPEND INITIAL LINE TO reported-%other ASSIGNING FIELD-SYMBOL(<lo_reported>).
      <lo_reported> = new_message( id       = zpru_if_m_po=>gc_po_message_class
                                   number   = '001'
                                   severity = if_abap_behv_message=>severity-error ).
      RETURN.
    ENDIF.

    READ ENTITIES OF zpru_u_purcorderhdr_tp
         IN LOCAL MODE
         ENTITY itemtp
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
         ENTITY itemtp BY \_header_tp
         ALL FIELDS
         WITH VALUE #( FOR <ls_i> IN keys
                       ( %tky-%is_draft       = <ls_i>-%is_draft
                         %tky-purchaseorderid = <ls_i>-purchaseorderid
                         %tky-itemid          = <ls_i>-itemid  ) )
         LINK DATA(lt_item_to_order).

    READ ENTITIES OF zpru_u_purcorderhdr_tp
         IN LOCAL MODE
         ENTITY ordertp BY \_items_tp
         ALL FIELDS
         WITH VALUE #( FOR <ls_ord> IN lt_item_to_order
                       ( CORRESPONDING #( <ls_ord>-target ) ) )
         RESULT DATA(lt_all_items).

    LOOP AT lt_items ASSIGNING FIELD-SYMBOL(<ls_group>)
         GROUP BY ( is_draft        = <ls_group>-%is_draft
                    purchaseorderid = <ls_group>-purchaseorderid ) ASSIGNING FIELD-SYMBOL(<ls_group_key>).

      LOOP AT lt_all_items ASSIGNING FIELD-SYMBOL(<ls_all_items>).
        IF line_exists( keys[ KEY id COMPONENTS %tky = <ls_all_items>-%tky ] ).
          CONTINUE.
        ENDIF.
        APPEND INITIAL LINE TO lt_existing_items ASSIGNING FIELD-SYMBOL(<ls_existing_item>).
        <ls_existing_item> = CORRESPONDING #( <ls_all_items> ).
      ENDLOOP.

      SORT lt_existing_items BY itemnumber DESCENDING.
      DATA(lv_count) = COND i( WHEN lines( lt_existing_items ) > 0
                               THEN VALUE #( lt_existing_items[ 1 ]-itemnumber OPTIONAL )
                               ELSE 0 ).

      LOOP AT GROUP <ls_group_key> ASSIGNING FIELD-SYMBOL(<ls_member>).

        lv_count = lv_count + 1.
        APPEND INITIAL LINE TO lt_item_update ASSIGNING FIELD-SYMBOL(<ls_item_update>).
        <ls_item_update>-%tky = <ls_member>-%tky.
        <ls_item_update>-%data-itemnumber = lv_count.
        <ls_item_update>-%control-itemnumber = if_abap_behv=>mk-on.
      ENDLOOP.

    ENDLOOP.

    IF lt_item_update IS INITIAL.
      RETURN.
    ENDIF.

    MODIFY ENTITIES OF zpru_u_purcorderhdr_tp
           IN LOCAL MODE
           ENTITY itemtp
           UPDATE FROM lt_item_update.
  ENDMETHOD.

  METHOD findwarehouselocation_in.
  ENDMETHOD.

  METHOD calculatetotalprice_in.
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
         ENTITY itemtp
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
      <ls_item_update>-%data-totalprice = <ls_instance>-quantity * <ls_instance>-unitprice.
      <ls_item_update>-%control-totalprice = if_abap_behv=>mk-on.

    ENDLOOP.

    IF lt_item_update IS INITIAL.
      RETURN.
    ENDIF.

    MODIFY ENTITIES OF zpru_u_purcorderhdr_tp
           IN LOCAL MODE
           ENTITY itemtp
           UPDATE FROM lt_item_update.
  ENDMETHOD.

  METHOD checksupplier_in.
  ENDMETHOD.

  METHOD checkheadercurrency_in.
  ENDMETHOD.

  METHOD checkbuyer_in.
  ENDMETHOD.

  METHOD setcontroltimestamp_in.
  ENDMETHOD.

  METHOD calctotalamount_in.
    DATA lt_order_update     TYPE TABLE FOR UPDATE zpru_u_purcorderhdr_tp\\ordertp.
    DATA lv_new_total_amount TYPE zpru_u_purcorderhdr_tp-totalamount.

    IF keys IS INITIAL.
      APPEND INITIAL LINE TO reported-%other ASSIGNING FIELD-SYMBOL(<lo_reported>).
      <lo_reported> = new_message( id       = zpru_if_m_po=>gc_po_message_class
                                   number   = '001'
                                   severity = if_abap_behv_message=>severity-error ).
      RETURN.
    ENDIF.

    READ ENTITIES OF zpru_u_purcorderhdr_tp
         IN LOCAL MODE
         ENTITY ordertp
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
         ENTITY ordertp BY \_items_tp
         ALL FIELDS WITH CORRESPONDING #( lt_roots )
         RESULT DATA(lt_items).

    LOOP AT lt_roots ASSIGNING FIELD-SYMBOL(<ls_instance>).

      CLEAR lv_new_total_amount.
      LOOP AT lt_items ASSIGNING FIELD-SYMBOL(<ls_item>)
           WHERE purchaseorderid = <ls_instance>-purchaseorderid.
        lv_new_total_amount = lv_new_total_amount + <ls_item>-%data-totalprice.
      ENDLOOP.
      " prevent auto triggering
      IF <ls_instance>-totalamount <> lv_new_total_amount.
        APPEND INITIAL LINE TO lt_order_update ASSIGNING FIELD-SYMBOL(<ls_order_update>).
        <ls_order_update>-%tky        = <ls_instance>-%tky.
        <ls_order_update>-totalamount = lv_new_total_amount.
        <ls_order_update>-%control-totalamount = if_abap_behv=>mk-on.
      ENDIF.

    ENDLOOP.

    IF lt_order_update IS INITIAL.
      RETURN.
    ENDIF.

    MODIFY ENTITIES OF zpru_u_purcorderhdr_tp
           IN LOCAL MODE
           ENTITY ordertp
           UPDATE FROM lt_order_update.
  ENDMETHOD.

  METHOD determinenames_in.
  ENDMETHOD.

  METHOD recalculateshippingmethod_in.
  ENDMETHOD.

  METHOD checkdates_in.
    IF keys IS INITIAL.
      APPEND INITIAL LINE TO reported-%other ASSIGNING FIELD-SYMBOL(<lo_reported>).
      <lo_reported> = new_message( id       = zpru_if_m_po=>gc_po_message_class
                                   number   = '001'
                                   severity = if_abap_behv_message=>severity-error ).
      RETURN.
    ENDIF.

    READ ENTITIES OF zpru_u_purcorderhdr_tp
         IN LOCAL MODE
         ENTITY ordertp
         FIELDS ( orderdate deliverydate )
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

      IF <ls_instance>-orderdate > <ls_instance>-deliverydate.
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
ENDCLASS.


CLASS lhc_ordertp DEFINITION INHERITING FROM cl_abap_behavior_handler.
  PRIVATE SECTION.
    METHODS get_instance_features FOR INSTANCE FEATURES
      IMPORTING keys REQUEST requested_features FOR ordertp RESULT result.

    METHODS get_instance_authorizations FOR INSTANCE AUTHORIZATION
      IMPORTING keys REQUEST requested_authorizations FOR ordertp RESULT result.

    METHODS get_global_authorizations FOR GLOBAL AUTHORIZATION
      IMPORTING REQUEST requested_authorizations FOR ordertp RESULT result.

    METHODS create FOR MODIFY
      IMPORTING entities FOR CREATE ordertp.

    METHODS precheck_create FOR PRECHECK
      IMPORTING entities FOR CREATE ordertp.

    METHODS update FOR MODIFY
      IMPORTING entities FOR UPDATE ordertp.

    METHODS precheck_update FOR PRECHECK
      IMPORTING entities FOR UPDATE ordertp.

    METHODS delete FOR MODIFY
      IMPORTING keys FOR DELETE ordertp.

    METHODS precheck_delete FOR PRECHECK
      IMPORTING keys FOR DELETE ordertp.

    METHODS read FOR READ
      IMPORTING keys FOR READ ordertp RESULT result.

    METHODS lock FOR LOCK
      IMPORTING keys FOR LOCK ordertp.

    METHODS rba_items_tp FOR READ
      IMPORTING keys_rba FOR READ ordertp\_items_tp FULL result_requested RESULT result LINK association_links.

    METHODS cba_items_tp FOR MODIFY
      IMPORTING entities_cba FOR CREATE ordertp\_items_tp.

    METHODS getallitems FOR READ
      IMPORTING keys FOR FUNCTION ordertp~getallitems REQUEST requested_fields RESULT result.

    METHODS getmajorsupplier FOR READ
      IMPORTING keys FOR FUNCTION ordertp~getmajorsupplier RESULT result.

    METHODS getstatushistory FOR READ
      IMPORTING keys FOR FUNCTION ordertp~getstatushistory RESULT result.

    METHODS issupplierblacklisted FOR READ
      IMPORTING keys FOR FUNCTION ordertp~issupplierblacklisted RESULT result.

    METHODS activate FOR MODIFY
      IMPORTING keys FOR ACTION ordertp~activate.

    METHODS changestatus FOR MODIFY
      IMPORTING keys FOR ACTION ordertp~changestatus.

    METHODS precheck_changestatus FOR PRECHECK
      IMPORTING keys FOR ACTION ordertp~changestatus.

    METHODS createfromtemplate FOR MODIFY
      IMPORTING keys FOR ACTION ordertp~createfromtemplate.

    METHODS discard FOR MODIFY
      IMPORTING keys FOR ACTION ordertp~discard.

    METHODS edit FOR MODIFY
      IMPORTING keys FOR ACTION ordertp~edit.

    METHODS resume FOR MODIFY
      IMPORTING keys FOR ACTION ordertp~resume.

    METHODS revalidatepricingrules FOR MODIFY
      IMPORTING keys FOR ACTION ordertp~revalidatepricingrules RESULT result.

    METHODS sendorderstatistictoazure FOR MODIFY
      IMPORTING keys FOR ACTION ordertp~sendorderstatistictoazure.

    METHODS determinenames FOR DETERMINE ON MODIFY
      IMPORTING keys FOR ordertp~determinenames.

    METHODS recalculateshippingmethod FOR DETERMINE ON MODIFY
      IMPORTING keys FOR ordertp~recalculateshippingmethod.

    METHODS calctotalamount FOR DETERMINE ON SAVE
      IMPORTING keys FOR ordertp~calctotalamount.

    METHODS setcontroltimestamp FOR DETERMINE ON SAVE
      IMPORTING keys FOR ordertp~setcontroltimestamp.

    METHODS checkbuyer FOR VALIDATE ON SAVE
      IMPORTING keys FOR ordertp~checkbuyer.

    METHODS checkdates FOR VALIDATE ON SAVE
      IMPORTING keys FOR ordertp~checkdates.

    METHODS checkheadercurrency FOR VALIDATE ON SAVE
      IMPORTING keys FOR ordertp~checkheadercurrency.

    METHODS checksupplier FOR VALIDATE ON SAVE
      IMPORTING keys FOR ordertp~checksupplier.

    METHODS precheck_cba_items_tp FOR PRECHECK
      IMPORTING entities FOR CREATE ordertp\_items_tp.

ENDCLASS.


CLASS lhc_ordertp IMPLEMENTATION.
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
         ENTITY ordertp
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
        <ls_result>-purchaseorderid = <ls_key>-purchaseorderid.
        <ls_result>-%features-%field-paymentterms = if_abap_behv=>fc-f-read_only.
        <ls_result>-%features-%delete             = if_abap_behv=>fc-o-disabled.
      ENDIF.
    ENDLOOP.
  ENDMETHOD.

  METHOD get_instance_authorizations.
    DATA lt_order_read_in TYPE TABLE FOR READ IMPORT zpru_u_purcorderhdr_tp\\ordertp. " qqq change to your type

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
         ENTITY ordertp
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
        <ls_result>-purchaseorderid = <ls_key>-purchaseorderid.
        <ls_result>-%update         = if_abap_behv=>auth-unauthorized.
        <ls_result>-%delete         = if_abap_behv=>auth-unauthorized.
        <ls_result>-%action-edit               = if_abap_behv=>auth-unauthorized.
        <ls_result>-%action-createfromtemplate = if_abap_behv=>auth-unauthorized.

        IF    requested_authorizations-%action-edit = if_abap_behv=>mk-on
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
        <ls_result>-purchaseorderid = <ls_key>-purchaseorderid.
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
                                                                    purchaseorderid = purchaseorderid ) ).

    LOOP AT entities ASSIGNING FIELD-SYMBOL(<ls_create>).

      IF    NOT line_exists( lcl_buffer=>root_buffer[ instance-purchaseorderid = <ls_create>-purchaseorderid
                                                      is_draft                 = <ls_create>-%is_draft ] )
         OR     line_exists( lcl_buffer=>root_buffer[ instance-purchaseorderid = <ls_create>-purchaseorderid
                                                      is_draft                 = <ls_create>-%is_draft
                                                      deleted                  = abap_true ] ).

        DELETE lcl_buffer=>root_buffer WHERE     instance-purchaseorderid = VALUE #( lcl_buffer=>root_buffer[
                                                                                         instance-purchaseorderid = <ls_create>-purchaseorderid
                                                                                         is_draft                 = <ls_create>-%is_draft ]-instance-purchaseorderid OPTIONAL )
                                             AND is_draft                 = <ls_create>-%is_draft
                                             AND deleted                  = abap_true.

        APPEND VALUE #(
            cid                       = <ls_create>-%cid
            is_draft                  = <ls_create>-%is_draft
            instance-purchaseorderid  = <ls_create>-purchaseorderid
            instance-orderdate        = COND #( WHEN <ls_create>-%control-orderdate <> if_abap_behv=>mk-off
                                                THEN <ls_create>-orderdate )
            instance-supplierid       = COND #( WHEN <ls_create>-%control-supplierid <> if_abap_behv=>mk-off
                                                THEN <ls_create>-supplierid )
            instance-suppliername     = COND #( WHEN <ls_create>-%control-suppliername <> if_abap_behv=>mk-off
                                                THEN <ls_create>-suppliername )
            instance-buyerid          = COND #( WHEN <ls_create>-%control-buyerid <> if_abap_behv=>mk-off
                                                THEN <ls_create>-buyerid )
            instance-buyername        = COND #( WHEN <ls_create>-%control-buyername <> if_abap_behv=>mk-off
                                                THEN <ls_create>-buyername )
            instance-totalamount      = COND #( WHEN <ls_create>-%control-totalamount <> if_abap_behv=>mk-off
                                                THEN <ls_create>-totalamount )
            instance-headercurrency   = COND #( WHEN <ls_create>-%control-headercurrency <> if_abap_behv=>mk-off
                                                THEN <ls_create>-headercurrency )
            instance-deliverydate     = COND #( WHEN <ls_create>-%control-deliverydate <> if_abap_behv=>mk-off
                                                THEN <ls_create>-deliverydate )
            instance-status           = COND #( WHEN <ls_create>-%control-status <> if_abap_behv=>mk-off
                                                THEN <ls_create>-status )
            instance-paymentterms     = COND #( WHEN <ls_create>-%control-paymentterms <> if_abap_behv=>mk-off
                                                THEN <ls_create>-paymentterms )
            instance-shippingmethod   = COND #( WHEN <ls_create>-%control-shippingmethod <> if_abap_behv=>mk-off
                                                THEN <ls_create>-shippingmethod )
            instance-controltimestamp = COND #( WHEN <ls_create>-%control-controltimestamp <> if_abap_behv=>mk-off
                                                THEN <ls_create>-controltimestamp )
            instance-createdby        = COND #( WHEN <ls_create>-%control-createdby <> if_abap_behv=>mk-off
                                                THEN <ls_create>-createdby )
            instance-createon         = COND #( WHEN <ls_create>-%control-createon <> if_abap_behv=>mk-off
                                                THEN <ls_create>-createon )
            instance-changedby        = COND #( WHEN <ls_create>-%control-changedby <> if_abap_behv=>mk-off
                                                THEN <ls_create>-changedby )
            instance-changedon        = COND #( WHEN <ls_create>-%control-changedon <> if_abap_behv=>mk-off
                                                THEN <ls_create>-changedon )
            " qqq make sure that your made you admin fields managed by RAP framework
            " it is expected that createOn already have been filled by time value
            " otherwise check semantic annotation on your transactional CDS
            instance-lastchanged      = <ls_create>-createon

            newly_created             = abap_true " qqq to raise event on order creation I must distinct created and updated instances
            " alternatively we can check db via select, but flag is likely be easier.

            changed                   = abap_true
            deleted                   = abap_false ) TO lcl_buffer=>root_buffer.

        INSERT VALUE #( %cid      = <ls_create>-%cid
                        %key      = <ls_create>-%key
                        %is_draft = <ls_create>-%is_draft ) INTO TABLE mapped-ordertp.

        APPEND VALUE #( %msg            = new_message_with_text( severity = if_abap_behv_message=>severity-success
                                                                 text     = 'create: Ok!' )
                        purchaseorderid = <ls_create>-purchaseorderid
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
    SELECT purchaseorderid FROM zpru_u_purcorderhdr_tp " qqq use your transactional CDS
      FOR ALL ENTRIES IN @entities
      WHERE purchaseorderid = @entities-purchaseorderid
      INTO TABLE @DATA(lt_existing_po).

    LOOP AT entities ASSIGNING FIELD-SYMBOL(<ls_entity>).
      IF NOT line_exists( lt_existing_po[ table_line = <ls_entity>-purchaseorderid ] ).
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
    lcl_buffer=>prep_root_buffer( CORRESPONDING #( entities MAPPING purchaseorderid = purchaseorderid
                                                                    is_draft        = %is_draft ) ).

    LOOP AT entities ASSIGNING FIELD-SYMBOL(<ls_update>).

      READ TABLE lcl_buffer=>root_buffer
           WITH KEY instance-purchaseorderid = <ls_update>-purchaseorderid
                    is_draft                 = <ls_update>-%is_draft
                    deleted                  = abap_false ASSIGNING FIELD-SYMBOL(<ls_up>).
      IF sy-subrc = 0.
        <ls_up>-instance-orderdate        = COND #( WHEN <ls_update>-%control-orderdate <> if_abap_behv=>mk-off
                                                    THEN <ls_update>-orderdate
                                                    ELSE <ls_up>-instance-orderdate ).
        <ls_up>-instance-supplierid       = COND #( WHEN <ls_update>-%control-supplierid <> if_abap_behv=>mk-off
                                                    THEN <ls_update>-supplierid
                                                    ELSE <ls_up>-instance-supplierid ).
        <ls_up>-instance-suppliername     = COND #( WHEN <ls_update>-%control-suppliername <> if_abap_behv=>mk-off
                                                    THEN <ls_update>-suppliername
                                                    ELSE <ls_up>-instance-suppliername ).
        <ls_up>-instance-buyerid          = COND #( WHEN <ls_update>-%control-buyerid <> if_abap_behv=>mk-off
                                                    THEN <ls_update>-buyerid
                                                    ELSE <ls_up>-instance-buyerid ).
        <ls_up>-instance-buyername        = COND #( WHEN <ls_update>-%control-buyername <> if_abap_behv=>mk-off
                                                    THEN <ls_update>-buyername
                                                    ELSE <ls_up>-instance-buyername ).
        <ls_up>-instance-totalamount      = COND #( WHEN <ls_update>-%control-totalamount <> if_abap_behv=>mk-off
                                                    THEN <ls_update>-totalamount
                                                    ELSE <ls_up>-instance-totalamount ).
        <ls_up>-instance-headercurrency   = COND #( WHEN <ls_update>-%control-headercurrency <> if_abap_behv=>mk-off
                                                    THEN <ls_update>-headercurrency
                                                    ELSE <ls_up>-instance-headercurrency ).
        <ls_up>-instance-deliverydate     = COND #( WHEN <ls_update>-%control-deliverydate <> if_abap_behv=>mk-off
                                                    THEN <ls_update>-deliverydate
                                                    ELSE <ls_up>-instance-deliverydate ).
        <ls_up>-instance-status           = COND #( WHEN <ls_update>-%control-status <> if_abap_behv=>mk-off
                                                    THEN <ls_update>-status
                                                    ELSE <ls_up>-instance-status ).
        <ls_up>-instance-paymentterms     = COND #( WHEN <ls_update>-%control-paymentterms <> if_abap_behv=>mk-off
                                                    THEN <ls_update>-paymentterms
                                                    ELSE <ls_up>-instance-paymentterms ).
        <ls_up>-instance-shippingmethod   = COND #( WHEN <ls_update>-%control-shippingmethod <> if_abap_behv=>mk-off
                                                    THEN <ls_update>-shippingmethod
                                                    ELSE <ls_up>-instance-shippingmethod ).
        <ls_up>-instance-controltimestamp = COND #( WHEN <ls_update>-%control-controltimestamp <> if_abap_behv=>mk-off
                                                    THEN <ls_update>-controltimestamp
                                                    ELSE <ls_up>-instance-controltimestamp ).
        <ls_up>-instance-createdby        = COND #( WHEN <ls_update>-%control-createdby <> if_abap_behv=>mk-off
                                                    THEN <ls_update>-createdby
                                                    ELSE <ls_up>-instance-createdby ).
        <ls_up>-instance-createon         = COND #( WHEN <ls_update>-%control-createon <> if_abap_behv=>mk-off
                                                    THEN <ls_update>-createon
                                                    ELSE <ls_up>-instance-createon ).
        <ls_up>-instance-changedby        = COND #( WHEN <ls_update>-%control-changedby <> if_abap_behv=>mk-off
                                                    THEN <ls_update>-changedby
                                                    ELSE <ls_up>-instance-changedby ).
        <ls_up>-instance-changedon        = COND #( WHEN <ls_update>-%control-changedon <> if_abap_behv=>mk-off
                                                    THEN <ls_update>-changedon
                                                    ELSE <ls_up>-instance-changedon ).
        " qqq make sure that your made you admin fields managed by RAP framework
        " it is expected that createOn already have been filled by time value
        " otherwise check semantic annotation on your transactional CDS
        <ls_up>-instance-lastchanged      = COND #( WHEN <ls_update>-changedon IS NOT INITIAL
                                                    THEN <ls_update>-changedon
                                                    ELSE <ls_up>-instance-lastchanged ).
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
    lcl_buffer=>prep_root_buffer( CORRESPONDING #( keys MAPPING purchaseorderid = purchaseorderid
                                                                is_draft        = %is_draft ) ).

    lcl_buffer=>prep_child_buffer( CORRESPONDING #( keys MAPPING purchaseorderid = purchaseorderid
                                                                 is_draft        = %is_draft ) ).

    LOOP AT keys ASSIGNING FIELD-SYMBOL(<ls_delete>).
      READ TABLE lcl_buffer=>root_buffer
           WITH KEY instance-purchaseorderid = <ls_delete>-purchaseorderid
                    is_draft                 = <ls_delete>-%is_draft
                    deleted                  = abap_false ASSIGNING FIELD-SYMBOL(<ls_del>).

      IF sy-subrc = 0.

        <ls_del>-newly_created = abap_false. " qqq for event on created order

        <ls_del>-changed       = abap_false.
        <ls_del>-deleted       = abap_true.
        " qqq cascade delete
        LOOP AT lcl_buffer=>child_buffer ASSIGNING FIELD-SYMBOL(<ls_child_del>)
             WHERE     instance-purchaseorderid = <ls_del>-instance-purchaseorderid
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
    lcl_buffer=>prep_root_buffer( CORRESPONDING #( keys MAPPING purchaseorderid = purchaseorderid
                                                                is_draft        = %is_draft ) ).

    LOOP AT keys ASSIGNING FIELD-SYMBOL(<ls_read>) GROUP BY <ls_read>-%tky.
      READ TABLE lcl_buffer=>root_buffer
           WITH KEY instance-purchaseorderid = <ls_read>-purchaseorderid
                    is_draft                 = <ls_read>-%is_draft
                    deleted                  = abap_false ASSIGNING FIELD-SYMBOL(<ls_r>).
      IF sy-subrc = 0.

        APPEND VALUE #( %tky             = <ls_read>-%tky
                        orderdate        = COND #( WHEN <ls_read>-%control-orderdate <> if_abap_behv=>mk-off
                                                   THEN <ls_r>-instance-orderdate )
                        supplierid       = COND #( WHEN <ls_read>-%control-supplierid <> if_abap_behv=>mk-off
                                                   THEN <ls_r>-instance-supplierid )
                        suppliername     = COND #( WHEN <ls_read>-%control-suppliername <> if_abap_behv=>mk-off
                                                   THEN <ls_r>-instance-suppliername )
                        buyerid          = COND #( WHEN <ls_read>-%control-buyerid <> if_abap_behv=>mk-off
                                                   THEN <ls_r>-instance-buyerid )
                        buyername        = COND #( WHEN <ls_read>-%control-buyername <> if_abap_behv=>mk-off
                                                   THEN <ls_r>-instance-buyername )
                        totalamount      = COND #( WHEN <ls_read>-%control-totalamount <> if_abap_behv=>mk-off
                                                   THEN <ls_r>-instance-totalamount )
                        headercurrency   = COND #( WHEN <ls_read>-%control-headercurrency <> if_abap_behv=>mk-off
                                                   THEN <ls_r>-instance-headercurrency )
                        deliverydate     = COND #( WHEN <ls_read>-%control-deliverydate <> if_abap_behv=>mk-off
                                                   THEN <ls_r>-instance-deliverydate )
                        status           = COND #( WHEN <ls_read>-%control-status <> if_abap_behv=>mk-off
                                                   THEN <ls_r>-instance-status )
                        paymentterms     = COND #( WHEN <ls_read>-%control-paymentterms <> if_abap_behv=>mk-off
                                                   THEN <ls_r>-instance-paymentterms )
                        shippingmethod   = COND #( WHEN <ls_read>-%control-shippingmethod <> if_abap_behv=>mk-off
                                                   THEN <ls_r>-instance-shippingmethod )
                        controltimestamp = COND #( WHEN <ls_read>-%control-controltimestamp <> if_abap_behv=>mk-off
                                                   THEN <ls_r>-instance-controltimestamp )
                        createdby        = COND #( WHEN <ls_read>-%control-createdby <> if_abap_behv=>mk-off
                                                   THEN <ls_r>-instance-createdby )
                        createon         = COND #( WHEN <ls_read>-%control-createon <> if_abap_behv=>mk-off
                                                   THEN <ls_r>-instance-createon )
                        changedby        = COND #( WHEN <ls_read>-%control-changedby <> if_abap_behv=>mk-off
                                                   THEN <ls_r>-instance-changedby )
                        changedon        = COND #( WHEN <ls_read>-%control-changedon <> if_abap_behv=>mk-off
                                                   THEN <ls_r>-instance-changedon )
                        " qqq you must return the value, otherwise update will not work
                        lastchanged      = COND #( WHEN <ls_read>-%control-lastchanged <> if_abap_behv=>mk-off
                                                   THEN <ls_r>-instance-lastchanged ) ) TO result.

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

  METHOD rba_items_tp.
    lcl_buffer=>prep_root_buffer( CORRESPONDING #( keys_rba MAPPING purchaseorderid = purchaseorderid
                                                                    is_draft        = %is_draft ) ).
    lcl_buffer=>prep_child_buffer( CORRESPONDING #( keys_rba MAPPING purchaseorderid = purchaseorderid
                                                                    is_draft        = %is_draft ) ).

    LOOP AT keys_rba ASSIGNING FIELD-SYMBOL(<ls_rba>) GROUP BY <ls_rba>-%tky.
      IF     line_exists( lcl_buffer=>root_buffer[ instance-purchaseorderid = <ls_rba>-purchaseorderid
                                                   is_draft                 = <ls_rba>-%is_draft
                                                   deleted                  = abap_false ] )
         AND line_exists( lcl_buffer=>child_buffer[ instance-purchaseorderid = <ls_rba>-purchaseorderid
                                                    is_draft                 = <ls_rba>-%is_draft
                                                    deleted                  = abap_false ] ).

        LOOP AT lcl_buffer=>child_buffer ASSIGNING FIELD-SYMBOL(<ls_ch>) WHERE     instance-purchaseorderid = <ls_rba>-purchaseorderid
                                                                               AND is_draft                 = <ls_rba>-%is_draft
                                                                               AND deleted                  = abap_false.
          INSERT VALUE #( source-%tky = <ls_rba>-%tky
                          target-%tky = VALUE #( purchaseorderid = <ls_ch>-instance-purchaseorderid
                                                 itemid          = <ls_ch>-instance-itemid
                                                 %is_draft       = <ls_ch>-is_draft ) ) INTO TABLE association_links.
          IF result_requested = abap_false.
            CONTINUE.
          ENDIF.

          APPEND VALUE #( %tky              = CORRESPONDING #( <ls_rba>-%tky )
                          itemid            = <ls_ch>-instance-itemid
                          itemnumber        = COND #( WHEN <ls_rba>-%control-itemnumber <> if_abap_behv=>mk-off
                                                      THEN <ls_ch>-instance-itemnumber )
                          productid         = COND #( WHEN <ls_rba>-%control-productid <> if_abap_behv=>mk-off
                                                      THEN <ls_ch>-instance-productid )
                          productname       = COND #( WHEN <ls_rba>-%control-productname <> if_abap_behv=>mk-off
                                                      THEN <ls_ch>-instance-productname )
                          quantity          = COND #( WHEN <ls_rba>-%control-quantity <> if_abap_behv=>mk-off
                                                      THEN <ls_ch>-instance-quantity )
                          unitprice         = COND #( WHEN <ls_rba>-%control-unitprice <> if_abap_behv=>mk-off
                                                      THEN <ls_ch>-instance-unitprice )
                          totalprice        = COND #( WHEN <ls_rba>-%control-totalprice <> if_abap_behv=>mk-off
                                                      THEN <ls_ch>-instance-totalprice )
                          deliverydate      = COND #( WHEN <ls_rba>-%control-deliverydate <> if_abap_behv=>mk-off
                                                      THEN <ls_ch>-instance-deliverydate )
                          warehouselocation = COND #( WHEN <ls_rba>-%control-warehouselocation <> if_abap_behv=>mk-off
                                                      THEN <ls_ch>-instance-warehouselocation )
                          itemcurrency      = COND #( WHEN <ls_rba>-%control-itemcurrency <> if_abap_behv=>mk-off
                                                      THEN <ls_ch>-instance-itemcurrency )
                          isurgent          = COND #( WHEN <ls_rba>-%control-isurgent <> if_abap_behv=>mk-off
                                                      THEN <ls_ch>-instance-isurgent )
                          createdby         = COND #( WHEN <ls_rba>-%control-createdby <> if_abap_behv=>mk-off
                                                      THEN <ls_ch>-instance-createdby )
                          createon          = COND #( WHEN <ls_rba>-%control-createon <> if_abap_behv=>mk-off
                                                      THEN <ls_ch>-instance-createon )
                          changedby         = COND #( WHEN <ls_rba>-%control-changedby <> if_abap_behv=>mk-off
                                                      THEN <ls_ch>-instance-changedby )
                          changedon         = COND #( WHEN <ls_rba>-%control-changedon <> if_abap_behv=>mk-off
                                                      THEN <ls_ch>-instance-changedon ) ) TO result.
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

  METHOD cba_items_tp.
    DATA lt_root_update           TYPE TABLE FOR UPDATE zpru_u_purcorderhdr_tp\\ordertp. " qqq change names on your BDEF
    DATA lt_calculatetotalprice_d TYPE lif_business_object=>tt_calculatetotalprice_d.
    DATA ls_reported_late         TYPE lif_business_object=>ts_reported_late.

    lcl_buffer=>prep_root_buffer( CORRESPONDING #( entities_cba MAPPING purchaseorderid = purchaseorderid
                                                                        is_draft        = %is_draft ) ).
    lcl_buffer=>prep_child_buffer( CORRESPONDING #( entities_cba MAPPING purchaseorderid = purchaseorderid
                                                                        is_draft        = %is_draft ) ).
    LOOP AT entities_cba ASSIGNING FIELD-SYMBOL(<ls_cba>) GROUP BY <ls_cba>-%tky.
      IF line_exists( lcl_buffer=>root_buffer[ instance-purchaseorderid = <ls_cba>-purchaseorderid
                                               is_draft                 = <ls_cba>-%is_draft
                                               deleted                  = abap_false ] ).

        LOOP AT <ls_cba>-%target ASSIGNING FIELD-SYMBOL(<ls_ch>).

          IF     (    NOT line_exists( lcl_buffer=>child_buffer[ instance-purchaseorderid = <ls_cba>-purchaseorderid
                                                                 is_draft                 = <ls_cba>-%is_draft
                                                                 instance-itemid          = <ls_ch>-itemid ] )
                   OR
                          line_exists( lcl_buffer=>child_buffer[ instance-purchaseorderid = <ls_cba>-purchaseorderid
                                                                 instance-itemid          = <ls_ch>-itemid
                                                                 is_draft                 = <ls_cba>-%is_draft
                                                                 deleted                  = abap_true ] ) )

             AND <ls_ch>-itemid IS NOT INITIAL.

            ASSIGN lcl_buffer=>child_buffer[ instance-purchaseorderid = <ls_cba>-purchaseorderid
                                             is_draft                 = <ls_cba>-%is_draft
                                             instance-itemid          = <ls_ch>-itemid
                                             deleted                  = abap_true ] TO FIELD-SYMBOL(<ls_deleted_item>).
            IF sy-subrc = 0.
              DELETE lcl_buffer=>child_buffer
                     WHERE     instance-purchaseorderid = <ls_deleted_item>-instance-purchaseorderid
                           AND instance-itemid          = <ls_deleted_item>-instance-itemid
                           AND is_draft                 = <ls_deleted_item>-is_draft
                           AND deleted                  = abap_true.
            ENDIF.

            APPEND VALUE #(
                cid_ref                    = <ls_cba>-%cid_ref
                cid_target                 = <ls_ch>-%cid
                is_draft                   = <ls_cba>-%is_draft
                instance-purchaseorderid   = <ls_cba>-purchaseorderid
                instance-itemid            = <ls_ch>-itemid
                instance-itemnumber        = COND #( WHEN <ls_ch>-%control-itemnumber <> if_abap_behv=>mk-off
                                                     THEN <ls_ch>-itemnumber )
                instance-productid         = COND #( WHEN <ls_ch>-%control-productid <> if_abap_behv=>mk-off
                                                     THEN <ls_ch>-productid )
                instance-productname       = COND #( WHEN <ls_ch>-%control-productname <> if_abap_behv=>mk-off
                                                     THEN <ls_ch>-productname )
                instance-quantity          = COND #( WHEN <ls_ch>-%control-quantity <> if_abap_behv=>mk-off
                                                     THEN <ls_ch>-quantity )
                instance-unitprice         = COND #( WHEN <ls_ch>-%control-unitprice <> if_abap_behv=>mk-off
                                                     THEN <ls_ch>-unitprice )
                instance-totalprice        = COND #( WHEN <ls_ch>-%control-totalprice <> if_abap_behv=>mk-off
                                                     THEN <ls_ch>-totalprice )
                instance-deliverydate      = COND #( WHEN <ls_ch>-%control-deliverydate <> if_abap_behv=>mk-off
                                                     THEN <ls_ch>-deliverydate )
                instance-warehouselocation = COND #( WHEN <ls_ch>-%control-warehouselocation <> if_abap_behv=>mk-off
                                                     THEN <ls_ch>-warehouselocation )
                instance-itemcurrency      = COND #( WHEN <ls_ch>-%control-itemcurrency <> if_abap_behv=>mk-off
                                                     THEN <ls_ch>-itemcurrency )
                instance-isurgent          = COND #( WHEN <ls_ch>-%control-isurgent <> if_abap_behv=>mk-off
                                                     THEN <ls_ch>-isurgent )
                instance-createdby         = COND #( WHEN <ls_ch>-%control-createdby <> if_abap_behv=>mk-off
                                                     THEN <ls_ch>-createdby )
                instance-createon          = COND #( WHEN <ls_ch>-%control-createon <> if_abap_behv=>mk-off
                                                     THEN <ls_ch>-createon )
                instance-changedby         = COND #( WHEN <ls_ch>-%control-changedby <> if_abap_behv=>mk-off
                                                     THEN <ls_ch>-changedby )
                instance-changedon         = COND #( WHEN <ls_ch>-%control-changedon <> if_abap_behv=>mk-off
                                                     THEN <ls_ch>-changedon )
                changed                    = abap_true ) TO lcl_buffer=>child_buffer.

            APPEND INITIAL LINE TO lt_root_update ASSIGNING FIELD-SYMBOL(<ls_root_update>).
            <ls_root_update>-purchaseorderid = <ls_cba>-purchaseorderid.
            <ls_root_update>-%is_draft       = <ls_cba>-%is_draft.

            INSERT VALUE #( %cid      = <ls_ch>-%cid
                            %is_draft = <ls_cba>-%is_draft
                            %key      = VALUE #( purchaseorderid = <ls_cba>-purchaseorderid
                                                 itemid          = <ls_ch>-itemid ) ) INTO TABLE mapped-itemtp.

            APPEND INITIAL LINE TO lt_calculatetotalprice_d ASSIGNING FIELD-SYMBOL(<ls_calculatetotalprice_d>).
            <ls_calculatetotalprice_d>-purchaseorderid = <ls_cba>-purchaseorderid.
            <ls_calculatetotalprice_d>-itemid          = <ls_ch>-itemid.

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
                            %key        = VALUE #( purchaseorderid = <ls_cba>-purchaseorderid
                                                   itemid          = <ls_ch>-itemid )
                            %fail-cause = if_abap_behv=>cause-dependency ) TO failed-itemtp.

            APPEND VALUE #( %cid = <ls_ch>-%cid
                            %key = VALUE #( purchaseorderid = <ls_cba>-purchaseorderid
                                            itemid          = <ls_ch>-itemid )
                            %msg = new_message_with_text( severity = if_abap_behv_message=>severity-error
                                                          text     = 'CBA operation (root to child) failed.' ) )
                   TO reported-itemtp.

          ENDIF.
        ENDLOOP.

        SORT lt_root_update BY purchaseorderid
                               %is_draft.
        DELETE ADJACENT DUPLICATES FROM lt_root_update COMPARING purchaseorderid %is_draft.

        GET TIME STAMP FIELD DATA(lv_now). " qqq if added item -- update etag field
        LOOP AT lt_root_update ASSIGNING <ls_root_update>.
          <ls_root_update>-changedon = lv_now.
          <ls_root_update>-%control-changedon = if_abap_behv=>mk-on.
        ENDLOOP.

        IF lt_root_update IS NOT INITIAL.
          MODIFY ENTITIES OF zpru_u_purcorderhdr_tp  " qqq change on your BDEF
                 IN LOCAL MODE
                 ENTITY ordertp UPDATE FROM lt_root_update.
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

    " determination on modify for items
    IF lt_calculatetotalprice_d IS NOT INITIAL.
      NEW lcl_det_val_manager( )->calculatetotalprice_in( EXPORTING keys     = lt_calculatetotalprice_d
                                                          CHANGING  reported = ls_reported_late ).
    ENDIF.
  ENDMETHOD.

  METHOD getallitems.
  ENDMETHOD.

  METHOD getmajorsupplier.
  ENDMETHOD.

  METHOD getstatushistory.
  ENDMETHOD.

  METHOD issupplierblacklisted.
  ENDMETHOD.

  METHOD activate.
    READ ENTITIES OF zpru_u_purcorderhdr_tp " use your base BDEF
         IN LOCAL MODE
         ENTITY ordertp
         ALL FIELDS WITH VALUE #( FOR <ls_k1>
                                  IN keys
                                  ( purchaseorderid = <ls_k1>-purchaseorderid
                                    %is_draft       = if_abap_behv=>mk-on ) )
         RESULT DATA(lt_order_draft).

    READ ENTITIES OF zpru_u_purcorderhdr_tp " use your base BDEF
         IN LOCAL MODE
         ENTITY ordertp BY \_items_tp
         ALL FIELDS WITH VALUE #( FOR <ls_k2>
                                  IN keys
                                  ( purchaseorderid = <ls_k2>-purchaseorderid
                                    %is_draft       = if_abap_behv=>mk-on ) )
         RESULT DATA(lt_items_draft).

    lcl_buffer=>prep_root_buffer( VALUE #( FOR <ls_k3>
                                           IN keys
                                           ( purchaseorderid = <ls_k3>-purchaseorderid
                                             is_draft        = if_abap_behv=>mk-off ) ) ).

    lcl_buffer=>prep_child_buffer( VALUE #( FOR <ls_k4>
                                            IN keys
                                            ( purchaseorderid = <ls_k4>-purchaseorderid
                                              is_draft        = if_abap_behv=>mk-off ) ) ).

    LOOP AT lt_order_draft ASSIGNING FIELD-SYMBOL(<ls_order_draft>).

      DELETE lcl_buffer=>root_buffer WHERE     instance-purchaseorderid = <ls_order_draft>-purchaseorderid
                                           AND is_draft                 = if_abap_behv=>mk-on
                                           AND deleted                  = abap_false.

      LOOP AT lt_items_draft ASSIGNING FIELD-SYMBOL(<ls_item_draft>)
           WHERE purchaseorderid = <ls_order_draft>-purchaseorderid.

        DELETE lcl_buffer=>child_buffer WHERE     instance-purchaseorderid = <ls_item_draft>-purchaseorderid
                                              AND instance-itemid          = <ls_item_draft>-itemid
                                              AND is_draft                 = if_abap_behv=>mk-on
                                              AND deleted                  = abap_false.
      ENDLOOP.
    ENDLOOP.
  ENDMETHOD.

  METHOD changestatus.
    DATA lt_po_update TYPE TABLE FOR UPDATE zpru_u_purcorderhdr_tp\\ordertp. " qqq change on your type

    IF keys IS INITIAL.
      APPEND INITIAL LINE TO reported-%other ASSIGNING FIELD-SYMBOL(<lo_reported>).
      <lo_reported> = new_message( id       = zpru_if_m_po=>gc_po_message_class
                                   number   = '001'
                                   severity = if_abap_behv_message=>severity-error ).
      RETURN.
    ENDIF.

    READ ENTITIES OF zpru_u_purcorderhdr_tp
         IN LOCAL MODE
         ENTITY ordertp
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
        <ls_failed>-%action-changestatus = if_abap_behv=>mk-on.
        CONTINUE.
      ENDIF.

      APPEND INITIAL LINE TO lt_po_update ASSIGNING FIELD-SYMBOL(<ls_order_update>).
      <ls_order_update>-%tky = <ls_instance>-%tky.
      <ls_order_update>-%data-status = <ls_key>-%param-newstatus.
      <ls_order_update>-%control-status = if_abap_behv=>mk-on.

    ENDLOOP.

    " update status
    IF lt_po_update IS NOT INITIAL.
      MODIFY ENTITIES OF zpru_u_purcorderhdr_tp
             IN LOCAL MODE
             ENTITY ordertp
             UPDATE FROM lt_po_update.
    ENDIF.
  ENDMETHOD.

  METHOD precheck_changestatus.
  ENDMETHOD.

  METHOD createfromtemplate.
  ENDMETHOD.

  METHOD discard.
    lcl_buffer=>prep_root_buffer( VALUE #( FOR <ls_k3>
                                           IN keys
                                           ( purchaseorderid = <ls_k3>-purchaseorderid
                                             is_draft        = if_abap_behv=>mk-off ) ) ).

    lcl_buffer=>prep_child_buffer( VALUE #( FOR <ls_k4>
                                            IN keys
                                            ( purchaseorderid = <ls_k4>-purchaseorderid
                                              is_draft        = if_abap_behv=>mk-off ) ) ).

    LOOP AT keys ASSIGNING FIELD-SYMBOL(<ls_key>).

      DELETE lcl_buffer=>root_buffer WHERE     instance-purchaseorderid = <ls_key>-purchaseorderid
                                           AND is_draft                 = if_abap_behv=>mk-on
                                           AND deleted                  = abap_false.

      DELETE lcl_buffer=>child_buffer
             WHERE     instance-purchaseorderid = <ls_key>-purchaseorderid
                   AND is_draft                 = if_abap_behv=>mk-on
                   AND deleted                  = abap_false.
    ENDLOOP.
  ENDMETHOD.

  METHOD edit.
    READ ENTITIES OF zpru_u_purcorderhdr_tp " use your base BDEF
         IN LOCAL MODE
         ENTITY ordertp
         ALL FIELDS WITH VALUE #( FOR <ls_k1>
                                  IN keys
                                  ( purchaseorderid = <ls_k1>-purchaseorderid
                                    %is_draft       = if_abap_behv=>mk-off ) )
         RESULT DATA(lt_order_active).

    READ ENTITIES OF zpru_u_purcorderhdr_tp " use your base BDEF
         IN LOCAL MODE
         ENTITY ordertp BY \_items_tp
         ALL FIELDS WITH VALUE #( FOR <ls_k2>
                                  IN keys
                                  ( purchaseorderid = <ls_k2>-purchaseorderid
                                    %is_draft       = if_abap_behv=>mk-off ) )
         RESULT DATA(lt_items_active).

    LOOP AT lt_order_active ASSIGNING FIELD-SYMBOL(<ls_order_active>).

      DELETE lcl_buffer=>root_buffer WHERE     instance-purchaseorderid = <ls_order_active>-purchaseorderid
                                           AND is_draft                 = if_abap_behv=>mk-off
                                           AND deleted                  = abap_false.

      LOOP AT lt_items_active ASSIGNING FIELD-SYMBOL(<ls_item_active>)
           WHERE purchaseorderid = <ls_order_active>-purchaseorderid.

        DELETE lcl_buffer=>child_buffer WHERE     instance-purchaseorderid = <ls_item_active>-purchaseorderid
                                              AND instance-itemid          = <ls_item_active>-itemid
                                              AND is_draft                 = if_abap_behv=>mk-off
                                              AND deleted                  = abap_false.
      ENDLOOP.
    ENDLOOP.
  ENDMETHOD.

  METHOD resume.
    lcl_buffer=>prep_root_buffer( VALUE #( FOR <ls_k1>
                                           IN keys
                                           ( purchaseorderid = <ls_k1>-purchaseorderid
                                             is_draft        = if_abap_behv=>mk-on ) ) ).

    lcl_buffer=>prep_child_buffer( VALUE #( FOR <ls_k1>
                                            IN keys
                                            ( purchaseorderid = <ls_k1>-purchaseorderid
                                              is_draft        = if_abap_behv=>mk-on ) ) ).
  ENDMETHOD.

  METHOD revalidatepricingrules.
  ENDMETHOD.

  METHOD sendorderstatistictoazure.
  ENDMETHOD.

  METHOD determinenames.
    NEW lcl_det_val_manager( )->determinenames_in( EXPORTING keys     = keys
                                                   CHANGING  reported = reported ).
  ENDMETHOD.

  METHOD recalculateshippingmethod.
    NEW lcl_det_val_manager( )->recalculateshippingmethod_in( EXPORTING keys     = keys
                                                              CHANGING  reported = reported ).
  ENDMETHOD.

  METHOD calctotalamount.
    NEW lcl_det_val_manager( )->calctotalamount_in( EXPORTING keys     = keys
                                                    CHANGING  reported = reported ).
  ENDMETHOD.

  METHOD setcontroltimestamp.
    NEW lcl_det_val_manager( )->setcontroltimestamp_in( EXPORTING keys     = keys
                                                        CHANGING  reported = reported ).
  ENDMETHOD.

  METHOD checkbuyer.
    NEW lcl_det_val_manager( )->checkbuyer_in( EXPORTING keys     = keys
                                               CHANGING  failed   = failed
                                                         reported = reported ).
  ENDMETHOD.

  METHOD checkdates.
    NEW lcl_det_val_manager( )->checkdates_in( EXPORTING keys     = keys
                                               CHANGING  failed   = failed
                                                         reported = reported ).
  ENDMETHOD.

  METHOD checkheadercurrency.
    NEW lcl_det_val_manager( )->checkheadercurrency_in( EXPORTING keys     = keys
                                                        CHANGING  failed   = failed
                                                                  reported = reported ).
  ENDMETHOD.

  METHOD checksupplier.
    NEW lcl_det_val_manager( )->checksupplier_in( EXPORTING keys     = keys
                                                  CHANGING  failed   = failed
                                                            reported = reported ).
  ENDMETHOD.

  METHOD precheck_cba_items_tp.
    SELECT purchaseorderid, itemid FROM zpru_u_purcorderitem_tp " qqq use your transactional CDS
      FOR ALL ENTRIES IN @entities
      WHERE purchaseorderid = @entities-purchaseorderid
      INTO TABLE @DATA(lt_existing_items).

    LOOP AT entities ASSIGNING FIELD-SYMBOL(<ls_entity>).
      LOOP AT <ls_entity>-%target ASSIGNING FIELD-SYMBOL(<ls_item>).
        IF NOT line_exists( lt_existing_items[ purchaseorderid = <ls_entity>-purchaseorderid
                                               itemid          = <ls_item>-itemid ] ).
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
                        %key        = VALUE #( purchaseorderid = <ls_entity>-purchaseorderid
                                               itemid          = <ls_item>-itemid )
                        %fail-cause = if_abap_behv=>cause-dependency ) TO failed-itemtp.

        APPEND VALUE #( %cid = <ls_item>-%cid
                        %key = VALUE #( purchaseorderid = <ls_entity>-purchaseorderid
                                        itemid          = <ls_item>-itemid )
                        %msg = new_message_with_text( severity = if_abap_behv_message=>severity-error
                                                      text     = 'root to child failed - already exists2.' ) )
               TO reported-itemtp.
      ENDLOOP.
    ENDLOOP.
  ENDMETHOD.
ENDCLASS.


CLASS lhc_itemtp DEFINITION INHERITING FROM cl_abap_behavior_handler.
  PRIVATE SECTION.
    METHODS get_instance_authorizations FOR INSTANCE AUTHORIZATION
      IMPORTING keys REQUEST requested_authorizations FOR itemtp RESULT result.

    METHODS get_global_authorizations FOR GLOBAL AUTHORIZATION
      IMPORTING REQUEST requested_authorizations FOR itemtp RESULT result.

    METHODS update FOR MODIFY
      IMPORTING entities FOR UPDATE itemtp.

    METHODS delete FOR MODIFY
      IMPORTING keys FOR DELETE itemtp.

    METHODS read FOR READ
      IMPORTING keys FOR READ itemtp RESULT result.

    METHODS rba_header_tp FOR READ
      IMPORTING keys_rba FOR READ itemtp\_header_tp FULL result_requested RESULT result LINK association_links.

    METHODS getinventorystatus FOR READ
      IMPORTING keys FOR FUNCTION itemtp~getinventorystatus RESULT result.

    METHODS markasurgent FOR MODIFY
      IMPORTING keys FOR ACTION itemtp~markasurgent.

    METHODS calculatetotalprice FOR DETERMINE ON MODIFY
      IMPORTING keys FOR itemtp~calculatetotalprice.

    METHODS findwarehouselocation FOR DETERMINE ON SAVE
      IMPORTING keys FOR itemtp~findwarehouselocation.

    METHODS writeitemnumber FOR DETERMINE ON SAVE
      IMPORTING keys FOR itemtp~writeitemnumber.

    METHODS checkitemcurrency FOR VALIDATE ON SAVE
      IMPORTING keys FOR itemtp~checkitemcurrency.

    METHODS checkquantity FOR VALIDATE ON SAVE
      IMPORTING keys FOR itemtp~checkquantity.

ENDCLASS.


CLASS lhc_itemtp IMPLEMENTATION.
  METHOD get_instance_authorizations.
  ENDMETHOD.

  METHOD get_global_authorizations.
  ENDMETHOD.

  METHOD update.
    DATA lt_root_upd              TYPE TABLE FOR UPDATE zpru_u_purcorderhdr_tp. " use your base BDEF
    DATA lt_calculatetotalprice_d TYPE lif_business_object=>tt_calculatetotalprice_d.
    DATA ls_reported_late         TYPE lif_business_object=>ts_reported_late.

    lcl_buffer=>prep_child_buffer( VALUE #( FOR <ls_k>
                                            IN entities
                                            ( purchaseorderid = <ls_k>-purchaseorderid
                                              itemid          = <ls_k>-itemid
                                              is_draft        = <ls_k>-%is_draft
                                              full_key        = abap_true  ) ) ).

    LOOP AT entities ASSIGNING FIELD-SYMBOL(<ls_update>).

      READ TABLE lcl_buffer=>child_buffer
           WITH KEY instance-purchaseorderid = <ls_update>-purchaseorderid
                    instance-itemid          = <ls_update>-itemid
                    is_draft                 = <ls_update>-%is_draft
                    deleted                  = abap_false
           ASSIGNING FIELD-SYMBOL(<ls_up>).

      IF sy-subrc = 0.
        <ls_up>-instance-itemnumber        = COND #( WHEN <ls_update>-%control-itemnumber <> if_abap_behv=>mk-off
                                                     THEN <ls_update>-itemnumber
                                                     ELSE <ls_up>-instance-itemnumber ).
        <ls_up>-instance-productid         = COND #( WHEN <ls_update>-%control-productid <> if_abap_behv=>mk-off
                                                     THEN <ls_update>-productid
                                                     ELSE <ls_up>-instance-productid ).
        <ls_up>-instance-productname       = COND #( WHEN <ls_update>-%control-productname <> if_abap_behv=>mk-off
                                                     THEN <ls_update>-productname
                                                     ELSE <ls_up>-instance-productname ).
        <ls_up>-instance-quantity          = COND #( WHEN <ls_update>-%control-quantity <> if_abap_behv=>mk-off
                                                     THEN <ls_update>-quantity
                                                     ELSE <ls_up>-instance-quantity ).
        <ls_up>-instance-unitprice         = COND #( WHEN <ls_update>-%control-unitprice <> if_abap_behv=>mk-off
                                                     THEN <ls_update>-unitprice
                                                     ELSE <ls_up>-instance-unitprice ).
        <ls_up>-instance-totalprice        = COND #( WHEN <ls_update>-%control-totalprice <> if_abap_behv=>mk-off
                                                     THEN <ls_update>-totalprice
                                                     ELSE <ls_up>-instance-totalprice ).
        <ls_up>-instance-deliverydate      = COND #( WHEN <ls_update>-%control-deliverydate <> if_abap_behv=>mk-off
                                                     THEN <ls_update>-deliverydate
                                                     ELSE <ls_up>-instance-deliverydate ).
        <ls_up>-instance-warehouselocation = COND #( WHEN <ls_update>-%control-warehouselocation <> if_abap_behv=>mk-off
                                                     THEN <ls_update>-warehouselocation
                                                     ELSE <ls_up>-instance-warehouselocation ).
        <ls_up>-instance-itemcurrency      = COND #( WHEN <ls_update>-%control-itemcurrency <> if_abap_behv=>mk-off
                                                     THEN <ls_update>-itemcurrency
                                                     ELSE <ls_up>-instance-itemcurrency ).
        <ls_up>-instance-isurgent          = COND #( WHEN <ls_update>-%control-isurgent <> if_abap_behv=>mk-off
                                                     THEN <ls_update>-isurgent
                                                     ELSE <ls_up>-instance-isurgent ).
        <ls_up>-instance-createdby         = COND #( WHEN <ls_update>-%control-createdby <> if_abap_behv=>mk-off
                                                     THEN <ls_update>-createdby
                                                     ELSE <ls_up>-instance-createdby ).
        <ls_up>-instance-createon          = COND #( WHEN <ls_update>-%control-createon <> if_abap_behv=>mk-off
                                                     THEN <ls_update>-createon
                                                     ELSE <ls_up>-instance-createon ).
        <ls_up>-instance-changedby         = COND #( WHEN <ls_update>-%control-changedby <> if_abap_behv=>mk-off
                                                     THEN <ls_update>-changedby
                                                     ELSE <ls_up>-instance-changedby ).
        <ls_up>-instance-changedon         = COND #( WHEN <ls_update>-%control-changedon <> if_abap_behv=>mk-off
                                                     THEN <ls_update>-changedon
                                                     ELSE <ls_up>-instance-changedon ).

        " QQQ you must update changeOn( last changed on will be taken from value of changed on)
        " in case of update field on item. Otherwise ETAG will not work!!!
        APPEND INITIAL LINE TO lt_root_upd ASSIGNING FIELD-SYMBOL(<ls_root_upd>).
        <ls_root_upd>-purchaseorderid = <ls_update>-purchaseorderid.
        <ls_root_upd>-%is_draft       = <ls_update>-%is_draft.

        <ls_up>-changed = abap_true.
        <ls_up>-deleted = abap_false.

        " to invoke determination on modify with field triggers
        IF    <ls_update>-%control-quantity  = if_abap_behv=>mk-on
           OR <ls_update>-%control-unitprice = if_abap_behv=>mk-on.
          APPEND INITIAL LINE TO lt_calculatetotalprice_d ASSIGNING FIELD-SYMBOL(<ls_calculatetotalprice_d>).
          <ls_calculatetotalprice_d>-purchaseorderid = <ls_update>-purchaseorderid.
          <ls_calculatetotalprice_d>-itemid          = <ls_update>-itemid.
        ENDIF.

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

    SORT lt_root_upd BY purchaseorderid
                        %is_draft.
    DELETE ADJACENT DUPLICATES FROM lt_root_upd COMPARING purchaseorderid %is_draft.

    GET TIME STAMP FIELD DATA(lv_now).
    LOOP AT lt_root_upd ASSIGNING <ls_root_upd>.
      <ls_root_upd>-changedon = lv_now.
      <ls_root_upd>-%control-changedon = if_abap_behv=>mk-on. " qqq update ETAG + total ETAG
    ENDLOOP.

    IF lt_root_upd IS NOT INITIAL.
      MODIFY ENTITIES OF zpru_u_purcorderhdr_tp  " qqq change on your BDEF
             IN LOCAL MODE
             ENTITY ordertp UPDATE FROM lt_root_upd.
    ENDIF.

    " determination on modify for items
    IF lt_calculatetotalprice_d IS NOT INITIAL.
      NEW lcl_det_val_manager( )->calculatetotalprice_in( EXPORTING keys     = lt_calculatetotalprice_d
                                                          CHANGING  reported = ls_reported_late ).
    ENDIF.
  ENDMETHOD.

  METHOD delete.
    DATA lt_root_upd TYPE TABLE FOR UPDATE zpru_u_purcorderhdr_tp. " qqq use your BDEF

    lcl_buffer=>prep_child_buffer( VALUE #( FOR <ls_k>
                                            IN keys
                                            ( purchaseorderid = <ls_k>-purchaseorderid
                                              itemid          = <ls_k>-itemid
                                              is_draft        = <ls_k>-%is_draft
                                              full_key        = abap_true  ) ) ).

    LOOP AT keys ASSIGNING FIELD-SYMBOL(<ls_delete>).
      READ TABLE lcl_buffer=>child_buffer
           WITH KEY instance-purchaseorderid = <ls_delete>-purchaseorderid
                    instance-itemid          = <ls_delete>-itemid
                    is_draft                 = <ls_delete>-%is_draft
                    deleted                  = abap_false ASSIGNING FIELD-SYMBOL(<ls_del>).

      IF sy-subrc = 0.
        " QQQ you must update changeOn( last changed on will be taken from value of changed on)
        " in case of deletion of item. Otherwise ETAG will not work!!!
        APPEND INITIAL LINE TO lt_root_upd ASSIGNING FIELD-SYMBOL(<ls_root_upd>).
        <ls_root_upd>-purchaseorderid = <ls_delete>-purchaseorderid.
        <ls_root_upd>-%is_draft       = <ls_delete>-%is_draft.

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

    SORT lt_root_upd BY purchaseorderid
                        %is_draft.
    DELETE ADJACENT DUPLICATES FROM lt_root_upd COMPARING purchaseorderid %is_draft.

    GET TIME STAMP FIELD DATA(lv_now).
    LOOP AT lt_root_upd ASSIGNING <ls_root_upd>.
      <ls_root_upd>-changedon = lv_now. " qqq update ETAG and total ETAG
      <ls_root_upd>-%control-changedon = if_abap_behv=>mk-on.
    ENDLOOP.

    IF lt_root_upd IS NOT INITIAL.
      MODIFY ENTITIES OF zpru_u_purcorderhdr_tp  " qqq change on your BDEF
             IN LOCAL MODE
             ENTITY ordertp UPDATE FROM lt_root_upd.
    ENDIF.
  ENDMETHOD.

  METHOD read.
    lcl_buffer=>prep_child_buffer( VALUE #( FOR <ls_k>
                                            IN keys
                                            ( purchaseorderid = <ls_k>-purchaseorderid
                                              itemid          = <ls_k>-itemid
                                              is_draft        = <ls_k>-%is_draft
                                              full_key        = abap_true  ) ) ).

    LOOP AT keys ASSIGNING FIELD-SYMBOL(<ls_read>) GROUP BY <ls_read>-%tky.

      READ TABLE lcl_buffer=>child_buffer
           WITH KEY instance-purchaseorderid = <ls_read>-purchaseorderid
                    instance-itemid          = <ls_read>-itemid
                    is_draft                 = <ls_read>-%is_draft
                    deleted                  = abap_false ASSIGNING FIELD-SYMBOL(<ls_rc>).

      IF sy-subrc = 0.
        APPEND VALUE #( %tky              = <ls_read>-%tky
                        itemnumber        = COND #( WHEN <ls_read>-%control-itemnumber <> if_abap_behv=>mk-off
                                                    THEN <ls_rc>-instance-itemnumber )
                        productid         = COND #( WHEN <ls_read>-%control-productid <> if_abap_behv=>mk-off
                                                    THEN <ls_rc>-instance-productid )
                        productname       = COND #( WHEN <ls_read>-%control-productname <> if_abap_behv=>mk-off
                                                    THEN <ls_rc>-instance-productname )
                        quantity          = COND #( WHEN <ls_read>-%control-quantity <> if_abap_behv=>mk-off
                                                    THEN <ls_rc>-instance-quantity )
                        unitprice         = COND #( WHEN <ls_read>-%control-unitprice <> if_abap_behv=>mk-off
                                                    THEN <ls_rc>-instance-unitprice )
                        totalprice        = COND #( WHEN <ls_read>-%control-totalprice <> if_abap_behv=>mk-off
                                                    THEN <ls_rc>-instance-totalprice )
                        deliverydate      = COND #( WHEN <ls_read>-%control-deliverydate <> if_abap_behv=>mk-off
                                                    THEN <ls_rc>-instance-deliverydate )
                        warehouselocation = COND #( WHEN <ls_read>-%control-warehouselocation <> if_abap_behv=>mk-off
                                                    THEN <ls_rc>-instance-warehouselocation )
                        itemcurrency      = COND #( WHEN <ls_read>-%control-itemcurrency <> if_abap_behv=>mk-off
                                                    THEN <ls_rc>-instance-itemcurrency )
                        isurgent          = COND #( WHEN <ls_read>-%control-isurgent <> if_abap_behv=>mk-off
                                                    THEN <ls_rc>-instance-isurgent )
                        createdby         = COND #( WHEN <ls_read>-%control-createdby <> if_abap_behv=>mk-off
                                                    THEN <ls_rc>-instance-createdby )
                        createon          = COND #( WHEN <ls_read>-%control-createon <> if_abap_behv=>mk-off
                                                    THEN <ls_rc>-instance-createon )
                        changedby         = COND #( WHEN <ls_read>-%control-changedby <> if_abap_behv=>mk-off
                                                    THEN <ls_rc>-instance-changedby )
                        changedon         = COND #( WHEN <ls_read>-%control-changedon <> if_abap_behv=>mk-off
                                                    THEN <ls_rc>-instance-changedon ) ) TO result.

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

  METHOD rba_header_tp.
    lcl_buffer=>prep_root_buffer( CORRESPONDING #( keys_rba MAPPING purchaseorderid = purchaseorderid
                                                                    is_draft        = %is_draft ) ).
    lcl_buffer=>prep_child_buffer( CORRESPONDING #( keys_rba MAPPING purchaseorderid = purchaseorderid
                                                                     is_draft        = %is_draft ) ).

    LOOP AT keys_rba ASSIGNING FIELD-SYMBOL(<ls_rba>) GROUP BY <ls_rba>-%tky.
      IF     line_exists( lcl_buffer=>root_buffer[ instance-purchaseorderid = <ls_rba>-purchaseorderid
                                                   is_draft                 = <ls_rba>-%is_draft
                                                   deleted                  = abap_false ] )
         AND line_exists( lcl_buffer=>child_buffer[ instance-purchaseorderid = <ls_rba>-purchaseorderid
                                                    is_draft                 = <ls_rba>-%is_draft
                                                    instance-itemid          = <ls_rba>-itemid
                                                    deleted                  = abap_false ] ).

        INSERT VALUE #( target-%tky = CORRESPONDING #( <ls_rba>-%tky )
                        source-%tky = VALUE #( purchaseorderid = <ls_rba>-purchaseorderid
                                               itemid          = <ls_rba>-itemid
                                               %is_draft       = <ls_rba>-%is_draft ) ) INTO TABLE association_links.

        IF result_requested = abap_true.
          READ TABLE lcl_buffer=>root_buffer
               WITH KEY instance-purchaseorderid = <ls_rba>-purchaseorderid
                        is_draft                 = <ls_rba>-%is_draft ASSIGNING FIELD-SYMBOL(<ls_rp>).
          IF sy-subrc = 0.
            APPEND VALUE #( %tky             = CORRESPONDING #( <ls_rba>-%tky )
                            orderdate        = COND #( WHEN <ls_rba>-%control-orderdate <> if_abap_behv=>mk-off
                                                       THEN <ls_rp>-instance-orderdate )
                            supplierid       = COND #( WHEN <ls_rba>-%control-supplierid <> if_abap_behv=>mk-off
                                                       THEN <ls_rp>-instance-supplierid )
                            suppliername     = COND #( WHEN <ls_rba>-%control-suppliername <> if_abap_behv=>mk-off
                                                       THEN <ls_rp>-instance-suppliername )
                            buyerid          = COND #( WHEN <ls_rba>-%control-buyerid <> if_abap_behv=>mk-off
                                                       THEN <ls_rp>-instance-buyerid )
                            buyername        = COND #( WHEN <ls_rba>-%control-buyername <> if_abap_behv=>mk-off
                                                       THEN <ls_rp>-instance-buyername )
                            totalamount      = COND #( WHEN <ls_rba>-%control-totalamount <> if_abap_behv=>mk-off
                                                       THEN <ls_rp>-instance-totalamount )
                            headercurrency   = COND #( WHEN <ls_rba>-%control-headercurrency <> if_abap_behv=>mk-off
                                                       THEN <ls_rp>-instance-headercurrency )
                            deliverydate     = COND #( WHEN <ls_rba>-%control-deliverydate <> if_abap_behv=>mk-off
                                                       THEN <ls_rp>-instance-deliverydate )
                            status           = COND #( WHEN <ls_rba>-%control-status <> if_abap_behv=>mk-off
                                                       THEN <ls_rp>-instance-status )
                            paymentterms     = COND #( WHEN <ls_rba>-%control-paymentterms <> if_abap_behv=>mk-off
                                                       THEN <ls_rp>-instance-paymentterms )
                            shippingmethod   = COND #( WHEN <ls_rba>-%control-shippingmethod <> if_abap_behv=>mk-off
                                                       THEN <ls_rp>-instance-shippingmethod )
                            controltimestamp = COND #( WHEN <ls_rba>-%control-controltimestamp <> if_abap_behv=>mk-off
                                                       THEN <ls_rp>-instance-controltimestamp )
                            createdby        = COND #( WHEN <ls_rba>-%control-createdby <> if_abap_behv=>mk-off
                                                       THEN <ls_rp>-instance-createdby )
                            createon         = COND #( WHEN <ls_rba>-%control-createon <> if_abap_behv=>mk-off
                                                       THEN <ls_rp>-instance-createon )
                            changedby        = COND #( WHEN <ls_rba>-%control-changedby <> if_abap_behv=>mk-off
                                                       THEN <ls_rp>-instance-changedby )
                            changedon        = COND #( WHEN <ls_rba>-%control-changedon <> if_abap_behv=>mk-off
                                                       THEN <ls_rp>-instance-changedon )
                            lastchanged      = COND #( WHEN <ls_rba>-%control-lastchanged <> if_abap_behv=>mk-off
                                                       THEN <ls_rp>-instance-lastchanged ) ) TO result.
          ENDIF.
        ENDIF.

      ELSE.

        APPEND VALUE #( %tky              = <ls_rba>-%tky
                        %assoc-_header_tp = if_abap_behv=>mk-on
                        %fail-cause       = if_abap_behv=>cause-not_found )
               TO failed-itemtp.

        APPEND VALUE #( %tky = <ls_rba>-%tky
                        %msg = new_message_with_text( severity = if_abap_behv_message=>severity-error
                                                      text     = 'RBA operation (child to parent) failed.' ) )
               TO reported-itemtp.

      ENDIF.
    ENDLOOP.

    " Removing potential duplicate entries.
    SORT association_links BY target ASCENDING.
    DELETE ADJACENT DUPLICATES FROM association_links COMPARING ALL FIELDS.

    SORT result BY %tky ASCENDING.
    DELETE ADJACENT DUPLICATES FROM result COMPARING ALL FIELDS.
  ENDMETHOD.

  METHOD getinventorystatus.
  ENDMETHOD.

  METHOD markasurgent.
  ENDMETHOD.

  METHOD calculatetotalprice.
    NEW lcl_det_val_manager( )->calculatetotalprice_in( EXPORTING keys     = keys
                                                        CHANGING  reported = reported ).
  ENDMETHOD.

  METHOD findwarehouselocation.
    NEW lcl_det_val_manager( )->findwarehouselocation_in( EXPORTING keys     = keys
                                                          CHANGING  reported = reported ).
  ENDMETHOD.

  METHOD writeitemnumber.
    NEW lcl_det_val_manager( )->writeitemnumber_in( EXPORTING keys     = keys
                                                    CHANGING  reported = reported ).
  ENDMETHOD.

  METHOD checkitemcurrency.
    NEW lcl_det_val_manager( )->checkitemcurrency_in( EXPORTING keys     = keys
                                                      CHANGING  failed   = failed
                                                                reported = reported ).
  ENDMETHOD.

  METHOD checkquantity.
    NEW lcl_det_val_manager( )->checkquantity_in( EXPORTING keys     = keys
                                                  CHANGING  failed   = failed
                                                            reported = reported ).
  ENDMETHOD.
ENDCLASS.


CLASS lsc_zpru_u_purcorderhdr_tp DEFINITION INHERITING FROM cl_abap_behavior_saver.
  PROTECTED SECTION.
    METHODS finalize          REDEFINITION.

    METHODS check_before_save REDEFINITION.

    METHODS save              REDEFINITION.

    METHODS cleanup           REDEFINITION.

    METHODS cleanup_finalize  REDEFINITION.

    METHODS calculate_triggers
      EXPORTING et_setcontroltimestamp_d   TYPE lif_business_object=>tt_setcontroltimestamp_d
                et_calctotalamount_d       TYPE lif_business_object=>tt_calctotalamount_d
                et_checkdates_v            TYPE lif_business_object=>tt_checkdates_v
                et_checkheadercurrency_v   TYPE lif_business_object=>tt_checkheadercurrency_v
                et_checksupplier_v         TYPE lif_business_object=>tt_checksupplier_v
                et_checkbuyer_v            TYPE lif_business_object=>tt_checkbuyer_v
                et_findwarehouselocation_d TYPE lif_business_object=>tt_findwarehouselocation_d
                et_writeitemnumber_d       TYPE lif_business_object=>tt_writeitemnumber_d
                et_checkquantity_v         TYPE lif_business_object=>tt_checkquantity_v
                et_checkitemcurrency_v     TYPE lif_business_object=>tt_checkitemcurrency_v.

ENDCLASS.


CLASS lsc_zpru_u_purcorderhdr_tp IMPLEMENTATION.
  METHOD calculate_triggers.
    DATA lt_setcontroltimestamp_d   TYPE lif_business_object=>tt_setcontroltimestamp_d.   " create
    DATA lt_calctotalamount_d       TYPE lif_business_object=>tt_calctotalamount_d.       " create and update
    DATA lt_checkdates_v            TYPE lif_business_object=>tt_checkdates_v.            " create and field orderDate, deliveryDate
    DATA lt_checkheadercurrency_v   TYPE lif_business_object=>tt_checkheadercurrency_v.   " create
    DATA lt_checksupplier_v         TYPE lif_business_object=>tt_checksupplier_v.         " create and update
    DATA lt_checkbuyer_v            TYPE lif_business_object=>tt_checkbuyer_v.            " create and update
    DATA lt_findwarehouselocation_d TYPE lif_business_object=>tt_findwarehouselocation_d. " create and field productId
    DATA lt_writeitemnumber_d       TYPE lif_business_object=>tt_writeitemnumber_d.       " create
    DATA lt_checkquantity_v         TYPE lif_business_object=>tt_checkquantity_v.         " create and update
    DATA lt_checkitemcurrency_v     TYPE lif_business_object=>tt_checkitemcurrency_v.     " create

    DATA lt_active_roots            LIKE lcl_buffer=>root_buffer.
    DATA lt_active_items            LIKE lcl_buffer=>child_buffer.
    DATA lo_root_descr              TYPE REF TO cl_abap_structdescr.
    DATA lo_item_descr              TYPE REF TO cl_abap_structdescr.

    CLEAR : et_setcontroltimestamp_d,
            et_calctotalamount_d,
            et_checkdates_v,
            et_checkheadercurrency_v,
            et_checksupplier_v,
            et_checkbuyer_v,
            et_findwarehouselocation_d,
            et_writeitemnumber_d,
            et_checkquantity_v,
            et_checkitemcurrency_v.

    IF NOT line_exists( lcl_buffer=>root_buffer[ is_draft = if_abap_behv=>mk-off ] ).
      RETURN.
    ENDIF.

    LOOP AT lcl_buffer=>root_buffer ASSIGNING FIELD-SYMBOL(<ls_roots>)
         WHERE is_draft = if_abap_behv=>mk-off.
      APPEND INITIAL LINE TO lt_active_roots ASSIGNING FIELD-SYMBOL(<ls_active_roots>).
      <ls_active_roots>-instance = CORRESPONDING #( <ls_roots>-instance ).
      <ls_active_roots>-deleted = <ls_roots>-deleted.

      LOOP AT lcl_buffer=>child_buffer ASSIGNING FIELD-SYMBOL(<ls_item>)
           WHERE instance-purchaseorderid = <ls_roots>-instance-purchaseorderid.
        APPEND INITIAL LINE TO lt_active_items ASSIGNING FIELD-SYMBOL(<ls_active_items>).
        <ls_active_items>-instance = CORRESPONDING #( <ls_item>-instance ).
        <ls_active_items>-deleted = <ls_item>-deleted.
      ENDLOOP.
    ENDLOOP.

    IF lt_active_roots IS NOT INITIAL.
      SELECT * FROM zpru_purcorderhdr AS order
        FOR ALL ENTRIES IN @lt_active_roots
        WHERE purchaseorderid = @lt_active_roots-instance-purchaseorderid
        INTO TABLE @DATA(lt_order_db_state).
    ENDIF.

    IF lt_active_items IS NOT INITIAL.
      SELECT * FROM zpru_purcorderitem AS item
        FOR ALL ENTRIES IN @lt_active_items
        WHERE purchaseorderid = @lt_active_items-instance-purchaseorderid
          AND itemid          = @lt_active_items-instance-itemid
        INTO TABLE @DATA(lt_item_db_state).
    ENDIF.

    lo_root_descr ?= cl_abap_structdescr=>describe_by_name( 'Zpru_PurcOrderHdr' ).
    DATA(lt_root_fields) = lo_root_descr->get_symbols( ).
    lo_item_descr ?= cl_abap_structdescr=>describe_by_name( 'Zpru_PurcOrderItem' ).
    DATA(lt_item_fields) = lo_item_descr->get_symbols( ).

    LOOP AT lt_active_roots ASSIGNING <ls_active_roots>.

      " CREATE
      IF NOT line_exists( lt_order_db_state[ purchaseorderid = <ls_active_roots>-instance-purchaseorderid ] ) AND
         <ls_active_roots>-deleted = abap_false.
        APPEND INITIAL LINE TO lt_setcontroltimestamp_d ASSIGNING FIELD-SYMBOL(<ls_setcontroltimestamp_d>).
        <ls_setcontroltimestamp_d> = CORRESPONDING #( <ls_active_roots>-instance ).

        APPEND INITIAL LINE TO lt_calctotalamount_d ASSIGNING FIELD-SYMBOL(<ls_calctotalamount_d>).
        <ls_calctotalamount_d> = CORRESPONDING #( <ls_active_roots>-instance ).

        APPEND INITIAL LINE TO lt_checkdates_v ASSIGNING FIELD-SYMBOL(<ls_checkdates_v>).
        <ls_checkdates_v> = CORRESPONDING #( <ls_active_roots>-instance ).

        APPEND INITIAL LINE TO lt_checkheadercurrency_v ASSIGNING FIELD-SYMBOL(<ls_checkheadercurrency_v>).
        <ls_checkheadercurrency_v> = CORRESPONDING #( <ls_active_roots>-instance ).

        APPEND INITIAL LINE TO lt_checksupplier_v ASSIGNING FIELD-SYMBOL(<ls_checksupplier_v>).
        <ls_checksupplier_v> = CORRESPONDING #( <ls_active_roots>-instance ).

        APPEND INITIAL LINE TO lt_checkbuyer_v ASSIGNING FIELD-SYMBOL(<ls_checkbuyer_v>).
        <ls_checkbuyer_v> = CORRESPONDING #( <ls_active_roots>-instance ).
      ENDIF.

      ASSIGN lt_order_db_state[ purchaseorderid = <ls_active_roots>-instance-purchaseorderid ] TO FIELD-SYMBOL(<ls_db_root>).
      IF sy-subrc <> 0.
        CONTINUE.
      ENDIF.

      " calc DELETE trigger before update - not applicable to our bo
      " just skip deleted entries
      IF <ls_active_roots>-deleted = abap_true.
        CONTINUE.
      ENDIF.

      " UPDATE
      LOOP AT lt_root_fields ASSIGNING FIELD-SYMBOL(<lv_root_fields>).

        ASSIGN COMPONENT <lv_root_fields>-name OF STRUCTURE <ls_active_roots>-instance TO FIELD-SYMBOL(<lv_buffer_value>).
        IF sy-subrc <> 0.
          CONTINUE.
        ENDIF.

        ASSIGN COMPONENT <lv_root_fields>-name OF STRUCTURE <ls_db_root> TO FIELD-SYMBOL(<lv_db_value>).
        IF sy-subrc <> 0.
          CONTINUE.
        ENDIF.

        IF <lv_buffer_value> <> <lv_db_value>.
          APPEND INITIAL LINE TO lt_calctotalamount_d ASSIGNING <ls_calctotalamount_d>.
          <ls_calctotalamount_d> = CORRESPONDING #( <ls_active_roots>-instance ).

          APPEND INITIAL LINE TO lt_checksupplier_v ASSIGNING <ls_checksupplier_v>.
          <ls_checksupplier_v> = CORRESPONDING #( <ls_active_roots>-instance ).

          APPEND INITIAL LINE TO lt_checkbuyer_v ASSIGNING <ls_checkbuyer_v>.
          <ls_checkbuyer_v> = CORRESPONDING #( <ls_active_roots>-instance ).

          EXIT.
        ENDIF.
      ENDLOOP.

      " FIELD orderDate
      ASSIGN COMPONENT 'ORDERDATE' OF STRUCTURE <ls_active_roots>-instance TO <lv_buffer_value>.
      IF sy-subrc = 0.
        ASSIGN COMPONENT 'ORDERDATE' OF STRUCTURE <ls_db_root> TO <lv_db_value>.
        IF sy-subrc = 0.
          IF <lv_buffer_value> <> <lv_db_value>.
            APPEND INITIAL LINE TO lt_checkdates_v ASSIGNING <ls_checkdates_v>.
            <ls_checkdates_v> = CORRESPONDING #( <ls_active_roots>-instance ).
          ENDIF.
        ENDIF.
      ENDIF.

      " FIELD deliveryDate
      ASSIGN COMPONENT 'DELIVERYDATE' OF STRUCTURE <ls_active_roots>-instance TO <lv_buffer_value>.
      IF sy-subrc = 0.
        ASSIGN COMPONENT 'DELIVERYDATE' OF STRUCTURE <ls_db_root> TO <lv_db_value>.
        IF sy-subrc = 0.
          IF <lv_buffer_value> <> <lv_db_value>.
            APPEND INITIAL LINE TO lt_checkdates_v ASSIGNING <ls_checkdates_v>.
            <ls_checkdates_v> = CORRESPONDING #( <ls_active_roots>-instance ).
          ENDIF.
        ENDIF.
      ENDIF.
    ENDLOOP.

    LOOP AT lt_active_items ASSIGNING <ls_active_items>.

      " CREATE
      IF NOT line_exists( lt_item_db_state[ purchaseorderid = <ls_active_items>-instance-purchaseorderid
                                            itemid          = <ls_active_items>-instance-itemid ] ) AND
         <ls_active_items>-deleted = abap_false.
        APPEND INITIAL LINE TO lt_findwarehouselocation_d ASSIGNING FIELD-SYMBOL(<ls_findwarehouselocation_d>).
        <ls_findwarehouselocation_d> = CORRESPONDING #( <ls_active_items>-instance ).

        APPEND INITIAL LINE TO lt_writeitemnumber_d ASSIGNING FIELD-SYMBOL(<ls_writeitemnumber_d>).
        <ls_writeitemnumber_d> = CORRESPONDING #( <ls_active_items>-instance ).

        APPEND INITIAL LINE TO lt_checkquantity_v ASSIGNING FIELD-SYMBOL(<ls_checkquantity_v>).
        <ls_checkquantity_v> = CORRESPONDING #( <ls_active_items>-instance ).

        APPEND INITIAL LINE TO lt_checkitemcurrency_v ASSIGNING FIELD-SYMBOL(<ls_checkitemcurrency_v>).
        <ls_checkitemcurrency_v> = CORRESPONDING #( <ls_active_items>-instance ).

      ENDIF.

      ASSIGN lt_item_db_state[ purchaseorderid = <ls_active_items>-instance-purchaseorderid
                               itemid          = <ls_active_items>-instance-itemid ] TO FIELD-SYMBOL(<ls_db_item>).
      IF sy-subrc <> 0.
        CONTINUE.
      ENDIF.

      " calc DELETE trigger before update - not applicable to our bo
      " just skip deleted entries
      IF <ls_active_items>-deleted = abap_true.
        CONTINUE.
      ENDIF.

      " UPDATE
      LOOP AT lt_item_fields ASSIGNING FIELD-SYMBOL(<lv_item_field>).

        ASSIGN COMPONENT <lv_item_field>-name OF STRUCTURE <ls_active_items>-instance TO <lv_buffer_value>.
        IF sy-subrc <> 0.
          CONTINUE.
        ENDIF.

        ASSIGN COMPONENT <lv_item_field>-name OF STRUCTURE <ls_db_item> TO <lv_db_value>.
        IF sy-subrc <> 0.
          CONTINUE.
        ENDIF.

        IF <lv_buffer_value> <> <lv_db_value>.
          APPEND INITIAL LINE TO lt_checkquantity_v ASSIGNING <ls_checkquantity_v>.
          <ls_checkquantity_v> = CORRESPONDING #( <ls_active_items>-instance ).

          EXIT.
        ENDIF.
      ENDLOOP.

      " FIELD PRODUCTID
      ASSIGN COMPONENT 'PRODUCTID' OF STRUCTURE <ls_active_items>-instance TO <lv_buffer_value>.
      IF sy-subrc = 0.
        ASSIGN COMPONENT 'PRODUCTID' OF STRUCTURE <ls_db_item> TO <lv_db_value>.
        IF sy-subrc = 0.
          IF <lv_buffer_value> <> <lv_db_value>.
            APPEND INITIAL LINE TO lt_findwarehouselocation_d ASSIGNING <ls_findwarehouselocation_d>.
            <ls_findwarehouselocation_d> = CORRESPONDING #( <ls_active_items>-instance ).
          ENDIF.
        ENDIF.
      ENDIF.
    ENDLOOP.

    SORT lt_setcontroltimestamp_d BY table_line.
    DELETE ADJACENT DUPLICATES FROM lt_setcontroltimestamp_d COMPARING table_line.

    SORT lt_calctotalamount_d BY table_line.
    DELETE ADJACENT DUPLICATES FROM lt_calctotalamount_d COMPARING table_line.

    SORT lt_checkdates_v BY table_line.
    DELETE ADJACENT DUPLICATES FROM lt_checkdates_v COMPARING table_line.

    SORT lt_checkheadercurrency_v BY table_line.
    DELETE ADJACENT DUPLICATES FROM lt_checkheadercurrency_v COMPARING table_line.

    SORT lt_checksupplier_v BY table_line.
    DELETE ADJACENT DUPLICATES FROM lt_checksupplier_v COMPARING table_line.

    SORT lt_checkbuyer_v BY table_line.
    DELETE ADJACENT DUPLICATES FROM lt_checkbuyer_v COMPARING table_line.

    SORT lt_findwarehouselocation_d BY table_line.
    DELETE ADJACENT DUPLICATES FROM lt_findwarehouselocation_d COMPARING table_line.

    SORT lt_writeitemnumber_d BY table_line.
    DELETE ADJACENT DUPLICATES FROM lt_writeitemnumber_d COMPARING table_line.

    SORT lt_checkquantity_v BY table_line.
    DELETE ADJACENT DUPLICATES FROM lt_checkquantity_v COMPARING table_line.

    SORT lt_checkitemcurrency_v BY table_line.
    DELETE ADJACENT DUPLICATES FROM lt_checkitemcurrency_v COMPARING table_line.

    et_setcontroltimestamp_d   = lt_setcontroltimestamp_d.
    et_calctotalamount_d       = lt_calctotalamount_d.
    et_checkdates_v            = lt_checkdates_v.
    et_checkheadercurrency_v   = lt_checkheadercurrency_v.
    et_checksupplier_v         = lt_checksupplier_v.
    et_checkbuyer_v            = lt_checkbuyer_v.
    et_findwarehouselocation_d = lt_findwarehouselocation_d.
    et_writeitemnumber_d       = lt_writeitemnumber_d.
    et_checkquantity_v         = lt_checkquantity_v.
    et_checkitemcurrency_v     = lt_checkitemcurrency_v.
  ENDMETHOD.

  METHOD finalize.
    IF NOT line_exists( lcl_buffer=>root_buffer[ is_draft = if_abap_behv=>mk-off ] ).
      RETURN.
    ENDIF.

    calculate_triggers( IMPORTING et_setcontroltimestamp_d   = DATA(lt_setcontroltimestamp_d)
                                  et_calctotalamount_d       = DATA(lt_calctotalamount_d)
                                  et_findwarehouselocation_d = DATA(lt_findwarehouselocation_d)
                                  et_writeitemnumber_d       = DATA(lt_writeitemnumber_d) ).

    DATA(lo_det_val_manager) = NEW lcl_det_val_manager( ).

    IF lt_setcontroltimestamp_d IS NOT INITIAL.
      lo_det_val_manager->setcontroltimestamp_in( EXPORTING keys     = lt_setcontroltimestamp_d
                                                  CHANGING  reported = reported ).
    ENDIF.

    IF lt_calctotalamount_d IS NOT INITIAL.
      lo_det_val_manager->calctotalamount_in( EXPORTING keys     = lt_calctotalamount_d
                                              CHANGING  reported = reported ).
    ENDIF.

    IF lt_findwarehouselocation_d IS NOT INITIAL.
      lo_det_val_manager->findwarehouselocation_in( EXPORTING keys     = lt_findwarehouselocation_d
                                                    CHANGING  reported = reported ).
    ENDIF.

    IF lt_writeitemnumber_d IS NOT INITIAL.
      lo_det_val_manager->writeitemnumber_in( EXPORTING keys     = lt_writeitemnumber_d
                                              CHANGING  reported = reported ).
    ENDIF.
  ENDMETHOD.

  METHOD check_before_save.
    IF NOT line_exists( lcl_buffer=>root_buffer[ is_draft = if_abap_behv=>mk-off ] ).
      RETURN.
    ENDIF.

    calculate_triggers( IMPORTING et_checkdates_v          = DATA(lt_checkdates_v)
                                  et_checkheadercurrency_v = DATA(lt_checkheadercurrency_v)
                                  et_checksupplier_v       = DATA(lt_checksupplier_v)
                                  et_checkbuyer_v          = DATA(lt_checkbuyer_v)
                                  et_checkquantity_v       = DATA(lt_checkquantity_v)
                                  et_checkitemcurrency_v   = DATA(lt_checkitemcurrency_v) ).

    DATA(lo_det_val_manager) = NEW lcl_det_val_manager( ).

    IF lt_checkdates_v IS NOT INITIAL.
      lo_det_val_manager->checkdates_in( EXPORTING keys     = lt_checkdates_v
                                         CHANGING  failed   = failed
                                                   reported = reported ).
    ENDIF.

    IF lt_checkheadercurrency_v IS NOT INITIAL.
      lo_det_val_manager->checkheadercurrency_in( EXPORTING keys     = lt_checkheadercurrency_v
                                                  CHANGING  failed   = failed
                                                            reported = reported ).
    ENDIF.

    IF lt_checksupplier_v IS NOT INITIAL.
      lo_det_val_manager->checksupplier_in( EXPORTING keys     = lt_checksupplier_v
                                            CHANGING  failed   = failed
                                                      reported = reported ).
    ENDIF.

    IF lt_checkbuyer_v IS NOT INITIAL.
      lo_det_val_manager->checkbuyer_in( EXPORTING keys     = lt_checkbuyer_v
                                         CHANGING  failed   = failed
                                                   reported = reported ).
    ENDIF.

    IF lt_checkquantity_v IS NOT INITIAL.
      lo_det_val_manager->checkquantity_in( EXPORTING keys     = lt_checkquantity_v
                                            CHANGING  failed   = failed
                                                      reported = reported ).
    ENDIF.

    IF lt_checkitemcurrency_v IS NOT INITIAL.
      lo_det_val_manager->checkitemcurrency_in( EXPORTING keys     = lt_checkitemcurrency_v
                                                CHANGING  failed   = failed
                                                          reported = reported ).

    ENDIF.
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
        APPEND VALUE #( purchase_order_id = <ls_del>-instance-purchaseorderid ) TO lt_del_tab.
      ENDLOOP.
      DELETE zpru_purc_order FROM TABLE @( CORRESPONDING #( lt_del_tab ) ). " qqq use on your  database tables

      """""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""
      " qqq logic below relates to issue with different node set for managed implementation ZPRU_PURCORDERHDR_TP
      " unmanaged implementation ZPRU_U_PURCORDERHDR_TP. As far asa you know managed BO has additionally
      " TEXT node for order and also TAG  as extension node. Since both BO work with the same tables.
      " We can create BO via managed implementation, text and tag nodes become create either. Then we can
      " delete instance via unamanged BO, as a result orphan nodes for text and tag remain.
      " solution is to provide additional deletion in cascade style

      IF lt_del_tab IS NOT INITIAL.
        " cascade deletion for TEXT node
        SELECT purchase_order_id, language
          FROM zpru_purc_ordert AS text
          FOR ALL ENTRIES IN @lt_del_tab
          WHERE text~purchase_order_id = @lt_del_tab-purchase_order_id
          INTO TABLE @DATA(lt_text_2_del).

        IF lt_text_2_del IS NOT INITIAL.
          DELETE zpru_purc_ordert FROM TABLE @( CORRESPONDING #( lt_text_2_del ) ).
        ENDIF.

        " cascade deletion for TAG node
        SELECT purchase_order_id, tag_id
          FROM zpru_order_tag AS tag
          FOR ALL ENTRIES IN @lt_del_tab
          WHERE tag~purchase_order_id = @lt_del_tab-purchase_order_id
          INTO TABLE @DATA(lt_tag_2_del).

        IF lt_tag_2_del IS NOT INITIAL.
          DELETE zpru_order_tag FROM TABLE @( CORRESPONDING #( lt_tag_2_del ) ).
        ENDIF.
      ENDIF.
      """""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""

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
        APPEND VALUE #( purchase_order_id = <ls_del_child>-instance-purchaseorderid
                        item_id           = <ls_del_child>-instance-itemid  ) TO lt_del_child_tab.
      ENDLOOP.
      DELETE zpru_po_item FROM TABLE @( CORRESPONDING #( lt_del_child_tab ) ). " qqq use on your  database tables
    ENDIF.

    " qqq logic below is relevant for raising event
    LOOP AT lcl_buffer=>root_buffer ASSIGNING FIELD-SYMBOL(<ls_order>)
         WHERE newly_created = abap_true.

      "   After save raise corresponding event
      APPEND INITIAL LINE TO lt_payload ASSIGNING FIELD-SYMBOL(<ls_po_payload>).
      <ls_po_payload>-%key-purchaseorderid    = <ls_order>-instance-purchaseorderid.
      <ls_po_payload>-%param-purchaseorderid2 = <ls_order>-instance-purchaseorderid.
      <ls_po_payload>-%param-orderdate2       = <ls_order>-instance-orderdate.
      <ls_po_payload>-%param-supplierid2      = <ls_order>-instance-supplierid.
      <ls_po_payload>-%param-suppliername2    = <ls_order>-instance-suppliername.
      <ls_po_payload>-%param-buyerid2         = <ls_order>-instance-buyerid.
      <ls_po_payload>-%param-buyername2       = <ls_order>-instance-buyername.
      <ls_po_payload>-%param-totalamount2     = <ls_order>-instance-totalamount.
      <ls_po_payload>-%param-headercurrency2  = <ls_order>-instance-headercurrency.
      <ls_po_payload>-%param-deliverydate2    = <ls_order>-instance-deliverydate.
      <ls_po_payload>-%param-status2          = <ls_order>-instance-status.
      <ls_po_payload>-%param-paymentterms2    = <ls_order>-instance-paymentterms.
      <ls_po_payload>-%param-shippingmethod2  = <ls_order>-instance-shippingmethod.

      <ls_po_payload>-%control-purchaseorderid2 = if_abap_behv=>mk-on.
      <ls_po_payload>-%control-orderdate2       = if_abap_behv=>mk-on.
      <ls_po_payload>-%control-supplierid2      = if_abap_behv=>mk-on.
      <ls_po_payload>-%control-suppliername2    = if_abap_behv=>mk-on.
      <ls_po_payload>-%control-buyerid2         = if_abap_behv=>mk-on.
      <ls_po_payload>-%control-buyername2       = if_abap_behv=>mk-on.
      <ls_po_payload>-%control-totalamount2     = if_abap_behv=>mk-on.
      <ls_po_payload>-%control-headercurrency2  = if_abap_behv=>mk-on.
      <ls_po_payload>-%control-deliverydate2    = if_abap_behv=>mk-on.
      <ls_po_payload>-%control-status2          = if_abap_behv=>mk-on.
      <ls_po_payload>-%control-paymentterms2    = if_abap_behv=>mk-on.
      <ls_po_payload>-%control-shippingmethod2  = if_abap_behv=>mk-on.
      <ls_po_payload>-%control-_cross_bo        = if_abap_behv=>mk-on.
      <ls_po_payload>-%control-_items_abs       = if_abap_behv=>mk-on.

      LOOP AT lcl_buffer=>child_buffer ASSIGNING FIELD-SYMBOL(<ls_item>)
           WHERE instance-purchaseorderid = <ls_order>-instance-purchaseorderid.
        APPEND INITIAL LINE TO <ls_po_payload>-%param-_items_abs ASSIGNING FIELD-SYMBOL(<ls_item_payload>).
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

    RAISE ENTITY EVENT zpru_u_purcorderhdr_tp~ordercreated " qqq use your BDEF
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
