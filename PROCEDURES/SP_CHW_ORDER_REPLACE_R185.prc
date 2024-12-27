create or replace
PROCEDURE               VMSCMS.sp_chw_order_replace_r185 (
   p_msg_in                IN     VARCHAR2,
   p_rrn_in                IN     VARCHAR2,
   p_delivery_channel_in   IN     VARCHAR2,
   p_term_id_in            IN     VARCHAR2,
   p_txn_code_in           IN     VARCHAR2,
   p_txn_mode_in           IN     VARCHAR2,
   p_tran_date_in          IN     VARCHAR2,
   p_tran_time_in          IN     VARCHAR2,
   p_hash_pan_in           IN     VARCHAR2,
   p_encr_pan_in           IN     VARCHAR2,
   p_prod_catg_in          IN     VARCHAR2,
   p_card_stat_in          IN     VARCHAR2,
   p_acct_number_in        IN     VARCHAR2,
   p_appl_code_in          IN     VARCHAR2,
   p_dispname_in           IN     VARCHAR2,
   p_prod_code_in          IN     VARCHAR2,
   p_card_type_in          IN     VARCHAR2,
   p_expiry_date_in        IN     VARCHAR2,
   p_replace_option_in     IN     VARCHAR2, 
   p_profile_code_in       IN     VARCHAR2, 
   p_new_prodcode_in       IN     VARCHAR2, 
   p_new_cardtype_in       IN     VARCHAR2,
   p_repl_provision_flag_in  IN     VARCHAR2,
   p_token_eligibility_in  IN     VARCHAR2,
   p_txn_amt_in            IN     NUMBER,
   p_curr_code_in          IN     VARCHAR2,
   p_rvsl_code_in          IN     NUMBER,
   p_fee_flag_in           IN     VARCHAR2,
   p_cardpack_id_in        IN     VARCHAR2,
   p_new_pan_out           OUT    VARCHAR2, 
   p_resp_code_out         OUT    VARCHAR2,
   p_resp_msg_out          OUT    VARCHAR2)
IS
   /*****************************************************************************
	* Created By       : Vini Pushkaran
    * Created Date     : 23-Jan-2019
    * Purpose          : VMS-742
    * Reviewer         : Saravanakumar
    * Release Number   : VMSGPRHOST_R11
	
	* Modified By       : Ubaidur Rahman H
    * Modified Date     : 03-Apr-2019
    * Purpose           : VMS-846 (Replacement not allowed for digital products)
    * Reviewer          : Saravanakumar A
    * Release Number    : VMSGPRHOST_R14_B0004
    ******************************************************************************/
   v_acct_balance               cms_acct_mast.cam_acct_bal%TYPE;
   v_ledger_bal                 cms_acct_mast.cam_ledger_bal%TYPE;
   v_auth_id                    transactionlog.auth_id%TYPE;
   v_resp_cde                   transactionlog.response_id%TYPE;
   v_dr_cr_flag                 cms_transaction_mast.ctm_credit_debit_flag%TYPE;
   v_err_msg                    transactionlog.error_msg%TYPE;
   v_business_date              transactionlog.date_time%TYPE;
   v_txn_type                   cms_transaction_log_dtl.ctd_txn_type%TYPE;
   v_crdstat_cnt                NUMBER ;
   v_cro_oldcard_reissue_stat   cms_reissue_oldcardstat.cro_oldcard_reissue_stat%TYPE;
   v_new_card_no                cms_appl_pan.cap_pan_code%TYPE;
   v_remrk                      cms_pan_spprt.cps_func_remark%TYPE;
   v_resoncode                  cms_spprt_reasons.csr_spprt_rsncode%TYPE;
   v_dup_check                  NUMBER ;
   v_new_hash_pan               cms_appl_pan.cap_pan_code%TYPE;
   v_cam_type_code              cms_acct_mast.cam_type_code%TYPE;
   v_timestamp                  transactionlog.time_stamp%TYPE;
   v_expiry_date                cms_appl_pan.cap_expry_date%TYPE;
   v_rrn                        vms_token_status_sync_dtls.vts_rrn%TYPE;
   v_stan                       vms_token_status_sync_dtls.vts_stan%TYPE;
   V_token_pan_ref_id           vms_token_info.vti_token_pan_ref_id%TYPE;
   v_token_count                NUMBER:=0;
   v_new_encr_pan               cms_appl_pan.cap_pan_code_encr%TYPE;
   v_query                      VARCHAR2(1000);
   v_token                      vms_token_info.vti_token_pan%TYPE;
   cur_ref_token                sys_refcursor;
   v_message_reasoncode         vms_token_status.vts_reason_code%TYPE;
   v_prod_code                  cms_appl_pan.cap_prod_code%TYPE;
   v_card_type                  cms_appl_pan.cap_card_type%TYPE;
   v_capture_date               DATE;
   v_form_factor                cms_appl_pan.cap_form_factor%TYPE;  -- Added for VMS-846 (Replacement not allowed for digital card)
   e_reject_record              EXCEPTION;
