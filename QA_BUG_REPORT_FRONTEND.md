# Frontend QA Bug Report - Trifecta Real Estate CRM

**Application:** Trifecta SFDX - Real Estate CRM (Salesforce Lightning)
**Report Type:** Frontend Manual Testing Bug Report
**QA Engineer:** Senior QA (4 Years Experience)
**Date:** 2026-03-23
**Environment:** Salesforce Lightning Experience
**Modules Covered:** Booking, Quote, Lead, Demand, Receipt, Inspection, Site Visit, File Upload

---

## BUG-001: Wrong File Uploaded for "Proof of Address" (4th File Upload)

| Field | Details |
|-------|---------|
| **Severity** | Critical |
| **Module** | Create Booking |
| **Component** | CreateBooking > File Upload Section |
| **File Reference** | `aura/CreateBooking/CreateBookingHelper.js` (Lines 327-338) |

**Steps to Reproduce:**
1. Navigate to Create Booking form
2. Fill in all mandatory booking details
3. Upload file in 1st upload slot (e.g., Aadhaar Front)
4. Upload file in 2nd upload slot (e.g., Aadhaar Back)
5. Upload file in 3rd upload slot (e.g., PAN Card)
6. Upload file in 4th upload slot (Proof of Address) - upload a DIFFERENT document
7. Submit the booking

**Expected Result:** All 4 files should be uploaded correctly to their respective categories. The 4th file should be saved as "Proof of Address."

**Actual Result:** The 4th file upload calls `upload3Helper()` instead of `upload4Helper()`. The Proof of Address document may upload incorrectly or overwrite the 3rd file.

**Root Cause:** In `CreateBookingHelper.js`, line 337 calls `helper.upload3Helper(component, bookingId)` for `fuploader4` instead of `upload4Helper`.

---

## BUG-002: File Upload Failures Show No Error to User

| Field | Details |
|-------|---------|
| **Severity** | High |
| **Module** | File Upload (All modules) |
| **Component** | FileUploader |
| **File Reference** | `aura/FileUploader/FileUploaderController.js` (Lines 16-22) |

**Steps to Reproduce:**
1. Navigate to any form with file upload (Booking, Inspection, etc.)
2. Upload a file while simulating poor network (throttle in DevTools)
3. Wait for upload to fail or timeout
4. Observe the UI

**Expected Result:** An error toast/message should appear telling the user "File upload failed. Please try again."

**Actual Result:** No error message is shown. The code has a comment `// We ignore errors here for simplicity`. The user believes the upload succeeded.

**Business Impact:** Customers may proceed with incomplete document submissions, causing delays in booking/agreement processing.

---

## BUG-003: Email Field Accepts Invalid Email Addresses

| Field | Details |
|-------|---------|
| **Severity** | High |
| **Module** | Create Booking |
| **Component** | CreateBooking Form - Personal Details |
| **File Reference** | `aura/CreateBooking/CreateBooking.cmp` (Line 362) |

**Steps to Reproduce:**
1. Navigate to Create Booking form
2. Go to the Primary Email field
3. Enter an invalid email: `notanemail`, `test@`, `@domain.com`, `test @email.com`
4. Tab out of the field or submit the form

**Expected Result:** The field should show a validation error: "Please enter a valid email address" and prevent form submission.

**Actual Result:** The field accepts any text input because it uses `type="text"` instead of `type="email"`. No email format validation occurs.

**Additional Check:** Also verify email fields on:
- Co-Applicant email fields
- Lead creation forms
- Site Visit forms

---

## BUG-004: App Crashes When Site Visit Returns Malformed Data

| Field | Details |
|-------|---------|
| **Severity** | High |
| **Module** | Site Visit |
| **Component** | SiteVisitForm |
| **File Reference** | `aura/SiteVisitForm/SiteVisitFormController.js` (Line 40) |

**Steps to Reproduce:**
1. Navigate to the Site Visit Form
2. Search for a lead record
3. If the server returns any unexpected or malformed response (simulate by entering special characters in search)
4. Observe the component behavior

**Expected Result:** A user-friendly error message should appear: "Unable to load lead details. Please try again."

