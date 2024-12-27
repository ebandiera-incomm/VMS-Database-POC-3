CREATE OR REPLACE PROCEDURE VMSCMS.Sp_Change_Pin_Online_CMSAUTH (
   prm_inst_code           IN       NUMBER,
   prm_msg                 IN       VARCHAR2,
   prm_rrn                 IN       VARCHAR2,
   prm_delivery_channel    IN       VARCHAR2,
   prm_term_id             IN       VARCHAR2,
   prm_txn_code            IN       VARCHAR2,
   prm_txn_mode            IN       VARCHAR2,
   prm_tran_date           IN       VARCHAR2,
   prm_tran_time           IN       VARCHAR2,
   prm_card_no             IN       VARCHAR2,
   prm_bank_code           IN       VARCHAR2,
   prm_txn_amt             IN       NUMBER,
   prm_rule_indicator      IN       VARCHAR2,
   prm_rulegrp_id          IN       VARCHAR2,
   prm_mcc_code            IN       VARCHAR2,
   prm_curr_code           IN       VARCHAR2,
   prm_prod_id             IN       VARCHAR2,
   prm_catg_id             IN       VARCHAR2,
   prm_tip_amt             IN       VARCHAR2,
   prm_decline_ruleid      IN       VARCHAR2,
   prm_atmname_loc         IN       VARCHAR2,
   prm_mcccode_groupid     IN       VARCHAR2,
   prm_currcode_groupid    IN       VARCHAR2,
   prm_transcode_groupid   IN       VARCHAR2,
   prm_rules               IN       VARCHAR2,
   prm_preauth_date        IN       DATE,
   prm_consodium_code      IN       VARCHAR2,
   prm_partner_code        IN       VARCHAR2,
   prm_expry_date          IN       VARCHAR2,
   prm_stan                IN       VARCHAR2,
   prm_new_pinoff          IN       VARCHAR2,                -- New pin offset
   prm_lupduser            IN       NUMBER,
   prm_mbr_numb            IN       VARCHAR2,
   prm_rvsl_code           IN       VARCHAR2,
   prm_resp_code           OUT      VARCHAR2,
   prm_auth_message        OUT      VARCHAR2
  -- prm_auth_id             OUT      VARCHAR2,
  -- prm_capture_date        OUT      DATE
--   prm_errmsg              OUT      VARCHAR2
)
AS
   exp_auth_reject_record   EXCEPTION;
   exp_main_reject_record   EXCEPTION;
   v_errmsg                 VARCHAR2 (300)                            := 'OK';
   v_mbrnumb                CMS_APPL_PAN.cap_mbr_numb%TYPE;
   v_crd_val                CMS_INST_PARAM.cip_param_value%TYPE;
   v_cap_prod_catg          CMS_APPL_PAN.cap_prod_catg%TYPE;
   v_cap_card_stat          CMS_APPL_PAN.cap_card_stat%TYPE;
   v_cap_cafgen_flag        CMS_APPL_PAN.cap_cafgen_flag%TYPE;
   v_cap_appl_code          CMS_APPL_PAN.cap_appl_code%TYPE;
   v_appl_code              CMS_APPL_MAST.cam_appl_code%TYPE;
   v_resoncode              CMS_SPPRT_REASONS.csr_spprt_rsncode%TYPE;
   v_txn_code               CMS_FUNC_MAST.cfm_txn_code%TYPE;
   v_txn_mode               CMS_FUNC_MAST.cfm_txn_mode%TYPE;
   v_del_channel            CMS_FUNC_MAST.cfm_delivery_channel%TYPE;
   v_txn_type               CMS_FUNC_MAST.cfm_txn_type%TYPE;
   v_respcode               VARCHAR2 (5);
   v_currcode               VARCHAR2 (3);
   v_old_pin_off            CMS_APPL_PAN.cap_pin_off%TYPE;
   v_repin_auth_id          TRANSACTIONLOG.auth_id%TYPE;
   v_respmsg                VARCHAR2 (500);
   v_authmsg                VARCHAR2 (500);
   v_capture_date           DATE;
   v_terminal_indicator        PCMS_TERMINAL_MAST.PTM_TERMINAL_ID%TYPE;
   v_trandate                DATE;
   v_iso_resp_code            VARCHAR2(2);
   v_log_errmsg                VARCHAR2(500);
   v_check_merchant                                        NUMBER(1);
   v_temp_expiry CMS_APPL_PAN.CAP_EXPRY_DATE%TYPE;
   v_expry_date                         DATE;
    v_atm_usagelimit          cms_translimit_check.ctc_atmusage_limit%TYPE;
   v_pos_usagelimit          cms_translimit_check.ctc_posusage_limit%TYPE;
   v_business_date_tran           DATE;
   v_atm_usageamnt               CMS_TRANSLIMIT_CHECK.CTC_ATMUSAGE_AMT%TYPE;
    v_hash_pan             cms_appl_pan.cap_pan_code%TYPE;
   v_encr_pan             cms_appl_pan.cap_pan_code_encr%TYPE;
    v_rrn_count              NUMBER;
