extend view entity Zpru_PurcOrderItem_ODATA_Proj with {
  @UI: { lineItem:       [ { position: 160 } ],
         identification: [ { position: 160 } ],
         fieldGroup:     [ { qualifier: 'Fieldgroup1',
                             position: 160 } ] }
  @EndUserText.label: 'Warranty Period'    
    Item.zzwarrantyperiodmonths
}
