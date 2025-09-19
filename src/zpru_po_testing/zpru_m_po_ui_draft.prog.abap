*&---------------------------------------------------------------------*
*& Report zpru_m_po_ui_draft
*&---------------------------------------------------------------------*
*&
*&---------------------------------------------------------------------*
REPORT zpru_m_po_ui_draft.

" CREATE BUTTON ON UI IS TRIGGERED
" DATA CREATED IN DATA BASE TABLES
*POST purchaseOrder?sap-client=100 HTTP/1.1
*{"purchaseOrderId":"13","headerCurrency":"USD"}


" UPDATE FIELDS ON ROOT NODE
" EACH PATCH IS SAVED DIRECTLY INTO DRAFT DATABASE TABLE
*PATCH purchaseOrder(purchaseOrderId='13',DraftUUID=edcbabb3-bfd7-1fe0-a5a6-eaf60cc9b7d9,IsActiveEntity=false)
*{"orderDate":"2027-08-22"}

*PATCH purchaseOrder(purchaseOrderId='13',DraftUUID=edcbabb3-bfd7-1fe0-a5a6-eaf60cc9b7d9,IsActiveEntity=false)
*{"supplierId":"SUP1"}

*PATCH purchaseOrder(purchaseOrderId='13',DraftUUID=edcbabb3-bfd7-1fe0-a5a6-eaf60cc9b7d9,IsActiveEntity=false)
*{"buyerId":"BUY1"}

*PATCH purchaseOrder(purchaseOrderId='13',DraftUUID=edcbabb3-bfd7-1fe0-a5a6-eaf60cc9b7d9,IsActiveEntity=false)
*{"deliveryDate":"2027-08-23"}

" CREATE ITEM
" PO ITEM IS SAVED DIRECTLY IN DRAFT DATA BASE TABLE
*POST purchaseOrder(purchaseOrderId='13',DraftUUID=edcbabb3-bfd7-1fe0-a5a6-eaf60cc9b7d9,IsActiveEntity=false)/_items_tp
*{"itemId":"1","purchaseOrderId":"13","quantity":15,"productId":"PROD1","unitPrice":"10","itemCurrency":"USD"}

" PREPARE ACTION
*POST purchaseOrder(purchaseOrderId='13',DraftUUID=edcbabb3-bfd7-1fe0-a5a6-eaf60cc9b7d9,IsActiveEntity=false)/com.sap.gateway.srvd.zpru_purcorderhdr_odata.v0001.Prepare
*{}

" ACTIVATE ACTION
*POST purchaseOrder(purchaseOrderId='13',DraftUUID=edcbabb3-bfd7-1fe0-a5a6-eaf60cc9b7d9,IsActiveEntity=false)/com.sap.gateway.srvd.zpru_purcorderhdr_odata.v0001.Activate
*{}
