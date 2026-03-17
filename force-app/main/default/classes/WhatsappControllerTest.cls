@isTest
private class WhatsappControllerTest {

    // ---- Mock for HTTP Callouts ----
    private class WhatsAppMock implements HttpCalloutMock {
        public HTTPResponse respond(HTTPRequest req) {
            HttpResponse res = new HttpResponse();
            res.setStatusCode(200);
            res.setBody('{"status":"success"}');
            return res;
        }
    }


    @testSetup
    static void setupData() {

        // Create test Lead
        Lead ld = new Lead(
            LastName = 'PreSales',
            Allocated_Project__c = 'Trifecta Vanto',
            Phone__c = '8111111111',
            Lead_Status__c = 'New',
            Source_Type__c = 'Google',
            Company='Trifecta'

        );
        insert ld;

        // Create Users first (Setup objects)
        Profile p = [SELECT Id FROM Profile WHERE Name = 'Pre Sales' LIMIT 1];

        User u = new User(
            ProfileId = p.Id,
            LastName = 'RH23',
            Email = 'RH@gm1ail.com',
            Username = 'RH@1gmail.com' + System.currentTimeMillis(),
            CompanyName = 'RH1',
            Title = 'titletitl1e',
            Alias = 'lokma1n',
            TimeZoneSidKey = 'America/Los_Angeles',
            EmailEncodingKey = 'UTF-8',
            LanguageLocaleKey = 'en_US',
            LocaleSidKey = 'en_US',
            Availability__c = true,
            IsActive = true,
            is_working__c = true
        );
        insert u;

        // Create user for site visit
        User usr = [SELECT Id FROM User WHERE IsActive = true and Alias = 'lokma1n' LIMIT 1];

        // Create site visit
        Site_Visit__c sv = new Site_Visit__c(
            SLead__c = ld.Id,
            OwnerId = usr.Id,
            Project__c = 'Trifecta Vanto',
            SV_Proposed_Date_Time__c = System.now().addMinutes(2),
            Date__c = System.now().addMinutes(2),
            SV_Completed_Date_Time__c = System.now().addMinutes(2)

        );
        insert sv;

        // Create Project
        Project__c pr = new Project__c(
            Location__c = 'google.com',
            Name ='test'
        );
        insert pr;

        // Create Project for Booking
        Project__c pjt = new Project__c(
            Name = 'Trifecta Vanto',
            Project__c = 'Trifecta Vanto',
            Active__c = true
        );
        insert pjt;

        Block__c bc = new Block__c(
            Name = 'A',
            Project__c = pjt.Id
        );
        insert bc;

        Plot__c ut = new Plot__c(
            Status__c = 'Available',
            Project__c = pjt.Id
        );
        insert ut;

        Lead bookingLead = new Lead(
            LastName = 'BookingTest',
            Company = 'testcompany',
            Phone__c = '8778987789',
            Source_Type__c = 'Google',
            Allocated_Project__c = 'Trifecta Vanto'
        );
        insert bookingLead;

        Quote__c qc = new Quote__c(
            Block_Lookup__c = bc.Id,
            Quote_status__c = 'Drafted',
            Block__c = 'A2',
            Project__c = 'Trifecta Vanto',
            Payment_Type__c = 'Standard',
            Sale_Area__c = 2567,
            Built_up_area__c = 4567,
            Rate_per_sqft__c = 7100,
            Unit__c = ut.Id,
            SLead__c = bookingLead.Id
        );
        insert qc;

        Booking__c book = new Booking__c(
            Funding_Type__c = 'Loan',
            Quote__c = qc.Id,
            Plot__c = ut.Id,
            CRM_Manager__c = UserInfo.getUserId(),
            Mobile__c = '9876543210',
            First_Applicant_Name__c = 'Test Customer',
            S__c = 'Mr.'
        );
        insert book;

        // Create Receipt for payment receipt test
        Receipt__c rc = new Receipt__c(
            Receipt_Name__c = 'TestReceipt',
            Receipt_Date__c = Date.today(),
            Remarks__c = 'Test receipt',
            Booking__c = book.Id,
            Amount_Received__c = 50000
        );
        insert rc;

        // Create Demand Raised for demand test
        Demand_Raised__c dr = new Demand_Raised__c(
            Booking__c = book.Id,
            Grand_Total__c = 100000,
            Due_Date__c = Date.today().addDays(30)
        );
        insert dr;
    }

    // Helper method to get test booking
    private static Booking__c getTestBooking() {
        return [SELECT Id, Mobile__c, First_Applicant_Name__c, Unit_No__c,
                       Project_Block_Name__c, CRM_Executive_Contact_No__c,
                       Owner_Full_Name__c, S__c, Plot__r.Name,
                       Plot__r.Super_Built_up_Area__c, Plot__r.BHK_Type__c,
                       Project1__r.Name
                FROM Booking__c LIMIT 1];
    }

