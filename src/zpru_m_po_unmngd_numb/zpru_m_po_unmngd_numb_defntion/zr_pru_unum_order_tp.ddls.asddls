@AccessControl.authorizationCheck: #NOT_REQUIRED
@EndUserText.label: '##GENERATED ZPRU_PURC_ORDER'
define root view entity ZR_PRU_UNUM_ORDER_TP
  as select from Zpru_PurcOrderHdr as OrderUn
  composition of exact one to many ZR_PRU_UNUM_ITEM_TP  as _itemsUn
  composition of exact one to many ZR_PRU_UNUM_TEXT_TP as _textUn
{
  key purchaseOrderId,
      orderDate,
      supplierId,
      supplierName,
      buyerId,
      buyerName,
      @Semantics.amount.currencyCode: 'HeaderCurrency'
      totalAmount,
      headerCurrency,
      deliveryDate,
      status,
      paymentTerms,
      shippingMethod,
      controlTimestamp,
      origin,
      @Semantics.user.createdBy: true
      createdBy,
      @Semantics.systemDateTime.createdAt: true
      createOn,
      @Semantics.user.localInstanceLastChangedBy: true
      changedBy,
      @Semantics.systemDateTime.localInstanceLastChangedAt: true
      changedOn,
      @Semantics.systemDateTime.lastChangedAt: true
      lastChanged,
      _itemsUn,
      _textUn
}
