*&---------------------------------------------------------------------*
*& Report zpru_un_po_draft_vs_active
*&---------------------------------------------------------------------*
*&
*&---------------------------------------------------------------------*
REPORT zpru_un_po_draft_vs_active.

SELECTION-SCREEN BEGIN OF BLOCK po WITH FRAME TITLE TEXT-001.
  PARAMETERS p_poid TYPE zpru_de_po_id OBLIGATORY.
  PARAMETERS p_sup_dr TYPE zpru_de_supplier.
  PARAMETERS p_sup_ac TYPE zpru_de_supplier.
SELECTION-SCREEN END OF BLOCK po.

START-OF-SELECTION.
  DATA lt_edit_input    TYPE TABLE FOR ACTION IMPORT zpru_u_purcorderhdr_int\\orderint~edit.
  DATA lt_discard_input    TYPE TABLE FOR ACTION IMPORT zpru_u_purcorderhdr_int\\orderint~discard.
  DATA lt_read_active   TYPE TABLE FOR READ IMPORT zpru_u_purcorderhdr_int\\orderint.
  DATA lt_read_draft    TYPE TABLE FOR READ IMPORT zpru_u_purcorderhdr_int\\orderint.
  DATA lt_update_active TYPE TABLE FOR UPDATE zpru_u_purcorderhdr_int\\orderint.
  DATA lt_update_draft  TYPE TABLE FOR UPDATE zpru_u_purcorderhdr_int\\orderint.

  APPEND INITIAL LINE TO lt_edit_input ASSIGNING FIELD-SYMBOL(<ls_edit_input>).
  <ls_edit_input>-%cid            = 'EDIT_1'.
  <ls_edit_input>-purchaseorderid = p_poid.

  " CREATE DRAFT PO IN DRAFT BUFFER
  MODIFY ENTITIES OF zpru_u_purcorderhdr_int
         ENTITY orderint
         EXECUTE edit FROM lt_edit_input
         MAPPED DATA(ls_map_edit)
         FAILED DATA(ls_fail_edit)
         REPORTED DATA(ls_rep_edit).

  BREAK-POINT.

  " READ PO FROM DRAFT BUFFER
  " DRAFT TABLES HAVEN'T HAD PO DATA YET
  READ ENTITIES OF zpru_u_purcorderhdr_int
       ENTITY orderint
       ALL FIELDS WITH VALUE #( FOR <ls_r1>
                                IN ls_map_edit-orderint
                                ( %is_draft       = <ls_r1>-%is_draft
                                  purchaseorderid = <ls_r1>-purchaseorderid ) )
       RESULT DATA(lt_roots_drft).

  " READ PO FROM DRAFT BUFFER
  " DRAFT TABLES HAVEN'T HAD PO DATA YET
  READ ENTITIES OF zpru_u_purcorderhdr_int
       ENTITY orderint BY \_items_tp
       ALL FIELDS WITH VALUE #( FOR <ls_r2>
                                IN ls_map_edit-orderint
                                ( %is_draft       = <ls_r2>-%is_draft
                                  purchaseorderid = <ls_r2>-purchaseorderid ) )
       RESULT DATA(lt_items_drft).

  " SAVE DRAFT BUFFER TO DRAFT TABLES
  " PO WILL APPEAR IN DRAFT DATA BASE TABLES
  COMMIT ENTITIES RESPONSE OF zpru_u_purcorderhdr_int
         FAILED DATA(ls_save_draft_failed)
         REPORTED DATA(ls_save_draft_report).

  APPEND INITIAL LINE TO lt_read_active ASSIGNING FIELD-SYMBOL(<ls_read_active>).
  <ls_read_active>-%is_draft       = if_abap_behv=>mk-off.
  <ls_read_active>-purchaseorderid = p_poid.

  " READ ACTIVE PO ROOT
  READ ENTITIES OF zpru_u_purcorderhdr_int
       ENTITY orderint
       ALL FIELDS WITH lt_read_active
       RESULT DATA(lt_roots_active1).

  APPEND INITIAL LINE TO lt_read_draft ASSIGNING FIELD-SYMBOL(<ls_read_draft>).
  <ls_read_draft>-%is_draft       = if_abap_behv=>mk-on.
  <ls_read_draft>-purchaseorderid = p_poid.

  " READ DRAFT PO ROOT
  READ ENTITIES OF zpru_u_purcorderhdr_int
       ENTITY orderint
       ALL FIELDS WITH lt_read_draft
       RESULT DATA(lt_roots_draft1).

  " UPDATE ACTIVE
  APPEND INITIAL LINE TO lt_update_active ASSIGNING FIELD-SYMBOL(<ls_update_active>).
  <ls_update_active>-%is_draft       = if_abap_behv=>mk-off.
  <ls_update_active>-purchaseorderid = p_poid.
  <ls_update_active>-supplierid      = p_sup_ac.
  <ls_update_active>-%control-supplierid = if_abap_behv=>mk-on.

  MODIFY ENTITIES OF zpru_u_purcorderhdr_int
         ENTITY orderint
         UPDATE FROM lt_update_active.

  " UPDATE DRAFT
  APPEND INITIAL LINE TO lt_update_draft ASSIGNING FIELD-SYMBOL(<ls_update_draft>).
  <ls_update_draft>-%is_draft       = if_abap_behv=>mk-on.
  <ls_update_draft>-purchaseorderid = p_poid.
  <ls_update_draft>-supplierid      = p_sup_dr.
  <ls_update_draft>-%control-supplierid = if_abap_behv=>mk-on.

  MODIFY ENTITIES OF zpru_u_purcorderhdr_int
         ENTITY orderint
         UPDATE FROM lt_update_draft.

  " READ ACTIVE PO ROOT AFTER UPDATE
  READ ENTITIES OF zpru_u_purcorderhdr_int
       ENTITY orderint
       ALL FIELDS WITH lt_read_active
       RESULT DATA(lt_roots_active2).

  " READ DRAFT PO ROOT AFTER UPDATE
  READ ENTITIES OF zpru_u_purcorderhdr_int
       ENTITY orderint
       ALL FIELDS WITH lt_read_draft
       RESULT DATA(lt_roots_draft2).

  APPEND INITIAL LINE TO lt_discard_input ASSIGNING FIELD-SYMBOL(<ls_DISCARD_draft>).
  <ls_DISCARD_draft>-purchaseorderid = p_poid.

  " DISCARD DRAFT
  MODIFY ENTITIES OF zpru_u_purcorderhdr_int
  ENTITY orderint
  EXECUTE discard FROM lt_discard_input
  REPORTED DATA(ls_discard_rep)
  FAILED DATA(ls_discard_fail).

  " READ ACTIVE PO ROOT AFTER DISCARD
  READ ENTITIES OF zpru_u_purcorderhdr_int
       ENTITY orderint
       ALL FIELDS WITH lt_read_active
       RESULT DATA(lt_roots_active3).

  " READ DRAFT PO ROOT AFTER DISCARD
  READ ENTITIES OF zpru_u_purcorderhdr_int
       ENTITY orderint
       ALL FIELDS WITH lt_read_draft
       RESULT DATA(lt_roots_draft3).

  " DELETE FROM DRAFT TABLES
  " PO WILL DISAPPEAR IN DRAFT DATA BASE TABLES
  COMMIT ENTITIES RESPONSE OF zpru_u_purcorderhdr_int
         FAILED DATA(ls_save_draft_failed2)
         REPORTED DATA(ls_save_draft_report2).

  WRITE 'The End'.
