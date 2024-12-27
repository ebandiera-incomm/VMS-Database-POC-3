CREATE OR REPLACE PROCEDURE VMSCMS.Sp_Grp_Block_Pan (
   prm_instcode   IN       NUMBER,
   prm_ipaddr     IN       VARCHAR2,
   prm_lupduser   IN       NUMBER,
   prm_errmsg     OUT      VARCHAR2
)
AS
   v_count                  NUMBER (1);
   v_card_curr              VARCHAR2 (3);
   v_rec_cnt                NUMBER (9);
   v_errflag                VARCHAR2 (1);
   v_errmsg                 VARCHAR2 (300);
   v_authmsg                VARCHAR2 (300);
   v_rrn                    VARCHAR2 (12);
   v_stan                   VARCHAR2 (12);
   v_blocksavepoint         NUMBER (9)                             DEFAULT 99;
   init_savepoint           NUMBER (9)                             DEFAULT 99;
   exp_loop_reject_record   EXCEPTION;
   exp_main_reject_record   EXCEPTION;
   v_resoncode              CMS_SPPRT_REASONS.csr_spprt_rsncode%TYPE;
   v_prod_catg              CMS_APPL_PAN.cap_card_stat%TYPE;
   v_txn_code               VARCHAR2 (2);
   v_txn_type               VARCHAR2 (2);
   v_txn_mode               VARCHAR2 (2);
   v_del_channel            VARCHAR2 (2);
   v_succ_flag              VARCHAR2 (1);
   v_remark                 CMS_PAN_SPPRT.cps_func_remark%TYPE;
   v_reasondesc             CMS_SPPRT_REASONS.CSR_REASONDESC%TYPE;
   v_cardstat               cms_appl_pan.cap_card_stat%TYPE;     --siva added for card status check
   v_applcode                   CMS_APPL_PAN.cap_appl_code%TYPE;
   v_acctno                     CMS_APPL_PAN.cap_acct_no%TYPE;                  
   v_prodcode                   CMS_APPL_PAN.cap_prod_code%TYPE;

   CURSOR c1
   IS
      SELECT cgt_card_no, cgt_file_name, cgt_remarks, cgt_process_flag,
             cgt_process_msg, cgt_mbr_numb, CGT_CARD_NO_ENCR, ROWID r
        FROM CMS_GROUP_BLOCK_TEMP
       WHERE cgt_process_flag = 'N'
       AND   cgt_inst_code = prm_instcode;
       
BEGIN                                                       --<< MAIN BEGIN >>
   prm_errmsg := 'OK';
   v_remark := 'Group Block';

------------------------------Sn check for pending records----------------------------
   BEGIN
      SELECT 1
        INTO v_rec_cnt
        FROM CMS_GROUP_BLOCK_TEMP
       WHERE cgt_process_flag = 'N' AND ROWNUM < 2;
   EXCEPTION
      WHEN NO_DATA_FOUND
      THEN
         v_errmsg := 'No record found for card blocking  processing';
         RAISE exp_main_reject_record;
      WHEN OTHERS
      THEN
         v_errmsg :=
               'Error while getting records from table '
            || SUBSTR (SQLERRM, 1, 200);
         RAISE exp_main_reject_record;
   END;

   ------------------------------En check for pending records----------------------------
   
   ------------------------------ Sn get Function Master----------------------------
   BEGIN
      SELECT cfm_txn_code, cfm_txn_mode, cfm_delivery_channel, cfm_txn_type
        INTO v_txn_code, v_txn_mode, v_del_channel, v_txn_type
        FROM CMS_FUNC_MAST
       --WHERE cfm_func_code = 'BLOCK SPRT';
        WHERE cfm_func_code = 'BLOCK'
      AND cfm_inst_code=prm_instcode;
   EXCEPTION
      WHEN OTHERS
      THEN
         prm_errmsg :=
                   'Function Master Not Defined ' || SUBSTR (SQLERRM, 1, 200);
         --RAISE exp_loop_reject_record;
         RETURN;
   END;

   ------------------------------ En get Function Master----------------------------
   
   ------------------------------Sn get reason code from support reason master----------------------------
    BEGIN
       SELECT csr_spprt_rsncode,CSR_REASONDESC
         INTO v_resoncode,v_reasondesc
         FROM CMS_SPPRT_REASONS
        WHERE csr_spprt_key = 'BLOCK' AND ROWNUM < 2
        AND   csr_inst_code = prm_instcode;
    EXCEPTION
       WHEN NO_DATA_FOUND
       THEN
          v_errmsg := 'Block  reason code not present in master';
          RETURN;
       WHEN OTHERS
       THEN
          v_errmsg :=
                'Error while selecting reason code from master'
             || SUBSTR (SQLERRM, 1, 200);
          RETURN;
    END;

    ------------------------------En get reason code from support reason master----------------------------
