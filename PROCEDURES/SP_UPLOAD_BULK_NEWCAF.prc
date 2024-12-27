CREATE OR REPLACE PROCEDURE VMSCMS.sp_upload_bulk_newcaf (
   p_instcode   IN       NUMBER,
   p_filename   IN       VARCHAR2,
   p_lupduser   IN       NUMBER,
   p_errmsg     OUT      VARCHAR2
)
AS

  /*************************************************
      * Created Date     : 10-Dec-2012
      * Created By       : Sivapragasam
      * PURPOSE          : For Bulk upload
      * Modified By      : Amit
      * Modified Date    : 17-July-12 
      * Modified Reason  : Changed the exception handling.
      * Reviewer         : B.Besky Anand.
      * Reviewed Date    : 17-July-12 
      * Build  No.       : CMS3.5.1_RI0011_B0014
      
      * Modified By      : Dhiarj
      * Modified Date    : 25-MAR-2013 
      * Modified Reason  : Performance changes
      * Reviewer         : 
      * Reviewed Date    :  
      * Build  No.       : CMS3.5.1_RI0024_B0008
         
      * Modified By      : Sagar
      * Modified Date    : 25-MAR-2013 
      * Modified Reason  : 1) Wait period set as 1 sec
                           2) Date of birth passed as 01-JAN-1900 
      * Modified For     : Defect 10747                       
      * Reviewer         : Dhiraj
      * Reviewed Date    : 25-MAR-2013 
      * Build  No.       : CMS3.5.1_RI0024_B0012   
      
      * Modified By      : Sachin P
      * Modified Date    : 23-APR-2013 
      * Modified Reason  : Changes to maintain expiry date same for batch 
      * Modified For     : FSS-1158                      
      * Reviewer         : Dhiraj G
      * Reviewed Date    : 26-APR-2013 
      * Build  No.       : RI0024.1_B0013

     * Modified by       : Pankaj S.
     * Modified Date     : 18-Aug-2015    
     * Modified reason   : Partner ID Changes
     * Reviewer          : Sarvanankumar 
     * Build Number      :      
     * Modified by      : Saravana Kumar A
	 
     * Modified Date    : 07-Jan-17
	 * Modified reason  : Card Expiry date logic changes
	 * Reviewer         : Spankaj
	 * Build Number     : VMSGPRHOST17.1

     * Modified By      : MageshKumar S
     * Modified Date    : 18/07/2017
     * Purpose          : FSS-5157
     * Reviewer         : Saravanan/Pankaj S. 
     * Release Number   : VMSGPRHOST17.07
	 
	 * Modified By      : Sreeja D
     * Modified Date    : 25/01/2018
     * Purpose          : VMS-162
     * Reviewer         : SaravanaKumar A/Vini Pushkaran
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

   v_appl_status           cms_appl_mast.cam_appl_stat%type  := 'A';


   CURSOR c2 (fname IN VARCHAR2)
   IS
      SELECT   cci_row_id, cci_seg12_cardholder_title, cci_seg12_name_line1,
               
               --custmast part
               cci_seg12_addr_line1, cci_seg12_addr_line2,
               cci_seg12_name_line2, cci_seg12_city, cci_seg12_state,
               cci_seg12_postal_code, cci_seg12_country_code,
               cci_seg12_open_text1,                           --address part
                                    cci_fiid, cci_crd_typ, cci_pan_code,
               cci_exp_dat, cci_cust_catg, cci_seg12_branch_num,
               
               --customer category comes in this field
               cci_ikit_flag,
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
               cci_custappl_param10, cci_card_type, cci_prod_code,
               cci_store_id, cci_seg31_typ, cci_seg31_stat,
               type_acct_rec_array (cci_seg31_num_param1,
                                    cci_seg31_num_param2,
                                    cci_seg31_num_param3,
                                    cci_seg31_num_param4,
                                    cci_seg31_num_param5,
                                    cci_seg31_num_param6,
                                    cci_seg31_num_param7,
                                    cci_seg31_num_param8,
                                    cci_seg31_num_param9,
                                    cci_seg31_num_param10
                                   ) seg31acctnum_data,
               cci_seg31_num
          FROM cms_caf_info_temp
         WHERE cci_inst_code = p_instcode
           AND cci_file_name = fname   --- p_filename
           AND cci_upld_stat = 'B'
      ORDER BY cci_fiid, cci_seg31_num;

   v_inst_prsnt             PLS_INTEGER                                   := 0;
   v_grpcode                cms_cust_group.ccg_group_code%TYPE;
   v_state_code             gen_state_mast.gsm_state_code%TYPE;
   v_swich_state_code       gen_state_mast.gsm_switch_state_code%TYPE;
   v_acct_num               cms_acct_mast.cam_acct_no%TYPE;
   v_dupcheck_param_flag    cms_inst_param.cip_param_value%TYPE;
   v_dup_flag               VARCHAR2 (10);
   v_cnt                    PLS_INTEGER                                   := 1;
   v_tmp_num                VARCHAR2 (16);
   v_serl_indx              NUMBER;
   v_chk_index              NUMBER;
   v_cac_length             NUMBER;
   v_table_acct_construct   PKG_STOCK.table_acct_construct;
   --variable declaration
   v_cust                   cms_cust_mast.ccm_cust_code%TYPE;
   v_salutcode              cms_cust_mast.ccm_salut_code%TYPE;
    
   v_addrcode               cms_addr_mast.cam_addr_code%TYPE;
   v_acctid                 cms_acct_mast.cam_acct_id%TYPE;
   v_holdposn               cms_cust_acct.cca_hold_posn%TYPE;
   v_cpb_prod_code          cms_prod_bin.cpb_prod_code%TYPE;
   v_applcode               cms_appl_mast.cam_appl_code%TYPE;
   v_cpm_interchange_code   cms_prodtype_map.cpm_interchange_code%TYPE;
   v_ccc_catg_code          cms_cust_catg.ccc_catg_code%TYPE             := 1;
   v_cat_type_code          cms_acct_type.cat_type_code%TYPE;
   v_cas_stat_code          cms_acct_stat.cas_stat_code%TYPE;
 
  
   v_check_branch           PLS_INTEGER;
   v_custcatg_code          cms_cust_catg.ccc_catg_code%TYPE;
   v_custcatg               cms_cust_catg.ccc_catg_sname%TYPE;
   v_check_bin_stat         cms_bin_mast.cbm_bin_stat%TYPE;
   v_cust_data              type_cust_rec_array;
   v_addr_data1             type_addr_rec_array;
   v_addr_data2             type_addr_rec_array;
   v_appl_data              type_appl_rec_array;
   v_seg31acctnum_data      type_acct_rec_array;
   v_dum                    PLS_INTEGER;
   v_prodcattype            cms_prod_ccc.cpc_card_type%TYPE;
   
   v_profile_code           cms_prod_cattype.cpc_profile_code%TYPE;
   v_cpm_catg_code          cms_prod_mast.cpm_catg_code%TYPE;
   v_prod_prefix            cms_prod_cattype.cpc_prod_prefix%TYPE;
   v_programid              cms_prod_cattype.cpc_program_id%TYPE;
   v_expry_date             DATE;
 
   v_rownumber              cms_caf_info_entry.cci_row_id%TYPE;
   v_starter_card           cms_prod_cattype.cpc_starter_card%TYPE;
   v_profile_code_catg      cms_prod_cattype.cpc_profile_code%TYPE;
    
   v_catg_code              cms_prod_mast.cpm_catg_code%TYPE;
   v_exp_date_exemption     cms_prod_cattype.cpc_exp_date_exemption%TYPE;
   v_encrypt_enable		    cms_prod_cattype.cpc_encrypt_enable%TYPE;
   v_encr_firstname         CMS_CAF_INFO_ENTRY.CCI_SEG12_NAME_LINE1%TYPE;
   --SN VMS-7342
   v_expry_arry vmscms.EXPRY_ARRAY_TYP := vmscms.EXPRY_ARRAY_TYP ();
   v_sweep_flag vmscms.cms_prod_cattype.cpc_sweep_flag%type;
   v_isexpry_randm vmscms.cms_prod_cattype.cpc_expdate_randomization%type;
   v_qntity  NUMBER(10);
   v_cntr    NUMBER:=0;
   --EN VMS-7342
   excp_movetohist          EXCEPTION;

   -- added by sagar on 06Apr2012 to pass prod catg from prod_mast

   --**************************************************************--
   PROCEDURE sp_create_cust_bulk (
      prm_instcode       IN       NUMBER,
      prm_custtype       IN       NUMBER,
      prm_corpcode       IN       NUMBER,
      prm_custstat       IN       CHAR,
      prm_salutcode      IN       VARCHAR2,
      prm_firstname      IN       VARCHAR2,
      prm_midname        IN       VARCHAR2,
      prm_lastname       IN       VARCHAR2,
      prm_dob            IN       DATE,
      prm_gender         IN       CHAR,
      prm_marstat        IN       CHAR,
      prm_permid         IN       VARCHAR2,
      prm_email1         IN       VARCHAR2,
      prm_email2         IN       VARCHAR2,
      prm_mobl1          IN       VARCHAR2,
      prm_mobl2          IN       VARCHAR2,
      prm_lupduser       IN       NUMBER,
      prm_ssn            IN       VARCHAR2,
      prm_maidname       IN       VARCHAR2,
      prm_hobby          IN       VARCHAR2,
      prm_empid          IN       VARCHAR2,
      prm_catg_code      IN       VARCHAR2,
      prm_custid         IN       NUMBER,
      prm_inst_prsnt     IN       NUMBER,
      prm_grpcode        IN       NUMBER,
      prm_gen_custdata   IN       type_cust_rec_array,
      prm_prodcode       IN       VARCHAR2,    --Added for Partner ID Changes
      prm_cardtype        IN      NUMBER,
      prm_custcode       OUT      NUMBER,
      prm_errmsg         OUT      VARCHAR2
   )
   AS
/**************************************************
     * Created Date                 : 23/03/2013
     * Created By                   : Dhiraj Gaikwad
     * Purpose                      : To generate customers in master table
     * Last Modification Done by    :
     * Last Modification Date       :
     * Mofication Reason            :
     * Build Number                 :
 **************************************************/

 
      v_corp              cms_cust_mast.ccm_corp_code%TYPE;
       
      v_setdata_errmsg    VARCHAR2 (300);
       
      v_custrec_outdata   type_cust_rec_array;
      v_cust_id           NUMBER;
       --Sn Added for Partner ID Changes
      v_partner_id             cms_product_param.cpp_partner_id%TYPE;

      --En Added for Partner ID Changes
   BEGIN
      --Main Begin Block Starts Here
      prm_errmsg := 'OK';

      IF prm_corpcode = 0
      THEN
         v_corp := NULL;
      ELSE
         v_corp := prm_corpcode;
      END IF;

 
      -- IF DUM = 1 THEN--if 1 -- commented by Dhiraj G 23/03/2013
      BEGIN
         BEGIN
            SELECT seq_custcode.NEXTVAL
              INTO prm_custcode
              FROM DUAL;
         EXCEPTION
            WHEN OTHERS
            THEN
               prm_errmsg :=
                     'Error while selecting the value from sequence '
                  || SUBSTR (SQLERRM, 1, 200);
               RETURN;
         END;

  
         IF prm_catg_code = 'P' AND prm_custid IS NOT NULL
         THEN
            v_cust_id := prm_custid;
         ELSIF prm_catg_code = 'P' AND prm_custid IS NULL
         THEN
            BEGIN
               -- Sn; Added by sagar on 02-apr-2012 for customer id generation requirement
               SELECT seq_cust_id.NEXTVAL
                 INTO v_cust_id
                 FROM DUAL;
            EXCEPTION
               WHEN OTHERS
               THEN
                  prm_errmsg :=
                        'Error while selecting the value for customer id '
                     || SUBSTR (SQLERRM, 1, 200);
                  RETURN;
            END;
         -- Sn; Added by sagar on 02-apr-2012 for customer id generation requirement
         END IF;

         IF prm_catg_code IN ('D', 'A')
         THEN
            -- IF DEBIT THEN
            v_cust_id := prm_custid;
         END IF;

         --Sn set the generic variable
         sp_set_gen_custdata (prm_instcode,
                              prm_gen_custdata,
                              v_custrec_outdata,
                              v_setdata_errmsg
                             );

         IF v_setdata_errmsg <> 'OK'
         THEN
            prm_errmsg :=
                         'Error in set gen parameters   ' || v_setdata_errmsg;
            RETURN;
         END IF;

         --En set the generic variable

         --Sn Added for Partner ID Changes
         BEGIN
            SELECT cpp_partner_id
              INTO v_partner_id
              FROM cms_product_param
             WHERE cpp_prod_code = prm_prodcode AND cpp_inst_code = prm_instcode;
         EXCEPTION
            WHEN NO_DATA_FOUND THEN
               prm_errmsg :='Product code '|| prm_prodcode || ' is not defined in the product param master';
               return;
            WHEN OTHERS THEN
               prm_errmsg :='Error while selecting partner dtls- ' || SUBSTR (SQLERRM, 1, 200);
               return;
         END;
         --En Added for Partner ID Changes
         
         
        --Sn Added for GETTING ENCRYPT ENABLE CHANGES
         BEGIN
            SELECT cpc_encrypt_enable
              INTO v_encrypt_enable
              FROM cms_prod_cattype
             WHERE cpc_prod_code = prm_prodcode AND cpc_card_type = prm_cardtype
                    AND cpc_inst_code = prm_instcode;
         EXCEPTION            
            WHEN OTHERS THEN
               prm_errmsg :='Error while selecting CMS_PROD_CATTYPE- ' || SUBSTR (SQLERRM, 1, 200);
               return;
         END;
         --En  Added for GETTING ENCRYPT ENABLE CHANGES 

         BEGIN
            INSERT INTO cms_cust_mast
                        (ccm_inst_code, ccm_cust_code, ccm_group_code,
                         ccm_cust_type, ccm_corp_code, ccm_cust_stat,
                         ccm_salut_code, ccm_first_name,
                         ccm_mid_name, ccm_last_name, ccm_birth_date,
                         ccm_perm_id,  ccm_email_two,
                         ccm_mobl_two, ccm_ins_user,
                         ccm_lupd_user, ccm_gender_type, ccm_marital_stat,
                         ccm_ssn, ccm_mother_name, ccm_hobbies, ccm_cust_id,
                         ccm_emp_id, ccm_cust_param1,
                         ccm_cust_param2, ccm_cust_param3,
                         ccm_cust_param4, ccm_cust_param5,
                         ccm_cust_param6, ccm_cust_param7,
                         ccm_cust_param8, ccm_cust_param9,
                         ccm_cust_param10,
                         ccm_partner_id,  --Added for Partner ID Changes
                         ccm_prod_code, ccm_card_type,
                         CCM_FIRST_NAME_ENCR,CCM_LAST_NAME_ENCR
                        )
                 VALUES (prm_instcode, prm_custcode, prm_grpcode,
                         --V_GRPCODE, Commented by Dhiraj Gaikwad  23/03/2013
                         prm_custtype, v_corp, prm_custstat,
                         prm_salutcode, UPPER (prm_firstname),
                         UPPER (prm_midname), UPPER (prm_lastname), prm_dob,
                         prm_permid, prm_email2,
                         prm_mobl2, prm_lupduser,
                         prm_lupduser, prm_gender, prm_marstat,
                         prm_ssn, prm_maidname, prm_hobby, v_cust_id,
                         prm_empid, v_custrec_outdata (1),
                         v_custrec_outdata (2), v_custrec_outdata (3),
                         v_custrec_outdata (4), v_custrec_outdata (5),
                         v_custrec_outdata (6), v_custrec_outdata (7),
                         v_custrec_outdata (8), v_custrec_outdata (9),
                         v_custrec_outdata (10),
                         v_partner_id,  --Added for Partner ID Changes
                         prm_prodcode, prm_cardtype,
                         decode(v_encrypt_enable,'Y',UPPER (prm_firstname),fn_emaps_main( UPPER (prm_firstname))),
                         decode(v_encrypt_enable,'Y', UPPER (prm_lastname),fn_emaps_main( UPPER (prm_lastname)))
                        );
         EXCEPTION
            WHEN DUP_VAL_ON_INDEX
            THEN
               prm_errmsg :=
                  'Error while creating customer data in master duplicate record found ';
               RETURN;
            WHEN OTHERS
            THEN
               prm_errmsg :=
                     'Error while creating customer data in master'
                  || SUBSTR (SQLERRM, 1, 150);
               RETURN;
         END;
      END;                                                 --Begin 2 Ends Here
