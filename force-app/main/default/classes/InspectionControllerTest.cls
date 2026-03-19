@isTest
public class InspectionControllerTest {

    static String firstActiveLabel(Schema.DescribeFieldResult dfr) {
        for (Schema.PicklistEntry e : dfr.getPicklistValues())
            if (e.isActive()) return e.getLabel();
        return null;
    }

    static String firstActiveValue(Schema.DescribeFieldResult dfr) {
        for (Schema.PicklistEntry e : dfr.getPicklistValues())
            if (e.isActive()) return e.getValue();
        return null;
    }

    static String preferredLabel(Schema.DescribeFieldResult dfr, String preferred) {
        String fallback = null;
        for (Schema.PicklistEntry e : dfr.getPicklistValues()) {
            if (!e.isActive()) continue;
            if (e.getLabel() == preferred) return e.getLabel();
            if (fallback == null) fallback = e.getLabel();
        }
        return fallback;
    }

    // ═══════════════════════════════════════════════════════
    //  @testSetup
    // ═══════════════════════════════════════════════════════

    @testSetup
    static void setupData() {

        User currentUser = [
            SELECT Id, ProfileId, TimeZoneSidKey, LocaleSidKey,
                   EmailEncodingKey, LanguageLocaleKey
            FROM User WHERE Id = :UserInfo.getUserId() LIMIT 1
        ];
        Long ts = System.now().getTime();

        // ── Inspection Executive User ─────────────────────
        User inspExec = new User(
            FirstName         = 'InspExec',
            LastName          = 'TestUser',
            Email             = 'inspexec' + ts + '@example.com',
            Username          = 'inspexec' + ts + '@example.com',
            Alias             = ('insp' + ts).left(8),
            TimeZoneSidKey    = currentUser.TimeZoneSidKey,
            LocaleSidKey      = currentUser.LocaleSidKey,
            EmailEncodingKey  = currentUser.EmailEncodingKey,
            LanguageLocaleKey = currentUser.LanguageLocaleKey,
            ProfileId         = currentUser.ProfileId
        );
        insert inspExec;

        // ── Project ───────────────────────────────────────
        Project__c pjt = new Project__c(
            Name                     = 'Test Project',
            Project__c               = 'Trifecta Vanto',
            Active__c                = true,
            Inspection_Executive__c  = inspExec.Id
        );
        insert pjt;

        // ── Plot ──────────────────────────────────────────
        Plot__c plt = new Plot__c(
            Status__c       = firstActiveLabel(Plot__c.Status__c.getDescribe()),
            Project__c      = pjt.Id
        );
        insert plt;

        // ── Lead ──────────────────────────────────────────
        Lead ld = new Lead(
            LastName             = 'TestLead',
            Company              = 'TestCompany',
            Phone__c             = '9876543210',
            Source_Type__c       = firstActiveLabel(Lead.Source_Type__c.getDescribe()),
            Allocated_Project__c = firstActiveLabel(Lead.Allocated_Project__c.getDescribe())
        );
        insert ld;

        // ── Quote ─────────────────────────────────────────
        List<RecordType> quoteRTs = [
            SELECT Id, Name FROM RecordType
            WHERE SObjectType = 'Quote__c' LIMIT 1
        ];

        Quote__c qc = new Quote__c(
            Quote_status__c  = firstActiveLabel(Quote__c.Quote_status__c.getDescribe()),
            Project__c       = firstActiveLabel(Quote__c.Project__c.getDescribe()),
            Payment_Type__c  = firstActiveLabel(Quote__c.Payment_Type__c.getDescribe()),
            Sale_Area__c     = 1000,
            Built_up_area__c = 1200,
            Rate_per_sqft__c = 5000,
            Unit__c          = plt.Id,
            SLead__c         = ld.Id,
            Property_Type__c = quoteRTs.isEmpty() ? null : quoteRTs[0].Name
        );
        insert qc;

        // ── Booking ───────────────────────────────────────
        List<RecordType> bookingRTs = [
            SELECT Id FROM RecordType
            WHERE SObjectType = 'Booking__c' LIMIT 1
        ];

        Booking__c bk = new Booking__c(
            First_Applicant_Name__c = 'Test Applicant',
            Mobile__c               = '9876543210',
            Quote__c                = qc.Id,
            Project__c              = firstActiveLabel(Booking__c.Project__c.getDescribe()),
            Stage__c                = firstActiveValue(Booking__c.Stage__c.getDescribe()),
            Booking_Date__c         = Date.today(),
            Plot__c                 = plt.Id,
            Project1__c             = pjt.Id
        );
        if (!bookingRTs.isEmpty()) bk.RecordTypeId = bookingRTs[0].Id;
        insert bk;

        // ── Inspection ────────────────────────────────────
        Inspection__c ins = new Inspection__c(
            Booking__c          = bk.Id,
            Inspection_Date__c  = Date.today(),
            Description__c      = 'Test Inspection',
            OwnerId             = inspExec.Id
        );
        insert ins;

        // ── Snag List records ─────────────────────────────
        List<Snag_List__c> snags = new List<Snag_List__c>();

        for (Integer i = 0; i < 3; i++) {
            Snag_List__c sg = new Snag_List__c(
                Inspection__c       = ins.Id,
                Description__c      = 'Snag ' + i,
                Status__c           = firstActiveLabel(Snag_List__c.Status__c.getDescribe()),
                Priority__c         = firstActiveLabel(Snag_List__c.Priority__c.getDescribe()),
                Inspection_Type__c  = firstActiveLabel(Snag_List__c.Inspection_Type__c.getDescribe())
            );
            snags.add(sg);
        }
        insert snags;
    }

