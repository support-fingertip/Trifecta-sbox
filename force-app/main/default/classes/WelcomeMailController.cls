public without sharing class WelcomeMailController {
    @AuraEnabled(cacheable=true)
    public static Booking__c getRecordData(Id recordId) {
        return [SELECT Id,Name,Franking_Amount__c,First_Applicant_Name__c,Swap_Unit_Status__c,Application_Amount__c,Unit_No__c,Owner_Phone__c, Project__c,Plot__r.Name,Booking_Amount__c, Project1__r.Company_Name__c,S__c,/*Owner_Designation__c, Booking_Amount1__c,Owner_NameFor__c,*/ Owner_Full_Name__c,Email__c FROM Booking__c WHERE Id = :recordId LIMIT 1];
    } 
    
    @AuraEnabled
public static void sendWelcomeEmail(Id recordId, String emailContent, List<String> toAddresses, List<String> contentIds) {
    system.debug('Content IDs: ' + contentIds);
    Booking__c leadRecord = [SELECT Id, Quote__c,Name, CRM_Manager__c,Project1__r.Name, Owner_Phone__c,CRM_Head__c, CRM_Head__r.Email, CRM_Manager__r.Email, First_Applicant_Name__c, Project__c, Email__c, 
                             (SELECT ContentDocumentId, ContentDocument.Title FROM ContentDocumentLinks WHERE ContentDocumentId IN :contentIds) 
                             FROM Booking__c 
                             WHERE Id = :recordId 
                             LIMIT 1];
    Payment_Schedule__c ps = [select id from Payment_Schedule__c where Booking__c =: leadRecord.Id AND S_No__c = 1];
    List<String> lstCCEmail = new List<String>();
    
    if (leadRecord != null && leadRecord.Email__c != null) {
        Messaging.SingleEmailMessage mail = new Messaging.SingleEmailMessage();
        
        // Set Organization-Wide Email Address
        OrgWideEmailAddress[] owea = [SELECT Id, Address FROM OrgWideEmailAddress WHERE Address = 'mrgarunkumar8892@gmail.com'];
        if (owea.size() > 0) {
            mail.setOrgWideEmailAddressId(owea[0].Id);
        }
        
        List<Messaging.EmailFileAttachment> emailAttachments = new List<Messaging.EmailFileAttachment>();
        Set<Id> contentDocumentIds = new Set<Id>();
        
        for (ContentDocumentLink docLink : leadRecord.ContentDocumentLinks) {
            contentDocumentIds.add(docLink.ContentDocumentId);
        }
        
        if (!contentDocumentIds.isEmpty()) {
            List<ContentVersion> contentVersions = [SELECT Title,FileExtension, VersionData FROM ContentVersion WHERE ContentDocumentId IN :contentDocumentIds];
            for (ContentVersion cv : contentVersions) {
                Messaging.EmailFileAttachment contentAttach = new Messaging.EmailFileAttachment();
                String fileNameWithExtension = cv.Title + '.' + cv.FileExtension;
                contentAttach.setFileName(fileNameWithExtension);
                contentAttach.setBody(cv.VersionData);
                emailAttachments.add(contentAttach);
            }
        }
        
        if(leadRecord.CRM_Head__c!= null){
            lstCCEmail.add(leadRecord.CRM_Head__r.Email);
        }
        
        String mess= DemandRaisedSave.raiseCustomDemand(ps.Id);
        System.debug(mess);
        
        Messaging.EmailFileAttachment vfAttachment = generateVFPageAttachment('BookingFormZGC', recordId);
        Messaging.EmailFileAttachment vfAttachment1 = generateVFPageAttachment('CostSheet', leadRecord.Quote__c);
        Messaging.EmailFileAttachment vfAttachment3 = generateVFPageAttachment('ConsolidatedReceipt', recordId);
        Messaging.EmailFileAttachment vfAttachment4 = generateVFPageAttachment('SaleAgreement', recordId);
        Messaging.EmailFileAttachment vfAttachment2 = generateVFPageAttachment('Demand_Invioce_Custom', recordId,ps.Id);
        
        if (vfAttachment != null) {
            emailAttachments.add(vfAttachment);
        }
        if (vfAttachment1 != null) {
            emailAttachments.add(vfAttachment1);
        }
        if (vfAttachment2 != null) {
            emailAttachments.add(vfAttachment2);
        }
        if (vfAttachment3 != null) {
            emailAttachments.add(vfAttachment3);
        }
        if (vfAttachment4 != null) {
            emailAttachments.add(vfAttachment4);
        }
        
        system.debug(toAddresses);
        mail.setToAddresses(toAddresses);
        if(lstCCEmail.size()>0){
            mail.setCcAddresses(lstCCEmail);
        }
        mail.setSubject('Welcome to Zuari');
        mail.setHtmlBody(emailContent);
        if (!emailAttachments.isEmpty()) {
            mail.setFileAttachments(emailAttachments);
        }
        
        List<Messaging.SendEmailResult> results = Messaging.sendEmail(new Messaging.SingleEmailMessage[] { mail });
        system.debug(results);           
        
        leadRecord.Welcome_Mail_Sent_Time__c = system.now();
        leadRecord.Welcome_Email_Sent_to_Customer__c = true;
        leadRecord.Sale_Agreement_Sent__c = true;
        leadRecord.Booking_Form_Sent__c = true;
        update leadRecord;
    }
}
    private static Messaging.EmailFileAttachment generateVFPageAttachment(String vfPageName, Id recordId, Id psId) {
        system.debug(vfPageName+'--'+recordId +'--'+psId );
        PageReference vfPage = new PageReference('/apex/' + vfPageName);
        System.debug(vfPage);
        if(psId!=null){
            
        vfPage.getParameters().put('id', recordId);
        vfPage.getParameters().put('PId', psId);
        }
        else{
            
        vfPage.getParameters().put('id', recordId);
        }
        vfPage.setRedirect(true);
        
        // Get the PDF content
        Blob pdfBlob;
        if (Test.isRunningTest()) {
            // For test classes, we can't actually generate PDFs
            pdfBlob = Blob.valueOf('Test PDF Content');
        } else {
            pdfBlob = vfPage.getContentAsPDF();
        }
        System.debug(pdfBlob);
        Messaging.EmailFileAttachment attachment = new Messaging.EmailFileAttachment();
        
        if(vfPageName=='Demand_Invioce_Custom'){
            
        attachment.setFileName('Demand Invioce' + '.pdf');
        }
        
        attachment.setBody(pdfBlob);
        attachment.setContentType('application/pdf');
        
        return attachment;
    }
   private static Messaging.EmailFileAttachment generateVFPageAttachment(String vfPageName, Id recordId) {
        PageReference vfPage = new PageReference('/apex/' + vfPageName);
        System.debug(vfPageName);
            
        vfPage.getParameters().put('id', recordId);
        
        vfPage.setRedirect(true);
        
        // Get the PDF content
        Blob pdfBlob;
        if (Test.isRunningTest()) {
            // For test classes, we can't actually generate PDFs
            pdfBlob = Blob.valueOf('Test PDF Content');
        } else {
            pdfBlob = vfPage.getContentAsPDF();
        }
        System.debug(pdfBlob);
        Messaging.EmailFileAttachment attachment = new Messaging.EmailFileAttachment();
       if(vfPageName=='BookingFormZGC'){
         
        attachment.setFileName('BookingForm' + '.pdf');   
        }
        else{
            
        attachment.setFileName(vfPageName + '.pdf');
        }
        attachment.setBody(pdfBlob);
        attachment.setContentType('application/pdf');
        
        return attachment;
    }
  
     @AuraEnabled
    public static void sendUnitRedinessMail(Id recordId, String emailContent, List<String> toAddresses, List<String> contentIds) {
        system.debug('Content IDs: ' + contentIds);
        Booking__c leadRecord = [SELECT Id, Quote__c,Name, CRM_Manager__c,Project1__r.Name, Owner_Phone__c,Unit_Readiness_Date_Time__c,CRM_Head__c, CRM_Head__r.Email,/*Owner_Designation__c,Owner_NameFor__c,Booking_Amount1__c*/ CRM_Manager__r.Email, First_Applicant_Name__c, Project__c, Email__c, 
                                 (SELECT ContentDocumentId, ContentDocument.Title FROM ContentDocumentLinks WHERE ContentDocumentId IN :contentIds) 
                                 FROM Booking__c 
                                 WHERE Id = :recordId 
                                 LIMIT 1];
        List<String> lstCCEmail = new List<String>();
        if (leadRecord != null && leadRecord.Email__c != null) {
            Messaging.SingleEmailMessage mail = new Messaging.SingleEmailMessage();
            List<Messaging.EmailFileAttachment> emailAttachments = new List<Messaging.EmailFileAttachment>();
            Set<Id> contentDocumentIds = new Set<Id>();
            for (ContentDocumentLink docLink : leadRecord.ContentDocumentLinks) {
                contentDocumentIds.add(docLink.ContentDocumentId);
            }
            if (!contentDocumentIds.isEmpty()) {
                List<ContentVersion> contentVersions = [SELECT Title,FileExtension, VersionData FROM ContentVersion WHERE ContentDocumentId IN :contentDocumentIds];
                for (ContentVersion cv : contentVersions) {
                    Messaging.EmailFileAttachment contentAttach = new Messaging.EmailFileAttachment();
                    String fileNameWithExtension = cv.Title + '.' + cv.FileExtension;
                    contentAttach.setFileName(fileNameWithExtension);
                    //contentAttach.setFileName(cv.Title);
                    contentAttach.setBody(cv.VersionData);
                    emailAttachments.add(contentAttach);
                }
            }
            if(leadRecord.CRM_Head__c!= null){
                   lstCCEmail.add(leadRecord.CRM_Head__r.Email);
            }
            
          Messaging.EmailFileAttachment vfAttachment = generateVFPageAttachment('Invitation_For_Inspection', leadRecord.Id,null);
            if (vfAttachment != null) {
                emailAttachments.add(vfAttachment);
            }
            List<PageReference> vfPages = new List<PageReference>();
            system.debug(toAddresses);
            mail.setToAddresses(toAddresses);
            if(lstCCEmail.size()>0){
                mail.setCcAddresses(lstCCEmail);
            }
            mail.setSubject('Unit Readiness Mail - Zuari');
            mail.setHtmlBody(emailContent);
            if (!emailAttachments.isEmpty()) {
                mail.setFileAttachments(emailAttachments);
            }
            List<Messaging.SendEmailResult> results = Messaging.sendEmail(new Messaging.SingleEmailMessage[] { mail });
            system.debug(results);           
            leadRecord.Unit_Readiness_Date_Time__c = system.now();
           // leadRecord.Welcome_Email_Sent_to_Customer__c = true;
            update leadRecord;
        }
    }
}