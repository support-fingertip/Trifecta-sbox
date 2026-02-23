public class executeBatchcmpController {
    /**
     * Executes Pending Payment Reminder Batch
     */
    @AuraEnabled
    public static String runPaymentReminderBatch() {
        try {
            Database.executeBatch(
                new PendingPaymentReminderScheduler(), 20
            );
            return 'Batch Called Successfully';
        } catch (Exception e) {
            throw new AuraHandledException(e.getMessage());
        }
    }

}