--    
   FOR i IN c1
   LOOP
      v_blocksavepoint := v_blocksavepoint + 1;
      SAVEPOINT v_blocksavepoint;
      v_errmsg := 'OK';

      BEGIN                                             -- << LOOP I BEGIN >>
         BEGIN
            SELECT cap_prod_catg ,cap_card_stat,CAP_APPL_CODE,CAP_ACCT_NO,CAP_PROD_CODE
              INTO v_prod_catg,v_cardstat,v_applcode, v_acctno, v_prodcode
              FROM CMS_APPL_PAN
             WHERE cap_pan_code = i.cgt_card_no
               AND cap_mbr_numb = i.cgt_mbr_numb
               AND cap_inst_code=prm_instcode;
               
               IF v_prod_catg IS NULL OR v_cardstat IS NULL THEN
                   prm_errmsg := 'Product category or card status not found in master for card no ';
                   RAISE exp_loop_reject_record;
                   END IF;
                   
         EXCEPTION
            WHEN exp_loop_reject_record THEN
            RAISE;
            
            WHEN NO_DATA_FOUND
            THEN
               prm_errmsg := 'Card not found in master';
               RAISE exp_loop_reject_record;
               
            WHEN OTHERS
            THEN
               v_errmsg :=
                     'Error while getting records from table '
                  || SUBSTR (SQLERRM, 1, 200);
               RAISE exp_loop_reject_record;
         END;
         
         IF v_cardstat <> '1'    --siva Mar 22 2011 card status check
         THEN
            prm_errmsg := 'Card status is not open, cannot be Blocked';
            RAISE exp_loop_reject_record;
         END IF;
------------------------------ Sn get rrn----------------------------
         IF v_prod_catg = 'P'
         THEN
            BEGIN
               SELECT LPAD (seq_auth_rrn.NEXTVAL, 12, '0')
                 INTO v_rrn
                 FROM DUAL;
            EXCEPTION
               WHEN OTHERS
               THEN
                  prm_errmsg :=
                        'Error while values from sequence '
                     || SUBSTR (SQLERRM, 1, 200);
                  RETURN;
            END;

------------------------------ En get rrn----------------------------
------------------------------ Sn get STAN----------------------------
            BEGIN
               SELECT LPAD (seq_auth_stan.NEXTVAL, 6, '0')
                 INTO v_stan
                 FROM DUAL;
            EXCEPTION
               WHEN OTHERS
               THEN
                  prm_errmsg :=
                        'Error while values from sequence '
                     || SUBSTR (SQLERRM, 1, 200);
                  RETURN;
            END;

            ------------------------------En get STAN----------------------------

            --------------------------------Sn get card currency ----------------------------
            BEGIN
               SELECT TRIM (cbp_param_value)
                 INTO v_card_curr
                 FROM CMS_APPL_PAN, CMS_BIN_PARAM, CMS_PROD_CATTYPE
                WHERE cap_prod_code = cpc_prod_code
                  AND cap_card_type = cpc_card_type
                  AND cap_pan_code = i.cgt_card_no
                  AND cbp_param_name = 'Currency'
                  AND cbp_profile_code = cpc_profile_code
                  AND cap_inst_code= prm_instcode;
            EXCEPTION
               WHEN NO_DATA_FOUND
               THEN
                  v_errmsg := 'Currency not defined for the card';
                  RAISE exp_loop_reject_record;
            END;

            ------------------------------En get card currency--------------------------------
 
 
             ------------------------------ Sn call to procedure----------------------------
            Sp_Block_Pan_prepaid (prm_instcode,
                           v_rrn,
                           'offline',
                           v_stan,
                           TO_CHAR (SYSDATE, 'YYYYMMDD'),
                           TO_CHAR (SYSDATE, 'HH24:MI:SS'),
                           Fn_Dmaps_Main(i.cgt_card_no_encr),
                           i.cgt_file_name,
                           i.cgt_remarks,
                           v_resoncode,
                           0,
                           NULL,
                           NULL,
                           NULL,
                           NULL,
                           v_card_curr,
                           prm_lupduser,
                           v_authmsg,
                           v_errmsg
                          );
 
             IF v_errmsg <> 'OK'
             THEN
                 v_succ_flag := 'E';
                RAISE exp_loop_reject_record;
             END IF;
 
             IF v_errmsg = 'OK' AND v_authmsg <> 'OK'
             THEN
                v_errflag := 'E';
                v_errmsg := v_authmsg;
                v_succ_flag := 'E';
             END IF;
 
             IF v_errmsg = 'OK' AND v_authmsg = 'OK'
             THEN
                v_errflag := 'S';
                v_errmsg := 'Successful';
                v_succ_flag := 'S';
 
                UPDATE CMS_GROUP_BLOCK_TEMP
                   SET cgt_process_flag = 'S',
                       cgt_process_msg = v_errmsg
                 WHERE ROWID = i.r;
             END IF;
 
             INSERT INTO CMS_BLOCK_DETAIL
                         (cbd_inst_code, cbd_card_no, cbd_file_name,
                          cbd_remarks, cbd_msg24_flag, cbd_process_flag,
                          cbd_process_msg, cbd_process_mode, cbd_ins_user,
                          cbd_ins_date, cbd_lupd_user, cbd_lupd_date
                         )
                  VALUES (prm_instcode, i.cgt_card_no, i.cgt_file_name,
                          i.cgt_remarks, 'N', v_errflag,
                          v_errmsg, 'G', prm_lupduser,
                          SYSDATE, prm_lupduser, SYSDATE
                         );
         ------------------------------ En call to procedure----------------------------
         ELSIF v_prod_catg in('D','A')
         THEN
            ------------------------------Sn get reason code from support reason master----------------------------
