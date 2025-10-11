CLASS lsc_zr_pru_unum_order_tp DEFINITION INHERITING FROM cl_abap_behavior_saver.

  PROTECTED SECTION.

    METHODS save_modified REDEFINITION.

ENDCLASS.

CLASS lsc_zr_pru_unum_order_tp IMPLEMENTATION.

  METHOD save_modified.
  ENDMETHOD.

ENDCLASS.

CLASS lhc_itemun DEFINITION INHERITING FROM cl_abap_behavior_handler.

  PRIVATE SECTION.

    METHODS get_global_authorizations FOR GLOBAL AUTHORIZATION
      IMPORTING REQUEST requested_authorizations FOR ItemUn RESULT result.

    METHODS getInventoryStatus FOR READ
      IMPORTING keys FOR FUNCTION ItemUn~getInventoryStatus RESULT result.

    METHODS markAsUrgent FOR MODIFY
      IMPORTING keys FOR ACTION ItemUn~markAsUrgent.

    METHODS calculateTotalPrice FOR DETERMINE ON MODIFY
      IMPORTING keys FOR ItemUn~calculateTotalPrice.

    METHODS findWarehouseLocation FOR DETERMINE ON SAVE
      IMPORTING keys FOR ItemUn~findWarehouseLocation.

    METHODS writeItemNumber FOR DETERMINE ON SAVE
      IMPORTING keys FOR ItemUn~writeItemNumber.

    METHODS checkItemCurrency FOR VALIDATE ON SAVE
      IMPORTING keys FOR ItemUn~checkItemCurrency.

    METHODS checkQuantity FOR VALIDATE ON SAVE
      IMPORTING keys FOR ItemUn~checkQuantity.

ENDCLASS.

CLASS lhc_itemun IMPLEMENTATION.

  METHOD get_global_authorizations.
  ENDMETHOD.

  METHOD getInventoryStatus.
  ENDMETHOD.

  METHOD markAsUrgent.
  ENDMETHOD.

  METHOD calculateTotalPrice.
  ENDMETHOD.

  METHOD findWarehouseLocation.
  ENDMETHOD.

  METHOD writeItemNumber.
  ENDMETHOD.

  METHOD checkItemCurrency.
  ENDMETHOD.

  METHOD checkQuantity.
  ENDMETHOD.

ENDCLASS.

CLASS LHC_ORDERUN DEFINITION INHERITING FROM CL_ABAP_BEHAVIOR_HANDLER.
  PRIVATE SECTION.
    METHODS:
      GET_GLOBAL_AUTHORIZATIONS FOR GLOBAL AUTHORIZATION
        IMPORTING
           REQUEST requested_authorizations FOR OrderUn
        RESULT result,
      earlynumbering_create FOR NUMBERING
            IMPORTING entities FOR CREATE OrderUn.

          METHODS earlynumbering_cba_Itemsun FOR NUMBERING
            IMPORTING entities FOR CREATE OrderUn\_Itemsun.

          METHODS earlynumbering_cba_Textun FOR NUMBERING
            IMPORTING entities FOR CREATE OrderUn\_Textun.
ENDCLASS.

CLASS LHC_ORDERUN IMPLEMENTATION.
  METHOD GET_GLOBAL_AUTHORIZATIONS.
  ENDMETHOD.
  METHOD earlynumbering_create.
  ENDMETHOD.

  METHOD earlynumbering_cba_Itemsun.
  ENDMETHOD.

  METHOD earlynumbering_cba_Textun.
  ENDMETHOD.

ENDCLASS.
