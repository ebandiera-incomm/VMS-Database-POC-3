create or replace PROCEDURE               vmscms.sp_username_regis_status (
   p_inst_code          IN       NUMBER,
   p_pan_code           IN       VARCHAR2,
   p_delivery_channel   IN       VARCHAR2,
   p_txn_code           IN       VARCHAR2,
   --Updated  by Siva kumar as on 09/07/2012
   p_rrn                IN       VARCHAR2,
   p_txn_mode           IN       VARCHAR2,
   p_tran_date          IN       VARCHAR2,
   p_tran_time          IN       VARCHAR2,
   p_ipaddress          IN       VARCHAR2,
   p_curr_code          IN       VARCHAR2,
   p_rvsl_code          IN       VARCHAR2,
   p_bank_code          IN       VARCHAR2,
   p_msg                IN       VARCHAR2,
   p_devmob_no          IN       VARCHAR2,   --  Added for MOB 62 amudhan
   p_dev_id             IN       VARCHAR2,   --  Added for MOB 62 amudhan
   p_resp_code          OUT      VARCHAR2,
   p_exp_date           OUT      VARCHAR2,   --Added by Ramesh.A on 09/04/2012
   p_srv_code           OUT      VARCHAR2,   --Added by Ramesh.A on 09/04/2012
   p_pin_offset         OUT      VARCHAR2,   --Added by Ramesh.A on 09/04/2012
   p_resmsg             OUT      VARCHAR2
)
AS
/*************************************************
     * Created Date     : 04-Apr-2012
     * Created By       : Ramesh.A
     * PURPOSE          : Checks whether the card has registerd or not , username has  created or not.
     * Modified By      : B.Besky
     * Modified Date    : 08-nov-12
     * Modified Reason  : Logging Customer Account number in to transactionlog table.
     * Reviewer         : Saravanakumar
     * Reviewed Date    : 19-nov-12
     * Release Number   : CMS3.5.1_RI0022_B0002

     * Modified By      : Pankaj S.
     * Modified Date    : 11-Jan-2013
     * Modified Reason  : Handled proper exception in duplicate RRN block(Mantis Id-9982)

     * Modified By      : Sai Prasad
     * Modified Date    : 11-Sep-2013
     * Modified For     : Mantis ID: 0012278 (JIRA FSS-1144)
     * Modified Reason  : IP Address is not logged in transactionlog table.
     * Reviewer         : DHIRAJ
     * Reviewed Date    : 11-Sep-2013
     * Build Number     : RI0024.4_B0010

     * Modified By      : Pankaj S.
     * Modified Date    : 10-Dec-2013
     * Modified Reason  : Logging issue changes(Mantis ID-13160)
     * Reviewer         : Dhiraj
     * Reviewed Date    :
     * Build Number     :

     * Modified By      : Amudhan S.
     * Modified Date    : 07-Apr-2014
     * Modified Reason  : MOB 62 changes
     * Reviewer         : spankaj
     * Reviewed Date    : 07-April-2014
     * Build Number     : RI0027.2_B0004

     * Modified By      : Amudhan S.
     * Modified Date    : 11-Apr-2014
     * Modified Reason  : MOB 62 -- Added delivery channel
     * Reviewer         : spankaj
     * Reviewed Date    : 15-April-2014
     * Build Number     : RI0027.2_B0005

     * Modified By      : Dinesh B
     * Modified Date    : 22-Apr-2014
     * Modified Reason  : Mantis-14308 - Logging Hash key value.
     * Reviewer         : spankaj
     * Reviewed Date    : 22-April-2014
     * Build Number     : RI0027.2_B0007

     * Modified By      : Ramesh
     * Modified Date    : 24-Apr-2014
     * Modified Reason  : Mantis-14383
     * Reviewer         : spankaj
     * Reviewed Date    : 24-April-2014
     * Build Number     : RI0027.2_B0009

     * Modified Date    : 25-Jun-2014
     * Modified By      : Ramesh
     * Modified for     : Integration from RI0027.1.9 (FSS-1710  - Performance changes)
     * Reviewer         : spankaj
     * Release Number   : RI0027.2.1_B0004
     
     * Modified By      : MageshKumar S
     * Modified Date    : 18/07/2017
     * Purpose          : FSS-5157
     * Reviewer         : Saravanan/Pankaj S. 
     * Release Number   : VMSGPRHOST17.07
     
     * Modified By      : UBAIDUR RAHMAN.H
     * Modified Date    : 25-JAN-2018
     * Purpose          : VMS-162 (encryption changes)
     * Reviewer         : Vini.P
     * Release Number   : VMSGPRHOST18.01
*************************************************/
   v_tran_date              DATE;
   v_auth_savepoint         NUMBER                                  DEFAULT 0;
   v_rrn_count              NUMBER;
   v_errmsg                 VARCHAR2 (500);
   v_hash_pan               cms_appl_pan.cap_pan_code%TYPE;
   v_encr_pan_from          cms_appl_pan.cap_pan_code_encr%TYPE;
   v_cust_code              cms_pan_acct.cpa_cust_code%TYPE;
   v_spnd_acct_no           cms_acct_mast.cam_acct_no%TYPE;
   v_txn_type               transactionlog.txn_type%TYPE;
   v_cust_name              cms_cust_mast.ccm_user_name%TYPE;
   v_hash_password          VARCHAR2 (100);
   v_card_expry             VARCHAR2 (20);
   v_stan                   VARCHAR2 (20);
   v_capture_date           DATE;
   v_term_id                VARCHAR2 (20);
   v_mcc_code               VARCHAR2 (20);
   v_txn_amt                NUMBER;
   v_acct_number            cms_appl_pan.cap_acct_no%TYPE;--NUMBER;  --MOdified by Pankaj S. for logging changes(Mantis ID-13160)
   v_auth_id                transactionlog.auth_id%TYPE;
   v_startercard_flag       cms_appl_pan.cap_startercard_flag%TYPE;
   v_card_stat              cms_appl_pan.cap_card_stat%TYPE;
   v_user_name              cms_cust_mast.ccm_user_name%TYPE;
   v_kyc_flag               cms_caf_info_entry.cci_kyc_flag%TYPE;
   v_appl_code              cms_appl_pan.cap_appl_code%TYPE;
   v_count                  NUMBER;
   v_exp_date               VARCHAR2 (10);  --Added by Ramesh.A on 09/04/2012
   v_srv_code               VARCHAR2 (5);   --Added by Ramesh.A on 09/04/2012
   v_cardstat               VARCHAR2 (5);   --Added by ramesh.a on 11/04/2012
   exp_auth_reject_record   EXCEPTION;
   exp_reject_record        EXCEPTION;
   v_dr_cr_flag             VARCHAR2 (2);
   v_output_type            VARCHAR2 (2);
   v_tran_type              VARCHAR2 (2);
   v_trans_desc             cms_transaction_mast.ctm_tran_desc%TYPE;
                              --Added for transaction detail report on 210812
   --Sn Added by Pankaj S. for Logging issue changes(Mantis ID-13160)
   v_prod_code             cms_appl_pan.cap_prod_code%type;
   v_card_type             cms_appl_pan.cap_card_type%type;
   v_acct_balance          cms_acct_mast.cam_acct_bal%TYPE;
   v_ledger_bal            cms_acct_mast.cam_ledger_bal%TYPE;
   v_acct_type             cms_acct_mast.cam_type_code%TYPE;
   v_resp_cde              transactionlog.response_id%TYPE;
   --En Added by Pankaj S. for Logging issue changes(Mantis ID-13160)
   V_HASHKEY_ID   CMS_TRANSACTION_LOG_DTL.CTD_HASHKEY_ID%TYPE; --Added for Mantis-14308
   V_TIME_STAMP   TIMESTAMP; --Added for Mantis-14308
   v_encrypt_enable         cms_prod_cattype.cpc_encrypt_enable%type;
   v_Retperiod  date;  --Added for VMS-5739/FSP-991
