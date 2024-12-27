create or replace
PROCEDURE        vmscms.SP_GEN_PAN_STOCK_ISSU_STARTER (
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
   ----------------------------
   prm_hsm_mode                            cms_inst_param.cip_param_value%TYPE,
   prm_pingen_flag                         VARCHAR2,
   prm_emboss_flag                         VARCHAR2,
   prm_bin                                 cms_bin_mast.cbm_inst_bin%TYPE,
   prm_profile_code                        cms_prod_cattype.cpc_profile_code%TYPE,
   prm_cpm_catg_code                       cms_prod_mast.cpm_catg_code%TYPE,
   prm_programid                           VARCHAR2,
   prm_proxylength                         cms_prod_mast.cpm_proxy_length%TYPE,
   prm_cpc_serl_flag                       cms_prod_cattype.cpc_serl_flag%TYPE,
   prm_startergpr_type                     cms_prod_cattype.cpc_startergpr_issue%TYPE,
   prm_starter_card_flg                    cms_appl_pan.cap_startercard_flag%TYPE,
   prm_prod_prefix                         cms_prod_cattype.cpc_prod_prefix%TYPE,
   prm_tmp_pan                             cms_appl_pan.cap_pan_code%TYPE,
  -- prm_serial_index                        NUMBER,
   prm_card_stat                           cms_appl_pan.cap_card_stat%TYPE,
   prm_expiry_date                         DATE,
   prm_mbrnumb                             cms_inst_param.cip_param_value%TYPE,
   prm_loop_max_cnt                           NUMBER ,
   prm_prod_desc                            cms_prod_mast.cpm_prod_desc%TYPE ,
   ----------------------
   p_pan                          OUT      VARCHAR2,
   p_applprocess_msg              OUT      VARCHAR2,
   p_errmsg                       OUT      VARCHAR2,
   p_inventory_flag       IN VARCHAR2 DEFAULT 'N',
   p_prod_suffix          IN VARCHAR2,       
   p_card_start           IN VARCHAR2, 
   p_card_end             IN VARCHAR2
)
AS
   /*************************************************
       * Created  By      :  Dhiraj G
       * Created reason   :  Performance Changes.
       * Created On       :  15/04/2013
       * Created For      :  FSS-1158
       * Reviewer         :
       * Reviewed Date    :
       * Build Number     :  RI0024.1_B0013

       * Modified By      :  Sachin P.
       * Modified reason  :  Performance Changes.
       * Modified On      :  07/05/2013
       * Modified For     :  MANTIS ID- 11048
       * Reviewer         :
       * Reviewed Date    :
       * Build Number     :  RI0024.1_B0017

    * Modified By      :  Siva Arcot
    * Modified reason  :  MVHOST-552
    * Modified On      :  03/09/2013
    * Modified For     :
    * Reviewer         : Dhiraj
    * Reviewed Date    : 03/09/2013
    * Build Number     : RI0024.3.6_B0002

    * Modified by      : MageshKumar.S
    * Modified Reason  : JH-6(Fast50 FEDRAL And State Tax Refund Alerts)
    * Modified Date    : 19-09-2013
    * Reviewer         : Dhiraj
    * Reviewed Date    : 19-Sep-2013
    * Build Number     : RI0024.5_B0001

    * Modified by      : MageshKumar S.
    * Modified Date    : 25-July-14
    * Modified For     : FWR-48
    * Modified reason  : GL Mapping removal changes
    * Reviewer         : Spankaj
    * Build Number     : RI0027.3.1_B0001

     * Modified By      : Raja Gopal G
     * Modified Date    : 30-Jul-2014
     * Modified for     : FR 3.2
     * Modified Reason  : Check Deposit Pending ,Accepted And Rejected Alerts
     * Reviewer         : Spankaj
     * Build Number     : RI0027.3.1_B0002

     * Modified by      : Pankaj S.
     * Modified Date    : 14-Sep-16
     * Modified For     : FSS-4779
     * Modified reason  : Card Generation Performance changes
     * Reviewer         : Saravanakumar
     * Build Number     : 4.2.3   

     * Modified by      : Pankaj S.
     * Modified Date    : 14-Sep-16
     * Modified For     : FSS-4779
     * Modified reason  : Card Generation Performance changes
     * Reviewer         : Saravanakumar
     * Build Number     : 4.2.5             
   
     * Modified By      : Pankaj S.
     * Modified Date    : 19-July-2017
     * Purpose          : FSS-5157 (PAN Inventory Changes)
     * Reviewer         : Saravanakumar 
     * Release Number   : VMSGPRHOST17.07
     
     * Modified By      : Vini Pushkaran
     * Modified Date    : 27-Feb-2018
     * Purpose          : VMS-161
     * Reviewer         : Saravanakumar
     * Release Number   : VMSGPRHOST18.02

     * Modified By      : Pankaj S.
     * Modified Date    : 05-Feb-2023
     * Purpose          : VMS-6652
     * Reviewer         : Venkat S.
     * Release Number   : R78
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
   --v_serial_index           NUMBER;
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
   v_cpm_catg_code          cms_prod_mast.cpm_catg_code%TYPE;
   v_issueflag              VARCHAR2 (1);
   v_initial_topup_amount   cms_appl_mast.cam_initial_topup_amount%TYPE;
   v_expryparam             cms_bin_param.cbp_param_value%TYPE;
   v_validity_period        cms_bin_param.cbp_param_value%TYPE;
   v_savepoint              NUMBER                                  DEFAULT 1;
   v_mbrnumb                cms_appl_pan.cap_mbr_numb%TYPE;
   v_proxy_number           cms_appl_pan.cap_proxy_number%TYPE;
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
   --p_shflcntrl_no           NUMBER (9);
   v_prod_desc              cms_prod_mast.cpm_prod_desc%TYPE ;
   v_acct_posn              cms_appl_det.cad_acct_posn%TYPE; --Added for Performance changes
   v_user_identify_type cms_prod_cattype.cpc_user_identify_type%type;
   v_prefix                  VARCHAR2(10);
   v_toggle_value           cms_inst_param.cip_param_value%TYPE;  --Added for VMS-6652
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

   --v_table_pan_construct    table_pan_construct;
    --v_table_pan_construct   PKG_STOCK.table_pan_construct;
   exp_reject_record        EXCEPTION;

   CURSOR c (p_profile_code IN VARCHAR2)
   IS
      SELECT   cpc_profile_code, cpc_field_name, cpc_start_from, cpc_length,
               cpc_start
          FROM cms_pan_construct
         WHERE cpc_profile_code = p_profile_code
               AND cpc_inst_code = p_instcode
      --ORDER BY cpc_start_from DESC
      ;

 
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
--      PRAGMA AUTONOMOUS_TRANSACTION; --Added on 07.05.2013 for Performance Changes MANTIS ID- 11048
--      excp_reject        EXCEPTION;--Added on 07.05.2013 for Performance Changes MANTIS ID- 11048
--      resource_busy      EXCEPTION;--Added on 09.05.2013 for Performance Changes MANTIS ID- 11048
--      PRAGMA EXCEPTION_INIT (resource_busy, -30006);--Added on 09.05.2013 for Performance Changes MANTIS ID- 11048
--   BEGIN
--      p_errmsg := 'OK';
--
--      SELECT     cpc_ctrl_numb, cpc_max_serial_no
--            INTO v_ctrlnumb, v_max_serial_no
--            FROM cms_pan_ctrl
--           WHERE cpc_pan_prefix = p_tmp_pan AND cpc_inst_code = p_instcode
--      --FOR UPDATE;
--
--      FOR UPDATE WAIT 1; --Added on 07.05.2013 for Performance Changes MANTIS ID- 11048
--
----Added "For update" for locking select query until update script will execute
--
--      -- IF V_CTRLNUMB > V_MAX_SERIAL_NO THEN
--      IF v_ctrlnumb > LPAD ('9', p_max_length, 9)
--      THEN
--         --Modified by Ramkumar.Mk, check the condition max serial number length
--         p_errmsg := 'Maximum serial number reached';
--         ROLLBACK;--Added on 07.05.2013 for Performance Changes MANTIS ID- 11048
--         RETURN;
--      END IF;
--
--      p_srno := v_ctrlnumb;
--
--      UPDATE cms_pan_ctrl
--         SET cpc_ctrl_numb = v_ctrlnumb + 1
--       WHERE cpc_pan_prefix = p_tmp_pan AND cpc_inst_code = p_instcode;
--
--      IF SQL%ROWCOUNT = 0
--      THEN
--         p_errmsg := 'Error while updating serial no';
--         Raise excp_reject;
--      END IF;
--
--      COMMIT; --Added on 07.05.2013 for Performance Changes MANTIS ID- 11048
--
--   EXCEPTION
--      --SN Added on 07.05.2013 for Performance Changes MANTIS ID- 11048
--      WHEN excp_reject
--      THEN
--       ROLLBACK;
--
--       WHEN resource_busy
--         THEN
--            p_errmsg := 'PLEASE TRY AFTER SOME TIME';
--            ROLLBACK;
--       --EN Added on 07.05.2013 for PRAGMA/WAIT-NOWAIT Changes MANTIS ID- 11048
--      WHEN NO_DATA_FOUND
--      THEN
--         INSERT INTO cms_pan_ctrl
--                     (cpc_inst_code, cpc_pan_prefix, cpc_ctrl_numb,
--                      cpc_max_serial_no
--                     )
--              VALUES (1, p_tmp_pan, 2,
--                      LPAD ('9', p_max_length, 9)
--                     );
--
--         v_ctrlnumb := 1;
--         p_srno := v_ctrlnumb;
--         COMMIT; --Added on 07.05.2013 for Performance Changes MANTIS ID- 11048
--      WHEN OTHERS
--      THEN
--         p_errmsg := 'Excp1 LP2 -- ' || SQLERRM;
--         ROLLBACK;--Added on 07.05.2013 for Performance Changes MANTIS ID- 11048
--   END lp_pan_srno;

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
--      --PRAGMA EXCEPTION_INIT (resource_busy, -54);--Commnted and modified on 09.05.2013 for MANTIS ID- 11048
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
--         --FOR UPDATE NOWAIT;
--         FOR UPDATE WAIT 1; --Added on 07.05.2013 for Performance Changes MANTIS ID- 11048
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
--                        'While Inserting into cms_shfl_cntrl  -- ' || SQLERRM;
--                  ROLLBACK;
--            END;
--
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
  ----------------
    v_hsm_mode          :=  PRM_hsm_mode             ;
    v_pingen_flag         :=  PRM_pingen_flag          ;
    v_emboss_flag         :=  PRM_emboss_flag          ;
    v_bin                 :=  PRM_bin                  ;
    v_profile_code        :=  PRM_profile_code         ;
    v_cpm_catg_code       :=  PRM_cpm_catg_code        ;
    v_programid           :=  PRM_programid            ;
    v_proxylength         :=  PRM_proxylength          ;
    v_cpc_serl_flag       :=  PRM_cpc_serl_flag        ;
    v_startergpr_type     :=  PRM_startergpr_type      ;
    v_starter_card_flg    :=  PRM_starter_card_flg     ;
    v_prod_prefix         :=  PRM_prod_prefix          ;
    v_tmp_pan             :=  PRM_tmp_pan              ;
   -- v_serial_index        :=  PRM_serial_index         ;
    v_card_stat           :=  PRM_card_stat            ;
      v_expiry_date         :=  PRM_expiry_date          ;
    v_mbrnumb             :=  PRM_mbrnumb              ;
    v_loop_max_cnt:=prm_loop_max_cnt ;
    v_prod_desc  := prm_prod_desc;
    ----------------
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



  IF p_inventory_flag='N' THEN 
  
--  BEGIN--Added for 17.07 PAN Inventory Changes 
--/*   IF v_serial_index IS NOT NULL
--   THEN
--      v_serial_maxlength := v_table_pan_construct (v_serial_index).cpc_length;
--
--      IF v_cpc_serl_flag = 1
--      THEN
--
--
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
--  /*          UPDATE cms_shfl_serl   -- Added on 25-Mar-2013
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
--           --SN Added on 07.05.2013 for Performance Changes MANTIS ID- 11048
--            WHEN exp_reject_record
--            THEN
--            RAISE exp_reject_record;
--           --EN Added on 07.05.2013 for Performance Changes MANTIS ID- 11048
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
--   END IF;  */
--/*
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
--   END LOOP;  */
--   --En generate temp pan for check digit
--   --Sn generate for check digit
   
   --SN: Modified/Added for VMS-6652
   BEGIN
     SELECT UPPER(TRIM(NVL(cip_param_value,'Y')))
  	   INTO v_toggle_value
	   FROM cms_inst_param
      WHERE cip_inst_code = 1
	    AND cip_param_key = 'RETL_GPR_MULTIBIN_TOGGLE';
   EXCEPTION
     WHEN NO_DATA_FOUND THEN
       v_toggle_value := 'Y';
   END;   
   
   BEGIN
    IF v_toggle_value = 'N' THEN
    vmscard.get_pan_srno (p_instcode,
                          v_prod_code,
                          v_card_type,
                          v_prod_prefix,
                          p_prod_suffix,
                          p_card_start,  
                          p_card_end,
                          v_cpc_serl_flag,
                          v_prefix,
                          v_serial_no,
                          v_errmsg);
    ELSE                      
    vmscard.get_pan_srno (p_instcode,
                          v_prod_code,
                          v_card_type,
                          prm_starter_card_flg,
                          v_cpc_serl_flag,
                          v_bin,
                          v_prefix,
                          v_serial_no,
                          v_errmsg);
    END IF;
    --EN: Modified/Added for VMS-6652
