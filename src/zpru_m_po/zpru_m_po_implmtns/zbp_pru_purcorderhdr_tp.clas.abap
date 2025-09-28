CLASS zbp_pru_purcorderhdr_tp DEFINITION PUBLIC ABSTRACT FINAL FOR BEHAVIOR OF zpru_purcorderhdr_tp.
  PUBLIC SECTION.
    CLASS-METHODS raise_event.
ENDCLASS.


CLASS zbp_pru_purcorderhdr_tp IMPLEMENTATION.
  METHOD raise_event.
    DATA lt_payload TYPE lif_business_object=>tt_createpo_event_in.

    APPEND INITIAL LINE TO lt_payload ASSIGNING FIELD-SYMBOL(<ls_payload>).
    <ls_payload>-purchaseorderid = '99'.

    RAISE ENTITY EVENT zpru_purcorderhdr_tp~ordercreated
          FROM lt_payload.
  ENDMETHOD.
ENDCLASS.
