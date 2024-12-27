CREATE OR REPLACE PROCEDURE VMSCMS.sp_upload_newcaf_pcms (
   prm_instcode   IN       NUMBER,
   prm_filename   IN       VARCHAR2,
   prm_lupduser   IN       NUMBER,
   prm_errmsg     OUT      VARCHAR2
)
AS
   v_tot_records           NUMBER (1);
   v_check_branch          NUMBER (1);
   v_check_cntry           NUMBER (1);
   v_check_custcatg        NUMBER (1);
   v_custcatg              cms_cust_catg.ccc_catg_sname%TYPE;
   v_custcatg_code         cms_cust_catg.ccc_catg_code%TYPE;
   v_prodcode              cms_prod_mast.cpm_prod_code%TYPE;
   v_check_product         NUMBER (1);
   v_card_type             cms_prod_cattype.cpc_card_type%TYPE;
   v_prod_ccc              cms_prod_ccc.cpc_prod_sname%TYPE;
   v_errmsg                VARCHAR2 (500);
   v_func_code             cms_func_mast.cfm_func_code%TYPE;
   v_func_desc             cms_func_mast.cfm_func_desc%TYPE;
   v_spprt_funccode        cms_func_mast.cfm_func_code%TYPE;
   v_spprtfunc_desc        cms_func_mast.cfm_func_desc%TYPE;
   v_check_spprtfunccode   NUMBER (1);
   v_check_funccode        NUMBER (1);
   v_initial_spprtflag     VARCHAR2 (1);
   v_cust_code             cms_cust_mast.ccm_cust_code%TYPE;
   v_gender                VARCHAR2 (3);
   v_gcm_cntry_code        gen_cntry_mast.gcm_cntry_code%TYPE;
   v_comm_addr_lin1        pcms_caf_info_temp.cci_seg12_addr_line1%TYPE;
   v_comm_addr_lin2        pcms_caf_info_temp.cci_seg12_addr_line2%TYPE;
   v_comm_postal_code      pcms_caf_info_temp.cci_seg12_postal_code%TYPE;
   v_comm_homephone_no     pcms_caf_info_temp.cci_seg12_homephone_no%TYPE;
   v_comm_mobileno         pcms_caf_info_temp.cci_seg12_mobileno%TYPE;
   v_comm_emailid          pcms_caf_info_temp.cci_seg12_emailid%TYPE;
   v_comm_city             pcms_caf_info_temp.cci_seg12_city%TYPE;
   v_comm_state            pcms_caf_info_temp.cci_seg12_state%TYPE;
   v_other_addr_lin1       pcms_caf_info_temp.cci_seg13_addr_line1%TYPE;
   v_other_addr_lin2       pcms_caf_info_temp.cci_seg13_addr_line2%TYPE;
   v_other_postal_code     pcms_caf_info_temp.cci_seg13_postal_code%TYPE;
   v_other_homephone_no    pcms_caf_info_temp.cci_seg13_homephone_no%TYPE;
   v_other_mobileno        pcms_caf_info_temp.cci_seg13_mobileno%TYPE;
   v_other_emailid         pcms_caf_info_temp.cci_seg13_emailid%TYPE;
   v_other_city            pcms_caf_info_temp.cci_seg13_city%TYPE;
   v_other_state           pcms_caf_info_temp.cci_seg12_state%TYPE;
   v_comm_addrcode         cms_addr_mast.cam_addr_code%TYPE;
   v_other_addrcode        cms_addr_mast.cam_addr_code%TYPE;
   v_switch_acct_type      cms_acct_type.cat_switch_type%TYPE    DEFAULT '11';
   v_switch_acct_stat      cms_acct_stat.cas_switch_statcode%TYPE DEFAULT '3';
   v_acct_type             cms_acct_type.cat_type_code%TYPE;
   v_acct_stat             cms_acct_mast.cam_stat_code%TYPE;
   v_acct_numb             cms_acct_mast.cam_acct_no%TYPE;
   v_acct_id               cms_acct_mast.cam_acct_id%TYPE;
   v_dup_flag              VARCHAR2 (1);
   v_holdposn              cms_cust_acct.cca_hold_posn%TYPE;
   v_expryparam            cms_inst_param.cip_param_value%TYPE;
   v_appl_code             cms_appl_mast.cam_appl_code%TYPE;
   v_catg_code             cms_prod_mast.cpm_catg_code%TYPE;
   v_kyc_flag              VARCHAR2 (1);
   v_instrument_realised   VARCHAR2 (1);
   exp_reject_record       EXCEPTION;
   exp_reject_file         EXCEPTION;
   exp_process_record       EXCEPTION;
   v_savepoint             NUMBER                                   DEFAULT 0;
   v_comm_type			   CHAR(1);

   CURSOR c1
   IS
      SELECT cuc_file_name, cuc_ins_user, cuc_file_header
        FROM cms_upload_ctrl
       WHERE cuc_file_name LIKE prm_filename || '%' AND cuc_upld_stat = 'P';

   CURSOR c2 (p_filename IN VARCHAR2)
   IS
      SELECT   TRIM (cci_inst_code) cci_inst_code,
               TRIM (cci_file_name) cci_file_name,
               TRIM (cci_row_id) cci_row_id,
               TRIM (cci_appl_code) cci_appl_code,
               TRIM (cci_appl_no) cci_appl_no,
               TRIM (cci_pan_code) cci_pan_code,
               TRIM (cci_mbr_numb) cci_mbr_numb,
               TRIM (cci_crd_stat) cci_crd_stat,
               TRIM (cci_exp_dat) cci_exp_dat, TRIM (cci_rec_typ)
                                                                 cci_rec_typ,
               TRIM (cci_crd_typ) cci_crd_typ,
               TRIM (cci_requester_name) cci_requester_name,
               TRIM (cci_prod_code) cci_prod_code,
               TRIM (cci_card_type) cci_card_type,
               TRIM (cci_seg12_branch_num) cci_seg12_branch_num,
               TRIM (cci_fiid) cci_fiid, TRIM (cci_title) cci_title,
               TRIM (cci_seg12_name_line1) cci_seg12_name_line1,
               TRIM (cci_seg12_name_line2) cci_seg12_name_line2,
               TRIM (cci_birth_date) cci_birth_date,
               TRIM (cci_mother_name) cci_mother_name, TRIM (cci_ssn)
                                                                     cci_ssn,
               TRIM (cci_hobbies) cci_hobbies, TRIM (cci_cust_id)
                                                                 cci_cust_id,
               TRIM (cci_comm_type) cci_comm_type,
               TRIM (cci_seg12_addr_line1) cci_seg12_addr_line1,
               TRIM (cci_seg12_addr_line2) cci_seg12_addr_line2,
               TRIM (cci_seg12_city) cci_seg12_city,
               TRIM (cci_seg12_state) cci_seg12_state,
               TRIM (cci_seg12_postal_code) cci_seg12_postal_code,
               TRIM (cci_seg12_country_code) cci_seg12_country_code,
               TRIM (cci_seg12_mobileno) cci_seg12_mobileno,
               TRIM (cci_seg12_homephone_no) cci_seg12_homephone_no,
               TRIM (cci_seg12_officephone_no) cci_seg12_officephone_no,
               TRIM (cci_seg12_emailid) cci_seg12_emailid,
               TRIM (cci_seg13_addr_line1) cci_seg13_addr_line1,
               TRIM (cci_seg13_addr_line2) cci_seg13_addr_line2,
               TRIM (cci_seg13_city) cci_seg13_city,
               TRIM (cci_seg13_state) cci_seg13_state,
               TRIM (cci_seg13_postal_code) cci_seg13_postal_code,
               TRIM (cci_seg13_country_code) cci_seg13_country_code,
               TRIM (cci_seg13_mobileno) cci_seg13_mobileno,
               TRIM (cci_seg13_homephone_no) cci_seg13_homephone_no,
               TRIM (cci_seg13_officephone_no) cci_seg13_officephone_no,
               TRIM (cci_seg13_emailid) cci_seg13_emailid,
               TRIM (cci_seg31_lgth) cci_seg31_lgth,
               TRIM (cci_seg31_acct_cnt) cci_seg31_acct_cnt,
               TRIM (cci_seg31_typ) cci_seg31_typ,
               TRIM (cci_seg31_num) cci_seg31_num,
               TRIM (cci_seg31_stat) cci_seg31_stat,
               TRIM (cci_prod_amt) cci_prod_amt,
               TRIM (cci_fee_amt) cci_fee_amt, TRIM (cci_tot_amt)
                                                                 cci_tot_amt,
               TRIM (cci_payment_mode) cci_payment_mode,
               TRIM (cci_instrument_no) cci_instrument_no,
               TRIM (cci_instrument_amt) cci_instrument_amt,
               TRIM (cci_drawn_date) cci_drawn_date,
               TRIM (cci_payref_no) cci_payref_no,
               TRIM (cci_emp_id) cci_emp_id,
               TRIM (cci_kyc_reason) cci_kyc_reason,
               TRIM (cci_kyc_flag) cci_kyc_flag,
               TRIM (cci_addon_flag) cci_addon_flag,
               TRIM (cci_virtual_acct) cci_virtual_acct,
               TRIM (cci_document_verify) cci_document_verify,
               TRIM (cci_exchange_rate) cci_exchange_rate,
               TRIM (cci_upld_stat) cci_upld_stat,
               TRIM (cci_approved) cci_approved, cci_maker_user_id,
               cci_maker_date, cci_checker_user_id, cci_cheker_date,
               cci_auth_user_id, cci_auth_date, cci_ins_user, cci_ins_date,
               cci_lupd_user, cci_lupd_date, TRIM (cci_comments),
               TRIM (cci_corp_id) cci_corp_id,TRIM(cci_merc_code) cci_merc_code, ROWID r
          FROM pcms_caf_info_temp
         WHERE cci_inst_code = prm_instcode
           AND cci_file_name = p_filename
           AND cci_upld_stat = 'P'
           --AND cci_instrument_realised = 'Y'
      ORDER BY cci_fiid, cci_seg31_num;
