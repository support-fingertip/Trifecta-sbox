public class DemandInvioceController {
    public Booking__c booking { get; set; }
    public Decimal totalAmount { get; set; }
    public String receiptAmountInWords { get; set; }
    public List<Co_Applicant__c> coapplicants { get; set; }
    public Co_Applicant__c firstCoApplicant { get; set; }
    public bookingInfoWrapper bookingInfo { get; set; }
    public String bookingId {get; set;}
    
    public String currentCompletedStage { get; set; }
    public Decimal totalAmountPayable { get; set; }
    public String totalAmountPayableInWords { get; set; }
    public Date demandDueDate { get; set; }
    
    
    
    
    
    public class bookingInfoWrapper {
        public String customerId { get; set; }
        public String customerName { get; set; }
        public String unitNo { get; set; }
        public String block { get; set; }
        public String project { get; set; }
        
        public String projectAddress { get; set; }
        public String email { get; set; }
        public String contactNo { get; set; }
        public String webAddress { get; set; }
        public String companyAddress { get; set; }
    }
    
    public static Map<Integer, String> daySuffixMap = new Map<Integer, String>{1 => 'st', 2 => 'nd', 3 => 'rd', 21 => 'st', 22 => 'nd', 23 => 'rd', 31 => 'st'};
        
    public DemandInvioceController(ApexPages.StandardController controller) {        
        Id bookingRecordId = ApexPages.currentPage().getParameters().get('Id');
        if (bookingRecordId == null) {
            ApexPages.addMessage(new ApexPages.Message(ApexPages.Severity.ERROR, 'Booking record Id is null.'));
            return;
        }
        bookingId=bookingRecordId;
        // ===================== BOOKING QUERY =====================
        booking = [ SELECT Id,Name,Total_received_Amount__c, SLead__r.Lead_ID__c, Block_Id__c,
                   First_Applicant_Name__c, Unit_No__c, Block_Name__c,Project1__r.Name,
                   Project1__r.Company_Address__c,CRM_Executive_Contact_No__c FROM Booking__c WHERE Id = :bookingId  LIMIT 1 ];
        
        // ===================== BLOCK QUERY =====================
        Block__c block = null;

        if (booking.Block_Id__c != null) {
            block = [SELECT Id, Name, Email__c, Project_Address__c FROM Block__c WHERE Id = :booking.Block_Id__c LIMIT 1 ];
        }

        // ===================== BOOKING INFO WRAPPER =====================
        bookingInfo = new bookingInfoWrapper();
        
        bookingInfo.customerId = (booking.SLead__r != null && booking.SLead__r.Lead_ID__c != null) ? booking.SLead__r.Lead_ID__c : '';
        
        bookingInfo.customerName = booking.First_Applicant_Name__c != null ? booking.First_Applicant_Name__c : '';
        
        bookingInfo.unitNo = booking.Unit_No__c != null ? booking.Unit_No__c : '';
        
        bookingInfo.block = booking.Block_Name__c != null ? booking.Block_Name__c : '';
        
        bookingInfo.project = (booking.Project1__r != null) ? booking.Project1__r.Name : '';
        
        bookingInfo.email = (block != null && block.Email__c != null) ? block.Email__c : '';
        
        bookingInfo.projectAddress = (block != null && block.Project_Address__c != null) ? block.Project_Address__c : '';
        
        bookingInfo.webAddress = 'www.trifectaprojects.com';
        
        bookingInfo.contactNo = booking.CRM_Executive_Contact_No__c != null ? booking.CRM_Executive_Contact_No__c : '';
        
        bookingInfo.companyAddress = (booking.Project1__r != null && booking.Project1__r.Company_Address__c != null) ? booking.Project1__r.Company_Address__c : '';
        
        
        // ===================== CO APPLICANTS =====================
        coapplicants = [
            SELECT Name, Salutation__c
            FROM Co_Applicant__c
            WHERE Booking__c = :bookingId
        ];

        if (!coapplicants.isEmpty()) {
            firstCoApplicant = coapplicants[0];
        }
              
        List<Payment_Schedule__c> psRecordList = [
            SELECT Id, Name, S_No__c, Completed_Date__c,
            Payment_percent__c, Last_Payment_Schedule__c,
            AmountB__c,Pending_Amount__c
            FROM Payment_Schedule__c
            WHERE Status__c = 'Completed'
            AND Booking__c = :booking.Id
            ORDER BY S_No__c DESC
        ];
        

        if (psRecordList.isEmpty()) {
            currentCompletedStage = 'No milestone completed';
            currentCompletedStage = '';
            demandDueDate = null;
            totalAmountPayableInWords = 'Zero';
            System.debug('No milestone completed for the booking.');
            return;
        }
        
        Payment_Schedule__c psRecord = psRecordList[0]; 
        
        if (psRecord != null) {
            currentCompletedStage = psRecord.Name;
        }
        
    }

}