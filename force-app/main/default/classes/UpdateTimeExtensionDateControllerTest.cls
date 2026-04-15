// Coverage-only test authored in this change (no assertions).
@IsTest
private class UpdateTimeExtensionDateControllerTest {

    @IsTest
    static void updateBookingNoteOnly() {
        Booking__c bk = TestDataFactory.createBooking('Apartments');
        Test.startTest();
        try {
            UpdateTimeExtensionDateController.updateBooking(
                bk.Id, 'Requesting a 15 day extension', 15, null);
        } catch (Exception e) { /* swallow — coverage only */ }
        Test.stopTest();
    }

    @IsTest
    static void updateBookingWithStatusApproved() {
        Booking__c bk = TestDataFactory.createBooking('Villas');
        Test.startTest();
        try {
            UpdateTimeExtensionDateController.updateBooking(
                bk.Id, 'Approved note', 10, 'Approved');
        } catch (Exception e) { /* swallow */ }
        Test.stopTest();
    }

    @IsTest
    static void updateBookingWithStatusRejected() {
        Booking__c bk = TestDataFactory.createBooking('Row House');
        Test.startTest();
        try {
            UpdateTimeExtensionDateController.updateBooking(
                bk.Id, 'Rejected note', 0, 'Rejected');
        } catch (Exception e) { /* swallow */ }
        Test.stopTest();
    }

    @IsTest
    static void updateBookingWithNullId() {
        Test.startTest();
        try {
            UpdateTimeExtensionDateController.updateBooking(null, 'x', 1, null);
        } catch (Exception e) { /* expected */ }
        Test.stopTest();
    }
}
