({
    doInit : function(component, event, helper) {
        var booking = component.get("v.booking");
        var recordId = component.get("v.recordId");
        var vfName = "";

        if (booking) {
            var pType = booking.Project_Type__c;
            if (pType === 'Villas') vfName = "VillasKeyHandoverVfp";
            else if (pType === 'Row House') vfName = "RowHouseKeyHandoverVfp";
            else if (pType === 'Apartments' || pType === 'Plots') vfName = "FlatKeyHandoverVfp";

            if (vfName !== "") {
                // Construct the URL to the VF page
                component.set("v.pdfUrl", "/apex/" + vfName + "?id=" + recordId);
            }
        }
    },

    handleSend : function(component, event, helper) {
        helper.sendKeyHandoverEmail(component);
    },

    handleCancel : function(component, event, helper) {
        $A.get("e.force:closeQuickAction").fire();
    }
})