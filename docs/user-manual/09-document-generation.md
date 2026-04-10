# 09 — Document Generation

## Overview

At each stage of the post-sales lifecycle, the CRM Executive generates a
formal document for the customer — sale agreement, bank NOC, possession
letter, key handover letter, and so on. All of these documents are
produced from Visualforce pages populated from the `Booking__c`,
`Project__c`, `Block__c` and `Plot__c` records, and each has a variant
for flats, row houses, villas and land villas.

This page is the catalogue of every document the org can generate, who
typically generates it, and which button / component produces it.

## Who uses it

- **New Booking CRM Executive** — booking PDFs and quotes.
- **Agreement CRM Executive** — sale agreement and tripartite agreement.
- **Registration CRM Executive** — registration NOC and
  compulsory-registration notice.
- **Possession Handover CRM Executive** — possession letter, key
  handover letter, completion certificate, consent letter.
- **Legal Team** — reviews documents before despatch.

## Catalogue of documents

Each row lists the Visualforce page (in
`force-app/main/default/pages/`), the Aura component that triggers it,
and a one-line description.

### Quotation & booking documents

| Document | VF page | Aura trigger |
|---|---|---|
| Cost Sheet (generic) | `CostSheet.page` | `GenerateQuotePDF` |
| Trifecta Cost Sheet | `TrifectaCostsheet.page` | `GenerateQuotePDF` |
| Trifecta Villa Cost Sheet | `trifectaVillaCostSheet.page` | `GenerateQuotePDF` |
| Trifecta Row House Cost Sheet | `TrifectaRowHouseCostSheet.page` | `GenerateQuotePDF` |
| Zuari Cost Sheet | `ZuariCostSheet.page` | `GenerateQuotePDF` |
| Mantri Quotation | `MantriquotationVF.page`, `MantriquotationVFP.page` | `GenerateQuotePDF` |
| Booking Form (standard) | `BookingForm.page`, `Trifecta_Booking_Form.page` | `BookingForm` Aura |
| Booking Form (row house) | `TrifectaRowHouseBookingForm.page` | `BookingForm` Aura |
| Booking Form (villa, under-construction) | `ConstructionVillaBookingForm.page` | `BookingForm` Aura |
| Booking Form (land + villa) | `LandVillaBookingForm.page` | `BookingForm` Aura |
| Public Booking Form | `PublicBookingForm.page` | Exposed via public site |
| Booking Form (project variant ZGC) | `BookingFormZGC.page` | `BookingForm` Aura |

### Receipts & statements

| Document | VF page | Aura trigger |
|---|---|---|
| Receipt | `Receipt.page` | `GenerateReceipt`, `GenerateReceiptPDF` |
| Consolidated Receipt | `ConsolidatedReceipt.page` | `GenerateConsolidatedReceipt`, `ConstructionConsolidatedReceipt` |
| Account Statement | `AccountStatement.page` | Direct link from booking |

### Demand notes

| Document | VF page | Aura trigger |
|---|---|---|
| Demand Note | `DemandNote.page` | `GenerateDemandNote`, `RaiseDemandLetter` |
| Demand Invoice | `Demand_Invoice.page`, `Demand_Invioce_Custom.page` | `RaiseDemandLetter`, `GenerateDemandAdditionalCharge` |
| Demand Note Send wrapper | `Demand_Note_Send.page` | Send-to-customer action |
| Penalty Demand Note | `PenaltyDemandNote.page` | `PenaltyDemand` |

### Agreements

| Document | VF page | Aura trigger |
|---|---|---|
| Sale Agreement | `SaleAgreement.page` | `GenerateSaleAggrement`, `RequestForSaleAgreement` |
| Tripartite Agreement | `TRIPARTITE_AGREEMENT.page` | `GenerateSaleAggrement` |
| Power of Attorney | `PowerofAttorney.page` | `GenerateSaleAggrement` |
| Consent Letter | `Consent_Letter.page` | `GeneratePossestionletter` |

### NOCs and registration

| Document | VF page | Aura trigger |
|---|---|---|
| Builder NOC | `BuilderNoc.page`, `Builder_NOC.page` | `GenerateBankNOC` |
| Flat / Row House NOC | `FlatOrRowHouseNOC.page` | `GenerateBankNOC` |
| Villa NOC | `VillaNOC.page` | `GenerateBankNOC` |
| Villa Registration NOC | `VillaRegistrationNOC.page` | `GenerateBankNOC` |
| Compulsory Registration Notice | `Compulsory_Registration_Notice.page` | Manual generation |

### Possession & handover

