CLASS lhc_OrderTP DEFINITION INHERITING FROM cl_abap_behavior_handler.
  PRIVATE SECTION.

    METHODS augment_create FOR MODIFY
      IMPORTING entities FOR CREATE OrderProj.

    METHODS precheck_create FOR PRECHECK
      IMPORTING entities FOR CREATE Orderproj.

    METHODS augment_cba_Items_tp FOR MODIFY
      IMPORTING entities FOR CREATE OrderProj\_Items_tp.

    METHODS precheck_cba_Items_tp FOR PRECHECK
      IMPORTING entities FOR CREATE OrderProj\_Items_tp.
    METHODS precheck_ChangeStatus FOR PRECHECK
      IMPORTING keys FOR ACTION OrderProj~ChangeStatus.
*    METHODS getStatusHistory FOR READ
*      IMPORTING keys FOR FUNCTION OrderProj~getStatusHistory RESULT result.

*    METHODS sendToIDOC FOR MODIFY
*      IMPORTING keys FOR ACTION OrderProj~sendToIDOC.

ENDCLASS.

CLASS lhc_OrderTP IMPLEMENTATION.

  METHOD augment_create.
  ENDMETHOD.

  METHOD precheck_create.
  ENDMETHOD.

  METHOD augment_cba_Items_tp.
  ENDMETHOD.

  METHOD precheck_cba_Items_tp.
  ENDMETHOD.

  METHOD precheck_ChangeStatus.
  ENDMETHOD.

*  METHOD getStatusHistory.
*  ENDMETHOD.
*
*  METHOD sendToIDOC.
*  ENDMETHOD.

ENDCLASS.
