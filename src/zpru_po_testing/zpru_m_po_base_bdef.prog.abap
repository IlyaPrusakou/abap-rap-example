*&---------------------------------------------------------------------*
*& Report zpru_m_po_base_bdef
*&---------------------------------------------------------------------*
*&
*&---------------------------------------------------------------------*
REPORT zpru_m_po_base_bdef.

" CREATE ACTIVE INSTANCE
DATA lt_create_PO_in  TYPE TABLE FOR CREATE Zpru_PurcOrderHdr_tp\\OrderTP.
DATA lt_create_ITM_in TYPE TABLE FOR CREATE Zpru_PurcOrderHdr_tp\\OrderTP\_items_tp.
DATA lT_root_k        TYPE TABLE FOR KEY OF Zpru_PurcOrderHdr_tp\\OrderTP.
DATA lT_item_k        TYPE TABLE FOR KEY OF Zpru_PurcOrderHdr_tp\\ItemTP.

BREAK-POINT.

lt_create_PO_in = VALUE #( headerCurrency = 'USD'
                           ( purchaseOrderId = '00000000000000000001'
                             orderDate       = '20260131'
                             supplierId      = zpru_if_m_po=>cs_supplier-sup1
                             buyerId         = zpru_if_m_po=>cs_buyer-buy1
                             deliveryDate    = '20260220'
                             paymentTerms    = zpru_if_m_po=>cs_payment_methods-advance
                             shippingMethod  = zpru_if_m_po=>cs_shipping_method-sea )
                           ( purchaseOrderId = '00000000000000000002'
                             orderDate       = '20270131'
                             supplierId      = zpru_if_m_po=>cs_supplier-sup2
                             buyerId         = zpru_if_m_po=>cs_buyer-buy2
                             deliveryDate    = '20270220'
                             paymentTerms    = zpru_if_m_po=>cs_payment_methods-post
                             shippingMethod  = zpru_if_m_po=>cs_shipping_method-air ) ).

MODIFY ENTITIES OF Zpru_PurcOrderHdr_tp
       ENTITY OrderTP
       CREATE AUTO FILL CID FIELDS ( purchaseOrderId
                                     orderDate
                                     supplierId
                                     buyerId
                                     headerCurrency
                                     deliveryDate
                                     paymentTerms
                                     shippingMethod ) WITH lt_create_PO_in
       MAPPED DATA(ls_PO_mapped)
       REPORTED DATA(ls_PO_reported)
       FAILED DATA(ls_PO_failed).

lt_create_ITM_in = VALUE #(
    ( purchaseorderid = '00000000000000000001'
      %pid            = VALUE #( ls_PO_mapped-ordertp[ KEY entity
                                                       COMPONENTS purchaseOrderId = '00000000000000000001' ]-%pid  OPTIONAL )
      %target         = VALUE #( purchaseOrderId = '00000000000000000001'
                                 itemCurrency    = 'USD'
                                 ( itemId       = '00000000000000000001'
                                   itemNumber   = 1
                                   productId    = 'PROD1'
                                   productName  = 'PROD1 NAME'
                                   quantity     = 13
                                   unitPrice    = '120'
                                   deliveryDate = '20260220' )
                                 ( itemId       = '00000000000000000002'
                                   itemNumber   = 2
                                   productId    = 'PROD2'
                                   productName  = 'PROD2 NAME'
                                   quantity     = 16
                                   unitPrice    = '220'
                                   deliveryDate = '20270220' ) ) )
    ( purchaseorderid = '00000000000000000002'
      %pid            = VALUE #( ls_PO_mapped-ordertp[ KEY entity
                                                       COMPONENTS purchaseOrderId = '00000000000000000002' ]-%pid  OPTIONAL )
      %target         = VALUE #( purchaseOrderId = '00000000000000000002'
                                 itemCurrency    = 'USD'
                                 ( itemId       = '00000000000000000001'
                                   itemNumber   = 1
                                   productId    = 'PROD1'
                                   productName  = 'PROD1 NAME'
                                   quantity     = 13
                                   unitPrice    = '120'
                                   deliveryDate = '20260220' )
                                 ( itemId       = '00000000000000000002'
                                   itemNumber   = 2
                                   productId    = 'PROD2'
                                   productName  = 'PROD2 NAME'
                                   quantity     = 16
                                   unitPrice    = '220'
                                   deliveryDate = '20270220' ) ) ) ).

MODIFY ENTITIES OF Zpru_PurcOrderHdr_tp
       ENTITY OrderTP
       CREATE BY \_items_tp AUTO FILL CID FIELDS ( itemId
                                                   purchaseOrderId
                                                   productId
                                                   productName
                                                   quantity
                                                   unitPrice
                                                   deliveryDate
                                                   itemCurrency
                                                   isUrgent
                                                   createdBy
                                                   createOn
                                                   changedBy
                                                   changedOn ) WITH lt_create_ITM_in
       MAPPED DATA(ls_ITM_mapped)
       REPORTED DATA(ls_ITM_reported)
       FAILED DATA(ls_ITM_failed).

COMMIT ENTITIES BEGIN RESPONSE OF Zpru_PurcOrderHdr_tp FAILED DATA(ls_failed_commit) REPORTED DATA(ls_reported_commit).

LOOP AT ls_PO_mapped-ordertp ASSIGNING FIELD-SYMBOL(<LS_ORDER_mapped_early>).

  IF line_exists( ls_failed_commit-ordertp[ KEY id COMPONENTS %tky = <LS_ORDER_mapped_early>-%tky ] ).
    CONTINUE. " Skip failed one
  ENDIF.

  APPEND INITIAL LINE TO lT_root_k ASSIGNING FIELD-SYMBOL(<ls_order_K>).
  CONVERT KEY OF Zpru_PurcOrderHdr_tp\\OrderTP
          FROM TEMPORARY VALUE #( %pid                 = <LS_ORDER_mapped_early>-%pky-%pid
                                  %tmp-purchaseOrderId = <LS_ORDER_mapped_early>-%pky-purchaseOrderId ) TO <ls_order_K>.
ENDLOOP.

LOOP AT ls_ITM_mapped-itemtp ASSIGNING FIELD-SYMBOL(<LS_ITEM_mapped_early>).

  IF line_exists( ls_failed_commit-itemtp[ KEY id COMPONENTS %tky = <LS_ITEM_mapped_early>-%tky ] ).
    CONTINUE. " Skip failed one
  ENDIF.

  APPEND INITIAL LINE TO lT_item_k ASSIGNING FIELD-SYMBOL(<ls_item_k>).
  CONVERT KEY OF Zpru_PurcOrderHdr_tp\\ItemTP
          FROM TEMPORARY VALUE #( %pid                 = <LS_ITEM_mapped_early>-%pid
                                  %tmp-purchaseOrderId = <LS_ITEM_mapped_early>-purchaseOrderId
                                  %tmp-itemId          = <LS_ITEM_mapped_early>-itemId ) TO <ls_item_k>.
ENDLOOP.

COMMIT ENTITIES END.

READ ENTITIES OF Zpru_PurcOrderHdr_tp
     ENTITY OrderTP
     ALL FIELDS WITH CORRESPONDING #( lT_root_k )
     RESULT DATA(lt_roots).

READ ENTITIES OF Zpru_PurcOrderHdr_tp
     ENTITY ItemTP
     ALL FIELDS WITH CORRESPONDING #( lT_item_k )
     RESULT DATA(lt_items).

BREAK-POINT.
