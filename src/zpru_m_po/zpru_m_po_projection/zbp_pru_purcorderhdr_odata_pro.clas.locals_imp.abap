CLASS lhc_OrderTP DEFINITION INHERITING FROM cl_abap_behavior_handler.
  PRIVATE SECTION.

    METHODS augment_create FOR MODIFY
      IMPORTING entities FOR CREATE OrderTP.

    METHODS precheck_create FOR PRECHECK
      IMPORTING entities FOR CREATE OrderTP.

    METHODS augment_cba_Items_tp FOR MODIFY
      IMPORTING entities FOR CREATE OrderTP\_Items_tp.

    METHODS precheck_cba_Items_tp FOR PRECHECK
      IMPORTING entities FOR CREATE OrderTP\_Items_tp.

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

ENDCLASS.
