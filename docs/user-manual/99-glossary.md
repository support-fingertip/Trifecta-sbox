# 99 — Glossary

A quick reference for the objects, roles, fields and acronyms used
throughout this manual. Objects are listed with their Salesforce API
name so you can find them under `force-app/main/default/objects/` in
this repository.

## Business / domain terms

| Term | Meaning |
|---|---|
| BRD | Business Requirements Document — the functional specification for the Trifecta Post Sales project, present at the repo root as a `.docx`. |
| CP | Channel Partner — an external broker or agency that brings buyers to Trifecta. |
| CRM | Customer Relationship Management — the post-sale customer lifecycle after a booking is created. |
| DLP | Defect Liability Period — the period after handover during which Trifecta is responsible for fixing defects. |
| DSS | Disbursement Sanction Statement — document from the customer's banker confirming the home-loan disbursement plan. |
| GRE | Guest Relations Executive — sales gallery user who captures walk-in enquiries. |
| KYC | Know Your Customer — identity verification documents (PAN, Aadhaar, photograph). |
| LOU | Letter Of Undertaking — legal document committing a customer to certain obligations. |
| NOC | No Objection Certificate — letter issued to a bank or authority stating Trifecta has no objection to a transaction. |
| PLC | Preferred Location Charge — premium levied on units with a better view, corner position, etc. |
| Round Robin | An assignment queue that distributes leads fairly across sales users / CPs. |
| Slab | A stage of construction against which a payment milestone is triggered. |
| Snag | A defect identified during a pre-handover inspection. |
| Swap | Moving a customer from one booked unit to another. |
| TAT | Turn-Around Time. |
| TDS | Tax Deducted at Source — income tax withheld by the buyer when paying. |
| UDS | Undivided Share of Land — the buyer's share of common land. |

## Custom objects (Salesforce API name → plain English)

| API name | What it represents |
|---|---|
| `Additional_Charges__c` | Extra charges raised alongside a booking (club house, amenity, etc.) |
| `Apex_Log__c` | Custom Apex log entries |
| `Block__c` | A block or phase within a project |
| `Booking__c` | A customer booking — the central post-sales record |
| `Call_Detail__c`, `Call_Detail1__c` | A logged phone call |
| `Campaign__c`, `Marketing_Campaign__c` | A marketing / sourcing campaign |
| `Car_Parking__c` | A car parking unit |
| `Channel_Partner__c` | A channel partner / broker |
| `Co_Applicant__c` | An additional applicant on a booking |
| `CtiNotification__e` | Platform event carrying CTI call notifications |
| `Demand_Raised__c` | An invoice raised against a booking for a milestone |
| `Discount_Limit__c` | Global maximum discount allowed on a quote |
| `Follow_up__c` | A scheduled follow-up on a lead |
| `General_Settings__c` | Singleton custom setting for org-wide defaults |
| `In_App_Checklist_Settings__c` | Toggles for in-app checklists |
| `Inspection__c` | A pre-handover inspection record |
| `Interest_Amount_Line_Item__c` | The interest component of a demand or receipt |
| `Interest_Percentage__c` | A delay-interest slab definition |
| `Landing_Number__c` | Incoming phone number mapping |
| `Lead_Assigned__e` | Platform event fired when a lead is assigned |
| `Lead_Unqualification__c` | Audit record for an unqualified lead |
| `MCUBE_Object_Api__c` | Raw M-Cube CTI integration payload |
| `Master_Payment_Schedule__c` | The booking-level payment schedule |
| `Param_Mapping__c` | Parameter mapping for third-party integrations |
| `Payment_Plan__c` | A milestone / payment plan template |
| `Payment_schedule__c` | A milestone row within the master schedule |
| `Plot__c` | A sellable unit — flat, plot, villa or row house |
| `Project_Discount_Limit__c` | Per-project override of the discount limit |
| `Project__c` | A real-estate project master |
| `Quote__c` | A cost sheet / quotation for a unit |
| `Receipt_Line_Item__c` | An allocation row on a receipt |
| `Receipt__c` | A header record for a payment received |
| `Refund__c` | A refund of money to a customer |
| `Related_Source__c` | Source mapping used when converting leads |
| `Round_Robin_Member__c` | A member of a Round Robin queue |
| `Round_Robin__c` | A Round Robin assignment queue |
| `Site_Visit__c` | A recorded site visit |
| `Snag_List__c` | A defect raised during inspection |
| `Ticket__c` | A customer support ticket |

