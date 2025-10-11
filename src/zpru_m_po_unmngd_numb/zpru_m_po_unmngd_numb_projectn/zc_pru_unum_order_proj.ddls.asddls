@AccessControl.authorizationCheck: #NOT_REQUIRED
@Metadata.allowExtensions: true
@EndUserText.label: 'Projection View for ZR_PRU_UNUM_ORDER_TP'
@ObjectModel.semanticKey: [ 'PurchaseOrderID' ]
define root view entity ZC_PRU_UNUM_ORDER_PROJ
  provider contract transactional_query
  as projection on ZR_PRU_UNUM_ORDER_TP
{
  key PurchaseOrderID,
  OrderDate,
  SupplierID,
  SupplierName,
  BuyerID,
  BuyerName,
  TotalAmount,
  HeaderCurrency,
  DeliveryDate,
  Status,
  PaymentTerms,
  ShippingMethod,
  ControlTimestamp,
  Origin,
  ChangedOn  
}
