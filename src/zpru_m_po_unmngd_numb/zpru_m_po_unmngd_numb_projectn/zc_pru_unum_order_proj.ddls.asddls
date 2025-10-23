@AccessControl.authorizationCheck: #NOT_REQUIRED
@Metadata.allowExtensions: true
@EndUserText.label: 'Projection View for ZR_PRU_UNUM_ORDER_TP'
@ObjectModel.semanticKey: [ 'PurchaseOrderID' ]
define root view entity ZC_PRU_UNUM_ORDER_PROJ
  provider contract transactional_query
  as projection on ZR_PRU_UNUM_ORDER_TP
{
  key purchaseOrderId,
  orderDate,
  supplierId,
  supplierName,
  buyerId,
  buyerName,
  totalAmount,
  headerCurrency,
  deliveryDate,
  status,
  paymentTerms,
  shippingMethod,
  controlTimestamp,
  origin,
  changedOn,
  _itemsUn : redirected to composition child ZC_PRU_UNUM_ITEM_PROJ,
  _textUn  : redirected to composition child ZC_PRU_UNUM_TEXT_PROJ  
}
