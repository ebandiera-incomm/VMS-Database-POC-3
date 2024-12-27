CREATE OR REPLACE PROCEDURE VMSCMS.sp_singlecard_renewal (
   prm_instcode      IN       NUMBER,
   prm_old_pancode   IN       VARCHAR2,
   prm_txn_code      IN       VARCHAR2,
   prm_lupduser      IN       NUMBER,
   prm_newpan        OUT      VARCHAR2,
   prm_errmsg        OUT      VARCHAR2
)
AS
/**************************************************************************
     * Created Date     : 26_Feb_2014
     * Created By       : Kaleeswaran P
     * Purpose          : MVCSD 4121 :Single Card Renewal
     * Reviewer         : Dhiraj
     * Reviewed Date    : 26_Feb_2014
     * Build Number     : RI0027.2_B0002


     * Modified Date    : 25_Mar_2014
     * Modified By      : Amudhan
     * Purpose          : Review changes for MVCSD-4121 and FWR-47
     * Reviewer         : Pankaj S.
     * Reviewed Date    : 01-April-2014
     * Build Number     : RI0027.2_B0003

     * Modified Date    : 11_APR_2014
     * Modified By      : RAMESH
     * Purpose          : REVIEW CHANGES MODIFIED FOR TO UPDATE NULL FOR AFTER CARD RENEWAL
     * Reviewer         : spankaj
     * Reviewed Date    : 15-April-2014
     * Build Number     : RI0027.2_B0005
     
     * Modified Date    : 08_May_2015
     * Modified By      : RAMESH
     * Purpose          : PinMigration chnages
     * Reviewer         : spankaj
     * Reviewed Date    : 08_May_2015
     * Build Number     : 3.0.3

     * Modified by      : Ramesh A.
     * Modified for     : FWR-59 : SMA and Email Alerts
     * Modified Date    : 13-Aug-2015
     * Reviewer         : Pankaj S
     * Build Number     : VMSGPRHOST_3.1   
     
     * Modified by      : Siva Kumar M
     * Modified for     : Mantis id 0016199
     * Modified Date    : 07-Oct-2015
     * Reviewer         : Saravana kumar 
     * Build Number     : VMSGPRHOST_3.2 
     
    * Modified by          : Pankaj S.
    * Modified Date        : 16-May-17
    * Modified For         : FSS-5135 -Changes in Card replacement / renewal logic
    * Reviewer             : Saravanan
    * Build Number         : VMSGPRHOST_17.05      
 /**************************************************************************/
   v_old_product             cms_appl_pan.cap_prod_code%TYPE;
   v_old_cardtype            cms_appl_pan.cap_card_type%TYPE;
   v_old_prodcatg            cms_appl_pan.cap_prod_catg%TYPE;
   v_new_product             cms_appl_pan.cap_prod_code%TYPE;
   v_new_cardtype            cms_appl_pan.cap_card_type%TYPE;
   v_cust_code               cms_appl_pan.cap_cust_code%TYPE;
   v_disp_name               cms_appl_pan.cap_disp_name%TYPE;
   new_product_code          cms_appl_pan.cap_prod_code%TYPE;
   new_cardtype              cms_appl_pan.cap_card_type%TYPE;
   v_errmsg                  VARCHAR2 (300);
   v_expiry_date             DATE;
   v_check_cardtype          NUMBER (1);
   v_cpm_catg_code           cms_prod_mast.cpm_catg_code%TYPE;
   v_prod_prefix             cms_prod_cattype.cpc_prod_prefix%TYPE;
   v_cardtype_profile_code   cms_prod_cattype.cpc_profile_code%TYPE;
   v_tran_code               cms_func_mast.cfm_txn_code%TYPE;
   v_tran_mode               cms_func_mast.cfm_txn_mode%TYPE;
   v_delv_chnl               cms_func_mast.cfm_delivery_channel%TYPE;
   v_profile_code            cms_prod_cattype.cpc_profile_code%TYPE;
   v_expryparam              cms_bin_param.cbp_param_value%TYPE;
   v_validity_period         cms_bin_param.cbp_param_value%TYPE;
   v_hash_pan                cms_appl_pan.cap_pan_code%TYPE;
   v_encr_pan                cms_appl_pan.cap_pan_code_encr%TYPE;
   v_hash_new_pan            cms_appl_pan.cap_pan_code%TYPE;
   v_encr_new_pan            cms_appl_pan.cap_pan_code_encr%TYPE;
   v_rrn                     VARCHAR2 (20);
   v_inst_code               cms_appl_pan.cap_inst_code%TYPE;
   v_prod_code               cms_appl_pan.cap_prod_code%TYPE;
   v_appl_bran               cms_appl_pan.cap_appl_bran%TYPE;
   v_card_type               cms_appl_pan.cap_card_type%TYPE;
   v_cust_catg               cms_appl_pan.cap_cust_catg%TYPE;
   v_mask_pan                cms_appl_pan.cap_mask_pan%TYPE;
   exp_reject_record         EXCEPTION;
   v_old_expry_date          DATE;
   v_hist_pan_count          NUMBER;
   v_cap_pin_off             cms_appl_pan.cap_pin_off%TYPE;
   v_acct_no                 cms_appl_pan.cap_acct_no%TYPE;
   v_card_stat               cms_appl_pan.cap_card_stat%TYPE;
   v_txn_desc                transactionlog.trans_desc%TYPE;
   v_acct_bal                cms_acct_mast.cam_acct_bal%TYPE;
   v_ledger_bal              cms_acct_mast.cam_ledger_bal%TYPE;
   v_addressverify_flag      NUMBER;
   old_prouct_count          NUMBER;
   v_acct_id                 cms_acct_mast.cam_acct_id%TYPE;
   v_acct_type               cms_acct_mast.cam_type_code%TYPE;
   v_appl_code               cms_appl_pan.cap_appl_code%TYPE;
   v_cardrenewal_check       NUMBER;
   v_cnt                     NUMBER;
   v_repl_period         cms_prod_cattype.cpc_repl_period%TYPE;
   v_repl_option                 cms_prod_cattype.cpc_renew_replace_option%TYPE;
   
   v_Retperiod  date;  --Added for VMS-5739/FSP-991
