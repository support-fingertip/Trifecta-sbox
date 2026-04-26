/**
 * BookingService
 * Provides business logic for managing bookings including creation,
 * retrieval, update, cancellation, and time-slot availability checks.
 */
public with sharing class BookingService {

    // ─── Custom Exception ────────────────────────────────────────────────────

    public class BookingException extends Exception {}

    // ─── Inner Classes ───────────────────────────────────────────────────────

    public class BookingRequest {
        public String   contactName;
        public String   contactEmail;
        public DateTime startTime;
        public DateTime endTime;
        public String   serviceType;
        public String   notes;
    }

    public class BookingResult {
        public Boolean        success;
        public String         message;
        public String         bookingId;
        public BookingRequest booking;
    }

    // ─── Constants ───────────────────────────────────────────────────────────

    private static final String EMAIL_REGEX = '^[a-zA-Z0-9._%+-]+@[a-zA-Z0-9.-]+\\.[a-zA-Z]{2,}$';

    // ─── Instance State ──────────────────────────────────────────────────────

    @TestVisible
    private Map<String, BookingRequest> bookingStore;

    public BookingService() {
        this.bookingStore = new Map<String, BookingRequest>();
    }

    // ─── Public Methods ──────────────────────────────────────────────────────

    /**
     * Creates a new booking after validating the request and checking
     * that the requested time slot is available.
     */
    public BookingResult createBooking(BookingRequest request) {
        validateBookingRequest(request);

        if (!isTimeSlotAvailable(request.startTime, request.endTime)) {
            throw new BookingException('Time slot is not available');
        }

        String bookingId = generateBookingId();
        bookingStore.put(bookingId, request);

        BookingResult result = new BookingResult();
        result.success   = true;
        result.message   = 'Booking created successfully';
        result.bookingId = bookingId;
        result.booking   = request;
        return result;
    }

    /**
     * Retrieves a booking by its ID.
     */
    public BookingRequest getBooking(String bookingId) {
        if (!bookingStore.containsKey(bookingId)) {
            throw new BookingException('Booking not found: ' + bookingId);
        }
        return bookingStore.get(bookingId);
    }

    /**
     * Returns all bookings belonging to the specified contact e-mail.
     */
    public List<BookingRequest> getBookingsByContact(String contactEmail) {
        List<BookingRequest> results = new List<BookingRequest>();
        for (BookingRequest booking : bookingStore.values()) {
            if (booking.contactEmail.equalsIgnoreCase(contactEmail)) {
                results.add(booking);
            }
        }
        return results;
    }

    /**
     * Updates an existing booking and verifies that the new time slot
     * does not conflict with any other booking.
     */
    public BookingResult updateBooking(String bookingId, BookingRequest updatedRequest) {
        if (!bookingStore.containsKey(bookingId)) {
            throw new BookingException('Booking not found: ' + bookingId);
        }
        validateBookingRequest(updatedRequest);

        // Temporarily remove the existing booking so we can check availability
        // against all *other* bookings only.
        BookingRequest original = bookingStore.remove(bookingId);
        try {
            if (!isTimeSlotAvailable(updatedRequest.startTime, updatedRequest.endTime)) {
                throw new BookingException('Time slot is not available');
            }
        } catch (BookingException e) {
            // Restore the original booking before re-throwing
            bookingStore.put(bookingId, original);
            throw e;
        }

        bookingStore.put(bookingId, updatedRequest);

        BookingResult result = new BookingResult();
        result.success   = true;
        result.message   = 'Booking updated successfully';
        result.bookingId = bookingId;
        result.booking   = updatedRequest;
        return result;
    }

    /**
     * Cancels an existing booking.
     */
    public BookingResult cancelBooking(String bookingId) {
        if (!bookingStore.containsKey(bookingId)) {
            throw new BookingException('Booking not found: ' + bookingId);
        }
        bookingStore.remove(bookingId);

        BookingResult result = new BookingResult();
        result.success   = true;
        result.message   = 'Booking cancelled successfully';
        result.bookingId = bookingId;
        return result;
    }

    /**
     * Returns true when no existing booking overlaps the given time window.
     */
    public Boolean isTimeSlotAvailable(DateTime startTime, DateTime endTime) {
        for (BookingRequest existing : bookingStore.values()) {
            if (startTime < existing.endTime && endTime > existing.startTime) {
                return false;
            }
        }
        return true;
    }

    // ─── Private Helpers ─────────────────────────────────────────────────────

    private void validateBookingRequest(BookingRequest request) {
        if (request == null) {
            throw new BookingException('Booking request cannot be null');
        }
        if (String.isBlank(request.contactName)) {
            throw new BookingException('Contact name is required');
        }
        if (String.isBlank(request.contactEmail)) {
            throw new BookingException('Contact email is required');
        }
        if (!isValidEmail(request.contactEmail)) {
            throw new BookingException('Invalid email format');
        }
        if (request.startTime == null) {
            throw new BookingException('Start time is required');
        }
        if (request.endTime == null) {
            throw new BookingException('End time is required');
        }
        if (request.startTime >= request.endTime) {
            throw new BookingException('End time must be after start time');
        }
        if (request.startTime < DateTime.now()) {
            throw new BookingException('Booking cannot be in the past');
        }
        if (String.isBlank(request.serviceType)) {
            throw new BookingException('Service type is required');
        }
    }

    private static Boolean isValidEmail(String email) {
        Pattern p = Pattern.compile(EMAIL_REGEX);
        Matcher m = p.matcher(email);
        return m.matches();
    }

    private static String generateBookingId() {
        return 'BK-' + String.valueOf(DateTime.now().getTime());
    }
}