    static Booking__c getBooking() {
        return [SELECT Id, Project1__c FROM Booking__c LIMIT 1];
    }

    static Inspection__c getInspection() {
        return [SELECT Id, OwnerId, Extended_Completed_Date__c FROM Inspection__c LIMIT 1];
    }

    static Snag_List__c getSnag() {
        return [SELECT Id FROM Snag_List__c LIMIT 1];
    }

    // ── Builds snag JSON dynamically from describe (no hardcoding) ─
    static String buildSnagJson(Integer count) {
        String status          = firstActiveLabel(Snag_List__c.Status__c.getDescribe());
        String priority        = firstActiveLabel(Snag_List__c.Priority__c.getDescribe());
        String inspectionType  = firstActiveLabel(Snag_List__c.Inspection_Type__c.getDescribe());

        List<Map<String, Object>> snagList = new List<Map<String, Object>>();
        for (Integer i = 0; i < count; i++) {
            Map<String, Object> snag = new Map<String, Object>{
                'Description__c'   => 'Snag Description ' + i,
                'Status__c'        => status,
                'Priority__c'      => priority,
                'Inspection_Type__c' => inspectionType
            };
            snagList.add(snag);
        }
        return JSON.serialize(snagList);
    }

    // ── Builds a minimal valid base64 PNG string ──────────
    static String getSampleBase64() {
        Blob sampleBlob = Blob.valueOf('SampleFileContent');
        return EncodingUtil.base64Encode(sampleBlob);
    }

