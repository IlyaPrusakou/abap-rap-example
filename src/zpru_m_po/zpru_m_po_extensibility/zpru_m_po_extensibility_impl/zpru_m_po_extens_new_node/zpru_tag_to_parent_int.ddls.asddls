@AccessControl.authorizationCheck: #NOT_REQUIRED
@EndUserText.label: 'Interface Tag To Parent Association'
@Metadata.ignorePropagatedAnnotations: true
define view entity ZPRU_TAG_TO_PARENT_INT
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
      _header_tp : redirected to parent Zpru_PurcOrderHdr_ODATA_Int  
}
