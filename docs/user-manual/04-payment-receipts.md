# 04 — Receipts & Payments

## Overview

This module covers capturing customer payments against a booking. Each
payment is recorded as a **Receipt** (`Receipt__c`), split into one or more
**Receipt Line Items** (`Receipt_Line_Item__c`) that allocate the received
amount across the booking's payment schedule milestones. Receipts are
approved by Finance, converted into PDFs and emailed to the customer.

## Who uses it

- **Finance User** (`Project__c.Finance_User__c`) — creates, approves and
  reconciles receipts.
- **Demands & Collections CRM Executive** — follows up on outstanding
  payments and uploads bank confirmations.
- **CRM Executive** — can view receipts on their booking but usually does
  not create them.

## Key objects and tabs

| Object | Tab | Purpose |
|---|---|---|
| `Receipt__c` | Receipt | Header record for a payment received |
| `Receipt_Line_Item__c` | — (related list on Receipt) | Allocation of the receipt amount to specific demands / milestones |
| `Interest_Amount_Line_Item__c` | — | Interest amount paid on the receipt |
| `Master_Payment_Schedule__c` | Master Payment Schedule | Booking-level schedule the receipt is applied against |
| `Payment_schedule__c` | — | Milestone rows within the master schedule |

## Screens

| Screen | Type | Purpose |
|---|---|---|
| `Receipt.page` | VF | Printable receipt |
| `ConsolidatedReceipt.page` | VF | Consolidated view across all receipts |
| `GenerateReceipt` / `GenerateReceiptPDF` | Aura | Create a receipt and its PDF |
| `GenerateConsolidatedReceipt` / `ConstructionConsolidatedReceipt` | Aura | Consolidated receipt generation |
| `ReceiptComponentSampleDevComp` | Aura | Receipt creation panel |
| `RedirectToRecieptComponent` | Aura | Quick action that opens the receipt form |
| `SendReceiptButton` / `SendReceiptPopup` / `SendReceiptToCustomer` | Aura | Sends the receipt PDF to the customer |

## Workflows

### 1. Record a new receipt

1. Open the booking and click **Generate Receipt** (Aura
   `GenerateReceipt`) — or click **New** on the **Receipts** related list.
2. Fill the header fields:
   - `Booking__c` (auto-populated when launched from a booking)
   - `Receipt_Date__c`
   - `Mode_Of_Payment__c` — cheque, NEFT, RTGS, UPI, cash, etc.
   - `Amount_Received__c`
   - `Bank_Name__c`, `Branch__c`, `Drawn_On__c` (if applicable)
   - `Cheque_no_Transaction_Number__c` or
     `Check_Transaction_Nmber__c`
   - `Remarks__c`
3. Click **Save**. The `ReceiptTrigger` fires and the receipt number
   (`Receipt_No__c`, `Receipt_Name__c`) is generated.

### 2. Allocate the receipt across milestones

1. From the saved receipt, open the **Receipt Line Item** related list.
2. For each demand / milestone the customer is paying, create a line item
   and fill the amount applied. The `ReceiptLineIemTrigger` updates the
   corresponding `Payment_schedule__c` / `Demand_Raised__c` records and
   increases the booking's `Total_Received_Amount__c` and
   `Received_Amount_Without_Interest__c`.
3. If the payment includes delay interest, enter it on
   `Received_Interest_Amount__c` — an `Interest_Amount_Line_Item__c` row
   is created to track the interest component separately from principal.
4. The `Receipt_Line_Item_Updated` flow then recalculates the booking
   balances and updates the `All_Payment_Clear__c` flag on
   `Booking__c` if all milestones are cleared.

### 3. Submit the receipt for Finance approval

1. Click **Submit For Approval** on the receipt. This triggers the
   **Recipet Approval Notification** flow which notifies the Finance User
   configured on the Project.
2. `Approval_status__c` moves to Pending.
3. The Finance User approves or rejects from the record or the
   `customApprovalPanel`.

### 4. Generate and send the receipt PDF

