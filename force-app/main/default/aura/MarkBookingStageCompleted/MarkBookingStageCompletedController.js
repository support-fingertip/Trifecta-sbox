({
    doInit : function(component, event, helper) {
        component.set("v.isButtonDisabled", false);
    },
    markStageCompleted : function(component, event, helper){
        component.set("v.isButtonDisabled", true);
        var comments = component.get("v.newNote");
        component.set("v.isButtonDisabled", true);
        var action = component.get("c.markStageAsCompleted");
        action.setParams({ 
            bookingId: component.get("v.recordId"),
            newNote: component.get("v.newNote")
        });
        
        action.setCallback(this, function(response) {
            component.set("v.isButtonDisabled", true);
            var state = response.getState();
            if (state === 'SUCCESS') {
                helper.showToast("Success", "Stage Status has been Updated Successfully", "Success");
                
                var recordId = component.get("v.recordId");
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