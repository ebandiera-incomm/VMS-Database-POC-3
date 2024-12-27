CREATE OR REPLACE PROCEDURE VMSCMS.sp_grp_reissue (
   prm_instcode   IN       NUMBER,
   prm_ipaddr     IN       VARCHAR2,
   prm_lupduser   IN       NUMBER,
   prm_errmsg     OUT      VARCHAR2
)
/*************************************************
* VERSION             :  1.0
* Created Date       : 27/APR/2009
* Created By        : Kaustubh.Dave
* PURPOSE          : Group Reissue Card ,only if card status is 2 or 3
* Modified By:    :
* Modified Date  :
***********************************************/
AS
   v_mbrnumb              VARCHAR2 (3);
   v_cardstat             cms_appl_pan.cap_card_stat%TYPE;
   v_resoncode            cms_spprt_reasons.csr_spprt_rsncode%TYPE;
   v_card_curr            VARCHAR2 (3);
   v_authmsg              VARCHAR2 (300);
   v_rrn                  VARCHAR2 (12);
   v_stan                 VARCHAR2 (12);
   v_auth_msg             VARCHAR2 (300);
   v_process_msg          VARCHAR2 (300);
   v_newpan               VARCHAR2 (20);
   v_prod_catg            cms_appl_pan.cap_card_stat%TYPE;
   v_succ_flag            VARCHAR2 (1);
   v_txn_code             cms_func_mast.cfm_txn_code%TYPE;
   v_txn_mode             cms_func_mast.cfm_txn_mode%TYPE;
   v_del_channel          cms_func_mast.cfm_delivery_channel%TYPE;
   v_txn_type             cms_func_mast.cfm_txn_type%TYPE;
   v_reasondesc           cms_spprt_reasons.csr_reasondesc%TYPE;
   v_remark               VARCHAR2 (100)              DEFAULT 'GROUP REISSUE';
   v_old_prodcode         cms_appl_pan.cap_prod_code%TYPE;
   v_new_cardtype         cms_appl_pan.cap_card_type%TYPE;
   v_new_prod_catg        cms_prod_mast.cpm_catg_code%TYPE;
   exp_reissueexception   EXCEPTION;
   nullvalueexception     EXCEPTION;
   excp_reissue_dup       EXCEPTION;
   v_reissuesavepoint     NUMBER (10)                               DEFAULT 1;
   v_ressiue_dupflg    VARCHAR2(1);
   v_old_dispname       VARCHAR2(30);
   v_new_dispname       VARCHAR2(30);
    v_new_hash_pan    CMS_APPL_PAN.CAP_PAN_CODE%TYPE;  
 v_new_encr_pan    CMS_APPL_PAN.cap_pan_code_encr%TYPE;
 v_applcode                   CMS_APPL_PAN.cap_appl_code%TYPE;
   v_acctno                     CMS_APPL_PAN.cap_acct_no%TYPE;

v_decr_pan    CMS_APPL_PAN.cap_pan_code_encr%TYPE;
   CURSOR c1
   IS
      SELECT TRIM (cgh_card_no) cgh_card_no, cgh_file_name, cgh_remarks,
             cgh_process_flag, cgh_process_msg, cgh_mbr_numb,
             cgh_new_product, cgh_new_productcat, cgh_new_dispname,
             cgh_reason_code, cgh_card_no_encr,
             CGH_ROWID
        FROM cms_group_reissue_temp
       WHERE cgh_process_flag = 'N' AND cgh_dup_flag!='D' and cgh_inst_code = prm_instcode;
BEGIN                                                            -- Begin Main
   prm_errmsg := 'OK';

   FOR x IN c1
   LOOP
      v_newpan := '';
      v_process_msg := 'OK';
      prm_errmsg := 'OK';
      v_reissuesavepoint := v_reissuesavepoint + 1;
      SAVEPOINT v_reissuesavepoint;
 

--SN create decr pan
BEGIN
    v_decr_pan := Fn_Dmaps_Main(x.cgh_card_no_encr);
