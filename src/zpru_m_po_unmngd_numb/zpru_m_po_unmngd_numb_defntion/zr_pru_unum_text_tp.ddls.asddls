@AccessControl.authorizationCheck: #NOT_REQUIRED
@EndUserText.label: 'Unmanaged Numbering Text'
@Metadata.ignorePropagatedAnnotations: true
define view entity ZR_PRU_UNUM_TEXT_TP as select from Zpru_PurcOrderHdr_T
association to parent ZR_PRU_UNUM_ORDER_TP as _OrderUn
    on $projection.PurchaseOrderId = _OrderUn.purchaseOrderId
{
    key PurchaseOrderId,
    key Language,
    TextContent,
    _OrderUn
}
