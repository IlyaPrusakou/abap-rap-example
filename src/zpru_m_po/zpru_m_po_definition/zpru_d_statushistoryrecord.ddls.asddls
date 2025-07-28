@EndUserText.label: 'Status History Record'
define abstract entity Zpru_D_StatusHistoryRecord
{
  startTimestamp  : timestampl;
  endTimestamp    : timestampl;
  header          : association to parent ZPRU_D_HistoryRoot;
}