v_Retdate  date; --Added for VMS-5739/FSP-991
--Main Begin Block Starts Here
BEGIN
   v_txn_type := '1';
   V_TIME_STAMP :=SYSTIMESTAMP; --Added for Mantis-14308
   SAVEPOINT v_auth_savepoint;

   --Sn Get the HashPan
   BEGIN
      v_hash_pan := gethash (p_pan_code);
   EXCEPTION
      WHEN OTHERS
      THEN
         p_resp_code := '12';
         v_errmsg :=
                    'Error while converting pan ' || SUBSTR (SQLERRM, 1, 200);
         RAISE exp_reject_record;
   END;

   --En Get the HashPan

   --Sn Create encr pan
   BEGIN
      v_encr_pan_from := fn_emaps_main (p_pan_code);
   EXCEPTION
      WHEN OTHERS
      THEN
         p_resp_code := '12';
         v_errmsg :=
                    'Error while converting pan ' || SUBSTR (SQLERRM, 1, 200);
         RAISE exp_reject_record;
   END;
 --Start Generate HashKEY for Mantis-14308
       BEGIN
           V_HASHKEY_ID := GETHASH (P_DELIVERY_CHANNEL||p_txn_mode||p_pan_code||P_RRN||to_char(V_TIME_STAMP,'YYYYMMDDHH24MISSFF5'));
       EXCEPTION
        WHEN OTHERS
        THEN
        p_resp_code := '21';
        v_errmsg :='Error while converting master data ' || SUBSTR (SQLERRM, 1, 200);
        RAISE exp_reject_record;
     END;

      --End Generate HashKEY for Mantis-14308
   --Sn find debit and credit flag
   BEGIN
      SELECT ctm_credit_debit_flag, ctm_output_type,
             TO_NUMBER (DECODE (ctm_tran_type, 'N', '0', 'F', '1')),
             ctm_tran_type, ctm_tran_desc
        INTO v_dr_cr_flag, v_output_type,
             v_txn_type,
             v_tran_type, v_trans_desc
        FROM cms_transaction_mast
       WHERE ctm_tran_code = p_txn_code
         AND ctm_delivery_channel = p_delivery_channel
         AND ctm_inst_code = p_inst_code;
   EXCEPTION
      WHEN NO_DATA_FOUND
      THEN
         p_resp_code := '12';                        --Ineligible Transaction
         v_errmsg :=
               'Transflag  not defined for txn code '
            || p_txn_code
            || ' and delivery channel '
            || p_delivery_channel;
         RAISE exp_reject_record;
      WHEN OTHERS
      THEN
         p_resp_code := '21';                        --Ineligible Transaction
         v_errmsg := 'Error while selecting transaction details';
         RAISE exp_reject_record;
   END;

   --En find debit and credit flag

   --Sn Duplicate RRN Check
   BEGIN
   --Added for VMS-5739/FSP-991
 select (add_months(trunc(sysdate,'MM'),'-'||RETENTION_PERIOD))
       INTO   v_Retperiod 
       FROM DBA_OPERATIONS.ARCHIVE_MGMNT_CTL 
       WHERE  OPERATION_TYPE='ARCHIVE' 
       AND OBJECT_NAME='TRANSACTIONLOG_EBR';
       
       v_Retdate := TO_DATE(SUBSTR(TRIM(p_tran_date), 1, 8), 'yyyymmdd');


