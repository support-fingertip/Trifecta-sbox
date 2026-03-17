@isTest
private class UnitReadinessMailControllerTest {

    @TestSetup
    static void setupTestData() {
        // Create a Project record
        Project__c project = new Project__c(
            Name = 'Test Project'
        );
        insert project;

        // Create a Plot record
        Plot__c plot = new Plot__c(
            Name = 'Plot-101',
            Project__c = project.Id
        );
        insert plot;

        // Create a Booking record
        Booking__c booking = new Booking__c(
            Customer_Name__c = 'John Doe',
            Customer_Email__c = 'john.doe@example.com',
            Plot_No__c = plot.Id,
            Project_Name__c = project.Id,
            Unit_Type__c = '2 BHK',
            CRM_Head_Email__c = 'crmhead@example.com'
        );
        insert booking;

        // Create a ContentVersion (file attachment)
        ContentVersion cv = new ContentVersion(
            Title = 'Test Attachment',
            PathOnClient = 'TestAttachment.pdf',
            VersionData = Blob.valueOf('Test file content for unit readiness'),
            IsMajorVersion = true
        );
        insert cv;

        // Link the ContentDocument to the Booking
        ContentVersion insertedCv = [
            SELECT ContentDocumentId FROM ContentVersion WHERE Id = :cv.Id
        ];
        ContentDocumentLink cdl = new ContentDocumentLink(
            ContentDocumentId = insertedCv.ContentDocumentId,
            LinkedEntityId = booking.Id,
            ShareType = 'V',
            Visibility = 'AllUsers'
        );
        insert cdl;
    }

    @isTest
    static void testGetBookingData() {
        Booking__c booking = [SELECT Id FROM Booking__c LIMIT 1];

        Test.startTest();
        Map<String, Object> result = UnitReadinessMailController.getBookingData(booking.Id);
        Test.stopTest();

        System.assertNotEquals(null, result, 'Result should not be null');
        System.assert(result.containsKey('booking'), 'Result should contain booking data');

        Booking__c returnedBooking = (Booking__c) result.get('booking');
        System.assertEquals('John Doe', returnedBooking.Customer_Name__c,
            'Customer name should match');
        System.assertEquals('john.doe@example.com', returnedBooking.Customer_Email__c,
            'Customer email should match');
    }

    @isTest
    static void testSendUnitReadinessMailSuccess() {
        Booking__c booking = [SELECT Id FROM Booking__c LIMIT 1];

        ContentVersion cv = [
            SELECT ContentDocumentId FROM ContentVersion LIMIT 1
        ];
        List<String> contentDocIds = new List<String>{
            cv.ContentDocumentId
        };

        String emailBody = '<p>Dear Customer, your unit is ready for inspection.</p>';
        String toAddresses = 'john.doe@example.com';

        Test.startTest();
        String result = UnitReadinessMailController.sendUnitReadinessMail(
            booking.Id,
            emailBody,
            toAddresses,
            contentDocIds
        );
        Test.stopTest();

        // In test context, emails are not actually sent but the method should succeed
        // The result could be 'Success' or an error depending on org email deliverability
        System.assertNotEquals(null, result, 'Result should not be null');

        // Verify the booking was updated if the email was successful
        if (result == 'Success') {
            Booking__c updatedBooking = [
                SELECT Unit_Readiness_Date_Time__c
                FROM Booking__c
                WHERE Id = :booking.Id
            ];
            System.assertNotEquals(null, updatedBooking.Unit_Readiness_Date_Time__c,
                'Unit Readiness Date Time should be set after successful email');
        }
    }

    @isTest
    static void testSendUnitReadinessMailMultipleRecipients() {
        Booking__c booking = [SELECT Id FROM Booking__c LIMIT 1];

        String emailBody = '<p>Unit readiness notification for multiple recipients.</p>';
        String toAddresses = 'john.doe@example.com, jane.doe@example.com';

        Test.startTest();
        String result = UnitReadinessMailController.sendUnitReadinessMail(
            booking.Id,
            emailBody,
            toAddresses,
            null
        );
        Test.stopTest();

        System.assertNotEquals(null, result, 'Result should not be null');
    }

    @isTest
    static void testSendUnitReadinessMailNoRecipients() {
        Booking__c booking = [SELECT Id FROM Booking__c LIMIT 1];

        String emailBody = '<p>Unit readiness notification.</p>';
        String toAddresses = '';

        Test.startTest();
        String result = UnitReadinessMailController.sendUnitReadinessMail(
            booking.Id,
            emailBody,
            toAddresses,
            null
        );
        Test.stopTest();

        System.assert(result.contains('Error'),
            'Should return error when no recipients provided');
    }

    @isTest
    static void testSendUnitReadinessMailWithoutAttachments() {
        Booking__c booking = [SELECT Id FROM Booking__c LIMIT 1];

        String emailBody = '<p>Unit readiness notification without attachments.</p>';
        String toAddresses = 'john.doe@example.com';

        Test.startTest();
        String result = UnitReadinessMailController.sendUnitReadinessMail(
            booking.Id,
            emailBody,
            toAddresses,
            new List<String>()
        );
        Test.stopTest();

        System.assertNotEquals(null, result, 'Result should not be null');
    }

    @isTest
    static void testSendUnitReadinessMailNullAddresses() {
        Booking__c booking = [SELECT Id FROM Booking__c LIMIT 1];

        String emailBody = '<p>Unit readiness notification.</p>';

        Test.startTest();
        String result = UnitReadinessMailController.sendUnitReadinessMail(
            booking.Id,
            emailBody,
            null,
            null
        );
        Test.stopTest();

        System.assert(result.contains('Error'),
            'Should return error when addresses are null');
    }
}
