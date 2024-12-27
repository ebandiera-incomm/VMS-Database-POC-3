CREATE OR REPLACE procedure VMSCMS.sp_preauthhold_release(
                                                                   prm_inst_code             IN       NUMBER,
                                                                   prm_msg_type              IN       VARCHAR2,
                                                                   prm_rrn                   IN       VARCHAR2,
                                                                   prm_stan                  IN       VARCHAR2,
                                                                   prm_tran_date             IN       VARCHAR2,
                                                                   prm_tran_time             IN       VARCHAR2,
                                                                   prm_txn_amt               IN       NUMBER,
                                                                   prm_txn_curr              IN       VARCHAR2,
                                                                   prm_txn_code              IN       VARCHAR2,
                                                                   prm_txn_mode              IN       VARCHAR2,
                                                                   prm_delivery_chnl         IN       VARCHAR2,
                                                                   prm_mbr_numb              IN       VARCHAR2,
                                                                   prm_rvsl_code             IN       VARCHAR2,
                                                                   prm_remark                IN       VARCHAR2,
                                                                   prm_orgnl_rrn             IN       VARCHAR2,
                                                                   prm_orgnl_card_no         IN       VARCHAR2,
                                                                   prm_orgnl_stan            IN       VARCHAR2,
                                                                   prm_orgnl_tran_date       IN       VARCHAR2,
                                                                   prm_orgnl_tran_time       IN       VARCHAR2,
                                                                   prm_orgnl_txn_amt         IN       NUMBER,
                                                                   prm_orgnl_txn_code        IN       VARCHAR2,
                                                                   prm_orgnl_delivery_chnl   IN       VARCHAR2,
                                                                   prm_ins_user              IN       NUMBER,
                                                                   prm_acct_bal              OUT      VARCHAR2,
                                                                   prm_resp_code             OUT      VARCHAR2,
                                                                   prm_errmsg                OUT      VARCHAR2
                                                                  )
 as
/*
  * VERSION               :  1.0
  * DATE OF CREATION      : 29/NOV/2011
  * PURPOSE               : for hold fund release
  * CREATED BY            : Sagar More
 * Modified By      : B.Dhinakaran
     * Modified Reason  : Transaction detail report
     * Modified Date    : 22-Aug-2012
     * Reviewer         :  B.Besky Anand
     * Reviewed Date    :  28-Aug-2012
     * Build Number     :  CMS3.5.1_RI0015_B0009

  *
***/

   v_func_code              cms_func_mast.cfm_func_code%TYPE;
   v_prod_code              cms_appl_pan.cap_prod_code%TYPE;
   v_card_type              cms_appl_pan.cap_card_type%TYPE;
   v_card_acct_no           cms_appl_pan.cap_acct_no%TYPE;
   v_check_funcattach       NUMBER (1);
   v_cr_acctno              transactionlog.tranfee_cr_acctno%TYPE;
   v_dr_acctno              transactionlog.tranfee_dr_acctno%TYPE;
   v_responsecode           transactionlog.response_code%TYPE;
   v_acct_balance           cms_acct_mast.cam_acct_bal%TYPE;
   v_resp_cde               VARCHAR2 (2);
   v_err_msg                VARCHAR2 (300);
   v_hash_pan               cms_appl_pan.cap_pan_code%TYPE;
   v_auth_id                transactionlog.auth_id%type;
   exp_reject_record        EXCEPTION;
   v_savepoint              NUMBER (2)                              DEFAULT 1;
   v_proxy_number           transactionlog.proxy_number%TYPE;
   v_ledger_bal             cms_acct_mast.cam_ledger_bal%TYPE;
   v_dr_cr_flag             cms_transaction_mast.ctm_credit_debit_flag%TYPE;
   v_tran_desc              cms_transaction_mast.ctm_tran_desc%TYPE;
   v_card_curr              cms_bin_param.cbp_param_value%TYPE;
   p1                       NUMBER                                  DEFAULT 0;
   v_check_statcnt          NUMBER;
   v_card_stat              cms_appl_pan.cap_card_stat%TYPE;
   v_profile_code           cms_prod_cattype.cpc_profile_code%TYPE;
   v_max_limit              cms_bin_param.cbp_param_value%TYPE;
   v_expry_date             cms_appl_pan.cap_expry_date%TYPE;
   v_rrn_count              NUMBER (3);
   v_check_max_bal          number(20,3);
   v_preauth_count          number(2);
   v_preauthhist_count      number(2);


