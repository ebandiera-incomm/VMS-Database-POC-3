CREATE OR REPLACE PROCEDURE VMSCMS.SP_IVR_UPDATE_PIN (P_INSTCODE         IN NUMBER,
                                       P_CARDNUM          IN VARCHAR2,
                                       P_RRN              IN VARCHAR2,
                                       P_TRANDATE         IN VARCHAR2,
                                       P_TRANTIME         IN VARCHAR2,
                                       P_TXN_CODE         IN VARCHAR2,
                                       P_DELIVERY_CHANNEL IN VARCHAR2,
                                       P_ANI              IN VARCHAR2,
                                       P_DNI              IN VARCHAR2,
                                       P_RESP_CODE        OUT VARCHAR2,
                                       P_ERRMSG           OUT VARCHAR2,
                     P_CARD_STATUS      OUT VARCHAR2,  --Added for MVCSD-4099(IVR PIN Update /Reversal transaction changes) on 02/09/2013
                     P_CARD_STAT_DESC   OUT VARCHAR2,  --Added for MVCSD-4099(IVR PIN Update /Reversal transaction changes) on 02/09/2013
                     P_KYC_FLAG         OUT VARCHAR2 ) --Added for MVCSD-4099(IVR PIN Update /Reversal transaction changes) on 02/09/2013
                     AS

  /*************************************************
      * Modified by      : T.Narayanan
      * Modified Reason  :reverted GPRCard no changes
      * Modified Date    : 09-Oct-2012
      * Reviewer         : Saravanakumar
      * Reviewed Date    :  11-Oct-2012
      * Release Number     :  CMS3.5.1_RI0019

     * Modified By      :  Ramesh.A
     * Modified Date    :  02-Sep-13
     * Modified Reason  :  MVCSD-4099(IVR PIN Update /Reversal transaction changes)
     * Reviewer         :  Dhiraj
     * Reviewed Date    :  02-Sep-13
     * Release Number   :  RI0024.4_B0007

     * Modified Date    : 16-Dec-2013
     * Modified By      : Sagar More
     * Modified for     : Defect ID 13160
     * Modified reason  : To log below details in transactinlog if applicable
                          Acct_type,timestamp,dr_cr_flag,product code,cardtype,error_msg
     * Reviewer         : Dhiraj
     * Reviewed Date    : 16-Dec-2013
     * Release Number   : RI0024.7_B0001

     * Modified By      :  Abdul Hameed M.A
     * Modified Date    :  05-Jan-15
     * Modified Reason  :  15984
     * Reviewer         :
     * Reviewed Date    :
     * Release Number   :


     * Modified By      :  Siva kumar M
     * Modified Date    :  06-Mar-15
     * Modified Reason  :  DFCTNM-28&29
     * Reviewer         :  SaravanaKumar A
     * Reviewed Date    :  06-Mar-15
     * Release Number   :  3.0_B0001

      * Modified By      : Siva Kumar M
     * Modified Date    : 09-Mar-2015
     * Modified for     : review changes
     * Reviewer         : Pankaj S
     * Reviewed Date    : 09-Mar-2015
     * Build Number     : VMSGPRHOSTCSD_3.0_B0001

     * Modified By      : Siva Kumar M
     * Modified Date    : 23-July-2015
     * Modified for     : FSS-3597&FSS-3598
     * Reviewer         : Pankaj S
     * Reviewed Date    : 23-July-2015
     * Build Number     : VMSGPRHOSTCSD_3.0.4_B0002

	 	 * Modified by       : DHINAKARAN B
     * Modified Date     : 18-Jul-17
     * Modified For      : FSS-5172 - B2B changes
     * Reviewer          : Saravanakumar A
     * Build Number      : VMSGPRHOST_17.07

     * Modified By      : UBAIDUR RAHMAN H
    * Modified Date    : 16-JAN-2018
    * Purpose          : CURRENCY CODE CHANGES FROM INST LEVEL TO BIN LEVEL.
    * Reviewer         : Vini
    * Release Number   : VMSGPRHOST18.1
	
	 * Modified Date    : 30-Nov-2020
     * Modified By      : Puvanesh.N/Ubaidur.H
     * Modified for     : VMS-3349 - IVR callLogId Validation
     * Modified reason  : IVR Call Log ID transaction - Blocking Session while fetching the account balance.
     * Reviewer         : Saravanakumar
     * Reviewed Date    : 30-Nov-2020
     * Release Number   : R39 Build 2
    
    * Modified By      : venkat Singamaneni
    * Modified Date    : 4-25-2022
    * Purpose          : Archival changes.
    * Reviewer         : Jyothi G
    * Release Number   : VMSGPRHOST60 for VMS-5735/FSP-991
	 *************************************************/
  V_CAP_CARD_STAT   CMS_APPL_PAN.CAP_CARD_STAT%TYPE;
  V_CAP_CAFGEN_FLAG CMS_APPL_PAN.CAP_CAFGEN_FLAG%TYPE;
  V_FIRSTTIME_TOPUP CMS_APPL_PAN.CAP_FIRSTTIME_TOPUP%TYPE;
  V_CURRCODE        VARCHAR2(3);
  V_APPL_CODE       CMS_APPL_MAST.CAM_APPL_CODE%TYPE;
  V_RESPCODE        VARCHAR2(5);
  V_ERRMSG         VARCHAR2(500);
  V_AUTHMSG         VARCHAR2(500);
  V_CAPTURE_DATE    DATE;
  V_MBRNUMB         CMS_APPL_PAN.CAP_MBR_NUMB%TYPE;
  V_TXN_TYPE        CMS_FUNC_MAST.CFM_TXN_TYPE%TYPE;
  V_INIL_AUTHID     TRANSACTIONLOG.AUTH_ID%TYPE;
  V_HASH_PAN            CMS_APPL_PAN.CAP_PAN_CODE%TYPE;
  V_ENCR_PAN            CMS_APPL_PAN.CAP_PAN_CODE_ENCR%TYPE;
  V_RRN_COUNT           NUMBER;
  V_DELCHANNEL_CODE     VARCHAR2(2);
  V_BASE_CURR           CMS_BIN_PARAM.CBP_PARAM_VALUE%TYPE;
  V_TRAN_DATE           DATE;
  V_TRAN_AMT            NUMBER;
  V_BUSINESS_DATE       DATE;
  V_BUSINESS_TIME       VARCHAR2(5);
  V_CUTOFF_TIME         VARCHAR2(5);
  V_CUST_CODE           CMS_CUST_MAST.CCM_CUST_CODE%TYPE;
  V_TRAN_COUNT          NUMBER;
  V_TRAN_COUNT_REVERSAL NUMBER;
  V_CAP_PROD_CATG       VARCHAR2(100);
  -- Commented by UBAIDUR RAHMAN on 25-Sep-2017
 -- V_MMPOS_USAGEAMNT     CMS_TRANSLIMIT_CHECK.CTC_MMPOSUSAGE_AMT%TYPE;
 -- V_MMPOS_USAGELIMIT    CMS_TRANSLIMIT_CHECK.CTC_MMPOSUSAGE_LIMIT%TYPE;
  V_BUSINESS_DATE_TRAN  DATE;
  V_ACCT_BALANCE        NUMBER;
  V_LEDGER_BALANCE      NUMBER;
  V_PROD_CODE           CMS_PROD_MAST.CPM_PROD_CODE%TYPE;
  V_PROD_CATTYPE        CMS_PROD_CATTYPE.CPC_CARD_TYPE%TYPE;
  V_EXPRY_DATE          DATE;
  V_ATMONLINE_LIMIT     CMS_APPL_PAN.CAP_ATM_ONLINE_LIMIT%TYPE;
  V_POSONLINE_LIMIT     CMS_APPL_PAN.CAP_ATM_OFFLINE_LIMIT%TYPE;
  V_PROXYNUMBER         CMS_APPL_PAN.CAP_PROXY_NUMBER%TYPE;
  V_ACCT_NUMBER         CMS_APPL_PAN.CAP_ACCT_NO%TYPE;
  V_COUNT               NUMBER;
  V_DR_CR_FLAG  VARCHAR2(2);
  V_OUTPUT_TYPE VARCHAR2(2);
  V_TRAN_TYPE   VARCHAR2(2);
  V_TRANS_DESC  CMS_TRANSACTION_MAST.CTM_TRAN_DESC%TYPE; --Added for transaction detail report on 210812

  --SN Added for 13160
  v_acct_type cms_acct_mast.cam_type_code%type;
  v_timestamp timestamp(3);
  --EN Added for 13160

  --SN ADDED FOR DFCTNM-28


   V_PINCHANGE_FLAG  CMS_PROD_CATTYPE.CPC_PINCHANGE_FLAG%TYPE;

   V_IPIN_OFFDATA    CMS_APPL_PAN.CAP_IPIN_OFFSET%TYPE;
  --EN ADDED FOR DFCTNM-28
  -- added for  FSS-3597&FSS-3598
   v_evmprevalid_flag   	cms_appl_pan.cap_emvprevalid_flag%TYPE;
   V_PROFILE_CODE       	CMS_PROD_CATTYPE.CPC_PROFILE_CODE%TYPE;
   V_HASHKEY_ID         	CMS_TRANSACTION_LOG_DTL.CTD_HASHKEY_ID%TYPE;
   V_STATUS_CHK             NUMBER;
   V_precheck_flag          PLS_INTEGER;
   EXP_MAIN_REJECT_RECORD 	EXCEPTION;
  v_Retperiod  date;  --Added for VMS-5735/FSP-991
