create or replace
PROCEDURE        VMSCMS.SP_CUSTOMER_SERVICES_CSR (
   p_inst_code          IN    NUMBER,
   p_msg_type           IN    VARCHAR2,
   p_pan_code           IN    VARCHAR2,
   p_mbr_numb           IN    VARCHAR2,
   p_rrn                IN    VARCHAR2, 
   p_stan               IN    VARCHAR2,
   p_delivery_channel   IN    VARCHAR2,
   p_txn_code           IN    VARCHAR2,
   p_txn_mode           IN    VARCHAR2,
   p_tran_date          IN    VARCHAR2,
   p_tran_time          IN    VARCHAR2,
   p_remark             IN    VARCHAR2,
   p_ins_user           IN    NUMBER,
   p_call_id            IN    NUMBER,
   p_curr_code          IN    VARCHAR2,              --added on 22-Jun-2012
   p_rvsl_code          IN    VARCHAR2,              --added on 22-Jun-2012
   p_fee_calc           IN    VARCHAR2,              -- Added by sagar on 27Aug2012 For fetching addtional Fee details
   p_ipaddress            IN      VARCHAR2,                 --added by amit on 06-Oct-2012
   p_resp_code          OUT   VARCHAR2,
   p_resp_msg           OUT   VARCHAR2,
   p_fee_amt           IN OUT VARCHAR2,
   p_avail_bal         OUT    VARCHAR2,
   p_ledger_bal        OUT    VARCHAR2,
   p_process_msg       OUT    VARCHAR2
)
IS
   /**********************************************************************************************
   * VERSION           :  1.0
   * DATE OF CREATION  : 28/May/2012
   * PURPOSE           : Call logging of statement Generation
   * CREATED BY        : Sagar More
   * Modified By       : Amit Sonar.
   * Modified Date     : 06-Oct-2012
   * Mofication Reason : to add new parameter IP address and log in transaction log table.
   * Build Number       : RI0021

   * modified by      : Santosh K
   * modified for     : MVCSD-4080 : Generate Paper Statement
   * modified Date    : 02-May-13
   * modified reason  : Added Email-Id Validation for email null statement [Saving as well as Spending].
   * Reviewer         :
   * Reviewed Date    :
   * build number     : RI0024.1_B0013

   * Modified By      : Sagar M.
   * Modified Date    : 19-Apr-2013
   * Modified for     : Defect 10871
   * Modified Reason  : Logging of below details handled in tranasctionlog
                        1) Product code,Product category code,Card status,Acct Type,drcr flag,account number
                        2) Timestamp and Amount values logging correction
   * Reviewer         : Dhiraj
   * Reviewed Date    : 17-Apr-2013
   * Build Number     : RI0024.1_B0015

   * Moodified By     : Dnyaneshwar J
   * Modified For     : Defect 0011178: Paper statement generation getting failed for Inactive card on selecting Date range
   * Modified Date    : 11-June-2013
   * Build Number     :  RI0024.2_B0002

   * Moodified By     : Dnyaneshwar J
   * Modified For     : Mantis-0012104 : Not displaying proper message
   * Modified Date    : 23-Aug-2013
   * Build Number     : RI0024.4_B0003

   * Modified by      : MageshKumar S.
   * Modified Date    : 25-July-14
   * Modified For     : FWR-48
   * Modified reason  : GL Mapping removal changes
   * Reviewer         : Spankaj
   * Build Number     : RI0027.3.1_B0001
   
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
    
     * Modified By      : UBAIDUR RAHMAN.H
     * Modified Date    : 25-JAN-2018
     * Purpose          : VMS-162 (encryption changes)
     * Reviewer         : Vini.P
     * Release Number   : VMSGPRHOST18.01
     
     * Modified by      : UBAIDUR RAHMAN H
      * Modified for     : VMS-2010
      * Modified Date    : 26-JAN-2020
      * Reviewer         : Saravanakumar A
      * Build Number     : VMSGPRHOST_R27_B2
      
	* Modified By      : venkat Singamaneni
    * Modified Date    : 4-4-2022
    * Purpose          : Archival changes.
    * Reviewer         : Saravana Kumar A
    * Release Number   : VMSGPRHOST60 for VMS-5733/FSP-991
   **************************************************************************************************/
   v_fee_crgl_catg        cms_prodcattype_fees.cpf_crgl_catg%TYPE;
   v_fee_crgl_code        cms_prodcattype_fees.cpf_crgl_code%TYPE;
   v_fee_crsubgl_code     cms_prodcattype_fees.cpf_crsubgl_code%TYPE;
   v_fee_cracct_no        cms_prodcattype_fees.cpf_cracct_no%TYPE;
   v_fee_drgl_catg        cms_prodcattype_fees.cpf_drgl_catg%TYPE;
   v_fee_drgl_code        cms_prodcattype_fees.cpf_drgl_code%TYPE;
   v_fee_drsubgl_code     cms_prodcattype_fees.cpf_drsubgl_code%TYPE;
   v_fee_dracct_no        cms_prodcattype_fees.cpf_dracct_no%TYPE;
   v_servicetax_percent   cms_inst_param.cip_param_value%TYPE;
   v_cess_percent         cms_inst_param.cip_param_value%TYPE;
   v_servicetax_amount    NUMBER;
   v_cess_amount          NUMBER;
   v_st_calc_flag         cms_prodcattype_fees.cpf_st_calc_flag%TYPE;
   v_cess_calc_flag       cms_prodcattype_fees.cpf_cess_calc_flag%TYPE;
   v_st_cracct_no         cms_prodcattype_fees.cpf_st_cracct_no%TYPE;
   v_st_dracct_no         cms_prodcattype_fees.cpf_st_dracct_no%TYPE;
   v_cess_cracct_no       cms_prodcattype_fees.cpf_cess_cracct_no%TYPE;
   v_cess_dracct_no       cms_prodcattype_fees.cpf_cess_dracct_no%TYPE;
   v_waiv_percnt          cms_prodcattype_waiv.cpw_waiv_prcnt%TYPE;
   v_resp_cde             VARCHAR2 (3);
   v_errmsg               VARCHAR2 (300);
   exp_reject_record      EXCEPTION;
   v_tran_date            DATE;
   v_tran_type            cms_transaction_mast.ctm_tran_type%TYPE;
   v_txn_type             VARCHAR2 (1);
   v_dr_cr_flag           cms_transaction_mast.ctm_credit_debit_flag%TYPE;
   v_base_curr            cms_bin_param.cbp_param_value%TYPE;
   v_fee_code             cms_fee_mast.cfm_fee_code%TYPE;
   --v_fee_amt              NUMBER;  -- Commented by sagar on 22-Aug-2012
   v_cap_prod_code        cms_appl_pan.cap_prod_code%TYPE;
   v_cap_card_type        cms_appl_pan.cap_card_type%TYPE;
   v_hash_pan             cms_appl_pan.cap_pan_code%TYPE;
   v_encr_pan             cms_appl_pan.cap_pan_code_encr%TYPE;
   v_log_actual_fee       NUMBER;
   v_log_waiver_amt       NUMBER;
   v_total_fee            NUMBER;
   v_fee_opening_bal      NUMBER;
   v_upd_amt              NUMBER;
   v_upd_ledger_amt       NUMBER;
   v_acct_bal             cms_acct_mast.cam_acct_bal%TYPE;
   v_ledger_bal           cms_acct_mast.cam_ledger_bal%TYPE;
   v_cap_acct_no          cms_appl_pan.cap_acct_no%TYPE;
  -- v_cfm_func_code        cms_func_mast.cfm_func_code%TYPE; --commented for fwr-48
   v_hold_amount          NUMBER                                         := 0;
   v_auth_id              transactionlog.auth_id%TYPE;
   v_cap_proxynumber      cms_appl_pan.cap_proxy_number%TYPE;
   v_call_seq             NUMBER (3);
   v_tran_desc            cms_transaction_mast.ctm_tran_desc%TYPE;
   v_capture_date         DATE;
   v_spnd_acctno          cms_appl_pan.cap_acct_no%TYPE;
   v_cust_code            cms_appl_pan.cap_cust_code%TYPE;
