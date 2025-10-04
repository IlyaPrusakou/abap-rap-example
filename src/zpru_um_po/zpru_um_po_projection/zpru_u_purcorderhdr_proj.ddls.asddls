@AccessControl.authorizationCheck: #NOT_REQUIRED
@EndUserText.label: 'Order Projection'
@Metadata.ignorePropagatedAnnotations: true
@Metadata.allowExtensions: true
define root view entity ZPRU_U_PURCORDERHDR_PROJ
  provider contract transactional_query
  as projection on ZPRU_U_PURCORDERHDR_TP
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
      origin,
           @ObjectModel.virtualElementCalculatedBy: 'ABAP:ZPRU_CL_U_PO_VIRT_ELEM'
  virtual BusinessObjectSource : abap.char( 30 ),      
      createdBy,
      createOn,
      changedBy,
      changedOn,
      lastChanged,
      /* Associations */
      _items_tp : redirected to composition child ZPRU_U_PURCORDERITEM_PROJ
}
