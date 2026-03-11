public class FlatKeyHandoverVfpController {
    public Booking__c booking { get; set; }
    public String handoverByName { get; set; }
    public String handoverByDesignation { get; set; }
    public String handoverByMobile { get; set; }

    public FlatKeyHandoverVfpController(ApexPages.StandardController stdController) {
        Id bookingId = stdController.getId();

        if (bookingId != null) {
            booking = [
                SELECT Id,
                       First_Applicant_Name__c,
                       Unit_Number__c
                FROM Booking__c
                WHERE Id = :bookingId
                LIMIT 1
            ];
        } else {
            booking = new Booking__c();
        }

        User currentUser = [
            SELECT Name, Title, MobilePhone
            FROM User
            WHERE Id = :UserInfo.getUserId()
            LIMIT 1
        ];

        handoverByName        = currentUser.Name        != null ? currentUser.Name        : '';
        handoverByDesignation = currentUser.Title       != null ? currentUser.Title       : '';
        handoverByMobile      = currentUser.MobilePhone != null ? currentUser.MobilePhone : '';
    }
}
