CREATE OR REPLACE PROCEDURE vmscms.sp_gen_allpans (
   prm_instcode   IN       NUMBER,
   prm_lupduser   IN       NUMBER,
   prm_totcnt     OUT      NUMBER,
   prm_succnt     OUT      NUMBER,
   prm_errcnt     OUT      NUMBER,
   prm_errmsg     OUT      VARCHAR2
)
AS
   CURSOR c1
   IS
      SELECT cam_inst_code, cam_appl_code, cam_asso_code, cam_inst_type,
             cam_prod_code, cam_appl_bran, cam_cust_code, cam_card_type,
             cam_cust_catg, cam_disp_name, cam_active_date, cam_expry_date,
             cam_addon_stat, cam_tot_acct, cam_chnl_code, cam_limit_amt,
             cam_use_limit, cam_bill_addr, cam_request_id, cam_appl_stat,
             cam_initial_topup_amount, cam_appl_param1, cam_appl_param2,
             cam_appl_param3, cam_appl_param4, cam_appl_param5,
             cam_appl_param6, cam_appl_param7, cam_appl_param8,
             cam_appl_param9, cam_appl_param10, cam_starter_card,
             cam_file_name, cam_addon_link
        FROM cms_appl_mast
       WHERE cam_appl_stat = 'A' AND cam_inst_code = prm_instcode;

   v_panout     VARCHAR2 (20);
   v_cnt        NUMBER (10)    := 0;
   v_appl_msg   VARCHAR2 (500);
   v_totcnt     NUMBER (10)    DEFAULT 0;
   v_succnt     NUMBER (10)    DEFAULT 0;
   v_errcnt     NUMBER (10)    DEFAULT 0;
BEGIN
   prm_errmsg := 'OK';

   FOR x IN c1
   LOOP
      v_totcnt := v_totcnt + 1;
      sp_gen_pan_stock_issu (x.cam_asso_code,
                             x.cam_inst_type,
                             x.cam_prod_code,
                             x.cam_appl_bran,
                             x.cam_cust_code,
                             x.cam_card_type,
                             x.cam_cust_catg,
                             x.cam_disp_name,
                             x.cam_active_date,
                             x.cam_expry_date,
                             x.cam_addon_stat,
                             x.cam_tot_acct,
                             x.cam_chnl_code,
                             x.cam_limit_amt,
                             x.cam_use_limit,
                             x.cam_bill_addr,
                             x.cam_request_id,
                             x.cam_appl_stat,
                             x.cam_initial_topup_amount,
                             x.cam_starter_card,
                             x.cam_file_name,
                             x.cam_addon_link,
                             type_appl_rec_array (x.cam_appl_param1,
                                                  x.cam_appl_param2,
                                                  x.cam_appl_param3,
                                                  x.cam_appl_param4,
                                                  x.cam_appl_param5,
                                                  x.cam_appl_param6,
                                                  x.cam_appl_param7,
                                                  x.cam_appl_param8,
                                                  x.cam_appl_param9,
                                                  x.cam_appl_param10
                                                 ),
                             prm_instcode,
                             x.cam_appl_code,
                             prm_lupduser,
                             v_panout,
                             v_appl_msg,
                             prm_errmsg
                            );

      IF prm_errmsg != 'OK'
      THEN
         ROLLBACK;

         UPDATE cms_appl_mast
            SET cam_appl_stat = 'E',
                cam_process_msg = prm_errmsg,
                cam_lupd_user = prm_lupduser
          WHERE cam_inst_code = prm_instcode
            AND cam_appl_code = x.cam_appl_code;

         COMMIT;
      ELSE
         COMMIT;
      END IF;

      IF prm_errmsg = 'OK' AND v_appl_msg = 'OK'
      THEN
         v_succnt := v_succnt + 1;
      END IF;

      v_cnt := v_cnt + 1;
   END LOOP;

   IF prm_errmsg = 'OK'
   THEN
      v_errcnt := v_totcnt - v_succnt;
   ELSE
      v_succnt := 0;
      v_errcnt := 0;
   END IF;

   prm_totcnt := v_totcnt;
   prm_succnt := v_succnt;
   prm_errcnt := v_errcnt;
EXCEPTION
   WHEN OTHERS
   THEN
      prm_errmsg := 'Error from main ' || SUBSTR (SQLERRM, 1, 200);
END;
/

SHOW ERROR