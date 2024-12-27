create or replace
PROCEDURE                      VMSCMS.SP_GEN_PAN_STOCK_ISSU (

   prm_cam_asso_code              IN       NUMBER,
   prm_cam_inst_type              IN       NUMBER,
   prm_cam_prod_code              IN       VARCHAR2,
   prm_cam_appl_bran              IN       VARCHAR2,
   prm_cam_cust_code              IN       NUMBER,
   prm_cam_card_type              IN       NUMBER,
   prm_cam_cust_catg              IN       NUMBER,
   prm_cam_disp_name              IN       VARCHAR2,
   prm_cam_active_date            IN       DATE,
   prm_cam_expry_date             IN       DATE,
   prm_cam_addon_stat             IN       CHAR,
   prm_cam_tot_acct               IN       NUMBER,
   prm_cam_chnl_code              IN       NUMBER,
   prm_cam_limit_amt              IN       NUMBER,
   prm_cam_use_limit              IN       NUMBER,
   prm_cam_bill_addr              IN       NUMBER,
   prm_cam_request_id             IN       VARCHAR2,
   prm_cam_appl_stat              IN       CHAR,
   prm_cam_initial_topup_amount   IN       NUMBER,
   prm_cam_starter_card           IN       VARCHAR2,
   prm_cam_file_name              IN       VARCHAR2,
   prm_cam_addon_link             IN       NUMBER,
   v_appl_data                             type_appl_rec_array,
   p_instcode                     IN       NUMBER,
   p_applcode                     IN       NUMBER,
   p_lupduser                     IN       NUMBER,
   p_pan                          OUT      VARCHAR2,
   p_applprocess_msg              OUT      VARCHAR2,
   p_errmsg                       OUT      VARCHAR2
)
AS
   /*************************************************
       * Created By       :  AMIT
       * Created Date     :  05/01/2013
       * Modified By      :
       * Modified reason :
       * Modified On       :
       * Reviewer         :
       * Reviewed Date    : 05/01/2013
       * Build Number     : CMS3.5.1_RI0023_B0010

       * Modified By      : Sagar
       * Modified reason  : Performance Issue
       * Modified On      : 01-Mar-2013
       * Reviewer         : Dhiraj
       * Reviewed Date    : 01-Mar-2013
       * Build Number     : CMS3.5.1_RI0023.1.3_B0001


       * Modified By      : Sagar
       * Modified reason  : Performance Issue
       * Modified On      : 25-Mar-2013
       * Reviewer         : Dhiraj
       * Reviewed Date    : 25-Mar-2013
       * Build Number     : CMS3.5.1_RI0024.1_B0002

       * Modified By      : Pankaj S.
       * Modified reason  : Performance Issue(mantis ID-11048)
       * Modified On      : 08-May-2013
       * Reviewer         : Dhiraj
       * Reviewed Date    :
       * Build Number     : CMS3.5.1_RI0024.1_B0017

	* Modified By      :  Siva Arcot
	* Modified reason  :  MVHOST-552
	* Modified On      :  03/09/2013
	* Modified For     :
	* Reviewer         :  Dhiraj
	* Reviewed Date    :  03/09/2013
	* Build Number     :  RI0024.3.6_B0002

    * Modified by      : MageshKumar.S
    * Modified Reason  : JH-6(Fast50  And State Tax Refund Alerts)
    * Modified Date    : 19-09-2013
    * Reviewer         : Dhiraj
    * Reviewed Date    : 19-09-2013
    * Build Number     : RI0024.5_B0001

    * Modified by      : MageshKumar S.
    * Modified Date    : 25-July-14
    * Modified For     : FWR-48
    * Modified reason  : GL Mapping removal changes
    * Reviewer         : Spankaj
    * Build Number     : RI0027.3.1_B0001

   * Modified By      : Raja Gopal G
   * Modified Date    : 30-Jul-2014
   * Modified Reason  : Check Deposit Pending ,Accepted And Rejected Alerts(FR 3.2)
   * Reviewer         : Spankaj
   * Build Number     : RI0027.3.1_B0002

   * Modified By      : MageshKumar S
   * Modified Date    : 18/07/2017
   * Purpose          : FSS-5157
   * Reviewer         : Saravanan/Pankaj S.
   * Release Number   : VMSGPRHOST17.07
    * Modified By      : Pankaj S.
    * Modified Date    : 19-July-2017
    * Purpose          : FSS-5157 (PAN Inventory Changes)
    * Reviewer         : Saravanakumar
    * Release Number   : VMSGPRHOST17.07
    
     * Modified By      : Akhil
     * Modified Date    : 22-Jan-2018
     * Purpose          : VMS-185
     * Reviewer         : Saravanakumar
     * Release Number   : VMSGPRHOST18.01
	 
	 * Modified By      : Vini Pushkaran
     * Modified Date    : 27-Feb-2018
     * Purpose          : VMS-161
     * Reviewer         : Saravanakumar
     * Release Number   : VMSGPRHOST18.02
     
     * Modified By      : Shanmugavel
     * Modified Date    : 23/01/2024
     * Purpose          : VMS-8219-Remove the Default Status in the Product Category Profile Screen on the Host UI
     * Reviewer         : Venkat/John/Pankaj
     * Release Number   : VMSGPRHOSTR92
   *************************************************/
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
   v_loop_cnt               NUMBER                                  DEFAULT 0;
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
 /*  v_func_code              cms_func_mast.cfm_func_code%TYPE;
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
   v_tran_type              cms_func_mast.cfm_txn_type%TYPE; */ -- commented for fwr-48
 --  v_expryparam             cms_bin_param.cbp_param_value%TYPE;
 --  v_validity_period        cms_bin_param.cbp_param_value%TYPE;
   v_savepoint              NUMBER                                  DEFAULT 1;
   v_emp_id                 cms_cust_mast.ccm_emp_id%TYPE;
   v_corp_code              cms_cust_mast.ccm_corp_code%TYPE;
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
   v_mask_pan               cms_appl_pan.cap_mask_pan%TYPE;
   v_cpc_serl_flag          cms_prod_cattype.cpc_serl_flag%TYPE;
   v_donot_mark_error       NUMBER (10)                             DEFAULT 0;
   v_cam_file_name          cms_appl_mast.cam_file_name%TYPE;
   v_startergpr_type        cms_prod_cattype.cpc_startergpr_issue%TYPE;
   v_gpr_card_type          cms_appl_pan.cap_card_type%TYPE;
   v_starter_card_flg       cms_appl_pan.cap_startercard_flag%TYPE;
   v_appl_count             NUMBER;
   p_shflcntrl_no           NUMBER (9);


   V_TRAN_CODE            VARCHAR2(2) DEFAULT 'IL' ; -- Added for fwr - 48
   V_TRAN_MODE            VARCHAR2(1) DEFAULT '0' ; -- Added for fwr - 48
   V_DELV_CHNL            VARCHAR2(2) DEFAULT '05' ; -- Added for fwr - 48
   V_TRAN_TYPE            VARCHAR2(1) DEFAULT '1' ; -- Added for fwr - 48
   v_pan_inventory_flag   cms_prod_cattype.cpc_pan_inventory_flag%TYPE;  --Added for 17.07 PAN Inventory Changes
   v_user_identify_type   cms_prod_cattype.cpc_user_identify_type%type;
   v_prod_suffix          cms_prod_cattype.cpc_prod_suffix%TYPE;
   v_card_start           cms_prod_cattype.cpc_start_card_no%TYPE;
   v_card_end             cms_prod_cattype.cpc_end_card_no%TYPE;
   v_prodprefx_index      NUMBER;
   v_prefix               VARCHAR2(10);
   
--   TYPE rec_pan_construct IS RECORD (
--      cpc_profile_code   cms_pan_construct.cpc_profile_code%TYPE,
--      cpc_field_name     cms_pan_construct.cpc_field_name%TYPE,
--      cpc_start_from     cms_pan_construct.cpc_start_from%TYPE,
--      cpc_start          cms_pan_construct.cpc_start%TYPE,
--      cpc_length         cms_pan_construct.cpc_length%TYPE,
--      cpc_field_value    VARCHAR2 (30)
--   );
--
--   TYPE table_pan_construct IS TABLE OF rec_pan_construct
--      INDEX BY BINARY_INTEGER;
--
--   v_table_pan_construct    table_pan_construct;
   exp_reject_record        EXCEPTION;
