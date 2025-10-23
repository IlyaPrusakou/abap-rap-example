@AccessControl.authorizationCheck: #NOT_REQUIRED
@EndUserText.label: 'Projection for ODATA Service Items'
@Metadata.ignorePropagatedAnnotations: true
@Metadata.allowExtensions: true

@ObjectModel.semanticKey: [ 'itemId', 'purchaseOrderId' ]

//@AbapCatalog.extensibility: {
//  extensible: true,
//  elementSuffix: 'ZPU',
//  allowNewDatasources: false,
//  dataSources: ['Item'],
//  quota: {
//    maximumFields: 500,
//    maximumBytes: 50000
//  },
//  allowNewCompositions: true
//}

define view entity ZC_PRU_UNUM_ITEM_PROJ 
as projection on ZR_PRU_UNUM_ITEM_TP as Item
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
    _OrderUn : redirected to parent ZC_PRU_UNUM_ORDER_PROJ
}
