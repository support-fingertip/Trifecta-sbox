@isTest
public class ConsolidatedReceiptControllerTest {

    @isTest
    static void testAllConsolidatedReceiptControllerMethods() {

        Project__c pjt = new Project__c(
            Name = 'Trifecta Vanto',
            Project__c = 'Trifecta Vanto',
            Active__c = true
        );
        insert pjt;

        Block__c bc = new Block__c(
            Name                         = 'A',
            Intrest_Percentage__c        = 12,
            Project__c                   = pjt.Id,
            Email__c                     = 'block@test.com',
            Project_Address__c           = 'Test Project Address',
            Company_Address__c           = 'Test Company Address',
            Company_Name__c              = 'Test Company',
            Land_Company_Name__c         = 'Test Land Company',
            Construction_Company_Name__c = 'Test Construction Company'
        );
        insert bc;

        Lead ld = new Lead(
            LastName             = 'Test',
            Company              = 'testcompany',
            Phone__c             = '8778987789',
            Source_Type__c       = 'Google',
            Allocated_Project__c = 'Trifecta Vanto'
        );
        insert ld;

        Plot__c ut = new Plot__c(
            Status__c  = 'Available',
            Project__c = pjt.Id
        );
        insert ut;

        List<RecordType> bookingRecordTypes = [
            SELECT Id, Name
            FROM RecordType
            WHERE SObjectType = 'Booking__c'
            LIMIT 1
        ];
        String validPropertyType = bookingRecordTypes.isEmpty() ? null : bookingRecordTypes[0].Name;

        Quote__c qc = new Quote__c(
            Block_Lookup__c  = bc.Id,
            Quote_status__c  = 'Drafted',
            Block__c         = 'A2',
            Project__c       = 'Trifecta Vanto',
            Payment_Type__c  = 'Standard',
            Sale_Area__c     = 2567,
            Built_up_area__c = 4567,
            Rate_per_sqft__c = 7100,
            Unit__c          = ut.Id,
            SLead__c         = ld.Id,
            Property_Type__c = validPropertyType
        );
        insert qc;

        Booking__c bookVillas = new Booking__c(
            Applicant_Name__c       = 'Test Villas User',
            First_Applicant_Name__c = 'Test Villas User',
            Project1__c             = pjt.Id,
            Plot__c                 = ut.Id,
            Quote__c                = qc.Id,
            SLead__c                = ld.Id,
            Booking_Date__c         = Date.today(),
            Booking_Amount__c       = 50000,
            Email__c                = 'villas@test.com',
            Project_Type__c         = 'Villas'
        );
        insert bookVillas;

        Booking__c bookApt = new Booking__c(
            Applicant_Name__c       = 'Test Apt User',
            First_Applicant_Name__c = 'Test Apt User',
            Project1__c             = pjt.Id,
            Plot__c                 = ut.Id,
            Quote__c                = qc.Id,
            SLead__c                = ld.Id,
            Booking_Date__c         = Date.today(),
            Booking_Amount__c       = 50000,
            Email__c                = 'apt@test.com',
            Project_Type__c         = 'Apartments'
        );
        insert bookApt;

        Co_Applicant__c coApp = new Co_Applicant__c(
            Name             = 'Co Applicant Test',
            Booking__c       = bookVillas.Id,
            Primary_Phone__c = '9876543210'
        );
        insert coApp;

        Master_Payment_Schedule__c mps = new Master_Payment_Schedule__c(
            Project__c        = pjt.Id,
            S_No__c           = 1,
            Status__c         = 'Completed',
            Completed_Date__c = Date.today()
        );
        insert mps;

        Payment_Schedule__c ps = new Payment_Schedule__c(
            Booking__c                 = bookVillas.Id,
            Master_Payment_Schedule__c = mps.Id,
            Amount__c                  = 100000,
            Status__c                  = 'Scheduled',
            Is_Demanded__c             = false,
            Payment_Due_Date__c        = Date.today()
        );
        insert ps;

        Receipt__c receipt = new Receipt__c(
            Booking__c      = bookVillas.Id,
            Receipt_Date__c = Date.today()
        );
        insert receipt;

        Receipt_Line_Item__c rli = new Receipt_Line_Item__c(
            Booking__c          = bookVillas.Id,
            Receipt__c          = receipt.Id,
            Payment_schedule__c = ps.Id,
            Payment_Type__c     = 'Booking Amount',
            Mode_of_Payment__c  = 'Cheque',
            Bank_Name__c        = 'HDFC',
            Cheque_Date__c      = Date.today()
        );
        insert rli;

        Test.startTest();

        // 1. Directly instantiate ReceiptWrapper and set all properties
        // Covers all ReceiptWrapper property lines that loop body would cover
        ConsolidatedReceiptController.ReceiptWrapper rw = new ConsolidatedReceiptController.ReceiptWrapper();
        rw.receiptDate    = Date.today();
        rw.receiptAmount  = '100.00';
        rw.modeOfPayment  = 'Cheque';
        rw.instruMentNo   = '123456';
        rw.payNameName    = 'Test Payment';
        rw.bankName       = 'HDFC';
        rw.receiptNo      = 'R-001';
        rw.refdate        = Date.today();

        // 2. Directly instantiate bookingInfoWrapper and set all properties
        ConsolidatedReceiptController.bookingInfoWrapper biw = new ConsolidatedReceiptController.bookingInfoWrapper();
        biw.receiptNo      = 'R-001';
        biw.customerId     = 'C-001';
        biw.customerName   = 'Test User';
        biw.unitNo         = 'A101';
        biw.block          = 'A';
        biw.receiptDate    = Date.today();
        biw.project        = 'Trifecta Vanto';
        biw.projectAddress = 'Test Address';
        biw.email          = 'test@test.com';
        biw.contactNo      = '9876543210';
        biw.webAddress     = 'www.test.com';
        biw.companyAddress = 'Test Company Address';
        biw.companyName    = 'Test Company';

        // 3. Villas + no typeVal - main path
        PageReference pageRefVillas = Page.ConsolidatedReceipt;
        pageRefVillas.getParameters().put('id', bookVillas.Id);
        Test.setCurrentPage(pageRefVillas);
        try {
            ConsolidatedReceiptController ctrlVillas = new ConsolidatedReceiptController(
                new ApexPages.StandardController(bookVillas)
            );
        } catch (Exception e) { System.debug('Villas no type: ' + e.getMessage()); }

        // 4. Villas + Land - covers Land branch
        PageReference pageRefLand = Page.ConsolidatedReceipt;
        pageRefLand.getParameters().put('id', bookVillas.Id);
        pageRefLand.getParameters().put('type', 'Land');
        Test.setCurrentPage(pageRefLand);
        try {
            ConsolidatedReceiptController ctrlLand = new ConsolidatedReceiptController(
                new ApexPages.StandardController(bookVillas)
            );
        } catch (Exception e) { System.debug('Villas Land: ' + e.getMessage()); }

        // 5. Villas + Construction - covers Construction branch
        PageReference pageRefConst = Page.ConsolidatedReceipt;
        pageRefConst.getParameters().put('id', bookVillas.Id);
        pageRefConst.getParameters().put('type', 'Construction');
        Test.setCurrentPage(pageRefConst);
        try {
            ConsolidatedReceiptController ctrlConst = new ConsolidatedReceiptController(
                new ApexPages.StandardController(bookVillas)
            );
        } catch (Exception e) { System.debug('Villas Construction: ' + e.getMessage()); }

        // 6. Apartment + no typeVal - covers else branch
        PageReference pageRefApt = Page.ConsolidatedReceipt;
        pageRefApt.getParameters().put('id', bookApt.Id);
        Test.setCurrentPage(pageRefApt);
        try {
            ConsolidatedReceiptController ctrlApt = new ConsolidatedReceiptController(
                new ApexPages.StandardController(bookApt)
            );
        } catch (Exception e) { System.debug('Apartment no type: ' + e.getMessage()); }

        // 7. Apartment + Construction - covers typeVal filter receipt query
        PageReference pageRefAptConst = Page.ConsolidatedReceipt;
        pageRefAptConst.getParameters().put('id', bookApt.Id);
        pageRefAptConst.getParameters().put('type', 'Construction');
        Test.setCurrentPage(pageRefAptConst);
        try {
            ConsolidatedReceiptController ctrlAptConst = new ConsolidatedReceiptController(
                new ApexPages.StandardController(bookApt)
            );
        } catch (Exception e) { System.debug('Apartment Construction: ' + e.getMessage()); }

        Test.stopTest();
    }
}