EXCEPTION
WHEN OTHERS THEN
prm_errmsg := 'Error while converting pan ' || SUBSTR(SQLERRM,1,200);
RAISE    exp_reissueexception;
END;
--EN create decr pan
  
      ----------------------------Sn Check for pan code and product,prod cat is not null-------------------
      BEGIN                                                        -- begin 1
         IF NVL (LENGTH (TRIM (x.cgh_card_no)), 0) = 0
         THEN
            prm_errmsg := 'PAN Code Is Null';
            RAISE exp_reissueexception;
         ELSIF NVL (LENGTH (TRIM (x.cgh_remarks)), 0) = 0
         THEN
            prm_errmsg := 'Remark Is Null';
            RAISE exp_reissueexception;
         ELSE
            prm_errmsg := 'OK';
         END IF;

         ----------------------------En Check for pan code and product,prod cat is not null-------------------
         -----------------------------Sn Check for debit or prepaid---------------------------
         BEGIN
            SELECT cap_prod_catg, cap_prod_code,cap_disp_name,CAP_APPL_CODE,CAP_ACCT_NO
              INTO v_prod_catg, v_old_prodcode,v_old_dispname,v_applcode, v_acctno
              FROM cms_appl_pan
             WHERE cap_inst_code = prm_instcode
               AND cap_pan_code = x.cgh_card_no
               AND cap_mbr_numb = x.cgh_mbr_numb;
         EXCEPTION
            WHEN NO_DATA_FOUND
            THEN
               prm_errmsg := 'No product category defined for the card';
               RAISE exp_reissueexception;
            WHEN OTHERS
            THEN
               prm_errmsg :=
                     'Error while getting records from table '
                  || SUBSTR (SQLERRM, 1, 200);
               RAISE exp_reissueexception;
         END;

         -----------------------------En Check for debit or prepaid---------------------------
         BEGIN
            SELECT cfm_txn_code, cfm_txn_mode, cfm_delivery_channel,
                   cfm_txn_type
              INTO v_txn_code, v_txn_mode, v_del_channel,
                   v_txn_type
              FROM cms_func_mast
             WHERE cfm_func_code = 'REISSUE' AND cfm_inst_code = prm_instcode;
         EXCEPTION
            WHEN OTHERS
            THEN
               prm_errmsg :=
                   'Function Master Not Defined ' || SUBSTR (SQLERRM, 1, 200);
               --RAISE exp_loop_reject_record;
               RETURN;
         END;
         
         IF (x.cgh_new_dispname) IS NULL THEN
            v_new_dispname:=v_old_dispname;
         ELSE
            v_new_dispname:=x.cgh_new_dispname;
         END IF;

         --Sn new product catg
         --En new product catg
         IF v_prod_catg = 'P'
         THEN
            NULL;
         /* ------------------------------ Sn get rrn----------------------------
          BEGIN
            SELECT LPAD (seq_auth_rrn.NEXTVAL, 12, '0') INTO v_rrn FROM DUAL;
          EXCEPTION
          WHEN OTHERS THEN
            prm_errmsg := 'Error while values from sequence ' || SUBSTR (SQLERRM, 1, 200);
            RAISE exp_reissueexception;
          END;
          ------------------------------ En get rrn-----------------------------
          ------------------------------ Sn get STAN----------------------------
          BEGIN
            SELECT LPAD (seq_auth_stan.NEXTVAL, 6, '0') INTO v_stan FROM DUAL;
          EXCEPTION
          WHEN OTHERS THEN
            prm_errmsg := 'Error while values from sequence ' || SUBSTR (SQLERRM, 1, 200);
            RAISE exp_reissueexception;
          END;
          ------------------------------En get STAN-------------------------------------------------
          --------------------------------Sn get card currency ----------------------------
          BEGIN
            SELECT TRIM (cbp_param_value)
            INTO v_card_curr
            FROM CMS_APPL_PAN,
              CMS_BIN_PARAM,
              CMS_PROD_CATTYPE
            WHERE cap_prod_code  = cpc_prod_code
            AND cap_card_type    = cpc_card_type
            AND cap_inst_code    = cpc_inst_code
            AND cap_pan_code     = x.cgh_card_no
            AND cbp_param_name   = 'Currency'
            AND cbp_profile_code = cpc_profile_code
            AND cbp_inst_code    = cpc_inst_code
            AND cbp_inst_code    = prm_instcode;
          EXCEPTION
          WHEN NO_DATA_FOUND THEN
            prm_errmsg := 'Currency not defined for the card';
            RAISE exp_reissueexception;
          END;
          ------------------------------En get card currency-----------------------------------------------------
          ------------------------------Sn get reason code from support reason master----------------------------
          BEGIN
            SELECT csr_spprt_rsncode,
              CSR_REASONDESC
            INTO v_resoncode,
              v_reasondesc
            FROM CMS_SPPRT_REASONS
            WHERE csr_spprt_key   = 'REISSUE'
            AND csr_spprt_rsncode = x.cgh_reason_code
            AND csr_inst_code     = prm_instcode;
          EXCEPTION
          WHEN NO_DATA_FOUND THEN
            prm_errmsg := 'Reissue  reason code not present in master';
            RAISE exp_reissueexception;
          WHEN OTHERS THEN
            prm_errmsg := 'Error while selecting reason code from master' || SUBSTR (SQLERRM, 1, 200);
            RAISE exp_reissueexception;
          END;
          ------------------------------En get reason code from support reason master---------------------------------
          -------------------------Sn find the status of card and call sp reissue pan procedure for reissue  pan--------------------------
          BEGIN
            SELECT cap_card_stat
            INTO v_cardstat
            FROM CMS_APPL_PAN
            WHERE cap_pan_code = x.cgh_card_no
            AND cap_mbr_numb   = x.CGH_MBR_NUMB
            AND cap_inst_code  = prm_instcode;
          EXCEPTION
          WHEN NO_DATA_FOUND THEN
            prm_errmsg := 'The Given Pan not found in Pan master';
            RAISE exp_reissueexception;
          WHEN OTHERS THEN
            prm_errmsg := 'Error while selecting status from app pan' || SQLERRM;
            RAISE exp_reissueexception;
          END;
          -------------------------En find the status of card and call sp reissue pan procedure for reissue  pan--------------------------
          IF prm_errmsg = 'OK' THEN
            -- if 1
            IF (v_cardstat = 2) OR (v_cardstat = 3) THEN
              NULL;
              --                Sp_Reissue_Pan (instcode,                        --prm_instcode
              --                                x.cgh_card_no,                    --prm_pancode
              --                                x.CGH_MBR_NUMB,                        --prm_mbrnumb
              --                                x.cgh_remarks,                     --prm_remark
              --                                v_resoncode,                   -- prm_resoncode
              --                                v_rrn,                                --prm_rrn
              --                                'OFFLINE',                    --prm_terminalid,
              --                                v_stan,                              --prm_stan
              --                                TO_CHAR (SYSDATE, 'YYYYMMDD'),   --prm_trandate
              --                                TO_CHAR (SYSDATE, 'HH24:MI:SS'), --prm_trantime
              --                                x.cgh_card_no,                     --prm_acctno
              --                                x.cgh_file_name,                 --prm_filename
              --                                0,                                 --prm_amount
              --                                NULL,                               --prm_refno
              --                                NULL,                         --prm_paymentmode
              --                                NULL,                        --prm_instrumentno
              --                                NULL,                           --prm_drawndate
              --                                v_card_curr,                     --prm_currcode
              --                                lupduser,                        --prm_lupduser
              --                                v_auth_msg,                  --prm_auth_message
              --                                v_newpan,                          --prm_newpan
              --                                v_process_msg,             --prm_processmessage
              --                                errmsg
              --                               );
            ELSE
              prm_errmsg := 'The Given Pan :' || x.cgh_card_no || ' is not available  as Hotlist .Its status is ' || v_cardstat;
              RAISE exp_reissueexception;
            END IF;
          END IF;
          IF prm_errmsg = 'OK' AND v_auth_msg = 'OK' THEN
            UPDATE CMS_GROUP_REISSUE_TEMP
            SET cgh_process_flag = 'S',
              cgh_process_msg    = 'SUCCESSFUL',
              cgh_new_card_no    = v_newpan
            WHERE ROWID          = x.ROWID;
            INSERT
            INTO CMS_REISSUE_DETAIL
              (
                crd_inst_code,
                crd_old_card_no,
                crd_new_card_no,
                crd_file_name,
                crd_remarks,
                crd_msg24_flag,
                crd_process_flag,
                crd_process_msg,
                crd_process_mode,
                crd_ins_user,
                crd_ins_date,
                crd_lupd_user,
                crd_lupd_date
              )
              VALUES
              (
                prm_instcode,
                x.cgh_card_no,
                v_newpan,
                x.cgh_file_name,
                x.cgh_remarks,
                'N',
                'S',
                prm_errmsg,
                'G',
                prm_lupduser,
                SYSDATE,
                prm_lupduser,
                SYSDATE
              );
          ELSIF prm_errmsg = 'OK' AND v_auth_msg <> 'OK' THEN
            prm_errmsg    := v_auth_msg;
            --RAISE nullvalueexception;
          ELSIF prm_errmsg <> 'OK' THEN
            RAISE exp_reissueexception;
          END IF;*/
         ELSIF v_prod_catg in('D','A')
         THEN
            ------------------------------Sn get reason code from support reason master----------------------------
            BEGIN
               SELECT csr_spprt_rsncode, csr_reasondesc
                 INTO v_resoncode, v_reasondesc
                 FROM cms_spprt_reasons
                WHERE csr_spprt_key = 'REISSUE'
                  --AND CSR_SPPRT_RSNCODE = x.cgh_reason_code
                  AND csr_inst_code = prm_instcode
                  AND ROWNUM < 2;
            EXCEPTION
               WHEN NO_DATA_FOUND
               THEN
                  prm_errmsg := 'Reissue  reason code not present in master';
                  RAISE exp_reissueexception;
               WHEN OTHERS
               THEN
                  prm_errmsg :=
                        'Error while selecting reason code from master'
                     || SUBSTR (SQLERRM, 1, 200);
                  RAISE exp_reissueexception;
            END;

            ------------------------------En get reason code from support reason master---------------------------------
            -------------------------Sn find the status of card and call sp reissue pan procedure for reissue  pan--------------------------
            BEGIN
               SELECT cap_card_stat
                 INTO v_cardstat
                 FROM cms_appl_pan
                WHERE cap_pan_code = x.cgh_card_no
                  AND cap_mbr_numb = x.cgh_mbr_numb
                  AND cap_inst_code = prm_instcode;
            EXCEPTION
               WHEN NO_DATA_FOUND
               THEN
                  prm_errmsg := 'The Given Pan not found in Pan master';
                  RAISE exp_reissueexception;
               WHEN OTHERS
               THEN
                  prm_errmsg :=
                       'Error while selecting status from app pan' || SQLERRM;
                  RAISE exp_reissueexception;
            END;

