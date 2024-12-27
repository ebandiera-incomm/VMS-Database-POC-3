CREATE OR REPLACE PROCEDURE VMSCMS.sp_upload_newcaf_old_12052010 (
   instcode   	  IN       NUMBER,
   filename   	  IN       VARCHAR2,
   filerectype    IN       VARCHAR2,
   lupduser   	  IN       NUMBER,
   errmsg     	  OUT      VARCHAR2
)
AS
   dup_check                VARCHAR (1);
   CURSOR c1
   IS
      SELECT cuc_file_name
        FROM cms_upload_ctrl
       WHERE cuc_file_name LIKE filename || '%' AND cuc_upld_stat = 'P';
   CURSOR c2 (fname IN VARCHAR2)
   IS
      SELECT   cci_file_name, cci_row_id, cci_inst_code, cci_lgth, cci_cnt,
               cci_pan_code, cci_mbr_numb, cci_prod_code, cci_rec_typ,
               cci_crd_typ, cci_requester_name, cci_fiid, cci_crd_stat,
               cci_pin_ofst, cci_ttl_wdl_lmt, cci_offl_wdl_lmt,
               cci_ttl_cca_lmt, cci_offl_cca_lmt, cci_aggr_lmt,
               cci_offl_aggr_lmt, cci_first_used_dat, cci_last_reset_dat,
               cci_exp_dat, cci_user_fld1, cci_card_alpha_key, cci_vendor,
               cci_crd_fiid, cci_stock, cci_prefix, cci_seg1_lgth,
               cci_seg1_use_lmt, cci_seg1_ttl_wdl_lmt, cci_seg1_offl_wdl_lmt,
               cci_seg1_ttl_cca_lmt, cci_seg1_offl_cca_lmt,
               cci_seg1_dep_cr_lmt, cci_seg1_last_used, cci_seg_lgth,
               cci_seg_ofst, cci_seg_ttl_pur_lmt, cci_seg_offl_pur_lmt,
               cci_seg_ttl_cca_lmt, cci_seg_offl_cca_lmt,
               cci_seg_ttl_wdl_lmt, cci_seg_offl_wdl_lmt, cci_seg_user_fld,
               cci_seg_use_lmt, cci_seg_ttl_rfnd_cr_lmt,
               cci_seg_offl_rfnd_cr_lmt, cci_seg_rsn_cde, cci_seg_last_used,
               cci_seg_user_fld2, cci_seg12_lgth, cci_seg12_branch_num,
               cci_seg12_dept_num, cci_seg12_pin_mailer,
               cci_seg12_card_carrier, cci_seg12_cardholder_title,
               cci_seg12_open_text1, cci_seg12_name_line1,
               cci_seg12_name_line2, cci_birth_date, cci_mother_name,
               cci_ssn, cci_hobbies, cci_seg12_addr_line1,
               cci_seg12_addr_line2, cci_seg12_city, cci_seg12_state,
               cci_seg12_postal_code, cci_seg12_country_code,
               cci_seg12_mobileno, cci_seg12_homephone_no,
               cci_seg12_officephone_no, cci_seg12_emailid,
               cci_seg13_addr_line1, cci_seg13_addr_line2, cci_seg13_city,
               cci_seg13_state, cci_seg13_postal_code,
               cci_seg13_country_code, cci_seg13_mobileno,
               cci_seg13_homephone_no, cci_seg13_officephone_no,
               cci_seg13_emailid, cci_seg12_issue_stat, cci_seg12_issue_num,
               cci_seg12_cards_to_issue, cci_seg12_cards_issued,
               cci_seg12_cards_ret, cci_seg12_sec_char, cci_seg12_issue_dat,
               cci_seg12_effective_dat, cci_seg12_cvv_value,
               cci_seg12_srvc_cde, cci_seg12_filler, cci_seg31_lgth,
               cci_seg31_acct_cnt, cci_seg31_typ, cci_seg31_num,
               cci_seg31_stat, cci_seg31_descr, cci_seg31_corp,
               cci_seg31_user_fld2a, cci_seg31_typ1, cci_seg31_num1,
               cci_seg31_stat1, cci_seg31_descr1, cci_seg31_corp1,
               cci_seg31_user_fld2a1, cci_seg31_typ2, cci_seg31_num2,
               cci_seg31_stat2, cci_seg31_descr2, cci_seg31_corp2,
               cci_seg31_user_fld2a2, cci_seg31_typ3, cci_seg31_num3,
               cci_seg31_stat3, cci_seg31_descr3, cci_seg31_corp3,
               cci_seg31_user_fld2a3, cci_seg31_typ4, cci_seg31_num4,
               cci_seg31_stat4, cci_seg31_descr4, cci_seg31_corp4,
               cci_seg31_user_fld2a4, cci_seg31_typ5, cci_seg31_num5,
               cci_seg31_stat5, cci_seg31_descr5, cci_seg31_corp5,
               cci_seg31_user_fld2a5, cci_seg31_typ6, cci_seg31_num6,
               cci_seg31_stat6, cci_seg31_descr6, cci_seg31_corp6,
               cci_seg31_user_fld2a6, cci_seg31_typ7, cci_seg31_num7,
               cci_seg31_stat7, cci_seg31_descr7, cci_seg31_corp7,
               cci_seg31_user_fld2a7, cci_seg31_typ8, cci_seg31_num8,
               cci_seg31_stat8, cci_seg31_descr8, cci_seg31_corp8,
               cci_seg31_user_fld2a8, cci_seg31_typ9, cci_seg31_num9,
               cci_seg31_stat9, cci_seg31_descr9, cci_seg31_corp9,
               cci_seg31_user_fld2a9, cci_upld_stat, cci_approved,
               cci_card_type, cci_cust_id, cci_document_verify, cci_ins_user,
               cci_ins_date, cci_lupd_user, cci_lupd_date, cci_comm_type,
			   --Sn Customer generic data
			    cci_custappl_param1, 
				cci_custappl_param2, 
				cci_custappl_param3, 
				cci_custappl_param4, 
				cci_custappl_param5, 
				cci_custappl_param6, 
				cci_custappl_param7, 
				cci_custappl_param8, 
				cci_custappl_param9, 
				cci_custappl_param10,
		   --En customer generic data
		   --Sn select addrss seg12 detail
		   		cci_seg12_addr_param1, 
				cci_seg12_addr_param2, 
				cci_seg12_addr_param3, 
				cci_seg12_addr_param4, 
				cci_seg12_addr_param5, 
				cci_seg12_addr_param6, 
				cci_seg12_addr_param7, 
				cci_seg12_addr_param8, 
				cci_seg12_addr_param9, 
				cci_seg12_addr_param10,
		   --En select ddrss seg12 detail
		   --Sn select addrss seg12 detail
		   		cci_seg13_addr_param1, 
				cci_seg13_addr_param2, 
				cci_seg13_addr_param3, 
				cci_seg13_addr_param4, 
				cci_seg13_addr_param5, 
				cci_seg13_addr_param6, 
				cci_seg13_addr_param7, 
				cci_seg13_addr_param8, 
				cci_seg13_addr_param9, 
				cci_seg13_addr_param10
		   --En select ddrss seg12 detail
          FROM cms_caf_info_temp
         WHERE cci_inst_code = instcode
           AND cci_file_name = fname
           AND cci_upld_stat = 'P'
      ORDER BY cci_fiid, cci_seg31_num;
   cust                     cms_cust_mast.ccm_cust_code%TYPE;
   v_gcm_othercntry_code    gen_cntry_mast.gcm_cntry_code%TYPE;
   v_gcm_cntry_code         gen_cntry_mast.gcm_cntry_code%TYPE;
   addrcode                 cms_addr_mast.cam_addr_code%TYPE;
   acctid                   cms_acct_mast.cam_acct_id%TYPE;
   holdposn                 cms_cust_acct.cca_hold_posn%TYPE;
   v_cpb_prod_code          cms_prod_bin.cpb_prod_code%TYPE;
   applcode                 cms_appl_mast.cam_appl_code%TYPE;
   dupflag                  CHAR (1);
   v_cpm_interchange_code   cms_prodtype_map.cpm_interchange_code%TYPE;
   v_ccc_catg_code          cms_cust_catg.ccc_catg_code%TYPE              := 1;
   v_cat_type_code          cms_acct_type.cat_type_code%TYPE;
   v_cas_stat_code          cms_acct_stat.cas_stat_code%TYPE;
   v_cci_seg31_acct_cnt     cms_caf_info_temp.cci_seg31_acct_cnt%TYPE;
   v_cci_seg31_typ          cms_caf_info_temp.cci_seg31_typ%TYPE;
   v_cci_seg31_num          cms_caf_info_temp.cci_seg31_num%TYPE;
   v_cci_seg31_stat         cms_caf_info_temp.cci_seg31_stat%TYPE;
   v_cci_seg31_typ1         cms_caf_info_temp.cci_seg31_typ1%TYPE;
   v_cci_seg31_num1         cms_caf_info_temp.cci_seg31_num1%TYPE;
   v_cci_seg31_stat1        cms_caf_info_temp.cci_seg31_stat1%TYPE;
   v_cci_seg31_typ2         cms_caf_info_temp.cci_seg31_typ2%TYPE;
   v_cci_seg31_num2         cms_caf_info_temp.cci_seg31_num2%TYPE;
   v_cci_seg31_stat2        cms_caf_info_temp.cci_seg31_stat2%TYPE;
   v_cci_seg31_typ3         cms_caf_info_temp.cci_seg31_typ3%TYPE;
   v_cci_seg31_num3         cms_caf_info_temp.cci_seg31_num3%TYPE;
   v_cci_seg31_stat3        cms_caf_info_temp.cci_seg31_stat3%TYPE;
   v_cci_seg31_typ4         cms_caf_info_temp.cci_seg31_typ4%TYPE;
   v_cci_seg31_num4         cms_caf_info_temp.cci_seg31_num4%TYPE;
   v_cci_seg31_stat4        cms_caf_info_temp.cci_seg31_stat4%TYPE;
   v_cci_seg31_typ5         cms_caf_info_temp.cci_seg31_typ5%TYPE;
   v_cci_seg31_num5         cms_caf_info_temp.cci_seg31_num5%TYPE;
   v_cci_seg31_stat5        cms_caf_info_temp.cci_seg31_stat5%TYPE;
   v_cci_seg31_typ6         cms_caf_info_temp.cci_seg31_typ6%TYPE;
   v_cci_seg31_num6         cms_caf_info_temp.cci_seg31_num6%TYPE;
   v_cci_seg31_stat6        cms_caf_info_temp.cci_seg31_stat6%TYPE;
   v_cci_seg31_typ7         cms_caf_info_temp.cci_seg31_typ7%TYPE;
   v_cci_seg31_num7         cms_caf_info_temp.cci_seg31_num7%TYPE;
   v_cci_seg31_stat7        cms_caf_info_temp.cci_seg31_stat7%TYPE;
   v_cci_seg31_typ8         cms_caf_info_temp.cci_seg31_typ8%TYPE;
   v_cci_seg31_num8         cms_caf_info_temp.cci_seg31_num8%TYPE;
   v_cci_seg31_stat8        cms_caf_info_temp.cci_seg31_stat8%TYPE;
   v_cci_seg31_typ9         cms_caf_info_temp.cci_seg31_typ9%TYPE;
   v_cci_seg31_num9         cms_caf_info_temp.cci_seg31_num9%TYPE;
   v_cci_seg31_stat9        cms_caf_info_temp.cci_seg31_stat9%TYPE;
   v_comm_addr_lin1         pcms_caf_info_temp.cci_seg12_addr_line1%TYPE;
   v_comm_addr_lin2         pcms_caf_info_temp.cci_seg12_addr_line2%TYPE;
   v_comm_postal_code       pcms_caf_info_temp.cci_seg12_postal_code%TYPE;
   v_comm_homephone_no      pcms_caf_info_temp.cci_seg12_homephone_no%TYPE;
   v_comm_mobileno          pcms_caf_info_temp.cci_seg12_mobileno%TYPE;
   v_comm_emailid           pcms_caf_info_temp.cci_seg12_emailid%TYPE;
   v_comm_city              pcms_caf_info_temp.cci_seg12_city%TYPE;
   v_comm_state             pcms_caf_info_temp.cci_seg12_state%TYPE;
   v_other_addr_lin1        pcms_caf_info_temp.cci_seg13_addr_line1%TYPE;
   v_other_addr_lin2        pcms_caf_info_temp.cci_seg13_addr_line2%TYPE;
   v_other_postal_code      pcms_caf_info_temp.cci_seg13_postal_code%TYPE;
   v_other_homephone_no     pcms_caf_info_temp.cci_seg13_homephone_no%TYPE;
   v_other_mobileno         pcms_caf_info_temp.cci_seg13_mobileno%TYPE;
   v_other_emailid          pcms_caf_info_temp.cci_seg13_emailid%TYPE;
   v_other_city             pcms_caf_info_temp.cci_seg13_city%TYPE;
   v_other_state            pcms_caf_info_temp.cci_seg12_state%TYPE;
   v_comm_addrcode          cms_addr_mast.cam_addr_code%TYPE;
   v_other_addrcode         cms_addr_mast.cam_addr_code%TYPE;
   expry_param              NUMBER (3);
   dum1                     NUMBER (1);
   v_card_type              cms_prod_cattype.cpc_card_type%TYPE;
   v_gender                 CHAR (1);
   exp_reject_record        EXCEPTION;
   exp_reject_file			EXCEPTION;
   v_savepoint              NUMBER                                   DEFAULT 0;
   v_comm_type				CHAR(1);
   v_cust_data				type_cust_rec_array;
   v_addr_data1				type_addr_rec_array;
   v_addr_data2				type_addr_rec_array;
   --*************************local procedure for handling the account part********************************
   PROCEDURE lp_acct_part (
      cust       IN       NUMBER,
      addr       IN       NUMBER,
      filename   IN       VARCHAR2,
      frowid     IN       NUMBER,
      branch     IN       VARCHAR2,
      acctid     OUT      VARCHAR2,
      lperr      OUT      VARCHAR2
   )
   IS
   BEGIN
      dupflag := 'A';
      SELECT cip_param_value
        INTO expry_param
        FROM cms_inst_param
       WHERE cip_inst_code = instcode AND cip_param_key = 'CARD EXPRY';
      BEGIN
         SELECT cci_seg31_acct_cnt, cci_seg31_typ, cci_seg31_num,
                cci_seg31_stat, cci_seg31_typ1, cci_seg31_num1,
                cci_seg31_stat1, cci_seg31_typ2, cci_seg31_num2,
                cci_seg31_stat2, cci_seg31_typ3, cci_seg31_num3,
                cci_seg31_stat3, cci_seg31_typ4, cci_seg31_num4,
                cci_seg31_stat4, cci_seg31_typ5, cci_seg31_num5,
                cci_seg31_stat5, cci_seg31_typ6, cci_seg31_num6,
                cci_seg31_stat6, cci_seg31_typ7, cci_seg31_num7,
                cci_seg31_stat7, cci_seg31_typ8, cci_seg31_num8,
                cci_seg31_stat8, cci_seg31_typ9, cci_seg31_num9,
                cci_seg31_stat9
           INTO v_cci_seg31_acct_cnt, v_cci_seg31_typ, v_cci_seg31_num,
                v_cci_seg31_stat, v_cci_seg31_typ1, v_cci_seg31_num1,
                v_cci_seg31_stat1, v_cci_seg31_typ2, v_cci_seg31_num2,
                v_cci_seg31_stat2, v_cci_seg31_typ3, v_cci_seg31_num3,
                v_cci_seg31_stat3, v_cci_seg31_typ4, v_cci_seg31_num4,
                v_cci_seg31_stat4, v_cci_seg31_typ5, v_cci_seg31_num5,
                v_cci_seg31_stat5, v_cci_seg31_typ6, v_cci_seg31_num6,
                v_cci_seg31_stat6, v_cci_seg31_typ7, v_cci_seg31_num7,
                v_cci_seg31_stat7, v_cci_seg31_typ8, v_cci_seg31_num8,
                v_cci_seg31_stat8, v_cci_seg31_typ9, v_cci_seg31_num9,
                v_cci_seg31_stat9
           FROM cms_caf_info_temp
          WHERE cci_file_name = filename AND cci_row_id = frowid;
         SELECT cat_type_code
           INTO v_cat_type_code
           FROM cms_acct_type
          WHERE cat_inst_code = instcode AND cat_switch_type = v_cci_seg31_typ;
         SELECT cas_stat_code
           INTO v_cas_stat_code
           FROM cms_acct_stat
          WHERE cas_inst_code = instcode
            AND cas_switch_statcode = v_cci_seg31_stat;
         sp_create_acct (instcode,
                         v_cci_seg31_num,
                         1,
                         branch,
                         addr,
                         v_cat_type_code,
                         v_cas_stat_code,
                         lupduser,
                         acctid,
                         lperr
                        );
         IF lperr != 'OK'
         THEN
            IF lperr = 'Account No already in Master.'
            THEN
               BEGIN                                                 -- check
                  SELECT DISTINCT 1
                             INTO dum1
                             FROM cms_pan_acct, cms_appl_pan
                            WHERE cpa_inst_code = instcode
                              AND cpa_acct_id = acctid
                              AND cap_pan_code = cpa_pan_code
                              AND cap_mbr_numb = cpa_mbr_numb
                              AND cap_card_stat = '1';
                  lperr := 'OK';
                  dupflag := 'D';
               EXCEPTION
                  WHEN NO_DATA_FOUND
                  THEN
                     BEGIN                                       -- dup begin
                        dup_check :=
                           fn_dup_appl_check (TRIM (v_cci_seg31_num),
                                              instcode
                                             );
                        IF dup_check = 'T'
                        THEN
                           dupflag := 'D';
                        ELSE
                           dupflag := 'A';
                        END IF;
                     END;                                  -- end of dup begin
                     lperr := 'OK';
               END;                                            -- end of check
               UPDATE cms_acct_mast
                  SET cam_hold_count = cam_hold_count + 1,
                      cam_lupd_user = lupduser
                WHERE cam_inst_code = instcode
                  AND cam_acct_no = v_cci_seg31_num;
            ELSE
               lperr :=
                     'From sp_create_acct '
                  || lperr
                  || ' for file '
                  || filename
                  || ' and row id '
                  || frowid;
            END IF;
         END IF;
         --now attach the account to the customer(create holder)
         IF lperr = 'OK'
         THEN
            sp_create_holder (instcode,
                              cust,
                              acctid,
                              NULL,
                              lupduser,
                              holdposn,
                              lperr
                             );
            IF errmsg != 'OK'
            THEN
               errmsg :=
                     'From sp_create_holder '
                  || lperr
                  || ' for file '
                  || filename
                  || ' and row id '
                  || frowid;
            END IF;
         END IF;
      EXCEPTION                                                     --excp lp1
         WHEN OTHERS
         THEN
            lperr := 'Excp Lp1 -- ' || SQLERRM;
      END;                                                           --end lp1
   EXCEPTION                                         --main excp of local proc
      WHEN OTHERS
      THEN
         lperr := 'Local Excp -- ' || SQLERRM;
   END;                                               --end main of local proc
