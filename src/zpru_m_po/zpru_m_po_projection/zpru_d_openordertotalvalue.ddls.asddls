@EndUserText.label: 'Supplier Open Order Total Value'
define abstract entity Zpru_D_OpenOrderTotalValue
{
  @Semantics.amount.currencyCode : 'headerCurrency'
  totalAmount          : abap.curr(15,2);
  headerCurrency       : abap.cuky;  
}