--
--   CURSOR c (p_profile_code IN VARCHAR2)
--   IS
--      SELECT   cpc_profile_code, cpc_field_name, cpc_start_from, cpc_length,
--               cpc_start
--          FROM cms_pan_construct
--         WHERE cpc_profile_code = p_profile_code
--               AND cpc_inst_code = p_instcode
--      --ORDER BY cpc_start_from DESC
--      ;

   CURSOR c1 (appl_code IN NUMBER)
   IS
      SELECT cad_acct_id, cad_acct_posn
        FROM cms_appl_det
       WHERE cad_appl_code = p_applcode AND cad_inst_code = p_instcode;

   --SN    LOCAL PROCEDURES
   PROCEDURE lp_pan_bin (
      p_instcode    IN       NUMBER,
      p_insttype    IN       NUMBER,
      p_prod_code   IN       VARCHAR2,
      p_pan_bin     OUT      NUMBER,
      p_errmsg      OUT      VARCHAR2
   )
   IS
   BEGIN
      SELECT cpb_inst_bin
        INTO p_pan_bin
        FROM cms_prod_bin
       WHERE cpb_inst_code = p_instcode
         AND cpb_prod_code = p_prod_code
         AND cpb_active_bin = 'Y';

      p_errmsg := 'OK';
   EXCEPTION
      WHEN NO_DATA_FOUND
      THEN
         p_errmsg :=
               'Excp1 LP1 -- No prefix  found for combination of Institution '
            || p_instcode
            || ' and product '
            || p_prod_code;
      WHEN OTHERS
      THEN
         p_errmsg := 'Excp1 LP1 -- ' || SQLERRM;
   END lp_pan_bin;

--   PROCEDURE lp_pan_srno (
--      p_instcode     IN       NUMBER,
--      p_lupduser     IN       NUMBER,
--      p_tmp_pan      IN       VARCHAR2,
--      p_max_length   IN       NUMBER,
--      p_srno         OUT      VARCHAR2,
--      p_errmsg       OUT      VARCHAR2
--   )
--   IS
--      v_ctrlnumb        NUMBER;
--      v_max_serial_no   NUMBER;
--      --Sn Added by Pankaj S. on 08_May_2013 for mantis ID-11048
--      excp_reject        EXCEPTION;
--      resource_busy      EXCEPTION;
--      PRAGMA EXCEPTION_INIT (resource_busy, -30006);
--      PRAGMA AUTONOMOUS_TRANSACTION;
--      --En Added by Pankaj S. on 08_May_2013 for mantis ID-11048
--    BEGIN
--       p_errmsg := 'OK';
--
--       SELECT     cpc_ctrl_numb, cpc_max_serial_no
--             INTO v_ctrlnumb, v_max_serial_no
--             FROM cms_pan_ctrl
--            WHERE cpc_pan_prefix = p_tmp_pan AND cpc_inst_code = p_instcode
--       FOR UPDATE WAIT 1; --Modified by Pankaj S. on 08_May_2013 for mantis ID-11048  --Added "For update" for locking select query until update script will execute
--
--       -- IF V_CTRLNUMB > V_MAX_SERIAL_NO THEN
--       IF v_ctrlnumb > LPAD ('9', p_max_length, 9) THEN --Modified by Ramkumar.Mk, check the condition max serial number length
--          p_errmsg := 'Maximum serial number reached';
--          RAISE excp_reject;     --RETURN; --Modified by Pankaj S. on 08_May_2013 for mantis ID-11048
--       END IF;
--
--       p_srno := v_ctrlnumb;
--
--       --Sn Modified by Pankaj S. on 08_May_2013 for mantis ID-11048
--       BEGIN
--          UPDATE cms_pan_ctrl
--             SET cpc_ctrl_numb = v_ctrlnumb + 1
--           WHERE cpc_pan_prefix = p_tmp_pan AND cpc_inst_code = p_instcode;
--
--          IF SQL%ROWCOUNT = 0 THEN
--             p_errmsg := 'Error while updating serial no';
--             RAISE excp_reject;
--          END IF;
--
--          COMMIT;
--       EXCEPTION
--          WHEN excp_reject THEN
--             RAISE;
--          WHEN OTHERS THEN
--             p_errmsg := 'Error While Updating Serial Number ' || SQLERRM;
--             RAISE excp_reject;
--       END;
--    --En Modified by Pankaj S. on 08_May_2013 for mantis ID-11048
--    EXCEPTION
--       --Sn Added by Pankaj S. on 08_May_2013 for mantis ID-11048
--       WHEN resource_busy THEN
--          p_errmsg := 'PLEASE TRY AFTER SOME TIME';
--          ROLLBACK;
--       WHEN excp_reject THEN
--          ROLLBACK;
--       --En Added by Pankaj S. on 08_May_2013 for mantis ID-11048
--       WHEN NO_DATA_FOUND
--       THEN
--          INSERT INTO cms_pan_ctrl
--                      (cpc_inst_code, cpc_pan_prefix, cpc_ctrl_numb,
--                       cpc_max_serial_no
--                      )
--               VALUES (p_instcode, p_tmp_pan, 2, --p_instcode added by Pankaj S. 0n 08_May_2013 for mantis ID-11048
--                       LPAD ('9', p_max_length, 9)
--                      );
--
--          v_ctrlnumb := 1;
--          p_srno := v_ctrlnumb;
--          COMMIT; --Added by Pankaj S. on 08_May_2013 for mantis ID-11048
--       WHEN OTHERS
--       THEN
--          p_errmsg := 'Excp1 LP2 -- ' || SQLERRM;
--    END lp_pan_srno;

   PROCEDURE lp_pan_chkdig (p_tmppan IN VARCHAR2, p_checkdig OUT NUMBER)
   IS
      v_ceilable_sum   NUMBER     := 0;
      v_ceiled_sum     NUMBER;
      v_temp_pan       NUMBER;
      v_len_pan        NUMBER (3);
      v_res            NUMBER (3);
      v_mult_ind       NUMBER (1);
      v_dig_sum        NUMBER (2);
      v_dig_len        NUMBER (1);
   BEGIN
      v_temp_pan := p_tmppan;
      v_len_pan := LENGTH (v_temp_pan);
      v_mult_ind := 2;

      FOR i IN REVERSE 1 .. v_len_pan
      LOOP
         v_res := SUBSTR (v_temp_pan, i, 1) * v_mult_ind;
         v_dig_len := LENGTH (v_res);

         IF v_dig_len = 2
         THEN
            v_dig_sum := SUBSTR (v_res, 1, 1) + SUBSTR (v_res, 2, 1);
         ELSE
            v_dig_sum := v_res;
         END IF;

         v_ceilable_sum := v_ceilable_sum + v_dig_sum;

         IF v_mult_ind = 2
         THEN
            --IF 2
            v_mult_ind := 1;
         ELSE
            --Else of If 2
            v_mult_ind := 2;
         END IF;                                                 --End of IF 2
      END LOOP;

      v_ceiled_sum := v_ceilable_sum;

      IF MOD (v_ceilable_sum, 10) != 0
      THEN
         LOOP
            v_ceiled_sum := v_ceiled_sum + 1;
            EXIT WHEN MOD (v_ceiled_sum, 10) = 0;
         END LOOP;
      END IF;

      p_checkdig := v_ceiled_sum - v_ceilable_sum;
   END lp_pan_chkdig;

