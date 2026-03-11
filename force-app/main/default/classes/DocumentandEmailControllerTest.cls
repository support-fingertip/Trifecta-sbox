@isTest
private class DocumentandEmailControllerTest {
    
    @isTest
    static void testGetBookingDetails_BasicFields() {
        // Create test user for Owner
        Profile p = [SELECT Id FROM Profile WHERE Name = 'Standard User' LIMIT 1];
        User testUser = new User(
            FirstName = 'Test',
            LastName = 'User',
            Email = 'testuser@example.com',
            Username = 'testuser' + DateTime.now().getTime() + '@example.com',
            Alias = 'tuser',
            ProfileId = p.Id,
            TimeZoneSidKey = 'Asia/Kolkata',
            LocaleSidKey = 'en_US',
            EmailEncodingKey = 'UTF-8',
            LanguageLocaleKey = 'en_US'
        );
        insert testUser;
        
        // Create related Project and Plot
        Project__c proj = new Project__c(Name = 'Test Project');
        insert proj;
        
        Plot__c plot = new Plot__c(Name = 'Plot-01', Project__c = proj.Id, Status__c = 'Available');
        insert plot;
        
        // Create Booking__c record
        Booking__c booking = new Booking__c(
            First_Applicant_Name__c = 'Alice',
            S__c = 'Ms.',
            Email__c = 'alice@example.com',
            PAN_Number__c = 'ABCDE1234F',
            Plot__c = plot.Id,
            Project1__c = proj.Id,
            Funding_Type__c = 'Self',
            
            Agreement_Execution_Amount1__c = 95000,
            OwnerId = testUser.Id
        );
        insert booking;
        
        // Call the method
        Test.startTest();
        DocumentandEmailController.BookingDataWrapper result = DocumentandEmailController.getBookingDetails(booking.Id);
        Test.stopTest();
        
        // Assert results
        System.assertNotEquals(null, result);
        System.assertEquals('Ms. Alice', result.customerNames);
        System.assertEquals(booking.Id, result.booking.Id);
    }
    
    @isTest
    static void testSendEmailGenerateReceipt_noBookingEmail() {
        try {
            // Create Booking without email
            Booking__c booking = new Booking__c(
                First_Applicant_Name__c = 'John Doe'
            );
            insert booking;
            
            Receipt__c receipt = new Receipt__c(
                Booking__c = booking.Id
            );
            insert receipt;
            
            Test.startTest();
            String result = DocumentandEmailController.sendEmailGenerateReceipt(receipt.Id);
            Test.stopTest();
            
            System.assertEquals('Email address not specified in the Booking record.', result);
        } catch (Exception e) {
            System.assert(e.getMessage().contains('List has no rows'), 'Expected query exception due to missing Booking fields');
        }
    }
    
    
    @isTest
    static void testSendEmailGenerateReceipt_invalidReceipt() {
        Test.startTest();
        String result = DocumentandEmailController.sendEmailGenerateReceipt(null); // Replace with your actual class name
        Test.stopTest();
        
        System.assert(result.startsWith('Error sending email'), 'Expected error message.');
    }
}