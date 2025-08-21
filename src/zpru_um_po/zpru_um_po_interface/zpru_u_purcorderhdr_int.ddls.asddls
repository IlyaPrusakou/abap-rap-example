@AccessControl.authorizationCheck: #NOT_REQUIRED
@EndUserText.label: 'Purchase Order'
@Metadata.ignorePropagatedAnnotations: true
define root view entity ZPRU_U_PURCORDERHDR_INT
provider contract transactional_interface 
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
    _items_tp : redirected to composition child ZPRU_U_PURCORDERITEM_INT
}
