@EndUserText.label: 'Purchase Order Abstract'
define root abstract entity Zpru_PurcOrderHdr_Abstract
{
  key purchaseOrderId2 : zpru_de_po_id;
      orderDate2       : abap.dats(8);
      supplierId2      : abap.char(10);
      supplierName2    : abap.char(50);
      buyerId2         : abap.char(10);
      buyerName2       : abap.char(50);
      @Semantics.amount.currencyCode : 'headerCurrency2'
      totalAmount2     : abap.curr(15,2);
      headerCurrency2  : abap.cuky(5);
      deliveryDate2    : abap.dats(8);
      status2          : abap.char(1);
      paymentTerms2    : abap.char(20);
      shippingMethod2  : abap.char(20);

      _items_abs       : composition of exact one to many Zpru_PurcOrderItem_Abstract;
      // cross bo association on another abstract BDEF
      _cross_bo        : association of exact one to one ZPRU_D_HistoryRoot on _cross_bo.purchaseOrderId = $projection.purchaseOrderId2;

}
