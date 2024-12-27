CREATE OR REPLACE PROCEDURE VMSCMS.SP_CARD_TO_CARD_TRANSFER_CSR 
                                               (
                                                P_INST_CODE        IN NUMBER,
                                                P_MSG              IN VARCHAR2,
                                                P_RRN              IN VARCHAR2,
                                                P_DELIVERY_CHANNEL IN VARCHAR2,
                                                P_TXN_CODE         IN VARCHAR2,
                                                P_TXN_MODE         IN VARCHAR2,
                                                P_TRAN_DATE        IN VARCHAR2,
                                                P_TRAN_TIME        IN VARCHAR2,
                                                P_TXN_AMT          IN NUMBER,
                                                P_CURR_CODE        IN VARCHAR2,
                                                P_FROM_CARD_NO     IN VARCHAR2,
                                                P_TO_CARD_NO       IN VARCHAR2,
                                                P_ORGNL_REQ_ID     IN VARCHAR2,
                                                P_INS_USER         IN NUMBER,
                                                P_RVSL_CODE        IN VARCHAR2,
                                                P_REMARK           IN VARCHAR2,
                                                P_REASON           IN VARCHAR2,
                                                P_IPADDRESS        IN VARCHAR2,
                                                P_CALL_ID          IN NUMBER,
                                                P_CTC_BINFLAG      IN VARCHAR2,--Added on 02-Mar-15 for DFCTNM-5
                                                PRM_FROM_ACCTBAL   OUT VARCHAR2,
                                                PRM_FROM_LEDGBAL   OUT VARCHAR2,
                                                P_RESP_CODE        OUT VARCHAR2,
                                                P_RESP_MSG         OUT VARCHAR2
                                                ) IS


  /**********************************************************************************
     * Created Date     : 11-Oct-2012
     * Created By       : Sagar
     * Purpose          : CSR card to card transfer
     * Modified by      : Sagar M.
     * Modified for     : Logging response id in CMS_C2CTXFR_TRANSACTION table
     * Modified Date    : 03-Jan-2013
     * Modified Reason  : Logging response id in CMS_C2CTXFR_TRANSACTION table
     * Build Number     : RI0023
     * Modified by      : Sagar M.
     * Modified Date    : 09-Feb-13
     * Modified reason  : Product Category spend limit not being adhered to by VMS
     * Modified for     : NA
     * Reviewer         : Dhiraj
     * Reviewed Date    : 10-Feb-13
     * Build Number     : RI0023.2_B0002

     * Modified By      :  Pankaj S.
     * Modified Date    :  25-Feb-13
     * Modified Reason  : FSS-549 (To logging TO_CARD details)
     * Reviewer         : Dhiraj
     * Reviewed Date    :
     * Release Number   : CSR3.5.1_RI0023.2_B0007

     * Modified by      : Dnyaneshwar J
     * Modified Date    : 16-APRIL-13
     * Modified reason  : for FSS-754 : To log Merchant Name

     * Modified By      : Sagar M.
     * Modified Date    : 18-Apr-2013
     * Modified for     : Defect 10871
     * Modified Reason  : Logging of below details in tranasctionlog and statementlog table
                          1) ledger balance in statementlog
                          2) Product code,Product category code,Card status,Acct Type,drcr flag
                          3) Timestamp and Amount values logging correction
     * Reviewer         : Dhiraj
     * Reviewed Date    : 18-Apr-2013
     * Build Number     : RI0024.1_B0010

     * Modified by      : Dnyaneshwar J
     * Modified Date    : 16-May-13
     * Modified reason  : for FSS-754 : To log Merchant Name as System
     * Build Number     : RI0024.1_B0018

     * Modified by      : Santosh K
     * Modified Date    : 23-Aug-13
     * Modified reason  : for Mantis Id : 0012102 : To card record shows incorrect available and balance in case of TXN Code 38 null
     * Build Number     : RI0024.4_B0003

     * Modified by      : Dnyaneshwar J
     * Modified Date    : 15-Jan-14
     * Modified reason  : MVCSD-4637
     * Reviewer         : Dhiraj
     * Reviewed Date    : 15-Jan-14
     * Build Number     : RI0027_B0003

     * Modified by      :  Narsing I
     * Modified Reason  :  Mantis-13847 (1.7.6.8 Changes merged)
     * Modified Date    :  10-Mar-2014
     * Build Number     :  RI0027.2_B0001

     * Modified by      : MAGESHKUMAR.S
     * Modified Date    : 02-Mar-15
     * Modified For     : DFCTNM-5
     * Reviewer         : Spankaj
     * Build Number     : VMSGPRHOSTCSD_3.0_B0001

     * Modified By      :  Narayanaswamy.T
     * Modified For     :  FSS-4118 - C2C transfer transactions must contain masked account number in comment with the from account and to account number
     * Modified Date    :  01-FEB-2016
     * Reviewer         :  Saravanakumar.A
     * Build Number     :  VMSGPRHOST_4.0

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
     
     * Modified by       : UBAIDUR RAHMAN.H
     * Modified Date     : 24-SEP-18
     * Modified For      : VMS-550
     * Reviewer          : Saravanakumar A
     * Build Number      : VMSGPRHOST_R06
	 
	 * Modified by       : BASKAR KRISHNAN
     * Modified Date     : 11-JUL-19
     * Modified For      : VMS-828
     * Reviewer          : Saravanakumar A
     * Build Number      : VMSGPRHOST_R18
     
    * Modified By      : venkat Singamaneni
    * Modified Date    : 4-4-2022
    * Purpose          : Archival changes.
    * Reviewer         : Saravana Kumar A
    * Release Number   : VMSGPRHOST60 for VMS-5733/FSP-991
  *************************************************************************************/



  V_FROM_CARD_EXPRY     CMS_APPL_PAN.CAP_EXPRY_DATE%TYPE;
  V_TO_CARD_EXPRY       CMS_APPL_PAN.CAP_EXPRY_DATE%TYPE;
  V_RESP_CDE            transactionlog.response_id%TYPE;
  V_ERR_MSG             transactionlog.error_msg%TYPE;
  V_TXN_TYPE            TRANSACTIONLOG.TXN_TYPE%TYPE;
  V_CURR_CODE           TRANSACTIONLOG.CURRENCYCODE%TYPE;
  V_CAPTURE_DATE        DATE;
  V_DR_CR_FLAG          CMS_TRANSACTION_MAST.CTM_CREDIT_DEBIT_FLAG%TYPE;
  V_CTOC_AUTH_ID        TRANSACTIONLOG.AUTH_ID%TYPE;
  V_FROM_PRODCODE       CMS_APPL_PAN.CAP_PROD_CODE%TYPE;
  V_FROM_CARDTYPE       CMS_APPL_PAN.CAP_CARD_TYPE%TYPE;
  V_TRAN_DATE           DATE;
  V_FROM_CARD_CURR      VARCHAR2(5);
  V_TO_CARD_CURR        VARCHAR2(5);
  V_HASH_PAN_FROM       CMS_APPL_PAN.CAP_PAN_CODE%TYPE;
  V_ENCR_PAN_FROM       CMS_APPL_PAN.CAP_PAN_CODE_ENCR%TYPE;
  V_HASH_PAN_TO         CMS_APPL_PAN.CAP_PAN_CODE%TYPE;
  V_ENCR_PAN_TO         CMS_APPL_PAN.CAP_PAN_CODE_ENCR%TYPE;
  V_ACCT_BALANCE        CMS_ACCT_MAST.CAM_ACCT_BAL%TYPE;
  V_TOCARDSTAT          CMS_APPL_PAN.CAP_CARD_STAT%TYPE;
  V_FROMCARDSTAT        CMS_APPL_PAN.CAP_CARD_STAT%TYPE;
  V_RRN_COUNT           PLS_INTEGER;
  V_MAX_CARD_BAL        PLS_INTEGER;
  V_ACCT_NUMBER         CMS_APPL_PAN.CAP_ACCT_NO%TYPE;
  V_LEDGER_BALANCE      CMS_ACCT_MAST.CAM_LEDGER_BAL%TYPE;
  V_NARRATION           CMS_STATEMENTS_LOG.CSL_TRANS_NARRRATION%TYPE;
  V_TOACCT_NO           CMS_APPL_PAN.CAP_ACCT_NO%TYPE;
  V_FROMACCT_NO         CMS_APPL_PAN.CAP_ACCT_NO%TYPE;
  V_TOPRODCODE          CMS_APPL_PAN.CAP_PROD_CODE%TYPE;
  V_TOCARDTYPE          CMS_APPL_PAN.CAP_CARD_TYPE%TYPE;
  V_STATUS_CHK          PLS_INTEGER;
  V_ATMONLINE_LIMIT     CMS_APPL_PAN.CAP_ATM_ONLINE_LIMIT%TYPE;
  V_POSONLINE_LIMIT     CMS_APPL_PAN.CAP_ATM_OFFLINE_LIMIT%TYPE;
  V_OUTPUT_TYPE         CMS_TRANSACTION_MAST.CTM_OUTPUT_TYPE%TYPE;
  V_TRAN_TYPE           CMS_TRANSACTION_MAST.CTM_TRAN_TYPE%TYPE;
  v_comb_hash           pkg_limits_check.type_hash;                --  Added by amit on 30072012 for Pre - LIMITS BRD
  V_PRFL_FLAG           CMS_TRANSACTION_MAST.CTM_PRFL_FLAG%TYPE ;  --  Added by amit on 30072012 for Pre - LIMITS BRD
  v_trans_desc          CMS_TRANSACTION_MAST.CTM_TRAN_DESC%TYPE;
  v_from_pan            VARCHAR2(10);
  v_to_pan              VARCHAR2(10);
  V_FRMLEDGER_BAL       CMS_ACCT_MAST.CAM_LEDGER_BAL%TYPE;
  V_TOLEDGER_BAL        CMS_ACCT_MAST.CAM_LEDGER_BAL%TYPE;
  V_FRMACCT_TYPE        CMS_ACCT_MAST.CAM_TYPE_CODE%TYPE;
  V_TOACCT_TYPE         CMS_ACCT_MAST.CAM_TYPE_CODE%TYPE;
  V_FRMACCT_BAL         CMS_ACCT_MAST.CAM_ACCT_BAL%TYPE;
  V_TOACCT_BAL          CMS_ACCT_MAST.CAM_ACCT_BAL%TYPE;
  V_REQ_ID              CMS_C2CTXFR_TRANSACTION.CCT_REQUEST_ID%TYPE;
  V_FROMCARD_PROXY      CMS_APPL_PAN.CAP_PROXY_NUMBER%TYPE;
  V_TOCARD_PROXY        CMS_APPL_PAN.CAP_PROXY_NUMBER%TYPE;
  v_orgnl_rrn           CMS_C2CTXFR_TRANSACTION.CCT_RRN%TYPE;
  v_orgnl_date          CMS_C2CTXFR_TRANSACTION.CCT_TXN_DATE%TYPE;
  v_orgl_time           CMS_C2CTXFR_TRANSACTION.CCT_TXN_TIME%TYPE;
  V_ORGNL_DELCHNL       CMS_C2CTXFR_TRANSACTION.CCT_DEL_CHNL%type;
  V_ORGNL_TXNCODE       CMS_C2CTXFR_TRANSACTION.CCT_TXN_CODE%type;
  V_ORGNL_TXNTYPE       CMS_C2CTXFR_TRANSACTION.CCT_TXN_TYPE%type;
  v_check_statcnt       PLS_INTEGER;
  V_TXN_STATUS          CMS_C2CTXFR_TRANSACTION.CCT_TXN_STATUS%type;
  v_call_id             CMS_CALLLOG_MAST.CCM_CALL_ID%TYPE;
  v_orgnl_from_card     CMS_C2CTXFR_TRANSACTION.CCT_FROM_CARD%TYPE;
  v_orgnl_to_card       CMS_C2CTXFR_TRANSACTION.CCT_TO_CARD%TYPE;
  v_timestamp           timestamp;                       -- Added on 17-Apr-2013 for defect 10871
  v_profile_code        cms_prod_cattype.cpc_profile_code%type;
  v_enable_flag         VARCHAR2 (20)                          := 'Y';
  v_initialload_amt     cms_acct_mast.cam_new_initialload_amt%type;
  v_badcredit_flag      cms_prod_cattype.cpc_badcredit_flag%TYPE;
  v_badcredit_transgrpid   vms_group_tran_detl.vgd_group_id%TYPE;
  v_cnt                  PLS_INTEGER;
  V_TXN_AMT              cms_statements_log.CSL_TRANS_AMOUNT%TYPE; 
  EXP_REJECT_RECORD      EXCEPTION;
  EXP_AUTH_REJECT_RECORD EXCEPTION;
  v_Retperiod  date; --Added for VMS-5733/FSP-991
