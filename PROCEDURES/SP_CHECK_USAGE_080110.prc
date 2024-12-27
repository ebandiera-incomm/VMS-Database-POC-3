CREATE OR REPLACE PROCEDURE VMSCMS.Sp_Check_Usage_080110
     (
     prm_inst_code   IN NUMBER,
     prm_usage_type   IN VARCHAR2,  -- 'D'  --DAILY, 'W' WEEKLY  , 'M' monthly..
     prm_card_no   IN VARCHAR2,
     prm_tran_date   IN DATE,
     prm_tot_trans   IN NUMBER  ,  -- 'Total allowed transaction count '
     prm_tot_transamt  IN NUMBER  ,
     prm_current_trans_amt  IN NUMBER ,
     prm_auth_type   IN VARCHAR2,
     prm_err_flag   OUT NUMBER,
     prm_err_msg   OUT VARCHAR2
     )

IS
 v_tot_transaction NUMBER;
 v_tot_amount  NUMBER;
 v_begining_of_week DATE; -- Monday is begining of the week.
 v_begining_of_month DATE;
 v_usage_type RULE.usagetype%TYPE;
 BEGIN   --<< MAIN BEGIN >>
 
 v_usage_type := prm_usage_type;


  -- DAILY CHECK BEGIN
   BEGIN
    IF v_usage_type = 'D' THEN
    BEGIN
     SELECT COUNT(1) , SUM(ctd_actual_amount)
     INTO   v_tot_transaction,v_tot_amount
     FROM   CMS_TRANSACTION_LOG_DTL
     WHERE  CTD_PROCESS_FLAG = 'Y'
	 AND    CTD_TXN_CODE IN ('10','30','90')
     AND    CTD_CUSTOMER_CARD_NO = prm_card_no
     AND    TO_DATE (   SUBSTR (TRIM (CTD_BUSINESS_DATE), 1, 8),'yyyymmdd') = TRUNC(prm_tran_date);

      IF  (v_tot_transaction >= prm_tot_trans)  OR ((v_tot_amount +prm_current_trans_amt) > prm_tot_transamt)   THEN

      	  prm_err_flag := '20';
     	  prm_err_msg  := 'Daily Transaction limit reached';
	  ELSE
	  	  prm_err_flag := '1';
 		  Prm_err_msg := 'OK';
		 
      END IF;
     END;

    END IF;
   EXCEPTION
   WHEN OTHERS THEN
    prm_err_flag := '20';
    prm_err_msg  := 'Error while checking daily transaction limit ' || SUBSTR(SQLERRM,1,200);
    RETURN;

   END;

  -- DAILY CHECK END



  -- WEEKLY CHECK BEGIN
  BEGIN
    IF v_usage_type = 'W' THEN
    v_begining_of_week := TRUNC(NEXT_DAY((prm_tran_date - 7),'monday')) ;

     BEGIN
      SELECT COUNT(1) , SUM(ctd_actual_amount)
      INTO   v_tot_transaction,v_tot_amount
      FROM   CMS_TRANSACTION_LOG_DTL
      WHERE  CTD_PROCESS_FLAG = 'Y'
	  AND    CTD_TXN_CODE IN ('10','30','90')
      AND    CTD_CUSTOMER_CARD_NO = prm_card_no
      AND    TO_DATE (   SUBSTR (TRIM (CTD_BUSINESS_DATE), 1, 8),'yyyymmdd')
             BETWEEN v_begining_of_week AND  prm_tran_date;

       IF  (v_tot_transaction >= prm_tot_trans)  OR ((v_tot_amount +prm_current_trans_amt) > prm_tot_transamt)   THEN

       	   prm_err_flag := '20';
      	   prm_err_msg  := 'Weekly Transaction limit reached';
	   ELSE
	   	   prm_err_flag := '1';
 		   Prm_err_msg := 'OK';
       END IF;
       END;

    END IF;

  EXCEPTION
   WHEN OTHERS THEN
    prm_err_flag := '20';
    prm_err_msg  := 'Error while checking weekly transaction limit ' || SUBSTR(SQLERRM,1,200);
    RETURN;

  END;

  -- WEEKLY CHECK END;


  -- MONTHLY CHECK BEGIN
  BEGIN
    IF v_usage_type = 'M' THEN
       v_begining_of_month := TRUNC((ADD_MONTHS((LAST_DAY(prm_tran_date) + 1), -1)));
       BEGIN
     SELECT COUNT(1) , SUM(ctd_actual_amount)
     INTO   v_tot_transaction,v_tot_amount
     FROM   CMS_TRANSACTION_LOG_DTL
     WHERE  CTD_PROCESS_FLAG = 'Y'
	 AND    CTD_TXN_CODE IN ('10','30','90')
     AND    CTD_CUSTOMER_CARD_NO = prm_card_no
     AND    TO_DATE (   SUBSTR (TRIM (CTD_BUSINESS_DATE), 1, 8),'yyyymmdd')
     BETWEEN v_begining_of_month AND  prm_tran_date;

      IF  (v_tot_transaction >= prm_tot_trans)  OR ((v_tot_amount +prm_current_trans_amt) > prm_tot_transamt)   THEN

      	  	prm_err_flag := '20';
     		prm_err_msg  := 'Monthly Transaction limit reached';
			
	  ELSE
	  	  	prm_err_flag := '1';
 		    Prm_err_msg := 'OK';
			
      END IF;
      END;



    END IF;
  EXCEPTION
   WHEN OTHERS THEN
   prm_err_flag := '20';
   prm_err_msg  := 'Error while checking monthly transaction limit ' || SUBSTR(SQLERRM,1,200);
   RETURN;

  END;

  -- MONTHLY CHECK END;


 EXCEPTION  --<< MAIN EXCEPTION >>

  WHEN OTHERS THEN
   prm_err_flag := '20';
   prm_err_msg  := 'Error from pre_auth process ' || SUBSTR(SQLERRM,1,200);

 END;   --<< MAIN END; >>
/


