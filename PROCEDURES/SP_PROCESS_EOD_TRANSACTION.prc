CREATE OR REPLACE PROCEDURE VMSCMS.sp_process_eod_transaction (
   prm_ins_date         DATE,
   prm_err_msg    OUT   VARCHAR2
)
AS
   v_previous_subgl_creditbalance   cms_float_subglwise_detail.cfsr_credit_amount%TYPE;
   v_previous_subgl_debitbalance    cms_float_subglwise_detail.cfsr_debit_amount%TYPE;
   v_balance_amt                    cms_transaction_summary.cts_subgl_balance%TYPE;
   v_gl_catg                        cms_gl_mast.cgm_catg_code%TYPE;
   v_cnt                            NUMBER (3);

   CURSOR c
   IS
      SELECT DISTINCT cfsr_gl_code, cfsr_subgl_code, cfsr_curr_code
                 FROM cms_float_subglwise_detail;

   CURSOR c1 (
      p_ins_date      DATE,
      p_gl_code       VARCHAR2,
      p_sub_gl_code   VARCHAR2,
      p_curr_code     VARCHAR2
   )
   IS
      SELECT cfsr_tran_date, cfsr_curr_code, cfsr_param_key, cfsr_gl_code,
             cfsr_subgl_code, NVL (cfsr_credit_amount, 0) credit_amt,
             NVL (cfsr_debit_amount, 0) debit_amt
        FROM cms_float_subglwise_detail
       WHERE TRUNC (cfsr_tran_date) = TRUNC (prm_ins_date)
         AND cfsr_gl_code = p_gl_code
         AND cfsr_subgl_code = p_sub_gl_code
         AND p_curr_code = p_curr_code;
BEGIN                                                       --<< MAIN BEGIN >>
   prm_err_msg := 'OK';
   ---Sn call to processes eod update acct
   sp_process_eodupdate_acct (1, prm_err_msg);

   IF prm_err_msg <> 'OK'
   THEN
      RETURN;
   END IF;

       ---En call to processes eod update acct
	   
	prm_err_msg := 'OK';
   ---Sn call to transferreord from transactionlog to pan trans
   
   sp_translog_to_pantrans (1,1, prm_err_msg);

   IF prm_err_msg <> 'OK'
   THEN
      RETURN;
   END IF;   
	   
	   
   --Sn Processes loop
   FOR i IN c
   LOOP
      BEGIN
         --Sn initialize the variables.
         v_balance_amt := 0;

         --En initialize the variables.
         -- Sn get the previous day balance
         BEGIN
            SELECT NVL (cts_subgl_balance, 0)
              INTO v_balance_amt
              FROM cms_transaction_summary
             WHERE cts_tran_head = TRIM (i.cfsr_curr_code)
               AND cts_gl_code = TRIM (i.cfsr_gl_code)
               AND cts_subgl_code = TRIM (i.cfsr_subgl_code)
               AND TRUNC (cts_tran_date) = TRUNC (prm_ins_date - 1);
         EXCEPTION
            WHEN NO_DATA_FOUND
            THEN
               v_balance_amt := 0;
         END;

         -- En get the previous day balance
         -- Sn get the transaction summary
         FOR i1 IN c1 (prm_ins_date,
                       i.cfsr_gl_code,
                       i.cfsr_subgl_code,
                       i.cfsr_curr_code
                      )
         LOOP
            BEGIN
               IF i1.credit_amt <> 0 AND i1.debit_amt <> 0
               THEN
                  prm_err_msg :=
                     'Both debit and credit amount cannot be there for a type of txn';
                  RETURN;
               END IF;

               IF i1.credit_amt <> 0
               THEN
                  v_balance_amt := v_balance_amt + i1.credit_amt;
               ELSE
                  IF i1.debit_amt <> 0
                  THEN
                     v_balance_amt := v_balance_amt - i1.debit_amt;
                  END IF;
               END IF;
            EXCEPTION
               WHEN OTHERS
               THEN
                  prm_err_msg :=
                     'Error while updating acct ' || SUBSTR (SQLERRM, 1, 300);
                  RETURN;
            END;
         END LOOP;

         -- En get the transaction summary
         -- Sn select GL catg
         BEGIN
            SELECT cgm_catg_code
              INTO v_gl_catg
              FROM cms_gl_mast
             WHERE cgm_gl_code = i.cfsr_gl_code;
         EXCEPTION
            WHEN NO_DATA_FOUND
            THEN
               v_gl_catg := NULL;
         END;

         -- En select GL catg
         --Sn select acct detail
         BEGIN
            SELECT 1
              INTO v_cnt
              FROM cms_transaction_summary
             WHERE cts_tran_head = i.cfsr_curr_code
               AND cts_gl_code = i.cfsr_gl_code
               AND cts_subgl_code = i.cfsr_subgl_code
               AND TRUNC (cts_tran_date) = TRUNC (prm_ins_date);

            UPDATE cms_transaction_summary
               SET cts_subgl_balance = v_balance_amt
             WHERE cts_tran_head = i.cfsr_curr_code
               AND cts_gl_code = i.cfsr_gl_code
               AND cts_subgl_code = i.cfsr_subgl_code
               AND TRUNC (cts_tran_date) = TRUNC (prm_ins_date);
         EXCEPTION
            WHEN NO_DATA_FOUND
            THEN
               INSERT INTO cms_transaction_summary
                           (cts_tran_date, cts_tran_head, cts_gl_catgcode,
                            cts_gl_code, cts_subgl_code, cts_subgl_balance
                           )
                    VALUES (prm_ins_date, i.cfsr_curr_code, v_gl_catg,
                            i.cfsr_gl_code, i.cfsr_subgl_code, v_balance_amt
                           );
         END;
      --Sn select acct detail
      EXCEPTION                                       --<< loop I exception >>
         WHEN OTHERS
         THEN
            prm_err_msg :=
                  'Error while creating transaction detail '
               || SUBSTR (SQLERRM, 1, 300);
            RETURN;
      END;                                                  --<< loop  Iend >>
   END LOOP;                                          --<< loop  I end loop >>
   
   
   
--En Processes loop
EXCEPTION                                                --<< MAIN EXCEPTION>>
   WHEN OTHERS
   THEN
      prm_err_msg := 'Error from main block ' || SUBSTR (SQLERRM, 1, 300);
END;                                                           --<< MAIN END>>
/
SHOW ERRORS

