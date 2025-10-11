@AccessControl.authorizationCheck: #NOT_REQUIRED
@EndUserText.label: 'Unmanaged Numbering Item'
@Metadata.ignorePropagatedAnnotations: true
define view entity ZR_PRU_UNUM_ITEM_TP as select from Zpru_PurcOrderItem
association to parent ZR_PRU_UNUM_ORDER_TP as _OrderUn
    on $projection.purchaseOrderId = _OrderUn.purchaseOrderId
{
    key itemId,
    key purchaseOrderId,
    itemNumber,
    productId,
    productName,
    quantity,
    @Semantics.amount.currencyCode: 'itemCurrency'
    unitPrice,
    @Semantics.amount.currencyCode: 'itemCurrency'
    totalPrice,
    deliveryDate,
    warehouseLocation,
    itemCurrency,
    isUrgent,
    @Semantics.user.createdBy: true
    createdBy,
    @Semantics.systemDateTime.createdAt: true
    createOn,
    @Semantics.user.localInstanceLastChangedBy: true
    changedBy,
    @Semantics.systemDateTime.localInstanceLastChangedAt: true
    changedOn,
    
    _OrderUn
}