IF (v_Retdate>v_Retperiod)
    THEN
      SELECT COUNT (1)
        INTO v_rrn_count
        FROM vmscms.transactionlog
       WHERE rrn = p_rrn
         AND business_date = p_tran_date
         AND instcode = p_inst_code
         AND delivery_channel = p_delivery_channel;
ELSE
	SELECT COUNT (1)
        INTO v_rrn_count
        FROM vmscms_history.transactionlog_hist
       WHERE rrn = p_rrn
         AND business_date = p_tran_date
         AND instcode = p_inst_code
         AND delivery_channel = p_delivery_channel;

end if;		 

      IF v_rrn_count > 0
      THEN
         p_resp_code := '22';
         v_errmsg := 'Duplicate RRN on ' || p_tran_date;
         RAISE exp_reject_record;
      END IF;
   EXCEPTION
      --Sn Added by Pankaj S. to handle exeception
      WHEN exp_reject_record
      THEN
         RAISE;
      --En Added by Pankaj S. to handle exeception
      WHEN OTHERS
      THEN
         p_resp_code := '12';
         v_errmsg :=
               'Error while selecting the RRN_COUNT from TRANSACTIONLOG'
            || SUBSTR (SQLERRM, 1, 200);
         RAISE exp_reject_record;
   END;

   --En Duplicate RRN Check

   --Sn Get Tran date
   BEGIN
      v_tran_date :=
         TO_DATE (   SUBSTR (TRIM (p_tran_date), 1, 8)
                  || ' '
                  || SUBSTR (TRIM (p_tran_time), 1, 8),
                  'yyyymmdd hh24:mi:ss'
                 );
   EXCEPTION
      WHEN OTHERS
      THEN
         p_resp_code := '21';
         v_errmsg :=
               'Problem while converting transaction date '
            || SUBSTR (SQLERRM, 1, 200);
         RAISE exp_reject_record;
   END;

   --En Get Tran date
