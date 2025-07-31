@EndUserText.label: 'Status History Record Redefinition'
define abstract entity Zpru_D_StatusHistoryRecord_Rn1
{
  startTimestamp2  : timestampl;
  endTimestamp2    : timestampl;
  header2          : association to parent ZPRU_D_HistoryRoot_Redefine1;   
}
