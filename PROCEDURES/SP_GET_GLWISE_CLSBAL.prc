CREATE OR REPLACE PROCEDURE VMSCMS.Sp_Get_Glwise_Clsbal
                                (prm_inst_code          		VARCHAR2,
                                 prm_calc_date          		VARCHAR2,
                                 prm_opening_bal        	VARCHAR2,
                                 prm_currency_code      VARCHAR2,
                                 prm_gl_code            VARCHAR2,
								 prm_flag						  NUMBER,
                                 prm_curr_bal OUT       VARCHAR2,
                                 prm_err_msg  OUT       VARCHAR2
                                )
IS
        v_credit_amt            NUMBER;
        v_debit_amt             NUMBER;
		v_curr_bal				  NUMBER DEFAULT 0;
BEGIN                   --<MAIN BEGIN>>
                prm_err_msg := 'OK';
             BEGIN
               SELECT
                                NVL(SUM(cfsr_credit_amount), 0) CREDIT_AMT,
                                NVL(SUM(cfsr_debit_amount) ,0)   DEBIT_AMT
                INTO            v_credit_amt,
                               		   v_debit_amt
                FROM           CMS_FLOAT_SUBGLWISE_DETAIL  		 		   		 --CMS_FLOAT_SUBGLWISE_REPORT		--Commented By Vikrant 31-Dec-08
  				WHERE           TRUNC(cfsr_tran_date) = TRUNC(TO_DATE(prm_calc_date,'dd/mm/yyyy') )
         		AND             CFSR_CURR_CODE           = prm_currency_code
                AND             CFSR_GL_CODE             = prm_gl_code  ;
              v_curr_bal  := (TO_NUMBER(prm_opening_bal, '99,99,99,99,990.99') + v_credit_amt) - v_debit_amt;
			   prm_curr_bal  := TO_CHAR (v_curr_bal,'99,99,99,99,990.99');
   			   DBMS_OUTPUT.PUT_LINE ('OPEN BAL:'||prm_opening_bal);
   			   DBMS_OUTPUT.PUT_LINE ('CREDIT_BAL:'||v_credit_amt);
   			   DBMS_OUTPUT.PUT_LINE ('DEBIT_BAL:'||v_debit_amt);
			   DBMS_OUTPUT.PUT_LINE ('CURR_BAL:'||prm_curr_bal);
  
             EXCEPTION
                        WHEN NO_DATA_FOUND THEN
                         v_curr_bal  := (TO_NUMBER(prm_opening_bal) + v_credit_amt) - v_debit_amt;
			   			 prm_curr_bal  := TO_CHAR(    v_curr_bal,'99,99,99,99,990.99');
             END;
EXCEPTION               --<< MAIN EXCEPTION >>
             WHEN OTHERS THEN
                prm_err_msg  := 'Error while generating currency wise gl ' || SUBSTR(SQLERRM,1,200);
END;                    --<< MAIN END >>
/

SHOW ERRORS