/* Commented for not requried defect id :14383
   --Sn Check Delivery Channel
   IF p_delivery_channel NOT IN ('10','13') -- changed for MOB 62 amudhan
   THEN
      v_errmsg :=
            'Not a valid delivery channel  for '
         || ' Querying user name registration status';
      --Updated by Ramesh.A on 09/04/2012
      p_resp_code := '21';                   ---ISO MESSAGE FOR DATABASE ERROR
      RAISE exp_reject_record;
   END IF;

   --En Check Delivery Channel

   --Sn Check transaction code
   IF p_txn_code='26' OR (P_DELIVERY_CHANNEL = '13' and P_TXN_CODE <>'22' ) -- changed for MOB 62 amudhan
   THEN
      v_errmsg :=
            'Not a valid transaction code for '
         || ' Querying user name registration status';
      --Updated by Ramesh.A on 09/04/2012
      p_resp_code := '21';                   ---ISO MESSAGE FOR DATABASE ERROR
      RAISE exp_reject_record;
   END IF;

   --En check transaction code
   */

   --St Get the cust id and appl code from mast
      BEGIN
      SELECT cap_cust_code, cap_appl_code, cap_startercard_flag,
             cap_acct_no,                         --Added by Besky on 09-nov-12
             cap_card_stat,cap_prod_code,cap_card_type ,  --Added by Pankaj S. for Logging issue changes(Mantis ID-13160)
             TO_CHAR (cap_expry_date, 'MMYY'), cap_pin_off  --review changes done for FSS-1710
        INTO v_cust_code, v_appl_code, v_startercard_flag,
             v_acct_number,                       --Added by Besky on 09-nov-12
             v_cardstat,v_prod_code,v_card_type,   --Added by Pankaj S. for Logging issue changes(Mantis ID-13160)
              v_exp_date, p_pin_offset  --review changes done for FSS-1710
        FROM cms_appl_pan
       WHERE cap_inst_code = p_inst_code
         --Sn Modified by Pankaj S. during Logging changes(Mantis ID-13160)
         --AND cap_pan_code = gethash (p_pan_code);
         AND cap_pan_code=v_hash_pan;
         --En Modified by Pankaj S. during Logging changes(Mantis ID-13160)
   EXCEPTION
      WHEN OTHERS
      THEN
         p_resp_code := '21';
         v_errmsg :=
               'Error from selecting the cust code and appl code'
            || SUBSTR (SQLERRM, 1, 200);
         RAISE exp_reject_record;
   END;
   --En Get the cust id and appl code from mast
   
    BEGIN
      SELECT cpc_encrypt_enable
        INTO v_encrypt_enable
        FROM cms_prod_cattype
       WHERE cpc_inst_code = p_inst_code
         AND cpc_prod_code = v_prod_code and cpc_card_type = v_card_type;

   EXCEPTION
      WHEN OTHERS
      THEN
         p_resp_code := '21';
         v_errmsg :=
               'Error while selecting the encrypt enable flag'
            || SUBSTR (SQLERRM, 1, 200);
         RAISE exp_reject_record;
   END;
   

   /* Commented by Ramesh.A on 14/05/2012 for it will allow both starter card & gpr card.
   --St Check the Statercard or not
   IF UPPER(V_STARTERCARD_FLAG) <> 'Y' THEN

    V_ERRMSG :='Invalid StarterCard';
    P_RESP_CODE := '120';
    RAISE EXP_REJECT_RECORD;
   END IF;
   --En Check the Statercard or not
   */

   --Added by ramesh.a on 10/04/2012
      --Sn below block commented by Pankaj S. during logging changes since same query used above(Mantis ID-13160)
   /*--Sn Get the card details
   BEGIN
      SELECT cap_card_stat
        INTO v_cardstat
        FROM cms_appl_pan
       WHERE cap_inst_code = p_inst_code AND cap_pan_code = v_hash_pan;
   EXCEPTION
      WHEN NO_DATA_FOUND
      THEN
         p_resp_code := '16';                        --Ineligible Transaction
         v_errmsg := 'Card number not found ' || p_pan_code;
         RAISE exp_reject_record;
      WHEN OTHERS
      THEN
         p_resp_code := '12';
         v_errmsg :=
            'Problem while selecting card detail' || SUBSTR (SQLERRM, 1, 200);
         RAISE exp_reject_record;
   END;
   --End Get the card details*/
   --En below block commented by Pankaj S. during logging changes since same query used above(Mantis ID-13160)

   --Sn call to authorize procedure
   BEGIN
      sp_authorize_txn_cms_auth (p_inst_code,
                                 p_msg,
                                 p_rrn,
                                 p_delivery_channel,
                                 v_term_id,
                                 p_txn_code,
                                 p_txn_mode,
                                 p_tran_date,
                                 p_tran_time,
                                 p_pan_code,
                                 p_bank_code,
                                 v_txn_amt,
                                 NULL,
                                 NULL,
                                 v_mcc_code,
                                 p_curr_code,
                                 NULL,
                                 NULL,
                                 NULL,
                                 v_acct_number,
                                 NULL,
                                 NULL,
                                 NULL,
                                 NULL,
                                 NULL,
                                 NULL,
                                 NULL,
                                 NULL,
                                 v_card_expry,
                                 v_stan,
                                 '000',
                                 p_rvsl_code,
                                 v_txn_amt,
                                 v_auth_id,
                                 p_resp_code,
                                 v_errmsg,
                                 v_capture_date
                                );

      IF p_resp_code <> '00' AND v_errmsg <> 'OK'
      THEN
         --P_RESP_CODE := '21';   --Commented by Ramesh.A on 01/11/2012
         --V_ERRMSG := 'Error from auth process' || V_ERRMSG;
         RAISE exp_auth_reject_record;
      END IF;
   EXCEPTION
      WHEN exp_auth_reject_record
      THEN
         RAISE;
      WHEN OTHERS
      THEN
         p_resp_code := '21';
         v_errmsg :=
                  'Error from Card authorization' || SUBSTR (SQLERRM, 1, 200);
         RAISE exp_reject_record;
   END;

   --En call to authorize procedure

   --Sn Expiry date, service code
   --review changes done for FSS-1710
   BEGIN
      SELECT  cbp_param_value
        INTO  v_srv_code
        FROM  cms_bin_param, cms_prod_cattype
       WHERE cbp_profile_code = cpc_profile_code
         AND cbp_inst_code = cpc_inst_code
         AND cpc_prod_code = v_prod_code
         AND cpc_card_type = v_card_type
         AND cbp_param_name = 'Service Code'
         AND cpc_inst_code = p_inst_code;
   EXCEPTION
      WHEN NO_DATA_FOUND
      THEN
         p_resp_code := '16';                        --Ineligible Transaction
         v_errmsg := 'Card number not found' || p_txn_code;
         RAISE exp_reject_record;
      WHEN OTHERS
      THEN
         p_resp_code := '12';
         v_errmsg :=
            'Problem while selecting card detail' || SUBSTR (SQLERRM, 1, 200);
         RAISE exp_reject_record;
   END;

    --En  Expiry date, service code
   --St Get the kyc flag from caf info entry table
   BEGIN
      SELECT cci_kyc_flag
        INTO v_kyc_flag
        FROM cms_caf_info_entry
       WHERE cci_inst_code = p_inst_code AND cci_appl_code = to_char(v_appl_code); --To_Char added for number to varchar changes FSS-1710
   EXCEPTION
      WHEN OTHERS
      THEN
         p_resp_code := '21';
         v_errmsg :=
              'Error from selecting the kyc flag' || SUBSTR (SQLERRM, 1, 200);
         RAISE exp_reject_record;
   END;

   --En Get the kyc flag from caf info entry table

   --St  Checks whether the  username has created or not.
   BEGIN
      SELECT NVL(decode(v_encrypt_enable,'Y',fn_dmaps_main(ccm_user_name),ccm_user_name),'0')
        INTO v_user_name
        FROM cms_cust_mast
       WHERE ccm_inst_code = p_inst_code AND ccm_cust_code = v_cust_code;
   EXCEPTION
      WHEN OTHERS
      THEN
         p_resp_code := '21';
         v_errmsg :=
            'Error from while selecting username '
            || SUBSTR (SQLERRM, 1, 200);
         RAISE exp_reject_record;
   END;

   --En  Checks whether the card has registerd or not , username has created or not.

   --St Checks whether the card has registerd or not
   --IF V_CARDSTAT = '0' THEN  -- Commented by Ramesh.A on 14/05/2012
   IF UPPER (v_kyc_flag) NOT IN ('P', 'Y', 'O')
   THEN                                   -- Updated by Ramesh.A on 03/10/2012
      p_resp_code := '1';
      p_resmsg := '0';
      v_errmsg := 'Card not registered';
   ELSE
      IF v_user_name = '0'
      THEN
         p_resp_code := '1';
         p_resmsg := '1';
         v_errmsg := 'Card registered, username/password not created';
      ELSE
         p_resp_code := '1';
         p_resmsg := '2';
         v_errmsg := 'Card registered, username/password exists';
      END IF;
   END IF;

   --En Checks whether the card has registerd or not and username has created or not
   p_exp_date := v_exp_date;                 --Added by Ramesh.A on 09/04/2012
   p_srv_code := v_srv_code;                 --Added by Ramesh.A on 09/04/2012

   --ST Get responce code fomr master
   BEGIN
      SELECT cms_iso_respcde
        INTO p_resp_code
        FROM cms_response_mast
       WHERE cms_inst_code = p_inst_code
         AND cms_delivery_channel = p_delivery_channel
         AND cms_response_id = p_resp_code;
   EXCEPTION
      WHEN NO_DATA_FOUND
      THEN
         p_resp_code := '21';
         v_errmsg := 'Responce code not found ' || p_resp_code;
         RAISE exp_reject_record;
      WHEN OTHERS
      THEN
         p_resp_code := '69';               ---ISO MESSAGE FOR DATABASE ERROR
         v_errmsg :=
               'Problem while selecting data from response master '
            || p_resp_code
            || SUBSTR (SQLERRM, 1, 300);
         RAISE exp_reject_record;
   END;

   --En Get responce code fomr master

   --Sn update topup card number details in translog
   BEGIN
   --Added for VMS-5739/FSP-991
 select (add_months(trunc(sysdate,'MM'),'-'||RETENTION_PERIOD))
       INTO   v_Retperiod 
       FROM DBA_OPERATIONS.ARCHIVE_MGMNT_CTL 
       WHERE  OPERATION_TYPE='ARCHIVE' 
       AND OBJECT_NAME='TRANSACTIONLOG_EBR';
       
       v_Retdate := TO_DATE(SUBSTR(TRIM(p_tran_date), 1, 8), 'yyyymmdd');