v_Retdate  date; --Added for VMS-5739/FSP-991
BEGIN
   --<< MAIN BEGIN >>
   v_errmsg := 'OK';
   prm_errmsg := 'OK';

   BEGIN
      v_hash_pan := gethash (prm_old_pancode);
   EXCEPTION
      WHEN OTHERS
      THEN
         v_errmsg :=
               'Error while converting old card number to hash pan code '
            || SUBSTR (SQLERRM, 1, 200);
         RAISE exp_reject_record;
   END;

   --EN CREATE HASH PAN

   --SN create encr pan
   BEGIN
      v_encr_pan := fn_emaps_main (prm_old_pancode);
   EXCEPTION
      WHEN OTHERS
      THEN
         v_errmsg :=
               'Error while converting old card number to encrypted pan code '
            || SUBSTR (SQLERRM, 1, 200);
         RAISE exp_reject_record;
   END;

   --EN create encr pan
   BEGIN
      SELECT    TO_CHAR (SYSTIMESTAMP, 'yymmddHH24MISS')
             || seq_passivestatupd_rrn.NEXTVAL
        INTO v_rrn
        FROM DUAL;
   EXCEPTION
      WHEN OTHERS
      THEN
         v_errmsg := 'Error while getting RRN ' || SUBSTR (SQLERRM, 1, 200);
         RAISE exp_reject_record;
   END;

   --To find product catg
   BEGIN
      SELECT cap_prod_catg, cap_prod_code, cap_card_type, cap_cust_code,
             cap_disp_name, cap_expry_date, cap_appl_code, cap_acct_id,
             cap_acct_no, cap_card_stat, cap_mask_pan
        INTO v_old_prodcatg, v_old_product, v_old_cardtype, v_cust_code,
             v_disp_name, v_old_expry_date, v_appl_code, v_acct_id,
             v_acct_no, v_card_stat, v_mask_pan
        FROM cms_appl_pan
       WHERE cap_pan_code = v_hash_pan AND cap_inst_code = prm_instcode;
   EXCEPTION
      WHEN NO_DATA_FOUND
      THEN
         v_errmsg := ' Card details not found';
         RAISE exp_reject_record;
      WHEN OTHERS
      THEN
         v_errmsg :=
               'Error while selecting Product details '
            || SUBSTR (SQLERRM, 1, 200);
         RAISE exp_reject_record;
   END;

   BEGIN
      SELECT cam_acct_bal, cam_ledger_bal, cam_type_code
        INTO v_acct_bal, v_ledger_bal, v_acct_type
        FROM cms_acct_mast
       WHERE cam_inst_code = prm_instcode AND cam_acct_id = v_acct_id;
   EXCEPTION
      WHEN OTHERS
      THEN
         v_errmsg :=
               'Error while selecting balance details '
            || SUBSTR (SQLERRM, 1, 300);
         RAISE exp_reject_record;
   END;

   BEGIN
      SELECT COUNT (*)
        INTO v_cardrenewal_check
        FROM cms_cardrenewal_hist
       WHERE cch_pan_code = v_hash_pan
         AND TRUNC (cch_expry_date) = TRUNC (v_old_expry_date)
         AND cch_inst_code = prm_instcode;

      IF v_cardrenewal_check > 0
      THEN
         v_errmsg := 'Card has been Renewed already : ' || v_mask_pan;
         RAISE exp_reject_record;
      END IF;
   EXCEPTION
      WHEN exp_reject_record
      THEN
         RAISE;
      WHEN OTHERS
      THEN
         v_errmsg :=
               'Error occured while selecting Card History details '
            || SUBSTR (SQLERRM, 1, 200);
         RAISE exp_reject_record;
   END;
   
    begin
          SELECT  cpc_repl_period, NVL(cpc_renew_replace_option, 'NP'), cpc_profile_code,
                          cpc_renew_replace_prodcode, cpc_renew_replace_cardtype
            INTO v_repl_period, v_repl_option, v_profile_code,
                        new_product_code, new_cardtype
           FROM cms_prod_cattype
           WHERE cpc_prod_code=v_old_product
           AND  cpc_card_type= v_old_cardtype;
    EXCEPTION
      WHEN others THEN
      v_errmsg :='Error occured while selecting replacement period'|| SUBSTR (SQLERRM, 1, 200);
         RAISE exp_reject_record;
    END; 
         BEGIN
		 --Added for VMS-5739/FSP-991
 select (add_months(trunc(sysdate,'MM'),'-'||RETENTION_PERIOD))
       INTO   v_Retperiod 
       FROM DBA_OPERATIONS.ARCHIVE_MGMNT_CTL 
       WHERE  OPERATION_TYPE='ARCHIVE' 
       AND OBJECT_NAME='TRANSACTIONLOG_EBR';
       
       v_Retdate := TO_DATE(SUBSTR(TRIM(v_repl_period), 1, 8), 'yyyymmdd');


