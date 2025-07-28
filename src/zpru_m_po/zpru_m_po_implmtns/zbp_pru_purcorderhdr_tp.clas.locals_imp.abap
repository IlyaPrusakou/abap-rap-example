INTERFACE lif_business_object.
  TYPES ts_po_auth_request             TYPE STRUCTURE FOR GLOBAL AUTHORIZATION REQUEST zpru_purcorderhdr_tp\\ordertp.
  TYPES ts_po_auth_result              TYPE STRUCTURE FOR GLOBAL AUTHORIZATION RESULT zpru_purcorderhdr_tp\\ordertp.
  TYPES ts_early_reported              TYPE RESPONSE FOR REPORTED EARLY zpru_purcorderhdr_tp.
  TYPES tt_po_key                      TYPE TABLE FOR KEY OF zpru_purcorderhdr_tp\\ordertp.
  TYPES ts_early_failed                TYPE RESPONSE FOR FAILED EARLY zpru_purcorderhdr_tp.
  TYPES tt_imp_getapprovedsupplierlist TYPE TABLE FOR FUNCTION IMPORT zpru_purcorderhdr_tp\\ordertp~getMajorSupplier.
  TYPES tt_res_getapprovedsupplierlist TYPE TABLE FOR FUNCTION RESULT zpru_purcorderhdr_tp\\ordertp~getMajorSupplier.
  TYPES tt_imp_getstatushistory        TYPE TABLE FOR FUNCTION IMPORT zpru_purcorderhdr_tp\\ordertp~getstatushistory.
  TYPES tt_res_getstatushistory        TYPE TABLE FOR FUNCTION RESULT zpru_purcorderhdr_tp\\ordertp~getstatushistory.
  TYPES tt_imp_issupplierblacklisted   TYPE TABLE FOR FUNCTION IMPORT zpru_purcorderhdr_tp\\ordertp~issupplierblacklisted.
  TYPES tt_res_issupplierblacklisted   TYPE TABLE FOR FUNCTION RESULT zpru_purcorderhdr_tp\\ordertp~issupplierblacklisted.
  TYPES tt_imp_activate                TYPE TABLE FOR ACTION IMPORT zpru_purcorderhdr_tp\\ordertp~activate.
  TYPES ts_early_mapped                TYPE RESPONSE FOR MAPPED EARLY zpru_purcorderhdr_tp.
  TYPES tt_imp_changestatus            TYPE TABLE FOR ACTION IMPORT zpru_purcorderhdr_tp\\ordertp~changestatus.
  TYPES tt_imp_createfromtemplate      TYPE TABLE FOR ACTION IMPORT zpru_purcorderhdr_tp\\ordertp~createfromtemplate.
  TYPES tt_imp_discard                 TYPE TABLE FOR ACTION IMPORT zpru_purcorderhdr_tp\\ordertp~discard.
  TYPES tt_imp_edit                    TYPE TABLE FOR ACTION IMPORT zpru_purcorderhdr_tp\\ordertp~edit.
  TYPES tt_imp_resume                  TYPE TABLE FOR ACTION IMPORT zpru_purcorderhdr_tp\\ordertp~resume.
  TYPES tt_imp_revalidatepricingrules  TYPE TABLE FOR ACTION IMPORT zpru_purcorderhdr_tp\\ordertp~revalidatepricingrules.
  TYPES tt_res_revalidatepricingrules  TYPE TABLE FOR ACTION RESULT zpru_purcorderhdr_tp\\ordertp~revalidatepricingrules.
  TYPES tt_imp_sendorderstatisttoazure TYPE TABLE FOR ACTION IMPORT zpru_purcorderhdr_tp\\ordertp~sendorderstatistictoazure.
  TYPES tt_recalculateshippingmethod   TYPE TABLE FOR DETERMINATION zpru_purcorderhdr_tp\\ordertp~recalculateshippingmethod.
  TYPES tt_setcontroltimestamp         TYPE TABLE FOR DETERMINATION zpru_purcorderhdr_tp\\ordertp~setcontroltimestamp.
  TYPES tt_checkdates                  TYPE TABLE FOR VALIDATION zpru_purcorderhdr_tp\\ordertp~checkdates.
  TYPES tt_prch_ordertp                TYPE TABLE FOR CREATE zpru_purcorderhdr_tp\\ordertp.
  TYPES tt_order_update                TYPE TABLE FOR UPDATE Zpru_PurcOrderHdr_tp\\OrderTP.

  CONSTANTS: BEGIN OF cs_state_area,
               BEGIN OF order,
                 checkDates TYPE string VALUE `checkdates`,
               END OF order,
               BEGIN OF item,
                 checkQuantity TYPE string VALUE `checkquantity`,
               END OF item,
             END OF cs_state_area.