v_Retdate  date; --Added for VMS-5733/FSP-991
BEGIN

  V_CURR_CODE := P_CURR_CODE;
  V_TXN_TYPE  := '1';
  V_RESP_CDE  :=  1;
  V_ERR_MSG   := 'OK';
  V_TXN_AMT := ROUND (P_TXN_AMT,2);

     --Sn: Get hash value of from card
      BEGIN

        V_HASH_PAN_FROM := GETHASH(P_FROM_CARD_NO);

      EXCEPTION
        WHEN OTHERS THEN
         V_RESP_CDE := '21';
         V_ERR_MSG := 'Error while converting From pan into hash' || SUBSTR(SQLERRM, 1, 200);
         RAISE EXP_REJECT_RECORD;
      END;
      --EN :Get hash value of from card

      --SN create encr pan
      BEGIN

        V_ENCR_PAN_FROM := FN_EMAPS_MAIN(P_FROM_CARD_NO);

      EXCEPTION
        WHEN OTHERS THEN
         V_RESP_CDE := '21';
         V_ERR_MSG := 'Error while converting From pan into encr ' || SUBSTR(SQLERRM, 1, 200);
         RAISE EXP_REJECT_RECORD;
      END;
      --EN create encr pan


      --SN :Get hash value of to card
      BEGIN

        V_HASH_PAN_TO := GETHASH(P_TO_CARD_NO);

      EXCEPTION
        WHEN OTHERS THEN
         V_RESP_CDE := '21';
         V_ERR_MSG := 'Error while converting To pan into hash' || SUBSTR(SQLERRM, 1, 200);
         RAISE EXP_REJECT_RECORD;
      END;
      --EN :Get hash value of to card


      --SN create encr pan
      BEGIN

        V_ENCR_PAN_TO := FN_EMAPS_MAIN(P_TO_CARD_NO);

      EXCEPTION
        WHEN OTHERS THEN
         V_RESP_CDE := '21';
         V_ERR_MSG := 'Error while converting To pan into encr' || SUBSTR(SQLERRM, 1, 200);
         RAISE EXP_REJECT_RECORD;
      END;
      --EN create encr pan

      --Sn Duplicate RRN Check
      BEGIN

v_Retdate := TO_DATE(SUBSTR(TRIM(P_TRAN_DATE), 1, 8), 'yyyymmdd');

       select (add_months(trunc(sysdate,'MM'),'-'||RETENTION_PERIOD))
       INTO   v_Retperiod 
       FROM DBA_OPERATIONS.ARCHIVE_MGMNT_CTL 
       WHERE  OPERATION_TYPE='ARCHIVE' 
       AND OBJECT_NAME='TRANSACTIONLOG_EBR';