--             BEGIN
--                SELECT csr_spprt_rsncode
--                  INTO v_resoncode
--                  FROM CMS_SPPRT_REASONS
--                 WHERE csr_spprt_key = 'BLOCK'
--                 AND csr_inst_code= prm_instcode
--                 AND ROWNUM < 2;
--             EXCEPTION
--                WHEN NO_DATA_FOUND
--                THEN
--                   v_errmsg := 'Block  reason code not present in master';
--                   RAISE exp_loop_reject_record;
--                WHEN OTHERS
--                THEN
--                   v_errmsg :=
--                         'Error while selecting reason code from master'
--                      || SUBSTR (SQLERRM, 1, 200);
--                   RAISE exp_loop_reject_record;
--             END;
-- 
--             ------------------------------En get reason code from support reason master----------------------------
            Sp_Block_Pan_Debit (prm_instcode,
                                --i.cgt_card_no,
                                fn_dmaps_main(i.CGT_CARD_NO_ENCR),
                                i.cgt_mbr_numb,
                                i.cgt_remarks,
                                v_resoncode,
                                prm_lupduser,
                                0,
                                v_errmsg
                               );

            IF v_errmsg <> 'OK'
            THEN
                v_succ_flag := 'E';
               RAISE exp_loop_reject_record;
            END IF;

            IF v_errmsg = 'OK'
            THEN
               v_errflag := 'S';
               v_errmsg := 'Successful';
               v_succ_flag := 'S';

--                
               BEGIN
                       UPDATE CMS_GROUP_BLOCK_TEMP
                             SET cgt_process_flag = 'S',
                                    cgt_process_msg = v_errmsg
                    WHERE ROWID = i.r;
                
                      IF sql%rowcount = 0 then
                              v_errmsg :='Record not updated in temp segment ';
                            RAISE exp_loop_reject_record;
                      END IF;
--                 
               EXCEPTION
                        WHEN exp_loop_reject_record THEN
                        RAISE;
                
                        WHEN OTHERS THEN
                        v_errmsg :='Error while updating process detail in temp   segment ' || substr(sqlerrm,1,150);
                        RAISE exp_loop_reject_record;
--                
               END;
            
            END IF;
