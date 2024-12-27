CREATE OR REPLACE PROCEDURE VMSCMS.sp_panacct_ctrl_updt (
   p_inst_code              NUMBER,
   p_branch_id              VARCHAR2,
   p_prod_code              VARCHAR2,
   p_card_type              VARCHAR2,
   p_acct_ctrl_numb         NUMBER,
   p_pan_ctrl_numb          NUMBER,
   p_err_msg          OUT   VARCHAR2
)
IS
   v_num             NUMBER (10);
   v_inst_code       NUMBER (5)                            := 1;
   v_lupd_user       NUMBER (5);
   v_tmp_pan         VARCHAR2 (20);
   v_errmsg          VARCHAR2 (500);
   v_tmp_acct        VARCHAR2 (16);
   v_cac_length      NUMBER;
   v_ctrlnumb        NUMBER (30);
   v_ctrl_numb       NUMBER (30);
   v_max_serl        cms_pan_ctrl.cpc_max_serial_no%TYPE;
   excp_reject_rec   EXCEPTION;
   v_savepnt         NUMBER (10)                           := 0;
BEGIN
   v_errmsg := 'OK';

   BEGIN
      SELECT cum_user_pin
        INTO v_lupd_user
        FROM cms_user_mast
       WHERE cum_user_code = 'MIGR_USER' AND cum_inst_code = v_inst_code;
   EXCEPTION
      WHEN OTHERS
      THEN
         v_lupd_user := 1;
   END;

   BEGIN
      v_errmsg := 'OK';
      v_savepnt := v_savepnt + 1;
      SAVEPOINT v_savepnt;
      sp_acct_tmpno (v_inst_code,
                     p_branch_id,
                     p_prod_code,
                     p_card_type,
                     v_tmp_acct,
                     v_cac_length,
                     v_errmsg
                    );

      IF v_errmsg <> 'OK'
      THEN
         v_errmsg := 'Error while selecting acct prefix-' || v_errmsg;
         RAISE excp_reject_rec;
      END IF;

      BEGIN
         SELECT     NVL (cac_ctrl_numb, 1)
               INTO v_ctrlnumb
               FROM cms_acct_ctrl
              WHERE cac_bran_code = v_tmp_acct AND cac_inst_code = p_inst_code
         FOR UPDATE WAIT 1;

         IF v_ctrlnumb + p_acct_ctrl_numb < LPAD ('9', v_cac_length, 9)
         THEN
            UPDATE cms_acct_ctrl
               SET cac_ctrl_numb = v_ctrlnumb + p_acct_ctrl_numb
             WHERE cac_bran_code = v_tmp_acct AND cac_inst_code = p_inst_code;

            IF SQL%ROWCOUNT = 0
            THEN
               v_errmsg := 'acct serial no not updated for acct prefix-'||v_tmp_acct; --Error message modified by Pankaj S. on 25-Sep-2013
               RAISE excp_reject_rec;
            END IF;
         ELSE
            v_errmsg := 'Maximum acct serial number reached';
            RAISE excp_reject_rec;
         END IF;
      --COMMIT;
      EXCEPTION WHEN NO_DATA_FOUND
      THEN
       
       BEGIN
       
        Insert into CMS_ACCT_CTRL
           (CAC_INST_CODE, CAC_BRAN_CODE, CAC_CTRL_NUMB, CAC_MAX_SERIAL_NO, CAC_LUPD_DATE, 
            CAC_LUPD_USER, CAC_INS_DATE, CAC_INS_USER)
         Values
           (p_inst_code, v_tmp_acct, nvl(p_acct_ctrl_numb,0) + 1, LPAD ('9', v_cac_length, 9), SYSDATE, 
            v_lupd_user, SYSDATE, v_lupd_user);
      
      
        EXCEPTION -- Added exception block on 28-Mar-2013 to avoid duplicate account number
           WHEN OTHERS
           THEN
              v_errmsg :=
                     'Error While Inserting into CMS_ACCT_CTRL  -- ' || SQLERRM;  --Error message modified by Pankaj S. on 25-Sep-2013
              
        END;      
      
      WHEN excp_reject_rec
         THEN
            RAISE;
         WHEN OTHERS
         THEN
            v_errmsg :=
                  'Error while adujust acct cntrl number- -- '
               || SUBSTR (SQLERRM, 1, 200);
            RAISE excp_reject_rec;
      END;

      migr_find_binprefix (v_inst_code,
                           p_prod_code,
                           p_card_type,
                           p_branch_id,
                           v_tmp_pan,
                           v_max_serl,
                           v_errmsg
                          );

      IF v_errmsg <> 'OK'
      THEN
         v_errmsg := 'Error while selecting bin prefix-' || v_errmsg;  --Error message modified by Pankaj S. on 25-Sep-2013
         RAISE excp_reject_rec;
      END IF;

      BEGIN
         SELECT     NVL (cpc_ctrl_numb, 1)
               INTO v_ctrl_numb
               FROM cms_pan_ctrl
              WHERE cpc_inst_code = v_inst_code AND cpc_pan_prefix = v_tmp_pan
         FOR UPDATE WAIT 1;

         IF v_ctrl_numb + p_pan_ctrl_numb < LPAD ('9', v_max_serl, 9)
         THEN
            UPDATE cms_pan_ctrl
               SET cpc_ctrl_numb = v_ctrl_numb + p_pan_ctrl_numb
             WHERE cpc_inst_code = v_inst_code AND cpc_pan_prefix = v_tmp_pan;

            IF SQL%ROWCOUNT = 0
            THEN
               v_errmsg :=
                     'PAN Control number not updated for product code '
                  || p_prod_code;
               RAISE excp_reject_rec;
            END IF;
         ELSE
            v_errmsg :=
                  'Maximum PAN Serial Number Reached for product code '
               || p_prod_code;
            RAISE excp_reject_rec;
         END IF;
      EXCEPTION WHEN NO_DATA_FOUND
      THEN
      
       BEGIN
       
       
        Insert into CMS_PAN_CTRL
           (CPC_INST_CODE, CPC_PAN_PREFIX, CPC_CTRL_NUMB, CPC_MAX_SERIAL_NO, CPC_LUPD_DATE, 
            CPC_LUPD_USER, CPC_INS_DATE, CPC_INS_USER)
         Values
           (p_inst_code, v_tmp_pan, nvl(p_pan_ctrl_numb,0) + 1,  LPAD ('9', v_max_serl, 9), SYSDATE, 
            v_lupd_user, SYSDATE, v_lupd_user);
      
       EXCEPTION -- Added exception block on 28-Mar-2013 to avoid duplicate account number
           WHEN OTHERS
           THEN
              v_errmsg :=
                     'Error While Inserting into CMS_PAN_CTRL  -- ' || SQLERRM;  --Error message modified by Pankaj S. on 25-Sep-2013
              
       END;        
      
      
         WHEN excp_reject_rec
         THEN
            RAISE;
         WHEN OTHERS
         THEN
            v_errmsg :=
                  'Erorr while updating pan control number for product code '
               || p_prod_code
               || ' as '
               || SUBSTR (SQLERRM, 1, 200);
            RAISE excp_reject_rec;
      END;

      IF v_errmsg = 'OK'
      THEN
         INSERT INTO migr_updt_ctrl_detl
                     (muc_inst_code, muc_prod_code, muc_card_type,
                      muc_brch_numb, muc_ctrl_numb, muc_ctrl_type,
                      muc_proc_flag, muc_proc_mesg, muc_ins_date,
                      muc_ins_user
                     )
              VALUES (p_inst_code, p_prod_code, p_card_type,
                      p_branch_id, v_ctrlnumb, 'ACCT',
                      'S', v_errmsg, SYSDATE,
                      v_lupd_user
                     );

         INSERT INTO migr_updt_ctrl_detl
                     (muc_inst_code, muc_prod_code, muc_card_type,
                      muc_brch_numb, muc_ctrl_numb, muc_ctrl_type,
                      muc_proc_flag, muc_proc_mesg, muc_ins_date, muc_ins_user
                     )
              VALUES (p_inst_code, p_prod_code, p_card_type,
                      p_branch_id, v_ctrl_numb, 'PAN',
                      'S', v_errmsg, SYSDATE, v_lupd_user
                     );
      END IF;
   EXCEPTION
      WHEN excp_reject_rec
      THEN
         ROLLBACK TO v_savepnt;
         p_err_msg := v_errmsg;

         INSERT INTO migr_updt_ctrl_detl
                     (muc_inst_code, muc_prod_code, muc_card_type,
                      muc_brch_numb, muc_ctrl_numb, muc_ctrl_type,
                      muc_proc_flag, muc_proc_mesg, muc_ins_date,
                      muc_ins_user
                     )
              VALUES (p_inst_code, p_prod_code, p_card_type,
                      p_branch_id, v_ctrlnumb, 'ACCT',
                      'E', v_errmsg, SYSDATE,
                      v_lupd_user
                     );

         INSERT INTO migr_updt_ctrl_detl
                     (muc_inst_code, muc_prod_code, muc_card_type,
                      muc_brch_numb, muc_ctrl_numb, muc_ctrl_type,
                      muc_proc_flag, muc_proc_mesg, muc_ins_date, muc_ins_user
                     )
              VALUES (v_inst_code, p_prod_code, p_card_type,
                      p_branch_id, v_ctrl_numb, 'PAN',
                      'E', v_errmsg, SYSDATE, v_lupd_user
                     );
      WHEN OTHERS
      THEN
         ROLLBACK TO v_savepnt;
         v_errmsg :=
               'Erorr while updating control number for product code '
            || p_prod_code
            || ' as '
            || SUBSTR (SQLERRM, 1, 200);
         p_err_msg := v_errmsg;

         INSERT INTO migr_updt_ctrl_detl
                     (muc_inst_code, muc_prod_code, muc_card_type,
                      muc_brch_numb, muc_ctrl_numb, muc_ctrl_type,
                      muc_proc_flag, muc_proc_mesg, muc_ins_date, muc_ins_user
                     )
              VALUES (p_inst_code, p_prod_code, p_card_type,
                      p_branch_id, v_ctrlnumb, 'ACCT',
                      'E', v_errmsg, SYSDATE, v_lupd_user
                     );

         INSERT INTO migr_updt_ctrl_detl
                     (muc_inst_code, muc_prod_code, muc_card_type,
                      muc_brch_numb, muc_ctrl_numb, muc_ctrl_type,
                      muc_proc_flag, muc_proc_mesg, muc_ins_date, muc_ins_user
                     )
              VALUES (v_inst_code, p_prod_code, p_card_type,
                      p_branch_id, v_ctrl_numb, 'PAN',
                      'E', v_errmsg, SYSDATE, v_lupd_user
                     );
   END;
   
   COMMIT ;
   
EXCEPTION
   WHEN OTHERS
   THEN
      p_err_msg :=
         'Error while ACCT/PAN control update as '
         || SUBSTR (SQLERRM, 1, 200);
END;
/

SHOW ERRORS;