ENDINTERFACE.


CLASS lhc_OrderTP DEFINITION INHERITING FROM cl_abap_behavior_handler.
  PRIVATE SECTION.
    METHODS get_instance_authorizations FOR INSTANCE AUTHORIZATION
      IMPORTING keys REQUEST requested_authorizations FOR OrderTP RESULT result.

    METHODS lock FOR LOCK
      IMPORTING keys FOR LOCK OrderTP.

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

    METHODS recalculateShippingMethod FOR DETERMINE ON MODIFY
      IMPORTING keys FOR OrderTP~recalculateShippingMethod.

    METHODS setControlTimestamp FOR DETERMINE ON SAVE
      IMPORTING keys FOR OrderTP~setControlTimestamp.

    METHODS checkDates FOR VALIDATE ON SAVE
      IMPORTING keys FOR OrderTP~checkDates.

    METHODS get_global_authorizations FOR GLOBAL AUTHORIZATION
      IMPORTING REQUEST requested_authorizations FOR OrderTP RESULT result.
    METHODS precheck_create FOR PRECHECK
      IMPORTING entities FOR CREATE OrderTP.

    METHODS precheck_update FOR PRECHECK
      IMPORTING entities FOR UPDATE OrderTP.

    METHODS precheck_delete FOR PRECHECK
      IMPORTING keys FOR DELETE OrderTP.
    METHODS get_instance_features FOR INSTANCE FEATURES
      IMPORTING keys REQUEST requested_features FOR OrderTP RESULT result.

ENDCLASS.


