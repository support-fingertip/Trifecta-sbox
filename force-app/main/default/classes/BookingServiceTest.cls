/**
 * BookingServiceTest
 * Comprehensive test suite for BookingService covering:
 *  - Successful booking creation
 *  - Input validation (null, blank fields, invalid e-mail, bad dates)
 *  - Time-slot conflict detection
 *  - Retrieval by ID and by contact
 *  - Update and cancellation
 *  - Re-booking a cancelled slot
 *  - Edge cases (same start/end time, exact boundary slots)
 */
@IsTest
private class BookingServiceTest {

    // ─── Helpers ─────────────────────────────────────────────────────────────

    /** Returns a valid BookingRequest starting daysOffset days from now. */
    private static BookingService.BookingRequest buildRequest(
        String name,
        String email,
        Integer daysOffset,
        Integer durationHours,
        String serviceType
    ) {
        BookingService.BookingRequest req = new BookingService.BookingRequest();
        req.contactName  = name;
        req.contactEmail = email;
        req.startTime    = DateTime.now().addDays(daysOffset);
        req.endTime      = DateTime.now().addDays(daysOffset).addHours(durationHours);
        req.serviceType  = serviceType;
        return req;
    }

    // ─── Create Booking – Happy Path ─────────────────────────────────────────

    @IsTest
    static void testCreateBooking_Success() {
        BookingService svc = new BookingService();
        BookingService.BookingRequest req = buildRequest('John Doe', 'john@example.com', 1, 1, 'Consultation');

        Test.startTest();
        BookingService.BookingResult result = svc.createBooking(req);
        Test.stopTest();

        System.assertNotEquals(null, result, 'Result must not be null');
        System.assertEquals(true, result.success, 'Booking should succeed');
        System.assertNotEquals(null, result.bookingId, 'A booking ID must be generated');
        System.assertEquals('Booking created successfully', result.message);
        System.assertNotEquals(null, result.booking, 'Result should contain the booking');
    }

    @IsTest
    static void testCreateBooking_WithOptionalNotes() {
        BookingService svc = new BookingService();
        BookingService.BookingRequest req = buildRequest('Jane Smith', 'jane@example.com', 2, 2, 'Follow-up');
        req.notes = 'Please bring previous records';

        Test.startTest();
        BookingService.BookingResult result = svc.createBooking(req);
        Test.stopTest();

        System.assertEquals(true, result.success);
        System.assertEquals('Please bring previous records', result.booking.notes);
    }

    // ─── Create Booking – Validation Failures ────────────────────────────────

    @IsTest
    static void testCreateBooking_NullRequest_ThrowsException() {
        BookingService svc = new BookingService();

        Test.startTest();
        try {
            svc.createBooking(null);
            System.assert(false, 'Expected BookingException');
        } catch (BookingService.BookingException e) {
            System.assertEquals('Booking request cannot be null', e.getMessage());
        }
        Test.stopTest();
    }

    @IsTest
    static void testCreateBooking_BlankContactName_ThrowsException() {
        BookingService svc = new BookingService();
        BookingService.BookingRequest req = buildRequest('', 'john@example.com', 1, 1, 'Consultation');

        Test.startTest();
        try {
            svc.createBooking(req);
            System.assert(false, 'Expected BookingException');
        } catch (BookingService.BookingException e) {
            System.assertEquals('Contact name is required', e.getMessage());
        }
        Test.stopTest();
    }

    @IsTest
    static void testCreateBooking_BlankContactEmail_ThrowsException() {
        BookingService svc = new BookingService();
        BookingService.BookingRequest req = buildRequest('John Doe', '', 1, 1, 'Consultation');

        Test.startTest();
        try {
            svc.createBooking(req);
            System.assert(false, 'Expected BookingException');
        } catch (BookingService.BookingException e) {
            System.assertEquals('Contact email is required', e.getMessage());
        }
        Test.stopTest();
    }

