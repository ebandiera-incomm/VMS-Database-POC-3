create or replace PROCEDURE               VMSCMS.sp_chw_order_replace_r306 (
   p_inst_code          IN     NUMBER,
   p_msg                IN     VARCHAR2,
   p_rrn                IN     VARCHAR2,
   p_delivery_channel   IN     VARCHAR2,
   p_term_id            IN     VARCHAR2,
   p_txn_code           IN     VARCHAR2,
   p_txn_mode           IN     VARCHAR2,
   p_tran_date          IN     VARCHAR2,
   p_tran_time          IN     VARCHAR2,
   p_card_no            IN     VARCHAR2,
   p_bank_code          IN     VARCHAR2,
   p_txn_amt            IN     NUMBER,
   p_mcc_code           IN     VARCHAR2,
   p_curr_code          IN     VARCHAR2,
   p_prod_id            IN     VARCHAR2,
   p_expry_date         IN     VARCHAR2,
   p_stan               IN     VARCHAR2,
   p_mbr_numb           IN     VARCHAR2,
   p_rvsl_code          IN     NUMBER,
   p_ipaddress          IN     VARCHAR2,
   p_fee_flag           IN     VARCHAR2 ,
   p_auth_id            OUT    VARCHAR2,
   p_resp_code          OUT    VARCHAR2,
   p_resp_msg           OUT    VARCHAR2,
   p_capture_date       OUT    DATE,
   p_new_pan            OUT    VARCHAR2,
   p_catg_code          OUT    VARCHAR2)
IS
   /*****************************************************************************
    * Modified By      : Ubaidur Rahman H
    * Modified Date    : 05-Jun-2020
    * Purpose          : Update activity 30.6
    * Reviewer         : Saravanakumar

    ******************************************************************************/
   v_acct_balance               NUMBER;
   v_ledger_bal                 NUMBER;
   v_tran_amt                   NUMBER;
   v_auth_id                    transactionlog.auth_id%TYPE;
   v_total_amt                  NUMBER;
   v_tran_date                  DATE;
   v_resp_cde                   VARCHAR2 (5);
   v_dr_cr_flag                 VARCHAR2 (2);
   v_output_type                VARCHAR2 (2);
   v_err_msg                    VARCHAR2 (500);
   v_business_date_tran         DATE;
   v_business_time              VARCHAR2 (5);
   v_card_curr                  VARCHAR2 (5);
   v_business_date              DATE;
   v_txn_type                   NUMBER (1);
   exp_reject_record            EXCEPTION;
   v_hash_pan                   cms_appl_pan.cap_pan_code%TYPE;
   v_encr_pan                   cms_appl_pan.cap_pan_code_encr%TYPE;
   v_tran_type                  VARCHAR2 (2);
   v_acct_number                cms_appl_pan.cap_acct_no%TYPE;
   v_cap_card_stat              VARCHAR2 (10);
   crdstat_cnt                  VARCHAR2 (10);
   v_cro_oldcard_reissue_stat   VARCHAR2 (10);
   v_mbrnumb                    VARCHAR2 (10);
   new_dispname                 cms_appl_pan.cap_disp_name%TYPE;
   new_card_no                  VARCHAR2 (100);
   v_cap_prod_catg              VARCHAR2 (100);
   v_cust_code                  VARCHAR2 (100);
   p_remrk                      VARCHAR2 (100);
   v_resoncode                  cms_spprt_reasons.csr_spprt_rsncode%TYPE;
   v_dup_check                  NUMBER (3);
   v_cam_lupd_date              cms_addr_mast.cam_lupd_date%TYPE;
   v_new_hash_pan               cms_appl_pan.cap_pan_code%TYPE;
   v_appl_code                  cms_appl_pan.cap_appl_code%TYPE;
   v_cam_type_code              cms_acct_mast.cam_type_code%TYPE;
   v_timestamp                  TIMESTAMP;
   v_prod_code                  cms_appl_pan.cap_prod_code%TYPE;
   v_prod_cattype               cms_appl_pan.cap_card_type%TYPE;
   v_repl_option                cms_prod_cattype.cpc_renew_replace_option%TYPE;
   v_new_prodcode               cms_prod_cattype.cpc_renew_replace_prodcode%TYPE;
   v_new_cardtype               cms_prod_cattype.cpc_renew_replace_cardtype%TYPE;
   v_profile_code               cms_prod_cattype.cpc_profile_code%TYPE;
   v_expryparam                 cms_bin_param.cbp_param_value%TYPE;
   v_validity_period            cms_bin_param.cbp_param_value%TYPE;
   v_expiry_date                DATE;
   v_replace_provision_flag     cms_prod_cattype.cpc_replacement_provision_flag%TYPE;
   v_rrn                        vms_token_status_sync_dtls.vts_rrn%TYPE;
   v_stan                       vms_token_status_sync_dtls.vts_stan%TYPE;
   v_card_expdate                VARCHAR2 (100);
   V_token_pan_ref_id           vms_token_info.vti_token_pan_ref_id%TYPE;
   v_token_eligibility          cms_prod_cattype.cpc_token_eligibility%TYPE;
   v_token_count                NUMBER:=0;
   v_new_encr_pan               cms_appl_pan.cap_pan_code_encr%TYPE;
   v_query                      CLOB;
   v_token                      vms_token_info.vti_token_pan%TYPE;
   ref_cur_token                sys_refcursor;
   v_message_reasoncode         vms_token_status.vts_reason_code%TYPE;
   v_form_factor                cms_appl_pan.cap_form_factor%TYPE;
   v_Retperiod  date;  --Added for VMS-5739/FSP-991
