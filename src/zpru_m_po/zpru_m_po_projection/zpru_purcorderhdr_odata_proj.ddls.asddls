@AccessControl.authorizationCheck: #NOT_REQUIRED
@EndUserText.label: 'Projection for ODATA Service Order'
@Metadata.ignorePropagatedAnnotations: true
define root view entity Zpru_PurcOrderHdr_ODATA_Proj
  provider contract transactional_query
  as projection on Zpru_PurcOrderHdr_ODATA_Int
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
      
      virtual isShippingMethodHidden : boole_d,
      
      
      
      /* Associations */
      _items_tp : redirected to composition child Zpru_PurcOrderItem_ODATA_Proj
}
