CLASS lcl_local_event_consumption DEFINITION
  INHERITING FROM cl_abap_behavior_event_handler.

  PRIVATE SECTION.
    METHODS on_order_created_mng
        FOR ENTITY EVENT it_purchase_order
          FOR orderint~derivedordercreate.

ENDCLASS.


CLASS lcl_local_event_consumption IMPLEMENTATION.
  METHOD on_order_created_mng.
    DATA(lt_purchase_order) = it_purchase_order.
  ENDMETHOD.
ENDCLASS.
