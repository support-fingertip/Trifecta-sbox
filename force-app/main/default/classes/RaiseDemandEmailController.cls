public without sharing class RaiseDemandEmailController {
    
    @AuraEnabled
    public static Boolean checkDemandedRaised(Id bookingId) {
        // Query the latest completed Payment_Schedule__c record based on S_No__c
        Payment_Schedule__c lastCompletedPaymentSchedule = [
            SELECT Id, Is_Demanded__c
            FROM Payment_Schedule__c
            WHERE Booking__c = :bookingId AND Status__c = 'Completed'
            ORDER BY S_No__c DESC
            LIMIT 1
        ];
        
        // Check if the Is_Demanded__c flag is true for the last completed payment schedule
        if (lastCompletedPaymentSchedule != null && lastCompletedPaymentSchedule.Is_Demanded__c) {
            return false; // Return true if Is_Demanded__c is true
        } else {
            return true; // Return false if Is_Demanded__c is false or no record found
        }
    } 
    
    @AuraEnabled
    public static String sendEmailWithAttachment(Id recId, String typeOfDemand) {
        String returnmessage;
        Booking__c booking;
        if(typeOfDemand == 'Flat'){
            booking = [SELECT Id, Email__c,Email1__c,Funding_Type__c,Bank_Email__c,First_Applicant_Name__c, Demand_Raised__c,Owner.email,CRM_Manager__c,CRM_Manager__r.Email FROM Booking__c WHERE Id = :recId LIMIT 1];
        }
        else if(typeOfDemand == 'AD'){
            Additional_Charges__c adc = [Select Id,Booking__c from Additional_Charges__c where Id=:recId];
            booking = [SELECT Id, Email__c,Email1__c,Funding_Type__c,First_Applicant_Name__c, Demand_Raised__c,Owner.email,CRM_Manager__c,CRM_Manager__r.Email FROM Booking__c WHERE Id = :adc.Booking__c LIMIT 1];
        }
        system.debug(booking);
        List<String> lstCCEmail = new List<String>();
        //  List<Co_Applicant__c> coApps = [select id,name,Email__c,Email_1__c,Booking__c from Co_Applicant__c where Booking__c =: booking.Id];
        List<ContentVersion> contentVersions1 = new List<ContentVersion>();
        List<ContentDocumentLink> contentDocumentLinks = new List<ContentDocumentLink>();
        List<OrgWideEmailAddress> owea = new List<OrgWideEmailAddress>();
        owea = [SELECT Id, Address, DisplayName FROM 
                OrgWideEmailAddress WHERE Address=:booking.Owner.email];
        if (booking != null && !String.isBlank(booking.Email__c)) {
            
            PageReference pdfPage;
            pdfPage = Page.Demand_Invoice; 
            /*
if(typeOfDemand == 'Flat'){
pdfPage = Page.Demand_Invoice; 
}
else if(typeOfDemand == 'AD'){
pdfPage = Page.Demand_letterAdditional; 
}

*/
            pdfPage.getParameters().put('id', recId);
            //pdfPage.getParameters().put('includeInterest', intrest);
            DemandRaisedSave demandRaisedSave = new DemandRaisedSave();
            system.debug(typeOfDemand);
            // Demand_Raised__c dem = demandRaisedSave.RaiseDemandController(recId, typeOfDemand);
            Blob pdfBlob;
            if (Test.isRunningTest()) {
                pdfBlob = Blob.valueOf('Unit.Test');
            } else {
                pdfBlob = pdfPage.getContentAsPDF();
            }
            
            Messaging.SingleEmailMessage email = new Messaging.SingleEmailMessage();
            List<String> sendTo = new List<String>();
            sendTo.add(booking.Email__c);
            if(booking.Email1__c != null){
                sendTo.add(booking.Email1__c);
            }
            
            if(booking.Funding_Type__c == 'Loan' && typeOfDemand == 'Flat'){
                sendTo.add(booking.Bank_Email__c);
            }
            if (owea.size()>0) {
                email.setOrgWideEmailAddressId(owea[0].Id);
            }
            if(booking.Owner.Email != null){
                lstCCEmail.add(booking.Owner.Email);
            }
            
            if(booking.CRM_Manager__c != null){
                lstCCEmail.add(booking.CRM_Manager__r.Email);
            }
            if(lstCCEmail.size()>0){
                email.setCcAddresses(lstCCEmail);
            }
            email.setToAddresses(lstCCEmail);
            email.setSubject('Demand Letter');
            email.setHtmlBody('Dear '+booking.First_Applicant_Name__c+',<br/>Please find the attached Demand Letter.<br/><br/>' +
                              'We are pleased to inform you that your booking has been confirmed. ' +
                              'Attached is the Demand Letter for your reference.<br/><br/>' +
                              'If you have any questions or need further assistance, please do not hesitate to contact us.<br/><br/>' +
                              'Thank you for choosing EIPL.<br/><br/>' +
                              'Best regards,<br/>' +
                              'EIPL Pvt Ltd');
            
            Messaging.EmailFileAttachment attachment = new Messaging.EmailFileAttachment();
            //saveAttachmentToFiles(recId, 'Demand.pdf', pdfBlob, contentVersions1, contentDocumentLinks);
            attachment.setFileName('DemandLetter.pdf'); 
            attachment.setBody(pdfBlob);
            email.setFileAttachments(new Messaging.EmailFileAttachment[] { attachment });
            
            Messaging.sendEmail(new Messaging.SingleEmailMessage[] { email });
            /*  if (!contentVersions1.isEmpty()) {
insert contentVersions1;

Set<Id> contentDocumentIdSet = new Set<Id>();

for(ContentVersion cv:[SELECT Id,ContentDocumentId,FirstPublishLocationId FROM ContentVersion WHERE Id IN : contentVersions1])
{
if(cv.ContentDocumentId != null)
{
contentDocumentIdSet.add(cv.ContentDocumentId);
}
}

List<ContentDocumentLink> lstContentDocumentlink = [SELECT ContentDocumentId, LINKEDENTITYID 
FROM ContentDocumentLink WHERE ContentDocumentId IN:contentDocumentIdSet];
set<Id> conIds = new set<Id>();

for(ContentDocumentLink cn : lstContentDocumentlink){
conIds.add(cn.ContentDocumentId);
}
for (ContentVersion cv : [SELECT Id,ContentDocumentId,FirstPublishLocationId FROM ContentVersion WHERE Id IN : contentVersions1]) {
if(cv.ContentDocumentId != null && !conIds.contains(cv.ContentDocumentId))
{
ContentDocumentLink cdl = new ContentDocumentLink();
cdl.ContentDocumentId = cv.ContentDocumentId;
cdl.LinkedEntityId = cv.FirstPublishLocationId;
system.debug('forloop book ir   '+cv.FirstPublishLocationId);
cdl.ShareType = 'V';
cdl.Visibility = 'AllUsers';
contentDocumentLinks.add(cdl);
}
}
if (!contentDocumentLinks.isEmpty()) {
insert contentDocumentLinks;
}

}*/
            if(typeOfDemand == 'Flat'){
                booking.Demand_Raised__c = true;
                update booking;
            }
            //  insert dem;
            
            // returnmessage = 'Demand Letter Sent Successfully.';
            returnmessage = 'Demand raise email sent Successfully';
        } else {
            returnmessage = 'Email address not specified in the Booking record.';
        }
        
        return returnmessage;
    }
    
    @AuraEnabled
    public static void updatePaymentSchedules(String recordId){
        Id recId = (Id) recordId;
        List<payment_schedule__c> payList = new List<payment_schedule__c>();
        Booking__c book = [select id,name from Booking__c where Id=: recId];
        // if(book.Property_Type_For__c == 'Apartments'){
        payList = [
            SELECT Id, S_No__c, Name,Pending_Amount__c,Payment_Due_Date__c,Received_Amount1__c,Is_Demanded__c, Payment_percent__c, AmountB__c,
            Master_Payment_Schedule__r.Completed_date__c, Booking__c
            FROM Payment_Schedule__c
            WHERE Master_Payment_Schedule__r.Status__c = 'Completed' and Pending_Amount__c != 0
            AND Booking__c = :recId
        ];
        //}
        /*else if(book.Property_Type_For__c == 'Villas'){
payList = [
SELECT Id, S_No__c, Name,Pending_Amount__c,Payment_Due_Date__c,Received_Amount1__c,Is_Demanded__c, Payment_percent__c, AmountB__c,
Master_Payment_Schedule__r.Completed_date__c, Booking__c
FROM Payment_Schedule__c
WHERE Status__c = 'Completed' and Pending_Amount__c != 0
AND Booking__c = :recId ];
}*/
        
        system.debug('payList   '+payList);
        system.debug('payIds   '+recId);
        List<payment_schedule__c> toUpdate = new List<payment_schedule__c>();
        for(payment_schedule__c p : payList){
            p.Is_Demanded__c = true;
            if(p.Payment_Due_Date__c == null){
                p.Payment_Due_Date__c = System.today() + 15;
            }
            toUpdate.add(p);
        }
        if(toUpdate.size()>0){
            update toUpdate;
            system.debug('after updated   '+toUpdate);
        }
    }
    
    @AuraEnabled
    public Static String RaiseDemand(List<Id> bookingIds, Map<Id,String> emailContents, map<Id,List<String>> contentIds ) {
        return DemandRaisedSave.RaiseDemand(bookingIds,emailContents,contentIds);
    }
}