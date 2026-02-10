/****************************************************************
* Class Name   : WelcomeEmailController
* Company      : Fingertipplus
* Created Date : 03-02-2026
* @description : This Apex class is used to generate Welcome Email
*                content from General Settings template, perform
*                merge with Booking data and send email to customer.
* @author      : Durga Prasad
*
* Change Log:
* -----------------------------------------------------------------------------
* Ver | Author         | Date        | Description
* -----------------------------------------------------------------------------
* 1.0 | Durga Prasad  | 03-02-2026  | Initial version
* -----------------------------------------------------------------------------
*****************************************************************/
public without sharing class WelcomeMailController {
    
    public class DataBox {
        @auraEnabled public Booking__c bookingRecord;
        @auraEnabled public String emailTemplate;
    }
    /**
     * Method Name  : getRecordData
     * Description  : Fetches Booking data and prepares merged Welcome Email template.
     *
     * Functionality:
     * 1. Retrieves Booking__c record based on provided recordId.
     * 2. Fetches project-specific email template from General_Settings__c 
     *    where Type__c = 'Welcome Email Template'.
     * 3. Performs merge operation by replacing placeholders with Booking values:
     *      ##APPLICANT_NAME##
     *      ##PROJECT_NAME##
     *      ##BLOCK_NAME##
     *      ##UNIT_NUMBER##
     *      ##SALEABLE_AREA##
     *      ##CARPET_AREA##
     *      ##AGREEMENT_DATE##
     *      ##CRM_NAME##
     *      ##CRM_PHONE##
     *      ##CRM_EMAIL##
     *      ##SIGNATURE##
     * 4. Prepares final HTML content and wraps it inside DataBox object.
     *
     * Parameters:
     * @param recordId - Id of Booking__c record
     *
     * Returns:
     * @return DataBox - Wrapper containing:
     *         - bookingRecord : Booking__c record
     *         - emailTemplate : Merged HTML email body
     *
     * Used From:
     * - LWC component for previewing Welcome Email
     * - Email send screen before confirmation
    */
    @AuraEnabled
    public static DataBox getRecordData(Id recordId) {
        DataBox db = new DataBox();
        // 1. Get Booking Data
        Booking__c bk =  [SELECT Id,Name,Franking_Amount__c,First_Applicant_Name__c,Swap_Unit_Status__c,Owner_Phone_Number__c,
                          Application_Amount__c,Unit_No__c,Owner_Phone__c, Project__c,Plot__r.Name,Booking_Amount__c,Owner_Email__c,
                          Project1__r.Company_Name__c,S__c,Super_Built_UpArea__c,Carpet_Area__c,Agreement_Expected_Date__c,
                          Block_Name__c,Owner_Full_Name__c,Email__c FROM Booking__c WHERE Id = :recordId LIMIT 1];
        db.bookingRecord = bk;
        
        // 2. Get Template Record (project wise)
        General_Settings__c temp = [
            SELECT Template_Body__c,Type__c FROM General_Settings__c WHERE Project_Name__c = :bk.Project__c AND
            Type__c ='Welcome Email Template' LIMIT 1
        ];
        
        
        String template = temp.Template_Body__c;
        
        // ================= MERGE LOGIC =================
        
        // Applicant
        template = template.replace(
            '##APPLICANT_NAME##',
            bk.First_Applicant_Name__c != null ? bk.First_Applicant_Name__c : ''
        );
        
        // Project
        template = template.replace(
            '##PROJECT_NAME##',
            bk.Project__c != null ? bk.Project__c : ''
        );
        
        // -------- UNIT DETAILS (YOU CAN CHANGE THIS LINE ANYTIME) --------
        // BLOCK_NAME
        template = template.replace(
            '##BLOCK_NAME##',
            bk.Block_Name__c != null ? String.valueOf(bk.Block_Name__c) : ''
        );
        
        // BLOCK_NAME
        template = template.replace(
            '##UNIT_NUMBER##',
            bk.Unit_No__c != null ? String.valueOf(bk.Unit_No__c) : ''
        );
        
        
        // Areas
        template = template.replace(
            '##SALEABLE_AREA##',
            bk.Super_Built_UpArea__c != null ? String.valueOf(bk.Super_Built_UpArea__c) : ''
        );
        
        template = template.replace(
            '##CARPET_AREA##',
            bk.Carpet_Area__c != null ? String.valueOf(bk.Carpet_Area__c) : ''
        );
        
        // Agreement Date
        template = template.replace(
            '##AGREEMENT_DATE##',
            bk.Agreement_Expected_Date__c != null ? String.valueOf(bk.Agreement_Expected_Date__c) : ''
        );
        
        // CRM
        template = template.replace(
            '##CRM_NAME##',
             bk.Owner_Full_Name__c != null ? String.valueOf(bk.Owner_Full_Name__c) : ''
        );
        
        template = template.replace(
            '##CRM_PHONE##',
             bk.Owner_Phone_Number__c != null ? String.valueOf(bk.Owner_Phone_Number__c) : ''
        );
        
        template = template.replace(
            '##CRM_EMAIL##',
            bk.Owner_Email__c != null ? String.valueOf(bk.Owner_Email__c) : ''
        );
        
        // Signature – controlled from system
        String sign =
            '<p>Warm Regards,<br/>' +
            '<strong>' + (bk.Owner_Full_Name__c != null ? bk.Owner_Full_Name__c : '') + '</strong><br/>' +
            (bk.Owner_Phone__c != null ? bk.Owner_Phone__c : '') +
            '</p>';
        
        template = template.replace('##SIGNATURE##', sign);
        db.emailTemplate = template;
        return db;
    }
    
    /**
    * Method Name  : sendWelcomeEmail
    * Description  : Generates and sends Welcome Email for a Booking record.
    *
    * Functionality:
    * 1. Fetches Booking__c record based on recordId.
    * 2. Fetches project-specific email template from General_Settings__c 
    *    where Type__c = 'Welcome Email Template'.
    * 3. Performs merge logic by replacing placeholders like:
    *      ##APPLICANT_NAME##
    *      ##PROJECT_NAME##
    *      ##BLOCK_NAME##
    *      ##UNIT_NUMBER##
    *      ##SALEABLE_AREA##
    *      ##CARPET_AREA##
    *      ##AGREEMENT_DATE##
    *      ##SIGNATURE##
    * 4. Prepares final HTML email body.
    * 5. Sends email to provided recipients with inline attachments if any.
    *
    * Parameters:
    * @param recordId     - Id of Booking__c record
    * @param toAddresses  - List of recipient email addresses
    * @param contentIds   - List of ContentDocumentIds for attachments (optional)
    *
    * Used From:
    * - LWC Welcome Email component
    * - Manual email send action from Booking record
    *
    * Template Source:
    * - General_Settings__c.Template_Body__c
    * - Filter: Project_Name__c = Booking.Project__c
    *           AND Type__c = 'Welcome Email Template'
    **/
    @AuraEnabled
    public static void sendWelcomeEmail(Id recordId, String emailContent, List<String> toAddresses, List<String> contentIds) {
        system.debug('Content IDs: ' + contentIds);
        Booking__c bk = [SELECT Id, Quote__c,Name, CRM_Manager__c,Project1__r.Name, Owner_Phone__c,CRM_Head__c, 
                         CRM_Head__r.Email, CRM_Manager__r.Email, First_Applicant_Name__c, Email__c, 
                         Project__c,Block_Name__c,Unit_No__c,Project_Type__c,
                         (SELECT ContentDocumentId, ContentDocument.Title FROM ContentDocumentLinks 
                          WHERE ContentDocumentId IN :contentIds) 
                         FROM Booking__c 
                         WHERE Id = :recordId 
                         LIMIT 1];
        Payment_Schedule__c ps = [select id from Payment_Schedule__c where Booking__c =: bk.Id AND S_No__c = 1];
        List<String> lstCCEmail = new List<String>();
        
        if (bk != null && bk.Email__c != null) {
            Messaging.SingleEmailMessage mail = new Messaging.SingleEmailMessage();
            
            string displayName = label.Default_Email_Address_Label;
            //sender using Org-Wide Email Addres
            OrgWideEmailAddress owea = [
                SELECT Id 
                FROM OrgWideEmailAddress 
                WHERE DisplayName =:displayName 
                LIMIT 1
            ];
            mail.setOrgWideEmailAddressId(owea.Id);

            
            List<Messaging.EmailFileAttachment> emailAttachments = new List<Messaging.EmailFileAttachment>();
            Set<Id> contentDocumentIds = new Set<Id>();
            
            for (ContentDocumentLink docLink : bk.ContentDocumentLinks) {
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
            
            if(bk.CRM_Head__c!= null){
                lstCCEmail.add(bk.CRM_Head__r.Email);
            }
            
            //=====================
            //Rasing the Fist Demand
            //====================
            String mess= DemandRaisedSave.raiseCustomDemand(ps.Id);
            System.debug(mess);
            String projectType = bk.Project_Type__c;
            
            String quotePdf ='TrifectaCostsheet';
            
            String consolidatedReceipt ='ConsolidatedReceipt';
            String demandInvioceCustom ='DemandNote';
            
            // Declare once at top
            Messaging.EmailFileAttachment vfAttachment;
            
            // ===== Booking Form based on Project Type =====
            if (projectType == 'Apartments') 
            {
                vfAttachment = generateVFPageAttachment('Trifecta_Booking_Form', recordId);
                quotePdf = 'TrifectaCostsheet';
            } 
            else if (projectType == 'Row House') 
            {
                vfAttachment = generateVFPageAttachment('TrifectaRowHouseBookingForm', recordId);
                quotePdf = 'TrifectaRowHouseCostSheet';
            } 
            else if (projectType == 'Villas') 
            {
                // For villas – you had two pages, so we attach first as main
                vfAttachment = generateVFPageAttachment('LandVillaBookingForm', recordId);
                
                // Add second villa form directly to list
                Messaging.EmailFileAttachment villaConst =
                    generateVFPageAttachment('ConstructionVillaBookingForm', recordId);
                
                if (villaConst != null) {
                    emailAttachments.add(villaConst);
                }
                
                quotePdf = 'trifectaVillaCostSheet';
            }
            
            // ===== Common Attachments =====
            Messaging.EmailFileAttachment vfAttachment1 = generateVFPageAttachment(quotePdf, bk.Quote__c);
            
            Messaging.EmailFileAttachment vfAttachment2 = generateVFPageAttachment(demandInvioceCustom, recordId, ps.Id);
            
            Messaging.EmailFileAttachment vfAttachment3 = generateVFPageAttachment(consolidatedReceipt, recordId);
        
            
            // ===== Add only if not null =====
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
            
            system.debug(toAddresses);
            
            
            // 2. Get Template Record (project wise)
            General_Settings__c temp = [
                SELECT Subject__c,Type__c FROM General_Settings__c WHERE Project_Name__c = :bk.Project__c AND
                Type__c ='Welcome Email Template' LIMIT 1
            ];
            String subject = temp.Subject__c;
            // Project
            subject = subject.replace(
                '##PROJECT_NAME##',
                bk.Project__c != null ? bk.Project__c : ''
            );
            
            // -------- UNIT DETAILS (YOU CAN CHANGE THIS LINE ANYTIME) --------
            // BLOCK_NAME
            subject = subject.replace(
                '##BLOCK_NAME##',
                bk.Block_Name__c != null ? String.valueOf(bk.Block_Name__c) : ''
            );
            
            // BLOCK_NAME
            subject = subject.replace(
                '##UNIT_NUMBER##',
                bk.Unit_No__c != null ? String.valueOf(bk.Unit_No__c) : ''
            );
            
            
            
            mail.setToAddresses(toAddresses);
            if(lstCCEmail.size()>0){
                mail.setCcAddresses(lstCCEmail);
            }
            mail.setSubject(subject);
            mail.setHtmlBody(emailContent);
            if (!emailAttachments.isEmpty()) {
                mail.setFileAttachments(emailAttachments);
            }
            
            List<Messaging.SendEmailResult> results = Messaging.sendEmail(new Messaging.SingleEmailMessage[] { mail });
            system.debug(results);           
            
            bk.Welcome_Mail_Sent_Time__c = system.now();
            bk.Welcome_Email_Sent_to_Customer__c = true;
            bk.Sale_Agreement_Sent__c = true;
            bk.Booking_Form_Sent__c = true;
            update bk;
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
        } 
        else {
            pdfBlob = vfPage.getContentAsPDF();
        }
        System.debug(pdfBlob);
        Messaging.EmailFileAttachment attachment = new Messaging.EmailFileAttachment();
        attachment.setFileName(vfPageName + '.pdf');
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
        attachment.setFileName(vfPageName + '.pdf');
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