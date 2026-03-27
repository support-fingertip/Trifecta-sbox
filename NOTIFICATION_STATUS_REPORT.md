# Mail & Notification Status Report — BRD vs Implementation

**Application:** Trifecta Post Sales CRM (Salesforce)
**BRD Version:** 4.0 (Approved 06/02/2026)
**Branch Tested:** `Durga_Prasad_Trifecta`
**Date:** 2026-03-27
**Prepared By:** QA Team

---

## Summary

| Category | Total Required | Implemented | Partially Implemented | Not Found | Implementation % |
|----------|---------------|-------------|----------------------|-----------|-----------------|
| Email Notifications | 30 | 22 | 5 | 3 | 73% |
| WhatsApp Notifications | 7 | 6 | 1 | 0 | 86% |
| SMS Notifications | 7 | 6 | 1 | 0 | 86% |
| In-App (Bell) Notifications | 12 | 10 | 1 | 1 | 83% |
| **Grand Total** | **56** | **44** | **8** | **4** | **78%** |

---

## Stage 1 — New Booking

| S.No | Notification Name | Channel | Trigger (When Sent) | Recipients | Auto/Manual | Status | File Reference | Remarks |
|------|-------------------|---------|---------------------|------------|-------------|--------|---------------|---------|
| 1 | Booking Confirmation WhatsApp | WhatsApp | On Booking creation | To: Customer Mobile | Automatic | IMPLEMENTED | `BookingTriggerHandler.cls:72-80` | ACTION '6' via WhatsappController |
| 2 | Booking Confirmation SMS | SMS | On Booking creation | To: Customer Mobile | Automatic | IMPLEMENTED | `BookingTriggerHandler.cls:72-80` | ACTION '6' via SMSHandler |
| 3 | Booking Owner Assignment Notification | In-App | On Booking OwnerId change | To: New Owner | Automatic | IMPLEMENTED | `BookingTriggerHandler.cls:163-213` | CustomNotification "Booking assigned to you" |
| 4 | Booking Stage Change Notification | In-App | On Stage__c change | To: Booking Owner | Automatic | IMPLEMENTED | `BookingTriggerHandler.cls:187-211` | CustomNotification "Booking moved to stage X" |
| 5 | Push To CRM Approval Notification | In-App | On Push_To_CRM__c submit | To: Management User | Automatic | IMPLEMENTED | `PushToCrmController.cls` | Approval Process: Booking_Push_to_CRM_Approval_Process |
| 6 | Booking Approval Status Notification | In-App | On Sub_Stages__c change | To: CreatedById | Automatic | IMPLEMENTED | `Booking_approval_notification.flow` | Submitted/Approved/Rejected notifications |
| 7 | Welcome Email (with attachments) | Email | Manual button click by CRM Executive | To: Customer Email, CC: CRM Head | Manual | PARTIALLY IMPLEMENTED | `WelcomeMailController.cls:189-365` | Email sends but BRD requires: Payment receipts, Cost sheet, Next payment demand letter, TDS & stamp duty (villa). Not all attachments auto-included |
| 8 | Welcome Email WhatsApp | WhatsApp | Triggered after Welcome Email sent | To: Customer Mobile | Automatic | IMPLEMENTED | `WelcomeMailController.cls` | ACTION '11' triggered after email send |
| 9 | Welcome Call Reminder (48 hrs) | Email | Scheduled — 48+ hrs after Booked Stage | To: Booking Owner + CRM Head/Manager | Automatic | IMPLEMENTED | `WelcomeCallReminderBatch.cls` | Checks Welcome_Call_Done__c = false AND Passed_Hour_after_Booked_Stage__c >= 48 |
| 10 | Finance Notification for Advance Amount | Email/In-App | On Booking creation | To: Finance Department | Automatic | NOT FOUND | — | BRD: "For advance amount finance approval is not required but notification will be sent for finance department." No implementation found |

---

## Stage 2 — Sale Agreement Execution

