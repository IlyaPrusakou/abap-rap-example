@AbapCatalog.viewEnhancementCategory: [#NONE]
@AccessControl.authorizationCheck: #NOT_REQUIRED
@EndUserText.label: 'Purchase Order Tag Transactional'
@Metadata.ignorePropagatedAnnotations: true
@ObjectModel.usageType:{
    serviceQuality: #X,
    sizeCategory: #S,
    dataClass: #MIXED
}
define view entity ZPRU_I_TAG_COMPOSITE
  as select from ZPRU_I_TAG
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
      ChangedOn
}