**Actual Result:** The component crashes with an unhandled JavaScript error. `JSON.parse()` is called without a try-catch block. The user sees a white screen or broken component.

**Also Affects:** Inspection Snag component (`aura/InspectionSnag/InspectionSnagController.js`) - same JSON parse issue.

---

## BUG-005: Booking Modal - Screen Reader Cannot Identify Dialog

| Field | Details |
|-------|---------|
| **Severity** | Medium |
| **Module** | Create Booking |
| **Component** | CreateBooking Modal Dialog |
| **File Reference** | `aura/CreateBooking/CreateBooking.cmp` (Line 91) |

**Steps to Reproduce:**
1. Navigate to a record where "Create Booking" quick action is available
2. Click "Create Booking" button to open the modal
3. Use a screen reader (NVDA, JAWS, or VoiceOver) to read the modal
4. Try pressing ESC key to close the modal
5. Try using Tab key to navigate through modal fields

**Expected Result:**
- Screen reader announces the modal title/purpose
- ESC key closes the modal
- Tab key cycles through fields within the modal (focus trap)

**Actual Result:**
- `aria-labelledby="header43"` points to non-existent element (actual heading ID is `modal-heading-01`) - screen reader cannot identify the dialog
- No `aria-modal="true"` attribute present
- No focus trap - Tab key moves focus behind the modal
- ESC key does not close the modal

---

## BUG-006: Co-Applicant Form Validation Shows Generic Error

| Field | Details |
|-------|---------|
| **Severity** | Medium |
| **Module** | Create Booking |
| **Component** | CreateBooking - Co-Applicant Section |
| **File Reference** | `aura/CreateBooking/CreateBookingHelper.js` (Lines 193-257) |

**Steps to Reproduce:**
1. Navigate to Create Booking form
2. Add a Co-Applicant section
3. Fill in some fields but leave mandatory fields empty (e.g., leave Name blank, fill Phone)
4. Click Save/Submit

**Expected Result:** Each invalid field should be highlighted in red with a specific error message (e.g., "Co-Applicant Name is required").

**Actual Result:** A single generic toast notification appears. Individual fields are not highlighted. The user does not know which specific co-applicant field is missing.

---

## BUG-007: No Loading Indicator During Booking Form Submission

| Field | Details |
|-------|---------|
| **Severity** | Medium |
| **Module** | Multiple Modules |
| **Component** | Various forms |

**Steps to Reproduce:**
1. Open any form (Create Booking, Create Quote, Raise Demand)
2. Fill in all details and click Submit/Save
3. While the server processes, quickly click Submit again

**Expected Result:**
- A spinner/loading indicator should appear immediately on first click
- Submit button should be disabled to prevent double submission

**Actual Result:** Inconsistent behavior across modules:
- Some forms use `isLoading`, others use `showSpinner`, others use `spinner` - no consistent pattern
- Some forms allow double-click, potentially creating duplicate records

**Test across these modules:**
- Create Booking
- Create Quote
- Raise Demand
- Site Visit Form
- Inspection Form

---

## BUG-008: Back Button Breaks Navigation in Lead Component

| Field | Details |
|-------|---------|
| **Severity** | Medium |
| **Module** | Lead Management |
| **Component** | newLeadComponent |
| **File Reference** | `aura/newLeadComponent/newLeadComponentController.js` (Line 60) |

**Steps to Reproduce:**
1. Navigate to Lead list view
2. Open a Lead record
3. Click "New Lead" quick action or component
4. Fill in some details
5. Click the Cancel/Back button

**Expected Result:** User should return to the previous Salesforce page (Lead record or list view) using Salesforce's navigation framework.

**Actual Result:** Uses browser `history.back()` which may:
- Navigate to a non-Salesforce page if user came from an external link
- Break navigation if opened from a modal/quick action
- Cause unexpected behavior in Lightning Experience console navigation

---

## BUG-009: Phone Number Validation Inconsistent Across Forms

| Field | Details |
|-------|---------|
| **Severity** | Medium |
| **Module** | Multiple Modules |
| **Component** | Booking, Lead, Site Visit, Co-Applicant forms |

