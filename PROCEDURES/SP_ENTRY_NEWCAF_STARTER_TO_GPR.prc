create or replace PROCEDURE  vmscms.SP_ENTRY_NEWCAF_STARTER_TO_GPR (
   p_instcode            IN       NUMBER,
   p_rowid               IN       VARCHAR2,
   p_stratercardnumber   IN       VARCHAR2,
                    --Parameters order changed for defectid 7117 by srinivasuk
   p_lupduser            IN       NUMBER,
   p_errmsg              OUT      VARCHAR2
)
IS
   /*************************************************
      * Created Date     :  21-Feb-2011
      * Created By       :  Srinivasu
      * PURPOSE          :  Starter card issuance
      * Modified by      :  Sagar M
      * Modified Date    :  16-Aug-2012
      * Modified Reason  :  For New KYC changes 
      * Reviewer          :  Nanda Kumar R.
      * Reviewed Date      :  16-Aug-2012
      * Build Number       :  RI0015_B0002
      
      
      * Modified By      :  Pankaj S.
      * Modified Date    :  08-Mar-2013
      * Modified Reason  :  To update id type iin customer mast(Mantis ID-10549)
      * Reviewer         :  Dhiraj
      * Reviewed Date    :  08/Mar/2013
      * Build Number     :  CMS3.5.1_RI0023.2_B0019

      * Modified By      :  Siva Kumar M
      * Modified Date    :  12-Sept-2013
      * Modified Reason  :  Defect Id:0012008
      * Reviewer         :  Dhiraj 
      * Reviewed Date    :  12-Sept-2013 
      * Build Number     :  RI0024.4_B0010
      
      * Modified By      :  Ramesh A
      * Modified Date    :  17-Jun-2014
      * Modified Reason  :  FSS-1710 - Performance issue in GPR Card generation transaction.needs to fine tune the process
      * Reviewer         :  spankaj
      * Build Number     :  RI0027.1.9_B0001
      
      * Modified by      : MageshKumar S.
      * Modified Date    : 25-July-14    
      * Modified For     : FWR-48
      * Modified reason  : GL Mapping removal changes
      * Reviewer         : Spankaj
      * Build Number     : RI0027.3.1_B0001
      
      * Modified by      : Pankaj S.
      * Modified Date    : 18-Aug-2015    
      * Modified reason  : Partner ID Changes
      * Reviewer         : Sarvanankumar 
      * Build Number     :
      
       * Modified by           : Abdul Hameed M.A
      * Modified Date         : 07-Sep-15
      * Modified For          : FSS-3509 & FSS-1817
      * Reviewer              : Saravanankumar
      * Build Number          : VMSGPRHOSTCSD3.2
      
      * Modified by                :MageshKumar S
      * Modified Date            : 06-Jan-16
      * Modified For             : VP-177
      * Reviewer                  : Saravanankumar/Spankaj
      * Build Number            : VMSGPRHOSTCSD3.3
      
     * Modified by                  : MageshKumar S.
     * Modified Date                : 18-Jan-16
     * Modified For                 : Mantis Id:0016238
     * Reviewer                     : Sarvanankumar/Spankaj
     * Build Number                 : VMSGPRHOSTCSD3.3
    
   
      * Modified by       :Siva kumar 
       * Modified Date    : 22-Mar-16
       * Modified For     : MVHOST-1323
       * Reviewer         : Saravanankumar/Pankaj
       * Build Number     : VMSGPRHOSTCSD_4.0_B006
       
       * Modified By      : MageshKumar S
       * Modified Date    : 18/07/2017
       * Purpose          : FSS-5157
       * Reviewer         : Saravanan/Pankaj S. 
       * Release Number   : VMSGPRHOST17.07
     
     * Modified By      : UBAIDUR RAHMAN.H
     * Modified Date    : 25-JAN-2018
     * Purpose          : VMS-162 (encryption changes)
     * Reviewer         : Vini.P
     * Release Number   : VMSGPRHOST18.01 
	 
	 * Modified by      :  Vini Pushkaran
     * Modified Date    :  02-Feb-2018
     * Modified For     :  VMS-162
     * Reviewer         :  Saravanankumar
     * Build Number     :  VMSGPRHOSTCSD_18.01
     
     * Modified By      : UBAIDUR RAHMAN.H
     * Modified Date    : 09-JUL-2019
     * Purpose          : VMS 960/962 - Enhance Website/middleware to 
                                support cardholder data search – phase 2.
     * Reviewer         : Saravana Kumar.A
     * Release Number   : VMSGPRHOST_R18
	 
	 * Modified By      : PUVANESH N
     * Modified Date    : 24-DEC-2021
     * Purpose          : VMS-5378 : Need to update ccm_system_generate_profile flag in Retail / Card stock flow.
     * Reviewer         : Saravana Kumar.A
     * Release Number   : VMSGPRHOST_R56 Build 2.
       
   *************************************************/
   v_cust_code             cms_cust_mast.ccm_cust_code%TYPE;
 
   v_comm_addrcode         cms_addr_mast.cam_addr_code%TYPE;
 
   v_switch_acct_type      cms_acct_type.cat_switch_type%TYPE    DEFAULT '11';
   v_switch_acct_stat      cms_acct_stat.cas_switch_statcode%TYPE DEFAULT '3';
   v_acct_type             cms_acct_type.cat_type_code%TYPE;
   v_acct_stat             cms_acct_mast.cam_stat_code%TYPE;
   v_acct_numb             cms_acct_mast.cam_acct_no%TYPE;
   v_acct_id               cms_acct_mast.cam_acct_id%TYPE;
    
   v_prod_code             cms_prod_mast.cpm_prod_code%TYPE;
   v_prod_cattype          cms_prod_cattype.cpc_card_type%TYPE;
   v_inst_bin              cms_prod_bin.cpb_inst_bin%TYPE;
   v_prod_ccc              cms_prod_ccc.cpc_prod_sname%TYPE;
   v_custcatg              cms_prod_ccc.cpc_cust_catg%TYPE;
   v_appl_code             cms_appl_mast.cam_appl_code%TYPE;
   v_errmsg                cms_caf_info_entry.cci_process_msg%type;
   v_savepoint             NUMBER                                   DEFAULT 1;
   v_gender                cms_cust_mast.ccm_gender_type%type;
  
   v_holdposn              cms_cust_acct.cca_hold_posn%TYPE;
   v_brancheck             PLS_INTEGER;
 
   v_catg_code             cms_prod_mast.cpm_catg_code%TYPE;
  
   v_kyc_flag              cms_caf_info_entry.cci_kyc_flag%type;
   v_instrument_realised   cms_caf_info_entry.cci_instrument_realised%type;
   v_kyc_error_log         PLS_INTEGER;
   v_instreal_error_log    PLS_INTEGER;
    
   v_cust_data             type_cust_rec_array;
   v_addr_data1            type_addr_rec_array;
   v_addr_data2            type_addr_rec_array;
   v_appl_data             type_appl_rec_array;
   v_seg31acctnum_data     type_acct_rec_array;
   
 
   v_cap_cust_code         cms_appl_pan.cap_cust_code%TYPE;
   v_startercard_custid    cms_cust_mast.ccm_cust_id%TYPE;
   v_partner_id            cms_product_param.cpp_partner_id%TYPE;
   v_mailing_addr_count    PLS_INTEGER; -- Added for VPP-177 of 3.3R
   v_card_type             cms_appl_pan.cap_card_type%TYPE;
   v_encrypt_enable        cms_prod_cattype.cpc_encrypt_enable%TYPE;
   exp_reject_record       EXCEPTION;
   exp_process_record      EXCEPTION;

   CURSOR c
   IS
      SELECT cci_inst_code, cci_file_name, cci_row_id, cci_appl_code,
             cci_appl_no, cci_pan_code, cci_mbr_numb, cci_crd_stat,
             cci_exp_dat, cci_rec_typ, cci_crd_typ, cci_requester_name,
             cci_prod_code, cci_card_type, cci_seg12_branch_num, cci_fiid,
             cci_title, cci_seg12_name_line1, cci_seg12_name_line2,
             cci_birth_date, cci_mothers_maiden_name, NVL(FN_DMAPS_MAIN(cci_ssn_ENCR),cci_ssn) cci_ssn, cci_hobbies,
             cci_cust_id, cci_comm_type, cci_seg12_addr_line1,
             cci_seg12_addr_line2, cci_seg12_city, cci_seg12_state, cci_seg12_state_code,
             cci_seg12_postal_code, cci_seg12_country_code,
             cci_seg12_mobileno, cci_seg12_homephone_no,
             cci_seg12_officephone_no, cci_seg12_emailid,
             cci_seg13_addr_line1, cci_seg13_addr_line2, cci_seg13_city,
             cci_seg13_state, cci_seg13_state_code, cci_seg13_postal_code, cci_seg13_country_code,
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
             cci_cust_catg,
                           --Sn Customer generic data
                           cci_customer_param1, cci_customer_param2,
             cci_customer_param3, cci_customer_param4, cci_customer_param5,
             cci_customer_param6, cci_customer_param7, cci_customer_param8,
             cci_customer_param9, cci_customer_param10,

             --En customer generic data
             --Sn select addrss seg12 detail
             cci_seg12_addr_param1, cci_seg12_addr_param2,
             cci_seg12_addr_param3, cci_seg12_addr_param4,
             cci_seg12_addr_param5, cci_seg12_addr_param6,
             cci_seg12_addr_param7, cci_seg12_addr_param8,
             cci_seg12_addr_param9, cci_seg12_addr_param10,

             --En select ddrss seg12 detail
             --Sn select addrss seg12 detail
             cci_seg13_addr_param1, cci_seg13_addr_param2,
             cci_seg13_addr_param3, cci_seg13_addr_param4,
             cci_seg13_addr_param5, cci_seg13_addr_param6,
             cci_seg13_addr_param7, cci_seg13_addr_param8,
             cci_seg13_addr_param9, cci_seg13_addr_param10,

             --Sn select acct data
             cci_seg31_num_param1, cci_seg31_num_param2,
             cci_seg31_num_param3, cci_seg31_num_param4,
             cci_seg31_num_param5, cci_seg31_num_param6,
             cci_seg31_num_param7, cci_seg31_num_param8,
             cci_seg31_num_param9, cci_seg31_num_param10,

             --Sn select appl data
             cci_custappl_param1, cci_custappl_param2, cci_custappl_param3,
             cci_custappl_param4, cci_custappl_param5, cci_custappl_param6,
             cci_custappl_param7, cci_custappl_param8, cci_custappl_param9,
             cci_lupd_date, cci_comments, ROWID r,
             --Sn Added by Pankaj S. for Mantis id 10549
             NVL(FN_DMAPS_MAIN(CCI_ID_NUMBER_ENCR),cci_id_number) cci_id_number,
             cci_id_expiry_date,
             cci_id_issuance_date,
             cci_id_issuer
             --En Added by Pankaj S. for Mantis id 10549
        FROM cms_caf_info_entry
       WHERE cci_approved = 'A'
         AND cci_inst_code = p_instcode
         AND cci_upld_stat = 'P'
         AND cci_row_id = p_rowid
         AND cci_kyc_flag in('Y','P','O','I');  -- In condition added by sagar on 16Aug2012 for KYC changes
