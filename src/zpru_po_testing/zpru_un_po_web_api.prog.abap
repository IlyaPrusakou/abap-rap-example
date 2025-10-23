*&---------------------------------------------------------------------*
*& Report zpru_un_po_web_api
*&---------------------------------------------------------------------*
*&
*&---------------------------------------------------------------------*
REPORT zpru_un_po_web_api.

DATA lo_http_client TYPE REF TO if_http_client.
DATA lv_ai_url      TYPE string.
DATA lv_response    TYPE string.

BREAK-POINT.

DATA lv_url    TYPE string.
DATA lv_result TYPE string.
DATA lv_status TYPE i.
DATA lv_reason TYPE string.
DATA code      TYPE sysubrc.

" Create HTTP client using the SM59 destination
cl_http_client=>create_by_destination( EXPORTING destination = 'IL'    " <-- your RFC destination name in SM59
                                       IMPORTING client      = lo_http_client ).

" Optional: set the specific resource path (e.g. entity set)
lv_url = '/purchaseOrder?sap-client=100'.

lo_http_client->request->set_header_field( name  = 'Accept'
                                           value = 'application/json' ).
lo_http_client->request->set_method( if_http_request=>co_request_method_get ).  " or POST, PUT, DELETE

cl_http_utility=>set_request_uri( request = lo_http_client->request
                                  uri     = lv_url ).

lo_http_client->send( EXCEPTIONS http_communication_failure = 1
                                 http_invalid_state         = 2
                                 http_invalid_timeout       = 3
                                 http_processing_failed     = 4
                                 OTHERS                     = 5 ).
IF sy-subrc = 0.
  lo_http_client->receive( EXCEPTIONS http_communication_failure = 1
                                      http_invalid_state         = 2
                                      http_processing_failed     = 4
                                      OTHERS                     = 5 ).
ENDIF.

DATA(http_response) = lo_http_client->response.
lo_http_client->response->get_status( IMPORTING code = code ).
DATA(response) = lo_http_client->response->get_cdata( ).
" Always close connection
lo_http_client->close( ).

BREAK-POINT.
