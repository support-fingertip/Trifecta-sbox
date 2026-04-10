# 13 — Admin & Settings

## Overview

This module is for the **System Administrator** and power users who
configure how the Post Sales application behaves: general settings,
discount limits, interest slabs, Round Robin queues, integrations
(M-Cube, WhatsApp, SMS), scheduled batches and custom logs.

## Who uses it

- **System Administrator** — full configuration access.
- **Finance Admin** — interest rates and discount policy.
- **IT / Integration Admin** — M-Cube, SMS and WhatsApp setup.

## Key objects and tabs

| Object | Tab | Purpose |
|---|---|---|
| `General_Settings__c` | General Settings | Org-level switches and defaults |
| `Discount_Limit__c` | — (accessed via admin list view) | Global discount ceiling |
| `Project_Discount_Limit__c` | — | Per-project discount ceiling |
| `Interest_Percentage__c` | Interest Percentage | Delay-interest slabs |
| `Round_Robin__c`, `Round_Robin_Member__c` | Round Robin | Lead assignment queues |
| `In_App_Checklist_Settings__c` | — | In-app checklist toggles |
| `Lead_Assignment_Config__mdt` | — | Lead assignment configuration (custom metadata) |
| `Mcube__mdt` | — | M-Cube CTI configuration (custom metadata) |
| `Whatsapp_Setting__mdt` | — | WhatsApp gateway configuration |
| `SMS_Setting__mdt` | — | SMS gateway configuration |
| `Country_Code_Mapping__mdt` | — | Country dialing codes |
| `Project_Name_Mappings__mdt` | — | Aliases / external names per project |
| `Param_Mapping__c` | — | Parameter mapping for third-party responses |
| `MCUBE_Object_Api__c` | MCUBE Object Api | Raw M-Cube webhook payloads |
| — | M Cube Setup Configuration | M-Cube setup Aura page (`mCube_Setup`) |
| `Apex_Log__c` | Apex Log | Custom Apex log viewer |
| — | Payment Reminder (Batch Executor) | Aura `ExecutiteBatchsCmp` to run reminder batches |
| `Landing_Number__c` | Landing Number | Incoming phone → project mapping |
| — | Bulk | LWC `bulkReassignment` for bulk lead reassignment |

## Workflows

### 1. Configure General Settings

1. Open the **General Settings** tab and open (or create) the
   singleton record.
2. Set org-wide defaults — for example, default project, default
   notification toggles, reminder windows.
3. Save. Custom Settings refresh automatically across users on the
   next page load.

### 2. Set discount limits

1. Create a `Discount_Limit__c` row for the global ceiling.
2. Create `Project_Discount_Limit__c` rows for each project that
   should override the global ceiling.
3. The Quote and Booking save logic reads these at runtime and forces
   approval when the user exceeds the configured percentage / amount.

### 3. Configure interest slabs

1. Open the **Interest Percentage** tab.
2. Create one `Interest_Percentage__c` row per slab — typically by
   delay bucket (e.g. 0–30 days, 31–60 days, 61+ days) with the
   applicable percentage.
3. The `Penalty Demand` Aura component and `BookingDemandInvoice` Apex
   read these rows when calculating interest.

### 4. Configure Round Robin

