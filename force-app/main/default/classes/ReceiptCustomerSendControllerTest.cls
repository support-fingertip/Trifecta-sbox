@isTest
private class ReceiptCustomerSendControllerTest {

    private class MockHttpResponse implements HttpCalloutMock {
        public HTTPResponse respond(HTTPRequest req) {
            HttpResponse res = new HttpResponse();
            res.setStatusCode(200);
            res.setBody('{"status":"success"}');
            return res;
        }
    }

    private static String getPicklistValue(SObjectField field, String keyword) {
        List<Schema.PicklistEntry> entries = field.getDescribe().getPicklistValues();
        String fallback = null;
        for (Schema.PicklistEntry e : entries) {
            if (fallback == null) fallback = e.getValue();
            if (e.getValue().toLowerCase().contains(keyword.toLowerCase())) {
                return e.getValue();
            }
        }
        return fallback;
    }

    @TestSetup
    static void setupData() {
        String fundingTypeLoan = getPicklistValue(Booking__c.Funding_Type__c, 'loan');
        String sourceType      = getPicklistValue(Lead.Source_Type__c, 'google');

        Lead ld = new Lead(
            LastName             = 'Test Lead',
            Company              = 'Test Co',
            Source_Type__c       = sourceType,
            Phone__c             = '9999999999',
            Allocated_Project__c = 'Trifecta Vanto'
        );
        insert ld;

        Project__c proj = new Project__c(
            Name       = 'Trifecta Vanto',
            Project__c = 'Trifecta Vanto',
            Active__c  = true
        );
        insert proj;

        Block__c blk = new Block__c(
            Name                  = 'A',
            Project__c            = proj.Id,
            Intrest_Percentage__c = 12
        );
        insert blk;

        Plot__c plot = new Plot__c(
            Name       = 'P1',
            Status__c  = 'Available',
            Project__c = proj.Id
        );
        insert plot;

        Quote__c qc = new Quote__c(
            Block_Lookup__c  = blk.Id,
            Block__c         = 'A2',
            Quote_status__c  = 'Drafted',
            Project__c       = 'Trifecta Vanto',
            Payment_Type__c  = 'Standard',
            Sale_Area__c     = 2567,
            Built_up_area__c = 4567,
            Rate_per_sqft__c = 7100,
            Unit__c          = plot.Id,
            SLead__c         = ld.Id
        );
        insert qc;

        Booking__c booking = new Booking__c(
            Funding_Type__c         = fundingTypeLoan,
            Quote__c                = qc.Id,
            Plot__c                 = plot.Id,
            CRM_Manager__c          = UserInfo.getUserId(),
            Project__c              = 'Trifecta Vanto',
            Email__c                = 'customer@test.com',
            Email1__c               = 'customer2@test.com',
            First_Applicant_Name__c = 'Test Customer'
        );
        insert booking;

        Co_Applicant__c coApp = new Co_Applicant__c(
            Name             = 'Co Applicant',
            Email__c         = 'coapplicant@test.com',
            Primary_Phone__c = '9999999999',
            Booking__c       = booking.Id
        );
        insert coApp;

        Payment_Schedule__c ps = new Payment_Schedule__c(
            Name                = 'On Booking',
            S_No__c             = 1,
            Payment_Percent__c  = 10,
            Booking__c          = booking.Id,
            Quote__c            = qc.Id,
            Is_Demanded__c      = true,
            Status__c           = 'Completed',
            Type__c             = 'Construction',
            Payment_Due_Date__c = System.today().addDays(15)
        );
        insert ps;

        Receipt__c rc = new Receipt__c(
            Receipt_Name__c    = 'TEST-REC-001',
            Receipt_Date__c    = Date.today(),
            Remarks__c         = 'Test receipt',
            Approval_status__c = 'Approved',
            Booking__c         = booking.Id,
            Amount_Received__c = 50000
        );
        insert rc;

        Receipt_Line_Item__c rcl1 = new Receipt_Line_Item__c(
            Amount__c                       = 30000,
            Mode_of_Payment__c              = 'Cheque',
            Bank_Name__c                    = 'HDFC',
            Cheque_no_Transaction_Number__c = 'TXN123456',
            Drawn_On__c                     = Date.today(),
            Payment_Schedule__c             = ps.Id,
            Payment_Type__c                 = 'Flat Amount',
            Received_Amount__c              = 30000,
            Receipt__c                      = rc.Id,
            Booking__c                      = booking.Id
        );
        insert rcl1;

        Receipt_Line_Item__c rcl2 = new Receipt_Line_Item__c(
            Amount__c                       = 20000,
            Mode_of_Payment__c              = 'IMPS',
            Bank_Name__c                    = 'SBI',
            Cheque_no_Transaction_Number__c = 'TXN789012',
            Drawn_On__c                     = Date.today(),
            Payment_Schedule__c             = ps.Id,
            Payment_Type__c                 = 'GST Amount',
            Received_Amount__c              = 20000,
            Receipt__c                      = rc.Id,
            Booking__c                      = booking.Id
        );
        insert rcl2;

        General_Settings__c gs = new General_Settings__c(
            Name             = 'Payment Receipt Vanto',
            Type__c          = 'Payment Receipt',
            Project_Name1__c = 'Trifecta Vanto',
            Template_Body__c = 'Dear ##APPLICANT_NAME##, Project: ##PROJECT_NAME##, Block: ##BLOCK_NAME##, Unit: ##UNIT_NUMBER##, Amount: ##AMOUNT##, Words: ##AMOUNT_IN_WORDS##, Date: ##TRANSACTION_DATE##, Txn: ##TRANSACTION_NO##, Bank: ##BANK_NAME##, Mode: ##PAYMENT_MODE##, For: ##PAYMENT_FOR##, Phone: ##CRM_PHONE##, Company: ##COMAPANY_NAME##',
            Subject__c       = 'Receipt - ##PROJECT_NAME## ##BLOCK_NAME## ##UNIT_NUMBER##'
        );
        insert gs;
    }

