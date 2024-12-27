create or replace
PROCEDURE               VMSCMS.SP_GEN_ALLPANS_STARTER (
   prm_instcode   IN       NUMBER,
   prm_fil_cnt      IN       rectypetab,
   prm_lupduser   IN       NUMBER,
   prm_errmsg     OUT      VARCHAR2,
   prm_resp_dtls  OUT   VARCHAR2
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
       * Modified On      :  09/05/2013
       * Modified For     :  MANTIS ID- 11048
       * Reviewer         :
       * Reviewed Date    :
       * Build Number     :  RI0024.1_B0017

       * Modified by      : MageshKumar S.
       * Modified Date    : 25-July-14
       * Modified For     : FWR-48
       * Modified reason  : GL Mapping removal changes
       * Reviewer         : Spankaj
       * Build Number     : RI0027.3.1_B0001

       * Modified by      : Pankaj S.
       * Modified Date    : 14-Sep-16
       * Modified For     : FSS-4779
       * Modified reason  : Card Generation Performance changes
       * Reviewer         : Saravanakumar
       * Build Number     : 4.2.3

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
   file_name               VARCHAR2 (30);

   CURSOR c1 (file_name VARCHAR2)
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
       WHERE cam_appl_stat = 'A'
         AND cam_inst_code = prm_instcode
         AND cam_file_name = file_name ;


   v_panout                VARCHAR2 (20);
   --v_cnt                   NUMBER (10)                                  := 0;
   v_appl_msg              VARCHAR2 (500);
   --SN: Modified for Performance changes
   --v_totcnt                NUMBER (10)                               DEFAULT 0;
   v_succnt                NUMBER (10) ;                              --DEFAULT 0;
   v_errcnt                NUMBER (10);                               --DEFAULT 0;
   --v_tot_err               NUMBER (10);
   --v_gl_check              NUMBER (10);
   --EN: Modified for Performance changes
   --v_table_pan_construct   PKG_STOCK.table_pan_construct;
   v_loop_cnt              NUMBER (12);
   v_loop_max_cnt          NUMBER (12);
   v_hsm_mode              cms_inst_param.cip_param_value%TYPE;
   v_pingen_flag           VARCHAR2 (1);
   v_emboss_flag           VARCHAR2 (1);
   v_bin                   cms_bin_mast.cbm_inst_bin%TYPE;
   v_profile_code          cms_prod_cattype.cpc_profile_code%TYPE;
   v_cpm_catg_code         cms_prod_mast.cpm_catg_code%TYPE;
   v_programid             VARCHAR2 (4);
   v_proxylength           cms_prod_mast.cpm_proxy_length%TYPE;
   v_cpc_serl_flag         cms_prod_cattype.cpc_serl_flag%TYPE;
   v_startergpr_type       cms_prod_cattype.cpc_startergpr_issue%TYPE;
   v_starter_card_flg      cms_appl_pan.cap_startercard_flag%TYPE;
   v_prod_prefix           cms_prod_cattype.cpc_prod_prefix%TYPE;
   v_tmp_pan               cms_appl_pan.cap_pan_code%TYPE;
   --v_serial_index          NUMBER (10);
   v_card_stat             cms_appl_pan.cap_card_stat%TYPE;
   v_expryparam            cms_bin_param.cbp_param_value%TYPE;
   v_expiry_date           DATE;
   v_mbrnumb               cms_inst_param.cip_param_value%TYPE;
   exp_reject_file         EXCEPTION;
   v_errmsg                VARCHAR2 (4000);
   v_expry_param           cms_bin_param.cbp_param_value%TYPE;
   v_validity_period       cms_bin_param.cbp_param_value%TYPE;
   v_cnt_exit              NUMBER (10)                                  := 0;
   v_shuffleno_cnt         NUMBER (10);
   v_cpm_prod_desc         cms_prod_mast.cpm_prod_desc%TYPE;
   v_pan_inventory_flag    cms_prod_cattype.cpc_pan_inventory_flag%TYPE;  --Added for 17.07 PAN Inventory Changes
   v_prod_suffix           cms_prod_cattype.cpc_prod_suffix%TYPE;
   v_card_start            cms_prod_cattype.cpc_start_card_no%TYPE;
   v_card_end              cms_prod_cattype.cpc_end_card_no%TYPE;


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


   --exp_reject_record       EXCEPTION;

--   CURSOR c (p_profile_code IN VARCHAR2)
--   IS
--      SELECT cpc_profile_code, cpc_field_name, cpc_start_from, cpc_length,
--             cpc_start
--        FROM cms_pan_construct
--       WHERE cpc_profile_code = p_profile_code
--             AND cpc_inst_code = prm_instcode
--   ;

BEGIN

   FOR i IN 1 .. prm_fil_cnt.COUNT
   LOOP
      --v_file_exit := 0; --Commented for performance changes
      IF v_cnt_exit=0 THEN
           prm_resp_dtls:=prm_fil_cnt (i).file_name;
      ELSE
            prm_resp_dtls:=prm_resp_dtls||'|'||prm_fil_cnt (i).file_name;
      END IF;
      v_cnt_exit := 1;
      v_succnt:=0;
      V_Errcnt:=0;

      FOR x IN c1 (prm_fil_cnt (i).file_name)
      LOOP
          v_errmsg := 'OK';
         --SN Commented for performance changes
         --EXIT WHEN v_cnt_exit > 1;
         --DBMS_OUTPUT.put_line (prm_fil_cnt (i).file_name);
         --EN Commented for performance changes


        IF v_cnt_exit =1 THEN  --Added for performance changes
         BEGIN
            --Sn find profile code attached to cardtype
            BEGIN
               SELECT cpc_profile_code, cpm_catg_code, cpc_prod_prefix,
                      cpc_program_id, cpm_proxy_length, cpc_serl_flag,
                      cpc_startergpr_issue, cpc_starter_card,cpm_prod_desc,
                      NVL(cpc_pan_inventory_flag, 'N'), --Added for 17.07 PAN Inventory Changes
                      cpc_prod_suffix, cpc_start_card_no, cpc_end_card_no
                 INTO v_profile_code, v_cpm_catg_code, v_prod_prefix,
                      v_programid, v_proxylength, v_cpc_serl_flag,
                      v_startergpr_type, v_starter_card_flg,v_cpm_prod_desc,
                      v_pan_inventory_flag,  --Added for 17.07 PAN Inventory Changes
                      v_prod_suffix, v_card_start, v_card_end
                 FROM cms_prod_cattype, cms_prod_mast
                WHERE cpc_inst_code = prm_instcode
                  AND cpc_inst_code = cpm_inst_code
                  AND cpc_prod_code = x.cam_prod_code
                  AND cpc_card_type = x.cam_card_type
                  AND cpm_prod_code = cpc_prod_code;
            EXCEPTION
               WHEN NO_DATA_FOUND
               THEN
                  v_errmsg :=
                        'Profile code not defined for product code '
                     || x.cam_prod_code
                     || 'card type '
                     || x.cam_card_type;
                  RAISE exp_reject_file;
               WHEN OTHERS
               THEN
                  v_errmsg :=
                        'Error while selecting applcode from applmast'
                     || SUBSTR (SQLERRM, 1, 300);
                  RAISE exp_reject_file;
            End;
   
--          IF v_pan_inventory_flag='N' THEN  --Added for 17.07 PAN Inventory Changes
--            IF v_cpc_serl_flag = 1
--            THEN
--               /* Serial Numbers present or not */
--               SELECT COUNT (*)
--                 INTO v_shuffleno_cnt
--                 FROM cms_shfl_serl
--                WHERE css_inst_code = prm_instcode
--                  AND css_prod_code = x.cam_prod_code
--                  AND css_prod_catg = x.cam_card_type
--                  AND css_serl_flag = 0;
--
--               IF v_shuffleno_cnt = 0
--               THEN
--                  BEGIN
--                     INSERT INTO cms_serl_error
--                                 (cse_inst_code, cse_prod_code,
--                                  cse_prod_catg, cse_ordr_rfrno,
--                                  cse_err_mseg
--                                 )
--                          VALUES (prm_instcode, x.cam_prod_code,
--                                  x.cam_card_type, x.cam_file_name,
--                                  'Need To Generate Shuffle Numbers '
--                                 );
--                  EXCEPTION
--                     WHEN OTHERS
--                     THEN
--                        v_errmsg :=
--                              'Error while Inserting Record Into  CMS_SERL_ERROR When Shuffle Count is 0  '
--                           || SUBSTR (SQLERRM, 1, 200);
--                        RAISE exp_reject_file;
--                  END;
--               ELSIF v_shuffleno_cnt < prm_fil_cnt (i).file_count
--               THEN
--                  -- v_order_process_cnt := v_shuffleno_cnt;
--                  v_errmsg :=
--                        'Available Shuffle Number Count is : '
--                     || v_shuffleno_cnt
--                     || '. Need To Generate Shuffle Numbers ';
--                  --v_donot_mark_error := 1;
--                  RAISE exp_reject_file;
--               END IF;
--            END IF;
--          END IF;  --Added for 17.07 PAN Inventory Changes
            /* Serial Numbers present or not */

            --Sn find hsm mode
            BEGIN
               SELECT cip_param_value
                 INTO v_hsm_mode
                 FROM cms_inst_param
                WHERE cip_param_key = 'HSM_MODE'
                  AND cip_inst_code = prm_instcode;

               IF v_hsm_mode = 'Y'
               THEN
                  v_pingen_flag := 'Y';                  -- i.e. generate pin
                  v_emboss_flag := 'Y';        -- i.e. generate embossa file.
               ELSE
                  v_pingen_flag := 'N';            -- i.e. don't generate pin
                  v_emboss_flag := 'N';  -- i.e. don't generate embossa file.
               END IF;
            EXCEPTION
               WHEN NO_DATA_FOUND
               THEN
                  v_hsm_mode := 'N';
                  v_pingen_flag := 'N';            -- i.e. don't generate pin
                  v_emboss_flag := 'N';  -- i.e. don't generate embossa file.
            END;

            --SN Find the Institution BIN
            BEGIN
               SELECT cpb_inst_bin
                 INTO v_bin
                 FROM cms_prod_bin
                WHERE cpb_inst_code = prm_instcode
                  AND cpb_prod_code = x.cam_prod_code
                  AND cpb_active_bin = 'Y';
            EXCEPTION
               WHEN NO_DATA_FOUND
               THEN
                  v_errmsg :=
                        'Institution Bin Not Found For Combination Of Institution '
                     || prm_instcode
                     || ' and product '
                     || x.cam_prod_code;
                  RAISE exp_reject_file;
               WHEN OTHERS
               THEN
                  v_errmsg :=
                        'Error while selecting Institution Bim from PROD BIN MAST '
                     || SUBSTR (SQLERRM, 1, 300);
                  RAISE exp_reject_file;
            END;

            IF v_prod_prefix IS NULL
            THEN
               BEGIN
                  SELECT cip_param_value
                    INTO v_prod_prefix
                    FROM cms_inst_param
                   WHERE cip_inst_code = prm_instcode
                     AND cip_param_key = 'PANPRODCATPREFIX';
               EXCEPTION
                  WHEN OTHERS
                  THEN
                     v_errmsg :=
                           'Error while selecting PAN Product Category Prefix from CMS_INST_PARAM '
                        || SUBSTR (SQLERRM, 1, 300);
                     RAISE exp_reject_file;
               END;
            END IF;

            --En find profile code attached to cardtype
--          IF v_pan_inventory_flag='N' THEN  --Added for 17.07 PAN Inventory Changes
--            --Sn find pan construct details based on profile code
--            BEGIN
--               v_loop_cnt := 0;
--
--               FOR i IN c (v_profile_code)
--               LOOP
--                  v_loop_cnt := v_loop_cnt + 1;
--
--                  SELECT i.cpc_profile_code,
--                         i.cpc_field_name,
--                         i.cpc_start_from,
--                         i.cpc_length,
--                         i.cpc_start
--                    INTO v_table_pan_construct (v_loop_cnt).cpc_profile_code,
--                         v_table_pan_construct (v_loop_cnt).cpc_field_name,
--                         v_table_pan_construct (v_loop_cnt).cpc_start_from,
--                         v_table_pan_construct (v_loop_cnt).cpc_length,
--                         v_table_pan_construct (v_loop_cnt).cpc_start
--                    FROM DUAL;
--               END LOOP;
--            EXCEPTION
--               WHEN OTHERS
--               THEN
--                  v_errmsg :=
--                        'Error while selecting profile detail from profile mast '
--                     || SUBSTR (SQLERRM, 1, 300);
--                  RAISE exp_reject_file;
--            END;
--
--            BEGIN
--               v_loop_max_cnt := v_table_pan_construct.COUNT;
--               v_tmp_pan := NULL;
--
--               FOR i IN 1 .. v_loop_max_cnt
--               LOOP
--                  IF v_table_pan_construct (i).cpc_field_name = 'Card Type'
--                  THEN
--                     v_table_pan_construct (i).cpc_field_value :=
--                        LPAD (SUBSTR (TRIM (x.cam_card_type),
--                                      v_table_pan_construct (i).cpc_start,
--                                      v_table_pan_construct (i).cpc_length
--                                     ),
--                              v_table_pan_construct (i).cpc_length,
--                              '0'
--                             );
--                  ELSIF v_table_pan_construct (i).cpc_field_name = 'Branch'
--                  THEN
--                     v_table_pan_construct (i).cpc_field_value :=
--                        LPAD (SUBSTR (TRIM (x.cam_appl_bran),
--                                      v_table_pan_construct (i).cpc_start,
--                                      v_table_pan_construct (i).cpc_length
--                                     ),
--                              v_table_pan_construct (i).cpc_length,
--                              '0'
--                             );
--                  ELSIF v_table_pan_construct (i).cpc_field_name =
--                                                                'BIN / PREFIX'
--                  THEN
--                     v_table_pan_construct (i).cpc_field_value :=
--                        LPAD (SUBSTR (TRIM (v_bin),
--                                      v_table_pan_construct (i).cpc_start,
--                                      v_table_pan_construct (i).cpc_length
--                                     ),
--                              v_table_pan_construct (i).cpc_length,
--                              '0'
--                             );
--                  ELSIF v_table_pan_construct (i).cpc_field_name =
--                                                 'PAN Product Category Prefix'
--                  THEN
--                     v_table_pan_construct (i).cpc_field_value :=
--                        LPAD (SUBSTR (TRIM (v_prod_prefix),
--                                      v_table_pan_construct (i).cpc_start,
--                                      v_table_pan_construct (i).cpc_length
--                                     ),
--                              v_table_pan_construct (i).cpc_length,
--                              '0'
--                             );
--                  ELSE
--                     IF v_table_pan_construct (i).cpc_field_name <>
--                                                              'Serial Number'
--                     THEN
--                        v_errmsg :=
--                              'Pan construct '
--                           || v_table_pan_construct (i).cpc_field_name
--                           || ' not exist ';
--                        RAISE exp_reject_file;
--                     END IF;
--                  END IF;
--               END LOOP;
--            EXCEPTION
--               WHEN exp_reject_file
--               THEN
--                  RAISE;
--               WHEN OTHERS
--               THEN
--                  v_errmsg :=
--                     'Error from pangen process ' || SUBSTR (SQLERRM, 1, 300);
--                  RAISE exp_reject_file;
--            END;
--
--            --En built the pan gen logic based on the value
--
--            --Sn generate the serial no
--            FOR i IN 1 .. v_loop_max_cnt
--            LOOP
--               --<< i loop >>
--               FOR j IN 1 .. v_loop_max_cnt
--               LOOP
--                  --<< j  loop >>
--                  IF     v_table_pan_construct (j).cpc_start_from = i
--                     AND v_table_pan_construct (j).cpc_field_name <>
--                                                               'Serial Number'
--                  THEN
--                     v_tmp_pan :=
--                        v_tmp_pan
--                        || v_table_pan_construct (j).cpc_field_value;
--                     EXIT;
--                  END IF;
--               END LOOP;                                   --<< j  end loop >>
--            END LOOP;                                       --<< i end loop >>
--
--            --Sn get  index value of serial no from PL/SQL table
--            FOR i IN 1 .. v_table_pan_construct.COUNT
--            LOOP
--               IF v_table_pan_construct (i).cpc_field_name = 'Serial Number'
--               THEN
--                  v_serial_index := i;
--               END IF;
--            END LOOP;
--          END IF; --Added for 17.07 PAN Inventory Changes

v_card_stat := '0';  -- VMS-8219
--            BEGIN
--               SELECT cbp_param_value
--                 INTO v_card_stat
--                 FROM cms_bin_param
--                WHERE cbp_inst_code = prm_instcode
--                  AND cbp_profile_code = v_profile_code
--                  AND cbp_param_name = 'Status';
--
--               IF v_card_stat IS NULL
--               THEN
--                  v_errmsg :=
--                         'Status is null for profile code ' || v_profile_code;
--                  RAISE exp_reject_file;
--               END IF;
--            EXCEPTION
--               WHEN exp_reject_file
--               THEN
--                  RAISE;
--               WHEN NO_DATA_FOUND
--               THEN
--                  v_errmsg :=
--                        'Status is not defined for profile code '
--                     || v_profile_code;
--                  RAISE exp_reject_file;
--               WHEN OTHERS
--               THEN
--                  v_errmsg :=
--                        'Error while selecting card status '
--                     || SUBSTR (SQLERRM, 1, 200);
--                  RAISE exp_reject_file;
--            END;

            --Sn get member number from master
            BEGIN
               SELECT cip_param_value
                 INTO v_mbrnumb
                 FROM cms_inst_param
                WHERE cip_inst_code = prm_instcode
                  AND cip_param_key = 'MBR_NUMB';
            EXCEPTION
               WHEN NO_DATA_FOUND
               THEN
                  v_errmsg := 'memeber number not defined in master';
                  RAISE exp_reject_file;
               WHEN OTHERS
               THEN
                  v_errmsg :=
                        'Error while selecting memeber number '
                     || SUBSTR (SQLERRM, 1, 200);
                  RAISE exp_reject_file;
            END;

 
            v_cnt_exit := v_cnt_exit + 1;
            prm_resp_dtls := prm_resp_dtls||'~'||v_errmsg;
         EXCEPTION
            WHEN exp_reject_file
            THEN
               --SN Added for performance changes
               prm_resp_dtls := prm_resp_dtls||'~'||v_errmsg;
               EXIT;
               --EN Added for performance changes
            WHEN OTHERS
            THEN

               --SN Added for performance changes
               prm_resp_dtls := prm_resp_dtls||'~'||v_errmsg;
               EXIT;
               --EN Added for performance changes
         END;
        END IF; --Added for performance changes
      --END LOOP;

           sp_gen_pan_stock_issu_starter
                                    (x.cam_asso_code,
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
                                     v_hsm_mode,
                                     v_pingen_flag,
                                     v_emboss_flag,
                                     v_bin,
                                     v_profile_code,
                                     v_cpm_catg_code,
                                     v_programid,
                                     v_proxylength,
                                     v_cpc_serl_flag,
                                     v_startergpr_type,
                                     v_starter_card_flg,
                                     v_prod_prefix,
                                     v_tmp_pan,
                                     v_card_stat,
                                     v_expiry_date,
                                     v_mbrnumb,
                                     v_loop_max_cnt,
                                     v_cpm_prod_desc,
                                     v_panout,
                                     v_appl_msg,
                                     prm_errmsg,
                                     v_pan_inventory_flag,
                                     v_prod_suffix, 
                                     v_card_start, 
                                     v_card_end
                                    );

       --SN: Modified for Performance changes
           IF prm_errmsg != 'OK' THEN
               v_errcnt :=v_errcnt+1;
           /*    ROLLBACK;
               UPDATE cms_appl_mast
                  SET cam_appl_stat = 'E',
                      cam_process_msg = prm_errmsg,
                      cam_lupd_user = prm_lupduser
                WHERE cam_inst_code = prm_instcode
                  AND cam_appl_code = x.cam_appl_code;

               COMMIT;*/
            ELSE
              v_succnt:=v_succnt+1;
           END IF;
               COMMIT;
            --END IF;
      END LOOP;

       prm_resp_dtls:=prm_resp_dtls||'~'||v_succnt||'~'||v_errcnt;
      --EN: Modified for Performance changes
   END LOOP;
EXCEPTION
   WHEN OTHERS
   THEN
      prm_errmsg := 'Error from main ' || SUBSTR (SQLERRM, 1, 200);
END;

/
show error