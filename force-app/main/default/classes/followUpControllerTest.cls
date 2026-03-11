@isTest
public class followUpControllerTest {
    
    @isTest
    public static void notes()
    {
        
       
        
        try {
             

            Follow_Up__c fu = new Follow_Up__c();
            
  
            fu.Subject__c = 'Test';
            fu.Status__c = 'Scheduled';
            
            DateTime dt = System.now();
            fu.Scheduled_Date__c = dt.addMinutes(5);
            
            insert fu;
        }
        catch (Exception e) {
            System.debug('Error while creating Follow Up: ' + e.getMessage());
        }
        
        


    }
    

}