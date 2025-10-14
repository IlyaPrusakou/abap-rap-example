INTERFACE lif_business_object.

  CONSTANTS: BEGIN OF cs_state_area,
               BEGIN OF order,
                 checkdates          TYPE string VALUE `checkdates`,
                 checkquantity       TYPE string VALUE `checkQuantity`,
                 checkheadercurrency TYPE string VALUE `checkHeaderCurrency`,
                 checksupplier       TYPE string VALUE `checkSupplier`,
                 checkbuyer          TYPE string VALUE `checkBuyer`,
               END OF order,
               BEGIN OF item,
                 checkquantity     TYPE string VALUE `checkquantity`,
                 checkitemcurrency TYPE string VALUE `checkItemCurrency`,
               END OF item,
             END OF cs_state_area.

ENDINTERFACE.


CLASS lsc_zr_pru_unum_order_tp DEFINITION INHERITING FROM cl_abap_behavior_saver.

  PROTECTED SECTION.
    METHODS save_modified REDEFINITION.

ENDCLASS.


CLASS lsc_zr_pru_unum_order_tp IMPLEMENTATION.
  METHOD save_modified.
    TYPES: BEGIN OF ts_root_db_keys,
             purchase_order_id TYPE zpru_de_po_id,
           END OF ts_root_db_keys.

    TYPES: BEGIN OF ts_text_db_keys,
             purchase_order_id TYPE zpru_de_po_id,
             language          TYPE spras,
           END OF ts_text_db_keys.

    DATA lt_mod_tab      TYPE TABLE OF zpru_purc_order WITH EMPTY KEY.
    DATA lt_del_tab      TYPE STANDARD TABLE OF ts_root_db_keys WITH EMPTY KEY.
    DATA lt_mod_text_tab TYPE TABLE OF zpru_purc_ordert WITH EMPTY KEY.
    DATA lt_del_text_tab TYPE STANDARD TABLE OF ts_text_db_keys WITH EMPTY KEY.

    IF create-orderun IS NOT INITIAL.
      LOOP AT create-orderun ASSIGNING FIELD-SYMBOL(<ls_cr_order>).
        APPEND CORRESPONDING #( <ls_cr_order> MAPPING FROM ENTITY ) TO lt_mod_tab.
      ENDLOOP.
    ENDIF.

    IF update-orderun IS NOT INITIAL.
      LOOP AT update-orderun ASSIGNING FIELD-SYMBOL(<ls_upd_order>).
        APPEND CORRESPONDING #( <ls_upd_order> MAPPING FROM ENTITY ) TO lt_mod_tab.
      ENDLOOP.
    ENDIF.

    IF lt_mod_tab IS NOT INITIAL.
      MODIFY zpru_purc_order FROM TABLE @( CORRESPONDING #( lt_mod_tab ) ).
    ENDIF.

    IF delete-orderun IS NOT INITIAL.
      LOOP AT delete-orderun ASSIGNING FIELD-SYMBOL(<ls_del_order>).
        APPEND VALUE #( purchase_order_id = <ls_del_order>-purchaseorderid ) TO lt_del_tab.
      ENDLOOP.
      DELETE zpru_purc_order FROM TABLE @( CORRESPONDING #( lt_del_tab ) ).

      """""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""
      " qqq logic below relates to issue with different node set for managed implementation ZPRU_PURCORDERHDR_TP
      " unmanaged implementation ZPRU_U_PURCORDERHDR_TP. As far asa you know managed BO has additionally
      " TEXT node for order and also TAG  as extension node. Since both BO work with the same tables.
      " We can create BO via managed implementation, text and tag nodes become create either. Then we can
      " delete instance via unamanged BO, as a result orphan nodes for text and tag remain.
      " solution is to provide additional deletion in cascade style

      IF lt_del_tab IS NOT INITIAL.
        " cascade deletion for TAG node
        SELECT purchase_order_id, tag_id
          FROM zpru_order_tag AS tag
          FOR ALL ENTRIES IN @lt_del_tab
          WHERE tag~purchase_order_id = @lt_del_tab-purchase_order_id
          INTO TABLE @DATA(lt_tag_2_del).

        IF lt_tag_2_del IS NOT INITIAL.
          DELETE zpru_order_tag FROM TABLE @( CORRESPONDING #( lt_tag_2_del ) ).
        ENDIF.
      ENDIF.
      """""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""
    ENDIF.

    IF create-textun IS NOT INITIAL.
      LOOP AT create-textun ASSIGNING FIELD-SYMBOL(<ls_cr_text>).
        APPEND CORRESPONDING #( <ls_cr_text> MAPPING FROM ENTITY ) TO lt_mod_text_tab.
      ENDLOOP.
    ENDIF.

    IF update-textun IS NOT INITIAL.
      LOOP AT update-textun ASSIGNING FIELD-SYMBOL(<ls_upd_text>).
        APPEND CORRESPONDING #( <ls_upd_text> MAPPING FROM ENTITY ) TO lt_mod_text_tab.
      ENDLOOP.
    ENDIF.

    IF lt_mod_text_tab IS NOT INITIAL.
      MODIFY zpru_purc_ordert FROM TABLE @( CORRESPONDING #( lt_mod_text_tab ) ).
    ENDIF.

    IF delete-textun IS NOT INITIAL.
      LOOP AT delete-textun ASSIGNING FIELD-SYMBOL(<ls_del_text>).
        APPEND VALUE #( purchase_order_id = <ls_del_text>-purchaseorderid
                        language          = <ls_del_text>-language ) TO lt_del_text_tab.
      ENDLOOP.
      DELETE zpru_purc_ordert FROM TABLE @( CORRESPONDING #( lt_del_text_tab ) ).
    ENDIF.
  ENDMETHOD.
ENDCLASS.


CLASS lhc_itemun DEFINITION INHERITING FROM cl_abap_behavior_handler.

  PRIVATE SECTION.
    METHODS get_global_authorizations FOR GLOBAL AUTHORIZATION
      IMPORTING REQUEST requested_authorizations FOR itemun RESULT result.

    METHODS getinventorystatus FOR READ
      IMPORTING keys FOR FUNCTION itemun~getinventorystatus RESULT result.

    METHODS markasurgent FOR MODIFY
      IMPORTING keys FOR ACTION itemun~markasurgent.

    METHODS calculatetotalprice FOR DETERMINE ON MODIFY
      IMPORTING keys FOR itemun~calculatetotalprice.

    METHODS findwarehouselocation FOR DETERMINE ON SAVE
      IMPORTING keys FOR itemun~findwarehouselocation.

    METHODS writeitemnumber FOR DETERMINE ON SAVE
      IMPORTING keys FOR itemun~writeitemnumber.

    METHODS checkitemcurrency FOR VALIDATE ON SAVE
      IMPORTING keys FOR itemun~checkitemcurrency.

    METHODS checkquantity FOR VALIDATE ON SAVE
      IMPORTING keys FOR itemun~checkquantity.

ENDCLASS.


CLASS lhc_itemun IMPLEMENTATION.
  METHOD get_global_authorizations.
  ENDMETHOD.

  METHOD getinventorystatus.
    IF keys IS INITIAL.
      APPEND INITIAL LINE TO reported-%other ASSIGNING FIELD-SYMBOL(<lo_reported>).
      <lo_reported> = new_message( id       = zpru_if_m_po=>gc_po_message_class
                                   number   = '001'
                                   severity = if_abap_behv_message=>severity-error ).
      RETURN.
    ENDIF.

    READ ENTITIES OF zr_pru_unum_order_tp
         IN LOCAL MODE
         ENTITY itemun
         FIELDS ( productid )
         WITH CORRESPONDING #( keys )
         RESULT DATA(lt_items).

    IF lt_items IS INITIAL.
      APPEND INITIAL LINE TO reported-%other ASSIGNING <lo_reported>.
      <lo_reported> = new_message( id       = zpru_if_m_po=>gc_po_message_class
                                   number   = '002'
                                   severity = if_abap_behv_message=>severity-error ).
      RETURN.
    ENDIF.

    LOOP AT keys ASSIGNING FIELD-SYMBOL(<ls_key>).

      ASSIGN lt_items[ KEY id COMPONENTS %tky = <ls_key>-%tky ] TO FIELD-SYMBOL(<ls_instance>).
      IF sy-subrc <> 0.
        APPEND INITIAL LINE TO failed-itemun ASSIGNING FIELD-SYMBOL(<ls_failed>).
        <ls_failed>-%tky = <ls_instance>-%tky.
        <ls_failed>-%fail-cause = if_abap_behv=>cause-not_found.
        <ls_failed>-%action-getinventorystatus = if_abap_behv=>mk-on.
        CONTINUE.
      ENDIF.

      APPEND INITIAL LINE TO result ASSIGNING FIELD-SYMBOL(<ls_result>).
      <ls_result>-%tky   = <ls_instance>-%tky.
      <ls_result>-%param = zpru_cl_utility_function=>get_inventory_status( <ls_instance>-%data-productid ).
    ENDLOOP.
  ENDMETHOD.

  METHOD markasurgent.
    DATA lt_item_update TYPE TABLE FOR UPDATE zr_pru_unum_order_tp\\itemun.

    IF keys IS INITIAL.
      APPEND INITIAL LINE TO reported-%other ASSIGNING FIELD-SYMBOL(<lo_reported>).
      <lo_reported> = new_message( id       = zpru_if_m_po=>gc_po_message_class
                                   number   = '001'
                                   severity = if_abap_behv_message=>severity-error ).
      RETURN.
    ENDIF.

    READ ENTITIES OF zr_pru_unum_order_tp
         IN LOCAL MODE
         ENTITY itemun
         ALL FIELDS
         WITH CORRESPONDING #( keys )
         RESULT DATA(lt_items).

    IF lt_items IS INITIAL.
      APPEND INITIAL LINE TO reported-%other ASSIGNING <lo_reported>.
      <lo_reported> = new_message( id       = zpru_if_m_po=>gc_po_message_class
                                   number   = '002'
                                   severity = if_abap_behv_message=>severity-error ).
      RETURN.
    ENDIF.

    LOOP AT keys ASSIGNING FIELD-SYMBOL(<ls_key>).

      ASSIGN lt_items[ KEY id COMPONENTS %tky = <ls_key>-%tky ] TO FIELD-SYMBOL(<ls_instance>).
      IF sy-subrc <> 0.
        APPEND INITIAL LINE TO failed-itemun ASSIGNING FIELD-SYMBOL(<ls_failed>).
        <ls_failed>-%tky = <ls_instance>-%tky.
        <ls_failed>-%fail-cause = if_abap_behv=>cause-not_found.
        <ls_failed>-%action-markasurgent = if_abap_behv=>mk-on.
        CONTINUE.
      ENDIF.

      APPEND INITIAL LINE TO lt_item_update ASSIGNING FIELD-SYMBOL(<ls_order_update>).
      <ls_order_update>-%tky = <ls_instance>-%tky.
      <ls_order_update>-%data-isurgent = abap_true.
      <ls_order_update>-%control-isurgent = if_abap_behv=>mk-on.

    ENDLOOP.

    " update status
    IF lt_item_update IS NOT INITIAL.
      MODIFY ENTITIES OF zr_pru_unum_order_tp
             IN LOCAL MODE
             ENTITY itemun
             UPDATE FROM lt_item_update.
    ENDIF.
  ENDMETHOD.

  METHOD calculatetotalprice.
    DATA lt_item_update TYPE TABLE FOR UPDATE zr_pru_unum_order_tp\\itemun.

    IF keys IS INITIAL.
      APPEND INITIAL LINE TO reported-%other ASSIGNING FIELD-SYMBOL(<lo_reported>).
      <lo_reported> = new_message( id       = zpru_if_m_po=>gc_po_message_class
                                   number   = '001'
                                   severity = if_abap_behv_message=>severity-error ).
      RETURN.
    ENDIF.

    READ ENTITIES OF zr_pru_unum_order_tp
         IN LOCAL MODE
         ENTITY itemun
         FIELDS ( quantity
                  unitprice )
         WITH CORRESPONDING #( keys )
         RESULT DATA(lt_items).

    IF lt_items IS INITIAL.
      APPEND INITIAL LINE TO reported-%other ASSIGNING <lo_reported>.
      <lo_reported> = new_message( id       = zpru_if_m_po=>gc_po_message_class
                                   number   = '002'
                                   severity = if_abap_behv_message=>severity-error ).
      RETURN.
    ENDIF.

    LOOP AT lt_items ASSIGNING FIELD-SYMBOL(<ls_instance>).

      APPEND INITIAL LINE TO lt_item_update ASSIGNING FIELD-SYMBOL(<ls_item_update>).
      <ls_item_update>-%tky = <ls_instance>-%tky.
      <ls_item_update>-%data-totalprice = <ls_instance>-quantity * <ls_instance>-unitprice.
      <ls_item_update>-%control-totalprice = if_abap_behv=>mk-on.

    ENDLOOP.

    IF lt_item_update IS INITIAL.
      RETURN.
    ENDIF.

    MODIFY ENTITIES OF zr_pru_unum_order_tp
           IN LOCAL MODE
           ENTITY itemun
           UPDATE FROM lt_item_update.
  ENDMETHOD.

  METHOD findwarehouselocation.
    DATA lt_item_update TYPE TABLE FOR UPDATE zr_pru_unum_order_tp\\itemun.

    IF keys IS INITIAL.
      APPEND INITIAL LINE TO reported-%other ASSIGNING FIELD-SYMBOL(<lo_reported>).
      <lo_reported> = new_message( id       = zpru_if_m_po=>gc_po_message_class
                                   number   = '001'
                                   severity = if_abap_behv_message=>severity-error ).
      RETURN.
    ENDIF.

    READ ENTITIES OF zr_pru_unum_order_tp
         IN LOCAL MODE
         ENTITY itemun
         FIELDS ( productid )
         WITH CORRESPONDING #( keys )
         RESULT DATA(lt_items).

    IF lt_items IS INITIAL.
      APPEND INITIAL LINE TO reported-%other ASSIGNING <lo_reported>.
      <lo_reported> = new_message( id       = zpru_if_m_po=>gc_po_message_class
                                   number   = '002'
                                   severity = if_abap_behv_message=>severity-error ).
      RETURN.
    ENDIF.

    LOOP AT lt_items ASSIGNING FIELD-SYMBOL(<ls_instance>).

      APPEND INITIAL LINE TO lt_item_update ASSIGNING FIELD-SYMBOL(<ls_item_update>).
      <ls_item_update>-%tky = <ls_instance>-%tky.
      <ls_item_update>-%data-warehouselocation = COND #( WHEN <ls_instance>-productid = zpru_if_m_po=>cs_products-product_1
                                                         THEN zpru_if_m_po=>cs_whs_location-stockpile1
                                                         ELSE zpru_if_m_po=>cs_whs_location-bulky ).
      <ls_item_update>-%control-warehouselocation = if_abap_behv=>mk-on.

    ENDLOOP.

    IF lt_item_update IS INITIAL.
      RETURN.
    ENDIF.

    MODIFY ENTITIES OF zr_pru_unum_order_tp
           IN LOCAL MODE
           ENTITY itemun
           UPDATE FROM lt_item_update.
  ENDMETHOD.

  METHOD writeitemnumber.
    DATA lt_item_update    TYPE TABLE FOR UPDATE zr_pru_unum_order_tp\\itemun.
    DATA lt_existing_items TYPE TABLE FOR READ RESULT zr_pru_unum_order_tp\\itemun.

    IF keys IS INITIAL.
      APPEND INITIAL LINE TO reported-%other ASSIGNING FIELD-SYMBOL(<lo_reported>).
      <lo_reported> = new_message( id       = zpru_if_m_po=>gc_po_message_class
                                   number   = '001'
                                   severity = if_abap_behv_message=>severity-error ).
      RETURN.
    ENDIF.

    READ ENTITIES OF zr_pru_unum_order_tp
         IN LOCAL MODE
         ENTITY itemun
         ALL FIELDS
         WITH CORRESPONDING #( keys )
         RESULT DATA(lt_items).

    IF lt_items IS INITIAL.
      APPEND INITIAL LINE TO reported-%other ASSIGNING <lo_reported>.
      <lo_reported> = new_message( id       = zpru_if_m_po=>gc_po_message_class
                                   number   = '002'
                                   severity = if_abap_behv_message=>severity-error ).
      RETURN.
    ENDIF.

    READ ENTITIES OF zr_pru_unum_order_tp
         IN LOCAL MODE
         ENTITY itemun BY \_orderun
         ALL FIELDS
         WITH VALUE #( FOR <ls_i> IN keys
                       ( %tky-purchaseorderid = <ls_i>-purchaseorderid
                         %tky-itemid          = <ls_i>-itemid  ) )
         LINK DATA(lt_item_to_order).

    READ ENTITIES OF zr_pru_unum_order_tp
         IN LOCAL MODE
         ENTITY orderun BY \_itemsun
         ALL FIELDS
         WITH VALUE #( FOR <ls_ord> IN lt_item_to_order
                       ( CORRESPONDING #( <ls_ord>-target ) ) )
         RESULT DATA(lt_all_items).

    LOOP AT lt_items ASSIGNING FIELD-SYMBOL(<ls_group>)
         GROUP BY ( purchaseorderid = <ls_group>-purchaseorderid ) ASSIGNING FIELD-SYMBOL(<ls_group_key>).

      LOOP AT lt_all_items ASSIGNING FIELD-SYMBOL(<ls_all_items>).
        IF line_exists( keys[ KEY id COMPONENTS %tky = <ls_all_items>-%tky ] ).
          CONTINUE.
        ENDIF.
        APPEND INITIAL LINE TO lt_existing_items ASSIGNING FIELD-SYMBOL(<ls_existing_item>).
        <ls_existing_item> = CORRESPONDING #( <ls_all_items> ).
      ENDLOOP.

      SORT lt_existing_items BY itemnumber DESCENDING.
      DATA(lv_count) = COND i( WHEN lines( lt_existing_items ) > 0
                               THEN VALUE #( lt_existing_items[ 1 ]-itemnumber OPTIONAL )
                               ELSE 0 ).

      LOOP AT GROUP <ls_group_key> ASSIGNING FIELD-SYMBOL(<ls_member>).

        lv_count = lv_count + 1.
        APPEND INITIAL LINE TO lt_item_update ASSIGNING FIELD-SYMBOL(<ls_item_update>).
        <ls_item_update>-%tky = <ls_member>-%tky.
        <ls_item_update>-%data-itemnumber = lv_count.
        <ls_item_update>-%control-itemnumber = if_abap_behv=>mk-on.
      ENDLOOP.

    ENDLOOP.

    IF lt_item_update IS INITIAL.
      RETURN.
    ENDIF.

    MODIFY ENTITIES OF zr_pru_unum_order_tp
           IN LOCAL MODE
           ENTITY itemun
           UPDATE FROM lt_item_update.
  ENDMETHOD.

  METHOD checkitemcurrency.
    IF keys IS INITIAL.
      APPEND INITIAL LINE TO reported-%other ASSIGNING FIELD-SYMBOL(<lo_reported>).
      <lo_reported> = new_message( id       = zpru_if_m_po=>gc_po_message_class
                                   number   = '001'
                                   severity = if_abap_behv_message=>severity-error ).
      RETURN.
    ENDIF.

    READ ENTITIES OF zr_pru_unum_order_tp
         IN LOCAL MODE
         ENTITY itemun
         FIELDS ( itemcurrency )
         WITH CORRESPONDING #( keys )
         RESULT DATA(lt_items).

    IF lt_items IS INITIAL.
      APPEND INITIAL LINE TO reported-%other ASSIGNING <lo_reported>.
      <lo_reported> = new_message( id       = zpru_if_m_po=>gc_po_message_class
                                   number   = '002'
                                   severity = if_abap_behv_message=>severity-error ).
      RETURN.
    ENDIF.

    LOOP AT keys ASSIGNING FIELD-SYMBOL(<ls_key>).

      ASSIGN lt_items[ KEY id COMPONENTS %tky = <ls_key>-%tky ] TO FIELD-SYMBOL(<ls_instance>).
      IF sy-subrc <> 0.
        APPEND INITIAL LINE TO failed-itemun ASSIGNING FIELD-SYMBOL(<ls_failed>).
        <ls_failed>-%tky = <ls_instance>-%tky.
        <ls_failed>-%fail-cause = if_abap_behv=>cause-not_found.
        CONTINUE.
      ENDIF.

      APPEND INITIAL LINE TO reported-itemun ASSIGNING FIELD-SYMBOL(<ls_item_reported>).
      <ls_item_reported>-%tky        = <ls_instance>-%tky.
      <ls_item_reported>-%state_area = lif_business_object=>cs_state_area-item-checkitemcurrency.

      IF <ls_instance>-itemcurrency <> 'USD'.
        APPEND INITIAL LINE TO failed-itemun ASSIGNING <ls_failed>.
        <ls_failed>-%tky = <ls_instance>-%tky.

        APPEND INITIAL LINE TO reported-itemun ASSIGNING <ls_item_reported>.
        <ls_item_reported>-%tky        = <ls_instance>-%tky.
        <ls_item_reported>-%state_area = lif_business_object=>cs_state_area-item-checkitemcurrency.
        <ls_item_reported>-%msg        = new_message( id       = zpru_if_m_po=>gc_po_message_class
                                                      number   = '011'
                                                      severity = if_abap_behv_message=>severity-error ).
      ENDIF.
    ENDLOOP.
  ENDMETHOD.

  METHOD checkquantity.
    DATA lv_correct_total_price TYPE p LENGTH 9 DECIMALS 2.

    IF keys IS INITIAL.
      APPEND INITIAL LINE TO reported-%other ASSIGNING FIELD-SYMBOL(<lo_reported>).
      <lo_reported> = new_message( id       = zpru_if_m_po=>gc_po_message_class
                                   number   = '001'
                                   severity = if_abap_behv_message=>severity-error ).
      RETURN.
    ENDIF.

    READ ENTITIES OF zr_pru_unum_order_tp
         IN LOCAL MODE
         ENTITY itemun
         FIELDS ( quantity unitprice totalprice )
         WITH CORRESPONDING #( keys )
         RESULT DATA(lt_items).

    IF lt_items IS INITIAL.
      APPEND INITIAL LINE TO reported-%other ASSIGNING <lo_reported>.
      <lo_reported> = new_message( id       = zpru_if_m_po=>gc_po_message_class
                                   number   = '002'
                                   severity = if_abap_behv_message=>severity-error ).
      RETURN.
    ENDIF.

    LOOP AT keys ASSIGNING FIELD-SYMBOL(<ls_key>).

      ASSIGN lt_items[ KEY id COMPONENTS %tky = <ls_key>-%tky ] TO FIELD-SYMBOL(<ls_instance>).
      IF sy-subrc <> 0.
        APPEND INITIAL LINE TO failed-itemun ASSIGNING FIELD-SYMBOL(<ls_failed>).
        <ls_failed>-%tky = <ls_instance>-%tky.
        <ls_failed>-%fail-cause = if_abap_behv=>cause-not_found.
        CONTINUE.
      ENDIF.

      APPEND INITIAL LINE TO reported-itemun ASSIGNING FIELD-SYMBOL(<ls_reported>).
      <ls_reported>-%tky        = <ls_instance>-%tky.
      <ls_reported>-%state_area = lif_business_object=>cs_state_area-order-checkquantity.

      lv_correct_total_price = <ls_instance>-quantity * <ls_instance>-unitprice.

      IF lv_correct_total_price <> <ls_instance>-totalprice.
        APPEND INITIAL LINE TO failed-itemun ASSIGNING <ls_failed>.
        <ls_failed>-%tky = <ls_instance>-%tky.

        APPEND INITIAL LINE TO reported-itemun ASSIGNING <ls_reported>.
        <ls_reported>-%tky        = <ls_instance>-%tky.
        <ls_reported>-%state_area = lif_business_object=>cs_state_area-order-checkquantity.
        <ls_reported>-%msg        = new_message( id       = zpru_if_m_po=>gc_po_message_class
                                                 number   = '010'
                                                 severity = if_abap_behv_message=>severity-error ).
      ENDIF.
    ENDLOOP.
  ENDMETHOD.
ENDCLASS.


CLASS lhc_orderun DEFINITION INHERITING FROM cl_abap_behavior_handler.
  PRIVATE SECTION.
    METHODS get_global_authorizations FOR GLOBAL AUTHORIZATION
      IMPORTING
      REQUEST requested_authorizations FOR orderun
      RESULT result.
    METHODS determinenames FOR DETERMINE ON MODIFY
      IMPORTING keys FOR orderun~determinenames.

    METHODS recalculateshippingmethod FOR DETERMINE ON MODIFY
      IMPORTING keys FOR orderun~recalculateshippingmethod.

    METHODS calctotalamount FOR DETERMINE ON SAVE
      IMPORTING keys FOR orderun~calctotalamount.

    METHODS fillorigin FOR DETERMINE ON SAVE
      IMPORTING keys FOR orderun~fillorigin.

    METHODS setcontroltimestamp FOR DETERMINE ON SAVE
      IMPORTING keys FOR orderun~setcontroltimestamp.

    METHODS checkbuyer FOR VALIDATE ON SAVE
      IMPORTING keys FOR orderun~checkbuyer.

    METHODS checkdates FOR VALIDATE ON SAVE
      IMPORTING keys FOR orderun~checkdates.

    METHODS checkheadercurrency FOR VALIDATE ON SAVE
      IMPORTING keys FOR orderun~checkheadercurrency.

    METHODS checksupplier FOR VALIDATE ON SAVE
      IMPORTING keys FOR orderun~checksupplier.
    METHODS earlynumbering_create FOR NUMBERING
      IMPORTING entities FOR CREATE orderun.

    METHODS earlynumbering_cba_itemsun FOR NUMBERING
      IMPORTING entities FOR CREATE orderun\_itemsun.

ENDCLASS.


CLASS lhc_orderun IMPLEMENTATION.
  METHOD get_global_authorizations.
  ENDMETHOD.

  METHOD earlynumbering_create.
    IF entities IS INITIAL.
      RETURN.
    ENDIF.

    DATA(lv_count) = zpru_cl_utility_function=>get_last_po_number( ).

    LOOP AT entities ASSIGNING FIELD-SYMBOL(<ls_ent>).
      lv_count += 1.
      APPEND INITIAL LINE TO mapped-orderun ASSIGNING FIELD-SYMBOL(<ls_orderun>).
      <ls_orderun>-%cid            = <ls_ent>-%cid.
      <ls_orderun>-purchaseorderid = lv_count.
    ENDLOOP.
  ENDMETHOD.

  METHOD earlynumbering_cba_itemsun.
    IF entities IS INITIAL.
      RETURN.
    ENDIF.

    READ ENTITIES OF zr_pru_unum_order_tp
         IN LOCAL MODE
         ENTITY orderun BY \_itemsun
         FIELDS ( purchaseorderid
                  itemid )
         WITH VALUE #( FOR <ls_e>
                       IN entities
                       ( purchaseorderid = <ls_e>-purchaseorderid ) )
         RESULT DATA(lt_items).

    LOOP AT entities ASSIGNING FIELD-SYMBOL(<ls_order>).

      DATA(lt_items_copy) = lt_items.
      DELETE lt_items_copy WHERE purchaseorderid <> <ls_order>-purchaseorderid.
      SORT lt_items_copy BY itemid DESCENDING.

      DATA(lv_count) = VALUE #( lt_items_copy[ 1 ]-itemid OPTIONAL ).
      IF lv_count IS NOT INITIAL.
        lv_count += 1.
      ELSE.
        lv_count = 1.
      ENDIF.

      LOOP AT <ls_order>-%target ASSIGNING FIELD-SYMBOL(<ls_item>).
        APPEND INITIAL LINE TO mapped-itemun ASSIGNING FIELD-SYMBOL(<ls_map_item>).
        <ls_map_item>-%cid            = <ls_item>-%cid.
        <ls_map_item>-purchaseorderid = <ls_order>-purchaseorderid.
        <ls_map_item>-itemid          = lv_count.

        lv_count += 1.
      ENDLOOP.
    ENDLOOP.
  ENDMETHOD.

  METHOD determinenames.
    DATA lt_order_update TYPE TABLE FOR UPDATE zr_pru_unum_order_tp\\orderun.

    IF keys IS INITIAL.
      APPEND INITIAL LINE TO reported-%other ASSIGNING FIELD-SYMBOL(<lo_reported>).
      <lo_reported> = new_message( id       = zpru_if_m_po=>gc_po_message_class
                                   number   = '001'
                                   severity = if_abap_behv_message=>severity-error ).
      RETURN.
    ENDIF.

    READ ENTITIES OF zr_pru_unum_order_tp
         IN LOCAL MODE
         ENTITY orderun
         FIELDS ( supplierid buyerid ) WITH CORRESPONDING #( keys )
         RESULT DATA(lt_roots).

    IF lt_roots IS INITIAL.
      APPEND INITIAL LINE TO reported-%other ASSIGNING <lo_reported>.
      <lo_reported> = new_message( id       = zpru_if_m_po=>gc_po_message_class
                                   number   = '002'
                                   severity = if_abap_behv_message=>severity-error ).
      RETURN.
    ENDIF.

    LOOP AT lt_roots ASSIGNING FIELD-SYMBOL(<ls_instance>).

      APPEND INITIAL LINE TO lt_order_update ASSIGNING FIELD-SYMBOL(<ls_order_update>).
      <ls_order_update>-%tky = <ls_instance>-%tky.
      <ls_order_update>-%data-suppliername = zpru_cl_utility_function=>get_supplier_name( <ls_instance>-supplierid ).
      <ls_order_update>-%control-suppliername = if_abap_behv=>mk-on.

      <ls_order_update>-%data-buyername = zpru_cl_utility_function=>get_buyer_name( <ls_instance>-buyerid ).
      <ls_order_update>-%control-buyername = if_abap_behv=>mk-on.

    ENDLOOP.

    IF lt_order_update IS INITIAL.
      RETURN.
    ENDIF.

    MODIFY ENTITIES OF zr_pru_unum_order_tp
           IN LOCAL MODE
           ENTITY orderun
           UPDATE FROM lt_order_update.
  ENDMETHOD.

  METHOD recalculateshippingmethod.
    DATA lt_order_update TYPE TABLE FOR UPDATE zr_pru_unum_order_tp\\orderun.

    IF keys IS INITIAL.
      APPEND INITIAL LINE TO reported-%other ASSIGNING FIELD-SYMBOL(<lo_reported>).
      <lo_reported> = new_message( id       = zpru_if_m_po=>gc_po_message_class
                                   number   = '001'
                                   severity = if_abap_behv_message=>severity-error ).
      RETURN.
    ENDIF.

    READ ENTITIES OF zr_pru_unum_order_tp
         IN LOCAL MODE
         ENTITY orderun
         FIELDS ( purchaseorderid
                  supplierid )
         WITH CORRESPONDING #( keys )
         RESULT DATA(lt_roots).

    IF lt_roots IS INITIAL.
      APPEND INITIAL LINE TO reported-%other ASSIGNING <lo_reported>.
      <lo_reported> = new_message( id       = zpru_if_m_po=>gc_po_message_class
                                   number   = '002'
                                   severity = if_abap_behv_message=>severity-error ).
      RETURN.
    ENDIF.

    LOOP AT lt_roots ASSIGNING FIELD-SYMBOL(<ls_instance>).

      APPEND INITIAL LINE TO lt_order_update ASSIGNING FIELD-SYMBOL(<ls_order_update>).
      <ls_order_update>-%tky = <ls_instance>-%tky.
      <ls_order_update>-%data-shippingmethod = zpru_cl_utility_function=>get_preferred_ship_method(
                                                   <ls_instance>-supplierid ).
      <ls_order_update>-%control-shippingmethod = if_abap_behv=>mk-on.

    ENDLOOP.

    IF lt_order_update IS INITIAL.
      RETURN.
    ENDIF.

    MODIFY ENTITIES OF zr_pru_unum_order_tp
           IN LOCAL MODE
           ENTITY orderun
           UPDATE FROM lt_order_update.
  ENDMETHOD.

  METHOD calctotalamount.
    DATA lt_order_update     TYPE TABLE FOR UPDATE zr_pru_unum_order_tp\\orderun.
    DATA lv_new_total_amount TYPE zr_pru_unum_order_tp-totalamount.

    IF keys IS INITIAL.
      APPEND INITIAL LINE TO reported-%other ASSIGNING FIELD-SYMBOL(<lo_reported>).
      <lo_reported> = new_message( id       = zpru_if_m_po=>gc_po_message_class
                                   number   = '001'
                                   severity = if_abap_behv_message=>severity-error ).
      RETURN.
    ENDIF.

    READ ENTITIES OF zr_pru_unum_order_tp
         IN LOCAL MODE
         ENTITY orderun
         FIELDS ( purchaseorderid totalamount )
         WITH CORRESPONDING #( keys )
         RESULT DATA(lt_roots).

    IF lt_roots IS INITIAL.
      APPEND INITIAL LINE TO reported-%other ASSIGNING <lo_reported>.
      <lo_reported> = new_message( id       = zpru_if_m_po=>gc_po_message_class
                                   number   = '002'
                                   severity = if_abap_behv_message=>severity-error ).
      RETURN.
    ENDIF.

    READ ENTITIES OF zr_pru_unum_order_tp
         IN LOCAL MODE
         ENTITY orderun BY \_itemsun
         FIELDS ( totalprice ) WITH CORRESPONDING #( lt_roots )
         RESULT DATA(lt_items).

    LOOP AT lt_roots ASSIGNING FIELD-SYMBOL(<ls_instance>).

      CLEAR lv_new_total_amount.
      LOOP AT lt_items ASSIGNING FIELD-SYMBOL(<ls_item>) WHERE purchaseorderid = <ls_instance>-purchaseorderid.
        lv_new_total_amount += <ls_item>-%data-totalprice.
      ENDLOOP.

      " prevent auto triggering
      IF <ls_instance>-totalamount <> lv_new_total_amount.
        APPEND INITIAL LINE TO lt_order_update ASSIGNING FIELD-SYMBOL(<ls_order_update>).
        <ls_order_update>-%tky        = <ls_instance>-%tky.
        <ls_order_update>-totalamount = lv_new_total_amount.
        <ls_order_update>-%control-totalamount = if_abap_behv=>mk-on.
      ENDIF.

    ENDLOOP.

    IF lt_order_update IS INITIAL.
      RETURN.
    ENDIF.

    MODIFY ENTITIES OF zr_pru_unum_order_tp
           IN LOCAL MODE
           ENTITY orderun
           UPDATE FROM lt_order_update.
  ENDMETHOD.

  METHOD fillorigin.
    DATA lt_order_update TYPE TABLE FOR UPDATE zr_pru_unum_order_tp\\orderun.

    IF keys IS INITIAL.
      APPEND INITIAL LINE TO reported-%other ASSIGNING FIELD-SYMBOL(<lo_reported>).
      <lo_reported> = new_message( id       = zpru_if_m_po=>gc_po_message_class
                                   number   = '001'
                                   severity = if_abap_behv_message=>severity-error ).
      RETURN.
    ENDIF.

    READ ENTITIES OF zr_pru_unum_order_tp
         IN LOCAL MODE
         ENTITY orderun
         ALL FIELDS WITH CORRESPONDING #( keys )
         RESULT DATA(lt_roots).

    IF lt_roots IS INITIAL.
      APPEND INITIAL LINE TO reported-%other ASSIGNING <lo_reported>.
      <lo_reported> = new_message( id       = zpru_if_m_po=>gc_po_message_class
                                   number   = '002'
                                   severity = if_abap_behv_message=>severity-error ).
      RETURN.
    ENDIF.

    LOOP AT lt_roots ASSIGNING FIELD-SYMBOL(<ls_instance>).

      APPEND INITIAL LINE TO lt_order_update ASSIGNING FIELD-SYMBOL(<ls_order_update>).
      <ls_order_update>-%tky = <ls_instance>-%tky.
      <ls_order_update>-%data-origin = zpru_if_m_po=>cs_origin-early_numbering.
      <ls_order_update>-%control-origin = if_abap_behv=>mk-on.

    ENDLOOP.

    IF lt_order_update IS INITIAL.
      RETURN.
    ENDIF.

    MODIFY ENTITIES OF zr_pru_unum_order_tp
           IN LOCAL MODE
           ENTITY orderun
           UPDATE FROM lt_order_update.
  ENDMETHOD.

  METHOD setcontroltimestamp.
    DATA lt_order_update TYPE TABLE FOR UPDATE zr_pru_unum_order_tp\\orderun.

    IF keys IS INITIAL.
      APPEND INITIAL LINE TO reported-%other ASSIGNING FIELD-SYMBOL(<lo_reported>).
      <lo_reported> = new_message( id       = zpru_if_m_po=>gc_po_message_class
                                   number   = '001'
                                   severity = if_abap_behv_message=>severity-error ).
      RETURN.
    ENDIF.

    READ ENTITIES OF zr_pru_unum_order_tp
         IN LOCAL MODE
         ENTITY orderun
         FIELDS ( purchaseorderid )
         WITH CORRESPONDING #( keys )
         RESULT DATA(lt_roots).

    IF lt_roots IS INITIAL.
      APPEND INITIAL LINE TO reported-%other ASSIGNING <lo_reported>.
      <lo_reported> = new_message( id       = zpru_if_m_po=>gc_po_message_class
                                   number   = '002'
                                   severity = if_abap_behv_message=>severity-error ).
      RETURN.
    ENDIF.

    GET TIME STAMP FIELD DATA(lv_now).

    LOOP AT lt_roots ASSIGNING FIELD-SYMBOL(<ls_instance>).

      APPEND INITIAL LINE TO lt_order_update ASSIGNING FIELD-SYMBOL(<ls_order_update>).
      <ls_order_update>-%tky = <ls_instance>-%tky.
      <ls_order_update>-%data-controltimestamp = lv_now.
      <ls_order_update>-%control-controltimestamp = if_abap_behv=>mk-on.

    ENDLOOP.

    IF lt_order_update IS INITIAL.
      RETURN.
    ENDIF.

    MODIFY ENTITIES OF zr_pru_unum_order_tp
           IN LOCAL MODE
           ENTITY orderun
           UPDATE FROM lt_order_update.
  ENDMETHOD.

  METHOD checkbuyer.
    IF keys IS INITIAL.
      APPEND INITIAL LINE TO reported-%other ASSIGNING FIELD-SYMBOL(<lo_reported>).
      <lo_reported> = new_message( id       = zpru_if_m_po=>gc_po_message_class
                                   number   = '001'
                                   severity = if_abap_behv_message=>severity-error ).
      RETURN.
    ENDIF.

    READ ENTITIES OF zr_pru_unum_order_tp
         IN LOCAL MODE
         ENTITY orderun
         FIELDS ( buyerid )
         WITH CORRESPONDING #( keys )
         RESULT DATA(lt_roots).

    IF lt_roots IS INITIAL.
      APPEND INITIAL LINE TO reported-%other ASSIGNING <lo_reported>.
      <lo_reported> = new_message( id       = zpru_if_m_po=>gc_po_message_class
                                   number   = '002'
                                   severity = if_abap_behv_message=>severity-error ).
      RETURN.
    ENDIF.

    LOOP AT keys ASSIGNING FIELD-SYMBOL(<ls_key>).

      ASSIGN lt_roots[ KEY id COMPONENTS %tky = <ls_key>-%tky ] TO FIELD-SYMBOL(<ls_instance>).
      IF sy-subrc <> 0.
        APPEND INITIAL LINE TO failed-orderun ASSIGNING FIELD-SYMBOL(<ls_failed>).
        <ls_failed>-%tky = <ls_instance>-%tky.
        <ls_failed>-%fail-cause = if_abap_behv=>cause-not_found.
        CONTINUE.
      ENDIF.

      APPEND INITIAL LINE TO reported-orderun ASSIGNING FIELD-SYMBOL(<ls_order_reported>).
      <ls_order_reported>-%tky        = <ls_instance>-%tky.
      <ls_order_reported>-%state_area = lif_business_object=>cs_state_area-order-checkbuyer.

      IF    <ls_instance>-buyerid = zpru_if_m_po=>cs_buyer-buy1
         OR <ls_instance>-buyerid = zpru_if_m_po=>cs_buyer-buy2
         OR <ls_instance>-buyerid = zpru_if_m_po=>cs_buyer-buy3
         OR <ls_instance>-buyerid = zpru_if_m_po=>cs_buyer-buy4
         OR <ls_instance>-buyerid = zpru_if_m_po=>cs_buyer-buy5.
        CONTINUE.
      ENDIF.

      APPEND INITIAL LINE TO failed-orderun ASSIGNING <ls_failed>.
      <ls_failed>-%tky = <ls_instance>-%tky.

      APPEND INITIAL LINE TO reported-orderun ASSIGNING <ls_order_reported>.
      <ls_order_reported>-%tky        = <ls_instance>-%tky.
      <ls_order_reported>-%state_area = lif_business_object=>cs_state_area-order-checkbuyer.
      <ls_order_reported>-%msg        = new_message( id       = zpru_if_m_po=>gc_po_message_class
                                                     number   = '013'
                                                     severity = if_abap_behv_message=>severity-error ).

    ENDLOOP.
  ENDMETHOD.

  METHOD checkdates.
    IF keys IS INITIAL.
      APPEND INITIAL LINE TO reported-%other ASSIGNING FIELD-SYMBOL(<lo_reported>).
      <lo_reported> = new_message( id       = zpru_if_m_po=>gc_po_message_class
                                   number   = '001'
                                   severity = if_abap_behv_message=>severity-error ).
      RETURN.
    ENDIF.

    READ ENTITIES OF zr_pru_unum_order_tp
         IN LOCAL MODE
         ENTITY orderun
         FIELDS ( orderdate deliverydate )
         WITH CORRESPONDING #( keys )
         RESULT DATA(lt_roots).

    IF lt_roots IS INITIAL.
      APPEND INITIAL LINE TO reported-%other ASSIGNING <lo_reported>.
      <lo_reported> = new_message( id       = zpru_if_m_po=>gc_po_message_class
                                   number   = '002'
                                   severity = if_abap_behv_message=>severity-error ).
      RETURN.
    ENDIF.

    LOOP AT keys ASSIGNING FIELD-SYMBOL(<ls_key>).

      ASSIGN lt_roots[ KEY id COMPONENTS %tky = <ls_key>-%tky ] TO FIELD-SYMBOL(<ls_instance>).
      IF sy-subrc <> 0.
        APPEND INITIAL LINE TO failed-orderun ASSIGNING FIELD-SYMBOL(<ls_failed>).
        <ls_failed>-%tky = <ls_instance>-%tky.
        <ls_failed>-%fail-cause = if_abap_behv=>cause-not_found.
        CONTINUE.
      ENDIF.

      APPEND INITIAL LINE TO reported-orderun ASSIGNING FIELD-SYMBOL(<ls_order_reported>).
      <ls_order_reported>-%tky        = <ls_instance>-%tky.
      <ls_order_reported>-%state_area = lif_business_object=>cs_state_area-order-checkdates.

      IF <ls_instance>-orderdate > <ls_instance>-deliverydate.
        APPEND INITIAL LINE TO failed-orderun ASSIGNING <ls_failed>.
        <ls_failed>-%tky = <ls_instance>-%tky.

        APPEND INITIAL LINE TO reported-orderun ASSIGNING <ls_order_reported>.
        <ls_order_reported>-%tky        = <ls_instance>-%tky.
        <ls_order_reported>-%state_area = lif_business_object=>cs_state_area-order-checkdates.
        <ls_order_reported>-%msg        = new_message( id       = zpru_if_m_po=>gc_po_message_class
                                                       number   = '005'
                                                       severity = if_abap_behv_message=>severity-error ).
      ENDIF.
    ENDLOOP.
  ENDMETHOD.

  METHOD checkheadercurrency.
    IF keys IS INITIAL.
      APPEND INITIAL LINE TO reported-%other ASSIGNING FIELD-SYMBOL(<lo_reported>).
      <lo_reported> = new_message( id       = zpru_if_m_po=>gc_po_message_class
                                   number   = '001'
                                   severity = if_abap_behv_message=>severity-error ).
      RETURN.
    ENDIF.

    READ ENTITIES OF zr_pru_unum_order_tp
         IN LOCAL MODE
         ENTITY orderun
         FIELDS ( headercurrency )
         WITH CORRESPONDING #( keys )
         RESULT DATA(lt_roots).

    IF lt_roots IS INITIAL.
      APPEND INITIAL LINE TO reported-%other ASSIGNING <lo_reported>.
      <lo_reported> = new_message( id       = zpru_if_m_po=>gc_po_message_class
                                   number   = '002'
                                   severity = if_abap_behv_message=>severity-error ).
      RETURN.
    ENDIF.

    LOOP AT keys ASSIGNING FIELD-SYMBOL(<ls_key>).

      ASSIGN lt_roots[ KEY id COMPONENTS %tky = <ls_key>-%tky ] TO FIELD-SYMBOL(<ls_instance>).
      IF sy-subrc <> 0.
        APPEND INITIAL LINE TO failed-orderun ASSIGNING FIELD-SYMBOL(<ls_failed>).
        <ls_failed>-%tky = <ls_instance>-%tky.
        <ls_failed>-%fail-cause = if_abap_behv=>cause-not_found.
        CONTINUE.
      ENDIF.

      APPEND INITIAL LINE TO reported-orderun ASSIGNING FIELD-SYMBOL(<ls_order_reported>).
      <ls_order_reported>-%tky        = <ls_instance>-%tky.
      <ls_order_reported>-%state_area = lif_business_object=>cs_state_area-order-checkheadercurrency.

      IF <ls_instance>-headercurrency <> 'USD'.
        APPEND INITIAL LINE TO failed-orderun ASSIGNING <ls_failed>.
        <ls_failed>-%tky = <ls_instance>-%tky.

        APPEND INITIAL LINE TO reported-orderun ASSIGNING <ls_order_reported>.
        <ls_order_reported>-%tky        = <ls_instance>-%tky.
        <ls_order_reported>-%state_area = lif_business_object=>cs_state_area-order-checkheadercurrency.
        <ls_order_reported>-%msg        = new_message( id       = zpru_if_m_po=>gc_po_message_class
                                                       number   = '011'
                                                       severity = if_abap_behv_message=>severity-error ).
      ENDIF.
    ENDLOOP.
  ENDMETHOD.

  METHOD checksupplier.
    IF keys IS INITIAL.
      APPEND INITIAL LINE TO reported-%other ASSIGNING FIELD-SYMBOL(<lo_reported>).
      <lo_reported> = new_message( id       = zpru_if_m_po=>gc_po_message_class
                                   number   = '001'
                                   severity = if_abap_behv_message=>severity-error ).
      RETURN.
    ENDIF.

    READ ENTITIES OF zr_pru_unum_order_tp
         IN LOCAL MODE
         ENTITY orderun
         FIELDS ( supplierid )
         WITH CORRESPONDING #( keys )
         RESULT DATA(lt_roots).

    IF lt_roots IS INITIAL.
      APPEND INITIAL LINE TO reported-%other ASSIGNING <lo_reported>.
      <lo_reported> = new_message( id       = zpru_if_m_po=>gc_po_message_class
                                   number   = '002'
                                   severity = if_abap_behv_message=>severity-error ).
      RETURN.
    ENDIF.

    LOOP AT keys ASSIGNING FIELD-SYMBOL(<ls_key>).

      ASSIGN lt_roots[ KEY id COMPONENTS %tky = <ls_key>-%tky ] TO FIELD-SYMBOL(<ls_instance>).
      IF sy-subrc <> 0.
        APPEND INITIAL LINE TO failed-orderun ASSIGNING FIELD-SYMBOL(<ls_failed>).
        <ls_failed>-%tky = <ls_instance>-%tky.
        <ls_failed>-%fail-cause = if_abap_behv=>cause-not_found.
        CONTINUE.
      ENDIF.

      APPEND INITIAL LINE TO reported-orderun ASSIGNING FIELD-SYMBOL(<ls_order_reported>).
      <ls_order_reported>-%tky        = <ls_instance>-%tky.
      <ls_order_reported>-%state_area = lif_business_object=>cs_state_area-order-checksupplier.

      IF    <ls_instance>-supplierid = zpru_if_m_po=>cs_supplier-sup1
         OR <ls_instance>-supplierid = zpru_if_m_po=>cs_supplier-sup2
         OR <ls_instance>-supplierid = zpru_if_m_po=>cs_supplier-sup3
         OR <ls_instance>-supplierid = zpru_if_m_po=>cs_supplier-sup4.
        CONTINUE.
      ENDIF.

      APPEND INITIAL LINE TO failed-orderun ASSIGNING <ls_failed>.
      <ls_failed>-%tky = <ls_instance>-%tky.

      APPEND INITIAL LINE TO reported-orderun ASSIGNING <ls_order_reported>.
      <ls_order_reported>-%tky        = <ls_instance>-%tky.
      <ls_order_reported>-%state_area = lif_business_object=>cs_state_area-order-checksupplier.
      <ls_order_reported>-%msg        = new_message( id       = zpru_if_m_po=>gc_po_message_class
                                                     number   = '012'
                                                     severity = if_abap_behv_message=>severity-error ).

    ENDLOOP.
  ENDMETHOD.
ENDCLASS.
