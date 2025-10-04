@AccessControl.authorizationCheck: #NOT_REQUIRED
@EndUserText.label: 'Purchase Order Text Projection'
@Metadata.ignorePropagatedAnnotations: true
define view entity ZPRU_RO_PURCORDERHDR_T_PROJ as projection on ZPRU_RO_PURCORDERHDR_T_TP
{
    key PurchaseOrderId,
    key Language,
    TextContent,
    /* Associations */
    _header_tp : redirected to parent Zpru_RO_PurcOrderHdr_Proj
}
