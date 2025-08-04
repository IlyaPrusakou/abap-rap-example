@EndUserText.label: 'Purchase Order Item Abstract'
define abstract entity Zpru_PurcOrderItem_Abstract
{
  key itemId2            : zpru_de_po_itm_id;
  key purchaseOrderId2   : zpru_de_po_id;
      itemNumber2        : abap.int4(10);
      productId2         : abap.char(10);
      productName2       : abap.char(50);
      quantity2          : abap.int4(10);
      @Semantics.amount.currencyCode : 'itemCurrency2'
      unitPrice2         : abap.curr(15,2);
      @Semantics.amount.currencyCode : 'itemCurrency2'
      totalPrice2        : abap.curr(15,2);
      deliveryDate2      : abap.dats(8);
      warehouseLocation2 : abap.char(20);
      itemCurrency2      : abap.cuky(5);
      isUrgent2          : boole_d;

      _header_abs        : association to parent Zpru_PurcOrderHdr_Abstract on _header_abs.purchaseOrderId2 = $projection.purchaseOrderId2;

}