v_Retdate  date; --Added for VMS-5735/FSP-991
BEGIN
BEGIN
  P_ERRMSG   := 'OK';
  V_RESPCODE := '1';
    --SN CREATE HASH PAN
  BEGIN
    V_HASH_PAN := GETHASH(P_CARDNUM);
  EXCEPTION
    WHEN OTHERS THEN
     V_ERRMSG := 'Error while converting pan ' || SUBSTR(SQLERRM, 1, 200);
     RAISE EXP_MAIN_REJECT_RECORD;
  END;
  --EN CREATE HASH PAN

  --SN create encr pan
  BEGIN
    V_ENCR_PAN := FN_EMAPS_MAIN(P_CARDNUM);
  EXCEPTION
    WHEN OTHERS THEN
     V_RESPCODE := '12';
     V_ERRMSG   := 'Error while converting pan ' ||
                SUBSTR(SQLERRM, 1, 200);
     RAISE EXP_MAIN_REJECT_RECORD;
  END;

  --Create Authid

BEGIN
    SELECT
        lpad(seq_auth_id.NEXTVAL, 6, '0')
    INTO v_inil_authid
    FROM
        dual;

EXCEPTION
    WHEN OTHERS THEN
        V_ERRMSG := 'Error while generating authid '
                    || substr(sqlerrm, 1, 300);
        V_RESPCODE := '21';
        RAISE EXP_MAIN_REJECT_RECORD;
