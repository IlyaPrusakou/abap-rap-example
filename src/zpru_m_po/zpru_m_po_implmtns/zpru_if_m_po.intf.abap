INTERFACE zpru_if_m_po
  PUBLIC.

  CONSTANTS: BEGIN OF cs_status,
               new                TYPE char1 VALUE space,
               ready              TYPE char1 VALUE 'R',
               partially_complete TYPE char1 VALUE 'P',
               completed          TYPE char1 VALUE 'C',
               archived           TYPE char1 VALUE 'A',
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
               sup1        TYPE char10 VALUE `SUP1`,
               sup2        TYPE char10 VALUE `SUP2`,
               sup3        TYPE char10 VALUE `SUP3`,
               sup4        TYPE char10 VALUE `SUP4`,
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

  CONSTANTS: BEGIN OF cs_buyer,
               buy1 TYPE char10 VALUE 'BUY1',
               buy2 TYPE char10 VALUE 'BUY2',
               buy3 TYPE char10 VALUE 'BUY3',
               buy4 TYPE char10 VALUE 'BUY4',
               buy5 TYPE char10 VALUE 'BUY5',
             END OF cs_buyer.

  CONSTANTS: BEGIN OF cs_buyer_names,
               buy1 TYPE char50 VALUE 'BUY1 NAME',
               buy2 TYPE char50 VALUE 'BUY2 NAME',
               buy3 TYPE char50 VALUE 'BUY3 NAME',
               buy4 TYPE char50 VALUE 'BUY4 NAME',
               buy5 TYPE char50 VALUE 'BUY5 NAME',
             END OF cs_buyer_names.

  CONSTANTS: BEGIN OF cs_SUPPLIER_names,
               sup1        TYPE char50 VALUE 'SUP1 NAME',
               sup2        TYPE char50 VALUE 'SUP2 NAME',
               sup3        TYPE char50 VALUE 'SUP3 NAME',
               sup4        TYPE char50 VALUE 'SUP4 NAME',
               banned_sup5 TYPE char50 VALUE 'BANSUP5 NAME',
               banned_sup6 TYPE char50 VALUE 'BANSUP6 NAME',
             END OF cs_SUPPLIER_names.

  CONSTANTS: BEGIN OF cs_payment_methods,
               advance TYPE char20 VALUE 'ADVANCE',
               post    TYPE char20 VALUE 'POST',
             END OF cs_payment_methods.

  TYPES ts_getstatushistory_key   TYPE STRUCTURE FOR FUNCTION IMPORT zpru_purcorderhdr_tp\\ordertp~getstatushistory.
  TYPES ts_getstatushistory_res   TYPE STRUCTURE FOR FUNCTION RESULT zpru_purcorderhdr_tp\\ordertp~getstatushistory.
  TYPES ts_order_read_res         TYPE STRUCTURE FOR READ RESULT zpru_purcorderhdr_tp\\ordertp.
  TYPES ts_approved_suppliers     TYPE zpru_d_approvedsupplier.
  TYPES tt_createfromtemplate_key TYPE TABLE FOR ACTION IMPORT zpru_purcorderhdr_tp\\ordertp~createfromtemplate.

ENDINTERFACE.
