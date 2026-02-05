/****************************************************************
* Class Name   : ReceiptTriggerHandler
* Company      : Fingertipplus
* Created Date : 04-02-2026
* @description : This handler class contains all business logic
*                executed from Receipt__c trigger such as:
*                - Sending receipt email and document generation
*                - Moving Booking stage to Agreement
*                - Syncing approval status to line items
*                - Handling interest calculation on payment schedule
* @author      : Durga Prasad
*
* Change Log:
* ----------------------------------------------------------------
* Ver | Author        | Date        | Description
* ----------------------------------------------------------------
* 1.0 | Durga Prasad | 04-02-2026  | Initial version
* ----------------------------------------------------------------
*****************************************************************/
public class ReceiptTriggerHandler {
    /**
     * Method Name  : afterInsert
     * Description  : Executes business logic after Receipt__c record insert.
     *
     * Functionality:
     * 1. Sends receipt email and generates receipt document using
     *    DocumentandEmailController.
     * 2. Collects inserted Receipt Ids.
     * 3. Calls moveStageToAgreement to validate booking stage movement.
     * 4. Calls approvedReceiptsHandler to process payment schedule
     *    and interest calculation.
     *
     * Parameters:
     * @param newReceiptList - List of newly inserted Receipt__c records
     *
     * Used From:
     * - Receipt__c Trigger (after insert)
    */
    public static void afterInsert(List<Receipt__c> newReceiptList) {
        Set<Id> receiptIds = new Set<Id>();
        for(Receipt__c rcp : newReceiptList)
        {
            DocumentandEmailController.sendEmailGenerateReceiptfromTrigger(rcp.Id);
            receiptIds.add(rcp.Id);
        }
        If(!receiptIds.isEmpty()){
            moveStageToAgreement(receiptIds);
            approvedReceiptsHandler(receiptIds);
        }
    }
    /**
     * Method Name  : afterUpdate
     * Description  : Syncs Approval Status from Receipt to related Line Items.
     *
     * Functionality:
     * 1. Compares old and new Receipt__c records.
     * 2. Identifies receipts where Approval_status__c is changed.
     * 3. Queries all related Receipt_Line_Item__c records in bulk.
     * 4. Updates Approval_Status_Picklist__c on each line item
     *    to match parent Receipt approval status.
     * 5. Performs single bulk update for better performance.
     *
     * Parameters:
     * @param newList - Updated Receipt__c records
     * @param oldMap  - Map of old Receipt__c records
     *
     * Used From:
     * - Receipt__c Trigger (after update)
     * - 04/02/2026 - this method is not use Trifecta Team infomed that for reciept approval not required
     */
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
    /**
     * Method Name  : moveStageToAgreement
     * Description  : Moves Booking stage to "Agreement" based on
     *                total received amount condition.
     *
     * Functionality:
     * 1. Fetches Booking__c records related to provided receipt Ids.
     * 2. Validates that Welcome_Email_Sent_to_Customer__c = true.
     * 3. Calculates total received amount from all receipts
     *    grouped by Booking__c.
     * 4. Compares total received amount with
     *    Agreement_Execution_Amount1__c on Booking.
     * 5. If received amount ≥ agreement amount,
     *    Stage__c is updated to 'Agreement'.
     *
     * Parameters:
     * @param bookingIds - Set of Booking__c record Ids
     *
     * Used From:
     * - afterInsert method of ReceiptTriggerHandler
     */    
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
        List<Booking__c> bookingsToUpdate = new List<Booking__c>();
        for (Booking__c booking : eligibleBookings) {
            Decimal totalReceived = bookingIdToTotal.get(booking.Id);
            system.debug('totalReceived'+ totalReceived+' Agreement_Execution_Amount1__c'+ booking.Agreement_Execution_Amount1__c);
            if (totalReceived != null && totalReceived >= booking.Agreement_Execution_Amount1__c.setScale(0)) {
                bookingsToUpdate.add(booking);
                bookingsById.put(booking.Id, booking);
            }
        }
        
