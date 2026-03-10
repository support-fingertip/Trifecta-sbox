public with sharing class SearchController {

    @AuraEnabled(cacheable=true)
    public static List<SearchResult> search(String searchTerm) {
        List<SearchResult> results = new List<SearchResult>();

        if (String.isBlank(searchTerm) || searchTerm.trim().length() < 2) {
            return results;
        }

        String sanitized = searchTerm.trim()
            .replaceAll('[\\?&|!{}\\[\\]\\^~\\*:\\\\\'"]', '\\\\$0');
        String sosl = 'FIND :sanitized IN ALL FIELDS RETURNING '
            + 'Account(Id, Name, Type), '
            + 'Contact(Id, Name, Email), '
            + 'Opportunity(Id, Name, StageName) '
            + 'LIMIT 20';

        List<List<SObject>> soslResults = Search.query(sosl);

        if (soslResults.size() > 0) {
            for (Account a : (List<Account>) soslResults[0]) {
                results.add(new SearchResult(a.Id, a.Name, 'Account', a.Type));
            }
        }
        if (soslResults.size() > 1) {
            for (Contact c : (List<Contact>) soslResults[1]) {
                results.add(new SearchResult(c.Id, c.Name, 'Contact', c.Email));
            }
        }
        if (soslResults.size() > 2) {
            for (Opportunity o : (List<Opportunity>) soslResults[2]) {
                results.add(new SearchResult(o.Id, o.Name, 'Opportunity', o.StageName));
            }
        }

        return results;
    }

    public class SearchResult {
        @AuraEnabled public String recordId;
        @AuraEnabled public String name;
        @AuraEnabled public String objectType;
        @AuraEnabled public String detail;

        public SearchResult(String recordId, String name, String objectType, String detail) {
            this.recordId = recordId;
            this.name = name;
            this.objectType = objectType;
            this.detail = detail;
        }
    }
}