    @IsTest
    static void testCreateBooking_InvalidEmailFormat_ThrowsException() {
        BookingService svc = new BookingService();
        BookingService.BookingRequest req = buildRequest('John Doe', 'not-an-email', 1, 1, 'Consultation');

        Test.startTest();
        try {
            svc.createBooking(req);
            System.assert(false, 'Expected BookingException');
        } catch (BookingService.BookingException e) {
            System.assertEquals('Invalid email format', e.getMessage());
        }
        Test.stopTest();
    }

    @IsTest
    static void testCreateBooking_NullStartTime_ThrowsException() {
        BookingService svc = new BookingService();
        BookingService.BookingRequest req = buildRequest('John Doe', 'john@example.com', 1, 1, 'Consultation');
        req.startTime = null;

        Test.startTest();
        try {
            svc.createBooking(req);
            System.assert(false, 'Expected BookingException');
        } catch (BookingService.BookingException e) {
            System.assertEquals('Start time is required', e.getMessage());
        }
        Test.stopTest();
    }

    @IsTest
    static void testCreateBooking_NullEndTime_ThrowsException() {
        BookingService svc = new BookingService();
        BookingService.BookingRequest req = buildRequest('John Doe', 'john@example.com', 1, 1, 'Consultation');
        req.endTime = null;

        Test.startTest();
        try {
            svc.createBooking(req);
            System.assert(false, 'Expected BookingException');
        } catch (BookingService.BookingException e) {
            System.assertEquals('End time is required', e.getMessage());
        }
        Test.stopTest();
    }

    @IsTest
    static void testCreateBooking_EndTimeBeforeStartTime_ThrowsException() {
        BookingService svc = new BookingService();
        BookingService.BookingRequest req = buildRequest('John Doe', 'john@example.com', 2, 1, 'Consultation');
        // Swap: end before start
        req.endTime   = DateTime.now().addDays(1);
        req.startTime = DateTime.now().addDays(2);

        Test.startTest();
        try {
            svc.createBooking(req);
            System.assert(false, 'Expected BookingException');
        } catch (BookingService.BookingException e) {
            System.assertEquals('End time must be after start time', e.getMessage());
        }
        Test.stopTest();
    }

    @IsTest
    static void testCreateBooking_SameStartAndEndTime_ThrowsException() {
        BookingService svc = new BookingService();
        DateTime moment = DateTime.now().addDays(1);
        BookingService.BookingRequest req = buildRequest('John Doe', 'john@example.com', 1, 1, 'Consultation');
        req.startTime = moment;
        req.endTime   = moment;

        Test.startTest();
        try {
            svc.createBooking(req);
            System.assert(false, 'Expected BookingException');
        } catch (BookingService.BookingException e) {
            System.assertEquals('End time must be after start time', e.getMessage());
        }
        Test.stopTest();
    }

    @IsTest
    static void testCreateBooking_PastStartTime_ThrowsException() {
        BookingService svc = new BookingService();
        BookingService.BookingRequest req = new BookingService.BookingRequest();
        req.contactName  = 'John Doe';
        req.contactEmail = 'john@example.com';
        req.startTime    = DateTime.now().addDays(-2);
        req.endTime      = DateTime.now().addDays(-1);
        req.serviceType  = 'Consultation';

        Test.startTest();
        try {
            svc.createBooking(req);
            System.assert(false, 'Expected BookingException');
        } catch (BookingService.BookingException e) {
            System.assertEquals('Booking cannot be in the past', e.getMessage());
        }
        Test.stopTest();
    }

    @IsTest
    static void testCreateBooking_BlankServiceType_ThrowsException() {
        BookingService svc = new BookingService();
        BookingService.BookingRequest req = buildRequest('John Doe', 'john@example.com', 1, 1, '');

        Test.startTest();
        try {
            svc.createBooking(req);
            System.assert(false, 'Expected BookingException');
        } catch (BookingService.BookingException e) {
            System.assertEquals('Service type is required', e.getMessage());
        }
        Test.stopTest();
    }

    // ─── Time-Slot Conflict ───────────────────────────────────────────────────

