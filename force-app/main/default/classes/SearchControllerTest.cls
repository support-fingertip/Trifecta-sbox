@IsTest
private class SearchControllerTest {

    @IsTest
    static void testSearchReturnsEmptyForBlankTerm() {
        List<SearchController.SearchResult> results = SearchController.search('');
        System.assertEquals(0, results.size(), 'Blank search term should return no results');
    }

    @IsTest
    static void testSearchReturnsEmptyForShortTerm() {
        List<SearchController.SearchResult> results = SearchController.search('a');
        System.assertEquals(0, results.size(), 'Single-character search term should return no results');
    }

    @IsTest
    static void testSearchReturnsEmptyForNullTerm() {
        List<SearchController.SearchResult> results = SearchController.search(null);
        System.assertEquals(0, results.size(), 'Null search term should return no results');
    }

    @IsTest
    static void testSearchWithValidTerm() {
        Account acc = new Account(Name = 'Test Account Alpha');
        insert acc;

        Test.setFixedSearchResults(new List<Id>{ acc.Id });

        Test.startTest();
        List<SearchController.SearchResult> results = SearchController.search('Test');
        Test.stopTest();

        System.assertNotEquals(0, results.size(), 'Search should return at least one result');
        Boolean found = false;
        for (SearchController.SearchResult r : results) {
            if (r.recordId == acc.Id) {
                found = true;
                System.assertEquals('Account', r.objectType);
                System.assertEquals('Test Account Alpha', r.name);
            }
        }
        System.assert(found, 'Inserted account should appear in results');
    }

    @IsTest
    static void testSearchResultFieldsPopulated() {
        Contact c = new Contact(FirstName = 'Jane', LastName = 'Doe', Email = 'jane@example.com');
        insert c;

        Test.setFixedSearchResults(new List<Id>{ c.Id });

        Test.startTest();
        List<SearchController.SearchResult> results = SearchController.search('Jane');
        Test.stopTest();

        Boolean found = false;
        for (SearchController.SearchResult r : results) {
            if (r.recordId == c.Id) {
                found = true;
                System.assertEquals('Contact', r.objectType);
                System.assertEquals('jane@example.com', r.detail);
            }
        }
        System.assert(found, 'Inserted contact should appear in results');
    }
}
