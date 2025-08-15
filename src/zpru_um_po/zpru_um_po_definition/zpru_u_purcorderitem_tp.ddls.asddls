@AbapCatalog.viewEnhancementCategory: [#PROJECTION_LIST]
@AccessControl.authorizationCheck: #NOT_REQUIRED
@EndUserText.label: 'Purchase Order Item Transactional'
@Metadata.ignorePropagatedAnnotations: true
@ObjectModel.usageType:{
    serviceQuality: #X,
    sizeCategory: #S,
    dataClass: #MIXED
}

define view entity ZPRU_U_PURCORDERITEM_TP
  as select from Zpru_PurcOrderItem as Item
  association to parent ZPRU_U_PURCORDERHDR_TP as _header_tp on _header_tp.purchaseOrderId = $projection.purchaseOrderId
  
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
      @Semantics.user.createdBy: true
      createdBy,
      @Semantics.systemDateTime.createdAt: true
      createOn,
      @Semantics.user.localInstanceLastChangedBy: true
      changedBy,
      @Semantics.systemDateTime.localInstanceLastChangedAt: true
      changedOn,
      /* Associations */
      _header_tp
}
