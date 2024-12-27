CREATE OR REPLACE PROCEDURE VMSCMS.Sp_Reissue_Pan_prepaid (
   prm_instcode         IN       NUMBER,
   prm_pancode          IN       VARCHAR2,
   prm_mbrnumb          IN       VARCHAR2,
   prm_remark           IN       VARCHAR2,
   prm_resoncode        IN       NUMBER,
   prm_rrn              IN       VARCHAR2,
   prm_terminalid       IN       VARCHAR2,
   prm_stan             IN       VARCHAR2,
   prm_trandate         IN       VARCHAR2,
   prm_trantime         IN       VARCHAR2,
   prm_acctno           IN       VARCHAR2,
   prm_filename         IN       VARCHAR2,
   prm_amount           IN       NUMBER,
   prm_refno            IN       VARCHAR2,
   prm_paymentmode      IN       VARCHAR2,
   prm_instrumentno     IN       VARCHAR2,
   prm_drawndate        IN       DATE,
   prm_currcode         IN       VARCHAR2,
   prm_lupduser         IN       NUMBER,
   prm_auth_message     OUT      VARCHAR2,
   prm_newpan           OUT      VARCHAR2,
   prm_processmessage   OUT      VARCHAR2,
   prm_errmsg           OUT      VARCHAR2
) AS
/*************************************************
     * VERSION             :  1.0
     * Created Date       : 25/APR/2009
     * Created By        : Kaustubh.Dave
     * PURPOSE          : Reissue new pan number,
                      first block old pan and start generating new pan
     * Modified By:    :
     * Modified Date  :
   ***********************************************/
   v_cap_prod_catg         VARCHAR2 (2);
   v_mbrnumb               VARCHAR2 (3);
   dum                     NUMBER (1);
   v_cap_cafgen_flag       CHAR (1);
   v_cap_card_stat         CHAR (1);
   software_pin_gen        CHAR (1);
   v_rrn                   VARCHAR2 (200);
   v_delivery_channel      VARCHAR2 (2);
   v_term_id               VARCHAR2 (200);
   v_txn_code              VARCHAR2 (2);
   v_txn_type              VARCHAR2 (2);
   v_txn_mode              VARCHAR2 (2);
   v_tran_date             VARCHAR2 (200);
   v_tran_time             VARCHAR2 (200);
   v_txn_amt               NUMBER;
   v_card_no               CMS_APPL_PAN.cap_pan_code%TYPE;
   v_resp_code             VARCHAR2 (200);
   v_resp_msg              VARCHAR2 (200);
   v_errmsg                VARCHAR2 (300);
   v_applprocess_msg       VARCHAR2 (300);
   v_capture_date          DATE;
   v_auth_id               VARCHAR2 (6);
   v_resoncode             CMS_SPPRT_REASONS.csr_spprt_rsncode%TYPE;
   v_del_channel           CMS_FUNC_MAST.cfm_delivery_channel%TYPE;
   v_autherrmsg            VARCHAR2 (300);
   v_merc_code               CMS_MERCHANT_CARDS.PCC_MERC_CODE%TYPE;
   v_cust_code                CMS_MERCHANT_CARDS.PCC_CUST_CODE%TYPE; 
   v_corp_code                cms_corporate_cards.PCC_CORP_CODE%TYPE;
   
       v_hash_pan    CMS_APPL_PAN.CAP_PAN_CODE%TYPE;  
 v_encr_pan    CMS_APPL_PAN.cap_pan_code_encr%TYPE;
  v_hash_new_pan    CMS_APPL_PAN.CAP_PAN_CODE%TYPE;  
 v_encr_new_pan    CMS_APPL_PAN.cap_pan_code_encr%TYPE;
   CURSOR c1 IS
-- this cursor finds the addon cards which were attached to the previousPAN so that they can be pointed towards the PAN being reissued
      SELECT cap_pan_code, cap_mbr_numb
        FROM CMS_APPL_PAN
       WHERE cap_addon_link = v_hash_pan --prm_pancode
        AND cap_mbr_numb = prm_mbrnumb;
   --AND cap_addon_stat = 'A';
   exp_reject_record       EXCEPTION;
   exp_authreject_record   EXCEPTION;
