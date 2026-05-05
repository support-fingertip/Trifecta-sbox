public class MarkBookingStageCompletedController {

    @AuraEnabled
    public static void markStageAsCompleted(String bookingId, String newNote) {
        try {
            Booking__c bookingRec = [
                SELECT Id, Name, Booking_Summary__c, CRM_Manager__c,
                Lead_Name__c, Stage__c, Stage_Status__c, Move_to_Next_Stage__c,
                Project_Type__c, Block__c, OwnerId, Owner_Full_Name__c,
                Block__r.Name,
                Block__r.Agreement_CRM_Executive__c,
                Block__r.Demands_Collections_CRM_Executive__c,
                Block__r.Registration_CRM_Executive__c,
                Block__r.Possession_Handover_CRM_Executive__c,
                Block__r.Customer_Service_CRM_Executive__c
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

            String currentStage = bookingRec.Stage__c;
            bookingRec.Stage_Status__c = 'Completed';
            bookingRec.Move_to_Next_Stage__c = true;

            // Resolve next stage + new owner from Stage_Progression__mdt + Block__c lookups
            Stage_Progression__mdt progression = getStageProgression(
                bookingRec.Project_Type__c, currentStage
            );

            if (progression != null) {
                if (bookingRec.Block__c == null) {
                    throw new AuraHandledException(
                        'Cannot advance stage: Booking is not linked to a Block.'
                    );
                }

                Id nextOwnerId = (Id) bookingRec.Block__r.get(
                    progression.Block_Executive_Field_API__c
                );

                if (nextOwnerId == null) {
                    throw new AuraHandledException(
                        'Cannot advance stage: ' +
                        progression.Block_Executive_Field_API__c +
                        ' is not set on Block ' + bookingRec.Block__r.Name + '.'
                    );
                }

                bookingRec.Stage__c = progression.Next_Stage__c;
                bookingRec.OwnerId = nextOwnerId;
                bookingRec.Stage_Status__c = 'In Progress';
                bookingRec.Move_to_Next_Stage__c = false;
            }

            update bookingRec;

            // Send Notification
            if (bookingRec.CRM_Manager__c != null) {
                String title = bookingRec.Lead_Name__c + ' – Stage \'' + currentStage + '\' marked as completed by ' + bookingRec.Owner_Full_Name__c;
                String body =
                    'Booking: ' + bookingRec.Name + '\n' +
                    'Stage: ' + (currentStage != null ? currentStage : '') + '\n' +
                    'Customer Name: ' + (bookingRec.Lead_Name__c != null ? bookingRec.Lead_Name__c : '') + '\n' +
                    'Current CRM Executive: ' +
                    (bookingRec.Owner_Full_Name__c != null ? bookingRec.Owner_Full_Name__c : '') + '\n' +
                    'Please proceed with the next steps.';

                CustomNotificationService.notificationSend( title, bookingRec.Id,body,new Set<String>{ bookingRec.CRM_Manager__c }, getNotificationTypeId());
            }
        }
        catch(AuraHandledException e) {
            throw e;
        }
        catch(Exception e) {
            throw new AuraHandledException('Error updating booking: ' + e.getMessage());
        }

    }

    /**
    * Looks up the Stage_Progression__mdt row for the given project type and
    * current stage. Returns null when no progression is configured (terminal
    * stage), in which case the caller leaves Stage__c / OwnerId untouched.
    */
    private static Stage_Progression__mdt getStageProgression(
        String projectType, String currentStage
    ) {
        if (String.isBlank(projectType) || String.isBlank(currentStage)) {
            return null;
        }

        List<Stage_Progression__mdt> rows = [
            SELECT Project_Type__c, Current_Stage__c, Next_Stage__c,
                   Block_Executive_Field_API__c
            FROM Stage_Progression__mdt
            WHERE Project_Type__c = :projectType
              AND Current_Stage__c = :currentStage
            LIMIT 1
        ];

        return rows.isEmpty() ? null : rows[0];
    }

    /**
    * Method Name  : getNotificationTypeId
    * Description  : Fetches Custom Notification Type Id for
    *                Booking Assignment Notification.
    *
    * Returns:
    * @return String - CustomNotificationType Id
    */
    public static String getNotificationTypeId() {

        CustomNotificationType nt = [
            SELECT Id
            FROM CustomNotificationType
            WHERE DeveloperName = 'Booking_Assignment_Notification'
            LIMIT 1
        ];

        return nt.Id;
    }
}
