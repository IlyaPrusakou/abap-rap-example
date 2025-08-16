@EndUserText.label: 'Purchase Order Item'
@ObjectModel.query.implementedBy: 'ABAP:ZPRU_CL_CE_ITEM'
define custom entity ZPRU_CE_PURCORDER_ITEM_TP
{
  key itemId            : zpru_de_po_itm_id;
  key purchaseOrderId   : zpru_de_po_id;
      itemNumber        : abap.int4;
      productId         : abap.char(10);
      productName       : abap.char(50);
      quantity          : abap.int4;
      @Semantics.amount.currencyCode : 'itemCurrency'
      unitPrice         : abap.curr(15,2);
      @Semantics.amount.currencyCode : 'itemCurrency'
      totalPrice        : abap.curr(15,2);
      deliveryDate      : abap.dats;
      warehouseLocation : abap.char(20);
      itemCurrency      : abap.cuky;
      isUrgent          : boole_d;
      @Semantics.user.createdBy: true
      createdBy         : abp_creation_user;
      @Semantics.systemDateTime.createdAt: true
      createOn          : abp_creation_tstmpl;
      @Semantics.user.localInstanceLastChangedBy: true
      changedBy         : abp_locinst_lastchange_user;
      @Semantics.systemDateTime.localInstanceLastChangedAt: true
      changedOn         : abp_locinst_lastchange_tstmpl;
      /* Associations */
      _header_tp        : association to parent ZPRU_CE_PURCORDERHDR_TP on  _header_tp.purchaseOrderId = $projection.purchaseOrderId;

}
