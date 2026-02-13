/****************************************************************
* Class Name   : BookingTriggerHandler
* Company      : Fingertipplus
* Created Date : 05-02-2026
* @description : Trigger handler for Booking__c object.
*                Handles:
*                - Payment Schedule mapping from Quote to Booking
*                - WhatsApp & SMS notifications on booking creation
*                - Owner assignment custom notification on update
* @author      : Durga Prasad
*
* Change Log:
* -----------------------------------------------------------------------------
* Ver | Author        | Date        | Description
* -----------------------------------------------------------------------------
* 1.0 | Durga Prasad  | 05-02-2026  | Initial version
* -----------------------------------------------------------------------------
*****************************************************************/
public class BookingTriggerHandler {
    /**
     * Method Name  : afterInsert
     * Description  : Executes after Booking__c records are inserted.
     *
     * Functionality:
     * 1. Maps related Payment_Schedule__c records from Quote__c → Booking__c.
     * 2. Updates all payment schedules linked to the Quote with the newly
     *    created Booking Id.
     * 3. Triggers WhatsApp and SMS notifications if the custom label
     *    'Enable_whatsapp_notifications' is set to TRUE.
     *
     * Process Flow:
     * - Collect Quote Ids from new Booking records.
     * - Fetch all Payment_Schedule__c linked to those Quotes.
     * - Update Booking__c lookup on Payment_Schedule__c.
     * - Enqueue WhatsAppController and SMSHandler queueable jobs.
     *
     *
     * Parameters:
     * @param newBookingList - List of newly inserted Booking__c records
    */
    public static void afterInsert(list<Booking__c> newBookingList){
        for(Booking__c bk: newBookingList)
        {
            // Step 1: Map Quote Id → Booking Id
            Map<Id, Id> quoteToBookingMap = new Map<Id, Id>();
            for (Booking__c booking : newBookingList) {
                if (booking.Quote__c != null) {
                    quoteToBookingMap.put(booking.Quote__c, booking.Id);
                }
            }
            
            if (!quoteToBookingMap.isEmpty()) {
                // Step 2: Fetch all Payment Schedules for these quotes
                List<Payment_Schedule__c> schedulesToUpdate = [
                    SELECT Id, Quote__c, Booking__c, S_No__c, Status__c
                    FROM Payment_Schedule__c
                    WHERE Quote__c IN :quoteToBookingMap.keySet()
                ];
                
                // Step 3: Assign Booking Id and mark first schedule as Completed
                for (Payment_Schedule__c schedule : schedulesToUpdate) {
                    schedule.Booking__c = quoteToBookingMap.get(schedule.Quote__c);
                }
                
                // Step 4: Update all in one go
                if (!schedulesToUpdate.isEmpty()) {
                    update schedulesToUpdate;
                }
            }
            
            if(label.Enable_whatsapp_notifications == 'TRUE'){
                
                List<Booking__c> books = [select Id,Name,S__c,First_Applicant_Name__c,Mobile__c,Plot__c,Plot__r.Name,Plot__r.Super_Built_up_Area__c,
                                          Plot__r.BHK_Type__c,Project1__c,Project1__r.Name from Booking__c where Id IN :trigger.new];
                
                WhatsappController wactrl = new WhatsappController(books,'6');
                System.enqueueJob(wactrl);
                SMSHandler smsctrl = new SMSHandler(books,'6');
                System.enqueueJob(smsctrl);
            }
        }
    }
    
    /**
     * Method Name  : beforeUpdate
     * Description  : Executes before Booking__c records are updated to enforce
     *                business rules during approval stage transition.
     *
     * Functionality:
     * 1. Detects when Sub_Stages__c is changed to 'Management User Approved'.
     * 2. Validates that an Initial CRM Executive (CRM_Executive__c) is populated.
     * 3. If CRM Executive is available:
     *      - Transfers Booking ownership to the CRM Executive.
     * 4. If CRM Executive is NOT available:
     *      - Blocks the update with a validation error message.
     *
     * Business Rule:
     * - A booking cannot move to 'Management User Approved' stage
     *   without assigning an Initial Booking CRM Executive.
     *
     *
     * Parameters:
     * @param newBookingList - List of Booking__c records being updated
     * @param oldBookingMap  - Map of old Booking__c records by Id
     *
     * Used From:
     * - Booking Trigger (before update context)
     */
    public static void beforeUpdate(List<Booking__c> newBookingList,Map<Id, Booking__c> oldBookingMap)
    {
        for (Booking__c bk : newBookingList)
        {
            Booking__c oldBk = oldBookingMap.get(bk.Id);
            
            /* Case 1: Sub Stage changed to Management User Approved */
            if (oldBk.Sub_Stages__c != bk.Sub_Stages__c && bk.Sub_Stages__c == 'Management User Approved') 
            {
                if (bk.CRM_executive__c != null) {
                    bk.OwnerId = bk.CRM_executive__c;
                    bk.Booking_Moved_To_Booked_Stage_Time__c = system.today();
                    bk.Stage_Status__c = 'In Progress';
                    bk.Move_to_Next_Stage__c = false;
                }
                else
                {
                    bk.addError('Please specify the Initial Booking CRM Executive in the booking to proceed with Approval');
                }
            }
        }
    }
    