--
--   PROCEDURE lp_shuffle_srno (
--      p_instcode       IN       NUMBER,
--      p_prod_code               cms_appl_mast.cam_prod_code%TYPE,
--      p_card_type               cms_appl_mast.cam_card_type%TYPE,
--      p_lupduser       IN       NUMBER,
--      p_shflcntrl_no   OUT      VARCHAR2,
--      v_serial_no      OUT      number,
--      p_errmsg         OUT      VARCHAR2
--   )
--   IS
--      v_csc_shfl_cntrl   NUMBER    := 0;
--      excp_reject        EXCEPTION;
--      resource_busy      EXCEPTION;
--      PRAGMA EXCEPTION_INIT (resource_busy, -30006);
--      PRAGMA AUTONOMOUS_TRANSACTION;
--   BEGIN
--      p_errmsg := 'OK';
--
--      BEGIN
--
--         SELECT  csc_shfl_cntrl
--               INTO v_csc_shfl_cntrl
--               FROM cms_shfl_cntrl
--              WHERE csc_inst_code = p_instcode
--                AND csc_prod_code = v_prod_code
--                AND csc_card_type = v_card_type
--         FOR UPDATE NOWAIT;
--
--
--         BEGIN
--
--            SELECT css_serl_numb -- Added on 25-Mar-2013
--              INTO v_serial_no
--              FROM cms_shfl_serl
--             WHERE css_inst_code = p_instcode
--               AND css_prod_code = v_prod_code
--               AND css_prod_catg = v_card_type
--               AND css_shfl_cntrl = v_csc_shfl_cntrl
--               AND css_serl_flag = 0;
--
--
--         EXCEPTION
--            WHEN NO_DATA_FOUND
--            THEN
--               p_errmsg :=
--                  'Shuffle Serial Number Not Found For Product And Product Catagory ';
--               RAISE excp_reject;
--            WHEN OTHERS
--            THEN
--               p_errmsg :=
--                      'Error While Finding Shuffle Serial Number ' || SQLERRM;
--               RAISE excp_reject;
--         END;
--
--
--         BEGIN
--            UPDATE cms_shfl_cntrl
--               SET csc_shfl_cntrl = v_csc_shfl_cntrl + 1
--             WHERE csc_inst_code = p_instcode
--               AND csc_prod_code = v_prod_code
--               AND csc_card_type = v_card_type;
--
--            IF SQL%ROWCOUNT = 0
--            THEN
--               p_errmsg :=
--                  'Shuffle Control Number Not Configuerd For Prodcut and Card Type';
--               RAISE excp_reject;
--               ROLLBACK ;
--            END IF;
--            COMMIT ;
--         EXCEPTION
--            WHEN excp_reject
--            THEN
--               RAISE;
--            WHEN OTHERS
--            THEN
--               p_errmsg :=
--                    'Error While Updating Shuffle Control Number ' || SQLERRM;
--                    ROLLBACK ;
--               RAISE excp_reject;
--
--         END;
--      EXCEPTION
--         WHEN excp_reject
--         THEN
--            RAISE;
--         WHEN NO_DATA_FOUND
--         THEN
--
--            BEGIN
--               INSERT INTO cms_shfl_cntrl
--                           (csc_inst_code, csc_prod_code, csc_card_type,
--                            csc_shfl_cntrl, csc_ins_user
--                           )
--                    VALUES (1, p_prod_code, p_card_type,
--                            2, 1 -- Modified for MVHOST-552 csc_shfl_cntrl is inserted as 2 instead of 1
--                           );
--
--               v_csc_shfl_cntrl := 1;
--               COMMIT;
--            EXCEPTION
--               WHEN OTHERS
--               THEN
--                  p_errmsg :=
--                        'While Inserting into CMS_SHFL_CNTRL  -- ' || SQLERRM;
--                  ROLLBACK;
--            END;
--
--
--            BEGIN
--
--                SELECT css_serl_numb -- Added on 25-Mar-2013
--                  INTO v_serial_no
--                  FROM cms_shfl_serl
--                 WHERE css_inst_code = p_instcode
--                   AND css_prod_code = v_prod_code
--                   AND css_prod_catg = v_card_type
--                   AND css_shfl_cntrl = v_csc_shfl_cntrl
--                   AND css_serl_flag = 0;
--
--
--            EXCEPTION
--                WHEN NO_DATA_FOUND
--                THEN
--                   p_errmsg :=
--                      'Shuffle Serial Number Not Found For Product And Product Catagory ';
--                   RAISE excp_reject;
--                WHEN OTHERS
--                THEN
--                   p_errmsg :=
--                          'Error While Finding Shuffle Serial Number ' || SQLERRM;
--                   RAISE excp_reject;
--            END;
--
--         WHEN resource_busy
--         THEN
--            p_errmsg := 'PLEASE TRY AFTER SOME TIME';
--            RAISE excp_reject;
--         WHEN OTHERS
--         THEN
--            p_errmsg :=
--                    'Error While Fetching Shuffle Control Number ' || SQLERRM;
--            RAISE excp_reject;
--      END;
--
--      p_shflcntrl_no := v_csc_shfl_cntrl;
--   EXCEPTION
--      WHEN excp_reject
--      THEN
--         p_errmsg := p_errmsg;
--         ROLLBACK;
--      WHEN OTHERS
--      THEN
--         p_errmsg := 'Main Exception From LP_SHUFFLE_SRNO ' || SQLERRM;
--         ROLLBACK;
--   END lp_shuffle_srno;


--EN    LOCAL PROCEDURES
BEGIN
   --<< MAIN BEGIN >>
   p_applprocess_msg := 'OK';
   p_errmsg := 'OK';
   v_inst_code := p_instcode;
   v_asso_code := prm_cam_asso_code;
   v_inst_type := prm_cam_inst_type;
   v_prod_code := prm_cam_prod_code;
   v_appl_bran := prm_cam_appl_bran;
   v_cust_code := prm_cam_cust_code;
   v_card_type := prm_cam_card_type;
   v_cust_catg := prm_cam_cust_catg;
   v_disp_name := prm_cam_disp_name;
   v_active_date := prm_cam_active_date;
   v_expry_date := prm_cam_expry_date;
   v_addon_stat := prm_cam_addon_stat;
   v_tot_acct := prm_cam_tot_acct;
   v_chnl_code := prm_cam_chnl_code;
   v_limit_amt := prm_cam_limit_amt;
   v_use_limit := prm_cam_use_limit;
   v_bill_addr := prm_cam_bill_addr;
   v_request_id := prm_cam_request_id;
   v_appl_stat := prm_cam_appl_stat;
   v_initial_topup_amount := prm_cam_initial_topup_amount;
   v_starter_card := prm_cam_starter_card;
   v_cam_file_name := prm_cam_file_name;
   v_cam_addon_link := prm_cam_addon_link;

   --Sn generate savepoint number
   BEGIN
      SELECT seq_pangen_savepoint.NEXTVAL
        INTO v_savepoint
        FROM DUAL;
   EXCEPTION
      WHEN OTHERS
      THEN
         v_errmsg :=
                    'Error from sequence pangen ' || SUBSTR (SQLERRM, 1, 200);
         RAISE exp_reject_record;
   END;

   --En generate savepoint number
   SAVEPOINT v_savepoint;

   --Sn find hsm mode
   BEGIN
      SELECT cip_param_value
        INTO v_hsm_mode
        FROM cms_inst_param
       WHERE cip_param_key = 'HSM_MODE' AND cip_inst_code = p_instcode;

      IF v_hsm_mode = 'Y'
      THEN
         v_pingen_flag := 'Y';                           -- i.e. generate pin
         v_emboss_flag := 'Y';                 -- i.e. generate embossa file.
      ELSE
         v_pingen_flag := 'N';                     -- i.e. don't generate pin
         v_emboss_flag := 'N';           -- i.e. don't generate embossa file.
      END IF;
   EXCEPTION
      WHEN NO_DATA_FOUND
      THEN
         v_hsm_mode := 'N';
         v_pingen_flag := 'N';                     -- i.e. don't generate pin
         v_emboss_flag := 'N';           -- i.e. don't generate embossa file.
   END;

   --En find hsm mode

   --Sn find the bin for the product code
   BEGIN
      lp_pan_bin (v_inst_code, v_inst_type, v_prod_code, v_bin, v_errmsg);

      IF v_errmsg <> 'OK'
      THEN
         RAISE exp_reject_record;
      END IF;
   EXCEPTION
      WHEN exp_reject_record
      THEN
         RAISE;
      WHEN OTHERS
      THEN
         v_errmsg :=
               'Error while selecting bin from binmast'
            || SUBSTR (SQLERRM, 1, 300);
         RAISE exp_reject_record;
   END;

   --En find the bin for the product code
   --Sn find profile code attached to cardtype
   BEGIN
      SELECT cpc_profile_code, cpm_catg_code, cpc_prod_prefix,
             cpc_program_id, cpm_proxy_length, cpc_serl_flag,
             cpc_startergpr_issue, cpc_starter_card,
             NVL(cpc_pan_inventory_flag, 'N'),cpc_user_identify_type, --Added for 17.07 PAN Inventory Changes
             cpc_prod_suffix, cpc_start_card_no, cpc_end_card_no 
        INTO v_profile_code, v_cpm_catg_code, v_prod_prefix,
             v_programid, v_proxylength, v_cpc_serl_flag,
             v_startergpr_type, v_starter_card_flg,
             v_pan_inventory_flag,v_user_identify_type,  --Added for 17.07 PAN Inventory Changes
             v_prod_suffix, v_card_start, v_card_end
        FROM cms_prod_cattype, cms_prod_mast
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
         RAISE exp_reject_record;
      WHEN OTHERS
      THEN
         v_errmsg :=
               'Error while selecting applcode from applmast'
            || SUBSTR (SQLERRM, 1, 300);
         RAISE exp_reject_record;
   END;

   --T.Narayanan changed for the product category changes for gpr card

   -- T.Narayanan added one more if condition for starter card generation card type issue on 05/10/2012
   BEGIN
      SELECT COUNT (*)
        INTO v_appl_count
        FROM cms_appl_pan
       WHERE cap_appl_code = p_applcode AND cap_inst_code = p_instcode;
   EXCEPTION
      WHEN NO_DATA_FOUND
      THEN
         NULL;
   END;

   IF v_appl_count > 0
   THEN
      IF v_starter_card_flg = 'Y'
      THEN
         IF v_startergpr_type = 'M'
         THEN
            BEGIN
               SELECT cpc_startergpr_crdtype
                 INTO v_gpr_card_type
                 FROM cms_prod_cattype
                WHERE cpc_prod_code = v_prod_code
                  AND cpc_inst_code = p_instcode
                  AND cpc_starter_card != 'N'
                  AND cpc_card_type = v_card_type;

               IF v_gpr_card_type != 0
               THEN
                  v_card_type := v_gpr_card_type;
               END IF;
            EXCEPTION
               WHEN NO_DATA_FOUND
               THEN
                  v_errmsg :=
                        'GPR Product Category not found for product code '
                     || v_prod_code
                     || 'card type '
                     || v_card_type;
                  RAISE exp_reject_record;
               WHEN OTHERS
               THEN
                  v_errmsg :=
                        'Error while selecting GPR Product Category from cms_prod_cattype'
                     || SUBSTR (SQLERRM, 1, 300);
                  RAISE exp_reject_record;
            END;
         END IF;
      END IF;
   END IF;

   -- T.Narayanan added one more if condition for starter card generation card type issue
   --T.Narayanan changed for the product category changes for gpr card

   -- Added by Trivkram on 08 June 2012 , If not configure PAN Product Category Prefix with Product Category level it will take from Instistute level
   IF v_prod_prefix IS NULL
   THEN
      BEGIN
         SELECT cip_param_value
           INTO v_prod_prefix
           FROM cms_inst_param
          WHERE cip_inst_code = p_instcode
            AND cip_param_key = 'PANPRODCATPREFIX';
      EXCEPTION
         WHEN OTHERS
         THEN
            v_errmsg :=
                  'Error while selecting PAN Product Category Prefix from CMS_INST_PARAM '
               || SUBSTR (SQLERRM, 1, 300);
            RAISE exp_reject_record;
      END;
   END IF;

   --En find profile code attached to cardtype
 IF v_pan_inventory_flag='N' THEN  --Added for 17.07 PAN Inventory Changes
   --Sn find pan construct details based on profile code