See [Channel Partner](08-channel-partner.md#3-configure-round-robin-assignment)
for the end-user workflow. As an admin:

1. Create the `Round_Robin__c` queue with its project scope.
2. Add active sales users as `Round_Robin_Member__c` rows.
3. Use **User Availability Admin** (Aura
   `UserAvailabilityAdminComp`) to pre-configure availability windows.
4. Confirm the `Lead_Assignment_Config__mdt` record is wired to the
   right queue for the project.

### 5. Configure M-Cube (CTI) integration

1. Open the **M Cube Setup Configuration** tab (Aura `mCube_Setup` /
   `mCubeLightningPage`).
2. Enter the M-Cube API credentials and endpoint.
3. Map your landing numbers to projects via the **Landing Number**
   tab — each incoming call lands on the project whose landing number
   it matches.
4. Use the **MCUBE Object Api** tab to inspect raw webhook payloads
   when debugging call routing issues.

### 6. Configure WhatsApp and SMS gateways

1. Open **Setup → Custom Metadata Types** and edit
   `Whatsapp_Setting__mdt` and `SMS_Setting__mdt` records with the
   gateway credentials, sender ID / template IDs.
2. Verify `Country_Code_Mapping__mdt` covers all customer countries.
3. Test a message from the relevant record action and confirm the
   delivery status updates.

### 7. Run scheduled batches on demand

1. Open the **Payment Reminder** tab (Aura `ExecutiteBatchsCmp`).
2. Select the batch to run — for example:
   - `AgreementReminderScheduler`
   - `AgreementPaymentReminderScheduler`
   - `AgreementPaymentReminderBatch`
3. Execute. Progress appears in the component. Use this when the
   daily schedule missed a run.

### 8. View Apex logs

1. Open the **Apex Log** tab for the custom `Apex_Log__c` object.
2. Filter by date, user or error type to debug failed integrations
   and triggers without needing System Administrator-level Setup
   access.

### 9. Bulk reassign leads

Use the **Bulk** tab (LWC `bulkReassignment`) to move leads between
owners — typically when a user leaves or goes on leave. See
[Channel Partner](08-channel-partner.md#5-bulk-re-assign-leads).

## Permission sets

The repo ships the following permission sets in
`force-app/main/default/permissionsets/`:

- `Sales_User` — standard Sales user access (includes
  `CampaignInfluence2` user permission).
- `Salesforce_Lead_Capture` — external / partner user access for lead
  capture.
- `Custom_Notification_Access` — required for every user who should
  receive in-app bell notifications from flows.
- `sfdcInternalInt__sfdc_activityplatform` — Salesforce internal.
- `sfdcInternalInt__sfdc_nc_constraints_engine_deploy` — Salesforce
  internal.

Assign **Sales_User** and **Custom_Notification_Access** to every
sales user. Assign **Salesforce_Lead_Capture** to users / integrations
that create leads from external sources.

## Triggers (for admin awareness)

The org has the following Apex triggers under
`force-app/main/default/triggers/`:

`BookingTrigger`, `CallDetailTrigger`, `DemandRaisedTrigger`,
`FollowUpTrigger`, `InspectionTrigger`, `InterestPercentageTrigger`,
`MasterPaymentScheduleTrigger`, `PaymentScheduleTrigger`,
`ProjectNameAutoFill`, `QuoteTrigger`, `ReceiptLineIemTrigger`,
`ReceiptTrigger`, `RelatedSourceTrigger`, `RenameUploadedFiles`,
`SLeadTrigger`, `SiteVisitTrigger`, `TicketTrigger`.

Each is paired with a handler class in `force-app/main/default/classes/`
for maintainability. Consult those classes when diagnosing unexpected
field updates.

## Common issues and tips

- **Users not receiving notifications**: assign the
  **Custom_Notification_Access** permission set.
- **Discounts still going through without approval**: verify
  `Project_Discount_Limit__c` is set for the project. A missing record
  falls back to the global `Discount_Limit__c`.
- **Round Robin stuck on one user**: ensure multiple members are
  active and that `UserAvailabilityComp` shows them available; if an
  admin disables a user in Salesforce, also mark them inactive in
  `Round_Robin_Member__c`.
- **M-Cube calls not routing**: inspect the `MCUBE_Object_Api__c`
  records for the incoming payload. Most routing issues are missing
  `Landing_Number__c` mappings.
- **Old custom settings cached**: after editing `General_Settings__c`,
  users may need to refresh the page to see the new values.
- **BRD source of truth**: the file `Trfiecta Projects Pvt. Ltd. Post
  Sales BRD Version 5 revised based on 3 demos.docx` at the repo
  root remains the authoritative functional specification. Update the
  manual (and this repo) whenever the BRD changes.
