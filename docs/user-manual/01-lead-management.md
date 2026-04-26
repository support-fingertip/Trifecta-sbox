# 01 — Lead Management

## Overview

The Lead Management module captures every enquiry a prospect makes about
Trifecta's real-estate projects, assigns the enquiry to the right sales user,
tracks follow-ups until the prospect either books a unit or is marked
unqualified, and records every call, walk-in and website registration that
feeds the sales pipeline.

## Who uses it

- **Guest Relations Executive (GRE)** — captures walk-in enquiries and
  qualifies leads at the sales gallery.
- **Sales Executive** — owns assigned leads, schedules follow-ups and site
  visits, and converts leads into bookings.
- **Sales Manager / Source Manager** — monitors lead volume, re-assigns
  leads and reviews unqualification reasons.
- **Marketing User** — links leads to `Marketing_Campaign__c` records.

## Key objects and tabs

| Object | Tab | Purpose |
|---|---|---|
| `Lead` (standard) | Lead Global Search | Standard Salesforce Lead with Trifecta custom fields |
| `Call_Detail__c`, `Call_Detail1__c` | Call Detail | Inbound / outbound call logs |
| `Follow_up__c` | Follow up | Scheduled follow-up activities |
| `Lead_Unqualification__c` | Lead Unqualification | Reasons and audit trail for unqualified leads |
| `Marketing_Campaign__c` | Marketing Campaign | Source campaign master |
| `Round_Robin__c`, `Round_Robin_Member__c` | Round Robin | Assignment queues |
| `Landing_Number__c` | Landing Number | Mapping of incoming phone numbers to projects |

### Lead Global Search (LWC)

The **Lead Global Search** tab opens the `leadGlobalSearch` Lightning Web
Component. Use it to find an existing lead by phone number, email or name
before creating a new one — this prevents duplicates and lets you attach a
new enquiry to the original lead.

## Workflows

### 1. Capture a new walk-in lead (GRE)

1. Open the **GRE Form** tab (Aura component `WalkinFormCmp`).
2. Enter the prospect details: name, mobile number, email, project of
   interest, source of enquiry.
3. Before saving, use **Lead Global Search** to confirm the prospect is not
   already in the system.
4. Save. The record is created as a Lead with a GRE record type; the
   `Go_For_Round_Robin__c` flag determines whether the lead auto-assigns via
   Round Robin.
5. If `Go_For_Round_Robin__c` is checked, the **Lead Assignment to Sales
   User** flow runs, the lead owner changes, and the new owner receives a
   **"Lead assigned for sales users"** in-app notification.

### 2. Capture an inbound phone lead

1. When a call lands on a configured **Landing Number**, the M-Cube (or
   other CTI) integration creates a `Call_Detail__c` record and the Dialer
   opens automatically (Aura `CallPanel`, `Click2Call`, VF page
   `Dialer.page`). See [Communications](11-communications.md).
2. Fill the walk-in/call disposition fields and click **Push To CRM** (Aura
   `PushToCRM`) to convert the call into a Lead.
3. The lead then follows the same assignment flow as walk-in leads.

### 3. Capture a website lead

Leads submitted from the public website hit the `WebsiteAPIController` Aura
component / Apex class. They are created with the source set to the website
campaign and handed to Round Robin automatically.

### 4. Schedule and complete a follow-up

1. Open the lead record.
2. Click **New** on the **Follow ups** related list (or create directly from
   the Follow up tab).
3. Fill in:
   - `Subject__c`
   - `Description__c`
   - `Scheduled_Date__c`
   - `Project_Name__c`
4. Save. The `FollowUpTrigger` fires and the **Follow Up Notifications**
   flow reminds you on the scheduled date.
5. When you complete the call or meeting, set `Status__c` to completed and
   fill `Completed_Date__c` and `Comments__c`.

### 5. Mark a lead unqualified

1. Open the lead.
2. Click **Mark Unqualified Lead** (Aura `MarkUnqualfiedLead`).
3. Pick the unqualification reason and save — a `Lead_Unqualification__c`
   record is created with the audit details.
4. If the lead reopens later (new enquiry from the same prospect), the
   **Re-opened Lead Notification** flow fires and notifies the original
   owner.

### 6. Re-assign leads in bulk

Sales Managers can use the **Bulk** tab (LWC `bulkReassignment`) to move
many leads from one sales user to another — for example, when a user goes
on leave. Filter by owner, select rows and choose a new owner.

### 7. Update lead owner / status

- **Update Lead Owner** Aura component reassigns one lead and preserves
  history via the `leadHistoryTracking` Aura component.
- **Update Lead Status** / **Update Lead Status NewComp** Aura components
  advance the lead stage. The **Update Lead Data** flow synchronises
  related fields (Credit Source, Enquiry Source, etc.).

## Key fields on `Lead` (Trifecta custom)

Only the fields you actually touch in day-to-day work are listed. See
`force-app/main/default/objects/Lead/` for the full field catalogue if you
need a complete reference.

| Field | What to enter |
|---|---|
| `Lead_Phone_Number__c` | 10-digit mobile number (primary identifier) |
| `Project1__c` / `Project__c` | Project the prospect is interested in |
| `Source__c`, `Sub_Source__c`, `Medium__c` | Lead source attribution |
| `Credit_Source__c`, `Credit_Source_for_Sharing__c` | Which sales user/channel gets credit |
| `Lead_Stage__c`, `Lead_Status__c` | Current funnel stage |
| `Go_For_Round_Robin__c` | Checkbox — if true, auto-assign |
| `Assisted_By__c`, `Sourcing_Member__c` | Additional attribution |
| `SV_Proposed_Date_Time__c` | Proposed site visit date/time |
| `Key_Trigger_for_purchase__c` | Motivation for purchase |
| `Customer_Visit_Happened__c`, `Customer_Visit_Not_Required__c` | Site visit flags |

## Automations you will experience

| Flow | When it fires | Effect |
|---|---|---|
| `Lead_Assignment_to_Sales_User` | New lead saved with Round Robin flag | Assigns owner, sends notification |
| `Lead_Assignment_Notification` | Lead re-assigned | Notifies new owner |
| `Lead_Email_Alert_After_30_Min` | 30 minutes after assignment | Reminds owner to act |
| `Re_opened_Lead_Notification` | Prospect re-enquires | Notifies original owner |
| `Update_Lead_Data` | Lead record changes | Keeps related fields in sync |
| `Sync_Credit_Source_from_Lead` | Lead credit source changes | Propagates to Booking |
| `Follow_Up_Notifications` | Scheduled follow-up | In-app + email reminder |

## Common issues and tips

- **"Lead not assigning"** — verify `Go_For_Round_Robin__c` is checked and
  the user is an active member of the appropriate
  `Round_Robin_Member__c` record.
- **"I can't see my leads"** — confirm your profile has Lead Read/Edit and
  that you have the **Salesforce Lead Capture** permission set.
- **Duplicate leads** — always search with `leadGlobalSearch` before
  creating a new lead; attach new enquiries to the existing lead instead.
- **Follow-up reminders not firing** — ensure `Scheduled_Date__c` is in the
  future and the lead owner has **Custom Notification Access**.
