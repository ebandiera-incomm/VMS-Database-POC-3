CREATE OR REPLACE PROCEDURE VMSCMS.SP_OVERRIDE_ACH_CSR (
                                            p_INST_CODE        IN NUMBER,
                                            p_MSG              IN VARCHAR2,
                                            p_RRN              VARCHAR2,
                                            p_DELIVERY_CHANNEL VARCHAR2,
                                            p_TERM_ID          VARCHAR2,
                                            p_TXN_CODE         VARCHAR2,
                                            p_TXN_MODE  VARCHAR2,
                                            p_TRAN_DATE VARCHAR2,
                                            p_TRAN_TIME VARCHAR2,
                                            p_CARD_NO   VARCHAR2,
                                            p_BANK_CODE VARCHAR2,
                                            p_TXN_AMT   NUMBER,
                                            p_MERCHANT_NAME     VARCHAR2,
                                            p_MERCHANT_CITY     VARCHAR2,
                                            p_MCC_CODE          VARCHAR2,
                                            p_CURR_CODE         VARCHAR2,
                                            p_PROD_ID           VARCHAR2,
                                            p_CATG_ID           VARCHAR2,
                                            p_TIP_AMT           VARCHAR2,
                                            p_TO_ACCT_NO        VARCHAR2,--Added for card to card transfer by removing the p_DECLINE_RULEID as the rule id is not passed
                                            p_ATMNAME_LOC       VARCHAR2,
                                            p_MCCCODE_GROUPID   VARCHAR2,
                                            p_CURRCODE_GROUPID  VARCHAR2,
                                            p_TRANSCODE_GROUPID VARCHAR2,
                                            p_RULES             VARCHAR2,
                                            p_PREAUTH_DATE      DATE,
                                            p_CONSODIUM_CODE    IN VARCHAR2,
                                            p_PARTNER_CODE      IN VARCHAR2,
                                            p_EXPRY_DATE        IN VARCHAR2,
                                            p_STAN              IN VARCHAR2,
                                            p_MBR_NUMB          IN VARCHAR2,
                                            p_RVSL_CODE         IN VARCHAR2,
                                            p_CURR_CONVERT_AMNT IN VARCHAR2,--Added for transactionlog insert
                                            p_ACHFILENAME       IN VARCHAR2,
                                            p_ODFI              IN VARCHAR2,
                                            p_RDFI              IN VARCHAR2,
                                            p_SECCODES          IN VARCHAR2,
                                            p_IMPDATE           IN VARCHAR2,
                                            p_PROCESSDATE       IN VARCHAR2,
                                            p_EFFECTIVEDATE     IN VARCHAR2,
                                            p_TRACENUMBER       IN VARCHAR2,
                                            p_INCOMING_CRFILEID IN VARCHAR2,
                                            p_ACHTRANTYPE_ID    IN VARCHAR2,
                                            p_BEFRETRAN_LEDGERBAL  IN VARCHAR2,
                                            p_BEFRETRAN_AVAILBALANCE IN VARCHAR2,
                                            p_INDIDNUM               IN VARCHAR2,
                                            p_INDNAME                IN VARCHAR2,
                                            p_COMPANYNAME            IN VARCHAR2,
                                            p_COMPANYID              IN VARCHAR2,
                                            p_ACH_ID                 IN VARCHAR2,
                                            p_COMPENTRYDESC          IN VARCHAR2,
                                            p_CUSTOMERLASTNAME       IN VARCHAR2,
                                            p_cardstatus             IN VARCHAR2,
                                            p_PROCESSTYPE      IN VARCHAR2,
                                            p_AUTH_ID      in VARCHAR2,
                                            P_RESP_ID      OUT VARCHAR2,
                                            p_RESP_CODE    OUT VARCHAR2,
                                            p_RESP_MSG     OUT VARCHAR2,
                                            p_CAPTURE_DATE OUT DATE) IS

/*************************************************************************************************
     * Created By       :  Sagar M.
     * Purpose          :  ACH FORCE POST
     * Modified By      :  NA
     * Modified Date    :  MA
     * Modified Reason  :  NA
     * Build Number     : CMS3.5.1_RI0017

     * Modified by      :  Pankaj S.
     * Modified Reason  :  10871
     * Modified Date    :  16-Apr-2013
     * Reviewer         :  Dhiraj
     * Reviewed Date    :
     * Build Number     :  RI0024.1_B0013

     * Modified by      : MageshKumar S.
     * Modified Date    : 25-July-14
     * Modified For     : FWR-48
     * Modified reason  : GL Mapping removal changes
     * Reviewer         : Spankaj
     * Build Number     : RI0027.3.1_B0001
     
         * Modified By      : Saravana Kumar A
    * Modified Date    : 07/07/2017
    * Purpose          : Prod code and card type logging in statements log
    * Reviewer         : Pankaj S. 
    * Release Number   : VMSGPRHOST17.07
    
    * Modified By      : venkat Singamaneni
    * Modified Date    : 4-4-2022
    * Purpose          : Archival changes.
    * Reviewer         : Saravana Kumar A
    * Release Number   : VMSGPRHOST60 for VMS-5733/FSP-991
 *************************************************************************************************/

  V_ERR_MSG          VARCHAR2(900) := 'OK';
  V_ACCT_BALANCE     NUMBER;
  V_TRAN_AMT         NUMBER;
  V_AUTH_ID          TRANSACTIONLOG.AUTH_ID%TYPE;
  V_TOTAL_AMT        NUMBER;
  V_TRAN_DATE        DATE;
  V_FUNC_CODE        CMS_FUNC_MAST.CFM_FUNC_CODE%TYPE;
  V_PROD_CODE        CMS_PROD_MAST.CPM_PROD_CODE%TYPE;
  V_PROD_CATTYPE     CMS_PROD_CATTYPE.CPC_CARD_TYPE%TYPE;
  V_FEE_AMT          NUMBER;
  V_TOTAL_FEE        NUMBER;
  V_UPD_AMT          NUMBER;
  V_NARRATION        VARCHAR2(300);
  V_FEE_OPENING_BAL  NUMBER;
  V_RESP_CDE         VARCHAR2(3);
  V_EXPRY_DATE       DATE;
  V_DR_CR_FLAG       VARCHAR2(2);
  V_OUTPUT_TYPE      VARCHAR2(2);
  V_APPLPAN_CARDSTAT CMS_APPL_PAN.CAP_CARD_STAT%TYPE;
--  V_ATMONLINE_LIMIT  CMS_APPL_PAN.CAP_ATM_ONLINE_LIMIT%TYPE;
--  V_POSONLINE_LIMIT  CMS_APPL_PAN.CAP_ATM_OFFLINE_LIMIT%TYPE;
--  V_PRECHECK_FLAG    NUMBER;
--  V_PREAUTH_FLAG     NUMBER;
  V_GL_UPD_FLAG      TRANSACTIONLOG.GL_UPD_FLAG%TYPE;
  V_GL_ERR_MSG       VARCHAR2(500);
  V_SAVEPOINT        NUMBER := 0;
  V_TRAN_FEE         NUMBER;
  V_ERROR            VARCHAR2(500);
  V_BUSINESS_DATE    DATE;
  V_BUSINESS_TIME    VARCHAR2(5);
  V_CUTOFF_TIME      VARCHAR2(5);
  V_CARD_CURR        VARCHAR2(5);
  V_FEE_CODE         CMS_FEE_MAST.CFM_FEE_CODE%TYPE;
  V_FEE_CRGL_CATG    CMS_PRODCATTYPE_FEES.CPF_CRGL_CATG%TYPE;
  V_FEE_CRGL_CODE    CMS_PRODCATTYPE_FEES.CPF_CRGL_CODE%TYPE;
  V_FEE_CRSUBGL_CODE CMS_PRODCATTYPE_FEES.CPF_CRSUBGL_CODE%TYPE;
  V_FEE_CRACCT_NO    CMS_PRODCATTYPE_FEES.CPF_CRACCT_NO%TYPE;
  V_FEE_DRGL_CATG    CMS_PRODCATTYPE_FEES.CPF_DRGL_CATG%TYPE;
  V_FEE_DRGL_CODE    CMS_PRODCATTYPE_FEES.CPF_DRGL_CODE%TYPE;
  V_FEE_DRSUBGL_CODE CMS_PRODCATTYPE_FEES.CPF_DRSUBGL_CODE%TYPE;
  V_FEE_DRACCT_NO    CMS_PRODCATTYPE_FEES.CPF_DRACCT_NO%TYPE;
  --st AND cess
  V_SERVICETAX_PERCENT CMS_INST_PARAM.CIP_PARAM_VALUE%TYPE;
  V_CESS_PERCENT       CMS_INST_PARAM.CIP_PARAM_VALUE%TYPE;
  V_SERVICETAX_AMOUNT  NUMBER;
  V_CESS_AMOUNT        NUMBER;
  V_ST_CALC_FLAG       CMS_PRODCATTYPE_FEES.CPF_ST_CALC_FLAG%TYPE;
  V_CESS_CALC_FLAG     CMS_PRODCATTYPE_FEES.CPF_CESS_CALC_FLAG%TYPE;
  V_ST_CRACCT_NO       CMS_PRODCATTYPE_FEES.CPF_ST_CRACCT_NO%TYPE;
  V_ST_DRACCT_NO       CMS_PRODCATTYPE_FEES.CPF_ST_DRACCT_NO%TYPE;
  V_CESS_CRACCT_NO     CMS_PRODCATTYPE_FEES.CPF_CESS_CRACCT_NO%TYPE;
  V_CESS_DRACCT_NO     CMS_PRODCATTYPE_FEES.CPF_CESS_DRACCT_NO%TYPE;
  --
  V_WAIV_PERCNT      CMS_PRODCATTYPE_WAIV.CPW_WAIV_PRCNT%TYPE;
  V_ERR_WAIV         VARCHAR2(300);
  V_LOG_ACTUAL_FEE   NUMBER;
  V_LOG_WAIVER_AMT   NUMBER;
  V_AUTH_SAVEPOINT   NUMBER DEFAULT 0;
  V_ACTUAL_EXPRYDATE DATE;
  V_TXN_TYPE         NUMBER(1);
  V_MINI_TOTREC      NUMBER(2);
  V_MINISTMT_ERRMSG  VARCHAR2(500);
  V_MINISTMT_OUTPUT  VARCHAR2(900);
  V_FEE_ATTACH_TYPE  VARCHAR2(1);
  EXP_REJECT_RECORD EXCEPTION;
  V_LEDGER_BAL     NUMBER;
  V_CARD_ACCT_NO   VARCHAR2(20);
  V_HASH_PAN       CMS_APPL_PAN.CAP_PAN_CODE%TYPE;
  V_ENCR_PAN       CMS_APPL_PAN.CAP_PAN_CODE_ENCR%TYPE;
