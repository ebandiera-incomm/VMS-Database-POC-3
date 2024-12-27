create or replace
PROCEDURE               VMSCMS.sp_spil_target_reg (
   p_instcode           IN       NUMBER,
   p_rrn                IN       VARCHAR2,
   p_terminalid         IN       VARCHAR2,
   p_stan               IN       VARCHAR2,
   p_trandate           IN       VARCHAR2,
   p_trantime           IN       VARCHAR2,
   p_card_no            IN       VARCHAR2,
   p_amount             IN       NUMBER,
   p_currcode           IN       VARCHAR2,
   p_lupduser           IN       NUMBER,
   p_msg_type           IN       VARCHAR2,
   p_txn_code           IN       VARCHAR2,
   p_txn_mode           IN       VARCHAR2,
   p_delivery_channel   IN       VARCHAR2,
   p_mbr_numb           IN       VARCHAR2,
   p_rvsl_code          IN       VARCHAR2,
   p_ssn                IN       VARCHAR2,
   p_dob                IN       DATE,
   p_first_name         IN       VARCHAR2,
   p_middle_name        IN       VARCHAR2,
   p_last_name          IN       VARCHAR2,
   p_addr_lineone       IN       VARCHAR2,
   p_addr_linetwo       IN       VARCHAR2,
   p_city               IN       VARCHAR2,
   p_zip                IN       VARCHAR2,
   p_phone_no           IN       VARCHAR2,
   p_other_no           IN       VARCHAR2,
   p_email              IN       VARCHAR2,
   p_state              IN       VARCHAR2,
   p_cntry_code         IN       VARCHAR2,
   p_merchant_name      IN       VARCHAR2,
   p_merchant_city      IN       VARCHAR2,
   p_store_address1     IN       VARCHAR2,
   p_store_address2     IN       VARCHAR2,
   p_store_city         IN       VARCHAR2,
   p_store_state        IN       VARCHAR2,
   p_store_zip          IN       VARCHAR2,
   p_kyc_stat           IN       VARCHAR2,
   p_pin_flag           IN       VARCHAR2,
   p_optn_phon2         IN       VARCHAR2,
   p_optn_email         IN       VARCHAR2,
   p_resp_code          OUT      VARCHAR2,
   p_errmsg             OUT      VARCHAR2,
   p_auth_id            OUT      VARCHAR2
)
AS
   /********************************************************************************************
      * Created By       : Pankaj S.
      * Created  Date    : 05-Sep-2013
      * Created  Reason  : Created for SPIL target registration
      * Reviewer         : Dhiraj
      * Reviewed Date    : 11-sep-2013
      * Build Number     : RI0024.4_B0009

      * Modified by      :  Pankaj S.
      * Reason           :  To log verification ID into txnlog dtl table
      * Created Date     :  20-Sep-2013
      * Reviewer         :  Dhiraj
      * Reviewed Date    :
      * Build Number     :  RI0024.4_B0017
      
      * Modified by      :  Pankaj S.
      * Reason           :  Review observations changes
      * Created Date     :  25-Sep-2013
      * Reviewer         :  Dhiraj
      * Reviewed Date    :
      * Build Number     :  RI0024.4_B0018
      
       * Modified by       :Siva kumar 
       * Modified Date    : 22-Mar-16
       * Modified For     : MVHOST-1323
       * Reviewer         : Saravanankumar/Pankaj
       * Build Number     : VMSGPRHOSTCSD_4.0_B006
	   
       	 * Modified By      : Sreeja D
     * Modified Date    : 25/01/2018
     * Purpose          : VMS-162
     * Reviewer         : SaravanaKumar A/Vini Pushkaran
     * Release Number   : VMSGPRHOST18.01
	 
	 * Modified By      : Saravana Kumar.A
     * Modified Date    : 24-DEC-2021
     * Purpose          : VMS-5378 : Need to update ccm_system_generate_profile flag in Retail / Card stock flow.
     * Reviewer         : Venkat. S
     * Release Number   : VMSGPRHOST_R56 Build 2.
	 
	* Modified By      : Karthick
    * Modified Date    : 06-28-2022
    * Purpose          : Archival changes.
    * Reviewer         : Venkat Singamaneni
    * Release Number   : VMSGPRHOST65 for VMS-5739/FSP-991

   ************************************************************************************************/
   v_cap_prod_catg            cms_appl_pan.cap_prod_catg%TYPE;
   v_cap_card_stat            cms_appl_pan.cap_card_stat%TYPE;
   v_firsttime_topup          cms_appl_pan.cap_firsttime_topup%TYPE;
   v_hash_pan                 cms_appl_pan.cap_pan_code%TYPE;
   v_encr_pan                 cms_appl_pan.cap_pan_code_encr%TYPE;
   v_mbrnumb                  cms_appl_pan.cap_mbr_numb%TYPE;
   v_proxunumber              cms_appl_pan.cap_proxy_number%TYPE;
   v_acct_number              cms_appl_pan.cap_acct_no%TYPE;
   v_prod_code                cms_appl_pan.cap_prod_code%TYPE;
   v_card_type                cms_appl_pan.cap_card_type%TYPE;
   v_cap_appl_code            cms_appl_pan.cap_appl_code%TYPE;
   v_acct_type                cms_acct_mast.cam_type_code%TYPE;
   v_errmsg                   VARCHAR2 (300);
   v_currcode                 VARCHAR2 (3);
   v_appl_code                cms_appl_mast.cam_appl_code%TYPE;
   v_resoncode                cms_spprt_reasons.csr_spprt_rsncode%TYPE;
   v_respcode                 VARCHAR2 (5);
   v_respmsg                  VARCHAR2 (500);
   v_capture_date             DATE;
   v_txn_code                 cms_func_mast.cfm_txn_code%TYPE;
   v_txn_mode                 cms_func_mast.cfm_txn_mode%TYPE;
   v_del_channel              cms_func_mast.cfm_delivery_channel%TYPE;
   v_txn_type                 cms_transaction_mast.ctm_tran_type%TYPE;
   v_inil_authid              transactionlog.auth_id%TYPE;
   exp_main_reject_record     EXCEPTION;
   exp_auth_reject_record     EXCEPTION;
   v_rrn_count                NUMBER;
   v_remrk                    VARCHAR2 (100);
   v_delchannel_desc          cms_delchannel_mast.cdm_channel_desc%TYPE;
   v_base_curr                cms_inst_param.cip_param_value%TYPE;
   v_tran_date                DATE;
   v_tran_amt                 NUMBER;
   v_card_curr                VARCHAR2 (5);
   v_acct_balance             NUMBER;
   v_ledger_balance           NUMBER;
   v_business_date            DATE;
   V_CUST_CODE                CMS_CUST_MAST.CCM_CUST_CODE%TYPE;
   v_addr_lineone             cms_addr_mast.cam_add_one%TYPE; 
   v_addr_linetwo             cms_addr_mast.cam_add_two%TYPE; 
   v_city_name                cms_addr_mast.cam_city_name%TYPE; 
   v_pin_code                 cms_addr_mast.cam_pin_code%TYPE; 
   v_phone_no                 cms_addr_mast.cam_phone_one%TYPE; 
   v_mobl_no                  cms_addr_mast.cam_mobl_one%TYPE; 
   v_email                    cms_addr_mast.cam_email%TYPE; 
   v_state_code               NUMBER (3);
   v_ctnry_code               NUMBER (3);
   v_ssn                      VARCHAR2 (10);
   V_BIRTH_DATE               DATE;
   v_first_name               cms_cust_mast.ccm_first_name%TYPE; 
   v_mid_name                 cms_cust_mast.ccm_mid_name%TYPE; 
   v_last_name                cms_cust_mast.ccm_last_name%TYPE; 
   v_dr_cr_flag               VARCHAR2 (2);
   v_output_type              VARCHAR2 (2);
   v_tran_type                VARCHAR2 (2);
   v_trans_desc               cms_transaction_mast.ctm_tran_desc%TYPE;
   v_prfl_flag                cms_transaction_mast.ctm_prfl_flag%TYPE;
   v_merv_count               NUMBER;
   v_phys_switch_state_code   cms_addr_mast.cam_state_switch%TYPE;
   v_curr_code                gen_cntry_mast.gcm_curr_code%TYPE;
   v_ssn_crddtls              transactionlog.ssn_fail_dtls%TYPE;
   v_set_cardstat             VARCHAR2(5);
   v_encrypt_enable           cms_prod_cattype.cpc_encrypt_enable%TYPE;
   v_encr_addr_lineone 		  cms_addr_mast.CAM_ADD_ONE%type;
   v_encr_addr_linetwo 		  cms_addr_mast.CAM_ADD_TWO%type;
   v_encr_city         		  cms_addr_mast.CAM_CITY_NAME%type;
   v_encr_email       		  cms_addr_mast.CAM_EMAIL%type;
   v_encr_phone_no    		  cms_addr_mast.CAM_PHONE_ONE%type;
   V_ENCR_MOB_ONE     		  CMS_ADDR_MAST.CAM_MOBL_ONE%TYPE;
   v_encr_zip         		  cms_addr_mast.CAM_PIN_CODE%type;
   v_encr_first_name   		  cms_cust_mast.CCM_FIRST_NAME%type; 
   v_encr_last_name   		  cms_cust_mast.CCM_LAST_NAME%type;
   v_encr_mid_name    		  cms_cust_mast.CCM_MID_NAME%type;
   v_Retperiod  date;  --Added for VMS-5739/FSP-991
   v_Retdate  date; --Added for VMS-5739/FSP-991
   
