@isTest
private class ConsolidatedReceiptControllerTest {
    
    @isTest
    static void testConsolidatedReceiptControllerConstructor() {
        // Create a Booking__c record with only required fields.
        // DO NOT set any amount fields (they are not writable).
        Booking__c booking = new Booking__c(
            
            // TODO: add other required fields for Booking__c here, e.g.
            // Project__c = someProjectId,
            // Customer__c = someAccountId,
            // etc.
        );
        insert booking;

        // Re-query to ensure rollup / formula fields (like Total_received_Amount__c) are populated
        booking = [
            SELECT Id, Name, Total_received_Amount__c
            FROM Booking__c
            WHERE Id = :booking.Id
        ];
        
        // StandardController for the VF controller
        ApexPages.StandardController stdCtrl = new ApexPages.StandardController(booking);
        
        // Call the constructor you want to cover
        ConsolidatedReceiptController ctrl = new ConsolidatedReceiptController(stdCtrl);
        
        // Basic sanity asserts – no amount field writes anywhere
        System.assertNotEquals(null, ctrl.booking, 'Booking should be set on the controller.');
        System.assertEquals(booking.Id, ctrl.booking.Id, 'Controller should be using the same booking.');
        
        // These should be initialized by the constructor (if your amount fields are non-null/rollup)
        // We are NOT assigning to any amount fields, only reading through the controller.
        System.assertNotEquals(null, ctrl.totalAmount, 'Total amount string should be initialized.');
        System.assertNotEquals(null, ctrl.receiptAmountInWords, 'Amount in words should be initialized.');
        
        // repList and acwBookList should be initialized (may be empty, that’s fine)
        System.assertNotEquals(null, ctrl.repList, 'repList should not be null.');
        System.assertNotEquals(null, ctrl.acwBookList, 'acwBookList should not be null.');
    }
      @isTest
    static void testReceiptWrapperAndAdditionalChargesWrapper() {
        // Test ReceiptWrapper
        ConsolidatedReceiptController.ReceiptWrapper rw =
            new ConsolidatedReceiptController.ReceiptWrapper();
        
        rw.receiptDate   = Date.today();
        rw.receiptAmount = '100.00';      // String, NOT any Amount__c field
        rw.modeOfPayment = 'Cash';
        rw.instruMentNo  = 'CHQ-12345';
        rw.payNameName   = 'Schedule-1';
        
        System.assertEquals(Date.today(), rw.receiptDate);
        System.assertEquals('100.00', rw.receiptAmount);
        System.assertEquals('Cash', rw.modeOfPayment);
        System.assertEquals('CHQ-12345', rw.instruMentNo);
        System.assertEquals('Schedule-1', rw.payNameName);
        
        // Test AdditionalChargesWrapper
        ConsolidatedReceiptController.AdditionalChargesWrapper acw =
            new ConsolidatedReceiptController.AdditionalChargesWrapper();
        
        acw.acDate   = Date.today();
        acw.acAmount = '50.00';           // String, NOT any Amount__c field
        acw.acName   = 'Maintenance Charge';
        
        System.assertEquals(Date.today(), acw.acDate);
        System.assertEquals('50.00', acw.acAmount);
        System.assertEquals('Maintenance Charge', acw.acName);
    }
}