BEGIN                                                        --<< MAIN BEGIN>>
   FOR i1 IN c1
   LOOP                                            --<< LOOP C1(FILE WISE) >>
      prm_errmsg := 'OK';

      --Sn insert a record in summary table
      BEGIN
         INSERT INTO pcms_upload_summary
              VALUES (prm_instcode, i1.cuc_file_name, 0, 0, 0, prm_lupduser,
                      SYSDATE, prm_lupduser, SYSDATE);
      EXCEPTION
         WHEN DUP_VAL_ON_INDEX
         THEN
            v_errmsg :=
                  'Duplicate record found file '
               || i1.cuc_file_name
               || ' already processed ';
            RAISE exp_reject_file;
         WHEN OTHERS
         THEN
            v_errmsg :=
                  'Error while creating a record in summary table '
               || SUBSTR (SQLERRM, 1, 200);
            RAISE exp_reject_file;
      END;

      BEGIN                                    --<< BEGIN LOOP C1(FILE WISE)>>
         FOR i2 IN c2 (i1.cuc_file_name)
         LOOP                          --<< LOOP C2(FILE WISE RECORD WISE) >>
            v_errmsg := 'OK';
            v_savepoint := v_savepoint + 1;
            SAVEPOINT v_savepoint;

            BEGIN               --<< BEGIN LOOP C2 (FILE WISE RECORD WISE) >>
               --Sn KYC Flage approvel check
               BEGIN
                  SELECT cci_kyc_flag
                    INTO v_kyc_flag
                    FROM pcms_caf_info_temp
                   WHERE cci_pan_code = i2.cci_pan_code
                     AND ROWID = i2.r
                     AND cci_kyc_flag = 'N';
               EXCEPTION
                  WHEN NO_DATA_FOUND
                  THEN
                     v_errmsg := 'KYC is pending for Approval';
                  RAISE  exp_process_record;
                  WHEN OTHERS
                  THEN
                     v_errmsg :=
                           'Error while selecting KYC Flag'
                        || SUBSTR (SQLERRM, 1, 200);
               RAISE  exp_process_record;
               END;

               --En KYC Flage approvel check
               -- Sn Check instrument_realised first is Y or not
               BEGIN
                  SELECT cci_instrument_realised
                    INTO v_instrument_realised
                    FROM pcms_caf_info_temp
                   WHERE cci_inst_code = prm_instcode
                     AND cci_row_id = i2.cci_row_id
                     AND cci_instrument_realised = 'Y';
               EXCEPTION
                  WHEN NO_DATA_FOUND
                  THEN
                     v_errmsg :=
                         'Instrument Realised is pending for approval ';
                     RAISE exp_process_record;
                  WHEN OTHERS
                  THEN
                     v_errmsg :=
                           'Error while selecting Instrument Realised '
                        || SUBSTR (SQLERRM, 1, 200);
                     RAISE exp_process_record;
               END;

                --En Check instrument realised first is Y or not
               --Sn check branch
               BEGIN
                  SELECT 1
                    INTO v_check_branch
                    FROM cms_bran_mast
                   WHERE cbm_bran_code = i2.cci_fiid;
               EXCEPTION
                  WHEN NO_DATA_FOUND
                  THEN
                     v_errmsg := 'Branch is not defined in master';
                     RAISE exp_reject_record;
                  WHEN OTHERS
                  THEN
                     v_errmsg :=
                           'Error while selecting branch detail'
                        || SUBSTR (SQLERRM, 1, 200);
                     RAISE exp_reject_record;
               END;

               --En check brach
               --Sn Check Sale condition
               BEGIN
                  SELECT 1
                    INTO v_check_branch
                    FROM cms_bran_mast
                   WHERE cbm_bran_code = i2.cci_fiid AND cbm_sale_trans = 1;
               EXCEPTION
                  WHEN NO_DATA_FOUND
                  THEN
                     v_errmsg :=
                               'Branch is not allowed for new card issuance ';
                     RAISE exp_reject_record;
                  WHEN OTHERS
                  THEN
                     v_errmsg :=
                           'Branch is not allowed for new card issuance'
                        || SUBSTR (SQLERRM, 1, 200);
                     RAISE exp_reject_record;
               END;

               --En Check Sale condition
               --Sn check cntry mast
               BEGIN
                  SELECT gcm_cntry_code
                    INTO v_gcm_cntry_code
                    FROM gen_cntry_mast
                   WHERE gcm_curr_code = i2.cci_seg12_country_code;
               EXCEPTION
                  WHEN NO_DATA_FOUND
                  THEN
                     v_errmsg :=
                           'Country is not defined in master'
                        || i2.cci_seg12_country_code;
                     RAISE exp_reject_record;
                  WHEN OTHERS
                  THEN
                     v_errmsg :=
                           'Error while selecting country detail'
                        || SUBSTR (SQLERRM, 1, 200);
                     RAISE exp_reject_record;
               END;

               --En check cntry mast
               --Sn check cust catg
               BEGIN
                  SELECT ccc_catg_code, ccc_catg_sname
                    INTO v_custcatg_code, v_custcatg
                    FROM cms_cust_catg
                   WHERE ccc_catg_sname = i2.cci_seg12_branch_num;
               EXCEPTION
                  WHEN NO_DATA_FOUND
                  THEN
                     v_custcatg := 'DEF';
                     --Master setup need to be done for 'DEF'
                     v_custcatg_code := 1;
                  WHEN OTHERS
                  THEN
                     v_errmsg :=
                           'Error while selecting customer category'
                        || SUBSTR (SQLERRM, 1, 200);
                     RAISE exp_reject_record;
               END;

               --En check cust catg
               --Sn check prod bin
               BEGIN
                  SELECT cpb_prod_code
                    INTO v_prodcode
                    FROM cms_prod_bin
                   WHERE cpb_inst_code = prm_instcode
                     AND cpb_inst_bin = i2.cci_pan_code
                     AND cpb_marc_prodbin_flag = 'N'
                     AND cpb_active_bin = 'Y';
               EXCEPTION
                  WHEN NO_DATA_FOUND
                  THEN
                     v_errmsg := 'Not a valid Bin ' || i2.cci_pan_code;
                     RAISE exp_reject_record;
                  WHEN OTHERS
                  THEN
                     v_errmsg :=
                           'Error while selecting product and bin dtl '
                        || SUBSTR (SQLERRM, 1, 200);
                     RAISE exp_reject_record;
               END;

               --En check prod bin
               --Sn check product
               BEGIN
                  SELECT 1
                    INTO v_check_product
                    FROM cms_prod_mast
                   WHERE cpm_inst_code = prm_instcode
                     AND cpm_prod_code = v_prodcode
                     AND cpm_marc_prod_flag = 'N';
               EXCEPTION
                  WHEN NO_DATA_FOUND
                  THEN
                     v_errmsg := 'Not a valid Product ' || v_prodcode;
                     RAISE exp_reject_record;
                  WHEN OTHERS
                  THEN
                     v_errmsg :=
                           'Error while selecting product '
                        || SUBSTR (SQLERRM, 1, 200);
                     RAISE exp_reject_record;
               END;

               --En check product
               --Sn check card type
               BEGIN
                  SELECT cpc_card_type
                    INTO v_card_type
                    FROM cms_prod_cattype
                   WHERE cpc_inst_code = prm_instcode
                     AND cpc_prod_code = v_prodcode
                     AND cpc_cardtype_sname = i2.cci_card_type;
               EXCEPTION
                  WHEN NO_DATA_FOUND
                  THEN
                     v_errmsg :=
                           'Product code'
                        || v_prodcode
                        || 'is not attached to cattype'
                        || i2.cci_card_type;
                     RAISE exp_reject_record;
                  WHEN OTHERS
                  THEN
                     v_errmsg :=
                           'Error while selecting product cattype '
                        || SUBSTR (SQLERRM, 1, 200);
                     RAISE exp_reject_record;
               END;

               --En check card type
               -- Sn find entry in prod ccc
               BEGIN
                  SELECT cpc_prod_sname
                    INTO v_prod_ccc
                    FROM cms_prod_ccc
                   WHERE cpc_inst_code = prm_instcode
                     AND cpc_prod_code = v_prodcode
                     AND cpc_card_type = v_card_type
                     AND cpc_cust_catg = v_custcatg_code;
               EXCEPTION
                  WHEN NO_DATA_FOUND
                  THEN
                     BEGIN
                        INSERT INTO cms_prod_ccc
                                    (cpc_inst_code, cpc_cust_catg,
                                     cpc_card_type, cpc_prod_code,
                                     cpc_ins_user, cpc_ins_date,
                                     cpc_lupd_user, cpc_lupd_date,
                                     cpc_vendor, cpc_stock, cpc_prod_sname
                                    )
                             VALUES (prm_instcode, v_custcatg_code,
                                     v_card_type, v_prodcode,
                                     prm_lupduser, SYSDATE,
                                     prm_lupduser, SYSDATE,
                                     '1', '1', 'Default'
                                    );
                     EXCEPTION
                        WHEN OTHERS
                        THEN
                           v_errmsg :=
                                   'Error while creating a entry in prod_ccc';
                           RAISE exp_reject_record;
                     END;
                  WHEN OTHERS
                  THEN
                     v_errmsg :=
                           'Error while selecting prodccc detail from master '
                        || SUBSTR (SQLERRM, 1, 200);
                     RAISE exp_reject_record;
               END;

               --Sn check product catg code
               BEGIN
                  SELECT cpm_catg_code
                    INTO v_catg_code
                    FROM cms_prod_mast
                   WHERE cpm_inst_code = prm_instcode
                     AND cpm_prod_code = v_prodcode
                     AND cpm_marc_prod_flag = 'N';
               EXCEPTION
                  WHEN NO_DATA_FOUND
                  THEN
                     v_errmsg := 'Not a valid Product ' || v_prodcode;
                     RAISE exp_reject_record;
                  WHEN OTHERS
                  THEN
                     v_errmsg :=
                           'Error while selecting product '
                        || SUBSTR (SQLERRM, 1, 200);
                     RAISE exp_reject_record;
               END;

               --En check product catg code
               IF v_catg_code = 'P'
               THEN
                  -----------------Sn check card issuance
                  BEGIN
                     SELECT cfm_func_code, cfm_func_desc
                       INTO v_func_code, v_func_desc
                       FROM cms_func_mast
                      WHERE cfm_txn_code = 'CI'
                        AND cfm_txn_mode = '0'
                        AND cfm_delivery_channel = '05';
                  EXCEPTION
                     WHEN NO_DATA_FOUND
                     THEN
                        v_errmsg :=
                             'Master data is not available for card issuance';
                        RAISE exp_reject_record;
                     WHEN OTHERS
                     THEN
                        v_errmsg :=
                              'Error while selecting funccode detail from master '
                           || SUBSTR (SQLERRM, 1, 200);
                        RAISE exp_reject_record;
                  END;

                  BEGIN
                     SELECT 1
                       INTO v_check_funccode
                       FROM cms_func_prod
                      WHERE cfp_prod_code = v_prodcode
                        AND cfp_prod_cattype = v_card_type
                        AND cfp_func_code = v_func_code;
                  EXCEPTION
                     WHEN NO_DATA_FOUND
                     THEN
                        v_errmsg :=
                              v_func_desc
                           || ' is not attached to product code '
                           || v_prodcode
                           || ' card type '
                           || i2.cci_card_type;
                        RAISE exp_reject_record;
                     WHEN OTHERS
                     THEN
                        v_errmsg :=
                              'Error while verifing  funccode attachment to Product code and card type '
                           || SUBSTR (SQLERRM, 1, 200);
                        RAISE exp_reject_record;
                  END;

                  --En check card issuance
                  --Sn check initial load
                  IF i2.cci_prod_amt > 0
                  THEN
                     --Sn check initial load spprt func
                     BEGIN
                        SELECT cfm_func_code, cfm_func_desc
                          INTO v_spprt_funccode, v_spprtfunc_desc
                          FROM cms_func_mast
                         WHERE cfm_txn_code = 'IL'
                           AND cfm_txn_mode = '0'
                           AND cfm_delivery_channel = '05';
                     EXCEPTION
                        WHEN NO_DATA_FOUND
                        THEN
                           v_errmsg :=
                              'Master data is not available for initial load';
                           RAISE exp_reject_record;
                        WHEN OTHERS
                        THEN
                           v_errmsg :=
                                 'Error while selecting funccode detail from master for initial load '
                              || SUBSTR (SQLERRM, 1, 200);
                           RAISE exp_reject_record;
                     END;

                     --En check initial load spprt function
                     --Sn Check card initial load attached to product and Cardtype
                     BEGIN
                        SELECT 1
                          INTO v_check_spprtfunccode
                          FROM cms_func_prod
                         WHERE cfp_prod_code = v_prodcode
                           AND cfp_prod_cattype = v_card_type
                           AND cfp_func_code = v_spprt_funccode;

                        v_initial_spprtflag := 'Y';
                     EXCEPTION
                        WHEN NO_DATA_FOUND
                        THEN
                           v_errmsg :=
                                 v_spprtfunc_desc
                              || ' is not attached to product code '
                              || v_prodcode
                              || ' card type '
                              || i2.cci_card_type;
                           RAISE exp_reject_record;
                        WHEN OTHERS
                        THEN
                           v_errmsg :=
                                 'Error while verifing  funccode attachment to Product code and card type for initial load'
                              || SUBSTR (SQLERRM, 1, 200);
                           RAISE exp_reject_record;
                     END;
                  --En Check card initial load attached to product and Cardtype
                  END IF;
               ---------------------En check initial load
               END IF;

               --Sn find customer
               BEGIN
                  SELECT ccm_cust_code
                    INTO v_cust_code
                    FROM cms_cust_mast
                   WHERE ccm_inst_code = prm_instcode
                     ---AND ccm_cust_code = i2.cci_cust_id;

                  AND ccm_cust_id   = I2.cci_cust_id;  --As per Discussion With Shyam.
                  /*IF SQL%FOUND
                  THEN
                     v_errmsg := 'Custome Code is already present in master ';
                     RAISE exp_reject_record;
                  END IF;*/
				  BEGIN 
					SELECT CAM_ADDR_CODE INTO v_comm_addrcode FROM CMS_ADDR_MAST
					 WHERE CAM_INST_CODE =prm_instcode
					 AND CAM_CUST_CODE =v_cust_code 
					 AND CAM_ADDR_FLAG = 'P';
					
					EXCEPTION
					WHEN NO_DATA_FOUND THEN
					 v_errmsg :=
		                     'No Data found while selecting Addr code '
		                  || SUBSTR (SQLERRM, 1, 200);
						 RAISE exp_reject_record;
					WHEN TOO_MANY_ROWS THEN
					 v_errmsg :=
		                     'Multiplal Rows found while selecting Addr code '
		                  || SUBSTR (SQLERRM, 1, 200);
						 RAISE exp_reject_record;
					WHEN OTHERS THEN
					 v_errmsg :=
		                     'Error while selecting Addr code  '
		                  || SUBSTR (SQLERRM, 1, 200);
						 RAISE exp_reject_record;
				  END;
               EXCEPTION
                  WHEN NO_DATA_FOUND
                  THEN
                     --Sn create customer
                     BEGIN
                        SELECT DECODE (UPPER (i2.cci_title),
                                       'MR.', 'M',
                                       'MRS.', 'F',
                                       'MISS.', 'F'
                                      )
                          INTO v_gender
                          FROM DUAL;

                        sp_create_cust (prm_instcode,
                                        1,
                                        0,
                                        'Y',
                                        i2.cci_title,
                                        i2.cci_seg12_name_line1,
                                        NULL,
                                        ' ',
                                        i2.cci_birth_date,
                                        v_gender,
                                        NULL,
                                        NULL,
                                        NULL,
                                        NULL,
                                        NULL,
                                        NULL,
                                        prm_lupduser,
                                        i2.cci_ssn,
                                        i2.cci_mother_name,
                                        i2.cci_hobbies,
                                        i2.cci_emp_id,
										v_catg_code,
										I2.cci_cust_id,
                                        v_cust_code,
                                        v_errmsg
                                       );

                        IF v_errmsg <> 'OK'
                        THEN
                           v_errmsg :=
                                     'Error from create cutomer ' || v_errmsg;
                           RAISE exp_reject_record;
                        END IF;
                     EXCEPTION
                        WHEN exp_reject_record
                        THEN
                           RAISE;
                        WHEN OTHERS
                        THEN
                           v_errmsg :=
                                 'Error while create customer '
                              || SUBSTR (SQLERRM, 1, 200);
                           RAISE exp_reject_record;
                     END;

                     --En create customer
                     --Sn create communication address
                     SELECT DECODE (i2.cci_comm_type,
                                    '0', i2.cci_seg12_addr_line1,
                                    i2.cci_seg13_addr_line1
                                   ),
                            DECODE (i2.cci_comm_type,
                                    '0', i2.cci_seg12_addr_line2,
                                    i2.cci_seg13_addr_line2
                                   ),
                            DECODE (i2.cci_comm_type,
                                    '0', i2.cci_seg12_postal_code,
                                    i2.cci_seg13_postal_code
                                   ),
                            DECODE (i2.cci_comm_type,
                                    '0', i2.cci_seg12_homephone_no,
                                    i2.cci_seg13_homephone_no
                                   ),
                            DECODE (i2.cci_comm_type,
                                    '0', i2.cci_seg12_mobileno,
                                    i2.cci_seg13_mobileno
                                   ),
                            DECODE (i2.cci_comm_type,
                                    '0', i2.cci_seg12_emailid,
                                    i2.cci_seg13_emailid
                                   ),
                            DECODE (i2.cci_comm_type,
                                    '0', i2.cci_seg12_city,
                                    i2.cci_seg13_city
                                   ),
                            DECODE (i2.cci_comm_type,
                                    '0', i2.cci_seg12_state,
                                    i2.cci_seg13_state
                                   ),
                            DECODE (i2.cci_comm_type,
                                    '0', i2.cci_seg13_addr_line1,
                                    i2.cci_seg12_addr_line1
                                   ),
                            DECODE (i2.cci_comm_type,
                                    '0', i2.cci_seg13_addr_line2,
                                    i2.cci_seg12_addr_line2
                                   ),
                            DECODE (i2.cci_comm_type,
                                    '0', i2.cci_seg13_postal_code,
                                    i2.cci_seg12_postal_code
                                   ),
                            DECODE (i2.cci_comm_type,
                                    '0', i2.cci_seg13_homephone_no,
                                    i2.cci_seg12_homephone_no
                                   ),
                            DECODE (i2.cci_comm_type,
                                    '0', i2.cci_seg13_mobileno,
                                    i2.cci_seg12_mobileno
                                   ),
                            DECODE (i2.cci_comm_type,
                                    '0', i2.cci_seg13_emailid,
                                    i2.cci_seg12_emailid
                                   ),
                            DECODE (i2.cci_comm_type,
                                    '0', i2.cci_seg13_city,
                                    i2.cci_seg12_city
                                   ),
                            DECODE (i2.cci_comm_type,
                                    '0', i2.cci_seg13_state,
                                    i2.cci_seg12_state
                                   )
                       INTO v_comm_addr_lin1,
                            v_comm_addr_lin2,
                            v_comm_postal_code,
                            v_comm_homephone_no,
                            v_comm_mobileno,
                            v_comm_emailid,
                            v_comm_city,
                            v_comm_state,
                            v_other_addr_lin1,
                            v_other_addr_lin2,
                            v_other_postal_code,
                            v_other_homephone_no,
                            v_other_mobileno,
                            v_other_emailid,
                            v_other_city,
                            v_other_state
                       FROM DUAL;

                     --Sn create communication address
                     IF v_comm_addr_lin1 IS NOT NULL
                     THEN
					 IF v_comm_addr_lin1 = i2.cci_seg12_addr_line1 
										  THEN
											 	v_comm_type := 'R';
										  ELSIF v_comm_addr_lin1 = i2.cci_seg13_addr_line1 
										  THEN
									  			v_comm_type := 'O';
										  END IF;
                        BEGIN
                           sp_create_addr (prm_instcode,
                                           v_cust_code,
                                           v_comm_addr_lin1,
                                           v_comm_addr_lin2,
                                           i2.cci_seg12_name_line2,
                                           v_comm_postal_code,
                                           v_comm_homephone_no,
                                           v_comm_mobileno,
                                           v_comm_emailid,
                                           v_gcm_cntry_code,
                                           v_comm_city,
                                           v_comm_state,
                                           NULL,
                                           'P',
										   v_comm_type,
                                           prm_lupduser,
                                           v_comm_addrcode,
                                           v_errmsg
                                          );

                           IF v_errmsg <> 'OK'
                           THEN
                              v_errmsg :=
                                    'Error from create communication address '
                                 || v_errmsg;
                              RAISE exp_reject_record;
                           END IF;
                        EXCEPTION
                           WHEN exp_reject_record
                           THEN
                              RAISE;
                           WHEN OTHERS
                           THEN
                              v_errmsg :=
                                    'Error while create communication address '
                                 || SUBSTR (SQLERRM, 1, 200);
                              RAISE exp_reject_record;
                        END;
                     END IF;

                     --En create communication address
                     --Sn create other address
                     IF v_other_addr_lin1 IS NOT NULL
                     THEN
					 IF v_comm_addr_lin1 = i2.cci_seg12_addr_line1 
										  THEN
											 	v_comm_type := 'R';
										  ELSIF v_comm_addr_lin1 = i2.cci_seg13_addr_line1 
										  THEN
									  			v_comm_type := 'O';
										  END IF;
                        BEGIN
                           sp_create_addr (prm_instcode,
                                           v_cust_code,
                                           v_other_addr_lin1,
                                           v_other_addr_lin2,
                                           i2.cci_seg12_name_line2,
                                           v_other_postal_code,
                                           v_other_homephone_no,
                                           v_other_mobileno,
                                           v_other_emailid,
                                           v_gcm_cntry_code,
                                           v_other_city,
                                           v_other_state,
                                           NULL,
                                           'O',
										   v_comm_type,
                                           prm_lupduser,
                                           v_other_addrcode,
                                           v_errmsg
                                          );

                           IF v_errmsg <> 'OK'
                           THEN
                              v_errmsg :=
                                    'Error from create communication address '
                                 || v_errmsg;
                              RAISE exp_reject_record;
                           END IF;
                        EXCEPTION
                           WHEN exp_reject_record
                           THEN
                              RAISE;
                           WHEN OTHERS
                           THEN
                              v_errmsg :=
                                    'Error while create communication address '
                                 || SUBSTR (SQLERRM, 1, 200);
                              RAISE exp_reject_record;
                        END;
                     END IF;
                  --En create other address
                  WHEN exp_reject_record THEN
				     v_errmsg :='Error while create communication address '
                                 || SUBSTR (SQLERRM, 1, 200);
                              RAISE;
				  WHEN OTHERS
                  THEN
                     v_errmsg :=
                           'Error while selecting customer from master '
                        || SUBSTR (SQLERRM, 1, 200);
                     RAISE exp_reject_record;
               END;

               --En find customer
               /*--Sn create communication address
                  SELECT
                     DECODE(I2.CCI_COMM_TYPE , '0' ,I2.cci_seg12_addr_line1,I2.cci_seg13_addr_line1),
                     DECODE(I2.CCI_COMM_TYPE , '0' ,I2.cci_seg12_addr_line2,I2.cci_seg13_addr_line2),
                     DECODE(I2.CCI_COMM_TYPE , '0' ,I2.cci_seg12_postal_code,I2.cci_seg13_postal_code),
                     DECODE(I2.CCI_COMM_TYPE , '0' ,I2.cci_seg12_homephone_no,I2.cci_seg13_homephone_no),
                     DECODE(I2.CCI_COMM_TYPE , '0' ,I2.cci_seg12_mobileno , I2.cci_seg13_mobileno ),
                     DECODE(I2.CCI_COMM_TYPE , '0' ,I2.cci_seg12_emailid, I2.cci_seg13_emailid ),
                     DECODE(I2.CCI_COMM_TYPE , '0' ,I2.cci_seg12_city,I2.cci_seg13_city),
                     DECODE(I2.CCI_COMM_TYPE , '0' ,I2.cci_seg12_state,I2.cci_seg13_state),
                     DECODE(I2.CCI_COMM_TYPE , '0' ,I2.cci_seg13_addr_line1,I2.cci_seg12_addr_line1),
                     DECODE(I2.CCI_COMM_TYPE , '0' ,I2.cci_seg13_addr_line2,I2.cci_seg12_addr_line2),
                     DECODE(I2.CCI_COMM_TYPE , '0' ,I2.cci_seg13_postal_code,I2.cci_seg12_postal_code),
                     DECODE(I2.CCI_COMM_TYPE , '0' ,I2.cci_seg13_homephone_no,I2.cci_seg12_homephone_no),
                     DECODE(I2.CCI_COMM_TYPE , '0' ,I2.cci_seg13_mobileno , I2.cci_seg12_mobileno ),
                     DECODE(I2.CCI_COMM_TYPE , '0' ,I2.cci_seg13_emailid, I2.cci_seg12_emailid ),
                     DECODE(I2.CCI_COMM_TYPE , '0' ,I2.cci_seg13_city,I2.cci_seg12_city),
                     DECODE(I2.CCI_COMM_TYPE , '0' ,I2.cci_seg13_state,I2.cci_seg12_state )
                  INTO  v_comm_addr_lin1,
                     v_comm_addr_lin2,
                     v_comm_postal_code,
                     v_comm_homephone_no,
                     v_comm_mobileno,
                     v_comm_emailid,
                     v_comm_city,
                     v_comm_state,
                     v_other_addr_lin1,
                     v_other_addr_lin2,
                     v_other_postal_code,
                     v_other_homephone_no,
                     v_other_mobileno,
                     v_other_emailid,
                     v_other_city,
                     v_other_state
                  FROM  DUAL;
                  --Sn create communication address
                  IF v_comm_addr_lin1 IS NOT NULL THEN
                     BEGIN
                       Sp_Create_Addr( prm_instcode,
                              v_cust_code,
                              v_comm_addr_lin1,
                              v_comm_addr_lin2,
                              I2.cci_seg12_name_line2,
                              v_comm_postal_code,
                              v_comm_homephone_no,
                              v_comm_mobileno,
                              v_comm_emailid,
                              v_gcm_cntry_code,
                              v_comm_city,
                              v_comm_state,
                              NULL,'P',
                              prm_lupduser,
                              v_comm_addrcode   ,
                              v_errmsg
                            );
                     IF v_errmsg <> 'OK' THEN
                        v_errmsg := 'Error from create communication address ' || v_errmsg;
                        RAISE exp_reject_record;
                     END IF;
                  EXCEPTION
                     WHEN exp_reject_record THEN
                     RAISE;
                     WHEN OTHERS THEN
                     v_errmsg := 'Error while create communication address ' || SUBSTR(SQLERRM,1,200);
                     RAISE exp_reject_record;
                  END;
                    END IF;
               --En create communication address
               --Sn create other address
                  IF v_other_addr_lin1 IS NOT NULL THEN
                     BEGIN
                          Sp_Create_Addr( prm_instcode,
                                 v_cust_code,
                                 v_other_addr_lin1,
                                 v_other_addr_lin2,
                                 I2.cci_seg12_name_line2,
                                 v_other_postal_code,
                                 v_other_homephone_no,
                                 v_other_mobileno,
                                 v_other_emailid,
                                 v_gcm_cntry_code,
                                 v_other_city,
                                 v_other_state,
                                 NULL,'O',
                                 prm_lupduser,
                                 v_other_addrcode,
                                 v_errmsg
                               );
                        IF v_errmsg <> 'OK' THEN
                           v_errmsg := 'Error from create communication address ' || v_errmsg;
                           RAISE exp_reject_record;
                        END IF;
                     EXCEPTION
                        WHEN exp_reject_record THEN
                        RAISE;
                        WHEN OTHERS THEN
                        v_errmsg := 'Error while create communication address ' || SUBSTR(SQLERRM,1,200);
                        RAISE exp_reject_record;
                     END;
                  END IF;
               --En create other address*/
               --Sn select acct type
               BEGIN
                  SELECT cat_type_code
                    INTO v_acct_type
                    FROM cms_acct_type
                   WHERE cat_inst_code = prm_instcode
                     AND cat_switch_type = v_switch_acct_type;
               EXCEPTION
                  WHEN NO_DATA_FOUND
                  THEN
                     v_errmsg :=
                          'Acct type not defined for  ' || v_switch_acct_type;
                     RAISE exp_reject_record;
                  WHEN OTHERS
                  THEN
                     v_errmsg :=
                           'Error while selecting accttype '
                        || SUBSTR (SQLERRM, 1, 200);
                     RAISE exp_reject_record;
               END;

               --En select acct type
               --Sn select acct stat
               BEGIN
                  SELECT cas_stat_code
                    INTO v_acct_stat
                    FROM cms_acct_stat
                   WHERE cas_inst_code = prm_instcode
                     AND cas_switch_statcode = v_switch_acct_stat;
               EXCEPTION
                  WHEN NO_DATA_FOUND
                  THEN
                     v_errmsg :=
                          'Acct stat not defined for  ' || v_switch_acct_type;
                     RAISE exp_reject_record;
                  WHEN OTHERS
                  THEN
                     v_errmsg :=
                           'Error while selecting accttype '
                        || SUBSTR (SQLERRM, 1, 200);
                     RAISE exp_reject_record;
               END;

