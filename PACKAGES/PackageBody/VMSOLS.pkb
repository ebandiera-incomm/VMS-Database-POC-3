create or replace
PACKAGE BODY               VMSCMS.VMSOLS AS

    PROCEDURE cr_adjust_cmsauth_iso93 (
        p_i_inst_code                 IN NUMBER,
        p_i_msg                       IN VARCHAR2,
        p_i_rrn                       IN VARCHAR2,
        p_i_del_channel               IN VARCHAR2,
        p_i_term_id                   IN VARCHAR2,
        p_i_txn_code                  IN VARCHAR2,
        p_i_txn_mode                  IN VARCHAR2,
        p_i_tran_date                 IN VARCHAR2,
        p_i_tran_time                 IN VARCHAR2,
        p_i_card_no                   IN VARCHAR2,
        p_i_txn_amt                   IN NUMBER,
        p_i_merchant_name             IN VARCHAR2,
        p_i_merchant_city             IN VARCHAR2,
        p_i_mcc_code                  IN VARCHAR2,
        p_i_curr_code                 IN VARCHAR2,
        p_i_pos_verification          IN VARCHAR2,
        p_i_atmname_loc               IN VARCHAR2,
        p_i_expry_date                IN VARCHAR2,
        p_i_stan                      IN VARCHAR2,
        p_i_international_ind         IN VARCHAR2,
        p_i_rvsl_code                 IN NUMBER,
        p_i_network_id                IN VARCHAR2,
        p_i_merchant_zip              IN VARCHAR2,
        p_i_addl_amt                  IN VARCHAR2,
        p_i_networkid_switch          IN VARCHAR2,
        p_i_networkid_acquirer        IN VARCHAR2,
        p_i_network_setl_date         IN VARCHAR2,
        p_i_cvv_verificationtype      IN VARCHAR2,
        p_partial_preauth_ind         IN VARCHAR2,
        p_i_pulse_transactionid       IN VARCHAR2,
        p_i_visa_transactionid        IN VARCHAR2,
        p_i_mc_traceid                IN VARCHAR2,
        p_i_cardverification_result   IN VARCHAR2,
        p_i_merchant_id               IN VARCHAR2,
        p_i_merchant_cntrycode        IN VARCHAR2,
        p_i_product_type              IN VARCHAR2,
        p_i_expiry_date_check         IN VARCHAR2,
        p_i_original_stan             IN VARCHAR2,
        p_i_orgnl_trandate            IN VARCHAR2,
        p_i_orgnl_trantime            IN VARCHAR2,
        p_o_auth_id                   OUT VARCHAR2,
        p_o_resp_code                 OUT VARCHAR2,
        p_o_resp_msg                  OUT CLOB,
        p_o_ledger_bal                OUT VARCHAR2,
        p_o_iso_respcde               OUT VARCHAR2,
        p_o_resp_id                   OUT VARCHAR2 --Added for sending to FSS (VMS-8018)
        
    ) IS
  /*************************************************
  * Modified By      :  Baskar K
  * Modified For     :  VMS-615
  * Modified Date    :  08-FEB-2019
  * Modified Reason  :  Credit Adjustments Support in HISO
  * Reviewer         :  Saravana kumar
  * Build Number     :   VMSR12_B0004
  
  * Modified By      : Karthick/Jey
  * Modified Date    : 05-18-2022
  * Purpose          : Archival changes.
  * Reviewer         : Venkat Singamaneni
  * Release Number   : VMSGPRHOST60 for VMS-5739/FSP-991
  
  * Modified By      : Areshka A.
  * Modified Date    : 03-Nov-2023
  * Purpose          : VMS-8018: Added new out parameter (response id) for sending to FSS
  * Reviewer         : 
  * Release Number   : 
  *************************************************/

        v_num_acct_bal             cms_acct_mast.cam_acct_bal%TYPE;
        v_num_ledger_bal           cms_acct_mast.cam_ledger_bal%TYPE;
        v_num_tran_amt             transactionlog.amount%TYPE;
        v_var_auth_id              transactionlog.auth_id%TYPE;
        v_num_total_amt            transactionlog.total_amount%TYPE;
        v_date_tran_date           cms_statements_log.csl_trans_date%TYPE;
        v_var_prod_code            cms_prod_mast.cpm_prod_code%TYPE;
        v_var_prod_cattype         cms_prod_cattype.cpc_card_type%TYPE;
        v_num_upd_amt              cms_acct_mast.cam_acct_bal%TYPE;
        v_num_upd_ledg_amt         cms_acct_mast.cam_ledger_bal%TYPE;
        v_var_narration            cms_statements_log.csl_trans_narrration%TYPE;
        v_var_trans_desc           transactionlog.trans_desc%TYPE;
        v_date_expry_date          cms_appl_pan.cap_expry_date%TYPE;
        v_var_dr_cr_flag           cms_transaction_mast.ctm_credit_debit_flag%TYPE;
        v_var_output_type          cms_transaction_mast.ctm_output_type%TYPE;
        v_var_pan_cardstat         cms_appl_pan.cap_card_stat%TYPE;     
        v_var_gl_upd_flag          transactionlog.gl_upd_flag%TYPE;
        v_time_businesstime        cms_statements_log.csl_business_time%TYPE;
        v_var_card_curr            cms_transaction_log_dtl.ctd_bill_curr%TYPE; 
        v_num_servicetax_amt       cms_inst_param.cip_param_value%TYPE;
        v_num_cess_amt             cms_inst_param.cip_param_value%TYPE;
        v_date_business_date       cms_statements_log.csl_trans_date%TYPE;
        v_var_txn_type             cms_transaction_mast.ctm_tran_type%TYPE;
        v_var_card_acctno          cms_acct_mast.cam_acct_no%TYPE;
        v_var_hash_pan             cms_appl_pan.cap_pan_code%TYPE;
        v_var_encr_pan             cms_appl_pan.cap_pan_code_encr%TYPE;
        v_var_tran_type            cms_transaction_mast.ctm_tran_type%TYPE;
        v_num_max_card_bal         cms_acct_mast.cam_acct_bal%TYPE;
        v_var_proxy_number         cms_appl_pan.cap_proxy_number%TYPE;
        v_num_acct_number          cms_appl_pan.cap_acct_no%TYPE;
        v_var_prfl_code            cms_appl_pan.cap_prfl_code%TYPE;
        v_var_comb_hash            pkg_limits_check.type_hash;
        v_var_prfl_flag            cms_transaction_mast.ctm_prfl_flag%TYPE;
        v_var_cam_type_code        cms_acct_mast.cam_type_code%TYPE;
        v_var_repeat_msgtype       transactionlog.msgtype%type default '1221';
        v_var_hashkey_id           cms_transaction_log_dtl.ctd_hashkey_id%TYPE;
        v_var_login_txn            cms_transaction_mast.ctm_login_txn%type;
       
        v_var_profile_code         cms_prod_cattype.cpc_profile_code%TYPE;
        v_var_rules                transactionlog.rules%TYPE;
        v_var_rrn                  transactionlog.rrn%TYPE;
        v_var_orgnl_date           transactionlog.orgnl_business_date%TYPE;
        v_var_orgnl_time           transactionlog.orgnl_business_time%TYPE;
        v_var_orgnl_stan           transactionlog.original_stan%TYPE;
        v_time_stamp               transactionlog.TIME_STAMP%type;
        v_num_stan_count           NUMBER;
        v_var_resp_code            cms_response_mast.cms_response_id%type;
        v_var_err_msg              varchar2(500) := 'OK';
        v_dub_tran                  NUMBER;
       exp_reject_record          EXCEPTION;
	   v_Retperiod  date;  --Added for VMS-5739/FSP-991
	   v_Retdate  date; --Added for VMS-5739/FSP-991
    BEGIN
        v_var_resp_code := '1';
        p_o_resp_msg := 'OK';
        v_var_rules := 'MATCHED';
        
        
        BEGIN
        
    --get Hash PAN
            BEGIN
                v_var_hash_pan := gethash(p_i_card_no);
            EXCEPTION
                WHEN OTHERS THEN
                    v_var_err_msg := 'Error while converting pan '
                     || substr(sqlerrm,1,200);
                    RAISE exp_reject_record;
            end;
     --get Encrypt PAN
            BEGIN
                v_var_encr_pan := fn_emaps_main(p_i_card_no);
            EXCEPTION
                WHEN OTHERS THEN
                    v_var_err_msg := 'Error while converting pan '
                     || substr(sqlerrm,1,200);
                    RAISE exp_reject_record;
            END;

            v_time_stamp := systimestamp;
            BEGIN
                v_var_hashkey_id := gethash(p_i_del_channel
                 || p_i_txn_code
                 || p_i_card_no
                 || p_i_rrn
                 || TO_CHAR(v_time_stamp,'YYYYMMDDHH24MISSFF5') );
            EXCEPTION
                WHEN OTHERS THEN
                    v_var_resp_code := '21';
                    v_var_err_msg := 'Error while converting master data '
                     || substr(sqlerrm,1,200);
                    RAISE exp_reject_record;
            END;
            
    -- Get Transaction Details
            BEGIN
                SELECT
                    ctm_credit_debit_flag,
                    ctm_output_type,
                    DECODE(ctm_tran_type, 'N', '0', 'F','1' ),
                    ctm_tran_type,
                    ctm_tran_desc,
                    ctm_prfl_flag,
                    ctm_login_txn
                INTO
                    v_var_dr_cr_flag,
                    v_var_output_type,
                    v_var_txn_type,
                    v_var_tran_type,
                    v_var_trans_desc,
                    v_var_prfl_flag,
                    v_var_login_txn
                FROM
                    cms_transaction_mast
                WHERE ctm_tran_code = p_i_txn_code
                    AND   ctm_delivery_channel = p_i_del_channel
                    AND   ctm_inst_code = p_i_inst_code;

            EXCEPTION
                WHEN OTHERS THEN
                    v_var_resp_code := '21';
                    v_var_err_msg := 'Error while selecting transaction details'
                     || substr(sqlerrm,1,200);
                    RAISE exp_reject_record;
            END;

            BEGIN
                v_var_auth_id:= lpad(  seq_auth_id.NEXTVAL, 6, '0'  );
            EXCEPTION
                WHEN OTHERS THEN
                    v_var_err_msg := 'Error while generating authid '
                     || substr(sqlerrm,1,300);
                    v_var_resp_code := '21';
                    RAISE exp_reject_record;
            END;
            
    -- get Product Details
            BEGIN
                SELECT
                    cap_prod_code,
                    cap_card_type,
                    cap_expry_date,
                    cap_card_stat,
                    cap_proxy_number,
                    cap_acct_no,
                    cap_prfl_code
                INTO
                    v_var_prod_code,
                    v_var_prod_cattype,
                    v_date_expry_date,
                    v_var_pan_cardstat,
                    v_var_proxy_number,
                    v_num_acct_number,
                    v_var_prfl_code
                FROM   cms_appl_pan
                where  cap_pan_code = v_var_hash_pan
                and cap_inst_code = p_i_inst_code
                and cap_mbr_numb='000';

            EXCEPTION
                WHEN OTHERS THEN
                    v_var_resp_code := '21';
                    v_var_err_msg := 'Problem while selecting card detail'
                     || substr(sqlerrm,1,200);
                    RAISE exp_reject_record;
            end;
