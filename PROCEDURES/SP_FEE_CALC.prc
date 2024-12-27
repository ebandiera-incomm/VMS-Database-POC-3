create or replace PROCEDURE        vmscms.SP_FEE_CALC (
   p_inst_code           IN       NUMBER,
   p_msg_type            IN       VARCHAR2,
   p_rrn                 IN       VARCHAR2,
   p_delivery_channel    IN       cms_delchannel_mast.cdm_channel_code%TYPE,
   p_txn_code            IN       VARCHAR2,
   p_txn_mode            IN       VARCHAR2,
   p_tran_date           IN       VARCHAR2,
   p_tran_time           IN       VARCHAR2,
   p_mbr_numb            IN       VARCHAR2,
   p_rvsl_code           IN       VARCHAR2,
   p_tran_type           IN       cms_transaction_mast.ctm_tran_type%TYPE,
   p_curr_code           IN       VARCHAR2,
   p_tran_amount         IN       VARCHAR2,
   p_pan_code            IN       VARCHAR2,
   p_hash_pan            IN       cms_appl_pan.cap_pan_code%TYPE,
   p_encr_pan            IN       cms_appl_pan.cap_pan_code_encr%TYPE,
   p_acct_no             IN       cms_appl_pan.cap_acct_no%TYPE,
   p_prod_code           IN       cms_appl_pan.cap_prfl_code%TYPE,
   p_card_type           IN       cms_appl_pan.cap_card_type%TYPE,
   p_preauth_flag        IN       cms_transaction_mast.ctm_preauth_flag%TYPE
         DEFAULT 'N',
   p_mcc_code            IN       VARCHAR2,
   p_international_ind   IN       VARCHAR2,
   p_pos_verfication     IN       VARCHAR2,
   p_trans_desc          IN       cms_transaction_mast.ctm_tran_desc%TYPE,
   p_drcr_flag           IN       cms_transaction_mast.ctm_credit_debit_flag%TYPE,
   p_acct_bal            IN       cms_acct_mast.cam_acct_bal%TYPE,
   p_led_bal             IN       cms_acct_mast.cam_ledger_bal%TYPE,
   p_acct_type           IN       cms_acct_mast.cam_type_code%TYPE,
   p_login_txn           IN       cms_transaction_mast.ctm_login_txn%TYPE,
   p_auth_id             IN       VARCHAR2,
   v_time_stamp          IN       transactionlog.time_stamp%TYPE,
   p_resp_code           OUT      VARCHAR2,
   p_res_msg             OUT      VARCHAR2,
   p_fee_code            OUT      VARCHAR2,
   p_fee_plan            OUT      VARCHAR2,
   p_feeattach_type      OUT      VARCHAR2,
   p_total_fee           OUT      VARCHAR2,
   p_total_amt           OUT      VARCHAR2,
   p_feerev_compfee         IN out        varchar2  ,
   p_comp_freetxn_exceed out       varchar2,
   p_comp_feecode out       varchar2 ,
   p_preauth_type        in       varchar2 default null,
   p_card_stat           in       varchar2 default null,
   p_hold_amount         IN       varchar2  default null
)
AS

    /*************************************************
   * Modified by       : Raja Gopal G
   * modified Date     : 13-Aug-14
   * Reviewer          : Spankaj
   * Release Number    : RI0027.3.1_B0003

   * Modified by       : MageshKumar S
   * modified Date     : 27-Nov-14
   * modified reason   : Mantis Id:15916
   * Reviewer          : Spankaj
   * Release Number    : RI0027.4.3_B0007

    * Modified by       : Abdul Hameed M.A
    * Modified Date     : 23-June-15
    * Modified For      : FSS 1960
    * Reviewer          : Pankaj S
    * Build Number      : VMSGPRHOSTCSD_3.1_B0001

        * Modified By      : Saravana Kumar A
    * Modified Date    : 07/07/2017
    * Purpose          : Prod code and card type logging in statements log
    * Reviewer         : Pankaj S.
    * Release Number   : VMSGPRHOST17.07
	
	  * Modified by                 : DHINAKARAN B
  * Modified Date               : 26-NOV-2019
  * Modified For                : VMS-1415
  * Reviewer                    :  Saravana Kumar A
  * Build Number                :  VMSGPRHOST_R23_B1
   /*************************************************/

   v_trans_desc           cms_transaction_mast.ctm_tran_desc%TYPE;
   v_tran_date            DATE;
   v_err_msg              VARCHAR2 (500);
   exp_reject_record      EXCEPTION;
   v_tran_amt             NUMBER;
   v_resp_cde             VARCHAR2 (5);
   v_acct_balance         cms_acct_mast.cam_acct_bal%TYPE;
   v_ledger_bal           cms_acct_mast.cam_ledger_bal%TYPE;
   v_acct_type            cms_acct_mast.cam_type_code%TYPE;
   v_fee_amt              NUMBER;
   v_error                VARCHAR2 (500);
   v_fee_code             cms_fee_mast.cfm_fee_code%TYPE;
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
   v_err_waiv             VARCHAR2 (300);
   v_log_actual_fee       NUMBER;
   v_log_waiver_amt       NUMBER;
   v_feeamnt_type         cms_fee_mast.cfm_feeamnt_type%TYPE;
   v_per_fees             cms_fee_mast.cfm_per_fees%TYPE;
   v_flat_fees            cms_fee_mast.cfm_fee_amt%TYPE;
   v_clawback             cms_fee_mast.cfm_clawback_flag%TYPE;
   v_fee_plan             cms_fee_feeplan.cff_fee_plan%TYPE;
   v_freetxn_exceed       VARCHAR2 (1);
   v_duration             VARCHAR2 (20);
   v_feeattach_type       VARCHAR2 (2);
   v_fee_desc             cms_fee_mast.cfm_fee_desc%TYPE;
   v_total_fee            NUMBER;
   v_upd_amt              NUMBER;
   v_upd_ledger_bal       NUMBER;
   v_narration            VARCHAR2 (300);
   v_total_amt            NUMBER;
   v_func_code            cms_func_mast.cfm_func_code%TYPE;
   v_timestamp            TIMESTAMP ( 3 );
   v_fee_opening_bal      NUMBER;
   v_dr_cr_flag           VARCHAR2 (2);
   v_clawback_amnt        cms_fee_mast.cfm_fee_amt%TYPE;
   v_actual_fee_amnt      NUMBER;
   v_clawback_count       NUMBER;
   v_tot_clwbck_count     cms_fee_mast.cfm_clawback_count%TYPE;
   v_chrg_dtl_cnt         NUMBER;
   v_cutoff_time          VARCHAR2 (5);
   V_MAX_CARD_BAL     NUMBER;
   v_chnge_crdstat   VARCHAR2(2):='N';
   v_hold_amount        NUMBER;
   
   v_completion_txn_code VARCHAR2(2);
   v_comp_fee_code             cms_fee_mast.cfm_fee_code%TYPE;
   v_comp_fee_crgl_catg        cms_prodcattype_fees.cpf_crgl_catg%TYPE;
   v_comp_fee_crgl_code        cms_prodcattype_fees.cpf_crgl_code%TYPE;
   v_comp_fee_crsubgl_code     cms_prodcattype_fees.cpf_crsubgl_code%TYPE;
   v_comp_fee_cracct_no        cms_prodcattype_fees.cpf_cracct_no%TYPE;
   v_comp_fee_drgl_catg        cms_prodcattype_fees.cpf_drgl_catg%TYPE;
   v_comp_fee_drgl_code        cms_prodcattype_fees.cpf_drgl_code%TYPE;
   v_comp_fee_drsubgl_code     cms_prodcattype_fees.cpf_drsubgl_code%TYPE;
   v_comp_fee_dracct_no        cms_prodcattype_fees.cpf_dracct_no%TYPE;
   v_comp_servicetax_percent   cms_inst_param.cip_param_value%TYPE;
   v_comp_cess_percent         cms_inst_param.cip_param_value%TYPE;
   v_comp_servicetax_amount    NUMBER;
   v_comp_cess_amount          NUMBER;
   v_comp_st_calc_flag         cms_prodcattype_fees.cpf_st_calc_flag%TYPE;
   v_comp_cess_calc_flag       cms_prodcattype_fees.cpf_cess_calc_flag%TYPE;
   v_comp_st_cracct_no         cms_prodcattype_fees.cpf_st_cracct_no%TYPE;
   v_comp_st_dracct_no         cms_prodcattype_fees.cpf_st_dracct_no%TYPE;
   v_comp_cess_cracct_no       cms_prodcattype_fees.cpf_cess_cracct_no%TYPE;
   v_comp_cess_dracct_no       cms_prodcattype_fees.cpf_cess_dracct_no%TYPE;
   v_comp_waiv_percnt          cms_prodcattype_waiv.cpw_waiv_prcnt%TYPE;
   v_comp_feeamnt_type         cms_fee_mast.cfm_feeamnt_type%TYPE;
   v_comp_per_fees             cms_fee_mast.cfm_per_fees%TYPE;
   v_comp_flat_fees            cms_fee_mast.cfm_fee_amt%TYPE;
   v_comp_clawback             cms_fee_mast.cfm_clawback_flag%TYPE;
   v_comp_fee_plan             cms_fee_feeplan.cff_fee_plan%TYPE;
   v_comp_freetxn_exceed       VARCHAR2 (1);
   v_comp_duration             VARCHAR2 (20);
   v_comp_feeattach_type       VARCHAR2 (2);
   v_comp_fee_amt              NUMBER;
   v_comp_err_waiv             VARCHAR2 (300);
   V_COMP_FEE_DESC             cms_fee_mast.cfm_fee_desc%TYPE;
   v_comp_error                VARCHAR2 (500);
   v_comp_total_fee            NUMBER:=0;
   v_complfee_applicable             VARCHAR2 (1);
    v_comp_fee_hold             NUMBER;
    v_complfee_increment_type   VARCHAR2 (1);
      v_tot_hold_amt              NUMBER;
      v_feerev_compfee             NUMBER;
