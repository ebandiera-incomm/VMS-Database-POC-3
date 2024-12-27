create or replace PACKAGE BODY        vmscms.VMS_SPIL_VIRTUAL AS

  PROCEDURE SALE_ACTIVE_CODE_REQ(
    p_inst_code_in                 IN VARCHAR2, 
    p_msg_typ_in                   IN VARCHAR2,
    p_rrn_in                       IN VARCHAR2,
    p_delivery_channel_in          IN VARCHAR2,
    p_term_id_in                   IN VARCHAR2,
    p_tran_code_in                 IN VARCHAR2,
    p_tran_mode_in                 IN VARCHAR2,
    p_business_date_in             IN VARCHAR2,
    p_business_time_in             IN VARCHAR2,
    p_curr_code_in                 IN VARCHAR2,
    p_reversal_code_in             IN VARCHAR2,
    p_prod_code_in                 IN VARCHAR2,
    p_card_type_in                 IN VARCHAR2,
    p_package_id_in                IN VARCHAR2,
    p_tran_amount_in               IN NUMBER,
    p_merchant_name_in             IN VARCHAR2,
    p_store_id_in                  IN VARCHAR2,
    p_store_addr1_in               IN VARCHAR2,
    p_store_addr2_in               IN VARCHAR2,
    p_store_city_in                IN VARCHAR2,
    p_store_state_in               IN VARCHAR2,
    p_postal_code_in               IN VARCHAR2,
    p_fee_amt_in                   IN VARCHAR2,
    p_upc_in                       IN VARCHAR2,
    p_mercrefnum_in                IN VARCHAR2,
    p_reqtimezone_in               IN VARCHAR2,
    p_localcountry_in              IN VARCHAR2,
    p_localcurrency_in             IN VARCHAR2,
    p_loclanguage_in               IN VARCHAR2,
    p_posentry_in                  IN VARCHAR2,
    p_poscond_in                   IN VARCHAR2,
    p_resp_msg_out                 OUT VARCHAR2,
    p_resp_code_out                OUT VARCHAR2,
    p_acct_balance_out             OUT NUMBER,
    p_auth_id_out                  OUT VARCHAR2,
    p_serial_no_out                OUT VARCHAR2,
    p_proxy_no_out                 OUT VARCHAR2,
    p_pan_number_out               OUT VARCHAR2,
    p_card_status_out              OUT VARCHAR2,
    p_merchant_id_in                IN VARCHAR2 DEFAULT NULL  --Added for VMS_7594
    ) AS
	
	
