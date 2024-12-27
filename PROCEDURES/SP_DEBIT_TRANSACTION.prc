create or replace 
PROCEDURE   VMSCMS.SP_DEBIT_TRANSACTION(P_INSTCODE          IN NUMBER,
                                        P_RRN               IN VARCHAR2,
                                        P_TERMINALID        IN VARCHAR2,
                                        P_TRACENUMBER       IN VARCHAR2,
                                        P_TRANDATE          IN VARCHAR2,
                                        P_TRANTIME          IN VARCHAR2,
                                        P_PANNO             IN VARCHAR2,
                                        P_AMOUNT            IN NUMBER,
                                        P_CURRCODE          IN VARCHAR2,
                                        P_LUPDUSER          IN NUMBER,
                                        P_MSG               IN VARCHAR2,
                                        P_TXN_CODE          IN VARCHAR2,
                                        P_TXN_MODE          IN VARCHAR2,
                                        P_DELIVERY_CHANNEL  IN VARCHAR2,
                                        P_MBR_NUMB          IN VARCHAR2,
                                        P_RVSL_CODE         IN VARCHAR2,
                                        P_ODFI              IN VARCHAR2,
                                        P_RDFI              IN VARCHAR2,
                                        P_ACHFILENAME       IN VARCHAR2,
                                        P_SECCODE           IN VARCHAR2,
                                        P_IMPDATE           IN VARCHAR2,
                                        P_PROCESSDATE       IN VARCHAR2,
                                        P_EFFECTIVEDATE     IN VARCHAR2,
                                        P_INCOMING_CRFILEID IN VARCHAR2,
                                        P_ACHTRANTYPE_ID    IN VARCHAR2,
                                        P_INDIDNUM          IN VARCHAR2,
                                        P_INDNAME           IN VARCHAR2,
                                        P_COMPANYNAME       IN VARCHAR2,
                                        P_COMPANYID         IN VARCHAR2,
                                        P_ID                IN VARCHAR2,
                                        P_COMPENTRYDESC     IN VARCHAR2,
                                        P_CUST_ACCT_NO      IN VARCHAR2,
                                        P_PROCESSTYPE       IN VARCHAR2,
                                        P_RESP_CODE         OUT VARCHAR2,
                                        P_ERRMSG            OUT VARCHAR2,
                                        P_AUTH_ID           OUT VARCHAR2) AS
																		
  /************************************************
      * Created Date     :  10-Dec-2011
      * Created By       :  Srinivasu
      * PURPOSE          :  For debit transaction
      * Modified by      :  trivikram 
      * Modified Reason  :  ACH Transaction reports and Return file reports
      * Modified Date    : 29-Sep-2012 
      * Reviewed Date    : 29-Sep-2012 
      * Reviewer         : Saravanakumar.
      * Release Number   :  CMS3.5.1_RI0018.1
      
     * Modified By      :  Shweta M
     * Modified Date    :  14-Aug-2013
     * Modified For     :  MVHOST-367   
     * Reviewer         :  Dhiraj
     * Reviewed Date    : 19-aug-2013
     * Build Number     : RI0024.4_B0002
     
      * Modified by       : Sagar
      * Modified for      : 
      * Modified Reason   : Concurrent Processsing Issue 
                            (1.7.6.7 changes integarted)
      * Modified Date     : 04-Mar-2014
      * Reviewer          : Dhiarj
      * Reviewed Date     : 06-Mar-2014
      * Build Number      : RI0027.1.1_B0001    
      
      * Created by                  : Siva Kumar M
        * Created Date                : 30-Mar-16
        * Created For                 : Mantis id:16343
        * Created reason              : ssn encription logic
        * Reviewer                    : Spankaj/Saravana
        * Build Number                : VMSGPRHOSTCSD_4.0_B0008
        
     * Modified By      : Siva Kumar M
     * Modified Date    : 27/05/2016
     * Purpose          : FSS-4354,4355&4356
     * Reviewer         : Saravana Kumar 
     * Release Number   : VMSGPRHOSTCSD_4.1_B0003
     * Modified By      : MageshKumar S
     * Modified Date    : 10/08/2016
     * Purpose          : FSS-4354&4356
     * Reviewer         : Saravana Kumar 
     * Release Number   : VMSGPRHOSTCSD_4.2.1_B0001
     
     * Modified By      : MageshKumar S
     * Modified Date    : 12/08/2016
     * Purpose          : FSS-4354&4356 reversal check removal
     * Reviewer         : Saravana Kumar 
     * Release Number   : VMSGPRHOSTCSD_4.2.1_B0002
     
     * Modified By      : Abdul Hameed M.A
     * Modified Date    : 22-Aug-2016
     * Modified for     : FSS-4422
     * Reviewer         : Saravanakumar
     * Release Number   : CMS@CORE-VMSGPRHOSTCSD_4.8_B0002

    * Modified by      :  Pankaj S.
    * Modified Reason  : AQ in ACH queues in VMS(FSS-4613)
    * Modified Date    :  17-Oct-2016
    * Reviewer         :  Saravanankumar
    * Reviewed Date    :  24-Oct-2016
    * Build Number     : VMSGPRHOSTCSD_4.10   
    
           * Modified By      : Akhil
      * Modified Date    : 24-jan-2018
      * Purpose          : VMS-162
      * Reviewer         : Saravanakumar
      * Build Number     : VMSGPRHOST_18.1

     * Modified By      : A.Sivakaminathan
     * Modified Date    : 18-Jun-2019
     * Purpose          : VMS-597
     * Reviewer         : Saravanankumar A
     * Release Number   : VMSGPRHOST R17	  
	  
  *************************************************/
  V_CAP_PROD_CATG   CMS_APPL_PAN.CAP_PROD_CATG%TYPE;
  V_CAP_CARD_STAT   CMS_APPL_PAN.CAP_CARD_STAT%TYPE;
  V_CAP_CAFGEN_FLAG CMS_APPL_PAN.CAP_CAFGEN_FLAG%TYPE;
   
  V_FIRSTTIME_TOPUP CMS_APPL_PAN.CAP_FIRSTTIME_TOPUP%TYPE;
  V_PROD_CODE       CMS_APPL_PAN.CAP_PROD_CODE%TYPE;
  V_CARD_TYPE       CMS_APPL_PAN.CAP_CARD_TYPE%TYPE;
   
  V_ERRMSG          CMS_TRANSACTION_LOG_DTL.CTD_PROCESS_MSG%TYPE;
  V_APPL_CODE       CMS_APPL_MAST.CAM_APPL_CODE%TYPE;
   
  V_RESPCODE        TRANSACTIONLOG.RESPONSE_ID%TYPE;
  V_MBRNUMB         CMS_APPL_PAN.CAP_MBR_NUMB%TYPE;
   
  V_TXN_TYPE        CMS_FUNC_MAST.CFM_TXN_TYPE%TYPE;
  V_AUTH_ID         TRANSACTIONLOG.AUTH_ID%TYPE;
  
   
  V_HASH_PAN       CMS_APPL_PAN.CAP_PAN_CODE%TYPE;
  V_ENCR_PAN       CMS_APPL_PAN.CAP_PAN_CODE_ENCR%TYPE;
  V_BUSINESS_DATE  TRANSACTIONLOG.DATE_TIME%TYPE;
  V_TRAN_DATE      DATE;
  V_ACCT_BALANCE   CMS_ACCT_MAST.cam_acct_bal%type;
  V_LEDGER_BALANCE CMS_ACCT_MAST.CAM_LEDGER_BAL%type;
  V_TRAN_AMT       CMS_ACCT_MAST.CAM_LEDGER_BAL%type;
   
  V_PROXUNUMBER    CMS_APPL_PAN.CAP_PROXY_NUMBER%TYPE;
  V_ACCT_NUMBER    CMS_APPL_PAN.CAP_ACCT_NO%TYPE;
  V_CUSTLASTNAME   cms_cust_mast.ccm_last_name%type;
   
  
  V_ERR_CODE            VARCHAR2(5) DEFAULT 0; --Added by Deepa on 23-Apr-2012 not to log Invalid transaction Date and time
  V_DATE                DATE;
  V_IMP_DATE            DATE;
  V_IMP_TRAN_DATE       DATE;
  V_PROCESS_DATE        DATE;
  V_PROCESS_TRAN_DATE   DATE;
  V_EFFECTIVE_DATE      DATE;
  V_EFFECTIVE_TRAN_DATE DATE;

  V_DR_CR_FLAG  CMS_TRANSACTION_MAST.CTM_CREDIT_DEBIT_FLAG%TYPE;
  V_OUTPUT_TYPE CMS_TRANSACTION_MAST.CTM_OUTPUT_TYPE%TYPE;
  V_TRAN_TYPE   CMS_TRANSACTION_MAST.CTM_TRAN_TYPE%TYPE;
  v_file_count  PLS_INTEGER;
  V_TRANS_DESC   CMS_TRANSACTION_MAST.CTM_TRAN_DESC%TYPE; --Added for transaction detail report on 210812
  
  V_CUSTFIRSTNAME       cms_cust_mast.ccm_first_name%type;  -- Added by Trivikram on 29/Sep/2012 logging into transactionlog for display Customer Name in ACH Report FSS-418
  V_CUST_CODE           CMS_APPL_PAN.CAP_CUST_CODE%TYPE; -- Added by Trivikrram on 29/Sep/2012 , for cust code from appl_pan instead of quering again from appl_pan
  V_RRN_COUNT number;--Added for Concurrent Processsing Issue  on 25-FEB-2014 By Revathi
  
 v_ach_exp_flag  transactionlog.ach_exception_queue_flag%TYPE;
 v_cam_type_code          cms_acct_mast.cam_type_code%TYPE;
 v_queue_name                 VARCHAR2(100);
 v_merc_name                    VARCHAR2(100);
