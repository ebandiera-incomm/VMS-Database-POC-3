CREATE OR REPLACE PACKAGE VMSCMS.migr_entry_newcaf_pkg
AS
-- MIGRATION PROCESSS STARTS WITH TIS PROCEDURE
   PROCEDURE migr_start_process (
      p_instcode   IN       NUMBER,
      p_lupduser   IN       NUMBER,
      p_errmsg     OUT      VARCHAR2
   );

   PROCEDURE migr_create_cust_pkg (
      p_instcode          IN       NUMBER,
      p_custtype          IN       NUMBER,
      p_corpcode          IN       NUMBER,
      p_custstat          IN       CHAR,
      p_salutcode         IN       VARCHAR2,
      p_firstname         IN       VARCHAR2,
      p_midname           IN       VARCHAR2,
      p_lastname          IN       VARCHAR2,
      p_dob               IN       DATE,
      p_gender            IN       CHAR,
      p_marstat           IN       CHAR,
      p_permid            IN       VARCHAR2,
      p_email1            IN       VARCHAR2,
      p_email2            IN       VARCHAR2,
      p_mobl1             IN       VARCHAR2,
      p_mobl2             IN       VARCHAR2,
      p_lupduser          IN       NUMBER,
      p_ssn               IN       VARCHAR2,
      p_maidname          IN       VARCHAR2,
      p_hobby             IN       VARCHAR2,
      p_empid             IN       VARCHAR2,
      p_catg_code         IN       VARCHAR2,
      --p_custid          IN       NUMBER,
      p_gen_custdata      IN       type_cust_rec_array,
      p_cust_username     IN       VARCHAR2,
      p_cust_password     IN       VARCHAR2,
      p_secu_que1         IN       VARCHAR2,
      p_secu_ans1         IN       VARCHAR2,
      p_secu_que2         IN       VARCHAR2,
      p_secu_ans2         IN       VARCHAR2,
      p_secu_que3         IN       VARCHAR2,
      p_secu_ans3         IN       VARCHAR2,
      p_kyc_flag          IN       VARCHAR2,
      --Added by Pankaj S. for KYC flag,
      p_id_type           IN       VARCHAR2,
      p_id_issuer         IN       VARCHAR2,
      p_idissuence_date   IN       DATE,
      p_idexpry_date      IN       DATE,
       --Sn 2.1 onward changes
      p_gproptin_flag     IN     VARCHAR2,
      p_prodcode          IN     VARCHAR2,
      --En 2.1 onward changes
      p_custcode          OUT      NUMBER,
      p_migr_err_code     OUT      VARCHAR2,
      p_migr_err_desc     OUT      VARCHAR2,
      p_errmsg            OUT      VARCHAR2
   );

   PROCEDURE migr_create_addr_pkg (
      p_instcode        IN       NUMBER,
      p_custcode        IN       NUMBER,
      p_add1            IN       VARCHAR2,
      p_add2            IN       VARCHAR2,
      p_add3            IN       VARCHAR2,
      p_pincode         IN       VARCHAR2,
      p_phon1           IN       VARCHAR2,
      p_phon2           IN       VARCHAR2,
      p_officno         IN       VARCHAR2,
      p_email           IN       VARCHAR2,
      p_cntrycode       IN       NUMBER,
      p_cityname        IN       VARCHAR2,
      p_switchstat      IN       VARCHAR2,
      p_fax1            IN       VARCHAR2,
      p_addrflag        IN       CHAR,
      p_comm_type       IN       CHAR,
      p_lupduser        IN       NUMBER,
      p_genaddr_data    IN       type_addr_rec_array,
      p_addrcode        OUT      NUMBER,
      p_migr_err_code   OUT      VARCHAR2,
      p_migr_err_desc   OUT      VARCHAR2,
      p_errmsg          OUT      VARCHAR2
   );

   PROCEDURE migr_create_acct_pcms_pkg (
      p_instcode              IN       NUMBER,
      p_acctno                IN       VARCHAR2,
      p_holdcount             IN       NUMBER,
      p_currbran              IN       VARCHAR2,
      p_billaddr              IN       NUMBER,
      p_accttype              IN       NUMBER,
      p_acctstat              IN       NUMBER,
      p_acctgen_date          IN       DATE,
      p_avail_bal             IN       NUMBER,
      p_ledg_bal              IN       NUMBER,
      p_svngacct_reopn_date   IN       DATE,
      p_svngacct_intrstamt    IN       NUMBER,
      p_initialtopup_amt      IN  NUMBER,  --2.1 onward changes
      p_lupduser              IN       NUMBER,
      p_dup_flag              OUT      VARCHAR2,
      p_acctid                OUT      NUMBER,
      p_migr_err_code         OUT      VARCHAR2,
      p_migr_err_desc         OUT      VARCHAR2,
      p_errmsg                OUT      VARCHAR2
   );

   PROCEDURE migr_create_holder_pkg (
      p_instcode        IN       NUMBER,
      p_custcode        IN       NUMBER,
      p_acctid          IN       NUMBER,
      p_acctname        IN       VARCHAR2,
      p_lupduser        IN       NUMBER,
      p_holdposn        OUT      NUMBER,
      p_migr_err_code   OUT      VARCHAR2,
      p_migr_err_desc   OUT      VARCHAR2,
      p_errmsg          OUT      VARCHAR2
   );

   PROCEDURE migr_create_appl_pcms_pkg (
      p_instcode               IN       NUMBER,
      p_assocode               IN       NUMBER,
      p_insttype               IN       NUMBER,
      p_applno                 IN       VARCHAR2,
      p_appldate               IN       DATE,
      p_regdate                IN       DATE,
      p_custcode               IN       NUMBER,
      p_applbran               IN       VARCHAR2,
      p_prodcode               IN       VARCHAR2,
      p_cardtype               IN       NUMBER,
      p_custcatg               IN       NUMBER,
      p_activedate             IN       DATE,
      p_exprydate              IN       DATE,
      p_dispname               IN       VARCHAR2,
      p_limtamt                IN       NUMBER,
      p_addonissu              IN       CHAR,
      p_usagelimt              IN       NUMBER,
      p_totacct                IN       NUMBER,
      p_addonstat              IN       CHAR,
      p_addonlink              IN       NUMBER,
      p_billaddr               IN       NUMBER,
      p_chnlcode               IN       NUMBER,
      p_request_id             IN       VARCHAR2,
      p_payment_ref            IN       VARCHAR2,
      p_appluser               IN       NUMBER,
      p_lupduser               IN       NUMBER,
      p_initial_topup_amount   IN       NUMBER,
      p_starter_crd_flag       IN       VARCHAR2,
      p_applcode               OUT      NUMBER,
      p_migr_err_code          OUT      VARCHAR2,
      p_migr_err_desc          OUT      VARCHAR2,
      p_errmsg                 OUT      VARCHAR2
   );

   PROCEDURE migr_create_appldet_pkg (
      p_instcode        IN       NUMBER,
      p_applcode        IN       NUMBER,
      p_acctid          IN       NUMBER,
      p_acctv_posn      IN       NUMBER,
      p_lupduser        IN       NUMBER,
      p_migr_err_code   OUT      VARCHAR2,
      p_migr_err_desc   OUT      VARCHAR2,
      p_errmsg          OUT      VARCHAR2
   );

   /*PROCEDURE migr_card_proc_pkg (
      p_instcode                 IN       NUMBER,
      p_applcode                 IN       NUMBER,
      p_card_no                  IN       VARCHAR2,
      p_card_stat                IN       VARCHAR2,
      p_pangen_date              IN       DATE,
      p_online_atm_limit         IN       NUMBER,
      p_offline_atm_limit        IN       NUMBER,
      p_online_pos_limit         IN       NUMBER,
      p_offline_pos_limit        IN       NUMBER,
      p_online_aggr_limit        IN       NUMBER,
      p_offline_aggr_limit       IN       NUMBER,
      p_online_mmpos_limit       IN       NUMBER,
      p_offline_mmpos_limit      IN       NUMBER,
      p_pin_offset               IN       VARCHAR2,
      p_pin_gen_date_time        IN       DATE,
      p_pin_gen_flag             IN       VARCHAR2,
      p_emboss_gen_date_time     IN       DATE,
      p_emboss_gen_flag          IN       VARCHAR2,
      p_next_billing_date        IN       DATE,
      p_next_monthly_bill_date   IN       DATE,
      p_ccf_file_name            IN       VARCHAR2,
      p_serial_number            IN       NUMBER,
      p_proxy_number             IN       NUMBER,
      p_starter_card_flag        IN       VARCHAR2,
      p_initial_load_flag        IN       VARCHAR2,
      p_sms_flag                 IN       VARCHAR2,
      p_email_flag               IN       VARCHAR2,
      p_pin_offst                IN       VARCHAR2,
      p_lupduser                 IN       NUMBER,
      p_migr_err_code            OUT      VARCHAR2,
      p_migr_err_desc            OUT      VARCHAR2,
      p_errmsg                   OUT      VARCHAR2
   );*/
   PROCEDURE migr_gen_pan_prepaid_cms_pkg (
      p_instcode                 IN       NUMBER,
      p_applcode                 IN       NUMBER,
      p_card_no                  IN       VARCHAR2,
      p_card_stat                IN       VARCHAR2,
      p_pangen_date              IN       DATE,
      p_online_atm_limit         IN       NUMBER,
      p_offline_atm_limit        IN       NUMBER,
      p_online_pos_limit         IN       NUMBER,
      p_offline_pos_limit        IN       NUMBER,
      p_online_aggr_limit        IN       NUMBER,
      p_offline_aggr_limit       IN       NUMBER,
      p_online_mmpos_limit       IN       NUMBER,
      p_offline_mmpos_limit      IN       NUMBER,
      p_pin_offset               IN       VARCHAR2,
      p_pin_gen_date_time        IN       DATE,
      p_pin_gen_flag             IN       VARCHAR2,
      p_emboss_gen_date_time     IN       DATE,
      p_emboss_gen_flag          IN       VARCHAR2,
      p_next_billing_date        IN       DATE,
      p_next_monthly_bill_date   IN       DATE,
      p_ccf_file_name            IN       VARCHAR2,
      p_serial_number            IN       NUMBER,
      p_proxy_number             IN       VARCHAR2,  --NUMBER, --MOdified by Pankaj S. on 20_Sep_2013
      p_starter_card_flag        IN       VARCHAR2,
      p_initial_load_flag        IN       VARCHAR2,
      p_sms_flag                 IN       VARCHAR2,
      p_email_flag               IN       VARCHAR2,
      p_pin_offst                IN       VARCHAR2,
      p_lupduser                 IN       NUMBER,
      p_mer_id                   IN       NUMBER,
      p_locn_id                  IN       VARCHAR2,--Dhiraj GAikwad Modified from NUMBER to VARCHAR2
      p_ordr_rfrno               OUT      VARCHAR2,
      p_migr_err_code            OUT      VARCHAR2,
      p_migr_err_desc            OUT      VARCHAR2,
      p_errmsg                   OUT      VARCHAR2
   );

   PROCEDURE migr_get_state_code_pkg (
      prm_inst_code          IN       NUMBER,
      prm_state_data         IN       VARCHAR2,
      prm_cntry_code         IN       VARCHAR2,
      prm_state_code         OUT      NUMBER,
      prm_swich_state_code   OUT      VARCHAR2,
      prm_migr_err_code      OUT      VARCHAR2,
      prm_migr_err_desc      OUT      VARCHAR2,
      prm_err_msg            OUT      VARCHAR2
   );

   PROCEDURE migr_set_gen_custdata_pkg (
      p_inst_code      IN       NUMBER,
      p_cust_rec       IN       type_cust_rec_array,
      p_cust_rec_out   OUT      type_cust_rec_array,
      p_err_msg        OUT      VARCHAR2
   );

   PROCEDURE migr_transaction_pkg (
      prm_instcode         NUMBER,
      prm_ins_date         DATE,
      prm_ins_user         NUMBER,
      prm_errmsg     OUT   VARCHAR2
   );


   PROCEDURE MIGR_CALLLOG_PKG (
      prm_instcode         NUMBER,
      prm_ins_date         DATE,
      prm_ins_user         NUMBER,
      prm_errmsg     OUT   VARCHAR2
   );

   /*
   PROCEDURE migr_spprt_func_pkg (
      p_instcode    IN       NUMBER,
      p_lupd_user            NUMBER,
      p_errmsg      OUT      VARCHAR2
   );
   */
   PROCEDURE migr_set_gen_addrdata_pkg (
      prm_inst_code      IN       NUMBER,
      prm_addr_rec       IN       type_addr_rec_array,
      prm_addr_rec_out   OUT      type_addr_rec_array,
      prm_err_msg        OUT      VARCHAR2
   );

   PROCEDURE migr_log_success_pkg (
      p_inst_code   IN   NUMBER,
      p_file_name   IN   VARCHAR2,
      p_rec_num     IN   NUMBER,
      p_card_numb   IN   VARCHAR2,
      p_msg         IN   VARCHAR2,
      p_lupduser    IN   NUMBER
   );

   PROCEDURE migr_log_error_pkg (
      p_inst_code       IN   NUMBER,
      p_file_name       IN   VARCHAR2,
      p_rec_numb        IN   NUMBER,
      p_card_numb       IN   VARCHAR2,
      p_type            IN   VARCHAR2,
      p_errmsg          IN   VARCHAR2,
      p_lupduser        IN   NUMBER,
      p_migr_err_code   IN   VARCHAR2,
      p_migr_err_desc   IN   VARCHAR2
   );

   --Sn Added by Pankaj S. for SSN check
   PROCEDURE sp_check_ssn_threshold (
      p_instcode    IN       NUMBER,
      p_ssn         IN       VARCHAR2,
      p_prod_code   IN       VARCHAR2,
      p_resp_msg    OUT      VARCHAR2
   );
--En Added by Pankaj S. for SSN check
END;
/
SHOW ERROR

CREATE OR REPLACE PACKAGE BODY VMSCMS.migr_entry_newcaf_pkg
AS
   PROCEDURE migr_start_process (
      p_instcode   IN       NUMBER,
      p_lupduser   IN       NUMBER,
      p_errmsg     OUT      VARCHAR2
   )
   IS
      v_cust_code                 cms_cust_mast.ccm_cust_code%TYPE;
      v_gcm_cntry_code            gen_cntry_mast.gcm_cntry_code%TYPE;
      v_comm_addr_lin1            migr_caf_info_entry.mci_seg12_addr_line1%TYPE;
      v_comm_addr_lin2            migr_caf_info_entry.mci_seg12_addr_line2%TYPE;
      v_comm_postal_code          migr_caf_info_entry.mci_seg12_postal_code%TYPE;
      v_comm_homephone_no         migr_caf_info_entry.mci_seg12_homephone_no%TYPE;
      v_comm_mobileno             migr_caf_info_entry.mci_seg12_mobileno%TYPE;
      v_comm_emailid              migr_caf_info_entry.mci_seg12_emailid%TYPE;
      v_comm_city                 migr_caf_info_entry.mci_seg12_city%TYPE;
      v_comm_state                migr_caf_info_entry.mci_seg12_state%TYPE;
      v_other_addr_lin1           migr_caf_info_entry.mci_seg13_addr_line1%TYPE;
      v_other_addr_lin2           migr_caf_info_entry.mci_seg13_addr_line2%TYPE;
      v_other_postal_code         migr_caf_info_entry.mci_seg13_postal_code%TYPE;
      v_other_homephone_no        migr_caf_info_entry.mci_seg13_homephone_no%TYPE;
      v_other_mobileno            migr_caf_info_entry.mci_seg13_mobileno%TYPE;
      v_other_emailid             migr_caf_info_entry.mci_seg13_emailid%TYPE;
      v_other_city                migr_caf_info_entry.mci_seg13_city%TYPE;
      v_other_state               migr_caf_info_entry.mci_seg12_state%TYPE;
      v_comm_addrcode             cms_addr_mast.cam_addr_code%TYPE;
      v_other_addrcode            cms_addr_mast.cam_addr_code%TYPE;
      v_switch_acct_type          cms_acct_type.cat_switch_type%TYPE
                                                                 DEFAULT '11';
      v_switch_acct_stat          cms_acct_stat.cas_switch_statcode%TYPE
                                                                  DEFAULT '3';
      v_acct_type                 cms_acct_type.cat_type_code%TYPE;
      v_acct_stat                 cms_acct_mast.cam_stat_code%TYPE;
      v_acct_numb                 cms_acct_mast.cam_acct_no%TYPE;
      v_acct_id                   cms_acct_mast.cam_acct_id%TYPE;
      v_dup_flag                  VARCHAR2 (1);
      v_prod_code                 cms_prod_mast.cpm_prod_code%TYPE;
      v_prod_cattype              cms_prod_cattype.cpc_card_type%TYPE;
      v_inst_bin                  cms_prod_bin.cpb_inst_bin%TYPE;
      v_prod_ccc                  cms_prod_ccc.cpc_prod_sname%TYPE;
      v_custcatg                  cms_prod_ccc.cpc_cust_catg%TYPE;
      v_appl_code                 cms_appl_mast.cam_appl_code%TYPE;
      v_errmsg                    VARCHAR2 (500);
      v_savepoint                 NUMBER                            DEFAULT 1;
      v_gender                    VARCHAR2 (1);
      v_expryparam                cms_bin_param.cbp_param_value%TYPE;
      v_holdposn                  cms_cust_acct.cca_hold_posn%TYPE;
      v_brancheck                 NUMBER (1);
      v_func_code                 cms_func_mast.cfm_func_code%TYPE;
      v_spprt_funccode            cms_func_mast.cfm_func_code%TYPE;
      v_func_desc                 cms_func_mast.cfm_func_desc%TYPE;
      v_spprtfunc_desc            cms_func_mast.cfm_func_desc%TYPE;
      v_catg_code                 cms_prod_mast.cpm_catg_code%TYPE;
      v_check_funccode            NUMBER (1);
      v_check_spprtfunccode       NUMBER (1);
      v_initial_spprtflag         VARCHAR2 (1);
      v_kyc_flag                  VARCHAR2 (1);
      v_instrument_realised       VARCHAR2 (1);
      v_comm_type                 CHAR (1);
      v_cust_data                 type_cust_rec_array;
      v_addr_data1                type_addr_rec_array;
      v_addr_data2                type_addr_rec_array;
      v_appl_data                 type_appl_rec_array;
      v_seg31acctnum_data         type_acct_rec_array;
      exp_reject_record_main      EXCEPTION;
      --exp_process_record      EXCEPTION;
      v_comm_officeno             migr_caf_info_entry.mci_seg12_officephone_no%TYPE;
      v_comm_cntrycode            migr_caf_info_entry.mci_seg12_country_code%TYPE;
      v_other_officeno            migr_caf_info_entry.mci_seg13_officephone_no%TYPE;
      v_other_cntrycode           migr_caf_info_entry.mci_seg12_country_code%TYPE;
      v_gcm_othercntry_code       gen_cntry_mast.gcm_cntry_code%TYPE;
      t_acct_num                  cms_acct_mast.cam_acct_no%TYPE;
      v_profile_code              cms_prod_cattype.cpc_profile_code%TYPE;
      v_cpm_catg_code             cms_prod_mast.cpm_catg_code%TYPE;
      v_prod_prefix               cms_prod_cattype.cpc_prod_prefix%TYPE;
      v_programid                 VARCHAR2 (4);
      v_expry_date                DATE;
      v_validity_period           cms_bin_param.cbp_param_value%TYPE;
      v_title                     cms_cust_mast.ccm_salut_code%TYPE;
      v_acct_branch               VARCHAR2 (4);
      v_acct_gen_date             VARCHAR2 (20);
      v_avail_bal                 VARCHAR2 (20);
      v_ledg_bal                  VARCHAR2 (20);
      v_savng_accreopen_date      VARCHAR2 (20);
      v_savng_acct_interest_amt   VARCHAR2 (20);
      v_rec_cnt                   NUMBER (1);
      v_migr_err_code             VARCHAR2 (10);
      v_migr_err_desc             VARCHAR2 (30);
      v_count                     NUMBER (1);
      v_mci_cust_catg             VARCHAR2 (5)                       := 'PCC';
      v_cnt                       NUMBER (1);
      v_cnt1                      NUMBER (1);
      v_hash_pan                  cms_appl_pan.cap_pan_code%TYPE;
      v_encr_pan                  cms_appl_pan.cap_pan_code_encr%TYPE;
      v_dum                       NUMBER (1);
      indx_val                    NUMBER (1);
      v_commit_pnt                migr_ctrl_table.mct_ctrl_numb%TYPE;
      v_rec_proc                  NUMBER (6)                             := 0;
      v_rowid                     VARCHAR2 (10);
      v_exist_acctid              cms_acct_mast.cam_acct_id%TYPE;
      v_exist_cust                cms_cust_mast.ccm_cust_code%TYPE;
      v_custmoer_id               cms_cust_mast.ccm_cust_id%TYPE;
      v_ordr_rfrno                cms_merinv_ordr.cmo_ordr_refrno%TYPE;

      TYPE migr_acct_no_tab IS TABLE OF VARCHAR2 (20)
         INDEX BY PLS_INTEGER;

      migr_acct_data              migr_acct_no_tab;

      TYPE migr_prim_acct_detl IS RECORD (
         pri_acctno               VARCHAR2 (20),
         pri_branid               VARCHAR2 (4),
         pri_accttype             VARCHAR2 (2),
         pri_acctstat             VARCHAR2 (2),
         pri_acctgen              VARCHAR2 (20),
         pri_avaibal              VARCHAR2 (20),
         pri_ledgbal              VARCHAR2 (20),
         pri_svngacct_reopndate   VARCHAR2 (20),
         pri_svngacct_intrstamt   VARCHAR2 (20)
      );

      TYPE migr_prim_acct_detl_tab IS TABLE OF migr_prim_acct_detl
         INDEX BY PLS_INTEGER;

      migr_prim_acct_detl_data    migr_prim_acct_detl_tab;

      TYPE migr_sec_acct_detl IS RECORD (
         sec_acctno               VARCHAR2 (20),
         sec_branid               VARCHAR2 (4),
         sec_accttype             VARCHAR2 (2),
         sec_acctstat             VARCHAR2 (2),
         sec_acctgen              VARCHAR2 (20),
         sec_avaibal              VARCHAR2 (20),
         sec_ledgbal              VARCHAR2 (20),
         sec_svngacct_reopndate   VARCHAR2 (20),
         sec_svngacct_intrstamt   VARCHAR2 (20)
      );

      TYPE migr_sec_acct_detl_tab IS TABLE OF migr_sec_acct_detl
         INDEX BY PLS_INTEGER;

      migr_sec_acct_detl_data     migr_sec_acct_detl_tab;

       V_PACKAGE_TYPE  CMS_CAF_INFO_ENTRY.CCI_PACKAGE_TYPE%TYPE; --Dhiraj Gaikwad
       V_PACKAGEID_CNT number(20) ; --Dhiraj Gaikwad
               V_PROD_ID  CMS_PROD_CATTYPE.CPC_PROD_ID%type ; --Dhiraj Gaikwad
                      V_PACKAGE_ID  CMS_PROD_CATTYPE.CPC_PACKAGE_ID%type ; --Dhiraj Gaikwad
      CURSOR c
      IS
         SELECT mci_inst_code, mci_file_name, mci_row_id, mci_appl_code,
                mci_appl_no, mci_pan_code, mci_mbr_numb, mci_crd_stat,
                mci_exp_dat, mci_crd_typ, mci_prod_code, mci_card_type,
                mci_seg12_branch_num, mci_fiid, mci_title,
                mci_seg12_name_line1, mci_seg12_name_line2, mci_birth_date,
                mci_mothers_maiden_name, mci_ssn, mci_hobbies,  --mci_cust_id,
                mci_seg12_addr_line1, mci_seg12_addr_line2, mci_seg12_city,
                mci_seg12_state, mci_seg12_postal_code,
                mci_seg12_country_code, mci_seg12_mobileno,
                mci_seg12_homephone_no, mci_seg12_officephone_no,
                mci_seg12_emailid, mci_seg13_addr_line1, mci_seg13_addr_line2,
                mci_seg13_city, mci_seg13_state, mci_seg13_postal_code,
                mci_seg13_country_code, mci_seg13_mobileno,
                mci_seg13_homephone_no, mci_seg13_officephone_no,
                mci_seg13_emailid, mci_seg31_lgth, mci_seg31_acct_cnt,
                mci_seg31_typ, mci_seg31_num, mci_seg31_stat, mci_prod_amt,
                mci_fee_amt, mci_tot_amt, mci_payment_mode, mci_instrument_no,
                mci_emp_id, mci_kyc_flag, mci_addon_flag, mci_ins_user,
                mci_ins_date, mci_lupd_user, mci_cust_catg,
                mci_customer_param1, mci_customer_param2, mci_customer_param3,
                mci_customer_param4, mci_customer_param5, mci_customer_param6,
                mci_customer_param7, mci_customer_param8, mci_customer_param9,
                mci_customer_param10, mci_seg12_addr_param1,
                mci_seg12_addr_param2, mci_seg12_addr_param3,
                mci_seg12_addr_param4, mci_seg12_addr_param5,
                mci_seg12_addr_param6, mci_seg12_addr_param7,
                mci_seg12_addr_param8, mci_seg12_addr_param9,
                mci_seg12_addr_param10, mci_seg13_addr_param1,
                mci_seg13_addr_param2, mci_seg13_addr_param3,
                mci_seg13_addr_param4, mci_seg13_addr_param5,
                mci_seg13_addr_param6, mci_seg13_addr_param7,
                mci_seg13_addr_param8, mci_seg13_addr_param9,
                mci_seg13_addr_param10, mci_seg31_num_param1,
                mci_seg31_num_param2, mci_seg31_num_param3,
                mci_seg31_num_param4, mci_seg31_num_param5,
                mci_seg31_num_param6, mci_seg31_num_param7,
                mci_seg31_num_param8, mci_seg31_num_param9,
                mci_seg31_num_param10, mci_custappl_param1,
                mci_custappl_param2, mci_custappl_param3, mci_custappl_param4,
                mci_custappl_param5, mci_custappl_param6, mci_custappl_param7,
                mci_custappl_param8, mci_custappl_param9, mci_marital_stat,
                mci_customer_username, mci_customer_password, mci_seg31_num2,
                mci_seg31_num3, mci_seg31_num4, mci_seg31_num5,
                mci_savigs_acct_number, mci_starter_crd_flag,
                mci_pan_active_date, mci_pan_expiry_date, mci_pan_gen_date,
                mci_atm_online_limit, mci_atm_offline_limit,
                mci_pos_online_limit, mci_pos_offline_limit,
                mci_online_aggr_limit, mci_offline_aggr_limit,
                mci_mmpos_online_limit, mci_mmpos_offline_limit,
                mci_pin_offset, mci_pin_gen_date, mci_emboss_gen_date,
                mci_init_load_flag, mci_proxy_numb, mci_serial_number,
                mci_ccf_file_name, mci_next_month_bill_date, mci_question_one,
                mci_answer_one, mci_question_two, mci_answer_two,
                mci_question_three, mci_answer_three, mci_next_bill_date,
                mci_pin_flag, mci_emboss_flag, mci_sms_alert_flag,
                mci_email_alert_flag, mci_rec_num, mci_lupd_date,
                mci_comments, ROWID migr_rowid, mci_id_type,
                mci_store_id                              --added by Pankaj S.
                            ,
                mci_merc_id, mci_inv_flag              -- Added on 20-JUN-2013
                                         ,
                mci_id_issuer, mci_id_issuance_date,
                mci_id_expiry_date,                     -- Added on 25-JUN-2013
                mci_reg_date  ,                          -- Added on 09-Oct-2013
                mci_package_type --Dhiraj Gaikwad
           FROM migr_caf_info_entry
          WHERE mci_inst_code = p_instcode -- Added on 16-sep-2013
          and   mci_proc_flag = 'N'  and rownum<100001 ;
/*mci_approved = 'A'
AND mci_inst_code = p_instcode
AND mci_upld_stat = 'P'
AND mci_row_id = p_rowid
AND mci_kyc_flag = 'Y';*/ -- COMMENTED BY GANESH
   BEGIN                       -- MIGRATION PROCESSS STARTS WITH TIS PROCEDURE
      p_errmsg := 'OK';
      v_errmsg := 'OK';
      v_count := 1;
      v_cust_data := type_cust_rec_array ();
      v_addr_data1 := type_addr_rec_array ();
      v_addr_data2 := type_addr_rec_array ();
      v_appl_data := type_appl_rec_array ();
      v_seg31acctnum_data := type_acct_rec_array ();

/*   BEGIN SELECT COUNT(1)
   INTO V_COUNT
    FROM migr_caf_info_entry
    WHERE MCI_PROC_FLAG = 'N' AND ROWNUM < 2;
*/
      BEGIN
         SELECT 1
           INTO v_dum
           FROM cms_inst_mast
          WHERE cim_inst_code = p_instcode;
      EXCEPTION
         WHEN NO_DATA_FOUND
         THEN
            p_errmsg :=
                  'No such Institution '
               || p_instcode
               || ' exists in Institution master ';
            RETURN;
         WHEN OTHERS
         THEN
            p_errmsg :=
                  'Exception While Validating Institution '
               || SUBSTR (SQLERRM, 1, 200);
            RETURN;
      END;

      BEGIN
         SELECT mct_ctrl_numb
           INTO v_commit_pnt
           FROM migr_ctrl_table
          WHERE mct_ctrl_code = p_instcode AND mct_ctrl_key = 'COMMIT_PARAM';
      EXCEPTION
         WHEN OTHERS
         THEN
            v_commit_pnt := 1000;
      END;

      LOOP
         EXIT WHEN v_count = 0;

         FOR i IN c
         LOOP
            --Initialize the common loop variable
            v_errmsg := 'OK';
            v_cust_data.DELETE;
            v_addr_data1.DELETE;
            v_addr_data2.DELETE;
            v_seg31acctnum_data.DELETE;
            v_appl_data.DELETE;
            v_rec_cnt := 1;
            v_cnt := 0;
            v_cnt1 := 0;
            indx_val := 1;
            v_ordr_rfrno := NULL;
            SAVEPOINT v_savepoint;
            v_rec_proc := v_rec_proc + 1;

            BEGIN
               BEGIN
                  v_hash_pan := gethash (i.mci_pan_code);
               EXCEPTION
                  WHEN OTHERS
                  THEN
                     v_errmsg :=
                           'Error while converting pan (hash) during precheck '
                        || SUBSTR (SQLERRM, 1, 200);
                     v_migr_err_code := 'MIG-1_001';
                     v_migr_err_desc := 'EXCP_PAN_HASHCONV_PRE';
                     RAISE exp_reject_record_main;
               END;

               BEGIN
                  v_dum := 0;

                  SELECT 1
                    INTO v_dum
                    FROM cms_appl_pan
                   WHERE cap_inst_code = p_instcode
                     AND cap_pan_code = v_hash_pan;

                  IF v_dum = 1
                  THEN
                     v_errmsg := 'Card Already Present in CMS ';
                     v_migr_err_code := 'MIG-1_003';
                     v_migr_err_desc := 'EXCP_CAR_ALREDY_EXIST';
                     RAISE exp_reject_record_main;
                  END IF;
               EXCEPTION
                  WHEN NO_DATA_FOUND
                  THEN
                     v_errmsg := 'OK';
                  WHEN exp_reject_record_main
                  THEN
                     RAISE exp_reject_record_main;
                  WHEN OTHERS
                  THEN
                     v_errmsg :=
                           'Error while Searching For card '
                        || i.mci_pan_code
                        || ' as -'
                        || SUBSTR (SQLERRM, 1, 100);
                     v_migr_err_code := 'MIG-1_';
                     v_migr_err_desc := 'OTHER_THAN_PRDEFINE_EXCP';
                     RAISE exp_reject_record_main;
               END;

               -- Sn find prod
               BEGIN
                  SELECT cpm_prod_code, cpm_catg_code
                    INTO v_prod_code, v_catg_code
                    FROM cms_prod_mast
                   WHERE cpm_inst_code = p_instcode
                     AND cpm_prod_code = i.mci_prod_code
                     AND cpm_marc_prod_flag = 'N';
               EXCEPTION
                  WHEN NO_DATA_FOUND
                  THEN
                     v_errmsg :=
                           'Product code '
                        || i.mci_prod_code
                        || ' is not defined in the master';
                     v_migr_err_code := 'MIG-1_030';
                     v_migr_err_desc := 'PROD_NOT_DEFINED';
                     RAISE exp_reject_record_main;
                  WHEN OTHERS
                  THEN
                     v_errmsg :=
                           'Error while selecting product '
                        || SUBSTR (SQLERRM, 1, 200);
                     v_migr_err_code := 'MIG-1_';
                     v_migr_err_desc := 'OTHER_THAN_PRDEFINE_EXCP';
                     RAISE exp_reject_record_main;
               END;

               -- En find prod
               -- Sn check in prod bin
               BEGIN
                  SELECT cpb_inst_bin
                    INTO v_inst_bin
                    FROM cms_prod_bin
                   WHERE cpb_inst_code = p_instcode
                     AND cpb_prod_code = i.mci_prod_code
                     AND cpb_marc_prodbin_flag = 'N'
                     AND cpb_active_bin = 'Y';
               EXCEPTION
                  WHEN NO_DATA_FOUND
                  THEN
                     v_errmsg :=
                           'Product code '
                        || i.mci_prod_code
                        || ' is not attached to BIN '
                        || SUBSTR (i.mci_pan_code, 1, 6);
                     v_migr_err_code := 'MIG-1_031';
                     v_migr_err_desc := 'PROD_BIN_NOT_ATTACHED';
                     RAISE exp_reject_record_main;
                  WHEN OTHERS
                  THEN
                     v_errmsg :=
                           'Error while selecting product and bin dtl '
                        || SUBSTR (SQLERRM, 1, 200);
                     v_migr_err_code := 'MIG-1_';
                     v_migr_err_desc := 'OTHER_THAN_PRDEFINE_EXCP';
                     RAISE exp_reject_record_main;
               END;

               -- En check in prod bin
               -- Sn find prod cattype
               BEGIN
                  SELECT cpc_card_type
                    INTO v_prod_cattype
                    FROM cms_prod_cattype
                   WHERE cpc_inst_code = p_instcode
                     AND cpc_prod_code = i.mci_prod_code
                     AND cpc_card_type = TO_NUMBER (i.mci_card_type);
               EXCEPTION
                  WHEN NO_DATA_FOUND
                  THEN
                     v_errmsg :=
                           'Product code '
                        || i.mci_prod_code
                        || 'is not attached to cattype '
                        || i.mci_card_type;
                     v_migr_err_code := 'MIG-1_032';
                     v_migr_err_desc := 'PROD_CATTYP_NOT_ATTACHED';
                     RAISE exp_reject_record_main;
                  WHEN OTHERS
                  THEN
                     v_errmsg :=
                           'Error while selecting product cattype '
                        || SUBSTR (SQLERRM, 1, 200);
                     v_migr_err_code := 'MIG-1_';
                     v_migr_err_desc := 'OTHER_THAN_PRDEFINE_EXCP';
                     RAISE exp_reject_record_main;
               END;

               -- En find prod cattype
               --Sn find the default cust catg
               BEGIN
                  SELECT ccc_catg_code
                    INTO v_custcatg
                    FROM cms_cust_catg
                   WHERE ccc_inst_code = p_instcode
                     AND ccc_catg_sname = v_mci_cust_catg; -- i.mci_cust_catg;
               EXCEPTION
                  WHEN NO_DATA_FOUND
                  THEN
                     v_errmsg :=
                           'Customer Catg code '
                        || v_mci_cust_catg
                        || ' is not defined ';
                     v_migr_err_code := 'MIG-1_033';
                     v_migr_err_desc := 'CUST_CATG_NOT_DEFINED';
                     RAISE exp_reject_record_main;
                  WHEN OTHERS
                  THEN
                     v_errmsg :=
                           'Error while selecting custcatg from master '
                        || SUBSTR (SQLERRM, 1, 200);
                     v_migr_err_code := 'MIG-1_';
                     v_migr_err_desc := 'OTHER_THAN_PRDEFINE_EXCP';
                     RAISE exp_reject_record_main;
               END;

               --En find the default cust
               -- Sn find entry in prod ccc
               BEGIN
                  SELECT cpc_prod_sname
                    INTO v_prod_ccc
                    FROM cms_prod_ccc
                   WHERE cpc_inst_code = p_instcode
                     AND cpc_prod_code = i.mci_prod_code
                     AND cpc_card_type = i.mci_card_type
                     AND cpc_cust_catg = v_custcatg;
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
                             VALUES (p_instcode, v_custcatg,
                                     i.mci_card_type, i.mci_prod_code,
                                     p_lupduser, SYSDATE,
                                     p_lupduser, SYSDATE,
                                     '1', '1', 'Default'
                                    );
                     EXCEPTION
                        WHEN OTHERS
                        THEN
                           v_errmsg :=
                                   'Error while creating a entry in prod_ccc';
                           v_migr_err_code := 'MIG-1_';
                           v_migr_err_desc := 'OTHER_THAN_PRDEFINE_EXCP';
                           RAISE exp_reject_record_main;
                     END;
                  WHEN OTHERS
                  THEN
                     v_errmsg :=
                           'Error while selecting prodccc detail from master '
                        || SUBSTR (SQLERRM, 1, 200);
                     v_migr_err_code := 'MIG-1_';
                     v_migr_err_desc := 'OTHER_THAN_PRDEFINE_EXCP';
                     RAISE exp_reject_record_main;
               END;

               -- En find entry in prod ccc
               BEGIN
                  SELECT cpm_profile_code, cpm_catg_code, cpc_prod_prefix,
                         cpm_program_id
                    INTO v_profile_code, v_cpm_catg_code, v_prod_prefix,
                         v_programid
                    FROM cms_prod_cattype, cms_prod_mast
                   WHERE cpc_inst_code = p_instcode
                     AND cpc_inst_code = cpm_inst_code
                     AND cpc_prod_code = i.mci_prod_code
                     AND cpc_card_type = i.mci_card_type
                     AND cpm_prod_code = cpc_prod_code;
               EXCEPTION
                  WHEN NO_DATA_FOUND
                  THEN
                     v_errmsg :=
                           'Profile code not defined for product code '
                        || i.mci_prod_code
                        || 'card type '
                        || i.mci_card_type;
                     v_migr_err_code := 'MIG-1_034';
                     v_migr_err_desc := 'PROD_PROFL_CODE_NOT_DEF';
                     RAISE exp_reject_record_main;
                  WHEN OTHERS
                  THEN
                     v_errmsg :=
                           'Error while selecting Profile code for product code '
                        || i.mci_prod_code
                        || 'card type '
                        || i.mci_card_type
                        || ' as '
                        || SUBSTR (SQLERRM, 1, 300);
                     v_migr_err_code := 'MIG-1_';
                     v_migr_err_desc := 'OTHER_THAN_PRDEFINE_EXCP';
                     RAISE exp_reject_record_main;
               END;

               /*
                Commented 16062013
                IF v_catg_code = 'P'
                THEN
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
                         v_errmsg :=
                              'Master data is not available for card issuance';
                         v_migr_err_code := 'MIG-1_035';
                         v_migr_err_desc := 'CARDISS_MASTDATA_NOT_FOUND';
                         RAISE exp_reject_record_main;
                      WHEN OTHERS
                      THEN
                         v_errmsg :=
                               'Error while selecting funccode detail from master '
                            || SUBSTR (SQLERRM, 1, 200);
                         v_migr_err_code := 'MIG-1_';
                         v_migr_err_desc := 'OTHER_THAN_PRDEFINE_EXCP';
                         RAISE exp_reject_record_main;
                   END;

                   BEGIN
                      SELECT 1
                        INTO v_check_funccode
                        FROM cms_func_prod
                       WHERE cfp_inst_code = p_instcode
                         AND cfp_prod_code = i.mci_prod_code
                         AND cfp_prod_cattype = i.mci_card_type
                         AND cfp_func_code = v_func_code;
                   EXCEPTION
                      WHEN NO_DATA_FOUND
                      THEN
                         v_errmsg :=
                               v_func_desc
                            || ' is not attached to product code '
                            || i.mci_prod_code
                            || ' card type '
                            || i.mci_card_type;
                         v_migr_err_code := 'MIG-1_036';
                         v_migr_err_desc := 'FUN_PROD_NOT_ATTACHED';
                         RAISE exp_reject_record_main;
                      WHEN OTHERS
                      THEN
                         v_errmsg :=
                               'Error while verifing  funccode attachment to Product code  type '
                            || SUBSTR (SQLERRM, 1, 200);
                         v_migr_err_code := 'MIG-1_';
                         v_migr_err_desc := 'OTHER_THAN_PRDEFINE_EXCP';
                         RAISE exp_reject_record_main;
                   END;

                   --En Check card issuance attached to product

                   --Sn check card amount and initial load spprt function
                   IF i.mci_prod_amt > 0
                   THEN
                      --Sn check initial load spprt func
                      BEGIN
                         SELECT cfm_func_code, cfm_func_desc
                           INTO v_spprt_funccode, v_spprtfunc_desc
                           FROM cms_func_mast
                          WHERE cfm_inst_code = p_instcode
                            AND cfm_txn_code = 'IL'
                            AND cfm_txn_mode = '0'
                            AND cfm_delivery_channel = '05';
                      EXCEPTION
                         WHEN NO_DATA_FOUND
                         THEN
                            v_errmsg :=
                               'Master data is not available for initial load';
                            v_migr_err_code := 'MIG-1_037';
                            v_migr_err_desc := 'IL_MASTDATA_NOT_FOUND';
                            RAISE exp_reject_record_main;
                         WHEN OTHERS
                         THEN
                            v_errmsg :=
                                  'Error while selecting funccode detail from master for initial load '
                               || SUBSTR (SQLERRM, 1, 200);
                            v_migr_err_code := 'MIG-1_';
                            v_migr_err_desc := 'OTHER_THAN_PRDEFINE_EXCP';
                            RAISE exp_reject_record_main;
                      END;

                      --En check initial load spprt function

                      --Sn Check card initial load attached to product
                      BEGIN
                         SELECT 1
                           INTO v_check_spprtfunccode
                           FROM cms_func_prod
                          WHERE cfp_inst_code = p_instcode
                            AND cfp_prod_code = i.mci_prod_code
                            AND cfp_prod_cattype = i.mci_card_type
                            AND cfp_func_code = v_spprt_funccode;

                         v_initial_spprtflag := 'Y';
                      EXCEPTION
                         WHEN NO_DATA_FOUND
                         THEN
                            v_errmsg :=
                                  v_spprtfunc_desc
                               || ' is not attached to product code '
                               || i.mci_prod_code
                               || ' card type '
                               || i.mci_card_type;
                            v_migr_err_code := 'MIG-1_038';
                            v_migr_err_desc := 'SPPRTFUN_PROD_NOT_ATTACHED';
                            RAISE exp_reject_record_main;
                         WHEN OTHERS
                         THEN
                            v_errmsg :=
                                  'Error while verifing  funccode attachment to Product code  type for initial load'
                               || SUBSTR (SQLERRM, 1, 200);
                            v_migr_err_code := 'MIG-1_';
                            v_migr_err_desc := 'OTHER_THAN_PRDEFINE_EXCP';
                            RAISE exp_reject_record_main;
                      END;
                   --En Check card initial load attached to product
                   END IF;
                END IF;
               */--En check card amount and initial load spprt function

               --Sn find Branch
               BEGIN
                  SELECT 1
                    INTO v_brancheck
                    FROM cms_bran_mast
                   WHERE cbm_inst_code = p_instcode
                     AND cbm_bran_code = i.mci_fiid;
               EXCEPTION
                  WHEN NO_DATA_FOUND
                  THEN
                     v_errmsg := 'Branch '||i.mci_fiid||' Not defined in master'; --Error message modified by Pankaj S. on 25-Sep-2013
                               -- 'Branch code not defined for  ' || i.mci_fiid;
                     v_migr_err_code := 'MIG-1_039';
                     v_migr_err_desc := 'BRANCH_NOT_DEFINED';
                     RAISE exp_reject_record_main;
                  WHEN OTHERS
                  THEN
                     v_errmsg := 'Error validating branch '  --Error message modified by Pankaj S. on 25-Sep-2013
                          -- 'Error while selecting branch code for  '
                        || i.mci_fiid
                        || ' in master as '  --Error message modified by Pankaj S. on 25-Sep-2013
                        || SUBSTR (SQLERRM, 1, 200);
                     v_migr_err_code := 'MIG-1_';
                     v_migr_err_desc := 'OTHER_THAN_PRDEFINE_EXCP';
                     RAISE exp_reject_record_main;
               END;

               FOR t IN 1 .. migr_acct_data.COUNT ()
               LOOP
                  migr_acct_data (t) := NULL;
               END LOOP;

               --En find customer
               IF TRIM (i.mci_seg31_num) IS NOT NULL
               THEN
                  migr_acct_data (indx_val) := i.mci_seg31_num;
                  indx_val := indx_val + 1;
               END IF;

               IF TRIM (i.mci_seg31_num2) IS NOT NULL
               THEN
                  migr_acct_data (indx_val) := i.mci_seg31_num2;
                  indx_val := indx_val + 1;
               END IF;

               IF TRIM (i.mci_seg31_num3) IS NOT NULL
               THEN
                  migr_acct_data (indx_val) := i.mci_seg31_num3;
                  indx_val := indx_val + 1;
               END IF;

               IF TRIM (i.mci_seg31_num4) IS NOT NULL
               THEN
                  migr_acct_data (indx_val) := i.mci_seg31_num4;
                  indx_val := indx_val + 1;
               END IF;

               IF TRIM (i.mci_seg31_num5) IS NOT NULL
               THEN
                  migr_acct_data (indx_val) := i.mci_seg31_num5;
                  indx_val := indx_val + 1;
               END IF;

               IF TRIM (i.mci_savigs_acct_number) IS NOT NULL
               THEN
                  migr_acct_data (indx_val) := i.mci_savigs_acct_number;
               END IF;

               FOR t IN 1 .. migr_acct_data.COUNT ()
               LOOP
                  BEGIN
                     SELECT mad_branch_id, mad_acct_type, mad_acct_stat,
                            mad_acctgen_date, mad_avail_bal, mad_ledg_bal,
                            mad_savng_acctreopen_date,
                            mad_savng_acct_interest_amt
                       INTO v_acct_branch, v_acct_type, v_acct_stat,
                            v_acct_gen_date, v_avail_bal, v_ledg_bal,
                            v_savng_accreopen_date,
                            v_savng_acct_interest_amt
                       FROM migr_acct_data_temp
                      WHERE mad_acct_numb = migr_acct_data (t)
                        AND mad_proc_flag IN ('N', 'P');

                     --AND mad_proc_flag = 'S';
                     IF v_acct_type = '02' AND v_acct_stat = '3'
                     THEN
                        v_errmsg :=
                              'Savings account can not be the primary account for the customer. Acct no. is '
                           || migr_acct_data (t);
                        v_migr_err_code := 'MIG-0_014';
                        v_migr_err_desc := 'INVALID_PRIM_ACCT';
                        RAISE exp_reject_record_main;
                     END IF;

                     IF v_acct_stat = 3
                     THEN
                        migr_prim_acct_detl_data (1).pri_acctno :=
                                                           migr_acct_data (t);
                        migr_prim_acct_detl_data (1).pri_branid :=
                                                                v_acct_branch;
                        migr_prim_acct_detl_data (1).pri_accttype :=
                                                                  v_acct_type;
                        migr_prim_acct_detl_data (1).pri_acctstat :=
                                                                  v_acct_stat;
                        migr_prim_acct_detl_data (1).pri_acctgen :=
                                                              v_acct_gen_date;
                        migr_prim_acct_detl_data (1).pri_avaibal :=
                                                                  v_avail_bal;
                        migr_prim_acct_detl_data (1).pri_ledgbal :=
                                                                   v_ledg_bal;
                        migr_prim_acct_detl_data (1).pri_svngacct_reopndate :=
                                                       v_savng_accreopen_date;
                        migr_prim_acct_detl_data (1).pri_svngacct_intrstamt :=
                                                    v_savng_acct_interest_amt;
                        v_cnt := v_cnt + 1;
                     ELSE
                        migr_sec_acct_detl_data (v_rec_cnt).sec_acctno :=
                                                           migr_acct_data (t);
                        migr_sec_acct_detl_data (v_rec_cnt).sec_branid :=
                                                                v_acct_branch;
                        migr_sec_acct_detl_data (v_rec_cnt).sec_accttype :=
                                                                  v_acct_type;
                        migr_sec_acct_detl_data (v_rec_cnt).sec_acctstat :=
                                                                  v_acct_stat;
                        migr_sec_acct_detl_data (v_rec_cnt).sec_acctgen :=
                                                              v_acct_gen_date;
                        migr_sec_acct_detl_data (v_rec_cnt).sec_avaibal :=
                                                                  v_avail_bal;
                        migr_sec_acct_detl_data (v_rec_cnt).sec_ledgbal :=
                                                                   v_ledg_bal;
                        migr_sec_acct_detl_data (v_rec_cnt).sec_svngacct_reopndate :=
                                                       v_savng_accreopen_date;
                        migr_sec_acct_detl_data (v_rec_cnt).sec_svngacct_intrstamt :=
                                                    v_savng_acct_interest_amt;
                        v_rec_cnt := v_rec_cnt + 1;
                     END IF;

                     IF v_acct_type = '02'
                     THEN
                        v_cnt1 := v_cnt1 + 1;
                     END IF;
                  EXCEPTION
                     WHEN exp_reject_record_main
                     THEN
                        RAISE exp_reject_record_main;
                     WHEN NO_DATA_FOUND
                     THEN
                        --                        v_errmsg :=
                        --                              'Account Details Not Found For Account Number'
                        --                           || migr_acct_data (t);
                        v_errmsg :=
                           'Not A Valid Account Number To Create The Account Details For The Customer ';
                        v_migr_err_code := 'MIG-1_052';
                        v_migr_err_desc := 'ACCT_DATA_NOT_FOUND';

                        INSERT INTO migr_cust_acct_err
                                    (cae_inst_code, cae_card_num,
                                     cae_acct_numb, cae_eror_mesg
                                    )
                             VALUES (p_instcode, i.mci_pan_code,
                                     migr_acct_data (t), v_errmsg
                                    );

                        v_errmsg := 'OK';
                     --RAISE exp_reject_record_main;
                     WHEN OTHERS
                     THEN
                        v_errmsg :=
                              'Error While Getting Account Details For Account Number'
                           || migr_acct_data (t)
                           || ' as -'
                           || SUBSTR (SQLERRM, 1, 100);
                        v_migr_err_code := 'MIG-1_';
                        v_migr_err_desc := 'OTHER_THAN_PRDEFINE_EXCP';
                        RAISE exp_reject_record_main;
                  END;
               END LOOP;

               BEGIN
                  IF v_cnt > 1
                  THEN
                     v_errmsg := 'Card Can Have Only one Primary account';
                     v_migr_err_code := 'MIG-0_006';
                     v_migr_err_desc := 'MULT_PRIM_ACCT';
                     RAISE exp_reject_record_main;
                  END IF;

                  --                  IF v_cnt > 1
                  --                  THEN
                  --                     v_errmsg := 'Card Can Have Only one Primary account';
                  --                     v_migr_err_code := 'MIG-0_006';
                  --                     v_migr_err_desc := 'MULT_PRIM_ACCT';
                  --                     RAISE exp_reject_record_main;
                  --                  END IF;
                  IF i.mci_crd_stat <> 9 AND v_cnt = 0
                  THEN
                     v_errmsg :=
                        'An Active Card Should Have atleast one primary account present in account data file';
                     v_migr_err_code := 'MIG-0_007';
                     v_migr_err_desc := 'NO_PRIM_ACCT';
                     RAISE exp_reject_record_main;
                  END IF;

                  IF v_cnt1 > 1
                  THEN
                     v_errmsg := 'Customer can have only one savings account';
                     v_migr_err_code := 'MIG-0_015';
                     v_migr_err_desc := 'MULT_SAVNG_ACCT';
                     RAISE exp_reject_record_main;
                  END IF;
               END;

               --En select acct stat
               IF v_catg_code = 'P'
               THEN
                  v_acct_numb := migr_prim_acct_detl_data (1).pri_acctno;
               ELSIF v_catg_code = 'D'
               THEN
                  v_acct_numb := migr_prim_acct_detl_data (1).pri_acctno;
               END IF;

               --En find Branch

               --Sn find customer
               BEGIN
                  -- SN : Commented on 20-JUN-2013 since cust id field removed from cust file
                  SELECT cap_cust_code
                    INTO v_cust_code
                    FROM cms_appl_pan
                   WHERE cap_inst_code = p_instcode
                     AND cap_acct_no = v_acct_numb
                     AND ROWNUM < 2;

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
                        v_errmsg :=
                           'Permanent Address details not found for the existing customer :';
                        --  errmsg added by ganesh
                        --|| i.mci_cust_id;
                        v_migr_err_code := 'MIG-1_040';
                        v_migr_err_desc := 'CUST_PERM_ADDR_NOT_FOUND';
                        RAISE exp_reject_record_main;
                     WHEN TOO_MANY_ROWS
                     THEN
                        v_errmsg :=
                           'More then one permanent Address details found for the existing customer :';
                        --  errmsg added by ganesh
                        --|| i.mci_cust_id;
                        v_migr_err_code := 'MIG-1_041';
                        v_migr_err_desc := 'CUST_MULT_PERM_ADDR_FOUND';
                        RAISE exp_reject_record_main;
                     WHEN OTHERS
                     THEN
                        v_errmsg :=
                              'Error while getting permanent Address details for the existing customer :'
                           --  errmsg added by ganesh
                           --|| i.mci_cust_id
                           || ' as -'
                           || SUBSTR (SQLERRM, 1, 200);
                        v_migr_err_code := 'MIG-1_';
                        v_migr_err_desc := 'OTHER_THAN_PRDEFINE_EXCP';
                        RAISE exp_reject_record_main;
                  END;
               EXCEPTION
                  WHEN NO_DATA_FOUND
                  THEN
                     --Sn assign records to customer gen variable
                     BEGIN
                        SELECT type_cust_rec_array (i.mci_customer_param1,
                                                    i.mci_customer_param2,
                                                    i.mci_customer_param3,
                                                    i.mci_customer_param4,
                                                    i.mci_customer_param5,
                                                    i.mci_customer_param6,
                                                    i.mci_customer_param7,
                                                    i.mci_customer_param8,
                                                    i.mci_customer_param9,
                                                    i.mci_customer_param10
                                                   )
                          INTO v_cust_data
                          FROM DUAL;
                     EXCEPTION
                        WHEN OTHERS
                        THEN
                           v_errmsg :=
                                 'Error while cutomer gen data '
                              || SUBSTR (SQLERRM, 1, 200);
                           v_migr_err_code := 'MIG-1_';
                           v_migr_err_desc := 'OTHER_THAN_PRDEFINE_EXCP';
                           RAISE exp_reject_record_main;
                     END;

                     --En assign records to customer gen variable

                     --Sn create customer
                     BEGIN
                        -- COMMENTED BY GANESH lOGIC CHANGED  FOR MIGRATION
                        /*     SELECT DECODE (i.mci_title,
                                          'Mr.', 'M',
                                          'Mrs.', 'F',
                                          'Miss.', 'F',
                                          'Dr.', 'D'
                                         )
                             INTO v_gender
                             FROM DUAL;*/
                        BEGIN
                           SELECT DECODE (i.mci_title,
                                          '0', 'Mr.',
                                          '1', 'Ms.',
                                          '2', 'Mrs.',
                                          '3', 'Dr.',
                                          '4', ' ' --NA added by Pankaj S. on 20_Sep_2013 for NULL mark NA -- incomm will send as 4 for NA 23-sep-2013 -- changed to null if value is 4 on 14-oct-2013
                                         )
                             INTO v_title
                             FROM DUAL;
                        EXCEPTION
                           WHEN OTHERS
                           THEN
                              v_errmsg :=
                                    'Error While Setting Salutation for customer  '
                                 --|| i.mci_cust_id
                                 || ' as - '
                                 || SUBSTR (SQLERRM, 1, 100);
                              v_migr_err_code := 'MIG-1_';
                              v_migr_err_desc := 'OTHER_THAN_PRDEFINE_EXCP';
                              RAISE exp_reject_record_main;
                        END;

                        BEGIN
                           SELECT DECODE (i.mci_title,
                                          '0', 'M',
                                          '1', 'F',
                                          '2', 'F',
                                          '3', 'D',
                                          '4', '' --NA added by Pankaj S. on 20_Sep_2013 for NULL mark NA-- change to pass as null for 4 on 14-oct-2013
                                         )
                             INTO v_gender
                             FROM DUAL;
                        EXCEPTION
                           WHEN OTHERS
                           THEN
                              v_errmsg :=
                                    'Error While Setting Gender for customer  '
                                 --|| i.mci_cust_id
                                 || ' as - '
                                 || SUBSTR (SQLERRM, 1, 100);
                              v_migr_err_code := 'MIG-1_';
                              v_migr_err_desc := 'OTHER_THAN_PRDEFINE_EXCP';
                              RAISE exp_reject_record_main;
                        END;

                        migr_create_cust_pkg (p_instcode,
                                              1,
                                              0,
                                              'Y',
                                              v_title,
                                              --i.mci_title, -- CHANGED BY GANESH
                                              i.mci_seg12_name_line1,
                                              NULL,
                                              --BEGIN changes by T.Narayanan for  Last Name  not stored in CMS_CUST_MAST
                                              i.mci_seg12_name_line2,
                                              --END changes by T.Narayanan for  Last Name  not stored in CMS_CUST_MAST
                                              TO_DATE (i.mci_birth_date,
                                                       'YYYYMMDD:HH24:MI:SS'
                                                      ),
                                              v_gender,
                                              i.mci_marital_stat,
                                              --NULL,  -- CHANGED BY GANESH
                                              NULL,
                                              i.mci_seg12_emailid,
                                              --NULL, -- CHANGED BY GANESH
                                              NULL,
                                              NULL,
                                              NULL,
                                              p_lupduser,
                                              i.mci_ssn,
                                              i.mci_mothers_maiden_name,
                                              i.mci_hobbies,
                                              i.mci_emp_id,
                                              v_catg_code,
                                              --i.mci_cust_id,     -- Commented on 20-JUN-2013
                                              v_cust_data,
                                              i.mci_customer_username,
                                              -- CHANGED BY GANESH  -- FIELD ADDED FOR MIGR
                                              i.mci_customer_password,
                                              -- CHANGED BY GANESH  -- FIELD ADDED FOR MIGR
                                              i.mci_question_one,
                                              i.mci_answer_one,
                                              i.mci_question_two,
                                              i.mci_answer_two,
                                              i.mci_question_three,
                                              i.mci_answer_three,
                                              i.mci_kyc_flag,
                                              --added by Pankaj S. for KYC flag
                                              i.mci_id_type,
                                              -- Added on 25-JUN-2013
                                              i.mci_id_issuer,
                                              -- Added on 25-JUN-2013
                                              --i.mci_id_issuance_date,
                                              to_date(i.mci_id_issuance_date,'YYYYMMDD HH24:MI:SS'),
                                              -- Added on 25-JUN-2013
                                              --i.mci_id_expiry_date,
                                              to_date(i.mci_id_expiry_date,'YYYYMMDD HH24:MI:SS'),
                                              -- Added on 25-JUN-2013
                                              --Sn 2.1 onward changes
                                               i.mci_starter_crd_flag,
                                               i.mci_prod_code,
                                               --En 2.1 onward changes 
                                              v_cust_code,
                                              v_migr_err_code,
                                              v_migr_err_desc,
                                              v_errmsg
                                             );

                        IF v_errmsg <> 'OK'
                        THEN
                           v_errmsg :=
                                 'Error from customer creation process ' --Error message modified by Pankaj S. on 25-Sep-2013
                              --|| i.mci_cust_id
                              || ' as :'
                              || v_errmsg;
                           RAISE exp_reject_record_main;
                        END IF;
                     EXCEPTION
                        WHEN exp_reject_record_main
                        THEN
                           RAISE exp_reject_record_main;
                        WHEN OTHERS
                        THEN
                           v_errmsg :=
                                 'Error while customer creation ' --Error message modified by Pankaj S. on 25-Sep-2013
                              --|| i.mci_cust_id
                              || ' as :'
                              || SUBSTR (SQLERRM, 1, 200);
                           v_migr_err_code := 'MIG-1_';
                           v_migr_err_desc := 'OTHER_THAN_PRDEFINE_EXCP';
                           RAISE exp_reject_record_main;
                     END;

                     BEGIN
                        SELECT i.mci_seg12_addr_line1,
                               i.mci_seg12_addr_line2,
                               i.mci_seg12_postal_code,
                               i.mci_seg12_homephone_no,
                               i.mci_seg12_mobileno,
                               i.mci_seg12_officephone_no,
                               i.mci_seg12_emailid, i.mci_seg12_city,
                               i.mci_seg12_state, i.mci_seg12_country_code,
                               type_addr_rec_array (i.mci_seg12_addr_param1,
                                                    i.mci_seg12_addr_param2,
                                                    i.mci_seg12_addr_param3,
                                                    i.mci_seg12_addr_param4,
                                                    i.mci_seg12_addr_param5,
                                                    i.mci_seg12_addr_param6,
                                                    i.mci_seg12_addr_param7,
                                                    i.mci_seg12_addr_param8,
                                                    i.mci_seg12_addr_param9,
                                                    i.mci_seg12_addr_param10
                                                   ),
                               i.mci_seg13_addr_line1,
                               i.mci_seg13_addr_line2,
                               i.mci_seg13_postal_code,
                               i.mci_seg13_homephone_no,
                               i.mci_seg13_mobileno,
                               i.mci_seg13_officephone_no,
                               i.mci_seg13_emailid, i.mci_seg13_city,
                               i.mci_seg13_state, i.mci_seg13_country_code,
                               type_addr_rec_array (i.mci_seg13_addr_param1,
                                                    i.mci_seg13_addr_param2,
                                                    i.mci_seg13_addr_param3,
                                                    i.mci_seg13_addr_param4,
                                                    i.mci_seg13_addr_param5,
                                                    i.mci_seg13_addr_param6,
                                                    i.mci_seg13_addr_param7,
                                                    i.mci_seg13_addr_param8,
                                                    i.mci_seg13_addr_param9,
                                                    i.mci_seg13_addr_param10
                                                   )
                          INTO v_comm_addr_lin1,
                               v_comm_addr_lin2,
                               v_comm_postal_code,
                               v_comm_homephone_no,
                               v_comm_mobileno,
                               v_comm_officeno,
                               v_comm_emailid, v_comm_city,
                               v_comm_state, v_comm_cntrycode,
                               v_addr_data1,
                               v_other_addr_lin1,
                               v_other_addr_lin2,
                               v_other_postal_code,
                               v_other_homephone_no,
                               v_other_mobileno,
                               v_other_officeno,
                               v_other_emailid, v_other_city,
                               v_other_state, v_other_cntrycode,
                               v_addr_data2
                          FROM DUAL;
                     EXCEPTION
                        WHEN OTHERS
                        THEN
                           v_errmsg :=
                                 'ERROR WHILE SETTING ADDRESS VARIABLES :'
                              || SUBSTR (SQLERRM, 1, 200);
                           RAISE exp_reject_record_main;
                           v_migr_err_code := 'MIG-1_';
                           v_migr_err_desc := 'OTHER_THAN_PRDEFINE_EXCP';
                     END;

                     BEGIN
                        BEGIN
                           SELECT gcm_cntry_code
                             INTO v_gcm_cntry_code
                             FROM gen_cntry_mast
                            WHERE gcm_cntry_name = v_comm_cntrycode
                              AND gcm_inst_code = p_instcode;
                        EXCEPTION
                           WHEN NO_DATA_FOUND
                           THEN
                              v_errmsg :=
                              --Sn Error message modified by Pankaj S. on 25-Sep-2013
                                   'Country Code '|| v_comm_cntrycode||' Not Found in Country Master';-- for cusomer id '
                                 --|| i.mci_cust_id
                                -- || ' and country code '
                                -- || v_comm_cntrycode;
                              --En Error message modified by Pankaj S. on 25-Sep-2013
                              v_migr_err_code := 'MIG-1_046';
                              v_migr_err_desc := 'INVALID_PERM_CNTRY_CODE';
                              RAISE exp_reject_record_main;
                           WHEN OTHERS
                           THEN
                              v_errmsg :=
                                    'Error While Validating country Code '-- for customer  ' --Error message modified by Pankaj S. on 25-Sep-2013
                                 --|| i.mci_cust_id
                                 --|| ' and country code '
                                 || v_comm_cntrycode
                                 || ' as :'
                                 || SUBSTR (SQLERRM, 1, 100);
                              v_migr_err_code := 'MIG-1_';
                              v_migr_err_desc := 'OTHER_THAN_PRDEFINE_EXCP';
                              RAISE exp_reject_record_main;
                        END;

                        v_comm_type := 'R';
                        migr_create_addr_pkg (p_instcode,
                                              v_cust_code,
                                              v_comm_addr_lin1,
                                              v_comm_addr_lin2,
                                              NULL,
                                              v_comm_postal_code,
                                              v_comm_homephone_no,
                                              v_comm_mobileno,
                                              v_comm_officeno,
                                              v_comm_emailid,
                                              v_gcm_cntry_code,
                                              v_comm_city,
                                              v_comm_state,
                                              NULL,
                                              'P',
                                              v_comm_type,
                                              p_lupduser,
                                              v_addr_data1,
                                              v_comm_addrcode,
                                              v_migr_err_code,
                                              v_migr_err_desc,
                                              v_errmsg
                                             );

                        IF v_errmsg <> 'OK'
                        THEN
                           v_errmsg :=
                                 'Error from Permanent address creation process ' --create communication address for cusomer id ' --Error message modified by Pankaj S. on 25-Sep-2013
                              --|| i.mci_cust_id
                              || ' as :'
                              || v_errmsg;
                           RAISE exp_reject_record_main;
                        END IF;
                     EXCEPTION
                        WHEN exp_reject_record_main
                        THEN
                           RAISE;
                        WHEN OTHERS
                        THEN
                           v_errmsg :=
                                 'Error while Permanent address creation '--create communication address for cusomer id ' --Error message modified by Pankaj S. on 25-Sep-2013
                              --|| i.mci_cust_id
                              || ' as :'
                              || SUBSTR (SQLERRM, 1, 200);
                           v_migr_err_code := 'MIG-1_';
                           v_migr_err_desc := 'OTHER_THAN_PRDEFINE_EXCP';
                           RAISE exp_reject_record_main;
                     END;

                     --END IF;

                     --En create communication address
                     --Sn create other address
                     /*IF v_other_addr_lin1 IS NOT NULL
                     THEN
                        IF v_comm_addr_lin1 = i.mci_seg12_addr_line1
                        THEN
                           v_comm_type := 'R';
                        ELSIF v_comm_addr_lin1 = i.mci_seg13_addr_line1
                        THEN
                           v_comm_type := 'O';
                        END IF;*/
                     v_comm_type := 'O';

                     BEGIN
                        IF     v_other_addr_lin1 IS NOT NULL
                           AND v_other_city IS NOT NULL
                           AND v_other_cntrycode IS NOT NULL
                        THEN
                           BEGIN
                              SELECT gcm_cntry_code
                                INTO v_gcm_othercntry_code
                                FROM gen_cntry_mast
                               WHERE gcm_cntry_name = v_other_cntrycode
                                 AND gcm_inst_code = p_instcode;
                           EXCEPTION
                              WHEN NO_DATA_FOUND
                              THEN
                                 v_errmsg :=
                                 --Sn Error message modified by Pankaj S. on 25-Sep-2013
                                       'Country Code '|| v_other_cntrycode||' Not Found in Country Master ';-- for cusomer id '
                                    --|| i.mci_cust_id
                                   -- || ' and country code '
                                    --|| v_other_cntrycode;
                                 --En Error message modified by Pankaj S. on 25-Sep-2013
                                 v_migr_err_code := 'MIG-1_051';
                                 v_migr_err_desc := 'INVALID_MAIL_CNTRY_CODE';
                                 RAISE exp_reject_record_main;
                              WHEN OTHERS
                              THEN
                                 v_errmsg :=
                                       'Error While Validating country Code '--for cusomer id '  --Error message modified by Pankaj S. on 25-Sep-2013
                                    --|| i.mci_cust_id
                                    --|| ' and country code '
                                    || v_other_cntrycode
                                    || ' as :'
                                    || SUBSTR (SQLERRM, 1, 100);
                                 v_migr_err_code := 'MIG-1_';
                                 v_migr_err_desc := 'OTHER_THAN_PRDEFINE_EXCP';
                                 RAISE exp_reject_record_main;
                           END;

                           migr_create_addr_pkg (p_instcode,
                                                 v_cust_code,
                                                 v_other_addr_lin1,
                                                 v_other_addr_lin2,
                                                 NULL,
                                                 v_other_postal_code,
                                                 v_other_homephone_no,
                                                 v_other_mobileno,
                                                 v_other_officeno,
                                                 v_other_emailid,
                                                 v_gcm_othercntry_code,
                                                 v_other_city,
                                                 v_other_state,
                                                 NULL,
                                                 'O',
                                                 v_comm_type,
                                                 p_lupduser,
                                                 v_addr_data2,
                                                 v_other_addrcode,
                                                 v_migr_err_code,
                                                 v_migr_err_desc,
                                                 v_errmsg
                                                );

                           IF v_errmsg <> 'OK'
                           THEN
                              v_errmsg :=
                                    'Error from communication address creation process ' --Error message modified by Pankaj S. on 25-Sep-2013
                                 --|| i.mci_cust_id
                                 || ' as :'
                                 || v_errmsg;
                              RAISE exp_reject_record_main;
                           END IF;
                        END IF;
                     EXCEPTION
                        WHEN exp_reject_record_main
                        THEN
                           RAISE;
                        WHEN OTHERS
                        THEN
                           v_errmsg :=
                                 'Error while communication address creation '--create communication address for cusomer id ' --Error message modified by Pankaj S. on 25-Sep-2013
                              --|| i.mci_cust_id
                              || ' as :'
                              || SUBSTR (SQLERRM, 1, 200);
                           v_migr_err_code := 'MIG-1_';
                           v_migr_err_desc := 'OTHER_THAN_PRDEFINE_EXCP';
                           RAISE exp_reject_record_main;
                     END;
                  --En create other address
                  WHEN exp_reject_record_main
                  THEN
                     RAISE exp_reject_record_main;
                  WHEN OTHERS
                  THEN
                     v_errmsg :=
                           'Error while selecting customer from master '-- for cusomer id ' --Error message modified by Pankaj S. on 25-Sep-2013
                        --|| i.mci_cust_id
                        || ' as :'
                        || SUBSTR (SQLERRM, 1, 200);
                     v_migr_err_code := 'MIG-1_';
                     v_migr_err_desc := 'OTHER_THAN_PRDEFINE_EXCP';
                     RAISE exp_reject_record_main;
               END;

               SELECT COUNT (1)
                 INTO v_cnt
                 FROM cms_acct_mast
                WHERE cam_inst_code = p_instcode
                  AND cam_acct_no = migr_prim_acct_detl_data (1).pri_acctno;

               IF v_cnt = 0
               THEN
                  BEGIN
                     migr_create_acct_pcms_pkg
                        (p_instcode,
                         migr_prim_acct_detl_data (1).pri_acctno,
                         0,
                         migr_prim_acct_detl_data (1).pri_branid,
                         v_comm_addrcode,
                         migr_prim_acct_detl_data (1).pri_accttype,
                         migr_prim_acct_detl_data (1).pri_acctstat,
                         TO_DATE (migr_prim_acct_detl_data (1).pri_acctgen,
                                  'YYYYMMDD:HH24:MI:SS'
                                 ),
                         migr_prim_acct_detl_data (1).pri_avaibal,
                         migr_prim_acct_detl_data (1).pri_ledgbal,
                         TO_DATE
                            (migr_prim_acct_detl_data (1).pri_svngacct_reopndate,
                             'YYYYMMDD:HH24:MI:SS'
                            ),
                         migr_prim_acct_detl_data (1).pri_svngacct_intrstamt,
                         i.mci_prod_amt,   --2.1 onward changes
                         p_lupduser,
                         v_dup_flag,
                         v_acct_id,
                         v_migr_err_code,
                         v_migr_err_desc,
                         v_errmsg
                        );

                     IF v_errmsg <> 'OK'
                     THEN
                        v_errmsg :=
                              'Error from create acct '
                           || v_errmsg
                           || ' For account Number :'
                           || migr_prim_acct_detl_data (1).pri_acctno;
                        RAISE exp_reject_record_main;
                     END IF;
                  EXCEPTION
                     WHEN exp_reject_record_main
                     THEN
                        RAISE;
                     WHEN OTHERS
                     THEN
                        v_errmsg :=
                              'Error while creating acct ' --Error message modified by Pankaj S. on 25-Sep-2013
                           || SUBSTR (SQLERRM, 1, 200);
                        v_migr_err_code := 'MIG-1_';
                        v_migr_err_desc := 'OTHER_THAN_PRDEFINE_EXCP';
                        RAISE exp_reject_record_main;
                  END;
               ELSE
                  BEGIN
                     SELECT cam_acct_id
                       INTO v_exist_acctid
                       FROM cms_acct_mast
                      WHERE cam_inst_code = p_instcode
                        AND cam_acct_no =
                                       migr_prim_acct_detl_data (1).pri_acctno;

                     v_acct_id := v_exist_acctid;
                  EXCEPTION
                     WHEN OTHERS
                     THEN
                        v_errmsg :=
                              'Error while fetching acct id for existing account '
                           || migr_prim_acct_detl_data (1).pri_acctno ||' As '
                           || SUBSTR (SQLERRM, 1, 200);
                        v_migr_err_code := 'MIG-1_';
                        v_migr_err_desc := 'OTHER_THAN_PRDEFINE_EXCP';
                        RAISE exp_reject_record_main;
                  END;

                  BEGIN
                     SELECT cca_cust_code
                       INTO v_exist_cust
                       FROM cms_cust_acct
                      WHERE cca_inst_code = p_instcode
                        AND cca_acct_id = v_exist_acctid;
                  EXCEPTION
                     WHEN OTHERS
                     THEN
                        v_errmsg :=
                              'Error while fetching CUSTCODE for existing account '
                           || migr_prim_acct_detl_data (1).pri_acctno ||' As '
                           || SUBSTR (SQLERRM, 1, 200);
                        v_migr_err_code := 'MIG-1_';
                        v_migr_err_desc := 'OTHER_THAN_PRDEFINE_EXCP';
                        RAISE exp_reject_record_main;
                  END;

                  IF v_exist_cust <> v_cust_code
                  THEN
                     v_errmsg :=
                     --Sn Error message modified by Pankaj S. on 25-Sep-2013
                     'Account number '|| migr_prim_acct_detl_data (1).pri_acctno||' already exist for other customer '||v_cust_code;
                           --'Duplicate account for other customer --'
                        --|| v_cust_code
                        --|| ' account Number :'
                        --|| migr_prim_acct_detl_data (1).pri_acctno;
                     --En Error message modified by Pankaj S. on 25-Sep-2013
                     RAISE exp_reject_record_main;
                  END IF;
               END IF;

               --En create acct

               --Sn create a entry in cms_cust_acct
               BEGIN
                  UPDATE cms_acct_mast
                     SET cam_hold_count = cam_hold_count + 1,
                         cam_lupd_user = p_lupduser
                   WHERE cam_inst_code = p_instcode
                         AND cam_acct_id = v_acct_id;

                  IF SQL%ROWCOUNT = 0
                  THEN
                     v_errmsg :=
                           'Error while updating acct hold count '
                        || SUBSTR (SQLERRM, 1, 200);
                     v_migr_err_code := 'MIG-1_053';
                     v_migr_err_desc := 'ACT_UPDT_ERR';
                     RAISE exp_reject_record_main;
                  END IF;
               EXCEPTION
                  WHEN OTHERS
                  THEN
                     v_errmsg :=
                           'ERROR WHILE UPDATING ACCT MASTER AS - '
                        || SUBSTR (SQLERRM, 1, 200);
                     RAISE exp_reject_record_main;
                     RAISE exp_reject_record_main;
               END;

               IF v_cnt = 0
               THEN
                  BEGIN
                     migr_create_holder_pkg (p_instcode,
                                             v_cust_code,
                                             v_acct_id,
                                             NULL,
                                             p_lupduser,
                                             v_holdposn,
                                             v_migr_err_code,
                                             v_migr_err_desc,
                                             v_errmsg
                                            );

                     IF v_errmsg <> 'OK'
                     THEN
                        v_errmsg :=
                             'Error while attaching customer to account ' || v_errmsg; --Error message modified by Pankaj S. on 25-Sep-2013
                        RAISE exp_reject_record_main;
                     END IF;
                  EXCEPTION
                     WHEN exp_reject_record_main
                     THEN
                        RAISE exp_reject_record_main;
                     WHEN OTHERS
                     THEN
                        v_errmsg :=
                              'Error While Getting Account Data : '
                           || SUBSTR (SQLERRM, 1, 200)
                           || ' for account number '
                           || migr_prim_acct_detl_data (1).pri_acctno;
                        v_migr_err_code := 'MIG-1_';
                        v_migr_err_desc := 'OTHER_THAN_PRDEFINE_EXCP';
                        RAISE exp_reject_record_main;
                  END;
               END IF;

               -- Sn Appl
               BEGIN
                  migr_create_appl_pcms_pkg
                          (p_instcode,
                           1,
                           1,
                           NULL, --x.mdl_appl_no,            --- need to check
                           --SYSDATE,
                           --SYSDATE,
                           to_date(i.mci_reg_date,'yyyymmdd hh24:mi:ss'),     -- Added on 09-oct-2013
                           to_date(i.mci_reg_date,'yyyymmdd hh24:mi:ss'),     -- Added on 09-oct-2013
                           v_cust_code,
                           i.mci_fiid,
                           v_prod_code,
                           v_prod_cattype,
                           v_custcatg,
                           TO_DATE (i.mci_pan_active_date,
                                    'YYYYMMDD:HH24:MI:SS'
                                   ),
                           TO_DATE (i.mci_pan_expiry_date,
                                    'YYYYMMDD:HH24:MI:SS'
                                   ),
                           i.mci_seg12_name_line1,
--SUBSTR (i.mci_seg12_name_line1, 1, 30),  --- COMMENETED BY GANESH AS INFORMATION COMING IN MIGRATION FILE IS TO BE PASSED AS IT IS.
                           0,
                           'N',
                           NULL,
                           i.mci_seg31_acct_cnt,
                           'P',
                           0,
                           v_comm_addrcode,
                           NULL,
                           NULL,
                           NULL, --x.mdl_payref_no,          --- need to check
                           p_lupduser,
                           p_lupduser,
                           TO_NUMBER (i.mci_prod_amt),
                           i.mci_starter_crd_flag,
                           v_appl_code,
                           v_migr_err_code,
                           v_migr_err_desc,
                           v_errmsg
                          );

                  IF v_errmsg <> 'OK'
                  THEN
                     v_errmsg := 'Error from application creation process ' || v_errmsg; --Error message modified by Pankaj S. on 25-Sep-2013
                     RAISE exp_reject_record_main;
                  END IF;
               EXCEPTION
                  WHEN exp_reject_record_main
                  THEN
                     RAISE;
                  WHEN OTHERS
                  THEN
                     v_errmsg :=
                        'Error while creating application '
                        || SUBSTR (SQLERRM, 1, 200);
                     v_migr_err_code := 'MIG-1_';
                     v_migr_err_desc := 'OTHER_THAN_PRDEFINE_EXCP';
                     RAISE exp_reject_record_main;
               END;

               -- Sn create entry in appl_det
               BEGIN
                  migr_create_appldet_pkg (p_instcode,
                                           v_appl_code,
                                           v_acct_id,
                                           1,
                                           p_lupduser,
                                           v_migr_err_code,
                                           v_migr_err_desc,
                                           v_errmsg
                                          );

                  IF v_errmsg <> 'OK'
                  THEN
                     v_errmsg := 'Error from application dtl creation process ' || v_errmsg; --Error message modified by Pankaj S. on 25-Sep-2013
                     RAISE exp_reject_record_main;
                  END IF;
               EXCEPTION
                  WHEN exp_reject_record_main
                  THEN
                     RAISE;
                  WHEN OTHERS
                  THEN
                     v_errmsg :=
                           'Error while create appl det '
                        || SUBSTR (SQLERRM, 1, 200);
                     v_migr_err_code := 'MIG-1_';
                     v_migr_err_desc := 'OTHER_THAN_PRDEFINE_EXCP';
                     RAISE exp_reject_record_main;
               END;

               FOR t IN 1 .. migr_sec_acct_detl_data.COUNT ()
               LOOP
                  BEGIN
                     v_acct_id := NULL;
                     v_dup_flag := NULL;

                     BEGIN
                        migr_create_acct_pcms_pkg
                           (p_instcode,
                            migr_sec_acct_detl_data (t).sec_acctno,
                            0,
                            migr_sec_acct_detl_data (t).sec_branid,
                            v_comm_addrcode,
                            migr_sec_acct_detl_data (t).sec_accttype,
                            migr_sec_acct_detl_data (t).sec_acctstat,
                            TO_DATE (migr_sec_acct_detl_data (t).sec_acctgen,
                                     'YYYYMMDD:HH24:MI:SS'
                                    ),
                            migr_sec_acct_detl_data (t).sec_avaibal,
                            migr_sec_acct_detl_data (t).sec_ledgbal,
                            TO_DATE
                               (migr_sec_acct_detl_data (t).sec_svngacct_reopndate,
                                'YYYYMMDD:HH24:MI:SS'
                               ),
                            migr_sec_acct_detl_data (t).sec_svngacct_intrstamt,
                            NULL,  --2.1 onward changes
                            p_lupduser,
                            v_dup_flag,
                            v_acct_id,
                            v_migr_err_code,
                            v_migr_err_code,
                            v_errmsg
                           );

                        IF v_errmsg <> 'OK'
                        THEN
                           v_errmsg :=
                                 'Error from create acct'
                              || v_errmsg
                              || ' for account number -'
                              || migr_sec_acct_detl_data (t).sec_acctno;
                           RAISE exp_reject_record_main;
                        END IF;
                     EXCEPTION
                        WHEN exp_reject_record_main
                        THEN
                           RAISE exp_reject_record_main;
                        WHEN OTHERS
                        THEN
                           v_errmsg :=
                                 'Error while acct creation process ' --Error message modified by Pankaj S. on 25-Sep-2013
                              || SUBSTR (SQLERRM, 1, 200)
                              || ' for account number -'
                              || migr_sec_acct_detl_data (t).sec_acctno;
                           v_migr_err_code := 'MIG-1_';
                           v_migr_err_desc := 'OTHER_THAN_PRDEFINE_EXCP';
                           RAISE exp_reject_record_main;
                     END;

                     BEGIN
                        UPDATE cms_acct_mast
                           SET cam_hold_count = cam_hold_count + 1,
                               cam_lupd_user = p_lupduser
                         WHERE cam_inst_code = p_instcode
                           AND cam_acct_id = v_acct_id;

                        IF SQL%ROWCOUNT = 0
                        THEN
                           v_errmsg :=
                                 'Error while update acct hold count '
                              || SUBSTR (SQLERRM, 1, 200)
                              || ' for account number -'
                              || migr_sec_acct_detl_data (t).sec_acctno;
                           v_migr_err_code := 'MIG-1_';
                           v_migr_err_desc := 'OTHER_THAN_PRDEFINE_EXCP';
                           RAISE exp_reject_record_main;
                        END IF;
                     END;

                     BEGIN
                        migr_create_holder_pkg (p_instcode,
                                                v_cust_code,
                                                v_acct_id,
                                                NULL,
                                                p_lupduser,
                                                v_holdposn,
                                                v_migr_err_code,
                                                v_migr_err_desc,
                                                v_errmsg
                                               );

                        IF v_errmsg <> 'OK'
                        THEN
                           v_errmsg :=
                                 'Error while attaching customer to account ' --Error message modified by Pankaj S. on 25-Sep-2013
                              || v_errmsg
                              || ' for account number -'
                              || migr_sec_acct_detl_data (t).sec_acctno;
                           RAISE exp_reject_record_main;
                        END IF;
                     EXCEPTION
                        WHEN exp_reject_record_main
                        THEN
                           RAISE exp_reject_record_main;
                        WHEN OTHERS
                        THEN
                           v_errmsg :=
                                 'Error While Getting Account Data : '
                              || SUBSTR (SQLERRM, 1, 200)
                              || ' for account number '
                              || migr_prim_acct_detl_data (1).pri_acctno;
                           v_migr_err_code := 'MIG-1_';
                           v_migr_err_desc := 'OTHER_THAN_PRDEFINE_EXCP';
                           RAISE exp_reject_record_main;
                     END;

                     BEGIN
                        migr_create_appldet_pkg (p_instcode,
                                                 v_appl_code,
                                                 v_acct_id,
                                                 (t + 1),
                                                 p_lupduser,
                                                 v_migr_err_code,
                                                 v_migr_err_desc,
                                                 v_errmsg
                                                );

                        IF v_errmsg <> 'OK'
                        THEN
                           v_errmsg :=
                                 'Error from application dtl creation process ' --Error message modified by Pankaj S. on 25-Sep-2013
                              || v_errmsg
                              || ' for account number -'
                              || migr_sec_acct_detl_data (t).sec_acctno;
                           RAISE exp_reject_record_main;
                        END IF;
                     EXCEPTION
                        WHEN exp_reject_record_main
                        THEN
                           RAISE exp_reject_record_main;
                        WHEN OTHERS
                        THEN
                           v_errmsg :=
                                 'Error while create application dtl '
                              || SUBSTR (SQLERRM, 1, 200)
                              || ' for account number -'
                              || migr_sec_acct_detl_data (t).sec_acctno;
                           v_migr_err_code := 'MIG-1_';
                           v_migr_err_desc := 'OTHER_THAN_PRDEFINE_EXCP';
                           RAISE exp_reject_record_main;
                     END;
                  EXCEPTION
                     WHEN OTHERS
                     THEN
                        v_errmsg :=
                              'Error While Getting details for account number '
                           || migr_sec_acct_detl_data (t).sec_acctno
                           || ' as - '
                           || SUBSTR (SQLERRM, 1, 200);
                        v_migr_err_code := 'MIG-1_';
                        v_migr_err_desc := 'OTHER_THAN_PRDEFINE_EXCP';
                  END;
               END LOOP;

               BEGIN
                  migr_gen_pan_prepaid_cms_pkg
                                      (p_instcode,
                                       v_appl_code,
                                       i.mci_pan_code,
                                       i.mci_crd_stat,
                                       TO_DATE (i.mci_pan_gen_date,
                                                'YYYYMMDD:HH24:MI:SS'
                                               ),
                                       i.mci_atm_online_limit,
                                       i.mci_atm_offline_limit,
                                       i.mci_pos_online_limit,
                                       i.mci_pos_offline_limit,
                                       i.mci_online_aggr_limit,
                                       i.mci_offline_aggr_limit,
                                       i.mci_mmpos_online_limit,
                                       i.mci_mmpos_offline_limit,
                                       i.mci_pin_offset,
                                       TO_DATE (i.mci_pin_gen_date,
                                                'YYYYMMDD:HH24:MI:SS'
                                               ),
                                       i.mci_pin_flag,
                                       TO_DATE (i.mci_emboss_gen_date,
                                                'YYYYMMDD:HH24:MI:SS'
                                               ),
                                       i.mci_emboss_flag,
                                       TO_DATE (i.mci_next_bill_date,
                                                'YYYYMMDD:HH24:MI:SS'
                                               ),
                                       TO_DATE (i.mci_next_month_bill_date,
                                                'YYYYMMDD:HH24:MI:SS'
                                               ),
                                       i.mci_ccf_file_name,
                                       i.mci_serial_number,
                                       i.mci_proxy_numb,
                                       i.mci_starter_crd_flag,
                                       i.mci_init_load_flag,
                                       i.mci_sms_alert_flag,
                                       i.mci_email_alert_flag,
                                       i.mci_pin_offset,
                                       p_lupduser,
                                       i.mci_merc_id,  -- Added on 20-JUN-2013
                                       i.mci_store_id, -- Added on 20-JUN-2013
                                       v_ordr_rfrno,   -- Added on 20-JUN-2013
                                       v_migr_err_code,
                                       v_migr_err_desc,
                                       v_errmsg
                                      );

                  IF v_errmsg <> 'OK'
                  THEN
                     v_errmsg := 'From PAN genration process : ' || v_errmsg;
                     RAISE exp_reject_record_main;
                  END IF;
               EXCEPTION
                  WHEN exp_reject_record_main
                  THEN
                     RAISE exp_reject_record_main;
                  WHEN OTHERS
                  THEN
                     v_errmsg :=
                           'Error while PAN generation process'
                        || SUBSTR (SQLERRM, 1, 100);
                     v_migr_err_code := 'MIG-1_';
                     v_migr_err_desc := 'OTHER_THAN_PRDEFINE_EXCP';
                     RAISE exp_reject_record_main;
               END;

              /*                                                      --SN: Commented for performance tunning on 14-OCT-2013
               --Sn Added by Pankaj S. to log same in Caf_info_entry
               SELECT NVL (MAX (cci_row_id), 0) + 1
                 INTO v_rowid
                 FROM cms_caf_info_entry;
               */                                                    --EN: Commented for performance tunning on 14-OCT-2013


              Begin


               select seq_dirupld_rowid.nextval into v_rowid from dual;

              exception when others
              then
                 v_errmsg :=
                       'Error while sequecne generation for rowid'
                    || SUBSTR (SQLERRM, 1, 100);
                 v_migr_err_code := 'MIG-2_';
                 v_migr_err_desc := 'OTHER_THAN_PRDEFINE_EXCP';
                 RAISE exp_reject_record_main;

              End;

                 BEGIN
                      SELECT COUNT (*)
                        INTO V_PACKAGEID_CNT
                        FROM CMS_PRODPACKAGE_MAPPING
                       WHERE     CPM_PROD_CODE = i.mci_prod_code
                             AND CPM_CARD_TYPE = i.mci_card_type
                             AND CPM_PRODPACK_IDS = i.MCI_PACKAGE_TYPE
                             AND CPM_INST_CODE = i.mci_inst_code;
                   EXCEPTION
                      WHEN OTHERS
                      THEN
                         v_errmsg :=
                            'Error while Fetching  from prod package mapping'
                            || SUBSTR (SQLERRM, 1, 100);
                         v_migr_err_code := 'MIG-2_';
                         v_migr_err_desc := 'OTHER_THAN_PRDEFINE_EXCP';
                         RAISE exp_reject_record_main;
                   END;

                   V_PACKAGE_type := i.MCI_PACKAGE_TYPE;

                   IF V_PACKAGEID_CNT = 0
                   THEN
                      BEGIN

                         SELECT CPC_PROD_ID, CPC_PACKAGE_ID
                           INTO V_PROD_ID, V_PACKAGE_ID
                           FROM CMS_PROD_CATTYPE
                          WHERE     CPC_PROD_CODE = i.mci_prod_code
                                AND CPC_CARD_TYPE = i.mci_card_type
                                AND CPC_INST_CODE = i.mci_inst_code;
                      EXCEPTION
                         WHEN OTHERS
                         THEN
                            v_errmsg :=
                               'Error while Fetching Prod/ Package ID  from prod cat Type'
                               || SUBSTR (SQLERRM, 1, 100);
                            v_migr_err_code := 'MIG-2_';
                            v_migr_err_desc := 'OTHER_THAN_PRDEFINE_EXCP';
                            RAISE exp_reject_record_main;
                      END;

                      IF V_PROD_ID IS NOT NULL
                      THEN
                         V_PACKAGE_type := V_PROD_ID;
                      ELSE
                         V_PACKAGE_type := V_PACKAGE_ID;
                      END IF;
                   END IF;
				
               BEGIN
                  INSERT INTO cms_caf_info_entry
                              (cci_inst_code,
                               cci_file_name,
                               cci_row_id, cci_appl_code,
                               cci_pan_code,
                               cci_mbr_numb, cci_exp_dat, cci_rec_typ,
                               cci_crd_typ, cci_prod_code,
                               cci_card_type, cci_fiid, cci_cust_id,
                               cci_cust_catg, cci_custappl_param1,
                               cci_custappl_param2, cci_custappl_param3,
                               cci_custappl_param4, cci_custappl_param5,
                               cci_custappl_param6, cci_custappl_param7,
                               cci_custappl_param8, cci_custappl_param9,
                               cci_title,
                               cci_birth_date,
                               cci_mothers_maiden_name, cci_ssn,
                               cci_hobbies, cci_customer_param1,
                               cci_customer_param2, cci_customer_param3,
                               cci_customer_param4, cci_customer_param5,
                               cci_customer_param6, cci_customer_param7,
                               cci_customer_param8, cci_customer_param9,
                               cci_customer_param10, cci_comm_type,
                               cci_seg12_branch_num,
                               cci_seg12_name_line1,
                               cci_seg12_name_line2,
                               cci_seg12_addr_line1,
                               cci_seg12_addr_line2, cci_seg12_city,
                               cci_seg12_state, cci_seg12_postal_code,
                               cci_seg12_country_code,
                               cci_seg12_mobileno,
                               cci_seg12_homephone_no,
                               cci_seg12_officephone_no,
                               cci_seg12_emailid, cci_seg12_addr_param1,
                               cci_seg12_addr_param2,
                               cci_seg12_addr_param3,
                               cci_seg12_addr_param4,
                               cci_seg12_addr_param5,
                               cci_seg12_addr_param6,
                               cci_seg12_addr_param7,
                               cci_seg12_addr_param8,
                               cci_seg12_addr_param9,
                               cci_seg12_addr_param10,
                               cci_seg13_addr_line1,
                               cci_seg13_addr_line2, cci_seg13_city,
                               cci_seg13_state, cci_seg13_postal_code,
                               cci_seg13_country_code,
                               cci_seg13_mobileno,
                               cci_seg13_homephone_no,
                               cci_seg13_officephone_no,
                               cci_seg13_emailid, cci_seg13_addr_param1,
                               cci_seg13_addr_param2,
                               cci_seg13_addr_param3,
                               cci_seg13_addr_param4,
                               cci_seg13_addr_param5,
                               cci_seg13_addr_param6,
                               cci_seg13_addr_param7,
                               cci_seg13_addr_param8,
                               cci_seg13_addr_param9,
                               cci_seg13_addr_param10, cci_seg31_lgth,
                               cci_seg31_acct_cnt, cci_seg31_typ,
                               cci_seg31_num, cci_seg31_num_param1,
                               cci_seg31_num_param2,
                               cci_seg31_num_param3,
                               cci_seg31_num_param4,
                               cci_seg31_num_param5,
                               cci_seg31_num_param6,
                               cci_seg31_num_param7,
                               cci_seg31_num_param8,
                               cci_seg31_num_param9,
                               cci_seg31_num_param10, cci_seg31_stat,
                               cci_prod_amt, cci_fee_amt, cci_tot_amt,
                               cci_payment_mode, cci_instrument_no,
                               cci_emp_id, cci_kyc_reason,
                               cci_kyc_flag,
                               cci_addon_flag, cci_document_verify,
                               cci_upld_stat, cci_approved, cci_comments,
                               cci_process_msg, cci_ins_user, cci_ins_date,
                               cci_lupd_user, cci_lupd_date, cci_store_id,
                               cci_question_one, cci_question_two,
                               cci_question_three, cci_answer_one,
                               cci_answer_two, cci_answer_three,
                               CCI_PACKAGE_TYPE, --Dhiraj GAikwad
                               --Sn 4.0 changes
                               cci_id_number, 
                               cci_ssn_encr, 
                               cci_id_number_encr  
                               --En 4.0 changes
                              )
                       VALUES (i.mci_inst_code,
                               DECODE (i.mci_inv_flag,
                                       'Y', v_ordr_rfrno,
                                       i.mci_file_name
                                      ),
                               v_rowid, v_appl_code,
                               SUBSTR (i.mci_pan_code, 1, 6),
                               i.mci_mbr_numb, i.mci_exp_dat, NULL, --rec_type
                               i.mci_crd_typ, i.mci_prod_code,
                               i.mci_card_type, i.mci_fiid, NULL,
                               --i.mci_cust_id,  -- Changed on 20-JUN-2013
                               i.mci_cust_catg, i.mci_custappl_param1,
                               i.mci_custappl_param2, i.mci_custappl_param3,
                               i.mci_custappl_param4, i.mci_custappl_param5,
                               i.mci_custappl_param6, i.mci_custappl_param7,
                               i.mci_custappl_param8, i.mci_custappl_param9,
                               i.mci_title,
                               TO_DATE (i.mci_birth_date,
                                        'yyyymmdd:hh24:MI:SS'
                                       ),
                               i.mci_mothers_maiden_name, decode(i.mci_id_type,'SSN',fn_maskacct_ssn(i.mci_inst_code, i.mci_ssn,0)), --i.mci_ssn  --4.0. changes
                               i.mci_hobbies, i.mci_customer_param1,
                               i.mci_customer_param2, i.mci_customer_param3,
                               i.mci_customer_param4, i.mci_customer_param5,
                               i.mci_customer_param6, i.mci_customer_param7,
                               i.mci_customer_param8, i.mci_customer_param9,
                               i.mci_customer_param10, NULL,      --comm_type,
                               i.mci_seg12_branch_num,
                               i.mci_seg12_name_line1,
                               i.mci_seg12_name_line2,
                               i.mci_seg12_addr_line1,
                               i.mci_seg12_addr_line2, i.mci_seg12_city,
                               i.mci_seg12_state, i.mci_seg12_postal_code,
                               v_gcm_cntry_code, --i.mci_seg12_country_code,
                               i.mci_seg12_mobileno,
                               i.mci_seg12_homephone_no,
                               i.mci_seg12_officephone_no,
                               i.mci_seg12_emailid, i.mci_seg12_addr_param1,
                               i.mci_seg12_addr_param2,
                               i.mci_seg12_addr_param3,
                               i.mci_seg12_addr_param4,
                               i.mci_seg12_addr_param5,
                               i.mci_seg12_addr_param6,
                               i.mci_seg12_addr_param7,
                               i.mci_seg12_addr_param8,
                               i.mci_seg12_addr_param9,
                               i.mci_seg12_addr_param10,
                               i.mci_seg13_addr_line1,
                               i.mci_seg13_addr_line2, i.mci_seg13_city,
                               i.mci_seg13_state, i.mci_seg13_postal_code,
                               v_gcm_othercntry_code, --i.mci_seg13_country_code,
                               i.mci_seg13_mobileno,
                               i.mci_seg13_homephone_no,
                               i.mci_seg13_officephone_no,
                               i.mci_seg13_emailid, i.mci_seg13_addr_param1,
                               i.mci_seg13_addr_param2,
                               i.mci_seg13_addr_param3,
                               i.mci_seg13_addr_param4,
                               i.mci_seg13_addr_param5,
                               i.mci_seg13_addr_param6,
                               i.mci_seg13_addr_param7,
                               i.mci_seg13_addr_param8,
                               i.mci_seg13_addr_param9,
                               i.mci_seg13_addr_param10, i.mci_seg31_lgth,
                               i.mci_seg31_acct_cnt, i.mci_seg31_typ,
                               i.mci_seg31_num, i.mci_seg31_num_param1,
                               i.mci_seg31_num_param2,
                               i.mci_seg31_num_param3,
                               i.mci_seg31_num_param4,
                               i.mci_seg31_num_param5,
                               i.mci_seg31_num_param6,
                               i.mci_seg31_num_param7,
                               i.mci_seg31_num_param8,
                               i.mci_seg31_num_param9,
                               i.mci_seg31_num_param10, i.mci_seg31_stat,
                               i.mci_prod_amt, i.mci_fee_amt, i.mci_tot_amt,
                               i.mci_payment_mode, i.mci_instrument_no,
                               i.mci_emp_id, NULL,                --KYC reason
                               DECODE (i.mci_kyc_flag,
                                       0, 'E',
                                       1, 'Y',
                                       2, 'F',
                                       3, 'P',
                                       4, 'O',
                                       5, 'N'
                                      ),
                               i.mci_addon_flag, i.mci_id_type,
                               'O', 'A', i.mci_comments,
                               'Sucessful', p_lupduser, SYSDATE,
                               --i.mci_ins_date,
                               p_lupduser, SYSDATE,    --i.mci_lupd_date,
                                                        i.mci_store_id,
                               i.mci_question_one, i.mci_question_two,
                               i.mci_question_three, i.mci_answer_one,
                               i.mci_answer_two, i.mci_answer_three,
                               V_PACKAGE_type, --Dhiraj Gaikwad
                               --Sn 4.0 changes
                               decode(i.mci_id_type,'SSN',NULL,fn_maskacct_ssn(i.mci_inst_code, i.mci_ssn,0)), 
                               decode(i.mci_id_type,'SSN',fn_emaps_main(i.mci_ssn)), 
                               decode(i.mci_id_type,'SSN',NULL,fn_emaps_main(i.mci_ssn))  
                               --En 4.0 changes
                              );
               EXCEPTION
                  WHEN OTHERS
                  THEN
                     v_errmsg :=
                           'Error while inserting data into CAF_INFO_ENTRY '
                        || SUBSTR (SQLERRM, 1, 200);
                     v_migr_err_code := 'MIG-1_044';
                     v_migr_err_desc := 'CAFINFO_INS_ERR';
                     RAISE exp_reject_record_main;
               END;

               --En Added by Pankaj S. to log same in Caf_info_entry
               BEGIN
                  migr_log_success_pkg (p_instcode,
                                        i.mci_file_name,
                                        i.mci_rec_num,
                                        i.mci_pan_code,
                                        v_errmsg,
                                        p_lupduser
                                       );

                  UPDATE migr_caf_info_entry m
                     SET m.mci_proc_flag = 'S',
                         m.mci_process_msg = v_errmsg
                   WHERE m.ROWID = i.migr_rowid;

                  v_savepoint := v_savepoint + 1;
               END;
            EXCEPTION
               WHEN exp_reject_record_main
               THEN
                  ROLLBACK TO v_savepoint;
                  v_errmsg :=
                        'Error while migration for card no.'
                     || i.mci_pan_code
                     || ' as :'
                     || v_errmsg;
                  migr_log_error_pkg (p_instcode,
                                      i.mci_file_name,
                                      i.mci_rec_num,
                                      i.mci_pan_code,
                                      'CUST',
                                      v_errmsg,
                                      p_lupduser,
                                      v_migr_err_code,
                                      v_migr_err_desc
                                     );

                  UPDATE migr_caf_info_entry m
                     SET m.mci_proc_flag = 'E',
                         m.mci_process_msg = v_errmsg,
                         m.mci_err_code = v_migr_err_code
                   WHERE m.ROWID = i.migr_rowid;
               WHEN OTHERS
               THEN
                  v_errmsg :=
                        'Error while migration for card no.'
                     || i.mci_pan_code
                     || ' as : '
                     || SUBSTR (SQLERRM, 1, 200);
                  ROLLBACK TO v_savepoint;
                  migr_log_error_pkg (p_instcode,
                                      i.mci_file_name,
                                      i.mci_rec_num,
                                      i.mci_pan_code,
                                      'CUST',
                                      v_errmsg,
                                      p_lupduser,
                                      v_migr_err_code,
                                      v_migr_err_desc
                                     );

                  UPDATE migr_caf_info_entry m
                     SET m.mci_proc_flag = 'E',
                         m.mci_process_msg = v_errmsg,
                         m.mci_err_code = v_migr_err_code
                   WHERE m.ROWID = i.migr_rowid;
            END;

            IF v_rec_proc = v_commit_pnt
            THEN
               COMMIT;
               v_rec_proc := 0;
            END IF;
         --En  Loop for record pending for processing
         END LOOP;

         BEGIN
            SELECT COUNT (1)
              INTO v_count
              FROM migr_caf_info_entry
             WHERE mci_proc_flag = 'N' AND ROWNUM < 2;
         EXCEPTION
            WHEN OTHERS
            THEN
               v_count := 0;
         END;
      END LOOP;

      BEGIN
         UPDATE cms_merinv_ordr
            SET cmo_error_records = cmo_nocards_ordr - cmo_success_records
          WHERE cmo_inst_code = p_instcode -- Added on 16-sep-2013
          and  cmo_ins_user = p_lupduser;
      EXCEPTION
         WHEN OTHERS
         THEN
            p_errmsg := 'OK';
      END;

      COMMIT;
      p_errmsg := 'OK';
   EXCEPTION
      WHEN OTHERS
      THEN
         p_errmsg := 'Exception from Main ' || SUBSTR (SQLERRM, 1, 300);
   END;

   PROCEDURE migr_create_cust_pkg (
      p_instcode          IN       NUMBER,
      p_custtype          IN       NUMBER,
      p_corpcode          IN       NUMBER,
      p_custstat          IN       CHAR,
      p_salutcode         IN       VARCHAR2,
      p_firstname         IN       VARCHAR2,
      p_midname           IN       VARCHAR2,
      p_lastname          IN       VARCHAR2,
      p_dob               IN       DATE,
      p_gender            IN       CHAR,
      p_marstat           IN       CHAR,
      p_permid            IN       VARCHAR2,
      p_email1            IN       VARCHAR2,
      p_email2            IN       VARCHAR2,
      p_mobl1             IN       VARCHAR2,
      p_mobl2             IN       VARCHAR2,
      p_lupduser          IN       NUMBER,
      p_ssn               IN       VARCHAR2,
      p_maidname          IN       VARCHAR2,
      p_hobby             IN       VARCHAR2,
      p_empid             IN       VARCHAR2,
      p_catg_code         IN       VARCHAR2,
      --p_custid          IN       NUMBER,
      p_gen_custdata      IN       type_cust_rec_array,
      p_cust_username     IN       VARCHAR2,
      p_cust_password     IN       VARCHAR2,
      p_secu_que1         IN       VARCHAR2,
      p_secu_ans1         IN       VARCHAR2,
      p_secu_que2         IN       VARCHAR2,
      p_secu_ans2         IN       VARCHAR2,
      p_secu_que3         IN       VARCHAR2,
      p_secu_ans3         IN       VARCHAR2,
      p_kyc_flag          IN       VARCHAR2, --added by Pankaj S. for KYC flag
      p_id_type           IN       VARCHAR2,
      p_id_issuer         IN       VARCHAR2,
      p_idissuence_date   IN       DATE,
      p_idexpry_date      IN       DATE,
      --Sn 2.1 onward changes
      p_gproptin_flag     IN     VARCHAR2,
      p_prodcode          IN     VARCHAR2,  
      --En 2.1 onward changes
      p_custcode          OUT      NUMBER,
      p_migr_err_code     OUT      VARCHAR2,
      p_migr_err_desc     OUT      VARCHAR2,
      p_errmsg            OUT      VARCHAR2
   )
   IS
      dum                 NUMBER (1)          := 0;
      v_grpcode           NUMBER (1);
      v_corp              NUMBER;
      v_ctrlcode          VARCHAR2 (20);
      v_setdata_errmsg    VARCHAR2 (300);
      v_errmesg           VARCHAR2 (500);
      v_custrec_outdata   type_cust_rec_array;
      v_cust_id           NUMBER;
      v_hash_sqa1         VARCHAR2 (100);
      v_hash_sqa2         VARCHAR2 (100);
      v_hash_sqa3         VARCHAR2 (100);
      v_cust_ctrlcode     VARCHAR2 (25);
      --Sn 2.1 onward changes
      v_partner_id          cms_product_param.cpp_partner_id%TYPE;
      v_tandc_version    cms_product_param.cpp_tandc_version%TYPE;
      --En 2.1 onward changes 
   BEGIN
      --Main Begin Block Starts Here
      p_errmsg := 'OK';

      IF p_corpcode = 0
      THEN
         v_corp := NULL;
      ELSE
         v_corp := p_corpcode;
      END IF;

      BEGIN
         --Begin 1 Starts Here
         SELECT 1
           INTO dum
           FROM cms_inst_mast
          WHERE cim_inst_code = p_instcode;
      EXCEPTION
         --Begin 1 Exception
         WHEN NO_DATA_FOUND
         THEN
            p_errmsg :=
                  'No such Institution '
               || p_instcode
               || ' exists in Institution master ';
            p_migr_err_code := 'MIG-1_042';
            p_migr_err_desc := 'INVALID_INST_CODE';
            RETURN;
         WHEN OTHERS
         THEN
            p_errmsg :=
                  'Exception While Validating Institution While Create Cust '
               || SUBSTR (SQLERRM, 1, 200);
            p_migr_err_code := 'MIG-1_';
            p_migr_err_desc := 'OTHER_THAN_PRDEFINE_EXCP';
            RETURN;
      END;                                                --Begin 1 Ends Here+

      IF dum = 1
      THEN
         --if 1
         BEGIN
            v_cust_ctrlcode := p_instcode;

            /*BEGIN
               SELECT seq_custcode.NEXTVAL
                 INTO p_custcode
                 FROM DUAL;
            EXCEPTION
               WHEN OTHERS
               THEN
                  p_errmsg :=
                        'Error while selecting the customer code value from sequence  '
                     || SUBSTR (SQLERRM, 1, 200);
                  p_migr_err_code := 'MIG-1_043';
                  p_migr_err_desc := 'CUSTCODE_SEQ_GEN_ERR';
                  RETURN;
            END; */
            BEGIN
--               SELECT mct_ctrl_numb
--                 INTO p_custcode
--                 FROM migr_ctrl_table
--                WHERE mct_ctrl_code = v_cust_ctrlcode
--                  AND mct_ctrl_key = 'CUSTCODE'
--                  AND mct_inst_code = p_instcode;

              /*
               SELECT NVL (MAX (ccm_cust_code), 0) + 1
                 INTO p_custcode
                 FROM cms_cust_mast;
               */

                SELECT SEQ_CUSTCODE.NEXTVAL INTO p_custcode FROM DUAL; --Added for PT on 10-Oct-2013


            EXCEPTION
--               WHEN NO_DATA_FOUND
--               THEN
--                  p_custcode := 1;

               --                  INSERT INTO migr_ctrl_table
--                              (mct_ctrl_code, mct_ctrl_key, mct_ctrl_numb,
--                               mct_ctrl_desc,
--                               mct_ins_user, mct_ins_date, mct_lupd_user,
--                               mct_lupd_date, mct_inst_code
--                              )
--                       VALUES (p_instcode, 'CUSTCODE', 2,
--                                  'Latest Cust code for Institution '
--                               || p_instcode,
--                               p_lupduser, SYSDATE, p_lupduser,
--                               SYSDATE, p_instcode
--                              );
               WHEN OTHERS
               THEN
                  p_errmsg :=
                        'Error while fetching custcode '
                     || SUBSTR (SQLERRM, 1, 200);
                  p_migr_err_code := 'MIG-1_044';
                  p_migr_err_desc := 'CUSTGRUP_INS_ERR';
                  RETURN;
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
                                  ccg_group_desc, ccg_ins_user,
                                  ccg_ins_date, ccg_lupd_user, ccg_lupd_date
                                 )
                          VALUES (p_instcode, v_grpcode,
                                  'DEFAULT GROUP', p_lupduser,
                                  SYSDATE, p_lupduser, SYSDATE
                                 );
                  EXCEPTION
                     WHEN OTHERS
                     THEN
                        p_errmsg :=
                              'Error while inserting data for customer group '
                           || SUBSTR (SQLERRM, 1, 200);
                        p_migr_err_code := 'MIG-1_044';
                        p_migr_err_desc := 'CUSTGRUP_INS_ERR';
                        RETURN;
                  END;
               END IF;
            EXCEPTION
               WHEN OTHERS
               THEN
                  p_errmsg :=
                        'Error while fetching group code '
                     || SUBSTR (SQLERRM, 1, 200);
                  p_migr_err_code := 'MIG-1_';
                  p_migr_err_desc := 'OTHER_THAN_PRDEFINE_EXCP';
                  RETURN;
            END;

            BEGIN

              /*
               SELECT NVL (MAX (ccm_cust_id), 0) + 1
                 INTO v_cust_id
                 FROM cms_cust_mast;
              */

               SELECT SEQ_CUST_ID.NEXTVAL INTO v_cust_id FROM DUAL; --Added for PT on 10-Oct-2013


            EXCEPTION
               WHEN OTHERS
               THEN
                  p_errmsg :=
                        'Error while selecting the value for customer id '
                     || SUBSTR (SQLERRM, 1, 200);
                  p_migr_err_code := 'MIG-1_';
                  RETURN;
            END;

-- SN : COMMENTED BY GANESH FOR MIGRATION

            --         IF p_catg_code = 'P' AND p_custid IS NOT NULL
--         THEN
--            v_cust_id := p_custid;
--         ELSIF p_catg_code = 'P' AND p_custid IS NULL
--         THEN
--            BEGIN
--               -- Sn; Added by sagar on 02-apr-2012 for customer id generation requirement
--               SELECT seq_cust_id.NEXTVAL
--                 INTO v_cust_id
--                 FROM DUAL;
--            EXCEPTION
--               WHEN OTHERS
--               THEN
--                  p_errmsg :=
--                        'Error while selecting the value for customer id '
--                     || SUBSTR (SQLERRM, 1, 200);
--                  p_migr_err_code := 'MIG-1_';
--                  RETURN;
--            END;
--         -- Sn; Added by sagar on 02-apr-2012 for customer id generation requirement
--               -- IF PREPAID THEN
--               --V_CUST_ID := p_CUSTCODE; -- Commneted by sagar on 02-apr-2012 for customer id generation requirement
--         END IF;

            -- EN : COMMENTED BY GANESH FOR MIGRATION
--            IF p_catg_code IN ('D', 'A')
--            THEN
--               -- IF DEBIT THEN
--               v_cust_id := p_custid;
--            END IF;

            --       EXCEP HANDLER ADDED BY GANESH
            --Sn set the generic variable
            BEGIN
               migr_set_gen_custdata_pkg (p_instcode,
                                          p_gen_custdata,
                                          v_custrec_outdata,
                                          v_setdata_errmsg
                                         );

               IF v_setdata_errmsg <> 'OK'
               THEN
                  p_errmsg :=
                        'Error in set gen parameters while creating customer  '
                     || v_setdata_errmsg;
                  p_migr_err_code := 'MIG-1_';
                  p_migr_err_desc := 'OTHER_THAN_PRDEFINE_EXCP';
                  RETURN;
               END IF;
            EXCEPTION
               WHEN OTHERS
               THEN
                  p_errmsg :=
                        'Error While calling get generic customer data procedure '
                     || SUBSTR (SQLERRM, 1, 200);
                  p_migr_err_code := 'MIG-1_';
                  p_migr_err_desc := 'OTHER_THAN_PRDEFINE_EXCP';
                  RETURN;
            END;

            --En set the generic variable
            
             --Sn Added for Partner ID Changes
             BEGIN
                SELECT cpp_partner_id, cpp_tandc_version 
                  INTO v_partner_id, v_tandc_version
                  FROM cms_product_param
                 WHERE cpp_prod_code = p_prodcode AND cpp_inst_code = p_instcode;
             EXCEPTION
                WHEN NO_DATA_FOUND THEN
                   p_errmsg :='Product code '|| p_prodcode || ' is not defined in the product param master';
                   p_migr_err_code := 'MIG-1_045';
                   p_migr_err_desc := 'PRODUCT_PARAM_NOT_DEFINED';
                   return;
                WHEN OTHERS THEN
                   p_errmsg :='Error while selecting partner dtls- ' || SUBSTR (SQLERRM, 1, 200);
                   p_migr_err_code := 'MIG-1_';
                   p_migr_err_desc := 'OTHER_THAN_PRDEFINE_EXCP';
                   return;
             END;
             --En Added for Partner ID Changes
     
            BEGIN
               INSERT INTO cms_cust_mast
                           (ccm_inst_code, ccm_cust_code, ccm_group_code,
                            ccm_cust_type, ccm_corp_code, ccm_cust_stat,
                            ccm_salut_code, ccm_first_name,
                            ccm_mid_name, ccm_last_name, ccm_birth_date,
                            ccm_perm_id, ccm_email_one, ccm_email_two,
                            ccm_mobl_one, ccm_mobl_two, ccm_ins_user,
                            ccm_lupd_user, ccm_gender_type,
                            ccm_marital_stat, ccm_ssn, ccm_mother_name,
                            ccm_hobbies, ccm_cust_id, ccm_emp_id,
                            ccm_cust_param1, ccm_cust_param2,
                            ccm_cust_param3, ccm_cust_param4,
                            ccm_cust_param5, ccm_cust_param6,
                            ccm_cust_param7, ccm_cust_param8,
                            ccm_cust_param9, ccm_cust_param10,
                            ccm_user_name, ccm_password_hash,
                            ccm_kyc_flag  --added by Pankaj S. to log KYC flag
                                        ,
                            ccm_id_type,               -- Added on 25-JUN-2013
                                        ccm_id_issuer, -- Added on 25-JUN-2013
                                                      ccm_idissuence_date,
                            -- Added on 25-JUN-2013
                            ccm_idexpry_date,          -- Added on 25-JUN-2013
                            --Sn 2.1 onward changes
                            ccm_gpr_optin,
                            ccm_flnamedob_hashkey,
                            ccm_partner_id,
                            ccm_tandc_version ,   
                            --En 2.1 onward changes
                            ccm_ssn_encr  --4.0 changes
                           )
                    VALUES (p_instcode, p_custcode, v_grpcode,
                            p_custtype, v_corp, p_custstat,
                            p_salutcode, UPPER (p_firstname),
                            UPPER (p_midname), UPPER (p_lastname), p_dob,
                            p_permid, p_email1, p_email2,
                            p_mobl1, p_mobl2, p_lupduser,
                            p_lupduser, p_gender,
                            p_marstat, fn_maskacct_ssn(p_instcode,p_ssn,0),--p_ssn,    --4.0 changes
                            p_maidname,
                            p_hobby, v_cust_id, p_empid,
                            v_custrec_outdata (1), v_custrec_outdata (2),
                            v_custrec_outdata (3), v_custrec_outdata (4),
                            v_custrec_outdata (5), v_custrec_outdata (6),
                            v_custrec_outdata (7), v_custrec_outdata (8),
                            v_custrec_outdata (9), v_custrec_outdata (10),
                            p_cust_username, p_cust_password,
                            DECODE (p_kyc_flag,
                                    0, 'E',
                                    1, 'Y',
                                    2, 'F',
                                    3, 'P',
                                    4, 'O',
                                    5, 'N'
                                   ),
                                     --added by Pankaj S. to store KYC details
                            --added by Pankaj S. to store KYC details
                            p_id_type,                 -- Added on 25-JUN-2013
                                      p_id_issuer,     -- Added on 25-JUN-2013
                                                  p_idissuence_date,
                            -- Added on 25-JUN-2013
                            p_idexpry_date,             -- Added on 25-JUN-2013
                            --Sn 2.1 onward changes
                            p_gproptin_flag,
                            gethash(UPPER (p_firstname)||UPPER (p_lastname)||p_dob),
                            v_partner_id, 
                            v_tandc_version,
                            --En 2.1 onward changes
                            fn_emaps_main(p_ssn)  --4.0 changes
                           );
            EXCEPTION
               WHEN DUP_VAL_ON_INDEX
               THEN
                  p_errmsg :=
                     'Duplicate record found while creating customer in master '; --Error message modified by Pankaj S. on 25-Sep-2013
                  p_migr_err_code := 'MIG-1_045';
                  p_migr_err_desc := 'DUPLICATE_CUST_CODE';
                  RETURN;
               WHEN OTHERS
               THEN
                  p_errmsg :=
                        'Error while creating customer in master'
                     || SUBSTR (SQLERRM, 1, 150);
                  p_migr_err_code := 'MIG-1_';
                  p_migr_err_desc := 'OTHER_THAN_PRDEFINE_EXCP';
                  RETURN;
            END;
--            BEGIN
--               UPDATE migr_ctrl_table
--                  SET mct_ctrl_numb = mct_ctrl_numb + 1
--                WHERE mct_ctrl_code = v_cust_ctrlcode
--                  AND mct_ctrl_key = 'CUSTCODE'
--                  AND mct_inst_code = p_instcode;

         --               IF SQL%ROWCOUNT = 0
--               THEN
--                  p_errmsg := 'Control table not updated for customer code';
--                  p_migr_err_code := 'MIG-1_073';
--                  p_migr_err_desc := 'CUST_CTRL_UPDT_ERR';
--                  RETURN;
--               END IF;
--            EXCEPTION
--               WHEN OTHERS
--               THEN
--                  p_errmsg :=
--                        'Error while updating control table for the customer code : '
--                     || SUBSTR (SQLERRM, 1, 200);
--                  p_migr_err_code := 'MIG-1_';
--                  p_migr_err_desc := 'OTHER_THAN_PRDEFINE_EXCP';
--                  RETURN;
--            END;
         END;                                              --Begin 2 Ends Here
      END IF;                                                           --if 1

      --Sn This is commented time being
      /*BEGIN
         v_hash_sqa1 := gethash (TRIM (p_secu_ans1));
      EXCEPTION
         WHEN OTHERS
         THEN
            p_errmsg :=
                  'Error while converting sequrity answer one '
               || SUBSTR (SQLERRM, 1, 200);
            p_migr_err_code := 'MIG-1_073';
            p_migr_err_desc := 'SECU_QUEANS_HASH_EXCP';
            RETURN;
      END;

      BEGIN
         v_hash_sqa2 := gethash (TRIM (p_secu_ans2));
      EXCEPTION
         WHEN OTHERS
         THEN
            p_errmsg :=
                  'Error while converting sequrity answer two '
               || SUBSTR (SQLERRM, 1, 200);
            p_migr_err_code := 'MIG-1_073';
            p_migr_err_desc := 'SECU_QUEANS_HASH_EXCP';
            RETURN;
      END;

      BEGIN
         v_hash_sqa3 := gethash (TRIM (p_secu_ans3));
      EXCEPTION
         WHEN OTHERS
         THEN
            p_errmsg :=
                  'Error while converting sequrity answer three '
               || SUBSTR (SQLERRM, 1, 200);
            p_migr_err_code := 'MIG-1_073';
            p_migr_err_desc := 'SECU_QUEANS_HASH_EXCP';
            RETURN;
      END;*/
      --En This is commented time being
      BEGIN
         INSERT INTO cms_security_questions
                     (csq_inst_code, csq_cust_id, csq_question,
                      csq_answer_hash
                     )
              VALUES (p_instcode, v_cust_id, TRIM (p_secu_que1),
                      p_secu_ans1
                     );

         INSERT INTO cms_security_questions
                     (csq_inst_code, csq_cust_id, csq_question,
                      csq_answer_hash
                     )
              VALUES (p_instcode, v_cust_id, TRIM (p_secu_que2),
                      p_secu_ans2
                     );

         INSERT INTO cms_security_questions
                     (csq_inst_code, csq_cust_id, csq_question,
                      csq_answer_hash
                     )
              VALUES (p_instcode, v_cust_id, TRIM (p_secu_que3),
                      p_secu_ans3
                     );
      EXCEPTION
         WHEN OTHERS
         THEN
            p_errmsg :=
                  'Error while inserting sequrity Questions & Answers ' --Error message modified by Pankaj S. on 25-Sep-2013
               || SUBSTR (SQLERRM, 1, 200);
            p_migr_err_code := 'MIG-1_074';
            p_migr_err_desc := 'SECU_QUEANS_LOG_EXCP';
            RETURN;
      END;
   EXCEPTION
      --Main block Exception
      WHEN OTHERS
      THEN
         p_errmsg :=
               'Main Exception While Creating Customer '
            || SUBSTR (SQLERRM, 1, 200);
         p_migr_err_code := 'MIG-1_';
         p_migr_err_desc := 'OTHER_THAN_PRDEFINE_EXCP';
   END;

   PROCEDURE migr_create_addr_pkg (
      p_instcode        IN       NUMBER,
      p_custcode        IN       NUMBER,
      p_add1            IN       VARCHAR2,
      p_add2            IN       VARCHAR2,
      p_add3            IN       VARCHAR2,
      p_pincode         IN       VARCHAR2,
      p_phon1           IN       VARCHAR2,
      p_phon2           IN       VARCHAR2,
      p_officno         IN       VARCHAR2,
      p_email           IN       VARCHAR2,
      p_cntrycode       IN       NUMBER,
      p_cityname        IN       VARCHAR2,
      p_switchstat      IN       VARCHAR2,       --state as coming from switch
      p_fax1            IN       VARCHAR2,
      p_addrflag        IN       CHAR,
      p_comm_type       IN       CHAR,
      p_lupduser        IN       NUMBER,
      p_genaddr_data    IN       type_addr_rec_array,
      p_addrcode        OUT      NUMBER,
      p_migr_err_code   OUT      VARCHAR2,
      p_migr_err_desc   OUT      VARCHAR2,
      p_errmsg          OUT      VARCHAR2
   )
   IS
      v_addrrec_outdata      type_addr_rec_array;
      v_setaddrdata_errmsg   VARCHAR2 (500);
      v_state_switch_code    gen_state_mast.gsm_switch_state_code%TYPE;
      v_state_code           gen_state_mast.gsm_state_code%TYPE;
      v_addr_ctrlcode        VARCHAR2 (25);
   BEGIN
      p_errmsg := 'OK';
      v_addr_ctrlcode := p_instcode;

      /*BEGIN
         SELECT seq_addr_code.NEXTVAL
           INTO p_addrcode
           FROM DUAL;
      EXCEPTION
         WHEN OTHERS
         THEN
            p_errmsg :=
                  'Error while generating address code '
               || SUBSTR (SQLERRM, 1, 200);
            p_migr_err_code := 'MIG-1_047';
            p_migr_err_desc := 'ADDRCODE_SEQ_GEN_ERR';
            RETURN;
      END;*/
      BEGIN
--         SELECT mct_ctrl_numb
--           INTO p_addrcode
--           FROM migr_ctrl_table
--          WHERE mct_ctrl_code = v_addr_ctrlcode
--            AND mct_ctrl_key = 'ADDRCODE'
--            AND mct_inst_code = p_instcode;

        /*
         SELECT NVL (MAX (cam_addr_code), 0) + 1
           INTO p_addrcode
           FROM cms_addr_mast;
         */

          SELECT SEQ_ADDR_CODE.NEXTVAL INTO p_addrcode FROM DUAL;  --Added for PT on 10-Oct-2013


      EXCEPTION
--         WHEN NO_DATA_FOUND
--         THEN
--            p_addrcode := 1;

         --            INSERT INTO migr_ctrl_table
--                        (mct_ctrl_code, mct_ctrl_key, mct_ctrl_numb,
--                         mct_ctrl_desc,
--                         mct_ins_user, mct_ins_date, mct_lupd_user,
--                         mct_lupd_date, mct_inst_code
--                        )
--                 VALUES (p_instcode, 'ADDRCODE', 2,
--                         'Latest Address code for Institution ' || p_instcode,
--                         p_lupduser, SYSDATE, p_lupduser,
--                         SYSDATE, p_instcode
--                        );
         WHEN OTHERS
         THEN
            p_errmsg :=
                  'Error while fetching address code '
               || SUBSTR (SQLERRM, 1, 200);
            p_migr_err_code := 'MIG-1_';
            p_migr_err_desc := 'OTHER_THAN_PRDEFINE_EXCP';
            RETURN;
      END;

      --Sn set the generic variable
      BEGIN
         migr_set_gen_addrdata_pkg (p_instcode,
                                    p_genaddr_data,
                                    v_addrrec_outdata,
                                    v_setaddrdata_errmsg
                                   );

         IF v_setaddrdata_errmsg <> 'OK'
         THEN
            p_errmsg :=
                     'Error in set genetic address parameters   ' || v_setaddrdata_errmsg;
            p_migr_err_code := 'MIG-1_';
            p_migr_err_desc := 'OTHER_THAN_PRDEFINE_EXCP';
            RETURN;
         END IF;
      EXCEPTION
         WHEN OTHERS
         THEN
            p_errmsg :=
                  'Error While get generic address data : '
               || SUBSTR (SQLERRM, 1, 200);
            p_migr_err_code := 'MIG-1_';
            p_migr_err_desc := 'OTHER_THAN_PRDEFINE_EXCP';
            RETURN;
      END;

      --En set the generic variable
      --Sn ger state and switch code
      BEGIN
         migr_get_state_code_pkg (p_instcode,
                                  p_switchstat,
                                  p_cntrycode,
                                  v_state_code,
                                  v_state_switch_code,
                                  p_migr_err_code,
                                  p_migr_err_desc,
                                  p_errmsg
                                 );

         IF p_errmsg <> 'OK'
         THEN
            RETURN;
         END IF;
      EXCEPTION
         WHEN OTHERS
         THEN
            p_errmsg :=
                  'Error While gen state code process : '
               || SUBSTR (SQLERRM, 1, 200);
            p_migr_err_code := 'MIG-1_';
            p_migr_err_desc := 'OTHER_THAN_PRDEFINE_EXCP';
            RETURN;
      END;

      --En get state and switch code
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
                      cam_addrmast_param9, cam_addrmast_param10
                     )
              VALUES (p_instcode, p_custcode, p_addrcode,
                      p_add1, p_add2, p_add3, p_pincode,
                      p_phon1, p_officno, p_phon2, p_email,
                      p_cntrycode, p_cityname, p_fax1,
                      p_addrflag, v_state_code, p_lupduser,
                      p_lupduser, p_comm_type, v_state_switch_code,
                      v_addrrec_outdata (1), v_addrrec_outdata (2),
                      v_addrrec_outdata (3), v_addrrec_outdata (4),
                      v_addrrec_outdata (5), v_addrrec_outdata (6),
                      v_addrrec_outdata (7), v_addrrec_outdata (8),
                      v_addrrec_outdata (9), v_addrrec_outdata (10)
                     );
      EXCEPTION
         WHEN DUP_VAL_ON_INDEX
         THEN
            p_errmsg := 'Duplicate record found while creating address '; --Error message modified by Pankaj S. on 25-Sep-2013
            p_migr_err_code := 'MIG-1_050';
            p_migr_err_desc := 'DUPL_ADDR_CODE_FOUND';
            RETURN;
         WHEN OTHERS
         THEN
            p_errmsg :=
                  'Error while creating address ' || SUBSTR (SQLERRM, 1, 200);
            p_migr_err_code := 'MIG-1_';
            p_migr_err_desc := 'OTHER_THAN_PRDEFINE_EXCP';
            RETURN;
      END;
--      BEGIN
--         UPDATE migr_ctrl_table
--            SET mct_ctrl_numb = mct_ctrl_numb + 1
--          WHERE mct_ctrl_code = v_addr_ctrlcode
--            AND mct_ctrl_key = 'ADDRCODE'
--            AND mct_inst_code = p_instcode;

   --         IF SQL%ROWCOUNT = 0
--         THEN
--            p_errmsg := 'Control table not updated for address code';
--            p_migr_err_code := 'MIG-1_074';
--            p_migr_err_desc := 'ADDR_CTRL_UPDT_ERR';
--            RETURN;
--         END IF;
--      EXCEPTION
--         WHEN OTHERS
--         THEN
--            p_errmsg :=
--                  'Error while updating control table for the adrress code : '
--               || SUBSTR (SQLERRM, 1, 200);
--            p_migr_err_code := 'MIG-1_';
--            p_migr_err_desc := 'OTHER_THAN_PRDEFINE_EXCP';
--            RETURN;
--      END;
   EXCEPTION
      --Main block Exception
      WHEN OTHERS
      THEN
         p_errmsg :=
            'Main Exexption During Create Addr : '
            || SUBSTR (SQLERRM, 1, 200);
         p_migr_err_code := 'MIG-1_';
         p_migr_err_desc := 'OTHER_THAN_PRDEFINE_EXCP';
   END;                                           --Main Begin Block Ends Here

PROCEDURE migr_create_acct_pcms_pkg (
      p_instcode              IN       NUMBER,
      p_acctno                IN       VARCHAR2,
      p_holdcount             IN       NUMBER,
      p_currbran              IN       VARCHAR2,
      p_billaddr              IN       NUMBER,
      p_accttype              IN       NUMBER,
      p_acctstat              IN       NUMBER,
      p_acctgen_date          IN       DATE,
      p_avail_bal             IN       NUMBER,
      p_ledg_bal              IN       NUMBER,
      p_svngacct_reopn_date   IN       DATE,
      p_svngacct_intrstamt    IN       NUMBER,
      p_initialtopup_amt      IN  NUMBER,   --2.1 onward changes
      p_lupduser              IN       NUMBER,
      p_dup_flag              OUT      VARCHAR2,
      p_acctid                OUT      NUMBER,
      p_migr_err_code         OUT      VARCHAR2,
      p_migr_err_desc         OUT      VARCHAR2,
      p_errmsg                OUT      VARCHAR2
   )
   IS
      v_p_acctno           cms_acct_mast.cam_acct_no%TYPE;
      uniq_excp_p_acctno   EXCEPTION;
      PRAGMA EXCEPTION_INIT (uniq_excp_p_acctno, -00001);
      excp_reject_acct     EXCEPTION;     -- ADDED BY GANESH DURING MIGRATION
      v_acct_ctrlcode      VARCHAR2 (25);
      v_cnt                NUMBER (5);
   BEGIN                                        --Main Begin Block Starts Here
       --Sn get acct number
      /* BEGIN
          SELECT seq_acct_id.NEXTVAL
            INTO p_acctid
            FROM DUAL;
       EXCEPTION
          WHEN OTHERS
          THEN
             p_errmsg :=
                   'Error while generating account id '
                || SUBSTR (SQLERRM, 1, 200);
             p_migr_err_code := 'MIG-0_010';
             p_migr_err_desc := 'ACCTNO_SEQGRN_ERR';
             -- RAISE uniq_excp_acctno; -- COMMNTED BY GANESH AS IT MAY OVERWRITE THE ERROR MESG
             RAISE excp_reject_acct;
       END;
       */
      p_errmsg := 'OK';
      v_acct_ctrlcode := p_instcode;

      SELECT COUNT (1)
        INTO v_cnt
        FROM cms_acct_mast
       WHERE cam_inst_code = p_instcode AND cam_acct_no = p_acctno;

      IF v_cnt = 0
      THEN
         BEGIN
--         SELECT mct_ctrl_numb
--           INTO p_acctid
--           FROM migr_ctrl_table
--          WHERE mct_ctrl_code = v_acct_ctrlcode
--            AND mct_ctrl_key = 'ACCTID'
--            AND mct_inst_code = p_instcode;

           /*
            SELECT NVL (MAX (cam_acct_id), 0) + 1
              INTO p_acctid
              FROM cms_acct_mast;
            */

            SELECT SEQ_ACCT_ID.NEXTVAL INTO p_acctid FROM DUAL;  --Added for PT on 10-Oct-2013


         EXCEPTION
--         WHEN NO_DATA_FOUND
--         THEN
--            p_acctid := 1;

            --            INSERT INTO migr_ctrl_table
--                        (mct_ctrl_code, mct_ctrl_key, mct_ctrl_numb,
--                         mct_ctrl_desc,
--                         mct_ins_user, mct_ins_date, mct_lupd_user,
--                         mct_lupd_date, mct_inst_code
--                        )
--                 VALUES (p_instcode, 'ACCTID', 2,
--                         'Latest Account Id for Institution ' || p_instcode,
--                         p_lupduser, SYSDATE, p_lupduser,
--                         SYSDATE, p_instcode
--                        );
            WHEN OTHERS
            THEN
               p_errmsg :=
                     'Error while fetching the account id'
                  || SUBSTR (SQLERRM, 1, 200);
               p_migr_err_code := 'MIG-1_';
               p_migr_err_desc := 'OTHER_THAN_PRDEFINE_EXCP';
               RAISE excp_reject_acct;
         END;

         --En get acct number
         IF p_acctno IS NULL
         THEN
            v_p_acctno := TRIM (p_acctid);
         ELSIF p_acctno IS NOT NULL
         THEN
            v_p_acctno := p_acctno;
         --Modified by Pankaj S. to trim left padded Zero's
         END IF;

         BEGIN               -- SEPERATE EXCP HANDLER ADDED FOR THIS INSERT AS
            INSERT INTO cms_acct_mast
                        (cam_inst_code, cam_acct_id, cam_acct_no,
                         cam_hold_count, cam_curr_bran, cam_bill_addr,
                         cam_type_code, cam_stat_code, cam_ins_user,
                         cam_lupd_user, cam_acct_bal, cam_ledger_bal,
                         cam_creation_date, cam_interest_amount,
                         cam_initialload_amt  --2.1 onward Changes 
                        )
                 VALUES (p_instcode, p_acctid, v_p_acctno,
                         p_holdcount, p_currbran, p_billaddr,
                         p_accttype, p_acctstat, p_lupduser,
                         p_lupduser, p_avail_bal, p_ledg_bal,
                         p_acctgen_date, p_svngacct_intrstamt,
                         p_initialtopup_amt   --2.1 onward Changes 
                        );

            p_dup_flag := 'A';
            p_errmsg := 'OK';
         EXCEPTION                                      --Main block Exception
            WHEN uniq_excp_p_acctno
            THEN
               p_errmsg := 'Account No already exists in Master.';
               p_migr_err_code := 'MIG-0_011';
               p_migr_err_desc := 'ACCTNO_ALREADY_EXISTS';
               p_dup_flag := 'D';
               RAISE excp_reject_acct;
            WHEN OTHERS
            THEN
               p_errmsg :=
                     'Error while creating account entry : '
                  || SUBSTR (SQLERRM, 1, 200);
               p_migr_err_code := 'MIG-1_';
               p_migr_err_desc := 'OTHER_THAN_PRDEFINE_EXCP';
               RAISE excp_reject_acct;
         END;
      END IF;
--      BEGIN
--         UPDATE migr_ctrl_table
--            SET mct_ctrl_numb = mct_ctrl_numb + 1
--          WHERE mct_ctrl_code = v_acct_ctrlcode
--            AND mct_ctrl_key = 'ACCTID'
--            AND mct_inst_code = p_instcode;

   --         IF SQL%ROWCOUNT = 0
--         THEN
--            p_errmsg := 'Control table not updated for account id ';
--            p_migr_err_code := 'MIG-1_075';
--            p_migr_err_desc := 'ACCT_CTRL_UPDT_ERR';
--            RAISE excp_reject_acct;
--         END IF;
--      EXCEPTION
--         WHEN OTHERS
--         THEN
--            p_errmsg :=
--                  'Error while updating control table for the account id : '
--               || SUBSTR (SQLERRM, 1, 200);
--            p_migr_err_code := 'MIG-1_';
--            p_migr_err_desc := 'OTHER_THAN_PRDEFINE_EXCP';
--            RAISE excp_reject_acct;
--      END;
   EXCEPTION
      WHEN excp_reject_acct
      THEN
         p_errmsg := p_errmsg;
      WHEN OTHERS
      THEN
         p_errmsg :=
               'Main Exception While creating account number '
            || SUBSTR (SQLERRM, 1, 200);
         p_migr_err_code := 'MIG-1_';
         p_migr_err_desc := 'OTHER_THAN_PRDEFINE_EXCP';
   END;

   PROCEDURE migr_create_holder_pkg (
      p_instcode        IN       NUMBER,
      p_custcode        IN       NUMBER,
      p_acctid          IN       NUMBER,
      p_acctname        IN       VARCHAR2,
      --billadd1        IN    number, shifted to account level from holder level
      p_lupduser        IN       NUMBER,
      p_holdposn        OUT      NUMBER,
      p_migr_err_code   OUT      VARCHAR2,
      p_migr_err_desc   OUT      VARCHAR2,
      p_errmsg          OUT      VARCHAR2
   )
   IS
      v_cnt   NUMBER (1);
   BEGIN                                        --Main Begin Block Starts Here
      p_errmsg := 'OK';

      BEGIN
         SELECT COUNT (1)
           INTO v_cnt
           FROM cms_cust_acct
          WHERE cca_inst_code = p_instcode
            AND cca_cust_code = p_custcode
            AND cca_acct_id = p_acctid;

         IF v_cnt > 0
         THEN
            p_errmsg := 'OK';

            BEGIN
               UPDATE cms_cust_acct
                  SET cca_rel_stat = 'Y'
                WHERE cca_inst_code = p_instcode
                  AND cca_cust_code = p_custcode
                  AND cca_acct_id = p_acctid;
            EXCEPTION
               WHEN OTHERS
               THEN
                  p_errmsg :=
                        'Error while getting customer acct relation '
                     || SUBSTR (SQLERRM, 1, 200);
                  p_migr_err_code := 'MIG-1_';
                  p_migr_err_desc := 'OTHER_THAN_PRDEFINE_EXCP';
                  RETURN;
            END;

            RETURN;
         END IF;
      EXCEPTION                                            -- Added by Ganesh.
         WHEN OTHERS
         THEN
            p_errmsg :=
                  'Error While finding customer account relation :'
               || SUBSTR (SQLERRM, 1, 100);
            p_migr_err_code := 'MIG-1_';
            p_migr_err_desc := 'OTHER_THAN_PRDEFINE_EXCP';
            RETURN;
      END;

      -- EN Chinmaya added: return if holder exist for the a/c
      BEGIN
         SELECT NVL (MAX (cca_hold_posn), 0) + 1
           INTO p_holdposn
           FROM cms_cust_acct
          WHERE cca_inst_code = p_instcode AND cca_acct_id = p_acctid;
      EXCEPTION                                            -- Added by Ganesh.
         WHEN OTHERS
         THEN
            p_errmsg :=
                  'Error While getting the hold position :'
               || SUBSTR (SQLERRM, 1, 200);
            p_migr_err_code := 'MIG-1_';
            p_migr_err_desc := 'OTHER_THAN_PRDEFINE_EXCP';
            RETURN;
      END;

      /*P_holdposn := 0;*/
      BEGIN
         INSERT INTO cms_cust_acct
                     (cca_inst_code, cca_cust_code, cca_acct_id,
                      cca_acct_name,
                                    --CCA_BILL_ADDR1    ,
                                    cca_hold_posn, cca_rel_stat,
                      cca_ins_user, cca_lupd_user
                     )
              VALUES (p_instcode, p_custcode, p_acctid,
                      p_acctname,
                                 --billadd1                ,
                                 p_holdposn, 'Y',
                      --means that the relation is active
                      p_lupduser, p_lupduser
                     );
      EXCEPTION
         WHEN OTHERS
         THEN
            p_errmsg :=
                  'error while inserting data in cust acct '
               || SUBSTR (SQLERRM, 1, 200);
            p_migr_err_code := 'MIG-1_053';
            p_migr_err_desc := 'CUST_ACCT_RELN_ERRR';
            RETURN;
      END;
   EXCEPTION                                            --Main block Exception
      WHEN OTHERS
      THEN
         p_errmsg := 'Main Exception ' || SUBSTR (SQLERRM, 1, 200);
         p_migr_err_code := 'MIG-1_';
         p_migr_err_desc := 'OTHER_THAN_PRDEFINE_EXCP';
         RETURN;
   END;                                           --Main Begin Block Ends Here

   PROCEDURE migr_create_appl_pcms_pkg (
      p_instcode               IN       NUMBER,
      p_assocode               IN       NUMBER,
      p_insttype               IN       NUMBER,
      p_applno                 IN       VARCHAR2,
      p_appldate               IN       DATE,
      p_regdate                IN       DATE,
      p_custcode               IN       NUMBER,
      p_applbran               IN       VARCHAR2,
      p_prodcode               IN       VARCHAR2,
      p_cardtype               IN       NUMBER,
      p_custcatg               IN       NUMBER,
      p_activedate             IN       DATE,
      p_exprydate              IN       DATE,
      p_dispname               IN       VARCHAR2,
      p_limtamt                IN       NUMBER,
      p_addonissu              IN       CHAR,
      p_usagelimt              IN       NUMBER,
      p_totacct                IN       NUMBER,
      p_addonstat              IN       CHAR,
      p_addonlink              IN       NUMBER,
      p_billaddr               IN       NUMBER,
      p_chnlcode               IN       NUMBER,
      p_request_id             IN       VARCHAR2,
      p_payment_ref            IN       VARCHAR2,
      p_appluser               IN       NUMBER,
      p_lupduser               IN       NUMBER,
      p_initial_topup_amount   IN       NUMBER,
      p_starter_crd_flag       IN       VARCHAR2,
      p_applcode               OUT      NUMBER,
      p_migr_err_code          OUT      VARCHAR2,
      p_migr_err_desc          OUT      VARCHAR2,
      p_errmsg                 OUT      VARCHAR2
   )
   IS
      truep_addonlink   NUMBER (20);
      v_cpc_catg_appl   VARCHAR2 (2);
      v_cam_bill_addr   cms_appl_pan.cap_bill_addr%TYPE;
      v_appl_stat       cms_appl_mast.cam_appl_stat%TYPE;
      v_pay_ref         cms_appl_mast.cam_payment_ref%TYPE;
      v_host_proc       cms_inst_param.cip_param_value%TYPE;
      v_appl_code       NUMBER (15);
      v_appl_ctrlcode   VARCHAR2 (25);
   BEGIN
      BEGIN
         SELECT cpc_catg_appl
           INTO v_cpc_catg_appl
           FROM cms_prod_catg
          WHERE cpc_inst_code = p_instcode
            AND cpc_catg_code =
                   (SELECT cpm_catg_code
                      FROM cms_prod_mast
                     WHERE cpm_inst_code = p_instcode
                       AND cpm_prod_code = p_prodcode);
      EXCEPTION
         WHEN NO_DATA_FOUND
         THEN
            p_errmsg :=
                  ' No data found for prod code '|| p_prodcode||' for creating application details'; --Error message modified by Pankaj S. on 25-Sep-2013
            p_migr_err_code := 'MIG-1_054';
            p_migr_err_desc := 'PROD_CODE_NOTFOUND_APPL';
            RETURN;
         WHEN OTHERS
         THEN
            p_errmsg :=
                  'Error while getting product category while creating application entry : '
               || SUBSTR (SQLERRM, 1, 100);
            p_migr_err_code := 'MIG-1_';
            p_migr_err_desc := 'OTHER_THAN_PRDEFINE_EXCP';
            RETURN;
      END;

      v_cpc_catg_appl := LPAD (v_cpc_catg_appl, 2, 0);
      v_appl_ctrlcode := p_instcode;

      BEGIN
         BEGIN
            SELECT mct_ctrl_numb
              INTO v_appl_code
              FROM migr_ctrl_table
             WHERE mct_ctrl_code = v_appl_ctrlcode
               AND mct_ctrl_key = 'APPLCODE'
               AND mct_inst_code = p_instcode;
         EXCEPTION
            WHEN NO_DATA_FOUND
            THEN
               --v_appl_code := 1;
               SELECT seq_appl_code.NEXTVAL
                 INTO v_appl_code
                 FROM DUAL;

               INSERT INTO migr_ctrl_table
                           (mct_ctrl_code, mct_ctrl_key, mct_ctrl_numb,
                            mct_ctrl_desc,
                            mct_ins_user, mct_ins_date, mct_lupd_user,
                            mct_lupd_date, mct_inst_code
                           )
                    VALUES (p_instcode, 'APPLCODE', v_appl_code,
                               'Latest Application Code for Institution '
                            || p_instcode,
                            p_lupduser, SYSDATE, p_lupduser,
                            SYSDATE, p_instcode
                           );
            WHEN OTHERS
            THEN
               p_errmsg :=
                     'Error while creating application code : '
                  || SUBSTR (SQLERRM, 1, 100);
               p_migr_err_code := 'MIG-1_';
               p_migr_err_desc := 'OTHER_THAN_PRDEFINE_EXCP';
               RETURN;
         END;

         IF p_addonstat = 'P' AND p_addonlink = 0
         THEN
            SELECT    TO_CHAR (SYSDATE, 'yyyy')
                   || v_cpc_catg_appl
                   || LPAD (v_appl_code, 8, 0)
              INTO p_applcode
              FROM DUAL;

            truep_addonlink := p_applcode;
         ELSIF p_addonstat IN ('A', 'B') AND p_addonlink IS NOT NULL
         THEN                                                           --IF 2
            SELECT    TO_CHAR (SYSDATE, 'yyyy')
                   || v_cpc_catg_appl
                   || LPAD (v_appl_code, 8, 0)
              INTO p_applcode
              FROM DUAL;

            truep_addonlink := p_addonlink;
         END IF;                                                 --End of IF 2
      EXCEPTION
         WHEN OTHERS
         THEN
            p_errmsg :=
                  'Error while creating application code : '
               || SUBSTR (SQLERRM, 1, 100);
            p_migr_err_code := 'MIG-1_';
            p_migr_err_desc := 'OTHER_THAN_PRDEFINE_EXCP';
            RETURN;
      END;

      v_cam_bill_addr := p_billaddr;
      v_appl_stat := 'A';

-- INSERT CHANGED BY GANESH.
      BEGIN
         INSERT INTO cms_appl_mast
                     (cam_inst_code, cam_asso_code, cam_inst_type,
                      cam_appl_code, cam_appl_no, cam_appl_date,
                      cam_reg_date, cam_cust_code, cam_appl_bran,
                      cam_prod_code, cam_card_type, cam_cust_catg,
                      cam_active_date, cam_expry_date, cam_disp_name,
                      cam_limit_amt, cam_use_limit, cam_addon_issu,
                      cam_tot_acct, cam_addon_stat, cam_addon_link,
                      cam_bill_addr, cam_chnl_code, cam_request_id,
                      cam_payment_ref, cam_appl_stat, cam_appl_user,
                      cam_initial_topup_amount, cam_lupd_user, cam_ins_date,
                      cam_ins_user, cam_starter_card
                     )
              VALUES (p_instcode, p_assocode, p_insttype,
                      p_applcode, p_applno, p_appldate,
                      p_regdate, p_custcode, p_applbran,
                      p_prodcode, p_cardtype, p_custcatg,
                      p_activedate, p_exprydate, p_dispname,
                      p_limtamt, p_usagelimt, p_addonissu,
                      p_totacct, p_addonstat, truep_addonlink,
                      v_cam_bill_addr, p_chnlcode, p_request_id,
                      p_payment_ref, v_appl_stat, p_appluser,
                      p_initial_topup_amount, p_lupduser, SYSDATE,
                      p_lupduser, p_starter_crd_flag
                     );

         DBMS_OUTPUT.put_line ('After appl insert');
      EXCEPTION
         WHEN OTHERS
         THEN
            p_errmsg :=
                  'Error While Inserting Application in Master '
               || SUBSTR (SQLERRM, 1, 100);
            p_migr_err_code := 'MIG-1_055';
            p_migr_err_desc := 'APPL_INS-ERR';
      END;

      BEGIN
         UPDATE migr_ctrl_table
            SET mct_ctrl_numb = mct_ctrl_numb + 1
          WHERE mct_ctrl_code = v_appl_ctrlcode
            AND mct_ctrl_key = 'APPLCODE'
            AND mct_inst_code = p_instcode;

         IF SQL%ROWCOUNT = 0
         THEN
            p_errmsg := 'Control table not updated for application code ';
            p_migr_err_code := 'MIG-1_076';
            p_migr_err_desc := 'APPL_CTRL_UPDT_ERR';
            RETURN;
         END IF;
      EXCEPTION
         WHEN OTHERS
         THEN
            p_errmsg :=
                  'Error while updating control table for the application code : '
               || SUBSTR (SQLERRM, 1, 200);
            p_migr_err_code := 'MIG-1_';
            p_migr_err_desc := 'OTHER_THAN_PRDEFINE_EXCP';
            RETURN;
      END;
   EXCEPTION                                            --Main block Exception
      WHEN OTHERS
      THEN
         p_errmsg :=
               'Main Exception While Creating Application Entry '
            || SUBSTR (SQLERRM, 1, 100);
         p_migr_err_code := 'MIG-1_';
         p_migr_err_desc := 'OTHER_THAN_PRDEFINE_EXCP';
   END;                                           --Main Begin Block Ends Here

   PROCEDURE migr_create_appldet_pkg (
      p_instcode        IN       NUMBER,
      p_applcode        IN       NUMBER,
      p_acctid          IN       NUMBER,
      p_acctv_posn      IN       NUMBER,
      p_lupduser        IN       NUMBER,
      p_migr_err_code   OUT      VARCHAR2,
      p_migr_err_desc   OUT      VARCHAR2,
      p_errmsg          OUT      VARCHAR2
   )
   IS
      v_dum              NUMBER (3);
      v_posn             NUMBER (3);
      v_cam_addon_link   NUMBER (14);
      v_cam_addon_stat   CHAR (1);
      v_appl_count       NUMBER (3)  := 0;

      CURSOR c1 (c1_p_applcode IN NUMBER, c1_p_instcode IN NUMBER)
      IS
         SELECT cad_acct_id, cad_acct_posn
           FROM cms_appl_det
          WHERE cad_inst_code = c1_p_instcode
            AND cad_appl_code = c1_p_applcode
            AND cad_acct_posn != 1;
   BEGIN                                        --Main Begin Block Starts Here
      IF     p_applcode IS NOT NULL
         AND p_acctid IS NOT NULL
         AND p_acctv_posn IS NOT NULL
         AND p_lupduser IS NOT NULL
      THEN
         p_errmsg := 'OK';

         IF p_acctv_posn != 1
         THEN
            BEGIN
               SELECT NVL (MAX (cad_acct_posn), 0) + 1
                 INTO v_dum
                 FROM cms_appl_det
                WHERE cad_inst_code = p_instcode
                      AND cad_appl_code = p_applcode;

               v_posn := v_dum;
               p_errmsg := 'OK';
            EXCEPTION
               WHEN OTHERS
               THEN
                  p_errmsg :=
                        'Error While getting account position '
                     || SUBSTR (SQLERRM, 1, 200);
                  p_migr_err_code := 'MIG-1_';
                  p_migr_err_desc := 'OTHER_THAN_PRDEFINE_EXCP';
                  RETURN;                                   -- added by ganesh
            END;
         END IF;

         IF p_errmsg = 'OK'
         THEN
            v_posn := p_acctv_posn;

            BEGIN
               INSERT INTO cms_appl_det
                           (cad_appl_code, cad_acct_id, cad_acct_posn,
                            cad_ins_user, cad_lupd_user, cad_inst_code
                           )
                    VALUES (p_applcode, p_acctid, v_posn,
                            p_lupduser, p_lupduser, p_instcode
                           );

               p_errmsg := 'OK';
            EXCEPTION                                       -- added by ganesh
               WHEN OTHERS
               THEN
                  p_errmsg :=
                        'Error while inserting in the pan acct relation table  : '
                     || SUBSTR (SQLERRM, 1, 200);
                  p_migr_err_code := 'MIG-1_056';
                  p_migr_err_desc := 'APPL_DET_INS_ERR';
                  RETURN;
            END;
         END IF;
      ELSE
         p_errmsg := 'create_appldet expected a not null parameter';
         p_migr_err_code := 'MIG-1_';
         p_migr_err_desc := 'OTHER_THAN_PRDEFINE_EXCP';
      END IF;

      BEGIN
         SELECT cam_addon_link, cam_addon_stat
           INTO v_cam_addon_link, v_cam_addon_stat
           FROM cms_appl_mast
          WHERE cam_inst_code = p_instcode AND cam_appl_code = p_applcode;

         IF v_cam_addon_stat = 'A'
         THEN
            FOR x IN c1 (v_cam_addon_link, p_instcode)
            LOOP
               BEGIN
                  INSERT INTO cms_appl_det
                              (cad_appl_code, cad_acct_id, cad_acct_posn,
                               cad_ins_user, cad_lupd_user, cad_inst_code
                              )
                       VALUES (p_applcode, x.cad_acct_id, x.cad_acct_posn,
                               p_lupduser, p_lupduser, p_instcode
                              );
               EXCEPTION
                  WHEN OTHERS
                  THEN
                     p_errmsg :=
                           'Error while inserting in the pan acct relation table Addon : '
                        || SUBSTR (SQLERRM, 1, 200);
                     p_migr_err_code := 'MIG-1_57';
                     p_migr_err_desc := 'APPL_DET_ADDON_INS_ERR';
                     RETURN;
               END;
            --EXIT WHEN c1%NOTFOUND; No Need - Ganesh.
            END LOOP;
         END IF;
      EXCEPTION
         WHEN NO_DATA_FOUND
         THEN                                               -- added by ganesh
            p_errmsg :=
                  'Application code not found in the application master :'
               || p_applcode;
            p_migr_err_code := 'MIG-1_058';
            p_migr_err_desc := 'APPLCODE_NOT_FOUND_DET';
            RETURN;
         WHEN OTHERS
         THEN
            p_errmsg := 'Exception 2 ' || SUBSTR (SQLERRM, 1, 200);
            p_migr_err_code := 'MIG-1_';
            p_migr_err_desc := 'OTHER_THAN_PRDEFINE_EXCP';
            RETURN;                                        -- added by ganesh
      END;
   EXCEPTION
      WHEN OTHERS
      THEN
         p_errmsg :=
               'Main Exception While Creating Entry In Appldet'
            || SUBSTR (SQLERRM, 1, 200);
         p_migr_err_code := 'MIG-1_';
         p_migr_err_desc := 'OTHER_THAN_PRDEFINE_EXCP';
   END;

   PROCEDURE migr_gen_pan_prepaid_cms_pkg (
      p_instcode                 IN       NUMBER,
      p_applcode                 IN       NUMBER,
      p_card_no                  IN       VARCHAR2,
      p_card_stat                IN       VARCHAR2,
      p_pangen_date              IN       DATE,
      p_online_atm_limit         IN       NUMBER,
      p_offline_atm_limit        IN       NUMBER,
      p_online_pos_limit         IN       NUMBER,
      p_offline_pos_limit        IN       NUMBER,
      p_online_aggr_limit        IN       NUMBER,
      p_offline_aggr_limit       IN       NUMBER,
      p_online_mmpos_limit       IN       NUMBER,
      p_offline_mmpos_limit      IN       NUMBER,
      p_pin_offset               IN       VARCHAR2,
      p_pin_gen_date_time        IN       DATE,
      p_pin_gen_flag             IN       VARCHAR2,
      p_emboss_gen_date_time     IN       DATE,
      p_emboss_gen_flag          IN       VARCHAR2,
      p_next_billing_date        IN       DATE,
      p_next_monthly_bill_date   IN       DATE,
      p_ccf_file_name            IN       VARCHAR2,
      p_serial_number            IN       NUMBER,
      p_proxy_number             IN       VARCHAR2,  --NUMBER, --MOdified by Pankaj S. on 20_Sep_2013
      p_starter_card_flag        IN       VARCHAR2,
      p_initial_load_flag        IN       VARCHAR2,
      p_sms_flag                 IN       VARCHAR2,
      p_email_flag               IN       VARCHAR2,
      p_pin_offst                IN       VARCHAR2,
      p_lupduser                 IN       NUMBER,
      p_mer_id                   IN       NUMBER,
      p_locn_id                  IN       VARCHAR2,--Dhiraj GAikwad Modified from NUMBER to VARCHAR2
      p_ordr_rfrno               OUT      VARCHAR2,
      p_migr_err_code            OUT      VARCHAR2,
      p_migr_err_desc            OUT      VARCHAR2,
      p_errmsg                   OUT      VARCHAR2
   )
   IS
      -- INPUT PARAMETERS CHANGED FOR MIGRATION BY GANESH
      v_inst_code              cms_appl_mast.cam_inst_code%TYPE;
      v_asso_code              cms_appl_mast.cam_asso_code%TYPE;
      v_inst_type              cms_appl_mast.cam_inst_type%TYPE;
      v_prod_code              cms_appl_mast.cam_prod_code%TYPE;
      v_appl_bran              cms_appl_mast.cam_appl_bran%TYPE;
      v_cust_code              cms_appl_mast.cam_cust_code%TYPE;
      v_card_type              cms_appl_mast.cam_card_type%TYPE;
      v_cust_catg              cms_appl_mast.cam_cust_catg%TYPE;
      v_disp_name              cms_appl_mast.cam_disp_name%TYPE;
      v_active_date            cms_appl_mast.cam_active_date%TYPE;
      v_expry_date             cms_appl_mast.cam_expry_date%TYPE;
      v_expiry_date            DATE;
      v_addon_stat             cms_appl_mast.cam_addon_stat%TYPE;
      v_tot_acct               cms_appl_mast.cam_tot_acct%TYPE;
      v_chnl_code              cms_appl_mast.cam_chnl_code%TYPE;
      v_limit_amt              cms_appl_mast.cam_limit_amt%TYPE;
      v_use_limit              cms_appl_mast.cam_use_limit%TYPE;
      v_bill_addr              cms_appl_mast.cam_bill_addr%TYPE;
      v_request_id             cms_appl_mast.cam_request_id%TYPE;
      v_appl_stat              cms_appl_mast.cam_appl_stat%TYPE;
      v_starter_card           cms_appl_mast.cam_starter_card%TYPE;
      v_bin                    cms_bin_mast.cbm_inst_bin%TYPE;
      v_profile_code           cms_prod_cattype.cpc_profile_code%TYPE;
      v_errmsg                 VARCHAR2 (500);
      v_hsm_mode               cms_inst_param.cip_param_value%TYPE;
      v_pingen_flag            VARCHAR2 (1);
      v_emboss_flag            VARCHAR2 (1);
      v_loop_cnt               NUMBER                               DEFAULT 0;
      v_loop_max_cnt           NUMBER;
      v_tmp_pan                cms_appl_pan.cap_pan_code%TYPE;
      v_noof_pan_param         NUMBER;
      v_inst_bin               cms_prod_bin.cpb_inst_bin%TYPE;
      v_serial_index           NUMBER;
      v_serial_maxlength       NUMBER (2);
      v_serial_no              NUMBER;
      v_check_digit            NUMBER;
      v_pan                    cms_appl_pan.cap_pan_code%TYPE;
      v_acct_id                cms_acct_mast.cam_acct_id%TYPE;
      v_acct_num               cms_acct_mast.cam_acct_no%TYPE;
      v_adonlink               cms_appl_pan.cap_pan_code%TYPE;
      v_mbrlink                cms_appl_pan.cap_mbr_numb%TYPE;
      v_cam_addon_link         cms_appl_mast.cam_addon_link%TYPE;
      v_prod_prefix            cms_prod_cattype.cpc_prod_prefix%TYPE;
      v_card_stat              cms_appl_pan.cap_card_stat%TYPE;
      v_offline_atm_limit      cms_appl_pan.cap_atm_offline_limit%TYPE;
      v_online_atm_limit       cms_appl_pan.cap_atm_online_limit%TYPE;
      v_online_pos_limit       cms_appl_pan.cap_pos_online_limit%TYPE;
      v_offline_pos_limit      cms_appl_pan.cap_pos_offline_limit%TYPE;
      v_offline_aggr_limit     cms_appl_pan.cap_offline_aggr_limit%TYPE;
      v_online_aggr_limit      cms_appl_pan.cap_online_aggr_limit%TYPE;
      v_cpm_catg_code          cms_prod_mast.cpm_catg_code%TYPE;
      v_issueflag              VARCHAR2 (1);
      v_initial_topup_amount   cms_appl_mast.cam_initial_topup_amount%TYPE;
      v_func_code              cms_func_mast.cfm_func_code%TYPE;
      v_func_desc              cms_func_mast.cfm_func_desc%TYPE;
      v_cr_gl_code             cms_func_prod.cfp_crgl_code%TYPE;
      v_crgl_catg              cms_func_prod.cfp_crgl_catg%TYPE;
      v_crsubgl_code           cms_func_prod.cfp_crsubgl_code%TYPE;
      v_cracct_no              cms_func_prod.cfp_cracct_no%TYPE;
      v_dr_gl_code             cms_func_prod.cfp_drgl_code%TYPE;
      v_drgl_catg              cms_func_prod.cfp_drgl_catg%TYPE;
      v_drsubgl_code           cms_func_prod.cfp_drsubgl_code%TYPE;
      v_dracct_no              cms_func_prod.cfp_dracct_no%TYPE;
      v_gl_check               NUMBER (1);
      v_subgl_desc             VARCHAR2 (30);
      v_tran_code              cms_func_mast.cfm_txn_code%TYPE;
      v_tran_mode              cms_func_mast.cfm_txn_mode%TYPE;
      v_delv_chnl              cms_func_mast.cfm_delivery_channel%TYPE;
      v_tran_type              cms_func_mast.cfm_txn_type%TYPE;
      v_expryparam             cms_bin_param.cbp_param_value%TYPE;
      v_validity_period        cms_bin_param.cbp_param_value%TYPE;
      v_savepoint              NUMBER                               DEFAULT 1;
      v_emp_id                 cms_cust_mast.ccm_emp_id%TYPE;
      v_corp_code              cms_cust_mast.ccm_corp_code%TYPE;
      v_appl_data              type_appl_rec_array;
      v_mbrnumb                cms_appl_pan.cap_mbr_numb%TYPE;
      v_proxy_number           cms_appl_pan.cap_proxy_number%TYPE;
      v_online_mmpos_limit     cms_appl_pan.cap_mmpos_online_limit%TYPE;
      v_offline_mmpos_limit    cms_appl_pan.cap_mmpos_offline_limit%TYPE;
      v_hash_pan               cms_appl_pan.cap_pan_code%TYPE;
      v_encr_pan               cms_appl_pan.cap_pan_code_encr%TYPE;
      v_getseqno               VARCHAR2 (200);
      v_programid              VARCHAR2 (4);
      v_seqno                  cms_program_id_cnt.cpi_sequence_no%TYPE;
      v_proxylength            cms_prod_mast.cpm_proxy_length%TYPE;
      exp_reject_record_pan    EXCEPTION;
      v_fee_calc               CHAR (1);
      --Sn added by Pankaj S. on 31-May-2013 for SSn check
      v_ssn                    cms_cust_mast.ccm_ssn%TYPE;
      v_check_status           NUMBER (3);
      v_loadcredit_flag        cms_prodcatg_smsemail_alerts.cps_loadcredit_flag%TYPE;
      v_lowbal_flag            cms_prodcatg_smsemail_alerts.cps_lowbal_flag%TYPE;
      v_negativebal_flag       cms_prodcatg_smsemail_alerts.cps_negativebal_flag%TYPE;
      v_highauthamt_flag       cms_prodcatg_smsemail_alerts.cps_highauthamt_flag%TYPE;
      v_dailybal_flag          cms_prodcatg_smsemail_alerts.cps_dailybal_flag%TYPE;
      v_insuffund_flag         cms_prodcatg_smsemail_alerts.cps_insuffund_flag%TYPE;
      v_incorrectpin_flag      cms_prodcatg_smsemail_alerts.cps_incorrectpin_flag%TYPE;
      --SN Dhiraj Gaikwad
      V_CPS_CARDTOCARD_TRANS_FLAG CMS_PRODCATG_SMSEMAIL_ALERTS.CPS_CARDTOCARD_TRANS_FLAG%type;
      V_CPS_FAST50_FLAG CMS_PRODCATG_SMSEMAIL_ALERTS.CPS_FAST50_FLAG%type;
      V_CPS_FEDTAX_REFUND_FLAG CMS_PRODCATG_SMSEMAIL_ALERTS.CPS_FEDTAX_REFUND_FLAG%type;
      V_CPS_MOBUPDATE_FLAG  CMS_PRODCATG_SMSEMAIL_ALERTS.CPS_MOBUPDATE_FLAG%type;

        V_C2C_alert            NUMBER(1) ;
        V_FAST50_alert         NUMBER(1) ;
        V_FEDTAX_REFUND_alert  NUMBER(1) ;
        V_MOBUPDATE_alert       NUMBER(1) ;

      --EN Dhiraj Gaikwad
      v_loadcredit_alert       NUMBER (1);
      v_lowbal_alert           NUMBER (1);
      v_negativebal_alert      NUMBER (1);
      v_highauthamt_alert      NUMBER (1);
      v_dailybal_alert         NUMBER (1);
      v_insuffund_alert        NUMBER (1);
      v_incorrectpin_alert     NUMBER (1);
      --En added by Pankaj S. on 31-May-2013 for SSn check
      v_merinv_prod_catg       cms_merinv_prodcat.cmp_merprodcat_id%TYPE
                                                                      := NULL;
      v_mer_inv_ordr           cms_merinv_ordr.cmo_ordr_refrno%TYPE   := NULL;
      v_ins_date               DATE;

      CURSOR c (p_profile_code IN VARCHAR2)
      IS
         SELECT   cpc_profile_code, cpc_field_name, cpc_start_from,
                  cpc_length, cpc_start
             FROM cms_pan_construct
            WHERE cpc_profile_code = p_profile_code
              AND cpc_inst_code = p_instcode
         ORDER BY cpc_start_from DESC;

      CURSOR c1 (appl_code IN NUMBER)
      IS
         SELECT cad_acct_id, cad_acct_posn
           FROM cms_appl_det
          WHERE cad_appl_code = p_applcode AND cad_inst_code = p_instcode;
   BEGIN
      --<< MAIN BEGIN >>
      p_errmsg := 'OK';

      --Sn fetch all details from appl_mast
      BEGIN
         --Begin 1 Block Starts Here
         SELECT cam_inst_code, cam_asso_code, cam_inst_type, cam_prod_code,
                cam_appl_bran, cam_cust_code, cam_card_type, cam_cust_catg,
                cam_disp_name, cam_active_date, cam_expry_date,
                cam_addon_stat, cam_tot_acct, cam_chnl_code, cam_limit_amt,
                cam_use_limit, cam_bill_addr, cam_request_id, cam_appl_stat,
                cam_initial_topup_amount,
                type_appl_rec_array (cam_appl_param1,
                                     cam_appl_param2,
                                     cam_appl_param3,
                                     cam_appl_param4,
                                     cam_appl_param5,
                                     cam_appl_param6,
                                     cam_appl_param7,
                                     cam_appl_param8,
                                     cam_appl_param9,
                                     cam_appl_param10
                                    ),
                cam_starter_card
           INTO v_inst_code, v_asso_code, v_inst_type, v_prod_code,
                v_appl_bran, v_cust_code, v_card_type, v_cust_catg,
                v_disp_name, v_active_date, v_expry_date,
                v_addon_stat, v_tot_acct, v_chnl_code, v_limit_amt,
                v_use_limit, v_bill_addr, v_request_id, v_appl_stat,
                v_initial_topup_amount,
                v_appl_data,
                v_starter_card
           FROM cms_appl_mast
          WHERE cam_inst_code = p_instcode
            AND cam_appl_code = p_applcode
            AND cam_appl_stat = 'A';
      EXCEPTION
         --Exception of Begin 1 Block
         WHEN NO_DATA_FOUND
         THEN
            v_errmsg := 'No row found for application code' || p_applcode;
            p_migr_err_code := 'MIG-1_061';
            p_migr_err_desc := 'APPLCODE_NOT_FOUND_PAN';
            RAISE exp_reject_record_pan;
         WHEN OTHERS
         THEN
            v_errmsg :=
                  'Error while selecting applcode from applmast'
               || SUBSTR (SQLERRM, 1, 200);
            p_migr_err_code := 'MIG-1_';
            p_migr_err_desc := 'OTHER_THAN_PRDEFINE_EXCP';
            RAISE exp_reject_record_pan;
      END;

      --En fetch all details from  appl_mast

      --  --Sn find profile code attached to cardtype
      BEGIN
         SELECT cpm_profile_code, cpm_catg_code, cpc_prod_prefix,
                cpm_program_id,                 --T.Narayanan added for prg id
                               cpm_proxy_length
-- ADDED by sagar on 29-mar-2012 to decide length of proxy number to be generated
         INTO   v_profile_code, v_cpm_catg_code, v_prod_prefix,
                v_programid,                    --T.Narayanan added for prg id
                            v_proxylength
-- ADDED by sagar on 29-mar-2012 to decide length of proxy number to be generated
         FROM   cms_prod_cattype, cms_prod_mast
          WHERE cpc_inst_code = p_instcode
            AND cpc_inst_code = cpm_inst_code
            AND cpc_prod_code = v_prod_code
            AND cpc_card_type = v_card_type
            AND cpm_prod_code = cpc_prod_code;
      EXCEPTION
         WHEN NO_DATA_FOUND
         THEN
            v_errmsg :=
                  'Profile code not defined for product code '
               || v_prod_code
               || 'card type '
               || v_card_type;
            RAISE exp_reject_record_pan;
         WHEN OTHERS
         THEN
            v_errmsg :=
                  'Error while selecting applcode from applmast'
               || SUBSTR (SQLERRM, 1, 300);
            RAISE exp_reject_record_pan;
      END;

      BEGIN
         v_hash_pan := gethash (p_card_no);
      EXCEPTION
         WHEN OTHERS
         THEN
            v_errmsg :=
                    'Error while converting(hash) pan ' || SUBSTR (SQLERRM, 1, 200);
            p_migr_err_code := 'MIG-1_061';
            p_migr_err_desc := 'EXCP_PAN_HASHCONV';
            RAISE exp_reject_record_pan;
      END;

      --EN CREATE HASH PAN

      --SN create encr pan
      BEGIN
         v_encr_pan := fn_emaps_main (p_card_no);
      EXCEPTION
         WHEN OTHERS
         THEN
            v_errmsg :=
                    'Error while converting(encr) pan ' || SUBSTR (SQLERRM, 1, 200);
            p_migr_err_code := 'MIG-1_062';
            p_migr_err_desc := 'EXCP_PAN_ENCRYPT';
            RAISE exp_reject_record_pan;
      END;

--  --EN create encr pan

      -- Sn find primary acct no for the pan
      BEGIN
         /* SELECT cam_acct_id, cam_acct_no
            INTO v_acct_id, v_acct_num
            FROM cms_acct_mast
           WHERE cam_inst_code = p_instcode
             AND cam_acct_id =
                    (SELECT cad_acct_id
                       FROM cms_appl_det
                      WHERE cad_inst_code = p_instcode
                        AND cad_appl_code = p_applcode
                        AND cad_acct_posn = 1); */
        /*
         SELECT cam_acct_id, cam_acct_no
           INTO v_acct_id, v_acct_num
           FROM cms_acct_mast
          WHERE cam_inst_code = p_instcode
            AND EXISTS (
                   SELECT 1
                     FROM cms_appl_det
                    WHERE cad_inst_code = p_instcode
                      AND cad_appl_code = p_applcode
                      AND cad_acct_posn = 1
                      AND cam_acct_id = cad_acct_id);
          */

          --SN :Added for PT on 10-Oct-2013

          SELECT cam_acct_id, cam_acct_no INTO v_acct_id, v_acct_num
          FROM cms_acct_mast,cms_appl_det
          WHERE cad_inst_code = p_instcode
              AND cad_appl_code = p_applcode
              and  cad_inst_code = cam_inst_code
              AND  cam_acct_id = cad_acct_id
              AND cad_acct_posn = 1;

          --EN :Added for PT on 10-Oct-2013

      EXCEPTION
         WHEN NO_DATA_FOUND
         THEN
            v_errmsg :=
                   'No account primary  defined for appl code ' || p_applcode;
            p_migr_err_code := 'MIG-1_063';
            p_migr_err_desc := 'PRIM_ACCT_NOT_DEF';
            RAISE exp_reject_record_pan;
         WHEN OTHERS
         THEN
            v_errmsg :=
                  'Error while selecting acct detail for pan '
               || SUBSTR (SQLERRM, 1, 200);
            p_migr_err_code := 'MIG-1_';
            p_migr_err_desc := 'OTHER_THAN_PRDEFINE_EXCP';
            RAISE exp_reject_record_pan;
      END;

      --En find primary acct no for the pan

      --Sn entry for addon stat
      IF v_addon_stat = 'A'
      THEN
         BEGIN
            --begin 1.1
            SELECT cam_addon_link
              INTO v_cam_addon_link
              FROM cms_appl_mast
             WHERE cam_inst_code = p_instcode AND cam_appl_code = p_applcode;

            SELECT cap_pan_code, cap_mbr_numb
              INTO v_adonlink, v_mbrlink
              FROM cms_appl_pan
             WHERE cap_inst_code = p_instcode
               AND cap_appl_code = v_cam_addon_link;
         EXCEPTION
            --excp 1.1
            WHEN NO_DATA_FOUND
            THEN
               v_errmsg := 'Parent PAN not generated for ' || p_applcode;
               p_migr_err_code := 'MIG-1_064';
               p_migr_err_desc := 'PARENT_PAN_NOT_GEN';
               RAISE exp_reject_record_pan;
            WHEN OTHERS
            THEN
               v_errmsg :=
                     'Excp While Getting Addon Link -- '
                  || SUBSTR (SQLERRM, 1, 200);
               p_migr_err_code := 'MIG-1_';
               p_migr_err_desc := 'OTHER_THAN_PRDEFINE_EXCP';
               RAISE exp_reject_record_pan;
         END;                                               --end of begin 1.1
      ELSIF v_addon_stat = 'P'
      THEN
         --v_adonlink    :=    v_pan;
         v_adonlink := v_hash_pan;
         v_mbrlink := '000';
      END IF;

      --msiva en added for Expiry date calculate
      IF v_request_id IS NOT NULL
      THEN
         v_issueflag := 'N';
      ELSE
         v_issueflag := 'Y';
      END IF;

      BEGIN
         SELECT ccm_emp_id, ccm_corp_code,
                ccm_ssn            --ccm_ssn added by Pankaj S. on 31-May-2013
           INTO v_emp_id, v_corp_code,
                v_ssn                --v_ssn added by Pankaj S. on 31-May-2013
           FROM cms_cust_mast
          WHERE ccm_inst_code = p_instcode AND ccm_cust_code = v_cust_code;
      EXCEPTION
         WHEN NO_DATA_FOUND
         THEN
            v_errmsg := 'Customer not found in master';
            p_migr_err_code := 'MIG-1_065';
            p_migr_err_desc := 'CUST_NOT_FOUND';
            RAISE exp_reject_record_pan;
         WHEN OTHERS
         THEN
            v_errmsg :=
                  'Error while selecting customer from master'
               || SUBSTR (SQLERRM, 1, 200);
            p_migr_err_code := 'MIG-1_';
            p_migr_err_desc := 'OTHER_THAN_PRDEFINE_EXCP';
            RAISE exp_reject_record_pan;
      END;

      --Sn get member number from master
      BEGIN
         SELECT cip_param_value
           INTO v_mbrnumb
           FROM cms_inst_param
          WHERE cip_inst_code = p_instcode AND cip_param_key = 'MBR_NUMB';
      EXCEPTION
         WHEN NO_DATA_FOUND
         THEN
            v_errmsg := 'memeber number not defined in master';
            p_migr_err_code := 'MIG-1_066';
            p_migr_err_desc := 'MEMBR_NUMB_NOT_DEFINED';
            RAISE exp_reject_record_pan;
         WHEN OTHERS
         THEN
            v_errmsg :=
                  'Error while selecting memeber number '
               || SUBSTR (SQLERRM, 1, 200);
            p_migr_err_code := 'MIG-1_';
            p_migr_err_desc := 'OTHER_THAN_PRDEFINE_EXCP';
            RAISE exp_reject_record_pan;
      END;

      --Sn create a record in appl_pan
      IF p_next_billing_date IS NOT NULL
      THEN
         v_fee_calc := 'Y';
      ELSIF p_next_billing_date IS NULL
      THEN
         v_fee_calc := 'N';
      END IF;

     /* --Sn Added by Pankaj S. for SSN check
      SELECT COUNT (1)
        INTO v_check_status
        FROM cms_ssn_cardstat
       WHERE csc_inst_code = p_instcode -- Added on 16-sep-2013
       and   csc_card_stat = p_card_stat AND csc_stat_flag = 'Y';

      IF v_check_status <> 0
      THEN
         sp_check_ssn_threshold (p_instcode, v_ssn, v_prod_code, v_errmsg);

         IF v_errmsg <> 'OK'
         THEN
            p_migr_err_code := 'MIG-1_067';
            p_migr_err_desc := 'SSN CHECK FAILS';
            RAISE exp_reject_record_pan;
         END IF;
      END IF;
     */ 

      v_ins_date := SYSDATE;

      --En Added by Pankaj S. for SSN check
      BEGIN
         INSERT INTO cms_appl_pan
                     (cap_appl_code, cap_inst_code, cap_asso_code,
                      cap_inst_type, cap_prod_code, cap_prod_catg,
                      cap_card_type, cap_cust_catg, cap_pan_code,
                      cap_mbr_numb, cap_card_stat, cap_cust_code,
                      cap_disp_name, cap_limit_amt, cap_use_limit,
                      cap_appl_bran, cap_active_date, cap_expry_date,
                      cap_addon_stat, cap_addon_link, cap_mbr_link,
                      cap_acct_id, cap_acct_no, cap_tot_acct, cap_bill_addr,
                      cap_chnl_code, cap_pangen_date, cap_pangen_user,
                      cap_cafgen_flag, cap_pin_flag, cap_embos_flag,
                      cap_phy_embos, cap_join_feecalc, cap_next_bill_date,
                      cap_next_mb_date, cap_request_id, cap_issue_flag,
                      cap_ins_user, cap_lupd_user, cap_atm_offline_limit,
                      cap_atm_online_limit, cap_pos_offline_limit,
                      cap_pos_online_limit, cap_offline_aggr_limit,
                      cap_online_aggr_limit, cap_emp_id,
                      cap_firsttime_topup, cap_panmast_param1,
                      cap_panmast_param2, cap_panmast_param3,
                      cap_panmast_param4, cap_panmast_param5,
                      cap_panmast_param6, cap_panmast_param7,
                      cap_panmast_param8, cap_panmast_param9,
                      cap_panmast_param10, cap_pan_code_encr,
                      cap_proxy_number, cap_mmpos_online_limit,
                      cap_mmpos_offline_limit, cap_startercard_flag,
                      cap_serial_number, cap_emb_fname, cap_fee_calc,
                      cap_pin_off, cap_pingen_date,
                      cap_embos_date,
                      cap_mask_pan        --added by Pankaj S. on 11_June_2013
                                  ,
                      cap_prfl_code                    -- Added on 18-JUN-2013
                                   , cap_ins_date
                     )
              VALUES (p_applcode, p_instcode, v_asso_code,
                      v_inst_type, v_prod_code, v_cpm_catg_code,
                      v_card_type, v_cust_catg, v_hash_pan,
                      v_mbrnumb, p_card_stat, v_cust_code,
                      v_disp_name, v_limit_amt, v_use_limit,
                      v_appl_bran, v_active_date, v_expry_date,
                      v_addon_stat, v_adonlink, v_mbrlink,
                      v_acct_id, v_acct_num, v_tot_acct, v_bill_addr,
                      v_chnl_code, p_pangen_date, p_lupduser,
                      'Y', p_pin_gen_flag, p_emboss_gen_flag,
                      'N', 'N', p_next_billing_date,
                      p_next_monthly_bill_date, v_request_id, v_issueflag,
                      p_lupduser, p_lupduser, p_offline_atm_limit,
                      p_online_atm_limit, p_offline_pos_limit,
                      p_online_pos_limit, p_offline_aggr_limit,
                      p_online_aggr_limit, v_emp_id,
                      p_initial_load_flag, v_appl_data (1),
                      v_appl_data (2), v_appl_data (3),
                      v_appl_data (4), v_appl_data (5),
                      v_appl_data (6), v_appl_data (7),
                      v_appl_data (8), v_appl_data (9),
                      v_appl_data (10), v_encr_pan,
                      p_proxy_number, p_online_mmpos_limit,
                      p_offline_mmpos_limit, p_starter_card_flag,
                      p_serial_number, p_ccf_file_name, v_fee_calc,
                      p_pin_offst, p_pin_gen_date_time,
                      p_emboss_gen_date_time,
                      fn_mask (p_card_no, 'X', 7, 6)
                                                    --added by Pankaj S. on 11_June_2013
         ,
                      v_profile_code                   -- Added on 18-JUN-2013
                                    , v_ins_date
                     );
      EXCEPTION
         WHEN DUP_VAL_ON_INDEX
         THEN
            v_errmsg :=
               'Pan ' || p_card_no || ' is already present in the Pan_master';
            p_migr_err_code := 'MIG-1_067';
            p_migr_err_desc := 'PAN_ALREADY_EXISTS';
            RAISE exp_reject_record_pan;
         WHEN OTHERS
         THEN
            v_errmsg :=
                  'Error while inserting records into pan master '
               || SUBSTR (SQLERRM, 1, 200);
            p_migr_err_code := 'MIG-1_';
            p_migr_err_desc := 'OTHER_THAN_PRDEFINE_EXCP';
            RAISE exp_reject_record_pan;
      END;

     --Sn commented by Pankaj S. since we are not disable triggers
     /* BEGIN
         INSERT INTO cms_translimit_check
                     (ctc_pan_code, ctc_inst_code, ctc_atm_offline_limit,
                      ctc_atm_online_limit, ctc_pos_offline_limit,
                      ctc_pos_online_limit, ctc_offline_aggr_limit,
                      ctc_online_aggr_limit, ctc_atmusage_amt,
                      ctc_posusage_amt, ctc_mbr_numb, ctc_lupd_date,
                      ctc_ins_date, ctc_atmusage_limit, ctc_posusage_limit,
                      ctc_business_date,
                      ctc_pan_code_encr, ctc_mmpos_offline_limit,
                      ctc_mmpos_online_limit, ctc_mmposusage_limit,
                      ctc_mmposusage_amt
                     )
              VALUES (v_hash_pan, p_instcode, p_offline_atm_limit,
                      p_online_atm_limit, p_offline_pos_limit,
                      p_online_pos_limit, p_offline_aggr_limit,
                      p_online_aggr_limit, '0',
                      '0', v_mbrnumb, NULL,
                      v_ins_date, '0', '0',
                      TO_DATE (   TO_CHAR (v_ins_date, 'dd/mm/yyyy')
                               || ' 23:59:59',
                               'dd/mm/yyyy hh24:mi:ss'
                              ),
                      v_encr_pan, p_offline_mmpos_limit,
                      p_online_aggr_limit, 0,
                      0
                     );
      EXCEPTION
         WHEN OTHERS
         THEN
            v_errmsg :=
                  'Error while Inserting in cms_translimit_check table '
               || SUBSTR (SQLERRM, 1, 200);
            RAISE exp_reject_record_pan;
      END;*/
      --En commented by Pankaj S. since we are not disable triggers

      --Inserting in card issuance status table
      BEGIN
         INSERT INTO cms_cardissuance_status
                     (ccs_inst_code, ccs_pan_code, ccs_card_status,
                      ccs_ins_user, ccs_lupd_user, ccs_pan_code_encr,
                      ccs_lupd_date, ccs_appl_code,
                      ccs_shipped_date  --2.1 onward changes
                     )
              VALUES (p_instcode, v_hash_pan, 15,
                      --2, -- STATUS CHANGED TO SHIPPED BY GANESH FOR MIGR
                      p_lupduser, p_lupduser, v_encr_pan,
                      SYSDATE, p_applcode,
                      p_emboss_gen_date_time+2  --2.1 onward changes
                     );
      EXCEPTION
         WHEN OTHERS
         THEN
            v_errmsg :=
                  'Error while Inserting in Card status Table '
               || SUBSTR (SQLERRM, 1, 200);
            p_migr_err_code := 'MIG-1_68';
            p_migr_err_desc := 'CARDISS_STAT_ENTRY_EXCP';
            RAISE exp_reject_record_pan;
      END;

      --End

      --En create a record in appl_pan
      BEGIN
         IF p_sms_flag = 'Y' OR p_email_flag = 'Y'
         THEN
            BEGIN
               SELECT cps_loadcredit_flag, cps_lowbal_flag,
                      cps_negativebal_flag, cps_highauthamt_flag,
                      cps_dailybal_flag, cps_insuffund_flag,
                      cps_incorrectpin_flag,CPS_CARDTOCARD_TRANS_FLAG,CPS_FAST50_FLAG,
                      CPS_FEDTAX_REFUND_FLAG,CPS_MOBUPDATE_FLAG
                 INTO v_loadcredit_flag, v_lowbal_flag,
                      v_negativebal_flag, v_highauthamt_flag,
                      v_dailybal_flag, v_insuffund_flag,
                      v_incorrectpin_flag,
                      V_CPS_CARDTOCARD_TRANS_FLAG,
                        V_CPS_FAST50_FLAG,
                        V_CPS_FEDTAX_REFUND_FLAG,
                        V_CPS_MOBUPDATE_FLAG
                 FROM cms_prodcatg_smsemail_alerts
                WHERE cps_inst_code = p_instcode
                  AND cps_prod_code = v_prod_code
                  AND cps_card_type = v_card_type
                 -- AND cps_config_flag = 'Y';
                  AND cps_config_flag in ( 'Y', 'N'); -- 20131028 SACHIN



            EXCEPTION
               WHEN NO_DATA_FOUND
               THEN
                  v_errmsg :=
                        'Invalid product code '
                     || v_prod_code
                     || ' and card type'
                     || v_card_type;
                  p_migr_err_code := 'MIG-1_072';
                  p_migr_err_desc := 'ALERT_CONFIG_EXCP';
                  RAISE exp_reject_record_pan;
               WHEN OTHERS
               THEN
                  v_errmsg :=
                        'Error while selecting alerts for '
                     || v_prod_code
                     || ' and '
                     || v_card_type;
                  p_migr_err_code := 'MIG-1_';
                  p_migr_err_desc := 'OTHER_THAN_PRDEFINE_EXCP';
                  RAISE exp_reject_record_pan;
            END;
                    IF v_loadcredit_flag = 1
                       THEN
                          SELECT CASE
                                    WHEN p_sms_flag = 'Y' AND p_email_flag = 'N' THEN 1
                                    WHEN p_sms_flag = 'N' AND p_email_flag = 'Y' THEN 2
                                    WHEN p_sms_flag = 'Y' AND p_email_flag = 'Y' THEN 3
                                 END
                            INTO v_loadcredit_alert
                            FROM DUAL;
                       END IF;

                       IF v_lowbal_flag = 1
                       THEN
                          SELECT CASE
                                    WHEN p_sms_flag = 'Y' AND p_email_flag = 'N' THEN 1
                                    WHEN p_sms_flag = 'N' AND p_email_flag = 'Y' THEN 2
                                    WHEN p_sms_flag = 'Y' AND p_email_flag = 'Y' THEN 3
                                 END
                            INTO v_lowbal_alert
                            FROM DUAL;
                       END IF;

                       IF v_negativebal_flag = 1
                       THEN
                          SELECT CASE
                                    WHEN p_sms_flag = 'Y' AND p_email_flag = 'N' THEN 1
                                    WHEN p_sms_flag = 'N' AND p_email_flag = 'Y' THEN 2
                                    WHEN p_sms_flag = 'Y' AND p_email_flag = 'Y' THEN 3
                                 END
                            INTO v_negativebal_alert
                            FROM DUAL;
                       END IF;

                       IF v_highauthamt_flag = 1
                       THEN
                          SELECT CASE
                                    WHEN p_sms_flag = 'Y' AND p_email_flag = 'N' THEN 1
                                    WHEN p_sms_flag = 'N' AND p_email_flag = 'Y' THEN 2
                                    WHEN p_sms_flag = 'Y' AND p_email_flag = 'Y' THEN 3
                                 END
                            INTO v_highauthamt_alert
                            FROM DUAL;
                       END IF;

                       IF v_dailybal_flag = 1
                       THEN
                          SELECT CASE
                                    WHEN p_sms_flag = 'Y' AND p_email_flag = 'N' THEN 1
                                    WHEN p_sms_flag = 'N' AND p_email_flag = 'Y' THEN 2
                                    WHEN p_sms_flag = 'Y' AND p_email_flag = 'Y' THEN 3
                                 END
                            INTO v_dailybal_alert
                            FROM DUAL;
                       END IF;

                       IF v_insuffund_flag = 1
                       THEN
                          SELECT CASE
                                    WHEN p_sms_flag = 'Y' AND p_email_flag = 'N' THEN 1
                                    WHEN p_sms_flag = 'N' AND p_email_flag = 'Y' THEN 2
                                    WHEN p_sms_flag = 'Y' AND p_email_flag = 'Y' THEN 3
                                 END
                            INTO v_insuffund_alert
                            FROM DUAL;
                       END IF;

                       IF v_incorrectpin_flag = 1
                       THEN
                          SELECT CASE
                                    WHEN p_sms_flag = 'Y' AND p_email_flag = 'N' THEN 1
                                    WHEN p_sms_flag = 'N' AND p_email_flag = 'Y' THEN 2
                                    WHEN p_sms_flag = 'Y' AND p_email_flag = 'Y' THEN 3
                                 END
                            INTO v_incorrectpin_alert
                            FROM DUAL;
                       END IF;

                       IF V_CPS_CARDTOCARD_TRANS_FLAG = 1
                       THEN
                          SELECT CASE
                                    WHEN p_sms_flag = 'Y' AND p_email_flag = 'N' THEN 1
                                    WHEN p_sms_flag = 'N' AND p_email_flag = 'Y' THEN 2
                                    WHEN p_sms_flag = 'Y' AND p_email_flag = 'Y' THEN 3
                                 END
                            INTO V_C2C_alert
                            FROM DUAL;
                       END IF;

                       IF V_CPS_FAST50_FLAG = 1
                       THEN
                          SELECT CASE
                                    WHEN p_sms_flag = 'Y' AND p_email_flag = 'N' THEN 1
                                    WHEN p_sms_flag = 'N' AND p_email_flag = 'Y' THEN 2
                                    WHEN p_sms_flag = 'Y' AND p_email_flag = 'Y' THEN 3
                                 END
                            INTO V_FAST50_alert
                            FROM DUAL;
                       END IF;

                       IF V_CPS_FEDTAX_REFUND_FLAG = 1
                       THEN
                          SELECT CASE
                                    WHEN p_sms_flag = 'Y' AND p_email_flag = 'N' THEN 1
                                    WHEN p_sms_flag = 'N' AND p_email_flag = 'Y' THEN 2
                                    WHEN p_sms_flag = 'Y' AND p_email_flag = 'Y' THEN 3
                                 END
                            INTO V_FEDTAX_REFUND_alert
                            FROM DUAL;
                       END IF;

                    /*   IF V_CPS_MOBUPDATE_FLAG = 1
                       THEN
                          SELECT CASE
                                    WHEN p_sms_flag = 'Y' AND p_email_flag = 'N' THEN 1
                                    WHEN p_sms_flag = 'N' AND p_email_flag = 'Y' THEN 2
                                    WHEN p_sms_flag = 'Y' AND p_email_flag = 'Y' THEN 3
                                 END
                            INTO V_MOBUPDATE_alert
                            FROM DUAL;
                       END IF;*/

                INSERT INTO cms_smsandemail_alert
                        (csa_inst_code, csa_pan_code, csa_pan_code_encr,
                         csa_loadorcredit_flag, csa_lowbal_flag,
                         csa_negbal_flag, csa_highauthamt_flag,
                         csa_dailybal_flag, csa_insuff_flag,
                         csa_incorrpin_flag,
                         CSA_C2C_FLAG    ,
                        CSA_FAST50_FLAG  ,
                        CSA_FEDTAX_REFUND_FLAG,
                --        CSA_MOBUPDATE_FLAG     ,
                         csa_ins_user, csa_ins_date,
                         --Sn 2.1 onward changes
                         csa_deppending_flag,
                         csa_depaccepted_flag,
                         csa_deprejected_flag
                         --En 2.1 onward changes
                        )
                 VALUES (p_instcode, v_hash_pan, v_encr_pan,
                         v_loadcredit_alert, v_lowbal_alert,
                         v_negativebal_alert, v_highauthamt_alert,
                         v_dailybal_alert, v_insuffund_alert,
                         v_incorrectpin_alert,
                         V_C2C_ALERT       ,
                         V_FAST50_ALERT     ,
                         V_FEDTAX_REFUND_ALERT ,
                     --    V_MOBUPDATE_ALERT ,
                         p_lupduser, SYSDATE,
                         --Sn 2.1 onward changes
                        0,
                        0,
                        0
                         --En 2.1 onward changes   
                        );
         ELSE
            INSERT INTO cms_smsandemail_alert
                        (csa_inst_code, csa_pan_code, csa_pan_code_encr,
                         csa_loadorcredit_flag, csa_lowbal_flag,
                         csa_negbal_flag, csa_highauthamt_flag,
                         csa_dailybal_flag, csa_insuff_flag,
                         csa_incorrpin_flag,
                         CSA_C2C_FLAG    ,
                        CSA_FAST50_FLAG  ,
                        CSA_FEDTAX_REFUND_FLAG,
                    --    CSA_MOBUPDATE_FLAG ,
                         csa_ins_user, csa_ins_date,
                         --Sn 2.1 onward changes
                         csa_deppending_flag,
                         csa_depaccepted_flag,
                         csa_deprejected_flag
                         --En 2.1 onward changes
                        )
                 VALUES (p_instcode, v_hash_pan, v_encr_pan,
                         0, 0,
                         0, 0,
                         0, 0,
                         0, 0,
                         0, 0,
                        -- 0,
                             p_lupduser, SYSDATE,
                        --Sn 2.1 onward changes
                        0,
                        0,
                        0
                         --En 2.1 onward changes    
                        );
         END IF;
      EXCEPTION
        --SN:  131025 Sachin -- Exception added
         WHEN exp_reject_record_pan
            THEN
               RAISE exp_reject_record_pan;
        --EN:  131025 Sachin -- Exception added


         WHEN OTHERS
         THEN
            v_errmsg :=
                  'Error while inserting records into SMS_EMAIL ALERT '
               || SUBSTR (SQLERRM, 1, 200);
            p_migr_err_code := 'MIG-1_069';
            p_migr_err_desc := 'SMS_EMAIL_ENTRY_EXCP';
            RAISE exp_reject_record_pan;
      END;

      --Sn create record in pan_acct
      FOR x IN c1 (p_applcode)
      LOOP
         BEGIN
            INSERT INTO cms_pan_acct
                        (cpa_inst_code, cpa_cust_code, cpa_acct_id,
                         cpa_acct_posn, cpa_pan_code, cpa_mbr_numb,
                         cpa_ins_user, cpa_lupd_user, cpa_pan_code_encr
                        )
                 VALUES (p_instcode, v_cust_code, x.cad_acct_id,
                         x.cad_acct_posn,
                                         --v_pan            ,
                                         v_hash_pan, v_mbrnumb,
                         p_lupduser, p_lupduser, v_encr_pan
                        );

            EXIT WHEN c1%NOTFOUND;
         EXCEPTION
            WHEN DUP_VAL_ON_INDEX
            THEN
               v_errmsg :=
                     'Duplicate record exist in pan acct master for pan  '
                  || v_pan
                  || ' and acct id '
                  || x.cad_acct_id;
               p_migr_err_code := 'MIG-1_070';
               p_migr_err_desc := 'DUPL_PAN_ACCT_RELN';
               RAISE exp_reject_record_pan;
            WHEN OTHERS
            THEN
               v_errmsg :=
                     'Error while inserting records into pan acct master '
                  || SUBSTR (SQLERRM, 1, 200);
               p_migr_err_code := 'MIG-1_';
               p_migr_err_desc := 'OTHER_THAN_PRDEFINE_EXCP';
               RAISE exp_reject_record_pan;
         END;
      END LOOP;

      --En create record in pan_acct
      IF p_mer_id IS NOT NULL AND p_locn_id IS NOT NULL
      THEN
         BEGIN
            SELECT cmp_merprodcat_id
              INTO v_merinv_prod_catg
              FROM cms_merinv_prodcat
             WHERE cmp_inst_code = p_instcode
               AND cmp_mer_id = p_mer_id
               AND cmp_prod_code = v_prod_code
               AND cmp_prod_cattype = v_card_type;
         EXCEPTION
            WHEN NO_DATA_FOUND
            THEN
               v_errmsg :=
                    'Merinv prod catg not found for merchant id ' || p_mer_id;
               RAISE exp_reject_record_pan;
            WHEN OTHERS
            THEN
               v_errmsg :=
                     'Error while getting merinv prod catg for merchant id '
                  || p_mer_id
                  || ' as '
                  || SUBSTR (SQLERRM, 1, 200);
               RAISE exp_reject_record_pan;
         END;

         BEGIN
            SELECT cmo_ordr_refrno
              INTO v_mer_inv_ordr
              FROM cms_merinv_ordr
             WHERE cmo_inst_code = p_instcode
               AND cmo_merprodcat_id = v_merinv_prod_catg
               AND cmo_location_id = p_locn_id
               AND cmo_ins_user = p_lupduser;
         EXCEPTION
            WHEN NO_DATA_FOUND
            THEN
               v_errmsg :=
                  'Merinv order refno not found for merchant id ' || p_mer_id;
               RAISE exp_reject_record_pan;
            WHEN OTHERS
            THEN
               v_errmsg :=
                     'Error while getting merinv order refno for merchant id '
                  || p_mer_id
                  || ' as '
                  || SUBSTR (SQLERRM, 1, 200);
               RAISE exp_reject_record_pan;
         END;

         BEGIN
            INSERT INTO cms_merinv_merpan
                        (cmm_inst_code, cmm_mer_id, cmm_location_id,
                         cmm_pancode_encr, cmm_pan_code,
                         cmm_activation_flag, cmm_expiry_date,
                         cmm_lupd_date, cmm_lupd_user, cmm_ins_date,
                         cmm_ins_user, cmm_ordr_refrno, cmm_merprodcat_id,
                         cmm_appl_code
                        )
                 VALUES (p_instcode, p_mer_id, p_locn_id,
                         v_encr_pan, v_hash_pan,
                         'M', v_expry_date,
                         SYSDATE, p_lupduser, SYSDATE,
                         p_lupduser, v_mer_inv_ordr, v_merinv_prod_catg,
                         p_applcode
                        );

            IF SQL%ROWCOUNT = 0
            THEN
               v_errmsg :=
                     'No rows inserted cms_merinv_merpan For-- '
                  || v_pan
                  || SUBSTR (SQLERRM, 1, 200);
               RAISE exp_reject_record_pan;
            END IF;
         EXCEPTION
            WHEN exp_reject_record_pan
            THEN
               RAISE exp_reject_record_pan;
            WHEN OTHERS
            THEN
               v_errmsg :=
                     'Error while inserting into cms_merinv_merpan'
                  || SUBSTR (SQLERRM, 1, 200);
               RAISE exp_reject_record_pan;
         END;

         --En to create record in CMS_MERINV_MERPAN
         BEGIN
            UPDATE cms_merinv_ordr
               SET cmo_success_records = NVL (cmo_success_records, 0) + 1
             WHERE cmo_inst_code = p_instcode -- Added on 16-sep-2013
             and   cmo_ordr_refrno = v_mer_inv_ordr;

            IF SQL%ROWCOUNT = 0
            THEN
               v_errmsg :=
                     'No rows updated cms_merinv_ordr For PAN '|| v_pan;  --|| SUBSTR (SQLERRM, 1, 200);--Error message modified by Pankaj S. on 25-Sep-2013
               RAISE exp_reject_record_pan;
            END IF;
         EXCEPTION
            WHEN exp_reject_record_pan
            THEN
               RAISE exp_reject_record_pan;
            WHEN OTHERS
            THEN
               v_errmsg :=
                     'Error while Updating cms_merinv_ordr For PAN '
                  || v_pan ||' as '
                  || SUBSTR (SQLERRM, 1, 200);
               RAISE exp_reject_record_pan;
         END;

         p_ordr_rfrno := v_mer_inv_ordr;
      END IF;

      --Sn update flag in appl_mast
      BEGIN
         UPDATE cms_appl_mast
            SET cam_appl_stat = 'O',
                cam_lupd_user = p_lupduser,
                cam_process_msg = 'SUCCESSFUL'
          WHERE cam_inst_code = p_instcode AND cam_appl_code = p_applcode;
      EXCEPTION
         WHEN OTHERS
         THEN
            v_errmsg :=
                  'Error while updating application status in appl mast  ' --Error message modified by Pankaj S. on 25-Sep-2013
               || SUBSTR (SQLERRM, 1, 200);
            p_migr_err_code := 'MIG-1_071';
            p_migr_err_desc := 'APPL_UPDT_ERR';
            RAISE exp_reject_record_pan;
      END;

      --En update flag in appl_mast
      p_errmsg := 'OK';
   EXCEPTION
      --<< MAIN EXCEPTION >>
      WHEN exp_reject_record_pan
      THEN
         p_errmsg := v_errmsg;

         UPDATE cms_appl_mast
            SET cam_appl_stat = 'E',
                cam_process_msg = v_errmsg,
                cam_lupd_user = p_lupduser
          WHERE cam_inst_code = p_instcode AND cam_appl_code = p_applcode;
      WHEN OTHERS
      THEN
         -- P_errmsg := 'Error while processing application for pan gen ' || SUBSTR(SQLERRM,1,200);
         v_errmsg :=
               'Error while processing application for pan gen '
            || SUBSTR (SQLERRM, 1, 200);
         p_migr_err_code := 'MIG-1_';
         p_migr_err_desc := 'OTHER_THAN_PRDEFINE_EXCP';

         UPDATE cms_appl_mast
            SET cam_appl_stat = 'E',
                cam_process_msg = v_errmsg,
                cam_lupd_user = p_lupduser
          WHERE cam_inst_code = p_instcode AND cam_appl_code = p_applcode;

         p_errmsg := v_errmsg;
   END;                                                        --<< MAIN END>>

   PROCEDURE migr_get_state_code_pkg (
      prm_inst_code          IN       NUMBER,
      prm_state_data         IN       VARCHAR2,
      prm_cntry_code         IN       VARCHAR2,
      prm_state_code         OUT      NUMBER,
      prm_swich_state_code   OUT      VARCHAR2,
      prm_migr_err_code      OUT      VARCHAR2,
      prm_migr_err_desc      OUT      VARCHAR2,
      prm_err_msg            OUT      VARCHAR2
   )
   IS
      v_state_code    gen_state_mast.gsm_state_code%TYPE;
      v_switch_code   gen_state_mast.gsm_switch_state_code%TYPE;
   BEGIN
      prm_err_msg := 'OK';

      SELECT gsm_state_code
        INTO v_state_code
        FROM gen_state_mast
       WHERE gsm_switch_state_code = prm_state_data
         AND gsm_inst_code = prm_inst_code
         AND gsm_cntry_code = prm_cntry_code;

      prm_state_code := v_state_code;
      prm_swich_state_code := prm_state_data;
   EXCEPTION
      WHEN NO_DATA_FOUND
      THEN
         BEGIN
            SELECT gsm_switch_state_code
              INTO v_switch_code
              FROM gen_state_mast
             WHERE gsm_state_code = prm_state_data
               AND gsm_inst_code = prm_inst_code
               AND gsm_cntry_code = prm_cntry_code;

            prm_state_code := prm_state_data;
            prm_swich_state_code := v_switch_code;
         EXCEPTION
            WHEN NO_DATA_FOUND
            THEN
               prm_err_msg := ' State data not defined in master';
               prm_migr_err_code := 'MIG-1_048';
               prm_migr_err_desc := 'INVALID_STATE_CODE1';
            WHEN INVALID_NUMBER
            THEN
               prm_err_msg := 'Not a valid state data';
               prm_migr_err_code := 'MIG-1_049';
               prm_migr_err_desc := 'INVALID_STATE_CODE2';
            WHEN OTHERS
            THEN
               prm_err_msg :=
                     'Error while selecting state detail data for state data='
                  || prm_state_data
                  || ' and state code='
                  || prm_state_code
                  || ' and swich_state_code='
                  || prm_swich_state_code
                  || SUBSTR (SQLERRM, 1, 200);
               prm_migr_err_code := 'MIG-1_';
               prm_migr_err_desc := 'OTHER_THAN_PRDEFINE_EXCP';
         END;
      WHEN OTHERS
      THEN
         prm_err_msg :=
               'Error while selecting state detail data'
            || SUBSTR (SQLERRM, 1, 200);
         prm_migr_err_code := 'MIG-1_';
         prm_migr_err_desc := 'OTHER_THAN_PRDEFINE_EXCP';
   END;

   PROCEDURE migr_set_gen_custdata_pkg (
      p_inst_code      IN       NUMBER,
      p_cust_rec       IN       type_cust_rec_array,
      p_cust_rec_out   OUT      type_cust_rec_array,
      p_err_msg        OUT      VARCHAR2
   )
   IS
      v_cusr_rec_outdata       type_cust_rec_array;
      v_error_message          VARCHAR2 (300);
      exp_cust_reject_record   EXCEPTION;
   BEGIN                                                    --<< main begin >>
      p_err_msg := 'OK';
      v_error_message := 'OK';

      BEGIN
         p_cust_rec_out := p_cust_rec;
      EXCEPTION
         WHEN OTHERS
         THEN
            v_error_message :=
                        'Error in fetching data ' || SUBSTR (SQLERRM, 1, 200);
            RAISE exp_cust_reject_record;
      END;
--En set data to generic variable
   EXCEPTION                                            --<< main exception >>
      WHEN exp_cust_reject_record
      THEN
         p_err_msg := v_error_message;
      WHEN OTHERS
      THEN
         p_err_msg := 'Error from main' || SUBSTR (SQLERRM, 1, 200);
   END;

   PROCEDURE migr_transaction_pkg (
      prm_instcode         NUMBER,
      prm_ins_date         DATE,
      prm_ins_user         NUMBER,
      prm_errmsg     OUT   VARCHAR2
   )
   IS
      v_errmsg                VARCHAR2 (500);
      v_errcode               VARCHAR2 (30);  -- Changed from 10 to 30 on 10-oct-2013
      v_reason_desc           cms_spprt_reasons.csr_reasondesc%TYPE;
      v_chk_del_chnl          VARCHAR2 (1);
      v_encr_pan              transactionlog.customer_card_no_encr%TYPE;
      v_gethash               transactionlog.customer_card_no%TYPE;
      v_tran_desc             cms_transaction_mast.ctm_tran_desc%TYPE;
      excp_reject_rec         EXCEPTION;
      v_commit_pnt            migr_ctrl_table.mct_ctrl_numb%TYPE;
      v_counter               NUMBER (6)                                 := 0;
      v_chk_card              VARCHAR2 (1);
      --Sn Added on 29-May-2013 by Pankaj S.
      v_prod_code             cms_appl_pan.cap_prod_code%TYPE;
      v_card_type             cms_appl_pan.cap_card_type%TYPE;
      v_acct_type             cms_acct_mast.cam_type_code%TYPE;
      v_preauth_count         NUMBER;
      v_trantype              VARCHAR2 (2);
      --En Added on 29-May-2013 by Pankaj S.
      v_total_amt             NUMBER;
      v_preauth_hold          VARCHAR2 (1);
      v_preauth_period        NUMBER;
      v_preauth_expryperiod   VARCHAR2 (3);
      v_preauth_date          DATE;
      v_tran_date             DATE;
      v_rowid                 VARCHAR2 (40);
      v_hold_amount           NUMBER                                     := 0;
      v_to_card_expry         cms_appl_pan.cap_expry_date%TYPE;
      v_hash_pan_to           cms_appl_pan.cap_pan_code%TYPE;
      v_encr_pan_to           cms_appl_pan.cap_pan_code_encr%TYPE;
      v_tocardstat            VARCHAR2 (5);
      v_toacct_no             VARCHAR2 (20);
      v_toprodcode            cms_appl_pan.cap_prod_code%TYPE;
      v_tocardtype            cms_appl_pan.cap_card_type%TYPE;
      v_tocard_proxy          cms_appl_pan.cap_proxy_number%TYPE;
      v_call_id               NUMBER;
      v_req_id                cms_c2ctxfr_transaction.cct_request_id%TYPE;
      v_toledger_bal          cms_acct_mast.cam_ledger_bal%TYPE;
      v_toacct_type           cms_acct_mast.cam_type_code%TYPE;
      v_toacct_bal            cms_acct_mast.cam_acct_bal%TYPE;
      v_migr_err_desc         VARCHAR2 (50);
      set_gethash             cms_appl_pan.cap_pan_code%TYPE;
      set_card_no             VARCHAR2 (4);
                                 --chnaged from number to varchar2 -- 04JUL13
      set_v_prod_code         cms_appl_pan.cap_prod_code%TYPE;
      set_v_acct_type         cms_appl_pan.cap_card_type%TYPE;
      set_v_encr_pan          transactionlog.customer_card_no_encr%TYPE;
      v_spprt_key             cms_spprt_reasons.csr_spprt_key%TYPE;
      v_func_remark           cms_spprt_reasons.csr_reasondesc%TYPE;
      v_reaosn_code           cms_spprt_reasons.csr_spprt_rsncode%TYPE;
      v_csr_spprt_key         cms_spprt_reasons.csr_spprt_key%TYPE;
      v_check                 VARCHAR2 (1);
      v_savepoint             NUMBER (20)                                := 0;
                                                                    --04JUL13
      v_date_time             DATE;                                 --04JUL13
      v_openeing_bal          cms_statements_log.csl_opening_bal%type; --04JUL13 Added to handle fee attached for reversal transaction
      v_resp_id               cms_response_mast.cms_response_id%TYPE;

      v_gl_acct_code          cms_gl_acct_mast.cga_acct_code%type;
      vv_gl_acct_code          cms_gl_acct_mast.cga_acct_code%type;
      v_opening_bal           cms_statements_log.csl_opening_bal%TYPE;
      v_preauth_validflag     cms_preauth_transaction.cpt_preauth_validflag%type;
      v_preauth_expflag       cms_preauth_transaction.cpt_expiry_flag%type;
      v_tran_flag             cms_preauth_transaction.cpt_transaction_flag%type;
      v_comp_flag             cms_preauth_transaction.cpt_completion_flag%type;

      main_tran_excp EXCEPTION; -- SN: 20131028 : SACHIN: PRFORMANCE

      CURSOR c
      IS
         SELECT   ROWID, a.*
             FROM migr_transactionlog_temp a
            WHERE mtt_flag = 'N'
         --ORDER BY TO_DATE (mtt_posted_date, 'YYYYMMDD hh24miss'); -- Sachin 20131028 - commented performance
         ;
         --SN Dhiraj Gaikwad
        v_Hash_key    cms_transaction_log_dtl.CTD_HASHKEY_ID%type ;
           v_odfi_cnt              NUMBER;
           V_ACH_EXCEPTION_QUEUE_FLAG          TRANSACTIONLOG.ACH_EXCEPTION_QUEUE_FLAG%TYPE;
           V_ACH_AUTO_CLEAR_FLAG   VARCHAR2 (2);

         --EN Dhiraj Gaikwad
   BEGIN
      v_errmsg := 'OK';
      prm_errmsg := 'OK';

      BEGIN
         SELECT mct_ctrl_numb
           INTO v_commit_pnt
           FROM migr_ctrl_table
          WHERE mct_ctrl_code = prm_instcode AND mct_ctrl_key = 'COMMIT_PARAM';
      EXCEPTION
         WHEN OTHERS
         THEN
            v_commit_pnt := 1000;
      END;

      -- SN: 20131028 Sacihn : added for perforamce

                 BEGIN

                    SELECT CGA_ACCT_CODE
                    into   vv_gl_acct_code
                      FROM cms_gl_acct_mast
                     WHERE CGA_INST_CODE = prm_instcode  -- Added on 16-sep-2013
                     and   cga_acct_code IN (
                                     SELECT tranfee_cr_acctno
                                       FROM transactionlog
                                      WHERE instcode = prm_instcode  -- Added on 16-sep-2013
                                      and   response_code = '00' AND tranfee_amt > 0
                                      and add_ins_user <> prm_ins_user  AND ROWNUM < 2 )
                       AND ROWNUM < 2;


                 EXCEPTION WHEN OTHERS
                  THEN
                      v_errmsg :=
                           'Error occured while fetching GL ACCT CODE '
                       ;

                        RAISE main_tran_excp;

                 END;

-- SN: 20131028 Sacihn : added for perforamce
      FOR i IN c
      LOOP
         BEGIN
            v_errcode := 'MIG-400';
            v_errmsg := 'OK';
            SAVEPOINT v_savepoint;
            v_savepoint := v_savepoint + 1;
           --Dhiraj Gaikwad
           v_Hash_key:=NULL ;
           v_odfi_cnt  :=NULL ;
           V_ACH_EXCEPTION_QUEUE_FLAG      :=NULL ;
           V_ACH_AUTO_CLEAR_FLAG :=NULL ;
           --Dhiraj Gaikwad

            BEGIN
               v_gethash := gethash (i.mtt_card_no);
            EXCEPTION
               WHEN OTHERS
               THEN
                  v_errcode := SQLCODE;
                  v_errmsg :=
                        'while getting hash value for card - '
                     || i.mtt_card_no
                     || ' and RRN '  --Error message modified by Pankaj S. on 25-Sep-2013
                     || i.mtt_rrn
                     || ' '
                     || SUBSTR (SQLERRM, 1, 100);
                  RAISE excp_reject_rec;
            END;

            BEGIN
               v_encr_pan := fn_emaps_main (i.mtt_card_no);
            EXCEPTION
               WHEN OTHERS
               THEN
                  v_errcode := SQLCODE;
                  v_errmsg :=
                        'while encrypting card - '
                     || i.mtt_card_no
                     || ' and RRN ' --Error message modified by Pankaj S. on 25-Sep-2013
                     || i.mtt_rrn
                     || ' '
                     || SUBSTR (SQLERRM, 1, 100);
                  RAISE excp_reject_rec;
            END;

            BEGIN
               v_date_time :=
                  TO_DATE (i.mtt_business_date || ' ' || i.mtt_business_time,
                           'YYYYMMDD HH24MISS'
                          );
            EXCEPTION
               WHEN OTHERS
               THEN
                  v_errcode := SQLCODE;
                  v_errmsg :=
                        'while converting input date for card - '
                     || i.mtt_card_no
                     || ' and RRN '  --Error message modified by Pankaj S. on 25-Sep-2013
                     || i.mtt_rrn
                     || ' '
                     || SUBSTR (SQLERRM, 1, 100);
                  RAISE excp_reject_rec;
            END;

            BEGIN
               --Sn Modified on 29-May-2013 by Pankaj S.
               SELECT cap_prod_code, cap_card_type                         --1
                 INTO v_prod_code, v_card_type                    --v_chk_card
                 --En Modified on 29-May-2013 by Pankaj S.
               FROM   cms_appl_pan
                WHERE cap_inst_code = prm_instcode
                      AND cap_pan_code = v_gethash;
            EXCEPTION
               WHEN NO_DATA_FOUND
               THEN
                  v_errcode := 'MIG-401';
                  v_migr_err_desc := 'EXCP_CARD_NOT_FOUND';
                  v_errmsg :=
                        'Card '|| i.mtt_card_no ||' not found in master '         --Error message modified by Pankaj S. on 25-Sep-2013
                     || ' for RRN ' --Error message modified by Pankaj S. on 25-Sep-2013
                     || i.mtt_rrn;
                  RAISE excp_reject_rec;
               WHEN OTHERS
               THEN
                  v_errcode := SQLCODE;
                  v_errmsg :=
                        'Error while validating delivery channel '
                     || i.mtt_delivery_channel
                     || ' for card - '
                     || i.mtt_card_no
                     || ' and RRN ' --Error message modified by Pankaj S. on 25-Sep-2013
                     || i.mtt_rrn
                     || ' '
                     || SUBSTR (SQLERRM, 1, 100);
                  RAISE excp_reject_rec;
            END;

            --Sn Added on 29-May-2013 by Pankaj S. to get account type
            BEGIN
               SELECT cam_type_code
                 INTO v_acct_type
                 FROM cms_acct_mast
                WHERE cam_inst_code = prm_instcode
                  AND cam_acct_no = TRIM (i.mtt_account_number);
            EXCEPTION
               WHEN NO_DATA_FOUND
               THEN
                  v_errcode := 'MIG-402';
                  v_migr_err_desc := 'EXCP_ACCT_NOT_FOUND';
                  v_errmsg :=
                        'Account '|| TRIM (i.mtt_account_number)||' not found in master ' --Error message modified by Pankaj S. on 25-Sep-2013
                     || ' for RRN '--Error message modified by Pankaj S. on 25-Sep-2013
                     || i.mtt_rrn;
                  RAISE excp_reject_rec;
               WHEN OTHERS
               THEN
                  v_errcode := SQLCODE;
                  v_errmsg :=
                        'Error while selecting account '|| TRIM (i.mtt_account_number)|| ' details ' --Error message modified by Pankaj S. on 25-Sep-2013
                     || ' for card - '
                     || i.mtt_card_no
                     || ' and RRN '  --Error message modified by Pankaj S. on 25-Sep-2013
                     || i.mtt_rrn
                     || ' '
                     || SUBSTR (SQLERRM, 1, 100);
                  RAISE excp_reject_rec;
            END;

            --En Added on 29-May-2013 by Pankaj S. to get account type
            BEGIN
               SELECT 1
                 INTO v_chk_del_chnl
                 FROM cms_delchannel_mast
                WHERE cdm_inst_code = prm_instcode
                  AND cdm_channel_code = i.mtt_delivery_channel;
            EXCEPTION
               WHEN NO_DATA_FOUND
               THEN
                  v_errcode := 'MIG-403';
                  v_migr_err_desc := 'EXCP_DELCHNL_NOT_FOUND';
                  v_errmsg :=
                        'Delivery channel '
                     || i.mtt_delivery_channel
                     || ' not found in master '
                     || ' for card '
                     || i.mtt_card_no
                     || ' and RRN ' --Error message modified by Pankaj S. on 25-Sep-2013
                     || i.mtt_rrn;
                  RAISE excp_reject_rec;
               WHEN OTHERS
               THEN
                  v_errcode := SQLCODE;
                  v_errmsg :=
                        'Error while validating delivery channel '
                     || i.mtt_delivery_channel
                     || ' for card - '
                     || i.mtt_card_no
                     || ' and RRN ' --Error message modified by Pankaj S. on 25-Sep-2013
                     || i.mtt_rrn
                     || ' '
                     || SUBSTR (SQLERRM, 1, 100);
                  RAISE excp_reject_rec;
            END;

            BEGIN
               SELECT ctm_tran_desc
                 INTO v_tran_desc
                 FROM cms_transaction_mast
                WHERE ctm_inst_code = prm_instcode
                  AND ctm_tran_code = i.mtt_transaction_code
                  AND ctm_delivery_channel = i.mtt_delivery_channel;
            EXCEPTION
               WHEN NO_DATA_FOUND
               THEN
                  v_errcode := 'MIG-404';
                  v_migr_err_desc := 'EXCP_TXNCODE_NOT_FOUND';
                  v_errmsg :=
                        'Combination of transaction code '
                     || i.mtt_transaction_code
                     || ' and delivery channel- '
                     || i.mtt_delivery_channel
                     || ' not found in master'
                     || ' for card - '
                     || i.mtt_card_no
                     || ' and RRN ' --Error message modified by Pankaj S. on 25-Sep-2013
                     || i.mtt_rrn;
                  RAISE excp_reject_rec;
               WHEN OTHERS
               THEN
                  v_errcode := SQLCODE;
                  v_errmsg :=
                        'Error while validating transaction code '
                     || i.mtt_transaction_code
                     || ' and delivery channel - '
                     || i.mtt_delivery_channel
                     || ' for card - '
                     || i.mtt_card_no
                     || ' and RRN ' --Error message modified by Pankaj S. on 25-Sep-2013
                     || i.mtt_rrn
                     || ' '
                     || SUBSTR (SQLERRM, 1, 100);
                  RAISE excp_reject_rec;
            END;
           IF ( (i.mtt_transaction_code = '80' AND i.mtt_delivery_channel = '04')
       OR (i.mtt_transaction_code = '82' AND i.mtt_delivery_channel = '04')
       OR (i.mtt_transaction_code = '88' AND i.mtt_delivery_channel = '04')
       OR (i.mtt_transaction_code = '85' AND i.mtt_delivery_channel = '04')
       OR (i.mtt_transaction_code = '68' AND i.mtt_delivery_channel = '04')) then

        select  Nvl(Decode(Substr(i.MTT_REASON_CODE,1,1),'F',('Fast'||i.mtt_amount),'T','Federal Assisted Refund','S','State Assisted Refund'),v_tran_desc) into  v_tran_desc
            from dual ;
            END IF ;
            IF     i.mtt_delivery_channel = '03'
               AND i.mtt_transaction_code IN
                      ('13', '14', '37', '19', '20', '12', '11', '74', '76',
                       '75', '78', '83', '84', '85', '86', '87')
            THEN
               BEGIN
                  SELECT csr_reasondesc, csr_spprt_key
                    INTO v_reason_desc, v_csr_spprt_key
                    FROM cms_spprt_reasons
                   WHERE csr_inst_code = prm_instcode
                     AND csr_spprt_rsncode = i.mtt_reasoncode;
               EXCEPTION
                  WHEN NO_DATA_FOUND
                  THEN
                     v_errcode := 'MIG-405';
                     v_migr_err_desc := 'EXCP_RSNCODE_NOT_FOUND';
                     v_errmsg :=
                           'Support reason code '
                        || i.mtt_reasoncode
                        || ' not found in master'
                        || ' for delivery channel '
                        || i.mtt_delivery_channel
                        || ' for card '
                        || i.mtt_card_no
                        || ' and RRN ' --Error message modified by Pankaj S. on 25-Sep-2013
                        || i.mtt_rrn;
                     RAISE excp_reject_rec;
                  WHEN OTHERS
                  THEN
                     v_errcode := SQLCODE;
                     v_errmsg :=
                           'Error occured while fetching details for reason code ' --Error message modified by Pankaj S. on 25-Sep-2013
                        || i.mtt_reasoncode
                        || ' for card - '
                        || i.mtt_card_no
                        || ' and RRN ' --Error message modified by Pankaj S. on 25-Sep-2013
                        || i.mtt_rrn
                        || ' '
                        || SUBSTR (SQLERRM, 1, 100);
                     RAISE excp_reject_rec;
               END;
            END IF;


/* -- SN : 20131028 SACHIN : CHANGED FOR PERFORMANCE
            if i.MTT_TRANFEE_AMOUNT > 0 or i.MTT_SERVICETAX_AMOUNT > 0
            then
                 BEGIN

                    SELECT CGA_ACCT_CODE
                    into   v_gl_acct_code
                      FROM cms_gl_acct_mast
                     WHERE CGA_INST_CODE = prm_instcode  -- Added on 16-sep-2013
                     and   cga_acct_code IN (
                                     SELECT tranfee_cr_acctno
                                       FROM transactionlog
                                      WHERE instcode = prm_instcode  -- Added on 16-sep-2013
                                      and   response_code = '00' AND tranfee_amt > 0
                                      and add_ins_user <> prm_ins_user  AND ROWNUM < 2 )
                       AND ROWNUM < 2;


                 EXCEPTION WHEN OTHERS
                  THEN
                     v_errcode := SQLCODE;
                     v_errmsg :=
                           'Error occured while fetching GL ACCT CODE '
                        || ' for card - '
                        || i.mtt_card_no
                        || ' and RRN ' --Error message modified by Pankaj S. on 25-Sep-2013
                        || i.mtt_rrn
                        || ' '
                        || SUBSTR (SQLERRM, 1, 100);
                     RAISE excp_reject_rec;

                 END;
            end if;

*/  -- EN : 20131028 SACHIN : CHANGED FOR PERFORMANCE

-- SN 2013 SACHIN: REPLACEMENT FOR ABOVE CODE

            if i.MTT_TRANFEE_AMOUNT > 0 or i.MTT_SERVICETAX_AMOUNT > 0
            then

            v_gl_acct_code := vv_gl_acct_code ;

            else

            v_gl_acct_code := null ;

            end if;

-- EN 2013 SACHIN: REPLACEMENT FOR ABOVE CODE
            IF     i.mtt_delivery_channel = '11'
               AND i.mtt_transaction_code IN ('22', '23', '32', '33')
            THEN
               v_spprt_key := 'TOP';
               v_func_remark := 'ACH Credit Transaction';
               v_reaosn_code := '31';
            ELSIF     i.mtt_delivery_channel = '04'
                  AND i.mtt_transaction_code IN ('68', '69')
            THEN
               v_spprt_key := 'INLOAD';
               v_func_remark := 'CARD ACTIVATION WITH PROFILE';
               v_reaosn_code := '49';
            ELSIF     i.mtt_delivery_channel = '04'
                  AND i.mtt_transaction_code IN ('75')
            THEN
               v_spprt_key := 'HTLST';
               v_func_remark := 'Online Card Status Change';
               v_reaosn_code := '2';
            ELSIF     i.mtt_delivery_channel = '04'
                  AND i.mtt_transaction_code IN ('76')
            THEN
               v_spprt_key := 'BLOCK';
               v_func_remark := 'Online Card Status Change';
               v_reaosn_code := '43';
            ELSIF     i.mtt_delivery_channel = '04'
                  AND i.mtt_transaction_code IN ('77')
            THEN
               v_spprt_key := 'DBLOK';
               v_func_remark := 'Online Card Status Change';
               v_reaosn_code := '54';
            ELSIF     i.mtt_delivery_channel = '04'
                  AND i.mtt_transaction_code IN ('83')
            THEN
               v_spprt_key := 'CARDCLOSE';
               v_func_remark := 'Online Card Status Change';
               v_reaosn_code := '9';
            ELSIF     i.mtt_delivery_channel = '10'
                  AND i.mtt_transaction_code IN ('06')
            THEN
               v_spprt_key := 'DEBLOCK';
               v_func_remark := 'Online Card Status Change';
               v_reaosn_code := '54';
            ELSIF     i.mtt_delivery_channel = '10'
                  AND i.mtt_transaction_code IN ('05')
            THEN
               v_spprt_key := 'BLOCK';
               v_func_remark := 'Online Card Status Change';
               v_reaosn_code := '61';
            ELSIF     i.mtt_delivery_channel = '07'
                  AND i.mtt_transaction_code IN ('05')
            THEN
               v_spprt_key := 'BLOCK';
               v_func_remark := 'Online Card Status Change';
               v_reaosn_code := '43';
            ELSIF     i.mtt_delivery_channel = '07'
                  AND i.mtt_transaction_code IN ('06')
            THEN
               v_spprt_key := 'DEBLOCK';
               v_func_remark := 'Online Card Status Change';
               v_reaosn_code := '54';
            ELSIF     i.mtt_delivery_channel = '10'
                  AND i.mtt_transaction_code IN ('02')
            THEN
               v_spprt_key := 'ACTVTCARD';
               v_func_remark := 'CHW Card Activation';
               v_reaosn_code := '55';
            ELSIF     i.mtt_delivery_channel = '10'
                  AND i.mtt_transaction_code IN ('99', '11')
            THEN
               v_spprt_key := 'REISSUE';
               v_func_remark := 'Online Order Replacement Card';
               v_reaosn_code := '10';
            ELSIF     i.mtt_delivery_channel = '07'
                  AND i.mtt_transaction_code IN ('02', '09')
            THEN
               v_spprt_key := 'ACTVTCARD';
               v_func_remark := 'IVR Card Activation';
               v_reaosn_code := '55';
            ELSIF     i.mtt_delivery_channel = '08'
                  AND i.mtt_transaction_code IN
                                               ('25', '26', '28', '21', '22')
            THEN
               v_spprt_key := 'TOP';
               v_func_remark := 'Online Card Topup';
               v_reaosn_code := '31';
            ELSIF     i.mtt_delivery_channel = '04'
                  AND i.mtt_transaction_code IN ('80', '82', '85', '88')
            THEN
               v_spprt_key := 'TOP';
               v_func_remark := 'Online Card Topup';
               v_reaosn_code := '31';
            ELSIF     i.mtt_delivery_channel = '07'
                  AND i.mtt_transaction_code IN ('08')
            THEN
               v_spprt_key := 'TOP';
               v_func_remark := 'Online Card Topup';
               v_reaosn_code := '31';
            ELSIF     i.mtt_delivery_channel = '03'
                  AND i.mtt_transaction_code IN
                         ('13', '14', '37', '19', '20', '12', '11', '74',
                          '76', '75', '78', '83', '84', '85', '86', '87')
            THEN
               v_spprt_key := v_csr_spprt_key;
               v_func_remark := v_reason_desc;
               v_reaosn_code := i.mtt_reasoncode;
            ELSIF     i.mtt_delivery_channel = '03'               --SN 04JUL13
                  AND i.mtt_transaction_code IN ('22', '29')
            THEN
               v_spprt_key := 'REISSUE';
               v_func_remark := 'Online Order Replacement Card';
               v_reaosn_code := '10';                            --EN 04JUL13
            END IF;

           -- IF     v_spprt_key IS NOT NULL
           --    AND v_func_remark IS NOT NULL
           --    AND v_reaosn_code IS NOT NULL
           -- 20131028 SACHIN COMMENTED AND DONE BELOW CHANGE FOR PERFORMACNE

           IF v_spprt_key IS  NULL
               AND v_func_remark IS  NULL
               AND v_reaosn_code IS  NULL
           THEN

           NULL;

           ELSE

               BEGIN
                  INSERT INTO /*+ append */ cms_pan_spprt
                              (cps_inst_code, cps_pan_code, cps_mbr_numb,
                               cps_spprt_key, cps_func_remark, cps_ins_user,
                               cps_ins_date,
                               cps_prod_catg, cps_lupd_user,
                               cps_lupd_date,
                               cps_pan_code_encr, cps_spprt_rsncode
                              )
                       VALUES (prm_instcode, v_gethash, '000',
                               v_spprt_key, v_func_remark, prm_ins_user,
                               TO_DATE (i.mtt_posted_date,
                                        'YYYYMMDD HH24MISS'),
                               v_card_type, prm_ins_user,
                               TO_DATE (i.mtt_posted_date,
                                        'YYYYMMDD HH24MISS'),
                               v_encr_pan, v_reaosn_code
                              );

                  IF v_spprt_key IN ('REISU', 'REISSUE')
                  THEN
                     BEGIN
                        INSERT INTO cms_htlst_reisu
                                    (chr_inst_code, chr_pan_code,
                                     chr_mbr_numb,
                                     chr_new_pan,
                                     chr_new_mbr, chr_reisu_cause,
                                     chr_ins_user,
                                     chr_ins_date,
                                     chr_lupd_user,
                                     chr_lupd_date,
                                     chr_new_pan_encr,
                                     chr_pan_code_encr
                                    )
                             VALUES (prm_instcode, v_gethash,
                                     '000',
                                     gethash (i.mtt_beneficiary_card_no),
                                     '000', 'R',
                                     prm_ins_user,
                                     TO_DATE (i.mtt_posted_date,
                                              'YYYYMMDD HH24MISS'
                                             ),
                                     prm_ins_user,
                                     TO_DATE (i.mtt_posted_date,
                                              'YYYYMMDD HH24MISS'
                                             ),
                                     fn_emaps_main (i.mtt_beneficiary_card_no),
                                     v_encr_pan
                                    );
                     EXCEPTION
                        WHEN OTHERS
                        THEN
                           v_errcode := SQLCODE;
                           v_errmsg :=
                                 'Error while creating entry in HTLST REISU table '
                              || SUBSTR (SQLERRM, 1, 200);
                           RAISE excp_reject_rec;
                     END;
                  END IF;
               EXCEPTION
                  WHEN excp_reject_rec
                  THEN
                     RAISE;
                  WHEN OTHERS
                  THEN
                     v_errcode := SQLCODE;
                     v_errmsg :=
                           'Error while creating entry in PAN support for card '
                        || i.mtt_card_no
                        || ' and RRN ' --Error message modified by Pankaj S. on 25-Sep-2013
                        || i.mtt_rrn
                        || SUBSTR (SQLERRM, 1, 100);
                     RAISE excp_reject_rec;
               END;
            END IF;

            IF i.mtt_dispute_flag = 1
            THEN
               BEGIN
                  INSERT INTO cms_dispute_txns
                              (cdt_inst_code, cdt_pan_code,
                               cdt_pan_code_encr, cdt_dispute_status,
                               cdt_dispute_amount, cdt_txn_date,
                               cdt_txn_time, cdt_delivery_channel,
                               cdt_txn_code, cdt_rrn,
                               cdt_remark, cdt_ins_user,
                               cdt_ins_date,
                               cdt_lupd_user,
                               cdt_lupd_date
                              )
                       VALUES (prm_instcode, gethash (i.mtt_orgnl_cardnumber),
                               fn_emaps_main (i.mtt_orgnl_cardnumber), 'O',
                               i.mtt_amount, i.mtt_orgnl_businessdate,
                               i.mtt_orgnl_businesstime, i.mtt_orgnl_delv_chnl,
                               i.mtt_orgnl_tran_code, i.mtt_orgnl_rrn,
                               i.mtt_disp_remark, prm_ins_user,
                               TO_DATE (i.mtt_posted_date,
                                        'yyyymmdd hh24miss'),
                               prm_ins_user,
                               TO_DATE (i.mtt_posted_date,
                                        'yyyymmdd hh24miss')
                              );
               EXCEPTION
                  WHEN OTHERS
                  THEN
                     v_errmsg :=
                           'Error occured while inserting into dispute table for card '
                        || i.mtt_card_no
                        || ' and RRN ' --Error message modified by Pankaj S. on 25-Sep-2013
                        || i.mtt_rrn
                        || ' '
                        || SUBSTR (SQLERRM, 1, 100);
                     v_errcode := SQLCODE;
                     RAISE excp_reject_rec;
               END;
            END IF;

            IF     i.mtt_transaction_code IN ('13', '14')
               AND i.mtt_delivery_channel = '03'
               AND i.mtt_response_code = '00'
            THEN
               BEGIN
                  INSERT INTO cms_manual_adjustment
                              (cma_inst_code,
                               cma_adjustment_date,
                               cma_pan_code, cma_pan_code_encr,
                               cma_adjustment_type,
                               cma_debit_amount,
                               cma_credit_amount,
                               cma_tran_code,
                               cma_tran_mode,
                               cma_delivery_channel, cma_ins_user,
                               cma_ins_date,
                               cma_lupd_user,
                               cma_lupd_date
                              )
                       VALUES (prm_instcode,
                               TO_DATE (i.mtt_business_date, 'yyyymmdd'),
                               v_gethash, v_encr_pan,
                               i.mtt_reasoncode,
                               DECODE (i.mtt_crdr_flag,
                                       '0', i.mtt_amount,
                                       '0'
                                      ),
                               DECODE (i.mtt_crdr_flag,
                                       '1', i.mtt_amount,
                                       '0'
                                      ),
                               i.mtt_transaction_code,
                               i.mtt_transaction_mode,
                               i.mtt_delivery_channel, prm_ins_user,
                               TO_DATE (i.mtt_posted_date,
                                        'yyyymmdd hh24miss'),
                               prm_ins_user,
                               TO_DATE (i.mtt_posted_date,
                                        'yyyymmdd hh24miss')
                              );
               EXCEPTION
                  WHEN OTHERS
                  THEN
                     v_errmsg :=
                           'Error occured while inserting into manual adjustment table for card '
                        || i.mtt_card_no
                        || ' and RRN ' --Error message modified by Pankaj S. on 25-Sep-2013
                        || i.mtt_rrn
                        || ' '
                        || SUBSTR (SQLERRM, 1, 100);
                     v_errcode := SQLCODE;
                     RAISE excp_reject_rec;
               END;
            END IF;

            IF     i.mtt_transaction_code =
                                         '11'
                                             --SN Preauth Hold release 04JUL13
               AND i.mtt_delivery_channel = '03'
               AND i.mtt_response_code = '00'
            THEN
               BEGIN
                  INSERT INTO /*+ append */ cms_preauth_trans_hist
                              (cph_card_no, cph_mbr_no, cph_inst_code,
                               cph_card_no_encr,
                               cph_preauth_validflag,
                               cph_completion_flag,
                               cph_txn_amnt,
                               cph_approve_amt,
                               cph_rrn, cph_txn_date,
                               cph_txn_time, cph_orgnl_rrn,
                               cph_orgnl_txn_date,
                               cph_orgnl_txn_time,
                               cph_orgnl_card_no,
                               cph_terminalid, cph_orgnl_terminalid,
                               cph_comp_count,
                               cph_transaction_flag,
                               cph_totalhold_amt, cph_merchant_name,
                               --Added by Deepa on May-09-2012 for statement changes
                               cph_merchant_city, cph_merchant_state,
                               cph_delivery_channel,
                               cph_tran_code,
                               cph_panno_last4digit,
                               cph_acct_no, cph_orgnl_mcccode,
                               -- Added on 27-Feb-2013 for FSS-781
                               cph_match_rrn, cph_expiry_flag,
                               -- Added on 27-Feb-2013 for FSS-781
                               cph_ins_date,
                               cph_lupd_date,
                               cph_expiry_date,    -- 04JUL13 expiry date added
                               cph_preauth_type  --2.1 onward changes
                              )
                       VALUES (v_gethash, '000', prm_instcode,
                               v_encr_pan,
                               NVL (i.mtt_preauth_validflag, 'N'),
                               NVL (i.mtt_completion_flag, 'C'),
                               ROUND (i.mtt_amount, 2),
                               TRIM (TO_CHAR (ROUND (i.mtt_total_amount, 2),
                                              '999999999999999990.99'
                                             )
                                    ),
                               i.mtt_rrn, i.mtt_business_date,
                               i.mtt_business_time, i.mtt_orgnl_rrn,
                               i.mtt_orgnl_businessdate,
                               i.mtt_orgnl_businesstime,
                               gethash (i.mtt_orgnl_cardnumber),
                               i.mtt_terminal_id, i.mtt_orgnl_terminalid,
                               i.mtt_completion_count,
                               NVL (i.mtt_transaction_flag, 'R'),
                               i.mtt_pend_holdamt, i.mtt_merchant_name,
                               i.mtt_merchant_city, i.mtt_atm_namelocation,
                               i.mtt_delivery_channel,
                               i.mtt_transaction_code,
                               (SUBSTR (i.mtt_card_no,
                                        LENGTH (i.mtt_card_no) - 3,
                                        LENGTH (i.mtt_card_no)
                                       )
                               ),
                               TRIM (i.mtt_account_number), i.mtt_mcccode,
                               i.mtt_orgnl_rrn, nvl(i.mtt_expiry_flag,'Y'), -- nvl added as per discssion 02-Aug-2013
                               TO_DATE (i.mtt_posted_date,
                                        'yyyymmdd hh24miss'),
                               TO_DATE (i.mtt_posted_date,
                                        'yyyymmdd hh24miss'),
                               TO_DATE (i.mtt_preauth_expry_date,
                                        'yyyymmdd hh24miss'
                                       ),
                               DECODE (i.mtt_crdr_flag, '1', 'C', 'D')  --2.1 onward changes        
                              );
               EXCEPTION
                  WHEN OTHERS
                  THEN
                     v_errmsg :=
                           'Error while inserting into cms_preauth_trans_hist for hold release txn '
                        || SUBSTR (SQLERRM, 1, 100);
                     v_errcode := SQLCODE;
                     RAISE excp_reject_rec;
               END;
            END IF;                          --EN Preauth Hold release 04JUL13

            IF     i.mtt_transaction_code in ('11','24')  -- = '11' --Added By Dhiraj Gaikwad For Preauth Adjustment Transaction
               AND i.mtt_delivery_channel = '02'
               AND i.mtt_response_code = '00'
            THEN

               BEGIN

                    --------------------------------------------------------Sn 02Aug2013

                    --                  SELECT COUNT (*)
                    --                    INTO v_preauth_count
                    --                    FROM cms_preauth_transaction
                    --                   WHERE cpt_card_no = v_gethash
                    --                     AND cpt_rrn = i.mtt_rrn
                    --                     AND cpt_preauth_validflag = 'Y'
                    --                     AND cpt_expiry_flag = 'N';

                    --                  IF v_preauth_count > 0
                    --                  THEN
                    --                     IF i.mtt_incremental_ind = '1'
                    --                     THEN
                    --                        v_trantype := 'I';

                    --                        BEGIN
                    --                           UPDATE cms_preauth_transaction
                    --                              SET cpt_totalhold_amt =
                    --                                       cpt_totalhold_amt
                    --                                     + ROUND (i.mtt_amount, 2),
                    --                                  cpt_transaction_flag = 'I',
                    --                                  cpt_txn_amnt = ROUND (i.mtt_amount, 2),
                    --                                  cpt_expiry_date =
                    --                                     TO_DATE
                    --                                        (i.mtt_preauth_expry_date,
                    --                                         'yyyymmdd hh24miss'
                    --                                        ) v_preauth_date   --Need to discuss
                    --                            WHERE cpt_card_no = v_gethash
                    --                              AND cpt_rrn = i.mtt_rrn
                    --                              AND cpt_preauth_validflag = 'Y'
                    --                              AND cpt_expiry_flag = 'N'
                    --                              AND cpt_inst_code = prm_instcode;

                    --                           IF SQL%ROWCOUNT = 0
                    --                           THEN
                    --                              v_errmsg :=
                    --                                 'Problem while updating data in cms_preauth_transaction';
                    --                              RAISE excp_reject_rec;
                    --                           END IF;
                    --                        EXCEPTION
                    --                           WHEN excp_reject_rec
                    --                           THEN
                    --                              RAISE;
                    --                           WHEN OTHERS
                    --                           THEN
                    --                              v_errmsg :=
                    --                                    'Error while updating  cms_preauth_transaction '
                    --                                 || SUBSTR (SQLERRM, 1, 100);
                    --                              v_errcode := SQLCODE;
                    --                              RAISE excp_reject_rec;
                    --                        END;
                    --                     ELSE
                    --                        v_errmsg :=
                    --                           'Not a Valid Pre-Auth' || SUBSTR (SQLERRM, 1, 100);
                    --                        RAISE excp_reject_rec;
                    --                     END IF;
                    --                  ELSE
                     --v_trantype := 'N';
                     --------------------------------------------------------En 02Aug2013

                    if nvl(i.mtt_pend_holdamt,0) > 0      --Added to set flag for preauth transaction as per discussion 02-Aug-2013
                     then

                         v_preauth_validflag := 'Y';
                         v_preauth_expflag   := 'N';
                         v_tran_flag         := 'N';
                         v_comp_flag         := 'N';

                     else

                         v_preauth_validflag := 'N';
                         v_preauth_expflag   := 'Y';
                         v_tran_flag         := 'C';
                         v_comp_flag         := 'Y';

                    end if;
                   IF  i.mtt_transaction_code ='11' THEN   --Added By Dhiraj Gaikwad For Preauth Adjustment Transaction
                     BEGIN
                        INSERT INTO /*+ append */ cms_preauth_transaction
                                    (cpt_card_no, cpt_txn_amnt,
                                     cpt_expiry_date,
                                     cpt_sequence_no, cpt_preauth_validflag,
                                     cpt_inst_code, cpt_mbr_no,
                                     cpt_card_no_encr, cpt_completion_flag,
                                     cpt_approve_amt,
                                     cpt_rrn, cpt_txn_date,
                                     cpt_txn_time, cpt_terminalid,
                                     cpt_expiry_flag, cpt_totalhold_amt,
                                     cpt_transaction_flag,
                                     cpt_acct_no,
                                     cpt_mcc_code,
                                     cpt_ins_date,
                                     cpt_lupd_date,
                                     cpt_preauth_type  --2.1 onward changes
                                    )
                             VALUES (v_gethash, ROUND (i.mtt_amount, 2),
                                     TO_DATE (i.mtt_preauth_expry_date,
                                              'yyyymmdd hh24miss'
                                             ),
                                     i.mtt_rrn, v_preauth_validflag,--i.mtt_preauth_validflag, --02Aug2013
                                     prm_instcode, '000',
                                     v_encr_pan, v_comp_flag,--i.mtt_completion_flag,   --02Aug2013
                                     TRIM (TO_CHAR (ROUND (i.mtt_amount, 2),
                                                    '999999999999999990.99'
                                                   )
                                          ),
                                     i.mtt_rrn, i.mtt_business_date,
                                     i.mtt_business_time, i.mtt_terminal_id,
                                     v_preauth_expflag,--i.mtt_expiry_flag,                    --02Aug2013
                                      i.mtt_pend_holdamt,
                                     v_tran_flag,--i.mtt_transaction_flag,               --02Aug2013
                                     TRIM (i.mtt_account_number),
                                     i.mtt_mcccode,
                                     TO_DATE (i.mtt_posted_date,
                                              'yyyymmdd hh24miss'
                                             ),
                                     TO_DATE (i.mtt_posted_date,
                                              'yyyymmdd hh24miss'
                                             ),
                                      DECODE (i.mtt_crdr_flag, '1', 'C', 'D')  --2.1 onward changes              
                                    );
                     EXCEPTION
                        WHEN OTHERS
                        THEN
                           v_errmsg :=
                                 'Error while inserting into cms_preauth_transaction '
                              || SUBSTR (SQLERRM, 1, 100);
                           v_errcode := SQLCODE;
                           RAISE excp_reject_rec;
                     END;
                  --END IF;                    --02Aug2013
                   END iF  ;  --Added By Dhiraj Gaikwad For Preauth Adjustment Transaction
                  BEGIN
                     INSERT INTO /*+ append */ cms_preauth_trans_hist
                                 (cph_card_no, cph_txn_amnt,
                                  cph_expiry_date,
                                  cph_sequence_no, cph_preauth_validflag,
                                  cph_inst_code, cph_mbr_no,
                                  cph_card_no_encr, cph_completion_flag,
                                  cph_approve_amt,
                                  cph_rrn, cph_txn_date,
                                  cph_terminalid, cph_expiry_flag,
                                  cph_transaction_flag,
                                  cph_totalhold_amt, cph_transaction_rrn,
                                  cph_merchant_name, cph_merchant_city,
                                  cph_merchant_state,
                                  cph_delivery_channel,
                                  cph_tran_code,
                                  cph_panno_last4digit,
                                  cph_acct_no,
                                  cph_ins_date,
                                  cph_lupd_date,
                                  cph_preauth_type  --2.1 onward changes
                                 )
                          VALUES (v_gethash, ROUND (i.mtt_amount, 2),
                                  TO_DATE (i.mtt_preauth_expry_date,
                                           'yyyymmdd hh24miss'
                                          ),
                                  i.mtt_rrn,                 --Need to discuss
                                            v_preauth_validflag,--i.mtt_preauth_validflag, --02Aug2013
                                  prm_instcode, '000',
                                  v_encr_pan,v_comp_flag,--i.mtt_completion_flag,   --02Aug2013
                                  TRIM (TO_CHAR (ROUND (i.mtt_total_amount, 2),
                                                 '999999999999999990.99'
                                                )
                                       ),
                                  i.mtt_rrn, i.mtt_business_date,
                                  i.mtt_terminal_id, v_preauth_expflag,--i.mtt_expiry_flag,                    --02Aug2013
                                  v_tran_flag,--i.mtt_transaction_flag,     --02Aug2013
                                  i.mtt_pend_holdamt, i.mtt_rrn,
                                  i.mtt_merchant_name, i.mtt_merchant_city,
                                  i.mtt_atm_namelocation,
                                  i.mtt_delivery_channel,
                                  i.mtt_transaction_code,
                                  (SUBSTR (i.mtt_card_no,
                                           LENGTH (i.mtt_card_no) - 3
                                          )
                                  ),
                                  TRIM (i.mtt_account_number),
                                  TO_DATE (i.mtt_posted_date,
                                           'yyyymmdd hh24miss'
                                          ),
                                  TO_DATE (i.mtt_posted_date,
                                           'yyyymmdd hh24miss'
                                          ),
                                   DECODE (i.mtt_crdr_flag, '1', 'C', 'D')  --2.1 onward changes                    
                                 );
                  EXCEPTION
                     WHEN OTHERS
                     THEN
                        v_errmsg :=
                              'Error while inserting into cms_preauth_trans_hist '
                           || SUBSTR (SQLERRM, 1, 100);
                        v_errcode := SQLCODE;
                        RAISE excp_reject_rec;
                  END;
               EXCEPTION
                  WHEN excp_reject_rec
                  THEN
                     RAISE;
                  WHEN OTHERS
                  THEN
                     v_errmsg :=
                           'Problem while inserting preauth transaction details'
                        || SUBSTR (SQLERRM, 1, 100);
                     v_errcode := SQLCODE;
                     RAISE excp_reject_rec;
               END;
            ELSIF     i.mtt_transaction_code = '12'
                  AND i.mtt_delivery_channel = '02'
                  AND i.mtt_response_code = '00'
            THEN

                /*                                       --Commented as all completions needs to consider as matched completions 02-Aug-2013
                  IF i.mtt_matchcomp_flag = 'N'
                  THEN
                      BEGIN
                         INSERT INTO cms_preauth_transaction
                                     (cpt_card_no,
                                      cpt_txn_amnt,
                                      cpt_expiry_date,
                                      cpt_sequence_no, cpt_preauth_validflag,
                                      cpt_inst_code, cpt_mbr_no,
                                      cpt_card_no_encr, cpt_completion_flag,
                                      cpt_approve_amt,
                                      cpt_rrn, cpt_txn_date,
                                      cpt_txn_time, cpt_terminalid,
                                      cpt_expiry_flag, cpt_totalhold_amt,
                                      cpt_transaction_flag, cpt_acct_no,
                                      cpt_ins_date,
                                      cpt_lupd_date
                                     )
                              VALUES (v_gethash,
                                      TRIM (TO_CHAR (ROUND (i.mtt_total_amount, 2),
                                                     '999999999999999990.99'
                                                    )
                                           ),
                                      DECODE (i.mtt_preauth_datetime,
                                              NULL, NULL,
                                              TO_DATE (i.mtt_preauth_datetime,
                                                       'YYYYMMDD HH:24:MI:SS'
                                                      )
                                             ),
                                      i.mtt_rrn, 'N',
                                      prm_instcode, '000',
                                      v_encr_pan, 'Y',
                                      TRIM (TO_CHAR (ROUND (i.mtt_total_amount, 2),
                                                     '999999999999999990.99'
                                                    )
                                           ),
                                      i.mtt_rrn, i.mtt_business_date,
                                      i.mtt_business_time, i.mtt_terminal_id,
                                      'Y', '0.00',
                                      'C', TRIM (i.mtt_account_number),
                                      TO_DATE (i.mtt_posted_date,
                                               'yyyymmdd hh24miss'
                                              ),
                                      TO_DATE (i.mtt_posted_date,
                                               'yyyymmdd hh24miss'
                                              )
                                     );
                      EXCEPTION
                         WHEN OTHERS
                         THEN
                            v_errmsg :=
                                  'Error while inserting  cms_preauth_transaction '
                               || SUBSTR (SQLERRM, 1, 100);
                            v_errcode := SQLCODE;
                            RAISE excp_reject_rec;
                      END;
                  END IF;                            --02Aug2013

                 */                         --Commented as all completions needs to consider as matched completions   02-Aug-2013

               BEGIN
                  INSERT INTO /*+ append */ cms_preauth_trans_hist
                              (cph_card_no, cph_mbr_no, cph_inst_code,
                               cph_card_no_encr, cph_preauth_validflag,
                               cph_completion_flag,
                               cph_txn_amnt,
                               cph_approve_amt,
                               cph_rrn, cph_txn_date,
                               cph_txn_time, cph_orgnl_rrn,
                               cph_orgnl_txn_date,
                               cph_orgnl_txn_time,
                               cph_orgnl_card_no,
                               cph_terminalid, cph_orgnl_terminalid,
                               cph_comp_count,
                               cph_transaction_flag, cph_totalhold_amt,
                               cph_merchant_name,
                                                 --Added by Deepa on May-09-2012 for statement changes
                                                 cph_merchant_city,
                               cph_merchant_state,
                               cph_delivery_channel,
                               cph_tran_code,
                               cph_panno_last4digit,
                               cph_acct_no, cph_orgnl_mcccode,
                               -- Added on 27-Feb-2013 for FSS-781
                               cph_match_rrn,
                               cph_expiry_flag,
                               -- Added on 27-Feb-2013 for FSS-781
                               cph_ins_date,
                               cph_lupd_date,
                               cph_expiry_date,    -- 04JUL13 expiry date added
                               cph_preauth_type  --2.1 onward changes             
                              )
                       VALUES (v_gethash, '000', prm_instcode,
                               v_encr_pan, 'N',--i.mtt_preauth_validflag,    --02Aug2013
                               'Y',--i.mtt_completion_flag,                  --02Aug2013
                               ROUND (i.mtt_amount, 2),
                               TRIM (TO_CHAR (ROUND (i.mtt_total_amount, 2),
                                              '999999999999999990.99'
                                             )
                                    ),
                               i.mtt_rrn, i.mtt_business_date,
                               i.mtt_business_time, i.mtt_orgnl_rrn,
                               i.mtt_orgnl_businessdate,
                               i.mtt_orgnl_businesstime,
                               gethash (i.mtt_orgnl_cardnumber),
                               i.mtt_terminal_id, i.mtt_orgnl_terminalid,
                               i.mtt_completion_count,
                               'C',--i.mtt_transaction_flag,                  --02Aug2013
                               i.mtt_pend_holdamt,
                               i.mtt_merchant_name, i.mtt_merchant_city,
                               i.mtt_atm_namelocation,
                               i.mtt_delivery_channel,
                               i.mtt_transaction_code,
                               (SUBSTR (i.mtt_card_no,
                                        LENGTH (i.mtt_card_no) - 3,
                                        LENGTH (i.mtt_card_no)
                                       )
                               ),
                               TRIM (i.mtt_account_number), i.mtt_mcccode,
                               -- Need to discuss , as such there is no field for original MCC code in file format
                               DECODE (i.mtt_matchcomp_flag,
                                       'Y', i.mtt_orgnl_rrn,
                                       NULL
                                      ),
                               'Y',--i.mtt_expiry_flag,                        --02Aug2013
                               -- need to verify this logic for storing match RRN
                               TO_DATE (i.mtt_posted_date,
                                        'yyyymmdd hh24miss'),
                               TO_DATE (i.mtt_posted_date,
                                        'yyyymmdd hh24miss'),
                               TO_DATE (i.mtt_preauth_expry_date,
                                        'yyyymmdd hh24miss'
                                       ),
                               DECODE (i.mtt_crdr_flag, '1', 'C', 'D')  --2.1 onward changes                     
                              );
               EXCEPTION
                  WHEN OTHERS
                  THEN
                     v_errmsg :=
                           'Error while inserting into cms_preauth_trans_hist '
                        || SUBSTR (SQLERRM, 1, 100);
                     v_errcode := SQLCODE;
                     RAISE excp_reject_rec;
               END;
            END IF;

            IF     (   (    i.mtt_transaction_code = '38'
                        AND i.mtt_delivery_channel = '03'
                       )
                    OR (    i.mtt_transaction_code = '07'
                        AND i.mtt_delivery_channel IN ('10', '07')
                       )
                   )
               AND i.mtt_response_code = '00'
            THEN
               v_hash_pan_to := gethash (i.mtt_beneficiary_card_no);
               v_encr_pan_to := fn_emaps_main (i.mtt_beneficiary_card_no);

               BEGIN
                  SELECT cap_expry_date, cap_card_stat, cap_prod_code,
                         cap_card_type, cap_acct_no, cap_proxy_number
                    INTO v_to_card_expry, v_tocardstat, v_toprodcode,
                         v_tocardtype, v_toacct_no, v_tocard_proxy
                    FROM cms_appl_pan
                   WHERE cap_inst_code = prm_instcode
                     AND cap_pan_code = v_hash_pan_to;
               EXCEPTION
                  WHEN NO_DATA_FOUND
                  THEN
                     v_errmsg :=
                            'To card '|| i.mtt_beneficiary_card_no ||'not found in CMS' ; --Error message modified by Pankaj S. on 25-Sep-2013
                     v_migr_err_desc := 'EXCP_TOCARD_NOT_FOUND';
                     v_errcode := 'MIG-407';
                     RAISE excp_reject_rec;
                  WHEN OTHERS
                  THEN
                     v_errmsg :=
                           'Problem while selecting card detail for TO_CARD '
                        || i.mtt_beneficiary_card_no
                        || ' '
                        || SUBSTR (SQLERRM, 1, 100);
                     v_errcode := SQLCODE;
                     RAISE excp_reject_rec;                      -- Sn changed
               END;

               BEGIN
                  SELECT cam_acct_bal, cam_ledger_bal, cam_acct_no,
                         cam_type_code
                    INTO v_toacct_bal, v_toledger_bal, v_toacct_no,
                         v_toacct_type
                    FROM cms_acct_mast
                   WHERE cam_inst_code = prm_instcode
                     AND cam_acct_no = v_toacct_no;
               EXCEPTION
                  WHEN NO_DATA_FOUND
                  THEN
                     v_errmsg := 'Invalid To Account-' || v_toacct_no;
                     v_migr_err_desc := 'EXCP_TOACCT_NOT_FOUND';
                     v_errcode := 'MIG-408';
                     RAISE excp_reject_rec;
                  WHEN OTHERS
                  THEN
                     v_errmsg :=
                           'Error while selecting data from acct Master for To acct '
                        || SUBSTR (SQLERRM, 1, 100);
                     v_errcode := SQLCODE;
                     RAISE excp_reject_rec;
               END;

               IF     i.mtt_transaction_code = '38'
                  AND i.mtt_delivery_channel = '03'
               THEN
                  SELECT seq_migr_call_id.NEXTVAL
                    INTO v_call_id
                    FROM DUAL;

                  BEGIN                                              --04JUL13
                     v_req_id := v_call_id || TO_CHAR (SYSDATE, 'yyyymmdd');
                                                                    --04JUL13
                  EXCEPTION
                     WHEN OTHERS
                     THEN
                        v_errmsg :=
                              'Error occured while preparing Request id for card '
                           || i.mtt_card_no
                           || ' and RRN ' --Error message modified by Pankaj S. on 25-Sep-2013
                           || i.mtt_rrn
                           || ' '
                           || SUBSTR (SQLERRM, 1, 100);
                        v_errcode := SQLCODE;
                        RAISE excp_reject_rec;
                  END;

                  BEGIN
                     INSERT INTO /*+ append */ cms_c2ctxfr_transaction
                                 (cct_inst_code, cct_txn_code,
                                  cct_rrn, cct_del_chnl,
                                  cct_txn_amt, cct_from_card, cct_to_card,
                                  cct_date_time,
                                  cct_txn_date, cct_txn_time,
                                  cct_txn_status, cct_from_card_encr,
                                  cct_to_card_encr,
                                  cct_from_acct, cct_to_acct,
                                  cct_request_id,
                                  cct_ins_date,
                                  cct_ins_user,
                                  cct_lupd_date,
                                  cct_lupd_user, cct_txn_type,
                                  cct_prod_code, cct_maker_remarks,
                                  cct_response_id
                                 )
                          VALUES (prm_instcode, i.mtt_transaction_code,
                                  i.mtt_rrn, i.mtt_delivery_channel,
                                  i.mtt_amount, v_gethash, v_hash_pan_to,
                                  TO_DATE (   i.mtt_business_date
                                           || ' '
                                           || i.mtt_business_time,
                                           'YYYYMMDD HH24MISS'
                                          ),
                                  i.mtt_business_date, i.mtt_business_time,
                                  i.mtt_c2ctxn_status, v_encr_pan,
                                  v_encr_pan_to,
                                  TRIM (i.mtt_account_number), v_toacct_no,
                                  v_req_id,
                                  TO_DATE (i.mtt_posted_date,
                                           'yyyymmdd hh24miss'
                                          ),
                                  prm_ins_user,
                                  TO_DATE (i.mtt_posted_date,
                                           'yyyymmdd hh24miss'
                                          ),
                                  prm_ins_user, i.mtt_transaction_type,
                                  v_prod_code, i.mtt_remark,
                                  1
                                 );
                  EXCEPTION
                     WHEN OTHERS
                     THEN
                        v_errmsg :=
                              'Error occured while inserting into C2C txn table for card '
                           || i.mtt_card_no
                           || ' and RRN ' --Error message modified by Pankaj S. on 25-Sep-2013
                           || i.mtt_rrn
                           || ' '
                           || SUBSTR (SQLERRM, 1, 100);
                        v_errcode := SQLCODE;
                        RAISE excp_reject_rec;
                  END;
               END IF;
            END IF;

            IF    (    i.mtt_transaction_code IN ('10', '11')
                   AND i.mtt_delivery_channel = '07'
                  )
               OR (    i.mtt_transaction_code IN ('19', '20')
                   AND i.mtt_delivery_channel = '10'
                  )
               OR (    i.mtt_transaction_code IN ('04', '11')
                   AND i.mtt_delivery_channel = '13'
                  )
            THEN
               BEGIN
                  SELECT cam_acct_bal, cam_ledger_bal, cam_acct_no,
                         cam_type_code
                    INTO v_toacct_bal, v_toledger_bal, v_toacct_no,
                         v_toacct_type
                    FROM cms_acct_mast
                   WHERE cam_inst_code = prm_instcode
                     AND cam_acct_no = i.mtt_topup_acctno;
               EXCEPTION
                  WHEN NO_DATA_FOUND
                  THEN
                     v_errmsg :=
                               'Invalid Topup Account-' || i.mtt_topup_acctno;
                     v_migr_err_desc := 'EXCP_TOPUPACCT_NOT_FOUND';
                     v_errcode := 'MIG-409';
                     RAISE excp_reject_rec;
                  WHEN OTHERS
                  THEN
                     v_errmsg :=
                           'Error while selecting data from acct Master for To acct '
                        || SUBSTR (SQLERRM, 1, 100);
                     v_errcode := SQLCODE;
                     RAISE excp_reject_rec;
               END;
            END IF;

-------------------------------------------------------
--En Added by Pankaj S. on 31-May-2013 to log C2C txns
-------------------------------------------------------
            IF     (   NVL (i.mtt_amount, 0) > 0
                    OR NVL (i.mtt_tranfee_amount, 0) > 0
                   )
               AND i.mtt_response_code = '00' -- only if Financial transaction
            THEN


               IF (   (    i.mtt_delivery_channel IN ('02', '03')
                       AND i.mtt_transaction_code <> '11'
                      )
                   OR (i.mtt_delivery_channel NOT IN ('02', '03'))   --04JUL13
                   OR (    i.mtt_delivery_channel = '03'
                       AND i.mtt_transaction_code = '38'
                       AND i.mtt_c2ctxn_status NOT IN ('N', 'R')
                      )
                  )
               THEN
                  v_check := 'Y';                               -- Sn 04JUL13

                  IF (    i.mtt_delivery_channel = '03'
                      AND i.mtt_transaction_code = '38'
                      AND i.mtt_c2ctxn_status IN ('N', 'R')
                     )
                  THEN
                     v_check := 'N';
                  END IF;                                         --En 04JUL13

                  IF v_check = 'Y'
                  THEN
                     IF     NVL (i.mtt_amount, 0) > 0
                        AND i.mtt_crdr_flag IN (0, 1)
                        AND NVL (i.mtt_tranfee_amount, 0) = 0
                     THEN

                        IF i.mtt_crdr_flag IN ('0','1') THEN
                        SELECT CASE
                                  WHEN i.mtt_crdr_flag = 0
                                     THEN i.mtt_ledger_balance + i.mtt_total_amount
                                  WHEN i.mtt_crdr_flag = 1
                                     THEN i.mtt_ledger_balance - i.mtt_total_amount
                               END
                          INTO v_opening_bal
                          FROM DUAL;
                        END IF;


                        BEGIN
                           INSERT INTO /*+ append */ cms_statements_log
                                       (csl_rrn, csl_delivery_channel,
                                        csl_txn_code,
                                        csl_trans_type,
                                        csl_business_date,
                                        csl_business_time, csl_pan_no,
                                        csl_merchant_name,
                                        csl_merchant_city, csl_trans_amount,
                                        csl_acct_no,
                                        csl_opening_bal,
                                        csl_closing_balance, csl_auth_id,
                                        csl_trans_narrration,
                                        csl_pan_no_encr,
                                        csl_trans_date,
                                        txn_fee_flag,
                                        csl_inst_code,
                                        csl_lupd_date,
                                        csl_lupd_user,
                                        csl_ins_date,
                                        csl_ins_user,
                                        --Sn Added on 29-May-2013 by Pankaj S.
                                        csl_panno_last4digit,
                                        csl_prod_code, csl_acct_type,
                                        csl_to_acctno
                                       --En Added on 29-May-2013 by Pankaj S.
                                       )
                                VALUES (i.mtt_rrn, i.mtt_delivery_channel,
                                        i.mtt_transaction_code,
                                        DECODE (i.mtt_crdr_flag,
                                                '0', 'DR',
                                                '1', 'CR'
                                               --,'2', 'NA'
                                               ),
                                        i.mtt_business_date,
                                        i.mtt_business_time, v_gethash,
                                        i.mtt_merchant_name,
                                        i.mtt_merchant_city, i.mtt_amount,
                                        TRIM (i.mtt_account_number),
                                        --Sn Modified by Pankaj S. to use Ledger balance instead of acct balnce
                                        v_opening_bal,--i.mtt_beforetxn_ledger_bal,  02Aug2013
                                        --i.mtt_beforetxn_avail_bal,
                                        i.mtt_ledger_balance,
                                                             --i.mtt_account_balance,
                                                                 --En Modified by Pankaj S. to use Ledger balance instead of acct balnce
                                                             i.mtt_auth_id,
                                        i.mtt_narration,
                                        v_encr_pan,
                                        TO_DATE (   i.mtt_business_date
                                                 || ' '
                                                 || i.mtt_business_time,
                                                 'yyyymmdd hh24miss'
                                                ),
                                        CASE
                                           WHEN     i.mtt_delivery_channel =
                                                                          '03'
                                                AND i.mtt_transaction_code =
                                                                          '12'
                                              THEN 'Y'
                                           WHEN     i.mtt_delivery_channel =
                                                                          '05'
                                                AND i.mtt_transaction_code =
                                                                          '17'
                                              THEN 'Y'
                                           ELSE 'N'
                                        END,
                                        prm_instcode,
                                        TO_DATE (i.mtt_posted_date,
                                                 'yyyymmdd hh24miss'
                                                ),
                                        prm_ins_user,
                                        TO_DATE (i.mtt_posted_date,
                                                 'yyyymmdd hh24miss'
                                                ),
                                        prm_ins_user,

                                        --Sn Added on 29-May-2013 by Pankaj S.
                                        (SUBSTR (i.mtt_card_no,
                                                 LENGTH (i.mtt_card_no) - 3
                                                )
                                        ),
                                        v_prod_code, v_acct_type,
                                        CASE
                                           WHEN     i.mtt_delivery_channel =
                                                                          '03'
                                                AND i.mtt_transaction_code =
                                                                          '38'
                                                AND i.mtt_c2ctxn_status = 'A'
                                              THEN v_toacct_no
                                           WHEN     i.mtt_delivery_channel IN
                                                                 ('10', '07')
                                                AND i.mtt_transaction_code =
                                                                          '07'
                                              THEN v_toacct_no
                                           WHEN     i.mtt_delivery_channel =
                                                                          '07'
                                                AND i.mtt_transaction_code IN
                                                                 ('10', '11')
                                              THEN i.mtt_topup_acctno
                      -- changed from  v_acct_no to i.MTT_TOPUP_ACCTNO 04JUL13
                                           WHEN     i.mtt_delivery_channel =
                                                              '10'
                                                                  --SN 04JUL13
                                                AND i.mtt_transaction_code IN
                                                                 ('19', '20')
                                              THEN i.mtt_topup_acctno
                                           WHEN     i.mtt_delivery_channel =
                                                                          '13'
                                                AND i.mtt_transaction_code IN
                                                                 ('04', '11')
                                              THEN i.mtt_topup_acctno
                                                                  --EN 04JUL13
                                           ELSE ''
                                        END
                                       --En Added on 29-May-2013 by Pankaj S.
                                       );
                        EXCEPTION
                           WHEN OTHERS
                           THEN
                              v_errmsg :=
                                    'Error while creating entry into statementlog for tran amount ' --Error message modified by Pankaj S. on 25-Sep-2013
                                 || ' for card '
                                 || i.mtt_card_no
                                 || ' and RRN ' --Error message modified by Pankaj S. on 25-Sep-2013
                                 || i.mtt_rrn
                                 || ' '
                                 || SUBSTR (SQLERRM, 1, 100);
                              v_errcode := SQLCODE;
                              RAISE excp_reject_rec;
                        END;
                     ELSIF     NVL (i.mtt_amount, 0) > '0'
                           AND i.mtt_crdr_flag = '0'
                           AND NVL (i.mtt_tranfee_amount, '0') > '0'
                     THEN

                       v_opening_bal:=(i.mtt_ledger_balance+NVL (i.mtt_amount, 0))+NVL (i.mtt_tranfee_amount, '0');


                        BEGIN                 -- Inserting transaction amount
                           INSERT INTO /*+ append */ cms_statements_log
                                       (csl_rrn, csl_delivery_channel,
                                        csl_txn_code,
                                        csl_trans_type,
                                        csl_business_date,
                                        csl_business_time, csl_pan_no,
                                        csl_merchant_name,
                                        csl_merchant_city, csl_trans_amount,
                                        csl_acct_no,
                                        csl_opening_bal,
                                        csl_closing_balance,
                                        csl_auth_id, csl_trans_narrration,
                                        csl_pan_no_encr,
                                        csl_trans_date,
                                        txn_fee_flag, csl_inst_code,
                                        csl_lupd_date,
                                        csl_lupd_user,
                                        csl_ins_date,
                                        csl_ins_user,
                                        --Sn Added on 29-May-2013 by Pankaj S.
                                        csl_panno_last4digit,
                                        csl_prod_code, csl_acct_type,
                                        csl_to_acctno
                                       --En Added on 29-May-2013 by Pankaj S.
                                       )
                                VALUES (i.mtt_rrn, i.mtt_delivery_channel,
                                        i.mtt_transaction_code,
                                        DECODE (i.mtt_reversal_code,
                                                0, 'DR',
                                                'CR'
                                               ),
                                        i.mtt_business_date,
                                        i.mtt_business_time, v_gethash,
                                        i.mtt_merchant_name,
                                        i.mtt_merchant_city, i.mtt_amount,
                                        TRIM (i.mtt_account_number),
                                        v_opening_bal,--i.mtt_beforetxn_ledger_bal,  02Aug2013
                                        DECODE
                                            (i.mtt_reversal_code,
                                             0,
                                               --04JUL13 reversal code checked
                                               v_opening_bal--i.mtt_beforetxn_ledger_bal  02Aug2013
                                             - NVL (i.mtt_amount, 0),
                                               v_opening_bal--i.mtt_beforetxn_ledger_bal  02Aug2013
                                             + NVL (i.mtt_amount, 0)
                                            ),
                                        i.mtt_auth_id, i.mtt_narration,
                                        v_encr_pan,
                                        TO_DATE (   i.mtt_business_date
                                                 || ' '
                                                 || i.mtt_business_time,
                                                 'yyyymmdd hh24miss'
                                                ),
                                        'N', prm_instcode,
                                        TO_DATE (i.mtt_posted_date,
                                                 'yyyymmdd hh24miss'
                                                ),
                                        prm_ins_user,
                                        TO_DATE (i.mtt_posted_date,
                                                 'yyyymmdd hh24miss'
                                                ),
                                        prm_ins_user,

                                        --Sn Added on 29-May-2013 by Pankaj S.
                                        (SUBSTR (i.mtt_card_no,
                                                 LENGTH (i.mtt_card_no) - 3
                                                )
                                        ),
                                        v_prod_code, v_acct_type,
                                        CASE
                                           WHEN     i.mtt_delivery_channel =
                                                                          '03'
                                                AND i.mtt_transaction_code =
                                                                          '38'
                                                AND i.mtt_c2ctxn_status = 'A'
                                              THEN v_toacct_no
                                           WHEN     i.mtt_delivery_channel IN
                                                                 ('10', '07')
                                                AND i.mtt_transaction_code =
                                                                          '07'
                                              THEN v_toacct_no
                                           WHEN     i.mtt_delivery_channel =
                                                                          '07'
                                                AND i.mtt_transaction_code IN
                                                                 ('10', '11')
                                              THEN i.mtt_topup_acctno
                      -- changed from  v_acct_no to i.MTT_TOPUP_ACCTNO 04JUL13
                                           WHEN     i.mtt_delivery_channel =
                                                              '10'
                                                                  --SN 04JUL13
                                                AND i.mtt_transaction_code IN
                                                                 ('19', '20')
                                              THEN i.mtt_topup_acctno
                                           WHEN     i.mtt_delivery_channel =
                                                                          '13'
                                                AND i.mtt_transaction_code IN
                                                                 ('04', '11')
                                              THEN i.mtt_topup_acctno
                                                                  --EN 04JUL13
                                           ELSE ''
                                        END
                                       --En Added on 29-May-2013 by Pankaj S.
                                       );
                        EXCEPTION
                           WHEN OTHERS
                           THEN
                              v_errmsg :=
                                    'Error while inserting into statementlog for txn amount(DR) '
                                 || ' for card '
                                 || i.mtt_card_no
                                 || ' and RRN ' --Error message modified by Pankaj S. on 25-Sep-2013
                                 || i.mtt_rrn
                                 || ' '
                                 || SUBSTR (SQLERRM, 1, 100);
                              v_errcode := SQLCODE;
                              RAISE excp_reject_rec;
                        END;

                        BEGIN                          -- Inserting fee amount
                           INSERT INTO /*+ append */ cms_statements_log
                                       (csl_rrn, csl_delivery_channel,
                                        csl_txn_code,
                                        csl_trans_type,
                                        csl_business_date,
                                        csl_business_time, csl_pan_no,
                                        csl_merchant_name,
                                        csl_merchant_city,
                                        csl_trans_amount,
                                        csl_acct_no,
                                        csl_opening_bal,
                                        csl_closing_balance, csl_auth_id,
                                        csl_trans_narrration,
                                        csl_pan_no_encr,
                                        csl_trans_date,
                                        txn_fee_flag, csl_inst_code,
                                        csl_lupd_date,
                                        csl_lupd_user,
                                        csl_ins_date,
                                        csl_ins_user,
                                        --Sn Added on 29-May-2013 by Pankaj S.
                                        csl_panno_last4digit,
                                        csl_prod_code, csl_acct_type
                                       --En Added on 29-May-2013 by Pankaj S.
                                       )
                                VALUES (i.mtt_rrn, i.mtt_delivery_channel,
                                        i.mtt_transaction_code,
                                        DECODE
                                           (i.mtt_reversal_code,
                                               --04JUL13 reversal code checked
                                            '0', 'DR',
                                            '1', 'CR'
                                           ),
                                        i.mtt_business_date,
                                        i.mtt_business_time, v_gethash,
                                        i.mtt_merchant_name,
                                        i.mtt_merchant_city,
                                        i.mtt_tranfee_amount,
                                        TRIM (i.mtt_account_number),
                                        DECODE (i.mtt_reversal_code,
                                                0, v_opening_bal--i.mtt_beforetxn_ledger_bal  02Aug2013
                                                 - NVL (i.mtt_amount, 0),
                                                  v_opening_bal--i.mtt_beforetxn_ledger_bal  02Aug2013
                                                + NVL (i.mtt_amount, 0)
                                               ),
                                        i.mtt_ledger_balance, i.mtt_auth_id,
                                        'Fee Debited For ' || i.mtt_narration,
                                        v_encr_pan,
                                        TO_DATE (   i.mtt_business_date
                                                 || ' '
                                                 || i.mtt_business_time,
                                                 'yyyymmdd hh24miss'
                                                ),
                                        'Y', prm_instcode,
                                        TO_DATE (i.mtt_posted_date,
                                                 'yyyymmdd hh24miss'
                                                ),
                                        prm_ins_user,
                                        TO_DATE (i.mtt_posted_date,
                                                 'yyyymmdd hh24miss'
                                                ),
                                        prm_ins_user,

                                        --Sn Added on 29-May-2013 by Pankaj S.
                                        (SUBSTR (i.mtt_card_no,
                                                 LENGTH (i.mtt_card_no) - 3
                                                )
                                        ),
                                        v_prod_code, v_acct_type
                                       --En Added on 29-May-2013 by Pankaj S.
                                       );
                        EXCEPTION
                           WHEN OTHERS
                           THEN
                              v_errmsg :=
                                    'Error while inserting into statementlog for fee amount(DR) '
                                 || ' for card '
                                 || i.mtt_card_no
                                 || ' and RRN ' --Error message modified by Pankaj S. on 25-Sep-2013
                                 || i.mtt_rrn
                                 || ' '
                                 || SUBSTR (SQLERRM, 1, 100);
                              v_errcode := SQLCODE;
                              RAISE excp_reject_rec;
                        END;
                     ELSIF     NVL (i.mtt_amount, 0) > '0'
                           AND i.mtt_crdr_flag = '1'
                           AND NVL (i.mtt_tranfee_amount, '0') > '0'
                     THEN

                       v_opening_bal:=(i.mtt_ledger_balance-NVL (i.mtt_amount, 0))+NVL (i.mtt_tranfee_amount, '0');

                        BEGIN                 -- Inserting transaction amount
                           INSERT INTO /*+ append */ cms_statements_log
                                       (csl_rrn, csl_delivery_channel,
                                        csl_txn_code, csl_trans_type,
                                        csl_business_date,
                                        csl_business_time, csl_pan_no,
                                        csl_merchant_name,
                                        csl_merchant_city, csl_trans_amount,
                                        csl_acct_no,
                                        csl_opening_bal,
                                        csl_closing_balance,
                                        csl_auth_id, csl_trans_narrration,
                                        csl_pan_no_encr,
                                        csl_trans_date,
                                        txn_fee_flag, csl_inst_code,
                                        csl_lupd_date,
                                        csl_lupd_user,
                                        csl_ins_date,
                                        csl_ins_user,
                                        --Sn Added on 29-May-2013 by Pankaj S.
                                        csl_panno_last4digit,
                                        csl_prod_code, csl_acct_type
                                       --En Added on 29-May-2013 by Pankaj S.
                                       )
                                VALUES (i.mtt_rrn, i.mtt_delivery_channel,
                                        i.mtt_transaction_code, 'CR',
                                                                    -- 04JUL13
                                        i.mtt_business_date,
                                        i.mtt_business_time, v_gethash,
                                        i.mtt_merchant_name,
                                        i.mtt_merchant_city, i.mtt_amount,
                                        TRIM (i.mtt_account_number),
                                        --Sn Modified by Pankaj S. to use Ledger balance instead of acct balnce
                                        v_opening_bal,--i.mtt_beforetxn_ledger_bal  02Aug2013
                                        v_opening_bal--i.mtt_beforetxn_ledger_bal   02Aug2013
                                        + NVL (i.mtt_amount, 0),
                                        --En Modified by Pankaj S. to use Ledger balance instead of acct balnce
                                        i.mtt_auth_id, i.mtt_narration,
                                        v_encr_pan,
                                        TO_DATE (   i.mtt_business_date
                                                 || ' '
                                                 || i.mtt_business_time,
                                                 'yyyymmdd hh24miss'
                                                ),
                                        'N', prm_instcode,
                                        TO_DATE (i.mtt_posted_date,
                                                 'yyyymmdd hh24miss'
                                                ),
                                        prm_ins_user,
                                        TO_DATE (i.mtt_posted_date,
                                                 'yyyymmdd hh24miss'
                                                ),
                                        prm_ins_user,

                                        --Sn Added on 29-May-2013 by Pankaj S.
                                        (SUBSTR (i.mtt_card_no,
                                                 LENGTH (i.mtt_card_no) - 3
                                                )
                                        ),
                                        v_prod_code, v_acct_type
                                       --En Added on 29-May-2013 by Pankaj S.
                                       );
                        EXCEPTION
                           WHEN OTHERS
                           THEN
                              v_errmsg :=
                                    'Error while inserting in statementlog for txn amount(CR) '
                                 || ' for card '
                                 || i.mtt_card_no
                                 || ' and RRN ' --Error message modified by Pankaj S. on 25-Sep-2013
                                 || i.mtt_rrn
                                 || ' '
                                 || SUBSTR (SQLERRM, 1, 100);
                              v_errcode := SQLCODE;
                              RAISE excp_reject_rec;
                        END;

                        BEGIN                          -- Inserting fee amount
                           INSERT INTO /*+ append */ cms_statements_log
                                       (csl_rrn, csl_delivery_channel,
                                        csl_txn_code,
                                        csl_trans_type,
                                        csl_business_date,
                                        csl_business_time, csl_pan_no,
                                        csl_merchant_name,
                                        csl_merchant_city,
                                        csl_trans_amount,
                                        csl_acct_no,
                                        csl_opening_bal,
                                        csl_closing_balance, csl_auth_id,
                                        csl_trans_narrration,
                                        csl_pan_no_encr,
                                        csl_trans_date,
                                        txn_fee_flag, csl_inst_code,
                                        csl_lupd_date,
                                        csl_lupd_user,
                                        csl_ins_date,
                                        csl_ins_user,
                                        --Sn Added on 29-May-2013 by Pankaj S.
                                        csl_panno_last4digit,
                                        csl_prod_code, csl_acct_type
                                       --En Added on 29-May-2013 by Pankaj S.
                                       )
                                VALUES (i.mtt_rrn, i.mtt_delivery_channel,
                                        i.mtt_transaction_code,
                                        DECODE
                                           (i.mtt_reversal_code,
                                                -- reversal code added 04JUL13
                                            0, 'DR',
                                            'CR'
                                           ),
                                        i.mtt_business_date,
                                        i.mtt_business_time, v_gethash,
                                        i.mtt_merchant_name,
                                        i.mtt_merchant_city,
                                        i.mtt_tranfee_amount,
                                        TRIM (i.mtt_account_number),
                                        v_opening_bal--i.mtt_beforetxn_ledger_bal   02Aug2013
                                        + NVL (i.mtt_amount, 0),
                                        decode(nvl(i.mtt_reverse_fee_amt,0),0,
                                               i.mtt_ledger_balance,
                                               (v_opening_bal--i.mtt_beforetxn_ledger_bal   02Aug2013
                                                + NVL (i.mtt_amount, 0))+i.mtt_tranfee_amount
                                               ),
                                        --i.mtt_ledger_balance,
                                        i.mtt_auth_id,
                                        DECODE
                                           (i.mtt_reversal_code,
                                                -- reversal code added 04JUL13
                                            0,  'Fee Debited For '
                                             || i.mtt_narration,
                                               'Fee Credited For '
                                            || i.mtt_narration
                                           ),
                                        v_encr_pan,
                                        TO_DATE (   i.mtt_business_date
                                                 || ' '
                                                 || i.mtt_business_time,
                                                 'yyyymmdd hh24miss'
                                                ),
                                        'Y', prm_instcode,
                                        TO_DATE (i.mtt_posted_date,
                                                 'yyyymmdd hh24miss'
                                                ),
                                        prm_ins_user,
                                        TO_DATE (i.mtt_posted_date,
                                                 'yyyymmdd hh24miss'
                                                ),
                                        prm_ins_user,

                                        --Sn Added on 29-May-2013 by Pankaj S.
                                        (SUBSTR (i.mtt_card_no,
                                                 LENGTH (i.mtt_card_no) - 3
                                                )
                                        ),
                                        v_prod_code, v_acct_type
                                       --En Added on 29-May-2013 by Pankaj S.
                                       );
                        EXCEPTION
                           WHEN OTHERS
                           THEN
                              v_errmsg :=
                                    'Error while inserting in statementlog for fee amount(CR) '
                                 || ' for card '
                                 || i.mtt_card_no
                                 || ' and RRN '--Error message modified by Pankaj S. on 25-Sep-2013
                                 || i.mtt_rrn
                                 || ' '
                                 || SUBSTR (SQLERRM, 1, 100);
                              v_errcode := SQLCODE;
                              RAISE excp_reject_rec;
                        END;

                        if i.mtt_reversal_code <> 0 and nvl(i.mtt_reverse_fee_amt,0)>0
                        then

                          --v_openeing_bal
                           v_opening_bal:= (v_opening_bal--i.mtt_beforetxn_ledger_bal   02Aug2013
                                             + NVL (i.mtt_amount, 0))+i.mtt_tranfee_amount;



                            BEGIN                             -- Inserting fee amount
                               INSERT INTO /*+ append */ cms_statements_log
                                           (csl_rrn, csl_delivery_channel,
                                            csl_txn_code,
                                            csl_trans_type,
                                            csl_business_date,
                                            csl_business_time, csl_pan_no,
                                            csl_merchant_name,
                                            csl_merchant_city,
                                            csl_trans_amount,
                                            csl_acct_no,
                                            csl_opening_bal,
                                            csl_closing_balance, csl_auth_id,
                                            csl_trans_narrration,
                                            csl_pan_no_encr,
                                            csl_trans_date,
                                            txn_fee_flag, csl_inst_code,
                                            csl_lupd_date,
                                            csl_lupd_user,
                                            csl_ins_date,
                                            csl_ins_user,
                                            --Sn Added on 29-May-2013 by Pankaj S.
                                            csl_panno_last4digit,
                                            csl_prod_code, csl_acct_type
                                           --En Added on 29-May-2013 by Pankaj S.
                                           )
                                    VALUES (i.mtt_rrn, i.mtt_delivery_channel,
                                            i.mtt_transaction_code,
                                            'DR',
                                            i.mtt_business_date,
                                            i.mtt_business_time,
                                            v_gethash,
                                            i.mtt_merchant_name,
                                            i.mtt_merchant_city,
                                            i.mtt_reverse_fee_amt,
                                            TRIM (i.mtt_account_number),
                                            v_opening_bal,--v_openeing_bal, 02Aug2013
                                            i.mtt_ledger_balance,
                                            i.mtt_auth_id,
                                            'RVSL - Fee Debited For '||i.mtt_narration,
                                            v_encr_pan,
                                            TO_DATE (   i.mtt_business_date
                                                     || ' '
                                                     || i.mtt_business_time,
                                                     'yyyymmdd hh24miss'
                                                    ),
                                            'Y', prm_instcode,
                                            TO_DATE (i.mtt_posted_date,
                                                     'yyyymmdd hh24miss'
                                                    ),
                                            prm_ins_user,
                                            TO_DATE (i.mtt_posted_date,
                                                     'yyyymmdd hh24miss'
                                                    ),
                                            prm_ins_user,

                                            --Sn Added on 29-May-2013 by Pankaj S.
                                            (SUBSTR (i.mtt_card_no,
                                                     LENGTH (i.mtt_card_no) - 3
                                                    )
                                            ),
                                            v_prod_code, v_acct_type
                                           --En Added on 29-May-2013 by Pankaj S.
                                           );
                            EXCEPTION
                               WHEN OTHERS
                               THEN
                                  v_errmsg :=
                                        'Error while inserting in statementlog for reversal fee amount '
                                     || ' for card '
                                     || i.mtt_card_no
                                     || ' and RRN ' --Error message modified by Pankaj S. on 25-Sep-2013
                                     || i.mtt_rrn
                                     || ' '
                                     || SUBSTR (SQLERRM, 1, 100);
                                  v_errcode := SQLCODE;
                                  RAISE excp_reject_rec;
                            END;

                        end if;

                     ELSIF     NVL (i.mtt_amount, 0) = '0'
                           AND i.mtt_crdr_flag IN ('0', '1', '2')
                           AND NVL (i.mtt_tranfee_amount, '0') > '0'
                     THEN
                        BEGIN                         -- Inserting fee amount
                           INSERT INTO /*+ append */ cms_statements_log
                                       (csl_rrn, csl_delivery_channel,
                                        csl_txn_code,
                                        csl_trans_type,
                                        csl_business_date,
                                        csl_business_time, csl_pan_no,
                                        csl_merchant_name,
                                        csl_merchant_city,
                                        csl_trans_amount,
                                        csl_acct_no,
                                        csl_opening_bal,
                                        csl_closing_balance, csl_auth_id,
                                        csl_trans_narrration,
                                        csl_pan_no_encr,
                                        csl_trans_date,
                                        txn_fee_flag, csl_inst_code,
                                        csl_lupd_date,
                                        csl_lupd_user,
                                        csl_ins_date,
                                        csl_ins_user,
                                        --Sn Added on 29-May-2013 by Pankaj S.
                                        csl_panno_last4digit,
                                        csl_prod_code, csl_acct_type
                                       --En Added on 29-May-2013 by Pankaj S.
                                       )
                                VALUES (i.mtt_rrn, i.mtt_delivery_channel,
                                        i.mtt_transaction_code,
                                        DECODE (i.mtt_crdr_flag,
                                                '0', 'DR',
                                                '1', 'CR',
                                                '2', 'NA'
                                               ),
                                        i.mtt_business_date,
                                        i.mtt_business_time, v_gethash,
                                        i.mtt_merchant_name,
                                        i.mtt_merchant_city,
                                        i.mtt_tranfee_amount,
                                        TRIM (i.mtt_account_number),
                                        --Sn Modified by Pankaj S. to use Ledger balance instead of acct balnce
                                        i.mtt_ledger_balance+i.mtt_tranfee_amount,--i.mtt_beforetxn_ledger_bal, 02Aug2013
                                        --i.mtt_beforetxn_avail_bal,
                                        i.mtt_ledger_balance,
                                                             --i.mtt_account_balance,
                                                              --En Modified by Pankaj S. to use Ledger balance instead of acct balnce
                                                             i.mtt_auth_id,
                                           DECODE
                                              (i.mtt_crdr_flag,
                                               '0', 'Fee Debited For ',
                                               '2', 'Fee Debited For ',
                                                                  -- 04JUL2013
                                               'Fee Credited For '
                                              )
                                        || i.mtt_narration,
                                        v_encr_pan,
                                        TO_DATE (   i.mtt_business_date
                                                 || ' '
                                                 || i.mtt_business_time,
                                                 'yyyymmdd hh24miss'
                                                ),
                                        'Y', prm_instcode,
                                        TO_DATE (i.mtt_posted_date,
                                                 'yyyymmdd hh24miss'
                                                ),
                                        prm_ins_user,
                                        TO_DATE (i.mtt_posted_date,
                                                 'yyyymmdd hh24miss'
                                                ),
                                        prm_ins_user,

                                        --Sn Added on 29-May-2013 by Pankaj S.
                                        (SUBSTR (i.mtt_card_no,
                                                 LENGTH (i.mtt_card_no) - 3
                                                )
                                        ),
                                        v_prod_code, v_acct_type
                                       --En Added on 29-May-2013 by Pankaj S.
                                       );
                        EXCEPTION
                           WHEN OTHERS
                           THEN
                              v_errmsg :=
                                    'Error while inserting in statementlog only for fee amount '
                                 || ' for card '
                                 || i.mtt_card_no
                                 || ' and RRN ' --Error message modified by Pankaj S. on 25-Sep-2013
                                 || i.mtt_rrn
                                 || ' '
                                 || SUBSTR (SQLERRM, 1, 100);
                              v_errcode := SQLCODE;
                              RAISE excp_reject_rec;
                        END;
                     END IF;
                  END IF;

                  IF    (    i.mtt_delivery_channel = '03'
                         AND i.mtt_transaction_code = '38'
                         AND i.mtt_c2ctxn_status = 'A'
                        )
                     OR (    i.mtt_transaction_code = '07'
                         AND i.mtt_delivery_channel IN ('10', '07')
                        )
                     OR (    i.mtt_transaction_code IN ('10', '11')
                         AND i.mtt_delivery_channel = '07'
                        )
                     OR (    i.mtt_transaction_code IN ('04', '11')
                         AND i.mtt_delivery_channel = '13'
                        )
                     OR (    i.mtt_transaction_code IN ('20', '19')
                         AND i.mtt_delivery_channel = '10'
                        )
                  THEN
                     IF    (    i.mtt_transaction_code IN ('10', '11')
                            AND i.mtt_delivery_channel = '07'
                           )
                        OR (    i.mtt_transaction_code IN ('04', '11')
                            AND i.mtt_delivery_channel = '13'
                           )
                        OR (    i.mtt_transaction_code IN ('20', '19')
                            AND i.mtt_delivery_channel = '10'
                           )
                     THEN
                        set_gethash := v_gethash;
                        set_card_no := SUBSTR (i.mtt_card_no, -4);
                        set_v_prod_code := v_prod_code;
                        set_v_acct_type := v_acct_type;
                        set_v_encr_pan := v_encr_pan;
                     ELSE
                        set_gethash := v_hash_pan_to;
                        set_card_no :=
                           SUBSTR (i.mtt_beneficiary_card_no,
                                   LENGTH (i.mtt_beneficiary_card_no) - 3
                                  );
                        set_v_prod_code := v_toprodcode;
                        set_v_acct_type := v_toacct_type;
                        set_v_encr_pan := v_encr_pan_to;
                     END IF;

                     BEGIN
                        INSERT INTO /*+ append */ cms_statements_log
                                    (csl_rrn, csl_delivery_channel,
                                     csl_txn_code,
                                     csl_trans_type, csl_business_date,
                                     csl_business_time, csl_pan_no,
                                     csl_merchant_name,
                                     csl_merchant_city, csl_trans_amount,
                                     csl_acct_no,
                                     csl_opening_bal,
                                     csl_closing_balance,
                                     csl_auth_id,
                                     csl_trans_narrration,
                                     csl_pan_no_encr,
                                     csl_trans_date,
                                     txn_fee_flag, csl_inst_code,
                                     csl_lupd_date,
                                     csl_lupd_user,
                                     csl_ins_date,
                                     csl_ins_user,
                                                  --Sn Added on 29-May-2013 by Pankaj S.
                                                  csl_panno_last4digit,
                                     csl_prod_code, csl_acct_type
                                    --En Added on 29-May-2013 by Pankaj S.
                                    )
                             VALUES (i.mtt_rrn, i.mtt_delivery_channel,
                                     CASE
                                        WHEN i.mtt_delivery_channel = '03'
                                           THEN '39'
                                        ELSE i.mtt_transaction_code
                                     END,
                                     'CR', i.mtt_business_date,
                                     i.mtt_business_time, set_gethash,
                                     i.mtt_merchant_name,
                                     i.mtt_merchant_city, i.mtt_amount,
                                     v_toacct_no,
                                     --Sn Modified  to use Ledger balance instead of acct balnce
                                     i.mtt_beftxn_topupcard_ledgerbal,
                                     --i.mtt_beforetxn_avail_bal,
                                     i.mtt_topupcard_ledgerbal,
                                                      --i.mtt_account_balance,
                                     --En Modified to use Ledger balance instead of acct balnce
                                     i.mtt_auth_id,
                                     DECODE (i.mtt_transaction_code,
                                             '38', i.mtt_narration,
                                             i.mtt_narration
                                            ),
                                     set_v_encr_pan,
                                     TO_DATE (   i.mtt_business_date
                                              || ' '
                                              || i.mtt_business_time,
                                              'yyyymmdd hh24miss'
                                             ),
                                     'N', prm_instcode,
                                     TO_DATE (i.mtt_posted_date,
                                              'yyyymmdd hh24miss'
                                             ),
                                     prm_ins_user,
                                     TO_DATE (i.mtt_posted_date,
                                              'yyyymmdd hh24miss'
                                             ),
                                     prm_ins_user,
                                                  --Sn Added on 29-May-2013 by Pankaj S.
                                                  set_card_no,
                                     set_v_prod_code, set_v_acct_type
                                    --En Added on 29-May-2013 by Pankaj S.
                                    );
                     EXCEPTION
                        WHEN OTHERS
                        THEN
                           v_errmsg :=
                                 'Error while inserting in statementlog for Topup card number  '
                              || i.mtt_beneficiary_card_no
                              || ' and RRN ' --Error message modified by Pankaj S. on 25-Sep-2013
                              || i.mtt_rrn
                              || ' '
                              || SUBSTR (SQLERRM, 1, 100);
                           v_errcode := SQLCODE;
                           RAISE excp_reject_rec;
                     END;

                     /*                       --Sn 02Aug2013
                     IF     i.mtt_delivery_channel = '03'
                        AND i.mtt_transaction_code = '38'
                        AND i.mtt_crdr_flag = '2'
                     THEN
                        BEGIN
                           INSERT INTO cms_statements_log
                                       (csl_rrn, csl_delivery_channel,
                                        csl_txn_code, csl_trans_type,
                                        csl_business_date,
                                        csl_business_time, csl_pan_no,
                                        csl_merchant_name,
                                        csl_merchant_city, csl_trans_amount,
                                        csl_acct_no,
                                        csl_opening_bal,
                                        csl_closing_balance, csl_auth_id,
                                        csl_trans_narrration,
                                        csl_pan_no_encr,
                                        csl_trans_date,
                                        txn_fee_flag, csl_inst_code,
                                        csl_lupd_date,
                                        csl_lupd_user,
                                        csl_ins_date,
                                        csl_ins_user,
                                        --Sn Added on 29-May-2013 by Pankaj S.
                                        csl_panno_last4digit,
                                        csl_prod_code, csl_acct_type,
                                        csl_to_acctno
                                       --En Added on 29-May-2013 by Pankaj S.
                                       )
                                VALUES (i.mtt_rrn, i.mtt_delivery_channel,
                                        '39', 'DR',
                                        i.mtt_business_date,
                                        i.mtt_business_time, v_gethash,
                                        i.mtt_merchant_name,
                                        i.mtt_merchant_city, i.mtt_amount,
                                        TRIM (i.mtt_account_number),
                                        --Sn Modified by Pankaj S. to use Ledger balance instead of acct balnce
                                        i.mtt_beforetxn_ledger_bal,
                                        --i.mtt_beforetxn_avail_bal,
                                        i.mtt_ledger_balance, i.mtt_auth_id,
                                        i.mtt_narration,
                                        v_encr_pan,
                                        TO_DATE (   i.mtt_business_date
                                                 || ' '
                                                 || i.mtt_business_time,
                                                 'yyyymmdd hh24miss'
                                                ),
                                        'N', prm_instcode,
                                        TO_DATE (i.mtt_posted_date,
                                                 'yyyymmdd hh24miss'
                                                ),
                                        prm_ins_user,
                                        TO_DATE (i.mtt_posted_date,
                                                 'yyyymmdd hh24miss'
                                                ),
                                        prm_ins_user,

                                        --Sn Added on 29-May-2013 by Pankaj S.
                                        (SUBSTR (i.mtt_card_no,
                                                 LENGTH (i.mtt_card_no) - 3
                                                )
                                        ),
                                        v_prod_code, v_acct_type,
                                        CASE
                                           WHEN     i.mtt_delivery_channel =
                                                                          '03'
                                                AND i.mtt_transaction_code =
                                                                          '38'
                                                AND i.mtt_c2ctxn_status = 'A'
                                              THEN v_toacct_no
                                           ELSE ''
                                        END
                                       );
                        EXCEPTION
                           WHEN OTHERS
                           THEN
                              v_errmsg :=
                                    'Error while inserting in statementlog for from card number'
                                 || ' for card '
                                 || i.mtt_card_no
                                 || ' and rrn '
                                 || i.mtt_rrn
                                 || ' '
                                 || SUBSTR (SQLERRM, 1, 100);
                              v_errcode := SQLCODE;
                              RAISE excp_reject_rec;
                        END;
                     END IF;
                     */                             --En 02Aug2013
                  END IF;
               END IF;
            ELSIF     NVL (i.mtt_tranfee_amount, 0) > 0
                  AND i.mtt_response_code <> '00'
                  AND i.mtt_crdr_flag IN
                         ('0', '1', '2') -- To handle decline fee transactions
            THEN
               BEGIN                     -- Inserting decline fee transaction
                  INSERT INTO /*+ append */ cms_statements_log
                              (csl_rrn, csl_delivery_channel,
                               csl_txn_code,
                               csl_trans_type,
                               csl_business_date, csl_business_time,
                               csl_pan_no, csl_merchant_name,
                               csl_merchant_city, csl_trans_amount,
                               csl_acct_no,
                               csl_opening_bal,
                               csl_closing_balance, csl_auth_id,
                               csl_trans_narrration,
                               csl_pan_no_encr,
                               csl_trans_date,
                               txn_fee_flag, csl_inst_code,
                               csl_lupd_date,
                               csl_lupd_user,
                               csl_ins_date,
                               csl_ins_user,
                               --Sn Added on 29-May-2013 by Pankaj S.
                               csl_panno_last4digit,
                               csl_prod_code, csl_acct_type
                              --En Added on 29-May-2013 by Pankaj S.
                              )
                       VALUES (i.mtt_rrn, i.mtt_delivery_channel,
                               i.mtt_transaction_code,
                               DECODE (i.mtt_crdr_flag,
                                       '0', 'DR',
                                       '1', 'CR',
                                       '2', 'NA'
                                      ),
                               i.mtt_business_date, i.mtt_business_time,
                               v_gethash, i.mtt_merchant_name,
                               i.mtt_merchant_city, i.mtt_tranfee_amount,
                               TRIM (i.mtt_account_number),
                               --Sn Modified by Pankaj S. to use Ledger balance instead of acct balnce
                               i.mtt_ledger_balance+i.mtt_tranfee_amount, --i.mtt_beforetxn_ledger_bal,  02Aug2013
                               --i.mtt_beforetxn_avail_bal,
                               i.mtt_ledger_balance,
                                                    --i.mtt_account_balance,
                                                     --En Modified by Pankaj S. to use Ledger balance instead of acct balnce
                                                    i.mtt_auth_id,
                                  DECODE (i.mtt_crdr_flag,
                                          '0', 'Fee Debited For ',
                                          '2', 'Fee Debited For ',
                                                              -- Added 04JUL13
                                          'Fee Credited For '
                                         )
                               || i.mtt_narration,
                               v_encr_pan,
                               TO_DATE (   i.mtt_business_date
                                        || ' '
                                        || i.mtt_business_time,
                                        'yyyymmdd hh24miss'
                                       ),
                               'Y', prm_instcode,
                               TO_DATE (i.mtt_posted_date,
                                        'yyyymmdd hh24miss'),
                               prm_ins_user,
                               TO_DATE (i.mtt_posted_date,
                                        'yyyymmdd hh24miss'),
                               prm_ins_user,

                               --Sn Added on 29-May-2013 by Pankaj S.
                               (SUBSTR (i.mtt_card_no,
                                        LENGTH (i.mtt_card_no) - 3
                                       )
                               ),
                               v_prod_code, v_acct_type
                              --En Added on 29-May-2013 by Pankaj S.
                              );
               EXCEPTION
                  WHEN OTHERS
                  THEN
                     v_errmsg :=
                           'Error while inserting decline fee transaction in statementlog '
                        || ' for card '
                        || i.mtt_card_no
                        || ' and RRN ' --Error message modified by Pankaj S. on 25-Sep-2013
                        || i.mtt_rrn
                        || ' '
                        || SUBSTR (SQLERRM, 1, 100);
                     v_errcode := SQLCODE;
                     RAISE excp_reject_rec;
               END;
            END IF;

            BEGIN
               SELECT cms_response_id
                 INTO v_resp_id
                 FROM cms_response_mast
                WHERE cms_delivery_channel = i.mtt_delivery_channel
                  AND cms_iso_respcde = i.mtt_response_code
                  AND cms_inst_code = prm_instcode
                  AND ROWNUM < 2;
            EXCEPTION
               WHEN NO_DATA_FOUND
               THEN
                  v_errmsg :=
                        'Response id not found'
                     || ' for card '
                     || i.mtt_card_no
                     || ' and RRN ' --Error message modified by Pankaj S. on 25-Sep-2013
                     || i.mtt_rrn;
                  v_errcode := 'MIG-888' ;
                  -- SACHIN:888

                  v_migr_err_desc:= 'EXCP_RESPID_NOT_FOUND';

                  RAISE excp_reject_rec;
               WHEN OTHERS
               THEN
                  v_errmsg :=
                        'Error while fetching response id'
                     || ' for card '
                     || i.mtt_card_no
                     || ' and RRN ' --Error message modified by Pankaj S. on 25-Sep-2013
                     || i.mtt_rrn
                     || ' '
                     || SUBSTR (SQLERRM, 1, 100);
                  v_errcode := SQLCODE;
                  RAISE excp_reject_rec;
            END;
             --SN Dhiraj Gaikwad
             IF     i.mtt_delivery_channel='11' THEN
                    BEGIN
                       SELECT COUNT (*)
                         INTO v_odfi_cnt
                         FROM cms_odfi_ach_mast
                        WHERE     COA_INST_CODE = prm_instcode
                              AND COA_PROD_CODE = V_PROD_CODE
                              AND COA_ODFI_CODE = i.mtt_odfi;

                       IF v_odfi_cnt <> 0
                       THEN
                          V_ACH_EXCEPTION_QUEUE_FLAG := 'FD';
                       ELSE
                          V_ACH_EXCEPTION_QUEUE_FLAG := NULL;
                       END IF;

                       IF V_ACH_EXCEPTION_QUEUE_FLAG <> 'FD'
                       THEN
                          V_ACH_AUTO_CLEAR_FLAG := 'Y';
                       ELSE
                          V_ACH_AUTO_CLEAR_FLAG := 'N';
                       END IF;
                    EXCEPTION
                       WHEN OTHERS
                       THEN
                          v_errmsg :=
                                'Error while fetching ODFI COUNT '
                             || ' for card '
                             || i.mtt_card_no
                             || ' and RRN '
                             || i.mtt_rrn
                             || ' '
                             || SUBSTR (SQLERRM, 1, 100);
                          v_errcode := SQLCODE;
                          RAISE excp_reject_rec;
                    END;
                    END IF ;
             --EN Dhiraj Gaikwad
            BEGIN
               INSERT INTO /*+ append */ transactionlog
                           (msgtype, rrn,
                            delivery_channel, terminal_id,
                            txn_code, txn_type,
                            txn_mode, response_code,
                            business_date, business_time,
                            customer_card_no,
                            topup_card_no,
                            topup_card_no_encr,
                            total_amount,
                            mccode, currencycode,
                            atm_name_location,
                            amount,
                            preauth_date,
                            system_trace_audit_no, tranfee_amt,
                            servicetax_amt,
                            tran_reverse_flag,
                            customer_acct_no,
                            orgnl_card_no,
                            orgnl_rrn, orgnl_business_date,
                            orgnl_business_time,
                            orgnl_terminal_id, reversal_code,
                            proxy_number, acct_balance,
                            ledger_balance, achfilename,
                            returnachfilename, odfi,
                            rdfi, seccodes, impdate,
                            processdate, effectivedate,
                            auth_id, befretran_ledgerbal,
                            befretran_availbalance,
                            achtrantype_id,
                            incoming_crfileid, indidnum,
                            indname, ach_id, ipaddress,
                            ani, dni, cardstatus,
                            internation_ind_response,
                            cr_dr_flag,
                            addr_verify_response,
                            dispute_flag,
                            reason,
                            remark,
                            txn_status,
                            trans_desc, customer_card_no_encr, instcode,
                            add_lupd_date,
                            add_lupd_user,
                            add_ins_date,
                            add_ins_user,
                                         --Sn Added on 29-May-2013 by Pankaj S.
                                         productid, categoryid,
                            acct_type, topup_acct_no, topup_acct_type,
                            topup_acct_balance,
                            topup_ledger_balance,
                                                 --En Added on 29-May-2013 by Pankaj S.
                                                 date_time,         -- 04JUL13
                            error_msg,                              -- 04JUL13
                                      response_id,                   -- 04JUL13
                                      TRANFEE_CR_ACCTNO,
                                      TRAN_ST_CR_ACCTNO,
                                      network_settl_date   ,          -- Added on 09-Oct-2013
                                      ---SN-Dhiraj Gaikwad
                               time_stamp    ,
                               store_id  ,
                                MERCHANT_NAME,
                                ACH_AUTO_CLEAR_FLAG,
                                ACH_EXCEPTION_QUEUE_FLAG ,
                                COUNTRY_CODE,
                                NETWORKID_ACQUIRER,
                                CVV_VERIFICATIONTYPE,
                                      ---EN-Dhiraj Gaikwad
                                reason_code  --2.1 onward changes      
                           )
                    VALUES (i.mtt_mesg_type, i.mtt_rrn,
                            i.mtt_delivery_channel, i.mtt_terminal_id,
                            i.mtt_transaction_code, i.mtt_transaction_type,
                            i.mtt_transaction_mode, i.mtt_response_code,
                            i.mtt_business_date, i.mtt_business_time,
                            v_gethash,
                            DECODE (i.mtt_beneficiary_card_no,
                                    NULL, '',
                                    gethash (i.mtt_beneficiary_card_no)
                                   ),
                            DECODE (i.mtt_beneficiary_card_no,
                                    NULL, '',
                                    fn_emaps_main (i.mtt_beneficiary_card_no)
                                   ),
                            TRIM (TO_CHAR (i.mtt_total_amount,
                                           '999999999999999990.99'
                                          )
                                 ),     --Modified by Pankaj S. on 29-May-2013
                            i.mtt_mcccode, i.mtt_currency_code,
                            i.mtt_atm_namelocation,
                            TRIM (TO_CHAR (i.mtt_amount,
                                           '999999999999999990.99'
                                          )
                                 ),     --Modified by Pankaj S. on 29-May-2013
                            TO_DATE (i.mtt_preauth_datetime,
                                     'YYYYMMDD:HH24:MI:SS'
                                    ),
                            i.mtt_stan, case when i.mtt_reversal_code <> 0 and i.mtt_reverse_fee_amt > 0
                                             then i.mtt_reverse_fee_amt else i.mtt_tranfee_amount
                                        end,
                            i.mtt_servicetax_amount,
                            DECODE (i.mtt_tran_rev_flag, '0', 'Y', '1', 'N'),
                            TRIM (i.mtt_account_number),
                            fn_emaps_main (i.mtt_orgnl_cardnumber),
                            i.mtt_orgnl_rrn, i.mtt_orgnl_businessdate,
                            i.mtt_orgnl_businesstime,
                            i.mtt_orgnl_terminalid, decode(i.mtt_reversal_code,0,i.mtt_reversal_code,'69'), --Changed as per discussion 02-Aug-2013
                            i.mtt_proxy_number, i.mtt_account_balance,
                            i.mtt_ledger_balance, i.mtt_ach_filename,
                            i.mtt_return_achfilename, i.mtt_odfi,
                            i.mtt_rdfi, i.mtt_sec_codes, i.mtt_imp_date,
                            i.mtt_process_date, i.mtt_effective_date,
                            i.mtt_auth_id, i.mtt_beforetxn_ledger_bal,
                            i.mtt_beforetxn_avail_bal,
                            i.mtt_ach_transactiontype_id,
                            i.mtt_incoming_crfile_id, i.mtt_ind_idnum,
                            i.mtt_ind_name, i.mtt_ach_id, i.mtt_ipaddress,
                            i.mtt_ani, i.mtt_dni, i.mtt_card_status,
                            i.mtt_international_ind,
                            DECODE (i.mtt_crdr_flag,
                                    '0', 'DR',
                                    '1', 'CR',
                                    '2', 'NA'
                                   ),
                            i.mtt_addr_verification_ind,
                            DECODE (i.mtt_dispute_flag, '1', 'Y', '0', 'N'),
                            DECODE (i.mtt_dispute_flag,
                                    '1', i.mtt_disp_reason,
                                    0, v_reason_desc
                                   ),
                            DECODE (i.mtt_dispute_flag,
                                    '1', i.mtt_disp_remark,
                                    0, i.mtt_remark
                                   ),
                            DECODE (i.mtt_response_code, '00', 'C', 'F'),
                            v_tran_desc, v_encr_pan, prm_instcode,
                            TO_DATE (i.mtt_posted_date, 'yyyymmdd hh24miss'),
                            prm_ins_user,
                            TO_DATE (i.mtt_posted_date, 'yyyymmdd hh24miss'),
                            prm_ins_user,
                                         --Sn Added on 29-May-2013 by Pankaj S.
                                         v_prod_code, v_card_type,
                            v_acct_type, v_toacct_no, v_toacct_type,
                            i.mtt_topupcard_acctbal,
                            i.mtt_topupcard_ledgerbal,
                                                      --En Added on 29-May-2013 by Pankaj S.
                                                      v_date_time,  -- 04JUL13
                            SUBSTR (v_errmsg, 1, 500),              -- 04JUL13
                                                      v_resp_id,     -- 04JUL13
                            v_gl_acct_code,
                            v_gl_acct_code,
                            case when i.mtt_delivery_channel in ('01','02')
                            then i.mtt_business_date
                            else '' end           ,           -- Added on 09-Oct-2013
                                   ---SN-Dhiraj Gaikwad
                             i.mtt_time_stamp         ,
                             Case when  i.mtt_delivery_channel ='04' and i.mtt_transaction_code in ('68' ,'69') then
                              i.mtt_terminal_id
                              when  i.mtt_delivery_channel ='08' then
                               i.mtt_store_id
                              else null end  ,
                               i.mtt_merchant_name ,
                              V_ACH_EXCEPTION_QUEUE_FLAG ,
                               V_ACH_AUTO_CLEAR_FLAG ,
                               i.MTT_COUNTRY_CODE,
                               CASE WHEN i.mtt_delivery_channel ='01' THEN 'VDBZ' ELSE '' END ,
                               i.MTT_CVV_VERIFICATIONTYPE,
                                      ---EN-Dhiraj Gaikwad
                               i.mtt_reasoncode  --2.1 onward changes       
                           );
            EXCEPTION
               WHEN OTHERS
               THEN
                  v_errmsg :=
                        'Error occured while inserting into transactionlog for card '
                     || i.mtt_card_no
                     || ' and RRN ' --Error message modified by Pankaj S. on 25-Sep-2013
                     || i.mtt_rrn
                     || ' '
                     || SUBSTR (SQLERRM, 1, 100);
                  v_errcode := SQLCODE;
                  RAISE excp_reject_rec;
            END;
         --SN Dhiraj Gaikwad
           BEGIN


                  v_Hash_key := GETHASH ( i.mtt_delivery_channel || i.mtt_transaction_code||i.mtt_card_no||  i.mtt_rrn||to_char(i.mtt_time_stamp,'YYYYMMDDHH24MISSFF5')) ;

            EXCEPTION
               WHEN OTHERS
               THEN
                  v_errmsg :=
                        'Error occured while Hash Key Generation '
                     || i.mtt_card_no
                     || ' and RRN ' --Error message modified by Pankaj S. on 25-Sep-2013
                     || i.mtt_rrn
                     || ' '
                     || SUBSTR (SQLERRM, 1, 100);
                  v_errcode := SQLCODE;
                  RAISE excp_reject_rec;
            END;
         --EN Dhiraj Gaikwad
            BEGIN
               INSERT INTO /*+ append */ cms_transaction_log_dtl
                           (ctd_msg_type, ctd_rrn,
                            ctd_delivery_channel, ctd_txn_code,
                            ctd_txn_type, ctd_txn_mode,
                            ctd_business_date, ctd_business_time,
                            ctd_customer_card_no, ctd_txn_curr,
                            ctd_txn_amount, ctd_system_trace_audit_no,
                            ctd_fee_amount, ctd_servicetax_amount,
                            ctd_cust_acct_number,
                            ctd_waiver_amount, ctd_internation_ind_response,
                            ctd_addr_verify_response,
                            ctd_customer_card_no_encr,
                            ctd_process_flag,
                            ctd_inst_code,
                            ctd_ins_date,
                            ctd_ins_user,
                            ctd_lupd_date,
                            ctd_lupd_user,
                            ctd_process_msg ,
                                       ---SN-Dhiraj Gaikwad
                            ctd_mobile_number,
                             ctd_device_id,
                             ctd_user_name ,
                             ctd_store_address1 ,
                             ctd_store_address2 ,
                             ctd_store_city     ,
                             ctd_store_state    ,
                             ctd_store_zip      ,
                             ctd_optn_phno2     ,
                             ctd_email          ,
                             ctd_optn_email     ,
                             CTD_TAXPREPARE_ID  ,
                             CTD_REASON_CODE    ,
                             CTD_ALERT_OPTIN   ,
                             CTD_LOCATION_ID ,
                             CTD_COUNTRY_CODE ,
                             CTD_HASHKEY_ID
                                      ---EN-Dhiraj Gaikwad
                           )
                    VALUES (i.mtt_mesg_type, i.mtt_rrn,
                            i.mtt_delivery_channel, i.mtt_transaction_code,
                            i.mtt_transaction_type, i.mtt_transaction_mode,
                            i.mtt_business_date, i.mtt_business_time,
                            v_gethash, i.mtt_currency_code,
                            i.mtt_amount, i.mtt_stan,
                            i.mtt_tranfee_amount, i.mtt_servicetax_amount,
                            TRIM (i.mtt_account_number),
                            i.mtt_waiver_amount, i.mtt_international_ind,
                            i.mtt_addr_verification_ind,
                            v_encr_pan,
                            DECODE (i.mtt_response_code, '00', 'Y', 'E'),
                            prm_instcode,
                            TO_DATE (i.mtt_posted_date, 'yyyymmdd hh24miss'),
                            prm_ins_user,
                            TO_DATE (i.mtt_posted_date, 'yyyymmdd hh24miss'),
                            prm_ins_user,
                            SUBSTR (v_errmsg, 1, 500) , -- substr added 04JUL13
                                       ---SN-Dhiraj Gaikwad
                             i.mtt_mobile_number,
                             i.mtt_device_id   ,
                             i.mtt_customer_username    ,
                             i.MTT_STORE_ADDRESS1 ,
                             i.MTT_STORE_ADDRESS2 ,
                             i.MTT_STORE_CITY  ,
                             i.MTT_STORE_STATE  ,
                             i.MTT_STORE_ZIP    ,
                             i.MTT_OPTN_PHNO2   ,
                             i.MTT_EMAIL        ,
                             i.MTT_OPTN_EMAIL   ,
                             i.MTT_TAXPREPARE_ID ,
                             i.MTT_REASON_CODE   ,
                             i.MTT_ALERT_OPTIN    ,
                             Case when  i.mtt_delivery_channel ='04' and i.mtt_transaction_code in ('68' ,'69') then
                              i.mtt_terminal_id else null end  ,
                               i.MTT_COUNTRY_CODE,v_Hash_key
                                      ---EN-Dhiraj Gaikwad
                           );
            EXCEPTION
               WHEN OTHERS
               THEN
                  v_errmsg :=
                        'Error occured while inserting into txnlog_dtl for card '
                     || i.mtt_card_no
                     || ' and RRN ' --Error message modified by Pankaj S. on 25-Sep-2013
                     || i.mtt_rrn
                     || ' '
                     || SUBSTR (SQLERRM, 1, 100);
                  v_errcode := SQLCODE;
                  RAISE excp_reject_rec;
            END;

            IF v_errcode = 'MIG-400'
            THEN
               migr_log_success_pkg (prm_instcode,
                                     i.mtt_file_name,
                                     i.mtt_record_number,
                                     i.mtt_card_no,
                                     v_errmsg,
                                     prm_ins_user
                                    );

               UPDATE migr_transactionlog_temp
                  SET mtt_errmsg = 'Transaction Successfuly Migrated',
                      mtt_errcode = 'MIG-400',
                      mtt_flag = 'S'
                WHERE ROWID = i.ROWID;
            END IF;
         EXCEPTION
            WHEN excp_reject_rec
            THEN
               ROLLBACK TO v_savepoint;                            -- 04JUL13

               UPDATE migr_transactionlog_temp
                  SET mtt_errmsg = SUBSTR (v_errmsg, 1, 500),
                                                       -- substr added 04JUL13
                      mtt_errcode = v_errcode,
                      mtt_flag = 'F'
                WHERE ROWID = i.ROWID;

               v_errmsg :=
                     'Transaction file - '
                  || i.mtt_file_name
                  || ' record - '
                  || i.mtt_record_number
                  || ' : '
                  || v_errmsg;
               migr_log_error_pkg (prm_instcode,
                                   i.mtt_file_name,
                                   i.mtt_record_number,
                                   i.mtt_card_no,
                                   'TRAN',
                                   v_errmsg,
                                   prm_ins_user,
                                   v_errcode,
                                   v_migr_err_desc
                                  );
            WHEN OTHERS
            THEN
               ROLLBACK TO v_savepoint;                            -- 04JUL13
               v_errcode := SQLCODE;
               v_errmsg :=
                     'Transaction file - '
                  || i.mtt_file_name
                  || ' record - '
                  || i.mtt_record_number
                  || ' : '
                  || SUBSTR (SQLERRM, 1, 100);

               UPDATE migr_transactionlog_temp
                  SET mtt_errmsg = SUBSTR (v_errmsg, 1, 500),
                                                       -- substr added 04JUL13
                      mtt_errcode = v_errcode,
                      mtt_flag = 'F'
                WHERE ROWID = i.ROWID;

               migr_log_error_pkg (prm_instcode,
                                   i.mtt_file_name,
                                   i.mtt_record_number,
                                   i.mtt_card_no,
                                   'TRAN',
                                   v_errmsg,
                                   prm_ins_user,
                                   v_errcode,
                                   v_migr_err_desc
                                  );
         END;

         v_counter := v_counter + 1;

         IF v_counter = v_commit_pnt
         THEN
            COMMIT;
            v_counter := 0;
         END IF;
      END LOOP;

      COMMIT;
   EXCEPTION

      WHEN main_tran_excp
      THEN
      prm_errmsg :=  v_errmsg ;

      WHEN OTHERS
      THEN
         prm_errmsg :=
               'Error While Transaction Data Migration '
            || SUBSTR (SQLERRM, 1, 200);
   END;


PROCEDURE MIGR_CALLLOG_PKG (
      prm_instcode         NUMBER,
      prm_ins_date         DATE,
      prm_ins_user         NUMBER,
      prm_errmsg     OUT   VARCHAR2
   )
   IS
      v_errmsg                VARCHAR2 (500);
      v_errcode               VARCHAR2 (30);  -- Changed from 10 to 30 on 10-oct-2013
      v_gethash               cms_calllog_mast.CCM_PAN_CODE%TYPE;
      excp_reject_rec         exception;
      v_commit_pnt            migr_ctrl_table.mct_ctrl_numb%TYPE;
      v_counter               NUMBER (6)                                 := 0;
      v_call_id               NUMBER;
      v_call_seq              cms_calllog_details.CCD_CALL_SEQ%TYPE      := 0;
      v_migr_err_desc         VARCHAR2 (50);
      v_savepoint             NUMBER (20)                                := 0;
      v_acct_number           cms_appl_pan.cap_pan_code%type;
      dum                     NUMBER(1);
      v_loop_cnt    number(1);

      type rec_call_det is record
      (
       v_tran_code  cms_transaction_mast.ctm_tran_code%type,
       v_date       CMS_CALLLOG_DETAILS.CCD_TRAN_DATE%type,
       v_time       CMS_CALLLOG_DETAILS.CCD_TRAN_TIME%type
      );

      type pl_call_det is table of rec_call_det index by pls_integer;

      v_call_detl  pl_call_det;

      V_CHK_TRAN  NUMBER(10);


      CURSOR c
      IS
         SELECT   ROWID, a.*
             FROM MIGR_CSR_CALLLOG_TEMP A
            WHERE MCC_PROC_FLAG = 'N'
         ORDER BY MCC_START_TIME;--TO_DATE (MCC_BUSINESS_DATE||' '||MCC_BUSINESS_TIME, 'YYYYMMDD hh24:mi:ss');


   BEGIN
      v_errmsg := 'OK';
      prm_errmsg := 'OK';

      BEGIN
         SELECT mct_ctrl_numb
           INTO v_commit_pnt
           FROM migr_ctrl_table
          WHERE mct_ctrl_code = prm_instcode AND mct_ctrl_key = 'COMMIT_PARAM';
      EXCEPTION
         WHEN OTHERS
         THEN
            v_commit_pnt := 1000;
      END;

      FOR i IN c
      LOOP

            select regexp_substr(i.mcc_tran_code,'[^~]+', 1, level) Txn_Code,
                   regexp_substr(i.mcc_business_date,'[^~]+', 1, level) business_date,
                   regexp_substr(i.mcc_business_time,'[^~]+', 1, level) business_time
            bulk collect into v_call_detl
            from dual
            connect by regexp_substr(i.mcc_tran_code, '[^~]+', 1, level) is not null;


            select seq_call_id.NEXTVAL into v_call_id from dual;

            v_call_seq := 0;

         FOR k in 1..v_call_detl.count()

         loop

             BEGIN
                v_errcode := 'MIG-500';
                v_errmsg := 'OK';
                SAVEPOINT v_savepoint;
                v_savepoint := v_savepoint + 1;
                v_call_seq  := v_call_seq + 1;

               /*
                BEGIN
                   v_gethash := gethash (i.mcc_pan_code);
                EXCEPTION
                   WHEN OTHERS
                   THEN
                      v_errcode := SQLCODE;
                      v_errmsg :=
                            'while getting hash value for card - '
                         || i.MCC_PAN_CODE
                         || ' and RRN '
                         || i.mcc_rrn
                         || ' '
                         ||' date '||v_call_detl(k).v_date
                         ||' time '||v_call_detl(k).v_time
                         || SUBSTR (SQLERRM, 1, 100);
                      RAISE excp_reject_rec;
                END;
               */

                BEGIN

                   SELECT cap_acct_no
                     INTO v_acct_number
                   FROM   cms_appl_pan
                    WHERE cap_inst_code = prm_instcode
                          AND cap_pan_code = i.mcc_hash_pan;
                EXCEPTION
                   WHEN NO_DATA_FOUND
                   THEN
                      v_errcode := 'MIG-501';
                      v_migr_err_desc := 'EXCP_CARD_NOT_FOUND';
                      v_errmsg :=
                            'Card '|| i.MCC_PAN_CODE ||' not found in master '
                         || ' for RRN '
                         || i.mcc_rrn
                         ||' date '||v_call_detl(k).v_date
                         ||' time '||v_call_detl(k).v_time;
                      RAISE excp_reject_rec;
                   WHEN OTHERS
                   THEN
                      v_errcode := SQLCODE;
                      v_errmsg :=
                            'Error while validating delivery channel '
                         || '03'
                         || ' for card - '
                         || i.MCC_PAN_CODE
                         || ' and RRN '
                         || i.mcc_rrn
                         ||' date '||v_call_detl(k).v_date
                         ||' time '||v_call_detl(k).v_time
                         || ' '
                         || SUBSTR (SQLERRM, 1, 100);
                      RAISE excp_reject_rec;
                END;

                BEGIN
                   SELECT 1
                     INTO dum
                     FROM cms_transaction_mast
                    WHERE ctm_inst_code = prm_instcode
                      AND ctm_tran_code = v_call_detl(k).v_tran_code
                      AND ctm_delivery_channel = '03';

                      dum := null;

                EXCEPTION
                   WHEN NO_DATA_FOUND
                   THEN
                      dum := null;
                      v_errcode := 'MIG-502';
                      v_migr_err_desc := 'EXCP_TXNCODE_NOT_FOUND';
                      v_errmsg :=
                            'Combination of transaction code '
                         || v_call_detl(k).v_tran_code
                         || ' and delivery channel- '
                         || '03'
                         || ' not found in master'
                         || ' for card - '
                         || i.mcc_pan_code
                         || ' and RRN '
                         || i.mcc_rrn
                         ||' date '||v_call_detl(k).v_date
                         ||' time '||v_call_detl(k).v_time;

                      RAISE excp_reject_rec;
                   WHEN OTHERS
                   THEN

                      dum := null;
                      v_errcode := SQLCODE;
                      v_errmsg :=
                            'Error while validating transaction code '
                         || v_call_detl(k).v_tran_code
                         || ' and delivery channel - '
                         || '03'
                         || ' for card - '
                         || i.mcc_pan_code
                         || ' and RRN '
                         || i.mcc_rrn
                         ||' date '||v_call_detl(k).v_date
                         ||' time '||v_call_detl(k).v_time
                         || ' '
                         || SUBSTR (SQLERRM, 1, 100);
                      RAISE excp_reject_rec;
                END;


                IF v_call_seq=1 THEN
                    BEGIN

                        insert into CMS_CALLLOG_MAST
                        (
                          ccm_inst_code,
                          ccm_call_id,
                          ccm_call_catg,
                          ccm_pan_code,
                          ccm_callstart_date,
                          ccm_callend_date,
                          ccm_call_status,
                          ccm_ins_user,
                          ccm_ins_date,
                          ccm_acct_no
                        )
                        values
                        (
                        prm_instcode,
                        v_call_id,
                        i.mcc_call_type,
                        i.mcc_hash_pan,
                        TO_DATE(i.mcc_start_time,'YYYYMMDD HH24:MI:SS'),
                        TO_DATE(i.mcc_call_endtime,'YYYYMMDD HH24:MI:SS'),
                        i.mcc_status,
                        prm_ins_user,
                        TO_DATE(i.mcc_call_endtime,'YYYYMMDD HH24:MI:SS'),
                        v_acct_number
                        );

                    EXCEPTION
                       WHEN OTHERS
                       THEN
                          v_errmsg :=
                                'Error occured while inserting into calllog mast for card '
                             || i.mcc_pan_code
                             || ' and RRN '
                             || i.mcc_rrn
                             ||' date '||v_call_detl(k).v_date
                             ||' time '||v_call_detl(k).v_time
                             || ' '
                             || SUBSTR (SQLERRM, 1, 100);
                          v_errcode := SQLCODE;
                          RAISE excp_reject_rec;
                    END;

                  END IF;

                    BEGIN

                        INSERT INTO CMS_CALLLOG_DETAILS
                        (
                          CCD_INST_CODE,
                          CCD_CALL_ID,
                          CCD_PAN_CODE,
                          CCD_CALL_SEQ,
                          CCD_RRN,
                          CCD_DEVL_CHNL,
                          CCD_TXN_CODE,
                          CCD_TRAN_DATE,
                          CCD_TRAN_TIME,
                          CCD_COMMENTS,
                          CCD_INS_USER,
                          CCD_INS_DATE,
                          CCD_ACCT_NO
                        )
                        VALUES
                        (
                        prm_instcode,
                        v_call_id,
                        i.mcc_hash_pan,
                        v_call_seq,
                        i.mcc_rrn,
                        '03',
                        v_call_detl(k).v_tran_code,
                        v_call_detl(k).v_date,
                        v_call_detl(k).v_time,
                        I.mcc_tran_comments,
                        prm_ins_user,
                        TO_DATE(i.mcc_call_endtime,'YYYYMMDD HH24:MI:SS'),
                        v_acct_number
                        );


                    EXCEPTION
                       WHEN OTHERS
                       THEN
                          v_errmsg :=
                                'Error occured while inserting into Calllog details for card '
                             || i.mcc_pan_code
                             || ' and RRN '
                             || i.mcc_rrn
                             ||' date '||v_call_detl(k).v_date
                             ||' time '||v_call_detl(k).v_time
                             || ' '
                             || SUBSTR (SQLERRM, 1, 100);
                          v_errcode := SQLCODE;
                          RAISE excp_reject_rec;
                    END;
                  

                IF v_errcode = 'MIG-500'
                THEN
                               migr_log_success_pkg (prm_instcode,
                                                     i.mcc_file_name,
                                                     i.mcc_record_numb,
                                                     i.mcc_pan_code,
                                                     v_errmsg,
                                                     prm_ins_user
                                                    );

                   UPDATE MIGR_CSR_CALLLOG_TEMP
                      SET mcc_errmsg = 'Successfuly Migrated',
                          MCC_ERR_CODE = 'MIG-500',
                          MCC_PROC_FLAG = 'S'
                    WHERE ROWID = i.ROWID;
                END IF;


             EXCEPTION
                WHEN excp_reject_rec
                THEN
                   ROLLBACK TO v_savepoint;

                   UPDATE MIGR_CSR_CALLLOG_TEMP
                      SET mcc_errmsg = SUBSTR (v_errmsg, 1, 500),

                          MCC_ERR_CODE = v_errcode,
                          MCC_PROC_FLAG = 'F'
                    WHERE ROWID = i.ROWID;

                   v_errmsg :=
                         'Calllog file - '
                      || i.mcc_file_name
                      || ' record - '
                      || i.mcc_record_numb
                      || ' : '
                      || v_errmsg;
                               migr_log_error_pkg (prm_instcode,
                                                   i.mcc_file_name,
                                                   i.mcc_record_numb,
                                                   i.mcc_pan_code,
                                                   'CALLLOG',
                                                   v_errmsg,
                                                   prm_ins_user,
                                                   v_errcode,
                                                   v_migr_err_desc
                                                  );
                WHEN OTHERS
                THEN
                   ROLLBACK TO v_savepoint;                            -- 04JUL13
                   v_errcode := SQLCODE;
                   v_errmsg :=
                         'Calllog file - '
                      || i.mCC_file_name
                      || ' record - '
                      || i.mcc_record_numb
                      || ' : '
                      || SUBSTR (SQLERRM, 1, 100);

                   UPDATE MIGR_CSR_CALLLOG_TEMP
                      SET mcc_errmsg = SUBSTR (v_errmsg, 1, 500),
                                                           -- substr added 04JUL13
                          MCC_ERR_CODE = v_errcode,
                          MCC_PROC_FLAG = 'F'
                    WHERE ROWID = i.ROWID;

                               migr_log_error_pkg (prm_instcode,
                                                   i.mcc_file_name,
                                                   i.mcc_record_numb,
                                                   i.mcc_pan_code,
                                                   'CALLLOG',
                                                   v_errmsg,
                                                   prm_ins_user,
                                                   v_errcode,
                                                   v_migr_err_desc
                                                  );
             END;

         end loop;

         v_counter := v_counter + 1;

         IF v_counter = v_commit_pnt
         THEN
            COMMIT;
            v_counter := 0;
         END IF;


      END LOOP;

      COMMIT;
   EXCEPTION
      WHEN OTHERS
      THEN
         prm_errmsg :=
               'Error While Call Log Data Migration '
            || SUBSTR (SQLERRM, 1, 200);
   END;

   /*
    PROCEDURE migr_spprt_func_pkg (
       p_instcode    IN       NUMBER,
       p_lupd_user            NUMBER,
       p_errmsg      OUT      VARCHAR2
    )
    IS
       CURSOR cur_spprt_func_data
       IS
          SELECT a.ROWID spprt_rowid, msf_file_name, msf_record_numb,
                 msf_card_number, msf_new_card_number, msf_spprt_key,
                 msf_spprt_rsncde, msf_remark, msf_processed_date,
                 msf_delivery_channel, msf_transaction_code
            FROM migr_spprt_func_data a
           WHERE msf_proc_flag = 'N' AND ROWNUM < 10001;

       v_prod_catg               cms_appl_pan.cap_prod_catg%TYPE;
       v_errmsg                  VARCHAR2 (500);
       v_hash_pan                cms_appl_pan.cap_pan_code%TYPE;
       v_encr_pan                cms_appl_pan.cap_pan_code_encr%TYPE;
       v_hash_pan_new            cms_appl_pan.cap_pan_code%TYPE;
       v_encr_pan_new            cms_appl_pan.cap_pan_code_encr%TYPE;
       exp_reject_record_spprt   EXCEPTION;
       v_dum                     NUMBER (1);
       v_mbr_numb                cms_appl_pan.cap_mbr_numb%TYPE;
       v_count                   NUMBER (1);
       p_migr_err_code           VARCHAR2 (40);
       p_migr_err_desc           VARCHAR2 (50);
       v_commit_param            NUMBER (5);
       v_rec_cnt                 NUMBER                                := 0;
    BEGIN
       v_count := 1;
       v_mbr_numb := '000';
       p_errmsg := 'OK';

       BEGIN
          SELECT mct_ctrl_numb
            INTO v_commit_param
            FROM migr_ctrl_table
           WHERE mct_ctrl_key = 'COMMIT_PARAM';
       EXCEPTION
          WHEN NO_DATA_FOUND
          THEN
             p_errmsg := 'Commit Paramter not defined in master.';
             RETURN;
          WHEN OTHERS
          THEN
             p_errmsg :=
                   'Error while getting commit parameter '
                || SUBSTR (SQLERRM, 1, 200);
             RETURN;
       END;

       LOOP
          EXIT WHEN v_count = 0;

          FOR i IN cur_spprt_func_data
          LOOP
             BEGIN
                v_errmsg := 'OK';
                SAVEPOINT v_savepnt;
                v_dum := 0;
                v_hash_pan := NULL;
                v_encr_pan := NULL;
                v_hash_pan_new := NULL;
                v_encr_pan_new := NULL;
                p_migr_err_code := 'MIG-2_000';
                p_migr_err_desc := 'SUPP_OK';
                v_rec_cnt := v_rec_cnt + 1;

                BEGIN
                   v_hash_pan := gethash (i.msf_card_number);
                EXCEPTION
                   WHEN OTHERS
                   THEN
                      p_migr_err_code := 'MIG-2_001';
                      p_migr_err_desc := 'EXCP_PAN_HASHCONV';
                      v_errmsg :=
                            'Error while converting pan (hash) for card number '
                         || i.msf_card_number
                         || ' as '
                         || SUBSTR (SQLERRM, 1, 200);
                      RAISE exp_reject_record_spprt;
                END;

                BEGIN
                   v_encr_pan := fn_emaps_main (i.msf_card_number);
                EXCEPTION
                   WHEN OTHERS
                   THEN
                      p_migr_err_code := 'MIG-2_002';
                      p_migr_err_desc := 'EXCP_PAN_ENCRYPT';
                      v_errmsg :=
                            'Error while converting pan (encrypt) for card number '
                         || i.msf_card_number
                         || ' as '
                         || SUBSTR (SQLERRM, 1, 200);
                      RAISE exp_reject_record_spprt;
                END;

                BEGIN
                   --v_dum := 0;
                   SELECT cap_prod_catg
                     INTO v_prod_catg
                     FROM cms_appl_pan
                    WHERE cap_inst_code = p_instcode
                      AND cap_pan_code = v_hash_pan;

                   IF v_prod_catg IS NULL
                   THEN
                      p_migr_err_code := 'MIG-2_007';
                      p_migr_err_desc := 'EXCP_PROD_CATG_NULL';
                      v_errmsg := 'Product Category For the Card is Null ';
                      RAISE exp_reject_record_spprt;
                   END IF;
                EXCEPTION
                   WHEN NO_DATA_FOUND
                   THEN
                      p_migr_err_code := 'MIG-2_003';
                      p_migr_err_desc := 'EXCP_CARD_NOT_FOUND';
                      v_errmsg :=
                                 'Card Not Found In CMS ' || i.msf_card_number;
                      RAISE exp_reject_record_spprt;
                   WHEN exp_reject_record_spprt
                   THEN
                      RAISE exp_reject_record_spprt;
                   WHEN OTHERS
                   THEN
                      v_errmsg :=
                            'Error while Searching For card '
                         || i.msf_card_number
                         || ' as -'
                         || SUBSTR (SQLERRM, 1, 100);
                      RAISE exp_reject_record_spprt;
                END;

                BEGIN
                   SELECT 1
                     INTO v_dum
                     FROM cms_spprt_funcs
                    WHERE csf_inst_code = p_instcode
                      AND csf_spprt_key = i.msf_spprt_key;
                EXCEPTION
                   WHEN NO_DATA_FOUND
                   THEN
                      p_migr_err_code := 'MIG-2_004';
                      p_migr_err_desc := 'INVALID_SPPRT_KEY';
                      v_errmsg := 'Invalid Support Key ' || i.msf_spprt_key;
                      RAISE exp_reject_record_spprt;
                      v_errmsg :=
                            'Error While Validating Support Key as -'
                         || SUBSTR (SQLERRM, 1, 100)
                         || ' for support key : '
                         || i.msf_spprt_key;
                      RAISE exp_reject_record_spprt;
                END;

                IF i.msf_spprt_key = 'REISU'
                THEN
                   BEGIN
                      v_hash_pan_new := gethash (i.msf_new_card_number);
                   EXCEPTION
                      WHEN OTHERS
                      THEN
                         p_migr_err_code := 'MIG-2_001';
                         p_migr_err_desc := 'EXCP_PAN_HASHCONV';
                         v_errmsg :=
                               'Error while converting pan(hash) for card number '
                            || i.msf_new_card_number
                            || ' as '
                            || SUBSTR (SQLERRM, 1, 200);
                         RAISE exp_reject_record_spprt;
                   END;

                   BEGIN
                      v_encr_pan_new := fn_emaps_main (i.msf_new_card_number);
                   EXCEPTION
                      WHEN OTHERS
                      THEN
                         p_migr_err_code := 'MIG-2_002';
                         p_migr_err_desc := 'EXCP_PAN_ENCRYPT';
                         v_errmsg :=
                               'Error while converting pan(encrypt) for card number '
                            || i.msf_new_card_number
                            || ' as '
                            || SUBSTR (SQLERRM, 1, 200);
                         RAISE exp_reject_record_spprt;
                   END;

                   BEGIN
                      SELECT 1
                        INTO v_dum
                        FROM cms_appl_pan
                       WHERE cap_inst_code = p_instcode
                         AND cap_pan_code = v_hash_pan_new;
                   EXCEPTION
                      WHEN NO_DATA_FOUND
                      THEN
                         p_migr_err_code := 'MIG-2_003';
                         p_migr_err_desc := 'EXCP_CARD_NOT_FOUND';
                         v_errmsg :=
                               'New Card ot Found in PAN Master '
                            || i.msf_new_card_number;
                         RAISE exp_reject_record_spprt;
                      WHEN OTHERS
                      THEN
                         v_errmsg :=
                               'Error while Searching For New card '
                            || i.msf_new_card_number
                            || ' as -'
                            || SUBSTR (SQLERRM, 1, 100);
                         RAISE exp_reject_record_spprt;
                   END;
                END IF;

                BEGIN
                   SELECT 1
                     INTO v_dum
                     FROM cms_delchannel_mast
                    WHERE cdm_inst_code = p_instcode
                      AND cdm_channel_code = i.msf_delivery_channel;
                EXCEPTION
                   WHEN NO_DATA_FOUND
                   THEN
                      p_migr_err_code := 'MIG-2_005';
                      p_migr_err_desc := 'EXCP_INVALID_DEL_CHAN';
                      v_errmsg :=
                         'Invalid Delivery Channel ' || i.msf_delivery_channel;
                      RAISE exp_reject_record_spprt;
                   WHEN OTHERS
                   THEN
                      v_errmsg :=
                            'Error while validating Delivery Channel : '
                         || i.msf_delivery_channel
                         || ' as '
                         || SUBSTR (SQLERRM, 1, 200);
                      RAISE exp_reject_record_spprt;
                END;

                BEGIN
                   SELECT 1
                     INTO v_dum
                     FROM cms_transaction_mast
                    WHERE ctm_inst_code = p_instcode
                      AND ctm_tran_code = i.msf_transaction_code
                      AND ctm_delivery_channel = i.msf_delivery_channel;
                EXCEPTION
                   WHEN NO_DATA_FOUND
                   THEN
                      p_migr_err_code := 'MIG-2_006';
                      p_migr_err_desc := 'EXCP_INVALID_TRAN_CODE';
                      v_errmsg :=
                         'Invalid Transaction Code ' || i.msf_transaction_code;
                      RAISE exp_reject_record_spprt;
                   WHEN OTHERS
                   THEN
                      v_errmsg :=
                            'Error while validating Transaction code : '
                         || i.msf_transaction_code
                         || ' as '
                         || SUBSTR (SQLERRM, 1, 200);
                      RAISE exp_reject_record_spprt;
                END;

                BEGIN
                   SELECT 1
                     INTO v_dum
                     FROM cms_spprt_reasons
                    WHERE csr_inst_code = p_instcode
                      AND csr_spprt_rsncode = i.msf_spprt_rsncde;
                EXCEPTION
                   WHEN NO_DATA_FOUND
                   THEN
                      p_migr_err_code := 'MIG-2_006';
                      p_migr_err_desc := 'EXCP_INVALID_RSNCODE';
                      v_errmsg := 'Invalid Reason Code ' || i.msf_spprt_rsncde;
                      RAISE exp_reject_record_spprt;
                   WHEN OTHERS
                   THEN
                      v_errmsg :=
                            'Error while validating Reason code : '
                         || i.msf_spprt_rsncde
                         || ' as '
                         || SUBSTR (SQLERRM, 1, 200);
                      RAISE exp_reject_record_spprt;
                END;

                BEGIN
                   INSERT INTO cms_pan_spprt
                               (cps_inst_code, cps_pan_code, cps_mbr_numb,
                                cps_spprt_key, cps_func_remark, cps_ins_user,
                                cps_ins_date,
                                cps_prod_catg, cps_lupd_user, cps_lupd_date,
                                cps_pan_code_encr, cps_spprt_rsncode
                               )
                        VALUES (p_instcode, v_hash_pan, v_mbr_numb,
                                i.msf_spprt_key, i.msf_remark, p_lupd_user,
                                TO_DATE (i.msf_processed_date,
                                         'YYYYMMDD:HH24:MI:SS'
                                        ),
                                v_prod_catg, p_lupd_user, SYSDATE,
                                v_encr_pan, i.msf_spprt_rsncde
                               );

                   IF i.msf_spprt_key = 'REISU'
                   THEN
                      BEGIN
                         INSERT INTO cms_htlst_reisu
                                     (chr_inst_code, chr_pan_code,
                                      chr_mbr_numb, chr_new_pan, chr_new_mbr,
                                      chr_reisu_cause, chr_ins_user,
                                      chr_ins_date,
                                      chr_lupd_user, chr_lupd_date,
                                      chr_new_pan_encr, chr_pan_code_encr
                                     )
                              VALUES (p_instcode, v_hash_pan,
                                      v_mbr_numb, v_hash_pan_new, v_mbr_numb,
                                      'R', p_lupd_user,
                                      TO_DATE (i.msf_processed_date,
                                               'YYYYMMDD:HH24:MI:SS'
                                              ),
                                      p_lupd_user, SYSDATE,
                                      v_encr_pan_new, v_encr_pan
                                     );
                      EXCEPTION
                         WHEN OTHERS
                         THEN
                            p_migr_err_code := 'MIG-2_008';
                            p_migr_err_desc := 'EXCP_HTLST_REISU_INSRT';
                            v_errmsg :=
                                  'Error while making entry in HTLST REISU:'
                               || SUBSTR (SQLERRM, 1, 200);
                            RAISE exp_reject_record_spprt;
                      END;
                   END IF;
                EXCEPTION
                   WHEN exp_reject_record_spprt
                   THEN
                      RAISE;
                   WHEN OTHERS
                   THEN
                      p_migr_err_code := 'MIG-2_009';
                      p_migr_err_desc := 'EXCP_PAN_SPPRT_INSRT';
                      v_errmsg :=
                            'Error while making entry in PAN support :'
                         || SUBSTR (SQLERRM, 1, 200);
                      RAISE exp_reject_record_spprt;
                END;

                IF v_errmsg = 'OK'
                THEN
                   migr_log_success_pkg (p_instcode,
                                         i.msf_file_name,
                                         i.msf_record_numb,
                                         i.msf_card_number,
                                         v_errmsg,
                                         p_lupd_user
                                        );

                   BEGIN
                      UPDATE migr_spprt_func_data m
                         SET m.msf_proc_flag = 'S',
                             m.msf_proc_mesg = v_errmsg
                       WHERE m.ROWID = i.spprt_rowid;
                   END;
                END IF;

                IF MOD (v_rec_cnt, v_commit_param) = 0
                THEN
                   COMMIT;
                END IF;
             EXCEPTION
                WHEN exp_reject_record_spprt
                THEN
                   v_errmsg :=
                         'Support function file - '
                      || i.msf_file_name
                      || ' record - '
                      || i.msf_record_numb
                      || ' : '
                      || v_errmsg;
                   migr_log_error_pkg (p_instcode,
                                       i.msf_file_name,
                                       i.msf_record_numb,
                                       i.msf_card_number,
                                       i.msf_spprt_key,
                                       v_errmsg,
                                       p_lupd_user,
                                       p_migr_err_code,
                                       p_migr_err_desc
                                      );

                   UPDATE migr_spprt_func_data m
                      SET m.msf_proc_flag = 'E',
                          m.msf_proc_mesg = v_errmsg,
                          m.msf_err_code = p_migr_err_code
                    WHERE m.ROWID = i.spprt_rowid;
                WHEN OTHERS
                THEN
                   v_errmsg :=
                         'Support function file - '
                      || i.msf_file_name
                      || ' record - '
                      || i.msf_record_numb
                      || ' ,Error While Processing -'
                      || SUBSTR (SQLERRM, 1, 200);
                   migr_log_error_pkg (p_instcode,
                                       i.msf_file_name,
                                       i.msf_record_numb,
                                       i.msf_card_number,
                                       i.msf_spprt_key,
                                       v_errmsg,
                                       p_lupd_user,
                                       p_migr_err_code,
                                       p_migr_err_desc
                                      );

                   UPDATE migr_spprt_func_data m
                      SET m.msf_proc_flag = 'E',
                          m.msf_proc_mesg = v_errmsg,
                          m.msf_err_code = p_migr_err_code
                    WHERE m.ROWID = i.spprt_rowid;
             END;
          END LOOP;

          COMMIT;

          BEGIN
             SELECT COUNT (1)
               INTO v_count
               FROM migr_spprt_func_data
              WHERE msf_proc_flag = 'N' AND ROWNUM < 2;
          EXCEPTION
             WHEN OTHERS
             THEN
                v_count := 0;
          END;
       END LOOP;
    EXCEPTION
       WHEN OTHERS
       THEN
          p_errmsg :=
                'Error While Support Function Data Migration as : '
             || SUBSTR (SQLERRM, 1, 200);
    END;
    */
   PROCEDURE migr_set_gen_addrdata_pkg (
      prm_inst_code      IN       NUMBER,
      prm_addr_rec       IN       type_addr_rec_array,
      prm_addr_rec_out   OUT      type_addr_rec_array,
      prm_err_msg        OUT      VARCHAR2
   )
   IS
      v_addr_rec_outdata       type_addr_rec_array;
      v_error_message          VARCHAR2 (300);
      exp_addr_reject_record   EXCEPTION;
   BEGIN                                                    --<< main begin >>
      prm_err_msg := 'OK';
      v_error_message := 'OK';

      --Sn set data to generic variable for base there is no manipulation of data
      BEGIN
         prm_addr_rec_out := prm_addr_rec;
      EXCEPTION
         WHEN OTHERS
         THEN
            v_error_message :=
                        'Error in fetching data ' || SUBSTR (SQLERRM, 1, 200);
            RAISE exp_addr_reject_record;
      END;
--En set data to generic variable
   EXCEPTION                                            --<< main exception >>
      WHEN exp_addr_reject_record
      THEN
         prm_err_msg := v_error_message;
      WHEN OTHERS
      THEN
         prm_err_msg := 'Error from main' || SUBSTR (SQLERRM, 1, 200);
   END;

   PROCEDURE migr_log_error_pkg (
      p_inst_code       IN   NUMBER,
      p_file_name       IN   VARCHAR2,
      p_rec_numb        IN   NUMBER,
      p_card_numb       IN   VARCHAR2,
      p_type            IN   VARCHAR2,
      p_errmsg          IN   VARCHAR2,
      p_lupduser        IN   NUMBER,
      p_migr_err_code   IN   VARCHAR2,
      p_migr_err_desc   IN   VARCHAR2
   )
   AS
      PRAGMA AUTONOMOUS_TRANSACTION;
   BEGIN
      INSERT INTO migr_error_log
                  (mel_inst_code, mel_file_name, mel_rec_numb,
                   mel_card_numb, mel_type, mel_err_code, mel_err_desc,
                   mel_error_mesg, mel_ins_user, mel_ins_date
                  )
           VALUES (p_inst_code, p_file_name, p_rec_numb,
                   p_card_numb, p_type, p_migr_err_code, p_migr_err_desc,
                   p_errmsg, p_lupduser, SYSDATE
                  );

      COMMIT;
   END;

   PROCEDURE migr_log_success_pkg (
      p_inst_code   IN   NUMBER,
      p_file_name   IN   VARCHAR2,
      p_rec_num     IN   NUMBER,
      p_card_numb   IN   VARCHAR2,
      p_msg         IN   VARCHAR2,
      p_lupduser    IN   NUMBER
   )
   AS
      PRAGMA AUTONOMOUS_TRANSACTION;
   BEGIN
      INSERT INTO migr_succ_log
                  (msl_inst_code, msl_file_name, msl_rec_numb,
                   msl_card_numb, msl_mesg, msl_user, msl_ins_date
                  )
           VALUES (p_inst_code, p_file_name, p_rec_num,
                   p_card_numb, p_msg, p_lupduser, SYSDATE
                  );

      COMMIT;
   END;

   PROCEDURE sp_check_ssn_threshold (
      p_instcode    IN       NUMBER,
      p_ssn         IN       VARCHAR2,
      p_prod_code   IN       VARCHAR2,
      p_resp_msg    OUT      VARCHAR2
   )
   AS
/**************************************************************************
     * Created Date               : 31_May_2013
     * Created By                 : Pankaj S.
     * Purpose                    : Checking No.Of Card generation/activation attempts against threshold
     * Reviewer                   :  Dhiraj
     * Reviewed Date              :

     * Modified fy                : Sagar
     * Modified date              : 10-oct-2013
     * Modified for               : Performace Tunning
****************************************************************************/
      v_errmsg            VARCHAR2 (500);
      v_no_crds_gen       NUMBER (10)                            := 0;
      v_cardissu_cnt      NUMBER (10)                            := 0;
      v_cnt               NUMBER (10)                            := 0;
      v_threshold_limit   NUMBER (10);
      v_threshold_inst    cms_inst_param.cip_param_value%TYPE;
      exp_reject_record   EXCEPTION;
      TYPE cust_tab IS TABLE OF number(10)
      INDEX BY PLS_INTEGER;
      v_cust_code  cust_tab;
      v_cust_string clob;
      v_query       clob;


   BEGIN
      p_resp_msg := 'OK';

      --Sn Get threshold parameter(Institution Level)
      BEGIN
         SELECT cip_param_value
           INTO v_threshold_inst
           FROM cms_inst_param
          WHERE cip_inst_code = p_instcode
            AND cip_param_key = 'PRODUCT_THRESHOLD';
      EXCEPTION
         WHEN OTHERS
         THEN
            v_threshold_limit := 0;
      END;


      begin
         select ccm_cust_code bulk collect into v_cust_code
         from cms_cust_mast
         where ccm_ssn = p_ssn;
      exception
        WHEN OTHERS
         THEN
            v_errmsg :='Error while getting cust code particular SSN/ID  -'|| SUBSTR (SQLERRM, 1, 300);
            RAISE exp_reject_record;
      END;

      for i in 1..v_cust_code.count loop
          v_cust_string := v_cust_string||to_char(v_cust_code(i))||',';
      end loop;

      v_cust_string := substr(v_cust_string,1,instr(v_cust_string,',',-1)-1);

      --En Get threshold parameter(Institution Level)

      --Sn check no .of cards generated for particular SSN/Otherid(institution level)
      BEGIN

        /*
         SELECT COUNT (1)
           INTO v_cardissu_cnt
           FROM cms_appl_pan, cms_cust_mast
          WHERE cap_inst_code = p_instcode -- Added on 16-sep-2013
            and ccm_inst_code = cap_inst_code
            AND ccm_cust_code = cap_cust_code
            AND EXISTS (
                   SELECT 1
                     FROM cms_ssn_cardstat
                    WHERE CSC_INST_CODE = p_instcode -- Added on 16-sep-2013
                    and cap_card_stat = csc_card_stat
                    AND csc_stat_flag = 'Y')
            AND ccm_ssn = p_ssn;
        */


         v_query := 'SELECT COUNT (1) FROM cms_appl_pan WHERE cap_inst_code = '||p_instcode||' AND cap_cust_code in ( ' ||v_cust_string || '  )
                     AND EXISTS (SELECT 1
                                 FROM cms_ssn_cardstat
                                 WHERE CSC_INST_CODE = '||p_instcode||'
                                 and cap_card_stat = csc_card_stat
                                 AND csc_stat_flag = '||''''||'Y'||''''||' )';

          execute immediate v_query into  v_cardissu_cnt;

         IF v_cardissu_cnt >= v_threshold_inst
         THEN
            v_errmsg :=
                     'Institution multiple SSN / Other ID level check failed';
            RAISE exp_reject_record;
         END IF;
      EXCEPTION
         WHEN exp_reject_record
         THEN
            RAISE;
         WHEN OTHERS
         THEN
            v_errmsg :=
                  'Error while getting count of cards generated for particular SSN/ID  -'
               || SUBSTR (SQLERRM, 1, 300);
            RAISE exp_reject_record;
      END;

      --En check no .of cards generated for particular SSN/Otherid(institution level)

      --Sn Get threshold parameter(Product Level)
      BEGIN
         SELECT cpt_prod_threshold
           INTO v_threshold_limit
           FROM cms_prod_threshold
          WHERE cpt_inst_code = p_instcode AND cpt_prod_code = p_prod_code;
      EXCEPTION
         WHEN NO_DATA_FOUND
         THEN
            v_threshold_limit := 0;
         WHEN OTHERS
         THEN
            v_errmsg :=
               'Error while selecting Threshold -'
               || SUBSTR (SQLERRM, 1, 300);
            RAISE exp_reject_record;
      END;

      --En Get threshold parameter(Product Level)

      --Sn Get count of cards generated for particular SSN/Otherid
      BEGIN

        /*
         SELECT COUNT (1)
           INTO v_no_crds_gen
           FROM cms_appl_pan, cms_cust_mast
          WHERE cap_inst_code = p_instcode -- Added on 16-sep-2013
            and ccm_inst_code = cap_inst_code
            AND ccm_cust_code = cap_cust_code
            AND EXISTS (
                   SELECT 1
                     FROM cms_ssn_cardstat
                    WHERE csc_inst_code = p_instcode -- Added on 16-sep-2013
                    and   cap_card_stat = csc_card_stat
                    AND csc_stat_flag = 'Y')
            AND cap_prod_code = p_prod_code
            AND ccm_ssn = p_ssn;
        */

          v_query := 'SELECT COUNT (1)
                  FROM cms_appl_pan
                  WHERE cap_inst_code = '||p_instcode||'
                  AND cap_cust_code in ( ' ||v_cust_string || '  )
                  AND EXISTS (
                  SELECT 1
                  FROM cms_ssn_cardstat
                  WHERE csc_inst_code = '||p_instcode||'
                  and  cap_card_stat = csc_card_stat
                  AND  csc_stat_flag = '||''''||'Y'||''''||' )  AND cap_prod_code = '||''''||p_prod_code||'''';

                  execute immediate v_query into  v_no_crds_gen;

         --Sn Determine if the process is to be allowed or terminated based on Threshold
         IF v_no_crds_gen >= v_threshold_limit
         THEN
            v_errmsg := 'Product multiple SSN / Other ID level check failed';
            RAISE exp_reject_record;
         END IF;
      --En Determine if the process is to be allowed or terminated based on Threshold\
      EXCEPTION
         WHEN exp_reject_record
         THEN
            RAISE;
         WHEN OTHERS
         THEN
            v_errmsg :=
                  'Error while selecting cards generated for particular SSN/ID- '
               || SUBSTR (SQLERRM, 1, 300);
            RAISE exp_reject_record;
      END;
--En Get count of cards generated for particular SSN/Other ID
   EXCEPTION
      WHEN exp_reject_record
      THEN
         p_resp_msg := v_errmsg;
      WHEN OTHERS
      THEN
         p_resp_msg := ' Error from main ' || SUBSTR (SQLERRM, 1, 200);
   END;
END;
/
SHOW ERROR