BEGIN
   v_errmsg := 'OK';
   v_respcode:='1';
   v_remrk := 'TARGET REGISTRATION';

   --Sn Create Hash PAN
   BEGIN
      v_hash_pan := gethash (p_card_no);
   EXCEPTION
      WHEN OTHERS THEN
         v_errmsg :='Error while converting pan to HASH ' || SUBSTR (SQLERRM, 1, 200);
         RAISE exp_main_reject_record;
   END;
   --En Create Hash PAN

   --Sn Create encr PAN
   BEGIN
      v_encr_pan := fn_emaps_main (p_card_no);
   EXCEPTION
      WHEN OTHERS THEN
         v_errmsg :='Error while converting pan to ENCR ' || SUBSTR (SQLERRM, 1, 200);
         RAISE exp_main_reject_record;
   END;
   --En Create encr PAN

   --Sn Get transaction details
   BEGIN
      SELECT ctm_credit_debit_flag, ctm_output_type,
             TO_NUMBER (DECODE (ctm_tran_type, 'N', '0', 'F', '1')),
             ctm_tran_type, ctm_prfl_flag, ctm_tran_desc
        INTO v_dr_cr_flag, v_output_type,
             v_txn_type,
             v_tran_type, v_prfl_flag, v_trans_desc
        FROM cms_transaction_mast
       WHERE ctm_tran_code = p_txn_code
         AND ctm_delivery_channel = p_delivery_channel
         AND ctm_inst_code = p_instcode;
   EXCEPTION
      WHEN NO_DATA_FOUND THEN
         v_respcode := '12';
         v_errmsg := 'Transaction not defined for txn code '|| p_txn_code|| ' and delivery channel '|| p_delivery_channel;
         RAISE exp_main_reject_record;
      WHEN OTHERS THEN
         v_respcode := '21';
         v_errmsg := 'Error while selecting transaction details '|| SUBSTR (SQLERRM, 1, 200);
         RAISE exp_main_reject_record;
   END;
   --En Get transaction details   

   --Sn Transaction Date-Time Check
   BEGIN
      v_tran_date :=TO_DATE (SUBSTR (TRIM (p_trandate), 1, 8)|| ' '|| SUBSTR (TRIM (p_trantime), 1, 10),'yyyymmdd hh24:mi:ss');
   EXCEPTION
      WHEN OTHERS THEN
         v_respcode := '32';
         v_errmsg :='Problem while converting transaction Time '|| SUBSTR (SQLERRM, 1, 200);
         RAISE exp_main_reject_record;
   END;
   --En Transaction Date-Time Check
   
   v_business_date := TRUNC (v_tran_date);

   --Sn Delivery Channel validation
   BEGIN
      SELECT cdm_channel_desc
        INTO v_delchannel_desc
        FROM cms_delchannel_mast
       WHERE cdm_channel_code = p_delivery_channel
         AND cdm_inst_code = p_instcode;

     IF v_delchannel_desc <> 'SPIL' THEN
         v_respcode := '69';
         v_errmsg := 'Delivery Channel for SPIL not defined in master';
         RAISE exp_main_reject_record;
     END IF; 
   EXCEPTION
      WHEN exp_main_reject_record THEN
           RAISE;
      WHEN NO_DATA_FOUND THEN
         v_respcode := '69';
         v_errmsg := 'Delivery Channel for SPIL not defined in master';
         RAISE exp_main_reject_record;
      WHEN OTHERS THEN
         v_respcode := '21';
         v_errmsg := 'Error while selecting the Delivery Channel of SPIL  ' || SUBSTR (SQLERRM, 1, 200);
         RAISE exp_main_reject_record;
   END;
   --En Delivery Channel validation

   --Sn currncy check
    BEGIN
       SELECT gcm_curr_code
         INTO v_currcode
         FROM gen_curr_mast
        WHERE gcm_curr_name = p_currcode AND gcm_inst_code = p_instcode;
    EXCEPTION
       WHEN NO_DATA_FOUND
       THEN
          v_respcode := '65';
          v_errmsg := 'Invalid Currency Code';
          RAISE exp_main_reject_record;
       WHEN OTHERS
       THEN
          v_respcode := '21';
          v_errmsg :='Error while selecting the currency code for '|| p_currcode|| SUBSTR (SQLERRM, 1, 200);
          RAISE exp_main_reject_record;
    END;
   --En currncy check
   
   --Sn select card detail
   BEGIN
      SELECT cap_card_stat, cap_prod_catg, cap_firsttime_topup,
             cap_mbr_numb, cap_cust_code, cap_proxy_number, cap_acct_no,
             cap_appl_code, cap_prod_code, cap_card_type
        INTO v_cap_card_stat, v_cap_prod_catg, v_firsttime_topup,
             v_mbrnumb, v_cust_code, v_proxunumber, v_acct_number,
             v_cap_appl_code, v_prod_code, v_card_type
        FROM cms_appl_pan
       WHERE cap_inst_code = p_instcode
         AND cap_pan_code = v_hash_pan
         AND cap_mbr_numb = p_mbr_numb;
   EXCEPTION
      WHEN NO_DATA_FOUND THEN
         v_respcode := '6';
         v_errmsg := 'Invalid Card number-' || p_card_no;
         RAISE exp_main_reject_record;
      WHEN OTHERS THEN
         v_respcode := '21';
         v_errmsg := 'Error while selecting card number ' || SUBSTR (SQLERRM, 1, 200);
         RAISE exp_main_reject_record;
   END;
   --En Select card detail

   --Sn Check initial load
   IF v_firsttime_topup = 'Y' AND v_cap_card_stat = '1' THEN
      v_respcode := '9';
      v_errmsg := 'Card Activation Already Done';
      RAISE exp_main_reject_record;
   ELSIF v_cap_card_stat<>'0' THEN
      v_respcode := '69';
      v_errmsg := 'Invalid Card for Registration ';
      RAISE exp_main_reject_record;
   ELSIF v_firsttime_topup IS NULL THEN
      v_respcode := '69';
      v_errmsg := 'Invalid Card Registration ';
      RAISE exp_main_reject_record;
   END IF;
   --En Check initial load

   --Sn get currncy Converted txn amount
   BEGIN
      IF (TO_NUMBER (p_amount) >= 0) THEN
         v_tran_amt := p_amount;
         BEGIN
            sp_convert_curr (p_instcode,
                             v_currcode,
                             p_card_no,
                             p_amount,
                             v_tran_date,
                             v_tran_amt,
                             v_card_curr,
                             v_errmsg,
                             v_prod_code,
                             v_card_type
                            );

               IF v_errmsg <> 'OK' THEN
               v_respcode := '21';
               RAISE exp_main_reject_record;
            END IF;
         EXCEPTION
            WHEN exp_main_reject_record THEN
               RAISE;
            WHEN OTHERS THEN
               v_respcode := '69';
               v_errmsg := 'Error from currency conversion '|| SUBSTR (SQLERRM, 1, 200);
               RAISE exp_main_reject_record;
         END;
      ELSE
         v_respcode := '43';
         v_errmsg := 'INVALID AMOUNT';
         RAISE exp_main_reject_record;
      END IF;
   EXCEPTION
      WHEN exp_main_reject_record THEN
         RAISE;
      WHEN OTHERS THEN
         v_respcode := '21';
         v_errmsg := 'Error in Convert Currency ' || SUBSTR (SQLERRM, 1, 200);
         RAISE exp_main_reject_record;
   END;
   --En get currncy Converted txn amount
    
   IF v_cap_prod_catg = 'P'
   THEN
      --Sn call to authorize txn
      BEGIN
         sp_authorize_txn_cms_auth (p_instcode,
                                    p_msg_type,
                                    p_rrn,
                                    p_delivery_channel,
                                    p_terminalid,
                                    p_txn_code,
                                    p_txn_mode,
                                    p_trandate,
                                    p_trantime,
                                    p_card_no,
                                    NULL,
                                    p_amount,
                                    p_merchant_name,
                                    p_merchant_city,
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
                                    p_stan,
                                    p_mbr_numb,
                                    p_rvsl_code,
                                    v_tran_amt,
                                    v_inil_authid,
                                    v_respcode,
                                    v_respmsg,
                                    v_capture_date
                                   );

         IF v_respcode <> '00' AND v_respmsg <> 'OK' THEN
            v_errmsg := v_respmsg;
            RAISE exp_auth_reject_record;
         ELSE
            v_respcode:='1';   
         END IF;
      EXCEPTION
         WHEN exp_auth_reject_record THEN
            RAISE;
         WHEN OTHERS THEN
            v_respcode := '21';
            v_errmsg := 'Error from Card authorization' || SUBSTR (SQLERRM, 1, 200);
            RAISE exp_main_reject_record;
      END;
      --En call to authorize txn
   END IF;
   
   IF p_pin_flag='Y' THEN
       --Sn multiple SSN check
       BEGIN
          sp_check_ssn_threshold (p_instcode,
                                  p_ssn,
                                  v_prod_code,
                                  v_card_type,
                                  NULL,
                                  v_ssn_crddtls,
                                  v_respcode,
                                  v_respmsg
                                 );

          IF v_respmsg <> 'OK' THEN
             v_respcode := '49'; 
             v_errmsg := SUBSTR (v_respmsg, 1, 200);
             RAISE exp_main_reject_record;
          END IF;
       EXCEPTION
          WHEN exp_main_reject_record THEN
             RAISE;
          WHEN OTHERS THEN
             v_respcode := '21';
             v_errmsg := 'Error from SSN check-' || SUBSTR (SQLERRM, 1, 200);
             RAISE exp_main_reject_record;
       END;
       --En multiple SSN check

       --Sn Activate card
       IF p_kyc_stat='00' THEN
          v_set_cardstat:='1';
          p_errmsg:='Success..,Card Activated';
          v_del_channel:='01';
       ELSE
          v_set_cardstat:='13';
          v_del_channel:='09';
          p_errmsg:='KYC Fail and Card Marked Active Unregisterd';
          p_resp_code:='10182';
       END IF;   
       
       BEGIN
          UPDATE cms_appl_pan
             SET cap_card_stat = v_set_cardstat,
                 cap_active_date = SYSDATE
           WHERE cap_inst_code = p_instcode AND cap_pan_code = v_hash_pan;

          IF SQL%ROWCOUNT = 0 THEN
             v_respcode := '21';
             v_errmsg := 'CARD ACTIVATION DATE / CARD STATUS UPDATION NOT HAPPENED' || '--' || p_card_no;
             RAISE exp_main_reject_record;
          END IF;
       EXCEPTION
          WHEN exp_main_reject_record THEN
             RAISE;
          WHEN OTHERS THEN
             v_respcode := '21';
             v_errmsg := 'ERROR IN CARD ACTIVATION / DATE UPDATION' || '--'|| p_card_no|| '--'|| SUBSTR (SQLERRM, 1, 200);
             RAISE exp_main_reject_record;
       END;
       --En Activate card

       --Sn Log system initiated card status change
       BEGIN
          sp_log_cardstat_chnge (p_instcode,
                                 v_hash_pan,
                                 v_encr_pan,
                                 v_inil_authid,
                                 v_del_channel,
                                 p_rrn,
                                 p_trandate,
                                 p_trantime,
                                 v_respcode,
                                 v_errmsg
                                );

          IF v_respcode <> '00' AND v_errmsg <> 'OK' THEN
             RAISE exp_main_reject_record;
          ELSE
             v_respcode := '1';
          END IF;
       EXCEPTION
          WHEN exp_main_reject_record THEN
             RAISE;
          WHEN OTHERS THEN
             v_respcode := '21';
             v_errmsg :='Error while logging system initiated card status change '|| SUBSTR (SQLERRM, 1, 200);
             RAISE exp_main_reject_record;
       END;
       v_cap_card_stat:=v_set_cardstat;
   END IF;
   --En Log system initiated card status change
   
   --------------------------------------------------
   --Sn Updating Address & customer details
   --------------------------------------------------
    BEGIN
      SELECT gsm_switch_state_code
        INTO v_phys_switch_state_code
        FROM gen_state_mast
       WHERE gsm_state_code = p_state
         AND gsm_cntry_code = p_cntry_code
         AND gsm_inst_code = p_instcode;
   EXCEPTION
      WHEN NO_DATA_FOUND THEN
         v_respcode := '69';
         v_errmsg := 'Invalid Data for Physical Address State' || p_state;
         RAISE exp_main_reject_record;
      WHEN OTHERS THEN
         v_respcode := '21';
         v_errmsg := 'Error while selecting Physical switch state code detail '|| SUBSTR (SQLERRM, 1, 200);
         RAISE exp_main_reject_record;
   END;
   
   BEGIN
     SELECT   CPC_ENCRYPT_ENABLE
       INTO  v_encrypt_enable
       FROM CMS_PROD_CATTYPE
      WHERE CPC_INST_CODE = p_instcode AND
	        CPC_PROD_CODE = v_prod_code AND
            CPC_CARD_TYPE = v_card_type;
    EXCEPTION
     WHEN NO_DATA_FOUND THEN
       v_respcode := '21';
       v_errmsg  := 'No data found in CMS_PROD_CATTYPE for encrpt enable flag' || SUBSTR (SQLERRM, 1, 200);
       RAISE exp_main_reject_record;
     WHEN OTHERS THEN
       v_respcode := '21';
       v_errmsg  := 'Error while selcting encrypt enable flag' || SUBSTR (SQLERRM, 1, 200);
       RAISE exp_main_reject_record;
    END;

   BEGIN
      SELECT 