--  END IF; -- commented by Dhiraj G 23/03/2013
   EXCEPTION
      WHEN OTHERS
      THEN
         prm_errmsg := 'Main Exception ' || SQLCODE || '---' || SQLERRM;
   END;

--**************************************************************--
   PROCEDURE sp_create_addr_bulk (
      prm_instcode            IN       NUMBER,
      prm_custcode            IN       NUMBER,
      prm_add1                IN       VARCHAR2,
      prm_add2                IN       VARCHAR2,
      prm_add3                IN       VARCHAR2,
      prm_pincode             IN       VARCHAR2,
      prm_phon1               IN       VARCHAR2,
      prm_phon2               IN       VARCHAR2,
      prm_officno             IN       VARCHAR2,
      prm_email               IN       VARCHAR2,
      prm_cntrycode           IN       NUMBER,
      prm_cityname            IN       VARCHAR2,
      prm_switchstat          IN       VARCHAR2, --state as coming from switch
      prm_fax1                IN       VARCHAR2,
      prm_addrflag            IN       CHAR,
      prm_comm_type           IN       CHAR,
      prm_lupduser            IN       NUMBER,
      prm_genaddr_data        IN       type_addr_rec_array,
      prm_state_code          IN       gen_state_mast.gsm_state_code%TYPE,
      prm_state_switch_code   IN       gen_state_mast.gsm_switch_state_code%TYPE,
      prm_addrcode            OUT      NUMBER,
      prm_errmsg              OUT      VARCHAR2
   )
   AS
    v_addrrec_outdata        type_addr_rec_array;
    v_setaddrdata_errmsg     VARCHAR2 (500);
 
    V_PROD_CODE              CMS_CUST_MAST.CCM_PROD_CODE%TYPE;
    V_CARD_TYPE              cms_cust_mast.ccm_card_type%type;
      BEGIN
      prm_errmsg := 'OK';

      SELECT seq_addr_code.NEXTVAL
        INTO prm_addrcode
        FROM DUAL;

      sp_set_gen_addrdata (prm_instcode,
                           prm_genaddr_data,
                           v_addrrec_outdata,
                           v_setaddrdata_errmsg
                          );

      IF v_setaddrdata_errmsg <> 'OK'
      THEN
         prm_errmsg :=
                     'Error in set gen parameters   ' || v_setaddrdata_errmsg;
         RETURN;
      END IF;


      BEGIN
      SELECT CCM_PROD_CODE , CCM_CARD_TYPE
      INTO V_PROD_CODE , V_CARD_TYPE
      FROM CMS_CUST_MAST
      WHERE CCM_INST_CODE = PRM_INSTCODE
      AND CCM_CUST_CODE = PRM_CUSTCODE;
      EXCEPTION
		 WHEN NO_DATA_FOUND THEN
		   prm_errmsg  := 'Invalid Cust code' || SUBSTR (SQLERRM, 1, 200);
		   return;
		 WHEN OTHERS THEN
		   PRM_ERRMSG  := 'Error while selcting cms_cust_mast' || SUBSTR (SQLERRM, 1, 200);
		   return;
      END;
      
      BEGIN
       SELECT cpc_encrypt_enable
              INTO v_encrypt_enable
              FROM cms_prod_cattype
             WHERE cpc_prod_code = V_PROD_CODE AND cpc_card_type = V_CARD_TYPE
                    AND cpc_inst_code = prm_instcode;
      EXCEPTION		  
		 WHEN OTHERS THEN
		   PRM_ERRMSG  := 'Error while selcting CMS_PROD_CATTYPE' || SUBSTR (SQLERRM, 1, 200);
		   return;
      END;
      
      
	  BEGIN
         INSERT INTO cms_addr_mast
                     (cam_inst_code, cam_cust_code, cam_addr_code,
                      cam_add_one, cam_add_two, cam_add_three, cam_pin_code,
                      cam_phone_one, cam_phone_two, cam_mobl_one, cam_email,
                      cam_cntry_code, cam_city_name, cam_fax_one,
                      cam_addr_flag, cam_state_code, cam_ins_user,
                      cam_lupd_user, cam_comm_type, cam_state_switch,
                      cam_addrmast_param1, cam_addrmast_param2,
                      cam_addrmast_param3, cam_addrmast_param4,
                      cam_addrmast_param5, cam_addrmast_param6,
                      cam_addrmast_param7, cam_addrmast_param8,
                      cam_addrmast_param9, cam_addrmast_param10,
                      CAM_ADD_ONE_ENCR,
                      CAM_ADD_TWO_ENCR,
                      CAM_CITY_NAME_ENCR,
                      CAM_PIN_CODE_ENCR,
                      CAM_EMAIL_ENCR
                     )
              VALUES (prm_instcode, prm_custcode, prm_addrcode,
                      prm_add1, prm_add2, prm_add3, prm_pincode,
                      prm_phon1, prm_officno, prm_phon2, prm_email,
                      prm_cntrycode, prm_cityname, prm_fax1,
                      prm_addrflag, prm_state_code,                                                
                                                   prm_lupduser,
                      prm_lupduser, prm_comm_type, prm_state_switch_code,                      
                      v_addrrec_outdata (1), v_addrrec_outdata (2),
                      v_addrrec_outdata (3), v_addrrec_outdata (4),
                      v_addrrec_outdata (5), v_addrrec_outdata (6),
                      v_addrrec_outdata (7), v_addrrec_outdata (8),
                      v_addrrec_outdata (9), v_addrrec_outdata (10),
                      decode(v_encrypt_enable,'Y',prm_add1,fn_emaps_main(prm_add1)),
                      decode(v_encrypt_enable,'Y',prm_add2,fn_emaps_main(prm_add2)),
                      decode(v_encrypt_enable,'Y',prm_cityname,fn_emaps_main(prm_cityname)),
                      decode(v_encrypt_enable,'Y',prm_pincode,fn_emaps_main(prm_pincode)),
                      decode(v_encrypt_enable,'Y',prm_email,fn_emaps_main(prm_email))
                     );
      EXCEPTION
         WHEN DUP_VAL_ON_INDEX
         THEN
            prm_errmsg :=
                        'Error while creating address duplicate record found';
            RETURN;
         WHEN OTHERS
         THEN
            prm_errmsg :=
                  'Error while creating address ' || SUBSTR (SQLERRM, 1, 200);
            RETURN;
      END;
	  
	  IF PRM_ADDRFLAG = 'P' AND (FN_DMAPS_MAIN(PRM_ADD1) IS NOT NULL AND FN_DMAPS_MAIN(PRM_ADD1) <> '*') THEN
			  UPDATE CMS_CUST_MAST
								SET CCM_SYSTEM_GENERATED_PROFILE = 'N' 
								WHERE CCM_INST_CODE = prm_instcode                      
								AND CCM_CUST_CODE = prm_custcode ; 
      ELSE 
			 UPDATE CMS_CUST_MAST
							SET CCM_SYSTEM_GENERATED_PROFILE = 'Y' 
							WHERE CCM_INST_CODE = prm_instcode                      
							AND CCM_CUST_CODE = prm_custcode ; 
	  END IF;
	  
   EXCEPTION
      WHEN OTHERS
      THEN
         prm_errmsg :=
            'Main exexption ' || SQLCODE || '---' || SUBSTR (SQLERRM, 1, 200);
   END;

