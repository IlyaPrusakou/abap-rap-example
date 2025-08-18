@EndUserText.label: 'Purchase Order Item'

@UI: { headerInfo: { typeNamePlural: 'List Report - Purchase Orders Items',
                     typeName: 'Purchase Order Item',
                     title: { value: 'itemId' } } }

@ObjectModel.query.implementedBy: 'ABAP:ZPRU_CL_CE_ITEM'
define custom entity ZPRU_CE_PURCORDER_ITEM_TP
{
      // Facets start

      @UI.facet         : [
            // Facet 1 - Parent (collection) for Fieldgroup 1 and Fieldgroup 2
                  { id  :              'Facet1-ID',
                    type:            #COLLECTION,
                    label:           'Order Item Details',
                    position:        10 },

            // Facet for Fieldgroup 1 - nested inside Facet 1

                  { id  :              'Fieldgroup1-ID',
                    type:            #FIELDGROUP_REFERENCE,
                    label:           'Main Item Data',
                    parentId:        'Facet1-ID',
                    targetQualifier: 'Fieldgroup1',
                    position:         10 },

            // Facet for Fieldgroup 2 - nested inside Facet 1

                  { id  :              'Fieldgroup2-ID',
                    type:            #FIELDGROUP_REFERENCE,
                    label:           'Transactional Data',
                    parentId:        'Facet1-ID',
                    targetQualifier: 'Fieldgroup2',
                    position:         20 },

            // Facet for Fieldgroup 3 - nested inside Facet 1

                  { id  :              'Fieldgroup3-ID',
                    type:            #FIELDGROUP_REFERENCE,
                    label:           'Administrative Data',
                    parentId:        'Facet1-ID',
                    targetQualifier: 'Fieldgroup3',
                    position:         20 }

                  ]

      // Facets end


      @UI.selectionField: [ { position: 10 } ]
      @UI               : { lineItem:       [ { position: 10 } ],
             identification: [ { position: 10 } ],
             fieldGroup :     [ { qualifier: 'Fieldgroup1',
                                 position: 10 } ] }
      @EndUserText.label: 'Item ID'
  key itemId            : zpru_de_po_itm_id;
      @UI.selectionField: [ { position: 20 } ]
      @UI               : { lineItem:       [ { position: 20 } ],
             identification: [ { position: 20 } ],
             fieldGroup :     [ { qualifier: 'Fieldgroup1',
                                 position: 20 } ] }
      @EndUserText.label: 'Order'
  key purchaseOrderId   : zpru_de_po_id;
      @UI               : { lineItem:       [ { position: 30 } ],
             identification: [ { position: 30 } ],
             fieldGroup :     [ { qualifier: 'Fieldgroup1',
                                 position: 30 } ] }
      @EndUserText.label: 'Item Number'
      itemNumber        : abap.int4;
      @UI.selectionField: [ { position: 40 } ]
      @UI               : { lineItem:       [ { position: 40 } ],
             identification: [ { position: 40 } ],
             fieldGroup :     [ { qualifier: 'Fieldgroup1',
                                 position: 40 } ] }
      @EndUserText.label: 'Product ID'
      productId         : abap.char(10);
      @UI               : { lineItem:       [ { position: 50 } ],
             identification: [ { position: 50 } ],
             fieldGroup :     [ { qualifier: 'Fieldgroup1',
                                 position: 50 } ] }
      @EndUserText.label: 'Product Name'
      productName       : abap.char(50);
      @UI               : { lineItem:       [ { position: 60 } ],
             identification: [ { position: 60 } ],
             fieldGroup :     [ { qualifier: 'Fieldgroup2',
                                 position: 60 } ] }
      @EndUserText.label: 'Quantity'
      quantity          : abap.int4;
      @UI               : { lineItem:       [ { position: 70 } ],
         identification : [ { position: 70 } ],
         fieldGroup     :     [ { qualifier: 'Fieldgroup2',
                             position: 70 } ] }
      @EndUserText.label: 'Price'
      @Semantics.amount.currencyCode : 'itemCurrency'
      unitPrice         : abap.curr(15,2);
      @UI               : { lineItem:       [ { position: 80 } ],
       identification   : [ { position: 80 } ],
       fieldGroup       :     [ { qualifier: 'Fieldgroup2',
                           position: 80 } ] }
      @EndUserText.label: 'Total Price'
      @Semantics.amount.currencyCode : 'itemCurrency'
      totalPrice        : abap.curr(15,2);
      @UI.selectionField: [ { position: 90 } ]
      @UI               : { lineItem:       [ { position: 90 } ],
             identification: [ { position: 90 } ],
             fieldGroup :     [ { qualifier: 'Fieldgroup2',
                                 position: 90 } ] }
      @EndUserText.label: 'Delivery Date'
      deliveryDate      : abap.dats;
      @UI.selectionField: [ { position: 100 } ]
      @UI               : { lineItem:       [ { position: 100 } ],
             identification: [ { position: 100 } ],
             fieldGroup :     [ { qualifier: 'Fieldgroup2',
                                 position: 100 } ] }
      @EndUserText.label: 'Warehouse Location'
      warehouseLocation : abap.char(20);
      @UI               : { lineItem:       [ { position: 110 } ],
             identification: [ { position: 110 } ],
             fieldGroup :     [ { qualifier: 'Fieldgroup2',
                                 position: 120 } ] }
      @EndUserText.label: 'Currency'
      itemCurrency      : abap.cuky;
      @Consumption.hidden:true
      isUrgent          : boole_d;
      @UI.selectionField: [ { position: 120 } ]
      @UI               : { lineItem:       [ { position: 120 } ],
             identification: [ { position: 120 } ],
             fieldGroup :     [ { qualifier: 'Fieldgroup3',
                                 position: 120 } ] }
      @EndUserText.label: 'Create By'
      @Semantics.user.createdBy: true
      createdBy         : abp_creation_user;
      @UI.selectionField: [ { position: 130 } ]
      @UI               : { lineItem:       [ { position: 130 } ],
             identification: [ { position: 130 } ],
             fieldGroup :     [ { qualifier: 'Fieldgroup3',
                                 position: 130 } ] }
      @EndUserText.label: 'Create On'
      @Semantics.systemDateTime.createdAt: true
      createOn          : abp_creation_tstmpl;
      @UI.selectionField: [ { position: 140 } ]
      @UI               : { lineItem:       [ { position: 140 } ],
             identification: [ { position: 140 } ],
             fieldGroup :     [ { qualifier: 'Fieldgroup3',
                                 position: 140 } ] }
      @EndUserText.label: 'Changed By'
      @Semantics.user.localInstanceLastChangedBy: true
      changedBy         : abp_locinst_lastchange_user;
      @UI.selectionField: [ { position: 150 } ]
      @UI               : { lineItem:       [ { position: 150 } ],
             identification: [ { position: 150 } ],
             fieldGroup :     [ { qualifier: 'Fieldgroup3',
                                 position: 150 } ] }
      @EndUserText.label: 'Changed On'
      @Semantics.systemDateTime.localInstanceLastChangedAt: true
      changedOn         : abp_locinst_lastchange_tstmpl;
      /* Associations */
      _header_tp        : association to parent ZPRU_CE_PURCORDERHDR_TP on _header_tp.purchaseOrderId = $projection.purchaseOrderId;

}