    @IsTest
    static void testCreateBooking_OverlappingSlot_ThrowsException() {
        BookingService svc = new BookingService();
        svc.createBooking(buildRequest('John Doe', 'john@example.com', 1, 2, 'Consultation'));

        // Overlaps with the first booking (starts 1 h in, ends 1 h after)
        BookingService.BookingRequest conflict = buildRequest('Jane Doe', 'jane@example.com', 1, 1, 'Consultation');
        conflict.startTime = DateTime.now().addDays(1).addHours(1);
        conflict.endTime   = DateTime.now().addDays(1).addHours(3);

        Test.startTest();
        try {
            svc.createBooking(conflict);
            System.assert(false, 'Expected BookingException');
        } catch (BookingService.BookingException e) {
            System.assertEquals('Time slot is not available', e.getMessage());
        }
        Test.stopTest();
    }

    @IsTest
    static void testCreateBooking_AdjacentSlot_Succeeds() {
        BookingService svc = new BookingService();
        // First booking: day 1, hour 0-1
        svc.createBooking(buildRequest('John Doe', 'john@example.com', 1, 1, 'Consultation'));

        // Second booking starts exactly when first ends – no overlap
        BookingService.BookingRequest adjacent = buildRequest('Jane Doe', 'jane@example.com', 1, 1, 'Follow-up');
        adjacent.startTime = DateTime.now().addDays(1).addHours(1);
        adjacent.endTime   = DateTime.now().addDays(1).addHours(2);

        Test.startTest();
        BookingService.BookingResult result = svc.createBooking(adjacent);
        Test.stopTest();

        System.assertEquals(true, result.success, 'Adjacent slots must not conflict');
    }

    // ─── Get Booking ─────────────────────────────────────────────────────────

    @IsTest
    static void testGetBooking_Success() {
        BookingService svc = new BookingService();
        BookingService.BookingResult created = svc.createBooking(
            buildRequest('John Doe', 'john@example.com', 1, 1, 'Consultation')
        );

        Test.startTest();
        BookingService.BookingRequest retrieved = svc.getBooking(created.bookingId);
        Test.stopTest();

        System.assertNotEquals(null, retrieved, 'Retrieved booking must not be null');
        System.assertEquals('John Doe', retrieved.contactName);
        System.assertEquals('john@example.com', retrieved.contactEmail);
    }

    @IsTest
    static void testGetBooking_InvalidId_ThrowsException() {
        BookingService svc = new BookingService();

        Test.startTest();
        try {
            svc.getBooking('INVALID-ID');
            System.assert(false, 'Expected BookingException');
        } catch (BookingService.BookingException e) {
            System.assert(e.getMessage().contains('Booking not found'), 'Message should indicate booking not found');
        }
        Test.stopTest();
    }

    // ─── Get Bookings By Contact ──────────────────────────────────────────────

    @IsTest
    static void testGetBookingsByContact_MultipleBookings() {
        BookingService svc = new BookingService();
        svc.createBooking(buildRequest('John Doe', 'john@example.com', 1, 1, 'Consultation'));
        svc.createBooking(buildRequest('John Doe', 'john@example.com', 3, 1, 'Follow-up'));
        svc.createBooking(buildRequest('Jane Smith', 'jane@example.com', 2, 1, 'Consultation'));

        Test.startTest();
        List<BookingService.BookingRequest> johnBookings = svc.getBookingsByContact('john@example.com');
        Test.stopTest();

        System.assertEquals(2, johnBookings.size(), 'Should return exactly 2 bookings for John');
    }

    @IsTest
    static void testGetBookingsByContact_NoBookings_ReturnsEmptyList() {
        BookingService svc = new BookingService();

        Test.startTest();
        List<BookingService.BookingRequest> results = svc.getBookingsByContact('nobody@example.com');
        Test.stopTest();

        System.assertNotEquals(null, results, 'Result list must not be null');
        System.assertEquals(0, results.size(), 'Should return an empty list');
    }