BEGIN
   v_acct_balance := p_acct_bal;
   v_ledger_bal := p_led_bal;
   v_acct_type := p_acct_type;
   v_dr_cr_flag := p_drcr_flag;
   v_tran_amt := p_tran_amount;

   --En find function code attached to txn code

   --Sn find service tax
   BEGIN
      SELECT cip_param_value
        INTO v_servicetax_percent
        FROM cms_inst_param
       WHERE cip_param_key = 'SERVICETAX' AND cip_inst_code = p_inst_code;
   EXCEPTION
      WHEN NO_DATA_FOUND
      THEN
         v_resp_cde := '21';
         v_err_msg := 'Service Tax is  not defined in the system';
         RAISE exp_reject_record;
      WHEN OTHERS
      THEN
         v_resp_cde := '21';
         v_err_msg := 'Error while selecting service tax from system ';
         RAISE exp_reject_record;
   END;

   --En find service tax

   --Sn find cess
   BEGIN
      SELECT cip_param_value
        INTO v_cess_percent
        FROM cms_inst_param
       WHERE cip_param_key = 'CESS' AND cip_inst_code = p_inst_code;
   EXCEPTION
      WHEN NO_DATA_FOUND
      THEN
         v_resp_cde := '21';
         v_err_msg := 'Cess is not defined in the system';
         RAISE exp_reject_record;
      WHEN OTHERS
      THEN
         v_resp_cde := '21';
         v_err_msg := 'Error while selecting cess from system ';
         RAISE exp_reject_record;
   END;

   --En find cess

   ---Sn find cutoff time
   BEGIN
      SELECT cip_param_value
        INTO v_cutoff_time
        FROM cms_inst_param
       WHERE cip_param_key = 'CUTOFF' AND cip_inst_code = p_inst_code;
   EXCEPTION
      WHEN NO_DATA_FOUND
      THEN
         v_cutoff_time := 0;
         v_resp_cde := '21';
         v_err_msg := 'Cutoff time is not defined in the system';
         RAISE exp_reject_record;
      WHEN OTHERS
      THEN
         v_resp_cde := '21';
         v_err_msg := 'Error while selecting cutoff  dtl  from system ';
         RAISE exp_reject_record;
   END;

   ---En find cutoff time

   --Sn get tran date
   BEGIN
      v_tran_date :=
         TO_DATE (   SUBSTR (TRIM (p_tran_date), 1, 8)
                  || ' '
                  || SUBSTR (TRIM (p_tran_time), 1, 10),
                  'yyyymmdd hh24:mi:ss'
                 );
   EXCEPTION
      WHEN OTHERS
      THEN
         v_resp_cde := '21';
         v_err_msg :=
               'Problem while converting transaction date '
            || SUBSTR (SQLERRM, 1, 200);
         RAISE exp_reject_record;
   END;

   --En get tran date
   --Start Fee
   BEGIN
      sp_tran_fees_cmsauth (p_inst_code,
                            p_pan_code,
                            p_delivery_channel,
                            p_tran_type,
                            p_txn_mode,
                            p_txn_code,
                            p_curr_code,
                            NULL,
                            NULL,
                            v_tran_amt,
                            v_tran_date,
                            NULL,
                            NULL,
                            v_resp_cde,
                            p_msg_type,
                            p_rvsl_code,
                            NULL,
                            v_fee_amt,
                            v_error,
                            v_fee_code,
                            v_fee_crgl_catg,
                            v_fee_crgl_code,
                            v_fee_crsubgl_code,
                            v_fee_cracct_no,
                            v_fee_drgl_catg,
                            v_fee_drgl_code,
                            v_fee_drsubgl_code,
                            v_fee_dracct_no,
                            v_st_calc_flag,
                            v_cess_calc_flag,
                            v_st_cracct_no,
                            v_st_dracct_no,
                            v_cess_cracct_no,
                            v_cess_dracct_no,
                            v_feeamnt_type,
                            v_clawback,
                            v_fee_plan,
                            v_per_fees,
                            v_flat_fees,
                            v_freetxn_exceed,
                            v_duration,
                            v_feeattach_type,
                            v_fee_desc
                           );

      IF v_error <> 'OK'
      THEN
         v_resp_cde := '21';
         v_err_msg := v_error;
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
                   'Error from fee calc process ' || SUBSTR (SQLERRM, 1, 200);
         RAISE exp_reject_record;
   END;

   ---En dynamic fee calculation .

   --Sn calculate waiver on the fee
   BEGIN
      sp_calculate_waiver (p_inst_code,
                           p_pan_code,
                           '000',
                           p_prod_code,
                           p_card_type,
                           v_fee_code,
                           v_fee_plan,
                           v_tran_date,
                           v_waiv_percnt,
                           v_err_waiv
                          );

      IF v_err_waiv <> 'OK'
      THEN
         v_resp_cde := '21';
         v_err_msg := v_err_waiv;
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
                'Error from waiver calc process ' || SUBSTR (SQLERRM, 1, 200);
         RAISE exp_reject_record;
   END;

   --En calculate waiver on the fee

   --Sn apply waiver on fee amount
   v_log_actual_fee := v_fee_amt;
   v_fee_amt := ROUND (v_fee_amt - ((v_fee_amt * v_waiv_percnt) / 100), 2);
   v_log_waiver_amt := v_log_actual_fee - v_fee_amt;

   --only used to log in log table

   --En apply waiver on fee amount

   --Sn apply service tax and cess
   IF v_st_calc_flag = 1
   THEN
      v_servicetax_amount := (v_fee_amt * v_servicetax_percent) / 100;
   ELSE
      v_servicetax_amount := 0;
   END IF;

   IF v_cess_calc_flag = 1
   THEN
      v_cess_amount := (v_servicetax_amount * v_cess_percent) / 100;
   ELSE
      v_cess_amount := 0;
   END IF;

   v_total_fee := ROUND (v_fee_amt + v_servicetax_amount + v_cess_amount, 2);

   --End Fee calculation
      
   
   
    IF p_hold_amount IS NULL OR p_hold_amount='0' THEN
     V_hold_amount  :=0;
    ELSE
     SELECT TO_NUMBER(SUBSTR(p_hold_amount, 1, LENGTH(p_hold_amount) - 2))
       INTO V_hold_amount
     FROM DUAL;
    END IF;
     IF p_msg_type='0100' THEN 
        v_feerev_compfee :=0;
        else
        v_feerev_compfee :=nvl(p_feerev_compfee,0);
    END IF;
    v_tot_hold_amt :=v_tran_amt;
  --settlement fee 
        BEGIN
            SELECT vft_completion_fee
            INTO v_complfee_applicable
            FROM vms_fsapi_trans_mast
            WHERE vft_channel_code = p_delivery_channel
                AND   vft_tran_code = p_txn_code
                AND   vft_msg_type = p_msg_type;
        EXCEPTION
            WHEN OTHERS THEN
                v_complfee_applicable :='N';
        END;