IF (v_Retdate>v_Retperiod)
    THEN
      UPDATE vmscms.transactionlog
         SET --response_id = p_resp_code,  --Commented by Pankaj S. during logging changes(Mantis ID-13160)
             add_lupd_date = SYSDATE,
             add_lupd_user = 1,
             error_msg = v_errmsg,
             IPADDRESS=P_IPADDRESS --Added for mantis id 0012278(FSS-1144)
       WHERE rrn = p_rrn
         AND delivery_channel = p_delivery_channel
         AND txn_code = p_txn_code
         AND business_date = p_tran_date
         AND business_time = p_tran_time
         AND msgtype = p_msg
         AND customer_card_no = v_hash_pan
         AND instcode = p_inst_code;
ELSE
	 UPDATE vmscms_history.transactionlog_hist
         SET --response_id = p_resp_code,  --Commented by Pankaj S. during logging changes(Mantis ID-13160)
             add_lupd_date = SYSDATE,
             add_lupd_user = 1,
             error_msg = v_errmsg,
             IPADDRESS=P_IPADDRESS --Added for mantis id 0012278(FSS-1144)
       WHERE rrn = p_rrn
         AND delivery_channel = p_delivery_channel
         AND txn_code = p_txn_code
         AND business_date = p_tran_date
         AND business_time = p_tran_time
         AND msgtype = p_msg
         AND customer_card_no = v_hash_pan
         AND instcode = p_inst_code;
end if;		 

      IF SQL%ROWCOUNT <> 1
      THEN
         p_resp_code := '21';
         v_errmsg :=
                'Error while updating transactionlog ' || 'no valid records ';
         RAISE exp_reject_record;
      END IF;
   EXCEPTION
      WHEN exp_reject_record
      THEN
         RAISE exp_reject_record;
      WHEN OTHERS
      THEN
         p_resp_code := '21';
         v_errmsg :=
            'Error while updating transactionlog '
            || SUBSTR (SQLERRM, 1, 200);
         RAISE exp_reject_record;
   END;
--En update topup card number details in translog
  --  Added for MOB 62 amudhan
      BEGIN
--Added for VMS-5739/FSP-991
 select (add_months(trunc(sysdate,'MM'),'-'||RETENTION_PERIOD))
       INTO   v_Retperiod 
       FROM DBA_OPERATIONS.ARCHIVE_MGMNT_CTL 
       WHERE  OPERATION_TYPE='ARCHIVE' 
       AND OBJECT_NAME='CMS_TRANSACTION_LOG_DTL_EBR';
       
       v_Retdate := TO_DATE(SUBSTR(TRIM(p_tran_date), 1, 8), 'yyyymmdd');


