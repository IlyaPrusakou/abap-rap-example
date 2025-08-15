@AbapCatalog.viewEnhancementCategory: [#NONE]
@AccessControl.authorizationCheck: #NOT_REQUIRED
@EndUserText.label: 'Buyers'
@Metadata.ignorePropagatedAnnotations: true
@ObjectModel.usageType:{
    serviceQuality: #X,
    sizeCategory: #S,
    dataClass: #MIXED
}
define root view entity ZPRU_I_BUYER
  as select from zpru_buyers
  composition [0..*] of ZPRU_I_BUYER_T as _Text
{
      @Search:{
      defaultSearchElement: true,
      fuzzinessThreshold: 0.8,
      ranking: #HIGH }
      @ObjectModel.text.association: '_Text'
  key buyer as buyerId,
      _Text
}