v_Retdate  date; --Added for VMS-5739/FSP-991
BEGIN
   v_resp_cde := '1';
   v_err_msg := 'OK';
   p_resp_msg := 'OK';
   v_mbrnumb := p_mbr_numb;
   p_remrk := 'Online Order Replacement Card';

   --Sn create hash pan
   BEGIN
      v_hash_pan := gethash (p_card_no);
   EXCEPTION
      WHEN OTHERS
      THEN
         v_err_msg :=
               'Error while converting into hash value '
            || fn_mask (p_card_no,
                        'X',
                        7,
                        6)
            || ' '
            || SUBSTR (SQLERRM, 1, 200);
         RAISE exp_reject_record;
   END;

   --En create hash pan

   --Sn create encr pan
   BEGIN
      v_encr_pan := fn_emaps_main (p_card_no);
   EXCEPTION
      WHEN OTHERS
      THEN
         v_err_msg :=
               'Error while converting into encrypted value '
            || fn_mask (p_card_no,
                        'X',
                        7,
                        6)
            || ' '
            || SUBSTR (SQLERRM, 1, 200);
         RAISE exp_reject_record;
   END;

   --En create encr pan

   --Sn Get PAN dtls
   BEGIN
      SELECT cap_prod_catg,
             cap_card_stat,
             cap_acct_no,
             cap_cust_code,
             cap_appl_code,
             cap_disp_name,
             cap_prod_code,
             cap_card_type,
             TO_CHAR(cap_expry_date,'MMYY'),
             cap_form_factor
        INTO v_cap_prod_catg,
             v_cap_card_stat,
             v_acct_number,
             v_cust_code,
             v_appl_code,
             new_dispname,
             v_prod_code,
             v_prod_cattype,
             v_card_expdate,
             v_form_factor
        FROM cms_appl_pan
       WHERE cap_pan_code = v_hash_pan AND cap_inst_code = p_inst_code;
   EXCEPTION
      WHEN NO_DATA_FOUND
      THEN
         v_err_msg := 'Pan not found in master';
         v_resp_cde := '21';
         RAISE exp_reject_record;
      WHEN OTHERS
      THEN
         v_err_msg :=
            'Error while selecting CMS_APPL_PAN' || SUBSTR (SQLERRM, 1, 200);
         v_resp_cde := '21';
         RAISE exp_reject_record;
   END;

   --En Get PAN dtls

   --Sn Get business date
   BEGIN
      v_business_date :=
         TO_DATE (
               SUBSTR (TRIM (p_tran_date), 1, 8)
            || ' '
            || SUBSTR (TRIM (p_tran_time), 1, 10),
            'yyyymmdd hh24:mi:ss');
   EXCEPTION
      WHEN OTHERS
      THEN
         v_resp_cde := '32';
         v_err_msg :=
            'Problem while converting transaction date time '
            || SUBSTR (SQLERRM, 1, 200);
         RAISE exp_reject_record;
   END;

   --En Get business date

   --Sn find debit and credit flag
   BEGIN
      SELECT ctm_credit_debit_flag,
             ctm_output_type,
             TO_NUMBER (DECODE (ctm_tran_type,  'N', '0',  'F', '1')),
             ctm_tran_type
        INTO v_dr_cr_flag,
             v_output_type,
             v_txn_type,
             v_tran_type
        FROM cms_transaction_mast
       WHERE     ctm_tran_code = p_txn_code
             AND ctm_delivery_channel = p_delivery_channel
             AND ctm_inst_code = p_inst_code;
   EXCEPTION
      WHEN NO_DATA_FOUND
      THEN
         v_resp_cde := '12';
         v_err_msg :=
               'Transflag  not defined for txn code '
            || p_txn_code
            || ' and delivery channel '
            || p_delivery_channel;
         RAISE exp_reject_record;
      WHEN OTHERS
      THEN
         v_resp_cde := '21';
         v_err_msg := 'Error while selecting transaction details';
         RAISE exp_reject_record;
   END;

   --En find debit and credit flag

   -- Sn Digital Card replacement check

   IF v_form_factor = 'V'
   THEN
         v_resp_cde := '145';
         v_err_msg := 'Replacement Not Allowed For Digital Card';
         RAISE exp_reject_record;
   END IF;

   -- En Digital Card replacement check

   --Sn Duplicate card Replacement check
   BEGIN
      SELECT COUNT (1)
        INTO v_dup_check
        FROM cms_htlst_reisu
       WHERE     chr_inst_code = p_inst_code
             AND chr_pan_code = v_hash_pan
             AND chr_reisu_cause = 'R'
             AND chr_new_pan IS NOT NULL;

      IF v_dup_check > 0
      THEN
         v_resp_cde := '159';
         v_err_msg := 'Card already Replaced';
         RAISE exp_reject_record;
      END IF;
   END;

   --En Duplicate card Replacement check

   --Sn address updation in last 24 hrs check
   IF p_delivery_channel <> '03'
   THEN
      BEGIN
         SELECT cam_lupd_date
           INTO v_cam_lupd_date
           FROM cms_addr_mast
          WHERE     cam_inst_code = p_inst_code
                AND cam_cust_code = v_cust_code
                AND cam_addr_flag = 'P';

         IF v_cam_lupd_date > SYSDATE - 1
         THEN
            v_err_msg :=
               'Card replacement is not allowed to customer who changed address in last 24 hr';
            v_resp_cde := '21';
            RAISE exp_reject_record;
         END IF;
      EXCEPTION
         WHEN exp_reject_record
         THEN
            RAISE;
         WHEN OTHERS
         THEN
            v_err_msg :=
               'Error while selecting customer address details'
               || SUBSTR (SQLERRM, 1, 200);
            v_resp_cde := '21';
            RAISE exp_reject_record;
      END;
   END IF;

   --En address updation in last 24 hrs check

   --Sn find the tran amt
   IF ( (v_tran_type = 'F') OR (p_msg = '0100'))
   THEN
      IF (p_txn_amt >= 0)
      THEN
         v_tran_amt := p_txn_amt;

         BEGIN
            sp_convert_curr (p_inst_code,
                             p_curr_code,
                             p_card_no,
                             p_txn_amt,
                             v_tran_date,
                             v_tran_amt,
                             v_card_curr,
                             v_err_msg,
                             v_prod_code,
                             v_prod_cattype
                             );

            IF v_err_msg <> 'OK'
            THEN
               v_resp_cde := '44';
               RAISE exp_reject_record;
            END IF;
         EXCEPTION
            WHEN exp_reject_record
            THEN
               RAISE;
            WHEN OTHERS
            THEN
               v_resp_cde := '69';
               v_err_msg :=
                  'Error from currency conversion '
                  || SUBSTR (SQLERRM, 1, 200);
               RAISE exp_reject_record;
         END;
      ELSE
         v_resp_cde := '43';
         v_err_msg := 'INVALID AMOUNT';
         RAISE exp_reject_record;
      END IF;
   END IF;

   --En find the tran amt

   --Sn authorize txn
   BEGIN
      sp_authorize_txn_cms_auth (p_inst_code,
                                 p_msg,
                                 p_rrn,
                                 p_delivery_channel,
                                 p_term_id,
                                 p_txn_code,
                                 p_txn_mode,
                                 p_tran_date,
                                 p_tran_time,
                                 p_card_no,
                                 p_inst_code,
                                 p_txn_amt,
                                 NULL,
                                 NULL,
                                 p_mcc_code,
                                 p_curr_code,
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
                                 p_expry_date,
                                 p_stan,
                                 p_mbr_numb,
                                 p_rvsl_code,
                                 p_txn_amt,
                                 p_auth_id,
                                 v_resp_cde,
                                 v_err_msg,
                                 p_capture_date,
                                 p_fee_flag);

      IF v_resp_cde <> '00' AND v_err_msg <> 'OK'
      THEN
         p_resp_code := v_resp_cde;

         p_resp_msg := 'Error from auth process' || v_err_msg;

         RETURN;
      END IF;
   EXCEPTION
      WHEN OTHERS
      THEN
         v_resp_cde := '21';
         v_err_msg :=
            'Error from Card authorization' || SUBSTR (SQLERRM, 1, 200);
         RAISE exp_reject_record;
   END;

   --En authorize txn

   --Sn Valid card stat check
   BEGIN
      SELECT COUNT (*)
        INTO crdstat_cnt
        FROM cms_reissue_validstat
       WHERE     crv_inst_code = p_inst_code
             AND crv_valid_crdstat = v_cap_card_stat
             AND crv_prod_catg IN ('P');

      IF crdstat_cnt = 0
      THEN
         v_err_msg := 'Not a valid card status. Card cannot be reissued';
         v_resp_cde := '09';
         RAISE exp_reject_record;
      END IF;
   END;

   --En Valid card stat check

   BEGIN
      SELECT nvl(cpc_renew_replace_option,'NP'), cpc_profile_code, cpc_renew_replace_prodcode, cpc_renew_replace_cardtype,NVL(CPC_REPLACEMENT_PROVISION_FLAG,'N'),cpc_token_eligibility
        INTO v_repl_option, v_profile_code, v_new_prodcode, v_new_cardtype,v_replace_provision_flag,v_token_eligibility
        FROM cms_prod_cattype
       WHERE     cpc_inst_code = p_inst_code
             AND cpc_prod_code = v_prod_code
             AND cpc_card_type = v_prod_cattype;
   EXCEPTION
      WHEN OTHERS
      THEN
         v_err_msg :=
            'Error while selecting replacement param '
            || SUBSTR (SQLERRM, 1, 200);
          v_resp_cde := '21';
         RAISE exp_reject_record;
   END;

   IF v_token_eligibility = 'Y' THEN
    BEGIN
      select count(*)
      INTO v_token_count
      from vms_token_info
      where vti_acct_no  = v_acct_number;
    END;
   END IF;

   IF v_token_count > 0 THEN
     BEGIN
      SELECT vti_token_pan_ref_id
      INTO v_token_pan_ref_id
      FROM vms_token_info
      WHERE vti_token_pan = v_hash_pan
      AND ROWNUM          =1;
    EXCEPTION
    WHEN NO_DATA_FOUND THEN
      v_err_msg  := 'Pan ref id not found ';
      v_resp_cde := '21';
      RAISE exp_reject_record;
    WHEN OTHERS THEN
      v_err_msg  := 'Error while selecting pan ref id ' || SUBSTR (SQLERRM, 1, 200);
      v_resp_cde := '21';
      RAISE exp_reject_record;
    END;
     BEGIN
        SELECT   vts_reason_code
        INTO  v_message_reasoncode
        FROM CMS_CARD_STAT,
          vms_token_status
        WHERE CCS_STAT_CODE = v_cap_card_stat
        AND CCS_TOKEN_STAT  = vts_token_stat;
      EXCEPTION
      WHEN OTHERS THEN
        v_err_msg := 'Error while selecting token status '|| SUBSTR (SQLERRM, 1, 300);
        RAISE exp_reject_record;
      END;
   END IF;
   IF v_repl_option = 'SP' AND v_cap_card_stat <> '2'
   THEN
      IF v_profile_code IS NULL
      THEN
         v_err_msg := 'Profile is not Attached to Product cattype';
         v_resp_cde := '21';
         RAISE exp_reject_record;
      END IF;

      BEGIN
            vmsfunutilities.get_expiry_date(P_INST_CODE,v_prod_code,
            v_prod_cattype,V_PROFILE_CODE,v_expiry_date,v_err_msg);

            if v_err_msg<>'OK' then
            RAISE exp_reject_record;
         END IF;


      EXCEPTION
              WHEN EXP_REJECT_RECORD THEN
            RAISE;
              WHEN OTHERS THEN
                v_err_msg:='Error while calling vmsfunutilities.get_expiry_date'||substr(sqlerrm,1,200);
            RAISE exp_reject_record;
      END;




      --Sn Update new expry
      BEGIN
         UPDATE cms_appl_pan
            SET cap_replace_exprydt = v_expiry_date,
                    cap_repl_flag=6
          WHERE cap_inst_code = p_inst_code AND cap_pan_code = v_hash_pan;

         IF SQL%ROWCOUNT <> 1
         THEN
            v_err_msg := 'Error while updating appl_pan ';
            v_resp_cde := '21';
            RAISE exp_reject_record;
         END IF;
      EXCEPTION
         WHEN exp_reject_record
         THEN
            RAISE;
         WHEN OTHERS
         THEN
            v_err_msg :=
               'Error while updating Expiry Date' || SUBSTR (SQLERRM, 1, 200);
            v_resp_cde := '21';
            RAISE exp_reject_record;
      END;

      --En Update new expry

      --Sn Update application status as printer pending
      BEGIN
         UPDATE cms_cardissuance_status
            SET ccs_card_status = '20'
          WHERE ccs_inst_code = p_inst_code AND ccs_pan_code = v_hash_pan;

         IF SQL%ROWCOUNT <> 1
         THEN
            v_err_msg := 'Error while updating CMS_CARDISSUANCE_STATUS ';
            v_resp_cde := '21';
            RAISE exp_reject_record;
         END IF;
      EXCEPTION
         WHEN exp_reject_record
         THEN
            RAISE;
         WHEN OTHERS
         THEN
            v_err_msg :=
               'Error while updating Application Card Issuance Status'
               || SUBSTR (SQLERRM, 1, 200);
            v_resp_cde := '21';
            RAISE exp_reject_record;
      END;
   --En Update application status as printer pending

        p_catg_code := v_cap_prod_catg;
		p_new_pan := p_card_no;

		IF v_token_count > 0 THEN

   BEGIN
        v_query  := 'SELECT vti_token FROM vms_token_info  WHERE  vti_token_pan = '''||v_hash_pan||'''
                              AND vti_token_stat <>''D''';
    OPEN ref_cur_token FOR v_query;
    LOOP
      FETCH ref_cur_token
      INTO v_token;
       EXIT
    WHEN ref_cur_token%NOTFOUND;
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
              v_hash_pan,
              v_token,
              v_message_reasoncode,
              systimestamp,
              v_encr_pan,
              p_rrn,
              v_rrn,
              v_stan,
              v_card_expdate,
              v_acct_number,
              v_cap_card_stat,
              'R'
            );

         EXCEPTION
        WHEN OTHERS THEN
          v_err_msg :='Error While inserting into token_status_sync_dtls-'||SUBSTR(SQLERRM, 1, 100);
          RAISE exp_reject_record;
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
                v_hash_pan,
                '3720',
                systimestamp,
                v_encr_pan,
                p_rrn,
                v_rrn,
                v_stan,
                v_card_expdate,
                v_token_pan_ref_id,
                v_hash_pan,
                v_encr_pan,
                TO_CHAR(v_expiry_date,'MMYY') ,
                v_acct_number,
                v_cap_card_stat,
                'R'
              );

  EXCEPTION
    WHEN OTHERS THEN
        v_err_msg :='Error While inserting into token_status_sync_dtls-'||SUBSTR(SQLERRM, 1, 100);
        RAISE exp_reject_record;
   END;

  END IF;
   ELSE
      IF v_repl_option='NPP' THEN
             v_prod_code:=v_new_prodcode;
             v_prod_cattype:=v_new_cardtype;
      END IF;

      BEGIN
         SELECT cro_oldcard_reissue_stat
           INTO v_cro_oldcard_reissue_stat
           FROM cms_reissue_oldcardstat
          WHERE     cro_inst_code = p_inst_code
                AND cro_oldcard_stat = v_cap_card_stat
                AND cro_spprt_key = 'R';
      EXCEPTION
         WHEN NO_DATA_FOUND
         THEN
            v_err_msg :=
               'Default old card status nor defined for institution '
               || p_inst_code;
            v_resp_cde := '09';
            RAISE exp_reject_record;
         WHEN OTHERS
         THEN
            v_err_msg :=
               'Error while getting default old card status for institution '
               || p_inst_code;
            v_resp_cde := '21';
            RAISE exp_reject_record;
      END;

      BEGIN
         UPDATE cms_appl_pan
            SET cap_card_stat = v_cro_oldcard_reissue_stat,
                cap_lupd_user = p_bank_code
          WHERE cap_inst_code = p_inst_code AND cap_pan_code = v_hash_pan;

         IF SQL%ROWCOUNT != 1
         THEN
            v_err_msg := 'Problem in updation of status for pan ';
            v_resp_cde := '09';
            RAISE exp_reject_record;
         END IF;
      EXCEPTION
         WHEN OTHERS
         THEN
            v_err_msg :=
               'Error while updating CMS_APPL_PAN'
               || SUBSTR (SQLERRM, 1, 200);
            v_resp_cde := '21';
            RAISE exp_reject_record;
      END;

      IF v_cro_oldcard_reissue_stat = '9'
      THEN
         BEGIN
            sp_log_cardstat_chnge (p_inst_code,
                                   v_hash_pan,
                                   v_encr_pan,
                                   p_auth_id,
                                   '02',
                                   p_rrn,
                                   p_tran_date,
                                   p_tran_time,
                                   v_resp_cde,
                                   v_err_msg);

            IF v_resp_cde <> '00' AND v_err_msg <> 'OK'
            THEN
               RAISE exp_reject_record;
            END IF;
         EXCEPTION
            WHEN exp_reject_record
            THEN
               RAISE;
            WHEN OTHERS
            THEN
               v_resp_cde := '21';
               v_err_msg :=
                  'Error while logging system initiated card status change '
                  || SUBSTR (SQLERRM, 1, 200);
               RAISE exp_reject_record;
         END;
      END IF;

      BEGIN
         SP_ORDER_REISSUEPAN_CMS_R306 (p_inst_code,
                                       p_card_no,
                                       v_prod_code,
                                       v_prod_cattype,
                                       new_dispname,
                                       p_bank_code,
                                       new_card_no,
									   p_catg_code,
                                       v_err_msg);

         IF v_err_msg != 'OK'
         THEN
            v_err_msg := 'From reissue pan generation process-- ' || v_err_msg;
            v_resp_cde := '21';
            RAISE exp_reject_record;
         END IF;
      EXCEPTION
         WHEN exp_reject_record
         THEN
            RAISE;
         WHEN OTHERS
         THEN
            v_err_msg := 'From reissue pan generation process-- ' || v_err_msg;
            v_resp_cde := '21';
            RAISE exp_reject_record;
      END;

      --Sn hash the new Pan no
      BEGIN
         v_new_hash_pan := gethash (new_card_no);
		 p_new_pan:=new_card_no;
      EXCEPTION
         WHEN OTHERS
         THEN
            v_err_msg :=
                  'Error while converting new pan. into hash value '
               || fn_mask (new_card_no,
                           'X',
                           7,
                           6)
               || ' '
               || SUBSTR (SQLERRM, 1, 200);
            RAISE exp_reject_record;
      END;

      --En hash the new Pan no
     BEGIN
          v_new_encr_pan := fn_emaps_main (new_card_no);
       EXCEPTION
          WHEN OTHERS
          THEN
             v_err_msg :=
                   'Error while converting into encrypted value '
                || fn_mask (new_card_no,
                            'X',
                            7,
                            6)
                || ' '
                || SUBSTR (SQLERRM, 1, 200);
             RAISE exp_reject_record;
       END;
         BEGIN
            UPDATE cms_appl_pan
               SET cap_repl_flag = 6
             WHERE cap_inst_code = p_inst_code
                   AND cap_pan_code = v_new_hash_pan;

            IF SQL%ROWCOUNT = 0
            THEN
               v_err_msg :=
                  'Problem in updation of replacement flag for pan '
                  || fn_mask (new_card_no,
                              'X',
                              7,
                              6);
               v_resp_cde := '21';
               RAISE exp_reject_record;
            END IF;
         EXCEPTION
            WHEN OTHERS
            THEN
               v_err_msg :=
                  'Error while updating CMS_APPL_PAN'
                  || SUBSTR (SQLERRM, 1, 200);
               v_resp_cde := '21';
               RAISE exp_reject_record;
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
                 VALUES (p_inst_code,
                         v_hash_pan,
                         v_mbrnumb,
                         v_new_hash_pan,
                         v_mbrnumb,
                         'R',
                         p_bank_code,
                         p_bank_code,
                         v_encr_pan,
                         v_new_encr_pan);
         EXCEPTION
            WHEN OTHERS
            THEN
               v_err_msg :=
                  'Error while creating  reissuue record '
                  || SUBSTR (SQLERRM, 1, 200);
               v_resp_cde := '21';
               RAISE exp_reject_record;
         END;

         BEGIN
            INSERT INTO cms_cardissuance_status (ccs_inst_code,
                                                 ccs_pan_code,
                                                 ccs_card_status,
                                                 ccs_ins_user,
                                                 ccs_ins_date,
                                                 ccs_pan_code_encr,
                                                 ccs_appl_code)
                 VALUES (p_inst_code,
                         v_new_hash_pan,
                         '2',
                         p_bank_code,
                         SYSDATE,
                         fn_emaps_main (new_card_no),
                         v_appl_code);
         EXCEPTION
            WHEN OTHERS
            THEN
               v_err_msg :=
                  'Error while Inserting CCF table '
                  || SUBSTR (SQLERRM, 1, 200);
               v_resp_cde := '21';
               RAISE exp_reject_record;
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
               (SELECT p_inst_code,
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
                       p_bank_code,
                       SYSDATE,
                       p_bank_code,
                       SYSDATE
                  FROM cms_smsandemail_alert
                 WHERE csa_inst_code = p_inst_code
                       AND csa_pan_code = v_hash_pan);

            IF SQL%ROWCOUNT != 1
            THEN
               v_err_msg :=
                  'Error while Entering sms email alert detail '
                  || SUBSTR (SQLERRM, 1, 200);
               v_resp_cde := '21';
               RAISE exp_reject_record;
            END IF;
         EXCEPTION
            WHEN OTHERS
            THEN
               v_err_msg :=
                  'Error while Entering sms email alert detail '
                  || SUBSTR (SQLERRM, 1, 200);
               v_resp_cde := '21';
               RAISE exp_reject_record;
         END;

         --AVQ Added for FSS-1961(Melissa)
         BEGIN
            sp_logavqstatus (p_inst_code,
                             p_delivery_channel,
                             new_card_no,
                             v_prod_code,
                             v_cust_code,
                             v_resp_cde,
                             v_err_msg,
                             v_prod_cattype);

            IF v_err_msg != 'OK'
            THEN
               v_err_msg :=
                  'Exception while calling LOGAVQSTATUS-- ' || v_err_msg;
               v_resp_cde := '21';
               RAISE exp_reject_record;
            END IF;
         EXCEPTION
            WHEN exp_reject_record
            THEN
               RAISE;
            WHEN OTHERS
            THEN
               v_err_msg :=
                  'Exception in LOGAVQSTATUS-- ' || SUBSTR (SQLERRM, 1, 200);
               v_resp_cde := '21';
               RAISE exp_reject_record;
         END;
      --End  Added for FSS-1961(Melissa)
      END IF;
  IF v_token_count > 0 THEN
    IF  v_replace_provision_flag ='Y' THEN

      BEGIN
      v_query  := 'SELECT vti_token FROM vms_token_info  WHERE  vti_token_pan = '''||v_hash_pan||'''
                          AND vti_token_stat <>''D''';
      OPEN ref_cur_token FOR v_query;
      LOOP
        FETCH ref_cur_token
        INTO v_token;
         EXIT
      WHEN ref_cur_token%NOTFOUND;
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
              v_hash_pan,
              v_token,
              v_message_reasoncode,
              systimestamp,
              v_encr_pan,
              p_rrn,
              v_rrn,
              v_stan,
              v_card_expdate,
              v_acct_number,
              v_cap_card_stat,
              'R'
            );

         EXCEPTION
        WHEN OTHERS THEN
          v_err_msg :='Error While inserting into token_status_sync_dtls-'||SUBSTR(SQLERRM, 1, 100);
          RAISE exp_reject_record;
          END;
        END LOOP;
        END;

        IF v_cro_oldcard_reissue_stat = '9' THEN
         BEGIN
              BEGIN
                  SELECT cap_expry_date
                    INTO v_expiry_date
                    FROM cms_appl_pan
                   WHERE cap_pan_code = v_new_hash_pan AND cap_inst_code = p_inst_code;
               EXCEPTION
                  WHEN NO_DATA_FOUND
                  THEN
                     v_err_msg := 'Pan not found in master';
                     v_resp_cde := '21';
                     RAISE exp_reject_record;
                  WHEN OTHERS
                  THEN
                     v_err_msg :=
                        'Error while selecting CMS_APPL_PAN' || SUBSTR (SQLERRM, 1, 200);
                     v_resp_cde := '21';
                     RAISE exp_reject_record;
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
                        v_hash_pan,
                        '3721',
                        systimestamp,
                        v_encr_pan,
                        p_rrn,
                        v_rrn,
                        v_stan,
                        v_card_expdate,
                        v_token_pan_ref_id,
                        v_new_hash_pan,
                        v_new_encr_pan,
                        TO_CHAR(v_expiry_date,'MMYY') ,
                        v_acct_number,
                        v_cap_card_stat,
                        'R'
                      );

        EXCEPTION
        WHEN exp_reject_record THEN
        RAISE;
        WHEN OTHERS THEN
          v_err_msg :='Error While inserting into token_status_sync_dtls-'||SUBSTR(SQLERRM, 1, 100);
          RAISE exp_reject_record;
           END;
       END IF;

    ELSE
        BEGIN
        v_query  := 'SELECT vti_token FROM vms_token_info  WHERE  vti_token_pan = '''||v_hash_pan||'''
                              AND vti_token_stat <>''D''';
    OPEN ref_cur_token FOR v_query;
    LOOP
      FETCH ref_cur_token
      INTO v_token;
       EXIT
    WHEN ref_cur_token%NOTFOUND;
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
              v_hash_pan,
              v_token,
              '3701',
              systimestamp,
              v_encr_pan,
              p_rrn,
              v_rrn,
              v_stan,
              v_card_expdate,
              v_acct_number,
              v_cap_card_stat,
              'R'
            );

         EXCEPTION
        WHEN OTHERS THEN
          v_err_msg :='Error While inserting into token_status_sync_dtls-'||SUBSTR(SQLERRM, 1, 100);
          RAISE exp_reject_record;
          END;
        END LOOP;
        END;
    END IF;
  END IF;
   END IF;

   p_resp_msg := new_card_no;

   --Sn Selecting Reason code for Initial Load
   BEGIN
      SELECT csr_spprt_rsncode
        INTO v_resoncode
        FROM cms_spprt_reasons
       WHERE     csr_inst_code = p_inst_code
             AND csr_spprt_key = 'REISSUE'
             AND ROWNUM < 2;
   EXCEPTION
      WHEN NO_DATA_FOUND
      THEN
         v_resp_cde := '21';
         v_err_msg :=
            'Order Replacement card reason code is present in master';
         RAISE exp_reject_record;
      WHEN OTHERS
      THEN
         v_resp_cde := '21';
         v_err_msg :=
            'Error while selecting reason code from master'
            || SUBSTR (SQLERRM, 1, 200);
         RAISE exp_reject_record;
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
           VALUES (p_inst_code,
                   v_hash_pan,
                   p_mbr_numb,
                   v_cap_prod_catg,
                   'REISSUE',
                   v_resoncode,
                   p_remrk,
                   p_bank_code,
                   p_bank_code,
                   0,
                   v_encr_pan);
   EXCEPTION
      WHEN OTHERS
      THEN
         v_resp_cde := '21';
         v_err_msg :=
            'Error while inserting records into card support master'
            || SUBSTR (SQLERRM, 1, 200);

         RAISE exp_reject_record;
   END;

   --En create a record in pan spprt

   v_resp_cde := '1';

   BEGIN
      SELECT cms_iso_respcde
        INTO p_resp_code
        FROM cms_response_mast
       WHERE     cms_inst_code = p_inst_code
             AND cms_delivery_channel = p_delivery_channel
             AND cms_response_id = TO_NUMBER (v_resp_cde);
   EXCEPTION
      WHEN OTHERS
      THEN
         v_err_msg :=
            'Problem while selecting data from response master for respose code'
            || v_resp_cde
            || SUBSTR (SQLERRM, 1, 300);
         v_resp_cde := '21';
         RAISE exp_reject_record;
   END;

   --0010762
   BEGIN
   --Added for VMS-5739/FSP-991
 select (add_months(trunc(sysdate,'MM'),'-'||RETENTION_PERIOD))
       INTO   v_Retperiod 
       FROM DBA_OPERATIONS.ARCHIVE_MGMNT_CTL 
       WHERE  OPERATION_TYPE='ARCHIVE' 
       AND OBJECT_NAME='TRANSACTIONLOG_EBR';
       
       v_Retdate := TO_DATE(SUBSTR(TRIM(p_tran_date), 1, 8), 'yyyymmdd');


