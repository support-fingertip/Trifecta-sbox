public class ConsolidatedReceiptController {

    public Booking__c booking { get; set; }
    public Decimal totalAmount { get; set; }
    public String receiptAmountInWords { get; set; }
    public String totalAmountFormatted { get; set; }
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
        public String  paymentType { get; set; } // added for grouping
        public Boolean isNegative { get; set; }
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
        public String companyName { get; set; }
    }

    public ConsolidatedReceiptController(ApexPages.StandardController stdController) {

        Id bookingId = (Id) stdController.getId();
        String typeVal = ApexPages.currentPage().getParameters().get('type');
        
        // ===================== BOOKING QUERY =====================
        booking = [
            SELECT Id,
            Name,
            Total_received_Amount__c,
            SLead__r.Lead_ID__c,
            Block_Id__c,
            First_Applicant_Name__c,
            Unit_No__c,
            Project_Type__c,
            Block_Name__c,
            Project1__r.Name,
            Owner_Email__c,
            Booing_Executive_Email_Id__c,
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
                SELECT Id, Name, Email__c,Project_Address__c,Company_Address__c,
                Land_Company_Name__c,Construction_Company_Name__c,Company_Name__c,Project_Name__c
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
            (block.Project_Name__c != null)
            ? block.Project_Name__c : '';

        bookingInfo.email =
            (booking != null && booking.Owner_Email__c != null)
            ? booking.Owner_Email__c : '';

        bookingInfo.projectAddress =
            (block != null && block.Project_Address__c != null)
            ? block.Project_Address__c : '';

        bookingInfo.webAddress = 'www.trifectaprojects.com';

        bookingInfo.contactNo =
            booking.CRM_Executive_Contact_No__c != null
            ? booking.CRM_Executive_Contact_No__c : '';
        
        bookingInfo.companyAddress = (block.Company_Address__c != null) 
            ? block.Company_Address__c.replaceAll('(?i),?\\s*Bangalore', '<br/>Bangalore')
            : '';

        bookingInfo.companyName = 'TRIFECTA PROJECTS PVT LTD';
        if(booking.Project_Type__c == 'Villas')
        {
            if(typeVal =='Land')
            {
                bookingInfo.companyName =(block.Land_Company_Name__c != null) ? block.Land_Company_Name__c : '';
            }
            else if(typeVal =='Construction')
            {
                bookingInfo.companyName =(block.Construction_Company_Name__c != null) ? block.Construction_Company_Name__c: '';
            }
            
        }
        else
        {
            bookingInfo.companyName =(block.Company_Name__c != null ) ? block.Company_Name__c : '';
        }
        
        
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
        List<Receipt_Line_Item__c> repLst = new List<Receipt_Line_Item__c>();
		if(typeVal =='Construction' || typeVal =='Land')
        {
            repLst = [
                SELECT Id,
                Name,
                Amount__c,
                Received_Amount__c,
                Payment_schedule__r.Name,
                Mode_of_Payment__c,
                Cheque_no_Transaction_Number__c,
                Cheque_Date__c,
                Receipt__c, 
                Payment_Type__c,
                Bank_Name__c,
                Receipt__r.Name,
                Receipt__r.Receipt_Date__c,
                Booking__c
                FROM Receipt_Line_Item__c
                WHERE Booking__c = :bookingId
                AND Approval_Status__c = 'Approved'
 				AND Payment_schedule__r.Type__c = :typeVal
                Order by CreatedDate
            ];
        }
        else
        {
            repLst = [
                SELECT Id,
                Name,
                Amount__c,
                Received_Amount__c,
                Payment_schedule__r.Name,
                Mode_of_Payment__c,
                Cheque_no_Transaction_Number__c,
                Cheque_Date__c,
                Bank_Name__c,
                Receipt__c,
                Payment_Type__c,
                Receipt__r.Name,
                Receipt__r.Receipt_Date__c,
                Booking__c
                FROM Receipt_Line_Item__c
                WHERE Booking__c = :bookingId
                AND Approval_Status__c = 'Approved'
                Order by CreatedDate
            ];
        }
       

        List<ReceiptWrapper> reppList = new List<ReceiptWrapper>();

        // Group by Receipt__c only — one row per Receipt. Metadata fields
        // (mode/instrument/bank/etc) come from the first encountered line of
        // the receipt. Sign is negative iff any line of the receipt is a
        // 'TDS Refund' (Phase 2 makes TDS Refund a solo-row receipt, so this
        // is equivalent to "the receipt is a refund receipt").
        Map<Id, Decimal>              receiptToTotal    = new Map<Id, Decimal>();
        Map<Id, Receipt_Line_Item__c> receiptToMeta     = new Map<Id, Receipt_Line_Item__c>();
        Map<Id, Boolean>              receiptIsNegative = new Map<Id, Boolean>();
        List<Id>                      orderedReceiptIds = new List<Id>();

        for (Receipt_Line_Item__c re : repLst) {
            Id rId = re.Receipt__c;
            Decimal amt = re.Received_Amount__c != null ? re.Received_Amount__c : 0;

            if (!receiptToTotal.containsKey(rId)) {
                receiptToTotal.put(rId, 0);
                receiptToMeta.put(rId, re);
                receiptIsNegative.put(rId, false);
                orderedReceiptIds.add(rId);
            }
            receiptToTotal.put(rId, receiptToTotal.get(rId) + amt);
            if (re.Payment_Type__c == 'TDS Refund') {
                receiptIsNegative.put(rId, true);
            }
        }

        for (Id rId : orderedReceiptIds) {
            Receipt_Line_Item__c meta = receiptToMeta.get(rId);
            Decimal sumAmt            = receiptToTotal.get(rId);
            Boolean isNeg             = receiptIsNegative.get(rId);

            if (isNeg) {
                totalAmount -= sumAmt;
            } else {
                totalAmount += sumAmt;
            }

            ReceiptWrapper rw  = new ReceiptWrapper();
            rw.paymentType     = isNeg ? 'TDS Refund' : 'Receipt';
            rw.isNegative      = isNeg;
            rw.receiptDate     = meta.Receipt__r != null ? meta.Receipt__r.Receipt_Date__c : null;
            rw.receiptAmount   = isNeg
                ? '-' + sumAmt.setScale(2).format() 
                : sumAmt.setScale(2).format();
            rw.modeOfPayment   = meta.Mode_of_Payment__c;
            rw.instruMentNo    = meta.Cheque_no_Transaction_Number__c;
            rw.payNameName     = meta.Payment_schedule__r != null ? meta.Payment_schedule__r.Name : '';
            rw.bankName        = meta.Bank_Name__c;
            rw.receiptNo       = meta.Receipt__r != null ? meta.Receipt__r.Name : '';
            rw.refdate         = meta.Cheque_Date__c != null
                ? meta.Cheque_Date__c
                : (meta.Receipt__r != null ? meta.Receipt__r.Receipt_Date__c : null);
            reppList.add(rw);
        }

        repList = reppList;
        
        totalAmountFormatted = totalAmount != null
            ? totalAmount.setScale(0, RoundingMode.HALF_UP).format()
            : '0';
        // ===================== AMOUNT IN WORDS =====================
        NumberTOWordConvertion conversion =
            new NumberTOWordConvertion();

        receiptAmountInWords =
            totalAmount != null
            ? conversion.getNumberTOWordConvertion(totalAmount)
            : null;
    }
}