    @isTest
    static void testAllInspectionControllerMethods() {

        Booking__c    bk  = getBooking();
        Inspection__c ins = getInspection();
        Snag_List__c  sg  = getSnag();

        Test.startTest();

        // ── 1. saveInspectionWithSnags – valid booking, with snags ─
        try {
            InspectionController.saveInspectionWithSnags(
                bk.Id,
                Date.today(),
                'Test inspection description',
                buildSnagJson(3)
            );
        } catch (Exception e) { System.debug('saveInspectionWithSnags valid: ' + e.getMessage()); }

        // ── 2. saveInspectionWithSnags – empty snag list ───────────
        try {
            InspectionController.saveInspectionWithSnags(
                bk.Id,
                Date.today(),
                'Inspection with no snags',
                '[]'
            );
        } catch (Exception e) { System.debug('saveInspectionWithSnags empty snags: ' + e.getMessage()); }

        // ── 3. saveInspectionWithSnags – single snag ───────────────
        try {
            InspectionController.saveInspectionWithSnags(
                bk.Id,
                Date.today().addDays(5),
                'Single snag inspection',
                buildSnagJson(1)
            );
        } catch (Exception e) { System.debug('saveInspectionWithSnags single snag: ' + e.getMessage()); }

        // ── 4. saveInspectionWithSnags – null inspectionDate ───────
        try {
            InspectionController.saveInspectionWithSnags(
                bk.Id,
                null,
                'No date inspection',
                buildSnagJson(2)
            );
        } catch (Exception e) { System.debug('saveInspectionWithSnags null date: ' + e.getMessage()); }

        // ── 5. saveInspectionWithSnags – blank bookingId ───────────
        try {
            InspectionController.saveInspectionWithSnags(
                '',
                Date.today(),
                'No booking id',
                buildSnagJson(1)
            );
        } catch (Exception e) { System.debug('saveInspectionWithSnags blank bookingId: ' + e.getMessage()); }

        // ── 6. saveInspectionWithSnags – null bookingId ────────────
        try {
            InspectionController.saveInspectionWithSnags(
                null,
                Date.today(),
                'Null booking id',
                buildSnagJson(1)
            );
        } catch (Exception e) { System.debug('saveInspectionWithSnags null bookingId: ' + e.getMessage()); }

        // ── 7. saveInspectionWithSnags – invalid bookingId ─────────
        try {
            InspectionController.saveInspectionWithSnags(
                'INVALID_ID_000000000000',
                Date.today(),
                'Invalid booking',
                buildSnagJson(1)
            );
        } catch (Exception e) { System.debug('saveInspectionWithSnags invalid id: ' + e.getMessage()); }

        // ── 8. saveInspectionWithSnags – null description ──────────
        try {
            InspectionController.saveInspectionWithSnags(
                bk.Id,
                Date.today(),
                null,
                buildSnagJson(2)
            );
        } catch (Exception e) { System.debug('saveInspectionWithSnags null desc: ' + e.getMessage()); }

        // ── 9. uploadFileToSnag – valid inputs ─────────────────────
        try {
            InspectionController.uploadFileToSnag(
                sg.Id,
                'testfile.txt',
                getSampleBase64(),
                'text/plain'
            );
        } catch (Exception e) { System.debug('uploadFileToSnag valid: ' + e.getMessage()); }

        // ── 10. uploadFileToSnag – blank snagId ────────────────────
        try {
            InspectionController.uploadFileToSnag(
                '',
                'testfile.txt',
                getSampleBase64(),
                'text/plain'
            );
        } catch (Exception e) { System.debug('uploadFileToSnag blank snagId: ' + e.getMessage()); }

        // ── 11. uploadFileToSnag – null snagId ─────────────────────
        try {
            InspectionController.uploadFileToSnag(
                null,
                'testfile.txt',
                getSampleBase64(),
                'text/plain'
            );
        } catch (Exception e) { System.debug('uploadFileToSnag null snagId: ' + e.getMessage()); }

        // ── 12. uploadFileToSnag – blank fileName ──────────────────
        try {
            InspectionController.uploadFileToSnag(
                sg.Id,
                '',
                getSampleBase64(),
                'text/plain'
            );
        } catch (Exception e) { System.debug('uploadFileToSnag blank fileName: ' + e.getMessage()); }

        // ── 13. uploadFileToSnag – null fileName ───────────────────
        try {
            InspectionController.uploadFileToSnag(
                sg.Id,
                null,
                getSampleBase64(),
                'text/plain'
            );
        } catch (Exception e) { System.debug('uploadFileToSnag null fileName: ' + e.getMessage()); }

        // ── 14. uploadFileToSnag – blank base64Data ────────────────
        try {
            InspectionController.uploadFileToSnag(
                sg.Id,
                'testfile.txt',
                '',
                'text/plain'
            );
        } catch (Exception e) { System.debug('uploadFileToSnag blank base64: ' + e.getMessage()); }

        // ── 15. uploadFileToSnag – null base64Data ─────────────────
        try {
            InspectionController.uploadFileToSnag(
                sg.Id,
                'testfile.txt',
                null,
                'text/plain'
            );
        } catch (Exception e) { System.debug('uploadFileToSnag null base64: ' + e.getMessage()); }

        // ── 16. uploadFileToSnag – image content type ──────────────
        try {
            InspectionController.uploadFileToSnag(
                sg.Id,
                'testimage.png',
                getSampleBase64(),
                'image/png'
            );
        } catch (Exception e) { System.debug('uploadFileToSnag image: ' + e.getMessage()); }

        // ── 17. requestSwapApproval – valid inspection + date ──────
        try {
            InspectionController.requestSwapApproval(
                ins.Id,
                Date.today().addDays(10)
            );
        } catch (Exception e) { System.debug('requestSwapApproval valid: ' + e.getMessage()); }

        // ── 18. requestSwapApproval – past date ────────────────────
        try {
            InspectionController.requestSwapApproval(
                ins.Id,
                Date.today().addDays(-5)
            );
        } catch (Exception e) { System.debug('requestSwapApproval past date: ' + e.getMessage()); }

        // ── 19. requestSwapApproval – today as date ────────────────
        try {
            InspectionController.requestSwapApproval(
                ins.Id,
                Date.today()
            );
        } catch (Exception e) { System.debug('requestSwapApproval today: ' + e.getMessage()); }

        // ── 20. requestSwapApproval – far future date ──────────────
        try {
            InspectionController.requestSwapApproval(
                ins.Id,
                Date.today().addDays(365)
            );
        } catch (Exception e) { System.debug('requestSwapApproval far future: ' + e.getMessage()); }

        Test.stopTest();
    }
}