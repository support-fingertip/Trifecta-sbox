public with sharing class PaymentSchedulePercentEditController {

    /**
     * Returns every Payment_schedule__c under the same Booking as the record
     * the calling component was launched from. The record can be either a
     * Payment_schedule__c (Quick Action on a PS page) or a Booking__c (button
     * embedded on the Booking record page).
     */
    @AuraEnabled(cacheable=false)
    public static Map<String, Object> getSchedules(Id recordId) {
        try {
            if (recordId == null) {
                throw new AuraHandledException('Record Id is required.');
            }

            String objectName = recordId.getSObjectType().getDescribe().getName();
            Id bookingId;

            if (objectName == 'Booking__c') {
                bookingId = recordId;
            } else if (objectName == 'Payment_schedule__c') {
                Payment_schedule__c source = [
                    SELECT Id, Booking__c
                    FROM Payment_schedule__c
                    WHERE Id = :recordId
                    LIMIT 1
                ];
                bookingId = source.Booking__c;
            } else {
                throw new AuraHandledException(
                    'Unsupported record type: ' + objectName);
            }

            if (bookingId == null) {
                throw new AuraHandledException(
                    'Could not resolve Booking for this record.');
            }

            Booking__c booking = [
                SELECT Id, Name, Total_Amount__c, Project_Type__c
                FROM Booking__c
                WHERE Id = :bookingId
                LIMIT 1
            ];

            List<Payment_schedule__c> schedules = [
                SELECT Id, Name, S_No__c, Payment_percent__c, Amount__c,
                       Is_Demanded__c, Received_Amount1__c
                FROM Payment_schedule__c
                WHERE Booking__c = :booking.Id
                ORDER BY S_No__c NULLS LAST
            ];

            Decimal expectedTotal =
                (booking.Project_Type__c == 'Villas') ? 200 : 100;

            Map<String, Object> result = new Map<String, Object>();
            result.put('schedules', schedules);
            result.put('booking', booking);
            result.put('expectedTotal', expectedTotal);
            return result;
        } catch (AuraHandledException ahe) {
            throw ahe;
        } catch (Exception e) {
            throw new AuraHandledException(
                'Unable to load payment schedules: ' + e.getMessage());
        }
    }

    /**
     * Persists edits. Accepts a List<Payment_schedule__c> from the client
     * where each row carries Id + new Payment_percent__c. All validation
     * runs server-side; any failure aborts the save with AuraHandledException.
     *
     * Rules enforced here:
     *   - Every edited schedule must belong to the given booking.
     *   - Demanded schedules cannot be edited.
     *   - Payment_percent__c cannot be negative.
     *   - New Amount__c (= Total_Amount__c * % / 100) cannot drop below
     *     Received_Amount1__c (already allocated receipts).
     *   - Total percent across the whole booking must equal 100 for
     *     Apartments/Row House/Plots and 200 for Villas.
     */
    @AuraEnabled
    public static void saveSchedules(Id bookingId,
                                     List<Payment_schedule__c> edits) {
        try {
            if (bookingId == null || edits == null || edits.isEmpty()) {
                throw new AuraHandledException('Nothing to save.');
            }

            Booking__c booking = [
                SELECT Id, Total_Amount__c, Project_Type__c
                FROM Booking__c
                WHERE Id = :bookingId
                LIMIT 1
            ];

            Decimal expectedTotal =
                (booking.Project_Type__c == 'Villas') ? 200 : 100;

            Map<Id, Payment_schedule__c> existing = new Map<Id, Payment_schedule__c>([
                SELECT Id, Payment_percent__c, Is_Demanded__c,
                       Received_Amount1__c, S_No__c
                FROM Payment_schedule__c
                WHERE Booking__c = :bookingId
            ]);

            Map<Id, Payment_schedule__c> edited = new Map<Id, Payment_schedule__c>();
            Decimal bookingTotal = (booking.Total_Amount__c == null)
                ? 0 : booking.Total_Amount__c;

            for (Payment_schedule__c e : edits) {
                Payment_schedule__c ref = existing.get(e.Id);
                if (ref == null) {
                    throw new AuraHandledException(
                        'Schedule does not belong to this booking.');
                }
                if (ref.Is_Demanded__c) {
                    throw new AuraHandledException(
                        'Cannot edit demanded schedule (S.No '
                        + ref.S_No__c + ').');
                }

                Decimal newPct = (e.Payment_percent__c == null)
                    ? 0 : e.Payment_percent__c;
                if (newPct < 0) {
                    throw new AuraHandledException(
                        'Percentage cannot be negative (S.No '
                        + ref.S_No__c + ').');
                }

                Decimal newAmount = (bookingTotal * newPct / 100).setScale(2);
                Decimal received = (ref.Received_Amount1__c == null)
                    ? 0 : ref.Received_Amount1__c;
                if (newAmount < received) {
                    throw new AuraHandledException(
                        'S.No ' + ref.S_No__c
                        + ': new amount (' + newAmount
                        + ') is below received amount (' + received + ').');
                }

                edited.put(ref.Id, new Payment_schedule__c(
                    Id = ref.Id,
                    Payment_percent__c = newPct,
                    Amount__c = newAmount
                ));
            }

            // Booking-wide percent total: use edited values where present,
            // current values elsewhere.
            Decimal totalPct = 0;
            for (Payment_schedule__c ref : existing.values()) {
                Decimal pct = edited.containsKey(ref.Id)
                    ? edited.get(ref.Id).Payment_percent__c
                    : ((ref.Payment_percent__c == null) ? 0 : ref.Payment_percent__c);
                totalPct += pct;
            }

            if (totalPct != expectedTotal) {
                throw new AuraHandledException(
                    'Total Payment % must equal ' + expectedTotal
                    + ' for ' + booking.Project_Type__c
                    + ' (currently ' + totalPct + ').');
            }

            update edited.values();
        } catch (AuraHandledException ahe) {
            throw ahe;
        } catch (Exception e) {
            throw new AuraHandledException('Save failed: ' + e.getMessage());
        }
    }
}