END;

v_timestamp := systimestamp;

-- Create Hashkey id

BEGIN
    v_hashkey_id := gethash(p_delivery_channel
                            || p_txn_code
                            || p_cardnum
                            || p_rrn
                            || TO_CHAR(nvl(v_timestamp, systimestamp), 'YYYYMMDDHH24MISSFF5'));
EXCEPTION
    WHEN OTHERS THEN
        V_RESPCODE := '21';
        V_ERRMSG := 'Error while generating hashkey_id- '
                    || substr(sqlerrm, 1, 200);
        RAISE EXP_MAIN_REJECT_RECORD;
END;

  --Sn find card detail
  BEGIN
    SELECT CAP_PROD_CODE,
         CAP_CARD_TYPE,
         CAP_EXPRY_DATE,
         CAP_CARD_STAT,
         CAP_ATM_ONLINE_LIMIT,
         CAP_POS_ONLINE_LIMIT,
         CAP_PROD_CATG,
         CAP_CAFGEN_FLAG,
         CAP_APPL_CODE,
         CAP_FIRSTTIME_TOPUP,
         CAP_MBR_NUMB,
         CAP_CUST_CODE,
         CAP_PROXY_NUMBER,
         CAP_ACCT_NO,
         CAP_IPIN_OFFSET,
         NVL(cap_emvprevalid_flag,'N')
     INTO V_PROD_CODE,
         V_PROD_CATTYPE,
         V_EXPRY_DATE,
         V_CAP_CARD_STAT,
         V_ATMONLINE_LIMIT,
         V_ATMONLINE_LIMIT,
         V_CAP_PROD_CATG,
         V_CAP_CAFGEN_FLAG,
         V_APPL_CODE,
         V_FIRSTTIME_TOPUP,
         V_MBRNUMB,
         V_CUST_CODE,
         V_PROXYNUMBER,
         V_ACCT_NUMBER,
         V_IPIN_OFFDATA,
         v_evmprevalid_flag
     FROM CMS_APPL_PAN
    WHERE CAP_INST_CODE = P_INSTCODE AND CAP_PAN_CODE = V_HASH_PAN;
  EXCEPTION
    WHEN NO_DATA_FOUND THEN
     V_RESPCODE := '16'; --Ineligible Transaction
     V_ERRMSG   := 'Card number not found ' || P_TXN_CODE;
     RAISE EXP_MAIN_REJECT_RECORD;
    WHEN OTHERS THEN
     V_RESPCODE := '12';
     V_ERRMSG   := 'Problem while selecting card detail' ||
                SUBSTR(SQLERRM, 1, 200);
     RAISE EXP_MAIN_REJECT_RECORD;
  END;

  --En find card detail

  BEGIN


     SELECT  CPC_PINCHANGE_FLAG,CPC_PROFILE_CODE
     INTO    V_PINCHANGE_FLAG,V_PROFILE_CODE
     FROM CMS_PROD_CATTYPE
     WHERE CPC_PROD_CODE=V_PROD_CODE
	   AND CPC_CARD_TYPE= V_PROD_CATTYPE
     AND CPC_INST_CODE=P_INSTCODE;

    EXCEPTION
    WHEN OTHERS THEN

     V_RESPCODE := '21';
     V_ERRMSG   := 'Problem while selecting PIN Retrieval detail' ||
                SUBSTR(SQLERRM, 1, 200);

     RAISE EXP_MAIN_REJECT_RECORD;