CLASS lhc_OrderTP IMPLEMENTATION.
  METHOD get_instance_authorizations.
    IF keys IS INITIAL.
      APPEND INITIAL LINE TO reported-%other ASSIGNING FIELD-SYMBOL(<lo_reported>).
      <lo_reported> = new_message( id       = zpru_if_m_po=>gc_po_message_class
                                   number   = '001'
                                   severity = if_abap_behv_message=>severity-error ).
      RETURN.
    ENDIF.

    READ ENTITIES OF zpru_purcorderhdr_tp
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

      IF <ls_instance>-status = zpru_if_m_po=>cs_status-archived.
        APPEND INITIAL LINE TO result ASSIGNING FIELD-SYMBOL(<ls_result>).
        <ls_result>-%is_draft       = <ls_result>-%is_draft.
        <ls_result>-%pid            = <ls_result>-%pid.
        <ls_result>-purchaseorderid = <ls_result>-purchaseOrderId.
        <ls_result>-%update         = if_abap_behv=>auth-unauthorized.
        <ls_result>-%delete         = if_abap_behv=>auth-unauthorized.
        <ls_result>-%action-edit               = if_abap_behv=>auth-unauthorized.
        <ls_result>-%action-checkorder         = if_abap_behv=>auth-unauthorized.
        <ls_result>-%action-changestatus       = if_abap_behv=>auth-unauthorized.
        <ls_result>-%action-createfromtemplate = if_abap_behv=>auth-unauthorized.

        APPEND INITIAL LINE TO failed-ordertp ASSIGNING <ls_failed>.
        <ls_failed>-%tky = <ls_instance>-%tky.
        <ls_failed>-%fail-cause = if_abap_behv=>cause-unauthorized.

        APPEND INITIAL LINE TO reported-ordertp ASSIGNING FIELD-SYMBOL(<lo_order>).
        <lo_order>-%tky = <ls_instance>-%tky.
        <lo_order>-%msg = new_message( id       = zpru_if_m_po=>gc_po_message_class
                                       number   = '004'
                                       severity = if_abap_behv_message=>severity-error
                                       v1       = <ls_instance>-purchaseOrderId ).
      ELSE.
        APPEND INITIAL LINE TO result ASSIGNING <ls_result>.
        <ls_result>-%is_draft       = <ls_result>-%is_draft.
        <ls_result>-%pid            = <ls_result>-%pid.
        <ls_result>-purchaseorderid = <ls_result>-purchaseOrderId.
        <ls_result>-%update         = if_abap_behv=>auth-allowed.
        <ls_result>-%delete         = if_abap_behv=>auth-allowed.
        <ls_result>-%action-edit               = if_abap_behv=>auth-allowed.
        <ls_result>-%action-checkorder         = if_abap_behv=>auth-allowed.
        <ls_result>-%action-changestatus       = if_abap_behv=>auth-allowed.
        <ls_result>-%action-createfromtemplate = if_abap_behv=>auth-allowed.
      ENDIF.
    ENDLOOP.
  ENDMETHOD.

  METHOD lock.
    IF keys IS INITIAL.
      APPEND INITIAL LINE TO reported-%other ASSIGNING FIELD-SYMBOL(<lo_reported>).
      <lo_reported> = new_message( id       = zpru_if_m_po=>gc_po_message_class
                                   number   = '001'
                                   severity = if_abap_behv_message=>severity-error ).
      RETURN.
    ENDIF.

    READ ENTITIES OF zpru_purcorderhdr_tp
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

    LOOP AT keys ASSIGNING FIELD-SYMBOL(<ls_key>).

      ASSIGN lt_roots[ KEY entity COMPONENTS purchaseOrderId = <ls_key>-purchaseOrderId ] TO FIELD-SYMBOL(<ls_instance>).
      IF sy-subrc <> 0.
        APPEND INITIAL LINE TO failed-ordertp ASSIGNING FIELD-SYMBOL(<ls_failed>).
        <ls_failed>-purchaseOrderId = <ls_instance>-purchaseOrderId.
        <ls_failed>-%fail-cause = if_abap_behv=>cause-not_found.
        CONTINUE.
      ENDIF.

      CALL FUNCTION 'ENQUEUE_EZPRU_PURC_ORDER'
        EXPORTING
          order_id = <ls_key>-purchaseOrderId
        EXCEPTIONS
          OTHERS   = 3.
      IF sy-subrc <> 0.
        APPEND INITIAL LINE TO failed-ordertp ASSIGNING FIELD-SYMBOL(<lo_failed>).
        <lo_failed>-purchaseOrderId = <ls_key>-purchaseOrderId.
        <lo_failed>-%fail-cause = if_abap_behv=>cause-locked.
      ENDIF.
    ENDLOOP.
  ENDMETHOD.

  METHOD getMajorSupplier.

    ASSIGN keys[ 1 ] TO FIELD-SYMBOL(<ls_key>).
    IF sy-subrc <> 0.
      RETURN.
    ENDIF.

    APPEND INITIAL LINE TO result ASSIGNING FIELD-SYMBOL(<ls_result>).
    <ls_result>-%cid = <ls_key>-%cid.
    <ls_result>-%param = zpru_cl_utility_function=>get_major_supplier( ).

  ENDMETHOD.

  METHOD getStatusHistory.
    IF keys IS INITIAL.
      APPEND INITIAL LINE TO reported-%other ASSIGNING FIELD-SYMBOL(<lo_reported>).
      <lo_reported> = new_message( id       = zpru_if_m_po=>gc_po_message_class
                                   number   = '001'
                                   severity = if_abap_behv_message=>severity-error ).
      RETURN.
    ENDIF.

    READ ENTITIES OF zpru_purcorderhdr_tp
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

    LOOP AT keys ASSIGNING FIELD-SYMBOL(<ls_key>).

      ASSIGN lt_roots[ KEY id COMPONENTS %tky = <ls_key>-%tky ] TO FIELD-SYMBOL(<ls_instance>).
      IF sy-subrc <> 0.
        APPEND INITIAL LINE TO failed-ordertp ASSIGNING FIELD-SYMBOL(<ls_failed>).
        <ls_failed>-%tky = <ls_instance>-%tky.
        <ls_failed>-%fail-cause = if_abap_behv=>cause-not_found.
        <ls_failed>-%action-getStatusHistory = if_abap_behv=>mk-on.
        CONTINUE.
      ENDIF.

      APPEND INITIAL LINE TO result ASSIGNING FIELD-SYMBOL(<ls_result>).
      <ls_result> = zpru_cl_utility_function=>fetch_history( <ls_instance> ).
    ENDLOOP.
  ENDMETHOD.

  METHOD isSupplierBlacklisted.

    IF keys IS INITIAL.
      APPEND INITIAL LINE TO reported-%other ASSIGNING FIELD-SYMBOL(<lo_reported>).
      <lo_reported> = new_message( id       = zpru_if_m_po=>gc_po_message_class
                                   number   = '001'
                                   severity = if_abap_behv_message=>severity-error ).
      RETURN.
    ENDIF.

    READ ENTITIES OF zpru_purcorderhdr_tp
         IN LOCAL MODE
         ENTITY OrderTP
         FIELDS ( supplierId )
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
        <ls_failed>-%action-isSupplierBlacklisted = if_abap_behv=>mk-on.
        CONTINUE.
      ENDIF.

      " always false
      APPEND INITIAL LINE TO result ASSIGNING FIELD-SYMBOL(<ls_result>).
      <ls_result>-%tky = <ls_instance>-%tky.
      <ls_result>-%param-isSupplierBlacklisted =  abap_false.

    ENDLOOP.

  ENDMETHOD.

  METHOD Activate.
  ENDMETHOD.

  METHOD ChangeStatus.

    DATA lt_po_update TYPE lif_business_object=>tt_order_update.
    DATA lt_reval_rules TYPE lif_business_object=>tt_imp_revalidatepricingrules.


    IF keys IS INITIAL.
      APPEND INITIAL LINE TO reported-%other ASSIGNING FIELD-SYMBOL(<lo_reported>).
      <lo_reported> = new_message( id       = zpru_if_m_po=>gc_po_message_class
                                   number   = '001'
                                   severity = if_abap_behv_message=>severity-error ).
      RETURN.
    ENDIF.

    READ ENTITIES OF zpru_purcorderhdr_tp
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

    READ ENTITIES OF Zpru_PurcOrderHdr_tp
    IN LOCAL MODE
    ENTITY OrderTP
    EXECUTE isSupplierBlacklisted
    FROM CORRESPONDING #( keys )
    RESULT DATA(lt_check_suppliers).

    LOOP AT keys ASSIGNING FIELD-SYMBOL(<ls_key>).

      ASSIGN lt_roots[ KEY id COMPONENTS %tky = <ls_key>-%tky ] TO FIELD-SYMBOL(<ls_instance>).
      IF sy-subrc <> 0.
        APPEND INITIAL LINE TO failed-ordertp ASSIGNING FIELD-SYMBOL(<ls_failed>).
        <ls_failed>-%tky = <ls_instance>-%tky.
        <ls_failed>-%fail-cause = if_abap_behv=>cause-not_found.
        <ls_failed>-%action-ChangeStatus = if_abap_behv=>mk-on.
        CONTINUE.
      ENDIF.

      IF line_exists( lt_check_suppliers[ KEY
                                          id
                                          COMPONENTS
                                          %tky = <ls_instance>-%tky
                                          %param-isSupplierBlacklisted = abap_true ] ).

        APPEND INITIAL LINE TO failed-ordertp ASSIGNING <ls_failed>.
        <ls_failed>-%tky = <ls_instance>-%tky.
        <ls_failed>-%action-ChangeStatus = if_abap_behv=>mk-on.

        APPEND INITIAL LINE TO reported-ordertp ASSIGNING FIELD-SYMBOL(<ls_order_reported>).
        <ls_order_reported>-%tky        = <ls_instance>-%tky.
        <ls_order_reported>-%msg        = new_message( id       = zpru_if_m_po=>gc_po_message_class
                                                       number   = '006'
                                                       severity = if_abap_behv_message=>severity-error
                                                       v1       = <ls_instance>-purchaseOrderId ).

        CONTINUE.
      ENDIF.




    ENDLOOP.

