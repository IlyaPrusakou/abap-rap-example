@AbapCatalog.viewEnhancementCategory: [#PROJECTION_LIST]
@AccessControl.authorizationCheck: #NOT_REQUIRED
@EndUserText.label: 'Extension View Items'
@AbapCatalog.extensibility: {
  extensible: true,
  elementSuffix: 'ZPU',
  allowNewDatasources: false,
  dataSources: ['Item'],
  quota: {
    maximumFields: 500,
    maximumBytes: 50000
  }
}
define view entity Zpru_PurcOrderItem_E
  as select from zpru_po_item as Item
{
  key item_id           as itemId,
  key purchase_order_id as purchaseOrderId
}