| S.No | Notification Name | Channel | Trigger (When Sent) | Recipients | Auto/Manual | Status | File Reference | Remarks |
|------|-------------------|---------|---------------------|------------|-------------|--------|---------------|---------|
| 11 | Agreement Reminder Email | Email | Scheduled — Agreement_Reminder_Date__c = TODAY | To: Customer Email | Automatic | IMPLEMENTED | `AgreementReminderScheduler.cls:1-66` | Template from General_Settings__c Type='Agreement Remainder'. Condition: Time_Extension_Requested__c = true |
| 12 | Agreement Payment Reminder 1 (Day 15) | Email | Scheduled — 15 days after Booking Approval | To: Customer Email | Automatic | PARTIALLY IMPLEMENTED | `AgreementPaymentReminderScheduler.cls` | BRD says "Day 10 before payment due date" but code uses Day 15 after Booking Approval. Day logic mismatch |
| 13 | Agreement Payment Reminder 2 (Day 25) | Email | Scheduled — 25 days after Booking Approval | To: Customer Email | Automatic | PARTIALLY IMPLEMENTED | `AgreementPaymentReminderScheduler.cls` | BRD says "Day 15 before due date" but code uses Day 25 after approval |
| 14 | Agreement Payment Reminder 3 (Day 35) | Email | Scheduled — 35 days after Booking Approval | To: Customer Email | Automatic | PARTIALLY IMPLEMENTED | `AgreementPaymentReminderScheduler.cls` | BRD says "Day 18 before due date" but code uses Day 35 after approval |
| 15 | Agreement 1-Week Before Reminder | Email | Scheduled — 1 week before Agreement date | To: Customer Email | Automatic | IMPLEMENTED | `AgreementReminderScheduler.cls` | Uses Agreement_Reminder_Date__c field |
| 16 | Agreement Time Extension Notification | In-App | On Time_Extension_Approval_Status__c change | To: Owner + CRM Head | Automatic | IMPLEMENTED | `Agreement_time_Extension_Approval_Notification.flow` | Pending/Approved/Rejected notifications |
| 17 | Termination Email to Customer | Email | Scheduled — Day 45 after Booking Approval | To: Customer Email | Automatic | IMPLEMENTED | `AgreementPaymentReminderScheduler.cls` | Sends termination notice with payment details |
| 18 | Termination Confirmation to Management | Email | Scheduled — Day 45 after Booking Approval | To: CRM Head, Sales Head, COO | Automatic | IMPLEMENTED | `AgreementPaymentReminderScheduler.cls` | Internal notification to management |
| 19 | Send Termination Email (Manual) | Email | CRM Manager clicks "Send Termination Email" | To: Customer Email | Manual | IMPLEMENTED | `BookingWelcomeMail.cls:sendEmailToCustomerCancellation()` | Sends cancellation/termination letter PDF |

---

## Stage 3 — Cancellation

| S.No | Notification Name | Channel | Trigger (When Sent) | Recipients | Auto/Manual | Status | File Reference | Remarks |
|------|-------------------|---------|---------------------|------------|-------------|--------|---------------|---------|
| 20 | Cancellation Request Initiated Notification | In-App | CRM Executive clicks "Request for Cancellation" | To: Sales User, Project Sales Head, CRM Manager, CRM Head | Automatic | IMPLEMENTED | `Booking_cancellation_request_initiated_Notification.flow` | Triggered when Is_Cancellation_Requested_by_Executive__c = true |
| 21 | Cancellation Status Notification (Submitted) | In-App | On Cancellation_Status__c = "Submitted" | To: CRM Manager + Owner | Automatic | IMPLEMENTED | `Booking_Cancellation_Notification_flow.flow` | "Booking has been Submitted for Cancellation Approval" |
| 22 | Cancellation Approved Notification | In-App | On Cancellation_Status__c = "Approved" | To: CRM Manager + Owner | Automatic | IMPLEMENTED | `Booking_Cancellation_Notification_flow.flow` | "Booking Cancellation has been Approved" |
| 23 | Cancellation Rejected Notification | In-App | On Cancellation_Status__c = "Rejected" | To: CRM Manager + Owner | Automatic | IMPLEMENTED | `Booking_Cancellation_Notification_flow.flow` | "Booking Cancellation has been Rejected" |
| 24 | Finance Notification on Cancellation Approval | In-App | On Cancellation_Status__c = "Approved" | To: Finance Lead | Automatic | IMPLEMENTED | `Cancellation_Process_Finance_Notification.flow` | "Please proceed with refund process" |
| 25 | Send Cancellation Mail to Customer | Email | CRM Manager clicks "Send Cancellation Mail" | To: Customer Email, CC: CRM Head | Manual | IMPLEMENTED | `CancellationMailController.cls:163-260` | Template merge with customer details. Updates Cancellation_Email_Sent__c |
| 26 | Cancellation Letter Email (with PDF) | Email | CRM Manager sends cancellation letter | To: Customer + Co-applicants | Manual | IMPLEMENTED | `BookingWelcomeMail.cls:sendEmailToCustomerCancellation()` | Attaches Cancellation_Letter.pdf |
| 27 | Cancellation Notification to Booking Sales User | In-App | CRM Executive requests cancellation | To: Sales_User__r | Automatic | IMPLEMENTED | `Booking_cancellation_request_initiated_Notification.flow` | Part of cancellation request flow |