IF (v_Retdate>v_Retperiod)
    THEN
         SELECT COUNT(1)
         INTO V_RRN_COUNT
         FROM TRANSACTIONLOG
        WHERE INSTCODE         = P_INST_CODE
        AND   CUSTOMER_CARD_NO = V_HASH_PAN_FROM
        AND   RRN              = P_RRN
        AND   BUSINESS_DATE    = P_TRAN_DATE
        AND   BUSINESS_TIME    = P_TRAN_TIME
        AND   DELIVERY_CHANNEL = P_DELIVERY_CHANNEL
        AND   TXN_CODE         = P_TXN_CODE;
      else
         SELECT COUNT(1)
         INTO V_RRN_COUNT
         FROM VMSCMS_HISTORY.TRANSACTIONLOG_HIST --Added for VMS-5733/FSP-991
        WHERE INSTCODE         = P_INST_CODE
        AND   CUSTOMER_CARD_NO = V_HASH_PAN_FROM
        AND   RRN              = P_RRN
        AND   BUSINESS_DATE    = P_TRAN_DATE
        AND   BUSINESS_TIME    = P_TRAN_TIME
        AND   DELIVERY_CHANNEL = P_DELIVERY_CHANNEL
        AND   TXN_CODE         = P_TXN_CODE;
      end if;  

        IF V_RRN_COUNT > 0
        THEN

         V_RESP_CDE := '22';
         V_ERR_MSG  := 'Duplicate RRN on ' || P_TRAN_DATE;
         RAISE EXP_REJECT_RECORD;

        END IF;
	   EXCEPTION
	   WHEN OTHERS THEN
       V_RESP_CDE := '21';
       V_ERR_MSG  := 'Error while selecting rrn count from transactionlog';
       RAISE EXP_REJECT_RECORD;
     END;
      --En Duplicate RRN Check


        --Sn find debit and credit flag
         BEGIN

             SELECT CTM_CREDIT_DEBIT_FLAG,
                    CTM_OUTPUT_TYPE,
                    TO_NUMBER(DECODE(CTM_TRAN_TYPE, 'N', '0', 'F', '1')),
                    CTM_TRAN_TYPE,
                    CTM_PRFL_FLAG,
                    CTM_TRAN_DESC
               INTO V_DR_CR_FLAG,
                    V_OUTPUT_TYPE,
                    V_TXN_TYPE,
                    V_TRAN_TYPE,
                    V_PRFL_FLAG,
                    V_TRANS_DESC
               FROM CMS_TRANSACTION_MAST
              WHERE CTM_TRAN_CODE        = P_TXN_CODE
              AND   CTM_DELIVERY_CHANNEL = P_DELIVERY_CHANNEL
              AND   CTM_INST_CODE        = P_INST_CODE;

         EXCEPTION
         WHEN NO_DATA_FOUND THEN
           V_RESP_CDE := '49';
           V_ERR_MSG  := 'Transflag  not defined for txn code ' ||
                      P_TXN_CODE || ' and delivery channel ' ||
                      P_DELIVERY_CHANNEL;
           RAISE EXP_REJECT_RECORD;
         WHEN OTHERS THEN
           V_RESP_CDE := '21';
           V_ERR_MSG  := 'Error while selecting transaction details';
           RAISE EXP_REJECT_RECORD;
         END;
        --En find debit and credit flag


        /*--SN Block moved up for concurrent issue */

          if P_TXN_CODE <> '38'
          then

             BEGIN

                SELECT CCT_RRN,CCT_TXN_DATE,
                       CCT_TXN_TIME,
                       CCT_DEL_CHNL,
                       CCT_TXN_CODE,
                       CCT_TXN_TYPE,
                       CCT_TXN_STATUS,
                       CCT_FROM_CARD,
                       CCT_TO_CARD
                INTO   V_ORGNL_RRN,
                       V_ORGNL_DATE,
                       V_ORGL_TIME,
                       V_ORGNL_DELCHNL,
                       V_ORGNL_TXNCODE,
                       V_ORGNL_TXNTYPE,
                       V_TXN_STATUS,
                       v_orgnl_from_card,
                       v_orgnl_to_card
                FROM   CMS_C2CTXFR_TRANSACTION
                WHERE  CCT_REQUEST_ID = P_ORGNL_REQ_ID
                for update;----added by Narsing I J on 4 Mar 2014 for Mantis-13847


                if v_orgnl_from_card <> v_hash_pan_from
                then

                 V_RESP_CDE := '49';
                 V_ERR_MSG  := 'FromCard not matching';
                 RAISE EXP_REJECT_RECORD;

                end if;


                if v_orgnl_to_card <> v_hash_pan_to
                then

                 V_RESP_CDE := '49';
                 V_ERR_MSG  := 'ToCard not matching';
                 RAISE EXP_REJECT_RECORD;


                end if;



                if V_TXN_STATUS = 'A'
                then

                 V_RESP_CDE := '215';--Modified by Narsing I on 04 Mar 2014 for Mantis-13847
                 V_ERR_MSG  := 'Card to Card transfer request is already approved ';--Modified by Dnyaneshwar J on 04 Mar 2014
                 RAISE EXP_REJECT_RECORD;

                elsif V_TXN_STATUS = 'R'
                then

                 V_RESP_CDE := '216';--Modified by Narsing I on 04 Mar 2014 for Mantis-13847
                 V_ERR_MSG  := 'Card to Card transfer request is already rejected ';--Modified by Dnyaneshwar J on 04 Mar 2014
                 RAISE EXP_REJECT_RECORD;

                end if;


             EXCEPTION WHEN EXP_REJECT_RECORD -- Added during 10871 changes on 21-apr-2013
             then raise;


             WHEN NO_DATA_FOUND THEN
                 V_RESP_CDE := '49';
                 V_ERR_MSG  := 'Invalid request id ' || P_ORGNL_REQ_ID;
                 RAISE EXP_REJECT_RECORD;

             WHEN OTHERS THEN
                 V_RESP_CDE := '21';
                 V_ERR_MSG  := 'Problem while selecting original transaction details ' ||
                            SUBSTR(SQLERRM, 1, 100);
                 RAISE EXP_REJECT_RECORD;
             END;

          end if;

        /*--EN Block moved up for concurrent issue */


         BEGIN

              SELECT CAP_EXPRY_DATE,
                     CAP_CARD_STAT,
                     CAP_PROD_CODE,
                     CAP_CARD_TYPE,
                     CAP_ACCT_NO,
                     CAP_PROXY_NUMBER
              INTO   V_FROM_CARD_EXPRY,
                     V_FROMCARDSTAT,
                     V_FROM_PRODCODE,
                     V_FROM_CARDTYPE,
                     V_FROMACCT_NO,
                     V_FROMCARD_PROXY
              FROM   CMS_APPL_PAN
              WHERE  CAP_INST_CODE = P_INST_CODE
              AND    CAP_PAN_CODE  = V_HASH_PAN_FROM;

         EXCEPTION WHEN NO_DATA_FOUND
         THEN

             V_RESP_CDE := '16';
             V_ERR_MSG  := 'From Card number not found ';
             RAISE EXP_REJECT_RECORD;

          WHEN OTHERS THEN

             V_RESP_CDE := '21';
             V_ERR_MSG  := 'Problem while selecting from card detail' ||SUBSTR(SQLERRM, 1, 200);
             RAISE EXP_REJECT_RECORD;
         END;




         BEGIN

              SELECT CAP_EXPRY_DATE,
                     CAP_CARD_STAT,
                     CAP_PROD_CODE,
                     CAP_CARD_TYPE,
                     CAP_ACCT_NO,
                     CAP_ATM_ONLINE_LIMIT,
                     CAP_POS_ONLINE_LIMIT,
                     CAP_PROXY_NUMBER
              INTO   V_TO_CARD_EXPRY ,
                     V_TOCARDSTAT,
                     V_TOPRODCODE,
                     V_TOCARDTYPE,
                     V_TOACCT_NO,
                     V_ATMONLINE_LIMIT,
                     V_POSONLINE_LIMIT,
                     V_TOCARD_PROXY
              FROM   CMS_APPL_PAN
              WHERE  CAP_INST_CODE = P_INST_CODE
              AND    CAP_PAN_CODE  = V_HASH_PAN_TO;

         EXCEPTION WHEN NO_DATA_FOUND
         THEN
             V_RESP_CDE := '16';
             V_ERR_MSG  := 'To card not found ';
             RAISE EXP_REJECT_RECORD;

         WHEN OTHERS
         THEN
             V_RESP_CDE := '21';
             V_ERR_MSG  := 'Problem while selecting to card detail' ||
                        SUBSTR(SQLERRM, 1, 200);
          RAISE EXP_REJECT_RECORD; -- Sn changed


         END;


         BEGIN

            SELECT CAM_ACCT_BAL,CAM_LEDGER_BAL,CAM_ACCT_NO,CAM_TYPE_CODE
             INTO V_FRMACCT_BAL,V_FRMLEDGER_BAL,V_FROMACCT_NO,V_FRMACCT_TYPE
             FROM CMS_ACCT_MAST
            WHERE CAM_INST_CODE = P_INST_CODE
            AND   CAM_ACCT_NO   = V_FROMACCT_NO;

         EXCEPTION
            WHEN NO_DATA_FOUND THEN
             V_RESP_CDE := '7'; --Ineligible Transaction
             V_ERR_MSG  := 'Invalid From Account '||V_FROMACCT_NO;
             RAISE EXP_REJECT_RECORD;
            WHEN OTHERS THEN
             V_RESP_CDE := '21';
             V_ERR_MSG  := 'Error while selecting data from acct Master for from acct ' ||
                        P_TO_CARD_NO || SUBSTR(SQLERRM, 1, 200);
             RAISE EXP_REJECT_RECORD;
         END;



     IF     P_TXN_CODE <> 40 -- THIS IS CHECKED FIRST BEFORE CHECKING FOR INSUFFCIENT
     THEN

          BEGIN

             sp_status_check_gpr (
                                 P_INST_CODE,
                                 P_from_CARD_NO,
                                 p_delivery_channel,
                                 V_from_CARD_EXPRY,
                                 V_fromCARDSTAT,
                                 P_TXN_CODE,
                                 P_TXN_MODE,
                                 V_from_PRODCODE,
                                 V_from_CARDTYPE,
                                 P_MSG,
                                 P_TRAN_DATE,
                                 P_TRAN_TIME,
                                 NULL,
                                 NULL,
                                 NULL,
                                 V_RESP_CDE,
                                 V_ERR_MSG
                                 );

             IF (   (v_resp_cde <> '1' AND v_err_msg <> 'OK')
                 OR (v_resp_cde <> '0' AND v_err_msg <> 'OK')
                )
             THEN
                RAISE exp_reject_record;
             ELSE
                v_status_chk := v_resp_cde;
                v_resp_cde := '1';
             END IF;
          EXCEPTION
             WHEN exp_reject_record
             THEN
                RAISE;
             WHEN OTHERS
             THEN
                v_resp_cde := '21';
                v_err_msg :=
                   'Error from GPR Card Status Check for from card'
                   || SUBSTR (SQLERRM, 1, 200);
                RAISE exp_reject_record;
          END;

          IF v_status_chk = '1'
          THEN

 
             --Sn check card stat
             BEGIN

                SELECT COUNT (1)
                  INTO v_check_statcnt
                  FROM pcms_valid_cardstat
                 WHERE pvc_inst_code = p_inst_code
                   AND pvc_card_stat = v_fromcardstat
                   AND pvc_tran_code = p_txn_code
                   AND pvc_delivery_channel = p_delivery_channel;

                IF v_check_statcnt = 0
                THEN
                   v_resp_cde := '10';
                   v_err_msg := 'From Card Not In valid Card Status';
                   RAISE exp_reject_record;
                END IF;

             EXCEPTION
                WHEN exp_reject_record
                THEN
                   RAISE exp_reject_record;
                WHEN OTHERS
                THEN
                   v_resp_cde := '21';
                   v_err_msg :=
                         'Problem while selecting card stat for from card'
                      || SUBSTR (SQLERRM, 1, 200);
                   RAISE exp_reject_record;
             END;
          --En check card stat
          END IF;



          --Sn GPR Card status check
          BEGIN
               SP_STATUS_CHECK_GPR( P_INST_CODE,
                                    P_TO_CARD_NO,
                                    p_delivery_channel,
                                    V_TO_CARD_EXPRY,
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
                                    NULL,
                                    V_RESP_CDE,
                                    V_ERR_MSG
                                  );

               IF ((V_RESP_CDE  <> '1' AND V_ERR_MSG <> 'OK')
                 OR (V_RESP_CDE <> '0' AND V_ERR_MSG <> 'OK')) THEN
                 RAISE EXP_REJECT_RECORD;

               ELSE
                    V_STATUS_CHK := V_RESP_CDE;
                    V_RESP_CDE   := '1';
               END IF;

          EXCEPTION
               WHEN EXP_REJECT_RECORD THEN
                RAISE;
               WHEN OTHERS THEN
                V_RESP_CDE := '21';
                V_ERR_MSG  := 'Error from GPR Card Status Check for to card' ||
                            SUBSTR(SQLERRM, 1, 100);
                RAISE EXP_REJECT_RECORD;
          END;
          --En GPR Card status check

          IF V_STATUS_CHK='1'
          THEN

            -- Expiry Check
             BEGIN

               IF TO_DATE(P_TRAN_DATE, 'YYYYMMDD') > LAST_DAY(TO_CHAR(V_TO_CARD_EXPRY, 'DD-MON-YY'))
               THEN
                V_RESP_CDE := '13';
                V_ERR_MSG  := 'TO CARD IS EXPIRED';
                RAISE EXP_REJECT_RECORD;
               END IF;

             EXCEPTION
             WHEN EXP_REJECT_RECORD
             THEN
                 RAISE;

             WHEN OTHERS THEN
                V_RESP_CDE := '21';
                V_ERR_MSG  := 'ERROR IN EXPIRY DATE CHECK FOR TO CARD: Tran Date - ' ||
                            P_TRAN_DATE || ', Expiry Date - ' || V_TO_CARD_EXPRY || ',' ||
                            SUBSTR(SQLERRM, 1, 200);
                RAISE EXP_REJECT_RECORD;

             END;

            --Sn check card stat
             BEGIN

                SELECT COUNT (1)
                  INTO v_check_statcnt
                  FROM pcms_valid_cardstat
                 WHERE pvc_inst_code = p_inst_code
                   AND pvc_card_stat =  v_tocardstat
                   AND pvc_tran_code = p_txn_code
                   AND pvc_delivery_channel = p_delivery_channel;

                IF v_check_statcnt = 0
                THEN
                   v_resp_cde := '10';
                   v_err_msg := 'To Card Not In valid Card Status';
                   RAISE exp_reject_record;

                END IF;

             EXCEPTION
                WHEN exp_reject_record
                THEN
                   RAISE exp_reject_record;
                WHEN OTHERS
                THEN
                   v_resp_cde := '21';
                   v_err_msg := 'Problem while selecting card stat for to card'
                                || SUBSTR (SQLERRM, 1, 200);
                   RAISE exp_reject_record;
             END;
          --En check card stat

          END IF;

     END IF;




       --SN find the TO acct balance--
      BEGIN

        SELECT CAM_ACCT_BAL,CAM_LEDGER_BAL, CAM_ACCT_NO,CAM_TYPE_CODE
        ,nvl(cam_new_initialload_amt,cam_initialload_amt)
         INTO V_TOACCT_BAL,V_TOLEDGER_BAL ,V_TOACCT_NO,V_TOACCT_TYPE,v_initialload_amt
         FROM CMS_ACCT_MAST
        WHERE CAM_INST_CODE =  P_INST_CODE
        AND   CAM_ACCT_NO   =  V_TOACCT_NO;

      EXCEPTION
        WHEN NO_DATA_FOUND THEN
         V_RESP_CDE := '7'; --Invalid account
         V_ERR_MSG  := 'Invalid To Account '||V_TOACCT_NO;
         RAISE EXP_REJECT_RECORD;

      WHEN OTHERS THEN
         V_RESP_CDE := '21';
         V_ERR_MSG  := 'Error while selecting data from acct Master for To acct' ||
                    SUBSTR(SQLERRM, 1, 100);
         RAISE EXP_REJECT_RECORD;
      END;
     --En find the TO acct balance--


      if P_TXN_CODE <> '40'
      then


             IF V_HASH_PAN_TO = V_HASH_PAN_FROM
             THEN

                V_RESP_CDE := '91';
                V_ERR_MSG  := 'FROM AND TO CARD NUMBERS SHOULD NOT BE SAME';
                RAISE EXP_REJECT_RECORD;

             END IF;



        IF P_CTC_BINFLAG = 'N' -- Added on 02-Mar-15 for DFCTNM-5
		AND length (p_from_card_no) > 10 
		AND  length (p_to_card_no) > 10
        THEN

                    v_from_pan := SUBSTR (P_FROM_CARD_NO, 1, 6);
                    v_to_pan   := SUBSTR (P_TO_CARD_NO, 1, 6);

                     if v_from_pan <> v_to_pan
                     then
                       V_RESP_CDE := '140';
                       V_ERR_MSG  := 'Both the card numbers should be of same BIN';
                     RAISE EXP_REJECT_RECORD;
                     end if;

       END IF; -- Added on 02-Mar-15 for DFCTNM-5


          --Sn find from card currency --
      BEGIN
         vmsfunutilities.get_currency_code(V_FROM_PRODCODE,V_from_CARDTYPE,P_INST_CODE,V_FROM_CARD_CURR,V_ERR_MSG);
      
      if V_ERR_MSG<>'OK' then
           raise EXP_REJECT_RECORD;
      end if;


            IF TRIM(V_FROM_CARD_CURR) IS NULL
            THEN

             V_RESP_CDE := '21';
             V_ERR_MSG  := 'From Card currency cannot be null ';
             RAISE EXP_REJECT_RECORD;

            END IF;

          EXCEPTION WHEN EXP_REJECT_RECORD
          THEN
               RAISE;

          WHEN OTHERS THEN
             V_ERR_MSG  := 'Error while selecting card currecy  ' ||
                        SUBSTR(SQLERRM, 1, 200);
             V_RESP_CDE := '21';
             RAISE EXP_REJECT_RECORD;
          end;
          --En find from card currency --


          --Sn find to card currency --
      BEGIN

      vmsfunutilities.get_currency_code(V_TOPRODCODE,V_TOCARDTYPE,P_INST_CODE,V_TO_CARD_CURR,V_ERR_MSG);
      
      if V_ERR_MSG<>'OK' then
           raise EXP_REJECT_RECORD;
      end if;


            IF TRIM(V_TO_CARD_CURR) IS NULL
            THEN

             V_RESP_CDE := '21';
             V_ERR_MSG  := 'To Card currency cannot be null ';
             RAISE EXP_REJECT_RECORD;

            END IF;

          EXCEPTION WHEN EXP_REJECT_RECORD
          THEN
               RAISE;

          WHEN OTHERS THEN
             V_ERR_MSG  := 'Error while selecting card currecy  ' ||SUBSTR(SQLERRM, 1, 200);
             V_RESP_CDE := '21';
             RAISE EXP_REJECT_RECORD;
          end;
          --En find to card currency --

          --sn check both currency--
          IF V_TO_CARD_CURR <> V_FROM_CARD_CURR
          THEN

            V_ERR_MSG  := 'Both from card currency and to card currency are not same  ' ||
                       SUBSTR(SQLERRM, 1, 100);
            V_RESP_CDE := '21';
            RAISE EXP_REJECT_RECORD;
          END IF;
          --En check both currency --

          --Sn check card currency with txn currency--
          IF V_CURR_CODE <> V_FROM_CARD_CURR
          THEN
            V_ERR_MSG  := 'Both from card currency and txn currency are not same  ';
            V_RESP_CDE := '21';
            RAISE EXP_REJECT_RECORD;
          end if;
          --En check card currency with txn currency--
          begin
           SELECT cpc_profile_code,cpc_badcredit_flag,cpc_badcredit_transgrpid
           into v_profile_code,v_badcredit_flag,v_badcredit_transgrpid
            FROM cms_prod_cattype
            WHERE CPC_INST_CODE = P_INST_CODE
            and   cpc_prod_code = v_toprodcode
            and   cpc_card_type = v_tocardtype;
          exception
              when others then
                   V_ERR_MSG  := 'Error while getting details from prod cattype';
            V_RESP_CDE := '21';
            RAISE EXP_REJECT_RECORD;
          end;
          BEGIN

            SELECT TO_NUMBER(CBP_PARAM_VALUE) -- Added on 09-Feb-2013 for max card balance check based on product category
            INTO V_MAX_CARD_BAL
            FROM CMS_BIN_PARAM
            WHERE CBP_INST_CODE = P_INST_CODE
            AND   CBP_PARAM_NAME = 'Max Card Balance'
            AND   CBP_PROFILE_CODE=v_profile_code;

          EXCEPTION
            WHEN OTHERS THEN
             V_RESP_CDE := '21';
             V_ERR_MSG  := 'ERROR IN FETCHING CARD BALANCE CONFIGURATION FOR THE PRODUCT PROFILE ' ||
                        SUBSTR(SQLERRM, 1, 100);
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
               v_resp_cde := '30';
               v_err_msg := 'EXCEEDING MAXIMUM CARD BALANCE';
               RAISE exp_reject_record;
         END IF;

          IF V_FRMACCT_BAL < V_TXN_AMT
          THEN

            V_RESP_CDE := '15'; --Ineligible Transaction
            V_ERR_MSG  := 'Insufficient Fund';
            RAISE EXP_REJECT_RECORD;

          END IF;

          IF NVL(V_TXN_AMT,0) = 0
          THEN

            V_RESP_CDE := '25'; --Ineligible Transaction
            V_ERR_MSG  := 'INVALID AMOUNT ';
            RAISE EXP_REJECT_RECORD;

          END IF;

          --Sn to check profile level limits
          BEGIN

              IF v_prfl_flag = 'Y' OR ( p_txn_code ='38' AND p_delivery_channel='03')
              THEN
                 pkg_limits_check.sp_limits_check (
                                                   null,
                                                   v_hash_pan_from,
                                                   v_hash_pan_to,
                                                   NULL,
                                                   p_txn_code,
                                                   v_tran_type,
                                                   NULL,
                                                   NULL,
                                                   p_inst_code,
                                                   NULL,
                                                   null,
                                                   v_txn_amt,
                                                   p_delivery_channel,
                                                   v_comb_hash,
                                                   v_resp_cde,
                                                   v_err_msg
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
                 raise exp_reject_record;
          End;
          --En to check profile level limits

      End IF;



      IF P_TXN_CODE = '38'
      THEN

           v_req_id := p_call_id||to_number(p_rrn);

           INSERT INTO CMS_C2CTXFR_TRANSACTION (
                                                CCT_INST_CODE,
                                                CCT_TXN_CODE,
                                                CCT_RRN,
                                                CCT_DEL_CHNL,
                                                CCT_TXN_AMT,
                                                CCT_FROM_CARD,
                                                CCT_TO_CARD,
                                                CCT_DATE_TIME,
                                                CCT_TXN_DATE,
                                                CCT_TXN_TIME,
                                                CCT_TXN_STATUS,
                                                CCT_FROM_CARD_ENCR,
                                                CCT_TO_CARD_ENCR,
                                                CCT_FROM_ACCT,
                                                CCT_TO_ACCT,
                                                CCT_REQUEST_ID,
                                                CCT_INS_DATE,
                                                CCT_INS_USER,
                                                CCT_LUPD_DATE,
                                                CCT_LUPD_USER,
                                                CCT_TXN_TYPE,
                                                cct_prod_code,
                                                cct_maker_remarks, -- Added on 27_DEC-2012 by Ganesh S. for logging maker remarks
                                                cct_response_id    --Added on 03-JAN-2013 by Sachin P. to capture Response Id
                                                )
                                        VALUES (
                                                P_INST_CODE,
                                                P_TXN_CODE,
                                                P_RRN,
                                                P_DELIVERY_CHANNEL,
                                                V_TXN_AMT,
                                                V_HASH_PAN_FROM,
                                                V_HASH_PAN_TO,
                                                TO_DATE(P_TRAN_DATE||P_TRAN_TIME,'YYYYMMDD HH24MISS'),
                                                P_TRAN_DATE,
                                                P_TRAN_TIME,
                                                'N',
                                                V_ENCR_PAN_FROM,
                                                V_ENCR_PAN_TO,
                                                V_FROMACCT_NO,
                                                V_TOACCT_NO,
                                                V_REQ_ID,
                                                SYSDATE,
                                                P_INS_USER,
                                                SYSDATE,
                                                P_INS_USER,
                                                V_TRAN_TYPE,
                                                V_FROM_PRODCODE,
                                                P_REMARK ,  -- Added on 27-DEC-2012 by Ganesh S. for logging maker remarks
                                                1          --Added on 03-JAN-2013 by Sachin P. to capture Response Id
                                               );

          PRM_FROM_ACCTBAL := NVL(TO_CHAR (V_FRMACCT_BAL, '99,99,99,990.99'),'0.00');

          PRM_FROM_LEDGBAL := NVL(TO_CHAR (V_FRMLEDGER_BAL, '99,99,99,990.99'),'0.00');


      ELSIF P_TXN_CODE = '39'
      then


         --Sn call to authorize procedure
          BEGIN

            SP_AUTHORIZE_TXN_CMS_AUTH(  P_INST_CODE,
                                        P_MSG,
                                        P_RRN,
                                        P_DELIVERY_CHANNEL,
                                        NULL,                --terminal id
                                        P_TXN_CODE,
                                        P_TXN_MODE,
                                        P_TRAN_DATE,
                                        P_TRAN_TIME,
                                        P_FROM_CARD_NO,
                                        1,                  --P_BANK_CODE
                                        V_TXN_AMT,
                                        NULL,
                                        NULL,
                                        null,               --P_MCC_CODE
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
                                        null,
                                        V_FROM_CARD_EXPRY,
                                        null,               --P_STAN
                                        '000',
                                        P_RVSL_CODE,
                                        V_TXN_AMT,
                                        V_CTOC_AUTH_ID,
                                        V_RESP_CDE,
                                        V_ERR_MSG,
                                        V_CAPTURE_DATE
                                     );

                IF V_RESP_CDE <> '00' AND V_ERR_MSG <> 'OK' THEN

                 RAISE EXP_AUTH_REJECT_RECORD;

                END IF;

          EXCEPTION
          WHEN EXP_AUTH_REJECT_RECORD THEN
             RAISE;

          WHEN OTHERS THEN
             V_RESP_CDE := '21';
             V_ERR_MSG  := 'Error from Card authorization' ||
                        SUBSTR(SQLERRM, 1, 100);
             RAISE EXP_REJECT_RECORD;
          end;
          --En call to authorize procedure


         --Sn Update the To acct no--
          BEGIN

            UPDATE CMS_ACCT_MAST
              SET CAM_ACCT_BAL   = CAM_ACCT_BAL + V_TXN_AMT,
                  CAM_LEDGER_BAL = CAM_LEDGER_BAL + V_TXN_AMT
            WHERE CAM_INST_CODE  = P_INST_CODE
            AND   CAM_ACCT_NO    = V_TOACCT_NO;

            IF SQL%ROWCOUNT = 0
            THEN
             V_RESP_CDE := '21';
             V_ERR_MSG  := 'Error while updating amount in to acct no ';
             RAISE EXP_REJECT_RECORD;
            END IF;

          EXCEPTION WHEN EXP_REJECT_RECORD
          THEN
              RAISE;

          WHEN OTHERS THEN
             V_RESP_CDE := '21';
             V_ERR_MSG  := 'Error while amount in to acct no ' ||
                        SUBSTR(SQLERRM, 1, 100);
             RAISE EXP_REJECT_RECORD;

          END;
         --En Update the to acct no--



        --SN  Add a record in statements lof for TO ACCT --
          BEGIN


            IF TRIM(V_TRANS_DESC) IS NOT NULL THEN
             V_NARRATION := V_TRANS_DESC || '/';
            END IF;

            IF TRIM(V_CTOC_AUTH_ID) IS NOT NULL THEN
             V_NARRATION := V_NARRATION || V_CTOC_AUTH_ID || '/';
            END IF;

            IF TRIM(V_FROMACCT_NO) IS NOT NULL THEN
             V_NARRATION := V_NARRATION || V_TOACCT_NO || '/';
            END IF;

            IF TRIM(P_TRAN_DATE) IS NOT NULL THEN
             V_NARRATION := V_NARRATION || P_TRAN_DATE;
            END IF;

          EXCEPTION WHEN OTHERS THEN

             V_RESP_CDE := '21';
             V_ERR_MSG  := 'Error in preparing the narration ' ||
                        SUBSTR(SQLERRM, 1, 100);
             RAISE EXP_REJECT_RECORD;

          END;

          v_timestamp := systimestamp;      -- Added on 17-Apr-2013 for defect 10871

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
              CSL_ACCT_TYPE,         -- Added on 17-Apr-2013 for defect 10871
              CSL_TIME_STAMP,         -- Added on 17-Apr-2013 for defect 10871
              CSL_PROD_CODE,
              csl_card_type-- Added on 17-Apr-2013 for defect 10871
              )
            VALUES
             (V_HASH_PAN_TO,
              V_TOLEDGER_BAL,                    -- V_TOACCT_BAL removed to use V_TOLEDGER_BAL on 17-Apr-2013 for defect 10871
              V_TXN_AMT,
              'CR',
              TO_DATE(P_TRAN_DATE||P_TRAN_TIME,'YYYYMMDD HH24MISS'),
              V_TOLEDGER_BAL + V_TXN_AMT,        -- V_TOACCT_BAL removed to use V_TOLEDGER_BAL on 17-Apr-2013 for defect 10871
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
              v_toacct_type,     -- Added on 17-Apr-2013 for defect 10871
              v_timestamp,        -- Added on 17-Apr-2013 for defect 10871
              V_TOPRODCODE,
              V_TOCARDTYPE-- Added on 17-Apr-2013 for defect 10871
             );
          EXCEPTION
            WHEN OTHERS THEN
             V_RESP_CDE := '21';
             V_ERR_MSG  := 'Error creating entry in statement log ';
             RAISE EXP_REJECT_RECORD;

          END;

          -----------------------------------------------------------------------------------------------
          --SN:updating latest timestamp value for from_crad to keep it same as to_card for defect 10871
          -----------------------------------------------------------------------------------------------

        Begin



       select trunc(add_months(sysdate,'-'||RETENTION_PERIOD))
       INTO   v_Retperiod 
       FROM DBA_OPERATIONS.ARCHIVE_MGMNT_CTL 
       WHERE  OPERATION_TYPE='ARCHIVE' 
       AND OBJECT_NAME='CMS_STATEMENTS_LOG_EBR';

