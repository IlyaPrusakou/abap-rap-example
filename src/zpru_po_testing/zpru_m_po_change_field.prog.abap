*&---------------------------------------------------------------------*
*& Report zpru_m_po_change_field
*&---------------------------------------------------------------------*
*&
*&---------------------------------------------------------------------*
REPORT zpru_m_po_change_field.

BREAK-POINT.

MODIFY ENTITIES OF zpru_purcorderhdr_odata_int
       ENTITY orderint
       UPDATE FIELDS ( supplierid )
       WITH VALUE #( ( %tky-purchaseorderid = '00000000000000000004'
                       %tky-%is_draft       = if_abap_behv=>mk-off
                       %data-supplierId = 'SUP2' ) ).

COMMIT ENTITIES RESPONSE OF zpru_purcorderhdr_odata_int
       FAILED DATA(ls_failed)
       REPORTED DATA(ls_reported).

BREAK-POINT.