--**************************************************************--
   PROCEDURE sp_fetch_acctno (
      prm_instcode               IN       NUMBER,
      prm_branc_code             IN       VARCHAR2,
      prm_prod_code              IN       VARCHAR2,
      prm_lupduser               IN       NUMBER,
      prod_cattype               IN       NUMBER,
      prm_tmp_num                IN       VARCHAR2,
      prm_serl_indx              IN       NUMBER,
      prm_chk_index              IN       NUMBER,
      prm_cac_length             IN       NUMBER,
      prm_table_acct_construct   IN       PKG_STOCK.table_acct_construct,
      prm_acct_num               OUT      VARCHAR2,
      prm_errmsg                 OUT      VARCHAR2
   )
   AS
      
      
      v_errmsg                 VARCHAR2 (500);
       
      exp_reject_record        EXCEPTION;
       
      v_loop_max_cnt           NUMBER;
       
      v_tmp_acct_no            cms_appl_pan.cap_acct_no%TYPE;
       
      v_serial_maxlength       NUMBER (2);
      v_serial_no              NUMBER;
      v_check_digit            NUMBER;
      v_tmp_acct               VARCHAR2 (16);
       

      PROCEDURE lp_acct_srno (                      -- Added on 25-Mar-2013 for performance changes
         l_instcode     IN       NUMBER,
         l_lupduser     IN       NUMBER,
         l_tmp_acct     IN       VARCHAR2,
         l_max_length   IN       NUMBER,
         l_srno         OUT      VARCHAR2,
         l_errmsg       OUT      VARCHAR2
      )
      IS
         v_ctrlnumb        NUMBER;
         v_max_serial_no   NUMBER;
         resource_busy     EXCEPTION;
         PRAGMA EXCEPTION_INIT (resource_busy, -54);
         PRAGMA AUTONOMOUS_TRANSACTION;
      BEGIN
         l_errmsg := 'OK';

         IF l_tmp_acct IS NULL
         THEN
            v_tmp_acct := 'XXXX';
         ELSE
            v_tmp_acct := l_tmp_acct;
         END IF;

         SELECT     cac_ctrl_numb,
                    SUBSTR (cac_max_serial_no, 1, prm_cac_length)
               INTO v_ctrlnumb,
                    v_max_serial_no
               FROM cms_acct_ctrl
              WHERE cac_bran_code = v_tmp_acct
                    AND cac_inst_code = prm_instcode
         FOR UPDATE WAIT 1;

         IF v_ctrlnumb > LPAD ('9', l_max_length, 9)
         THEN
            l_errmsg := 'Maximum serial number reached';
            ROLLBACK;
            RETURN;
         END IF;

         l_srno := v_ctrlnumb;

         UPDATE cms_acct_ctrl
            SET cac_ctrl_numb = v_ctrlnumb +1
          WHERE cac_bran_code = v_tmp_acct AND cac_inst_code = prm_instcode;

         IF SQL%ROWCOUNT = 0
         THEN
            l_errmsg := 'Error while updating serial no';
            ROLLBACK;
            RETURN;
         END IF;

         COMMIT;
      EXCEPTION
         WHEN NO_DATA_FOUND
         THEN
            BEGIN
               INSERT INTO cms_acct_ctrl
                           (cac_inst_code, cac_bran_code, cac_ctrl_numb,
                            cac_max_serial_no
                           )
                    VALUES (1, v_tmp_acct, 2,
                            LPAD ('9', l_max_length, 9)
                           );

               v_ctrlnumb := 1;
               l_srno := v_ctrlnumb;

               COMMIT;
            EXCEPTION
               WHEN OTHERS
               THEN
                  l_errmsg :=
                         'While Inserting into CMS_ACCT_CTRL  -- ' || SQLERRM;
                  ROLLBACK;
            END;
         WHEN resource_busy
         THEN
            l_errmsg := 'PLEASE TRY AFTER SOME TIME';
            ROLLBACK;
         WHEN OTHERS
         THEN
            l_errmsg := 'Excp1 LP2 -- ' || SQLERRM;
            ROLLBACK;
      END;

      PROCEDURE lp_acct_chkdig (l_tmpacct IN VARCHAR2, l_checkdig OUT NUMBER)
      IS
         ceilable_sum   NUMBER     := 0;
         ceiled_sum     NUMBER;
         temp_acct      NUMBER;
         len_acct       NUMBER (3);
         res            NUMBER (3);
         mult_ind       NUMBER (1);
         dig_sum        NUMBER (2);
         dig_len        NUMBER (1);
      BEGIN
         temp_acct := l_tmpacct;
         len_acct := LENGTH (temp_acct);
         mult_ind := 2;

         FOR i IN REVERSE 1 .. len_acct
         LOOP
            res := SUBSTR (temp_acct, i, 1) * mult_ind;
            dig_len := LENGTH (res);

            IF dig_len = 2
            THEN
               dig_sum := SUBSTR (res, 1, 1) + SUBSTR (res, 2, 1);
            ELSE
               dig_sum := res;
            END IF;

            ceilable_sum := ceilable_sum + dig_sum;

            IF mult_ind = 2
            THEN
               mult_ind := 1;
            ELSE
               mult_ind := 2;
            END IF;
         END LOOP;

         ceiled_sum := ceilable_sum;

         IF MOD (ceilable_sum, 10) <> 0
         THEN
            LOOP
               ceiled_sum := ceiled_sum + 1;
               EXIT WHEN MOD (ceiled_sum, 10) = 0;
            END LOOP;
         END IF;

         l_checkdig := ceiled_sum - ceilable_sum;
      END;
   BEGIN
      v_table_acct_construct := prm_table_acct_construct;
      v_loop_max_cnt := v_table_acct_construct.COUNT;
      v_tmp_acct_no := prm_tmp_num;

      IF prm_serl_indx IS NOT NULL
      THEN
         v_serial_maxlength :=
                            v_table_acct_construct (prm_serl_indx).cac_length;

         lp_acct_srno (prm_instcode,            -- Added on 25-Mar-2013 for performance changes
                       prm_lupduser,
                       v_tmp_acct_no,
                       v_serial_maxlength,
                       v_serial_no,
                       v_errmsg
                      );

         IF v_errmsg <> 'OK'
         THEN
            RAISE exp_reject_record;
         END IF;

         v_table_acct_construct (prm_serl_indx).cac_field_value :=
            LPAD (SUBSTR (TRIM (v_serial_no),
                          v_table_acct_construct (prm_serl_indx).cac_start,
                          v_table_acct_construct (prm_serl_indx).cac_length
                         ),
                  v_table_acct_construct (prm_serl_indx).cac_length,
                  '0'
                 );
      END IF;

      v_tmp_acct_no := NULL;

      FOR i IN 1 .. v_loop_max_cnt
      LOOP
         FOR j IN 1 .. v_loop_max_cnt
         LOOP
            IF prm_table_acct_construct (j).cac_start_from = i
            THEN
               v_tmp_acct_no :=
                  v_tmp_acct_no || v_table_acct_construct (j).cac_field_value;
               EXIT;
            END IF;
         END LOOP;
      END LOOP;

      IF prm_chk_index = 1
      THEN
         lp_acct_chkdig (v_tmp_acct_no, v_check_digit);
         prm_acct_num := v_tmp_acct_no || v_check_digit;
      ELSE
         prm_acct_num := v_tmp_acct_no;
      END IF;

     --- DBMS_OUTPUT.put_line ('Account Number ---' || prm_acct_num);
   EXCEPTION
      WHEN exp_reject_record
      THEN
         prm_errmsg := v_errmsg;
      WHEN OTHERS
      THEN
         prm_errmsg :=
            'Error from Account Number Construct '
            || SUBSTR (SQLERRM, 1, 200);
   END;

