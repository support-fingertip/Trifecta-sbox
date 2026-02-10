public without sharing class ReceiptController {
    public class dataBox{
        @AuraEnabled
        public List<Receipt_Line_Item__c> rcList;
        @AuraEnabled
        public Decimal grandTotal;
        @AuraEnabled
        public List<Payment_schedule__c> pysch{get;set;}
        @AuraEnabled
        public List<Additional_Charges__c> additionalCharges{get;set;}
        @AuraEnabled
        public List<Payment_schedule__c> paymentSchdules {get;set;}
        @AuraEnabled
        public List<string> paymentTypePicklist {get;set;}
        @AuraEnabled
        public Decimal tdsAmount;
        @AuraEnabled
        public Decimal flatOrVillaPendingAmount;
        @AuraEnabled
        public Booking__c bookingRecord; 
        @AuraEnabled
        public decimal iterestAmount;
    } 
    
    @AuraEnabled
    public static dataBox getData(string recId){
        dataBox dt = new dataBox();
        dt.additionalCharges = [select id,name,Pending_Amount__c
                                from Additional_Charges__c where Booking__c =: recid and Pending_Amount__c> 0];
        dt.paymentSchdules = [SELECT Id,Name,Payment_percent__c,
                              Payment_Due_Date__c,Recived_Per__c,Amount1__c,S_No__c,
                              status__c,Booking__c,Quote__c FROM Payment_schedule__c
                              WHERE Booking__c =:recid ORDER BY S_No__c ASC];
        dt.paymentTypePicklist = getPicklistValues('Receipt_Line_Item__c','Mode_of_Payment__c');
        
        Booking__c bk =[select Id,Name,Project__c,TOTAL__c,Unit_Number__c,Total_Tds_Amount__c,
                        Pending_Amount__c,Total_Amount__c,Project_Type__c from Booking__c where Id=: recId];
        dt.bookingRecord = bk; 
        
        
        Decimal TotaltdsAmount = bk.Total_Tds_Amount__c;
        TotaltdsAmount = TotaltdsAmount.setScale(2, RoundingMode.HALF_UP);
        List<Receipt_Line_Item__c> rcptitmlst =  [SELECT Id,Name,Receipt__c,Payment_schedule__c,
                                                  Received_Amount__c,Receipt__r.Booking__c,Booking__c,
                                                  Drawn_On__c,Branch__c,Amount__c FROM Receipt_Line_Item__c 
                                                  where  Booking__c =:recid AND Payment_Type__c = 'TDS'];
        Decimal paidTdsAmount = 0;
        for (Receipt_Line_Item__c item : rcptitmlst) {
            paidTdsAmount += item.Received_Amount__c != null ? item.Received_Amount__c : 0;
        }
        
        //As Per Trifecta Client - TDS Amount not required - 17/11/2025 
        Decimal finalTdsamount = TotaltdsAmount - paidTdsAmount;
        finalTdsamount = finalTdsamount.setScale(2, RoundingMode.HALF_UP);
        dt.tdsAmount = finalTdsamount;
        dt.flatOrVillaPendingAmount = bk.Pending_Amount__c - finalTdsamount; 
        
        //Getting Interestamount
        Decimal iterestAmount = 0;
        List<Payment_Schedule__c> payList = [select id,name,Interest_Up_To_Date__c from Payment_schedule__c where Booking__c =: recId];
        for(Payment_Schedule__c pay : payList){
            iterestAmount += pay.Interest_Up_to_Date__c != null ? pay.Interest_Up_to_Date__c : 0 ;
        }
        dt.iterestAmount = iterestAmount;
        return dt;
    }
    public static List<String> getPicklistValues(String objectName, String fieldName) {
        List<String> picklistValueList = new List<String>();
        
        // Get the describe info for the object
        Schema.SObjectType objType = Schema.getGlobalDescribe().get(objectName);
        if (objType == null) {
            return picklistValueList; // Return empty list if object not found
        }
        
        // Get field describe info
        Schema.DescribeSObjectResult objDescribe = objType.getDescribe();
        Map<String, Schema.SObjectField> fieldMap = objDescribe.fields.getMap();
        
        if (!fieldMap.containsKey(fieldName)) {
            return picklistValueList; // Return empty list if field not found
        }
        
        Schema.DescribeFieldResult fieldResult = fieldMap.get(fieldName).getDescribe();
        
        // Extract picklist values
        for (Schema.PicklistEntry picklistEntry : fieldResult.getPicklistValues()) {
            picklistValueList.add(picklistEntry.getLabel());
        }
        
        return picklistValueList;
    }
    @AuraEnabled
    public static Id insertReceiptLineItems(List<Receipt_Line_Item__c> polist,string remark,string poc, string recid, Decimal paidAmount, Decimal interestAmount)
    {
        Booking__c bk = [SELECT Id, Name,Finance_Lead__c, Project__c FROM Booking__c WHERE Id = :recid LIMIT 1];
        Receipt__c rc = new Receipt__c();
        rc.Remarks__c = remark;
        rc.Receipt_date__c = Date.valueOf(poc);
        rc.Booking__c = recid;
        rc.Finance_User__c = bk.Finance_Lead__c;
        //Status Auto Approved
        rc.Approval_status__c = 'Approved';
        insert rc;
        List<Payment_Schedule__c> payList = [SELECT Id, Amount1__c,Is_Demanded__c,Interest_Pending_Amount__c,
                                             Villa_Flat_Amount_Pending__c, Pending_Amount__c,
                                             S_No__c FROM Payment_Schedule__c WHERE Pending_Amount__c > 0 
                                             and Booking__c = :bk.Id ORDER BY S_No__c ASC];
        //Debug 
        system.debug('Receipt Record'+rc);
        system.debug('Payment Scdule'+payList);
        system.debug('Receipt Item from Js'+polist);
        
        Set<Id> payIds = new Set<Id>();
        Map<Id,Decimal> paymentScheduleToPendingAmount = new Map<Id,Decimal>();
        for(Payment_Schedule__c pay : payList){
            paymentScheduleToPendingAmount.put(pay.Id,pay.Pending_Amount__c);
        }
        
        // -------------------------------
        // Main Amount Calculation
        // -------------------------------
        Map<Integer, Receipt_Line_Item__c> receiptLineItemMap = new Map<Integer, Receipt_Line_Item__c>();
        for (Integer i = 0; i < polist.size(); i++) {
            if(polist[i].Payment_Type__c != 'Additional Charges' &&
               (polist[i].Payment_Type__c == 'Flat Amount' || polist[i].Payment_Type__c == 'Villa Amount' || 
                polist[i].Payment_Type__c == 'Plot Amount' || polist[i].Payment_Type__c == 'TDS' ||
                polist[i].Payment_Type__c == 'Row House Amount'
               ))
            {
                receiptLineItemMap.put(i + 1, polist[i]);
            }
        }
        List<Receipt_Line_Item__c> receiptsToCreate = new List<Receipt_Line_Item__c>();
        for(Payment_Schedule__c payIt : payList){
            if(paymentScheduleToPendingAmount.get(payIt.Id) > 0){
                for(Integer inte : receiptLineItemMap.keySet()){
                    if(receiptLineItemMap.get(inte).Received_Amount__c > 0 && paymentScheduleToPendingAmount.get(payIt.Id) > 0){
                        Decimal amountToReceive = Math.min(paymentScheduleToPendingAmount.get(payIt.Id), 
                                                           receiptLineItemMap.get(inte).Received_Amount__c);
                        Receipt_Line_Item__c rece = new Receipt_Line_Item__c();
                        rece.Booking__c = bk.Id;
                        rece.Name = receiptLineItemMap.get(inte).Payment_Type__c;
                        rece.Receipt__c = rc.Id;
                        rece.Payment_Schedule__c = payIt.Id;
                        rece.Received_Amount__c = amountToReceive;
                        rece.Amount__c = amountToReceive;
                        rece.Bank_Name__c = receiptLineItemMap.get(inte).Bank_Name__c;
                        rece.Branch__c = receiptLineItemMap.get(inte).Branch__c;
                        rece.Drawn_On__c = receiptLineItemMap.get(inte).Drawn_On__c;
                        rece.Payment_Type__c = receiptLineItemMap.get(inte).Payment_Type__c;
                        rece.Mode_of_Payment__c = receiptLineItemMap.get(inte).Mode_of_Payment__c;
                        rece.Cheque_Date__c = receiptLineItemMap.get(inte).Cheque_Date__c;
                        rece.Cheque_no_Transaction_Number__c = receiptLineItemMap.get(inte).Cheque_no_Transaction_Number__c;
                        //Auto Approved
                        rece.Approval_Status_Picklist__c = 'Approved';
                        receiptsToCreate.add(rece);
                        system.debug(rece);
                        paymentScheduleToPendingAmount.put(payIt.Id, paymentScheduleToPendingAmount.get(payIt.Id) - amountToReceive);
                        
                        Receipt_Line_Item__c updatedReceiptLineItem = receiptLineItemMap.get(inte);
                        updatedReceiptLineItem.Received_Amount__c -= amountToReceive;
                        receiptLineItemMap.put(inte, updatedReceiptLineItem);
                    }
                }
            }
        }
        
        
        //--------------------------------
        // Additional Amount 
        // -------------------------------
        
   		// ------------------------------
   		// Interest Amount Calculation
   		// -----------------------------
        for(Payment_Schedule__c paymentSchedule : payList){
            if (interestAmount <= 0 || interestAmount == null) {
                break;
            }
            if( (interestAmount != 0 || interestAmount != null) &&  paymentSchedule.Interest_Pending_Amount__c != null
               && paymentSchedule.Interest_Pending_Amount__c > 0 )
            {
               
                Decimal amountToReceive = Math.min(paymentSchedule.Interest_Pending_Amount__c, interestAmount);
                interestAmount -= amountToReceive;
                Receipt_Line_Item__c rece = new Receipt_Line_Item__c();
                rece.Booking__c = bk.Id;
                rece.Name = 'Against Interest';
                rece.Payment_Type__c = 'Interest';
                rece.Receipt__c = rc.Id;
                rece.Payment_Schedule__c = paymentSchedule.Id;
                rece.Received_Amount__c = amountToReceive;
                rece.Amount__c = amountToReceive;
                rece.Bank_Name__c = polist[0].Bank_Name__c;
                rece.Mode_of_Payment__c =  polist[0].Mode_of_Payment__c;
                rece.Branch__c =polist[0].Branch__c;
                rece.Cheque_no_Transaction_Number__c = polist[0].Cheque_no_Transaction_Number__c;
                rece.Cheque_Date__c = polist[0].Cheque_Date__c;
                rece.Drawn_On__c = polist[0].Drawn_On__c;
                //Auto Approved
                rece.Approval_Status_Picklist__c = 'Approved';
                if(amountToReceive > 0){
                    receiptsToCreate.add(rece);
                }
            }
        }
        
        // After allocating interest against each Payment Schedule’s Interest_Pending__c,
        // there can be a scenario where the user entered Interest Amount is MORE than
        // the actual pending interest available in all schedules.
        //
        // Example:
        // User entered Interest Paid  = 10,000
        // Total Interest Pending      = 8,000
        // ------------------------------------
        // Excess interest             = 2,000
        //
        // This remaining 2,000 cannot be mapped to Interest bucket,
        // so it will be adjusted against the last available Payment Schedule
        // as a normal payment line item to ensure total received amount is not lost.
        if(interestAmount !=null && interestAmount !=0) {
            system.debug('Interest');
            Integer PaymentScheduleSize = payList.size();
            Receipt_Line_Item__c rece = new Receipt_Line_Item__c();
            rece.Booking__c = bk.Id;
            rece.Name = 'Against Interest';
            rece.Payment_Type__c = 'Interest';
            rece.Receipt__c = rc.Id;
            rece.Payment_Schedule__c = payList[PaymentScheduleSize-1].Id;
            rece.Received_Amount__c = interestAmount;
            rece.Amount__c = interestAmount;
            rece.Bank_Name__c = polist[0].Bank_Name__c;
            rece.Mode_of_Payment__c =  polist[0].Mode_of_Payment__c;
            rece.Branch__c =polist[0].Branch__c;
            rece.Cheque_no_Transaction_Number__c = polist[0].Cheque_no_Transaction_Number__c;
            rece.Cheque_Date__c = polist[0].Cheque_Date__c;
            rece.Drawn_On__c = polist[0].Drawn_On__c;
            rece.Approval_Status_Picklist__c = 'Approved';
            receiptsToCreate.add(rece);
        }
        
        
        // Insert all Receipt Line Items
        if (!receiptsToCreate.isEmpty()) {
            insert receiptsToCreate;
        }
        

        
        return rc.Id;
    }
}