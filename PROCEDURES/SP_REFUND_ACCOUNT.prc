CREATE OR REPLACE PROCEDURE VMSCMS.Sp_Refund_Account (
   prm_instcode       IN       NUMBER,
   prm_pancode        IN       VARCHAR2,
   prm_mbrnumb        IN       VARCHAR2,
   prm_remark         IN       VARCHAR2,
   prm_rsncode        IN       NUMBER,
   prm_rrn            IN       VARCHAR2,
   prm_terminalid     IN       VARCHAR2,
   prm_stan           IN       VARCHAR2,
   prm_trandate       IN       VARCHAR2,
   prm_trantime       IN       VARCHAR2,
   prm_acctno         IN       VARCHAR2,
   prm_filename       IN       VARCHAR2,
   prm_amount         IN       NUMBER,
   prm_refno          IN       VARCHAR2,
   prm_paymentmode    IN       VARCHAR2,
   prm_instrumentno   IN       VARCHAR2,
   prm_drawndate      IN       DATE,
   prm_currcode       IN       VARCHAR2,
   prm_workmode       IN       NUMBER,
   prm_sinkbankname   IN       VARCHAR2,
   prm_sinkbranch     IN       VARCHAR2,
   prm_sinkbankacct   IN       VARCHAR2,
   prm_sinkbankifcs   IN       VARCHAR2,
   prm_lupduser       IN       NUMBER,
   prm_auth_message   OUT      VARCHAR2,
   prm_errmsg         OUT      VARCHAR2
)
AS
/*************************************************
     * VERSION             :  1.0
     * Created Date       : 27/APR/2009
     * Created By        : Kaustubh.Dave
     * PURPOSE          : Refund Amount to customer for a perticular card number
     * Modified By:    :
     * Modified Date  :
  *************************************************/
   v_cap_prod_catg          VARCHAR2 (2);
   v_mbrnumb                VARCHAR2 (3);
   dum                      NUMBER;
   v_cap_card_stat          CHAR (1);
   v_cap_cafgen_flag        CHAR (1);
   v_cap_embos_flag         CHAR (1);
   v_cap_pin_flag           CHAR (1);
   v_errmsg                 VARCHAR2 (300)                    DEFAULT 'OK';
   v_rrn                    VARCHAR2 (200);
   v_del_channel            VARCHAR2 (2);
   v_term_id                VARCHAR2 (200);
   v_date_time              DATE;
   v_txn_code               VARCHAR2 (2);
   v_txn_type               VARCHAR2 (2);
   v_txn_mode               VARCHAR2 (2);
   v_tran_date              VARCHAR2 (200);
   v_tran_time              VARCHAR2 (200);
   v_txn_amt                NUMBER;
   v_card_no                CMS_APPL_PAN.cap_pan_code%TYPE;
   v_resp_code              VARCHAR2 (200);
   v_resp_msg               VARCHAR2 (200);
   v_capture_date           DATE;
   v_auth_id                VARCHAR2 (6);
   v_autherrmsg             VARCHAR2 (300)                    DEFAULT 'OK';
   v_acct_cnt               NUMBER;
   v_cust_code              CMS_APPL_PAN.cap_cust_code%TYPE;
   v_acctid                 CMS_APPL_PAN.cap_acct_id%TYPE;
   exp_reject_record        EXCEPTION;
   exp_auth_reject_record   EXCEPTION;
     v_hash_pan    CMS_APPL_PAN.CAP_PAN_CODE%TYPE;  
 v_encr_pan    CMS_APPL_PAN.cap_pan_code_encr%TYPE;
BEGIN                                                      --<< MAIN BEGIN  >>
   prm_errmsg := 'OK';
   prm_auth_message := 'OK';
   v_rrn := prm_rrn;
   v_term_id := prm_terminalid;
   v_tran_date := TO_CHAR (SYSDATE, 'yyyymmdd');               -- '20080723';
   v_tran_time := TO_CHAR (SYSDATE, 'HH24:MI:SS');              --'16:21:10';
   v_card_no := prm_pancode;
   v_txn_amt := prm_amount;

  
--SN CREATE HASH PAN 
BEGIN
    v_hash_pan := Gethash(prm_pancode);
EXCEPTION
WHEN OTHERS THEN
v_errmsg := 'Error while converting pan ' || SUBSTR(SQLERRM,1,200);
RAISE    exp_reject_record;
END;
--EN CREATE HASH PAN

--SN create encr pan
BEGIN
    v_encr_pan := Fn_Emaps_Main(prm_pancode);
