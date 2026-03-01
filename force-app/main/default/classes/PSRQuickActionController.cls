public with sharing class PSRQuickActionController {
      
    public class BookingWrapper {
        @AuraEnabled
        public Booking__c booking { get; set; }
        @AuraEnabled
        public Payment_Schedule__c currentMilestone { get; set; }
        
        // Constructor
        public BookingWrapper(Booking__c booking, Payment_Schedule__c currentMilestone) {
            this.booking = booking;
            this.currentMilestone = currentMilestone;
        }
    }
    
    @AuraEnabled
    public static List<Payment_schedule__c> getPaymentSchedules(Id bookingId) {
        return [
            SELECT Id, Name, status__c,S_No__c, Pending_Amount__c
            FROM Payment_schedule__c
            WHERE Booking__c = :bookingId
            ORDER BY S_No__c asc
        ];
    }
    @AuraEnabled
    public static BookingWrapper getBookingRecord(Id recordId) {
        Booking__c booking = [
            SELECT Id, Project__c, Project1__r.Name, 
            Total_received_Amount__c, First_Applicant_Name__c
            FROM Booking__c 
            WHERE Id = :recordId 
            LIMIT 1
        ];
        
        List<Payment_Schedule__c> psRecordList = [
            SELECT Id, Name, S_No__c, Completed_Date__c, Payment_percent__c
            FROM Payment_Schedule__c
            WHERE Status__c = 'Completed' AND Booking__c = :recordId
            ORDER BY S_No__c DESC 
            LIMIT 1
        ];
        
        Payment_Schedule__c currentMilestone = psRecordList.isEmpty() ? null : psRecordList[0];
        
        // Return the wrapper instance
        return new BookingWrapper(booking, currentMilestone);
    }
    
    
    @AuraEnabled
    public static String sendPSREmail(Id bookingId, Id scheduleId, String messageBody, List<Id> fileIds) {
        Booking__c booking = [SELECT Id,Email__c FROM Booking__c WHERE Id = :bookingId LIMIT 1];
        List<Messaging.Emailfileattachment> fileAttachments = new List<Messaging.Emailfileattachment>();
        for (ContentDocumentLink cdl : [
            SELECT ContentDocument.LatestPublishedVersionId, ContentDocument.Title
            FROM ContentDocumentLink WHERE LinkedEntityId = :bookingId AND ContentDocumentId IN :fileIds
        ]) {
            // Fetch the ContentVersion for the file
            ContentVersion cv = [
                SELECT VersionData, Title FROM ContentVersion WHERE ContentDocumentId = :cdl.ContentDocumentId ORDER BY VersionNumber DESC LIMIT 1
            ];
            Messaging.Emailfileattachment efa = new Messaging.Emailfileattachment();
            efa.setFileName(cv.Title);
            efa.setBody(cv.VersionData);
            fileAttachments.add(efa);
        }
        
        Messaging.SingleEmailMessage mail = new Messaging.SingleEmailMessage();
        mail.setToAddresses(new String[] { booking.Email__c });
        mail.setSubject('Project Status Report');
        mail.setHtmlBody(messageBody);
        mail.setSaveAsActivity(true);
        mail.setFileAttachments(fileAttachments);
        Messaging.sendEmail(new Messaging.SingleEmailMessage[] {mail});
        return 'SUCCESS';
    }
}