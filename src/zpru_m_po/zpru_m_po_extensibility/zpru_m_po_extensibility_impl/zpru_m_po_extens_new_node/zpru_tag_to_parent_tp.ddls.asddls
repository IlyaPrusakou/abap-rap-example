@AbapCatalog.viewEnhancementCategory: [#NONE]
@AccessControl.authorizationCheck: #NOT_REQUIRED
@EndUserText.label: 'Tag To Parent Association'
@Metadata.ignorePropagatedAnnotations: true
@ObjectModel.usageType:{
    serviceQuality: #X,
    sizeCategory: #S,
    dataClass: #MIXED
}
define view entity ZPRU_TAG_TO_PARENT_TP
  as select from ZPRU_I_TAG_COMPOSITE
    association to parent Zpru_PurcOrderHdr_tp as _header_tp on _header_tp.purchaseOrderId = $projection.PurchaseOrderId
{
  key PurchaseOrderId,
  key TagId,
      TagText,
      @Semantics.user.createdBy: true      
      CreatedBy,
      @Semantics.systemDateTime.createdAt: true
      CreateOn,
      @Semantics.user.localInstanceLastChangedBy: true
      ChangedBy,
      @Semantics.systemDateTime.localInstanceLastChangedAt: true
      ChangedOn,
      _header_tp
}
