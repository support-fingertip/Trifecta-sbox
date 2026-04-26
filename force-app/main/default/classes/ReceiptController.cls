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
        public List<String> tdsStatusPicklist {get;set;}
        @AuraEnabled
        public List<Receipt_Line_Item__c> pendingTdsRefunds {get;set;}
        @AuraEnabled
        public Decimal pendingTdsRefundAmount;
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
                              Payment_Due_Date__c,Recived_Per__c,S_No__c,
                              status__c,Booking__c,Quote__c FROM Payment_schedule__c
                              WHERE Booking__c =:recid ORDER BY S_No__c ASC];
        dt.paymentTypePicklist = getPicklistValues('Receipt_Line_Item__c','Mode_of_Payment__c');
        dt.tdsStatusPicklist = getPicklistValues('Receipt_Line_Item__c', 'TDS_Status__c');
        Set<Id> refundedFromBankIds = new Set<Id>();
        Decimal refundedTotal = 0;
        Decimal bankDeductedTotal = 0;
        for (AggregateResult ar : [
            SELECT Payment_Type__c pt, SUM(Received_Amount__c) total
            FROM Receipt_Line_Item__c
            WHERE Booking__c = :recId
              AND Payment_Type__c IN ('TDS from Bank', 'TDS Refund')
            GROUP BY Payment_Type__c
        ]) {
            Decimal total = (Decimal) ar.get('total');
            if ((String) ar.get('pt') == 'TDS Refund') {
                refundedTotal = total != null ? total : 0;
            } else {
                bankDeductedTotal = total != null ? total : 0;
            }
        }
        if (bankDeductedTotal > refundedTotal) {
            dt.pendingTdsRefunds = [
                SELECT Id, Name, Received_Amount__c, Amount__c, TDS_Status__c,
                       Receipt__c, Receipt__r.Name,
                       Payment_Schedule__c, Payment_Schedule__r.Name,
                       Mode_of_Payment__c, Drawn_On__c
                FROM Receipt_Line_Item__c
                WHERE Booking__c = :recId
                  AND Payment_Type__c = 'TDS from Bank'
                ORDER BY CreatedDate DESC
            ];
        } else {
            dt.pendingTdsRefunds = new List<Receipt_Line_Item__c>();
        }
        dt.pendingTdsRefundAmount = (bankDeductedTotal > refundedTotal)
            ? (bankDeductedTotal - refundedTotal)
            : 0;

        Booking__c bk =[select Id,Name,Project__c,TOTAL__c,Unit_Number__c,Total_Tds_Amount__c,
                        Pending_Amount__c,Total_Amount__c,Project_Type__c from Booking__c where Id=: recId];
        dt.bookingRecord = bk; 
        
        
        Decimal TotaltdsAmount = bk.Total_Tds_Amount__c;
        TotaltdsAmount = TotaltdsAmount.setScale(2, RoundingMode.HALF_UP);
        List<Receipt_Line_Item__c> rcptitmlst =  [SELECT Id,Name,Receipt__c,Payment_schedule__c,
                                                  Received_Amount__c,Receipt__r.Booking__c,Booking__c,
                                                  Drawn_On__c,Branch__c,Amount__c FROM Receipt_Line_Item__c
                                                  where  Booking__c =:recid AND Payment_Type__c IN ('TDS', 'TDS Paid')];
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
    public static Id insertReceiptLineItems(List<Receipt_Line_Item__c> polist, String remark, String poc, String recid, Decimal paidAmount, Decimal interestAmount, String stagedFiles)
    {
        Booking__c bk = [SELECT Id, Name, Finance_Lead__c, Project__c, Project_Type__c 
                         FROM Booking__c WHERE Id = :recid LIMIT 1];
        
        //  FIX: Added Pending_Tds_Amount__c to the query
        List<Payment_Schedule__c> payList = [
            SELECT Id, Is_Demanded__c, Interest_Pending_Amount__c,
            Villa_Flat_Amount_Pending__c, Pending_Amount__c, Type__c,Pending_Amount_Without_Tds__c,
            S_No__c, Pending_Tds_Amount__c
            FROM Payment_Schedule__c 
            WHERE Pending_Amount__c > 0 AND Booking__c = :bk.Id 
            ORDER BY S_No__c ASC
        ];
        
        System.debug('Payment Schedule: ' + payList);
        System.debug('Receipt Items from JS: ' + polist);
        
        Map<Id, Decimal> paymentScheduleToPendingAmount = new Map<Id, Decimal>();
        Map<Id, Payment_Schedule__c> paymentScheduleMap = new Map<Id, Payment_Schedule__c>();
        for (Payment_Schedule__c pay : payList) {
            paymentScheduleToPendingAmount.put(pay.Id, pay.Pending_Amount_Without_Tds__c);
            paymentScheduleMap.put(pay.Id, pay);
        }
        
        // ===============================
        // 1. Main Amount Calculation
        //    (Flat, Villa, Plot, Booking, Row House — excludes TDS & Additional Charges)
        // ===============================
        Map<Integer, Receipt_Line_Item__c> receiptLineItemMap = new Map<Integer, Receipt_Line_Item__c>();
        for (Integer i = 0; i < polist.size(); i++) {
            String payType = polist[i].Payment_Type__c;
            //  FIX: Removed 'TDS' from this block — TDS now has its own section
            if (payType != 'Additional Charges' && payType != 'TDS' &&
                (payType == 'Flat Amount' || payType == 'Villa Amount' || 
                 payType == 'Plot Amount' || payType == 'Booking Amount' ||
                 payType == 'Row House Amount'))
            {
                receiptLineItemMap.put(i + 1, polist[i]);
            }
        }
        
        List<Receipt_Line_Item__c> receiptsToCreate = new List<Receipt_Line_Item__c>();
        
        for (Payment_Schedule__c payIt : payList) {
            if (paymentScheduleToPendingAmount.get(payIt.Id) > 0) {
                for (Integer inte : receiptLineItemMap.keySet()) {
                    if (receiptLineItemMap.get(inte).Received_Amount__c > 0 && paymentScheduleToPendingAmount.get(payIt.Id) > 0) {
                        Decimal amountToReceive = Math.min(
                            paymentScheduleToPendingAmount.get(payIt.Id), 
                            receiptLineItemMap.get(inte).Received_Amount__c
                        );
                        
                        Receipt_Line_Item__c rece = new Receipt_Line_Item__c();
                        rece.Booking__c = bk.Id;
                        rece.Name = receiptLineItemMap.get(inte).Payment_Type__c;
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
                        rece.Approval_Status_Picklist__c = 'Approved';
                        receiptsToCreate.add(rece);
                        
                        paymentScheduleToPendingAmount.put(payIt.Id, paymentScheduleToPendingAmount.get(payIt.Id) - amountToReceive);
                        
                        Receipt_Line_Item__c updatedReceiptLineItem = receiptLineItemMap.get(inte);
                        updatedReceiptLineItem.Received_Amount__c -= amountToReceive;
                        receiptLineItemMap.put(inte, updatedReceiptLineItem);
                    }
                }
            }
        }
        
        // ===============================
        // 2. TDS Branches
        //    'TDS from Bank' — bank-deducted TDS, informational; no schedule decrement
        //    'TDS Refund'    — refund of bank-deducted TDS back to customer; no decrement
        //    'TDS Paid'      — challan from customer; decrements Pending_Tds_Amount__c
        //    'TDS' (legacy)  — preserved for backward compatibility, behaves like 'TDS Paid'
        // ===============================

        Id firstScheduleWithPendingTds = null;
        for (Payment_Schedule__c ps : payList) {
            if (ps.Pending_Tds_Amount__c != null && ps.Pending_Tds_Amount__c > 0) {
                firstScheduleWithPendingTds = ps.Id;
                break;
            }
        }
        if (firstScheduleWithPendingTds == null && !payList.isEmpty()) {
            firstScheduleWithPendingTds = payList[payList.size() - 1].Id;
        }

        // (a) Informational TDS rows — no schedule decrement
        for (Integer i = 0; i < polist.size(); i++) {
            Receipt_Line_Item__c src = polist[i];
            String pt = src.Payment_Type__c;
            if (pt != 'TDS from Bank' && pt != 'TDS Refund') {
                continue;
            }
            if (src.Received_Amount__c == null || src.Received_Amount__c <= 0) {
                continue;
            }

            Receipt_Line_Item__c rece = new Receipt_Line_Item__c();
            rece.Booking__c = bk.Id;
            rece.Name = pt;
            rece.Payment_Type__c = pt;
            rece.TDS_Status__c = src.TDS_Status__c;
            rece.Payment_Schedule__c = firstScheduleWithPendingTds;
            rece.Received_Amount__c = src.Received_Amount__c;
            rece.Amount__c = src.Received_Amount__c;
            rece.Bank_Name__c = src.Bank_Name__c;
            rece.Branch__c = src.Branch__c;
            rece.Drawn_On__c = src.Drawn_On__c;
            rece.Mode_of_Payment__c = src.Mode_of_Payment__c;
            rece.Cheque_Date__c = src.Cheque_Date__c;
            rece.Cheque_no_Transaction_Number__c = src.Cheque_no_Transaction_Number__c;
            rece.Challan_Reference_Number__c = src.Challan_Reference_Number__c;
            rece.Approval_Status_Picklist__c = 'Approved';
            receiptsToCreate.add(rece);
        }

        // (b) TDS Paid (and legacy 'TDS') — decrement Pending_Tds_Amount__c
        Decimal totalTdsPaid = 0;
        Receipt_Line_Item__c tdsPaidSourceLineItem = null;
        String tdsPaidStampedType = 'TDS Paid';
        for (Integer i = 0; i < polist.size(); i++) {
            String pt = polist[i].Payment_Type__c;
            Boolean isPaidType = (pt == 'TDS Paid' || pt == 'TDS');
            if (isPaidType && polist[i].Received_Amount__c != null && polist[i].Received_Amount__c > 0) {
                totalTdsPaid += polist[i].Received_Amount__c;
                if (tdsPaidSourceLineItem == null) {
                    tdsPaidSourceLineItem = polist[i];
                    tdsPaidStampedType = pt;
                }
            }
        }

        if (totalTdsPaid > 0 && tdsPaidSourceLineItem != null) {
            Decimal remainingTds = totalTdsPaid;
            String tdsStatusToApply = String.isNotBlank(tdsPaidSourceLineItem.TDS_Status__c)
                ? tdsPaidSourceLineItem.TDS_Status__c
                : null;

            for (Payment_Schedule__c paymentSchedule : payList) {
                if (remainingTds <= 0) {
                    break;
                }
                if (paymentSchedule.Pending_Tds_Amount__c != null && paymentSchedule.Pending_Tds_Amount__c > 0) {
                    Decimal amountToReceive = Math.min(paymentSchedule.Pending_Tds_Amount__c, remainingTds);
                    remainingTds -= amountToReceive;

                    Receipt_Line_Item__c rece = new Receipt_Line_Item__c();
                    rece.Booking__c = bk.Id;
                    rece.Name = 'Against TDS';
                    rece.Payment_Type__c = tdsPaidStampedType;
                    rece.TDS_Status__c = tdsStatusToApply;
                    rece.Payment_Schedule__c = paymentSchedule.Id;
                    rece.Received_Amount__c = amountToReceive;
                    rece.Amount__c = amountToReceive;
                    rece.Bank_Name__c = tdsPaidSourceLineItem.Bank_Name__c;
                    rece.Branch__c = tdsPaidSourceLineItem.Branch__c;
                    rece.Drawn_On__c = tdsPaidSourceLineItem.Drawn_On__c;
                    rece.Mode_of_Payment__c = tdsPaidSourceLineItem.Mode_of_Payment__c;
                    rece.Cheque_Date__c = tdsPaidSourceLineItem.Cheque_Date__c;
                    rece.Cheque_no_Transaction_Number__c = tdsPaidSourceLineItem.Cheque_no_Transaction_Number__c;
                    rece.Challan_Reference_Number__c = tdsPaidSourceLineItem.Challan_Reference_Number__c;
                    rece.Approval_Status_Picklist__c = 'Approved';

                    if (amountToReceive > 0) {
                        receiptsToCreate.add(rece);
                    }
                }
            }

            // Excess TDS Paid — adjust against last Payment Schedule (interest-overflow pattern)
            if (remainingTds > 0 && !payList.isEmpty()) {
                System.debug('Excess TDS Paid Amount: ' + remainingTds);
                Receipt_Line_Item__c rece = new Receipt_Line_Item__c();
                rece.Booking__c = bk.Id;
                rece.Name = 'Against TDS';
                rece.Payment_Type__c = tdsPaidStampedType;
                rece.TDS_Status__c = tdsStatusToApply;
                rece.Payment_Schedule__c = payList[payList.size() - 1].Id;
                rece.Received_Amount__c = remainingTds;
                rece.Amount__c = remainingTds;
                rece.Bank_Name__c = tdsPaidSourceLineItem.Bank_Name__c;
                rece.Branch__c = tdsPaidSourceLineItem.Branch__c;
                rece.Drawn_On__c = tdsPaidSourceLineItem.Drawn_On__c;
                rece.Mode_of_Payment__c = tdsPaidSourceLineItem.Mode_of_Payment__c;
                rece.Cheque_Date__c = tdsPaidSourceLineItem.Cheque_Date__c;
                rece.Cheque_no_Transaction_Number__c = tdsPaidSourceLineItem.Cheque_no_Transaction_Number__c;
                rece.Challan_Reference_Number__c = tdsPaidSourceLineItem.Challan_Reference_Number__c;
                rece.Approval_Status_Picklist__c = 'Approved';
                receiptsToCreate.add(rece);
            }
        }
        
        // ===============================
        // 3. Additional Amount (placeholder for future)
        // ===============================
        
        // ===============================
        // 4. Interest Amount Calculation
        // ===============================
        for (Payment_Schedule__c paymentSchedule : payList) {
            if (interestAmount == null || interestAmount <= 0) {
                break;
            }
            if (interestAmount != 0 && interestAmount != null
                && paymentSchedule.Interest_Pending_Amount__c != null
                && paymentSchedule.Interest_Pending_Amount__c > 0)
            {
                Decimal amountToReceive = Math.min(paymentSchedule.Interest_Pending_Amount__c, interestAmount);
                interestAmount -= amountToReceive;
                
                Receipt_Line_Item__c rece = new Receipt_Line_Item__c();
                rece.Booking__c = bk.Id;
                rece.Name = 'Against Interest';
                rece.Payment_Type__c = 'Interest';
                rece.Payment_Schedule__c = paymentSchedule.Id;
                rece.Received_Amount__c = amountToReceive;
                rece.Amount__c = amountToReceive;
                rece.Bank_Name__c = polist[0].Bank_Name__c;
                rece.Mode_of_Payment__c = polist[0].Mode_of_Payment__c;
                rece.Branch__c = polist[0].Branch__c;
                rece.Cheque_no_Transaction_Number__c = polist[0].Cheque_no_Transaction_Number__c;
                rece.Cheque_Date__c = polist[0].Cheque_Date__c;
                rece.Drawn_On__c = polist[0].Drawn_On__c;
                rece.Approval_Status_Picklist__c = 'Approved';
                if (amountToReceive > 0) {
                    receiptsToCreate.add(rece);
                }
            }
        }
        
        // Handle excess Interest — adjust against last Payment Schedule
        if (interestAmount != null && interestAmount > 0) {
            System.debug('Excess Interest Amount: ' + interestAmount);
            Integer paymentScheduleSize = payList.size();
            Receipt_Line_Item__c rece = new Receipt_Line_Item__c();
            rece.Booking__c = bk.Id;
            rece.Name = 'Against Interest';
            rece.Payment_Type__c = 'Interest';
            rece.Payment_Schedule__c = payList[paymentScheduleSize - 1].Id;
            rece.Received_Amount__c = interestAmount;
            rece.Amount__c = interestAmount;
            rece.Bank_Name__c = polist[0].Bank_Name__c;
            rece.Mode_of_Payment__c = polist[0].Mode_of_Payment__c;
            rece.Branch__c = polist[0].Branch__c;
            rece.Cheque_no_Transaction_Number__c = polist[0].Cheque_no_Transaction_Number__c;
            rece.Cheque_Date__c = polist[0].Cheque_Date__c;
            rece.Drawn_On__c = polist[0].Drawn_On__c;
            rece.Approval_Status_Picklist__c = 'Approved';
            receiptsToCreate.add(rece);
        }
        
        // =======================================
        // 5. SPLIT RECEIPTS BASED ON TYPE (VILLAS)
        // =======================================
        Map<String, List<Receipt_Line_Item__c>> typeToLinesMap = new Map<String, List<Receipt_Line_Item__c>>();
        
        for (Receipt_Line_Item__c line : receiptsToCreate) {
            String typeKey = paymentScheduleMap.get(line.Payment_Schedule__c).Type__c;
            
            if (String.isBlank(typeKey)) {
                typeKey = 'COMMON';
            }
            
            if (!typeToLinesMap.containsKey(typeKey)) {
                typeToLinesMap.put(typeKey, new List<Receipt_Line_Item__c>());
            }
            
            typeToLinesMap.get(typeKey).add(line);
        }
        
        List<Receipt__c> receiptsToInsert = new List<Receipt__c>();
        Map<String, Receipt__c> typeToReceiptMap = new Map<String, Receipt__c>();
        
        Set<String> tdsExcludedTypes = new Set<String>{
            'TDS', 'TDS from Bank', 'TDS Refund', 'TDS Paid'
        };
        if (bk.Project_Type__c == 'Villas') {
            for (String typeKey : typeToLinesMap.keySet()) {
                Decimal amountReceived = 0;
                for (Receipt_Line_Item__c line : typeToLinesMap.get(typeKey)) {
                    if (!tdsExcludedTypes.contains(line.Payment_Type__c)) {
                        amountReceived += line.Received_Amount__c != null ? line.Received_Amount__c : 0;
                    }
                }


                Receipt__c receipt = new Receipt__c();
                receipt.Remarks__c = remark;
                receipt.Receipt_date__c = Date.valueOf(poc);
                receipt.Booking__c = recid;
                receipt.Finance_User__c = bk.Finance_Lead__c;
                receipt.Approval_status__c = 'Approved';
                receipt.Type__c = typeKey;
                receipt.Amount_Received__c = amountReceived;
                
                receiptsToInsert.add(receipt);
                typeToReceiptMap.put(typeKey, receipt);
            }
        } else {
            Decimal amountReceived = 0;
            for (Receipt_Line_Item__c line : receiptsToCreate) {
                if (!tdsExcludedTypes.contains(line.Payment_Type__c)) {
                    amountReceived += line.Received_Amount__c != null ? line.Received_Amount__c : 0;
                }
            }
            Receipt__c receipt = new Receipt__c();
            receipt.Remarks__c = remark;
            receipt.Receipt_date__c = Date.valueOf(poc);
            receipt.Booking__c = recid;
            receipt.Finance_User__c = bk.Finance_Lead__c;
            receipt.Approval_status__c = 'Approved';
            receipt.Amount_Received__c = amountReceived;
            receipt.Type__c = bk.Project_Type__c;
            
            receiptsToInsert.add(receipt);
            typeToReceiptMap.put('COMMON', receipt);
        }
        
        insert receiptsToInsert;
        
        for (String typeKey : typeToLinesMap.keySet()) {
            Receipt__c createdReceipt;
            
            if (bk.Project_Type__c == 'Villas') {
                createdReceipt = typeToReceiptMap.get(typeKey);
            } else {
                createdReceipt = typeToReceiptMap.get('COMMON');
            }
            
            for (Receipt_Line_Item__c line : typeToLinesMap.get(typeKey)) {
                line.Receipt__c = createdReceipt.Id;
            }
        }
        
        insert receiptsToCreate;

        // Stage attached files: create ContentVersion + ContentDocumentLink to
        // every Receipt created in this transaction (Villas split → both
        // Land & Construction receipts get the same file).
        if (String.isNotBlank(stagedFiles)) {
            List<Object> raw = (List<Object>) JSON.deserializeUntyped(stagedFiles);
            if (raw != null && !raw.isEmpty()) {
                List<ContentVersion> versions = new List<ContentVersion>();
                for (Object o : raw) {
                    Map<String, Object> w = (Map<String, Object>) o;
                    String fileName = (String) w.get('name');
                    String b64 = (String) w.get('base64');
                    if (String.isBlank(fileName) || String.isBlank(b64)) {
                        continue;
                    }
                    ContentVersion cv = new ContentVersion();
                    cv.Title = fileName;
                    cv.PathOnClient = fileName;
                    cv.VersionData = EncodingUtil.base64Decode(b64);
                    cv.IsMajorVersion = true;
                    versions.add(cv);
                }
                if (!versions.isEmpty()) {
                    insert versions;

                    Set<Id> versionIds = new Set<Id>();
                    for (ContentVersion cv : versions) {
                        versionIds.add(cv.Id);
                    }
                    Map<Id, Id> versionToDocument = new Map<Id, Id>();
                    for (ContentVersion cv : [
                        SELECT Id, ContentDocumentId FROM ContentVersion WHERE Id IN :versionIds
                    ]) {
                        versionToDocument.put(cv.Id, cv.ContentDocumentId);
                    }

                    List<ContentDocumentLink> links = new List<ContentDocumentLink>();
                    for (Receipt__c r : receiptsToInsert) {
                        for (Id vId : versionToDocument.keySet()) {
                            ContentDocumentLink cdl = new ContentDocumentLink();
                            cdl.ContentDocumentId = versionToDocument.get(vId);
                            cdl.LinkedEntityId = r.Id;
                            cdl.ShareType = 'V';
                            cdl.Visibility = 'AllUsers';
                            links.add(cdl);
                        }
                    }
                    if (!links.isEmpty()) {
                        insert links;
                    }
                }
            }
        }

        return bk.Id;
    }

}