    /**
     * Method Name  : afterUpdate
     * Description  : Executes after Booking__c records are updated.
     *
     * Functionality:
     * 1. Detects change in OwnerId of Booking.
     * 2. Sends a Custom Notification to the newly assigned owner.
     *
     * Notification Contains:
     * - Booking Name
     * - Stage
     * - Customer Name
     * - Action message for next steps
     *
     * Parameters:
     * @param newBookingList - List of updated Booking__c records
     * @param oldBookingMap  - Map of old Booking__c records by Id
    */
    public static void afterUpdate(List<Booking__c> newBookingList, Map<Id, Booking__c> oldBookingMap) {
        // ===== 1. SEND OWNER ASSIGNMENT NOTIFICATION =====
        String notificationTypeId = getNotificationTypeId();
        Map<Id, Id> bookingToOwnerMap = new Map<Id, Id>();
        for (Booking__c bk : newBookingList) {
            Booking__c oldBk = oldBookingMap.get(bk.Id);
            if (oldBk.OwnerId != bk.OwnerId && bk.OwnerId != null) {
                bookingToOwnerMap.put(bk.Id, bk.OwnerId);
                String title = bk.Lead_Name__c + ' booking has been assigned to you';
                
                String body = 'Booking: ' + bk.Name + '\n'
                    + 'Stage: ' + bk.Stage__c + '\n'
                    + 'Customer Name: ' + bk.Lead_Name__c + '\n'
                    + 'Please proceed with the next steps.';
                
                CustomNotificationService.notificationSend(
                    title,
                    bk.Id,
                    body,
                    new Set<String>{bk.OwnerId},
                    notificationTypeId
                );
            }
        }
        syncChildOwner(bookingToOwnerMap);
    }
    /**
    * Method Name  : syncChildOwner
    * Description  : Generic method to update owner of related child objects
    *                based on Booking owner change.
    *
    * Supported Objects:
    * - Payment_Schedule__c
    * - Co_Applicant__c
    *
    * Parameters:
    * @param bookingToOwnerMap - Map<BookingId, NewOwnerId>
    */
    public static void syncChildOwner(Map<Id, Id> bookingToOwnerMap) {
        
        if (bookingToOwnerMap.isEmpty()) {
            return;
        }
        //1.Co-Applicants - Master Detail
        //2.Receipt - Master Detail
        //3.Demand Raised - Master Detail
        //4.Payment Schdule - Lookup
        //5.Refund - Lookup
        //6.Inspections - lookup
        
        // ===== 1. Update Payment Schedules =====
        List<Payment_Schedule__c> psList = [
            SELECT Id, OwnerId, Booking__c
            FROM Payment_Schedule__c
            WHERE Booking__c IN :bookingToOwnerMap.keySet()
        ];
        
        for (Payment_Schedule__c ps : psList) {
            ps.OwnerId = bookingToOwnerMap.get(ps.Booking__c);
        }
        
        // ===== 2. Update RefundList =====
        List<Refund__c> refundList = [
            SELECT Id, OwnerId, Booking__c
            FROM Refund__c
            WHERE Booking__c IN :bookingToOwnerMap.keySet()
        ];
        
        for (Refund__c ps : refundList) {
            ps.OwnerId = bookingToOwnerMap.get(ps.Booking__c);
        }
        
           
        // ===== 2. Update Inspections =====
        List<Inspection__c> inspectionList = [
            SELECT Id, OwnerId, Booking__c
            FROM Inspection__c
            WHERE Booking__c IN :bookingToOwnerMap.keySet()
        ];
        
        for (Inspection__c ps : inspectionList) {
            ps.OwnerId = bookingToOwnerMap.get(ps.Booking__c);
        }
        
    

        
        // ===== 3. DML =====
        if (!psList.isEmpty()) {
            update psList;
        }

        if (!refundList.isEmpty()) {
            update refundList;
        }

        if (!inspectionList.isEmpty()) {
            update inspectionList;
        }
        
    }
    
    
    
    
    /**
     * Method Name  : getNotificationTypeId
     * Description  : Fetches Custom Notification Type Id for
     *                Booking Assignment Notification.
     *
     * Returns:
     * @return String - CustomNotificationType Id
    */
    private static String getNotificationTypeId() {
        
        CustomNotificationType nt = [
            SELECT Id
            FROM CustomNotificationType
            WHERE DeveloperName = 'Booking_Assignment_Notification'
            LIMIT 1
        ];
        
        return nt.Id;
    }
    
}