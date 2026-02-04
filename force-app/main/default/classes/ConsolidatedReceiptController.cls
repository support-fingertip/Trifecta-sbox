public class ConsolidatedReceiptController {
    public Booking__c booking { get; set; }
    public String totalAmount { get; set; }
    public String receiptAmountInWords { get; set; }
    public String receiptAmountInString { get; set; }
    public List<ReceiptWrapper> repList {get;set;}
    public List<AdditionalChargesWrapper> acwBookList {get;set;}
    public List<Co_Applicant__c> coapplicants { get; set; }
    public Co_Applicant__c firstCoApplicant { get; set; }
    public class ReceiptWrapper{
        public date receiptDate{get;set;}
        public String receiptAmount{get;set;}
        public String modeOfPayment{get;set;}
        public String instruMentNo{get;set;}
        public String payNameName{get;set;}
        
        
    }
    public class AdditionalChargesWrapper{
        public date acDate{get;set;}
        public String acAmount{get;set;}
        public String acName{get;set;}
    }
    public ConsolidatedReceiptController(ApexPages.StandardController stdController) {
        // Get the current record ID from the standard controller
        Id bookingId = (Id)stdController.getId();
        
        // Query the Booking__c object with related Receipts__r
        booking = [SELECT Id, Name,Total_received_Amount__c,
                   (SELECT Id,Receipt__r.Receipt_Date__c,Bank_Name__c, Name,Cheque_no_Transaction_Number__c,Mode_of_Payment__c,Amount__c 
                    FROM Receipt_Line_Items__r where Approval_Status__c = 'Approved' ORDER BY Name ASC),(select id,name,Amount__c from Additional_Charges__r) 
                   FROM Booking__c WHERE Id = :bookingId];
        
        coapplicants=[
            SELECT Name, Salutation__c
            FROM Co_Applicant__c WHERE Booking__c = :bookingId  ];
        
        if (!coapplicants.isEmpty()) {
            firstCoApplicant = coapplicants[0];
        }
        receiptAmountInString = booking.Total_received_Amount__c.setScale(2).format(); 
        List<Receipt_Line_Item__c> repLst = [select id,name,Amount__c,Received_Amount__c,Payment_schedule__r.Name,Mode_of_Payment__c,Cheque_no_Transaction_Number__c,Bank_Name__c,Receipt__r.Receipt_Date__c,Booking__c from Receipt_Line_Item__c where Booking__c =: bookingId and  Approval_Status__c = 'Approved'];
        //List<Additional_Charge__c> acList = [select id,name,Amount__c,Date__c from Additional_Charge__c where Booking__c =:bookingId ];
        List<ReceiptWrapper> reppList = new List<ReceiptWrapper>();
        List<AdditionalChargesWrapper> acwList = new List<AdditionalChargesWrapper>();
        for(Receipt_Line_Item__c re : repLst){
            ReceiptWrapper rw = new ReceiptWrapper();
            rw.receiptDate = re.Receipt__r.Receipt_Date__c;
            rw.receiptAmount = re.Amount__c.setScale(2).format();
            rw.modeOfPayment = re.Mode_of_Payment__c;
            rw.instruMentNo = re.Cheque_no_Transaction_Number__c;
            rw.payNameName = re.Payment_schedule__r.Name;
            reppList.add(rw);
        }
        repList = reppList;
        acwBookList = acwList;
        // Format total amount and convert to words
        totalAmount = booking.Total_received_Amount__c.setScale(2).format();
        NumberTOWordConvertion nwcObj = new NumberTOWordConvertion();
        receiptAmountInWords = nwcObj.getNumberTOWordConvertion(booking.Total_received_Amount__c);
    }
    
}