--**************************************************************--
   PROCEDURE sp_create_acct_bulk (
      prm_instcode         IN       NUMBER,
      prm_acctno           IN       VARCHAR2,
      prm_holdcount        IN       NUMBER,
      prm_currbran         IN       VARCHAR2,
      prm_billaddr         IN       NUMBER,
      prm_accttype         IN       NUMBER,
      prm_acctstat         IN       NUMBER,
      prm_lupduser         IN       NUMBER,
      prm_gen_acctdata     IN       type_acct_rec_array,
      prm_bin                       NUMBER,
      prm_cust_id                   cms_cust_mast.ccm_cust_id%TYPE,
      prm_dup_check_flag            CHAR,
      prm_prodcode            IN VARCHAR2,
      prm_cardtype          IN NUMBER,
      prm_dup_flag         OUT      VARCHAR2,
      prm_acctid           OUT      NUMBER,
      prm_errmsg           OUT      VARCHAR2
   )
   AS
      v_acctno                cms_acct_mast.cam_acct_no%TYPE;
      uniq_excp_acctno        EXCEPTION;
      v_acctrec_outdata       type_acct_rec_array;
      v_check_skipacct        NUMBER (2);
      v_check_primaryrec      NUMBER (1);
      v_acctdata_errmsg       VARCHAR2 (500);
      v_dupacct_check         VARCHAR2 (1);
      
      v_instspecific_dupchk   VARCHAR2 (1);
      v_instspecific_errmsg   VARCHAR2 (500);
      PRAGMA EXCEPTION_INIT (uniq_excp_acctno, -00001);
   BEGIN                                        --Main Begin Block Starts Here
      --Sn get acct number
      BEGIN
         SELECT seq_acct_id.NEXTVAL
           INTO prm_acctid
           FROM DUAL;
      EXCEPTION
         WHEN OTHERS
         THEN
            prm_errmsg :=
                 'Error while selecting acctnum ' || SUBSTR (SQLERRM, 1, 200);
            RAISE uniq_excp_acctno;
      END;

      --En get acct number
      IF prm_acctno IS NULL
      THEN
         v_acctno := TRIM (prm_acctid);
      ELSIF prm_acctno IS NOT NULL
      THEN
         v_acctno := TRIM (prm_acctno);
      END IF;

      --Sn set acct data
      sp_set_gen_acctdata (prm_instcode,
                           prm_gen_acctdata,
                           v_acctrec_outdata,
                           v_acctdata_errmsg
                          );

      IF v_acctdata_errmsg <> 'OK'
      THEN
         prm_errmsg := 'Error in set gen parameters   ' || v_acctdata_errmsg;
         RETURN;
      END IF;

      --En set acct data
      IF v_acctrec_outdata IS NULL
      THEN
         INSERT INTO cms_acct_mast
                     (cam_inst_code, cam_acct_id, cam_acct_no,
                      cam_hold_count, cam_curr_bran, cam_bill_addr,
                      cam_type_code, cam_stat_code, cam_ins_user,
                      cam_lupd_user, cam_prod_code, cam_card_type
                     )
              VALUES (prm_instcode, prm_acctid, TRIM (v_acctno),
                      prm_holdcount, prm_currbran, prm_billaddr,
                      prm_accttype, prm_acctstat, prm_lupduser,
                      prm_lupduser, prm_prodcode, prm_cardtype
                     );
      ELSE
         INSERT INTO cms_acct_mast
                     (cam_inst_code, cam_acct_id, cam_acct_no,
                      cam_hold_count, cam_curr_bran, cam_bill_addr,
                      cam_type_code, cam_stat_code, cam_ins_user,
                      cam_lupd_user, cam_acct_param1,
                      cam_acct_param2, cam_acct_param3,
                      cam_acct_param4, cam_acct_param5,
                      cam_acct_param6, cam_acct_param7,
                      cam_acct_param8, cam_acct_param9,
                      cam_acct_param10, cam_prod_code, cam_card_type
                     )
              VALUES (prm_instcode, prm_acctid, TRIM (v_acctno),
                      prm_holdcount, prm_currbran, prm_billaddr,
                      prm_accttype, prm_acctstat, prm_lupduser,
                      prm_lupduser, v_acctrec_outdata (1),
                      v_acctrec_outdata (2), v_acctrec_outdata (3),
                      v_acctrec_outdata (4), v_acctrec_outdata (5),
                      v_acctrec_outdata (6), v_acctrec_outdata (7),
                      v_acctrec_outdata (8), v_acctrec_outdata (9),
                      v_acctrec_outdata (10), prm_prodcode, prm_cardtype
                     );
      END IF;

      prm_dup_flag := 'A';
      prm_errmsg := 'OK';
   EXCEPTION                                            --Main block Exception
      WHEN uniq_excp_acctno
      THEN
         prm_errmsg := 'Account No already in Master.';

         SELECT cam_acct_id
           INTO prm_acctid
           FROM cms_acct_mast
          WHERE cam_inst_code = prm_instcode
            AND cam_acct_no = TRIM (prm_acctno);

--Sn check in skip acct table
         BEGIN
            SELECT COUNT (*)
              INTO v_check_skipacct
              FROM cms_skipdup_accts
             WHERE csa_inst_code = prm_instcode AND csa_acct_no = prm_acctno;
         EXCEPTION
            WHEN OTHERS
            THEN
               prm_errmsg :=
                     'Error while selecting data from skip acct '
                  || SUBSTR (SQLERRM, 1, 200);
               RETURN;
         END;

--En check in  skip acct table
         IF v_check_skipacct > 0
         THEN
            prm_dup_flag := 'A';
            prm_errmsg := 'OK';
         ELSE
            --Sn check for card already present on this acctno
            BEGIN
 
               v_dupcheck_param_flag := prm_dup_check_flag;

               IF v_dupcheck_param_flag = 'N'
               THEN
                  RAISE NO_DATA_FOUND;
               ELSE
                  BEGIN
                     SELECT DISTINCT 1
                                INTO v_check_primaryrec
                                FROM cms_pan_acct, cms_appl_pan,
                                     cms_cust_mast
                               WHERE cpa_inst_code = prm_instcode
                                 AND cpa_acct_id = prm_acctid
                                 AND SUBSTR (cpa_pan_code, 1, 6) = prm_bin
                                 AND cap_pan_code = cpa_pan_code
                                 AND cap_mbr_numb = cpa_mbr_numb
                                 AND ccm_cust_code = cpa_cust_code
                                 AND ccm_cust_id = prm_cust_id
                                 AND cap_card_stat = '1';

                     prm_dup_flag := 'D';
                     prm_errmsg := 'OK';
                  EXCEPTION
                     WHEN NO_DATA_FOUND
                     THEN
                        sp_dup_check_acct_instspecific
                                                      (prm_instcode,
                                                       prm_acctid,
                                                       v_instspecific_dupchk,
                                                       v_instspecific_errmsg
                                                      );

                        IF v_instspecific_errmsg <> 'OK'
                        THEN
                           prm_errmsg := v_instspecific_errmsg;
                           RETURN;
                        ELSE
                           IF v_instspecific_dupchk = 'T'
                           THEN
                              prm_dup_flag := 'D';
                              prm_errmsg := 'OK';
                           ELSE
                              RAISE NO_DATA_FOUND;
                           END IF;
                        END IF;
                     WHEN OTHERS
                     THEN
                        prm_errmsg :=
                              'Error while Duplicate Account check flag from master 2 '
                           || SUBSTR (SQLERRM, 1, 150);
                        RETURN;
                  END;
               END IF;
            EXCEPTION
               WHEN NO_DATA_FOUND
               THEN
                  v_dupacct_check :=
                     fn_dup_appl_check (prm_cust_id,
                                        prm_bin,
                                        prm_acctid,
                                        prm_instcode
                                       );

                  IF v_dupacct_check = 'T'
                  THEN
                     prm_dup_flag := 'D';
                  ELSE
                     prm_dup_flag := 'A';
                  END IF;

                  prm_errmsg := 'OK';
               WHEN OTHERS
               THEN
                  prm_errmsg :=
                        'Error while checking pending appl data for duplicate acct '
                     || SUBSTR (SQLERRM, 1, 200);
                  RETURN;
            END;
         --En check for card already present on this acctno
         END IF;
      WHEN OTHERS
      THEN
         prm_errmsg := 'Main Exception ' || SQLCODE || '---' || SQLERRM;
   END;

--**************************************************************--
   PROCEDURE sp_create_holder_bulk (
      instcode   IN       NUMBER,
      custcode   IN       NUMBER,
      acctid     IN       NUMBER,
      acctname   IN       VARCHAR2,
      --billadd1     IN number, shifted to account level from holder level
      lupduser   IN       NUMBER,
      holdposn   OUT      NUMBER,
      errmsg     OUT      VARCHAR2
   )
   AS
      v_cnt         PLS_INTEGER;
   BEGIN                                        --Main Begin Block Starts Here
--this if condition commented on 20-06-02 to take in the incoming data in caf format for finacle
 -- SN  Chinmaya added: return if holder exist for the a/c
      errmsg := 'OK';

      --dbms_output.put_line('acct id is '||acctid);
       --dbms_output.put_line('cust code '||custcode);
      BEGIN
         SELECT COUNT (1)
           INTO v_cnt
           FROM cms_cust_acct
          WHERE cca_inst_code = instcode
            AND cca_cust_code = custcode
            AND cca_acct_id = acctid;

         IF v_cnt > 0
         THEN
            errmsg := 'OK';

            BEGIN
               UPDATE cms_cust_acct
                  SET cca_rel_stat = 'Y'
                WHERE cca_inst_code = instcode
                  AND cca_cust_code = custcode
                  AND cca_acct_id = acctid;
            EXCEPTION
               WHEN OTHERS
               THEN
                  errmsg :=
                        'Error while getting customer acct relation '
                     || SUBSTR (SQLERRM, 1, 200);
                  RETURN;
            END;

            RETURN;
         END IF;
         
       EXCEPTION
               WHEN OTHERS
               THEN
                  errmsg :=
                        'Error while getting customer acct count '
                     || SUBSTR (SQLERRM, 1, 200);
                RETURN;     
      END;

      -- EN Chinmaya added: return if holder exist for the a/c

      --IF instcode IS NOT NULL  AND custcode IS NOT NULL AND acctid IS NOT NULL  AND lupduser IS NOT NULL THEN
      SELECT NVL (MAX (cca_hold_posn), 0) + 1
        INTO holdposn
        FROM cms_cust_acct
       WHERE cca_inst_code = instcode AND cca_acct_id = acctid;

      /*holdposn := 0;*/
      BEGIN
         INSERT INTO cms_cust_acct
                     (cca_inst_code, cca_cust_code, cca_acct_id,
                      cca_acct_name,
                                    --CCA_BILL_ADDR1  ,
                                    cca_hold_posn, cca_rel_stat,
                      cca_ins_user, cca_lupd_user
                     )
              VALUES (instcode, custcode, acctid,
                      acctname,
                               --billadd1           ,
                               holdposn, 'Y',
                      --means that the relation is active
                      lupduser, lupduser
                     );
      EXCEPTION
         WHEN OTHERS
         THEN
            errmsg :=
                  'error while inserting data in cust acct '
               || SUBSTR (SQLERRM, 1, 200);
            RETURN;
      END;
   --errmsg := 'OK';

   --ELSE   --IF 1
   --errmsg := 'sp_create_holders expected a not null parameter';
   --END IF;   --IF 1
   EXCEPTION                                            --Main block Exception
      WHEN OTHERS
      THEN
         errmsg := 'Main Exception ' || SQLCODE || '---' || SQLERRM;
         RETURN;
   END;