END;
  --Sn find debit and credit flag

  BEGIN
    SELECT CTM_CREDIT_DEBIT_FLAG,
         CTM_OUTPUT_TYPE,
         TO_NUMBER(DECODE(CTM_TRAN_TYPE, 'N', '0', 'F', '1')),
         CTM_TRAN_TYPE,
         CTM_TRAN_DESC
     INTO V_DR_CR_FLAG,
         V_OUTPUT_TYPE,
         V_TXN_TYPE,
         V_TRAN_TYPE,
         V_TRANS_DESC
     FROM CMS_TRANSACTION_MAST
    WHERE CTM_TRAN_CODE = P_TXN_CODE AND
         CTM_DELIVERY_CHANNEL = P_DELIVERY_CHANNEL AND
         CTM_INST_CODE = P_INSTCODE;
  EXCEPTION
    WHEN NO_DATA_FOUND THEN
     V_RESPCODE := '12'; --ineligible transaction
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
    V_TRAN_DATE := TO_DATE(SUBSTR(TRIM(P_TRANDATE), 1, 8), 'yyyymmdd');
  EXCEPTION
    WHEN OTHERS THEN
     V_RESPCODE := '45'; -- Server Declined -220509
     V_ERRMSG   := 'Problem while converting transaction date ' ||
                SUBSTR(SQLERRM, 1, 200);
     RAISE EXP_MAIN_REJECT_RECORD;
  END;
  --En Transaction Date Check

  --Sn Transaction Time Check
  BEGIN

    V_TRAN_DATE := TO_DATE(SUBSTR(TRIM(P_TRANDATE), 1, 8) || ' ' ||
                      SUBSTR(TRIM(P_TRANTIME), 1, 10),
                      'yyyymmdd hh24:mi:ss');

  EXCEPTION
    WHEN OTHERS THEN
     V_RESPCODE := '32'; -- Server Declined -220509
     V_ERRMSG   := 'Problem while converting transaction Time ' ||
                SUBSTR(SQLERRM, 1, 200);
     RAISE EXP_MAIN_REJECT_RECORD;
  END;
  --En Transaction Time Check

  V_BUSINESS_TIME := TO_CHAR(V_TRAN_DATE, 'HH24:MI');



  IF V_BUSINESS_TIME > V_CUTOFF_TIME THEN
    V_BUSINESS_DATE := TRUNC(V_TRAN_DATE) + 1;
  ELSE
    V_BUSINESS_DATE := TRUNC(V_TRAN_DATE);
  END IF;

  BEGIN

    SELECT CDM_CHANNEL_CODE
     INTO V_DELCHANNEL_CODE
     FROM CMS_DELCHANNEL_MAST
    WHERE CDM_CHANNEL_DESC = 'IVR' AND CDM_INST_CODE = P_INSTCODE;
    --IF the DeliveryChannel is MMPOS then the base currency will be the txn curr

    IF V_DELCHANNEL_CODE = P_DELIVERY_CHANNEL THEN

     BEGIN
