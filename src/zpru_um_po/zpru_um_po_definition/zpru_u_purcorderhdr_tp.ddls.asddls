@AbapCatalog.viewEnhancementCategory: [#PROJECTION_LIST]
@AccessControl.authorizationCheck: #NOT_REQUIRED
@EndUserText.label: 'Purchase Order Transactional'
@Metadata.ignorePropagatedAnnotations: true
@ObjectModel.usageType:{
    serviceQuality: #X,
    sizeCategory: #S,
    dataClass: #MIXED
}

define root view entity ZPRU_U_PURCORDERHDR_TP
  as select from Zpru_PurcOrderHdr as PurchaseOrder
  composition of exact one to many ZPRU_U_PURCORDERITEM_TP  as _items_tp
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
