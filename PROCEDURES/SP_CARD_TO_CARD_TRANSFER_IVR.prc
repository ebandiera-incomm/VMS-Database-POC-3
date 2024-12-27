CREATE OR REPLACE PROCEDURE VMSCMS.SP_CARD_TO_CARD_TRANSFER_IVR (
                                                P_INST_CODE        IN NUMBER,
                                                P_MSG              IN VARCHAR2,
                                                P_RRN              IN VARCHAR2,
                                                P_DELIVERY_CHANNEL IN VARCHAR2,
                                                P_TERM_ID          IN VARCHAR2,
                                                P_TXN_CODE         IN VARCHAR2,
                                                P_TXN_MODE         IN VARCHAR2,
                                                P_TRAN_DATE        IN VARCHAR2,
                                                P_TRAN_TIME        IN VARCHAR2,
                                                P_FROM_CARD_NO     IN VARCHAR2,
                                                P_FROM_CARD_EXPRY  IN VARCHAR2,
                                                P_BANK_CODE        IN VARCHAR2,
                                                P_TXN_AMT          IN NUMBER,
                                                P_MCC_CODE         IN VARCHAR2,
                                                P_CURR_CODE        IN VARCHAR2,
                                                P_TO_CARD_NO       IN VARCHAR2,
                                                P_TO_EXPRY_DATE    IN VARCHAR2,
                                                P_STAN             IN VARCHAR2,
                                                P_LUPD_USER        IN NUMBER,
                                                P_RVSL_CODE        IN VARCHAR2,
                                                P_ANI              IN VARCHAR2,
                                                P_DNI              IN VARCHAR2,
                                                P_IPADDRESS        IN VARCHAR2,
                                                P_ID_TYPE          IN VARCHAR2 ,
                                                P_ID_NUMBER        IN VARCHAR2,
                                                P_MOB_NO           IN VARCHAR2,
                                                P_DEVICE_ID        IN VARCHAR2,
                                                P_CTC_BINFLAG      IN VARCHAR2,
                                                P_RESP_CODE        OUT VARCHAR2,
                                                P_RESP_MSG         OUT VARCHAR2,
                                                P_FEE_AMT          OUT NUMBER,
                                                P_FEE_WAIVER_FLAG  IN  VARCHAR2 DEFAULT 'N'
                                                ) IS
  /********************************************************************************
 
    * Modified By      :  Saravanakumar
    * Modified For     :  To log reason code
    * Modified Date    :  28-SEP-2015
    * Reviewer         :  Pankaj S
    * Build Number     :  VMSGPRHOSTCSD_3.1.1

    * Modified By      :  Narayanaswamy.T
    * Modified For     :  FSS-4118 - C2C transfer transactions must contain masked account number in comment with the from account and to account number
    * Modified Date    :  01-FEB-2016
    * Reviewer         :  Saravanakumar.A
    * Build Number     :  VMSGPRHOST_4.0

        * Modified by       :Siva kumar 
       * Modified Date    : 22-Mar-16
       * Modified For     : MVHOST-1323
       * Reviewer         : Saravanankumar/Pankaj
       * Build Number     : VMSGPRHOSTCSD_4.0_B006

       * Modified by       :Saravanakumar
       * Modified Date    : 25-May-2016
       * Modified For     : FSS-4398
       * Reviewer         : Pankaj
       * Build Number     : VMSGPRHOSTCSD_4.1_B001
       
           * Modified By      : Saravana Kumar A
    * Modified Date    : 07/07/2017
    * Purpose          : Prod code and card type logging in statements log
    * Reviewer         : Pankaj S. 
    * Release Number   : VMSGPRHOST17.07
    
        * Modified By      : Saravana Kumar A
    * Modified Date    : 07/13/2017
    * Purpose          : Currency code getting from prodcat profile
    * Reviewer         : Pankaj S. 
    * Release Number   : VMSGPRHOST17.07
    
    
    
                       * Modified by       : Akhil
     * Modified Date     : 05-JAN-18
     * Modified For      : VMS-103
     * Reviewer          : Saravanakumar A
     * Build Number      : VMSGPRHOST_17.12
     
     * Modified By      : UBAIDUR RAHMAN.H
     * Modified Date    : 25-JAN-2018
     * Purpose          : VMS-162 (encryption changes)
     * Reviewer         : Vini.P
     * Release Number   : VMSGPRHOST18.01
     
     * Modified By      : UBAIDUR RAHMAN.H
     * Modified Date    : 24-SEP-2018
     * Purpose          : VMS-550.
     * Reviewer         : Vini.P
     * Release Number   : VMSGPRHOSTR06
     
	  * Modified by       : BASKAR KRISHNAN
     * Modified Date     : 11-JUL-19
     * Modified For      : VMS-828
     * Reviewer          : Saravanakumar A
     * Build Number      : VMSGPRHOST_R18
     
  *********************************************************************************/

  V_FROM_CARD_EXPRYDATE DATE;
  V_TO_CARD_EXPRYDATE   DATE;
  V_RESP_CDE            transactionlog.response_id%TYPE;
  V_ERR_MSG             transactionlog.error_msg%TYPE;
  V_TXN_TYPE            TRANSACTIONLOG.TXN_TYPE%TYPE;
  V_CURR_CODE           TRANSACTIONLOG.CURRENCYCODE%TYPE;
  V_RESPMSG             transactionlog.error_msg%TYPE;
  V_CAPTURE_DATE        DATE;
  V_AUTHMSG             transactionlog.error_msg%TYPE;
  V_TOACCT_BAL          CMS_ACCT_MAST.CAM_ACCT_BAL%TYPE;
  V_DR_CR_FLAG          VARCHAR2(2);
  V_CTOC_AUTH_ID        TRANSACTIONLOG.AUTH_ID%TYPE;
  V_FROM_PRODCODE       CMS_APPL_PAN.CAP_PROD_CODE%TYPE;
  V_FROM_CARDTYPE       CMS_APPL_PAN.CAP_CARD_TYPE%TYPE;
  V_TRAN_DATE           DATE;
  V_TERMINAL_INDICATOR  PCMS_TERMINAL_MAST.PTM_TERMINAL_INDICATOR%TYPE;
  V_FROM_CARD_CURR      VARCHAR2(5);
  V_TO_CARD_CURR        VARCHAR2(5);
  V_RESP_CONC_MSG       transactionlog.error_msg%TYPE;
  V_HASH_PAN_FROM       CMS_APPL_PAN.CAP_PAN_CODE%TYPE;
  V_ENCR_PAN_FROM       CMS_APPL_PAN.CAP_PAN_CODE_ENCR%TYPE;
  V_HASH_PAN_TO         CMS_APPL_PAN.CAP_PAN_CODE%TYPE;
  V_ENCR_PAN_TO         CMS_APPL_PAN.CAP_PAN_CODE_ENCR%TYPE;
  V_ACCT_BALANCE        CMS_ACCT_MAST.CAM_ACCT_BAL%TYPE;
  V_TOCARDSTAT          CMS_APPL_PAN.cap_card_stat%type;
  V_FROMCARDSTAT        CMS_APPL_PAN.cap_card_stat%type;
  V_FROMCARDEXP         CMS_APPL_PAN.CAP_EXPRY_DATE%TYPE;
  V_TOCARDEXP           CMS_APPL_PAN.CAP_EXPRY_DATE%TYPE;
  V_RRN_COUNT           PLS_INTEGER;
  V_MAX_CARD_BAL        PLS_INTEGER;
  V_ACCT_NUMBER         CMS_APPL_PAN.CAP_ACCT_NO%TYPE;
  V_COUNT               PLS_INTEGER;
  V_LEDGER_BALANCE      CMS_ACCT_MAST.CAM_LEDGER_BAL%TYPE;
  V_NARRATION           CMS_STATEMENTS_LOG.CSL_TRANS_NARRRATION%TYPE;
  V_TOACCT_NO           CMS_ACCT_MAST.CAM_ACCT_NO%TYPE;
  V_FROMACCT_NO         CMS_ACCT_MAST.CAM_ACCT_NO%TYPE;
  V_TOPRODCODE          CMS_APPL_PAN.CAP_PROD_CODE%TYPE;
  V_TOCARDTYPE          CMS_APPL_PAN.CAP_CARD_TYPE%TYPE;
  V_TOACCTNUMBER        CMS_APPL_PAN.CAP_ACCT_NO%TYPE;
  V_STATUS_CHK          PLS_INTEGER;
  V_PRECHECK_FLAG       PCMS_TRANAUTH_PARAM.PTP_PARAM_VALUE%TYPE;
  V_ATMONLINE_LIMIT     CMS_APPL_PAN.CAP_ATM_ONLINE_LIMIT%TYPE;
  V_POSONLINE_LIMIT     CMS_APPL_PAN.CAP_ATM_OFFLINE_LIMIT%TYPE;
  V_OUTPUT_TYPE         cms_transaction_mast.ctm_output_type%type;
  V_TRAN_TYPE           cms_transaction_mast.ctm_tran_type%type;
  v_comb_hash           pkg_limits_check.type_hash;
  V_PRFL_CODE           CMS_APPL_PAN.CAP_PRFL_CODE%type ;
  V_PRFL_FLAG           CMS_TRANSACTION_MAST.CTM_PRFL_FLAG%TYPE ;
  V_TRANS_DESC          CMS_TRANSACTION_MAST.CTM_TRAN_DESC%TYPE; 
  v_from_pan            VARCHAR2(10);
  v_to_pan              VARCHAR2(10);
  V_TOLEDGER_BAL        CMS_ACCT_MAST.CAM_LEDGER_BAL%TYPE;  
  V_FRMACCT_TYPE        CMS_ACCT_MAST.CAM_TYPE_CODE%TYPE;   
  V_TOACCT_TYPE         CMS_ACCT_MAST.CAM_TYPE_CODE%TYPE;   
  V_CUST_CODE           CMS_APPL_PAN.CAP_CUST_CODE%TYPE; 
  v_id_number           CMS_CUST_MAST.CCM_SSN%TYPE;      
  v_mob_mail_flag       VARCHAR2(1);               
  v_email               cms_addr_mast.cam_email%type;  
  v_mobl_one            cms_addr_mast.cam_mobl_one%type;
  V_HASHKEY_ID          CMS_TRANSACTION_LOG_DTL.CTD_HASHKEY_ID%TYPE; 
  V_TIME_STAMP          TIMESTAMP;                                  
  v_enable_flag         VARCHAR2 (20)                          := 'Y';
  v_initialload_amt     cms_acct_mast.cam_new_initialload_amt%type;
  v_profile_code        cms_prod_cattype.cpc_profile_code%type;
  v_badcredit_flag      cms_prod_cattype.cpc_badcredit_flag%TYPE;
  v_badcredit_transgrpid  vms_group_tran_detl.vgd_group_id%TYPE;
  v_cnt                   PLS_INTEGER;
  v_encrypt_enable        CMS_PROD_CATTYPE.cpc_encrypt_enable%TYPE;  
  V_TXN_AMT               cms_statements_log.CSL_TRANS_AMOUNT%TYPE; 
  EXP_REJECT_RECORD       EXCEPTION;
  EXP_AUTH_REJECT_RECORD  EXCEPTION;   
