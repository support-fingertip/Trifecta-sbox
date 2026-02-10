/****************************************************************
* Class Name   : ReceiptVFPController
* Company      : Fingertipplus
* Created Date : 06-02-2026
* @description : Controller for Receipt Visualforce page which:
*                - Retrieves receipt and related booking details
*                - Converts total amount into words
*                - Fetches first co-applicant information
*                - Loads receipt line items excluding TDS
*                - Calculates total received amount for display
* @author      : Durga Prasad
*
* Change Log:
* ----------------------------------------------------------------
* Ver | Author        | Date        | Description
* ----------------------------------------------------------------
* 1.0 | Durga Prasad | 06-02-2026  | Initial version
* ----------------------------------------------------------------
*****************************************************************/
public class ReceiptVFPController {

    public Id receiptId { get; set; }
    public String amountInWords { get; set; }
    public Co_Applicant__c firstCoApplicant { get; set; }
  
    public List<Receipt_Line_Item__c> receiptLineItems { get; set; }
    public Decimal totalReceivedAmount { get; set; }
    public ReceiptInfoWrapper receiptInfo { get; set; }
    
    public class ReceiptInfoWrapper {
        
        public String receiptNo { get; set; }
        public String customerId { get; set; }
        public String customerName { get; set; }
        public String unitNo { get; set; }
        public String block { get; set; }
        public String receiptDate { get; set; }
        public String project { get; set; }
        
        public String projectAddress { get; set; }
        public String email { get; set; }
        public String contactNo { get; set; }
        public String webAddress { get; set; }
        public String companyAddress { get; set; }
        
        // Constructor
        public ReceiptInfoWrapper() { }
    }

