CREATE OR REPLACE PROCEDURE VMSCMS.migr_bulk_shrink_segment (
   prm_errmsg   OUT   VARCHAR2
)
AS
   CURSOR c1
   IS
      SELECT table_name
        FROM user_tables
       WHERE table_name IN
                ('CMS_STATEMENTS_LOG', 'CMS_TRANSACTION_LOG_DTL',
                 'TRANSACTIONLOG', 'CMS_MANUAL_ADJUSTMENT',
                 'CMS_DISPUTE_TXNS', 'CMS_HTLST_REISU', 'CMS_PAN_SPPRT',
                 'CMS_SMSANDEMAIL_ALERT', 'CMS_CARDISSUANCE_STATUS',
                 'CMS_PAN_ACCT', 'CMS_APPL_PAN', 'CMS_APPL_DET',
                 'CMS_APPL_MAST', 'CMS_CUST_ACCT', 'CMS_ACCT_MAST',
                 'CMS_ADDR_MAST', 'CMS_SECURITY_QUESTIONS', 'CMS_CUST_MAST',
                 'CMS_PROD_CCC');

   v_errmsg            VARCHAR2 (300);
   exp_reject_record   EXCEPTION;
BEGIN
   prm_errmsg := 'OK';

   FOR x IN c1
   LOOP
      v_errmsg := 'OK';

      BEGIN
         migr_shrink_segments (x.table_name, v_errmsg);

         IF v_errmsg <> 'OK'
         THEN
            v_errmsg := 'From shrink segment ' || v_errmsg;
            RAISE exp_reject_record;
         END IF;
      EXCEPTION
         WHEN exp_reject_record
         THEN
            RAISE;
      END;
   END LOOP;
EXCEPTION
   WHEN exp_reject_record
   THEN
      prm_errmsg := v_errmsg;
   WHEN OTHERS
   THEN
      prm_errmsg :=
               'Main exception from bulk shrink ' || SUBSTR (SQLERRM, 1, 200);
END;
/

SHOW ERRORS;