--  V_MAX_CARD_BAL   NUMBER;
--  V_MIN_ACT_AMT    NUMBER; --added for minimum activation amount check
  V_CURR_DATE      DATE;
  V_UPD_LEDGER_BAL NUMBER;
  V_PROXUNUMBER    CMS_APPL_PAN.CAP_PROXY_NUMBER%TYPE;
  V_ACCT_NUMBER    CMS_APPL_PAN.CAP_ACCT_NO%TYPE;
  V_TRANS_DESC     VARCHAR2(50);
  V_STATUS_CHK            NUMBER;
--  v_appliocationprocess_stat   VARCHAR2 (3);

  V_FEEAMNT_TYPE          CMS_FEE_MAST.CFM_FEEAMNT_TYPE%TYPE;
  V_PER_FEES              CMS_FEE_MAST.CFM_PER_FEES%TYPE;
  V_FLAT_FEES             CMS_FEE_MAST.CFM_FEE_AMT%TYPE;
  V_CLAWBACK              CMS_FEE_MAST.CFM_CLAWBACK_FLAG%TYPE;
  V_FEE_PLAN              CMS_FEE_FEEPLAN.CFF_FEE_PLAN%TYPE;
  V_CLAWBACK_AMNT         CMS_FEE_MAST.CFM_FEE_AMT%TYPE;
  V_FREETXN_EXCEED VARCHAR2(1);
  V_DURATION VARCHAR2(20);
  V_FEEATTACH_TYPE  VARCHAR2(2);
  --Sn added by Pankaj S. for 10871
  v_timestamp  timestamp(3);
  v_acct_type  cms_acct_mast.cam_type_code%TYPE;
  --En added by Pankaj S. for 10871
  V_FEE_DESC                    cms_fee_mast.cfm_fee_desc%TYPE; -- Added for MVCSD-4471
  
  v_Retperiod  date; --Added for VMS-5733/FSP-991
  v_Retdate  date; --Added for VMS-5733/FSP-991

 BEGIN
  SAVEPOINT V_AUTH_SAVEPOINT;
  V_RESP_CDE   := '1';
  P_RESP_MSG := 'OK';
  V_TRAN_AMT   := NVL(P_CURR_CONVERT_AMNT,0);  --NVL added by Pankaj S. for 10871


  BEGIN

    --SN CREATE HASH PAN
    BEGIN
     V_HASH_PAN := GETHASH(p_CARD_NO);
    EXCEPTION
     WHEN OTHERS THEN
       V_ERR_MSG := 'Error while converting pan ' ||
                 SUBSTR(SQLERRM, 1, 200);
       RAISE EXP_REJECT_RECORD;
    END;
    --EN CREATE HASH PAN

    --SN create encr pan
    BEGIN
     V_ENCR_PAN := FN_EMAPS_MAIN(p_CARD_NO);
    EXCEPTION
     WHEN OTHERS THEN
       V_ERR_MSG := 'Error while converting pan ' ||
                 SUBSTR(SQLERRM, 1, 200);
       RAISE EXP_REJECT_RECORD;
    END;
    --EN create encr pan

      /* -- commented by sagar 17sep2012 as same is redundant and checked below
        BEGIN
         SELECT CTM_TRAN_DESC
           INTO V_TRANS_DESC
           FROM CMS_TRANSACTION_MAST
          WHERE CTM_TRAN_CODE = p_TXN_CODE AND
               CTM_DELIVERY_CHANNEL = p_DELIVERY_CHANNEL AND
               CTM_INST_CODE = p_INST_CODE;
        EXCEPTION
         WHEN NO_DATA_FOUND THEN
           V_TRANS_DESC := 'Transaction type ' || p_TXN_CODE;
         WHEN OTHERS THEN

           V_RESP_CDE := '21';
           V_ERR_MSG  := 'Error in finding the narration ' ||
                      SUBSTR(SQLERRM, 1, 200);
           RAISE EXP_REJECT_RECORD;

        END;
       */ -- commented by sagar 17sep2012 as same is redundant and checked below


        --Sn find debit and credit flag
        BEGIN
         SELECT CTM_CREDIT_DEBIT_FLAG,
               CTM_OUTPUT_TYPE,
               TO_NUMBER(DECODE(CTM_TRAN_TYPE, 'N', '0', 'F', '1')),
               CTM_TRAN_DESC
           INTO V_DR_CR_FLAG, V_OUTPUT_TYPE, V_TXN_TYPE,V_TRANS_DESC
           FROM CMS_TRANSACTION_MAST
          WHERE CTM_TRAN_CODE = p_TXN_CODE AND
               CTM_DELIVERY_CHANNEL = p_DELIVERY_CHANNEL AND
               CTM_INST_CODE = p_INST_CODE;
        EXCEPTION
         WHEN NO_DATA_FOUND THEN
           V_RESP_CDE := '21'; --Ineligible Transaction
           V_ERR_MSG  := 'Transflag  not defined for txn code ' ||
                      p_TXN_CODE || ' and delivery channel ' ||
                      p_DELIVERY_CHANNEL;
           RAISE EXP_REJECT_RECORD;
         WHEN OTHERS THEN
           V_RESP_CDE := '21'; --Ineligible Transaction
           V_ERR_MSG  := 'Error while selecting transflag ' ||
                      SUBSTR(SQLERRM, 1, 200);
           RAISE EXP_REJECT_RECORD;
        END;

        --En find debit and credit flag


       V_AUTH_ID :=p_AUTH_ID;
        --sN CHECK INST CODE
        BEGIN

             IF p_INST_CODE IS NULL THEN
               V_RESP_CDE := '21';
               V_ERR_MSG  := 'Institute code cannot be null ';
               RAISE EXP_REJECT_RECORD;
             END IF;

        EXCEPTION
         WHEN EXP_REJECT_RECORD THEN
           RAISE;
         WHEN OTHERS THEN
           V_RESP_CDE := '21';
           V_ERR_MSG  := 'Error while selecting Institute code ' ||
                      SUBSTR(SQLERRM, 1, 200);
           RAISE EXP_REJECT_RECORD;
        END;

    --eN CHECK INST CODE

    --Sn check txn currency
    BEGIN

         IF TRIM(p_CURR_CODE) IS NULL THEN
           V_RESP_CDE := '21';
           V_ERR_MSG  := 'Transaction currency  cannot be null ';
           RAISE EXP_REJECT_RECORD;
         END IF;

    EXCEPTION
     WHEN EXP_REJECT_RECORD THEN
       RAISE;
     WHEN OTHERS THEN
       V_RESP_CDE := '21';
       V_ERR_MSG  := 'Error while selecting Transcurrency  ' ||
                  SUBSTR(SQLERRM, 1, 200);
       RAISE EXP_REJECT_RECORD;
    END;

    --En check txn currency

    --Sn get date
    BEGIN
     V_TRAN_DATE := TO_DATE(SUBSTR(TRIM(p_TRAN_DATE), 1, 8) || ' ' ||
                        SUBSTR(TRIM(p_TRAN_TIME), 1, 10),
                        'yyyymmdd hh24:mi:ss');
    EXCEPTION
     WHEN OTHERS THEN
       V_RESP_CDE := '21';
       V_ERR_MSG  := 'Problem while converting transaction date ' ||
                  SUBSTR(SQLERRM, 1, 200);
       RAISE EXP_REJECT_RECORD;
    END;

    --En get date
    --Sn find service tax
    BEGIN
     SELECT CIP_PARAM_VALUE
       INTO V_SERVICETAX_PERCENT
       FROM CMS_INST_PARAM
      WHERE CIP_PARAM_KEY = 'SERVICETAX' AND CIP_INST_CODE = p_INST_CODE;
    EXCEPTION
     WHEN NO_DATA_FOUND THEN
       V_RESP_CDE := '21';
       V_ERR_MSG  := 'Service Tax is  not defined in the system';
       RAISE EXP_REJECT_RECORD;
     WHEN OTHERS THEN
       V_RESP_CDE := '21';
       V_ERR_MSG  := 'Error while selecting service tax from system ';
       RAISE EXP_REJECT_RECORD;
    END;

    --En find service tax

    --Sn find cess
    BEGIN
     SELECT CIP_PARAM_VALUE
       INTO V_CESS_PERCENT
       FROM CMS_INST_PARAM
      WHERE CIP_PARAM_KEY = 'CESS' AND CIP_INST_CODE = p_INST_CODE;
    EXCEPTION
     WHEN NO_DATA_FOUND THEN
       V_RESP_CDE := '21';
       V_ERR_MSG  := 'Cess is not defined in the system';
       RAISE EXP_REJECT_RECORD;
     WHEN OTHERS THEN
       V_RESP_CDE := '21';
       V_ERR_MSG  := 'Error while selecting cess from system ';
       RAISE EXP_REJECT_RECORD;
    END;

    --En find cess

    ---Sn find cutoff time
        BEGIN
         SELECT CIP_PARAM_VALUE
           INTO V_CUTOFF_TIME
           FROM CMS_INST_PARAM
          WHERE CIP_PARAM_KEY = 'CUTOFF' AND CIP_INST_CODE = p_INST_CODE;
        EXCEPTION
         WHEN NO_DATA_FOUND THEN
           V_CUTOFF_TIME := 0;
           V_RESP_CDE    := '21';
           V_ERR_MSG     := 'Cutoff time is not defined in the system';
           RAISE EXP_REJECT_RECORD;
         WHEN OTHERS THEN
           V_RESP_CDE := '21';
           V_ERR_MSG  := 'Error while selecting cutoff  dtl  from system ';
           RAISE EXP_REJECT_RECORD;
        END;

        ---En find cutoff time

   -------------------------------------------------------------
      /* -- not required to check for ach force post txn
   -------------------------------------------------------------

       --Sn select authorization processe flag
        BEGIN
         SELECT PTP_PARAM_VALUE
           INTO V_PRECHECK_FLAG
           FROM PCMS_TRANAUTH_PARAM
          WHERE PTP_PARAM_NAME = 'PRE CHECK' AND PTP_INST_CODE = p_INST_CODE;
        EXCEPTION
         WHEN NO_DATA_FOUND THEN
           V_RESP_CDE := '21'; --only for master setups
           V_ERR_MSG  := 'Master set up is not done for Authorization Process';
           RAISE EXP_REJECT_RECORD;
         WHEN OTHERS THEN
           V_RESP_CDE := '21'; --only for master setups
           V_ERR_MSG  := 'Error while selecting precheck flag' ||
                      SUBSTR(SQLERRM, 1, 200);
           RAISE EXP_REJECT_RECORD;
        END;

        --En select authorization process   flag
        --Sn select authorization processe flag
        BEGIN
         SELECT PTP_PARAM_VALUE
           INTO V_PREAUTH_FLAG
           FROM PCMS_TRANAUTH_PARAM
          WHERE PTP_PARAM_NAME = 'PRE AUTH' AND PTP_INST_CODE = p_INST_CODE;
        EXCEPTION
         WHEN NO_DATA_FOUND THEN
           V_RESP_CDE := '21'; --only for master setups
           V_ERR_MSG  := 'Master set up is not done for Authorization Process';
           RAISE EXP_REJECT_RECORD;
         WHEN OTHERS THEN
           V_RESP_CDE := '21'; --only for master setups
           V_ERR_MSG  := 'Error while selecting preauth flag' ||
                      SUBSTR(SQLERRM, 1, 200);
           RAISE EXP_REJECT_RECORD;
        END;
       --En select authorization process   flag

   -------------------------------------------------------------
     */ -- not required to check for ach force post txn
   -------------------------------------------------------------

        --Sn find card detail
        BEGIN
         SELECT CAP_PROD_CODE,
               CAP_CARD_TYPE,
               TO_CHAR(CAP_EXPRY_DATE, 'DD-MON-YY'),
               CAP_CARD_STAT,
               --CAP_ATM_ONLINE_LIMIT,
               --CAP_POS_ONLINE_LIMIT,
               CAP_PROXY_NUMBER,
               CAP_ACCT_NO
           INTO V_PROD_CODE,
               V_PROD_CATTYPE,
               V_EXPRY_DATE,
               V_APPLPAN_CARDSTAT,
               --V_ATMONLINE_LIMIT,
               --V_ATMONLINE_LIMIT,
               V_PROXUNUMBER,
               V_ACCT_NUMBER
           FROM CMS_APPL_PAN
          WHERE CAP_INST_CODE = p_INST_CODE AND CAP_PAN_CODE = V_HASH_PAN;
        EXCEPTION
         WHEN NO_DATA_FOUND THEN
           V_RESP_CDE := '16'; --Ineligible Transaction
           V_ERR_MSG  := 'Card number not found ' || p_TXN_CODE;
           RAISE EXP_REJECT_RECORD;
         WHEN OTHERS THEN
           V_RESP_CDE := '12';
           V_ERR_MSG  := 'Problem while selecting card detail' ||
                      SUBSTR(SQLERRM, 1, 200);
           RAISE EXP_REJECT_RECORD;
        END;

    --En find card detail

   -------------------------------------------------------------
      /* -- not required to check for ach force post txn
   -------------------------------------------------------------

     --Sn GPR Card status check
      BEGIN
           SP_STATUS_CHECK_GPR(p_INST_CODE,
                        p_CARD_NO,
                        p_DELIVERY_CHANNEL,
                        V_EXPRY_DATE,
                        V_APPLPAN_CARDSTAT,
                        p_TXN_CODE,
                        p_TXN_MODE,
                        V_PROD_CODE,
                        V_PROD_CATTYPE,
                        p_MSG,
                        p_TRAN_DATE,
                        p_TRAN_TIME,
                        V_RESP_CDE,
                        V_ERR_MSG);

           IF ((V_RESP_CDE <> '1' AND V_ERR_MSG <> 'OK') OR (V_RESP_CDE <> '0' AND V_ERR_MSG <> 'OK')) THEN
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
            V_ERR_MSG  := 'Error from GPR Card Status Check ' ||
                        SUBSTR(SQLERRM, 1, 200);
            RAISE EXP_REJECT_RECORD;
      END;
     --En GPR Card status check


      IF V_STATUS_CHK='1' THEN

        -- Expiry Check
            --IF p_DELIVERY_CHANNEL <> '11' THEN -- commented by sagar for override changes

             BEGIN


               IF TO_DATE(p_TRAN_DATE, 'YYYYMMDD') >
                 LAST_DAY(TO_CHAR(V_EXPRY_DATE, 'DD-MON-YY')) THEN

                V_RESP_CDE := '13';
                V_ERR_MSG  := 'EXPIRED CARD';
                RAISE EXP_REJECT_RECORD;

               END IF;

             EXCEPTION

               WHEN EXP_REJECT_RECORD THEN
                RAISE;

               WHEN OTHERS THEN
                V_RESP_CDE := '21';
                V_ERR_MSG  := 'ERROR IN EXPIRY DATE CHECK : Tran Date - ' ||
                            p_TRAN_DATE || ', Expiry Date - ' || V_EXPRY_DATE || ',' ||
                            SUBSTR(SQLERRM, 1, 200);
                RAISE EXP_REJECT_RECORD;




             END;

            -- End Expiry Check
            -- Begin Added by ramkumar.MK on 4 april 4 2012
          -- ELSE


               BEGIN
                     SELECT ccs_CARD_STATUS
                    INTO v_appliocationprocess_stat
                    FROM cms_cardissuance_status
                   WHERE ccs_pan_code = v_hash_pan AND ccs_inst_code = p_INST_CODE;

                  IF v_appliocationprocess_stat <> '15'
                  THEN
                     V_RESP_CDE := '12';                         --Ineligible Transaction
                     V_ERR_MSG := 'INVALID APPLICATION ISSUANCE STATUS';
                     RAISE EXP_REJECT_RECORD;
                  END IF;
               EXCEPTION
                  WHEN NO_DATA_FOUND
                  THEN
                     V_RESP_CDE := '12';                         --Ineligible Transaction
                     V_ERR_MSG := 'INVALID APPLICATION ISSUANCE STATUS.';
                     RAISE EXP_REJECT_RECORD;
                  WHEN OTHERS THEN
                     V_RESP_CDE := '12';
                     V_ERR_MSG := 'INVALID APPLICATION ISSUANCE STATUS.';
                     RAISE EXP_REJECT_RECORD;

               END;
                -- End Added by ramkumar.MK on 4 april 4 2012



          -- END IF;

        --Sn check for precheck
            IF V_PRECHECK_FLAG = 1 THEN

                 BEGIN

                   SP_PRECHECK_TXN(p_INST_CODE,
                                p_CARD_NO,
                                p_DELIVERY_CHANNEL,
                                V_EXPRY_DATE,
                                V_APPLPAN_CARDSTAT,
                                p_TXN_CODE,
                                p_TXN_MODE,
                                p_TRAN_DATE,
                                p_TRAN_TIME,
                                V_TRAN_AMT,
                                V_ATMONLINE_LIMIT,
                                V_POSONLINE_LIMIT,
                                V_RESP_CDE,
                                V_ERR_MSG);

                   IF (V_RESP_CDE <> '1' OR V_ERR_MSG <> 'OK') THEN
                    RAISE EXP_REJECT_RECORD;
                   END IF;
                 EXCEPTION
                   WHEN EXP_REJECT_RECORD THEN
                    RAISE;
                   WHEN OTHERS THEN
                    V_RESP_CDE := '21';
                    V_ERR_MSG  := 'Error from precheck processes ' ||
                                SUBSTR(SQLERRM, 1, 200);
                    RAISE EXP_REJECT_RECORD;
                 END;

            END IF;

      END IF;
    --En check for Precheck

       --Sn check for Preauth
        IF V_PREAUTH_FLAG = 1 THEN

             BEGIN

               SP_PREAUTHORIZE_TXN(p_CARD_NO,
                               p_MCC_CODE,
                               p_CURR_CODE,
                               V_TRAN_DATE,
                               p_TXN_CODE,
                               p_INST_CODE,
                               p_TRAN_DATE,
                               p_TXN_AMT,
                               p_DELIVERY_CHANNEL,
                               V_RESP_CDE,
                               V_ERR_MSG);

               IF (V_RESP_CDE <> '1' OR V_ERR_MSG <> 'OK') THEN
                RAISE EXP_REJECT_RECORD;
               END IF;
             EXCEPTION
               WHEN EXP_REJECT_RECORD THEN
                RAISE;
               WHEN OTHERS THEN
                V_RESP_CDE := '21';
                V_ERR_MSG  := 'Error from pre_auth process ' ||
                            SUBSTR(SQLERRM, 1, 200);
                RAISE EXP_REJECT_RECORD;
             END;

        END IF;
       --En check for preauth

   -------------------------------------------------------------
    */  -- not required to check for ACH force post txn
   -------------------------------------------------------------




        --Sn commented for fwr-48
        --Sn find function code attached to txn code
        /*BEGIN

         SELECT CFM_FUNC_CODE
           INTO V_FUNC_CODE
           FROM CMS_FUNC_MAST
          WHERE CFM_TXN_CODE = p_TXN_CODE AND CFM_TXN_MODE = p_TXN_MODE AND
               CFM_DELIVERY_CHANNEL = p_DELIVERY_CHANNEL AND
               CFM_INST_CODE = p_INST_CODE;
         --TXN mode and delivery channel we need to attach
         --bkz txn code may be same for all type of channels
        EXCEPTION
         WHEN NO_DATA_FOUND THEN
           V_RESP_CDE := '89'; --Ineligible Transaction --Modified by srinivasu on 20 feb 2012 for reponse code changes from 89 to R20
           V_ERR_MSG  := 'Function code not defined for txn code ' ||
                      p_TXN_CODE;
           RAISE EXP_REJECT_RECORD;
         WHEN TOO_MANY_ROWS THEN
           V_RESP_CDE := '89';
           V_ERR_MSG  := 'More than one function defined for txn code ' || --Modified by srinivasu on 20 feb 2012 for reponse code changes from 89 to R20
                      p_TXN_CODE;
           RAISE EXP_REJECT_RECORD;
         WHEN OTHERS THEN
           V_RESP_CDE := '89'; --Modified by srinivasu on 20 feb 2012 for reponse code changes from 89 to R20
           V_ERR_MSG  := 'Error while selecting func code' ||
                      SUBSTR(SQLERRM, 1, 200);
           RAISE EXP_REJECT_RECORD;
        END;*/
        --En find function code attached to txn code

        --En commented for fwr-48

        --Get the card no
        BEGIN

         SELECT CAM_ACCT_BAL, CAM_LEDGER_BAL, CAM_ACCT_NO,
                cam_type_code  --Added by Pankaj S. for 10871
           INTO V_ACCT_BALANCE, V_LEDGER_BAL, V_CARD_ACCT_NO,
                v_acct_type  --Added by Pankaj S. for 10871
           FROM CMS_ACCT_MAST
          WHERE CAM_ACCT_NO =
               (SELECT CAP_ACCT_NO
                 FROM CMS_APPL_PAN
                WHERE CAP_PAN_CODE = V_HASH_PAN
                     AND CAP_MBR_NUMB = p_MBR_NUMB AND
                     CAP_INST_CODE = p_INST_CODE) AND
               CAM_INST_CODE = p_INST_CODE
            FOR UPDATE NOWAIT;
        EXCEPTION
         WHEN NO_DATA_FOUND THEN
           V_RESP_CDE := '14'; --Ineligible Transaction
           V_ERR_MSG  := 'Invalid Card ';
           RAISE EXP_REJECT_RECORD;
         WHEN OTHERS THEN
           V_RESP_CDE := '12';
           V_ERR_MSG  := 'Error while selecting data from card Master for card number ' ||
                      p_CARD_NO;
           RAISE EXP_REJECT_RECORD;
        END;

    --Sn find fees amount attaced to func code, prod_code and card type

        ---Sn dynamic fee calculation .
        BEGIN


         SP_TRAN_FEES_CMSAUTH(P_INST_CODE,
                          P_CARD_NO,
                          P_DELIVERY_CHANNEL,
                          V_TXN_TYPE,
                          P_TXN_MODE,
                          P_TXN_CODE,
                          P_CURR_CODE,
                          P_CONSODIUM_CODE,
                          P_PARTNER_CODE,
                          V_TRAN_AMT,
                          V_TRAN_DATE,
                          NULL,--Added by Deepa for Fees Changes
                          NULL,--Added by Deepa for Fees Changes
                          V_RESP_CDE,--Added by Deepa for Fees Changes
                          P_MSG,--Added by Deepa for Fees Changes
                          p_RVSL_CODE,--Added by Deepa on June 25 2012 for Reversal txn Fee
                          P_MCC_CODE, --Added by Trivikram on 05-Sep-2012 for merchant catg code
                          V_FEE_AMT,
                          V_ERROR,
                          V_FEE_CODE,
                          V_FEE_CRGL_CATG,
                          V_FEE_CRGL_CODE,
                          V_FEE_CRSUBGL_CODE,
                          V_FEE_CRACCT_NO,
                          V_FEE_DRGL_CATG,
                          V_FEE_DRGL_CODE,
                          V_FEE_DRSUBGL_CODE,
                          V_FEE_DRACCT_NO,
                          V_ST_CALC_FLAG,
                          V_CESS_CALC_FLAG,
                          V_ST_CRACCT_NO,
                          V_ST_DRACCT_NO,
                          V_CESS_CRACCT_NO,
                          V_CESS_DRACCT_NO,
                          V_FEEAMNT_TYPE,--Added by Deepa for Fees Changes
                          V_CLAWBACK,--Added by Deepa for Fees Changes
                          V_FEE_PLAN,--Added by Deepa for Fees Changes
                          V_PER_FEES, --Added by Deepa for Fees Changes
                          V_FLAT_FEES, --Added by Deepa for Fees Changes
                          V_FREETXN_EXCEED, -- Added by Trivikram for logging fee of free transaction
                          V_DURATION, -- Added by Trivikram for logging fee of free transaction
                          V_FEEATTACH_TYPE, -- Added by Trivikram on Sep 05 2012
                          V_FEE_DESC                  -- Added for MVCSD-4471
                          );
             IF V_ERROR <> 'OK' THEN
               V_RESP_CDE := '21';
               V_ERR_MSG  := V_ERROR;
               RAISE EXP_REJECT_RECORD;
             END IF;

        EXCEPTION
         WHEN EXP_REJECT_RECORD THEN
           RAISE;
         WHEN OTHERS THEN
           V_RESP_CDE := '21';
           V_ERR_MSG  := 'Error from fee calc process ' ||
                      SUBSTR(SQLERRM, 1, 200);
           RAISE EXP_REJECT_RECORD;
        END;
       ---En dynamic fee calculation .

        --Sn calculate waiver on the fee
        BEGIN
         SP_CALCULATE_WAIVER(p_INST_CODE,
                         p_CARD_NO,
                         '000',
                         V_PROD_CODE,
                         V_PROD_CATTYPE,
                         V_FEE_CODE,
                         V_FEE_PLAN,  -- Added by Trivikram on 21/aug/2012
                         V_TRAN_DATE,--Added Trivikam on Aug-23-2012 to calculate the waiver based on tran date
                         V_WAIV_PERCNT,
                         V_ERR_WAIV);

             IF V_ERR_WAIV <> 'OK' THEN
               V_RESP_CDE := '21';
               V_ERR_MSG  := V_ERR_WAIV;
               RAISE EXP_REJECT_RECORD;
             END IF;

        EXCEPTION
         WHEN EXP_REJECT_RECORD THEN
           RAISE;
         WHEN OTHERS THEN
           V_RESP_CDE := '21';
           V_ERR_MSG  := 'Error from waiver calc process ' ||
                      SUBSTR(SQLERRM, 1, 200);
           RAISE EXP_REJECT_RECORD;
        END;
       --En calculate waiver on the fee

        --Sn apply waiver on fee amount
        V_LOG_ACTUAL_FEE := V_FEE_AMT; --only used to log in log table
        V_FEE_AMT        := ROUND(V_FEE_AMT -
                            ((V_FEE_AMT * V_WAIV_PERCNT) / 100),
                            2);
        V_LOG_WAIVER_AMT := V_LOG_ACTUAL_FEE - V_FEE_AMT;
        --only used to log in log table

        --En apply waiver on fee amount

        --Sn apply service tax and cess
        IF V_ST_CALC_FLAG = 1 THEN
         V_SERVICETAX_AMOUNT := (V_FEE_AMT * V_SERVICETAX_PERCENT) / 100;
        ELSE
         V_SERVICETAX_AMOUNT := 0;
        END IF;

        IF V_CESS_CALC_FLAG = 1 THEN
         V_CESS_AMOUNT := (V_SERVICETAX_AMOUNT * V_CESS_PERCENT) / 100;
        ELSE
         V_CESS_AMOUNT := 0;
        END IF;

        V_TOTAL_FEE := ROUND(V_FEE_AMT + V_SERVICETAX_AMOUNT + V_CESS_AMOUNT, 2);

    --En apply service tax and cess

    --En find fees amount attached to func code, prod code and card type

     -------------------------------------------------------------
      /* -- not required to check for ACH force post txn
     -------------------------------------------------------------

       --added for minimum activation amount check beg
        IF P_TXN_CODE = '68' THEN

             BEGIN
               SELECT TO_NUMBER(CBP_PARAM_VALUE)
                INTO V_MIN_ACT_AMT
                FROM CMS_BIN_PARAM
                WHERE CBP_INST_CODE = p_INST_CODE AND
                    CBP_PARAM_NAME = 'Min Card Balance' AND
                    CBP_PROFILE_CODE IN
                    (SELECT CPM_PROFILE_CODE
                       FROM CMS_PROD_MAST
                      WHERE CPM_PROD_CODE = V_PROD_CODE);

               IF V_TRAN_AMT < V_MIN_ACT_AMT THEN
                V_RESP_CDE := '39';
                V_ERR_MSG  := 'Amount should be = or > than ' || V_MIN_ACT_AMT ||
                            ' for Card Activation';
                RAISE EXP_REJECT_RECORD;
               END IF;

             EXCEPTION
               WHEN OTHERS THEN
                V_RESP_CDE := '39';
                V_ERR_MSG  := 'Amount should be = or > than ' || V_MIN_ACT_AMT ||
                            ' for Card Activation ';
                RAISE EXP_REJECT_RECORD;
             END;

        END IF;
        --added for minimum activation amount check beg

   -------------------------------------------------------------
    */  -- not required to check for ACH force post txn
   -------------------------------------------------------------


        --Sn find total transaction   amount
        IF V_DR_CR_FLAG = 'CR' THEN
         V_TOTAL_AMT      := V_TRAN_AMT - V_TOTAL_FEE;
         V_UPD_AMT        := V_ACCT_BALANCE + V_TOTAL_AMT;
         V_UPD_LEDGER_BAL := V_LEDGER_BAL + V_TOTAL_AMT;

        ELSIF V_DR_CR_FLAG = 'DR' THEN
         V_TOTAL_AMT      := V_TRAN_AMT + V_TOTAL_FEE;
         V_UPD_AMT        := V_ACCT_BALANCE - V_TOTAL_AMT;
         V_UPD_LEDGER_BAL := V_LEDGER_BAL - V_TOTAL_AMT;

        ELSIF V_DR_CR_FLAG = 'NA' THEN

         V_TOTAL_AMT      := V_TOTAL_FEE;
         V_UPD_AMT        := V_ACCT_BALANCE - V_TOTAL_AMT;
         V_UPD_LEDGER_BAL := V_LEDGER_BAL - V_TOTAL_AMT;

        ELSE
         V_RESP_CDE := '12'; --Ineligible Transaction
         V_ERR_MSG  := 'Invalid transflag    txn code ' || p_TXN_CODE;
         RAISE EXP_REJECT_RECORD;
        END IF;

    --En find total transaction   amout


   -------------------------------------------------------------
      /*    -- not required to check for ACH force post txn
   -------------------------------------------------------------

        --Sn check balance
        IF V_DR_CR_FLAG NOT IN ('NA', 'CR') -- For credit transaction or Non-Financial transaction Insufficient Balance Check is not required. -- 29th June 2011
        THEN
             IF V_UPD_AMT < 0 THEN
               V_RESP_CDE := '15'; --Ineligible Transaction
               V_ERR_MSG  := 'Insufficent Balance ';
               RAISE EXP_REJECT_RECORD;
             END IF;

        END IF;



        -- Check for maximum card balance configured for the product profile.
        BEGIN

         SELECT TO_NUMBER(CBP_PARAM_VALUE)
           INTO V_MAX_CARD_BAL
           FROM CMS_BIN_PARAM
          WHERE CBP_INST_CODE = p_INST_CODE AND
               CBP_PARAM_NAME = 'Max Card Balance' AND
               CBP_PROFILE_CODE IN
               (SELECT CPM_PROFILE_CODE
                 FROM CMS_PROD_MAST
                WHERE CPM_PROD_CODE = V_PROD_CODE);

        EXCEPTION
         WHEN OTHERS THEN
           V_RESP_CDE := '21';
           V_ERR_MSG := SQLERRM;
           RAISE EXP_REJECT_RECORD;

        END;

        --Sn check balance
        IF (V_UPD_LEDGER_BAL > V_MAX_CARD_BAL) OR (V_UPD_AMT > V_MAX_CARD_BAL) THEN

         V_RESP_CDE := '30';
         V_ERR_MSG  := 'EXCEEDING MAXIMUM CARD BALANCE';
         RAISE EXP_REJECT_RECORD;
        END IF;

       -------------------------------------------------------------
        */  -- not required to check for ACH force post txn
       -------------------------------------------------------------



        --En check balance
        IF (TO_NUMBER(p_TXN_CODE) = 21) OR (TO_NUMBER(p_TXN_CODE) = 23) OR
          (TO_NUMBER(p_TXN_CODE) = 33) THEN
         V_DR_CR_FLAG := 'NA';
         V_TXN_TYPE   := '0';
        END IF;

        --Sn create gl entries and acct update
        BEGIN
         SP_UPD_TRANSACTION_ACCNT_AUTH(p_INST_CODE,
                                 V_TRAN_DATE,
                                 V_PROD_CODE,
                                 V_PROD_CATTYPE,
                                 V_TRAN_AMT,
                                 V_FUNC_CODE,
                                 p_TXN_CODE,
                                 V_DR_CR_FLAG,
                                 p_RRN,
                                 p_TERM_ID,
                                 p_DELIVERY_CHANNEL,
                                 p_TXN_MODE,
                                 p_CARD_NO,
                                 V_FEE_CODE,
                                 V_FEE_AMT,
                                 V_FEE_CRACCT_NO,
                                 V_FEE_DRACCT_NO,
                                 V_ST_CALC_FLAG,
                                 V_CESS_CALC_FLAG,
                                 V_SERVICETAX_AMOUNT,
                                 V_ST_CRACCT_NO,
                                 V_ST_DRACCT_NO,
                                 V_CESS_AMOUNT,
                                 V_CESS_CRACCT_NO,
                                 V_CESS_DRACCT_NO,
                                 V_CARD_ACCT_NO,
                                 '',
                                 p_MSG,
                                 V_RESP_CDE,
                                 V_ERR_MSG);

         IF (V_RESP_CDE <> '1' OR V_ERR_MSG <> 'OK') THEN
           V_RESP_CDE := '21';
           RAISE EXP_REJECT_RECORD;
         END IF;
        EXCEPTION
         WHEN EXP_REJECT_RECORD THEN
           RAISE;
         WHEN OTHERS THEN
           V_RESP_CDE := '21';
           V_ERR_MSG  := 'Error from currency conversion ' ||
                      SUBSTR(SQLERRM, 1, 200);
           RAISE EXP_REJECT_RECORD;
        END;

        --En create gl entries and acct update

      /* -- not required since tran desc already fetched above

        --Sn find narration
        BEGIN



            SELECT CTM_TRAN_DESC
            INTO V_TRANS_DESC
            FROM CMS_TRANSACTION_MAST
            WHERE CTM_TRAN_CODE = p_TXN_CODE AND
            CTM_DELIVERY_CHANNEL = p_DELIVERY_CHANNEL AND
            CTM_INST_CODE = p_INST_CODE;


        EXCEPTION
         WHEN NO_DATA_FOUND THEN
           V_TRANS_DESC := 'Transaction type ' || p_TXN_CODE;
        WHEN OTHERS THEN

           V_RESP_CDE := '21';
          V_ERR_MSG  := 'Error in finding the narration ' ||
                      SUBSTR(SQLERRM, 1, 200);
           RAISE EXP_REJECT_RECORD;

         END;
         */ --  not required since tran desc already fetched above




       IF (p_TXN_CODE ='07') THEN

            IF TRIM(V_TRANS_DESC) IS NOT NULL THEN

                V_NARRATION := V_TRANS_DESC || '/';

            END IF;

            IF TRIM(V_AUTH_ID) IS NOT NULL THEN

                V_NARRATION := V_NARRATION || V_AUTH_ID|| '/';

            END IF;



            IF TRIM(p_TO_ACCT_NO) IS NOT NULL THEN

                V_NARRATION := V_NARRATION || p_TO_ACCT_NO || '/';

            END IF;

            IF TRIM(p_TRAN_DATE) IS NOT NULL THEN

                V_NARRATION := V_NARRATION || p_TRAN_DATE ;

            END IF;

        ELSE

            IF TRIM(V_TRANS_DESC) IS NOT NULL THEN

              V_NARRATION := V_TRANS_DESC || '/';

            END IF;

            IF TRIM(p_MERCHANT_NAME) IS NOT NULL THEN

                V_NARRATION := V_NARRATION || p_MERCHANT_NAME || '/';

            END IF;

            IF TRIM(p_MERCHANT_CITY) IS NOT NULL THEN

                V_NARRATION := V_NARRATION || p_MERCHANT_CITY || '/';

            END IF;

            IF TRIM(p_TRAN_DATE) IS NOT NULL THEN

                V_NARRATION := V_NARRATION || p_TRAN_DATE || '/';

            END IF;

            IF TRIM(V_AUTH_ID) IS NOT NULL THEN

                V_NARRATION := V_NARRATION || V_AUTH_ID;

            END IF;


       END IF;

       v_timestamp:=systimestamp;  --added by Pankaj S. for 10871

       --Sn create a entry in statement log
        IF V_DR_CR_FLAG <> 'NA'
        THEN

             BEGIN
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
                 CSL_ACCT_NO,--Added by Deepa to log the account number ,INS_DATE and INS_USER
                 CSL_INS_USER,
                 CSL_INS_DATE,
                 csl_merchant_name,--Added by Deepa on 03-May-2012 to log Merchant name,city and state
                 csl_merchant_city,
                 csl_merchant_state,
                 CSL_PANNO_LAST4DIGIT,--Added by Srinivasu on 15-May-2012 to log Last 4 Digit of the card number
                 --Sn added by Pankaj S. for 10871
                 csl_prod_code,csl_card_type,
                 csl_acct_type,
                 csl_time_stamp
                 --En added by Pankaj S. for 10871
                 )

                  VALUES
                (
                 V_HASH_PAN,
                 V_LEDGER_BAL,  --V_ACCT_BALANCE repalced by Pankaj S. with V_LEDGER_BAL for 10871
                 V_TRAN_AMT,
                 V_DR_CR_FLAG,
                 V_TRAN_DATE,
                 DECODE(V_DR_CR_FLAG,'DR',V_LEDGER_BAL - V_TRAN_AMT,'CR',V_LEDGER_BAL + V_TRAN_AMT,'NA',V_LEDGER_BAL), --V_ACCT_BALANCE repalced by Pankaj S with V_LEDGER_BAL for 10871
                 V_NARRATION,
                 V_ENCR_PAN,
                 p_RRN,
                 V_AUTH_ID,
                 p_TRAN_DATE,
                 p_TRAN_TIME,
                 'N',
                 p_DELIVERY_CHANNEL,
                 p_INST_CODE,
                 p_TXN_CODE,
                 V_CARD_ACCT_NO,
                 1,
                 sysdate,--Added by Deepa to log the account number ,INS_DATE and INS_USER
                 P_MERCHANT_NAME,--Added by Deepa on 03-May-2012 to log Merchant name,city and state
                 P_MERCHANT_CITY,
                 P_ATMNAME_LOC,
                 (substr(p_CARD_NO, length(p_CARD_NO) -3,length(p_CARD_NO))),--Added by Srinivasu on 15-May-2012 to log Last 4 Digit of the card number
                 --Sn added by Pankaj S. for 10871
                 v_prod_code,V_PROD_CATTYPE,
                 v_acct_type,
                 v_timestamp
                 --En added by Pankaj S. for 10871
                 );

             EXCEPTION
               WHEN OTHERS THEN
                V_RESP_CDE := '21';
                V_ERR_MSG  := 'Problem while inserting into statement log for tran amt ' ||
                            SUBSTR(SQLERRM, 1, 200);
                RAISE EXP_REJECT_RECORD;
             END;


           ------------------------------------------------------------
           /* -- not required to check for ACH force post txn
           ------------------------------------------------------------

             BEGIN
                   SP_DAILY_BIN_BAL(p_CARD_NO,
                                V_TRAN_DATE,
                                V_TRAN_AMT,
                                V_DR_CR_FLAG,
                                p_INST_CODE,
                                p_BANK_CODE,
                                V_ERR_MSG);

                          IF V_ERR_MSG <> 'OK' THEN
                             V_RESP_CDE := '21';
                             V_ERR_MSG  := 'Error while calling SP_DAILY_BIN_BAL ' ||
                                p_CARD_NO;
                             RAISE EXP_REJECT_RECORD;
                          END IF;
             EXCEPTION
             WHEN OTHERS THEN

               V_RESP_CDE := '21';
               V_ERR_MSG  := 'Error while calling SP_DAILY_BIN_BAL ' ||p_CARD_NO;
               RAISE EXP_REJECT_RECORD;
             END;

           -------------------------------------------------------------
            */  -- not required to check for ACH force post txn
           -------------------------------------------------------------


         END IF;
    --En create a entry in statement log

    --Sn find fee opening balance
    IF V_TOTAL_FEE <> 0 OR V_FREETXN_EXCEED = 'N' THEN

         BEGIN

           SELECT DECODE(V_DR_CR_FLAG,
                      'DR',
                      V_LEDGER_BAL - V_TRAN_AMT,
                      'CR',
                      V_LEDGER_BAL + V_TRAN_AMT,
                      'NA',
                      V_LEDGER_BAL)    --V_ACCT_BALANCE repalced by Pankaj S with V_LEDGER_BAL for 10871
            INTO V_FEE_OPENING_BAL
            FROM DUAL;
         EXCEPTION
           WHEN OTHERS THEN
            V_RESP_CDE := '21';
            V_ERR_MSG  := 'Error while calculating opening balance for fee ';
            RAISE EXP_REJECT_RECORD;
         END;


        IF V_FREETXN_EXCEED = 'N' THEN

             BEGIN
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
                 csl_merchant_name,
                 csl_merchant_city,
                 csl_merchant_state,
                 CSL_PANNO_LAST4DIGIT,
                 --Sn added by Pankaj S. for 10871
                 csl_prod_code,csl_card_type,
                 csl_acct_type,
                 csl_time_stamp
                 --En added by Pankaj S. for 10871
                 )
               VALUES
                (
                 V_HASH_PAN,
                 V_FEE_OPENING_BAL,
                 V_TOTAL_FEE,
                 'DR',
                 V_TRAN_DATE,
                 V_FEE_OPENING_BAL - V_TOTAL_FEE,
                 'Complimentary ' || V_DURATION ||' '|| V_NARRATION,
                 V_ENCR_PAN,
                 p_RRN,
                 V_AUTH_ID,
                 p_TRAN_DATE,
                 p_TRAN_TIME,
                 'Y',
                 p_DELIVERY_CHANNEL,
                 p_INST_CODE,
                 p_TXN_CODE,
                 V_CARD_ACCT_NO,
                 1,
                 sysdate,
                 P_MERCHANT_NAME,
                 P_MERCHANT_CITY,
                 P_ATMNAME_LOC,
                 (substr(p_CARD_NO, length(p_CARD_NO) -3,length(p_CARD_NO))),
                 --Sn added by Pankaj S. for 10871
                 v_prod_code,V_PROD_CATTYPE,
                 v_acct_type,
                 v_timestamp
                 --En added by Pankaj S. for 10871
                 );
             EXCEPTION
               WHEN OTHERS THEN
                V_RESP_CDE := '21';
                V_ERR_MSG  := 'Problem while inserting into statement log for tran fee ' ||
                            SUBSTR(SQLERRM, 1, 200);
                RAISE EXP_REJECT_RECORD;
             END;

        ELSE

          BEGIN

            --En find fee opening balance
             IF V_FEEAMNT_TYPE='A' THEN

                -- Added by Trivikram on 23/aug/2012 for logged fixed fee and percentage fee with waiver

                V_FLAT_FEES := ROUND(V_FLAT_FEES -
                                    ((V_FLAT_FEES * V_WAIV_PERCNT) / 100),2);


                    V_PER_FEES  := ROUND(V_PER_FEES -
                                ((V_PER_FEES * V_WAIV_PERCNT) / 100),2);

             --En Entry for Fixed Fee
             INSERT INTO CMS_STATEMENTS_LOG
                (CSL_PAN_NO,
                 CSL_OPENING_BAL,
                 CSL_TRANS_AMOUNT,
                 CSL_TRANS_TYPE,
                 CSL_TRANS_DATE,
                 CSL_CLOSING_BALANCE,
                 CSL_TRANS_NARRRATION,
                 CSL_INST_CODE,
                 CSL_PAN_NO_ENCR,
                 CSL_RRN,
                 CSL_AUTH_ID,
                 CSL_BUSINESS_DATE,
                 CSL_BUSINESS_TIME,
                 TXN_FEE_FLAG,
                 CSL_DELIVERY_CHANNEL,
                 CSL_TXN_CODE,
                 CSL_ACCT_NO,
                 CSL_INS_USER,
                 CSL_INS_DATE,
                 csl_merchant_name,
                 csl_merchant_city,
                 csl_merchant_state,
                 CSL_PANNO_LAST4DIGIT,
                 --Sn added by Pankaj S. for 10871
                 csl_prod_code,csl_card_type,
                 csl_acct_type,
                 csl_time_stamp
                 --En added by Pankaj S. for 10871
                 )
               VALUES
                (
                 V_HASH_PAN,
                 V_FEE_OPENING_BAL,
                 V_FLAT_FEES,
                 'DR',
                 V_TRAN_DATE,
                 V_FEE_OPENING_BAL - V_FLAT_FEES,
                 'Fixed Fee debited for ' || V_NARRATION,
                 P_INST_CODE,
                 V_ENCR_PAN,
                 P_RRN,
                 V_AUTH_ID,
                 P_TRAN_DATE,
                 P_TRAN_TIME,
                 'Y',
                 P_DELIVERY_CHANNEL,
                 P_TXN_CODE,
                 V_CARD_ACCT_NO,
                 1,
                 sysdate,
                 P_MERCHANT_NAME,
                 P_MERCHANT_CITY,
                 P_ATMNAME_LOC,
                 (substr(p_CARD_NO, length(p_CARD_NO) -3,length(p_CARD_NO))),
                 --Sn added by Pankaj S. for 10871
                 v_prod_code,V_PROD_CATTYPE,
                 v_acct_type,
                 v_timestamp
                 --En added by Pankaj S. for 10871
                 );
                 --En Entry for Fixed Fee


                 V_FEE_OPENING_BAL:=V_FEE_OPENING_BAL - V_FLAT_FEES;

                 --Sn Entry for Percentage Fee

                  INSERT INTO CMS_STATEMENTS_LOG
                (CSL_PAN_NO,
                 CSL_OPENING_BAL,
                 CSL_TRANS_AMOUNT,
                 CSL_TRANS_TYPE,
                 CSL_TRANS_DATE,
                 CSL_CLOSING_BALANCE,
                 CSL_TRANS_NARRRATION,
                 CSL_INST_CODE,
                 CSL_PAN_NO_ENCR,
                 CSL_RRN,
                 CSL_AUTH_ID,
                 CSL_BUSINESS_DATE,
                 CSL_BUSINESS_TIME,
                 TXN_FEE_FLAG,
                 CSL_DELIVERY_CHANNEL,
                 CSL_TXN_CODE,
                 CSL_ACCT_NO,--Added by Deepa to log the account number ,INS_DATE and INS_USER
                 CSL_INS_USER,
                 CSL_INS_DATE,
                 csl_merchant_name,--Added by Deepa on 03-May-2012 to log Merchant name,city and state
                 csl_merchant_city,
                 csl_merchant_state,
                 CSL_PANNO_LAST4DIGIT,--Added by Trivikram on 23-May-2012 to log Last 4 Digit of the card number
                 --Sn added by Pankaj S. for 10871
                 csl_prod_code,csl_card_type,
                 csl_acct_type,
                 csl_time_stamp
                 --En added by Pankaj S. for 10871
                 )
               VALUES
                (
                 V_HASH_PAN,
                 V_FEE_OPENING_BAL,
                 V_PER_FEES,
                 'DR',
                 V_TRAN_DATE,
                 V_FEE_OPENING_BAL - V_PER_FEES,
                 'Percetage Fee debited for ' || V_NARRATION,
                 P_INST_CODE,
                 V_ENCR_PAN,
                 P_RRN,
                 V_AUTH_ID,
                 P_TRAN_DATE,
                 P_TRAN_TIME,
                 'Y',
                 P_DELIVERY_CHANNEL,
                 P_TXN_CODE,
                 V_CARD_ACCT_NO,--Added by Deepa to log the account number ,INS_DATE and INS_USER
                 1,
                 sysdate,
                 P_MERCHANT_NAME,--Added by Deepa on 03-May-2012 to log Merchant name,city and state
                 P_MERCHANT_CITY,
                 P_ATMNAME_LOC,
                 (substr(p_CARD_NO, length(p_CARD_NO) -3,length(p_CARD_NO))),
                 --Sn added by Pankaj S. for 10871
                 v_prod_code,V_PROD_CATTYPE,
                 v_acct_type,
                 v_timestamp
                 --En added by Pankaj S. for 10871
                 );

                 --En Entry for Percentage Fee

             ELSE
             --Sn create entries for FEES attached
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
                 csl_merchant_name,
                 csl_merchant_city,
                 csl_merchant_state,
                 CSL_PANNO_LAST4DIGIT,
                 --Sn added by Pankaj S. for 10871
                 csl_prod_code,csl_card_type,
                 csl_acct_type,
                 csl_time_stamp
                 --En added by Pankaj S. for 10871
                 )
               VALUES
                (
                 V_HASH_PAN,
                 V_FEE_OPENING_BAL,
                 V_TOTAL_FEE,
                 'DR',
                 V_TRAN_DATE,
                 V_FEE_OPENING_BAL - V_TOTAL_FEE,
                 'Fee debited for ' || V_NARRATION,
                 V_ENCR_PAN,
                 p_RRN,
                 V_AUTH_ID,
                 p_TRAN_DATE,
                 p_TRAN_TIME,
                 'Y',
                 p_DELIVERY_CHANNEL,
                 p_INST_CODE,
                 p_TXN_CODE,
                 V_CARD_ACCT_NO,
                 1,
                 sysdate,
                 P_MERCHANT_NAME,
                 P_MERCHANT_CITY,
                 P_ATMNAME_LOC,
                 (substr(p_CARD_NO, length(p_CARD_NO) -3,length(p_CARD_NO))),
                  --Sn added by Pankaj S. for 10871
                 v_prod_code,V_PROD_CATTYPE,
                 v_acct_type,
                 v_timestamp
                 --En added by Pankaj S. for 10871
                 );
             END IF;

          EXCEPTION
           WHEN OTHERS THEN
            V_RESP_CDE := '21';
            V_ERR_MSG  := 'Problem while inserting into statement log for tran fee ' ||
                        SUBSTR(SQLERRM, 1, 200);
            RAISE EXP_REJECT_RECORD;
          END;

        END IF;

    END IF;

    --En create entries for FEES attached
    --Sn create a entry for successful
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
        CTD_CUSTOMER_CARD_NO_ENCR,
        CTD_MSG_TYPE,
        CTD_CUST_ACCT_NUMBER,
        CTD_INST_CODE
        )
     VALUES
       (p_DELIVERY_CHANNEL,
        p_TXN_CODE,
        V_TXN_TYPE,
        p_TXN_MODE,
        p_TRAN_DATE,
        p_TRAN_TIME,
        V_HASH_PAN,
        p_TXN_AMT,
        p_CURR_CODE,
        V_TRAN_AMT,
        V_LOG_ACTUAL_FEE,
        V_LOG_WAIVER_AMT,
        V_SERVICETAX_AMOUNT,
        V_CESS_AMOUNT,
        V_TOTAL_AMT,
        V_CARD_CURR,
        'Y',
        'Successful',
        p_RRN,
        p_STAN,
        V_ENCR_PAN,
        p_MSG,
        V_ACCT_NUMBER,
        p_INST_CODE);
    EXCEPTION
     WHEN OTHERS THEN
       V_ERR_MSG  := 'Problem while selecting data from response master ' ||
                  SUBSTR(SQLERRM, 1, 300);
       V_RESP_CDE := '21';
       RAISE EXP_REJECT_RECORD;
    END;

    --En create a entry for successful

    ---Sn update daily and weekly transcounter  and amount
    BEGIN
     /*SELECT CAT_PAN_CODE
       INTO V_AVAIL_PAN
       FROM CMS_AVAIL_TRANS
      WHERE CAT_PAN_CODE = V_HASH_PAN --p_card_no
           AND CAT_TRAN_CODE = p_TXN_CODE AND
           CAT_TRAN_MODE = p_TXN_MODE;*/

     UPDATE CMS_AVAIL_TRANS
        SET CAT_MAXDAILY_TRANCNT  = DECODE(CAT_MAXDAILY_TRANCNT,
                                    0,
                                    CAT_MAXDAILY_TRANCNT,
                                    CAT_MAXDAILY_TRANCNT - 1),
           CAT_MAXDAILY_TRANAMT  = DECODE(V_DR_CR_FLAG,
                                    'DR',
                                    CAT_MAXDAILY_TRANAMT - V_TRAN_AMT,
                                    CAT_MAXDAILY_TRANAMT),
           CAT_MAXWEEKLY_TRANCNT = DECODE(CAT_MAXWEEKLY_TRANCNT,
                                    0,
                                    CAT_MAXWEEKLY_TRANCNT,
                                    CAT_MAXDAILY_TRANCNT - 1),
           CAT_MAXWEEKLY_TRANAMT = DECODE(V_DR_CR_FLAG,
                                    'DR',
                                    CAT_MAXWEEKLY_TRANAMT -
                                    V_TRAN_AMT,
                                    CAT_MAXWEEKLY_TRANAMT)
      WHERE CAT_INST_CODE = p_INST_CODE AND CAT_PAN_CODE = V_HASH_PAN
           AND CAT_TRAN_CODE = p_TXN_CODE AND
           CAT_TRAN_MODE = p_TXN_MODE;
    /*
     IF SQL%ROWCOUNT = 0 THEN
       V_ERR_MSG  := 'Problem while updating data in avail trans ' ||
                  SUBSTR(SQLERRM, 1, 300);
       V_RESP_CDE := '21';
       RAISE EXP_REJECT_RECORD;
     END IF;
     */
    EXCEPTION  WHEN OTHERS THEN
       V_ERR_MSG  := 'Problem while selecting data from avail trans ' ||
                  SUBSTR(SQLERRM, 1, 300);
       V_RESP_CDE := '21';
       RAISE EXP_REJECT_RECORD;
    END;

    --En update daily and weekly transaction counter and amount

    --Sn create detail for response message
    IF V_OUTPUT_TYPE = 'B' THEN
     --Balance Inquiry
     p_RESP_MSG := TO_CHAR(V_UPD_AMT);
    END IF;

    --En create detail fro response message
    --Sn mini statement
    IF V_OUTPUT_TYPE = 'M' THEN

     --Mini statement
         BEGIN
           SP_GEN_MINI_STMT(p_INST_CODE,
                        p_CARD_NO,
                        V_MINI_TOTREC,
                        V_MINISTMT_OUTPUT,
                        V_MINISTMT_ERRMSG);

           IF V_MINISTMT_ERRMSG <> 'OK' THEN
            V_ERR_MSG  := V_MINISTMT_ERRMSG;
            V_RESP_CDE := '21';
            RAISE EXP_REJECT_RECORD;
           END IF;

           p_RESP_MSG := LPAD(TO_CHAR(V_MINI_TOTREC), 2, '0') ||
                        V_MINISTMT_OUTPUT;
         EXCEPTION
           WHEN EXP_REJECT_RECORD THEN
            RAISE;
           WHEN OTHERS THEN
            V_ERR_MSG  := 'Problem while selecting data for mini statement ' ||
                        SUBSTR(SQLERRM, 1, 300);
            V_RESP_CDE := '21';
            RAISE EXP_REJECT_RECORD;
         END;

    END IF;

    --En mini statement
    P_RESP_ID :=V_RESP_CDE;
    V_RESP_CDE := '1';

    BEGIN
     SELECT CMS_ISO_RESPCDE
       INTO p_RESP_CODE
       FROM CMS_RESPONSE_MAST
      WHERE CMS_INST_CODE = p_INST_CODE AND
           CMS_DELIVERY_CHANNEL = TO_NUMBER(p_DELIVERY_CHANNEL) AND
           CMS_RESPONSE_ID = TO_NUMBER(V_RESP_CDE);
    EXCEPTION
     WHEN OTHERS THEN
       V_ERR_MSG  := 'Problem while selecting data from response master for respose code' ||
                  V_RESP_CDE || SUBSTR(SQLERRM, 1, 300);
       V_RESP_CDE := '21';
       RAISE EXP_REJECT_RECORD;
    END;
  EXCEPTION
    --<< MAIN EXCEPTION >>
    WHEN EXP_REJECT_RECORD THEN
     ROLLBACK TO V_AUTH_SAVEPOINT;
     BEGIN
       SELECT CAM_ACCT_BAL, CAM_LEDGER_BAL, CAM_ACCT_NO
        INTO V_ACCT_BALANCE, V_LEDGER_BAL, V_ACCT_NUMBER
        FROM CMS_ACCT_MAST
        WHERE CAM_ACCT_NO =
            (SELECT CAP_ACCT_NO
               FROM CMS_APPL_PAN
              WHERE CAP_PAN_CODE = V_HASH_PAN AND
                   CAP_INST_CODE = p_INST_CODE) AND
            CAM_INST_CODE = p_INST_CODE;
     EXCEPTION
       WHEN OTHERS THEN
        V_ACCT_BALANCE := 0;
        V_LEDGER_BAL   := 0;
     END;

     --Sn select response code and insert record into txn log dtl
     P_RESP_ID :=V_RESP_CDE;
     p_RESP_CODE := V_RESP_CDE;

        BEGIN
          SELECT CMS_ISO_RESPCDE
            INTO p_RESP_CODE
            FROM CMS_RESPONSE_MAST
           WHERE CMS_INST_CODE = p_INST_CODE AND
                 CMS_DELIVERY_CHANNEL = p_DELIVERY_CHANNEL AND
                 CMS_RESPONSE_ID = V_RESP_CDE;

          p_RESP_MSG := V_ERR_MSG;
        EXCEPTION
          WHEN OTHERS THEN
            p_RESP_MSG  := 'Problem while selecting data from response master ' ||
                             V_RESP_CDE || SUBSTR(SQLERRM, 1, 300);
            p_RESP_CODE := '89'; ---ISO MESSAGE FOR DATABASE ERROR --Modified by srinivasu on 20 feb 2012 for reponse code changes from 89 to R20
            ROLLBACK;
            --  RETURN;
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
         CTD_CUSTOMER_CARD_NO_ENCR,
         CTD_MSG_TYPE,
         CTD_CUST_ACCT_NUMBER,
         CTD_INST_CODE)
       VALUES
        (p_DELIVERY_CHANNEL,
         p_TXN_CODE,
         V_TXN_TYPE,
         p_TXN_MODE,
         p_TRAN_DATE,
         p_TRAN_TIME,
         --p_card_no
         V_HASH_PAN,
         p_TXN_AMT,
         p_CURR_CODE,
         V_TRAN_AMT,
         NULL,
         NULL,
         NULL,
         NULL,
         V_TOTAL_AMT,
         V_CARD_CURR,
         'E',
         V_ERR_MSG,
         p_RRN,
         p_STAN,
         V_ENCR_PAN,
         p_MSG,
         V_ACCT_NUMBER,
         p_INST_CODE);

       p_RESP_MSG := V_ERR_MSG;
     EXCEPTION
       WHEN OTHERS THEN
        p_RESP_CODE := 'R20'; --Modified by srinivasu on 20 feb 2012 for reponse code changes from 89 to R20
        p_RESP_MSG  := 'Problem while inserting data into transaction log  dtl' ||
                      SUBSTR(SQLERRM, 1, 300);
        ROLLBACK;
        RETURN;
     END;

  WHEN OTHERS THEN

     ROLLBACK TO V_AUTH_SAVEPOINT;

     BEGIN
       SELECT CAM_ACCT_BAL, CAM_LEDGER_BAL
        INTO V_ACCT_BALANCE, V_LEDGER_BAL
        FROM CMS_ACCT_MAST
        WHERE CAM_ACCT_NO =
            (SELECT CAP_ACCT_NO
               FROM CMS_APPL_PAN
              WHERE CAP_PAN_CODE = V_HASH_PAN AND
                   CAP_INST_CODE = p_INST_CODE) AND
            CAM_INST_CODE = p_INST_CODE;
     EXCEPTION
       WHEN OTHERS THEN
        V_ACCT_BALANCE := 0;
        V_LEDGER_BAL   := 0;
     END;
     --Sn select response code and insert record into txn log dtl

     P_RESP_ID :=V_RESP_CDE;

     BEGIN
       SELECT CMS_ISO_RESPCDE
        INTO p_RESP_CODE
        FROM CMS_RESPONSE_MAST
        WHERE CMS_INST_CODE = p_INST_CODE AND
            CMS_DELIVERY_CHANNEL = p_DELIVERY_CHANNEL AND
            CMS_RESPONSE_ID = V_RESP_CDE;

       p_RESP_MSG := V_ERR_MSG;
     EXCEPTION
       WHEN OTHERS THEN
        p_RESP_MSG  := 'Problem while selecting data from response master ' ||
                      V_RESP_CDE || SUBSTR(SQLERRM, 1, 300);
        p_RESP_CODE := 'R20';
        ROLLBACK;
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
         CTD_CUSTOMER_CARD_NO_ENCR,
         CTD_MSG_TYPE,
         CTD_CUST_ACCT_NUMBER,
         CTD_INST_CODE)
       VALUES
        (p_DELIVERY_CHANNEL,
         p_TXN_CODE,
         V_TXN_TYPE,
         p_TXN_MODE,
         p_TRAN_DATE,
         p_TRAN_TIME,
         V_HASH_PAN,
         p_TXN_AMT,
         p_CURR_CODE,
         V_TRAN_AMT,
         NULL,
         NULL,
         NULL,
         NULL,
         V_TOTAL_AMT,
         V_CARD_CURR,
         'E',
         V_ERR_MSG,
         p_RRN,
         p_STAN,
         V_ENCR_PAN,
         p_MSG,
         V_ACCT_NUMBER,
         p_INST_CODE);
     EXCEPTION
       WHEN OTHERS THEN
        p_RESP_MSG  := 'Problem while inserting data into transaction log  dtl' ||
                      SUBSTR(SQLERRM, 1, 300);
        p_RESP_CODE := 'R20';
        ROLLBACK;
        RETURN;
     END;
     --En select response code and insert record into txn log dtl
  END;

  --- Sn create GL ENTRIES
  IF V_RESP_CDE = '1' THEN
    --Sn find business date
    V_BUSINESS_TIME := TO_CHAR(V_TRAN_DATE, 'HH24:MI');

    IF V_BUSINESS_TIME > V_CUTOFF_TIME THEN
     V_BUSINESS_DATE := TRUNC(V_TRAN_DATE) + 1;
    ELSE
     V_BUSINESS_DATE := TRUNC(V_TRAN_DATE);
    END IF;

    --En find businesses date

    --Sn commented for fwr-48
    /*BEGIN
     SP_CREATE_GL_ENTRIES_CMSAUTH(p_INST_CODE,
                            V_BUSINESS_DATE,
                            V_PROD_CODE,
                            V_PROD_CATTYPE,
                            V_TRAN_AMT,
                            V_FUNC_CODE,
                            p_TXN_CODE,
                            V_DR_CR_FLAG,
                            p_CARD_NO,
                            V_FEE_CODE,
                            V_TOTAL_FEE,
                            V_FEE_CRACCT_NO,
                            V_FEE_DRACCT_NO,
                            V_CARD_ACCT_NO,
                            p_RVSL_CODE,
                            p_MSG,
                            p_DELIVERY_CHANNEL,
                            V_RESP_CDE,
                            V_GL_UPD_FLAG,
                            V_GL_ERR_MSG);

         IF V_GL_ERR_MSG <> 'OK' OR V_GL_UPD_FLAG <> 'Y' THEN
           V_GL_UPD_FLAG := 'N';
           p_RESP_CODE := V_RESP_CDE;
           V_ERR_MSG := V_GL_ERR_MSG;
           RAISE EXP_REJECT_RECORD;
         END IF;

    EXCEPTION
     WHEN OTHERS THEN
       V_GL_UPD_FLAG := 'N';
       p_RESP_CODE := V_RESP_CDE;
        V_ERR_MSG := V_GL_ERR_MSG;
       RAISE EXP_REJECT_RECORD;
    END;*/

    --En commented for fwr-48

  END IF;

  --En create GL ENTRIES

  --if transaction approved from exception queue it will update only process type
    if P_PROCESSTYPE <> 'N' THEN

      --Sn added by Pankaj S. for 10871
      IF v_dr_cr_flag IS NULL THEN
      BEGIN
         SELECT ctm_credit_debit_flag,to_number(decode(ctm_tran_type, 'N', '0', 'F', '1')),ctm_tran_desc
           into v_dr_cr_flag,v_txn_type,v_trans_desc
           FROM cms_transaction_mast
          WHERE ctm_tran_code = p_txn_code
            AND ctm_delivery_channel = p_delivery_channel
            AND ctm_inst_code = p_inst_code;
      EXCEPTION
         WHEN OTHERS THEN
            NULL;
      END;
      END IF;

      IF v_prod_code is NULL THEN
      BEGIN
         SELECT cap_prod_code, cap_card_type, cap_card_stat,cap_acct_no
           INTO v_prod_code, v_prod_cattype, v_applpan_cardstat,v_acct_number
           FROM cms_appl_pan
          WHERE cap_pan_code = gethash (p_card_no) AND cap_inst_code = p_inst_code;
      EXCEPTION
         WHEN OTHERS THEN
            NULL;
      END;
      END IF;

      IF v_acct_type IS NULL THEN
      BEGIN
         SELECT cam_type_code
           INTO v_acct_type
           FROM cms_acct_mast
          WHERE cam_acct_no = v_acct_number AND cam_inst_code = p_inst_code
          FOR UPDATE NOWAIT;
      EXCEPTION
         WHEN OTHERS THEN
            NULL;
      END;
      END IF;
      --En added by Pankaj S. for 10871

      --Sn create a entry in txn log
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
          RULE_INDICATOR,
          RULEGROUPID,
          MCCODE,
          CURRENCYCODE,
          ADDCHARGE,
          PRODUCTID,
          CATEGORYID,
          TIPS,
          DECLINE_RULEID,
          ATM_NAME_LOCATION,
          AUTH_ID,
          TRANS_DESC,
          AMOUNT,
          PREAUTHAMOUNT,
          PARTIALAMOUNT,
          MCCODEGROUPID,
          CURRENCYCODEGROUPID,
          TRANSCODEGROUPID,
          RULES,
          PREAUTH_DATE,
          GL_UPD_FLAG,
          SYSTEM_TRACE_AUDIT_NO,
          INSTCODE,
          FEECODE,
          TRANFEE_AMT,
          SERVICETAX_AMT,
          CESS_AMT,
          CR_DR_FLAG,
          TRANFEE_CR_ACCTNO,
          TRANFEE_DR_ACCTNO,
          TRAN_ST_CALC_FLAG,
          TRAN_CESS_CALC_FLAG,
          TRAN_ST_CR_ACCTNO,
          TRAN_ST_DR_ACCTNO,
          TRAN_CESS_CR_ACCTNO,
          TRAN_CESS_DR_ACCTNO,
          CUSTOMER_CARD_NO_ENCR,
          TOPUP_CARD_NO_ENCR,
          PROXY_NUMBER,
          REVERSAL_CODE,
          CUSTOMER_ACCT_NO,
          ACCT_BALANCE,
          LEDGER_BALANCE,
          RESPONSE_ID,
              ACHFILENAME,
                ODFI  ,
                RDFI  ,
                SECCODES,
                IMPDATE ,
                PROCESSDATE,
                EFFECTIVEDATE,
                TRACENUMBER  ,
                INCOMING_CRFILEID,
                ACHTRANTYPE_ID   ,
                BEFRETRAN_LEDGERBAL,
                BEFRETRAN_AVAILBALANCE,
                INDIDNUM,
                INDNAME  ,
                COMPANYNAME,
                COMPANYID,
                ACH_ID    ,
                COMPENTRYDESC,
             CUSTOMERLASTNAME,
             cardstatus  ,
             PROCESSTYPE,
             FEE_PLAN,
             FEEATTACHTYPE,
             --Sn added by Pankaj S. for 10871
             acct_type,
             time_stamp,
             error_msg
             --En added by Pankaj S. for 10871

          )
        VALUES
         (p_MSG,
          p_RRN,
          p_DELIVERY_CHANNEL,
          p_TERM_ID,
          V_BUSINESS_DATE,
          p_TXN_CODE,
          V_TXN_TYPE,
          p_TXN_MODE,
          DECODE(p_RESP_CODE, '00', 'C', 'F'),
          p_RESP_CODE,
          p_TRAN_DATE,
          SUBSTR(p_TRAN_TIME, 1, 10),
          V_HASH_PAN,
          NULL,
          NULL, --p_topup_acctno ,
          NULL, --p_topup_accttype,
          p_BANK_CODE,
          TRIM(TO_CHAR(nvl(V_TOTAL_AMT,0), '99999999999999990.99')), --modified for 10871
          NULL,
          NULL,
          p_MCC_CODE,
          p_CURR_CODE,
          NULL, -- p_add_charge,
          V_PROD_CODE,
          V_PROD_CATTYPE,
          to_char(nvl(p_TIP_AMT,0),'999999999999999990.99'),  --Formatted by Pankaj S. for 10871
          NULL,
          p_ATMNAME_LOC,
          V_AUTH_ID,
          V_TRANS_DESC,
          TRIM(TO_CHAR(nvl(V_TRAN_AMT,0), '999999999999999990.99')), --modified for 10871
          '0.00', --modified by Pankaj S. for 10871
          '0.00', --modified by Pankaj S. for 10871  -- Partial amount (will be given for partial txn)
          p_MCCCODE_GROUPID,
          p_CURRCODE_GROUPID,
          p_TRANSCODE_GROUPID,
          p_RULES,
          p_PREAUTH_DATE,
          V_GL_UPD_FLAG,
          p_STAN,
          p_INST_CODE,
          V_FEE_CODE,
          NVL(V_FEE_AMT,0), --Modified by Pankaj S. for 10871
          NVL(V_SERVICETAX_AMOUNT,0), --Modified by Pankaj S. for 10871
          NVL(V_CESS_AMOUNT,0), --Modified by Pankaj S. for 10871
          V_DR_CR_FLAG,
          V_FEE_CRACCT_NO,
          V_FEE_DRACCT_NO,
          V_ST_CALC_FLAG,
          V_CESS_CALC_FLAG,
          V_ST_CRACCT_NO,
          V_ST_DRACCT_NO,
          V_CESS_CRACCT_NO,
          V_CESS_DRACCT_NO,
          V_ENCR_PAN,
          NULL,
          V_PROXUNUMBER,
          p_RVSL_CODE,
          V_ACCT_NUMBER,
          DECODE(p_RESP_CODE, '00', V_UPD_AMT, V_ACCT_BALANCE),
          DECODE(p_RESP_CODE, '00', V_UPD_LEDGER_BAL, V_LEDGER_BAL),
          V_RESP_CDE,
         p_ACHFILENAME ,
        p_ODFI,
        p_RDFI,
        p_SECCODES,
        p_IMPDATE ,
        p_PROCESSDATE,
        p_EFFECTIVEDATE,
        p_TRACENUMBER  ,
        p_INCOMING_CRFILEID,
        p_ACHTRANTYPE_ID   ,
        p_BEFRETRAN_LEDGERBAL,
        p_BEFRETRAN_AVAILBALANCE,
        p_INDIDNUM ,
        p_INDNAME  ,
        p_COMPANYNAME,
        p_COMPANYID ,
        p_ACH_ID ,
        p_COMPENTRYDESC,
        p_CUSTOMERLASTNAME,
        V_APPLPAN_CARDSTAT ,
        p_PROCESSTYPe,
        V_FEE_PLAN,
        V_FEEATTACH_TYPE,
        --Sn added by Pankaj S. for 10871
        v_acct_type,
        nvl(v_timestamp,systimestamp),
        v_err_msg
        --En added by Pankaj S. for 10871
        );

        p_CAPTURE_DATE := V_BUSINESS_DATE;
      EXCEPTION
        WHEN OTHERS THEN
         ROLLBACK;
         p_RESP_CODE := '89';
         p_RESP_MSG  := 'Problem while inserting data into transaction log  dtl' ||
                       SUBSTR(SQLERRM, 1, 300);
      END;

    End if;

  --If transaction is approved from csr or Host application p_PROCESSTYPE is n will update and the same record moved to history
  if p_PROCESSTYPE = 'N' THEN
  BEGIN
  v_Retdate := TO_DATE(SUBSTR(TRIM(p_tran_date), 1, 8), 'yyyymmdd');

       select (add_months(trunc(sysdate,'MM'),'-'||RETENTION_PERIOD))
       INTO   v_Retperiod 
       FROM DBA_OPERATIONS.ARCHIVE_MGMNT_CTL 
       WHERE  OPERATION_TYPE='ARCHIVE' 
       AND OBJECT_NAME='TRANSACTIONLOG_EBR';



