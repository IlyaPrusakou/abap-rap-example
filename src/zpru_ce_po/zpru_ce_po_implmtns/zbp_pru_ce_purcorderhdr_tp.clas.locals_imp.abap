CLASS lhc_zpru_ce_purcorderhdr_tp DEFINITION INHERITING FROM cl_abap_behavior_handler.
  PRIVATE SECTION.

    METHODS get_instance_authorizations FOR INSTANCE AUTHORIZATION
      IMPORTING keys REQUEST requested_authorizations FOR zpru_ce_purcorderhdr_tp RESULT result.

*    METHODS create FOR MODIFY
*      IMPORTING entities FOR CREATE zpru_ce_purcorderhdr_tp.

*    METHODS update FOR MODIFY
*      IMPORTING entities FOR UPDATE zpru_ce_purcorderhdr_tp.
*
*    METHODS delete FOR MODIFY
*      IMPORTING keys FOR DELETE zpru_ce_purcorderhdr_tp.

    METHODS read FOR READ
      IMPORTING keys FOR READ zpru_ce_purcorderhdr_tp RESULT result.

    METHODS lock FOR LOCK
      IMPORTING keys FOR LOCK zpru_ce_purcorderhdr_tp.

    METHODS rba_items_tp FOR READ
      IMPORTING keys_rba FOR READ zpru_ce_purcorderhdr_tp\_items_tp FULL result_requested RESULT result LINK association_links.

    METHODS cba_items_tp FOR MODIFY
      IMPORTING entities_cba FOR CREATE zpru_ce_purcorderhdr_tp\_items_tp.
    METHODS get_global_authorizations FOR GLOBAL AUTHORIZATION
      IMPORTING REQUEST requested_authorizations FOR zpru_ce_purcorderhdr_tp RESULT result.
    METHODS summary FOR MODIFY
      IMPORTING keys FOR ACTION zpru_ce_purcorderhdr_tp~summary.

ENDCLASS.

CLASS lhc_zpru_ce_purcorderhdr_tp IMPLEMENTATION.

  METHOD get_instance_authorizations.
  ENDMETHOD.

*  METHOD create.
*  ENDMETHOD.
*
*  METHOD update.
*  ENDMETHOD.
*
*  METHOD delete.
*  ENDMETHOD.

  METHOD read.
  ENDMETHOD.

  METHOD lock.
  ENDMETHOD.

  METHOD rba_items_tp.
  ENDMETHOD.

  METHOD cba_items_tp.
  ENDMETHOD.

  METHOD get_global_authorizations.
  ENDMETHOD.

  METHOD Summary.
  ENDMETHOD.

ENDCLASS.

CLASS lhc_zpru_ce_purcorder_item_tp DEFINITION INHERITING FROM cl_abap_behavior_handler.
  PRIVATE SECTION.

    METHODS update FOR MODIFY
      IMPORTING entities FOR UPDATE zpru_ce_purcorder_item_tp.

    METHODS delete FOR MODIFY
      IMPORTING keys FOR DELETE zpru_ce_purcorder_item_tp.

    METHODS read FOR READ
      IMPORTING keys FOR READ zpru_ce_purcorder_item_tp RESULT result.

    METHODS rba_header_tp FOR READ
      IMPORTING keys_rba FOR READ zpru_ce_purcorder_item_tp\_header_tp FULL result_requested RESULT result LINK association_links.

ENDCLASS.

CLASS lhc_zpru_ce_purcorder_item_tp IMPLEMENTATION.

  METHOD update.
  ENDMETHOD.

  METHOD delete.
  ENDMETHOD.

  METHOD read.
  ENDMETHOD.

  METHOD rba_header_tp.
  ENDMETHOD.

ENDCLASS.

CLASS lsc_zpru_ce_purcorderhdr_tp DEFINITION INHERITING FROM cl_abap_behavior_saver.
  PROTECTED SECTION.

    METHODS finalize REDEFINITION.

    METHODS check_before_save REDEFINITION.

    METHODS save REDEFINITION.

    METHODS cleanup REDEFINITION.

    METHODS cleanup_finalize REDEFINITION.

ENDCLASS.

CLASS lsc_zpru_ce_purcorderhdr_tp IMPLEMENTATION.

  METHOD finalize.
  ENDMETHOD.

  METHOD check_before_save.
  ENDMETHOD.

  METHOD save.
  ENDMETHOD.

  METHOD cleanup.
  ENDMETHOD.

  METHOD cleanup_finalize.
  ENDMETHOD.

ENDCLASS.