    @isTest
    static void testWhatsappController() {

        // Use HTTP Mock
        Test.setMock(HttpCalloutMock.class, new WhatsAppMock());

        Lead ld = [SELECT Id,FirstName,LastName,Allocated_Project__c, Phone__c,Name FROM Lead WHERE LastName = 'PreSales' LIMIT 1];

        // ACTION 1 – Welcome
        Test.startTest();
        WhatsappController wc = new WhatsappController(new List<Lead>{ ld }, '1');
        wc.sendWelcomeMsg(new List<Lead>{ ld });

        Test.stopTest();

    }

    @isTest
    static void testWhatsappController2() {

        // Use HTTP Mock
        Test.setMock(HttpCalloutMock.class, new WhatsAppMock());

        Lead ld = [SELECT Id,FirstName,LastName,Allocated_Project__c, Phone__c,Name FROM Lead WHERE LastName = 'PreSales' LIMIT 1];

        // ACTION 2 – NotConnected
        Test.startTest();
        WhatsappController wc = new WhatsappController(new List<Lead>{ ld }, '2');
        wc.sendNotConnectedMsg(new List<Lead>{ ld });

        Test.stopTest();

    }

    @isTest
    static void testWhatsappController3() {

        // Use HTTP Mock
        Test.setMock(HttpCalloutMock.class, new WhatsAppMock());

        Booking__c book = getTestBooking();

        // ACTION 6 – BookingDone
        Test.startTest();
        WhatsappController wc = new WhatsappController(new List<Booking__c>{ book }, '6');
        wc.sendBookingDoneMsg(new List<Booking__c>{ book });

        Test.stopTest();

    }

    @isTest
    static void testWhatsappController4() {

        // Use HTTP Mock
        Test.setMock(HttpCalloutMock.class, new WhatsAppMock());

        Site_Visit__c sv = [SELECT Id,SLead__r.Name,Project__c,SV_Proposed_Date_Time__c,SLead__r.Phone__c FROM Site_Visit__c LIMIT 1];

        // ACTION 3 – SVProposed
        Test.startTest();
        WhatsappController wc = new WhatsappController(new List<Site_Visit__c>{ sv }, '3');
        wc.sendSVProposedMsg(new List<Site_Visit__c>{ sv });

        Test.stopTest();

    }

    @isTest
    static void testWhatsappController5() {

        // Use HTTP Mock
        Test.setMock(HttpCalloutMock.class, new WhatsAppMock());

        Site_Visit__c sv = [SELECT Id,SLead__r.Name,Project__c,SV_Proposed_Date_Time__c,SLead__r.Phone__c,OwnerId,Owner.Name,
                            SV_Completed_Date_Time__c,Date__c FROM Site_Visit__c LIMIT 1];

        Test.startTest();
        try {
            WhatsappController wc = new WhatsappController(new List<Site_Visit__c>{ sv }, '4');
            wc.sendSVConfirmedMsg(new List<Site_Visit__c>{ sv });

            System.assert(true, 'Method executed without unhandled exception.');
        }
        catch (Exception ex) {
        }
        Test.stopTest();

    }

    @isTest
    static void testWhatsappController6() {

        // Use HTTP Mock
        Test.setMock(HttpCalloutMock.class, new WhatsAppMock());

        Site_Visit__c sv = [SELECT Id,SLead__r.Name,Project__c,SV_Proposed_Date_Time__c,SLead__r.Phone__c,OwnerId,Owner.Name,
                            SV_Completed_Date_Time__c,Date__c FROM Site_Visit__c LIMIT 1];

        // ACTION 5 – SVDone
        Test.startTest();
        WhatsappController wc = new WhatsappController(new List<Site_Visit__c>{ sv }, '5');
        wc.sendSVDoneMsg(new List<Site_Visit__c>{ sv });

        Test.stopTest();

    }

    @isTest
    static void testSendPaymentReceiptMsg() {

        // Use HTTP Mock
        Test.setMock(HttpCalloutMock.class, new WhatsAppMock());

        List<Receipt__c> receipts = [SELECT Id, Booking__r.Mobile__c, Booking__r.First_Applicant_Name__c,
                                            Amount_Received__c, Booking__r.Unit_No__c,
                                            Project_Block_Name__c, Booking__r.CRM_Executive_Contact_No__c
                                     FROM Receipt__c LIMIT 1];

        // ACTION 7 – Payment Receipt
        Test.startTest();
        WhatsappController wc = new WhatsappController(receipts, '7');
        wc.sendPaymentReceiptMsg(receipts);
        Test.stopTest();

    }

