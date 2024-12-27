                                                                                                                                                                                                                                                                                                                                                         
  CREATE OR REPLACE PROCEDURE "VMSCMS"."GPP_SP_UPD_PROFILEINFO"                                                                                                                                                                                                                                                                                               
-- gpp_sp_upd_profileinfo
(
   p_action_in          IN VARCHAR2,
   prm_instcode         IN NUMBER,
   prm_msg_type         IN VARCHAR2,
   prm_remark           IN VARCHAR2,
   prm_pan_code         IN VARCHAR2,
   prm_mbrnumb          IN VARCHAR2,
   prm_acct_no          IN VARCHAR2,
   prm_rrn              IN VARCHAR2,
   prm_stan             IN VARCHAR2,
   prm_txn_code         IN VARCHAR2,
   prm_txn_mode         IN VARCHAR2,
   prm_delivery_channel IN VARCHAR2,
   prm_trandate         IN VARCHAR2,
   prm_trantime         IN VARCHAR2,
   prm_currcode         IN VARCHAR2,
   prm_lastname         IN VARCHAR2,
   prm_dob              IN VARCHAR2,
   prm_ssn              IN VARCHAR2,
   prm_email            IN VARCHAR2,
   prm_mobile_no        IN VARCHAR2,
   prm_alternate_phone  IN VARCHAR2,
   prm_phy_addr1        IN VARCHAR2,
   prm_phy_addr2        IN VARCHAR2,
   prm_phy_city         IN VARCHAR2,
   prm_phy_state        IN NUMBER,
   prm_phy_zip          IN VARCHAR2,
   prm_phy_country      IN NUMBER,
   prm_mailing_addr1    IN VARCHAR2,
   prm_mailing_addr2    IN VARCHAR2,
   prm_mailing_city     IN VARCHAR2,
   prm_mailing_state    IN NUMBER,
   prm_mailing_zip      IN VARCHAR2,
   prm_mailing_country  IN NUMBER,
   prm_rvsl_code        IN VARCHAR2,
   prm_ins_user         IN NUMBER,
   prm_call_id          IN NUMBER,
   prm_addrupd_flag     IN CHAR,
   prm_ipaddress        IN VARCHAR2,
   prm_maiden_name      IN VARCHAR2,
   prm_first_name       IN VARCHAR2,
   prm_middle_name      IN VARCHAR2,
   prm_reason_code      IN VARCHAR2,
   prm_id_type          IN VARCHAR2,
   p_issuedby_in        IN VARCHAR2,
   p_issuance_date_in   IN VARCHAR2,
   p_expiration_date_in IN VARCHAR2,
   p_encr_pan           IN RAW,
   p_hash_pan           IN VARCHAR2,
   prm_auth_user        IN VARCHAR2,
   prm_username         IN VARCHAR2,
   prm_resp_code        OUT VARCHAR2,
   prm_resp_msg         OUT VARCHAR2,
   Prm_Optin_Flag_Out   OUT VARCHAR2
) IS
   /*******************************************************************************
        * Created Date                 : 13/Jan/2012.
        * Created By                   : Sagar More.
        * Purpose                      : to update profile information of customer
        * Last Modified for            : Mailing Address Update
        * Last Modification Date       : 23-Nov-2012
        * Build Number                 : RI0022

        * modified for                 : SSN Changes
        * modified Date                : 19-Feb-2013
        * modified reason              : To update prm_id_type in cms_cust_mast table
        * Build Number                 : RI0023.2_B0001


        * Modified for                 : MVCSD-4121
        * Modified Date                : 14-Mar-2014
        * Modified By                  : Narsing Ingle
        * Modified reason              : To update address verification flag
        * Build Number                 : RI0027.2_B0002

        * Modified for                 : Mantis-14101
        * Modified Date                : 14-Apr-2014
        * Modified By                  : Narsing Ingle
        * Modified reason              : To update address verification flag
        * Build Number                 : RI0027.2_B0005

        * Modified for                 : JH-3159
        * Modified Date                : 18-dEC-2014
        * Modified By                  : Abdul Hameed M.A
        * Modified reason              : To update auth user name in cust mast
        * Build Number                 :

        * Modified for                 : JH-1961
        * Modified Date                : 22-dEC-2014
        * Modified By                  : Abdul Hameed M.A
        * Modified reason              : Address Override
        * Build Number                 : RI0027.5_B0002
        * Modified for                 : MVCAN-676
        * Modified Date                : 29-May-2015
        * Modified By                  : Siva Kumar M
        * Modified reason              : CSD is Requiring SSN/SIN Number When Updating Profile
        * Build Number                  :VMSGPRHOSTCSD_3.0.3_B0001

        * Modified for                 : VMS-162
        * Modified Date                : 17-Apr-2018
        * Modified By                  : Vini
        * Build Number                 : 18.02

        * Modified for                 : FSAPICCA-103
        * Modified Date                : 26-Apr-2018
        * Modified By                  : Vini
        * Build Number                 : R01

		* Modified for                 : VMS-958(Enhance CCA to support cardholder data search for Rewards products )
        * Modified Date                : 17-Jun-2019
        * Modified By                  : Ubaidur Rahman H
		* Reviewed By                  : Saravanakumar A
        * Build Number                 : R17

	* Modified By      :  Ubaidur Rahman.H
     * Modified Date    :  03-Dec-2021
     * Modified Reason  :  VMS-5253 / 5372 - Do not pass sytem generated value from VMS to CCA.
     * Reviewer         :  Saravanakumar
     * Build Number     :  VMSGPRHOST_R55_RELEASE
     
     * Modified By      :  Bhavani E
     * Modified Date    :  29-Nov-2022
     * Modified Reason  :  VMS-6588 - Enabling CCPA flag if user request
     * Reviewer         :  Venkat
     * Build Number     :  FSAPI-CCA R73 

   ********************************************************************************/
   v_mail_city_chk  gen_city_mast.gcm_city_name%TYPE;
   v_mail_cntry_chk gen_cntry_mast.gcm_cntry_code%TYPE;
   v_mail_state_chk gen_state_mast.gsm_state_code%TYPE;
   v_phy_city_chk   gen_city_mast.gcm_city_name%TYPE;
   v_phy_cntry_chk  gen_cntry_mast.gcm_cntry_code%TYPE;
   v_phy_state_chk  gen_state_mast.gsm_state_code%TYPE;
   v_cust_code      cms_appl_pan.cap_cust_code%TYPE;
   v_hash_pan       cms_appl_pan.cap_pan_code%TYPE;
   v_mbrnumb        cms_appl_pan.cap_mbr_numb%TYPE;
   v_proxynumber    cms_appl_pan.cap_proxy_number%TYPE;
   v_encr_pan       cms_appl_pan.cap_pan_code_encr%TYPE;
   v_prodcatg       cms_appl_pan.cap_prod_catg%TYPE;
   v_prod_cattype   cms_appl_pan.cap_card_type%TYPE;
   v_prod_code      cms_appl_pan.cap_prod_code%TYPE;
   v_capture_date   DATE;
   v_auth_id        NUMBER;
   v_rrn_count      NUMBER(3);
   v_respcode       VARCHAR2(5);
   v_errmsg         transactionlog.error_msg%TYPE; -- changed from varchar2(200) to column datatype
   exp_reject_txn EXCEPTION;
   v_acct_balance   cms_acct_mast.cam_acct_bal%TYPE;
   v_ledger_balance cms_acct_mast.cam_ledger_bal%TYPE;
   v_cnt            NUMBER(2);
   -- added by sagar on 16FEB2012 to check sql%rowcount fof insert

   /* variables added for call log info   start */
   v_table_list    VARCHAR2(2000);
   v_colm_list     VARCHAR2(2000);
   v_colm_qury     VARCHAR2(2000);
   v_old_value_p   VARCHAR2(4000);
   v_old_value_o   VARCHAR2(4000);
   v_old_value     VARCHAR2(4000);
   v_new_value_p   VARCHAR2(4000);
   v_new_value_o   VARCHAR2(4000);
   v_new_value     VARCHAR2(4000);
   v_call_seq      NUMBER(3);
   v_addr_flag     CHAR(1);
   v_offaddrcount  NUMBER(3);
   v_mailaddr_cnt  NUMBER(4);
   v_phyaddr_cnt   NUMBER(4);
   v_mailaddr_cnt1 NUMBER(4);
   v_phyaddr_cnt1  NUMBER(4);
   /* variables added for call log info   END */
   v_date_format cms_inst_param.cip_param_value%TYPE;
   -- added by sagar on 24-May-2012
   v_spnd_acctno     cms_appl_pan.cap_acct_no%TYPE; -- ADDED BY GANESH ON 19-JUL-12
   v_resoncode       cms_spprt_reasons.csr_spprt_rsncode%TYPE; -- added on 06NOV2012
   v_reason          cms_spprt_reasons.csr_reasondesc%TYPE; -- added on 06NOV2012
   v_addr_verif_flag cms_cust_mast.ccm_addrverify_flag%TYPE; --Added By Narsing on 14th Jan 2014 for MVCSD-4121
   v_trans_desc      cms_transaction_mast.ctm_tran_desc%TYPE; --Added By Narsing on 14th Jan 2014 for MVCSD-4121
   v_addrcallseq     cms_calllog_details.ccd_call_seq%TYPE; --Added By Narsing on 14th Jan 2014 for MVCSD-4121
   V_ENCRYPT_ENABLE     CMS_PROD_CATTYPE.CPC_ENCRYPT_ENABLE%TYPE; -- Added for VMS-162
   v_encr_first_name    cms_cust_mast.ccm_first_name%type;
   v_encr_mid_name      cms_cust_mast.ccm_mid_name%type;
   v_encr_last_name     cms_cust_mast.ccm_last_name%type;
   v_encr_mother_name   cms_cust_mast.ccm_mother_name%type;
   v_encr_mob_one       cms_addr_mast.cam_mobl_one%type;
   v_encr_phone_no      cms_addr_mast.CAM_PHONE_ONE%type;
   v_encr_email         cms_addr_mast.cam_email%type;
   v_encr_addr_lineone  cms_addr_mast.cam_add_one%type;
   v_encr_addr_linetwo  cms_addr_mast.cam_add_two%type;
   v_encr_city_name     cms_addr_mast.cam_city_name%type;
   v_encr_zip           cms_addr_mast.cam_pin_code%type;
   v_encr_full_name     cms_avq_status.cas_cust_name%Type;
   addr_rrn          VARCHAR2(100); --Added By Narsing on 14th Jan 2014 for MVCSD-4121
   --Sn Added for JH-1961
   v_cust_id      cms_cust_mast.ccm_cust_id%TYPE;
   v_cust_name    cms_avq_status.cas_cust_name%Type;
   v_pending_cnt  NUMBER;
   v_cardstat_cnt NUMBER;
   v_state_code   gen_state_mast.gsm_switch_state_code%TYPE;
   --En Added for JH-1961
   --fsapi changes
   l_main_query  VARCHAR2(4000);
   l_where_query VARCHAR2(4000);
   V_Doptin_Flag        Number;
   Type CurrentAlert_Collection Is Table Of Varchar2(30);
   CurrentAlert             CurrentAlert_Collection;
   V_Cam_Mobl_One           Cms_Addr_Mast.Cam_Mobl_One%Type;
   v_Alert_Lang_Id          Cms_Smsandemail_Alert.Csa_Alert_Lang_Id%Type;
   v_loadcredit_flag        CMS_SMSANDEMAIL_ALERT.CSA_LOADORCREDIT_FLAG%TYPE;
   v_lowbal_flag            CMS_SMSANDEMAIL_ALERT.CSA_LOWBAL_AMT%TYPE;
   v_negativebal_flag       CMS_SMSANDEMAIL_ALERT.CSA_NEGBAL_FLAG%TYPE;
   v_highauthamt_flag       CMS_SMSANDEMAIL_ALERT.CSA_HIGHAUTHAMT_FLAG%TYPE;
   v_dailybal_flag          CMS_SMSANDEMAIL_ALERT.CSA_DAILYBAL_FLAG%TYPE;
   V_Insuffund_Flag         Cms_Smsandemail_Alert.Csa_Insuff_Flag%Type;
   V_Incorrectpin_Flag      CMS_SMSANDEMAIL_ALERT.CSA_INCORRPIN_FLAG%Type;
   V_Fast50_Flag            CMS_SMSANDEMAIL_ALERT.Csa_Fast50_Flag%Type;
   v_federal_state_flag     CMS_SMSANDEMAIL_ALERT.CSA_FEDTAX_REFUND_FLAG%Type;
