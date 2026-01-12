public class Demand_Note_send_Controller {
    public Decimal cgst { get; set; }
    public Decimal sgst { get; set; }
    public Decimal taxableValue { get; set; }
    public String demandId { get; set; }
   
    public Demand_Raised__c demand { get; set; }
    public Decimal TDSonePercentage { get; set; }
    
    public Demand_Note_send_Controller(ApexPages.StandardController controller) {
        TDSonePercentage = 0;
        
        demandId = ApexPages.currentPage().getParameters().get('Id');
        List<Demand_Raised__c> dmList = [SELECT Id, Grand_Total__c, GST__c FROM Demand_Raised__c WHERE Id = :demandId LIMIT 1];
        
        if (!dmList.isEmpty()) {
            demand = dmList[0];
            taxableValue = (demand.Grand_Total__c / (1 + demand.GST__c)).setScale(1);
            cgst = ((demand.Grand_Total__c - taxableValue) / 2).setScale(1);
            sgst = ((demand.Grand_Total__c - taxableValue) / 2).setScale(1);

            // Calculate TDSonePercentage here
            Decimal paidTotalAmount = demand.Grand_Total__c; // Replace with actual paid amount if available
            Decimal gstPercentage = (demand.GST__c != null) ? demand.GST__c / 100 : 0;
            Decimal amountExcludingGST = (demand.Grand_Total__c) / (1 + gstPercentage);
            TDSonePercentage = paidTotalAmount > 4999999 ? (amountExcludingGST * 0.01).setScale(0) : 0;
        }
    }
}