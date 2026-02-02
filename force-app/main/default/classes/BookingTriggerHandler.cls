public class BookingTriggerHandler {
    public static void afterInsert(list<Booking__c> newBookingList)
    {
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
    public static void beforeUpdate( List<Booking__c> newBookingList,Map<Id, Booking__c> oldBookingMap)
    {
        for (Booking__c bk : newBookingList)
        {
            Booking__c oldBk = oldBookingMap.get(bk.Id);
            
            /* Case 1: Sub Stage changed to Management User Approved */
            if (oldBk.Sub_Stages__c != bk.Sub_Stages__c && bk.Sub_Stages__c == 'Management User Approved') 
            {
                if (bk.New_Booking_CRM_Executive__c != null) {
                    bk.OwnerId = bk.New_Booking_CRM_Executive__c;
                }
                else
                {
                    bk.addError('Please specify the New Booking CRM Executive in the booking to proceed');
                }
            }
            
            /* Case 2: Stage changed */
            if (oldBk.Stage__c != bk.Stage__c) {
                
                /* Agreement */
                if (bk.Stage__c == 'Agreement') {
                    if (bk.Agreement_CRM_Executive__c != null) {
                        bk.OwnerId = bk.Agreement_CRM_Executive__c;
                    } else {
                        bk.addError('Please specify the Agreement Booking CRM Executive in the booking to proceed');
                    }
                }
                
                /* Demands & Progressive Collections */
                else if (bk.Stage__c == 'Demands & Progressive Collections') {
                    if (bk.Demands_Collections_CRM_Executive__c != null) {
                        bk.OwnerId = bk.Demands_Collections_CRM_Executive__c;
                    } else {
                         bk.addError('Please specify the Demands & Collections Booking CRM Executive in the booking to proceed');
                    }
                }
                
                /* Registration */
                else if (bk.Stage__c == 'Registration') {
                    if (bk.Registration_CRM_Executive__c != null) {
                        bk.OwnerId = bk.Registration_CRM_Executive__c;
                    } else {
                       bk.addError('Please specify the Registration Booking CRM Executive in the booking to proceed');
                    }
                }
                
                /* Possession_Handover_CRM_Executive__c */
                else if (bk.Stage__c == 'Possession / Handover') {
                    if (bk.Possession_Handover_CRM_Executive__c != null) {
                        bk.OwnerId = bk.Possession_Handover_CRM_Executive__c;
                    } else {
                        bk.addError('Please specify the Possession / Handover Booking CRM Executive in the booking to proceed');
                    }
                }
                
                /* Customer_Service_CRM_Executive__c */
                else if (bk.Stage__c == 'Customer Service & Complaints') {
                    if (bk.Customer_Service_CRM_Executive__c != null) {
                        bk.OwnerId = bk.Customer_Service_CRM_Executive__c;
                    } else {
                        bk.addError('Please specify the Customer Service Booking CRM Executive in the booking to proceed');
                    }
                }
                /* Customer_Service_CRM_Executive__c */
                else if (bk.Stage__c == 'Cancellation') {
                    if (bk.Cancellation_CRM_Executive__c != null) {
                        bk.OwnerId = bk.Cancellation_CRM_Executive__c;
                    } else {
                       bk.addError('Please specify the Cancellation Booking CRM Executive in the booking to proceed');
                    }
                }
            }
        }
    }
    
    public static void afterUpdate(list<Booking__c> newBookingList,map<Id,Booking__c> oldBookingMap)
    {
        Map<Id,set<Id>> bookingWithUserId = new Map<Id,set<Id>>();
        for(Booking__c bk : newBookingList)
        {
            Booking__c oldBk =  oldBookingMap.get(bk.Id);
            if(oldBk.OwnerId != bk.OwnerId)
            {
                set<Id> userIds = new set<Id>();
                if(bk.New_Booking_CRM_Executive__c != null)
                {
                    userIds.add(bk.New_Booking_CRM_Executive__c);
                }
                if(bk.Agreement_CRM_Executive__c != null)
                {
                    userIds.add(bk.Agreement_CRM_Executive__c);
                }
                if(bk.Demands_Collections_CRM_Executive__c != null)
                {
                    userIds.add(bk.Demands_Collections_CRM_Executive__c);
                }
                if(bk.Registration_CRM_Executive__c != null)
                {
                    userIds.add(bk.Registration_CRM_Executive__c);
                 }
                if(bk.Possession_Handover_CRM_Executive__c != null)
                {
                    userIds.add(bk.Possession_Handover_CRM_Executive__c);
                }
                if(bk.Customer_Service_CRM_Executive__c != null)
                {
                    userIds.add(bk.Customer_Service_CRM_Executive__c);
                }
                if(bk.Cancellation_CRM_Executive__c != null)
                {
                    userIds.add(bk.Cancellation_CRM_Executive__c);
                }
                bookingWithUserId.put(bk.Id,userIds);
            }
        }
        
        //share the Quote Acess to users which mentioned
        List<Booking__Share> bookingShares = new List<Booking__Share>();
        Map<Id, Booking__c> newBookingMap = new Map<Id, Booking__c>(newBookingList);
        
        for (Id bookingId : bookingWithUserId.keySet()) {
            Booking__c bk = newBookingMap.get(bookingId);
            
            for (Id userId : bookingWithUserId.get(bookingId)) {
                
                if (userId == bk.OwnerId) {
                    continue;
                }
                
                Booking__Share bs = new Booking__Share();
                bs.ParentId = bookingId;
                bs.UserOrGroupId = userId;
                bs.AccessLevel = 'Edit';
                bs.RowCause = Schema.Booking__Share.RowCause.Manual;
                
                bookingShares.add(bs);
            }
        }

        if (!bookingShares.isEmpty()) {
            insert bookingShares;
        }

    }
}