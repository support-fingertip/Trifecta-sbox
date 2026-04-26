# 00 — Getting Started

This page explains what you see when you first log in to the Trifecta Post
Sales application and how to navigate it.

## 1. Logging in

1. Open your Salesforce login URL (production: `https://login.salesforce.com`,
   sandbox: `https://test.salesforce.com`). The sandbox URL for this project
   is configured in `sfdx-project.json`.
2. Enter the username and password provided by your System Administrator.
3. After login, Salesforce displays the **App Launcher** (the nine-dot icon
   at the top-left). Use the App Launcher to switch between the standard
   Salesforce app and the Trifecta Post Sales app.

If you cannot see the Trifecta app or a specific tab, ask your administrator
to assign you the appropriate permission set (see
[Admin & Settings](13-admin-settings.md)).

## 2. The navigation bar (tabs)

The Post Sales app exposes the following tabs (from
`force-app/main/default/tabs/`). Use them as your primary entry points:

| Tab | Purpose | Covered in |
|---|---|---|
| Home | Dashboards, recent items, activity | — |
| Home Custom | Custom landing page | — |
| Lead Global Search | LWC-powered global lead lookup | [Lead Management](01-lead-management.md) |
| Follow up | Scheduled follow-ups on leads | [Lead Management](01-lead-management.md) |
| Lead Unqualification | Mark and track unqualified leads | [Lead Management](01-lead-management.md) |
| Call Detail | Incoming / outgoing call logs | [Communications](11-communications.md) |
| Dialer | Click-to-call softphone | [Communications](11-communications.md) |
| Landing Number | Incoming telephone number mapping | [Communications](11-communications.md) |
| Site Visit | Scheduled / completed site visits | [Site Visit & Inspection](02-site-visit-inspection.md) |
| Inspection | Pre-handover inspection records | [Site Visit & Inspection](02-site-visit-inspection.md) |
| Snag List | Defects identified during inspection | [Site Visit & Inspection](02-site-visit-inspection.md) |
| Project | Project master records | [Inventory & Units](07-inventory-units.md) |
| Block | Blocks within a project | [Inventory & Units](07-inventory-units.md) |
| Plot | Units (flats, plots, villas, row houses) | [Inventory & Units](07-inventory-units.md) |
| Inventory Management | Unit allocation & status board (Aura) | [Inventory & Units](07-inventory-units.md) |
| Quote | Cost sheets / quotations | [Booking & Quotation](03-booking-quotation.md) |
| Booking | Active bookings | [Booking & Quotation](03-booking-quotation.md) |
| Co Applicant | Additional applicants on a booking | [Booking & Quotation](03-booking-quotation.md) |
| Payment Plan | Milestone / payment plan templates | [Booking & Quotation](03-booking-quotation.md) |
| Master Payment Schedule | Per-booking payment schedule | [Demand & Invoice](05-demand-invoice.md) |
| Receipt | Payment receipts | [Receipts & Payments](04-payment-receipts.md) |
| Refund | Refund records | [Booking Cancellation & Refund](06-booking-cancellation-refund.md) |
| Channel Partner | Channel partners / brokers | [Channel Partner](08-channel-partner.md) |
| Round Robin | Round-robin assignment groups | [Channel Partner](08-channel-partner.md), [Admin & Settings](13-admin-settings.md) |
| Marketing Campaign | Marketing campaign master | [Lead Management](01-lead-management.md) |
| Ticket | Customer service tickets | [Support & Tickets](10-support-tickets.md) |
| Interest Percentage | Penalty / delay interest slabs | [Demand & Invoice](05-demand-invoice.md) |
| General Settings | Org-level settings | [Admin & Settings](13-admin-settings.md) |
| M Cube Setup Configuration | CTI / M-Cube dialer setup | [Admin & Settings](13-admin-settings.md) |
| MCUBE Object Api | M-Cube integration log | [Admin & Settings](13-admin-settings.md) |
| Payment Reminder (Batch Executor) | Scheduled payment reminder batches | [Admin & Settings](13-admin-settings.md) |
| Apex Log | Custom Apex log viewer | [Admin & Settings](13-admin-settings.md) |
| GRE Form | Guest Relations Executive walk-in form | [Lead Management](01-lead-management.md) |
| Bulk | Bulk reassignment screen | [Admin & Settings](13-admin-settings.md) |