BEGIN                                                        --<< MAIN BEGIN>>
---------------------------------------------------------------------
--   prm_errmsg := 'OK';
   prm_auth_message := 'OK';
   v_log_errmsg     := 'OK';
   v_respmsg     := 'OK';


        --SN CREATE HASH PAN 
        BEGIN
            v_hash_pan := Gethash(prm_card_no);
        EXCEPTION
        WHEN OTHERS THEN
        v_errmsg := 'Error while converting pan ' || SUBSTR(SQLERRM,1,200);
        RAISE	exp_main_reject_record;
        END;
        --EN CREATE HASH PAN

        --SN create encr pan
        BEGIN
            v_encr_pan := Fn_Emaps_Main(prm_card_no);
        EXCEPTION
        WHEN OTHERS THEN
        v_errmsg := 'Error while converting pan ' || SUBSTR(SQLERRM,1,200);
        RAISE	exp_main_reject_record;
        END;
        --EN create encr pan
        
     --Sn get date
        BEGIN
                            v_trandate :=  TO_DATE (SUBSTR(TRIM(prm_tran_date),1,8) || ' '|| SUBSTR(TRIM(prm_tran_time),1,10) ,  'yyyymmdd hh24:mi:ss');
                            /*IF TRIM(v_tran_date) IS NULL THEN
                            prm_resp_code  := '999';
                            prm_resp_msg:= 'Invalid transaction date' || SUBSTR(SQLERRM,1,300);
                            RETURN;
                            END IF;  */
        EXCEPTION
                            WHEN OTHERS THEN
                            v_respcode  := '21';
                            v_errmsg  := 'Problem while converting transaction date ' || SUBSTR(SQLERRM,1 ,200);
                            RAISE exp_main_reject_record;
        END;
                            --En get date

   IF prm_txn_code <> '81'
   THEN
      v_respcode := '12';
      v_errmsg := 'Not a valid request for Pin change';
      RAISE exp_main_reject_record;
   END IF;
   
   
    --Sn Duplicate RRN Check
      
        BEGIN
        
        SELECT count(1) INTO v_rrn_count 
            FROM transactionlog 
            WHERE terminal_id = prm_term_id
            AND rrn = prm_rrn 
            AND business_date = prm_tran_date;
            
          IF v_rrn_count > 0 THEN
            v_respcode := '21';
            v_errmsg := 'Duplicate RRN from the Treminal' || prm_term_id || 'on' || prm_tran_date;
            RAISE exp_main_reject_record;
          
          END IF;  
            
            
        END;
      
      --En Duplicate RRN Check
          

   --Sn select Pan detail
   BEGIN
      SELECT cap_card_stat, cap_prod_catg, cap_cafgen_flag,
             cap_appl_code, cap_mbr_numb, cap_pin_off, cap_expry_date
        INTO v_cap_card_stat, v_cap_prod_catg, v_cap_cafgen_flag,
             v_appl_code, v_mbrnumb, v_old_pin_off, v_expry_date
        FROM CMS_APPL_PAN
       WHERE cap_pan_code = v_hash_pan; --prm_card_no;

   /*   IF v_cap_cafgen_flag = 'N'
      THEN
         v_respcode := '21';
         v_errmsg := 'CAF has to be generated atleast once for this pan ';
         RAISE exp_main_reject_record;
      END IF;*/

      IF v_cap_card_stat <> '1'
      THEN
         v_respcode := '14';
         v_errmsg := 'Not a valid card status for on line pin change ';
         RAISE exp_main_reject_record;
      END IF;
   EXCEPTION
      WHEN exp_main_reject_record
      THEN
         RAISE;
      WHEN NO_DATA_FOUND
      THEN
         v_respcode := '16';
         v_errmsg := 'Invalid Card number ' || prm_card_no;
         RAISE exp_main_reject_record;
      WHEN OTHERS
      THEN
         v_respcode := '21';
         v_errmsg :=
               'Error while selecting card number from appl pan master '
            || SUBSTR (SQLERRM, 1, 200);
         RAISE exp_main_reject_record;
   END;

   --En select Pan detail

   --Sn terminal Indicator find
   /*BEGIN
      SELECT ptm_terminal_indicator
        INTO v_terminal_indicator
        FROM PCMS_TERMINAL_MAST
       WHERE ptm_terminal_id = prm_term_id
         AND ptm_inst_code = prm_inst_code;
   EXCEPTION
      WHEN NO_DATA_FOUND
      THEN
           v_respcode := '27';
         v_errmsg :=
               'Terminal indicator is not declared for terminal id'
            || prm_term_id;
         RAISE exp_main_reject_record;
      WHEN OTHERS
      THEN
         v_respcode := '21';
         v_errmsg :=
               'Terminal indicator is not declared for terminal id'
            || SQLERRM
            || ' '
            || SQLCODE;
         RAISE exp_main_reject_record;
   END;*/

   
   --Sn check Merchant
                      /*  BEGIN
                            SELECT 1 
                            INTO   v_check_merchant    
                            FROM   MCCODE                                 
                            WHERE  MCCODE = prm_mcc_code;
                        EXCEPTION
                           WHEN NO_DATA_FOUND THEN
                              v_respcode  := '21';
                               v_errmsg    := 'Merchant code is not found in master ' ;
                               RAISE exp_main_reject_record;
                              WHEN OTHERS THEN
                              v_respcode  := '21';
                               v_errmsg    := 'Error while selecting Merchant detail'|| SUBSTR(SQLERRM,1,200) ;
                               RAISE exp_main_reject_record;
                        END; */
                                    
                        --En check Merchant
                        
     --Commented for CMSAuth Expiry date check done in java             
    --Sn check expry date
    /*BEGIN
         IF TRIM(prm_expry_date) IS NOT NULL THEN
         v_temp_expiry := LAST_DAY(TO_DATE('01'||prm_expry_date || ' 23:59:59','ddyymm hh24:mi:ss'));         
             IF  TO_DATE(v_temp_expiry,'dd-MM-yy') = LAST_DAY(TO_DATE(v_expry_date,'dd-MM-yy')) THEN 
                IF TO_DATE(SYSDATE,'dd-mm-yy') < v_temp_expiry THEN
                            v_expry_date := LAST_DAY(TO_DATE('01'||prm_expry_date || ' 23:59:59','ddyymm hh24:mi:ss'));
                ELSE
                            v_respcode  := '33';
                            v_errmsg := 'EXPIRED CARD';
                            RAISE exp_main_reject_record;
                END IF;
            ELSE
                        RAISE  exp_main_reject_record;
            END IF;
         ELSE
              RAISE exp_main_reject_record;      
         END IF;
    EXCEPTION
         WHEN OTHERS THEN
         IF v_respcode != '33' THEN
                 v_errmsg   := 'PROBLEM WHILE CONVERTING EXPIRY DATE '  || SUBSTR(SQLERRM,1,300);
                v_respcode := '40';   ---ISO MESSAGE FOR DATABASE ERROR -- Invalid Expiry Date Response Code - 220509
        END IF;
        RAISE exp_main_reject_record;
    END;*/
    --En check expry date

   --Sn call to authorize txn
   BEGIN
      v_currcode := prm_curr_code;
      sp_authorize_txn_cms_auth (prm_inst_code,
                        prm_msg,
                        prm_rrn,
                        prm_delivery_channel,
                        prm_term_id,
                        prm_txn_code,
                        prm_txn_mode,
                        prm_tran_date,
                        prm_tran_time,
                        prm_card_no,
                        prm_bank_code,
                        prm_txn_amt,
                        prm_rule_indicator,
                        prm_rulegrp_id,
                        prm_mcc_code,
                        prm_curr_code,
                        prm_prod_id,
                        prm_catg_id,
                        prm_tip_amt,
                        prm_decline_ruleid,
                        prm_atmname_loc,
                        prm_mcccode_groupid,
                        prm_currcode_groupid,
                        prm_transcode_groupid,
                        prm_rules,
                        prm_preauth_date,
                        prm_consodium_code,
                        prm_partner_code,
                        prm_expry_date,
                        prm_stan,
                        prm_mbr_numb,
                        prm_rvsl_code,                        
                        v_repin_auth_id,
                        v_respcode,
                        v_respmsg,
                        v_capture_date
                       );

      IF v_respcode <> '00' AND v_respmsg <> 'OK'
      THEN

          v_authmsg := v_respmsg;
         --v_errmsg := 'Error from auth process' || v_respmsg;
         RAISE exp_auth_reject_record;
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
                  'Error from Card authorization' || SUBSTR (SQLERRM, 1, 200);
         RAISE exp_main_reject_record;
   END;

   --Sn update the pan Pin offset
   BEGIN
      UPDATE CMS_APPL_PAN
         SET cap_pin_off = prm_new_pinoff,
             cap_lupd_date = SYSDATE
       WHERE cap_pan_code = v_hash_pan --prm_card_no 
       AND cap_mbr_numb = v_mbrnumb;

      IF SQL%ROWCOUNT <> 1
      THEN
         v_respcode := '21';
         v_errmsg := 'Error while updating Pin ';
         RAISE exp_main_reject_record;
      END IF;
   EXCEPTION
      WHEN OTHERS
      THEN
           v_respcode := '21';
         v_errmsg := 'Error while updating Pin ' || SUBSTR (SQLERRM, 1, 200);
         RAISE exp_main_reject_record;
   END;

   --Sn update the pan Pin offset

   --Sn create a record in pan spprt
   BEGIN
      SELECT csr_spprt_rsncode
        INTO v_resoncode
        FROM CMS_SPPRT_REASONS
       WHERE csr_spprt_key = 'PIN_CHANGE' AND ROWNUM < 2;
   EXCEPTION
      WHEN NO_DATA_FOUND
      THEN
         v_respcode := '21';
         v_errmsg := 'Repin reason code is not present in support master';
         RAISE exp_main_reject_record;
      WHEN OTHERS
      THEN
         v_respcode := '21';
         v_errmsg :=
               'Error while selecting reason code from support master'
            || SUBSTR (SQLERRM, 1, 200);
         RAISE exp_main_reject_record;
   END;

   BEGIN
      INSERT INTO CMS_PAN_SPPRT
                  (cps_inst_code, cps_pan_code, cps_mbr_numb, cps_prod_catg,
                   cps_spprt_key, cps_spprt_rsncode, cps_func_remark,
                   cps_ins_user, cps_lupd_user, cps_cmd_mode,CPS_PAN_CODE_ENCR
                  )
           VALUES (prm_inst_code, --prm_card_no
           v_hash_pan, v_mbrnumb, v_cap_prod_catg,
                   'PIN_CHANGE', v_resoncode, 'Online Pin Change',
                   prm_lupduser, prm_lupduser, 0,v_encr_pan
                  );
   EXCEPTION
      WHEN OTHERS
      THEN
         v_respcode := '21';
         v_errmsg :=
               'Error while inserting records into card support master'
            || SUBSTR (SQLERRM, 1, 200);
         RAISE exp_main_reject_record;
   END;

   --En create a record in pan spprt

   --SN Insert Successful Records in CMS_REPIN_HIST
   BEGIN
      INSERT INTO CMS_REPIN_HIST
                  (crh_pan_code, crh_mbr_numb, crh_old_pin_off,
                   crh_new_pin_off, crh_auth_id, crh_rrn, crh_stan,
                   crh_business_date, crh_business_time, crh_ins_user,
                   crh_ins_date,CRH_PAN_CODE_ENCR
                  )
           VALUES (--prm_card_no
           v_hash_pan, v_mbrnumb, v_old_pin_off,
                   prm_new_pinoff, v_repin_auth_id, prm_rrn, prm_stan,
                   prm_tran_date, prm_tran_time, prm_lupduser,
                   SYSDATE,v_encr_pan
                  );
   EXCEPTION
      WHEN OTHERS
      THEN
         v_respcode := '21';
         v_errmsg :=
               'Error while inserting records into Repin history '
            || SUBSTR (SQLERRM, 1, 200);
         RAISE exp_main_reject_record;
   END;
 --EN Insert Successful Records in CMS_REPIN_HIST
       prm_resp_code := v_respcode;
  IF v_terminal_indicator IS NOT NULL AND v_repin_auth_id IS NOT NULL AND v_respcode IS NOT NULL THEN
           v_authmsg := RPAD (v_repin_auth_id,'6', ' ')||RPAD (v_terminal_indicator,'1', ' ');
          prm_auth_message := v_authmsg;
  END IF;



  --Sn create successful response code

   v_respcode := '1';
  BEGIN
                    SELECT CMS_ISO_RESPCDE
                    INTO   prm_resp_code
                    FROM   CMS_RESPONSE_MAST
                    WHERE  CMS_INST_CODE        = prm_inst_code
                    AND    CMS_DELIVERY_CHANNEL    = prm_delivery_channel
                    AND    CMS_RESPONSE_ID        = v_respcode ;

                     --prm_auth_message := v_errmsg;
                EXCEPTION
                    WHEN OTHERS THEN
                     prm_auth_message  := 'Problem while selecting data from response master ' || v_respcode ||SUBSTR(SQLERRM,1,300);
                     prm_resp_code := '99';
                    RETURN;
 END;
 
 BEGIN
         
             SELECT ctc_atmusage_limit,ctc_posusage_limit,CTC_BUSINESS_DATE
                INTO v_atm_usagelimit,v_pos_usagelimit,v_business_date_tran
                FROM cms_translimit_check WHERE ctc_inst_code = prm_inst_code
                AND ctc_pan_code = v_hash_pan --prm_card_no 
                AND ctc_mbr_numb = prm_mbr_numb;
            
            EXCEPTION
                WHEN NO_DATA_FOUND THEN
                v_errmsg :='Cannot get the Transaction Limit Details of the Card'|| SUBSTR (SQLERRM, 1, 300);
                prm_resp_code := '21';
            RAISE exp_auth_reject_record;
        END;


         BEGIN
         IF prm_delivery_channel = '01' THEN
         
            IF v_trandate > v_business_date_tran THEN
            
                v_atm_usageamnt :=  0;
                v_atm_usagelimit := 1;
                
               UPDATE cms_translimit_check
               SET ctc_atmusage_amt = v_atm_usageamnt,ctc_atmusage_limit = v_atm_usagelimit,CTC_POSUSAGE_AMT=0 ,CTC_POSUSAGE_LIMIT=0,
               ctc_preauthusage_limit=0,
               ctc_business_date = TO_DATE (prm_tran_date || '23:59:59','yymmdd' || 'hh24:mi:ss')
             WHERE ctc_inst_code = prm_inst_code
               AND ctc_pan_code = v_hash_pan--prm_card_no
               AND ctc_mbr_numb = prm_mbr_numb;
            
            ELSE
                
                v_atm_usagelimit := v_atm_usagelimit + 1;
                
                UPDATE cms_translimit_check
               SET ctc_atmusage_limit = v_atm_usagelimit               
              -- ctc_business_date = TO_DATE (prm_tran_date || '23:59:59','yymmdd' || 'hh24:mi:ss')
             WHERE ctc_inst_code = prm_inst_code
               AND ctc_pan_code = v_hash_pan--prm_card_no
               AND ctc_mbr_numb = prm_mbr_numb;
            
            END IF;
            

           
         END IF;

         
      END;

        BEGIN
             Sp_Log_Transaction(prm_inst_code,
                                   prm_msg,
                                   prm_rrn,
                                   prm_delivery_channel,
                                   prm_term_id,
                                   prm_txn_code,
                                   prm_txn_mode,
                                   prm_tran_date,
                                   prm_tran_time,
                                   prm_card_no,
                                   prm_bank_code,
                                   prm_txn_amt,
                                   prm_rule_indicator,
                                   prm_rulegrp_id,
                                   prm_mcc_code,
                                   prm_curr_code,
                                   prm_prod_id,
                                   prm_catg_id,
                                   prm_tip_amt,
                                   prm_decline_ruleid,
                                   prm_atmname_loc,
                                   prm_mcccode_groupid,
                                   prm_currcode_groupid,
                                   prm_transcode_groupid,
                                   prm_rules,
                                   prm_preauth_date,
                                   prm_consodium_code,
                                   prm_partner_code,
                                   prm_expry_date,
                                   prm_stan,
                                   v_repin_auth_id,
                                   v_respcode,
                                   v_authmsg,
                                   v_trandate,
                                   v_log_errmsg
                                   );
                        IF v_log_errmsg <> 'OK' THEN
                           prm_resp_code := '99';
                           prm_auth_message  := 'Error while creating a transaction log ' || v_log_errmsg;
                           RETURN;
                        END IF;

                EXCEPTION
                         WHEN OTHERS THEN
                          prm_resp_code := '99';
                          prm_auth_message  := 'Error while creating a transaction log ' || SUBSTR(SQLERRM,1,200);
                          RETURN;

                END;

  --En create successful response code
