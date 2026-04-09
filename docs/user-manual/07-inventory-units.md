# 07 — Inventory & Units

## Overview

This module describes how Trifecta's real-estate inventory is modelled in
Salesforce and how users view, block, book and swap units. Inventory is
organised in a three-level hierarchy: **Project → Block → Plot** (where
"Plot" represents any sellable unit — flat, plot, villa, or row house).

## Who uses it

- **Sales Executive** — views availability and blocks units for customers.
- **Sales Manager / Inventory Manager** — manages overall inventory
  status, re-activates units, sets holding limits.
- **CRM Executive** — references the unit to prepare agreements and
  possession documents.
- **Admin** — configures project-level pricing defaults and roles.

## Key objects and tabs

| Object | Tab | Purpose |
|---|---|---|
| `Project__c` | Project | Project master — one per development |
| `Block__c` | Block | Blocks / phases within a project |
| `Plot__c` | Plot | Sellable unit (flat, villa, row house, plot) |
| `Car_Parking__c` | — | Car parking inventory |
| — | Inventory Management | Visual inventory board (Aura `newInventoryManagment`) |

## Screens

| Screen | Type | Purpose |
|---|---|---|
| `newInventoryManagment` | Aura | Interactive inventory board used from the Inventory Management tab |
| `CarParkingLayoutComp` | Aura | Car parking allocation view |
| `SwappingUnitComponent` | Aura | Swap a booked unit with another available unit |
| `BulkUnitPriceUpdateComponent` | Aura | Bulk update unit prices |
| `UnitRedinessMail` | Aura | Send unit readiness email |
| `ProjectBoardNewComp` | Aura | Project-level summary board |

## Workflows

### 1. Browse inventory

1. Open the **Inventory Management** tab.
2. Filter by project, block, floor, facing, BHK type, area, status, etc.
3. The Aura component displays each `Plot__c` with its current
   `Status__c` (Available, Blocked, Booked, Sold, Cancelled, Not
   Released).
4. Click a plot to view details: `Plot_Number__c`, `Flat_No__c`,
   `Floor__c`, `Super_Built_up_Area__c`, `Carpet_Area__c`, corner /
   facing, price breakdown.

### 2. Block a unit for a customer

1. From the lead or site visit, open the inventory board.
2. Select an available unit and click **Block / Create Booking**.
3. The unit's `Status__c` becomes Blocked and `Holding_Time__c` starts
   counting down, governed by `Project__c.TAT_for_Holding_Unit__c`.
4. If the customer does not complete the booking within the TAT, the
   unit is released automatically back to Available.

### 3. Book a unit

Follow the [Booking & Quotation](03-booking-quotation.md) workflow.
When the booking is saved, the **Update Unit Status** flow and
`BookingTriggerHandler` set the plot to Booked and populate
`Booked_Date__c`.

### 4. Swap a booked unit

1. From the booking, click **Swapping Unit** (Aura
   `SwappingUnitComponent`, Apex `SwappingUnitController`).
2. Select the new unit. The component:
   - Releases the old unit back to Available.
   - Blocks / books the new unit.
   - Recalculates the cost sheet and payment schedule.
   - Carries forward receipts and cancels outstanding demands on the
     old unit if needed.
3. Review the summary and save.

### 5. Update multiple unit prices

1. Open **Bulk Unit Price Update** (Aura `BulkUnitPriceUpdateComponent`).
2. Filter the plots you want to update — typically by project / block.
3. Enter the new price components (`Basic_Price__c`, PLC, car parking,
   etc.).
4. Review and confirm. The change applies to all matching plots.

### 6. Send unit-ready notification

When a unit is construction-ready, click **Unit Readiness Mail** (Aura
`UnitRedinessMail`) to email the customer.

## Key fields on `Project__c`

The project master holds configuration used across bookings, demands and
documents. Selected fields:

**Identity & legal**
`Project_Id__c`, `Project__c`, `Project_Type__c`, `Project_Address__c`,
`Project_description__c`, `Project_Specification__c`,
`Project_Completion_Date__c`, `RERA_NO__c`, `Recitals__c`,
`SAN_HSN_CODE__c`, `CIN__c`, `CIN_Number__c`, `GSTIN__c`, `PAN__c`,
`State_Code__c`

**Sales & CRM roles**
`Sales_Head__c`, `Project_Sales_Head__c`, `CRM_Head__c`, `CRM_Manager__c`,
`CRM_executive__c`, `COO__c`, `Finance_User__c`,
`Inspection_Executive__c`, `Legal_Team__c`,
`New_Booking_CRM_Executive__c`, `Agreement_CRM_Executive__c`,
`Registration_CRM_Executive__c`, `Possession_Handover_CRM_Executive__c`,
`Cancellation_CRM_Executive__c`, `Customer_Service_CRM_Executive__c`,
`Demands_Collections_CRM_Executive__c`, `CRM_Executive_L1__c` through
`CRM_Executive_L4__c`

