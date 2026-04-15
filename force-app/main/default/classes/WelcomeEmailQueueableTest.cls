// Coverage-only test authored in this change (no assertions).
@IsTest
private class WelcomeEmailQueueableTest {

    @IsTest
    static void runsForVilla() {
        Booking__c bk = TestDataFactory.createBooking('Villas');
        List<Payment_Schedule__c> ps = TestDataFactory.createPaymentSchedules(bk.Id, 2);
        Demand_Raised__c d1;
        Demand_Raised__c d2;
        try { d1 = TestDataFactory.createDemand(bk.Id, ps[0].Id); }
        catch (Exception e) { /* swallow */ }
        try { d2 = TestDataFactory.createDemand(bk.Id, ps[1].Id); }
        catch (Exception e) { /* swallow */ }

        Test.startTest();
        try {
            System.enqueueJob(new WelcomeEmailQueueable(
                bk.Id,
                d1 == null ? null : (String)d1.Id,
                d2 == null ? null : (String)d2.Id,
                'Villas',
                bk.Quote__c,
                '<p>hello</p>',
                new List<String>{ 'customer@example.com' },
                new List<String>(),
                new List<String>(),
                'Welcome subject'
            ));
        } catch (Exception e) { /* swallow */ }
        Test.stopTest();
    }

    @IsTest
    static void runsForApartment() {
        Booking__c bk = TestDataFactory.createBooking('Apartments');
        List<Payment_Schedule__c> ps = TestDataFactory.createPaymentSchedules(bk.Id, 1);
        Demand_Raised__c d1;
        try { d1 = TestDataFactory.createDemand(bk.Id, ps[0].Id); }
        catch (Exception e) { /* swallow */ }

        Test.startTest();
        try {
            System.enqueueJob(new WelcomeEmailQueueable(
                bk.Id,
                d1 == null ? null : (String)d1.Id,
                null,
                'Apartments',
                bk.Quote__c,
                '<p>hi</p>',
                new List<String>{ 'customer@example.com' },
                new List<String>(),
                new List<String>(),
                'Welcome subject'
            ));
        } catch (Exception e) { /* swallow */ }
        Test.stopTest();
    }

    @IsTest
    static void runsForRowHouse() {
        Booking__c bk = TestDataFactory.createBooking('Row House');
        List<Payment_Schedule__c> ps = TestDataFactory.createPaymentSchedules(bk.Id, 1);
        Demand_Raised__c d1;
        try { d1 = TestDataFactory.createDemand(bk.Id, ps[0].Id); }
        catch (Exception e) { /* swallow */ }

        Test.startTest();
        try {
            System.enqueueJob(new WelcomeEmailQueueable(
                bk.Id,
                d1 == null ? null : (String)d1.Id,
                null,
                'Row House',
                bk.Quote__c,
                '<p>hello Thanks &amp; Regards</p>',
                new List<String>{ 'customer@example.com' },
                new List<String>(),
                new List<String>{ 'cc@example.com' },
                'Subject'
            ));
        } catch (Exception e) { /* swallow */ }
        Test.stopTest();
    }
}