1. After approval, click **Generate Receipt PDF** (Aura
   `GenerateReceiptPDF`). This opens `Receipt.page` (controller
   `ReceiptVFPController`) in PDF mode.
2. Save the PDF or click **Send Receipt** (Aura `SendReceiptButton` /
   `SendReceiptPopup` / `SendReceiptToCustomer`) to email it to the
   customer on file.

### 5. Generate a consolidated receipt

For customers who want a single statement covering all their payments to
date, use **Generate Consolidated Receipt** (Aura
`GenerateConsolidatedReceipt` — or the `ConstructionConsolidatedReceipt`
variant for construction-linked projects). The component aggregates every
`Receipt__c` linked to the booking into `ConsolidatedReceipt.page`.

### 6. View the account statement

Use the `AccountStatement.page` VF page (controller
`AccountStatementController`) for a booking-level statement showing
demands raised, receipts posted and outstanding balance.

## Key fields on `Receipt__c`

| Field | Required? | Notes |
|---|---|---|
| `Booking__c` | Yes | Parent booking |
| `Receipt_Date__c` | Yes | Date of payment |
| `Mode_Of_Payment__c` | Yes | Picklist of payment modes |
| `Amount_Received__c` | Yes | Gross amount received |
| `Receipt_Amount_Without_Tds__c` | Auto | Amount net of TDS, if applicable |
| `Received_Amount_Without_Interest__c` | Auto | Principal component |
| `Received_Interest_Amount__c` | Optional | Interest component |
| `Total_Received_Amount__c` | Auto | Rolled up across line items |
| `Bank_Name__c`, `Branch__c`, `Drawn_On__c` | Conditional | For cheque / DD payments |
| `Cheque_no_Transaction_Number__c` | Conditional | Cheque number / UTR |
| `Approval_status__c` | Auto | Pending / Approved / Rejected |
| `Finance_User__c` | Auto | Populated from the project |
| `Owner_Email_Id__c` | Auto | Customer email to send the receipt |
| `Type__c` | Yes | Receipt type — booking, demand, refund reversal, etc. |
| `Flat_Amount__c` | Auto | Amount attributable to the flat (excluding extras) |
| `Project_Block_Name__c` | Auto | For reporting |

## Key fields on `Receipt_Line_Item__c`

See `force-app/main/default/objects/Receipt_Line_Item__c/fields/` for
the full list. Typical fields to fill:

- `Receipt__c` — parent receipt
- `Payment_schedule__c` or `Demand_Raised__c` — milestone being paid
- Amount applied (principal + interest split)

## Automations you will experience

| Flow / Trigger | When it fires | Effect |
|---|---|---|
| `ReceiptTrigger` | Receipt insert/update | Assigns number, validates totals |
| `ReceiptLineIemTrigger` | Line item insert/update | Rolls up amounts to Receipt & Booking |
| `Receipt_Line_Item_Updated` (Flow) | Line item saved | Updates `All_Payment_Clear__c`, clears outstanding demand |
| `Recipet_Approval_Notification` | Receipt submitted for approval | Notifies Finance User |
| `PaymentScheduleTrigger`, `MasterPaymentScheduleTrigger` | Related schedule changes | Keeps schedule totals consistent |
| `AgreementPaymentReminderScheduler` (Scheduled Apex) | Nightly | Sends reminders for upcoming agreement payments |

## Common issues and tips

- Always set **Mode Of Payment** before entering amounts — some validation
  rules depend on it.
- If `All_Payment_Clear__c` does not turn true after a full payment, open
  the receipt line items and confirm every milestone was allocated and
  `Pending_Dues_excluding_TDS__c` on related demands is zero.
- For cheque bounces, do **not** delete the receipt. Create a negative
  receipt or a reversal entry so the audit trail remains intact.
- TDS: ensure the `Receipt_Amount_Without_Tds__c` and interest split are
  correct, otherwise downstream demand calculations will be wrong.
- The Finance User must be populated on the Project
  (`Project__c.Finance_User__c`) for the approval notification to reach
  anyone.
