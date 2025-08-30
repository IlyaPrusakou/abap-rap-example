@EndUserText.label: 'Total Amount'
define abstract entity Zpru_D_Total_Amount
{
  @Semantics.amount.currencyCode : 'headerCurrency'
  totalAmount    : abap.curr(15,2);
  headerCurrency : abap.cuky;
}