--             
            BEGIN
                INSERT INTO CMS_BLOCK_DETAIL
                            (cbd_inst_code, cbd_card_no, cbd_file_name,
                             cbd_remarks, cbd_msg24_flag, cbd_process_flag,
                             cbd_process_msg, cbd_process_mode, cbd_ins_user,
                             cbd_ins_date, cbd_lupd_user, cbd_lupd_date
                            )
                     VALUES (prm_instcode, i.cgt_card_no, i.cgt_file_name,
                             i.cgt_remarks, 'N', v_errflag,
                             v_errmsg, 'G', prm_lupduser,
                             SYSDATE, prm_lupduser, SYSDATE
                            );
             EXCEPTION
                WHEN OTHERS THEN
                v_errmsg :='Error while updating process detail in block detail segment ' || substr(sqlerrm,1,150);
                RAISE exp_loop_reject_record;
               
               END;
          END IF;
      EXCEPTION                                       -- << LOOP I EXCEPTION>>
         WHEN exp_loop_reject_record
         THEN
            ROLLBACK TO v_blocksavepoint;
            v_succ_flag := 'E';
            BEGIN
            
                UPDATE CMS_GROUP_BLOCK_TEMP
                   SET cgt_process_flag = 'E',
                       cgt_process_msg = v_errmsg
                 WHERE ROWID = i.r;
                 
                 
    
                INSERT INTO CMS_BLOCK_DETAIL
                            (cbd_inst_code, cbd_card_no, cbd_file_name,
                             cbd_remarks, cbd_msg24_flag, cbd_process_flag,
                             cbd_process_msg, cbd_process_mode, cbd_ins_user,
                             cbd_ins_date, cbd_lupd_user, cbd_lupd_date
                            )
                     VALUES (prm_instcode, i.cgt_card_no, i.cgt_file_name,
                             i.cgt_remarks, 'N', 'E',
                             v_errmsg, 'G', prm_lupduser,
                             SYSDATE, prm_lupduser, SYSDATE
                            );
             EXCEPTION
             WHEN OTHERS THEN
                v_errmsg :='Error while updating process detail in block detail segment ' || substr(sqlerrm,1,150);
                RETURN;
             
             END;
         WHEN OTHERS
         THEN
            ROLLBACK TO v_blocksavepoint;
            v_errmsg := 'Error while processing block  ' || substr(sqlerrm,1,200);
            v_succ_flag := 'E';
            BEGIN
            
                UPDATE CMS_GROUP_BLOCK_TEMP
                   SET cgt_process_flag = 'E',
                       cgt_process_msg = v_errmsg
                 WHERE ROWID = i.r;

                INSERT INTO CMS_BLOCK_DETAIL
                            (cbd_inst_code, cbd_card_no, cbd_file_name,
                             cbd_remarks, cbd_msg24_flag, cbd_process_flag,
                             cbd_process_msg, cbd_process_mode, cbd_ins_user,
                             cbd_ins_date, cbd_lupd_user, cbd_lupd_date
                            )
                     VALUES (prm_instcode, i.cgt_card_no, i.cgt_file_name,
                             i.cgt_remarks, 'N', 'E',
                             v_errmsg, 'G', prm_lupduser,
                             SYSDATE, prm_lupduser, SYSDATE
                            );
             EXCEPTION
             WHEN OTHERS THEN
                v_errmsg :='Error while updating process detail in block detail segment ' || substr(sqlerrm,1,150);
                RETURN;
             
             END;
     END;
            --siva mar 22 2011
        --start for audit log success
      IF v_errmsg = 'Successful'
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
                         i.CGT_CARD_NO, v_prodcode, 'GROUP BLOCK',
                         'INSERT', 'SUCCESS', prm_ipaddr,
                         'CMS_PAN_SPPRT', '', i.CGT_CARD_NO_ENCR,
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
                         i.CGT_CARD_NO, v_prodcode, 'GROUP BLOCK',
                         'INSERT', 'FAILURE', prm_ipaddr,
                         'CMS_PAN_SPPRT', '', i.CGT_CARD_NO_ENCR,
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
          --siva end mar 22 2011                                                                     --<< LOOP I END >>
      
      BEGIN
         INSERT INTO PROCESS_AUDIT_LOG
                     (pal_card_no, pal_activity_type, pal_transaction_code,
                      pal_delv_chnl, pal_tran_amt, pal_source,
                      pal_success_flag, pal_ins_user, pal_ins_date,
                      pal_process_msg, pal_reason_desc, pal_remarks,
                      pal_spprt_type,
                      pal_inst_code
                     )
              VALUES (i.cgt_card_no, v_remark, v_txn_code,
                      v_del_channel, 0, 'HOST',
                      v_succ_flag, prm_lupduser, SYSDATE,
                      v_errmsg,v_reasondesc, i.cgt_remarks,'G',
                      prm_instcode
                     );
      EXCEPTION
         WHEN OTHERS
         THEN
            --prm_errmsg := 'Pan Not Found in Master';
            UPDATE CMS_GROUP_BLOCK_TEMP
               SET CGT_PROCESS_FLAG = 'E',
                   CGT_PROCESS_MSG = 'Error while inserting into Audit log'
             WHERE ROWID = i.r;
        END;
    -- END;                                                   
   END LOOP;

   prm_errmsg := 'OK';
EXCEPTION                                                --<< MAIN EXCEPTION>>
   WHEN exp_main_reject_record
   THEN
      prm_errmsg := v_errmsg;
   WHEN OTHERS
   THEN
      prm_errmsg := ' Error from main ' || SUBSTR (SQLERRM, 1, 200);
END;                                                           --<< MAIN END>>
/


