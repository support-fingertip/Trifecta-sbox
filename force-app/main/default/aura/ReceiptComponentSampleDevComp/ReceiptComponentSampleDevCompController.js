({
    doInit : function(component,event,helper){
        var id = component.get("v.recordId");
        var today = $A.localizationService.formatDate(new Date(), "yyyy-MM-dd");
        var rcpt = component.get("v.rcpt");
        rcpt.Receipt_Date__c = today;
        component.set("v.rcpt", rcpt);
        helper.addProductRecord(component, event,id);
        helper.getData(component, event,helper); 
      
    },
    /**Select Type **/
    selectingType: function(component, event, helper) {
        var index = event.currentTarget.dataset.record;
        var recptItemList = component.get("v.recptItemList");
        var selectedType = recptItemList[index].Payment_Type__c;
        var SOLO_TYPES = ['TDS Paid', 'TDS Refund'];

        // Duplicate-row check (preserved from original)
        var isTrue = false;
        for (var i = 0; i < recptItemList.length; i++) {
            if (i != index && recptItemList[i].Payment_Type__c === selectedType) {
                helper.showToast("This payment type has already been selected in another row", "error");
                isTrue = true;
                break;
            }
        }

        // Solo-row guards: TDS Paid / TDS Refund must be standalone receipts
        var isSelectedSolo = SOLO_TYPES.indexOf(selectedType) !== -1;
        var otherRowsHaveContent = recptItemList.some(function(r, i) {
            return i != index && (r.Payment_Type__c || '').length > 0;
        });
        var otherRowHasSolo = recptItemList.some(function(r, i) {
            return i != index && SOLO_TYPES.indexOf(r.Payment_Type__c) !== -1;
        });

        if (isSelectedSolo && otherRowsHaveContent) {
            var updatedSelectedType = selectedType == 'TDS Paid' ? 'TDS Challan Entry' : selectedType;
            helper.showToast("'" + updatedSelectedType + "' must be the only line item in a receipt. Remove other rows first.", "error");
            recptItemList[index].Payment_Type__c = '';
            component.set("v.recptItemList", recptItemList);
            return;
        }
        if (otherRowHasSolo) {
            helper.showToast("This receipt already contains a TDS Challan Entry or TDS Refund row, which must be standalone.", "error");
            recptItemList[index].Payment_Type__c = '';
            component.set("v.recptItemList", recptItemList);
            return;
        }

        if (selectedType === 'Flat Amount' || selectedType === 'Villa Amount' || selectedType === 'Row House Amount') {
            recptItemList[index].Pending_Amount__c = component.get('v.flatOrVillaPendingAmount');
        }
        else if (selectedType === 'TDS from Bank' || selectedType === 'TDS Paid') {
            recptItemList[index].Pending_Amount__c = component.get('v.totalPendingTds');
        }
        else if (selectedType === 'TDS Refund') {
            recptItemList[index].Pending_Amount__c = component.get('v.pendingTdsRefundAmount');
        }
        else if (selectedType === 'Interest Amount') {
            recptItemList[index].Pending_Amount__c = component.get('v.interestAmount');
        }

        if (isTrue) {
            recptItemList.splice(index, 1);
            helper.addProductRecord(component, event);
        }
        component.set("v.recptItemList", recptItemList);
    },
    /**On change Received Amount **/
    validateReceivedAmount: function(component, event, helper) {
        var index = event.currentTarget.dataset.record;
        var recptItemList = component.get("v.recptItemList");
        var receivedAmount = recptItemList[index].Received_Amount__c;
        helper.validateCumulativeAmount(component, event, helper,index);
        if (isNaN(receivedAmount) || receivedAmount <= 0) {
            helper.showToast("Received Amount must be a valid number greater than or equal to 0", "error");
            recptItemList[index].Received_Amount__c = null;
            return;
        }
        
       
    },

    addRow: function(component, event, helper) {
        var existing = component.get("v.recptItemList") || [];
        var SOLO_TYPES = ['TDS Paid', 'TDS Refund'];
        var hasSolo = existing.some(function(r) {
            return SOLO_TYPES.indexOf(r.Payment_Type__c) !== -1;
        });
        if (hasSolo) {
            helper.showToast("TDS Paid and TDS Refund must be standalone receipts. Cannot add more rows.", "error");
            return;
        }
        component.set("v.savebuttonhide",true);
        helper.addProductRecord(component, event);
        helper.getTotalAmount(component, event, helper);
    },
    handleFileSelection: function(component, event, helper) {
        var files = event.getSource().get("v.files");
        if (!files || files.length === 0) {
            return;
        }
        var staged = component.get("v.stagedFiles") || [];
        var pending = files.length;
        Array.prototype.forEach.call(files, function(file) {
            var reader = new FileReader();
            reader.onload = function() {
                var base64 = reader.result.split(',')[1];
                staged.push({
                    name: file.name,
                    base64: base64,
                    sizeKb: Math.round(file.size / 1024)
                });
                pending--;
                if (pending === 0) {
                    component.set("v.stagedFiles", staged);
                }
            };
            reader.readAsDataURL(file);
        });
    },
    removeRow: function(component, event, helper) {
        var selectedItem = event.currentTarget;
        var index = selectedItem.dataset.record;
        
        var oitems= component.get('v.recptItemList');
        oitems.splice(index, 1);
        component.set("v.recptItemList", oitems);
        if(oitems.length < 1){
            helper.addProductRecord(component, event);
        }
        helper.getTotalAmount(component, event, helper);
        
    },
    receiptSave: function(component,event,helper) {
        component.set("v.saveButtonDisabled", true);
        let isAllValid = component.find('field').reduce(function(isValidSoFar, inputCmp){
            inputCmp.showHelpMessageIfInvalid();
            return isValidSoFar && inputCmp.checkValidity();
        },true);
        if(isAllValid == true){
            component.set("v.savebuttonhide",true);
            var ponum=component.get("v.rcpt.Receipt_Name__c"); 
            var reark = component.get("v.rcpt.Remarks__c"); 
            var oit= component.get('v.recptItemList');
            var tarik = component.get("v.rcpt.Receipt_Date__c"); 
   
            
            var action = component.get("c.insertReceiptLineItems");
            action.setParams({
                'polist' : component.get('v.recptItemList'),
                'remark':reark,
                'poc' : tarik,
                'recid':  component.get('v.recordId'),
                'paidAmount' : component.get('v.totalrcvdAmount'),
                'interestAmount' : component.get('v.interestReceived'),
                'stagedFiles' : JSON.stringify(component.get("v.stagedFiles") || [])
            });
            action.setCallback(this, function(response) {
                var state = response.getState();      
                if (state === "SUCCESS") {
                    
                    var ttu=response.getReturnValue();
                    // alert(ttu);
                    helper.showToast("Receipt has been created succesfully","Success");
                    $A.get('e.force:refreshView').fire();
                    var urlEvent = $A.get("e.force:navigateToURL");
                    urlEvent.setParams({
                        "url": "/"+ttu
                    });
                    urlEvent.fire();
                    $A.get('e.force:refreshView').fire();
                }
                else{
                    var errors = response.getError();
                    helper.showToast( errors[0].message, "Error");
                    component.set("v.saveButtonDisabled", false);
                }
            });
            $A.enqueueAction(action);
        }
        else{
            helper.showToast("Please fill all mandatory fields","Error");
            component.set("v.saveButtonDisabled", false);
        }
    },
    navigateToRefund: function(component, event, helper) {
        var recId = event.currentTarget.dataset.recordId;
        var navEvt = $A.get("e.force:navigateToSObject");
        navEvt.setParams({ "recordId": recId, "slideDevName": "detail" });
        navEvt.fire();
    },
    receiptCancel:function(component, event, helper) {
        component.set("v.savebuttonhide",false);
        component.set("v.recptItemList", []);
        
        component.set("v.matchpaymentschdl", []);
        component.set("v.paymentschdl", []);
        var navEvt = $A.get("e.force:navigateToSObject");
        navEvt.setParams({
            "recordId": component.get('v.recordId'),
            "slideDevName": "detail"
        });
        navEvt.fire();
        
    },
   
    /**Non in Use**/
    selectedAdditionalCharge : function(component, event, helper) {
        const selectedChargeId = event.target.value;
        const additionalCharges = component.get("v.additionlCharges"); 
        const selectedCharge = additionalCharges.find(charge => charge.Id === selectedChargeId);
        
        if (selectedCharge) {
            var index = event.currentTarget.dataset.record;
            const recptItemList = component.get("v.recptItemList"); 
            recptItemList[index].GRAND_TOTAL__c = selectedCharge.GRAND_TOTAL__c;
            component.set("v.bookingPendingAmount",selectedCharge.GRAND_TOTAL__c);
            component.set("v.recptItemList", recptItemList);
        }
    },
    ChangeName : function(component, event, helper){
        component.set("v.savebuttonhide",true);
    },
    getGrandTotal : function(component, event, helper) {
        component.set("v.savebuttonhide", true);
        var index = event.currentTarget.dataset.record;
        var oitems = component.get('v.recptItemList');
        var bookPendingAmount = component.get('v.bookingPendingAmount');
        var totalReceivedAmount = 0;
        var totalPendingAmount = 0;
        
        // Calculate totals
        for (var i = 0; i < oitems.length; i++) {
            if (oitems[i].Received_Amount__c) {
                totalReceivedAmount += parseFloat(oitems[i].Received_Amount__c);
            }
        }
        totalPendingAmount = bookPendingAmount - totalReceivedAmount;
        
        
        if (parseFloat(totalReceivedAmount) > parseFloat(totalPendingAmount)) {
            helper.showToast("Received Amount cannot exceed the Maximum Pending Amount", "error");
            return; 
        }
        
        var newPendingAmount = parseFloat(bookPendingAmount) - parseFloat(totalReceivedAmount);
        component.set('v.newPendingAmount', newPendingAmount);
        
        component.set('v.recptItemList', oitems);
        component.set('v.totalrcvdAmount', grandtotal);
        component.set('v.totalPending', totalPendingAmount);
        
    },
    

})