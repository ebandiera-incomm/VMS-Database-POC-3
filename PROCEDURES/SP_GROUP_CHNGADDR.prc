CREATE OR REPLACE PROCEDURE VMSCMS.Sp_Group_Chngaddr (
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
   v_old_addr_code          CMS_APPL_PAN.cap_bill_addr%TYPE;
   exp_loop_reject_record   EXCEPTION;
   exp_main_reject_record   EXCEPTION;
   v_resoncode              CMS_SPPRT_REASONS.csr_spprt_rsncode%TYPE;
   v_prod_catg              CMS_APPL_PAN.cap_card_stat%TYPE;
   v_newaddrcode            NUMBER (10);
   v_txn_code               CMS_FUNC_MAST.cfm_txn_code%TYPE;
   v_txn_mode               CMS_FUNC_MAST.cfm_txn_mode%TYPE;
   v_del_channel            CMS_FUNC_MAST.cfm_delivery_channel%TYPE;
   v_txn_type               CMS_FUNC_MAST.cfm_txn_type%TYPE;
   v_reasondesc             CMS_SPPRT_REASONS.csr_reasondesc%TYPE;
   v_decr_pan    CMS_APPL_PAN.cap_pan_code_encr%TYPE;
   v_applcode                   CMS_APPL_PAN.cap_appl_code%TYPE;
   v_acctno                     CMS_APPL_PAN.cap_acct_no%TYPE;                  
   v_prodcode                   CMS_APPL_PAN.cap_prod_code%TYPE;
   v_cardstat                   CMS_APPL_PAN.cap_card_stat%TYPE;
   v_expry_date                CMS_APPL_PAN.cap_expry_date%TYPE;
   
   CURSOR c1
   IS
      SELECT cgt_card_no, cgt_mbr_numb, cgt_file_name, cgt_remarks,
             cgt_disp_name, cgt_addr1, cgt_addr2, cgt_city_name,
             cgt_state_switch, cgt_pin_code, cgt_cntry_code, cgt_phone_one,
             cgt_phone_two, cgt_process_flag, cgt_process_msg, cgt_lupd_date,
             cgt_inst_code, cgt_lupd_user, cgt_ins_date, cgt_ins_user,
             cgt_addr3, cgt_fax, cgt_cust_code, cgt_card_no_encr,
             ROWID r
        FROM CMS_GROUP_CHNGADDR_TEMP
       WHERE cgt_process_flag = 'N'
       AND cgt_inst_code= prm_instcode;
BEGIN                                                       --<< MAIN BEGIN >>
   prm_errmsg := 'OK';

------------------------------Sn check for pending records----------------------------
   BEGIN
      SELECT 1
        INTO v_rec_cnt
        FROM CMS_GROUP_CHNGADDR_TEMP
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
   
   ------------------------------Sn For Getting Transaction Code and Del Channel----------------------------   
   BEGIN
      SELECT cfm_txn_code, cfm_txn_mode, cfm_delivery_channel,
             cfm_txn_type
        INTO v_txn_code, v_txn_mode, v_del_channel,
             v_txn_type
        FROM CMS_FUNC_MAST
       WHERE cfm_func_code = 'ADDR' AND cfm_inst_code=prm_instcode;
   EXCEPTION
      WHEN NO_DATA_FOUND
      THEN
         v_errmsg :=
            'Support function card address change not defined in master';
         RAISE exp_loop_reject_record;
      WHEN OTHERS
      THEN
         v_errmsg :=
               'Error while selecting support function detail '
            || SUBSTR (SQLERRM, 1, 200);
         RAISE exp_loop_reject_record;
   END;
   ------------------------------En For Getting Transaction Code and Del Channel----------------------------
   
   ------------------------------Sn get reason code from support reason master----------------------------
            BEGIN
               SELECT csr_spprt_rsncode, csr_reasondesc
                 INTO v_resoncode, v_reasondesc
                 FROM CMS_SPPRT_REASONS
                WHERE csr_spprt_key = 'ADDR' AND ROWNUM < 2;
            EXCEPTION
               WHEN NO_DATA_FOUND
               THEN
                  v_errmsg := 'ADDR  reason code not present in master';
                  RAISE exp_loop_reject_record;
               WHEN OTHERS
               THEN
                  v_errmsg :=
                        'Error while selecting reason code from master'
                     || SUBSTR (SQLERRM, 1, 200);
                  RAISE exp_loop_reject_record;
            END;

            ------------------------------En get reason code from support reason master----------------------------   
            
   FOR i IN c1
   LOOP
      v_blocksavepoint := v_blocksavepoint + 1;
      SAVEPOINT v_blocksavepoint;
      v_errmsg := 'OK';

    --SN create decr pan
BEGIN
    v_decr_pan := Fn_dmaps_Main(i.cgt_card_no_encr);
EXCEPTION
WHEN OTHERS THEN
v_errmsg := 'Error while converting pan ' || SUBSTR(SQLERRM,1,200);
RAISE    exp_main_reject_record;
END;
--EN create decr pan
      
      
      BEGIN                                             -- << LOOP I BEGIN >>
         BEGIN
            SELECT cap_prod_catg, cap_bill_addr,CAP_APPL_CODE,CAP_ACCT_NO,CAP_PROD_CODE,cap_card_stat, cap_expry_date
              INTO v_prod_catg, v_old_addr_code,v_applcode, v_acctno, v_prodcode, v_cardstat, v_expry_date
              FROM CMS_APPL_PAN
             WHERE CAP_PAN_CODE = i.cgt_card_no
               AND cap_mbr_numb = i.cgt_mbr_numb
               AND cap_inst_code = prm_instcode;
         EXCEPTION
            WHEN NO_DATA_FOUND
            THEN
               v_errmsg := 'No product category dfined for the card';
               RAISE exp_main_reject_record;
            WHEN OTHERS
            THEN
               v_errmsg :=
                     'Error while getting records from table '
                  || SUBSTR (SQLERRM, 1, 200);
               RAISE exp_main_reject_record;
         END;
         
         IF v_cardstat <> '1'    --siva Mar 22 2011 card status check
         THEN
            prm_errmsg := 'Card status is not open, cannot do address change';
            RAISE exp_loop_reject_record;
         END IF;
         
         IF  TRUNC (v_expry_date) < TRUNC (SYSDATE)     --siva added on 25 mar 2011 for expiry card check
            THEN
                prm_errmsg :=  'Card ' || i.cgt_card_no || ' is already Expired ,cannot do address change';
                RAISE exp_loop_reject_record;
                --RETURN;
         END IF;
------------------------------ Sn get rrn----------------------------
         IF v_prod_catg = 'P'
         THEN
         NUll;
            /*BEGIN
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
                  AND cbp_profile_code = cpc_profile_code;
            EXCEPTION
               WHEN NO_DATA_FOUND
               THEN
                  v_errmsg := 'Currency not defined for the card';
                  RAISE exp_loop_reject_record;
            END;

            ------------------------------En get card currency--------------------------------

            ------------------------------ Sn call to procedure for prepaid----------------------------
            Sp_Change_Addr (prm_instcode,
                           i.cgt_card_no,
                           i.cgt_mbr_numb,
                           i.cgt_remarks,
                           v_resoncode,
                           v_rrn,
                           'offline',
                           v_stan,
                           TO_CHAR (SYSDATE, 'YYYYMMDD'),
                           TO_CHAR (SYSDATE, 'HH24:MI:SS'),
                           i.cgt_card_no,
                           i.cgt_file_name,
                           0,
                           NULL,
                           NULL,
                           NULL,
                           NULL,
                           v_card_curr,
                           NULL,                             --i.cgt_new_addr,
                           i.cgt_cust_code,
                           i.cgt_addr1,
                           i.cgt_addr2,
                           i.cgt_addr3,
                           i.cgt_pin_code,
                           i.cgt_phone_one,
                           i.cgt_phone_two,
                           i.cgt_cntry_code,
                           i.cgt_city_name,
                           i.cgt_state_switch,
                           i.cgt_fax,
                           'E',
                           prm_lupduser,
                           0,
                           v_authmsg,
                           v_newaddrcode,
                           v_errmsg
                          );

            IF v_errmsg <> 'OK'
            THEN
               v_errflag := 'E';
               RAISE exp_loop_reject_record;
            END IF;

            IF v_errmsg = 'OK' AND v_authmsg <> 'OK'
            THEN
               v_errflag := 'E';
               v_errmsg := v_authmsg;
            END IF;

            IF v_errmsg = 'OK' AND v_authmsg = 'OK'
            THEN
               v_errflag := 'S';
               v_errmsg := 'Successful';

               UPDATE CMS_GROUP_CHNGADDR_TEMP
                  SET cgt_process_flag = 'S',
                      cgt_process_msg = v_errmsg
                WHERE ROWID = i.r;
            END IF;

            INSERT INTO CMS_ADDRCHNG_DETAIL
                        (crd_inst_code, crd_card_no, crd_file_name,
                         crd_remarks, crd_msg24_flag, crd_old_addr,
                         crd_new_addr, crd_process_flag, crd_process_msg,
                         crd_process_mode, crd_ins_user, crd_ins_date,
                         crd_lupd_user, crd_lupd_date
                        )
                 VALUES (prm_instcode, i.cgt_card_no, i.cgt_file_name,
                         i.cgt_remarks, 'N', v_old_addr_code,
                         v_newaddrcode, v_errflag, v_errmsg,
                         'G', prm_lupduser, SYSDATE,
                         prm_lupduser, SYSDATE
                        );*/
         ------------------------------ En call to procedure for prepaid----------------------------
         ELSIF v_prod_catg in('D','A')
         THEN
            ------------------------------Sn get reason code from support reason master----------------------------
            BEGIN
               SELECT csr_spprt_rsncode
                 INTO v_resoncode
                 FROM CMS_SPPRT_REASONS
                WHERE csr_spprt_key = 'ADDR' AND ROWNUM < 2;
            EXCEPTION
               WHEN NO_DATA_FOUND
               THEN
                  v_errmsg := 'Block  reason code not present in master';
                  RAISE exp_loop_reject_record;
               WHEN OTHERS
               THEN
                  v_errmsg :=
                        'Error while selecting reason code from master'
                     || SUBSTR (SQLERRM, 1, 200);
                  RAISE exp_loop_reject_record;
            END;

            ------------------------------En get reason code from support reason master----------------------------
            Sp_Change_Addr_Debit (prm_instcode,
                                  --i.cgt_card_no
                                  v_decr_pan,
                                 -- Fn_dmaps_Main(i.cgt_card_no_encr),
                                  i.cgt_mbr_numb,
                                  i.cgt_remarks,
                                  NULL,                      --i.cgt_new_addr,
                                  v_resoncode,
                                  i.cgt_cust_code,
                                  i.cgt_addr1,
                                  i.cgt_addr2,
                                  i.cgt_addr3,
                                  i.cgt_pin_code,
                                  i.cgt_phone_one,
                                  i.cgt_phone_two,
                                  i.cgt_cntry_code,
                                  i.cgt_city_name,
                                  i.cgt_state_switch,
                                  i.cgt_fax,
                                  'E',
                                  prm_lupduser,
                                  0,
                                  v_newaddrcode,
                                  v_errmsg
                                 );

            IF v_errmsg <> 'OK'
            THEN
            v_errflag := 'E';
               RAISE exp_loop_reject_record;
            END IF;

            IF v_errmsg = 'OK'
            THEN
               v_errflag := 'S';
               v_errmsg := 'Successful';

               UPDATE CMS_GROUP_CHNGADDR_TEMP
                  SET cgt_process_flag = 'S',
                      cgt_process_msg = v_errmsg
                WHERE ROWID = i.r;
            END IF;

            INSERT INTO CMS_ADDRCHNG_DETAIL
                        (crd_inst_code, crd_card_no, crd_file_name,
                         crd_remarks, crd_msg24_flag, crd_old_addr,
                         crd_new_addr, crd_process_flag, crd_process_msg,
                         crd_process_mode, crd_ins_user, crd_ins_date,
                         crd_lupd_user, crd_lupd_date,crd_card_no_encr
                        )
                 VALUES (prm_instcode, i.cgt_card_no, i.cgt_file_name,
                         i.cgt_remarks, 'N', v_old_addr_code,
                         v_newaddrcode, v_errflag, v_errmsg,
                         'G', prm_lupduser, SYSDATE,
                         prm_lupduser, SYSDATE, i.cgt_card_no_encr
                        );
         END IF;
      EXCEPTION                                       -- << LOOP I EXCEPTION>>
         WHEN exp_loop_reject_record
         THEN
            ROLLBACK TO v_blocksavepoint;

            UPDATE CMS_GROUP_CHNGADDR_TEMP
               SET cgt_process_flag = 'E',
                   cgt_process_msg = v_errmsg
             WHERE ROWID = i.r;

            INSERT INTO CMS_ADDRCHNG_DETAIL
                        (crd_inst_code, crd_card_no, crd_file_name,
                         crd_remarks, crd_msg24_flag, crd_old_addr,
                         crd_new_addr, crd_process_flag, crd_process_msg,
                         crd_process_mode, crd_ins_user, crd_ins_date,
                         crd_lupd_user, crd_lupd_date,crd_card_no_encr
                        )
                 VALUES (prm_instcode, i.cgt_card_no, i.cgt_file_name,
                         i.cgt_remarks, 'N', v_old_addr_code,
                         v_newaddrcode, v_errflag, v_errmsg,
                         'G', prm_lupduser, SYSDATE,
                         prm_lupduser, SYSDATE,i.cgt_card_no_encr
                        );
         WHEN OTHERS
         THEN
            ROLLBACK TO v_blocksavepoint;

            UPDATE CMS_GROUP_CHNGADDR_TEMP
               SET cgt_process_flag = 'E',
                   cgt_process_msg = v_errmsg
             WHERE ROWID = i.r;

            INSERT INTO CMS_ADDRCHNG_DETAIL
                        (crd_inst_code, crd_card_no, crd_file_name,
                         crd_remarks, crd_msg24_flag, crd_old_addr,
                         crd_new_addr, crd_process_flag, crd_process_msg,
                         crd_process_mode, crd_ins_user, crd_ins_date,
                         crd_lupd_user, crd_lupd_date,crd_card_no_encr
                        )
                 VALUES (prm_instcode, i.cgt_card_no, i.cgt_file_name,
                         i.cgt_remarks, 'N', v_old_addr_code,
                         v_newaddrcode, v_errflag, v_errmsg,
                         'G', prm_lupduser, SYSDATE,
                         prm_lupduser, SYSDATE,i.cgt_card_no_encr
                        );
      END;
      
                    --siva mar 24 2011
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
                         i.cgt_card_no, v_prodcode, 'GROUP ADDRESS CHANGE USING CARD',
                         'INSERT', 'SUCCESS', prm_ipaddr,
                         'CMS_PAN_SPPRT', '', i.cgt_card_no_encr,
                         prm_lupduser, SYSDATE
                        );
         EXCEPTION
            --excp of begin 3
            WHEN OTHERS
            THEN
               prm_errmsg :=
                     'Error while inserting records for audit log process'
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
                         i.cgt_card_no, v_prodcode, 'GROUP ADDRESS CHANGE USING CARD',
                         'INSERT', 'FAILURE', prm_ipaddr,
                         'CMS_PAN_SPPRT', '', i.cgt_card_no_encr,
                         prm_lupduser, SYSDATE
                        );
         EXCEPTION
            --excp of begin 3
            WHEN OTHERS
            THEN
               prm_errmsg :=
                     'Error while inserting records for audit log process'
                  || SUBSTR (SQLERRM, 1, 200);
               RETURN;
         END;
      --end insert audit table
      END IF;

      --end for failure status record
          --siva end mar 24 2011

      BEGIN
         INSERT INTO PROCESS_AUDIT_LOG
                     (pal_card_no, pal_activity_type, pal_transaction_code,
                      pal_delv_chnl, pal_tran_amt, pal_source,
                      pal_success_flag, pal_ins_user, pal_ins_date,
                      pal_process_msg, pal_reason_desc, pal_remarks,
                      pal_spprt_type,pal_card_no_encr
                     )
              VALUES (i.cgt_card_no, 'Group Address Change', v_txn_code,
                      v_del_channel, 0, 'HOST',
                      v_errflag, prm_lupduser, SYSDATE,
                      v_errmsg, v_reasondesc, i.cgt_remarks,
                      'G',i.cgt_card_no_encr
                     );
      EXCEPTION
         WHEN OTHERS
         THEN
            --prm_errmsg := 'Pan Not Found in Master';
            UPDATE CMS_GROUP_CHNGADDR_TEMP
               SET cgt_process_flag = 'E',
                   cgt_process_msg = 'Error while inserting into Audit log'
             WHERE ROWID = i.r;
      END;                                                  --<< LOOP I END >>
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
SHOW ERRORS

