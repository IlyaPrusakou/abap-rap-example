CLASS lhc_orderint DEFINITION INHERITING FROM cl_abap_behavior_handler.
  PRIVATE SECTION.

    METHODS get_instance_authorizations FOR INSTANCE AUTHORIZATION
      IMPORTING keys REQUEST requested_authorizations FOR orderint RESULT result.

    METHODS get_global_authorizations FOR GLOBAL AUTHORIZATION
      IMPORTING REQUEST requested_authorizations FOR orderint RESULT result.

    METHODS layer_1_a FOR MODIFY
      IMPORTING keys FOR ACTION orderint~layer_1_a.

ENDCLASS.

CLASS lhc_orderint IMPLEMENTATION.

  METHOD get_instance_authorizations.
  ENDMETHOD.

  METHOD get_global_authorizations.
  ENDMETHOD.

  METHOD layer_1_a.

    READ ENTITIES OF zpru_purcorderhdr_odata_int
    IN LOCAL MODE
    ENTITY orderint
    ALL FIELDS WITH CORRESPONDING #( keys )
    RESULT DATA(lt_result).

  ENDMETHOD.

ENDCLASS.
