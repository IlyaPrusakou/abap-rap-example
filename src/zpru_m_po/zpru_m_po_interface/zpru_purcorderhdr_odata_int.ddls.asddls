@AccessControl.authorizationCheck: #NOT_REQUIRED
@EndUserText.label: 'Interface for ODATA Service'
@Metadata.ignorePropagatedAnnotations: true

@AbapCatalog.extensibility: {
  extensible: true,
  elementSuffix: 'ZPR',
  allowNewDatasources: false,
  dataSources: ['PurchaseOrder'],
  quota: {
    maximumFields: 500,
    maximumBytes: 50000
  },
  allowNewCompositions: true
}

define root view entity Zpru_PurcOrderHdr_ODATA_Int
  provider contract transactional_interface
  as projection on Zpru_PurcOrderHdr_tp as PurchaseOrder
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
      origin,
      createdBy,
      createOn,
      changedBy,
      changedOn,
      lastChanged,
      /* Associations */
      _items_tp : redirected to composition child Zpru_PurcOrderItem_ODATA_Int
}
where
  supplierId <> 'BANSUP5' // managed instance filter
