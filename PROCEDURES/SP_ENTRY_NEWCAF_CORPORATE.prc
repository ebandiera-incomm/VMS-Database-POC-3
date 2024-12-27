CREATE OR REPLACE PROCEDURE VMSCMS.Sp_Entry_Newcaf_Corporate (
   prm_instcode   IN       NUMBER,
   prm_lupduser   IN       NUMBER,
   prm_errmsg     OUT      VARCHAR2
)
IS
/*************************************************
     * VERSION             :  1.0.
     * Created Date       : 02/Sept/2009.
     * Created By        : Kaustubh.Dave
     * PURPOSE          : Application Processing for Corporate Customer.
     * Modified By     :.
     * Modified Date  :.
     * Reviewed By   : Chinmay B.
   ***********************************************/
   v_cust_code             CMS_CUST_MAST.ccm_cust_code%TYPE;
   v_gcm_cntry_code        GEN_CNTRY_MAST.gcm_cntry_code%TYPE;
   v_comm_addr_lin1        PCMS_CAF_INFO_CORPORATE.cci_seg12_addr_line1%TYPE;
   v_comm_addr_lin2        PCMS_CAF_INFO_CORPORATE.cci_seg12_addr_line2%TYPE;
   v_comm_postal_code      PCMS_CAF_INFO_CORPORATE.cci_seg12_postal_code%TYPE;
   v_comm_homephone_no     PCMS_CAF_INFO_CORPORATE.cci_seg12_homephone_no%TYPE;
   v_comm_mobileno         PCMS_CAF_INFO_CORPORATE.cci_seg12_mobileno%TYPE;
   v_comm_emailid          PCMS_CAF_INFO_CORPORATE.cci_seg12_emailid%TYPE;
   v_comm_city             PCMS_CAF_INFO_CORPORATE.cci_seg12_city%TYPE;
   v_comm_state            PCMS_CAF_INFO_CORPORATE.cci_seg12_state%TYPE;
   v_other_addr_lin1       PCMS_CAF_INFO_CORPORATE.cci_seg13_addr_line1%TYPE;
   v_other_addr_lin2       PCMS_CAF_INFO_CORPORATE.cci_seg13_addr_line2%TYPE;
   v_other_postal_code     PCMS_CAF_INFO_CORPORATE.cci_seg13_postal_code%TYPE;
   v_other_homephone_no    PCMS_CAF_INFO_CORPORATE.cci_seg13_homephone_no%TYPE;
   v_other_mobileno        PCMS_CAF_INFO_CORPORATE.cci_seg13_mobileno%TYPE;
   v_other_emailid         PCMS_CAF_INFO_CORPORATE.cci_seg13_emailid%TYPE;
   v_other_city            PCMS_CAF_INFO_CORPORATE.cci_seg13_city%TYPE;
   v_other_state           PCMS_CAF_INFO_CORPORATE.cci_seg12_state%TYPE;
   v_comm_addrcode         CMS_ADDR_MAST.cam_addr_code%TYPE;
   v_other_addrcode        CMS_ADDR_MAST.cam_addr_code%TYPE;
   v_switch_acct_type      CMS_ACCT_TYPE.cat_switch_type%TYPE    DEFAULT '11';
   v_switch_acct_stat      CMS_ACCT_STAT.cas_switch_statcode%TYPE DEFAULT '3';
   v_acct_type             CMS_ACCT_TYPE.cat_type_code%TYPE;
   v_acct_stat             CMS_ACCT_MAST.cam_stat_code%TYPE;
   v_acct_numb             CMS_ACCT_MAST.cam_acct_no%TYPE;
   v_acct_id               CMS_ACCT_MAST.cam_acct_id%TYPE;
   v_dup_flag              VARCHAR2 (1);
   v_prod_code             CMS_PROD_MAST.cpm_prod_code%TYPE;
   v_prod_cattype          CMS_PROD_CATTYPE.cpc_card_type%TYPE;
   v_inst_bin              CMS_PROD_BIN.cpb_inst_bin%TYPE;
   v_prod_ccc              CMS_PROD_CCC.cpc_prod_sname%TYPE;
   v_custcatg              CMS_PROD_CCC.cpc_cust_catg%TYPE;
   v_appl_code             CMS_APPL_MAST.cam_appl_code%TYPE;
   v_errmsg                VARCHAR2 (300);
   v_savepoint             NUMBER                                   DEFAULT 1;
   v_gender                VARCHAR2 (1);
   v_expryparam            CMS_INST_PARAM.cip_param_value%TYPE;
   v_holdposn              CMS_CUST_ACCT.cca_hold_posn%TYPE;
   v_brancheck             NUMBER (1);
   v_func_code             CMS_FUNC_MAST.cfm_func_code%TYPE;
   v_spprt_funccode        CMS_FUNC_MAST.cfm_func_code%TYPE;
   v_func_desc             CMS_FUNC_MAST.cfm_func_desc%TYPE;
   v_spprtfunc_desc        CMS_FUNC_MAST.cfm_func_desc%TYPE;
   v_catg_code             CMS_PROD_MAST.cpm_catg_code%TYPE;
   v_check_funccode        NUMBER (1);
   v_check_spprtfunccode   NUMBER (1);
   v_initial_spprtflag     VARCHAR2 (1);
   v_instrument_realised  VARCHAR2 (1);
   v_comm_type 		   CHAR(1);
   exp_reject_record       EXCEPTION;
   exp_process_record	   EXCEPTION;

   CURSOR c
   IS
      SELECT cci_inst_code, cci_file_name, cci_row_id, cci_appl_code,
             cci_appl_no, cci_pan_code, cci_mbr_numb, cci_crd_stat,
             cci_exp_dat, cci_rec_typ, cci_crd_typ, cci_requester_name,
             cci_prod_code, cci_card_type, cci_seg12_branch_num, cci_fiid,
             cci_title, cci_seg12_name_line1, cci_seg12_name_line2,
             cci_birth_date, cci_mother_name, cci_ssn, cci_hobbies,
             cci_cust_id, cci_comm_type, cci_seg12_addr_line1,
             cci_seg12_addr_line2, cci_seg12_city, cci_seg12_state,
             cci_seg12_postal_code, cci_seg12_country_code,
             cci_seg12_mobileno, cci_seg12_homephone_no,
             cci_seg12_officephone_no, cci_seg12_emailid,
             cci_seg13_addr_line1, cci_seg13_addr_line2, cci_seg13_city,
             cci_seg13_state, cci_seg13_postal_code, cci_seg13_country_code,
             cci_seg13_mobileno, cci_seg13_homephone_no,
             cci_seg13_officephone_no, cci_seg13_emailid, cci_seg31_lgth,
             cci_seg31_acct_cnt, cci_seg31_typ, cci_seg31_num,
             cci_seg31_stat, cci_prod_amt, cci_fee_amt, cci_tot_amt,
             cci_payment_mode, cci_instrument_no, cci_instrument_amt,
             cci_drawn_date, cci_payref_no, cci_emp_id, cci_kyc_reason,
             cci_kyc_flag, cci_addon_flag, cci_virtual_acct,
             cci_document_verify, cci_exchange_rate, cci_upld_stat,
             cci_approved, cci_maker_user_id, cci_maker_date,
             cci_checker_user_id, cci_cheker_date, cci_auth_user_id,
             cci_auth_date, cci_ins_user, cci_ins_date, cci_lupd_user,
             cci_lupd_date, cci_comments, cci_corp_id, ROWID r
        FROM PCMS_CAF_INFO_CORPORATE
       WHERE cci_approved = 'A'
         AND cci_inst_code = prm_instcode
         AND cci_upld_stat = 'P';
		-- AND    cci_instrument_realised ='Y';  -- 280109 Chinmaya not used in case of IIT
