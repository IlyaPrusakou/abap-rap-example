extend view entity Zpru_PurcOrderHdr_ODATA_Proj with {
  @UI: { lineItem:       [ { position: 170 } ],
         identification: [ { position: 170 } ],
         fieldGroup:     [ { qualifier: 'Fieldgroup2',
                             position: 170 } ] }
  @EndUserText.label: 'Attached Document'    
    PurchaseOrder.zzdocumentattachmentid
}
