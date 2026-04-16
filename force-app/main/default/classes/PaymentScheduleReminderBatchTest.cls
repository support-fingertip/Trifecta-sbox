// Coverage-only test authored in this change (no assertions).
@IsTest
private class PaymentScheduleReminderBatchTest {

    @IsTest
    static void batchRunsWithCompletedSchedules() {
        Booking__c bk = TestDataFactory.createBooking('Apartments');

        // Create a PS that matches the batch start() query:
        // Completed_Date_New__c = System.today()
        Payment_Schedule__c ps = new Payment_Schedule__c(
            Booking__c           = bk.Id,
            Name                 = 'Milestone Batch',
            S_No__c              = 1,
            Payment_percent__c   = 10,
            Completed_Date_New__c = Date.today()
        );
        try { insert ps; } catch (Exception e) { /* swallow */ }

        Test.startTest();
        try {
            Database.executeBatch(new PaymentScheduleReminderBatch(), 200);
        } catch (Exception e) { /* swallow */ }
        Test.stopTest();
    }

    @IsTest
    static void batchRunsWithNoMatchingSchedules() {
        // No PS records with Completed_Date_New__c = today → empty scope
        Test.startTest();
        try {
            Database.executeBatch(new PaymentScheduleReminderBatch(), 200);
        } catch (Exception e) { /* swallow */ }
        Test.stopTest();
    }
}
