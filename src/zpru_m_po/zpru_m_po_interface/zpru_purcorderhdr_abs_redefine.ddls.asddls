@EndUserText.label: 'Purchase Order Abstract Redefinition'
define root abstract entity Zpru_PurcOrderHdr_Abs_Redefine
{
  key purchaseOrderId3 : zpru_de_po_id;
      orderDate3       : abap.dats(8);
      supplierId3      : abap.char(10);
      supplierName3    : abap.char(50);
      buyerId3         : abap.char(10);
      buyerName3       : abap.char(50);
      @Semantics.amount.currencyCode : 'headerCurrency3'
      totalAmount3     : abap.curr(15,2);
      headerCurrency3  : abap.cuky(5);
      deliveryDate3    : abap.dats(8);
      status3          : abap.char(1);
      paymentTerms3    : abap.char(20);
      shippingMethod3  : abap.char(20);

      // cross bo association on another abstract BDEF
      _cross_bo3        : association of exact one to one ZPRU_D_HistoryRoot_Redefine1 on _cross_bo3.purchaseOrderId2 = $projection.purchaseOrderId3;
      _items_abs3       : composition of exact one to many Zpru_PurcOrderItem_Abs_Redefin;
    
}