BEGIN
   v_resp_cde := '1';
   v_err_msg := 'OK';
   p_resp_msg_out := 'OK';
   v_remrk := 'Online Order Replacement Card';
   v_prod_code := p_prod_code_in;
   v_card_type := p_card_type_in;
 
   --Sn Get business date
   BEGIN
      v_business_date :=
         TO_DATE (
               SUBSTR (TRIM (p_tran_date_in), 1, 8)
            || ' '
            || SUBSTR (TRIM (p_tran_time_in), 1, 10),
            'yyyymmdd hh24:mi:ss');
   EXCEPTION
      WHEN OTHERS
      THEN
         v_resp_cde := '21';
         v_err_msg :=
            'Problem while converting transaction date time '
            || SUBSTR (SQLERRM, 1, 200);
         RAISE e_reject_record;
   END;

   --En Get business date

   --Sn find debit and credit flag
   BEGIN
      SELECT ctm_credit_debit_flag,
             TO_NUMBER (DECODE (ctm_tran_type,  'N', '0',  'F', '1'))
        INTO v_dr_cr_flag,
             v_txn_type
        FROM cms_transaction_mast
       WHERE     ctm_tran_code = p_txn_code_in
             AND ctm_delivery_channel = p_delivery_channel_in
             AND ctm_inst_code = 1;
   EXCEPTION
      WHEN OTHERS
      THEN
         v_resp_cde := '21';                          
         v_err_msg := 'Error while selecting transaction details';
         RAISE e_reject_record;
   END;

   --En find debit and credit flag
   
   --Sn Digital Card Replacement Check
	BEGIN
	  SELECT cap_form_factor
	  INTO v_form_factor
	  FROM cms_appl_pan
	  WHERE cap_inst_code = 1
	  AND cap_pan_code    = p_hash_pan_in
	  AND cap_mbr_numb    = '000';
	  
	  IF v_form_factor    = 'V' 
	  THEN
		v_resp_cde       := '145';
		v_err_msg        := 'Replacement Not Allowed For Digital Card';
		RAISE e_reject_record;
	  END IF;
	  
	EXCEPTION
	WHEN e_reject_record THEN
	  RAISE e_reject_record;
	WHEN OTHERS THEN
	  v_resp_cde := '21';
	  v_err_msg  := 'Error while selecting form factor from CMS_APPL_PAN' || SUBSTR (SQLERRM, 1, 200);
	  RAISE e_reject_record;
	END;
   
   --En Digital Card Replacement Check

   --Sn Duplicate card Replacement check
   BEGIN
      SELECT COUNT (1)
        INTO v_dup_check
        FROM cms_htlst_reisu
       WHERE     chr_inst_code = 1
             AND chr_pan_code = p_hash_pan_in
             AND chr_reisu_cause = 'R'
             AND chr_new_pan IS NOT NULL;

      IF v_dup_check > 0
      THEN
         v_resp_cde := '14';
         v_err_msg := 'Card already Replaced';
         RAISE e_reject_record;
      END IF;
   END;

   --Sn authorize txn
   BEGIN
      sp_authorize_txn_cms_auth (1,
                                 p_msg_in,
                                 p_rrn_in,
                                 p_delivery_channel_in,
                                 p_term_id_in,
                                 p_txn_code_in,
                                 p_txn_mode_in,
                                 p_tran_date_in,
                                 p_tran_time_in,
                                 vmscms.fn_dmaps_main(p_encr_pan_in),
                                 1,
                                 p_txn_amt_in,
                                 NULL,
                                 NULL,
                                 null,
                                 p_curr_code_in,
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
                                 null,
                                 null,
                                 '000',
                                 p_rvsl_code_in,
                                 p_txn_amt_in,
                                 v_auth_id,
                                 v_resp_cde,
                                 v_err_msg,
                                 v_capture_date,
                                 p_fee_flag_in);

      IF v_resp_cde <> '00' AND v_err_msg <> 'OK'
      THEN
         p_resp_code_out := v_resp_cde;
         p_resp_msg_out := 'Error from auth process' || v_err_msg;
         RETURN;
      END IF;
   EXCEPTION
      WHEN OTHERS
      THEN
         v_resp_cde := '21';
         v_err_msg :=
            'Error from Card authorization' || SUBSTR (SQLERRM, 1, 200);
         RAISE e_reject_record;
   END;

   --En authorize txn

   --Sn Valid card stat check
   BEGIN
      SELECT COUNT (*)
        INTO v_crdstat_cnt
        FROM cms_reissue_validstat
       WHERE     crv_inst_code = 1
             AND crv_valid_crdstat = p_card_stat_in
             AND crv_prod_catg IN ('P');

      IF v_crdstat_cnt = 0
      THEN
         v_err_msg := 'Not a valid card status. Card cannot be reissued';
         v_resp_cde := '14';
         RAISE e_reject_record;
      END IF;
   EXCEPTION
      WHEN e_reject_record
      THEN
         raise;
      WHEN OTHERS
      THEN
         v_resp_cde := '21';
         v_err_msg :=
            'Error while checking cms_reissue_validstat ' || SUBSTR (SQLERRM, 1, 200);
         RAISE e_reject_record;
   END;

   --En Valid card stat check

 
   IF p_token_eligibility_in = 'Y' THEN
    BEGIN
      select count(*) 
      INTO v_token_count 
      from vms_token_info
      where vti_acct_no  = p_acct_number_in;  
    EXCEPTION
    WHEN OTHERS THEN
      v_err_msg  := 'Error while checking count ' || SUBSTR (SQLERRM, 1, 200);
      v_resp_cde := '21';
      RAISE e_reject_record;
    END;
   END IF; 

   IF v_token_count > 0 THEN
     BEGIN
      SELECT vti_token_pan_ref_id
      INTO v_token_pan_ref_id
      FROM vms_token_info
      WHERE vti_token_pan = p_hash_pan_in
      AND ROWNUM          =1;
    EXCEPTION
    WHEN OTHERS THEN
      v_err_msg  := 'Error while selecting pan ref id ' || SUBSTR (SQLERRM, 1, 200);
      v_resp_cde := '21';
      RAISE e_reject_record;
    END;
    
     BEGIN
        SELECT   vts_reason_code
        INTO  v_message_reasoncode
        FROM CMS_CARD_STAT,
          vms_token_status
        WHERE CCS_STAT_CODE = p_card_stat_in
        AND CCS_TOKEN_STAT  = vts_token_stat;
      EXCEPTION
      WHEN OTHERS THEN
        v_err_msg := 'Error while selecting token status '|| SUBSTR (SQLERRM, 1, 300);
        RAISE e_reject_record;
      END;
   END IF; 

   IF p_replace_option_in = 'SP' AND p_card_stat_in <> '2'
   THEN
      IF p_profile_code_in IS NULL
      THEN
         v_err_msg := 'Profile is not Attached to Product cattype';
         v_resp_cde := '21';
         RAISE e_reject_record;
      END IF;

      BEGIN
            vmsfunutilities.get_expiry_date(1,v_prod_code,
            v_card_type,p_profile_code_in,v_expiry_date,v_err_msg);

            if v_err_msg<>'OK' then
            RAISE e_reject_record;
         END IF;


      EXCEPTION
              WHEN e_reject_record THEN
            RAISE;
              WHEN OTHERS THEN
                v_err_msg:='Error while calling vmsfunutilities.get_expiry_date'||substr(sqlerrm,1,200);
            RAISE e_reject_record;
      END;

      --Sn Update new expry
      BEGIN
         UPDATE cms_appl_pan
            SET cap_replace_exprydt = v_expiry_date,
                    cap_repl_flag=6
          WHERE cap_inst_code = 1 AND cap_pan_code = p_hash_pan_in;

         IF SQL%ROWCOUNT <> 1
         THEN
            v_err_msg := 'Error while updating appl_pan ';
            v_resp_cde := '21';
            RAISE e_reject_record;
         END IF;
         
      EXCEPTION
         WHEN e_reject_record
         THEN
            RAISE;
         WHEN OTHERS
         THEN
            v_err_msg :=
               'Error while updating Expiry Date' || SUBSTR (SQLERRM, 1, 200);
            v_resp_cde := '21';
            RAISE e_reject_record;
      END;

      --En Update new expry

      --Sn Update application status as printer pending
      BEGIN
         UPDATE cms_cardissuance_status
            SET ccs_card_status = '20'
          WHERE ccs_inst_code = 1 AND ccs_pan_code = p_hash_pan_in;

         IF SQL%ROWCOUNT <> 1
         THEN
            v_err_msg := 'Error while updating CMS_CARDISSUANCE_STATUS ';
            v_resp_cde := '21';
            RAISE e_reject_record;
         END IF;
         
      EXCEPTION
         WHEN e_reject_record
         THEN
            RAISE;
         WHEN OTHERS
         THEN
            v_err_msg :=
               'Error while updating Application Card Issuance Status'
               || SUBSTR (SQLERRM, 1, 200);
            v_resp_cde := '21';
            RAISE e_reject_record;
      END;

   --En Update application status as printer pending
    IF v_token_count > 0 THEN

   BEGIN
        v_query  := 'SELECT vti_token FROM vms_token_info  WHERE  vti_token_pan = '''||p_hash_pan_in||'''
                              AND vti_token_stat <>''D''';
    OPEN cur_ref_token FOR v_query;
    LOOP
      FETCH cur_ref_token
      INTO v_token;  
       EXIT  WHEN cur_ref_token%NOTFOUND;
       
      BEGIN
          v_rrn  := LPAD(seq_auth_rrn.NEXTVAL,12,'0');
          v_stan := LPAD(seq_auth_stan.NEXTVAL,6,'0');
          INSERT
          INTO vms_token_status_sync_dtls
            (
              vts_card_no,
              vts_token_no,
              vts_reason_code,
              vts_ins_date,
              vts_pan_code_encr,
              vts_tran_rrn,
              vts_rrn,
              vts_stan,
              vts_expry_date,
              vts_acct_no,
              vts_card_stat,
              vts_token_status_flag
            )
            VALUES
            (
              p_hash_pan_in,
              v_token,
              v_message_reasoncode,
              systimestamp,
              p_encr_pan_in,
              p_rrn_in,
              v_rrn,
              v_stan,
              p_expiry_date_in,
              p_acct_number_in,
              p_card_stat_in,
              'R'
            );
          EXCEPTION
          WHEN OTHERS THEN
              v_err_msg :='Error While inserting into token_status_sync_dtls-'||SUBSTR(SQLERRM, 1, 100);
              v_resp_cde := '21';
              RAISE e_reject_record;   
          END;    
        END LOOP;
        END;

           BEGIN
                v_rrn  := LPAD(seq_auth_rrn.NEXTVAL,12,'0');
                v_stan := LPAD(seq_auth_stan.NEXTVAL,6,'0');
                INSERT INTO vms_token_status_sync_dtls
                      (
                        vts_card_no,
                        vts_reason_code,
                        vts_ins_date,
                        vts_pan_code_encr,
                        vts_tran_rrn,
                        vts_rrn,
                        vts_stan,
                        vts_expry_date,
                        vts_token_pan_ref_id,
                        vts_new_pan,
                        vts_newpan_encr,
                        vts_newexpry_date,
                        vts_acct_no,
                        vts_card_stat,
                        vts_token_status_flag
                      )
                      VALUES
                      (
                        p_hash_pan_in,
                        '3720',
                        systimestamp,
                        p_encr_pan_in,
                        p_rrn_in,
                        v_rrn,
                        v_stan,
                        p_expiry_date_in,
                        v_token_pan_ref_id,
                        p_hash_pan_in,
                        p_encr_pan_in,
                        TO_CHAR(v_expiry_date,'MMYY') ,
                        p_acct_number_in,
                        p_card_stat_in,
                        'R'
                      );
          EXCEPTION            
            WHEN OTHERS THEN
                v_err_msg :='Error While inserting into token_status_sync_dtls-'||SUBSTR(SQLERRM, 1, 100);
                v_resp_cde := '21';
                RAISE e_reject_record;              
           END;

  END IF; 
  
   ELSE
      IF p_replace_option_in='NPP' THEN
             v_prod_code:=p_new_prodcode_in;
             v_card_type:=p_new_cardtype_in;
      END IF;

      BEGIN
         SELECT cro_oldcard_reissue_stat
           INTO v_cro_oldcard_reissue_stat
           FROM cms_reissue_oldcardstat
          WHERE     cro_inst_code = 1
                AND cro_oldcard_stat = p_card_stat_in
                AND cro_spprt_key = 'R';
      EXCEPTION
         WHEN NO_DATA_FOUND
         THEN
            v_err_msg :=
               'Default old card status not defined for institution '
               || 1;
            v_resp_cde := '14';
            RAISE e_reject_record;
         WHEN OTHERS
         THEN
            v_err_msg :=
               'Error while getting default old card status for institution '
               || 1;
            v_resp_cde := '21';
            RAISE e_reject_record;
      END;

      BEGIN
         UPDATE cms_appl_pan
            SET cap_card_stat = v_cro_oldcard_reissue_stat,
                cap_lupd_user = 1
          WHERE cap_inst_code= 1 AND cap_pan_code = p_hash_pan_in;
        
      EXCEPTION
         WHEN OTHERS
         THEN
            v_err_msg :=
               'Error while updating CMS_APPL_PAN'
               || SUBSTR (SQLERRM, 1, 200);
            v_resp_cde := '21';
            RAISE e_reject_record;
      END;

      IF v_cro_oldcard_reissue_stat = '9'
      THEN
         BEGIN
            sp_log_cardstat_chnge (1,
                                   p_hash_pan_in,
                                   p_encr_pan_in,
                                   v_auth_id,
                                   '02',
                                   p_rrn_in,
                                   p_tran_date_in,
                                   p_tran_time_in,
                                   v_resp_cde,
                                   v_err_msg);

            IF v_resp_cde <> '00' AND v_err_msg <> 'OK'
            THEN
               RAISE e_reject_record;
            END IF;
            
         EXCEPTION
            WHEN e_reject_record
            THEN
               RAISE;
            WHEN OTHERS
            THEN
               v_resp_cde := '21';
               v_err_msg :=
                  'Error while logging system initiated card status change '
                  || SUBSTR (SQLERRM, 1, 200);
               RAISE e_reject_record;
         END;
      END IF;

      BEGIN
         SP_ORDER_REISSUEPAN_CMS_R185 (p_hash_pan_in,
                                       v_prod_code,
                                       v_card_type,
                                       p_dispname_in,
                                       p_cardpack_id_in,
                                       v_new_card_no,
                                       v_err_msg);

         IF v_err_msg != 'OK'
         THEN
            v_err_msg := 'From reissue pan generation process-- ' || v_err_msg;
            v_resp_cde := '21';
            RAISE e_reject_record;
         END IF;
         
      EXCEPTION
         WHEN e_reject_record
         THEN
            RAISE;
         WHEN OTHERS
         THEN
            v_err_msg := 'From reissue pan generation process-- ' || v_err_msg;
            v_resp_cde := '21';
            RAISE e_reject_record;
      END;

      --Sn hash the new Pan no
      BEGIN
         v_new_hash_pan := gethash (v_new_card_no);
      EXCEPTION
         WHEN OTHERS
         THEN
            v_err_msg :=
                  'Error while converting new pan. into hash value '
               || SUBSTR (SQLERRM, 1, 200);
            RAISE e_reject_record;
      END;

      --En hash the new Pan no
     BEGIN
          v_new_encr_pan := fn_emaps_main (v_new_card_no);
       EXCEPTION
          WHEN OTHERS
          THEN
             v_err_msg :=
                   'Error while converting into encrypted value '
                || SUBSTR (SQLERRM, 1, 200);
             RAISE e_reject_record;
       END;

         BEGIN
            UPDATE cms_appl_pan
               SET cap_repl_flag = 6
             WHERE cap_inst_code = 1
                   AND cap_pan_code = v_new_hash_pan;
 
           EXCEPTION
            WHEN OTHERS
            THEN
               v_err_msg :=
                  'Error while updating CMS_APPL_PAN'
                  || SUBSTR (SQLERRM, 1, 200);
               v_resp_cde := '21';
               RAISE e_reject_record;
         END;

      IF v_err_msg = 'OK'
      THEN
         BEGIN
            INSERT INTO cms_htlst_reisu (chr_inst_code,
                                         chr_pan_code,
                                         chr_mbr_numb,
                                         chr_new_pan,
                                         chr_new_mbr,
                                         chr_reisu_cause,
                                         chr_ins_user,
                                         chr_lupd_user,
                                         chr_pan_code_encr,
                                         chr_new_pan_encr)
                 VALUES (1,
                         p_hash_pan_in,
                         '000',
                         v_new_hash_pan,
                         '000',
                         'R',
                         1,
                         1,
                         p_encr_pan_in,
                         v_new_encr_pan);
         EXCEPTION
            WHEN OTHERS
            THEN
               v_err_msg :=
                  'Error while creating  reissuue record '
                  || SUBSTR (SQLERRM, 1, 200);
               v_resp_cde := '21';
               RAISE e_reject_record;
         END;

         BEGIN
            INSERT INTO cms_cardissuance_status (ccs_inst_code,
                                                 ccs_pan_code,
                                                 ccs_card_status,
                                                 ccs_ins_user,
                                                 ccs_ins_date,
                                                 ccs_pan_code_encr,
                                                 ccs_appl_code)
                 VALUES (1,
                         v_new_hash_pan,
                         '2',
                         1,
                         SYSDATE,
                         fn_emaps_main (v_new_card_no),
                         p_appl_code_in);
         EXCEPTION
            WHEN OTHERS
            THEN
               v_err_msg :=
                  'Error while Inserting CCF table '
                  || SUBSTR (SQLERRM, 1, 200);
               v_resp_cde := '21';
               RAISE e_reject_record;
         END;

         BEGIN
            INSERT INTO cms_smsandemail_alert (csa_inst_code,
                                               csa_pan_code,
                                               csa_pan_code_encr,
                                               csa_cellphonecarrier,
                                               csa_loadorcredit_flag,
                                               csa_lowbal_flag,
                                               csa_lowbal_amt,
                                               csa_negbal_flag,
                                               csa_highauthamt_flag,
                                               csa_highauthamt,
                                               csa_dailybal_flag,
                                               csa_begin_time,
                                               csa_end_time,
                                               csa_insuff_flag,
                                               csa_incorrpin_flag,
                                               csa_fast50_flag,
                                               csa_fedtax_refund_flag,
                                               csa_deppending_flag,
                                               csa_depaccepted_flag,
                                               csa_deprejected_flag,
                                               csa_ins_user,
                                               csa_ins_date,
                                               csa_lupd_user,
                                               csa_lupd_date)
               (SELECT 1,
                       v_new_hash_pan,
                       v_new_encr_pan,
                       NVL (csa_cellphonecarrier, 0),
                       csa_loadorcredit_flag,
                       csa_lowbal_flag,
                       NVL (csa_lowbal_amt, 0),
                       csa_negbal_flag,
                       csa_highauthamt_flag,
                       NVL (csa_highauthamt, 0),
                       csa_dailybal_flag,
                       NVL (csa_begin_time, 0),
                       NVL (csa_end_time, 0),
                       csa_insuff_flag,
                       csa_incorrpin_flag,
                       csa_fast50_flag,
                       csa_fedtax_refund_flag,
                       csa_deppending_flag,
                       csa_depaccepted_flag,
                       csa_deprejected_flag,
                       1,
                       SYSDATE,
                       1,
                       SYSDATE
                  FROM cms_smsandemail_alert
                 WHERE csa_inst_code = 1
                       AND csa_pan_code = p_hash_pan_in);

            IF SQL%ROWCOUNT != 1
            THEN
               v_err_msg :=
                  'No / More Records Present in cms_smsandemail_alert';
               v_resp_cde := '21';
               RAISE e_reject_record;
            END IF;
            
         EXCEPTION
           WHEN DUP_VAL_ON_INDEX 
           THEN 
              null;
            WHEN e_reject_record THEN
             RAISE;
            WHEN OTHERS
            THEN
               v_err_msg :=
                  'Error while Entering sms email alert detail '
                  || SUBSTR (SQLERRM, 1, 200);
               v_resp_cde := '21';
               RAISE e_reject_record;
         END;


      END IF;
  IF v_token_count > 0 THEN 
    IF  p_repl_provision_flag_in ='Y' THEN

      BEGIN
      v_query  := 'SELECT vti_token FROM vms_token_info  WHERE  vti_token_pan = '''||p_hash_pan_in||'''
                          AND vti_token_stat <>''D''';
      OPEN cur_ref_token FOR v_query;
      LOOP
        FETCH cur_ref_token
        INTO v_token;  
         EXIT  WHEN cur_ref_token%NOTFOUND;
      BEGIN
          v_rrn  := LPAD(seq_auth_rrn.NEXTVAL,12,'0');
          v_stan := LPAD(seq_auth_stan.NEXTVAL,6,'0');
          
          INSERT
          INTO vms_token_status_sync_dtls
            (
              vts_card_no,
              vts_token_no,
              vts_reason_code,
              vts_ins_date,
              vts_pan_code_encr,
              vts_tran_rrn,
              vts_rrn,
              vts_stan,
              vts_expry_date,
              vts_acct_no,
              vts_card_stat,
              vts_token_status_flag
            )
            VALUES
            (
              p_hash_pan_in,
              v_token,
              v_message_reasoncode,
              systimestamp,
              p_encr_pan_in,
              p_rrn_in,
              v_rrn,
              v_stan,
              p_expiry_date_in,
              p_acct_number_in,
              p_card_stat_in,
              'R'
            );
         EXCEPTION
        WHEN OTHERS THEN
          v_err_msg :='Error While inserting into token_status_sync_dtls-'||SUBSTR(SQLERRM, 1, 100);
          v_resp_cde := '21';
          RAISE e_reject_record;   
          END;    
        END LOOP;
        END;

        IF v_cro_oldcard_reissue_stat = '9' THEN
         BEGIN
              BEGIN
                  SELECT cap_expry_date
                    INTO v_expiry_date
                    FROM cms_appl_pan
                   WHERE cap_pan_code = v_new_hash_pan AND cap_inst_code = 1;
               EXCEPTION
                  WHEN OTHERS
                  THEN
                     v_err_msg :=
                        'Error while selecting CMS_APPL_PAN' || SUBSTR (SQLERRM, 1, 200);
                     v_resp_cde := '21';
                     RAISE e_reject_record;
               END;

                v_rrn  := LPAD(seq_auth_rrn.NEXTVAL,12,'0');
                v_stan := LPAD(seq_auth_stan.NEXTVAL,6,'0');

            INSERT INTO vms_token_status_sync_dtls
                      (
                        vts_card_no,
                        vts_reason_code,
                        vts_ins_date,
                        vts_pan_code_encr,
                        vts_tran_rrn,
                        vts_rrn,
                        vts_stan,
                        vts_expry_date,
                        vts_token_pan_ref_id,
                        vts_new_pan,
                        vts_newpan_encr,
                        vts_newexpry_date,
                        vts_acct_no,
                        vts_card_stat,
                        vts_token_status_flag
                      )
                      VALUES
                      (
                        p_hash_pan_in,
                        '3721',
                        systimestamp,
                        p_encr_pan_in,
                        p_rrn_in,
                        v_rrn,
                        v_stan,
                        p_expiry_date_in,
                        v_token_pan_ref_id,
                        v_new_hash_pan,
                        v_new_encr_pan,
                        TO_CHAR(v_expiry_date,'MMYY') ,
                        p_acct_number_in,
                        p_card_stat_in,
                        'R'
                      );
        EXCEPTION
        WHEN OTHERS THEN
          v_err_msg :='Error While inserting into token_status_sync_dtls-'||SUBSTR(SQLERRM, 1, 100);
          RAISE e_reject_record;        
           END;        
       END IF; 

    ELSE
        BEGIN
        v_query  := 'SELECT vti_token FROM vms_token_info  WHERE  vti_token_pan = '''||p_hash_pan_in||'''
                              AND vti_token_stat <>''D''';

    OPEN cur_ref_token FOR v_query;
    LOOP
      FETCH cur_ref_token
      INTO v_token;  
       EXIT  WHEN cur_ref_token%NOTFOUND;
      
      BEGIN
          v_rrn  := LPAD(seq_auth_rrn.NEXTVAL,12,'0');
          v_stan := LPAD(seq_auth_stan.NEXTVAL,6,'0');

          INSERT
          INTO vms_token_status_sync_dtls
            (
              vts_card_no,
              vts_token_no,
              vts_reason_code,
              vts_ins_date,
              vts_pan_code_encr,
              vts_tran_rrn,
              vts_rrn,
              vts_stan,
              vts_expry_date,
              vts_acct_no,
              vts_card_stat,
              vts_token_status_flag
            )
            VALUES
            (
              p_hash_pan_in,
              v_token,
              '3701',
              systimestamp,
              p_encr_pan_in,
              p_rrn_in,
              v_rrn,
              v_stan,
              p_expiry_date_in,
              p_acct_number_in,
              p_card_stat_in,
              'R'
            );
         EXCEPTION
        WHEN OTHERS THEN
          v_err_msg :='Error While inserting into token_status_sync_dtls-'||SUBSTR(SQLERRM, 1, 100);
          RAISE e_reject_record;   
          END;    
          
        END LOOP;
        END;
    END IF;
  END IF;
   END IF;

   p_new_pan_out := v_new_card_no;

   --Sn Selecting Reason code for Initial Load
   BEGIN
      SELECT csr_spprt_rsncode
        INTO v_resoncode
        FROM cms_spprt_reasons
       WHERE     csr_inst_code = 1
             AND csr_spprt_key = 'REISSUE'
             AND ROWNUM < 2;
   EXCEPTION
      WHEN OTHERS
      THEN
         v_resp_cde := '21';
         v_err_msg :=
            'Error while selecting reason code from master'
            || SUBSTR (SQLERRM, 1, 200);
         RAISE e_reject_record;
   END;

   BEGIN
      INSERT INTO cms_pan_spprt (cps_inst_code,
                                 cps_pan_code,
                                 cps_mbr_numb,
                                 cps_prod_catg,
                                 cps_spprt_key,
                                 cps_spprt_rsncode,
                                 cps_func_remark,
                                 cps_ins_user,
                                 cps_lupd_user,
                                 cps_cmd_mode,
                                 cps_pan_code_encr)
           VALUES (1,
                   p_hash_pan_in,
                   '000',
                   p_prod_catg_in,
                   'REISSUE',
                   v_resoncode,
                   v_remrk,
                   1,
                   1,
                   0,
                   p_encr_pan_in);
   EXCEPTION
      WHEN OTHERS
      THEN
         v_resp_cde := '21';
         v_err_msg :=
            'Error while inserting records into card support master'
            || SUBSTR (SQLERRM, 1, 200);

         RAISE e_reject_record;
   END;

   --En create a record in pan spprt

   v_resp_cde := '1';

   BEGIN
      SELECT cms_iso_respcde
        INTO p_resp_code_out
        FROM cms_response_mast
       WHERE     cms_inst_code = 1
             AND cms_delivery_channel = p_delivery_channel_in
             AND cms_response_id = TO_NUMBER (v_resp_cde);
   EXCEPTION
      WHEN OTHERS
      THEN
         v_err_msg :=
            'Problem while selecting data from response master for respose code'
            || v_resp_cde
            || SUBSTR (SQLERRM, 1, 300);
         v_resp_cde := '21';
         RAISE e_reject_record;
   END;