BEGIN                                                       --<< MAIN BEGIN >>
   prm_errmsg := 'OK';
   prm_auth_message := 'OK';
   v_autherrmsg := 'OK';
    -- v_errmsg := 'OK';
   prm_processmessage := 'OK';
   -- v_applprocess_msg := 'OK';
   v_rrn := prm_rrn;
   v_term_id := prm_terminalid;
   v_tran_date := TO_CHAR (SYSDATE, 'yyyymmdd');               -- '20080723';
   v_tran_time := TO_CHAR (SYSDATE, 'HH24:MI:SS');              --'16:21:10';
   v_card_no := prm_pancode;
   v_txn_amt := prm_amount;
   v_resoncode := prm_resoncode;
   IF prm_mbrnumb IS NULL THEN
      v_mbrnumb := '000';
   ELSE
      v_mbrnumb := prm_mbrnumb;
   END IF;

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
  


   ---------------------------------Sn old pan details-------------------------------
   BEGIN
      SELECT cap_prod_catg, cap_cafgen_flag, cap_card_stat
        INTO v_cap_prod_catg, v_cap_cafgen_flag, v_cap_card_stat
        FROM CMS_APPL_PAN
       WHERE cap_pan_code = v_hash_pan --prm_pancode
        AND cap_mbr_numb = v_mbrnumb;
   EXCEPTION
      WHEN NO_DATA_FOUND THEN
         v_errmsg := 'No such PAN found.';
         RAISE exp_reject_record;
      WHEN OTHERS THEN
         v_errmsg :=
               'Error while selecting card details -- '
            || SUBSTR (SQLERRM, 1, 300);
         RAISE exp_reject_record;
   END;
   ---------------------------------En old pan details-------------------------------
   -----------------------------------Sn select transaction code,mode and del channel---------------------------------
   BEGIN
      SELECT cfm_txn_code, cfm_txn_mode, cfm_delivery_channel, cfm_txn_type
        INTO v_txn_code, v_txn_mode, v_del_channel, v_txn_type
        FROM CMS_FUNC_MAST
       WHERE cfm_func_code = 'REISSUE';
   EXCEPTION
      WHEN NO_DATA_FOUND THEN
         v_errmsg := 'Support function Reissue not defined in master';
         RAISE exp_reject_record;
      WHEN OTHERS THEN
         v_errmsg :=
               'Error while selecting support function detail '
            || SUBSTR (SQLERRM, 1, 200);
         RAISE exp_reject_record;
   END;
   -----------------------------------En select transaction code,mode and del channel---------------------------------
   DBMS_OUTPUT.PUT_LINE ('v_auth_id' || v_del_channel);
   DBMS_OUTPUT.PUT_LINE ('V txn code' || v_txn_code);
   
   --------------------------------Sn For Debit Card No Authorization Required-----------------------------------------
   
   IF v_cap_prod_catg = 'P' THEN
   ---------------------------------Sn call to authorization-------------------------------
   Sp_Authorize_Txn (prm_instcode,                            -- prm_inst_code
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
                     prm_lupduser,
                     SYSDATE,
                     v_auth_id,                                 -- prm_auth_id
                     v_resp_code,                              --prm_resp_code
                     v_resp_msg,                                --prm_resp_msg
                     v_capture_date                         --prm_capture_date
                    );
   DBMS_OUTPUT.PUT_LINE ('v_auth_id' || v_auth_id);
   DBMS_OUTPUT.PUT_LINE (' v_resp_code' || v_resp_code);
   DBMS_OUTPUT.PUT_LINE ('v_resp_msg12' || v_resp_msg);
   IF v_resp_code <> '00' THEN
      DBMS_OUTPUT.PUT_LINE ('v_resp_msg' || v_resp_msg);
      v_autherrmsg := v_resp_msg;
      RAISE exp_authreject_record;
   END IF;
  END IF;
   --------------------------------En For Debit Card No Authorization Required-----------------------------------------
   ---------------------------------En call to authorization-------------------------------