EXCEPTION
WHEN OTHERS THEN
v_errmsg := 'Error while converting pan ' || SUBSTR(SQLERRM,1,200);
RAISE    exp_reject_record;
END;
--EN create encr pan


   IF prm_mbrnumb IS NULL
   THEN
      v_mbrnumb := '000';
   ELSE
      v_mbrnumb := prm_mbrnumb;
   END IF;

----------------------------------------------Sn check remark-------------------------------------------
   IF prm_remark IS NULL
   THEN
      v_errmsg := 'Please enter appropriate remark';
      RAISE exp_reject_record;
   END IF;

----------------------------------------------EN check remark-------------------------------------------

   ------------------------------------------------Sn check card number------------------------------------
   BEGIN
      SELECT cap_prod_catg, cap_card_stat, cap_cafgen_flag,
             cap_embos_flag, cap_pin_flag, cap_cust_code, cap_acct_id
        INTO v_cap_prod_catg, v_cap_card_stat, v_cap_cafgen_flag,
             v_cap_embos_flag, v_cap_pin_flag, v_cust_code, v_acctid
        FROM CMS_APPL_PAN
       WHERE cap_pan_code = v_hash_pan--prm_pancode
        AND cap_mbr_numb = v_mbrnumb;
   EXCEPTION
      WHEN NO_DATA_FOUND
      THEN
         v_errmsg := 'No such PAN found.';
         RAISE exp_reject_record;
      WHEN OTHERS
      THEN
         v_errmsg :=
                'Error while selecting pan code ' || SUBSTR (SQLERRM, 1, 300);
         RAISE exp_reject_record;
   END;

------------------------------------------------EN check card number--------------------------------------

   -----------------------------------Sn select transaction code,mode and del channel-------------------------
   BEGIN
      SELECT cfm_txn_code, cfm_txn_mode, cfm_delivery_channel, cfm_txn_type
        INTO v_txn_code, v_txn_mode, v_del_channel, v_txn_type
        FROM CMS_FUNC_MAST
       WHERE cfm_func_code = 'ACCREF';
   EXCEPTION
      WHEN NO_DATA_FOUND
      THEN
         v_errmsg := 'Support function Hotlist not defined in master';
         RAISE exp_reject_record;
      WHEN OTHERS
      THEN
         v_errmsg :=
               'Error while selecting support function detail '
            || SUBSTR (SQLERRM, 1, 200);
         RAISE exp_reject_record;
   END;

   --Sn find acct in master
   BEGIN
      SELECT 1
        INTO v_acct_cnt
        FROM CMS_ACCT_MAST
       WHERE cam_inst_code = prm_instcode AND cam_acct_no = prm_pancode;
   EXCEPTION
      WHEN NO_DATA_FOUND
      THEN
         v_errmsg := 'Card is not found';
         RAISE exp_reject_record;
   END;

   --En find acct in master

   -----------------------------------EN select transaction code,mode and del channel---------------------------
     ----------------------------Debit and prepaid_condition check-----------------------------------
   IF v_cap_prod_catg = 'P'
   THEN
      --------------------------------------------------Sn call to authorize procedure--------------------------
      Sp_Authorize_Txn (prm_instcode,                         -- prm_inst_code
                        '210',                                      -- prm_msg
                        v_rrn,                                      -- prm_rrn
                        v_del_channel,                  --prm_delivery_channel
                        v_term_id,                               --prm_term_id
                        v_txn_code,                             --prm_txn_code
                        v_txn_mode,                            -- prm_txn_mode
                        v_tran_date,                           --prm_tran_date
                        v_tran_time,                          -- prm_tran_time
                        v_card_no,                              -- prm_card_no
                        NULL,                                  --prm_bank_code
                        v_txn_amt,                              -- prm_txn_amt
                        NULL,                             --prm_rule_indicator
                        NULL,                                 --prm_rulegrp_id
                        NULL,                                   --prm_mcc_code
                        prm_currcode,                          --prm_curr_code
                        NULL,                                   -- prm_prod_id
                        NULL,                                   -- prm_catg_id
                        NULL,                                    --prm_tip_amt
                        NULL,                            -- prm_decline_ruleid
                        NULL,                               -- prm_atmname_loc
                        NULL,                           -- prm_mcccode_groupid
                        NULL,                          -- prm_currcode_groupid
                        NULL,                         -- prm_transcode_groupid
                        NULL,                                      --prm_rules
                        NULL,                              -- prm_preauth_date
                        NULL,                            -- prm_consodium_code
                        NULL,                               --prm_partner_code
                        NULL,                                -- prm_expry_date
                        prm_stan,                                  -- prm_stan
                        prm_lupduser,                               --Ins User
                        SYSDATE,                                    --INS Date
                        v_auth_id,                              -- prm_auth_id
                        v_resp_code,                           --prm_resp_code
                        v_resp_msg,                             --prm_resp_msg
                        v_capture_date                      --prm_capture_date
                       );

      IF v_resp_code <> '00'
      THEN
         v_autherrmsg := v_resp_msg;
         RAISE exp_auth_reject_record;
      END IF;
   END IF;