**Steps to Reproduce:**
1. Navigate to Create Booking form and enter phone: `123` (less than 10 digits) - check validation
2. Navigate to Lead form and enter the same phone - check validation
3. Navigate to Site Visit form and enter the same phone - check validation
4. Try entering: `+911234567890` (with country code)
5. Try entering: `12345 67890` (with space)
6. Try entering: `1234567890123` (13 digits)

**Expected Result:** All forms should validate phone numbers consistently - exactly 10 digits, numeric only, same error message.

**Actual Result:**
- Booking form uses regex `/^[0-9]{10}$/`
- Other forms may not validate at all or use different patterns
- Some forms accept alphabetic characters in phone fields

---

## BUG-010: Commented-Out Validation for Payment Mode

| Field | Details |
|-------|---------|
| **Severity** | Medium |
| **Module** | Create Booking |
| **Component** | CreateBooking - Payment Details |
| **File Reference** | `aura/CreateBooking/CreateBookingHelper.js` (Lines 153-159) |

**Steps to Reproduce:**
1. Navigate to Create Booking form
2. Go to Payment Details section
3. Select "Credit Card" or "Debit Card" as payment mode
4. Leave the Card Number field empty
5. Submit the form

**Expected Result:** If payment mode is Credit/Debit Card, the Card Number field should be mandatory with format validation.

**Actual Result:** Card number validation is commented out in the code. Users can submit bookings with Credit/Debit Card payment mode without entering a card number.

---

## BUG-011: Bulk Raise Demand - No Confirmation Before Mass Action

| Field | Details |
|-------|---------|
| **Severity** | Medium |
| **Module** | Demand Management |
| **Component** | BulkRaiseDemand |
| **File Reference** | `aura/BulkRaiseDemand/BulkRaiseDemandController.js` |

**Steps to Reproduce:**
1. Navigate to Bulk Raise Demand component
2. Select multiple booking records (e.g., 50 bookings)
3. Click "Raise Demand" button

**Expected Result:** A confirmation dialog should appear: "You are about to raise demands for 50 bookings. This will send notifications to customers. Are you sure?"

**Actual Result:** Demands are raised immediately without confirmation. SMS/WhatsApp notifications are triggered for all selected customers with no way to undo.

---

## BUG-012: File Upload Has No File Type Restriction

| Field | Details |
|-------|---------|
| **Severity** | Medium |
| **Module** | File Upload (All modules) |
| **Component** | FileUploader |
| **File Reference** | `aura/FileUploader/` and `classes/FileUploadController.cls` |

**Steps to Reproduce:**
1. Navigate to any file upload area (Booking, Inspection, etc.)
2. Try uploading a `.exe` file
3. Try uploading a `.bat` or `.sh` file
4. Try uploading a very large file (e.g., 100MB)
5. Try uploading a file with no extension

**Expected Result:**
- Only allowed file types should be accepted (PDF, JPG, PNG, DOC)
- A file size limit should be enforced (e.g., max 10MB)
- Error messages for unsupported types/sizes

**Actual Result:** All file types and sizes are accepted without restriction. No client-side or server-side validation exists.

---

## BUG-013: Inspection Snag Component Crashes on Special Characters

| Field | Details |
|-------|---------|
| **Severity** | Medium |
| **Module** | Inspection |
| **Component** | InspectionSnag |
| **File Reference** | `aura/InspectionSnag/InspectionSnagController.js` |

**Steps to Reproduce:**
1. Open an Inspection record with Snag List
2. Add a snag with description containing special characters: `<script>alert('test')</script>`
3. Add a snag with description containing: `'; DROP TABLE--`
4. Save and reload the page

**Expected Result:** Special characters should be escaped/sanitized. The text should display as literal text, not be interpreted.

**Actual Result:** No input sanitization on the frontend. Characters are passed directly to the server. Test if they render unsafely when the snag list is displayed back.

---

## BUG-014: Inventory Management Component - No Responsive Design

| Field | Details |
|-------|---------|
| **Severity** | Low |
| **Module** | Inventory/Project Board |
| **Component** | newInventoryManagment, ProjectBoardNewComp |
| **File Reference** | `aura/newInventoryManagment/newInventoryManagment.css` (572 lines), `aura/ProjectBoardNewComp/ProjectBoardNewComp.css` (564 lines) |

