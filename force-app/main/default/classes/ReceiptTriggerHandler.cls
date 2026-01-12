public class ReceiptTriggerHandler {
        
    public static void afterInsert(List<Receipt__c> newReceiptList) {
        Set<Id> receiptIds = new Set<Id>();
        for(Receipt__c rcp : newReceiptList)
        {
            DocumentandEmailController.sendEmailGenerateReceiptfromTrigger(rcp.Id);
            receiptIds.add(rcp.Id);
        }
        If(!receiptIds.isEmpty()){
            moveStageToAgreement(receiptIds);
        }
    }
    public static void afterUpdate(List<Receipt__c> newList, Map<Id, Receipt__c> oldMap) {

        // Collect Receipt Ids where approval status changed
        Set<Id> changedReceiptIds = new Set<Id>();
        Map<Id, String> receiptToStatus = new Map<Id, String>();

        for (Receipt__c newRec : newList) {
            Receipt__c oldRec = oldMap.get(newRec.Id);

            if (newRec.Approval_status__c != oldRec.Approval_status__c) {
                changedReceiptIds.add(newRec.Id);
                receiptToStatus.put(newRec.Id, newRec.Approval_status__c);
            }
        }

        if (changedReceiptIds.isEmpty()) {
            return;
        }

        // Query all related Receipt Line Items at once
        List<Receipt_Line_Item__c> rliList = [
            SELECT Id, Receipt__c, Approval_Status_Picklist__c
            FROM Receipt_Line_Item__c
            WHERE Receipt__c IN :changedReceiptIds
        ];

        List<Receipt_Line_Item__c> updates = new List<Receipt_Line_Item__c>();

        // Update each Line Item
        for (Receipt_Line_Item__c rli : rliList) {
            rli.Approval_Status_Picklist__c = receiptToStatus.get(rli.Receipt__c);
            updates.add(rli);
        }

        // Perform update once
        if (!updates.isEmpty()) {
            update updates;
        }
    }
        
    public static void moveStageToAgreement(Set<Id> bookingIds) {
        if (bookingIds == null || bookingIds.isEmpty()) return;
        
        List<Booking__c> eligibleBookings = [
            SELECT Id, OwnerId, Stage__c, Agreement_Execution_Amount1__c
            FROM Booking__c WHERE Id IN :bookingIds AND Welcome_Email_Sent_to_Customer__c = true
        ];
        if (eligibleBookings.isEmpty()) return;
        
        // 2. Fetch the total advance amount from approved receipts
        Map<Id, Decimal> bookingIdToTotal = new Map<Id, Decimal>();
        for (AggregateResult ar : [
            SELECT Booking__c bookingId, SUM(Total_Received_Amount__c) total
            FROM Receipt__c WHERE Booking__c IN :bookingIds GROUP BY Booking__c
        ]) {
            bookingIdToTotal.put((Id) ar.get('bookingId'), (Decimal) ar.get('total'));
        }
        
        Map<Id, Booking__c> bookingsById = new Map<Id, Booking__c>();
        Set<Id> eligibleBookingIds = new Set<Id>();
        List<Booking__c> bookingsToUpdate = new List<Booking__c>();
        for (Booking__c booking : eligibleBookings) {
            Decimal totalReceived = bookingIdToTotal.get(booking.Id);
            system.debug('totalReceived'+ totalReceived+' Agreement_Execution_Amount1__c'+ booking.Agreement_Execution_Amount1__c);
            if (totalReceived != null && totalReceived >= booking.Agreement_Execution_Amount1__c.setScale(0)) {
                bookingsToUpdate.add(booking);
                eligibleBookingIds.add(booking.Id);
                bookingsById.put(booking.Id, booking);
            }
        }
        
        if (!eligibleBookingIds.isEmpty()) {
            for (Booking__c booking : bookingsToUpdate) {
                booking.Stage__c = 'Agreement';
            }
            
            if (!bookingsToUpdate.isEmpty()) {
                update bookingsToUpdate;
            }
        }
        
    }
    
}