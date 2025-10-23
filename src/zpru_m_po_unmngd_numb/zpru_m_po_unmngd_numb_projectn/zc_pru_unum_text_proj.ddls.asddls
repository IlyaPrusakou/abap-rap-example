@AccessControl.authorizationCheck: #NOT_REQUIRED
@EndUserText.label: 'Purchase Order Text Projection'
@Metadata.ignorePropagatedAnnotations: true
define view entity ZC_PRU_UNUM_TEXT_PROJ 
as projection on ZR_PRU_UNUM_TEXT_TP
{
    key PurchaseOrderId,
    key Language,
    TextContent,
    /* Associations */
    _OrderUn : redirected to parent ZC_PRU_UNUM_ORDER_PROJ
}