v_encrypt_enable cms_prod_cattype.cpc_encrypt_enable%type;

 EXP_MAIN_REJECT_RECORD       EXCEPTION;
 EXP_REJECT_RECORD            EXCEPTION; --Added by srinivasu on 07-Mar-2012 for testing defect fix
 
 v_Retperiod  date;  --Added for VMS-5739/FSP-991
v_Retdate  date; --Added for VMS-5739/FSP-991
 
PROCEDURE lp_purge_q
AS
   PRAGMA AUTONOMOUS_TRANSACTION;
   l_errmsg     VARCHAR2 (1000);
   l_last_ach   vms_achaq_clr.vac_last_ach%TYPE;
BEGIN
   SELECT vac_last_ach INTO l_last_ach FROM vms_achaq_clr;

   IF l_last_ach <> TRUNC (SYSDATE) THEN
      achaq.purge_queue ('ACH_QT', 'ACH_ACHVIEW_QUEUE', l_errmsg);

      UPDATE vms_achaq_clr
         SET vac_last_ach = TRUNC (SYSDATE);

      COMMIT;
   END IF;
EXCEPTION
   WHEN NO_DATA_FOUND THEN
      achaq.purge_queue ('ACH_QT', 'ACH_ACHVIEW_QUEUE', l_errmsg);
      
      INSERT INTO vms_achaq_clr (VAC_LAST_ACH)
           VALUES (TRUNC (SYSDATE));

      COMMIT;
   WHEN OTHERS THEN
      ROLLBACK;
END;