-------------------------En find the status of card and call sp reissue pan procedure for reissue  pan--------------------------
-------------------------Sn find product cattype -------------------------------------------------------------------------------
            --Sn check product and cardtype combination
               BEGIN
                  SELECT 1
                    INTO v_new_cardtype
                    FROM cms_prod_cattype
                   WHERE cpc_inst_code = prm_instcode
                     AND cpc_prod_code = x.cgh_new_product
                     AND cpc_card_type = x.cgh_new_productcat;
               EXCEPTION
                  WHEN NO_DATA_FOUND
                  THEN
                     prm_errmsg := ' Not a valid combination of Product and product type';
                     RAISE exp_reissueexception;
                  WHEN OTHERS
                  THEN
                     prm_errmsg :=
                           'Error while selecting product and product type combination '
                        || SUBSTR (SQLERRM, 1, 200);
                     RAISE exp_reissueexception;
               END;



--            BEGIN
--               SELECT cpc_card_type
--                 INTO v_new_cardtype
--                 FROM cms_prod_cattype
--                WHERE cpc_inst_code = prm_instcode
--                  AND cpc_cardtype_sname = x.cgh_new_productcat
--                  AND cpc_prod_code = x.cgh_new_product;
--            EXCEPTION
--               WHEN NO_DATA_FOUND
--               THEN
--                  sp_check_cardtype (prm_instcode,
--                                     x.cgh_new_product,
--                                     x.cgh_new_productcat,
--                                     v_new_cardtype,
--                                     prm_errmsg
--                                    );

