@isTest
public class FileUploadControllerTest {

    static String base64FileData = EncodingUtil.base64Encode(Blob.valueOf('Test File Content'));

    // Create a parent record (Account)
    private static Account createParentRecord() {
        Account acc = new Account(Name = 'Test Parent');
        insert acc;
        return acc;
    }

    @isTest
    public static void testFileUpload_NewFile() {
        Account acc = createParentRecord();

        Test.startTest();
        String docId = FileUploadController.fileUpload(
            acc.Id,
            'TestDoc.pdf',
            'pdf',
            base64FileData,
            'TestDocument'
        );
        Test.stopTest();

        System.assertNotEquals(null, docId, 'Document ID should be returned');

        ContentDocument doc = [
            SELECT Id, Title FROM ContentDocument WHERE Id = :docId LIMIT 1
        ];
        System.assertEquals('TestDocument', doc.Title, 'Document name should match');

        ContentDocumentLink link = [
            SELECT Id, LinkedEntityId FROM ContentDocumentLink WHERE ContentDocumentId = :docId LIMIT 1
        ];
        System.assertEquals(acc.Id, link.LinkedEntityId, 'File should be linked to Parent');
    }

    @isTest
    public static void testMultiFileUpload() {
        Account acc = createParentRecord();

        Test.startTest();
        String docId = FileUploadController.multifileUpload(
            acc.Id,
            'Invoice.pdf',
            'pdf',
            base64FileData,
            'InvoiceDoc',
            false
        );
        Test.stopTest();

        System.assertNotEquals(null, docId, 'Document ID should be returned');

        ContentDocument doc = [
            SELECT Id, Title FROM ContentDocument WHERE Id = :docId LIMIT 1
        ];
        System.assert(doc.Title.startsWith('InvoiceDoc-'), 'Title should use pattern invoiceDoc-name');
    }

    @isTest
    public static void testGetFiles() {
        Account acc = createParentRecord();

        // Upload one file
        String docId = FileUploadController.fileUpload(
            acc.Id, 'File1.pdf', 'pdf', base64FileData, 'File1'
        );

        Test.startTest();
        List<FileUploadController.FileWrapper> files =
            FileUploadController.getFiles(acc.Id, 'File1');
        Test.stopTest();

        System.assertEquals(1, files.size(), 'Should return one file');
        System.assertEquals(docId, files[0].fileId);
    }

    @isTest
    public static void testGetMultiFiles() {
        Account acc = createParentRecord();

        // Upload multiple files with similar prefix
        FileUploadController.multifileUpload(
            acc.Id, 'A.pdf', 'pdf', base64FileData, 'Prefix', true
        );
        FileUploadController.multifileUpload(
            acc.Id, 'B.pdf', 'pdf', base64FileData, 'Prefix', true
        );

        Test.startTest();
        List<FileUploadController.FileWrapper> files =
            FileUploadController.getMultiFiles(acc.Id, 'Prefix');
        Test.stopTest();

        System.assertEquals(2, files.size(), 'Should return two files');
    }

    @isTest
    public static void testDeleteFile() {
        Account acc = createParentRecord();

        // Upload
        String docId = FileUploadController.fileUpload(
            acc.Id, 'DeleteMe.pdf', 'pdf', base64FileData, 'DeleteMe'
        );

        Test.startTest();
        FileUploadController.deleteFileFromSalesforce(docId);
        Test.stopTest();

        Integer countDocs = [
            SELECT count() FROM ContentDocument WHERE Id = :docId
        ];
        System.assertEquals(0, countDocs, 'Document should be deleted');
    }

    @isTest
    public static void testFileUpload_ExistingFileVersioning() {
        Account acc = createParentRecord();

        // Upload initial version
        String originalDocId = FileUploadController.fileUpload(
            acc.Id, 'VersionTest.pdf', 'pdf', base64FileData, 'VersionTest'
        );

        // Upload new version of same file using the same Title
        Test.startTest();
        String newDocId = FileUploadController.fileUpload(
            acc.Id, 'VersionTest.pdf', 'pdf', base64FileData, 'VersionTest'
        );
        Test.stopTest();

        System.assertEquals(originalDocId, newDocId, 'New version should reuse same ContentDocument');
    }
}