({
    addProductRecord: function(component, event) {
        var productList = component.get("v.recptItemList");
        // Check if the list already has 2 items
        if (productList.length >= 2) {
            return;
        }
        productList.push({
            'sobjectType': 'Receipt_Line_Item__c',
            'Payment_schedule__c': '',
            'Mode_of_Payment__c': '',
            'Name': '',
            'Payment_Type__c':'',
            'Cheque_no_Transaction_Number__c':'',
            'Received_Amount__c': '',
            'Payment_From__c':'',
            'Bank_Name__c':'',
            'Branch__c':'',
            'Drwan_On__c':'',
            'GRAND_TOTAL__c':'',
            'Pending_Amount__c': '',
            'Additional_Charges__c':''
        });
        component.set("v.recptItemList", productList);
    },
    getData : function(component,event,helper){
        var action=component.get("c.getData");
        action.setParams({'recId':  component.get('v.recordId') })
        action.setCallback(this,function(response){
            if(response.getState() == "SUCCESS"){ 
                var data = response.getReturnValue();
                component.set('v.additionlCharges',  data.additionalCharges);
                component.set('v.paymentschdl',  data.paymentSchdules);
                component.set("v.paymentTypePicklist",data.paymentTypePicklist);
                component.set("v.totalPendingTds", data.tdsAmount);
                component.set("v.projectName", data.bookingRecord.Project__c);
                component.set("v.flatNumber", data.bookingRecord.Unit_Number__c);
                component.set("v.FlatCost", data.bookingRecord.Total_Amount__c);
                console.log('data.flatOrVillaPendingAmount'+data.flatOrVillaPendingAmount);
                component.set("v.flatOrVillaPendingAmount",data.flatOrVillaPendingAmount);
                component.set("v.bookingPendingAmount",data.bookingRecord.Pending_Amount__c);
                component.set("v.bookingPendingAmount1",data.bookingRecord.Pending_Amount__c);
                component.set("v.totalPending", data.bookingRecord.Pending_Amount__c);
                component.set("v.bookingType",data.bookingRecord.Project_Type__c);
                component.set("v.interestAmount",data.iterestAmount);
            }
        });
        $A.enqueueAction(action); 
    },
    showToast : function(message,type) {
        var toastEvent = $A.get("e.force:showToast");
        toastEvent.setParams({
            "type":type,
            "message":  message
        });
        toastEvent.fire();
    },
    
    validateCumulativeAmount: function(component, event, helper, index) {
        var recptItemList = component.get("v.recptItemList");
        var totalPendingAmount = component.get("v.bookingPendingAmount1");
        var cumulativeReceivedAmount = 0;
        
        for (var i = 0; i < recptItemList.length; i++) {
            if (
                recptItemList[i].Payment_Type__c === 'Flat Amount' ||
                recptItemList[i].Payment_Type__c === 'Plot Amount' ||
                recptItemList[i].Payment_Type__c === 'GST Amount' ||
                recptItemList[i].Payment_Type__c === 'Villa Amount' ||
                recptItemList[i].Payment_Type__c === 'Row House Amount' ||
                recptItemList[i].Payment_Type__c === 'TDS'
            ) {
                let received = parseFloat(recptItemList[i].Received_Amount__c) || 0;
                let pending = parseFloat(recptItemList[i].Pending_Amount__c) || 0;
                
                //  Row-level validation — prevent exceeding the row's pending amount
                if (received > pending) {
                    helper.showToast("Received amount cannot exceed the pending "+recptItemList[i].Payment_Type__c, "error");
                    recptItemList[i].Received_Amount__c = null;
                    received = 0;
                }
                
                cumulativeReceivedAmount += received;
            }
        }
        
        //  Overall total validation — prevent cumulative > total pending
        if (cumulativeReceivedAmount > totalPendingAmount) {
            helper.showToast("Cumulative received amount cannot exceed the total pending amount", "error");
            recptItemList[index].Received_Amount__c = null;
            
            // Recalculate total again after resetting the current field
            cumulativeReceivedAmount = 0;
            for (var j = 0; j < recptItemList.length; j++) {
                if (
                    recptItemList[j].Payment_Type__c === 'Flat Amount' ||
                    recptItemList[j].Payment_Type__c === 'Plot Amount' ||
                    recptItemList[j].Payment_Type__c === 'GST Amount' ||
                    recptItemList[j].Payment_Type__c === 'Villa Amount' ||
                    recptItemList[j].Payment_Type__c === 'TDS'
                ) {
                    cumulativeReceivedAmount += parseFloat(recptItemList[j].Received_Amount__c) || 0;
                }
            }
        }
        
        component.set("v.totalrcvdAmount", cumulativeReceivedAmount);
        component.set("v.totalPending", parseFloat((totalPendingAmount - cumulativeReceivedAmount).toFixed(2)));
        component.set("v.recptItemList", recptItemList);
    },
    getTotalAmount: function(component, event, helper) {
        var totalPendingAmount = component.get("v.bookingPendingAmount1");
        var recptItemList = component.get("v.recptItemList");
        // Recalculate total again after resetting the current field
        var cumulativeReceivedAmount = 0;
        for (var j = 0; j < recptItemList.length; j++) {
            if (
                recptItemList[j].Payment_Type__c === 'Flat Amount' ||
                recptItemList[j].Payment_Type__c === 'Plot Amount' ||
                recptItemList[j].Payment_Type__c === 'GST Amount' ||
                recptItemList[j].Payment_Type__c === 'Villa Amount' ||
                recptItemList[j].Payment_Type__c === 'TDS'
            ) {
                cumulativeReceivedAmount += parseFloat(recptItemList[j].Received_Amount__c) || 0;
            }
        }
        
        component.set("v.totalrcvdAmount", cumulativeReceivedAmount);
        component.set("v.totalPending", parseFloat((totalPendingAmount - cumulativeReceivedAmount).toFixed(2)));
        component.set("v.recptItemList", recptItemList);
    },
    
})