*&---------------------------------------------------------------------*
*& Report zpru_un_po_draft
*&---------------------------------------------------------------------*
*&
*&---------------------------------------------------------------------*
REPORT zpru_un_po_draft.

DATA lt_read_draft TYPE TABLE FOR READ IMPORT zpru_u_purcorderhdr_tp\\OrderTP.
DATA lt_read_active TYPE TABLE FOR READ IMPORT zpru_u_purcorderhdr_tp\\OrderTP.



BREAK-POINT.

lt_read_active = VALUE #( (  purchaseOrderId = '00000000000000000002'
                            %is_draft       = if_abap_behv=>mk-off ) ).

READ ENTITIES OF zpru_u_purcorderhdr_tp
ENTITY OrderTP
ALL FIELDS WITH lt_read_active
RESULT DATA(lt_active).

BREAK-POINT.

lt_read_draft = VALUE #( (  purchaseOrderId = '00000000000000000002'
                            %is_draft       = if_abap_behv=>mk-on ) ).

"check dispatch
READ ENTITIES OF zpru_u_purcorderhdr_tp
ENTITY OrderTP
ALL FIELDS WITH lt_read_draft
RESULT DATA(lt_draft).

BREAK-POINT.

DATA lt_update_in_draft TYPE TABLE FOR UPDATE zpru_u_purcorderhdr_tp\\OrderTP.

lt_update_in_draft = VALUE #( ( purchaseOrderId = '00000000000000000002'
                                %is_draft       = if_abap_behv=>mk-on
                                supplierId      = 'SUP3'  ) ).

MODIFY ENTITIES OF zpru_u_purcorderhdr_tp
ENTITY OrderTP UPDATE FIELDS ( supplierId )
WITH lt_update_in_draft
REPORTED DATA(ls_reported_draft)
FAILED DATA(ls_failed_draft).


READ ENTITIES OF zpru_u_purcorderhdr_tp
ENTITY OrderTP
ALL FIELDS WITH lt_read_draft
RESULT DATA(lt_draft2).

BREAK-POINT.

DATA lt_update_in_ACTIVE TYPE TABLE FOR UPDATE zpru_u_purcorderhdr_tp\\OrderTP.

lt_update_in_ACTIVE = VALUE #( ( purchaseOrderId = '00000000000000000002'
                                %is_draft       = if_abap_behv=>mk-off
                                supplierId      = 'SUP4'  ) ).

MODIFY ENTITIES OF zpru_u_purcorderhdr_tp
ENTITY OrderTP UPDATE FIELDS ( supplierId )
WITH lt_update_in_ACTIVE
REPORTED DATA(ls_reported_active)
FAILED DATA(ls_failed_active).

READ ENTITIES OF zpru_u_purcorderhdr_tp
ENTITY OrderTP
ALL FIELDS WITH lt_read_active
RESULT DATA(lt_activ2).

BREAK-POINT.