IF (v_Retdate>v_Retperiod)
    THEN

                          SELECT count (1)
                                INTO v_cnt
                                FROM vmscms.transactionlog 
                                WHERE   customer_card_no = v_hash_pan
                                AND (  (delivery_channel = '11' AND txn_code IN ('22', '32'))
                                    OR (delivery_channel = '08' AND txn_code IN ('22', '26'))
                                    OR (delivery_channel = '01' AND txn_code IN ('10', '99','12'))
                                    OR (delivery_channel = '02' AND txn_code IN ('12', '14', '16', '18', '20', '22', '25', '28','23','27','35','37','38','39','40','41','42','44','47','50','53','56')))
                                AND response_code = '00'
                                AND add_ins_date BETWEEN sysdate - v_repl_period AND sysdate;
ELSE
							SELECT count (1)
                                INTO v_cnt
                                FROM VMSCMS_HISTORY.TRANSACTIONLOG_HIST --Added for VMS-5733/FSP-991
                                WHERE   customer_card_no = v_hash_pan
                                AND (  (delivery_channel = '11' AND txn_code IN ('22', '32'))
                                    OR (delivery_channel = '08' AND txn_code IN ('22', '26'))
                                    OR (delivery_channel = '01' AND txn_code IN ('10', '99','12'))
                                    OR (delivery_channel = '02' AND txn_code IN ('12', '14', '16', '18', '20', '22', '25', '28','23','27','35','37','38','39','40','41','42','44','47','50','53','56')))
                                AND response_code = '00'
                                AND add_ins_date BETWEEN sysdate - v_repl_period AND sysdate;
END IF;
								
                              
                          IF v_cnt = 0 THEN
                               v_errmsg :='No Successful Financial Transaction found for last '||v_repl_period ||' Days';
                                RAISE exp_reject_record;
                         END IF;
                         EXCEPTION 
                         WHEN exp_reject_record THEN
                            raise;
                         WHEN others THEN
                           v_errmsg :='Error while selecting transactionlog'|| substr (SQLERRM, 1, 200);
                           RAISE exp_reject_record;                  
                      END;

--   BEGIN
--      SELECT cpp_renew_prodcode, cpp_renew_cardtype
--        INTO new_product_code, new_cardtype
--        FROM cms_product_param
--       WHERE cpp_prod_code = v_old_product AND cpp_inst_code = prm_instcode;
--   EXCEPTION
--      WHEN NO_DATA_FOUND
--      THEN
--         new_product_code := NULL;
--         new_cardtype := NULL;
--      WHEN OTHERS
--      THEN
--         v_errmsg :=
--            'Error while selecting Product param '
--            || SUBSTR (SQLERRM, 1, 200);
--         RAISE exp_reject_record;
--   END;

   IF    v_repl_option = 'SP' AND v_card_stat <> '2' 
--   TRIM (new_product_code) IS NULL
--      OR TRIM (new_cardtype) IS NULL
--      OR (    TRIM (v_old_product) = TRIM (new_product_code)
--          AND TRIM (v_old_cardtype) = TRIM (new_cardtype)
--         )
   THEN
--      BEGIN
--         SELECT cpm_profile_code, cpm_catg_code, cpc_prod_prefix,
--                cpc_profile_code
--           INTO v_profile_code, v_cpm_catg_code, v_prod_prefix,
--                v_cardtype_profile_code
--           FROM cms_prod_cattype, cms_prod_mast
--          WHERE cpc_inst_code = prm_instcode
--            AND cpc_inst_code = cpm_inst_code
--            AND cpm_prod_code = cpc_prod_code
--            AND cpc_prod_code = v_old_product
--            AND cpc_card_type = v_old_cardtype;

         IF v_profile_code IS NULL
         THEN
            v_errmsg := 'Profile is not Attached to Product CatType';
            RAISE exp_reject_record;
         END IF;

