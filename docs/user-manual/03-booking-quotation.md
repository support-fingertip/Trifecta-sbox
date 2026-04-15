# 03 — Booking & Quotation

## Overview

A **Quote** is a cost sheet that details the price breakdown for a unit
before the customer commits. A **Booking** is the formal record created
when the customer pays the booking amount and signs the booking form. This
module covers the full path from cost sheet generation through booking
creation, approval and stage tracking.

## Who uses it

- **Sales Executive** — creates the quote, shares the cost sheet,
  initiates the booking.
- **New Booking CRM Executive**
  (`Project__c.New_Booking_CRM_Executive__c`) — validates the booking
  form and uploads supporting documents.
- **Sales Head / CRM Manager / COO** — approvers for discounts and
  bookings.
- **Finance User** — confirms the booking amount has been received before
  the booking is moved to "Booked" stage.

## Key objects and tabs

| Object | Tab | Purpose |
|---|---|---|
| `Quote__c` | Quote | Cost sheet / quotation |
| `Booking__c` | Booking | Primary booking record |
| `Co_Applicant__c` | Co Applicant | Additional applicants on the booking |
| `Payment_Plan__c` | Payment Plan | Milestone template chosen at booking |
| `Master_Payment_Schedule__c` | Master Payment Schedule | Per-booking payment schedule generated from the plan |
| `Additional_Charges__c` | — | Per-unit extra charges (club house, parking, etc.) |

## Screens

### Booking forms (Visualforce)

Multiple form variants exist for different property / project types:

| Page | Used for |
|---|---|
| `BookingForm.page` | Standard flat booking |
| `BookingFormZGC.page` | Project-specific variant |
| `Trifecta_Booking_Form.page` | Trifecta master flat form |
| `TrifectaRowHouseBookingForm.page` | Row house |
| `ConstructionVillaBookingForm.page` | Under-construction villa |
| `LandVillaBookingForm.page` | Land + villa |
| `PublicBookingForm.page` | Customer-facing public form |

### Cost sheet / quotation pages

| Page | Used for |
|---|---|
| `CostSheet.page` | Generic cost sheet |
| `TrifectaCostsheet.page` | Trifecta flats |
| `TrifectaRowHouseCostSheet.page` | Row house |
| `trifectaVillaCostSheet.page` | Villa |
| `ZuariCostSheet.page` | Project-specific (Zuari) |
| `MantriquotationVF.page` / `MantriquotationVFP.page` | Project-specific (Mantri) |

### LWC / Aura components

| Component | Role |
|---|---|
| `Quote` / `CreateQuote` / `CreateQuoteComponent` | Initiates quote creation |
| `GenerateQuotePDF` | Produces the printable quote PDF |
| `BookingForm` / `BookingFormApp` | Booking form wrapper |
| `CreateBooking` | Entry point from a lead or quote |
| `BookingfileUploader`, `CoApplicantFileUPloader`, `BookingDocumentUpload` | KYC & document upload |
| `BookkingSummary` | Read-only booking summary (Aura `BookkingSummary`, Apex `BookingSummaryController`) |
| `bookingStageUpdate` / `MarkBookingStageCompleted` | Advances the booking through its stages |
| `customApprovalPanel` | Panel used by approvers to act on pending bookings/quotes |

## Workflows

### 1. Create a quote (cost sheet)

1. From the lead, site visit or directly from the Plot (unit) record,
   click **Create Quote** (Aura `CreateQuote`).
2. Select the unit (`Plot__c` via `Block_Lookup__c` / `Block__c`).
3. The form pre-fills pricing from the Plot master (basic cost, PLC,
   car parking, club house, corpus fund, maintenance charges, GST, etc.).
4. Adjust discount fields if allowed:
   - `Discount__c`, `Discount_Amount__c`, `Discount_in_Percentage__c`
   - The discount must fall within the `Discount_Limit__c` /
     `Project_Discount_Limit__c` configured by admins. Larger discounts
     require approver sign-off.
5. Populate `Approver_1__c`, `Approver_2__c` if the cost sheet needs
   review.
6. Click **Save**. The `QuoteTrigger` fires and `Approval_status__c` is
   initialised.
7. Click **Generate Quote PDF** (Aura `GenerateQuotePDF`) to create the
   printable cost sheet.

### 2. Submit a quote for approval

1. Open the quote and click **Submit For Approval** — this triggers the
   **Submit_For_Approval** / **Quote Approval Process** flows.
