CREATE OR REPLACE PROCEDURE VMSCMS.sp_create_mercwall_acct (
   p_instcode    IN       NUMBER,
   p_bran_code   IN       VARCHAR2,
   p_lupd_user   IN       NUMBER,
   p_err_msg     OUT      VARCHAR2,
   p_pan		 OUT      VARCHAR2,
   p_applprocess_msg OUT  VARCHAR2		 
)
AS
   v_switch_acct_type      cms_acct_type.cat_switch_type%TYPE    DEFAULT '11';
   v_switch_acct_stat      cms_acct_stat.cas_switch_statcode%TYPE DEFAULT '3';
   v_cbm_cntry_code        cms_bran_mast.cbm_cntry_code%TYPE;
   v_cbm_state_code        cms_bran_mast.cbm_state_code%TYPE;
   v_cbm_inst_code         cms_bran_mast.cbm_inst_code%TYPE;
   v_cbm_bran_code         cms_bran_mast.cbm_bran_code%TYPE;
   v_cbm_bran_fiid         cms_bran_mast.cbm_bran_fiid%TYPE;
   v_cbm_micr_no           cms_bran_mast.cbm_micr_no%TYPE;
   v_cbm_bran_locn         cms_bran_mast.cbm_bran_locn%TYPE;
   v_cbm_addr_one          cms_bran_mast.cbm_addr_one%TYPE;
   v_cbm_addr_two          cms_bran_mast.cbm_addr_two%TYPE;
   v_cbm_addr_three        cms_bran_mast.cbm_addr_three%TYPE;
   v_cbm_city_code         cms_bran_mast.cbm_city_code%TYPE;
   v_cbm_pin_code          cms_bran_mast.cbm_pin_code%TYPE;
   v_cbm_phon_one          cms_bran_mast.cbm_phon_one%TYPE;
   v_cbm_phon_two          cms_bran_mast.cbm_phon_two%TYPE;
   v_cbm_phon_three        cms_bran_mast.cbm_phon_three%TYPE;
   v_cbm_cont_prsn         cms_bran_mast.cbm_cont_prsn%TYPE;
   v_cbm_fax_no            cms_bran_mast.cbm_fax_no%TYPE;
   v_cbm_email_id          cms_bran_mast.cbm_email_id%TYPE;
   v_cbm_ins_user          cms_bran_mast.cbm_ins_user%TYPE;
   v_cbm_ins_date          cms_bran_mast.cbm_ins_date%TYPE;
   v_cbm_lupd_user         cms_bran_mast.cbm_lupd_user%TYPE;
   v_cbm_lupd_date         cms_bran_mast.cbm_lupd_date%TYPE;
   v_cbm_tot_limit         cms_bran_mast.cbm_tot_limit%TYPE;
   v_cbm_avail_limit       cms_bran_mast.cbm_avail_limit%TYPE;
   v_cbm_bran_catg         cms_bran_mast.cbm_bran_catg%TYPE;
   v_cbm_bran_type         cms_bran_mast.cbm_bran_type%TYPE;
   v_cbm_reporting_bran    cms_bran_mast.cbm_reporting_bran%TYPE;
   v_cbm_acct_id           cms_bran_mast.cbm_acct_id%TYPE;
   v_cbm_wallet_catg       cms_bran_mast.cbm_wallet_catg%TYPE;
   v_cbm_wallet_type       cms_bran_mast.cbm_wallet_type%TYPE;
   v_cbm_commission_plan   cms_bran_mast.cbm_commission_plan%TYPE;
   v_cbm_define_commplan   cms_bran_mast.cbm_define_commplan%TYPE;
   v_cbm_sale_trans        cms_bran_mast.cbm_sale_trans%TYPE;
   v_cbm_topup_trans       cms_bran_mast.cbm_topup_trans%TYPE;
   v_prod_code             cms_prod_mast.cpm_prod_code%TYPE;
   v_inst_bin              cms_prod_bin.cpb_inst_bin%TYPE;
   v_prod_cattype          cms_prod_cattype.cpc_card_type%TYPE;
   v_custcatg              cms_cust_catg.ccc_catg_code%TYPE;
   v_prod_ccc              cms_prod_ccc.cpc_prod_sname%TYPE;
   v_func_code             cms_func_mast.cfm_func_code%TYPE;
   v_func_desc             cms_func_mast.cfm_func_desc%TYPE;
   v_gcm_cntry_code        gen_cntry_mast.gcm_cntry_code%TYPE;
   v_comm_addrcode         cms_addr_mast.cam_addr_code%TYPE;
   v_cust_code             cms_cust_mast.ccm_cust_code%TYPE;
   v_acct_type             cms_acct_type.cat_type_code%TYPE;
   v_acct_stat             cms_acct_mast.cam_stat_code%TYPE;
   v_acct_numb             cms_acct_mast.cam_acct_no%TYPE;
   v_acct_id               cms_acct_mast.cam_acct_id%TYPE;
   v_holdposn              cms_cust_acct.cca_hold_posn%TYPE;
   v_expryparam            cms_inst_param.cip_param_value%TYPE;
   v_appl_code             cms_appl_mast.cam_appl_code%TYPE;
   v_appl_no			   cms_appl_mast.cam_appl_no%TYPE;
   v_check_funccode        NUMBER;
   v_gender                VARCHAR2 (1);
   v_dup_flag              VARCHAR2 (1);
   v_errmsg                VARCHAR2 (300);
   exp_reject_record       EXCEPTION;