/*************************************************
	  * Modified By      : Veneetha C
     * Modified Date    : 21-JAN-2019
     * Purpose          : VMS-622 Redemption delay for activations /reloads processed through ICGPRM
     * Reviewer         : Saravanan
     * Release Number   : VMSGPRHOST R11

      * Modified By      : Ubaidur Rahman H
     * Modified Date    : 29-AUG-2019
     * Purpose          : VMS-1084 (Pan genaration process from sequential to shuffled - B2B & Retail)
     * Reviewer         : Saravanakumar A
     * Release Number   : VMSGPRHOSTR20_B1    

     * Modified By      : Ubaidur Rahman H
     * Modified Date    : 30-OCT-2019
     * Purpose          : VMS-1248 (Improve Query performance for BOL SQL for card creation)
     * Reviewer         : Saravanakumar A        

     * Modified By      : UBAIDUR RAHMAN H
     * Modified Date    : 28-AUG-2020
     * Purpose          : VMS-2888 - VPS_AVAIL_CARDS Column on VMS_PANGEN_SUMMARY 
					Table has incorrect value. 
     * Reviewer         : Saravanakumar A. 
     * Build Number     : R35 - BUILD 3

     * Modified By      : PANDU GANDHAM
     * Modified Date    : 29-SEP-2020
     * Purpose          : VMS-3066 - Product Setup re-Vamp - BIN.
     * Reviewer         : Puvanesh / Ubaidur 
     * Build Number     : R36 - BUILD 3

	 * Modified By      : Saravana Kumar A
     * Modified Date    : 27-DEC-2021
     * Purpose          : VMS-4208 : SPIL Virtual Sale Active code transaction is not returning 
									the proper error message when the system is not having the Virtual PIN 
									for the requested card.
     * Reviewer         : Venkat.S
     * Build Number     : R56 - BUILD 2

     * Modified By      : Mageshkumar.S
     * Modified Date    : 25-01-2022
     * Purpose          : VMS-5432:C - Order V1/V2 with Initial Load Amount--Access to Funds-- --B2B Spec Consolidation
     * Reviewer         : Saravanakumar A.
     * Build Number     : R57.1 - BUILD 1

     * Modified By      : Mageshkumar.S
     * Modified Date    : 04-04-2022
     * Purpose          : VMS-5814:System not updating the CVK Key ID(Key used to generate the CVV) in CMS_APPL_PAN table for Virtual Card CVV generation
     * Reviewer         : Saravanakumar A.
     * Build Number     : R60.1 - BUILD 1

	* Modified By      : Karthick
    * Modified Date    : 08-24-2022
    * Purpose          : Archival changes.
    * Reviewer         : Venkat Singamaneni
    * Release Number   : VMSGPRHOST60 for VMS-5739/FSP-991

    * Modified By      : Bhavani E.
    * Modified Date    : 04-05-2023
    * Purpose          : VMS-7274 :  Expiry Date Randomization - Exclude sweep products
    * Reviewer         : Venkat S.
    
    * Modified By      : Mohan E.
    * Modified Date    : 06-29-2023
    * Purpose          : VMS-7594 : Log MerchantId, MerchantName and storeID for Sale active code
    * Reviewer         : Pankaj S.
*********************************************************************************/



     l_tran_desc                 cms_transaction_mast.ctm_tran_desc%TYPE;
    l_drcr_flag                 cms_transaction_mast.ctm_credit_debit_flag%TYPE;
    l_profile_code              cms_prod_cattype.cpc_profile_code%TYPE;
    l_display_name              cms_prod_cattype.cpc_startercard_dispname%TYPE; 
    l_product_id                cms_prod_cattype.cpc_product_id%TYPE;
    l_prxy_length               cms_prod_cattype.cpc_proxy_length%TYPE;
    l_redmption_delay_flag      cms_prod_cattype.cpc_redemption_delay_flag%TYPE;
    l_appl_code                 cms_appl_mast.cam_appl_code%TYPE;
    l_acct_no                   cms_acct_mast.cam_acct_no%TYPE;
    l_expry_date                cms_appl_pan.cap_expry_date%TYPE;
    l_cust_catg                 cms_appl_pan.cap_cust_catg%TYPE;
	  l_pan_code				          cms_appl_pan.cap_pan_code%TYPE;
	  l_cust_code					        cms_appl_pan.cap_cust_code%TYPE;		
	  l_acct_id                   cms_appl_pan.cap_acct_id%TYPE;
	  l_bill_addr					        cms_appl_pan.cap_bill_addr%TYPE;
	  l_pan_code_encr             cms_appl_pan.cap_pan_code_encr%TYPE;
	  l_mask_pan					        cms_appl_pan.cap_mask_pan%TYPE;
	  l_appl_bran                 cms_appl_pan.cap_appl_bran%TYPE;
    l_prod_type                 cms_bin_param.cbp_param_value%TYPE;
    l_prod_catg                 cms_appl_pan.cap_prod_catg%TYPE;
    l_cpc_prod_deno				      cms_prod_cattype.cpc_prod_denom%TYPE;
    l_cpc_pden_min				      cms_prod_cattype.cpc_pdenom_min%TYPE;
    l_cpc_pden_max				      cms_prod_cattype.cpc_pdenom_max%TYPE;
    l_cpc_pden_fix		   		    cms_prod_cattype.cpc_pdenom_fix%TYPE;
    l_b2b_flag                  cms_prod_cattype.cpc_b2b_flag%TYPE;
    l_lmtprfl				            cms_appl_pan.cap_prfl_code%TYPE;
    l_profile_level		          cms_appl_pan.cap_prfl_levl%TYPE;
    l_txn_redmption_flag        cms_transaction_mast.ctm_redemption_delay_flag%TYPE;
    l_timestamp                 TIMESTAMP;
    l_hashkey_id                cms_transaction_log_dtl.ctd_hashkey_id%TYPE;
    l_narration                 cms_statements_log.csl_trans_narrration%TYPE;
    excp_error                  EXCEPTION;
    l_user_code                 cms_appl_mast.cam_lupd_user%TYPE := 1;
    l_currcode                  transactionlog.currencycode%TYPE;
    l_card_id                   cms_prod_cardpack.cpc_card_id%TYPE;
    l_bin                       cms_prod_bin.cpb_inst_bin%TYPE;
    l_mbr_numb                  VARCHAR2 (5) := '000';
    l_const                     NUMBER := 1;
    l_pins                      NUMBER;
    l_count                     NUMBER;
    l_rrn_count                 number;
    l_txn_amt                   cms_statements_log.CSL_TRANS_AMOUNT%TYPE;
	l_start_control_number 		VMS_INVENTORY_CONTROL.VIC_CONTROL_NUMBER%TYPE;
	l_end_control_number 		VMS_INVENTORY_CONTROL.VIC_CONTROL_NUMBER%TYPE;
	l_cntrl_flag                VARCHAR2 (1) :='N';
    l_error_msg                 TRANSACTIONLOG.ERROR_MSG%TYPE := 'OK';
    l_remark                    TRANSACTIONLOG.REMARK%TYPE;
    l_delayed_accessto_firstload_flag CMS_PROD_CATTYPE.CPC_DELAYED_FIRSTLOAD_ACCESS%TYPE;
    l_delayed_access_date CMS_CUST_MAST.CCM_DELAYEDACCESS_DATE%TYPE;
    l_cvv_multiplekey_flag  CMS_PROD_CATTYPE.cpc_multikey_flag%TYPE;
    l_exec_query                VARCHAR2 (20000);
    l_key_id    cms_appl_pan.cap_cvk_keyid%type;
	--sn vms-7274
    l_expry_arry EXPRY_ARRAY_TYP := EXPRY_ARRAY_TYP ();
    l_sweep_flag cms_prod_cattype.cpc_sweep_flag%type;
    l_isexpry_randm cms_prod_cattype.cpc_expdate_randomization%type;
    --en vms-7274
	v_Retperiod  date;  --Added for VMS-5739/FSP-991
	v_Retdate  date; --Added for VMS-5739/FSP-991

	 PROCEDURE lp_get_proxy (
     p_productid_in         IN  VARCHAR2,
     p_proxy_no_out         OUT VARCHAR2,
     p_resp_msg_out           OUT VARCHAR2)
  AS
     l_cntrl_no         vms_prodid_pin_cntrl.vpp_cntrl_no%TYPE;
     l_excp             EXCEPTION;
     PRAGMA AUTONOMOUS_TRANSACTION;
  BEGIN
     p_resp_msg_out := 'OK';
     BEGIN
        SELECT vpp_cntrl_no
          INTO l_cntrl_no
          FROM vms_prodid_pin_cntrl
         WHERE vpp_product_id = p_productid_in
         FOR UPDATE;
       EXCEPTION
           WHEN OTHERS
           THEN
              p_resp_msg_out :=
                 'Error while selecting vms_prodid_pin_cntrl :'
                 || SUBSTR (SQLERRM, 1, 200);
             RAISE l_excp;
     END;

     BEGIN
        SELECT vsp_pin_numb
          INTO p_proxy_no_out
          FROM vms_shfl_pinno
         WHERE vsp_product_id = p_productid_in
           AND vsp_shfl_cntrl = l_cntrl_no;
       EXCEPTION
           WHEN OTHERS
           THEN
              p_resp_msg_out :=
                 'Error while selecting vms_shfl_pinno :'
                 || SUBSTR (SQLERRM, 1, 200);
              RAISE l_excp;
     END;

     BEGIN
         UPDATE vms_prodid_pin_cntrl
            SET vpp_cntrl_no = vpp_cntrl_no + 1
          WHERE vpp_product_id = p_productid_in;
      EXCEPTION
         WHEN OTHERS
         THEN
            p_resp_msg_out :=
               'Error While updating control number :'
               || SUBSTR (SQLERRM, 1, 200);
            RAISE l_excp;
      END;
      COMMIT;
  EXCEPTION
     WHEN l_excp THEN
      ROLLBACK;
     WHEN OTHERS
     THEN
        p_resp_msg_out := 'Main Excp : lp_get_proxy' || SUBSTR (SQLERRM, 1, 200);
        ROLLBACK;
  END lp_get_proxy;


  PROCEDURE lp_virtual_process (
     p_productid_in         IN  VARCHAR2,
     p_pan_code_in          IN  VARCHAR2,
     p_pan_code_encr_in     IN  VARCHAR2,
     p_cust_code_in         IN  VARCHAR2,
     p_acct_id_in           IN  VARCHAR2,
     p_delayed_accessto_firstload_flag_in IN  VARCHAR2,
     p_proxy_no_out         OUT VARCHAR2,
     p_resp_msg_out           OUT VARCHAR2)
  AS
     l_cntrl_no         vms_prodid_pin_cntrl.vpp_cntrl_no%TYPE;
     l_serial_number_arr  SHUFFLE_ARRAY_TYP;
	  l_toggle_value     cms_inst_param.cip_param_value%TYPE; --VMS-6248 Changes
  BEGIN
     p_resp_msg_out := 'OK';

	 	 --SN: VMS-6248 Changes
     BEGIN
	  SELECT UPPER(TRIM(NVL(cip_param_value,'Y')))
		INTO l_toggle_value
		FROM vmscms.cms_inst_param
	   WHERE cip_inst_code = 1
		 AND cip_param_key = 'VMS_6248_TOGGLE';
	 EXCEPTION
	   WHEN NO_DATA_FOUND THEN
		  l_toggle_value := 'Y';
	 END;

     IF l_toggle_value = 'Y' THEN
        BEGIN
            lp_get_proxy(p_productid_in,p_proxy_no_out,p_resp_msg_out);

            IF p_resp_msg_out != 'OK' THEN
               RETURN;
            END IF;
        EXCEPTION
          WHEN OTHERS THEN
              p_resp_msg_out :='Error while calling lp_get_proxy :'|| SUBSTR (SQLERRM, 1, 200);
             RETURN;
        END;
     ELSE
     --EN: VMS-6248 Changes

     BEGIN
        SELECT vpp_cntrl_no
          INTO l_cntrl_no
          FROM vms_prodid_pin_cntrl
         WHERE vpp_product_id = l_product_id
         FOR UPDATE;  
       EXCEPTION
           WHEN OTHERS
           THEN
              p_resp_msg_out :=
                 'Error while selecting vms_prodid_pin_cntrl :'
                 || SUBSTR (SQLERRM, 1, 200);
             RETURN;
     END;

     BEGIN
        SELECT vsp_pin_numb
          INTO p_proxy_no_out
          FROM vms_shfl_pinno
         WHERE vsp_product_id = l_product_id
           AND vsp_shfl_cntrl = l_cntrl_no;  
       EXCEPTION
           WHEN OTHERS
           THEN
              p_resp_msg_out :=
                 'Error while selecting vms_shfl_pinno :'
                 || SUBSTR (SQLERRM, 1, 200);
              RETURN;
     END;

     BEGIN
         UPDATE vms_prodid_pin_cntrl
            SET vpp_cntrl_no = vpp_cntrl_no + 1
          WHERE vpp_product_id = l_product_id;
      EXCEPTION
         WHEN OTHERS
         THEN
            p_resp_msg_out :=
               'Error While updating control number :'
               || SUBSTR (SQLERRM, 1, 200);
            RETURN;
      END;
  END IF; --VMS-6248 Changes    
      BEGIN
         UPDATE cms_cust_mast
            SET ccm_kyc_flag = 'A',
            ccm_delayedaccess_date=decode(p_delayed_accessto_firstload_flag_in,'Y',LAST_DAY(SYSDATE),ccm_delayedaccess_date)
          WHERE ccm_cust_code = p_cust_code_in
                AND ccm_inst_code = p_inst_code_in;
      EXCEPTION
         WHEN OTHERS
         THEN
            p_resp_msg_out :=
               'Error While updating kyc flag :'
               || SUBSTR (SQLERRM, 1, 200);
            RETURN;
      END;

        BEGIN
           INSERT INTO cms_smsandemail_alert (csa_inst_code,
                                              csa_pan_code,
                                              csa_pan_code_encr,
                                              csa_loadorcredit_flag,
                                              csa_lowbal_flag,
                                              csa_negbal_flag,
                                              csa_highauthamt_flag,
                                              csa_dailybal_flag,
                                              csa_insuff_flag,
                                              csa_incorrpin_flag,
                                              csa_fast50_flag,
                                              csa_fedtax_refund_flag,
                                              csa_deppending_flag,
                                              csa_depaccepted_flag,
                                              csa_deprejected_flag,
                                              csa_ins_user,
                                              csa_ins_date)
                VALUES (p_inst_code_in,
                        p_pan_code_in,
                        p_pan_code_encr_in,
                        0,
                        0,
                        0,
                        0,
                        0,
                        0,
                        0,
                        0,
                        0,
                        0,
                        0,
                        0,
                        l_user_code,
                        SYSDATE);
        EXCEPTION
		 WHEN DUP_VAL_ON_INDEX THEN NULL;
           WHEN OTHERS
           THEN
              p_resp_msg_out :=
                 'Error While Inserting smsandemail_alert :'
                 || SUBSTR (SQLERRM, 1, 200);
              RETURN;
        END;

        BEGIN
           INSERT INTO cms_pan_acct (cpa_inst_code,
                                     cpa_cust_code,
                                     cpa_acct_id,
                                     cpa_acct_posn,
                                     cpa_pan_code,
                                     cpa_mbr_numb,
                                     cpa_ins_user,
                                     cpa_lupd_user,
                                     cpa_pan_code_encr)
                VALUES (p_inst_code_in,
                        p_cust_code_in,
                        p_acct_id_in,
                        l_const,
                        p_pan_code_in,
                        l_mbr_numb,
                        l_user_code,
                        l_user_code,
                        p_pan_code_encr_in);
        EXCEPTION
           WHEN OTHERS
           THEN
              p_resp_msg_out :=
                 'Error While Inserting pan_acct :'
                 || SUBSTR (SQLERRM, 1, 200);
              RETURN;
        END;

  EXCEPTION
     WHEN OTHERS
     THEN
        p_resp_msg_out := 'Main Excp : LP_VIRTUAL_PROCESS' || SUBSTR (SQLERRM, 1, 200);
  END LP_VIRTUAL_PROCESS;

