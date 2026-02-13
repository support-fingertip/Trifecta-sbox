public class ConsolidatedReceiptController {

    public Booking__c booking { get; set; }
    public Decimal totalAmount { get; set; }
    public String receiptAmountInWords { get; set; }
    public List<ReceiptWrapper> repList { get; set; }
    public List<Co_Applicant__c> coapplicants { get; set; }
    public Co_Applicant__c firstCoApplicant { get; set; }

    public class ReceiptWrapper {
        public Date receiptDate { get; set; }
        public String receiptAmount { get; set; }
        public String modeOfPayment { get; set; }
        public String instruMentNo { get; set; }
        public String payNameName { get; set; }
        public String bankName { get; set; }
        public String receiptNo { get; set; }
        public Date refdate { get; set; }
    }

    public bookingInfoWrapper bookingInfo { get; set; }

    public class bookingInfoWrapper {
        public String receiptNo { get; set; }
        public String customerId { get; set; }
        public String customerName { get; set; }
        public String unitNo { get; set; }
        public String block { get; set; }
        public Date receiptDate { get; set; }
        public String project { get; set; }

        public String projectAddress { get; set; }
        public String email { get; set; }
        public String contactNo { get; set; }
        public String webAddress { get; set; }
        public String companyAddress { get; set; }
    }

    public ConsolidatedReceiptController(ApexPages.StandardController stdController) {

        Id bookingId = (Id) stdController.getId();

        // ===================== BOOKING QUERY =====================
        booking = [
            SELECT Id,
                   Name,
                   Total_received_Amount__c,
                   SLead__r.Lead_ID__c,
                   Block_Id__c,
                   First_Applicant_Name__c,
                   Unit_No__c,
                   Block_Name__c,
                   Project1__r.Name,
                   Project1__r.Company_Address__c,
                   CRM_Executive_Contact_No__c
            FROM Booking__c
            WHERE Id = :bookingId
            LIMIT 1
        ];

        // ===================== BLOCK QUERY =====================
        Block__c block = null;

        if (booking.Block_Id__c != null) {
            block = [
                SELECT Id, Name, Email__c, Project_Address__c
                FROM Block__c
                WHERE Id = :booking.Block_Id__c
                LIMIT 1
            ];
        }

        // ===================== BOOKING INFO WRAPPER =====================
        bookingInfo = new bookingInfoWrapper();

        bookingInfo.customerId =
            (booking.SLead__r != null && booking.SLead__r.Lead_ID__c != null)
            ? booking.SLead__r.Lead_ID__c : '';

        bookingInfo.customerName =
            booking.First_Applicant_Name__c != null
            ? booking.First_Applicant_Name__c : '';

        bookingInfo.unitNo =
            booking.Unit_No__c != null
            ? booking.Unit_No__c : '';

        bookingInfo.block =
            booking.Block_Name__c != null
            ? booking.Block_Name__c : '';

        bookingInfo.receiptDate = System.today();

        bookingInfo.project =
            (booking.Project1__r != null)
            ? booking.Project1__r.Name : '';

        bookingInfo.email =
            (block != null && block.Email__c != null)
            ? block.Email__c : '';

        bookingInfo.projectAddress =
            (block != null && block.Project_Address__c != null)
            ? block.Project_Address__c : '';

        bookingInfo.webAddress = 'www.trifectaprojects.com';

        bookingInfo.contactNo =
            booking.CRM_Executive_Contact_No__c != null
            ? booking.CRM_Executive_Contact_No__c : '';

        bookingInfo.companyAddress =
            (booking.Project1__r != null &&
             booking.Project1__r.Company_Address__c != null)
            ? booking.Project1__r.Company_Address__c : '';

        // ===================== CO APPLICANTS =====================
        coapplicants = [
            SELECT Name, Salutation__c
            FROM Co_Applicant__c
            WHERE Booking__c = :bookingId
        ];

        if (!coapplicants.isEmpty()) {
            firstCoApplicant = coapplicants[0];
        }

        // ===================== RECEIPT LINE ITEMS =====================
        totalAmount = 0;

        List<Receipt_Line_Item__c> repLst = [
            SELECT Id,
            Name,
            Amount__c,
            Received_Amount__c,
            Payment_schedule__r.Name,
            Mode_of_Payment__c,
            Cheque_no_Transaction_Number__c,
            Cheque_Date__c,
            Bank_Name__c,
            Receipt__r.Name,
            Receipt__r.Receipt_Date__c,
            Booking__c
            FROM Receipt_Line_Item__c
            WHERE Booking__c = :bookingId
            AND Approval_Status__c = 'Approved'
            AND Payment_Type__c != 'TDS'
        ];

        List<ReceiptWrapper> reppList = new List<ReceiptWrapper>();

        for (Receipt_Line_Item__c re : repLst) {

            if (re.Received_Amount__c != null) {
                totalAmount += re.Received_Amount__c;
            }

            ReceiptWrapper rw = new ReceiptWrapper();

            rw.receiptDate = re.Receipt__r != null
                ? re.Receipt__r.Receipt_Date__c
                : null;

            rw.receiptAmount = re.Received_Amount__c != null
                ? re.Received_Amount__c.setScale(2).format()
                : '0.00';

            rw.modeOfPayment = re.Mode_of_Payment__c;
            rw.instruMentNo = re.Cheque_no_Transaction_Number__c;
            rw.payNameName = re.Payment_schedule__r != null ? re.Payment_schedule__r.Name : '';

            rw.bankName = re.Bank_Name__c;
            rw.receiptNo =  re.Receipt__r != null ?  re.Receipt__r.Name : '';
            rw.refdate =   re.Cheque_Date__c != null ? re.Cheque_Date__c : re.Receipt__r != null
                ? re.Receipt__r.Receipt_Date__c
                : null;
            reppList.add(rw);
        }

        repList = reppList;

        // ===================== AMOUNT IN WORDS =====================
        NumberTOWordConvertion conversion =
            new NumberTOWordConvertion();

        receiptAmountInWords =
            totalAmount != null
            ? conversion.getNumberTOWordConvertion(totalAmount)
            : null;
    }
}