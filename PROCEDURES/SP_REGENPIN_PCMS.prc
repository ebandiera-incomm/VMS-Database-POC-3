CREATE OR REPLACE PROCEDURE VMSCMS.Sp_Regenpin_Pcms (
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
     * Created Date       : 27/APR/2009
     * Created By        : Kaustubh.Dave
     * PURPOSE          : Regenerate pin for a card
     * Modified By:    :
     * Modified Date  :
  *************************************************/
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
 v_hash_pan    CMS_APPL_PAN.CAP_PAN_CODE%TYPE;  
     v_encr_pan    CMS_APPL_PAN.cap_pan_code_encr%TYPE;
BEGIN                                                        --<< MAIN BEGIN>>

   prm_errmsg := 'OK';
   prm_auth_message := 'OK';

   IF prm_remrk IS NULL
   THEN
      v_errmsg := 'Please enter appropriate remrk';
      RAISE exp_main_reject_record;
   END IF;

--SN CREATE HASH PAN 
BEGIN
    v_hash_pan := Gethash(prm_acctno);
EXCEPTION
WHEN OTHERS THEN
v_errmsg := 'Error while converting pan ' || SUBSTR(SQLERRM,1,200);
RAISE    exp_main_reject_record;
END;
--EN CREATE HASH PAN
  


--SN create encr pan
BEGIN
    v_encr_pan := Fn_Emaps_Main(prm_acctno);
EXCEPTION
WHEN OTHERS THEN
v_errmsg := 'Error while converting pan ' || SUBSTR(SQLERRM,1,200);
RAISE    exp_main_reject_record;
END;
--EN create encr pan
  

   -----------------------------------Sn select Pan detail---------------------------------
   BEGIN
      SELECT cap_card_stat, cap_prod_catg, cap_cafgen_flag,
             cap_appl_code, cap_mbr_numb, cap_pin_off
        INTO v_cap_card_stat, v_cap_prod_catg, v_cap_cafgen_flag,
             v_appl_code, v_mbrnumb, v_old_pin_off
        FROM CMS_APPL_PAN
       WHERE cap_pan_code = v_hash_pan--prm_acctno
         AND cap_issue_flag = 'Y'
         AND cap_pin_flag = 'N';
/*
      IF v_cap_cafgen_flag = 'N'
      THEN
         v_errmsg := 'CAF has to be generated atleast once for this pan ';
         RAISE exp_main_reject_record;
      END IF;
*/
      IF v_cap_card_stat <> '1'
      THEN
         v_errmsg := 'Not a valid card status for Repin ';
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
         v_errmsg :=
               'Error while selecting card number from appl pan master '
            || SUBSTR (SQLERRM, 1, 200);
         RAISE exp_main_reject_record;
   END;

   -----------------------------------En select Pan detail---------------------------------

   -----------------------------------Sn select transaction code,mode and del channel---------------------------------
   BEGIN
      SELECT cfm_txn_code, cfm_txn_mode, cfm_delivery_channel, cfm_txn_type
        INTO v_txn_code, v_txn_mode, v_del_channel, v_txn_type
        FROM CMS_FUNC_MAST
       WHERE cfm_func_code = 'REPIN';
   EXCEPTION
      WHEN NO_DATA_FOUND
      THEN
         v_errmsg := 'Support function repin not defined in master';
         RAISE exp_main_reject_record;
      WHEN OTHERS
      THEN
         v_errmsg :=
               'Error while selecting support function detail '
            || SUBSTR (SQLERRM, 1, 200);
         RAISE exp_main_reject_record;
   END;

   -----------------------------------En select transaction code,mode and del channel---------------------------------
   -----------------------------------Sn For Debit Card No Need Of authorization------------------------------
   IF v_cap_prod_catg =  'P' THEN
   -----------------------------------Sn call to authorize txn---------------------------------
   BEGIN
      v_currcode := prm_currcode;
      Sp_Authorize_Txn (prm_instcode,
                        '210',
                        prm_rrn,
                        v_del_channel,
                        prm_terminalid,
                        v_txn_code,
                        v_txn_mode,
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
                        prm_stan,
                        prm_lupduser,
                        SYSDATE,
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
   END IF;
    -----------------------------------En For Debit Card No Need Of authorization------------------------------
   -----------------------------------Sn update the pan Pin offset---------------------------------
   BEGIN
      UPDATE CMS_APPL_PAN
         SET cap_pin_flag = 'Y',
             cap_lupd_date = SYSDATE
       WHERE cap_pan_code = v_hash_pan--prm_acctno
        AND cap_mbr_numb = v_mbrnumb;

      IF SQL%ROWCOUNT <> 1
      THEN
         v_errmsg := 'Error while updating Pin flag';
         RAISE exp_main_reject_record;
      END IF;
   EXCEPTION
      WHEN OTHERS
      THEN
         v_errmsg :=
                 'Error while updating Pin flag ' || SUBSTR (SQLERRM, 1, 200);
         RAISE exp_main_reject_record;
   END;

    ------------------------------------Sn update the pan Pin offset ----------------------------------

   ------------------------------------Sn create a record in pan spprt ----------------------------------
   /*BEGIN
      SELECT csr_spprt_rsncode
        INTO v_resoncode
        FROM CMS_SPPRT_REASONS
       WHERE csr_spprt_key = 'REPIN' AND ROWNUM < 2;
   EXCEPTION
      WHEN NO_DATA_FOUND
      THEN
         v_errmsg := 'Repin reason code is not present in support master';
         RAISE exp_main_reject_record;
      WHEN OTHERS
      THEN
         v_errmsg :=
               'Error while selecting reason code from support master'
            || SUBSTR (SQLERRM, 1, 200);
         RAISE exp_main_reject_record;
   END;*/

   BEGIN
      INSERT INTO CMS_PAN_SPPRT
                  (cps_inst_code, cps_pan_code, cps_mbr_numb, cps_prod_catg,
                   cps_spprt_key, cps_spprt_rsncode, cps_func_remark,
                   cps_ins_user, cps_lupd_user, cps_cmd_mode,cps_pan_code_encr
                  )
           VALUES (prm_instcode, v_hash_pan--prm_acctno
           , v_mbrnumb, v_cap_prod_catg,
                   'REPIN', prm_resoncode, prm_remrk,
                   prm_lupduser, prm_lupduser, 0,v_encr_pan
                  );
   EXCEPTION
      WHEN OTHERS
      THEN
         v_errmsg :=
               'Error while inserting records into card support master'
            || SUBSTR (SQLERRM, 1, 200);
         RAISE exp_main_reject_record;
   END;

    ------------------------------------En create a record in pan spprt ----------------------------------

    ------------------------------------SN Insert Successful Records in CMS_REPIN_HIST ----------------------------------
   BEGIN
      INSERT INTO CMS_REGEN_PIN_HIST
                  (crh_pan_code, crh_mbr_numb, crh_pin_off, crh_auth_id,
                   crh_rrn, crh_stan, crh_business_date, crh_business_time,
                   crh_ins_user, crh_ins_date,crh_pan_code_encr
                  )
           VALUES (--prm_acctno
           v_hash_pan , v_mbrnumb, v_old_pin_off, v_repin_auth_id,
                   prm_rrn, prm_stan, prm_trandate, prm_trantime,
                   prm_lupduser, SYSDATE,v_encr_pan
                  );
   EXCEPTION
      WHEN OTHERS
      THEN
         v_errmsg :=
               'Error while inserting records into Repin history '
            || SUBSTR (SQLERRM, 1, 200);
         RAISE exp_main_reject_record;
   END;
  -----------------------------------EN Insert Successful Records in CMS_REPIN_HIST ----------------------------------
---------------------------------------------------------------------
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


