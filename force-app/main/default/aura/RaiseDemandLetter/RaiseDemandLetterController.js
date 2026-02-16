({
    doInit: function (component, event, helper) {
        var bookingRecordId = component.get("v.recordId");
        var bookingId = component.get("v.Bookid");
        helper.getData(component, event, helper);
    },
    handleToggleChange : function(component, event, helper) {
        var isChecked = event.target.checked;
        if(isChecked == true){
            component.set("v.includeInterest", 'true');
        }
        else{
            component.set("v.includeInterest", 'false');
        }
        
    },
    
    sendEmail: function (component, event, helper) {
        console.log('here sendEmail'); 
        var action = component.get("c.RaiseDemand");
        var recId = component.get("v.recordId");

        action.setParams({
            "bookingId": recId,
            "emailContent": component.get("v.emailContent")
        });
        console.log('here 1');        
        // Set the callback function to handle the response from Apex
        action.setCallback(this, function(response) {
            var state = response.getState(); // Get the response state
            
            if (state === 'SUCCESS') {
                console.log('here sucess');
                // Retrieve the return value from the Apex method
                var res_string = response.getReturnValue();
                
                // Close the quick action panel
                var dismissActionPanel = $A.get("e.force:closeQuickAction");
                dismissActionPanel.fire();
                
                // Determine the toast type based on the response
                var type = res_string === 'Demand raised successfully' ? 'success' : 'error';
                
                // Show toast notification
                var toastEvent = $A.get("e.force:showToast");
                toastEvent.setParams({
                    "type": 'Success',
                    "title": 'success', // Capitalize title
                    "message": 'Demand raised successfully',
                    "duration": 2000
                });
                toastEvent.fire();
                
                // Refresh the view to reflect changes
                $A.get('e.force:refreshView').fire();
            } else if (state === 'ERROR') {
                console.log('here Error');
                // Handle error case
                var errors = response.getError();
                if (errors && Array.isArray(errors) && errors.length > 0) {
                    console.log('Error message: ' + errors[0].message);
                } else {
                    console.log('Unknown error');
                }
            }
        });
        
        // Enqueue the action to call the Apex method
        $A.enqueueAction(action);
    },
    
    close: function (component, event, helper) {
        component.set('v.visible',false);
        $A.get("e.force:closeQuickAction").fire();
        
    },
    
    handleClick : function (cmp, event, helper) {
        var buttonstate = cmp.get('v.buttonstate');
        cmp.set('v.buttonstate', !buttonstate);
    },
    
})