    @IsTest
    static void testUpdateBooking_ConflictingSlot_ThrowsException() {
        BookingService svc = new BookingService();
        // Create two non-overlapping bookings
        BookingService.BookingResult b1 = svc.createBooking(
            buildRequest('John Doe', 'john@example.com', 1, 1, 'Consultation')
        );
        svc.createBooking(buildRequest('Jane Smith', 'jane@example.com', 3, 1, 'Consultation'));

        // Try to update b1 to overlap with b2
        BookingService.BookingRequest conflicting = buildRequest('John Doe', 'john@example.com', 3, 1, 'Consultation');
        conflicting.startTime = DateTime.now().addDays(3);
        conflicting.endTime   = DateTime.now().addDays(3).addHours(1);

        Test.startTest();
        try {
            svc.updateBooking(b1.bookingId, conflicting);
            System.assert(false, 'Expected BookingException');
        } catch (BookingService.BookingException e) {
            System.assertEquals('Time slot is not available', e.getMessage());
        }
        Test.stopTest();

        // The original booking should still be retrievable (unchanged)
        BookingService.BookingRequest unchanged = svc.getBooking(b1.bookingId);
        System.assertEquals('Consultation', unchanged.serviceType);
    }

    @IsTest
    static void testGetBookingsByContact_CaseInsensitiveEmail() {
        BookingService svc = new BookingService();
        svc.createBooking(buildRequest('John Doe', 'John@Example.com', 1, 1, 'Consultation'));

        Test.startTest();
        List<BookingService.BookingRequest> results = svc.getBookingsByContact('john@example.com');
        Test.stopTest();

        System.assertEquals(1, results.size(), 'Email lookup should be case-insensitive');
    }

    @IsTest
    static void testUpdateBooking_Success() {
        BookingService svc = new BookingService();
        BookingService.BookingResult created = svc.createBooking(
            buildRequest('John Doe', 'john@example.com', 1, 1, 'Consultation')
        );

        BookingService.BookingRequest updated = buildRequest('John Doe', 'john@example.com', 5, 2, 'Follow-up');
        updated.notes = 'Rescheduled appointment';

        Test.startTest();
        BookingService.BookingResult result = svc.updateBooking(created.bookingId, updated);
        Test.stopTest();

        System.assertEquals(true, result.success, 'Update should succeed');
        System.assertEquals('Booking updated successfully', result.message);
        System.assertEquals('Follow-up', result.booking.serviceType);
        System.assertEquals('Rescheduled appointment', result.booking.notes);
    }

    @IsTest
    static void testUpdateBooking_InvalidId_ThrowsException() {
        BookingService svc = new BookingService();
        BookingService.BookingRequest updated = buildRequest('John Doe', 'john@example.com', 1, 1, 'Consultation');

        Test.startTest();
        try {
            svc.updateBooking('INVALID-ID', updated);
            System.assert(false, 'Expected BookingException');
        } catch (BookingService.BookingException e) {
            System.assert(e.getMessage().contains('Booking not found'));
        }
        Test.stopTest();
    }

    @IsTest
    static void testUpdateBooking_WithInvalidData_ThrowsException() {
        BookingService svc = new BookingService();
        BookingService.BookingResult created = svc.createBooking(
            buildRequest('John Doe', 'john@example.com', 1, 1, 'Consultation')
        );

        BookingService.BookingRequest badUpdate = buildRequest('', 'john@example.com', 5, 2, 'Follow-up');

        Test.startTest();
        try {
            svc.updateBooking(created.bookingId, badUpdate);
            System.assert(false, 'Expected BookingException');
        } catch (BookingService.BookingException e) {
            System.assertEquals('Contact name is required', e.getMessage());
        }
        Test.stopTest();
    }

    // ─── Cancel Booking ───────────────────────────────────────────────────────

