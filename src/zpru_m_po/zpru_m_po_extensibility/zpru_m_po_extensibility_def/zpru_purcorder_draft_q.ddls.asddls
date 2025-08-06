@AccessControl.authorizationCheck: #NOT_REQUIRED
@EndUserText.label: 'Draft Query for Order'

@AbapCatalog.extensibility: {
  extensible: true,
  elementSuffix: 'ZPR',
  allowNewDatasources: false,
  dataSources: ['PurchaseOrder'],
  quota: {
    maximumFields: 500,
    maximumBytes: 50000
  }
}

define view entity ZPRU_PURCORDER_DRAFT_Q
  as select from zpru_po_draft as PurchaseOrder
{
  key purchaseorderid               as purchaseorderid,
  key draftuuid                     as draftuuid,
      orderdate                     as orderdate,
      supplierid                    as supplierid,
      suppliername                  as suppliername,
      buyerid                       as buyerid,
      buyername                     as buyername,
      totalamount                   as totalamount,
      headercurrency                as headercurrency,
      deliverydate                  as deliverydate,
      status                        as status,
      paymentterms                  as paymentterms,
      shippingmethod                as shippingmethod,
      controltimestamp              as controltimestamp,
      createdby                     as createdby,
      createon                      as createon,
      changedby                     as changedby,
      changedon                     as changedon,
      lastchanged                   as lastchanged,
      draftentitycreationdatetime   as draftentitycreationdatetime,
      draftentitylastchangedatetime as draftentitylastchangedatetime,
      draftadministrativedatauuid   as draftadministrativedatauuid,
      draftentityoperationcode      as draftentityoperationcode,
      hasactiveentity               as hasactiveentity,
      draftfieldchanges             as draftfieldchanges
}
