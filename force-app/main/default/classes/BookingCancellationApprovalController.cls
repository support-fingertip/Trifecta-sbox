public class BookingCancellationApprovalController {
    @AuraEnabled
    public static boolean sendCancellationApproval(Id recId, string cancellationReason, String cancellationRemarks, Decimal cancellationCharges){
        List<Booking__c> bklist = [Select Id, Name, Cancellation_Charge__c,Cancellation_Reason__c, Cancellation_Description__c From Booking__c Where id =: recId];
        // Get Cancellation Amount from Custom Label
        Decimal cancellationAmount = 0;
        
        if(String.isNotBlank(Label.Cancellation_Amount)){
            cancellationAmount = Decimal.valueOf(
                Label.Cancellation_Amount.replace(',', '')
            );
        }
        
        for(Booking__c bk : bklist)
        {
            bk.Cancellation_Reason__c = cancellationReason;
            bk.Cancellation_Description__c = cancellationRemarks;
            bk.Cancellation_Charge__c = cancellationCharges;
            bk.Is_Cancelled__c = true;
            if(cancellationCharges > cancellationAmount) {
                bk.Cancellation_Status__c = 'Approved';
                bk.Stage__c = 'Cancellation';
            }
        }
        Update bklist;
        

        // Send for approval if cancellationCharges is less than defined Cancellation Amount
        if(cancellationCharges < cancellationAmount) {
            Approval.ProcessSubmitRequest req1 = new Approval.ProcessSubmitRequest();
            req1.setComments('Cancellation request');
            req1.setObjectId(recId);
            req1.setSubmitterId(userInfo.getUserId());
            req1.setProcessDefinitionNameOrId('Cancellation_Approval_For_Booking_heads');
            req1.setSkipEntryCriteria(true);
            Approval.ProcessResult result = Approval.process(req1);
        }
        return true;
    }
    
}