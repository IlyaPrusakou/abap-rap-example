CLASS lhc_orderint DEFINITION INHERITING FROM cl_abap_behavior_handler.
  PRIVATE SECTION.

    METHODS layer_1_b FOR MODIFY
      IMPORTING keys FOR ACTION orderint~layer_1_b.

ENDCLASS.

CLASS lhc_orderint IMPLEMENTATION.

  METHOD layer_1_b.

    READ ENTITIES OF zpru_purcorderhdr_odata_int
    IN LOCAL MODE
    ENTITY orderint
    ALL FIELDS WITH CORRESPONDING #( keys )
    RESULT DATA(lt_result).

  ENDMETHOD.

ENDCLASS.
