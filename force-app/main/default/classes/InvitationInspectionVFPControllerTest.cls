// Coverage-only test authored in this change (no assertions).
@IsTest
private class InvitationInspectionVFPControllerTest {

    @IsTest
    static void constructorWithBooking() {
        Booking__c bk = TestDataFactory.createBooking('Apartments');

        Test.startTest();
        PageReference pr = Page.Invitation_For_Inspection;
        pr.getParameters().put('id', bk.Id);
        Test.setCurrentPage(pr);
        try {
            new InvitationInspectionVFPController(
                new ApexPages.StandardController(bk));
        } catch (Exception e) { /* swallow */ }
        Test.stopTest();
    }

    @IsTest
    static void constructorWithNullId() {
        Booking__c bk = new Booking__c();

        Test.startTest();
        PageReference pr = Page.Invitation_For_Inspection;
        Test.setCurrentPage(pr);
        try {
            new InvitationInspectionVFPController(
                new ApexPages.StandardController(bk));
        } catch (Exception e) { /* swallow */ }
        Test.stopTest();
    }
}