---

## Stage 4 — Demands & Progressive Collections

| S.No | Notification Name | Channel | Trigger (When Sent) | Recipients | Auto/Manual | Status | File Reference | Remarks |
|------|-------------------|---------|---------------------|------------|-------------|--------|---------------|---------|
| 28 | Milestone Completion Notification to CRM Executive | In-App | On Master_Payment_Schedule__c Status = "Completed" | To: CRM Executives (Demands stage) | Automatic | IMPLEMENTED | `MasterPaymentScheduleTriggerHandler.cls:62-99` | CustomNotification: Master_Payment_Schedule_Completion_Notification |
| 29 | Demand Note Email (Individual) | Email | CRM Executive clicks "Raise Demand" | To: Customer Email + CRM Head/Manager | Manual | IMPLEMENTED | `DemandRaisedHelper.cls:54-149` | Subject: "Demand Note Raised - {DemandName}". Attaches Demand_Note.pdf |
| 30 | Demand Note Email (Bulk - Apartment) | Email | CRM Manager clicks "Raise All" in Bulk Demand | To: Multiple Customers | Manual | IMPLEMENTED | `BulkRaiseDemandController.cls` | Raises demands for all selected bookings. Calls DemandRaisedHelper |
| 31 | Demand Raised WhatsApp | WhatsApp | On Demand_Raised__c insert | To: Customer Mobile | Automatic | IMPLEMENTED | `DemandRaisedTriggerHandler.cls:1-27` | ACTION '8' via WhatsappController |
| 32 | Demand Raised SMS | SMS | On Demand_Raised__c insert | To: Customer Mobile | Automatic | IMPLEMENTED | `DemandRaisedTriggerHandler.cls:1-27` | ACTION '8' via SMSHandler |
| 33 | Payment Reminder 1 (Day 6 post demand) | Email | Scheduled — X1st_Reminder_Date__c = TODAY | To: Customer Email | Automatic | PARTIALLY IMPLEMENTED | `PendingPaymentReminderScheduler.cls` | Template: Demand_1ST_REMINDER. BRD says "Day 6 post demand" — verify reminder date calculation matches |
| 34 | Payment Reminder 2 (Day 8 post demand) | Email | Scheduled — X2nd_Reminder_Date__c = TODAY | To: Customer Email | Automatic | PARTIALLY IMPLEMENTED | `PendingPaymentReminderScheduler.cls` | Template: Demand_2ND_REMINDER. BRD says "Day 8 post demand" — verify |
| 35 | Payment Reminder 3 / Final (Day 10 post demand) | Email | Scheduled — X3rd_Interest_Reminder_Date__c = TODAY | To: Customer Email + CRM Head, Sales Head, COO | Automatic | PARTIALLY IMPLEMENTED | `PendingPaymentReminderScheduler.cls` | Template: Demand_3RD_REMINDER. BRD says "Day 10 final" — verify |
| 36 | Demand Reminder WhatsApp | WhatsApp | Triggered with payment reminders | To: Customer Mobile | Automatic | IMPLEMENTED | `PendingPaymentReminderScheduler.cls` | ACTION '9' via WhatsappController |
| 37 | Demand Reminder SMS | SMS | Triggered with payment reminders | To: Customer Mobile | Automatic | IMPLEMENTED | `PendingPaymentReminderScheduler.cls` | ACTION '9' via SMSHandler |
| 38 | Project Status Report (PSR) Email | Email | CRM Manager/Executive sends PSR | To: Customer Email | Manual | IMPLEMENTED | `ProjectStatusReportController.cls` | Supports file attachments (photos). Template: General_Settings Type='PSR Mail Template' |
| 39 | Revised Demand Note Email | Email | CRM Executive resends/revises demand | To: Customer Email | Manual | IMPLEMENTED | `DemandRaisedSave.cls:40-55` | Calls DocumentandEmailController.sendEmailGenerateDemand |
| 40 | Revised Demand WhatsApp | WhatsApp | After Revised Demand email sent | To: Customer Mobile | Automatic | IMPLEMENTED | `WhatsappController.cls` | ACTION '10' |
| 41 | Penalty Demand Note Email | Email | CRM Executive raises penalty demand | To: Customer Email | Manual | IMPLEMENTED | `DemandRaisedHelper.cls` | Uses PenaltyDemandNote.page VF template |

