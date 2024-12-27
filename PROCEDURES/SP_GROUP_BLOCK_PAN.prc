CREATE OR REPLACE PROCEDURE VMSCMS.Sp_Group_Block_Pan (
   prm_instcode   IN       NUMBER,
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
v_decr_pan    CMS_APPL_PAN.cap_pan_code_encr%TYPE;
   CURSOR c1
   IS
      SELECT cgt_card_no, cgt_file_name, cgt_remarks, cgt_process_flag,
             cgt_process_msg, cgt_mbr_numb,cgt_card_no_encr,
              ROWID r
        FROM CMS_GROUP_BLOCK_TEMP
       WHERE cgt_process_flag = 'N';
       
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
        AND csr_spprt_key= prm_instcode;
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

      
 --SN create decr pan
BEGIN
    v_decr_pan := Fn_dmaps_Main(i.cgt_card_no);
EXCEPTION
WHEN OTHERS THEN
v_errmsg := 'Error while converting pan ' || SUBSTR(SQLERRM,1,200);
RAISE    exp_main_reject_record;
END;
--EN create decr pan
  
  
  
      BEGIN                                             -- << LOOP I BEGIN >>
         BEGIN
            SELECT cap_prod_catg
              INTO v_prod_catg
              FROM CMS_APPL_PAN
             WHERE cap_pan_code = i.cgt_card_no
               AND cap_mbr_numb = i.cgt_mbr_numb
               AND cap_inst_code=prm_instcode;
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
               RAISE exp_loop_reject_record;
         END;
-- 
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
-- 
-- 
--             ------------------------------ Sn call to procedure----------------------------
            Sp_Block_Pan_prepaid (prm_instcode,
                          v_rrn,
                          'offline',
                          v_stan,
                          TO_CHAR (SYSDATE, 'YYYYMMDD'),
                          TO_CHAR (SYSDATE, 'HH24:MI:SS'),
                          --i.cgt_card_no
                          v_decr_pan,
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
                         cbd_ins_date, cbd_lupd_user, cbd_lupd_date,cbd_card_no_encr
                        )
                 VALUES (prm_instcode, i.cgt_card_no, i.cgt_file_name,
                         i.cgt_remarks, 'N', v_errflag,
                         v_errmsg, 'G', prm_lupduser,
                         SYSDATE, prm_lupduser, SYSDATE,i.cgt_card_no_encr
                        );
         ------------------------------ En call to procedure----------------------------
         ELSIF v_prod_catg = 'D'
         THEN
            ------------------------------Sn get reason code from support reason master----------------------------
            BEGIN
               SELECT csr_spprt_rsncode
                 INTO v_resoncode
                 FROM CMS_SPPRT_REASONS
                WHERE csr_spprt_key = 'BLOCK'
                AND csr_inst_code= prm_instcode
                AND ROWNUM < 2;
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
-- 
--             ------------------------------En get reason code from support reason master----------------------------
            Sp_Block_Pan_Debit (prm_instcode,
                               -- i.cgt_card_no
                               v_decr_pan,
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
                             cbd_ins_date, cbd_lupd_user, cbd_lupd_date,cbd_card_no_encr
                            )
                     VALUES (prm_instcode, i.cgt_card_no, i.cgt_file_name,
                             i.cgt_remarks, 'N', v_errflag,
                             v_errmsg, 'G', prm_lupduser,
                             SYSDATE, prm_lupduser, SYSDATE,i.cgt_card_no_encr
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
                             cbd_ins_date, cbd_lupd_user, cbd_lupd_date,cbd_card_no_encr
                            )
                     VALUES (prm_instcode, i.cgt_card_no, i.cgt_file_name,
                             i.cgt_remarks, 'N', 'E',
                             v_errmsg, 'G', prm_lupduser,
                             SYSDATE, prm_lupduser, SYSDATE,i.cgt_card_no_encr
                            );
             EXCEPTION
             WHEN OTHERS THEN
                v_errmsg :='Error while updating process detail in block detail segment ' || substr(sqlerrm,1,150);
                RETURN;
             
             END;
         WHEN OTHERS
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
                             cbd_ins_date, cbd_lupd_user, cbd_lupd_date,cbd_card_no_encr
                            )
                     VALUES (prm_instcode, i.cgt_card_no, i.cgt_file_name,
                             i.cgt_remarks, 'N', 'E',
                             v_errmsg, 'G', prm_lupduser,
                             SYSDATE, prm_lupduser, SYSDATE,i.cgt_card_no_encr
                            );
             EXCEPTION
             WHEN OTHERS THEN
                v_errmsg :='Error while updating process detail in block detail segment ' || substr(sqlerrm,1,150);
                RETURN;
             
             END;
     END;                                                                     --<< LOOP I END >>
      
      BEGIN
         INSERT INTO PROCESS_AUDIT_LOG
                     (pal_card_no, pal_activity_type, pal_transaction_code,
                      pal_delv_chnl, pal_tran_amt, pal_source,
                      pal_success_flag, pal_ins_user, pal_ins_date,
                      pal_process_msg, pal_reason_desc, pal_remarks,
                      pal_spprt_type,pal_card_no_encr
                     )
              VALUES (i.cgt_card_no, v_remark, v_txn_code,
                      v_del_channel, 0, 'HOST',
                      v_succ_flag, prm_lupduser, SYSDATE,
                      v_errmsg,v_reasondesc, i.cgt_remarks,'G',i.cgt_card_no_encr
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


