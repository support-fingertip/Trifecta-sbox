global class PendingPaymentReminderScheduler implements Database.Batchable<SObject>, Database.Stateful, Schedulable {
    
    global Database.QueryLocator start(Database.BatchableContext bc) {
        return Database.getQueryLocator([
            SELECT Id, Pending_Amount__c, S_No__c, Booking__c, Received_Amount1__c, Demanded_Date__c
            FROM Payment_Schedule__c
            WHERE Is_Demanded__c = true
            AND Pending_Amount__c > 0
            AND Booking__r.Stage__c NOT IN ('Unit Swap', 'Cancellation')
            AND Booking__r.Disable_Automatic_Payment_Reminders__c != true AND Demanded_Date__c != null AND S_No__c!= 1
            ORDER BY Booking__c, S_No__c ASC
        ]);
    }
    
    global void execute(Database.BatchableContext bc, List<Payment_Schedule__c> scope) {
        Date today = Date.today();
        list<Booking__c> cancelBookings = new list<Booking__c>();
        Map<Id, List<Payment_Schedule__c>> bookingToSchedules = new Map<Id, List<Payment_Schedule__c>>();
        Set<Id> bookingIds = new Set<Id>();
        Map<Id, Integer> bookingToDays = new Map<Id, Integer>();
        
        // Group by booking and determine days difference
        for (Payment_Schedule__c ps : scope) {
            if (ps.Booking__c == null || ps.Demanded_Date__c == null) continue;
            Integer daysDiff = ps.Demanded_Date__c.daysBetween(today);
            
            // Process only if within target intervals
            if (daysDiff == 7 || daysDiff == 14 || daysDiff == 21 || daysDiff == 28 || daysDiff == 35 || daysDiff == 42 || daysDiff == 49
                || daysDiff == 79) {
                    bookingIds.add(ps.Booking__c);
                    if (!bookingToSchedules.containsKey(ps.Booking__c)) {
                        bookingToSchedules.put(ps.Booking__c, new List<Payment_Schedule__c>());
                    }
                    bookingToSchedules.get(ps.Booking__c).add(ps);
                    
                    // Store highest interval for that booking
                    if (!bookingToDays.containsKey(ps.Booking__c) || daysDiff > bookingToDays.get(ps.Booking__c)) {
                        bookingToDays.put(ps.Booking__c, daysDiff);
                    }
                }
        }
        
        if (bookingIds.isEmpty()) return;
        
        // Fetch booking info
        Map<Id, Booking__c> bookingMap = new Map<Id, Booking__c>([
            SELECT Id, First_Applicant_Name__c, Email__c, Plot__r.Name, Project1__r.Name,Owner_Full_Name__c,CRM_Head__r.Email,Sales_Head__r.Email,COO__r.Email
            FROM Booking__c
            WHERE Id IN :bookingIds
        ]);
        
        List<Messaging.SingleEmailMessage> emails = new List<Messaging.SingleEmailMessage>();
        
        for (Id bookingId : bookingToSchedules.keySet()) {
            Booking__c booking = bookingMap.get(bookingId);
            if (booking == null || String.isBlank(booking.Email__c)) continue;
            
            List<Payment_Schedule__c> schedules = bookingToSchedules.get(bookingId);
            Integer days = bookingToDays.get(bookingId);
            
            // Calculate total pending
            Decimal totalPending = 0;
            for (Payment_Schedule__c ps : schedules) {
                totalPending += ps.Pending_Amount__c;
            }
            
            String projectName = (booking.Project1__r != null ? booking.Project1__r.Name : '');
            String unitName = (booking.Plot__r != null ? booking.Plot__r.Name : '');
            String formattedAmount = '₹' + String.valueOf(totalPending.setScale(2));
            
            // Subject & Body
            String subject = '';
            String body = '';
            
            // ======================= 7th Day =======================
            if (days == 7) {
                subject = 'Payment Reminder for Plot/Unit No. ' + unitName + ' at Zuari ' + projectName;
                body =
                    'Dear Sir/Madam,<br/><br/>' +
                    'Greetings from Zuari.<br/><br/>' +
                    'This is a gentle reminder that the payment of ' + formattedAmount + 
                    ' towards Plot/Unit No. ' + unitName + ' at Zuari ' + projectName +
                    ' was due as per the Final Demand Letter previously sent to you.<br/><br/>' +
                    'We kindly request you to treat this reminder as a priority and make the payment at the earliest along with interest thereon.<br/><br/>' +
                    'Should you require any clarification or assistance, please feel free to contact us. We’ll be happy to help.<br/><br/>' +
                    'Thank you for your prompt attention to this matter.<br/><br/>' +
                    'Warm regards,<br/><strong>Zuari Infraworld India Ltd.</strong>';
            }
            
            // ======================= 14th Day =======================
            else if (days == 14) {
                subject = 'Second Reminder: Overdue Payment for Unit No. ' + unitName + ' at Zuari ' + projectName;
                body =
                    'Dear Sir/Madam,<br/><br/>' +
                    'Greetings from Zuari.<br/><br/>' +
                    'This is in reference to our earlier communication dated ' + booking.CreatedDate.format() + 
                    ', where we reminded you about the outstanding payment of ' + formattedAmount +
                    ' towards Unit No. ' + unitName + ' at Zuari ' + projectName + '.<br/><br/>' +
                    'To date, we have neither received the payment nor any communication explaining the reason for the delay. Please note that the amount is now seriously overdue.<br/><br/>' +
                    'As the payment deadline has passed, we request you to either settle the outstanding amount or contact us to discuss the matter within the next 7 days.<br/><br/>' +
                    'Kindly be advised that failure to make the payment or respond within this period may lead to the cancellation of your booking as per the applicable terms.<br/><br/>' +
                    'We look forward to hearing from you within the next 7 days.<br/><br/>' +
                    'Warm regards,<br/><strong>Zuari Infraworld India Ltd.</strong>';
            }
            
            // ======================= 21–35 Days =======================
            else if (days == 21 || days == 28 || days == 35) {
                subject = 'Final Reminder: Immediate Action Required – Overdue Payment for Unit No. ' + unitName + ' at Zuari ' + projectName;
                body =
                    'Dear Sir/Madam,<br/><br/>' +
                    'Greetings from Zuari.<br/><br/>' +
                    'This is to formally inform you that, despite multiple reminders—including our last communication dated ' + booking.CreatedDate.format() +
                    '—the payment of ' + formattedAmount + ' towards Unit No. ' + unitName + 
                    ' at Zuari ' + projectName + ' remains unpaid.<br/><br/>' +
                    'We have also attempted to reach you through phone calls, messages, and emails, but have not received any confirmation or commitment regarding the clearance of the outstanding amount.<br/><br/>' +
                    'As previously communicated, delayed payments are subject to interest on the outstanding amount. Continued non-response will leave us with no choice but to escalate this matter to higher authorities for appropriate action.<br/><br/>' +
                    'Please note, this is our final reminder, and the payment is now critically overdue.<br/><br/>' +
                    'We urge you to take immediate action by either:<br/>' +
                    '<ul>' +
                    '<li>Clearing the outstanding dues, or</li>' +
                    '<li>Getting in touch with us within the next 7 days to discuss your situation.</li>' +
                    '</ul>' +
                    'Failure to do so will result in further steps being taken, which may include:<br/>' +
                    '<ul>' +
                    '<li>Cancellation of your booking, and/or</li>' +
                    '<li>Forfeiture of any amounts already paid, as per the terms and conditions of your agreement.</li>' +
                    '</ul>' +
                    'We sincerely hope this matter can be resolved amicably, and we request your urgent attention and cooperation.<br/><br/>' +
                    'Thank you.<br/><br/>' +
                    'Warm regards,<br/><strong>Zuari Infraworld India Ltd.</strong>';
            }
            
            // ======================= 42nd Day (Pre-Termination) =======================
            else if (days == 42) {
                subject = 'Pre-Termination Notice – Outstanding Payment for Unit No. ' + unitName + ' at Zuari ' + projectName;
                body =
                    'Dear Sir/Madam,<br/><br/>' +
                    'Greetings from Zuari.<br/><br/>' +
                    'This is to notify you that your payment of ' + formattedAmount + 
                    ' towards Unit No. ' + unitName + ' at Zuari ' + projectName +
                    ' has been overdue for more than 6 weeks despite repeated reminders.<br/><br/>' +
                    'Please note that as per the terms of your booking, continued default in payment may lead to the termination of your allotment.<br/><br/>' +
                    'You are hereby given a final opportunity to clear all outstanding dues within 7 days from the date of this notice to avoid termination.<br/><br/>' +
                    'In case of any difficulty or query, please contact our office immediately.<br/><br/>' +
                    'Warm regards,<br/><strong>Zuari Infraworld India Ltd.</strong>';
            }
            
            // ======================= 49th Day (Termination) =======================
            else if (days == 49) {
                subject = 'Termination Notice – Unit No. ' + unitName + ' at Zuari ' + projectName;
                body =
                    'Dear Sir/Madam,<br/><br/>' +
                    'Greetings from Zuari.<br/><br/>' +
                    'We regret to inform you that despite multiple communications and reminders, the payment of ' + formattedAmount +
                    ' towards Unit No. ' + unitName + ' at Zuari ' + projectName +
                    ' has not been received.<br/><br/>' +
                    'As per the terms and conditions of your booking, your allotment stands terminated with immediate effect.<br/><br/>' +
                    'Any further communication regarding this matter will be considered only at the sole discretion of the management.<br/><br/>' +
                    'For any clarifications, please reach out to our Customer Relations Department.<br/><br/>' +
                    'Warm regards,<br/><strong>Zuari Infraworld India Ltd.</strong>';
                
                
                // For Sending Termination Confirmation mail to CFO , Sales Head and respective user;
                
                String subjectcc = 'Termination Confirmation Sent to Customer for Unit ' + unitName;
                String bodycc = ''
                    + '<p>Dear Team,</p>'
                    + '<p>This is to inform you that a <strong>termination confirmation email</strong> has been successfully sent to the customer regarding <strong>Unit ' + booking.Plot__r.Name + '</strong>.</p>'
                    + '<p><strong>Termination Details:</strong></p>'
                    + '<table style="border-collapse: collapse; border: 1px solid #ddd;">'
                    + '<tr><td style="padding: 6px; border: 1px solid #ddd;">Project Name</td><td style="padding: 6px; border: 1px solid #ddd;">' +projectName + '</td></tr>'
                    + '<tr><td style="padding: 6px; border: 1px solid #ddd;">Customer Name</td><td style="padding: 6px; border: 1px solid #ddd;">' + booking.First_Applicant_Name__c + '</td></tr>'
                    + '<tr><td style="padding: 6px; border: 1px solid #ddd;">Customer Email</td><td style="padding: 6px; border: 1px solid #ddd;">' + booking.Email__c + '</td></tr>'
                    + '<tr><td style="padding: 6px; border: 1px solid #ddd;">Initiated By</td><td style="padding: 6px; border: 1px solid #ddd;">' + booking.Owner_Full_Name__c + '</td></tr>'
                    + '</table>'
                    + '<br/>'
                    + '<p><strong>Summary:</strong><br/>The termination confirmation mail has been sent to the customer as per the standard communication process. '
                    + 'All concerned departments are requested to update their respective systems accordingly.</p>'
                    + '<ul>'
                    + '<li><strong>Sales Team</strong> – Update lead/opportunity status to Terminated</li>'
                    + '<li><strong>Finance Team</strong> – Process refund or financial settlement as applicable</li>'
                    + '<li><strong>CRM Team</strong> – Ensure CRM record accuracy</li>'
                    + '</ul>'
                    + '<br/>'
                    + '<p>Best Regards,<br/><strong>CRM Notification System</strong><br/>' + 'Zuari' + '</p>';
                List<String> toaddress = new List<String>();
                if(booking.CRM_Executive__r.Email!=null){
                    toaddress.add(booking.CRM_Head__r.Email);
                }
                if(booking.CRM_Head__r.Email!=null){
                    
                    toaddress.add(booking.CRM_Head__r.Email);
                }
                if(booking.Sales_Head__r.Email!=null){
                    
                    toaddress.add(booking.Sales_Head__r.Email);
                }
                if(booking.COO__r.Email!=null){
                    toaddress.add(booking.COO__r.Email);
                }
                Messaging.SingleEmailMessage mailcfo = new Messaging.SingleEmailMessage();
                mailcfo.setToAddresses(toaddress);
                mailcfo.setSubject(subject);
                mailcfo.setHtmlBody(body);
                mailcfo.setSaveAsActivity(false);
                emails.add(mailcfo);
                
                
            }
            else if (days == 79) {
                cancelBookings.add(booking);
            }
            
            // Send email
            if (!String.isBlank(subject) && !String.isBlank(body)) {
                Messaging.SingleEmailMessage mail = new Messaging.SingleEmailMessage();
                mail.setToAddresses(new String[] { booking.Email__c });
                mail.setSubject(subject);
                mail.setHtmlBody(body);
                emails.add(mail);
            }
        }
        
        if (!emails.isEmpty()) {
            Messaging.sendEmail(emails);
        }
        if(!cancelBookings.isEmpty()){
            BookingController.changeUnitStatus(cancelBookings);
        }
    }
    
    global void finish(Database.BatchableContext bc) {
        // Optional logging
    }
    
    global void execute(SchedulableContext sc) {
        Database.executeBatch(new PendingPaymentReminderScheduler(), 100);
    }
}