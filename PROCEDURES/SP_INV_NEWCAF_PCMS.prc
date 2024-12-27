CREATE OR REPLACE PROCEDURE VMSCMS.sp_inv_newcaf_pcms (
   prm_instcode   IN       NUMBER,
   prm_filename   IN       VARCHAR2,
   prm_lupduser   IN       NUMBER,
   prm_errmsg     OUT      VARCHAR2
)
AS
/*************************************************
     * VERSION             :  1.0
     * Created Date       : 16/MAR/2009
     * Created By        : Kaustubh.Dave
     * PURPOSE          : Create application For Inventory, Fetch Record from pcms_caf_info_inv
     * Modified By:    :
     * Modified Date  :
   ***************u********************************/
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
   v_comm_addr_lin1        pcms_caf_info_inv.cci_seg12_addr_line1%TYPE;
   v_comm_addr_lin2        pcms_caf_info_inv.cci_seg12_addr_line2%TYPE;
   v_comm_postal_code      pcms_caf_info_inv.cci_seg12_postal_code%TYPE;
   v_comm_homephone_no     pcms_caf_info_inv.cci_seg12_homephone_no%TYPE;
   v_comm_mobileno         pcms_caf_info_inv.cci_seg12_mobileno%TYPE;
   v_comm_emailid          pcms_caf_info_inv.cci_seg12_emailid%TYPE;
   v_comm_city             pcms_caf_info_inv.cci_seg12_city%TYPE;
   v_comm_state            pcms_caf_info_inv.cci_seg12_city%TYPE;
   v_other_addr_lin1       pcms_caf_info_inv.cci_oaddr1%TYPE;
   v_other_addr_lin2       pcms_caf_info_inv.cci_oaddr2%TYPE;
   v_other_postal_code     pcms_caf_info_inv.cci_opostal_code%TYPE;
   v_other_ophone_no       pcms_caf_info_inv.cci_ophone%TYPE;
   v_other_mobileno        pcms_caf_info_inv.cci_omobile%TYPE;
   v_other_emailid         pcms_caf_info_inv.cci_oemail%TYPE;
   v_other_city            pcms_caf_info_inv.cci_ocity%TYPE;
   v_other_country         pcms_caf_info_inv.cci_ocountry_code%TYPE;
   v_other_state           pcms_caf_info_inv.cci_ostate%TYPE;
   v_comm_addr             pcms_caf_info_inv.cci_comm_addr%TYPE;
   v_comm_addrcode         cms_addr_mast.cam_addr_code%TYPE;
   v_other_addrcode        cms_addr_mast.cam_addr_code%TYPE;
   v_switch_acct_type      cms_acct_type.cat_switch_type%TYPE    DEFAULT '11';
   v_switch_acct_stat      cms_acct_stat.cas_switch_statcode%TYPE DEFAULT '3';
   v_acct_type             cms_acct_type.cat_type_code%TYPE;
   v_acct_stat             cms_acct_mast.cam_stat_code%TYPE;
   v_acct_numb             cms_acct_mast.cam_acct_no%TYPE;
   v_acct_id               cms_acct_mast.cam_acct_id%TYPE;
   v_dup_flag              VARCHAR2 (1);
   v_instbin               cms_prod_bin.CPB_INST_BIN%TYPE;
   v_holdposn              cms_cust_acct.cca_hold_posn%TYPE;
   v_expryparam            cms_inst_param.cip_param_value%TYPE;
   v_appl_code             cms_appl_mast.cam_appl_code%TYPE;
   v_catg_code			   cms_prod_mast.cpm_catg_code%TYPE;
   v_comm_type			   CHAR(1);
   exp_reject_record       EXCEPTION;
   exp_reject_file         EXCEPTION;
   v_savepoint             NUMBER                                   DEFAULT 0;

   CURSOR c1
   IS
      SELECT cuc_file_name, cuc_ins_user, cuc_file_header
        FROM cms_upload_ctrl
     --  WHERE cuc_file_name LIKE prm_filename || '%' AND cuc_upld_stat = 'P';
	   WHERE cuc_file_name = prm_filename  AND cuc_upld_stat = 'P';

   CURSOR c2 (p_filename IN VARCHAR2)
   IS
      SELECT   TRIM (cci_inst_code) cci_inst_code,
               TRIM (cci_file_name) cci_file_name,
               TRIM (cci_row_id) cci_row_id, TRIM (cci_appl_no) cci_appl_no,
               TRIM (cci_pan_code) cci_pan_code,
               TRIM (cci_crd_stat) cci_crd_stat,
               TRIM (cci_exp_dat) cci_exp_dat, TRIM (cci_crd_typ)
                                                                 cci_crd_typ,
               TRIM (cci_prod_code) cci_prod_code,
               TRIM (cci_card_type) cci_card_type,
               TRIM (cci_seg12_branch_num) cci_seg12_branch_num,
               TRIM (cci_fiid) cci_fiid, TRIM (cci_title) cci_title,
               TRIM (cci_seg12_name_line1) cci_seg12_name_line1,
               TRIM (cci_seg12_name_line2) cci_seg12_name_line2,
               TRIM (cci_cust_id) cci_cust_id,
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
               TRIM (cci_oaddr1) cci_oaddr1, TRIM (cci_oaddr2) cci_oaddr2,
               TRIM (cci_ocity) cci_ocity, TRIM (cci_ostate) cci_ostate,
               TRIM (cci_opostal_code) cci_opostal_code,
               TRIM (cci_ocountry_code) cci_ocountry_code,
               TRIM (cci_ophone) cci_ophone, TRIM (cci_omobile) cci_omobile,
               TRIM (cci_oemail) cci_oemail,
               TRIM (cci_comm_addr) cci_comm_addr,
               TRIM (cci_seg31_lgth) cci_seg31_lgth,
               TRIM (cci_seg31_acct_cnt) cci_seg31_acct_cnt,
               TRIM (cci_seg31_typ) cci_seg31_typ,
               TRIM (cci_seg31_num) cci_seg31_num,
               TRIM (cci_seg31_stat) cci_seg31_stat,
               TRIM (cci_prod_amt) cci_prod_amt,
               TRIM (cci_payref_no) cci_payref_no,
               TRIM (cci_upld_stat) cci_upld_stat,
               TRIM (cci_approved) cci_approved, cci_ins_user, cci_ins_date,
               cci_lupd_user, cci_lupd_date,CCI_EMP_ID, ROWID r
          FROM pcms_caf_info_inv
         WHERE cci_inst_code = prm_instcode
           AND cci_file_name = p_filename
           AND cci_upld_stat = 'P'
      ORDER BY cci_fiid, cci_seg31_num;
