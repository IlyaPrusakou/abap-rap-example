@EndUserText.label: 'Status History Record'
define root abstract entity ZPRU_D_HistoryRoot
{
  purchaseOrderId : zpru_de_po_id;
  pid             : abp_behv_pid;
  records         : composition [0..*]  of Zpru_D_StatusHistoryRecord;
}