--                  IF prm_errmsg <> 'OK'
--                  THEN
--                     RAISE exp_reissueexception;
--                  END IF;
--               WHEN OTHERS
--               THEN
--                  prm_errmsg :=
--                        'Error while selecting card type '
--                     || SUBSTR (SQLERRM, 1, 200);
--                  RAISE exp_reissueexception;
--            END;

-------------------------En find product cattype -------------------------------------------------------------------------------
--Sn new product catg
--Sn check new product catg with old product catg
            BEGIN
               SELECT cpm_catg_code
                 INTO v_new_prod_catg
                 FROM cms_prod_mast
                WHERE cpm_prod_code = x.cgh_new_product
                  AND cpm_inst_code = prm_instcode;
            EXCEPTION
               WHEN NO_DATA_FOUND
               THEN
                  prm_errmsg := ' New product category not found';
                  RAISE exp_reissueexception;
               WHEN TOO_MANY_ROWS
               THEN
                  prm_errmsg := 'More than one product category found ';
                  RAISE exp_reissueexception;
               WHEN OTHERS
               THEN
                  prm_errmsg :=
                        'Error while selecting product catg '
                     || SUBSTR (SQLERRM, 1, 200);
                  RAISE exp_reissueexception;
            END;

            --En check new product catg with old product catg
            --Sn check old and new prod catg
            IF v_new_prod_catg <> v_prod_catg
            THEN
               prm_errmsg :=
                          'Both old and new product category is not matching';
               RAISE exp_reissueexception;
            END IF;

            --En check old and new prod catg
            --   IF errmsg = 'OK'
            --        THEN
            -- if 1
            BEGIN
               --IF (v_cardstat = 2) OR (v_cardstat = 3)
               --THEN
               sp_reissue_pan_debit
                  (prm_instcode,                                --prm_instcode
                  -- x.cgh_card_no,                                --prm_pancode
                  --v_decr_pan,
                    Fn_Dmaps_Main(x.cgh_card_no_encr),
                   v_old_prodcode,
                   x.cgh_remarks,                                 --prm_remark
                   v_resoncode,                               -- prm_resoncode
                   'R',
                   x.cgh_new_product,
                   x.cgh_new_productcat,
                   v_new_dispname,
                   prm_lupduser,                                --prm_lupduser
                   v_ressiue_dupflg,  
                   v_newpan,                            --prm_newpan                  
                   prm_errmsg                           --prm_processmessage
                  );

               IF prm_errmsg = 'OK'
               THEN
                  v_succ_flag := 'S';
                
                --SN CREATE HASH PAN 
                BEGIN
                    v_new_hash_pan := Gethash(v_newpan);
                EXCEPTION
                WHEN OTHERS THEN
                prm_errmsg := 'Error while converting pan ' || SUBSTR(SQLERRM,1,200);
                RAISE    exp_reissueexception;
                END;
                --EN CREATE HASH PAN
                
                --SN create encr pan
                BEGIN
                    v_new_encr_pan := Fn_Emaps_Main(v_newpan);
                EXCEPTION
                WHEN OTHERS THEN
                prm_errmsg := 'Error while converting pan ' || SUBSTR(SQLERRM,1,200);
                RAISE    exp_reissueexception;
                END;
                --EN create encr pan
                  

                  UPDATE cms_group_reissue_temp
                     SET cgh_process_flag = 'S',
                         cgh_process_msg = 'SUCCESSFUL',
                         cgh_new_card_no =v_new_hash_pan, -- v_newpan
                         cgh_new_card_no_encr =v_new_encr_pan
                   WHERE cgh_rowid = x.CGH_ROWID;
                   