--AND    cci_kyc_flag      =  'Y';      -- 280109 Chinmaya not used in case of IIT
BEGIN                                                       --<< MAIN BEGIN >>
   --SN  Loop for record pending for processing
   DELETE FROM PCMS_UPLOAD_LOG;

   FOR i IN c
   LOOP
      --Initialize the common loop variable
      v_errmsg := 'OK';
      SAVEPOINT v_savepoint;

      BEGIN                                               --<< LOOP C BEGIN>>
	  
	  -- Sn Check instrument_realised first is Y or not
		 BEGIN
            SELECT CCI_INSTRUMENT_REALISED
              INTO v_instrument_realised
              FROM PCMS_CAF_INFO_CORPORATE
             WHERE cci_inst_code = prm_instcode
               AND cci_row_id = i.cci_row_id
               AND CCI_INSTRUMENT_REALISED = 'Y';
         EXCEPTION
            WHEN NO_DATA_FOUND
            THEN
               v_errmsg :=
                     'Instrument Realised '
                  || 'is pending for approval ';
               RAISE exp_process_record;
            WHEN OTHERS
            THEN
               v_errmsg :=
                  'Error while selecting Instrument Realised '
                  || SUBSTR (SQLERRM, 1, 200);
               RAISE exp_process_record;
         END;
		 --En check kyc first is N or Not
         --Sn  Check product , prodtype & cust catg
         -- Sn find prod
         BEGIN
            SELECT cpm_prod_code
              INTO v_prod_code
              FROM CMS_PROD_MAST
             WHERE cpm_inst_code = prm_instcode
               AND cpm_prod_code = i.cci_prod_code
               AND cpm_marc_prod_flag = 'N';
         EXCEPTION
            WHEN NO_DATA_FOUND
            THEN
               v_errmsg :=
                     'Product code'
                  || i.cci_prod_code
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
         -- Sn check in prod bin
         BEGIN
            SELECT cpb_inst_bin
              INTO v_inst_bin
              FROM CMS_PROD_BIN
             WHERE cpb_inst_code = prm_instcode
               AND cpb_prod_code = i.cci_prod_code
               AND cpb_marc_prodbin_flag = 'N'
               AND cpb_active_bin = 'Y';
         EXCEPTION
            WHEN NO_DATA_FOUND
            THEN
               v_errmsg :=
                     'Product code'
                  || i.cci_prod_code
                  || 'is not attached to BIN'
                  || i.cci_pan_code;
               RAISE exp_reject_record;
            WHEN OTHERS
            THEN
               v_errmsg :=
                     'Error while selecting product and bin dtl '
                  || SUBSTR (SQLERRM, 1, 200);
               RAISE exp_reject_record;
         END;

         -- En check in prod bin
         -- Sn find prod cattype
         BEGIN
            SELECT cpc_card_type
              INTO v_prod_cattype
              FROM CMS_PROD_CATTYPE
             WHERE cpc_inst_code = prm_instcode
               AND cpc_prod_code = i.cci_prod_code
               AND cpc_card_type = i.cci_card_type;
         EXCEPTION
            WHEN NO_DATA_FOUND
            THEN
               v_errmsg :=
                     'Product code'
                  || i.cci_prod_code
                  || 'is not attached to cattype'
                  || i.cci_card_type;
               RAISE exp_reject_record;
            WHEN OTHERS
            THEN
               v_errmsg :=
                     'Error while selecting product cattype '
                  || SUBSTR (SQLERRM, 1, 200);
               RAISE exp_reject_record;
         END;

         -- En find prod cattype
         --Sn find the default cust catg
         BEGIN
            SELECT ccc_catg_code
              INTO v_custcatg
              FROM CMS_CUST_CATG
             WHERE ccc_inst_code = prm_instcode AND ccc_catg_sname = 'DEF';
         EXCEPTION
            WHEN NO_DATA_FOUND
            THEN
               v_errmsg := 'Catg code is not defined ' || 'DEF';
               RAISE exp_reject_record;
            WHEN OTHERS
            THEN
               v_errmsg :=
                     'Error while selecting custcatg from master '
                  || SUBSTR (SQLERRM, 1, 200);
               RAISE exp_reject_record;
         END;

         --En find the default cust
         -- Sn find entry in prod ccc
         BEGIN
            SELECT cpc_prod_sname
              INTO v_prod_ccc
              FROM CMS_PROD_CCC
             WHERE cpc_inst_code = prm_instcode
               AND cpc_prod_code = i.cci_prod_code
               AND cpc_card_type = i.cci_card_type
               AND cpc_cust_catg = v_custcatg;
         EXCEPTION
            WHEN NO_DATA_FOUND
            THEN
               BEGIN
                  INSERT INTO CMS_PROD_CCC
                              (cpc_inst_code, cpc_cust_catg, cpc_card_type,
                               cpc_prod_code, cpc_ins_user, cpc_ins_date,
                               cpc_lupd_user, cpc_lupd_date, cpc_vendor,
                               cpc_stock, cpc_prod_sname
                              )
                       VALUES (prm_instcode, v_custcatg, i.cci_card_type,
                               i.cci_prod_code, prm_lupduser, SYSDATE,
                               prm_lupduser, SYSDATE, '1',
                               '1', 'Default'
                              );
               EXCEPTION
                  WHEN OTHERS
                  THEN
                     v_errmsg := 'Error while creating a entry in prod_ccc';
                     RAISE exp_reject_record;
               END;
            WHEN OTHERS
            THEN
               v_errmsg :=
                     'Error while selecting prodccc detail from master '
                  || SUBSTR (SQLERRM, 1, 200);
               RAISE exp_reject_record;
         END;

         -- En find entry in prod ccc

         --En Check Product , prod type & cust catg

         -- Sn find prod
         BEGIN
            SELECT cpm_catg_code
              INTO v_catg_code
              FROM CMS_PROD_MAST
             WHERE cpm_inst_code = prm_instcode
               AND cpm_prod_code = i.cci_prod_code
               AND cpm_marc_prod_flag = 'N';
         EXCEPTION
            WHEN NO_DATA_FOUND
            THEN
               v_errmsg :=
                     'Product code'
                  || i.cci_prod_code
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
            --Sn Check card issuance attached to product & Cardtype
            BEGIN
               SELECT cfm_func_code, cfm_func_desc
                 INTO v_func_code, v_func_desc
                 FROM CMS_FUNC_MAST
                WHERE cfm_inst_code = prm_instcode
                  AND cfm_txn_code = 'CI'
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
                 FROM CMS_FUNC_PROD
                WHERE cfp_inst_code = prm_instcode
                  AND cfp_prod_code = i.cci_prod_code
                  AND cfp_prod_cattype = i.cci_card_type
                  AND cfp_func_code = v_func_code;
            EXCEPTION
               WHEN NO_DATA_FOUND
               THEN
                  v_errmsg :=
                        v_func_desc
                     || ' is not attached to product code '
                     || i.cci_prod_code
                     || ' card type '
                     || i.cci_card_type;
                  RAISE exp_reject_record;
               WHEN OTHERS
               THEN
                  v_errmsg :=
                        'Error while verifing  funccode attachment to Product code & card type '
                     || SUBSTR (SQLERRM, 1, 200);
                  RAISE exp_reject_record;
            END;

            --En Check card issuance attached to product & Cardtype

            --Sn check card amount and initial load spprt function
            IF i.cci_prod_amt > 0
            THEN
               --Sn check initial load spprt func
               BEGIN
                  SELECT cfm_func_code, cfm_func_desc
                    INTO v_spprt_funccode, v_spprtfunc_desc
                    FROM CMS_FUNC_MAST
                   WHERE cfm_inst_code = prm_instcode
                     AND cfm_txn_code = 'IL'
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

               --Sn Check card initial load attached to product & Cardtype
               BEGIN
                  SELECT 1
                    INTO v_check_spprtfunccode
                    FROM CMS_FUNC_PROD
                   WHERE cfp_inst_code = prm_instcode
                     AND cfp_prod_code = i.cci_prod_code
                     AND cfp_prod_cattype = i.cci_card_type
                     AND cfp_func_code = v_spprt_funccode;

                  v_initial_spprtflag := 'Y';
               EXCEPTION
                  WHEN NO_DATA_FOUND
                  THEN
                     v_errmsg :=
                           v_spprtfunc_desc
                        || ' is not attached to product code '
                        || i.cci_prod_code
                        || ' card type '
                        || i.cci_card_type;
                     RAISE exp_reject_record;
                  WHEN OTHERS
                  THEN
                     v_errmsg :=
                           'Error while verifing  funccode attachment to Product code & card type for initial load'
                        || SUBSTR (SQLERRM, 1, 200);
                     RAISE exp_reject_record;
               END;
            --En Check card initial load attached to product & Cardtype
            END IF;
         END IF;

         --En check card amount and initial load spprt function

         --Sn find Branch
         BEGIN
            SELECT 1
              INTO v_brancheck
              FROM CMS_BRAN_MAST
             WHERE cbm_inst_code = prm_instcode AND cbm_bran_code = i.cci_fiid;
         EXCEPTION
            WHEN NO_DATA_FOUND
            THEN
               v_errmsg := 'Branch code not defined for  ' || i.cci_fiid;
               RAISE exp_reject_record;
            WHEN OTHERS
            THEN
               v_errmsg :=
                     'Error while selecting branch code for  '
                  || i.cci_fiid
                  || '  '
                  || SUBSTR (SQLERRM, 1, 200);
               RAISE exp_reject_record;
         END;

         --En find Branch

         --Sn find customer
         BEGIN
            SELECT ccm_cust_code
              INTO v_cust_code
              FROM CMS_CUST_MAST
             WHERE ccm_inst_code = prm_instcode
			 -- AND ccm_cust_code = i.cci_cust_id;
                AND ccm_cust_id = i.cci_cust_id;--As discuss with Shyamjit on 020909.
				   
			/*IF v_cust_code IS NOT NULL THEN	   
	            v_errmsg := 'Customer is already present in master ';
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
			--------------------If customer is not Found in table then we create Customer and address (As discussed with Shyamjit on 020909)------
				               --Sn create customer
				               BEGIN
				                  SELECT DECODE (i.cci_title,
				                                 'Mr.', 'M',
				                                 'Mrs.', 'F',
				                                 'Miss.', 'F',
				                                 'Dr.', 'D'
				                                )
				                    INTO v_gender
				                    FROM DUAL;
				
				                  Sp_Create_Cust (prm_instcode,
				                                  1,
				                                  i.cci_corp_id,
				                                  'Y',
				                                  i.cci_title,
				                                  i.cci_seg12_name_line1,
				                                  NULL,
				                                  ' ',
				                                  i.cci_birth_date,
				                                  v_gender,
				                                  NULL,
				                                  NULL,
				                                  NULL,
				                                  NULL,
				                                  NULL,
				                                  NULL,
				                                  prm_lupduser,
				                                  i.cci_ssn,
				                                  i.cci_mother_name,
				                                  i.cci_hobbies,
				                                  i.cci_emp_id,
												  v_catg_code,
												  i.cci_cust_id,
												  NULL, --Added on 10-12-2010
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
							--Sn find country
				         BEGIN
				            SELECT gcm_cntry_code
				              INTO v_gcm_cntry_code
				              FROM GEN_CNTRY_MAST
				             WHERE gcm_cntry_code = i.cci_seg12_country_code;
				         EXCEPTION
				            WHEN NO_DATA_FOUND
				            THEN
				               v_errmsg :=
				                  'Country code not defined for  '
				                  || i.cci_seg12_country_code;
				               RAISE exp_reject_record;
				            WHEN OTHERS
				            THEN
				               v_errmsg :=
				                     'Error while selecting country code for '
				                  || i.cci_seg12_country_code
				                  || SUBSTR (SQLERRM, 1, 200);
				               RAISE exp_reject_record;
				         END;
				
				         --En find country
				         --Sn create communication address
				         SELECT DECODE (i.cci_comm_type,
				                        '0', i.cci_seg12_addr_line1,
				                        i.cci_seg13_addr_line1
				                       ),
				                DECODE (i.cci_comm_type,
				                        '0', i.cci_seg12_addr_line2,
				                        i.cci_seg13_addr_line2
				                       ),
				                DECODE (i.cci_comm_type,
				                        '0', i.cci_seg12_postal_code,
				                        i.cci_seg13_postal_code
				                       ),
				                DECODE (i.cci_comm_type,
				                        '0', i.cci_seg12_homephone_no,
				                        i.cci_seg13_homephone_no
				                       ),
				                DECODE (i.cci_comm_type,
				                        '0', i.cci_seg12_mobileno,
				                        i.cci_seg13_mobileno
				                       ),
				                DECODE (i.cci_comm_type,
				                        '0', i.cci_seg12_emailid,
				                        i.cci_seg13_emailid
				                       ),
				                DECODE (i.cci_comm_type,
				                        '0', i.cci_seg12_city,
				                        i.cci_seg13_city
				                       ),
				                DECODE (i.cci_comm_type,
				                        '0', i.cci_seg12_state,
				                        i.cci_seg13_state
				                       ),
				                DECODE (i.cci_comm_type,
				                        '0', i.cci_seg13_addr_line1,
				                        i.cci_seg12_addr_line1
				                       ),
				                DECODE (i.cci_comm_type,
				                        '0', i.cci_seg13_addr_line2,
				                        i.cci_seg12_addr_line2
				                       ),
				                DECODE (i.cci_comm_type,
				                        '0', i.cci_seg13_postal_code,
				                        i.cci_seg12_postal_code
				                       ),
				                DECODE (i.cci_comm_type,
				                        '0', i.cci_seg13_homephone_no,
				                        i.cci_seg12_homephone_no
				                       ),
				                DECODE (i.cci_comm_type,
				                        '0', i.cci_seg13_mobileno,
				                        i.cci_seg12_mobileno
				                       ),
				                DECODE (i.cci_comm_type,
				                        '0', i.cci_seg13_emailid,
				                        i.cci_seg12_emailid
				                       ),
				                DECODE (i.cci_comm_type,
				                        '0', i.cci_seg13_city,
				                        i.cci_seg12_city
				                       ),
				                DECODE (i.cci_comm_type,
				                        '0', i.cci_seg13_state,
				                        i.cci_seg12_state
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
				
				         IF v_comm_addr_lin1 IS NOT NULL
				         THEN
						 	  IF v_comm_addr_lin1 = i.cci_seg12_addr_line1 
							  THEN
								 	v_comm_type := 'R';
							  ELSIF v_comm_addr_lin1 = i.cci_seg13_addr_line1 
							  THEN
						  			v_comm_type := 'O';
							  END IF;
				            BEGIN
				               Sp_Create_Addr (prm_instcode,
				                               v_cust_code,
				                               v_comm_addr_lin1,
				                               v_comm_addr_lin2,
											   i.cci_seg12_name_line2,
				                               v_comm_postal_code,
				                               v_comm_homephone_no,
				                               v_comm_mobileno,
											   v_comm_mobileno,
				                               v_comm_emailid,
				                               v_gcm_cntry_code,
				                               v_comm_city,
				                               v_comm_state,
				                               NULL,
				                               'P',
											   v_comm_type,
				                               prm_lupduser,
										       NULL, --Added on 10-12-2010
				                               v_comm_addrcode,
				                               v_errmsg
				                              );
				
				               IF v_errmsg <> 'OK'
				               THEN
				                  v_errmsg :=
				                       'Error from create communication address ' || v_errmsg;
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
						 	 IF v_comm_addr_lin1 = i.cci_seg12_addr_line1 
							  THEN
								 	v_comm_type := 'R';
							  ELSIF v_comm_addr_lin1 = i.cci_seg13_addr_line1 
							  THEN
						  			v_comm_type := 'O';
							  END IF;
				            BEGIN
				               Sp_Create_Addr (prm_instcode,
				                               v_cust_code,
				                               v_other_addr_lin1,
				                               v_other_addr_lin2,
				                               i.cci_seg12_name_line2,
				                               v_other_postal_code,
				                               v_other_homephone_no,
				                               v_other_mobileno,
											    v_other_mobileno,
				                               v_other_emailid,
				                               v_gcm_cntry_code,
				                               v_other_city,
				                               v_other_state,
				                               NULL,
				                               'O',
											   v_comm_type,
				                               prm_lupduser,
									   NULL, -- Added  on 10-12-2010
				                               v_other_addrcode,
				                               v_errmsg
				                              );
				
				               IF v_errmsg <> 'OK'
				               THEN
				                  v_errmsg :=
				                       'Error from create communication address ' || v_errmsg;
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
			--------------------If customer is not Found in table then we create Customer and address-- As discussed with Shyamjit on 020909 .-------
			WHEN exp_reject_record THEN
				 v_errmsg :=
                     'Error while selecting customer from master '
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
         /*--Sn find country
         BEGIN
            SELECT gcm_cntry_code
              INTO v_gcm_cntry_code
              FROM gen_cntry_mast
             WHERE gcm_cntry_code = i.cci_seg12_country_code;
         EXCEPTION
            WHEN NO_DATA_FOUND
            THEN
               v_errmsg :=
                  'Country code not defined for  '
                  || i.cci_seg12_country_code;
               RAISE exp_reject_record;
            WHEN OTHERS
            THEN
               v_errmsg :=
                     'Error while selecting country code for '
                  || i.cci_seg12_country_code
                  || SUBSTR (SQLERRM, 1, 200);
               RAISE exp_reject_record;
         END;

         --En find country
         --Sn create communication address
         SELECT DECODE (i.cci_comm_type,
                        '0', i.cci_seg12_addr_line1,
                        i.cci_seg13_addr_line1
                       ),
                DECODE (i.cci_comm_type,
                        '0', i.cci_seg12_addr_line2,
                        i.cci_seg13_addr_line2
                       ),
                DECODE (i.cci_comm_type,
                        '0', i.cci_seg12_postal_code,
                        i.cci_seg13_postal_code
                       ),
                DECODE (i.cci_comm_type,
                        '0', i.cci_seg12_homephone_no,
                        i.cci_seg13_homephone_no
                       ),
                DECODE (i.cci_comm_type,
                        '0', i.cci_seg12_mobileno,
                        i.cci_seg13_mobileno
                       ),
                DECODE (i.cci_comm_type,
                        '0', i.cci_seg12_emailid,
                        i.cci_seg13_emailid
                       ),
                DECODE (i.cci_comm_type,
                        '0', i.cci_seg12_city,
                        i.cci_seg13_city
                       ),
                DECODE (i.cci_comm_type,
                        '0', i.cci_seg12_state,
                        i.cci_seg13_state
                       ),
                DECODE (i.cci_comm_type,
                        '0', i.cci_seg13_addr_line1,
                        i.cci_seg12_addr_line1
                       ),
                DECODE (i.cci_comm_type,
                        '0', i.cci_seg13_addr_line2,
                        i.cci_seg12_addr_line2
                       ),
                DECODE (i.cci_comm_type,
                        '0', i.cci_seg13_postal_code,
                        i.cci_seg12_postal_code
                       ),
                DECODE (i.cci_comm_type,
                        '0', i.cci_seg13_homephone_no,
                        i.cci_seg12_homephone_no
                       ),
                DECODE (i.cci_comm_type,
                        '0', i.cci_seg13_mobileno,
                        i.cci_seg12_mobileno
                       ),
                DECODE (i.cci_comm_type,
                        '0', i.cci_seg13_emailid,
                        i.cci_seg12_emailid
                       ),
                DECODE (i.cci_comm_type,
                        '0', i.cci_seg13_city,
                        i.cci_seg12_city
                       ),
                DECODE (i.cci_comm_type,
                        '0', i.cci_seg13_state,
                        i.cci_seg12_state
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

         IF v_comm_addr_lin1 IS NOT NULL
         THEN
            BEGIN
               sp_create_addr (prm_instcode,
                               v_cust_code,
                               v_comm_addr_lin1,
                               v_comm_addr_lin2,
                               i.cci_seg12_name_line2,
                               v_comm_postal_code,
                               v_comm_homephone_no,
                               v_comm_mobileno,
                               v_comm_emailid,
                               v_gcm_cntry_code,
                               v_comm_city,
                               v_comm_state,
                               NULL,
                               'P',
                               prm_lupduser,
                               v_comm_addrcode,
                               v_errmsg
                              );

               IF v_errmsg <> 'OK'
               THEN
                  v_errmsg :=
                       'Error from create communication address ' || v_errmsg;
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
            BEGIN
               sp_create_addr (prm_instcode,
                               v_cust_code,
                               v_other_addr_lin1,
                               v_other_addr_lin2,
                               i.cci_seg12_name_line2,
                               v_other_postal_code,
                               v_other_homephone_no,
                               v_other_mobileno,
                               v_other_emailid,
                               v_gcm_cntry_code,
                               v_other_city,
                               v_other_state,
                               NULL,
                               'O',
                               prm_lupduser,
                               v_other_addrcode,
                               v_errmsg
                              );

               IF v_errmsg <> 'OK'
               THEN
                  v_errmsg :=
                       'Error from create communication address ' || v_errmsg;
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

         --En create other address*/
         -- Sn create account
            --Sn select acct type
         BEGIN
            SELECT cat_type_code
              INTO v_acct_type
              FROM CMS_ACCT_TYPE
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
              FROM CMS_ACCT_STAT
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
        --**************************************************
		/* --Sn get acct number
         BEGIN
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
         END;
		 --***************************************************
         --En get acct number*/
		 IF v_catg_code = 'P' THEN
		 v_acct_numb := NULL;
		 ELSIF v_catg_code = 'D' THEN
		 v_acct_numb := i.cci_seg31_num;
		 END IF;
         --Sn create acct
         BEGIN
            Sp_Create_Acct_Pcms (prm_instcode,
                                 v_acct_numb,
                                 0,
                                 i.cci_fiid,
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
                       'Error while create acct ' || SUBSTR (SQLERRM, 1, 200);
               RAISE exp_reject_record;
         END;

           --En create acct
         --Sn Create acct in corporate card
         IF i.cci_corp_id IS NOT NULL
         THEN
            BEGIN
               INSERT INTO PCMS_CORPORATE_CARDS
                           (pcc_inst_code, pcc_corp_code, pcc_pan_no,
                            pcc_ins_user, pcc_ins_date, pcc_lupd_user,
                            pcc_lupd_date
                           )
                    VALUES (prm_instcode, i.cci_corp_id, v_acct_id,
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

         --Sn create a entry in cms_cust_acct
         BEGIN
            UPDATE CMS_ACCT_MAST
               SET cam_hold_count = cam_hold_count + 1,
                   cam_lupd_user = prm_lupduser
             WHERE cam_inst_code = prm_instcode AND cam_acct_id = v_acct_id;

            IF SQL%ROWCOUNT = 0
            THEN
               v_errmsg :=
                       'Error while update acct ' || SUBSTR (SQLERRM, 1, 200);
               RAISE exp_reject_record;
            END IF;
         END;

         Sp_Create_Holder (prm_instcode,
                           v_cust_code,
                           v_acct_id,
                           NULL,
                           prm_lupduser,
                           v_holdposn,
                           v_errmsg
                          );

         IF v_errmsg <> 'OK'
         THEN
            v_errmsg := 'Error from create entry cust_acct ' || v_errmsg;
            RAISE exp_reject_record;
         END IF;

         ---En create a entry in cms_cust_acct

         -- En create account
         -- Sn create Application

         -- Sn find expry param
         BEGIN
            SELECT cip_param_value
--added on 11/10/2002 ...gets the card validity period in months from parameter table
            INTO   v_expryparam
              FROM CMS_INST_PARAM
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
            Sp_Create_Appl_Pcms
                    (prm_instcode,
                     1,
                     1,
                     i.cci_appl_no,
                     SYSDATE,
                     SYSDATE,
                     v_cust_code,
                     i.cci_fiid,
                     v_prod_code,
                     v_prod_cattype,
                     --(normal or blue depending upon hni or others cust catg)
                     v_custcatg,                           --customer category
                     SYSDATE,
-- last_day(add_months(to_date(y.cci_exp_dat,'YYMM'),--(expry_param))), -- Ashwini -25 Jan 05----  to be written as code refered frm hdfc ,
                -- Expry date is last day of the prev month after adding expry param
                     LAST_DAY (ADD_MONTHS (SYSDATE, v_expryparam - 1)),
--last_day(to_date(y.cci_exp_dat,'YYMM')), -- Ashwini-25 Jan 05 ----  to be written as code refered frm hdfc --
                     SUBSTR (i.cci_seg12_name_line1, 1, 30),
                     0,
                     'N',
                     NULL,
                     1,
                     
--total account count  = 1 since in upload a card is associated with only one account
                     'P',          --addon status always a primary application
                     0, --addon link 0 means that the appln is for promary pan
                     v_comm_addrcode,                        --billing address
                     NULL,                                      --channel code
                     NULL,
                     i.cci_payref_no,
                     prm_lupduser,
                     prm_lupduser,
                     TO_NUMBER (i.cci_prod_amt),
                     v_appl_code,                                  --out param
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
                       'Error while create appl ' || SUBSTR (SQLERRM, 1, 200);
               RAISE exp_reject_record;
         END;

         -- En Appl
         -- Sn create entry in appl_det
         BEGIN
            Sp_Create_Appldet (prm_instcode,
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
                   'Error while create appl det ' || SUBSTR (SQLERRM, 1, 200);
               RAISE exp_reject_record;
         END;

             -- En create entry in appl_det
         --En create Application

         --Sn mark the record as successful
         UPDATE PCMS_CAF_INFO_CORPORATE
            SET cci_approved = 'O',
                cci_upld_stat = 'O',
				CCI_APPL_CODE = v_appl_code,
                cci_process_msg = 'Successful'
          WHERE cci_inst_code = prm_instcode AND ROWID = i.r;

         ---prm_errmsg := 'Successful';
         BEGIN
            INSERT INTO PCMS_UPLOAD_LOG
                        (pul_inst_code, pul_file_name, pul_appl_no,
                         pul_upld_stat, pul_approve_stat, pul_ins_date,
                         pul_row_id, pul_process_message
                        )
                 VALUES (prm_instcode, i.cci_file_name, i.cci_appl_no,
                         'O', 'O', SYSDATE,
                         i.cci_row_id, 'Successful'
                        );

            IF SQL%ROWCOUNT = 0
            THEN
               prm_errmsg := 'Error While inserting record in log table';
               ROLLBACK TO v_savepoint;
            END IF;
         EXCEPTION
            WHEN OTHERS
            THEN
               prm_errmsg := 'Error While inserting record in log table';
               ROLLBACK TO v_savepoint;
         END;

         --En mark the record as successful
         v_savepoint := v_savepoint + 1;
      EXCEPTION
--<< LOOP C EXCEPTION >>  /* Added By kaustubh 23-04-09 for inserting record into log table*/
         WHEN exp_process_record
         THEN
            ROLLBACK TO v_savepoint;

            UPDATE PCMS_CAF_INFO_CORPORATE
               SET cci_approved = 'A',
                   cci_upld_stat = 'P',
                   cci_process_msg = v_errmsg
             WHERE cci_inst_code = prm_instcode AND ROWID = i.r;

            BEGIN
               INSERT INTO PCMS_UPLOAD_LOG
                           (pul_inst_code, pul_file_name, pul_appl_no,
                            pul_upld_stat, pul_approve_stat, pul_ins_date,
                            pul_row_id, pul_process_message
                           )
                    VALUES (prm_instcode, i.cci_file_name, i.cci_appl_no,
                            'E', 'A', SYSDATE,
                            i.cci_row_id, v_errmsg
                           );

               IF SQL%ROWCOUNT = 0
               THEN
                  prm_errmsg := 'Error While inserting record in log table';
                  ROLLBACK TO v_savepoint;
               END IF;
            EXCEPTION
               WHEN OTHERS
               THEN
                  prm_errmsg := 'Error While inserting record in log table';
                  ROLLBACK TO v_savepoint;
            END;
		 
		 WHEN exp_reject_record
         THEN
            ROLLBACK TO v_savepoint;

            UPDATE PCMS_CAF_INFO_CORPORATE
               SET cci_approved = 'A',
                   cci_upld_stat = 'E',
                   cci_process_msg = v_errmsg
             WHERE cci_inst_code = prm_instcode AND ROWID = i.r;

            BEGIN
               INSERT INTO PCMS_UPLOAD_LOG
                           (pul_inst_code, pul_file_name, pul_appl_no,
                            pul_upld_stat, pul_approve_stat, pul_ins_date,
                            pul_row_id, pul_process_message
                           )
                    VALUES (prm_instcode, i.cci_file_name, i.cci_appl_no,
                            'E', 'A', SYSDATE,
                            i.cci_row_id, v_errmsg
                           );

               IF SQL%ROWCOUNT = 0
               THEN
                  prm_errmsg := 'Error While inserting record in log table';
                  ROLLBACK TO v_savepoint;
               END IF;
            EXCEPTION
               WHEN OTHERS
               THEN
                  prm_errmsg := 'Error While inserting record in log table';
                  ROLLBACK TO v_savepoint;
            END;
         WHEN OTHERS
         THEN
            /* Added By kaustubh 23-04-09 for inserting record into log table*/
            ROLLBACK TO v_savepoint;

            UPDATE PCMS_CAF_INFO_CORPORATE
               SET cci_approved = 'A',
                   cci_upld_stat = 'E',
                   cci_process_msg = v_errmsg
             WHERE cci_inst_code = prm_instcode AND ROWID = i.r;

            BEGIN
               INSERT INTO PCMS_UPLOAD_LOG
                           (pul_inst_code, pul_file_name, pul_appl_no,
                            pul_upld_stat, pul_approve_stat, pul_ins_date,
                            pul_row_id, pul_process_message
                           )
                    VALUES (prm_instcode, i.cci_file_name, i.cci_appl_no,
                            'E', 'A', SYSDATE,
                            i.cci_row_id, v_errmsg
                           );

               IF SQL%ROWCOUNT = 0
               THEN
                  prm_errmsg := 'Error While inserting record in log table';
                  ROLLBACK TO v_savepoint;
               END IF;
            EXCEPTION
               WHEN OTHERS
               THEN
                  prm_errmsg := 'Error While inserting record in log table';
                  ROLLBACK TO v_savepoint;
            END;
      END;                                                   --<< LOOP C END>>
   --En  Loop for record pending for processing
   END LOOP;

   prm_errmsg := 'OK';
EXCEPTION                                               --<< MAIN EXCEPTION >>
   WHEN OTHERS
   THEN
      prm_errmsg := 'Exception from Main ' || SUBSTR (SQLERRM, 1, 300);
END;                                                          --<< MAIN END >>
/