--	         decode(v_encrypt_enable,'Y', fn_dmaps_main(cam_add_one),cam_add_one), 
--	         decode(v_encrypt_enable,'Y', fn_dmaps_main(cam_add_two),cam_add_two), 
--			 decode(v_encrypt_enable,'Y', fn_dmaps_main(cam_city_name),cam_city_name), 
--			 decode(v_encrypt_enable,'Y', fn_dmaps_main(cam_pin_code),cam_pin_code),
--           decode(v_encrypt_enable,'Y', fn_dmaps_main(cam_phone_one),cam_phone_one), 
--			 decode(v_encrypt_enable,'Y', fn_dmaps_main(cam_mobl_one),cam_mobl_one), 
--			 decode(v_encrypt_enable,'Y', fn_dmaps_main(cam_email),cam_email), 
                         cam_add_one,
			 cam_add_two,
			 cam_city_name,
			 cam_pin_code,
			 cam_phone_one,
			 cam_mobl_one,
			 cam_email,
			 cam_state_code,
             cam_cntry_code
        INTO v_addr_lineone, v_addr_linetwo, v_city_name, v_pin_code,
             v_phone_no, v_mobl_no, v_email, v_state_code,
             v_ctnry_code
        FROM cms_addr_mast
       WHERE cam_cust_code = v_cust_code
         AND cam_inst_code = p_instcode
         AND cam_addr_flag = 'P';
   EXCEPTION
      WHEN NO_DATA_FOUND THEN
         v_respcode := '69';
         v_errmsg :='No data found in addrmast for'|| '-'|| v_cust_code;
         RAISE exp_main_reject_record;
      WHEN OTHERS THEN
         v_respcode := '21';
         v_errmsg := 'Error while selecting address dtls ' || SUBSTR (SQLERRM, 1, 300);
         RAISE exp_main_reject_record;
   END;

   BEGIN
      SELECT nvl(fn_dmaps_main(ccm_ssn_encr),ccm_ssn), 
	         ccm_birth_date, 
