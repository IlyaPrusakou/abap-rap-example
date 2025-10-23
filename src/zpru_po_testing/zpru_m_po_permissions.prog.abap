*&---------------------------------------------------------------------*
*& Report zpru_m_po_permissions
*&---------------------------------------------------------------------*
*&
*&---------------------------------------------------------------------*
REPORT zpru_m_po_permissions.

BREAK-POINT.

GET PERMISSIONS
    ONLY INSTANCE FEATURES
    OF ZPRU_PURCORDERHDR_ODATA_INT
    ENTITY OrderInt
    FROM VALUE #( ( %tky-purchaseorderid = '00000000000000000005' ) )
    REQUEST VALUE #( %action-ChangeStatus = if_abap_behv=>mk-on
                     %field-PaymentTerms  = if_abap_behv=>mk-on
                     %create              = if_abap_behv=>mk-on
                     %update              = if_abap_behv=>mk-on
                     %delete              = if_abap_behv=>mk-on )
    RESULT FINAL(result2)
    FAILED FINAL(failed2)
    REPORTED FINAL(reported2).

GET PERMISSIONS
    OF ZPRU_PURCORDERHDR_ODATA_INT
    ENTITY OrderInt
    FROM VALUE #( ( %tky-purchaseorderid = '00000000000000000005' ) )
    REQUEST VALUE #( %action-ChangeStatus = if_abap_behv=>mk-on
                     %field-PaymentTerms  = if_abap_behv=>mk-on
                     %create              = if_abap_behv=>mk-on
                     %update              = if_abap_behv=>mk-on
                     %delete              = if_abap_behv=>mk-on )
    RESULT FINAL(result3)
    FAILED FINAL(failed3)
    REPORTED FINAL(reported3).

BREAK-POINT.