---------------------------------------------------------------------
EXCEPTION                                                --<< MAIN EXCEPTION>>
   WHEN exp_auth_reject_record
   THEN
   ROLLBACK;
      prm_resp_code := v_respcode ;
      prm_auth_message := v_authmsg;


                BEGIN
                Sp_Log_Transaction(prm_inst_code,
                                   prm_msg,
                                   prm_rrn,
                                   prm_delivery_channel,
                                   prm_term_id,
                                   prm_txn_code,
                                   prm_txn_mode,
                                   prm_tran_date,
                                   prm_tran_time,
                                   prm_card_no,
                                   prm_bank_code,
                                   prm_txn_amt,
                                   prm_rule_indicator,
                                   prm_rulegrp_id,
                                   prm_mcc_code,
                                   prm_curr_code,
                                   prm_prod_id,
                                   prm_catg_id,
                                   prm_tip_amt,
                                   prm_decline_ruleid,
                                   prm_atmname_loc,
                                   prm_mcccode_groupid,
                                   prm_currcode_groupid,
                                   prm_transcode_groupid,
                                   prm_rules,
                                   prm_preauth_date,
                                   prm_consodium_code,
                                   prm_partner_code,
                                   prm_expry_date,
                                   prm_stan,
                                   v_repin_auth_id,
                                   v_respcode,
                                   v_authmsg,
                                   v_trandate,
                                   v_log_errmsg
                                   );
                        IF v_log_errmsg <> 'OK' THEN
                           prm_resp_code := '99';
                           prm_auth_message  := 'Error while creating a transaction log ' || v_log_errmsg;
                           RETURN;
                        END IF;

                EXCEPTION
                         WHEN OTHERS THEN
                          prm_resp_code := '99';
                          prm_auth_message  := 'Error while creating a transaction log ' || SUBSTR(SQLERRM,1,200);
                          RETURN;

                END;
      --prm_errmsg := 'OK';
        BEGIN
         
             SELECT ctc_atmusage_limit,ctc_posusage_limit,CTC_BUSINESS_DATE
                INTO v_atm_usagelimit,v_pos_usagelimit,v_business_date_tran
                FROM cms_translimit_check WHERE ctc_inst_code = prm_inst_code
                AND ctc_pan_code = v_hash_pan -- prm_card_no 
                 AND ctc_mbr_numb = prm_mbr_numb;
            
            EXCEPTION
                WHEN NO_DATA_FOUND THEN
                v_errmsg :='Cannot get the Transaction Limit Details of the Card'|| SUBSTR (SQLERRM, 1, 300);
                prm_resp_code := '21';
            RAISE exp_auth_reject_record;
        END;


         BEGIN
         IF prm_delivery_channel = '01' THEN
         
            IF v_trandate > v_business_date_tran THEN
            
                v_atm_usageamnt :=  0;
                v_atm_usagelimit := 1;
                
               UPDATE cms_translimit_check
               SET ctc_atmusage_amt = v_atm_usageamnt,ctc_atmusage_limit = v_atm_usagelimit,CTC_POSUSAGE_AMT=0 ,CTC_POSUSAGE_LIMIT=0,
               ctc_preauthusage_limit=0,
               ctc_business_date = TO_DATE (prm_tran_date || '23:59:59','yymmdd' || 'hh24:mi:ss')
             WHERE ctc_inst_code = prm_inst_code
               AND ctc_pan_code = v_hash_pan --prm_card_no
               AND ctc_mbr_numb = prm_mbr_numb;
            
            ELSE
                
                v_atm_usagelimit := v_atm_usagelimit + 1;
                
                UPDATE cms_translimit_check
               SET ctc_atmusage_limit = v_atm_usagelimit,
               ctc_business_date = TO_DATE (prm_tran_date || '23:59:59','yymmdd' || 'hh24:mi:ss')
             WHERE ctc_inst_code = prm_inst_code
               AND ctc_pan_code = v_hash_pan --prm_card_no
               AND ctc_mbr_numb = prm_mbr_numb;
            
            END IF;
            

           
         END IF;

         
      END;

   WHEN exp_main_reject_record
   THEN
    ROLLBACK;
               BEGIN
                    SELECT CMS_ISO_RESPCDE
                    INTO    v_iso_resp_code
                    FROM   CMS_RESPONSE_MAST
                    WHERE  CMS_INST_CODE        = prm_inst_code
                    AND    CMS_DELIVERY_CHANNEL    = prm_delivery_channel
                    AND    CMS_RESPONSE_ID        = v_respcode ;

                     prm_resp_code    := v_iso_resp_code;
                     prm_auth_message := v_errmsg;
                EXCEPTION
                    WHEN OTHERS THEN
                     prm_auth_message  := 'Problem while selecting data from response master ' || v_respcode ||SUBSTR(SQLERRM,1,300);
                     prm_resp_code := '99';
                    RETURN;
                END;


                BEGIN
                Sp_Log_Transaction(prm_inst_code,
                                   prm_msg,
                                   prm_rrn,
                                   prm_delivery_channel,
                                   prm_term_id,
                                   prm_txn_code,
                                   prm_txn_mode,
                                   prm_tran_date,
                                   prm_tran_time,
                                   prm_card_no,
                                   prm_bank_code,
                                   prm_txn_amt,
                                   prm_rule_indicator,
                                   prm_rulegrp_id,
                                   prm_mcc_code,
                                   prm_curr_code,
                                   prm_prod_id,
                                   prm_catg_id,
                                   prm_tip_amt,
                                   prm_decline_ruleid,
                                   prm_atmname_loc,
                                   prm_mcccode_groupid,
                                   prm_currcode_groupid,
                                   prm_transcode_groupid,
                                   prm_rules,
                                   prm_preauth_date,
                                   prm_consodium_code,
                                   prm_partner_code,
                                   prm_expry_date,
                                   prm_stan,
                                   v_repin_auth_id,
                                   v_respcode,
                                   v_errmsg,
                                   v_trandate,
                                   v_log_errmsg
                                   );
                        IF v_log_errmsg <> 'OK' THEN
                           prm_resp_code := '99';
                           prm_auth_message  := 'Error while creating a transaction log ' || v_log_errmsg;
                           RETURN;
                        END IF;

                EXCEPTION
                         WHEN OTHERS THEN
                          prm_resp_code := '99';
                          prm_auth_message  := 'Error while creating a transaction log ' || SUBSTR(SQLERRM,1,200);
                          RETURN;

                END;


     --  prm_errmsg := v_errmsg;

   WHEN OTHERS
   THEN
      ROLLBACK;
              BEGIN
                    SELECT CMS_ISO_RESPCDE
                    INTO    v_iso_resp_code
                    FROM   CMS_RESPONSE_MAST
                    WHERE  CMS_INST_CODE        = prm_inst_code
                    AND    CMS_DELIVERY_CHANNEL    = prm_delivery_channel
                    AND    CMS_RESPONSE_ID        = '21' ;

                     prm_resp_code    := v_iso_resp_code;
                     prm_auth_message := v_errmsg;

                EXCEPTION
                    WHEN OTHERS THEN
                     prm_auth_message  := 'Problem while selecting data from response master ' || v_respcode ||SUBSTR(SQLERRM,1,300);
                     prm_resp_code := '99';
                    RETURN;
                END;

                BEGIN
                Sp_Log_Transaction(prm_inst_code,
                                   prm_msg,
                                   prm_rrn,
                                   prm_delivery_channel,
                                   prm_term_id,
                                   prm_txn_code,
                                   prm_txn_mode,
                                   prm_tran_date,
                                   prm_tran_time,
                                   prm_card_no,
                                   prm_bank_code,
                                   prm_txn_amt,
                                   prm_rule_indicator,
                                   prm_rulegrp_id,
                                   prm_mcc_code,
                                   prm_curr_code,
                                   prm_prod_id,
                                   prm_catg_id,
                                   prm_tip_amt,
                                   prm_decline_ruleid,
                                   prm_atmname_loc,
                                   prm_mcccode_groupid,
                                   prm_currcode_groupid,
                                   prm_transcode_groupid,
                                   prm_rules,
                                   prm_preauth_date,
                                   prm_consodium_code,
                                   prm_partner_code,
                                   prm_expry_date,
                                   prm_stan,
                                   v_repin_auth_id,
                                   '21',
                                   v_errmsg,
                                   v_trandate,
                                   v_log_errmsg
                                   );
                        IF v_log_errmsg <> 'OK' THEN
                           prm_resp_code := '99';
                           prm_auth_message  := 'Error while creating a transaction log ' || v_log_errmsg;
                           RETURN;
                        END IF;
                        
                        BEGIN
         
             SELECT ctc_atmusage_limit,ctc_posusage_limit,CTC_BUSINESS_DATE
                INTO v_atm_usagelimit,v_pos_usagelimit,v_business_date_tran
                FROM cms_translimit_check WHERE ctc_inst_code = prm_inst_code
                AND ctc_pan_code = v_hash_pan -- prm_card_no
                 AND ctc_mbr_numb = prm_mbr_numb;
            
            EXCEPTION
                WHEN NO_DATA_FOUND THEN
                v_errmsg :='Cannot get the Transaction Limit Details of the Card'|| SUBSTR (SQLERRM, 1, 300);
                prm_resp_code := '21';
            RAISE exp_auth_reject_record;
        END;


         BEGIN
         IF prm_delivery_channel = '01' THEN
         
            IF v_trandate > v_business_date_tran THEN
            
                v_atm_usageamnt :=  0;
                v_atm_usagelimit := 1;
                
               UPDATE cms_translimit_check
               SET ctc_atmusage_amt = v_atm_usageamnt,ctc_atmusage_limit = v_atm_usagelimit,CTC_POSUSAGE_AMT=0 ,CTC_POSUSAGE_LIMIT=0,
               ctc_preauthusage_limit=0,
               ctc_business_date = TO_DATE (prm_tran_date || '23:59:59','yymmdd' || 'hh24:mi:ss')
             WHERE ctc_inst_code = prm_inst_code
               AND ctc_pan_code = v_hash_pan --prm_card_no
               AND ctc_mbr_numb = prm_mbr_numb;
            
            ELSE
                
                v_atm_usagelimit := v_atm_usagelimit + 1;
                
                UPDATE cms_translimit_check
               SET ctc_atmusage_limit = v_atm_usagelimit,
               ctc_business_date = TO_DATE (prm_tran_date || '23:59:59','yymmdd' || 'hh24:mi:ss')
             WHERE ctc_inst_code = prm_inst_code
               AND ctc_pan_code = v_hash_pan --prm_card_no
               AND ctc_mbr_numb = prm_mbr_numb;
            
            END IF;
            

           
         END IF;

         
      END;

                EXCEPTION
                         WHEN OTHERS THEN
                          prm_resp_code := '99';
                          prm_auth_message  := 'Error while creating a transaction log ' || SUBSTR(SQLERRM,1,200);
                          RETURN;

                END;


  --    prm_errmsg := ' Error from main ' || SUBSTR (SQLERRM, 1, 200);

END;                                                           --<< MAIN END>>
/