---<< MAIN >> --
BEGIN
  BEGIN
   p_resp_msg_out := 'OK';
   l_txn_amt := ROUND (p_tran_amount_in,2);

   BEGIN
        SELECT ctm_tran_desc,
               ctm_credit_debit_flag,
               NVL(ctm_redemption_delay_flag,'N')
          INTO l_tran_desc,
               l_drcr_flag,
               l_txn_redmption_flag
          FROM cms_transaction_mast
         WHERE ctm_inst_code = p_inst_code_in
           AND ctm_delivery_channel = p_delivery_channel_in
           AND ctm_tran_code = p_tran_code_in;
     EXCEPTION
        WHEN OTHERS
        THEN
           p_resp_msg_out :=
              'Error While Transaction Details:'
              || SUBSTR (SQLERRM, 1, 200);
           p_resp_code_out := '89';
           RAISE excp_error;
   END;

    BEGIN
		--Added for VMS-5739/FSP-991
	   select (add_months(trunc(sysdate,'MM'),'-'||RETENTION_PERIOD))
       INTO   v_Retperiod 
       FROM DBA_OPERATIONS.ARCHIVE_MGMNT_CTL  
       WHERE  OPERATION_TYPE='ARCHIVE' 
       AND OBJECT_NAME='TRANSACTIONLOG_EBR';

       v_Retdate := TO_DATE(SUBSTR(TRIM(p_business_date_in), 1, 8), 'yyyymmdd');

	IF (v_Retdate>v_Retperiod)THEN												--Added for VMS-5739/FSP-991

        SELECT count(1)
          INTO l_rrn_count
          FROM transactionlog
         WHERE instcode = p_inst_code_in 
		       AND rrn = p_rrn_in 
		       AND business_date = p_business_date_in 
		       AND delivery_channel = p_delivery_channel_in;

	ELSE 

	    SELECT count(1)
          INTO l_rrn_count
          FROM VMSCMS_HISTORY.TRANSACTIONLOG_HIST 						--Added for VMS-5739/FSP-991
         WHERE instcode = p_inst_code_in 
		       AND rrn = p_rrn_in 
		       AND business_date = p_business_date_in 
		       AND delivery_channel = p_delivery_channel_in;

	END IF;

        IF l_rrn_count > 0 then
            p_resp_code_out := '22';
            p_resp_msg_out   := 'Duplicate Incomm Reference Number ' || p_rrn_in;
            RAISE excp_error;
        END IF;
    EXCEPTION
        WHEN excp_error THEN
             RAISE;
        WHEN OTHERS THEN
            p_resp_code_out := '21';
            p_resp_msg_out := 'Error while selecting rrn count  ' ||  SUBSTR(SQLERRM, 1, 200);
            RAISE excp_error;
    END;

   BEGIN
      SELECT gcm_curr_code
        INTO l_currcode
        FROM gen_curr_mast
       WHERE gcm_inst_code = p_inst_code_in
             AND gcm_curr_name = p_curr_code_in;
   EXCEPTION
      WHEN OTHERS
      THEN
         p_resp_code_out := '89';
         p_resp_msg_out :=
               'Error while selecting the currency code for '
            || p_curr_code_in
            || ' is-'
            || SUBSTR (SQLERRM, 1, 200);
         RAISE excp_error;
   END;

   BEGIN
        SELECT cpc_profile_code,
               cpc_startercard_dispname,
               cpc_product_id,
               cpc_proxy_length,
               cpc_prod_denom,
               cpc_pdenom_min,
               cpc_pdenom_max,
               cpc_pdenom_fix,
               cpc_b2b_flag,
               NVL(cpc_redemption_delay_flag,'N'),
               cpc_b2b_lmtprfl,
               NVL(CPC_DELAYED_FIRSTLOAD_ACCESS,'N'),
               NVL(cpc_multikey_flag,'N'),
               NVL(cpc_expdate_randomization,'N'), --Added for VMS-7274
               NVL(cpc_sweep_flag,'N')             --Added for VMS-7274 
          INTO l_profile_code,
               l_display_name,
               l_product_id,
               l_prxy_length,
               l_cpc_prod_deno,
               l_cpc_pden_min,
               l_cpc_pden_max,
               l_cpc_pden_fix,
               l_b2b_flag,
               l_redmption_delay_flag,
               l_lmtprfl,
               l_delayed_accessto_firstload_flag,
               l_cvv_multiplekey_flag,
               l_isexpry_randm, --Added for VMS-7274
               l_sweep_flag     --Added for VMS-7274
          FROM cms_prod_cattype
          WHERE cpc_inst_code = p_inst_code_in
            AND cpc_prod_code = p_prod_code_in
            AND cpc_card_type = p_card_type_in;


     EXCEPTION
        WHEN OTHERS
        THEN
           p_resp_msg_out :=
              'Error while selecting product dtls:'
              || SUBSTR (SQLERRM, 1, 200);
            p_resp_code_out := '89';
           RAISE excp_error;
   END;

   IF l_cpc_prod_deno = 1
   THEN
        IF l_txn_amt NOT BETWEEN l_cpc_pden_min AND l_cpc_pden_max
        THEN
           p_resp_code_out := '43';
           p_resp_msg_out := 'Invalid Amount';
           RAISE excp_error;
        END IF;
   ELSIF l_cpc_prod_deno = 2
   THEN
        IF l_txn_amt <> l_cpc_pden_fix
        THEN
          p_resp_code_out := '43';
          p_resp_msg_out := 'Invalid Amount';
          RAISE excp_error;
        END IF;
   ELSIF l_cpc_prod_deno = 3
   THEN
       SELECT COUNT (*)
         INTO l_count
         FROM vms_prodcat_deno_mast
        WHERE vpd_inst_code = p_inst_code_in
          AND vpd_prod_code = p_prod_code_in
          AND vpd_card_type = p_card_type_in
          AND vpd_pden_val = l_txn_amt;

        IF l_count = 0
        THEN
          p_resp_code_out := '43';
          p_resp_msg_out := 'Invalid Amount';
          RAISE excp_error;
        END IF;
   END IF;

   IF l_b2b_flag = 'Y'
   THEN
          l_profile_level := 1;
   END IF;

   IF l_lmtprfl IS NULL OR l_profile_level IS NULL 
   THEN
      BEGIN
              SELECT cpl_lmtprfl_id
                INTO l_lmtprfl
                FROM cms_prdcattype_lmtprfl
               WHERE cpl_inst_code = p_inst_code_in 
                 AND cpl_prod_code = p_prod_code_in 
                 AND cpl_card_type = p_card_type_in;

              l_profile_level := 2;
        EXCEPTION
          WHEN NO_DATA_FOUND THEN
           BEGIN
              SELECT cpl_lmtprfl_id
                INTO l_lmtprfl
                FROM cms_prod_lmtprfl
               WHERE cpl_inst_code = p_inst_code_in
                 AND cpl_prod_code = p_prod_code_in;

                 l_profile_level := 3;
               EXCEPTION
                 WHEN NO_DATA_FOUND THEN
                  NULL;
                 WHEN OTHERS THEN
                  p_resp_code_out := '21';
                  p_resp_msg_out   := 'Error while selecting Limit Profile At Product Level' ||
                              SQLERRM;
                  RAISE excp_error;
           END;
         WHEN OTHERS THEN
             p_resp_code_out := '21';
             p_resp_msg_out   := 'Error while selecting Limit Profile At Product Catagory Level' ||
                        SQLERRM;
             RAISE excp_error;
      END;
   END IF;

   IF l_display_name IS NULL
      THEN

         BEGIN
               SELECT cpb_inst_bin
                 INTO l_bin
                 FROM cms_prod_bin
                WHERE cpb_inst_code = p_inst_code_in
                  AND cpb_prod_code = p_prod_code_in;
              EXCEPTION
                 WHEN OTHERS
                 THEN
                    p_resp_msg_out :=
                       'Error while selecting prod-bin dtls:'
                       || SUBSTR (SQLERRM, 1, 200);
                    RAISE excp_error;
         END;

         BEGIN
            SELECT cbm_interchange_code
              INTO l_display_name
              FROM cms_bin_mast
             WHERE cbm_inst_bin = l_bin 
               AND cbm_inst_code = p_inst_code_in;

            IF l_display_name IS NULL
            THEN
               l_display_name := 'No Record for the selected Bin';
            ELSE
               IF l_display_name = 'M'
               THEN
                  l_display_name := 'INSTANT MASTERCARD';
               ELSIF l_display_name = 'V'
               THEN
                  l_display_name := 'INSTANT VISA CARD';
               ELSE
                  l_display_name := 'No Record for the selected Bin';
               END IF;
            END IF;
         EXCEPTION
            WHEN OTHERS
            THEN
               p_resp_msg_out :=
                  'Error while selecting bin dtls:'
                  || SUBSTR (SQLERRM, 1, 200);
               RAISE excp_error;
         END;
      END IF;

		BEGIN
                vmsb2bapi.get_inventory_control_number(	p_prod_code_in,
							p_card_type_in,
							1,
							l_start_control_number ,
							l_end_control_number ,
							p_resp_msg_out );
                IF p_resp_msg_out <> 'OK' THEN
                    RAISE excp_error;
                END IF;

				 l_cntrl_flag :='Y';


        EXCEPTION
                WHEN excp_error THEN
                    RAISE;
                WHEN OTHERS THEN
                 p_resp_msg_out :=
                        'Error while calling get_inventory_control_number '
                        || SUBSTR (SQLERRM, 1, 200);
                     RAISE excp_error;
        END;

   BEGIN
       SELECT cap_appl_code,
             cap_prod_catg,
             cap_cust_catg,
             cap_pan_code,
             cap_cust_code,
             cap_acct_id,
             cap_acct_no,
             cap_bill_addr,
             cap_pan_code_encr,
             cap_mask_pan,
             cap_appl_bran
        INTO l_appl_code,
             l_prod_catg,
             l_cust_catg,
             l_pan_code,
             l_cust_code,
             l_acct_id,
             l_acct_no,
             l_bill_addr,
             l_pan_code_encr,
             l_mask_pan,
             l_appl_bran    
          FROM cms_appl_pan_inv
           WHERE cap_prod_code = p_prod_code_in
                 AND cap_card_type = p_card_type_in
                 AND cap_issue_stat = 'N'
                 AND cap_card_seq  BETWEEN l_start_control_number AND l_end_control_number;	
			  /*(SELECT cap_card_seq
			  FROM
			    (SELECT a.cap_card_seq
			    FROM cms_appl_pan_inv a
			    WHERE a.cap_prod_code= p_prod_code_in
			    AND a.cap_card_type  = p_card_type_in
			    AND a.cap_issue_stat ='N'
				AND ROWNUM <=10000
			    ORDER BY dbms_random.value
			    )
			  WHERE ROWNUM = 1
			  ) FOR UPDATE;*/

	---Modified for VMS-1084 (Pan genaration process from sequential to shuffled - B2B & Retail)		  			  


      EXCEPTION   
          WHEN OTHERS THEN
                 p_resp_code_out := '21';
                 p_resp_msg_out   := 'Error while selecting card details from inventory' ||
                            SQLERRM;
                 RAISE excp_error;
    END;

   p_pan_number_out := fn_dmaps_main(l_pan_code_encr);   

   BEGIN
      UPDATE cms_appl_pan_inv
         SET cap_issue_stat = 'I'
       WHERE cap_pan_code = l_pan_code;  

       EXCEPTION
         WHEN OTHERS
         THEN
            p_resp_msg_out :=
               'Error While updating issue stat :'
               || SUBSTR (SQLERRM, 1, 200);
            RAISE excp_error;
   END;

   BEGIN
    --SN:VMS-7274 Changes
    IF l_isexpry_randm = 'Y' AND l_sweep_flag='N' THEN
        vmsfunutilities.get_expiry_date (p_inst_code_in,
                                         p_prod_code_in,
                                         p_card_type_in,
                                         l_profile_code,
                                         1,
                                         l_expry_arry,
                                         p_resp_msg_out);
           IF p_resp_msg_out = 'OK' THEN
            l_expry_date:=l_expry_arry(1);  
           END IF;                 
    ELSE  
    --EN:VMS-7274 Changes   
        vmsfunutilities.get_expiry_date (p_inst_code_in,
                                         p_prod_code_in,
                                         p_card_type_in,
                                         l_profile_code,
                                         l_expry_date,
                                         p_resp_msg_out);
    END IF;
        IF p_resp_msg_out <> 'OK'
        THEN
           p_resp_code_out := '89';
           RAISE excp_error;
        END IF;
     EXCEPTION
        WHEN excp_error
        THEN
           RAISE;
        WHEN OTHERS
        THEN
           p_resp_msg_out :=
              'Error while calling vmsfunutilities.get_expiry_date'
              || SUBSTR (SQLERRM, 1, 200);
           p_resp_code_out := '89';
           RAISE excp_error;
   END;  


   BEGIN
      SELECT cpc_card_id 
        INTO l_card_id
        FROM cms_prod_cardpack
       WHERE cpc_inst_code = p_inst_code_in
         AND cpc_prod_code = p_prod_code_in
         AND cpc_card_details = p_package_id_in;
       EXCEPTION   
          WHEN OTHERS THEN
                 p_resp_code_out := '21';
                 p_resp_msg_out   := 'Error while selecting card id' ||
                            SQLERRM;
                 RAISE excp_error;   
   END;


   p_card_status_out := '1';


                        BEGIN

                           l_exec_query := 'SELECT  cbp_key_id from(SELECT  cbp_key_id from vmscms.cms_bin_param 
                                           WHERE   cbp_param_type = ''Emboss Parameter''
                                           AND CBP_PROFILE_CODE = :l_profile_code
                                           ORDER BY CBP_INS_DATE '|| case when l_cvv_multiplekey_flag= 'Y' then 'DESC ' else 'ASC ' end||') where rownum=1' ;

                           EXECUTE IMMEDIATE l_exec_query
                           INTO l_key_id using l_profile_code;

                       EXCEPTION
                          WHEN OTHERS
                          THEN
                             p_resp_code_out := '21';
                             p_resp_msg_out :=
                                   'Error while executing l_exec_query '
                                || SUBSTR (SQLERRM, 1, 200);
                             RAISE excp_error;
    END;

   BEGIN
       INSERT INTO cms_appl_pan (cap_appl_code,
                                 cap_prod_code,
                                 cap_prod_catg,
                                 cap_card_type,
                                 cap_cust_catg,
                                 cap_pan_code,
                                 cap_cust_code,
                                 cap_expry_date,
                                 cap_acct_id,
                                 cap_acct_no,
                                 cap_bill_addr,
                                 cap_pan_code_encr,
                                 cap_mask_pan,
                                 cap_appl_bran,
                                 cap_inst_code,
                                 cap_asso_code,
                                 cap_inst_type,
                                 cap_mbr_numb,
                                 cap_disp_name,
                                 cap_addon_stat,
                                 cap_addon_link,
                                 cap_mbr_link,
                                 cap_tot_acct,
                                 cap_pangen_date,
                                 cap_pangen_user,
                                 cap_ins_user,
                                 cap_lupd_user,
                                 cap_issue_flag,
                                 cap_card_stat,
                                 cap_active_date,
                                 cap_startercard_flag,
                                 CAP_FIRSTTIME_TOPUP, 
                                 cap_prfl_code,
                                 cap_prfl_levl, 
                                 cap_cardpack_id,
                                 cap_form_factor,
                                 cap_proxy_msg,
                                 cap_pin_off,
                                 cap_cvk_keyid,
                                 CAP_MERCHANT_ID,       --Added for VMS_7594 
                                 CAP_MERCHANT_NAME,     --Added for VMS_7594 
                                 CAP_STORE_ID           --Added for VMS_7594 
                                 )
                        VALUES ( l_appl_code,
                                 p_prod_code_in,
                                 l_prod_catg,
                                 p_card_type_in,
                                 l_cust_catg,
                                 l_pan_code,
                                 l_cust_code,
                                 l_expry_date,
                                 l_acct_id,
                                 l_acct_no,
                                 l_bill_addr,
                                 l_pan_code_encr,
                                 l_mask_pan,
                                 l_appl_bran,
                                 p_inst_code_in,
                                 l_const,
                                 l_const,
                                 l_mbr_numb,
                                 l_display_name,
                                 'P',
                                 l_pan_code,
                                 l_mbr_numb,
                                 l_const,
                                 SYSDATE,
                                 l_user_code,
                                 l_user_code,
                                 l_user_code,
                                 'Y',
                                 p_card_status_out,
                                 SYSDATE,
                                 'Y',
--                                 l_activation_code,
                                 'Y',
                                 l_lmtprfl,
                                 l_profile_level,
                                 l_card_id,
                                 'V',
                                 'Success',
                                 '0000',
                                 l_key_id,
                                 p_merchant_id_in,         --Added for VMS_7594
                                 p_merchant_name_in,    --Added for VMS_7594
                                 p_store_id_in          --Added for VMS_7594
                                 );
    EXCEPTION
         WHEN OTHERS
         THEN
            p_resp_msg_out :=
               'Error While Inserting Cards :'
               || SUBSTR (SQLERRM, 1, 200);
            p_resp_code_out := '89';
            RAISE excp_error;
   END;

   BEGIN
       INSERT INTO cms_cardissuance_status (ccs_inst_code,
                                            ccs_pan_code,
                                            ccs_card_status,
                                            ccs_ins_user,
                                            ccs_lupd_user,
                                            ccs_pan_code_encr,
                                            ccs_lupd_date,
                                            ccs_appl_code)
                        VALUES (p_inst_code_in,
                                l_pan_code,
                                '15',
                                l_user_code,
                                l_user_code,
                                l_pan_code_encr,
                                SYSDATE,
                                l_appl_code);
                  EXCEPTION
                     WHEN OTHERS
                     THEN
                        p_resp_msg_out :=
                           'Error While Inserting Cards :'
                           || SUBSTR (SQLERRM, 1, 200);
                        p_resp_code_out := '89';
                        RAISE excp_error;
   END;

      BEGIN
        lp_virtual_process(l_product_id,
                           l_pan_code,
                           l_pan_code_encr,
                           l_cust_code,
                           l_acct_id,
                           l_delayed_accessto_firstload_flag,
                           p_proxy_no_out,
                           p_resp_msg_out); 

        IF p_resp_msg_out <> 'OK'
        THEN
            p_resp_msg_out :=
               'Error from lp_virtual_process: '
               || p_resp_msg_out;
            p_resp_code_out := '89';
            RAISE excp_error;
        END IF;  
        EXCEPTION
           WHEN excp_error
           THEN
              RAISE;
           WHEN OTHERS
           THEN
              p_resp_msg_out:= 'Error while calling lp_virtual_process : ' || SUBSTR (SQLERRM, 1, 200);
              p_resp_code_out := '89';
              RAISE excp_error;
   END;

   BEGIN
      p_serial_no_out := SEQ_SERIAL_NO.NEXTVAL;
      EXCEPTION
        WHEN OTHERS
           THEN
              p_resp_msg_out:= 'Error while generating serial : ' || SUBSTR (SQLERRM, 1, 200);
              p_resp_code_out := '89';
              RAISE excp_error;
   END;

   BEGIN
      UPDATE cms_appl_pan 
         SET cap_serial_number = p_serial_no_out,
             cap_proxy_number = p_proxy_no_out
       WHERE cap_pan_code = l_pan_code
         AND cap_mbr_numb = l_mbr_numb;
      EXCEPTION
           WHEN OTHERS
           THEN
              p_resp_msg_out :=
                 'Error While updating serial number and proxy number :'
                 || SUBSTR (SQLERRM, 1, 200);
              p_resp_code_out := '89';                 
              RAISE excp_error;
   END;

   IF l_txn_redmption_flag='Y' AND l_redmption_delay_flag='Y' THEN
      BEGIN
         vmsredemptiondelay.redemption_delay (l_acct_no,
                              p_rrn_in,
                              p_delivery_channel_in,
                              p_tran_code_in,
                              l_txn_amt,
                              p_prod_code_in,
                              p_card_type_in,
                              UPPER (p_merchant_name_in),
                              p_postal_code_in,--added for VMS-622 (redemption_delay zip code validation)
                              p_resp_msg_out);
          IF p_resp_msg_out <> 'OK' THEN
               p_resp_code_out := '21';
               RAISE  excp_error;
          END IF;
      EXCEPTION
         WHEN excp_error THEN
           RAISE;
         WHEN OTHERS
         THEN
            p_resp_msg_out :=
               'Error while calling sp_log_delayed_load: '
               || SUBSTR (SQLERRM, 1, 200);
            p_resp_code_out := '21';
            RAISE excp_error;
      END;
   END IF;

   BEGIN
        UPDATE cms_acct_mast
           SET cam_acct_bal = l_txn_amt,
               cam_ledger_bal = l_txn_amt,
               cam_initialload_amt = l_txn_amt,
               cam_first_load_date = sysdate,
               cam_initamt_flag = 'Y'
         WHERE cam_inst_code = p_inst_code_in
           AND cam_acct_no = l_acct_no;
       EXCEPTION
       WHEN OTHERS
       THEN
          p_resp_msg_out :=
             'Error While updating acct mast:'
             || SUBSTR (SQLERRM, 1, 200);
         p_resp_code_out := '89';
          RAISE excp_error;
   END;

   p_acct_balance_out := l_txn_amt;

   BEGIN
        p_auth_id_out := LPAD (seq_auth_id.NEXTVAL, 6, '0');
        l_timestamp := SYSTIMESTAMP;
        l_hashkey_id :=
           gethash (
                 p_delivery_channel_in
              || p_tran_code_in
              || fn_dmaps_main (l_pan_code_encr)
              || p_rrn_in
              || TO_CHAR (l_timestamp, 'YYYYMMDDHH24MISSFF5'));
        l_narration :=
              l_tran_desc
           || '/'
           || TO_CHAR (SYSDATE, 'yyyymmdd')
           || '/'
           || p_auth_id_out;

        INSERT INTO cms_statements_log (csl_pan_no,
                                        csl_opening_bal,
                                        csl_trans_amount,
                                        csl_trans_type,
                                        csl_trans_date,
                                        csl_closing_balance,
                                        csl_trans_narrration,
                                        csl_pan_no_encr,
                                        csl_rrn,
                                        csl_auth_id,
                                        csl_business_date,
                                        csl_business_time,
                                        txn_fee_flag,
                                        csl_delivery_channel,
                                        csl_inst_code,
                                        csl_txn_code,
                                        csl_ins_date,
                                        csl_ins_user,
                                        csl_acct_no,
                                        csl_panno_last4digit,
                                        csl_time_stamp,
                                        csl_prod_code,
                                        csl_card_type)
             VALUES (
                       l_pan_code,
                       0,
                       l_txn_amt,
                       l_drcr_flag,
                       SYSDATE,
                       l_txn_amt,
                       l_narration,
                       l_pan_code_encr,
                       p_rrn_in,
                       p_auth_id_out,
                       p_business_date_in,
                       p_business_time_in,
                       'N',
                       p_delivery_channel_in,
                       p_inst_code_in,
                       p_tran_code_in,
                       SYSDATE,
                       1,
                       l_acct_no,
                       SUBSTR (
                          fn_dmaps_main (
                             l_pan_code_encr),
                          -4),
                       l_timestamp,
                       p_prod_code_in,
                       p_card_type_in);
       EXCEPTION
          WHEN OTHERS
          THEN
             p_resp_msg_out :=
                'Error While logging initial_load txn :'
                || SUBSTR (SQLERRM, 1, 200);
             p_resp_code_out := '89';   
              RAISE excp_error;
   END;

   BEGIN 
       INSERT INTO cms_spilserial_logging
                   (csl_inst_code,
                    csl_pan_code,
                    csl_delivery_channel,
                    csl_txn_code,
                    csl_msg_type,
                    csl_serial_number,
                    csl_auth_id,
                    csl_response_code,
                    csl_rrn,
                    csl_time_stamp,
                    csl_reversal_flag
                   )
            VALUES (1,
                    l_pan_code,
                    p_delivery_channel_in,
                    p_tran_code_in,
                    p_msg_typ_in,
                    p_serial_no_out,
                    p_auth_id_out,
                    '00',
                    p_rrn_in,
                    l_timestamp,
                    'N'
                   ) ;
       EXCEPTION
          WHEN OTHERS
          THEN
             p_resp_msg_out :=
                'Error While logging initial_load txn :'
                || SUBSTR (SQLERRM, 1, 200);
             p_resp_code_out := '89';    
              RAISE excp_error;

   END;
     p_resp_code_out := '1';

     IF p_resp_msg_out = 'OK'
     THEN
         p_resp_msg_out := 'Success';
     END IF;

