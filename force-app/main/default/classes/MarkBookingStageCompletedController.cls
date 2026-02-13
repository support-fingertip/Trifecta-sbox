public class MarkBookingStageCompletedController {

    @AuraEnabled
    public static void markStageAsCompleted(String bookingId, String newNote) {

        Booking__c bookingRec = [
            SELECT Id, Name, Booking_Summary__c, CRM_Manager__c,
                   Lead_Name__c, Stage__c, Owner_Full_Name__c
            FROM Booking__c
            WHERE Id = :bookingId
            LIMIT 1
        ];

        User currentUser = [
            SELECT Id, Name
            FROM User
            WHERE Id = :UserInfo.getUserId()
            LIMIT 1
        ];

        Datetime dt = Datetime.now();
        String strTimeInAMorPM = dt.format('dd-MM-yy HH:mm a');

        Integer noteCount = 1;

        if (String.isBlank(bookingRec.Booking_Summary__c)) {
            bookingRec.Booking_Summary__c = '';
        } else {
            List<String> notes = bookingRec.Booking_Summary__c.split('\n');
            noteCount = notes.size() + 1;
        }

        bookingRec.Booking_Summary__c +=
            '\nStage Summary ' + noteCount + ': ' +
            currentUser.Name + ' [' + strTimeInAMorPM + ']: ' + newNote;

        bookingRec.Stage_Status__c = 'Completed';
        bookingRec.Move_to_Next_Stage__c = true;

        update bookingRec;

        // Send Notification
        if (bookingRec.CRM_Manager__c != null) {

            
            String title =
                bookingRec.Lead_Name__c +
                ' – Stage \'' + bookingRec.Stage__c + '\' marked as completed by ' +
                bookingRec.Owner_Full_Name__c;


            String body =
                'Booking: ' + bookingRec.Name + '\n' +
                'Stage: ' + (bookingRec.Stage__c != null ? bookingRec.Stage__c : '') + '\n' +
                'Customer Name: ' + (bookingRec.Lead_Name__c != null ? bookingRec.Lead_Name__c : '') + '\n' +
                'Current CRM Executive: ' +
                (bookingRec.Owner_Full_Name__c != null ? bookingRec.Owner_Full_Name__c : '') + '\n' +
                'Please proceed with the next steps.';

            CustomNotificationService.notificationSend(
                title,
                bookingRec.Id,
                body,
                new Set<String>{ bookingRec.CRM_Manager__c },
                getNotificationTypeId()
            );
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