v_Retdate := TO_DATE(SUBSTR(TRIM(P_TRAN_DATE), 1, 8), 'yyyymmdd');


--Added for VMS-5733/FSP-991
IF (v_Retdate>v_Retperiod)
    THEN
      
          update cms_statements_log
          set csl_time_stamp = v_timestamp
          where csl_pan_no = v_hash_pan_from
          and   csl_rrn = p_rrn
          and   csl_delivery_channel=p_delivery_channel
          and   csl_txn_code = p_txn_code
          and   csl_business_date = p_tran_date
          and   csl_business_time = p_tran_time;
      else
          update VMSCMS_HISTORY.CMS_STATEMENTS_LOG_HIST --Added for VMS-5733/FSP-991
          set csl_time_stamp = v_timestamp
          where csl_pan_no = v_hash_pan_from
          and   csl_rrn = p_rrn
          and   csl_delivery_channel=p_delivery_channel
          and   csl_txn_code = p_txn_code
          and   csl_business_date = p_tran_date
          and   csl_business_time = p_tran_time;
       end if;            
 
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

          ----------------------------------------------------------------------------------------------
          --EN:updating latest timestamp value for from_crad to keep it same as to_card for defect 10871
          ----------------------------------------------------------------------------------------------


          BEGIN

            SP_DAILY_BIN_BAL(P_TO_CARD_NO,
                             V_TRAN_DATE,
                             V_TXN_AMT,
                             V_DR_CR_FLAG,
                             P_INST_CODE,
                             1,             --P_BANK_CODE
                             V_ERR_MSG
                             );

               IF V_ERR_MSG <> 'OK' THEN
                V_RESP_CDE := '21';
                V_ERR_MSG  := 'Error from SP_DAILY_BIN_BAL execution '||V_ERR_MSG;
                RAISE EXP_REJECT_RECORD;
               END IF;

          EXCEPTION WHEN EXP_REJECT_RECORD
          THEN
              RAISE;

          WHEN OTHERS
          THEN
            V_RESP_CDE := '21';
            V_ERR_MSG  := 'Error from SP_DAILY_BIN_BAL execution ';
            RAISE EXP_REJECT_RECORD;

          END;



        --Sn to reset limit
         BEGIN

              IF v_prfl_flag = 'Y'
              THEN
                 pkg_limits_check.sp_limitcnt_reset (P_INST_CODE,
                                                     NULL,
                                                     V_TXN_AMT,                --p_txn_amt,
                                                     v_comb_hash,
                                                     V_RESP_CDE,
                                                     V_ERR_MSG
                                                    );
              END IF;

              IF V_RESP_CDE <> '00' AND V_ERR_MSG <> 'OK'
              THEN
                 V_ERR_MSG := 'From Procedure sp_limitcnt_reset' || V_ERR_MSG;
                 raise exp_reject_record;
              end if;

         END;
         --Sn to reset limit




          --Sn to update success flag in que table after succesful transaction--
          BEGIN

              update cms_c2ctxfr_transaction
              set    cct_txn_status = 'A',
                     CCT_LUPD_USER  = p_ins_user ,
                     -- SN : Added on 27-DEC-2012 by Ganesh S. for logging approver remarks, approving user and date
                     cct_approver_remarks = P_REMARK,
                     cct_approver_user = P_INS_USER,
                     cct_approval_date = sysdate,
                     -- EN : Added on 27-DEC-2012 by Ganesh S. for logging approver remarks, approving user and date
                     cct_response_id = 1    --Added on 03-JAN-2013 by Sachin P. to capture Response Id
              where  CCT_REQUEST_ID = p_orgnl_req_id;

              if sql%rowcount=0
              then
                V_RESP_CDE:='21';
                v_err_msg:='Request not found in queue table to update success flag.';
                raise EXP_REJECT_RECORD;
              END IF;

          exception
          when exp_reject_record
          then
            RAISE;
          when others
          THEN
            V_RESP_CDE:='21';
            v_err_msg:='Error while updating status flag in queue table '||substr(sqlerrm,1,100);
            RAISE EXP_REJECT_RECORD;
          END;

          --Sn update topup card number in translog
          BEGIN
       select (add_months(trunc(sysdate,'MM'),'-'||RETENTION_PERIOD))
       INTO   v_Retperiod 
       FROM DBA_OPERATIONS.ARCHIVE_MGMNT_CTL 
       WHERE  OPERATION_TYPE='ARCHIVE' 
       AND OBJECT_NAME='TRANSACTIONLOG_EBR';
	   
	   v_Retdate := TO_DATE(SUBSTR(TRIM(P_TRAN_DATE), 1, 8), 'yyyymmdd');

          
     IF (v_Retdate>v_Retperiod)
    THEN     

            UPDATE TRANSACTIONLOG
              SET TOPUP_CARD_NO       = V_HASH_PAN_TO,
                  TOPUP_CARD_NO_ENCR  = V_ENCR_PAN_TO,
                  TOPUP_ACCT_NO       = V_TOACCT_NO,
                  TOPUP_ACCT_TYPE     = V_TOACCT_TYPE,
                  IPADDRESS           = P_IPADDRESS,
                  ORGNL_CARD_NO       = V_HASH_PAN_FROM,
                  ORGNL_RRN           = V_ORGNL_RRN,
                  ORGNL_BUSINESS_DATE = V_ORGNL_DATE,
                  ORGNL_BUSINESS_TIME = V_ORGL_TIME,
                  REASON              = P_REASON,
                  REMARK              = DECODE(P_TXN_CODE,
								  '39',
								  NVL2(P_REMARK,P_REMARK||CHR(13) || CHR(10) ||'From Account No : ' ||
								  FN_MASK_ACCT(V_FROMACCT_NO) || ' ' ||
								  'To Account No : ' ||
								  FN_MASK_ACCT(V_TOACCT_NO),'From Account No : ' ||
								  FN_MASK_ACCT(V_FROMACCT_NO) || ' ' ||
								  'To Account No : ' ||
								  FN_MASK_ACCT(V_TOACCT_NO)),
								  P_REMARK), --changed for FSS-4118
                  ADD_LUPD_USER       = P_INS_USER,
                  TRAN_CURR           = V_CURR_CODE,
                  ADD_INS_USER        = P_INS_USER  ,
                  --Sn Added by Pankaj S. on 25_Feb_13 for logging to_card details
                  topup_acct_balance  = V_TOACCT_BAL+V_TXN_AMT,
                  topup_ledger_balance =V_TOLEDGER_BAL+V_TXN_AMT,
                  --En Added by Pankaj S. on 25_Feb_13 for logging to_card details
                  MERCHANT_NAME = 'System', --added on 16-April-2013 for defect 754 --Modified by Dnyaneshwar J on 09 May 2013
                  TIME_STAMP    = v_timestamp   --added on 18-April-2013 for defect 10871
            WHERE RRN = P_RRN
            AND DELIVERY_CHANNEL = P_DELIVERY_CHANNEL
            AND TXN_CODE         = P_TXN_CODE
            AND BUSINESS_DATE    = P_TRAN_DATE
            AND BUSINESS_TIME    = P_TRAN_TIME
            AND CUSTOMER_CARD_NO = V_HASH_PAN_FROM;
       else
       UPDATE VMSCMS_HISTORY.TRANSACTIONLOG_HIST --Added for VMS-5733/FSP-991
              SET TOPUP_CARD_NO       = V_HASH_PAN_TO,
                  TOPUP_CARD_NO_ENCR  = V_ENCR_PAN_TO,
                  TOPUP_ACCT_NO       = V_TOACCT_NO,
                  TOPUP_ACCT_TYPE     = V_TOACCT_TYPE,
                  IPADDRESS           = P_IPADDRESS,
                  ORGNL_CARD_NO       = V_HASH_PAN_FROM,
                  ORGNL_RRN           = V_ORGNL_RRN,
                  ORGNL_BUSINESS_DATE = V_ORGNL_DATE,
                  ORGNL_BUSINESS_TIME = V_ORGL_TIME,
                  REASON              = P_REASON,
                  REMARK              = DECODE(P_TXN_CODE,
								  '39',
								  NVL2(P_REMARK,P_REMARK||CHR(13) || CHR(10) ||'From Account No : ' ||
								  FN_MASK_ACCT(V_FROMACCT_NO) || ' ' ||
								  'To Account No : ' ||
								  FN_MASK_ACCT(V_TOACCT_NO),'From Account No : ' ||
								  FN_MASK_ACCT(V_FROMACCT_NO) || ' ' ||
								  'To Account No : ' ||
								  FN_MASK_ACCT(V_TOACCT_NO)),
								  P_REMARK), --changed for FSS-4118
                  ADD_LUPD_USER       = P_INS_USER,
                  TRAN_CURR           = V_CURR_CODE,
                  ADD_INS_USER        = P_INS_USER  ,
                  --Sn Added by Pankaj S. on 25_Feb_13 for logging to_card details
                  topup_acct_balance  = V_TOACCT_BAL+V_TXN_AMT,
                  topup_ledger_balance =V_TOLEDGER_BAL+V_TXN_AMT,
                  --En Added by Pankaj S. on 25_Feb_13 for logging to_card details
                  MERCHANT_NAME = 'System', --added on 16-April-2013 for defect 754 --Modified by Dnyaneshwar J on 09 May 2013
                  TIME_STAMP    = v_timestamp   --added on 18-April-2013 for defect 10871
            WHERE RRN = P_RRN
            AND DELIVERY_CHANNEL = P_DELIVERY_CHANNEL
            AND TXN_CODE         = P_TXN_CODE
            AND BUSINESS_DATE    = P_TRAN_DATE
            AND BUSINESS_TIME    = P_TRAN_TIME
            AND CUSTOMER_CARD_NO = V_HASH_PAN_FROM;     
      end if;
            IF SQL%ROWCOUNT <> 1
            THEN
             V_RESP_CDE := '21';
             V_ERR_MSG  := 'For auth sucess,Transactionlog not updated for topup card details';
             RAISE EXP_REJECT_RECORD;
            END IF;

          EXCEPTION WHEN EXP_REJECT_RECORD
          THEN
               Raise;

          WHEN OTHERS THEN
             V_RESP_CDE := '21';
             V_ERR_MSG  := 'Error while updating transactionlog ' ||
                        SUBSTR(SQLERRM, 1, 200);
             RAISE EXP_REJECT_RECORD;

          END;

          PRM_FROM_ACCTBAL := V_FRMACCT_BAL - V_TXN_AMT;

          PRM_FROM_ACCTBAL := NVL(TO_CHAR (prm_from_acctbal, '99,99,99,990.99'),'0.00');

          PRM_FROM_LEDGBAL := V_FRMLEDGER_BAL - V_TXN_AMT;

          PRM_FROM_LEDGBAL :=  NVL(TO_CHAR (prm_from_ledgbal, '99,99,99,990.99'),'0.00');


      ELSIF p_txn_code = '40'
      then
            BEGIN

              UPDATE CMS_C2CTXFR_TRANSACTION
              SET    CCT_TXN_STATUS = 'R',
                     CCT_LUPD_USER  = p_ins_user ,
                     -- SN : Added on 27-DEC-2012 by Ganesh S. for logging approver remarks, approving user and date
                     cct_approver_remarks = P_REMARK,
                     cct_approver_user = P_INS_USER,
                     cct_approval_date = sysdate,
                     -- EN : Added on 27-DEC-2012 by Ganesh S. for logging approver remarks, approving user and date
                     cct_response_id = v_resp_cde      --Added on 03-JAN-2013 by Sachin P. to capture Response Id
              where  CCT_REQUEST_ID = p_orgnl_req_id;

                 If sql%rowcount=0
                 then
                    V_RESP_CDE:='21';
                    v_err_msg:='Rrequest not found in queue table to update reject flag';
                    raise EXP_REJECT_RECORD;
                 END IF;

            exception when others
            then
              v_resp_cde:='21';
              v_err_msg:='Error while updating reject flag in queue table-'||substr(sqlerrm,1,200);
              raise EXP_REJECT_RECORD;
            END;

            PRM_FROM_ACCTBAL :=  NVL(TO_CHAR (V_FRMACCT_BAL, '99,99,99,990.99'),'0.00');

            PRM_FROM_LEDGBAL :=  NVL(TO_CHAR (V_FRMLEDGER_BAL, '99,99,99,990.99'),'0.00');


      END IF;


      -- SN : Call Id will be generated incase of Approve and Reject Transaction
       IF P_TXN_CODE IN ('39','40')
       THEN

           BEGIN

              SELECT seq_call_id.NEXTVAL
                INTO v_call_id
                FROM DUAL;
           EXCEPTION
              WHEN OTHERS
              THEN
                 v_resp_cde := '21';
                 v_err_msg := 'Error while generating call id ' || substr(SQLERRM,1,100);
                 RAISE exp_reject_record;
           END;

           BEGIN

              INSERT INTO cms_calllog_mast
                          (ccm_inst_code, ccm_call_id, ccm_call_catg, ccm_pan_code,
                           ccm_callstart_date, ccm_callend_date, ccm_ins_user,
                           ccm_ins_date, ccm_lupd_user, ccm_lupd_date,
                           ccm_acct_no,ccm_call_status
                          )
                   VALUES (P_INST_CODE, v_call_id, 1, V_HASH_PAN_FROM,
                           sysdate, null, P_INS_USER,
                           sysdate, P_INS_USER, sysdate,
                           V_FROMACCT_NO,'C'
                          );
           EXCEPTION
              WHEN OTHERS
              THEN
                 v_resp_cde := '21';
                 v_err_msg :=
                           'Error while inserting into cms_calllog_mast ' ||substr(SQLERRM,1,100);
                 RAISE exp_reject_record;
           END;


           BEGIN
              INSERT INTO cms_calllog_details
                          (ccd_inst_code, ccd_call_id, ccd_pan_code, ccd_call_seq,
                           ccd_rrn, ccd_devl_chnl, ccd_txn_code,
                           ccd_tran_date, ccd_tran_time, ccd_tbl_names,
                           ccd_colm_name, ccd_old_value, ccd_new_value,
                           ccd_comments, ccd_ins_user, ccd_ins_date, ccd_lupd_user,
                           ccd_lupd_date,
                           ccd_acct_no
                          )
                   VALUES (P_INST_CODE, v_call_id, V_HASH_PAN_FROM, 1,
                           P_RRN, P_DELIVERY_CHANNEL, P_TXN_CODE,
                           P_TRAN_DATE, P_TRAN_TIME, NULL,
                           NULL, NULL, NULL,
                           P_REMARK, P_INS_USER, SYSDATE, P_INS_USER,
                           SYSDATE,
                           V_FROMACCT_NO
                          );
           EXCEPTION
              WHEN OTHERS
              THEN
                 v_resp_cde := '21';
                 v_err_msg :='Error while inserting into cms_calllog_details ' || substr(SQLERRM,1,100);
                 RAISE  exp_reject_record;
           END;

       END IF;
      -- SN : Call Id will be generated incase of Approve and Reject Transaction


    V_RESP_CDE := 1;

    BEGIN

      SELECT CMS_ISO_RESPCDE
      INTO P_RESP_CODE
      FROM CMS_RESPONSE_MAST
      WHERE CMS_INST_CODE        = P_INST_CODE
      AND   CMS_DELIVERY_CHANNEL = P_DELIVERY_CHANNEL
      AND   CMS_RESPONSE_ID      = V_RESP_CDE;

     P_RESP_MSG := V_ERR_MSG;

    EXCEPTION
     WHEN OTHERS THEN
       V_ERR_MSG  := 'Problem while selecting data from response master1 ' ||
                   V_RESP_CDE || SUBSTR(SQLERRM, 1, 100);
       V_RESP_CDE := '69';
       raise  EXP_REJECT_RECORD;
    END;


     IF p_txn_code in ('38','40')
          then

          v_timestamp := systimestamp;      -- Added on 17-Apr-2013 for defect 10871

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
                     IPADDRESS,
                     CARDSTATUS,
                     TRANS_DESC,
                     ORGNL_CARD_NO,
                     ORGNL_RRN,
                     ORGNL_BUSINESS_DATE,
                     ORGNL_BUSINESS_TIME,
                     CR_DR_FLAG,
                     REASON,
                     REMARK,
                     add_ins_user,
                     add_lupd_user,
                     error_msg,
                     TRAN_CURR,
                     --Sn Added by Pankaj S. on 25_Feb_13 for logging to_card details
                     topup_acct_balance,
                     topup_ledger_balance,
                     --En Added by Pankaj S. on 25_Feb_13 for logging to_card details
                     MERCHANT_NAME, --Added on 16-April-2013 for defect 754
                     acct_type,
                     time_stamp
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
                     DECODE(p_resp_code, '00', 'C', 'F'),
                     p_resp_code,
                     P_TRAN_DATE,
                     P_TRAN_TIME,
                     V_HASH_PAN_FROM,
                     V_HASH_PAN_TO,
                     V_TOACCT_NO,
                     V_TOACCT_TYPE,
                     P_INST_CODE,
                     TRIM(TO_CHAR(nvl(V_TXN_AMT,0), '99999999999999999.99')),   -- NVL added on 17-Apr-2013 for defect 10871
                     P_CURR_CODE,
                     NULL,
                     V_FROM_PRODCODE,           -- Added on 18-apr-2013 for defect 10871
                     V_FROM_CARDTYPE,           -- Added on 18-apr-2013 for defect 10871
                     0,
                     V_CTOC_AUTH_ID,
                     TRIM(TO_CHAR(nvl(V_TXN_AMT,0), '99999999999999999.99')),   -- NVL added on 17-Apr-2013 for defect 10871
                     '0.00',                                                    -- NULL replaced by 0.00 , on 17-Apr-2013 for defect 10871
                     '0.00',                                                    -- NULL replaced by 0.00 , on 17-Apr-2013 for defect 10871
                     P_INST_CODE,
                     V_ENCR_PAN_FROM,
                     V_ENCR_PAN_TO,
                     '',
                     00,
                     V_FROMACCT_NO,
                     V_FRMACCT_BAL,
                     V_FRMLEDGER_BAL,
                     V_RESP_CDE,
                     P_IPADDRESS,
                     V_FROMCARDSTAT,
                     V_TRANS_DESC,
                     DECODE(P_TXN_CODE,'40',V_HASH_PAN_FROM,NULL),
                     DECODE(P_TXN_CODE,'40',V_ORGNL_RRN,NULL),
                     DECODE(P_TXN_CODE,'40',V_ORGNL_DATE,NULL),
                     DECODE(P_TXN_CODE,'40',V_ORGL_TIME,NULL),
                     V_DR_CR_FLAG,
                     P_REASON,
                     DECODE(P_TXN_CODE,
								  '39',
								  NVL2(P_REMARK,P_REMARK||CHR(13) || CHR(10) ||'From Account No : ' ||
								  FN_MASK_ACCT(V_FROMACCT_NO) || ' ' ||
								  'To Account No : ' ||
								  FN_MASK_ACCT(V_TOACCT_NO),'From Account No : ' ||
								  FN_MASK_ACCT(V_FROMACCT_NO) || ' ' ||
								  'To Account No : ' ||
								  FN_MASK_ACCT(V_TOACCT_NO)),
								  P_REMARK),--changed for FSS-4118
                     P_INS_USER,
                     P_INS_USER,
                     V_ERR_MSG,
                     V_CURR_CODE ,
                     --Sn Added by Pankaj S. on 25_Feb_13 for logging to_card details
                     V_TOACCT_BAL,    --V_TOACCT_BAL+P_TXN_AMT,  -- Modified for Mantis Id : 0012102
                     V_TOLEDGER_BAL,  --V_TOLEDGER_BAL+P_TXN_AMT,  -- Modified for Mantis Id : 0012102
                     --En Added by Pankaj S. on 25_Feb_13 for logging to_card details
                     'System', --Added on 16-April-2013 for defect 754--Modified by Dnyaneshwar J on 09 May 2013
                     V_FRMACCT_TYPE, -- Added on 17-Apr-2013 for defect 10871
                     v_timestamp     -- Added on 17-Apr-2013 for defect 10871
                     );

             EXCEPTION
               WHEN OTHERS THEN

                P_RESP_CODE := '21';
                P_RESP_MSG  := 'Problem while inserting data into transactionlog' ||
                            SUBSTR(SQLERRM, 1, 100);
                   RAISE EXP_REJECT_RECORD;
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
                    CTD_ADDR_VERIFY_RESPONSE)
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
                    'Y',
                    V_ERR_MSG,
                    P_RRN,
                    NULL,       --P_STAN
                    SYSDATE,
                    P_INST_CODE,
                    P_INS_USER,
                    SYSDATE,
                    P_INS_USER,
                    V_ENCR_PAN_FROM,
                    '000',
                    '',
                    V_FROMACCT_NO,
                    ''
                   );

                 --P_RESP_MSG := V_ERR_MSG;

             EXCEPTION
                 WHEN OTHERS THEN
                   P_RESP_MSG  := 'Problem while inserting data into transaction log  dtl' ||
                               SUBSTR(SQLERRM, 1, 100);
                   P_RESP_CODE := '89';
                   RETURN;
             END;


     end if;