--------------------------------------------------EN call to authorize procedure--------------------------------

   --------------------------------------------------Sn update Acct stat----------------------------------------
   /*BEGIN
      UPDATE CMS_ACCT_MAST
         SET cam_stat_code = 2
       WHERE cam_acct_no = prm_pancode AND cam_inst_code = prm_instcode;

      IF SQL%ROWCOUNT != 1
      THEN
         v_errmsg :=
               'Problem in updation of status for pan ' || prm_pancode || '.';
         RAISE exp_reject_record;
      END IF;
   EXCEPTION
      WHEN exp_reject_record
      THEN
         RAISE;
      WHEN OTHERS
      THEN
         v_errmsg :=
               'Problem in updation of status for pan '
            || prm_pancode
            || ' . '
            || SUBSTR (SQLERRM, 1, 200);
         RAISE exp_reject_record;
   END;*/

--------------------------------------------------EN update Acct stat-------------------------------------------
   --------------------------------------------------Sn update card stat----------------------------------------
  /* BEGIN
      UPDATE CMS_APPL_PAN
         SET cap_card_stat = 9
       WHERE cap_pan_code = prm_pancode
         AND cap_inst_code = prm_instcode
         AND cap_mbr_numb = v_mbrnumb;

      IF SQL%ROWCOUNT != 1
      THEN
         v_errmsg :=
               'Problem in updation of status for pan ' || prm_pancode || '.';
         RAISE exp_reject_record;
      END IF;
   EXCEPTION
      WHEN exp_reject_record
      THEN
         RAISE;
      WHEN OTHERS
      THEN
         v_errmsg :=
               'Problem in updation of status for pan '
            || prm_pancode
            || ' . '
            || SUBSTR (SQLERRM, 1, 200);
         RAISE exp_reject_record;
   END;*/

--------------------------------------------------EN update card stat-------------------------------------------

   ------------------------------------------------SN insert a record in pan spprt------------------------------
   BEGIN
      INSERT INTO CMS_PAN_SPPRT
                  (cps_inst_code, cps_pan_code, cps_mbr_numb, cps_prod_catg,
                   cps_spprt_key, cps_spprt_rsncode, cps_func_remark,
                   cps_ins_user, cps_lupd_user, cps_cmd_mode,cps_pan_code_encr
                  )
           VALUES (prm_instcode, --prm_pancode
           v_hash_pan, v_mbrnumb, v_cap_prod_catg,
                   'REFUND', prm_rsncode, prm_remark,
                   prm_lupduser, prm_lupduser, prm_workmode,v_encr_pan
                  );
   EXCEPTION                                                 --excp of begin 3
      WHEN OTHERS
      THEN
         prm_errmsg :=
               'error while inserting records into pan_spprt'
            || SUBSTR (SQLERRM, 1, 300);
         RAISE exp_reject_record;
   END;

----------------------------------------------En insert a record in pan spprt------------------------------------

   ---------------------------------------------Sn update the Cust acct for sink---------------------------------
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
         AND cca_acct_id = v_acctid;
   EXCEPTION
      WHEN OTHERS
      THEN
         v_errmsg :=
               'Error while inserting records into SinkAccount'
            || SUBSTR (SQLERRM, 1, 200);
         RAISE exp_reject_record;
   END;
---------------------------En update the Cust acct for sink---------------------------------------
EXCEPTION                                                --<<MAIN EXCEPTION >>
   WHEN exp_auth_reject_record
   THEN
      prm_auth_message := v_autherrmsg;
      prm_errmsg := v_autherrmsg;
   WHEN exp_reject_record
   THEN
      prm_errmsg := v_errmsg;
      prm_auth_message := v_errmsg;
   WHEN OTHERS
   THEN
      prm_errmsg := 'Error from main ' || SUBSTR (SQLERRM, 1, 200);
END;                                                           --<< MAIN END>>
/


