CREATE OR REPLACE PROCEDURE VMSCMS.Sp_Grp_Acctlink (
   prm_instcode   IN       NUMBER,
   prm_ipaddr     IN       VARCHAR2,
   prm_lupduser   IN       NUMBER,
   prm_errmsg     OUT      VARCHAR2
)
/*************************************************
     * VERSION             :  1.0
     * Created Date        :  27/MAY/2010
     * Created By          :  Chinmaya Behera
     * PURPOSE             :  Group Acctlink Card , only if ard is open
     * Modified By:        :  
     * Modified Date       :
   ***********************************************/
AS
   v_remark                 CMS_PAN_SPPRT.cps_func_remark%TYPE;
   v_cardstat               CMS_APPL_PAN.cap_card_stat%TYPE;
   v_resoncode              CMS_SPPRT_REASONS.csr_spprt_rsncode%TYPE;
   v_cardstatdesc           VARCHAR2 (10);
   v_mbrnumb                VARCHAR2 (3)                        DEFAULT '000';
   v_rrn                    VARCHAR2 (12);
   v_stan                   VARCHAR2 (12);
   v_authmsg                VARCHAR2 (300);
   v_card_curr              VARCHAR2 (3);
   v_errmsg                 VARCHAR2 (300);
   v_linksavepoint          NUMBER (9)                             DEFAULT 0;
   v_errflag                CHAR (1);
   v_txn_code               VARCHAR2 (2);
   v_txn_type               VARCHAR2 (2);
   v_txn_mode               VARCHAR2 (2);
   v_del_channel            VARCHAR2 (2);
   v_succ_flag              VARCHAR2 (1);
   v_prod_catg              CMS_APPL_PAN.cap_prod_catg%TYPE;
   v_reasondesc             CMS_SPPRT_REASONS.CSR_REASONDESC%TYPE;
   v_applcode                   CMS_APPL_PAN.cap_appl_code%TYPE;
   v_acctno                     CMS_APPL_PAN.cap_acct_no%TYPE;                  
   v_prodcode                   CMS_APPL_PAN.cap_prod_code%TYPE;
   exp_loop_reject_record   EXCEPTION;
     v_decr_pan    CMS_APPL_PAN.cap_pan_code_encr%TYPE;
     
      CURSOR c1
IS
    SELECT  cga_card_no,        
        cga_new_acct_no,
        cga_remarks,
        cga_process_flag,
        cga_file_name ,
        cga_mbr_numb,cga_card_no_encr,
        rowid
    FROM    CMS_GROUP_ACCTLINK_TEMP
    WHERE    cga_process_flag = 'N'
  AND cga_inst_code= prm_instcode;
BEGIN            --<< MAIN BEGIN >>
 prm_errmsg := 'OK';
------------------------------ Sn get Function Master----------------------------
   BEGIN
        SELECT cfm_txn_code, 
               cfm_txn_mode, 
               cfm_delivery_channel, 
               cfm_txn_type
        INTO    v_txn_code, 
            v_txn_mode, 
            v_del_channel, 
            v_txn_type
        FROM    CMS_FUNC_MAST
        WHERE cfm_func_code = 'LINK'
        AND   cfm_inst_code = prm_instcode;
   EXCEPTION
      WHEN OTHERS
      THEN
         prm_errmsg :=
                   'Function Master Not Defined for link' || SUBSTR (SQLERRM, 1, 200);
         --RAISE exp_loop_reject_record;
         RETURN;
   END;
   ------------------------------ En get Function Master----------------------------
   ------------------------------Sn get reason code from support reason master--------------------
    BEGIN
      SELECT csr_spprt_rsncode,CSR_REASONDESC
        INTO v_resoncode,v_reasondesc
        FROM CMS_SPPRT_REASONS
       WHERE csr_spprt_key = 'LINK' 
       AND   ROWNUM < 2
       AND   csr_inst_code = prm_instcode;
   EXCEPTION
      WHEN VALUE_ERROR
      THEN
         prm_errmsg := 'Link  reason code not present in master ';
         RETURN;
      WHEN NO_DATA_FOUND
      THEN
         prm_errmsg := 'Link  reason code not present in master';
         RETURN;
      WHEN OTHERS
      THEN
         prm_errmsg :=
               'Error while selecting reason code from master'
            || SUBSTR (SQLERRM, 1, 200);
         RETURN;
   END;
   ------------------------------En get reason code from support reason master---------------------
  FOR x IN c1
   LOOP
      ------------------------Sn find the pan details Cursor loop Begin---------------------------------------
      BEGIN                                             -- << LOOP I BEGIN >>
         v_linksavepoint := v_linksavepoint + 1;
         SAVEPOINT v_linksavepoint;
         v_errmsg := 'OK';
     prm_errmsg := 'OK';
     v_prod_catg := null;
     v_cardstat  := null;
     --Sn find prodcatg
     BEGIN
        SELECT    cap_prod_catg,cap_card_stat,CAP_APPL_CODE,CAP_ACCT_NO,CAP_PROD_CODE
        INTO    v_prod_catg,v_cardstat,v_applcode, v_acctno, v_prodcode
        FROM    CMS_APPL_PAN
        WHERE    cap_pan_code  = x.cga_card_no 
        AND    cap_mbr_numb  = x.cga_mbr_numb
        AND     cap_inst_code = prm_instcode;
                IF v_prod_catg IS NULL OR v_cardstat IS NULL THEN
                   v_errmsg := 'Product category or card status is not defined for the card';
                          RAISE exp_loop_reject_record;
                
                END IF;
        
         EXCEPTION
            WHEN NO_DATA_FOUND
            THEN
               v_errmsg := 'Card number not found in master';
               RAISE exp_loop_reject_record;
            WHEN OTHERS
            THEN
               v_errmsg :=
                     'Error while getting records from table '
                  || SUBSTR (SQLERRM, 1, 200);
               RAISE exp_loop_reject_record;
         END;
    --En find prodcatg
    
    --Sn check card stat
        IF  v_cardstat <> '1' THEN
             v_errmsg := 'Card is not open, cannot be linked to other account';
             RAISE exp_loop_reject_record;
        END IF;
    --En check card stat
  
 --SN create decr pan
