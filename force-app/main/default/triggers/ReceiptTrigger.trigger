trigger ReceiptTrigger on Receipt__c (after insert) {
    if(trigger.isInsert)
    {
        if(trigger.isAfter)
        {
            ReceiptTriggerHandler.afterInsert(trigger.new);      
        }
    }

}