BEGIN
  --Changed by T.Narayanan for the debit transaction Response code changes beg
  P_RESP_CODE := '15';
  V_RESPCODE  := '15'; --Added by srinivasu on 07-Mar-2012 for testing defect fix
  --Changed by T.Narayanan for the debit transaction Response code changes end
  P_ERRMSG := 'invalid transaction';

  --SN CREATE HASH PAN
  BEGIN
    V_HASH_PAN := GETHASH(P_PANNO);
  EXCEPTION
    WHEN OTHERS THEN
     V_RESPCODE := '89';
     P_ERRMSG   := 'Error while converting pan ' ||
                SUBSTR(SQLERRM, 1, 200);
     RAISE EXP_MAIN_REJECT_RECORD;
  END;

  --EN CREATE HASH PAN

  --SN create encr pan
  BEGIN
    V_ENCR_PAN := FN_EMAPS_MAIN(P_PANNO);
  EXCEPTION
    WHEN OTHERS THEN
     V_RESPCODE := '89';
     P_ERRMSG   := 'Error while converting pan ' ||
                SUBSTR(SQLERRM, 1, 200);
     RAISE EXP_MAIN_REJECT_RECORD;
  END;
  
  --Sn find debit and credit flag

  BEGIN
    SELECT CTM_CREDIT_DEBIT_FLAG,
         CTM_OUTPUT_TYPE,
         TO_NUMBER(DECODE(CTM_TRAN_TYPE, 'N', '0', 'F', '1')),
         CTM_TRAN_TYPE,CTM_TRAN_DESC
     INTO V_DR_CR_FLAG, V_OUTPUT_TYPE, V_TXN_TYPE, V_TRAN_TYPE,V_TRANS_DESC
     FROM CMS_TRANSACTION_MAST
    WHERE CTM_TRAN_CODE = P_TXN_CODE AND
         CTM_DELIVERY_CHANNEL = P_DELIVERY_CHANNEL AND
         CTM_INST_CODE = P_INSTCODE;
  EXCEPTION
    WHEN NO_DATA_FOUND THEN
     V_RESPCODE := '12'; --Ineligible Transaction
     V_ERRMSG   := 'Transflag  not defined for txn code ' || P_TXN_CODE ||
                ' and delivery channel ' || P_DELIVERY_CHANNEL;
     RAISE EXP_MAIN_REJECT_RECORD;
    WHEN OTHERS THEN
     V_RESPCODE := '21'; --Ineligible Transaction
     V_RESPCODE := 'Error while selecting transaction details';
     RAISE EXP_MAIN_REJECT_RECORD;
  END;

  --En find debit and credit flag

  BEGIN
    IF (P_AMOUNT >= 0) THEN
     V_TRAN_AMT := P_AMOUNT;
    END IF;
  EXCEPTION
    WHEN OTHERS THEN
     P_ERRMSG   := 'Error while getting amount ' ||
                SUBSTR(SQLERRM, 1, 300);
     V_RESPCODE := '89'; -- Server Declined
     RAISE EXP_MAIN_REJECT_RECORD;
  END;

  BEGIN
    --  SELECT TO_CHAR(SYSDATE, 'YYYYMMDD') INTO V_AUTHID_DATE FROM DUAL;
  
    --  SELECT V_AUTHID_DATE || LPAD(SEQ_AUTH_ID.NEXTVAL, 6, '0')
    SELECT LPAD(SEQ_AUTH_ID.NEXTVAL, 6, '0') INTO V_AUTH_ID FROM DUAL;
  EXCEPTION
    WHEN OTHERS THEN
     P_ERRMSG   := 'Error while generating authid ' ||
                SUBSTR(SQLERRM, 1, 300);
     V_RESPCODE := '89'; -- Server Declined
     --ROLLBACK;
     -- RETURN;
     RAISE EXP_MAIN_REJECT_RECORD;
  END;

  P_AUTH_ID := V_AUTH_ID;
  BEGIN
    V_HASH_PAN := GETHASH(P_PANNO);
  EXCEPTION
    WHEN OTHERS THEN
     V_RESPCODE := '89';
     V_ERRMSG   := 'Error while converting pan ' ||
                SUBSTR(SQLERRM, 1, 200);
     RAISE EXP_MAIN_REJECT_RECORD;
  END;

  --Trnsaction Date Validation  starts
  BEGIN
    V_DATE := TO_DATE(SUBSTR(TRIM(P_TRANDATE), 1, 8), 'yyyymmdd');
  EXCEPTION
    WHEN OTHERS THEN
     V_RESPCODE := '89';
     V_ERR_CODE := '45';
     P_ERRMSG   := 'Problem while converting transaction date ' ||
                SUBSTR(SQLERRM, 1, 200);
     RAISE EXP_MAIN_REJECT_RECORD;
  END;

  BEGIN
    V_TRAN_DATE := TO_DATE(SUBSTR(TRIM(P_TRANDATE), 1, 8) || ' ' ||
                      SUBSTR(TRIM(P_TRANTIME), 1, 10),
                      'yyyymmdd hh24:mi:ss');
  EXCEPTION
    WHEN OTHERS THEN
     V_RESPCODE := '89';
     V_ERR_CODE := '32';
     P_ERRMSG   := 'Problem while converting transaction time ' ||
                SUBSTR(SQLERRM, 1, 200);
     RAISE EXP_MAIN_REJECT_RECORD;
  END;

  --Trnsaction Date Validation Ends

  --Imp date Vlaidation starts
  BEGIN
    V_IMP_DATE := TO_DATE(SUBSTR(TRIM(P_IMPDATE), 1, 8), 'yyyymmdd');
  EXCEPTION
    WHEN OTHERS THEN
     V_RESPCODE := '89';
     V_ERR_CODE := '45';
     P_ERRMSG   := 'Problem while converting IMP Date  ' ||
                SUBSTR(SQLERRM, 1, 200);
     RAISE EXP_MAIN_REJECT_RECORD;
  END;

  BEGIN
    V_IMP_TRAN_DATE := TO_DATE(SUBSTR(TRIM(P_IMPDATE), 1, 8) || ' ' ||
                         SUBSTR(TRIM(P_IMPDATE), 9, 19),
                         'yyyymmdd hh24:mi:ss');
  EXCEPTION
    WHEN OTHERS THEN
     V_RESPCODE := '89';
     V_ERR_CODE := '32';
     P_ERRMSG   := 'Problem while converting IMP Time ' ||
                SUBSTR(SQLERRM, 1, 200);
     RAISE EXP_MAIN_REJECT_RECORD;
  END;

  --IMP Date Validaton Ends

  --PROCESS date Vlaidation starts
  BEGIN
    V_PROCESS_DATE := TO_DATE(SUBSTR(TRIM(P_PROCESSDATE), 1, 8), 'yyyymmdd');
  EXCEPTION
    WHEN OTHERS THEN
     V_RESPCODE := '89';
     V_ERR_CODE := '45';
     P_ERRMSG   := 'Problem while converting PROCESS Date  ' ||
                SUBSTR(SQLERRM, 1, 200);
     RAISE EXP_MAIN_REJECT_RECORD;
  END;

  BEGIN
    V_PROCESS_TRAN_DATE := TO_DATE(SUBSTR(TRIM(P_PROCESSDATE), 1, 8) || ' ' ||
                            SUBSTR(TRIM(P_PROCESSDATE), 9, 19),
                            'yyyymmdd hh24:mi:ss');
  EXCEPTION
    WHEN OTHERS THEN
     V_RESPCODE := '89';
     V_ERR_CODE := '32';
     P_ERRMSG   := 'Problem while converting PROCESS Time ' ||
                SUBSTR(SQLERRM, 1, 200);
     RAISE EXP_MAIN_REJECT_RECORD;
  END;

  --PROCESS Date Validaton Ends

  --EFFECTIVE DATE   Vlaidation starts
  BEGIN
    V_EFFECTIVE_DATE := TO_DATE(SUBSTR(TRIM(P_EFFECTIVEDATE), 1, 8),
                          'yyyymmdd');
  EXCEPTION
    WHEN OTHERS THEN
     V_RESPCODE := '89';
     V_ERR_CODE := '45';
     P_ERRMSG   := 'Problem while converting EFFECTIVE Date  ' ||
                SUBSTR(SQLERRM, 1, 200);
     RAISE EXP_MAIN_REJECT_RECORD;
  END;

  BEGIN
    V_EFFECTIVE_TRAN_DATE := TO_DATE(SUBSTR(TRIM(P_EFFECTIVEDATE), 1, 8) || ' ' ||
                              SUBSTR(TRIM(P_EFFECTIVEDATE), 9, 19),
                              'yyyymmdd hh24:mi:ss');
  EXCEPTION
    WHEN OTHERS THEN
     V_RESPCODE := '89';
     V_ERR_CODE := '32';
     P_ERRMSG   := 'Problem while converting EFFECTIVE Time ' ||
                SUBSTR(SQLERRM, 1, 200);
     RAISE EXP_MAIN_REJECT_RECORD;
  END;

  --EFFECTIVE DATE   Validaton Ends


  --Getting Cardstatus
  BEGIN
    SELECT CAP_CARD_STAT,
         CAP_PROD_CATG,
         CAP_CAFGEN_FLAG,
         CAP_APPL_CODE,
         CAP_FIRSTTIME_TOPUP,
         CAP_MBR_NUMB,
         CAP_PROD_CODE,
         CAP_CARD_TYPE,
         CAP_PROXY_NUMBER,
         CAP_ACCT_NO,
         CAP_CUST_CODE -- Added by Trivikrram on 29/Sep/2012 , for cust code , FSS - 418
     INTO V_CAP_CARD_STAT,
         V_CAP_PROD_CATG,
         V_CAP_CAFGEN_FLAG,
         V_APPL_CODE,
         V_FIRSTTIME_TOPUP,
         V_MBRNUMB,
         V_PROD_CODE,
         V_CARD_TYPE,
         V_PROXUNUMBER,
         V_ACCT_NUMBER,
         V_CUST_CODE    -- Added by Trivikrram on 29/Sep/2012 , for cust code , FSS - 418
     FROM CMS_APPL_PAN
    WHERE CAP_PAN_CODE = V_HASH_PAN AND CAP_INST_CODE = P_INSTCODE;
  
  EXCEPTION
    WHEN EXP_MAIN_REJECT_RECORD THEN
     RAISE;
    WHEN NO_DATA_FOUND THEN
     V_RESPCODE := '89';
     V_ERRMSG   := 'Invalid Card number ' || V_HASH_PAN;
     RAISE EXP_MAIN_REJECT_RECORD;
    WHEN OTHERS THEN
     V_RESPCODE := '89';
     V_ERRMSG   := 'Error while selecting card number ' || V_HASH_PAN;
     RAISE EXP_MAIN_REJECT_RECORD;
  END;
  
   BEGIN
         SELECT  cam_acct_bal, cam_ledger_bal, cam_type_code
            INTO v_acct_balance, v_ledger_balance, v_cam_type_code
            FROM cms_acct_mast
           WHERE cam_acct_no = p_cust_acct_no AND cam_inst_code = p_instcode
      FOR UPDATE;

   EXCEPTION
      WHEN NO_DATA_FOUND
      THEN
         v_respcode := '16';
         v_errmsg := 'Invalid Account No ';
         RAISE exp_main_reject_record;
      WHEN OTHERS
      THEN
         v_respcode := '12';
         v_errmsg :=
            'Error while selecting account dtls ' || SUBSTR (SQLERRM, 1, 200);
         RAISE exp_main_reject_record;
   END;