--         IF v_cardtype_profile_code IS NULL
--         THEN
--            v_errmsg := 'Profile is not attached to Product CatType';
--            RAISE exp_reject_record;
--         END IF;
--      EXCEPTION
--         WHEN NO_DATA_FOUND
--         THEN
--            v_errmsg :=
--                  'Profile code not defined for Product code '
--               || v_prod_code
--               || 'card type '
--               || v_card_type;
--            RAISE exp_reject_record;
--         WHEN exp_reject_record
--         THEN
--            RAISE;
--         WHEN OTHERS
--         THEN
--            v_errmsg :=
--                  'Error while selecting Profile code '
--               || SUBSTR (SQLERRM, 1, 300);
--            RAISE exp_reject_record;
--      END;

      v_prod_code := v_old_product;
      v_card_type := v_old_cardtype;

      BEGIN                                                              --B16
         SELECT cbp_param_value
           INTO v_expryparam
           FROM cms_bin_param
          WHERE cbp_profile_code = v_profile_code
            AND cbp_param_name = 'Validity'
            AND cbp_inst_code = prm_instcode;

         IF v_expryparam IS NULL
         THEN
            v_errmsg :=
                   'EXPRYPARAM not found for Profile code ' || v_profile_code;
            RAISE exp_reject_record;
         END IF;
      EXCEPTION
         WHEN exp_reject_record
         THEN
            RAISE;
         WHEN NO_DATA_FOUND
         THEN
            v_errmsg :=
                'No validity data found either Product/Product type Profile ';
            RAISE exp_reject_record;
         WHEN OTHERS
         THEN
            v_errmsg :=
                  'Error while selecting validity Data '
               || SUBSTR (SQLERRM, 1, 200);
            RAISE exp_reject_record;
      END;

      BEGIN                                                              --B17
         SELECT cbp_param_value
           INTO v_validity_period
           FROM cms_bin_param
          WHERE cbp_profile_code = v_profile_code
            AND cbp_param_name = 'Validity Period'
            AND cbp_inst_code = prm_instcode;

         IF v_validity_period IS NULL
         THEN
            v_errmsg :=
               'VALIDITY_PERIOD not found for Profile code '
               || v_profile_code;
            RAISE exp_reject_record;
         END IF;
      EXCEPTION
         WHEN exp_reject_record
         THEN
            RAISE;
         WHEN NO_DATA_FOUND
         THEN
            v_errmsg := 'Validity period is not defined for Product Profile ';
            RAISE exp_reject_record;
         WHEN OTHERS
         THEN
            v_errmsg :=
                  'Error while selecting Bin Parameter '
               || SUBSTR (SQLERRM, 1, 200);
            RAISE exp_reject_record;
      END;

      --En find validitty period
      IF v_validity_period = 'Hour'
      THEN
         v_expiry_date := SYSDATE + v_expryparam / 24;
      ELSIF v_validity_period = 'Day'
      THEN
         v_expiry_date := SYSDATE + v_expryparam;
      ELSIF v_validity_period = 'Week'
      THEN
         v_expiry_date := SYSDATE + (7 * v_expryparam);
      ELSIF v_validity_period = 'Month'
      THEN
         v_expiry_date := LAST_DAY (ADD_MONTHS (SYSDATE, v_expryparam - 1));
      ELSIF v_validity_period = 'Year'
      THEN
         v_expiry_date :=
                      LAST_DAY (ADD_MONTHS (SYSDATE, (12 * v_expryparam) - 1));
      END IF;

      ---Expiry Date Updation Block-----
      BEGIN
         UPDATE cms_appl_pan
            SET cap_replace_exprydt = v_expiry_date
          WHERE cap_inst_code = prm_instcode AND cap_pan_code = v_hash_pan;

         IF SQL%ROWCOUNT <> 1
         THEN
            v_errmsg := 'Error while updating appl_pan ';
            RAISE exp_reject_record;
         END IF;
      EXCEPTION
         WHEN exp_reject_record
         THEN
            RAISE;
         WHEN OTHERS
         THEN
            v_errmsg :=
               'Error while updating Expiry Date' || SUBSTR (SQLERRM, 1, 200);
            RAISE exp_reject_record;
      END;

      BEGIN
         UPDATE cms_cardissuance_status
            SET ccs_card_status = '20'
          WHERE ccs_inst_code = prm_instcode AND ccs_pan_code = v_hash_pan;

         IF SQL%ROWCOUNT <> 1
         THEN
            v_errmsg := 'Error while updating CMS_CARDISSUANCE_STATUS ';
            RAISE exp_reject_record;
         END IF;
      EXCEPTION
         WHEN exp_reject_record
         THEN
            RAISE;
         WHEN OTHERS
         THEN
            v_errmsg :=
                  'Error while updating Application Card Issuance Status'
               || SUBSTR (SQLERRM, 1, 200);
            RAISE exp_reject_record;
      END;
   ELSE
      --------NEW PRODUCT Block Begings here-------
     IF v_repl_option='NPP' THEN
           v_prod_code := new_product_code;
           v_card_type := new_cardtype;
     END IF;
     
      --Generate New Pan
      BEGIN
         sp_order_reissuepan_cms (prm_instcode,
                                  prm_old_pancode,
                                  v_prod_code, --new_product_code,
                                  v_card_type, --new_cardtype,
                                  v_disp_name,
                                  prm_instcode,
                                  prm_newpan,
                                  v_errmsg
                                 );

         IF v_errmsg != 'OK'
         THEN
            v_errmsg := 'From Renewal pan generation process-- ' || v_errmsg;
            RAISE exp_reject_record;
         END IF;
      EXCEPTION
         WHEN exp_reject_record
         THEN
            RAISE;
         WHEN OTHERS
         THEN
            v_errmsg :=
                  'From reissue pan generation process-- '
               || SUBSTR (SQLERRM, 1, 200);
            RAISE exp_reject_record;
      END;

      BEGIN
         v_hash_new_pan := gethash (prm_newpan);
      EXCEPTION
         WHEN OTHERS
         THEN
            v_errmsg :=
                  'Error while converting new card number to hash pan code '
               || SUBSTR (SQLERRM, 1, 200);
            RAISE exp_reject_record;
      END;

      --EN CREATE HASH PAN

      --SN create encr pan
      BEGIN
         v_encr_new_pan := fn_emaps_main (prm_newpan);
      EXCEPTION
         WHEN OTHERS
         THEN
            v_errmsg :=
                  'Error while converting new card number to encrypted pan code '
               || SUBSTR (SQLERRM, 1, 200);
            RAISE exp_reject_record;
      END;

      BEGIN
         INSERT INTO cms_cardissuance_status
                     (ccs_inst_code, ccs_pan_code, ccs_card_status,
                      ccs_ins_user, ccs_ins_date, ccs_pan_code_encr,
                      ccs_appl_code                      --Added on 18.03.2013
                     )
              VALUES (prm_instcode, v_hash_new_pan, '2',
                      prm_instcode, SYSDATE, v_encr_new_pan,
                      v_appl_code                        --Added on 18.03.2013
                     );
      EXCEPTION
         WHEN OTHERS
         THEN
            v_errmsg :=
               'Error while Inserting CCF table ' || SUBSTR (SQLERRM, 1, 200);
            RAISE exp_reject_record;
      END;

      BEGIN
         INSERT INTO cms_smsandemail_alert
                     (csa_inst_code, csa_pan_code, csa_pan_code_encr,
                      csa_cellphonecarrier, csa_loadorcredit_flag,
                      csa_lowbal_flag, csa_lowbal_amt, csa_negbal_flag,
                      csa_highauthamt_flag, csa_highauthamt,
                      csa_dailybal_flag, csa_begin_time, csa_end_time,
                      csa_insuff_flag, csa_incorrpin_flag, csa_fast50_flag,

                      -- Added by MageshKumar.S on 19/09/2013 for JH-6
                      csa_fedtax_refund_flag,
                                             -- Added by MageshKumar.S on 19/09/2013 for JH-6
                                             csa_ins_user, csa_ins_date,
                      csa_lupd_user, csa_lupd_date,csa_alert_lang_id) --Added for FWR-59
            (SELECT prm_instcode, v_hash_new_pan, v_encr_new_pan,
                    NVL (csa_cellphonecarrier, 0), csa_loadorcredit_flag,
                    csa_lowbal_flag, NVL (csa_lowbal_amt, 0),
                    csa_negbal_flag, csa_highauthamt_flag,
                    NVL (csa_highauthamt, 0), csa_dailybal_flag,
                    NVL (csa_begin_time, 0), NVL (csa_end_time, 0),
                    csa_insuff_flag, csa_incorrpin_flag, csa_fast50_flag,

                    -- Added by MageshKumar.S on 19/09/2013 for JH-6
                    csa_fedtax_refund_flag,
                                           -- Added by MageshKumar.S on 19/09/2013 for JH-6
                                           prm_instcode, SYSDATE,
                    prm_instcode, SYSDATE,csa_alert_lang_id --Added for FWR-59
               FROM cms_smsandemail_alert
              WHERE csa_inst_code = prm_instcode
                    AND csa_pan_code = v_hash_pan);

         IF SQL%ROWCOUNT != 1
         THEN
            v_errmsg := 'Error while Entering sms email alert detail ';
            RAISE exp_reject_record;
         END IF;
      EXCEPTION
         WHEN exp_reject_record
         THEN
            RAISE;
         WHEN OTHERS
         THEN
            v_errmsg :=
                  'Error while Entering sms email alert detail '
               || SUBSTR (SQLERRM, 1, 200);
            RAISE exp_reject_record;
      END;
   END IF;

   ----------After Renewal process
   BEGIN
      SELECT ccm_addrverify_flag
        INTO v_addressverify_flag
        FROM cms_cust_mast
       WHERE ccm_inst_code = prm_instcode AND ccm_cust_code = v_cust_code;
   EXCEPTION
      WHEN NO_DATA_FOUND
      THEN
         v_errmsg := 'No record found in CMS_CUST_MAST ';
         RAISE exp_reject_record;
      WHEN OTHERS
      THEN
         v_errmsg :=
               'Error while fetching address flag from CMS_CUST_MAST '
            || SUBSTR (SQLERRM, 1, 200);
         RAISE exp_reject_record;
   END;

   BEGIN
      UPDATE cms_cardissuance_status
         SET ccs_renewal_comments =
                DECODE (v_addressverify_flag,
                        1,  'Address not Verified:Renewal Card Ordered '
                         || TO_CHAR (SYSDATE, 'MMDDYY'),
                        2,  'Address Verified.Renewal Card Ordered '
                         || TO_CHAR (SYSDATE, 'MMDDYY')
                       ),
             ccs_renewal_date = SYSDATE
       WHERE ccs_inst_code = prm_instcode AND ccs_pan_code = v_hash_pan;

      IF SQL%ROWCOUNT <> 1
      THEN
         v_errmsg :=
            'Error while updating ADDRESS VERIFY FLAG into CMS_CARDISSUANCE_STATUS ';
         RAISE exp_reject_record;
      END IF;
   EXCEPTION
      WHEN exp_reject_record
      THEN
         RAISE;
      WHEN OTHERS
      THEN
         v_errmsg :=
               'Error while updating Address Verification flag/DATE'
            || SUBSTR (SQLERRM, 1, 200);
         RAISE exp_reject_record;
   END;

   BEGIN
      UPDATE cms_cust_mast
         SET ccm_addrverify_flag = 0,
             ccm_addverify_date = NULL,
             ccm_avfset_channel = NULL,
             ccm_avfset_txncode = NULL
       --MODIFIED FOR TO UPDATE NULL FOR AFTER CARD RENEWAL
      WHERE  ccm_cust_code = v_cust_code AND ccm_inst_code = prm_instcode;

      IF SQL%ROWCOUNT <> 1
      THEN
         v_errmsg := 'Error while updating cust mast for addr flag ';
         RAISE exp_reject_record;
      END IF;
   EXCEPTION
      WHEN OTHERS
      THEN
         v_errmsg :=
               'Error while updating Address Verification flag'
            || SUBSTR (SQLERRM, 1, 200);
         RAISE exp_reject_record;
   END;

   ---History Block--
   BEGIN
      INSERT INTO cms_cardrenewal_hist
                  (cch_inst_code, cch_pan_code, cch_card_stat,
                   cch_renewal_date, cch_expry_date, cch_ins_user,
                   cch_ins_date,cch_new_pan_code,cch_new_pan_code_encr,cch_old_pan_code_encr --Added for PinMigration changes
                  )
           VALUES (prm_instcode, v_hash_pan, v_card_stat,
                   SYSDATE, v_old_expry_date, prm_lupduser,
                   SYSDATE,v_hash_new_pan,v_encr_new_pan,v_encr_pan --Added for PinMigration changes
                  );
   EXCEPTION
      WHEN OTHERS
      THEN
         v_errmsg :=
               'Error in inserting Card Renewal History'
            || SUBSTR (SQLERRM, 1, 200);
         RAISE exp_reject_record;
   END;

              ------------End of History BLock---------
