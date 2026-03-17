public with sharing class UnitReadinessMailController {

    @AuraEnabled
    public static Map<String, Object> getBookingData(Id bookingId) {
        Map<String, Object> result = new Map<String, Object>();

        Booking__c booking = [
            SELECT Id, Name, Customer_Name__c, Customer_Email__c,
                   Plot_No__c, Project_Name__c, Unit_Type__c,
                   Unit_Readiness_Date_Time__c, CRM_Head_Email__c,
                   Owner.Email
            FROM Booking__c
            WHERE Id = :bookingId
            LIMIT 1
        ];

        result.put('booking', booking);

        General_Settings__c settings = General_Settings__c.getInstance();
        if (settings != null && settings.Unit_Readiness_Email_Template__c != null) {
            result.put('emailTemplate', settings.Unit_Readiness_Email_Template__c);
        }

        return result;
    }

    @AuraEnabled
    public static String sendUnitReadinessMail(
        Id bookingId,
        String emailBody,
        String toAddresses,
        List<String> contentDocumentIds
    ) {
        try {
            Booking__c booking = [
                SELECT Id, Name, Customer_Name__c, Customer_Email__c,
                       Plot_No__c, Project_Name__c, Unit_Type__c,
                       CRM_Head_Email__c, Owner.Email
                FROM Booking__c
                WHERE Id = :bookingId
                LIMIT 1
            ];

            List<String> recipientList = new List<String>();
            if (String.isNotBlank(toAddresses)) {
                for (String addr : toAddresses.split(',')) {
                    String trimmed = addr.trim();
                    if (String.isNotBlank(trimmed)) {
                        recipientList.add(trimmed);
                    }
                }
            }

            if (recipientList.isEmpty()) {
                return 'Error: No valid recipient email addresses provided.';
            }

            List<Messaging.EmailFileAttachment> attachments = new List<Messaging.EmailFileAttachment>();

            if (contentDocumentIds != null && !contentDocumentIds.isEmpty()) {
                List<ContentVersion> contentVersions = [
                    SELECT Id, Title, VersionData, FileExtension, ContentDocumentId
                    FROM ContentVersion
                    WHERE ContentDocumentId IN :contentDocumentIds
                    AND IsLatest = true
                ];
                for (ContentVersion cv : contentVersions) {
                    Messaging.EmailFileAttachment attachment = new Messaging.EmailFileAttachment();
                    attachment.setFileName(cv.Title + '.' + cv.FileExtension);
                    attachment.setBody(cv.VersionData);
                    attachments.add(attachment);
                }
            }

            Messaging.SingleEmailMessage email = new Messaging.SingleEmailMessage();
            email.setToAddresses(recipientList);
            email.setSubject('Unit Readiness Notification - ' + booking.Name);
            email.setHtmlBody(emailBody);
            email.setSaveAsActivity(true);

            if (String.isNotBlank(booking.CRM_Head_Email__c)) {
                email.setCcAddresses(new List<String>{ booking.CRM_Head_Email__c });
            }

            if (!attachments.isEmpty()) {
                email.setFileAttachments(attachments);
            }

            Messaging.SendEmailResult[] results = Messaging.sendEmail(
                new Messaging.SingleEmailMessage[]{ email }
            );

            if (results[0].isSuccess()) {
                booking.Unit_Readiness_Date_Time__c = System.now();
                update booking;
                return 'Success';
            } else {
                return 'Error: ' + results[0].getErrors()[0].getMessage();
            }
        } catch (Exception e) {
            return 'Error: ' + e.getMessage();
        }
    }
}