--   BEGIN
--      v_loop_cnt := 0;
--
--      FOR i IN c (v_profile_code)
--      LOOP
--         v_loop_cnt := v_loop_cnt + 1;
--
--         SELECT i.cpc_profile_code,
--                i.cpc_field_name,
--                i.cpc_start_from,
--                i.cpc_length,
--                i.cpc_start
--           INTO v_table_pan_construct (v_loop_cnt).cpc_profile_code,
--                v_table_pan_construct (v_loop_cnt).cpc_field_name,
--                v_table_pan_construct (v_loop_cnt).cpc_start_from,
--                v_table_pan_construct (v_loop_cnt).cpc_length,
--                v_table_pan_construct (v_loop_cnt).cpc_start
--           FROM DUAL;
--      END LOOP;
--   EXCEPTION
--      WHEN OTHERS
--      THEN
--         v_errmsg :=
--               'Error while selecting profile detail from profile mast '
--            || SUBSTR (SQLERRM, 1, 300);
--         RAISE exp_reject_record;
--   END;
--
--   --En find pan construct details based on profile code
--   --Sn built the pan gen logic based on the value (except serial no)
--   BEGIN
--      v_loop_max_cnt := v_table_pan_construct.COUNT;
--      v_tmp_pan := NULL;
--
--      FOR i IN 1 .. v_loop_max_cnt
--      LOOP
--         IF v_table_pan_construct (i).cpc_field_name = 'Card Type'
--         THEN
--            v_table_pan_construct (i).cpc_field_value :=
--               LPAD (SUBSTR (TRIM (v_card_type),
--                             v_table_pan_construct (i).cpc_start,
--                             v_table_pan_construct (i).cpc_length
--                            ),
--                     v_table_pan_construct (i).cpc_length,
--                     '0'
--                    );
--         ELSIF v_table_pan_construct (i).cpc_field_name = 'Branch'
--         THEN
--            v_table_pan_construct (i).cpc_field_value :=
--               LPAD (SUBSTR (TRIM (v_appl_bran),
--                             v_table_pan_construct (i).cpc_start,
--                             v_table_pan_construct (i).cpc_length
--                            ),
--                     v_table_pan_construct (i).cpc_length,
--                     '0'
--                    );
--         ELSIF v_table_pan_construct (i).cpc_field_name = 'BIN / PREFIX'
--         THEN
--            v_table_pan_construct (i).cpc_field_value :=
--               LPAD (SUBSTR (TRIM (v_bin),
--                             v_table_pan_construct (i).cpc_start,
--                             v_table_pan_construct (i).cpc_length
--                            ),
--                     v_table_pan_construct (i).cpc_length,
--                     '0'
--                    );
--         ELSIF v_table_pan_construct (i).cpc_field_name =
--                                                 'PAN Product Category Prefix'
--         THEN
--            -- Modified by Trivikram on 06 June 2012 to distinguish Product Category Prefix of Account and PAN
--            v_table_pan_construct (i).cpc_field_value :=
--               LPAD (SUBSTR (TRIM (v_prod_prefix),
--                             v_table_pan_construct (i).cpc_start,
--                             v_table_pan_construct (i).cpc_length
--                            ),
--                     v_table_pan_construct (i).cpc_length,
--                     '0'
--                    );
--         ELSE
--            IF v_table_pan_construct (i).cpc_field_name <> 'Serial Number'
--            THEN
--               v_errmsg :=
--                     'Pan construct '
--                  || v_table_pan_construct (i).cpc_field_name
--                  || ' not exist ';
--               RAISE exp_reject_record;
--            END IF;
--         END IF;
--      END LOOP;
--   EXCEPTION
--      WHEN exp_reject_record
--      THEN
--         RAISE;
--      WHEN OTHERS
--      THEN
--         v_errmsg := 'Error from pangen process ' || SUBSTR (SQLERRM, 1, 300);
--         RAISE exp_reject_record;
--   END;
--
--   --En built the pan gen logic based on the value
--
--   --Sn generate the serial no
--   FOR i IN 1 .. v_loop_max_cnt
--   LOOP
--      --<< i loop >>
--      FOR j IN 1 .. v_loop_max_cnt
--      LOOP
--         --<< j  loop >>
--         IF     v_table_pan_construct (j).cpc_start_from = i
--            AND v_table_pan_construct (j).cpc_field_name <> 'Serial Number'
--         THEN
--            v_tmp_pan :=
--                       v_tmp_pan || v_table_pan_construct (j).cpc_field_value;
--            EXIT;
--         END IF;
--      END LOOP;                                            --<< j  end loop >>
--   END LOOP;                                                --<< i end loop >>
--
--   --Sn get  index value of serial no from PL/SQL table
--   FOR i IN 1 .. v_table_pan_construct.COUNT
--   LOOP
--      IF v_table_pan_construct (i).cpc_field_name = 'Serial Number'
--      THEN
--         v_serial_index := i;
--      END IF;
--   END LOOP;
--
--   --En get  index value of serial no from PL/SQL table
--   IF v_serial_index IS NOT NULL
--   THEN
--      v_serial_maxlength := v_table_pan_construct (v_serial_index).cpc_length;
--
--      IF v_cpc_serl_flag = 1
--      THEN
--
--         BEGIN
--            lp_shuffle_srno (p_instcode,
--                             v_prod_code,
--                             v_card_type,
--                             p_lupduser,
--                             p_shflcntrl_no,
--                             v_serial_no,
--                             v_errmsg
--                            );
--
--            IF v_errmsg <> 'OK'
--            THEN
--               v_donot_mark_error := 1;
--               RAISE exp_reject_record;
--            END IF;
--
--         EXCEPTION when exp_reject_record
--         then
--             raise;
--
--         WHEN OTHERS
--         THEN
--               v_errmsg :=
--                     'Error while calling LP_SHUFFLE_SRNO '
--                  || SUBSTR (SQLERRM, 1, 300);
--               RAISE exp_reject_record;
--         END;
--
--
--         BEGIN
--
--           /*
--            UPDATE cms_shfl_serl
--               SET css_serl_flag = 1
--             WHERE css_serl_numb = v_serial_no
--               AND css_inst_code = p_instcode
--               AND css_prod_code = v_prod_code
--               AND css_prod_catg = v_card_type
--               AND css_serl_flag = 0;
--            */
--
--            UPDATE cms_shfl_serl   -- Added on 25-Mar-2013
--               SET css_serl_flag = 1
--             WHERE css_inst_code = p_instcode
--               AND css_prod_code = v_prod_code
--               AND css_prod_catg = v_card_type
--               AND css_shfl_cntrl = p_shflcntrl_no
--               AND css_serl_flag = 0;
--
--
--            IF SQL%ROWCOUNT = 0
--            THEN
--               v_errmsg :=
--                  'Error updating Serial  control data, record not updated successfully';
--               RAISE exp_reject_record;
--            END IF;
--         EXCEPTION
--            WHEN OTHERS
--            THEN
--               v_errmsg :=
--                   'Error updating control data ' || SUBSTR (SQLERRM, 1, 150);
--               RAISE exp_reject_record;
--         END;
--      ELSE
--         BEGIN
--            lp_pan_srno (p_instcode,
--                         p_lupduser,
--                         v_tmp_pan,
--                         v_serial_maxlength,
--                         v_serial_no,
--                         v_errmsg
--                        );
--
--            IF v_errmsg <> 'OK'
--            THEN
--               RAISE exp_reject_record;
--            END IF;
--         EXCEPTION
--            WHEN exp_reject_record THEN
--            RAISE;
--            WHEN OTHERS
--            THEN
--               v_errmsg :=
--                     'Error while calling LP_PAN_SRNO '
--                  || SUBSTR (SQLERRM, 1, 300);
--               RAISE exp_reject_record;
--         END;
--      END IF;
--
--      v_table_pan_construct (v_serial_index).cpc_field_value :=
--         LPAD (SUBSTR (TRIM (v_serial_no),
--                       v_table_pan_construct (v_serial_index).cpc_start,
--                       v_table_pan_construct (v_serial_index).cpc_length
--                      ),
--               v_table_pan_construct (v_serial_index).cpc_length,
--               '0'
--              );
--   END IF;
--
--   --En generate the serial no
--   --Sn generate temp pan for check digit
--   v_tmp_pan := NULL;
--
--   FOR i IN 1 .. v_loop_max_cnt
--   LOOP
--      FOR j IN 1 .. v_loop_max_cnt
--      LOOP
--         IF v_table_pan_construct (j).cpc_start_from = i
--         THEN
--            v_tmp_pan :=
--                       v_tmp_pan || v_table_pan_construct (j).cpc_field_value;
--            EXIT;
--         END IF;
--      END LOOP;
--   END LOOP;
--
--   --En generate temp pan for check digit

 BEGIN
    vmscard.get_pan_srno (p_instcode,
                          v_prod_code,
                          v_card_type,
                          v_prod_prefix,
                          v_prod_suffix,
                          v_card_start,  
                          v_card_end,
                          v_cpc_serl_flag,
                          v_prefix,
                          v_serial_no,
                          v_errmsg);

       IF V_ERRMSG <> 'OK' THEN
        RAISE EXP_REJECT_RECORD;
       END IF;
     EXCEPTION
       --Sn added by Pankaj S. on 08_May_2013 for mantis ID-11048
       WHEN EXP_REJECT_RECORD THEN
       RAISE;
       --En added by Pankaj S. 0n 08_May_2013 for mantis ID-11048
       WHEN OTHERS THEN
        V_ERRMSG := 'Error while calling get_pan_srno ' ||
                  SUBSTR(SQLERRM, 1, 300);
        RAISE EXP_REJECT_RECORD;
     END;
     
     V_TMP_PAN := NULL;
     
     BEGIN
     FOR I
         IN (SELECT cpc_profile_code,
                    cpc_field_name,
                    cpc_start_from,
                    cpc_length,
                    cpc_start
               FROM cms_pan_construct
              WHERE cpc_profile_code = V_PROFILE_CODE
                    AND cpc_inst_code = P_INSTCODE
                    order by cpc_start_from)
      LOOP
         IF i.cpc_field_name = 'Card Type'
         THEN
            V_TMP_PAN := V_TMP_PAN || LPAD ( SUBSTR (TRIM (V_CARD_TYPE), I.CPC_START, I.CPC_LENGTH), I.CPC_LENGTH,'0');
         ELSIF i.cpc_field_name = 'Branch'
         THEN
            V_TMP_PAN := V_TMP_PAN || LPAD ( SUBSTR (TRIM (V_APPL_BRAN), I.CPC_START, I.CPC_LENGTH),  I.CPC_LENGTH, '0');
         ELSIF i.cpc_field_name = 'BIN / PREFIX'
         THEN
            V_TMP_PAN := V_TMP_PAN || LPAD ( SUBSTR (TRIM (V_BIN), I.CPC_START, I.CPC_LENGTH),  I.CPC_LENGTH, '0');
          ELSIF i.cpc_field_name = 'PAN Product Category Prefix'
         THEN
            V_TMP_PAN := V_TMP_PAN || LPAD ( SUBSTR (TRIM (V_PREFIX), I.CPC_START, I.CPC_LENGTH),  I.CPC_LENGTH, '0');
         ELSIF i.cpc_field_name = 'Serial Number'
         THEN
            V_TMP_PAN := V_TMP_PAN || LPAD ( SUBSTR (TRIM (V_SERIAL_NO), I.CPC_START, I.CPC_LENGTH),  I.CPC_LENGTH, '0');
         END IF;
      END LOOP;
   EXCEPTION
      WHEN OTHERS
      THEN
         V_ERRMSG :=
            'Error while getting temp PAN:' || SUBSTR (SQLERRM, 1, 200);
   END;
   
   --Sn generate for check digit
   lp_pan_chkdig (v_tmp_pan, v_check_digit);
   v_pan := v_tmp_pan || v_check_digit;

   --En generate for check digit
   --SN:Added for 17.07 PAN Inventory Changes
 ELSE
       vmscard.get_card_no (v_prod_code,
                            v_card_type,
                            v_pan,
                            v_errmsg);
       IF v_errmsg <> 'OK' THEN
          v_errmsg := 'Error from get_card_no-' || v_errmsg;
          RAISE exp_reject_record;
       END IF;
 END IF;
 --EN:Added for 17.07 PAN Inventory Changes

   --SN CREATE HASH PAN
   BEGIN
      v_hash_pan := gethash (v_pan);
   EXCEPTION
      WHEN OTHERS
      THEN
         v_errmsg :=
                    'Error while converting pan ' || SUBSTR (SQLERRM, 1, 200);
         RAISE exp_reject_record;
   END;

   --EN CREATE HASH PAN

   --SN create encr pan
   BEGIN
      v_encr_pan := fn_emaps_main (v_pan);
   EXCEPTION
      WHEN OTHERS
      THEN
         v_errmsg :=
                    'Error while converting pan ' || SUBSTR (SQLERRM, 1, 200);
         RAISE exp_reject_record;
   END;

   --EN create encr pan

   --SN create Mask PAN  -- Added by sagar on 06Aug2012 for Pan masking changes
   BEGIN
      v_mask_pan := fn_getmaskpan (v_pan);
   EXCEPTION
      WHEN OTHERS
      THEN
         v_errmsg :=
               'Error while converting into mask pan '
            || SUBSTR (SQLERRM, 1, 200);
         RAISE exp_reject_record;
   END;

   -- Sn find primary acct no for the pan
   BEGIN
      SELECT cam_acct_id, cam_acct_no
        INTO v_acct_id, v_acct_num
        FROM cms_acct_mast
       WHERE cam_inst_code = p_instcode
         AND cam_acct_id =
                (SELECT cad_acct_id
                   FROM cms_appl_det
                  WHERE cad_inst_code = p_instcode
                    AND cad_appl_code = p_applcode
                    AND cad_acct_posn = 1);
   EXCEPTION
      WHEN NO_DATA_FOUND
      THEN
         v_errmsg :=
                   'No account primary  defined for appl code ' || p_applcode;
         RAISE exp_reject_record;
      WHEN OTHERS
      THEN
         v_errmsg :=
               'Error while selecting acct detail for pan '
            || SUBSTR (SQLERRM, 1, 200);
         RAISE exp_reject_record;
   END;

   --En find primary acct no for the pan

   --Sn entry for addon stat
   IF v_addon_stat = 'A'
   THEN
      BEGIN
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
            RAISE exp_reject_record;
         WHEN OTHERS
         THEN
            v_errmsg := 'Excp1.1 -- ' || SQLERRM;
            RAISE exp_reject_record;
      END;                                                  --end of begin 1.1
   ELSIF v_addon_stat = 'P'
   THEN
      --v_adonlink    :=    v_pan;
      v_adonlink := v_hash_pan;
      v_mbrlink := '000';
   END IF;