-- ADDED BY GANESH ON 19-JUL-12
   v_fee_amt cms_statements_log.csl_trans_amount%type; -- Added by sagar on 22-Aug-2012 to fetch addtional fee details
    v_chk_clawback   varchar2(2);
    v_rrn_count      number;
    v_clawback_amt CMS_CHARGE_DTL.ccd_clawback_amnt%type;
    V_CAM_ACCT_NO    CMS_ACCT_MAST.CAM_ACCT_NO%type;
    V_CAM_EMAIL_ID     CMS_ADDR_MAST.CAM_EMAIL%type;    -- Added for MVCSD-4080 : Generate Paper Statement
   --- v_cap_bill_addr   cms_appl_pan.CAP_BILL_ADDR%TYPE;      -- Added for MVCSD-4080 : Generate Paper Statement
    v_cam_type_code   cms_acct_mast.cam_type_code%type;  -- Added on 19-Apr-2013 for defect 10871
    v_timestamp       timestamp;                         -- Added on 19-Apr-2013 for defect 10871
    V_APPLPAN_CARDSTAT  CMS_APPL_PAN.CAP_CARD_STAT%type;   --Added for defect 10871
    v_profile_code       CMS_APPL_PAN.cap_prfl_code%type;
    V_EMAIL_ID     CMS_PROD_CATTYPE.CPC_EMAIL_ID%type;
    v_encrypt_enable  CMS_PROD_CATTYPE.cpc_encrypt_enable%TYPE;
    v_Retperiod  date; --Added for VMS-5733/FSP-991
v_Retdate  date; --Added for VMS-5733/FSP-991
BEGIN

 v_errmsg := 'OK';

  IF p_fee_calc ='N'
  THEN

      p_process_msg := 'FEE NOT APPLIED';

  END IF;

   BEGIN
      BEGIN
         v_hash_pan := gethash (p_pan_code);
      EXCEPTION
         WHEN OTHERS
         THEN
            v_resp_cde := '21';
            v_errmsg :=
                    'Error while converting pan ' || SUBSTR (SQLERRM, 1, 100);
            RAISE exp_reject_record;
      END;

      BEGIN
         v_encr_pan := fn_emaps_main (p_pan_code);
      EXCEPTION
         WHEN OTHERS
         THEN
            v_resp_cde := '21';
            v_errmsg :=
                    'Error while converting pan ' || SUBSTR (SQLERRM, 1, 100);
            RAISE exp_reject_record;
      END;


      BEGIN
      
      v_Retdate := TO_DATE(SUBSTR(TRIM(p_tran_date), 1, 8), 'yyyymmdd');

       select (add_months(trunc(sysdate,'MM'),'-'||RETENTION_PERIOD))
       INTO   v_Retperiod 
       FROM DBA_OPERATIONS.ARCHIVE_MGMNT_CTL 
       WHERE  OPERATION_TYPE='ARCHIVE' 
       AND OBJECT_NAME='TRANSACTIONLOG_EBR';