IF (v_Retdate>v_Retperiod)
    THEN
          UPDATE vmscms.CMS_TRANSACTION_LOG_DTL
          SET  CTD_PROCESS_MSG = V_ERRMSG,
          CTD_MOBILE_NUMBER=p_devmob_no,
          CTD_DEVICE_ID=p_dev_id
          WHERE CTD_RRN = P_RRN AND CTD_DELIVERY_CHANNEL = P_DELIVERY_CHANNEL AND
           CTD_TXN_CODE = P_TXN_CODE AND CTD_BUSINESS_DATE = p_tran_date AND
           CTD_BUSINESS_TIME = p_tran_time AND  CTD_MSG_TYPE = '0200' AND
           CTD_CUSTOMER_CARD_NO = V_HASH_PAN AND CTD_INST_CODE=p_inst_code;
ELSE
		UPDATE vmscms_history.CMS_TRANSACTION_LOG_DTL_hist
          SET  CTD_PROCESS_MSG = V_ERRMSG,
          CTD_MOBILE_NUMBER=p_devmob_no,
          CTD_DEVICE_ID=p_dev_id
          WHERE CTD_RRN = P_RRN AND CTD_DELIVERY_CHANNEL = P_DELIVERY_CHANNEL AND
           CTD_TXN_CODE = P_TXN_CODE AND CTD_BUSINESS_DATE = p_tran_date AND
           CTD_BUSINESS_TIME = p_tran_time AND  CTD_MSG_TYPE = '0200' AND
           CTD_CUSTOMER_CARD_NO = V_HASH_PAN AND CTD_INST_CODE=p_inst_code;
end if;		   

          IF SQL%ROWCOUNT <> 1 THEN
           P_RESP_CODE := '21';
           V_ERRMSG  := 'Error while updating transactionlog_detl ' ||
                SUBSTR(SQLERRM, 1, 200);
           RAISE exp_reject_record;
          END IF;

         EXCEPTION
         WHEN exp_reject_record THEN
               RAISE exp_reject_record;
          WHEN OTHERS THEN
           P_RESP_CODE := '21';
           V_ERRMSG  := 'Error while updating transactionlog ' ||
                SUBSTR(SQLERRM, 1, 200);
          RAISE exp_reject_record;
        END;
        --  Added for MOB 62 amudhan
-- TransactionLog & cms_transaction_log_dtl has been removed by ramesh on 12/03/2012