--			 decode(v_encrypt_enable,'Y', fn_dmaps_main(ccm_first_name),ccm_first_name), 
--			 decode(v_encrypt_enable,'Y', fn_dmaps_main(ccm_mid_name),ccm_mid_name),
--           decode(v_encrypt_enable,'Y', fn_dmaps_main(ccm_last_name),ccm_last_name)
	         ccm_first_name,
	         ccm_mid_name,
	         ccm_last_name
        INTO v_ssn, v_birth_date, v_first_name, v_mid_name,
             v_last_name
        FROM cms_cust_mast
       WHERE ccm_cust_code = v_cust_code AND ccm_inst_code = p_instcode;
   EXCEPTION
      WHEN NO_DATA_FOUND THEN
         v_respcode := '69';
         v_errmsg :='No data found in custmast for'|| '-'|| v_cust_code;
         RAISE exp_main_reject_record;
      WHEN OTHERS
      THEN
         v_respcode := '21';
         v_errmsg := 'Error while selecting customer dtls ' || SUBSTR (SQLERRM, 1, 200);
         RAISE exp_main_reject_record;
   END;
   
     IF V_ENCRYPT_ENABLE = 'Y' THEN
        v_encr_addr_lineone := fn_emaps_main(p_addr_lineone);
		v_encr_addr_linetwo := fn_emaps_main(p_addr_linetwo);
		v_encr_city         := fn_emaps_main(p_city);
		v_encr_zip          := fn_emaps_main(p_zip);
		v_encr_phone_no     := fn_emaps_main(p_phone_no);
		v_encr_mob_one      := fn_emaps_main(p_other_no);
		v_encr_email        := fn_emaps_main(p_email);
		v_encr_first_name   := fn_emaps_main(p_first_name);
		v_encr_mid_name     := fn_emaps_main(p_middle_name);
		v_encr_last_name    := fn_emaps_main(p_last_name);
		
     ELSE
        v_encr_addr_lineone := p_addr_lineone;
		v_encr_addr_linetwo := p_addr_linetwo;
		v_encr_city         := p_city;
		v_encr_zip          := p_zip;
		v_encr_phone_no     := p_phone_no;
		v_encr_mob_one      := p_other_no;
		v_encr_email        := p_email; 
		v_encr_first_name   := p_first_name;
		v_encr_mid_name     := p_middle_name;
		v_encr_last_name    := p_last_name;
     END IF;

   BEGIN
      UPDATE cms_addr_mast
         SET cam_add_one = v_encr_addr_lineone,
             cam_add_two = v_encr_addr_linetwo,
             cam_city_name = v_encr_city,
             cam_pin_code = v_encr_zip,
             cam_phone_one = v_encr_phone_no,
             cam_mobl_one = v_encr_mob_one,
             cam_email = v_encr_email,
             cam_state_code = p_state,
             cam_cntry_code = p_cntry_code,
             cam_state_switch = v_phys_switch_state_code
       WHERE cam_cust_code = v_cust_code
         AND cam_inst_code = p_instcode
         AND cam_addr_flag = 'P';

      IF SQL%ROWCOUNT = 0 THEN
       v_respcode := '21';
       v_errmsg := 'Address update not happened for customer-' || v_cust_code;
       RAISE exp_main_reject_record;
      END IF;
   EXCEPTION
      WHEN exp_main_reject_record THEN
          RAISE;
      WHEN OTHERS THEN
         v_respcode := '21';
         v_errmsg := 'Error in address update-' || SUBSTR (SQLERRM, 1, 200);
         RAISE exp_main_reject_record;
   END;

   BEGIN
      INSERT INTO cms_addr_mast
                  (cam_inst_code, cam_cust_code, cam_addr_code,
                   cam_add_one, cam_add_two, cam_phone_one, cam_mobl_one,
                   cam_email, cam_pin_code, cam_cntry_code, cam_city_name,
                   cam_addr_flag, cam_state_code, cam_state_switch,
                   cam_ins_user, cam_ins_date, cam_lupd_user, cam_lupd_date
                  )
           VALUES (p_instcode, v_cust_code, seq_addr_code.NEXTVAL,
                   v_encr_addr_lineone,
				   v_encr_addr_linetwo, 
				   v_encr_phone_no, 
				   v_encr_mob_one,
                   v_encr_email, 
				   v_encr_zip, 
				   p_cntry_code, 
				   v_encr_city,
                   'O', p_state, v_phys_switch_state_code,
                   1, SYSDATE, 1, SYSDATE
                  );
   EXCEPTION
      WHEN OTHERS THEN
         v_respcode := '21';
         v_errmsg :='Error while inserting Mailing Address'|| SUBSTR (SQLERRM, 1, 200);
         RAISE exp_main_reject_record;
   END;
   --En Address verification & updation/insertion

   --Sn Update ID type as SSN
   BEGIN
      UPDATE cms_cust_mast
         SET ccm_ssn = fn_maskacct_ssn(p_instcode,p_ssn,0),
             ccm_ssn_encr = fn_emaps_main(p_ssn),
             ccm_id_type = 'SSN',
             ccm_birth_date = p_dob,
             ccm_first_name = v_encr_first_name,
             ccm_mid_name = v_encr_mid_name,
             ccm_last_name = v_encr_last_name,
			 CCM_SYSTEM_GENERATED_PROFILE = 'N' 
       WHERE ccm_cust_code = v_cust_code AND ccm_inst_code = p_instcode;

      IF SQL%ROWCOUNT = 0 THEN
         v_errmsg :='No records Updated SSN details for customer-' || v_cust_code;
         v_respcode := '21';
         RAISE exp_main_reject_record;
      END IF;
   EXCEPTION
      WHEN exp_main_reject_record THEN
         RAISE;
      WHEN OTHERS THEN
         v_respcode := '21';
         v_errmsg :='Error in customer dtls update ' || SUBSTR (SQLERRM, 1, 200);
         RAISE exp_main_reject_record;
   END;
   
   --Sn Create entry in Card profile hisory table
   BEGIN
   INSERT INTO cms_cardprofile_hist
                  (ccp_pan_code, ccp_inst_code, ccp_add_one, ccp_add_two,
                   ccp_city_name, ccp_pin_code, ccp_phone_one, ccp_mobl_one,
                   ccp_email, ccp_state_code, ccp_cntry_code, ccp_cust_code,
                   ccp_ssn, ccp_birth_date, ccp_first_name, ccp_mid_name,
                   ccp_last_name, ccp_pan_code_encr, ccp_ins_date,
                   ccp_lupd_date, ccp_mbr_numb, ccp_rrn, ccp_stan,
                   ccp_business_date, ccp_business_time, ccp_terminal_id
                  )
           VALUES (v_hash_pan, p_instcode, v_addr_lineone, v_addr_linetwo,
                   v_city_name, v_pin_code, v_phone_no, v_mobl_no,
                   v_email, v_state_code, v_ctnry_code, v_cust_code,
                   fn_maskacct_ssn(p_instcode,v_ssn,0) ,v_birth_date, v_first_name, v_mid_name,
                   v_last_name, v_encr_pan, SYSDATE,
                   SYSDATE, p_mbr_numb, p_rrn, p_stan,
                   p_trandate, p_trantime, p_terminalid
                  );
   EXCEPTION
    WHEN OTHERS THEN
     v_respcode := '21';
     v_errmsg :='Error in card profile hist insert ' || SUBSTR (SQLERRM, 1, 200);
     RAISE exp_main_reject_record;
   END;              
   --En Update ID type as SSN
   --------------------------------------------------
   --En Updating Address & customer details
   --------------------------------------------------

   --Sn Selecting Reason code for Initial Load
   BEGIN
      SELECT csr_spprt_rsncode
        INTO v_resoncode
        FROM cms_spprt_reasons
       WHERE csr_inst_code = p_instcode AND csr_spprt_key = 'INILOAD';
   EXCEPTION
      WHEN NO_DATA_FOUND THEN
         v_respcode := '21';
         v_errmsg := 'Initial load reason code is present in master';
         RAISE exp_main_reject_record;
      WHEN OTHERS THEN
         v_respcode := '21';
         v_errmsg :='Error while selecting reason code from master'|| SUBSTR (SQLERRM, 1, 200);
         RAISE exp_main_reject_record;
   END;
   --En Selecting Reason code for Initial Load

   --Sn create a record in pan spprt
   BEGIN
      INSERT INTO cms_pan_spprt
                  (cps_inst_code, cps_pan_code, cps_mbr_numb, cps_prod_catg,
                   cps_spprt_key, cps_spprt_rsncode, cps_func_remark,
                   cps_ins_user, cps_lupd_user, cps_cmd_mode,
                   cps_pan_code_encr
                  )
           VALUES (p_instcode, v_hash_pan, v_mbrnumb, v_cap_prod_catg,
                   'INLOAD', v_resoncode, v_remrk,
                   p_lupduser, p_lupduser, 0,
                   v_encr_pan
                  );
   EXCEPTION
      WHEN OTHERS THEN
         v_respcode := '21';
         v_errmsg :='Error while inserting records into card support master'|| SUBSTR (SQLERRM, 1, 200);
         RAISE exp_main_reject_record;
   END;
   --En create a record in pan spprt

   --Sn get response code
   IF p_resp_code IS NULL THEN
   BEGIN
      --p_errmsg := v_errmsg;

      SELECT cms_iso_respcde
        INTO p_resp_code
        FROM cms_response_mast
       WHERE cms_inst_code = p_instcode
         AND cms_delivery_channel = p_delivery_channel
         AND cms_response_id = v_respcode;
   EXCEPTION
      WHEN NO_DATA_FOUND THEN
         v_errmsg :='No data available in response master  for' || v_respcode;
         v_respcode := '69';
         RAISE exp_main_reject_record;
      WHEN OTHERS THEN
         v_errmsg :='Problem while selecting data from response master '|| v_respcode|| SUBSTR (SQLERRM, 1, 200);
         v_respcode := '69';
         RAISE exp_main_reject_record;
   END;
   END IF;
   --En get response code
 
   IF p_pin_flag = 'N' AND p_kyc_stat <> '00' THEN
      p_resp_code:='10182';
      p_errmsg := 'KYC Fail And PIN Not Set.,Card Inactive';
    ELSIF p_pin_flag = 'N' AND UPPER (p_kyc_stat) = '00' THEN
      p_errmsg := 'Success.,But PIN Not Set,Card Inactive';
   END IF;
 
