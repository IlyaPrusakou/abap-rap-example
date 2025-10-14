CLASS zpru_cl_m_po_virt_elem DEFINITION
  PUBLIC FINAL
  CREATE PUBLIC.

  PUBLIC SECTION.
    INTERFACES if_sadl_exit.
    INTERFACES if_sadl_exit_calc_element_read.
ENDCLASS.


CLASS zpru_cl_m_po_virt_elem IMPLEMENTATION.
  METHOD if_sadl_exit_calc_element_read~calculate.
    LOOP AT it_requested_calc_elements ASSIGNING FIELD-SYMBOL(<lv_virtual_field_name>).
      LOOP AT ct_calculated_data ASSIGNING FIELD-SYMBOL(<ls_calculation_structure>).

        DATA(lv_tabix) = sy-tabix.

        ASSIGN it_original_data[ lv_tabix ] TO FIELD-SYMBOL(<ls_original_data>).
        IF sy-subrc <> 0.
          CONTINUE.
        ENDIF.

        IF <lv_virtual_field_name> <> 'BUSINESSOBJECTSOURCE'.
          CONTINUE.
        ENDIF.

        ASSIGN COMPONENT 'ORIGIN' OF STRUCTURE <ls_original_data> TO FIELD-SYMBOL(<lv_original_field_value>).
        IF sy-subrc <> 0.
          CONTINUE.
        ENDIF.

        ASSIGN COMPONENT <lv_virtual_field_name> OF STRUCTURE <ls_calculation_structure> TO FIELD-SYMBOL(<lv_virtual_field_value>).
        IF sy-subrc <> 0.
          CONTINUE.
        ENDIF.

        CASE <lv_original_field_value>.
          WHEN zpru_if_m_po=>cs_origin-managed.
            <lv_virtual_field_value> = `MANAGED`.
          WHEN zpru_if_m_po=>cs_origin-unamanged.
            <lv_virtual_field_value> = `UNMANAGED`.
          WHEN zpru_if_m_po=>cs_origin-early_numbering.
            <lv_virtual_field_value> = 'EARLY_NUMB'.
          WHEN OTHERS.
            <lv_virtual_field_value> = `UNDEFINED`.
        ENDCASE.
      ENDLOOP.
    ENDLOOP.
  ENDMETHOD.

  METHOD if_sadl_exit_calc_element_read~get_calculation_info.
    LOOP AT it_requested_calc_elements ASSIGNING FIELD-SYMBOL(<ls_requested_calc_elements>).
      IF <ls_requested_calc_elements> = `BUSINESSOBJECTSOURCE`.
        INSERT `ORIGIN` INTO TABLE et_requested_orig_elements.
      ELSE.
        CONTINUE.
      ENDIF.
    ENDLOOP.
  ENDMETHOD.
ENDCLASS.
