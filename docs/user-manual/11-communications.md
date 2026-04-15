# 11 — Communications (Dialer, SMS, Email, WhatsApp)

## Overview

This module covers how users make and receive calls, send SMS and
WhatsApp messages, and rely on email notifications inside the Trifecta
Post Sales application. Every outgoing / incoming interaction is logged
as a `Call_Detail__c` record so that reporting and call-back workflows
are possible.

## Who uses it

- **GRE / Sales Executive** — uses the dialer and WhatsApp messaging
  most frequently.
- **Demands & Collections CRM Executive** — sends bulk reminder SMS.
- **Marketing User** — sends bulk SMS via `booking_SendBulkSMS.page` /
  `SendBulkSMSCOLightning.page`.
- **Admin** — configures M-Cube (CTI provider), WhatsApp and SMS
  gateway settings.

## Key objects and tabs

| Object | Tab | Purpose |
|---|---|---|
| `Call_Detail__c`, `Call_Detail1__c` | Call Detail | Call logs |
| `Landing_Number__c` | Landing Number | Incoming phone number → project mapping |
| — | Dialer | Soft-phone tab (Aura `CallPanel`) |
| `MCUBE_Object_Api__c` | MCUBE Object Api | Integration payload log |
| `Mcube__mdt` | — | M-Cube configuration (custom metadata) |
| `Whatsapp_Setting__mdt` | — | WhatsApp gateway configuration |
| `SMS_Setting__mdt` | — | SMS gateway configuration |
| `Country_Code_Mapping__mdt` | — | Country dialing code mapping |
| `Param_Mapping__c` | — | Parameter mapping for third-party integrations |
| `CtiNotification__e` | — | Platform event carrying CTI notifications |

## Screens

| Screen | Type | Purpose |
|---|---|---|
| `Dialer.page` / `calland.page` / `routeCall.page` | VF | Dialer and call routing pages |
| `CallPanel` / `Click2Call` / `MakeCall` | Aura | Soft-phone panel and click-to-call buttons |
| `CallStatusComp` | Aura | Shows current call status |
| `massdialer` | Aura | Bulk outbound dialing |
| `booking_SendBulkSMS.page`, `SendBulkSMSCOLightning.page` | VF | Bulk SMS screens |
| `mCubeLightningPage` / `mCube_Setup` | Aura | M-Cube integration admin pages |

## Workflows

### 1. Make an outbound call

1. On any lead, booking or contact record, click **Call** / **Click2Call**
   (Aura `Click2Call` / `MakeCall`).
2. The `Dialer.page` opens, routing through M-Cube (or the configured
   CTI provider).
3. The `routeCall.page` handles the two-leg call (agent's desk phone →
   customer).
4. After the call, the CTI provider posts a status to the
   `MCUBE_Object_Api__c` object and a `Call_Detail__c` record is
   created. `Call_Detail__c` links to the lead/booking so you can see
   the full call history on each record.
5. Use the **Call Panel** (Aura `CallPanel`, `CallStatusComp`) to
   capture disposition (Interested / Not Interested / Callback /
   Wrong Number).

### 2. Receive an inbound call

1. When a call lands on a configured **Landing Number**, the
   `CtiNotification__e` platform event fires.
2. The `leadAssignmentSubscriber` LWC listens to the event and opens
   the Dialer panel for the assigned user.
3. The `Dialercontroller` Apex class creates the `Call_Detail__c`
   record and looks up an existing lead by phone number — if found,
   the call is attached to that lead; otherwise, a new lead is created
   using the **GRE Form** / walk-in component logic.

### 3. Bulk dialer for collections

Use the **massdialer** Aura component to dial a list of customers in
sequence — typically used by the Demands & Collections CRM Executive to
call customers with overdue demands. Each call creates a
`Call_Detail__c` record automatically.

### 4. Send a bulk SMS

1. Open **booking_SendBulkSMS.page** or the Lightning version
   **SendBulkSMSCOLightning.page**.
2. Filter the recipients (by project, booking stage, last SMS sent
   date, etc.).
3. Pick or compose the message template. The gateway is configured via
   `SMS_Setting__mdt`.
4. Click **Send**. The delivery status for each message is written
   back through the `Param_Mapping__c` / gateway response handler.

### 5. Send a WhatsApp message

- Individual WhatsApp messages are sent from record actions (for
  example, site visit feedback link). The `WhatsAppTriggerHandler`
  Apex class routes the message through the configured
  `Whatsapp_Setting__mdt` gateway.
- Delivery status is stored back on the record in fields like
  `Site_Visit__c.WhatsApp_Message_Status__c`,
  `WhatsApp_Message_DateTime__c` and `WhatsApp_Message_Sent__c`.

### 6. Email notifications

The org sends emails for many business events. The main ones are:

- **Booking form sent** → customer
- **Quote PDF sent** → customer
- **Demand note / revised demand / penalty demand** → customer
- **Receipt PDF** → customer
- **Cancellation letter / cancellation agreement** → customer
- **Site visit confirmation** → customer and sales team
- **Inspection invite** → customer
- **Ticket closure email** → customer (`TicketClosureEmailService`)
- **Welcome mail** (Aura `WelcomeMail`) → customer after booking
- **Lead alerts / follow-up reminders** → internal users

Custom notification flows (in-app bell notifications) use the
**Custom Notification Access** permission set. Make sure every user
who should receive in-app notifications has this set assigned.

## Automations you will experience

| Component | When it runs | Effect |
|---|---|---|
| `CallDetailTrigger` | Call Detail insert/update | Keeps disposition and lead linkage consistent |
| `Dialercontroller` (Apex) | Incoming / outgoing call | Creates call log |
| `leadAssignmentSubscriber` (LWC) | CtiNotification event | Opens the dialer for the assigned user |
| `WhatsAppTriggerHandler` (Apex) | Record saved with WhatsApp trigger | Sends WhatsApp via gateway |
| `SMSHandler` (Apex) | Record saved with SMS trigger / Bulk SMS | Sends SMS via gateway |
| `AddNoteController` | Add-note action | Writes a note to the record |

## Common issues and tips

- **Dialer not opening on inbound call**: ensure the user has the
  **Custom Notification Access** permission set and is a member of the
  Round Robin / landing number mapping.
- **WhatsApp status stuck on "Pending"**: check the gateway status via
  `MCUBE_Object_Api__c` entries and ask admin to validate the
  `Whatsapp_Setting__mdt` token.
- **Bulk SMS not sending**: check the `SMS_Setting__mdt` record for the
  active gateway credentials and confirm the templates are approved by
  the gateway.
- **Duplicate call logs**: if the same call creates two Call Detail
  records, the M-Cube webhook may be firing twice — report it to admin
  to review `MCUBE_Object_Api__c` raw payloads.
- **Email bounces**: always set a valid customer email on the booking —
  many downstream flows (receipts, demands, closure emails) depend on
  it.
