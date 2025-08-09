@AccessControl.authorizationCheck: #NOT_REQUIRED
@EndUserText.label: 'Purchase Order Text Projection'
@Metadata.ignorePropagatedAnnotations: true
define view entity Zpru_PurcOrderHdr_T_PROJ as projection on Zpru_PurcOrderHdr_T_TP
{
    key PurchaseOrderId,
    key Language,
    TextContent,
    /* Associations */
    _header_tp : redirected to parent Zpru_PurcOrderHdr_ODATA_Proj
}
