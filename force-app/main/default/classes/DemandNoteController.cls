public class DemandNoteController {
    
    // Wrapper class for demand note details
    public class DemandNoteData {
        public String customerId {get; set;}
        public String customerName {get; set;}
        public String unitNo {get; set;}
        public String block {get; set;}
        public String projectName {get; set;}
        public String projectAddress {get; set;}
        public String email {get; set;}
        public String contactNo {get; set;}
        public Date demandDate {get; set;}
        public Date dueDate {get; set;}
        public Decimal totalAmount {get; set;}
        public String totalAmountInWords {get; set;}
        public List<MilestoneItem> milestones {get; set;}
        public BankDetails bankInfo {get; set;}
    }
    
    // Wrapper class for milestone items
    public class MilestoneItem {
        public String milestoneName {get; set;}
        public Date dueDate {get; set;}
        public Decimal previousDues {get; set;}
        public Decimal milestoneExcludingTDS {get; set;}
        public Decimal tdsAmount {get; set;}
        public Decimal totalAmount {get; set;}
    }
    
    // Wrapper class for bank details
    public class BankDetails {
        public String bankName {get; set;}
        public String accountNumber {get; set;}
        public String ifscCode {get; set;}
        public String accountType {get; set;}
        public String branch {get; set;}
    }
    
    public DemandNoteData demandNote {get; set;}
    
    // Constructor - Initialize with sample data or fetch from database
    public DemandNoteController() {
        initializeDemandNote();
    }
    
    // Constructor with record ID for fetching data from Salesforce
    public DemandNoteController(ApexPages.StandardController controller) {
        initializeDemandNote();
        // You can fetch data from the record here
        // Id recordId = controller.getId();
        // fetchDemandNoteData(recordId);
    }
    
    private void initializeDemandNote() {
        demandNote = new DemandNoteData();
        
        // Company and Customer Details
        demandNote.customerId = 'T-000012';
        demandNote.customerName = 'Mr. Umesh Mishra & Mrs. Reena Mishra';
        demandNote.unitNo = '1155';
        demandNote.block = 'C';
        demandNote.projectName = 'TRIFECTA VENTO PHASE-2';
        demandNote.projectAddress = 'Kodathi Village, Varthur Hobli, Bangalore Urban, Karnataka - 560035';
        demandNote.email = 'vantopayments@trifectaprojects.com';
        demandNote.contactNo = '8088097739/6366558234';
        demandNote.demandDate = Date.newInstance(2026, 1, 23);
        demandNote.dueDate = Date.newInstance(2026, 2, 1);
        demandNote.totalAmount = 1100000;
        demandNote.totalAmountInWords = 'Eleven Lakhs Only';
        
        // Milestone Items
        demandNote.milestones = new List<MilestoneItem>();
        MilestoneItem milestone = new MilestoneItem();
        milestone.milestoneName = 'On Completion of Foundation (Sample)';
        milestone.dueDate = Date.newInstance(2026, 1, 25);
        milestone.previousDues = 100000;
        milestone.milestoneExcludingTDS = 999000;
        milestone.tdsAmount = 11000;
        milestone.totalAmount = 1100000;
        demandNote.milestones.add(milestone);
        
        // Bank Details
        demandNote.bankInfo = new BankDetails();
        demandNote.bankInfo.bankName = 'HDFC BANK';
        demandNote.bankInfo.accountNumber = '31500021761783';
        demandNote.bankInfo.ifscCode = 'HDFC01211045';
        demandNote.bankInfo.accountType = 'Current Account';
        demandNote.bankInfo.branch = 'Mahadevapura, Bangalore';
    }
    
    // Method to fetch data from Salesforce object (customize based on your data model)
    /*
    private void fetchDemandNoteData(Id recordId) {
        // Example: Fetch from a custom object
        // Demand_Note__c dn = [SELECT Id, Customer_Id__c, Customer_Name__c, Unit_No__c, 
        //                      Block__c, Total_Amount__c, Due_Date__c 
        //                      FROM Demand_Note__c WHERE Id = :recordId];
        // demandNote.customerId = dn.Customer_Id__c;
        // demandNote.customerName = dn.Customer_Name__c;
        // ... map other fields
    }
    */
    
    // Helper method to format currency
    public String formatCurrency(Decimal amount) {
        if (amount == null) return '0.00';
        return String.valueOf(amount.setScale(2));
    }
    
    // Helper method to format date
    public String formatDate(Date dt) {
        if (dt == null) return '';
        return dt.format();
    }
}