--                    IF v_ressiue_dupflg='D' THEN
--                        update cms_reissue_detail 
--                        set crd_process_flag='S',
--                            crd_process_msg='Suceessful',
--                            crd_new_card_no=v_newpan,
--                            crd_file_name=x.cgh_file_name
--                        where crd_old_card_no= x.cgh_card_no
--                        and crd_process_flag='N'
--                        and crd_reissue_dupflag='D';  
--                                              
--                      ELSE

                      INSERT INTO cms_reissue_detail
                                  (crd_inst_code, crd_old_card_no,
                                   crd_new_card_no, crd_file_name, crd_remarks,
                                   crd_msg24_flag, crd_process_flag,
                                   crd_process_msg, crd_process_mode,
                                   crd_ins_user, crd_ins_date, crd_lupd_user,
                                   crd_lupd_date, crd_new_dispname,
                                   crd_new_product, crd_new_productcat,
                                   crd_reason_code, crd_old_card_no_encr,
                                   crd_new_card_no_encr
                                  )
                           VALUES (prm_instcode, x.cgh_card_no,
                                   --v_newpan
                                   v_new_hash_pan, x.cgh_file_name, x.cgh_remarks,
                                   'N', 'S',
                                   'Successful', 'G',
                                   prm_lupduser, SYSDATE, prm_lupduser,
                                   SYSDATE, v_new_dispname,
                                   x.cgh_new_product, v_new_cardtype,
                                   v_resoncode, x.cgh_card_no_encr,v_new_encr_pan
                                  );

                        prm_errmsg := 'Successful';
                      --END IF;
