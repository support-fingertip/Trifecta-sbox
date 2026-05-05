public class WelcomeEmailQueueable implements Queueable, Database.AllowsCallouts {

    private Id bookingId;
    private String demandId1;
    private String demandId2;
    private String projectType;
    private Id quoteId;
    private String emailContent;
    private List<String> toAddresses;
    private List<String> contentIds;
    private List<String> ccEmails;
    private String subject;

    public WelcomeEmailQueueable(Id bookingId, String demandId1, String demandId2,
            String projectType, Id quoteId, String emailContent,
            List<String> toAddresses, List<String> contentIds,
            List<String> ccEmails, String subject) {
        this.bookingId = bookingId;
        this.demandId1 = demandId1;
        this.demandId2 = demandId2;
        this.projectType = projectType;
        this.quoteId = quoteId;
        this.emailContent = emailContent;
        this.toAddresses = toAddresses;
        this.contentIds = contentIds;
        this.ccEmails = ccEmails;
        this.subject = subject;
    }

    public void execute(QueueableContext context) {
        List<Messaging.EmailFileAttachment> emailAttachments =
                new List<Messaging.EmailFileAttachment>();

        // ── Content-document attachments (user-selected files) ──
        if (contentIds != null && !contentIds.isEmpty()) {
            Set<Id> docIds = new Set<Id>();
            for (String cid : contentIds) { docIds.add(cid); }
            for (ContentVersion cv : [SELECT Title, FileExtension, VersionData
                                      FROM ContentVersion
                                      WHERE ContentDocumentId IN :docIds]) {
                Messaging.EmailFileAttachment a = new Messaging.EmailFileAttachment();
                a.setFileName(cv.Title + '.' + cv.FileExtension);
                a.setBody(cv.VersionData);
                emailAttachments.add(a);
            }
        }

        // ── Booking-form attachment (project-type specific) ──
        String quotePdf = 'TrifectaCostsheet';
        Messaging.EmailFileAttachment bookingFormAttach;

        if (projectType == 'Apartments') {
            bookingFormAttach = generatePdf('Trifecta_Booking_Form', bookingId);
            quotePdf = 'TrifectaCostsheet';
        } else if (projectType == 'Row House') {
            bookingFormAttach = generatePdf('TrifectaRowHouseBookingForm', bookingId);
            quotePdf = 'TrifectaRowHouseCostSheet';
        } else if (projectType == 'Villas') {
            bookingFormAttach = generatePdf('LandVillaBookingForm', bookingId);
            Messaging.EmailFileAttachment villaConst =
                    generatePdf('ConstructionVillaBookingForm', bookingId);
            if (villaConst != null) { emailAttachments.add(villaConst); }
            quotePdf = 'trifectaVillaCostSheet';
        }

        // ── Cost-sheet attachment ──
        Messaging.EmailFileAttachment costSheet = generatePdf(quotePdf, quoteId);

        // ── Demand-note attachments via Demand_Note_Send (Demand_Raised__c Id) ──
        Messaging.EmailFileAttachment demandNote1;
        if (String.isNotBlank(demandId1) && !demandId1.startsWith('Error')) {
            demandNote1 = generatePdf('Demand_Note_Send', demandId1);
            if (projectType == 'Villas' && demandNote1 != null) {
                demandNote1.setFileName('Land Agreement Demand Note.pdf');
            }
            else
            {
                demandNote1.setFileName('Demand Note.pdf');
            }
        }

        Messaging.EmailFileAttachment demandNote2;
        if (projectType == 'Villas' &&
                String.isNotBlank(demandId2) && !demandId2.startsWith('Error')) {
            demandNote2 = generatePdf('Demand_Note_Send', demandId2);
            if (demandNote2 != null) {
                demandNote2.setFileName('Construction Agreement Demand Note.pdf');
            }
        }

        // ── Consolidated-receipt attachment ──
        Messaging.EmailFileAttachment consolidated =
                generatePdf('ConsolidatedReceipt', bookingId);

        // ── Assemble attachment list ──
        if (bookingFormAttach != null) { emailAttachments.add(bookingFormAttach); }
        if (costSheet != null)         { emailAttachments.add(costSheet); }
        if (demandNote1 != null)       { emailAttachments.add(demandNote1); }
        if (demandNote2 != null)       { emailAttachments.add(demandNote2); }
        if (consolidated != null)      { emailAttachments.add(consolidated); }

        // ── Build and send email ──
        Messaging.SingleEmailMessage mail = new Messaging.SingleEmailMessage();

        if (!Test.isRunningTest()) {
            List<OrgWideEmailAddress> orgWide = [
                SELECT Id FROM OrgWideEmailAddress
                WHERE DisplayName = 'Trifecta Admin' LIMIT 1];
            if (!orgWide.isEmpty()) {
                mail.setOrgWideEmailAddressId(orgWide[0].Id);
            }
        }

        mail.setToAddresses(toAddresses);
        if (ccEmails != null && !ccEmails.isEmpty()) {
            mail.setCcAddresses(ccEmails);
        }
        system.debug('emailContent'+emailContent);
        mail.setSubject(subject);
        // Remove extra blank paragraph before setting body
        emailContent = emailContent.replace('<p style="text-align: justify;"><br></p>', '');
        
        mail.setHtmlBody(emailContent);
        mail.setHtmlBody(emailContent);
        if (!emailAttachments.isEmpty()) {
            mail.setFileAttachments(emailAttachments);
        }

        Messaging.sendEmail(new List<Messaging.SingleEmailMessage>{ mail });
    }

    private Messaging.EmailFileAttachment generatePdf(String vfPageName, Id recordId) {
        PageReference vfPage = new PageReference('/apex/' + vfPageName);
        vfPage.getParameters().put('id', recordId);
        vfPage.setRedirect(true);

        Blob pdfBlob;
        if (Test.isRunningTest()) {
            pdfBlob = Blob.valueOf('Test PDF Content');
        } else {
            pdfBlob = vfPage.getContentAsPDF();
        }

        Messaging.EmailFileAttachment att = new Messaging.EmailFileAttachment();
        att.setFileName(vfPageName + '.pdf');
        att.setBody(pdfBlob);
        att.setContentType('application/pdf');
        return att;
    }

    private Messaging.EmailFileAttachment generatePdf(String vfPageName, String recordIdStr) {
        return generatePdf(vfPageName, Id.valueOf(recordIdStr));
    }
}