---

## Stage 5 — Registration

| S.No | Notification Name | Channel | Trigger (When Sent) | Recipients | Auto/Manual | Status | File Reference | Remarks |
|------|-------------------|---------|---------------------|------------|-------------|--------|---------------|---------|
| 42 | Final Demand + Registration Details Email | Email | CRM Executive sends final demand | To: Customer Email | Manual | NOT FOUND | — | BRD: "When final demand is sent, Registration required details list needs to be sent in same mail." No implementation found for combining these |
| 43 | Final Payment Received Email | Email | CRM Executive manually sends | To: Customer Email | Manual | IMPLEMENTED | `DocumentandEmailController.cls` | Uses "Send Email" standard activity |
| 44 | Receipt Email to Customer | Email | On Receipt creation / manual send | To: Customer + Co-applicants, CC: Owner | Auto + Manual | IMPLEMENTED | `DocumentandEmailController.cls:26-96`, `SendReceiptToCustomerClass.cls` | PDF receipt attached. Both auto (trigger) and manual (button) |
| 45 | Receipt WhatsApp | WhatsApp | On Receipt creation | To: Customer Mobile | Automatic | IMPLEMENTED | `WhatsappController.cls` | ACTION '7'. Note: ReceiptTriggerHandler.afterInsert is commented out — may not fire |
| 46 | NOC Uploaded Notification to CRM Executive | In-App/Email | Finance uploads NOC | To: CRM Executive | Automatic | NOT FOUND | — | BRD: "Once finance uploads NOC, CRM executive receives notification." No trigger/flow found |
| 47 | Registration Stage Completed Notification | In-App | CRM Executive marks stage complete | To: CRM Manager | Manual | IMPLEMENTED | `MarkBookingStageCompletedController.cls:42-67` | CustomNotification: "Stage 'Registration' marked as completed by {Executive}" |

---

## Stage 6 — Possession / Handover