    @IsTest
    static void testCancelBooking_Success() {
        BookingService svc = new BookingService();
        BookingService.BookingResult created = svc.createBooking(
            buildRequest('John Doe', 'john@example.com', 1, 1, 'Consultation')
        );

        Test.startTest();
        BookingService.BookingResult cancelResult = svc.cancelBooking(created.bookingId);
        Test.stopTest();

        System.assertEquals(true, cancelResult.success, 'Cancellation should succeed');
        System.assertEquals('Booking cancelled successfully', cancelResult.message);
        System.assertEquals(created.bookingId, cancelResult.bookingId);
    }

    @IsTest
    static void testCancelBooking_InvalidId_ThrowsException() {
        BookingService svc = new BookingService();

        Test.startTest();
        try {
            svc.cancelBooking('INVALID-ID');
            System.assert(false, 'Expected BookingException');
        } catch (BookingService.BookingException e) {
            System.assert(e.getMessage().contains('Booking not found'));
        }
        Test.stopTest();
    }

    @IsTest
    static void testCancelBooking_ThenGetBooking_ThrowsException() {
        BookingService svc = new BookingService();
        BookingService.BookingResult created = svc.createBooking(
            buildRequest('John Doe', 'john@example.com', 1, 1, 'Consultation')
        );
        svc.cancelBooking(created.bookingId);

        Test.startTest();
        try {
            svc.getBooking(created.bookingId);
            System.assert(false, 'Expected BookingException after cancellation');
        } catch (BookingService.BookingException e) {
            System.assert(e.getMessage().contains('Booking not found'));
        }
        Test.stopTest();
    }

    // ─── Re-book Cancelled Slot ───────────────────────────────────────────────

    @IsTest
    static void testCancelAndRebookSameSlot_Success() {
        BookingService svc = new BookingService();
        BookingService.BookingRequest req1 = buildRequest('John Doe', 'john@example.com', 1, 1, 'Consultation');
        BookingService.BookingResult created = svc.createBooking(req1);
        svc.cancelBooking(created.bookingId);

        // Same time window should now be available again
        BookingService.BookingRequest req2 = buildRequest('Jane Smith', 'jane@example.com', 1, 1, 'Consultation');
        req2.startTime = req1.startTime;
        req2.endTime   = req1.endTime;

        Test.startTest();
        BookingService.BookingResult rebooked = svc.createBooking(req2);
        Test.stopTest();

        System.assertEquals(true, rebooked.success, 'Should be able to rebook a cancelled slot');
        System.assertEquals('Jane Smith', rebooked.booking.contactName);
    }

    // ─── Time-Slot Availability ───────────────────────────────────────────────

    @IsTest
    static void testIsTimeSlotAvailable_EmptyStore_ReturnsTrue() {
        BookingService svc = new BookingService();

        Test.startTest();
        Boolean available = svc.isTimeSlotAvailable(
            DateTime.now().addDays(5),
            DateTime.now().addDays(5).addHours(1)
        );
        Test.stopTest();

        System.assertEquals(true, available, 'Slot must be available when store is empty');
    }

    @IsTest
    static void testIsTimeSlotAvailable_WithConflict_ReturnsFalse() {
        BookingService svc = new BookingService();
        svc.createBooking(buildRequest('John Doe', 'john@example.com', 1, 2, 'Consultation'));

        Test.startTest();
        Boolean available = svc.isTimeSlotAvailable(
            DateTime.now().addDays(1).addHours(1),
            DateTime.now().addDays(1).addHours(3)
        );
        Test.stopTest();

        System.assertEquals(false, available, 'Overlapping slot must not be available');
    }

    @IsTest
    static void testIsTimeSlotAvailable_DifferentDay_ReturnsTrue() {
        BookingService svc = new BookingService();
        svc.createBooking(buildRequest('John Doe', 'john@example.com', 1, 2, 'Consultation'));

        Test.startTest();
        Boolean available = svc.isTimeSlotAvailable(
            DateTime.now().addDays(2),
            DateTime.now().addDays(2).addHours(2)
        );
        Test.stopTest();

        System.assertEquals(true, available, 'Non-overlapping slot on a different day should be available');
    }
}
