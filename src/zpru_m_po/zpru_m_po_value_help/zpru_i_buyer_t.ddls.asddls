@AbapCatalog.viewEnhancementCategory: [#NONE]
@AccessControl.authorizationCheck: #NOT_REQUIRED
@EndUserText.label: 'Buyers Text'
@Metadata.ignorePropagatedAnnotations: true
@ObjectModel.usageType:{
    serviceQuality: #X,
    sizeCategory: #S,
    dataClass: #MIXED
}
define view entity ZPRU_I_BUYER_T
  as select from zpru_buyers_t
  association        to parent ZPRU_I_BUYER as _buyer    on $projection.buyerId = _buyer.buyerId
  association [0..1] to I_Language          as _Language on $projection.Language = _Language.Language
{
      @ObjectModel:{
      foreignKey.association: '_buyer',
      text.element: ['Description'] }
  key buyer       as buyerId,
      @ObjectModel.foreignKey.association: '_Language'
      @Semantics.language: true
  key spras       as Language,
      @Semantics.text: true
      description as Description,
      _buyer,
      _Language
}