    /**
     * Method Name  : ReceiptVFPController (Constructor)
     * Description  : Initializes data required for Receipt Visualforce page.
     *
     * Functionality:
     * 1. Retrieves Receipt record and related booking/plot details.
     * 2. Converts total received amount into words format.
     * 3. Fetches first co-applicant linked to the booking.
     * 4. Fetches receipt line items excluding TDS payments.
     * 5. Calculates total received amount from line items.
     *
     * Parameters:
     * @param stdController - StandardController instance from VF page
     *
     * Used From:
     * - Receipt Visualforce Page Controller
     */
    public ReceiptVFPController(ApexPages.StandardController stdController) {
        
        receiptId = stdController.getId();
        
        // Retrieve Receipt record with all required relationships
        Receipt__c receiptRecord = [
            SELECT Name, Total_Received_Amount__c, Booking__c,
            Booking__r.Plot__r.Name,
            Booking__r.First_Applicant_Name__c, Booking__r.SLead__r.Lead_ID__c,
            Booking__r.Project1__r.Name,
            Booking__r.Project1__r.Company_Address__c,
            Booking__r.Unit_No__c, Booking__r.Block_Name__c,Booking__r.Block_Id__c,
            CreatedDate,Booking__r.CRM_Executive_Contact_No__c
            FROM Receipt__c
            WHERE Id = :receiptId
        ];
        
        //Block 
        Block__c block = [select Id,Name,Email__c,Project_Address__c from Block__c where Id =: receiptRecord.Booking__r.Block_Id__c];
        
        // Convert number to words – safe check
        NumberTOWordConvertion conversion = new NumberTOWordConvertion();
        // Initialize wrapper
        receiptInfo = new ReceiptInfoWrapper();
        receiptInfo.receiptNo = receiptRecord.Name;
        receiptInfo.customerId = (receiptRecord.Booking__r != null && receiptRecord.Booking__r.SLead__r != null)
            ? receiptRecord.Booking__r.SLead__r.Lead_ID__c : '';
        receiptInfo.customerName = (receiptRecord.Booking__r != null && receiptRecord.Booking__r.First_Applicant_Name__c!= null)
            ? receiptRecord.Booking__r.First_Applicant_Name__c : '';
        receiptInfo.unitNo = (receiptRecord.Booking__r != null) ? receiptRecord.Booking__r.Unit_No__c : '';
        receiptInfo.block = (receiptRecord.Booking__r != null && receiptRecord.Booking__r.Block_Name__c != null)
            ? receiptRecord.Booking__r.Block_Name__c : '';
        receiptInfo.receiptDate = receiptRecord.CreatedDate != null ? String.valueOf(receiptRecord.CreatedDate.date()) : '';
        receiptInfo.project = (receiptRecord.Booking__r != null && receiptRecord.Booking__r.Project1__r != null)
            ? receiptRecord.Booking__r.Project1__r.Name : '';
        
        receiptInfo.email = (block != null && block.Email__c != null) ? block.Email__c  : '';
        receiptInfo.projectAddress = (block != null && block.Project_Address__c != null) ? block.Project_Address__c : '';
        
        receiptInfo.webAddress = 'www.trifectaprojects.com';
        receiptInfo.contactNo =  (receiptRecord.Booking__r != null && receiptRecord.Booking__r.CRM_Executive_Contact_No__c != null)
            ? receiptRecord.Booking__r.CRM_Executive_Contact_No__c : '';
        
        receiptInfo.companyAddress =  (receiptRecord.Booking__r != null && receiptRecord.Booking__r.Project1__r.Company_Address__c != null)
            ? receiptRecord.Booking__r.Project1__r.Company_Address__c : ''; 
        
        
        
        // Initialize lists
        receiptLineItems = new List<Receipt_Line_Item__c>();
        totalReceivedAmount = 0;
        
        // Fetch related data only if Booking exists
        if (receiptRecord.Booking__c != null) {

            // Co-applicants
            List<Co_Applicant__c> coApplicants = [
                SELECT Name,
                       Salutation__c,
                       Date_of_Birth__c,
                       Spouse_Date_Of_Birth_coapp__c,
                       Spouse_Name__c,
                       Permanent_Address__c,
                       Communication_Address__c,
                       Pincode_office__c,
                       Other_Qualification__c,
                       Qualification__c,
                       Pincode_commmunication__c,
                       Pincode_permanent__c,
                       Other_Industry__c,
                       Office_Address__c,
                       Anniverssary_Date__c,
                       Son_Daughter_Wife_of__c,
                       Nationality__c,
                       Aadhar_Number__c,
                       Alternate_Contact_No__c,
                       Country_of_Residence__c,
                       Passport_Number__c,
                       PAN_Number__c,
                       Email__c,
                       Primary_Phone__c,
                       Office_Pincode__c,
                       Residential_Status__c,
                       Profession__c,
                       Industry__c,
                       Employeed_at__c,
                       Designation__c
                FROM Co_Applicant__c
                WHERE Booking__c = :receiptRecord.Booking__c
                ORDER BY CreatedDate ASC
                LIMIT 1
            ];
            
            if (!coApplicants.isEmpty()) {
                firstCoApplicant = coApplicants[0];
            }
            
            // Here TDS Amount we are Excluding into the receipt which is sending to the customer
            // TDS Customer will pay to GOVT but for the Calculation purpose we are Creating TDS as one of the receipt
            receiptLineItems = [
                SELECT Payment_Type__c,
                Cheque_no_Transaction_Number__c,
                Received_Amount__c,
                Bank_Name__c,
                Mode_of_Payment__c,
                Drawn_On__c,Receipt_Date__c,
                Payment_schedule__r.Name
                FROM Receipt_Line_Item__c
                WHERE Booking__c = :receiptRecord.Booking__c
                AND Payment_Type__c != 'TDS'
                AND Receipt__c = :receiptId
            ];
            
            // Calculate total received amount
            for (Receipt_Line_Item__c item : receiptLineItems) {
                if (item.Received_Amount__c != null) {
                    totalReceivedAmount += item.Received_Amount__c;
                }
            }
            amountInWords = totalReceivedAmount != null ?conversion.getNumberTOWordConvertion(totalReceivedAmount) : null;
            

        }
    }
}