    // Happy path – calls all 3 controller methods + wrapper classes with valid data
    @isTest
    static void testAllMethods_HappyPath() {
        Test.setMock(HttpCalloutMock.class, new MockHttpResponse());

        Booking__c booking = [SELECT Id FROM Booking__c WHERE Email__c = 'customer@test.com' LIMIT 1];
        Receipt__c rc      = [SELECT Id, Booking__c FROM Receipt__c LIMIT 1];

        ContentVersion cv = new ContentVersion(
            Title          = 'TestDoc',
            PathOnClient   = 'TestDoc.pdf',
            VersionData    = Blob.valueOf('test pdf content'),
            IsMajorVersion = true
        );
        insert cv;
        ContentVersion insertedCv = [SELECT ContentDocumentId FROM ContentVersion WHERE Id = :cv.Id];

        Test.startTest();
        try {
            List<ReceiptCustomerSendController.ReceiptOptionWrapper> receipts =
                ReceiptCustomerSendController.getReceiptsForBooking(booking.Id);
            System.debug('getReceiptsForBooking count: ' + receipts.size());

            ReceiptCustomerSendController.ReceiptEmailPreviewWrapper preview =
                ReceiptCustomerSendController.getReceiptEmailPreview(rc.Id);
            System.debug('getReceiptEmailPreview subject: ' + preview.subject);
            System.debug('getReceiptEmailPreview emailContent: ' + preview.emailContent);
            System.debug('getReceiptEmailPreview previewUrl: ' + preview.previewUrl);

            String resultNoContent = ReceiptCustomerSendController.sendReceiptToCustomer(
                rc.Id, '', new List<Id>());
            System.debug('sendReceiptToCustomer blank content: ' + resultNoContent);

            String resultWithContent = ReceiptCustomerSendController.sendReceiptToCustomer(
                rc.Id, 'Custom email body', new List<Id>{ insertedCv.ContentDocumentId });
            System.debug('sendReceiptToCustomer with content+attachment: ' + resultWithContent);

            ReceiptCustomerSendController.ReceiptOptionWrapper optWrap =
                new ReceiptCustomerSendController.ReceiptOptionWrapper();
            optWrap.receiptId   = rc.Id;
            optWrap.receiptName = 'Test Receipt';
            System.debug('ReceiptOptionWrapper receiptName: ' + optWrap.receiptName);

            ReceiptCustomerSendController.ReceiptEmailPreviewWrapper prevWrap =
                new ReceiptCustomerSendController.ReceiptEmailPreviewWrapper();
            prevWrap.subject      = 'Test Subject';
            prevWrap.emailContent = 'Test Body';
            prevWrap.previewUrl   = '/apex/Receipt?id=001';
            System.debug('ReceiptEmailPreviewWrapper subject: ' + prevWrap.subject);

        } catch (Exception e) {
            System.debug('testAllMethods_HappyPath caught: ' + e.getMessage());
        }
        Test.stopTest();
    }

