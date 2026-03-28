({
    doInit : function(component, event, helper) {
     component.set("v.isButtonDisabled", false);  
    },
    pushToCRMComp : function(component, event, helper){
        component.set("v.isButtonDisabled", true);
        var comments = component.get("v.newNote");
        component.set("v.isButtonDisabled", true);
        var action = component.get("c.moveToCRM");
        action.setParams({ 
            bookingId: component.get("v.recordId"),
            comments: component.get("v.newNote")
        });
        
        action.setCallback(this, function(response) {
            component.set("v.isButtonDisabled", true);
            var state = response.getState();
            if (state === 'SUCCESS') {
                component.set("v.isButtonDisabled", false);
                var returnVal = response.getReturnValue();
                if(returnVal == 'BookingFormNotSent')
                {
                    helper.showToast("Error", "Please send the booking form to the customer before pushing it to CRM.", "Error");
                }
                else
                {
                    helper.showToast("Success", "Booking has been Submitted for Approval", "Success");
                    
                    
                    var navEvt = $A.get("e.force:navigateToSObject");
                    navEvt.setParams({
                        "recordId": returnVal,
                        "slideDevName": "detail"
                    });
                    navEvt.fire();
                    $A.get('e.force:refreshView').fire();
                }
           
            }
        });
        $A.enqueueAction(action);
    },
    closeModel :function(component, event, helper){
        $A.get("e.force:closeQuickAction").fire();
    }
})