Begin        -- Main Begin starts here


   Begin    --SN 001


      v_err_msg := 'OK';
      SAVEPOINT p1;


     --SN CREATE HASH PAN
      BEGIN
         v_hash_pan := gethash (prm_orgnl_card_no);
      EXCEPTION
         WHEN OTHERS
         THEN
            v_resp_cde := '21';
            v_err_msg :=
                    'Error while converting pan ' || SUBSTR (SQLERRM, 1, 100);
            RAISE exp_reject_record;
      END;
      --EN CREATE HASH PAN
      
      --Sn find the type of orginal txn (credit or debit)
      BEGIN
         SELECT ctm_credit_debit_flag, ctm_tran_desc
           INTO v_dr_cr_flag, v_tran_desc
           FROM cms_transaction_mast
          WHERE ctm_tran_code = prm_txn_code
            AND ctm_delivery_channel = prm_delivery_chnl
            AND ctm_inst_code = prm_inst_code;
      EXCEPTION
         WHEN NO_DATA_FOUND
         THEN
            v_resp_cde := '16';
            v_err_msg :=
                  'Transaction detail is not found in master for reversal txn '
               || prm_txn_code
               || 'delivery channel '
               || prm_delivery_chnl;
            RAISE exp_reject_record;
         WHEN OTHERS
         THEN
            v_resp_cde := '21';
            v_err_msg :=
                  'Problem while selecting debit/credit flag '
               || SUBSTR (SQLERRM, 1, 100);
            RAISE exp_reject_record;
      END;
      --En find the type of orginal txn (credit or debit)

      --Sn generate auth id
      BEGIN
         SELECT LPAD (seq_auth_id.NEXTVAL, 6, '0')
           INTO v_auth_id
           FROM DUAL;
      EXCEPTION
         WHEN OTHERS
         THEN
            prm_errmsg :=
                 'Error while generating authid ' || SUBSTR (SQLERRM, 1, 100);
            prm_resp_code := '21';
            RETURN;
      END;
      --En generate auth id

      --Sn Duplicate RRN Check
      BEGIN
         SELECT COUNT (1)
           INTO v_rrn_count
           FROM transactionlog
          WHERE rrn = prm_rrn AND business_date = prm_tran_date and DELIVERY_CHANNEL = prm_delivery_chnl;--Ramkumar.MK

         IF v_rrn_count > 0
         THEN
            v_resp_cde := '22';
            v_err_msg :=
                        'Duplicate RRN ' || prm_rrn || ' on' || prm_tran_date;
            RAISE exp_reject_record;
         END IF;
      END;
      --En Duplicate RRN Check

      --SN identify the fee rvsl txn
      BEGIN
         SELECT cfm_func_code
           INTO v_func_code
           FROM cms_func_mast
          WHERE cfm_inst_code = prm_inst_code
            AND cfm_txn_code = prm_txn_code
            AND cfm_txn_mode = prm_txn_mode
            AND cfm_delivery_channel = prm_delivery_chnl;
      EXCEPTION
         WHEN NO_DATA_FOUND
         THEN
            v_resp_cde := '16';
            v_err_msg :=' Preauth release function code is not defined in master';
            RAISE exp_reject_record;
         WHEN OTHERS
         THEN
            v_resp_cde := '21';
            v_err_msg := ' Error while master data for Preauth release '|| SUBSTR (SQLERRM, 1, 100);
            RAISE exp_reject_record;
      END;

      --En identify the fee rvsl txn



      --Sn get the prod detail
      BEGIN
         SELECT cap_prod_code, cap_card_type, cap_acct_no, cap_card_stat,
                cap_expry_date
           INTO v_prod_code, v_card_type, v_card_acct_no, v_card_stat,
                v_expry_date
           FROM cms_appl_pan
          WHERE cap_inst_code = prm_inst_code AND cap_pan_code = v_hash_pan;

      EXCEPTION
         WHEN NO_DATA_FOUND
         THEN
            v_resp_cde := '16';
            v_err_msg := 'Pan code is not defined ';
            RAISE exp_reject_record;
         WHEN OTHERS
         THEN
            v_resp_cde := '21';
            v_err_msg :=
                  ' Error while selecting data from card master  '
               || SUBSTR (SQLERRM, 1, 100);
            RAISE exp_reject_record;
      END;
      --En get the prod detail


      --Sn  check fun is attached to product
      BEGIN
         SELECT 1
           INTO v_check_funcattach
           FROM cms_func_prod
          WHERE cfp_inst_code = prm_inst_code
            AND cfp_func_code = v_func_code
            AND cfp_prod_code = v_prod_code
            AND cfp_prod_cattype = v_card_type;
      EXCEPTION
         WHEN NO_DATA_FOUND
         THEN
            v_resp_cde := '16';
            v_err_msg :=
                  'Function code '
               || v_func_code
               || ' not attached to product '
               || v_prod_code
               || ' and card type '
               || v_card_type;
            RAISE exp_reject_record;
         WHEN TOO_MANY_ROWS
         THEN
            v_resp_cde := '21';
            v_err_msg :=
                  'Error while selecting func prod detail from master '
               || SUBSTR (SQLERRM, 1, 100);
            RAISE exp_reject_record;
      END;
      --En  check fun is attached to product

      


     --SN: get profile code
      BEGIN
         SELECT cpc_profile_code
           INTO v_profile_code
           FROM cms_prod_cattype
          WHERE cpc_prod_code = v_prod_code
            AND cpc_card_type = v_card_type
            AND cpc_inst_code = prm_inst_code;
      EXCEPTION
         WHEN NO_DATA_FOUND
         THEN
            v_err_msg := 'profile_code not defined ' || v_profile_code;
             v_resp_cde := '16';
            RAISE exp_reject_record;
         WHEN OTHERS
         THEN
            v_err_msg := 'while fetching profile code ' ||substr(sqlerrm,1,100);
            v_resp_cde := '21';
            RAISE exp_reject_record;
      END;
      --EN: get profile code

      --Sn: get max topup limit
      BEGIN
         SELECT cbp_param_value
           INTO v_max_limit
           FROM cms_bin_param
          WHERE cbp_profile_code = v_profile_code
            AND cbp_param_type = 'Topup Parameter'
            AND cbp_param_name = 'Max Topup Limit';
      EXCEPTION
         WHEN NO_DATA_FOUND
         THEN
            v_resp_cde := '16';
            v_err_msg := 'max toup limit not configured for profile code '|| v_profile_code;
            RAISE exp_reject_record;

      WHEN OTHERS
      THEN
            v_err_msg := 'while fetching max card limit ' || substr(sqlerrm,1,100);
            v_resp_cde := '21';
            RAISE exp_reject_record;

      END;
      --Sn: get max topup limit

      --Sn get acct bal
      BEGIN
         SELECT cam_acct_bal, cam_ledger_bal
           INTO v_acct_balance, v_ledger_bal
           FROM cms_acct_mast
          WHERE cam_inst_code = prm_inst_code AND cam_acct_no = v_card_acct_no;


         prm_acct_bal := v_acct_balance;
      EXCEPTION
         WHEN NO_DATA_FOUND
         THEN
            v_resp_cde := '16';
            v_err_msg := 'Account not found ';
            RAISE exp_reject_record;
         WHEN OTHERS
         THEN
            v_resp_cde := '21';
            v_err_msg :=
                  ' Error while selecting data from acct master  '
               || SUBSTR (SQLERRM, 1, 100);
            RAISE exp_reject_record;
      END;
      --En get acct bal

      v_check_max_bal := prm_acct_bal  + prm_txn_amt;

      if v_max_limit < v_check_max_bal
      then

         v_resp_cde := '2';
         v_err_msg := 'preauth release failed.Maximum balance exceeding';
         RAISE exp_reject_record;


      end if;

      --Sn : check expiry card
      IF TRUNC (v_expry_date) < TO_DATE (prm_tran_date, 'yyyymmdd')
      THEN
         prm_resp_code := '13';                      --Ineligible Transaction
         prm_errmsg := 'EXPIRED CARD';
         RETURN;
      END IF;

      --En : check expiry card

      --Sn check card stat
      BEGIN
         SELECT COUNT (1)
           INTO v_check_statcnt
           FROM pcms_valid_cardstat
          WHERE pvc_inst_code = prm_inst_code
            AND pvc_card_stat = v_card_stat
            AND pvc_tran_code = prm_txn_code
            AND pvc_delivery_channel = prm_delivery_chnl;

         IF v_check_statcnt = 0
         THEN
            prm_resp_code := '12';
            prm_errmsg := 'Invalid Card Status';
            RETURN;
         END IF;
      EXCEPTION
         WHEN OTHERS
         THEN
            v_resp_cde  := '21';
            v_err_msg   := 'Problem while selecting card stat '|| SUBSTR (SQLERRM, 1, 200);
            RAISE exp_reject_record;
      END;
      --En check card stat


      --Sn get orginal transaction
      BEGIN
         SELECT response_code, proxy_number
           INTO v_responsecode,v_proxy_number
           FROM transactionlog
          WHERE rrn = prm_orgnl_rrn
            AND business_date = prm_orgnl_tran_date
            AND business_time = prm_orgnl_tran_time
            AND customer_card_no = v_hash_pan
            AND NVL (amount, 0.00) = prm_orgnl_txn_amt;

      EXCEPTION
              WHEN NO_DATA_FOUND
         THEN
            v_resp_cde := '16';
            v_err_msg := 'Orginal transaction record not found';
            RAISE exp_reject_record;
         WHEN OTHERS
         THEN
            v_resp_cde := '21';
            v_err_msg :=
                  'while selecting orginal txn detail'|| SUBSTR (SQLERRM, 1, 100);
            RAISE exp_reject_record;
      END;
      --En get orginal transaction

      --Sn check for successful Transaction and get the detail...
      IF v_responsecode <> '00'
      THEN
         v_resp_cde := '21';
         v_err_msg := 'Orginal transaction was not a successful transaction';
         RAISE exp_reject_record;
      END IF;
      --En check for successful Transaction and get the detail...


        --Sn find the card curr
        begin

         SELECT trim(cbp_param_value)
           INTO v_card_curr
           FROM cms_appl_pan, cms_bin_param, cms_prod_mast
          WHERE cap_inst_code = cbp_inst_code and
               cpm_inst_code = cbp_inst_code and
               cap_prod_code = cpm_prod_code and
               cpm_profile_code = cbp_profile_code and
               cbp_param_name = 'Currency' AND cap_pan_code = v_hash_pan;

         if trim(v_card_curr) is null then

           v_resp_cde := '21';
           v_err_msg  := 'Card currency cannot be null ';
           raise exp_reject_record;
         end if;

        exception
         when exp_reject_record then
           raise;
         when no_data_found then
           v_resp_cde := '16';
           v_err_msg  := 'card currency is not defined for the institution ';
           raise exp_reject_record;
         when others then
           v_resp_cde := '21';
           v_err_msg  := 'Error while selecting card currecy  ' ||
                      SUBSTR(SQLERRM, 1, 100);
           raise exp_reject_record;
        end;
        --En find the card curr

        --Sn check card currency with txn currency --------
        IF v_card_curr <> prm_txn_curr THEN
         v_err_msg  := 'Both from card currency and txn currency are not same';
         v_resp_cde := '21';
         raise exp_reject_record;
        end if;
        --En check card currency with txn currency

      BEGIN

        SELECT count(*)
        INTO   v_preauth_count
        FROM   cms_preauth_transaction
        WHERE  cpt_card_no = v_hash_pan
        and    cpt_rrn = prm_orgnl_rrn
        and    cpt_preauth_validflag = 'Y'
        and    cpt_expiry_flag = 'N'
        AND    cpt_txn_date = prm_orgnl_tran_date
        AND    cpt_txn_time = prm_orgnl_tran_time
        AND    cpt_totalhold_amt = prm_orgnl_txn_amt;

      EXCEPTION
         WHEN OTHERS
         THEN
            v_resp_cde  := '21';
            v_err_msg   := 'Problem while selecting preauth txn '|| SUBSTR (SQLERRM, 1, 200);
            RAISE exp_reject_record;
      END;



        If v_preauth_count = 0
        then

        v_err_msg := 'Orignal preauth txn not found for rrn '||prm_orgnl_rrn||
                         'date   = '||prm_orgnl_tran_date||
                         'time   = '||prm_orgnl_tran_time||
                         'amount = '||prm_orgnl_txn_amt ;
        v_resp_cde := '16';
        raise exp_reject_record;

        elsif v_preauth_count = 1
        then

            SELECT count(*)
            INTO   v_preauthhist_count
            FROM   CMS_PREAUTH_TRANS_HIST
            WHERE  cph_card_no = v_hash_pan
            and    cph_rrn = prm_orgnl_rrn
            and    cph_preauth_validflag = 'Y'
            and    cph_expiry_flag = 'N'
            AND    cph_txn_date = prm_orgnl_tran_date
            AND    cph_txn_time = prm_orgnl_tran_time
            AND    cph_totalhold_amt = prm_orgnl_txn_amt;

            if v_preauthhist_count = 0
            then

            v_err_msg := 'Orignal preauth txn not found in history for rrn '||prm_orgnl_rrn||
                         'date = '||prm_orgnl_tran_date||
                         'time = '||prm_orgnl_tran_time||
                         'amount = '|| prm_orgnl_txn_amt ;
            v_resp_cde := '16';
            raise exp_reject_record;


            elsif v_preauthhist_count = 1
            then
               Begin
                  update cms_preauth_transaction
                  set        cpt_expiry_flag = 'C'  -- flag C will denote that its a on request preauth release
                      WHERE  cpt_card_no = v_hash_pan
                      and    cpt_rrn     = prm_orgnl_rrn
                      and    cpt_preauth_validflag = 'Y'
                      and    cpt_expiry_flag = 'N'
                      AND    cpt_txn_date = prm_orgnl_tran_date
                      AND    cpt_txn_time = prm_orgnl_tran_time
                      AND    cpt_totalhold_amt = prm_orgnl_txn_amt;


                  update    CMS_PREAUTH_TRANS_HIST
                  set      cph_expiry_flag = 'C'  -- flag C will denote that its a on request preauth release
                    WHERE  cph_card_no = v_hash_pan
                    and    cph_rrn = prm_orgnl_rrn
                    and    cph_preauth_validflag = 'Y'
                    and    cph_expiry_flag = 'N'
                    AND    cph_txn_date = prm_orgnl_tran_date
                    AND    cph_txn_time = prm_orgnl_tran_time
                    AND    cph_totalhold_amt = prm_orgnl_txn_amt;

                    update cms_acct_mast
                    set    cam_ledger_bal = cam_ledger_bal + prm_txn_amt,
                           cam_acct_bal   = cam_acct_bal   + prm_txn_amt
                    where cam_inst_code   = prm_inst_code
                    and   cam_acct_no     = v_card_acct_no;

                    if sql%rowcount = 0
                    then
                    v_err_msg := 'account not found in acct master '||v_card_acct_no;
                    v_resp_cde := '16';
                    raise exp_reject_record;
                    end if;

               exception when exp_reject_record
               then
               raise ;
               when others
               then
               v_err_msg  := 'While updating amount for hold release '||substr(sqlerrm,1,100);
               v_resp_cde := '21';
               raise exp_reject_record;

               End;


            elsif v_preauthhist_count > 1
            then
            v_err_msg := 'Multiple preauth txn found in hist for rrn = '||prm_orgnl_rrn||
                         ' date = '||prm_orgnl_tran_date||
                         ' time = '||prm_orgnl_tran_time||
                         ' amount = '|| prm_txn_amt ;
            v_resp_cde := '16';
            raise exp_reject_record;


            end if;

        elsif v_preauthhist_count > 1
        then
        v_err_msg := 'Multiple preauth txn found for rrn = '||prm_orgnl_rrn||
                     'date = '||prm_orgnl_tran_date||
                     'time = '||prm_orgnl_tran_time||
                     'amount = '|| prm_txn_amt ;
        v_resp_cde := '16';
        raise exp_reject_record;

        End if;

      BEGIN
         INSERT INTO cms_transaction_log_dtl
                     (ctd_delivery_channel,
                      ctd_txn_code,
                      ctd_txn_type,
                      ctd_msg_type,
                      ctd_txn_mode,
                      ctd_business_date,
                      ctd_business_time,
                      ctd_customer_card_no,
                      ctd_txn_amount,
                      ctd_txn_curr,
                      ctd_actual_amount,
                      ctd_bill_amount,
                      ctd_bill_curr,
                      ctd_process_flag,
                      ctd_process_msg,
                      ctd_rrn,
                      ctd_system_trace_audit_no,
                      ctd_inst_code,
                      ctd_customer_card_no_encr,
                      ctd_cust_acct_number,
                      ctd_ins_date,
                      ctd_ins_user
                     )
              VALUES (prm_delivery_chnl,
                      prm_txn_code,
                      1,
                      prm_msg_type,
                      prm_txn_mode,
                      prm_tran_date,
                      prm_tran_time,
                      v_hash_pan,
                      prm_txn_amt,
                      prm_txn_curr,
                      prm_txn_amt,
                      prm_txn_amt,
                      v_card_curr,
                      'Y',
                      v_err_msg,
                      prm_rrn,
                      prm_stan,
                      prm_inst_code,
                      fn_emaps_main (prm_orgnl_card_no),
                      v_card_acct_no,
                      SYSDATE,
                      prm_ins_user
                     );
      EXCEPTION
         WHEN OTHERS
         THEN
            prm_resp_code := '89';
            prm_errmsg :=
                  'Error while inserting in log detail '
               || SUBSTR (SQLERRM, 1, 100);
            RETURN;
      END;

      -- Sn create a entry in txnlog
      BEGIN
         INSERT INTO transactionlog
                     (msgtype,
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
                      rule_indicator,
                      rulegroupid,
                      mccode,
                      currencycode,
                      productid,
                      categoryid,
                      tranfee_amt,
                      tips,
                      decline_ruleid,
                      atm_name_location,
                      auth_id,
                      trans_desc,
                      amount,
                      preauthamount,
                      partialamount,
                      mccodegroupid,
                      currencycodegroupid,
                      transcodegroupid,
                      rules,
                      preauth_date,
                      gl_upd_flag,
                      system_trace_audit_no,
                      instcode,
                      feecode,
                      feeattachtype,
                      tran_reverse_flag,
                      customer_card_no_encr,
                      topup_card_no_encr,
                      proxy_number,
                      reversal_code,
                      customer_acct_no,
                      acct_balance,
                      ledger_balance,
                      error_msg,
                      orgnl_card_no,
                      orgnl_rrn,
                      orgnl_business_date,
                      orgnl_business_time,
                      orgnl_terminal_id,
                      remark,
                      add_ins_date,
                      add_ins_user,response_id
                     )
              VALUES (
                      prm_msg_type,
                      prm_rrn,
                      prm_delivery_chnl,
                      NULL,
                      SYSDATE,
                      prm_txn_code,
                      1,
                      prm_txn_mode,
                      DECODE (prm_resp_code, '00', 'C', 'F'),
                      prm_resp_code,
                      prm_tran_date,
                      prm_tran_time,
                      v_hash_pan,
                      NULL,
                      NULL,
                      NULL,
                      prm_inst_code,
                      prm_txn_amt,
                      NULL,
                      NULL,
                      NULL,
                      prm_txn_curr,
                      v_prod_code,
                      v_card_type,
                      0,
                      0,
                      NULL,
                      NULL,
                      v_auth_id,
                      v_tran_desc|| 'for rrn '|| prm_orgnl_rrn|| ' date: '|| TO_DATE (prm_orgnl_tran_date|| ' '|| prm_orgnl_tran_time,'yyyymmdd hh24miss'),
                      prm_txn_amt,
                      NULL,
                      NULL,
                      NULL,
                      NULL,
                      NULL,
                      NULL,
                      NULL,
                      'Y',
                      prm_stan,
                      prm_inst_code,
                      NULL,
                      NULL,
                      'N',
                      fn_emaps_main (prm_orgnl_card_no),
                      NULL,
                      v_proxy_number,
                      prm_rvsl_code,
                      v_card_acct_no,
                      v_acct_balance + prm_txn_amt,
                      v_ledger_bal   + prm_txn_amt,
                      v_err_msg,
                      prm_orgnl_card_no,
                      prm_orgnl_rrn,
                      prm_orgnl_tran_date,
                      prm_orgnl_tran_time,
                      NULL,
                      prm_remark,
                      SYSDATE,
                      prm_ins_user,prm_resp_code
                     );
      EXCEPTION
         WHEN OTHERS
         THEN
            prm_resp_code := '89';
            prm_errmsg :=
               'Error while inserting in txnlog ' || SUBSTR (SQLERRM, 1, 100);
            RETURN;
      END;
      -- En create a entry in txnlog

   EXCEPTION
      WHEN exp_reject_record
      THEN

         ROLLBACK TO SAVEPOINT p1;

         BEGIN
            SELECT cms_iso_respcde
              INTO prm_resp_code
              FROM cms_response_mast
             WHERE cms_inst_code = prm_inst_code
               AND cms_delivery_channel = prm_delivery_chnl
               AND cms_response_id = v_resp_cde;

            prm_errmsg := v_err_msg;
         EXCEPTION
            WHEN OTHERS
            THEN
               prm_errmsg :=
                     'Problem while selecting data from response master2 '
                  || v_resp_cde
                  || SUBSTR (SQLERRM, 1, 100);
               prm_resp_code := '89';
               RETURN;
         END;

         BEGIN
            INSERT INTO cms_transaction_log_dtl
                        (ctd_delivery_channel,
                        ctd_txn_code,
                        ctd_txn_type,
                        ctd_msg_type,
                        ctd_txn_mode,
                        ctd_business_date,
                        ctd_business_time,
                        ctd_customer_card_no,
                        ctd_txn_amount,
                        ctd_txn_curr,
                        ctd_actual_amount,
                        ctd_bill_amount,
                        ctd_bill_curr,
                        ctd_process_flag,
                        ctd_process_msg,
                        ctd_rrn,
                        ctd_system_trace_audit_no,
                        ctd_inst_code,
                        ctd_customer_card_no_encr,
                        ctd_cust_acct_number,
                        ctd_ins_user
                        )
                 VALUES (prm_delivery_chnl,
                         prm_txn_code,
                         1,                 --discuss
                         prm_msg_type,
                         prm_txn_mode,
                         prm_tran_date,
                         prm_tran_time,
                         v_hash_pan,
                         prm_txn_amt,
                         prm_txn_curr,
                         prm_txn_amt,
                         prm_txn_amt,
                         v_card_curr,
                         'E',
                         v_err_msg,
                         prm_rrn,
                         prm_stan,
                         prm_inst_code,
                         fn_emaps_main (prm_orgnl_card_no),
                         v_card_acct_no,
                         prm_ins_user
                        );


         EXCEPTION
            WHEN OTHERS
            THEN
               prm_resp_code := '89';
               prm_errmsg :=
                     'Error while inserting in log detail 1'
                  || SUBSTR (SQLERRM, 1, 100);
               RETURN;
         END;

         BEGIN

            INSERT INTO transactionlog
                        (msgtype,
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
                         rule_indicator,
                         rulegroupid,
                         mccode,
                         currencycode,
                         productid,
                         categoryid,
                         tranfee_amt,
                         tips,
                         decline_ruleid,
                         atm_name_location,
                         auth_id,
                         trans_desc,
                         amount,
                         preauthamount,
                         partialamount,
                         mccodegroupid,
                         currencycodegroupid,
                         transcodegroupid,
                         rules,-- preauth_date,
                         gl_upd_flag,
                         system_trace_audit_no,
                         instcode,
                         feecode,
                         feeattachtype,
                         tran_reverse_flag,
                         customer_card_no_encr,
                         topup_card_no_encr,
                         proxy_number,
                         reversal_code,
                         customer_acct_no,
                         acct_balance,
                         ledger_balance,
                         error_msg,
                         orgnl_card_no,
                         orgnl_rrn,
                         orgnl_business_date,
                         orgnl_business_time,
                         orgnl_terminal_id,
                         add_ins_user,response_id
                        )
                 VALUES (prm_msg_type,
                         prm_rrn,
                         prm_delivery_chnl,
                         NULL,
                         SYSDATE,
                         prm_txn_code,
                         1,
                         prm_txn_mode,
                         DECODE (prm_resp_code, '00', 'C', 'F'),
                         prm_resp_code,
                         prm_tran_date,
                         prm_tran_time,
                         v_hash_pan,
                         NULL,
                         NULL,
                         NULL,
                         prm_inst_code,
                         prm_txn_amt,
                         NULL,
                         NULL,
                         NULL,
                         prm_txn_curr,
                         v_prod_code,
                         v_card_type,
                         0,
                         0,
                         NULL,
                         NULL,
                         v_auth_id,
                         v_tran_desc,
                         prm_txn_amt,
                         NULL,
                         NULL,
                         NULL,
                         NULL,
                         NULL,
                         NULL,
                         'N', -- gl update flag ?
                         prm_stan,
                         prm_inst_code,
                         NULL,
                         NULL,
                         'N',
                         fn_emaps_main (prm_orgnl_card_no),
                         NULL,
                         v_proxy_number,
                         prm_rvsl_code,
                         v_card_acct_no,
                         v_acct_balance,
                         v_ledger_bal,
                         v_err_msg,
                         prm_orgnl_card_no,
                         prm_orgnl_rrn,
                         prm_orgnl_tran_date,
                         prm_orgnl_tran_time,
                         NULL,
                         prm_ins_user,prm_resp_code
                         );

         EXCEPTION
            WHEN OTHERS
            THEN
               prm_resp_code := '89';
               prm_errmsg :=
                     'Error while inserting in txnlog 1'
                  || SUBSTR (SQLERRM, 1, 100);
               RETURN;
         END;
      WHEN OTHERS
      THEN
         ROLLBACK;

         BEGIN
            SELECT cms_iso_respcde
              INTO prm_resp_code
              FROM cms_response_mast
             WHERE cms_inst_code = prm_inst_code
               AND cms_delivery_channel = prm_delivery_chnl
               AND cms_response_id = '21';
         EXCEPTION
            WHEN OTHERS
            THEN
               prm_errmsg :=
                     'Problem while selecting data from response master3'
                  || v_resp_cde
                  || SUBSTR (SQLERRM, 1, 100);
               prm_resp_code := '89';
               RETURN;
         END;

         BEGIN
            INSERT INTO cms_transaction_log_dtl
                        (ctd_delivery_channel,
                        ctd_txn_code,
                        ctd_txn_type,
                        ctd_msg_type,
                        ctd_txn_mode,
                        ctd_business_date,
                        ctd_business_time,
                        ctd_customer_card_no,
                        ctd_txn_amount,
                        ctd_txn_curr,
                        ctd_actual_amount,
                        ctd_bill_amount,
                        ctd_bill_curr,
                        ctd_process_flag,
                        ctd_process_msg,
                        ctd_rrn,
                        ctd_system_trace_audit_no,
                        ctd_inst_code,
                        ctd_customer_card_no_encr,
                        ctd_cust_acct_number,
                        ctd_ins_user
                        )
                 VALUES (prm_delivery_chnl,
                         prm_txn_code,
                         1,                 --discuss
                         prm_msg_type,
                         prm_txn_mode,
                         prm_tran_date,
                         prm_tran_time,
                         v_hash_pan,
                         prm_txn_amt,
                         prm_txn_curr,
                         prm_txn_amt,
                         prm_txn_amt,
                         v_card_curr,
                         'E',
                         v_err_msg,
                         prm_rrn,
                         prm_stan,
                         prm_inst_code,
                         fn_emaps_main (prm_orgnl_card_no),
                         v_card_acct_no,
                         prm_ins_user
                        );
           EXCEPTION
            WHEN OTHERS
            THEN
               prm_resp_code := '89';
               prm_errmsg :=
                     'Error while inserting in log detail 2'
                  || SUBSTR (SQLERRM, 1, 100);
               RETURN;
         END;

         BEGIN

            INSERT INTO transactionlog
                        (msgtype,
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
                         rule_indicator,
                         rulegroupid,
                         mccode,
                         currencycode,
                         productid,
                         categoryid,
                         tranfee_amt,
                         tips,
                         decline_ruleid,
                         atm_name_location,
                         auth_id,
                         trans_desc,
                         amount,
                         preauthamount,
                         partialamount,
                         mccodegroupid,
                         currencycodegroupid,
                         transcodegroupid,
                         rules,-- preauth_date,
                         gl_upd_flag,
                         system_trace_audit_no,
                         instcode,
                         feecode,
                         feeattachtype,
                         tran_reverse_flag,
                         customer_card_no_encr,
                         topup_card_no_encr,
                         proxy_number,
                         reversal_code,
                         customer_acct_no,
                         acct_balance,
                         ledger_balance,
                         error_msg,
                         orgnl_card_no,
                         orgnl_rrn,
                         orgnl_business_date,
                         orgnl_business_time,
                         orgnl_terminal_id,
                         add_ins_user,
                         response_id
                        )
                 VALUES (prm_msg_type,
                         prm_rrn,
                         prm_delivery_chnl,
                         NULL,
                         SYSDATE,
                         prm_txn_code,
                         1,
                         prm_txn_mode,
                         DECODE (prm_resp_code, '00', 'C', 'F'),
                         prm_resp_code,
                         prm_tran_date,
                         prm_tran_time,
                         v_hash_pan,
                         NULL,
                         NULL,
                         NULL,
                         prm_inst_code,
                         prm_txn_amt,
                         NULL,
                         NULL,
                         NULL,
                         prm_txn_curr,
                         v_prod_code,
                         v_card_type,
                         0,
                         0,
                         NULL,
                         NULL,
                         v_auth_id,
                         v_tran_desc,
                         prm_txn_amt,
                         NULL,
                         NULL,
                         NULL,
                         NULL,
                         NULL,
                         NULL,
                         'Y',
                         prm_stan,
                         prm_inst_code,
                         NULL,
                         NULL,
                         'N',
                         fn_emaps_main (prm_orgnl_card_no),
                         NULL,
                         v_proxy_number,
                         prm_rvsl_code,
                         v_card_acct_no,
                         v_acct_balance,
                         v_ledger_bal,
                         v_err_msg,
                         prm_orgnl_card_no,
                         prm_orgnl_rrn,
                         prm_orgnl_tran_date,
                         prm_orgnl_tran_time,
                         NULL,
                         prm_ins_user,
                         prm_resp_code
                         );
         EXCEPTION
            WHEN OTHERS
            THEN
               prm_resp_code := '89';
               prm_errmsg :=
                     'Error while inserting in txnlog 2'
                  || SUBSTR (SQLERRM, 1, 100);
               RETURN;
         END;

   END; --EN 001


exception when OTHERS  -- exception of main begin block
then

prm_errmsg := 'ERROR FROM MAIN ' || SUBSTR (SQLERRM, 1, 100);


End;         -- Main Begin ends here
/
show error;