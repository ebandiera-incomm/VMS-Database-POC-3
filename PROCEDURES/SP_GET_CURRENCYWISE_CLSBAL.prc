CREATE OR REPLACE PROCEDURE vmscms.sp_get_currencywise_clsbal (
   prm_inst_code             VARCHAR2,
   prm_calc_date             VARCHAR2,
   prm_opening_bal           VARCHAR2,
   prm_currency_code         VARCHAR2,
   prm_flag                  NUMBER,
   prm_curr_bal        OUT   VARCHAR2,
   prm_err_msg         OUT   VARCHAR2
)
IS
   v_credit_amt   NUMBER;
   v_debit_amt    NUMBER;
   v_curr_bal     NUMBER DEFAULT 0;
BEGIN
   prm_err_msg := 'OK';

   BEGIN
      SELECT NVL (SUM (cfsr_credit_amount), 0) credit_amt,
             NVL (SUM (cfsr_debit_amount), 0) debit_amt
        INTO v_credit_amt,
             v_debit_amt
        FROM cms_float_subglwise_detail, gen_curr_mast
       WHERE TRUNC (cfsr_tran_date) =
                                 TRUNC (TO_DATE (prm_calc_date, 'mm/dd/yyyy'))
         AND TRIM (cfsr_curr_code) = TRIM (gcm_curr_code)
         AND TRIM (gcm_curr_code) = TRIM (prm_currency_code);

      v_curr_bal :=
           (TO_NUMBER (prm_opening_bal, '99,99,99,99,990.99') + v_credit_amt
           )
         - v_debit_amt;
      prm_curr_bal := TO_CHAR (v_curr_bal, '99,99,99,99,990.99');
   EXCEPTION
      WHEN NO_DATA_FOUND
      THEN
         prm_curr_bal := (prm_opening_bal + v_credit_amt) - v_debit_amt;
   END;
EXCEPTION
   WHEN OTHERS
   THEN
      prm_err_msg :=
            'Error while generating currency wise gl '
         || SUBSTR (SQLERRM, 1, 200);
END;
/

SHOW ERROR