| S.No | Notification Name | Channel | Trigger (When Sent) | Recipients | Auto/Manual | Status | File Reference | Remarks |
|------|-------------------|---------|---------------------|------------|-------------|--------|---------------|---------|
| 48 | Unit Readiness Email to Customer | Email | CRM Executive clicks "Unit Readiness" button | To: Customer Email, CC: CRM Head | Manual | IMPLEMENTED | `UnitReadinessMailController.cls:96+` | Template: General_Settings Type='Unit Readiness Mail'. Attaches Invitation_For_Inspection PDF |
| 49 | Inspection Assignment Notification | Email + In-App | On Inspection creation | To: Inspection Owner (Executive) | Automatic | IMPLEMENTED | `InspectionController.cls:78-100` | Email: "New Inspection Assigned". In-App: Inspection_Notification CustomNotificationType |
| 50 | Snag Completion / Inspection Completed Email | Email | On Inspection Status = 'Completed' (all snags resolved) | To: Customer Email | Automatic | IMPLEMENTED | `InspectionTriggerHandler.cls:76-120` | Subject: "Inspection Completed – All Issues Resolved" |
| 51 | Snag Resolved Notification to CRM Executive | In-App | On Inspection completion | To: Booking Owner | Automatic | IMPLEMENTED | `InspectionTriggerHandler.cls` | CustomNotification: "Snags Resolved – {BookingName}" |
| 52 | Inspection Completion Email (Manual) | Email | CRM Executive clicks send | To: Customer, CC: CRM Head | Manual | IMPLEMENTED | `InspectionCompletionMailController.cls:40-108` | Customizable HTML email. BRD says "manually instead of system automatically" |
| 53 | Inspection Reminder (Due Date) | Email | Scheduled — Expected/Extended Date = TODAY | To: Customer Email | Automatic | IMPLEMENTED | `InspectionReminderBatch.cls` | Subject: "Inspection Reminder" |
| 54 | Inspection Escalation (to CFO) | Email | Scheduled — Escalation_Date__c = TODAY | To: CFO Profile User | Automatic | IMPLEMENTED | `InspectionEsclationBatch.cls` | Escalation for overdue inspections |
| 55 | Inspection Extension Approval Notification | In-App | On Approval_Status__c change | To: Inspection Owner | Automatic | IMPLEMENTED | `Inspection_Approval_Notification.flow` | Pending/Approved/Rejected |
| 56 | Possession Stage Completed Notification | In-App | CRM Executive marks stage complete | To: CRM Manager | Manual | IMPLEMENTED | `MarkBookingStageCompletedController.cls` | Same stage completion mechanism |

---

## Stage 7 — Customer Service & Complaints

| S.No | Notification Name | Channel | Trigger (When Sent) | Recipients | Auto/Manual | Status | File Reference | Remarks |
|------|-------------------|---------|---------------------|------------|-------------|--------|---------------|---------|
| 57 | Ticket Closure Email to Customer | Email | On Ticket Status = "Completed" | To: Customer Email (Booking.Email__c) | Automatic (BRD says Manual) | PARTIALLY IMPLEMENTED | `TicketClosureEmailService.cls:1-282` | BRD says "manually by CRM executive" but code sends automatically via trigger. Behavior mismatch |

---

## Cross-Cutting Notifications

| S.No | Notification Name | Channel | Trigger (When Sent) | Recipients | Auto/Manual | Status | File Reference | Remarks |
|------|-------------------|---------|---------------------|------------|-------------|--------|---------------|---------|
| 58 | Stage Completion Notification (All Stages) | In-App | CRM Executive clicks "Mark Stage Complete" | To: CRM Manager | Manual | IMPLEMENTED | `MarkBookingStageCompletedController.cls` | Works for all stages |
| 59 | Refund Creation Notification to Finance | In-App | On Refund__c record creation | To: Finance Lead | Automatic | IMPLEMENTED | `Refund_Notification.flow` | "Refund for {Customer} has been created by {Owner}" |
| 60 | CC on All Emails (CRM Manager + CRM Executive) | Email | On every outgoing email | CC: CRM Manager, CRM Executive | Automatic | PARTIALLY IMPLEMENTED | Various controllers | BRD says "No limitation" on CC. Some controllers CC CRM Head only, not consistently CRM Manager + Executive on all emails |

---

## WhatsApp Notification Summary