**Steps to Reproduce:**
1. Open the Inventory Management or Project Board component
2. Resize browser to tablet width (768px)
3. Resize browser to mobile width (375px)
4. Check on iPad/tablet device

**Expected Result:** Layout should adjust responsively - tables should scroll horizontally, forms should stack vertically, all content should be accessible.

**Actual Result:** Fixed-width CSS values used. Layout breaks on smaller screens. Content may overflow or become unreachable.

---

## BUG-015: Create Quote - Plot/Unit Selection Doesn't Validate Availability at Submit

| Field | Details |
|-------|---------|
| **Severity** | Medium |
| **Module** | Quote Creation |
| **Component** | CreateQuote |
| **File Reference** | `aura/CreateQuote/` and `classes/CreateQuoteController.cls` |

**Steps to Reproduce:**
1. Open Create Quote for a project
2. Select a Block and Unit/Plot
3. Have another user simultaneously select the same Unit/Plot
4. Both users click Save at roughly the same time

**Expected Result:** Only one quote should be created. The second user should see "This unit is no longer available."

**Actual Result:** No real-time availability check occurs at submission time. Both quotes may be created for the same unit, leading to double-booking. The unit status check (`if(unitstatus == 'Booked')`) uses loose equality and only checks at form load, not at submission time.

---

## BUG-016: Bulk Reassignment - Error Message Shows Technical Details

| Field | Details |
|-------|---------|
| **Severity** | Low |
| **Module** | Lead Management |
| **Component** | bulkReassignment (LWC) |
| **File Reference** | `lwc/bulkReassignment/bulkReassignment.js` (Lines 371-377) |

**Steps to Reproduce:**
1. Navigate to Bulk Lead Reassignment
2. Select multiple leads
3. Try to reassign while offline or with server error

**Expected Result:** User-friendly message: "Unable to reassign leads. Please try again or contact support."

**Actual Result:** Technical error object/details may be shown to the user. Error handling extracts `error.body.message` which may contain Apex exception stack traces or SOQL errors visible to the end user.

---

## BUG-017: Age Validation Allows Unrealistic Values

| Field | Details |
|-------|---------|
| **Severity** | Low |
| **Module** | Create Booking |
| **Component** | CreateBooking - Co-Applicant |
| **File Reference** | `aura/CreateBooking/CreateBookingHelper.js` |

**Steps to Reproduce:**
1. Open Create Booking form
2. Add a Co-Applicant
3. Enter Age as `17` - should be rejected (min 18)
4. Enter Age as `101` - should be rejected (max 100)
5. Enter Age as `0` or negative number
6. Enter Age as `18.5` (decimal)

**Expected Result:** Age must be a whole number between 18 and 100. Clear error message for out-of-range values.

**Actual Result:** While code checks `age < 18 || age > 100`, verify:
- Does it handle decimal values?
- Does it handle 0 or negative numbers?
- Is the error message user-friendly?
- Does the HTML `min="18"` attribute match the JS validation?

---

## BUG-018: PAN Card Validation Only Works on Uppercase

| Field | Details |
|-------|---------|
| **Severity** | Low |
| **Module** | Create Booking |
| **Component** | CreateBooking - Document Details |

**Steps to Reproduce:**
1. Open Create Booking form
2. Enter PAN: `abcde1234f` (lowercase)
3. Enter PAN: `ABCDE1234F` (uppercase - valid)
4. Enter PAN: `AbCdE1234F` (mixed case)

**Expected Result:** PAN field should auto-convert to uppercase OR accept both cases. Pattern: `^[A-Z]{5}[0-9]{4}[A-Z]{1}$`

**Actual Result:** Validation regex only matches uppercase. If user types lowercase, validation fails silently or shows generic error without suggesting "Please use uppercase letters."

---

## BUG-019: Console Logs Expose Data in Browser Developer Tools

| Field | Details |
|-------|---------|
| **Severity** | Low |
| **Module** | All Modules |
| **Component** | All JavaScript Controllers/Helpers |

**Steps to Reproduce:**
1. Open browser Developer Tools (F12) > Console tab
2. Navigate through the application (open bookings, quotes, leads)
3. Perform actions like creating records, searching, uploading files
4. Observe console output

