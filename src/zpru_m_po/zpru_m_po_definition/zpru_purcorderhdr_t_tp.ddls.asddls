@AbapCatalog.viewEnhancementCategory: [#NONE]
@AccessControl.authorizationCheck: #NOT_REQUIRED
@EndUserText.label: 'Purchase Order Text'
@Metadata.ignorePropagatedAnnotations: true
@ObjectModel.usageType:{
    serviceQuality: #X,
    sizeCategory: #S,
    dataClass: #MIXED
}
define view entity Zpru_PurcOrderHdr_T_TP
  as select from Zpru_PurcOrderHdr_T
  association to parent Zpru_PurcOrderHdr_tp as _header_tp on _header_tp.purchaseOrderId = $projection.PurchaseOrderId
{
  key PurchaseOrderId,
  key Language,
      TextContent,
      _header_tp
}
