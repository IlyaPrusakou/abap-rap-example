INTERFACE zpru_if_m_po
  PUBLIC .

  CONSTANTS: BEGIN OF cs_status,
               new       TYPE char1 VALUE space,
               ready     TYPE char1 VALUE 'R',
               completed TYPE char1 VALUE 'C',
               archived  type char1 value 'A',
             END OF cs_status.

  CONSTANTS: gc_po_message_class TYPE  symsgid VALUE `ZPRU_PO`.

CONSTANTS: BEGIN OF cs_shipping_method,
             air     TYPE char20 VALUE 'AIR',
             sea     TYPE char20 VALUE 'SEA',
             rail    TYPE char20 VALUE 'RAIL',
             road    TYPE char20 VALUE 'ROAD',
           END OF cs_shipping_method.

ENDINTERFACE.
