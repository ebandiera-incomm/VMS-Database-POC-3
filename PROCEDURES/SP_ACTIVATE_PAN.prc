CREATE OR REPLACE PROCEDURE VMSCMS.sp_ACTIVATE_pan (
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
   prm_lupduser       IN       NUMBER,
   prm_workmode       IN       NUMBER,
   prm_auth_message   OUT      VARCHAR2,
   prm_errmsg         OUT      VARCHAR2
)
AS
/*************************************************
     * VERSION             :  1.0
     * Created Date       : 29/APR/2010
     * Created By        : SAGAR MORE
     * PURPOSE          : ACTIVATE card for a perticular card number
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
   --v_record_exist      CHAR (1)                         := 'Y';
   --v_caffilegen_flag   CHAR (1)                         := 'N';
   --v_issuestatus       VARCHAR2 (2);
   --v_pinmailer         VARCHAR2 (1);
   --v_cardcarrier       VARCHAR2 (1);
   --v_pinoffset         VARCHAR2 (16);
   --v_rec_type          VARCHAR2 (1);
   v_errmsg                 VARCHAR2 (300)                   DEFAULT 'OK';
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
   v_card_no                cms_appl_pan.cap_pan_code%TYPE;
   v_resp_code              VARCHAR2 (200);
   v_resp_msg               VARCHAR2 (200);
   v_capture_date           DATE;
   v_auth_id                VARCHAR2 (6);
   v_autherrmsg             VARCHAR2 (300)                   DEFAULT 'OK';
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
             cap_embos_flag, cap_pin_flag
        INTO v_cap_prod_catg, v_cap_card_stat, v_cap_cafgen_flag,
             v_cap_embos_flag, v_cap_pin_flag
        FROM cms_appl_pan
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
--   IF v_cap_cafgen_flag = 'N'
   /*IF (v_cap_embos_flag = 'Y' OR v_cap_pin_flag = 'Y')
   THEN
--      v_errmsg := 'CAF has to be generated atleast once for this pan';
      v_errmsg := 'Card Not Eligible to hotlist'; -- Changed for PCMS as CAF is not there for PCMS ...
      RAISE exp_reject_record;
   ELSE
      IF prm_workmode = 0 AND v_cap_card_stat != 1
      THEN
         v_errmsg := 'Card Not Eligible to hotlist';
         RAISE exp_reject_record;
      END IF;
   END IF; */

   -----------------------------------Sn select transaction code,mode and del channel-------------------------
   BEGIN
      SELECT cfm_txn_code, cfm_txn_mode, cfm_delivery_channel, cfm_txn_type
        INTO v_txn_code, v_txn_mode, v_del_channel, v_txn_type
        FROM cms_func_mast
       WHERE cfm_func_code = 'ACTVTCARD';
   EXCEPTION
      WHEN NO_DATA_FOUND
      THEN
         v_errmsg := 'Support function Activate card not defined in master';
         RAISE exp_reject_record;
      WHEN OTHERS
      THEN
         v_errmsg :=
               'Error while selecting support function detail '
            || SUBSTR (SQLERRM, 1, 200);
         RAISE exp_reject_record;
   END;

-----------------------------------EN select transaction code,mode and del channel---------------------------
     ----------------------------Debit and prepaid_condition check-----------------------------------
 IF v_cap_prod_catg = 'P' THEN               
   --------------------------------------------------Sn call to authorize procedure--------------------------
   sp_authorize_txn (prm_instcode,                            -- prm_inst_code
                     '210',                                         -- prm_msg
                     v_rrn,                                         -- prm_rrn
                     v_del_channel,                     --prm_delivery_channel
                     v_term_id,                                  --prm_term_id
                     v_txn_code,                                --prm_txn_code
                     v_txn_mode,                               -- prm_txn_mode
                     v_tran_date,                              --prm_tran_date
                     v_tran_time,                             -- prm_tran_time
                     v_card_no,                                 -- prm_card_no
                     NULL,                                     --prm_bank_code
                     v_txn_amt,                                 -- prm_txn_amt
                     NULL,                                --prm_rule_indicator
                     NULL,                                    --prm_rulegrp_id
                     NULL,                                      --prm_mcc_code
                     prm_currcode,                             --prm_curr_code
                     NULL,                                      -- prm_prod_id
                     NULL,                                      -- prm_catg_id
                     NULL,                                       --prm_tip_amt
                     NULL,                               -- prm_decline_ruleid
                     NULL,                                  -- prm_atmname_loc
                     NULL,                              -- prm_mcccode_groupid
                     NULL,                             -- prm_currcode_groupid
                     NULL,                            -- prm_transcode_groupid
                     NULL,                                         --prm_rules
                     NULL,                                 -- prm_preauth_date
                     NULL,                               -- prm_consodium_code
                     NULL,                                  --prm_partner_code
                     NULL,                                   -- prm_expry_date
                     prm_stan,                                     -- prm_stan
                     prm_lupduser,                                  --Ins User
                     SYSDATE,                                       --INS Date
                     v_auth_id,                                 -- prm_auth_id
                     v_resp_code,                              --prm_resp_code
                     v_resp_msg,                                --prm_resp_msg
                     v_capture_date                         --prm_capture_date
                    );

   IF v_resp_code <> '00'
   THEN
      v_autherrmsg := v_resp_msg;
      RAISE exp_auth_reject_record;
   END IF;
