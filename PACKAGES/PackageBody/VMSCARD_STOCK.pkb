create or replace
PACKAGE BODY       VMSCMS.VMSCARD_STOCK
IS
   -- Private type declarations

   -- Private constant declarations
   l_const         NUMBER := 1;
   l_mbr_numb      VARCHAR2 (5) := '000';

   -- Private variable declarations

   -- Function and procedure implementations
   PROCEDURE stock_issuance_process (p_instcode_in           NUMBER,
                                     p_filename_in           VARCHAR2,
                                     p_prodcode_in           VARCHAR2,
                                     p_cardtype_in           VARCHAR2,
                                     p_merid_in              VARCHAR2,
                                     p_locationid_in         VARCHAR2,
                                     p_merprodcatid_in       VARCHAR2,
                                     P_Quantity_In           Number,
                                     P_Cust_Catg             Varchar2,
                                     p_usercode_in           NUMBER,
                                     p_errmsg_out        OUT VARCHAR2,
                                     p_respdtls_out      OUT VARCHAR2)
   AS

/*************************************************     
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
     
     * Modified By      : Shanmugavel
     * Modified Date    : 23/01/2024
     * Purpose          : VMS-8219-Remove the Default Status in the Product Category Profile Screen on the Host UI
     * Reviewer         : Venkat/John/Pankaj
     * Release Number   : VMSGPRHOSTR92

*************************************************/    
   
      CURSOR cur_cards (
         prodcode   IN VARCHAR2,
         prodcatg   IN NUMBER,
	 fromseq    IN NUMBER,
         toseq      IN NUMBER)
      IS
         SELECT cap_appl_code,
            to_char(cap_appl_code) applcode,
                cap_prod_code,
                cap_prod_catg,
                cap_card_type,
                cap_cust_catg,
                cap_pan_code,
                cap_cust_code,
                cap_acct_id,
                cap_acct_no,
                cap_bill_addr,
                cap_pan_code_encr,
                cap_mask_pan,
                cap_appl_bran
          FROM cms_appl_pan_inv
           WHERE cap_prod_code = prodcode
                 AND cap_card_type = prodcatg
                 AND cap_issue_stat = 'N'
                 AND cap_card_seq  BETWEEN fromseq AND toseq;	
				 /*IN
			  (SELECT cap_card_seq
			  FROM
			    (SELECT a.cap_card_seq
			    FROM cms_appl_pan_inv a
			    WHERE a.cap_prod_code= prodcode
			    AND a.cap_card_type  = prodcatg
			    AND a.cap_issue_stat ='N'
				AND ROWNUM <= quantity + 10000 
			    ORDER BY dbms_random.value
			    )
			  WHERE ROWNUM <= quantity
			  ) FOR UPDATE;*/

	---Modified for VMS-1084 (Pan genaration process from sequential to shuffled - B2B & Retail)			  

      TYPE t_cards IS TABLE OF cur_cards%ROWTYPE;

      l_cards          t_cards;
      l_profile_code   cms_prod_cattype.cpc_profile_code%TYPE;
      l_display_name   cms_prod_cattype.cpc_startercard_dispname%TYPE;
      l_card_stat      cms_appl_pan.cap_card_stat%TYPE;
      l_expry_date     cms_appl_pan.cap_expry_date%TYPE;
      l_hsm_mode       VARCHAR2 (1);
      l_pingen_flag    VARCHAR2 (1);
      l_emboss_flag    VARCHAR2 (1);
      l_err_cnt        NUMBER := 0;
      l_errmsg         VARCHAR2 (1000);
      l_err_index      NUMBER;
	  l_start_control_number VMS_INVENTORY_CONTROL.VIC_CONTROL_NUMBER%TYPE;
	  l_end_control_number VMS_INVENTORY_CONTROL.VIC_CONTROL_NUMBER%TYPE;
      excp_bulk_dml    EXCEPTION;
      PRAGMA EXCEPTION_INIT (excp_bulk_dml, -24381);
      excp_process     EXCEPTION;
      excp_error       EXCEPTION;
   BEGIN
      P_Errmsg_Out := 'OK';

      BEGIN
         SELECT cpc_profile_code,
                NVL (cpc_startercard_dispname, 'INSTANT CARD')
           INTO l_profile_code, l_display_name
           FROM cms_prod_cattype
          WHERE     cpc_inst_code = cpc_inst_code
                AND cpc_prod_code = p_prodcode_in
                AND cpc_card_type = p_cardtype_in;
      EXCEPTION
         WHEN OTHERS
         THEN
            p_errmsg_out :=
               'Error while selecting product dtls:'
               || SUBSTR (SQLERRM, 1, 200);
            RETURN;
      END;