--       SELECT CIP_PARAM_VALUE
--        INTO V_BASE_CURR
--        FROM CMS_INST_PARAM
--        WHERE CIP_INST_CODE = P_INSTCODE AND CIP_PARAM_KEY = 'CURRENCY';

         SELECT TRIM(cbp_param_value)
			    INTO v_base_curr
			   FROM cms_bin_param
			   WHERE cbp_param_name = 'Currency'
          AND cbp_inst_code= p_instcode
          AND cbp_profile_code = V_PROFILE_CODE;

       IF V_BASE_CURR IS NULL THEN
        V_RESPCODE := '21';
        V_ERRMSG   := 'Base currency cannot be null ';
        RAISE EXP_MAIN_REJECT_RECORD;
       END IF;
     EXCEPTION
       WHEN NO_DATA_FOUND THEN
        V_RESPCODE := '21';
        V_ERRMSG   := 'Base currency is not defined for the PROFILE ';
        RAISE EXP_MAIN_REJECT_RECORD;
       WHEN OTHERS THEN
        V_RESPCODE := '21';
        V_ERRMSG   := 'Error while selecting bese currecy  ' ||
                    SUBSTR(SQLERRM, 1, 200);
        RAISE EXP_MAIN_REJECT_RECORD;
     END;

     V_CURRCODE := V_BASE_CURR;

    ELSE
     V_CURRCODE := '840';
    END IF;

  EXCEPTION
    WHEN OTHERS THEN
     V_ERRMSG := 'Error while selecting the Delivery Channel of IVR  ' ||
               SUBSTR(SQLERRM, 1, 200);
     RAISE EXP_MAIN_REJECT_RECORD;

  END;

  --Sn Duplicate RRN Check.IF duplicate RRN log the txn and return

  BEGIN

--Added for VMS-5735/FSP-991
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
    WHERE INSTCODE = P_INSTCODE AND RRN = P_RRN AND
         BUSINESS_DATE = P_TRANDATE AND
         DELIVERY_CHANNEL = P_DELIVERY_CHANNEL; --Added by ramkumar.Mk on 25 march 2012
ELSE
   SELECT COUNT(1)
     INTO V_RRN_COUNT
     FROM VMSCMS_HISTORY.TRANSACTIONLOG_HIST --Added for VMS-5733/FSP-991
    WHERE INSTCODE = P_INSTCODE AND RRN = P_RRN AND
         BUSINESS_DATE = P_TRANDATE AND
         DELIVERY_CHANNEL = P_DELIVERY_CHANNEL;
END IF;

    IF V_RRN_COUNT > 0 THEN

     V_RESPCODE := '22';
     V_ERRMSG   := 'Duplicate RRN ' || ' on ' || P_TRANDATE;
     RAISE EXP_MAIN_REJECT_RECORD;

    END IF;

  END;

  --En Duplicate RRN Check

   -- added for dfctnm-28

  IF     P_DELIVERY_CHANNEL='07' AND  P_TXN_CODE in ('32','33') THEN

    -- Get the PINRetrieve  configuration.


   IF P_DELIVERY_CHANNEL='07' AND  P_TXN_CODE ='32' THEN

     IF V_PINCHANGE_FLAG = 1 THEN

         IF  V_IPIN_OFFDATA IS NULL  THEN

              --PIN  NOT YET GENERETED.
          V_RESPCODE := '101';
          V_ERRMSG   := 'Pin Generation Process Not done';
           RAISE EXP_MAIN_REJECT_RECORD;
         ELSE

          P_ERRMSG :=  V_IPIN_OFFDATA;
               -- added for  FSS-3597&FSS-3598
              IF v_evmprevalid_flag ='L' THEN

              BEGIN

                  UPDATE CMS_APPL_PAN
                  SET cap_emvprevalid_flag='P'
                  WHERE CAP_INST_CODE = P_INSTCODE
                  AND CAP_PAN_CODE = V_HASH_PAN;

                IF SQL%ROWCOUNT =0 THEN

                     V_ERRMSG   := 'Error while updating pinretrieve_flag ' || SUBSTR(SQLERRM, 1, 200);
                     V_RESPCODE := '21';
                     RAISE EXP_MAIN_REJECT_RECORD;
                END IF;

              EXCEPTION
               WHEN EXP_MAIN_REJECT_RECORD THEN
               RAISE;

               WHEN OTHERS THEN
                     V_ERRMSG   := 'Error while updating pinretrieve_flag ' || SUBSTR(SQLERRM, 1, 200);
                     V_RESPCODE := '21';
                     RAISE EXP_MAIN_REJECT_RECORD;

              END;

             END IF;



         END IF;

     ELSE

        --Pin retrieval configuration not done..

        V_RESPCODE := '227';
        V_ERRMSG   := 'Pin Retrieval Configuration not Done';
        RAISE EXP_MAIN_REJECT_RECORD;

      END IF;

   elsIF P_DELIVERY_CHANNEL='07' AND  P_TXN_CODE ='33' THEN

    P_ERRMSG :=  V_PINCHANGE_FLAG;

   END IF;

  END IF;
  
	-- Modified for VMS-3349 Start
 
