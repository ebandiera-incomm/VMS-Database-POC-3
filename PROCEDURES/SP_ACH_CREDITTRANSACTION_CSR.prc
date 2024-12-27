create or replace PROCEDURE        vmscms.sp_ach_credittransaction_csr (
   prm_instcode              IN       NUMBER,
   prm_rrn                   IN       VARCHAR2,
   prm_terminalid            IN       VARCHAR2,
   prm_tracenumber           IN       VARCHAR2,
   prm_trandate              IN       VARCHAR2,
   prm_trantime              IN       VARCHAR2,
   prm_acctno                IN       VARCHAR2,                         ---PAN
   prm_amount                IN       NUMBER,
   prm_currcode              IN       VARCHAR2,
   prm_lupduser              IN       NUMBER,
   prm_msg                   IN       VARCHAR2,
   prm_txn_code              IN       VARCHAR2,
   prm_txn_mode              IN       VARCHAR2,
   prm_delivery_channel      IN       VARCHAR2,
   prm_mbr_numb              IN       VARCHAR2,
   prm_rvsl_code             IN       VARCHAR2,
   prm_odfi                  IN       VARCHAR2,
   prm_rdfi                  IN       VARCHAR2,
   prm_achfilename           IN       VARCHAR2,
   prm_seccode               IN       VARCHAR2,
   prm_impdate               IN       VARCHAR2,
   prm_processdate           IN       VARCHAR2,
   prm_effectivedate         IN       VARCHAR2,
   prm_incoming_crfileid     IN       VARCHAR2,
   prm_achtrantype_id        IN       VARCHAR2,
   prm_indidnum              IN       VARCHAR2,
   prm_indname               IN       VARCHAR2,
   prm_companyname           IN       VARCHAR2,
   prm_companyid             IN       VARCHAR2,
   prm_id                    IN       VARCHAR2,
   prm_compentrydesc         IN       VARCHAR2,
   prm_cust_acct_no          IN       VARCHAR2,
   prm_processtype           IN       VARCHAR2,
   prm_reason_code           IN       VARCHAR2,
   prm_remark                IN       VARCHAR2,
   prm_reason_desc           IN       VARCHAR2,
   prm_authid                IN       VARCHAR2,
                                               --added by Pankaj S.for FSS-390
   prm_resp_code             OUT      VARCHAR2,
   prm_errmsg                OUT      VARCHAR2,
   prm_startledgerbal        OUT      VARCHAR2,
   prm_startaccountbalance   OUT      VARCHAR2,
   prm_endledgerbal          OUT      VARCHAR2,
   prm_endaccountbalance     OUT      VARCHAR2,
   prm_auth_id               OUT      VARCHAR2
)
AS
/************************************************************************************************
     * Created Date                 : 26/Feb/2012.
     * Created By                   : Dhiraj G.
     * Purpose                      : NA
     * Last Modification Done by    : Sagar More
     * Last Modification Date       : 06-NOV-2012
     * Mofication Reason            : Original ACH txn is not logging currency code in TXNLOG
                                      hence hardcoded 840 while ACH exception processing
     * Build no                     : RI0021_B0004

     * Modified By                  : Pankaj S.
     * Modified Date                : 21-Mar-2013
     * Modified Reason              : Logging of system initiated card status change(FSS-390) and
                                      for max card balance check based on product category(Mantis ID-10643)
     * Reviewer                     : Dhiraj
     * Reviewed Date                :
     * Build Number                 : CSR3.5.1_RI0024_B0007

     * Modified By                  : Pankaj S.
     * Modified Date                :  09-Apr-2013
     * Modified Reason              :  Max Card Balance Check (MVHOST-299)
     * Reviewer                     : Dhiraj
     * Reviewed Date                :
     * Build Number                 : CSR3.5.1_RI0024.1_B0004

     * Modified by       : Sagar
     * Modified for      :
     * Modified Reason   : Concurrent Processsing Issue
			                (1.7.6.7 changes integarted)
     * Modified Date     : 04-Mar-2014
     * Reviewer          : Dhiarj
     * Reviewed Date     : 06-Mar-2014
     * Build Number      : RI0027.1.1_B0001

     * Modified By      : Abdul Hameed M.A
     * Modified Date    : 23-07-2015
     * Modified Reason  : For new ach changes
     * Reviewer         : Spankaj
     * Reviewed Date    : 23-07-2015
     * Build Number     : VMSGPRHOST3.0.4
     
     * Modified By      : MageshKumar S
     * Modified Date    : 10/08/2016
     * Purpose          : FSS-4354&4356
     * Reviewer         : Saravana Kumar 
     * Release Number   : VMSGPRHOSTCSD_4.2.1_B0001
    * Modified by       : Akhil
     * Modified Date     : 05-JAN-18
     * Modified For      : VMS-103
     * Reviewer          : Saravanakumar A
     * Build Number      : VMSGPRHOST_17.12
     
       * Modified By      : UBAIDUR RAHMAN H
    * Modified Date    : 16-JAN-2018
    * Purpose          : CURRENCY CODE CHANGES FROM INST LEVEL TO BIN LEVEL.
    * Reviewer         : Vini
    * Release Number   : VMSGPRHOST18.1

  * Modified By      : Sivakumar M
  * Modified Date    : 24-May-2019
  * Purpose          : VMS-922
  * Reviewer         : Saravanan
  * Release Number   : VMSGPRHOST R16
  
  * Modified by       : Mageshkumar  S
  * Modified Date     : 28-May-20
  * Modified For      : VMS-2548
  * Reviewer          : Saravanakumar A
  * Build Number      : R31_build_3
 *************************************************************************************************/
   v_cap_prod_catg              cms_appl_pan.cap_prod_catg%TYPE;
   v_cap_card_stat              cms_appl_pan.cap_card_stat%TYPE;
   v_cap_cafgen_flag            cms_appl_pan.cap_cafgen_flag%TYPE;
   v_cap_appl_code              cms_appl_pan.cap_appl_code%TYPE;
   v_firsttime_topup            cms_appl_pan.cap_firsttime_topup%TYPE;
   v_prod_code                  cms_appl_pan.cap_prod_code%TYPE;
   v_card_type                  cms_appl_pan.cap_card_type%TYPE;
   v_profile_code               cms_prod_cattype.cpc_profile_code%TYPE;
   v_errmsg                     VARCHAR2 (300);
   v_varprodflag                cms_prod_mast.cpm_var_flag%TYPE;
   v_currcode                   VARCHAR2 (3);
   v_appl_code                  cms_appl_mast.cam_appl_code%TYPE;
   v_resoncode                  cms_spprt_reasons.csr_spprt_rsncode%TYPE;
   v_respcode                   VARCHAR2 (5);
   v_respmsg                    VARCHAR2 (500);
   v_capture_date               DATE;
   v_mbrnumb                    cms_appl_pan.cap_mbr_numb%TYPE;
   v_txn_code                   cms_func_mast.cfm_txn_code%TYPE;
   v_txn_mode                   cms_func_mast.cfm_txn_mode%TYPE;
   v_del_channel                cms_func_mast.cfm_delivery_channel%TYPE;
   v_txn_type                   cms_func_mast.cfm_txn_type%TYPE;
   v_auth_id                    transactionlog.auth_id%TYPE;
   v_min_max_limit              VARCHAR2 (50);
   v_acct_txn_dtl               cms_topuptrans_count.ctc_totavail_days%TYPE;
   v_topup_freq                 VARCHAR2 (50);
   v_topup_freq_period          VARCHAR2 (50);
   v_end_lupd_date              cms_topuptrans_count.ctc_lupd_date%TYPE;
   v_acct_txn_dtl_1             cms_topuptrans_count.ctc_totavail_days%TYPE;
   v_end_day_update             cms_topuptrans_count.ctc_lupd_date%TYPE;
   v_min_limit                  VARCHAR2 (50);
   v_max_limit                  VARCHAR2 (50);
   v_rrn_count                  NUMBER;
   exp_main_reject_record       EXCEPTION;
   exp_auth_reject_record       EXCEPTION;
   v_hash_pan                   cms_appl_pan.cap_pan_code%TYPE;
   v_hash_pan_val               cms_appl_pan.cap_pan_code%TYPE;
   v_encr_pan                   cms_appl_pan.cap_pan_code_encr%TYPE;
   v_encr_pan_val               cms_appl_pan.cap_pan_code_encr%TYPE;
   v_business_date              DATE;
   v_tran_date                  DATE;
   v_topupremrk                 VARCHAR2 (100);
   v_acct_balance               NUMBER;
   v_ledger_balance             NUMBER;
   v_tran_amt                   NUMBER;
   v_delchannel_code            VARCHAR2 (2);
   v_card_curr                  VARCHAR2 (5);
   v_date                       DATE;
   v_base_curr                  cms_bin_param.cbp_param_value%TYPE;
   v_mmpos_usageamnt            cms_translimit_check.ctc_mmposusage_amt%TYPE;
   v_mmpos_usagelimit           cms_translimit_check.ctc_mmposusage_limit%TYPE;
   v_business_date_tran         DATE;
   v_proxunumber                cms_appl_pan.cap_proxy_number%TYPE;
   v_acct_number                cms_appl_pan.cap_acct_no%TYPE;
   achflag                      VARCHAR2 (5);
   achdaytrancnt                NUMBER;
   achdaytranminamt             NUMBER;
   achdaytranmaxamt             NUMBER;
   v_trancnt                    NUMBER;
   v_daytranamt                 NUMBER;
   v_ach_filename               VARCHAR2 (100);
   achseccode                   VARCHAR2 (10);
   achfilecount                 NUMBER;
   file_count                   NUMBER;
   v_start_acct_balance         VARCHAR2 (15);
   v_start_ledger_balance       VARCHAR2 (15);
   v_cust_card_no               VARCHAR2 (19);
   v_imp_date                   DATE;
   v_imp_tran_date              DATE;
   v_process_date               DATE;
   v_process_tran_date          DATE;
   v_effective_date             DATE;
   v_effective_tran_date        DATE;
   v_respcode_org_txn           VARCHAR2 (5);
   v_appliocationprocess_stat   VARCHAR2 (3);
   achweektrancnt               NUMBER;
--  ACHWEEKTRANMINAMT          NUMBER;
   achweektranmaxamt            NUMBER;
   achmonthtrancnt              NUMBER;
   --ACHMONMINAMT               NUMBER;
   achmonmaxamt                 NUMBER;
   v_weektrancnt                NUMBER;
   v_weektranamt                NUMBER;
   monthtrancnt                 NUMBER;
   monthtranamt                 NUMBER;
   odfi_txn_refundno            NUMBER;
   custssn                      VARCHAR2 (11);
   custlastname                 VARCHAR2 (40);
   maxtranamt                   VARCHAR2 (12);
   -- authid_date                  VARCHAR2 (8);
   v_resp_code                  VARCHAR2 (5);
   v_trans_desc                 cms_transaction_mast.ctm_tran_desc%TYPE;
                              --Added for transaction detail report on 210812
   --Sn Added by Pankaj S. for Mantis ID-10643
   v_max_card_bal               cms_bin_param.cbp_param_value%TYPE;
   v_dr_cr_flag                 cms_transaction_mast.ctm_credit_debit_flag%TYPE;
   --En Added by Pankaj S. for Mantis ID-10643
   v_chnge_crdstat              VARCHAR2 (2)                           := 'N';
   v_badcredit_flag             cms_prod_cattype.cpc_badcredit_flag%TYPE;
   v_tran_detl                  VARCHAR2 (100);
   v_badcredit_transgrpid       vms_group_tran_detl.vgd_group_id%TYPE;
   v_cnt                        NUMBER (2);
   v_card_stat                  cms_appl_pan.cap_card_stat%TYPE       := '12';
   v_enable_flag                VARCHAR2 (20)                          := 'Y';
   v_initialload_amt         cms_acct_mast.cam_new_initialload_amt%type;
                                             --added by Pankaj S. for FSS-390
	v_Retperiod  date;  --Added for VMS-5739/FSP-991
	v_Retdate  date; --Added for VMS-5739/FSP-991										 