## Custom metadata types (`__mdt`)

| API name | Purpose |
|---|---|
| `Country_Code_Mapping__mdt` | Dialing code per country |
| `Lead_Assignment_Config__mdt` | Lead assignment rules |
| `Mcube__mdt` | M-Cube CTI configuration |
| `Project_Name_Mappings__mdt` | Project aliases / external names |
| `SMS_Setting__mdt` | SMS gateway configuration |
| `Whatsapp_Setting__mdt` | WhatsApp gateway configuration |

## Roles referenced in this manual

| Role | Where it is stored | Responsibility |
|---|---|---|
| Sales Head | `Project__c.Sales_Head__c`, `Project__c.Project_Sales_Head__c` | Top-level sales approver for a project |
| CRM Head | `Project__c.CRM_Head__c` | Head of post-sales CRM operations |
| CRM Manager | `Project__c.CRM_Manager__c` | Day-to-day CRM manager |
| COO | `Project__c.COO__c`, `Booking__c.COO__c` | Senior approver for escalated items |
| Finance User | `Project__c.Finance_User__c` | Receipt / refund / demand finance approvals |
| Inspection Executive | `Project__c.Inspection_Executive__c` | Performs inspections and closes snags |
| Legal Team | `Project__c.Legal_Team__c` | Legal document review |
| New Booking CRM Executive | `Project__c.New_Booking_CRM_Executive__c` | Owns the booking form process |
| Agreement CRM Executive | `Project__c.Agreement_CRM_Executive__c`, `Booking__c.Agreement_CRM_Executive__c` | Owns sale agreement execution |
| Registration CRM Executive | `Project__c.Registration_CRM_Executive__c` | Owns sale-deed registration |
| Possession Handover CRM Executive | `Project__c.Possession_Handover_CRM_Executive__c` | Owns possession handover |
| Cancellation CRM Executive | `Project__c.Cancellation_CRM_Executive__c`, `Cancellation_User__c` | Owns cancellation process |
| Customer Service CRM Executive | `Project__c.Customer_Service_CRM_Executive__c` | Owns customer tickets |
| Demands & Collections CRM Executive | `Project__c.Demands_Collections_CRM_Executive__c` | Owns demand / reminder collections |
| Source Manager | `Channel_Partner__c.Source_Manager__c` | Owns the CP relationship |

## Permission sets

| Name | Purpose |
|---|---|
| `Sales_User` | Standard sales rep access |
| `Salesforce_Lead_Capture` | External / partner lead capture |
| `Custom_Notification_Access` | Required to receive in-app bell notifications from flows |

## Frequently used field suffixes

| Suffix | Meaning |
|---|---|
| `__c` | Custom field or custom object |
| `__mdt` | Custom metadata type |
| `__e` | Platform event |
| `_Sent__c` | Boolean audit flag — true once the document / email was sent |
| `_Status__c` | Picklist representing lifecycle state |
| `Approval_status__c` | Pending / Approved / Rejected |
| `_CRM_Executive__c` | Lookup to the CRM user responsible at a particular stage |

## Source files in this repository

If you need to go deeper than this manual, the ground truth lives in:

- `force-app/main/default/objects/<Object>/fields/` — every field with
  its type, picklist values and help text.
- `force-app/main/default/objects/<Object>/validationRules/` — the
  validation errors users see on save.
- `force-app/main/default/classes/` — Apex controllers behind every
  button.
- `force-app/main/default/flows/` — declarative approvals and
  notifications.
- `force-app/main/default/lwc/`, `force-app/main/default/aura/` — UI
  components.
- `force-app/main/default/pages/` — Visualforce pages used for
  printable documents.
- `force-app/main/default/permissionsets/` — permission set
  definitions.
- `Trfiecta Projects Pvt. Ltd. Post Sales BRD Version 5 revised based
  on 3 demos.docx` — the authoritative business requirements.
