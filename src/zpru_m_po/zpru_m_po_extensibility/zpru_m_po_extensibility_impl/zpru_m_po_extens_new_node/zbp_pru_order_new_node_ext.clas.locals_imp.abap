INTERFACE lif_business_object.

  CONSTANTS gc_po_message_class TYPE symsgid VALUE `ZPRU_PO_EXT`.

  CONSTANTS: BEGIN OF cs_state_area,
               BEGIN OF tag,
                 checkTag TYPE string VALUE `checkTag`,
               END OF tag,
             END OF cs_state_area.

  TYPES ts_cleartag_in TYPE STRUCTURE FOR ACTION IMPORT zpru_tag_to_parent_tp~clearAllTags.
  TYPES tt_cleartag_in TYPE TABLE FOR ACTION IMPORT zpru_tag_to_parent_tp~clearAllTags.
  TYPES ts_UPD_tag_in  TYPE STRUCTURE FOR UPDATE zpru_tag_to_parent_int.
  TYPES tt_UPD_tag_in  TYPE TABLE FOR UPDATE zpru_tag_to_parent_int.

ENDINTERFACE.


CLASS lhc_tag DEFINITION INHERITING FROM cl_abap_behavior_handler.

  PRIVATE SECTION.
    METHODS get_instance_features FOR INSTANCE FEATURES
      IMPORTING keys REQUEST requested_features FOR Tag RESULT result.

    METHODS get_global_authorizations FOR GLOBAL AUTHORIZATION
      IMPORTING REQUEST requested_authorizations FOR Tag RESULT result.

    METHODS getTagCount FOR READ
      IMPORTING keys FOR FUNCTION Tag~getTagCount RESULT result.

    METHODS clearAllTags FOR MODIFY
      IMPORTING keys FOR ACTION Tag~clearAllTags.

    METHODS generateDefaultTag FOR DETERMINE ON SAVE
      IMPORTING keys FOR Tag~generateDefaultTag.

    METHODS checkTag FOR VALIDATE ON SAVE
      IMPORTING keys FOR Tag~checkTag.

ENDCLASS.


