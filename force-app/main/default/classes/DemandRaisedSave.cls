public class DemandRaisedSave {
    @AuraEnabled
    public static Demand_Raised__c getDemandRaised(id recordId){
        Demand_Raised__c demand = [SELECT 
                                   Id, Amount_Demanded__c, Booking__c, Current_Demand_amount__c, Name, Demanded_Date__c,Demand_Email_Content__c, 
                                   Due_Date__c, Grand_Total__c, Include_Interest__c, Payment_schedule__c, Previous_pendings__c,Interest_Till_Now__c
                                   FROM Demand_Raised__c WHERE id =: recordId LIMIT 1];
        return demand;
    }
    
    @AuraEnabled
    public static void ResendRaiseDemand(list<Id> recordIds){
        if(recordIds.size() > 0){
            try {
                DocumentandEmailController.sendEmailGenerateDemand(recordIds);
                List<Demand_Raised__c> recordsToUpdate = [SELECT Id, Demand_Email_Send__c FROM Demand_Raised__c WHERE Id IN :recordIds];
                for (Demand_Raised__c record : recordsToUpdate) {
                    record.Demand_Email_Send__c = true;
                }
                update recordsToUpdate;
            } catch (Exception e) {
                System.debug('Error during email sending: ' + e.getMessage());
                throw new AuraHandledException('Failed to resend demand. Please try again later.');
            }
        }
    }
    
    @AuraEnabled
    public Static String RaiseDemand(List<Id> bookingIds, Map<Id,String> emailContents, map<Id,List<String>> contentIds ) {
        
        String demandRaisedReturn='';
        
        // Check if the bookingIds list is not empty
        if (bookingIds == null || bookingIds.isEmpty()) {
            ApexPages.addMessage(new ApexPages.Message(ApexPages.Severity.ERROR, 'No Booking records provided.'));
            return 'No Booking records provided';
        }
        
        // Query all the Booking records based on the provided bookingIds
        List<Booking__c> bookings = [SELECT Id,Applicant_Name__c,Plot__r.Name, Total__c, Name, Project__c, GST__c,CRM_Manager__c,
                                     Project1__r.Name FROM Booking__c WHERE Id IN :bookingIds];
        
        // Check if there are any bookings returned
        if (bookings.isEmpty()) {
            ApexPages.addMessage(new ApexPages.Message(ApexPages.Severity.ERROR, 'No Booking records found.'));
            return 'No Booking records found';
        }
        
        // Split bookings based on Property_Type_For__c (Apartments and Villas)
        List<Booking__c> apartmentBookings = new List<Booking__c>();
        
        for (Booking__c book : bookings) {
            apartmentBookings.add(book);
        }
        
        // Call bulk apartment schedule calculations for apartment bookings
        if (!apartmentBookings.isEmpty()) {
            List<Demand_Raised__c> apartmentDemands = bulkScheduleCalculations(apartmentBookings,emailContents,contentIds);
            if (apartmentDemands != null && !apartmentDemands.isEmpty()) {
                demandRaisedReturn = 'Demand Raise records created';
            }
        }
        
        // Return the final list of all demands raised
        return demandRaisedReturn;
    }
    
    @TestVisible
    private Static List<Demand_Raised__c> bulkScheduleCalculations(List<Booking__c> bookings,Map<Id,String> emailContents, map<Id,List<String>> contentIds) {
        List<Demand_Raised__c> demands = new List<Demand_Raised__c>();
        Map<Id, Payment_Schedule__c> bookingLatestPaymentSchedules = new Map<Id, Payment_Schedule__c>();
        Map<Id, List<Payment_Schedule__c>> groupedByBooking = new Map<Id, List<Payment_Schedule__c>>();
        Map<Id, Booking__c> bookingProjectMap = new Map<Id, Booking__c>();
        map<id,Decimal> debitAmountMap = new map<id,Decimal>();
        map<id,Decimal> WaveOffMap = new map<id,Decimal>();
        
        for (Booking__c book : bookings) {
            bookingProjectMap.put(book.Id, book);
            //debitAmountMap.put(book.Id, book.Debit_Amount__c);
            //WaveOffMap.put(book.Id,book.Total_Interest_Waive_Off__c);
        }
        
        List<Payment_Schedule__c> psRecords = [
            SELECT Id, S_No__c, Is_Demanded__c,Completed_Date__c, Booking__c,Name,Payment_percent__c,Interest_Paid__c,Received_Amount1__c,Interest_Up_to_Date__c,AmountB__c,Interest_Amount__c,Pending_Amount__c
            FROM Payment_Schedule__c
            WHERE Status__c = 'Completed' AND Booking__c IN :bookings
            
        ];
        
        //system.debug('psRecords'+psRecords);
        
        for (Payment_Schedule__c ps : psRecords) {
            if (!groupedByBooking.containsKey(ps.Booking__c)) {
                groupedByBooking.put(ps.Booking__c, new List<Payment_Schedule__c>());
            }
            groupedByBooking.get(ps.Booking__c).add(ps);
        }
        
        for (Id bookingId : groupedByBooking.keySet()) {
            List<Payment_Schedule__c> schedules = groupedByBooking.get(bookingId);
            Decimal highestSNo = 0;
            Payment_Schedule__c latestps;
            for (Payment_Schedule__c schedule : schedules) {
                if (schedule.S_No__c != null && schedule.S_No__c > highestSNo) {
                    highestSNo = schedule.S_No__c;
                    latestps = schedule;
                }
            }
            bookingLatestPaymentSchedules.put(bookingId, latestps);         
        }
        
        List<AggregateResult> aggregateResults = [
            SELECT Booking__c, 
            SUM(Pending_Amount__c) totalPendingAmount, 
            SUM(Interest_Amount__c) totalInterestAmount,
            SUM(AmountB__c) totalPayableAmount, 
            SUM(Interest_Up_to_Date__c) totalInterestUplodate, 
            SUM(Received_Amount1__c) totalReceivedAmount,
            SUM(Interest_Paid__c) totalInterestPaid, 
            SUM(Payment_percent__c) paymentPercentageTill
            FROM Payment_Schedule__c
            WHERE Status__c = 'Completed' 
            AND Booking__c IN :bookings
            GROUP BY Booking__c
        ];
        
        Map<Id, AggregateResult> bookingToAggregateResultMap = new Map<Id, AggregateResult>();
        Map<Id, Decimal> bookingToPendingAmountMap = new Map<Id, Decimal>();
        Map<Id, Decimal> bookingToInterestAmountMap = new Map<Id, Decimal>();
        Map<Id, Decimal> bookingToPayableAmountMap = new Map<Id, Decimal>();
        Map<Id, Decimal> bookingToInterestUpToDateAmountMap = new Map<Id, Decimal>();
        Map<Id, Decimal> bookingToReceivedAmountMap = new Map<Id, Decimal>();
        Map<Id, Decimal> bookingToInterestPaidMap = new Map<Id, Decimal>();
        Map<Id, Decimal> bookingToPaymentPercentageMap = new Map<Id, Decimal>();
        
        for (AggregateResult result : aggregateResults) {
            Id bookingId = (Id) result.get('Booking__c');
            
            bookingToPendingAmountMap.put(bookingId, (Decimal) result.get('totalPendingAmount'));
            bookingToInterestAmountMap.put(bookingId, (Decimal) result.get('totalInterestAmount'));
            bookingToPayableAmountMap.put(bookingId, (Decimal) result.get('totalPayableAmount'));
            bookingToInterestUpToDateAmountMap.put(bookingId, (Decimal) result.get('totalInterestUplodate'));
            bookingToReceivedAmountMap.put(bookingId, (Decimal) result.get('totalReceivedAmount'));
            bookingToInterestPaidMap.put(bookingId, (Decimal) result.get('totalInterestPaid'));
            // Object percentVal = result.get('paymentPercentageTill');
            //Decimal paymentPercent = (percentVal != null) ? (Decimal) percentVal : 0;
            bookingToPaymentPercentageMap.put(bookingId, (Decimal) result.get('paymentPercentageTill'));
            
            bookingToAggregateResultMap.put(bookingId, result);
        }
        
        for (Id bookingId : bookingToPendingAmountMap.keySet()) {
            
            if (bookingLatestPaymentSchedules.containsKey(bookingId) && 
                bookingLatestPaymentSchedules.get(bookingId).Is_Demanded__c == true) {
                    continue;
                }
            
            system.debug('bookingLatestPaymentSchedules.get(bookingId).Pending_Amount__c'+ bookingLatestPaymentSchedules.get(bookingId));
            
            Decimal pendingAmount = bookingToPendingAmountMap.get(bookingId) - bookingLatestPaymentSchedules.get(bookingId).Pending_Amount__c;
            Decimal interestAmount = bookingToInterestAmountMap.get(bookingId) - bookingLatestPaymentSchedules.get(bookingId).Interest_Amount__c;
            Decimal payableAmount = bookingToPayableAmountMap.get(bookingId) - bookingLatestPaymentSchedules.get(bookingId).AmountB__c;
            
            Decimal receivedAmount = bookingToReceivedAmountMap.get(bookingId);
            
            //if(debitAmountMap.get(bookingId) != null){
            //     receivedAmount -= debitAmountMap.get(bookingId);
            // }
            
            Decimal PaymentPercentage = bookingToPaymentPercentageMap.get(bookingId);
            Decimal CurrentPaymentPercentage = bookingLatestPaymentSchedules.get(bookingId).Payment_percent__c;
            Decimal totalInterestUplodateAmount = bookingToInterestUpToDateAmountMap.get(bookingId) - bookingLatestPaymentSchedules.get(bookingId).Interest_Up_to_Date__c;
            Decimal totalInterestPaid = bookingToInterestPaidMap.get(bookingId);
            Decimal balanceDueTillPrevMilestoneMod = payableAmount - receivedAmount;
            Decimal balanceDueTillPrevMilestone = balanceDueTillPrevMilestoneMod > 0 ? balanceDueTillPrevMilestoneMod : 0;
            Decimal balanceInterest = totalInterestUplodateAmount - totalInterestPaid /*- WaveOffMap.get(bookingId)*/;
            Decimal presentDue = bookingLatestPaymentSchedules.get(bookingId).AmountB__c;
            
            Decimal gstPercentage = (bookingProjectMap.get(bookingId).GST__c  != null) ? bookingProjectMap.get(bookingId).GST__c : 0;
            Decimal amountExcludingGST = presentDue / (1 + gstPercentage);
            
            Decimal TDSonePercentage = receivedAmount > 4999999 ? (amountExcludingGST * 0.01).setScale(0): 0;
            
            String currentMilestone = bookingLatestPaymentSchedules.get(bookingId).Name;
            Date currentMilestoneCompletedDate = bookingLatestPaymentSchedules.get(bookingId).Completed_Date__c;
            String currentMilestoneNumber =getMilestoneLabel(bookingLatestPaymentSchedules.get(bookingId).S_No__c.intValue());
            Decimal totalFlatCost = bookingProjectMap.get(bookingId).Total__c;
            //id FinanceUser = bookingProjectMap.get(bookingId).Finance_User__c;
            Id currentMilestoneId = bookingLatestPaymentSchedules.get(bookingId).Id;
            
            Decimal actualTotalAmountPayable;
            actualTotalAmountPayable = (balanceDueTillPrevMilestoneMod/* + balanceInterest*/ + presentDue/* - TDSonePercentage*/).setScale(0);
            
            Decimal actualTotalWithoutInterest = (balanceDueTillPrevMilestoneMod + presentDue/* - TDSonePercentage*/).setScale(0);
            Decimal TotalWithoutInterest = actualTotalWithoutInterest > 0 ? actualTotalWithoutInterest : 0;
            
            Decimal totalAmountPayable = actualTotalAmountPayable > 0 ? actualTotalAmountPayable : 0;
            
            NumberTOWordConvertion convert = new NumberTOWordConvertion();
            String totalAmountPayableInWords = convert.getNumberTOWordConvertion(totalAmountPayable);
            String TotalWithoutInterestInwords = convert.getNumberTOWordConvertion(TotalWithoutInterest);
            String totaCurrentMilestoneAmount = convert.getNumberTOWordConvertion(presentDue);
            
            String content = emailContents.get(bookingId);            
            
            if (String.isBlank(content)) {
                content = ''
                    + '<div style="color: black;">'
                    + 'Dear <strong>' + bookingProjectMap.get(bookingId).Applicant_Name__c + '</strong>,'
                    + '</div><br/>'
                    + '<div>'
                    + '<strong>Greetings from Zuari !!</strong><br/><br/>'
                    + 'Hope this mail finds you in good health and spirit.<br/><br/>'
                    + '<strong>Sub: Requisition for release of instalment.</strong><br/>'
                    + '<strong>Ref: ' + bookingProjectMap.get(bookingId).Project1__r.Name + ', Apartment No. ' + bookingProjectMap.get(bookingId).Plot__r.Name + ' - ' + bookingProjectMap.get(bookingId).Applicant_Name__c + '</strong><br/><br/>'
                    + 'This is to remind you that an amount of <strong>INR '+totalAmountPayable+'/-</strong> ('+totalAmountPayableInWords+') will be due against apartment No. '
                    + bookingProjectMap.get(bookingId).Plot__r.Name + ' at <strong>' + bookingProjectMap.get(bookingId).Project1__r.Name + '</strong>.<br/><br/>'
                    + 'Request you to kindly release the amount <br/><br/>'/* to our below mentioned bank account:

+ '<table style="border-collapse: collapse; width: 100%; font-size: 14px;" border="1">'
+ '<tr><th style="padding: 8px; text-align: left;">Account No.</th><td style="padding: 8px;"> '+projectBeneficiaryAccountNo+' </td></tr>'
+ '<tr><th style="padding: 8px; text-align: left;">Bank Name</th><td style="padding: 8px;"> '+projectBankName+' </td></tr>'
+ '<tr><th style="padding: 8px; text-align: left;">Branch Name</th><td style="padding: 8px;"> '+projectBranchName+' </td></tr>'
+ '<tr><th style="padding: 8px; text-align: left;">IFSC Code</th><td style="padding: 8px;"> '+projectIfscCode+' </td></tr>'*/
                    // + '</table> <br/>'
                    
                    
                    + '<br/><br/>Thank you for choosing <strong>Zuari.</strong><br/><br/>'
                    + 'Best regards,<br/><br/>'
                    + 'Zuari'
                    + '</div>';
            }
            
            Demand_Raised__c re = new Demand_Raised__c();
            re.Current_Demand_amount__c = presentDue; 
            re.Previous_pendings__c = balanceDueTillPrevMilestone;
            re.Amount_Demanded__c = totalAmountPayable;
            re.Include_Interest__c = true;
            re.Due_Date__c = system.today() + 15;
            re.Interest_Till_Now__c = balanceInterest;
            re.Total_Interest__c = totalInterestUplodateAmount;
            re.Total_Interest_Paid__c = totalInterestPaid;
            re.Grand_Total__c = totalAmountPayable;
            re.Demanded_Date__c = system.now();
            re.Payment_schedule__c = currentMilestoneId;
            re.Demand_Name__c =  currentMilestone;
            re.Demand_Email_Content__c = content;
            re.Total_Percentage_till_Current_Milestone__c = PaymentPercentage;
            re.Milestone_Percentage__c = CurrentPaymentPercentage;
            re.Booking__c = bookingId;
            re.Total_Amount_Paid__c = receivedAmount;
            re.Grand_Total_in_Words__c = totalAmountPayableInWords;
            demands.add(re);
        }
        
        // Insert all Demand_Raised__c records into the database
        if (!demands.isEmpty()) {
            insert demands;
        }
        return demands;
    }
    
    
    public static Map<Integer, String> daySuffixMap = new Map<Integer, String>{1 => 'st', 2 => 'nd', 3 => 'rd', 21 => 'st', 22 => 'nd', 23 => 'rd', 31 => 'st'};
        public static String getMilestoneLabel(Integer sNo) {
            if (sNo == null) {
                return 'Invalid milestone';
            }
            // Determine the suffix, default to 'th'
            String suffix = daySuffixMap.containsKey(sNo) ? daySuffixMap.get(sNo) : 'th';
            
            return sNo + suffix;
        }
    @AuraEnabled
    public static BookingWrapper getBookingRecord(Id recordId) {
        Booking__c booking = [
            SELECT Id, Project__c, Project1__r.Name, 
            Total_received_Amount__c, First_Applicant_Name__c, Plot__r.Name,Total__c
            
            FROM Booking__c 
            WHERE Id = :recordId 
            LIMIT 1
        ];
        
        List<Payment_Schedule__c> psRecordList = [
            SELECT Id, Name, S_No__c, Completed_Date__c, Payment_percent__c
            FROM Payment_Schedule__c
            WHERE Status__c = 'Completed' AND Booking__c = :recordId
            ORDER BY S_No__c DESC 
            LIMIT 1
        ];
        
        Payment_Schedule__c currentMilestone = psRecordList.isEmpty() ? null : psRecordList[0];
        
        // Return the wrapper instance
        return new BookingWrapper(booking, currentMilestone);
    }
    
    public class BookingWrapper {
        @AuraEnabled
        public Booking__c booking { get; set; }
        @AuraEnabled
        public Payment_Schedule__c currentMilestone { get; set; }
        
        // Constructor
        public BookingWrapper(Booking__c booking, Payment_Schedule__c currentMilestone) {
            this.booking = booking;
            this.currentMilestone = currentMilestone;
        }
    }
    public Decimal totalAmount;
    public Decimal totalPaymentPercent;
    public Decimal totalPendingAmount;
    public Decimal totalReceivedAmount;
    public Decimal totalInterest;
    
    public Static String  RaiseDemandController(ID bookingRecordId) {
        Booking__c bk = [select id,Agreement_Value_Before_GST__c,Payment_Plan_Name__c,Booking_Date__c,Project1__r.GST_on_Aggrement__c from Booking__c where Id =:bookingRecordId];
        Payment_schedule__c ps = [select id,Amount__c,Amount1__c,Master_Payment_Schedule__c From Payment_schedule__c where Booking__c =: bk.Id and S_No__c=1];
        
        Decimal demandAmount = bk.Agreement_Value_Before_GST__c* 0.2;
        Demand_Raised__c re = new Demand_Raised__c();
        re.Current_Demand_amount__c = ps.Amount1__c; 
        //re.Previous_pendings__c = (totalPendingAmount - totalAmount);
        re.Amount_Demanded__c = ps.Amount1__c;
        re.Include_Interest__c = true;
        if(bk.Payment_Plan_Name__c =='20:80 Payment plan'){
            
            re.Due_Date__c = bk.Booking_Date__c + 20;
        }
        if(bk.Payment_Plan_Name__c =='70:30 Payment Plan'){
            
            re.Due_Date__c = bk.Booking_Date__c+ 15;
        }
        else{
            
            re.Due_Date__c = bk.Booking_Date__c+ 30;
        }
        re.Demanded_Date__c = system.now();
        re.Payment_schedule__c = ps.Id;
        
        re.Booking__c = bookingRecordId;
        try{
            insert re;
            return 'Demand Created';
        }
        catch(Exception e){
            return e.getMessage();
        }
        
    }
    
    @AuraEnabled
    public static String raiseCustomDemand(id milestoneId){
        
        Payment_Schedule__c psRecord = [SELECT Id, Name, S_No__c, Completed_Date__c, Payment_percent__c, 
                                        Booking__c,Master_Payment_Schedule__r.S_No__c,Master_Payment_Schedule__c 
                                        FROM Payment_Schedule__c WHERE Id = :milestoneId];
        
        Booking__c book = [SELECT Id,Applicant_Name__c,Plot__r.Name, Total__c, Name, Project__c, Project1__r.Name,GST__c
                           FROM Booking__c WHERE Id = :psRecord.Booking__c];
        return customScheduleCalculations(milestoneId,psRecord.Master_Payment_Schedule__c,book);
    }
    public static String customScheduleCalculations(Id milestoneId,Id masterId,Booking__c book) {
        String totalAmountPayableInWords = '';
        Decimal totalAmountPayable =0;
        Decimal paidTillPrevMilestone =0;
        String currentCompletedStage = '';
        date demandDueDate;
        Decimal currentMilestonePaymentPercent = 0;
        String currentMilestoneNumber = '';
        date currentCompletedStageDate;
        Decimal totAmtDueTillPrevMilestone = 0;
        Decimal interestPaidTillPrevious = 0;
        Decimal interestDelayTillPrevious = 0;
        Decimal balanceDueTillPrevMilestone = 0;
        Decimal milestonePaymentPercentTill = 0;
        Decimal presentDue = 0;
        Decimal TDSonePercentage = 0;
        Decimal balanceInterest = 0;
        
        list<Master_Payment_Schedule__c> msRecordList = [
            SELECT Id, Name, S_No__c, Completed_Date__c, Payment_percent__c
            FROM Master_Payment_Schedule__c
            WHERE Id =:masterId Limit 1 
        ];
        if (msRecordList.isEmpty()) {
            // Handle case where no milestones are completed
            currentCompletedStage = 'No milestone completed';
            currentCompletedStageDate = null;
            demandDueDate = null;
            currentMilestonePaymentPercent = 0;
            currentMilestoneNumber = null;
            totalAmountPayableInWords = 'Zero';
            
            System.debug('No milestone completed for the booking.');
            return 'ERROR: No milestone completed for the booking';
        }
        
        Master_Payment_Schedule__c msRecord = msRecordList[0]; 
        
        if (msRecord != null) {
            currentCompletedStage = msRecord.Name;
            currentCompletedStageDate = msRecord.Completed_Date__c;
            demandDueDate = System.today().addDays(7);
            currentMilestonePaymentPercent = msRecord.Payment_percent__c != null ? msRecord.Payment_percent__c.setScale(0) : 0;
            
            Decimal stNumber = msRecord.S_No__c;
            if (stNumber != null) {
                currentMilestoneNumber = getMilestoneLabel(stNumber.intValue());
            }
            
            AggregateResult[] aggregateResults = [
                SELECT SUM(Pending_Amount__c) totalPendingAmount, SUM(Interest_Amount__c) totalInterestAmount,
                SUM(AmountB__c) totalPayableAmount,
                SUM(Interest_Up_to_Date__c) totalInterestUplodate, SUM(Interest_Paid__c) totalInterestPaid,
                SUM(Payment_percent__c) paymentPercentageTill
                FROM Payment_Schedule__c
                WHERE Master_Payment_Schedule__r.Status__c = 'Completed' 
                AND Master_Payment_Schedule__r.S_No__c < :msRecord.S_No__c 
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
                WHERE Master_Payment_Schedule__r.S_No__c = :msRecord.S_No__c
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
                balanceDueTillPrevMilestone = balanceDueTillPrevMilestoneMod;
            }
            milestonePaymentPercentTill = milestonePaymentPercentResult.setScale(0);
            presentDue = presentDueAmount;
            
            Decimal gstPercentage = (book.GST__c != null) ? book.GST__c / 100 : 0;
            Decimal amountExcludingGST = presentDue / (1 + gstPercentage);
            //TDSonePercentage = paidTillPrevMilestone > 4999999 ? (amountExcludingGST * 0.01).setScale(0): 0;
            
            balanceInterest = interestDelayTillPrevious - waveOff - interestPaidTillPrevious;
            
            Decimal actualTotalAmountPayable;
            actualTotalAmountPayable = (totalPayableAmount /*+ balanceInterest*/ + presentDue  - paidTotalAmount/*- TDSonePercentage*/).setScale(0);
            
            Decimal actualTotalWithoutInterest = (totalPayableAmount + presentDue   - paidTotalAmount/*- TDSonePercentage*/).setScale(0);
            Decimal TotalWithoutInterest = actualTotalWithoutInterest > 0 ? actualTotalWithoutInterest : 0;
            
            totalAmountPayable = actualTotalAmountPayable > 0 ? actualTotalAmountPayable : 0;
            
            NumberTOWordConvertion convert = new NumberTOWordConvertion();
            totalAmountPayableInWords = convert.getNumberTOWordConvertion(totalAmountPayable);
            String TotalWithoutInterestInwords = convert.getNumberTOWordConvertion(TotalWithoutInterest);
            String totaCurrentMilestoneAmount = convert.getNumberTOWordConvertion(presentDue);
            
            /* String fileIdsString = String.join(documentIds, ',');

String tdsMessage = '';
String projectIfscCode = '';
String projectBranchName = '';
String projectBankName = '';
String projectBeneficiaryAccountNo = '';

if (book.Project1__r != null) {
projectIfscCode = (book.Project1__r.IFSC_CODE__c == null) ? '' : book.Project1__r.IFSC_CODE__c;
projectBranchName = (book.Project1__r.Branch_Name__c == null) ? '' : book.Project1__r.Branch_Name__c;
projectBankName = (book.Project1__r.Bank_Name__c == null) ? '' : book.Project1__r.Bank_Name__c;
projectBeneficiaryAccountNo = (book.Project1__r.Beneficiary_Account_No__c == null) ? '' : book.Project1__r.Beneficiary_Account_No__c;
} else {
projectIfscCode = '';
projectBranchName = '';
projectBankName = '';
projectBeneficiaryAccountNo = '';
}*/
            
            String emailContent = ''
                + '<div style="color: black;">'
                + 'Dear <strong>' + book.Applicant_Name__c + '</strong>,'
                + '</div><br/>'
                + '<div>'
                + '<strong>Greetings from Zuari !!</strong><br/><br/>'
                + 'Hope this mail finds you in good health and spirit.<br/><br/>'
                + '<strong>Sub: Requisition for release of instalment.</strong><br/>'
                + '<strong>Ref: ' + book.Project1__r.Name + ', Apartment No. ' + book.Plot__r.Name + ' - ' + book.Applicant_Name__c + '</strong><br/><br/>'
                + 'This is to remind you that an amount of <strong>INR '+totalAmountPayable+'/-</strong> ('+totalAmountPayableInWords+') will be due against apartment No. '
                + book.Plot__r.Name + ' at <strong>' + book.Project1__r.Name + '</strong>.<br/><br/>'
                + 'Request you to kindly release the amount <br/><br/>'
                
                + '</div>';
            
            Demand_Raised__c re = new Demand_Raised__c();
            re.Current_Demand_amount__c = presentDue; 
            re.Previous_pendings__c = balanceDueTillPrevMilestone;
            re.Amount_Demanded__c = totalAmountPayable;
            re.Include_Interest__c = true;
            re.Due_Date__c = system.today() + 15;
            re.Interest_Till_Now__c = balanceInterest;
            re.Total_Interest__c = totalInterestUplodateAmount;
            re.Total_Interest_Paid__c = totalInterestPaid;
            re.Grand_Total__c = totalAmountPayable;
            re.Demanded_Date__c = system.now();
            re.Payment_schedule__c = milestoneId;
            re.Demand_Name__c =  currentCompletedStage;
            re.Demand_Email_Content__c = emailContent;
            re.Total_Percentage_till_Current_Milestone__c = milestonePaymentPercentResult;
            re.Milestone_Percentage__c = currentMilestonePaymentPercent;
            re.Booking__c = book.Id;
            re.Total_Amount_Paid__c = paidTotalAmount;
            re.Grand_Total_in_Words__c = totalAmountPayableInWords;
            re.Disable_Demand_Mail__c = true;
            
            try {
                insert re;
                return 'Demand raised successfully.';
            } catch (DmlException e) {
                //ExceptionHandler.addLog(e,string.valueof(re),'customDemandController',milestoneId);  /*Add Exception to error log*/
                System.debug('Error inserting record: ' + e.getMessage());
                return 'Error: ' + e.getMessage();
            }
        }
        else{
            return 'ERROR: No milestone records';
        }
    }
    
    
    @TestVisible
    public Static List<Demand_Raised__c> bulkAutoDemands ( Map<String,Decimal> bookingsWithPSNO) { //String will be bookingId and Decimal will be raising demand number
        System.debug(bookingsWithPSNO);
        List<Demand_Raised__c> demands = new List<Demand_Raised__c>();
        
        Map<Id, Payment_Schedule__c> bookingLatestPaymentSchedules = new Map<Id, Payment_Schedule__c>();
        Map<Id, List<Payment_Schedule__c>> groupedByBooking = new Map<Id, List<Payment_Schedule__c>>();
        Map<Id, Booking__c> bookingProjectMap = new Map<Id, Booking__c>();
        map<id,Decimal> debitAmountMap = new map<id,Decimal>();
        map<id,Decimal> WaveOffMap = new map<id,Decimal>();
        List<Id> CompletedPsIDs = new List<Id> ();
        
        List<Booking__c> bookings = [Select Id, Total__c, Applicant_Name__c, Project1__r.Name, Plot__r.Name, GST__c, Project1__r.GST_on_Aggrement__c from Booking__c WHERE Id IN: bookingsWithPSNO.keySet()];
        
        if(bookings.isEmpty()){
            return null;
        }
        
        for (Booking__c book : bookings) {
            bookingProjectMap.put(book.Id, book);
        }
        
        List<Payment_Schedule__c> psRecords = [
            SELECT Id, S_No__c, Is_Demanded__c,Completed_Date__c, Booking__c,Name,Payment_percent__c,Interest_Paid__c,Received_Amount1__c,Interest_Up_to_Date__c,AmountB__c,Interest_Amount__c,Pending_Amount__c
            FROM Payment_Schedule__c
            WHERE Booking__c IN :bookings
            
        ];
        System.debug(psRecords);
        for (Payment_Schedule__c ps : psRecords) {
            if (!groupedByBooking.containsKey(ps.Booking__c)) {
                groupedByBooking.put(ps.Booking__c, new List<Payment_Schedule__c>());
            }
            
            //Only taking the milestones till current PS
            if( ps.S_No__c <= bookingsWithPSNO.get(ps.Booking__c)){
                groupedByBooking.get(ps.Booking__c).add(ps);
                CompletedPsIDs.add(ps.Id);
            }
        }
        System.debug(CompletedPsIDs);
        for (Id bookingId : groupedByBooking.keySet()) {
            List<Payment_Schedule__c> schedules = groupedByBooking.get(bookingId);
            
            for (Payment_Schedule__c schedule : schedules) {
                //taking the current PS as last completed one
                if (schedule.S_No__c != null && schedule.S_No__c == bookingsWithPSNO.get(bookingId)) {
                    bookingLatestPaymentSchedules.put(bookingId, schedule);         
                }
            }
        }
        
        List<AggregateResult> aggregateResults = [
            SELECT Booking__c, 
            SUM(Pending_Amount__c) totalPendingAmount, 
            SUM(Interest_Amount__c) totalInterestAmount,
            SUM(AmountB__c) totalPayableAmount, 
            SUM(Interest_Up_to_Date__c) totalInterestUplodate, 
            SUM(Received_Amount1__c) totalReceivedAmount,
            SUM(Interest_Paid__c) totalInterestPaid, 
            SUM(Payment_percent__c) paymentPercentageTill
            FROM Payment_Schedule__c
            WHERE Booking__c IN :bookings AND Id IN: CompletedPsIDs
            GROUP BY Booking__c
        ];
        system.debug(aggregateResults);
        Map<Id, AggregateResult> bookingToAggregateResultMap = new Map<Id, AggregateResult>();
        Map<Id, Decimal> bookingToPendingAmountMap = new Map<Id, Decimal>();
        Map<Id, Decimal> bookingToInterestAmountMap = new Map<Id, Decimal>();
        Map<Id, Decimal> bookingToPayableAmountMap = new Map<Id, Decimal>();
        Map<Id, Decimal> bookingToInterestUpToDateAmountMap = new Map<Id, Decimal>();
        Map<Id, Decimal> bookingToReceivedAmountMap = new Map<Id, Decimal>();
        Map<Id, Decimal> bookingToInterestPaidMap = new Map<Id, Decimal>();
        Map<Id, Decimal> bookingToPaymentPercentageMap = new Map<Id, Decimal>();
        
        for (AggregateResult result : aggregateResults) {
            Id bookingId = (Id) result.get('Booking__c');
            
            bookingToPendingAmountMap.put(bookingId, (Decimal) result.get('totalPendingAmount'));
            bookingToInterestAmountMap.put(bookingId, (Decimal) result.get('totalInterestAmount'));
            bookingToPayableAmountMap.put(bookingId, (Decimal) result.get('totalPayableAmount'));
            bookingToInterestUpToDateAmountMap.put(bookingId, (Decimal) result.get('totalInterestUplodate'));
            bookingToReceivedAmountMap.put(bookingId, (Decimal) result.get('totalReceivedAmount'));
            bookingToInterestPaidMap.put(bookingId, (Decimal) result.get('totalInterestPaid'));
            // Object percentVal = result.get('paymentPercentageTill');
            //Decimal paymentPercent = (percentVal != null) ? (Decimal) percentVal : 0;
            bookingToPaymentPercentageMap.put(bookingId, (Decimal) result.get('paymentPercentageTill'));
            
            bookingToAggregateResultMap.put(bookingId, result);
        }
        System.debug(bookingToPendingAmountMap);
        
        for (Id bookingId : bookingToPendingAmountMap.keySet()) {
            
            if (bookingLatestPaymentSchedules.containsKey(bookingId) && 
                bookingLatestPaymentSchedules.get(bookingId).Is_Demanded__c == true) {
                    system.debug(bookingLatestPaymentSchedules.get(bookingId).Is_Demanded__c);
                    continue;
                }
            
            system.debug('bookingLatestPaymentSchedules.get(bookingId).Pending_Amount__c'+ bookingLatestPaymentSchedules.get(bookingId));
            
            Decimal pendingAmount = bookingToPendingAmountMap.get(bookingId) - bookingLatestPaymentSchedules.get(bookingId).Pending_Amount__c;
            Decimal interestAmount = bookingToInterestAmountMap.get(bookingId) - bookingLatestPaymentSchedules.get(bookingId).Interest_Amount__c;
            Decimal payableAmount = bookingToPayableAmountMap.get(bookingId) - bookingLatestPaymentSchedules.get(bookingId).AmountB__c;
            
            Decimal receivedAmount = bookingToReceivedAmountMap.get(bookingId);
            
            //if(debitAmountMap.get(bookingId) != null){
            //     receivedAmount -= debitAmountMap.get(bookingId);
            // }
            
            Decimal PaymentPercentage = bookingToPaymentPercentageMap.get(bookingId);
            Decimal CurrentPaymentPercentage = bookingLatestPaymentSchedules.get(bookingId).Payment_percent__c;
            Decimal totalInterestUplodateAmount = bookingToInterestUpToDateAmountMap.get(bookingId) - bookingLatestPaymentSchedules.get(bookingId).Interest_Up_to_Date__c;
            Decimal totalInterestPaid = bookingToInterestPaidMap.get(bookingId);
            Decimal balanceDueTillPrevMilestoneMod = payableAmount - receivedAmount;
            Decimal balanceDueTillPrevMilestone = balanceDueTillPrevMilestoneMod > 0 ? balanceDueTillPrevMilestoneMod : 0;
            Decimal balanceInterest = totalInterestUplodateAmount - totalInterestPaid /*- WaveOffMap.get(bookingId)*/;
            Decimal presentDue = bookingLatestPaymentSchedules.get(bookingId).AmountB__c;
            
            Decimal gstPercentage = (bookingProjectMap.get(bookingId).Project1__r.GST_on_Aggrement__c  != null) ? bookingProjectMap.get(bookingId).Project1__r.GST_on_Aggrement__c : 0;
            Decimal amountExcludingGST = presentDue / (1 + gstPercentage);
            
            Decimal TDSonePercentage = receivedAmount > 4999999 ? (amountExcludingGST * 0.01).setScale(0): 0;
            
            String currentMilestone = bookingLatestPaymentSchedules.get(bookingId).Name;
            Date currentMilestoneCompletedDate = bookingLatestPaymentSchedules.get(bookingId).Completed_Date__c;
            String currentMilestoneNumber =getMilestoneLabel(bookingLatestPaymentSchedules.get(bookingId).S_No__c.intValue());
            Decimal totalFlatCost = bookingProjectMap.get(bookingId).Total__c;
            //id FinanceUser = bookingProjectMap.get(bookingId).Finance_User__c;
            Id currentMilestoneId = bookingLatestPaymentSchedules.get(bookingId).Id;
            
            Decimal actualTotalAmountPayable;
            actualTotalAmountPayable = (balanceDueTillPrevMilestoneMod/* + balanceInterest*/ + presentDue/* - TDSonePercentage*/).setScale(0);
            
            Decimal actualTotalWithoutInterest = (balanceDueTillPrevMilestoneMod + presentDue/* - TDSonePercentage*/).setScale(0);
            Decimal TotalWithoutInterest = actualTotalWithoutInterest > 0 ? actualTotalWithoutInterest : 0;
            
            Decimal totalAmountPayable = actualTotalAmountPayable > 0 ? actualTotalAmountPayable : 0;
            
            NumberTOWordConvertion convert = new NumberTOWordConvertion();
            String totalAmountPayableInWords = convert.getNumberTOWordConvertion(totalAmountPayable);
            String TotalWithoutInterestInwords = convert.getNumberTOWordConvertion(TotalWithoutInterest);
            String totaCurrentMilestoneAmount = convert.getNumberTOWordConvertion(presentDue);
            
            String content = ''
                + '<div style="color: black;">'
                + 'Dear <strong>' + bookingProjectMap.get(bookingId).Applicant_Name__c + '</strong>,'
                + '</div><br/>'
                + '<div>'
                + '<strong>Greetings from Zuari !!</strong><br/><br/>'
                + 'Hope this mail finds you in good health and spirit.<br/><br/>'
                + '<strong>Sub: Requisition for release of instalment.</strong><br/>'
                + '<strong>Ref: ' + bookingProjectMap.get(bookingId).Project1__r.Name + ', Apartment No. ' + bookingProjectMap.get(bookingId).Plot__r.Name + ' - ' + bookingProjectMap.get(bookingId).Applicant_Name__c + '</strong><br/><br/>'
                + 'This is to remind you that an amount of <strong>INR '+totalAmountPayable+'/-</strong> ('+totalAmountPayableInWords+') will be due against apartment No. '
                + bookingProjectMap.get(bookingId).Plot__r.Name + ' at <strong>' + bookingProjectMap.get(bookingId).Project1__r.Name + '</strong>.<br/><br/>'
                + 'Request you to kindly release the amount <br/><br/>'/* to our below mentioned bank account:

+ '<table style="border-collapse: collapse; width: 100%; font-size: 14px;" border="1">'
+ '<tr><th style="padding: 8px; text-align: left;">Account No.</th><td style="padding: 8px;"> '+projectBeneficiaryAccountNo+' </td></tr>'
+ '<tr><th style="padding: 8px; text-align: left;">Bank Name</th><td style="padding: 8px;"> '+projectBankName+' </td></tr>'
+ '<tr><th style="padding: 8px; text-align: left;">Branch Name</th><td style="padding: 8px;"> '+projectBranchName+' </td></tr>'
+ '<tr><th style="padding: 8px; text-align: left;">IFSC Code</th><td style="padding: 8px;"> '+projectIfscCode+' </td></tr>'*/
                // + '</table> <br/>'
                
                
                + '<br/><br/>Thank you for choosing <strong>Zuari.</strong><br/><br/>'
                + 'Best regards,<br/><br/>'
                + 'Zuari'
                + '</div>';
            
            Demand_Raised__c re = new Demand_Raised__c();
            re.Current_Demand_amount__c = presentDue; 
            re.Previous_pendings__c = balanceDueTillPrevMilestone;
            re.Amount_Demanded__c = totalAmountPayable;
            re.Include_Interest__c = true;
            re.Due_Date__c = system.today() + 15;
            re.Interest_Till_Now__c = balanceInterest;
            re.Total_Interest__c = totalInterestUplodateAmount;
            re.Total_Interest_Paid__c = totalInterestPaid;
            re.Grand_Total__c = totalAmountPayable;
            re.Demanded_Date__c = system.now();
            re.Payment_schedule__c = currentMilestoneId;
            re.Demand_Name__c =  currentMilestone;
            re.Demand_Email_Content__c = content;
            re.Total_Percentage_till_Current_Milestone__c = PaymentPercentage;
            re.Milestone_Percentage__c = CurrentPaymentPercentage;
            re.Booking__c = bookingId;
            re.Total_Amount_Paid__c = receivedAmount;
            re.Grand_Total_in_Words__c = totalAmountPayableInWords;
            demands.add(re);
        }
        System.debug(demands);
        // Insert all Demand_Raised__c records into the database
        if (!demands.isEmpty()) {
            insert demands;
        }
        return demands;
    }    
}