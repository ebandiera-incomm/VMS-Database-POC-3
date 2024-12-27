set define off;
CREATE OR REPLACE PROCEDURE VMSCMS.SP_CHW_GPR_CARDGEN(
    p_instcode           IN  NUMBER,
    P_CARDNUM            IN  VARCHAR2,
    P_RRN                IN  VARCHAR2,
    P_DELIVERY_CHANNEL   IN  VARCHAR2,
    p_txn_code           IN  VARCHAR2,
    p_trandate           IN  VARCHAR2,
    p_trantime           IN  VARCHAR2,
    p_ipaddress          IN  VARCHAR2,
    p_devmob_no          IN  VARCHAR2,
    p_dev_id             IN  VARCHAR2,
    p_shipping_method    IN  VARCHAR2, --Added for JH-3043
    P_BUSINESS_NAME      IN  VARCHAR2,
    p_fee_waiver_flag    IN  VARCHAR2,-- Added for FSS-5213
    p_addrone_in         IN  VARCHAR2,
    p_addrtwo_in         IN  VARCHAR2,
    p_city_in            IN  VARCHAR2,
    p_state_in           IN  VARCHAR2,
    p_postalcode_in      IN  VARCHAR2,
    p_countrycode_in     IN  VARCHAR2,
    P_RESP_CODE          OUT VARCHAR2,
    P_PAN_NUMBER         OUT VARCHAR2,
    P_ACCT_NO            OUT VARCHAR2,
    p_cust_id            OUT VARCHAR2,
    P_ERRMSG             OUT VARCHAR2
    )
AS
  /*************************************************
  * Created Date     :  10-Sep-2014
  * Created By       :  Abdul Hameed M.A
  * PURPOSE          :  For gpr card generation
  *Build No          : RI0027.4_B0002

   * Modified By     : Ramesh A
   * Modified Date    : 05-Dec-2014
   * Modified Reason  : JH-3043
   * Reviewer         : Spankaj
   * Build Number     : RI0027.4.3_B0009

   * Modified By     : siva Kumar M
   * Modified Date    : 10-Dec-2014
   * Modified Reason  : JH-3043
   * Reviewer         : Spankaj
   * Build Number     : RI0027.4.3_B0010

   * Modified By     : Ramesh A
   * Modified Date    : 12-Dec-2014
   * Modified Reason  : FSS-1961(Melissa)
   * Reviewer         : Spankaj
   * Build Number     : RI0027.5_B0002

   * Modified By      : MAGESHKUMAR SA
   * Modified Date    : 24-MAR-2015
   * Modified Reason  : MANTIS:16071(Spelling mistake corrected)
   * Reviewer         : PANKAJ S
   * Build Number     : VMSGPRCHOSTCSD3.0_B0002

  * Modified by           : Abdul Hameed M.A
  * Modified Date         : 07-Sep-15
  * Modified For          : FSS-3509 & FSS-1817
  * Reviewer              : Saravanankumar
  * Build Number          : VMSGPRHOSTCSD3.2

   * Modified By      : T.NARAYANASWAMY
   * Modified Date    : 23-MAR-2016
   * Modified Reason  : FSS-4129 - DFC Momentum Visa to MasterCard Migration
   * Reviewer         : PANKAJ S
   * Build Number     : VMSGPRCHOSTCSD4.0_B0006

   * Modified By      : T.Narayanaswamy.
   * Modified Date    : 11/09/2017
   * Purpose          : FSS-5236 - PERSONALIZED CARD WITH FEE ENHANCEMENT
   * Reviewer         : Saravanan/Pankaj S.
   * Release Number   : VMSGPRHOST17.09

   * Modified By      : Ummar Hussain
   * Modified Date    : 04-Sep-2017
   * Modified Reason  : FSS-5213 - B2B BusinessName Updation
   * Reviewer         : Saravanakumar/PankajS
   * Build Number     : VMSGPRCHOSTCSD17.09_B0001

   * Modified By      : Ubaidur Rahman
   * Modified Date    : 08-May-2019
   * Modified Reason  : VMS-924
   * Reviewer         : Saravanakumar
   * Build Number     : VMSGPRHOST_R15_B0006

   * Modified By      : UBAIDUR RAHMAN.H
    * Modified Date    : 09-JUL-2019
    * Purpose          : VMS 960/962 - Enhance Website/middleware to
                                support cardholder data search ¿ phase 2.
    * Reviewer         : Saravana Kumar.A
    * Release Number   : VMSGPRHOST_R18

    * Modified By      : UBAIDUR RAHMAN.H
    * Modified Date    : 01-AUG-2019
    * Purpose          : VMS 1019 - MMPOS Order Personalized Card transaction.
    * Reviewer         : SaravanaKumar.A
    * Release Number   : VMSGPRHOST_R19
    
    * Modified By      : venkat Singamaneni
    * Modified Date    : 3-15-2022
    * Purpose          : Archival changes.
    * Reviewer         : Saravana Kumar A
    * Release Number   : VMSGPRHOST60 for VMS-5733/FSP-991
  *************************************************/
  v_cap_card_stat          cms_appl_pan.cap_card_stat%TYPE;
  v_firsttime_topup        cms_appl_pan.cap_firsttime_topup%TYPE;
  v_errmsg                 transactionlog.error_msg%TYPE;
  v_currcode               transactionlog.currencycode%TYPE;
  v_appl_code              cms_appl_mast.cam_appl_code%TYPE;
  v_respcode               transactionlog.response_id%TYPE;
  v_respmsg                transactionlog.error_msg%TYPE;
  V_CAPTURE_DATE           transactionlog.date_time%type;
  v_txn_type               cms_func_mast.cfm_txn_type%TYPE;
  v_inil_authid            transactionlog.auth_id%TYPE;
  v_hash_pan               cms_appl_pan.cap_pan_code%TYPE;
  v_encr_pan               cms_appl_pan.cap_pan_code_encr%TYPE;
  V_RRN_COUNT              PLS_INTEGER;
  v_tran_date              transactionlog.date_time%type;
  v_tran_amt               cms_acct_mast.cam_acct_bal%type;
  v_business_date          transactionlog.date_time%type;
  V_CUST_CODE              CMS_CUST_MAST.CCM_CUST_CODE%type;
  v_cap_prod_catg          CMS_APPL_PAN.CAP_PROD_CATG%TYPE;
  v_acct_balance           cms_acct_mast.cam_acct_bal%TYPE;
  v_prod_code              cms_prod_mast.cpm_prod_code%TYPE;
  V_PROD_CATTYPE           CMS_PROD_CATTYPE.CPC_CARD_TYPE%type;
  V_LEDGER_BALANCE         cms_acct_mast.cam_ledger_bal%type;
  v_dr_cr_flag             cms_transaction_mast.ctm_credit_debit_flag%type;
  v_output_type            cms_transaction_mast.ctm_output_type%type;
  v_tran_type              cms_transaction_mast.ctm_tran_type%type;
  V_STARTER_CARD_FLAG      cms_appl_pan.cap_startercard_flag%type;
  v_acct_number            cms_appl_pan.cap_acct_no%TYPE;
  v_inst_code              cms_appl_pan.cap_inst_code%TYPE;
  v_lmtprfl                cms_prdcattype_lmtprfl.cpl_lmtprfl_id%TYPE;
  v_profile_level          cms_appl_pan.cap_prfl_levl%TYPE;
  V_TRANS_DESC             CMS_TRANSACTION_MAST.CTM_TRAN_DESC%type;
  v_acct_type              cms_acct_mast.cam_type_code%type;
  v_timestamp              TIMESTAMP(3);
  V_HASHKEY_ID             CMS_TRANSACTION_LOG_DTL.CTD_HASHKEY_ID%type;
  V_USERBIN                PLS_INTEGER DEFAULT 1;
  V_KYC_FLAG               cms_cust_mast.ccm_kyc_flag%type;
  V_GPR_CARDCNT            PLS_INTEGER;
  v_err_msg                transactionlog.error_msg%TYPE;
  V_GPR_CARD_NO            VARCHAR2 (50);
  V_APPLPROCES_MSG         transactionlog.error_msg%TYPE;
  V_RESP_CODE              transactionlog.response_id%TYPE;
  V_GPRHASHPAN             cms_appl_pan.cap_pan_code%TYPE; --Added for JH-3043
  V_DEL_MTHD               cms_appl_pan.cap_repl_flag%type DEFAULT 0; --Added for JH-3043
  v_upgrade_eligible_flag  cms_prod_cattype.CPC_UPGRADE_ELIGIBLE_FLAG%TYPE;
  v_encrypt_enable         vmscms.cms_prod_cattype.cpc_encrypt_enable%TYPE;
  v_addr_one               vmscms.vms_order_details.VOD_ADDRESS_LINE1%type;
  v_addr_two 			         vmscms.vms_order_details.VOD_ADDRESS_LINE2%type;
  v_city 				           vmscms.vms_order_details.VOD_CITY%type;
  v_postal_code 		       vmscms.vms_order_details.VOD_POSTALCODE%type;
  v_state_code             vmscms.gen_state_mast.gsm_state_code%TYPE;
  v_cntry_code             vmscms.gen_cntry_mast.gcm_cntry_code%TYPE;
  v_cap_expry_date         vmscms.cms_appl_pan.cap_expry_date%TYPE;
  v_fee_waiver_flag        varchar2(20);
  EXP_MAIN_REJECT_RECORD   EXCEPTION;
  EXP_AUTH_REJECT_RECORD   exception;
  v_Retperiod  date;  --Added for VMS-5733/FSP-991
  v_Retdate  date; --Added for VMS-5733/FSP-991