* revalidates rules

*update status

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

  METHOD recalculateShippingMethod.
    DATA lt_order_update TYPE lif_business_object=>tt_order_update.

    IF keys IS INITIAL.
      APPEND INITIAL LINE TO reported-%other ASSIGNING FIELD-SYMBOL(<lo_reported>).
      <lo_reported> = new_message( id       = zpru_if_m_po=>gc_po_message_class
                                   number   = '001'
                                   severity = if_abap_behv_message=>severity-error ).
      RETURN.
    ENDIF.

    READ ENTITIES OF zpru_purcorderhdr_tp
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

    LOOP AT lt_roots ASSIGNING FIELD-SYMBOL(<ls_instance>).

      APPEND INITIAL LINE TO lt_order_update ASSIGNING FIELD-SYMBOL(<ls_order_update>).
      <ls_order_update>-%tky = <ls_instance>-%tky.
      <ls_order_update>-%data-shippingMethod = zpru_cl_utility_function=>get_preferred_ship_method(
                                                   <ls_instance>-supplierId ).
      <ls_order_update>-%control-shippingMethod = if_abap_behv=>mk-on.

    ENDLOOP.

    IF lt_order_update IS INITIAL.
      RETURN.
    ENDIF.

    MODIFY ENTITIES OF Zpru_PurcOrderHdr_tp
           IN LOCAL MODE
           ENTITY OrderTP
           UPDATE FROM lt_order_update.
  ENDMETHOD.

  METHOD setControlTimestamp.
    DATA lt_order_update TYPE lif_business_object=>tt_order_update.

    IF keys IS INITIAL.
      APPEND INITIAL LINE TO reported-%other ASSIGNING FIELD-SYMBOL(<lo_reported>).
      <lo_reported> = new_message( id       = zpru_if_m_po=>gc_po_message_class
                                   number   = '001'
                                   severity = if_abap_behv_message=>severity-error ).
      RETURN.
    ENDIF.

    READ ENTITIES OF zpru_purcorderhdr_tp
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

    GET TIME STAMP FIELD DATA(lv_now).

    LOOP AT lt_roots ASSIGNING FIELD-SYMBOL(<ls_instance>).

      APPEND INITIAL LINE TO lt_order_update ASSIGNING FIELD-SYMBOL(<ls_order_update>).
      <ls_order_update>-%tky = <ls_instance>-%tky.
      <ls_order_update>-%data-controlTimestamp = lv_now.
      <ls_order_update>-%control-controlTimestamp = if_abap_behv=>mk-on.

    ENDLOOP.

    IF lt_order_update IS INITIAL.
      RETURN.
    ENDIF.

    MODIFY ENTITIES OF Zpru_PurcOrderHdr_tp
           IN LOCAL MODE
           ENTITY OrderTP
           UPDATE FROM lt_order_update.
  ENDMETHOD.

  METHOD checkDates.
    IF keys IS INITIAL.
      APPEND INITIAL LINE TO reported-%other ASSIGNING FIELD-SYMBOL(<lo_reported>).
      <lo_reported> = new_message( id       = zpru_if_m_po=>gc_po_message_class
                                   number   = '001'
                                   severity = if_abap_behv_message=>severity-error ).
      RETURN.
    ENDIF.

    READ ENTITIES OF zpru_purcorderhdr_tp
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

      IF <ls_instance>-orderDate > <ls_instance>-deliveryDate.
        APPEND INITIAL LINE TO failed-ordertp ASSIGNING <ls_failed>.
        <ls_failed>-%tky = <ls_instance>-%tky.

        APPEND INITIAL LINE TO reported-ordertp ASSIGNING <ls_order_reported>.
        <ls_order_reported>-%tky        = <ls_instance>-%tky.
        <ls_order_reported>-%state_area = lif_business_object=>cs_state_area-order-checkdates.
        <ls_order_reported>-%msg        = new_message( id       = zpru_if_m_po=>gc_po_message_class
                                                       number   = '005'
                                                       severity = if_abap_behv_message=>severity-error
                                                       v1       = <ls_instance>-purchaseOrderId ).
      ENDIF.
    ENDLOOP.
  ENDMETHOD.

  METHOD get_global_authorizations.
