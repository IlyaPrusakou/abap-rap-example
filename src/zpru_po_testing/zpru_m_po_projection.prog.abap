*&---------------------------------------------------------------------*
*& Report zpru_m_po_projection
*&---------------------------------------------------------------------*
*&
*&---------------------------------------------------------------------*
REPORT zpru_m_po_projection.


DATA lt_read_in TYPE TABLE FOR READ IMPORT Zpru_PurcOrderHdr_ODATA_Proj\\OrderProj.


lt_read_in = VALUE #( ( purchaseorderid = '00000000000000000002') ).

BREAK-POINT.
" technically I can read data from projection BDEF, however it seems to not supposed way.
READ ENTITIES OF Zpru_PurcOrderHdr_ODATA_Proj
ENTITY OrderProj
ALL FIELDS WITH lt_read_in
RESULT DATA(lt_result).

BREAK-POINT.