--Sn GPR Card status check
        BEGIN
            SP_STATUS_CHECK_GPR (P_INSTCODE,
                                        P_CARDNUM,
                                        P_DELIVERY_CHANNEL,
                                        V_EXPRY_DATE,   
                                        V_CAP_CARD_STAT,     
                                        P_TXN_CODE,
                                        '0',
                                        V_PROD_CODE,
                                        V_PROD_CATTYPE,
                                        '0200',
                                        P_TRANDATE,
                                        P_TRANTIME,
                                        NULL,
                                        NULL,  
                                        NULL,
                                        V_RESPCODE,
                                        V_ERRMSG);



            IF ( (V_RESPCODE <> '1' AND V_ERRMSG <> 'OK')
                 OR (V_RESPCODE <> '0' AND V_ERRMSG <> 'OK'))
            THEN
                RAISE EXP_MAIN_REJECT_RECORD;
            ELSE
                V_STATUS_CHK := V_RESPCODE;
                V_RESPCODE := '1';
            END IF;
        EXCEPTION
            WHEN EXP_MAIN_REJECT_RECORD
            THEN
                RAISE;
            WHEN OTHERS
            THEN
                V_RESPCODE := '21';
                V_ERRMSG :=
                    'Error from GPR Card Status Check '
                    || SUBSTR (SQLERRM, 1, 200);
                RAISE EXP_MAIN_REJECT_RECORD;
        END;
  
        --En GPR Card status check
        IF V_STATUS_CHK = '1'
        THEN
            -- Expiry Check

                BEGIN

                        IF TO_DATE (P_TRANDATE, 'YYYYMMDD') >
                                LAST_DAY (V_EXPRY_DATE)
                        THEN
                            V_RESPCODE := '13';
                            V_ERRMSG := 'EXPIRED CARD';
                            RAISE EXP_MAIN_REJECT_RECORD;
                        END IF;


                EXCEPTION
                    WHEN EXP_MAIN_REJECT_RECORD
                    THEN
                        RAISE;
                    WHEN OTHERS
                    THEN
                        V_RESPCODE := '21';
                        V_ERRMSG :=
                                'ERROR IN EXPIRY DATE CHECK : Tran Date - '
                            || P_TRANDATE
                            || ', Expiry Date - '
                            || V_EXPRY_DATE
                            || ','
                            || SUBSTR (SQLERRM, 1, 200);
                        RAISE EXP_MAIN_REJECT_RECORD;
                END; 
            -- End Expiry Check

			BEGIN
				SELECT ptp_param_value
					INTO V_precheck_flag
				FROM pcms_tranauth_param
				WHERE ptp_param_name = 'PRE CHECK' AND ptp_inst_code = P_INSTCODE;

			EXCEPTION
				WHEN OTHERS   THEN
					V_RESPCODE := '21';
					V_ERRMSG :=  'Error while selecting precheck flag' || SUBSTR (SQLERRM, 1, 200);
				RAISE EXP_MAIN_REJECT_RECORD;
			END; 
            --Sn check for precheck
    
            IF V_precheck_flag = 1
                THEN
                    BEGIN
                 
                        SP_PRECHECK_TXN (P_INSTCODE,
                                              P_CARDNUM,
                                              P_DELIVERY_CHANNEL,
                                              V_EXPRY_DATE,
                                              V_CAP_CARD_STAT,
                                              P_TXN_CODE,
                                              '0',
                                              P_TRANDATE,
                                              P_TRANTIME,
                                              V_TRAN_AMT,        
                                              V_ATMONLINE_LIMIT, 
                                              V_POSONLINE_LIMIT,  
                                              V_RESPCODE,
                                              V_ERRMSG);


                    IF (V_RESPCODE <> '1' OR V_ERRMSG <> 'OK')
                    THEN
                        RAISE EXP_MAIN_REJECT_RECORD;
                    END IF;
                EXCEPTION
                    WHEN EXP_MAIN_REJECT_RECORD
                    THEN
                        RAISE;
                    WHEN OTHERS
                    THEN
                        V_RESPCODE := '21';
                        V_ERRMSG  :=
                            'Error from precheck processes '
                            || SUBSTR (SQLERRM, 1, 200);
                        RAISE EXP_MAIN_REJECT_RECORD;
                END;
                END IF;

    END IF;

    --Sn of Getting  the Acct Balannce
    BEGIN
     SELECT CAM_ACCT_BAL, CAM_LEDGER_BAL
       INTO V_ACCT_BALANCE, V_LEDGER_BALANCE
       FROM CMS_ACCT_MAST
      WHERE CAM_ACCT_NO =V_ACCT_NUMBER
       AND CAM_INST_CODE = P_INSTCODE;
       -- FOR UPDATE NOWAIT;
    EXCEPTION
     WHEN NO_DATA_FOUND THEN
       V_RESPCODE := '14'; --Ineligible Transaction
       V_ERRMSG   := 'Invalid Card ';
       RAISE EXP_MAIN_REJECT_RECORD;
     WHEN OTHERS THEN
       V_RESPCODE := '12';
       V_ERRMSG   := 'Error while selecting data from card Master for card number ' ||
                  V_HASH_PAN;
       RAISE EXP_MAIN_REJECT_RECORD;
    END;
  
  --Sn Getting Card Status description for MVCSD-4099(IVR PIN Update /Reversal transaction changes) on 02/09/2013
