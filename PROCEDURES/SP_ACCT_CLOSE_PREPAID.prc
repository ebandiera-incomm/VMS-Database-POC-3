CREATE OR REPLACE PROCEDURE VMSCMS.Sp_Acct_Close_prepaid (
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
   prm_sinkbankname   IN       VARCHAR2,
   prm_sinkbranch     IN       VARCHAR2,
   prm_sinkbankacct   IN       VARCHAR2,
   prm_sinkbankifcs   IN       VARCHAR2,
   prm_acct_id          IN       VARCHAR2,
   prm_lupduser       IN       NUMBER,
   prm_auth_message   OUT      VARCHAR2,
   prm_errmsg         OUT      VARCHAR2
)
/*************************************************
     * VERSION             :  1.0
     * Created Date       : 27/APR/2009
     * Created By        : Kaustubh.Dave
     * PURPOSE          : Close account of a customer
     * Modified By:    :
     * Modified Date  :
  *************************************************/
AS
   exp_auth_reject_record   EXCEPTION;
   exp_main_reject_record   EXCEPTION;
   v_errmsg                 VARCHAR2 (300)                            := 'OK';
   v_mbrnumb                CMS_APPL_PAN.cap_mbr_numb%TYPE;
   v_crd_val                CMS_INST_PARAM.cip_param_value%TYPE;
   v_exp_date               CMS_APPL_PAN.cap_expry_date%TYPE;
   v_cap_prod_catg          CMS_APPL_PAN.cap_prod_catg%TYPE;
   v_cap_card_stat          CMS_APPL_PAN.cap_card_stat%TYPE;
   v_cap_cafgen_flag        CMS_APPL_PAN.cap_cafgen_flag%TYPE;
   v_cap_appl_code          CMS_APPL_PAN.cap_appl_code%TYPE;
   v_date                   CMS_APPL_PAN.cap_expry_date%TYPE;
   v_appl_code              CMS_APPL_MAST.cam_appl_code%TYPE;
   v_resoncode              CMS_SPPRT_REASONS.csr_spprt_rsncode%TYPE;
   v_txn_code               CMS_FUNC_MAST.cfm_txn_code%TYPE;
   v_txn_mode               CMS_FUNC_MAST.cfm_txn_mode%TYPE;
   v_del_channel            CMS_FUNC_MAST.cfm_delivery_channel%TYPE;
   v_txn_type               CMS_FUNC_MAST.cfm_txn_type%TYPE;
   v_cust_code              CMS_APPL_PAN.cap_cust_code%TYPE;
   v_acct_id                CMS_APPL_PAN.cap_acct_id%TYPE;
   v_respcode               VARCHAR2 (5);
   v_currcode               VARCHAR2 (3);
   v_renew_auth_id          TRANSACTIONLOG.auth_id%TYPE;
   v_respmsg                VARCHAR2 (500);
   v_authmsg                VARCHAR2 (500);
   v_capture_date           DATE;

 v_hash_pan    CMS_APPL_PAN.CAP_PAN_CODE%TYPE;  
 v_encr_pan    CMS_APPL_PAN.cap_pan_code_encr%TYPE;

    
BEGIN                                                        --<< MAIN BEGIN>>
---------------------------------------------------------------------
   prm_errmsg := 'OK';
   prm_auth_message := 'OK';

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

   IF prm_remrk IS NULL
   THEN
      v_errmsg := 'Please enter appropriate remrk';
      RAISE exp_main_reject_record;
   END IF;

   --Sn select Pan detail
   BEGIN
      SELECT cap_card_stat, cap_prod_catg, cap_cafgen_flag,
             cap_appl_code, cap_mbr_numb, cap_expry_date, cap_cust_code,
             cap_acct_id 
        INTO v_cap_card_stat, v_cap_prod_catg, v_cap_cafgen_flag,
             v_appl_code, v_mbrnumb, v_exp_date, v_cust_code,
             v_acct_id
        FROM CMS_APPL_PAN
       WHERE cap_pan_code =v_hash_pan -- prm_acctno 
       AND cap_inst_code = prm_instcode;

/*
      IF v_cap_cafgen_flag = 'N'
      THEN
         v_errmsg := 'CAF has to be generated atleast once for this pan ';
         RAISE exp_main_reject_record;
      END IF;
*/
      IF v_cap_card_stat <> '1'
      THEN
         v_errmsg := 'Not a valid card status for Account Close ';
         RAISE exp_main_reject_record;
      END IF;
