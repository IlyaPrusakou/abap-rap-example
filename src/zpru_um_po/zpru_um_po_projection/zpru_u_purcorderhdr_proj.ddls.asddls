@AccessControl.authorizationCheck: #NOT_REQUIRED
@EndUserText.label: 'Order Projection'
@Metadata.ignorePropagatedAnnotations: true
@Metadata.allowExtensions: true
define root view entity ZPRU_U_PURCORDERHDR_PROJ
provider contract transactional_query 
as projection on ZPRU_U_PURCORDERHDR_TP
{
    key purchaseOrderId,
    orderDate,
    supplierId,
    supplierName,
    buyerId,
    buyerName,
    @Semantics.amount.currencyCode : 'headerCurrency'
    totalAmount,
    headerCurrency,
    deliveryDate,
    status,
    paymentTerms,
    shippingMethod,
    controlTimestamp,
    createdBy,
    createOn,
    changedBy,
    changedOn,
    lastChanged,
    /* Associations */
    _items_tp : redirected to composition child ZPRU_U_PURCORDERITEM_PROJ
}