BEGIN
    v_decr_pan := Fn_dmaps_Main(x.cga_card_no_encr);
EXCEPTION
WHEN OTHERS THEN
v_errmsg := 'Error while converting pan ' || SUBSTR(SQLERRM,1,200);
RAISE    exp_loop_reject_record;
END;
--EN create decr pan
  
  
        IF v_prod_catg = 'P' THEN
            null;
        ELSIF v_prod_catg in('D','A') THEN
            sp_acct_link_debit
                (
                prm_instcode,
                v_resoncode,
                prm_lupduser,
            --    x.cga_card_no
                v_decr_pan,
                x.cga_new_acct_no,
                x.cga_remarks,
                x.cga_mbr_numb,
                0,
                v_errmsg
                );
          IF v_errmsg <> 'OK'
               THEN
                  v_succ_flag := 'E';
                  RAISE exp_loop_reject_record;
               ELSIF v_errmsg = 'OK'
               THEN
            v_errflag   := 'S';
            v_succ_flag := 'S';
            v_errmsg    := 'Successful';
            
            
            BEGIN
                UPDATE    CMS_GROUP_ACCTLINK_TEMP
                SET    cga_process_flag = 'S',
                    cga_process_msg = 'SUCCESSFULL'
                WHERE    ROWID = x.ROWID;
            EXCEPTION
                WHEN OTHERS THEN
                 v_errmsg := 'Error while updating record in temp table' || substr(sqlerrm,1,150);
                 RAISE exp_loop_reject_record;
            END;
               END IF;
        --SN CREATE SUCCESSFUL RECORDS
        -------------------------------
                BEGIN
                INSERT INTO CMS_ACCT_LINK_DETAIL (
                        cad_inst_code   ,
                        cad_card_no     ,
                        cad_newacct_no  ,
                        cad_file_name   ,
                        cad_remarks     ,
                        cad_msg24_flag  ,
                        cad_process_flag,
                        cad_process_msg ,
                        cad_process_mode,
                        cad_ins_user    ,
                        cad_ins_date    ,
                        cad_lupd_user   ,
                        cad_lupd_date,cad_card_no_encr   )
                       VALUES ( prm_instcode,
                           x.cga_card_no,
                           x.cga_new_acct_no,
                           x.cga_file_name,
                           x.cga_remarks,
                            'N',
                            'S',
                            'SUCCESSFUL',
                            'S',
                            prm_lupduser,
                            sysdate,
                            prm_lupduser,
                            sysdate,
                 x.cga_card_no_encr
                  );
                EXCEPTION
                WHEN OTHERS THEN
                 v_errmsg := 'ERROR WHILE LOGGING SUCCESSFUL RECORDS ' || substr(sqlerrm,1,150);
                 RAISE exp_loop_reject_record;
                END;
    
    
                -------------------------------
                --EN CREATE SUCCESSFUL RECORDS
                -------------------------------
    ELSE
             v_errmsg := 'Not a valid product category for account link';
                 RAISE exp_loop_reject_record;
    END IF;
    --end if;
    
    
    
    EXCEPTION                        --<< LOOP I EXCEPTION >>
     WHEN exp_loop_reject_record
         THEN
            ROLLBACK TO v_linksavepoint;
            v_succ_flag := 'E';
            UPDATE CMS_GROUP_ACCTLINK_TEMP
               SET cga_process_flag = 'E',
                   cga_process_msg = v_errmsg
             WHERE ROWID = x.ROWID;
            INSERT INTO CMS_ACCT_LINK_DETAIL (
                        cad_inst_code   ,
                        cad_card_no     ,
                        cad_newacct_no  ,
                        cad_file_name   ,
                        cad_remarks     ,
                        cad_msg24_flag  ,
                        cad_process_flag,
                        cad_process_msg ,
                        cad_process_mode,
                        cad_ins_user    ,
                        cad_ins_date    ,
                        cad_lupd_user   ,
                        cad_lupd_date , cad_card_no_encr  )
                       VALUES ( prm_instcode,
                           x.cga_card_no,
                           x.cga_new_acct_no,
                           x.cga_file_name,
                           x.cga_remarks,
                            'N',
                            'E',
                            v_errmsg,
                            'G',
                            prm_lupduser,
                            sysdate,
                            prm_lupduser,
                            sysdate, x.cga_card_no_encr
                  );
        
         WHEN OTHERS
         THEN
        ROLLBACK TO v_linksavepoint;
            v_succ_flag := 'E';
        v_errmsg := 'Error while processing group acct link ' || substr(sqlerrm,1,150);
               UPDATE CMS_GROUP_ACCTLINK_TEMP
               SET cga_process_flag = 'E',
                   cga_process_msg = v_errmsg
             WHERE ROWID = x.ROWID;
            INSERT INTO CMS_ACCT_LINK_DETAIL (
                        cad_inst_code   ,
                        cad_card_no     ,
                        cad_newacct_no  ,
                        cad_file_name   ,
                        cad_remarks     ,
                        cad_msg24_flag  ,
                        cad_process_flag,
                        cad_process_msg ,
                        cad_process_mode,
                        cad_ins_user    ,
                        cad_ins_date    ,
                        cad_lupd_user   ,
                        cad_lupd_date ,cad_card_no_encr  )
                       VALUES ( prm_instcode,
                           x.cga_card_no,
                           x.cga_new_acct_no,
                           x.cga_file_name,
                           x.cga_remarks,
                            'N',
                            'E',
                            v_errmsg,
                            'G',
                            prm_lupduser,
                            sysdate,
                            prm_lupduser,
                            sysdate, x.cga_card_no_encr
                        );
      END;                        --<< LOOP I END >>
      
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
                         x.cga_card_no, v_prodcode, 'GROUP ACCOUNT LINK',
                         'INSERT', 'SUCCESS', prm_ipaddr,
                         'CMS_PAN_SPPRT', '', x.cga_card_no_encr,
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
                         x.cga_card_no, v_prodcode, 'GROUP ACCOUNT LINK',
                         'INSERT', 'FAILURE', prm_ipaddr,
                         'CMS_PAN_SPPRT', '', x.cga_card_no_encr,
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
          --siva end mar 22 2011
    
      BEGIN
         INSERT INTO PROCESS_AUDIT_LOG
                     (pal_card_no, pal_activity_type, pal_transaction_code,
                      pal_delv_chnl, pal_tran_amt, pal_source,
                      pal_success_flag, pal_ins_user, pal_ins_date,
                      pal_process_msg, pal_reason_desc, pal_remarks,
                      pal_spprt_type,
                      pal_inst_code,pal_card_no_encr
                     )
              VALUES (x.cga_card_no, 'Group Link', v_txn_code,
                      v_del_channel, 0, 'HOST',
                      v_succ_flag, prm_lupduser, SYSDATE,
              v_errmsg, v_reasondesc, x.cga_remarks,
                      'G',
                       prm_instcode, x.cga_card_no_encr
                     );
      EXCEPTION
         WHEN OTHERS
         THEN
            --prm_errmsg := 'Pan Not Found in Master';
            UPDATE CMS_GROUP_HOTLIST_TEMP
               SET cgh_process_flag = 'E',
                   cgh_process_msg = 'Error while inserting into Audit log'
             WHERE ROWID = x.ROWID;
      END;
      END LOOP;
 prm_errmsg := 'OK';
 
EXCEPTION        --<< MAIN EXCEPTION >>
WHEN OTHERS
   THEN
      prm_errmsg := 'Main Excp from link acct  -- ' || substr(SQLERRM,1,200);
END;            --<< MAIN END>>
/