*    AUTHORITY-CHECK OBJECT 'Test'
*    ID 'FIELD1' DUMMY.
*    IF sy-subrc <> 0.
*      result-%create = if_abap_behv=>auth-unauthorized.
*      result-%update = if_abap_behv=>auth-unauthorized.
*      result-%delete = if_abap_behv=>auth-unauthorized.
*      result-%action-Edit = if_abap_behv=>auth-unauthorized.
*      result-%action-ChangeStatus = if_abap_behv=>auth-unauthorized.
*      result-%action-checkOrder = if_abap_behv=>auth-unauthorized.
*      result-%action-createFromTemplate = if_abap_behv=>auth-unauthorized.
*      result-%action-sendOrderStatisticToAzure = if_abap_behv=>auth-unauthorized.
*    ELSE.
    result-%create = if_abap_behv=>auth-allowed.
    result-%update = if_abap_behv=>auth-allowed.
    result-%delete = if_abap_behv=>auth-allowed.
    result-%action-Edit                      = if_abap_behv=>auth-allowed.
    result-%action-ChangeStatus              = if_abap_behv=>auth-allowed.
    result-%action-checkOrder                = if_abap_behv=>auth-allowed.
    result-%action-createFromTemplate        = if_abap_behv=>auth-allowed.
    result-%action-sendOrderStatisticToAzure = if_abap_behv=>auth-allowed.
