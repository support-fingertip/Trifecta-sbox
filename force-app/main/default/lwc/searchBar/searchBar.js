import { LightningElement, track } from 'lwc';
import search from '@salesforce/apex/SearchController.search';
import { NavigationMixin } from 'lightning/navigation';

const COLUMNS = [
    { label: 'Name', fieldName: 'name', type: 'text' },
    { label: 'Type', fieldName: 'objectType', type: 'text' },
    { label: 'Detail', fieldName: 'detail', type: 'text' },
    {
        type: 'action',
        typeAttributes: {
            rowActions: [{ label: 'View Record', name: 'view' }]
        }
    }
];

const SEARCH_DELAY = 300;

export default class SearchBar extends NavigationMixin(LightningElement) {
    @track results = [];
    @track isLoading = false;
    @track searchTerm = '';

    columns = COLUMNS;
    _searchTimeout;

    get hasResults() {
        return this.results.length > 0;
    }

    get showNoResults() {
        return (
            !this.isLoading &&
            this.searchTerm.trim().length >= 2 &&
            this.results.length === 0
        );
    }

    handleSearchTermChange(event) {
        this.searchTerm = event.target.value;
        clearTimeout(this._searchTimeout);

        if (this.searchTerm.trim().length < 2) {
            this.results = [];
            this.isLoading = false;
            return;
        }

        // Debounce the search to avoid excessive server calls
        // eslint-disable-next-line @lwc/lwc/no-async-operation
        this._searchTimeout = setTimeout(() => {
            this._performSearch();
        }, SEARCH_DELAY);
    }

    _performSearch() {
        this.isLoading = true;
        search({ searchTerm: this.searchTerm })
            .then((data) => {
                this.results = data;
            })
            .catch((error) => {
                console.error('Search error:', error);
                this.results = [];
            })
            .finally(() => {
                this.isLoading = false;
            });
    }

    handleRowAction(event) {
        const { name } = event.detail.action;
        const row = event.detail.row;
        if (name === 'view') {
            this[NavigationMixin.Navigate]({
                type: 'standard__recordPage',
                attributes: {
                    recordId: row.recordId,
                    actionName: 'view'
                }
            });
        }
    }
}
