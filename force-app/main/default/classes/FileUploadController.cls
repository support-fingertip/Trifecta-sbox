public with sharing class FileUploadController {
    
    private static final String ISSUE_UPLOADING_FILE = 'There is a problem in uploading the file';
    
    @AuraEnabled
    public static String fileUpload(String parentId, String name, String fileType, String fileData, String documentName) {
        try {
            System.debug('**Uploading File: ' + documentName + '**');
            
            // Ensure parentId is valid
            if (String.isEmpty(parentId)) {
                throw new AuraHandledException('Parent Record ID is required.');
            }
            
            // Step 1: Check if the file already exists
            List<ContentDocument> existingDocs = [ SELECT Id FROM ContentDocument  WHERE Title = :documentName  ORDER BY LatestPublishedVersionId DESC  LIMIT 1 ];
            
            ContentVersion fileVersion = new ContentVersion();
            fileVersion.Title = documentName;
            fileVersion.PathOnClient = name;
            fileVersion.VersionData = EncodingUtil.base64Decode(fileData);
            
            if (!existingDocs.isEmpty()) {
                // If the file exists, create a new version
                fileVersion.ContentDocumentId = existingDocs[0].Id;
            } else {
                // For new files, set FirstPublishLocationId to link it to the parent record
                fileVersion.FirstPublishLocationId = parentId;
            }
            
            insert fileVersion;
            System.debug('**FileVersion Inserted: ' + fileVersion.Id + '**');
            
            // Fetch ContentDocumentId from the inserted ContentVersion
            ContentDocument newDoc = [ SELECT Id FROM ContentDocument  WHERE LatestPublishedVersionId = :fileVersion.Id  LIMIT 1 ];
            String newDocId = newDoc.Id;
            
            // Step 2: Always link the document to the parent record
            try {
                ContentDocumentLink newLink = new ContentDocumentLink();
                newLink.LinkedEntityId = parentId;
                newLink.ShareType = 'V';
                newLink.ContentDocumentId = newDocId;
                   newLink.Visibility = 'AllUsers';
                insert newLink;
                System.debug('**ContentDocumentLink Created: ' + newLink.Id + '**');
            } catch (DmlException linkEx) {
                System.debug('Link may already exist. DML Error: ' + linkEx.getMessage());
            }
            
            System.debug('**File Successfully Uploaded and Linked**');
            return newDocId;
            
        } catch (Exception ex) {
            System.debug('### Exception Details ###');
            System.debug('Line Number: ' + ex.getLineNumber());
            System.debug('Error Message: ' + ex.getMessage());
            System.debug('Stack Trace: ' + ex.getStackTraceString());
            throw new AuraHandledException('Exception: ' + ex.getMessage() + ' on Line Number: ' + ex.getLineNumber());
        }
    }
    
    @AuraEnabled
    public static String multifileUpload(String parentId, String name, String fileType, String fileData, String documentName,Boolean isPicklist) {
        try {
            System.debug('**Uploading File: ' + name + '**');
            
            // Ensure parentId is valid
            if (String.isEmpty(parentId)) {
                throw new AuraHandledException('Parent Record ID is required.');
            }
            
            // Step 1: Create a new ContentVersion object without versioning
            ContentVersion fileVersion = new ContentVersion();
            fileVersion.Title = isPicklist == true? documentName : documentName+'-'+name;  // Use 'name' as the title
            fileVersion.PathOnClient = name;
            fileVersion.VersionData = EncodingUtil.base64Decode(fileData);
            
            // Set the FirstPublishLocationId to link it to the parent record
            fileVersion.FirstPublishLocationId = parentId;
            
            insert fileVersion;
            System.debug('**FileVersion Inserted: ' + fileVersion.Id + '**');
            
            // Fetch ContentDocumentId from the inserted ContentVersion
            ContentDocument newDoc = [
                SELECT Id FROM ContentDocument 
                WHERE LatestPublishedVersionId = :fileVersion.Id
                LIMIT 1
            ];
            String newDocId = newDoc.Id;
            
            System.debug('**ContentDocumentId Retrieved: ' + newDocId + '**');
            
            // Step 2: Always link the document to the parent record
            try {
                ContentDocumentLink newLink = new ContentDocumentLink();
                newLink.LinkedEntityId = parentId;
                newLink.ShareType = 'V';
                newLink.ContentDocumentId = newDocId;
                insert newLink;
                System.debug('**ContentDocumentLink Created: ' + newLink.Id + '**');
            } catch (DmlException linkEx) {
                System.debug('Link may already exist. DML Error: ' + linkEx.getMessage());
            }
            
            System.debug('**File Successfully Uploaded and Linked**');
            
            // Confirm that the file is available in ContentDocument
            ContentDocument verifyDoc = [SELECT Id, Title FROM ContentDocument WHERE Id = :newDocId LIMIT 1];
            System.debug('**File Verified: ' + verifyDoc.Title + '**');
            
            return newDocId;
            
        } catch (Exception ex) {
            System.debug('### Exception Details ###');
            System.debug('Line Number: ' + ex.getLineNumber());
            System.debug('Error Message: ' + ex.getMessage());
            System.debug('Stack Trace: ' + ex.getStackTraceString());
            throw new AuraHandledException('Exception: ' + ex.getMessage() + ' on Line Number: ' + ex.getLineNumber());
        }
    }
    
    
    // Wrapper class for returning file metadata
    public class FileWrapper {
        @AuraEnabled public String fileId;
        @AuraEnabled public String title;
        @AuraEnabled public String fileExtension;
        @AuraEnabled public String previewUrl;
        @AuraEnabled public String downloadUrl;
        
        public FileWrapper(ContentDocumentLink docLink) {
            this.fileId = docLink.ContentDocumentId;
            this.title = docLink.ContentDocument.Title;
            this.fileExtension = docLink.ContentDocument.FileExtension;
            this.previewUrl = '/sfc/servlet.shepherd/version/renditionDownload?rendition=THUMB120BY90&versionId=' + docLink.ContentDocument.LatestPublishedVersionId;
            this.downloadUrl = '/sfc/servlet.shepherd/document/download/' + docLink.ContentDocumentId;
        }
    }
    
    // Get files linked to a specific record
    @AuraEnabled
    public static List<FileWrapper> getFiles(String recordId, String fileName) {
        List<FileWrapper> files = new List<FileWrapper>();
        
        List<ContentDocumentLink> documentLinks = [
            SELECT Id, LinkedEntityId, ContentDocumentId, 
            ContentDocument.Title, ContentDocument.FileExtension, 
            ContentDocument.LatestPublishedVersionId
            FROM ContentDocumentLink
            WHERE LinkedEntityId = :recordId
        ];
        
        for (ContentDocumentLink docLink : documentLinks) {
            if (String.isEmpty(fileName) || docLink.ContentDocument.Title == fileName) {
                files.add(new FileWrapper(docLink));
            }
        }
        return files;
    }
    
    @AuraEnabled
    public static List<FileWrapper> getMultiFiles(String recordId, String fileName) {
        List<FileWrapper> files = new List<FileWrapper>();
        
        // Construct the SOQL query with LIKE operator for fileName to match starting string
        String fileNameFilter = String.isEmpty(fileName) ? '%' : fileName + '%';
        
        List<ContentDocumentLink> documentLinks = [
            SELECT Id, LinkedEntityId, ContentDocumentId, 
            ContentDocument.Title, ContentDocument.FileExtension, 
            ContentDocument.LatestPublishedVersionId
            FROM ContentDocumentLink
            WHERE LinkedEntityId = :recordId
            AND ContentDocument.Title LIKE :fileNameFilter
        ];
        
        for (ContentDocumentLink docLink : documentLinks) {
            files.add(new FileWrapper(docLink));
        }
        
        return files;
    }
    @AuraEnabled
    public static void deleteFileFromSalesforce(String fileId) {
        try {
            // Fetch the ContentDocument using the ContentDocumentId (fileId)
            ContentDocument contentDoc = [SELECT Id FROM ContentDocument WHERE Id = :fileId LIMIT 1];
            
            // Deleting the ContentDocument will also delete all associated ContentVersions
            delete contentDoc;
            
            // Log success
            System.debug('File successfully deleted: ' + contentDoc.Id);
            
        } catch (Exception e) {
            // Handle any errors
            throw new AuraHandledException('Error deleting file: ' + e.getMessage());
        }
    }
}