BEGIN
    SELECT ccs_stat_desc
    INTO p_card_stat_desc
    FROM cms_card_stat
    WHERE ccs_stat_code = v_cap_card_stat AND ccs_inst_code = p_instcode;

    p_card_status := v_cap_card_stat;

  EXCEPTION
     WHEN NO_DATA_FOUND THEN
       V_RESPCODE := '21';
       V_ERRMSG   := 'Card Status not found ';
       RAISE EXP_MAIN_REJECT_RECORD;
  WHEN OTHERS THEN
       V_RESPCODE := '21';
       V_ERRMSG   := 'Error while selecting data from card status ' ||SUBSTR(SQLERRM, 1, 200);
       RAISE EXP_MAIN_REJECT_RECORD;
END;
--En Getting Card Status description for MVCSD-4099(IVR PIN Update /Reversal transaction changes) on 02/09/2013
--Sn Getting KYC flag for MVCSD-4099(IVR PIN Update /Reversal transaction changes) on 02/09/2013
  BEGIN
/*
      SELECT CCI_KYC_FLAG INTO p_kyc_flag FROM cms_caf_info_entry
      WHERE CCI_APPL_CODE= v_appl_code AND cci_inst_code=p_instcode;*/
      --Modified for 15984
      select CCM_KYC_FLAG INTO p_kyc_flag from CMS_CUST_MAST where
      ccm_cust_code=V_CUST_CODE and ccm_inst_code=p_instcode;

   EXCEPTION
     WHEN NO_DATA_FOUND THEN
       V_RESPCODE := '21';
       V_ERRMSG   := 'KYC FLAG not found ';
       RAISE EXP_MAIN_REJECT_RECORD;
  WHEN OTHERS THEN
       V_RESPCODE := '21';
       V_ERRMSG   := 'Error while selecting data from caf_info ' ||SUBSTR(SQLERRM, 1, 200);
       RAISE EXP_MAIN_REJECT_RECORD;
  END;
  --En Getting KYC flag for MVCSD-4099(IVR PIN Update /Reversal transaction changes) on 02/09/2013

		 --P_ERRMSG    := V_ERRMSG;
		 P_RESP_CODE := V_RESPCODE;
		 -- Assign the response code to the out parameter  

EXCEPTION
  --<< MAIN EXCEPTION >>

  /*WHEN EXP_AUTH_REJECT_TXN THEN
    P_ERRMSG    := V_ERRMSG;
    P_RESP_CODE := V_RESPCODE;
    rollback;*/

  WHEN EXP_MAIN_REJECT_RECORD THEN
    P_ERRMSG    := V_ERRMSG;
    P_RESP_CODE := V_RESPCODE;
    ROLLBACK;

  WHEN OTHERS THEN
    P_RESP_CODE := '21';
    P_ERRMSG := ' Error from main ' || SUBSTR(SQLERRM, 1, 200);
    ROLLBACK;

