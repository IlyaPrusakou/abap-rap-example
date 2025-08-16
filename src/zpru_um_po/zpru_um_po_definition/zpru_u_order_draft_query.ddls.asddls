@AbapCatalog.viewEnhancementCategory: [#NONE]
@AccessControl.authorizationCheck: #NOT_REQUIRED
@EndUserText.label: 'Order Draft Query'
@Metadata.ignorePropagatedAnnotations: true
@ObjectModel.usageType:{
    serviceQuality: #X,
    sizeCategory: #S,
    dataClass: #MIXED
}
define view entity zpru_u_order_draft_query
  as select from zpru_upo_draft as PurchaseOrder
{
  key purchaseorderid               as Purchaseorderid,
      orderdate                     as Orderdate,
      supplierid                    as Supplierid,
      suppliername                  as Suppliername,
      buyerid                       as Buyerid,
      buyername                     as Buyername,
      @Semantics.amount.currencyCode : 'headerCurrency'
      totalamount                   as Totalamount,
      headercurrency                as Headercurrency,
      deliverydate                  as Deliverydate,
      status                        as Status,
      paymentterms                  as Paymentterms,
      shippingmethod                as Shippingmethod,
      controltimestamp              as Controltimestamp,
      createdby                     as Createdby,
      createon                      as Createon,
      changedby                     as Changedby,
      changedon                     as Changedon,
      lastchanged                   as Lastchanged,
      draftentitycreationdatetime   as Draftentitycreationdatetime,
      draftentitylastchangedatetime as Draftentitylastchangedatetime,
      draftadministrativedatauuid   as Draftadministrativedatauuid,
      draftentityoperationcode      as Draftentityoperationcode,
      hasactiveentity               as Hasactiveentity,
      draftfieldchanges             as Draftfieldchanges
}
