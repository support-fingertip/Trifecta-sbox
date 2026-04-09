# 10 — Support & Tickets

## Overview

After possession, customer complaints about the unit (defects, warranty
issues, documentation issues, service requests) are tracked via
**Tickets**. Tickets have an expected resolution date, status tracking
and an auto-generated closure email when they are resolved.

## Who uses it

- **Customer Service CRM Executive**
  (`Project__c.Customer_Service_CRM_Executive__c`) — logs tickets,
  assigns them, tracks resolution.
- **Inspection Executive** — resolves snag-related tickets in
  coordination with the site team.
- **CRM Head / Manager** — monitors backlog, escalations and SLAs.

## Key objects and tabs

| Object | Tab | Purpose |
|---|---|---|
| `Ticket__c` | Ticket | Customer support ticket |

## Workflows

### 1. Log a new ticket

1. Open the **Ticket** tab and click **New**, or create a ticket
   directly from the related booking.
2. Fill the ticket form:
   - `Booking__c` — parent booking
   - `Project__c`, `Block__c`, `Unit__c` — auto-populated from booking
   - `Customer_Email__c` — for closure notifications
   - `Category__c` — the type of issue (warranty, documentation,
     service, plumbing, electrical, civil, etc.)
   - `Priority__c`
   - `Description__c` — detailed description of the problem
   - `Source__c` — how the ticket came in (phone, email, walk-in,
     inspection)
   - `Raised_date__c` — when the customer raised it
   - `Expected_Resolution_Date__c` — SLA target based on priority
3. Save. The `TicketTrigger` sets `Is_New__c` and tracks initial state.

### 2. Work on and resolve a ticket

1. Open the ticket, update `Status__c` as work progresses (Open,
   In Progress, On Hold, Resolved, Closed — the exact picklist is in
   `Ticket__c/fields/Status__c.field-meta.xml`).
2. Capture the work done in `Resolution_Remarks__c`.
3. When the work is done, set `Actual_Resolution_Date__c` and move
   `Status__c` to Resolved.
4. If the unit is in the DLP (Defect Liability Period), update
   `DLP_Status__c` so reporting is accurate.

### 3. Close the ticket and notify the customer

1. When closing, the `TicketClosureEmailService` Apex (scheduled /
   invoked by trigger) sends a closure email to `Customer_Email__c`.
2. On success, `Closure_Email_Sent__c` becomes true and
   `Closure_Email_Sent_Date__c` is populated.
3. Archive the ticket by moving `Status__c` to Closed.

## Key fields on `Ticket__c`

| Field | Purpose |
|---|---|
| `Booking__c`, `Project__c`, `Block__c`, `Unit__c` | Where the issue is |
| `Customer_Email__c` | Customer contact for closure |
| `Category__c` | Type of issue |
| `Priority__c` | SLA driver |
| `Status__c` | Current lifecycle state |
| `Source__c` | How the ticket was raised |
| `Description__c` | Problem detail |
| `Raised_date__c` | Ticket raise date |
| `Expected_Resolution_Date__c` | SLA target |
| `Actual_Resolution_Date__c` | Actual close date |
| `Resolution_Remarks__c` | How it was resolved |
| `Closure_Email_Sent__c` / `Closure_Email_Sent_Date__c` | Customer notification audit |
| `DLP_Status__c` | Defect Liability Period indicator |
| `Is_New__c` | Trigger helper flag |

## Automations you will experience

| Trigger / Service | When it fires | Effect |
|---|---|---|
| `TicketTrigger` | Ticket insert / update | Sets `Is_New__c`, updates timestamps, triggers closure email service |
| `TicketClosureEmailService` (Apex) | Ticket resolved / closed | Sends closure email to the customer |

## Common issues and tips

- Always set the **Priority** before saving — the Expected Resolution
  Date is usually derived from it by your SLA rules.
- Avoid creating duplicate tickets for the same complaint; search the
  booking's ticket related list first.
- If the closure email did not reach the customer, confirm
  `Customer_Email__c` is valid and `Closure_Email_Sent__c` is true — if
  it is false, the `TicketClosureEmailService` likely errored out and
  admin should check the Apex Log tab.
- For DLP-related issues, link the ticket to the relevant
  `Inspection__c` record so that the inspection team can close any
  related snags in the same motion.
