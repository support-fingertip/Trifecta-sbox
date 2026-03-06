({
	doInit: function(component, event, helper) {
        component.set("v.isLoading", true);
        let action = component.get("c.getBookingRecord");
        action.setParams({ recordId: component.get("v.recordId")  });
        action.setCallback(this, function(response) {
            let state = response.getState();
            if (state === "SUCCESS") {
                var result = response.getReturnValue();
                component.set("v.data", result.paymentSchdules);
                component.set("v.coApplicant", result.coApplicant);
                component.set("v.booking", result.booking);
                component.set("v.currentMilestone", result.currentMilestone);
                component.set("v.emailTemplateContent", result.template);
            } else {
                console.error("Error fetching data: ", response.getError());
            }
            component.set("v.isLoading", false);
        });
        
        $A.enqueueAction(action);
        
    },
    handleClosePopup : function(component, event, helper) {
		component.set("v.visible",false);
	},
    handleRadioSelection: function(component, event, helper) {
        const selectedIndex = parseInt(event.currentTarget.getAttribute('data-index'), 10);
        const selectedIndexId = event.currentTarget.getAttribute('value');
        const selectedMilestone = event.currentTarget.getAttribute('data-value');
       
        component.set("v.selectedIndexId", selectedIndexId);
        component.set("v.selectedMilestone", selectedMilestone);
        component.set("v.selectedIndex", selectedIndex);
    },
    handleGenerate: function(component, event, helper) {
        
        var bookingval = component.get('v.booking') || {};
        var currentMilestone = component.get('v.currentMilestone') || {};
        var selectedIndexId = component.get('v.selectedIndexId');
        var selectedMilestone = component.get('v.selectedMilestone') || '';
        var coApplicant = component.get('v.coApplicant') || {};
        var emailTemplateContent = component.get('v.emailTemplateContent') || {};
        
        var rawEmailContent = emailTemplateContent.Template_Body__c || '';
        
        component.set("v.milestoneId", selectedIndexId);
        
        if (!selectedIndexId) {
            var toastEvent = $A.get("e.force:showToast");
            toastEvent.setParams({
                type: 'error',
                title: 'Error',
                message: 'Please select a milestone',
                duration: 5000
            });
            toastEvent.fire();
            return;
        }
        
        /* ================= Applicant Names ================= */
        var applicantNames = '';
        
        if (bookingval.S__c && bookingval.First_Applicant_Name__c) {
            applicantNames = bookingval.S__c + ' ' + bookingval.First_Applicant_Name__c;
        } else if (bookingval.First_Applicant_Name__c) {
            applicantNames = bookingval.First_Applicant_Name__c;
        }
        
        if (coApplicant.Name && coApplicant.Name.trim() !== '') {
            applicantNames += (applicantNames ? ' and ' : '') + coApplicant.Name.trim();
        }
        
        /* ================= Milestone ================= */
        var milestoneName =  selectedMilestone;
        
        /* ================= Project Name ================= */
        var projectName = '';
        if (bookingval.Project1__r && bookingval.Project1__r.Name) {
            projectName = bookingval.Project1__r.Name;
        }
        
        /* ================= Company Details ================= */
        var companyName =bookingval.Company_Name__c || '';  
        var crmPhone = bookingval.Owner_Phone__c || '';
        
        /* ================= Placeholder Replacement ================= */
        var finalEmailContent = rawEmailContent;
        
        finalEmailContent = finalEmailContent.replace(/##APPLICANT_NAME##/g, applicantNames);
        finalEmailContent = finalEmailContent.replace(/##COMPANY_NAME##/g, companyName);
        finalEmailContent = finalEmailContent.replace(/##MILESTONE_NAME##/g, milestoneName);
        finalEmailContent = finalEmailContent.replace(/##PROJECT_NAME##/g, projectName);
        finalEmailContent = finalEmailContent.replace(/##CRM_PHONE##/g, crmPhone);
        
           // 1. Decode HTML entities first
        var decoded = finalEmailContent
        .replace(/&lt;/g, "<")
        .replace(/&gt;/g, ">")
        .replace(/&amp;/g, "&");
        
        // 2. Remove extra span wrappers added by RTE
        decoded = decoded.replace(/<span[^>]*>/g, "");
        decoded = decoded.replace(/<\/span>/g, "");
        
        // 3. Remove empty paragraphs created by editor
        decoded = decoded.replace(/<p><br><\/p>/g, "");
        
        
        component.set("v.emailContent", decoded);
        component.set("v.filesLoading", true);
        var action = component.get("c.getScheduleFiles");
        action.setParams({
            paymentScheduleId: selectedIndexId
        });
        
        action.setCallback(this, function(response){
            if(response.getState() === "SUCCESS"){
                component.set("v.filesLoading", false);
                var fileIds = response.getReturnValue();
                component.set("v.exestingFilesIDS", fileIds);
                component.set("v.filesIDS", fileIds);
            }
        });
        $A.enqueueAction(action);
    },
    handleSendProjectStatus: function(component, event, helper) {
        component.set("v.isLoading", true);
        var selectedIndexId =  component.get('v.milestoneId');
        var emailContent = component.get("v.emailContent");
        emailContent = emailContent.replace(/<p>(&nbsp;|\s)*<\/p>/g, '');
        emailContent = emailContent.replace(/(<br\s*\/?>\s*){2,}/g, '<br/>');
        var contentDocumentIds = component.get("v.filesIDS");
        console.log('contentDocumentIds'+JSON.stringify(contentDocumentIds)); 
        if(selectedIndexId){
            let action = component.get("c.sendPSREmail");
            action.setParams({
                "bookingId": component.get("v.recordId"),
                "paymentScheduleId": selectedIndexId,
                "messageBody": emailContent,
                "fileDocumentIds": contentDocumentIds
            });
            
            // Set the callback function to handle the response from Apex
            action.setCallback(this, function(response) {
                var state = response.getState(); // Get the response state
                component.set("v.isLoading", true);
                if (state === 'SUCCESS') {
                    console.log('here sucess');
                    var toastEvent = $A.get("e.force:showToast");
                    toastEvent.setParams({
                        "title": "Success",
                        "message": "Project Status Report send Successfully",
                        "type": "Success"
                    });
                    toastEvent.fire();
                    
                    // Close the quick action panel
                    var dismissActionPanel = $A.get("e.force:closeQuickAction");
                    dismissActionPanel.fire();
                    // Refresh the view to reflect changes
                    $A.get('e.force:refreshView').fire();
                } 
                else if (state === 'ERROR') {
                    console.log('here Error');
                    // Handle error case
                    var errors = response.getError();
                    if (errors && Array.isArray(errors) && errors.length > 0) {
                        console.log('Error message: ' + errors[0].message);
                    } else {
                        console.log('Unknown error');
                    }
                }
                component.set("v.visible",false);
            });
            
            // Enqueue the action to call the Apex method
            $A.enqueueAction(action);
        }else{
            var toastEvent = $A.get("e.force:showToast");
            var type = 'error';
            toastEvent.setParams({
                "type": type,
                "title": type.charAt(0).toUpperCase() + type.slice(1), // Capitalize title
                "message": 'Please select a milestone',
                "duration": 10000
            });
            toastEvent.fire();
        }
    },
    handleFileUpload: function(component, event, helper) {
        var files = event.getParam("files");
        var getFiles = component.get("v.filesIDS");
        getFiles.push(...files);
        component.set('v.filesIDS',getFiles);
        
        var afercomit = component.get('v.filesIDS');
    },

})