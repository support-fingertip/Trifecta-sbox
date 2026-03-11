@isTest
public class ReceiptTriggerHandlerTest {
    @isTest
    public static void receiptTri(){
         Project__c pjt = new Project__c(
            Name = 'Trifecta Vanto',
            Project__c = 'Trifecta Vanto',
            Active__c = true
        );
        insert pjt;

       
        Block__c bc = new Block__c(
            Name = 'A',
            Project__c = pjt.Id
        );
        insert bc;

        
        Lead ld = new Lead(
            LastName = 'Test',
            Company = 'testcompany',
            Phone__c = '8778987789',
            Source_Type__c = 'Google',
            Allocated_Project__c = 'Trifecta Vanto'
        );
        insert ld;

        Plot__c ut = new Plot__c(
            Status__c = 'Available',
            Project__c = pjt.Id
        );
        insert ut;

        Quote__c qc = new Quote__c(
            Block_Lookup__c = bc.Id,
            Quote_status__c = 'Drafted',
            Block__c = 'A2',
            Project__c = 'Trifecta Vanto',
            Payment_Type__c = 'Standard',
            Sale_Area__c = 2567,
            Built_up_area__c = 4567,
            Rate_per_sqft__c = 7100,
            Unit__c = ut.Id,
            SLead__c = ld.Id
        );
        insert qc;

        
        Booking__c book = new Booking__c(
            Funding_Type__c = 'Loan',
            Quote__c = qc.Id,
            Plot__c = ut.Id,
            CRM_Manager__c = UserInfo.getUserId()
        );
        insert book;
        
         Master_payment_schedule__c mps = new Master_payment_schedule__c();
        mps.Project__c = pjt.id;
        mps.Name = 'test';
        mps.Payment_Percent__c = 20;
        mps.Status__c ='Completed';
        insert mps;
        
        Payment_schedule__c ps = new Payment_schedule__c();
         ps.Payment_percent__c =100;
        ps.Master_Payment_Schedule__c = mps.Id;
        ps.Is_Demanded__c = true;
        ps.Quote__c = qc.id;
         insert ps;

        List<Receipt__c> rcList = new  List<Receipt__c>(); 
        Receipt__c rc = new Receipt__c(
            Receipt_Name__c = 'test',
        Receipt_Date__c = Date.today(),
            Remarks__c = 'test',
            Approval_status__c ='Submitted for Approval',
            Booking__c = book.Id
          
        );
        insert rc;
        
        Map<Id, Receipt__c> oldMap = new Map<Id, Receipt__c>{ rc.Id => rc };
        
        rc.Approval_status__c = 'Approved';
        update rc;
        rcList.add(rc);
        
    
        
        
        Receipt_Line_Item__c rcl = new Receipt_Line_Item__c(
        
        Amount__c = 30000,
            Mode_of_Payment__c = 'Cheque',
            Bank_Name__c = 'test',
            Cheque_no_Transaction_Number__c = 'sdgfsg23124',
            	Drawn_On__c = Date.Today(),
            Payment_schedule__c = ps.Id,
            Payment_Type__c = 'Flat Amount',
            Received_Amount__c = 50000
        );

        ReceiptTriggerHandler.afterUpdate(rcList, oldMap);
        
    }

}