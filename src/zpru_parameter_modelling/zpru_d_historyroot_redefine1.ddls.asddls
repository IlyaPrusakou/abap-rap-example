@EndUserText.label: 'Status History Redefinition'
define root abstract entity ZPRU_D_HistoryRoot_Redefine1
{
  purchaseOrderId2 : zpru_de_po_id;
  pid2             : abp_behv_pid;
  records2         : composition [0..*]  of Zpru_D_StatusHistoryRecord_Rn1;
}
