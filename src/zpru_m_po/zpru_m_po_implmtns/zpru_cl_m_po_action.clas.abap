CLASS zpru_cl_m_po_action DEFINITION
  PUBLIC
  FINAL
  CREATE PUBLIC .

  PUBLIC SECTION.

    METHODS revalidatePricingRules.
    METHODS sendOrderStatisticToAzure.
    METHODS ChangeStatus.
    METHODS createFromTemplate.

  PROTECTED SECTION.
  PRIVATE SECTION.
ENDCLASS.



CLASS zpru_cl_m_po_action IMPLEMENTATION.
  METHOD changestatus.
  " Change field Zpru_PurcOrderHdr_tp~status.
  ENDMETHOD.

  METHOD createfromtemplate.
  " Takes a template ID or last PO and pre-fills common fields (paymentTerms, buyerId).
  ENDMETHOD.

  METHOD sendOrderStatisticToAzure.

  ENDMETHOD.

  METHOD revalidatepricingrules.
  " Clears totalAmount, re-applies pricing logic.
  ENDMETHOD.

ENDCLASS.