CLASS lhc_tag IMPLEMENTATION.
  METHOD get_instance_features.
  ENDMETHOD.

  METHOD get_global_authorizations.
  ENDMETHOD.

  METHOD getTagCount.
    DATA(lv_value) = 10.
    LOOP AT keys ASSIGNING FIELD-SYMBOL(<ls_key>).

      lv_value = lv_value + 7.
      APPEND INITIAL LINE TO result ASSIGNING FIELD-SYMBOL(<ls_result>).
      <ls_result>-%cid = <ls_key>-%cid.
      <ls_result>-%param-tagCount = lv_value.
    ENDLOOP.
  ENDMETHOD.

  METHOD clearAllTags.
    DATA lt_tag_update TYPE lif_business_object=>tT_UPD_tag_in.

    IF keys IS INITIAL.
      APPEND INITIAL LINE TO reported-%other ASSIGNING FIELD-SYMBOL(<lo_reported>).
      <lo_reported> = new_message( id       = zpru_if_m_po=>gc_po_message_class
                                   number   = '001'
                                   severity = if_abap_behv_message=>severity-error ).
      RETURN.
    ENDIF.

    READ ENTITIES OF Zpru_PurcOrderHdr_ODATA_Int
         IN LOCAL MODE
         ENTITY Tag
         ALL FIELDS
         WITH CORRESPONDING #( keys )
         RESULT DATA(lt_tags).

    IF lt_tags IS INITIAL.
      APPEND INITIAL LINE TO reported-%other ASSIGNING <lo_reported>.
      <lo_reported> = new_message( id       = zpru_if_m_po=>gc_po_message_class
                                   number   = '002'
                                   severity = if_abap_behv_message=>severity-error ).
      RETURN.
    ENDIF.

    LOOP AT keys ASSIGNING FIELD-SYMBOL(<ls_key>).

      ASSIGN lt_tags[ KEY id COMPONENTS %tky = <ls_key>-%tky ] TO FIELD-SYMBOL(<ls_instance>).
      IF sy-subrc <> 0.
        APPEND INITIAL LINE TO failed-tag ASSIGNING FIELD-SYMBOL(<ls_failed>).
        <ls_failed>-%tky = <ls_instance>-%tky.
        <ls_failed>-%fail-cause = if_abap_behv=>cause-not_found.
        <ls_failed>-%action-clearAllTags = if_abap_behv=>mk-on.
        CONTINUE.
      ENDIF.

      APPEND INITIAL LINE TO lt_tag_update ASSIGNING FIELD-SYMBOL(<ls_tag_update>).
      <ls_tag_update>-%tky = <ls_instance>-%tky.
      <ls_tag_update>-%data-tagtext = '###INVALID'.
      <ls_tag_update>-%control-tagtext = if_abap_behv=>mk-on.

    ENDLOOP.

    IF lt_TAG_update IS NOT INITIAL.
      MODIFY ENTITIES OF Zpru_PurcOrderHdr_ODATA_Int
             IN LOCAL MODE
             ENTITY Tag
             UPDATE FROM lt_TAG_update.
    ENDIF.
  ENDMETHOD.

  METHOD generateDefaultTag.
  ENDMETHOD.

  METHOD checkTag.
    IF keys IS INITIAL.
      APPEND INITIAL LINE TO reported-%other ASSIGNING FIELD-SYMBOL(<lo_reported>).
      <lo_reported> = new_message( id       = zpru_if_m_po=>gc_po_message_class
                                   number   = '001'
                                   severity = if_abap_behv_message=>severity-error ).
      RETURN.
    ENDIF.

    READ ENTITIES OF Zpru_PurcOrderHdr_ODATA_Int
         IN LOCAL MODE
         ENTITY Tag
         FIELDS ( TagText )
         WITH CORRESPONDING #( keys )
         RESULT DATA(lt_tags).

    IF lt_tags IS INITIAL.
      APPEND INITIAL LINE TO reported-%other ASSIGNING <lo_reported>.
      <lo_reported> = new_message( id       = zpru_if_m_po=>gc_po_message_class
                                   number   = '002'
                                   severity = if_abap_behv_message=>severity-error ).
      RETURN.
    ENDIF.

    LOOP AT keys ASSIGNING FIELD-SYMBOL(<ls_key>).

      ASSIGN lt_tags[ KEY id COMPONENTS %tky = <ls_key>-%tky ] TO FIELD-SYMBOL(<ls_instance>).
      IF sy-subrc <> 0.
        APPEND INITIAL LINE TO failed-tag ASSIGNING FIELD-SYMBOL(<ls_failed>).
        <ls_failed>-%tky = <ls_instance>-%tky.
        <ls_failed>-%fail-cause = if_abap_behv=>cause-not_found.
        CONTINUE.
      ENDIF.

      APPEND INITIAL LINE TO reported-tag ASSIGNING FIELD-SYMBOL(<ls_tag_reported>).
      <ls_tag_reported>-%tky        = <ls_instance>-%tky.
      <ls_tag_reported>-%state_area = lif_business_object=>cs_state_area-tag-checktag.

      IF <ls_instance>-TagText IS INITIAL.
        APPEND INITIAL LINE TO failed-tag ASSIGNING <ls_failed>.
        <ls_failed>-%tky = <ls_instance>-%tky.

        APPEND INITIAL LINE TO reported-tag ASSIGNING <ls_tag_reported>.
        <ls_tag_reported>-%tky        = <ls_instance>-%tky.
        <ls_tag_reported>-%state_area = lif_business_object=>cs_state_area-tag-checktag.
        <ls_tag_reported>-%msg        = new_message( id       = lif_business_object=>gc_po_message_class
                                                     number   = '001'
                                                     severity = if_abap_behv_message=>severity-error ).
      ENDIF.
    ENDLOOP.
  ENDMETHOD.
ENDCLASS.


CLASS lsc_ZPRU_PURCORDERHDR_TP DEFINITION INHERITING FROM cl_abap_behavior_saver.
  PROTECTED SECTION.
    METHODS adjust_numbers   REDEFINITION.

    METHODS cleanup_finalize REDEFINITION.

