*&---------------------------------------------------------------------*
*& Report zpru_un_po_determ_on_mod
*&---------------------------------------------------------------------*
*&
*&---------------------------------------------------------------------*
REPORT zpru_un_po_determ_on_mod.

SELECTION-SCREEN BEGIN OF BLOCK po WITH FRAME TITLE TEXT-001.
  PARAMETERS p_poid TYPE zpru_de_po_id OBLIGATORY.
  PARAMETERS p_buy_nw TYPE zpru_de_buyer.
SELECTION-SCREEN END OF BLOCK po.

START-OF-SELECTION.

  DATA lt_read_active   TYPE TABLE FOR READ IMPORT zpru_u_purcorderhdr_int\\orderint.
  DATA lt_update_active TYPE TABLE FOR UPDATE zpru_u_purcorderhdr_int\\orderint.

  APPEND INITIAL LINE TO lt_read_active ASSIGNING FIELD-SYMBOL(<ls_read_active>).
  <ls_read_active>-%is_draft       = if_abap_behv=>mk-off.
  <ls_read_active>-purchaseorderid = p_poid.

  " READ BEFORE UPDATE
  READ ENTITIES OF zpru_u_purcorderhdr_int
       ENTITY orderint
       ALL FIELDS WITH lt_read_active
       RESULT DATA(lt_roots_active1).

  " UPDATE ACTIVE
  APPEND INITIAL LINE TO lt_update_active ASSIGNING FIELD-SYMBOL(<ls_update_active>).
  <ls_update_active>-%is_draft        = if_abap_behv=>mk-off.
  <ls_update_active>-purchaseorderid  = p_poid.
  <ls_update_active>-buyerid          = p_buy_nw.
  <ls_update_active>-%control-buyerid = if_abap_behv=>mk-on.

  " DETERMINATION determineNames IS NOT INVOKED BECAUSE IT IS ACTIVE INSTANCE
  " FOR DRAFT DETERMINATION ON MODIFY IS INVOKED
  MODIFY ENTITIES OF zpru_u_purcorderhdr_int
         ENTITY orderint
         UPDATE FROM lt_update_active.

  " READ AFTER UPDATE
  READ ENTITIES OF zpru_u_purcorderhdr_int
       ENTITY orderint
       ALL FIELDS WITH lt_read_active
       RESULT DATA(lt_roots_active2).


  " METHOD OF DETERMIANTION ON SAVE setControlTimestamp AND VALIDATION ON SAVE checkSupplier
  " NOT INVOKED BUT METHOD FINALIZE IS INVOKED
  COMMIT ENTITIES RESPONSE OF zpru_u_purcorderhdr_int
         FAILED DATA(ls_save_draft_failed2)
         REPORTED DATA(ls_save_draft_report2).

  READ ENTITIES OF zpru_u_purcorderhdr_int
       ENTITY orderint
       ALL FIELDS WITH lt_read_active
       RESULT DATA(lt_roots_active3).
