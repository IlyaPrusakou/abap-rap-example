FUNCTION zpru_summarize_order_gemini.
*"----------------------------------------------------------------------
*"*"Local Interface:
*"  IMPORTING
*"     VALUE(IT_ROOT_FOR_AI) TYPE  ZPRU_TT_PURCORDERHDR
*"----------------------------------------------------------------------
  TYPES: BEGIN OF ts_part,
           text TYPE string, " preserves the full JSON text
         END OF ts_part.

  TYPES tt_parts TYPE STANDARD TABLE OF ts_part WITH EMPTY KEY.

  TYPES: BEGIN OF ts_content,
           parts TYPE tt_parts,
         END OF ts_content.

  TYPES: BEGIN OF ts_candidate,
           content      TYPE ts_content,
           role         TYPE string,
           finishreason TYPE string,
           avglogprobs  TYPE f,
         END OF ts_candidate.

  TYPES tt_candidates TYPE STANDARD TABLE OF ts_candidate WITH EMPTY KEY.

  TYPES: BEGIN OF ts_usage_metadata_details,
           modality   TYPE string,
           tokencount TYPE i,
         END OF ts_usage_metadata_details.

  TYPES tt_usage_metadata_details_tab TYPE STANDARD TABLE OF ts_usage_metadata_details WITH EMPTY KEY.

  TYPES: BEGIN OF ts_usage_metadata,
           prompttokencount        TYPE i,
           candidatestokencount    TYPE i,
           totaltokencount         TYPE i,
           prompttokensdetails     TYPE tt_usage_metadata_details_tab,
           candidatestokensdetails TYPE tt_usage_metadata_details_tab,
         END OF ts_usage_metadata.

  TYPES: BEGIN OF ty_response,
           candidates    TYPE tt_candidates,
           usagemetadata TYPE ts_usage_metadata,
           modelversion  TYPE string,
           responseid    TYPE string,
         END OF ty_response.

  DATA ls_parsed_response TYPE ty_response.
  DATA lt_root_for_ai     TYPE zpru_tt_purcorderhdr.
  DATA lo_http_client     TYPE REF TO if_http_client.
  DATA lv_ai_url          TYPE string.
  DATA lv_response        TYPE string.
  DATA lv_prompt          TYPE string.
  DATA lv_string_payload  TYPE string.
  DATA lv_order_string    TYPE string.
  DATA lt_zpru_ai_summary TYPE STANDARD TABLE OF zpru_ai_summary WITH EMPTY KEY.
  DATA ls_zpru_ai_summary TYPE zpru_ai_summary.

  lt_root_for_ai = it_root_for_ai.

  IF lt_root_for_ai IS INITIAL.
    RETURN.
  ENDIF.

  SELECT * FROM zpru_purcorderitem AS item
    FOR ALL ENTRIES IN @lt_root_for_ai
    WHERE item~purchaseorderid = @lt_root_for_ai-purchaseorderid
    INTO TABLE @DATA(lt_items).

  SORT lt_root_for_ai BY purchaseorderid.
  SORT lt_items BY purchaseorderid
                   itemid.

  LOOP AT lt_root_for_ai ASSIGNING FIELD-SYMBOL(<ls_root_for_ai>).

    " Append purchase order header
    lv_order_string = lv_order_string &&
      |# Purchase Order { <ls_root_for_ai>-purchaseorderid }{ cl_abap_char_utilities=>newline }| &&
      |Order Date: { <ls_root_for_ai>-orderdate }{ cl_abap_char_utilities=>newline }| &&
      |Supplier: { <ls_root_for_ai>-suppliername } ({ <ls_root_for_ai>-supplierid }){ cl_abap_char_utilities=>newline }| &&
      |Buyer: { <ls_root_for_ai>-buyername } ({ <ls_root_for_ai>-buyerid }){ cl_abap_char_utilities=>newline }| &&
      |Total Amount: { <ls_root_for_ai>-totalamount } { <ls_root_for_ai>-headercurrency }{ cl_abap_char_utilities=>newline }| &&
      |Delivery Date: { <ls_root_for_ai>-deliverydate }{ cl_abap_char_utilities=>newline }| &&
      |Status: { <ls_root_for_ai>-status }{ cl_abap_char_utilities=>newline }| &&
      |Payment Terms: { <ls_root_for_ai>-paymentterms }{ cl_abap_char_utilities=>newline }| &&
      |Shipping Method: { <ls_root_for_ai>-shippingmethod }{ cl_abap_char_utilities=>newline }{ cl_abap_char_utilities=>newline }| &&
      |## Items{ cl_abap_char_utilities=>newline }|.

    " Loop through items of this order
    LOOP AT lt_items ASSIGNING FIELD-SYMBOL(<ls_item>)
         WHERE purchaseorderid = <ls_root_for_ai>-purchaseorderid.

      lv_order_string = lv_order_string &&
        |### Item { <ls_item>-itemnumber }{ cl_abap_char_utilities=>newline }| &&
        |Product ID: { <ls_item>-productid }{ cl_abap_char_utilities=>newline }| &&
        |Quantity: { <ls_item>-quantity }{ cl_abap_char_utilities=>newline }| &&
        |Unit Price: { <ls_item>-unitprice } { <ls_item>-itemcurrency }{ cl_abap_char_utilities=>newline }| &&
        |Total Price: { <ls_item>-totalprice } { <ls_item>-itemcurrency }{ cl_abap_char_utilities=>newline }| &&
        |Delivery Date: { <ls_item>-deliverydate }{ cl_abap_char_utilities=>newline }| &&
        |Warehouse Location: { <ls_item>-warehouselocation }{ cl_abap_char_utilities=>newline }| &&
        |Urgent: { COND #( WHEN <ls_item>-isurgent = abap_true THEN 'Yes' ELSE 'No' ) }{ cl_abap_char_utilities=>newline }{ cl_abap_char_utilities=>newline }|.

    ENDLOOP.
    IF sy-subrc <> 0.
      lv_order_string = |{ lv_order_string }(No items){ cl_abap_char_utilities=>newline }|.
    ENDIF.

  ENDLOOP.

  lv_ai_url = 'https://generativelanguage.googleapis.com/v1beta/models/gemini-2.0-flash:generateContent'.

  " Create HTTP client by URL
  cl_http_client=>create_by_url( EXPORTING url    = lv_ai_url
                                 IMPORTING client = lo_http_client ).

  " Set HTTP method (GET by default, so this is optional)
  lo_http_client->request->set_method( if_http_request=>co_request_method_post ).
  " Set headers
  lo_http_client->request->set_header_field( name  = 'Content-Type'
                                             value = 'application/json' ).
  lo_http_client->request->set_header_field( name  = 'X-goog-api-key'
                                             value = 'API_KEY' ). " qqq replace with your key

  lv_prompt = |Summarize purchase orders from #TEXT, showing ID, order date, supplier,| &&
              | buyer, total amount, currency, delivery date, status, payment terms,| &&
              | shipping method, and item quantities with product IDs.{ cl_abap_char_utilities=>newline }| &&
              | Output is json string with two fields: purchase_order_id and summary.| &&
              | Field summary must not be JSON. It must be unstructured free text. | &&
              | Also, start summary text with date and time of summury generation.| &&
              | #TEXT to summarize:{ cl_abap_char_utilities=>newline }| &&
              |{ lv_order_string }|.

  lv_string_payload = |\{ "contents": [ \{ "parts": [ \{ "text": "{ lv_prompt }" \} ] \} ] \}|.

  " Set body
  lo_http_client->request->set_cdata( lv_string_payload ).
  " Send request
  lo_http_client->send( ).
  lo_http_client->receive( ).

  " Get response body
  lv_response = lo_http_client->response->get_cdata( ).

  /ui2/cl_json=>deserialize( EXPORTING json = lv_response
                             CHANGING  data = ls_parsed_response ).

  ASSIGN ls_parsed_response-candidates[ 1 ]-content-parts[ 1 ]-text TO FIELD-SYMBOL(<lv_llm_response>).
  IF sy-subrc = 0.
    DATA(lv_cleaned_string) = <lv_llm_response>.

    REPLACE FIRST OCCURRENCE OF '```json' IN lv_cleaned_string WITH ''.
    REPLACE ALL OCCURRENCES OF '```' IN lv_cleaned_string WITH ''.

    IF lines( lt_root_for_ai ) = 1.
      /ui2/cl_json=>deserialize( EXPORTING json = lv_cleaned_string
                                 CHANGING  data = ls_zpru_ai_summary ).
      APPEND ls_zpru_ai_summary TO lt_zpru_ai_summary.
    ELSE.
      /ui2/cl_json=>deserialize( EXPORTING json = lv_cleaned_string
                                 CHANGING  data = lt_zpru_ai_summary ).
    ENDIF.

    IF lt_zpru_ai_summary IS NOT INITIAL.
      MODIFY zpru_ai_summary FROM TABLE @lt_zpru_ai_summary.
      IF sy-subrc = 0.
        COMMIT WORK.
      ELSE.
        ROLLBACK WORK.
      ENDIF.
    ENDIF.
  ENDIF.
ENDFUNCTION.
