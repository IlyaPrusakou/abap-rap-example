CLASS lhc_orderint DEFINITION INHERITING FROM cl_abap_behavior_handler.
  PRIVATE SECTION.
    METHODS layer_2_a FOR MODIFY
      IMPORTING keys FOR ACTION orderint~layer_2_a.

ENDCLASS.


CLASS lhc_orderint IMPLEMENTATION.
  METHOD layer_2_a.
    READ ENTITIES OF zpru_purcorderhdr_odata_int
         IN LOCAL MODE
         ENTITY orderint
         ALL FIELDS WITH CORRESPONDING #( keys )
         RESULT DATA(lt_result).

    MODIFY ENTITIES OF zpru_purcorderhdr_odata_int
           IN LOCAL MODE
           ENTITY orderint
           EXECUTE layer_1_a
           FROM CORRESPONDING #( keys ).

    MODIFY ENTITIES OF zpru_purcorderhdr_odata_int IN LOCAL MODE
           ENTITY orderint
           EXECUTE layer_1_b
           FROM CORRESPONDING #( keys ).

     " endless recursion
*    MODIFY ENTITIES OF zpru_purcorderhdr_odata_int IN LOCAL MODE
*           ENTITY orderint
*           EXECUTE layer_2_a
*           FROM CORRESPONDING #( keys ).
  ENDMETHOD.
ENDCLASS.
