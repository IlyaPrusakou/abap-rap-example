@AccessControl.authorizationCheck: #NOT_REQUIRED
@EndUserText.label: 'Interface for ODATA Service'
@Metadata.ignorePropagatedAnnotations: true
define root view entity Zpru_PurcOrderHdr_ODATA_Int
  provider contract transactional_interface
  as projection on Zpru_PurcOrderHdr_tp
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
      _items_tp : redirected to composition child Zpru_PurcOrderItem_ODATA_Int
}
