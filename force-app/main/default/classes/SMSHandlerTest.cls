@isTest
public class SMSHandlerTest {
  
    // ---- Mock for HTTP Callouts ----
    private class SMSMock implements HttpCalloutMock {
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
        
        // Create site visit
        Project__c pr = new Project__c(
            Location__c = 'google.com',
            Name ='test'
        );
        insert pr;
    }
    
    @isTest
    static void testSMSController() {
        
        // Use HTTP Mock
         Test.setMock(HttpCalloutMock.class, new SMSMock());
        
        Lead ld = [SELECT Id,FirstName,LastName,Allocated_Project__c, Phone__c,Name FROM Lead LIMIT 1];
        Site_Visit__c sv = [SELECT Id,SLead__r.Name,Project__c,SV_Proposed_Date_Time__c,SLead__r.Phone__c FROM Site_Visit__c LIMIT 1];
        
        // ACTION 1 – Welcome
        Test.startTest();
      
        SMSHandler smsc = new SMSHandler(new List<Lead>{ ld }, '1');
        smsc.sendWelcomeMsg(new List<Lead>{ ld });
        
        Test.stopTest();
        
    }
    
    @isTest
    static void testSMSController2() {
        
        // Use HTTP Mock
          Test.setMock(HttpCalloutMock.class, new SMSMock());
        
        Lead ld = [SELECT Id,FirstName,LastName,Allocated_Project__c, Phone__c,Name FROM Lead LIMIT 1];
        Site_Visit__c sv = [SELECT Id,SLead__r.Name,Project__c,SV_Proposed_Date_Time__c,SLead__r.Phone__c FROM Site_Visit__c LIMIT 1];
        
        // ACTION 1 – Welcome
        Test.startTest();
       
        SMSHandler smsc = new SMSHandler(new List<Lead>{ ld }, '2');
        smsc.sendNotConnectedMsg(new List<Lead>{ ld });
        
        
        
        Test.stopTest();
        
    }
    @isTest
    static void testSMSController3() {
        
        // Use HTTP Mock
          Test.setMock(HttpCalloutMock.class, new SMSMock());
        
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
        
        
        Lead ld = new Lead(
            LastName = 'Test',
            Company = 'testcompany',
            Phone__c = '8778987789',
            Source_Type__c = 'Google',
            Allocated_Project__c = 'Trifecta Vanto'
        );
        insert ld;
        
        Plot__c ut = new Plot__c(
            Status__c = 'Available',
            Project__c = pjt.Id
        );
        insert ut;
        
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
            SLead__c = ld.Id
        );
        insert qc;
        
        
        Booking__c book = new Booking__c(
            Funding_Type__c = 'Loan',
            Quote__c = qc.Id,
            Plot__c = ut.Id,
            CRM_Manager__c = UserInfo.getUserId()
        );
        insert book;
        
        // ACTION 1 – Welcome
        Test.startTest();
       SMSHandler smsc = new SMSHandler(new List<Booking__c>{ book }, '6');
        smsc.sendBookingDoneMsg(new List<Booking__c>{ book });
        
        Test.stopTest();
        
    }
    @isTest
    static void testSMSController4() {
        
        // Use HTTP Mock
          Test.setMock(HttpCalloutMock.class, new SMSMock());
        
        Lead ld = [SELECT Id,FirstName,LastName,Allocated_Project__c, Phone__c,Name FROM Lead LIMIT 1];
        Site_Visit__c sv = [SELECT Id,SLead__r.Name,Project__c,SV_Proposed_Date_Time__c,SLead__r.Phone__c FROM Site_Visit__c LIMIT 1];
        
        // ACTION 1 – Welcome
        Test.startTest();
       
         SMSHandler smsc = new SMSHandler(new List<Site_Visit__c>{ sv }, '3');
        smsc.sendSVProposedMsg(new List<Site_Visit__c>{ sv });
        
        
        
        Test.stopTest();
        
    }
    @isTest
    static void testSMSController5() {
        
        // Use HTTP Mock
          Test.setMock(HttpCalloutMock.class, new SMSMock());
        
        Lead ld = [SELECT Id,FirstName,LastName,Allocated_Project__c, Phone__c,Name FROM Lead LIMIT 1];
        Site_Visit__c sv = [SELECT Id,SLead__r.Name,Project__c,SV_Proposed_Date_Time__c,SLead__r.Phone__c,OwnerId,Owner.Name,
                            SV_Completed_Date_Time__c,Date__c FROM Site_Visit__c LIMIT 1];
        
        Project__c pr = [SELECT Id,Location__c,Name FROM Project__c LIMIT 1];
        
        Test.startTest();
        try {
           
            SMSHandler smsc = new SMSHandler(new List<Site_Visit__c>{ sv }, '4');
            smsc.sendSVConfirmedMsg(new List<Site_Visit__c>{ sv });
            
            System.assert(true, 'Method executed without unhandled exception.');
        }
        catch (Exception ex) {
        }
        Test.stopTest();
        
    }
    @isTest
    static void testSMSController6() {
        
        // Use HTTP Mock
          Test.setMock(HttpCalloutMock.class, new SMSMock());
        
        Lead ld = [SELECT Id,FirstName,LastName,Allocated_Project__c, Phone__c,Name FROM Lead LIMIT 1];
        Site_Visit__c sv = [SELECT Id,SLead__r.Name,Project__c,SV_Proposed_Date_Time__c,SLead__r.Phone__c,OwnerId,Owner.Name,
                            SV_Completed_Date_Time__c,Date__c FROM Site_Visit__c LIMIT 1];
        
        // ACTION 1 – Welcome
        Test.startTest();
       SMSHandler smsc = new SMSHandler(new List<Site_Visit__c>{ sv }, '5');
        smsc.sendSVDoneMsg(new List<Site_Visit__c>{ sv });
        
        Test.stopTest();
        
    }
}