IF (v_Retdate>v_Retperiod)
    THEN
    update transactionlog set PROCESSTYPE= p_PROCESSTYPE,response_code=p_RESP_CODE 
    WHERE RRN = p_RRN AND BUSINESS_DATE = p_TRAN_DATE AND
         TXN_CODE = p_TXN_CODE AND INSTCODE = p_INST_CODE ;
    ELSE
       update VMSCMS_HISTORY.TRANSACTIONLOG_HIST  set PROCESSTYPE= p_PROCESSTYPE,response_code=p_RESP_CODE 
       WHERE RRN = p_RRN AND BUSINESS_DATE = p_TRAN_DATE AND
         TXN_CODE = p_TXN_CODE AND INSTCODE = p_INST_CODE ; --Added for VMS-5733/FSP-991
    END IF;              

    EXCEPTION
      WHEN OTHERS THEN
        p_RESP_CODE := '89';
        p_RESP_MSG  := 'Error while updating transactionlog' ||
                     SUBSTR(SQLERRM, 1, 300);
    END;
    end if;
  --En create a entry in txn log


EXCEPTION
  WHEN OTHERS THEN
    ROLLBACK;
    p_RESP_CODE := '89';
    p_RESP_MSG  := 'Main exception from  authorization ' ||
                 SUBSTR(SQLERRM, 1, 300);
END;

/

show error