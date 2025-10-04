@AccessControl.authorizationCheck: #NOT_REQUIRED
@EndUserText.label: 'Projection for ODATA Service Items'
@Metadata.ignorePropagatedAnnotations: true
@Metadata.allowExtensions: true

@ObjectModel.semanticKey: [ 'itemId', 'purchaseOrderId' ]

@AbapCatalog.extensibility: {
  extensible: true,
  elementSuffix: 'ZPM',
  allowNewDatasources: false,
  dataSources: ['Item'],
  quota: {
    maximumFields: 500,
    maximumBytes: 50000
  },
  allowNewCompositions: true
}

define view entity ZPRU_RO_PURCORDERITEM_PROJ 
as projection on ZPRU_RO_PURCORDERITEM_TP as Item
{
    key itemId,
    key purchaseOrderId,
    itemNumber,
    productId,
    productName,
    quantity,
    @Semantics.amount.currencyCode : 'itemCurrency'
    unitPrice,
    @Semantics.amount.currencyCode : 'itemCurrency'
    totalPrice,
    deliveryDate,
    warehouseLocation,
    itemCurrency,
    isUrgent,
    createdBy,
    createOn,
    changedBy,
    changedOn,
    
    /* Associations */
    _header_tp : redirected to parent ZPRU_RO_PURCORDERHDR_PROJ
}