        if (!bookingsToUpdate.isEmpty()) {
            for (Booking__c booking : bookingsToUpdate) {
                booking.Stage__c = 'Agreement';
            }
            
            if (!bookingsToUpdate.isEmpty()) {
                update bookingsToUpdate;
            }
        }
        
    }
    /**
     * Method Name  : approvedReceiptsHandler
     * Description  : Handles payment schedule update and
     *                interest calculation after receipt approval.
     *
     * Functionality:
     * 1. Fetches Receipt_Line_Item__c linked to provided receipts.
     * 2. Retrieves related Payment_schedule__c records.
     * 3. For Payment schedules with Include_Interest__c = true:
     *      - Creates Interest_Amount_Line_Item__c record
     *      - Sets interest start date from last payment date
     *        or payment due date.
     *      - Sets interest end date as today.
     * 4. Updates on Payment Schedule:
     *      - Last_Payment_Date__c
     *      - Last_Payment_Time__c
     * 5. Inserts interest line items and updates schedules in bulk.
     *
     * Parameters:
     * @param receiptIds - Set of Receipt__c record Ids
     *
     * Used From:
     * - afterInsert method of ReceiptTriggerHandler
    */ 
    public static void approvedReceiptsHandler(Set<Id> receiptIds) {
        //Query all Reciept Line items not a payment type of Interest
        list<Receipt_Line_Item__c> recLinIds = [SELECT id,Name,Receipt__r.Receipt_date__c,Booking__c,Payment_schedule__c,
                                                Received_Amount__c,Payment_schedule__r.PaymentDueDate__c,
                                                Payment_schedule__r.Last_Payment_Date__c,Payment_schedule__r.Interest_Percent__c,
                                                Payment_Type__c,Payment_schedule__r.Include_Interest__c FROM Receipt_Line_Item__c 
                                                WHERE Receipt__c IN : receiptIds and Payment_Type__c != 'Interest'];
        Map<Id,Receipt_Line_Item__c> paymentScheduleIDToReceiptLineItem = new Map<Id,Receipt_Line_Item__c>();
        
        //creating a map with Payment Schdule and Receipt Line item Aggrement - 10000 - receipt line item
        for(Receipt_Line_Item__c recl :recLinIds){
            paymentScheduleIDToReceiptLineItem.put(recl.Payment_schedule__c,recl);
        }
        
        List<Payment_schedule__c> payList1 = [SELECT id,name,Booking__c,PaymentDueDate__c,Last_Payment_Date__c,
                                              Include_Interest__c,Interest_Percent__c,Interest_Amount__c,Pending_Amount__c 
                                              FROM Payment_schedule__c
                                              WHERE id in:paymentScheduleIDToReceiptLineItem.keySet() ];
        List<Interest_Amount_Line_Item__c> IntAmtLiEs = new List<Interest_Amount_Line_Item__c>();
        
        for(Payment_schedule__c pay : payList1){
            pay.Last_Payment_Date__c = recLinIds[0].Receipt__r.Receipt_date__c;
            pay.Last_Payment_Time__c = system.now();
        }
        Date todayDate = Date.today();
        for(Receipt_Line_Item__c recipetItem : recLinIds){
            system.debug(recipetItem.Name);
            //After Due to if they paid the amount--> Recipet date is greater than payment Due date
            if (recipetItem.Payment_schedule__r.Include_Interest__c == true && recipetItem.Payment_schedule__r.PaymentDueDate__c != null
                && recipetItem.Received_Amount__c != null && recipetItem.Payment_schedule__r.Interest_Percent__c != null
                &&  recipetItem.Receipt__r.Receipt_date__c > recipetItem.Payment_schedule__r.PaymentDueDate__c &&
                recipetItem.Payment_Type__c != 'Interest') 
            {
                Interest_Amount_Line_Item__c IntLine = new Interest_Amount_Line_Item__c();
                IntLine.Interest_Amount__c = (paymentScheduleIDToReceiptLineItem.get(recipetItem.Payment_schedule__c).Received_Amount__c 
                                              * recipetItem.Payment_schedule__r.Interest_Percent__c * 
                                              (recipetItem.Payment_schedule__r.PaymentDueDate__c.daysBetween(recipetItem.Receipt__r.Receipt_date__c))
                                             ) / 36500;
                if(recipetItem.Payment_schedule__r.Last_Payment_Date__c == null){
                    IntLine.Interest_Start_Date__c = recipetItem.Payment_schedule__r.PaymentDueDate__c;
                }
                else{
                    IntLine.Interest_Start_Date__c = recipetItem.Payment_schedule__r.Last_Payment_Date__c;
                }
                IntLine.Interest_End_Date__c = system.today();
                IntLine.Interest_Percent__c = recipetItem.Payment_schedule__r.Interest_Percent__c;
                IntLine.Payment_Schedule__c = recipetItem.Payment_Schedule__c;
                IntLine.Booking__c = recipetItem.Booking__c;
                IntLine.Principal_Amount__c = recipetItem.Received_Amount__c;
                IntAmtLiEs.add(IntLine);
            }
        }
        
        if(IntAmtLiEs.size()>0){
            insert IntAmtLiEs;
        }
        
        update payList1;
    }
}