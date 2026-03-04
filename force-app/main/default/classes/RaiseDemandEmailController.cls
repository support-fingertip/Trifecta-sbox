public without sharing class RaiseDemandEmailController {
    
    
    public class dataBox {
        @AuraEnabled public string emailContent;
        @AuraEnabled public string subject;
        @AuraEnabled public boolean isDemandRaised;
        @AuraEnabled public boolean lastPymtSchedule;
    }
    @AuraEnabled
    public static dataBox getData(Id bookingId) {
        dataBox dt = new dataBox();
        boolean lastPymtSchedule =false;
        // Query the latest completed Payment_Schedule__c record based on S_No__c
        Payment_Schedule__c lastCompletedPaymentSchedule = [
            SELECT Id, Is_Demanded__c,Type__c,S_No__c
            FROM Payment_Schedule__c
            WHERE Booking__c = :bookingId AND Status__c = 'Completed'
            ORDER BY S_No__c DESC
            LIMIT 1
        ];
        Payment_Schedule__c LastPaymentschedule = [
            SELECT Id, Is_Demanded__c,Type__c,S_No__c
            FROM Payment_Schedule__c
            WHERE Booking__c = :bookingId
            ORDER BY S_No__c DESC
            LIMIT 1
        ];
        Booking__c bk =  [SELECT Id,Name,Franking_Amount__c,First_Applicant_Name__c,Swap_Unit_Status__c,Owner_Phone_Number__c,
                          Application_Amount__c,Unit_No__c,Owner_Phone__c, Project__c,Plot__r.Name,Booking_Amount__c,Owner_Email__c,
                          Project1__r.Company_Name__c,S__c,Super_Built_UpArea__c,Carpet_Area__c,Agreement_Expected_Date__c,Company_Name__c,
                          Block_Name__c,Owner_Full_Name__c,Email__c,Project_Type__c,Block_Id__c FROM Booking__c WHERE Id = :bookingId LIMIT 1];
        
        Block__c block = bk.Block_Id__c != null ? [SELECT Id, Name, Email__c, Project_Address__c,Company_Name__c,
                                                   Construction_Company_Name__c,Land_Company_Name__c,
                                                   Branch__c, Type_of_Account__c, IFSC_Code__c, Account_Number__c, 
                                                   Bank_Name__c FROM Block__c WHERE Id = :bk.Block_Id__c LIMIT 1] : null;
        
        if(lastCompletedPaymentSchedule.S_No__c == LastPaymentschedule.S_No__c){
            lastPymtSchedule =true;
        }
        boolean isDemandRaised = false;
        // Check if the Is_Demanded__c flag is true for the last completed payment schedule
        if (lastCompletedPaymentSchedule != null && lastCompletedPaymentSchedule.Is_Demanded__c) {
            isDemandRaised =  false; // Return true if Is_Demanded__c is true
        } else {
            isDemandRaised =  true; // Return false if Is_Demanded__c is false or no record found
        }
        dt.isDemandRaised = isDemandRaised;
        dt.lastPymtSchedule = lastPymtSchedule;
        
        
        String companyName = 'TRIFECTA PROJECTS PVT LTD';
        if(bk.Project_Type__c == 'Villas')
        {
            if(lastCompletedPaymentSchedule.Type__c =='Land')
            {
                companyName =(block.Land_Company_Name__c != null) ? block.Land_Company_Name__c : '';
            }
            else if(lastCompletedPaymentSchedule.Type__c =='Construction')
            {
                companyName =(block.Construction_Company_Name__c != null) ? block.Construction_Company_Name__c: '';
            }
        }
        else
        {
            companyName =(block.Company_Name__c != null ) ? block.Company_Name__c : '';
        }
        
        
        
        
        // 2. Get Template Record (project wise)
        General_Settings__c temp = [
            SELECT Template_Body__c,Type__c FROM General_Settings__c WHERE
            Project_Name1__c INCLUDES (:bk.Project__c) AND
            Type__c ='Demand Note' LIMIT 1
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
        
        template = template.replace(
            '##CRM_PHONE##',
            bk.Owner_Phone_Number__c != null ? String.valueOf(bk.Owner_Phone_Number__c) : ''
        );
        
        template = template.replace(
            '##CRM_EMAIL##',
            bk.Owner_Email__c != null ? String.valueOf(bk.Owner_Email__c) : ''
        );
        template = template.replace(
            '##COMAPANY_NAME##', companyName != null ? String.valueOf(companyName) : ''
        );
        
        dt.emailContent = template;
        
        return dt;
        
        
    } 
    
    @AuraEnabled
    public static dataBox getRevisedDemandData(Id bookingId) {
        dataBox dt = new dataBox();
        boolean lastPymtSchedule =false;
        // Query the latest completed Payment_Schedule__c record based on S_No__c
        Payment_Schedule__c lastCompletedPaymentSchedule = [
            SELECT Id, Is_Demanded__c,Type__c,S_No__c
            FROM Payment_Schedule__c
            WHERE Booking__c = :bookingId AND Status__c = 'Completed'
            ORDER BY S_No__c DESC
            LIMIT 1
        ];
        Payment_Schedule__c LastPaymentschedule = [
            SELECT Id, Is_Demanded__c,Type__c,S_No__c
            FROM Payment_Schedule__c
            WHERE Booking__c = :bookingId
            ORDER BY S_No__c DESC
            LIMIT 1
        ];
        Booking__c bk =  [SELECT Id,Name,Franking_Amount__c,First_Applicant_Name__c,Swap_Unit_Status__c,Owner_Phone_Number__c,
                          Application_Amount__c,Unit_No__c,Owner_Phone__c, Project__c,Plot__r.Name,Booking_Amount__c,Owner_Email__c,
                          Project1__r.Company_Name__c,S__c,Super_Built_UpArea__c,Carpet_Area__c,Agreement_Expected_Date__c,Company_Name__c,
                          Block_Name__c,Owner_Full_Name__c,Email__c,Project_Type__c,Block_Id__c FROM Booking__c WHERE Id = :bookingId LIMIT 1];
        
        Block__c block = bk.Block_Id__c != null ? [SELECT Id, Name, Email__c, Project_Address__c,Company_Name__c,
                                                   Construction_Company_Name__c,Land_Company_Name__c,
                                                   Branch__c, Type_of_Account__c, IFSC_Code__c, Account_Number__c, 
                                                   Bank_Name__c FROM Block__c WHERE Id = :bk.Block_Id__c LIMIT 1] : null;
        
        if(lastCompletedPaymentSchedule.S_No__c == LastPaymentschedule.S_No__c){
            lastPymtSchedule =true;
        }
        boolean isDemandRaised = false;
        // Check if the Is_Demanded__c flag is true for the last completed payment schedule
        if (lastCompletedPaymentSchedule != null && lastCompletedPaymentSchedule.Is_Demanded__c) {
            isDemandRaised =  false; // Return true if Is_Demanded__c is true
        } else {
            isDemandRaised =  true; // Return false if Is_Demanded__c is false or no record found
        }
        dt.isDemandRaised = isDemandRaised;
        dt.lastPymtSchedule = lastPymtSchedule;
        
        
        String companyName = 'TRIFECTA PROJECTS PVT LTD';
        if(bk.Project_Type__c == 'Villas')
        {
            if(lastCompletedPaymentSchedule.Type__c =='Land')
            {
                companyName =(block.Land_Company_Name__c != null) ? block.Land_Company_Name__c : '';
            }
            else if(lastCompletedPaymentSchedule.Type__c =='Construction')
            {
                companyName =(block.Construction_Company_Name__c != null) ? block.Construction_Company_Name__c: '';
            }
        }
        else
        {
            companyName =(block.Company_Name__c != null ) ? block.Company_Name__c : '';
        }
        
        
        
        
        // 2. Get Template Record (project wise)
        General_Settings__c temp = [
            SELECT Template_Body__c,Type__c,Subject__c FROM General_Settings__c WHERE
            Project_Name1__c INCLUDES (:bk.Project__c) AND
            Type__c ='Revised Demand Note' LIMIT 1
        ];
        
        
        String template = temp.Template_Body__c;
        String subject = temp.Subject__c;
        
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
        
        template = template.replace(
            '##CRM_PHONE##',
            bk.Owner_Phone_Number__c != null ? String.valueOf(bk.Owner_Phone_Number__c) : ''
        );
        
        template = template.replace(
            '##CRM_EMAIL##',
            bk.Owner_Email__c != null ? String.valueOf(bk.Owner_Email__c) : ''
        );
        template = template.replace(
            '##COMAPANY_NAME##', companyName != null ? String.valueOf(companyName) : ''
        );
        dt.emailContent = template;

        // Project
        subject = subject.replace(
            '##PROJECT_NAME##',
            bk.Project__c != null ? bk.Project__c : ''
        );
        
        // -------- UNIT DETAILS--------
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

        dt.subject = subject;
        return dt;
        
        
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
            attachment.setFileName('DemandLetter.pdf'); 
            attachment.setBody(pdfBlob);
            email.setFileAttachments(new Messaging.EmailFileAttachment[] { attachment });
            
            Messaging.sendEmail(new Messaging.SingleEmailMessage[] { email });
            if(typeOfDemand == 'Flat'){
                booking.Demand_Raised__c = true;
                update booking;
            }
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
        payList = [
            SELECT Id, S_No__c, Name,Pending_Amount__c,Payment_Due_Date__c,Received_Amount1__c,Is_Demanded__c, Payment_percent__c, AmountB__c,
            Master_Payment_Schedule__r.Completed_date__c, Booking__c
            FROM Payment_Schedule__c
            WHERE Master_Payment_Schedule__r.Status__c = 'Completed' and Pending_Amount__c != 0
            AND Booking__c = :recId
        ];
        
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
    public Static String RaiseDemand(String bookingId, String emailContent,List<Id> contentIds) {
        return DemandRaisedSave.raiseNewCustomDemand(bookingId,emailContent,contentIds);
    }
    @AuraEnabled
    public static String revisedDemand(String bookingId, String emailContent, List<Id> contentIds,string subject) {
        try {
            // 1. Get the latest completed Payment Schedule
            Payment_Schedule__c psRecord = [
                SELECT Id, Name, S_No__c, Completed_Date__c, Payment_percent__c,
                Booking__c, Master_Payment_Schedule__r.S_No__c, Master_Payment_Schedule__c,
                CreatedBy.Email
                FROM Payment_Schedule__c
                WHERE Status__c = 'Completed' AND Booking__c = :bookingId
                ORDER BY S_No__c DESC
                LIMIT 1
            ];
            
            // 2. Get Booking with ALL required fields
            Booking__c book = [
                SELECT Id, Applicant_Name__c, First_Applicant_Name__c, Plot__r.Name, Total__c, Name,
                Project__c, Project1__r.Name, GST__c, RecordType.DeveloperName,
                Quote__r.Agreement_Value_Before_GST__c, Total_Amount__c, Block_Name__c,
                Unit_No__c, Owner_Phone_Number__c, Company_Name__c,
                Email__c, Owner.Email, CRM_Head_Manager_Email__c
                FROM Booking__c
                WHERE Id = :psRecord.Booking__c
            ];
            
            /** ==================GET TEMPLATE RECORD ========================= **/
            String template = '';
            if (String.isBlank(emailContent)) {
                General_Settings__c temp = [
                    SELECT Template_Body__c, Type__c,Subject__c
                    FROM General_Settings__c
                    WHERE Project_Name1__c INCLUDES (:book.Project__c)
                    AND Type__c = 'Demand Note'
                    LIMIT 1
                ];
                
                template = temp.Template_Body__c;
                
                template = template.replace('##APPLICANT_NAME##', book.First_Applicant_Name__c ?? '');
                template = template.replace('##PROJECT_NAME##', book.Project__c ?? '');
                template = template.replace('##BLOCK_NAME##', String.valueOf(book.Block_Name__c ?? ''));
                template = template.replace('##UNIT_NUMBER##', String.valueOf(book.Unit_No__c ?? ''));
                template = template.replace('##CRM_PHONE##', String.valueOf(book.Owner_Phone_Number__c ?? ''));
                template = template.replace('##COMAPANY_NAME##', String.valueOf(book.Company_Name__c ?? ''));
            } else {
                template = emailContent;
            }
            
            // 3. Prepare email list
            List<Messaging.SingleEmailMessage> emails = new List<Messaging.SingleEmailMessage>();
            List<String> lstCCEmail = new List<String>();
            
            if (book != null && !String.isBlank(book.Email__c)) {
                
                // 4. Generate the PDF — pass reminderType=Revised Demand
                PageReference vfPage = Page.DemandNote;
                vfPage.getParameters().put('id', book.Id);
                vfPage.getParameters().put('reminderType', 'REVISED DEMAND NOTE');
                Blob pdfBlob = !Test.isRunningTest() ? vfPage.getContentAsPDF() : Blob.valueOf('testblob');
                
                // 5. Prepare email
                Messaging.SingleEmailMessage email = new Messaging.SingleEmailMessage();
                
                List<String> sendTo = new List<String>();
                sendTo.add(book.Email__c);
                
                if (!String.isBlank(book.Owner.Email)) {
                    lstCCEmail.add(book.Owner.Email);
                }
                if (!String.isBlank(book.CRM_Head_Manager_Email__c)) {
                    lstCCEmail.add(book.CRM_Head_Manager_Email__c);
                }
                if (!lstCCEmail.isEmpty()) {
                    email.setCcAddresses(lstCCEmail);
                }
                
                email.setToAddresses(sendTo);
                string rawSubject = 'Revised Demand Note for Completion of ' + psRecord.Name + ' In ' + book.Project1__r.Name;
                if (!String.isBlank(subject)) {
                    rawSubject = subject;
                }
                
                email.setSubject(rawSubject);
 
                String htmlBody =
                    '<html><body style="font-family: Arial; font-size:14px; color:#000; line-height:1.4;">'
                    + template +
                    '</body></html>';
                
                email.setHtmlBody(htmlBody);
                
                // 7. Prepare attachments
                List<Messaging.EmailFileAttachment> emailAttachments = new List<Messaging.EmailFileAttachment>();
                
                // Attach files from contentIds
                if (contentIds != null && !contentIds.isEmpty()) {
                    List<ContentVersion> contentVersionsMain = [
                        SELECT Title, FileExtension, VersionData
                        FROM ContentVersion
                        WHERE ContentDocumentId IN :contentIds
                        AND IsLatest = true
                    ];
                    
                    for (ContentVersion cv : contentVersionsMain) {
                        Messaging.EmailFileAttachment contentAttach = new Messaging.EmailFileAttachment();
                        contentAttach.setFileName(cv.Title + '.' + cv.FileExtension);
                        contentAttach.setBody(cv.VersionData);
                        emailAttachments.add(contentAttach);
                    }
                }
                
                // Attach the Demand PDF
                Messaging.EmailFileAttachment attachment = new Messaging.EmailFileAttachment();
                attachment.setFileName('Revised Demand Note.pdf');
                attachment.setBody(pdfBlob);
                emailAttachments.add(attachment);
                
                if (!emailAttachments.isEmpty()) {
                    email.setFileAttachments(emailAttachments);
                }
                
                // 8. Set OrgWideEmailAddress using Payment Schedule's CreatedBy email
                if (!Test.isRunningTest()) {
                    String createdEmail = psRecord.CreatedBy.Email;
                    List<OrgWideEmailAddress> orgWideEmail = [
                        SELECT Id FROM OrgWideEmailAddress WHERE Address = :createdEmail LIMIT 1
                    ];
                    if (!orgWideEmail.isEmpty()) {
                        email.setOrgWideEmailAddressId(orgWideEmail[0].Id);
                    }
                }
                
                email.setSaveAsActivity(true);
                email.setWhatId(book.Id);  // Link activity to the Booking record
                
                emails.add(email);
            }
            
            // 9. Send emails
            if (!emails.isEmpty()) {
                Messaging.sendEmail(emails);
            }
            
            return 'Revised Demand sent successfully.';
            
        } catch (Exception e) {
            throw new AuraHandledException('Error sending Revised Demand: ' + e.getMessage());
        }
    }
}