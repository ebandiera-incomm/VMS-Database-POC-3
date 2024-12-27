create or replace PROCEDURE        vmscms.SP_UPLOAD_NEWCAF_MERINV_REP (
   p_instcode   IN       NUMBER,
   p_lupduser   IN       NUMBER,
   p_raise_flag IN       VARCHAR,-- Added for the mantis ID :14105 of DFCHOST-344
   p_errmsg     OUT      VARCHAR2
)
AS
   /*************************************************
       * Created Date     :  Apr-17-2014
       * Created By       :  Deepa T
       * PURPOSE          : To Generate application and card for auto replenishment inventory card for DFCHOST-344
       * Reviewer         : spankaj
       * Reviewed Date    : 18-April-2014
       * Release Number   : RI0027.2_B0006

       * Modified by      : Pankaj S.
       * Modified Date    : 18-Aug-2015
       * Modified reason  : Partner ID Changes
       * Reviewer         : Sarvanankumar
       * Build Number     :
       
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
	   
	  * Modified by       : BASKAR KRISHNAN
     * Modified Date     : 11-JUL-19
     * Modified For      : VMS-828
     * Reviewer          : Saravanakumar A
     * Build Number      : VMSGPRHOST_R18
     
     * Modified By      : UBAIDUR RAHMAN.H
    * Modified Date    : 09-JUL-2019
    * Purpose          : VMS 960/962 - Enhance Website/middleware to 
                                support cardholder data search – phase 2.
    * Reviewer         : Saravana Kumar.A
    * Release Number   : VMSGPRHOST_R18
   *************************************************/
   v_appl_status            cms_appl_mast.cam_appl_stat%type;
   v_encrypt_enable         cms_prod_cattype.cpc_encrypt_enable%type; 

   --cursor c2 picks up the actual data from cms_caf_info_inv for filenames which are picked up from cursor c1
   CURSOR c2 (fname IN VARCHAR2, v_order_process_cnt NUMBER)
   IS
      SELECT   cci_file_name, cci_row_id, cci_seg12_cardholder_title,
               cci_seg12_name_line1,                          --custmast part
                                    cci_seg12_addr_line1,
               cci_seg12_addr_line2, cci_seg12_name_line2, cci_seg12_city,
               cci_seg12_state, cci_seg12_postal_code,
               cci_seg12_country_code, cci_seg12_open_text1,   --address part
                                                            cci_fiid,
               cci_crd_typ, cci_pan_code, cci_exp_dat, cci_cust_catg,
               cci_seg12_branch_num,
                                    --customer category comes in this field
                                    cci_ikit_flag,
                                                  --Sn Customer generic data
                                                  cci_customer_param1,
               cci_customer_param2, cci_customer_param3, cci_customer_param4,
               cci_customer_param5, cci_customer_param6, cci_customer_param7,
               cci_customer_param8, cci_customer_param9,
               cci_customer_param10,
                                    --En customer generic data
                                    --Sn select addrss seg12 detail
                                    cci_seg12_addr_param1,
               cci_seg12_addr_param2, cci_seg12_addr_param3,
               cci_seg12_addr_param4, cci_seg12_addr_param5,
               cci_seg12_addr_param6, cci_seg12_addr_param7,
               cci_seg12_addr_param8, cci_seg12_addr_param9,
               cci_seg12_addr_param10,
                                      --En select ddrss seg12 detail
                                      --Sn select addrss seg12 detail
                                      cci_seg13_addr_param1,
               cci_seg13_addr_param2, cci_seg13_addr_param3,
               cci_seg13_addr_param4, cci_seg13_addr_param5,
               cci_seg13_addr_param6, cci_seg13_addr_param7,
               cci_seg13_addr_param8, cci_seg13_addr_param9,
               cci_seg13_addr_param10,
                                      --Sn select acct data
                                      cci_seg31_num_param1,
               cci_seg31_num_param2, cci_seg31_num_param3,
               cci_seg31_num_param4, cci_seg31_num_param5,
               cci_seg31_num_param6, cci_seg31_num_param7,
               cci_seg31_num_param8, cci_seg31_num_param9,
               cci_seg31_num_param10,
                                     --Sn select appl data
                                     cci_custappl_param1,
               cci_custappl_param2, cci_custappl_param3, cci_custappl_param4,
               cci_custappl_param5, cci_custappl_param6, cci_custappl_param7,
               cci_custappl_param8, cci_custappl_param9,
               cci_custappl_param10, cci_card_type, cci_prod_code,
               cci_store_id, cci_merc_id, cci_locn_id, cci_merprodcat_id
          FROM cms_caf_info_inv
         WHERE cci_inst_code = p_instcode
           AND cci_file_name = fname
           -- all records pertaionig to that file name will be picked
           AND cci_upld_stat = 'B'
           AND ROWNUM < v_order_process_cnt + 1
      --this will be B for Bulk issuance (Normally it is P)
      ORDER BY cci_fiid, cci_seg31_num;          --Added by Abhijit 11/11/2004

   v_order_process_cnt          PLS_INTEGER;
   V_DONOT_MARK_ERROR           PLS_INTEGER DEFAULT 0 ;
   v_result                     cms_serl_error.cse_err_mseg%TYPE;
    
   v_shuffleno_cnt              PLS_INTEGER    DEFAULT 0;
   v_succnt                     PLS_INTEGER    DEFAULT 0;
   v_merpan_cnt                 PLS_INTEGER;
   v_error                      PLS_INTEGER;
   v_generate                   PLS_INTEGER;
   --variable declaration
   v_cust                       cms_cust_mast.ccm_cust_code%TYPE;
   v_salutcode                  cms_cust_mast.ccm_salut_code%TYPE;
   v_gcm_cntry_code             gen_cntry_mast.gcm_cntry_code%TYPE;
   v_addrcode                   cms_addr_mast.cam_addr_code%TYPE;
   v_acctid                     cms_acct_mast.cam_acct_id%TYPE;
   v_holdposn                   cms_cust_acct.cca_hold_posn%TYPE;
   v_cpb_prod_code              cms_prod_bin.cpb_prod_code%TYPE;
   v_applcode                   cms_appl_mast.cam_appl_code%TYPE;
   v_interchange_code           cms_bin_mast.cbm_interchange_code%TYPE;
   v_ccc_catg_code              cms_cust_catg.ccc_catg_code%TYPE           := 1;
   v_cat_type_code              cms_acct_type.cat_type_code%TYPE;
   v_cas_stat_code              cms_acct_stat.cas_stat_code%TYPE;
   v_cci_seg31_acct_cnt         cms_caf_info_inv.cci_seg31_acct_cnt%TYPE;
   v_cci_seg31_typ              cms_caf_info_inv.cci_seg31_typ%TYPE;
   v_cci_seg31_num              cms_caf_info_inv.cci_seg31_num%TYPE;
   v_cci_seg31_stat             cms_caf_info_inv.cci_seg31_stat%TYPE;
   v_cci_seg31_typ1             cms_caf_info_inv.cci_seg31_typ1%TYPE;
   v_cci_seg31_num1             cms_caf_info_inv.cci_seg31_num1%TYPE;
   v_cci_seg31_stat1            cms_caf_info_inv.cci_seg31_stat1%TYPE;
   v_cci_seg31_typ2             cms_caf_info_inv.cci_seg31_typ2%TYPE;
   v_cci_seg31_num2             cms_caf_info_inv.cci_seg31_num2%TYPE;
   v_cci_seg31_stat2            cms_caf_info_inv.cci_seg31_stat2%TYPE;
   v_cci_seg31_typ3             cms_caf_info_inv.cci_seg31_typ3%TYPE;
   v_cci_seg31_num3             cms_caf_info_inv.cci_seg31_num3%TYPE;
   v_cci_seg31_stat3            cms_caf_info_inv.cci_seg31_stat3%TYPE;
   v_cci_seg31_typ4             cms_caf_info_inv.cci_seg31_typ4%TYPE;
   v_cci_seg31_num4             cms_caf_info_inv.cci_seg31_num4%TYPE;
   v_cci_seg31_stat4            cms_caf_info_inv.cci_seg31_stat4%TYPE;
   v_cci_seg31_typ5             cms_caf_info_inv.cci_seg31_typ5%TYPE;
   v_cci_seg31_num5             cms_caf_info_inv.cci_seg31_num5%TYPE;
   v_cci_seg31_stat5            cms_caf_info_inv.cci_seg31_stat5%TYPE;
   v_cci_seg31_typ6             cms_caf_info_inv.cci_seg31_typ6%TYPE;
   v_cci_seg31_num6             cms_caf_info_inv.cci_seg31_num6%TYPE;
   v_cci_seg31_stat6            cms_caf_info_inv.cci_seg31_stat6%TYPE;
   v_cci_seg31_typ7             cms_caf_info_inv.cci_seg31_typ7%TYPE;
   v_cci_seg31_num7             cms_caf_info_inv.cci_seg31_num7%TYPE;
   v_cci_seg31_stat7            cms_caf_info_inv.cci_seg31_stat7%TYPE;
   v_cci_seg31_typ8             cms_caf_info_inv.cci_seg31_typ8%TYPE;
   v_cci_seg31_num8             cms_caf_info_inv.cci_seg31_num8%TYPE;
   v_cci_seg31_stat8            cms_caf_info_inv.cci_seg31_stat8%TYPE;
   v_cci_seg31_typ9             cms_caf_info_inv.cci_seg31_typ9%TYPE;
   v_cci_seg31_num9             cms_caf_info_inv.cci_seg31_num9%TYPE;
   v_cci_seg31_stat9            cms_caf_info_inv.cci_seg31_stat9%TYPE;
   v_check_branch               PLS_INTEGER;
   v_custcatg_code              cms_cust_catg.ccc_catg_code%TYPE;
   v_custcatg                   cms_cust_catg.ccc_catg_sname%TYPE;
   v_check_bin_stat             cms_bin_mast.cbm_bin_stat%TYPE;
   v_cust_data                  type_cust_rec_array;
   v_addr_data1                 type_addr_rec_array;
   v_addr_data2                 type_addr_rec_array;
   v_appl_data                  type_appl_rec_array;
   v_seg31acctnum_data          type_acct_rec_array;
   v_dum                        PLS_INTEGER;
   v_prodcattype                cms_prod_ccc.cpc_card_type%type;
   
   v_profile_code               cms_prod_cattype.cpc_profile_code%TYPE;
   v_cpm_catg_code              cms_prod_mast.cpm_catg_code%TYPE;
   v_prod_prefix                cms_prod_cattype.cpc_prod_prefix%TYPE;
   v_programid                  cms_prod_cattype.cpc_program_id%TYPE;
   v_expry_date                 DATE;
    
   v_rownumber                  PLS_INTEGER;
   v_starter_card               cms_prod_cattype.cpc_starter_card%TYPE;
   v_profile_code_catg          cms_prod_cattype.cpc_profile_code%TYPE;
   v_cci_card_type              cms_prod_cattype.cpc_card_type%TYPE;
   v_catg_code                  cms_prod_mast.cpm_catg_code%TYPE;
   v_pan                        cms_appl_pan.cap_pan_code%TYPE;
   --added on 14-Jun-2012
   v_encr_pan                   cms_appl_pan.cap_pan_code_encr%TYPE;
   --added on 14-Jun-2012
   v_errmsg                     transactionlog.error_msg%type;                 --added on 14-Jun2012
   v_appl_proc_msg              transactionlog.error_msg%type;                --added on 14-Jun2012
   v_inst_bin                   cms_bin_mast.cbm_inst_bin%TYPE;
                                                         --added on 14-Jun2012
               -- added by sagar on 06Apr2012 to pass prod catg from prod_mast
   /* Start Added by Dhiraj Gaikwad 13062012 */
   excp_movetohist              EXCEPTION;
   exp_reject_file              EXCEPTION;
   excp_pan_gen                 EXCEPTION;

   v_savepoint                  NUMBER  DEFAULT 0;
   v_exp_date_exemption     cms_prod_cattype.cpc_exp_date_exemption%TYPE;

   /* End  Added by Dhiraj Gaikwad 13062012 */
   PROCEDURE lp_cms_error_log (
      p_inst_code     IN   NUMBER,
      p_file_name     IN   VARCHAR2,
      p_row_id        IN   VARCHAR2,
      p_error_mesg    IN   VARCHAR2,
      p_lupd_user     IN   NUMBER,
      p_lupd_date     IN   DATE,
      p_prob_action   IN   VARCHAR2
   )
   AS
      PRAGMA AUTONOMOUS_TRANSACTION;
   BEGIN
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

   --local procedure for handling the account part
   PROCEDURE lp_acct_part (
      p_cust       IN       NUMBER,
      p_addr       IN       NUMBER,
      p_filename   IN       VARCHAR2,
      p_frowid     IN       NUMBER,
      p_branch     IN       VARCHAR2,
      p_bin        IN       NUMBER,
      p_custid     IN       NUMBER,
      p_acctid     OUT      VARCHAR2,
      p_lperr      OUT      VARCHAR2
   )
   IS
      v_dupflag         VARCHAR2 (1);
      v_prod_code       cms_prod_cattype.cpc_prod_code%TYPE; 
      v_acct_num        cms_acct_mast.cam_acct_no%TYPE;
   BEGIN
      v_appl_status := 'A';

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
                cci_seg31_stat9, cci_prod_code,
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
                                    ),
                cci_card_type
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
                v_cci_seg31_stat9, v_prod_code,
                v_seg31acctnum_data,
                v_cci_card_type
           FROM cms_caf_info_inv
          WHERE cci_file_name = p_filename
            AND cci_row_id = p_frowid
            AND cci_inst_code = p_instcode;
      EXCEPTION
         WHEN OTHERS
         THEN
            p_lperr :=
                  'Error while selecting CMS_CAF_INFO_INV '
               || SUBSTR (SQLERRM, 1, 200);
            RETURN;
      END;

      --for primary account
      BEGIN
         SELECT cat_type_code
           INTO v_cat_type_code
           FROM cms_acct_type
          WHERE cat_inst_code = p_instcode
            AND cat_switch_type = v_cci_seg31_typ;
      EXCEPTION
         WHEN OTHERS
         THEN
            p_lperr :=
                  'Error while selecting CMS_ACCT_TYPE '
               || SUBSTR (SQLERRM, 1, 200);
            RETURN;
      END;

      BEGIN
         SELECT cas_stat_code
           INTO v_cas_stat_code
           FROM cms_acct_stat
          WHERE cas_inst_code = p_instcode
            AND cas_switch_statcode = v_cci_seg31_stat;
      EXCEPTION
         WHEN OTHERS
         THEN
            p_lperr :=
                  'Error while selecting CMS_ACCT_STAT '
               || SUBSTR (SQLERRM, 1, 200);
            RETURN;
      END;

      --Get Account number Added on 5-07-2011
      BEGIN
         --Added one more argument for cardtype
         sp_account_construct (p_instcode,
                               p_branch,
                               v_prod_code,
                               p_lupduser,
                               v_cci_card_type,              --Addec by ram.MK
                               v_acct_num,
                               p_lperr
                              );

         IF p_lperr <> 'OK'
         THEN
            p_lperr :=
                  'From sp_account_construct '
               || p_lperr
               || ' for file '
               || p_filename
               || ' and row id '
               || p_frowid;
            RETURN;
         END IF;
      EXCEPTION
         WHEN OTHERS
         THEN
            p_lperr :=
                  'Error while calling SP_ACCOUNT_CONSTRUCT '
               || SUBSTR (SQLERRM, 1, 200);
            RETURN;
      END;

      --now call the procedure for creating account
      BEGIN
         sp_create_acct (p_instcode,
                         v_acct_num,                        --v_cci_seg31_num,
                         1,
                         p_branch,
                         p_addr,
                         v_cat_type_code,
                         v_cas_stat_code,
                         p_lupduser,
                         v_seg31acctnum_data,
                         p_bin,
                         p_custid,
                         v_prod_code,
                         v_cci_card_type,
                         v_dupflag,
                         p_acctid,
                         p_lperr
                        );

         IF p_lperr <> 'OK'
         THEN
            p_lperr :=
                  'From sp_create_acct '
               || p_lperr
               || ' for file '
               || p_filename
               || ' and row id '
               || p_frowid;
            RETURN;
         END IF;
      EXCEPTION
         WHEN OTHERS
         THEN
            p_lperr :=
                  'Error while calling SP_CREATE_ACCT '
               || SUBSTR (SQLERRM, 1, 200);
            RETURN;
      END;

      BEGIN
         UPDATE cms_acct_mast
            SET cam_hold_count = cam_hold_count + 1,
                cam_lupd_user = p_lupduser
          WHERE cam_inst_code = p_instcode AND cam_acct_no = v_cci_seg31_num;
      EXCEPTION
         WHEN OTHERS
         THEN
            p_lperr :=
                  'Error while updating CMS_ACCT_MAST '
               || SUBSTR (SQLERRM, 1, 200);
            RETURN;
      END;

      --now attach the account to the customer(create holder)
      IF p_lperr = 'OK'
      THEN
         --  dbms_output.put_line('Before calling Sp create Holder -->'||lperr);
         BEGIN
            sp_create_holder (p_instcode,
                              p_cust,
                              p_acctid,
                              NULL,
                              p_lupduser,
                              v_holdposn,
                              p_lperr
                             );

            IF p_errmsg <> 'OK'
            THEN
               p_errmsg :=
                     'From sp_create_holder '
                  || p_lperr
                  || ' for file '
                  || p_filename
                  || ' and row id '
                  || p_frowid;
               RETURN;
            END IF;
         EXCEPTION
            WHEN OTHERS
            THEN
               p_lperr :=
                     'Error while calling SP_CREATE_HOLDER '
                  || SUBSTR (SQLERRM, 1, 200);
               RETURN;
         END;
      END IF;
   EXCEPTION
      WHEN OTHERS
      THEN
         p_lperr := 'Error in LP_ACCT_PART ' || SUBSTR (SQLERRM, 1, 200);
   END lp_acct_part;
