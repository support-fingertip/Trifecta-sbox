/**
* Trigger : ReceiptTrigger
* Handler : ReceiptTriggerHandler
* Purpose : Delegates all business logic to handler class
*           to maintain trigger best practices.
* @author      : Durga Prasad
*
* Change Log:
* ----------------------------------------------------------------
* Ver | Author        | Date        | Description
* ----------------------------------------------------------------
* 1.0 | Durga Prasad | 04-02-2026  | Initial version
* ----------------------------------------------------------------
*/
trigger ReceiptTrigger on Receipt__c (after insert) {
    if(trigger.isInsert)
    {
        if(trigger.isAfter)
        {
            ReceiptTriggerHandler.afterInsert(trigger.new);      
        }
    }

}