v_card_stat := '0';  -- VMS-8219
   --En entry for addon stat
   --Sn find card status and limit parameter for the profile
--   BEGIN
--      SELECT cbp_param_value
--        INTO v_card_stat
--        FROM cms_bin_param
--       WHERE cbp_inst_code = p_instcode
--         AND cbp_profile_code = v_profile_code
--         AND cbp_param_name = 'Status';
--
--      IF v_card_stat IS NULL
--      THEN
--         v_errmsg := 'Status is null for profile code ' || v_profile_code;
--         RAISE exp_reject_record;
--      END IF;
--   EXCEPTION
--      WHEN exp_reject_record
--      THEN
--         RAISE;
--      WHEN NO_DATA_FOUND
--      THEN
--         v_errmsg :=
--                  'Status is not defined for profile code ' || v_profile_code;
--         RAISE exp_reject_record;
--      WHEN OTHERS
--      THEN
--         v_errmsg :=
--             'Error while selecting card status ' || SUBSTR (SQLERRM, 1, 200);
--         RAISE exp_reject_record;
--   END;

   --En find card status and limit parameter for the profile

   --msiva en added for Expiry date calculate
   IF v_request_id IS NOT NULL
   THEN
      v_issueflag := 'N';
   ELSE
      v_issueflag := 'Y';
   END IF;

   -- If card is corporate then we need emp id  and corp id from cust_mast.
   BEGIN
      SELECT ccm_emp_id, ccm_corp_code
        INTO v_emp_id, v_corp_code
        FROM cms_cust_mast
       WHERE ccm_inst_code = p_instcode AND ccm_cust_code = v_cust_code;
   EXCEPTION
      WHEN NO_DATA_FOUND
      THEN
         v_errmsg := 'Customer code not found in master';
         RAISE exp_reject_record;
      WHEN OTHERS
      THEN
         v_errmsg :=
               'Error while selecting customer code from master'
            || SUBSTR (SQLERRM, 1, 150);
         RAISE exp_reject_record;
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
         RAISE exp_reject_record;
      WHEN OTHERS
      THEN
         v_errmsg :=
               'Error while selecting memeber number '
            || SUBSTR (SQLERRM, 1, 200);
         RAISE exp_reject_record;
   END;

   --En get member number from master
