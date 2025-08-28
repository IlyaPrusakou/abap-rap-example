@EndUserText.label: 'Order Template'
define abstract entity Zpru_D_Order_Template
{
  orderDate       : abap.dats;
  supplierId      : abap.char(10);
  buyerId         : abap.char(10);
  deliveryDate    : abap.dats;
  paymentTerms   : abap.char(20);
  shippingMethod : abap.char(20);

}
