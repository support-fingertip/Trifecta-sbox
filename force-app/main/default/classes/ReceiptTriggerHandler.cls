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
        set<Id> receiptsIds = new set<Id>();
        for(Receipt__c rcp : newReceiptList)
        {
            DocumentandEmailController.sendEmailGenerateReceiptfromTrigger(rcp.Id);
            receiptsIds.add(rcp.Id);
        }
        if(label.Enable_whatsapp_notifications == 'TRUE'){
            List<Receipt__c> receipts = [select Id,Booking__r.First_Applicant_Name__c,Booking__r.Mobile__c,Amount_Received__c,
                                         Booking__r.Unit_No__c,Project_Block_Name__c,Booking__r.CRM_Executive_Contact_No__c
                                         from Receipt__c where Id IN :receiptsIds];
            WhatsappController wactrl = new WhatsappController(receipts,'7');
            System.enqueueJob(wactrl);
        }
   
    }

}