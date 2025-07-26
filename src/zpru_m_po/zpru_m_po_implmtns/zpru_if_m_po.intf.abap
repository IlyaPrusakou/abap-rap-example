INTERFACE zpru_if_m_po
  PUBLIC .

  CONSTANTS: BEGIN OF cs_status,
               new       TYPE char1 VALUE space,
               ready     TYPE char1 VALUE 'R',
               completed TYPE char1 VALUE 'C',
             END OF cs_status.

ENDINTERFACE.
