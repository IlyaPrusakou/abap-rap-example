CLASS zpru_cl_utility_function DEFINITION
  PUBLIC FINAL
  CREATE PUBLIC.

  PUBLIC SECTION.
    CLASS-METHODS get_preferred_ship_method
      IMPORTING iv_supplier_id      TYPE char10
      RETURNING VALUE(rv_ship_meth) TYPE char20.

    CLASS-METHODS fetch_history
      IMPORTING is_instance       TYPE zpru_if_m_po=>tt_order_read_res
      RETURNING VALUE(rt_history) TYPE zpru_if_m_po=>tt_getstatushistory_res.
ENDCLASS.


CLASS zpru_cl_utility_function IMPLEMENTATION.
  METHOD get_preferred_ship_method.
    CASE iv_supplier_id.
      WHEN 'SUP1'.
        rv_ship_meth = zpru_if_m_po=>cs_shipping_method-air.
      WHEN 'SUP2'.
        rv_ship_meth = zpru_if_m_po=>cs_shipping_method-rail.
      WHEN 'SUP3'.
        rv_ship_meth = zpru_if_m_po=>cs_shipping_method-road.
      WHEN 'SUP4'.
        rv_ship_meth = zpru_if_m_po=>cs_shipping_method-sea.
      WHEN OTHERS.
        rv_ship_meth = zpru_if_m_po=>cs_shipping_method-air.
    ENDCASE.
  ENDMETHOD.

  METHOD fetch_history.
    " TODO: variable is assigned but never used (ABAP cleaner)
    CONVERT DATE is_instance-orderDate TIME sy-timlo INTO TIME STAMP DATA(lv_start) TIME ZONE 'CET'.
    " TODO: variable is assigned but never used (ABAP cleaner)
    CONVERT DATE is_instance-DeliveryDate TIME sy-timlo INTO TIME STAMP DATA(lv_end) TIME ZONE 'CET'.
  ENDMETHOD.
ENDCLASS.
