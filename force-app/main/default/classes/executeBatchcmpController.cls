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
    
    @AuraEnabled
    public static String agreementbatch() {
        try {
            AgreementReminderScheduler scheduler = new AgreementReminderScheduler();
            scheduler.execute(null);
            
            return 'Batch Called Successfully';
        } catch (Exception e) {
            throw new AuraHandledException(e.getMessage());
        }
    }

}