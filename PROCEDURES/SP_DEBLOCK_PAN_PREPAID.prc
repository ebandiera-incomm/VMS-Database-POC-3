CREATE OR REPLACE PROCEDURE VMSCMS.Sp_Deblock_Pan_Prepaid(
   prm_instcode       IN       NUMBER,
   prm_rrn            IN       VARCHAR2,
   prm_terminalid     IN       VARCHAR2,
   prm_stan           IN       VARCHAR2,
   prm_trandate       IN       VARCHAR2,
   prm_trantime       IN       VARCHAR2,
   prm_acctno         IN       VARCHAR2,
   prm_filename       IN       VARCHAR2,
   prm_remrk          IN       VARCHAR2,
   prm_resoncode      IN       NUMBER,
   prm_amount         IN       NUMBER,
   prm_refno          IN       VARCHAR2,
   prm_paymentmode    IN       VARCHAR2,
   prm_instrumentno   IN       VARCHAR2,
   prm_drawndate      IN       DATE,
   prm_currcode       IN       VARCHAR2,
   prm_lupduser       IN       NUMBER,
   prm_auth_message   OUT      VARCHAR2,
   prm_errmsg         OUT      VARCHAR2
)
/*************************************************
     * VERSION             :  1.0
     * Created Date       : 29/APR/2009
     * Created By        : Kaustubh.Dave
     * PURPOSE          : DeBlock card for a perticular card number
     * Modified By:    :
     * Modified Date  :
  *************************************************/
AS
   v_cap_prod_catg          CMS_APPL_PAN.cap_prod_catg%TYPE;
   v_cap_card_stat          CMS_APPL_PAN.cap_card_stat%TYPE;
   v_cap_cafgen_flag        CMS_APPL_PAN.cap_cafgen_flag%TYPE;
   v_cap_appl_code          CMS_APPL_PAN.cap_appl_code%TYPE;
   v_firsttime_topup        CMS_APPL_PAN.cap_firsttime_topup%TYPE;
   v_errmsg                 VARCHAR2 (300)                            := 'OK';
   v_varprodflag            CMS_PROD_MAST.cpm_var_flag%TYPE;
   v_currcode               VARCHAR2 (3);
   v_appl_code              CMS_APPL_MAST.cam_appl_code%TYPE;
   v_resoncode              CMS_SPPRT_REASONS.csr_spprt_rsncode%TYPE;
   v_respcode               VARCHAR2 (5);
   v_respmsg                VARCHAR2 (500);
   v_authmsg                VARCHAR2 (500);
   v_capture_date           DATE;
   v_mbrnumb                CMS_APPL_PAN.cap_mbr_numb%TYPE;
   v_txn_code               CMS_FUNC_MAST.cfm_txn_code%TYPE;
   v_txn_mode               CMS_FUNC_MAST.cfm_txn_mode%TYPE;
   v_del_channel            CMS_FUNC_MAST.cfm_delivery_channel%TYPE;
   v_txn_type               CMS_FUNC_MAST.cfm_txn_type%TYPE;
   v_block_auth_id          TRANSACTIONLOG.auth_id%TYPE;
   exp_main_reject_record   EXCEPTION;
   exp_auth_reject_record   EXCEPTION;
BEGIN                                                        --<< MAIN BEGIN>>
   prm_errmsg := 'OK';
   prm_auth_message := 'OK';
   v_resoncode := prm_resoncode;

   IF prm_remrk IS NULL
   THEN
      v_errmsg := 'Please enter appropriate remrk';
      RAISE exp_main_reject_record;
   END IF;

   --------------------------------Sn select Pan detail------------------------------
   BEGIN
      SELECT cap_card_stat, cap_prod_catg, cap_cafgen_flag,
             cap_appl_code, cap_mbr_numb
        INTO v_cap_card_stat, v_cap_prod_catg, v_cap_cafgen_flag,
             v_appl_code, v_mbrnumb
        FROM CMS_APPL_PAN
       WHERE cap_pan_code = prm_acctno;
