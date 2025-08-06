@AbapCatalog.viewEnhancementCategory: [#PROJECTION_LIST]
@AccessControl.authorizationCheck: #NOT_REQUIRED
@EndUserText.label: 'Extension View Order'
@AbapCatalog.extensibility: {
  extensible: true,
  elementSuffix: 'ZPR',
  allowNewDatasources: false,
  dataSources: ['PurchaseOrder'],
  quota: {
    maximumFields: 500,
    maximumBytes: 50000
  }
}
define view entity Zpru_PurcOrderHdr_E 
as select from zpru_purc_order as PurchaseOrder
{
    key purchase_order_id as purchaseOrderId
}
