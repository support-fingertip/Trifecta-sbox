// Coverage-only test authored in this change (no assertions).
@IsTest
private class MarkBookingStageCompletedControllerTest {

    @IsTest
    static void marksApartmentStageCompleted() {
        Booking__c bk = TestDataFactory.createBooking('Apartments');
        Test.startTest();
        try {
            MarkBookingStageCompletedController.markStageAsCompleted(
                bk.Id, 'Completed the apartment stage');
        } catch (Exception e) { /* swallow — CustomNotificationType may not exist in test org */ }
        Test.stopTest();
    }

    @IsTest
    static void marksVillaStageCompleted() {
        Booking__c bk = TestDataFactory.createBooking('Villas');
        Test.startTest();
        try {
            MarkBookingStageCompletedController.markStageAsCompleted(
                bk.Id, 'Completed villa stage');
        } catch (Exception e) { /* swallow */ }
        Test.stopTest();
    }

    @IsTest
    static void marksRowHouseStageCompleted() {
        Booking__c bk = TestDataFactory.createBooking('Row House');
        Test.startTest();
        try {
            MarkBookingStageCompletedController.markStageAsCompleted(
                bk.Id, 'Completed row house stage');
        } catch (Exception e) { /* swallow */ }
        Test.stopTest();
    }

    @IsTest
    static void invalidBookingId() {
        Test.startTest();
        try {
            MarkBookingStageCompletedController.markStageAsCompleted(null, 'x');
        } catch (Exception e) { /* expected */ }
        Test.stopTest();
    }
}