--   --Sn of Getting  the Acct Balannce
--   BEGIN
--      SELECT cam_acct_bal, cam_ledger_bal
--            INTO v_acct_balance, v_ledger_balance
--            FROM cms_acct_mast
--           WHERE cam_acct_no = v_acct_number AND cam_inst_code = p_instcode
--      FOR UPDATE NOWAIT;
--   EXCEPTION
--      WHEN NO_DATA_FOUND THEN
--         v_respcode := '14';
--         v_errmsg := 'Invalid Account number';
--         RAISE exp_main_reject_record;
--      WHEN OTHERS THEN
--         v_respcode := '12';
--         v_errmsg :='Error while selecting data from account Master-'|| SUBSTR (SQLERRM, 1, 200);
--         RAISE exp_main_reject_record;
--   END;
--   --En of Getting  the Acct Balannce
   --p_errmsg := TO_CHAR (v_acct_balance);

   --Sn To update  STORE_ID in transactionlog table
   BEGIN
   
       --Added for VMS-5739/FSP-991
       select (add_months(trunc(sysdate,'MM'),'-'||RETENTION_PERIOD))
       INTO   v_Retperiod 
       FROM DBA_OPERATIONS.ARCHIVE_MGMNT_CTL  
       WHERE  OPERATION_TYPE='ARCHIVE' 
       AND OBJECT_NAME='TRANSACTIONLOG_EBR';
       
       v_Retdate := TO_DATE(SUBSTR(TRIM(p_trandate), 1, 8), 'yyyymmdd');
	   
	IF (v_Retdate>v_Retperiod) THEN            --Added for VMS-5739/FSP-991
	
        UPDATE transactionlog
         SET store_id = p_terminalid,
             cardstatus =v_cap_card_stat
        WHERE instcode = p_instcode
         AND terminal_id = p_terminalid
         AND rrn = p_rrn
         AND customer_card_no = v_hash_pan
         AND business_date = p_trandate
         AND txn_code = p_txn_code
         AND delivery_channel = p_delivery_channel;
		 
	ELSE
	
	    UPDATE  VMSCMS_HISTORY.TRANSACTIONLOG_HIST --Added for VMS-5739/FSP-991
         SET store_id = p_terminalid,
             cardstatus =v_cap_card_stat
        WHERE instcode = p_instcode
         AND terminal_id = p_terminalid
         AND rrn = p_rrn
         AND customer_card_no = v_hash_pan
         AND business_date = p_trandate
         AND txn_code = p_txn_code
         AND delivery_channel = p_delivery_channel;
		 
	END IF;

      IF SQL%ROWCOUNT = 0 THEN
         v_errmsg := '0 rows Updated StoreId in Transactionlog table';
         v_respcode := '21';
         RAISE exp_main_reject_record;
      END IF;
   EXCEPTION
      WHEN exp_main_reject_record THEN
         RAISE;
      WHEN OTHERS THEN
         v_errmsg :='Error while Updating StoreId in Transactionlog table'|| SUBSTR (SQLERRM, 1, 200);
         v_respcode := '21';
         RAISE exp_main_reject_record;
   END;
   --En To update  STORE_ID in transactionlog table
   p_auth_id:=substr(v_inil_authid||TO_CHAR (SYSTIMESTAMP, 'yymmddHH24MISS'),1,15);

   --Sn To update store loc details in transaction_log dtl table
   BEGIN
   
       --Added for VMS-5739/FSP-991
       select (add_months(trunc(sysdate,'MM'),'-'||RETENTION_PERIOD))
       INTO   v_Retperiod 
       FROM DBA_OPERATIONS.ARCHIVE_MGMNT_CTL  
       WHERE  OPERATION_TYPE='ARCHIVE' 
       AND OBJECT_NAME='CMS_TRANSACTION_LOG_DTL_EBR';
       
       v_Retdate := TO_DATE(SUBSTR(TRIM(p_trandate), 1, 8), 'yyyymmdd');
	
    IF (v_Retdate>v_Retperiod)  THEN                      --Added for VMS-5739/FSP-991
	
      UPDATE cms_transaction_log_dtl
         SET ctd_store_address1 = p_store_address1,
             ctd_store_address2 = p_store_address2,
             ctd_store_city = p_store_city,
             ctd_store_state = p_store_state,
             ctd_store_zip = p_store_zip,
             ctd_optn_phno2=p_optn_phon2,
             ctd_email=p_email,
             ctd_optn_email=p_optn_email,
             ctd_auth_id=p_auth_id
       WHERE ctd_rrn = p_rrn
         AND ctd_delivery_channel = p_delivery_channel
         AND ctd_txn_code = p_txn_code
         AND ctd_business_date = p_trandate
         AND ctd_business_time = p_trantime
         AND ctd_msg_type = p_msg_type
         AND ctd_customer_card_no = v_hash_pan
         AND ctd_inst_code = p_instcode;
		 
    ELSE
	       UPDATE VMSCMS_HISTORY.CMS_TRANSACTION_LOG_DTL_HIST     --Added for VMS-5739/FSP-991
         SET ctd_store_address1 = p_store_address1,
             ctd_store_address2 = p_store_address2,
             ctd_store_city = p_store_city,
             ctd_store_state = p_store_state,
             ctd_store_zip = p_store_zip,
             ctd_optn_phno2=p_optn_phon2,
             ctd_email=p_email,
             ctd_optn_email=p_optn_email,
             ctd_auth_id=p_auth_id
       WHERE ctd_rrn = p_rrn
         AND ctd_delivery_channel = p_delivery_channel
         AND ctd_txn_code = p_txn_code
         AND ctd_business_date = p_trandate
         AND ctd_business_time = p_trantime
         AND ctd_msg_type = p_msg_type
         AND ctd_customer_card_no = v_hash_pan
         AND ctd_inst_code = p_instcode;
		
	END IF;

      IF SQL%ROWCOUNT = 0 THEN
         v_errmsg :='0 rows updated store loc details in Transactionlog dtl table';
         v_respcode := '21';
         RAISE exp_main_reject_record;
      END IF;
   EXCEPTION
      WHEN exp_main_reject_record THEN
         RAISE;
      WHEN OTHERS THEN
         v_errmsg := 'Error while Updating store loc details in Transactionlog dtl table' || SUBSTR (SQLERRM, 1, 200);
         v_respcode := '21';
         RAISE exp_main_reject_record;
   END;
   --En To update store loc details in transaction_log dtl table
   
