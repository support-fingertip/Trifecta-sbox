({
    handleClick : function(component, event, helper) {
        component.set("v.showPopup",true);
    },
    handleDemandClick : function(component, event, helper) {
        component.set("v.showDemandPopup",true);
    },
    handlePenaltyClick : function(component, event, helper) {
        component.set("v.showPenaltyPopup", true);
    }
})