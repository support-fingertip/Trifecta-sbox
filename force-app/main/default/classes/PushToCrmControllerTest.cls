@isTest
public class PushToCrmControllerTest {

    @isTest
    public static void testReturnCRMUser() {
        
        Profile p = [SELECT Id FROM Profile WHERE Name = 'Pre Sales' LIMIT 1];

        User u = new User(
            ProfileId = p.Id,
            LastName = 'RH23',
            Email = 'RH@gm1ail.com',
            Username = 'RH@1gmail.com' + System.currentTimeMillis(),
            CompanyName = 'RH1',
            Title = 'titletitl1e',
            Alias = 'lokma1n',
            TimeZoneSidKey = 'America/Los_Angeles',
            EmailEncodingKey = 'UTF-8',
            LanguageLocaleKey = 'en_US',
            LocaleSidKey = 'en_US',
            Availability__c = true,
            IsActive = true,
            is_working__c = true
        );
        insert u;

        User u1 = new User(
            ProfileId = p.Id,
            LastName = 'RH23',
            Email = 'RH@gm2ail.com',
            Username = 'RH2@1gmail.com' + System.currentTimeMillis(),
            CompanyName = 'RH1',
            Title = 'titletitl1e',
            Alias = 'lokma2n',
            TimeZoneSidKey = 'America/Los_Angeles',
            EmailEncodingKey = 'UTF-8',
            LanguageLocaleKey = 'en_US',
            LocaleSidKey = 'en_US',
            Availability__c = false,
            ManagerId = u.Id,
            IsActive = true,
            is_working__c = true
        );
        insert u1;


        System.runAs(u1) {

            // Create project
            Project__c pjt = new Project__c(
                Name = 'Trifecta Vanto',
                Project__c = 'Trifecta Vanto',
                Active__c = true
            );
            insert pjt;

            // Create block
            Block__c bc = new Block__c(
                Name = 'A',
                Project__c = pjt.Id
            );
            insert bc;

            // Create Lead
            Lead ld = new Lead(
                LastName = 'Test',
                Company = 'test company',
                Phone__c = '9999999999',
                Source_Type__c = 'Google',
                Allocated_Project__c = pjt.Name
            );
            insert ld;

            // Create Plot
            Plot__c ut = new Plot__c(
                Name = 'P1',
                Status__c = 'Available',
                Project__c = pjt.Id
            );
            insert ut;

            // Create Quote
            Quote__c qc = new Quote__c(
                Block_Lookup__c = bc.Id,
                Quote_status__c = 'Drafted',
                Block__c = 'A2',
                Project__c = pjt.Name,
                Payment_Type__c = 'Standard',
                Sale_Area__c = 2000,
                Built_up_area__c = 1500,
                Rate_per_sqft__c = 7000,
                Unit__c = ut.Id,
                SLead__c = ld.Id
            );
            insert qc;

            // Booking
            Booking__c book = new Booking__c(
                Funding_Type__c = 'Loan',
                Quote__c = qc.Id,
                Plot__c = ut.Id,
                CRM_Manager__c = u1.Id,
                Project__c = 'Trifecta Vanto'
            );
            insert book;

            Round_Robin__c rr = new Round_Robin__c(
                Project_Assigned__c = pjt.Name,
                Active__c = true,
                Project_Head__c = u1.Id
            );
            insert rr;


            Test.startTest();
            PushToCrmController.moveToCRM(book.Id, 'test');
            Test.stopTest();
        }
    }
}