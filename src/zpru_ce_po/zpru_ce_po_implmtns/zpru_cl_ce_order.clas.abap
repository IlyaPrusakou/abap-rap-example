CLASS zpru_cl_ce_order DEFINITION
  PUBLIC FINAL
  CREATE PUBLIC.

  PUBLIC SECTION.
    INTERFACES if_rap_query_provider.
ENDCLASS.


CLASS zpru_cl_ce_order IMPLEMENTATION.
  METHOD if_rap_query_provider~select.

    DATA lt_root_select     TYPE STANDARD TABLE OF zpru_purcorderhdr WITH EMPTY KEY.
    DATA lt_root_response   TYPE STANDARD TABLE OF zpru_ce_purcorderhdr_tp WITH EMPTY KEY.
    DATA lt_ids             TYPE RANGE OF zpru_de_po_id.
    DATA lt_root_for_ai     LIKE lt_root_select.

    TRY.
        IF io_request->get_entity_id( ) <> 'ZPRU_CE_PURCORDERHDR_TP'.
          RETURN.
        ENDIF.

        " filter
        DATA(lv_sql_filter) = io_request->get_filter( )->get_as_sql_string( ).
        TRY.
            " TODO: variable is assigned but never used (ABAP cleaner)
            DATA(lt_filter) = io_request->get_filter( )->get_as_ranges( ).
          CATCH cx_rap_query_filter_no_range.
            " handle exception
        ENDTRY.

        " request data
        IF io_request->is_data_requested( ).
          " paging
          DATA(lo_paging) = io_request->get_paging( ).
          IF lo_paging IS BOUND.
            DATA(lv_offset) = lo_paging->get_offset( ).
            DATA(lv_page_size) = lo_paging->get_page_size( ).
            DATA(lv_max_rows) = COND #( WHEN lv_page_size = if_rap_query_paging=>page_size_unlimited
                                        THEN 0
                                        ELSE lv_page_size ).
          ENDIF.
          " sorting
          DATA(sort_elements) = io_request->get_sort_elements( ).
          DATA(lt_sort_criteria) = VALUE string_table(
              FOR sort_element IN sort_elements
              ( sort_element-element_name && COND #( WHEN sort_element-descending = abap_true
                                                     THEN ` descending`
                                                     ELSE ` ascending` ) ) ).
          DATA(lv_sort_string)  = COND #( WHEN lt_sort_criteria IS INITIAL
                                          THEN `primary key`
                                          ELSE concat_lines_of( table = lt_sort_criteria
                                                                sep   = `, ` ) ).
          " requested elements
          DATA(lt_req_elements) = io_request->get_requested_elements( ).

          DELETE lt_req_elements WHERE table_line = 'SUMMARY'.

          DATA(lo_aggregation) = io_request->get_aggregation( ).
          IF lo_aggregation IS BOUND.
            " aggregate
            DATA(lt_aggr_element) = lo_aggregation->get_aggregated_elements( ).

            IF lt_aggr_element IS NOT INITIAL.
              LOOP AT lt_aggr_element ASSIGNING FIELD-SYMBOL(<fs_aggr_element>).
                DELETE lt_req_elements WHERE table_line = <fs_aggr_element>-result_element.
                DATA(lv_aggregation) = |{ <fs_aggr_element>-aggregation_method }( { <fs_aggr_element>-input_element } ) as { <fs_aggr_element>-result_element }|.
                APPEND lv_aggregation TO lt_req_elements.
              ENDLOOP.
            ENDIF.
          ENDIF.

          DATA(lv_req_elements) = concat_lines_of( table = lt_req_elements
                                                   sep   = `, ` ).
          " grouping
          IF lo_aggregation IS BOUND.
            DATA(lt_grouped_element) = lo_aggregation->get_grouped_elements( ).
            DATA(lv_grouping) = concat_lines_of( table = lt_grouped_element
                                                 sep   = `, ` ).
          ENDIF.

          " select data
          SELECT (lv_req_elements) FROM zpru_purcorderhdr
            WHERE (lv_sql_filter)
            GROUP BY (lv_grouping)
            ORDER BY (lv_sort_string)
            INTO CORRESPONDING FIELDS OF TABLE @lt_root_select
                                   OFFSET @lv_offset
            UP TO @lv_max_rows ROWS.

          IF lt_root_select IS NOT INITIAL.
            lt_ids = VALUE #( FOR <ls_rs>
                              IN lt_root_select
                              ( sign   = 'I'
                                option = 'EQ'
                                low    = <ls_rs>-purchaseorderid ) ).

            SELECT * FROM zpru_ai_summary AS sum
              WHERE sum~purchase_order_id IN @lt_ids
              INTO TABLE @DATA(lt_saved_summary).
          ENDIF.

          LOOP AT lt_root_select ASSIGNING FIELD-SYMBOL(<ls_select_result>).
            APPEND INITIAL LINE TO lt_root_response ASSIGNING FIELD-SYMBOL(<ls_target>).
            <ls_target> = CORRESPONDING #( <ls_select_result> ).

            ASSIGN lt_saved_summary[ purchase_order_id = <ls_select_result>-purchaseorderid ]-summary TO FIELD-SYMBOL(<ls_summary>).
            IF sy-subrc = 0.
              <ls_target>-summary = <ls_summary>.
            ELSE.
              APPEND INITIAL LINE TO lt_root_for_ai ASSIGNING FIELD-SYMBOL(<ls_root_for_ai>).
              <ls_root_for_ai> = <ls_select_result>.
            ENDIF.
          ENDLOOP.

          IF lt_root_for_ai IS NOT INITIAL.
            CALL FUNCTION 'ZPRU_SUMMARIZE_ORDER_GEMINI'
              STARTING NEW TASK 'IL1'
              EXPORTING
                it_root_for_ai = lt_root_for_ai.
          ENDIF.

          " fill response
          io_response->set_data( lt_root_response ).
        ENDIF.
        " request count
        IF io_request->is_total_numb_of_rec_requested( ).
          " select count
          SELECT COUNT( * ) FROM zpru_purcorderhdr
            WHERE (lv_sql_filter)
            INTO @DATA(lv_root_count).
          " fill response
          io_response->set_total_number_of_records( lv_root_count ).
        ENDIF.

      CATCH cx_rap_query_provider.

    ENDTRY.
  ENDMETHOD.
ENDCLASS.
