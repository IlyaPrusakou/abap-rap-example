@AbapCatalog.viewEnhancementCategory: [#NONE]
@AccessControl.authorizationCheck: #NOT_REQUIRED
@EndUserText.label: 'Purchase Order Item'
@Metadata.ignorePropagatedAnnotations: true
@ObjectModel.usageType:{
    serviceQuality: #X,
    sizeCategory: #S,
    dataClass: #MIXED
}

define view entity Zpru_PurcOrderItem
  as select from zpru_po_item
  association [1..1] to Zpru_PurcOrderHdr    as _header    on  $projection.purchaseOrderId = _header.purchaseOrderId
{
  key item_id            as itemId,
  key purchase_order_id  as purchaseOrderId,
      item_number        as itemNumber,
      product_id         as productId,
      product_name       as productName,
      quantity           as quantity,
      @Semantics.amount.currencyCode : 'itemCurrency'
      unit_price         as unitPrice,
      @Semantics.amount.currencyCode : 'itemCurrency'
      total_price        as totalPrice,
      delivery_date      as deliveryDate,
      warehouse_location as warehouseLocation,
      item_currency      as itemCurrency,
      is_urgent          as isUrgent,
      created_by         as createdBy,
      create_on          as createOn,
      changed_by         as changedBy,
      changed_on         as changedOn,
      _header // Association to Header Table
}
