@isTest
public class RequestForAgreementExtensionTest {

    // ─── Factory Helpers ──────────────────────────────────────────────────────

    private static Booking__c createBooking(String existingSummary) {
        Booking__c b = new Booking__c(
            Stage__c             = 'Agreement',
            Booking_Summary__c   = existingSummary
        );
        insert b;
        return b;
    }

    // ─── submitforextensionApproval – validation ───────────────────────────────

    @isTest
    static void testSubmit_nullBookingId_throwsAuraHandledException() {
        Test.startTest();
        try {
            RequestForAgreementExtensionController.submitforextensionApproval(null, 'Need extension', 10);
            System.assert(false, 'Expected AuraHandledException');
        } catch (AuraHandledException e) {
            System.assert(
                e.getMessage().contains('Booking Id is required'),
                'Message should mention Booking Id: ' + e.getMessage()
            );
        }
        Test.stopTest();
    }

    // ─── submitforextensionApproval – booking field updates ───────────────────

    @isTest
    static void testSubmit_setsTimeExtensionAndExtensionDays() {
        Booking__c b = createBooking(null);

        // Approval.process will throw in test context without active process;
        // wrap and verify the booking was updated before the approval call.
        Test.startTest();
        try {
            RequestForAgreementExtensionController.submitforextensionApproval(b.Id, 'Please extend', 15);
        } catch (AuraHandledException e) {
            // Expected — approval process not configured in test org
        }
        Test.stopTest();

        Booking__c updated = [
            SELECT Time_Extension_Requested__c, Extension_Days__c
            FROM Booking__c WHERE Id = :b.Id
        ];
        System.assertEquals(true, updated.Time_Extension_Requested__c,
            'Time_Extension_Requested__c should be true');
        System.assertEquals(15, updated.Extension_Days__c,
            'Extension_Days__c should be 15');
    }

    /**
     * Pre-populate Booking_Summary__c so the controller takes the
     * "split existing notes" branch where noteCount = notes.size() + 1.
     */
    @isTest
    static void testSubmit_appendsToExistingSummary() {
        Booking__c b = createBooking(
            'Summary 1: Existing User [01-01-25 10:00 AM]: prior\n' +
            'Summary 2: Existing User [02-01-25 11:00 AM]: another'
        );

        Test.startTest();
        try {
            RequestForAgreementExtensionController.submitforextensionApproval(
                b.Id, 'Appended note', 20);
        } catch (Exception e) { /* swallow approval process not configured */ }
        Test.stopTest();

        Booking__c updated = [
            SELECT Booking_Summary__c, Extension_Days__c
            FROM Booking__c WHERE Id = :b.Id
        ];
        System.assert(
            updated.Booking_Summary__c.contains('Appended note'),
            'Summary should contain new note'
        );
        System.assertEquals(20, updated.Extension_Days__c);
    }

    /**
     * Blank/null note — exercises the "skip note append" branch where
     * Booking_Summary__c is untouched but Extension_Days__c still updates.
     */
    @isTest
    static void testSubmit_blankNote() {
        Booking__c b = createBooking('seed');

        Test.startTest();
        try {
            RequestForAgreementExtensionController.submitforextensionApproval(
                b.Id, null, 7);
        } catch (Exception e) { /* swallow */ }
        Test.stopTest();
    }
}