*&---------------------------------------------------------------------*
*& Report zpru_m_po_interface
*&---------------------------------------------------------------------*
*&
*&---------------------------------------------------------------------*
REPORT zpru_m_po_interface.

DATA lt_change_status_in TYPE TABLE FOR ACTION IMPORT Zpru_PurcOrderHdr_ODATA_Int~ChangeStatus.

lt_change_status_in = VALUE #( (  purchaseorderid  = '00000000000000000001'
                                  %param-newStatus1 = 'P'  ) ).

BREAK-POINT.

MODIFY ENTITIES OF Zpru_PurcOrderHdr_ODATA_Int
ENTITY OrderInt
EXECUTE ChangeStatus
FROM lt_change_status_in
REPORTED DATA(ls_reported)
FAILED DATA(ls_failed).

COMMIT ENTITIES RESPONSE OF Zpru_PurcOrderHdr_ODATA_Int
REPORTED DATA(ls_reported2)
FAILED DATA(ls_failed2).

BREAK-POINT.