l_card_stat := '0';  -- VMS-8219
--      BEGIN
--         SELECT cbp_param_value
--           INTO l_card_stat
--           FROM cms_bin_param
--          WHERE     cbp_inst_code = p_instcode_in
--                AND cbp_profile_code = l_profile_code
--                AND cbp_param_name = 'Status';
--
--         IF l_card_stat IS NULL
--         THEN
--            p_errmsg_out :=
--               'Status is null for profile code ' || l_profile_code;
--            RETURN;
--         END IF;
--      EXCEPTION
--         WHEN NO_DATA_FOUND
--         THEN
--            p_errmsg_out :=
--               'Status is not defined for profile code ' || l_profile_code;
--            RETURN;
--         WHEN OTHERS
--         THEN
--            p_errmsg_out :=
--               'Error while selecting card status '
--               || SUBSTR (SQLERRM, 1, 200);
--            RETURN;
--      END;

      BEGIN
         vmsfunutilities.get_expiry_date (p_instcode_in,
                                          p_prodcode_in,
                                          p_cardtype_in,
                                          l_profile_code,
                                          l_expry_date,
                                          p_errmsg_out);

         IF p_errmsg_out <> 'OK'
         THEN
            RETURN;
         END IF;
      EXCEPTION
         WHEN OTHERS
         THEN
            p_errmsg_out :=
               'Error while calling vmsfunutilities.get_expiry_date'
               || SUBSTR (SQLERRM, 1, 200);
            RETURN;
      END;

      BEGIN
         SELECT cip_param_value
           INTO l_hsm_mode
           FROM cms_inst_param
          Where Cip_Param_Key = 'HSM_MODE' And Cip_Inst_Code = P_Instcode_In;
 
         IF l_hsm_mode = 'Y'
         THEN
            l_pingen_flag := 'Y';
            l_emboss_flag := 'Y';
         ELSE
            l_pingen_flag := 'N';
            l_emboss_flag := 'N';
         END IF;
      EXCEPTION
         WHEN OTHERS
         THEN
            l_hsm_mode := 'N';
            l_pingen_flag := 'N';
            l_emboss_flag := 'N';
      END;
	  
      BEGIN
                VMSB2BAPI.get_inventory_control_number(p_prodcode_in,
					     p_cardtype_in,
					     p_quantity_in,
					     l_start_control_number,
                         l_end_control_number,
					     l_errmsg );
                 IF l_errmsg <> 'OK' THEN
                    RAISE excp_error;
                 END IF;
                 
              EXCEPTION
                WHEN excp_error THEN
                    RAISE;
                WHEN OTHERS THEN
                 l_errmsg :=
                        'Error while calling get_inventory_control_number '
                        || SUBSTR (SQLERRM, 1, 200);
                     RAISE excp_process;
      END;

      OPEN cur_cards (p_prodcode_in, p_cardtype_in,l_start_control_number,l_end_control_number);

      LOOP
         L_Errmsg := 'OK';
        
         BEGIN
            FETCH cur_cards
            BULK COLLECT INTO l_cards
            LIMIT 1000;

            Exit When L_Cards.Count = 0;
           
            Begin
             
               Forall I In 1 .. L_Cards.Count Save Exceptions
                         INSERT ALL
                  WHEN 1 = 1
                  THEN
                       INTO cms_appl_pan_temp(cap_appl_code,
                                               cap_inst_code,
                                               cap_asso_code,
                                               cap_inst_type,
                                               cap_prod_code,
                                               cap_prod_catg,
                                               cap_card_type,
                                               cap_cust_catg,
                                               cap_pan_code,
                                               cap_mbr_numb,
                                               cap_card_stat,
                                               cap_cust_code,
                                               cap_disp_name,
                                               --cap_limit_amt,
                                               --cap_use_limit,
                                               cap_appl_bran,
                                               cap_expry_date,
                                               cap_addon_stat,
                                               cap_addon_link,
                                               cap_mbr_link,
                                               cap_acct_id,
                                               cap_acct_no,
                                               cap_tot_acct,
                                               cap_bill_addr,
                                               --cap_chnl_code,
                                               cap_pangen_date,
                                               cap_pangen_user,
                                               cap_cafgen_flag,
                                               cap_pin_flag,
                                               cap_embos_flag,
                                               cap_phy_embos,
                                               cap_join_feecalc,
                                               --cap_request_id,
                                               --cap_issue_flag,
                                               cap_ins_user,
                                               cap_lupd_user,
                                               cap_firsttime_topup,
                                               cap_pan_code_encr,
                                               cap_startercard_flag,
                                               cap_mask_pan,
                                               cap_file_name,
                                               cap_ins_date,
                                               cap_lupd_date)
                     VALUES (l_cards (i).cap_appl_code,
                             p_instcode_in,
                             l_const,
                             l_const,
                             l_cards (i).cap_prod_code,
                             l_cards (i).cap_prod_catg,
                             L_Cards (I).Cap_Card_Type,
                             nvl(l_cards (i).cap_cust_catg,P_Cust_Catg),
                             l_cards (i).cap_pan_code,
                             l_mbr_numb,
                             l_card_stat,
                             l_cards (i).cap_cust_code,
                             l_display_name,
                             --limit_amt,
                             --use_limit,
                             l_cards (i).cap_appl_bran,
                             l_expry_date,
                             'P',
                             l_cards (i).cap_pan_code,
                             l_mbr_numb,
                             l_cards (i).cap_acct_id,
                             l_cards (i).cap_acct_no,
                             l_const,
                             l_cards (i).cap_bill_addr,
                             --chnl_code,
                             SYSDATE,
                             p_usercode_in,
                             'Y',
                             l_pingen_flag,
                             l_emboss_flag,
                             'N',
                             'N',
                             --request_id,
                             --issueflag,
                             p_usercode_in,
                             p_usercode_in,
                             'N',
                             l_cards (i).cap_pan_code_encr,
                             'Y',
                             l_cards (i).cap_mask_pan,
                             p_filename_in,
                             SYSDATE,
                             SYSDATE)
                  WHEN 1 = 1
                  THEN
                       INTO cms_cardissuance_status (ccs_inst_code,
                                                     ccs_pan_code,
                                                     ccs_card_status,
                                                     ccs_ins_user,
                                                     ccs_lupd_user,
                                                     ccs_pan_code_encr,
                                                     ccs_lupd_date,
                                                     ccs_appl_code)
                     VALUES (p_instcode_in,
                             l_cards (i).cap_pan_code,
                             '2',
                             p_usercode_in,
                             p_usercode_in,
                             l_cards (i).cap_pan_code_encr,
                             SYSDATE,
                             l_cards (i).cap_appl_code)
                   WHEN p_merid_in IS NOT NULL
                  THEN
                       INTO cms_merinv_merpan (cmm_inst_code,
                                               cmm_mer_id,
                                               cmm_location_id,
                                               cmm_pancode_encr,
                                               cmm_pan_code,
                                               cmm_activation_flag,
                                               cmm_expiry_date,
                                               cmm_lupd_date,
                                               cmm_lupd_user,
                                               cmm_ins_date,
                                               cmm_ins_user,
                                               cmm_ordr_refrno,
                                               cmm_merprodcat_id,
                                               cmm_appl_code)
                     VALUES (p_instcode_in,
                             p_merid_in,
                             p_locationid_in,
                             l_cards (i).cap_pan_code_encr,
                             l_cards (i).cap_pan_code,
                             'M',
                             l_expry_date,
                             SYSDATE,
                             p_usercode_in,
                             SYSDATE,
                             p_usercode_in,
                             p_filename_in,
                             p_merprodcatid_in,
                             l_cards (i).cap_appl_code)
                     SELECT * FROM DUAL;
            EXCEPTION
               WHEN excp_bulk_dml
               THEN
                  BEGIN
                     l_err_cnt := l_err_cnt + SQL%BULK_EXCEPTIONS.COUNT;

                     FOR i IN 1 .. SQL%BULK_EXCEPTIONS.COUNT
                     LOOP
                        l_err_index := SQL%BULK_EXCEPTIONS (i).ERROR_INDEX;
                        l_errmsg :=
                           Sqlerrm (-Sql%Bulk_Exceptions (I).Error_Code);

                        UPDATE cms_appl_pan_inv
                           SET cap_issue_stat = 'E'
                         WHERE cap_pan_code =
                                  L_Cards (L_Err_Index).Cap_Pan_Code;

                        UPDATE cms_appl_mast
                           SET cam_appl_stat = 'E',
                               cam_file_name = p_filename_in,
                               cam_lupd_user = p_usercode_in,
                               cam_process_msg = l_errmsg
                         WHERE cam_inst_code = p_instcode_in
                               AND cam_appl_code =
                                      l_cards (l_err_index).cap_appl_code;
                     END LOOP;
                  EXCEPTION
                     WHEN OTHERS
                     THEN
                        l_errmsg :=
                           'Error While updating exception cards :'
                           || SUBSTR (SQLERRM, 1, 200);
                        RAISE excp_process;
                  END;

                  l_errmsg := 'OK';
               WHEN OTHERS
               THEN
                  l_errmsg :=
                     'Error While Inserting Cards :'
                     || SUBSTR (SQLERRM, 1, 200);
                  RAISE excp_process;
            END;

            BEGIN
               FORALL i IN 1 .. l_cards.COUNT
                  UPDATE cms_appl_mast
                     SET cam_appl_stat = 'O',
                         cam_file_name = p_filename_in,
                         cam_lupd_user = p_usercode_in,
                         cam_process_msg = 'SUCCESSFUL'
                   WHERE     cam_inst_code = p_instcode_in
                         AND cam_appl_code = l_cards (i).cap_appl_code
                         And Cam_Appl_Stat = 'A';
            EXCEPTION
               WHEN OTHERS
               THEN
                  l_errmsg :=
                     'Error While Updating Appl Stat:'
                     || SUBSTR (SQLERRM, 1, 200);
                  RAISE excp_process;
            END;
            
            BEGIN
               FORALL i IN 1 .. l_cards.COUNT
                  UPDATE Cms_Caf_Info_Entry
                     SET cci_file_name = p_filename_in
                   WHERE Cci_Inst_Code = P_Instcode_In
                         AND cci_appl_code = l_cards (i).applcode;
            EXCEPTION
               WHEN OTHERS
               THEN
                  L_Errmsg :=
                     'Error While Updating cms_caf_info_entry:'
                     || SUBSTR (SQLERRM, 1, 200);
                  RAISE Excp_Process;
            END;

            BEGIN
               FORALL i IN 1 .. l_cards.COUNT
                  UPDATE cms_appl_pan_inv
                     SET cap_issue_stat = 'I'
                   WHERE cap_pan_code = l_cards (i).cap_pan_code
                         AND cap_issue_stat = 'N';
            EXCEPTION
               WHEN OTHERS
               THEN
                  l_errmsg :=
                     'Error While Updating Cards Issue Stat:'
                     || SUBSTR (SQLERRM, 1, 200);
                  RAISE excp_process;
            END;
         EXCEPTION
            WHEN excp_process
            THEN
               ROLLBACK;
               l_err_cnt := l_err_cnt + l_cards.COUNT;
            WHEN OTHERS
            THEN
               l_errmsg := 'Error in loop:' || SUBSTR (SQLERRM, 1, 200);
               ROLLBACK;
               l_err_cnt := l_err_cnt + l_cards.COUNT;
         END;

         IF l_errmsg <> 'OK'
         THEN
            INSERT INTO cms_error_log (cel_inst_code,
                                       cel_file_name,
                                       cel_row_id,
                                       cel_error_mesg,
                                       cel_lupd_user,
                                       cel_lupd_date,
                                       cel_prob_action)
                 VALUES (p_instcode_in,
                         p_filename_in,
                         NULL,
                         l_errmsg,
                         p_usercode_in,
                         SYSDATE,
                         'Error In Bulk Card Process Loop');
						 
				
	--- Added for VMS-2888 - VPS_AVAIL_CARDS Column on VMS_PANGEN_SUMMARY					 
						 
		BEGIN
	
			FORALL i IN 1 .. l_cards.COUNT
					
		UPDATE cms_appl_pan_inv
                     SET cap_issue_stat = 'E'
                   WHERE cap_pan_code = l_cards (i).cap_pan_code
                         AND cap_issue_stat = 'N';

		EXCEPTION
		WHEN OTHERS
		THEN
                  l_errmsg :=
                     'Error While Updating Cards Issue Stat:'
                     || SUBSTR (SQLERRM, 1, 200);                 
		END;		 
		
	--- Ended for VMS-2888 - VPS_AVAIL_CARDS Column on VMS_PANGEN_SUMMARY	
       
  END IF;
    
  
         COMMIT;
      END LOOP;

      CLOSE cur_cards;
      
              --- Added for VMS-2888 - VPS_AVAIL_CARDS Column on VMS_PANGEN_SUMMARY
	    
             BEGIN		
	     
	      --- Modified for VMS-3066 - Product Setup re-Vamp - BIN.

                  /*UPDATE vms_pangen_summary
                    SET vps_avail_cards =  vps_avail_cards - P_Quantity_In       
                WHERE vps_prod_code = p_prodcode_in
                AND vps_card_type =  p_cardtype_in;*/

				VMSB2BAPI.UPDATE_PANGEN_SUMMARY(p_prodcode_in,
					     p_cardtype_in,
					     l_start_control_number,
                         l_end_control_number,
					     l_errmsg );

                COMMIT;
            EXCEPTION
               WHEN OTHERS
               THEN
                  l_errmsg :=
                     'Error While Updating avail cards in pan gen summary:'
                     || SUBSTR (SQLERRM, 1, 200);                  
            END;      
	    
  	    --- Ended change for VMS-2888 - VPS_AVAIL_CARDS Column on VMS_PANGEN_SUMMARY
      

  BEGIN
      Update Vms_Stock_Caf_Info_Temp
                     SET Vsc_Upld_Stat = 'A'
                   Where     Vsc_Inst_Code = P_Instcode_In
                         And Vsc_File_Name = P_Filename_In;