BEGIN
  V_CURR_CODE := P_CURR_CODE;
  V_TXN_TYPE  := '1';
  P_FEE_AMT   :=0;
  V_TIME_STAMP :=SYSTIMESTAMP;
  V_TXN_AMT := ROUND (P_TXN_AMT,2);
  
  BEGIN
    V_HASH_PAN_FROM := GETHASH(P_FROM_CARD_NO);
  EXCEPTION
    WHEN OTHERS THEN
     V_ERR_MSG := 'Error while converting pan ' || SUBSTR(SQLERRM, 1, 200);
     RAISE EXP_REJECT_RECORD;
  END;

  BEGIN
    V_ENCR_PAN_FROM := FN_EMAPS_MAIN(P_FROM_CARD_NO);
  EXCEPTION
    WHEN OTHERS THEN
     V_ERR_MSG := 'Error while converting pan ' || SUBSTR(SQLERRM, 1, 200);
     RAISE EXP_REJECT_RECORD;
  END;

  BEGIN
    V_HASH_PAN_TO := GETHASH(P_TO_CARD_NO);
  EXCEPTION
    WHEN OTHERS THEN
     V_ERR_MSG := 'Error while converting pan ' || SUBSTR(SQLERRM, 1, 200);
     RAISE EXP_REJECT_RECORD;
  END;

  BEGIN
    V_ENCR_PAN_TO := FN_EMAPS_MAIN(P_TO_CARD_NO);
  EXCEPTION
    WHEN OTHERS THEN
     V_ERR_MSG := 'Error while converting pan ' || SUBSTR(SQLERRM, 1, 200);
     RAISE EXP_REJECT_RECORD;
  END;

       BEGIN
           V_HASHKEY_ID := GETHASH (P_DELIVERY_CHANNEL||P_TXN_CODE||P_FROM_CARD_NO||P_RRN||to_char(V_TIME_STAMP,'YYYYMMDDHH24MISSFF5'));
       EXCEPTION
        WHEN OTHERS
        THEN
        P_RESP_CODE := '21';
        V_ERR_MSG :='Error while converting master data ' || SUBSTR (SQLERRM, 1, 200);
        RAISE EXP_REJECT_RECORD;
     END;


    BEGIN
     SELECT CTM_CREDIT_DEBIT_FLAG,
           CTM_OUTPUT_TYPE,
           TO_NUMBER(DECODE(CTM_TRAN_TYPE, 'N', '0', 'F', '1')),
           CTM_TRAN_TYPE,
           CTM_PRFL_FLAG,CTM_TRAN_DESC
       INTO V_DR_CR_FLAG, V_OUTPUT_TYPE, V_TXN_TYPE, V_TRAN_TYPE,
            V_PRFL_FLAG,V_TRANS_DESC 
       FROM CMS_TRANSACTION_MAST
      WHERE CTM_TRAN_CODE = P_TXN_CODE AND
           CTM_DELIVERY_CHANNEL = P_DELIVERY_CHANNEL AND
           CTM_INST_CODE = P_INST_CODE;
    EXCEPTION
     WHEN NO_DATA_FOUND THEN
       V_RESP_CDE := '12'; 
       V_ERR_MSG  := 'Transflag  not defined for txn code ' ||
                  P_TXN_CODE || ' and delivery channel ' ||
                  P_DELIVERY_CHANNEL;
       RAISE EXP_REJECT_RECORD;
     WHEN OTHERS THEN
       V_RESP_CDE := '21'; 
       V_ERR_MSG  := 'Error while selecting transaction details';
       RAISE EXP_REJECT_RECORD;
    END;


  IF P_CTC_BINFLAG = 'N' 
  AND( LENGTH (P_FROM_CARD_NO) > 10) 
  AND ( LENGTH (P_TO_CARD_NO) > 10) 
  THEN

      v_from_pan := SUBSTR (P_FROM_CARD_NO, 1, 6);
      v_to_pan := SUBSTR (P_TO_CARD_NO, 1, 6);

       if v_from_pan <> v_to_pan then
         V_RESP_CDE := '140';
         V_ERR_MSG  := 'Both the card number should be in same BIN';
       RAISE EXP_REJECT_RECORD;
       end if;

    END IF; 

  BEGIN
    SELECT COUNT(1)
     INTO V_RRN_COUNT
     FROM TRANSACTIONLOG
    WHERE RRN = P_RRN AND BUSINESS_DATE = P_TRAN_DATE AND
         DELIVERY_CHANNEL = P_DELIVERY_CHANNEL; 

    IF V_RRN_COUNT > 0 THEN
     V_RESP_CDE := '22';
     V_ERR_MSG  := 'Duplicate RRN on ' || P_TRAN_DATE;
     RAISE EXP_REJECT_RECORD;
    END IF;
  EXCEPTION
    WHEN EXP_REJECT_RECORD THEN
     RAISE;
    WHEN OTHERS THEN
       V_RESP_CDE := '21';
       V_ERR_MSG  := 'Error while checking  duplicate RRN-'|| SUBSTR(SQLERRM, 1, 200);
       RAISE EXP_REJECT_RECORD;
  END;

  BEGIN
    V_TRAN_DATE := TO_DATE(SUBSTR(TRIM(P_TRAN_DATE), 1, 8) || ' ' ||
                      SUBSTR(TRIM(P_TRAN_TIME), 1, 8),
                      'yyyymmdd hh24:mi:ss');
  EXCEPTION
    WHEN OTHERS THEN
     V_RESP_CDE := '21';
     V_ERR_MSG  := 'Problem while converting transaction date ' ||
                SUBSTR(SQLERRM, 1, 200);
     RAISE EXP_REJECT_RECORD;
  END;

  BEGIN
    IF TRIM(P_FROM_CARD_EXPRY) IS NOT NULL THEN
     V_FROM_CARD_EXPRYDATE := LAST_DAY(TO_DATE('01' || P_FROM_CARD_EXPRY ||' 23:59:59','ddyymm hh24:mi:ss'));
    END IF;
  EXCEPTION
    WHEN OTHERS THEN
     V_ERR_MSG  := 'Problem while converting from card expry date ' ||
                SUBSTR(SQLERRM, 1, 300);
     V_RESP_CDE := '22'; 
     RAISE EXP_REJECT_RECORD;
  END;

  BEGIN
    IF TRIM(P_TO_EXPRY_DATE) IS NOT NULL THEN
     V_TO_CARD_EXPRYDATE := LAST_DAY(TO_DATE('01' || P_TO_EXPRY_DATE ||
                                     ' 23:59:59',
                                     'ddyymm hh24:mi:ss'));
    END IF;
  EXCEPTION
    WHEN OTHERS THEN
     V_ERR_MSG  := 'Problem while converting to card expry date ' ||
                SUBSTR(SQLERRM, 1, 300);
     V_RESP_CDE := '22'; 
     RAISE EXP_REJECT_RECORD;
  END;


  BEGIN
    SELECT CAP_CARD_STAT, CAP_EXPRY_DATE,
          CAP_PROD_CODE,CAP_CARD_TYPE, CAP_ACCT_NO,CAP_CUST_CODE
     INTO V_FROMCARDSTAT, V_FROMCARDEXP,
         V_FROM_PRODCODE,V_FROM_CARDTYPE, V_ACCT_NUMBER,V_CUST_CODE 
     FROM CMS_APPL_PAN
    WHERE CAP_INST_CODE = P_INST_CODE AND CAP_PAN_CODE = V_HASH_PAN_FROM;
  EXCEPTION
    WHEN NO_DATA_FOUND THEN
     V_RESP_CDE := '16'; 
     V_ERR_MSG  := 'Card number not found ' || V_HASH_PAN_FROM;
     RAISE EXP_REJECT_RECORD;
    WHEN OTHERS THEN
     V_RESP_CDE := '12';
     V_ERR_MSG  := 'Problem while selecting card detail' ||
                SUBSTR(SQLERRM, 1, 200);
     RAISE EXP_REJECT_RECORD;
  END;


  BEGIN

      vmsfunutilities.get_currency_code(V_FROM_PRODCODE,V_FROM_CARDTYPE,P_INST_CODE,V_FROM_CARD_CURR,V_ERR_MSG);
      
      if V_ERR_MSG<>'OK' then
           raise EXP_REJECT_RECORD;
      end if;

    IF V_FROM_CARD_CURR IS NULL THEN
     V_RESP_CDE := '21';
     V_ERR_MSG  := 'From Card currency cannot be null ';
     RAISE EXP_REJECT_RECORD;
    END IF;

  EXCEPTION
    WHEN EXP_REJECT_RECORD THEN
      RAISE;
    WHEN NO_DATA_FOUND THEN
     V_ERR_MSG  := 'card currency is not defined for the from card ';
     V_RESP_CDE := '21';
     RAISE EXP_REJECT_RECORD;
    WHEN OTHERS THEN
     V_ERR_MSG  := 'Error while selecting card currecy  ' ||
                SUBSTR(SQLERRM, 1, 200);
     V_RESP_CDE := '21';
     RAISE EXP_REJECT_RECORD;
  END;

  BEGIN
    SELECT CAP_CARD_STAT, CAP_EXPRY_DATE, CAP_PROD_CODE, CAP_CARD_TYPE, CAP_ACCT_NO,
           CAP_ATM_ONLINE_LIMIT,CAP_POS_ONLINE_LIMIT
     INTO V_TOCARDSTAT, V_TOCARDEXP, V_TOPRODCODE, V_TOCARDTYPE, V_TOACCTNUMBER,
     V_ATMONLINE_LIMIT,V_POSONLINE_LIMIT
     FROM CMS_APPL_PAN
    WHERE CAP_INST_CODE = P_INST_CODE AND CAP_PAN_CODE = V_HASH_PAN_TO;
  EXCEPTION
    WHEN NO_DATA_FOUND THEN
     V_RESP_CDE := '16'; 
     V_ERR_MSG  := 'Card number not found ' || V_HASH_PAN_TO;
     RAISE EXP_REJECT_RECORD;
    WHEN OTHERS THEN
     V_RESP_CDE := '12';
     V_ERR_MSG  := 'Problem while selecting card detail' ||
                SUBSTR(SQLERRM, 1, 200);
     RAISE EXP_REJECT_RECORD;
  END;
  
    BEGIN
           SELECT cpc_profile_code,cpc_badcredit_flag,cpc_badcredit_transgrpid,cpc_encrypt_enable
             into v_profile_code,v_badcredit_flag,v_badcredit_transgrpid,v_encrypt_enable
           FROM cms_prod_cattype
           WHERE CPC_INST_CODE = P_INST_CODE
            and   cpc_prod_code = v_toprodcode
            and   cpc_card_type = v_tocardtype;
          exception
              when others then
                   V_ERR_MSG  := 'Error while getting details from prod cattype';
            V_RESP_CDE := '21';
            RAISE EXP_REJECT_RECORD;
  END;


   IF V_HASH_PAN_TO = V_HASH_PAN_FROM THEN
    V_RESP_CDE := '91';
    V_ERR_MSG  := 'FROM AND TO CARD NUMBERS SHOULD NOT BE SAME';
    RAISE EXP_REJECT_RECORD;
  END IF;

    BEGIN
     SELECT PTP_PARAM_VALUE
       INTO V_PRECHECK_FLAG
       FROM PCMS_TRANAUTH_PARAM
      WHERE PTP_PARAM_NAME = 'PRE CHECK' AND PTP_INST_CODE = P_INST_CODE;
    EXCEPTION
     WHEN NO_DATA_FOUND THEN
       V_RESP_CDE := '21'; 
       V_ERR_MSG  := 'Master set up is not done for Authorization Process';
       RAISE EXP_REJECT_RECORD;
     WHEN OTHERS THEN
       V_RESP_CDE := '21'; 
       V_ERR_MSG  := 'Error while selecting precheck flag' ||
                  SUBSTR(SQLERRM, 1, 200);
       RAISE EXP_REJECT_RECORD;
    END;


  BEGIN

      vmsfunutilities.get_currency_code(V_TOPRODCODE,V_TOCARDTYPE,P_INST_CODE,V_TO_CARD_CURR,V_ERR_MSG);
      
      if V_ERR_MSG<>'OK' then
           raise EXP_REJECT_RECORD;
      end if;

    IF V_TO_CARD_CURR IS NULL THEN
     V_RESP_CDE := '21';
     V_ERR_MSG  := 'To Card currency cannot be null ';
     RAISE EXP_REJECT_RECORD;
    END IF;

  EXCEPTION
    WHEN EXP_REJECT_RECORD THEN
      RAISE;
     V_ERR_MSG  := 'Error while selecting card currecy  ' ||
                SUBSTR(SQLERRM, 1, 200);
     V_RESP_CDE := '21';
     RAISE EXP_REJECT_RECORD;
  END;


  IF V_TO_CARD_CURR <> V_FROM_CARD_CURR THEN
    V_ERR_MSG  := 'Both from card currency and to card currency are not same  ' ||
               SUBSTR(SQLERRM, 1, 200);
    V_RESP_CDE := '21';
    RAISE EXP_REJECT_RECORD;
  END IF;

  IF V_CURR_CODE <> V_FROM_CARD_CURR THEN
    V_ERR_MSG  := 'Both from card currency and txn currency are not same  ' ||
               SUBSTR(SQLERRM, 1, 200);
    V_RESP_CDE := '21';
    RAISE EXP_REJECT_RECORD;
  END IF;

  IF P_TXN_CODE NOT IN ('56', '07','13','39')
   THEN
    V_ERR_MSG  := 'Not a valid transaction code for ' ||
               ' card to card transfer';
    V_RESP_CDE := '21'; 
    RAISE EXP_REJECT_RECORD;
  END IF;

