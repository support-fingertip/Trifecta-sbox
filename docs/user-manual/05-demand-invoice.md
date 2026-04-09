# 05 — Demand & Invoice

## Overview

A **Demand** is an invoice Trifecta sends to the customer asking them to
pay the next milestone (slab casting, plastering, possession, etc.) on
their chosen **Payment Plan**. This module covers single-booking demands,
revised demands, penalty / delay-interest demands, and bulk demand runs
across many bookings.

## Who uses it

- **Demands & Collections CRM Executive**
  (`Project__c.Demands_Collections_CRM_Executive__c`) — raises demand
  notes, sends reminders and reconciles payments.
- **Finance User** — approves special cases and reviews interest
  calculations.

## Key objects and tabs

| Object | Tab | Purpose |
|---|---|---|
| `Demand_Raised__c` | — (accessed via booking) | A demand note raised against a booking |
| `Master_Payment_Schedule__c` | Master Payment Schedule | Schedule the demand is drawn from |
| `Payment_schedule__c` | — | Milestone rows |
| `Interest_Percentage__c` | Interest Percentage | Delay interest slabs used for penalty demands |
| `Interest_Amount_Line_Item__c` | — | Interest calculated on a specific demand |
| `Additional_Charges__c` | — | Extra charges raised alongside a demand |

## Screens

| Screen | Type | Purpose |
|---|---|---|
| `DemandNote.page` | VF | Standard demand note PDF |
| `Demand_Invoice.page`, `Demand_Invioce_Custom.page` | VF | Demand invoice variants |
| `PenaltyDemandNote.page` | VF | Penalty / delay interest demand note |
| `Demand_Note_Send.page` | VF | Wrapper used when emailing the demand note |
| `RaiseDemandLetter` / `RaiseAllModalPopup` | Aura | Raise a single demand |
| `RevisiedDemand` | Aura | Raise a revised demand against an existing one |
| `PenaltyDemand` | Aura | Raise a penalty demand |
| `BulkRaiseDemand` / `ReDirectToBulkRaiseDemand` | Aura | Raise demands for many bookings at once |
| `GenerateDemandNote` / `GenerateDemandAdditionalCharge` | Aura | Generate demand PDFs |
| `raiseDemandEvent` | Aura event | Bubble to parent after a demand is raised |

## Workflows

### 1. Raise a single demand note

1. Open the booking and confirm the `Master_Payment_Schedule__c` and the
   milestone (`Payment_schedule__c`) you are demanding against.
2. Click **Raise Demand Letter** (Aura `RaiseDemandLetter`). A modal
   opens (`RaiseAllModalPopup`).
3. Choose the milestone and click confirm. The controller creates a
   `Demand_Raised__c` record with:
   - `Booking__c`, `Booking_Name__c`
   - `Payment_schedule__c`
   - `Milestone_Percentage__c`, `Total_Percentage_till_Current_Milestone__c`
   - `Amount_Demanded__c`, `Current_Demand_amount__c`
   - `Current_Milestone_Excluding_the_TDS__c`,
     `Current_Milestone_TDS_1__c`
   - `Previous_pendings__c`, `Pending_Dues_excluding_TDS__c`,
     `Pending_Payment_TDS_1__c`
   - `GST__c`, `Grand_Total__c`, `Grand_Total_in_Words__c`
   - `Due_Date__c`, `Payment_Due_Date__c`
4. The `DemandRaisedTrigger` fires, runs final calculations and sets
   `Demand_Status__c` = Raised.
5. Click **Generate Demand Note** (Aura `GenerateDemandNote`) to open
   `DemandNote.page` as a PDF.

### 2. Email the demand note to the customer

1. From the saved demand, click **Send** / **Generate & Send** — this
   opens `Demand_Note_Send.page` which emails the PDF to the booking
   owner email on file.
2. `Demand_Email_Send__c` and `Demand_Email_Content__c` are set
   accordingly.
3. The reminder dates `X1st_Reminder_Date__c`, `X2nd_Reminder_Date__c`
   are auto-populated for the scheduled reminder batch.
4. If the admin has set `Disable_Demand_Mail__c` on the project, the
   email will not be sent automatically.

### 3. Raise a revised demand

If the original demand needs correction (customer amended cost sheet,
incorrect milestone, etc.):

1. Open the original demand.
2. Click **Revisied Demand** (Aura `RevisiedDemand`).
3. Adjust the amount / milestone, save. A new `Demand_Raised__c` is
   created linked back to the original.
4. Both the original and revised demand are visible on the booking's
   demand related list — keep the original for audit.

### 4. Raise a penalty (delay interest) demand

When the customer pays after the due date, calculate interest using the
**Interest Percentage** slabs:

1. From the booking click **Penalty Demand** (Aura `PenaltyDemand`).
2. The component reads the configured `Interest_Percentage__c` rows, the
   `Interest_Rate__c` on the project, and the `Intrest_Percentage__c` on
   the block, and calculates the interest between the due date and the
   actual payment date.
3. Review the calculation, save. A `Demand_Raised__c` of type penalty is
   created; `Include_Interest__c` is true and `Interest_Till_Now__c` is
   populated.
4. Click **Generate Demand Note** / open `PenaltyDemandNote.page` to
   produce the PDF.

### 5. Bulk raise demands

1. Open the **Bulk Raise Demand** action (Aura `BulkRaiseDemand`,
   controller `BulkRaiseDemandController`).
2. Filter the bookings you want to demand against — for example all
   bookings in a given project/block whose next milestone is due this
   month.
3. Preview the totals and confirm. Demands are raised in batch.
4. Use this action at the end of each milestone cycle to avoid raising
   demands booking by booking.

### 6. Send pre-termination and termination mails

The demand record tracks two escalation dates —
`Pre_Termination_Mail_Date__c` and `Termination_Mail_Date__c`. These are
used by the scheduled reminder jobs:

- `AgreementPaymentReminderScheduler`
- `AgreementReminderScheduler`
- `AgreementPaymentReminderBatch`

These Apex schedulers pick up demands whose reminder/termination dates
have passed and fire the corresponding emails automatically.

## Key fields on `Demand_Raised__c`

| Field | Purpose |
|---|---|
| `Booking__c`, `Booking_Name__c` | Parent booking |
| `Payment_schedule__c` | Milestone this demand relates to |
| `Milestone_Percentage__c` | Percentage due at this milestone |
| `Total_Percentage_till_Current_Milestone__c` | Cumulative percentage |
| `Amount_Demanded__c`, `Current_Demand_amount__c` | Current demand amount |
| `Current_Milestone_Excluding_the_TDS__c` | Principal portion |
| `Current_Milestone_TDS_1__c` | TDS portion |
| `Previous_pendings__c` | Any unpaid amounts from prior demands |
| `Pending_Dues_excluding_TDS__c`, `Pending_Payment_TDS_1__c` | Outstanding after this demand |
| `Include_Interest__c`, `Interest_Till_Now__c`, `Total_Interest__c`, `Total_Interest_Paid__c` | Interest handling |
| `GST__c`, `Grand_Total__c`, `Grand_Total_in_Words__c` | Totals |
| `Due_Date__c`, `Payment_Due_Date__c` | When the customer must pay |
| `Demand_Email_Send__c`, `Demand_Email_Content__c`, `Disable_Demand_Mail__c` | Email status |
| `X1st_Reminder_Date__c`, `X1st_Reminder_Date_with_Interest__c`, `X2nd_Reminder_Date__c`, `X2nd_Reminder_Interest_Date__c`, `X3rd_Reminder_Interest_Date__c` | Reminder schedule |
| `Pre_Termination_Mail_Date__c`, `Termination_Mail_Date__c` | Escalation dates |
| `Demand_Status__c` | Raised / Cancelled / Paid |

## Automations you will experience

| Flow / Trigger / Batch | When it fires | Effect |
|---|---|---|
| `DemandRaisedTrigger` | Insert/update of demand | Calculations, status updates |
| `InterestPercentageTrigger` | Change to the interest slab | Keeps dependent demands current |
| `PaymentScheduleTrigger`, `MasterPaymentScheduleTrigger` | Schedule changes | Recalculates totals |
| `AgreementPaymentReminderScheduler` / `AgreementReminderScheduler` | Scheduled daily | Sends reminder / termination emails |
| `BookingDemandInvoice` (Apex) | Called from UI | Generates demand invoice data |

## Common issues and tips

- **Demand amount is zero**: check that the `Payment_schedule__c` has a
  non-zero percentage and that `Master_Payment_Schedule__c` is finalised.
- **Reminder not going out**: confirm the scheduled Apex jobs
  `AgreementPaymentReminderScheduler` and `AgreementReminderScheduler`
  are active in the org, and `Disable_Demand_Mail__c` is not set on the
  project or booking.
- **Penalty demand interest looks wrong**: check the
  `Interest_Percentage__c` slabs and the project-level `Interest_Rate__c`
  and `Block__c.Intrest_Percentage__c`. Only one slab should apply to
  the given delay period.
- **Bulk demand run skipped some bookings**: bookings whose
  `All_Payment_Clear__c` is true or whose status is Cancelled are
  skipped by design.
- Do not manually edit `Grand_Total__c` — it's rolled up from the
  principal, TDS, previous pending and interest fields.