EXCEPTION --<< MAIN EXCEPTION>>
WHEN EXP_AUTH_REJECT_RECORD
THEN

    PRM_FROM_ACCTBAL := NVL(TO_CHAR (V_FRMACCT_BAL, '99,99,99,990.99'),'0.00');
    PRM_FROM_LEDGBAL := NVL(TO_CHAR (V_FRMLEDGER_BAL, '99,99,99,990.99'),'0.00');

    P_RESP_CODE := V_RESP_CDE;
    P_RESP_MSG  := V_ERR_MSG;

      --Sn update topup card number in translog
      BEGIN
          select (add_months(trunc(sysdate,'MM'),'-'||RETENTION_PERIOD))
       INTO   v_Retperiod 
       FROM DBA_OPERATIONS.ARCHIVE_MGMNT_CTL 
       WHERE  OPERATION_TYPE='ARCHIVE' 
       AND OBJECT_NAME='TRANSACTIONLOG_EBR';
	   
	   v_Retdate := TO_DATE(SUBSTR(TRIM(P_TRAN_DATE), 1, 8), 'yyyymmdd');

      
IF (v_Retdate>v_Retperiod)
    THEN
            UPDATE TRANSACTIONLOG
              SET TOPUP_CARD_NO       = V_HASH_PAN_TO,
                  TOPUP_CARD_NO_ENCR  = V_ENCR_PAN_TO,
                  TOPUP_ACCT_NO       = V_TOACCT_NO,
                  TOPUP_ACCT_TYPE     = V_TOACCT_TYPE,
                  IPADDRESS           = P_IPADDRESS,
                  ORGNL_CARD_NO       = V_HASH_PAN_FROM,
                  ORGNL_RRN           = V_ORGNL_RRN,
                  ORGNL_BUSINESS_DATE = V_ORGNL_DATE,
                  ORGNL_BUSINESS_TIME = V_ORGL_TIME,
                  REASON              = P_REASON,
                  REMARK              = DECODE(P_TXN_CODE,
								  '39',
								  NVL2(P_REMARK,P_REMARK||CHR(13) || CHR(10) ||'From Account No : ' ||
								  FN_MASK_ACCT(V_FROMACCT_NO) || ' ' ||
								  'To Account No : ' ||
								  FN_MASK_ACCT(V_TOACCT_NO),'From Account No : ' ||
								  FN_MASK_ACCT(V_FROMACCT_NO) || ' ' ||
								  'To Account No : ' ||
								  FN_MASK_ACCT(V_TOACCT_NO)),
								  P_REMARK),--changed for FSS-4118
                  ADD_LUPD_USER       = P_INS_USER,
                  TRAN_CURR           = V_CURR_CODE,
                  --Sn Added by Pankaj S. on 25_Feb_13 for logging to_card details
                  topup_acct_balance  = V_TOACCT_BAL,
                  topup_ledger_balance =V_TOLEDGER_BAL,
                  --En Added by Pankaj S. on 25_Feb_13 for logging to_card details
                  MERCHANT_NAME = 'System'--Added on 16-April-2013 for defect 754--Modified by Dnyaneshwar J on 09 May 2013
            WHERE RRN = P_RRN
            AND DELIVERY_CHANNEL = P_DELIVERY_CHANNEL
            AND TXN_CODE         = P_TXN_CODE
            AND BUSINESS_DATE    = P_TRAN_DATE
            AND BUSINESS_TIME    = P_TRAN_TIME
            AND CUSTOMER_CARD_NO = V_HASH_PAN_FROM;
        else
                UPDATE VMSCMS_HISTORY.TRANSACTIONLOG_HIST --Added for VMS-5733/FSP-991
              SET TOPUP_CARD_NO       = V_HASH_PAN_TO,
                  TOPUP_CARD_NO_ENCR  = V_ENCR_PAN_TO,
                  TOPUP_ACCT_NO       = V_TOACCT_NO,
                  TOPUP_ACCT_TYPE     = V_TOACCT_TYPE,
                  IPADDRESS           = P_IPADDRESS,
                  ORGNL_CARD_NO       = V_HASH_PAN_FROM,
                  ORGNL_RRN           = V_ORGNL_RRN,
                  ORGNL_BUSINESS_DATE = V_ORGNL_DATE,
                  ORGNL_BUSINESS_TIME = V_ORGL_TIME,
                  REASON              = P_REASON,
                  REMARK              = DECODE(P_TXN_CODE,
								  '39',
								  NVL2(P_REMARK,P_REMARK||CHR(13) || CHR(10) ||'From Account No : ' ||
								  FN_MASK_ACCT(V_FROMACCT_NO) || ' ' ||
								  'To Account No : ' ||
								  FN_MASK_ACCT(V_TOACCT_NO),'From Account No : ' ||
								  FN_MASK_ACCT(V_FROMACCT_NO) || ' ' ||
								  'To Account No : ' ||
								  FN_MASK_ACCT(V_TOACCT_NO)),
								  P_REMARK),--changed for FSS-4118
                  ADD_LUPD_USER       = P_INS_USER,
                  TRAN_CURR           = V_CURR_CODE,
                  --Sn Added by Pankaj S. on 25_Feb_13 for logging to_card details
                  topup_acct_balance  = V_TOACCT_BAL,
                  topup_ledger_balance =V_TOLEDGER_BAL,
                  --En Added by Pankaj S. on 25_Feb_13 for logging to_card details
                  MERCHANT_NAME = 'System'--Added on 16-April-2013 for defect 754--Modified by Dnyaneshwar J on 09 May 2013
            WHERE RRN = P_RRN
            AND DELIVERY_CHANNEL = P_DELIVERY_CHANNEL
            AND TXN_CODE         = P_TXN_CODE
            AND BUSINESS_DATE    = P_TRAN_DATE
            AND BUSINESS_TIME    = P_TRAN_TIME
            AND CUSTOMER_CARD_NO = V_HASH_PAN_FROM;    
    end if;
    
        IF SQL%ROWCOUNT <> 1
        THEN
         P_RESP_CODE := '89';
         P_RESP_MSG  := 'For authfail, Transactionlog not updated for topup card details';
         raise EXP_REJECT_RECORD;
        END IF;

      EXCEPTION WHEN EXP_REJECT_RECORD
      THEN
           RETURN;

      WHEN OTHERS THEN
         P_RESP_CODE := '89';
         P_RESP_MSG  := 'Error while updating transactionlog ' ||
                    SUBSTR(SQLERRM, 1, 200);
         return;

      END;