IF (v_Retdate>v_Retperiod)
    THEN
 SELECT COUNT (1)
           INTO v_rrn_count
           FROM transactionlog
          WHERE instcode = p_inst_code
            AND customer_card_no = v_hash_pan
            AND rrn = p_rrn
            AND delivery_channel = p_delivery_channel
            AND txn_code = p_txn_code
            AND business_date = p_tran_date
            AND business_time = p_tran_time;
         ELSE
          SELECT COUNT (1)
           INTO v_rrn_count
           FROM VMSCMS_HISTORY.TRANSACTIONLOG_HIST --Added for VMS-5733/FSP-991
          WHERE instcode = p_inst_code
            AND customer_card_no = v_hash_pan
            AND rrn = p_rrn
            AND delivery_channel = p_delivery_channel
            AND txn_code = p_txn_code
            AND business_date = p_tran_date
            AND business_time = p_tran_time;
         END IF;   
            

         IF v_rrn_count > 0
         THEN
            v_resp_cde := '22';
            v_errmsg := 'Duplicate RRN found - ' || p_rrn;
            RAISE exp_reject_record;
         END IF;
      EXCEPTION
         WHEN exp_reject_record
         THEN
            RAISE;
         WHEN OTHERS
         THEN
            v_resp_cde := '21';
            v_errmsg :=
                  'While checking for duplicate '
               || p_rrn
               || SUBSTR (SQLERRM, 1, 100);
            RAISE exp_reject_record;
      END;


      BEGIN
         --         SELECT TO_CHAR(SYSDATE, 'YYYYMMDD') || LPAD(SEQ_AUTH_ID.NEXTVAL, 6, '0')
         SELECT LPAD (seq_auth_id.NEXTVAL, 6, '0')
           INTO v_auth_id
           FROM DUAL;
      EXCEPTION
         WHEN OTHERS
         THEN
            v_errmsg :=
                 'Error while generating authid ' || SUBSTR (SQLERRM, 1, 100);
            v_resp_cde := '21';
            RAISE exp_reject_record;
      END;

      BEGIN
         SELECT ctm_credit_debit_flag, ctm_tran_type,
                TO_NUMBER (DECODE (ctm_tran_type, 'N', '0', 'F', '1')),
                ctm_tran_desc
           INTO v_dr_cr_flag, v_tran_type,
                v_txn_type,
                v_tran_desc
           FROM cms_transaction_mast
          WHERE ctm_tran_code = p_txn_code
            AND ctm_delivery_channel = p_delivery_channel
            AND ctm_inst_code = p_inst_code;
      EXCEPTION
         WHEN NO_DATA_FOUND
         THEN
            v_resp_cde := '12';
            v_errmsg :=
                  'Transflag  not defined for txn code '
               || p_txn_code
               || ' and delivery channel '
               || p_delivery_channel;
            RAISE exp_reject_record;
         WHEN OTHERS
         THEN
            v_resp_cde := '21';
            v_errmsg :=
                  'Error while selecting transaction details'
               || SUBSTR (SQLERRM, 1, 100);
            RAISE exp_reject_record;
      END;

      --Sn commented for fwr-48
   /*   BEGIN
         SELECT cfm_func_code
           INTO v_cfm_func_code
           FROM cms_func_mast
          WHERE cfm_inst_code = p_inst_code
            AND cfm_txn_code = p_txn_code
            AND cfm_delivery_channel = p_delivery_channel;
      EXCEPTION
         WHEN NO_DATA_FOUND
         THEN
            v_resp_cde := '49';
            v_errmsg :=
                  'Function not defined for txn code '
               || p_txn_code
               || ' and delivery channel '
               || p_delivery_channel;
            RAISE exp_reject_record;
         WHEN OTHERS
         THEN
            v_resp_cde := '21';
            v_errmsg :=
                  'error while fetching function code '
               || SUBSTR (SQLERRM, 1, 100);
            RAISE exp_reject_record;
      END;*/

      --En commented for fwr-48

      BEGIN
         select CAP_PROD_CODE, CAP_CARD_TYPE, CAP_ACCT_NO,
                cap_proxy_number,                  -- cap_bill_addr Added for MVCSD-4080 : Generate Paper Statement
                cap_card_stat,cap_cust_code                                    --Added for defect 10871
           into V_CAP_PROD_CODE, V_CAP_CARD_TYPE, V_CAP_ACCT_NO,
                v_cap_proxynumber,                 -- v_cap_bill_addr Added for MVCSD-4080 : Generate Paper Statement
                v_applpan_cardstat,v_cust_code                               --Added for defect 10871
           FROM cms_appl_pan
          WHERE cap_inst_code = p_inst_code
            AND cap_mbr_numb = p_mbr_numb
            AND cap_pan_code = v_hash_pan;
            
      EXCEPTION
         WHEN NO_DATA_FOUND
         THEN
            v_resp_cde := '14';
            v_errmsg := 'Card not found';
            RAISE exp_reject_record;
         WHEN OTHERS
         THEN
            v_resp_cde := '21';
            v_errmsg :=
               'While fetching details for card ' || SUBSTR (SQLERRM, 1, 100);
            RAISE exp_reject_record;
      END;

      BEGIN
         SELECT cam_acct_bal, cam_ledger_bal,
                cam_type_code                                   --Added for defect 10871
           INTO v_acct_bal, v_ledger_bal,
                v_cam_type_code                                 --Added for defect 10871
           FROM cms_acct_mast
          WHERE cam_inst_code = p_inst_code AND cam_acct_no = v_cap_acct_no;
      EXCEPTION
         WHEN NO_DATA_FOUND
         THEN
            v_resp_cde := '07';
            v_errmsg := 'Account not found';
            RAISE exp_reject_record;
         WHEN OTHERS
         THEN
            v_resp_cde := '21';
            v_errmsg :=
                  'while getting balance from acct master '
               || SUBSTR (SQLERRM, 1, 100);
            RAISE exp_reject_record;
      END;

      /*
        BEGIN

           SELECT cip_param_value
             INTO v_servicetax_percent
             FROM cms_inst_param
            WHERE cip_param_key = 'SERVICETAX' and cip_inst_code = p_inst_code;
          EXCEPTION
           WHEN NO_DATA_FOUND THEN
             v_resp_cde := '21';
             v_errmsg  := 'Service Tax is  not defined in the system';
             raise exp_reject_record;
           WHEN OTHERS THEN
             v_resp_cde := '21';
             v_errmsg  := 'Error while selecting service tax from system ';
             RAISE EXP_REJECT_RECORD;
        END;

        BEGIN

           SELECT cip_param_value
             INTO v_cess_percent
             FROM cms_inst_param
            WHERE cip_param_key = 'CESS' and cip_inst_code = p_inst_code;
        EXCEPTION
           WHEN NO_DATA_FOUND THEN
             v_resp_cde := '21';
             v_errmsg  := 'Cess is not defined in the system';
             raise exp_reject_record;
           WHEN OTHERS THEN
             v_resp_cde := '21';
             v_errmsg  := 'Error while selecting cess from system ';
             raise exp_reject_record;
        END;


        BEGIN
           V_TRAN_DATE := TO_DATE(SUBSTR(TRIM(P_TRAN_DATE), 1, 8) || ' ' ||
                              SUBSTR(TRIM(P_TRAN_TIME), 1, 10),
                              'yyyymmdd hh24:mi:ss');
          EXCEPTION
           WHEN OTHERS THEN
             v_resp_cde := '89';
             v_errmsg  := 'Problem while converting transaction time ' ||substr(sqlerrm, 1, 200);
             raise exp_reject_record;

        END;
      */
      

