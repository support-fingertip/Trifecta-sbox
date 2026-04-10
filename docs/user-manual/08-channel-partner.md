# 08 — Channel Partner

## Overview

Channel Partners (CPs) are external brokers and sourcing agencies that
bring buyers to Trifecta. This module covers onboarding a CP, attaching
their sourcing member to a lead, and running Round Robin assignment to
distribute leads fairly across active sales users and CPs.

## Who uses it

- **Source Manager** (`Channel_Partner__c.Source_Manager__c`) — owns the
  CP relationship end-to-end.
- **Sales Manager** — monitors CP productivity.
- **Admin** — maintains Round Robin configuration.

## Key objects and tabs

| Object | Tab | Purpose |
|---|---|---|
| `Channel_Partner__c` | Channel Partner | Broker / sourcing agency master |
| `Round_Robin__c` | Round Robin | Round-robin assignment queue |
| `Round_Robin_Member__c` | — | Members who belong to a Round Robin queue |
| `Related_Source__c` | — | Source mapping used when converting leads |
| `Campaign__c`, `Marketing_Campaign__c` | Marketing Campaign | Campaigns the CP is tagged to |

## Screens

| Screen | Type | Purpose |
|---|---|---|
| `Channel_Partner` flow | Flow | Onboarding / update wizard for a CP |
| `NewRoundrobinComponent` | Aura | Create / edit a Round Robin queue |
| `RoundRobinUsersView` | Aura | View and manage members of a queue |
| `UserAvailabilityAdminComp` / `UserAvailabilityComp` | Aura | Configure whether a user is available for assignment |
| `bulkReassignment` | LWC | Bulk move leads between users / CPs |

## Workflows

### 1. Onboard a new Channel Partner

1. Open the **Channel Partner** tab and click **New**.
2. Run the **Channel Partner** flow to collect:
   - `ContactPerson__c`, `Mobile_Number__c`, `Alternate_number__c`,
     `Email__c`, `Designation__c`
   - `Type_of_CP__c` (individual / firm / RERA-registered, etc.)
   - `PAN__c`, `Aadhaar_No__c`, `GST__c`, `RERA__c`,
     `Registraction_No__c`
   - `Project_Name__c` the CP is empanelled for
   - `Source_Manager__c` — the Trifecta user who owns the relationship
3. Save. The CP is created with `Approval_Status__c` = Pending and
   `Active__c` = false until admin approval.
4. Once the admin approves the CP, they flip `Active__c` to true and
   the CP can be attributed as a lead source.

### 2. Attribute a lead to a Channel Partner

1. When creating a lead, set `Source__c` / `Sub_Source__c` / `Medium__c`
   to the channel partner source.
2. Populate `Channel_Partner__c` on the lead (or site visit) record and
   `Sourcing_Member__c` with the CP's contact person.
3. Attribution carries into the booking via the **Sync Credit Source
   from Lead** flow so commission reports are accurate.

### 3. Configure Round Robin assignment

1. Open the **Round Robin** tab.
2. Click **New** and fill:
   - Round Robin name
   - Project or scope
   - `listViews` / filter criteria
3. Open the Round Robin record and use **Round Robin Users View**
   (Aura `RoundRobinUsersView`) to add members — one
   `Round_Robin_Member__c` per sales user or CP.
4. Use **User Availability** components to mark individual members as
   available or unavailable (leave, weekend, etc.).
5. When a new lead is saved with `Go_For_Round_Robin__c` = true, the
   `Lead_Assignment_Notification` logic picks the next available
   member and assigns the lead.

### 4. Deactivate a Round Robin member

1. From the Round Robin record, open the member row and uncheck
   **Available** or mark the member inactive.
2. The **Round Robin Member Deactivation Notification** flow fires and
   notifies the Source Manager and admin that the member has been
   removed from the queue, so they can review any in-flight leads.

### 5. Bulk re-assign leads

1. Open the **Bulk** tab (LWC `bulkReassignment`).
2. Filter leads by owner / project / status.
3. Select rows and pick a new owner from the list of active users.
4. Click **Reassign**. Lead history tracking (`leadHistoryTracking`
   Aura) records the change.

## Key fields on `Channel_Partner__c`

| Field | Purpose |
|---|---|
| `ContactPerson__c` | CP contact name |
| `Mobile_Number__c`, `Alternate_number__c`, `Email__c` | Contact details |
| `Designation__c` | Role at the CP firm |
| `Type_of_CP__c` | Category (individual / firm / RERA, etc.) |
| `PAN__c`, `Aadhaar_No__c`, `GST__c`, `RERA__c`, `Registraction_No__c` | KYC / compliance |
| `Project_Name__c` | Which Trifecta projects they are empanelled for |
| `Source_Manager__c` | Trifecta owner of the CP relationship |
| `Approval_Status__c` | Approved / Pending / Rejected |
| `Active__c` | Whether the CP is currently eligible for attribution |

## Key fields on `Round_Robin__c`

See `force-app/main/default/objects/Round_Robin__c/fields/` and the
listViews / validationRules folders for the full reference. Typical
usage is:

- Round Robin name / scope
- Members maintained via `Round_Robin_Member__c`
- Active / inactive flag
- Allocation rules per project

## Automations you will experience

| Flow | When it fires | Effect |
|---|---|---|
| `Channel_Partner` | New / updated CP | Walks the user through onboarding |
| `Lead_Assignment_to_Sales_User` | Lead with Go_For_Round_Robin=true | Assigns via Round Robin |
| `Round_Robin_Member_Deactivation_Notification` | Member deactivated | Notifies admin and source manager |

## Common issues and tips

- **CP not appearing in the source picklist**: check `Active__c` is true
  and `Approval_Status__c` is Approved.
- **Leads always go to the same sales user**: verify there are multiple
  active `Round_Robin_Member__c` rows with `Available` set to true. A
  queue with a single active member will always assign to that member.
- **Attribution missing on the booking**: the `Sync_Credit_Source_from_Lead`
  flow runs on booking insert. If attribution is missing, confirm the
  lead had `Credit_Source__c` populated before conversion.
- Keep CP KYC documents (PAN, GST, RERA) current — expired KYC should
  deactivate the CP until refreshed.