BEGIN
   -- Main begin starts here
   dbms_output.put_line('prm_pan_code' || prm_pan_code);
   dbms_output.put_line('prm_acct_no' || prm_acct_no);
   dbms_output.put_line('prm_rrn' || prm_rrn);
   dbms_output.put_line('prm_trandate' || prm_trandate);
   dbms_output.put_line('prm_trantime' || prm_trantime);
   dbms_output.put_line('prm_currcode' || prm_currcode);
   dbms_output.put_line('prm_lastname' || prm_lastname);
   dbms_output.put_line('prm_dob' || prm_dob);
   dbms_output.put_line('prm_ssn' || prm_ssn);
   dbms_output.put_line('prm_email' || prm_email);
   dbms_output.put_line('prm_mobile_no' || prm_mobile_no);
   dbms_output.put_line('prm_alternate_phone' || prm_alternate_phone);
   dbms_output.put_line('prm_mailing_addr1' || prm_mailing_addr1);
   dbms_output.put_line('prm_phy_addr1' || prm_phy_addr1);

   BEGIN
      -- begin 001 starts here
      v_errmsg := 'OK';
      Prm_Optin_Flag_Out :='N';
      --SN CREATE HASH PAN
      BEGIN
         -- v_hash_pan := gethash(prm_pan_code);
         v_hash_pan := p_hash_pan;
      EXCEPTION
         WHEN OTHERS THEN
            v_respcode := '21';
            v_errmsg   := 'Error while converting in hashpan ' ||
                          substr(SQLERRM, 1, 100);
            RAISE exp_reject_txn;
      END;

      --EN CREATE HASH PAN

      --SN create encr pan
      BEGIN
         --  v_encr_pan := fn_emaps_main(prm_pan_code);
         v_encr_pan := p_encr_pan;
      EXCEPTION
         WHEN OTHERS THEN
            v_respcode := '12';
            v_errmsg   := 'Error while converting encrpan ' ||
                          substr(SQLERRM, 1, 200);
            RAISE exp_reject_txn;
      END;

      --EN create encr pan
      --      BEGIN
      --         SELECT COUNT(1)
      --           INTO v_rrn_count
      --           FROM vmscms.transactionlog
      --          WHERE instcode = prm_instcode
      --            AND customer_card_no = v_hash_pan
      --            AND rrn = prm_rrn
      --            AND delivery_channel = prm_delivery_channel
      --            AND txn_code = prm_txn_code
      --            AND business_date = prm_trandate
      --            AND business_time = prm_trantime
      --            AND delivery_channel = prm_delivery_channel; --Ramkumar.MK
      --
      --         IF v_rrn_count > 0
      --         THEN
      --            v_respcode := '22';
      --            v_errmsg   := 'Duplicate RRN found';
      --            RAISE exp_reject_txn;
      --         END IF;
      --      EXCEPTION
      --         WHEN exp_reject_txn THEN
      --            RAISE;
      --         WHEN OTHERS THEN
      --            v_errmsg   := 'while getting rrn count ' ||
      --                          substr(SQLERRM, 1, 100);
      --            v_respcode := '21';
      --            RAISE exp_reject_txn;
      --      END;

      BEGIN

         IF prm_reason_code IS NOT NULL
         THEN

            v_resoncode := prm_reason_code;

            BEGIN

               SELECT csr_reasondesc
                 INTO v_reason
                 FROM vmscms.cms_spprt_reasons
                WHERE csr_spprt_rsncode = v_resoncode
                  AND csr_inst_code = prm_instcode;

            EXCEPTION
               WHEN no_data_found THEN
                  v_respcode := '21';
                  v_errmsg   := 'reason code not found in master for reason code ' ||
                                v_resoncode;
                  RAISE exp_reject_txn;
               WHEN OTHERS THEN
                  v_respcode := '21';
                  v_errmsg   := 'Error while selecting reason description' ||
                                substr(SQLERRM, 1, 200);
                  RAISE exp_reject_txn;
            END;

         END IF;

      EXCEPTION
         WHEN exp_reject_txn THEN
            RAISE;

         WHEN OTHERS THEN
            v_respcode := '21';
            v_errmsg   := 'Error from reason code block ' ||
                          substr(SQLERRM, 1, 200);
            RAISE exp_reject_txn;
      END;

      BEGIN
         vmscms.sp_authorize_txn_cms_auth(prm_instcode,
                                          prm_msg_type,
                                          prm_rrn,
                                          prm_delivery_channel,
                                          NULL,
                                          prm_txn_code,
                                          prm_txn_mode,
                                          prm_trandate,
                                          prm_trantime,
                                          prm_pan_code,
                                          NULL,
                                          0,
                                          NULL,
                                          NULL,
                                          NULL,
                                          prm_currcode,
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
                                          prm_mbrnumb,
                                          prm_rvsl_code,
                                          NULL,
                                          v_auth_id,
                                          v_respcode,
                                          v_errmsg,
                                          v_capture_date);                              

         IF v_respcode <> '00'
         THEN

            BEGIN
               --added on 09-Oct-2012
               UPDATE vmscms.transactionlog
                  SET remark        = prm_remark,
                      ipaddress     = prm_ipaddress,
                      add_ins_user  = prm_ins_user,
                      add_lupd_user = prm_ins_user,
                      reason        = v_reason -- added on 06NOV2012
                WHERE instcode = prm_instcode
                  AND customer_card_no = v_hash_pan
                  AND rrn = prm_rrn
                  AND business_date = prm_trandate
                  AND business_time = prm_trantime
                  AND delivery_channel = prm_delivery_channel
                  AND txn_code = prm_txn_code;

               IF SQL%ROWCOUNT = 0
               THEN
                  v_respcode := '21';
                  v_errmsg   := 'Auth Fail - Txn not updated in transactiolog for remark ';
                  RAISE exp_reject_txn;
               END IF;
            EXCEPTION
               WHEN exp_reject_txn THEN
                  RAISE;
               WHEN OTHERS THEN
                  v_respcode := '21';
                  v_errmsg   := 'Auth Fail - Error while updating into transactiolog ' ||
                                substr(SQLERRM, 1, 200);
                  RAISE exp_reject_txn;
            END;

            prm_resp_code := v_respcode;
            prm_resp_msg  := v_errmsg;

            RETURN;

         END IF;

      EXCEPTION
         WHEN exp_reject_txn THEN
            RAISE;

         WHEN OTHERS THEN
            v_respcode := '21';
            v_errmsg   := 'problem while call to sp_authorize_txn_cmsauth ' ||
                          substr(SQLERRM, 1, 100);
            RAISE exp_reject_txn;
      END;

      BEGIN
         SELECT cap_cust_code,
                cap_mbr_numb,
                cap_proxy_number,
                cap_prod_code,
                cap_prod_catg,
                cap_card_type,
                cap_acct_no
           INTO v_cust_code,
                v_mbrnumb,
                v_proxynumber,
                v_prod_code,
                v_prodcatg,
                v_prod_cattype,
                v_spnd_acctno
           FROM vmscms.cms_appl_pan
          WHERE cap_inst_code = prm_instcode
            AND cap_pan_code = v_hash_pan;
      EXCEPTION
         WHEN no_data_found THEN
            v_errmsg   := 'Pan not found in master';
            v_respcode := '16';
            RAISE exp_reject_txn;
         WHEN OTHERS THEN
            v_errmsg   := 'from pan master ' || substr(SQLERRM, 1, 100);
            v_respcode := '21';
            RAISE exp_reject_txn;
      END;

      SELECT COUNT(*)
        INTO v_mailaddr_cnt
        FROM vmscms.cms_addr_mast
       WHERE cam_inst_code = prm_instcode
         AND cam_cust_code = v_cust_code
         AND cam_addr_flag = 'O';

      SELECT COUNT(*)
        INTO v_phyaddr_cnt
        FROM vmscms.cms_addr_mast
       WHERE cam_inst_code = prm_instcode
         AND cam_cust_code = v_cust_code
         AND cam_addr_flag = 'P';

      /*  call log info   start */
      --      BEGIN
      --         SELECT cut_table_list, cut_colm_list, cut_colm_qury
      --           INTO v_table_list, v_colm_list, v_colm_qury
      --           FROM vmscms.cms_calllogquery_mast
      --          WHERE cut_inst_code = prm_instcode
      --            AND cut_devl_chnl = prm_delivery_channel
      --            AND cut_txn_code = prm_txn_code;
      --      EXCEPTION
      --         WHEN no_data_found THEN
      --            v_respcode := '16';
      --            v_errmsg   := 'Column list not found in cms_calllogquery_mast ';
      --            RAISE exp_reject_txn;
      --         WHEN OTHERS THEN
      --            v_errmsg   := 'Error while finding Column list ' ||
      --                          substr(SQLERRM, 1, 100);
      --            v_respcode := '21';
      --            RAISE exp_reject_txn;
      --      END;

      --IF prm_addrupd_flag = 'Y'
      --THEN
      IF prm_mailing_zip IS NOT NULL
      THEN
         BEGIN
            SELECT gsm_state_code
              INTO v_mail_state_chk
              FROM vmscms.gen_state_mast
             WHERE gsm_inst_code = prm_instcode
               AND TRIM(gsm_cntry_code) = TRIM(prm_mailing_country)
               AND TRIM(gsm_state_code) = TRIM(prm_mailing_state);

            v_mail_state_chk := NULL;
         EXCEPTION
            WHEN no_data_found THEN
               v_errmsg   := 'mailing state code ' || prm_mailing_state ||
                             ' not found for country code ' ||
                             prm_mailing_country;
               v_respcode := '16';
               RAISE exp_reject_txn;
            WHEN OTHERS THEN
               v_errmsg   := 'while fecthing mailing state code ' ||
                             substr(SQLERRM, 1, 100);
               v_respcode := '21';
               RAISE exp_reject_txn;
         END;

         BEGIN
            SELECT gcm_cntry_code
              INTO v_mail_cntry_chk
              FROM vmscms.gen_cntry_mast
             WHERE gcm_inst_code = prm_instcode
               AND TRIM(gcm_cntry_code) = TRIM(prm_mailing_country);

            v_mail_cntry_chk := NULL;
         EXCEPTION
            WHEN no_data_found THEN
               v_errmsg   := 'mailing country code ' || prm_mailing_country ||
                             ' not found in master';
               v_respcode := '16';
               RAISE exp_reject_txn;
            WHEN OTHERS THEN
               v_errmsg   := 'while fecthing mailing country code for cntry ' ||
                             prm_mailing_country || ' ' ||
                             substr(SQLERRM, 1, 100);
               v_respcode := '21';
               RAISE exp_reject_txn;
         END;
      END IF;

      -- END IF;
      dbms_output.put_line('v_phy_state_chk' || v_phy_state_chk);
      IF prm_phy_zip IS NOT NULL
      THEN
         BEGIN
            SELECT gsm_state_code
              INTO v_phy_state_chk
              FROM vmscms.gen_state_mast
             WHERE gsm_inst_code = prm_instcode
               AND TRIM(gsm_cntry_code) = TRIM(prm_phy_country)
               AND TRIM(gsm_state_code) = TRIM(prm_phy_state);

            v_phy_state_chk := NULL;
         EXCEPTION
            WHEN no_data_found THEN
               v_errmsg   := 'physical state code not found for state ' ||
                             prm_phy_state || ' and country code ' ||
                             prm_phy_country;
               v_respcode := '16';
               RAISE exp_reject_txn;
            WHEN OTHERS THEN
               v_errmsg   := 'while fecthing physical state code ' ||
                             substr(SQLERRM, 1, 100);
               v_respcode := '21';
               RAISE exp_reject_txn;
         END;
         dbms_output.put_line('prm_phy_country' || prm_phy_country);
         BEGIN
            SELECT gcm_cntry_code
              INTO v_phy_cntry_chk
              FROM vmscms.gen_cntry_mast
             WHERE gcm_inst_code = prm_instcode
               AND TRIM(gcm_cntry_code) = TRIM(prm_phy_country);

            v_phy_cntry_chk := NULL;
         EXCEPTION
            WHEN no_data_found THEN
               v_errmsg   := 'Physical country code not found for cntry ' ||
                             prm_phy_country;
               v_respcode := '16';
               RAISE exp_reject_txn;
            WHEN OTHERS THEN
               v_errmsg   := 'while fecthing Physical country code for cntry ' ||
                             prm_phy_country || ' ' ||
                             substr(SQLERRM, 1, 100);
               v_respcode := '21';
               RAISE exp_reject_txn;
         END;
      END IF;

      --      IF v_mailaddr_cnt > 0
      --      THEN
      --         BEGIN
      --            v_addr_flag := 'O';
      --
      --            EXECUTE IMMEDIATE v_colm_qury
      --               INTO v_old_value_o
      --               USING v_cust_code, v_addr_flag;
      --         EXCEPTION
      --            WHEN OTHERS THEN
      --               v_errmsg   := 'Error while selecting old values -- ' ||
      --                             prm_addrupd_flag || '---' ||
      --                             substr(SQLERRM, 1, 100);
      --               v_respcode := '21';
      --               RAISE exp_reject_txn;
      --         END;
      --      ELSE
      --         v_old_value_o := 'Mailing Address not available ';
      --      END IF;
      --
      --      v_old_value_o := 'O-|' || v_old_value_o;

      --      IF v_phyaddr_cnt > 0
      --      THEN
      --         BEGIN
      --            v_addr_flag := 'P';
      --
      --            EXECUTE IMMEDIATE v_colm_qury
      --               INTO v_old_value_p
      --               USING v_cust_code, v_addr_flag;
      --         EXCEPTION
      --            WHEN OTHERS THEN
      --               v_errmsg   := 'Error while selecting old values -- ' ||
      --                             prm_addrupd_flag || '---' ||
      --                             substr(SQLERRM, 1, 100);
      --               v_respcode := '21';
      --               RAISE exp_reject_txn;
      --         END;
      --      ELSE
      --         v_old_value_p := 'Physical Address not available ';
      --      END IF;
      --
      --      v_old_value_p := 'P-|' || v_old_value_p;
      --      v_old_value   := v_old_value_o || '|' || v_old_value_p;

      -- SN : ADDED BY Ganesh on 18-JUL-12
      --      BEGIN
      --         SELECT cap_acct_no
      --           INTO v_spnd_acctno
      --           FROM vmscms.cms_appl_pan
      --          WHERE cap_pan_code = v_hash_pan
      --            AND cap_inst_code = prm_instcode
      --            AND cap_mbr_numb = prm_mbrnumb;
      --      EXCEPTION
      --         WHEN no_data_found THEN
      --            v_respcode := '21';
      --            v_errmsg   := 'Spending Account Number Not Found For the Card in PAN Master ';
      --            RAISE exp_reject_txn;
      --         WHEN OTHERS THEN
      --            v_respcode := '21';
      --            v_errmsg   := 'Error While Selecting Spending account Number for Card ' ||
      --                          substr(SQLERRM, 1, 100);
      --            RAISE exp_reject_txn;
      --      END;

      -- EN : ADDED BY Ganesh on 18-JUL-12
      BEGIN
         BEGIN
            SELECT nvl(MAX(ccd_call_seq), 0) + 1
              INTO v_call_seq
              FROM vmscms.cms_calllog_details
             WHERE ccd_inst_code = ccd_inst_code
               AND ccd_call_id = prm_call_id
               AND ccd_pan_code = v_hash_pan;
         EXCEPTION
            WHEN no_data_found THEN
               v_errmsg   := 'record is not present in cms_calllog_details  ';
               v_respcode := '16';
               RAISE exp_reject_txn;
            WHEN OTHERS THEN
               v_errmsg   := 'Error while selecting frmo cms_calllog_details ' ||
                             substr(SQLERRM, 1, 100);
               v_respcode := '21';
               RAISE exp_reject_txn;
         END;

         INSERT INTO vmscms.cms_calllog_details
            (ccd_inst_code,
             ccd_call_id,
             ccd_pan_code,
             ccd_call_seq,
             ccd_rrn,
             ccd_devl_chnl,
             ccd_txn_code,
             ccd_tran_date,
             ccd_tran_time,
             ccd_tbl_names,
             ccd_colm_name,
             ccd_old_value,
             ccd_new_value,
             ccd_comments,
             ccd_ins_user,
             ccd_ins_date,
             ccd_lupd_user,
             ccd_lupd_date,
             ccd_acct_no
             -- CCD_ACCT_NO ADDED BY GANESH ON 18-JUL-2012
             )
         VALUES
            (prm_instcode,
             prm_call_id,
             v_hash_pan,
             v_call_seq,
             prm_rrn,
             prm_delivery_channel,
             prm_txn_code,
             prm_trandate,
             prm_trantime,
             v_table_list,
             v_colm_list,
             v_old_value,
             NULL,
             prm_remark,
             prm_ins_user,
             SYSDATE,
             prm_ins_user,
             SYSDATE,
             v_spnd_acctno
             -- V_SPND_ACCTNO ADDED BY GANESH ON 18-JUL-2012
             );
      EXCEPTION
         WHEN exp_reject_txn THEN
            RAISE;
         WHEN OTHERS THEN
            v_respcode := '21';
            v_errmsg   := ' Error while inserting into cms_calllog_details ' ||
                          SQLERRM;
            RAISE exp_reject_txn;
      END;

      /*  call log info   END */
      BEGIN
         SELECT cam_acct_bal, cam_ledger_bal
           INTO v_acct_balance, v_ledger_balance
           FROM vmscms.cms_acct_mast
          WHERE cam_inst_code = prm_instcode
            AND cam_acct_no = prm_acct_no;
      EXCEPTION
         WHEN no_data_found THEN
            v_errmsg   := 'account not found in master';
            v_respcode := '16';
            RAISE exp_reject_txn;
         WHEN OTHERS THEN
            v_errmsg   := 'from account master ' || substr(SQLERRM, 1, 100);
            v_respcode := '21';
            RAISE exp_reject_txn;
      END;

      BEGIN
         SELECT cip_param_value
           INTO v_date_format
           FROM vmscms.cms_inst_param
          WHERE cip_inst_code = '1'
            AND cip_param_key = 'CSRDATEFORMAT';
      EXCEPTION
         WHEN no_data_found THEN
            v_errmsg   := 'Date format value not found in master';
            v_respcode := '49';
            RAISE exp_reject_txn;
         WHEN OTHERS THEN
            v_errmsg   := 'While fetching date format from master ' ||
                          substr(SQLERRM, 1, 100);
            v_respcode := '21';
            RAISE exp_reject_txn;
      END;
      BEGIN
         SELECT CPC_ENCRYPT_ENABLE
           INTO V_ENCRYPT_ENABLE
           FROM CMS_PROD_CATTYPE
          WHERE CPC_INST_CODE = PRM_INSTCODE
            AND CPC_PROD_CODE = V_PROD_CODE
            AND CPC_CARD_TYPE = V_PROD_CATTYPE;
      EXCEPTION
         WHEN NO_DATA_FOUND
         THEN
            v_errmsg := 'Product Category not Found';
            v_respcode := '16';
            RAISE exp_reject_txn;
         WHEN OTHERS
         THEN
            v_errmsg := 'from prod catg mast ' || SUBSTR (SQLERRM, 1, 100);
            v_respcode := '21';
            RAISE exp_reject_txn;
      END;

      BEGIN
         INSERT INTO VMS_AUDITTXN_DTLS (vad_rrn, vad_del_chnnl, vad_txn_code, vad_cust_code, vad_action_user, vad_action_username)
              VALUES (prm_rrn, prm_delivery_channel, prm_txn_code, v_cust_code,prm_ins_user, fn_emaps_main(prm_username));
      EXCEPTION
         WHEN OTHERS THEN
            v_respcode := '21';
            v_errmsg := 'Error while inserting audit dtls ' || SUBSTR (SQLERRM, 1, 200);
            RAISE exp_reject_txn;
      END;

	  IF V_ENCRYPT_ENABLE = 'Y' THEN
          v_encr_first_name   := fn_emaps_main(prm_first_name);
		      v_encr_mid_name     := fn_emaps_main(prm_middle_name);
          v_encr_last_name    := fn_emaps_main(PRM_LASTNAME);
	        v_encr_mother_name  := fn_emaps_main(prm_maiden_name);
          v_encr_mob_one      := fn_emaps_main(prm_mobile_no);
          v_encr_phone_no     := fn_emaps_main(prm_alternate_phone);
          v_encr_email        := fn_emaps_main(prm_email);
          v_encr_addr_lineone := fn_emaps_main(prm_phy_addr1);
          v_encr_addr_linetwo := fn_emaps_main(prm_phy_addr2);
          v_encr_city_name    := fn_emaps_main(prm_phy_city);
          v_encr_zip          := fn_emaps_main(prm_phy_zip);
      else
          v_encr_first_name   := prm_first_name;
          v_encr_mid_name     := prm_middle_name;
          v_encr_last_name    := PRM_LASTNAME;
          v_encr_mother_name  := prm_maiden_name;
          v_encr_mob_one      := prm_mobile_no;
          v_encr_phone_no     := prm_alternate_phone;
          v_encr_email        := prm_email;
          v_encr_addr_lineone := prm_phy_addr1;
          v_encr_addr_linetwo := prm_phy_addr2;
          v_encr_city_name    := prm_phy_city;
          v_encr_zip          := prm_phy_zip;
      end if;
      -- IF prm_addrupd_flag <> 'M'
      -- THEN
      --Added on 23112012 by Dhiraj G as discussed with Tejas



      BEGIN
         IF upper(p_action_in) = 'UPDATENAME'
         THEN

            /*dbms_output.put_line('prm_lastname' || prm_lastname);
            l_main_query  := 'UPDATE cms_cust_mast ';
            l_where_query := 'WHERE ccm_inst_code = prm_instcode
              AND ccm_cust_code = v_cust_code';
            CASE
               WHEN prm_first_name IS NOT NULL THEN
                  EXECUTE IMMEDIATE l_main_query || 'SET
                                 ccm_first_name = :prm_first_name' ||
                                    l_where_query
                     USING prm_first_name;
               WHEN prm_lastname IS NOT NULL THEN
                  EXECUTE IMMEDIATE l_main_query || 'SET
                                 ccm_last_name = :prm_lastname' ||
                                    l_where_query
                     USING prm_lastname;
               WHEN prm_maiden_name IS NOT NULL THEN
                  EXECUTE IMMEDIATE l_main_query || 'SET
                                 ccm_mother_name = :prm_maiden_name' ||
                                    l_where_query
                     USING prm_maiden_name;
               WHEN prm_dob IS NOT NULL THEN
                  EXECUTE IMMEDIATE l_main_query || 'SET
                                 ccm_birth_date = to_date(:prm_dob, v_date_format)' ||
                                    l_where_query
                     USING prm_dob;
               WHEN prm_auth_user IS NOT NULL THEN
                  EXECUTE IMMEDIATE l_main_query || 'SET
                                 ccm_auth_user = :prm_auth_user' ||
                                    l_where_query
                     USING prm_auth_user;
               ELSE
                  NULL;
                  END CASE;
                  */
            dbms_output.put_line('updating the name');
            UPDATE vmscms.cms_cust_mast
               SET ccm_last_name  = decode(prm_lastname,
                                           NULL,
                                           ccm_last_name,
                                           v_encr_last_name),
                   ccm_auth_user  = decode(prm_auth_user,
                                           NULL,
                                           ccm_auth_user,
                                           prm_auth_user),
                   ccm_birth_date = decode(to_date(prm_dob, v_date_format),
                                           NULL,
                                           ccm_birth_date,
                                           to_date(prm_dob, v_date_format)),
                   ccm_first_name = decode(prm_first_name,
                                           NULL,
                                           ccm_first_name,
                                           v_encr_first_name),
                   --
                   -- Start JIRA: CFIP-251 (3)
                   -- 5/16/2016
                   -- Update middle name if provided with a not null value
                   ccm_mid_name = nvl(v_encr_mid_name, ccm_mid_name),
                   -- End JIRA: CFIP-251 (3)
                   --

                   --Jira issue cfip:171 starts
                   /*ccm_mother_name = decode(prm_maiden_name,
                   NULL,
                   ccm_mother_name,
                   prm_maiden_name)*/

                   --
                   -- Start JIRA: CFIP-251 (4)
                   -- 5/16/2016
                   -- Update maiden name if provided with a not null value
                   ccm_mother_name = nvl(v_encr_mother_name, ccm_mother_name),
                   ccm_first_name_encr = nvl(fn_emaps_main(prm_first_name),ccm_first_name_encr),      --Added for VMS-958
                   ccm_last_name_encr  = nvl(fn_emaps_main(prm_lastname),ccm_last_name_encr)          --Added for VMS-958
            -- End JIRA: CFIP-251 (4)
            --
            --Jira issue cfip:171 ends
             WHERE ccm_inst_code = prm_instcode
               AND ccm_cust_code = v_cust_code;

         END IF;
         /*IF upper(p_action_in) = 'UNLOCKACCOUNT'
         THEN
            UPDATE vmscms.cms_cust_mast
               SET ccm_acctlock_flag   = 'N',
                   ccm_wrong_logincnt  = '0',
                   ccm_last_logindate  = '',
                   ccm_acctunlock_date = SYSDATE
             WHERE ccm_cust_id = p_customer_id_in;
         END IF;*/

         IF upper(p_action_in) = 'UPDATEIDENTIFICATION'
            AND prm_id_type IN ('DL', 'PASS') --jira fix for cfip:170
         THEN
            dbms_output.put_line('updating the identification for DL and PASS');
            /* JIRA CFIP-302:
            Updating SSN:
            Step 1: Encrypt SSN and update the CCM_SSN_ENCR column
            Step 2: Mask SSN and update the CCM_SSN column
            */
            UPDATE vmscms.cms_cust_mast
               SET ccm_ssn_encr = decode(prm_ssn,
                                         NULL,
                                         ccm_ssn_encr,
                                         fn_emaps_main(prm_ssn)),

                   ccm_ssn = decode(prm_ssn,
                                    NULL,
                                    ccm_ssn,
                                    fn_maskacct_ssn(1, prm_ssn, 0)),
                   /*      -- CFIP-302         SET ccm_ssn             = decode(prm_ssn,
                   NULL,
                   ccm_ssn,
                   prm_ssn),*/

                   ccm_id_type         = decode(prm_id_type,
                                                NULL,
                                                ccm_id_type,
                                                prm_id_type),
                   ccm_id_issuer       = decode(p_issuedby_in,
                                                NULL,
                                                ccm_id_issuer,
                                                p_issuedby_in),
                   ccm_idissuence_date = decode(to_date(p_issuance_date_in,
                                                        v_date_format),
                                                NULL,
                                                ccm_idissuence_date,
                                                to_date(p_issuance_date_in,
                                                        v_date_format)),
                   ccm_idexpry_date    = decode(to_date(p_expiration_date_in,
                                                        v_date_format),
                                                NULL,
                                                ccm_idexpry_date,
                                                to_date(p_expiration_date_in,
                                                        v_date_format))
             WHERE ccm_inst_code = prm_instcode
               AND ccm_cust_code = v_cust_code;
         END IF;
         --jira fix for cfip:170 starts
         IF upper(p_action_in) = 'UPDATEIDENTIFICATION'
            AND prm_id_type IN ('SSN', 'SIN')
         THEN
            dbms_output.put_line('updating the identification for SSN and SIN');
            /* JIRA CFIP-302:
            Updating SSN:
            Step 1: Encrypt SSN and update the CCM_SSN_ENCR column
            Step 2: Mask SSN and update the CCM_SSN column
            */
            UPDATE vmscms.cms_cust_mast
               SET ccm_ssn_encr = decode(prm_ssn,
                                         NULL,
                                         ccm_ssn_encr,
                                         fn_emaps_main(prm_ssn)),

                   ccm_ssn = decode(prm_ssn,
                                    NULL,
                                    ccm_ssn,
                                    fn_maskacct_ssn(1, prm_ssn, 0)),
                   /*      -- CFIP-302         SET ccm_ssn             = decode(prm_ssn,
                   NULL,
                   ccm_ssn,
                   prm_ssn),*/
                   ccm_id_type         = decode(prm_id_type,
                                                NULL,
                                                ccm_id_type,
                                                prm_id_type),
                   ccm_id_issuer       = NULL,
                   ccm_idissuence_date = NULL,
                   ccm_idexpry_date    = NULL
             WHERE ccm_inst_code = prm_instcode
               AND ccm_cust_code = v_cust_code;
            dbms_output.put_line('Rows updated for SSN ' || SQL%ROWCOUNT);
         END IF;
         --jira fix for cfip:170 starts ends
         /*CASE
           WHEN prm_ssn IS NOT NULL THEN
               EXECUTE IMMEDIATE l_main_query || 'SET
                                 ccm_ssn = :prm_ssn' ||
                                 l_where_query
                  USING prm_ssn;

               EXECUTE IMMEDIATE l_main_query || 'SET
                                 ccm_id_type = decode(:prm_id_type,
                                           NULL,
                                           ccm_id_type,
                                           :prm_id_type)' ||
                                 l_where_query
                  USING prm_id_type;

         END CASE;
         */
         /*UPDATE vmscms.cms_cust_mast
           SET ccm_last_name   = prm_lastname,
               ccm_auth_user   = prm_auth_user, --Added for JH-3159
               ccm_birth_date  = to_date(prm_dob, v_date_format),
               ccm_ssn         = prm_ssn, --DECODE (prm_ssn, NULL, ccm_ssn, prm_ssn),  -- Modified for MVCAN-676
               ccm_first_name  = prm_first_name, --Added on 01NOV2012 as a new enhancement
               ccm_mother_name = prm_maiden_name, --Added on 01NOV2012 as a new enhancement
               ccm_id_type     = decode(prm_id_type,
                                        NULL,
                                        ccm_id_type,
                                        prm_id_type) --Added on 19FEB2013 for SSN changes
         WHERE ccm_inst_code = prm_instcode
           AND ccm_cust_code = v_cust_code;*/

         IF SQL%ROWCOUNT = 0
         THEN
            v_errmsg   := 'cust mast not updated for custcode ' ||
                          v_cust_code;
            v_respcode := '16';
            RAISE exp_reject_txn;
         END IF;
      EXCEPTION
         WHEN exp_reject_txn THEN
            RAISE;
         WHEN OTHERS THEN
            v_errmsg   := 'Problem while updating cust mast for custcode ' ||
                          v_cust_code || substr(SQLERRM, 1, 100);
            v_respcode := '21';
            RAISE exp_reject_txn;
      END;

      BEGIN
      IF upper(p_action_in) = 'UPDATEPHONE' THEN
        BEGIN
          SELECT Csa_Alert_Lang_Id,
            Csa_Loadorcredit_Flag,
            Csa_Lowbal_Flag,
            Csa_Negbal_Flag,
            Csa_Highauthamt_Flag,
            Csa_Dailybal_Flag,
            Csa_Insuff_Flag,
            Csa_Fedtax_Refund_Flag,
            Csa_Fast50_Flag,
            Csa_Incorrpin_Flag
          INTO v_Alert_Lang_Id,
            V_Loadcredit_Flag,
            V_Lowbal_Flag,
            V_Negativebal_Flag,
            V_Highauthamt_Flag,
            V_Dailybal_Flag,
            V_Insuffund_Flag,
            V_Federal_State_Flag,
            V_Fast50_Flag,
            V_Incorrectpin_Flag
          FROM Cms_Smsandemail_Alert
          WHERE Csa_Pan_Code=v_hash_pan
          AND CSA_INST_CODE =prm_instcode;
      EXCEPTION
     WHEN OTHERS THEN
       v_respcode := '21';
       v_errmsg   :='Error while selecting customer alerts ' || SUBSTR (SQLERRM, 1, 200);
       RAISE exp_reject_txn;
     END;

    BEGIN
      SELECT COUNT(1)
      INTO v_doptin_flag
      FROM CMS_PRODCATG_SMSEMAIL_ALERTS
      WHERE NVL(Dbms_Lob.Substr( Cps_Alert_Msg,1,1),0) !=0
      AND Cps_Prod_Code= v_Prod_Code
      AND Cps_Card_Type= v_prod_cattype
      AND cps_alert_id=33
      AND Cps_Inst_Code= prm_instcode
      AND ( Cps_Alert_Lang_Id= v_alert_lang_id
      OR (v_alert_lang_id IS NULL
      AND CPS_DEFALERT_LANG_FLAG= 'Y'));

      IF(v_doptin_flag = 1) THEN
        Currentalert := Currentalert_Collection(V_Loadcredit_Flag,V_Lowbal_Flag,V_Negativebal_Flag,V_Highauthamt_Flag,V_Dailybal_Flag,V_Insuffund_Flag, V_Federal_State_Flag, V_Fast50_Flag,V_Incorrectpin_Flag);
        IF ('1' Member OF Currentalert OR '3' Member OF Currentalert) THEN

          SELECT DECODE(v_encrypt_enable,'Y',fn_dmaps_main(Cam_Mobl_One),Cam_Mobl_One)
          INTO V_Cam_Mobl_One
          FROM Cms_Addr_Mast
          WHERE Cam_Cust_Code = v_cust_code
          AND Cam_Addr_Flag ='P'
          AND Cam_Inst_Code = prm_instcode;

         IF(V_Cam_Mobl_One <> prm_mobile_no) THEN
            Prm_Optin_Flag_Out :='Y';
         END IF;
        END IF;
      END IF;
    EXCEPTION
    WHEN OTHERS THEN
      v_respcode := '21';
      v_errmsg   :='Error while selecting customer alerts ' || SUBSTR (SQLERRM, 1, 200);
      RAISE exp_reject_txn;
    END;

            dbms_output.put_line('updating the phone');
            UPDATE vmscms.cms_addr_mast
            --jira issue CFIP:171 starts
            /*cam_phone_one = decode(prm_alternate_phone,
            NULL,
            cam_phone_one,
            prm_alternate_phone),*/
               SET cam_phone_one = v_encr_phone_no,
                   --jira issue CFIP:171 ends
                   cam_mobl_one = decode(prm_mobile_no,
                                         NULL,
                                         cam_mobl_one,
                                         v_encr_mob_one)
             WHERE cam_inst_code = prm_instcode
               AND cam_cust_code = v_cust_code;
         END IF;
      EXCEPTION
         WHEN OTHERS THEN
            v_errmsg   := 'While updating PHONE for custcode-- ' || '---' ||
                          v_cust_code || substr(SQLERRM, 1, 100);
            v_respcode := '21';
            RAISE exp_reject_txn;
      END;

      BEGIN
         IF upper(p_action_in) = 'UPDATEEMAIL'
         THEN
            dbms_output.put_line('updating the email');
            UPDATE vmscms.cms_addr_mast cam_email
               SET cam_email = decode(prm_email, NULL, cam_email, v_encr_email),
                   cam_email_encr = nvl(fn_emaps_main(prm_email),cam_email_encr)
             WHERE cam_inst_code = prm_instcode
               AND cam_cust_code = v_cust_code;
         END IF;
      EXCEPTION
         WHEN OTHERS THEN
            v_errmsg   := 'While updating Email for custcode-- ' || '---' ||
                          v_cust_code || substr(SQLERRM, 1, 100);
            v_respcode := '21';
            RAISE exp_reject_txn;
      END;

      IF upper(p_action_in) = 'UPDATEADDRESS'
      THEN
         dbms_output.put_line('updating the physical address');
         dbms_output.put_line('prm_phy_state' || prm_phy_state);
         IF prm_phy_zip IS NOT NULL
         THEN
            IF v_phyaddr_cnt > 0
            THEN
               BEGIN
                  UPDATE vmscms.cms_addr_mast

                     SET cam_add_one = decode(prm_phy_addr1,
                                              NULL,
                                              cam_add_one,
                                              v_encr_addr_lineone),
                         --JIRA Issie CFIP:173 starts
                         /* cam_add_two    = decode(prm_phy_addr2,
                         NULL,
                         cam_add_two,
                         prm_phy_addr2),*/
                         cam_add_two = v_encr_addr_linetwo,
                         --JIRA Issie CFIP:173 ends
                         cam_city_name  = decode(prm_phy_city,
                                                 NULL,
                                                 cam_city_name,
                                                 v_encr_city_name),
                         cam_pin_code   = decode(prm_phy_zip,
                                                 NULL,
                                                 cam_pin_code,
                                                 v_encr_zip),
                         cam_state_code = decode(prm_phy_state,
                                                 NULL,
                                                 cam_state_code,
                                                 prm_phy_state),
                         cam_cntry_code = decode(prm_phy_country,
                                                 NULL,
                                                 cam_cntry_code,
                                                 prm_phy_country),
						 --Sn:Added for VMS-958						 
                         cam_add_one_encr = nvl(fn_emaps_main(prm_phy_addr1),cam_add_one_encr),
                         cam_add_two_encr = nvl(fn_emaps_main(prm_phy_addr2),cam_add_two_encr),
                         cam_city_name_encr = nvl(fn_emaps_main(prm_phy_city),cam_city_name_encr),
                         cam_pin_code_encr = nvl(fn_emaps_main(prm_phy_zip),cam_pin_code_encr)
						 --En:Added for VMS-958
                  /*SET cam_add_one   = prm_phy_addr1,
                         cam_add_two   = prm_phy_addr2,
                         cam_city_name = prm_phy_city,
                         cam_pin_code  = prm_phy_zip,
                        cam_phone_one  = prm_alternate_phone,
                         cam_mobl_one   = prm_mobile_no,
                         cam_state_code = prm_phy_state,
                         cam_cntry_code = prm_phy_country
                  cam_email      = prm_email*/
                   WHERE cam_inst_code = prm_instcode
                     AND cam_cust_code = v_cust_code
                     AND cam_addr_flag = 'P';
               EXCEPTION
                  WHEN OTHERS THEN
                     v_errmsg   := 'While updating physical addr for custcode-- ' ||
                                   prm_addrupd_flag || '---' || v_cust_code ||
                                   substr(SQLERRM, 1, 100);
                     v_respcode := '21';
                     RAISE exp_reject_txn;
               END;
            ELSE
               BEGIN
                  INSERT INTO vmscms.cms_addr_mast
                     (cam_inst_code,
                      cam_cust_code,
                      cam_addr_code,
                      cam_add_one,
                      cam_add_two,
                      cam_pin_code,
                      --cam_phone_one,
                      --cam_mobl_one,
                      cam_cntry_code,
                      cam_city_name,
                      cam_addr_flag,
                      cam_state_code,
                      cam_comm_type,
                      cam_ins_user,
                      cam_ins_date,
                      cam_lupd_user,
                      cam_lupd_date,
                      cam_add_one_encr,                 --Sn:Added for VMS-958
                      cam_add_two_encr,
                      cam_pin_code_encr,
                      cam_city_name_encr                --En:Added for VMS-958
                      )
                  VALUES
                     (prm_instcode,
                      v_cust_code,
                      seq_addr_code.nextval,
                      v_encr_addr_lineone,
                      v_encr_addr_linetwo,
                      v_encr_zip,
                      -- prm_alternate_phone,
                      -- prm_mobile_no,
                      prm_phy_country,
                      v_encr_city_name,
                      'P',
                      prm_phy_state,
                      'R',
                      1,
                      SYSDATE,
                      1,
                      SYSDATE,
                      fn_emaps_main(prm_phy_addr1),        --Sn:Added for VMS-958
                      fn_emaps_main(prm_phy_addr2),
                      fn_emaps_main(prm_phy_zip),
                      fn_emaps_main(prm_phy_city)          --En:Added for VMS-958
                      );
               EXCEPTION
                  WHEN OTHERS THEN
                     v_errmsg   := 'While inserting physical addr for custcode-- ' ||
                                   prm_addrupd_flag || '---' || v_cust_code ||
                                   substr(SQLERRM, 1, 100);
                     v_respcode := '21';
                     RAISE exp_reject_txn;
               END;
            END IF;
         END IF;
         /*--END IF; -- As discussed with Arun Vijay Commenting the if condition
         IF prm_addrupd_flag IN ('Y', 'M') -- 'Y' value replaced to ( 'Y' ,'M') --Added on 23112012 by Dhiraj G as discussed with Tejas
         THEN*/

        IF v_encrypt_enable = 'Y' THEN
              v_encr_addr_lineone := fn_emaps_main(prm_mailing_addr1);
              v_encr_addr_linetwo := fn_emaps_main(prm_mailing_addr2);
              v_encr_city_name    := fn_emaps_main(prm_mailing_city);
              v_encr_zip          := fn_emaps_main(prm_mailing_zip);
              v_encr_full_name    := fn_emaps_main(v_cust_name);
        ELSE
              v_encr_addr_lineone := prm_mailing_addr1;
              v_encr_addr_linetwo := prm_mailing_addr2;
              v_encr_city_name    := prm_mailing_city;
              v_encr_zip          := prm_mailing_zip;
              v_encr_full_name    := v_cust_name;
        END IF;

         IF prm_mailing_zip IS NOT NULL
         THEN
            dbms_output.put_line('updating the mailing address');
            IF v_mailaddr_cnt > 0
            THEN
               BEGIN
                  UPDATE vmscms.cms_addr_mast
                     SET cam_add_one = decode(prm_mailing_addr1,
                                              NULL,
                                              cam_add_one,
                                              v_encr_addr_lineone),
                         --Jira issue CFIP:173 starts
                         /*cam_add_two    = decode(prm_mailing_addr2,
                         NULL,
                         cam_add_two,
                         prm_mailing_addr2),*/
                         cam_add_two = v_encr_addr_linetwo,
                         --Jira issue CFIP:173 ends
                         cam_city_name  = decode(prm_mailing_city,
                                                 NULL,
                                                 cam_city_name,
                                                 v_encr_city_name),
                         cam_pin_code   = decode(prm_mailing_zip,
                                                 NULL,
                                                 cam_pin_code,
                                                 v_encr_zip),
                         cam_state_code = decode(prm_mailing_state,
                                                 NULL,
                                                 cam_state_code,
                                                 prm_mailing_state),
                         cam_cntry_code = decode(prm_mailing_country,
                                                 NULL,
                                                 cam_cntry_code,
                                                 prm_mailing_country),
						 --Sn:Added for VMS-958						 
                         cam_add_one_encr = nvl(fn_emaps_main(prm_mailing_addr1),cam_add_one_encr),
                         cam_add_two_encr = nvl(fn_emaps_main(prm_mailing_addr2),cam_add_two_encr),
                         cam_city_name_encr = nvl(fn_emaps_main(prm_mailing_city),cam_city_name_encr),
                         cam_pin_code_encr = nvl(fn_emaps_main(prm_mailing_zip),cam_pin_code_encr)
						 --En:Added for VMS-958
                  /*SET cam_add_one    = prm_mailing_addr1,
                  cam_add_two    = prm_mailing_addr2,
                  cam_city_name  = prm_mailing_city,
                  cam_pin_code   = prm_mailing_zip,
                  cam_state_code = prm_mailing_state,
                  cam_cntry_code = prm_mailing_country,
                  cam_mobl_one   = prm_mobile_no,
                  cam_phone_one  = prm_alternate_phone*/
                   WHERE cam_inst_code = prm_instcode
                     AND cam_cust_code = v_cust_code
                     AND cam_addr_flag = 'O';
               EXCEPTION
                  WHEN OTHERS THEN
                     v_errmsg   := 'While updating mailing addr for custcode -- ' ||
                                   prm_addrupd_flag || '---' || v_cust_code ||
                                   substr(SQLERRM, 1, 100);
                     v_respcode := '21';
                     RAISE exp_reject_txn;
               END;
            ELSE
               BEGIN
                  INSERT INTO vmscms.cms_addr_mast
                     (cam_inst_code,
                      cam_cust_code,
                      cam_addr_code,
                      cam_add_one,
                      cam_add_two,
                      cam_pin_code,
                      --cam_phone_one,
                      --cam_mobl_one,
                      cam_cntry_code,
                      cam_city_name,
                      cam_addr_flag,
                      cam_state_code,
                      cam_comm_type,
                      cam_ins_user,
                      cam_ins_date,
                      cam_lupd_user,
                      cam_lupd_date,
                      cam_add_one_encr,              --Sn:Added for VMS-958
                      cam_add_two_encr,
                      cam_pin_code_encr,
                      cam_city_name_encr             --En:Added for VMS-958
                      )
                  VALUES
                     (prm_instcode,
                      v_cust_code,
                      seq_addr_code.nextval,
                      v_encr_addr_lineone,
                      v_encr_addr_linetwo,
                      v_encr_zip,
                      --prm_alternate_phone,
                      --prm_mobile_no,
                      prm_mailing_country,
                      v_encr_city_name,
                      'O',
                      prm_mailing_state,
                      'R',
                      1,
                      SYSDATE,
                      1,
                      SYSDATE,
                      fn_emaps_main(prm_mailing_addr1),         --Sn:Added for VMS-958
                      fn_emaps_main(prm_mailing_addr2),
                      fn_emaps_main(prm_mailing_zip),
                      fn_emaps_main(prm_mailing_city)           --En:Added for VMS-958
                      );
               EXCEPTION
                  WHEN OTHERS THEN
                     v_errmsg   := 'While inserting mailing addr for custcode -- ' ||
                                   prm_addrupd_flag || '---' || v_cust_code ||
                               substr(SQLERRM, 1, 100);
                     v_respcode := '21';
                     RAISE exp_reject_txn;
               END;
            END IF;
         END IF;

	 --- Added for VMS-5253 Do not pass system generated value from VMS to CCA.
         BEGIN 
            UPDATE vmscms.CMS_CUST_MAST
            SET CCM_SYSTEM_GENERATED_PROFILE ='N'
            WHERE CCM_INST_CODE = prm_instcode                       
            AND CCM_CUST_CODE = v_cust_code ;

            EXCEPTION
                  WHEN OTHERS THEN
                     v_errmsg   := 'While updating system generated profile for custcode-- ' ||                                   
                                   substr(SQLERRM, 1, 100);
                     v_respcode := '21';
                     RAISE exp_reject_txn;
               END;
      END IF;
      --Added by Narsing for MVCSD-4121
      --  IF upper(p_action_in) = 'UPDATEADDRESSOVERRIDEAVS'
      -- THEN
      dbms_output.put_line('Updating adress overrides');
      -- SN added for VMS- 6588 enabling CCPA flag if users request it by bhavani
      IF upper(p_action_in) = 'ENABLECCPA' THEN
      BEGIN
        UPDATE vmscms.cms_cust_mast SET CCM_PRIVACYREGULATION_FLAG='Y'
         WHERE ccm_cust_code = v_cust_code
           AND ccm_inst_code = prm_instcode;
         EXCEPTION
                  WHEN OTHERS THEN
                     v_errmsg   := 'While enabling CCPA as True for custcode-- ' || v_cust_code||'-'||                                  
                                   substr(SQLERRM, 1, 100);
                     v_respcode := '21';
                     RAISE exp_reject_txn;
        END;
      END IF;
       -- EN added for VMS- 6588 enabling CCPA flag if users request it by bhavani
      BEGIN
         BEGIN
            SELECT ccm_addrverify_flag,
                   ccm_cust_id,
                   decode(v_encrypt_enable,'Y',fn_dmaps_main(ccm_first_name),ccm_first_name)  || ' ' || decode(v_encrypt_enable,'Y',fn_dmaps_main(ccm_last_name),ccm_last_name)
              INTO v_addr_verif_flag, v_cust_id, v_cust_name --Added for JH-1961
              FROM vmscms.cms_cust_mast
             WHERE ccm_cust_code = v_cust_code
               AND ccm_inst_code = prm_instcode;

         EXCEPTION
            WHEN no_data_found THEN
               v_errmsg   := 'No Record found for Address verification flag reset';
               v_respcode := '21';
               RAISE exp_reject_txn;
            WHEN OTHERS THEN
               v_errmsg   := 'No Record found for Address verification flag reset ' ||
                             substr(SQLERRM, 1, 100);
               v_respcode := '21';
               RAISE exp_reject_txn;
         END;
         IF v_addr_verif_flag = 1
         THEN
            UPDATE vmscms.cms_cust_mast
               SET ccm_addrverify_flag = 2,
                   ccm_addverify_date  = SYSDATE,
                   ccm_avfset_channel  = '03', --Mantis:14101 Added by Narsing I
                   ccm_avfset_txncode  = '43' --Mantis:14101 Added by Narsing I
             WHERE ccm_inst_code = prm_instcode
               AND ccm_cust_code = v_cust_code;

            v_cnt := SQL%ROWCOUNT;

            IF v_cnt = 0
            THEN
               prm_resp_code := '99';
               prm_resp_msg  := 'Error while reseting Address verification flag';
               RAISE exp_reject_txn;

            END IF;

            BEGIN
               SELECT nvl((MAX(ccd_call_seq)), 0) + 1
                 INTO v_addrcallseq
                 FROM vmscms.cms_calllog_details
                WHERE ccd_inst_code = prm_instcode
                  AND ccd_call_id = prm_call_id
                  AND ccd_pan_code = v_hash_pan;
            EXCEPTION
               WHEN no_data_found THEN
                  v_errmsg   := 'Error while fetching call seq ID';
                  v_respcode := '21';
                  RAISE exp_reject_txn;
               WHEN OTHERS THEN
                  v_errmsg   := 'Error while fetching call seq ID ' ||
                                substr(SQLERRM, 1, 100);
                  v_respcode := '21';
                  RAISE exp_reject_txn;
            END;

            INSERT INTO vmscms.cms_calllog_details
               (ccd_inst_code,
                ccd_call_id,
                ccd_pan_code,
                ccd_call_seq,
                ccd_devl_chnl,
                ccd_txn_code,
                ccd_tran_date,
                ccd_tran_time,
                ccd_comments,
                ccd_ins_user,
                ccd_ins_date,
                ccd_lupd_user,
                ccd_lupd_date,
                ccd_acct_no,
                ccd_rrn)
            VALUES
               (prm_instcode,
                prm_call_id,
                v_hash_pan,
                v_addrcallseq,
                prm_delivery_channel,
                '43',
                prm_trandate,
                prm_trantime,
                'Address verification flag reset through profile update',
                prm_ins_user,
                SYSDATE,
                prm_ins_user,
                SYSDATE,
                prm_acct_no,
                prm_rrn);

            v_cnt := SQL%ROWCOUNT;
            IF v_cnt = 0
            THEN
               prm_resp_code := '99';
               prm_resp_msg  := 'Error while inserting call seq ID';
               RAISE exp_reject_txn;
            END IF;

            BEGIN
               SELECT ctm_tran_desc
                 INTO v_trans_desc
                 FROM vmscms.cms_transaction_mast
                WHERE ctm_inst_code = prm_instcode
                  AND ctm_tran_code = '43'
                  AND ctm_delivery_channel = prm_delivery_channel;

            EXCEPTION
               WHEN no_data_found THEN
                  v_errmsg   := 'Error while fetching transaction description';
                  v_respcode := '21';
                  RAISE exp_reject_txn;
               WHEN OTHERS THEN
                  v_errmsg   := 'Error while fetching transaction description ' ||
                                substr(SQLERRM, 1, 100);
                  v_respcode := '21';
                  RAISE exp_reject_txn;
            END;

            BEGIN
               SELECT lpad(seq_auth_rrn.nextval, 12, '0')
                 INTO addr_rrn
                 FROM dual;

            EXCEPTION
               WHEN no_data_found THEN
                  v_errmsg   := 'Error while selecting rrn for address verification flag';
                  v_respcode := '21';
                  RAISE exp_reject_txn;
               WHEN OTHERS THEN
                  v_errmsg   := 'Error while selecting rrn for address verification flag ' ||
                                substr(SQLERRM, 1, 100);
                  v_respcode := '21';
                  RAISE exp_reject_txn;
            END;

            INSERT INTO vmscms.transactionlog
               (msgtype,
                rrn,
                delivery_channel,
                date_time,
                txn_code,
                txn_type,
                txn_mode,
                txn_status,
                business_date,
                business_time,
                customer_card_no,
                total_amount,
                currencycode,
                productid,
                categoryid,
                auth_id,
                trans_desc,
                amount,
                instcode,
                customer_card_no_encr,
                proxy_number,
                reversal_code,
                acct_balance,
                ledger_balance,
                customer_acct_no,
                add_ins_user,
                add_lupd_user,
                ipaddress,
                error_msg,
                response_code,
                response_id,
                add_ins_date,
                cr_dr_flag)
            VALUES
               (prm_msg_type,
                addr_rrn,
                prm_delivery_channel,
                to_date(prm_trandate || ' ' || prm_trantime,
                        'yyyymmdd hh24miss'),
                '43',
                'N',
                prm_txn_mode,
                'C',
                prm_trandate,
                prm_trantime,
                v_hash_pan,
                TRIM(to_char(0, '99999999999999990.99')),
                prm_currcode,
                v_prod_code,
                v_prod_cattype,
                v_auth_id,
                v_trans_desc,
                TRIM(to_char(0, '99999999999999990.99')),
                prm_instcode,
                v_encr_pan,
                v_proxynumber,
                prm_rvsl_code,
                v_acct_balance,
                v_ledger_balance,
                prm_acct_no,
                prm_ins_user,
                prm_ins_user,
                prm_ipaddress,
                'OK',
                '00',
                '1',
                SYSDATE,
                'NA');

            v_cnt := SQL%ROWCOUNT;

            IF v_cnt = 0
            THEN
               prm_resp_code := '99';
               prm_resp_msg  := 'Error while inserting into transactionlog for address verification flag reset';
               RAISE exp_reject_txn;

            END IF;
            prm_resp_code := '00';
            prm_resp_msg  := 'Address verification flag Updated Successfully';
         END IF;
      EXCEPTION
         WHEN exp_reject_txn THEN
            RAISE;
         WHEN OTHERS THEN
            v_errmsg   := 'Error while Reseting address verification flag ' ||
                          substr(SQLERRM, 1, 100);
            v_respcode := '99';
            RAISE exp_reject_txn;

      END;

      --End Narsing for MVCSD-4121
      --Sn Added for JH-1961

      BEGIN
         SELECT COUNT(*)
           INTO v_cardstat_cnt
           FROM vmscms.cms_cardissuance_status
          WHERE ccs_inst_code = prm_instcode
            AND ccs_pan_code = v_hash_pan
            AND ccs_card_status = '17';

      END;
      dbms_output.put_line('v_cardstat_cnt' || v_cardstat_cnt);
      BEGIN
         SELECT COUNT(*)
           INTO v_pending_cnt
           FROM vmscms.cms_avq_status
          WHERE cas_inst_code = prm_instcode
            AND cas_cust_id = v_cust_id
            AND cas_pan_code = v_hash_pan
            AND cas_avq_flag = 'P';
      END;
      dbms_output.put_line('v_pending_cnt' || v_pending_cnt);

      BEGIN
         SELECT gsm_switch_state_code
           INTO v_state_code
           FROM vmscms.gen_state_mast
          WHERE gsm_inst_code = prm_instcode
            AND gsm_cntry_code = prm_mailing_country
            AND gsm_state_code = prm_mailing_state;
      EXCEPTION
         WHEN no_data_found THEN
            v_errmsg   := 'Invalid Data for Mailing Address State';
            v_respcode := '21';
         WHEN OTHERS THEN
            v_respcode := '21';
            v_errmsg   := 'Error while selecting state detail-' ||
                          substr(SQLERRM, 1, 200);
      END;

      BEGIN
         IF (v_cardstat_cnt > 0)
         THEN
            IF (v_pending_cnt > 0)
            THEN
               UPDATE vmscms.cms_avq_status
                  SET cas_addr_one = decode(prm_mailing_addr1,
                                            NULL,
                                            cas_addr_one,
                                            v_encr_addr_lineone),
                      --Jira Issue cfip: 173 starts
                      /*cas_addr_two    = decode(prm_mailing_addr2,
                      NULL,
                      cas_addr_two,
                      prm_mailing_addr2),*/
                      cas_addr_two = v_encr_addr_linetwo,
                      --Jira Issue cfip: 173 ends
                      cas_city_name   = decode(prm_mailing_city,
                                               NULL,
                                               cas_city_name,
                                               v_encr_city_name),
                      cas_state_name  = decode(v_state_code,
                                               NULL,
                                               cas_state_name,
                                               v_state_code),
                      cas_postal_code = decode(prm_mailing_zip,
                                               NULL,
                                               cas_postal_code,
                                               v_encr_zip),
                      cas_lupd_user   = decode(prm_ins_user,
                                               NULL,
                                               cas_lupd_user,
                                               prm_ins_user),
                      cas_lupd_date   = SYSDATE
                WHERE cas_inst_code = prm_instcode
                  AND cas_cust_id = v_cust_id
                  AND cas_pan_code = v_hash_pan
                  AND cas_avq_flag = 'P';
            ELSE
               INSERT INTO vmscms.cms_avq_status
                  (cas_inst_code,
                   cas_cust_id,
                   cas_pan_code,
                   cas_pan_encr,
                   cas_cust_name,
                   cas_addr_one,
                   cas_addr_two,
                   cas_city_name,
                   cas_state_name,
                   cas_postal_code,
                   cas_avq_flag,
                   cas_avqstat_id,
                   cas_ins_user,
                   cas_ins_date)
               VALUES
                  (prm_instcode,
                   v_cust_id,
                   v_hash_pan,
                   v_encr_pan,
                   v_encr_full_name,
                   v_encr_addr_lineone,
                   v_encr_addr_linetwo,
                   v_encr_city_name,
                   v_state_code,
                   v_encr_zip,
                   'P',
                   avq_seq.nextval,
                   prm_ins_user,
                   SYSDATE);
            END IF;
         END IF;
      EXCEPTION

         WHEN OTHERS THEN
            v_errmsg   := 'Problem while updating CMS_AVQ_STATUS for custcode ' ||
                          v_cust_code || substr(SQLERRM, 1, 100);
            v_respcode := '21';
      END;
      --En Added for JH-1961
      --END IF; --Commneted as this flag is not required for fsapi dev
      -- END IF;
      BEGIN

         INSERT INTO vmscms.cms_pan_spprt
            (cps_inst_code,
             cps_pan_code,
             cps_mbr_numb,
             cps_prod_catg,
             cps_spprt_key,
             cps_spprt_rsncode,
             cps_func_remark,
             cps_ins_user,
             cps_ins_date,
             cps_lupd_user,
             cps_lupd_date,
             cps_cmd_mode,
             cps_pan_code_encr)
         VALUES
            (prm_instcode,
             v_hash_pan,
             v_mbrnumb,
             v_prodcatg,
             decode(prm_reason_code, NULL, 'PROFUPD', 'PROFILE'),
             decode(prm_reason_code, NULL, 63, prm_reason_code),
             prm_remark,
             prm_ins_user,
             SYSDATE,
             prm_ins_user,
             SYSDATE,
             0,
             v_encr_pan);

         v_cnt := SQL%ROWCOUNT;

         IF v_cnt = 0
         THEN
            v_respcode := '21';
            v_errmsg   := 'No records inserted in pan support';
            RAISE exp_reject_txn;
         END IF;
      EXCEPTION
         WHEN exp_reject_txn THEN
            RAISE;
         WHEN OTHERS THEN
            v_errmsg   := 'Error while inserting in panspprt ' ||
                          substr(SQLERRM, 1, 100);
            v_respcode := '21';
            RAISE exp_reject_txn;
      END;

      --Sn get record for successful transaction
      v_respcode := '1';

      SELECT COUNT(*)
        INTO v_mailaddr_cnt1
        FROM vmscms.cms_addr_mast
       WHERE cam_inst_code = prm_instcode
         AND cam_cust_code = v_cust_code
         AND cam_addr_flag = 'O';

      SELECT COUNT(*)
        INTO v_phyaddr_cnt1
        FROM vmscms.cms_addr_mast
       WHERE cam_inst_code = prm_instcode
         AND cam_cust_code = v_cust_code
         AND cam_addr_flag = 'P';

      /*  call log info   start  */
      --      IF v_mailaddr_cnt1 > 0
      --      THEN
      --         BEGIN
      --            v_addr_flag := 'O';
      --
      --            EXECUTE IMMEDIATE v_colm_qury
      --               INTO v_new_value_o
      --               USING v_cust_code, v_addr_flag;
      --         EXCEPTION
      --            WHEN OTHERS THEN
      --               v_errmsg   := 'Error while selecting new values   for mailing address ' ||
      --                             substr(SQLERRM, 1, 100);
      --               v_respcode := '21';
      --               RAISE exp_reject_txn;
      --         END;
      --      ELSE
      --         v_new_value_o := 'Mailing Address not available ';
      --      END IF;

      --      IF v_phyaddr_cnt1 > 0
      --      THEN
      --         BEGIN
      --            v_addr_flag := 'P';
      --
      --            EXECUTE IMMEDIATE v_colm_qury
      --               INTO v_new_value_p
      --               USING v_cust_code, v_addr_flag;
      --         EXCEPTION
      --            WHEN OTHERS THEN
      --               v_errmsg   := 'Error while selecting new values  for physical address ' ||
      --                             substr(SQLERRM, 1, 100);
      --               v_respcode := '21';
      --               RAISE exp_reject_txn;
      --         END;
      --      ELSE
      --         v_new_value_p := 'Mailing Physical not available ';
      --      END IF;
      --
      --      v_new_value := 'O-|' || v_new_value_o || '|' || 'P-|' ||
      --                     v_new_value_p;

      --      BEGIN
      --         UPDATE vmscms.cms_calllog_details
      --            SET ccd_new_value = v_new_value
      --          WHERE ccd_inst_code = ccd_inst_code
      --            AND ccd_call_id = prm_call_id
      --            AND ccd_pan_code = v_hash_pan
      --            AND ccd_call_seq = v_call_seq;
      --
      --         IF SQL%ROWCOUNT = 0
      --         THEN
      --            v_errmsg   := 'call log details is not updated for ' ||
      --                          prm_call_id;
      --            v_respcode := '16';
      --            RAISE exp_reject_txn;
      --         END IF;
      --      EXCEPTION
      --         WHEN OTHERS THEN
      --            v_errmsg   := 'Error while updating call log details   ' ||
      --                          substr(SQLERRM, 1, 100);
      --            v_respcode := '21';
      --            RAISE exp_reject_txn;
      --      END;

      /*  call log info   end  */
      BEGIN
         SELECT cms_iso_respcde
           INTO prm_resp_code
           FROM vmscms.cms_response_mast
          WHERE cms_inst_code = prm_instcode
            AND cms_delivery_channel = prm_delivery_channel
            AND cms_response_id = v_respcode;

         dbms_output.put_line(v_respcode);
         prm_resp_msg := v_errmsg;
      EXCEPTION
         WHEN OTHERS THEN
            prm_resp_msg  := 'Problem while selecting data from response master1 ' ||
                             v_respcode || substr(SQLERRM, 1, 100);
            prm_resp_code := '89';
            ROLLBACK;
            RETURN;
      END;

      --En get record for successful transaction

      BEGIN
         UPDATE vmscms.transactionlog
            SET remark        = prm_remark,
                ipaddress     = prm_ipaddress, --added by amit on 06-Oct-2012
                add_ins_user  = prm_ins_user, --added by amit on 06-Oct-2012
                add_lupd_user = prm_ins_user, --added by amit on 06-Oct-2012
                reason        = v_reason -- added on 06NOV2012
          WHERE instcode = prm_instcode
            AND customer_card_no = v_hash_pan
            AND rrn = prm_rrn
            AND business_date = prm_trandate
            AND business_time = prm_trantime
            AND delivery_channel = prm_delivery_channel
            AND txn_code = prm_txn_code;

         IF SQL%ROWCOUNT = 0
         THEN
            v_respcode := '21';
            v_errmsg   := 'Txn not updated in transactiolog for remark';
            RAISE exp_reject_txn;
         END IF;
      EXCEPTION
         WHEN exp_reject_txn THEN
            RAISE;
         WHEN OTHERS THEN
            v_respcode := '21';
            v_errmsg   := 'Error while updating into transactiolog ' ||
                          substr(SQLERRM, 1, 200);
            RAISE exp_reject_txn;
      END;
   EXCEPTION
      WHEN exp_reject_txn THEN
         ROLLBACK;

         BEGIN

            SELECT cms_iso_respcde
              INTO prm_resp_code
              FROM vmscms.cms_response_mast
             WHERE cms_inst_code = prm_instcode
               AND cms_delivery_channel = prm_delivery_channel
               AND cms_response_id = v_respcode;

            prm_resp_msg := v_errmsg;

         EXCEPTION
            WHEN OTHERS THEN
               prm_resp_msg  := 'Problem while selecting data from response master2 ' ||
                                v_respcode || substr(SQLERRM, 1, 100);
               prm_resp_code := '89';
               RETURN;
         END;

         BEGIN

            INSERT INTO vmscms.cms_transaction_log_dtl
               (ctd_delivery_channel,
                ctd_txn_code,
                ctd_txn_type,
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
                ctd_customer_card_no_encr,
                ctd_msg_type,
                ctd_cust_acct_number,
                ctd_inst_code)
            VALUES
               (prm_delivery_channel,
                prm_txn_code,
                NULL,
                prm_txn_mode,
                prm_trandate,
                prm_trantime,
                v_hash_pan,
                NULL,
                prm_currcode,
                NULL,
                NULL,
                NULL,
                NULL,
                NULL,
                NULL,
                NULL,
                'E',
                v_errmsg,
                prm_rrn,
                prm_stan,
                v_encr_pan,
                prm_msg_type,
                prm_acct_no,
                prm_instcode);

            v_cnt := SQL%ROWCOUNT;

            IF v_cnt = 0
            THEN
               prm_resp_code := '89';
               prm_resp_msg  := 'unsucessful records inserted in transactionlog detail 1';
               RETURN;
            END IF;

            --prm_resp_msg := v_errmsg;

         EXCEPTION
            WHEN OTHERS THEN
               prm_resp_code := '99';
               prm_resp_msg  := 'Problem while inserting data into transaction log1  dtl' ||
                                substr(SQLERRM, 1, 300);
               ROLLBACK;
               RETURN;
         END;

         --Sn create a entry in txn log
         BEGIN
            INSERT INTO vmscms.transactionlog
               (msgtype,
                rrn,
                delivery_channel,
                date_time,
                txn_code,
                txn_type,
                txn_mode,
                txn_status,
                response_code,
                business_date,
                business_time,
                customer_card_no,
                total_amount,
                currencycode,
                productid,
                categoryid,
                auth_id,
                trans_desc,
                amount,
                system_trace_audit_no,
                instcode,
                cr_dr_flag,
                customer_card_no_encr,
                proxy_number,
                reversal_code,
                customer_acct_no,
                acct_balance,
                ledger_balance,
                response_id,
                error_msg,
                add_ins_user, --added by amit on 06-Oct-2012
                add_lupd_user, --added by amit on 06-Oct-2012
                ipaddress, --added by amit on 06-Oct-2012
                remark, --added by amit on 06-Oct-2012
                reason -- added on 06NOV2012
                )
            VALUES
               (prm_msg_type,
                prm_rrn,
                prm_delivery_channel,
                to_date(prm_trandate || ' ' || prm_trantime,
                        'yyyymmdd hh24miss'),
                prm_txn_code,
                NULL,
                prm_txn_mode,
                decode(prm_resp_code, '00', 'C', 'F'),
                prm_resp_code,
                prm_trandate,
                prm_trantime,
                v_hash_pan,
                TRIM(to_char(0, '99999999999999990.99')),
                prm_currcode,
                v_prod_code,
                v_prod_cattype,
                v_auth_id,
                prm_remark,
                TRIM(to_char(0, '999999999999999990.99')),
                prm_stan,
                prm_instcode,
                'NA',
                v_encr_pan,
                v_proxynumber,
                prm_rvsl_code,
                prm_acct_no,
                v_acct_balance,
                v_ledger_balance,
                v_respcode,
                prm_resp_msg,
                prm_ins_user, --added by amit on 06-Oct-2012
                prm_ins_user, --added by amit on 06-Oct-2012
                prm_ipaddress, --added by amit on 06-Oct-2012
                prm_remark, --added by amit on 06-Oct-2012
                v_reason -- added on 06NOV2012
                );

            v_cnt := SQL%ROWCOUNT;

            IF v_cnt = 0
            THEN
               prm_resp_code := '99';
               prm_resp_msg  := 'unsucessful records not inserted in transactionlog 1';
               RETURN;
            END IF;

         EXCEPTION
            WHEN OTHERS THEN
               ROLLBACK;
               prm_resp_code := '99';
               prm_resp_msg  := 'Problem while inserting data into transaction log3 ' ||prm_trandate||'-'||prm_trantime||
                                substr(SQLERRM, 1, 300);
               RETURN;
         END;
         --En create a entry in txn log
      WHEN OTHERS THEN
         ROLLBACK;

         BEGIN
            SELECT cms_iso_respcde
              INTO prm_resp_code
              FROM vmscms.cms_response_mast
             WHERE cms_inst_code = prm_instcode
               AND cms_delivery_channel = prm_delivery_channel
               AND cms_response_id = '21';

            prm_resp_msg := 'Error from others exception ' ||
                            substr(SQLERRM, 1, 100);
         EXCEPTION
            WHEN OTHERS THEN
               prm_resp_msg  := 'Problem while selecting data from response master3 ' ||
                                v_respcode || substr(SQLERRM, 1, 100);
               prm_resp_code := '89';
               RETURN;
         END;

         BEGIN
            INSERT INTO vmscms.cms_transaction_log_dtl
               (ctd_delivery_channel,
                ctd_txn_code,
                ctd_txn_type,
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
                ctd_customer_card_no_encr,
                ctd_msg_type,
                ctd_cust_acct_number,
                ctd_inst_code)
            VALUES
               (prm_delivery_channel,
                prm_txn_code,
                NULL,
                prm_txn_mode,
                prm_trandate,
                prm_trantime,
                v_hash_pan,
                NULL,
                prm_currcode,
                NULL,
                NULL,
                NULL,
                NULL,
                NULL,
                NULL,
                NULL,
                'E',
                v_errmsg,
                prm_rrn,
                prm_stan,
                v_encr_pan,
                prm_msg_type,
                prm_acct_no,
                prm_instcode);

            v_cnt := SQL%ROWCOUNT;

            IF v_cnt = 0
            THEN
               prm_resp_code := '99';
               prm_resp_msg  := 'unsucessful records not inserted in transactionlog detail 2';
               RETURN;
            END IF;

            --prm_resp_msg := v_errmsg;
         EXCEPTION
            WHEN OTHERS THEN
               prm_resp_code := '99';
               prm_resp_msg  := 'Problem while inserting data into transaction log dtl2' ||
                                substr(SQLERRM, 1, 300);
               ROLLBACK;
               RETURN;
         END;

         --Sn create a entry in txn log
         BEGIN
            INSERT INTO vmscms.transactionlog
               (msgtype,
                rrn,
                delivery_channel,
                date_time,
                txn_code,
                txn_type,
                txn_mode,
                txn_status,
                response_code,
                business_date,
                business_time,
                customer_card_no,
                total_amount,
                currencycode,
                productid,
                categoryid,
                auth_id,
                trans_desc,
                amount,
                system_trace_audit_no,
                instcode,
                cr_dr_flag,
                customer_card_no_encr,
                proxy_number,
                reversal_code,
                customer_acct_no,
                acct_balance,
                ledger_balance,
                response_id,
                error_msg,
                add_ins_user, --added by amit on 06-Oct-2012
                add_lupd_user, --added by amit on 06-Oct-2012
                ipaddress, --added by amit on 06-Oct-2012
                remark, --added by amit on 06-Oct-2012
                reason -- added on 06NOV2012
                )
            VALUES
               (prm_msg_type,
                prm_rrn,
                prm_delivery_channel,
                to_date(prm_trandate || ' ' || prm_trantime,
                        'yyyymmdd hh24miss'),
                prm_txn_code,
                NULL,
                prm_txn_mode,
                decode(prm_resp_code, '00', 'C', 'F'),
                prm_resp_code,
                prm_trandate,
                prm_trantime,
                v_hash_pan,
                TRIM(to_char(0, '99999999999999990.99')),
                prm_currcode,
                v_prod_code,
                v_prod_cattype,
                v_auth_id,
                prm_remark,
                TRIM(to_char(0, '999999999999999990.99')),
                prm_stan,
                prm_instcode,
                'NA',
                v_encr_pan,
                v_proxynumber,
                prm_rvsl_code,
                prm_acct_no,
                v_acct_balance,
                v_ledger_balance,
                v_respcode,
                prm_resp_msg,
                prm_ins_user, --added by amit on 06-Oct-2012
                prm_ins_user, --added by amit on 06-Oct-2012
                prm_ipaddress, --added by amit on 06-Oct-2012
                prm_remark, --added by amit on 06-Oct-2012
                v_reason --Added on 06NOV2012
                );

            v_cnt := SQL%ROWCOUNT;

            IF v_cnt = 0
            THEN

               prm_resp_code := '99';
               prm_resp_msg  := 'unsucessful record not inserted in transactionlog 2';
               RETURN;

            END IF;

         EXCEPTION
            WHEN OTHERS THEN
               ROLLBACK;
               prm_resp_code := '99';
               prm_resp_msg  := 'Problem while inserting data into transaction log4 ' ||
                                substr(SQLERRM, 1, 300);
               RETURN;
         END;

   END;
END;
/
SHOW ERROR;