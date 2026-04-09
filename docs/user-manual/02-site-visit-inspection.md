# 02 — Site Visit & Inspection

## Overview

This module covers two connected processes:

1. **Site Visit** — a prospective buyer's visit to a project site, from
   scheduling through completion and feedback capture.
2. **Inspection** — a pre-handover inspection of a booked unit, where the
   buyer or the inspection team logs defects (**Snag List**) that must be
   fixed before possession.

## Who uses it

- **GRE / Sales Executive** — schedules site visits and completes the
  walk-in form at the gallery.
- **Sales Manager** — reviews visit feedback and conversion rates.
- **CRM Executive** — drives pre-handover inspections.
- **Inspection Executive** (`Project__c.Inspection_Executive__c`) —
  performs the inspection and closes snags.

## Key objects and tabs

| Object | Tab | Purpose |
|---|---|---|
| `Site_Visit__c` | Site Visit | Record of a prospect's visit |
| `Inspection__c` | Inspection | Pre-handover inspection of a unit |
| `Snag_List__c` | Snag List | Defects raised during an inspection |

## Screens

| Screen | Type | Purpose |
|---|---|---|
| `NewSiteVisit` | Aura | Create a new site visit from a lead |
| `SiteVisitForm` | Aura | Capture full walk-in form details |
| `ReVisitComponent` | Aura | Log a repeat visit |
| `Invitation_For_Inspection.page` | VF | Email invite sent to the customer to book an inspection |
| `UpdateInspectionExpectedCompletedDate` | Aura | Extend the inspection/snag completion date |

## Workflows

### 1. Schedule a site visit from a lead

1. Open the lead and click **New Site Visit** (Aura `NewSiteVisit`).
2. Fill in:
   - `SV_Proposed_Date_Time__c`
   - `Site_Visit_Type__c` (first visit, revisit, event, etc.)
   - `Pre_SV_Customer_Requirement_Summary__c`
   - `Transport_Arrangement__c` / `Pickup_Address__c` if Trifecta is
     arranging pickup
   - `Project1__c` and `Primary_Apartment_Type__c`
3. Save. A `Site_Visit__c` record is created and the **Site visit
   notification** flow notifies the project sales team.
4. The **Site Visit Notification Before Half An Hour** and **90 Min Before
   Site Visit Notification to Owner** flows send reminders at T-30 and T-90
   minutes before `SV_Proposed_Date_Time__c`.

### 2. Complete a site visit (walk-in)

1. When the customer arrives, open the **GRE Form** or the lead's Site
   Visit record.
2. Use **Site Visit Form** (Aura `SiteVisitForm` / `WalkinFormCmp`) to
   capture:
   - `Site_Visit_Entry_Time__c`
   - Demographic fields (`SV_Occupation_Employment__c`,
     `SV_Household_Annual_Income__c`, `SV_Reason_for_Purchase__c`, etc.)
   - Customer requirements (`SV_Budget_of_Purchase__c`,
     `SV_Current_Accomadation__c`, `SV_Is_this_your_first_Home__c`)
   - Feedback (`Sv_Quality_of_Information__c`,
     `Sv_Response_at_reception_Feed_back__c`, `SV_Sales_Feedback__c`)
3. When the visit is done, set `Site_Visit_Happened__c` = true and fill
   `SV_Completed_Date_Time__c`.
4. If the customer needs to come again, use **ReVisit Component** to log
   the next visit (fills `Multiple_SV_date__c`, `Revisit_Count__c`, etc.).

### 3. Capture site visit feedback

After the visit, fill the feedback checkboxes
(`Sv_Feedback_check_box__c`), rating (`Site_Visit_rating__c`), ambience
feedback (`SV_Ambience_and_cleanliness__c`) and any free-text remarks
(`Site_Visit_Remarks__c`). A WhatsApp feedback link can be sent — fields
`WhatsApp_Message_Sent__c`, `WhatsApp_Message_DateTime__c` and
`WhatsApp_Message_Status__c` track the status.