**Pricing & charges**
`Booking_Amount__c`, `Clubhouse_Charges__c`,
`Franking_Shifting_Rate__c`, `Guideline_Value_Charges__c`,
`GST_on_Aggrement__c`, `GST_on_Other__c`, `Interest_Rate__c`,
`W_E_Charges__c`, `Maintenance_Charge_Rate__c`, `Home_Automation__c`

**Banking**
`Bank_Name__c`, `Bank_Account_Number__c`, `Bank_Address__c`, `IFSC__c`,
`Branch__c`, `Beneficiary_Name__c`, `Financier__c`,
`Cheque_Favoring_Name__c`, `Company_Name__c`, `Company_Address__c`

**Inventory counters** (read-only, rolled up)
`Total_Units__c`, `Available_Units__c`, `Blocked_Units__c`,
`Blocked_by_Management_Units__c`, `Blocked_by_Investor_Units__c`,
`Booked_Units__c`, `Sold_Units__c`, `Not_Released_Units__c`,
`Total_Car_Parking__c`, `Total_Available_Car_Parking__c`,
`Total_Alotted_Car_Parking__c`, `Total_Blocked_Car_Parking__c`

## Key fields on `Block__c`

`Project__c`, `Project_Name__c`, `Phase__c`, `RERA_NO__c`,
`Type__c`, `Construction_Company_Name__c`, `Land_Company_Name__c`,
`Bank_Name__c`, `Account_Number__c`, `IFSC_Code__c`, `Branch__c`,
`Type_of_Account__c`, `Intrest_Percentage__c`, `CRM_Head__c`,
`CRM_Manager__c`, `CRM_Executive__c`, `Inspection_Executive__c`

## Key fields on `Plot__c`

`Project_Name__c`, `Project__c`, `Block_Lookup__c`, `Block_Name__c`,
`Plot_Number__c`, `Flat_No__c`, `Floor__c`, `Tower__c`, `Wing__c`,
`Unit_Type__c`, `Unit_Configuration_Name__c`, `BHK_Type__c`,
`Flat_Type__c`, `Plot_Type__c`, `Property_Type__c`, `Phase_Detail__c`,
`Plot_Size__c`, `Plot_Land_Area__c`, `Super_Built_up_Area__c`,
`Carpet_Area__c`, `Built_up_area__c`, `Balcony_in_SFT__c`,
`Terrace_Area_Sq_ft__c`, `Unit_Facing_Direction__c`, `Corner__c`,
`Corner_Non_Corner__c`, `Price__c`, `Basic_Price__c`, `Basic_Cost1__c`,
`Basic_Cost_with_CP__c`, `Rate_per_sqft__c`, `PLC__c`, `PLC_Charges__c`,
`Club_House__c`, `Clubhouse_Charges__c`, `Corpus_Fund__c`,
`Maintenance_Charge__c`, `GST__c`, `Sale_Consideration__c`,
`Total_Consideration_with_taxes_and_other__c`, `Total_Cost__c`,
`UDS__c`, `Undivided_Share_of_Land__c`, `Status__c`, `Booked_Date__c`,
`Holding_Time__c`, `Sub_total__c`, `Premium_Location_Charge__c`,
`HOD_for_Selling__c`, `TL__c`, `RM__c`

## Automations you will experience

| Flow / Trigger | When it fires | Effect |
|---|---|---|
| `BookingTrigger` / `BookingTriggerHandler` | Booking insert/update | Sets Plot status, Booked_Date, rollup counters |
| `Update_Unit_Status` | Booking / cancellation / swap | Keeps Plot `Status__c` consistent |
| `SwappingUnitController` | Unit swap | Atomic swap of two plots' statuses |
| Holding time job | Nightly (scheduled Apex) | Releases plots whose hold has expired |

## Common issues and tips

- If a plot is stuck in Blocked, check if a booking in "Booking
  Initiated" stage is holding it. The plot cannot be re-used until the
  booking is saved/cancelled.
- Bulk price updates do **not** retroactively change existing bookings —
  they only affect new quotes and bookings created afterwards.
- Inventory counters on the project (Total Units, Available Units,
  Booked Units, etc.) are rolled up by trigger code. If they drift, ask
  an admin to re-run the rollup batch.
- Car parking is a separate object (`Car_Parking__c`) and is not
  implicitly bundled with a plot — allocate it explicitly.
- `Not_Released_Units__c` counts units that are withheld from sale —
  they are not the same as "Blocked".