--               ELSIF prm_errmsg =
--                          'Card '
--                       || x.cgh_card_no
--                       || ' has been sent for Duplicate reissuance'
--               THEN
--                  RAISE excp_reissue_dup;
               ELSE
                  v_succ_flag := 'E';
                  RAISE exp_reissueexception;
               END IF;
            /*ELSE
            prm_errmsg :=
            'The Given Pan :'
            || x.cgh_card_no
            || ' is not available  as Hotlist .Its status is '
            || v_cardstat;
            RAISE exp_reissueexception;
            END IF;*/
            END;
         --     END IF;
         END IF;
      EXCEPTION                                         --<<LOOP EXCEPTION>>--
         WHEN exp_reissueexception
         THEN
            ROLLBACK TO v_reissuesavepoint;
            v_succ_flag := 'E';

            UPDATE cms_group_reissue_temp
               SET cgh_process_flag = 'E',
                   cgh_process_msg = prm_errmsg
             WHERE cgh_rowid= x.CGH_ROWID;

            INSERT INTO cms_reissue_detail
                        (crd_inst_code, crd_old_card_no, crd_new_card_no,
                         crd_file_name, crd_remarks, crd_msg24_flag,
                         crd_process_flag, crd_process_msg, crd_process_mode,
                         crd_ins_user, crd_ins_date, crd_lupd_user,
                         crd_lupd_date, crd_new_dispname, crd_new_product,
                         crd_new_productcat, crd_reason_code, crd_old_card_no_encr, crd_new_card_no_encr
                        )
                 VALUES (prm_instcode, x.cgh_card_no, NULL,
                         x.cgh_file_name, x.cgh_remarks, 'N',
                         'E', prm_errmsg, 'G',
                         prm_lupduser, SYSDATE, prm_lupduser,
                         SYSDATE, v_new_dispname, x.cgh_new_product,
                         v_new_cardtype, v_resoncode, x.cgh_card_no_encr, NULL
                        );
--         WHEN excp_reissue_dup
--         THEN
--            ROLLBACK TO v_reissuesavepoint;
--            v_succ_flag := 'C';

--            UPDATE cms_group_reissue_temp
--               SET cgh_process_flag = 'C',
--                   cgh_dup_flag='D',
--                   cgh_process_msg = prm_errmsg,
--                   cgh_reason_code=v_resoncode
--             WHERE cgh_rowid = x.CGH_ROWID;