--Sn Handle EXP_REJECT_RECORD execption
EXCEPTION
   WHEN exp_auth_reject_record
   THEN                                      --Added by Ramesh.A on 01/11/2012
      p_resmsg := v_errmsg;
   WHEN exp_reject_record
   THEN
      ROLLBACK TO v_auth_savepoint;
      p_resmsg := v_errmsg;                 --Added by Ramesh.A on 09/04/2012
      v_resp_cde :=p_resp_code;   --Added by Pankaj S. during logging changes(Mantis ID-13160)

      --Sn Get responce code fomr master
      BEGIN
         SELECT cms_iso_respcde
           INTO p_resp_code
           FROM cms_response_mast
          WHERE cms_inst_code = p_inst_code
            AND cms_delivery_channel = p_delivery_channel
            AND cms_response_id = p_resp_code;
      EXCEPTION
         WHEN OTHERS
         THEN
            v_errmsg :=
                  'Problem while selecting data from response master '
               || p_resp_code
               || SUBSTR (SQLERRM, 1, 300);
            p_resp_code := '69';
            RAISE exp_reject_record;
      END;

      --En Get responce code fomr master

      --Sn Added by Pankaj S. for Logging issue changes(Mantis ID-13160)
      IF v_prod_code IS NULL THEN
        BEGIN
           SELECT cap_prod_code, cap_card_type, cap_card_stat, cap_acct_no
             INTO v_prod_code, v_card_type, v_cardstat, v_acct_number
             FROM cms_appl_pan
            WHERE cap_inst_code = p_inst_code AND cap_pan_code = gethash (p_pan_code);
        EXCEPTION
           WHEN OTHERS THEN
              NULL;
        END;
      END IF;

        BEGIN
           SELECT cam_acct_bal, cam_ledger_bal, cam_type_code
             INTO v_acct_balance, v_ledger_bal, v_acct_type
             FROM cms_acct_mast
            WHERE cam_acct_no = v_acct_number AND cam_inst_code = p_inst_code;
        EXCEPTION
           WHEN OTHERS
           THEN
              v_acct_balance := 0;
              v_ledger_bal := 0;
        END;

      IF V_DR_CR_FLAG IS NULL THEN
        BEGIN
           SELECT ctm_credit_debit_flag,
                  TO_NUMBER (DECODE (ctm_tran_type, 'N', '0', 'F', '1')),
                  ctm_tran_desc
             INTO v_dr_cr_flag,
                  v_txn_type,
                  v_trans_desc
             FROM cms_transaction_mast
            WHERE ctm_tran_code = p_txn_code
              AND ctm_delivery_channel = p_delivery_channel
              AND ctm_inst_code = p_inst_code;
        EXCEPTION
           WHEN OTHERS THEN
              NULL;
        END;
      END IF;
      --En Added by Pankaj S. for Logging issue changes(Mantis ID-13160)


            --Sn Inserting data in transactionlog
      BEGIN
         INSERT INTO transactionlog
                     (msgtype, rrn, delivery_channel, date_time, txn_code,
                      txn_type, txn_mode, txn_status, response_code,
                      business_date, business_time, customer_card_no,
                      instcode, customer_card_no_encr, customer_acct_no,
                      error_msg, ipaddress, add_ins_date, add_ins_user,
                      cardstatus,--Added CARDSTATUS insert in transactionlog by srinivasu.k
                      trans_desc, response_id,
                      --Sn Added by Pankaj S. for logging changes(Mantis ID-13160)
                      productid,categoryid,cr_dr_flag,acct_balance,ledger_balance,acct_type,
                      time_stamp
                      --En Added by Pankaj S. for logging changes(Mantis ID-13160)
                     )
              VALUES (p_msg, p_rrn, p_delivery_channel, SYSDATE, p_txn_code,
                      v_txn_type, p_txn_mode, 'F', p_resp_code,
                      p_tran_date, p_tran_time, v_hash_pan,
                      p_inst_code, v_encr_pan_from,--V_SPND_ACCT_NO,
                      v_acct_number,--Added by Besky on 09-nov-12


                      v_errmsg, p_ipaddress, SYSDATE, 1,
                      v_cardstat,--Added CARDSTATUS insert in transactionlog by srinivasu.k
                      v_trans_desc, v_resp_cde,--p_resp_code,  --Modified by Pankaj S. during logging changes(Mantis ID-13160)
                      --Sn Added by Pankaj S. for logging changes(Mantis ID-13160)
                      v_prod_code,v_card_type,v_dr_cr_flag,v_acct_balance, v_ledger_bal, v_acct_type,
                      V_TIME_STAMP
                      --En Added by Pankaj S. for logging changes(Mantis ID-13160)
                     );
      EXCEPTION
         WHEN OTHERS
         THEN
            p_resp_code := '12';
            v_errmsg :=
                  'Exception while inserting to transaction log '
               || SQLCODE
               || '---'
               || SQLERRM;
            RAISE exp_reject_record;
      END;

      --En Inserting data in transactionlog

      --Sn Inserting data in transactionlog dtl
      BEGIN
         INSERT INTO cms_transaction_log_dtl
                     (ctd_delivery_channel, ctd_txn_code, ctd_txn_type,
                      ctd_txn_mode, ctd_business_date, ctd_business_time,
                      ctd_customer_card_no, ctd_fee_amount,
                      ctd_waiver_amount, ctd_servicetax_amount,
                      ctd_cess_amount, ctd_process_flag, ctd_process_msg,
                      ctd_rrn, ctd_inst_code, ctd_ins_date, ctd_ins_user,
                      ctd_customer_card_no_encr, ctd_msg_type, request_xml,
                      ctd_cust_acct_number,
                      ctd_addr_verify_response,CTD_MOBILE_NUMBER,CTD_DEVICE_ID, ctd_hashkey_id   --Added for Mantis-14308
                     )
              VALUES (p_delivery_channel, p_txn_code, v_txn_type,
                      p_txn_mode, p_tran_date, p_tran_time,
                      v_hash_pan, NULL,
                      NULL, NULL,
                      NULL, 'E', v_errmsg,
                      p_rrn, p_inst_code, SYSDATE, 1,
                      v_encr_pan_from, '000', '',
                      v_acct_number,--v_spnd_acct_no,  --Modified by Pankaj S. during Logging changes(Mantis ID-13160)
                      '',p_devmob_no,p_dev_id,  --  Added for MOB 62 amudhan
                      V_HASHKEY_ID --Added for Mantis-14308
                     );
      EXCEPTION
         WHEN OTHERS
         THEN
            v_errmsg :=
                  'Problem while inserting data into transaction log  dtl'
               || SUBSTR (SQLERRM, 1, 300);
            p_resp_code := '69';
            RETURN;
      END;
    --En Inserting data in transactionlog dtl
