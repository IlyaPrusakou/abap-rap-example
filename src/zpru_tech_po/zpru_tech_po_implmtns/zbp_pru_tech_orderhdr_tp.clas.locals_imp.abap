CLASS lsc_zpru_tech_orderhdr_tp DEFINITION INHERITING FROM cl_abap_behavior_saver.

  PROTECTED SECTION.

    METHODS save_modified REDEFINITION.

    METHODS cleanup REDEFINITION.

ENDCLASS.

CLASS lsc_zpru_tech_orderhdr_tp IMPLEMENTATION.

  METHOD save_modified.
  ENDMETHOD.

  METHOD cleanup.
  ENDMETHOD.

ENDCLASS.

CLASS lhc_OrderTP DEFINITION INHERITING FROM cl_abap_behavior_handler.
  PRIVATE SECTION.

    METHODS get_instance_authorizations FOR INSTANCE AUTHORIZATION
      IMPORTING keys REQUEST requested_authorizations FOR OrderTP RESULT result.
    METHODS get_global_authorizations FOR GLOBAL AUTHORIZATION
      IMPORTING REQUEST requested_authorizations FOR ordertp RESULT result.

ENDCLASS.

CLASS lhc_OrderTP IMPLEMENTATION.

  METHOD get_instance_authorizations.
  ENDMETHOD.

  METHOD get_global_authorizations.
  ENDMETHOD.

ENDCLASS.