BEGIN                                                               --Begin 1.
   v_errmsg := 'OK';
   p_err_msg := 'OK';
   p_applprocess_msg := 'OK';
   SELECT cbm_cntry_code, cbm_state_code, cbm_inst_code,
          cbm_bran_code, cbm_bran_fiid, cbm_micr_no, cbm_bran_locn,
          cbm_addr_one, cbm_addr_two, cbm_addr_three, cbm_city_code,
          cbm_pin_code, cbm_phon_one, cbm_phon_two, cbm_phon_three,
          cbm_cont_prsn, cbm_fax_no, cbm_email_id, cbm_ins_user,
          cbm_ins_date, cbm_lupd_user, cbm_lupd_date, cbm_tot_limit,
          cbm_avail_limit, cbm_bran_catg, cbm_bran_type,
          cbm_reporting_bran, cbm_acct_id, cbm_wallet_catg,
          cbm_wallet_type, cbm_commission_plan, cbm_define_commplan,
          cbm_sale_trans, cbm_topup_trans
     INTO v_cbm_cntry_code, v_cbm_state_code, v_cbm_inst_code,
          v_cbm_bran_code, v_cbm_bran_fiid, v_cbm_micr_no, v_cbm_bran_locn,
          v_cbm_addr_one, v_cbm_addr_two, v_cbm_addr_three, v_cbm_city_code,
          v_cbm_pin_code, v_cbm_phon_one, v_cbm_phon_two, v_cbm_phon_three,
          v_cbm_cont_prsn, v_cbm_fax_no, v_cbm_email_id, v_cbm_ins_user,
          v_cbm_ins_date, v_cbm_lupd_user, v_cbm_lupd_date, v_cbm_tot_limit,
          v_cbm_avail_limit, v_cbm_bran_catg, v_cbm_bran_type,
          v_cbm_reporting_bran, v_cbm_acct_id, v_cbm_wallet_catg,
          v_cbm_wallet_type, v_cbm_commission_plan, v_cbm_define_commplan,
          v_cbm_sale_trans, v_cbm_topup_trans
     FROM cms_bran_mast
    WHERE cbm_bran_code = p_bran_code AND cbm_inst_code = p_instcode;

   BEGIN                                                            --Begin 2.
      -- Sn find product
      BEGIN
         SELECT cpm_prod_code
           INTO v_prod_code
           FROM cms_prod_mast
          WHERE cpm_inst_code = p_instcode
            AND cpm_prod_code = v_cbm_wallet_catg
            AND cpm_marc_prod_flag = 'N';
      EXCEPTION
         WHEN NO_DATA_FOUND
         THEN
            v_errmsg :=
                  'Product code'
               || v_cbm_wallet_catg
               || ' is not defined in the master';
            RAISE exp_reject_record;
         WHEN OTHERS
         THEN
            v_errmsg :=
                 'Error while selecting product ' || SUBSTR (SQLERRM, 1, 200);
            RAISE exp_reject_record;
      END;

      -- En find prod

      -- Sn check in prod bin
      BEGIN
         SELECT cpb_inst_bin
           INTO v_inst_bin
           FROM cms_prod_bin
          WHERE cpb_inst_code = p_instcode
            AND cpb_prod_code = v_cbm_wallet_catg
            AND cpb_marc_prodbin_flag = 'N'
            AND cpb_active_bin = 'Y';
      EXCEPTION
         WHEN NO_DATA_FOUND
         THEN
            v_errmsg :=
               'Product code' || v_cbm_wallet_catg
               || ' is not attached to BIN';
            RAISE exp_reject_record;
         WHEN OTHERS
         THEN
            v_errmsg :=
                  'Error while selecting product and bin dtl '
               || SUBSTR (SQLERRM, 1, 200);
            RAISE exp_reject_record;
      END;

      -- En check in prod bin.

      -- Sn find prod cattype
      BEGIN
         SELECT cpc_card_type
           INTO v_prod_cattype
           FROM cms_prod_cattype
          WHERE cpc_inst_code = p_instcode
            AND cpc_prod_code = v_cbm_wallet_catg
            AND cpc_card_type = v_cbm_wallet_type;
      EXCEPTION
         WHEN NO_DATA_FOUND
         THEN
            v_errmsg :=
                  'Product code'
               || v_cbm_wallet_catg
               || 'is not attached to cattype'
               || v_cbm_wallet_catg;
            RAISE exp_reject_record;
         WHEN OTHERS
         THEN
            v_errmsg :=
                  'Error while selecting product cattype '
               || SUBSTR (SQLERRM, 1, 200);
            RAISE exp_reject_record;
      END;

      BEGIN
         SELECT ccc_catg_code
           INTO v_custcatg
           FROM cms_cust_catg
          WHERE ccc_inst_code = p_instcode AND ccc_catg_sname = 'DEF';
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

      -- Sn find entry in prod ccc
      BEGIN
         SELECT cpc_prod_sname
           INTO v_prod_ccc
           FROM cms_prod_ccc
          WHERE cpc_inst_code = p_instcode
            AND cpc_prod_code = v_cbm_wallet_catg
            AND cpc_card_type = v_cbm_wallet_type
            AND cpc_cust_catg = v_custcatg;
      EXCEPTION
         WHEN NO_DATA_FOUND
         THEN
            BEGIN
               INSERT INTO cms_prod_ccc
                           (cpc_inst_code, cpc_cust_catg, cpc_card_type,
                            cpc_prod_code, cpc_ins_user, cpc_ins_date,
                            cpc_lupd_user, cpc_lupd_date, cpc_vendor,
                            cpc_stock, cpc_prod_sname
                           )
                    VALUES (p_instcode, v_custcatg, v_cbm_wallet_type,
                            v_cbm_wallet_catg, p_lupd_user, SYSDATE,
                            p_lupd_user, SYSDATE, '1',
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

      --Sn Check card issuance attached to product & Cardtype.
      BEGIN
         SELECT cfm_func_code, cfm_func_desc
           INTO v_func_code, v_func_desc
           FROM cms_func_mast
          WHERE cfm_inst_code = p_instcode
            AND cfm_txn_code = 'CI'
            AND cfm_txn_mode = '0'
            AND cfm_delivery_channel = '05';
      EXCEPTION
         WHEN NO_DATA_FOUND
         THEN
            v_errmsg := 'Master data is not available for card issuance';
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
          WHERE cfp_inst_code = p_instcode
            AND cfp_prod_code = v_cbm_wallet_catg
            AND cfp_prod_cattype = v_cbm_wallet_type
            AND cfp_func_code = v_func_code;
      EXCEPTION
         WHEN NO_DATA_FOUND
         THEN
            v_errmsg :=
                  v_func_desc
               || ' is not attached to product code '
               || v_cbm_wallet_catg
               || ' card type '
               || v_cbm_wallet_type;
            RAISE exp_reject_record;
         WHEN OTHERS
         THEN
            v_errmsg :=
                  'Error while verifing  funccode attachment to Product code & card type '
               || SUBSTR (SQLERRM, 1, 200);
            RAISE exp_reject_record;
      END;

      --En Check card issuance attached to product & Cardtype

      --Sn create customer
      BEGIN
         SELECT DECODE ('',
                        'Mr.', 'M',
                        'Mrs.', 'F',
                        'Miss.', 'F',
                        'Dr.', 'D',
                        '', 'O'
                       )
           INTO v_gender
           FROM DUAL;

         sp_create_cust (p_instcode,
                         1,
                         0,
                         'Y',
                         NULL,
                         v_cbm_bran_locn,
                         NULL,
                         NULL,
                         NULL,
                         v_gender,
                         NULL,
                         NULL,
                         v_cbm_email_id,
                         NULL,
                         v_cbm_phon_one,
                         v_cbm_phon_two,
                         p_lupd_user,
                         NULL,
                         NULL,
                         NULL,
                         NULL,
						 'P',
						 NULL,
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
                   'Error while create customer ' || SUBSTR (SQLERRM, 1, 200);
            RAISE exp_reject_record;
      END;

      --En create customer

      --Sn find country
      BEGIN
         SELECT gcm_cntry_code
           INTO v_gcm_cntry_code
           FROM gen_cntry_mast
          WHERE gcm_cntry_code = v_cbm_cntry_code;
      EXCEPTION
         WHEN NO_DATA_FOUND
         THEN
            v_errmsg := 'Country code not defined for  ' || v_cbm_cntry_code;
            RAISE exp_reject_record;
         WHEN OTHERS
         THEN
            v_errmsg :=
                  'Error while selecting country code for '
               || v_cbm_cntry_code
               || SUBSTR (SQLERRM, 1, 200);
            RAISE exp_reject_record;
      END;

      --En find country
      --Sn Create Address
      BEGIN
         sp_create_addr (p_instcode,
                         v_cust_code,
                         v_cbm_addr_one,
                         v_cbm_addr_two,
                         v_cbm_cont_prsn,
                         v_cbm_pin_code,
                         v_cbm_phon_one,
                         v_cbm_phon_two,
                         v_cbm_email_id,
                         v_gcm_cntry_code,
                         v_cbm_city_code,
                         v_cbm_state_code,
                         NULL,
                         'P',
						 'R', --v_comm_type
                         p_lupd_user,
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

--En Create Address
---------------------------------------------------------------------------------------

      -- Sn create account

      --Sn select acct type
      BEGIN
         SELECT cat_type_code
           INTO v_acct_type
           FROM cms_acct_type
          WHERE cat_inst_code = p_instcode
            AND cat_switch_type = v_switch_acct_type;
      EXCEPTION
         WHEN NO_DATA_FOUND
         THEN
            v_errmsg := 'Acct type not defined for  ' || v_switch_acct_type;
            RAISE exp_reject_record;
         WHEN OTHERS
         THEN
            v_errmsg :=
                'Error while selecting accttype ' || SUBSTR (SQLERRM, 1, 200);
            RAISE exp_reject_record;
      END;

      --En select acct type

      --Sn select acct stat
      BEGIN
         SELECT cas_stat_code
           INTO v_acct_stat
           FROM cms_acct_stat
          WHERE cas_inst_code = p_instcode
            AND cas_switch_statcode = v_switch_acct_stat;
      EXCEPTION
         WHEN NO_DATA_FOUND
         THEN
            v_errmsg := 'Acct stat not defined for  ' || v_switch_acct_type;
            RAISE exp_reject_record;
         WHEN OTHERS
         THEN
            v_errmsg :=
                'Error while selecting accttype ' || SUBSTR (SQLERRM, 1, 200);
            RAISE exp_reject_record;
      END;

      --En select acct stat

      /*--Sn get acct number
      BEGIN
         SELECT seq_acct_id.NEXTVAL
           INTO v_acct_numb
           FROM DUAL;
      EXCEPTION
         WHEN OTHERS
         THEN
            v_errmsg :=
                 'Error while selecting acctnum ' || SUBSTR (SQLERRM, 1, 200);
            RAISE exp_reject_record;
      END;
	  
      --En get acct number*/
	   v_acct_numb := NULL;
      --Sn create acct
      BEGIN
         sp_create_acct_pcms (p_instcode,
                              v_acct_numb,
                              0,
                              v_cbm_bran_fiid,
                              v_comm_addrcode,
                              v_acct_type,
                              v_acct_stat,
                              p_lupd_user,
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

      --Sn create a entry in cms_cust_acct
      BEGIN
         UPDATE cms_acct_mast
            SET cam_hold_count = cam_hold_count + 1,
                cam_lupd_user = p_lupd_user
          WHERE cam_inst_code = p_instcode AND cam_acct_id = v_acct_id;

         IF SQL%ROWCOUNT = 0
         THEN
            v_errmsg :=
                       'Error while update acct ' || SUBSTR (SQLERRM, 1, 200);
            RAISE exp_reject_record;
         END IF;
      END;

      sp_create_holder (p_instcode,
                        v_cust_code,
                        v_acct_id,
                        NULL,
                        p_lupd_user,
                        v_holdposn,
                        v_errmsg
                       );

      IF v_errmsg <> 'OK'
      THEN
         v_errmsg := 'Error from create entry cust_acct ' || v_errmsg;
         RAISE exp_reject_record;
      END IF;

      -- En create a entry in cms_cust_acct
      -- En create account

      -- Sn create Application
      -- Sn find expry param
      BEGIN
         SELECT cip_param_value
           INTO v_expryparam
           FROM cms_inst_param
          WHERE cip_inst_code = p_instcode AND cip_param_key = 'CARD EXPRY';
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
	  SELECT    TO_CHAR (SYSDATE, 'yyyy')
             || 'DEF'
             || LPAD (seq_appl_code.NEXTVAL, 8, 0)
        INTO v_appl_no
       FROM DUAL;
      BEGIN
         sp_create_appl_pcms (p_instcode,
                              1,
                              1,
                              v_appl_no,
                              SYSDATE,
                              SYSDATE,
                              v_cust_code,
                              v_cbm_bran_fiid,
                              v_prod_code,
                              v_prod_cattype,
                              v_custcatg,
                              SYSDATE,
                              LAST_DAY (ADD_MONTHS (SYSDATE, v_expryparam - 1)),
                              SUBSTR (v_cbm_bran_locn, 1, 30),
                              0,
                              'N',
                              NULL,
                              1,
                              'P',
                              0,
                              v_comm_addrcode,
                              NULL,
                              NULL,
                              NULL,
                              p_lupd_user,
                              p_lupd_user,
                              0,
                              v_appl_code,
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
         sp_create_appldet (p_instcode,
                            v_appl_code,
                            v_acct_id,
                            1,
                            p_lupd_user,
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
   -- En create Application
   	  
	  BEGIN
	  sp_gen_pan_mercwall(p_instcode,
						   v_appl_code,
						   p_lupd_user,
						   p_pan,
						   p_applprocess_msg,
						   v_errmsg);
		IF v_errmsg = 'OK' AND p_applprocess_msg = 'OK' AND p_pan IS NOT NULL THEN
		   p_pan := p_pan;
		   
		   		 
				BEGIN
				 	 INSERT INTO cms_merc_wallet(cmw_inst_code,cmw_acct_id,cmw_pan_no,cmw_bran_code,
		   		  	   			       		cmw_ins_user,cmw_ins_date,cmw_lupd_user,cmw_lups_date)
					 VALUES(p_instcode,v_acct_id, p_pan,v_cbm_bran_code,1,sysdate,1,sysdate);
					
				EXCEPTION
               	WHEN OTHERS
                THEN
                  	v_errmsg := 'Error while inserting record in merc wallet';
                RAISE exp_reject_record;
            	END;
		   
		END IF;
		IF v_errmsg <> 'OK' OR p_applprocess_msg <> 'OK'
        THEN
            v_errmsg := 'Error from create appl det ' || p_applprocess_msg;
			
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
   
   EXCEPTION
      WHEN exp_reject_record
      THEN
         p_err_msg := v_errmsg;
		 p_applprocess_msg := p_applprocess_msg;
      /*BEGIN
         INSERT INTO PCMS_UPLOAD_LOG(pul_inst_code,pul_file_name,pul_appl_no,pul_upld_stat,
         pul_approve_stat,pul_ins_date,pul_row_id,pul_process_message)
         VALUES(p_instcode,v_cbm_bran_code,I.CCI_APPL_NO,'E','A',SYSDATE,I.CCI_ROW_ID,v_errmsg);
         IF SQL%ROWCOUNT = 0 THEN
             prm_errmsg:= 'Error While inserting record in log table';

         END IF;
         EXCEPTION
            WHEN OTHERS THEN
                prm_errmsg:= 'Error While inserting record in log table';
      END;*/
      WHEN OTHERS
      THEN
         p_err_msg := v_errmsg;
		 p_applprocess_msg := p_applprocess_msg;
		 --p_applprocess_msg := p_applprocess_msg;
   /*BEGIN
      INSERT INTO PCMS_UPLOAD_LOG(pul_inst_code,pul_file_name,pul_appl_no,pul_upld_stat,
      pul_approve_stat,pul_ins_date,pul_row_id,pul_process_message)
      VALUES(prm_instcode,v_cbm_bran_code,I.CCI_APPL_NO,'E','A',SYSDATE,I.CCI_ROW_ID,v_errmsg);
      IF SQL%ROWCOUNT = 0 THEN
          prm_errmsg:= 'Error While inserting record in log table';

      END IF;
      EXCEPTION
         WHEN OTHERS THEN
             prm_errmsg:= 'Error While inserting record in log table';
   END;*/
   END;
EXCEPTION                                               --<< MAIN EXCEPTION >>
   WHEN OTHERS
   THEN
      p_err_msg := 'Exception from Main ' || SUBSTR (SQLERRM, 1, 300);
END;
/


