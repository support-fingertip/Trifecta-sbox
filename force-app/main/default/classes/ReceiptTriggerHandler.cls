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
     *
     * Parameters:
     * @param newReceiptList - List of newly inserted Receipt__c records
     *
     * Used From:
     * - Receipt__c Trigger (after insert)
    */
    public static void afterInsert(List<Receipt__c> newReceiptList) {
        for(Receipt__c rcp : newReceiptList)
        {
            DocumentandEmailController.sendEmailGenerateReceiptfromTrigger(rcp.Id);
        }
    }

}