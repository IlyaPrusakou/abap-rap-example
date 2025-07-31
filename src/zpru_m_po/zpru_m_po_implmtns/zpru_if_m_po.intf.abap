INTERFACE zpru_if_m_po
  PUBLIC.

  CONSTANTS: BEGIN OF cs_status,
               new       TYPE char1 VALUE space,
               ready     TYPE char1 VALUE 'R',
               completed TYPE char1 VALUE 'C',
               archived  TYPE char1 VALUE 'A',
             END OF cs_status.

  CONSTANTS gc_po_message_class TYPE symsgid VALUE `ZPRU_PO`.

  CONSTANTS: BEGIN OF cs_shipping_method,
               air  TYPE char20 VALUE 'AIR',
               sea  TYPE char20 VALUE 'SEA',
               rail TYPE char20 VALUE 'RAIL',
               road TYPE char20 VALUE 'ROAD',
             END OF cs_shipping_method.

  CONSTANTS: BEGIN OF cs_command,
               sendToAzure TYPE abp_behv_cid VALUE `$sendToAzure`,
             END OF cs_command.

  CONSTANTS: BEGIN OF cs_supplier,
               sup1 TYPE char10 VALUE `SUP1`,
               sup2 TYPE char10 VALUE `SUP2`,
               sup3 TYPE char10 VALUE `SUP3`,
               sup4 TYPE char10 VALUE `SUP4`,
               banned_sup5 TYPE char10 VALUE `BANSUP5`, " used in interface BDEF as managed instance filter
               banned_sup6 TYPE char10 VALUE `BANSUP6`, " used in projection BDEF as managed instance filter
             END OF cs_supplier.


  CONSTANTS: BEGIN OF cs_products,
               product_1 TYPE char10 VALUE 'PROD1',
               product_2 TYPE char10 VALUE 'PROD2',
               product_3 TYPE char10 VALUE 'PROD3',
               product_4 TYPE char10 VALUE 'PROD4',
             END OF cs_products.

  CONSTANTS: BEGIN OF cs_inventory_status,
               active TYPE char1 VALUE 'A',
               await  TYPE char1 VALUE 'W',
             END OF cs_inventory_status.

  CONSTANTS: BEGIN OF cs_whs_location,
               stockpile1 TYPE char20 VALUE 'STOCKPILE1',
               bulky      TYPE char20 VALUE 'BULKY',
             END OF cs_whs_location.

  TYPES ts_getstatushistory_key   TYPE STRUCTURE FOR FUNCTION IMPORT zpru_purcorderhdr_tp\\ordertp~getstatushistory.
  TYPES ts_getstatushistory_res   TYPE STRUCTURE FOR FUNCTION RESULT zpru_purcorderhdr_tp\\ordertp~getstatushistory.
  TYPES ts_order_read_res         TYPE STRUCTURE FOR READ RESULT zpru_purcorderhdr_tp\\ordertp.
  TYPES ts_approved_suppliers     TYPE zpru_d_approvedsupplier.
  TYPES tt_createfromtemplate_key TYPE TABLE FOR ACTION IMPORT zpru_purcorderhdr_tp\\ordertp~createfromtemplate.

ENDINTERFACE.