**Expected Result:** No sensitive data or debug information in the browser console in production.

**Actual Result:** 521+ `console.log` and `console.error` statements throughout the codebase. May expose:
- Record IDs
- API responses with customer data
- Internal object structure
- Error stack traces

---

## BUG-020: Loading Screen Components Have No Timeout

| Field | Details |
|-------|---------|
| **Severity** | Low |
| **Module** | Global |
| **Component** | loadingScreen, onLoadingScreen (LWC) |
| **File Reference** | `lwc/loadingScreen/`, `lwc/onLoadingScreen/` |

**Steps to Reproduce:**
1. Navigate to any page that shows a loading spinner
2. Disconnect network (go offline in DevTools)
3. Wait and observe the loading screen

**Expected Result:** After a reasonable timeout (e.g., 30 seconds), the loading screen should disappear and show an error: "Unable to load. Please check your connection and try again."

**Actual Result:** The loading spinner may spin indefinitely with no timeout mechanism, leaving the user stuck.

---

## Test Execution Checklist

| # | Bug ID | Module | Severity | Test Status | Pass/Fail | Notes |
|---|--------|--------|----------|-------------|-----------|-------|
| 1 | BUG-001 | Booking - File Upload | Critical | | | Test 4th file upload specifically |
| 2 | BUG-002 | File Upload | High | | | Throttle network to simulate failure |
| 3 | BUG-003 | Booking - Email | High | | | Try invalid email formats |
| 4 | BUG-004 | Site Visit | High | | | Search with special characters |
| 5 | BUG-005 | Booking - Modal | Medium | | | Use screen reader + keyboard |
| 6 | BUG-006 | Booking - Co-Applicant | Medium | | | Leave fields blank, check error UX |
| 7 | BUG-007 | Multiple | Medium | | | Double-click submit buttons |
| 8 | BUG-008 | Lead | Medium | | | Test Cancel/Back in various contexts |
| 9 | BUG-009 | Multiple | Medium | | | Enter various phone formats |
| 10 | BUG-010 | Booking - Payment | Medium | | | Select Card, leave number empty |
| 11 | BUG-011 | Demand | Medium | | | Bulk select and raise without confirm |
| 12 | BUG-012 | File Upload | Medium | | | Upload .exe, .sh, 100MB files |
| 13 | BUG-013 | Inspection | Medium | | | Enter HTML/SQL in snag description |
| 14 | BUG-014 | Inventory | Low | | | Resize browser to 768px, 375px |
| 15 | BUG-015 | Quote | Medium | | | Two users select same unit |
| 16 | BUG-016 | Bulk Reassignment | Low | | | Force server error, check message |
| 17 | BUG-017 | Booking - Age | Low | | | Enter 0, -1, 17, 101, 18.5 |
| 18 | BUG-018 | Booking - PAN | Low | | | Enter lowercase PAN |
| 19 | BUG-019 | All | Low | | | Open browser console during testing |
| 20 | BUG-020 | Global | Low | | | Go offline while loading |

---

## Summary Statistics

| Severity | Count | Key Areas |
|----------|-------|-----------|
| **Critical** | 1 | File Upload Logic |
| **High** | 3 | File Upload UX, Email Validation, JSON Parse Crash |
| **Medium** | 9 | Accessibility, Double-Submit, Phone Validation, Payment Mode, Demand Confirmation, File Types, XSS, Responsive, Concurrency |
| **Low** | 7 | PAN Case, Age Edge Cases, Console Logs, Loading Timeout, Error Messages |
| **Total** | **20** | |

---

## Environment and Tools Needed for Testing

- **Browser:** Chrome (latest) with DevTools for network throttling
- **Screen Reader:** NVDA or VoiceOver for accessibility testing (BUG-005)
- **Multiple Users:** Two Salesforce user accounts for concurrency testing (BUG-015)
- **Test Files:** Prepare `.exe`, `.bat`, `.sh`, and 100MB+ files (BUG-012)
- **Network Control:** Chrome DevTools > Network > Throttle to simulate poor connectivity
- **Devices:** Desktop + Tablet for responsive testing (BUG-014)
