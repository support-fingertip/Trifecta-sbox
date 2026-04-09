# 06 — Booking Cancellation & Refund

## Overview

If a customer decides to cancel their booking, this module drives the
end-to-end process: capturing the cancellation request, securing the
necessary approvals, generating the cancellation agreement and letter,
reversing demands, refunding the eligible amount and releasing the unit
back into inventory.

## Who uses it

- **Cancellation CRM Executive** (`Project__c.Cancellation_CRM_Executive__c`,
  `Cancellation_User__c`) — drives the cancellation workflow.
- **Sales Manager / CRM Head / COO** — approvers, depending on
  cancellation charge and refund amount.
- **Finance User** — processes the refund.
- **Inventory Manager** — confirms the unit is released back to sale.

## Key objects and tabs

| Object | Tab | Purpose |
|---|---|---|
| `Booking__c` (cancellation fields) | Booking | Booking being cancelled |
| `Refund__c` | Refund | Refund record attached to a cancelled booking |

## Screens

| Screen | Type | Purpose |
|---|---|---|
| `BookingCancellationRequest` | Aura | Raise a cancellation request from a booking |
| `BookingCancellationApproval` | Aura | Approver panel for cancellations |
| `GenerateCancellationAgreement` | Aura | Generate the cancellation agreement PDF |
| `CancellationMail` | Aura | Send the cancellation letter / mail |
| `Cancellation_Letter_Request.page` | VF | Customer-facing cancellation letter request |
| `GenerateCreditNote` | Aura | Generate a credit note for the cancelled booking |

## Workflows

### 1. Raise a cancellation request

1. Open the booking to be cancelled.
2. Click **Booking Cancellation Request** (Aura
   `BookingCancellationRequest`, controller
   `BookingCancellationRequestController`).
3. Fill the cancellation request form:
   - `Cancellation_Reason__c`
   - `Cancellation_Description__c`
   - `Cancellation_Charge__c` (per project policy)
   - `Cancellation_Amount__c` (refundable to the customer)
4. Save. The `Cancellation_Status__c` moves to Requested and the
   **Booking Cancellation Request Initiated Notification** flow notifies
   the approver chain.

### 2. Review and approve the cancellation

1. The approver (Cancellation Approver / CRM Head / COO, depending on
   amount) opens the booking — the **Booking Cancellation Approval**
   panel (Aura `BookingCancellationApproval`, controller
   `BookingCancellationApprovalController`) shows the request details.
2. The approver validates the charge calculation and either approves or
   rejects.
3. On approval the **Booking Cancellation Notification flow** sends an
   in-app notification to the Cancellation CRM Executive and the
   Finance team, and the **Cancellation Process Finance Notification**
   flow alerts Finance that a refund will need to be processed.

### 3. Generate the cancellation agreement and letter

1. Click **Generate Cancellation Agreement** (Aura
   `GenerateCancellationAgreement`) to produce the legal agreement.
2. Click **Cancellation Mail** (Aura `CancellationMail`) to email the
   cancellation letter to the customer. The flags
   `Cancellation_Letter_Sent__c`, `Cancellation_Email_Sent__c` and
   `Cancellation_Email_Sent_Time__c` update automatically.
3. Upload the customer-signed cancellation agreement — the
   `Cancellation_Agreement_Uploaded__c` flag turns true.

### 4. Reverse demands and generate a credit note

1. From the booking, review the `Demand_Raised__c` records. Demands
   that were raised but unpaid should be cancelled (marked
   `Demand_Status__c` = Cancelled).
2. Click **Generate Credit Note** (Aura `GenerateCreditNote`) to produce
   the credit note covering the amount to be refunded, net of the
   cancellation charge.

### 5. Create the refund record

1. From the booking, click **New** on the **Refund** related list.
2. Fill the refund form:
   - `Booking__c`
   - `Refund_Amount__c`
   - `Refund_Date__c`
   - `Refund_Type__c` (full, partial, scheme-related)
   - `Payment_Mode__c`
   - `Bank__c` — the bank from which Trifecta will refund
   - `Reason__c`
   - `Reversed_Demand__c` — link back to the demand being reversed, if
     applicable
   - `Customer_Name__c`, `Unit_No__c` (auto-populated)
3. Save. The **Refund Notification** flow alerts the Finance team.
4. Once Finance completes the bank transfer, update the refund record
   with the remittance details.

### 6. Release the unit back to inventory

After the cancellation is approved, the **Update Unit Status** flow (and
`BookingTriggerHandler`) sets the `Plot__c.Status__c` back to Available
so it can be re-sold. Verify this from the **Inventory Management** tab.

## Key cancellation fields on `Booking__c`

| Field | Purpose |
|---|---|
| `Cancellation_Reason__c` | Why the customer is cancelling |
| `Cancellation_Description__c` | Free-text detail |
| `Cancellation_Charge__c` | Amount Trifecta retains |
| `Cancellation_Amount__c` | Amount to be refunded |
| `Cancellation_Status__c` | Lifecycle state |
| `Cancellation_CRM_Executive__c` | Owner of the cancellation |
| `Cancellation_Letter__c`, `Cancellation_Letter_Sent__c` | Letter generation / send status |
| `Cancellation_Email_Sent__c`, `Cancellation_Email_Sent_Time__c` | Email audit |
| `Cancellation_Agreement_Uploaded__c` | Whether signed agreement is uploaded |

## Fields on `Refund__c`

| Field | Purpose |
|---|---|
| `Booking__c`, `Booking_Id__c`, `Unit_No__c` | Booking reference |
| `Customer_Name__c`, `Owner_Name__c` | Customer identity |
| `Refund_Amount__c`, `Refund_Date__c`, `Refund_Type__c` | Refund details |
| `Payment_Mode__c`, `Bank__c` | How the refund will be paid |
| `Reason__c` | Why the refund |
| `Reversed_Demand__c` | Link to the original demand being reversed |

## Automations you will experience

| Flow | When it fires | Effect |
|---|---|---|
| `Booking_cancellation_request_initiated_Notification` | User submits cancellation | Notifies approvers |
| `Booking_Cancellation_Notification_flow` | Cancellation approved | Notifies CRM team |
| `Cancellation_Process_Finance_Notification` | Cancellation approved | Notifies Finance for refund |
| `Refund_Notification` | Refund record created | Notifies Finance |
| `Update_Unit_Status` | Cancellation approved | Releases the unit back to inventory |

## Common issues and tips

- The cancellation cannot proceed until `Cancellation_Reason__c` and
  `Cancellation_Charge__c` are filled.
- If the unit does not release back to inventory after approval, check
  the `BookingTriggerHandler` has run and the `Plot__c` status is not
  locked by another open booking (for example during a swap).
- Match the refund amount exactly to `Cancellation_Amount__c` — any
  mismatch will force finance to create an adjustment entry later.
- Do not delete the original `Demand_Raised__c` rows; mark them
  Cancelled so the audit trail is preserved.
- The **Reversed Demand** lookup on the refund helps Finance trace which
  demand is being reversed; always set it when reversing a specific
  demand.