--
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
      v_mask_pan := fn_getmaskpan (v_pan);--substr(v_pan,1,6)||'XXXXXX'||substr(v_pan,13); -- fn_mask (v_pan, 'X', 7, 6);
   EXCEPTION
      WHEN OTHERS
      THEN
         v_errmsg :=
               'Error while converting into mask pan '
            || SUBSTR (SQLERRM, 1, 200);
         RAISE exp_reject_record;
   END;
   
   --SN: Modified for Performance changes
   BEGIN
      SELECT cad_acct_id, cad_acct_posn
        INTO v_acct_id, v_acct_posn
        FROM cms_appl_det
      WHERE cad_inst_code = p_instcode
        AND cad_appl_code = p_applcode;
   EXCEPTION
      WHEN NO_DATA_FOUND THEN
         v_errmsg :='Application dtls not found for appl code ' || p_applcode;
         RAISE exp_reject_record;
      WHEN OTHERS THEN
         v_errmsg :='Error while selecting application dtls '|| SUBSTR (SQLERRM, 1, 200);
         RAISE exp_reject_record;
   END;
   
   -- Sn find primary acct no for the pan
   BEGIN
      SELECT cam_acct_no--cam_acct_id, cam_acct_no
        INTO v_acct_num--v_acct_id, v_acct_num
        FROM cms_acct_mast
       WHERE cam_inst_code = p_instcode
         AND cam_acct_id = v_acct_id;
                /*(SELECT cad_acct_id
                   FROM cms_appl_det
                  WHERE cad_inst_code = p_instcode
                    AND cad_appl_code = p_applcode
                    AND cad_acct_posn = 1);*/
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
   --EN: Modified for Performance changes


