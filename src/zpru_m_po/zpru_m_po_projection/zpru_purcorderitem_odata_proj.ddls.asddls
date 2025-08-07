@AccessControl.authorizationCheck: #NOT_REQUIRED
@EndUserText.label: 'Projection for ODATA Service Items'
@Metadata.ignorePropagatedAnnotations: true
@Metadata.allowExtensions: true

@ObjectModel.semanticKey: [ 'itemId', 'purchaseOrderId' ]

@AbapCatalog.extensibility: {
  extensible: true,
  elementSuffix: 'ZPU',
  allowNewDatasources: false,
  dataSources: ['Item'],
  quota: {
    maximumFields: 500,
    maximumBytes: 50000
  },
  allowNewCompositions: true
}

define view entity Zpru_PurcOrderItem_ODATA_Proj 
as projection on Zpru_PurcOrderItem_tp as Item
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
    
    @ObjectModel.virtualElementCalculatedBy: 'ABAP:ZPRU_CL_ITM_VIRT_ELEM_EXIT'
    virtual isWarehouseLocationHidden : boole_d,
    
    
    /* Associations */
    _header_tp : redirected to parent Zpru_PurcOrderHdr_ODATA_Proj
}