if V_FROM_CARD_CURR <>'124' then 
    BEGIN
       SELECT 
             nvl(fn_dmaps_main(ccm_ssn_encr),ccm_ssn) 
         INTO v_id_number
         FROM cms_cust_mast
        WHERE ccm_inst_code = p_inst_code AND ccm_cust_code = v_cust_code
        and NVL(ccm_id_type,'SSN')=p_id_type;
    EXCEPTION
       WHEN NO_DATA_FOUND
       THEN
         v_resp_cde := '195';
        v_err_msg := 'Invalid ID type';
        RAISE exp_reject_record;

       WHEN OTHERS
       THEN
          v_resp_cde := '21';
          v_err_msg := 'Problem while selecting id number--' || SUBSTR (SQLERRM, 1, 200);
          RAISE exp_reject_record;
    END;

    IF nvl(p_id_number,'*') <> nvl(v_id_number,'*') then
        v_resp_cde := '195';
        v_err_msg := 'Invalid ID Number';
        RAISE exp_reject_record;

    END IF;

end if; 

    BEGIN
       SELECT decode(v_encrypt_enable,'Y',fn_dmaps_main(cam_email),cam_email),
              decode(v_encrypt_enable,'Y',fn_dmaps_main(cam_mobl_one),cam_mobl_one) 
         INTO v_email, v_mobl_one
         FROM cms_addr_mast
        WHERE cam_inst_code = p_inst_code
          AND cam_cust_code = v_cust_code
          AND cam_addr_flag = 'P';
    EXCEPTION
       WHEN NO_DATA_FOUND
       THEN
          v_resp_cde := '21';
          v_err_msg :=
                      'Permanent  Address Not Defined for Customer=' || v_cust_code;
          RAISE exp_reject_record;
       WHEN OTHERS
       THEN
          v_resp_cde := '21';
          v_err_msg :=
             'Problem while selecting mobile/email--' || SUBSTR (SQLERRM, 1, 200);
          RAISE exp_reject_record;
    END;


    IF (v_email is null) and (v_mobl_one is null)  THEN
      v_resp_cde := '201';
      v_err_msg  :='Mobile and Email not configured.';
      RAISE exp_reject_record;
    ELSIF v_email is null then
      v_resp_cde := '202';
      v_err_msg  :='Email not configured.';
      RAISE exp_reject_record;
    ELSIF v_mobl_one is null then
      v_resp_cde := '203';
      v_err_msg  :='Mobile not configured.';
      RAISE exp_reject_record;
    END IF;

 

    BEGIN
       SELECT CASE
                 WHEN cme_chng_date > (SYSDATE - 1)
                    THEN 'Y'
                 ELSE 'N'
              END
         INTO v_mob_mail_flag
         FROM cms_mob_email_log
        WHERE cme_inst_code = p_inst_code AND cme_cust_code = v_cust_code;
    EXCEPTION
       WHEN NO_DATA_FOUND
       THEN
          v_mob_mail_flag := 'N';
       WHEN OTHERS
       THEN
          v_resp_cde := '21';
          v_err_msg :=
                'Problem while selecting flag from cms_mob_email_log-'
             || SUBSTR (SQLERRM, 1, 200);
          RAISE exp_reject_record;
    END;

    IF v_mob_mail_flag = 'Y' THEN

      v_resp_cde := '197';
      v_err_msg :='Mobile/Email address has been updated within last 24 hrs.';
      RAISE exp_reject_record;

    END IF;
 

  BEGIN
    SELECT CAM_ACCT_BAL
     INTO V_ACCT_BALANCE
     FROM CMS_ACCT_MAST
    WHERE CAM_INST_CODE = P_INST_CODE AND
         CAM_ACCT_NO =  V_ACCT_NUMBER
       FOR UPDATE NOWAIT;

  EXCEPTION
    WHEN NO_DATA_FOUND THEN
     V_RESP_CDE := '17'; 
     V_ERR_MSG  := 'Invalid Account ';
     RAISE EXP_REJECT_RECORD;
    WHEN OTHERS THEN
     V_RESP_CDE := '21';
     V_ERR_MSG  := 'Error while selecting data from card Master for card number ' ||
                P_TO_CARD_NO || SUBSTR(SQLERRM, 1, 200);
     RAISE EXP_REJECT_RECORD;
  END;



  IF V_ACCT_BALANCE < V_TXN_AMT THEN
    V_RESP_CDE := '15'; 
    V_ERR_MSG  := 'Insufficient Fund ';
    RAISE EXP_REJECT_RECORD;
  END IF;
  IF V_TXN_AMT = 0 THEN
    V_RESP_CDE := '25'; 
    V_ERR_MSG  := 'INVALID AMOUNT ';
    RAISE EXP_REJECT_RECORD;
  END IF;


  BEGIN
    SELECT CAM_ACCT_BAL, CAM_ACCT_NO,CAM_LEDGER_BAL,
           CAM_TYPE_CODE,   nvl(cam_new_initialload_amt,cam_initialload_amt)
     INTO V_TOACCT_BAL, V_TOACCT_NO,V_TOLEDGER_BAL, 
          V_TOACCT_TYPE,v_initialload_amt
     FROM CMS_ACCT_MAST
    WHERE CAM_INST_CODE = P_INST_CODE AND
         CAM_ACCT_NO =  V_TOACCTNUMBER;
  EXCEPTION
    WHEN NO_DATA_FOUND THEN
     V_RESP_CDE := '26'; 
     V_RESPMSG  := 'Account number not found ' || P_TO_CARD_NO;
     RAISE EXP_REJECT_RECORD;
    WHEN OTHERS THEN
     V_RESP_CDE := '21';
     V_RESPMSG  := 'Problem while selecting acct balance ' ||
                SUBSTR(SQLERRM, 1, 200);
     RAISE EXP_REJECT_RECORD;
  END;

  V_FROMACCT_NO:=V_ACCT_NUMBER;

  BEGIN                                 
       SP_STATUS_CHECK_GPR( P_INST_CODE,
                            P_TO_CARD_NO,
                            P_DELIVERY_CHANNEL,
                            V_TOCARDEXP,
                            V_TOCARDSTAT,
                            P_TXN_CODE,
                            P_TXN_MODE,
                            V_TOPRODCODE,
                            V_TOCARDTYPE,
                            P_MSG,
                            P_TRAN_DATE,
                            P_TRAN_TIME,
                            NULL,  
                            NULL,
                            P_MCC_CODE,
                            V_RESP_CDE,
                            V_ERR_MSG
                           );

       IF ((V_RESP_CDE <> '1' AND V_ERR_MSG <> 'OK') OR (V_RESP_CDE <> '0' AND V_ERR_MSG <> 'OK')) THEN

         V_ERR_MSG := 'For TO CARD -- '||V_ERR_MSG; 
         RAISE EXP_REJECT_RECORD;
       ELSE
            V_STATUS_CHK:=V_RESP_CDE;
            V_RESP_CDE:='1';
       END IF;

  EXCEPTION
  WHEN EXP_REJECT_RECORD THEN
   RAISE;
  WHEN OTHERS THEN
    V_RESP_CDE := '21';
    V_ERR_MSG  := 'Error from GPR Card Status Check for TO CARD' ||SUBSTR(SQLERRM, 1, 200);
  RAISE EXP_REJECT_RECORD;
  END;

  IF V_STATUS_CHK='1' THEN

     IF P_DELIVERY_CHANNEL <> '11' THEN

         BEGIN

               IF TO_DATE(P_TRAN_DATE, 'YYYYMMDD') >
                 LAST_DAY(TO_CHAR(V_TOCARDEXP, 'DD-MON-YY')) THEN

                V_RESP_CDE := '13';
                V_ERR_MSG  := 'TO CARD IS EXPIRED'; 
                RAISE EXP_REJECT_RECORD;

               END IF;

         EXCEPTION

           WHEN EXP_REJECT_RECORD THEN
            RAISE;

           WHEN OTHERS THEN
            V_RESP_CDE := '21';
            V_ERR_MSG  := 'ERROR IN EXPIRY DATE CHECK FOR TO CARD: Tran Date - ' ||
                        P_TRAN_DATE || ', Expiry Date - ' || V_TOCARDEXP || ',' ||
                        SUBSTR(SQLERRM, 1, 200);
            RAISE EXP_REJECT_RECORD;

         END;

    END IF;

        IF V_PRECHECK_FLAG = 1 THEN

             BEGIN
               SP_PRECHECK_TXN( P_INST_CODE,
                                P_TO_CARD_NO,
                                P_DELIVERY_CHANNEL,
                                V_TOCARDEXP,
                                V_TOCARDSTAT,
                                P_TXN_CODE,
                                P_TXN_MODE,
                                P_TRAN_DATE,
                                P_TRAN_TIME,
                                V_TXN_AMT,
                                V_ATMONLINE_LIMIT,
                                V_POSONLINE_LIMIT,
                                V_RESP_CDE,
                                V_ERR_MSG
                               );

               IF (V_RESP_CDE <> '1' OR V_ERR_MSG <> 'OK') THEN

                V_ERR_MSG := 'For TO CARD -- '||V_ERR_MSG; 
                RAISE EXP_REJECT_RECORD;
               END IF;

             EXCEPTION
               WHEN EXP_REJECT_RECORD THEN
                RAISE;
               WHEN OTHERS THEN
                V_RESP_CDE := '21';
                V_ERR_MSG  := 'Error from precheck processes for TO CARD' ||SUBSTR(SQLERRM, 1, 200); 
                RAISE EXP_REJECT_RECORD;
             END;

        END IF;

  END IF;  

   BEGIN
    SP_AUTHORIZE_TXN_CMS_AUTH(P_INST_CODE,
                        P_MSG,
                        P_RRN,
                        P_DELIVERY_CHANNEL,
                        P_TERM_ID,
                        P_TXN_CODE,
                        P_TXN_MODE,
                        P_TRAN_DATE,
                        P_TRAN_TIME,
                        P_FROM_CARD_NO,
                        P_BANK_CODE,
                        V_TXN_AMT,
                        NULL,
                        NULL,
                        P_MCC_CODE,
                        P_CURR_CODE,
                        NULL,
                        NULL,
                        NULL,
                        V_TOACCT_NO,
                        NULL,
                        NULL,
                        NULL,
                        NULL,
                        NULL,
                        NULL,
                        NULL,
                        NULL,
                        P_FROM_CARD_EXPRY,
                        P_STAN,
                        '000',
                        P_RVSL_CODE,
                        V_TXN_AMT,
                        V_CTOC_AUTH_ID,
                        V_RESP_CDE,
                        V_RESPMSG,
                        V_CAPTURE_DATE,
                        CASE WHEN P_FEE_WAIVER_FLAG='N' THEN
                            'Y'
                            WHEN P_FEE_WAIVER_FLAG='Y' THEN
                            'N' END);
    IF V_RESP_CDE <> '00' AND V_RESPMSG <> 'OK' THEN
     V_AUTHMSG := V_RESPMSG;
     RAISE EXP_AUTH_REJECT_RECORD;
    END IF;
  EXCEPTION
    WHEN EXP_AUTH_REJECT_RECORD THEN
     RAISE;

    WHEN EXP_REJECT_RECORD THEN
     RAISE;
    WHEN OTHERS THEN
     V_RESP_CDE := '21';
     V_ERR_MSG  := 'Error from Card authorization' ||
                SUBSTR(SQLERRM, 1, 200);
     RAISE EXP_REJECT_RECORD;
  END;

   BEGIN
      IF v_prfl_flag = 'Y'
      THEN
         pkg_limits_check.sp_limits_check (NULL,
                                           V_HASH_PAN_FROM,   
                                           V_HASH_PAN_TO,     
                                           NULL,                
                                           P_TXN_CODE,
                                           V_TRAN_TYPE,
                                           NULL,        
                                           NULL,
                                           P_INST_CODE,
                                           NULL,
                                           v_prfl_code,
                                           V_TXN_AMT,                 
                                           P_DELIVERY_CHANNEL,
                                           v_comb_hash,
                                           V_RESP_CDE,
                                           V_ERR_MSG
                                          );

      END IF;

      IF V_RESP_CDE <> '00' AND V_ERR_MSG <> 'OK'
      THEN
         V_ERR_MSG := 'Error from Limit Check Process ' || V_ERR_MSG;
         RAISE EXP_REJECT_RECORD;
      END IF;
   EXCEPTION
      WHEN EXP_REJECT_RECORD
      THEN
         RAISE;
      WHEN OTHERS
      THEN
         V_RESP_CDE := '21';
         V_ERR_MSG :=
                'Error from Limit Check Process ' || SUBSTR (SQLERRM, 1, 200);
         RAISE EXP_REJECT_RECORD;
   END;

   BEGIN

      SELECT TO_NUMBER(CBP_PARAM_VALUE)       
      INTO V_MAX_CARD_BAL
      FROM CMS_BIN_PARAM
      WHERE CBP_INST_CODE = P_INST_CODE 
	  AND CBP_PARAM_NAME = 'Max Card Balance' 
	  AND CBP_PROFILE_CODE=v_profile_code;

  EXCEPTION
    WHEN OTHERS THEN
     V_RESP_CDE := '21';
     V_ERR_MSG  := 'ERROR IN FETCHING CARD BALANCE CONFIGURATION FOR THE PRODUCT PROFILE ' ||
                SUBSTR(SQLERRM, 1, 200);
     RAISE EXP_REJECT_RECORD;
  END;