--get profile details
            BEGIN
                SELECT
                    cpc_profile_code
                    
                INTO
                    v_var_profile_code
                   
                    
                FROM  cms_prod_cattype
                where cpc_inst_code = p_i_inst_code
                and   cpc_prod_code = v_var_prod_code
                AND    cpc_card_type = v_var_prod_cattype;

            EXCEPTION
                WHEN OTHERS THEN
                    v_var_resp_code := '21';
                    v_var_err_msg := 'Problem while selecting card cms_prod_cattype'
                     || substr(sqlerrm,1,200);
                    RAISE exp_reject_record;
            END;

            BEGIN
                v_date_tran_date := TO_DATE(substr( trim(p_i_tran_date), 1, 8 ) || ' ' || substr( trim(p_i_tran_time), 1, 10 ), 'yyyymmdd hh24:mi:ss' );
            EXCEPTION
                WHEN OTHERS THEN
                    v_var_resp_code := '32';
                    v_var_err_msg := 'Problem while converting transaction time '
                     || substr(sqlerrm,1,200);
                    RAISE exp_reject_record;
            END;

            IF ( ( v_var_tran_type = 'F' ) OR ( p_i_msg = '0100' ) ) THEN
                IF ( p_i_txn_amt >= 0 ) THEN
                    v_num_tran_amt := p_i_txn_amt;
        -- Currency conversion
                    BEGIN
                        sp_convert_curr(
                            p_i_inst_code,
                            p_i_curr_code,
                            p_i_card_no,
                            p_i_txn_amt,
                            v_date_tran_date,
                            v_num_tran_amt,
                            v_var_card_curr,
                            v_var_err_msg,
                            v_var_prod_code,
                            v_var_prod_cattype
                        );

                        IF v_var_err_msg <> 'OK' THEN
                            v_var_resp_code := '44';
                            RAISE exp_reject_record;
                        END IF;
                    EXCEPTION
                        WHEN exp_reject_record THEN
                            RAISE;
                        WHEN OTHERS THEN
                            v_var_resp_code := '69';
                            v_var_err_msg := 'Error from currency conversion '
                             || substr(sqlerrm,1,200);
                            RAISE exp_reject_record;
                    END;

                ELSE
                    v_var_resp_code := '43';
                    v_var_err_msg := 'INVALID AMOUNT';
                    RAISE exp_reject_record;
                END IF;
            END IF;




            
            
    -- Dupliacte Stan CHeck
            IF p_i_msg NOT IN ( '1200','1120','1100' ) THEN
                BEGIN
				
				--Added for VMS-5739/FSP-991
	   select (add_months(trunc(sysdate,'MM'),'-'||RETENTION_PERIOD))
       INTO   v_Retperiod 
       FROM DBA_OPERATIONS.ARCHIVE_MGMNT_CTL  
       WHERE  OPERATION_TYPE='ARCHIVE' 
       AND OBJECT_NAME='TRANSACTIONLOG_EBR';
       
       v_Retdate := TO_DATE(SUBSTR(TRIM(p_i_tran_date), 1, 8), 'yyyymmdd');		--Added for VMS-5739/FSP-991


			IF (v_Retdate>v_Retperiod)THEN												--Added for VMS-5739/FSP-991
                    
					SELECT
                        COUNT(1)
                    INTO
                        v_num_stan_count
                        
                    FROM transactionlog
                    WHERE customer_card_no = v_var_hash_pan
                        AND business_date = p_i_tran_date
                        and delivery_channel = p_i_del_channel
                        AND add_ins_date BETWEEN trunc(SYSDATE - 1) AND SYSDATE
                        AND system_trace_audit_no = p_i_stan;
			ELSE
					SELECT
                        COUNT(1)
                    INTO
                        v_num_stan_count
                        
                    FROM VMSCMS_HISTORY.TRANSACTIONLOG_HIST 					--Added for VMS-5739/FSP-991
                    WHERE customer_card_no = v_var_hash_pan
                        AND business_date = p_i_tran_date
                        and delivery_channel = p_i_del_channel
                        AND add_ins_date BETWEEN trunc(SYSDATE - 1) AND SYSDATE
                        AND system_trace_audit_no = p_i_stan;
	
			END IF;
                    IF  v_num_stan_count > 0 THEN
                        v_var_resp_code := '191';
                        v_var_err_msg := 'Duplicate Stan from the Terminal'
                         || p_i_term_id
                         || 'on'
                         || p_i_tran_date;
                        RAISE exp_reject_record;
                    END IF;

                EXCEPTION
                    WHEN exp_reject_record THEN
                        RAISE exp_reject_record;
                    WHEN OTHERS THEN
                        v_var_resp_code := '21';
                        v_var_err_msg := 'Error while checking duplicate STAN '
                         || substr(sqlerrm,1,200);
                        RAISE exp_reject_record;
                END;

                v_var_orgnl_date := p_i_orgnl_trandate;
                v_var_orgnl_stan := p_i_original_stan;
                v_var_orgnl_time := p_i_orgnl_trantime;
      -- Original RRN Check
                BEGIN
				
				v_Retdate := TO_DATE(SUBSTR(TRIM(p_i_orgnl_trandate), 1, 8), 'yyyymmdd');    --Added for VMS-5739/FSP-991


				IF (v_Retdate>v_Retperiod)THEN												--Added for VMS-5739/FSP-991
				
                    SELECT
                        rrn
                    INTO
                        v_var_rrn
                        
                    FROM transactionlog
                    WHERE system_trace_audit_no = v_var_orgnl_stan
                    and business_date = v_var_orgnl_date
                    and business_time = v_var_orgnl_time
                    AND response_code = '00'
                    AND customer_card_no = v_var_hash_pan
                    AND delivery_channel = p_i_del_channel;
				ELSE
					SELECT
                        rrn
                    INTO
                        v_var_rrn
                        
                    FROM VMSCMS_HISTORY.TRANSACTIONLOG_HIST 						--Added for VMS-5739/FSP-991
                    WHERE system_trace_audit_no = v_var_orgnl_stan
                    and business_date = v_var_orgnl_date
                    and business_time = v_var_orgnl_time
                    AND response_code = '00'
                    AND customer_card_no = v_var_hash_pan
                    AND delivery_channel = p_i_del_channel;
				END IF;

                EXCEPTION
                    WHEN OTHERS THEN
                        v_var_rules := 'UNMATCHED';
                        v_var_orgnl_date := NULL;
                        v_var_orgnl_stan := NULL;
                        v_var_orgnl_time := NULL;
                        v_var_resp_code := '21';
                        v_var_err_msg := 'Error fetching original transaction details '
                         || substr(sqlerrm,1,200);
                END;
                
          begin 
              select 
                  count(1)
              into 
                  v_dub_tran
              from VMSCMS.TRANSACTIONLOG											--Added for VMS-5739/FSP-991			
              where orgnl_rrn = v_var_rrn 
              and original_stan=v_var_orgnl_stan
              and customer_card_no = v_var_hash_pan
              and delivery_channel = p_i_del_channel
              and rules is not null 
              AND response_code = '00';
			  IF SQL%ROWCOUNT = 0 THEN
			      select count(1)
                  into 
                  v_dub_tran
              from VMSCMS_HISTORY.TRANSACTIONLOG_HIST												--Added for VMS-5739/FSP-991			
              where orgnl_rrn = v_var_rrn 
              and original_stan=v_var_orgnl_stan
              and customer_card_no = v_var_hash_pan
              and delivery_channel = p_i_del_channel
              and rules is not null 
              AND response_code = '00';
			  END IF;
              
              
          if v_dub_tran > 0 then 
               
               v_var_resp_code := '21';
               v_var_err_msg := 'Adjustment already processed';
               v_var_rules := '';
               raise exp_reject_record;
          END IF; 
          END;
                

            END IF;
    -- Duplicate RRN Check

            BEGIN
                    sp_dup_rrn_check(
                        v_var_hash_pan,
                        p_i_rrn,
                        p_i_tran_date,
                        p_i_del_channel,
                        p_i_msg,
                        p_i_txn_code,
                        v_var_err_msg
                    );
                    IF v_var_err_msg <> 'OK' THEN
                        v_var_resp_code := '22';
                        RAISE exp_reject_record;
                    END IF;
            EXCEPTION
                WHEN exp_reject_record THEN
                    RAISE;
                WHEN OTHERS THEN
                    v_var_resp_code := '22';
                    v_var_err_msg := 'Error while checking RRN'
                     || substr(sqlerrm,1,200);
                    RAISE exp_reject_record;
            end;

    ---------------------------------------------------------------------------
    --EN:Added on 06-Feb-2013 to validate amount by ignoring surcharge fee
    ---------------------------------------------------------------------------
    --LYFE changes....

  
    --SN Added by Pankaj S. for DB time logging changes

               BEGIN
                    SELECT
                        cam_acct_bal,
                        cam_ledger_bal,
                        cam_acct_no
                    INTO
                        v_num_acct_bal,
                        v_num_ledger_bal,
                        v_var_card_acctno
                        
                    FROM cms_acct_mast
                    WHERE cam_acct_no = v_num_acct_number
                    and cam_inst_code = p_i_inst_code
                    FOR UPDATE;

            EXCEPTION
                WHEN OTHERS THEN
                    v_var_resp_code := '12';
                    v_var_err_msg := 'Error while selecting data from card Master for card number ' || sqlerrm;
                    RAISE exp_reject_record;
            end;


            IF v_var_dr_cr_flag = 'CR'  THEN
                v_num_upd_amt := v_num_acct_bal + v_num_tran_amt;
                v_num_upd_ledg_amt := v_num_ledger_bal + v_num_tran_amt;
            ELSIF v_var_dr_cr_flag = 'DR' THEN
                v_num_upd_amt := v_num_acct_bal - v_num_tran_amt;
                v_num_upd_ledg_amt := v_num_ledger_bal - v_num_tran_amt;
            ELSIF v_var_dr_cr_flag = 'NA' THEN
                v_num_upd_amt := v_num_acct_bal - v_num_tran_amt;
                v_num_upd_ledg_amt := v_num_ledger_bal - v_num_tran_amt;
            ELSE
                v_var_resp_code := '12';
                v_var_err_msg := 'Invalid transflag    txn code ' || p_i_txn_code;
                RAISE exp_reject_record;
            END IF;
    -- Get CARD BALANCE CONFIGURATION

            IF ( v_var_dr_cr_flag = 'CR' AND p_i_rvsl_code = '00' ) OR ( v_var_dr_cr_flag = 'DR' AND p_i_rvsl_code <> '00' ) THEN
                BEGIN
                    SELECT
                        to_number(cbp_param_value)
                    INTO
                        v_num_max_card_bal
                        
                    FROM cms_bin_param
                    where cbp_inst_code = p_i_inst_code
                    AND cbp_param_name = 'Max Card Balance'
                    AND cbp_profile_code = v_var_profile_code;

                EXCEPTION
                    WHEN OTHERS THEN
                        v_var_resp_code := '21';
                        v_var_err_msg := 'ERROR IN FETCHING CARD BALANCE CONFIGURATION FOR THE PRODUCT PROFILE '
                         || substr(sqlerrm,1,200);
                        RAISE exp_reject_record;
                END;
            END IF;

            IF ( v_num_upd_amt > v_num_max_card_bal ) THEN
                BEGIN
                    UPDATE cms_appl_pan
                    set cap_card_stat = '12'
                    where cap_inst_code = p_i_inst_code          
                    and cap_pan_code = v_var_hash_pan;
                    
                    sp_log_cardstat_chnge(
                                  p_i_inst_code,
                                  v_var_hash_pan,
                                  v_var_encr_pan,
                                  v_var_auth_id,
                                  p_i_txn_code,
                                  p_i_rrn,
                                  p_i_tran_date,
                                  p_i_tran_time,
                                  v_var_resp_code,
                                  v_var_err_msg);
                    
                EXCEPTION
                    WHEN OTHERS THEN
                        v_var_resp_code := '21';
                        v_var_err_msg := 'ERROR IN  UPDATE card status '
                         || substr(sqlerrm,1,300);
                        RAISE exp_reject_record;
                END;
            END IF;
    --Update Acct Balace

            BEGIN
                sp_upd_transaction_accnt_auth(
                    p_i_inst_code,
                    v_date_tran_date,
                    v_var_prod_code,
                    v_var_prod_cattype,
                    v_num_tran_amt,
                    NULL,
                    p_i_txn_code,
                    v_var_dr_cr_flag,
                    p_i_rrn,
                    p_i_term_id,
                    p_i_del_channel,
                    p_i_txn_mode,
                    p_i_card_no,
                    NULL,
                    NULL,
                    NULL,
                    NULL,
                    NULL,
                    NULL,
                    v_num_servicetax_amt,
                    NULL,
                    NULL,
                    v_num_cess_amt,
                    NULL,
                    NULL,
                    v_var_card_acctno,
                    NULL,
                    p_i_msg,
                    v_var_resp_code,
                    v_var_err_msg
                );

                IF ( v_var_resp_code <> '1' OR v_var_err_msg <> 'OK' ) THEN
                    v_var_resp_code := '21';
                    RAISE exp_reject_record;
                END IF;

            EXCEPTION
                WHEN exp_reject_record THEN
                    RAISE;
                WHEN OTHERS THEN
                    v_var_resp_code := '21';
                    v_var_err_msg := 'Error from currency conversion '
                     || substr(sqlerrm,1,200);
                    RAISE exp_reject_record;
            END;

            BEGIN
                IF TRIM(v_var_trans_desc) IS NOT NULL THEN
                    v_var_narration := v_var_trans_desc || '/';
                END IF;

                IF TRIM(p_i_merchant_name) IS NOT NULL THEN
                    v_var_narration := v_var_narration || p_i_merchant_name || '/';
                END IF;

                IF TRIM(p_i_term_id) IS NOT NULL THEN
                    v_var_narration := v_var_narration || p_i_term_id || '/';
                END IF;

                IF TRIM(p_i_merchant_city) IS NOT NULL THEN
                    v_var_narration := v_var_narration || p_i_merchant_city || '/';
                END IF;

                IF TRIM(p_i_tran_date) IS NOT NULL THEN
                    v_var_narration := v_var_narration || p_i_tran_date || '/';
                END IF;

                IF TRIM(v_var_auth_id) IS NOT NULL THEN
                    v_var_narration := v_var_narration || v_var_auth_id;
                END IF;

            EXCEPTION
                WHEN no_data_found THEN
                    v_var_trans_desc := 'Transaction type ' || p_i_txn_code;
                WHEN OTHERS THEN
                    v_var_resp_code := '21';
                    v_var_err_msg := 'Error in finding the narration '
                     || substr(sqlerrm,1,200);
                    RAISE exp_reject_record;
            END;

  -- logging Statementlog table

                BEGIN
                    INSERT INTO cms_statements_log (
                        csl_pan_no,
                        csl_opening_bal,
                        csl_trans_amount,
                        csl_trans_type,
                        csl_trans_date,
                        csl_closing_balance,
                        csl_trans_narrration,
                        csl_inst_code,
                        csl_pan_no_encr,
                        csl_rrn,
                        csl_auth_id,
                        csl_business_date,
                        csl_business_time,
                        txn_fee_flag,
                        csl_delivery_channel,
                        csl_txn_code,
                        csl_acct_no,
                        csl_ins_user,
                        csl_ins_date,
                        csl_merchant_name,
                        csl_merchant_city,
                        csl_merchant_state,
                        csl_panno_last4digit,
                        csl_acct_type,
                        csl_time_stamp,
                        csl_prod_code,
                        csl_card_type
                    ) VALUES (
                        v_var_hash_pan,
                        v_num_ledger_bal,
                        v_num_tran_amt,
                        v_var_dr_cr_flag,
                        v_date_tran_date,
                        DECODE(
                            v_var_dr_cr_flag,
                            'DR',
                            v_num_ledger_bal - v_num_tran_amt,
                            'CR',
                            v_num_ledger_bal + v_num_tran_amt,
                            'NA',
                            v_num_ledger_bal
                        ),
                        v_var_narration,
                        p_i_inst_code,
                        v_var_encr_pan,
                        p_i_rrn,
                        v_var_auth_id,
                        p_i_tran_date,
                        p_i_tran_time,
                        'N',
                        p_i_del_channel,
                        p_i_txn_code,
                        v_var_card_acctno,
                        1,
                        SYSDATE,
                        p_i_merchant_name,
                        p_i_merchant_city,
                        p_i_atmname_loc,
                        ( substr(
                            p_i_card_no,
                            length(p_i_card_no) - 3,
                            length(p_i_card_no)
                        ) ),
                        v_var_cam_type_code,
                        v_time_stamp,
                        v_var_prod_code,
                        v_var_prod_cattype
                    );

                EXCEPTION
                    WHEN OTHERS THEN
                        v_var_resp_code := '21';
                        v_var_err_msg := 'Problem while inserting into statement log for tran amt '
                         || substr(sqlerrm,1,200);
                        RAISE exp_reject_record;
                END;

                    BEGIN
                        SELECT
                            cam_acct_bal,
                            cam_ledger_bal
                        INTO
                            v_num_acct_bal,
                            v_num_ledger_bal
                            
                        FROM cms_acct_mast
                        WHERE cam_acct_no = v_num_acct_number
                        AND cam_inst_code = p_i_inst_code;

                    EXCEPTION
                        WHEN OTHERS THEN
                            v_var_resp_code := '12';
                            v_var_err_msg := 'Error while selecting data from card Master for card number ' || sqlerrm;
                            RAISE exp_reject_record;
                    END;

                    IF v_var_output_type = 'N' THEN
                        p_o_resp_msg := TO_CHAR(v_num_upd_amt);
                        p_o_ledger_bal := TO_CHAR(v_num_upd_ledg_amt); 
                    END IF;



    -- get Response Code
            v_var_resp_code := '1';
            p_o_resp_id := v_var_resp_code; --Added for VMS-8018
            BEGIN
                SELECT
                    cms_b24_respcde,
                    cms_iso_respcde
                INTO
                    p_o_resp_code,
                    p_o_iso_respcde
                    
                FROM cms_response_mast
                WHERE cms_inst_code = p_i_inst_code
                and cms_delivery_channel = p_i_del_channel
                AND cms_response_id = to_number(v_var_resp_code);

            EXCEPTION
                WHEN OTHERS THEN
                    v_var_err_msg := 'Problem while selecting data from response master for respose code'
                     || v_var_resp_code
                     || substr(sqlerrm,1,300);
                    v_var_resp_code := '21';
                    RAISE exp_reject_record;
            END;

        EXCEPTION
    --<< MAIN EXCEPTION >>
            WHEN exp_reject_record THEN
                ROLLBACK;
                BEGIN
                    SELECT
                        cam_acct_bal,
                        cam_ledger_bal,
                        cam_acct_no,
                        cam_type_code
                    INTO
                        v_num_acct_bal,
                        v_num_ledger_bal,
                        v_num_acct_number,
                        v_var_cam_type_code
                        
                    FROM cms_acct_mast
                    WHERE cam_acct_no = v_num_acct_number
                    AND cam_inst_code = p_i_inst_code;

                EXCEPTION
                    WHEN OTHERS THEN
                        v_num_acct_bal := 0;
                        v_num_ledger_bal := 0;
                END;

                BEGIN
                   
                    p_o_resp_code := v_var_resp_code;
                    p_o_resp_msg := v_var_err_msg;
                    p_o_resp_id := v_var_resp_code; --Added for VMS-8018
                    
                    SELECT
                        cms_b24_respcde,
                        cms_iso_respcde
                    INTO
                        p_o_resp_code,
                        p_o_iso_respcde
                        
                    FROM  cms_response_mast
                    WHERE cms_inst_code = p_i_inst_code
                    AND cms_delivery_channel = p_i_del_channel
                    AND cms_response_id = v_var_resp_code;

                EXCEPTION
                    WHEN OTHERS THEN
                        p_o_resp_msg := 'Problem while selecting data from response master '
                         || v_var_resp_code
                         || substr(sqlerrm,1,300);
                        p_o_resp_code := '69';
                        p_o_resp_id := '69'; --Added for VMS-8018
                        ROLLBACK;
                END;
             WHEN OTHERS THEN
                ROLLBACK;
    -- get Account Details
                BEGIN
                    SELECT
                        cam_acct_bal,
                        cam_ledger_bal,
                        cam_acct_no,
                        cam_type_code
                    INTO
                        v_num_acct_bal,
                        v_num_ledger_bal,
                        v_num_acct_number,
                        v_var_cam_type_code
                        
                    FROM cms_acct_mast
                    WHERE cam_acct_no = v_num_acct_number
                    AND cam_inst_code = p_i_inst_code;

                EXCEPTION
                    WHEN OTHERS THEN
                        v_num_acct_bal := 0;
                        v_num_ledger_bal := 0;
                END;

                BEGIN
                    SELECT
                        cms_b24_respcde,
                        cms_iso_respcde
                    INTO
                        p_o_resp_code,
                        p_o_iso_respcde
                        
                    from cms_response_mast
                    WHERE cms_inst_code = p_i_inst_code
                    AND cms_delivery_channel = p_i_del_channel
                    AND cms_response_id = v_var_resp_code;

                    p_o_resp_msg := v_var_err_msg;
                    p_o_resp_id := v_var_resp_code; --Added for VMS-8018
                    
                EXCEPTION
                    WHEN OTHERS THEN
                        p_o_resp_msg := 'Problem while selecting data from response master '
                         || v_var_resp_code
                         || substr(sqlerrm,1,300);
                        p_o_resp_code := '69';
                        p_o_resp_id := '69'; --Added for VMS-8018
                        ROLLBACK;
                END;

        END;
  -- logging transactionlog table

        BEGIN
            INSERT INTO transactionlog (
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
                total_amount,
                rule_indicator,
                rulegroupid,
                mccode,
                currencycode,
                addcharge,
                productid,
                categoryid,
                atm_name_location,
                auth_id,
                trans_desc,
                amount,
                preauthamount,
                partialamount,
                rules,
                preauth_date,
                gl_upd_flag,
                system_trace_audit_no,
                instcode,
                feecode,
                tranfee_amt,
                servicetax_amt,
                cess_amt,
                cr_dr_flag,
                tranfee_cr_acctno,
                tranfee_dr_acctno,
                tran_st_calc_flag,
                tran_cess_calc_flag,
                tran_st_cr_acctno,
                tran_st_dr_acctno,
                tran_cess_cr_acctno,
                tran_cess_dr_acctno,
                customer_card_no_encr,
                topup_card_no_encr,
                proxy_number,
                reversal_code,
                customer_acct_no,
                acct_balance,
                ledger_balance,
                internation_ind_response,
                response_id,
                network_id,
                merchant_zip,
                fee_plan,
                pos_verification,
                feeattachtype,
                merchant_name,
                merchant_city,
                merchant_state,
                error_msg,
                acct_type,
                time_stamp,
                cardstatus,
                add_ins_user,
                addl_amnt,
                networkid_switch,
                networkid_acquirer,
                network_settl_date,
                cvv_verificationtype,
                partial_preauth_ind,
                addr_verify_response,
                addr_verify_indicator,
                merchant_id,
                remark,
                original_stan,
                orgnl_rrn,
                orgnl_business_date,
                orgnl_business_time
            ) VALUES (
                p_i_msg,
                p_i_rrn,
                p_i_del_channel,
                p_i_term_id,
                v_date_tran_date,
                p_i_txn_code,
                v_var_txn_type,
                p_i_txn_mode,
                DECODE(
                    p_o_iso_respcde,
                    '00',
                    'C',
                    'F'
                ),
                p_o_iso_respcde,
                p_i_tran_date,
                p_i_tran_time,
                v_var_hash_pan,
                NULL,
                NULL,
                NULL,
                TRIM(TO_CHAR(
                    nvl(v_num_total_amt,0),
                    '99999999999999990.99'
                ) ),
                NULL,
                NULL,
                p_i_mcc_code,
                p_i_curr_code,
                NULL,
                v_var_prod_code,
                v_var_prod_cattype,
                p_i_atmname_loc,
                v_var_auth_id,
                v_var_trans_desc,
                TRIM(TO_CHAR(
                    nvl(v_num_tran_amt,0),
                    '99999999999999990.99'
                ) ),
                p_i_merchant_cntrycode,
                '0.00',
                v_var_rules,
                NULL,
                v_var_gl_upd_flag,
                p_i_stan,
                p_i_inst_code,
                NULL,
                NULL,
                nvl(v_num_servicetax_amt,0),
                nvl(v_num_cess_amt,0),
                v_var_dr_cr_flag,
                NULL,
                NULL,
                NULL,
                NULL,
                NULL,
                NULL,
                NULL,
                NULL,
                v_var_encr_pan,
                NULL,
                v_var_proxy_number,
                p_i_rvsl_code,
                v_num_acct_number,
                DECODE(
                    p_o_resp_code,
                    '00',
                    nvl(v_num_upd_amt,0),
                    nvl(v_num_acct_bal,0)
                ),
                DECODE(
                    p_o_resp_code,
                    '00',
                    nvl(v_num_upd_ledg_amt,0),
                    nvl(v_num_ledger_bal,0)
                ),
                p_i_international_ind,
                v_var_resp_code,
                p_i_network_id,
                p_i_merchant_zip,
                NULL,
                p_i_pos_verification,
                NULL,
                p_i_merchant_name,
                p_i_merchant_city,
                p_i_atmname_loc,
                v_var_err_msg,
                v_var_cam_type_code,
                v_time_stamp,
                v_var_pan_cardstat,
                1,
                p_i_addl_amt,
                p_i_networkid_switch,
                p_i_networkid_acquirer,
                p_i_network_setl_date,
                nvl(p_i_cvv_verificationtype,'N'),
                p_partial_preauth_ind,
                NULL,
                NULL,
                p_i_merchant_id,
                DECODE(
                    v_var_resp_code,
                    '1000',
                    'Decline due to redemption delay',
                    v_var_err_msg
                ),
                v_var_orgnl_stan,
                v_var_rrn,
                v_var_orgnl_date,
                v_var_orgnl_time
            );

            p_o_auth_id := v_var_auth_id;
        EXCEPTION
            WHEN OTHERS THEN
                ROLLBACK;
                p_o_resp_code := '69';
                p_o_resp_msg := 'Problem while inserting data into transaction log  '
                 || substr(sqlerrm,1,300);
                p_o_resp_id := '69'; --Added for VMS-8018
        END;
    -- logging in Transactionlogdtl table

            BEGIN
                INSERT INTO cms_transaction_log_dtl (
                    ctd_delivery_channel,
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
                    ctd_fee_amount,
                    ctd_waiver_amount,
                    ctd_servicetax_amount,
                    ctd_cess_amount,
                    ctd_bill_amount,
                    ctd_bill_curr,
                    ctd_process_flag,
                    ctd_process_msg,
                    ctd_rrn,
                    ctd_system_trace_audit_no,
                    ctd_inst_code,
                    ctd_customer_card_no_encr,
                    ctd_cust_acct_number,
                    ctd_internation_ind_response,
                    ctd_network_id,
                    ctd_merchant_zip,
                    ctd_ins_user,
                    ctd_ins_date,
                    ctd_pulse_transactionid,
                    ctd_visa_transactionid,
                    ctd_mc_traceid,
                    ctd_cardverification_result,
                    ctd_merchant_id,
                    ctd_country_code,
                    ctd_hashkey_id
                ) VALUES (
                    p_i_del_channel,
                    p_i_txn_code,
                    v_var_txn_type,
                    p_i_msg,
                    p_i_txn_mode,
                    p_i_tran_date,
                    p_i_tran_time,
                    v_var_hash_pan,
                    p_i_txn_amt,
                    p_i_curr_code,
                    v_num_tran_amt,
                    NULL,
                    NULL,
                    v_num_servicetax_amt,
                    v_num_cess_amt,
                    v_num_upd_amt,
                    v_var_card_curr,
                    DECODE(
                    p_o_iso_respcde,
                    '00',
                    'Y',
                    'E'
                    ),
                    v_var_err_msg,
                    p_i_rrn,
                    p_i_stan,
                    p_i_inst_code,
                    v_var_encr_pan,
                    v_num_acct_number,
                    p_i_international_ind,
                    p_i_network_id,
                    p_i_merchant_zip,
                    1,
                    SYSDATE,
                    p_i_pulse_transactionid,
                    p_i_visa_transactionid,
                    p_i_mc_traceid,
                    p_i_cardverification_result,
                    p_i_merchant_id,
                    p_i_merchant_cntrycode,
                    v_var_hashkey_id
                );

            EXCEPTION
                WHEN OTHERS THEN
                    ROLLBACK;
                    v_var_err_msg := 'Problem while inserting in to CMS_TRANSACTION_LOG_DTL '
                     || substr(sqlerrm,1,300);
                    v_var_resp_code := '21';
            END;
            
        
        
        IF p_o_resp_msg = 'OK' THEN
            p_o_resp_msg := TO_CHAR(v_num_upd_amt);
            p_o_ledger_bal := TO_CHAR(v_num_upd_ledg_amt);
        END IF;

    EXCEPTION
        WHEN OTHERS THEN
            ROLLBACK;
            p_o_resp_code := '69';
            p_o_resp_msg := 'Main exception from  authorization '
             || substr(sqlerrm,1,300);
            p_o_resp_id := '69'; --Added for VMS-8018
    END cr_adjust_cmsauth_iso93;

END vmsols;
/
show error;