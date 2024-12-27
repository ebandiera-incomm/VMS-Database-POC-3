create or replace PROCEDURE        vmscms.sp_cmsauth_check (
   p_inst_code           IN       NUMBER,
   p_msg_type            IN       VARCHAR2,
   p_rrn                 IN       VARCHAR2,
   p_delivery_channel    IN       cms_delchannel_mast.cdm_channel_code%TYPE,
   p_txn_code            IN       cms_transaction_mast.ctm_tran_code%TYPE,
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
   p_card_stat           IN       cms_appl_pan.cap_card_stat%TYPE,
   p_expry_date          IN       cms_appl_pan.cap_expry_date%TYPE,
   p_prod_code           IN       cms_appl_pan.cap_prfl_code%TYPE,
   p_card_type           IN       cms_appl_pan.cap_card_type%TYPE,
   p_prfl_flag           IN       cms_transaction_mast.ctm_prfl_flag%TYPE,
   p_prfl_code           IN       cms_appl_pan.cap_prfl_code%TYPE,
   p_mcc_code            IN       VARCHAR2,
   p_international_ind   IN       VARCHAR2,
   p_pos_verfication     IN       VARCHAR2,
   p_resp_code           OUT      VARCHAR2,
   p_res_msg             OUT      VARCHAR2,
   p_comb_hash           OUT      pkg_limits_check.type_hash
)
AS
   v_tran_date         DATE;
   v_err_msg           VARCHAR2 (500)             DEFAULT 'OK';
   exp_reject_record   EXCEPTION;
   v_tran_amt          NUMBER (9, 3);
   v_card_curr         VARCHAR2 (5);
   v_resp_cde          VARCHAR2 (5);
   v_comb_hash         pkg_limits_check.type_hash;
   v_status_chk        NUMBER;
   v_precheck_flag     NUMBER;
