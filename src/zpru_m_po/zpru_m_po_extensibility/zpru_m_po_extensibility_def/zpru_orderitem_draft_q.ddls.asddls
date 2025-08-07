@AccessControl.authorizationCheck: #NOT_REQUIRED
@EndUserText.label: 'Draft Query for Order Item'

@AbapCatalog.extensibility: {
  extensible: true,
  elementSuffix: 'ZPU',
  allowNewDatasources: false,
  dataSources: ['Item'],
  quota: {
    maximumFields: 500,
    maximumBytes: 50000
  }
}

define view entity ZPRU_ORDERITEM_DRAFT_Q
  as select from zpru_poitm_draft as Item
{
  key itemid                        as itemid,
  key purchaseorderid               as purchaseorderid,
  key draftuuid                     as draftuuid,
      parentdraftuuid               as parentdraftuuid,
      itemnumber                    as itemnumber,
      productid                     as productid,
      productname                   as productname,
      quantity                      as quantity,
      @Semantics.amount.currencyCode : 'itemcurrency'
      unitprice                     as unitprice,
      @Semantics.amount.currencyCode : 'itemcurrency'
      totalprice                    as totalprice,
      deliverydate                  as deliverydate,
      warehouselocation             as warehouselocation,
      itemcurrency                  as itemcurrency,
      isurgent                      as isurgent,
      createdby                     as createdby,
      createon                      as createon,
      changedby                     as changedby,
      changedon                     as changedon,
      draftentitycreationdatetime   as draftentitycreationdatetime,
      draftentitylastchangedatetime as draftentitylastchangedatetime,
      draftadministrativedatauuid   as draftadministrativedatauuid,
      draftentityoperationcode      as draftentityoperationcode,
      hasactiveentity               as hasactiveentity,
      draftfieldchanges             as draftfieldchanges
}