--**************************************************************--
   PROCEDURE sp_tmpno_serlcnt_bulk (
      prm_instcode               IN       NUMBER,
      prm_branc_code             IN       VARCHAR2,
      prm_prod_code              IN       VARCHAR2,
      prm_prod_cattype           IN       NUMBER,
      prm_tmp_num                OUT      VARCHAR2,
      prm_serl_indx              OUT      NUMBER,
      prm_chk_index              OUT      NUMBER,
      prm_cac_length             OUT      NUMBER,
      prm_table_acct_construct   OUT      PKG_STOCK.table_acct_construct,
      prm_errmsg                 OUT      VARCHAR2
   )
   AS
      v_prod_code              cms_prod_mast.cpm_prod_code%TYPE;
      v_errmsg                 transactionlog.error_msg%type;
      
      
      v_loop_cnt               PLS_INTEGER                        DEFAULT 0;
      v_loop_max_cnt           PLS_INTEGER;
       
      v_tmp_acct_no            cms_appl_pan.cap_acct_no%TYPE;
       
      v_serial_index           PLS_INTEGER;
 
      t_cac_profile_code       cms_acct_construct.cac_profile_code%TYPE;
      t_cac_field_name         cms_acct_construct.cac_field_name%TYPE;
      t_cac_start_from         cms_acct_construct.cac_start_from%TYPE;
      t_cac_start              cms_acct_construct.cac_start%TYPE;
      t_cac_length             cms_acct_construct.cac_length%TYPE;
 
      t_cac_tot_length         cms_acct_construct.cac_tot_length%TYPE;
  
      exp_reject_record        EXCEPTION;

      CURSOR c (p_profile_code IN VARCHAR2)
      IS
         SELECT   cac_profile_code, cac_field_name, cac_start_from,
                  cac_length, cac_start, cac_tot_length
             INTO t_cac_profile_code, t_cac_field_name, t_cac_start_from,
                  t_cac_length, t_cac_start, t_cac_tot_length
             FROM cms_acct_construct
            WHERE cac_profile_code = p_profile_code
              AND cac_inst_code = prm_instcode
         ORDER BY cac_start_from DESC;
   BEGIN
      prm_errmsg := 'OK';

      BEGIN
        SELECT cattype.cpc_profile_code
        INTO v_profile_code
        FROM cms_prod_cattype CATTYPE, cms_prod_mast PROD
       WHERE cattype.cpc_inst_code = prm_instcode
         AND cattype.cpc_inst_code = prod.cpm_inst_code
         AND cattype.cpc_prod_code = prm_prod_code
         AND cattype.cpc_card_type = prm_prod_cattype
         AND prod.cpm_prod_code = cattype.cpc_prod_code;
      EXCEPTION
         WHEN NO_DATA_FOUND
         THEN
            v_errmsg :=
                  'Profile code not defined for product code ' || v_prod_code;
            RAISE exp_reject_record;
         WHEN OTHERS
         THEN
            v_errmsg :=
                  'Error while selecting applcode from applmast'
               || SUBSTR (SQLERRM, 1, 300);
            RAISE exp_reject_record;
      END;

      BEGIN
         SELECT cac_length
           INTO prm_cac_length
           FROM cms_acct_construct
          WHERE cac_profile_code = v_profile_code
            AND cac_inst_code = prm_instcode
            AND cac_field_name = 'Serial Number';
      EXCEPTION
         WHEN NO_DATA_FOUND
         THEN
            v_errmsg :=
                  'Profile code not defined for product code ' || v_prod_code;
            RAISE exp_reject_record;
         WHEN OTHERS
         THEN
            v_errmsg :=
                  'Error while selecting applcode from applmast'
               || SUBSTR (SQLERRM, 1, 300);
            RAISE exp_reject_record;
      END;

      BEGIN
         v_loop_cnt := 0;

         FOR i IN c (v_profile_code)
         LOOP
            v_loop_cnt := v_loop_cnt + 1;

            SELECT i.cac_profile_code,
                   i.cac_field_name,
                   i.cac_start_from,
                   i.cac_length,
                   i.cac_start,
                   i.cac_tot_length
              INTO v_table_acct_construct (v_loop_cnt).cac_profile_code,
                   v_table_acct_construct (v_loop_cnt).cac_field_name,
                   v_table_acct_construct (v_loop_cnt).cac_start_from,
                   v_table_acct_construct (v_loop_cnt).cac_length,
                   v_table_acct_construct (v_loop_cnt).cac_start,
                   v_table_acct_construct (v_loop_cnt).cac_tot_length
              FROM DUAL;
         END LOOP;
      EXCEPTION
         WHEN OTHERS
         THEN
            v_errmsg :=
                  'Error while selecting profile detail from profile mast '
               || SUBSTR (SQLERRM, 1, 300);
            RAISE exp_reject_record;
      END;

      BEGIN
         v_loop_max_cnt := v_table_acct_construct.COUNT;
         v_tmp_acct_no := NULL;

         FOR i IN 1 .. v_loop_max_cnt
         LOOP
            IF v_table_acct_construct (i).cac_field_name = 'Branch'
            THEN
               v_table_acct_construct (i).cac_field_value :=
                  LPAD (SUBSTR (TRIM (prm_branc_code),
                                v_table_acct_construct (i).cac_start,
                                v_table_acct_construct (i).cac_length
                               ),
                        v_table_acct_construct (i).cac_length,
                        '0'
                       );
            ELSIF v_table_acct_construct (i).cac_field_name = 'Product Prefix'
            THEN
               BEGIN
                  SELECT cpc_acct_prod_prefix
                    INTO v_prod_prefix
                    FROM cms_prod_cattype
                   WHERE cpc_prod_code = prm_prod_code
                     AND cpc_card_type = prm_prod_cattype;
               EXCEPTION
                  WHEN NO_DATA_FOUND
                  THEN
                     v_errmsg :=
                           'Data not available in cms_prod_cattype for product code'
                        || prm_prod_code;
                     RAISE exp_reject_record;
                  WHEN OTHERS
                  THEN
                     v_errmsg :=
                           'Error while selecting Account Product Category Prefix from cms_prod_cattype '
                        || SUBSTR (SQLERRM, 1, 300);
                     RAISE exp_reject_record;
               END;

               IF v_prod_prefix IS NULL
               THEN
                  BEGIN
                     SELECT cip_param_value
                       INTO v_prod_prefix
                       FROM cms_inst_param
                      WHERE cip_inst_code = prm_instcode
                        AND cip_param_key = 'ACCTPRODCATPREFIX';
                  EXCEPTION
                     WHEN NO_DATA_FOUND
                     THEN
                        v_errmsg :=
                           'Data not available in CMS_INST_PARAM for paramkey ACCTPRODCATPREFIX';
                        RAISE exp_reject_record;
                     WHEN OTHERS
                     THEN
                        v_errmsg :=
                              'Error while selecting Account Product Category Prefix from CMS_INST_PARAM '
                           || SUBSTR (SQLERRM, 1, 300);
                        RAISE exp_reject_record;
                  END;
               END IF;

               v_table_acct_construct (i).cac_field_value :=
                  LPAD (SUBSTR (TRIM (v_prod_prefix),
                                v_table_acct_construct (i).cac_start,
                                v_table_acct_construct (i).cac_length
                               ),
                        v_table_acct_construct (i).cac_length,
                        '0'
                       );
            ELSIF v_table_acct_construct (i).cac_field_name = 'Check Digit'
            THEN
               v_chk_index := 1;
            ELSE
               IF v_table_acct_construct (i).cac_field_name <>
                                                              'Serial Number'
               THEN
                  v_errmsg :=
                        'Account Number construct '
                     || v_table_acct_construct (i).cac_field_name
                     || ' not exist ';
                  RAISE exp_reject_record;
               END IF;
            END IF;
         END LOOP;
      EXCEPTION
         WHEN exp_reject_record
         THEN
            RAISE;
         WHEN OTHERS
         THEN
            v_errmsg :=
                'Error from Account gen process ' || SUBSTR (SQLERRM, 1, 300);
            RAISE exp_reject_record;
      END;

      FOR i IN 1 .. v_loop_max_cnt
      LOOP
         --<< i loop >>
         FOR j IN 1 .. v_loop_max_cnt
         LOOP
            --<< j  loop >>
            IF     v_table_acct_construct (j).cac_start_from = i
               AND v_table_acct_construct (j).cac_field_name <>
                                                               'Serial Number'
            THEN
               v_tmp_acct_no :=
                  v_tmp_acct_no || v_table_acct_construct (j).cac_field_value;
               prm_tmp_num := v_tmp_acct_no;
               EXIT;
            END IF;
         END LOOP;
      END LOOP;

      FOR i IN 1 .. v_table_acct_construct.COUNT
      LOOP
         IF v_table_acct_construct (i).cac_field_name = 'Serial Number'
         THEN
            v_serial_index := i;
         END IF;
      END LOOP;

      prm_chk_index := v_chk_index;
      prm_serl_indx := v_serial_index;
      prm_table_acct_construct := v_table_acct_construct;
--      DBMS_OUTPUT.put_line ('Serial Index ---' || prm_serl_indx);
--      DBMS_OUTPUT.put_line ('CPC Length ---' || prm_cac_length);
--      DBMS_OUTPUT.put_line ('Check Index ---' || prm_chk_index);
   EXCEPTION
      WHEN OTHERS
      THEN
         prm_errmsg := 'Main Exception From SP_TMPNO_SERLCNT -- ' || SQLERRM;
   END;

--**************************************************************--
   PROCEDURE lp_cms_error_log (
      p_inst_code     IN       NUMBER,
      p_file_name     IN       VARCHAR2,
      p_row_id        IN       VARCHAR2,
      p_error_mesg    IN       VARCHAR2,
      p_lupd_user     IN       NUMBER,
      p_lupd_date     IN       DATE,
      p_prob_action   IN       VARCHAR2,
      p_errmsg        OUT      VARCHAR2
   )
   AS
      PRAGMA AUTONOMOUS_TRANSACTION;
   BEGIN
         p_errmsg:=p_error_mesg;
   --   DBMS_OUTPUT.put_line ('EROROOROROOROROOR---' || p_error_mesg);

      INSERT INTO cms_error_log
                  (cel_inst_code, cel_file_name, cel_row_id, cel_error_mesg,
                   cel_lupd_user, cel_lupd_date, cel_prob_action
                  )
           VALUES (p_inst_code, p_file_name, p_row_id, p_error_mesg,
                   p_lupd_user, p_lupd_date, p_prob_action
                  );

      COMMIT;
   EXCEPTION
      WHEN OTHERS
      THEN
         p_errmsg := 'Error from ' || SQLERRM;
  --       DBMS_OUTPUT.put_line ('EROROOROROOROROOR---' || p_errmsg);

         INSERT INTO cms_error_log
                     (cel_inst_code, cel_file_name, cel_row_id,
                      cel_error_mesg, cel_lupd_user, cel_lupd_date,
                      cel_prob_action
                     )
              VALUES (p_inst_code, p_file_name, p_row_id,
                      p_error_mesg, p_lupd_user, p_lupd_date,
                      'Error in procedure LP_CMS_ERROR_LOG'
                     );

         COMMIT;
   END lp_cms_error_log;