--Sn Added for Concurrent Processsing Issue 
  --Sn Duplicate RRN Check.IF duplicate RRN log the txn and return
  BEGIN
    IF P_PROCESSTYPE <> 'N' THEN
	--Added for VMS-5739/FSP-991
 select (add_months(trunc(sysdate,'MM'),'-'||RETENTION_PERIOD))
       INTO   v_Retperiod 
       FROM DBA_OPERATIONS.ARCHIVE_MGMNT_CTL 
       WHERE  OPERATION_TYPE='ARCHIVE' 
       AND OBJECT_NAME='TRANSACTIONLOG_EBR';
       
       v_Retdate := TO_DATE(SUBSTR(TRIM(p_trandate), 1, 8), 'yyyymmdd');


IF (v_Retdate>v_Retperiod)
    THEN
     SELECT COUNT(1)
       INTO V_RRN_COUNT
       FROM TRANSACTIONLOG
      WHERE RRN = P_RRN AND BUSINESS_DATE = P_TRANDATE AND
           DELIVERY_CHANNEL = P_DELIVERY_CHANNEL;
     --Added by ramkumar.Mk on 25 march 2012
ELSE
	SELECT COUNT(1)
       INTO V_RRN_COUNT
       FROM VMSCMS_HISTORY.TRANSACTIONLOG_HIST --Added for VMS-5733/FSP-991
      WHERE RRN = P_RRN AND BUSINESS_DATE = P_TRANDATE AND
           DELIVERY_CHANNEL = P_DELIVERY_CHANNEL;
     --Added by ramkumar.Mk on 25 march 2012
END IF;	 
    END IF;

    IF V_RRN_COUNT > 0 THEN
     V_RESPCODE := '22';
     V_ERRMSG   := 'Duplicate RRN ' || 'on ' || P_TRANDATE;
     RAISE EXP_MAIN_REJECT_RECORD;
    END IF;
  EXCEPTION
    WHEN EXP_MAIN_REJECT_RECORD THEN
     RAISE EXP_MAIN_REJECT_RECORD;
    WHEN OTHERS THEN
     V_RESPCODE := '21';
     V_ERRMSG   := 'Duplicate RRN ' || 'on ' || P_TRANDATE;
     RAISE EXP_MAIN_REJECT_RECORD;
  END;

  --En Duplicate RRN Check