--En Handle EXP_REJECT_RECORD execption

   --Sn Handle OTHERS Execption
   WHEN OTHERS
   THEN
      p_resp_code := '21';
      v_errmsg := 'Main Exception ' || SQLCODE || '---' || SQLERRM;
      ROLLBACK TO v_auth_savepoint;
      p_resmsg := v_errmsg;                 --Added by Ramesh.A on 09/04/2012
      v_resp_cde :=p_resp_code;   --Added by Pankaj S. during logging changes(Mantis ID-13160)

      --Sn Get responce code fomr master
      BEGIN
         SELECT cms_iso_respcde
           INTO p_resp_code
           FROM cms_response_mast
          WHERE cms_inst_code = p_inst_code
            AND cms_delivery_channel = p_delivery_channel
            AND cms_response_id = p_resp_code;
      EXCEPTION
         WHEN OTHERS
         THEN
            v_errmsg :=
                  'Problem while selecting data from response master '
               || p_resp_code
               || SUBSTR (SQLERRM, 1, 300);
            p_resp_code := '69';
            RAISE exp_reject_record;
      END;

      --En Get responce code fomr master

       --Sn Added by Pankaj S. for Logging issue changes(Mantis ID-13160)
      IF v_prod_code IS NULL THEN
        BEGIN
           SELECT cap_prod_code, cap_card_type, cap_card_stat, cap_acct_no
             INTO v_prod_code, v_card_type, v_cardstat, v_acct_number
             FROM cms_appl_pan
            WHERE cap_inst_code = p_inst_code AND cap_pan_code = gethash (p_pan_code);
        EXCEPTION
           WHEN OTHERS THEN
              NULL;
        END;
      END IF;

        BEGIN
           SELECT cam_acct_bal, cam_ledger_bal, cam_type_code
             INTO v_acct_balance, v_ledger_bal, v_acct_type
             FROM cms_acct_mast
            WHERE cam_acct_no = v_acct_number AND cam_inst_code = p_inst_code;
        EXCEPTION
           WHEN OTHERS
           THEN
              v_acct_balance := 0;
              v_ledger_bal := 0;
        END;

      IF V_DR_CR_FLAG IS NULL THEN
        BEGIN
           SELECT ctm_credit_debit_flag,
                  TO_NUMBER (DECODE (ctm_tran_type, 'N', '0', 'F', '1')),
                  ctm_tran_desc
             INTO v_dr_cr_flag,
                  v_txn_type,
                  v_trans_desc
             FROM cms_transaction_mast
            WHERE ctm_tran_code = p_txn_code
              AND ctm_delivery_channel = p_delivery_channel
              AND ctm_inst_code = p_inst_code;
        EXCEPTION
           WHEN OTHERS THEN
              NULL;
        END;
      END IF;
      --En Added by Pankaj S. for Logging issue changes(Mantis ID-13160)

      --Sn Inserting data in transactionlog
      BEGIN
         INSERT INTO transactionlog
                     (msgtype, rrn, delivery_channel, date_time, txn_code,
                      txn_type, txn_mode, txn_status, response_code,
                      business_date, business_time, customer_card_no,
                      instcode, customer_card_no_encr, customer_acct_no,
                      error_msg, ipaddress, add_ins_date, add_ins_user,
                      cardstatus,--Added CARDSTATUS insert in transactionlog by srinivasu.k
                      trans_desc, response_id,
                      --Sn Added by Pankaj S. for logging changes(Mantis ID-13160)
                      productid,categoryid,cr_dr_flag,acct_balance,ledger_balance,acct_type,
                      time_stamp
                      --En Added by Pankaj S. for logging changes(Mantis ID-13160)
                     )
              VALUES (p_msg, p_rrn, p_delivery_channel, SYSDATE, p_txn_code,
                      v_txn_type, p_txn_mode, 'F', p_resp_code,
                      p_tran_date, p_tran_time, v_hash_pan,
                      p_inst_code, v_encr_pan_from,-- V_SPND_ACCT_NO,
                      v_acct_number, --Added by Besky on 09-nov-12


                      v_errmsg, p_ipaddress, SYSDATE, 1,
                      v_cardstat,--Added CARDSTATUS insert in transactionlog by srinivasu.k
                      v_trans_desc, v_resp_cde,--p_resp_code,  --Modified by Pankaj S. during logging changes(Mantis ID-13160)
                      --Sn Added by Pankaj S. for logging changes(Mantis ID-13160)
                      v_prod_code,v_card_type,v_dr_cr_flag,v_acct_balance, v_ledger_bal, v_acct_type,
                      V_TIME_STAMP
                      --En Added by Pankaj S. for logging changes(Mantis ID-13160)
                     );
      EXCEPTION
         WHEN OTHERS
         THEN
            p_resp_code := '12';
            v_errmsg :=
                  'Exception while inserting to transaction log '
               || SQLCODE
               || '---'
               || SQLERRM;
            RAISE exp_reject_record;
      END;

      --En Inserting data in transactionlog

      --Sn Inserting data in transactionlog dtl
      BEGIN
         INSERT INTO cms_transaction_log_dtl
                     (ctd_delivery_channel, ctd_txn_code, ctd_txn_type,
                      ctd_txn_mode, ctd_business_date, ctd_business_time,
                      ctd_customer_card_no, ctd_fee_amount,
                      ctd_waiver_amount, ctd_servicetax_amount,
                      ctd_cess_amount, ctd_process_flag, ctd_process_msg,
                      ctd_rrn, ctd_inst_code, ctd_ins_date, ctd_ins_user,
                      ctd_customer_card_no_encr, ctd_msg_type, request_xml,
                      ctd_cust_acct_number,
                      ctd_addr_verify_response,CTD_MOBILE_NUMBER,CTD_DEVICE_ID,ctd_hashkey_id --Added for Mantis-14308
                     )
              VALUES (p_delivery_channel, p_txn_code, v_txn_type,
                      p_txn_mode, p_tran_date, p_tran_time,
                      v_hash_pan, NULL,
                      NULL, NULL,
                      NULL, 'E', v_errmsg,
                      p_rrn, p_inst_code, SYSDATE, 1,
                      v_encr_pan_from, '000', '',
                      v_acct_number,--v_spnd_acct_no,  --Modified by Pankaj S. during Logging changes(Mantis ID-13160)
                      '',p_devmob_no,p_dev_id,  --  Added for MOB 62 amudhan
                      V_HASHKEY_ID  --Added for Mantis-14308
                     );
      EXCEPTION
         WHEN OTHERS
         THEN
            v_errmsg :=
                  'Problem while inserting data into transaction log  dtl'
               || SUBSTR (SQLERRM, 1, 300);
            p_resp_code := '69';
            RETURN;
      END;
   --En Inserting data in transactionlog dtl
--En Handle OTHERS Execption
END;
/
show error;