END;

	BEGIN

		 SELECT CMS_ISO_RESPCDE
		   INTO P_RESP_CODE
		   FROM CMS_RESPONSE_MAST
		  WHERE CMS_INST_CODE = P_INSTCODE AND
			   CMS_DELIVERY_CHANNEL = P_DELIVERY_CHANNEL AND
			   CMS_RESPONSE_ID = V_RESPCODE;
		EXCEPTION
		 WHEN OTHERS THEN
		   P_ERRMSG    := 'Problem while selecting data from response master ' ||
					   V_RESPCODE || SUBSTR(SQLERRM, 1, 300);
		   P_RESP_CODE := '89';
		   ---ISO MESSAGE FOR DATABASE ERROR Server Declined
    END;

	IF V_ACCT_BALANCE IS NULL AND V_LEDGER_BALANCE IS NULL THEN

	BEGIN
     SELECT CAM_ACCT_BAL, CAM_LEDGER_BAL,
            cam_type_code                       --Added for 13160
       INTO V_ACCT_BALANCE, V_LEDGER_BALANCE,
            v_acct_type                         --Added for 13160
       FROM CMS_ACCT_MAST
      WHERE CAM_ACCT_NO = V_ACCT_NUMBER
           AND  CAM_INST_CODE = P_INSTCODE;
    EXCEPTION
     WHEN OTHERS THEN
       V_ACCT_BALANCE   := 0;
       V_LEDGER_BALANCE := 0;
    END;

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
        RESPONSE_ID,
        ANI,
        DNI,
        CARDSTATUS, 
        TRANS_DESC,
        acct_type,
        Time_stamp,
        cr_dr_flag,
        error_msg,
		ADD_INS_USER,
		SYSTEM_TRACE_AUDIT_NO
        )
     VALUES
       ('0200',
        P_RRN,
        P_DELIVERY_CHANNEL,
        0,
        V_BUSINESS_DATE,
        P_TXN_CODE,
        V_TXN_TYPE,
        0,
        DECODE(P_RESP_CODE, '00', 'C', 'F'),
        P_RESP_CODE,
        P_TRANDATE,
        SUBSTR(P_TRANTIME, 1, 10),
        V_HASH_PAN,
        NULL,
        NULL,
        NULL,
        NULL,
        TRIM(TO_CHAR(nvl(V_TRAN_AMT,0), '99999999999999990.99')),
        V_CURRCODE,
        NULL,
        V_PROD_CODE,--SUBSTR(P_CARDNUM, 1, 4),      
        v_prod_cattype,--NULL,                      
        0,
        V_INIL_AUTHID,
        TRIM(TO_CHAR(nvl(V_TRAN_AMT,0), '99999999999999990.99')),   
        '0.00',--NULL,                                              
        '0.00',--NULL,                                              
        P_INSTCODE,
        V_ENCR_PAN,
        NULL,
        V_PROXYNUMBER,
        0,
        V_ACCT_NUMBER,
        nvl(V_ACCT_BALANCE,0),
        nvl(V_LEDGER_BALANCE,0),
        V_RESPCODE,
        P_ANI,
        P_DNI,
        V_CAP_CARD_STAT, 
        V_TRANS_DESC,
        v_acct_type,
        v_timestamp,
        V_DR_CR_FLAG,
        P_ERRMSG,
		'1',
		'0'
        );

    EXCEPTION
     WHEN OTHERS THEN

       P_RESP_CODE := '89';
       P_ERRMSG    := 'Problem while inserting data into transaction log  dtl' ||
                   SUBSTR(SQLERRM, 1, 300);
    END;
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
		CTD_INS_DATE,
        CTD_CUSTOMER_CARD_NO_ENCR,
        CTD_CUST_ACCT_NUMBER,
        CTD_TXN_TYPE,
		CTD_HASHKEY_ID,
		CTD_SYSTEM_TRACE_AUDIT_NO)
     VALUES
       (P_DELIVERY_CHANNEL,
        P_TXN_CODE,
        '0200',
        0,
        P_TRANDATE,
        P_TRANTIME,
        V_HASH_PAN,
        0,
        V_CURRCODE,
        0,
        NULL,
        NULL,
        NULL,
        NULL,
        NULL,
        NULL,
        DECODE (P_RESP_CODE, '00', 'Y', 'E'),
        DECODE (V_ERRMSG, 'OK', 'Successful', V_ERRMSG),
        P_RRN,
        P_INSTCODE,
		SYSDATE,
        V_ENCR_PAN,
        V_ACCT_NUMBER,
        V_TXN_TYPE,
		v_hashkey_id,
		'0');

    EXCEPTION
     WHEN OTHERS THEN
       P_ERRMSG    := 'Problem while inserting data into transaction log  dtl' ||
                   SUBSTR(SQLERRM, 1, 300);
       P_RESP_CODE := '89'; 

    END;
	
	-- Modified for VMS-3349 End

END;

/

show error