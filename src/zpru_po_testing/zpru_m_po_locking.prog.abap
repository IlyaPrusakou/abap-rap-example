*&---------------------------------------------------------------------*
*& Report zpru_m_po_locking
*&---------------------------------------------------------------------*
*&
*&---------------------------------------------------------------------*
REPORT zpru_m_po_locking.

BREAK-POINT.

SET LOCKS OF zpru_purcorderhdr_odata_int
    ENTITY orderint
    FROM VALUE #( ( purchaseorderid = '00000000000000000004' ) )
    FAILED   FINAL(lt_failed2)
    REPORTED FINAL(lt_reported2).

BREAK-POINT.

*COMMIT ENTITIES RESPONSE OF zpru_purcorderhdr_odata_int
*       FAILED DATA(ls_save_draft_failed)
*       REPORTED DATA(ls_save_draft_report).
*IF sy-subrc <> 0.
*  ROLLBACK ENTITIES.
*  RETURN.
*ENDIF.

BREAK-POINT.