/*
   --Sn proxy number
   IF v_proxylength = '12'
-- ADDED by sagar on 29-mar-2012 to decide length of proxy number to be generated
   THEN
      BEGIN
         --T.Narayanan added for program id generation beg
         v_getseqno :=
               'SELECT CPI_SEQUENCE_NO FROM CMS_PROGRAM_ID_CNT WHERE CPI_PROGRAM_ID='
            || CHR (39)
            || v_programid
            || CHR (39)
            || 'AND CPI_INST_CODE='
            || p_instcode;

         EXECUTE IMMEDIATE v_getseqno
                      INTO v_seqno;

         v_proxy_number :=
            fn_proxy_no (SUBSTR (v_pan, 1, 6),
                         LPAD (v_card_type, 2, 0),
                         v_programid,
                         NVL (v_seqno, 0),
                         p_instcode,
                         p_lupduser
                        );

         --T.Narayanan added for program id generation end
         IF v_proxy_number = '0'
         THEN
            v_errmsg :=
                  'Error while gen Proxy number ' || SUBSTR (SQLERRM, 1, 200);
            RAISE exp_reject_record;
         END IF;
      EXCEPTION
         WHEN OTHERS
         THEN
            v_errmsg :=
                      'Error while Proxy number ' || SUBSTR (SQLERRM, 1, 200);
            RAISE exp_reject_record;
      END;
   ELSIF v_proxylength = '9'
   THEN

      BEGIN
         SELECT     LPAD (cpc_prxy_cntrlno, 9, 0)
               INTO v_proxy_number
               FROM cms_prxy_cntrl
              WHERE cpc_prxy_key = 'PRXYCTRL' AND cpc_inst_code = p_instcode
         FOR UPDATE;
      EXCEPTION
         WHEN NO_DATA_FOUND
         THEN
            v_errmsg :=
                  'Proxy Number Not Found For Institution Code --  '
               || p_instcode
               || SUBSTR (SQLERRM, 1, 200);
            RAISE exp_reject_record;
         WHEN OTHERS
         THEN
            v_errmsg :=
               'Error While Fetching Proxy Number'
               || SUBSTR (SQLERRM, 1, 200);
            RAISE exp_reject_record;
      END;

      BEGIN
         UPDATE cms_prxy_cntrl
            SET cpc_prxy_cntrlno = cpc_prxy_cntrlno + 1,
                cpc_lupd_user = p_lupduser,
                cpc_lupd_date = SYSDATE
          WHERE cpc_prxy_key = 'PRXYCTRL' AND cpc_inst_code = p_instcode;

         IF SQL%ROWCOUNT = 0
         THEN
            v_errmsg :=
               'Error updating Proxy  control data, record not updated successfully';
            RAISE exp_reject_record;
         END IF;
      EXCEPTION
         WHEN OTHERS
         THEN
            v_errmsg :=
                   'Error updating control data ' || SUBSTR (SQLERRM, 1, 150);
            RAISE exp_reject_record;
      END;

   ELSE
      v_errmsg := 'Invalid length for proxy number generation';
      RAISE exp_reject_record;
   END IF;


*/
   --En proxy number

   --Sn create a record in appl_pan
   BEGIN
      INSERT INTO cms_appl_pan
                  (cap_appl_code, cap_inst_code, cap_asso_code,
                   cap_inst_type, cap_prod_code, cap_prod_catg,
                   cap_card_type, cap_cust_catg, cap_pan_code, cap_mbr_numb,
                   cap_card_stat, cap_cust_code, cap_disp_name,
                   cap_limit_amt, cap_use_limit, cap_appl_bran,
                   cap_expry_date, cap_addon_stat, cap_addon_link,
                   cap_mbr_link, cap_acct_id, cap_acct_no, cap_tot_acct,
                   cap_bill_addr, cap_chnl_code, cap_pangen_date,
                   cap_pangen_user, cap_cafgen_flag, cap_pin_flag,
                   cap_embos_flag, cap_phy_embos, cap_join_feecalc,
                   cap_next_bill_date, cap_next_mb_date, cap_request_id,
                   cap_issue_flag, cap_ins_user, cap_lupd_user,
                   cap_atm_offline_limit, cap_atm_online_limit,
                   cap_pos_offline_limit, cap_pos_online_limit,
                   cap_offline_aggr_limit, cap_online_aggr_limit,
                   cap_emp_id, cap_firsttime_topup, cap_panmast_param1,
                   cap_panmast_param2, cap_panmast_param3,
                   cap_panmast_param4, cap_panmast_param5,
                   cap_panmast_param6, cap_panmast_param7,
                   cap_panmast_param8, cap_panmast_param9,
                   cap_panmast_param10, cap_pan_code_encr, cap_proxy_number,
                   cap_mmpos_online_limit, cap_mmpos_offline_limit,
                   cap_startercard_flag, cap_inactive_feecalc_date,
                   cap_mask_pan,cap_user_identify_type
                  )
           VALUES (p_applcode, p_instcode, v_asso_code,
                   v_inst_type, v_prod_code, v_cpm_catg_code,
                   v_card_type, v_cust_catg, v_hash_pan, v_mbrnumb,
                   v_card_stat, v_cust_code, v_disp_name,
                   v_limit_amt, v_use_limit, v_appl_bran,
                   v_expry_date, v_addon_stat, v_adonlink,
                   v_mbrlink, v_acct_id, v_acct_num, v_tot_acct,
                   v_bill_addr, v_chnl_code, SYSDATE,
                   p_lupduser, 'Y', v_pingen_flag,
                   v_emboss_flag, 'N', 'N',
                   NULL, NULL, v_request_id,
                   v_issueflag, p_lupduser, p_lupduser,
                   v_offline_atm_limit, v_online_atm_limit,
                   v_offline_pos_limit, v_online_pos_limit,
                   v_offline_aggr_limit, v_online_aggr_limit,
                   v_emp_id, 'N', v_appl_data (1),
                   v_appl_data (2), v_appl_data (3),
                   v_appl_data (4), v_appl_data (5),
                   v_appl_data (6), v_appl_data (7),
                   v_appl_data (8), v_appl_data (9),
                   v_appl_data (10), v_encr_pan, v_proxy_number,
                   v_online_mmpos_limit, v_offline_mmpos_limit,
                   v_starter_card, NULL,
                   v_mask_pan,v_user_identify_type
                  );
   EXCEPTION
      WHEN DUP_VAL_ON_INDEX
      THEN
         v_errmsg :=
               'Pan '
            || fn_getmaskpan (v_pan)