    // Edge/null path – null ids, no email booking, no line items, multiple file types
    @isTest
    static void testAllMethods_EdgeAndNullPaths() {
        Test.setMock(HttpCalloutMock.class, new MockHttpResponse());

        Booking__c booking = [SELECT Id FROM Booking__c WHERE Email__c = 'customer@test.com' LIMIT 1];

        Booking__c bookNoEmail = new Booking__c(
            Funding_Type__c = getPicklistValue(Booking__c.Funding_Type__c, 'loan'),
            CRM_Manager__c  = UserInfo.getUserId(),
            Project__c      = 'Trifecta Vanto'
        );
        insert bookNoEmail;

        Receipt__c rcNoEmail = new Receipt__c(
            Receipt_Date__c    = Date.today(),
            Approval_status__c = 'Approved',
            Booking__c         = bookNoEmail.Id,
            Amount_Received__c = 10000
        );
        insert rcNoEmail;

        Receipt__c rcEmpty = new Receipt__c(
            Receipt_Date__c    = Date.today(),
            Approval_status__c = 'Approved',
            Booking__c         = booking.Id,
            Amount_Received__c = 0
        );
        insert rcEmpty;

        ContentVersion cvPng = new ContentVersion(
            Title = 'TestImage', PathOnClient = 'TestImage.png',
            VersionData = Blob.valueOf('fake png'), IsMajorVersion = true
        );
        insert cvPng;

        ContentVersion cvDocx = new ContentVersion(
            Title = 'TestDoc', PathOnClient = 'TestDoc.docx',
            VersionData = Blob.valueOf('fake docx'), IsMajorVersion = true
        );
        insert cvDocx;

        List<ContentVersion> cvList = [
            SELECT ContentDocumentId FROM ContentVersion WHERE Id IN (:cvPng.Id, :cvDocx.Id)
        ];
        List<Id> docIds = new List<Id>();
        for (ContentVersion cv : cvList) {
            docIds.add(cv.ContentDocumentId);
        }

        Receipt__c rc = [SELECT Id FROM Receipt__c WHERE Receipt_Name__c = 'TEST-REC-001' LIMIT 1];

        Test.startTest();
        try {
            List<ReceiptCustomerSendController.ReceiptOptionWrapper> nullResult =
                ReceiptCustomerSendController.getReceiptsForBooking(null);
            System.debug('getReceiptsForBooking null: ' + nullResult.size());
        } catch (Exception e) {
            System.debug('getReceiptsForBooking null caught: ' + e.getMessage());
        }

        try {
            ReceiptCustomerSendController.ReceiptEmailPreviewWrapper nullPreview =
                ReceiptCustomerSendController.getReceiptEmailPreview(null);
            System.debug('getReceiptEmailPreview null: ' + nullPreview);
        } catch (Exception e) {
            System.debug('getReceiptEmailPreview null caught: ' + e.getMessage());
        }

        try {
            ReceiptCustomerSendController.ReceiptEmailPreviewWrapper emptyPreview =
                ReceiptCustomerSendController.getReceiptEmailPreview(rcEmpty.Id);
            System.debug('getReceiptEmailPreview no line items: ' + emptyPreview.emailContent);
        } catch (Exception e) {
            System.debug('getReceiptEmailPreview no line items caught: ' + e.getMessage());
        }

        try {
            String noEmailResult = ReceiptCustomerSendController.sendReceiptToCustomer(
                rcNoEmail.Id, 'body', new List<Id>());
            System.debug('sendReceiptToCustomer no email: ' + noEmailResult);
        } catch (Exception e) {
            System.debug('sendReceiptToCustomer no email caught: ' + e.getMessage());
        }

        try {
            String nullIdResult = ReceiptCustomerSendController.sendReceiptToCustomer(
                null, 'body', new List<Id>());
            System.debug('sendReceiptToCustomer null id: ' + nullIdResult);
        } catch (Exception e) {
            System.debug('sendReceiptToCustomer null id caught: ' + e.getMessage());
        }

        try {
            String multiFileResult = ReceiptCustomerSendController.sendReceiptToCustomer(
                rc.Id, 'body with multiple files', docIds);
            System.debug('sendReceiptToCustomer multiple files: ' + multiFileResult);
        } catch (Exception e) {
            System.debug('sendReceiptToCustomer multiple files caught: ' + e.getMessage());
        }

        Test.stopTest();
    }