/* START Added by DMG  170420123 */
      v_adonlink := v_hash_pan;
      v_mbrlink := '000';
/* END Added by DMG  170420123 */
 
   IF v_request_id IS NOT NULL
   THEN
      v_issueflag := 'N';
   ELSE
      v_issueflag := 'Y';
   END IF;

    --Sn Added for Card_Issu Pahse-3 changes
    BEGIN
       SELECT COUNT (*)
         INTO v_appl_count
         FROM cms_appl_pan
        WHERE cap_pan_code =v_hash_pan ;
    EXCEPTION
      WHEN OTHERS THEN
        v_appl_count:=0;
    END;
  begin
      select cpc_user_identify_type
      into v_user_identify_type
      from cms_prod_cattype
      where cpc_inst_code=1
      and cpc_prod_code=v_prod_code
      and cpc_card_type=v_card_type;
  exception
      when others then
          v_errmsg:='Error while selecing prod cattype'||substr(sqlerrm,1,200);
          raise exp_reject_record;
  end;
   
  IF v_appl_count=0 THEN 
   --En Added for Card_Issu Pahse-3 changes
    
   --Sn create a record in appl_pan
   BEGIN
      INSERT INTO CMS_APPL_PAN_TEMP
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
                   --SN Commented for Performance changes
                   /*cap_atm_offline_limit, cap_atm_online_limit,
                   cap_pos_offline_limit, cap_pos_online_limit,
                   cap_offline_aggr_limit, cap_online_aggr_limit,*/
                   --EN Commented for Performance changes
                   --cap_emp_id, --Commented for Performance changes
                   cap_firsttime_topup, cap_panmast_param1,
                   cap_panmast_param2, cap_panmast_param3,
                   cap_panmast_param4, cap_panmast_param5,
                   cap_panmast_param6, cap_panmast_param7,
                   cap_panmast_param8, cap_panmast_param9,
                   cap_panmast_param10, cap_pan_code_encr, cap_proxy_number,
                   --cap_mmpos_online_limit, cap_mmpos_offline_limit, --Commented for Performance changes
                   cap_startercard_flag, cap_inactive_feecalc_date,
                   cap_mask_pan,
                   cap_file_name, cap_ins_date,cap_lupd_date,cap_user_identify_type  --Added for Card_issu Phase-3 changes
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
                   --SN Commented for Performance changes
                   /*v_offline_atm_limit, v_online_atm_limit,
                   v_offline_pos_limit, v_online_pos_limit,
                   v_offline_aggr_limit, v_online_aggr_limit,*/
                   --EN Commented for Performance changes
                   --v_emp_id, --Commented for Performance changes
                   'N', v_appl_data (1),
                   v_appl_data (2), v_appl_data (3),
                   v_appl_data (4), v_appl_data (5),
                   v_appl_data (6), v_appl_data (7),
                   v_appl_data (8), v_appl_data (9),
                   v_appl_data (10), v_encr_pan, v_proxy_number,
                   --v_online_mmpos_limit, v_offline_mmpos_limit, --Commented for Performance changes
                   v_starter_card, NULL,
                   v_mask_pan,
                   v_cam_file_name, sysdate,sysdate,v_user_identify_type  --Added for Card_issu Phase-3 changes
                  );
   EXCEPTION
      WHEN DUP_VAL_ON_INDEX
      THEN
         v_errmsg :=
               'Pan '
            || v_mask_pan-- fn_mask (v_pan, 'X', 7, 6)
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
      INSERT INTO CMS_CARDISSUANCE_STATUS
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

  ELSE
       v_errmsg := 'Pan ' || v_mask_pan || ' is already present in the Pan_master';
         RAISE exp_reject_record;
  END IF;
 
   BEGIN
      UPDATE CMS_APPL_MAST
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
    --P_ERRMSG          := 'OK';
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

END;

/
show error