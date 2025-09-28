CLASS lhc_orderproj DEFINITION INHERITING FROM cl_abap_behavior_handler.

  PRIVATE SECTION.

    METHODS proj_ext FOR MODIFY
      IMPORTING keys FOR ACTION OrderProj~proj_ext.

ENDCLASS.

CLASS lhc_orderproj IMPLEMENTATION.

  METHOD proj_ext.

    READ ENTITIES OF zpru_purcorderhdr_odata_int
    ENTITY orderint
    ALL FIELDS WITH CORRESPONDING #( keys )
    RESULT DATA(lt_result).

  ENDMETHOD.

ENDCLASS.
