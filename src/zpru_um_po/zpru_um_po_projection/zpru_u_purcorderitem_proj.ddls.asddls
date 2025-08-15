@AccessControl.authorizationCheck: #NOT_REQUIRED
@EndUserText.label: 'Order Item Projection'
@Metadata.ignorePropagatedAnnotations: true
define view entity ZPRU_U_PURCORDERITEM_PROJ 
as projection on ZPRU_U_PURCORDERITEM_TP
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
    _header_tp : redirected to parent ZPRU_U_PURCORDERHDR_PROJ
}
