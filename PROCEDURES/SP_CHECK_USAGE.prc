CREATE OR REPLACE PROCEDURE VMSCMS.SP_CHECK_USAGE
     (
     prm_inst_code   IN NUMBER,
     prm_usage_type   IN VARCHAR2,   -- '0'  --DAILY, '1' WEEKLY  , '2' monthly..
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
/*************************************************
     * Modified By      :  Deepa
     * Modified Date    :  30-Apr-2012
     * Modified Reason  :  for the response code change
     * Reviewer         :  Saravanakumar
     * Reviewed Date    :  30-Apr-2012
     * Build Number     :  CMS3.4.2_RI0008_B0002
 *************************************************/
 v_tot_transaction NUMBER;
 v_tot_amount  NUMBER;
 v_begining_of_week DATE; -- Monday is begining of the week.
 v_begining_of_month DATE;
 v_usage_type RULE.usagetype%TYPE;
  v_hash_pan    CMS_APPL_PAN.CAP_PAN_CODE%TYPE;

v_Retperiod  date;  --Added for VMS-5739/FSP-991
v_Retdate  date; --Added for VMS-5739/FSP-991

 BEGIN   --<< MAIN BEGIN >>

 v_usage_type := prm_usage_type;
--SN CREATE HASH PAN
BEGIN
    v_hash_pan := Gethash(prm_card_no);
EXCEPTION
WHEN OTHERS THEN
prm_err_msg := 'Error while converting pan ' || SUBSTR(SQLERRM,1,200);
RETURN;
END;
--EN CREATE HASH PAN

  -- DAILY CHECK BEGIN
   BEGIN
    IF v_usage_type = '0' THEN
    BEGIN
	--Added for VMS-5739/FSP-991
 select (add_months(trunc(sysdate,'MM'),'-'||RETENTION_PERIOD))
       INTO   v_Retperiod 
       FROM DBA_OPERATIONS.ARCHIVE_MGMT_CTL 
       WHERE  OPERATION_TYPE='ARCHIVE' 
       AND OBJECT_NAME='CMS_TRANSACTION_LOG_DTL_EBR';
       
       v_Retdate := TO_DATE(SUBSTR(TRIM(prm_tran_date), 1, 8), 'yyyymmdd');


IF (v_Retdate>v_Retperiod)
    THEN
     SELECT COUNT(1) , SUM(ctd_actual_amount)
     INTO   v_tot_transaction,v_tot_amount
     FROM   CMS_TRANSACTION_LOG_DTL
     WHERE  CTD_PROCESS_FLAG = 'Y'
     AND    CTD_TXN_CODE IN (select distinct CTM_TRAN_CODE from cms_transaction_mast where CTM_SUPPORT_TYPE='T')
     AND    CTD_CUSTOMER_CARD_NO = v_hash_pan --prm_card_no
     AND    TO_DATE (   SUBSTR (TRIM (CTD_BUSINESS_DATE), 1, 8),'yyyymmdd') = TRUNC(prm_tran_date);
ELSE
SELECT COUNT(1) , SUM(ctd_actual_amount)
     INTO   v_tot_transaction,v_tot_amount
     FROM   VMSCMS_HISTORY.CMS_TRANSACTION_LOG_DTL_HIST  --Added for VMS-5733/FSP-991
     WHERE  CTD_PROCESS_FLAG = 'Y'
     AND    CTD_TXN_CODE IN (select distinct CTM_TRAN_CODE from cms_transaction_mast where CTM_SUPPORT_TYPE='T')
     AND    CTD_CUSTOMER_CARD_NO = v_hash_pan --prm_card_no
     AND    TO_DATE (   SUBSTR (TRIM (CTD_BUSINESS_DATE), 1, 8),'yyyymmdd') = TRUNC(prm_tran_date);
END IF;	 


       IF v_tot_transaction=0 THEN

        v_tot_amount :=0;

       END IF;

      IF  (v_tot_transaction >= prm_tot_trans)  OR ((v_tot_amount +prm_current_trans_amt) > prm_tot_transamt)   THEN

            prm_err_flag := '70';--Modified by Deepa on 30-Apr-2012 to change the Response Code
           prm_err_msg  := 'Daily Transaction limit reached';
      ELSE
            prm_err_flag := '1';
           Prm_err_msg := 'OK';

      END IF;
     END;

    END IF;
   EXCEPTION
   WHEN OTHERS THEN
    prm_err_flag := '21';--Modified by Deepa on 30-Apr-2012 to change the Response Code
    prm_err_msg  := 'Error while checking daily transaction limit ' || SUBSTR(SQLERRM,1,200);
    RETURN;

   END;

  -- DAILY CHECK END



  -- WEEKLY CHECK BEGIN
  BEGIN
    IF v_usage_type = '1' THEN
    v_begining_of_week := TRUNC(NEXT_DAY((prm_tran_date - 7),'monday')) ;

     BEGIN
	 --Added for VMS-5739/FSP-991
 select (add_months(trunc(sysdate,'MM'),'-'||RETENTION_PERIOD))
       INTO   v_Retperiod 
       FROM DBA_OPERATIONS.ARCHIVE_MGMT_CTL 
       WHERE  OPERATION_TYPE='ARCHIVE' 
       AND OBJECT_NAME='CMS_TRANSACTION_LOG_DTL_EBR';
       
       v_Retdate := TO_DATE(SUBSTR(TRIM(prm_tran_date), 1, 8), 'yyyymmdd');


IF (v_Retdate>v_Retperiod)
    THEN
      SELECT COUNT(1) , SUM(ctd_actual_amount)
      INTO   v_tot_transaction,v_tot_amount
      FROM   CMS_TRANSACTION_LOG_DTL
      WHERE  CTD_PROCESS_FLAG = 'Y'
      AND    CTD_TXN_CODE IN (select distinct CTM_TRAN_CODE from cms_transaction_mast where CTM_SUPPORT_TYPE='T')
      AND    CTD_CUSTOMER_CARD_NO = v_hash_pan --prm_card_no
      AND    TO_DATE (   SUBSTR (TRIM (CTD_BUSINESS_DATE), 1, 8),'yyyymmdd')
             BETWEEN v_begining_of_week AND  prm_tran_date;
ELSE
	SELECT COUNT(1) , SUM(ctd_actual_amount)
      INTO   v_tot_transaction,v_tot_amount
      FROM   VMSCMS_HISTORY.CMS_TRANSACTION_LOG_DTL_HIST  --Added for VMS-5733/FSP-991
      WHERE  CTD_PROCESS_FLAG = 'Y'
      AND    CTD_TXN_CODE IN (select distinct CTM_TRAN_CODE from cms_transaction_mast where CTM_SUPPORT_TYPE='T')
      AND    CTD_CUSTOMER_CARD_NO = v_hash_pan --prm_card_no
      AND    TO_DATE (   SUBSTR (TRIM (CTD_BUSINESS_DATE), 1, 8),'yyyymmdd')
             BETWEEN v_begining_of_week AND  prm_tran_date;
END IF;			 

       IF v_tot_transaction=0 THEN

        v_tot_amount :=0;

       END IF;

       IF  (v_tot_transaction >= prm_tot_trans)  OR ((v_tot_amount +prm_current_trans_amt) > prm_tot_transamt)   THEN

              prm_err_flag := '70';--Modified by Deepa on 30-Apr-2012 to change the Response Code
             prm_err_msg  := 'Weekly Transaction limit reached';
       ELSE
              prm_err_flag := '1';
            Prm_err_msg := 'OK';
       END IF;
       END;

    END IF;

  EXCEPTION
   WHEN OTHERS THEN
    prm_err_flag := '21';
    prm_err_msg  := 'Error while checking weekly transaction limit ' || SUBSTR(SQLERRM,1,200);
    RETURN;

  END;

  -- WEEKLY CHECK END;


  -- MONTHLY CHECK BEGIN
  BEGIN
    IF v_usage_type = '2' THEN
       v_begining_of_month := TRUNC((ADD_MONTHS((LAST_DAY(prm_tran_date) + 1), -1)));
       BEGIN
	   --Added for VMS-5739/FSP-991
 select (add_months(trunc(sysdate,'MM'),'-'||RETENTION_PERIOD))
       INTO   v_Retperiod 
       FROM DBA_OPERATIONS.ARCHIVE_MGMT_CTL 
       WHERE  OPERATION_TYPE='ARCHIVE' 
       AND OBJECT_NAME='CMS_TRANSACTION_LOG_DTL_EBR';
       
       v_Retdate := TO_DATE(SUBSTR(TRIM(prm_tran_date), 1, 8), 'yyyymmdd');


IF (v_Retdate>v_Retperiod)
    THEN
     SELECT COUNT(1) , SUM(ctd_actual_amount)
     INTO   v_tot_transaction,v_tot_amount
     FROM   CMS_TRANSACTION_LOG_DTL
     WHERE  CTD_PROCESS_FLAG = 'Y'
     AND    CTD_TXN_CODE IN (select distinct CTM_TRAN_CODE from cms_transaction_mast where CTM_SUPPORT_TYPE='T')
     AND    CTD_CUSTOMER_CARD_NO = v_hash_pan --prm_card_no
     AND    TO_DATE (   SUBSTR (TRIM (CTD_BUSINESS_DATE), 1, 8),'yyyymmdd')
     BETWEEN v_begining_of_month AND  prm_tran_date;
ELSE
	     SELECT COUNT(1) , SUM(ctd_actual_amount)
     INTO   v_tot_transaction,v_tot_amount
     FROM   VMSCMS_HISTORY.CMS_TRANSACTION_LOG_DTL_HIST  --Added for VMS-5733/FSP-991
     WHERE  CTD_PROCESS_FLAG = 'Y'
     AND    CTD_TXN_CODE IN (select distinct CTM_TRAN_CODE from cms_transaction_mast where CTM_SUPPORT_TYPE='T')
     AND    CTD_CUSTOMER_CARD_NO = v_hash_pan --prm_card_no
     AND    TO_DATE (   SUBSTR (TRIM (CTD_BUSINESS_DATE), 1, 8),'yyyymmdd')
     BETWEEN v_begining_of_month AND  prm_tran_date;
END IF;
	 


       IF v_tot_transaction=0 THEN

        v_tot_amount :=0;

       END IF;

      IF  (v_tot_transaction >= prm_tot_trans)  OR ((v_tot_amount +prm_current_trans_amt) > prm_tot_transamt)   THEN

                prm_err_flag := '70';--Modified by Deepa on 30-Apr-2012 to change the Response Code
             prm_err_msg  := 'Monthly Transaction limit reached';

      ELSE
                prm_err_flag := '1';
             Prm_err_msg := 'OK';

      END IF;
      END;



    END IF;
  EXCEPTION
   WHEN OTHERS THEN
   prm_err_flag := '21';
   prm_err_msg  := 'Error while checking monthly transaction limit ' || SUBSTR(SQLERRM,1,200);
   RETURN;

  END;

  -- MONTHLY CHECK END;


 EXCEPTION  --<< MAIN EXCEPTION >>

  WHEN OTHERS THEN
   prm_err_flag := '21';
   prm_err_msg  := 'Error from pre_auth process ' || SUBSTR(SQLERRM,1,200);

 END;   --<< MAIN END; >>
/
SHOW ERROR;

