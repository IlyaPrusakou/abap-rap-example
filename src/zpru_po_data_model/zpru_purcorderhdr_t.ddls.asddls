@AbapCatalog.viewEnhancementCategory: [#NONE]
@AccessControl.authorizationCheck: #NOT_REQUIRED
@EndUserText.label: 'Purchase Order Text'
@Metadata.ignorePropagatedAnnotations: true
@ObjectModel.usageType:{
    serviceQuality: #X,
    sizeCategory: #S,
    dataClass: #MIXED
}
define view entity Zpru_PurcOrderHdr_T
  as select from zpru_purc_ordert
  association of many to one Zpru_PurcOrderHdr as _order on _order.purchaseOrderId = $projection.PurchaseOrderId
{
  key purchase_order_id as PurchaseOrderId,
  key language          as Language,
      text_content      as TextContent,
      _order
}