BEGIN
   --<<MAIN BEGIN >>
   prm_errmsg := 'OK ';
   v_topupremrk := 'ACH Credit Transaction';

   --SN CREATE HASH PAN
   BEGIN
      v_hash_pan := gethash (prm_acctno);
      v_hash_pan_val := v_hash_pan;           --added by sagar on 05-Jul-2012
   EXCEPTION
      WHEN OTHERS
      THEN
         v_respcode := '21';
         v_errmsg :=
                    'Error while converting pan ' || SUBSTR (SQLERRM, 1, 200);
         RAISE exp_main_reject_record;
   END;

   --EN CREATE HASH PAN

   --SN create encr pan
   BEGIN
      v_encr_pan := fn_emaps_main (prm_acctno);
      v_encr_pan_val := v_encr_pan;           --added by sagar on 05-Jul-2012
   EXCEPTION
      WHEN OTHERS
      THEN
         v_respcode := '21';
         v_errmsg :=
                    'Error while converting pan ' || SUBSTR (SQLERRM, 1, 200);
         RAISE exp_main_reject_record;
   END;

   --Sn getting txn  desc
   BEGIN
      SELECT ctm_tran_desc,
             ctm_credit_debit_flag
        INTO v_trans_desc,
             v_dr_cr_flag            --v_dr_cr_flag addded for Mantis ID-10643
        FROM cms_transaction_mast
       WHERE ctm_tran_code = prm_txn_code
         AND ctm_delivery_channel = prm_delivery_channel
         AND ctm_inst_code = prm_instcode;
   EXCEPTION
      WHEN NO_DATA_FOUND
      THEN
         v_trans_desc := 'Transaction type ' || prm_txn_code;
      WHEN OTHERS
      THEN
         v_trans_desc := 'Transaction type ' || prm_txn_code;
   END;

   IF (prm_amount >= 0)
   THEN
      v_tran_amt := prm_amount;
   END IF;

