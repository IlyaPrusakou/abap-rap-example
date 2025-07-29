@AccessControl.authorizationCheck: #NOT_REQUIRED
@EndUserText.label: 'Projection for ODATA Service Items'
@Metadata.ignorePropagatedAnnotations: true
define view entity Zpru_PurcOrderItem_ODATA_Proj 
as projection on Zpru_PurcOrderItem_ODATA_Int
{
    key itemId,
    key purchaseOrderId,
    itemNumber,
    productId,
    productName,
    quantity,
    @Semantics.amount.currencyCode : 'itemCurrency'
    unitPrice,
    @Semantics.amount.currencyCode : 'itemCurrency'
    totalPrice,
    deliveryDate,
    warehouseLocation,
    itemCurrency,
    isUrgent,
    createdBy,
    createOn,
    changedBy,
    changedOn,
    /* Associations */
    _header_tp : redirected to parent Zpru_PurcOrderHdr_ODATA_Proj
}