--En Added for Concurrent Processsing Issue  
  
  
    IF UPPER(p_compentrydesc) LIKE '%REVERSAL%' THEN
      v_ach_exp_flag := 'R';
      V_RESPCODE     := '253';
      V_ERRMSG       := 'Debit Reversal';
      P_ERRMSG:=V_ERRMSG;
      v_queue_name :='ACH_REVERSAL_QUEUE';
      RAISE EXP_MAIN_REJECT_RECORD;
    END IF;
  

  --Modified by srinivasu on 20 feb 2012 for reponse code changes from 89 to R20
  BEGIN
    SELECT CMS_ISO_RESPCDE
     INTO P_RESP_CODE
     FROM CMS_RESPONSE_MAST
    WHERE CMS_INST_CODE = P_INSTCODE AND
         CMS_DELIVERY_CHANNEL = TO_NUMBER(P_DELIVERY_CHANNEL) AND
         CMS_RESPONSE_ID = TO_NUMBER(V_RESPCODE);
  EXCEPTION
    WHEN OTHERS THEN
     V_ERRMSG   := 'Problem while selecting data from response master for respose code' ||
                V_RESPCODE || SUBSTR(SQLERRM, 1, 300);
    V_RESPCODE := '89'; --Modified by srinivasu on 20 feb 2012 for reponse code changes from 89 to R20
    --P_RESP_CODE := 'R20'; --Added for Response_id on 200912.
    P_RESP_CODE := 'R16'; 
     RAISE EXP_REJECT_RECORD; --Modified by srinu raised exception changedExceptiion
  END;
  
  
   -- Added by Trivikram on 29/Sep/2012 , fetching First Name and Last Name  for display Customer Name in ACH Report FSS-418
   
  BEGIN
        SELECT cpc_encrypt_enable
          INTO v_encrypt_enable
          FROM cms_prod_cattype
         WHERE cpc_inst_code=p_instcode
         and cpc_prod_code=v_prod_code
         and cpc_card_type=v_card_type;
   EXCEPTION
    WHEN OTHERS THEN
     V_RESPCODE := '17';
     V_ERRMSG   := 'Error while selecting prod cattype' || SUBSTR(SQLERRM, 1, 200);
     RAISE EXP_MAIN_REJECT_RECORD;
  END;
  
  BEGIN
      SELECT  decode(v_encrypt_enable,'Y',fn_dmaps_main(CCM_LAST_NAME),ccm_last_name)
      ,decode(v_encrypt_enable,'Y',fn_dmaps_main( CCM_FIRST_NAME),ccm_first_name)
     INTO  V_CUSTLASTNAME, V_CUSTFIRSTNAME 
     FROM CMS_CUST_MAST
    WHERE CCM_CUST_CODE = V_CUST_CODE  AND CCM_INST_CODE = P_INSTCODE;
  
   EXCEPTION
    WHEN NO_DATA_FOUND THEN
     V_RESPCODE := '17';
     V_ERRMSG   := 'SSN Not Available';
     RAISE EXP_MAIN_REJECT_RECORD;
    WHEN OTHERS THEN
     V_RESPCODE := '17';
     V_ERRMSG   := 'Error while selecting SSN' || SUBSTR(SQLERRM, 1, 200);
     RAISE EXP_MAIN_REJECT_RECORD;
  END;
  
  -- Added code for log into CMS_ACH_FILEPROCESS table by Trivikram on 23 July 2012
  BEGIN
          SELECT COUNT (*)
            INTO v_file_count
            FROM cms_ach_fileprocess
           WHERE caf_ach_file = p_achfilename AND caf_inst_code = p_instcode;

          IF v_file_count = 0
          THEN
             INSERT INTO cms_ach_fileprocess
                         (caf_inst_code, caf_ach_file, caf_tran_date,
                          caf_lupd_user, caf_ins_user
                         )
                  VALUES (p_instcode, p_achfilename, p_trandate,
                          p_lupduser, p_lupduser
                         );
          END IF;
       EXCEPTION
          WHEN OTHERS
          THEN
             v_errmsg :=
                   'Error while inserting records into ACH File Processing table    '
                || SUBSTR (SQLERRM, 1, 200);
         --  v_respcode := 'R20';
           V_RESPCODE := '89';  
           --P_RESP_CODE := 'R20'; --Added for Response_id on 200912.
           P_RESP_CODE := 'R16'; 
            
             RAISE exp_main_reject_record;
       END;
       
  IF V_ERRMSG IS NULL THEN
  V_ERRMSG := P_ERRMSG;
  END IF;

  BEGIN
    INSERT INTO TRANSACTIONLOG
     (MSGTYPE,
      RRN,
      DELIVERY_CHANNEL,
      TERMINAL_ID,
      DATE_TIME,
      TXN_CODE,
      TXN_TYPE,
      TXN_MODE,
      TXN_STATUS,
      RESPONSE_CODE,
      BUSINESS_DATE,
      BUSINESS_TIME,
      CUSTOMER_CARD_NO,
      TOPUP_CARD_NO,
      TOPUP_ACCT_NO,
      TOPUP_ACCT_TYPE,
      BANK_CODE,
      TOTAL_AMOUNT,
      CURRENCYCODE,
      ADDCHARGE,
      PRODUCTID,
      CATEGORYID,
      ATM_NAME_LOCATION,
      AUTH_ID,
      AMOUNT,
      PREAUTHAMOUNT,
      PARTIALAMOUNT,
      INSTCODE,
      CUSTOMER_CARD_NO_ENCR,
      TOPUP_CARD_NO_ENCR,
      PROXY_NUMBER,
      REVERSAL_CODE,
      CUSTOMER_ACCT_NO,
      ACCT_BALANCE,
      LEDGER_BALANCE,
      ACHFILENAME,
      RDFI,
      SECCODES,
      IMPDATE,
      PROCESSDATE,
      EFFECTIVEDATE,
      TRACENUMBER,
      INCOMING_CRFILEID,
      ACHTRANTYPE_ID,
      INDIDNUM,
      INDNAME,
      COMPANYNAME,
      COMPANYID,
      ACH_ID,
      COMPENTRYDESC,
      RESPONSE_ID,
      CUSTOMERLASTNAME,
      CARDSTATUS,
      PROCESSTYPE,
      TRANS_DESC,
      CUSTFIRSTNAME, -- Added by Trivikram on 29/Sep/2012 logging into transactionlog for display Customer Name in ACH Report FSS-418
    MERCHANT_NAME,ERROR_MSG---Added by Shweta on 14Aug13 for MVHOST-367 
      )
    VALUES
     (P_MSG,
      P_RRN,
      P_DELIVERY_CHANNEL,
      P_TERMINALID,
      V_BUSINESS_DATE,
      P_TXN_CODE,
      V_TXN_TYPE,
      P_TXN_MODE,
      DECODE(P_RESP_CODE, '00', 'C', 'F'),
      P_RESP_CODE,
      P_TRANDATE,
      SUBSTR(P_TRANTIME, 1, 10),
      V_HASH_PAN,
      NULL,
      NULL,
      NULL,
      P_INSTCODE,
      TRIM(TO_CHAR(V_TRAN_AMT, '999999999999999990.99')),
      P_CURRCODE,
      NULL,
      V_PROD_CODE,
      V_CARD_TYPE,
      P_TERMINALID,
      P_AUTH_ID,
      TRIM(TO_CHAR(V_TRAN_AMT, '999999999999999990.99')),
      NULL,
      NULL,
      P_INSTCODE,
      V_ENCR_PAN,
      V_ENCR_PAN,
      V_PROXUNUMBER,
      P_RVSL_CODE,
      P_CUST_ACCT_NO,
      V_ACCT_BALANCE,
      V_LEDGER_BALANCE,
      P_ACHFILENAME,
      P_RDFI,
      P_SECCODE,
      P_IMPDATE,
      P_PROCESSDATE,
      P_EFFECTIVEDATE,
      P_TRACENUMBER,
      P_INCOMING_CRFILEID,
      P_ACHTRANTYPE_ID,
          --P_INDIDNUM,
          fn_maskacct_ssn(P_INSTCODE,P_INDIDNUM,0),
      P_INDNAME,
      P_COMPANYNAME,
      P_COMPANYID,
      P_ID,
      P_COMPENTRYDESC,
      V_RESPCODE,
      V_CUSTLASTNAME,
      V_CAP_CARD_STAT,
      P_PROCESSTYPE,
      V_TRANS_DESC,
      V_CUSTFIRSTNAME, -- Added by Trivikram on 29/Sep/2012 logging into transactionlog for display Customer Name in ACH Report FSS-418
      P_COMPANYNAME,V_ERRMSG );  ---Added by Shweta on 14Aug13 for MVHOST-367 
  EXCEPTION
    WHEN OTHERS THEN
    -- P_RESP_CODE := 'R20'; --Modified by srinivasu on 20 feb 2012 for reponse code changes from 89 to R20
     P_RESP_CODE := 'R16'; 
     P_ERRMSG    := 'Problem while inserting data into transaction log  dtl' ||
                 SUBSTR(SQLERRM, 1, 300);
  END;

  --En create a entry in txn log

  BEGIN
    INSERT INTO CMS_TRANSACTION_LOG_DTL
     (CTD_DELIVERY_CHANNEL,
      CTD_TXN_CODE,
      CTD_MSG_TYPE,
      CTD_TXN_MODE,
      CTD_BUSINESS_DATE,
      CTD_BUSINESS_TIME,
      CTD_CUSTOMER_CARD_NO,
      CTD_TXN_AMOUNT,
      CTD_TXN_CURR,
      CTD_ACTUAL_AMOUNT,
      CTD_FEE_AMOUNT,
      CTD_WAIVER_AMOUNT,
      CTD_SERVICETAX_AMOUNT,
      CTD_CESS_AMOUNT,
      CTD_BILL_AMOUNT,
      CTD_BILL_CURR,
      CTD_PROCESS_FLAG,
      CTD_PROCESS_MSG,
      CTD_RRN,
      CTD_INST_CODE,
      CTD_CUSTOMER_CARD_NO_ENCR,
      CTD_CUST_ACCT_NUMBER,
      CTD_TXN_TYPE)
    VALUES
     (P_DELIVERY_CHANNEL,
      P_TXN_CODE,
      P_MSG,
      P_TXN_MODE,
      P_TRANDATE,
      P_TRANTIME,
      V_HASH_PAN,
      P_AMOUNT,
      P_CURRCODE,
      P_AMOUNT,
      NULL,
      NULL,
      NULL,
      NULL,
      NULL,
      NULL,
      'E',
      V_ERRMSG,
      P_RRN,
      P_INSTCODE,
      V_ENCR_PAN,
      P_CUST_ACCT_NO,
      V_TXN_TYPE);
  
    --p_errmsg := v_errmsg;
    RETURN;
  EXCEPTION
    WHEN OTHERS THEN
     P_ERRMSG    := 'Problem while inserting data into transaction log  dtl' ||
                 SUBSTR(SQLERRM, 1, 300);
     --P_RESP_CODE := 'R20'; --Modified by srinivasu on 20 feb 2012 for reponse code changes from 89 to R20
     P_RESP_CODE := 'R16'; 
     ROLLBACK;
     RETURN;
  END;

    
  --Added by srinivasu on 07-Mar-2012 for testing defect fix