| S.No | Scenario | ACTION Code | Trigger | Status | File Reference |
|------|----------|-------------|---------|--------|---------------|
| W1 | Welcome Mail WhatsApp | ACTION '11' | After Welcome Email sent | IMPLEMENTED | `WelcomeMailController.cls` |
| W2 | First-time Demand Note | ACTION '8' | On Demand_Raised__c insert | IMPLEMENTED | `DemandRaisedTriggerHandler.cls` |
| W3 | Revised Demand Note | ACTION '10' | After revised demand email | IMPLEMENTED | `WhatsappController.cls` |
| W4 | Penalty Demand Note | — | After penalty demand email | NOT FOUND | — | No specific WhatsApp action for penalty demand |
| W5 | Demand Reminders | ACTION '9' | With scheduled payment reminders | IMPLEMENTED | `PendingPaymentReminderScheduler.cls` |
| W6 | Receipts | ACTION '7' | On Receipt creation | PARTIALLY IMPLEMENTED | `ReceiptTriggerHandler.cls` | afterInsert method is COMMENTED OUT |
| W7 | Booking Confirmation | ACTION '6' | On Booking creation | IMPLEMENTED | `BookingTriggerHandler.cls` |

---

## Critical Gaps & Issues

### NOT FOUND (Missing Implementation)

| # | Notification | Stage | BRD Reference | Impact |
|---|-------------|-------|---------------|--------|
| 1 | Finance Notification for Advance Amount | Stage 1 | "Notification will be sent for finance department" | Finance unaware of advance payments |
| 2 | Final Demand + Registration Details Combined Email | Stage 5 | "Registration required details list needs to be sent in same mail" | Customers don't receive registration checklist with final demand |
| 3 | NOC Uploaded Notification to CRM Executive | Stage 5 | "CRM executive will receive notification saying NOC is attached" | CRM Executive unaware when finance uploads NOC |
| 4 | Penalty Demand Note WhatsApp | Stage 4 | "Penalty demand note" in WhatsApp list | No WhatsApp for penalty demands specifically |

### PARTIALLY IMPLEMENTED (Behavior Mismatch)

| # | Notification | Issue | BRD Says | Code Does |
|---|-------------|-------|----------|-----------|
| 1 | Welcome Email Attachments | Missing attachments | Include: receipts, cost sheet, demand letter, TDS/stamp duty | Sends email but not all documents auto-attached |
| 2 | Agreement Payment Reminders (Day 10/15/18) | Day calculation mismatch | Day 10, 15, 18 BEFORE payment due date | Day 15, 25, 35 AFTER Booking Approval |
| 3 | Demand Payment Reminders (Day 6/8/10) | Day calculation needs verification | Day 6, 8, 10 POST demand raised | Uses X1st/X2nd/X3rd_Reminder_Date__c fields — actual day offset unclear |
| 4 | Ticket Closure Email | Auto vs Manual | "Manually by CRM executive" | Sends automatically via trigger on status change |
| 5 | CC on All Emails | Inconsistent CC | "CC to CRM manager and CRM executive — No limitation" | Some emails CC CRM Head only, not all CC both manager + executive |
| 6 | Receipt WhatsApp | Commented out trigger | Should fire on receipt creation | `ReceiptTriggerHandler.afterInsert()` is commented out |
| 7 | Demand Reminders WhatsApp/SMS | Linked to email reminders | Should send with each reminder | Fires only with 3rd reminder (Scheduler level) — verify all 3 fire |

---

## Verification Checklist for QA

| # | Check | How to Verify |
|---|-------|--------------|
| 1 | Welcome Email sends with ALL required attachments | Create booking → send welcome email → verify PDF attachments |
| 2 | Agreement reminders fire on correct days | Set booking date → wait for Day 10/15/18 → check email |
| 3 | Demand reminders fire on Day 6/8/10 | Raise demand → check reminder dates on Payment Schedule |
| 4 | WhatsApp fires for receipts | Create receipt → check WhatsApp trigger (ReceiptTriggerHandler commented out!) |
| 5 | CC includes CRM Manager on ALL emails | Send any email → verify CC list |
| 6 | Ticket closure is manual not auto | Close ticket → check if email sends automatically |
| 7 | Finance gets advance payment notification | Create booking with advance → check finance notifications |
| 8 | NOC upload triggers notification | Upload NOC document → check CRM Executive notifications |
