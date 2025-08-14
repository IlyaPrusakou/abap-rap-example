@AbapCatalog.viewEnhancementCategory: [#NONE]
@AccessControl.authorizationCheck: #NOT_REQUIRED
@EndUserText.label: 'Shipping Method Text'
@Metadata.ignorePropagatedAnnotations: true
@ObjectModel.usageType:{
    serviceQuality: #X,
    sizeCategory: #S,
    dataClass: #MIXED
}
define view entity zpru_i_shipping_method_t 
  as select from dd07t
  association to parent zpru_i_shipping_method as _shippingMethod on $projection.shippingMethod = _shippingMethod.shippingMethod
  association [0..1] to I_Language              as _Language on $projection.Language = _Language.Language
{
      @ObjectModel.foreignKey.association: '_Language'
      @Semantics.language: true
  key cast( dd07t.ddlanguage as spras preserving type ) as Language,
      @ObjectModel:{
        foreignKey.association: '_shippingMethod',
        text.element: ['Description'] }
  key cast( dd07t.domvalue_l as zpru_de_shipping_meth )     as shippingMethod,
      @Consumption.hidden: true
      dd07t.domvalue_l                                  as DomainValue,
      @Search:{
        defaultSearchElement: true,
        fuzzinessThreshold: 0.8,
        ranking: #HIGH }
      @Semantics.text: true
      dd07t.ddtext                                      as Description,
      _shippingMethod,
      _Language
}
where
      dd07t.domname  = 'ZPRU_DO_SHIPPING_METH'
  and dd07t.as4local = 'A'
  and dd07t.as4vers  = '0000'