IF prm_authid IS NULL THEN
   --Generate AuthId
   BEGIN
      /* -- Commented by sagar on 03-10-2012 to generate 6 digit auth id
       SELECT TO_CHAR (SYSDATE, 'YYYYMMDD') || LPAD (seq_auth_id.NEXTVAL, 6, '0')
         INTO v_auth_id
         FROM DUAL;
      */
      SELECT LPAD
                (seq_auth_id.NEXTVAL, 6, '0')
                   -- Added by sagar on 03-10-2012 to generate 6 digit auth id
        INTO v_auth_id
        FROM DUAL;
   EXCEPTION
      WHEN OTHERS
      THEN
         v_errmsg :=
                 'Error while generating authid ' || SUBSTR (SQLERRM, 1, 300);
         v_respcode := '21';                               -- Server Declined
         --ROLLBACK;
         -- RETURN;
         RAISE exp_main_reject_record;
   END;
   
   ELSE
   
   v_auth_id := prm_authid;
   
   END IF;

   prm_auth_id := v_auth_id;

   --Sn Duplicate RRN Check.IF duplicate RRN log the txn and return
   BEGIN
      IF prm_processtype <> 'N'
      THEN
	  --Added for VMS-5739/FSP-991
	 select (add_months(trunc(sysdate,'MM'),'-'||RETENTION_PERIOD))
		   INTO   v_Retperiod 
		   FROM DBA_OPERATIONS.ARCHIVE_MGMNT_CTL 
		   WHERE  OPERATION_TYPE='ARCHIVE' 
		   AND OBJECT_NAME='TRANSACTIONLOG_EBR';
		   
		   v_Retdate := TO_DATE(SUBSTR(TRIM(prm_trandate), 1, 8), 'yyyymmdd');


	IF (v_Retdate>v_Retperiod)
		THEN
			 SELECT COUNT (1)
			   INTO v_rrn_count
			   FROM transactionlog
			  WHERE rrn = prm_rrn
				AND business_date = prm_trandate
				AND delivery_channel = prm_delivery_channel;
	ELSE
			 SELECT COUNT (1)
			   INTO v_rrn_count
			   FROM VMSCMS_HISTORY.TRANSACTIONLOG_HIST --Added for VMS-5733/FSP-991
			  WHERE rrn = prm_rrn
				AND business_date = prm_trandate
				AND delivery_channel = prm_delivery_channel;
	END IF;		
      END IF;

      IF v_rrn_count > 0
      THEN
         v_respcode := '22';
         v_errmsg := 'Duplicate RRN ' || 'on ' || prm_trandate;
         RAISE exp_main_reject_record;
      END IF;
   EXCEPTION
      WHEN exp_main_reject_record
      THEN
         RAISE exp_main_reject_record;
      WHEN OTHERS
      THEN
         v_respcode := '21';
         v_errmsg := 'Duplicate RRN ' || 'on ' || prm_trandate;
         RAISE exp_main_reject_record;
   END;

   --En Duplicate RRN Check

   --BEFORE TRANSACTION LEDGER BALANCE AND ACCOUNT BALANCE
   BEGIN
      SELECT     cam_acct_bal, cam_ledger_bal,nvl(cam_new_initialload_amt,cam_initialload_amt)
            INTO v_start_acct_balance, v_start_ledger_balance,v_initialload_amt
            FROM cms_acct_mast
           WHERE cam_acct_no =
                    (SELECT cap_acct_no
                       FROM cms_appl_pan
                      WHERE cap_pan_code = v_hash_pan            --prm_card_no
                        AND cap_mbr_numb = prm_mbr_numb
                        AND cap_inst_code = prm_instcode)
             AND cam_inst_code = prm_instcode
            FOR UPDATE;                      -- Added for Concurrent Processsing Issue
             --FOR UPDATE NOWAIT;             -- Commented for Concurrent Processsing Issue


      prm_startledgerbal := v_start_ledger_balance;
      prm_startaccountbalance := v_start_acct_balance;
   EXCEPTION
      WHEN NO_DATA_FOUND
      THEN
         v_respcode := '14';                         --Ineligible Transaction
         v_errmsg := 'Invalid Card ';
         RAISE exp_main_reject_record;
      WHEN OTHERS
      THEN
         v_respcode := '12';
         v_errmsg :=
               'Error while selecting data from card Master for card number '
            || v_hash_pan;
         RAISE exp_main_reject_record;
   END;

   --prm_startledgerbal := v_start_ledger_balance;
   --prm_startaccountbalance := v_start_acct_balance;

   --PRM_ERRMSG := TO_CHAR(V_ACCT_BALANCE);

    ------------------------------------------------------
        --Sn Added for Concurrent Processsing Issue
    ------------------------------------------------------

       BEGIN
          IF prm_processtype <> 'N'
          THEN
		  --Added for VMS-5739/FSP-991
	 select (add_months(trunc(sysdate,'MM'),'-'||RETENTION_PERIOD))
		   INTO   v_Retperiod 
		   FROM DBA_OPERATIONS.ARCHIVE_MGMNT_CTL 
		   WHERE  OPERATION_TYPE='ARCHIVE' 
		   AND OBJECT_NAME='TRANSACTIONLOG_EBR';
		   
		   v_Retdate := TO_DATE(SUBSTR(TRIM(prm_trandate), 1, 8), 'yyyymmdd');


	IF (v_Retdate>v_Retperiod)
		THEN
				 SELECT COUNT (1)
				   INTO v_rrn_count
				   FROM transactionlog
				  WHERE rrn = prm_rrn
					AND business_date = prm_trandate
					AND delivery_channel = prm_delivery_channel;
	ELSE
				SELECT COUNT (1)
				   INTO v_rrn_count
				   FROM VMSCMS_HISTORY.TRANSACTIONLOG_HIST --Added for VMS-5733/FSP-991
				  WHERE rrn = prm_rrn
					AND business_date = prm_trandate
					AND delivery_channel = prm_delivery_channel;
	END IF;				
          END IF;

          IF v_rrn_count > 0
          THEN
             v_respcode := '22';
             v_errmsg := 'Duplicate RRN ' || 'on ' || prm_trandate;
             RAISE exp_main_reject_record;
          END IF;
       EXCEPTION
          WHEN exp_main_reject_record
          THEN
             RAISE exp_main_reject_record;
          WHEN OTHERS
          THEN
             v_respcode := '21';
             v_errmsg := 'Duplicate RRN ' || 'on ' || prm_trandate;
             RAISE exp_main_reject_record;
       END;

    ------------------------------------------------------
        --En Added for Concurrent Processsing Issue
    ------------------------------------------------------


   --Sn select Pan detail
   BEGIN
      SELECT cap_card_stat, cap_prod_catg, cap_cafgen_flag,
             cap_appl_code, cap_firsttime_topup, cap_mbr_numb,
             cap_prod_code, cap_card_type, cap_proxy_number, cap_acct_no
        INTO v_cap_card_stat, v_cap_prod_catg, v_cap_cafgen_flag,
             v_appl_code, v_firsttime_topup, v_mbrnumb,
             v_prod_code, v_card_type, v_proxunumber, v_acct_number
        FROM cms_appl_pan
       WHERE cap_pan_code = v_hash_pan AND cap_inst_code = prm_instcode;
   EXCEPTION
      WHEN exp_main_reject_record
      THEN
         RAISE;
      WHEN NO_DATA_FOUND
      THEN
         v_respcode := '21';
         v_errmsg := 'Invalid Card number ' || v_hash_pan;
         RAISE exp_main_reject_record;
      WHEN OTHERS
      THEN
         v_respcode := '21';
         v_errmsg := 'Error while selecting card number ' || v_hash_pan;
         RAISE exp_main_reject_record;
   END;

   BEGIN
      SELECT cpc_profile_code, cpc_badcredit_flag, cpc_badcredit_transgrpid
        INTO v_profile_code, v_badcredit_flag, v_badcredit_transgrpid
        FROM cms_prod_cattype
       WHERE cpc_inst_code = prm_instcode
         AND cpc_prod_code = v_prod_code
         AND cpc_card_type = v_card_type;
   EXCEPTION
      WHEN exp_main_reject_record
      THEN
         RAISE;
      WHEN NO_DATA_FOUND
      THEN
         v_respcode := '21';
         v_errmsg := 'Error while selecting from CMS_PROD_CATTYPE';
         RAISE exp_main_reject_record;
      WHEN OTHERS
      THEN
         v_respcode := '21';
         v_errmsg :=
               'ERROR IN FETCHING DATA FROM  CMS_PROD_CATTYPE '
            || SUBSTR (SQLERRM, 1, 200);
         RAISE exp_main_reject_record;
   END;
   --Sn added by Pankaj S. for max card balance check based on product category(Mantis ID-10643)
   BEGIN
      SELECT TO_NUMBER (cbp_param_value)
        INTO v_max_card_bal
        FROM cms_bin_param
       WHERE cbp_inst_code = prm_instcode
         AND cbp_param_name = 'Max Card Balance'
         AND cbp_profile_code = v_profile_code;

      IF v_dr_cr_flag = 'CR'
      THEN
         IF v_badcredit_flag = 'Y'
         THEN
            EXECUTE IMMEDIATE    'SELECT  count(*) 
              FROM vms_group_tran_detl
              WHERE vgd_group_id ='
                              || v_badcredit_transgrpid
                              || '
              AND vgd_tran_detl LIKE 
              (''%'
                              || prm_delivery_channel
                              || ':'
                              || prm_txn_code
                              || '%'')'
                         INTO v_cnt;
            IF v_cnt = 1
            THEN
               v_enable_flag := 'N';
               IF    ((v_start_acct_balance + prm_amount) > v_initialload_amt
                     )                                     --initialloadamount
                  OR ((v_start_ledger_balance + prm_amount) > v_initialload_amt
                     )
               THEN                                        --initialloadamount
                  UPDATE cms_appl_pan
                     SET cap_card_stat = '18'
                   WHERE cap_inst_code = prm_instcode
                     AND cap_pan_code = v_hash_pan;
                  v_chnge_crdstat := 'Y';
               END IF;
            END IF;
         END IF;
         IF v_enable_flag = 'Y'
         THEN
         IF    ((v_start_acct_balance + prm_amount) > v_max_card_bal)
            OR ((v_start_ledger_balance + prm_amount) > v_max_card_bal)
         THEN
            v_respcode := '30';
            v_errmsg := 'EXCEEDING MAXIMUM CARD BALANCE';
            RAISE exp_main_reject_record;
         END IF;
         END IF;
      /*  IF    ((v_start_acct_balance + prm_amount) > v_max_card_bal)
            OR ((v_start_ledger_balance + prm_amount) > v_max_card_bal)
         THEN
            IF v_cap_card_stat <> '12'
            THEN
               UPDATE cms_appl_pan
                  SET cap_card_stat = '12'
                WHERE cap_inst_code = prm_instcode
                  AND cap_pan_code = v_hash_pan;

               IF SQL%ROWCOUNT = 0
               THEN
                  v_errmsg := 'Error while updating the card status';
                  v_respcode := '21';
                  RAISE exp_main_reject_record;
               END IF;

               v_chnge_crdstat := 'Y';                     --added for FSS-390
            END IF;
        END IF;*/
      END IF;
   EXCEPTION
      WHEN exp_main_reject_record
      THEN
         RAISE;
      WHEN NO_DATA_FOUND
      THEN
         v_respcode := '21';
         v_errmsg := 'Max card balance not configured to product profile';
         RAISE exp_main_reject_record;
      WHEN OTHERS
      THEN
         v_respcode := '21';
         v_errmsg :=
               'ERROR IN FETCHING CARD BALANCE CONFIGURATION FOR THE PRODUCT PROFILE '
            || SUBSTR (SQLERRM, 1, 200);
         RAISE exp_main_reject_record;
   END;

   --En added by Pankaj S. for max card balance check based on product category(Mantis ID-10643)

   -----------------------------------------
--SN: Commented for Force posting changes
------------------------------------------

   /*
     --Sn check the min and max limit for topup
     BEGIN
        SELECT cpc_profile_code
          INTO v_profile_code
          FROM cms_prod_cattype
         WHERE cpc_prod_code = v_prod_code
           AND cpc_card_type = v_card_type
           AND cpc_inst_code = prm_instcode;
     EXCEPTION
        WHEN NO_DATA_FOUND
        THEN
           v_respcode := '21';
           v_errmsg := 'profile_code not defined ' || v_profile_code;
           RAISE exp_main_reject_record;
        WHEN OTHERS
        THEN
           v_respcode := '21';
           v_errmsg := 'profile_code not defined ' || v_profile_code;
           RAISE exp_main_reject_record;
     END;

     --ACH Suupot for ProdCAtg

     --CPC_ACHTXN_MAXTRANAMT
     BEGIN
        SELECT cpc_achtxn_flg, cpc_achtxn_daycnt,
                                                 --Per day transaction max count
                                                 cpc_achtxn_mintranamt,
               --Per transaction minimum amount
               cpc_achtxn_daymaxamt,       -- Per day transaction maximum amount
                                    cpc_achtxn_weekcnt,
               --Per week transaction max count
               cpc_achtxn_weekmaxamt,     -- Per week transaction maximum amount
                                     cpc_achtxn_moncnt,
                                                       --Per month transaction max count
                                                       cpc_achtxn_monmaxamt,
               -- Per month transaction maximum amount
               cpc_odfi_taxrefundno, cpc_achtxn_maxtranamt
          INTO achflag, achdaytrancnt, achdaytranminamt,
               achdaytranmaxamt, achweektrancnt,
               achweektranmaxamt, achmonthtrancnt, achmonmaxamt,
               odfi_txn_refundno, maxtranamt
          FROM cms_prod_cattype
         WHERE cpc_profile_code = v_profile_code
           AND cpc_prod_code = v_prod_code
           AND cpc_card_type = v_card_type
           AND cpc_inst_code = prm_instcode;

        IF TRIM (achflag) IS NULL
        THEN
           v_errmsg := 'ACH FLAG Cannot be null ';
           RAISE exp_main_reject_record;
        END IF;
     EXCEPTION
        WHEN NO_DATA_FOUND
        THEN
           v_errmsg := 'ACH FLAG Cannot be null ';
           RAISE exp_main_reject_record;
        WHEN OTHERS
        THEN
           v_errmsg :=
                  'Error while selecting ACH FLAG  ' || SUBSTR (SQLERRM, 1, 200);
           RAISE exp_main_reject_record;
     END;

     --En  select variable type detail
     BEGIN
        SELECT COUNT (*)
          INTO achseccode
          FROM cms_prod_catsec
         WHERE cpc_prod_code = v_prod_code
           AND cpc_inst_code = prm_instcode
           AND cpc_sec_code = prm_seccode
           AND cpc_card_type = v_card_type
           AND cpc_tran_code = prm_txn_code;
     EXCEPTION
        WHEN NO_DATA_FOUND
        THEN
           v_respcode := '27';
           v_errmsg := 'SEC Code is not allowed for ACH transaction ';
           RAISE exp_main_reject_record;
        WHEN OTHERS
        THEN
           v_respcode := '27';
           v_errmsg :=
                 'Error while selecting cms_prod_catsec '
              || SUBSTR (SQLERRM, 1, 200);
           RAISE exp_main_reject_record;
     END;

     IF achseccode = 0
     THEN
        v_respcode := '27';
        v_errmsg := 'SEC Code is not allowed for ACH transaction';
        RAISE exp_main_reject_record;
     END IF;

     IF TRIM (achflag) = 'N'
     THEN
        v_respcode := '33';
        v_errmsg :=
              'ACH Transaction is not Supported for the Product Category'
           || prm_cust_acct_no;
        RAISE exp_main_reject_record;
     END IF;
    */

   -----------------------------------------
--EN: Commented for Force posting changes
------------------------------------------

   --En Check initial load
   BEGIN
      SELECT cdm_channel_code
        INTO v_delchannel_code
        FROM cms_delchannel_mast
       WHERE cdm_channel_desc = 'MMPOS' AND cdm_inst_code = prm_instcode;

      --IF the DeliveryChannel is MMPOS then the base currency will be the txn curr
      IF v_delchannel_code = prm_delivery_channel
      THEN
         BEGIN
            SELECT trim(cbp_param_value)
              INTO v_base_curr
              FROM cms_bin_param
             WHERE cbp_inst_code = prm_instcode AND cbp_param_name = 'Currency'
             AND cbp_profile_code = v_profile_code;

            IF TRIM (v_base_curr) IS NULL
            THEN
               v_errmsg := 'Base currency cannot be null ';
               RAISE exp_main_reject_record;
            END IF;
         EXCEPTION
            WHEN NO_DATA_FOUND
            THEN
               v_errmsg :=
                          'Base currency is not defined for the institution ';
               RAISE exp_main_reject_record;
            WHEN OTHERS
            THEN
               v_errmsg :=
                     'Error while selecting bese currecy  '
                  || SUBSTR (SQLERRM, 1, 200);
               RAISE exp_main_reject_record;
         END;

         v_currcode := v_base_curr;
      ELSE
         v_currcode := prm_currcode;
      END IF;
   EXCEPTION
      WHEN exp_main_reject_record
      THEN
         RAISE exp_main_reject_record;
      WHEN NO_DATA_FOUND
      THEN
         v_errmsg :=
               'Delivery Channel of MMPOS is not defined'
            || SUBSTR (SQLERRM, 1, 200);
         RAISE exp_main_reject_record;
      WHEN OTHERS
      THEN
         v_errmsg :=
               'Error while selecting the Delivery Channel of MMPOS  '
            || SUBSTR (SQLERRM, 1, 200);
         RAISE exp_main_reject_record;
   END;

   --Trnsaction Date Validation  starts
   BEGIN
      v_date := TO_DATE (SUBSTR (TRIM (prm_trandate), 1, 8), 'yyyymmdd');
   EXCEPTION
      WHEN OTHERS
      THEN
         v_respcode := '45';
         v_errmsg :=
               'Problem while converting transaction date '
            || SUBSTR (SQLERRM, 1, 200);
         RAISE exp_main_reject_record;
   END;

   BEGIN
      v_tran_date :=
         TO_DATE (   SUBSTR (TRIM (prm_trandate), 1, 8)
                  || ' '
                  || SUBSTR (TRIM (prm_trantime), 1, 10),
                  'yyyymmdd hh24:mi:ss'
                 );
   EXCEPTION
      WHEN OTHERS
      THEN
         v_respcode := '32';
         v_errmsg :=
               'Problem while converting transaction time '
            || SUBSTR (SQLERRM, 1, 200);
         RAISE exp_main_reject_record;
   END;

   --Trnsaction Date Validation Ends

   --Imp date Vlaidation starts
   BEGIN
      v_imp_date := TO_DATE (SUBSTR (TRIM (prm_impdate), 1, 8), 'yyyymmdd');
   EXCEPTION
      WHEN OTHERS
      THEN
         v_respcode := '45';
         v_errmsg :=
            'Problem while converting IMP Date  ' || SUBSTR (SQLERRM, 1, 200);
         RAISE exp_main_reject_record;
   END;

   BEGIN
      v_imp_tran_date :=
         TO_DATE (   SUBSTR (TRIM (prm_impdate), 1, 8)
                  || ' '
                  || SUBSTR (TRIM (prm_impdate), 9, 19),
                  'yyyymmdd hh24:mi:ss'
                 );
   EXCEPTION
      WHEN OTHERS
      THEN
         v_respcode := '32';
         v_errmsg :=
             'Problem while converting IMP Time ' || SUBSTR (SQLERRM, 1, 200);
         RAISE exp_main_reject_record;
   END;

   --IMP Date Validaton Ends

   --PROCESS date Vlaidation starts
   BEGIN
      v_process_date :=
                  TO_DATE (SUBSTR (TRIM (prm_processdate), 1, 8), 'yyyymmdd');
   EXCEPTION
      WHEN OTHERS
      THEN
         v_respcode := '45';
         v_errmsg :=
               'Problem while converting PROCESS Date  '
            || SUBSTR (SQLERRM, 1, 200);
         RAISE exp_main_reject_record;
   END;

   BEGIN
      v_process_tran_date :=
         TO_DATE (   SUBSTR (TRIM (prm_processdate), 1, 8)
                  || ' '
                  || SUBSTR (TRIM (prm_processdate), 9, 19),
                  'yyyymmdd hh24:mi:ss'
                 );
   EXCEPTION
      WHEN OTHERS
      THEN
         v_respcode := '32';
         v_errmsg :=
               'Problem while converting PROCESS Time '
            || SUBSTR (SQLERRM, 1, 200);
         RAISE exp_main_reject_record;
   END;

   --PROCESS Date Validaton Ends

   --EFFECTIVE DATE   Vlaidation starts
   BEGIN
      v_effective_date :=
                TO_DATE (SUBSTR (TRIM (prm_effectivedate), 1, 8), 'yyyymmdd');
   EXCEPTION
      WHEN OTHERS
      THEN
         v_respcode := '45';
         v_errmsg :=
               'Problem while converting EFFECTIVE Date  '
            || SUBSTR (SQLERRM, 1, 200);
         RAISE exp_main_reject_record;
   END;

   BEGIN
      v_effective_tran_date :=
         TO_DATE (   SUBSTR (TRIM (prm_effectivedate), 1, 8)
                  || ' '
                  || SUBSTR (TRIM (prm_effectivedate), 9, 19),
                  'yyyymmdd hh24:mi:ss'
                 );
   EXCEPTION
      WHEN OTHERS
      THEN
         v_respcode := '32';
         v_errmsg :=
               'Problem while converting EFFECTIVE Time '
            || SUBSTR (SQLERRM, 1, 200);
         RAISE exp_main_reject_record;
   END;

   --EFFECTIVE DATE   Validaton Ends
   BEGIN
      sp_convert_curr (prm_instcode,
                       v_currcode,
                       -- PRM_ACCTNO,
                       --v_cust_card_no,
                       prm_acctno,
                       prm_amount,
                       v_tran_date,
                       v_tran_amt,
                       v_card_curr,
                       v_errmsg,
                       v_prod_code,
                       v_card_type
                      );

      IF v_errmsg <> 'OK'
      THEN
         v_respcode := '21';
         RAISE exp_main_reject_record;
      END IF;
   EXCEPTION
      WHEN exp_main_reject_record
      THEN
         RAISE;
      WHEN OTHERS
      THEN
         v_respcode := '89';                       -- Server Declined -220509
         v_errmsg :=
                'Error from currency conversion ' || SUBSTR (SQLERRM, 1, 200);
         RAISE exp_main_reject_record;
   END;

-----------------------------------------
--SN: Commented for Force posting changes
------------------------------------------

   /*
      --SSN COMEs under name
      BEGIN
         SELECT ccm_ssn, ccm_last_name
           INTO custssn, custlastname
           FROM cms_cust_mast
          WHERE ccm_cust_code = (SELECT cap_cust_code
                                   FROM cms_appl_pan
                                  WHERE cap_pan_code = v_hash_pan)
            AND ccm_inst_code = prm_instcode;

         IF prm_processtype <> 'N'
         THEN
            IF odfi_txn_refundno = prm_odfi
            THEN
               IF custssn <> prm_indname
               THEN
                  v_respcode := '17';
                  --need to be change base on the response required
                  v_errmsg := 'SSN Not Matched ';
                  RAISE exp_main_reject_record;
               END IF;
            END IF;
         END IF;
      EXCEPTION when exp_main_reject_record
      then
         raise exp_main_reject_record;

         WHEN NO_DATA_FOUND
         THEN
            v_respcode := '17';
            v_errmsg := 'SSN Not Available';
            RAISE exp_main_reject_record;
         WHEN OTHERS
         THEN
            v_respcode := '17';
            v_errmsg := 'Error while selecting SSN' || SUBSTR (SQLERRM, 1, 200);
            RAISE exp_main_reject_record;
      END;

      IF prm_amount > maxtranamt
      THEN
         v_respcode := '23';
         v_errmsg := ' ACH transaction Amount is GREATER THAN MAX TRAN AMOUNT';
         RAISE exp_main_reject_record;
      END IF;

      BEGIN
         SELECT COUNT (*), SUM (amount)
           INTO v_trancnt, v_daytranamt
           FROM transactionlog
          WHERE business_date = prm_trandate
            AND response_code = '00'
            AND customer_card_no = v_hash_pan
            AND txn_code IN ('22', '32', '27', '37')
            AND instcode = prm_instcode
            AND delivery_channel = prm_delivery_channel;
                                       --modified by Ramkumar.MK on 26 march 2012
      EXCEPTION
         WHEN NO_DATA_FOUND
         THEN
            v_errmsg :=
                      'error in transaction count1 ' || SUBSTR (SQLERRM, 1, 200);
            RAISE exp_main_reject_record;
         WHEN OTHERS
         THEN
            v_errmsg :=
                      'error in transaction count2 ' || SUBSTR (SQLERRM, 1, 200);
            RAISE exp_main_reject_record;
      END;

      IF (v_trancnt + 1) > achdaytrancnt
      THEN
         v_respcode := '23';
         v_errmsg := 'Per Day Maximum ACH transaction count reached';
         RAISE exp_main_reject_record;
      END IF;

      IF prm_txn_code NOT IN ('23', '33')
      THEN
       --Adde for Allowing Zero amount for PRE-Note Transctions on 21-05-2012 Defetce ID 7589
           IF prm_amount < achdaytranminamt
          THEN
             v_respcode := '23';
             v_errmsg := ' ACH transaction Amount is lesser than Minimum Tranamount';
             RAISE exp_main_reject_record;
          END IF;

      end if;

      IF (v_daytranamt + prm_amount) > achdaytranmaxamt
      THEN
         v_respcode := '23';
         v_errmsg := 'Per Day Maximum ACH transaction Amount Reached';
         RAISE exp_main_reject_record;
      END IF;

      --Week Trancount and maxTranAmounr
      BEGIN
         SELECT COUNT (*), SUM (amount)
           INTO v_weektrancnt, v_weektranamt
           FROM transactionlog
          WHERE TO_DATE (business_date, 'yyyymmdd')
                   BETWEEN TRUNC (TO_DATE (prm_trandate, 'yyyymmdd'), 'day')
                       AND TO_DATE (prm_trandate, 'yyyymmdd')
            AND response_code = '00'
            AND customer_card_no = v_hash_pan
            AND txn_code IN ('22', '32', '27', '37')
            AND instcode = prm_instcode
            AND delivery_channel = prm_delivery_channel;
                                       --modified by Ramkumar.MK on 26 march 2012
      EXCEPTION
         WHEN NO_DATA_FOUND
         THEN
            v_errmsg :=
               'error in week txn count selection1 ' || SUBSTR (SQLERRM, 1, 200);
            RAISE exp_main_reject_record;
         WHEN OTHERS
         THEN
            v_errmsg :=
               'error in week txn count selection2 ' || SUBSTR (SQLERRM, 1, 200);
            RAISE exp_main_reject_record;
      END;

      IF (v_weektrancnt + 1) > achweektrancnt
      THEN
         v_respcode := '23';
         v_errmsg := 'Per Week Maximum ACH transaction count reached';
         RAISE exp_main_reject_record;
      END IF;

      IF (v_weektranamt + prm_amount) > achdaytranmaxamt
      THEN
         v_respcode := '23';
         v_errmsg := 'Per Week Maximum ACH transaction Amount Reached';
         RAISE exp_main_reject_record;
      END IF;

      --END

      --Month Trancount and maxTranAmounr
      BEGIN
         SELECT COUNT (*), SUM (amount)
           INTO monthtrancnt, monthtranamt
           FROM transactionlog
          WHERE TO_DATE (business_date, 'yyyymmdd')
                   BETWEEN TRUNC (TO_DATE (prm_trandate, 'yyyymmdd'), 'MONTH')
                       AND TO_DATE (prm_trandate, 'yyyymmdd')
            AND response_code = '00'
            AND customer_card_no = v_hash_pan
            AND txn_code IN ('22', '32', '27', '37')
            AND instcode = prm_instcode
            AND delivery_channel = prm_delivery_channel;
                                       --modified by Ramkumar.MK on 26 march 2012

      EXCEPTION
         --WHEN NO_DATA_FOUND
         --THEN
          --  NULL;
         WHEN OTHERS
         THEN
            v_errmsg := 'Error in monthly txn count';
            RAISE exp_main_reject_record;
      END;

      IF (monthtrancnt + 1) > achmonthtrancnt
      THEN
         v_respcode := '23';
         v_errmsg := 'Per Month Maximum ACH transaction count reached';
         RAISE exp_main_reject_record;
      END IF;

      IF (monthtranamt + prm_amount) > achmonmaxamt
      THEN
         v_respcode := '23';
         v_errmsg := 'Per Month Maximum ACH transaction Amount Reached';
         RAISE exp_main_reject_record;
      END IF;

      --END
      --inst level ODFI Code
      BEGIN
         IF odfi_txn_refundno = NULL
         THEN
            SELECT cip_param_value
              INTO odfi_txn_refundno
              FROM cms_inst_param
             WHERE cip_param_key = 'ODFI' AND cip_inst_code = prm_instcode;
         END IF;
      EXCEPTION
         WHEN NO_DATA_FOUND
         THEN
            v_respcode := '23';
            v_errmsg := 'ODFI CODE IS NOT CONFIGURED FOR INSTUTION';
            RAISE exp_main_reject_record;
         WHEN OTHERS
         THEN
            v_respcode := '23';
            v_errmsg :=
                   'ERROR WHILE SELECTING ODFI CODE' || SUBSTR (SQLERRM, 1, 200);
            RAISE exp_main_reject_record;
      END;
      --End
     */

   -----------------------------------------
--EN: Commented for Force posting changes
------------------------------------------

   --------------Sn For Debit Card No need using authorization -----------------------------------
   IF v_cap_prod_catg = 'P'
   THEN
      --Sn call to ACH override txn prcoess
      v_ach_filename := prm_achfilename;
      v_currcode := '840';                              -- added on 06NOV2012

      BEGIN
         --SP_OVERRIDE_ACH_CSR
         sp_authorize_txn_csr_auth_ach
            (prm_instcode,
             prm_msg,
             prm_rrn,
             prm_delivery_channel,
             prm_terminalid,
             prm_txn_code,
             prm_txn_mode,
             prm_trandate,
             prm_trantime,
             prm_acctno,
             NULL,
             prm_amount,
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
             NULL,                                                 -- prm_stan
             prm_mbr_numb,                                          --Ins User
             prm_rvsl_code,                                         --INS Date
             v_tran_amt,
             prm_achfilename,
             prm_odfi,
             prm_rdfi,
             prm_seccode,
             prm_impdate,
             prm_processdate,
             prm_effectivedate,
             prm_tracenumber,
             prm_incoming_crfileid,
             prm_achtrantype_id,
             v_start_ledger_balance,
             v_start_acct_balance,
             prm_indidnum,
             prm_indname,
             prm_companyname,
             prm_companyid,
             prm_id,
             NULL,
             custlastname,
             v_cap_card_stat,
             prm_processtype,
             prm_auth_id,
             v_respcode,
-- Response Id --Added by sivapragasam to get response id to insert in transactionlog on june 08 2012
             v_resp_code,                                     -- Response Code
             v_respmsg,
             v_capture_date
            );

         IF v_resp_code <> '00' AND v_respmsg <> 'OK'
         THEN
            v_errmsg := v_respmsg;
            RAISE exp_auth_reject_record;
         /*
           IF v_respcode ='12' and v_respmsg='INVALID APPLICATION ISSUANCE STATUS' ---added by amit on 17-sep-2012 to override the exceeding card balance and shipp status validation.
           THEN
               v_respcode:='00';
                 v_respmsg:='OK';
           ELSIF v_respcode ='30' and v_respmsg='EXCEEDING MAXIMUM CARD BALANCE'
           THEN
               v_respcode:='00';
               v_respmsg:='OK';
           ELSE
               v_errmsg := v_respmsg;
               RAISE exp_auth_reject_record;
           END IF;
         */
         END IF;
      EXCEPTION
         WHEN exp_auth_reject_record
         THEN
            RAISE;
         WHEN exp_main_reject_record
         THEN
            RAISE;
         WHEN OTHERS
         THEN
            v_errmsg :=
                'Error from ACH override prcess ' || SUBSTR (SQLERRM, 1, 200);
            RAISE exp_main_reject_record;
      END;
   END IF;

   prm_auth_id := v_auth_id;

--------------------------En
--En call to authorize txn

   --Sn added by Pankaj S. for FSS-390
   IF v_chnge_crdstat = 'Y'
   THEN
      BEGIN
         sp_log_cardstat_chnge (prm_instcode,
                                v_hash_pan,
                                v_encr_pan,
                                v_auth_id, --prm_authid,
                                '10',
                                prm_rrn,
                                prm_trandate,
                                prm_trantime,
                                v_respcode,
                                v_errmsg
                               );

         IF v_respcode <> '00' AND v_errmsg <> 'OK'
         THEN
            RAISE exp_main_reject_record;
         END IF;
      EXCEPTION
         WHEN exp_main_reject_record
         THEN
            RAISE;
         WHEN OTHERS
         THEN
            v_respcode := '21';
            v_errmsg :=
                  'Error while logging system initiated card status change '
               || SUBSTR (SQLERRM, 1, 200);
            RAISE exp_main_reject_record;
      END;
   END IF;

   --En added by Pankaj S. for FSS-390

   --Sn create a record in pan spprt
   BEGIN
      SELECT csr_spprt_rsncode
        INTO v_resoncode
        FROM cms_spprt_reasons
       WHERE csr_spprt_key = 'TOP UP' AND csr_inst_code = prm_instcode;
   EXCEPTION
      WHEN NO_DATA_FOUND
      THEN
         v_errmsg := 'Top up reason code is present in master';
         v_respcode := '21';
         RAISE exp_main_reject_record;
      WHEN OTHERS
      THEN
         v_errmsg :=
               'Error while selecting reason code from master'
            || SUBSTR (SQLERRM, 1, 200);
         v_respcode := '21';
         RAISE exp_main_reject_record;
   END;

   BEGIN
      INSERT INTO cms_pan_spprt
                  (cps_inst_code, cps_pan_code, cps_mbr_numb, cps_prod_catg,
                   cps_spprt_key, cps_spprt_rsncode, cps_func_remark,
                   cps_ins_user, cps_lupd_user, cps_cmd_mode,
                   cps_pan_code_encr
                  )
           VALUES (prm_instcode,                                  --prm_acctno
                                v_hash_pan, v_mbrnumb, v_cap_prod_catg,
                   'TOP', v_resoncode, v_topupremrk,
                   prm_lupduser, prm_lupduser, 0,
                   v_encr_pan
                  );
   EXCEPTION
      WHEN OTHERS
      THEN
         v_errmsg :=
               'Error while inserting records into card support master'
            || SUBSTR (SQLERRM, 1, 200);
         v_respcode := '21';
         RAISE exp_main_reject_record;
   END;

   --En create a record in pan spprt

   ----------------------------------------------------------------------------------------------------------

   --Sn Last Day Process Call
   BEGIN
      --Sn Week end Process Call
      IF v_topup_freq_period = 'Week'
      THEN
         BEGIN
            SELECT NEXT_DAY (TRUNC (ctc_lupd_date), 'SUNDAY')
              INTO v_end_day_update
              FROM cms_topuptrans_count
             WHERE ctc_pan_code = v_hash_pan                      --PRM_ACCTNO
               AND ctc_inst_code = prm_instcode;
         EXCEPTION
            WHEN NO_DATA_FOUND
            THEN
               v_errmsg :=
                       'LAST UPDATE DATE(SUNDAY) IS UNDEFINED IN TOPUP TRANS';
               v_respcode := '21';
               RAISE exp_main_reject_record;
            WHEN OTHERS
            THEN
               v_errmsg :=
                     'ERROR WHILE SELECTING LAST UPDATE DATE(SUNDAY)'
                  || SUBSTR (SQLERRM, 1, 200);
               v_respcode := '21';
               RAISE exp_main_reject_record;
         END;

         IF TRUNC (SYSDATE) = (v_end_day_update) - 1
         THEN
            BEGIN
               UPDATE cms_topuptrans_count
                  SET ctc_totavail_days = 0,
                      ctc_lupd_date = SYSDATE
                WHERE ctc_pan_code = v_hash_pan
                  AND ctc_inst_code = prm_instcode;
            EXCEPTION
               WHEN OTHERS
               THEN
                  v_errmsg :=
                        'Error while updating cms_topuptrans_count1 '
                     || SUBSTR (SQLERRM, 1, 200);
                  v_respcode := '21';
                  RAISE exp_main_reject_record;
            END;
         END IF;

         BEGIN
            --------THINK ON THAT----------------
            SELECT TRUNC (ctc_lupd_date)
              INTO v_end_lupd_date
              FROM cms_topuptrans_count
             WHERE ctc_pan_code = v_hash_pan                      --PRM_ACCTNO
               AND ctc_inst_code = prm_instcode;
         EXCEPTION
            WHEN NO_DATA_FOUND
            THEN
               v_errmsg := 'LAST UPDATE DATE IS UNDEFINED IN TOPUP TRANS';
               v_respcode := '21';
               RAISE exp_main_reject_record;
            WHEN OTHERS
            THEN
               v_errmsg :=
                     'ERROR WHILE SELECTING LAST UPDATE DATE'
                  || SUBSTR (SQLERRM, 1, 200);
               v_respcode := '21';
               RAISE exp_main_reject_record;
         END;

         IF (TRUNC (SYSDATE) - TRUNC (v_end_lupd_date)) > 7
         THEN
            BEGIN
               UPDATE cms_topuptrans_count
                  SET ctc_totavail_days = 0,
                      ctc_lupd_date = SYSDATE
                WHERE ctc_pan_code = v_hash_pan
                  AND ctc_inst_code = prm_instcode;
            EXCEPTION
               WHEN OTHERS
               THEN
                  v_errmsg :=
                        'Error while updating cms_topuptrans_count2 '
                     || SUBSTR (SQLERRM, 1, 200);
                  v_respcode := '21';
                  RAISE exp_main_reject_record;
            END;
         END IF;
      END IF;

      --------THINK ON THAT----------------
      --Sn Month end Process Call
      IF v_topup_freq_period = 'Month'
      THEN
         BEGIN
            SELECT LAST_DAY (TRUNC (ctc_lupd_date))
              INTO v_end_day_update
              FROM cms_topuptrans_count
             WHERE ctc_pan_code = v_hash_pan                      --PRM_ACCTNO
               AND ctc_inst_code = prm_instcode;
         EXCEPTION
            WHEN NO_DATA_FOUND
            THEN
               v_errmsg :=
                     'LAST UPDATE DATE IS UNDEFINED IN TOPUP TRANS FOR MONTH';
               v_respcode := '21';
               RAISE exp_main_reject_record;
            WHEN OTHERS
            THEN
               v_errmsg :=
                     'ERROR WHILE SELECTING LAST UPDATE DATE FOR MONTH'
                  || SUBSTR (SQLERRM, 1, 200);
               v_respcode := '21';
               RAISE exp_main_reject_record;
         END;

         IF TRUNC (SYSDATE) = (v_end_day_update)
         THEN
            BEGIN
               UPDATE cms_topuptrans_count
                  SET ctc_totavail_days = 0,
                      ctc_lupd_date = SYSDATE
                WHERE ctc_pan_code = v_hash_pan
                  AND ctc_inst_code = prm_instcode;
            EXCEPTION
               WHEN OTHERS
               THEN
                  v_errmsg :=
                        'Error while updating cms_topuptrans_count3 '
                     || SUBSTR (SQLERRM, 1, 200);
                  v_respcode := '21';
                  RAISE exp_main_reject_record;
            END;
         END IF;
      END IF;

      --Sn Year end Process Call
      IF v_topup_freq_period = 'Year'
      THEN
         IF TRUNC (SYSDATE) = TO_DATE ('12/31/2009', 'MM/DD/YYYY')
         THEN
            BEGIN
               UPDATE cms_topuptrans_count
                  SET ctc_totavail_days = 0,
                      ctc_lupd_date = SYSDATE
                WHERE ctc_pan_code = v_hash_pan
                  AND ctc_inst_code = prm_instcode;
            EXCEPTION
               WHEN OTHERS
               THEN
                  v_errmsg :=
                        'Error while updating cms_topuptrans_count4 '
                     || SUBSTR (SQLERRM, 1, 200);
                  v_respcode := '21';
                  RAISE exp_main_reject_record;
            END;
         END IF;
      END IF;
   EXCEPTION
      WHEN OTHERS
      THEN
         v_errmsg :=
               'Error while Updating records into cms_topuptrans_count'
            || SUBSTR (SQLERRM, 1, 200);
         v_respcode := '21';
         RAISE exp_main_reject_record;
   END;

   -- Sn Transaction availdays Count update
   BEGIN
      UPDATE cms_topuptrans_count
         SET ctc_totavail_days = ctc_totavail_days + 1
       WHERE ctc_pan_code = v_hash_pan                            --PRM_ACCTNO
         AND ctc_inst_code = prm_instcode;
   EXCEPTION
      WHEN OTHERS
      THEN
         v_errmsg :=
               'Error while updating records in topuptrans'
            || SUBSTR (SQLERRM, 1, 200);
         v_respcode := '21';
         RAISE exp_main_reject_record;
   END;

   -- En Transaction availdays Count update

   --En Last Day Process Call
-------------------------------------------------------------------------------------------------------------
   v_respcode := 1;                         --Response code for successful txn

   --Sn select response code and insert record into txn log dtl
   BEGIN
      prm_errmsg := v_errmsg;
      prm_resp_code := v_respcode;

      -- Assign the response code to the out parameter
      SELECT cms_iso_respcde
        INTO prm_resp_code
        FROM cms_response_mast
       WHERE cms_inst_code = prm_instcode
         AND cms_delivery_channel = prm_delivery_channel
         AND cms_response_id = v_respcode;
   EXCEPTION
      WHEN NO_DATA_FOUND
      THEN
         prm_errmsg :=
                   'Data not available in response master for ' || v_respcode;
         --prm_resp_code := 'R20';
         prm_resp_code := 'R16';
         RAISE exp_main_reject_record;
      --ROLLBACK;
      WHEN OTHERS
      THEN
         prm_errmsg :=
               'Problem while selecting data from response master '
            || v_respcode
            || SUBSTR (SQLERRM, 1, 300);
         --prm_resp_code := 'R20';
         prm_resp_code := 'R16';
         RAISE exp_main_reject_record;
    ---ISO MESSAGE FOR DATABASE ERROR Server Declined
   -- ROLLBACK;
   END;

   --En select response code and insert record into txn log dtl

   ---Sn Updation of Usage limit and amount
--   BEGIN
--      SELECT ctc_mmposusage_amt, ctc_mmposusage_limit, ctc_business_date
--        INTO v_mmpos_usageamnt, v_mmpos_usagelimit, v_business_date_tran
--        FROM cms_translimit_check
--       WHERE ctc_inst_code = prm_instcode
--         AND ctc_pan_code = v_hash_pan                           --prm_card_no
--         AND ctc_mbr_numb = prm_mbr_numb;
--   EXCEPTION
--      WHEN NO_DATA_FOUND
--      THEN
--         v_errmsg :=
--               'Cannot get the Transaction Limit Details of the Card'
--            || SUBSTR (SQLERRM, 1, 300);
--         v_respcode := '21';
--         RAISE exp_main_reject_record;
--      WHEN OTHERS
--      THEN
--         v_errmsg :=
--               'Error while selecting cms_translimit_check '
--            || SUBSTR (SQLERRM, 1, 300);
--         v_respcode := '21';
--         RAISE exp_main_reject_record;
--   END;
/*
   BEGIN
      --Sn Usage limit and amount updation for MMPOS
      IF prm_delivery_channel = '04'
      THEN
         IF v_tran_date > v_business_date_tran
         THEN
            v_mmpos_usagelimit := 1;

            BEGIN
               UPDATE cms_translimit_check
                  SET ctc_mmposusage_amt = 0,
                      ctc_mmposusage_limit = v_mmpos_usagelimit,
                      ctc_atmusage_amt = 0,
                      ctc_atmusage_limit = 0,
                      ctc_business_date =
                         TO_DATE (prm_trandate || '23:59:59',
                                  'yymmdd' || 'hh24:mi:ss'
                                 ),
                      ctc_preauthusage_limit = 0,
                      ctc_posusage_amt = 0,
                      ctc_posusage_limit = 0
                WHERE ctc_inst_code = prm_instcode
                  AND ctc_pan_code = v_hash_pan
                  AND ctc_mbr_numb = prm_mbr_numb;
            EXCEPTION
               WHEN OTHERS
               THEN
                  v_errmsg :=
                        'Error while updating cms_translimit_check1 '
                     || SUBSTR (SQLERRM, 1, 200);
                  v_respcode := '21';
                  RAISE exp_main_reject_record;
            END;
         ELSE
            v_mmpos_usagelimit := v_mmpos_usagelimit + 1;

            BEGIN
               UPDATE cms_translimit_check
                  SET ctc_mmposusage_limit = v_mmpos_usagelimit
                WHERE ctc_inst_code = prm_instcode
                  AND ctc_pan_code = v_hash_pan
                  AND ctc_mbr_numb = prm_mbr_numb;
            EXCEPTION
               WHEN OTHERS
               THEN
                  v_errmsg :=
                        'Error while updating cms_translimit_check2 '
                     || SUBSTR (SQLERRM, 1, 200);
                  v_respcode := '21';
                  RAISE exp_main_reject_record;
            END;
         END IF;
      END IF;
   --En Usage limit and amount updation for MMPOS
   EXCEPTION
      WHEN OTHERS
      THEN
         v_errmsg :=
               'Error while updating records in CMS_TRANSLIMIT_CHECK'
            || SUBSTR (SQLERRM, 1, 200);
         v_respcode := '21';
         RAISE exp_main_reject_record;
   END;
*/
   --    BEGIN
   --       select count(*) into ACHFILECOUNT from  CMS_ACH_FILEPROCESS
   --       where CAF_ACH_FILE =PRM_ACHFILENAME and CAF_INST_CODE =PRM_INSTCODE;
   --       if ACHFILECOUNT > 0 then
   --          V_RESPCODE := '44';
   --          V_ERRMSG   := 'ACH FILE ALREADY processed' ;
   --       RAISE EXP_MAIN_REJECT_RECORD;
   --       end if;
   --
   --      end;
   --
   ---En Updation of Usage limit and amount

   --IF errmsg is OK then balance amount will be returned
   IF prm_errmsg = 'OK'
   THEN
      --Sn of Getting  the Acct Balannce
      BEGIN
         SELECT     cam_acct_bal, cam_ledger_bal
               INTO v_acct_balance, v_ledger_balance
               FROM cms_acct_mast
              WHERE cam_acct_no =
                       (SELECT cap_acct_no
                          FROM cms_appl_pan
                         WHERE cap_pan_code = v_hash_pan         --prm_card_no
                           AND cap_mbr_numb = prm_mbr_numb
                           AND cap_inst_code = prm_instcode)
                AND cam_inst_code = prm_instcode;
          --FOR UPDATE NOWAIT;                -- Commented for Concurrent Processsing Issue

         prm_endledgerbal := v_ledger_balance;
         prm_endaccountbalance := v_acct_balance;
      EXCEPTION
         WHEN NO_DATA_FOUND
         THEN
            v_respcode := '14';                      --Ineligible Transaction
            v_errmsg := 'Invalid Card ';
            RAISE exp_main_reject_record;
         WHEN OTHERS
         THEN
            v_respcode := '12';
            v_errmsg :=
                  'Error while selecting data from card Master for card number '
               || v_hash_pan;
            RAISE exp_main_reject_record;
      END;
    --prm_endledgerbal := v_ledger_balance;
   -- prm_endaccountbalance := v_acct_balance;
    --En of Getting  the Acct Balannce
   -- prm_errmsg := TO_CHAR (v_acct_balance);
   END IF;

   BEGIN
      SELECT COUNT (*)
        INTO file_count
        FROM cms_ach_fileprocess
       WHERE caf_ach_file = prm_achfilename AND caf_inst_code = prm_instcode;

      IF file_count = 0
      THEN
         INSERT INTO cms_ach_fileprocess
                     (caf_inst_code, caf_ach_file, caf_tran_date,
                      caf_lupd_user, caf_ins_user
                     )
              VALUES (prm_instcode, prm_achfilename, prm_trandate,
                      prm_lupduser, prm_lupduser
                     );
      END IF;
   EXCEPTION
      WHEN OTHERS
      THEN
         v_errmsg :=
               'Error while inserting records into ACH File Processing table    '
            || SUBSTR (SQLERRM, 1, 200);
         v_respcode := '21';
         RAISE exp_main_reject_record;
   END;

   BEGIN
   --Added for VMS-5739/FSP-991
	 select (add_months(trunc(sysdate,'MM'),'-'||RETENTION_PERIOD))
		   INTO   v_Retperiod 
		   FROM DBA_OPERATIONS.ARCHIVE_MGMNT_CTL 
		   WHERE  OPERATION_TYPE='ARCHIVE' 
		   AND OBJECT_NAME='TRANSACTIONLOG_EBR';
		   
		   v_Retdate := TO_DATE(SUBSTR(TRIM(prm_trandate), 1, 8), 'yyyymmdd');


	IF (v_Retdate>v_Retperiod)

		THEN
		  UPDATE transactionlog
			 SET csr_achactiontaken = 'A',
				 reason = prm_reason_desc,
				 remark = prm_remark,
				 response_code = prm_resp_code    -- added by sagar on 01-MAR-2012
				 ,gl_eod_flag=prm_reason_code,
				 txn_status='C',
				 error_msg='OK'
		   WHERE rrn = prm_rrn
			 AND business_date = prm_trandate
			 AND txn_code = prm_txn_code
			 AND instcode = prm_instcode
			 --AND business_date = prm_trandate
			 AND business_time = prm_trantime
			 AND customer_card_no_encr = v_encr_pan;
	ELSE	
			UPDATE VMSCMS_HISTORY.TRANSACTIONLOG_HIST --Added for VMS-5733/FSP-991
			 SET csr_achactiontaken = 'A',
				 reason = prm_reason_desc,
				 remark = prm_remark,
				 response_code = prm_resp_code    -- added by sagar on 01-MAR-2012
				 ,gl_eod_flag=prm_reason_code,
				 txn_status='C',
				 error_msg='OK'
		   WHERE rrn = prm_rrn
			 AND business_date = prm_trandate
			 AND txn_code = prm_txn_code
			 AND instcode = prm_instcode
			 --AND business_date = prm_trandate
			 AND business_time = prm_trantime
			 AND customer_card_no_encr = v_encr_pan;
	END IF;		 

      IF SQL%ROWCOUNT = 0
      THEN
         v_errmsg :=
               'Error while Updating CSR action taken flag'
            || SUBSTR (SQLERRM, 1, 200);
         v_respcode := '21';
         RAISE exp_main_reject_record;
      END IF;
   END;
EXCEPTION
   --<< MAIN EXCEPTION >>
   WHEN exp_auth_reject_record
   THEN
      ROLLBACK;
/*
      ---Sn Updation of Usage limit and amount
      BEGIN
         SELECT ctc_mmposusage_amt, ctc_mmposusage_limit, ctc_business_date
           INTO v_mmpos_usageamnt, v_mmpos_usagelimit, v_business_date_tran
           FROM cms_translimit_check
          WHERE ctc_inst_code = prm_instcode
            AND ctc_pan_code = v_hash_pan                        --prm_card_no
            AND ctc_mbr_numb = prm_mbr_numb;
      EXCEPTION
         WHEN NO_DATA_FOUND
         THEN
            v_errmsg :=
                  'Cannot get the Transaction Limit Details of the Card'
               || SUBSTR (SQLERRM, 1, 300);
            v_respcode := '21';
            RAISE exp_main_reject_record;
         WHEN OTHERS
         THEN
            v_errmsg :=
                  'Error while selecting cms_translimit_check '
               || SUBSTR (SQLERRM, 1, 300);
            v_respcode := '21';
            RAISE exp_main_reject_record;
      END;

      BEGIN
         --Sn Usage limit and amount updation for MMPOS
         IF prm_delivery_channel = '04'
         THEN
            IF v_tran_date > v_business_date_tran
            THEN
               v_mmpos_usagelimit := 1;

               BEGIN
                  UPDATE cms_translimit_check
                     SET ctc_mmposusage_amt = 0,
                         ctc_mmposusage_limit = v_mmpos_usagelimit,
                         ctc_atmusage_amt = 0,
                         ctc_atmusage_limit = 0,
                         ctc_business_date =
                            TO_DATE (prm_trandate || '23:59:59',
                                     'yymmdd' || 'hh24:mi:ss'
                                    ),
                         ctc_preauthusage_limit = 0,
                         ctc_posusage_amt = 0,
                         ctc_posusage_limit = 0
                   WHERE ctc_inst_code = prm_instcode
                     AND ctc_pan_code = v_hash_pan
                     AND ctc_mbr_numb = prm_mbr_numb;
               EXCEPTION
                  WHEN OTHERS
                  THEN
                     v_errmsg :=
                           'Error while updating cms_translimit_check3 '
                        || SUBSTR (SQLERRM, 1, 200);
                     v_respcode := '21';
                     RAISE exp_main_reject_record;
               END;
            ELSE
               v_mmpos_usagelimit := v_mmpos_usagelimit + 1;

               BEGIN
                  UPDATE cms_translimit_check
                     SET ctc_mmposusage_limit = v_mmpos_usagelimit
                   WHERE ctc_inst_code = prm_instcode
                     AND ctc_pan_code = v_hash_pan
                     AND ctc_mbr_numb = prm_mbr_numb;
               EXCEPTION
                  WHEN OTHERS
                  THEN
                     v_errmsg :=
                           'Error while updating cms_translimit_check4 '
                        || SUBSTR (SQLERRM, 1, 200);
                     v_respcode := '21';
                     RAISE exp_main_reject_record;
               END;
            END IF;
         END IF;
      --En Usage limit and amount updation for MMPOS
      EXCEPTION
         WHEN OTHERS
         THEN
            v_errmsg :=
                  'Error while updating records in TRANSLIMIT CHECK'
               || SUBSTR (SQLERRM, 1, 200);
            v_respcode := '21';
            RAISE exp_main_reject_record;
      END;
*/
      prm_errmsg := v_errmsg;
      prm_resp_code := v_respcode;

      BEGIN
         SELECT COUNT (*)
           INTO file_count
           FROM cms_ach_fileprocess
          WHERE caf_ach_file = prm_achfilename
                AND caf_inst_code = prm_instcode;

         IF file_count = 0
         THEN
            INSERT INTO cms_ach_fileprocess
                        (caf_inst_code, caf_ach_file, caf_tran_date,
                         caf_lupd_user, caf_ins_user
                        )
                 VALUES (prm_instcode, prm_achfilename, prm_trandate,
                         prm_lupduser, prm_lupduser
                        );
         END IF;
      EXCEPTION
         WHEN OTHERS
         THEN
            v_errmsg :=
                  'Error while inserting records into ACH File Processing table    '
               || SUBSTR (SQLERRM, 1, 200);
            v_respcode := '21';
            RAISE exp_main_reject_record;
      END;

      prm_errmsg := v_errmsg;
      prm_resp_code := v_respcode;

      -- Assign the response code to the out parameter
      IF prm_processtype <> 'N'
      THEN
         --Sn create a entry in txn log
         BEGIN
            INSERT INTO transactionlog
                        (msgtype, rrn, delivery_channel,
                         terminal_id, date_time, txn_code,
                         txn_type, txn_mode,
                         txn_status,
                         response_code, business_date,
                         business_time, customer_card_no, topup_card_no,
                         topup_acct_no, topup_acct_type, bank_code,
                         total_amount,
                         currencycode, addcharge, productid, categoryid,
                         atm_name_location, auth_id,
                         amount,
                         preauthamount, partialamount, instcode,
                         customer_card_no_encr, topup_card_no_encr,
                         proxy_number, reversal_code, customer_acct_no,
                         acct_balance, ledger_balance, achfilename,
                         rdfi, seccodes, impdate,
                         processdate, effectivedate,
                         tracenumber, incoming_crfileid,
                         achtrantype_id, indidnum, indname,
                         companyname, companyid, ach_id,
                         compentrydesc, response_id, customerlastname,
                         cardstatus, processtype, trans_desc
                        )
                 VALUES (prm_msg, prm_rrn, prm_delivery_channel,
                         prm_terminalid, v_business_date, prm_txn_code,
                         v_txn_type, prm_txn_mode,
                         DECODE (prm_resp_code, '00', 'C', 'F'),
                         prm_resp_code, prm_trandate,
                         SUBSTR (prm_trantime, 1, 10), v_hash_pan, NULL,
                         NULL, NULL, prm_instcode,
                         TRIM (TO_CHAR (v_tran_amt, '999999999999999990.99')),
                         prm_currcode, NULL, v_prod_code, v_card_type,
                         prm_terminalid, v_auth_id,
                         TRIM (TO_CHAR (v_tran_amt, '999999999999999990.99')),
                         NULL, NULL, prm_instcode,
                         v_encr_pan, v_encr_pan,
                         v_proxunumber, prm_rvsl_code,
                                                      -- V_ACCT_NUMBER,
                                                      prm_cust_acct_no,
                         v_acct_balance, v_ledger_balance, prm_achfilename,
                         prm_rdfi, prm_seccode, prm_impdate,
                         prm_processdate, prm_effectivedate,
                         prm_tracenumber, prm_incoming_crfileid,
                         prm_achtrantype_id, prm_indidnum, prm_indname,
                         prm_companyname, prm_companyid, prm_id,
                         prm_compentrydesc, v_respcode, custlastname,
                         v_cap_card_stat, prm_processtype, v_trans_desc
                        );
         EXCEPTION
            WHEN OTHERS
            THEN
               prm_resp_code := '89';
               prm_errmsg :=
                     'Problem while inserting data into transaction log  dtl'
                  || SUBSTR (SQLERRM, 1, 300);
         END;
      END IF;

      IF prm_processtype = 'N'
      THEN
         BEGIN
		 --Added for VMS-5739/FSP-991
	 select (add_months(trunc(sysdate,'MM'),'-'||RETENTION_PERIOD))
		   INTO   v_Retperiod 
		   FROM DBA_OPERATIONS.ARCHIVE_MGMNT_CTL 
		   WHERE  OPERATION_TYPE='ARCHIVE' 
		   AND OBJECT_NAME='TRANSACTIONLOG_EBR';
		   
		   v_Retdate := TO_DATE(SUBSTR(TRIM(prm_trandate), 1, 8), 'yyyymmdd');


	IF (v_Retdate>v_Retperiod)

		THEN
				UPDATE transactionlog
				   SET processtype = prm_processtype,
					   response_code = prm_resp_code,
					   --auth_id = prm_auth_id,    --commented by sagar on 01-MAR-2012
					   csr_achactiontaken = 'A',
								 --changed from 'R' to 'A' by sagar on 01-MAR-2012
					   reason = prm_reason_desc,
					   remark = prm_remark
						,gl_eod_flag=prm_reason_code
				 WHERE rrn = prm_rrn
				   AND business_time = prm_trantime
				   AND business_date = prm_trandate
				   AND customer_card_no_encr = v_encr_pan
				   AND txn_code = prm_txn_code
				   AND instcode = prm_instcode;
	ELSE
				UPDATE VMSCMS_HISTORY.TRANSACTIONLOG_HIST --Added for VMS-5733/FSP-991
				   SET processtype = prm_processtype,
					   response_code = prm_resp_code,
					   --auth_id = prm_auth_id,    --commented by sagar on 01-MAR-2012
					   csr_achactiontaken = 'A',
								 --changed from 'R' to 'A' by sagar on 01-MAR-2012
					   reason = prm_reason_desc,
					   remark = prm_remark
						,gl_eod_flag=prm_reason_code
				 WHERE rrn = prm_rrn
				   AND business_time = prm_trantime
				   AND business_date = prm_trandate
				   AND customer_card_no_encr = v_encr_pan
				   AND txn_code = prm_txn_code
				   AND instcode = prm_instcode;
	END IF;
			   
         EXCEPTION
            WHEN OTHERS
            THEN
               v_errmsg :=
                     'Error while UPDATING  records into TRANSACTION LOG FOR PRCSTYPE N    '
                  || SUBSTR (SQLERRM, 1, 200);
               v_respcode := '21';
               RAISE exp_main_reject_record;
         END;
      END IF;

      --En create a entry in txn log
      BEGIN
         INSERT INTO cms_transaction_log_dtl
                     (ctd_delivery_channel, ctd_txn_code, ctd_msg_type,
                      ctd_txn_mode, ctd_business_date, ctd_business_time,
                      ctd_customer_card_no, ctd_txn_amount, ctd_txn_curr,
                      ctd_actual_amount, ctd_fee_amount, ctd_waiver_amount,
                      ctd_servicetax_amount, ctd_cess_amount,
                      ctd_bill_amount, ctd_bill_curr, ctd_process_flag,
                      ctd_process_msg, ctd_rrn, ctd_inst_code,
                      ctd_customer_card_no_encr, ctd_cust_acct_number
                     )
              VALUES (prm_delivery_channel, prm_txn_code, prm_msg,
                      prm_txn_mode, prm_trandate, prm_trantime,
                      --prm_card_no
                      v_hash_pan, prm_amount, prm_currcode,
                      prm_amount, NULL, NULL,
                      NULL, NULL,
                      NULL, NULL, 'E',
                      prm_errmsg, prm_rrn, prm_instcode,
                      v_encr_pan,
                                 --V_ACCT_NUMBER
                                 prm_cust_acct_no
                     );

         prm_errmsg := v_errmsg;
         RETURN;
      EXCEPTION
         WHEN OTHERS
         THEN
            v_errmsg :=
                  'Problem while inserting data into transaction log  dtl'
               || SUBSTR (SQLERRM, 1, 300);
            prm_resp_code := '22';                          -- Server Declined
            prm_errmsg := v_errmsg;                 --added by DMG on 28022012
            ROLLBACK;
            RETURN;
      END;

      prm_errmsg := v_errmsg;
   WHEN exp_main_reject_record
   THEN
      ROLLBACK;

      BEGIN
         SELECT cam_acct_bal, cam_ledger_bal
           INTO v_acct_balance, v_ledger_balance
           FROM cms_acct_mast
          WHERE cam_acct_no =
                   (SELECT cap_acct_no
                      FROM cms_appl_pan
                     WHERE cap_pan_code = v_hash_pan
                       AND cap_inst_code = prm_instcode)
            AND cam_inst_code = prm_instcode;
      EXCEPTION
         WHEN NO_DATA_FOUND
         THEN
            v_acct_balance := 0;
            v_ledger_balance := 0;
         WHEN OTHERS
         THEN
            v_acct_balance := 0;
            v_ledger_balance := 0;
      END;

 /*     ---Sn Updation of Usage limit and amount
      BEGIN
         SELECT ctc_mmposusage_amt, ctc_mmposusage_limit, ctc_business_date
           INTO v_mmpos_usageamnt, v_mmpos_usagelimit, v_business_date_tran
           FROM cms_translimit_check
          WHERE ctc_inst_code = prm_instcode
            AND ctc_pan_code = v_hash_pan                        --prm_card_no
            AND ctc_mbr_numb = prm_mbr_numb;
      EXCEPTION
         WHEN NO_DATA_FOUND
         THEN
            v_errmsg :=
                  'Cannot get the Transaction Limit Details of the Card'
               || SUBSTR (SQLERRM, 1, 300);
            v_respcode := '21';
         WHEN OTHERS
         THEN
            v_errmsg :=
                  'Error while selecting the Transaction Limit details of the Card'
               || SUBSTR (SQLERRM, 1, 300);
            v_respcode := '21';
--       RAISE EXP_MAIN_REJECT_RECORD;
      END;

      BEGIN
         --Sn Usage limit and amount updation for MMPOS
         IF prm_delivery_channel = '04'
         THEN
            IF v_tran_date > v_business_date_tran
            THEN
               v_mmpos_usagelimit := 1;

               BEGIN
                  UPDATE cms_translimit_check
                     SET ctc_mmposusage_amt = 0,
                         ctc_mmposusage_limit = v_mmpos_usagelimit,
                         ctc_atmusage_amt = 0,
                         ctc_atmusage_limit = 0,
                         ctc_business_date =
                            TO_DATE (prm_trandate || '23:59:59',
                                     'yymmdd' || 'hh24:mi:ss'
                                    ),
                         ctc_preauthusage_limit = 0,
                         ctc_posusage_amt = 0,
                         ctc_posusage_limit = 0
                   WHERE ctc_inst_code = prm_instcode
                     AND ctc_pan_code = v_hash_pan
                     AND ctc_mbr_numb = prm_mbr_numb;
               EXCEPTION
                  WHEN OTHERS
                  THEN
                     v_errmsg :=
                           'Error while updating cms_translimit_check5 '
                        || SUBSTR (SQLERRM, 1, 200);
                     v_respcode := '21';
                     RAISE exp_main_reject_record;
               END;
            ELSE
               v_mmpos_usagelimit := v_mmpos_usagelimit + 1;

               BEGIN
                  UPDATE cms_translimit_check
                     SET ctc_mmposusage_limit = v_mmpos_usagelimit
                   WHERE ctc_inst_code = prm_instcode
                     AND ctc_pan_code = v_hash_pan
                     AND ctc_mbr_numb = prm_mbr_numb;
               EXCEPTION
                  WHEN OTHERS
                  THEN
                     v_errmsg :=
                           'Error while updating cms_translimit_check6 '
                        || SUBSTR (SQLERRM, 1, 200);
                     v_respcode := '21';
                     RAISE exp_main_reject_record;
               END;
            END IF;
         END IF;
      --En Usage limit and amount updation for MMPOS
      EXCEPTION
         WHEN OTHERS
         THEN
            v_errmsg :=
                  'Error while updating records in TRANSLIMIT'
               || SUBSTR (SQLERRM, 1, 200);
            v_respcode := '21';
            RAISE exp_main_reject_record;
      END;
      */

      BEGIN
         prm_errmsg := v_errmsg;
         prm_resp_code := v_respcode;

         -- Assign the response code to the out parameter
         SELECT cms_iso_respcde
           INTO prm_resp_code
           FROM cms_response_mast
          WHERE cms_inst_code = prm_instcode
            AND cms_delivery_channel = prm_delivery_channel
            AND cms_response_id = v_respcode;
      EXCEPTION
         WHEN NO_DATA_FOUND
         THEN
            prm_errmsg :=
               'Response code not available in response master '
               || v_respcode;
           -- prm_resp_code := 'R20';
            prm_resp_code := 'R16';
            ---ISO MESSAGE FOR DATABASE ERROR Server Declined
            ROLLBACK;
         WHEN OTHERS
         THEN
            prm_errmsg :=
                  'Problem while selecting data from response master '
               || v_respcode
               || SUBSTR (SQLERRM, 1, 300);
            --prm_resp_code := 'R20';
            prm_resp_code := 'R16';
            ---ISO MESSAGE FOR DATABASE ERROR Server Declined
            ROLLBACK;
      -- RETURN;
      END;

      v_respcode_org_txn := prm_resp_code;

      BEGIN
         SELECT COUNT (*)
           INTO file_count
           FROM cms_ach_fileprocess
          WHERE caf_ach_file = prm_achfilename
                AND caf_inst_code = prm_instcode;

         IF file_count = 0
         THEN
            INSERT INTO cms_ach_fileprocess
                        (caf_inst_code, caf_ach_file, caf_tran_date,
                         caf_lupd_user, caf_ins_user
                        )
                 VALUES (prm_instcode, prm_achfilename, prm_trandate,
                         prm_lupduser, prm_lupduser
                        );
         END IF;
      EXCEPTION
         WHEN OTHERS
         THEN
            v_errmsg :=
                  'Error while inserting records into ACH File Processing table    '
               || SUBSTR (SQLERRM, 1, 200);
            v_respcode := '21';
            RAISE exp_main_reject_record;
      END;

      BEGIN
         IF v_rrn_count > 0
         THEN
            IF TO_NUMBER (prm_delivery_channel) = 11
            THEN
               BEGIN
                  SELECT                                     --response_code,
                         acct_balance, ledger_balance,
                         auth_id, befretran_ledgerbal,
                         befretran_availbalance
                    INTO                                         --v_respcode,
                         prm_endaccountbalance, prm_endledgerbal,
                         prm_auth_id, prm_startledgerbal,
                         prm_startaccountbalance
                    FROM VMSCMS.TRANSACTIONLOG a,			 --Added for VMS-5733/FSP-991
                         (SELECT MIN (add_ins_date) mindate
                            FROM VMSCMS.TRANSACTIONLOG			 --Added for VMS-5733/FSP-991
                           WHERE rrn = prm_rrn) b
                   WHERE a.add_ins_date = mindate AND rrn = prm_rrn;
               --prm_resp_code := v_respcode;
			   IF SQL%ROWCOUNT = 0 THEN 
			    SELECT                                     --response_code,
                         acct_balance, ledger_balance,
                         auth_id, befretran_ledgerbal,
                         befretran_availbalance
                    INTO                                         --v_respcode,
                         prm_endaccountbalance, prm_endledgerbal,
                         prm_auth_id, prm_startledgerbal,
                         prm_startaccountbalance
                    FROM VMSCMS_HISTORY.TRANSACTIONLOG_HIST a,			 --Added for VMS-5733/FSP-991
                         (SELECT MIN (add_ins_date) mindate
                            FROM VMSCMS_HISTORY.TRANSACTIONLOG_HIST			 --Added for VMS-5733/FSP-991
                           WHERE rrn = prm_rrn) b
                   WHERE a.add_ins_date = mindate AND rrn = prm_rrn;
			   END IF;
               EXCEPTION
                  WHEN OTHERS
                  THEN
                     v_errmsg :=
                           'Problem in selecting the response detail of Original transaction'
                        || SUBSTR (SQLERRM, 1, 300);
                     prm_resp_code := '89';                 -- Server Declined
                     ROLLBACK;
                     RETURN;
               END;
            END IF;
         END IF;
      EXCEPTION
         WHEN OTHERS
         THEN
            v_errmsg :=
                  'Problem in delivery channel conversion'
               || SUBSTR (SQLERRM, 1, 300);
            prm_resp_code := '89';                          -- Server Declined
            ROLLBACK;
            RETURN;
      END;

      --Sn create a entry in txn log
      IF v_respcode NOT IN ('45', '32')
      THEN
         --Added by Deepa on Apr-23-2012 not to log the Invalid transaction Date and Time
         IF prm_processtype <> 'N'
         THEN
            BEGIN
               INSERT INTO transactionlog
                           (msgtype, rrn, delivery_channel,
                            terminal_id, date_time, txn_code,
                            txn_type, txn_mode,
                            txn_status,
                            response_code, business_date,
                            business_time, customer_card_no, topup_card_no,
                            topup_acct_no, topup_acct_type, bank_code,
                            total_amount,
                            currencycode, addcharge, productid, categoryid,
                            atm_name_location, auth_id,
                            amount,
                            preauthamount, partialamount, instcode,
                            customer_card_no_encr, topup_card_no_encr,
                            proxy_number, reversal_code, customer_acct_no,
                            acct_balance, ledger_balance,
                            achfilename, rdfi, seccodes,
                            impdate, processdate, effectivedate,
                            tracenumber, incoming_crfileid,
                            achtrantype_id, indidnum, indname,
                            companyname, companyid, ach_id,
                            compentrydesc, response_id, customerlastname,
                            cardstatus, processtype, trans_desc
                           )
                    VALUES (prm_msg, prm_rrn, prm_delivery_channel,
                            prm_terminalid, v_business_date, prm_txn_code,
                            v_txn_type, prm_txn_mode,
                            DECODE (v_respcode_org_txn, '00', 'C', 'F'),
                            v_respcode_org_txn, prm_trandate,
                            SUBSTR (prm_trantime, 1, 10), v_hash_pan, NULL,
                            NULL, NULL, prm_instcode,
                            TRIM (TO_CHAR (v_tran_amt,
                                           '999999999999999990.99')
                                 ),
                            prm_currcode, NULL, v_prod_code, v_card_type,
                            prm_terminalid, v_auth_id,
                            TRIM (TO_CHAR (v_tran_amt, '99999999999999990.99')),
                            NULL, NULL, prm_instcode,
                            v_encr_pan, v_encr_pan,
                            v_proxunumber, prm_rvsl_code,
                                                         -- V_ACCT_NUMBER,
                                                         prm_cust_acct_no,
                            v_acct_balance, v_ledger_balance,
                            prm_achfilename, prm_rdfi, prm_seccode,
                            prm_impdate, prm_processdate, prm_effectivedate,
                            prm_tracenumber, prm_incoming_crfileid,
                            prm_achtrantype_id, prm_indidnum, prm_indname,
                            prm_companyname, prm_companyid, prm_id,
                            prm_compentrydesc, v_respcode, custlastname,
                            v_cap_card_stat, prm_processtype, v_trans_desc
                           );
            EXCEPTION
               WHEN OTHERS
               THEN
                  prm_resp_code := '89';
                  prm_errmsg :=
                        'Problem while inserting data into transaction log  dtl'
                     || SUBSTR (SQLERRM, 1, 300);
            END;
         END IF;

         IF prm_processtype = 'N'
         THEN
            BEGIN
			
				--Added for VMS-5739/FSP-991
	 select (add_months(trunc(sysdate,'MM'),'-'||RETENTION_PERIOD))
		   INTO   v_Retperiod 
		   FROM DBA_OPERATIONS.ARCHIVE_MGMNT_CTL 
		   WHERE  OPERATION_TYPE='ARCHIVE' 
		   AND OBJECT_NAME='TRANSACTIONLOG_EBR';
		   
		   v_Retdate := TO_DATE(SUBSTR(TRIM(PRM_TRANDATE), 1, 8), 'yyyymmdd');


	IF (v_Retdate>v_Retperiod)

		THEN
				   UPDATE transactionlog
					  SET processtype = prm_processtype,
						  response_code = prm_resp_code,
						  csr_achactiontaken = 'A',
									 --changed from R to A on 01-mar-2012 by sagar
						  reason = prm_reason_desc,
						  remark = prm_remark
						   ,gl_eod_flag=prm_reason_code
					WHERE rrn = prm_rrn
					  and BUSINESS_DATE = PRM_TRANDATE
					  --AND business_date = prm_trandate
					  AND business_time = prm_trantime
					  AND customer_card_no_encr = v_encr_pan
					  AND txn_code = prm_txn_code
					  AND instcode = prm_instcode;
	ELSE
					UPDATE VMSCMS_HISTORY.TRANSACTIONLOG_HIST --Added for VMS-5733/FSP-991
					  SET processtype = prm_processtype,
						  response_code = prm_resp_code,
						  csr_achactiontaken = 'A',
									 --changed from R to A on 01-mar-2012 by sagar
						  reason = prm_reason_desc,
						  remark = prm_remark
						   ,gl_eod_flag=prm_reason_code
					WHERE rrn = prm_rrn
					  and BUSINESS_DATE = PRM_TRANDATE
					  --AND business_date = prm_trandate
					  AND business_time = prm_trantime
					  AND customer_card_no_encr = v_encr_pan
					  AND txn_code = prm_txn_code
					  AND instcode = prm_instcode;
	END IF;				  
            EXCEPTION
               WHEN OTHERS
               THEN
                  v_errmsg :=
                        'Problem while  updating data into transaction log'
                     || SUBSTR (SQLERRM, 1, 300);
                  prm_resp_code := '21';
                  ROLLBACK;
                  RETURN;
            END;
         END IF;
      END IF;

      --En create a entry in txn log

      --Sn create a entry in cms_transaction_log_dtl
      BEGIN
         INSERT INTO cms_transaction_log_dtl
                     (ctd_delivery_channel, ctd_txn_code, ctd_msg_type,
                      ctd_txn_mode, ctd_business_date, ctd_business_time,
                      ctd_customer_card_no, ctd_txn_amount, ctd_txn_curr,
                      ctd_actual_amount, ctd_fee_amount, ctd_waiver_amount,
                      ctd_servicetax_amount, ctd_cess_amount,
                      ctd_bill_amount, ctd_bill_curr, ctd_process_flag,
                      ctd_process_msg, ctd_rrn, ctd_inst_code,
                      ctd_customer_card_no_encr, ctd_cust_acct_number
                     )
              VALUES (prm_delivery_channel, prm_txn_code, prm_msg,
                      prm_txn_mode, prm_trandate, prm_trantime,
                      --prm_card_no
                      v_hash_pan, prm_amount, prm_currcode,
                      prm_amount, NULL, NULL,
                      NULL, NULL,
                      NULL, NULL, 'E',
                      prm_errmsg, prm_rrn, prm_instcode,
                      v_encr_pan,
                                 --V_ACCT_NUMBER
                                 prm_cust_acct_no
                     );

         prm_errmsg := v_errmsg;
         RETURN;
      EXCEPTION
         WHEN OTHERS
         THEN
            v_errmsg :=
                  'Problem while inserting data into transaction log  dtl'
               || SUBSTR (SQLERRM, 1, 300);
            prm_resp_code := '89';                          -- Server Declined
            ROLLBACK;
            RETURN;
      END;

      prm_errmsg := v_errmsg;
   WHEN OTHERS
   THEN
      prm_errmsg := ' Error from main ' || SUBSTR (SQLERRM, 1, 200);
END;
/
show error;