-- Masked pan will be returned if error occures instead of clear pan (Sagar-30-Aug-2012)
            || ' is already present in the Pan_master';
         RAISE exp_reject_record;
      WHEN OTHERS
      THEN
         v_errmsg :=
               'Error while inserting records into pan master '
            || SUBSTR (SQLERRM, 1, 200);
         RAISE exp_reject_record;
   END;

   --Inserting in card issuance status table
   BEGIN
      INSERT INTO cms_cardissuance_status
                  (ccs_inst_code, ccs_pan_code, ccs_card_status,
                   ccs_ins_user, ccs_lupd_user, ccs_pan_code_encr,
                   ccs_lupd_date, ccs_appl_code
                  )
           VALUES (p_instcode, v_hash_pan, 2,
                   p_lupduser, p_lupduser, v_encr_pan,
                   SYSDATE, p_applcode
                  );
   EXCEPTION
      WHEN OTHERS
      THEN
         v_errmsg :=
               'Error while Inserting in Card status Table '
            || SUBSTR (SQLERRM, 1, 200);
         RAISE exp_reject_record;
   END;

   --End

   --En create a record in appl_pan
   BEGIN
      INSERT INTO cms_smsandemail_alert
                  (csa_inst_code, csa_pan_code, csa_pan_code_encr,
                   csa_loadorcredit_flag, csa_lowbal_flag, csa_negbal_flag,
                   csa_highauthamt_flag, csa_dailybal_flag, csa_insuff_flag,
                   csa_incorrpin_flag,
                   CSA_FAST50_FLAG, -- Added by MageshKumar.S on 19/09/2013 for JH-6
                   CSA_FEDTAX_REFUND_FLAG, -- Added by MageshKumar.S on 19/09/2013 for JH-6
                   CSA_DEPPENDING_FLAG,CSA_DEPACCEPTED_FLAG,CSA_DEPREJECTED_FLAG, -- Added by Raja Gopal G on 30/07/2014 fro FR 3.2
                   csa_ins_user,
                   csa_ins_date
                  )
           VALUES (p_instcode, v_hash_pan, v_encr_pan,
                   0, 0, 0,
                   0, 0, 0,
                   0,
                   0, -- Added by MageshKumar.S on 19/09/2013 for JH-6
                   0, -- Added by MageshKumar.S on 19/09/2013 for JH-6
                    0, 0, 0, -- Added by Raja Gopal G on 30/07/2014 fro FR 3.2
                   p_lupduser, SYSDATE
                  );
   EXCEPTION
   WHEN  DUP_VAL_ON_INDEX THEN NULL;
      WHEN OTHERS
      THEN
         v_errmsg :=
               'Error while inserting records into SMS_EMAIL ALERT '
            || SUBSTR (SQLERRM, 1, 200);
         RAISE exp_reject_record;
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
                  'Duplicate record exist  in pan acct master for pan  '
               || fn_getmaskpan (v_pan)
