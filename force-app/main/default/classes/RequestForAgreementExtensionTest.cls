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

  
}