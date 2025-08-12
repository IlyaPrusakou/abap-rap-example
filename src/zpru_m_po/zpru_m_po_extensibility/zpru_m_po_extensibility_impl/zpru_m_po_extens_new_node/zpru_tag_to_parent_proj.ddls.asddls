@AccessControl.authorizationCheck: #NOT_REQUIRED
@EndUserText.label: 'Interface Tag To Parent Association'
@Metadata.allowExtensions: true
@ObjectModel.semanticKey: ['PurchaseOrderId', 'TagId']


define view entity ZPRU_TAG_TO_PARENT_PROJ
  as projection on ZPRU_TAG_TO_PARENT_TP
{
  key PurchaseOrderId,
  key TagId,
      TagText,
      CreatedBy,
      CreateOn,
      ChangedBy,
      ChangedOn,
      /* Associations */
      _header_tp : redirected to parent Zpru_PurcOrderHdr_ODATA_Proj  
}