### 4. Invite a customer for inspection (pre-handover)

1. From the booking, the Possession Handover CRM Executive opens
   `Invitation_For_Inspection.page` to send the invitation.
2. Create an `Inspection__c` record with:
   - `Booking__c`
   - `Inspection_Date__c`
   - `Inspection_Type__c`
   - `Inspection_Checklist__c`
   - `Expected_Completed_Date__c`
   - `Priority__c`
3. Submit for approval if your project requires approval — this triggers
   the **Inspection Approval Notification** flow which alerts the approver.

### 5. Raise snags during inspection

1. From the `Inspection__c` record, click **New** on the Snag List related
   list.
2. For each defect, create a `Snag_List__c` with:
   - `Category__c`
   - `Description__c`
   - `Priority__c`
   - `Expected_Completed_Date__c`
3. As defects are fixed, upload the completion photo
   (`Snag_Completed_File_Uploaded__c`) and update `Status__c`.
4. When all snags are closed, the Inspection `Status__c` becomes complete
   and `Snags_Completion_Email_Sent__c` is set to true when the completion
   email is sent to the customer.

### 6. Extend inspection completion date

If the inspection cannot be closed by `Expected_Completed_Date__c`, use
**Update Inspection Expected Completed Date** (Aura
`UpdateInspectionExpectedCompletedDate`) to set
`Extended_Completed_Date__c` / `Extended_Completion_Date__c` and capture
`Extended_Completion_Reason__c`.

## Key fields on `Site_Visit__c`

| Field | Required? | Notes |
|---|---|---|
| `SLead__c` | Yes | Parent lead lookup |
| `Project1__c` / `Project__c` | Yes | Project visited |
| `SV_Proposed_Date_Time__c` | Yes | Scheduled visit time |
| `Site_Visit_Type__c` | Yes | First, revisit, event, etc. |
| `Site_Visit_Happened__c` | On completion | Set true when visit finishes |
| `SV_Completed_Date_Time__c` | On completion | Auto-captured via Aura form |
| `Feedback__c`, `Site_Visit_rating__c` | Optional | Fill from customer feedback |

## Key fields on `Inspection__c`

| Field | Required? | Notes |
|---|---|---|
| `Booking__c` | Yes | Parent booking |
| `Inspection_Type__c`, `Inspection_Date__c` | Yes | Type and date |
| `Customer_Name__c`, `Customer_Email__c` | Yes | For the invitation email |
| `Inspection_Checklist__c` | Yes | Text list of items to verify |
| `Priority__c`, `Status__c` | Yes | Lifecycle state |
| `Expected_Completed_Date__c` | Yes | Target close date |
| `Extended_Completed_Date__c` | On extension | Populated when deadline is extended |
| `Approval_Status__c`, `Approver__c` | Auto | Driven by approval flow |

## Automations you will experience

| Flow | When it fires | Effect |
|---|---|---|
| `Site_visit_notification` | New / updated site visit | Notifies sales team |
| `Site_Visit_Notification_Before_Half_An_Hour` | 30 mins before scheduled time | Reminder notification |
| `X90_Min_Before_Site_Visit_Notification_to_Owner` | 90 mins before scheduled time | Reminder notification |
| `Inspection_Approval_Notification` | Inspection submitted for approval | Notifies approver |
| `SiteVisitTrigger` | Any insert / update | Keeps visit counts (`No_Of_Sv__c`, `Multiple_SV_Count__c`) in sync |
| `InspectionTrigger` | Any insert / update | Maintains escalation and reminder dates |

## Common issues and tips

- Always capture `Site_Visit_Entry_Time__c` when the customer walks in —
  it's used for turnaround-time reports.
- The `SV_form_filled_online__c` flag indicates the customer pre-filled the
  form via website. Don't overwrite their responses on arrival.
- If the reminder notifications are not firing, verify the scheduled time
  is in the future and the owning sales user has **Custom Notification
  Access**.
- Inspection snags cannot be closed until the **Snag Completed File** is
  uploaded — users frequently forget this step.