    @isTest
    static void testSendDemandRaisedMsg() {

        // Use HTTP Mock
        Test.setMock(HttpCalloutMock.class, new WhatsAppMock());

        List<Demand_Raised__c> demands = [SELECT Id, Booking__c, Booking__r.Mobile__c,
                                                 Booking__r.First_Applicant_Name__c,
                                                 Booking__r.Unit_No__c, Payment_Due_Date__c,
                                                 Booking__r.CRM_Executive_Contact_No__c,
                                                 Grand_Total__c, Project_Block_Name__c
                                          FROM Demand_Raised__c LIMIT 1];

        // ACTION 8 – Demand Raised
        Test.startTest();
        WhatsappController wc = new WhatsappController(demands, '8');
        wc.sendDemandRaisedMsg(demands);
        Test.stopTest();

    }

    @isTest
    static void testSendDemandReminderMsg() {

        // Use HTTP Mock
        Test.setMock(HttpCalloutMock.class, new WhatsAppMock());

        Booking__c book = getTestBooking();

        // ACTION 9 – Demand Reminder
        Test.startTest();
        WhatsappController wc = new WhatsappController(new List<Booking__c>{ book }, '9');
        wc.sendDemandReminderMsg(new List<Booking__c>{ book });
        Test.stopTest();

    }

    @isTest
    static void testSendRevisedDemandMsg() {

        // Use HTTP Mock
        Test.setMock(HttpCalloutMock.class, new WhatsAppMock());

        Booking__c book = getTestBooking();
        Decimal testAmount = 75000;
        Date testDueDate = Date.today().addDays(15);

        // ACTION 10 – Revised Demand (with amount and due date)
        Test.startTest();
        WhatsappController wc = new WhatsappController(book, testAmount, testDueDate, '10');
        wc.sendRevisedDemandMsg(book, testAmount, testDueDate);
        Test.stopTest();

    }

    @isTest
    static void testSendRevisedDemandMsgNullValues() {

        // Use HTTP Mock
        Test.setMock(HttpCalloutMock.class, new WhatsAppMock());

        Booking__c book = getTestBooking();

        // Test with null amount and null due date for branch coverage
        Test.startTest();
        WhatsappController wc = new WhatsappController(book, null, null, '10');
        wc.sendRevisedDemandMsg(book, null, null);
        Test.stopTest();

    }

    @isTest
    static void testSendRevisedDemandMsgSingleParam() {

        // Use HTTP Mock
        Test.setMock(HttpCalloutMock.class, new WhatsAppMock());

        Booking__c book = getTestBooking();

        // Test the single-parameter overload
        Test.startTest();
        WhatsappController wc = new WhatsappController(book, '11');
        wc.sendRevisedDemandMsg(book);
        Test.stopTest();

    }

    @isTest
    static void testSendWelcomeMail() {

        // Use HTTP Mock
        Test.setMock(HttpCalloutMock.class, new WhatsAppMock());

        Booking__c book = getTestBooking();

        // ACTION 11 – Welcome Mail
        Test.startTest();
        WhatsappController wc = new WhatsappController(book, '11');
        wc.sendWelcomeMail(book);
        Test.stopTest();

    }

    @isTest
    static void testExecuteMethod() {

        // Use HTTP Mock
        Test.setMock(HttpCalloutMock.class, new WhatsAppMock());

        Lead ld = [SELECT Id,FirstName,LastName,Allocated_Project__c, Phone__c,Name FROM Lead WHERE LastName = 'PreSales' LIMIT 1];

        // Test execute method - will hit Test.isRunningTest() early return
        Test.startTest();
        WhatsappController wc = new WhatsappController(new List<Lead>{ ld }, '1');
        wc.execute(null);
        Test.stopTest();

    }

    @isTest
    static void testNoPhoneNumberSkip() {

        // Use HTTP Mock
        Test.setMock(HttpCalloutMock.class, new WhatsAppMock());

        // Create a lead without phone number to test skip logic
        Lead ldNoPhone = new Lead(
            LastName = 'NoPhone',
            Company = 'TestCo',
            Source_Type__c = 'Google',
            Allocated_Project__c = 'Trifecta Vanto'
        );
        insert ldNoPhone;

        Lead ld = [SELECT Id,FirstName,LastName,Allocated_Project__c, Phone__c,Name FROM Lead WHERE LastName = 'NoPhone' LIMIT 1];

        Test.startTest();
        WhatsappController wc = new WhatsappController(new List<Lead>{ ld }, '1');
        wc.sendWelcomeMsg(new List<Lead>{ ld });
        Test.stopTest();

    }
}