EXCEPTION
   WHEN excp_error
   THEN
       ROLLBACK;
   WHEN OTHERS
   THEN
       ROLLBACK;
       p_resp_msg_out :=
               'Error while processing Sale Active Code Order:'
               || SUBSTR (SQLERRM, 1, 200);
       p_resp_code_out := '89';        

END;

 --- Added for VMS-2888 - VPS_AVAIL_CARDS Column on VMS_PANGEN_SUMMARY					 

  IF l_cntrl_flag ='Y'
  THEN 

  IF p_resp_msg_out not in ('OK','Success')
  THEN 


    UPDATE cms_appl_pan_inv
         SET cap_issue_stat = 'E'
       WHERE cap_pan_code = l_pan_code; 

  END IF;

   BEGIN     --- Modified for VMS-3066 - Product Setup re-Vamp - BIN.

        vmsb2bapi.UPDATE_PANGEN_SUMMARY(	p_prod_code_in,
							p_card_type_in,
							l_start_control_number ,
							l_end_control_number ,
							l_error_msg );

                IF l_error_msg <> 'OK' THEN
                    RAISE excp_error;
                END IF;
     EXCEPTION
		WHEN excp_error THEN
           l_remark := 'Error while updating pangen summary table for failure records';
--			p_resp_code_out := '89';
        WHEN OTHERS
        THEN
           l_remark := 'Error while updating pangen summary table for failure records';
