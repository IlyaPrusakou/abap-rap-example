@AccessControl.authorizationCheck: #NOT_REQUIRED
@EndUserText.label: 'Projection for ODATA Service Order'
@Metadata.ignorePropagatedAnnotations: true
@Metadata.allowExtensions: true

@ObjectModel.semanticKey: [ 'purchaseOrderId' ]

@AbapCatalog.extensibility: {
  extensible: true,
  elementSuffix: 'ZPN',
  allowNewDatasources: false,
  dataSources: ['PurchaseOrder'],
  quota: {
    maximumFields: 500,
    maximumBytes: 50000
  },
  allowNewCompositions: true
}

define root view entity ZPRU_RO_PURCORDERHDR_PROJ
  provider contract transactional_query
  as projection on ZPRU_RO_PURCORDERHDR_TP as PurchaseOrder
{
  key     purchaseOrderId,
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
          origin,
           @ObjectModel.virtualElementCalculatedBy: 'ABAP:ZPRU_CL_M_PO_VIRT_ELEM'
  virtual BusinessObjectSource : abap.char( 30 ),
          createdBy,
          createOn,
          changedBy,
          changedOn,
          lastChanged,
          _text_tp.TextContent as orderDescription : localized,

          /* Associations */
          _items_tp : redirected to composition child ZPRU_RO_PURCORDERITEM_PROJ,
          _text_tp  : redirected to composition child ZPRU_RO_PURCORDERHDR_T_PROJ
}
where
  supplierId <> 'BANSUP6' // managed instance filter