*    ENDIF.
  ENDMETHOD.

  METHOD precheck_create.
  ENDMETHOD.

  METHOD precheck_update.
  ENDMETHOD.

  METHOD precheck_delete.
  ENDMETHOD.

  METHOD get_instance_features.
    IF keys IS INITIAL.
      APPEND INITIAL LINE TO reported-%other ASSIGNING FIELD-SYMBOL(<lo_reported>).
      <lo_reported> = new_message( id       = zpru_if_m_po=>gc_po_message_class
                                   number   = '001'
                                   severity = if_abap_behv_message=>severity-error ).
      RETURN.
    ENDIF.

    READ ENTITIES OF zpru_purcorderhdr_tp
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

      IF <ls_instance>-status = zpru_if_m_po=>cs_status-archived.
        APPEND INITIAL LINE TO result ASSIGNING FIELD-SYMBOL(<ls_result>).
        <ls_result>-%is_draft       = <ls_result>-%is_draft.
        <ls_result>-%pid            = <ls_result>-%pid.
        <ls_result>-purchaseorderid = <ls_result>-purchaseOrderId.
        <ls_result>-%features-%field-PaymentTerms = if_abap_behv=>fc-f-read_only.
      ENDIF.
    ENDLOOP.
  ENDMETHOD.
ENDCLASS.


CLASS lhc_ItemTP DEFINITION INHERITING FROM cl_abap_behavior_handler.
  PRIVATE SECTION.
    METHODS get_instance_authorizations FOR INSTANCE AUTHORIZATION
      IMPORTING keys REQUEST requested_authorizations FOR ItemTP RESULT result.

    METHODS getInventoryStatus FOR READ
      IMPORTING keys FOR FUNCTION ItemTP~getInventoryStatus RESULT result.

    METHODS markAsUrgent FOR MODIFY
      IMPORTING keys FOR ACTION ItemTP~markAsUrgent.

    METHODS calculateTotalPrice FOR DETERMINE ON MODIFY
      IMPORTING keys FOR ItemTP~calculateTotalPrice.

    METHODS findWarehouseLocation FOR DETERMINE ON SAVE
      IMPORTING keys FOR ItemTP~findWarehouseLocation.

    METHODS checkQuantity FOR VALIDATE ON SAVE
      IMPORTING keys FOR ItemTP~checkQuantity.
    METHODS get_global_authorizations FOR GLOBAL AUTHORIZATION
      IMPORTING REQUEST requested_authorizations FOR ItemTP RESULT result.

ENDCLASS.


CLASS lhc_ItemTP IMPLEMENTATION.
  METHOD get_instance_authorizations.
  ENDMETHOD.

  METHOD getInventoryStatus.
  ENDMETHOD.

  METHOD markAsUrgent.
  ENDMETHOD.

  METHOD calculateTotalPrice.
  ENDMETHOD.

  METHOD findWarehouseLocation.
  ENDMETHOD.

  METHOD checkQuantity.
  ENDMETHOD.

  METHOD get_global_authorizations.
  ENDMETHOD.
ENDCLASS.


CLASS lsc_ZPRU_PURCORDERHDR_TP DEFINITION INHERITING FROM cl_abap_behavior_saver.
  PROTECTED SECTION.
    METHODS adjust_numbers   REDEFINITION.

    METHODS save_modified    REDEFINITION.

    METHODS cleanup          REDEFINITION.

    METHODS cleanup_finalize REDEFINITION.

ENDCLASS.


CLASS lsc_ZPRU_PURCORDERHDR_TP IMPLEMENTATION.
  METHOD adjust_numbers.
  ENDMETHOD.

  METHOD save_modified.
  ENDMETHOD.

  METHOD cleanup.
  ENDMETHOD.

  METHOD cleanup_finalize.
  ENDMETHOD.
ENDCLASS.