--           l_error_msg :=
--              'Problem while updating the avail card in pan gen summary-'
--              || p_resp_msg_out
--              || SUBSTR (SQLERRM, 1, 200);
--           p_resp_code_out := '89';
     END;

	END IF;

     --- Ended for VMS-2888 - VPS_AVAIL_CARDS Column on VMS_PANGEN_SUMMARY					 

    BEGIN
        SELECT cms_iso_respcde
          INTO p_resp_code_out
          FROM cms_response_mast
         WHERE     cms_inst_code = p_inst_code_in
               AND cms_delivery_channel = p_delivery_channel_in
               AND cms_response_id = TO_NUMBER (p_resp_code_out);
     EXCEPTION
        WHEN OTHERS
        THEN
           p_resp_msg_out :=
              'Problem while selecting data from response master for respose code-'
              || p_resp_msg_out
              || SUBSTR (SQLERRM, 1, 200);
           p_resp_code_out := '89';
     END;         

    BEGIN
          INSERT INTO transactionlog (msgtype,
                                rrn,
                                delivery_channel,
                                date_time,
                                txn_code,
                                txn_mode,
                                txn_type,
                                txn_status,
                                response_code,
                                business_date,
                                business_time,
                                customer_card_no,
                                total_amount,
                                productid,
                                categoryid,
                                auth_id,
                                trans_desc,
                                amount,
                                instcode,
                                tranfee_amt,
                                cr_dr_flag,
                                customer_card_no_encr,
                                reversal_code,
                                customer_acct_no,
                                acct_balance,
                                ledger_balance,
                                response_id,
                                add_ins_date,
                                add_ins_user,
                                cardstatus,
                                error_msg,
                                time_stamp,
                                terminal_id,
                                currencycode,
                                merchant_name, 
                                store_id,
                                spil_fee,
                                spil_upc,
                                spil_merref_num,
                                spil_req_tmzm,
                                spil_loc_cntry,
                                spil_loc_crcy,
                                spil_loc_lang,
                                spil_pos_entry,
                                spil_pos_cond,
                                proxy_number,
                                MERCHANT_ZIP)--added for VMS-622 (redemption_delay zip code validation)
         VALUES (p_msg_typ_in,
                 p_rrn_in,
                 p_delivery_channel_in,
                 SYSDATE,
                 p_tran_code_in,
                 p_tran_mode_in,
                 1,
                 DECODE (p_resp_code_out, '00', 'C', 'F'),
                 p_resp_code_out,
                 p_business_date_in,
                 p_business_time_in,
                 l_pan_code,
                 l_txn_amt,
                 p_prod_code_in,
                 p_card_type_in,
                 p_auth_id_out,
                 l_tran_desc,
                 l_txn_amt,
                 p_inst_code_in,
                 '0.00',
                 l_drcr_flag,
                 l_pan_code_encr,
                 p_reversal_code_in,
                 l_acct_no,
                 l_txn_amt,
                 l_txn_amt,
                 1,
                 SYSDATE,
                 1,
                 '1',
                 p_resp_msg_out,
                 l_timestamp,
                 p_term_id_in,
                 l_currcode,
                 p_merchant_name_in,
                 p_store_id_in,
                 p_fee_amt_in,
                 p_upc_in,
                 p_mercrefnum_in,
                 p_reqtimezone_in, 
                 p_localcountry_in,
                 p_localcurrency_in,
                 p_loclanguage_in,
                 p_posentry_in,
                 p_poscond_in,
                 p_proxy_no_out,
                 p_postal_code_in);--added for VMS-622 (redemption_delay zip code validation)

          INSERT
            INTO cms_transaction_log_dtl (
                    ctd_delivery_channel,
                    ctd_txn_code,
                    ctd_txn_type,
                    ctd_txn_mode,
                    ctd_business_date,
                    ctd_business_time,
                    ctd_customer_card_no,
                    ctd_txn_amount,
                    ctd_actual_amount,
                    ctd_bill_amount,
                    ctd_process_flag,
                    ctd_process_msg,
                    ctd_rrn,
                    ctd_customer_card_no_encr,
                    ctd_msg_type,
                    ctd_cust_acct_number,
                    ctd_inst_code,
                    ctd_hashkey_id,
                    ctd_txn_curr,
                    ctd_store_address1,
                    ctd_store_address2,
                    ctd_store_city,
                    ctd_store_state,
                    ctd_store_zip)
          VALUES (p_delivery_channel_in,
                  p_tran_code_in,
                  1,
                  p_tran_mode_in,
                  p_business_date_in,
                  p_business_time_in,
                  l_pan_code,
                  l_txn_amt,
                  l_txn_amt,
                  l_txn_amt,
                  DECODE (p_resp_code_out, '00', 'Y', 'E'),
                  p_resp_msg_out,
                  p_rrn_in,
                  l_pan_code_encr,
                  p_msg_typ_in,
                  l_acct_no,
                  p_inst_code_in,
                  l_hashkey_id,
                  l_currcode,
                  p_store_addr1_in,
                  p_store_addr2_in,
                  p_store_city_in,
                  p_store_state_in,
                  p_postal_code_in);
       EXCEPTION
          WHEN OTHERS
          THEN
             p_resp_msg_out :=
                'Error While logging initial_load txn :'
                || SUBSTR (SQLERRM, 1, 200);
             p_resp_code_out := '89';
   END;
  END SALE_ACTIVE_CODE_REQ;

  PROCEDURE SALE_ACTIVE_CODE_REV(
    p_inst_code_in                 IN VARCHAR2, 
    p_msg_typ_in                   IN VARCHAR2,
    p_rrn_in                       IN VARCHAR2,
    p_delivery_channel_in          IN VARCHAR2,
    p_term_id_in                   IN VARCHAR2,
    p_tran_code_in                 IN VARCHAR2,
    p_tran_mode_in                 IN VARCHAR2,
    p_business_date_in             IN VARCHAR2,
    p_business_time_in             IN VARCHAR2,
    p_curr_code_in                 IN VARCHAR2,
    p_reversal_code_in             IN VARCHAR2,
    p_prod_code_in                 IN VARCHAR2,
    p_card_type_in                 IN VARCHAR2,
    p_package_id_in                IN VARCHAR2,
    p_tran_amount_in               IN NUMBER,
    p_merchant_name_in             IN VARCHAR2,
    p_store_id_in                  IN VARCHAR2,
    p_store_addr1_in               IN VARCHAR2,
    p_store_addr2_in               IN VARCHAR2,
    p_store_city_in                IN VARCHAR2,
    p_store_state_in               IN VARCHAR2,
    p_postal_code_in               IN VARCHAR2,
    p_fee_amt_in                   IN VARCHAR2,
    p_upc_in                       IN VARCHAR2,
    p_mercrefnum_in                IN VARCHAR2,
    p_reqtimezone_in               IN VARCHAR2,
    p_localcountry_in              IN VARCHAR2,
    p_localcurrency_in             IN VARCHAR2,
    p_loclanguage_in               IN VARCHAR2,
    p_posentry_in                  IN VARCHAR2,
    p_poscond_in                   IN VARCHAR2,
    p_resp_msg_out                 OUT VARCHAR2,
    p_resp_code_out                OUT VARCHAR2,
    p_acct_balance_out             OUT NUMBER,
    p_auth_id_out                  OUT VARCHAR2,
    p_serial_no_out                OUT VARCHAR2,
    p_proxy_no_out                 OUT VARCHAR2,
    p_pan_number_out               OUT VARCHAR2,
    p_card_status_out              OUT VARCHAR2
    ) AS
    l_tran_desc                 cms_transaction_mast.ctm_tran_desc%TYPE;
    l_acct_no                   cms_acct_mast.cam_acct_no%TYPE;
	  l_pan_code				          cms_appl_pan.cap_pan_code%TYPE;
	  l_pan_code_encr             cms_appl_pan.cap_pan_code_encr%TYPE;
    l_timestamp                 TIMESTAMP;
    l_hashkey_id                cms_transaction_log_dtl.ctd_hashkey_id%TYPE;
    l_narration                 cms_statements_log.csl_trans_narrration%TYPE;
    excp_error                  EXCEPTION;
    l_currcode                  transactionlog.currencycode%TYPE;
    l_tran_reverse_flag         transactionlog.tran_reverse_flag%TYPE;
    l_orgnl_resp_code          transactionlog.response_code%TYPE;
    l_bin                       cms_prod_bin.cpb_inst_bin%TYPE;
    l_mbr_numb                  VARCHAR2 (5) := '000';
    l_amount                    number := 0;
    l_txn_amt                   cms_statements_log.CSL_TRANS_AMOUNT%TYPE; 
    l_balcount                  NUMBER; --Added for VMS-6477 Fraud issue

