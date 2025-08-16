@EndUserText.label: 'Purchase Order'
@ObjectModel.query.implementedBy: 'ABAP:ZPRU_CL_CE_ORDER'
define root custom entity ZPRU_CE_PURCORDERHDR_TP

{
  key purchaseOrderId  : zpru_de_po_id;
      orderDate        : abap.dats;
      supplierId       : zpru_de_supplier;
      supplierName     : abap.char(50);
      buyerId          : zpru_de_buyer;
      buyerName        : abap.char(50);
      @Semantics.amount.currencyCode : 'headerCurrency'
      totalAmount      : abap.curr(15,2);
      headerCurrency   : abap.cuky;
      deliveryDate     : abap.dats;
      status           : abap.char(1);
      paymentTerms     : zpru_de_payment_method;
      shippingMethod   : zpru_de_shipping_meth;
      controlTimestamp : timestampl;
      @Semantics.user.createdBy: true
      createdBy        : abp_creation_user;
      @Semantics.systemDateTime.createdAt: true
      createOn         : abp_creation_tstmpl;
      @Semantics.user.localInstanceLastChangedBy: true
      changedBy        : abp_locinst_lastchange_user;
      @Semantics.systemDateTime.localInstanceLastChangedAt: true
      changedOn        : abp_locinst_lastchange_tstmpl;
      @Semantics.systemDateTime.lastChangedAt: true
      lastChanged      : abp_lastchange_tstmpl;
      /* Associations */
            _items_tp : composition of exact one to many ZPRU_CE_PURCORDER_ITEM_TP;

}