BEGIN
  p_errmsg           := 'OK';
  v_errmsg           := 'OK';
  V_RESPCODE         := '1';
  v_fee_waiver_flag  := p_fee_waiver_flag;
  v_timestamp        := SYSTIMESTAMP;
  --SN CREATE HASH PAN
  BEGIN
    v_hash_pan := gethash (p_cardnum);
  EXCEPTION
  WHEN OTHERS THEN
    v_respcode := '12';
    v_errmsg   := 'Error while converting pan ' || SUBSTR (SQLERRM, 1, 200);
    RAISE exp_main_reject_record;
  END;
  --EN CREATE HASH PAN
  --Start Generate HashKEY
  BEGIN
    V_HASHKEY_ID := GETHASH (P_DELIVERY_CHANNEL||p_txn_code||p_cardnum||P_RRN||TO_CHAR(v_timestamp,'YYYYMMDDHH24MISSFF5'));
  EXCEPTION
  WHEN OTHERS THEN
    v_respcode := '21';
    v_errmsg   :='Error while converting master data ' || SUBSTR (SQLERRM, 1, 200);
    RAISE exp_main_reject_record;
  END;
  --End Generate HashKEY
  --SN create encr pan
  BEGIN
    v_encr_pan := fn_emaps_main (p_cardnum);
  EXCEPTION
  WHEN OTHERS THEN
    v_respcode := '12';
    v_errmsg   := 'Error while converting pan ' || SUBSTR (SQLERRM, 1, 200);
    RAISE exp_main_reject_record;
  END;
  --Sn find debit and credit flag
  BEGIN
    SELECT ctm_credit_debit_flag,
      ctm_output_type,
      TO_NUMBER (DECODE (ctm_tran_type, 'N', '0', 'F', '1')),
      ctm_tran_type,
      ctm_tran_desc
    INTO v_dr_cr_flag,
      v_output_type,
      v_txn_type,
      v_tran_type,
      v_trans_desc
    FROM cms_transaction_mast
    WHERE ctm_tran_code      = p_txn_code
    AND ctm_delivery_channel = p_delivery_channel
    AND ctm_inst_code        = p_instcode;
  EXCEPTION
  WHEN NO_DATA_FOUND THEN
    v_respcode := '12'; --Ineligible Transaction
    v_errmsg   := 'Transflag  not defined for txn code ' || p_txn_code || ' and delivery channel ' || p_delivery_channel;
    RAISE exp_main_reject_record;
  WHEN OTHERS THEN
    v_respcode := '21'; --Ineligible Transaction
    v_errmsg := 'Error while selecting transaction details';
    RAISE exp_main_reject_record;
  end;

   --Sn Transaction Time Check
  BEGIN
    v_tran_date := TO_DATE ( SUBSTR (TRIM (p_trandate), 1, 8) || ' ' || SUBSTR (TRIM (p_trantime), 1, 10), 'yyyymmdd hh24:mi:ss' );
  EXCEPTION
  WHEN OTHERS THEN
    v_respcode := '32'; -- Server Declined -220509
    v_errmsg   := 'Problem while converting transaction Time ' || SUBSTR (SQLERRM, 1, 200);
    RAISE exp_main_reject_record;
  END;
  --En Transaction Time Check
  v_currcode := '124';
  BEGIN
  
  --Added for VMS-5733/FSP-991
         select (add_months(trunc(sysdate,'MM'),'-'||RETENTION_PERIOD))
       INTO   v_Retperiod 
       FROM DBA_OPERATIONS.ARCHIVE_MGMNT_CTL 
       WHERE  OPERATION_TYPE='ARCHIVE' 
       AND OBJECT_NAME='TRANSACTIONLOG_EBR';
       
       v_Retdate := TO_DATE(SUBSTR(TRIM(p_trandate), 1, 8), 'yyyymmdd');
      
  IF (v_Retdate>v_Retperiod) --Added for VMS-5733/FSP-991
    THEN
    SELECT COUNT (1)
    INTO v_rrn_count
    FROM transactionlog
    WHERE instcode       = p_instcode
    AND rrn              = p_rrn
    AND business_date    = p_trandate
    AND delivery_channel = p_delivery_channel;
    ELSE
    SELECT COUNT (1)--Added for VMS-5733/FSP-991
    INTO v_rrn_count
    FROM VMSCMS_HISTORY.TRANSACTIONLOG_HIST
    WHERE instcode       = p_instcode
    AND rrn              = p_rrn
    AND business_date    = p_trandate
    AND delivery_channel = p_delivery_channel;
   END IF; 
    IF v_rrn_count       > 0 THEN
      v_respcode        := '22';
      v_errmsg          := 'Duplicate RRN ' || ' on ' || p_trandate;
      RAISE exp_main_reject_record;
    END IF;
  EXCEPTION
  WHEN exp_main_reject_record
  then
          RAISE;

  WHEN OTHERS THEN
    v_respcode := '21';
    v_errmsg := 'Error while selecting rrn count';
    RAISE exp_main_reject_record;
  END;
  --En Duplicate RRN Check
  --Sn find card detail
  BEGIN
    SELECT CAP_PROD_CODE,
      CAP_CARD_TYPE,
      CAP_CARD_STAT,
      CAP_PROD_CATG,
      CAP_APPL_CODE,
      CAP_FIRSTTIME_TOPUP,
      CAP_CUST_CODE,
      cap_inst_code,
      cap_prfl_code,
      cap_prfl_levl,
      cap_startercard_flag,
      cap_acct_no,
      cap_expry_date
    INTO V_PROD_CODE,
      V_PROD_CATTYPE,
      V_CAP_CARD_STAT,
      V_CAP_PROD_CATG,
      V_APPL_CODE,
      V_FIRSTTIME_TOPUP,
      V_CUST_CODE,
      v_inst_code,
      v_lmtprfl,
      v_profile_level,
      v_starter_card_flag,
      v_acct_number,
      v_cap_expry_date
    FROM cms_appl_pan
    WHERE cap_inst_code = p_instcode
    AND cap_pan_code    = v_hash_pan;
  EXCEPTION
  WHEN NO_DATA_FOUND THEN
    V_RESPCODE := '16'; --Ineligible Transaction
    v_errmsg   := 'Card number not found'; --|| p_txn_code;--Commented for REVIEW COMMENTS FWR 70
    RAISE exp_main_reject_record;
  WHEN OTHERS THEN
    v_respcode := '12';
    v_errmsg   := 'Problem while selecting card detail' || SUBSTR (SQLERRM, 1, 200);
    RAISE exp_main_reject_record;
  END;

    -- FSS-5236 - PERSONALIZED CARD WITH FEE ENHANCEMENT beg

  BEGIN

        SELECT NVL(CPC_UPGRADE_ELIGIBLE_FLAG,'N'),
          CPC_ENCRYPT_ENABLE
        INTO v_upgrade_eligible_flag,
          v_encrypt_enable
        FROM CMS_PROD_CATTYPE
        WHERE CPC_PROD_CODE = v_prod_code
        AND CPC_CARD_TYPE   = V_PROD_CATTYPE
        AND CPC_INST_CODE   = p_instcode;

    EXCEPTION
    WHEN OTHERS  THEN
         v_respcode := '21';
         v_errmsg := 'Error while selecting product detls ' || v_prod_code;
         RAISE exp_main_reject_record;

    END;


       BEGIN
       if v_UPGRADE_ELIGIBLE_FLAG<>'Y' then
          v_respcode := '270';
          V_ERRMSG := 'Upgrade flag disabled in Product Category Configuration';
          RAISE exp_main_reject_record;
       END IF;
       EXCEPTION
       WHEN exp_main_reject_record
        then
          RAISE;
       WHEN OTHERS  THEN
         V_RESPCODE := '21';
         v_errmsg := 'Error while selecting details from product : ' || v_prod_code ||' and Product Category :'||V_PROD_CATTYPE;
         RAISE exp_main_reject_record;
    end;
  -- FSS-5236 - PERSONALIZED CARD WITH FEE ENHANCEMENT end

  IF(V_STARTER_CARD_FLAG='N') THEN
    V_RESPCODE         := '21';
    v_errmsg           := 'GPR Card Already Generated';
    RAISE EXP_MAIN_REJECT_RECORD;
  END IF;

    IF LAST_DAY (TRUNC (v_cap_expry_date)) < TRUNC(SYSDATE)
    -- last_day checked during expired card check
    THEN
        v_fee_waiver_flag := 'Y';
    END IF;

    --Sn call to authorize txn
    BEGIN
       sp_authorize_txn_cms_auth (p_instcode,
                                  '0200',
                                  p_rrn,
                                  p_delivery_channel,
                                  '0',
                                  p_txn_code,
                                  0,
                                  p_trandate,
                                  p_trantime,
                                  p_cardnum,
                                  NULL,
                                  0,
                                  NULL,
                                  NULL,
                                  NULL,
                                  v_currcode,
                                  NULL,
                                  NULL,
                                  NULL,
                                  NULL,
                                  NULL,
                                  NULL,
                                  NULL,
                                  NULL,
                                  NULL,
                                  NULL,
                                  NULL,
                                  NULL,
                                  NULL,
                                  '0', -- P_stan
                                  '000',                                                                                                                                                                                                                                                     --Ins User
                                  '00',                                                                                                                                                                                                                                                      --INS Date
                                  0,
                                  V_INIL_AUTHID,
                                  v_resp_code,
                                  v_respmsg,
                                  v_capture_date,
                                  (case when v_fee_waiver_flag='N' then 'Y' else 'N' end) );

      IF V_RESP_CODE <> '00' AND V_RESPMSG <> 'OK' THEN
        V_ERRMSG     := V_RESPMSG;
        RAISE exp_auth_reject_record;
      END IF;
    EXCEPTION
      WHEN exp_auth_reject_record
         then
            RAISE;
    WHEN exp_main_reject_record THEN
      RAISE;
    WHEN OTHERS THEN
      v_respcode := '21';
      v_errmsg   := 'Error from Card authorization' || SUBSTR (SQLERRM, 1, 200);
      RAISE exp_main_reject_record;
    END;
    --En call to authorize txn

  IF v_resp_code = '00' THEN
    BEGIN
      BEGIN
        SELECT CCM_KYC_FLAG
        INTO v_kyc_flag
        FROM CMS_CUST_MAST
        WHERE CCM_CUST_CODE=V_CUST_CODE
        AND CCM_INST_CODE  =P_INSTCODE;
      EXCEPTION
      WHEN OTHERS THEN
        v_respcode := '21';
        V_ERRMSG   := 'Error while selecting KYC flag for the cust code' || V_CUST_CODE;
        RAISE EXP_MAIN_REJECT_RECORD;
      END;
      IF UPPER(V_KYC_FLAG) IN ( 'Y' ,'P','O','I') THEN
        BEGIN
          SELECT COUNT(1)
          INTO V_GPR_CARDCNT
          FROM CMS_APPL_PAN
          WHERE cap_acct_no       = v_acct_number
          AND CAP_STARTERCARD_FLAG='N'
		  AND CAP_APPL_CODE=v_appl_code  -- CHANGED FOR FSS-4129 - DFC Momentum Visa to MasterCard Migration
          AND CAP_INST_CODE       = P_INSTCODE;
        EXCEPTION
        WHEN OTHERS THEN
          v_respcode := '21';
          V_ERRMSG   := 'Error while selecting GPR Card details for Account No ' || v_acct_number;
          RAISE EXP_MAIN_REJECT_RECORD;
        END;
        IF (V_GPR_CARDCNT=0) THEN
          BEGIN
            UPDATE CMS_APPL_MAST
            SET CAM_APPL_STAT   = 'A' , CAM_STARTER_CARD= 'N' --added starter crad  N from below commented code
            WHERE CAM_APPL_CODE = v_appl_code
            AND CAM_INST_CODE   = P_INSTCODE;
            IF SQL%ROWCOUNT     = 0 THEN
              v_respcode       := '21';
              V_ERRMSG         := 'Error while updating cms_appl_mast for appl_stat';
              RAISE EXP_MAIN_REJECT_RECORD;
            END IF;
          EXCEPTION
          WHEN EXP_MAIN_REJECT_RECORD THEN
            RAISE;
          WHEN OTHERS THEN
            v_respcode := '21';
            v_errmsg   := 'Error while updating CMS_APPL_MAST-' || SUBSTR (SQLERRM, 1, 200);
            RAISE EXP_MAIN_REJECT_RECORD;
          END;

          BEGIN
            UPDATE CMS_ACCT_MAST
            SET cam_hold_count  = cam_hold_count + 1,
              cam_lupd_user     = v_userbin
            WHERE cam_inst_code = p_instcode
            AND cam_acct_no     = v_acct_number;
            IF SQL%ROWCOUNT     = 0 THEN
              V_RESPCODE       := '21';
              v_errmsg         := 'Error while update acct ' ;
              RAISE EXP_MAIN_REJECT_RECORD;
            END IF;
          EXCEPTION
          WHEN EXP_MAIN_REJECT_RECORD THEN
          RAISE;
          WHEN OTHERS THEN
            v_respcode := '21';
            v_errmsg   := 'Error while update acct ' || SUBSTR (SQLERRM, 1, 200);
            RAISE EXP_MAIN_REJECT_RECORD;
          END;
          BEGIN
            sp_gen_pan_starter_to_gpr (p_instcode, v_appl_code, v_userbin, v_gpr_card_no, V_APPLPROCES_MSG, v_err_msg );
            IF v_err_msg <> 'OK' THEN
              v_respcode := '21';
              RAISE EXP_MAIN_REJECT_RECORD;
            END IF;
            IF v_applproces_msg <> 'OK' THEN
              v_respcode        := '21';
              v_errmsg          := v_applproces_msg;
              RAISE EXP_MAIN_REJECT_RECORD;
            END IF;
          EXCEPTION
          WHEN EXP_MAIN_REJECT_RECORD THEN
            RAISE;
          WHEN OTHERS THEN
            v_respcode := '21';
            v_errmsg   := 'Error while updating CMS_APPL_MAST-' || SUBSTR (SQLERRM, 1, 200);
            RAISE EXP_MAIN_REJECT_RECORD;
          END;
          BEGIN
            SELECT fn_dmaps_main (pan.cap_pan_code_encr),
              pan.cap_acct_no,
              cust.ccm_cust_id,pan.cap_pan_code  --Added for JH-3043
            INTO p_pan_number,
              p_acct_no,
              p_cust_id,V_GPRHASHPAN  --Added for JH-3043
            FROM cms_appl_pan pan,
              cms_cust_mast cust
            WHERE pan.cap_appl_code  = v_appl_code
            AND pan.cap_cust_code    = cust.ccm_cust_code
            AND pan.cap_inst_code    = cust.ccm_inst_code
            AND pan.cap_inst_code    = p_instcode
            AND cap_startercard_flag = 'N';
          EXCEPTION
          WHEN OTHERS THEN
            v_respcode := '21';
            v_errmsg   := 'Error while selecting (gpr card)details from appl_pan :' || SUBSTR (SQLERRM, 1, 200);
            RAISE EXP_MAIN_REJECT_RECORD;
          END;
        --St Added for JH-3043
         IF p_shipping_method IS NOT NULL
         THEN
              IF p_shipping_method = 0 THEN
                V_DEL_MTHD:=5;--3;
              ELSIF p_shipping_method = 1 THEN
                V_DEL_MTHD:=6;--4;
              END IF;
         ELSE
             IF  p_txn_code = '98'
             THEN
                V_DEL_MTHD := 6;
             ELSIF p_txn_code = '35'
             THEN
                V_DEL_MTHD := 7;
             END IF;
         END IF;

          BEGIN
            update cms_appl_pan set cap_repl_flag=V_DEL_MTHD
            where cap_pan_code=V_GPRHASHPAN and cap_inst_code=p_instcode;

              IF SQL%ROWCOUNT     = 0 THEN
                V_RESPCODE       := '21';
                v_errmsg         := 'Error while update REPL FLAG ' ;
                RAISE EXP_MAIN_REJECT_RECORD;
              END IF;
            EXCEPTION
            WHEN EXP_MAIN_REJECT_RECORD THEN
            RAISE;
            WHEN OTHERS THEN
              v_respcode := '21';
              v_errmsg   := 'Error while update REPL FLAG ' || SUBSTR (SQLERRM, 1, 200);
              RAISE EXP_MAIN_REJECT_RECORD;
          END;

        --END Added for JH-3043
       -- Start Added for FSS-5213
        IF p_business_name IS NOT NULL THEN
          BEGIN
            UPDATE CMS_CUST_MAST
            SET CCM_BUSINESS_NAME = p_business_name
               WHERE  ccm_cust_code = V_CUST_CODE
               AND ccm_inst_code = P_INSTCODE;
            IF SQL%ROWCOUNT = 0 THEN
               v_respcode       := '21';
               v_errmsg :='bussiness name not updated against customer';
               RAISE EXP_MAIN_REJECT_RECORD;
            END IF;
            EXCEPTION
              WHEN EXP_MAIN_REJECT_RECORD THEN
                RAISE EXP_MAIN_REJECT_RECORD;
              WHEN OTHERS THEN
                v_respcode       := '21';
                v_errmsg :='Error while updating bussiness name in custmat' || SUBSTR (SQLERRM, 1, 200);
                RAISE EXP_MAIN_REJECT_RECORD;
           END;
          END IF;

    -- End Added for FSS-5213


      IF p_addrone_in      IS NOT NULL AND
         p_city_in         IS NOT NULL AND
         p_state_in        IS NOT NULL AND
         p_postalcode_in   IS NOT NULL AND
         p_countrycode_in  IS NOT NULL
      THEN

        SELECT gsm_state_code
          INTO v_state_code
          FROM gen_state_mast
         WHERE gsm_inst_code = 1
           AND gsm_switch_state_code = upper(p_state_in);

        SELECT gcm_cntry_code
          INTO v_cntry_code
          FROM gen_cntry_mast
         WHERE gcm_inst_code = 1
           AND gcm_switch_cntry_code = upper(p_countrycode_in);

      IF v_encrypt_enable = 'Y'
      THEN
        v_addr_one     := fn_emaps_main(p_addrone_in);
        v_addr_two     := fn_emaps_main(p_addrtwo_in);
        v_city         := fn_emaps_main(p_city_in);
        v_postal_code  := fn_emaps_main(p_postalcode_in);
      ELSE
        v_addr_one     := p_addrone_in;
        v_addr_two     := p_addrtwo_in;
        v_city         := p_city_in;
        v_postal_code  := p_postalcode_in;
      END IF;

            BEGIN
                MERGE INTO cms_addr_mast
                USING (SELECT v_cust_code cust_code,'O' addr_flag FROM dual) a
                ON (cam_cust_code = a.cust_code
                AND cam_addr_flag = a.addr_flag)
                WHEN MATCHED THEN
                    UPDATE SET
                    cam_add_one    = v_addr_one,
                    cam_add_two    = v_addr_two,
                    cam_city_name  = v_city,
                    cam_pin_code   = v_postal_code,
                    cam_state_code = v_state_code,
                    cam_cntry_code = v_cntry_code,
                    cam_add_one_encr = fn_emaps_main(p_addrone_in),
                    cam_add_two_encr = fn_emaps_main(p_addrtwo_in),
                    cam_city_name_encr = fn_emaps_main(p_city_in),
                    cam_pin_code_encr = fn_emaps_main(p_postalcode_in)
                WHEN NOT MATCHED THEN
                    INSERT
                        (cam_inst_code,
                         cam_cust_code,
                         cam_addr_code,
                         cam_add_one,
                         cam_add_two,
                         cam_pin_code,
                         cam_cntry_code,
                         cam_city_name,
                         cam_addr_flag,
                         cam_state_code,
                         cam_ins_user,
                         cam_ins_date,
                         cam_lupd_user,
                         cam_lupd_date,
                         cam_add_one_encr,
                         cam_add_two_encr,
                         cam_city_name_encr,
                         cam_pin_code_encr)
                    VALUES
                        (p_instcode,
						             v_cust_code,
                         seq_addr_code.nextval,
                         v_addr_one,
                         v_addr_two,
                         v_postal_code,
                         v_cntry_code,
                         v_city,
                         'O',
                         v_state_code,
                         1,
                         SYSDATE,
                         1,
                         SYSDATE,
                         fn_emaps_main(p_addrone_in),
                         fn_emaps_main(p_addrtwo_in),
                         fn_emaps_main(p_city_in),
                         fn_emaps_main(p_postalcode_in));

            EXCEPTION
            WHEN EXP_MAIN_REJECT_RECORD THEN
                RAISE EXP_MAIN_REJECT_RECORD;
            WHEN OTHERS THEN
                v_respcode       := '21';
                v_errmsg :='Error while updating address in addrmast' || SUBSTR (SQLERRM, 1, 200);
                RAISE EXP_MAIN_REJECT_RECORD;
            END;
      END IF;

        --AVQ Added for FSS-1961(Melissa)
        BEGIN
                SP_LOGAVQSTATUS(
                p_instcode,
                P_DELIVERY_CHANNEL,
                p_pan_number,
                V_PROD_CODE,
                V_CUST_CODE,
                v_respcode,
                v_errmsg,
                V_PROD_CATTYPE
                );
            IF v_errmsg <> 'OK' THEN
               v_errmsg  := 'Exception while calling LOGAVQSTATUS-- ' || v_errmsg;
               v_respcode := '21';
              RAISE EXP_MAIN_REJECT_RECORD;
             END IF;
        EXCEPTION WHEN EXP_MAIN_REJECT_RECORD
        THEN  RAISE;
        WHEN OTHERS THEN
           v_errmsg  := 'Exception in LOGAVQSTATUS-- '  || SUBSTR (SQLERRM, 1, 200);
           v_respcode := '21';
           RAISE EXP_MAIN_REJECT_RECORD;
        END;
        --End  Added for FSS-1961(Melissa)
        ELSE
          V_RESPCODE := '21';
          V_ERRMSG   := 'GPR Card Already Generated';
          RAISE EXP_MAIN_REJECT_RECORD;
        END IF;

      ELSE
        V_RESPCODE := '21';
        V_ERRMSG   :='KYC Verification is not successful for this customer ' || V_CUST_CODE;
        RAISE EXP_MAIN_REJECT_RECORD;
      END IF;
    EXCEPTION
    WHEN exp_main_reject_record THEN
      RAISE;
    WHEN OTHERS THEN
      v_respcode := '21';
      v_errmsg   := 'Error from Card authorization' || SUBSTR (SQLERRM, 1, 200);
      RAISE exp_main_reject_record;
    END;
    --En call to authorize txn
  END IF;
  BEGIN
    -- Assign the response code to the out parameter
    SELECT cms_iso_respcde
    INTO p_resp_code
    FROM cms_response_mast
    WHERE cms_inst_code      = p_instcode
    AND cms_delivery_channel = p_delivery_channel
    AND cms_response_id      = v_respcode;

     EXCEPTION
         WHEN NO_DATA_FOUND
         THEN
            v_errmsg :=
                    'No data available in response master  for' || v_respcode;
            v_resp_code := '89';
            RAISE exp_main_reject_record;
         WHEN OTHERS
         THEN
            v_errmsg :=
                  'Problem while selecting data from response master '
               || v_respcode
               || SUBSTR (SQLERRM, 1, 300);
            v_resp_code := '89';
            RAISE exp_main_reject_record;
    ---ISO MESSAGE FOR DATABASE ERROR Server Declined
  END;
  p_errmsg := v_errmsg;
  --En select response code and insert record into txn log dtl
    BEGIN
   IF (v_Retdate>v_Retperiod)--Added for VMS-5733/FSP-991
    THEN   
      UPDATE transactionlog
      SET ipaddress        = p_ipaddress , transactionlog = p_shipping_method --Added for jh-3043
      WHERE  instcode      = p_instcode
      AND rrn              = p_rrn
      AND business_date    = p_trandate
      AND txn_code         = p_txn_code
      AND business_time    = p_trantime
      AND delivery_channel = p_delivery_channel;
      else
      UPDATE VMSCMS_HISTORY.TRANSACTIONLOG_HIST --Added for VMS-5733/FSP-991
      SET ipaddress        = p_ipaddress , transactionlog = p_shipping_method 
      WHERE  instcode      = p_instcode
      AND rrn              = p_rrn
      AND business_date    = p_trandate
      AND txn_code         = p_txn_code
      AND business_time    = p_trantime
      AND delivery_channel = p_delivery_channel;
      end if;
         IF SQL%ROWCOUNT =0 THEN
            v_resp_code := '21';
             v_errmsg := 'Not updated txn log details:'||p_rrn||':'||p_trandate||':'||p_trantime||':'||p_delivery_channel||':'||p_txn_code;
            RAISE exp_main_reject_record;  
    END IF;

    EXCEPTION
    WHEN exp_main_reject_record THEN
    RAISE;
    WHEN OTHERS THEN
      v_resp_code := '69';
      v_errmsg    := 'Problem while inserting data into transaction log  dtl' || SUBSTR (SQLERRM, 1, 300);
       RAISE exp_main_reject_record;
    END;
    --  Added for MOB 62 amudhan
    BEGIN
    
    --Added for VMS-5733/FSP-991
           select (add_months(trunc(sysdate,'MM'),'-'||RETENTION_PERIOD))
       INTO   v_Retperiod 
       FROM DBA_OPERATIONS.ARCHIVE_MGMNT_CTL 
       WHERE  OPERATION_TYPE='ARCHIVE' 
       AND OBJECT_NAME='CMS_TRANSACTION_LOG_DTL_EBR';
      
  IF (v_Retdate>v_Retperiod) --Added for VMS-5733/FSP-991
  
    THEN
      UPDATE CMS_TRANSACTION_LOG_DTL
      SET CTD_PROCESS_MSG      = V_ERRMSG,
        CTD_MOBILE_NUMBER      =p_devmob_no,
        CTD_DEVICE_ID          =p_dev_id
      WHERE CTD_RRN            = P_RRN
      AND CTD_DELIVERY_CHANNEL = P_DELIVERY_CHANNEL
      AND CTD_TXN_CODE         = P_TXN_CODE
      AND CTD_BUSINESS_DATE    = p_trandate
      AND CTD_BUSINESS_TIME    = p_trantime
      AND CTD_MSG_TYPE         = '0200'
      AND CTD_CUSTOMER_CARD_NO = V_HASH_PAN
      AND CTD_INST_CODE        =p_instcode;
      ELSE 
         UPDATE VMSCMS_HISTORY.CMS_TRANSACTION_LOG_DTL_HIST  --Added for VMS-5733/FSP-991
      SET CTD_PROCESS_MSG      = V_ERRMSG,
        CTD_MOBILE_NUMBER      =p_devmob_no,
        CTD_DEVICE_ID          =p_dev_id
      WHERE CTD_RRN            = P_RRN
      AND CTD_DELIVERY_CHANNEL = P_DELIVERY_CHANNEL
      AND CTD_TXN_CODE         = P_TXN_CODE
      AND CTD_BUSINESS_DATE    = p_trandate
      AND CTD_BUSINESS_TIME    = p_trantime
      AND CTD_MSG_TYPE         = '0200'
      AND CTD_CUSTOMER_CARD_NO = V_HASH_PAN
      AND CTD_INST_CODE        =p_instcode;
      END IF;
      IF SQL%ROWCOUNT         <> 1 THEN
        V_RESP_CODE           := '21';
        V_ERRMSG              := 'Error while updating transactionlog_detl ';-- || SUBSTR(SQLERRM, 1, 200); --Commented for review comments FWR 70
        RAISE exp_main_reject_record;
      END IF;
    EXCEPTION
    WHEN exp_main_reject_record THEN
      RAISE exp_main_reject_record;
    WHEN OTHERS THEN
      V_RESP_CODE := '21';
      V_ERRMSG    := 'Error while updating transactionlog ' || SUBSTR(SQLERRM, 1, 200);
      RAISE exp_main_reject_record;
    END;

    IF P_DELIVERY_CHANNEL <> '04' THEN

    BEGIN
       INSERT INTO CMS_CARD_EXCPFEE
                                 (CCE_INST_CODE,
                                  CCE_PAN_CODE,
                                  CCE_INS_DATE,
                                  CCE_INS_USER,
                                  CCE_LUPD_USER,
                                  CCE_LUPD_DATE,
                                  CCE_FEE_PLAN,
                                  CCE_FLOW_SOURCE,
                                  CCE_VALID_FROM,
                                  CCE_VALID_TO,
                                  CCE_PAN_CODE_ENCR,
                                  CCE_MBR_NUMB,
                                  CCE_ST_CALC_FLAG,
                                  CCE_CESS_CALC_FLAG,
                                  CCE_DRGL_CATG)
                                 (SELECT
                                  CCE_INST_CODE,
                                  V_GPRHASHPAN,
                                  SYSDATE,
                                  1,
                                  1,
                                  SYSDATE,
                                  CCE_FEE_PLAN,
                                  CCE_FLOW_SOURCE,
                                  CCE_VALID_FROM,
                                  CCE_VALID_TO,
                                  fn_emaps_main(p_pan_number),
                                  CCE_MBR_NUMB,
                                  CCE_ST_CALC_FLAG,
                                  CCE_CESS_CALC_FLAG,
                                  CCE_DRGL_CATG
                                 FROM CMS_CARD_EXCPFEE
                                 WHERE CCE_INST_CODE = p_instcode
                                 AND CCE_PAN_CODE = v_hash_pan
                                 AND ((cce_valid_to IS NOT NULL AND (TRUNC(sysdate) BETWEEN cce_valid_from AND cce_valid_to))
                                  OR (cce_valid_to IS NULL AND TRUNC(sysdate) >= cce_valid_from)));
    EXCEPTION
    WHEN OTHERS THEN
      V_RESP_CODE := '21';
      V_ERRMSG    := 'Error while inserting into cms_card_excpfee ' || SUBSTR(SQLERRM, 1, 200);
      RAISE exp_main_reject_record;
    END;

    END IF;

  --  Added for MOB 62 amudhan
