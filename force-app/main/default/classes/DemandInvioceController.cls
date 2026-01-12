public class DemandInvioceController {
    public Booking__c book {get; set;} 
        public Booking__c booking { get; set; }
    public String bookingId {get; set;}
    public String formattedPin {Get; set;}
    public String paymentscheudlename {Get; set;}
    public String formattedPostalCode {get; set;}
    public Decimal totAmtDueTillPrevMilestone { get; set; }
    public Decimal paidTillPrevMilestone { get; set; }
    public Decimal balanceDueTillPrevMilestone { get; set; }
    public Decimal interestDelayTillPrevious { get; set; }
    public Decimal interestPaidTillPrevious { get; set; }
    public Decimal presentDue { get; set; }
    public Decimal balanceInterest { get; set; }
    public Decimal totalAmountPayable { get; set; }
    public String totalAmountPayableInWords { get; set; }
    public String currentCompletedStage { get; set; }
    public Date currentCompletedStageDate { get; set; }
    public String currentMilestoneNumber { get; set; }
    public String milestoneAmountInWords { get; set; }
    public Date demandDueDate { get; set; }
    public Decimal currentMilestonePaymentPercent { get; set; }
    public Decimal milestonePaymentPercentTill { get; set; }
    public Decimal TDSonePercentage { get; set; }
    
    public Decimal totalAmountWithoutInterest { get; set; }
    public Decimal valueOfSupply { get; set; }
    public Decimal landCost { get; set; }
    public Decimal taxableValue { get; set; }
    public Decimal cgst { get; set; }
    public Decimal sgst { get; set; }
    public Decimal interestAmount { get; set; } // this can be your balanceInterest
    public String  formattedCurrentDate {get; set;}
    
    private Boolean bookingAddressesLoaded = false;
      private Address permanentAddress;
    
    public static Map<Integer, String> daySuffixMap = new Map<Integer, String>{1 => 'st', 2 => 'nd', 3 => 'rd', 21 => 'st', 22 => 'nd', 23 => 'rd', 31 => 'st'};
        
        public DemandInvioceController(ApexPages.StandardController controller) {
            
            totAmtDueTillPrevMilestone =0;
            paidTillPrevMilestone =0;
            balanceDueTillPrevMilestone =0;
            interestDelayTillPrevious =0;
            presentDue =0;
            totalAmountPayable =0;
            TDSonePercentage=0;
            interestPaidTillPrevious =0;
            totalAmountWithoutInterest = 0;
            valueOfSupply = 0;
            landCost = 0;
            taxableValue = 0;
            cgst = 0;
            sgst = 0;

            DateTime dt = DateTime.newInstance(Date.today(), Time.newInstance(0, 0, 0, 0));
            formattedCurrentDate = dt.format('MMM dd, yyyy');
            Id bookingRecordId = ApexPages.currentPage().getParameters().get('Id');
            if (bookingRecordId == null) {
                ApexPages.addMessage(new ApexPages.Message(ApexPages.Severity.ERROR, 'Booking record Id is null.'));
                return;
            }
             bookingId=bookingRecordId;
           
            fetchBookingDetails();
            Booking__c book = [SELECT Id, Name, Project__c,Project1__r.Name,GST__c  FROM Booking__c WHERE Id = :bookingRecordId];
            
            /*if (book.Permanent_Postal_Code__c != null) {
formattedPostalCode = String.valueOf(book.Permanent_Postal_Code__c.intValue());
}*/
            
            apartmentScheduleCalculations(book);
            
        }
    
    private void apartmentScheduleCalculations(Booking__c book) {
        
        list<Payment_Schedule__c> psRecordList = [
            SELECT Id, Name, S_No__c, Completed_Date__c, Payment_percent__c
            FROM Payment_Schedule__c
            WHERE Status__c = 'Completed' AND Booking__c = :book.Id
            ORDER BY S_No__c DESC
        ];
        
        if (psRecordList.isEmpty()) {
            // Handle case where no milestones are completed
            currentCompletedStage = 'No milestone completed';
            currentCompletedStageDate = null;
            demandDueDate = null;
            currentMilestonePaymentPercent = 0;
            currentMilestoneNumber = null;
            totalAmountPayableInWords = 'Zero';
            
            // Optionally, you could log or show a message
            System.debug('No milestone completed for the booking.');
            return;
        }
        
        Payment_Schedule__c psRecord = psRecordList[0]; 
        paymentscheudlename=psRecord.Name;
        if (psRecord != null) {
            currentCompletedStage = psRecord.Name;
            currentCompletedStageDate = psRecord.Completed_Date__c;
            demandDueDate = System.today().addDays(7);
            currentMilestonePaymentPercent = psRecord.Payment_percent__c != null ? psRecord.Payment_percent__c.setScale(0) : 0;
            
            Decimal stNumber = psRecord.S_No__c;
            if (stNumber != null) {
                currentMilestoneNumber = getMilestoneLabel(stNumber.intValue());
            }

            AggregateResult[] aggregateResults = [
                SELECT SUM(Pending_Amount__c) totalPendingAmount, SUM(Interest_Amount__c) totalInterestAmount,
                SUM(AmountB__c) totalPayableAmount,
                SUM(Interest_Up_to_Date__c) totalInterestUplodate, SUM(Interest_Paid__c) totalInterestPaid,
                SUM(Payment_percent__c) paymentPercentageTill
                FROM Payment_Schedule__c
                WHERE Status__c = 'Completed' 
                AND S_No__c != :psRecord.S_No__c 
                AND Booking__c = :book.Id
            ];
            system.debug('aggregateResults'+aggregateResults);
            Decimal totalPendingAmount = 0;
            Decimal totalInterestAmount = 0;
            Decimal totalPayableAmount = 0;
            Decimal totalReceivedAmount = 0;
            Decimal paidPreMilestone = 0;
            Decimal totalInterestUplodateAmount = 0;
            Decimal totalInterestPaid = 0;
            Decimal waveOff = 0;
            Decimal milestonePaymentPercent = 0;
            Decimal balanceDueTillPrevMilestoneMod = 0;
            Decimal milestonePaymentPercentResult =0;
            if (!aggregateResults.isEmpty()) {
                totalPendingAmount = (Decimal) aggregateResults[0].get('totalPendingAmount') != null ? (Decimal) aggregateResults[0].get('totalPendingAmount') : 0;
                totalInterestAmount = (Decimal) aggregateResults[0].get('totalInterestAmount') != null ? (Decimal) aggregateResults[0].get('totalInterestAmount') : 0;
                totalPayableAmount = (Decimal) aggregateResults[0].get('totalPayableAmount') != null ? (Decimal) aggregateResults[0].get('totalPayableAmount') : 0;
                totalInterestUplodateAmount = (Decimal) aggregateResults[0].get('totalInterestUplodate') != null ? (Decimal) aggregateResults[0].get('totalInterestUplodate') : 0;
                totalInterestPaid = (Decimal) aggregateResults[0].get('totalInterestPaid') != null ? (Decimal) aggregateResults[0].get('totalInterestPaid') : 0;
                milestonePaymentPercent = aggregateResults[0].get('paymentPercentageTill') != null ? (Decimal) aggregateResults[0].get('paymentPercentageTill') : 0;
            }
            system.debug('paidPreMilestone'+paidPreMilestone);
            totAmtDueTillPrevMilestone = totalPayableAmount;
            interestPaidTillPrevious = totalInterestPaid;
            interestDelayTillPrevious = (totalInterestUplodateAmount > 0) ? (totalInterestUplodateAmount) : totalInterestAmount;
            
            double paidTotalAmount = 0;
            AggregateResult presentDueResult = [
                SELECT SUM(AmountB__c) totalAmountB,SUM(Payment_percent__c) paymentPercentageTill
                FROM Payment_Schedule__c
                WHERE S_No__c = :psRecord.S_No__c
                AND Booking__c = :book.Id
            ];
            Decimal presentDueAmount = 0;
            if (presentDueResult != null && presentDueResult.get('totalAmountB') != null) {
                presentDueAmount = (Decimal) presentDueResult.get('totalAmountB');
            }
            if (presentDueResult != null && presentDueResult.get('paymentPercentageTill') != null) {
                milestonePaymentPercentResult = milestonePaymentPercent + currentMilestonePaymentPercent;
            }
            
            /* if (book.Total_Interest_Waive_Off__c != null) {
waveOff = book.Total_Interest_Waive_Off__c;
}*/
            
            AggregateResult totalReceied = [
                SELECT SUM(Received_Amount1__c) totalReceivedAmount
                FROM Payment_Schedule__c
                WHERE Booking__c = :book.Id
            ];
            
            if (totalReceied != null && totalReceied.get('totalReceivedAmount') != null) {
                paidTotalAmount = (Decimal) totalReceied.get('totalReceivedAmount');
            }
            /* if (book.Debit_Amount__c != null){
paidTotalAmount-= book.Debit_Amount__c;
}*/
            paidTillPrevMilestone =  paidTotalAmount;   
            balanceDueTillPrevMilestoneMod = totalPayableAmount - paidTotalAmount;
            if(balanceDueTillPrevMilestoneMod > 0){
                balanceDueTillPrevMilestone = totalPayableAmount - paidTotalAmount;
            }
            milestonePaymentPercentTill = milestonePaymentPercentResult.setScale(0);
            presentDue = presentDueAmount;
            
            Decimal gstPercentage = (book.GST__c != null) ? book.GST__c / 100 : 0;
            Decimal amountExcludingGST = presentDue / (1 + gstPercentage);
            TDSonePercentage = paidTotalAmount > 4999999 ? (amountExcludingGST * 0.01).setScale(0): 0;
            
            balanceInterest = interestDelayTillPrevious - interestPaidTillPrevious - waveOff;
            
            double totalAmount = 0;
            
            Decimal calculatedAmountWithoutInterest = balanceDueTillPrevMilestoneMod + presentDue/* - TDSonePercentage*/;
            System.debug(calculatedAmountWithoutInterest);
            if (calculatedAmountWithoutInterest > 0) {
                totalAmountWithoutInterest = calculatedAmountWithoutInterest.setScale(0);
            } else {
                totalAmountWithoutInterest = 0;
            }            
            if (totalAmountWithoutInterest != null && totalAmountWithoutInterest > 0) {
                taxableValue = (totalAmountWithoutInterest / (1 + gstPercentage)).setScale(1);
                cgst = ((totalAmountWithoutInterest - taxableValue)/2).setScale(1);
                sgst = ((totalAmountWithoutInterest - taxableValue)/2).setScale(1);
            }
            
            
            totalAmount = (balanceDueTillPrevMilestoneMod /*+ balanceInterest*/ + presentDue/* - TDSonePercentage*/).setScale(0) ;
            
            if(totalAmount > -1){
                totalAmountPayable = totalAmountWithoutInterest;
            }
            
            NumberTOWordConvertion convert = new NumberTOWordConvertion();
            if (totalAmountPayable != null && totalAmountPayable > -1) {
                totalAmountPayableInWords = convert.getNumberTOWordConvertion(totalAmountPayable);
            }
            if (presentDue != null && presentDue > -1) {
                milestoneAmountInWords = convert.getNumberTOWordConvertion(presentDue);
            }
        }
    }
    public static String getMilestoneLabel(Integer sNo) {
        if (sNo == null) {
            return 'Invalid milestone';
        }
        // Determine the suffix, default to 'th'
        String suffix = daySuffixMap.containsKey(sNo) ? daySuffixMap.get(sNo) : 'th';
        
        return sNo + suffix;
    }
    public void  fetchBookingDetails(){
         booking = [Select Id,
                   First_Applicant_Name__c,
                   Agreement_Execution_Date__c,
                   S__c,
                   Son_Daughter_Wife_of1__c,
                   PAN_Number__c,
                   Agreement_Executed_Date__c,
                   Aadhar_No__c,
                   Address__c,
                   Date_of_Birth1__c,
                   Son_Daughter_Wife_of__c,
                   Booking_Amount__c,
                   GRAND_TOTAL__c,
                   Permanent_Address1__c,
                   Correspondence_Address__Street__s,
                   Correspondence_Address__City__s,
                   Correspondence_Address__PostalCode__s,
                   Correspondence_Address__StateCode__s,
                   Pincode1__c,
                   Permanent_Address2__c,
                   Plot__c
                   
                   
                   From Booking__c Where Id=:bookingId];
    }
   
    private void loadBookingAddresses() {
        if (bookingAddressesLoaded) return;
        
        Booking__c b = [
            SELECT Permanent_Address2__c,
            Correspondence_Address__c,
            Office_Address1__c
            FROM Booking__c
            WHERE Id = :booking.Id
            LIMIT 1
        ];
        
        permanentAddress      = b.Permanent_Address2__c;
        
        bookingAddressesLoaded = true;
    }
    public String getPermanentFullAddress() {
        loadBookingAddresses();            // you already have this
        return formatAddress(permanentAddress);
    }
    private String formatAddress(Address addr) {
    if (addr == null) return '';
    
    List<String> parts = new List<String>();
    
    if (!String.isBlank(addr.street))  parts.add(addr.street);
    if (!String.isBlank(addr.city))    parts.add(addr.city);
    if (!String.isBlank(addr.state))   parts.add(addr.state);
    if (!String.isBlank(addr.postalcode))   parts.add(addr.postalcode);
    if (!String.isBlank(addr.country)) parts.add(addr.country);
    
    return String.join(parts, ', ');
}

    
}