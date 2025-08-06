@AbapCatalog.viewEnhancementCategory: [#PROJECTION_LIST]
@AccessControl.authorizationCheck: #NOT_REQUIRED
@EndUserText.label: 'Purchase Order Transactional'
@Metadata.ignorePropagatedAnnotations: true
@ObjectModel.usageType:{
    serviceQuality: #X,
    sizeCategory: #S,
    dataClass: #MIXED
}

@AbapCatalog.extensibility: {
  extensible: true,
  elementSuffix: 'ZPR',
  allowNewDatasources: false,
  dataSources: ['_Extension'],
  quota: {
    maximumFields: 500,
    maximumBytes: 50000
  }
}

define root view entity Zpru_PurcOrderHdr_tp
  as select from Zpru_PurcOrderHdr as PurchaseOrder
  composition of exact one to many Zpru_PurcOrderItem_tp as _items_tp
    association [1]    to Zpru_PurcOrderHdr_E as _Extension on $projection.purchaseOrderId = _Extension.purchaseOrderId
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
      @Semantics.user.createdBy: true
      createdBy,
      @Semantics.systemDateTime.createdAt: true
      createOn,
      @Semantics.user.localInstanceLastChangedBy: true
      changedBy,
      @Semantics.systemDateTime.localInstanceLastChangedAt: true
      changedOn,
      @Semantics.systemDateTime.lastChangedAt: true
      lastChanged,
      /* Associations */
      _items_tp
}