END IF;
--------------------------------------------------EN call to authorize procedure--------------------------------

   --------------------------------------------------Sn update card stat----------------------------------------
   BEGIN
      UPDATE cms_appl_pan
         SET cap_card_stat = 1
       WHERE cap_pan_code = v_hash_pan--prm_pancode
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
   END;

--------------------------------------------------EN update card stat-------------------------------------------

   ------------------------------------------------SN insert a record in pan spprt------------------------------
   /* BEGIN
          SELECT csr_spprt_rsncode
            INTO v_resoncode
            FROM cms_spprt_reasons
           WHERE csr_spprt_key = 'DHTLST';
       EXCEPTION
          WHEN NO_DATA_FOUND
          THEN
             v_errmsg := 'reissue  reason code is present in master';
             RAISE exp_reject_record;
          WHEN OTHERS
          THEN
             v_errmsg :=
                   'Error while selecting reason code from master'
                || SUBSTR (SQLERRM, 1, 200);
             RAISE exp_reject_record;
       END;*/
   BEGIN
      INSERT INTO cms_pan_spprt
                  (cps_inst_code, cps_pan_code, cps_mbr_numb, cps_prod_catg,
                   cps_spprt_key, cps_spprt_rsncode, cps_func_remark,
                   cps_ins_user, cps_lupd_user, cps_cmd_mode,cps_pan_code_encr
                  )
           VALUES (prm_instcode, --prm_pancode
           v_hash_pan, v_mbrnumb, v_cap_prod_catg,
                   'ACTVTCARD', prm_rsncode, prm_remark,
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

-------------------------------------------------Sn create a record in CAF--------------------------------------
/*   BEGIN
--------------------------------------------------Sn record from cafinfo------------------------------------------
      BEGIN
         SELECT   cci_rec_typ, cci_file_gen, cci_seg12_issue_stat,
                  cci_seg12_pin_mailer, cci_seg12_card_carrier, cci_pin_ofst
             INTO v_rec_type, v_caffilegen_flag, v_issuestatus,
                  v_pinmailer, v_cardcarrier, v_pinoffset
             FROM cms_caf_info
            WHERE cci_inst_code = prm_instcode
              AND cci_pan_code = RPAD (prm_pancode, 19, ' ')
              AND cci_mbr_numb = v_mbrnumb
         GROUP BY cci_rec_typ,
                  cci_file_gen,
                  cci_seg12_issue_stat,
                  cci_seg12_pin_mailer,
                  cci_seg12_card_carrier,
                  cci_pin_ofst;

         DELETE FROM cms_caf_info
               WHERE cci_inst_code = prm_instcode
                 AND cci_pan_code = RPAD (prm_pancode, 19, ' ')
                 AND cci_mbr_numb = v_mbrnumb;
      EXCEPTION
         WHEN NO_DATA_FOUND
         THEN
            v_record_exist := 'N';
      END;

--------------------------------------------------En record from cafinfo-----------------------------------------
      IF v_rec_type = 'A'
      THEN
         v_issuestatus := '00';                   -- no pinmailer no embossa.
         v_pinoffset := RPAD ('Z', 16, 'Z');           -- keep original pin .
      END IF;

      IF (prm_workmode = 1 AND v_record_exist = 'Y')
      THEN
         UPDATE cms_caf_info
            SET cci_seg12_issue_stat = v_issuestatus,
                cci_seg12_pin_mailer = v_pinmailer,
                cci_seg12_card_carrier = v_cardcarrier,
                cci_pin_ofst = v_pinoffset                  -- rahul 10 Mar 05
          WHERE cci_inst_code = 1
            AND cci_pan_code = RPAD (prm_pancode, 19, ' ')
            AND cci_mbr_numb = '000';
      END IF;
   EXCEPTION                                                          --Excp 5
      WHEN exp_reject_record
      THEN
         RAISE;
      WHEN OTHERS
      THEN
         prm_errmsg := 'Error from caf generation ' || SQLERRM;
         RAISE exp_reject_record;
   END;*/
-------------------------------------------En create a record in CAF-----------------------------------------
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