BEGIN
   v_errmsg := 'OK';
   v_cust_data := type_cust_rec_array ();
   v_addr_data1 := type_addr_rec_array ();
   v_addr_data2 := type_addr_rec_array ();
   v_appl_data := type_appl_rec_array ();
   v_seg31acctnum_data := type_acct_rec_array ();

   --SN  Loop for record pending for processing
   --DELETE FROM pcms_upload_log; -- Commented for not required on FSS-1710

   FOR i IN c
   LOOP
      --Initialize the common loop variable
      v_errmsg := 'OK';
      v_cust_data.DELETE;
      v_addr_data1.DELETE;
      v_addr_data2.DELETE;
      v_seg31acctnum_data.DELETE;
      v_appl_data.DELETE;
      SAVEPOINT v_savepoint;

      BEGIN
         --Sn  Check product , prodtype  catg

         -- Sn Check KYC first is N or not
         --if kyc show en error then also we will process the record
         BEGIN
            SELECT cci_kyc_flag
              INTO v_kyc_flag
              FROM cms_caf_info_entry
             WHERE cci_inst_code = p_instcode AND cci_row_id = i.cci_row_id;

            IF v_kyc_flag = 'N'
            THEN
               v_kyc_error_log := 1;
               v_errmsg := 'KYC is pending for approval ';
               RAISE exp_process_record;
            END IF;
         EXCEPTION
            WHEN NO_DATA_FOUND THEN
             v_kyc_error_log := 1;
               v_errmsg :=
                     'NO KYC flag';
               RAISE exp_process_record;
            WHEN OTHERS
            THEN
               v_kyc_error_log := 1;
               v_errmsg :=
                     'Error while selecting KYC flag '
                  || SUBSTR (SQLERRM, 1, 200);
               RAISE exp_process_record;
         END;

         --En check kyc first is N or Not

         -- Sn find prod
         BEGIN
            SELECT cpm_prod_code
              INTO v_prod_code
              FROM cms_prod_mast
             WHERE cpm_inst_code = p_instcode
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
              FROM cms_prod_bin
             WHERE cpb_inst_code = p_instcode
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

         BEGIN
            IF i.cci_card_type IS NOT NULL
            THEN
               v_prod_cattype := i.cci_card_type;
            END IF;
         END;

         -- En check in prod bin
         -- Sn find prod cattype

         -- En find prod cattype
         --Sn find the default cust catg
         BEGIN
            SELECT ccc_catg_code
              INTO v_custcatg
              FROM cms_cust_catg
             WHERE ccc_inst_code = p_instcode
               AND ccc_catg_sname = i.cci_cust_catg;
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
              FROM cms_prod_ccc
             WHERE cpc_inst_code = p_instcode
               AND cpc_prod_code = i.cci_prod_code
               AND cpc_card_type = i.cci_card_type
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
                       VALUES (p_instcode, v_custcatg, i.cci_card_type,
                               i.cci_prod_code, p_lupduser, SYSDATE,
                               p_lupduser, SYSDATE, '1',
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

         --En Check Product , prod type  catg

         -- Sn find prod
         BEGIN
            SELECT cpm_catg_code
              INTO v_catg_code
              FROM cms_prod_mast
             WHERE cpm_inst_code = p_instcode
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

         --msiva added on Jul 25 2011 for Expiry date calculation Sn
 

         -- En find prod
         IF v_catg_code = 'P'
         THEN
            -- Sn Check KYC first is N or not
            BEGIN
               v_instreal_error_log := 0;

               SELECT cci_instrument_realised
                 INTO v_instrument_realised
                 FROM cms_caf_info_entry
                WHERE cci_inst_code = p_instcode
                  AND cci_row_id = i.cci_row_id
                  AND cci_instrument_realised = 'Y';
            EXCEPTION
               WHEN NO_DATA_FOUND
               THEN
                  v_errmsg :=
                         'Instrument Realised ' || 'is pending for approval ';
                  RAISE exp_process_record;
               WHEN OTHERS
               THEN
                  v_instreal_error_log := 1;
                  v_errmsg :=
                        'Error while selecting Instrument Realised '
                     || SUBSTR (SQLERRM, 1, 200);
                  RAISE exp_process_record;
            END;

            --En check instrument_realised first is N or Not
            
 
         END IF;

         --En check card amount and initial load spprt function

         --Sn find Branch
         BEGIN
            SELECT 1
              INTO v_brancheck
              FROM cms_bran_mast
             WHERE cbm_inst_code = p_instcode AND cbm_bran_code = i.cci_fiid;
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
              FROM cms_cust_mast
             WHERE ccm_inst_code = p_instcode AND ccm_cust_id = i.cci_cust_id;

            BEGIN
               SELECT cam_addr_code
                 INTO v_comm_addrcode
                 FROM cms_addr_mast
                WHERE cam_inst_code = p_instcode
                  AND cam_cust_code = v_cust_code
                  AND cam_addr_flag = 'P';
            EXCEPTION
               WHEN NO_DATA_FOUND
               THEN
                  RAISE exp_reject_record;
               WHEN TOO_MANY_ROWS
               THEN
                  RAISE exp_reject_record;
               WHEN OTHERS
               THEN
                  RAISE exp_reject_record;
            END;
         EXCEPTION
            WHEN NO_DATA_FOUND
            THEN
               --------------------If customer is not Found in table then we create Customer and address (As discussed with Shyamjit on 020909)------

               --Sn assign records to customer gen variable
               BEGIN
                  SELECT type_cust_rec_array (i.cci_customer_param1,
                                              i.cci_customer_param2,
                                              i.cci_customer_param3,
                                              i.cci_customer_param4,
                                              i.cci_customer_param5,
                                              i.cci_customer_param6,
                                              i.cci_customer_param7,
                                              i.cci_customer_param8,
                                              i.cci_customer_param9,
                                              i.cci_customer_param10
                                             )
                    INTO v_cust_data
                    FROM DUAL;
               EXCEPTION
                  WHEN OTHERS
                  THEN
                     v_errmsg :=
                           'Error while cutomer gen data '
                        || SUBSTR (SQLERRM, 1, 200);
                     RAISE exp_reject_record;
               END;

               --En assign records to customer gen variable

               -----------------------------------------------------------------------
--SN: added by sagar on 11-Apr-2012 for Changes in starter card respon
-----------------------------------------------------------------------
               BEGIN
                  SELECT cap_cust_code, cap_prod_code,cap_card_type
                    INTO v_cap_cust_code,v_prod_code,v_card_type
                    FROM cms_appl_pan
                   WHERE cap_inst_code = p_instcode
                     AND cap_pan_code = gethash (p_stratercardnumber);
                    -- AND cap_startercard_flag = 'Y';
               EXCEPTION
                  WHEN NO_DATA_FOUND
                  THEN
                     v_errmsg :=
                             'Starter card not found ' || p_stratercardnumber;
                     RAISE exp_reject_record;
                  WHEN OTHERS
                  THEN
                     v_errmsg :=
                           'error while fetching starter card '
                        || SUBSTR (SQLERRM, 1, 200);
                     RAISE exp_reject_record;
               END;

               v_cust_code := v_cap_cust_code;

               BEGIN
                  SELECT ccm_cust_id, ccm_partner_id
                    INTO v_startercard_custid, v_partner_id
                    FROM cms_cust_mast
                   WHERE ccm_inst_code = p_instcode
                     AND ccm_cust_code = v_cap_cust_code;
               EXCEPTION
                  WHEN NO_DATA_FOUND
                  THEN
                     v_errmsg :=
                           'custid not found for starter card custcode '
                        || v_cap_cust_code;
                     RAISE exp_reject_record;
                  WHEN OTHERS
                  THEN
                     v_errmsg :=
                           'error while fetching custid of starter card '
                        || SUBSTR (SQLERRM, 1, 200);
                     RAISE exp_reject_record;
               END;

               --SN: added by srinivasu on 12-Apr-2012 for Changes in starter card addr code also same
               --Added by Deepa on 15-04-12 to update the customer details
               BEGIN
                  SELECT DECODE (i.cci_title,
                                 'Mr.', 'M',
                                 'Mrs.', 'F',
                                 'Miss.', 'F',
                                 'Dr.', 'D'
                                )
                    INTO v_gender
                    FROM DUAL;
               END;
               
               --Sn Added for partner id changes
               IF v_partner_id IS NULL THEN
                 BEGIN
                    SELECT cpp_partner_id
                      INTO v_partner_id
                      FROM cms_product_param
                     WHERE cpp_prod_code = v_prod_code AND cpp_inst_code = p_instcode;
                 EXCEPTION
                    WHEN NO_DATA_FOUND THEN
                       v_errmsg :='Product code '|| v_prod_code || ' is not defined in the product param master';
                       RAISE exp_reject_record;
                    WHEN OTHERS THEN
                       v_errmsg :='Error while selecting partner dtls- ' || SUBSTR (SQLERRM, 1, 200);
                       RAISE exp_reject_record;
                 END;                
               END IF;               
               --Sn Added for partner id changes
               
			   BEGIN
			       SELECT cpc_encrypt_enable 
				   INTO v_encrypt_enable
				   FROM cms_prod_cattype
				   WHERE cpc_inst_code = p_instcode
				   AND cpc_prod_code = v_prod_code
				   AND cpc_card_type = v_card_type;
			   EXCEPTION
                    WHEN NO_DATA_FOUND THEN
                       v_errmsg :='No data found for prod code and card type';
                       RAISE exp_reject_record;
                    WHEN OTHERS THEN
                       v_errmsg :='Error while selecting encrypt_enable flag- ' || SUBSTR (SQLERRM, 1, 200);
                       RAISE exp_reject_record;			      
			   END;

               --Update the Customer details
               BEGIN
                  UPDATE cms_cust_mast
                     SET ccm_salut_code = i.cci_title,
                         ccm_first_name = i.cci_seg12_name_line1,
                         ccm_mid_name = NULL,
                         ccm_last_name = i.cci_seg12_name_line2,
                         ccm_birth_date = i.cci_birth_date,
                         ccm_perm_id = NULL,
                         --ccm_email_one = i.cci_seg12_emailid,
                         ccm_email_two = NULL,
                         --ccm_mobl_one = i.cci_seg12_mobileno,
                         ccm_mobl_two = NULL,
                         ccm_lupd_user = p_lupduser,
                         ccm_gender_type = v_gender,
                         ccm_marital_stat = NULL,
                          ccm_ssn = fn_maskacct_ssn(p_instcode,decode(i.cci_document_verify,'SSN',i.cci_ssn,'SIN',i.cci_ssn,i.cci_id_number),0),  --Modified by Pankaj S. for Mantisid-10549
                         ccm_ssn_encr = fn_emaps_main(decode(i.cci_document_verify,'SSN',i.cci_ssn,'SIN',i.cci_ssn,i.cci_id_number)),
                         ccm_mother_name = i.cci_mothers_maiden_name,
                         ccm_hobbies = i.cci_hobbies,
                         ccm_emp_id = i.cci_emp_id,
                         ccm_partner_id=v_partner_id,
                         CCM_FIRST_NAME_ENCR = decode(v_encrypt_enable,'Y',i.cci_seg12_name_line1,fn_emaps_main(i.cci_seg12_name_line1)),
                         CCM_LAST_NAME_ENCR = decode(v_encrypt_enable,'Y',i.cci_seg12_name_line2,fn_emaps_main(i.cci_seg12_name_line2))
                   WHERE ccm_cust_code = v_cap_cust_code
                     AND ccm_cust_id = v_startercard_custid
                     AND ccm_inst_code = p_instcode;

                  IF SQL%ROWCOUNT = 0
                  THEN
                     v_errmsg :=
                           'Exception in updating the Customer details for '
                        || v_cap_cust_code;
                     RAISE exp_reject_record;
                  END IF;
               EXCEPTION
                  WHEN exp_reject_record
                  THEN
                     RAISE;
                  WHEN OTHERS
                  THEN
                     v_errmsg :=
                           'Error while updating the Customer details '
                        || SUBSTR (SQLERRM, 1, 200);
                     RAISE exp_reject_record;
               END;

               --Sn Added by Pankaj S. for Mantis id 10549
                BEGIN
                   IF i.cci_document_verify = 'SSN'
                   THEN
                      UPDATE cms_cust_mast
                         SET ccm_id_type = i.cci_document_verify
                       WHERE ccm_cust_code = v_cap_cust_code
                         AND ccm_cust_id = v_startercard_custid
                         AND ccm_inst_code = p_instcode;
                   ELSE
                      UPDATE cms_cust_mast
                         SET ccm_id_type = i.cci_document_verify,
                             ccm_id_issuer = i.cci_id_issuer,
                             ccm_idissuence_date = i.cci_id_issuance_date,
                             ccm_idexpry_date = i.cci_id_expiry_date
                       WHERE ccm_cust_code = v_cap_cust_code
                         AND ccm_cust_id = v_startercard_custid
                         AND ccm_inst_code = p_instcode;
                   END IF;

                   IF SQL%ROWCOUNT = 0
                   THEN
                      v_errmsg :=
                         'Exception in updating the Customer details for ' || v_cap_cust_code;
                      RAISE exp_reject_record;
                   END IF;
                EXCEPTION
                   WHEN exp_reject_record
                   THEN
                      RAISE;
                   WHEN OTHERS
                   THEN
                      v_errmsg :=
                            'Error while updating the Customer details '
                         || SUBSTR (SQLERRM, 1, 200);
                      RAISE exp_reject_record;
                END;
                --En Added by Pankaj S. for Mantis id 10549
               BEGIN
                  SELECT cam_addr_code
                    INTO v_comm_addrcode
                    FROM cms_addr_mast
                   WHERE cam_cust_code = v_cap_cust_code
                     AND cam_inst_code = p_instcode
                     AND cam_addr_flag = 'P'; -- added for defect id:0012008
               EXCEPTION
                  WHEN NO_DATA_FOUND
                  THEN
                     v_errmsg :=
                           'ADDRD CODE  not found for starter card custcode '
                        || SUBSTR (SQLERRM, 1, 200);
                     RAISE exp_reject_record;
                  WHEN OTHERS
                  THEN
                     v_errmsg :=
                           'error while fetching ADDRD CODE  of starter card '
                        || SUBSTR (SQLERRM, 1, 200);
                     RAISE exp_reject_record;
               END;

   
               
                       
               BEGIN

                     --Modified by Deepa on Apr-19-12 to update the physical address and insert the mailing address as Office Address
                     UPDATE cms_addr_mast
                     SET cam_add_one = i.cci_seg12_addr_line1,
                         cam_add_two = i.cci_seg12_addr_line2,
                         cam_pin_code = i.cci_seg12_postal_code,
                         cam_phone_one = i.CCI_SEG12_HOMEPHONE_NO,
                         cam_mobl_one = i.CCI_SEG12_MOBILENO,
                         cam_email = i.cci_seg12_emailid,
                         cam_cntry_code = i.cci_seg12_country_code,
                         cam_city_name = i.cci_seg12_city,
                         cam_state_switch = i.cci_seg12_state,
                         cam_state_code = i.cci_seg12_state_code, -- Changed by Trivikram on 21-05-2012 for update state code of residential address in CMS_ADDR_MAST
                         cam_lupd_user = p_lupduser,
                         CAM_ADD_ONE_ENCR = decode(v_encrypt_enable,'Y',i.cci_seg12_addr_line1,fn_emaps_main(i.cci_seg12_addr_line1)),
                         CAM_ADD_TWO_ENCR = decode(v_encrypt_enable,'Y',i.cci_seg12_addr_line2,fn_emaps_main(i.cci_seg12_addr_line2)),
                         CAM_CITY_NAME_ENCR = decode(v_encrypt_enable,'Y',i.cci_seg12_city,fn_emaps_main(i.cci_seg12_city)),
                         CAM_PIN_CODE_ENCR = decode(v_encrypt_enable,'Y',i.cci_seg12_postal_code,fn_emaps_main(i.cci_seg12_postal_code)),
                         CAM_EMAIL_ENCR = decode(v_encrypt_enable,'Y',i.cci_seg12_emailid,fn_emaps_main(i.cci_seg12_emailid))
                   WHERE cam_inst_code = p_instcode
                     AND cam_addr_code = v_comm_addrcode
                     AND cam_addr_flag = 'P';
					 
					BEGIN
						UPDATE CMS_CUST_MAST
							SET CCM_SYSTEM_GENERATED_PROFILE = 'N'
						WHERE CCM_INST_CODE = P_INSTCODE
						AND CCM_CUST_CODE = V_CAP_CUST_CODE;
						
					EXCEPTION
						WHEN OTHERS THEN
						 V_ERRMSG := 'Exception While Updating Customer Mast ' || SUBSTR (SQLERRM, 1, 200);
						  RAISE exp_reject_record;
					END;

--SN added for VPP-177 of 3.3R
   BEGIN

        SELECT count(1)
          INTO v_mailing_addr_count
          FROM cms_addr_mast
          WHERE cam_cust_code = v_cap_cust_code
          AND cam_inst_code = p_instcode
          AND cam_addr_flag = 'O';
          EXCEPTION
         WHEN OTHERS THEN
         V_ERRMSG := 'Error while selecting mailing address count ' || SUBSTR (SQLERRM, 1, 200);
          RAISE exp_reject_record;
        END;
        
        IF v_mailing_addr_count <> 0 THEN        
		
         IF i.cci_seg13_addr_line1 IS NOT NULL 
            AND i.cci_seg13_country_code IS NOT NULL
            AND i.cci_seg13_city IS NOT NULL THEN

            BEGIN
            
           
                 UPDATE cms_addr_mast
                 SET cam_add_one = i.cci_seg13_addr_line1,
                     cam_add_two = i.cci_seg13_addr_line2,
                     cam_city_name = i.cci_seg13_city,
                     cam_pin_code = i.cci_seg13_postal_code,
                     cam_phone_one = i.cci_seg13_homephone_no,
                     cam_mobl_one = i.cci_seg13_mobileno,
                     cam_email = i.cci_seg12_emailid,
                     cam_state_code = i.cci_seg13_state_code,
                     cam_cntry_code =i.cci_seg13_country_code,
                     cam_state_switch = i.cci_seg13_state,
                     cam_lupd_user = p_lupduser,
                     cam_lupd_date = sysdate,
                     CAM_ADD_ONE_ENCR = decode(v_encrypt_enable,'Y',i.cci_seg13_addr_line1,fn_emaps_main(i.cci_seg13_addr_line1)),
                     CAM_ADD_TWO_ENCR = decode(v_encrypt_enable,'Y',i.cci_seg13_addr_line2,fn_emaps_main(i.cci_seg13_addr_line2)),
                     CAM_CITY_NAME_ENCR = decode(v_encrypt_enable,'Y',i.cci_seg13_city,fn_emaps_main(i.cci_seg13_city)),
                     CAM_PIN_CODE_ENCR = decode(v_encrypt_enable,'Y',i.cci_seg13_postal_code,fn_emaps_main(i.cci_seg13_postal_code)),
                     CAM_EMAIL_ENCR = decode(v_encrypt_enable,'Y',i.cci_seg13_emailid,fn_emaps_main(i.cci_seg13_emailid))
               WHERE cam_cust_code = v_cap_cust_code
                 AND cam_inst_code = p_instcode
                 AND cam_addr_flag = 'O';

            END;
            
            END IF;

         ELSE --EN added for VPP-177 of 3.3R

    

                  IF     i.cci_seg13_addr_line1 IS NOT NULL
                      AND i.cci_seg13_postal_code IS NOT NULL
                     AND i.cci_seg13_country_code IS NOT NULL
                     AND i.cci_seg13_city IS NOT NULL
                     AND i.cci_seg13_state IS NOT NULL
                  THEN
                     INSERT INTO cms_addr_mast
                                 (cam_inst_code, cam_cust_code,
                                  cam_addr_code,
                                  cam_add_one,
                                  cam_add_two,
                                  cam_phone_one,
                                  cam_mobl_one, cam_email,
                                  cam_pin_code,
                                  cam_cntry_code,
                                  cam_city_name, cam_addr_flag,
                                  cam_state_switch, cam_ins_user,
                                  cam_ins_date, cam_lupd_user,
                                  cam_lupd_date, cam_state_code,
                                  CAM_ADD_ONE_ENCR,CAM_ADD_TWO_ENCR,
                                  CAM_CITY_NAME_ENCR,CAM_PIN_CODE_ENCR,
                                  CAM_EMAIL_ENCR 
                                 )
                         VALUES (p_instcode, v_cap_cust_code,
                                  seq_addr_code.NEXTVAL,
                                  i.cci_seg13_addr_line1,
                                  i.cci_seg13_addr_line2,
                                  i.cci_seg13_homephone_no,
                                  i.cci_seg13_mobileno, i.cci_seg12_emailid,
                                  i.cci_seg13_postal_code,
                                  i.cci_seg13_country_code,
                                  i.cci_seg13_city, 'O',
                                  i.cci_seg13_state, 1,
                                  SYSDATE, p_lupduser,
                                  SYSDATE, i.cci_seg13_state_code, -- Changed by Trivikram on 21-05-2012 for update state code of mailing address in CMS_ADDR_MAST
                                  decode(v_encrypt_enable,'Y',i.cci_seg13_addr_line1,fn_emaps_main(i.cci_seg13_addr_line1)),
                                  decode(v_encrypt_enable,'Y',i.cci_seg13_addr_line2,fn_emaps_main(i.cci_seg13_addr_line2)),
                                  decode(v_encrypt_enable,'Y',i.cci_seg13_city,fn_emaps_main(i.cci_seg13_city)),
                                  decode(v_encrypt_enable,'Y',i.cci_seg13_postal_code,fn_emaps_main(i.cci_seg13_postal_code)),
                                  decode(v_encrypt_enable,'Y',i.cci_seg13_emailid,fn_emaps_main(i.cci_seg13_emailid))
                                 );
                  END IF;
                  END IF; ----Condition added for VPP-177 of 3.3R

                  IF SQL%ROWCOUNT = 0
                  THEN
                     v_errmsg := 'Exception in updating addr_mast ';
                     RAISE exp_reject_record;
                  END IF;
               EXCEPTION
                  WHEN exp_reject_record
                  THEN
                     RAISE;
                  WHEN OTHERS
                  THEN
                     v_errmsg :=
                           'Error while updating addr_mast'
                        || SUBSTR (SQLERRM, 1, 200)
                        || i.cci_seg12_country_code
                        || i.cci_seg12_state;
                     RAISE exp_reject_record;
               END;
 
            WHEN exp_reject_record
            THEN
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
               v_errmsg := 'Acct type not defined in master';
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
             WHERE cas_inst_code = p_instcode
               AND cas_switch_statcode = v_switch_acct_stat;
         EXCEPTION
            WHEN NO_DATA_FOUND
            THEN
               v_errmsg := 'Acct stat not defined for  master';
               RAISE exp_reject_record;
            WHEN OTHERS
            THEN
               v_errmsg :=
                     'Error while selecting accttype '
                  || SUBSTR (SQLERRM, 1, 200);
               RAISE exp_reject_record;
         END;

--*************************************************************
--En select acct stat
--Sn get acct number

         --En get acct number
         IF v_catg_code = 'P'
         THEN
            /*For Stater card to GPR Card generation Account number is same for starter card and GPR Card
             */
            BEGIN
               SELECT cap_acct_no, cap_acct_id
                 INTO v_acct_numb, v_acct_id
                 FROM cms_appl_pan
                WHERE cap_pan_code = gethash (p_stratercardnumber)
                  AND cap_inst_code = p_instcode;
            EXCEPTION
               WHEN OTHERS
               THEN
                  v_errmsg :=
                        'Error while selecting CMS_APPL_PAN '
                     || SUBSTR (SQLERRM, 1, 200);
                  RAISE exp_reject_record;
            END;
         ELSIF v_catg_code = 'D'
         THEN
            v_acct_numb := i.cci_seg31_num;
         END IF;

--*****************************************************
--Sn create acct

         --En create acct

         --Sn create a entry in cms_cust_acct
         BEGIN
            UPDATE cms_acct_mast
               SET cam_hold_count = cam_hold_count + 1,
                   cam_lupd_user = p_lupduser
             WHERE cam_inst_code = p_instcode AND cam_acct_id = v_acct_id;

            IF SQL%ROWCOUNT = 0
            THEN
               v_errmsg :=
                       'Error while update acct ' || SUBSTR (SQLERRM, 1, 200);
               RAISE exp_reject_record;
            END IF;
         EXCEPTION
            WHEN OTHERS
            THEN
               v_errmsg :=
                       'Error while update acct ' || SUBSTR (SQLERRM, 1, 200);
               RAISE exp_reject_record;
         END;

         BEGIN
            sp_create_holder (p_instcode,
                              v_cust_code,
                              v_acct_id,
                              NULL,
                              p_lupduser,
                              v_holdposn,
                              v_errmsg
                             );

            IF v_errmsg <> 'OK'
            THEN
               v_errmsg := 'Error from create entry cust_acct ' || v_errmsg;
               RAISE exp_reject_record;
            END IF;
         EXCEPTION
            WHEN OTHERS
            THEN
               v_errmsg :=
                     'Error while calling SP_CREATE_HOLDER '
                  || SUBSTR (SQLERRM, 1, 200);
               RAISE exp_reject_record;
         END;

         ---En create a entry in cms_cust_acct

         -- En create account
         -- Sn create Application
 
         BEGIN

        v_appl_code := i.cci_appl_code; --Added fro FSS-1710
        
            update cms_appl_mast set CAM_STARTER_CARD= 'N',CAM_DISP_NAME=i.CCI_SEG12_NAME_LINE1 where--Modified  by Deepa on Apr-20-2012 to update the display name
            CAM_APPL_CODE = v_appl_code and CAM_INST_CODE=p_instcode;
                IF SQL%ROWCOUNT = 0 THEN
                v_errmsg :=
                     'Updating CMS_CAF_INFO_ENTRY ERROR v_appl_code:'
                  || v_appl_code;
               RAISE exp_reject_record;
                END IF;

            EXCEPTION
            WHEN exp_reject_record THEN
            RAISE exp_reject_record;
            WHEN OTHERS
            THEN
               v_errmsg :=
                     'Error while updating CMS_CAF_INFO_ENTRY'
                  || SUBSTR (SQLERRM, 1, 200);
               RAISE exp_reject_record;
          END;

         --Sn mark the record as successful
         BEGIN
            UPDATE cms_caf_info_entry
               SET cci_approved = 'O',
                   cci_upld_stat = 'O',
                  -- cci_appl_code = v_appl_code, --Commented for not required in FSS-1710
                   cci_process_msg = 'Successful'
             WHERE cci_inst_code = p_instcode AND ROWID = i.r;
             IF SQL%ROWCOUNT = 0 THEN
                v_errmsg :=
                     'Updating  SUCCESS FLAG IN CMS_CAF_INFO_ENTRY ERROR v_appl_code:'
                  || v_appl_code;
               RAISE exp_reject_record;
                END IF;

         EXCEPTION
            WHEN exp_reject_record THEN
            RAISE exp_reject_record;
            WHEN OTHERS
            THEN
               v_errmsg :=
                     'Error while updating CMS_CAF_INFO_ENTRY'
                  || SUBSTR (SQLERRM, 1, 200);
               RAISE exp_reject_record;
         END;
 
         v_savepoint := v_savepoint + 1;
      EXCEPTION
         WHEN exp_process_record
         THEN
            ROLLBACK TO v_savepoint;

            UPDATE cms_caf_info_entry
               SET cci_approved = 'A',
                   cci_upld_stat = 'P',
                   cci_process_msg = v_errmsg
             WHERE cci_inst_code = p_instcode AND ROWID = i.r;
 
         WHEN exp_reject_record
         THEN
            ROLLBACK TO v_savepoint;

            UPDATE cms_caf_info_entry
               SET cci_approved = 'A',
                   cci_upld_stat = 'E',
                   cci_process_msg = v_errmsg
             WHERE cci_inst_code = p_instcode AND ROWID = i.r;
 
         WHEN OTHERS
         THEN
            /* Added By kaustubh 23-04-09 for inserting record into log table*/
            ROLLBACK TO v_savepoint;

            UPDATE cms_caf_info_entry
               SET cci_approved = 'A',
                   cci_upld_stat = 'E',
                   cci_process_msg = v_errmsg
             WHERE cci_inst_code = p_instcode AND ROWID = i.r;
 
      END;
   --En  Loop for record pending for processing
   END LOOP;

   p_errmsg := v_errmsg;
EXCEPTION
   WHEN OTHERS
   THEN
      p_errmsg := 'Exception from Main ' || SUBSTR (SQLERRM, 1, 300);
END;
/
show error