/*
      IF v_cap_cafgen_flag = 'N'
      THEN
         v_errmsg := 'CAF has to be generated atleast once for this pan ';
         RAISE exp_main_reject_record;
      END IF;
*/
      IF v_cap_card_stat <> '4'
      THEN
         v_errmsg := 'Not a valid card status for Deblocking ';
         RAISE exp_main_reject_record;
      END IF;
   EXCEPTION
      WHEN exp_main_reject_record
      THEN
         RAISE;
      WHEN NO_DATA_FOUND
      THEN
         v_errmsg := 'Invalid Card number ' || prm_acctno;
         RAISE exp_main_reject_record;
      WHEN OTHERS
      THEN
         v_errmsg := 'Error while selecting card number ' || prm_acctno;
         RAISE exp_main_reject_record;
   END;

   --------------------------------En select Pan detail------------------------------

   --------------------------------Sn select transaction code,mode and del channel------------------------------
   BEGIN
      SELECT cfm_txn_code, cfm_txn_mode, cfm_delivery_channel, cfm_txn_type
        INTO v_txn_code, v_txn_mode, v_del_channel, v_txn_type
        FROM CMS_FUNC_MAST
       WHERE cfm_func_code = 'UNBLOCK';
   EXCEPTION
      WHEN NO_DATA_FOUND
      THEN
         v_errmsg := 'Support function block not defined in master';
         RAISE exp_main_reject_record;
      WHEN OTHERS
      THEN
         v_errmsg :=
               'Error while selecting support function detail '
            || SUBSTR (SQLERRM, 1, 200);
         RAISE exp_main_reject_record;
   END;

   --------------------------------En select transaction code,mode and del channel------------------------------
   --------------------------------Sn For Debit Card No need of using authorixation----------------------------
   IF v_cap_prod_catg = 'P'
   THEN
      --------------------------------Sn call to authorize txn------------------------------
      BEGIN
         v_currcode := prm_currcode;
         Sp_Authorize_Txn (prm_instcode,                       --prm_inst_code
                           '210',                                    --prm_msg
                           prm_rrn,                                  --prm_rrn
                           v_del_channel,               --prm_delivery_channel
                           prm_terminalid,                       --prm_term_id
                           v_txn_code,                          --prm_txn_code
                           v_txn_mode,                          --prm_txn_mode
                           prm_trandate,                       --prm_tran_date
                           prm_trantime,                       --prm_tran_time
                           prm_acctno,                           --prm_card_no
                           NULL,                               --prm_bank_code
                           prm_amount,                           --prm_txn_amt
                           NULL,                          --prm_rule_indicator
                           NULL,                              --prm_rulegrp_id
                           NULL,                                --prm_mcc_code
                           v_currcode,                         --prm_curr_code
                           NULL,                                 --prm_prod_id
                           NULL,                                 --prm_catg_id
                           NULL,                                 --prm_tip_amt
                           NULL,                          --prm_decline_ruleid
                           NULL,                             --prm_atmname_loc
                           NULL,                         --prm_mcccode_groupid
                           NULL,                        --prm_currcode_groupid
                           NULL,                       --prm_transcode_groupid
                           NULL,                                   --prm_rules
                           NULL,                            --prm_preauth_date
                           NULL,                          --prm_consodium_code
                           --NULL,
                           NULL,                            --prm_partner_code
                           NULL,                              --prm_expry_date
                           prm_stan,                                --prm_stan
                           prm_lupduser,                        --prm_ins_user
                           SYSDATE,                             --prm_ins_date
                           v_block_auth_id,                      --prm_auth_id
                           v_respcode,                         --prm_resp_code
                           v_respmsg,                           --prm_resp_msg
                           v_capture_date                   --prm_capture_date
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
   --------------------------------En call to authorize txn------------------------------
   END IF;

   --------------------------------Sn For Debit Card No need of using authorixation----------------------------

   --------------------------------Sn update the pan status------------------------------
   BEGIN
      UPDATE CMS_APPL_PAN
         SET cap_card_stat = '1'
       WHERE cap_pan_code = prm_acctno;

      IF SQL%ROWCOUNT <> 1
      THEN
         v_errmsg := 'Error while updating card status';
         RAISE exp_main_reject_record;
      END IF;
   EXCEPTION
      WHEN OTHERS
      THEN
         v_errmsg :=
               'Error while updating card status' || SUBSTR (SQLERRM, 1, 200);
         RAISE exp_main_reject_record;
   END;

   --------------------------------En update the pan status------------------------------

   --------------------------------Sn create a record in pan spprt------------------------------
   /* BEGIN
       SELECT csr_spprt_rsncode
         INTO v_resoncode
         FROM cms_spprt_reasons
        WHERE csr_spprt_key = 'BLOCK';
    EXCEPTION
       WHEN NO_DATA_FOUND
       THEN
          v_errmsg := 'Block  reason code is present in master';
          RAISE exp_main_reject_record;
       WHEN OTHERS
       THEN
          v_errmsg :=
                'Error while selecting reason code from master'
             || SUBSTR (SQLERRM, 1, 200);
          RAISE exp_main_reject_record;
    END;*/
   BEGIN
      INSERT INTO CMS_PAN_SPPRT
                  (cps_inst_code, cps_pan_code, cps_mbr_numb, cps_prod_catg,
                   cps_spprt_key, cps_spprt_rsncode, cps_func_remark,
                   cps_ins_user, cps_lupd_user, cps_cmd_mode
                  )
           VALUES (prm_instcode, prm_acctno, v_mbrnumb, v_cap_prod_catg,
                   'DBLOK', v_resoncode, prm_remrk,
                   prm_lupduser, prm_lupduser, 0
                  );
   EXCEPTION
      WHEN OTHERS
      THEN
         v_errmsg :=
               'Error while inserting records into card support master'
            || SUBSTR (SQLERRM, 1, 200);
         RAISE exp_main_reject_record;
   END;
--------------------------------En create a record in pan spprt------------------------------
EXCEPTION                                                --<< MAIN EXCEPTION>>
   WHEN exp_auth_reject_record
   THEN
      prm_auth_message := v_authmsg;
      prm_errmsg := v_authmsg;
   WHEN exp_main_reject_record
   THEN
      prm_errmsg := v_errmsg;
      prm_auth_message := v_errmsg;
   WHEN OTHERS
   THEN
      prm_errmsg := ' Error from main ' || SUBSTR (SQLERRM, 1, 200);
      prm_auth_message := ' Error from main ' || SUBSTR (SQLERRM, 1, 200);
END;                                                           --<< MAIN END>>
/


