# Trifecta Post Sales — User Manual

This manual describes how to use the Trifecta Projects Pvt. Ltd. Post Sales
application built on Salesforce. It is written for end users — Sales, CRM,
Finance, Inventory, Customer Service and Administrators — who perform the
day-to-day activities of capturing leads, booking units, collecting payments,
raising demands, processing cancellations, and generating customer documents.

The content is derived directly from the Salesforce metadata in this
repository (`force-app/main/default/`): custom objects, Apex controllers,
Lightning Web Components (LWCs), Aura components, Visualforce pages, flows,
permission sets and tabs. Where a field, button, screen or automation is
referenced, it exists in the org.

## How to use this manual

1. If you are new to the application, start with **[Getting Started](00-getting-started.md)** — it explains how to log in, switch apps, find records, and use the common navigation elements.
2. Find the module that matches the task you want to perform (see the table of contents below). Each module page is self-contained and includes step-by-step workflows.
3. Use the **[Approvals Reference](12-approvals-reference.md)** when you need to know who approves what and what the pending states mean.
4. Use the **[Glossary](99-glossary.md)** for definitions of any object, field or role you don't recognise.

## Table of contents

| # | Module | Who uses it |
|---|---|---|
| 00 | [Getting Started](00-getting-started.md) | All users |
| 01 | [Lead Management](01-lead-management.md) | GRE, Sales Executive, Sales Manager |
| 02 | [Site Visit & Inspection](02-site-visit-inspection.md) | GRE, Sales Executive, Inspection Executive |
| 03 | [Booking & Quotation](03-booking-quotation.md) | Sales Executive, Sales Manager, CRM Executive |
| 04 | [Receipts & Payments](04-payment-receipts.md) | Finance User, CRM Executive |
| 05 | [Demand & Invoice](05-demand-invoice.md) | Demands & Collections User, Finance User |
| 06 | [Booking Cancellation & Refund](06-booking-cancellation-refund.md) | CRM Executive, Finance User, Approvers |
| 07 | [Inventory & Units](07-inventory-units.md) | Sales Executive, Inventory Manager |
| 08 | [Channel Partner](08-channel-partner.md) | Source Manager, Sales Manager |
| 09 | [Document Generation](09-document-generation.md) | CRM Executive, Legal, Registration Team |
| 10 | [Support & Tickets](10-support-tickets.md) | Customer Service, CRM Executive |
| 11 | [Communications (Dialer, SMS, Email, WhatsApp)](11-communications.md) | Sales, Marketing, CRM |
| 12 | [Approvals Reference](12-approvals-reference.md) | All approver roles |
| 13 | [Admin & Settings](13-admin-settings.md) | System Administrator |
| 99 | [Glossary](99-glossary.md) | All users |

## Personas in this manual

The manual refers to the following roles. These are the business roles visible
on records (CRM Executive, Sales Manager, Finance User, etc.) and are stored
as user lookups on the `Project__c`, `Booking__c` and related records. The
permission sets that govern access live under
`force-app/main/default/permissionsets/`:

- **Sales User** — standard sales rep, books units and maintains quotes.
- **Salesforce Lead Capture** — user who captures and qualifies leads from
  external sources.
- **CRM Executive (L1 – L4)** — post-sale customer relationship executives
  handling agreements, demands, collections, registration and possession
  handover. Specific roles on `Project__c` and `Booking__c`:
  - `New_Booking_CRM_Executive__c`
  - `Demands_Collections_CRM_Executive__c`
  - `Agreement_CRM_Executive__c`
  - `Registration_CRM_Executive__c`
  - `Possession_Handover_CRM_Executive__c`
  - `Cancellation_CRM_Executive__c`
  - `Customer_Service_CRM_Executive__c`
- **Finance User** — receipts, refunds, interest and demand approvals
  (`Finance_User__c` on `Project__c`).
- **Inspection Executive** — schedules inspections and closes snags
  (`Inspection_Executive__c` on `Project__c`).
- **Sales Head / CRM Head / CRM Manager / COO** — approver roles referenced
  on `Project__c` and `Booking__c`.
- **System Administrator** — configures the org, Round Robin, discount limits
  and integrations.

## What this manual does not cover

- Salesforce admin setup, deployment or test automation (see the root
  `README.md` and the `.github/` workflow files).
- The Business Requirements Document (`Trfiecta Projects Pvt. Ltd. Post Sales
  BRD Version 5 revised based on 3 demos.docx`) — that document remains the
  source of truth for functional requirements.
- Screenshots. Add screenshots from your running org if you need visual
  reference; the manual is kept metadata-driven so that it can be regenerated.