IF v_complfee_applicable = 'Y'  THEN
    BEGIN
        IF( v_tran_amt = 0 ) THEN
            v_comp_fee_amt := 0;
            v_comp_fee_hold := 0;
        ELSE
            BEGIN
                SELECT cpt_compl_txncode
                INTO v_completion_txn_code
                FROM cms_preauthcomp_txncode
                WHERE cpt_inst_code = p_inst_code
                    AND   cpt_preauth_txncode = p_txn_code;
            EXCEPTION
                WHEN no_data_found THEN
                    v_completion_txn_code := '00';
                WHEN OTHERS THEN
                    v_resp_cde := '21';
                    v_err_msg := 'Error while selecting data for Completion transaction code '
                    || sqlerrm;
                    RAISE exp_reject_record;
            END;

            BEGIN
                sp_tran_fees_cmsauth(p_inst_code,
                                     p_pan_code,
                                     p_delivery_channel,
                                     '1',
                                     p_txn_mode,
                                     v_completion_txn_code,
                                     p_curr_code,
                                     NULL,
                                     NULL,
                                     v_tran_amt,
                                     v_tran_date,
                                     p_international_ind,
                                     p_pos_verfication,
                                     v_resp_cde,
                                     '0200',
                                     p_rvsl_code,
                                     p_mcc_code,
                                     v_comp_fee_amt,
                                     v_comp_error,
                                     v_comp_fee_code,
                                     v_comp_fee_crgl_catg,
                                     v_comp_fee_crgl_code,
                                     v_comp_fee_crsubgl_code,
                                     v_comp_fee_cracct_no,
                                     v_comp_fee_drgl_catg,
                                     v_comp_fee_drgl_code,
                                     v_comp_fee_drsubgl_code,
                                     v_comp_fee_dracct_no,
                                     v_comp_st_calc_flag,
                                     v_comp_cess_calc_flag,
                                     v_comp_st_cracct_no,
                                     v_comp_st_dracct_no,
                                     v_comp_cess_cracct_no,
                                     v_comp_cess_dracct_no,
                                     v_comp_feeamnt_type,
                                     v_comp_clawback,
                                     v_comp_fee_plan,
                                     v_comp_per_fees,
                                     v_comp_flat_fees,
                                     v_comp_freetxn_exceed,
                                     v_comp_duration,
                                     v_comp_feeattach_type,
                                     v_comp_fee_desc);

                IF v_comp_error <> 'OK' THEN
                    v_resp_cde := '21';
                    v_err_msg := v_comp_error;
                    RAISE exp_reject_record;
                END IF;

            EXCEPTION
                WHEN exp_reject_record THEN
                    RAISE;
                WHEN OTHERS THEN
                    v_resp_cde := '21';
                    v_err_msg := 'Error from fee calc process '
                    || substr(sqlerrm,1,200);
                    RAISE exp_reject_record;
            END;

            IF v_comp_freetxn_exceed = 'N' THEN
                BEGIN
                    vmsfee.fee_freecnt_reverse(p_acct_no,v_comp_fee_code,v_err_msg);
                    IF v_err_msg <> 'OK' THEN
                        v_resp_cde := '21';
                        RAISE exp_reject_record;
                    END IF;
                EXCEPTION
                    WHEN exp_reject_record THEN
                        RAISE;
                    WHEN OTHERS THEN
                        v_resp_cde := '21';
                        v_err_msg := 'Error from fee count reverse procedure '
                        || substr(sqlerrm,1,200);
                        RAISE exp_reject_record;
                END;
            END IF;
        
        --Sn calculate waiver on the fee

            BEGIN
                sp_calculate_waiver(p_inst_code,
                                    p_pan_code,
                                    '000',
                                    p_prod_code,
                                    p_card_type,
                                    v_comp_fee_code,
                                    v_comp_fee_plan,
                                    v_tran_date,
                                    v_comp_waiv_percnt,
                                    v_comp_err_waiv);

                IF v_comp_err_waiv <> 'OK' THEN
                    v_resp_cde := '21';
                    v_err_msg := v_comp_err_waiv;
                    RAISE exp_reject_record;
                END IF;

            EXCEPTION
                WHEN exp_reject_record THEN
                    RAISE;
                WHEN OTHERS THEN
                    v_resp_cde := '21';
                    v_err_msg := 'Error from waiver calc process '
                    || substr(sqlerrm,1,200);
                    RAISE exp_reject_record;
            END;

      --En calculate waiver on the fee
      
       --Sn apply waiver on fee amount

            v_comp_fee_amt := round(v_comp_fee_amt - ( (v_comp_fee_amt * v_comp_waiv_percnt) / 100),2);

      --En apply waiver on fee amount

      --Sn apply service tax and cess

            IF v_comp_st_calc_flag = 1 THEN
                v_comp_servicetax_amount := ( v_comp_fee_amt * v_comp_servicetax_percent ) / 100;
            ELSE
                v_comp_servicetax_amount := 0;
            END IF;

            IF v_comp_cess_calc_flag = 1 THEN
                v_comp_cess_amount := ( v_comp_servicetax_amount * v_comp_cess_percent ) / 100;
            ELSE
                v_comp_cess_amount := 0;
            END IF;

            v_comp_total_fee := round(v_comp_fee_amt + v_comp_servicetax_amount + v_comp_cess_amount,2);
            
  
      --En apply service tax and cess
      
            v_comp_fee_hold := v_comp_total_fee;
            IF (p_preauth_type = 'D') THEN 
            p_feerev_compfee := v_comp_total_fee;
            END IF;
            IF v_comp_total_fee > '0' THEN
                IF (v_tran_amt + v_total_fee + v_comp_total_fee+v_feerev_compfee) > v_acct_balance THEN
                     v_resp_cde := '15';
                    v_err_msg := 'Insufficient Balance';
                    RAISE exp_reject_record;
                ELSE
                   v_tot_hold_amt := v_tran_amt + v_comp_total_fee;
               END IF;
            ELSE
                v_tot_hold_amt := v_tran_amt;
            END IF;
        END IF;
    EXCEPTION
        WHEN exp_reject_record THEN
            RAISE;
        WHEN OTHERS THEN
            v_resp_cde := '21';
            v_err_msg := 'Error from fee calc process excp '
            || substr(sqlerrm,1,200);
            RAISE exp_reject_record;
    END;