--end local procedure
--
BEGIN
 

   --  FOR i1 IN cur_file_control-- LOOP-- BEGIN
   FOR i1 IN (SELECT ordr.cmo_merprodcat_id, prodcat.cmp_inst_code,
                     ordr.cmo_ordr_refrno cum_file_name, prodcat.cmp_mer_id,
                     ordr.cmo_location_id, prodcat.cmp_prod_code, prodcat.cmp_prod_cattype,
                     ordr.cmo_nocards_ordr, ordr.cmo_ins_user, cattype.cpc_serl_flag
                FROM cms_merinv_prodcat prodcat, cms_merinv_ordr ordr, cms_prod_cattype cattype
               WHERE prodcat.cmp_merprodcat_id = ordr.cmo_merprodcat_id
                 AND ordr.cmo_authorize_flag = 'A'
                 AND ordr.cmo_process_flag = 'N'
                 AND cattype.cpc_inst_code = prodcat.cmp_inst_code
                 AND cattype.cpc_prod_code = prodcat.cmp_prod_code
                 AND cattype.cpc_card_type = prodcat.cmp_prod_cattype
                 AND ordr.CMO_RAISE_FLAG=p_raise_flag)-- Added for the mantis ID :14105 of DFCHOST-344
   LOOP
      BEGIN
         p_errmsg := 'OK';
         v_cust_data := type_cust_rec_array ();
         v_addr_data1 := type_addr_rec_array ();
         v_addr_data2 := type_addr_rec_array ();
         v_appl_data := type_appl_rec_array ();
         v_seg31acctnum_data := type_acct_rec_array ();
         v_order_process_cnt := 0;
         v_succnt := 0;
        --- DBMS_OUTPUT.put_line ('Order Number ---' || i1.cum_file_name);

         SELECT COUNT (*)
           INTO v_merpan_cnt
           FROM cms_merinv_merpan
          WHERE cmm_ordr_refrno = i1.cum_file_name;

         IF v_merpan_cnt = 0
         THEN
            BEGIN
               SELECT cpb_inst_bin
                 INTO v_inst_bin
                 FROM cms_prod_bin
                WHERE cpb_prod_code = i1.cmp_prod_code
                  AND cpb_inst_code = p_instcode;
            EXCEPTION
               WHEN OTHERS
               THEN
                  p_errmsg :=
                        'Error while selecting institution bin for product '
                     || i1.cmp_prod_code
                     || SUBSTR (SQLERRM, 1, 200);
                  RAISE exp_reject_file;
            END;

  
               v_order_process_cnt := i1.cmo_nocards_ordr;

               FOR j IN 1 .. v_order_process_cnt
               LOOP
                  BEGIN
                     INSERT INTO cms_caf_info_inv
                                 (cci_file_name, cci_row_id, cci_inst_code,
                                  cci_pan_code, cci_crd_typ, cci_fiid,
                                  cci_seg12_branch_num,
                                  cci_seg12_cardholder_title,
                                  cci_seg12_open_text1,
                                  cci_seg12_name_line1,
                                  cci_seg12_name_line2,
                                  cci_seg12_addr_line1,
                                  cci_seg12_addr_line2, cci_seg12_city,
                                  cci_seg12_state, cci_seg12_postal_code,
                                  cci_seg12_country_code, cci_seg31_typ,
                                  cci_seg31_num, cci_seg31_stat,
                                  cci_ins_user, cci_ins_date, cci_lupd_user,
                                  cci_lupd_date, cci_upld_stat,
                                  cci_cust_catg, cci_prod_code,
                                  cci_card_type, cci_merc_id,
                                  cci_locn_id, cci_merprodcat_id,
                                  cci_store_id
                                 )
                          VALUES (i1.cum_file_name, j, i1.cmp_inst_code,
                                  v_inst_bin, i1.cmp_prod_cattype, '0001',
                                  '',
                                  1,
                                  '*',
                                  'Alwin',
                                  '*',
                                  '*',
                                  '*', '*',
                                  'GA', '*',
                                  '840', 11,
                                  NULL, 3,
                                  p_lupduser, SYSDATE, p_lupduser,
                                  SYSDATE, 'B',
                                  'DEF', i1.cmp_prod_code,
                                  i1.cmp_prod_cattype, i1.cmp_mer_id,
                                  i1.cmo_location_id, i1.cmo_merprodcat_id,
                                  i1.cmo_location_id
                                 );
                  EXCEPTION
                     WHEN OTHERS
                     THEN
                        p_errmsg :=
                              'Error while selecting institution bin for product '
                           || i1.cmp_prod_code
                           || SUBSTR (SQLERRM, 1, 200);
                        RAISE exp_reject_file;
                  END;
               END LOOP;
           -- END IF;

            --p_filename := i1.cum_file_name;
            BEGIN
				INSERT
				INTO cms_summary_merinv
				  (
					csm_inst_code,
					csm_file_name,
					csm_success_records,
					csm_error_records,
					csm_tot_records,
					csm_ins_user,
					csm_ins_date,
					csm_lupd_user,
					csm_lupd_date,
					csm_file_type
				  )
				  VALUES
				  (
					p_instcode,
					i1.cum_file_name,
					0,
					0,
					0,
					p_lupduser,
					SYSDATE,
					p_lupduser,
					SYSDATE,
					''
				  );
            EXCEPTION
               WHEN DUP_VAL_ON_INDEX
               THEN
                  p_errmsg :=
                        'Duplicate record found file '
                     || i1.cum_file_name
                     || ' already processed ';
                  RAISE exp_reject_file;
               WHEN OTHERS
               THEN
                  p_errmsg :=
                        'Error while creating a record in summary table '
                     || SUBSTR (SQLERRM, 1, 200);
                  RAISE exp_reject_file;
            END;

            FOR y IN c2 (i1.cum_file_name, v_order_process_cnt)
            --loop 2 for cursor 2
            LOOP
               --p_errmsg := 'OK';
               v_pan := NULL;
               v_errmsg := 'OK';
               v_appl_proc_msg := 'OK';
               v_savepoint := v_savepoint + 1;
               SAVEPOINT v_savepoint;

               BEGIN
                  v_cust_data.DELETE;
                  v_addr_data1.DELETE;
                  v_addr_data2.DELETE;
                  v_seg31acctnum_data.DELETE;
                  v_appl_data.DELETE;

                  --Sn Check Sale condition
                  BEGIN
                     SELECT 1
                       INTO v_check_branch
                       FROM cms_bran_mast
                      WHERE cbm_bran_code = y.cci_fiid
                        AND cbm_sale_trans = 1
                        AND cbm_inst_code = p_instcode;
                  EXCEPTION
                     WHEN NO_DATA_FOUND
                     THEN
                        v_errmsg :=
                               'Branch is not allowed for new card issuance ';
                        RAISE excp_movetohist;
                     WHEN OTHERS
                     THEN
                        v_errmsg :=
                              'Branch is not allowed for new card issuance'
                           || SUBSTR (SQLERRM, 1, 200);
                        RAISE excp_movetohist;
                  END;

                  --En Check Sale condition
                  --Sn check cust catg
                  BEGIN
                     SELECT ccc_catg_code, ccc_catg_sname
                       INTO v_custcatg_code, v_custcatg
                       FROM cms_cust_catg
                      WHERE ccc_catg_sname = y.cci_cust_catg
                        AND ccc_inst_code = p_instcode;
                  EXCEPTION
                     WHEN excp_movetohist
                     THEN
                        RAISE excp_movetohist;
                     WHEN NO_DATA_FOUND
                     THEN
                        BEGIN
                           sp_set_custcatg (p_instcode,
                                            y.cci_cust_catg,
                                            p_lupduser,
                                            v_custcatg_code,
                                            v_errmsg
                                           );

                           IF v_errmsg <> 'OK'
                           THEN
                              RAISE excp_movetohist;
                           END IF;
                        EXCEPTION
                           WHEN excp_movetohist
                           THEN
                              RAISE excp_movetohist;
                           WHEN OTHERS
                           THEN
                              v_errmsg :=
                                    'Error while creating cust catg '
                                 || SUBSTR (SQLERRM, 1, 200);
                              RAISE excp_movetohist;
                        END;
                     WHEN OTHERS
                     THEN
                        v_errmsg :=
                              'Error while selecting customer category'
                           || SUBSTR (SQLERRM, 1, 200);
                        RAISE excp_movetohist;
                  END;

                  --En check cust catg
                  --Sn check bin status
                  BEGIN
                     SELECT cbm_bin_stat
                       INTO v_check_bin_stat
                       FROM cms_bin_mast
                      WHERE cbm_inst_bin = y.cci_pan_code
                        AND cbm_inst_code = p_instcode;

                     IF v_check_bin_stat NOT IN ('0', '1')
                     THEN
                        v_errmsg := 'Not a active Bin ' || y.cci_pan_code;
                        RAISE excp_movetohist;
                     END IF;
                  EXCEPTION
                     WHEN excp_movetohist
                     THEN
                        RAISE excp_movetohist;
                     WHEN NO_DATA_FOUND
                     THEN
                        v_errmsg :=
                           'Bin ' || y.cci_pan_code
                           || ' not found in master ';
                        RAISE excp_movetohist;
                     WHEN OTHERS
                     THEN
                        v_errmsg :=
                              'Error while selecting bin details from master '
                           || SUBSTR (SQLERRM, 1, 200);
                        RAISE excp_movetohist;
                  END;

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
                     WHEN excp_movetohist
                     THEN
                        RAISE excp_movetohist;
                     WHEN OTHERS
                     THEN
                        v_errmsg :=
                              'Error while cutomer gen data '
                           || SUBSTR (SQLERRM, 1, 200);
                        RAISE excp_movetohist;
                  END;

 

                  -- Sn find prod
                  BEGIN
                     SELECT cpm_catg_code
                       INTO v_catg_code
                       FROM cms_prod_mast
                      WHERE cpm_inst_code = p_instcode
                        AND cpm_prod_code = y.cci_prod_code
                        AND cpm_marc_prod_flag = 'N';
                  EXCEPTION
                     WHEN excp_movetohist
                     THEN
                        RAISE excp_movetohist;
                     WHEN NO_DATA_FOUND
                     THEN
                        v_errmsg :=
                              'Product code'
                           || y.cci_prod_code
                           || 'is not defined in the master';
                        RAISE excp_movetohist;
                     WHEN OTHERS
                     THEN
                        v_errmsg :=
                              'Error while selecting product '
                           || SUBSTR (SQLERRM, 1, 200);
                        RAISE excp_movetohist;
                  END;