-- Masked pan will be returned if error occures instead of clear pan (Sagar-30-Aug-2012)
               || 'acct id '
               || x.cad_acct_id;
            RAISE exp_reject_record;
         WHEN OTHERS
         THEN
            v_errmsg :=
                  'Error while inserting records into pan acct  master '
               || SUBSTR (SQLERRM, 1, 200);
            RAISE exp_reject_record;
      END;
   END LOOP;

   --En create record in pan_acct

   --Sn update Corporate Card for pan.
   BEGIN
      UPDATE cms_corporate_cards
         SET pcc_pan_no = v_hash_pan                                   --v_pan
                                    ,
             pcc_pan_no_encr = v_encr_pan
       WHERE pcc_inst_code = p_instcode AND pcc_pan_no = v_acct_num;
   EXCEPTION
      WHEN exp_reject_record
      THEN
         RAISE;
      WHEN OTHERS
      THEN
         v_errmsg :=
               'Error while updating corporate_card account number '
            || SUBSTR (SQLERRM, 1, 200);
         RAISE exp_reject_record;
   END;

   --En update acct_mast for pan

   --Sn update Corporate Card for pan.
   BEGIN
      UPDATE cms_merchant_cards
         SET pcc_pan_no = v_hash_pan                                   --v_pan
                                    ,
             pcc_pan_no_encr = v_encr_pan
       WHERE pcc_inst_code = p_instcode AND pcc_pan_no = v_acct_num;
   EXCEPTION
      WHEN exp_reject_record
      THEN
         RAISE;
      WHEN OTHERS
      THEN
         v_errmsg :=
               'Error while updating corporate_card account number '
            || SUBSTR (SQLERRM, 1, 200);
         RAISE exp_reject_record;
   END;

   --En update acct_mast for pan

   --SN -- Commented for fwr-48

   --Sn find the GL  detail for the func code
 /*  BEGIN
      SELECT cfp_crgl_code, cfp_crgl_catg, cfp_crsubgl_code, cfp_cracct_no,
             cfp_drgl_code, cfp_drgl_catg, cfp_drsubgl_code, cfp_dracct_no
        INTO v_cr_gl_code, v_crgl_catg, v_crsubgl_code, v_cracct_no,
             v_dr_gl_code, v_drgl_catg, v_drsubgl_code, v_dracct_no
        FROM cms_func_prod
       WHERE cfp_inst_code = p_instcode
         AND cfp_func_code = 'CRDISS'
         AND cfp_prod_code = v_prod_code
         AND cfp_prod_cattype = v_card_type;
   EXCEPTION
      WHEN NO_DATA_FOUND
      THEN
         v_errmsg :=
               'GL detail is not defined for func code  Card Issuance  prod code '
            || v_prod_code
            || 'card type '
            || v_card_type;
         RAISE exp_reject_record;
      WHEN OTHERS
      THEN
         v_errmsg :=
               'Error while selecting gl details for card issuance '
            || SUBSTR (SQLERRM, 1, 200);
         RAISE exp_reject_record;
   END;

   --En find the GL  detail for the func code
   IF v_cr_gl_code IS NULL OR v_crsubgl_code IS NULL
   THEN
      v_errmsg := 'Credit GL or SUB  GL cannot be null for card issuance';
      RAISE exp_reject_record;
   END IF;

   -- Sn create a record in GL_ACCT mast
   BEGIN
      SELECT 1
        INTO v_gl_check
        FROM cms_gl_mast
       WHERE cgm_inst_code = p_instcode AND cgm_gl_code = v_cr_gl_code;
   EXCEPTION
      WHEN NO_DATA_FOUND
      THEN
         v_errmsg := 'GL code is not defined for txn code ' || v_cr_gl_code;
         RAISE exp_reject_record;
      WHEN OTHERS
      THEN
         v_errmsg :=
               'Error while selecting gl code from master '
            || SUBSTR (SQLERRM, 1, 300);
         RAISE exp_reject_record;
   END;

   BEGIN
      SELECT csm_subgl_desc
        INTO v_subgl_desc
        FROM cms_sub_gl_mast
       WHERE csm_inst_code = p_instcode
         AND csm_gl_code = v_cr_gl_code
         AND csm_subgl_code = v_crsubgl_code;
   EXCEPTION
      WHEN NO_DATA_FOUND
      THEN
         v_errmsg :=
                   'Sub gl code is not defined for txn code ' || v_cr_gl_code;
         RAISE exp_reject_record;
      WHEN OTHERS
      THEN
         v_errmsg :=
               'Error while selecting sub gl code from master '
            || SUBSTR (SQLERRM, 1, 300);
         RAISE exp_reject_record;
   END;

   BEGIN
      INSERT INTO cms_gl_acct_mast
                  (cga_inst_code, cga_glcatg_code, cga_gl_code,
                   cga_subgl_code, cga_acct_code, cga_acct_desc,
                   cga_tran_amt, cga_glsubglacct_flag, cga_ins_date,
                   cga_lupd_user, cga_lupd_date
                  )
           VALUES (p_instcode, SUBSTR (v_crgl_catg, 1, 1), v_cr_gl_code,
                   v_crsubgl_code,
                                  --V_PAN,
                                  v_acct_num,
                                              --Modified by Ramkumar.Mk on 21 Aug, Acctnum inserted
                                              v_subgl_desc || 'acct',
                   0, 'Y',
--Modified by Ramkumar.mK on 21 Aug, when card generated, glsubglacct flag will be Y
                          SYSDATE,
                   p_lupduser, SYSDATE
                  );
   EXCEPTION
      WHEN DUP_VAL_ON_INDEX
      THEN
         NULL;
      WHEN OTHERS
      THEN
         v_errmsg :=
               'Error while selecting sub gl code from master '
            || SUBSTR (SQLERRM, 1, 300);
         RAISE exp_reject_record;
   END; */

   -- En create a record in GL_ACCT mast

   --EN -- Commented for fwr-48

   -- Sn Create a entry for initial load
   IF v_initial_topup_amount > 0
   THEN

   -- SN - commented for fwr - 48
      --Sn find f to txn code , type, delchannel attached to function code
   /*   BEGIN
         SELECT cfm_txn_code, cfm_txn_mode, cfm_delivery_channel,
                cfm_txn_type, cfm_func_desc
           INTO v_tran_code, v_tran_mode, v_delv_chnl,
                v_tran_type, v_func_desc
           FROM cms_func_mast
          WHERE cfm_func_code = 'INILOAD' AND cfm_inst_code = p_instcode;
      EXCEPTION
         WHEN NO_DATA_FOUND
         THEN
            v_errmsg :=
                     v_func_desc || 'Function code not defined for txn code ';
            RAISE exp_reject_record;
         WHEN TOO_MANY_ROWS
         THEN
            v_errmsg :=
                'More than one function defined for txn code ' || v_tran_code;
            RAISE exp_reject_record;
         WHEN OTHERS
         THEN
            v_errmsg :=
                  'Error while selecting func code from master '
               || SUBSTR (SQLERRM, 1, 300);
            RAISE exp_reject_record;
      END; */

      --En find function code attached to txn code

      -- EN - commented for fwr - 48

      BEGIN
         --Sn create gl data
         sp_create_issuance_gl_data                       -- FOR INITIAL LOAD
                                                     (p_instcode,
                                                      SYSDATE,
                                                      v_tran_code,
                                                      v_tran_mode,
                                                      v_tran_type,
                                                      v_delv_chnl,
                                                      v_pan,
                                                      v_prod_code,
                                                      v_card_type,
                                                      null, -- v_cr_gl_code, -- commented for fwr - 48
                                                      null, -- v_crsubgl_code, -- commented for fwr - 48
                                                      v_initial_topup_amount,
                                                      p_lupduser,
                                                      v_errmsg
                                                     );

         --En create gl data
         IF (v_errmsg <> 'OK')
         THEN
            RAISE exp_reject_record;
         END IF;
      --Sn update flag in appl_pan for initial load
      EXCEPTION
         WHEN OTHERS
         THEN
            v_errmsg :=
                  'Error while calling SP_CREATE_ISSUANCE_GL_DATA '
               || SUBSTR (SQLERRM, 1, 300);
            RAISE exp_reject_record;
      END;
   --En update flag in appl_pan for initial load
   END IF;

   --En create entry for initial load

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
               'Error while updating records in appl mast  '
            || SUBSTR (SQLERRM, 1, 200);
         RAISE exp_reject_record;
   END;

   --En update flag in appl_mast
   BEGIN
      INSERT INTO cms_audit_log_process
                  (cal_inst_code, cal_appl_no, cal_acct_no, cal_pan_no,
                   cal_prod_code,
                   cal_prg_name, cal_action,
                   cal_status,
                   cal_ref_tab_name, cal_ref_tab_rowid, cal_pan_encr,
                   cal_ins_user, cal_ins_date
                  )
           VALUES (p_instcode, p_applcode, v_acct_num, v_hash_pan,
                   (SELECT cpm.cpm_prod_desc
                      FROM cms_prod_mast cpm
                     WHERE cpm.cpm_prod_code = v_prod_code),
                   'PAN GENERATION', 'INSERT',
                   DECODE (v_errmsg, 'OK', 'SUCCESS', 'FAILURE'),

                   --                   P_ip_addr,
                   'CMS_APPL_PAN', '', fn_emaps_main (v_pan),
                   p_lupduser, SYSDATE
                  );
   EXCEPTION
      WHEN OTHERS
      THEN
         v_errmsg :=
               'Error while inserting CMS_AUDIT_LOG_PROCESS '
            || SUBSTR (SQLERRM, 1, 200);
         RAISE exp_reject_record;
   END;

   p_errmsg := 'OK';
   p_applprocess_msg := 'OK';
EXCEPTION
  WHEN EXP_REJECT_RECORD THEN
    ROLLBACK TO V_SAVEPOINT;
    P_ERRMSG := V_ERRMSG;

    IF V_DONOT_MARK_ERROR <> 1 THEN
     UPDATE CMS_APPL_MAST
        SET CAM_APPL_STAT   = 'E',
           CAM_PROCESS_MSG = V_ERRMSG,
           CAM_LUPD_USER   = P_LUPDUSER
      WHERE CAM_INST_CODE = P_INSTCODE AND CAM_APPL_CODE = P_APPLCODE;
    ELSIF V_DONOT_MARK_ERROR = 1 THEN
     INSERT INTO CMS_SERL_ERROR
       (CSE_INST_CODE,
        CSE_PROD_CODE,
        CSE_PROD_CATG,
        CSE_ORDR_RFRNO,
        CSE_ERR_MSEG)
     VALUES
       (P_INSTCODE, V_PROD_CODE, V_CARD_TYPE, V_CAM_FILE_NAME, V_ERRMSG);
    END IF;
    P_APPLPROCESS_MSG := V_ERRMSG;
    P_ERRMSG          := 'OK';
  WHEN OTHERS THEN
    ROLLBACK TO V_SAVEPOINT;
    P_APPLPROCESS_MSG := 'Error while processing application for pan gen ' ||
                    SUBSTR(SQLERRM, 1, 200);
    V_ERRMSG          := 'Error while processing application for pan gen ' ||
                    SUBSTR(SQLERRM, 1, 200);

    UPDATE CMS_APPL_MAST
      SET CAM_APPL_STAT   = 'E',
         CAM_PROCESS_MSG = V_ERRMSG,
         CAM_LUPD_USER   = P_LUPDUSER
    WHERE CAM_INST_CODE = P_INSTCODE AND CAM_APPL_CODE = P_APPLCODE;

    P_ERRMSG := 'OK';
END;
/
show error;