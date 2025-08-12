@AbapCatalog.viewEnhancementCategory: [#NONE]
@AccessControl.authorizationCheck: #NOT_REQUIRED
@EndUserText.label: 'Purchase Order Tag'
@Metadata.ignorePropagatedAnnotations: true
@ObjectModel.usageType:{
    serviceQuality: #X,
    sizeCategory: #S,
    dataClass: #MIXED
}
define view entity ZPRU_I_TAG
  as select from zpru_order_tag
{
  key purchase_order_id as PurchaseOrderId,
  key tag_id            as TagId,
      tag_text          as TagText,
      created_by        as CreatedBy,
      create_on         as CreateOn,
      changed_by        as ChangedBy,
      changed_on        as ChangedOn
}
