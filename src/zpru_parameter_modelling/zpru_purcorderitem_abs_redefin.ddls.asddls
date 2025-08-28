@EndUserText.label: 'Purchase Order Item Abstract Redefine'
define abstract entity Zpru_PurcOrderItem_Abs_Redefin
{
  key itemId3            : zpru_de_po_itm_id;
  key purchaseOrderId3   : zpru_de_po_id;
      itemNumber3        : abap.int4(10);
      productId3         : abap.char(10);
      productName3       : abap.char(50);
      quantity3          : abap.int4(10);
      @Semantics.amount.currencyCode : 'itemCurrency3'
      unitPrice3         : abap.curr(15,2);
      @Semantics.amount.currencyCode : 'itemCurrency3'
      totalPrice3        : abap.curr(15,2);
      deliveryDate3      : abap.dats(8);
      warehouseLocation3 : abap.char(20);
      itemCurrency3      : abap.cuky(5);
      isUrgent3          : boole_d;

      _header_abs3       : association to parent Zpru_PurcOrderHdr_Abs_Redefine on _header_abs3.purchaseOrderId3 = $projection.purchaseOrderId3;

}