EXCEPTION
   --<< MAIN EXCEPTION >>
   WHEN e_reject_record
   THEN
      ROLLBACK;

      BEGIN
         SELECT cam_acct_bal,
                cam_ledger_bal,
                cam_type_code
           INTO v_acct_balance,
                v_ledger_bal,
                v_cam_type_code
           FROM cms_acct_mast
          WHERE cam_acct_no = p_acct_number_in AND cam_inst_code = 1;
      EXCEPTION
         WHEN OTHERS
         THEN
            v_acct_balance := 0;
            v_ledger_bal := 0;
      END;

      --Sn select response code and insert record into txn log dtl
      BEGIN
         p_resp_code_out := v_resp_cde;
         p_resp_msg_out := v_err_msg;

         SELECT cms_iso_respcde
           INTO p_resp_code_out
           FROM cms_response_mast
          WHERE     cms_inst_code = 1
                AND cms_delivery_channel = p_delivery_channel_in
                AND cms_response_id = v_resp_cde;
      EXCEPTION
         WHEN OTHERS
         THEN
            p_resp_msg_out :=
                  'Problem while selecting data from response master '
               || v_resp_cde
               || SUBSTR (SQLERRM, 1, 300);
            p_resp_code_out := '69';
       END;

      BEGIN
         INSERT INTO cms_transaction_log_dtl (ctd_delivery_channel,
                                              ctd_txn_code,
                                              ctd_txn_type,
                                              ctd_msg_type,
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
                                              ctd_inst_code,
                                              ctd_customer_card_no_encr,
                                              ctd_cust_acct_number)
              VALUES (p_delivery_channel_in,
                      p_txn_code_in,
                      v_txn_type,
                      p_msg_in,
                      p_txn_mode_in,
                      p_tran_date_in,
                      p_tran_time_in,
                      p_hash_pan_in,
                      p_txn_amt_in,
                      p_curr_code_in,
                      p_txn_amt_in,
                      NULL,
                      NULL,
                      NULL,
                      NULL,
                      p_txn_amt_in,
                      840,
                      'E',
                      v_err_msg,
                      p_rrn_in,
                      null,
                      1,
                      p_encr_pan_in,
                      p_acct_number_in);

         p_resp_msg_out := v_err_msg;
      EXCEPTION
         WHEN OTHERS
         THEN
            p_resp_msg_out :=
               'Problem while inserting data into transaction log  dtl'
               || SUBSTR (SQLERRM, 1, 300);
            p_resp_code_out := '69';
            ROLLBACK;
            RETURN;
      END;

      v_timestamp := SYSTIMESTAMP;

      --Sn create a entry in txn log
      BEGIN
         INSERT INTO transactionlog (msgtype,
                                     rrn,
                                     delivery_channel,
                                     terminal_id,
                                     date_time,
                                     txn_code,
                                     txn_type,
                                     txn_mode,
                                     txn_status,
                                     response_code,
                                     business_date,
                                     business_time,
                                     customer_card_no,
                                     topup_card_no,
                                     topup_acct_no,
                                     topup_acct_type,
                                     bank_code,
                                     total_amount,
                                     rule_indicator,
                                     rulegroupid,
                                     mccode,
                                     currencycode,
                                     addcharge,
                                     productid,
                                     categoryid,
                                     tips,
                                     decline_ruleid,
                                     atm_name_location,
                                     auth_id,
                                     trans_desc,
                                     amount,
                                     preauthamount,
                                     partialamount,
                                     mccodegroupid,
                                     currencycodegroupid,
                                     transcodegroupid,
                                     rules,
                                     preauth_date,
                                     gl_upd_flag,
                                     system_trace_audit_no,
                                     instcode,
                                     feecode,
                                     tranfee_amt,
                                     servicetax_amt,
                                     cess_amt,
                                     cr_dr_flag,
                                     tranfee_cr_acctno,
                                     tranfee_dr_acctno,
                                     tran_st_calc_flag,
                                     tran_cess_calc_flag,
                                     tran_st_cr_acctno,
                                     tran_st_dr_acctno,
                                     tran_cess_cr_acctno,
                                     tran_cess_dr_acctno,
                                     customer_card_no_encr,
                                     topup_card_no_encr,
                                     proxy_number,
                                     reversal_code,
                                     customer_acct_no,
                                     acct_balance,
                                     ledger_balance,
                                     response_id,
                                     ipaddress,
                                     cardstatus,
                                     fee_plan,
                                     csr_achactiontaken,
                                     error_msg,
                                     processes_flag,
                                     acct_type,
                                     time_stamp)
              VALUES (
                        p_msg_in,
                        p_rrn_in,
                        p_delivery_channel_in,
                        p_term_id_in,
                        v_business_date,
                        p_txn_code_in,
                        v_txn_type,
                        p_txn_mode_in,
                        DECODE (p_resp_code_out, '00', 'C', 'F'),
                        p_resp_code_out,
                        p_tran_date_in,
                        SUBSTR (p_tran_time_in, 1, 10),
                        p_hash_pan_in,
                        NULL,
                        NULL,
                        NULL,
                        1,
                        TRIM (
                           TO_CHAR (NVL (p_txn_amt_in, 0),
                                    '99999999999999990.99')),
                        '',
                        '',
                        null,
                        p_curr_code_in,
                        NULL,
                        v_prod_code,
                        v_card_type,
                        0,
                        '',
                        '',
                        v_auth_id,
                        'Card replacement update activity 30.5',
                        TRIM (
                           TO_CHAR (NVL (p_txn_amt_in, 0),
                                    '99999999999999990.99')),
                        '0.00',
                        '0.00',
                        '',
                        '',
                        '',
                        '',
                        '',
                        NULL,
                        null,
                        1,
                        NULL,
                        NVL (0, 0),
                        NVL (0, 0),
                        NVL (0, 0),
                        v_dr_cr_flag,
                        NULL,
                        NULL,
                        NULL,
                        NULL,
                        NULL,
                        NULL,
                        NULL,
                        NULL,
                        p_encr_pan_in,
                        NULL,
                        NULL,
                        p_rvsl_code_in,
                        p_acct_number_in,
                        NVL (v_acct_balance, 0),
                        NVL (v_ledger_bal, 0),
                        v_resp_cde,
                        null,
                        p_card_stat_in,
                        NULL,
                        p_fee_flag_in,
                        v_err_msg,
                        'E',
                        v_cam_type_code,
                        v_timestamp);

       EXCEPTION
         WHEN OTHERS
         THEN
            ROLLBACK;
            p_resp_code_out := '69';
            p_resp_msg_out :=
               'Problem while inserting data into transaction log  '
               || SUBSTR (SQLERRM, 1, 300);
      END;
   --En create a entry in txn log
   WHEN OTHERS
   THEN
      ROLLBACK;

      BEGIN
         SELECT cam_acct_bal,
                cam_ledger_bal,
                cam_type_code
           INTO v_acct_balance,
                v_ledger_bal,
                v_cam_type_code
           FROM cms_acct_mast
          WHERE cam_acct_no = p_acct_number_in AND cam_inst_code = 1;
      EXCEPTION
         WHEN OTHERS
         THEN
            v_acct_balance := 0;
            v_ledger_bal := 0;
      END;

      --Sn select response code and insert record into txn log dtl
      BEGIN
         SELECT cms_iso_respcde
           INTO p_resp_code_out
           FROM cms_response_mast
          WHERE     cms_inst_code = 1
                AND cms_delivery_channel = p_delivery_channel_in
                AND cms_response_id = v_resp_cde;

         p_resp_msg_out := v_err_msg;
      EXCEPTION
         WHEN OTHERS
         THEN
            p_resp_msg_out :=
                  'Problem while selecting data from response master '
               || v_resp_cde
               || SUBSTR (SQLERRM, 1, 300);
            p_resp_code_out := '69';
       END;

      BEGIN
         INSERT INTO cms_transaction_log_dtl (ctd_delivery_channel,
                                              ctd_txn_code,
                                              ctd_txn_type,
                                              ctd_msg_type,
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
                                              ctd_inst_code,
                                              ctd_customer_card_no_encr,
                                              ctd_cust_acct_number)
              VALUES (p_delivery_channel_in,
                      p_txn_code_in,
                      v_txn_type,
                      p_msg_in,
                      p_txn_mode_in,
                      p_tran_date_in,
                      p_tran_time_in,
                      p_hash_pan_in,
                      p_txn_amt_in,
                      p_curr_code_in,
                      p_txn_amt_in,
                      NULL,
                      NULL,
                      NULL,
                      NULL,
                      p_txn_amt_in,
                      840,
                      'E',
                      v_err_msg,
                      p_rrn_in,
                      null,
                      1,
                      p_encr_pan_in,
                      p_acct_number_in);
      EXCEPTION
         WHEN OTHERS
         THEN
            p_resp_msg_out :=
               'Problem while inserting data into transaction log  dtl'
               || SUBSTR (SQLERRM, 1, 300);
            p_resp_code_out := '69';
      END;

      v_timestamp := SYSTIMESTAMP;

      --Sn create a entry in txn log
      BEGIN
         INSERT INTO transactionlog (msgtype,
                                     rrn,
                                     delivery_channel,
                                     terminal_id,
                                     date_time,
                                     txn_code,
                                     txn_type,
                                     txn_mode,
                                     txn_status,
                                     response_code,
                                     business_date,
                                     business_time,
                                     customer_card_no,
                                     topup_card_no,
                                     topup_acct_no,
                                     topup_acct_type,
                                     bank_code,
                                     total_amount,
                                     rule_indicator,
                                     rulegroupid,
                                     mccode,
                                     currencycode,
                                     addcharge,
                                     productid,
                                     categoryid,
                                     tips,
                                     decline_ruleid,
                                     atm_name_location,
                                     auth_id,
                                     trans_desc,
                                     amount,
                                     preauthamount,
                                     partialamount,
                                     mccodegroupid,
                                     currencycodegroupid,
                                     transcodegroupid,
                                     rules,
                                     preauth_date,
                                     gl_upd_flag,
                                     system_trace_audit_no,
                                     instcode,
                                     feecode,
                                     tranfee_amt,
                                     servicetax_amt,
                                     cess_amt,
                                     cr_dr_flag,
                                     tranfee_cr_acctno,
                                     tranfee_dr_acctno,
                                     tran_st_calc_flag,
                                     tran_cess_calc_flag,
                                     tran_st_cr_acctno,
                                     tran_st_dr_acctno,
                                     tran_cess_cr_acctno,
                                     tran_cess_dr_acctno,
                                     customer_card_no_encr,
                                     topup_card_no_encr,
                                     proxy_number,
                                     reversal_code,
                                     customer_acct_no,
                                     acct_balance,
                                     ledger_balance,
                                     response_id,
                                     ipaddress,
                                     cardstatus,
                                     fee_plan,
                                     csr_achactiontaken,
                                     error_msg,
                                     processes_flag,
                                     acct_type,
                                     time_stamp)
              VALUES (
                        p_msg_in,
                        p_rrn_in,
                        p_delivery_channel_in,
                        p_term_id_in,
                        v_business_date,
                        p_txn_code_in,
                        v_txn_type,
                        p_txn_mode_in,
                        DECODE (p_resp_code_out, '00', 'C', 'F'),
                        p_resp_code_out,
                        p_tran_date_in,
                        SUBSTR (p_tran_time_in, 1, 10),
                        p_hash_pan_in,
                        NULL,
                        NULL,
                        NULL,
                        1,
                        TRIM (
                           TO_CHAR (NVL (p_txn_amt_in, 0),
                                    '99999999999999999.99')),
                        '',
                        '',
                        null,
                        p_curr_code_in,
                        NULL,
                        v_prod_code,
                        v_card_type,
                        0,
                        '',
                        '',
                        v_auth_id,
                        'Card replacement update activity 30.5',
                        TRIM (
                           TO_CHAR (NVL (p_txn_amt_in, 0),
                                    '99999999999999999.99')),
                        '0.00',
                        '0.00',
                        '',
                        '',
                        '',
                        '',
                        '',
                        NULL,
                        null,
                        1,
                        NULL,
                        0,
                        NVL (0, 0),
                        NVL (0, 0),
                        v_dr_cr_flag,
                        NULL,
                        NULL,
                        NULL,
                        NULL,
                        NULL,
                        NULL,
                        NULL,
                        NULL,
                        p_encr_pan_in,
                        NULL,
                        NULL,
                        p_rvsl_code_in,
                        p_acct_number_in,
                        NVL (v_acct_balance, 0),
                        NVL (v_ledger_bal, 0),
                        v_resp_cde,
                        null,
                        p_card_stat_in,
                        NULL,
                        p_fee_flag_in,
                        v_err_msg,
                        'E',
                        v_cam_type_code,
                        v_timestamp);

       EXCEPTION
         WHEN OTHERS
         THEN
            ROLLBACK;
            p_resp_code_out := '69';
            p_resp_msg_out :=
               'Problem while inserting data into transaction log  '
               || SUBSTR (SQLERRM, 1, 300);
      END;
END;
/
show error