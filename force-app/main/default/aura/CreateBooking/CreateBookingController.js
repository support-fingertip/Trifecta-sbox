({
    doInit: function(component, event, helper) {
        component.set('v.showCostSheet',true);
        component.set("v.isLoading", true);
        var action = component.get("c.quoteRecord");
        action.setParams({ 
            recId: component.get("v.recordId")
        });
        
        action.setCallback(this, function(response) {
            var state=response.getState();
            console.log('Response : '+response.getReturnValue()); 
            
            if(state==='SUCCESS'){
                var qt = response.getReturnValue();
                component.set('v.quote',qt);
                var book = component.get("v.book");
                var unitstatus = qt.Unit__r.Status__c;
                if(unitstatus == 'Booked'){
                    helper.showToast('Error', 'Error!', "Unit is not available. Booking already created for this Unit");
                    var dismissActionPanel = $A.get("e.force:closeQuickAction");
                    dismissActionPanel.fire();
                }	
                book.BHK_Type__c = qt.BHK_Type__c;	
                book.Super_Built_UpArea__c = qt.Super_Built_UpArea__c;		
                book.Rate_per_sqft__c = qt.Rate_sq_Ft_Discount__c;	
                book.Project__c	 = qt.Project__c;
                book.Unit_Number__c	 = qt.Unit_Number__c;
                book.Type_of_Aggrement__c = 'Single';
                
                book.Email__c = qt.SLead__r.Email;
                book.First_Applicant_Name__c = qt.SLead__r.Name;
                book.Age__c = qt.SLead__r.Age__c;
                book.Mobile__c =  qt.SLead__r.Phone__c;
                book.Project_Type__c =  qt.Property_Type__c; 
                book.Plot_Land_Area__c =  qt.Plot_Land_Area__c; 
                book.Construction_Cost__c =  qt.Construction_Cost__c; 
                book.Plot_Land_Cost__c =  qt.Land_Cost__c; 
                book.Extra_Land_Amount__c =  qt.Extra_Land_Amount__c;
                
                /*book.Aadhaar_Uploaded__c = true;
                book.PAN_Uploaded__c = true;
                book.Applicant_Photo_Uploaded__c = true; 
                book.Proof_of_Address_Uploaded__c = true; */
                component.set('v.grandTotal', qt.Grand_Total_Amount__c);

                component.set('v.book',book);
                
            }
            component.set("v.isModalOpen", true);
            component.set("v.isLoading", false);
        });
        $A.enqueueAction(action);
    },
    
    //Format fields
    handleEmailChange: function(component, event, helper) {
        var newEmail = event.getSource().get("v.value");
        component.set("v.PEmail", newEmail);
    },
    formatPAN: function(component, event, helper) {
        var panField = event.getSource();
        var panValue = panField.get("v.value");
        
        if (panValue) {
            panField.set("v.value", panValue.toUpperCase()); // Force uppercase
        }
    },
    handleSameAddressChange : function(component, event, helper) {
        var checked = event.getSource().get("v.checked");
        var book = component.get("v.book");
        if (checked) {
            book.Permanent_Address1__c = book.Address__c;
            book.Pincode1__c = book.Pincode__c;
        } else {
            book.Permanent_Address1__c = '';
            book.Pincode1__c = '';
        }
        
        component.set("v.book", book);
    },
    
    //Photo Upload Section
    handleFilesChangePhoto: function(component, event, helper) {
        var fileName = 'Upload Government issued photo identity proof..';
        if (event.getSource().get("v.files").length > 0) {
            fileName = event.getSource().get("v.files")[0]['name'];
        }
        component.set("v.fileName", fileName);
        
    },
    handleFilesChange2ndPhoto: function(component, event, helper) {
        var fileName = 'Upload PAN Photo..';
        if (event.getSource().get("v.files").length > 0) {
            fileName = event.getSource().get("v.files")[0]['name'];
        }
        component.set("v.file2ndName", fileName);
        
    },
    handleFilesChange3rdPhoto: function(component, event, helper) {
        var fileName = 'Upload Applicant Photo..';
        if (event.getSource().get("v.files").length > 0) {
            fileName = event.getSource().get("v.files")[0]['name'];
        }
        component.set("v.file3rdName", fileName);
        
    },
    handleFilesChange4thPhoto: function(component, event, helper) {
        var fileName = 'Upload Proof of Address..';
        if (event.getSource().get("v.files").length > 0) {
            fileName = event.getSource().get("v.files")[0]['name'];
        }
        component.set("v.file4thName", fileName);
        
    },
    
    removeRow : function(component, event, helper) {
        var selectedItem = event.currentTarget;
        var index = selectedItem.dataset.record;
        var aitems= component.get('v.applicantList');
        aitems.splice(index, 1);
        component.set("v.applicantList", aitems);
    },
    addRow: function(component, event, helper) { 
        helper.addAppliacantRecord(component, event, helper);
    },
    
    closeModel: function(component, event, helper) {
        component.set("v.isModalOpen", false);
        $A.get("e.force:closeQuickAction").fire();
    },
    validateBookingDate: function(component, event, helper) {
        var bookingDate = component.get("v.book.Booking_Date__c");
        var dopyamentDate = component.get("v.book.Date_of_Payment__c");
        
        if (bookingDate) {
            var selectedDate = new Date(bookingDate);
            var currentDate = new Date();
            
            // Check if date is in future
            if (selectedDate > currentDate) {
                helper.showToast('Error', 'Error!', "Booking date cannot be a future date.");
                component.set("v.book.Booking_Date__c", null);
            } 
        }
        if (dopyamentDate) {
            var selectedDate = new Date(dopyamentDate);
            var currentDate = new Date();
            
            // Check if date is in future
            if (selectedDate > currentDate) {
                helper.showToast('Error', 'Error!', "Date of Payment cannot be a future date.");
                component.set("v.book.Date_of_Payment__c", null);
            } 
        }
    },
    
    save: function(component, event, helper) {
        if(helper.validateFields(component,event,helper)) {
            // If validation passes, call the helper function to save the record
            helper.saveRecord(component,event,helper);
        }
    },
    calculateLoanAmount : function(component, event, helper) {
        var loanPercent = component.get("v.book.Loan_Percentage__c");
        var grandTotal = component.get("v.grandTotal");
        
        
        if(loanPercent != null && grandTotal != null){
            if(loanPercent > 100 )
            {
                helper.showToast('Error', 'Error!', "Loan Percentage cannot be more than 100%");
                component.set("v.loanAmount", 0);
                component.set("v.book.Loan_Percentage__c", 0);
            }
            else
            {
                var loanAmount = (grandTotal * loanPercent) / 100;
                component.set("v.loanAmount", loanAmount.toFixed(2));
            }
          
        } else {
            component.set("v.loanAmount", 0);
        }
    }


})