INTERFACE zpru_if_m_po
  PUBLIC .

  CONSTANTS: BEGIN OF cs_status,
               new       TYPE char1 VALUE space,
               ready     TYPE char1 VALUE 'R',
               completed TYPE char1 VALUE 'C',
               archived  TYPE char1 VALUE 'A',
             END OF cs_status.

  CONSTANTS: gc_po_message_class TYPE  symsgid VALUE `ZPRU_PO`.

  CONSTANTS: BEGIN OF cs_shipping_method,
               air  TYPE char20 VALUE 'AIR',
               sea  TYPE char20 VALUE 'SEA',
               rail TYPE char20 VALUE 'RAIL',
               road TYPE char20 VALUE 'ROAD',
             END OF cs_shipping_method.

  CONSTANTS: BEGIN OF cs_command,
               sendToAzure TYPE abp_behv_cid VALUE `$sendToAzure`,
             END OF cs_command.

  TYPES: ts_getstatushistory_key TYPE STRUCTURE FOR FUNCTION IMPORT zpru_purcorderhdr_tp\\ordertp~getstatushistory.
  TYPES: ts_getstatushistory_res TYPE STRUCTURE FOR FUNCTION RESULT zpru_purcorderhdr_tp\\ordertp~getstatushistory.
  TYPES: ts_order_read_res TYPE STRUCTURE FOR READ RESULT zpru_purcorderhdr_tp\\ordertp.
  TYPES: ts_approved_suppliers TYPE zpru_d_approvedsupplier.


ENDINTERFACE.