-----------------------------------------------------------------------------------------------------------
  --Log Section
   BEGIN                                                                 --B23
      SELECT ctm_tran_desc
        INTO v_txn_desc
        FROM cms_transaction_mast
       WHERE ctm_inst_code = prm_instcode
         AND ctm_tran_code = prm_txn_code
         AND ctm_delivery_channel = '05';
   EXCEPTION
      WHEN NO_DATA_FOUND
      THEN
         v_errmsg := 'Txn not defined for Txn Code-' || prm_txn_code;
         RAISE exp_reject_record;
      WHEN OTHERS
      THEN
         v_errmsg :=
             'Error while selecting Txn details-' || SUBSTR (SQLERRM, 1, 200);
         RAISE exp_reject_record;
   END;

   --Success Log
   BEGIN                                                                 --B25
      INSERT INTO transactionlog
                  (msgtype, rrn, delivery_channel, txn_code, trans_desc,
                   customer_card_no, customer_card_no_encr, business_date,
                   business_time, txn_status, response_code, instcode,
                   add_ins_date, response_id, date_time, customer_acct_no,
                   acct_balance, ledger_balance, cardstatus, error_msg,
                   acct_type, productid, categoryid, cr_dr_flag,
                   time_stamp
                  )
           VALUES ('0200', v_rrn, '05', prm_txn_code, v_txn_desc,
                   v_hash_pan, v_encr_pan, TO_CHAR (SYSDATE, 'yyyymmdd'),
                   TO_CHAR (SYSDATE, 'hh24miss'), 'C', '00', prm_instcode,
                   SYSDATE, '1', SYSDATE, v_acct_no,
                   v_acct_bal, v_ledger_bal, v_card_stat, 'Successful',
                   v_acct_type, v_prod_code, v_cpm_catg_code, 'NA',
                   SYSTIMESTAMP
                  );
   EXCEPTION
      WHEN OTHERS
      THEN
         v_errmsg :=
               'Error while logging system initiated Card Status change '
            || SUBSTR (SQLERRM, 1, 200);
         RAISE exp_reject_record;
   END;

   BEGIN                                                                 --B26
      INSERT INTO cms_transaction_log_dtl
                  (ctd_delivery_channel, ctd_txn_code, ctd_txn_type,
                   ctd_msg_type, ctd_txn_mode, ctd_business_date,
                   ctd_business_time, ctd_customer_card_no,
                   ctd_process_flag, ctd_process_msg, ctd_inst_code,
                   ctd_customer_card_no_encr, ctd_cust_acct_number
                  )
           VALUES ('05', prm_txn_code, '0',
                   '0200', 0, TO_CHAR (SYSDATE, 'YYYYMMDD'),
                   TO_CHAR (SYSDATE, 'hh24miss'), v_hash_pan,
                   'Y', 'Successful', prm_instcode,
                   v_encr_pan, v_acct_no
                  );
   EXCEPTION
      WHEN OTHERS
      THEN
         v_errmsg :=
               'Error while inserting log details in transaction table'
            || SUBSTR (SQLERRM, 1, 200);
         RAISE exp_reject_record;
   END;

