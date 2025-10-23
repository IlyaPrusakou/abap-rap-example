CLASS lhc_action_group_in_textun DEFINITION INHERITING FROM cl_abap_behavior_handler.
  PRIVATE SECTION.

    METHODS get_global_authorizations FOR GLOBAL AUTHORIZATION
      IMPORTING REQUEST requested_authorizations FOR textun~action_group RESULT result.

    METHODS changetext FOR MODIFY
      IMPORTING keys FOR ACTION textun~changetext.

    METHODS precheck_changetext FOR PRECHECK
      IMPORTING keys FOR ACTION textun~changetext.

ENDCLASS.

CLASS lhc_action_group_in_textun IMPLEMENTATION.

  METHOD get_global_authorizations.
  ENDMETHOD.

  METHOD changetext.
  ENDMETHOD.

  METHOD precheck_changetext.
  ENDMETHOD.

ENDCLASS.