IF (v_Retdate>v_Retperiod)
    THEN
      UPDATE VMSCMS.transactionlog
         SET ipaddress = p_ipaddress
       WHERE     rrn = p_rrn
             AND business_date = p_tran_date
             AND txn_code = p_txn_code
             AND msgtype = p_msg
             AND business_time = p_tran_time
             AND delivery_channel = p_delivery_channel;
ELSE
			UPDATE VMSCMS_HISTORY.transactionlog_HIST
         SET ipaddress = p_ipaddress
       WHERE     rrn = p_rrn
             AND business_date = p_tran_date
             AND txn_code = p_txn_code
             AND msgtype = p_msg
             AND business_time = p_tran_time
             AND delivery_channel = p_delivery_channel;
END IF;			 
   EXCEPTION
      WHEN OTHERS
      THEN
         v_resp_cde := '69';
         v_err_msg :=
            'Problem while inserting data into transaction log'
            || SUBSTR (SQLERRM, 1, 300);
   END;
EXCEPTION
   --<< MAIN EXCEPTION >>
   WHEN exp_reject_record
   THEN
      ROLLBACK;

      BEGIN
         SELECT cam_acct_bal,
                cam_ledger_bal,
                cam_type_code,
                cam_acct_no
           INTO v_acct_balance,
                v_ledger_bal,
                v_cam_type_code,
                v_acct_number
           FROM cms_acct_mast
          WHERE cam_acct_no = v_acct_number AND cam_inst_code = p_inst_code;
      EXCEPTION
         WHEN OTHERS
         THEN
            v_acct_balance := 0;
            v_ledger_bal := 0;
      END;

      --Sn select response code and insert record into txn log dtl
      BEGIN
         p_resp_code := v_resp_cde;
         p_resp_msg := v_err_msg;

         SELECT cms_iso_respcde
           INTO p_resp_code
           FROM cms_response_mast
          WHERE     cms_inst_code = p_inst_code
                AND cms_delivery_channel = p_delivery_channel
                AND cms_response_id = v_resp_cde;
      EXCEPTION
         WHEN OTHERS
         THEN
            p_resp_msg :=
                  'Problem while selecting data from response master '
               || v_resp_cde
               || SUBSTR (SQLERRM, 1, 300);
            p_resp_code := '69';
            ROLLBACK;
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
              VALUES (p_delivery_channel,
                      p_txn_code,
                      v_txn_type,
                      p_msg,
                      p_txn_mode,
                      p_tran_date,
                      p_tran_time,
                      v_hash_pan,
                      p_txn_amt,
                      p_curr_code,
                      v_tran_amt,
                      NULL,
                      NULL,
                      NULL,
                      NULL,
                      v_total_amt,
                      v_card_curr,
                      'E',
                      v_err_msg,
                      p_rrn,
                      p_stan,
                      p_inst_code,
                      v_encr_pan,
                      v_acct_number);

         p_resp_msg := v_err_msg;
      EXCEPTION
         WHEN OTHERS
         THEN
            p_resp_msg :=
               'Problem while inserting data into transaction log  dtl'
               || SUBSTR (SQLERRM, 1, 300);
            p_resp_code := '69';
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
                        p_msg,
                        p_rrn,
                        p_delivery_channel,
                        p_term_id,
                        v_business_date,
                        p_txn_code,
                        v_txn_type,
                        p_txn_mode,
                        DECODE (p_resp_code, '00', 'C', 'F'),
                        p_resp_code,
                        p_tran_date,
                        SUBSTR (p_tran_time, 1, 10),
                        v_hash_pan,
                        NULL,
                        NULL,
                        NULL,
                        p_bank_code,
                        TRIM (
                           TO_CHAR (NVL (v_total_amt, 0),
                                    '99999999999999990.99')),
                        '',
                        '',
                        p_mcc_code,
                        p_curr_code,
                        NULL,
                        v_prod_code,
                        v_prod_cattype,
                        0,
                        '',
                        '',
                        v_auth_id,
                        'Card replacement update activity 30.5',
                        TRIM (
                           TO_CHAR (NVL (v_tran_amt, 0),
                                    '99999999999999990.99')),
                        '0.00',
                        '0.00',
                        '',
                        '',
                        '',
                        '',
                        '',
                        NULL,
                        p_stan,
                        p_inst_code,
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
                        v_encr_pan,
                        NULL,
                        NULL,
                        p_rvsl_code,
                        v_acct_number,
                        NVL (v_acct_balance, 0),
                        NVL (v_ledger_bal, 0),
                        v_resp_cde,
                        p_ipaddress,
                        v_cap_card_stat,
                        NULL,
                        p_fee_flag,
                        v_err_msg,
                        'E',
                        v_cam_type_code,
                        v_timestamp);

         p_capture_date := v_business_date;
         p_auth_id := v_auth_id;
      EXCEPTION
         WHEN OTHERS
         THEN
            ROLLBACK;
            p_resp_code := '69';
            p_resp_msg :=
               'Problem while inserting data into transaction log  '
               || SUBSTR (SQLERRM, 1, 300);
            RETURN;
      END;
   --En create a entry in txn log
   WHEN OTHERS
   THEN
      ROLLBACK;

      BEGIN
         SELECT cam_acct_bal,
                cam_ledger_bal,
                cam_type_code,
                cam_acct_no
           INTO v_acct_balance,
                v_ledger_bal,
                v_cam_type_code,
                v_acct_number
           FROM cms_acct_mast
          WHERE cam_acct_no = v_acct_number AND cam_inst_code = p_inst_code;
      EXCEPTION
         WHEN OTHERS
         THEN
            v_acct_balance := 0;
            v_ledger_bal := 0;
      END;

      --Sn select response code and insert record into txn log dtl
      BEGIN
         SELECT cms_iso_respcde
           INTO p_resp_code
           FROM cms_response_mast
          WHERE     cms_inst_code = p_inst_code
                AND cms_delivery_channel = p_delivery_channel
                AND cms_response_id = v_resp_cde;

         p_resp_msg := v_err_msg;
      EXCEPTION
         WHEN OTHERS
         THEN
            p_resp_msg :=
                  'Problem while selecting data from response master '
               || v_resp_cde
               || SUBSTR (SQLERRM, 1, 300);
            p_resp_code := '69';
            ROLLBACK;
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
              VALUES (p_delivery_channel,
                      p_txn_code,
                      v_txn_type,
                      p_msg,
                      p_txn_mode,
                      p_tran_date,
                      p_tran_time,
                      v_hash_pan,
                      p_txn_amt,
                      p_curr_code,
                      v_tran_amt,
                      NULL,
                      NULL,
                      NULL,
                      NULL,
                      v_total_amt,
                      v_card_curr,
                      'E',
                      v_err_msg,
                      p_rrn,
                      p_stan,
                      p_inst_code,
                      v_encr_pan,
                      v_acct_number);
      EXCEPTION
         WHEN OTHERS
         THEN
            p_resp_msg :=
               'Problem while inserting data into transaction log  dtl'
               || SUBSTR (SQLERRM, 1, 300);
            p_resp_code := '69';
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
                        p_msg,
                        p_rrn,
                        p_delivery_channel,
                        p_term_id,
                        v_business_date,
                        p_txn_code,
                        v_txn_type,
                        p_txn_mode,
                        DECODE (p_resp_code, '00', 'C', 'F'),
                        p_resp_code,
                        p_tran_date,
                        SUBSTR (p_tran_time, 1, 10),
                        v_hash_pan,
                        NULL,
                        NULL,
                        NULL,
                        p_bank_code,
                        TRIM (
                           TO_CHAR (NVL (v_total_amt, 0),
                                    '99999999999999999.99')),
                        '',
                        '',
                        p_mcc_code,
                        p_curr_code,
                        NULL,
                        v_prod_code,
                        v_prod_cattype,
                        0,
                        '',
                        '',
                        v_auth_id,
                        'Card replacement update activity 30.5',
                        TRIM (
                           TO_CHAR (NVL (v_tran_amt, 0),
                                    '99999999999999999.99')),
                        '0.00',
                        '0.00',
                        '',
                        '',
                        '',
                        '',
                        '',
                        NULL,
                        p_stan,
                        p_inst_code,
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
                        v_encr_pan,
                        NULL,
                        NULL,
                        p_rvsl_code,
                        v_acct_number,
                        NVL (v_acct_balance, 0),
                        NVL (v_ledger_bal, 0),
                        v_resp_cde,
                        p_ipaddress,
                        v_cap_card_stat,
                        NULL,
                        p_fee_flag,
                        v_err_msg,
                        'E',
                        v_cam_type_code,
                        v_timestamp);

         p_capture_date := v_business_date;
         p_auth_id := v_auth_id;
      EXCEPTION
         WHEN OTHERS
         THEN
            ROLLBACK;
            p_resp_code := '69';
            p_resp_msg :=
               'Problem while inserting data into transaction log  '
               || SUBSTR (SQLERRM, 1, 300);
            RETURN;
      END;
END;
/
SHOW ERROR;