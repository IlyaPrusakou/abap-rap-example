@EndUserText.label: 'Order Template'
define abstract entity Zpru_D_Order_Template
{
  orderDate       : abap.dats;
  supplierId      : abap.char(10);
  buyerId         : abap.char(10);
  deliveryDate    : abap.dats;
  payment_terms   : abap.char(20);
  shipping_method : abap.char(20);

}