IF v_badcredit_flag = 'Y'
         THEN
            EXECUTE IMMEDIATE    'SELECT  count(*) 
              FROM vms_group_tran_detl
              WHERE vgd_group_id ='
                              || v_badcredit_transgrpid
                              || '
              AND vgd_tran_detl LIKE 
              (''%'
                              || p_delivery_channel
                              || ':'
                              || p_txn_code
                              || '%'')'
                         INTO v_cnt;
            IF v_cnt = 1
            THEN
               v_enable_flag := 'N';
               IF    ((V_TOACCT_BAL) > v_initialload_amt
                     )                                     --initialloadamount
                  OR ((V_TOACCT_BAL + V_TXN_AMT) > v_initialload_amt
                     )
               THEN                                        --initialloadamount
                  UPDATE cms_appl_pan
                     SET cap_card_stat = '18'
                   WHERE cap_inst_code = p_inst_code
                     AND cap_pan_code = V_HASH_PAN_TO;
                 BEGIN
         sp_log_cardstat_chnge (p_inst_code,
                                V_HASH_PAN_TO,
                                v_encr_pan_to,
                                V_CTOC_AUTH_ID,
                                '10',
                                p_rrn,
                                p_tran_date,
                                p_tran_time,
                                v_resp_cde,
                                v_err_msg
                               );
         IF v_resp_cde <> '00' AND v_err_msg <> 'OK'
         THEN
            RAISE exp_reject_record;
         END IF;
      EXCEPTION
         WHEN exp_reject_record
         THEN
            RAISE;
         WHEN OTHERS
         THEN
            v_resp_cde := '21';
            v_err_msg :=
                  'Error while logging system initiated card status change '
               || SUBSTR (SQLERRM, 1, 200);
            RAISE exp_reject_record;
      END;
               END IF;
            END IF;
         END IF;
         IF v_enable_flag = 'Y'
         AND (((V_TOACCT_BAL) > v_max_card_bal)
               OR ((V_TOACCT_BAL + V_TXN_AMT) > v_max_card_bal))
         THEN
                V_RESP_CDE := '30';
                v_err_msg := 'EXCEEDING MAXIMUM CARD BALANCE';
			  RAISE EXP_REJECT_RECORD;
         END IF;


  BEGIN
    UPDATE CMS_ACCT_MAST
      SET CAM_ACCT_BAL   = CAM_ACCT_BAL + V_TXN_AMT,
         CAM_LEDGER_BAL = CAM_LEDGER_BAL + V_TXN_AMT
    WHERE CAM_INST_CODE = P_INST_CODE AND
         CAM_ACCT_NO =V_TOACCTNUMBER;

    IF SQL%ROWCOUNT = 0 THEN
     V_RESP_CDE := '21';
     V_RESPMSG  := 'Error while updating amount in to acct no ';
     RAISE EXP_REJECT_RECORD;
    END IF;

  EXCEPTION
    WHEN OTHERS THEN
     V_RESP_CDE := '21';
     V_RESPMSG  := 'Error while amount in to acct no ' ||
                SUBSTR(SQLERRM, 1, 200);
     RAISE EXP_REJECT_RECORD;
  END;

  BEGIN

    IF TRIM(V_TRANS_DESC) IS NOT NULL THEN

     V_NARRATION := V_TRANS_DESC || '/';

    END IF;

    IF TRIM(V_CTOC_AUTH_ID) IS NOT NULL THEN

     V_NARRATION := V_NARRATION || V_CTOC_AUTH_ID || '/';

    END IF;

    IF TRIM(V_FROMACCT_NO) IS NOT NULL THEN

     V_NARRATION := V_NARRATION || V_FROMACCT_NO || '/';

    END IF;

    IF TRIM(P_TRAN_DATE) IS NOT NULL THEN

     V_NARRATION := V_NARRATION || P_TRAN_DATE;

    END IF;

  EXCEPTION
    WHEN OTHERS THEN

     V_RESP_CDE := '21';
     V_ERR_MSG  := 'Error in finding the narration ' ||
                SUBSTR(SQLERRM, 1, 200);
     RAISE EXP_REJECT_RECORD;

  END;

  BEGIN
              UPDATE CMS_TRANSACTION_LOG_DTL
              SET
              CTD_MOBILE_NUMBER=P_MOB_NO,
              CTD_DEVICE_ID=P_DEVICE_ID,
              CTD_HASHKEY_ID=V_HASHKEY_ID
              WHERE CTD_RRN=P_RRN AND CTD_BUSINESS_DATE=P_TRAN_DATE
              AND CTD_BUSINESS_TIME=P_TRAN_TIME
              AND CTD_DELIVERY_CHANNEL=P_DELIVERY_CHANNEL
              AND CTD_TXN_CODE=P_TXN_CODE
              AND CTD_MSG_TYPE=P_MSG
              AND CTD_INST_CODE=P_INST_CODE;

             IF SQL%ROWCOUNT = 0 THEN
                V_RESPMSG  := 'ERROR WHILE UPDATING CMS_TRANSACTION_LOG_DTL ';
                P_RESP_CODE := '21';
              RAISE EXP_REJECT_RECORD;
             END IF;
             EXCEPTION
             WHEN EXP_REJECT_RECORD THEN
             RAISE EXP_REJECT_RECORD;
             WHEN OTHERS THEN
                P_RESP_CODE := '21';
                V_RESPMSG  := 'Problem on updated cms_Transaction_log_dtl ' ||
                SUBSTR(SQLERRM, 1, 200);
               RAISE EXP_REJECT_RECORD;
            END;

  BEGIN
    V_DR_CR_FLAG := 'CR';

 
    INSERT INTO CMS_STATEMENTS_LOG
     (CSL_PAN_NO,
      CSL_OPENING_BAL,
      CSL_TRANS_AMOUNT,
      CSL_TRANS_TYPE,
      CSL_TRANS_DATE,
      CSL_CLOSING_BALANCE,
      CSL_TRANS_NARRRATION,
      CSL_PAN_NO_ENCR,
      CSL_RRN,
      CSL_AUTH_ID,
      CSL_BUSINESS_DATE,
      CSL_BUSINESS_TIME,
      TXN_FEE_FLAG,
      CSL_DELIVERY_CHANNEL,
      CSL_INST_CODE,
      CSL_TXN_CODE,
      CSL_ACCT_NO, 
      CSL_INS_USER,
      CSL_INS_DATE,
      CSL_PANNO_LAST4DIGIT,     
      CSL_ACCT_TYPE,            
      CSL_TIME_STAMP,           
      CSL_PROD_CODE,csl_card_type             
      )
    VALUES
     (V_HASH_PAN_TO,
      V_TOLEDGER_BAL,      
      V_TXN_AMT,
      'CR',
      V_TRAN_DATE,
      DECODE(V_DR_CR_FLAG,
            'DR',
            V_TOLEDGER_BAL - V_TXN_AMT,      
            'CR',
            V_TOLEDGER_BAL + V_TXN_AMT,      
            'NA',
            V_TOLEDGER_BAL),                  
      V_NARRATION,
      V_ENCR_PAN_TO,
      P_RRN,
      V_CTOC_AUTH_ID,
      P_TRAN_DATE,
      P_TRAN_TIME,
      'N',
      P_DELIVERY_CHANNEL,
      P_INST_CODE,
      P_TXN_CODE,
      V_TOACCT_NO, 
      1,
      SYSDATE,
      (substr(P_TO_CARD_NO, length(P_TO_CARD_NO) -3,length(P_TO_CARD_NO))),  
      v_toacct_type,    
      v_time_stamp,       
      V_TOPRODCODE,v_tocardtype        
      );
  EXCEPTION
    WHEN OTHERS THEN
     V_RESP_CDE := '21';
     V_ERR_MSG  := 'Error creating entry in statement log ';
     RAISE EXP_REJECT_RECORD;

  END;


        Begin

          update cms_statements_log
          set csl_time_stamp = v_time_stamp 
          where csl_pan_no = v_hash_pan_from
          and   csl_rrn = p_rrn
          and   csl_delivery_channel=p_delivery_channel
          and   csl_txn_code = p_txn_code
          and   csl_business_date = p_tran_date
          and   csl_business_time = p_tran_time;

          if sql%rowcount = 0
          then

             V_RESP_CDE := '21';
             V_ERR_MSG  := 'Timestamp not updated in statement log';
             RAISE EXP_REJECT_RECORD;

          end if;

        exception when EXP_REJECT_RECORD
        then
            raise;
        when others
        then

             V_RESP_CDE := '21';
             V_ERR_MSG  := 'Error while updating timestamp in statement log '||substr(sqlerrm,1,100);
             RAISE EXP_REJECT_RECORD;
        end;

  BEGIN

    UPDATE TRANSACTIONLOG
      SET TOPUP_CARD_NO     = V_HASH_PAN_TO,
         TOPUP_CARD_NO_ENCR = V_ENCR_PAN_TO,
         TOPUP_ACCT_NO      =    V_TOACCTNUMBER,
           topup_acct_balance  = V_TOACCT_BAL+V_TXN_AMT,
          topup_ledger_balance =V_TOLEDGER_BAL+V_TXN_AMT,
          TOPUP_ACCT_TYPE     = V_TOACCT_TYPE,                  
         TIME_STAMP           = v_time_stamp         
    WHERE RRN = P_RRN AND DELIVERY_CHANNEL = P_DELIVERY_CHANNEL AND
         TXN_CODE = P_TXN_CODE AND BUSINESS_DATE = P_TRAN_DATE AND
         BUSINESS_TIME = P_TRAN_TIME AND
         CUSTOMER_CARD_NO = V_HASH_PAN_FROM;

    IF SQL%ROWCOUNT <> 1 THEN
     V_RESP_CDE := '21';
     V_ERR_MSG  := 'Error while updating transactionlog ' ||
                'no valid records ';
     RAISE EXP_REJECT_RECORD;
    END IF;

  EXCEPTION
    WHEN EXP_REJECT_RECORD THEN
     RAISE;
    WHEN OTHERS THEN
     V_RESP_CDE := '21';
     V_ERR_MSG  := 'Error while updating transactionlog ' ||
                SUBSTR(SQLERRM, 1, 200);
     RAISE EXP_REJECT_RECORD;

  END;
  BEGIN
    UPDATE TRANSACTIONLOG
      SET ANI = P_ANI, DNI = P_DNI, IPADDRESS = P_IPADDRESS,
    REMARK  = 'From Account No : ' || FN_MASK_ACCT(V_FROMACCT_NO) || ' ' ||
                   'To Account No : ' || FN_MASK_ACCT(V_TOACCTNUMBER)
    WHERE RRN = P_RRN AND BUSINESS_DATE = P_TRAN_DATE AND
         TXN_CODE = P_TXN_CODE AND MSGTYPE = P_MSG AND
         BUSINESS_TIME = P_TRAN_TIME AND
         DELIVERY_CHANNEL = P_DELIVERY_CHANNEL;

          IF SQL%ROWCOUNT <> 1 THEN
         V_RESP_CDE := '21';
         V_ERR_MSG  := 'Error while updating transactionlog ' ||
                'no valid records ';
          RAISE EXP_REJECT_RECORD;
          END IF;

  EXCEPTION
    WHEN EXP_REJECT_RECORD THEN
     RAISE;
    WHEN OTHERS THEN
     V_RESP_CDE := '69';
     V_ERR_MSG  := 'Problem while inserting data into transaction log  dtl' ||
                SUBSTR(SQLERRM, 1, 300);
      RAISE EXP_REJECT_RECORD;
  END;

  IF P_TXN_CODE NOT IN ('07','13','39') THEN 

    BEGIN
     SELECT PTM_TERMINAL_INDICATOR
       INTO V_TERMINAL_INDICATOR
       FROM PCMS_TERMINAL_MAST
      WHERE PTM_TERMINAL_ID = P_TERM_ID AND PTM_INST_CODE = P_INST_CODE;
    EXCEPTION
     WHEN NO_DATA_FOUND THEN
       V_RESP_CDE := '21';
       V_ERR_MSG  := 'Terminal indicator is not declared for terminal id' ||
                  P_TERM_ID;
       RAISE EXP_REJECT_RECORD;

     WHEN OTHERS THEN
       V_RESP_CDE := '21';
       V_ERR_MSG  := 'Terminal indicator is not declared for terminal id' ||
                  SQLERRM || ' ' || SQLCODE;
       RAISE EXP_REJECT_RECORD;
    END;
  END IF;

  IF P_TXN_CODE not in ('07','13','39') THEN
    BEGIN

     IF V_TERMINAL_INDICATOR IS NOT NULL AND V_CTOC_AUTH_ID IS NOT NULL AND
        V_RESP_CDE IS NOT NULL AND V_TOACCT_BAL IS NOT NULL THEN
       V_RESP_CONC_MSG := RPAD(P_FROM_CARD_NO, '19', ' ') ||
                      RPAD(V_TOACCT_BAL + V_TXN_AMT, '12', ' ') ||
                      RPAD(V_CTOC_AUTH_ID, '6', ' ') ||
                      RPAD(V_RESP_CDE, '2', ' ') ||
                      RPAD(V_TERMINAL_INDICATOR, '1', ' ');
       P_RESP_MSG      := V_RESP_CONC_MSG;
     ELSE
       V_RESP_CDE := '21';
       V_ERR_MSG  := ' Error while crating response message :- Either terminal indicator or authid is null ';
       RAISE EXP_REJECT_RECORD;
     END IF;
    EXCEPTION
     WHEN OTHERS THEN
       V_RESP_CDE := '21';
       V_ERR_MSG  := 'Exception while creating the response format' ||
                  SUBSTR(SQLERRM, 1, 200);

       RAISE EXP_REJECT_RECORD;
    END;
  END IF;

  P_RESP_CODE := '00';
  IF P_RESP_MSG = 'OK' OR P_RESP_MSG IS NULL THEN
    BEGIN
     SELECT CAM_ACCT_BAL
       INTO V_TOACCT_BAL
       FROM CMS_ACCT_MAST
      WHERE CAM_INST_CODE = P_INST_CODE AND
           CAM_ACCT_NO =
           (SELECT CAP.CAP_ACCT_NO
             FROM CMS_APPL_PAN CAP
            WHERE CAP.CAP_PAN_CODE = V_HASH_PAN_FROM);
     P_RESP_MSG := V_TOACCT_BAL;
    EXCEPTION
     WHEN OTHERS THEN
       V_RESP_CDE := '21';
       V_ERR_MSG  := 'Error while selecting CMS_ACCT_MAST' ||
                  SUBSTR(SQLERRM, 1, 200);
       RAISE EXP_REJECT_RECORD;
    END;
  END IF;

   BEGIN
      IF v_prfl_flag = 'Y'
      THEN
         pkg_limits_check.sp_limitcnt_reset (P_INST_CODE,
                                             NULL,
                                             V_TXN_AMT,                
                                             v_comb_hash,
                                             V_RESP_CDE,
                                             V_ERR_MSG
                                            );
      END IF;

      IF V_RESP_CDE <> '00' AND V_ERR_MSG <> 'OK'
      THEN
         V_ERR_MSG := 'From Procedure sp_limitcnt_reset' || V_ERR_MSG;
         RAISE EXP_REJECT_RECORD;
      END IF;
   EXCEPTION
      WHEN EXP_REJECT_RECORD
      THEN
         RAISE;
      WHEN OTHERS
      THEN
         V_RESP_CDE := '21';
         V_ERR_MSG :=
               'Error from Limit Reset Count Process '
            || SUBSTR (SQLERRM, 1, 200);
         RAISE EXP_REJECT_RECORD;
   END;

    BEGIN
        SELECT sum(CSL_TRANS_AMOUNT) INTO P_FEE_AMT
        FROM CMS_STATEMENTS_LOG
        WHERE TXN_FEE_FLAG='Y'
        AND CSL_DELIVERY_CHANNEL=P_DELIVERY_CHANNEL
        AND CSL_TXN_CODE=P_TXN_CODE
        AND CSL_PAN_NO= V_HASH_PAN_FROM
        AND CSL_RRN=P_RRN
        and csl_inst_code=p_inst_code;
    exception
        when no_data_found then
            p_fee_amt:=0;

        WHEN OTHERS  THEN
            V_RESP_CDE := '21';
            V_ERR_MSG :=  'Error while selecting CMS_STATEMENTS_LOG ' || SUBSTR (SQLERRM, 1, 200);
            RAISE EXP_REJECT_RECORD;
    END;

EXCEPTION

  WHEN EXP_AUTH_REJECT_RECORD THEN
    P_RESP_CODE := V_RESP_CDE;
    P_RESP_MSG  := V_RESPMSG;
  BEGIN
              UPDATE CMS_TRANSACTION_LOG_DTL
              SET
              CTD_MOBILE_NUMBER=P_MOB_NO,
              CTD_DEVICE_ID=P_DEVICE_ID
              WHERE CTD_RRN=P_RRN AND CTD_BUSINESS_DATE=P_TRAN_DATE
              AND CTD_BUSINESS_TIME=P_TRAN_TIME
              AND CTD_DELIVERY_CHANNEL=P_DELIVERY_CHANNEL
              AND CTD_TXN_CODE=P_TXN_CODE
              AND CTD_MSG_TYPE=P_MSG
              AND CTD_INST_CODE=P_INST_CODE;

             IF SQL%ROWCOUNT = 0 THEN
                V_RESPMSG  := 'ERROR WHILE UPDATING CMS_TRANSACTION_LOG_DTL ';
                P_RESP_CODE := '21';
              RAISE EXP_REJECT_RECORD;
             END IF;
             EXCEPTION
             WHEN EXP_REJECT_RECORD THEN
             RAISE EXP_REJECT_RECORD;
             WHEN OTHERS THEN
                P_RESP_CODE := '21';
                V_RESPMSG  := 'Problem on updated cms_Transaction_log_dtl ' ||
                SUBSTR(SQLERRM, 1, 200);
               RAISE EXP_REJECT_RECORD;
            END;

  BEGIN

    UPDATE TRANSACTIONLOG
      SET TOPUP_CARD_NO     = V_HASH_PAN_TO,
         TOPUP_CARD_NO_ENCR = V_ENCR_PAN_TO,
         TOPUP_ACCT_NO      = V_TOACCTNUMBER,
         topup_acct_balance  = V_TOACCT_BAL,
         topup_ledger_balance =V_TOLEDGER_BAL,
         TOPUP_ACCT_TYPE     = V_TOACCT_TYPE,
         TIME_STAMP           = v_time_stamp,
       REMARK               = 'From Account No : ' ||
                             FN_MASK_ACCT(V_FROMACCT_NO) || ' ' ||
                             'To Account No : ' ||
                             FN_MASK_ACCT(V_TOACCTNUMBER)
    WHERE RRN = P_RRN AND DELIVERY_CHANNEL = P_DELIVERY_CHANNEL AND
         TXN_CODE = P_TXN_CODE AND BUSINESS_DATE = P_TRAN_DATE AND
         BUSINESS_TIME = P_TRAN_TIME AND
         CUSTOMER_CARD_NO = V_HASH_PAN_FROM;

    IF SQL%ROWCOUNT <> 1 THEN
     V_RESP_CDE := '21';
     V_ERR_MSG  := 'Error while updating transactionlog ' ||
                'no valid records ';
     RAISE EXP_REJECT_RECORD;
    END IF;

  EXCEPTION
    WHEN EXP_REJECT_RECORD THEN
     RAISE;
      WHEN OTHERS THEN
     V_RESP_CDE := '21';
     V_ERR_MSG  := 'Error while updating transactionlog ' ||
                SUBSTR(SQLERRM, 1, 200);
     RAISE EXP_REJECT_RECORD;

  END;

  WHEN EXP_REJECT_RECORD THEN
    ROLLBACK ;
    BEGIN
     SELECT CAM_ACCT_BAL, CAM_LEDGER_BAL,
            cam_type_code                        
       INTO V_ACCT_BALANCE, V_LEDGER_BALANCE,
            v_frmacct_type                       
       FROM CMS_ACCT_MAST
      WHERE CAM_ACCT_NO =
           (SELECT CAP_ACCT_NO
             FROM CMS_APPL_PAN
            WHERE CAP_PAN_CODE = V_HASH_PAN_FROM AND
                 CAP_INST_CODE = P_INST_CODE) AND
           CAM_INST_CODE = P_INST_CODE;
    EXCEPTION
     WHEN OTHERS THEN
       V_ACCT_BALANCE   := 0;
       V_LEDGER_BALANCE := 0;
    END;


 if V_TOACCTNUMBER is null 
     then

         BEGIN

              SELECT CAP_ACCT_NO
                       INTO   V_TOACCTNUMBER
                   FROM   CMS_APPL_PAN
              WHERE  CAP_INST_CODE = P_INST_CODE
              AND    CAP_PAN_CODE  = V_HASH_PAN_TO;

         EXCEPTION WHEN OTHERS THEN
            null;

         END;

     END IF;


      BEGIN
        SELECT CAM_ACCT_BAL, CAM_ACCT_NO,CAM_LEDGER_BAL,
               CAM_TYPE_CODE                             
         INTO V_TOACCT_BAL, V_TOACCT_NO,V_TOLEDGER_BAL,  
              V_TOACCT_TYPE                              
         FROM CMS_ACCT_MAST
        WHERE CAM_INST_CODE = P_INST_CODE AND
             CAM_ACCT_NO =  V_TOACCTNUMBER;

      EXCEPTION
        WHEN NO_DATA_FOUND THEN
        null; 
        WHEN OTHERS THEN
        null; 
      END;

    BEGIN
     SELECT CMS_ISO_RESPCDE
       INTO P_RESP_CODE
       FROM CMS_RESPONSE_MAST
      WHERE CMS_INST_CODE = P_INST_CODE AND
           CMS_DELIVERY_CHANNEL = P_DELIVERY_CHANNEL AND
           CMS_RESPONSE_ID = V_RESP_CDE;
     P_RESP_MSG := V_ERR_MSG;
    EXCEPTION
     WHEN OTHERS THEN
       P_RESP_MSG  := 'Problem while selecting data from response master ' ||
                   V_RESP_CDE || SUBSTR(SQLERRM, 1, 300);
       P_RESP_CODE := '69';
         RETURN;
    END;

     if V_FROM_PRODCODE is null
     then

         BEGIN

              SELECT CAP_CARD_STAT,
                     CAP_PROD_CODE,
                     CAP_CARD_TYPE,
                     CAP_ACCT_NO
              INTO   V_FROMCARDSTAT,
                     V_FROM_PRODCODE,
                     V_FROM_CARDTYPE,
                     V_FROMACCT_NO
              FROM   CMS_APPL_PAN
              WHERE  CAP_INST_CODE = P_INST_CODE
              AND    CAP_PAN_CODE  = V_HASH_PAN_FROM;

         EXCEPTION WHEN OTHERS THEN
            null;

         END;

     end if;


     if V_DR_CR_FLAG is null
     then

        BEGIN

             SELECT CTM_CREDIT_DEBIT_FLAG
               INTO V_DR_CR_FLAG
               FROM CMS_TRANSACTION_MAST
              WHERE CTM_TRAN_CODE = P_TXN_CODE
              AND   CTM_DELIVERY_CHANNEL = P_DELIVERY_CHANNEL
              AND   CTM_INST_CODE = P_INST_CODE;

        EXCEPTION
         WHEN OTHERS THEN

         NULL;

        END;

     end if;


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
         RESPONSE_ID,
         ANI,
         DNI,
         IPADDRESS,
         CARDSTATUS, 
         TRANS_DESC, 
         ERROR_MSG,
         topup_acct_balance ,
         topup_ledger_balance,
         ACCT_TYPE,
         TIME_STAMP,
         CR_DR_FLAG,     
       REMARK
         )
       VALUES
        ('0200',
         P_RRN,
         P_DELIVERY_CHANNEL,
         0,
         TO_DATE(P_TRAN_DATE, 'YYYY/MM/DD'),
         P_TXN_CODE,
         V_TXN_TYPE,
         0,
         DECODE(P_RESP_CODE, '00', 'C', 'F'),
         P_RESP_CODE,
         P_TRAN_DATE,
         SUBSTR(P_TRAN_TIME, 1, 10),
         V_HASH_PAN_FROM,
         V_HASH_PAN_TO,
         V_TOACCTNUMBER,
         V_TOACCT_TYPE,
         P_INST_CODE,
         TRIM(TO_CHAR(nvl(V_TXN_AMT,0), '99999999999999990.99')),    
         P_CURR_CODE,
         NULL,
         V_FROM_PRODCODE,      
         V_FROM_CARDTYPE,       
         0,
         V_CTOC_AUTH_ID,
         TRIM(TO_CHAR(nvl(V_TXN_AMT,0), '99999999999999990.99')),    
         '0.00',                                                     
         '0.00',                                                     
         P_INST_CODE,
         V_ENCR_PAN_FROM,
         V_ENCR_PAN_TO,
         '',
         0,
         V_ACCT_NUMBER,                                         
         nvl(V_ACCT_BALANCE,0),                                       
         nvl(V_LEDGER_BALANCE,0),                                     
         V_RESP_CDE,   
         P_ANI,
         P_DNI,
         P_IPADDRESS,
         V_FROMCARDSTAT, 
         V_TRANS_DESC, 
         V_ERR_MSG,
         nvl(V_TOACCT_BAL,0),
         nvl(V_TOLEDGER_BAL,0),
         V_FRMACCT_TYPE,            
         V_TIME_STAMP,               
         V_DR_CR_FLAG,              
       'From Account No : ' || FN_MASK_ACCT(V_FROMACCT_NO) || ' ' ||
        'To Account No : ' || FN_MASK_ACCT(V_TOACCTNUMBER));

     EXCEPTION
       WHEN OTHERS THEN

        P_RESP_CODE := '89';
        P_RESP_MSG  := 'Problem while inserting data into transaction log  dtl' ||
                    SUBSTR(SQLERRM, 1, 300);
            RETURN;
     END;

    BEGIN
     INSERT INTO CMS_TRANSACTION_LOG_DTL
       (CTD_DELIVERY_CHANNEL,
        CTD_TXN_CODE,
        CTD_TXN_TYPE,
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
        CTD_SYSTEM_TRACE_AUDIT_NO,
        CTD_LUPD_DATE,
        CTD_INST_CODE,
        CTD_LUPD_USER,
        CTD_INS_DATE,
        CTD_INS_USER,
        CTD_CUSTOMER_CARD_NO_ENCR,
        CTD_MSG_TYPE,
        REQUEST_XML,
        CTD_CUST_ACCT_NUMBER,
        CTD_ADDR_VERIFY_RESPONSE,
        CTD_MOBILE_NUMBER,CTD_DEVICE_ID,CTD_HASHKEY_ID 
        )
     VALUES
       (P_DELIVERY_CHANNEL,
        P_TXN_CODE,
        V_TXN_TYPE,
        P_TXN_MODE,
        P_TRAN_DATE,
        P_TRAN_TIME,
        V_HASH_PAN_FROM,
        V_TXN_AMT,
        P_CURR_CODE,
        V_TXN_AMT,
        NULL,
        NULL,
        NULL,
        NULL,
        V_TXN_AMT,
        V_CURR_CODE,
        'E',
        V_ERR_MSG,
        P_RRN,
        P_STAN,
        SYSDATE,
        P_INST_CODE,
        P_LUPD_USER,
        SYSDATE,
        P_LUPD_USER,
        V_ENCR_PAN_FROM,
        '000',
        '',
        V_ACCT_NUMBER,
        '',P_MOB_NO,P_DEVICE_ID,V_HASHKEY_ID 
        );
     P_RESP_MSG := V_ERR_MSG;
    EXCEPTION
     WHEN OTHERS THEN
       P_RESP_MSG  := 'Problem while inserting data into transaction log  dtl' ||
                   SUBSTR(SQLERRM, 1, 300);
       P_RESP_CODE := '99';
       RETURN;
    END;
  WHEN OTHERS THEN
    ROLLBACK ;
    V_RESP_CDE := '69';
    V_ERR_MSG  := 'Error from transaction processing ' ||
               SUBSTR(SQLERRM, 1, 90);

    BEGIN
     SELECT CMS_ISO_RESPCDE
       INTO P_RESP_CODE
       FROM CMS_RESPONSE_MAST
      WHERE CMS_INST_CODE = P_INST_CODE AND
           CMS_DELIVERY_CHANNEL = P_DELIVERY_CHANNEL AND
           CMS_RESPONSE_ID = V_RESP_CDE;
     P_RESP_MSG := V_ERR_MSG;

     IF P_RESP_CODE = '00' THEN
       SELECT CAM_ACCT_BAL
        INTO V_TOACCT_BAL
        FROM CMS_ACCT_MAST
        WHERE CAM_INST_CODE = P_INST_CODE AND
            CAM_ACCT_NO =
            (SELECT CAP.CAP_ACCT_NO
               FROM CMS_APPL_PAN CAP
              WHERE CAP.CAP_PAN_CODE = V_HASH_PAN_FROM);
       P_RESP_MSG := V_TOACCT_BAL;
     END IF;
    EXCEPTION
     WHEN OTHERS THEN
       P_RESP_MSG  := 'Problem while selecting data from response master ' ||
                   V_RESP_CDE || SUBSTR(SQLERRM, 1, 300);
       P_RESP_CODE := '99';
         RETURN;
    END;


      BEGIN
        SELECT CAM_ACCT_BAL, CAM_ACCT_NO,CAM_LEDGER_BAL,
               CAM_TYPE_CODE
         INTO V_TOACCT_BAL, V_TOACCT_NO,V_TOLEDGER_BAL,
              V_TOACCT_TYPE
         FROM CMS_ACCT_MAST
        WHERE CAM_INST_CODE = P_INST_CODE AND
             CAM_ACCT_NO =  V_TOACCTNUMBER;


      EXCEPTION
        WHEN NO_DATA_FOUND THEN
        null; 
        WHEN OTHERS THEN
        null;
      END;



    BEGIN
     INSERT INTO CMS_TRANSACTION_LOG_DTL
       (CTD_DELIVERY_CHANNEL,
        CTD_TXN_CODE,
        CTD_TXN_TYPE,
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
        CTD_SYSTEM_TRACE_AUDIT_NO,
        CTD_LUPD_DATE,
        CTD_INST_CODE,
        CTD_LUPD_USER,
        CTD_INS_DATE,
        CTD_INS_USER,
        CTD_CUSTOMER_CARD_NO_ENCR,
        CTD_MSG_TYPE,
        REQUEST_XML,
        CTD_CUST_ACCT_NUMBER,
        CTD_ADDR_VERIFY_RESPONSE,
        CTD_MOBILE_NUMBER,CTD_DEVICE_ID,CTD_HASHKEY_ID 
        )
     VALUES
       (P_DELIVERY_CHANNEL,
        P_TXN_CODE,
        V_TXN_TYPE,
        P_TXN_MODE,
        P_TRAN_DATE,
        P_TRAN_TIME,
        V_HASH_PAN_FROM, 
        V_TXN_AMT,
        P_CURR_CODE,
        V_TXN_AMT,
        NULL,
        NULL,
        NULL,
        NULL,
        V_TXN_AMT,
        V_CURR_CODE,
        'E',
        V_ERR_MSG,
        P_RRN,
        P_STAN,
        SYSDATE,
        P_INST_CODE,
        P_LUPD_USER,
        SYSDATE,
        P_LUPD_USER,
        V_ENCR_PAN_FROM,
        '000',
        '',
        V_ACCT_NUMBER,
        '',P_MOB_NO,P_DEVICE_ID,V_HASHKEY_ID 
        );
    EXCEPTION
     WHEN OTHERS THEN
       P_RESP_MSG  := 'Problem while inserting data into transaction log  dtl' ||
                   SUBSTR(SQLERRM, 1, 300);
       P_RESP_CODE := '99';
       RETURN;
    END;

    SELECT COUNT(*)
     INTO V_COUNT
     FROM TRANSACTIONLOG
    WHERE INSTCODE = P_INST_CODE AND RRN = P_RRN AND
         BUSINESS_DATE = P_TRAN_DATE AND BUSINESS_TIME = P_TRAN_TIME;


    IF V_COUNT < 1 THEN

     if V_FROM_PRODCODE is null
     then

         BEGIN

              SELECT CAP_CARD_STAT,
                     CAP_PROD_CODE,
                     CAP_CARD_TYPE,
                     CAP_ACCT_NO
              INTO   V_FROMCARDSTAT,
                     V_FROM_PRODCODE,
                     V_FROM_CARDTYPE,
                     V_FROMACCT_NO
              FROM   CMS_APPL_PAN
              WHERE  CAP_INST_CODE = P_INST_CODE
              AND    CAP_PAN_CODE  = V_HASH_PAN_FROM;

         EXCEPTION WHEN OTHERS THEN
            null;

         END;

     end if;


     if V_DR_CR_FLAG is null
     then

        BEGIN

             SELECT CTM_CREDIT_DEBIT_FLAG
               INTO V_DR_CR_FLAG
               FROM CMS_TRANSACTION_MAST
              WHERE CTM_TRAN_CODE = P_TXN_CODE
              AND   CTM_DELIVERY_CHANNEL = P_DELIVERY_CHANNEL
              AND   CTM_INST_CODE = P_INST_CODE;

        EXCEPTION
         WHEN OTHERS THEN

         NULL;

        END;

     end if;


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
         RESPONSE_ID,
         ANI,
         DNI,
         IPADDRESS,
         CARDSTATUS, 
         TRANS_DESC, 
         ERROR_MSG,
         topup_acct_balance ,
         topup_ledger_balance,
         ACCT_TYPE,
         TIME_STAMP,
         CR_DR_FLAG,      
       REMARK
         )
       VALUES
        ('0200',
         P_RRN,
         P_DELIVERY_CHANNEL,
         0,
         TO_DATE(P_TRAN_DATE, 'YYYY/MM/DD'),
         P_TXN_CODE,
         V_TXN_TYPE,
         0,
         DECODE(P_RESP_CODE, '00', 'C', 'F'),
         P_RESP_CODE,
         P_TRAN_DATE,
         SUBSTR(P_TRAN_TIME, 1, 10),
         V_HASH_PAN_FROM,
          V_HASH_PAN_TO,
         V_TOACCTNUMBER,
         V_TOACCT_TYPE,
         P_INST_CODE,
         TRIM(TO_CHAR(nvl(V_TXN_AMT,0), '99999999999999990.99')),    
         P_CURR_CODE,
         NULL,
         V_FROM_PRODCODE,       
         V_FROM_CARDTYPE,       
         0,
         V_CTOC_AUTH_ID,
         TRIM(TO_CHAR(nvl(V_TXN_AMT,0), '99999999999999990.99')),    
         '0.00',                                                     
         '0.00',                                                     
         P_INST_CODE,
         V_ENCR_PAN_FROM,
         V_ENCR_PAN_TO,
         '',
         0,
         V_ACCT_NUMBER,                                           
         nvl(V_ACCT_BALANCE,0),                                       
         nvl(V_LEDGER_BALANCE,0),                                     
         V_RESP_CDE,   
         P_ANI,
         P_DNI,
         P_IPADDRESS,
         V_FROMCARDSTAT, 
         V_TRANS_DESC, 
         V_ERR_MSG,
         nvl(V_TOACCT_BAL,0),
         nvl(V_TOLEDGER_BAL,0),
         V_FRMACCT_TYPE,            
         V_TIME_STAMP,               
         V_DR_CR_FLAG,              
       'From Account No : ' || FN_MASK_ACCT(V_FROMACCT_NO) || ' ' ||
         'To Account No : ' || FN_MASK_ACCT(V_TOACCTNUMBER));

     EXCEPTION
       WHEN OTHERS THEN

        P_RESP_CODE := '89';
        P_RESP_MSG  := 'Problem while inserting data into transaction log  dtl' ||
                    SUBSTR(SQLERRM, 1, 300);
            RETURN;
     END;
    END IF;

 
END;

/

show error