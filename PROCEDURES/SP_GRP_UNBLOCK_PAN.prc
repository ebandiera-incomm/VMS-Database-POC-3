CREATE OR REPLACE PROCEDURE VMSCMS.Sp_Grp_Unblock_Pan (
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
   v_resoncode              NUMBER (3);
   v_unblocksavepoint       NUMBER (9)                        DEFAULT 99;
   init_savepoint           NUMBER (9)                        DEFAULT 99;
   v_txn_code               VARCHAR2 (2);
   v_txn_type               VARCHAR2 (2);
   v_txn_mode               VARCHAR2 (2);
   v_del_channel            VARCHAR2 (2);
   v_succ_flag              VARCHAR2 (1);
   v_prod_catg              CMS_APPL_PAN.CAP_PROD_CATG%TYPE;
   v_remark                 CMS_PAN_SPPRT.cps_func_remark%TYPE;
   v_reasondesc                CMS_SPPRT_REASONS.csr_reasondesc%TYPE;
   v_cardstat                   CMS_APPL_PAN.cap_card_stat%TYPE;
   v_applcode                   CMS_APPL_PAN.cap_appl_code%TYPE;
   v_acctno                     CMS_APPL_PAN.cap_acct_no%TYPE;                  
   v_prodcode                   CMS_APPL_PAN.cap_prod_code%TYPE;          
   exp_loop_reject_record   EXCEPTION;
   exp_main_reject_record   EXCEPTION;

   CURSOR c1
   IS
      SELECT cgu_card_no, cgu_file_name, cgu_remarks, cgu_process_flag,
             cgu_process_msg, cgu_mbr_numb, cgu_card_no_encr, ROWID r
        FROM CMS_GROUP_UNBLOCK_TEMP
       WHERE cgu_process_flag = 'N'
       AND     cgu_inst_code  = prm_instcode;
BEGIN                                                       --<< MAIN BEGIN >>
   prm_errmsg := 'OK';
   v_remark := 'Group Deblock';

--Sn check for pending records
   BEGIN
      SELECT 1
        INTO v_rec_cnt
        FROM CMS_GROUP_UNBLOCK_TEMP
       WHERE cgu_process_flag = 'N' 
       AND cgu_inst_code= prm_instcode
       AND ROWNUM < 2;
   EXCEPTION
      WHEN NO_DATA_FOUND
      THEN
         prm_errmsg := 'No record found for card unblocking  processing';
         RAISE exp_main_reject_record;
      WHEN OTHERS
      THEN
         prm_errmsg :=
               'Error while getting records from table '
            || SUBSTR (SQLERRM, 1, 200);
         RAISE exp_main_reject_record;
   END;

   --------------------------------En check for pending records------------------------------
   
   ------------------------------ Sn get Function Master----------------------------
   BEGIN
      SELECT cfm_txn_code, cfm_txn_mode, cfm_delivery_channel, cfm_txn_type
        INTO v_txn_code, v_txn_mode, v_del_channel, v_txn_type
        FROM CMS_FUNC_MAST
       WHERE cfm_func_code = 'UNBLOKSPRT'
       AND cfm_inst_code= prm_instcode;
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
        SELECT csr_spprt_rsncode,csr_reasondesc
          INTO v_resoncode,v_reasondesc    
          FROM CMS_SPPRT_REASONS
         WHERE csr_spprt_key = 'DBLOK' AND ROWNUM < 2
         AND csr_inst_code= prm_instcode;
     EXCEPTION
        WHEN NO_DATA_FOUND
        THEN
           prm_errmsg := 'Deblock  reason code not present in master';
           RETURN;
        WHEN OTHERS
        THEN
           prm_errmsg :=
                 'Error while selecting reason code from master'
              || SUBSTR (SQLERRM, 1, 200);
           RETURN;
     END;

        ------------------------------En get reason code from support reason master---------------------------------
   
   FOR i IN c1
   LOOP
      v_unblocksavepoint := v_unblocksavepoint + 1;
      SAVEPOINT v_unblocksavepoint;

      BEGIN                                             -- << LOOP I BEGIN >>
         BEGIN
            SELECT cap_prod_catg,cap_card_stat,CAP_APPL_CODE,CAP_ACCT_NO,CAP_PROD_CODE
              INTO v_prod_catg ,v_cardstat ,v_applcode, v_acctno, v_prodcode
              FROM CMS_APPL_PAN
             WHERE cap_pan_code = i.cgu_card_no
               AND cap_mbr_numb = i.cgu_mbr_numb
               AND cap_inst_code= prm_instcode;
         EXCEPTION
            WHEN NO_DATA_FOUND
            THEN
               v_errmsg := 'No product category or card status defined for the card';
               RAISE exp_loop_reject_record;
            WHEN OTHERS
            THEN
               v_errmsg :=
                     'Error while getting records from table '
                  || SUBSTR (SQLERRM, 1, 200);
               RAISE exp_loop_reject_record;
         END;
         
         IF v_cardstat <> '0'    --siva Mar 22 2011 card status check
         THEN
            prm_errmsg := 'Card status is not blocked, cannot be UnBlocked';
            RAISE exp_loop_reject_record;
         END IF;

         IF v_prod_catg = 'P'
         THEN
--------------------------------Sn get rrn------------------------------
            BEGIN
               SELECT LPAD (seq_auth_rrn.NEXTVAL, 12, '0')
                 INTO v_rrn
                 FROM DUAL;
            EXCEPTION
               WHEN OTHERS
               THEN
                  v_errmsg :=
                        'Error while values from sequence '
                     || SUBSTR (SQLERRM, 1, 200);
                  RAISE exp_loop_reject_record;
            END;

-------------------------------- En get rrn------------------------------
-------------------------------- Sn get STAN------------------------------
            BEGIN
               SELECT LPAD (seq_auth_stan.NEXTVAL, 6, '0')
                 INTO v_stan
                 FROM DUAL;
            EXCEPTION
               WHEN OTHERS
               THEN
                  v_errmsg :=
                        'Error while values from sequence '
                     || SUBSTR (SQLERRM, 1, 200);
                  RAISE exp_loop_reject_record;
            END;

--------------------------------En get STAN------------------------------

                 --------------------------------Sn get card currency ----------------------------
            BEGIN
               SELECT TRIM (cbp_param_value)
                 INTO v_card_curr
                 FROM CMS_APPL_PAN, CMS_BIN_PARAM, CMS_PROD_CATTYPE
                WHERE cap_prod_code = cpc_prod_code
                  AND cap_card_type = cpc_card_type
                  AND cap_pan_code = i.cgu_card_no
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

            -------------------------------- Sn call to procedure------------------------------
             sp_unblock_pan_prepaid (prm_instcode,
                             v_rrn,
                             'offline',
                             v_stan,
                             TO_CHAR (SYSDATE, 'YYYYMMDD'),
                             TO_CHAR (SYSDATE, 'HH24:MI:SS'),
                             Fn_Dmaps_Main(i.cgu_card_no_encr),
                             i.cgu_file_name,
                             i.cgu_remarks,
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
                v_succ_flag := 'E';
                v_errmsg := v_authmsg;
             END IF;
 
             IF v_errmsg = 'OK' AND v_authmsg = 'OK'
             THEN
                v_errflag := 'S';
                v_errmsg := 'Successful';
                v_succ_flag := 'S';
 
                BEGIN
                   UPDATE CMS_GROUP_UNBLOCK_TEMP
                      SET cgu_process_flag = 'S',
                          cgu_process_msg = v_errmsg
                    WHERE ROWID = i.r;
 
                   IF SQL%ROWCOUNT = 0
                   THEN
                      v_errflag := 'E';
                      v_errmsg := 'Error while updating flag in temp table';
                      RAISE exp_loop_reject_record;
                   END IF;
                END;
             END IF;
 
             INSERT INTO CMS_UNBLOCK_DETAIL
                         (cud_inst_code, cud_card_no, cud_file_name,
                          cud_remarks, cud_msg24_flag, cud_process_flag,
                          cud_process_msg, cud_process_mode, cud_ins_user,
                          cud_ins_date, cud_lupd_user, cud_lupd_date
                         )
                  VALUES (prm_instcode, i.cgu_card_no, i.cgu_file_name,
                          i.cgu_remarks, 'N', v_errflag,
                          v_errmsg, 'G', prm_lupduser,
                          SYSDATE, prm_lupduser, SYSDATE
                         );
         --------------------------------En call to procedure------------------------------
         ELSIF v_prod_catg in('D','A')
         THEN
            ------------------------------Sn get reason code from support reason master----------------------------
            BEGIN
               SELECT csr_spprt_rsncode
                 INTO v_resoncode
                 FROM CMS_SPPRT_REASONS
                WHERE csr_spprt_key = 'DBLOK' AND ROWNUM < 2
                AND csr_inst_code= prm_instcode;
            EXCEPTION
               WHEN NO_DATA_FOUND
               THEN
                  v_errmsg := 'Deblock  reason code not present in master';
                  RAISE exp_loop_reject_record;
               WHEN OTHERS
               THEN
                  v_errmsg :=
                        'Error while selecting reason code from master'
                     || SUBSTR (SQLERRM, 1, 200);
                  RAISE exp_loop_reject_record;
            END;

            ------------------------------En get reason code from support reason master---------------------------------

            -------------------------------- Sn call to procedure------------------------------
            Sp_Unblock_Pan_Debit (prm_instcode,
                                  --i.cgu_card_no,
                                  fn_dmaps_main(i.cgu_card_no_encr),
                                  i.cgu_mbr_numb,
                                  i.cgu_remarks,
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

               BEGIN
                  UPDATE CMS_GROUP_UNBLOCK_TEMP
                     SET cgu_process_flag = 'S',
                         cgu_process_msg = v_errmsg
                   WHERE ROWID = i.r;

                  IF SQL%ROWCOUNT = 0
                  THEN
                     v_errflag := 'E';
                     v_errmsg := 'Error while updating flag in temp table';
                     RAISE exp_loop_reject_record;
                  END IF;
               END;
            END IF;

            INSERT INTO CMS_UNBLOCK_DETAIL
                        (cud_inst_code, cud_card_no, cud_file_name,
                         cud_remarks, cud_msg24_flag, cud_process_flag,
                         cud_process_msg, cud_process_mode, cud_ins_user,
                         cud_ins_date, cud_lupd_user, cud_lupd_date
                        )
                 VALUES (prm_instcode, i.cgu_card_no, i.cgu_file_name,
                         i.cgu_remarks, 'N', v_errflag,
                         v_errmsg, 'G', prm_lupduser,
                         SYSDATE, prm_lupduser, SYSDATE
                        );
         ------------------------------En call to procedure------------------------------
         END IF;
      EXCEPTION                                       -- << LOOP I EXCEPTION>>
         WHEN exp_loop_reject_record
         THEN
            ROLLBACK TO v_unblocksavepoint;
            v_succ_flag := 'E';

            UPDATE CMS_GROUP_UNBLOCK_TEMP
               SET cgu_process_flag = 'E',
                   cgu_process_msg = v_errmsg
             WHERE ROWID = i.r;

            INSERT INTO CMS_UNBLOCK_DETAIL
                        (cud_inst_code, cud_card_no, cud_file_name,
                         cud_remarks, cud_msg24_flag, cud_process_flag,
                         cud_process_msg, cud_process_mode, cud_ins_user,
                         cud_ins_date, cud_lupd_user, cud_lupd_date
                        )
                 VALUES (prm_instcode, i.cgu_card_no, i.cgu_file_name,
                         i.cgu_remarks, 'N', 'E',
                         v_errmsg, 'G', prm_lupduser,
                         SYSDATE, prm_lupduser, SYSDATE
                        );
         WHEN OTHERS
         THEN
             v_errmsg := 'Error while processing deblock  ' || substr(sqlerrm,1,200);
            ROLLBACK TO v_unblocksavepoint;
            v_succ_flag := 'E';

            UPDATE CMS_GROUP_UNBLOCK_TEMP
               SET cgu_process_flag = 'E',
                   cgu_process_msg = v_errmsg
             WHERE ROWID = i.r;

            INSERT INTO CMS_UNBLOCK_DETAIL
                        (cud_inst_code, cud_card_no, cud_file_name,
                         cud_remarks, cud_msg24_flag, cud_process_flag,
                         cud_process_msg, cud_process_mode, cud_ins_user,
                         cud_ins_date, cud_lupd_user, cud_lupd_date
                        )
                 VALUES (prm_instcode, i.cgu_card_no, i.cgu_file_name,
                         i.cgu_remarks, 'N', 'E',
                         v_errmsg, 'G', prm_lupduser,
                         SYSDATE, prm_lupduser, SYSDATE
                        );
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
                         i.cgu_card_no, v_prodcode, 'GROUP DEBLOCK',
                         'INSERT', 'SUCCESS', prm_ipaddr,
                         'CMS_PAN_SPPRT', '', i.cgu_card_no_encr,
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
                         i.cgu_card_no, v_prodcode, 'GROUP DEBLOCK',
                         'INSERT', 'FAILURE', prm_ipaddr,
                         'CMS_PAN_SPPRT', '', i.cgu_card_no_encr,
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
         INSERT INTO PROCESS_AUDIT_LOG
                     (pal_card_no, pal_activity_type, pal_transaction_code,
                      pal_delv_chnl, pal_tran_amt, pal_source,
                      pal_success_flag, pal_ins_user, pal_ins_date,
                      pal_process_msg, pal_reason_desc, pal_remarks,
                      pal_spprt_type, pal_inst_code
                     )
              VALUES (i.cgu_card_no, v_remark, v_txn_code,
                      v_del_channel, 0, 'HOST',
                      v_succ_flag, prm_lupduser, SYSDATE,
                      v_errmsg, v_reasondesc, i.cgu_remarks,
                      'G', prm_instcode
                     );
      EXCEPTION
         WHEN OTHERS
         THEN
            --prm_errmsg := 'Pan Not Found in Master';
            UPDATE CMS_GROUP_UNBLOCK_TEMP
               SET CGU_PROCESS_FLAG = 'E',
                   CGU_PROCESS_MSG = 'Error while inserting into Audit log'
             WHERE ROWID = i.r;
      END;                                                 --<< LOOP I END >>
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


