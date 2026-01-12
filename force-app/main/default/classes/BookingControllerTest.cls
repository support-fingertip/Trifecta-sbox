@isTest
public class BookingControllerTest {

    @isTest
    public static void testBookingControllerMethods() {

        
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
Test.setMock(HttpCalloutMock.class, new RestMock());
       
        Test.startTest();

        List<String> payTypes = BookingController.getPaymentTypePicklistValues();
        List<String> fundTypes = BookingController.getFundingtTypePicklistValues();

      
        Quote__c qResult = BookingController.quoteRecord(qc.Id);
       
        Blob testBlob = Blob.valueOf('Test File Content');
        String base64File = EncodingUtil.base64Encode(testBlob);

        Id docId = BookingController.saveFile(
            qc.Id,
            'Sample.pdf',
            base64File,
            'application/pdf',
            'BookingDoc'
        );

        System.assertNotEquals(null, docId, 'ContentDocument should have been created');

    
        Map<Id, String> unitStatusMap = new Map<Id, String>();
        unitStatusMap.put(ut.Id, 'Booked');

        BookingController.changeUnitStatus(unitStatusMap);

        Plot__c updatedPlot = [SELECT Status__c FROM Plot__c WHERE Id = :ut.Id];
        System.assertEquals('Booked', updatedPlot.Status__c);

  
        BookingController.chnageUnitStatus(new List<Booking__c>{ book });

        Plot__c updatedPlot2 = [SELECT Status__c FROM Plot__c WHERE Id = :ut.Id];
        

       
        Booking__c newBook = new Booking__c(
            Funding_Type__c = 'Loan'
        );

        List<Co_Applicant__c> caList = new List<Co_Applicant__c>{
            new Co_Applicant__c(Name = 'Test User')
        };

        String bId = BookingController.convertQuote(qc.Id, newBook, caList);
        

        Test.stopTest();
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