EXCEPTION
  --<< MAIN EXCEPTION >>

when  EXP_AUTH_REJECT_RECORD then

  P_ERRMSG := V_ERRMSG;
  p_resp_code:=V_RESP_CODE;

WHEN exp_main_reject_record THEN
  ROLLBACK;
  p_errmsg := v_errmsg;
  ---Sn Updation of Usage limit and amount
  BEGIN
    SELECT cam_acct_bal,
      cam_ledger_bal,
      cam_type_code
    INTO v_acct_balance,
      v_ledger_balance,
      v_acct_type
    FROM CMS_ACCT_MAST
    WHERE cam_acct_no =v_acct_number
    AND cam_inst_code = p_instcode;
  EXCEPTION
  WHEN OTHERS THEN
    v_acct_balance   := 0;
    v_ledger_balance := 0;
  END;
  --Sn select response code and insert record into txn log dtl
  BEGIN
    -- Assign the response code to the out parameter
    SELECT cms_iso_respcde
    INTO p_resp_code
    FROM cms_response_mast
    WHERE cms_inst_code      = p_instcode
    AND cms_delivery_channel = p_delivery_channel
    AND cms_response_id      = v_respcode;
  EXCEPTION
  WHEN OTHERS THEN
    p_errmsg    := 'Problem while selecting data from response master ' || v_respcode || SUBSTR (SQLERRM, 1, 300);
    p_resp_code := '89';
    ---ISO MESSAGE FOR DATABASE ERROR Server Declined
  END;
  IF v_dr_cr_flag IS NULL THEN
    BEGIN
      SELECT ctm_credit_debit_flag
      INTO v_dr_cr_flag
      FROM cms_transaction_mast
      WHERE ctm_tran_code      = p_txn_code
      AND ctm_delivery_channel = p_delivery_channel
      AND ctm_inst_code        = p_instcode;
    EXCEPTION
    WHEN OTHERS THEN
      NULL;
    END;
  END IF;
  IF v_prod_code IS NULL THEN
    BEGIN
      SELECT cap_prod_code,
        cap_card_type,
        cap_card_stat,
        cap_acct_no
      INTO v_prod_code,
        v_prod_cattype,
        v_cap_card_stat,
        v_acct_number
      FROM cms_appl_pan
      WHERE cap_inst_code = p_instcode
      AND cap_pan_code    = v_hash_pan;
    EXCEPTION
    WHEN OTHERS THEN
      NULL;
    END;
  END IF;
  BEGIN
    INSERT
    INTO transactionlog
      (
        msgtype,
        rrn,
        delivery_channel,
        terminal_id,
        date_time,
        txn_code,
        txn_type,
        txn_mode,
        txn_status,
        response_code,
        business_date,
        business_time,
        customer_card_no,
        topup_card_no,
        topup_acct_no,
        topup_acct_type,
        bank_code,
        total_amount,
        currencycode,
        addcharge,
        productid,
        categoryid,
        atm_name_location,
        auth_id,
        amount,
        preauthamount,
        partialamount,
        instcode,
        customer_card_no_encr,
        topup_card_no_encr,
        proxy_number,
        reversal_code,
        customer_acct_no,
        ACCT_BALANCE,
        LEDGER_BALANCE,
        ERROR_MSG,
        RESPONSE_ID,
        IPADDRESS,
        CARDSTATUS,
        TRANS_DESC,
        acct_type,
        cr_dr_flag,
        time_stamp,
        transactionlog --Added for jh-3043
      )
      VALUES
      (
        '0200',
        p_rrn,
        p_delivery_channel,
        0,
        v_business_date,
        p_txn_code,
        v_txn_type,
        0,
        DECODE (p_resp_code, '00', 'C', 'F'),
        p_resp_code,
        p_trandate,
        SUBSTR (p_trantime, 1, 10),
        v_hash_pan,
        NULL,
        NULL,
        NULL,
        p_instcode,
        TRIM (TO_CHAR (NVL(v_tran_amt,0), '99999999999999990.99')),
        v_currcode,
        NULL,
        v_prod_code,
        v_prod_cattype,
        0,
        v_inil_authid,
        TRIM (TO_CHAR (NVL(v_tran_amt,0), '99999999999999990.99')),
        NULL,
        NULL,
        p_instcode,
        v_encr_pan,
        v_encr_pan,
        '',
        0,
        V_ACCT_NUMBER,
        NVL(V_ACCT_BALANCE,0),
        NVL(V_LEDGER_BALANCE,0),
        V_ERRMSG,
        V_RESPCODE,
        P_IPADDRESS,
        V_CAP_CARD_STAT,
        V_TRANS_DESC,
        v_acct_type,
        v_dr_cr_flag,
        v_timestamp,
        p_shipping_method --Added for jh-3043
      );
  EXCEPTION
  WHEN OTHERS THEN
    p_resp_code := '89';
    p_errmsg    := 'Problem while inserting data into transaction log  dtl' || SUBSTR (SQLERRM, 1, 300);
  END;
  BEGIN
    INSERT
    INTO cms_transaction_log_dtl
      (
        ctd_delivery_channel,
        ctd_txn_code,
        ctd_msg_type,
        ctd_txn_mode,
        ctd_business_date,
        ctd_business_time,
        ctd_customer_card_no,
        ctd_txn_amount,
        ctd_txn_curr,
        ctd_actual_amount,
        ctd_fee_amount,
        ctd_waiver_amount,
        ctd_servicetax_amount,
        ctd_cess_amount,
        ctd_bill_amount,
        ctd_bill_curr,
        ctd_process_flag,
        ctd_process_msg,
        ctd_rrn,
        ctd_inst_code,
        ctd_customer_card_no_encr,
        ctd_cust_acct_number,
        CTD_MOBILE_NUMBER,
        CTD_DEVICE_ID,
        ctd_hashkey_id
      )
      VALUES
      (
        p_delivery_channel,
        p_txn_code,
        '0200',
        0,
        p_trandate,
        p_trantime,
        v_hash_pan,
        0,
        v_currcode,
        0,
        NULL,
        NULL,
        NULL,
        NULL,
        NULL,
        NULL,
        'E',
        v_errmsg,
        p_rrn,
        p_instcode,
        v_encr_pan,
        '',
        p_devmob_no,
        p_dev_id,
        V_HASHKEY_ID
      );
    p_errmsg := v_errmsg ;
  EXCEPTION
  WHEN OTHERS THEN
    p_errmsg    := 'Problem while inserting data into transaction log  dtl' || SUBSTR (SQLERRM, 1, 300);
    p_resp_code := '89'; -- Server Declined
  END;
WHEN OTHERS THEN
  P_ERRMSG := ' Error from main ' || SUBSTR (SQLERRM, 1, 200);
END;
/
show error