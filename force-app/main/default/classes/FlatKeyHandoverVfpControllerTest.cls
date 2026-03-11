@isTest
public class FlatKeyHandoverVfpControllerTest {

    @isTest
    public static void testControllerWithBooking() {
        Booking__c bk = new Booking__c(
            First_Applicant_Name__c = 'Test Customer',
            Unit_Number__c = 'A-101'
        );
        insert bk;

        PageReference pref = Page.FlatKeyHandoverVfp;
        Test.setCurrentPage(pref);
        pref.getParameters().put('Id', bk.Id);

        ApexPages.StandardController sc = new ApexPages.StandardController(bk);
        FlatKeyHandoverVfpController ctrl = new FlatKeyHandoverVfpController(sc);

        System.assertNotEquals(null, ctrl.booking, 'Booking should not be null');
        System.assertEquals('Test Customer', ctrl.booking.First_Applicant_Name__c);
        System.assertEquals('A-101', ctrl.booking.Unit_Number__c);
        System.assertNotEquals(null, ctrl.handoverByName);
    }

    @isTest
    public static void testControllerWithNullId() {
        Booking__c bk = new Booking__c();

        ApexPages.StandardController sc = new ApexPages.StandardController(bk);
        FlatKeyHandoverVfpController ctrl = new FlatKeyHandoverVfpController(sc);

        System.assertNotEquals(null, ctrl.booking, 'Booking should not be null even with no Id');
    }
}
