@AbapCatalog.viewEnhancementCategory: [#NONE]
@AccessControl.authorizationCheck: #NOT_REQUIRED
@EndUserText.label: 'Shipping Method'
@Metadata.ignorePropagatedAnnotations: true
@ObjectModel.usageType:{
    serviceQuality: #X,
    sizeCategory: #S,
    dataClass: #MIXED
}
define root view entity zpru_i_shipping_method 
as select from dd07l
  composition [0..*] of zpru_i_shipping_method_t as _Text
{
      @ObjectModel.text.association: '_Text'
  key cast( domvalue_l as zpru_de_shipping_meth ) as shippingMethod,
      @Consumption.hidden: true
      @Search:{
        defaultSearchElement: true,
        fuzzinessThreshold: 0.8,
        ranking: #HIGH }
      domvalue_l                              as DomainValue,
      _Text
}
where
      dd07l.domname  = 'ZPRU_DO_SHIPPING_METH'
  and dd07l.as4local = 'A'
  and dd07l.as4vers  = '0000'