/*   IF v_cap_cafgen_flag = 'N' THEN                                 --cafgen if
      v_errmsg := 'CAF has to be generated atleast once for this pan';
      RAISE exp_reject_record;
   ELSE
   */
      ---------------------------------Sn update the card status-------------------------------
      BEGIN                                                  --begin 5 starts
         UPDATE CMS_APPL_PAN
            SET cap_card_stat = 9,
                cap_lupd_user = prm_lupduser
          WHERE cap_inst_code = prm_instcode
            AND cap_pan_code = v_hash_pan --prm_pancode
            AND cap_mbr_numb = v_mbrnumb;
         IF SQL%ROWCOUNT != 1 THEN
            v_errmsg :=
               'Problem in updation of status for pan ' || prm_pancode || '.';
            RAISE exp_reject_record;
         END IF;
      EXCEPTION                                              --excp of begin 4
         WHEN OTHERS THEN
            v_errmsg :=
                   'Error while updating pan -- ' || SUBSTR (SQLERRM, 1, 200);
            RAISE exp_reject_record;
      END;
      ---------------------------------En update the card status-------------------------------
      ----------------------------------Sn generate a new pan-------------------------------
      BEGIN
         Sp_Gen_Reissuepan_Pcms (prm_instcode,
                                 prm_pancode,
                                 v_mbrnumb,
                                 prm_lupduser,
                                 prm_newpan,
                                 v_applprocess_msg,
                                 v_errmsg
                                );
         DBMS_OUTPUT.PUT_LINE ('New pan' || prm_newpan);
         DBMS_OUTPUT.PUT_LINE ('Appl error msg' || v_applprocess_msg);
         DBMS_OUTPUT.PUT_LINE ('error msg' || v_errmsg);
         --prm_processmessage := v_applprocess_msg;
         IF v_errmsg != 'OK' OR v_applprocess_msg != 'OK' THEN
         
             v_errmsg := v_applprocess_msg;
            
           /*  prm_processmessage := v_applprocess_msg;
             prm_errmsg := v_errmsg;*/
            RAISE exp_reject_record; 
         END IF;
      EXCEPTION                                              --excp of begin 2
         WHEN exp_reject_record THEN
              /* v_applprocess_msg := v_applprocess_msg;
            v_errmsg := v_errmsg;*/
            RAISE;
         WHEN OTHERS THEN
            prm_errmsg := 'Excp 2 -- ' || SQLERRM;
            RAISE exp_reject_record;
      END;
      ---------------------------------En generate a new pan-------------------------------
      ---------------------------------Sn create a record in PAN_SPPRT-------------------------------
      /* BEGIN
          SELECT csr_spprt_rsncode
            INTO v_resoncode
            FROM cms_spprt_reasons
           WHERE csr_spprt_key = 'REISU';
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

--SN CREATE HASH PAN 
BEGIN
    v_hash_new_pan := Gethash(prm_newpan);
EXCEPTION
WHEN OTHERS THEN
prm_errmsg := 'Error while converting pan ' || SUBSTR(SQLERRM,1,200);
RAISE    exp_reject_record;
END;
--EN CREATE HASH PAN


--SN create encr pan
BEGIN
    v_encr_new_pan := Fn_Emaps_Main(prm_newpan);
EXCEPTION
WHEN OTHERS THEN
prm_errmsg := 'Error while converting pan ' || SUBSTR(SQLERRM,1,200);
RAISE    exp_reject_record;
END;
--EN create encr pan
       
      BEGIN
         INSERT INTO CMS_PAN_SPPRT
                     (cps_inst_code, cps_pan_code, cps_mbr_numb,
                      cps_prod_catg, cps_spprt_key, cps_func_remark,
                      cps_spprt_rsncode, cps_ins_user, cps_lupd_user,cps_pan_code_encr
                     )
              VALUES (prm_instcode,v_hash_new_pan, --prm_newpan,--prm_pancode, 
                       v_mbrnumb,
                      v_cap_prod_catg, 'REISU', prm_remark,
                      v_resoncode, prm_lupduser, prm_lupduser,v_encr_new_pan
                     );
      EXCEPTION                                              --excp of begin 3
         WHEN OTHERS THEN
            v_errmsg :=
                  'Error while inserting records in Pan_Spprt'
               || SUBSTR (SQLERRM, 1, 200);
            RAISE exp_reject_record;
      END;                                                               --beg
   ---------------------------------En create a record in PAN_SPPRT-------------------------------
   ----------------------------------Sn Insert new pan in merchant if request is from merchat module------------------
   BEGIN
           SELECT pcc_merc_code,pcc_cust_code 
           INTO v_merc_code,v_cust_code FROM cms_merchant_cards 
           WHERE pcc_pan_no = prm_pancode
           AND pcc_inst_code = prm_instcode;
           IF v_merc_code IS NOT NULL THEN
               INSERT INTO cms_merchant_cards(pcc_inst_code, pcc_merc_code, pcc_pan_no, 
                                pcc_ins_user, pcc_ins_date, pcc_lupd_user, pcc_lupd_date, pcc_cust_code,
                   pcc_pan_no_encr)  
                      VALUES(prm_instcode,v_merc_code,--prm_newpan
            v_hash_new_pan,prm_lupduser,
                                  sysdate,prm_lupduser,sysdate,v_cust_code,v_encr_new_pan);
           END IF;
    EXCEPTION
    WHEN NO_DATA_FOUND THEN
                v_errmsg :=
                  'Error while inserting records in Merc cards' || SUBSTR (SQLERRM, 1, 200);
    WHEN OTHERS THEN
                v_errmsg :=
                  'Error while inserting records in Merc cards' || SUBSTR (SQLERRM, 1, 200);
    END;
    
    ----------------------------------Sn Insert new pan in merchant if request is from merchat module------------------
   BEGIN
           SELECT pcc_corp_code 
           INTO v_corp_code FROM cms_corporate_cards 
           WHERE pcc_pan_no = prm_pancode
           AND pcc_inst_code = prm_instcode;
           IF v_merc_code IS NOT NULL THEN
               INSERT INTO cms_corporate_cards(pcc_inst_code, pcc_corp_code, pcc_pan_no, 
               pcc_ins_user, pcc_ins_date, pcc_lupd_user, pcc_lupd_date,pcc_pan_no_encr)  
                      VALUES(prm_instcode,v_corp_code,--prm_newpan
            v_hash_new_pan,prm_lupduser,
                                  sysdate,prm_lupduser,sysdate,v_encr_new_pan);
           END IF;
    EXCEPTION
    WHEN NO_DATA_FOUND THEN
                v_errmsg :=
                  'Error while inserting records in Corp cards' || SUBSTR (SQLERRM, 1, 200);
    WHEN OTHERS THEN
                v_errmsg :=
                  'Error while inserting records in Corp cards' || SUBSTR (SQLERRM, 1, 200);
    END;           
    
   /*  ---------------------------------Sn create a record in HTLST   REISSUE-------------------------------
      BEGIN                                                   --begin 4 starts
         INSERT INTO CMS_HTLST_REISU
                     (chr_inst_code, chr_pan_code, chr_mbr_numb,
                      chr_new_pan, chr_new_mbr, chr_reisu_cause,
                      chr_ins_user, chr_lupd_user
                     )
              VALUES (prm_instcode, prm_pancode, v_mbrnumb,
                      prm_newpan, v_mbrnumb, 'H',
                      prm_lupduser, prm_lupduserj
                     );
      EXCEPTION                                              --excp of begin 4
         WHEN OTHERS
         THEN
            v_errmsg :=
                   'Excp 4 -- Given Pan is already reissued once ' || SQLERRM;
            RAISE exp_reject_record;
      END;*/
   -----------------------En create a record in HTLST   REISSUE-------------------------------------
--   END IF;
--prm_errmsg :='OK';
EXCEPTION
   WHEN exp_authreject_record THEN
      prm_errmsg := v_autherrmsg;
      prm_auth_message := v_autherrmsg;                --<< MAIN EXCEPTION >>
      prm_processmessage := v_autherrmsg;
   WHEN exp_reject_record THEN
      prm_errmsg := v_errmsg;
      prm_auth_message := v_errmsg;
      prm_processmessage := v_applprocess_msg;
   WHEN OTHERS THEN
      prm_errmsg := 'Error from main ' || SUBSTR (SQLERRM, 1, 200);
END;                                                          --<< MAIN END >>
/