--********************************end local procedure********************************
BEGIN                                                 --MAIN BEGIN starts here
   errmsg := 'OK';
   BEGIN                                 --begin 1 encloses the loops 1 and 2
      FOR x IN c1                                      --loop 1 for cursor c1
	  LOOP
	      --Sn insert a record in summary table
	      BEGIN
	         INSERT INTO cms_upload_summary
	              VALUES (instcode, x.cuc_file_name, 0, 0, 0, lupduser,
	                      SYSDATE, lupduser, SYSDATE,filerectype);
	      EXCEPTION
	         WHEN DUP_VAL_ON_INDEX
	         THEN
	            errmsg :=
	                  'Duplicate record found file '
	               || x.cuc_file_name
	               || ' already processed ';
	            RAISE exp_reject_file;
	         WHEN OTHERS
	         THEN
	            errmsg :=
	                  'Error while creating a record in summary table '
	               || SUBSTR (SQLERRM, 1, 200);
	            RAISE exp_reject_file;
	      END;
		 BEGIN
					         FOR y IN c2 (x.cuc_file_name)                   --loop 2 for cursor 2
					         LOOP
					            BEGIN
								   --Sn assign null to generic variable
							 	   v_cust_data.delete;
							 	   --En assign null to generic variable	 
					               v_savepoint := v_savepoint + 1;
					               SAVEPOINT v_savepoint;
					               BEGIN
					                  SELECT ccm_cust_code
					                    INTO cust
					                    FROM cms_cust_mast
					                   WHERE ccm_inst_code = instcode
					                     AND ccm_cust_id = y.cci_cust_id;
					                  /*IF SQL%FOUND
					                  THEN
					                     errmsg := 'Custome Code is already present in master ';
					                     RAISE exp_reject_record;
					                  END IF;*/
										  BEGIN 
											SELECT CAM_ADDR_CODE INTO v_comm_addrcode FROM CMS_ADDR_MAST
											 WHERE CAM_INST_CODE =instcode
											 AND CAM_CUST_CODE = cust
											 AND CAM_ADDR_FLAG = 'P';
											EXCEPTION
											WHEN NO_DATA_FOUND THEN
											 errmsg :=
								                     'No Data found while selecting Addr code '
								                  || SUBSTR (SQLERRM, 1, 200);
												 RAISE exp_reject_record;
											WHEN TOO_MANY_ROWS THEN
											 errmsg :=
								                     'Multiplal Rows found while selecting Addr code '
								                  || SUBSTR (SQLERRM, 1, 200);
												 RAISE exp_reject_record;
											WHEN OTHERS THEN
											 errmsg :=
								                     'Error while selecting Addr code  '
								                  || SUBSTR (SQLERRM, 1, 200);
												 RAISE exp_reject_record;
										  END;
					               EXCEPTION
					                  WHEN NO_DATA_FOUND
					                  THEN
					                     --Sn create customer
					                     BEGIN
					                        SELECT DECODE (UPPER (y.cci_seg12_cardholder_title),
					                                       'MR.', 'M',
					                                       'MRS.', 'F',
					                                       'MISS.', 'F'
					                                      )
					                          INTO v_gender
					                          FROM DUAL;
											  --Sn assign records to customer gen variable
											   SELECT   y.cci_custappl_param1, 
														y.cci_custappl_param2, 
														y.cci_custappl_param3, 
														y.cci_custappl_param4, 
														y.cci_custappl_param5, 
														y.cci_custappl_param6, 
														y.cci_custappl_param7, 
														y.cci_custappl_param8, 
														y.cci_custappl_param9, 
														y.cci_custappl_param10 
											  INTO		
											  			v_cust_data(1),
														v_cust_data(2),
											  			v_cust_data(3),
											  			v_cust_data(4),
														v_cust_data(5),
											  			v_cust_data(6),
											  			v_cust_data(7),
														v_cust_data(8),
														v_cust_data(9),
														v_cust_data(10)
											 from dual;
											  --En assign records to customer gen variable
					                        sp_create_cust (instcode,
					                                        1,
					                                        0,
					                                        'Y',
					                                        y.cci_seg12_cardholder_title,
					                                        y.cci_seg12_name_line1,
					                                        NULL,
					                                        ' ',
					                                        y.cci_birth_date,
					                                        v_gender,
					                                        NULL,
					                                        NULL,
					                                        NULL,
					                                        NULL,
					                                        NULL,
					                                        NULL,
					                                        lupduser,
					                                        y.cci_ssn,
					                                        y.cci_mother_name,
					                                        y.cci_hobbies,
					                                        NULL,
															'D',
															y.cci_cust_id,
															v_cust_data,
					                                        cust,
					                                        errmsg
					                                       );
					                        IF errmsg <> 'OK'
					                        THEN
					                           errmsg := 'Error from create cutomer ' || errmsg;
					                           RAISE exp_reject_record;
					                        END IF;
					                     EXCEPTION
					                        WHEN exp_reject_record
					                        THEN
					                           RAISE;
					                        WHEN OTHERS
					                        THEN
					                           errmsg :=
					                                 'Error while create customer '
					                              || SUBSTR (SQLERRM, 1, 200);
					                           RAISE exp_reject_record;
					                     END;
					                     --En create customer
					                     --Sn create communication address
					                     SELECT DECODE (y.cci_comm_type,
					                                    '0', y.cci_seg12_addr_line1,
					                                    y.cci_seg13_addr_line1
					                                   ),
					                            DECODE (y.cci_comm_type,
					                                    '0', y.cci_seg12_addr_line2,
					                                    y.cci_seg13_addr_line2
					                                   ),
					                            DECODE (y.cci_comm_type,
					                                    '0', y.cci_seg12_postal_code,
					                                    y.cci_seg13_homephone_no
					                                   ),
					                            DECODE (y.cci_comm_type,
					                                    '0', y.cci_seg12_homephone_no,
					                                    y.cci_seg13_homephone_no
					                                   ),
					                            DECODE (y.cci_comm_type,
					                                    '0', y.cci_seg12_mobileno,
					                                    y.cci_seg13_mobileno
					                                   ),
					                            DECODE (y.cci_comm_type,
					                                    '0', y.cci_seg12_emailid,
					                                    y.cci_seg13_emailid
					                                   ),
					                            DECODE (y.cci_comm_type,
					                                    '0', y.cci_seg12_city,
					                                    y.cci_seg13_city
					                                   ),
					                            DECODE (y.cci_comm_type,
					                                    '0', y.cci_seg12_state,
					                                    y.cci_seg13_state
					                                   ),
												--Sn assign other gen comm adddress
												 DECODE (y.cci_comm_type,
					                                    '0', y.cci_seg12_addr_param1,
					                                    y.cci_seg13_addr_param1
					                                   ),
												  DECODE (y.cci_comm_type,
					                                    '0', y.cci_seg12_addr_param2,
					                                    y.cci_seg13_addr_param2
					                                   ),
												  DECODE (y.cci_comm_type,
					                                    '0', y.cci_seg12_addr_param3,
					                                    y.cci_seg13_addr_param3
					                                   ),
												  DECODE (y.cci_comm_type,
					                                    '0', y.cci_seg12_addr_param4,
					                                    y.cci_seg13_addr_param4
					                                   ),
												  DECODE (y.cci_comm_type,
					                                    '0', y.cci_seg12_addr_param5,
					                                    y.cci_seg13_addr_param5
					                                   ),
												  DECODE (y.cci_comm_type,
					                                    '0', y.cci_seg12_addr_param6,
					                                    y.cci_seg13_addr_param6
					                                   ),
												  DECODE (y.cci_comm_type,
					                                    '0', y.cci_seg12_addr_param7,
					                                    y.cci_seg13_addr_param7
					                                   ),
												  DECODE (y.cci_comm_type,
					                                    '0', y.cci_seg12_addr_param8,
					                                    y.cci_seg13_addr_param8
					                                   ),
												  DECODE (y.cci_comm_type,
					                                    '0', y.cci_seg12_addr_param9,
					                                    y.cci_seg13_addr_param9
					                                   ),
												  DECODE (y.cci_comm_type,
					                                    '0', y.cci_seg12_addr_param10,
					                                    y.cci_seg13_addr_param10
					                                   ), 
												--En assign other gen comm address
					                            DECODE (y.cci_comm_type,
					                                    '0', y.cci_seg13_addr_line1,
					                                    y.cci_seg12_addr_line1
					                                   ),
					                            DECODE (y.cci_comm_type,
					                                    '0', y.cci_seg13_addr_line2,
					                                    y.cci_seg12_addr_line2
					                                   ),
					                            DECODE (y.cci_comm_type,
					                                    '0', y.cci_seg13_postal_code,
					                                    y.cci_seg12_postal_code
					                                   ),
					                            DECODE (y.cci_comm_type,
					                                    '0', y.cci_seg13_homephone_no,
					                                    y.cci_seg12_homephone_no
					                                   ),
					                            DECODE (y.cci_comm_type,
					                                    '0', y.cci_seg13_mobileno,
					                                    y.cci_seg12_mobileno
					                                   ),
					                            DECODE (y.cci_comm_type,
					                                    '0', y.cci_seg13_emailid,
					                                    y.cci_seg12_emailid
					                                   ),
					                            DECODE (y.cci_comm_type,
					                                    '0', y.cci_seg13_city,
					                                    y.cci_seg12_city
					                                   ),
					                            DECODE (y.cci_comm_type,
					                                    '0', y.cci_seg13_state,
					                                    y.cci_seg12_state
					                                   ),
												--Sn assign other gen comm adddress
												 DECODE (y.cci_comm_type,
					                                    '0', y.cci_seg13_addr_param1,
					                                    y.cci_seg12_addr_param1
					                                   ),
												  DECODE (y.cci_comm_type,
					                                    '0', y.cci_seg13_addr_param2,
					                                    y.cci_seg12_addr_param2
					                                   ),
												  DECODE (y.cci_comm_type,
					                                    '0', y.cci_seg13_addr_param3,
					                                    y.cci_seg12_addr_param3
					                                   ),
												  DECODE (y.cci_comm_type,
					                                    '0', y.cci_seg13_addr_param4,
					                                    y.cci_seg12_addr_param4
					                                   ),
												  DECODE (y.cci_comm_type,
					                                    '0', y.cci_seg13_addr_param5,
					                                    y.cci_seg12_addr_param5
					                                   ),
												  DECODE (y.cci_comm_type,
					                                    '0', y.cci_seg13_addr_param6,
					                                    y.cci_seg12_addr_param6
					                                   ),
												  DECODE (y.cci_comm_type,
					                                    '0', y.cci_seg13_addr_param7,
					                                    y.cci_seg12_addr_param7
					                                   ),
												  DECODE (y.cci_comm_type,
					                                    '0', y.cci_seg13_addr_param8,
					                                    y.cci_seg12_addr_param8
					                                   ),
												  DECODE (y.cci_comm_type,
					                                    '0', y.cci_seg13_addr_param9,
					                                    y.cci_seg12_addr_param9
					                                   ),
												  DECODE (y.cci_comm_type,
					                                    '0', y.cci_seg13_addr_param10,
					                                    y.cci_seg12_addr_param10
					                                   )
												--En assign other gen comm address
					                       INTO v_comm_addr_lin1,
					                            v_comm_addr_lin2,
					                            v_comm_postal_code,
					                            v_comm_homephone_no,
					                            v_comm_mobileno,
					                            v_comm_emailid,
					                            v_comm_city,
					                            v_comm_state,
												v_addr_data1(1),
												v_addr_data1(2),
												v_addr_data1(3),
												v_addr_data1(4),
												v_addr_data1(5),
												v_addr_data1(6),
												v_addr_data1(7),
												v_addr_data1(8),
												v_addr_data1(9),
												v_addr_data1(10),
					                            v_other_addr_lin1,
					                            v_other_addr_lin2,
					                            v_other_postal_code,
					                            v_other_homephone_no,
					                            v_other_mobileno,
					                            v_other_emailid,
					                            v_other_city,
					                            v_other_state,
												v_addr_data2(1),
												v_addr_data2(2),
												v_addr_data2(3),
												v_addr_data2(4),
												v_addr_data2(5),
												v_addr_data2(6),
												v_addr_data2(7),
												v_addr_data2(8),
												v_addr_data2(9),
												v_addr_data2(10)
					                       FROM DUAL;
					                     --Sn create communication address
					                     IF v_comm_addr_lin1 IS NOT NULL
					                     THEN
										  IF v_comm_addr_lin1 = y.cci_seg12_addr_line1 
										  THEN
											 	v_comm_type := 'R';
										  ELSIF v_comm_addr_lin1 = y.cci_seg13_addr_line1 
										  THEN
									  			v_comm_type := 'O';
										  END IF;
					                        BEGIN
					                           SELECT gcm_cntry_code
					                             INTO v_gcm_cntry_code
					                             FROM gen_cntry_mast
					                            WHERE gcm_curr_code = y.cci_seg12_country_code;
					                           sp_create_addr (instcode,
					                                           cust,
					                                           v_comm_addr_lin1,
					                                           v_comm_addr_lin2,
					                                           y.cci_seg12_name_line2,
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
					                                           lupduser,
															   v_addr_data1,
					                                           v_comm_addrcode,
					                                           errmsg
					                                          );
					                           IF errmsg <> 'OK'
					                           THEN
					                              errmsg :=
					                                    'Error from create communication address '
					                                 || errmsg;
					                              RAISE exp_reject_record;
					                           END IF;
					                        EXCEPTION
					                           WHEN exp_reject_record
					                           THEN
					                              RAISE;
					                           WHEN OTHERS
					                           THEN
					                              errmsg :=
					                                    'Error while create communication address '
					                                 || SUBSTR (SQLERRM, 1, 200);
					                              RAISE exp_reject_record;
					                        END;
					                     END IF;
					                     --En create communication address
					                     --Sn create other address
					                     IF v_other_addr_lin1 IS NOT NULL
					                     THEN
										  IF v_comm_addr_lin1 = y.cci_seg12_addr_line1 
							  THEN
								 	v_comm_type := 'R';
							  ELSIF v_comm_addr_lin1 = y.cci_seg13_addr_line1 
							  THEN
						  			v_comm_type := 'O';
							  END IF;
					                        BEGIN
					                           SELECT gcm_cntry_code
					                             INTO v_gcm_othercntry_code
					                             FROM gen_cntry_mast
					                            WHERE gcm_curr_code = y.cci_seg13_country_code;
					                           sp_create_addr (instcode,
					                                           cust,
					                                           v_other_addr_lin1,
					                                           v_other_addr_lin2,
					                                           y.cci_seg12_name_line2,
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
					                                           lupduser,
															   v_addr_data2,
					                                           v_other_addrcode,
					                                           errmsg
					                                          );
					                           IF errmsg <> 'OK'
					                           THEN
					                              errmsg :=
					                                    'Error from create communication address '
					                                 || errmsg;
					                              RAISE exp_reject_record;
					                           END IF;
					                        EXCEPTION
					                           WHEN exp_reject_record
					                           THEN
					                              RAISE;
					                           WHEN OTHERS
					                           THEN
					                              errmsg :=
					                                    'Error while create communication address '
					                                 || SUBSTR (SQLERRM, 1, 200);
					                              RAISE exp_reject_record;
					                        END;
					                     END IF;
					                  --En create other address
					                  WHEN exp_reject_record THEN
									  	   errmsg :=
					                           'Error while selecting customer from master '
					                        || SUBSTR (SQLERRM, 1, 200);
					                     RAISE;
									  WHEN OTHERS
					                  THEN
					                     errmsg :=
					                           'Error while selecting customer from master '
					                        || SUBSTR (SQLERRM, 1, 200);
					                     RAISE exp_reject_record;
					               END;
					--************************************************************************************************************
					                                                           --account part
					               BEGIN                                               --begin 1.3
					                  IF v_comm_addrcode IS NOT NULL
					                  THEN
					                     addrcode := v_comm_addrcode;
					                  ELSIF v_other_addrcode IS NOT NULL
					                  THEN
					                     addrcode := v_other_addrcode;
					                  END IF;
					                  lp_acct_part (cust,
					                                addrcode,
					                                x.cuc_file_name,
					                                y.cci_row_id,
					                                y.cci_fiid,
					                                acctid,
					                                errmsg
					                               );
					                  IF errmsg != 'OK'
					                  THEN
					                     errmsg :=
					                           'From lp_acct_part '
					                        || errmsg
					                        || ' for file '
					                        || x.cuc_file_name
					                        || ' and row id '
					                        || y.cci_row_id;
					                     RAISE exp_reject_record;
					                  END IF;
					               EXCEPTION
					                  WHEN exp_reject_record
					                  THEN
					                     errmsg :=
					                           'Excp 1.3 -- '
					                        || SQLERRM
					                        || ' for file '
					                        || x.cuc_file_name
					                        || ' and row id '
					                        || y.cci_row_id;
					                     RAISE;                                         --excp 1.3
					                  WHEN OTHERS
					                  THEN
					                     errmsg :=
					                           'Excp 1.3 -- '
					                        || SQLERRM
					                        || ' for file '
					                        || x.cuc_file_name
					                        || ' and row id '
					                        || y.cci_row_id;
					                     RAISE exp_reject_record;
					               END;                                            --end begin 1.3
					               BEGIN                                               --begin 1.4
					                  SELECT cpm_interchange_code
					                    INTO v_cpm_interchange_code
					                    FROM cms_prodtype_map
					                   WHERE cpm_inst_code = instcode
					                     AND cpm_prod_b24 = TRIM (y.cci_crd_typ);
					               EXCEPTION
					                  WHEN NO_DATA_FOUND
					                  THEN
									  errmsg := 'No Interchange code found for the card type';
					                     RAISE exp_reject_record;
					                  WHEN OTHERS
					                  THEN
									   errmsg := 'No Interchange code found for the card type';
					                     RAISE exp_reject_record;
					               END;
					               BEGIN
					                  SELECT cpb_prod_code
					                    INTO v_cpb_prod_code
					                    FROM cms_prod_bin
					                   WHERE cpb_inst_code = instcode
					                     AND cpb_inst_bin = y.cci_pan_code
					                     AND cpb_interchange_code = v_cpm_interchange_code
					                     AND cpb_active_bin = 'Y';
					               EXCEPTION
					                  WHEN NO_DATA_FOUND
					                  THEN
									  errmsg := 'No prod code found for the interchange type';
					                     RAISE exp_reject_record;
					                  WHEN OTHERS
					                  THEN
									  errmsg := 'No prod code found for the interchange type';
					                     RAISE exp_reject_record;
					               END;
					               BEGIN
					                  SELECT cpc_card_type
					                    INTO v_card_type
					                    FROM cms_prod_cattype
					                   WHERE cpc_inst_code = instcode
					                     AND cpc_prod_code = v_cpb_prod_code
					                     AND cpc_cardtype_sname = y.cci_card_type;
					               EXCEPTION
					                  WHEN NO_DATA_FOUND
					                  THEN
					                     errmsg :=
					                           'Product code'
					                        || v_cpb_prod_code
					                        || 'is not attached to cattype'
					                        || y.cci_card_type;
					                     RAISE exp_reject_record;
					                  WHEN OTHERS
					                  THEN
					                     errmsg :=
					                           'Error while selecting product cattype '
					                        || SUBSTR (SQLERRM, 1, 200);
					                     RAISE exp_reject_record;
					               END;
					               IF    y.cci_seg12_branch_num = '*'
					                  OR y.cci_seg12_branch_num IS NULL
					               THEN
					                  v_ccc_catg_code := 1;           --default customer category
					               ELSE
					                  BEGIN
					                     SELECT ccc_catg_code
					                       INTO v_ccc_catg_code
					                       FROM cms_cust_catg
					                      WHERE ccc_inst_code = instcode
					                        AND ccc_catg_sname = y.cci_seg12_branch_num;
					                  EXCEPTION
					                     WHEN NO_DATA_FOUND
					                     THEN
										 v_ccc_catg_code := 1; 
										 --errmsg := 'No cust catg code found';
					                        --RAISE exp_reject_record;
					                     WHEN OTHERS
					                     THEN
										 v_ccc_catg_code := 1; 
										  ---errmsg := 'No cust catg code found ';
					                        --RAISE exp_reject_record;
					                  END;
					               END IF;
					               BEGIN
					                  SELECT cpm_validity_period
					                    INTO expry_param
					                    FROM cms_prod_mast
					                   WHERE cpm_inst_code = instcode
					                     AND cpm_prod_code = v_cpb_prod_code;
					               EXCEPTION
					                  WHEN NO_DATA_FOUND
					                  THEN
					                     expry_param := 120;
					               END;
					               BEGIN
					                  sp_create_appl (instcode,
					                                  1,
					                                  1,
					                                  NULL,
					                                  SYSDATE,
					                                  SYSDATE,
					                                  cust,
					                                  y.cci_fiid,
					                                  v_cpb_prod_code,
					                                  v_card_type,
					                                  v_ccc_catg_code,         --customer category
					                                  SYSDATE,
					                                  LAST_DAY (ADD_MONTHS (SYSDATE,
					                                                        expry_param - 1
					                                                       )
					                                           ),
					                                  SUBSTR (y.cci_seg12_name_line1, 1, 30),
					                                  0,
					                                  'N',
					                                  NULL,
					                                  1,
					                                  'P',
					                                  0,
					                                  addrcode,                  --billing address
					                                  NULL,                         --channel code
					                                  NULL,
					                                  NULL,
					                                  lupduser,
					                                  lupduser,
					                                  NULL,
					                                  applcode,                        --out param
					                                  errmsg
					                                 );
					                  IF errmsg != 'OK'
					                  THEN
					                     errmsg :=
					                           'From sp_create_appl '
					                        || errmsg
					                        || ' for file '
					                        || x.cuc_file_name
					                        || ' and row id '
					                        || y.cci_row_id;
					                     RAISE exp_reject_record;
					                  END IF;
					               EXCEPTION
					                  WHEN exp_reject_record
					                  THEN
					                     errmsg :=
					                           'From sp_create_appl '
					                        || errmsg
					                        || ' for file '
					                        || x.cuc_file_name
					                        || ' and row id '
					                        || y.cci_row_id;
					                     RAISE;
					                  WHEN OTHERS
					                  THEN
					                     errmsg :=
					                           'From sp_create_appl '
					                        || errmsg
					                        || ' for file '
					                        || x.cuc_file_name
					                        || ' and row id '
					                        || y.cci_row_id;
					                     RAISE exp_reject_record;
					               END;
					               --call the procedure which creates appldets
					               BEGIN
					                  sp_create_appldet (instcode,
					                                     applcode,
					                                     acctid,
					                                     1,
					                                     lupduser,
					                                     errmsg
					                                    );
					                  IF errmsg != 'OK'
					                  THEN
					                     errmsg :=
					                           'From sp_create_appldet '
					                        || errmsg
					                        || ' for file '
					                        || x.cuc_file_name
					                        || ' and row id '
					                        || y.cci_row_id;
					                     RAISE exp_reject_record;
					                  ELSIF errmsg = 'OK'
					                  THEN
					                     UPDATE cms_appl_mast
					                        SET cam_appl_stat = dupflag
					                      WHERE cam_inst_code = instcode
					                        AND cam_appl_code = applcode;
					                  END IF;
					               EXCEPTION
					                  WHEN exp_reject_record
					                  THEN
					                     errmsg :=
					                           'Excp 1.4 -- '
					                        || SQLERRM
					                        || ' for file '
					                        || x.cuc_file_name
					                        || ' and row id '
					                        || y.cci_row_id;
					                     RAISE;
					                  WHEN OTHERS
					                  THEN
					                     errmsg :=
					                           'Excp 1.4 -- '
					                        || SQLERRM
					                        || ' for file '
					                        || x.cuc_file_name
					                        || ' and row id '
					                        || y.cci_row_id;
					                     RAISE exp_reject_record;
					               END;                                                  --end 1.4
					               IF errmsg = 'OK'
					               THEN
					                  UPDATE cms_caf_info_temp
					                     SET cci_upld_stat = 'O',
					                         cci_approved = 'O',
					                         cci_process_msg = 'SUCCESSFUL'
					                   WHERE cci_file_name = x.cuc_file_name
					                     AND cci_row_id = y.cci_row_id;
										UPDATE cms_upload_summary
                    				    SET PUC_SUCCESS_RECORDS = PUC_SUCCESS_RECORDS+1,
										puc_tot_records = puc_tot_records + 1
                   						WHERE puc_file_name = x.cuc_file_name
										AND PUC_FILE_TYPE = filerectype;
					               END IF;
					            EXCEPTION
					               WHEN exp_reject_record
					               THEN
					                  ROLLBACK TO v_savepoint;
					                  UPDATE cms_caf_info_temp
					                     SET cci_upld_stat = 'E',
					                         cci_process_msg = errmsg
					                   WHERE cci_file_name = x.cuc_file_name
					                     AND cci_row_id = y.cci_row_id;
									  UPDATE cms_upload_summary
                    				    SET puc_error_records = puc_error_records + 1,
                         					puc_tot_records = puc_tot_records + 1
                   						WHERE puc_file_name = x.cuc_file_name
										AND PUC_FILE_TYPE = filerectype;
					                  INSERT INTO cms_error_log
					                              (cel_inst_code, cel_file_name, cel_row_id,
					                               cel_error_mesg, cel_lupd_user, cel_lupd_date,
					                               cel_prob_action
					                              )
					                       VALUES (instcode, x.cuc_file_name, y.cci_row_id,
					                               errmsg, lupduser, SYSDATE,
					                               'Contact Site Administrator'
					                              );
					               WHEN OTHERS
					               THEN
					                  ROLLBACK TO v_savepoint;
					                  UPDATE cms_caf_info_temp
					                     SET cci_upld_stat = 'E',
					                         cci_process_msg = errmsg
					                   WHERE cci_file_name = x.cuc_file_name;
									   UPDATE cms_upload_summary
                    				    SET puc_error_records = puc_error_records + 1,
                         					puc_tot_records = puc_tot_records + 1
                   						WHERE puc_file_name = x.cuc_file_name
										AND PUC_FILE_TYPE = filerectype;
					                   INSERT INTO cms_error_log
					                              (cel_inst_code, cel_file_name, cel_row_id,
					                               cel_error_mesg, cel_lupd_user, cel_lupd_date,
					                               cel_prob_action
					                              )
					                       VALUES (instcode, x.cuc_file_name, y.cci_row_id,
					                               errmsg, lupduser, SYSDATE,
					                               'Contact Site Administrator'
					                              );
					            END;
         END LOOP;
		 EXCEPTION                            --<< EXCEPTION LOOP C1(FILE WISE)>>
         WHEN exp_reject_file
         THEN
            RAISE;
         WHEN OTHERS
         THEN
            errmsg :=
                   'Error while processing file ' || SUBSTR (SQLERRM, 1, 200);
            RAISE exp_reject_file;
      	END;     
        IF errmsg = 'OK'
         THEN
            UPDATE cms_upload_ctrl
               SET cuc_upld_stat = 'O'
             WHERE cuc_file_name = x.cuc_file_name;
        END IF;
      END LOOP;
	  errmsg := 'OK';
   EXCEPTION
      WHEN exp_reject_file
      THEN
         errmsg := ' Excp 1 -- ' || SQLERRM || ' ' || errmsg;
      WHEN OTHERS
      THEN
         errmsg := 'Excp 1 -- ' || SQLERRM;
   END;                                                          --end begin 1
EXCEPTION
   WHEN OTHERS
   THEN
      errmsg := 'Main Excp -- ' || SQLERRM;
END;                                                                --end main
/


