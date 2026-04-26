# 12 — Approvals Reference

## Overview

Many actions in the Trifecta Post Sales app need sign-off from a
manager, a finance user, or a project head before they can proceed.
This page is a single cross-reference for every approval in the app —
what triggers it, who approves it, what happens when it is approved or
rejected, and where to go to act on a pending item.

## How approvals work in this app

Most approvals in Trifecta Post Sales are implemented via:

- **Submit For Approval** Flow (`Submit_For_Approval.flow-meta.xml`) —
  the generic entry point that users click on a record.
- Per-process approval flows (one per business process) that notify
  the approvers and update the record's `Approval_status__c` field.
- A shared **custom approval panel** Aura component
  (`customApprovalPanel`) that approvers use to see pending items and
  act on them in one place.
- Custom notification flows, gated by the **Custom Notification
  Access** permission set, for in-app bell notifications.

Each object with an approval carries an `Approval_status__c` (and
often `Approver_1__c` / `Approver_2__c`) field that you can filter on
in list views to find pending items.

## Approval matrix

| Process | Object | Trigger | Approver | Notification flow | Effect on approval |
|---|---|---|---|---|---|
| Quote / discount approval | `Quote__c` | User clicks Submit For Approval after exceeding `Project_Discount_Limit__c` | `Approver_1__c`, `Approver_2__c` (Sales Head / Project Head) | `Quote_Approval_Process`, `Quote_Approval_Notification` | `Approval_status__c` = Approved, Quote can be converted to Booking |
| Booking approval | `Booking__c` | Submit booking | Sales Head / CRM Head / Finance (role depends on value) | `Booking_approval_notification` | `Booking_Approval_Time__c` set, booking can move to Booked stage |
| Customer approval form | `Booking__c` | Customer-facing step | Customer (via link) | `Customer_Approval_Form` | Captures customer sign-off |
| Receipt approval | `Receipt__c` | Submit receipt | Finance User (`Project__c.Finance_User__c`) | `Recipet_Approval_Notification` | Receipt becomes official, PDF can be sent |
| Demand — additional charges / revised | `Demand_Raised__c` | Raise revised / additional-charge demand | Finance User | `Demand_Raised__c` approval fields | Demand becomes valid for collection |
| Booking cancellation request | `Booking__c` | User clicks Booking Cancellation Request | Cancellation approver chain (CRM Head / COO) | `Booking_cancellation_request_initiated_Notification` | Moves to Cancellation Approved |
| Booking cancellation approval | `Booking__c` | Approver decision | Cancellation approver | `Booking_Cancellation_Notification_flow`, `Cancellation_Process_Finance_Notification` | Unit released, refund enabled |
| Refund | `Refund__c` | Refund record created | Finance User | `Refund_Notification` | Refund pushed to Finance for disbursal |
| Inspection approval | `Inspection__c` | Inspection created / submitted | `Inspection__c.Approver__c` | `Inspection_Approval_Notification` | Inspection approved, snags can be raised |
| Agreement time extension | `Booking__c` | User clicks Request For Agreement Time Extension | Agreement approver chain | `Agreement_time_Extension_Approval_Notification` | `Agreement_Extension_Approved_Date__c` set |
| Lead reassignment | `Lead` | Owner change via Bulk reassignment | N/A (logged) | `Lead_Assignment_Notification` | New owner notified |
| Round Robin member deactivation | `Round_Robin_Member__c` | Member marked inactive | N/A (logged) | `Round_Robin_Member_Deactivation_Notification` | Admin informed |

## How to find your pending approvals

1. **In-app notification bell** — most approvers are notified via an
   in-app notification driven by one of the flows above. Click the
   bell icon at the top of the Salesforce UI.
2. **Custom Approval Panel** — from the relevant tab (Booking, Quote,
   Receipt, etc.), open the record and the **Custom Approval Panel**
   (Aura `customApprovalPanel`) displays the items waiting on you.
3. **List views** — each object has a list view that filters on
   `Approval_status__c = Pending`. Ask your admin to add it to your
   default list views if it's missing.
4. **Salesforce home Approvals component** — if the org uses standard
   approval processes, pending items also appear on the home page.

## How to act on a pending approval

1. Open the record. Review the key fields flagged in the matrix above
   (for example, discount amount on a Quote, cancellation charge on a
   Booking, received amount on a Receipt).
2. Scroll down to the **Approval History** related list and the
   **Custom Approval Panel**.
3. Click **Approve** or **Reject**. If rejecting, always leave a
   comment so the submitter understands why.
4. The corresponding notification flow runs automatically and alerts
   the submitter.

## If you cannot approve

- **"I don't see the Approve button"** — check that your user is set
  as `Approver_1__c` / `Approver_2__c` on the record (for quotes) or
  in the relevant role lookup on the `Project__c` (for bookings,
  receipts, refunds). If not, ask an admin to correct the role
  assignment.
- **"Notification missing"** — check you have the **Custom
  Notification Access** permission set assigned.
- **"Approve button is grey"** — the record is already approved, or
  someone else in your group has acted on it.

## For approvers: best practices

- Always read the notes / description on the record before approving.
- When rejecting, provide a clear reason that the submitter can fix.
- For financial approvals (receipts, refunds, discounts), confirm the
  calculations manually against the source document before
  approving — automated rollups cannot catch every edge case.
- Keep an eye on your list views for backlog — delays cascade into
  customer-facing delays.