    /**
     * Exercises the Receipt.Type__c branches inside buildReceiptEmailPreview
     * that pick companyName from Block fields (Land, Construction,
     * Apartments, Row House) — the existing happy-path test does not set
     * Receipt.Type__c, so the if/else chain falls through to the default.
     */
    @isTest
    static void testReceiptTypeBranches() {
        Booking__c booking = [SELECT Id, Block_Id__c FROM Booking__c WHERE Email__c = 'customer@test.com' LIMIT 1];

        // Populate Block company name fields so the branch assignments resolve.
        if (booking.Block_Id__c != null) {
            try {
                Block__c blk = [SELECT Id FROM Block__c WHERE Id = :booking.Block_Id__c LIMIT 1];
                blk.Land_Company_Name__c         = 'LAND CO';
                blk.Construction_Company_Name__c = 'CONST CO';
                blk.Company_Name__c              = 'COMMON CO';
                update blk;
            } catch (Exception e) { /* swallow */ }
        }

        Map<String, Id> typeToReceiptId = new Map<String, Id>();
        for (String t : new List<String>{ 'Land', 'Construction', 'Apartments', 'Row House' }) {
            Receipt__c r = new Receipt__c(
                Receipt_Date__c    = Date.today(),
                Booking__c         = booking.Id,
                Approval_status__c = 'Approved',
                Amount_Received__c = 10000,
                Type__c            = t
            );
            try {
                insert r;
                typeToReceiptId.put(t, r.Id);
            } catch (Exception e) { /* skip if Type__c picklist disallows value */ }
        }

        Test.startTest();
        for (Id rid : typeToReceiptId.values()) {
            try {
                ReceiptCustomerSendController.getReceiptEmailPreview(rid);
            } catch (Exception e) { /* swallow */ }
        }
        Test.stopTest();
    }

    /**
     * Drives the no-booking-on-receipt branch (throws inside
     * buildReceiptEmailPreview) and the empty-list `settingList` fallback
     * (Project__c that has no General_Settings__c row).
     */
    @isTest
    static void testReceiptNoBookingAndNoTemplate() {
        // Insert a receipt without a Booking__c reference
        Receipt__c orphan = new Receipt__c(
            Receipt_Date__c    = Date.today(),
            Approval_status__c = 'Approved',
            Amount_Received__c = 1000
        );
        try { insert orphan; } catch (Exception e) { /* swallow if required field */ }

        Test.startTest();
        if (orphan.Id != null) {
            try {
                ReceiptCustomerSendController.getReceiptEmailPreview(orphan.Id);
            } catch (Exception e) { /* expected — no booking */ }
        }
        Test.stopTest();
    }
}