-----------------------------------------------------------------------------------------------------------
   IF prm_newpan IS NULL
   THEN
      prm_newpan := 'OK';
   END IF;

   prm_errmsg := v_errmsg;
EXCEPTION
   WHEN exp_reject_record
   THEN
      ROLLBACK;
      prm_errmsg := v_errmsg;
      prm_newpan := v_errmsg;

      IF v_txn_desc IS NULL
      THEN
         BEGIN
            SELECT ctm_tran_desc
              INTO v_txn_desc
              FROM cms_transaction_mast
             WHERE ctm_tran_code = prm_txn_code
               AND ctm_delivery_channel = '05'
               AND ctm_inst_code = prm_instcode;
         EXCEPTION
            WHEN OTHERS
            THEN
               NULL;
         END;
      END IF;

      IF v_prod_code IS NULL
      THEN
         BEGIN
            SELECT cap_prod_code, cap_card_type, cap_card_stat, cap_acct_no
              INTO v_prod_code, v_cpm_catg_code, v_card_stat, v_acct_no
              FROM cms_appl_pan
             WHERE cap_inst_code = prm_instcode AND cap_pan_code = v_hash_pan;
         EXCEPTION
            WHEN OTHERS
            THEN
               NULL;
         END;
      END IF;

      IF v_acct_bal IS NULL
      THEN
         BEGIN
            SELECT cam_acct_bal, cam_ledger_bal, cam_type_code
              INTO v_acct_bal, v_ledger_bal, v_acct_type
              FROM cms_acct_mast
             WHERE cam_inst_code = prm_instcode AND cam_acct_no = v_acct_no;
         EXCEPTION
            WHEN OTHERS
            THEN
               v_acct_bal := 0;
               v_ledger_bal := 0;
         END;
      END IF;

      --Error Log
      BEGIN                                                              --B24
         INSERT INTO transactionlog
                     (msgtype, rrn, delivery_channel, txn_code, trans_desc,
                      customer_card_no, customer_card_no_encr,
                      business_date,
                      business_time, txn_status, response_code,
                      instcode, add_ins_date, response_id, date_time,
                      customer_acct_no, acct_balance, ledger_balance,
                      cardstatus, error_msg, acct_type, productid,
                      categoryid, cr_dr_flag, time_stamp
                     )
              VALUES ('0200', v_rrn, '05', prm_txn_code, v_txn_desc,
                      v_hash_pan, v_encr_pan,
                      TO_CHAR (SYSDATE, 'yyyymmdd'),
                      TO_CHAR (SYSDATE, 'hh24miss'), 'F', '89',
                      prm_instcode, SYSDATE, '89', SYSDATE,
                      v_acct_no, v_acct_bal, v_ledger_bal,
                      v_card_stat, v_errmsg, v_card_type, v_prod_code,
                      v_cpm_catg_code, 'NA', SYSTIMESTAMP
                     );
      EXCEPTION
         WHEN OTHERS
         THEN
            v_errmsg :=
                  'Error while logging system initiated Single Card Renewal '
               || SUBSTR (SQLERRM, 1, 200);
            prm_errmsg := v_errmsg;
            prm_newpan := v_errmsg;
      END;

      BEGIN                                                              --B26
         INSERT INTO cms_transaction_log_dtl
                     (ctd_delivery_channel, ctd_txn_code, ctd_txn_type,
                      ctd_msg_type, ctd_txn_mode, ctd_business_date,
                      ctd_business_time, ctd_customer_card_no,
                      ctd_process_flag, ctd_process_msg, ctd_inst_code,
                      ctd_customer_card_no_encr, ctd_cust_acct_number
                     )
              VALUES ('05', prm_txn_code, '0',
                      '0200', 0, TO_CHAR (SYSDATE, 'YYYYMMDD'),
                      TO_CHAR (SYSDATE, 'hh24miss'), v_hash_pan,
                      'E', v_errmsg, prm_instcode,
                      v_encr_pan, v_acct_no
                     );
      EXCEPTION
         WHEN OTHERS
         THEN
            v_errmsg :=
                  'Error while inserting log details in transaction table'
               || SUBSTR (SQLERRM, 1, 200);
            prm_errmsg := v_errmsg;
            prm_newpan := v_errmsg;
            RETURN;
      END;
   WHEN OTHERS
   THEN
      ROLLBACK;
      prm_errmsg := 'Main Exception' || SUBSTR (SQLERRM, 1, 100);
      prm_newpan := 'Main Exception' || SUBSTR (SQLERRM, 1, 100);

      IF v_txn_desc IS NULL
      THEN
         BEGIN
            SELECT ctm_tran_desc
              INTO v_txn_desc
              FROM cms_transaction_mast
             WHERE ctm_tran_code = prm_txn_code
               AND ctm_delivery_channel = '05'
               AND ctm_inst_code = prm_instcode;
         EXCEPTION
            WHEN OTHERS
            THEN
               NULL;
         END;
      END IF;

      IF v_prod_code IS NULL
      THEN
         BEGIN
            SELECT cap_prod_code, cap_card_type, cap_card_stat, cap_acct_no
              INTO v_prod_code, v_cpm_catg_code, v_card_stat, v_acct_no
              FROM cms_appl_pan
             WHERE cap_inst_code = prm_instcode AND cap_pan_code = v_hash_pan;
         EXCEPTION
            WHEN OTHERS
            THEN
               NULL;
         END;
      END IF;

      IF v_acct_bal IS NULL
      THEN
         BEGIN
            SELECT cam_acct_bal, cam_ledger_bal, cam_type_code
              INTO v_acct_bal, v_ledger_bal, v_acct_type
              FROM cms_acct_mast
             WHERE cam_inst_code = prm_instcode AND cam_acct_no = v_acct_no;
         EXCEPTION
            WHEN OTHERS
            THEN
               v_acct_bal := 0;
               v_ledger_bal := 0;
         END;
      END IF;

      --Error Log
      BEGIN                                                              --B24
         INSERT INTO transactionlog
                     (msgtype, rrn, delivery_channel, txn_code, trans_desc,
                      customer_card_no, customer_card_no_encr,
                      business_date,
                      business_time, txn_status, response_code,
                      instcode, add_ins_date, response_id, date_time,
                      customer_acct_no, acct_balance, ledger_balance,
                      cardstatus, error_msg, acct_type, productid,
                      categoryid, cr_dr_flag, time_stamp
                     )
              VALUES ('0200', v_rrn, '05', prm_txn_code, v_txn_desc,
                      v_hash_pan, v_encr_pan,
                      TO_CHAR (SYSDATE, 'yyyymmdd'),
                      TO_CHAR (SYSDATE, 'hh24miss'), 'F', '89',
                      prm_instcode, SYSDATE, '89', SYSDATE,
                      v_acct_no, v_acct_bal, v_ledger_bal,
                      v_card_stat, v_errmsg, v_card_type, v_prod_code,
                      v_cpm_catg_code, 'NA', SYSTIMESTAMP
                     );
      EXCEPTION
         WHEN OTHERS
         THEN
            v_errmsg :=
                  'Error while logging system initiated Single Card Renewal '
               || SUBSTR (SQLERRM, 1, 200);
            prm_errmsg := v_errmsg;
            prm_newpan := v_errmsg;
      END;

      BEGIN                                                              --B26
         INSERT INTO cms_transaction_log_dtl
                     (ctd_delivery_channel, ctd_txn_code, ctd_txn_type,
                      ctd_msg_type, ctd_txn_mode, ctd_business_date,
                      ctd_business_time, ctd_customer_card_no,
                      ctd_process_flag, ctd_process_msg, ctd_inst_code,
                      ctd_customer_card_no_encr, ctd_cust_acct_number
                     )
              VALUES ('05', prm_txn_code, '0',
                      '0200', 0, TO_CHAR (SYSDATE, 'YYYYMMDD'),
                      TO_CHAR (SYSDATE, 'hh24miss'), v_hash_pan,
                      'E', v_errmsg, prm_instcode,
                      v_encr_pan, v_acct_no
                     );
      EXCEPTION
         WHEN OTHERS
         THEN
            v_errmsg :=
                  'Error while inserting log details in transaction table'
               || SUBSTR (SQLERRM, 1, 200);
            prm_errmsg := v_errmsg;
            prm_newpan := v_errmsg;
            RETURN;
      END;
END;
/
SHOW ERROR;