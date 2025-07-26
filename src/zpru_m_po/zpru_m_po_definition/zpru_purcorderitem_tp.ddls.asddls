@AbapCatalog.viewEnhancementCategory: [#NONE]
@AccessControl.authorizationCheck: #NOT_REQUIRED
@EndUserText.label: 'Purchase Order Item Transactional'
@Metadata.ignorePropagatedAnnotations: true
@ObjectModel.usageType:{
    serviceQuality: #X,
    sizeCategory: #S,
    dataClass: #MIXED
}
define view entity Zpru_PurcOrderItem_tp
  as select from Zpru_PurcOrderItem
  association to parent Zpru_PurcOrderHdr_tp as _header_tp on _header_tp.purchaseOrderId = $projection.purchaseOrderId
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