| Document | VF page | Aura trigger |
|---|---|---|
| Completion Certificate | `Completion_Certificate.page` | `GeneratePocessionCertificate` |
| Possession Letter (generic) | `Possession_Letter.page` | `GeneratePossestionletter` |
| Flat Possession Letter | `FlatPossessionLetter.page` | `GeneratePossestionletter` |
| Row House Possession Letter | `RowHousePossessionLetter.page` | `GeneratePossestionletter` |
| Villa Possession Letter | `VillaPossessionLetter.page` | `GeneratePossestionletter` |
| Key Handover Letter (generic) | `Key_Handover_Letter.page` | `GenerateKeyHandOverLetter` |
| Flat Key Handover | `FlatKeyHandoverVfp.page` | `GenerateKeyHandOverLetter` |
| Row House Key Handover | `RowHouseKeyHandoverVfp.page` | `GenerateKeyHandOverLetter` |
| Villa Key Handover | `VillasKeyHandoverVfp.page` | `GenerateKeyHandOverLetter` |

### Cancellation documents

| Document | VF page | Aura trigger |
|---|---|---|
| Cancellation Letter Request | `Cancellation_Letter_Request.page` | `CancellationMail` |
| Cancellation Agreement | (generated via Apex) | `GenerateCancellationAgreement` |
| Credit Note | (generated via Apex) | `GenerateCreditNote` |

### Other

| Document | VF page | Aura trigger |
|---|---|---|
| Invitation For Inspection | `Invitation_For_Inspection.page` | Sent from inspection record |
| Letter of Undertaking (LOU) | (generated via Apex) | `GenerateLOU` |
| Agreement Time Extension Request | — | `RequestForAggrementTimeExtension`, `SubmitAgreementTimeExtension` |

## Standard workflow for generating a document

1. Open the relevant record (booking for customer documents, inspection
   for inspection documents, etc.).
2. Click the Aura button listed above. The button opens the
   Visualforce page in a new tab / embedded iframe, populated from the
   record.
3. Review the generated document on screen. If something is wrong,
   close the preview, correct the source record, and re-generate.
4. Download the PDF (Salesforce PDF rendering) or send it to the
   customer via the **Send** action. Audit flags on the booking track
   what has been sent (`Cancellation_Letter_Sent__c`,
   `Booking_Form_Sent__c`, `Agreement_Status__c`, etc.).

## Requesting a document

For agreements and time extensions, the CRM Executive does not create
the document directly — they raise a request:

- **Request For Sale Agreement** (Aura `RequestForSaleAgreement`) —
  raises a request to the Agreement CRM Executive.
- **Request For Sale Deed** (Aura `RequestForSaleDeed`) — raises a
  request to the Registration CRM Executive.
- **Request For Agreement Time Extension** (Aura
  `RequestForAggrementTimeExtension`, submit via
  `SubmitAgreementTimeExtension`) — asks for more time to execute the
  agreement. The **Agreement time Extension Approval Notification**
  flow notifies the approver. On approval the
  `UpdateTimeExtensionDate` Aura component updates
  `Agreement_Extension_Approved_Date__c` and re-runs the reminder
  scheduler.

## Key audit fields on `Booking__c`

Use these to confirm which documents have gone out:

- `Booking_Form_Sent__c`
- `Building_Plan_Uploaded__c`, `Aadhaar_Uploaded__c`,
  `Applicant_Photo_Uploaded__c`
- `Agreement_Status__c`, `Agreement_Executed_Date__c`,
  `Agreement_Execution_Date__c`
- `Agreement_Value__c`, `Agreement_Value_Before_GST__c`
- `Agreement_Expected_Date__c`, `Agreement_Extension_Approved_Date__c`
- `Agreement_Reminder_Date__c`
- `Cancellation_Letter_Sent__c`, `Cancellation_Agreement_Uploaded__c`

## Common issues and tips

- **PDF renders blank or with `!` characters**: a merge field on the
  page references a field that is blank on the booking. Open the
  record, fill the missing field, and regenerate.
- **Wrong document variant**: pick the VF page that matches the project
  / unit type — flats, villas, row houses and plots have separate
  pages. Check with your admin if you're unsure which page is wired to
  which button for your project.
- **Document generated but not emailed**: some buttons only generate the
  PDF; a separate **Send** action emails it. Check the
  `*_Sent__c` audit flag on the booking to know the current status.
- **Time extension not taking effect**: the extension flow must be
  approved. Check `Agreement_Extension_Approved_Date__c` and the
  approval status before assuming the extension is active.