EXCEPTION
  WHEN EXP_REJECT_RECORD THEN
  
    IF V_ERR_CODE NOT IN ('32', '45') THEN
     BEGIN
     
       INSERT INTO TRANSACTIONLOG
        (MSGTYPE,
         RRN,
         DELIVERY_CHANNEL,
         TERMINAL_ID,
         DATE_TIME,
         TXN_CODE,
         TXN_TYPE,
         TXN_MODE,
         TXN_STATUS,
         RESPONSE_CODE,
         BUSINESS_DATE,
         BUSINESS_TIME,
         CUSTOMER_CARD_NO,
         TOPUP_CARD_NO,
         TOPUP_ACCT_NO,
         TOPUP_ACCT_TYPE,
         BANK_CODE,
         TOTAL_AMOUNT,
         CURRENCYCODE,
         ADDCHARGE,
         PRODUCTID,
         CATEGORYID,
         ATM_NAME_LOCATION,
         AUTH_ID,
         AMOUNT,
         PREAUTHAMOUNT,
         PARTIALAMOUNT,
         INSTCODE,
         CUSTOMER_CARD_NO_ENCR,
         TOPUP_CARD_NO_ENCR,
         PROXY_NUMBER,
         REVERSAL_CODE,
         CUSTOMER_ACCT_NO,
         ACCT_BALANCE,
         LEDGER_BALANCE,
         ACHFILENAME,
         RDFI,
         SECCODES,
         IMPDATE,
         PROCESSDATE,
         EFFECTIVEDATE,
         TRACENUMBER,
         INCOMING_CRFILEID,
         ACHTRANTYPE_ID,
         INDIDNUM,
         INDNAME,
         COMPANYNAME,
         COMPANYID,
         ACH_ID,
         COMPENTRYDESC,
         RESPONSE_ID,
         CUSTOMERLASTNAME,
         CARDSTATUS,
         PROCESSTYPE,
         TRANS_DESC,
         CUSTFIRSTNAME,  -- Added by Trivikram on 29/Sep/2012 logging into transactionlog for display Customer Name in ACH Report FSS-418
          MERCHANT_NAME,ERROR_MSG---Added by Shweta on 14Aug13 for MVHOST-367 
          )
       VALUES
        (P_MSG,
         P_RRN,
         P_DELIVERY_CHANNEL,
         P_TERMINALID,
         V_BUSINESS_DATE,
         P_TXN_CODE,
         V_TXN_TYPE,
         P_TXN_MODE,
         DECODE(P_RESP_CODE, '00', 'C', 'F'),
         P_RESP_CODE,
         P_TRANDATE,
         SUBSTR(P_TRANTIME, 1, 10),
         V_HASH_PAN,
         NULL,
         NULL,
         NULL,
         P_INSTCODE,
         TRIM(TO_CHAR(V_TRAN_AMT, '999999999999999990.99')),
         P_CURRCODE,
         NULL,
         V_PROD_CODE,
         V_CARD_TYPE,
         P_TERMINALID,
         P_AUTH_ID,
         TRIM(TO_CHAR(V_TRAN_AMT, '999999999999999990.99')),
         NULL,
         NULL,
         P_INSTCODE,
         V_ENCR_PAN,
         V_ENCR_PAN,
         V_PROXUNUMBER,
         P_RVSL_CODE,
         P_CUST_ACCT_NO,
         V_ACCT_BALANCE,
         V_LEDGER_BALANCE,
         P_ACHFILENAME,
         P_RDFI,
         P_SECCODE,
         P_IMPDATE,
         P_PROCESSDATE,
         P_EFFECTIVEDATE,
         P_TRACENUMBER,
         P_INCOMING_CRFILEID,
         P_ACHTRANTYPE_ID,
                 --P_INDIDNUM,
                 fn_maskacct_ssn(P_INSTCODE,P_INDIDNUM,0),
         P_INDNAME,
         P_COMPANYNAME,
         P_COMPANYID,
         P_ID,
         P_COMPENTRYDESC,
         V_RESPCODE,
         V_CUSTLASTNAME,
         V_CAP_CARD_STAT,
         P_PROCESSTYPE,
         V_TRANS_DESC,
         V_CUSTFIRSTNAME , -- Added by Trivikram on 29/Sep/2012 logging into transactionlog for display Customer Name in ACH Report FSS-418
          P_COMPANYNAME,V_ERRMSG  ---Added by Shweta on 14Aug13 for MVHOST-367 
         );
     EXCEPTION
       WHEN OTHERS THEN
        --P_RESP_CODE := 'R20'; --Modified by srinivasu on 20 feb 2012 for reponse code changes from 89 to R20
        P_RESP_CODE := 'R16'; 
        P_ERRMSG    := 'Problem while inserting data into transaction log  dtl' ||
                    SUBSTR(SQLERRM, 1, 300);
     END;
     
     -- Added code for log into CMS_ACH_FILEPROCESS table by Trivikram on 23 July 2012
     BEGIN
          SELECT COUNT (*)
            INTO v_file_count
            FROM cms_ach_fileprocess
           WHERE caf_ach_file = p_achfilename AND caf_inst_code = p_instcode;

          IF v_file_count = 0
          THEN
             INSERT INTO cms_ach_fileprocess
                         (caf_inst_code, caf_ach_file, caf_tran_date,
                          caf_lupd_user, caf_ins_user
                         )
                  VALUES (p_instcode, p_achfilename, p_trandate,
                          p_lupduser, p_lupduser
                         );
          END IF;
       EXCEPTION
          WHEN OTHERS
          THEN
             v_errmsg :=
                   'Error while inserting records into ACH File Processing table    '
                || SUBSTR (SQLERRM, 1, 200);
          --  v_respcode := 'R20';
          V_RESPCODE := '89';  
         --P_RESP_CODE := 'R20'; --Added for Response_id on 200912.
         P_RESP_CODE := 'R16'; 
              
             RAISE exp_main_reject_record;
       END;
       
        BEGIN      
          IF v_queue_name IS NULL THEN 
              lp_purge_q;
          END IF;   
		
          SELECT REGEXP_REPLACE(NVL((DECODE(p_companyname ,'','','/'||p_companyname) ||
                DECODE( p_compentrydesc ,'','','/'||p_compentrydesc) ||
                DECODE( p_indname ,'','','/'||p_indidnum||' to '||p_indname)),'Direct Deposit'),'/','',1,1)
          INTO V_MERC_NAME
          FROM dual;
     
            
           achaq.enqueue_ach_msgs (ach_type (p_rrn,
                                             p_trandate,
                                             p_trantime,
                                             p_txn_code,
                                             p_delivery_channel,
                                             v_trans_desc,
                                             v_hash_pan,
                                             v_encr_pan,
                                             v_cap_card_stat,
                                             v_tran_amt,
                                             NULL,
                                             SYSDATE,
                                             p_achfilename,
                                             NULL,
                                             'N',
                                             p_auth_id,
                                             p_indname,
                                             v_acct_balance,
                                             v_ledger_balance,
                                             v_respcode,
                                             p_resp_code,
                                             v_merc_name),
                                   NVL (v_queue_name, 'ACH_ACHVIEW_QUEUE'),
                                   v_errmsg);
         IF v_errmsg <> 'OK'
         THEN
            v_errmsg := 'Error in enqueue_ach_msgs ACH_ACHVIEW_QUEUE ' || v_errmsg;
            RAISE exp_main_reject_record;
         END IF;
      EXCEPTION
         WHEN exp_main_reject_record THEN
            --RAISE;
            null;
         WHEN OTHERS    THEN
            V_RESPCODE := '21';
            v_errmsg := 'Error while enqueue ACH_ACHVIEW_QUEUE ' || SUBSTR (SQLERRM, 1, 200);
            --RAISE exp_main_reject_record;
      END;
       
    END IF;
  
    BEGIN
     INSERT INTO CMS_TRANSACTION_LOG_DTL
       (CTD_DELIVERY_CHANNEL,
        CTD_TXN_CODE,
        CTD_MSG_TYPE,
        CTD_TXN_MODE,
        CTD_BUSINESS_DATE,
        CTD_BUSINESS_TIME,
        CTD_CUSTOMER_CARD_NO,
        CTD_TXN_AMOUNT,
        CTD_TXN_CURR,
        CTD_ACTUAL_AMOUNT,
        CTD_FEE_AMOUNT,
        CTD_WAIVER_AMOUNT,
        CTD_SERVICETAX_AMOUNT,
        CTD_CESS_AMOUNT,
        CTD_BILL_AMOUNT,
        CTD_BILL_CURR,
        CTD_PROCESS_FLAG,
        CTD_PROCESS_MSG,
        CTD_RRN,
        CTD_INST_CODE,
        CTD_CUSTOMER_CARD_NO_ENCR,
        CTD_CUST_ACCT_NUMBER,
        CTD_TXN_TYPE)
     VALUES
       (P_DELIVERY_CHANNEL,
        P_TXN_CODE,
        P_MSG,
        P_TXN_MODE,
        P_TRANDATE,
        P_TRANTIME,
        --p_card_no
        V_HASH_PAN,
        P_AMOUNT,
        P_CURRCODE,
        P_AMOUNT,
        NULL,
        NULL,
        NULL,
        NULL,
        NULL,
        NULL,
        'E',
        V_ERRMSG,
        P_RRN,
        P_INSTCODE,
        V_ENCR_PAN,
        P_CUST_ACCT_NO,
        V_TXN_TYPE);
    
     RETURN;
    EXCEPTION
     WHEN OTHERS THEN
       P_ERRMSG    := 'Problem while inserting data into transaction log  dtl' ||
                   SUBSTR(SQLERRM, 1, 300);
      -- P_RESP_CODE := 'R20'; --Modified by srinivasu on 20 feb 2012 for reponse code changes from 89 to R20
      P_RESP_CODE := 'R16'; 
       ROLLBACK;
       RETURN;
    END;
  
  WHEN EXP_MAIN_REJECT_RECORD THEN
  
    --Modified by srinivasu on 20 feb 2012 for reponse code changes from 89 to R20
    BEGIN
     SELECT CMS_ISO_RESPCDE
       INTO P_RESP_CODE
       FROM CMS_RESPONSE_MAST
      WHERE CMS_INST_CODE = P_INSTCODE AND
           CMS_DELIVERY_CHANNEL = TO_NUMBER(P_DELIVERY_CHANNEL) AND
           CMS_RESPONSE_ID = TO_NUMBER(V_RESPCODE);
    EXCEPTION
     WHEN OTHERS THEN
       V_ERRMSG   := 'Problem while selecting data from response master for respose code' ||
                  V_RESPCODE || SUBSTR(SQLERRM, 1, 300);
     -- V_RESPCODE := 'R20'; --Modified by srinivasu on 20 feb 2012 for reponse code changes from 89 to R20
      V_RESPCODE := '89'; --Modified by srinivasu on 20 feb 2012 for reponse code changes from 89 to R20
      --P_RESP_CODE := 'R20'; --Added for Response_id on 200912.
      P_RESP_CODE := 'R16'; 
       --RAISE EXP_MAIN_REJECT_RECORD;
    END;
  
    IF V_ERR_CODE NOT IN ('32', '45') THEN
     --Added by Deepa on Apr-23-2012 not to log the Invalid transaction Date and Time
     BEGIN
       INSERT INTO TRANSACTIONLOG
        (MSGTYPE,
         RRN,
         DELIVERY_CHANNEL,
         TERMINAL_ID,
         DATE_TIME,
         TXN_CODE,
         TXN_TYPE,
         TXN_MODE,
         TXN_STATUS,
         RESPONSE_CODE,
         BUSINESS_DATE,
         BUSINESS_TIME,
         CUSTOMER_CARD_NO,
         TOPUP_CARD_NO,
         TOPUP_ACCT_NO,
         TOPUP_ACCT_TYPE,
         BANK_CODE,
         TOTAL_AMOUNT,
         CURRENCYCODE,
         ADDCHARGE,
         PRODUCTID,
         CATEGORYID,
         ATM_NAME_LOCATION,
         AUTH_ID,
         AMOUNT,
         PREAUTHAMOUNT,
         PARTIALAMOUNT,
         INSTCODE,
         CUSTOMER_CARD_NO_ENCR,
         TOPUP_CARD_NO_ENCR,
         PROXY_NUMBER,
         REVERSAL_CODE,
         CUSTOMER_ACCT_NO,
         ACCT_BALANCE,
         LEDGER_BALANCE,
         ACHFILENAME,
         RDFI,
         SECCODES,
         IMPDATE,
         PROCESSDATE,
         EFFECTIVEDATE,
         TRACENUMBER,
         INCOMING_CRFILEID,
         ACHTRANTYPE_ID,
         INDIDNUM,
         INDNAME,
         COMPANYNAME,
         COMPANYID,
         ACH_ID,
         COMPENTRYDESC,
         RESPONSE_ID,
         CUSTOMERLASTNAME,
         CARDSTATUS,
         PROCESSTYPE,
         TRANS_DESC,
         CUSTFIRSTNAME,  -- Added by Trivikram on 29/Sep/2012 logging into transactionlog for display Customer Name in ACH Report FSS-418
        MERCHANT_NAME,ERROR_MSG,ach_exception_queue_flag,cr_dr_flag,acct_type,time_stamp ---Added by Shweta on 14Aug13 for MVHOST-367 
        )
       VALUES
        (P_MSG,
         P_RRN,
         P_DELIVERY_CHANNEL,
         P_TERMINALID,
         V_BUSINESS_DATE,
         P_TXN_CODE,
         V_TXN_TYPE,
         P_TXN_MODE,
         DECODE(P_RESP_CODE, '00', 'C', 'F'),
         P_RESP_CODE,
         P_TRANDATE,
         SUBSTR(P_TRANTIME, 1, 10),
         V_HASH_PAN,
         NULL,
         NULL,
         NULL,
         P_INSTCODE,
         TRIM(TO_CHAR(V_TRAN_AMT, '999999999999999990.99')),
         P_CURRCODE,
         NULL,
         V_PROD_CODE,
         V_CARD_TYPE,
         P_TERMINALID,
         P_AUTH_ID,
         TRIM(TO_CHAR(V_TRAN_AMT, '999999999999999990.99')),
         NULL,
         NULL,
         P_INSTCODE,
         V_ENCR_PAN,
         V_ENCR_PAN,
         V_PROXUNUMBER,
         P_RVSL_CODE,
         P_CUST_ACCT_NO,
         V_ACCT_BALANCE,
         V_LEDGER_BALANCE,
         P_ACHFILENAME,
         P_RDFI,
         P_SECCODE,
         P_IMPDATE,
         P_PROCESSDATE,
         P_EFFECTIVEDATE,
         P_TRACENUMBER,
         P_INCOMING_CRFILEID,
         P_ACHTRANTYPE_ID,
                 -- P_INDIDNUM,
                 fn_maskacct_ssn(P_INSTCODE,P_INDIDNUM,0),
         P_INDNAME,
         P_COMPANYNAME,
         P_COMPANYID,
         P_ID,
         P_COMPENTRYDESC,
         V_RESPCODE,
         V_CUSTLASTNAME,
         V_CAP_CARD_STAT,
         P_PROCESSTYPE,
         V_TRANS_DESC,
         V_CUSTFIRSTNAME,  -- Added by Trivikram on 29/Sep/2012 logging into transactionlog for display Customer Name in ACH Report FSS-418
         P_COMPANYNAME,V_ERRMSG,v_ach_exp_flag,V_DR_CR_FLAG,v_cam_type_code,SYSTIMESTAMP ---Added by Shweta on 14Aug13 for MVHOST-367 
         );
     EXCEPTION
       WHEN OTHERS THEN
        --P_RESP_CODE := 'R20'; --Modified by srinivasu on 20 feb 2012 for reponse code changes from 89 to R20
        P_RESP_CODE := 'R16'; 
        P_ERRMSG    := 'Problem while inserting data into transaction log  dtl' ||
                    SUBSTR(SQLERRM, 1, 300);
     END;
     
     -- Added code for log into CMS_ACH_FILEPROCESS table by Trivikram on 23 July 2012
     BEGIN
          SELECT COUNT (*)
            INTO v_file_count
            FROM cms_ach_fileprocess
           WHERE caf_ach_file = p_achfilename AND caf_inst_code = p_instcode;

          IF v_file_count = 0
          THEN
             INSERT INTO cms_ach_fileprocess
                         (caf_inst_code, caf_ach_file, caf_tran_date,
                          caf_lupd_user, caf_ins_user
                         )
                  VALUES (p_instcode, p_achfilename, p_trandate,
                          p_lupduser, p_lupduser
                         );
          END IF;
       EXCEPTION
          WHEN OTHERS
          THEN
             v_errmsg :=
                   'Error while inserting records into ACH File Processing table    '
                || SUBSTR (SQLERRM, 1, 200);
        --v_respcode := 'R20';
        V_RESPCODE := '89'; 
        --P_RESP_CODE := 'R20'; --Added for Response_id on 200912.
        P_RESP_CODE := 'R16'; 
            
           --  RAISE exp_main_reject_record;
       END;
       
        BEGIN        
		
		   IF v_queue_name IS NULL THEN 
              lp_purge_q;
           END IF;   

          SELECT REGEXP_REPLACE(NVL((DECODE( p_companyname ,'','','/'||p_companyname) ||
                DECODE( p_compentrydesc ,'','','/'||p_compentrydesc) ||
                DECODE( p_indname ,'','','/'||p_indidnum||' to '||p_indname)),'Direct Deposit'),'/','',1,1)
          INTO V_MERC_NAME
          FROM dual;
     
     
            
           achaq.enqueue_ach_msgs (ach_type (p_rrn,
                                             p_trandate,
                                             p_trantime,
                                             p_txn_code,
                                             p_delivery_channel,
                                             v_trans_desc,
                                             v_hash_pan,
                                             v_encr_pan,
                                             v_cap_card_stat,
                                             v_tran_amt,
                                             NULL,
                                             SYSDATE,
                                             p_achfilename,
                                             NULL,
                                             'N',
                                             p_auth_id,
                                             p_indname,
                                             v_acct_balance,
                                             v_ledger_balance,
                                             v_respcode,
                                             p_resp_code,
                                             v_merc_name),
                                   NVL (v_queue_name, 'ACH_ACHVIEW_QUEUE'),
                                   v_errmsg);
        IF v_errmsg <> 'OK'
         THEN
            v_errmsg := 'Error in enqueue_ach_msgs1 ACH_ACHVIEW_QUEUE ' || v_errmsg;
            RAISE exp_main_reject_record;
         END IF;
      EXCEPTION
         WHEN exp_main_reject_record THEN
            --RAISE;
            null;
         WHEN OTHERS    THEN
            V_RESPCODE := '21';
            v_errmsg := 'Error while enqueue1 ACH_ACHVIEW_QUEUE ' || SUBSTR (SQLERRM, 1, 200);
            --RAISE exp_main_reject_record;
      END;
       
    END IF;
    --En create a entry in txn log
    BEGIN
     INSERT INTO CMS_TRANSACTION_LOG_DTL
       (CTD_DELIVERY_CHANNEL,
        CTD_TXN_CODE,
        CTD_MSG_TYPE,
        CTD_TXN_MODE,
        CTD_BUSINESS_DATE,
        CTD_BUSINESS_TIME,
        CTD_CUSTOMER_CARD_NO,
        CTD_TXN_AMOUNT,
        CTD_TXN_CURR,
        CTD_ACTUAL_AMOUNT,
        CTD_FEE_AMOUNT,
        CTD_WAIVER_AMOUNT,
        CTD_SERVICETAX_AMOUNT,
        CTD_CESS_AMOUNT,
        CTD_BILL_AMOUNT,
        CTD_BILL_CURR,
        CTD_PROCESS_FLAG,
        CTD_PROCESS_MSG,
        CTD_RRN,
        CTD_INST_CODE,
        CTD_CUSTOMER_CARD_NO_ENCR,
        CTD_CUST_ACCT_NUMBER,
        CTD_TXN_TYPE)
     VALUES
       (P_DELIVERY_CHANNEL,
        P_TXN_CODE,
        P_MSG,
        P_TXN_MODE,
        P_TRANDATE,
        P_TRANTIME,
        --p_card_no
        V_HASH_PAN,
        P_AMOUNT,
        P_CURRCODE,
        P_AMOUNT,
        NULL,
        NULL,
        NULL,
        NULL,
        NULL,
        NULL,
        'E',
        V_ERRMSG,
        P_RRN,
        P_INSTCODE,
        V_ENCR_PAN,
        P_CUST_ACCT_NO,
        V_TXN_TYPE);
    
     RETURN;
    EXCEPTION
     WHEN OTHERS THEN
       P_ERRMSG    := 'Problem while inserting data into transaction log  dtl' ||
                   SUBSTR(SQLERRM, 1, 300);
       --P_RESP_CODE := 'R20'; --Modified by srinivasu on 20 feb 2012 for reponse code changes from 89 to R20
       P_RESP_CODE := 'R16'; 
       ROLLBACK;
       RETURN;
    END;
END;
/
show error;