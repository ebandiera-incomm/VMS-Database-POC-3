create or replace PROCEDURE        vmscms.SP_OPTIN_OPTOUT_STATUS (
   p_inst_code          IN       NUMBER,
   p_rrn                IN       VARCHAR2,
   p_txn_code           IN       VARCHAR2,
   p_delivery_channel   IN       VARCHAR2,
   p_msg_type           IN       VARCHAR2,
   p_rvsl_code          IN       VARCHAR2,
   p_txn_mode           IN       VARCHAR2, 
   p_tran_date          IN       VARCHAR2,
   p_tran_time          IN       VARCHAR2,
   p_pan_code           IN       VARCHAR2,
   p_mbr_numb           IN       VARCHAR2,
   p_curr_code          IN       VARCHAR2,
   p_ani                IN       VARCHAR2,
   p_dni                IN       VARCHAR2,
   p_ipaddress          IN       VARCHAR2,
   p_mobil_no           IN       VARCHAR2,
   p_device_id          IN       VARCHAR2,
   p_user_name          IN       VARCHAR2,
   p_optin_list         IN       VARCHAR2,
  -- p_optin              IN       VARCHAR2,--Commented for FWR-69 change in requirement
   p_resp_code          OUT      VARCHAR2,
   p_res_msg            OUT      VARCHAR2,
   p_saving_acct_info   OUT      VARCHAR2,
   p_tandc_version      OUT      VARCHAR2,
   p_tandc_flag         OUT      VARCHAR2
)
AS
   v_auth_savepoint           NUMBER                                DEFAULT 0;
   v_err_msg                  VARCHAR2 (500);
   v_hash_pan                 cms_appl_pan.cap_pan_code%TYPE;
   v_encr_pan                 cms_appl_pan.cap_pan_code_encr%TYPE;
   v_txn_type                 transactionlog.txn_type%TYPE;
   v_auth_id                  transactionlog.auth_id%TYPE;
   exp_reject_record          EXCEPTION;
   v_dr_cr_flag               VARCHAR2 (2);
   v_tran_type                VARCHAR2 (2);
   v_tran_amt                 NUMBER;
   v_prod_code                cms_appl_pan.cap_prod_code%TYPE;
   v_card_type                cms_appl_pan.cap_card_type%TYPE;
   v_resp_cde                 VARCHAR2 (5);
   v_time_stamp               TIMESTAMP;
   v_hashkey_id               cms_transaction_log_dtl.ctd_hashkey_id%TYPE;
   v_trans_desc               cms_transaction_mast.ctm_tran_desc%TYPE;
   v_prfl_flag                cms_transaction_mast.ctm_prfl_flag%TYPE;
   v_acct_number              cms_appl_pan.cap_acct_no%TYPE;
   v_prfl_code                cms_appl_pan.cap_prfl_code%TYPE;
   v_card_stat                cms_appl_pan.cap_card_stat%TYPE;
   v_preauth_flag             cms_transaction_mast.ctm_preauth_flag%TYPE;
   v_acct_bal                 cms_acct_mast.cam_acct_bal%TYPE;
   v_ledger_bal               cms_acct_mast.cam_ledger_bal%TYPE;
   v_acct_type                cms_acct_mast.cam_type_code%TYPE;
   v_proxy_number             cms_appl_pan.cap_proxy_number%TYPE;
   v_fee_code                 transactionlog.feecode%TYPE;
   v_fee_plan                 transactionlog.fee_plan%TYPE;
   v_feeattach_type           transactionlog.feeattachtype%TYPE;
   v_tranfee_amt              transactionlog.tranfee_amt%TYPE;
   v_total_amt                transactionlog.total_amount%TYPE;
   v_expry_date               cms_appl_pan.cap_expry_date%TYPE;
   v_comb_hash                pkg_limits_check.type_hash;
   v_login_txn                cms_transaction_mast.ctm_login_txn%TYPE;
   v_logdtl_resp              VARCHAR2 (500);
   v_sms_optinflag            cms_optin_status.cos_sms_optinflag%TYPE;
   v_email_optinflag          cms_optin_status.cos_email_optinflag%TYPE;
   v_markmsg_optinflag        cms_optin_status.cos_markmsg_optinflag%TYPE;
   v_gpresign_optinflag       cms_optin_status.cos_gpresign_optinflag%TYPE;
   v_savingsesign_optinflag   cms_optin_status.cos_savingsesign_optinflag%TYPE;
   v_rrn_count                NUMBER;
   v_count                    NUMBER;
   v_cust_id                  cms_cust_mast.ccm_cust_id%TYPE;
   v_optin_type               cms_optin_status.cos_sms_optinflag%TYPE; --Added for FWR-69 change in requirement
   v_optin                    cms_optin_status.cos_sms_optinflag%TYPE; --Added for FWR-69 change in requirement
   v_optin_list               VARCHAR2(1000); --Added for FWR-69 change in requirement
   v_comma_pos                NUMBER; --Added for FWR-69 change in requirement
   v_comma_pos1               NUMBER; --Added for FWR-69 change in requirement
   i                          NUMBER:=1; --Added for FWR-69 change in requirement
   v_tandc_version            CMS_PROD_CATTYPE.CPC_TANDC_VERSION%TYPE;
   v_ccm_tandc_version        cms_cust_mast.ccm_tandc_version%TYPE;
   v_saving_type_code         VARCHAR2(1) DEFAULT '2';
   v_saving_acct_dtl          VARCHAR2(40);
   v_cust_code                cms_cust_mast.ccm_cust_code%TYPE;
   v_min_tran_amt             cms_dfg_param.cdp_param_value%TYPE;
   v_savings_statcode         cms_acct_mast.cam_stat_code%TYPE;
      v_compl_fee varchar2(10);
   v_compl_feetxn_excd varchar2(10);
   v_compl_feecode varchar2(10);
   v_Retperiod  date;  --Added for VMS-5735/FSP-991
   v_Retdate  date; --Added for VMS-5735/FSP-991
   /**********************************************************************************************
        * Created Date     : 30-October-2014
        * Created By       : MageshKumar S
        * PURPOSE          : FWR-69

        * Modified Date     : 20-November-2014
        * Created By        : MageshKumar S
        * PURPOSE           : Mantis Id:15889

        * Modified by      : MAGESHKUMAR.S
        * Modified Date    : 29-April-15
        * Modified For     : FSS-3369
        * Reviewer         : Spankaj
        * Build Number     : VMSGPRHOSTCSD_3.0.1_B0002


     * Modified by      : Siva Kumar M
     * Modified for     : FSS-2279(Savings account changes)
     * Modified Date    : 31-Aug-2015
     * Reviewer         :  Saravanankumar
     * Build Number     : VMSGPRHOAT_3.1.1_B0007

     * Modified by      : A.Sivakaminathan
     * Modified Date    : 31-Dec-2015
     * Modified for     : MVHOST-1253(additional response tags)
     * Reviewer         : Pankaj Salunkhe
     * Build Number     : VMSGPRHOSTCSD_3.3

	 	 * Modified by       : DHINAKARAN B
     * Modified Date     : 18-Jul-17
     * Modified For      : FSS-5172 - B2B changes
     * Reviewer          : Saravanakumar A
     * Build Number      : VMSGPRHOST_17.07
	 
	   * Modified by                 : DHINAKARAN B
  * Modified Date               : 26-NOV-2019
  * Modified For                : VMS-1415
  * Reviewer                    :  Saravana Kumar A
  * Build Number                :  VMSGPRHOST_R23_B1
  
    * Modified By      : venkat Singamaneni
    * Modified Date    : 4-25-2022
    * Purpose          : Archival changes.
    * Reviewer         : Jyothi G
    * Release Number   : VMSGPRHOST60 for VMS-5735/FSP-991

/**********************************************************************************************/
BEGIN
   v_resp_cde := '1';
   v_time_stamp := SYSTIMESTAMP;

   BEGIN
      SAVEPOINT v_auth_savepoint;

      --Sn Get the HashPan
      BEGIN
         v_hash_pan := gethash (p_pan_code);
      EXCEPTION
         WHEN OTHERS
         THEN
            v_resp_cde := '12';
            v_err_msg :=
               'Error while converting hash pan ' || SUBSTR (SQLERRM, 1, 200);
            RAISE exp_reject_record;
      END;

      --En Get the HashPan

      --Sn Create encr pan
      BEGIN
         v_encr_pan := fn_emaps_main (p_pan_code);
      EXCEPTION
         WHEN OTHERS
         THEN
            v_resp_cde := '12';
            v_err_msg :=
                  'Error while converting encrypted pan '
               || SUBSTR (SQLERRM, 1, 200);
            RAISE exp_reject_record;
      END;

      --Start Generate HashKEY value
      BEGIN
         v_hashkey_id :=
            gethash (   p_delivery_channel
                     || p_txn_code
                     || p_pan_code
                     || p_rrn
                     || TO_CHAR (v_time_stamp, 'YYYYMMDDHH24MISSFF5')
                    );
      EXCEPTION
         WHEN OTHERS
         THEN
            v_resp_cde := '21';
            v_err_msg :=
                  'Error while converting hashkey id data '
               || SUBSTR (SQLERRM, 1, 200);
            RAISE exp_reject_record;
      END;

      --End Generate HashKEY

      --Sn find debit and credit flag
      BEGIN
         SELECT ctm_credit_debit_flag,
                TO_NUMBER (DECODE (ctm_tran_type, 'N', '0', 'F', '1')),
                ctm_tran_type, ctm_tran_desc, ctm_prfl_flag,
                ctm_preauth_flag, ctm_login_txn
           INTO v_dr_cr_flag,
                v_txn_type,
                v_tran_type, v_trans_desc, v_prfl_flag,
                v_preauth_flag, v_login_txn
           FROM cms_transaction_mast
          WHERE ctm_tran_code = p_txn_code
            AND ctm_delivery_channel = p_delivery_channel
            AND ctm_inst_code = p_inst_code;
      EXCEPTION
         WHEN NO_DATA_FOUND
         THEN
            v_resp_cde := '12';
            v_err_msg :=
                  'Transflag  not defined for txn code '
               || p_txn_code
               || ' and delivery channel '
               || p_delivery_channel;
            RAISE exp_reject_record;
         WHEN OTHERS
         THEN
            v_resp_cde := '21';
            v_err_msg := 'Error while selecting transaction details';
            RAISE exp_reject_record;
      END;

      --En find debit and credit flag

      --Sn Get the card details
      BEGIN
         SELECT cap_card_stat, cap_prod_code, cap_card_type, cap_acct_no,
                cap_proxy_number, ccm_cust_id,ccm_tandc_version,ccm_cust_code
           INTO v_card_stat, v_prod_code, v_card_type, v_acct_number,
                v_proxy_number, v_cust_id,v_ccm_tandc_version,v_cust_code
           FROM cms_appl_pan, cms_cust_mast
          WHERE cap_inst_code = ccm_inst_code
            AND cap_cust_code = ccm_cust_code
            AND cap_inst_code = p_inst_code
            AND cap_pan_code = v_hash_pan;
      EXCEPTION
         WHEN NO_DATA_FOUND
         THEN
            v_resp_cde := '16';
            v_err_msg := 'Card number not found ' || v_encr_pan;
            RAISE exp_reject_record;
         WHEN OTHERS
         THEN
            v_resp_cde := '12';
            v_err_msg :=
                  'Problem while selecting card detail'
               || SUBSTR (SQLERRM, 1, 200);
            RAISE exp_reject_record;
      END;

      --End Get the card details

      --Sn generate auth id
      BEGIN
         SELECT LPAD (seq_auth_id.NEXTVAL, 6, '0')
           INTO v_auth_id
           FROM DUAL;
      EXCEPTION
         WHEN OTHERS
         THEN
            v_err_msg :=
                 'Error while generating authid ' || SUBSTR (SQLERRM, 1, 300);
            v_resp_cde := '21';                            -- Server Declined
            RAISE exp_reject_record;
      END;

      --En generate auth id

      --Sn Duplicate RRN Check
      BEGIN
