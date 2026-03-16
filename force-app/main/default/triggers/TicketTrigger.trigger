trigger TicketTrigger on Ticket__c (after update) {
    TicketTriggerHandler.handleAfterUpdate(
        Trigger.new,
        Trigger.oldMap
    );
}