--Sn select profile code for product
 BEGIN
    SELECT CPC_PROFILE_CODE,TRIM(CPC_EMAIL_ID),upper(cpc_encrypt_enable) 
      INTO v_PROFILE_CODE,v_email_id,v_encrypt_enable 
      FROM CMS_PROD_CATTYPE
      WHERE CPC_PROD_CODE = V_CAP_PROD_CODE AND
            CPC_CARD_TYPE = V_CAP_CARD_TYPE AND
            CPC_INST_CODE = p_inst_code;
      EXCEPTION
        WHEN NO_DATA_FOUND THEN
          V_ERRMSG   := 'NO PROFILE CODE FOUND FROM PRODCATTYPE - NO DATA FOUND' ;
          v_resp_cde := '21';
          RAISE exp_reject_record;
        WHEN OTHERS THEN
          V_ERRMSG   := 'ERROR WHILE FETCHING PROFILE CODE FROM PRODCATTYPE ' ||
                  SUBSTR(SQLERRM, 1, 200);
          v_resp_cde := '21';
          RAISE exp_reject_record;
  END;
      
      
      
      
      
      BEGIN
--         SELECT cip_param_value
--           INTO v_base_curr
--           FROM cms_inst_param
--          WHERE cip_inst_code = p_inst_code AND cip_param_key = 'CURRENCY';

             SELECT TRIM (cbp_param_value)
	     INTO v_base_curr
	     FROM cms_bin_param WHERE cbp_param_name = 'Currency'
	     AND cbp_inst_code= p_inst_code
                AND cbp_profile_code =V_PROFILE_CODE;			 
			 
			 

         IF v_base_curr IS NULL
         THEN
            v_resp_cde := '21';
            v_errmsg := 'Base currency cannot be null ';
            RAISE exp_reject_record;
         END IF;
      EXCEPTION
         WHEN exp_reject_record                -- this block added by chinmaya
         THEN
            RAISE;
         WHEN NO_DATA_FOUND
         THEN
            v_resp_cde := '21';
            v_errmsg := 'Base currency is not defined for the BIN profile ';
            RAISE exp_reject_record;
         WHEN OTHERS
         THEN
            v_resp_cde := '21';
            v_errmsg :=
                  'Error while selecting base currency for BIN '
               || SUBSTR (SQLERRM, 1, 200);
            RAISE exp_reject_record;
      END;

      --SN:Added by Santosh on 02-May-2013 for MVCSD-4080 : Generate Paper Statement



      IF P_TXN_CODE IN ('31', '32') THEN
       BEGIN
          SELECT decode(v_encrypt_enable,'Y',fn_dmaps_main(CAM_EMAIL),CAM_EMAIL)
          INTO v_cam_email_id
            from CMS_ADDR_MAST
          where CAM_INST_CODE = P_INST_CODE
          ---  AND cam_addr_code = v_cap_bill_addr  --- Modified for impact on VMS-2010.
	    AND cam_cust_code = v_cust_code
	    AND cam_addr_flag = 'P';

        IF TRIM (v_cam_email_id) IS NULL
         THEN
            V_RESP_CDE := '170';
            v_errmsg := 'Email-Id not configured to Customer';
            RAISE EXP_REJECT_RECORD;
        END IF;

      EXCEPTION
         WHEN exp_reject_record
         then
            RAISE;
         WHEN NO_DATA_FOUND
         then
            V_RESP_CDE := '170';
            v_errmsg := 'Email-Id not configured to Customer';
            RAISE exp_reject_record;
         WHEN OTHERS
         THEN
            v_resp_cde := '21';
            V_ERRMSG :=
                  'Error while selecting Email-Id'
               || SUBSTR (SQLERRM, 1, 200);
            RAISE EXP_REJECT_RECORD;
      end;
     elsif P_TXN_CODE IN ('41', '42') THEN
      BEGIN
          
          IF v_email_id IS NULL
            THEN
              V_RESP_CDE := '171';
              v_errmsg := 'Email-Id not configured to Product';
              RAISE EXP_REJECT_RECORD;
          END IF;

      EXCEPTION
        WHEN exp_reject_record
         then
            RAISE;
         WHEN NO_DATA_FOUND
         THEN
            V_RESP_CDE := '171';
            v_errmsg := 'Email-Id not configured to Product';
            RAISE exp_reject_record;
         WHEN OTHERS
         THEN
            v_resp_cde := '21';
            V_ERRMSG :=
                  'Error while selecting Email-Id'
               || SUBSTR (SQLERRM, 1, 200);
            RAISE EXP_REJECT_RECORD;
      end;
      END IF;

      --EN:Added by Santosh on 02-May-2013 for MVCSD-4080 : Generate Paper Statement

      BEGIN
         -- Added by sagar on 22-Jun-2012 to handle new fee related changes
         sp_authorize_txn_cms_auth (p_inst_code,
                                    p_msg_type,
                                    p_rrn,
                                    p_delivery_channel,
                                    NULL,                          --P_TERM_ID
                                    p_txn_code,
                                    p_txn_mode,
                                    p_tran_date,
                                    p_tran_time,
                                    p_pan_code,
                                    p_inst_code,
                                    0,                                   --AMT
                                    NULL,                    --P_MERCHANT_NAME
                                    NULL,                    --P_MERCHANT_CITY
                                    NULL,                         --P_MCC_CODE
                                    p_curr_code,
                                    NULL,                          --P_PROD_ID
                                    NULL,                          --P_CATG_ID
                                    NULL,                          --P_TIP_AMT
                                    NULL,                       --P_TO_ACCT_NO
                                    NULL,                      --P_ATMNAME_LOC
                                    NULL,                  --P_MCCCODE_GROUPID
                                    NULL,                 --P_CURRCODE_GROUPID
                                    NULL,                --P_TRANSCODE_GROUPID
                                    NULL,                            --P_RULES
                                    NULL,                     --P_PREAUTH_DATE
                                    NULL,                   --P_CONSODIUM_CODE
                                    NULL,                     --P_PARTNER_CODE
                                    NULL,                       --P_EXPRY_DATE
                                    p_stan,
                                    p_mbr_numb,
                                    p_rvsl_code,
                                    NULL,                --P_CURR_CONVERT_AMNT
                                    v_auth_id,
                                    v_resp_cde,
                                    v_errmsg,
                                    v_capture_date,
                                    p_fee_calc
                                   );

         IF v_resp_cde <> '00' AND v_errmsg <> 'OK'
         THEN
            --v_resp_cde := '21';--Commented by Dnyaneshwar J on 23 Aug 2013 Mantis-0012104
            --v_errmsg := 'Error from auth process ' || v_errmsg;--Commented by Dnyaneshwar J on 23 Aug 2013 Mantis-0012104
            RAISE exp_reject_record;
         END IF;
      EXCEPTION
         WHEN exp_reject_record
         THEN
            RAISE exp_reject_record;
         WHEN OTHERS
         THEN
            v_resp_cde := '21';
            v_errmsg :=
                  'Error from Card authorization' || SUBSTR (SQLERRM, 1, 200);
            RAISE exp_reject_record;
      END;



      v_resp_cde := 1;

      BEGIN
         SELECT cms_iso_respcde
           INTO p_resp_code
           FROM cms_response_mast
          WHERE cms_inst_code = p_inst_code
            AND cms_delivery_channel = p_delivery_channel
            AND cms_response_id = v_resp_cde;

         p_resp_msg := v_errmsg;
      EXCEPTION
         WHEN OTHERS
         THEN
            p_resp_msg :=
                  'Problem while selecting data from response master '
               || v_resp_cde
               || SUBSTR (SQLERRM, 1, 100);
            p_resp_code := '89';
            ROLLBACK;
            RETURN;
      END;

      BEGIN
      IF (v_Retdate>v_Retperiod)
    THEN
         --added by sagar on 20-Jun-2012 for reamrk logging in txnlog table
         UPDATE transactionlog
            SET remark = p_remark,
                add_ins_user = p_ins_user,  -- added by sagar on 25Sep2012
                add_lupd_user = p_ins_user, -- added by sagar on 25Sep2012
                ipaddress = p_ipaddress  --added by amit on 06-Oct-2012
          WHERE instcode = p_inst_code
            AND customer_card_no = v_hash_pan
            AND rrn = p_rrn
            AND business_date = p_tran_date
            AND business_time = p_tran_time
            AND delivery_channel = p_delivery_channel
            AND txn_code = p_txn_code;
        ELSE
                 UPDATE VMSCMS_HISTORY.TRANSACTIONLOG_HIST --Added for VMS-5733/FSP-991
            SET remark = p_remark,
                add_ins_user = p_ins_user,  -- added by sagar on 25Sep2012
                add_lupd_user = p_ins_user, -- added by sagar on 25Sep2012
                ipaddress = p_ipaddress  --added by amit on 06-Oct-2012
          WHERE instcode = p_inst_code
            AND customer_card_no = v_hash_pan
            AND rrn = p_rrn
            AND business_date = p_tran_date
            AND business_time = p_tran_time
            AND delivery_channel = p_delivery_channel
            AND txn_code = p_txn_code;
         END IF;   

         IF SQL%ROWCOUNT = 0
         THEN
            v_resp_cde := '21';
            v_errmsg := 'Txn not updated in transactiolog for remark';
            RAISE exp_reject_record;
         END IF;
      EXCEPTION
         WHEN exp_reject_record
         THEN
            RAISE;
         WHEN OTHERS
         THEN
            v_resp_cde := '21';
            v_errmsg :=
                  'Error while updating into transactiolog '
               || SUBSTR (SQLERRM, 1, 200);
            RAISE exp_reject_record;
      END;

    -- SN : ADDED BY Ganesh on 18-JUL-12
      BEGIN
         SELECT cap_acct_no
           INTO v_spnd_acctno
           FROM cms_appl_pan
          WHERE cap_pan_code = v_hash_pan
            AND cap_inst_code = p_inst_code
            AND cap_mbr_numb = p_mbr_numb;
      EXCEPTION
         WHEN NO_DATA_FOUND
         THEN
            v_resp_cde := '21';
            v_errmsg :=
               'Spending Account Number Not Found For the Card in PAN Master ';
            RAISE exp_reject_record;
         WHEN OTHERS
         THEN
            v_resp_cde := '21';
            v_errmsg :=
                  'Error While Selecting Spending account Number for Card '
               || SUBSTR (SQLERRM, 1, 100);
            RAISE exp_reject_record;
      END;

        -- EN : ADDED BY Ganesh on 18-JUL-12
      BEGIN
         BEGIN
            SELECT NVL (MAX (ccd_call_seq), 0) + 1
              INTO v_call_seq
              FROM cms_calllog_details
             WHERE ccd_inst_code = ccd_inst_code
               AND ccd_call_id = p_call_id
               AND ccd_pan_code = v_hash_pan;
         EXCEPTION
            WHEN NO_DATA_FOUND
            THEN
               v_errmsg := 'record is not present in cms_calllog_details  ';
               v_resp_cde := '49';
               RAISE exp_reject_record;
            WHEN OTHERS
            THEN
               v_errmsg :=
                     'Error while selecting frmo cms_calllog_details '
                  || SUBSTR (SQLERRM, 1, 100);
               v_resp_cde := '21';
               RAISE exp_reject_record;
         END;

         INSERT INTO cms_calllog_details
                     (ccd_inst_code, ccd_call_id, ccd_pan_code, ccd_call_seq,
                      ccd_rrn, ccd_devl_chnl, ccd_txn_code, ccd_tran_date,
                      ccd_tran_time, ccd_comments, ccd_ins_user,
                      ccd_ins_date, ccd_lupd_user, ccd_lupd_date, ccd_acct_no
                     -- CCD_ACCT_NO ADDED BY GANESH ON 18-JUL-2012
                     )
              VALUES (p_inst_code, p_call_id, v_hash_pan, v_call_seq,
                      p_rrn, p_delivery_channel, p_txn_code, p_tran_date,
                      p_tran_time, p_remark, p_ins_user,
                      SYSDATE, p_ins_user, SYSDATE, v_spnd_acctno
                     -- V_SPND_ACCTNO ADDED BY GANESH ON 18-JUL-2012
                     );
      EXCEPTION
         WHEN exp_reject_record
         THEN
            RAISE;
         WHEN OTHERS
         THEN
            v_resp_cde := '21';
            v_errmsg :=
                  ' Error while inserting into cms_calllog_details '
               || SUBSTR (SQLERRM, 1, 100);
            RAISE exp_reject_record;
      END;

       -------------------------------------------------------------------
       --SN: Added by sagar on 28-Aug-2012 to fetch additional fee details
       -------------------------------------------------------------------

        BEGIN

           select cam_acct_bal,cam_ledger_bal,cam_acct_no
           into   p_avail_bal,p_ledger_bal,v_cam_acct_no
           from   cms_acct_mast
           where cam_inst_code = p_inst_code
           and   cam_acct_no = v_cap_acct_no;

        exception when no_data_found
        then
             p_avail_bal  := null;
             p_ledger_bal := null;

        when others
        then
                 v_errmsg := 'Error While Fetching Balance '||substr(sqlerrm,1,100);
                 RAISE exp_reject_record;
        END;


       IF p_fee_calc = 'Y'
       THEN

            Begin
  v_Retdate := TO_DATE(SUBSTR(TRIM(p_tran_date), 1, 8), 'yyyymmdd');

       select (add_months(trunc(sysdate,'MM'),'-'||RETENTION_PERIOD))
       INTO   v_Retperiod 
       FROM DBA_OPERATIONS.ARCHIVE_MGMNT_CTL 
       WHERE  OPERATION_TYPE='ARCHIVE' 
       AND OBJECT_NAME='CMS_STATEMENTS_LOG_EBR';



