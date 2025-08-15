@AccessControl.authorizationCheck: #NOT_REQUIRED
@EndUserText.label: 'Projection for ODATA Service Order'
@Metadata.ignorePropagatedAnnotations: true
@Metadata.allowExtensions: true

@ObjectModel.semanticKey: [ 'purchaseOrderId' ] 

@AbapCatalog.extensibility: {
  extensible: true,
  elementSuffix: 'ZPR',
  allowNewDatasources: false,
  dataSources: ['PurchaseOrder'],
  quota: {
    maximumFields: 500,
    maximumBytes: 50000
  },
  allowNewCompositions: true
}

define root view entity Zpru_PurcOrderHdr_ODATA_Proj
  provider contract transactional_query
  as projection on Zpru_PurcOrderHdr_tp as PurchaseOrder
{
  key purchaseOrderId,
      orderDate,
      supplierId,
      supplierName,
      @Consumption.valueHelpDefinition: [{  entity: {   name: 'ZPRU_I_BUYER' , 
                                                        element: 'buyerId'  }     }]
      buyerId,
      buyerName,
      @Semantics.amount.currencyCode : 'headerCurrency'
      totalAmount,
      headerCurrency,
      deliveryDate,
      status,
      paymentTerms,
      @Consumption.valueHelpDefinition: [{  entity: {   name: 'ZPRU_I_SHIPPING_METHOD' , 
                                                        element: 'shippingMethod'  }     }] 
      shippingMethod,
      controlTimestamp,
      createdBy,
      createOn,
      changedBy,
      changedOn,
      lastChanged,
      _text_tp.TextContent as orderDescription : localized, 
      
//      @ObjectModel.virtualElementCalculatedBy: 'ABAP:ZPRU_CL_PO_VIRT_ELEM_EXIT'
//      virtual orderDescription : abap.string( 5000 ),      
      
      /* Associations */
      _items_tp : redirected to composition child Zpru_PurcOrderItem_ODATA_Proj,
      _text_tp : redirected to composition child Zpru_PurcOrderHdr_T_PROJ
}
where
  supplierId <> 'BANSUP6' // managed instance filter