WHEN EXP_REJECT_RECORD THEN
ROLLBACK ;--TO V_CTOC_SAVEPOINT;

    PRM_FROM_ACCTBAL := NVL(TO_CHAR (V_FRMACCT_BAL, '99,99,99,990.99'),'0.00');
    PRM_FROM_LEDGBAL := NVL(TO_CHAR (V_FRMLEDGER_BAL, '99,99,99,990.99'),'0.00');


   IF P_TXN_CODE <> 38
   THEN

        BEGIN                         --added aby amit on 14-Nov-2012
              update cms_c2ctxfr_transaction
              set    cct_txn_status = decode(cct_txn_status,'A',cct_txn_status,'R',cct_txn_status,'E'),--Added by Narsing I on 04 Mar 2014 for Mantis-13847
              -- SN : Added on 27-DEC-2012 by Ganesh S. for logging approver remarks, approving user and date
                     cct_approver_remarks = P_REMARK,
                     cct_approver_user = P_INS_USER,
                     cct_approval_date = sysdate,
                     -- EN : Added on 27-DEC-2012 by Ganesh S. for logging approver remarks, approving user and date
                     cct_response_id = v_resp_cde    --Added on 03-JAN-2013 by Sachin P. to capture Response Id
              where  CCT_REQUEST_ID = p_orgnl_req_id;

              if sql%rowcount=0 then
                P_RESP_CODE :='89';
                P_RESP_MSG  :='Request not found in que table to mark as error';
                raise EXP_REJECT_RECORD;
              END IF;

        Exception
          when exp_reject_record
          then
            RETURN;
          when others
          THEN
            P_RESP_CODE :='21';
            P_RESP_MSG :='Error while updating status error flag in que table '||substr(sqlerrm,1,200);
            RETURN;
        END;

   END IF;


    BEGIN
     SELECT CAM_ACCT_BAL, CAM_LEDGER_BAL,
            CAM_TYPE_CODE
       INTO V_ACCT_BALANCE, V_LEDGER_BALANCE,
            V_FRMACCT_TYPE
       FROM CMS_ACCT_MAST
      WHERE CAM_ACCT_NO =
           (SELECT CAP_ACCT_NO
             FROM CMS_APPL_PAN
            WHERE CAP_PAN_CODE = V_HASH_PAN_FROM AND
                 CAP_INST_CODE = P_INST_CODE) AND
           CAM_INST_CODE = P_INST_CODE;

    PRM_FROM_ACCTBAL := NVL(TO_CHAR (V_ACCT_BALANCE, '99,99,99,990.99'),'0.00');--added by Narsing I on 04 Mar 2014 for Mantis-13847
    PRM_FROM_LEDGBAL := NVL(TO_CHAR (V_LEDGER_BALANCE, '99,99,99,990.99'),'0.00');--added by Narsing I on 04 Mar 2014 for Mantis-13847

    EXCEPTION
     WHEN OTHERS THEN
       V_ACCT_BALANCE   := 0;
       V_LEDGER_BALANCE := 0;
    END;

    BEGIN

      SELECT CMS_ISO_RESPCDE
      INTO P_RESP_CODE
      FROM CMS_RESPONSE_MAST
      WHERE CMS_INST_CODE        = P_INST_CODE
      AND   CMS_DELIVERY_CHANNEL = P_DELIVERY_CHANNEL
      AND   CMS_RESPONSE_ID      = V_RESP_CDE;

     P_RESP_MSG := V_ERR_MSG;

    EXCEPTION
     WHEN OTHERS THEN
       P_RESP_MSG  := 'Problem while selecting data from response master2 ' ||
                   V_RESP_CDE || SUBSTR(SQLERRM, 1, 300);
       P_RESP_CODE := '69';
         RETURN;
    END;

     -----------------------------------------------
     --SN: Added on 18-Apr-2013 for defect 10871
     -----------------------------------------------

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

     -----------------------------------------------
     --EN: Added on 18-Apr-2013 for defect 10871
     -----------------------------------------------



   v_timestamp := systimestamp;      -- Added on 18-Apr-2013 for defect 10871

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
         ORGNL_CARD_NO,
         ORGNL_RRN,
         ORGNL_BUSINESS_DATE,
         ORGNL_BUSINESS_TIME,
         CR_DR_FLAG,
         REASON,
         REMARK,
         add_ins_user,
         add_lupd_user,
         error_msg,
         --Sn Added by Pankaj S. on 25_Feb_13 for logging to_card details
         topup_acct_balance,
         topup_ledger_balance,
         --En Added by Pankaj S. on 25_Feb_13 for logging to_card details
         MERCHANT_NAME, --Added on 16-April-2013 for defect 754
         ACCT_TYPE,     -- Added on 17-Apr-2013 for defect 10871
         TIME_STAMP     -- Added on 17-Apr-2013 for defect 10871
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
         V_TOACCT_NO,
         V_TOACCT_TYPE,
         P_INST_CODE,
         TRIM(TO_CHAR(NVL(V_TXN_AMT,0), '99999999999999999.99')),   -- NVL added on 17-Apr-2013 for defect 10871
         P_CURR_CODE,
         NULL,
         V_FROM_PRODCODE,               --Added on 18-Apr-2013 for defect 10871
         V_FROM_CARDTYPE,               --Added on 18-Apr-2013 for defect 10871
         0,
         V_CTOC_AUTH_ID,
         TRIM(TO_CHAR(NVL(V_TXN_AMT,0), '99999999999999999.99')),   -- NVL added on 17-Apr-2013 for defect 10871
         '0.00',                                                    -- NULL replaced by 0.00 , on 17-Apr-2013 for defect 10871
         '0.00',                                                    -- NULL replaced by 0.00 , on 17-Apr-2013 for defect 10871
         P_INST_CODE,
         V_ENCR_PAN_FROM,
         V_ENCR_PAN_TO,
         '',
         0,
         V_FROMACCT_NO,
         V_ACCT_BALANCE,
         V_LEDGER_BALANCE,
         --P_RESP_CODE,
         V_RESP_CDE,
         NULL,  --P_ANI
         NULL,  --P_DNI
         P_IPADDRESS,
         V_FROMCARDSTAT,
         V_TRANS_DESC,
         DECODE(P_TXN_CODE,'39',V_HASH_PAN_FROM,'40',V_HASH_PAN_FROM,NULL),
         DECODE(P_TXN_CODE,'39',V_ORGNL_RRN,'40',V_ORGNL_RRN,NULL),
         DECODE(P_TXN_CODE,'39',V_ORGNL_DATE,'40',V_ORGNL_DATE,NULL),
         DECODE(P_TXN_CODE,'39',V_ORGL_TIME,'40',V_ORGL_TIME,NULL),
         V_DR_CR_FLAG,
         P_REASON,
         DECODE(P_TXN_CODE,
								  '39',
								  NVL2(P_REMARK,P_REMARK||CHR(13) || CHR(10) ||'From Account No : ' ||
								  FN_MASK_ACCT(V_FROMACCT_NO) || ' ' ||
								  'To Account No : ' ||
								  FN_MASK_ACCT(V_TOACCT_NO),'From Account No : ' ||
								  FN_MASK_ACCT(V_FROMACCT_NO) || ' ' ||
								  'To Account No : ' ||
								  FN_MASK_ACCT(V_TOACCT_NO)),
								  P_REMARK),--changed for FSS-4118

         P_INS_USER,
         P_INS_USER,
         V_ERR_MSG ,
         --Sn Added by Pankaj S. on 25_Feb_13 for logging to_card details
         V_TOACCT_BAL,
         V_TOLEDGER_BAL,
         --En Added by Pankaj S. on 25_Feb_13 for logging to_card details
         'System', --Added on 16-April-2013 for defect 754--Modified by Dnyaneshwar J on 09 May 2013
         v_frmacct_type,
         v_timestamp
         );

    EXCEPTION
       WHEN OTHERS THEN

        P_RESP_CODE := '89';
        P_RESP_MSG  := 'Problem while inserting data into transactionlog1' ||
                    SUBSTR(SQLERRM, 1, 100);
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
        CTD_ADDR_VERIFY_RESPONSE)
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
        NULL,       --P_STAN
        SYSDATE,
        P_INST_CODE,
        P_INS_USER,
        SYSDATE,
        P_INS_USER,
        V_ENCR_PAN_FROM,
        '000',
        '',
        V_ACCT_NUMBER,
        ''
       );

    EXCEPTION
     WHEN OTHERS THEN
       P_RESP_MSG  := 'Problem while inserting data into transaction log  dtl1' ||
                   SUBSTR(SQLERRM, 1, 100);
       P_RESP_CODE := '89';
       RETURN;
    END;

