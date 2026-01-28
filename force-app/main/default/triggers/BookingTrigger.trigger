trigger BookingTrigger on Booking__c (after insert) {
    if (Trigger.isAfter && Trigger.isInsert) {
        // Step 1: Map Quote Id → Booking Id
        Map<Id, Id> quoteToBookingMap = new Map<Id, Id>();
        for (Booking__c booking : Trigger.new) {
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