## 3. Common actions from a record

Most records display the following action buttons, each backed by an Aura /
LWC component or a Visualforce page. Not all actions appear on every record —
they are gated by record type, status and user role.

| Button | What it does | Backed by |
|---|---|---|
| **Create Booking** | Opens the booking form for the current lead/site visit | `CreateBooking` Aura |
| **Create Quote** | Generates a cost sheet / quotation | `CreateQuote`, `CreateQuoteComponent` Aura |
| **Generate Quote PDF** | Produces a printable quotation | `GenerateQuotePDF` Aura |
| **Generate Receipt** | Creates a receipt against a booking | `GenerateReceipt` Aura |
| **Generate Receipt PDF** | Opens the receipt PDF | `GenerateReceiptPDF` Aura, `Receipt.page` |
| **Generate Consolidated Receipt** | Produces a consolidated receipt PDF | `GenerateConsolidatedReceipt`, `ConsolidatedReceipt.page` |
| **Raise Demand Letter** | Raises a demand note against a booking | `RaiseDemandLetter` Aura, `DemandNote.page` |
| **Revisied Demand** | Raises a revised demand | `RevisiedDemand` Aura |
| **Penalty Demand** | Raises a penalty demand note | `PenaltyDemand` Aura, `PenaltyDemandNote.page` |
| **Bulk Raise Demand** | Raises demands across many bookings | `BulkRaiseDemand` Aura, `BulkRaiseDemandController` |
| **Generate Sale Agreement** | Produces the sale agreement | `GenerateSaleAggrement`, `SaleAgreement.page` |
| **Generate Possession Letter** | Produces a possession letter | `GeneratePossestionletter`, `Possession_Letter.page` |
| **Generate Key Hand-Over Letter** | Produces the key handover letter | `GenerateKeyHandOverLetter`, `Key_Handover_Letter.page` |
| **Generate Bank NOC** | Generates a bank NOC | `GenerateBankNOC`, `BuilderNoc.page` |
| **Generate Cancellation Agreement** | Generates a cancellation agreement | `GenerateCancellationAgreement` |
| **Generate Credit Note** | Generates a credit note | `GenerateCreditNote` |
| **Generate LOU** | Generates a letter of undertaking | `GenerateLOU` |
| **Mark Booking Stage Completed** | Advances the booking stage | `MarkBookingStageCompleted` Aura, `BookingStageController` |
| **Submit For Approval** | Sends a record into an approval process | `Submit_For_Approval` Flow |
| **Swap First Applicant** | Swaps the primary applicant with a co-applicant | `SwapFirstApplicantButton` Aura |
| **Swapping Unit** | Swaps a booked unit with another available unit | `SwappingUnitComponent` Aura, `SwappingUnitController` |
| **Request For Agreement Time Extension** | Asks for more time to execute the agreement | `RequestForAggrementTimeExtension`, `SubmitAgreementTimeExtension` |
| **Request For Sale Agreement / Sale Deed** | Raises a documentation request | `RequestForSaleAgreement`, `RequestForSaleDeed` |
| **Push To CRM / Push To Sales** | Moves a lead into the sales pipeline | `PushToCRM`, `pushToSales` Aura |
| **Add Note** | Adds a note to the record | `AddNoteComponent`, `AddNoteController` |

## 4. Notifications

The org sends in-app notifications via the **Custom Notification Access**
permission set for the following events (from the
`force-app/main/default/flows/` folder):

- Lead assigned to a sales user
- Lead re-opened
- Lead email alert 30 minutes after assignment
- Site visit scheduled (with reminders 30 and 90 minutes before the visit)
- Quote submitted / approved
- Booking submitted / approved
- Booking cancellation request initiated / approved
- Cancellation process — finance notification
- Receipt approved / updated
- Refund initiated
- Inspection approval
- Agreement time extension approval
- Follow-up reminders
- Round Robin member deactivation

If you are a named approver on a record and you are not receiving
notifications, check that you have the **Custom Notification Access**
permission set assigned.

## 5. Getting help

- For application issues (missing tabs, failing approvals, missing fields),
  contact your Salesforce Administrator.
- For process questions (what to enter in a field, when to raise a demand),
  refer to the relevant module page in this manual.
- For requirement clarifications, the source of truth is the
  **Post Sales BRD v5** document at the repository root.
