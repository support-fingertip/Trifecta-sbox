/****************************************************************
* Class Name   : WhatsappController
* Company      : Fingertipplus
* Created Date : 06-11-2025
* @description : This class is used to send Whatsapp message to customers
* @author      : Mayuri Patel

* Change Log:
* -----------------------------------------------------------------------------
* Ver | Author 			| 	  Date 		| Description
* -----------------------------------------------------------------------------
* 1.0 | Mayuri Patel 	| 06-11-2025 	| Initial version
* -----------------------------------------------------------------------------
**************************************************************/
public class WhatsappController implements Queueable, Database.AllowsCallouts{
    
    public String COMPANY_NAME = 'Trifecta Projects Pvt. Ltd.';
    public String ACTION = '';
    
    
    public static Boolean disableWhatsApp = false;
    
    
    private List<Lead> leads;
    private List<Site_Visit__c> visits;
    private List<Booking__c> bookings;
    
    // Constructor to pass leads to the queueable class
    public WhatsappController(List<Lead> leads, String act) {
        this.leads = leads;
        this.ACTION = act;
    }
    // Constructor to pass leads to the queueable class
    public WhatsappController(List<Site_Visit__c> visits, String act) {
        this.visits = visits;
        this.ACTION = act;
    }
     // Constructor to pass leads to the queueable class
    public WhatsappController(List<Booking__c> bookings, String act) {
        this.bookings = bookings;
        this.ACTION = act;
    }
    
    // The execute method where the actual callout will happen
    public void execute(QueueableContext context) {
        if (Test.isRunningTest() || disableWhatsApp) {
            System.debug('WhatsApp execution skipped (test mode).');
            return;
        }
        
        if(this.ACTION == '1') sendWelcomeMsg(this.leads);
        if(this.ACTION == '2') sendNotConnectedMsg(this.leads);
        if(this.ACTION == '3') sendSVProposedMsg(this.visits);
        if(this.ACTION == '4') sendSVConfirmedMsg(this.visits);
        if(this.ACTION == '5') sendSVDoneMsg(this.visits);
        if(this.ACTION == '6') sendBookingDoneMsg(this.bookings);
    }
    
    // Method to send WELCOME WhatsApp message to multiple leads
    public void sendWelcomeMsg(List<Lead> leads) {
        
        // Fetch WhatsApp configuration from Custom Metadata
        Whatsapp_Setting__mdt config = getWhatsAppConfig('Welcome');
        
        if(config == null){
            System.debug('Template not found: No Active Whatsapp template is available!');
            return;
        }
        
        List<Lead> leadsToUpdate = new List<Lead>();
        // Loop through the leads and send a message to each one
        for (Lead lead : leads) {
            String customerPhoneNumber = lead.Phone__c;
            String customerName = lead.FirstName != null ? lead.FirstName + ' ' + lead.LastName : lead.LastName;
            String projectName = lead.Allocated_Project__c;
            
            if (String.isBlank(customerPhoneNumber)) {
                continue; // Skip to the next lead if no phone number
            }
            
            // Construct the dynamic JSON body
            String jsonBody = '{"mobileNumbers":"'+customerPhoneNumber+'","senderId":"'+config.Sender_ID__c+'","component":{"messaging_product":"whatsapp","recipient_type":"individual","type":"template","template":{"name":"'+config.Template_Name__c+'","language":{"code":"en"},"components":[{"type":"body","index":0,"parameters":[{"type":"text","text":"'+customerName+'"},{"type":"text","text":"'+COMPANY_NAME+'"},{"type":"text","text":"'+projectName+'"}]}]},"qrImageUrl":false,"qrLinkUrl":false,"to":"'+customerPhoneNumber+'"}}';
            
            // Send the message
            Boolean res = sendWhatsAppMessage(jsonBody, config);
            
            Lead ld = new Lead();
            ld.Id = lead.Id;
            ld.Sent_Welcome_Msg__c = res;
            leadsToUpdate.add(ld);
        }
        
        try{
            update leadsToUpdate;
        }
        catch(Exception ex){
            System.debug('Error while updating leads:' + ex.getMessage());
        }
    }
    
    // Method to send NOTCONNECTED WhatsApp message to multiple leads
    public void sendNotConnectedMsg(List<Lead> leads) {
        
        // Fetch WhatsApp configuration from Custom Metadata
        Whatsapp_Setting__mdt config = getWhatsAppConfig('NotConnected');
        
        if(config == null){
            System.debug('Template not found: No Active Whatsapp template is available!');
            return;
        }
        
        // Loop through the leads and send a message to each one
        for (Lead lead : leads) {
            String customerPhoneNumber = lead.Phone__c;
            String customerName = lead.Name;
            String projectName = lead.Allocated_Project__c;
            
            if (String.isBlank(customerPhoneNumber)) {
                continue; // Skip to the next lead if no phone number
            }
            
            // Construct the dynamic JSON body
            String jsonBody = '{"mobileNumbers":"'+customerPhoneNumber+'","senderId":"'+config.Sender_ID__c+'","component":{"messaging_product":"whatsapp","recipient_type":"individual","type":"template","template":{"name":"'+config.Template_Name__c+'","language":{"code":"en"},"components":[{"type":"body","index":0,"parameters":[{"type":"text","text":"'+customerName+'"},{"type":"text","text":"'+projectName+'"}]}]},"qrImageUrl":false,"qrLinkUrl":false,"to":"'+customerPhoneNumber+'"}}';
            
            // Send the message
            Boolean res = sendWhatsAppMessage(jsonBody, config);
            
        }
        
    }
    