--Added for VMS-5735/FSP-991
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
           FROM transactionlog
          WHERE rrn = p_rrn
            AND business_date = p_tran_date
            AND instcode = p_inst_code
            AND delivery_channel = p_delivery_channel;
ELSE
  SELECT COUNT (1)
           INTO v_rrn_count
           FROM VMSCMS_HISTORY.TRANSACTIONLOG_HIST --Added for VMS-5733/FSP-991
          WHERE rrn = p_rrn
            AND business_date = p_tran_date
            AND instcode = p_inst_code
            AND delivery_channel = p_delivery_channel;
 END IF;


         IF v_rrn_count > 0
         THEN
            v_resp_cde := '22';
            v_err_msg := 'Duplicate RRN on ' || p_tran_date;
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
                  'Error while checking duplicate rrn '
               || SUBSTR (SQLERRM, 1, 200);
            RAISE exp_reject_record;
      END;

      --En Duplicate RRN Check
      BEGIN
         sp_cmsauth_check (p_inst_code,
                           p_msg_type,
                           p_rrn,
                           p_delivery_channel,
                           p_txn_code,
                           p_txn_mode,
                           p_tran_date,
                           p_tran_time,
                           p_mbr_numb,
                           p_rvsl_code,
                           v_tran_type,
                           p_curr_code,
                           v_tran_amt,
                           p_pan_code,
                           v_hash_pan,
                           v_encr_pan,
                           v_card_stat,
                           v_expry_date,
                           v_prod_code,
                           v_card_type,
                           v_prfl_flag,
                           v_prfl_code,
                           NULL,
                           NULL,
                           NULL,
                           v_resp_cde,
                           v_err_msg,
                           v_comb_hash
                          );

         IF v_err_msg <> 'OK'
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
                  'Error from  cmsauth Check Procedure '
               || SUBSTR (SQLERRM, 1, 200);
            RAISE exp_reject_record;
      END;

	BEGIN
	   SELECT nvl(CPC_TANDC_VERSION,'')
                   INTO v_tandc_version
                   FROM CMS_PROD_CATTYPE
					WHERE CPC_PROD_CODE=v_prod_code
					AND CPC_CARD_TYPE= V_CARD_TYPE
					AND CPC_INST_CODE=p_inst_code;


	EXCEPTION
	WHEN others THEN

	  v_resp_cde := '21';
	  v_err_msg :=
		  'Error from  featching the t and c version '
	   || SUBSTR (SQLERRM, 1, 200);
	RAISE exp_reject_record;

	END;


    -- Sn -- Modified for FWR-69 change in requirement
     BEGIN

     loop

        v_comma_pos:= instr(p_optin_list,',',1,i);

        if i=1 and v_comma_pos=0 then
            v_optin_list:=p_optin_list;
        elsif i<>1 and v_comma_pos=0 then
            v_comma_pos1:= instr(p_optin_list,',',1,i-1);
            v_optin_list:=substr(p_optin_list,v_comma_pos1+1);
         elsif i<>1 and v_comma_pos<>0 then
            v_comma_pos1:= instr(p_optin_list,',',1,i-1);
            v_optin_list:=substr(p_optin_list,v_comma_pos1+1,v_comma_pos-v_comma_pos1-1);
        elsif i=1 and v_comma_pos<>0 then
            v_optin_list:=substr(p_optin_list,1,v_comma_pos-1);
        end if;

        i:=i+1;

        v_optin_type:=substr(v_optin_list,1,instr(v_optin_list,':',1,1)-1);
        v_optin:=substr(v_optin_list,instr(v_optin_list,':',1,1)+1);






      BEGIN
         IF v_optin_type IS NOT NULL AND v_optin_type = '1'
         THEN
            v_sms_optinflag := v_optin;
         ELSIF v_optin_type IS NOT NULL AND v_optin_type = '2'
         THEN
            v_email_optinflag := v_optin;
         ELSIF v_optin_type IS NOT NULL AND v_optin_type = '3'
         THEN
            v_markmsg_optinflag := v_optin;
         ELSIF v_optin_type IS NOT NULL AND v_optin_type = '4'
         THEN
            v_gpresign_optinflag := v_optin;

            IF v_gpresign_optinflag = '1' THEN
            BEGIN

                    UPDATE cms_cust_mast
                    set ccm_tandc_version=v_tandc_version
                    WHERE ccm_cust_id=v_cust_id;

                    IF  SQL%ROWCOUNT =0 THEN
                       v_resp_cde := '21';
                       v_err_msg :=
                             'Error while updating t and c version '|| SUBSTR (SQLERRM, 1, 200);
                         RAISE exp_reject_record;

                    END IF;


            EXCEPTION

             WHEN exp_reject_record THEN
              RAISE ;
             WHEN others THEN

               v_resp_cde := '21';
               v_err_msg :=
                  'Error while updating t and c version '
               || SUBSTR (SQLERRM, 1, 200);
            RAISE exp_reject_record;
            END;
            END IF;
         ELSIF v_optin_type IS NOT NULL AND v_optin_type = '5'
         THEN
            v_savingsesign_optinflag := v_optin;
         END IF;
      END;

      BEGIN
         SELECT COUNT (*)
           INTO v_count
           FROM cms_optin_status
          WHERE cos_inst_code = p_inst_code AND cos_cust_id = v_cust_id;

         IF v_count > 0
         THEN
            UPDATE cms_optin_status
               SET cos_sms_optinflag =
                                      NVL (v_sms_optinflag, cos_sms_optinflag),
                   cos_sms_optintime =
                      NVL (DECODE (v_sms_optinflag, '1', SYSTIMESTAMP, NULL),
                           cos_sms_optintime
                          ),
                   cos_sms_optouttime =
                      NVL (DECODE (v_sms_optinflag, '0', SYSTIMESTAMP, NULL),
                           cos_sms_optouttime
                          ),
                   cos_email_optinflag =
                                  NVL (v_email_optinflag, cos_email_optinflag),
                   cos_email_optintime =
                      NVL (DECODE (v_email_optinflag,
                                   '1', SYSTIMESTAMP,
                                   NULL
                                  ),
                           cos_email_optintime
                          ),
                   cos_email_optouttime =
                      NVL (DECODE (v_email_optinflag,
                                   '0', SYSTIMESTAMP,
                                   NULL
                                  ),
                           cos_email_optouttime
                          ),
                   cos_markmsg_optinflag =
                              NVL (v_markmsg_optinflag, cos_markmsg_optinflag),
                   cos_markmsg_optintime =
                      NVL (DECODE (v_markmsg_optinflag,
                                   '1', SYSTIMESTAMP,
                                   NULL
                                  ),
                           cos_markmsg_optintime
                          ),
                   cos_markmsg_optouttime =
                      NVL (DECODE (v_markmsg_optinflag,
                                   '0', SYSTIMESTAMP,
                                   NULL
                                  ),
                           cos_markmsg_optouttime
                          ),
                   cos_gpresign_optinflag =
                            NVL (v_gpresign_optinflag, cos_gpresign_optinflag),
                   cos_gpresign_optintime =
                      NVL (DECODE (v_gpresign_optinflag,
                                   '1', SYSTIMESTAMP,
                                   NULL
                                  ),
                           cos_gpresign_optintime
                          ),
                   cos_gpresign_optouttime =
                      NVL (DECODE (v_gpresign_optinflag,
                                   '0', SYSTIMESTAMP,
                                   NULL
                                  ),
                           cos_gpresign_optouttime
                          ),
                   cos_savingsesign_optinflag =
                      NVL (v_savingsesign_optinflag,
                           cos_savingsesign_optinflag
                          ),
                   cos_savingsesign_optintime =
                      NVL (DECODE (v_savingsesign_optinflag,
                                   '1', SYSTIMESTAMP,
                                   NULL
                                  ),
                           cos_savingsesign_optintime
                          ),
                   cos_savingsesign_optouttime =
                      NVL (DECODE (v_savingsesign_optinflag,
                                   '0', SYSTIMESTAMP,
                                   NULL
                                  ),
                           cos_savingsesign_optouttime
                          )
             WHERE cos_inst_code = p_inst_code AND cos_cust_id = v_cust_id;
         ELSE
            INSERT INTO cms_optin_status
                        (cos_inst_code, cos_cust_id, cos_sms_optinflag,
                         cos_sms_optintime,
                         cos_sms_optouttime,
                         cos_email_optinflag,
                         cos_email_optintime,
                         cos_email_optouttime,
                         cos_markmsg_optinflag,
                         cos_markmsg_optintime,
                         cos_markmsg_optouttime,
                         cos_gpresign_optinflag,
                         cos_gpresign_optintime,
                         cos_gpresign_optouttime,
                         cos_savingsesign_optinflag,
                         cos_savingsesign_optintime,
                         cos_savingsesign_optouttime
                        )
                 VALUES (p_inst_code, v_cust_id, v_sms_optinflag,
                         DECODE (v_sms_optinflag, '1', SYSTIMESTAMP, NULL),
                         DECODE (v_sms_optinflag, '0', SYSTIMESTAMP, NULL),
                         v_email_optinflag,
                         DECODE (v_email_optinflag, '1', SYSTIMESTAMP, NULL),
                         DECODE (v_email_optinflag, '0', SYSTIMESTAMP, NULL),
                         v_markmsg_optinflag,
                         DECODE (v_markmsg_optinflag,
                                 '1', SYSTIMESTAMP,
                                 NULL
                                ),
                         DECODE (v_markmsg_optinflag,
                                 '0', SYSTIMESTAMP,
                                 NULL
                                ),
                         v_gpresign_optinflag,
                         DECODE (v_gpresign_optinflag,
                                 '1', SYSTIMESTAMP,
                                 NULL
                                ),
                         DECODE (v_gpresign_optinflag,
                                 '0', SYSTIMESTAMP,
                                 NULL
                                ),
                         v_savingsesign_optinflag,
                         DECODE (v_savingsesign_optinflag,
                                 '1', SYSTIMESTAMP,
                                 NULL
                                ),
                         DECODE (v_savingsesign_optinflag,
                                 '0', SYSTIMESTAMP,
                                 NULL
                                )
                        );
         END IF;
      EXCEPTION
         WHEN OTHERS
         THEN
            v_resp_cde := '21';
            v_err_msg :=
                  'ERROR IN INSERTING RECORDS IN CMS_OPTIN_STATUS'
               || SUBSTR (SQLERRM, 1, 300);
            RAISE exp_reject_record;
      END;
      if v_comma_pos=0 then
            exit;
        end if;
    END LOOP;
    END;

  -- En -- Modified for FWR-69 change in requirement

      --Sn added for Mantis id:15889
    BEGIN
         SELECT cam_acct_bal, cam_ledger_bal, cam_type_code
           INTO v_acct_bal, v_ledger_bal, v_acct_type
           FROM cms_acct_mast
          WHERE cam_acct_no = v_acct_number AND cam_inst_code = p_inst_code;
      EXCEPTION
         WHEN OTHERS
         THEN
            v_acct_bal := 0;
            v_ledger_bal := 0;
      END;



      BEGIN
         sp_fee_calc (p_inst_code,
                      p_msg_type,
                      p_rrn,
                      p_delivery_channel,
                      p_txn_code,
                      p_txn_mode,
                      p_tran_date,
                      p_tran_time,
                      p_mbr_numb,
                      p_rvsl_code,
                      v_txn_type,
                      p_curr_code,
                      v_tran_amt,
                      p_pan_code,
                      v_hash_pan,
                      v_encr_pan,
                      v_acct_number,
                      v_prod_code,
                      v_card_type,
                      v_preauth_flag,
                      NULL,
                      NULL,
                      NULL,
                      v_trans_desc,
                      v_dr_cr_flag,
                      v_acct_bal,
                      v_ledger_bal,
                      v_acct_type,
                      v_login_txn,
                      v_auth_id,
                      v_time_stamp,
                      v_resp_cde,
                      v_err_msg,
                      v_fee_code,
                      v_fee_plan,
                      v_feeattach_type,
                      v_tranfee_amt,
                      v_total_amt,
                      v_compl_fee,
                      v_compl_feetxn_excd,
                      v_compl_feecode
                     );

         IF v_err_msg <> 'OK'
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
                  'Error from sp_fee_calc '
               || SUBSTR (SQLERRM, 1, 200);
            RAISE exp_reject_record;
      END;
 --En added for Mantis id:15889

		IF  v_ccm_tandc_version = v_tandc_version THEN
			p_tandc_flag :='0';
		ELSE
			p_tandc_flag := '1';
		END IF;
		p_tandc_version :=v_tandc_version;

		BEGIN
			 SELECT cam_acct_no,cam_stat_code
			       INTO v_saving_acct_dtl,v_savings_statcode
			        FROM cms_acct_mast
			       WHERE cam_acct_id IN (
			                SELECT cca_acct_id
			                  FROM cms_cust_acct
			                 WHERE cca_cust_code = v_cust_code
			                   AND cca_inst_code = p_inst_code)
			        AND cam_type_code = v_saving_type_code
			         AND cam_inst_code = p_inst_code;
		EXCEPTION
			WHEN NO_DATA_FOUND THEN
				v_saving_acct_dtl:=NULL;
			WHEN OTHERS THEN
				v_resp_cde := '21';
				v_err_msg  := 'Error while selecting Savings Account Details'|| SUBSTR(SQLERRM, 1, 200);
				RAISE exp_reject_record;
		END;

		BEGIN
			 SELECT  cdp_param_value
			 INTO  v_min_tran_amt
			 FROM cms_dfg_param
			 WHERE cdp_param_key = 'InitialTransferAmount'
			 AND  cdp_inst_code = p_inst_code
			 AND cdp_prod_code =v_prod_code
       and cdp_card_type= v_card_type;
		EXCEPTION
			WHEN NO_DATA_FOUND THEN
			   v_min_tran_amt :='0';
			WHEN OTHERS THEN
				 v_resp_cde:= '12';
				 v_err_msg := 'Error while selecting min Initial Tran amt ' ||
							SUBSTR(SQLERRM, 1, 200);
				RAISE exp_reject_record;
		END;

      v_resp_cde := 1;
      v_err_msg := 'SUCCESS';
   EXCEPTION
      WHEN exp_reject_record
      THEN
         ROLLBACK TO v_auth_savepoint;
      WHEN OTHERS
      THEN
         v_resp_cde := '21';
         v_err_msg := 'Main Exception ' || SQLCODE || '---' || SQLERRM;
         ROLLBACK TO v_auth_savepoint;
   END;

   --Sn Get responce code fomr master
   BEGIN
      SELECT cms_iso_respcde
        INTO p_resp_code
        FROM cms_response_mast
       WHERE cms_inst_code = p_inst_code
         AND cms_delivery_channel = p_delivery_channel
         AND cms_response_id = v_resp_cde;
   EXCEPTION
      WHEN OTHERS
      THEN
         v_err_msg :=
               'Problem while selecting data from response master '
            || v_resp_cde
            || SUBSTR (SQLERRM, 1, 300);
         p_resp_code := '89';
   END;

   --En Get responce code fomr master
   BEGIN
      SELECT cam_acct_bal, cam_ledger_bal, cam_type_code
        INTO v_acct_bal, v_ledger_bal, v_acct_type
        FROM cms_acct_mast
       WHERE cam_acct_no = v_acct_number AND cam_inst_code = p_inst_code;
   EXCEPTION
      WHEN OTHERS
      THEN
         v_acct_bal := 0;
         v_ledger_bal := 0;
   END;

	IF v_saving_acct_dtl IS NULL THEN
		IF v_gpresign_optinflag = '0' OR  v_acct_bal < TO_NUMBER(v_min_tran_amt) OR TO_NUMBER(v_min_tran_amt) =0  THEN
			p_saving_acct_info := 'NE'; -- Not eligible Minimum balance requirement for savings is not met OR e-Sign declined
		ELSE
			p_saving_acct_info :='E'; -- Eligible for Savings Account
		END IF;
	ELSIF v_savings_statcode = 2 THEN
		p_saving_acct_info :='D'; -- Savings Account disabled due to the 7th transfer rule
	ELSE
		p_saving_acct_info :='A'; -- Savings Account exists
	END IF;

   IF v_dr_cr_flag IS NULL
   THEN
      BEGIN
         SELECT ctm_credit_debit_flag,
                TO_NUMBER (DECODE (ctm_tran_type, 'N', '0', 'F', '1')),
                ctm_tran_type, ctm_tran_desc, ctm_prfl_flag
           INTO v_dr_cr_flag,
                v_txn_type,
                v_tran_type, v_trans_desc, v_prfl_flag
           FROM cms_transaction_mast
          WHERE ctm_tran_code = p_txn_code
            AND ctm_delivery_channel = p_delivery_channel
            AND ctm_inst_code = p_inst_code;
      EXCEPTION
         WHEN OTHERS
         THEN
            NULL;
      END;
   END IF;

   --Sn Inserting data in transactionlog
   BEGIN
      sp_log_txnlog (p_inst_code,
                     p_msg_type,
                     p_rrn,
                     p_delivery_channel,
                     p_txn_code,
                     v_tran_type,
                     p_txn_mode,
                     p_tran_date,
                     p_tran_time,
                     p_rvsl_code,
                     v_hash_pan,
                     v_encr_pan,
                     v_err_msg,
                     p_ipaddress,
                     v_card_stat,
                     v_trans_desc,
                     p_ani,
                     p_dni,
                     v_time_stamp,
                     v_acct_number,
                     v_prod_code,
                     v_card_type,
                     v_dr_cr_flag,
                     v_acct_bal,
                     v_ledger_bal,
                     v_acct_type,
                     v_proxy_number,
                     v_auth_id,
                     v_tran_amt,
                     v_total_amt,
                     v_fee_code,
                     v_tranfee_amt,
                     v_fee_plan,
                     v_feeattach_type,
                     v_resp_cde,
                     p_resp_code,
                     p_curr_code,
                     v_err_msg
                    );
   EXCEPTION
      WHEN OTHERS
      THEN
         p_resp_code := '89';
         v_err_msg :=
               'Exception while inserting to transaction log '
            || SQLCODE
            || '---'
            || SQLERRM;
   --RAISE exp_reject_record;
   END;

   --En Inserting data in transactionlog

   --Sn Inserting data in transactionlog dtl
   BEGIN
      sp_log_txnlogdetl (p_inst_code,
                         p_msg_type,
                         p_rrn,
                         p_delivery_channel,
                         p_txn_code,
                         v_txn_type,
                         p_txn_mode,
                         p_tran_date,
                         p_tran_time,
                         v_hash_pan,
                         v_encr_pan,
                         v_err_msg,
                         v_acct_number,
                         v_auth_id,
                         v_tran_amt,
                         p_mobil_no,
                         p_device_id,
                         v_hashkey_id,
                         NULL,
                         NULL,
                         NULL,
                         NULL,
                         p_resp_code,
                         NULL,
                         NULL,
                         NULL,
                         v_logdtl_resp
                        );
   EXCEPTION
      WHEN OTHERS
      THEN
         v_err_msg :=
               'Problem while inserting data into transaction log  dtl'
            || SUBSTR (SQLERRM, 1, 300);
         p_resp_code := '89';
   END;

--Sn Inserting data in transactionlog dtl
   p_res_msg := v_err_msg;
EXCEPTION
   WHEN OTHERS
   THEN
      ROLLBACK;
      p_resp_code := '69';                                 -- Server Declined
      p_res_msg :=
            'Main exception from  authorization ' || SUBSTR (SQLERRM, 1, 300);
END;
/
show error