WHEN OTHERS THEN

    ROLLBACK ;

    PRM_FROM_ACCTBAL := NVL(TO_CHAR (V_FRMACCT_BAL, '99,99,99,990.99'),'0.00');
    PRM_FROM_LEDGBAL := NVL(TO_CHAR (V_FRMLEDGER_BAL, '99,99,99,990.99'),'0.00');

    V_RESP_CDE := '69';
    V_ERR_MSG  := 'Error from transaction processing ' ||SUBSTR(SQLERRM, 1, 90);


   IF P_TXN_CODE <> 38
   THEN

        BEGIN
              UPDATE CMS_C2CTXFR_TRANSACTION
              set    cct_txn_status = decode(cct_txn_status,'A',cct_txn_status,'R',cct_txn_status,'E'),--Added by Narsing I on 04 Mar 2014 for Mantis-13847
              -- SN : Added on 27-DEC-2012 by Ganesh S. for logging approver remarks, approving user and date
                     cct_approver_remarks = P_REMARK,
                     cct_approver_user = P_INS_USER,
                     cct_approval_date = sysdate,
                     -- EN : Added on 27-DEC-2012 by Ganesh S. for logging approver remarks, approving user and date
                     cct_response_id = v_resp_cde       --Added on 03-JAN-2013 by Sachin P. to capture Response Id
              where  CCT_REQUEST_ID = p_orgnl_req_id;

              if sql%rowcount=0 then
                P_RESP_CODE :='89';
                P_RESP_MSG  :='Exception: Request not found in que table to mark as error';
                raise EXP_REJECT_RECORD;
              END IF;

        Exception
          when exp_reject_record
          then
            RETURN;
          when others
          THEN
            P_RESP_CODE :='89';
            P_RESP_MSG  :='Error while updating status error flag in que table '||substr(sqlerrm,1,200);
            RETURN;
        END;

   END IF;


    BEGIN

     SELECT CAM_ACCT_BAL, CAM_LEDGER_BAL,
            CAM_TYPE_CODE                               --Added on 18-Apr-2013 for defect 10871
       INTO V_ACCT_BALANCE, V_LEDGER_BALANCE,
            V_FRMACCT_TYPE                              --Added on 18-Apr-2013 for defect 10871
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

    BEGIN

      SELECT CMS_ISO_RESPCDE
      INTO P_RESP_CODE
      FROM CMS_RESPONSE_MAST
      WHERE CMS_INST_CODE        = P_INST_CODE
      AND   CMS_DELIVERY_CHANNEL = P_DELIVERY_CHANNEL
      AND   CMS_RESPONSE_ID      = V_RESP_CDE;

     P_RESP_MSG := V_ERR_MSG;

    EXCEPTION
     WHEN OTHERS THEN
       P_RESP_MSG  := 'Problem while selecting data from response master3 '
                     || V_RESP_CDE || SUBSTR(SQLERRM, 1, 300);
       P_RESP_CODE := '69';
         RETURN;
    END;

     -----------------------------------------------
     --SN: Added on 18-Apr-2013 for defect 10871
     -----------------------------------------------

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

     -----------------------------------------------
     --EN: Added on 18-Apr-2013 for defect 10871
     -----------------------------------------------



   v_timestamp := systimestamp;      -- Added on 18-Apr-2013 for defect 10871


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
         CARDSTATUS, --Added cardstatus insert in transactionlog by srinivasu.k
         TRANS_DESC, -- FOR Transaction detail report issue
         ORGNL_CARD_NO,
         ORGNL_RRN,
         ORGNL_BUSINESS_DATE,
         ORGNL_BUSINESS_TIME,
         CR_DR_FLAG,
         REASON,
         REMARK,
         add_ins_user,
         add_lupd_user,
         error_msg,
         --Sn Added by Pankaj S. on 25_Feb_13 for logging to_card details
         topup_acct_balance ,
         topup_ledger_balance,
         --En Added by Pankaj S. on 25_Feb_13 for logging to_card details
         MERCHANT_NAME, --Added on 16-April-2013 for defect 754
         ACCT_TYPE,     --Added on 16-April-2013 for defect 10871
         TIME_STAMP     --Added on 16-April-2013 for defect 10871
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
         V_TOACCT_NO,
         V_TOACCT_TYPE,
         P_INST_CODE,
         TRIM(TO_CHAR(V_TXN_AMT, '99999999999999999.99')),
         P_CURR_CODE,
         NULL,
         V_FROM_PRODCODE,           --Added on 18-Apr-2013 for defect 10871
         V_FROM_CARDTYPE,           --Added on 18-Apr-2013 for defect 10871
         0,
         V_CTOC_AUTH_ID,
         TRIM(TO_CHAR(V_TXN_AMT, '99999999999999999.99')),
         NULL,
         NULL,
         P_INST_CODE,
         V_ENCR_PAN_FROM,
         V_ENCR_PAN_TO,
         '',
         0,
         V_FROMACCT_NO,
         V_ACCT_BALANCE,
         V_LEDGER_BALANCE,
         --P_RESP_CODE,
         V_RESP_CDE,
         NULL,  --P_ANI
         NULL,  --P_DNI
         P_IPADDRESS,
         V_FROMCARDSTAT,
         V_TRANS_DESC,
         DECODE(P_TXN_CODE,'39',V_HASH_PAN_FROM,'40',V_HASH_PAN_FROM,NULL),
         DECODE(P_TXN_CODE,'39',V_ORGNL_RRN,'40',V_ORGNL_RRN,NULL),
         DECODE(P_TXN_CODE,'39',V_ORGNL_DATE,'40',V_ORGNL_DATE,NULL),
         DECODE(P_TXN_CODE,'39',V_ORGL_TIME,'40',V_ORGL_TIME,NULL),
         V_DR_CR_FLAG,
         P_REASON,
         DECODE(P_TXN_CODE,
								  '39',
								  NVL2(P_REMARK,P_REMARK||CHR(13) || CHR(10) ||'From Account No : ' ||
								  FN_MASK_ACCT(V_FROMACCT_NO) || ' ' ||
								  'To Account No : ' ||
								  FN_MASK_ACCT(V_TOACCT_NO),'From Account No : ' ||
								  FN_MASK_ACCT(V_FROMACCT_NO) || ' ' ||
								  'To Account No : ' ||
								  FN_MASK_ACCT(V_TOACCT_NO)),
								  P_REMARK),--changed for FSS-4118
         P_INS_USER,
         P_INS_USER,
         V_ERR_MSG,
         --Sn Added by Pankaj S. on 25_Feb_13 for logging to_card details
         V_TOACCT_BAL,
         V_TOLEDGER_BAL,
         --En Added by Pankaj S. on 25_Feb_13 for logging to_card details
         'System', --Added on 16-April-2013 for defect 754--Modified by Dnyaneshwar J on 09 May 2013
         V_FRMACCT_TYPE, --Added on 16-April-2013 for defect 10871
         V_TIMESTAMP     --Added on 16-April-2013 for defect 10871
         );

     EXCEPTION
       WHEN OTHERS THEN

        P_RESP_CODE := '89';
        P_RESP_MSG  := 'Problem while inserting data into transactionlog2' ||
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
        CTD_ADDR_VERIFY_RESPONSE)
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
        NULL,       --P_STAN
        SYSDATE,
        P_INST_CODE,
        P_INS_USER,
        SYSDATE,
        P_INS_USER,
        V_ENCR_PAN_FROM,
        '000',
        '',
        V_ACCT_NUMBER,
        ''
        );

     EXCEPTION
     WHEN OTHERS THEN
       P_RESP_MSG  := 'Problem while inserting data into transaction log dtl2' ||
                   SUBSTR(SQLERRM, 1, 300);
       P_RESP_CODE := '89';
       RETURN;
     END;

END;

/
show error