    // Method to send SVPROPOSED WhatsApp message to multiple leads
    public void sendSVProposedMsg(List<Site_Visit__c> visits) {
        
        // Fetch WhatsApp configuration from Custom Metadata
        Whatsapp_Setting__mdt config = getWhatsAppConfig('SVProposed');
        
        if(config == null){
            System.debug('Template not found: No Active Whatsapp template is available!');
            return;
        }
        
        // Loop through the leads and send a message to each one
        for (Site_Visit__c sv : visits) {
            String customerPhoneNumber = sv.SLead__r.Phone__c;
            String customerName = sv.SLead__r.Name;
            String projectName = sv.Project__c;
            DateTime svdatetime = sv.SV_Proposed_Date_Time__c.addHours(5).addMinutes(30);
            
            if (String.isBlank(customerPhoneNumber)) {
                continue; // Skip to the next lead if no phone number
            }
            
            // Construct the dynamic JSON body
            String jsonBody = '{"mobileNumbers":"'+customerPhoneNumber+'","senderId":"'+config.Sender_ID__c+'","component":{"messaging_product":"whatsapp","recipient_type":"individual","type":"template","template":{"name":"'+config.Template_Name__c+'","language":{"code":"en"},"components":[{"type":"body","index":0,"parameters":[{"type":"text","text":"'+customerName+'"},{"type":"text","text":"'+projectName+'"},{"type":"text","text":"'+svdatetime+'"}]}]},"qrImageUrl":false,"qrLinkUrl":false,"to":"'+customerPhoneNumber+'"}}';
            
            // Send the message
            Boolean res = sendWhatsAppMessage(jsonBody, config);
            
        }
        
    }
    
    // Method to send SVCONFIRMED WhatsApp message to multiple leads
    public void sendSVConfirmedMsg(List<Site_Visit__c> visits) {
        
        // Fetch WhatsApp configuration from Custom Metadata
        Whatsapp_Setting__mdt config = getWhatsAppConfig('SVConfirmed');
        
        if(config == null){
            System.debug('Template not found: No Active Whatsapp template is available!');
            return;
        }
        
        Map<String, Project__c> projectMap = new Map<String, Project__c>();
        
        for(Project__c pr: [SELECT Id, Name, Location__c FROM Project__c]) {
            projectMap.put(pr.Name, pr);
        }
        // Loop through the leads and send a message to each one
        for (Site_Visit__c sv : visits) {
            String customerPhoneNumber = sv.SLead__r.Phone__c;
            String customerName = sv.SLead__r.Name;
            String projectName = sv.Project__c;
            DateTime svdatetime = sv.Date__c.addHours(5).addMinutes(30);
            String loc = projectMap.get(projectName).Location__c != null ? projectMap.get(projectName).Location__c : 'N/A';
            
            if (String.isBlank(customerPhoneNumber)) {
                continue; // Skip to the next lead if no phone number
            }
            
            // Construct the dynamic JSON body
            String jsonBody = '{"mobileNumbers":"'+customerPhoneNumber+'","senderId":"'+config.Sender_ID__c+'","component":{"messaging_product":"whatsapp","recipient_type":"individual","type":"template","template":{"name":"'+config.Template_Name__c+'","language":{"code":"en"},"components":[{"type":"body","index":0,"parameters":[{"type":"text","text":"'+customerName+'"},{"type":"text","text":"'+projectName+'"},{"type":"text","text":"'+svdatetime+'"},{"type":"text","text":"'+sv.Name+'"},{"type":"text","text":"'+loc+'"}]}]},"qrImageUrl":false,"qrLinkUrl":false,"to":"'+customerPhoneNumber+'"}}';
            
            // Send the message
            Boolean res = sendWhatsAppMessage(jsonBody, config);
            
        }
    }
    
