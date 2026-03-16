public class TicketTriggerHandler {

    public static void handleAfterUpdate(
        List<Ticket__c> newList,
        Map<Id, Ticket__c> oldMap
    ) {
        // Collect ticket IDs where status just changed to Completed
        // and closure email has NOT been sent yet
        List<Id> ticketIdsToEmail = new List<Id>();

        for (Ticket__c ticket : newList) {
            Ticket__c oldTicket = oldMap.get(ticket.Id);

            Boolean statusChangedToCompleted =
                ticket.Status__c == 'Completed'
                && oldTicket.Status__c != 'Completed';

            Boolean emailNotYetSent =
                ticket.Closure_Email_Sent__c == false
                || ticket.Closure_Email_Sent__c == null;

            if (statusChangedToCompleted && emailNotYetSent) {
                ticketIdsToEmail.add(ticket.Id);
            }
        }

        if (!ticketIdsToEmail.isEmpty()) {
            //TicketClosureEmailService.sendClosureEmails(ticketIdsToEmail);
        }
    }
}