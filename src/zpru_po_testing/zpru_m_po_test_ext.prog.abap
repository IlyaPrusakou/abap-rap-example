*&---------------------------------------------------------------------*
*& Report zpru_m_po_test_ext
*&---------------------------------------------------------------------*
*&
*&---------------------------------------------------------------------*
REPORT zpru_m_po_test_ext.

DATA lt_layer_1_a TYPE TABLE FOR ACTION IMPORT zpru_purcorderhdr_odata_int\\orderint~layer_1_a.
DATA lt_layer_1_b TYPE TABLE FOR ACTION IMPORT zpru_purcorderhdr_odata_int\\orderint~layer_1_b.
DATA lt_layer_2_a TYPE TABLE FOR ACTION IMPORT zpru_purcorderhdr_odata_int\\orderint~layer_2_a.

SELECT * FROM zpru_purcorderhdr_odata_int INTO TABLE @DATA(lt_result) UP TO 5 ROWS.

IF lt_result IS INITIAL.
  RETURN.
ENDIF.

lt_layer_1_a = VALUE #( FOR <ls_1_a> IN lt_result ( %tky-purchaseorderid = <ls_1_a>-purchaseorderid
                                                    %tky-%is_draft       = if_abap_behv=>mk-off ) ).

lt_layer_1_b = VALUE #( FOR <ls_1_b> IN lt_result ( %tky-purchaseorderid = <ls_1_b>-purchaseorderid
                                                    %tky-%is_draft       = if_abap_behv=>mk-off ) ).

lt_layer_2_a = VALUE #( FOR <ls_2_a> IN lt_result ( %tky-purchaseorderid = <ls_2_a>-purchaseorderid
                                                    %tky-%is_draft       = if_abap_behv=>mk-off ) ).

MODIFY ENTITIES OF zpru_purcorderhdr_odata_int
       ENTITY orderint
       EXECUTE layer_1_a
       FROM lt_layer_1_a.

MODIFY ENTITIES OF zpru_purcorderhdr_odata_int
       ENTITY orderint
       EXECUTE layer_1_b
       FROM lt_layer_1_b.

MODIFY ENTITIES OF zpru_purcorderhdr_odata_int
       ENTITY orderint
       EXECUTE layer_2_a
       FROM lt_layer_2_a.

WRITE 'The End'.