--En select acct stat
--**********************************************************************
--Sn get acct number
/*BEGIN
   SELECT seq_acct_id.NEXTVAL
   INTO   v_acct_numb
   FROM  dual;
EXCEPTION
   WHEN OTHERS THEN
   v_errmsg := 'Error while selecting acctnum ' || SUBSTR(SQLERRM,1,200);
   RAISE exp_reject_record;
END;*/
--En get acct number

               --***********************************************************************
               IF v_catg_code = 'P'
               THEN
                  v_acct_numb := NULL;
               ELSIF v_catg_code = 'D'
               THEN
                  v_acct_numb := i2.cci_seg31_num;
               END IF;

               --Sn create acct
               BEGIN
                  sp_create_acct_pcms (prm_instcode,
                                       v_acct_numb,
                                       0,
                                       i2.cci_fiid,
                                       v_comm_addrcode,
                                       v_acct_type,
                                       v_acct_stat,
                                       prm_lupduser,
                                       v_dup_flag,
                                       v_acct_id,
                                       v_errmsg
                                      );

                  IF v_errmsg <> 'OK'
                  THEN
                     v_errmsg := 'Error from create acct ' || v_errmsg;
                     RAISE exp_reject_record;
                  END IF;
               EXCEPTION
                  WHEN exp_reject_record
                  THEN
                     RAISE;
                  WHEN OTHERS
                  THEN
                     v_errmsg :=
                        'Error while create acct '
                        || SUBSTR (SQLERRM, 1, 200);
                     RAISE exp_reject_record;
               END;

               --En create acct

              

               --Sn create a entry in cms_cust_acct
               BEGIN
                  UPDATE cms_acct_mast
                     SET cam_hold_count = cam_hold_count + 1,
                         cam_lupd_user = prm_lupduser
                   WHERE cam_inst_code = prm_instcode
                     AND cam_acct_id = v_acct_id;

                  IF SQL%ROWCOUNT = 0
                  THEN
                     v_errmsg :=
                        'Error while create acct '
                        || SUBSTR (SQLERRM, 1, 200);
                     RAISE exp_reject_record;
                  END IF;
               END;

               sp_create_holder (prm_instcode,
                                 v_cust_code,
                                 v_acct_id,
                                 NULL,
                                 prm_lupduser,
                                 v_holdposn,
                                 v_errmsg
                                );

               IF v_errmsg <> 'OK'
               THEN
                  v_errmsg :=
                             'Error from create entry cust_acct ' || v_errmsg;
                  RAISE exp_reject_record;
               END IF;

               ---En create a entry in cms_cust_acct
               -- Sn create Application

               -- Sn find expry param
               BEGIN
                  SELECT cip_param_value