IF (v_Retdate>v_Retperiod)
    THEN          

               select csl_trans_amount
               into   v_fee_amt
               from   cms_statements_log
               where  csl_pan_no = v_hash_pan
               and    csl_rrn    = p_rrn
               and    csl_business_date = p_tran_date
               and    csl_business_time = p_tran_time
               and    txn_fee_flag      = 'Y'
               and    csl_delivery_channel = p_delivery_channel
               and    csl_txn_code         = p_txn_code;
    ELSE

                 select csl_trans_amount
               into   v_fee_amt
               from   VMSCMS_HISTORY.CMS_STATEMENTS_LOG_HIST --Added for VMS-5733/FSP-991
               where  csl_pan_no = v_hash_pan
               and    csl_rrn    = p_rrn
               and    csl_business_date = p_tran_date
               and    csl_business_time = p_tran_time
               and    txn_fee_flag      = 'Y'
               and    csl_delivery_channel = p_delivery_channel
               and    csl_txn_code         = p_txn_code;
        END IF;       

            exception when no_data_found
            then
                   BEGIN

                     select 1,ccd_clawback_amnt
                     into  v_chk_clawback,v_clawback_amt
                     from CMS_CHARGE_DTL
                     where ccd_pan_code = v_hash_pan
                     and   ccd_rrn      = p_rrn
                     and   ccd_acct_no  = v_cam_acct_no
                     and   ccd_delivery_channel = p_delivery_channel
                     and   ccd_txn_code = p_txn_code
                     and   ccd_clawback = 'Y';

                     if v_clawback_amt >= p_fee_amt
                     then
                         p_process_msg := 'Fee Amount Will Be Collected Through Clawback';

                     end if;


                   Exception when no_data_found
                   then
                        p_process_msg := 'Fee not debited';
                        v_fee_amt := 0;

                   when others
                   then
                         p_resp_msg := 'Error While clawback check '||substr(sqlerrm,1,100);
                         raise exp_reject_record;

                   END;

            when exp_reject_record
            then
                 raise;

            when others
            then
                     v_errmsg := 'Error While fetching fee amount '||substr(sqlerrm,1,100);
                     RAISE exp_reject_record;
            END;


           BEGIN

                if p_process_msg is null
                then

                      if  p_fee_amt = v_fee_amt
                      then

                         p_process_msg := 'Fee Debited Successfully';
                         p_fee_amt := v_fee_amt;


                      elsif v_fee_amt = 0
                      then

                        p_process_msg := 'Fee not Debited. Complementary';
                        p_fee_amt := v_fee_amt;

                      elsif p_fee_amt > v_fee_amt
                      then

                        p_process_msg := 'Fee Debited Partially. Balance fee Will Be Collected Through Clawback';
                        p_fee_amt := v_fee_amt;

                      end if;

                end if;


           exception when others
           then
                 v_errmsg := 'Error while assigning fee amt and message '||substr(sqlerrm,1,100);
                 RAISE exp_reject_record;

           END;


       END IF;

       -------------------------------------------------------------------
       --EN: Added by sagar on 28-Aug-2012 to fetch additional fee details
       -------------------------------------------------------------------




   EXCEPTION
      WHEN exp_reject_record
      THEN
         ROLLBACK;

         BEGIN
            SELECT cms_iso_respcde
              INTO p_resp_code
              FROM cms_response_mast
             WHERE cms_inst_code = p_inst_code
               AND cms_delivery_channel = p_delivery_channel
               AND cms_response_id = v_resp_cde;

            p_resp_msg := v_errmsg;
         EXCEPTION
            WHEN OTHERS
            THEN
               p_resp_msg :=
                     'Problem while selecting data from response master1 '
                  || v_resp_cde
                  || SUBSTR (SQLERRM, 1, 100);
               p_resp_code := '89';
               ROLLBACK;
               RETURN;
         END;

         BEGIN
            INSERT INTO cms_transaction_log_dtl
                        (ctd_delivery_channel, ctd_txn_code, ctd_txn_type,
                         ctd_txn_mode, ctd_business_date, ctd_business_time,
                         ctd_customer_card_no, ctd_txn_amount, ctd_txn_curr,
                         ctd_actual_amount, ctd_fee_amount,
                         ctd_waiver_amount, ctd_servicetax_amount,
                         ctd_cess_amount, ctd_bill_amount, ctd_bill_curr,
                         ctd_process_flag, ctd_process_msg, ctd_rrn,
                         ctd_system_trace_audit_no,
                         ctd_customer_card_no_encr, ctd_msg_type,
                         ctd_cust_acct_number, ctd_inst_code
                        )
                 VALUES (p_delivery_channel, p_txn_code, NULL,
                         p_txn_mode, p_tran_date, p_tran_time,
                         v_hash_pan, NULL, v_base_curr,
                         NULL, NULL,
                         NULL, NULL,
                         NULL, NULL, NULL,
                         'E', v_errmsg, p_rrn,
                         p_stan,
                         v_encr_pan, p_msg_type,
                         v_cap_acct_no, p_inst_code
                        );

            p_resp_msg := v_errmsg;
         EXCEPTION
            WHEN OTHERS
            THEN
               p_resp_code := '89';
               p_resp_msg :=
                     'Problem while inserting data into transaction_log_dtl1'
                  || SUBSTR (SQLERRM, 1, 300);
               ROLLBACK;
               RETURN;
         END;

        if v_acct_bal is null --If condition Added for defect 10871
        then

             BEGIN
                SELECT cam_acct_bal, cam_ledger_bal,
                       cam_type_code                    --Added for defect 10871
                  INTO v_acct_bal, v_ledger_bal,
                       v_cam_type_code                  --Added for defect 10871
                  FROM cms_acct_mast
                 WHERE cam_inst_code = p_inst_code AND cam_acct_no = v_cap_acct_no;
             EXCEPTION
                WHEN OTHERS
                THEN
                   v_acct_bal := 0;
                   v_ledger_bal := 0;
             END;

        end if;


     -----------------------------------------------
     --SN: Added on 19-Apr-2013 for defect 10871
     -----------------------------------------------


       if v_cap_acct_no is null
       then

         BEGIN
            SELECT cap_acct_no, cap_prod_code, cap_card_type,
                   cap_proxy_number,
                   cap_card_stat                                --Added for defect 10871
              INTO v_cap_acct_no, v_cap_prod_code, v_cap_card_type,
                   v_cap_proxynumber,
                   v_applpan_cardstat                           --Added for defect 10871
              FROM cms_appl_pan
             WHERE cap_inst_code = p_inst_code AND cap_pan_code = v_hash_pan;
         EXCEPTION
            WHEN OTHERS
            THEN
              NULL;
         END;

       end if;

      if v_dr_cr_flag is null
      then

         BEGIN

             SELECT ctm_credit_debit_flag, ctm_tran_type,
                    TO_NUMBER (DECODE (ctm_tran_type, 'N', '0', 'F', '1')),
                    ctm_tran_desc
               INTO v_dr_cr_flag, v_tran_type,
                    v_txn_type,
                    v_tran_desc
               FROM cms_transaction_mast
              WHERE ctm_tran_code = p_txn_code
                AND ctm_delivery_channel = p_delivery_channel
                AND ctm_inst_code = p_inst_code;
         EXCEPTION WHEN OTHERS
         THEN
             null;

         END;

      end if;

      v_timestamp := systimestamp;              -- Added on 19-Apr-2013 for defect 10871

     -----------------------------------------------
     --EN: Added on 19-Apr-2013 for defect 10871
     -----------------------------------------------


         --Sn create a entry in txn log
         BEGIN
            INSERT INTO transactionlog
                        (msgtype, rrn, delivery_channel,
                         date_time,
                         txn_code, txn_type, txn_mode,
                         txn_status, response_code,
                         business_date, business_time, customer_card_no,
                         total_amount,
                         currencycode, productid, categoryid,
                         trans_desc,
                         amount,
                         system_trace_audit_no, instcode, cr_dr_flag,
                         customer_card_no_encr, proxy_number,
                         customer_acct_no, acct_balance, ledger_balance,
                         response_id, error_msg, tranfee_amt, remark,csr_achactiontaken,
                         add_ins_date,add_ins_user,add_lupd_user, --added  by sagar on 25SEP2012
                         ipaddress, --added by amit on 06-Oct-2012 to log ipaddress in transactionlog table
                         acct_type,  --added for defect 10871
                         time_stamp, --added  for defect 10871
                         cardstatus  --added  for defect 10871
                        )
                 VALUES (p_msg_type, p_rrn, p_delivery_channel,
                         TO_DATE (p_tran_date || ' ' || p_tran_time,
                                  'yyyymmdd hh24miss'
                                 ),
                         p_txn_code, NULL, p_txn_mode,
                         DECODE (p_resp_code, '00', 'C', 'F'), p_resp_code,
                         p_tran_date, p_tran_time, v_hash_pan,
                         TRIM (TO_CHAR (nvl(v_total_fee,0), '99999999999999990.99')), --NVL added for defect 10871
                         v_base_curr, v_cap_prod_code, v_cap_card_type,
                         v_tran_desc,--Updated by Dnyaneshwar J on 11 June 2013 for Defect 0011178
                         TRIM (TO_CHAR (0, '999999999999999990.99')),
                         p_stan, p_inst_code, v_dr_cr_flag,
                         v_encr_pan, v_cap_proxynumber,
                         v_cap_acct_no, v_acct_bal, v_ledger_bal,
                         v_resp_cde, v_errmsg, v_total_fee, p_remark,p_fee_calc,
                         sysdate,p_ins_user,p_ins_user, --added  by sagar on 25SEP2012
                         p_ipaddress,  --added by amit on 06-Oct-2012 to log ipaddress in transactionlog table
                         v_cam_type_code,       --added for defect 10871
                         v_timestamp,           --added  for defect 10871
                         v_applpan_cardstat   --added  for defect 10871
                        );

            p_resp_msg := v_errmsg;
         EXCEPTION
            WHEN OTHERS
            THEN
               ROLLBACK;
               p_resp_code := '89';
               p_resp_msg :=
                     'Problem while inserting data into transactionlog1 '
                  || SUBSTR (SQLERRM, 1, 300);
               RETURN;
         END;
      WHEN OTHERS
      THEN
         ROLLBACK;

         BEGIN
            SELECT cms_iso_respcde
              INTO p_resp_code
              FROM cms_response_mast
             WHERE cms_inst_code = p_inst_code
               AND cms_delivery_channel = p_delivery_channel
               AND cms_response_id = v_resp_cde;

            p_resp_msg := v_errmsg;
         EXCEPTION
            WHEN OTHERS
            THEN
               p_resp_msg :=
                     'Problem while selecting data from response master1 '
                  || v_resp_cde
                  || SUBSTR (SQLERRM, 1, 100);
               p_resp_code := '89';
               ROLLBACK;
               RETURN;
         END;

         BEGIN
            INSERT INTO cms_transaction_log_dtl
                        (ctd_delivery_channel, ctd_txn_code, ctd_txn_type,
                         ctd_txn_mode, ctd_business_date, ctd_business_time,
                         ctd_customer_card_no, ctd_txn_amount, ctd_txn_curr,
                         ctd_actual_amount, ctd_fee_amount,
                         ctd_waiver_amount, ctd_servicetax_amount,
                         ctd_cess_amount, ctd_bill_amount, ctd_bill_curr,
                         ctd_process_flag, ctd_process_msg, ctd_rrn,
                         ctd_system_trace_audit_no,
                         ctd_customer_card_no_encr, ctd_msg_type,
                         ctd_cust_acct_number, ctd_inst_code
                        )
                 VALUES (p_delivery_channel, p_txn_code, NULL,
                         p_txn_mode, p_tran_date, p_tran_time,
                         v_hash_pan, NULL, v_base_curr,
                         NULL, NULL,
                         NULL, NULL,
                         NULL, NULL, NULL,
                         'E', v_errmsg, p_rrn,
                         p_stan,
                         v_encr_pan, p_msg_type,
                         v_cap_acct_no, p_inst_code
                        );

            p_resp_msg := v_errmsg;
         EXCEPTION
            WHEN OTHERS
            THEN
               p_resp_code := '89';
               p_resp_msg :=
                     'Problem while inserting data into transaction_log_dtl2'
                  || SUBSTR (SQLERRM, 1, 300);
               ROLLBACK;
               RETURN;
         END;

        if v_acct_bal is null --If condition Added for defect 10871
         then

             BEGIN
                SELECT cam_acct_bal, cam_ledger_bal
                  INTO v_acct_bal, v_ledger_bal
                  FROM cms_acct_mast
                 WHERE cam_inst_code = p_inst_code AND cam_acct_no = v_cap_acct_no;
             EXCEPTION
                WHEN OTHERS
                THEN
                   v_acct_bal := 0;
                   v_ledger_bal := 0;
             END;

        end if;


     -----------------------------------------------
     --SN: Added on 19-Apr-2013 for defect 10871
     -----------------------------------------------


       if v_cap_acct_no is null
       then

         BEGIN
            SELECT cap_acct_no, cap_prod_code, cap_card_type,
                   cap_proxy_number,
                   cap_card_stat                                --Added for defect 10871
              INTO v_cap_acct_no, v_cap_prod_code, v_cap_card_type,
                   v_cap_proxynumber,
                   v_applpan_cardstat                           --Added for defect 10871
              FROM cms_appl_pan
             WHERE cap_inst_code = p_inst_code AND cap_pan_code = v_hash_pan;
         EXCEPTION
            WHEN OTHERS
            THEN
              NULL;
         END;

       end if;

      if v_dr_cr_flag is null
      then

         BEGIN

             SELECT ctm_credit_debit_flag, ctm_tran_type,
                    TO_NUMBER (DECODE (ctm_tran_type, 'N', '0', 'F', '1')),
                    ctm_tran_desc
               INTO v_dr_cr_flag, v_tran_type,
                    v_txn_type,
                    v_tran_desc
               FROM cms_transaction_mast
              WHERE ctm_tran_code = p_txn_code
                AND ctm_delivery_channel = p_delivery_channel
                AND ctm_inst_code = p_inst_code;
         EXCEPTION WHEN OTHERS
         THEN
             null;

         END;

      end if;

      v_timestamp := systimestamp;              -- Added on 19-Apr-2013 for defect 10871

     -----------------------------------------------
     --EN: Added on 19-Apr-2013 for defect 10871
     -----------------------------------------------

         --Sn create a entry in txn log
         BEGIN
            INSERT INTO transactionlog
                        (msgtype, rrn, delivery_channel,
                         date_time,
                         txn_code, txn_type, txn_mode,
                         txn_status, response_code,
                         business_date, business_time, customer_card_no,
                         total_amount,
                         currencycode, productid, categoryid,
                         trans_desc,
                         amount,
                         system_trace_audit_no, instcode, cr_dr_flag,
                         customer_card_no_encr, proxy_number,
                         customer_acct_no, acct_balance, ledger_balance,
                         response_id, error_msg, tranfee_amt, remark,csr_achactiontaken,
                         add_ins_date,add_ins_user,add_lupd_user, --added  by sagar on 25SEP2012
                         ipaddress, --added by amit on 06-Oct-2012 to log ipaddress in transactionlog table
                         acct_type,  --added for defect 10871
                         time_stamp, --added  for defect 10871
                         cardstatus  --added  for defect 10871
                        )
                 VALUES (p_msg_type, p_rrn, p_delivery_channel,
                         TO_DATE (p_tran_date || ' ' || p_tran_time,
                                  'yyyymmdd hh24miss'
                                 ),
                         p_txn_code, NULL, p_txn_mode,
                         DECODE (p_resp_code, '00', 'C', 'F'), p_resp_code,
                         p_tran_date, p_tran_time, v_hash_pan,
                         TRIM (TO_CHAR (nvl(v_total_fee,0), '99999999999999990.99')),
                         v_base_curr, v_cap_prod_code, v_cap_card_type,
                         v_tran_desc,--Updated by Dnyaneshwar J on 11 June 2013 for Defect 0011178
                         TRIM (TO_CHAR (0, '999999999999999990.99')),
                         p_stan, p_inst_code,v_dr_cr_flag,
                         v_encr_pan, v_cap_proxynumber,
                         v_cap_acct_no, v_acct_bal, v_ledger_bal,
                         v_resp_cde, v_errmsg, v_total_fee, p_remark,p_fee_calc,
                         sysdate,p_ins_user,p_ins_user, --added  by sagar on 25SEP2012
                         p_ipaddress,  --added by amit on 06-Oct-2012 to log ipaddress in transactionlog table
                         v_cam_type_code,       --added for defect 10871
                         v_timestamp,           --added  for defect 10871
                         v_applpan_cardstat   --added  for defect 10871
                        );

            p_resp_msg := v_errmsg;
         EXCEPTION
            WHEN OTHERS
            THEN
               ROLLBACK;
               p_resp_code := '89';
               p_resp_msg :=
                     'Problem while inserting data into transactionlog2 '
                  || SUBSTR (SQLERRM, 1, 300);
               RETURN;
         END;
   END;
END;
/

show error
