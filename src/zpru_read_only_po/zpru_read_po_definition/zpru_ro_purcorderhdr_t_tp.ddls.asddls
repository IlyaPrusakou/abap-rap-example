@AbapCatalog.viewEnhancementCategory: [#NONE]
@AccessControl.authorizationCheck: #NOT_REQUIRED
@EndUserText.label: 'Purchase Order Text'
@Metadata.ignorePropagatedAnnotations: true
@ObjectModel.usageType:{
    serviceQuality: #X,
    sizeCategory: #S,
    dataClass: #MIXED
}
define view entity ZPRU_RO_PURCORDERHDR_T_TP
  as select from Zpru_PurcOrderHdr_T
  association to parent ZPRU_RO_PURCORDERHDR_TP as _header_tp on _header_tp.purchaseOrderId = $projection.PurchaseOrderId
{
  key PurchaseOrderId,
  key Language,
      TextContent,
      _header_tp
}
