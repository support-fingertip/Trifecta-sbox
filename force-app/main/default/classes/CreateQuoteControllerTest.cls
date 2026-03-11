@isTest
public class CreateQuoteControllerTest {
    @isTest
    public static void CreateQuotetest(){
        
        // Profile
        Profile p = [SELECT Id FROM Profile WHERE Name = 'Standard User' LIMIT 1];

// Create a User for test context
User testUser = new User(
    FirstName = 'Test',
    LastName  = 'User',
    Email = 'testuser@example.com',
    Username = 'testuser' + DateTime.now().getTime() + '@example.com',
    Alias = 'tusr',
    CommunityNickname = 'tuser123',
    TimeZoneSidKey = 'America/Los_Angeles',
    LocaleSidKey = 'en_US',
    EmailEncodingKey = 'UTF-8',
    LanguageLocaleKey = 'en_US',
    ProfileId = p.Id
);

insert testUser;
        
        User salesHead = new User(
    FirstName = 'Vijayan',
    LastName = 'P',
    Email = 'vijayan.p' + DateTime.now().getTime() + '@example.com',
    Username = 'vijayan.p' + DateTime.now().getTime() + '@example.com',
    Alias = 'vijpn',
    CommunityNickname = 'vijayanP',
    TimeZoneSidKey = 'America/Los_Angeles',
    LocaleSidKey = 'en_US',
    EmailEncodingKey = 'UTF-8',
    LanguageLocaleKey = 'en_US',
    ProfileId = p.Id
           
);
insert salesHead;

// Management User (Sunil)
User mgmtUser = new User(
    FirstName = 'Sunil',
    LastName = 'Management User',
    Email = 'sunil.mgmt' + DateTime.now().getTime() + '@example.com',
    Username = 'sunil.mgmt' + DateTime.now().getTime() + '@example.com',
    Alias = 'sunmg',
    CommunityNickname = 'sunilMgmt',
    TimeZoneSidKey = 'America/Los_Angeles',
    LocaleSidKey = 'en_US',
    EmailEncodingKey = 'UTF-8',
    LanguageLocaleKey = 'en_US',
    ProfileId = p.Id
);
insert mgmtUser;
        
        
        Project__c pjt = new Project__c(
            Name = 'Trifecta Vanto',
            Project__c = 'Trifecta Vanto',
            Active__c = true
        );
        insert pjt;
        
        Block__c bc = new Block__c();
        bc.Name='A2';
        bc.Project__c=pjt.id;
        insert bc;
        
        Lead ld = new Lead();
        ld.LastName = 'Test';
        ld.Company = 'testcompany';
        ld.Phone__c = '8778987789';
        ld.Source_Type__c = 'Referral and Loyalty';
        ld.Allocated_Project__c = 'Trifecta Vanto';
        insert ld;
        
          Plot__c ut = new Plot__c(
            Name = 'P1',
            Status__c = 'Available',
            Project__c = pjt.Id
        );
        insert ut;
       
        
        Quote__c qc = new Quote__c();
        qc.Quote_status__c = 'Drafted';
        qc.Block__c = 'A2';
        //qc.Booking__c = book.Id;
        qc.Project_Sales_Head__c = testUser.Id;
        qc.Block_Lookup__c=bc.Id;
        qc.Payment_Type__c = 'Standard';
        qc.Approver_1__c = salesHead.Id;
        qc.Approver_2__c = mgmtUser.Id;
        insert qc;
        
        
        Quote__c qc1 = new Quote__c();
        qc1.Quote_status__c = 'Drafted';
        qc1.Block__c = 'A2';
        //qc.Booking__c = book.Id;
        qc1.Project_Sales_Head__c = testUser.Id;
        qc1.Block_Lookup__c=bc.Id;
        qc1.Payment_Type__c = 'Custom';
        qc1.Approver_1__c = salesHead.Id;
        qc1.Approver_2__c = mgmtUser.Id;
        insert qc1;
        
       
          Booking__c book = new Booking__c(
            Funding_Type__c = 'Loan',
            Quote__c = qc.Id,
            Plot__c = ut.Id,
            CRM_Manager__c = UserInfo.getUserId(),
            Project__c = 'Trifecta Vanto'
        );
        insert book;
        
       
       Master_payment_schedule__c mps = new Master_payment_schedule__c();
        mps.Project__c = pjt.id;
        mps.Name = 'test';
        mps.Payment_Percent__c = 20;
        mps.Status__c ='Completed';
        mps.Block__c = bc.Id;
        insert mps;
        
        Payment_schedule__c ps = new Payment_schedule__c();
         ps.Payment_percent__c =100;
        ps.Master_Payment_Schedule__c = mps.Id;
        ps.Is_Demanded__c = true;
        ps.Quote__c = qc.id;
        ps.Type__c = 'Land';
         insert ps;
        
         Payment_schedule__c ps1 = new Payment_schedule__c();
         ps1.Payment_percent__c =100;
        ps1.Master_Payment_Schedule__c = mps.Id;
        ps1.Is_Demanded__c = true;
        ps1.Quote__c = qc.id;
        ps1.Type__c = 'Construction';
         insert ps1;
        
        Payment_schedule__c ps2 = new Payment_schedule__c();
         ps2.Payment_percent__c =100;
        ps2.Master_Payment_Schedule__c = mps.Id;
        ps2.Is_Demanded__c = true;
        ps2.Quote__c = qc.id;
        ps2.Type__c = 'Construction';
         insert ps2;
        
        
        
        List<Payment_schedule__c> PaymentList = new List<Payment_schedule__c>();
        
        PaymentList.add(ps);
        PaymentList.add(ps1);
         PaymentList.add(ps2);
        
        Test.setMock(HttpCalloutMock.class, new RestMock());
        
        System.runAs(salesHead) {
   // Test.startTest();
    //Approval.ProcessSubmitRequest.setAllowTestApproval(true);
   // CreateQuoteController.callQuoteApproval(qc.id);
  //  Test.stopTest();
  CreateQuoteController.getData(ld.Id);
}
        
        
        
        
      // CreateQuoteController.getPlots(ld.Id, pjt.Name); 
      //  CreateQuoteController.getvillasPlots( pjt.Name);
        CreateQuoteController.saveOppPlot(qc, PaymentList, true);
        CreateQuoteController.saveOppPlot(qc1, PaymentList, true);
      CreateQuoteController.callQuoteApproval(qc.id);
        
       // CreateQuoteController.getPaymentTypePicklistValues();
      //  CreateQuoteController.getBlock(ld.id);
        CreateQuoteController.getPlots(bc.Name);
      //  CreateQuoteController.quotationqquery(ld.Id);
        CreateQuoteController.getPaymentSchedules('Standard','Trifecta Vanto', bc.Id);
        //CreateQuoteController.getPaymentSchedules('Custom','Trifecta Vanto');
        CreateQuoteController.deleteSchedule(ps.id);
        String qid =qc.id;
       CreateQuoteController.insertSchedules(PaymentList,qc.Id);
       CreateQuoteController.QuoteCreate(ld.Id,qc.Id);
        
        
       // CreateQuoteController.getblocks('Mantri Serenity');
        //CreateQuoteController.getType(ld.Id);
       // CreateQuoteController.getPicklistValues('Lead','Allocated_Project__c');
        ///getQuoteData testclass
        PageReference pageRef = Page.MantriquotationVF;
        //Test.setCurrentPage(pageRef);
        
        pageRef.getParameters().put('Id', String.valueOf(qc.Id));
        ApexPages.StandardController sc = new ApexPages.StandardController(qc);
        //getQuoteData testp = new getQuoteData(sc);
        
        
   

    }
    private class RestMock implements HttpCalloutMock {
 
        public HTTPResponse respond(HTTPRequest req) {
            String fullJson = 'your Json Response';
 
            HTTPResponse res = new HTTPResponse();
            res.setHeader('Content-Type', 'text/json');
            res.setBody(fullJson);
            res.setStatusCode(200);
            return res;
        }
     }
}