BEGIN
  BEGIN
   p_resp_msg_out := 'OK';
   l_txn_amt := ROUND (p_tran_amount_in,2);
   BEGIN
        SELECT ctm_tran_desc
          INTO l_tran_desc
          FROM cms_transaction_mast
         WHERE ctm_inst_code = p_inst_code_in
           AND ctm_delivery_channel = p_delivery_channel_in
           AND ctm_tran_code = p_tran_code_in;
     EXCEPTION
        WHEN OTHERS
        THEN
           p_resp_msg_out :=
              'Error While Transaction Details:'
              || SUBSTR (SQLERRM, 1, 200);
           p_resp_code_out := '89';
           RAISE excp_error;
   END;

   BEGIN
       SELECT csl_reversal_flag, 
              csl_response_code,
              csl_pan_code
         INTO l_tran_reverse_flag, 
              l_orgnl_resp_code,
              l_pan_code
         FROM cms_spilserial_logging
        WHERE csl_rrn = p_rrn_in 
          AND csl_inst_code = p_inst_code_in 
          AND csl_delivery_channel = p_delivery_channel_in
          AND csl_txn_code = p_tran_code_in
          AND csl_msg_type = '1200';
        EXCEPTION
           WHEN no_data_found THEN
             p_resp_code_out := '67';
             p_resp_msg_out   := 'Matching transaction not found';
             RAISE excp_error;
           WHEN too_many_rows THEN
             p_resp_code_out := '89';
             p_resp_msg_out   := 'More than one matching record found in the master';
             RAISE excp_error;
           WHEN OTHERS THEN
             p_resp_code_out := '89';
             p_resp_msg_out   := 'Error while selecting master data' ||
                  substr(SQLERRM, 1, 200);
             RAISE excp_error;  
   END;

   IF l_orgnl_resp_code <> '00'
   THEN
       p_resp_code_out := '53';
       p_resp_msg_out   := ' The original transaction was not successful';
       RAISE excp_error;
   END IF;

   IF l_tran_reverse_flag = 'Y' THEN
      p_resp_code_out := '52';
      p_resp_msg_out   := 'Already Reversed';
      RAISE excp_error;  
   END IF;      


   BEGIN
      SELECT gcm_curr_code
        INTO l_currcode
        FROM gen_curr_mast
       WHERE gcm_inst_code = p_inst_code_in
             AND gcm_curr_name = p_curr_code_in;
   EXCEPTION
      WHEN OTHERS
      THEN
         p_resp_code_out := '89';
         p_resp_msg_out :=
               'Error while selecting the currency code for '
            || p_curr_code_in
            || ' is-'
            || SUBSTR (SQLERRM, 1, 200);
         RAISE excp_error;
   END;

   BEGIN
      SELECT cap_pan_code_encr,
             cap_acct_no,
             cap_proxy_number,
             cap_serial_number
        INTO l_pan_code_encr,
             l_acct_no,
             p_proxy_no_out,
             p_serial_no_out
        FROM cms_appl_pan
       WHERE cap_pan_code = l_pan_code
         AND cap_mbr_numb = l_mbr_numb;
   EXCEPTION
      WHEN OTHERS
      THEN
         p_resp_code_out := '89';
         p_resp_msg_out :=
               'Error while selecting the Pan details  '
            || SUBSTR (SQLERRM, 1, 200);
         RAISE excp_error;
   END;


   --SN: Added for VMS-6477 Fraud issue
   BEGIN
    SELECT COUNT(*)
      INTO l_balcount
      FROM cms_acct_mast
    WHERE cam_inst_code = p_inst_code_in
      AND cam_acct_no = l_acct_no
      AND cam_acct_bal != cam_ledger_bal;
  EXCEPTION
    WHEN OTHERS THEN
        p_resp_code_out := '89';
        p_resp_msg_out := 'Error while selecting the BALANCE FROM  ACCT MAST details  '|| substr(sqlerrm,1,200);
        RAISE excp_error;
  END;

  IF l_balcount > 0 THEN
      p_resp_code_out := '18';
      p_resp_msg_out := ' Card is Redeemed ';
      RAISE excp_error;
  END IF;
  --EN: Added for VMS-6477 Fraud issue

   p_pan_number_out := fn_dmaps_main(l_pan_code_encr);   

   BEGIN
      UPDATE cms_appl_pan
         SET cap_card_stat = '9'
       WHERE cap_pan_code = l_pan_code
         AND cap_mbr_numb = l_mbr_numb;

       EXCEPTION
         WHEN OTHERS
         THEN
            p_resp_msg_out :=
               'Error While updating card status :'
               || SUBSTR (SQLERRM, 1, 200);
            p_resp_code_out := '89';
   END;

   p_card_status_out := '9';

   BEGIN
       sp_log_cardstat_chnge (p_inst_code_in,
                              l_pan_code,
                              l_pan_code_encr,
                              LPAD (seq_auth_id.NEXTVAL, 6, '0'),
                              '02',
                              NULL,
                              NULL,
                              NULL,
                              p_resp_code_out,
                              p_resp_msg_out,
                              'Closed due to sale code active revesal');

       IF p_resp_msg_out <> 'OK'
       THEN
          p_resp_code_out := '89';
          p_resp_msg_out :=
             'Error while logging card close status' || p_resp_msg_out;
           RAISE excp_error;
       END IF;
    EXCEPTION
       WHEN excp_error
       THEN
           RAISE; 
       WHEN OTHERS
       THEN
          p_resp_msg_out :=
             'Error While ogging card close status: '
             || SUBSTR (SQLERRM, 1, 200);
             p_resp_code_out := '89';
              RAISE excp_error;
   END;

   BEGIN
       UPDATE cms_acct_mast
          SET cam_acct_bal = l_amount,
              cam_ledger_bal = l_amount
        WHERE cam_inst_code = p_inst_code_in
          AND cam_acct_no = l_acct_no;
       EXCEPTION
       WHEN OTHERS
       THEN
          p_resp_msg_out :=
             'Error While updating acct mast:'
             || SUBSTR (SQLERRM, 1, 200);
         p_resp_code_out := '89';
          RAISE excp_error;
   END;

   p_acct_balance_out := l_amount;

   BEGIN
        p_auth_id_out := LPAD (seq_auth_id.NEXTVAL, 6, '0');
        l_timestamp := SYSTIMESTAMP;
        l_hashkey_id :=
           gethash (
                 p_delivery_channel_in
              || p_tran_code_in
              || fn_dmaps_main (l_pan_code_encr)
              || p_rrn_in
              || TO_CHAR (l_timestamp, 'YYYYMMDDHH24MISSFF5'));
        l_narration :=
             'RVSL-' || l_tran_desc
           || '/'
           || TO_CHAR (SYSDATE, 'yyyymmdd')
           || '/'
           || p_auth_id_out;

        INSERT INTO cms_statements_log (csl_pan_no,
                                        csl_opening_bal,
                                        csl_trans_amount,
                                        csl_trans_type,
                                        csl_trans_date,
                                        csl_closing_balance,
                                        csl_trans_narrration,
                                        csl_pan_no_encr,
                                        csl_rrn,
                                        csl_auth_id,
                                        csl_business_date,
                                        csl_business_time,
                                        txn_fee_flag,
                                        csl_delivery_channel,
                                        csl_inst_code,
                                        csl_txn_code,
                                        csl_ins_date,
                                        csl_ins_user,
                                        csl_acct_no,
                                        csl_panno_last4digit,
                                        csl_time_stamp,
                                        csl_prod_code,
                                        csl_card_type)
             VALUES (
                       l_pan_code,
                       l_txn_amt,
                       l_txn_amt,
                       'DR',
                       SYSDATE,
                       l_amount,
                       l_narration,
                       l_pan_code_encr,
                       p_rrn_in,
                       p_auth_id_out,
                       p_business_date_in,
                       p_business_time_in,
                       'N',
                       p_delivery_channel_in,
                       p_inst_code_in,
                       p_tran_code_in,
                       SYSDATE,
                       1,
                       l_acct_no,
                       SUBSTR (
                          fn_dmaps_main (
                             l_pan_code_encr),
                          -4),
                       l_timestamp,
                       p_prod_code_in,
                       p_card_type_in);
       EXCEPTION
          WHEN OTHERS
          THEN
             p_resp_msg_out :=
                'Error While logging initial_load txn :'
                || SUBSTR (SQLERRM, 1, 200);
             p_resp_code_out := '89';      
              RAISE excp_error;
   END;


     BEGIN
       UPDATE cms_spilserial_logging
          SET csl_reversal_flag = 'Y'
        WHERE csl_rrn = p_rrn_in 
          AND csl_inst_code = p_inst_code_in 
          AND csl_delivery_channel = p_delivery_channel_in
          AND csl_txn_code = p_tran_code_in
          AND csl_msg_type = '1200';

       IF SQL%ROWCOUNT = 0
       THEN
          p_resp_code_out := '89';
          p_resp_msg_out   := 'Reverse flag is not updated in cms_spilserial_logging ';
          RAISE excp_error;
       END IF;

       EXCEPTION
           WHEN excp_error THEN
              RAISE;
           WHEN OTHERS THEN
                p_resp_code_out := '89';
                p_resp_msg_out   := 'Error while updating gl flag ' ||
                        substr(SQLERRM, 1, 200);
                RAISE excp_error;
     END;

     p_resp_code_out := '1';

     IF p_resp_msg_out = 'OK'
     THEN
         p_resp_msg_out := 'Success';
     END IF;