EXCEPTION
   --<< MAIN EXCEPTION >>
   WHEN exp_auth_reject_record THEN
      p_resp_code:=v_respcode;
      p_errmsg := v_errmsg;
     
   p_auth_id:=substr(v_inil_authid||TO_CHAR (SYSTIMESTAMP, 'yymmddHH24MISS'),1,15);
   
      --Sn To update  STORE_ID in transactionlog table
      BEGIN
	  
	   --Added for VMS-5739/FSP-991
       select (add_months(trunc(sysdate,'MM'),'-'||RETENTION_PERIOD))
       INTO   v_Retperiod 
       FROM DBA_OPERATIONS.ARCHIVE_MGMNT_CTL  
       WHERE  OPERATION_TYPE='ARCHIVE' 
       AND OBJECT_NAME='TRANSACTIONLOG_EBR';
       
       v_Retdate := TO_DATE(SUBSTR(TRIM(p_trandate), 1, 8), 'yyyymmdd');
	   
	 IF (v_Retdate>v_Retperiod) THEN                           --Added for VMS-5739/FSP-991
	 
         UPDATE transactionlog
            SET store_id = p_terminalid
          WHERE instcode = p_instcode
            AND terminal_id = p_terminalid
            AND rrn = p_rrn
            AND customer_card_no = v_hash_pan
            AND business_date = p_trandate
            AND txn_code = p_txn_code
            AND delivery_channel = p_delivery_channel;
			
	  ELSE
	  
	   UPDATE VMSCMS_HISTORY.TRANSACTIONLOG_HIST --Added for VMS-5739/FSP-991
            SET store_id = p_terminalid
          WHERE instcode = p_instcode
            AND terminal_id = p_terminalid
            AND rrn = p_rrn
            AND customer_card_no = v_hash_pan
            AND business_date = p_trandate
            AND txn_code = p_txn_code
            AND delivery_channel = p_delivery_channel;
	  
	  END IF;

         IF SQL%ROWCOUNT = 0 THEN
            p_errmsg := 'No records updated in Transactionlog';
            p_resp_code := '21';
         END IF;
      EXCEPTION
         WHEN OTHERS THEN
            p_errmsg :='Error while Updating StoreId in Transactionlog table'|| SUBSTR (SQLERRM, 1, 200);
            p_resp_code := '21';
      END;
      --En To update  STORE_ID in transactionlog table

      --Sn To update  store loc details in transaction_log dtl table
      BEGIN
	  
	    --Added for VMS-5739/FSP-991
       select (add_months(trunc(sysdate,'MM'),'-'||RETENTION_PERIOD))
       INTO   v_Retperiod 
       FROM DBA_OPERATIONS.ARCHIVE_MGMNT_CTL  
       WHERE  OPERATION_TYPE='ARCHIVE' 
       AND OBJECT_NAME='CMS_TRANSACTION_LOG_DTL_EBR';
       
       v_Retdate := TO_DATE(SUBSTR(TRIM(p_trandate), 1, 8), 'yyyymmdd');
	 
	 IF (v_Retdate>v_Retperiod) THEN                          --Added for VMS-5739/FSP-991
     
	 UPDATE cms_transaction_log_dtl
            SET ctd_store_address1 = p_store_address1,
                ctd_store_address2 = p_store_address2,
                ctd_store_city = p_store_city,
                ctd_store_state = p_store_state,
                ctd_store_zip = p_store_zip,
                ctd_optn_phno2=p_optn_phon2,
                ctd_email=p_email,
                ctd_optn_email=p_optn_email,
                ctd_auth_id=p_auth_id
          WHERE ctd_rrn = p_rrn
            AND ctd_delivery_channel = p_delivery_channel
            AND ctd_txn_code = p_txn_code
            AND ctd_business_date = p_trandate
            AND ctd_business_time = p_trantime
            AND ctd_msg_type = p_msg_type
            AND ctd_customer_card_no = v_hash_pan
            AND ctd_inst_code = p_instcode;
			
			ELSE
			
		    UPDATE VMSCMS_HISTORY.CMS_TRANSACTION_LOG_DTL_HIST     --Added for VMS-5739/FSP-991
            SET ctd_store_address1 = p_store_address1,
                ctd_store_address2 = p_store_address2,
                ctd_store_city = p_store_city,
                ctd_store_state = p_store_state,
                ctd_store_zip = p_store_zip,
                ctd_optn_phno2=p_optn_phon2,
                ctd_email=p_email,
                ctd_optn_email=p_optn_email,
                ctd_auth_id=p_auth_id
          WHERE ctd_rrn = p_rrn
            AND ctd_delivery_channel = p_delivery_channel
            AND ctd_txn_code = p_txn_code
            AND ctd_business_date = p_trandate
            AND ctd_business_time = p_trantime
            AND ctd_msg_type = p_msg_type
            AND ctd_customer_card_no = v_hash_pan
            AND ctd_inst_code = p_instcode;
			
			END IF;

         IF SQL%ROWCOUNT = 0 THEN
            p_errmsg := 'No records updated in Transactionlog dtl table';
            p_resp_code := '21';
         END IF;
      EXCEPTION
         WHEN OTHERS THEN
            p_errmsg :='Error while Updating store loc details in Transactionlog dtl table'|| SUBSTR (SQLERRM, 1, 200);
            p_resp_code := '21';
      END;
      --En To update  store loc details in transaction_log dtl table
   WHEN exp_main_reject_record
   THEN
      ROLLBACK;

      --Sn generate auth id
      BEGIN
         SELECT LPAD (seq_auth_id.NEXTVAL, 6, '0')
           INTO v_inil_authid
           FROM DUAL;
      EXCEPTION
         WHEN OTHERS THEN
            v_errmsg := 'Error while generating authid ' || SUBSTR (SQLERRM, 1, 200);
            v_respcode := '21';
      END;
      --En generate auth id
      p_auth_id:=substr(v_inil_authid||TO_CHAR (SYSTIMESTAMP, 'yymmddHH24MISS'),1,15);
      
      --Sn Get Response code
      BEGIN
         p_errmsg := v_errmsg;
         
         SELECT cms_iso_respcde
           INTO p_resp_code
           FROM cms_response_mast
          WHERE cms_inst_code = p_instcode
            AND cms_delivery_channel = p_delivery_channel
            AND cms_response_id = v_respcode;
      EXCEPTION
         WHEN OTHERS THEN
            p_errmsg := 'Problem while selecting data from response master '|| v_respcode|| SUBSTR (SQLERRM, 1, 200);
            p_resp_code := '89';
      END;
      --En Get Response code
      
      IF v_dr_cr_flag IS NULL THEN
         BEGIN
            SELECT ctm_credit_debit_flag,
                   TO_NUMBER (DECODE (ctm_tran_type, 'N', '0', 'F', '1')),
                   ctm_tran_desc
              INTO v_dr_cr_flag,
                   v_txn_type,
                   v_trans_desc
              FROM cms_transaction_mast
             WHERE ctm_tran_code = p_txn_code
               AND ctm_delivery_channel = p_delivery_channel
               AND ctm_inst_code = p_instcode;
         EXCEPTION
            WHEN OTHERS THEN
               NULL;
         END;
      END IF;

      IF v_prod_code IS NULL THEN
         BEGIN
            SELECT cap_card_stat, cap_acct_no, cap_prod_code, cap_card_type
              INTO v_cap_card_stat, v_acct_number, v_prod_code, v_card_type
              FROM cms_appl_pan
             WHERE cap_inst_code = p_instcode
               AND cap_pan_code = v_hash_pan
               AND cap_mbr_numb = p_mbr_numb;
         EXCEPTION
            WHEN OTHERS THEN
               NULL;
         END;
      END IF;

      BEGIN
         SELECT cam_acct_bal, cam_ledger_bal, cam_type_code
           INTO v_acct_balance, v_ledger_balance, v_acct_type
           FROM cms_acct_mast
          WHERE cam_acct_no = v_acct_number AND cam_inst_code = p_instcode;
      EXCEPTION
         WHEN OTHERS
         THEN
            v_acct_balance := 0;
            v_ledger_balance := 0;
      END;

      --Sn create a entry in txn log
      BEGIN
         INSERT INTO transactionlog
                     (msgtype, rrn, delivery_channel, terminal_id,
                      date_time, txn_code, txn_type, txn_mode,
                      txn_status, response_code,
                      business_date, business_time, customer_card_no,
                      topup_card_no, topup_acct_no, topup_acct_type,
                      bank_code,
                      total_amount,
                      currencycode, addcharge, productid, categoryid,
                      atm_name_location, auth_id,
                      amount,
                      preauthamount, partialamount, instcode,
                      customer_card_no_encr, topup_card_no_encr,
                      proxy_number, reversal_code, customer_acct_no,
                      acct_balance, ledger_balance, response_id,
                      cardstatus, error_msg, trans_desc,
                      merchant_name, merchant_city, merchant_state,
                      ssn_fail_dtls, store_id, cr_dr_flag, acct_type,
                      time_stamp
                     )
              VALUES (p_msg_type, p_rrn, p_delivery_channel, p_terminalid,
                      v_business_date, p_txn_code, v_txn_type, p_txn_mode,
                      DECODE (p_resp_code, '00', 'C', 'F'), p_resp_code,
                      p_trandate, p_trantime, v_hash_pan,
                      NULL, NULL, NULL,
                      p_instcode,
                      TRIM (TO_CHAR (NVL (p_amount, 0),
                                     '999999999999999990.99'
                                    )
                           ),
                      v_currcode, NULL, v_prod_code, v_card_type,
                      p_terminalid, v_inil_authid,
                      TRIM (TO_CHAR (NVL (p_amount, 0),
                                     '999999999999999990.99'
                                    )
                           ),
                      NULL, NULL, p_instcode,
                      v_encr_pan, v_encr_pan,
                      v_proxunumber, p_rvsl_code, v_acct_number,
                      v_acct_balance, v_ledger_balance, v_respcode,
                      v_cap_card_stat, p_errmsg, v_trans_desc,
                      p_merchant_name, p_merchant_city, NULL,
                      v_ssn_crddtls, p_terminalid, v_dr_cr_flag, v_acct_type,
                      SYSTIMESTAMP
                     );
      EXCEPTION
         WHEN OTHERS THEN
            p_resp_code := '69';
            p_errmsg := 'Problem while inserting data into transactionlog-'|| SUBSTR (SQLERRM, 1, 200);
      END;
      --En create a entry in txn log
      
      --Sn Create entry in txn log dtl
      BEGIN
         INSERT INTO cms_transaction_log_dtl
                     (ctd_delivery_channel, ctd_txn_code, ctd_msg_type,
                      ctd_txn_mode, ctd_business_date, ctd_business_time,
                      ctd_customer_card_no, ctd_txn_amount, ctd_txn_curr,
                      ctd_actual_amount, ctd_fee_amount, ctd_waiver_amount,
                      ctd_servicetax_amount, ctd_cess_amount,
                      ctd_bill_amount, ctd_bill_curr, ctd_process_flag,
                      ctd_process_msg, ctd_rrn, ctd_inst_code,
                      ctd_customer_card_no_encr, ctd_cust_acct_number,
                      ctd_store_address1, ctd_store_address2,
                      ctd_store_city, ctd_store_state, ctd_store_zip,
                      ctd_optn_phno2,ctd_email,ctd_optn_email,ctd_auth_id
                     )
              VALUES (p_delivery_channel, p_txn_code, p_msg_type,
                      p_txn_mode, p_trandate, p_trantime,
                      v_hash_pan, p_amount, v_currcode,
                      p_amount, NULL, NULL,
                      NULL, NULL,
                      NULL, NULL, 'E',
                      v_errmsg, p_rrn, p_instcode,
                      v_encr_pan, v_acct_number,
                      p_store_address1, p_store_address2,
                      p_store_city, p_store_state, p_store_zip,p_optn_phon2,
                      p_email,p_optn_email,p_auth_id
                     );
      EXCEPTION
         WHEN OTHERS THEN
            p_errmsg := 'Problem while inserting data into transaction log  dtl-' || SUBSTR (SQLERRM, 1, 200);
            p_resp_code := '89';
            ROLLBACK;
      END;
      --En Create entry in txn log dtl
   WHEN OTHERS THEN
      p_errmsg := ' Error from main ' || SUBSTR (SQLERRM, 1, 200);
END; 
/
show error