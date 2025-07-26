@EndUserText.label: 'Status History Record'
define abstract entity Zpru_D_StatusHistoryRecord
{
  purchaseOrderId : zpru_de_po_id;
  startTimestamp  : timestampl;
  endTimestamp    : timestampl;

}