End;

      p_respdtls_out :=
            p_filename_in
         || '~'
         || p_errmsg_out
         || '~'
         || (p_quantity_in - l_err_cnt)
         || '~'
         || l_err_cnt;
   EXCEPTION
      WHEN OTHERS
      THEN
         ROLLBACK;
         p_errmsg_out := 'Main Excp-' || SUBSTR (SQLERRM, 1, 200);
   END stock_issuance_process;

   PROCEDURE merinv_process (p_instcode_in       NUMBER,
                             p_usercode_in       NUMBER,
                             p_raise_in          VARCHAR,
                             p_errmsg_out    OUT VARCHAR2)
   AS
      l_merpan_cnt   NUMBER;
      l_err_cnt      NUMBER;
      l_succ_cnt     NUMBER;
      l_errmsg       VARCHAR2 (1000);
      l_respmsg      VARCHAR2 (1000);
      excp_merinv    EXCEPTION;
   BEGIN
      FOR l_idx
         IN (SELECT cmo_merprodcat_id,
                    cmo_ordr_refrno file_name,
                    cmp_mer_id,
                    cmo_location_id,
                    cmp_prod_code,
                    cmp_prod_cattype,
                    cmo_nocards_ordr,
                    cpc_profile_code,
                    NVL (cpc_startercard_dispname, 'INSTANT CARD')
               FROM cms_merinv_prodcat, cms_merinv_ordr, cms_prod_cattype
              WHERE     cmp_merprodcat_id = cmo_merprodcat_id
                    AND cmo_authorize_flag = 'A'
                    AND cmo_process_flag = 'N'
                    AND cpc_inst_code = cmp_inst_code
                    AND cpc_prod_code = cmp_prod_code
                    AND cpc_card_type = cmp_prod_cattype
                    AND CASE
                           WHEN p_raise_in IS NOT NULL THEN cmo_raise_flag
                           ELSE '1'
                        END = NVL (p_raise_in, '1'))
      LOOP
         l_errmsg := 'OK';
         l_respmsg := NULL;
         l_succ_cnt := 0;
         l_err_cnt := 0;

         BEGIN
            SELECT COUNT (*)
              INTO l_merpan_cnt
              FROM cms_merinv_merpan
             Where Cmm_Ordr_Refrno = L_Idx.File_Name;
 
            IF l_merpan_cnt = 0
            THEN
               BEGIN
                  INSERT INTO cms_summary_merinv
                       VALUES (p_instcode_in,
                               l_idx.file_name,
                               0,
                               0,
                               l_idx.cmo_nocards_ordr,
                               p_usercode_in,
                               SYSDATE,
                               p_usercode_in,
                               SYSDATE,
                               '');
               EXCEPTION
                  WHEN OTHERS
                  THEN
                     l_errmsg :=
                        'Error while creating a record in summary table '
                        || SUBSTR (SQLERRM, 1, 200);
                     RAISE excp_merinv;
               End;

               vmscard_stock.stock_issuance_process (p_instcode_in,
                                                     l_idx.file_name,
                                                     l_idx.cmp_prod_code,
                                                     l_idx.cmp_prod_cattype,
                                                     l_idx.cmp_mer_id,
                                                     l_idx.cmo_location_id,
                                                     l_idx.cmo_merprodcat_id,
                                                     L_Idx.Cmo_Nocards_Ordr,
                                                     Null,
                                                    p_usercode_in,
                                                     L_Errmsg,
                                                     l_respmsg);

               IF l_errmsg <> 'OK'
               THEN
                  RAISE excp_merinv;
               END IF;

               l_err_cnt :=
                  SUBSTR (l_respmsg,
                          INSTR (l_respmsg,
                                 '~',
                                 1,
                                 3)
                          + 1);
               l_succ_cnt := l_idx.cmo_nocards_ordr - l_err_cnt;

               UPDATE cms_merinv_ordr
                  SET cmo_success_records =
                         NVL (cmo_success_records, 0) + l_succ_cnt
                WHERE cmo_ordr_refrno = l_idx.file_name;

               UPDATE cms_merinv_stock
                  SET cms_curr_stock = NVL (cms_curr_stock, 0) + l_succ_cnt
                WHERE cms_merprodcat_id = l_idx.cmo_merprodcat_id
                      AND cms_location_id = l_idx.cmo_location_id;

               UPDATE cms_summary_merinv
                  SET csm_success_records = l_succ_cnt,
                      csm_error_records = l_err_cnt
                WHERE csm_file_name = l_idx.file_name;
            END IF;
         EXCEPTION
            WHEN excp_merinv
            THEN
               ROLLBACK;
            WHEN OTHERS
            THEN
               ROLLBACK;
               l_errmsg :=
                  'Error while processing file-' || SUBSTR (SQLERRM, 1, 200);
         END;

         IF l_errmsg <> 'OK'
         THEN
            INSERT INTO cms_error_log (cel_inst_code,
                                       cel_file_name,
                                       cel_row_id,
                                       cel_error_mesg,
                                       cel_lupd_user,
                                       cel_lupd_date,
                                       cel_prob_action)
                 VALUES (p_instcode_in,
                         l_idx.file_name,
                         NULL,
                         l_errmsg,
                         p_usercode_in,
                         SYSDATE,
                         'Contact Site Administrator');
         END IF;

         COMMIT;
      END LOOP;
   EXCEPTION
      WHEN OTHERS
      THEN
         ROLLBACK;
         p_errmsg_out := 'Main Excp-' || SUBSTR (SQLERRM, 1, 200);
   END merinv_process;
END;
/
show error;