/**********************************************************************************************
                  * Created Date     :08-August-2014
                  * Created By       :  Dhinakaran B
                  * PURPOSE          : FWR-67
                  
                  * Modified Date     : 23-June-2016
                  * Modified By       : MageshKumar
                  * PURPOSE           : VISA Tokenization
                  * Reviewed By       : Saravanakumar/Pankaj
                  * Build             : VMSGPRHOSTCSD4.4_B0001
                  
                  * Modified Date     : 06-June-2016
                  * Modified By       : MageshKumar
                  * PURPOSE           : VISA Tokenization
                  * Reviewed By       : Saravanakumar/Pankaj
                  * Build             : VMSGPRHOSTCSD4.4_B0002
/**********************************************************************************************/
BEGIN
   -- To Convert Currency
   IF p_tran_amount IS NOT NULL
   THEN
      IF (p_tran_amount >= 0)
      THEN
         v_tran_amt := p_tran_amount;

         BEGIN
            sp_convert_curr (p_inst_code,
                             p_curr_code,
                             p_pan_code,
                             p_tran_amount,
                             v_tran_date,
                             v_tran_amt,
                             v_card_curr,
                             v_err_msg,
                             p_prod_code,
                             p_card_type
                            );

            IF v_err_msg <> 'OK'
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
                     'Error from currency conversion '
                  || SUBSTR (SQLERRM, 1, 200);
               RAISE exp_reject_record;
         END;
      ELSE
         v_resp_cde := '43';
         v_err_msg := 'INVALID AMOUNT';
         RAISE exp_reject_record;
      END IF;
   END IF;

   -- End  Convert Currency

   --Sn GPR Card status check
   
  
   BEGIN
      sp_status_check_gpr (p_inst_code,
                           p_pan_code,
                           p_delivery_channel,
                           p_expry_date,
                           p_card_stat,
                           p_txn_code,
                           p_txn_mode,
                           p_prod_code,
                           p_card_type,
                           p_msg_type,
                           p_tran_date,
                           p_tran_time,
                           NULL,                        --p_international_ind,
                           NULL,                          --p_pos_verfication,
                           NULL,                                 --p_mcc_code,
                           v_resp_cde,
                           v_err_msg
                          );

      IF (   (v_resp_cde <> '1' AND v_err_msg <> 'OK')
          OR (v_resp_cde <> '0' AND v_err_msg <> 'OK')
         )
      THEN
         RAISE exp_reject_record;
      ELSE
         v_status_chk := v_resp_cde;
         v_resp_cde := '1';
      END IF;
   EXCEPTION
      WHEN exp_reject_record
      THEN
         RAISE;
      WHEN OTHERS
      THEN
         v_resp_cde := '21';
         v_err_msg :=
               'Error from GPR Card Status Check 33 '
            || SUBSTR (SQLERRM, 1, 200)
            || v_resp_cde;
         RAISE exp_reject_record;
   END;

   --En GPR Card status check
   IF v_status_chk = '1'
   THEN
      -- Expiry Check
      BEGIN
         IF TO_DATE (p_tran_date, 'YYYYMMDD') >
                               LAST_DAY (TO_CHAR (p_expry_date, 'DD-MON-YY'))
         THEN
            v_resp_cde := '13';
            v_err_msg := 'EXPIRED CARD';
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
                    'ERROR IN EXPIRY DATE CHECK ' || SUBSTR (SQLERRM, 1, 200);
            RAISE exp_reject_record;
      END;

      --Sn select authorization processe flag
      BEGIN
         SELECT ptp_param_value
           INTO v_precheck_flag
           FROM pcms_tranauth_param
          WHERE ptp_param_name = 'PRE CHECK' AND ptp_inst_code = p_inst_code;
      EXCEPTION
         WHEN NO_DATA_FOUND
         THEN
            v_resp_cde := '21';                      --only for master setups
            v_err_msg :=
                        'Master set up is not done for Authorization Process';
            RAISE exp_reject_record;
         WHEN OTHERS
         THEN
            v_resp_cde := '21';                      --only for master setups
            v_err_msg :=
                  'Error while selecting precheck flag'
               || SUBSTR (SQLERRM, 1, 200);
            RAISE exp_reject_record;
      END;

      --Sn check for precheck
      IF v_precheck_flag = 1
      THEN
         BEGIN
            sp_precheck_txn (p_inst_code,
                             p_pan_code,
                             p_delivery_channel,
                             p_expry_date,
                             p_card_stat,
                             p_txn_code,
                             p_txn_mode,
                             p_tran_date,
                             p_tran_time,
                             v_tran_amt,
                             NULL,
                             NULL,
                             v_resp_cde,
                             v_err_msg
                            );

            IF (v_resp_cde <> '1' OR v_err_msg <> 'OK')
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
                     'Error from precheck processes 44444'
                  || SUBSTR (SQLERRM, 1, 200);
               RAISE exp_reject_record;
         END;
      END IF;
   END IF;
   
   

   --Start  Limit check
   IF p_prfl_flag IS NOT NULL AND p_prfl_flag = 'Y'
   THEN
      BEGIN
         pkg_limits_check.sp_limits_check
                                  (p_hash_pan,
                                   NULL,
                                   NULL,
                                   p_mcc_code,                   --p_mcc_code,
                                   p_txn_code,
                                   p_tran_type,
                                   p_international_ind, --p_international_ind,
                                   p_pos_verfication,     --p_pos_verfication,
                                   p_inst_code,
                                   NULL,
                                   p_prfl_code,
                                   v_tran_amt,
                                   p_delivery_channel,
                                   v_comb_hash,
                                   v_resp_cde,
                                   v_err_msg
                                  );

         IF v_err_msg <> 'OK'
         THEN
            IF p_delivery_channel = '13' AND p_txn_code = '28'
            THEN
               v_err_msg := 'MATCHRULEFAILED' || v_err_msg;
               RAISE exp_reject_record;
            END IF;

            RAISE exp_reject_record;
         END IF;

         p_comb_hash := v_comb_hash;
      EXCEPTION
         WHEN exp_reject_record
         THEN
            RAISE;
         WHEN OTHERS
         THEN
            v_resp_cde := '21';
            v_err_msg :=
                'Error from Limit Check Process ' || SUBSTR (SQLERRM, 1, 200);
            RAISE exp_reject_record;
      END;
   END IF;
--End  Limit check
      p_resp_code := v_resp_cde;
      p_res_msg := v_err_msg;
      
EXCEPTION
   WHEN exp_reject_record
   THEN
      p_resp_code := v_resp_cde;
      p_res_msg := v_err_msg;
   WHEN OTHERS
   THEN
      ROLLBACK;
      p_resp_code := '69';                                 -- Server Declined
      p_res_msg :=
            'Main exception from  authorization ' || SUBSTR (SQLERRM, 1, 300);
END;
/
show error