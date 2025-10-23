@EndUserText.label: 'Purchase Order'

@UI: { headerInfo: { typeNamePlural: 'List Report - Query Purchase Orders',
                     typeName: 'Purchase Order',
                     title: { value: 'purchaseOrderId' } } }


@ObjectModel.query.implementedBy: 'ABAP:ZPRU_CL_CE_ORDER'
define root custom entity ZPRU_CE_PURCORDERHDR_TP

{
      // Facets start

      @UI.facet        : [
            // Facet 1 - Parent (collection) for Fieldgroup 1 and Fieldgroup 2
                  { id :              'Facet1-ID',
                    type:            #COLLECTION,
                    label:           'Purchase Order Details',
                    position:        10 },

            // Facet for Fieldgroup 1 - nested inside Facet 1

                  { id :              'Fieldgroup1-ID',
                    type:            #FIELDGROUP_REFERENCE,
                    label:           'Main Order Data',
                    parentId:        'Facet1-ID',
                    targetQualifier: 'Fieldgroup1',
                    position:         10 },

            // Facet for Fieldgroup 2 - nested inside Facet 1

                  { id :              'Fieldgroup2-ID',
                    type:            #FIELDGROUP_REFERENCE,
                    label:           'Transactional Data',
                    parentId:        'Facet1-ID',
                    targetQualifier: 'Fieldgroup2',
                    position:         20 },

            // Facet for Fieldgroup 3 - nested inside Facet 1

                  { id :              'Fieldgroup3-ID',
                    type:            #FIELDGROUP_REFERENCE,
                    label:           'Administrative Data',
                    parentId:        'Facet1-ID',
                    targetQualifier: 'Fieldgroup3',
                    position:         30 },

                  {
                    purpose:  #STANDARD,
                    type:     #LINEITEM_REFERENCE,
                    label:    'Purchase Order Items',
                    position: 40,
                    targetElement: '_items_tp'
                  }
      ]

      // Facets end

      @UI.selectionField:[ { position: 10 } ]
      @UI              : { lineItem:       [ { position: 10 },
                          { type: #FOR_ACTION, dataAction: 'Summary', label: 'Summary' } ],
             identification: [ { position: 10 } ],
             fieldGroup:     [ { qualifier: 'Fieldgroup1',
                                 position: 10 } ] }
      @EndUserText.label:'Order'

  key purchaseOrderId  : zpru_de_po_id;
      @UI.selectionField:[ { position: 20 } ]
      @UI              : { lineItem:       [ { position: 20 } ],
             identification: [ { position: 20 } ],
             fieldGroup:     [ { qualifier: 'Fieldgroup1',
                                 position: 20 } ] }
      @EndUserText.label:'Order Date'
      orderDate        : abap.dats;
      @UI.selectionField:[ { position: 30 } ]
      @UI              : { lineItem:       [ { position: 30 } ],
             identification: [ { position: 30 } ],
             fieldGroup:     [ { qualifier: 'Fieldgroup1',
                                 position: 30 } ] }
      @EndUserText.label:'Supplier ID'
      supplierId       : zpru_de_supplier;
      @UI              : { lineItem:       [ { position: 40 } ],
             identification: [ { position: 40 } ],
             fieldGroup:     [ { qualifier: 'Fieldgroup1',
                                 position: 40 } ] }
      @EndUserText.label:'Supplier Name'
      supplierName     : abap.char(50);

      @Consumption.valueHelpDefinition: [{  entity: {   name: 'ZPRU_I_BUYER' , 
                                                        element: 'buyerId'  }     }]   
      @UI.selectionField:[ { position: 40 } ]
      @UI              : { lineItem:       [ { position: 50 } ],
           identification: [ { position: 50 } ],
           fieldGroup  :     [ { qualifier: 'Fieldgroup1',
                               position: 50 } ] }
      @EndUserText.label:'Buyer ID'
      buyerId          : zpru_de_buyer;
      @UI              : { lineItem:       [ { position: 60 } ],
          identification: [ { position: 60 } ],
          fieldGroup   :     [ { qualifier: 'Fieldgroup1',
                                position: 60 } ] }
      @EndUserText.label:'Buyer Name'

      buyerName        : abap.char(50);
      @UI              : { lineItem:       [ { position: 70 } ],
           identification: [ { position: 70 } ],
           fieldGroup  :     [ { qualifier: 'Fieldgroup1',
                                 position: 70 } ] }
      @EndUserText.label:'Total Amount'
      @Semantics.amount.currencyCode : 'headerCurrency'
      totalAmount      : abap.curr(15,2);
      @UI              : { lineItem:       [ { position: 80 } ],
          identification: [ { position: 80 } ],
          fieldGroup   :     [ { qualifier: 'Fieldgroup1',
                                position: 80 } ] }
      @EndUserText.label:'Currency'
      headerCurrency   : abap.cuky;
      @UI.selectionField:[ { position: 50 } ]
      @UI              : { lineItem:       [ { position: 90 } ],
             identification: [ { position: 90 } ],
            fieldGroup :     [ { qualifier: 'Fieldgroup2',
                                 position: 90 } ]  }
      @EndUserText.label:'Delivery Date'
      deliveryDate     : abap.dats;
      @UI.selectionField:[ { position: 60 } ]
      @UI              : { lineItem:       [ { position: 100 } ],
           identification: [ { position: 100 } ],
           fieldGroup  :     [ { qualifier: 'Fieldgroup2',
                                 position: 100 } ] }
      @EndUserText.label:'Order Status'
      status           : abap.char(1);
      @UI              : { lineItem:       [ { position: 110 } ],
           identification: [ { position: 110 } ],
           fieldGroup  :     [ { qualifier: 'Fieldgroup2',
                                 position: 110 } ] }
      @EndUserText.label:'Payment Terms'
      paymentTerms     : zpru_de_payment_method;
      @Consumption.valueHelpDefinition: [{  entity: {   name: 'ZPRU_I_SHIPPING_METHOD' ,
                                                        element: 'shippingMethod'  }     }]      
      @UI              : { lineItem:       [ { position: 120 } ],
             identification: [ { position: 120 } ],
             fieldGroup:     [ { qualifier: 'Fieldgroup2',
                                 position: 120 } ] }
      @EndUserText.label:'Shipping Method'
      shippingMethod   : zpru_de_shipping_meth;

      @Consumption.hidden: true
      controlTimestamp : timestampl;
      @UI              : { lineItem:       [ { position: 130 } ],
           identification: [ { position: 130 } ],
           fieldGroup  :     [ { qualifier: 'Fieldgroup3',
                                 position: 130 } ] }
      @EndUserText.label:'Created By'
      @Semantics.user.createdBy: true
      createdBy        : abp_creation_user;
      @UI              : { lineItem:       [ { position: 140 } ],
           identification: [ { position: 140 } ],
           fieldGroup  :     [ { qualifier: 'Fieldgroup3',
                                 position: 140 } ] }
      @EndUserText.label:'Created On'
      @Semantics.systemDateTime.createdAt: true
      createOn         : abp_creation_tstmpl;

      @UI              : { lineItem:       [ { position: 150 } ],
          identification: [ { position: 150 } ],
          fieldGroup   :     [ { qualifier: 'Fieldgroup3',
                                position: 150 } ] }
      @EndUserText.label:'Changed By'
      @Semantics.user.localInstanceLastChangedBy: true
      changedBy        : abp_locinst_lastchange_user;

      @UI              : { lineItem:       [ { position: 160 } ],
           identification: [ { position: 160 } ],
           fieldGroup  :     [ { qualifier: 'Fieldgroup3',
                                 position: 160 } ] }
      @EndUserText.label:'Chaned On'
      @Semantics.systemDateTime.localInstanceLastChangedAt: true
      changedOn        : abp_locinst_lastchange_tstmpl;
      
      @UI              : { lineItem:       [ { position: 170 } ],
             identification: [ { position: 170 } ],
             fieldGroup:     [ { qualifier: 'Fieldgroup1',
                                 position: 170 } ] }
      @EndUserText.label:'Summary'
      summary : abap.string;

      @Consumption.hidden: true
      @Semantics.systemDateTime.lastChangedAt: true
      lastChanged      : abp_lastchange_tstmpl;
      /* Associations */
      _items_tp        : composition of exact one to many ZPRU_CE_PURCORDER_ITEM_TP;

}