END IF;
   --settlement fee 
   
  
   
   --Sn find total transaction    amount
   
   
   IF v_dr_cr_flag = 'CR'
   THEN
      v_total_amt := v_tran_amt - v_total_fee;
      v_upd_amt := v_acct_balance + v_total_amt;
      v_upd_ledger_bal := v_ledger_bal + v_total_amt;
   ELSIF v_dr_cr_flag = 'DR'
   THEN
      v_total_amt := v_tran_amt + v_total_fee;
      v_upd_amt := (v_acct_balance+V_hold_amount+v_feerev_compfee) - v_total_amt;
      v_upd_ledger_bal := (v_ledger_bal) - v_total_amt;
   ELSIF v_dr_cr_flag = 'NA'
   THEN
      IF p_preauth_flag = 'Y'
      THEN
      if(p_preauth_type = 'D') then
           v_total_amt := v_tot_hold_amt + v_total_fee;
           v_upd_amt := v_acct_balance - v_total_amt;
         else
          v_total_amt := v_tot_hold_amt - v_total_fee;
          v_upd_amt := v_acct_balance + v_total_amt;
       end if;
      ELSE
         v_total_amt := v_total_fee;
         v_upd_amt := v_acct_balance - v_total_amt;
      END IF;

      v_tran_amt := v_tot_hold_amt;
      v_upd_ledger_bal := v_ledger_bal - v_total_amt;
   ELSE
      v_resp_cde := '21';                            --Ineligible Transaction
      v_err_msg := 'Invalid transflag txn code ' || p_txn_code;
      RAISE exp_reject_record;
   END IF;

   --En find total transaction    amout


   --ClawBack

   IF (v_dr_cr_flag NOT IN ('NA', 'CR') OR (v_total_fee <> 0))
   THEN
      IF v_upd_amt < 0
      THEN
         IF p_login_txn = 'Y' AND v_clawback = 'Y'
         THEN
            v_actual_fee_amnt := v_total_fee;

            IF (v_acct_balance > 0)
            THEN
               v_clawback_amnt := v_total_fee - v_acct_balance;
               v_fee_amt := v_acct_balance;
            ELSE
               v_clawback_amnt := v_total_fee;
               v_fee_amt := 0;
            END IF;

            --End
            IF v_clawback_amnt > 0
            THEN
               BEGIN
                  SELECT cfm_clawback_count
                    INTO v_tot_clwbck_count
                    FROM cms_fee_mast
                   WHERE cfm_fee_code = v_fee_code;
               EXCEPTION
                  WHEN NO_DATA_FOUND
                  THEN
                     v_resp_cde := '21';
                     v_err_msg :=
                           'Clawback count not configured '
                        || SUBSTR (SQLERRM, 1, 200);
                     RAISE exp_reject_record;
               END;

               BEGIN
                  SELECT COUNT (*)
                    INTO v_chrg_dtl_cnt
                    FROM cms_charge_dtl
                   WHERE ccd_inst_code = p_inst_code
                     AND ccd_delivery_channel = p_delivery_channel
                     AND ccd_txn_code = p_txn_code
                     AND ccd_pan_code = p_hash_pan
                     AND ccd_acct_no = p_acct_no
                     AND ccd_fee_code = v_fee_code
                     AND ccd_clawback = 'Y';
               EXCEPTION
                  WHEN OTHERS
                  THEN
                     v_resp_cde := '21';
                     v_err_msg :=
                           'Error occured while fetching count from cms_charge_dtl'
                        || SUBSTR (SQLERRM, 1, 100);
                     RAISE exp_reject_record;
               END;

               --Sn Clawback Details
               BEGIN
                  SELECT COUNT (*)
                    INTO v_clawback_count
                    FROM cms_acctclawback_dtl
                   WHERE cad_inst_code = p_inst_code
                     AND cad_delivery_channel = p_delivery_channel
                     AND cad_txn_code = p_txn_code
                     AND cad_pan_code = p_hash_pan
                     AND cad_acct_no = p_acct_no;

                  IF v_clawback_count = 0
                  THEN
                     INSERT INTO cms_acctclawback_dtl
                                 (cad_inst_code, cad_acct_no, cad_pan_code,
                                  cad_pan_code_encr, cad_clawback_amnt,
                                  cad_recovery_flag, cad_ins_date,
                                  cad_lupd_date, cad_delivery_channel,
                                  cad_txn_code, cad_ins_user, cad_lupd_user
                                 )
                          VALUES (p_inst_code, p_acct_no, p_hash_pan,
                                  p_encr_pan, ROUND (v_clawback_amnt, 2),
                                  'N', SYSDATE,
                                  SYSDATE, p_delivery_channel,
                                  p_txn_code, '1', '1'
                                 );
                  ELSIF v_chrg_dtl_cnt < v_tot_clwbck_count
                  THEN
                     UPDATE cms_acctclawback_dtl
                        SET cad_clawback_amnt =
                                ROUND (cad_clawback_amnt + v_clawback_amnt, 2),
                            cad_recovery_flag = 'N',
                            cad_lupd_date = SYSDATE
                      WHERE cad_inst_code = p_inst_code
                        AND cad_acct_no = p_acct_no
                        AND cad_pan_code = p_hash_pan
                        AND cad_delivery_channel = p_delivery_channel
                        AND cad_txn_code = p_txn_code;
                  END IF;
               EXCEPTION
                  WHEN OTHERS
                  THEN
                     v_resp_cde := '21';
                     v_err_msg :=
                           'Error while inserting Account ClawBack details'
                        || SUBSTR (SQLERRM, 1, 200);
                     RAISE exp_reject_record;
               END;
            --En Clawback Details
            END IF;

         ELSIF  (v_dr_cr_flag <> 'CR' and nvl(p_preauth_type,'D') <> 'C') THEN
            v_resp_cde := '15';
            v_err_msg := 'Insufficient Balance ';
            RAISE exp_reject_record;
          ELSIF  ( p_preauth_type = 'C' and v_total_fee <> 0) THEN
            v_resp_cde := '15';
            v_err_msg := 'Insufficient Balance ';
            RAISE exp_reject_record;
         END IF;

         v_upd_amt := 0;
         v_upd_ledger_bal := 0;
         v_total_amt := v_tran_amt + v_fee_amt;
      END IF;
   END IF;

   --Sn check balance
   IF v_upd_amt < 0 and v_dr_cr_flag <> 'CR' and  p_preauth_type <> 'C'
   THEN
      v_resp_cde := '15';
      v_err_msg := 'Insufficient Balance ';
      RAISE exp_reject_record;
     ELSIF v_upd_amt < 0 and  ( p_preauth_type = 'C' and v_total_fee <> 0) THEN
       v_resp_cde := '15';
       v_err_msg := 'Insufficient Balance ';
      RAISE exp_reject_record;
   END IF;

   --En check balance
      IF (v_dr_cr_flag='CR') THEN
      BEGIN
             SELECT TO_NUMBER(CBP_PARAM_VALUE)
             INTO V_MAX_CARD_BAL
             FROM CMS_BIN_PARAM
             WHERE CBP_INST_CODE = P_INST_CODE AND
                    CBP_PARAM_NAME = 'Max Card Balance' AND
                    CBP_PROFILE_CODE IN (
                                        SELECT cpc_profile_code
                                        FROM cms_prod_cattype
                                        WHERE CPC_INST_CODE = p_inst_code
                                        and   cpc_prod_code = p_prod_code
                                        and   cpc_card_type = p_card_type
                                        );
      EXCEPTION
         WHEN NO_DATA_FOUND THEN
           V_RESP_CDE := '21';
           V_ERR_MSG  := 'NO DATA CARD BALANCE CONFIGURATION FOR THE PRODUCT PROFILE ' ||
                      SUBSTR(SQLERRM, 1, 200);
           RAISE EXP_REJECT_RECORD;
         WHEN OTHERS THEN
           V_RESP_CDE := '21';
           V_ERR_MSG  := 'ERROR IN FETCHING CARD BALANCE CONFIGURATION FOR THE PRODUCT PROFILE ' ||
                      SUBSTR(SQLERRM, 1, 200);
           RAISE EXP_REJECT_RECORD;
        END;
        --Sn check balance
        IF (v_upd_ledger_bal > V_MAX_CARD_BAL) OR (v_upd_amt > V_MAX_CARD_BAL) THEN
         BEGIN

          V_RESP_CDE := '30';
          V_ERR_MSG := 'EXCEEDING MAXIMUM CARD BALANCE';
          RAISE EXP_REJECT_RECORD;
          /*
             IF ( p_card_stat<>'12') THEN
               UPDATE CMS_APPL_PAN
                 SET CAP_CARD_STAT = '12'
                WHERE CAP_PAN_CODE = P_HASH_PAN AND CAP_INST_CODE = P_INST_CODE;
               IF SQL%ROWCOUNT = 0 THEN
                V_ERR_MSG  := 'updating the card status is not happened';
                V_RESP_CDE := '21';
                RAISE EXP_REJECT_RECORD;
               END IF;
               v_chnge_crdstat:='Y';
            end if;
            */
         EXCEPTION
           WHEN EXP_REJECT_RECORD THEN
            RAISE EXP_REJECT_RECORD;
           WHEN OTHERS THEN
            V_ERR_MSG  := 'Error while updating the card status';
            V_RESP_CDE := '21';
            RAISE EXP_REJECT_RECORD;
         END;
        END IF;
    END IF;
        --En check balance
   --Sn create gl entries and acct update
   BEGIN
   
      sp_upd_transaction_accnt_auth (p_inst_code,
                                     v_tran_date,
                                     p_prod_code,
                                     p_card_type,
                                    -- v_tran_amt,
                                    case when (p_preauth_type='C' and v_dr_cr_flag = 'NA') then 0 else v_tran_amt end,
                                     v_func_code,
                                     p_txn_code,
                                     v_dr_cr_flag,
                                     p_rrn,
                                     NULL,                        --p_term_id,
                                     p_delivery_channel,
                                     p_txn_mode,
                                     p_pan_code,
                                     v_fee_code,
                                     v_fee_amt,
                                     v_fee_cracct_no,
                                     v_fee_dracct_no,
                                     v_st_calc_flag,
                                     v_cess_calc_flag,
                                     v_servicetax_amount,
                                     v_st_cracct_no,
                                     v_st_dracct_no,
                                     v_cess_amount,
                                     v_cess_cracct_no,
                                     v_cess_dracct_no,
                                     p_acct_no,
                                   --  NULL,                    --v_hold_amount,
                                     p_hold_amount,
                                     p_msg_type,
                                     v_resp_cde,
                                     v_err_msg,
                                     v_feerev_compfee
                                    );

      IF (v_resp_cde <> '1' OR v_err_msg <> 'OK')
      THEN
         v_resp_cde := '21';
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
                'Error from currency conversion ' || SUBSTR (SQLERRM, 1, 200);
         RAISE exp_reject_record;
   END;

   --En create gl entries and acct update

   --Sn find narration
   BEGIN
      v_trans_desc := p_trans_desc;

      IF TRIM (v_trans_desc) IS NOT NULL
      THEN
         v_narration := v_trans_desc || '/';
      END IF;

      IF TRIM (p_tran_date) IS NOT NULL
      THEN
         v_narration := v_narration || p_tran_date || '/';
      END IF;

      IF TRIM (p_auth_id) IS NOT NULL
      THEN
         v_narration := v_narration || p_auth_id;
      END IF;
   EXCEPTION
      WHEN NO_DATA_FOUND
      THEN
         v_trans_desc := 'Transaction type ' || p_txn_code;
      WHEN OTHERS
      THEN
         v_resp_cde := '21';
         v_err_msg :=
                'Error in finding the narration ' || SUBSTR (SQLERRM, 1, 200);
         RAISE exp_reject_record;
   END;

   --En find narration
   v_timestamp:= v_time_stamp;
 --  v_timestamp := SYSTIMESTAMP; -- Time Stampe should be matched with all table, Commented by Raja Gopal G

   --Sn create a entry in statement log
   IF v_dr_cr_flag <> 'NA'
   THEN
      BEGIN
         INSERT INTO cms_statements_log
                     (csl_pan_no, csl_opening_bal, csl_trans_amount,
                      csl_trans_type, csl_trans_date,
                      csl_closing_balance,
                      csl_trans_narrration, csl_inst_code, csl_pan_no_encr,
                      csl_rrn, csl_auth_id, csl_business_date,
                      csl_business_time, txn_fee_flag, csl_delivery_channel,
                      csl_txn_code, csl_acct_no, csl_ins_user, csl_ins_date,
                      csl_merchant_name, csl_merchant_city,
                      csl_merchant_state,
                      csl_panno_last4digit,
                      csl_prod_code,csl_card_type, csl_acct_type, csl_time_stamp
                     )
              VALUES (p_hash_pan, v_ledger_bal, v_tran_amt,
                      v_dr_cr_flag, v_tran_date,
                      DECODE (v_dr_cr_flag,
                              'DR', v_ledger_bal - v_tran_amt,
                              'CR', v_ledger_bal + v_tran_amt,
                              'NA', v_ledger_bal
                             ),
                      v_narration, p_inst_code, p_encr_pan,
                      p_rrn, p_auth_id, p_tran_date,
                      p_tran_time, 'N', p_delivery_channel,
                      p_txn_code, p_acct_no, 1, SYSDATE,
                      NULL, NULL,
                      NULL,
                      (SUBSTR (p_pan_code,
                               LENGTH (p_pan_code) - 3,
                               LENGTH (p_pan_code)
                              )
                      ),
                      p_prod_code,p_card_type, v_acct_type, v_timestamp
                     );
      EXCEPTION
         WHEN OTHERS
         THEN
            v_resp_cde := '21';
            v_err_msg :=
                  'Problem while inserting into statement log for tran amt '
               || SUBSTR (SQLERRM, 1, 200);
            RAISE exp_reject_record;
      END;
   END IF;

   --En create a entry in statement log

   --Sn find fee opening balance
   IF v_total_fee <> 0 OR v_freetxn_exceed = 'N'
   THEN
      BEGIN
         SELECT DECODE (v_dr_cr_flag,
                        'DR', v_ledger_bal - v_tran_amt,
                        'CR', v_ledger_bal + v_tran_amt,
                        'NA', v_ledger_bal
                       )
           INTO v_fee_opening_bal
           FROM DUAL;
      EXCEPTION
         WHEN OTHERS
         THEN
            v_resp_cde := '21';
            v_err_msg :=
                  'Error in acct balance calculation based on transflag'
               || v_dr_cr_flag;
            RAISE exp_reject_record;
      END;

      IF v_freetxn_exceed = 'N'
      THEN
         BEGIN
            INSERT INTO cms_statements_log
                        (csl_pan_no, csl_opening_bal, csl_trans_amount,
                         csl_trans_type, csl_trans_date,
                         csl_closing_balance, csl_trans_narrration,
                         csl_inst_code, csl_pan_no_encr, csl_rrn,
                         csl_auth_id, csl_business_date, csl_business_time,
                         txn_fee_flag, csl_delivery_channel, csl_txn_code,
                         csl_acct_no, csl_ins_user, csl_ins_date,
                         csl_merchant_name, csl_merchant_city,
                         csl_merchant_state,
                         csl_panno_last4digit,
                         csl_prod_code, csl_acct_type, csl_time_stamp
                        )
                 VALUES (p_hash_pan, v_fee_opening_bal, v_total_fee,
                         'DR', v_tran_date,
                         v_fee_opening_bal - v_total_fee, v_fee_desc,
                         p_inst_code, p_encr_pan, p_rrn,
                         p_auth_id, p_tran_date, p_tran_time,
                         'Y', p_delivery_channel, p_txn_code,
                         p_acct_no, 1, SYSDATE,
                         NULL, NULL,                                   --NULL,
                         NULL,
                         SUBSTR (p_pan_code,
                                 LENGTH (p_pan_code) - 3,
                                 LENGTH (p_pan_code)
                                ),
                         p_prod_code, v_acct_type, v_timestamp
                        );
         EXCEPTION
            WHEN OTHERS
            THEN
               v_resp_cde := '21';
               v_err_msg :=
                     'Problem while inserting into statement log for tran fee '
                  || SUBSTR (SQLERRM, 1, 200);
               RAISE exp_reject_record;
         END;
      ELSE
         BEGIN
            --En find fee opening balance
            IF v_feeamnt_type = 'A'
            THEN
               v_flat_fees :=
                  ROUND (v_flat_fees - ((v_flat_fees * v_waiv_percnt) / 100),
                         2
                        );
               v_per_fees :=
                  ROUND (v_per_fees - ((v_per_fees * v_waiv_percnt) / 100), 2);

               --En Entry for Fixed Fee
               INSERT INTO cms_statements_log
                           (csl_pan_no, csl_opening_bal, csl_trans_amount,
                            csl_trans_type, csl_trans_date,
                            csl_closing_balance,
                            csl_trans_narrration,
                            csl_inst_code, csl_pan_no_encr, csl_rrn,
                            csl_auth_id, csl_business_date,
                            csl_business_time, txn_fee_flag,
                            csl_delivery_channel, csl_txn_code, csl_acct_no,
                            csl_ins_user, csl_ins_date, csl_merchant_name,
                            csl_merchant_city, csl_merchant_state,
                            csl_panno_last4digit,
                            csl_prod_code, csl_acct_type, csl_time_stamp
                           )
                    VALUES (p_hash_pan, v_fee_opening_bal, v_flat_fees,
                            'DR', v_tran_date,
                            v_fee_opening_bal - v_flat_fees,
                            'Fixed Fee debited for ' || v_fee_desc,
                            p_inst_code, p_encr_pan, p_rrn,
                            p_auth_id, p_tran_date,
                            p_tran_time, 'Y',
                            p_delivery_channel, p_txn_code, p_acct_no,
                            1, SYSDATE, NULL,
                            NULL, NULL,
                            (SUBSTR (p_pan_code,
                                     LENGTH (p_pan_code) - 3,
                                     LENGTH (p_pan_code)
                                    )
                            ),
                            p_prod_code, v_acct_type, v_timestamp
                           );

               --En Entry for Fixed Fee
               v_fee_opening_bal := v_fee_opening_bal - v_flat_fees;

               --Sn Entry for Percentage Fee
               INSERT INTO cms_statements_log
                           (csl_pan_no, csl_opening_bal, csl_trans_amount,
                            csl_trans_type, csl_trans_date,
                            csl_closing_balance,
                            csl_trans_narrration,
                            csl_inst_code, csl_pan_no_encr, csl_rrn,
                            csl_auth_id, csl_business_date,
                            csl_business_time, txn_fee_flag,
                            csl_delivery_channel, csl_txn_code, csl_acct_no,
                            csl_ins_user, csl_ins_date, csl_merchant_name,
                            csl_merchant_city, csl_merchant_state,
                            csl_panno_last4digit,
                            csl_prod_code, csl_acct_type, csl_time_stamp
                           )
                    VALUES (p_hash_pan, v_fee_opening_bal, v_per_fees,
                            'DR', v_tran_date,
                            v_fee_opening_bal - v_per_fees,
                            'Percentage Fee debited for ' || v_fee_desc,
                            p_inst_code, p_encr_pan, p_rrn,
                            p_auth_id, p_tran_date,
                            p_tran_time, 'Y',
                            p_delivery_channel, p_txn_code, p_acct_no,
                            1, SYSDATE, NULL,
                            NULL, NULL,
                            (SUBSTR (p_pan_code,
                                     LENGTH (p_pan_code) - 3,
                                     LENGTH (p_pan_code)
                                    )
                            ),
                            p_prod_code, v_acct_type, v_timestamp
                           );
            --En Entry for Percentage Fee
            ELSE
               --Sn create entries for FEES attached
               INSERT INTO cms_statements_log
                           (csl_pan_no, csl_opening_bal, csl_trans_amount,
                            csl_trans_type, csl_trans_date,
                            csl_closing_balance, csl_trans_narrration,
                            csl_inst_code, csl_pan_no_encr, csl_rrn,
                            csl_auth_id, csl_business_date,
                            csl_business_time, txn_fee_flag,
                            csl_delivery_channel, csl_txn_code, csl_acct_no,
                            csl_ins_user, csl_ins_date, csl_merchant_name,
                            csl_merchant_city, csl_merchant_state,
                            csl_panno_last4digit,
                            csl_prod_code, csl_acct_type, csl_time_stamp
                           )
                    VALUES (p_hash_pan, v_fee_opening_bal, v_total_fee,
                            'DR', v_tran_date,
                            v_fee_opening_bal - v_total_fee, v_fee_desc,
                            p_inst_code, p_encr_pan, p_rrn,
                            p_auth_id, p_tran_date,
                            p_tran_time, 'Y',
                            p_delivery_channel, p_txn_code, p_acct_no,
                            1, SYSDATE, NULL,
                            NULL, NULL,
                            SUBSTR (p_pan_code,
                                    LENGTH (p_pan_code) - 3,
                                    LENGTH (p_pan_code)
                                   ),
                            p_prod_code, v_acct_type, v_timestamp
                           );
              --Sn added for Mantis Id:15916
                IF     p_login_txn = 'Y'
                     AND v_clawback_amnt > 0
                     AND v_chrg_dtl_cnt < v_tot_clwbck_count
                  THEN
                     BEGIN
                        INSERT INTO cms_charge_dtl
                                    (ccd_pan_code, ccd_acct_no,
                                     ccd_clawback_amnt,
                                     ccd_gl_acct_no, ccd_pan_code_encr,
                                     ccd_rrn, ccd_calc_date, ccd_fee_freq,
                                     ccd_file_status, ccd_clawback,
                                     ccd_inst_code, ccd_fee_code,
                                     ccd_calc_amt,
                                     ccd_fee_plan, ccd_delivery_channel,
                                     ccd_txn_code, ccd_debited_amnt,
                                     ccd_mbr_numb,
                                     ccd_process_msg,
                                     ccd_feeattachtype
                                    )
                             VALUES (p_hash_pan, p_acct_no,
                                     ROUND (v_clawback_amnt, 2),
                                     v_fee_cracct_no, p_encr_pan,
                                     p_rrn, v_tran_date, 'T',
                                     'C', v_clawback,
                                     p_inst_code, v_fee_code,
                                     ROUND (v_actual_fee_amnt, 2),
                                     v_fee_plan, p_delivery_channel,
                                     p_txn_code, ROUND (v_fee_amt, 2),
                                     p_mbr_numb,
                                     DECODE (v_err_msg, 'OK', 'SUCCESS'),
                                     v_feeattach_type
                                    );
                     EXCEPTION
                        WHEN OTHERS
                        THEN
                           v_resp_cde := '21';
                           v_err_msg :=
                                 'Problem while inserting into CMS_CHARGE_DTL '
                              || SUBSTR (SQLERRM, 1, 200);
                           RAISE exp_reject_record;
                     END;
                  END IF;

               --En added for Mantis Id:15916

            END IF;
         EXCEPTION
            WHEN OTHERS
            THEN
               v_resp_cde := '21';
               v_err_msg :=
                     'Problem while inserting into statement log for tran fee '
                  || SUBSTR (SQLERRM, 1, 200);
               RAISE exp_reject_record;
         END;
      END IF;
   END IF;



 /*
  --Sn Logging of system initiated card status change
  IF v_chnge_crdstat='Y' THEN
    BEGIN
      sp_log_cardstat_chnge (p_inst_code,
      p_hash_pan,
      p_encr_pan,
      p_auth_id,
      '03',
      p_rrn,
      P_TRAN_DATE,
      P_TRAN_TIME,
      V_RESP_CDE,
      V_ERR_MSG );
      IF V_RESP_CDE <> '00' AND V_ERR_MSG <> 'OK' THEN
        RAISE EXP_REJECT_RECORD;
      END IF;
    EXCEPTION
    WHEN EXP_REJECT_RECORD THEN
      RAISE;
    WHEN OTHERS THEN
      v_resp_cde := '21';
      V_ERR_MSG   := 'Error while logging system initiated card status change ' || SUBSTR (SQLERRM, 1, 200);
      RAISE EXP_REJECT_RECORD;
    END;
  END IF;
  --En Logging of system initiated card status change
 */



   p_resp_code := v_resp_cde;
   p_res_msg := v_err_msg;
   p_fee_code := v_fee_code;
   p_fee_plan := v_fee_plan;
   p_feeattach_type := v_feeattach_type;
   p_total_fee := v_total_fee;
   p_total_amt := v_total_amt;
   p_comp_freetxn_exceed := v_comp_freetxn_exceed;
   p_comp_feecode :=v_comp_fee_code;
EXCEPTION
   WHEN exp_reject_record
   THEN
      p_resp_code := v_resp_cde;
      p_res_msg := v_err_msg;
   WHEN OTHERS
   THEN
      p_resp_code := '89';
      -- Server Declined
      p_res_msg :=
         'Main exception from  Fee calculation  ' || SUBSTR (SQLERRM, 1, 300);
END;
/
show error