    // Method to send SVDONE WhatsApp message to multiple leads
    public void sendSVDoneMsg(List<Site_Visit__c> visits) {
        
        // Fetch WhatsApp configuration from Custom Metadata
        Whatsapp_Setting__mdt config = getWhatsAppConfig('SVDone');
        
        if(config == null){
            System.debug('Template not found: No Active Whatsapp template is available!');
            return;
        }
        
        // Loop through the leads and send a message to each one
        for (Site_Visit__c sv : visits) {
            String customerPhoneNumber = sv.SLead__r.Phone__c;
            String customerName = sv.SLead__r.Name;
            String projectName = sv.Project__c;
            String executiveName = sv.Owner.Name;
            DateTime svdatetime = sv.SV_Completed_Date_Time__c.addHours(5).addMinutes(30);
            String feedLink = 'https://trifectaprojects.com/contact-us/';
            
            if (String.isBlank(customerPhoneNumber)) {
                continue; // Skip to the next lead if no phone number
            }
            
            // Construct the dynamic JSON body
            String jsonBody = '{"mobileNumbers":"'+customerPhoneNumber+'","senderId":"'+config.Sender_ID__c+'","component":{"messaging_product":"whatsapp","recipient_type":"individual","type":"template","template":{"name":"'+config.Template_Name__c+'","language":{"code":"en"},"components":[{"type":"body","index":0,"parameters":[{"type":"text","text":"'+customerName+'"},{"type":"text","text":"'+projectName+'"},{"type":"text","text":"'+executiveName+'"},{"type":"text","text":"'+feedLink+'"}]}]},"qrImageUrl":false,"qrLinkUrl":false,"to":"'+customerPhoneNumber+'"}}';
            
            // Send the message
            Boolean res = sendWhatsAppMessage(jsonBody, config);
            
        }
    }
    
    // Method to send BOOKINGDONE WhatsApp message to multiple leads
    public void sendBookingDoneMsg(List<Booking__c> bookings) {
        
        // Fetch WhatsApp configuration from Custom Metadata
        Whatsapp_Setting__mdt config = getWhatsAppConfig('BookingDone');
        
        if(config == null){
            System.debug('Template not found: No Active Whatsapp template is available!');
            return;
        }
        
    
        // Loop through the leads and send a message to each one
        for (Booking__c book : bookings) {
            String customerPhoneNumber = book.Mobile__c;
            String sal = book.S__c;
            String customerName = book.First_Applicant_Name__c;
            String projectName = book.Project1__r.Name;
            String unit = book.Plot__r.Name;
            String dim = book.Plot__r.Super_Built_up_Area__c + ' Sqft.';
            String bhk = book.Plot__r.BHK_Type__c;
            
            if (String.isBlank(customerPhoneNumber)) {
                continue; // Skip to the next lead if no phone number
            }
            
            // Construct the dynamic JSON body
            String jsonBody = '{"mobileNumbers":"'+customerPhoneNumber+'","senderId":"'+config.Sender_ID__c+'","component":{"messaging_product":"whatsapp","recipient_type":"individual","type":"template","template":{"name":"'+config.Template_Name__c+'","language":{"code":"en"},"components":[{"type":"body","index":0,"parameters":[{"type":"text","text":"'+customerName+'"},{"type":"text","text":"'+projectName+'"},{"type":"text","text":"'+unit+'"},{"type":"text","text":"'+dim+'"},{"type":"text","text":"'+bhk+'"},{"type":"text","text":"'+sal+'"}]}]},"qrImageUrl":false,"qrLinkUrl":false,"to":"'+customerPhoneNumber+'"}}';
            
            // Send the message
            Boolean res = sendWhatsAppMessage(jsonBody, config);
            
        }
        
    }
    
    // Helper method to fetch WhatsApp settings from Custom Metadata
    private Whatsapp_Setting__mdt getWhatsAppConfig(String templateName) {
        // Query the custom metadata record (assuming only one configuration record exists)
        List<Whatsapp_Setting__mdt> config = [SELECT DeveloperName,Template_Name__c, Sender_ID__c,  Authentication_Key__c, URL__c 
                                              FROM Whatsapp_Setting__mdt where DeveloperName = :templateName and Active__c = true LIMIT 1];
        return config.size() > 0 ? config[0] : null;
    }
    
    
    
    // Helper method to send the WhatsApp message, using the URL from Custom Metadata
    private Boolean sendWhatsAppMessage(String jsonBody, WhatsApp_Setting__mdt config) {
        
        Apex_Log__c log = new Apex_Log__c();
        
        
        // Fetch the URL from the metadata record dynamically
        String apiUrl = config.URL__c; // Custom Metadata field containing the API URL
        
        // Create the HTTP request
        HttpRequest req = new HttpRequest();
        req.setEndpoint(apiUrl + '?AUTH_KEY=' + config.Authentication_Key__c); // Dynamically use URL and Auth Key
        req.setMethod('POST');
        req.setHeader('Accept', 'application/json');
        req.setHeader('Content-Type', 'application/json');
        
        req.setBody(jsonBody);
        system.debug(jsonBody);
        
        // Initialize the HTTP client
        Http http = new Http();
        HttpResponse res = http.send(req);
        
        log.Request__c = String.valueof(req);
        log.Input_parameters__c = jsonBody;
        log.Response__c = res.getBody();
        log.Status__c = res.getStatus();
        
        system.debug(res);
        // Handle the response
        if (res.getStatusCode() == 200) {
            System.debug('Message sent successfully! Response: ' + res.getBody());
            return true;
        } else {
            log.Error_Message__c = res.getBody();
            System.debug('Failed to send message. Status: ' + res.getStatus() + ' Response: ' + res.getBody());
        }
        
        Database.insert(log,false);
        return false;
    }
}