ENDCLASS.


CLASS lsc_ZPRU_PURCORDERHDR_TP IMPLEMENTATION.
  METHOD adjust_numbers.
    DATA lv_count_char TYPE zpru_de_po_tag_id.

    IF mapped IS INITIAL.
      RETURN.
    ENDIF.

    IF mapped-tag IS INITIAL.
      RETURN.
    ENDIF.

    READ ENTITIES OF Zpru_PurcOrderHdr_ODATA_Int
         IN LOCAL MODE
         ENTITY Tag BY \_header_tp
         ALL FIELDS WITH VALUE #( FOR <ls_i>
                                  IN mapped-tag
                                  ( %tky-%pid            = <ls_i>-%pre-%pid
                                    %tky-purchaseOrderId = <ls_i>-%pre-%tmp-purchaseOrderId
                                    %tky-TagId           = <ls_i>-%pre-%tmp-TagId ) )
         LINK DATA(lt_link_tag_to_order).

    READ ENTITIES OF Zpru_PurcOrderHdr_ODATA_Int
         IN LOCAL MODE
         ENTITY OrderInt BY \_tag
         ALL FIELDS WITH VALUE #( FOR <ls_o> IN lt_link_tag_to_order
                                  ( %tky = <ls_o>-target-%tky  ) )
         LINK DATA(lt_all_tags).

    LOOP AT lt_link_tag_to_order ASSIGNING FIELD-SYMBOL(<ls_group>)
         GROUP BY ( pid             = <ls_group>-target-%pid
                    purchaseorderid = <ls_group>-target-purchaseOrderId
                    is_draft        = <ls_group>-target-%is_draft ) ASSIGNING FIELD-SYMBOL(<ls_group_key>).

      DATA(lt_tags_all_copy) = lt_all_tags.

      DELETE lt_tags_all_copy WHERE     source-%is_draft       <> <ls_group_key>-is_draft
                                    AND source-%pid            <> <ls_group_key>-pid
                                    AND source-purchaseorderid <> <ls_group_key>-purchaseorderid.

      LOOP AT GROUP <ls_group_key> ASSIGNING FIELD-SYMBOL(<ls_tag_member>).
        DELETE lt_tags_all_copy WHERE target = <ls_tag_member>-source.
      ENDLOOP.

      SORT lt_tags_all_copy BY target-tagid DESCENDING.
      DATA(lv_count) = COND i( WHEN lines( lt_tags_all_copy ) > 0
                               THEN VALUE #( lt_tags_all_copy[ 1 ]-target-tagid OPTIONAL )
                               ELSE 0 ).

      LOOP AT GROUP <ls_group_key> ASSIGNING <ls_tag_member>.

        ASSIGN mapped-tag[ %pid                 = <ls_tag_member>-source-%pid
                           %tmp-tagid           = <ls_tag_member>-source-tagId
                           %tmp-purchaseOrderId = <ls_tag_member>-source-purchaseOrderId ] TO FIELD-SYMBOL(<ls_tag_target>).
        IF sy-subrc <> 0.
          CONTINUE.
        ENDIF.

        lv_count = lv_count + 1.
        lv_count_char = lv_count.

        ASSIGN mapped-orderint[ %pid                 = <ls_group_key>-pid
                                %tmp-purchaseOrderId = <ls_group_key>-purchaseorderid ] TO FIELD-SYMBOL(<ls_order_in_one_session>).
        IF sy-subrc = 0.
          <ls_tag_target>-%key-purchaseOrderId = <ls_order_in_one_session>-%key-purchaseOrderId.
        ELSE.
          <ls_tag_target>-%key-purchaseOrderId = <ls_group_key>-purchaseorderid.
        ENDIF.
        <ls_tag_target>-%key-TagId = |{ lv_count_char ALPHA = IN }|.
      ENDLOOP.

    ENDLOOP.
  ENDMETHOD.

  METHOD cleanup_finalize.
  ENDMETHOD.
ENDCLASS.