--            INSERT INTO cms_reissue_detail
--                        (crd_inst_code, crd_old_card_no, crd_new_card_no,
--                         crd_file_name, crd_remarks, crd_msg24_flag,
--                         crd_process_flag, crd_process_msg, crd_process_mode,
--                         crd_ins_user, crd_ins_date, crd_lupd_user,
--                         crd_lupd_date, crd_reissue_dupflag,
--                         crd_new_dispname, crd_new_product,
--                         crd_new_productcat, crd_reason_code
--                        )
--                 VALUES (prm_instcode, x.cgh_card_no, v_newpan,
--                         x.cgh_file_name, x.cgh_remarks, 'N',
--                         'C', prm_errmsg, 'G',
--                         prm_lupduser, SYSDATE, prm_lupduser,
--                         SYSDATE, 'D',
--                         v_new_dispname, x.cgh_new_product,
--                         v_new_cardtype, v_resoncode
--                        );
         WHEN OTHERS
         THEN
            prm_errmsg :=
                        'Error while processing ' || SUBSTR (SQLERRM, 1, 200);
            ROLLBACK TO v_reissuesavepoint;
            v_succ_flag := 'E';

            UPDATE cms_group_reissue_temp
               SET cgh_process_flag = 'E',
                   cgh_process_msg = prm_errmsg
             WHERE cgh_rowid = x.cgh_rowid;

            INSERT INTO cms_reissue_detail
                        (crd_inst_code, crd_old_card_no, crd_new_card_no,
                         crd_file_name, crd_remarks, crd_msg24_flag,
                         crd_process_flag, crd_process_msg, crd_process_mode,
                         crd_ins_user, crd_ins_date, crd_lupd_user,
                         crd_lupd_date, crd_new_dispname, crd_new_product,
                         crd_new_productcat, crd_reason_code, crd_old_card_no_encr, crd_new_card_no_encr
                        )
                 VALUES (prm_instcode, x.cgh_card_no, NULL,
                         x.cgh_file_name, x.cgh_remarks, 'N',
                         'E', prm_errmsg, NULL,
                         prm_lupduser, SYSDATE, prm_lupduser,
                         SYSDATE, v_new_dispname, x.cgh_new_product,
                         v_new_cardtype, v_resoncode, x.cgh_card_no_encr, NULL
                        );
      END;
      
                    --siva mar 22 2011
        --start for audit log success
      IF prm_errmsg = 'Successful'
      THEN
         --insert into Audit table
         BEGIN
            INSERT INTO cms_audit_log_process
                        (cal_inst_code, cal_appl_no, cal_acct_no,
                         cal_pan_no, cal_prod_code, cal_prg_name,
                         cal_action, cal_status, cal_ip_address,
                         cal_ref_tab_name, cal_ref_tab_rowid, cal_pan_encr,
                         cal_ins_user, cal_ins_date
                        )
                 VALUES (prm_instcode, v_applcode, v_acctno,
                         x.cgh_card_no, v_old_prodcode, 'GROUP REISSUE',
                         'INSERT','SUCCESS', prm_ipaddr,
                         'CMS_PAN_SPPRT', '', x.cgh_card_no_encr,
                         prm_lupduser, SYSDATE
                        );
         EXCEPTION
            --excp of begin 3
            WHEN OTHERS
            THEN
               prm_errmsg :=
                     'Error while inserting records for support detail'
                  || SUBSTR (SQLERRM, 1, 200);
               RETURN;
         END;
      --end insert audit table

       --end for audit log success
      -- start for failure record
      ELSE
         --insert into Audit table
         BEGIN
            INSERT INTO cms_audit_log_process
                        (cal_inst_code, cal_appl_no, cal_acct_no,
                         cal_pan_no, cal_prod_code, cal_prg_name,
                         cal_action, cal_status, cal_ip_address,
                         cal_ref_tab_name, cal_ref_tab_rowid, cal_pan_encr,
                         cal_ins_user, cal_ins_date
                        )
                 VALUES (prm_instcode, v_applcode, v_acctno,
                         x.cgh_card_no, v_old_prodcode, 'GROUP REISSUE',
                         'INSERT', 'FAILURE', prm_ipaddr,
                         'CMS_PAN_SPPRT', '', x.cgh_card_no_encr,
                         prm_lupduser, SYSDATE
                        );
         EXCEPTION
            --excp of begin 3
            WHEN OTHERS
            THEN
               prm_errmsg :=
                     'Error while inserting records for support detail'
                  || SUBSTR (SQLERRM, 1, 200);
               RETURN;
         END;
      --end insert audit table
      END IF;

      --end for failure status record
          --siva end mar 22 2011

      BEGIN
         INSERT INTO process_audit_log
                     (pal_card_no, pal_activity_type, pal_transaction_code,
                      pal_delv_chnl, pal_tran_amt, pal_source,
                      pal_success_flag, pal_ins_user, pal_ins_date,
                      pal_process_msg, pal_reason_desc, pal_remarks,
                      pal_spprt_type, pal_inst_code, pal_new_card,pal_card_no_encr,pal_new_card_encr
                     )
              VALUES (x.cgh_card_no, v_remark, v_txn_code,
                      v_del_channel, 0, 'HOST',
                      v_succ_flag, prm_lupduser, SYSDATE,
                      prm_errmsg, v_reasondesc, x.cgh_remarks,
                      'G', prm_instcode, --v_newpan
                      v_new_hash_pan,x.cgh_card_no_encr,v_new_encr_pan
                     );
      EXCEPTION
         WHEN OTHERS
         THEN
            --prm_prm_errmsg := 'Pan Not Found in Master';
            UPDATE cms_group_reissue_temp
               SET cgh_process_flag = 'E',
                   cgh_process_msg = 'Error while inserting into Audit log'
             WHERE cgh_rowid = x.cgh_rowid;
      END;                                              --<<LOOP EXCEPTION>>--
   END LOOP;

   prm_errmsg := 'OK';
EXCEPTION
   WHEN OTHERS
   THEN
      prm_errmsg := 'Main Excp -- ' || SUBSTR (SQLERRM, 1, 200);
END;
/


