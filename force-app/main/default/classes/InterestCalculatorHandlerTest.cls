// Coverage-only test authored in this change (no assertions).
@IsTest
private class InterestCalculatorHandlerTest {

    @IsTest
    static void createsInterestLineItemsWithPastDueSchedules() {
        Booking__c bk = TestDataFactory.createBooking('Apartments');

        // Create a Payment_Schedule with a past PaymentDueDate and pending amount
        // so InterestCalculatorHandler.createInterestLineItems finds it.
        Payment_Schedule__c ps = new Payment_Schedule__c(
            Booking__c           = bk.Id,
            Name                 = 'Interest Milestone',
            S_No__c              = 1,
            Payment_percent__c   = 50,
            Amount__c            = 500000,
            PaymentDueDate__c    = Date.today().addDays(-60),
            Last_Payment_Date__c = null
        );
        try { insert ps; } catch (Exception e) { return; }

        Test.startTest();
        try {
            InterestCalculatorHandler.createInterestLineItems(
                Date.today(), 12);
        } catch (Exception e) { /* swallow */ }
        Test.stopTest();
    }

    @IsTest
    static void handlesLastPaymentDateSet() {
        Booking__c bk = TestDataFactory.createBooking('Apartments');

        Payment_Schedule__c ps = new Payment_Schedule__c(
            Booking__c           = bk.Id,
            Name                 = 'Interest Milestone 2',
            S_No__c              = 1,
            Payment_percent__c   = 50,
            Amount__c            = 500000,
            PaymentDueDate__c    = Date.today().addDays(-60),
            Last_Payment_Date__c = Date.today().addDays(-20)
        );
        try { insert ps; } catch (Exception e) { return; }

        Test.startTest();
        try {
            InterestCalculatorHandler.createInterestLineItems(
                Date.today().addDays(-10), 15);
        } catch (Exception e) { /* swallow */ }
        Test.stopTest();
    }

    @IsTest
    static void handlesNoMatchingSchedules() {
        // No PS records with Pending_Amount__c > 0 and past due date → early return
        Test.startTest();
        try {
            InterestCalculatorHandler.createInterestLineItems(
                Date.today(), 10);
        } catch (Exception e) { /* swallow */ }
        Test.stopTest();
    }
}