EXCEPTION
   WHEN excp_error
   THEN
       ROLLBACK;
   WHEN OTHERS
   THEN
       ROLLBACK;
       p_resp_msg_out :=
               'Error while processing Sale Active Code Order:'
               || SUBSTR (SQLERRM, 1, 200);
       p_resp_code_out := '89';        

END;
    BEGIN
        SELECT cms_iso_respcde
          INTO p_resp_code_out
          FROM cms_response_mast
         WHERE     cms_inst_code = p_inst_code_in
               AND cms_delivery_channel = p_delivery_channel_in
               AND cms_response_id = TO_NUMBER (p_resp_code_out);
     EXCEPTION
        WHEN OTHERS
        THEN
           p_resp_msg_out :=
              'Problem while selecting data from response master for respose code-'
              || p_resp_msg_out
              || SUBSTR (SQLERRM, 1, 200);
           p_resp_code_out := '89';
     END;         

    BEGIN
          INSERT INTO transactionlog (msgtype,
                                rrn,
                                delivery_channel,
                                date_time,
                                txn_code,
                                txn_mode,
                                txn_type,
                                txn_status,
                                response_code,
                                business_date,
                                business_time,
                                customer_card_no,
                                total_amount,
                                productid,
                                categoryid,
                                auth_id,
                                trans_desc,
                                amount,
                                instcode,
                                tranfee_amt,
                                cr_dr_flag,
                                customer_card_no_encr,
                                reversal_code,
                                customer_acct_no,
                                acct_balance,
                                ledger_balance,
                                response_id,
                                add_ins_date,
                                add_ins_user,
                                cardstatus,
                                error_msg,
                                time_stamp,
                                terminal_id,
                                currencycode,
                                merchant_name, 
                                store_id,
                                spil_fee,
                                spil_upc,
                                spil_merref_num,
                                spil_req_tmzm,
                                spil_loc_cntry,
                                spil_loc_crcy,
                                spil_loc_lang,
                                spil_pos_entry,
                                spil_pos_cond,
                                proxy_number)
         VALUES (p_msg_typ_in,
                 p_rrn_in,
                 p_delivery_channel_in,
                 SYSDATE,
                 p_tran_code_in,
                 p_tran_mode_in,
                 1,
                 DECODE (p_resp_code_out, '00', 'C', 'F'),
                 p_resp_code_out,
                 p_business_date_in,
                 p_business_time_in,
                 l_pan_code,
                 l_txn_amt,
                 p_prod_code_in,
                 p_card_type_in,
                 p_auth_id_out,
                 l_tran_desc,
                 l_txn_amt,
                 p_inst_code_in,
                 '0.00',
                 'DR',
                 l_pan_code_encr,
                 p_reversal_code_in,
                 l_acct_no,
                 l_amount,
                 l_amount,
                 1,
                 SYSDATE,
                 1,
                 '1',
                 p_resp_msg_out,
                 l_timestamp,
                 p_term_id_in,
                 l_currcode,
                 p_merchant_name_in,
                 p_store_id_in,
                 p_fee_amt_in,
                 p_upc_in,
                 p_mercrefnum_in,
                 p_reqtimezone_in, 
                 p_localcountry_in,
                 p_localcurrency_in,
                 p_loclanguage_in,
                 p_posentry_in,
                 p_poscond_in,
                 p_proxy_no_out);

          INSERT
            INTO cms_transaction_log_dtl (
                    ctd_delivery_channel,
                    ctd_txn_code,
                    ctd_txn_type,
                    ctd_txn_mode,
                    ctd_business_date,
                    ctd_business_time,
                    ctd_customer_card_no,
                    ctd_txn_amount,
                    ctd_actual_amount,
                    ctd_bill_amount,
                    ctd_process_flag,
                    ctd_process_msg,
                    ctd_rrn,
                    ctd_customer_card_no_encr,
                    ctd_msg_type,
                    ctd_cust_acct_number,
                    ctd_inst_code,
                    ctd_hashkey_id,
                    ctd_txn_curr,
                    ctd_store_address1,
                    ctd_store_address2,
                    ctd_store_city,
                    ctd_store_state,
                    ctd_store_zip)
          VALUES (p_delivery_channel_in,
                  p_tran_code_in,
                  1,
                  p_tran_mode_in,
                  p_business_date_in,
                  p_business_time_in,
                  l_pan_code,
                  l_txn_amt,
                  l_txn_amt,
                  l_txn_amt,
                  DECODE (p_resp_code_out, '00', 'Y', 'E'),
                  p_resp_msg_out,
                  p_rrn_in,
                  l_pan_code_encr,
                  p_msg_typ_in,
                  l_acct_no,
                  p_inst_code_in,
                  l_hashkey_id,
                  l_currcode,
                  p_store_addr1_in,
                  p_store_addr2_in,
                  p_store_city_in,
                  p_store_state_in,
                  p_postal_code_in);
       EXCEPTION
          WHEN OTHERS
          THEN
             p_resp_msg_out :=
                'Error While logging initial_load txn :'
                || SUBSTR (SQLERRM, 1, 200);
             p_resp_code_out := '89';
   END;
END  SALE_ACTIVE_CODE_REV;
END VMS_SPIL_VIRTUAL;

/
show error;