--added on 11/10/2002 ...gets the card validity period in months from parameter table
                  INTO   v_expryparam
                    FROM cms_inst_param
                   WHERE cip_inst_code = prm_instcode
                     AND cip_param_key = 'CARD EXPRY';
               EXCEPTION
                  WHEN NO_DATA_FOUND
                  THEN
                     v_errmsg := 'Expry parameter is not defined in master';
                     RAISE exp_reject_record;
                  WHEN OTHERS
                  THEN
                     v_errmsg :=
                        'Error while selecting data from master for expryparam';
                     RAISE exp_reject_record;
               END;

               -- En find expry param
               -- Sn Appl
               BEGIN
                  sp_create_appl_pcms
                             (prm_instcode,
                              1,
                              1,
                              i2.cci_appl_no,
                              SYSDATE,
                              SYSDATE,
                              v_cust_code,
                              i2.cci_fiid,
                              v_prodcode,
                              v_card_type,
                              --(normal or blue depending upon hni or others cust catg)
                              v_custcatg_code,             --customer category
                              SYSDATE,
-- last_day(add_months(to_date(y.cci_exp_dat,'YYMM'),--(expry_param))), -- Ashwini -25 Jan 05----  to be written as code refered frm hdfc ,
                      -- Expry date is last day of the prev month after adding expry param
                              LAST_DAY (ADD_MONTHS (SYSDATE, v_expryparam - 1)),
--last_day(to_date(y.cci_exp_dat,'YYMM')), -- Ashwini-25 Jan 05 ----  to be written as code refered frm hdfc --
                              SUBSTR (i2.cci_seg12_name_line1, 1, 30),
                              0,
                              'N',
                              NULL,
                              1,
                              
--total account count  = 1 since in upload a card is associated with only one account
                              'P', --addon status always a primary application
                              0,
                              --addon link 0 means that the appln is for promary pan
                              v_comm_addrcode,               --billing address
                              NULL,                             --channel code
                              NULL,
                              i2.cci_payref_no,
                              prm_lupduser,
                              prm_lupduser,
                              TO_NUMBER (i2.cci_prod_amt),
                              v_appl_code,                         --out param
                              v_errmsg
                             );

                  IF v_errmsg <> 'OK'
                  THEN
                     v_errmsg := 'Error from create appl ' || v_errmsg;
                     RAISE exp_reject_record;
                  END IF;
               EXCEPTION
                  WHEN exp_reject_record
                  THEN
                     RAISE;
                  WHEN OTHERS
                  THEN
                     v_errmsg :=
                        'Error while create appl '
                        || SUBSTR (SQLERRM, 1, 200);
                     RAISE exp_reject_record;
               END;

               -- En Appl
               -- Sn create entry in appl_det
               BEGIN
                  sp_create_appldet (prm_instcode,
                                     v_appl_code,
                                     v_acct_id,
                                     1,
                                     prm_lupduser,
                                     v_errmsg
                                    );

                  IF v_errmsg <> 'OK'
                  THEN
                     v_errmsg := 'Error from create appl det ' || v_errmsg;
                     RAISE exp_reject_record;
                  END IF;
               EXCEPTION
                  WHEN exp_reject_record
                  THEN
                     RAISE;
                  WHEN OTHERS
                  THEN
                     v_errmsg :=
                           'Error while create appl det '
                        || SUBSTR (SQLERRM, 1, 200);
                     RAISE exp_reject_record;
               END;

                   -- En create entry in appl_det
				   
				      --Sn Create acct in corporate card
				               IF i2.cci_corp_id IS NOT NULL
				               THEN
				                  BEGIN
				                     INSERT INTO pcms_corporate_cards
				                                 (pcc_inst_code, pcc_corp_code, pcc_pan_no,
				                                  pcc_ins_user, pcc_ins_date, pcc_lupd_user,
				                                  pcc_lupd_date
				                                 )
				                          VALUES (prm_instcode, i2.cci_corp_id, v_acct_id,
				                                  prm_lupduser, SYSDATE, prm_lupduser,
				                                  SYSDATE
				                                 );
				
				                     IF SQL%ROWCOUNT = 0
				                     THEN
				                        v_errmsg :=
				                              'Error while inserting in CMS_CORPORATE_CARDS '
				                           || SUBSTR (SQLERRM, 1, 200);
				                        RAISE exp_reject_record;
				                     END IF;
				                  END;
				               END IF;
				
				             --En Create acct in corporate card.
							   
						--Sn Create acct in corporate card
				         IF i2.cci_merc_code IS NOT NULL
				         THEN
				            BEGIN
				               INSERT INTO pcms_merchant_cards
				                           (pcc_inst_code, pcc_merc_code, pcc_pan_no,
				                            pcc_ins_user, pcc_ins_date, pcc_lupd_user,
				                            pcc_lupd_date,pcc_cust_code
				                           )
				                    VALUES (prm_instcode, i2.cci_merc_code, v_acct_id,
				                            prm_lupduser, SYSDATE, prm_lupduser,
				                            SYSDATE,v_cust_code
				                           );
				
				               IF SQL%ROWCOUNT = 0
				               THEN
				                  v_errmsg :=
				                        'Error while inserting in PCMS_MERCHANT_CARDS '
				                     || SUBSTR (SQLERRM, 1, 200);
				                  RAISE exp_reject_record;
				               END IF;
				            END;
				         END IF;

         				 --En Create acct in corporate card.   
				   
               --En create Application
               UPDATE pcms_caf_info_temp
                  SET cci_approved = 'O',
                      cci_upld_stat = 'O',
                      cci_appl_code = v_appl_code,
                      cci_process_msg = 'Successful'
                WHERE cci_row_id = i2.cci_row_id;

               UPDATE pcms_upload_summary
                  SET puc_success_records = puc_success_records + 1,
                      puc_tot_records = puc_tot_records + 1
                WHERE puc_file_name = i1.cuc_file_name;
            EXCEPTION       --<< EXCEPTION LOOP C2  (FILE WISE RECORD WISE) >>
                WHEN exp_process_record
               THEN
                  ROLLBACK TO v_savepoint;

                  UPDATE pcms_caf_info_temp
                     SET cci_upld_stat = 'P',
                         cci_process_msg = v_errmsg
                   WHERE cci_row_id = i2.cci_row_id;

                  UPDATE pcms_upload_summary
                     SET puc_error_records = puc_error_records + 1,
                         puc_tot_records = puc_tot_records + 1
                   WHERE puc_file_name = i1.cuc_file_name;

			   WHEN exp_reject_record
               THEN
                  ROLLBACK TO v_savepoint;

                  UPDATE pcms_caf_info_temp
                     SET cci_upld_stat = 'E',
                         cci_process_msg = v_errmsg
                   WHERE cci_row_id = i2.cci_row_id;

                  UPDATE pcms_upload_summary
                     SET puc_error_records = puc_error_records + 1,
                         puc_tot_records = puc_tot_records + 1
                   WHERE puc_file_name = i1.cuc_file_name;
               WHEN OTHERS
               THEN
                  ROLLBACK TO v_savepoint;
                  v_errmsg :=
                        'Error while processing ' || SUBSTR (SQLERRM, 1, 200);

                  UPDATE pcms_caf_info_temp
                     SET cci_upld_stat = 'E',
                         cci_process_msg = v_errmsg
                   WHERE cci_row_id = i2.cci_row_id;

                  UPDATE pcms_upload_summary
                     SET puc_error_records = puc_error_records + 1,
                         puc_tot_records = puc_tot_records + 1
                   WHERE puc_file_name = i1.cuc_file_name;
            END;                  --<< END LOOP C2 (FILE WISE RECORD WISE)  >>
         END LOOP;                  --<< LOOP END C2(FILE WISE RECORD WISE) >>
      EXCEPTION                            --<< EXCEPTION LOOP C1(FILE WISE)>>
         WHEN exp_reject_file
         THEN
            RAISE;
         WHEN OTHERS
         THEN
            v_errmsg :=
                   'Error while processing file ' || SUBSTR (SQLERRM, 1, 200);
            RAISE exp_reject_file;
      END;                                       --<< END LOOP C1(FILE WISE)>>
   END LOOP;                                     --<< LOOP END C1 FILE WISE >>

   prm_errmsg := 'OK';
EXCEPTION                                               --<< MAIN EXCEPTION >>
   WHEN exp_reject_file
   THEN
      prm_errmsg := v_errmsg;
   --update the flag to 'E' from cms_upld_ctrl
   WHEN OTHERS
   THEN
      prm_errmsg := 'Error from main ' || SUBSTR (SQLERRM, 1, 200);
END;                                                           --<< MAIN END>>
/


