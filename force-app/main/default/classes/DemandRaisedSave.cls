public class DemandRaisedSave {
    /**
    * Method Name  : getDemandRaised
    * Description  : Entry method to generate Demand record for selected Payment Schedule milestone.
    *
    * Functionality:
    * 1. Fetches Demand_Raised__c record based on recordId.
    *
    * Parameters:
    * @param milestoneId - Id of Demand_Raised__c recordId record for which demand is raised.
    * Used From:
    * - LWC / Aura component when user clicks “Resend Demand” button from Demand and Component GenerateDemandNote.
    * - Automated demand generation process.
    */
    @AuraEnabled
    public static Demand_Raised__c getDemandRaised(id recordId){
        Demand_Raised__c demand = [SELECT 
                                   Id, Amount_Demanded__c, Booking__c, Current_Demand_amount__c, Name, Demanded_Date__c,Demand_Email_Content__c, 
                                   Due_Date__c, Grand_Total__c, Include_Interest__c, Payment_schedule__c, Previous_pendings__c,Interest_Till_Now__c
                                   FROM Demand_Raised__c WHERE id =: recordId LIMIT 1];
        return demand;
    }
    /**
    * Method Name  : ResendRaiseDemand
    * Description  : Entry method to generate Demand record for selected Payment Schedule milestone.
    *
    * Functionality:
    * 1. Fetches Demand_Raised__c record based on list<Id> recordIds.
    *
    * Parameters:
    * @param milestoneId - Id of Demand_Raised__c list<Id> recordIds.
    * Used From:
    * - LWC / Aura component when user clicks “Resend Demand” button from Demand and Component GenerateDemandNote.
    * - Automated demand generation process.
    */
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
    
    /**
    * Method Name  : raiseCustomDemand
    * Description  : Entry method to generate Demand record for selected Payment Schedule milestone.
    *
    * Functionality:
    * 1. Fetches Payment_Schedule__c record based on milestoneId.
    * 2. Retrieves related Booking__c details required for demand calculations.
    * 3. Passes fetched data to customScheduleCalculations method for:
    *      - Previous due calculation
    *      - Interest computation
    *      - TDS handling
    *      - Grand total preparation
    * 4. Returns success or error message from calculation method.
    *
    * Parameters:
    * @param milestoneId - Id of Payment_Schedule__c record for which demand is raised.
    *
    * Returns:
    * @return String - Success/Error message after demand generation.
    *
    * Used From:
    * - LWC / Aura component when user clicks “Raise Demand” button.
    * - Automated demand generation process.
    */
    @AuraEnabled
    public static String raiseCustomDemand(id milestoneId){
        
        Payment_Schedule__c psRecord = [SELECT Id, Name, S_No__c, Completed_Date__c, Payment_percent__c, 
                                        Booking__c,Master_Payment_Schedule__r.S_No__c,Master_Payment_Schedule__c 
                                        FROM Payment_Schedule__c WHERE Id = :milestoneId];
        
        Booking__c book = [SELECT Id,Applicant_Name__c,First_Applicant_Name__c,Plot__r.Name, Total__c, Name, Project__c, Project1__r.Name,GST__c,
                           RecordType.DeveloperName, Quote__r.Agreement_Value_Before_GST__c,Total_Amount__c,Block_Name__c,Unit_No__c,Owner_Phone_Number__c,
                           Company_Name__c FROM Booking__c WHERE Id = :psRecord.Booking__c];
        return customScheduleCalculations(milestoneId,psRecord.Master_Payment_Schedule__c,book);
    }

    /**
    * Method Name  : customScheduleCalculations
    * Description  : Core calculation engine to prepare Demand_Raised__c record data.
    *
    * Business Rules:
    * - TDS is customer responsibility.
    * - Grand Total = Sum of Pending + Interest.
    * - Overpayments adjust previous dues.
    *
    * @param milestoneId - Current Payment Schedule Id.
    * @param masterId    - Master Payment Schedule Id (optional).
    * @param book        - Booking__c record.
    *
    * @return String - Success or error message.
    */
    public static String customScheduleCalculations(Id milestoneId, Id masterId, Booking__c book) {
        
        /** ==================VARIABLE DECLARATIONS =========================**/
        String totalAmountPayableInWords = '';
        Decimal totalAmountPayable = 0;
        
        String currentCompletedStage = '';
        String currentMilestoneNumber = '';
        Date currentCompletedStageDate;
        Decimal currentSNo = 0;
        
        Decimal balanceTotalInterest = 0;
        Decimal previousbalanceInterest = 0;
        Decimal milestonePaymentPercentResult = 0;
        Decimal totalIntrestAmount = 0;
        
        
        /** ==================GET TEMPLATE RECORD =========================**/
        General_Settings__c temp = [
            SELECT Template_Body__c, Type__c 
            FROM General_Settings__c 
            WHERE Project_Name1__c INCLUDES (:book.Project__c)
            AND Type__c = 'Demand Note'
            LIMIT 1
        ];
        
        String template = temp.Template_Body__c;
        
        template = template.replace('##APPLICANT_NAME##', book.First_Applicant_Name__c ?? '');
        template = template.replace('##PROJECT_NAME##', book.Project__c ?? '');
        template = template.replace('##BLOCK_NAME##', String.valueOf(book.Block_Name__c ?? ''));
        template = template.replace('##UNIT_NUMBER##', String.valueOf(book.Unit_No__c ?? ''));
        template = template.replace('##CRM_PHONE##', String.valueOf(book.Owner_Phone_Number__c ?? ''));
        template = template.replace('##COMAPANY_NAME##', String.valueOf(book.Company_Name__c ?? ''));
        
        
        /** ==================FETCH CURRENT PAYMENT SCHEDULE =========================**/
        Payment_Schedule__c currentPS = [
            SELECT Id, Name, S_No__c, Completed_Date__c, Payment_percent__c
            FROM Payment_Schedule__c
            WHERE Id = :milestoneId
            LIMIT 1
        ];
        
        Boolean hasMaster = (masterId != null);
        
        if (hasMaster) {
            
            Master_Payment_Schedule__c msRecord = [
                SELECT Id, Name, S_No__c, Completed_Date__c
                FROM Master_Payment_Schedule__c
                WHERE Id = :masterId
                LIMIT 1
            ];
            
            currentCompletedStage = msRecord.Name;
            currentCompletedStageDate = msRecord.Completed_Date__c;
            currentSNo = msRecord.S_No__c;
            
        } 
        else {
            
            currentCompletedStage = currentPS.Name;
            currentCompletedStageDate = currentPS.Completed_Date__c;
            currentSNo = currentPS.S_No__c;
        }
        
        if (currentSNo != null) {
            currentMilestoneNumber = getMilestoneLabel(currentSNo.intValue());
        }
        
        
        /** ==================PREVIOUS MILESTONE AGGREGATES =========================**/
        AggregateResult[] aggregateResults = [
            SELECT SUM(Pending_Amount__c) totalPendingAmount,
            SUM(Interest_Up_to_Date__c) totalInterestAmount,
            SUM(Interest_Paid__c) totalInterestPaid,
            SUM(Payment_percent__c) paymentPercentageTill,
            SUM(Total_TDS_Amount__c) tdsAmount
            FROM Payment_Schedule__c
            WHERE Status__c = 'Completed'
            AND Booking__c = :book.Id
            AND S_No__c < :currentSNo
        ];
        
        Decimal balanceDueTillPrevMilestone = 0;
        Decimal previousMileStoneInterest = 0;
        Decimal previousTotalInterestPaid = 0;
        Decimal previousMilestonePaymentPercent = 0;
        Decimal previousTDS = 0;
        

        
        if (!aggregateResults.isEmpty()) {
            AggregateResult ar = aggregateResults[0];
            balanceDueTillPrevMilestone = (Decimal)ar.get('totalPendingAmount') ?? 0;
            previousMileStoneInterest = (Decimal)ar.get('totalInterestAmount') ?? 0;
            previousTotalInterestPaid = (Decimal)ar.get('totalInterestPaid') ?? 0;
            previousMilestonePaymentPercent = (Decimal)ar.get('paymentPercentageTill') ?? 0;
            previousTDS = (Decimal)ar.get('tdsAmount') ?? 0;
        }
        previousbalanceInterest = previousMileStoneInterest - previousTotalInterestPaid;
        
        
        /** ==================CURRENT MILESTONE DUE =========================**/
        AggregateResult presentDueResult = [
            SELECT SUM(Pending_Amount__c) Pending_Amount,
            SUM(Interest_Up_to_Date__c) totalInterestAmount,
            SUM(Interest_Paid__c) totalInterestPaid,
            SUM(Payment_percent__c) paymentPercentage,
            SUM(Total_TDS_Amount__c) tdsAmount
            FROM Payment_Schedule__c
            WHERE S_No__c = :currentSNo
            AND Booking__c = :book.Id
        ];
        
        Decimal presentDue = (Decimal)presentDueResult.get('Pending_Amount') ?? 0;
        Decimal presentInterestAmount = (Decimal)presentDueResult.get('totalInterestAmount') ?? 0;
        Decimal presentInterestAmountPaid = (Decimal)presentDueResult.get('totalInterestPaid') ?? 0;
        Decimal presentMilestonePaymentPercent = (Decimal)presentDueResult.get('paymentPercentage') ?? 0;
        Decimal currentTds = (Decimal)presentDueResult.get('tdsAmount') ?? 0;
        
        Decimal presentBalanceInterst = presentInterestAmount - presentInterestAmountPaid;
        milestonePaymentPercentResult = presentMilestonePaymentPercent + previousMilestonePaymentPercent;
      
        
        
        /** ==================TOTAL RECEIVED INCLUDING CURRENT =========================**/
        AggregateResult[] totalReceivedIncludingCurrent = [
            SELECT SUM(Received_Amount1__c) totalReceivedAmountWithCurrent,
            SUM(Interest_Paid__c) totalInterestPaid
            FROM Payment_Schedule__c
            WHERE Booking__c = :book.Id
        ];
        
        Decimal totalReceivedWithCurrent = 0;
        Decimal totalInterstPaid = 0;
        
        if (!totalReceivedIncludingCurrent.isEmpty()) {
            AggregateResult tr = totalReceivedIncludingCurrent[0];
            
            totalReceivedWithCurrent = (Decimal)tr.get('totalReceivedAmountWithCurrent') ?? 0;
            totalInterstPaid = (Decimal)tr.get('totalInterestPaid') ?? 0;
        }
  
        
        /** ==================TDS CALCULATION =========================**/
        Decimal paidTDS = 0;
        Decimal pendingPreviousTDS = 0;
        Decimal currentPendingTDS = 0;
        Decimal prevDueExcludingTDS = 0;
        Decimal currentDueExcludingTDS = 0;
        
        Decimal totalBookingAmount = book.Total_Amount__c ?? 0;

        AggregateResult paidTDSAgg = [SELECT SUM(Amount__c) amt FROM Receipt_Line_Item__c WHERE Payment_Type__c = 'TDS' AND Booking__c = :book.Id];
        paidTDS = (Decimal)paidTDSAgg.get('amt') ?? 0;
        
        pendingPreviousTDS = previousTDS - paidTDS;
        pendingPreviousTDS = pendingPreviousTDS < 0 ? 0 : pendingPreviousTDS;
        
        Decimal remaingTdPaidAmount = paidTDS - previousTDS;
        currentPendingTDS = currentTds;
        currentPendingTDS = remaingTdPaidAmount > 0 ? currentTds - remaingTdPaidAmount : currentPendingTDS;
        currentPendingTDS = currentPendingTDS < 0 ? 0 : currentPendingTDS;
        
        /** ===================== EXCLUDING TDS ===================== **/
        prevDueExcludingTDS = balanceDueTillPrevMilestone - previousTDS;
        currentDueExcludingTDS = presentDue - currentTds;
        currentDueExcludingTDS = currentDueExcludingTDS < 0 ? 0 : currentDueExcludingTDS;
        
        /** ==================GRAND TOTAL =========================**/
        balanceTotalInterest = presentBalanceInterst + previousbalanceInterest;
        totalIntrestAmount = previousMileStoneInterest + presentInterestAmount;
        
        Decimal grandTotal = presentDue + balanceDueTillPrevMilestone + balanceTotalInterest;
        
        NumberTOWordConvertion convert = new NumberTOWordConvertion();
        totalAmountPayableInWords = convert.getNumberTOWordConvertion(grandTotal);
        
        
        /** ==================PREPARE DEMAND RECORD =========================**/
        Demand_Raised__c re = new Demand_Raised__c();
        
        re.Current_Demand_amount__c = presentDue;
        re.Current_Milestone_Excluding_the_TDS__c = currentDueExcludingTDS;
        re.Current_Milestone_TDS_1__c = currentTds;
        re.Milestone_Percentage__c = presentMilestonePaymentPercent;
            
        re.Pending_Dues_excluding_TDS__c = prevDueExcludingTDS;
        re.Previous_pendings__c = balanceDueTillPrevMilestone;
        
        re.Include_Interest__c = true;
        re.Due_Date__c = system.today() + 15;
    
        
        re.Amount_Demanded__c = grandTotal;
        re.Grand_Total__c = grandTotal;
        re.Total_Amount_Paid__c = totalReceivedWithCurrent;
        re.Total_Percentage_till_Current_Milestone__c = milestonePaymentPercentResult;
        
        re.Interest_Till_Now__c = balanceTotalInterest;
        re.Total_Interest_Paid__c = totalInterstPaid;
        re.Total_Interest__c = totalIntrestAmount;
        
        re.Booking__c = book.Id;
        re.Payment_schedule__c = milestoneId;
        re.Demanded_Date__c = system.now();
        re.Demand_Name__c = currentCompletedStage;
        re.Demand_Email_Content__c = template;
        re.Grand_Total_in_Words__c = totalAmountPayableInWords;
        re.Disable_Demand_Mail__c = true;
        
        /** ==================SAVE RECORDS =========================**/
        try {
            currentPS.Is_Demanded__c = true;
            currentPS.Demanded_Date__c = Date.today();
            update currentPS;
            insert re;
            return 'Demand raised successfully.';
            
        } catch (DmlException e) {
            return 'Error: ' + e.getMessage();
        }
    }
    
    
    
    
    
    
    
    
    @AuraEnabled
    public Static String RaiseDemand(List<Id> bookingIds, Map<Id,String> emailContents, map<Id,List<String>> contentIds ) {
        
        String demandRaisedReturn='';
        
        if (bookingIds == null || bookingIds.isEmpty()) {
            ApexPages.addMessage(new ApexPages.Message(ApexPages.Severity.ERROR, 'No Booking records provided.'));
            return 'No Booking records provided';
        }
        
        List<Booking__c> bookings = [SELECT Id,Applicant_Name__c,First_Applicant_Name__c,Plot__r.Name, Total__c, Name, Project__c, GST__c,CRM_Manager__c,
                                     Project1__r.Name,Quote__r.With_GST__c, RecordType.DeveloperName, Quote__r.Agreement_Value_Before_GST__c
                                     FROM Booking__c WHERE Id IN :bookingIds];
        
        if (bookings.isEmpty()) {
            ApexPages.addMessage(new ApexPages.Message(ApexPages.Severity.ERROR, 'No Booking records found.'));
            return 'No Booking records found';
        }
        
        List<Booking__c> apartmentBookings = new List<Booking__c>();
        
        for (Booking__c book : bookings) {
            apartmentBookings.add(book);
        }
        
        if (!apartmentBookings.isEmpty()) {
            List<Demand_Raised__c> apartmentDemands = bulkScheduleCalculations(apartmentBookings,emailContents,contentIds);
            if (apartmentDemands != null && !apartmentDemands.isEmpty()) {
                demandRaisedReturn = 'Demand Raise records created';
            }
        }
        
        return demandRaisedReturn;
    }
    
    @TestVisible
    private Static List<Demand_Raised__c> bulkScheduleCalculations(List<Booking__c> bookings,Map<Id,String> emailContents, map<Id,List<String>> contentIds) {
        List<Demand_Raised__c> demands = new List<Demand_Raised__c>();
        Map<Id, Payment_Schedule__c> bookingLatestPaymentSchedules = new Map<Id, Payment_Schedule__c>();
        Map<Id, List<Payment_Schedule__c>> groupedByBooking = new Map<Id, List<Payment_Schedule__c>>();
        Map<Id, Booking__c> bookingProjectMap = new Map<Id, Booking__c>();
        
        for (Booking__c book : bookings) {
            bookingProjectMap.put(book.Id, book);
        }
        
        List<Payment_Schedule__c> psRecords = [
            SELECT Id, S_No__c, Is_Demanded__c, Completed_Date__c, Booking__c, Name, Payment_percent__c, 
            Interest_Paid__c, Received_Amount1__c, Interest_Up_to_Date__c, AmountB__c, Interest_Amount__c, 
            Pending_Amount__c, Last_Payment_Schedule__c
            FROM Payment_Schedule__c
            WHERE Status__c = 'Completed' AND Booking__c IN :bookings
        ];
        
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
        
        // Get previous milestones data (excluding current)
        List<AggregateResult> aggregateResults = [
            SELECT Booking__c, 
            SUM(Pending_Amount__c) totalPendingAmount, 
            SUM(Interest_Up_to_Date__c) totalInterestAmount,
            SUM(AmountB__c) totalPayableAmount, 
            SUM(Interest_Up_to_Date__c) totalInterestUplodate, 
            SUM(Received_Amount1__c) totalReceivedAmount,
            SUM(Interest_Paid__c) totalInterestPaid, 
            SUM(Payment_percent__c) paymentPercentageTill
            FROM Payment_Schedule__c
            WHERE Status__c = 'Completed' 
            AND Booking__c IN :bookings
            AND Id NOT IN :bookingLatestPaymentSchedules.values()
            GROUP BY Booking__c
        ];
        
        // Get total received amount INCLUDING current milestone
        List<AggregateResult> totalReceivedIncludingCurrent = [
            SELECT Booking__c, 
            SUM(Received_Amount1__c) totalReceivedAmountWithCurrent
            FROM Payment_Schedule__c
            WHERE Status__c = 'Completed' 
            AND Booking__c IN :bookings
            GROUP BY Booking__c
        ];
        
        // Get total pending INCLUDING current milestone
        List<AggregateResult> totalPendingIncludingCurrent = [
            SELECT Booking__c, 
            SUM(Pending_Amount__c) totalPendingWithCurrent
            FROM Payment_Schedule__c
            WHERE Status__c = 'Completed' 
            AND Booking__c IN :bookings
            GROUP BY Booking__c
        ];
        
        Map<Id, Decimal> bookingToPendingAmountMap = new Map<Id, Decimal>();
        Map<Id, Decimal> bookingToInterestAmountMap = new Map<Id, Decimal>();
        Map<Id, Decimal> bookingToPayableAmountMap = new Map<Id, Decimal>();
        Map<Id, Decimal> bookingToInterestUpToDateAmountMap = new Map<Id, Decimal>();
        Map<Id, Decimal> bookingToReceivedAmountMap = new Map<Id, Decimal>();
        Map<Id, Decimal> bookingToInterestPaidMap = new Map<Id, Decimal>();
        Map<Id, Decimal> bookingToPaymentPercentageMap = new Map<Id, Decimal>();
        Map<Id, Decimal> bookingToTotalReceivedWithCurrentMap = new Map<Id, Decimal>();
        Map<Id, Decimal> bookingToTotalPendingWithCurrentMap = new Map<Id, Decimal>();
        
        for (AggregateResult result : aggregateResults) {
            Id bookingId = (Id) result.get('Booking__c');
            
            bookingToPendingAmountMap.put(bookingId, (Decimal) result.get('totalPendingAmount'));
            bookingToInterestAmountMap.put(bookingId, (Decimal) result.get('totalInterestAmount'));
            bookingToPayableAmountMap.put(bookingId, (Decimal) result.get('totalPayableAmount'));
            bookingToInterestUpToDateAmountMap.put(bookingId, (Decimal) result.get('totalInterestUplodate'));
            bookingToReceivedAmountMap.put(bookingId, (Decimal) result.get('totalReceivedAmount'));
            bookingToInterestPaidMap.put(bookingId, (Decimal) result.get('totalInterestPaid'));
            bookingToPaymentPercentageMap.put(bookingId, (Decimal) result.get('paymentPercentageTill'));
        }
        
        // Map total received including current milestone
        for (AggregateResult result : totalReceivedIncludingCurrent) {
            Id bookingId = (Id) result.get('Booking__c');
            bookingToTotalReceivedWithCurrentMap.put(bookingId, (Decimal) result.get('totalReceivedAmountWithCurrent'));
        }
        
        // Map total pending including current milestone
        for (AggregateResult result : totalPendingIncludingCurrent) {
            Id bookingId = (Id) result.get('Booking__c');
            bookingToTotalPendingWithCurrentMap.put(bookingId, (Decimal) result.get('totalPendingWithCurrent'));
        }
        
        for (Id bookingId : bookingLatestPaymentSchedules.keySet()) {
            
            if (bookingLatestPaymentSchedules.get(bookingId).Is_Demanded__c == true) {
                continue;
            }
            
            // Get values from maps (previous milestones only)
            Decimal totalPayableAmountPrevious = bookingToPayableAmountMap.get(bookingId) != null ? bookingToPayableAmountMap.get(bookingId) : 0;
            Decimal totalReceivedAmountPrevious = bookingToReceivedAmountMap.get(bookingId) != null ? bookingToReceivedAmountMap.get(bookingId) : 0;
            Decimal totalInterestAmount = bookingToInterestAmountMap.get(bookingId) != null ? bookingToInterestAmountMap.get(bookingId) : 0;
            
            // Get total received including current milestone
            Decimal totalReceivedWithCurrent = bookingToTotalReceivedWithCurrentMap.get(bookingId) != null ? bookingToTotalReceivedWithCurrentMap.get(bookingId) : 0;
            
            // Get total pending including current milestone (from Pending_Amount__c field)
            Decimal totalPendingWithCurrent = bookingToTotalPendingWithCurrentMap.get(bookingId) != null ? bookingToTotalPendingWithCurrentMap.get(bookingId) : 0;
            
            Decimal PaymentPercentage = bookingToPaymentPercentageMap.get(bookingId) != null ? bookingToPaymentPercentageMap.get(bookingId) : 0;
            Decimal CurrentPaymentPercentage = bookingLatestPaymentSchedules.get(bookingId).Payment_percent__c;
            Decimal totalInterestUplodateAmount = bookingToInterestUpToDateAmountMap.get(bookingId) != null ? bookingToInterestUpToDateAmountMap.get(bookingId) : 0;
            Decimal totalInterestPaid = bookingToInterestPaidMap.get(bookingId) != null ? bookingToInterestPaidMap.get(bookingId) : 0;
            
            // Previous pending from actual Pending_Amount__c field
            Decimal previousPendingFromField = bookingToPendingAmountMap.get(bookingId) != null ? bookingToPendingAmountMap.get(bookingId) : 0;
            
            Decimal balanceInterest = totalInterestUplodateAmount - totalInterestPaid;
            Decimal presentDue = bookingLatestPaymentSchedules.get(bookingId).AmountB__c;
            
            // TDS Calculation - 1% of Agreement Value Before GST if > 50 lakhs
            Decimal totalSalesConsideration = bookingProjectMap.get(bookingId).Quote__r.Agreement_Value_Before_GST__c != null ? 
                bookingProjectMap.get(bookingId).Quote__r.Agreement_Value_Before_GST__c : 0;
            Decimal TDSonePercentage = totalSalesConsideration > 5000000 ? (totalSalesConsideration * 0.01).setScale(0) : 0;
            
            String currentMilestone = bookingLatestPaymentSchedules.get(bookingId).Name;
            Date currentMilestoneCompletedDate = bookingLatestPaymentSchedules.get(bookingId).Completed_Date__c;
            String currentMilestoneNumber = getMilestoneLabel(bookingLatestPaymentSchedules.get(bookingId).S_No__c.intValue());
            Id currentMilestoneId = bookingLatestPaymentSchedules.get(bookingId).Id;
            
            // Grand Total = Sum of Pending_Amount__c from all milestones (previous + current)
            Decimal grandTotal = totalPendingWithCurrent != null ? totalPendingWithCurrent : 0;
            
            NumberTOWordConvertion convert = new NumberTOWordConvertion();
            String totalAmountPayableInWords = convert.getNumberTOWordConvertion(grandTotal);
            String totaCurrentMilestoneAmount = convert.getNumberTOWordConvertion(presentDue);
            
            String content = emailContents.get(bookingId);            
            
            if (String.isBlank(content)) {
                content = ''
                    + '<div style="color: black;">'
                    + 'Dear <strong>' + bookingProjectMap.get(bookingId).First_Applicant_Name__c + '</strong>,'
                    + '</div><br/>'
                    + '<div>'
                    + '<strong>Greetings from Zuari !!</strong><br/><br/>'
                    + 'Hope this mail finds you in good health and spirit.<br/><br/>'
                    + '<strong>Sub: Requisition for release of instalment.</strong><br/>'
                    + '<strong>Ref: ' + bookingProjectMap.get(bookingId).Project1__r.Name + ', Apartment No. ' + bookingProjectMap.get(bookingId).Plot__r.Name + ' - ' + bookingProjectMap.get(bookingId).First_Applicant_Name__c + '</strong><br/><br/>'
                    + 'This is to remind you that an amount of <strong>INR '+grandTotal+'/-</strong> ('+totalAmountPayableInWords+') will be due against apartment No. '
                    + bookingProjectMap.get(bookingId).Plot__r.Name + ' at <strong>' + bookingProjectMap.get(bookingId).Project1__r.Name + '</strong>.<br/><br/>'
                    + 'Request you to kindly release the amount <br/><br/>'
                    + '<br/><br/>Thank you for choosing <strong>Zuari.</strong><br/><br/>'
                    + 'Best regards,<br/><br/>'
                    + 'Zuari'
                    + '</div>';
            }
            
            Demand_Raised__c re = new Demand_Raised__c();
            re.Current_Demand_amount__c = presentDue; // Always current milestone amount
            re.Previous_pendings__c = previousPendingFromField; // Actual pending from Payment_Schedule__c.Pending_Amount__c
            re.Amount_Demanded__c = grandTotal; // Total amount to pay (can be 0 if overpaid)
            re.Include_Interest__c = true;
            re.Due_Date__c = system.today() + 15;
            re.Interest_Till_Now__c = balanceInterest;
            re.Total_Interest__c = totalInterestUplodateAmount;
            re.Total_Interest_Paid__c = totalInterestPaid;
            re.Grand_Total__c = grandTotal; // Total amount to pay
            re.Demanded_Date__c = system.now();
            re.Payment_schedule__c = currentMilestoneId;
            re.Demand_Name__c =  currentMilestone;
            re.Demand_Email_Content__c = content;
            re.Total_Percentage_till_Current_Milestone__c = PaymentPercentage;
            re.Milestone_Percentage__c = CurrentPaymentPercentage;
            re.Booking__c = bookingId;
            re.Total_Amount_Paid__c = totalReceivedWithCurrent; // FIXED: Now includes current milestone payment
            re.Grand_Total_in_Words__c = totalAmountPayableInWords;
            demands.add(re);
        }
        
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
        
        return new BookingWrapper(booking, currentMilestone);
    }
    
    public class BookingWrapper {
        @AuraEnabled
        public Booking__c booking { get; set; }
        @AuraEnabled
        public Payment_Schedule__c currentMilestone { get; set; }
        
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
    
    public Static String RaiseDemandController(ID bookingRecordId) {
        Booking__c bk = [select id,Agreement_Value_Before_GST__c,Payment_Plan_Name__c,Booking_Date__c,Project1__r.GST_on_Aggrement__c from Booking__c where Id =:bookingRecordId];
        Payment_schedule__c ps = [select id,Amount__c,Amount1__c,Master_Payment_Schedule__c From Payment_schedule__c where Booking__c =: bk.Id and S_No__c=1];
        
        Decimal demandAmount = bk.Agreement_Value_Before_GST__c* 0.2;
        Demand_Raised__c re = new Demand_Raised__c();
        re.Current_Demand_amount__c = ps.Amount1__c; 
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
    
    
    @TestVisible
    public Static List<Demand_Raised__c> bulkAutoDemands ( Map<String,Decimal> bookingsWithPSNO) {
        System.debug(bookingsWithPSNO);
        List<Demand_Raised__c> demands = new List<Demand_Raised__c>();
        
        Map<Id, Payment_Schedule__c> bookingLatestPaymentSchedules = new Map<Id, Payment_Schedule__c>();
        Map<Id, List<Payment_Schedule__c>> groupedByBooking = new Map<Id, List<Payment_Schedule__c>>();
        Map<Id, Booking__c> bookingProjectMap = new Map<Id, Booking__c>();
        List<Id> CompletedPsIDs = new List<Id> ();
        
        List<Booking__c> bookings = [Select Id, Total__c, Applicant_Name__c,First_Applicant_Name__c, Project1__r.Name, Plot__r.Name, GST__c, 
                                     Project1__r.GST_on_Aggrement__c, RecordType.DeveloperName, Quote__r.With_GST__c,
                                     Quote__r.Agreement_Value_Before_GST__c
                                     from Booking__c WHERE Id IN: bookingsWithPSNO.keySet()];
        
        if(bookings.isEmpty()){
            return null;
        }
        
        for (Booking__c book : bookings) {
            bookingProjectMap.put(book.Id, book);
        }
        
        List<Payment_Schedule__c> psRecords = [
            SELECT Id, S_No__c, Is_Demanded__c, Completed_Date__c, Booking__c, Name, Payment_percent__c, 
            Interest_Paid__c, Received_Amount1__c, Interest_Up_to_Date__c, AmountB__c, Interest_Amount__c, 
            Pending_Amount__c, Last_Payment_Schedule__c
            FROM Payment_Schedule__c
            WHERE Booking__c IN :bookings
        ];
        
        System.debug(psRecords);
        for (Payment_Schedule__c ps : psRecords) {
            if (!groupedByBooking.containsKey(ps.Booking__c)) {
                groupedByBooking.put(ps.Booking__c, new List<Payment_Schedule__c>());
            }
            
            if( ps.S_No__c <= bookingsWithPSNO.get(ps.Booking__c)){
                groupedByBooking.get(ps.Booking__c).add(ps);
                CompletedPsIDs.add(ps.Id);
            }
        }
        
        System.debug(CompletedPsIDs);
        for (Id bookingId : groupedByBooking.keySet()) {
            List<Payment_Schedule__c> schedules = groupedByBooking.get(bookingId);
            
            for (Payment_Schedule__c schedule : schedules) {
                if (schedule.S_No__c != null && schedule.S_No__c == bookingsWithPSNO.get(bookingId)) {
                    bookingLatestPaymentSchedules.put(bookingId, schedule);         
                }
            }
        }
        
        // Get previous milestones data (excluding current milestone)
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
            WHERE Booking__c IN :bookings 
            AND Id IN: CompletedPsIDs
            AND Id NOT IN :bookingLatestPaymentSchedules.values()
            GROUP BY Booking__c
        ];
        
        // Get total received INCLUDING current milestone
        List<AggregateResult> totalReceivedIncludingCurrent = [
            SELECT Booking__c,
            SUM(Received_Amount1__c) totalReceivedAmountWithCurrent
            FROM Payment_Schedule__c
            WHERE Booking__c IN :bookings 
            AND Id IN: CompletedPsIDs
            GROUP BY Booking__c
        ];
        
        // Get total pending INCLUDING current milestone
        List<AggregateResult> totalPendingIncludingCurrent = [
            SELECT Booking__c,
            SUM(Pending_Amount__c) totalPendingWithCurrent
            FROM Payment_Schedule__c
            WHERE Booking__c IN :bookings 
            AND Id IN: CompletedPsIDs
            GROUP BY Booking__c
        ];
        Map<Id, Decimal> bookingToTotalPendingWithCurrentMap = new Map<Id, Decimal>();
        
        system.debug(aggregateResults);
        Map<Id, Decimal> bookingToPendingAmountMap = new Map<Id, Decimal>();
        Map<Id, Decimal> bookingToInterestAmountMap = new Map<Id, Decimal>();
        Map<Id, Decimal> bookingToPayableAmountMap = new Map<Id, Decimal>();
        Map<Id, Decimal> bookingToInterestUpToDateAmountMap = new Map<Id, Decimal>();
        Map<Id, Decimal> bookingToReceivedAmountMap = new Map<Id, Decimal>();
        Map<Id, Decimal> bookingToInterestPaidMap = new Map<Id, Decimal>();
        Map<Id, Decimal> bookingToPaymentPercentageMap = new Map<Id, Decimal>();
        Map<Id, Decimal> bookingToTotalReceivedWithCurrentMap = new Map<Id, Decimal>();
        
        for (AggregateResult result : aggregateResults) {
            Id bookingId = (Id) result.get('Booking__c');
            
            bookingToPendingAmountMap.put(bookingId, (Decimal) result.get('totalPendingAmount'));
            bookingToInterestAmountMap.put(bookingId, (Decimal) result.get('totalInterestAmount'));
            bookingToPayableAmountMap.put(bookingId, (Decimal) result.get('totalPayableAmount'));
            bookingToInterestUpToDateAmountMap.put(bookingId, (Decimal) result.get('totalInterestUplodate'));
            bookingToReceivedAmountMap.put(bookingId, (Decimal) result.get('totalReceivedAmount'));
            bookingToInterestPaidMap.put(bookingId, (Decimal) result.get('totalInterestPaid'));
            bookingToPaymentPercentageMap.put(bookingId, (Decimal) result.get('paymentPercentageTill'));
        }
        
        // Map total received including current milestone
        for (AggregateResult result : totalReceivedIncludingCurrent) {
            Id bookingId = (Id) result.get('Booking__c');
            bookingToTotalReceivedWithCurrentMap.put(bookingId, (Decimal) result.get('totalReceivedAmountWithCurrent'));
        }
        
        // Map total pending including current milestone
        for (AggregateResult result : totalPendingIncludingCurrent) {
            Id bookingId = (Id) result.get('Booking__c');
            bookingToTotalPendingWithCurrentMap.put(bookingId, (Decimal) result.get('totalPendingWithCurrent'));
        }
        
        System.debug(bookingToPendingAmountMap);
        
        for (Id bookingId : bookingLatestPaymentSchedules.keySet()) {
            
            if (bookingLatestPaymentSchedules.get(bookingId).Is_Demanded__c == true) {
                system.debug(bookingLatestPaymentSchedules.get(bookingId).Is_Demanded__c);
                continue;
            }
            
            // Get values from maps (previous milestones only)
            Decimal totalPayableAmountPrevious = bookingToPayableAmountMap.get(bookingId) != null ? bookingToPayableAmountMap.get(bookingId) : 0;
            Decimal totalReceivedAmountPrevious = bookingToReceivedAmountMap.get(bookingId) != null ? bookingToReceivedAmountMap.get(bookingId) : 0;
            
            // Get total received including current milestone
            Decimal totalReceivedWithCurrent = bookingToTotalReceivedWithCurrentMap.get(bookingId) != null ? bookingToTotalReceivedWithCurrentMap.get(bookingId) : 0;
            
            // Get total pending including current milestone (from Pending_Amount__c field)
            Decimal totalPendingWithCurrent = bookingToTotalPendingWithCurrentMap.get(bookingId) != null ? bookingToTotalPendingWithCurrentMap.get(bookingId) : 0;
            
            Decimal PaymentPercentage = bookingToPaymentPercentageMap.get(bookingId) != null ? bookingToPaymentPercentageMap.get(bookingId) : 0;
            Decimal CurrentPaymentPercentage = bookingLatestPaymentSchedules.get(bookingId).Payment_percent__c;
            Decimal totalInterestUplodateAmount = bookingToInterestUpToDateAmountMap.get(bookingId) != null ? bookingToInterestUpToDateAmountMap.get(bookingId) : 0;
            Decimal totalInterestPaid = bookingToInterestPaidMap.get(bookingId) != null ? bookingToInterestPaidMap.get(bookingId) : 0;
            
            // Previous pending from actual Pending_Amount__c field
            Decimal previousPendingFromField = bookingToPendingAmountMap.get(bookingId) != null ? bookingToPendingAmountMap.get(bookingId) : 0;
            
            Decimal balanceInterest = totalInterestUplodateAmount - totalInterestPaid;
            Decimal presentDue = bookingLatestPaymentSchedules.get(bookingId).AmountB__c;
            
            // TDS Calculation - 1% of Agreement Value Before GST if > 50 lakhs
            Decimal totalSalesConsideration = bookingProjectMap.get(bookingId).Quote__r.Agreement_Value_Before_GST__c != null ? 
                bookingProjectMap.get(bookingId).Quote__r.Agreement_Value_Before_GST__c : 0;
            Decimal TDSonePercentage = totalSalesConsideration > 5000000 ? (totalSalesConsideration * 0.01).setScale(0) : 0;
            
            String currentMilestone = bookingLatestPaymentSchedules.get(bookingId).Name;
            Date currentMilestoneCompletedDate = bookingLatestPaymentSchedules.get(bookingId).Completed_Date__c;
            String currentMilestoneNumber =getMilestoneLabel(bookingLatestPaymentSchedules.get(bookingId).S_No__c.intValue());
            Id currentMilestoneId = bookingLatestPaymentSchedules.get(bookingId).Id;
            
            // Grand Total = Sum of Pending_Amount__c from all milestones (previous + current)
            Decimal grandTotal = totalPendingWithCurrent != null ? totalPendingWithCurrent : 0;
            
            NumberTOWordConvertion convert = new NumberTOWordConvertion();
            String totalAmountPayableInWords = convert.getNumberTOWordConvertion(grandTotal);
            String totaCurrentMilestoneAmount = convert.getNumberTOWordConvertion(presentDue);
            
            String content = ''
                + '<div style="color: black;">'
                + 'Dear <strong>' + bookingProjectMap.get(bookingId).First_Applicant_Name__c + '</strong>,'
                + '</div><br/>'
                + '<div>'
                + '<strong>Greetings from Zuari !!</strong><br/><br/>'
                + 'Hope this mail finds you in good health and spirit.<br/><br/>'
                + '<strong>Sub: Requisition for release of instalment.</strong><br/>'
                + '<strong>Ref: ' + bookingProjectMap.get(bookingId).Project1__r.Name + ', Apartment No. ' + bookingProjectMap.get(bookingId).Plot__r.Name + ' - ' + bookingProjectMap.get(bookingId).First_Applicant_Name__c + '</strong><br/><br/>'
                + 'This is to remind you that an amount of <strong>INR '+grandTotal+'/-</strong> ('+totalAmountPayableInWords+') will be due against apartment No. '
                + bookingProjectMap.get(bookingId).Plot__r.Name + ' at <strong>' + bookingProjectMap.get(bookingId).Project1__r.Name + '</strong>.<br/><br/>'
                + 'Request you to kindly release the amount <br/><br/>'
                + '<br/><br/>Thank you for choosing <strong>Zuari.</strong><br/><br/>'
                + 'Best regards,<br/><br/>'
                + 'Zuari'
                + '</div>';
            
            Demand_Raised__c re = new Demand_Raised__c();
            re.Current_Demand_amount__c = presentDue; // Always current milestone amount
            re.Previous_pendings__c = previousPendingFromField; // Actual pending from Payment_Schedule__c.Pending_Amount__c
            re.Amount_Demanded__c = grandTotal; // Total amount to pay (can be 0 if overpaid)
            re.Include_Interest__c = true;
            re.Due_Date__c = system.today() + 15;
            re.Interest_Till_Now__c = balanceInterest;
            re.Total_Interest__c = totalInterestUplodateAmount;
            re.Total_Interest_Paid__c = totalInterestPaid;
            re.Grand_Total__c = grandTotal; // Total amount to pay
            re.Demanded_Date__c = system.now();
            re.Payment_schedule__c = currentMilestoneId;
            re.Demand_Name__c =  currentMilestone;
            re.Demand_Email_Content__c = content;
            re.Total_Percentage_till_Current_Milestone__c = PaymentPercentage;
            re.Milestone_Percentage__c = CurrentPaymentPercentage;
            re.Booking__c = bookingId;
            re.Total_Amount_Paid__c = totalReceivedWithCurrent; // FIXED: Now includes current milestone payment
            re.Grand_Total_in_Words__c = totalAmountPayableInWords;
            demands.add(re);
        }
        
        System.debug(demands);
        if (!demands.isEmpty()) {
            insert demands;
        }
        return demands;
    }    
}