/*
      IF TRUNC (v_exp_date) > TRUNC (SYSDATE)
      THEN
         v_errmsg := 'Card is not expired for  Account Close';
         RAISE exp_main_reject_record;
      END IF;
*/
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
               'Error while selecting card number '
            || prm_acctno
            || ' '
            || SUBSTR (SQLERRM, 1, 200);
         RAISE exp_main_reject_record;
   END;

   --En select Pan detail
   --Sn select transaction code,mode and del channel
   BEGIN
      SELECT cfm_txn_code, cfm_txn_mode, cfm_delivery_channel, cfm_txn_type
        INTO v_txn_code, v_txn_mode, v_del_channel, v_txn_type
        FROM CMS_FUNC_MAST
       WHERE cfm_func_code = 'ACCCLOSE' AND cfm_inst_code = prm_instcode;
   EXCEPTION
      WHEN NO_DATA_FOUND
      THEN
         v_errmsg := 'Support function ACCCLOSE not defined in master';
         RAISE exp_main_reject_record;
      WHEN OTHERS
      THEN
         v_errmsg :=
               'Error while selecting support function detail '
            || SUBSTR (SQLERRM, 1, 200);
         RAISE exp_main_reject_record;
   END;

   --En select transaction code,mode and del channel
   --Sn call to authorize txn
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
                        prm_lupduser,                               --Ins User
                        SYSDATE,                                    --INS Date
                        v_renew_auth_id,
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

    --Sn get the Crad validity from inst param
   /* BEGIN
       SELECT cip_param_value
         INTO v_crd_val
         FROM CMS_INST_PARAM
        WHERE cip_param_key = 'ACCCLOSE';
       v_date := ADD_MONTHS (v_exp_date, v_crd_val);
    EXCEPTION
       WHEN NO_DATA_FOUND
       THEN
          v_errmsg :=
                'Card validity value not defined in master '
             || SUBSTR (SQLERRM, 1, 200);
          RAISE exp_main_reject_record;
       WHEN OTHERS
       THEN
          v_errmsg :=
                'Error while selecting card validity from master '
             || SUBSTR (SQLERRM, 1, 200);
          RAISE exp_main_reject_record;
    END;
    --En get the Crad validity from inst param
    --Sn update the pan EXPIRY
    BEGIN
       UPDATE CMS_APPL_PAN
          SET cap_expry_date = v_date,
              cap_lupd_date = SYSDATE
        WHERE cap_pan_code = prm_acctno;
       IF SQL%ROWCOUNT <> 1
       THEN
          v_errmsg := 'Error while updating expiry date';
          RAISE exp_main_reject_record;
       END IF;
    EXCEPTION
       WHEN OTHERS
       THEN
          v_errmsg :=
               'Error while updating expiry date ' || SUBSTR (SQLERRM, 1, 200);
          RAISE exp_main_reject_record;
    END;
    */
    --Sn update the pan EXPIRY
   --Sn update the pan EXPIRY
   BEGIN
      UPDATE CMS_APPL_PAN
         SET cap_card_stat = 9,
             cap_lupd_date = SYSDATE
       WHERE cap_pan_code =v_hash_pan -- prm_acctno
         AND cap_inst_code = prm_instcode
         AND cap_mbr_numb = v_mbrnumb;

      IF SQL%ROWCOUNT <> 1
      THEN
         v_errmsg := 'Error while updating expiry date';
         RAISE exp_main_reject_record;
      END IF;
   EXCEPTION
      WHEN OTHERS
      THEN
         v_errmsg :=
              'Error while updating expiry date ' || SUBSTR (SQLERRM, 1, 200);
         RAISE exp_main_reject_record;
   END;
   --Sn Acct Close in acct master change status to 2.
   BEGIN
            UPDATE CMS_ACCT_MAST
               SET cam_stat_code = 2,
                   cam_lupd_user = prm_lupduser
             WHERE cam_inst_code = prm_instcode AND cam_acct_id = prm_acct_id;

            IF SQL%ROWCOUNT != 1
            THEN
               v_errmsg := 'Problem in updation of status in acct mast';
               RAISE exp_main_reject_record;
            END IF;
         EXCEPTION
            WHEN exp_main_reject_record
            THEN
               RAISE;
            WHEN OTHERS
            THEN
               v_errmsg :=
                     'Problem in updation of status in acct mast. '
                  || SUBSTR (SQLERRM, 1, 200);
               RAISE exp_main_reject_record;
         END;    
   --En Acct Close in acct master change status to 2.
   
   --Sn update the pan EXPIRY
   BEGIN
      INSERT INTO CMS_PAN_SPPRT
                  (cps_inst_code, cps_pan_code, cps_mbr_numb, cps_prod_catg,
                   cps_spprt_key, cps_spprt_rsncode, cps_func_remark,
                   cps_ins_user, cps_lupd_user, cps_cmd_mode,cps_pan_code_encr 
                  )
           VALUES (prm_instcode, --prm_acctno
           v_hash_pan, v_mbrnumb, v_cap_prod_catg,
                   'ACCCLOSE', prm_resoncode, prm_remrk,
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

--En create a record in pan spprt

   --Sn update the Cust acct for sink
   BEGIN
      UPDATE CMS_CUST_ACCT
         SET cca_fundtrans_amt = prm_amount,
             cca_fundtrans_acctno = prm_sinkbankacct,
             cca_fundtrans_bank = prm_sinkbankname,
             cca_fundtrans_branch = prm_sinkbranch,
             cca_fundtrans_ifcs = prm_sinkbankifcs,
             cca_fundtrans_filegen_flag = 'N'
       WHERE cca_inst_code = prm_instcode
         AND cca_cust_code = v_cust_code
         AND cca_acct_id = v_acct_id;
   EXCEPTION
      WHEN OTHERS
      THEN
         v_errmsg :=
               'Error while inserting records into SinkAccount'
            || SUBSTR (SQLERRM, 1, 200);
         RAISE exp_main_reject_record;
   END;
   --En update the Cust acct for sink
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