BEGIN                                                        --<< MAIN BEGIN>>
   FOR i1 IN c1
   LOOP                                            --<< LOOP C1(FILE WISE) >>
      prm_errmsg := 'OK';

      --Sn insert a record in summary table
      BEGIN
         INSERT INTO pcms_upload_summary
              VALUES (prm_instcode, i1.cuc_file_name, 0, 0, 0, prm_lupduser,
                      SYSDATE, prm_lupduser, SYSDATE,''); --MAR 01 11
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
               --Sn check cntry mast
               BEGIN
                  SELECT gcm_cntry_code
                    INTO v_gcm_cntry_code
                    FROM gen_cntry_mast
                   WHERE gcm_curr_code = i2.cci_seg12_country_code and GCM_INST_CODE=prm_instcode;
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
               BEGIN /* for inventory we found bin on the basis of product code */
                  SELECT CPB_INST_BIN,CPB_PROD_CODE
                    INTO v_instbin,v_prodcode
                    FROM cms_prod_bin
                   WHERE cpb_inst_code = prm_instcode
                   --  AND cpb_inst_bin = i2.cci_pan_code
				   AND CPB_PROD_CODE = i2.cci_prod_code
                     AND cpb_marc_prodbin_flag = 'N'
                     AND cpb_active_bin = 'Y';
               EXCEPTION
                  WHEN NO_DATA_FOUND
                  THEN
                     v_errmsg := 'Not a valid Bin ' || i2.cci_prod_code||' ' ||v_instbin;
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
                     AND cpm_prod_code = v_prodcode;
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
                     --AND cpc_cardtype_sname = i2.cci_card_type;
					 AND cpc_card_type = i2.cci_card_type;
               EXCEPTION
                  WHEN NO_DATA_FOUND
                  THEN
                     v_errmsg :=
                           'Product code'
                        || v_prodcode
                        || ' is not attached to cattype'
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
			   
			    -- Sn find prod catg
         BEGIN
            SELECT cpm_catg_code
              INTO v_catg_code
              FROM cms_prod_mast
             WHERE cpm_inst_code = prm_instcode
               AND cpm_prod_code = i2.cci_prod_code
               AND cpm_marc_prod_flag = 'N';
         EXCEPTION
            WHEN NO_DATA_FOUND
            THEN
               v_errmsg :=
                     'Product code'
                  || i2.cci_prod_code
                  || 'is not defined in the master';
               RAISE exp_reject_record;
            WHEN OTHERS
            THEN
               v_errmsg :=
                  'Error while selecting product '
                  || SUBSTR (SQLERRM, 1, 200);
               RAISE exp_reject_record;
         END;

         -- En find prod
         IF v_catg_code = 'P'
         THEN 
               --Sn check card issuance
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
			 END IF;
                        --En check initial load
                  --Sn find customer
               /*   BEGIN
                     SELECT ccm_cust_code
                       INTO v_cust_code
                       FROM cms_cust_mast
                      WHERE ccm_inst_code = prm_instcode
                        AND ccm_cust_id = i2.cci_cust_id;
                  EXCEPTION
                     WHEN NO_DATA_FOUND
                     THEN*/
                        --Sn create customer
               BEGIN
                  SELECT DECODE (i2.cci_title,
                                 'Mr.', 'M',
                                 'Mrs.', 'F',
                                 'Miss.', 'F',
								 'Dr.','D'
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
                                  NULL,                   --i2.cci_birth_date,
                                  v_gender,
                                  NULL,
                                  NULL,
                                  NULL,
                                  NULL,
                                  NULL,
                                  NULL,
                                  prm_lupduser,
                                  NULL,                          --i2.cci_ssn,
                                  NULL,                  --i2.cci_mother_name,
                                  NULL,                      --i2.cci_hobbies,
								  NULL,
								  v_catg_code,
								  i2.cci_cust_id,                                                  
                                  NULL,                 --prm_gen_custdata
                                  v_cust_code,
                                  v_errmsg
                                 );

                  IF v_errmsg <> 'OK'
                  THEN
                     v_errmsg := 'Error from create cutomer ' || v_errmsg;
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
                /*  WHEN OTHERS
                  THEN
                     v_errmsg :=
                           'Error while selecting customer from master '
                        || SUBSTR (SQLERRM, 1, 200);
                     RAISE exp_reject_record;
               END;*/

               --En find customer
               --Sn create communication address
               /*SELECT i2.cci_seg12_addr_line1, i2.cci_seg12_addr_line2,
                      i2.cci_seg12_postal_code, i2.cci_seg12_homephone_no,
                      i2.cci_seg12_mobileno, i2.cci_seg12_emailid,
                      i2.cci_seg12_city, i2.cci_seg12_state, i2.cci_oaddr1,
                      i2.cci_oaddr2, i2.cci_ocity, i2.cci_ostate,
                      i2.cci_opostal_code, i2.cci_ocountry_code,
                      i2.cci_ophone, i2.cci_omobile, i2.cci_oemail,
                      i2.cci_comm_addr
                 INTO v_comm_addr_lin1, v_comm_addr_lin2,
                      v_comm_postal_code, v_comm_homephone_no,
                      v_comm_mobileno, v_comm_emailid,
                      v_comm_city, v_comm_state, v_other_addr_lin1,
                      v_other_addr_lin2, v_other_city, v_other_state,
                      v_other_postal_code, v_other_country,
                      v_other_ophone_no, v_other_mobileno, v_other_emailid,
                      v_comm_addr
                 FROM DUAL;*/
               SELECT DECODE (i2.cci_comm_type,
                              '0', i2.cci_seg12_addr_line1,
                              i2.cci_oaddr1
                             ),
                      DECODE (i2.cci_comm_type,
                              '0', i2.cci_seg12_addr_line2,
                              i2.cci_oaddr2
                             ),
                      DECODE (i2.cci_comm_type,
                              '0', i2.cci_seg12_postal_code,
                              i2.cci_opostal_code
                             ),
                      DECODE (i2.cci_comm_type,
                              '0', i2.cci_seg12_homephone_no,
                              i2.cci_ophone
                             ),
                      DECODE (i2.cci_comm_type,
                              '0', i2.cci_seg12_mobileno,
                              i2.cci_omobile
                             ),
                      DECODE (i2.cci_comm_type,
                              '0', i2.cci_seg12_emailid,
                              i2.cci_oemail
                             ),
                      DECODE (i2.cci_comm_type,
                              '0', i2.cci_seg12_city,
                              i2.cci_ocity
                             ),
                      DECODE (i2.cci_comm_type,
                              '0', i2.cci_seg12_state,
                              i2.cci_ostate
                             ),
                      DECODE (i2.cci_comm_type,
                              '0', i2.cci_oaddr1,
                              i2.cci_seg12_addr_line1
                             ),
                      DECODE (i2.cci_comm_type,
                              '0', i2.cci_oaddr2,
                              i2.cci_seg12_addr_line2
                             ),
                      DECODE (i2.cci_comm_type,
                              '0', i2.cci_opostal_code,
                              i2.cci_seg12_postal_code
                             ),
                      DECODE (i2.cci_comm_type,
                              '0', i2.cci_ophone,
                              i2.cci_seg12_homephone_no
                             ),
                      DECODE (i2.cci_comm_type,
                              '0', i2.cci_omobile,
                              i2.cci_seg12_mobileno
                             ),
                      DECODE (i2.cci_comm_type,
                              '0', i2.cci_oemail,
                              i2.cci_seg12_emailid
                             ),
                      DECODE (i2.cci_comm_type,
                              '0', i2.cci_ocity,
                              i2.cci_seg12_city
                             ),
                      DECODE (i2.cci_comm_type,
                              '0', i2.cci_ostate,
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
                      v_other_ophone_no,
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
			  ELSIF v_comm_addr_lin1 = i2.cci_oaddr1 
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
                                     NULL,          --officno
                                     v_comm_emailid,
                                     v_gcm_cntry_code,
                                     v_comm_city,
                                     v_comm_state,
                                     NULL,
                                     'P',
									 v_comm_type,
                                     prm_lupduser,
                                      NULL,                      --prm_genaddr_data
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

               IF v_other_addr_lin1 IS NOT NULL
               THEN
			   IF v_comm_addr_lin1 = i2.cci_seg12_addr_line1 
										  THEN
											 	v_comm_type := 'R';
										  ELSIF v_comm_addr_lin1 = i2.cci_oaddr1
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
                                     v_other_ophone_no,
                                     v_other_mobileno,
                                     NULL,          --officno
                                     v_other_emailid,
                                     v_gcm_cntry_code,		 			   	  			 	 	  
                                     v_other_city,
                                     v_other_state,
                                     NULL,
                                     'O',
									 v_comm_type,
                                     prm_lupduser,
                                     NULL,                      --prm_genaddr_data
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

               --En create communication address

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
               --*******************************************************************
			   --Sn get acct number
               /*BEGIN
                  SELECT seq_acct_id.NEXTVAL
                    INTO v_acct_numb
                    FROM DUAL;
               EXCEPTION
                  WHEN OTHERS
                  THEN
                     v_errmsg :=
                           'Error while selecting acctnum '
                        || SUBSTR (SQLERRM, 1, 200);
                     RAISE exp_reject_record;
               END;*/

               --En get acct number
               --*******************************************************************
				 IF v_catg_code = 'P'
		         THEN
				 	  v_acct_numb :=NULL;
				 ELSIF v_catg_code = 'D' THEN
		
					 v_acct_numb :=i2.cci_seg31_num;
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
                    INTO v_expryparam
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
                  sp_create_appl_pcms_inv
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
                              -- Expry date is last day of the prev month after adding expry param
                              LAST_DAY (ADD_MONTHS (SYSDATE, v_expryparam - 1)),
                              SUBSTR (i2.cci_seg12_name_line1, 1, 30),
                              0,
                              'N',
                              NULL,
                              1,
                              'P', --addon status always a primary application
                              0,
                              --addon link 0 means that the appln is for promary pan
                              v_comm_addrcode,               --billing address
                              NULL,                             --channel code
                              i2.cci_file_name,					--Request id is file name 
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
               --En create Application
               UPDATE pcms_caf_info_inv
                  SET cci_approved = 'O',
                      cci_upld_stat = 'O',
					  CCI_APPL_CODE = v_appl_code,		---this condition is added because for ins
                      cci_process_msg = 'Successful'
                WHERE cci_row_id = i2.cci_row_id;

               UPDATE pcms_upload_summary
                  SET puc_success_records = puc_success_records + 1,
                      puc_tot_records = puc_tot_records + 1
                WHERE puc_file_name = i1.cuc_file_name;
/*This insert is used for update addr mast,appl pan and cust mast from procedure sp_update_appl_maker, these table data is matched with cms_caf_issuance_entry tale */
               
                  INSERT INTO pcms_issuanceentry_update
                              (ciu_appl_code, ciu_addr_comm_code,
                               ciu_addr_other_code
                              )
                       VALUES (v_appl_code, v_comm_addrcode,
                               v_other_addrcode
                              );
              
            EXCEPTION       --<< EXCEPTION LOOP C2  (FILE WISE RECORD WISE) >>
               WHEN exp_reject_record
               THEN
                  ROLLBACK TO v_savepoint;

                  UPDATE pcms_caf_info_inv
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

                  UPDATE pcms_caf_info_inv
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
            
			UPDATE CMS_UPLOAD_CTRL
			SET	   cuc_upld_stat = 'E'
			WHERE  CUC_FILE_NAME = i1.cuc_file_name;
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


