# Trifecta-sbox

A Salesforce DX project with search functionality across Accounts, Contacts, and Opportunities.

## Features

### Search

The `searchBar` Lightning Web Component provides a global search experience:

- **Debounced input** — searches fire 300 ms after the user stops typing, avoiding unnecessary server calls.
- **Multi-object results** — returns matching Accounts, Contacts, and Opportunities in a single list.
- **Navigate on click** — the "View Record" row action opens the selected record's standard page.
- **Minimum 2 characters** — queries are skipped for very short terms to avoid noisy results.

#### Components

| File | Description |
|------|-------------|
| `force-app/main/default/classes/SearchController.cls` | Apex controller exposing the `search` AuraEnabled method via SOSL |
| `force-app/main/default/classes/SearchControllerTest.cls` | Apex unit tests for `SearchController` |
| `force-app/main/default/lwc/searchBar/` | Lightning Web Component (HTML + JS + metadata) |
| `manifest/package.xml` | Deployment manifest |

#### Deploying

```bash
sf project deploy start --manifest manifest/package.xml --target-org <alias>
```

#### Running Tests

```bash
sf apex run test --class-names SearchControllerTest --target-org <alias> --result-format human
```