2. The approver receives an in-app notification ("Quote Approval
   Notification" flow) and opens the quote via the `customApprovalPanel`
   Aura component or directly via the `QuoteApprovalUIPanelController`.
3. The approver either approves or rejects. `Approval_status__c` updates
   accordingly.

### 3. Create a booking

1. Once the quote is approved, from the quote record (or from the lead)
   click **Create Booking** (Aura `CreateBooking`).
2. Fill the **Booking Form** (VF page variant appropriate to the project /
   unit type). Key sections:
   - **Applicant details**: `Applicant_Name__c`, `Applicant_Mobile_Number__c`,
     `Aadhar_No__c`, `Age__c`, `Annual_Income__c`,
     `Applicant_Company_Name__c`
   - **Unit & pricing**: inherited from the quote — basic cost, PLC,
     car parking, amenity charges, club house, corpus fund, GST,
     agreement value
   - **Booking amount**: `Booking_Amount__c`, `Booking_Date__c`
   - **Funding**: `Bank_Name__c`, `Branch_Name__c`, `Bank_Email__c`,
     `Banker_DSS__c`
3. Upload supporting documents (PAN, Aadhaar, photograph) via
   `BookingfileUploader` / `BookingDocumentUpload`. Flags
   `Aadhaar_Uploaded__c`, `Applicant_Photo_Uploaded__c`,
   `Building_Plan_Uploaded__c` update automatically.
4. Click **Save**. The `BookingTrigger` runs, the unit's status on
   `Plot__c` changes to blocked/booked, and a `Master_Payment_Schedule__c`
   is generated from the selected `Payment_Plan__c`.

### 4. Add co-applicants

1. From the booking, open the **Co Applicant** related list and click
   **New**.
2. Fill:
   - `Aadhar_Number__c`
   - `Date_of_Birth__c`, `Age__c`
   - `Marital_Status__c`, `Nationality__c`
   - `Communication_Address__c`, `Office_Address__c`
   - `Employeed_at__c`, `Designation__c`, `Industry__c`
   - `Annual_House_Hold_Income__c`
3. Upload the co-applicant documents via `CoApplicantFileUPloader`.
4. Use **Swap First Applicant** (Aura `SwapFirstApplicantButton`) if you
   need to promote a co-applicant to primary applicant later.

### 5. Submit the booking for approval

1. Click **Submit For Approval** on the booking.
2. The **Submit_For_Approval** flow routes the record based on the
   booking's discount, total agreement value and project rules
   (`Approval_Criteria__c` on related objects).
3. Approvers receive notifications via the **Booking approval notification**
   flow. They act via the booking record or the `customApprovalPanel`.
4. On approval, `Approval_status__c` = Approved, `Booking_Approval_Time__c`
   is set, and the booking can be moved to the next stage.

### 6. Advance booking stages

Use **Mark Booking Stage Completed** (Aura `MarkBookingStageCompleted`,
Apex `BookingStageController`) to move through stages such as:

1. **Booking Initiated** — booking form filled, waiting for approval.
2. **Booked** — after Finance confirms the booking amount receipt;
   `Booking_Moved_To_Booked_Stage_Time__c` records the timestamp.
3. **Agreement** — sale agreement drafted, executed and uploaded.
4. **Registration** — handled by the Registration CRM Executive.
5. **Possession Handover** — handled by the Possession Handover CRM
   Executive (see [Document Generation](09-document-generation.md)).

### 7. Swap a unit

If the customer wants to move to a different unit after booking, use
**Swapping Unit** (Aura `SwappingUnitComponent`, Apex
`SwappingUnitController`). The component updates both plots' statuses,
carries forward receipts and recalculates the payment schedule.

### 8. Generate the booking PDF / summary

- **Booking Summary** (Aura `BookkingSummary`) displays a read-only summary
  for sharing with the customer.
- **Booking PDF** is generated via `BookingPDFController`.

## Key fields on `Booking__c`

Only the high-traffic fields are listed. The object has ~330 fields; see
`force-app/main/default/objects/Booking__c/fields/` for the full catalogue.

**Applicant**
`Applicant_Name__c`, `Applicant_Mobile_Number__c`,
`Alternate_Contact_No__c`, `Applicant_Company_Name__c`, `Aadhar_No__c`,
`Age__c`, `Address__c`, `Anniverssary_Date__c`, `Annual_Income__c`,
`Annual_House_Hold_Income__c`

**Unit & pricing**
`Block_Name__c`, `Block_Id__c`, `Basic_Cost__c`,
`Additional_Car_Parking_Charges__c`, `Amenity_Charges__c`,
`Bescom_Charges__c`, `Booking_Amount__c`, `Agreement_Value__c`,
`Agreement_Value_Before_GST__c`, `Car_Parking_Amount__c`,
`Carpet_Area__c`

**Booking lifecycle**
`Booking_Date__c`, `Booking_Form_Sent__c`, `Booking_Approval_Time__c`,
`Booking_Moved_To_Booked_Stage_Time__c`, `Booking_Summary__c`,
`All_Payment_Clear__c`, `Approval_status__c`

**Ownership / roles**
`CRM_Head__c`, `CRM_Manager__c`, `CRM_executive__c`,
`Agreement_CRM_Executive__c`, `Cancellation_CRM_Executive__c`,
`COO__c`, `Booing_Executive_Email_Id__c`,
`CRM_Head_Manager_Email__c`, `CRM_Executive_Contact_No__c`

## Automations you will experience

| Flow / Trigger | When it fires | Effect |
|---|---|---|
| `QuoteTrigger` | Quote insert/update | Keeps `Approval_status__c` and related fields consistent |
| `Quote_Approval_Process` | Quote submitted | Routes the approval |
| `Quote_Approval_Notification` | Quote submitted / acted on | In-app notification |
| `BookingTrigger` | Booking insert/update | Syncs unit status, creates payment schedule, totals |
| `Booking_approval_notification` | Booking submitted | Notifies approvers |
| `Submit_For_Approval` | User clicks Submit For Approval | Drives approval routing |
| `Customer_Approval_Form` | Customer-facing approval | Captures sign-off |
| `Update_Unit_Status` | Booking / cancellation | Updates the Plot `Status__c` |
| `Sync_Credit_Source_from_Lead` | Booking create | Copies credit source from lead |

## Common issues and tips

- **Discount rejected**: check the discount is within
  `Project_Discount_Limit__c`. If not, it will need a higher-level
  approver.
- **"Unit not available" when creating a booking**: another booking may
  have already blocked the unit. Refresh the Plot record or the Inventory
  Management tab.
- **Payment schedule blank after booking**: confirm a `Payment_Plan__c`
  was selected on the booking — the schedule is generated from the plan.
- **Co-applicant KYC missing**: the booking cannot be moved to Agreement
  stage until all applicants have uploaded PAN, Aadhaar and photograph.
- **Approval stuck**: check that `Approver_1__c` and `Approver_2__c` are
  set and that both users are active and have notification access.
