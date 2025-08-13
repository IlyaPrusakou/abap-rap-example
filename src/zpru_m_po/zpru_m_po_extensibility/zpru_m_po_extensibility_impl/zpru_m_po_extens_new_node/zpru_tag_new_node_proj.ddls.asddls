extend view entity Zpru_PurcOrderHdr_ODATA_Proj with
{
    @UI.facet: [
      {
//        id:            'Tag',
        purpose:       #STANDARD,
        type:          #LINEITEM_REFERENCE,
        label:         'Tag',
        position:      250,
        targetElement: '_tag'
      }
    ]
  PurchaseOrder._tag : redirected to composition child ZPRU_TAG_TO_PARENT_PROJ
}