--
BEGIN
   p_errmsg := 'OK';

   FOR x IN c2 (p_filename)
   LOOP
      EXIT WHEN v_cnt > 1;

      BEGIN
         /* SN Commented part of  SP_CREATE_CUST */
         BEGIN
            SELECT 1
              INTO v_inst_prsnt
              FROM cms_inst_mast
             WHERE cim_inst_code = p_instcode;
         EXCEPTION
            WHEN NO_DATA_FOUND
            THEN
               p_errmsg :=
                     'No such Institution '
                  || p_instcode
                  || ' exists in Institution master ';
               RAISE excp_movetohist;
            WHEN OTHERS
            THEN
               p_errmsg := 'Exception 1 ' || SQLCODE || '---' || SQLERRM;
               RAISE excp_movetohist;
         END;

         BEGIN
            SELECT MIN (ccg_group_code)
              INTO v_grpcode
              FROM cms_cust_group
             WHERE ccg_inst_code = p_instcode;

            IF v_grpcode IS NULL
            THEN
               v_grpcode := 1;

               BEGIN
                  INSERT INTO cms_cust_group
                              (ccg_inst_code, ccg_group_code,
                               ccg_group_desc, ccg_ins_user, ccg_ins_date,
                               ccg_lupd_user, ccg_lupd_date
                              )
                       VALUES (p_instcode, v_grpcode,
                               'DEFAULT GROUP', p_lupduser, SYSDATE,
                               p_lupduser, SYSDATE
                              );
               EXCEPTION
                  WHEN OTHERS
                  THEN
                     p_errmsg :=
                           'Error while inserting data for customer group '
                        || SUBSTR (SQLERRM, 1, 200);
                     RAISE excp_movetohist;
               END;
            END IF;
         EXCEPTION
            WHEN excp_movetohist
            THEN
               RAISE;
            WHEN OTHERS
            THEN
               p_errmsg :=
                     'Error while fetching group code '
                  || SUBSTR (SQLERRM, 1, 200);
               RAISE excp_movetohist;
         END;

         
         /* SN Commented above procedure from SP_CREATE_ADDR and finding the state swith code and state by below two queries  */
         BEGIN
            SELECT gsm_state_code
              INTO v_state_code
              FROM gen_state_mast
             WHERE gsm_switch_state_code = x.cci_seg12_state
               AND gsm_inst_code = p_instcode
               AND gsm_cntry_code = x.cci_seg12_country_code;

            v_swich_state_code := x.cci_seg12_state;
         EXCEPTION
            WHEN NO_DATA_FOUND
            THEN
               BEGIN
                  SELECT gsm_switch_state_code
                    INTO v_swich_state_code
                    FROM gen_state_mast
                   WHERE gsm_state_code = x.cci_seg12_state
                     AND gsm_inst_code = p_instcode
                     AND gsm_cntry_code = x.cci_seg12_country_code;

                  v_state_code := x.cci_seg12_state;
               EXCEPTION
                  WHEN NO_DATA_FOUND
                  THEN
                     p_errmsg := ' State data not defined in master';
                     RAISE excp_movetohist;
                  WHEN INVALID_NUMBER
                  THEN
                     p_errmsg := 'Not a valid state data';
                     RAISE excp_movetohist;
                  WHEN OTHERS
                  THEN
                     p_errmsg :=
                           'Error while selecting state detail data'
                        || SUBSTR (SQLERRM, 1, 200);
                     RAISE excp_movetohist;
               END;
            WHEN excp_movetohist
            THEN
               RAISE;
            WHEN OTHERS
            THEN
               p_errmsg :=
                     'Error while selecting state detail data'
                  || SUBSTR (SQLERRM, 1, 200);
               RAISE excp_movetohist;
         END;

         /* END Commented above procedure from SP_CREATE_ADDR and finding the state swith code and state by below two queries  */
         BEGIN
            SELECT cip_param_value
              INTO v_dupcheck_param_flag
              FROM cms_inst_param
             WHERE cip_param_key = 'DUP_ACCT_CHECK'
               AND cip_inst_code = p_instcode;
         EXCEPTION
            WHEN NO_DATA_FOUND
            THEN
               p_errmsg :=
                  'Duplicate Account check flag for institute is not defined in master  ';
               RAISE excp_movetohist;
            WHEN OTHERS
            THEN
               p_errmsg :=
                     'Error while Duplicate Account check flag from master 1 '
                  || SUBSTR (SQLERRM, 1, 150);
               RAISE excp_movetohist;
         END;

         BEGIN
            SELECT 1
              INTO v_check_branch
              FROM cms_bran_mast
             WHERE cbm_bran_code = x.cci_fiid
               AND cbm_sale_trans = 1
               AND cbm_inst_code = p_instcode;
         EXCEPTION
            WHEN NO_DATA_FOUND
            THEN
               p_errmsg := 'Branch is not allowed for new card issuance ';
               RAISE excp_movetohist;
            WHEN OTHERS
            THEN
               p_errmsg :=
                     'Branch is not allowed for new card issuance'
                  || SUBSTR (SQLERRM, 1, 200);
               RAISE excp_movetohist;
         END;

         BEGIN
            SELECT cat_type_code
              INTO v_cat_type_code
              FROM cms_acct_type
             WHERE cat_inst_code = p_instcode
               AND cat_switch_type = x.cci_seg31_typ;
         EXCEPTION
            WHEN OTHERS
            THEN
               p_errmsg :=
                     'Error while selecting CMS_ACCT_TYPE '
                  || SUBSTR (SQLERRM, 1, 200);
               RAISE excp_movetohist;
         END;

         BEGIN
            SELECT cas_stat_code
              INTO v_cas_stat_code
              FROM cms_acct_stat
             WHERE cas_inst_code = p_instcode
               AND cas_switch_statcode = x.cci_seg31_stat;
         EXCEPTION
            WHEN OTHERS
            THEN
               p_errmsg :=
                     'Error while selecting CMS_ACCT_STAT '
                  || SUBSTR (SQLERRM, 1, 200);
               RAISE excp_movetohist;
         END;

         BEGIN
            SELECT ccc_catg_code, ccc_catg_sname
              INTO v_custcatg_code, v_custcatg
              FROM cms_cust_catg
             WHERE ccc_catg_sname = x.cci_cust_catg
               AND ccc_inst_code = p_instcode;
         EXCEPTION
            WHEN NO_DATA_FOUND
            THEN
               BEGIN
                  sp_set_custcatg (p_instcode,
                                   x.cci_cust_catg,
                                   p_lupduser,
                                   v_custcatg_code,
                                   p_errmsg
                                  );

                  IF p_errmsg <> 'OK'
                  THEN
                     RAISE excp_movetohist;
                  END IF;
               EXCEPTION
                  WHEN excp_movetohist
                  THEN
                     RAISE;
                  WHEN OTHERS
                  THEN
                     p_errmsg :=
                           'Error while creating cust catg '
                        || SUBSTR (SQLERRM, 1, 200);
                     RAISE excp_movetohist;
               END;
            WHEN OTHERS
            THEN
               p_errmsg :=
                     'Error while selecting customer category'
                  || SUBSTR (SQLERRM, 1, 200);
               RAISE excp_movetohist;
         END;

         BEGIN
            SELECT cbm_bin_stat
              INTO v_check_bin_stat
              FROM cms_bin_mast
             WHERE cbm_inst_bin = x.cci_pan_code
                   AND cbm_inst_code = p_instcode;

            IF v_check_bin_stat NOT IN ('0', '1')
            THEN
               p_errmsg := 'Not a active Bin ' || x.cci_pan_code;
               RAISE excp_movetohist;
            END IF;
         EXCEPTION
            WHEN excp_movetohist
            THEN
               RAISE;
            WHEN NO_DATA_FOUND
            THEN
               p_errmsg :=
                          'Bin ' || x.cci_pan_code || ' not found in master ';
               RAISE excp_movetohist;
            WHEN OTHERS
            THEN
               p_errmsg :=
                     'Error while selecting bin details from master '
                  || SUBSTR (SQLERRM, 1, 200);
               RAISE excp_movetohist;
         END;

         BEGIN
            SELECT cpm_catg_code
              INTO v_catg_code
              FROM cms_prod_mast
             WHERE cpm_inst_code = p_instcode
               AND cpm_prod_code = x.cci_prod_code
               AND cpm_marc_prod_flag = 'N';
         EXCEPTION
            WHEN NO_DATA_FOUND
            THEN
               p_errmsg :=
                     'Product code'
                  || x.cci_prod_code
                  || 'is not defined in the master';
               RAISE excp_movetohist;
            WHEN OTHERS
            THEN
               p_errmsg :=
                  'Error while selecting product '
                  || SUBSTR (SQLERRM, 1, 200);
               RAISE excp_movetohist;
         END;

         BEGIN
            SELECT cpm_interchange_code
              INTO v_cpm_interchange_code
              FROM cms_prodtype_map
             WHERE cpm_inst_code = p_instcode
               AND cpm_prod_b24 = TRIM (x.cci_crd_typ);
         EXCEPTION
            WHEN NO_DATA_FOUND
            THEN
               p_errmsg := 'Unable to Fetch InterChange code' || SQLERRM;
               RAISE excp_movetohist;
            WHEN OTHERS
            THEN
               p_errmsg :=
                          'Error while selecting CMS_PRODTYPE_MAP' || SQLERRM;
               RAISE excp_movetohist;
         END;

         BEGIN
            SELECT cpb_prod_code
              INTO v_cpb_prod_code
              FROM cms_prod_bin
             WHERE cpb_inst_code = p_instcode
               AND cpb_inst_bin = x.cci_pan_code
               AND cpb_interchange_code = v_cpm_interchange_code
               AND cpb_active_bin = 'Y';
         EXCEPTION
            WHEN NO_DATA_FOUND
            THEN
               p_errmsg := 'Unable to Fetch Poduct Code' || SQLERRM;
               RAISE excp_movetohist;
            WHEN OTHERS
            THEN
               p_errmsg := 'Error while selecting CMS_PROD_BIN' || SQLERRM;
               RAISE excp_movetohist;
         END;

         IF x.cci_cust_catg = '*' OR x.cci_cust_catg IS NULL
         THEN
            v_ccc_catg_code := 1;
         ELSE
            BEGIN
               SELECT ccc_catg_code
                 INTO v_ccc_catg_code
                 FROM cms_cust_catg
                WHERE ccc_inst_code = p_instcode
                  AND ccc_catg_sname = x.cci_cust_catg;
            EXCEPTION
               WHEN OTHERS
               THEN
                  p_errmsg :=
                             'Error while selecting CMS_CUST_CATG' || SQLERRM;
                  RAISE excp_movetohist;
            END;
         END IF;

         v_prodcattype := x.cci_card_type;

         BEGIN
            SELECT 1
              INTO v_dum
              FROM cms_prod_ccc
             WHERE cpc_inst_code = p_instcode
               AND cpc_cust_catg = v_ccc_catg_code
               AND cpc_prod_code = v_cpb_prod_code
               AND cpc_card_type = v_prodcattype;
         EXCEPTION
            WHEN NO_DATA_FOUND
            THEN
               BEGIN
                  sp_create_prodccc (p_instcode,
                                     v_ccc_catg_code,
                                     v_prodcattype,
                                     v_cpb_prod_code,
                                     NULL,
                                     NULL,
                                        v_cpb_prod_code
                                     || '_'
                                     || v_prodcattype
                                     || '_'
                                     || v_ccc_catg_code,
                                     p_lupduser,
                                     p_errmsg
                                    );

                  IF p_errmsg <> 'OK'
                  THEN
                     p_errmsg :=
                           'Problem while attaching cust catg for pan '
                        || x.cci_row_id
                        || '-'
                        || p_errmsg;
                     RAISE excp_movetohist;
                  END IF;
               EXCEPTION
                  WHEN excp_movetohist
                  THEN
                     RAISE;
                  WHEN OTHERS
                  THEN
                     p_errmsg :=
                           'Error while calling SP_CREATE_PRODCCC'
                        || SUBSTR (SQLERRM, 1, 200);
                     RAISE excp_movetohist;
               END;
            WHEN OTHERS
            THEN
               p_errmsg :=
                     'Error while selecting CMS_PROD_CCC'
                  || SUBSTR (SQLERRM, 1, 200);
               RAISE excp_movetohist;
         END;

 
         BEGIN
            SELECT cattype.cpc_profile_code, prod.cpm_profile_code,prod.cpm_catg_code,
                   cattype.cpc_prod_prefix, cattype.cpc_program_id, 
                   cattype.cpc_starter_card,cattype.cpc_exp_date_exemption,
                   NVL(cattype.cpc_expdate_randomization,'N'), NVL(cattype.cpc_sweep_flag,'N')   --Added for VMS-7342
              INTO v_profile_code_catg, v_profile_code, v_cpm_catg_code,
                   v_prod_prefix, v_programid, v_starter_card,v_exp_date_exemption,
                    v_isexpry_randm,v_sweep_flag   --Added for VMS-7342
              FROM cms_prod_cattype cattype, cms_prod_mast prod
             WHERE cattype.cpc_inst_code = p_instcode
               AND cattype.cpc_inst_code = prod.cpm_inst_code
               AND cattype.cpc_prod_code = x.cci_prod_code
               AND cattype.cpc_card_type = x.cci_card_type
               AND prod.cpm_prod_code = cattype.cpc_prod_code;
         EXCEPTION
            WHEN NO_DATA_FOUND
            THEN
               p_errmsg :=
                     'Profile code not defined for product code '
                  || x.cci_prod_code
                  || 'card type '
                  || x.cci_card_type;
               RAISE excp_movetohist;
            WHEN OTHERS
            THEN
               p_errmsg :=
                     'Error while selecting applcode from applmast'
                  || SUBSTR (SQLERRM, 1, 300);
               RAISE excp_movetohist;
         END;

         BEGIN

            vmsfunutilities.get_expiry_date(p_instcode,x.cci_prod_code,
            x.cci_card_type,v_profile_code_catg,v_expry_date,p_errmsg);
	 
            if p_errmsg<>'OK' then
                     RAISE excp_movetohist;
            END IF;
               EXCEPTION
            when excp_movetohist then
                     RAISE;

         
         
         
            WHEN others THEN
                p_errmsg:='Error while calling vmsfunutilities.get_expiry_date'||substr(sqlerrm,1,200);
                RAISE excp_movetohist;  
         END;
         
        --SN: Added for VMS-7342     
        BEGIN
            SELECT COUNT (*)
              INTO v_qntity
              FROM cms_caf_info_temp
             WHERE     cci_inst_code = p_instcode
                   AND cci_file_name = p_filename
                   AND cci_upld_stat = 'B';
        EXCEPTION
            WHEN OTHERS THEN
                p_errmsg := 'Error while getting total qntity-' || SUBSTR (SQLERRM, 1, 200);
                RAISE excp_movetohist;
        END;

        IF v_isexpry_randm = 'Y' AND v_sweep_flag='N' THEN
            BEGIN
                vmscms.vmsfunutilities.get_expiry_date (p_instcode,
                                                        x.cci_prod_code,
                                                        x.cci_card_type,
                                                        v_profile_code_catg,
                                                        v_qntity,
                                                        v_expry_arry,
                                                        p_errmsg);

                IF p_errmsg <> 'OK' THEN
                    RAISE excp_movetohist;
                END IF;
            EXCEPTION
                WHEN excp_movetohist THEN
                    RAISE;
                WHEN OTHERS THEN
                    p_errmsg := 'Error while calling get_expiry_date_1' || SUBSTR (SQLERRM, 1, 200);
                    RAISE excp_movetohist;
            END;
        ELSE
            SELECT v_expry_date
              BULK COLLECT INTO v_expry_arry
              FROM DUAL
            CONNECT BY LEVEL <= v_qntity;
        END IF;
        --EN: Added for VMS-7342


         BEGIN
            sp_tmpno_serlcnt_bulk (p_instcode,
                                   x.cci_fiid,
                                   x.cci_prod_code,
                                   x.cci_card_type,
                                   v_tmp_num,
                                   v_serl_indx,
                                   v_chk_index,
                                   v_cac_length,
                                   v_table_acct_construct,
                                   p_errmsg
                                  );

            IF p_errmsg <> 'OK'
            THEN
               p_errmsg :=
                     'From  sp_tmpno_serlcnt_bulk  '
                  || p_errmsg
                  || ' for file '
                  || p_filename;
               RAISE excp_movetohist;
            END IF;
         EXCEPTION
            WHEN excp_movetohist
            THEN
               RAISE;
            WHEN OTHERS
            THEN
               p_errmsg :=
                       'Error while calling sp_tmpno_serlcnt_bulk ' || SQLERRM;
               RAISE excp_movetohist;
         END;
      EXCEPTION
         WHEN excp_movetohist
         THEN
            lp_cms_error_log (p_instcode,
                              p_filename,
                              x.cci_row_id,
                              p_errmsg,
                              p_lupduser,
                              SYSDATE,
                              'Contact Site Administrator',
                              p_errmsg
                             );
            RETURN;
         WHEN OTHERS
         THEN
            lp_cms_error_log (p_instcode,
                              p_filename,
                              x.cci_row_id,
                              p_errmsg,
                              p_lupduser,
                              SYSDATE,
                              'Contact Site Administrator',
                              p_errmsg
                             );
            RETURN;
      END;

      v_cnt := v_cnt + 1;
   END LOOP;

   v_cust_data := type_cust_rec_array ();
   v_addr_data1 := type_addr_rec_array ();
   v_addr_data2 := type_addr_rec_array ();
   v_appl_data := type_appl_rec_array ();
   v_seg31acctnum_data := type_acct_rec_array ();
   
   FOR y IN c2 (p_filename)                              --loop 2 for cursor 2
   LOOP
      BEGIN
         v_cust_data.DELETE;
         v_addr_data1.DELETE;
         v_addr_data2.DELETE;
         v_seg31acctnum_data.DELETE;
         v_appl_data.DELETE;
         v_cntr := v_cntr+1; --VMS-7342 Changes

 
         IF y.cci_seg12_cardholder_title = '0'
         THEN
            v_salutcode := NULL;
         ELSIF y.cci_seg12_cardholder_title = '1'
         THEN
            v_salutcode := 'Mr.';
         ELSIF y.cci_seg12_cardholder_title = '2'
         THEN
            v_salutcode := 'Mrs.';
         ELSIF y.cci_seg12_cardholder_title = '3'
         THEN
            v_salutcode := 'Miss';
         ELSIF y.cci_seg12_cardholder_title = '4'
         THEN
            v_salutcode := 'Ms.';
         ELSIF y.cci_seg12_cardholder_title = '5'
         THEN
            v_salutcode := 'Dr.';
         ELSE
            v_salutcode := NULL;
         END IF;

         --Sn assign records to customer gen variable
         BEGIN
            SELECT type_cust_rec_array (y.cci_customer_param1,
                                        y.cci_customer_param2,
                                        y.cci_customer_param3,
                                        y.cci_customer_param4,
                                        y.cci_customer_param5,
                                        y.cci_customer_param6,
                                        y.cci_customer_param7,
                                        y.cci_customer_param8,
                                        y.cci_customer_param9,
                                        y.cci_customer_param10
                                       )
              INTO v_cust_data
              FROM DUAL;
         EXCEPTION
            WHEN OTHERS
            THEN
               p_errmsg :=
                  'Error while cutomer gen data ' || SUBSTR (SQLERRM, 1, 200);
               RAISE excp_movetohist;
         END;

 
         BEGIN
 
            sp_create_cust_bulk
                          (p_instcode,
                           1,
                           0,
                           'Y',
                           v_salutcode,
                           y.cci_seg12_name_line1,
                           NULL,
                           ' ',
                           --TO_DATE ('15-AUG-1947', 'DD-MON-YYYY'), -- Commented on 28-Mar-2013
                           TO_DATE ('01-JAN-1900', 'DD-MON-YYYY'),   -- Added on 28-Mar-2013
                           'M',
                           NULL,
                           NULL,
                           NULL,
                           NULL,
                           NULL,
                           NULL,
                           p_lupduser,
                           NULL,
                           NULL,
                           NULL,
                           NULL,
                           --'D',      -- commented by sagar ON 06APR2012 to remove hardcoding for product catg code
                           v_catg_code,
-- product catg code is passed using varible value from cms_prod_mast --sagar - 06Apr2012
                           NULL,
                           v_inst_prsnt, --Added by Dhiraj Gaikwad  23/03/2013
                           v_grpcode,    --Added by Dhiraj Gaikwad  23/03/2013
                           v_cust_data,
                           y.cci_prod_code,  --Added for Partner ID Changes
                           y.cci_card_type,
                           v_cust,
                           p_errmsg
                          );

            IF p_errmsg <> 'OK'
            THEN
               p_errmsg :=
                     'From sp_create_cust '
                  || p_errmsg
                  || ' for file '
                  || p_filename
                  || ' and row id '
                  || y.cci_row_id;
               RAISE excp_movetohist;
            END IF;
         EXCEPTION
            WHEN excp_movetohist
            THEN                                        --added on 14-Jul-2012
               RAISE;
            WHEN OTHERS
            THEN
               p_errmsg := 'Error while calling SP_CREATE_CUST ' || SQLERRM;
               RAISE excp_movetohist;
         END;

         IF p_errmsg = 'OK'
         THEN
            BEGIN
               SELECT type_addr_rec_array (
                                           --Sn select addrss seg12 detail
                                           y.cci_seg12_addr_param1,
                                           y.cci_seg12_addr_param2,
                                           y.cci_seg12_addr_param3,
                                           y.cci_seg12_addr_param4,
                                           y.cci_seg12_addr_param5,
                                           y.cci_seg12_addr_param6,
                                           y.cci_seg12_addr_param7,
                                           y.cci_seg12_addr_param8,
                                           y.cci_seg12_addr_param9,
                                           y.cci_seg12_addr_param10
                                          )
                 INTO v_addr_data1
                 FROM DUAL;
            EXCEPTION
               WHEN OTHERS
               THEN
                  p_errmsg :=
                        'Error while address gen data '
                     || SUBSTR (SQLERRM, 1, 200);
                  RAISE excp_movetohist;
            END;

            --En select ddrss seg12 detail
            BEGIN
 
               sp_create_addr_bulk
                    (p_instcode,
                     v_cust,
                     y.cci_seg12_addr_line1,
                     y.cci_seg12_addr_line2,
                     y.cci_seg12_name_line2,
                     y.cci_seg12_postal_code,
                     y.cci_seg12_open_text1,
                     NULL,
                     NULL,
                     NULL,
                     y.cci_seg12_country_code,
                     y.cci_seg12_city,
                     y.cci_seg12_state,
                     NULL,
                     'P',
                     'R',
                     p_lupduser,
                     v_addr_data1,
                     v_state_code,       --Added by Dhiraj Gaikwad  23/03/2013
                     v_swich_state_code, --Added by Dhiraj Gaikwad  23/03/2013
                     v_addrcode,
                     p_errmsg
                    );

               IF p_errmsg <> 'OK'
               THEN
                  p_errmsg :=
                        'From sp_create_addr '
                     || p_errmsg
                     || ' for file '
                     || p_filename
                     || ' and row id '
                     || y.cci_row_id;
                  RAISE excp_movetohist;
               END IF;
            EXCEPTION
               WHEN excp_movetohist
               THEN                                     --added on 14-Jul-2012
                  RAISE;
               WHEN OTHERS
               THEN
                  p_errmsg :=
                             'Error while calling SP_CREATE_ADDR ' || SQLERRM;
                  RAISE excp_movetohist;
            END;
         END IF;

         BEGIN
            sp_fetch_acctno (p_instcode,
                             y.cci_fiid,
                             y.cci_prod_code,
                             p_lupduser,
                             y.cci_card_type,
                             v_tmp_num,
                             v_serl_indx,
                             v_chk_index,
                             v_cac_length,
                             v_table_acct_construct,
                             v_acct_num,
                             p_errmsg
                            );

            IF p_errmsg <> 'OK'
            THEN
               p_errmsg :=
                     'From sp_create_acct_bulk '
                  || p_errmsg
                  || ' for file '
                  || p_filename;
               RAISE excp_movetohist;
            END IF;
         EXCEPTION
            WHEN excp_movetohist
            THEN                                        --added on 14-Jul-2012
               RAISE;
            WHEN OTHERS
            THEN
               p_errmsg :=
                     'Error while calling SP_CREATE_ACCT '
                  || SUBSTR (SQLERRM, 1, 200);
               RAISE excp_movetohist;
         END;

         BEGIN
            sp_create_acct_bulk (p_instcode,
                                 v_acct_num,                --v_cci_seg31_num,
                                 1,
                                 y.cci_fiid,
                                 v_addrcode,
                                 v_cat_type_code,
                                 v_cas_stat_code,
                                 p_lupduser,
                                 y.seg31acctnum_data,
                                 y.cci_pan_code,
                                 NULL,
                                 v_dupcheck_param_flag,
                                 y.cci_prod_code,
                                 y.cci_card_type,
                                 v_dup_flag,
                                 v_acctid,
                                 p_errmsg
                                );

            IF p_errmsg <> 'OK'
            THEN
               p_errmsg :=
                     'From sp_create_acct_bulk '
                  || p_errmsg
                  || ' for file '
                  || p_filename;
               RAISE excp_movetohist;
            END IF;
         EXCEPTION
            WHEN excp_movetohist
            THEN                                        --added on 14-Jul-2012
               RAISE;
            WHEN OTHERS
            THEN
               p_errmsg :=
                     'Error while calling SP_CREATE_ACCT '
                  || SUBSTR (SQLERRM, 1, 200);
               RAISE excp_movetohist;
         END;

         BEGIN
            UPDATE cms_acct_mast
               SET cam_hold_count = cam_hold_count + 1,
                   cam_lupd_user = p_lupduser
             WHERE cam_inst_code = p_instcode
                   AND cam_acct_no = y.cci_seg31_num;
         EXCEPTION
            WHEN OTHERS
            THEN
               p_errmsg :=
                     'Error while updating CMS_ACCT_MAST '
                  || SUBSTR (SQLERRM, 1, 200);
               RAISE excp_movetohist;
         END;

         --now attach the account to the customer(create holder)
         IF p_errmsg = 'OK'
         THEN
            --  dbms_output.put_line('Before calling Sp create Holder -->'||lperr);
            BEGIN
               sp_create_holder_bulk (p_instcode,
                                      v_cust,
                                      v_acctid,
                                      NULL,
                                      p_lupduser,
                                      v_holdposn,
                                      p_errmsg
                                     );

               IF p_errmsg <> 'OK'
               THEN
                  p_errmsg :=
                        'From sp_create_holder_bulk '
                     || p_errmsg
                     || ' for file '
                     || p_filename;
                  RAISE excp_movetohist;
               END IF;
            EXCEPTION
               WHEN excp_movetohist
               THEN                                     --added on 14-Jul-2012
                  RAISE;
               WHEN OTHERS
               THEN
                  p_errmsg :=
                        'Error while calling SP_CREATE_HOLDER '
                     || SUBSTR (SQLERRM, 1, 200);
                  RAISE excp_movetohist;
            END;
         END IF;

  

	    BEGIN
           SELECT cpc_encrypt_enable
             INTO v_encrypt_enable
             FROM cms_prod_cattype
            WHERE cpc_prod_code = y.cci_prod_code
              AND cpc_card_type = y.cci_card_type
              AND cpc_inst_code = p_instcode;
         EXCEPTION
			WHEN OTHERS THEN
				 p_errmsg   := 'Error while selecting Encrypt Enable flag-'|| SUBSTR (SQLERRM, 1, 200);
				 RAISE excp_movetohist;
        END;

		IF v_encrypt_enable = 'Y' THEN
		   v_encr_firstname := SUBSTR (fn_dmaps_main(y.cci_seg12_name_line1), 1, 30);
		ELSE
		   v_encr_firstname := SUBSTR (y.cci_seg12_name_line1, 1, 30);
		END IF;

         IF p_errmsg = 'OK'
         THEN
            BEGIN
               sp_create_bulk_appl
                        (p_instcode,
                         1,
                         1,
                         'S',
                         SYSDATE,
                         SYSDATE,
                         v_cust,
                         y.cci_fiid,
                         v_cpb_prod_code,
                         v_prodcattype,
                         v_ccc_catg_code,                  --customer category
                         SYSDATE,
                         v_expry_arry(v_cntr), --v_expry_date, --Modified for VMS-7342
                         v_encr_firstname,
                         0,
                         'N',
                         NULL,
                         1,

                         --total account count  = 1 since in upload a card is associated with only one account
                         'P',      --addon status always a primary application
                         0,
                         --addon link 0 means that the appln is for promary pan
                         v_addrcode,                         --billing address
                         NULL,                                  --channel code
                         p_lupduser,
                         p_lupduser,
                         y.cci_ikit_flag,
                         p_filename,
                         --Modified by Sivapragasam on 15 Feb 2012 for Starter Card Development
                         v_starter_card, -- starter card flag for product catg
                         v_applcode,                              --out param,
                         p_errmsg
                        );

               IF p_errmsg <> 'OK'
               THEN
                  p_errmsg :=
                        'From sp_create_appl '
                     || p_errmsg
                     || ' for file '
                     || p_filename
                     || ' and row id '
                     || y.cci_row_id;
                  RAISE excp_movetohist;
               END IF;
            EXCEPTION
               WHEN excp_movetohist
               THEN                                     --added on 14-Jul-2012
                  RAISE;
               WHEN OTHERS
               THEN
                  p_errmsg :=
                        'Error while calling SP_CREATE_BULK_APPL'
                     || SUBSTR (SQLERRM, 1, 200);
                  RAISE excp_movetohist;
            END;
         END IF;

         IF p_errmsg = 'OK'
         THEN
            BEGIN
               sp_create_appldet (p_instcode,
                                  v_applcode,
                                  v_acctid,
                                  1,
                                  p_lupduser,
                                  p_errmsg
                                 );
            EXCEPTION
               WHEN OTHERS
               THEN
                  p_errmsg :=
                        'Error while calling SP_CREATE_APPLDET'
                     || SUBSTR (SQLERRM, 1, 200);
                  RAISE excp_movetohist;
            END;
         END IF;

         IF p_errmsg <> 'OK'
         THEN
            p_errmsg :=
                  'From sp_create_appldet '
               || p_errmsg
               || ' for file '
               || p_filename
               || ' and row id '
               || y.cci_row_id;
            RAISE excp_movetohist;
         ELSIF p_errmsg = 'OK'
         THEN
            BEGIN
               UPDATE cms_appl_mast
                  SET cam_appl_stat = v_appl_status
                WHERE cam_inst_code = p_instcode
                      AND cam_appl_code = v_applcode;
            EXCEPTION
               WHEN OTHERS
               THEN
                  p_errmsg :=
                        'Error while updateing CMS_APPL_MAST'
                     || SUBSTR (SQLERRM, 1, 200);
                  RAISE excp_movetohist;
            END;
         END IF;

         IF p_errmsg = 'OK'
         THEN
            BEGIN
               UPDATE cms_caf_info_temp
                  SET cci_upld_stat = 'O'                    --processing Over
                WHERE cci_file_name = p_filename
                  AND cci_row_id = y.cci_row_id
                  AND cci_inst_code = p_instcode;
            EXCEPTION
               WHEN OTHERS
               THEN
                  p_errmsg :=
                        'Error while updateing CMS_CAF_INFO_TEMP'
                     || SUBSTR (SQLERRM, 1, 200);
                  RAISE excp_movetohist;
            END;

            SELECT seq_dirupld_rowid.NEXTVAL
              INTO v_rownumber
              FROM DUAL;



            BEGIN
               INSERT INTO cms_caf_info_entry
                           (cci_inst_code, cci_fiid,cci_seg12_name_line1,
                            cci_seg12_name_line2,cci_seg12_addr_line1,
                            cci_seg12_city, cci_seg12_state,
                            cci_seg12_postal_code,
                            cci_seg12_country_code, cci_row_id,
                            cci_ins_date, cci_lupd_date, cci_file_name,
                            cci_upld_stat, cci_approved, cci_store_id,
                            cci_appl_code, cci_cust_catg,
                            CCI_SEG12_NAME_LINE1_ENCR,
                            CCI_SEG12_NAME_LINE2_ENCR,
                            CCI_SEG12_ADDR_LINE1_ENCR,
                            CCI_SEG12_CITY_ENCR,
                            CCI_SEG12_POSTAL_CODE_ENCR                            
                           )
                    VALUES (p_instcode, y.cci_fiid, y.cci_seg12_name_line1,
                            y.cci_seg12_name_line2, y.cci_seg12_addr_line1,
                            y.cci_seg12_city, y.cci_seg12_state,
                            y.cci_seg12_postal_code,
                            y.cci_seg12_country_code, v_rownumber,
                            SYSDATE, SYSDATE, p_filename,
                            'P', 'A', y.cci_store_id,
                            v_applcode, y.cci_cust_catg,
                            decode(v_encrypt_enable,'Y',y.cci_seg12_name_line1,fn_emaps_main(y.cci_seg12_name_line1)),
                            decode(v_encrypt_enable,'Y',y.cci_seg12_name_line2,fn_emaps_main(y.cci_seg12_name_line2)),
                            decode(v_encrypt_enable,'Y',y.cci_seg12_addr_line1,fn_emaps_main(y.cci_seg12_addr_line1)),
                            decode(v_encrypt_enable,'Y',y.cci_seg12_city,fn_emaps_main(y.cci_seg12_city)),
                            decode(v_encrypt_enable,'Y',y.cci_seg12_postal_code,fn_emaps_main(y.cci_seg12_postal_code))                            
                           );
            EXCEPTION
               WHEN OTHERS
               THEN
                  p_errmsg :=
                        'Error while inserting CMS_CAF_INFO_ENTRY'
                     || SUBSTR (SQLERRM, 1, 200);
                  RAISE excp_movetohist;
            END;
         END IF;

         COMMIT;
      EXCEPTION
         WHEN excp_movetohist
         THEN
            ROLLBACK;
            lp_cms_error_log (p_instcode,
                              p_filename,
                              y.cci_row_id,
                              p_errmsg,
                              p_lupduser,
                              SYSDATE,
                              'Contact Site Administrator',
                              p_errmsg
                             );
         WHEN OTHERS
         THEN
            ROLLBACK;
            lp_cms_error_log (p_instcode,
                              p_filename,
                              y.cci_row_id,
                              p_errmsg,
                              p_lupduser,
                              SYSDATE,
                              'Contact Site Administrator',
                              p_errmsg
                             );
      END;
   END LOOP;
EXCEPTION
   WHEN excp_movetohist
   THEN
      ROLLBACK;
      lp_cms_error_log (p_instcode,
                        p_filename,
                        1,
                        p_errmsg,
                        p_lupduser,
                        SYSDATE,
                        'Contact Site Administrator',
                        p_errmsg
                       );
   WHEN OTHERS
   THEN
      ROLLBACK;
      lp_cms_error_log (p_instcode,
                        p_filename,
                        1,
                        p_errmsg,
                        p_lupduser,
                        SYSDATE,
                        'Contact Site Administrator',
                        p_errmsg
                       );
END;
/
show error