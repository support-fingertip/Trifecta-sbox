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
                helper.showToast("Success", "Booking has been Submitted for Approval", "Success");
                
                var recordId = response.getReturnValue();
                var navEvt = $A.get("e.force:navigateToSObject");
                navEvt.setParams({
                    "recordId": recordId,
                    "slideDevName": "detail"
                });
                navEvt.fire();
                $A.get('e.force:refreshView').fire();
            }
        });
        $A.enqueueAction(action);
    },
    closeModel :function(component, event, helper){
        $A.get("e.force:closeQuickAction").fire();
    }
})