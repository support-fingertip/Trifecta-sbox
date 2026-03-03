({
    sendKeyHandoverEmail : function(component) {
        component.set("v.errorMessage", "");
        component.set("v.isSending", true);

        var action = component.get("c.sendKeyHandoverEmail");
        action.setParams({
            bookingId : component.get("v.recordId")
        });

        action.setCallback(this, function(response) {
            component.set("v.isSending", false);
            var state = response.getState();

            if (state === "SUCCESS") {
                var res = response.getReturnValue();
                if (res.startsWith("Success")) {
                    this.showToast("Success", res, "success");
                    // Close the quick action window on success
                    $A.get("e.force:closeQuickAction").fire();
                    // Refresh the view to show the email activity in the timeline
                    $A.get("e.force:refreshView").fire();
                } else {
                    component.set("v.errorMessage", res);
                }
            } else {
                var errors = response.getError();
                var msg = (errors && errors[0] && errors[0].message) ? errors[0].message : "Unknown error.";
                component.set("v.errorMessage", msg);
            }
        });

        $A.enqueueAction(action);
    },

    showToast : function(title, message, type) {
        var toast = $A.get("e.force:showToast");
        if (toast) {
            toast.setParams({
                title: title,
                message: message,
                type: type
            });
            toast.fire();
        }
    }
})