------------------------------------------------
--En : Selecting prod catg code from prod_mast
-- added by sagar on 06-Apr-2012
-------------------------------------------------
                  BEGIN
                     sp_create_cust (p_instcode,
                                     1,
                                     0,
                                     'Y',
                                     v_salutcode,
                                     y.cci_seg12_name_line1,
                                     NULL,
                                     ' ',
                                     TO_DATE ('15-AUG-1947', 'DD-MON-YYYY'),
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
                                     v_cust_data,
                                     y.cci_prod_code,  --Added for Partner ID Changes
                                     y.cci_card_type,
                                     v_cust,
                                     v_errmsg
                                    );

                     IF v_errmsg <> 'OK'
                     THEN
                        v_errmsg :=
                              'From sp_create_cust '
                           || v_errmsg
                           || ' for file '
                           || i1.cum_file_name
                           || ' and row id '
                           || y.cci_row_id;
                        RAISE excp_movetohist;
                     END IF;
                  EXCEPTION
                     WHEN excp_movetohist
                     THEN
                        RAISE excp_movetohist;
                     WHEN OTHERS
                     THEN
                        v_errmsg :=
                             'Error while calling SP_CREATE_CUST ' || SQLERRM;
                        RAISE excp_movetohist;
                  END;

                  IF v_errmsg = 'OK'
                  THEN
                     --address part
                     --begin commented on 13/03/2012 by Narayanan for the country code issue , this validation is not required
                     BEGIN
                        SELECT gcm_cntry_code
                          INTO v_gcm_cntry_code
                          FROM gen_cntry_mast
                         WHERE gcm_curr_code = y.cci_seg12_country_code
                           AND gcm_inst_code = p_instcode;
                     EXCEPTION
                        WHEN NO_DATA_FOUND
                        THEN
                           v_errmsg := 'Country Not defined in master';
                           RAISE excp_movetohist;
                        WHEN OTHERS
                        THEN
                           v_errmsg :=
                                 'Error while selecting GEN_CNTRY_MAST '
                              || SQLERRM;
                           RAISE excp_movetohist;
                     END;

                     --end commented on 13/03/2012 by Narayanan for the country code issue , this validation is not required
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
                           v_errmsg :=
                                 'Error while address gen data '
                              || SUBSTR (SQLERRM, 1, 200);
                           RAISE excp_movetohist;
                     END;

                     --En select ddrss seg12 detail
                     BEGIN
                        sp_create_addr (p_instcode,
                                        v_cust,
                                        y.cci_seg12_addr_line1,
                                        y.cci_seg12_addr_line2,
                                        y.cci_seg12_name_line2,
                                        y.cci_seg12_postal_code,
                                        y.cci_seg12_open_text1,
                                        NULL,
                                        NULL,
                                        NULL,
                                        --begin commented  on 13/03/2012 by Narayanan for the country code issue , this validation is not required
                                        --V_GCM_CNTRY_CODE,
                                        v_gcm_cntry_code,
                                        --end commented on 13/03/2012 by Narayanan for the country code issue , this validation is not required
                                        y.cci_seg12_city,
                                        y.cci_seg12_state,
                                        NULL,
                                        'P',
                                        'R',
                                        p_lupduser,
                                        v_addr_data1,
                                        v_addrcode,
                                        v_errmsg
                                       );

                        IF v_errmsg <> 'OK'
                        THEN
                           v_errmsg :=
                                 'From sp_create_addr '
                              || v_errmsg
                              || ' for file '
                              || i1.cum_file_name
                              || ' and row id '
                              || y.cci_row_id;
                           RAISE excp_movetohist;
                        END IF;
                     EXCEPTION
                        WHEN excp_movetohist
                        THEN
                           RAISE excp_movetohist;
                        WHEN OTHERS
                        THEN
                           v_errmsg :=
                              'Error while calling SP_CREATE_ADDR '
                              || SQLERRM;
                           RAISE excp_movetohist;
                     END;
                  END IF;

                  IF v_errmsg = 'OK'
                  THEN
                     --account part
                     BEGIN
                        --call the local procedure which handles the account part
                        lp_acct_part (v_cust,
                                      v_addrcode,
                                      i1.cum_file_name,
                                      y.cci_row_id,
                                      y.cci_fiid,
                                      y.cci_pan_code,
                                      NULL,
                                      v_acctid,
                                      v_errmsg
                                     );

                        IF v_errmsg <> 'OK'
                        THEN
                           v_errmsg :=
                                 'From lp_acct_part '
                              || v_errmsg
                              || ' for stock file '
                              || i1.cum_file_name
                              || ' and row id '
                              || y.cci_row_id;
                           RAISE excp_movetohist;
                        END IF;
                     EXCEPTION
                        WHEN excp_movetohist
                        THEN
                           RAISE excp_movetohist;
                        WHEN OTHERS
                        THEN
                           v_errmsg :=
                                 'Excp 1.3 -- '
                              || SQLERRM
                              || ' for stock file '
                              || i1.cum_file_name
                              || ' and row id '
                              || y.cci_row_id;
                           RAISE excp_movetohist;
                     END;
                  END IF;

                  IF v_errmsg = 'OK'
                  THEN
                     --application part
                     BEGIN
                        SELECT cbm_interchange_code
                          INTO v_interchange_code
                          FROM cms_bin_mast 
                        WHERE  cbm_inst_code = p_instcode
                           AND cbm_inst_bin = TRIM (y.cci_pan_code);
                     EXCEPTION
                        WHEN NO_DATA_FOUND
                        THEN
                           v_errmsg :=
                                'Unable to Fetch InterChange code' || SQLERRM;
                           RAISE excp_movetohist;
                        WHEN OTHERS
                        THEN
                           v_errmsg :=
                                 'Error while selecting CMS_PRODTYPE_MAP'
                              || SQLERRM;
                           RAISE excp_movetohist;
                     END;

                     BEGIN
                        SELECT cpb_prod_code
                          INTO v_cpb_prod_code
                          FROM cms_prod_bin
                         WHERE cpb_inst_code = p_instcode
                           AND cpb_inst_bin = y.cci_pan_code
                           AND cpb_interchange_code = v_interchange_code
                           AND cpb_active_bin = 'Y';     --added on 17/09/2002
                     EXCEPTION
                        WHEN NO_DATA_FOUND
                        THEN
                           v_errmsg :=
                                     'Unable to Fetch Poduct Code' || SQLERRM;
                           RAISE excp_movetohist;
                        WHEN OTHERS
                        THEN
                           v_errmsg :=
                              'Error while selecting CMS_PROD_BIN' || SQLERRM;
                           RAISE excp_movetohist;
                     END;

                     IF y.cci_cust_catg = '*' OR y.cci_cust_catg IS NULL
                     THEN
                        v_ccc_catg_code := 1;     --default customer category
                     ELSE
                        BEGIN
                           SELECT ccc_catg_code
                             INTO v_ccc_catg_code
                             FROM cms_cust_catg
                            WHERE ccc_inst_code = p_instcode
                              AND ccc_catg_sname = y.cci_cust_catg;
                        EXCEPTION
                           WHEN excp_movetohist
                           THEN
                              RAISE excp_movetohist;
                           WHEN OTHERS
                           THEN
                              v_errmsg :=
                                    'Error while selecting CMS_CUST_CATG'
                                 || SQLERRM;
                              RAISE excp_movetohist;
                        END;
                     END IF;

                     v_prodcattype := y.cci_card_type;

                     BEGIN
                        SELECT 1
                          INTO v_dum
                          FROM cms_prod_ccc
                         WHERE cpc_inst_code = p_instcode
                           AND cpc_cust_catg = v_ccc_catg_code       -- number
                           AND cpc_prod_code = v_cpb_prod_code      -- varchar
                           AND cpc_card_type = v_prodcattype;        -- number
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
                                                 v_errmsg
                                                );

                              IF v_errmsg <> 'OK'
                              THEN
                                 v_errmsg :=
                                       'From sp_create_prodccc '
                                    || v_errmsg
                                    || i1.cum_file_name
                                    || ' and row id '
                                    || y.cci_row_id;
                                 RAISE excp_movetohist;
                              END IF;
                           EXCEPTION
                              WHEN excp_movetohist
                              THEN
                                 RAISE excp_movetohist;
                              WHEN OTHERS
                              THEN
                                 v_errmsg :=
                                       'Error while calling SP_CREATE_PRODCCC'
                                    || SUBSTR (SQLERRM, 1, 200);
                                 RAISE excp_movetohist;
                           END;

                           IF v_errmsg <> 'OK'
                           THEN
                              v_errmsg :=
                                    'Problem while attaching cust catg for pan '
                                 || y.cci_row_id;
                              RAISE excp_movetohist;
                           END IF;
                        WHEN OTHERS
                        THEN
                           v_errmsg :=
                                 'Error while selecting CMS_PROD_CCC'
                              || SUBSTR (SQLERRM, 1, 200);
                           RAISE excp_movetohist;
                     END;


                     --msiva added on Jul 25 2011 for Expiry date calculation Sn
                     BEGIN
                        SELECT prod.cpm_profile_code,prod.cpm_catg_code,
                               cattype.cpc_prod_prefix,cattype.cpc_program_id,
                               cattype.cpc_starter_card,cattype.cpc_exp_date_exemption,cattype.cpc_profile_code,
                               cattype.cpc_encrypt_enable
                          INTO v_profile_code, v_cpm_catg_code,
                               v_prod_prefix, v_programid,
                               v_starter_card,v_exp_date_exemption,v_profile_code_catg,v_encrypt_enable
                          --Modified by Sivapragasam on 15 Feb 2012 for Starter Card Development
                        FROM   cms_prod_cattype cattype, cms_prod_mast prod
                         WHERE cattype.cpc_inst_code = p_instcode
                           AND cattype.cpc_inst_code = prod.cpm_inst_code
                           AND cattype.cpc_prod_code = y.cci_prod_code
                           AND cattype.cpc_card_type = y.cci_card_type
                           AND prod.cpm_prod_code = cattype.cpc_prod_code;
                     EXCEPTION
                        WHEN NO_DATA_FOUND
                        THEN
                           v_errmsg :=
                                 'Profile code not defined for product code '
                              || y.cci_prod_code
                              || 'card type '
                              || y.cci_card_type;
                           RAISE excp_movetohist;
                        WHEN OTHERS
                        THEN
                           v_errmsg :=
                                 'Error while selecting applcode from applmast'
                              || SUBSTR (SQLERRM, 1, 300);
                           RAISE excp_movetohist;
                     END;

                    
                     BEGIN

                      vmsfunutilities.get_expiry_date(p_instcode,y.cci_prod_code,
                      y.cci_card_type,v_profile_code_catg,v_expry_date,v_errmsg);
                    
                      if p_errmsg<>'OK' then
                                 RAISE excp_movetohist;
                        END IF;
                        
                        EXCEPTION
                      when excp_movetohist then
                        
                      raise;


           
                                  WHEN others THEN
                      p_errmsg:='Error while calling vmsfunutilities.get_expiry_date'||substr(sqlerrm,1,200);
                                      RAISE excp_movetohist;
                              END;

                     IF v_errmsg = 'OK'
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
                               v_ccc_catg_code,            --customer category
                               SYSDATE,
                               v_expry_date,
                               SUBSTR (y.cci_seg12_name_line1, 1, 30),
                               0,
                               'N',
                               NULL,
                               1,

                               --total account count  = 1 since in upload a card is associated with only one account
                               'P',
                                   --addon status always a primary application
                               0,
                               --addon link 0 means that the appln is for promary pan
                               v_addrcode,                   --billing address
                               NULL,                            --channel code
                               p_lupduser,
                               p_lupduser,
                               y.cci_ikit_flag,
                               i1.cum_file_name,
                               --Modified by Sivapragasam on 15 Feb 2012 for Starter Card Development
                               v_starter_card,
                               -- starter card flag for product catg
                               v_applcode,                        --out param,
                               v_errmsg
                              );

                           IF v_errmsg <> 'OK'
                           THEN
                              v_errmsg :=
                                    'From sp_create_appl '
                                 || v_errmsg
                                 || ' for file '
                                 || i1.cum_file_name
                                 || ' and row id '
                                 || y.cci_row_id;
                              RAISE excp_movetohist;
                           END IF;
                        EXCEPTION
                           WHEN excp_movetohist
                           THEN
                              RAISE excp_movetohist;
                           WHEN OTHERS
                           THEN
                              v_errmsg :=
                                    'Error while calling SP_CREATE_BULK_APPL'
                                 || SUBSTR (SQLERRM, 1, 200);
                              RAISE excp_movetohist;
                        END;
                     END IF;

                     IF v_errmsg = 'OK'
                     THEN
                        BEGIN
                           sp_create_appldet (p_instcode,
                                              v_applcode,
                                              v_acctid,
                                              1,
                                              p_lupduser,
                                              v_errmsg
                                             );
                        EXCEPTION
                           WHEN excp_movetohist
                           THEN
                              RAISE excp_movetohist;
                           WHEN OTHERS
                           THEN
                              v_errmsg :=
                                    'Error while calling SP_CREATE_APPLDET'
                                 || SUBSTR (SQLERRM, 1, 200);
                              RAISE excp_movetohist;
                        END;
                     END IF;

                     IF v_errmsg <> 'OK'
                     THEN
                        v_errmsg :=
                              'From sp_create_appldet '
                           || v_errmsg
                           || ' for file '
                           || i1.cum_file_name
                           || ' and row id '
                           || y.cci_row_id;
                        RAISE excp_movetohist;
                     ELSIF v_errmsg = 'OK'
                     THEN
                        BEGIN
                           UPDATE cms_appl_mast
                              SET cam_appl_stat = v_appl_status
                            WHERE cam_inst_code = p_instcode
                              AND cam_appl_code = v_applcode;
                        EXCEPTION
                           WHEN excp_movetohist
                           THEN
                              RAISE excp_movetohist;
                           WHEN OTHERS
                           THEN
                              v_errmsg :=
                                    'Error while updateing CMS_APPL_MAST'
                                 || SUBSTR (SQLERRM, 1, 200);
                              RAISE excp_movetohist;
                        END;
                     END IF;
                  END IF;

                  IF v_errmsg = 'OK'
                  THEN
                     BEGIN
                        UPDATE cms_caf_info_inv
                           SET cci_upld_stat = 'O'           --processing Over
                         WHERE cci_file_name = i1.cum_file_name
                           AND cci_row_id = y.cci_row_id
                           AND cci_inst_code = p_instcode;

                        UPDATE cms_summary_merinv
                           SET csm_success_records = csm_success_records + 1,
                               csm_tot_records = csm_tot_records + 1
                         WHERE csm_file_name = i1.cum_file_name;
                     EXCEPTION
                        WHEN excp_movetohist
                        THEN
                           RAISE excp_movetohist;
                        WHEN OTHERS
                        THEN
                           v_errmsg :=
                                 'Error while updateing CMS_CAF_INFO_INV'
                              || SUBSTR (SQLERRM, 1, 200);
                           RAISE excp_movetohist;
                     END;

                     SELECT seq_dirupld_rowid.NEXTVAL
                       INTO v_rownumber
                       FROM DUAL;

                     BEGIN
                        INSERT INTO cms_caf_info_entry
                                    (cci_inst_code, cci_fiid,
                                     cci_seg12_name_line1,
                                     cci_seg12_name_line2,
                                     cci_seg12_addr_line1,
                                     cci_seg12_city, cci_seg12_state,
                                     cci_seg12_postal_code,
                                     cci_seg12_country_code, cci_row_id,
                                     cci_ins_date, cci_lupd_date,
                                     cci_file_name, cci_upld_stat,
                                     cci_approved, cci_store_id,
                                     cci_appl_code, cci_cust_catg,
                                     CCI_SEG12_NAME_LINE1_ENCR,
                                     CCI_SEG12_NAME_LINE2_ENCR,
                                     CCI_SEG12_ADDR_LINE1_ENCR,
                                     CCI_SEG12_CITY_ENCR,
                                     CCI_SEG12_POSTAL_CODE_ENCR
                                    )
                             VALUES (p_instcode, y.cci_fiid,
                                     y.cci_seg12_name_line1,
                                     y.cci_seg12_name_line2,
                                     y.cci_seg12_addr_line1,
                                     y.cci_seg12_city, y.cci_seg12_state,
                                     y.cci_seg12_postal_code,
                                     y.cci_seg12_country_code, v_rownumber,
                                     SYSDATE, SYSDATE,
                                     i1.cum_file_name, 'P',
                                     'A', y.cci_store_id,
                                     v_applcode, y.cci_cust_catg, 
                                     decode(v_encrypt_enable,'Y',y.cci_seg12_name_line1,fn_emaps_main(y.cci_seg12_name_line1)),
                                     decode(v_encrypt_enable,'Y',y.cci_seg12_name_line2,fn_emaps_main(y.cci_seg12_name_line2)),
                                     decode(v_encrypt_enable,'Y',y.cci_seg12_addr_line1,fn_emaps_main(y.cci_seg12_addr_line1)),
                                     decode(v_encrypt_enable,'Y',y.cci_seg12_city,fn_emaps_main(y.cci_seg12_city)),
                                     decode(v_encrypt_enable,'Y',y.cci_seg12_postal_code,fn_emaps_main(y.cci_seg12_postal_code))
                                    );
                     EXCEPTION
                        WHEN excp_movetohist
                        THEN
                           RAISE excp_movetohist;
                        WHEN OTHERS
                        THEN
                           v_errmsg :=
                                 'Error while inserting CMS_CAF_INFO_ENTRY'
                              || SUBSTR (SQLERRM, 1, 200);
                           RAISE excp_movetohist;
                     END;
                  END IF;

                  --Sn to generate APN for scussesfull application--
                  BEGIN
                     sp_gen_pan_inv
                               (p_instcode,
                                v_applcode,
                                p_lupduser,
                                v_pan,                              --hash PAN
                                v_encr_pan,                    --excrypted pan
                                v_appl_proc_msg, --Application process message
                                v_errmsg                       --Error message
                               );

                     IF v_appl_proc_msg <> 'OK'         --OR  v_errmsg <> 'OK'
                     THEN
                        v_errmsg :=
                              'Error Msg From sp_gen_pan_inv --'
                           || v_appl_proc_msg;
                        RAISE excp_pan_gen;
                     END IF;

                     v_succnt := v_succnt + 1;

                     --Sn to create record in CMS_MERINV_MERPAN with mer id , location id ,card no with 'm'
                     BEGIN
                        INSERT INTO cms_merinv_merpan
                                    (cmm_inst_code, cmm_mer_id,
                                     cmm_location_id, cmm_pancode_encr,
                                     cmm_pan_code, cmm_activation_flag,
                                     cmm_expiry_date, cmm_lupd_date,
                                     cmm_lupd_user, cmm_ins_date,
                                     cmm_ins_user, cmm_ordr_refrno,
                                     cmm_merprodcat_id, cmm_appl_code
                                    )
                             VALUES (p_instcode, y.cci_merc_id,
                                     y.cci_locn_id, v_encr_pan,
                                     v_pan, 'M',
                                     v_expry_date, SYSDATE,
                                     p_lupduser, SYSDATE,
                                     p_lupduser, i1.cum_file_name,
                                     y.cci_merprodcat_id, v_applcode
                                    );

                        IF SQL%ROWCOUNT = 0
                        THEN
                           v_errmsg :=
                                 'No rows inserted cms_merinv_merpan For-- '
                              || v_pan
                              || SUBSTR (SQLERRM, 1, 200);
                           RAISE excp_pan_gen;
                        END IF;
                     EXCEPTION
                        WHEN excp_pan_gen
                        THEN
                           RAISE excp_pan_gen;
                        WHEN OTHERS
                        THEN
                           v_errmsg :=
                                 'Error while inserting cms_merinv_merpan'
                              || SUBSTR (SQLERRM, 1, 200);
                           RAISE excp_pan_gen;
                     END;

                     --En to create record in CMS_MERINV_MERPAN
                     BEGIN
                        UPDATE cms_merinv_ordr
                           SET cmo_success_records =
                                               NVL (cmo_success_records, 0)
                                               + 1
                         WHERE cmo_ordr_refrno = y.cci_file_name;

                        IF SQL%ROWCOUNT = 0
                        THEN
                           v_errmsg :=
                                 'No rows updated cms_merinv_ordr For-- '
                              || v_pan
                              || SUBSTR (SQLERRM, 1, 200);
                           RAISE excp_pan_gen;
                        END IF;
                     EXCEPTION
                        WHEN excp_pan_gen
                        THEN
                           RAISE excp_pan_gen;
                        WHEN OTHERS
                        THEN
                           v_errmsg :=
                                 'Error while Updating  cms_merinv_ordr For-- '
                              || v_pan
                              || SUBSTR (SQLERRM, 1, 200);
                           RAISE excp_pan_gen;
                     END;

                     BEGIN
                        UPDATE cms_merinv_stock
                           SET cms_curr_stock = NVL (cms_curr_stock, 0) + 1
                         WHERE cms_merprodcat_id = y.cci_merprodcat_id
                           AND cms_location_id = y.cci_locn_id;

                        IF SQL%ROWCOUNT = 0
                        THEN
                           v_errmsg :=
                                 'No rows updated cms_merinv_stock For-- '
                              || v_pan
                              || SUBSTR (SQLERRM, 1, 200);
                           RAISE excp_pan_gen;
                        END IF;
                     EXCEPTION
                        WHEN excp_pan_gen
                        THEN
                           RAISE excp_pan_gen;
                        WHEN OTHERS
                        THEN
                           v_errmsg :=
                                 'Error while Updating  cms_merinv_stock For-- '
                              || v_pan
                              || SUBSTR (SQLERRM, 1, 200);
                           RAISE excp_pan_gen;
                     END;
                  END;

                  --En to generate APN for scussesfull application--
                  COMMIT;
               EXCEPTION
                  WHEN excp_pan_gen
                  THEN
                     --   ROLLBACK TO v_savepoint;
                     lp_cms_error_log (p_instcode,
                                       i1.cum_file_name,
                                       y.cci_row_id,
                                       v_errmsg,
                                       p_lupduser,
                                       SYSDATE,
                                       'Contact Site Administrator'
                                      );

                     UPDATE cms_merinv_ordr
                        SET cmo_error_records = NVL (cmo_error_records, 0) + 1,
                        cmo_process_flag = 'E'
                      WHERE cmo_ordr_refrno = y.cci_file_name
                      AND CMO_INST_CODE=p_instcode;--Modified for the mantis ID :14105 of DFCHOST-344
                      --AND cmo_process_flag = 'N';
                  WHEN excp_movetohist
                  THEN
                     ROLLBACK TO v_savepoint;
                     lp_cms_error_log (p_instcode,
                                       i1.cum_file_name,
                                       y.cci_row_id,
                                       v_errmsg,
                                       p_lupduser,
                                       SYSDATE,
                                       'Contact Site Administrator'
                                      );

                     UPDATE cms_caf_info_inv
                        SET cci_upld_stat = 'E',             --processing Over
                            cci_process_msg = v_errmsg
                      WHERE cci_file_name = i1.cum_file_name
                        AND cci_row_id = y.cci_row_id
                        AND cci_inst_code = p_instcode;

                     UPDATE cms_summary_merinv
                        SET csm_error_records = csm_error_records + 1,
                            csm_tot_records = csm_tot_records + 1
                      WHERE csm_file_name = i1.cum_file_name;

                      --Added for the mantis ID :14105 of DFCHOST-344
                      UPDATE cms_merinv_ordr
                        SET cmo_error_records = NVL (cmo_error_records, 0) + 1,
                        cmo_process_flag = 'E'
                      WHERE cmo_ordr_refrno = y.cci_file_name
                      AND CMO_INST_CODE=p_instcode;
                     -- AND cmo_process_flag = 'N';
                  WHEN OTHERS
                  THEN
                     ROLLBACK TO v_savepoint;
                     lp_cms_error_log (p_instcode,
                                       i1.cum_file_name,
                                       y.cci_row_id,
                                       v_errmsg,
                                       p_lupduser,
                                       SYSDATE,
                                       'Contact Site Administrator'
                                      );

                     UPDATE cms_caf_info_inv
                        SET cci_upld_stat = 'E',
                            cci_process_msg = v_errmsg
                      WHERE cci_file_name = i1.cum_file_name
                        AND cci_row_id = y.cci_row_id
                        AND cci_inst_code = p_instcode;

                     UPDATE cms_summary_merinv
                        SET csm_error_records = csm_error_records + 1,
                            csm_tot_records = csm_tot_records + 1
                      WHERE csm_file_name = i1.cum_file_name;

                      --Added for the mantis ID :14105 of DFCHOST-344
                      UPDATE cms_merinv_ordr
                        SET cmo_error_records = NVL (cmo_error_records, 0) + 1,
                        cmo_process_flag = 'E'
                      WHERE cmo_ordr_refrno = y.cci_file_name
                      AND CMO_INST_CODE=p_instcode;
                     -- AND cmo_process_flag = 'N';

               END;
            END LOOP;

 
            IF v_shuffleno_cnt >= i1.cmo_nocards_ordr
             or i1.cpc_serl_flag = 0 --changed by Dhiraj G on 14092012
             THEN

            BEGIN
               UPDATE cms_merinv_ordr
                  SET cmo_process_flag = 'Y'
                WHERE cmo_inst_code = p_instcode
                  AND cmo_ordr_refrno = i1.cum_file_name
                  AND cmo_process_flag = 'N';
            EXCEPTION
               WHEN OTHERS
               THEN
                  p_errmsg :=
                        'Error while updating order status '
                     || SUBSTR (SQLERRM, 1, 200);

            END;
         END IF  ;
            IF p_errmsg = 'OK'
            THEN
               v_error := i1.cmo_nocards_ordr - v_succnt;

               IF v_order_process_cnt < i1.cmo_nocards_ordr
               THEN
                  v_generate := i1.cmo_nocards_ordr - v_order_process_cnt;
                  v_result :=
                        v_succnt
                     || ' Number of Cards Generated Out Of '
                     || i1.cmo_nocards_ordr
                     || '. Need To Generate-- '
                     || v_generate
                     || ' Shuffle Numbers .'
                     || ' Number Of Records In Error --'
                     || v_error
                     || ' . ';
               ELSE
                  v_result :=
                        v_succnt
                     || ' Number of Cards Generated Out Of '
                     || ' Number Of Records In Error --'
                     || v_error
                     || ' . ';
               END IF;

               BEGIN
                  INSERT INTO cms_serl_error
                              (cse_inst_code, cse_prod_code,
                               cse_prod_catg, cse_ordr_rfrno,
                               cse_ordr_cnt, cse_sucs_cnt,
                               cse_eror_cnt, cse_err_mseg
                              )
                       VALUES (i1.cmp_inst_code, i1.cmp_prod_code,
                               i1.cmp_prod_cattype, i1.cum_file_name,
                               i1.cmo_nocards_ordr, v_succnt,
                               i1.cmo_nocards_ordr - v_succnt, v_result
                              );
               EXCEPTION
                  WHEN exp_reject_file
                  THEN
                     RAISE exp_reject_file;
                  WHEN OTHERS
                  THEN
                     v_errmsg :=
                           'Error While InsertING In CMS_SERL_ERROR For Order  -- '
                        || i1.cum_file_name
                        || SUBSTR (SQLERRM, 1, 200);
                     RAISE exp_reject_file;
               END;
            END IF;
         ELSE
            lp_cms_error_log (p_instcode,
                              i1.cum_file_name,
                              NULL,
                              'File Allready Processed ',
                              p_lupduser,
                              SYSDATE,
                              'Contact Site Administrator'
                             );
         END IF;
      EXCEPTION                            --<< EXCEPTION LOOP C1(FILE WISE)>>
         WHEN exp_reject_file
         THEN
            ROLLBACK;
       IF   V_DONOT_MARK_ERROR <>1 THEN
            BEGIN
               UPDATE cms_merinv_ordr
                  SET cmo_process_flag = 'E'
                WHERE cmo_inst_code = p_instcode
                  AND cmo_ordr_refrno = i1.cum_file_name
                  AND cmo_process_flag = 'N';
            EXCEPTION
               WHEN OTHERS
               THEN
                  p_errmsg :=
                        'Error while updating order status '
                     || SUBSTR (SQLERRM, 1, 200);
                  RAISE excp_movetohist;
            END;
       END IF  ;
            lp_cms_error_log (p_instcode,
                              i1.cum_file_name,
                              NULL,
                              p_errmsg,
                              p_lupduser,
                              SYSDATE,
                              'Contact Site Administrator'
                             );
         WHEN OTHERS
         THEN
            ROLLBACK;
            p_errmsg :=
                   'Error while processing file ' || SUBSTR (SQLERRM, 1, 200);

            BEGIN
               UPDATE cms_merinv_ordr
                  SET cmo_process_flag = 'E'
                WHERE cmo_inst_code = p_instcode
                  AND cmo_ordr_refrno = i1.cum_file_name
                  AND cmo_process_flag = 'N';
            EXCEPTION
               WHEN OTHERS
               THEN
                  p_errmsg :=
                        'Error while updating order status '
                     || SUBSTR (SQLERRM, 1, 200);
                  RAISE excp_movetohist;
            END;

            lp_cms_error_log (p_instcode,
                              i1.cum_file_name,
                              NULL,
                              p_errmsg,
                              p_lupduser,
                              SYSDATE,
                              'Contact Site Administrator'
                             );
      END;
   END LOOP;

   p_errmsg := 'OK';
EXCEPTION
   WHEN excp_movetohist
   THEN
      ROLLBACK;
      lp_cms_error_log (p_instcode,
                        'Exception Move To hist ',
                        1,
                        p_errmsg,
                        p_lupduser,
                        SYSDATE,
                        'Contact Site Administrator'
                       );
   WHEN OTHERS
   THEN
      ROLLBACK;
      lp_cms_error_log (p_instcode,
                        'Main Exception  ',
                        1,
                        p_errmsg,
                        p_lupduser,
                        SYSDATE,
                        'Contact Site Administrator'
                       );
END;
/
show error