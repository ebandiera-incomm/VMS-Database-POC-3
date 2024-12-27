CREATE OR REPLACE PROCEDURE VMSCMS.sp_grp_upd_limits
  (
    prm_instcode IN VARCHAR2,
     prm_ipaddr   IN VARCHAR2,
    prm_lupduser IN VARCHAR2,
    prm_errmsg OUT VARCHAR2 )
AS
  v_mbrnumb VARCHAR2(3);
  v_remark CMS_PAN_SPPRT.cps_func_remark%TYPE;
  v_cap_cafgen_flag CMS_APPL_PAN.cap_cafgen_flag%TYPE;
  v_prod_catg CMS_APPL_PAN.cap_prod_catg%TYPE;
  v_cardstat CMS_APPL_PAN.cap_card_stat%TYPE;
  v_cap_atmOnline_lmt CMS_APPL_PAN.CAP_ATM_ONLINE_LIMIT%TYPE;
  v_cap_posOnline_lmt CMS_APPL_PAN.CAP_POS_ONLINE_LIMIT%TYPE;
  v_errmsg VARCHAR2(500) ;
  v_resoncode CMS_SPPRT_REASONS.csr_spprt_rsncode%TYPE;
  v_reasondesc CMS_SPPRT_REASONS.CSR_REASONDESC%TYPE;
  v_applcode                   CMS_APPL_PAN.cap_appl_code%TYPE;
  v_acctno                     CMS_APPL_PAN.cap_acct_no%TYPE;                  
  v_prodcode                   CMS_APPL_PAN.cap_prod_code%TYPE;
  v_updlimitsavepoint    NUMBER (9) DEFAULT 99;
  v_errflag              CHAR (1);
  v_txn_code             VARCHAR2 (2);
  v_txn_type             VARCHAR2 (2);
  v_txn_mode             VARCHAR2 (2);
  v_del_channel          VARCHAR2 (2);
  v_succ_flag            VARCHAR2 (1);
  v_expry_date                CMS_APPL_PAN.cap_expry_date%TYPE;
  v_decr_pan	CMS_APPL_PAN.cap_pan_code_encr%TYPE;
  EXP_LOOP_REJECT_RECORD EXCEPTION;
    

    
  CURSOR c1
  IS
    SELECT ROWID AS ROW_ID,
      CUL_CARD_NO,
      CUL_FILE_NAME,
      CUL_REMARKS,
      CUL_INS_DATE,
      --CUL_INST_CODE,
      CUL_MBR_NUMB,
      CUL_ATM_ONLINE_LIMIT,
      CUL_POS_ONLINE_LIMIT,
      CUL_ATM_OFFLINE_LIMIT,
      CUL_POS_OFFLINE_LIMIT,
      CUL_UPDCARD_LIMIT_PARAM1,
      CUL_UPDCARD_LIMIT_PARAM2,
      CUL_CARD_NO_encr
    FROM CMS_GROUP_LIMITUPDATE_TEMP
    WHERE CUL_PROCESS_FLAG='N'
    AND cul_inst_code= prm_instcode;
BEGIN --<< main begin start >>--
  prm_errmsg:='OK';
  ------------------------------ Sn get Function Master----------------------------
  BEGIN
    SELECT cfm_txn_code,
      cfm_txn_mode,
      cfm_delivery_channel,
      cfm_txn_type
    INTO v_txn_code,
      v_txn_mode,
      v_del_channel,
      v_txn_type
    FROM CMS_FUNC_MAST
    WHERE cfm_func_code = 'LIMT'
    AND cfm_inst_code   = prm_instcode;
  EXCEPTION
  WHEN OTHERS THEN
    prm_errmsg :='Function Master Not Defined ' || SUBSTR (SQLERRM, 1, 200);
    RETURN;
  END;
  ------------------------------ En get Function Master----------------------------
  ------------------------------Sn get reason code from support reason master--------------------
  BEGIN
    SELECT csr_spprt_rsncode,
      CSR_REASONDESC
    INTO v_resoncode,
      v_reasondesc
    FROM CMS_SPPRT_REASONS
    WHERE csr_spprt_key = 'LIMT'
    AND csr_inst_code   =prm_instcode
    AND ROWNUM          < 2;
  EXCEPTION
  WHEN VALUE_ERROR THEN
    prm_errmsg := 'Limit update reason code not present in master ';
    --RAISE exp_loop_reject_record;
    RETURN;
  WHEN NO_DATA_FOUND THEN
    prm_errmsg := 'Limit update reason code not present in master';
    --RAISE exp_loop_reject_record;
    RETURN;
  WHEN OTHERS THEN
    prm_errmsg := 'Error while selecting reason code from master' || SUBSTR (SQLERRM, 1, 200);
    --RAISE exp_loop_reject_record;
    RETURN;
  END;
  ------------------------------En get reason code from support reason master--------------------
  FOR x IN c1
  LOOP
    BEGIN --<< loop main begin start >>--
      v_errmsg            := 'OK';
      v_updlimitsavepoint := v_updlimitsavepoint + 1 ;
      SAVEPOINT v_updlimitsavepoint ;
      prm_errmsg  := 'OK';
      v_prod_catg := NULL;
      v_cardstat  := NULL;
      
     
--SN create decr pan
BEGIN
	v_decr_pan := Fn_dmaps_Main(x.CUL_CARD_NO_ENCR);
EXCEPTION
WHEN OTHERS THEN
v_errmsg := 'Error while converting pan ' || SUBSTR(SQLERRM,1,200);
RAISE	exp_loop_reject_record;
END;
--EN create decr pan


      --------start to find prodct category and card status--------------
      BEGIN
        SELECT cap_prod_catg,
          cap_card_stat,CAP_APPL_CODE,CAP_ACCT_NO,CAP_PROD_CODE, CAP_EXPRY_DATE
         INTO v_prod_catg,
          v_cardstat,v_applcode, v_acctno, v_prodcode, v_expry_date
          FROM CMS_APPL_PAN
        WHERE cap_pan_code = x.cul_card_no
        AND cap_mbr_numb   = x.cul_mbr_numb
        AND cap_inst_code  = prm_instcode;
        IF v_prod_catg    IS NULL OR v_cardstat IS NULL THEN
          v_errmsg        := 'Product category or card status is not defined for the card';
          RAISE exp_loop_reject_record;
        END IF;
      EXCEPTION
      WHEN NO_DATA_FOUND THEN
        v_errmsg := 'Card number not found in master';
        RAISE exp_loop_reject_record;
      WHEN OTHERS THEN
        v_errmsg :='Error while getting records from appl pan table '|| SUBSTR (SQLERRM, 1, 200);
        RAISE exp_loop_reject_record;
      END;
      --------end to find prodct category and card status--------------
      
      IF v_cardstat <> '1' THEN 
        v_errmsg   :='Card is not open to update the limits';
        RAISE exp_loop_reject_record;
      END IF;
      
      IF  TRUNC (v_expry_date) < TRUNC (SYSDATE)     --siva added on 25 mar 2011 for expiry card check
            THEN
                prm_errmsg :=  'Card ' || x.cul_card_no || ' is already Expired ,cannot update the limits';
                RAISE exp_loop_reject_record;
                --RETURN;
         END IF;
         
      IF v_prod_catg = 'P' THEN
        ------start limit update for prepaid
        NULL;
        ------end limit update for prepaid
      ELSIF v_prod_catg in('D','A') THEN
        --------start limit update for debit-------
        sp_update_limits_debit( 
                                prm_instcode,
                              --  x.CUL_CARD_NO
                              v_decr_pan,
                                x.CUL_MBR_NUMB,
                                x.CUL_REMARKS,
                                v_resoncode,
                                x.CUL_ATM_OFFLINE_LIMIT,
                                x.CUL_ATM_ONLINE_LIMIT,
                                x.CUL_POS_OFFLINE_LIMIT,
                                x.CUL_POS_ONLINE_LIMIT,
                                x.CUL_UPDCARD_LIMIT_PARAM1,
                                x.CUL_UPDCARD_LIMIT_PARAM2 ,
                                'U',
                                prm_lupduser,
                                v_errmsg );
        IF v_errmsg   <> 'OK' THEN
          v_succ_flag := 'E';
          RAISE exp_loop_reject_record;
        ELSIF v_errmsg = 'OK' THEN
          v_errflag   := 'S';
          v_succ_flag := 'S';
          v_errmsg    := 'Successful';
          BEGIN
            UPDATE CMS_GROUP_LIMITUPDATE_TEMP
            SET cul_process_flag='S',
              cul_process_msg   ='Successful'
            WHERE rowid         =x.ROW_ID;
          EXCEPTION
          WHEN OTHERS THEN
            v_errmsg := 'Error while updating record in grp limit update temp table' || SUBSTR(sqlerrm,1,200);
            RAISE exp_loop_reject_record;
          END;
          ----------------Start create successfull reocords in Detail table-------------------------
          BEGIN
            INSERT
            INTO CMS_UPD_LIMIT_DETAIL
              (
                cud_inst_code ,
                cud_card_no ,
                cud_file_name ,
                cud_remarks ,
                cud_msg24_flag ,
                cud_process_flag,
                cud_process_msg ,
                cud_process_mode,
                cud_ins_user ,
                cud_ins_date ,
                cud_lupd_user ,
                cud_lupd_date,
                cud_card_no_encr
              )
              VALUES
              (
                prm_instcode,
                x.CUL_CARD_NO,
                x.CUL_FILE_NAME,
                x.CUL_REMARKS,
                'N',
                v_succ_flag,
                v_errmsg,
                'G',
                prm_lupduser,
                x.CUL_INS_DATE,
                prm_lupduser,
                x.CUL_INS_DATE,
                x.CUL_CARD_NO_encr
              );
          EXCEPTION
          WHEN OTHERS THEN
            v_errmsg := 'ERROR WHILE LOGGING SUCCESSFUL RECORDS ' || SUBSTR
            (
              sqlerrm,1,150
            )
            ;
            RAISE exp_loop_reject_record;
          END;
          ----------------start create successfull reocords in Detail table-------------------------
          ------------------------------------end limit update for debit-----------------------------
        END IF;
      END IF;
      EXCEPTION --<< loop exception >>--
      WHEN exp_loop_reject_record THEN
        ROLLBACK TO v_updlimitsavepoint;
        v_succ_flag := 'E';
        UPDATE CMS_GROUP_LIMITUPDATE_TEMP
        SET cul_process_flag='E',
          cul_process_msg   =v_errmsg
        WHERE rowid         =x.ROW_ID;
        INSERT
        INTO CMS_UPD_LIMIT_DETAIL
          (
            cud_inst_code ,
            cud_card_no ,
            cud_file_name ,
            cud_remarks ,
            cud_msg24_flag ,
            cud_process_flag,
            cud_process_msg ,
            cud_process_mode,
            cud_ins_user ,
            cud_ins_date ,
            cud_lupd_user ,
            cud_lupd_date,
            cud_card_no_encr
          )
          VALUES
          (
            prm_instcode,
            x.CUL_CARD_NO,
            x.CUL_FILE_NAME,
            x.CUL_REMARKS,
            'N',
            v_succ_flag,
            v_errmsg,
            'G',
            prm_lupduser,
            x.CUL_INS_DATE,
            prm_lupduser,
            x.CUL_INS_DATE,
             x.CUL_CARD_NO_encr
          );
      WHEN OTHERS THEN
        ROLLBACK TO v_updlimitsavepoint;
        v_succ_flag := 'E';
        v_errmsg := 'Error while processing update limit ' || substr(sqlerrm,1,200);
        UPDATE CMS_GROUP_LIMITUPDATE_TEMP
        SET cul_process_flag='E',
          cul_process_msg   =v_errmsg
        WHERE rowid         =x.ROW_ID;
        INSERT
        INTO CMS_UPD_LIMIT_DETAIL
          (
            cud_inst_code ,
            cud_card_no ,
            cud_file_name ,
            cud_remarks ,
            cud_msg24_flag ,
            cud_process_flag,
            cud_process_msg ,
            cud_process_mode,
            cud_ins_user ,
            cud_ins_date ,
            cud_lupd_user ,
            cud_lupd_date,
            cud_card_no_encr
          )
          VALUES
          (
            prm_instcode,
            x.CUL_CARD_NO,
            x.CUL_FILE_NAME,
            x.CUL_REMARKS,
            'N',
            v_succ_flag,
            v_errmsg,
            'G',
            prm_lupduser,
            x.CUL_INS_DATE,
            prm_lupduser,
            x.CUL_INS_DATE,
               x.CUL_CARD_NO_encr
          );
      END; --<< loop main begin end >>--
      
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
                         x.CUL_CARD_NO, v_prodcode, 'GROUP UPDATE LIMITS',
                         'INSERT', 'SUCCESS', prm_ipaddr,
                         'CMS_PAN_SPPRT', '', x.CUL_CARD_NO_ENCR,
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
                         x.CUL_CARD_NO, v_prodcode, 'GROUP UPDATE LIMITS',
                         'INSERT', 'FAILURE', prm_ipaddr,
                         'CMS_PAN_SPPRT', '', x.CUL_CARD_NO_ENCR,
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
      -------------------start inserting record in audit log----------------
      BEGIN
        INSERT
        INTO PROCESS_AUDIT_LOG
          (
            pal_card_no,
            pal_activity_type,
            pal_transaction_code,
            pal_delv_chnl,
            pal_tran_amt,
            pal_source,
            pal_success_flag,
            pal_ins_user,
            pal_ins_date,
            pal_process_msg,
            pal_reason_desc,
            pal_remarks,
            pal_spprt_type,
            pal_inst_code,
            pal_card_no_encr
          )
          VALUES
          (
            x.cul_card_no,
            'Update limit',
            v_txn_code,
            v_del_channel,
            0,
            'HOST',
            v_succ_flag,
            prm_lupduser,
            SYSDATE,
            v_errmsg,
            v_reasondesc,
            x.cul_remarks,
            'G',
            prm_instcode,
               x.cul_card_no_encr
          );
      EXCEPTION
      WHEN OTHERS THEN
        UPDATE CMS_GROUP_ACCTDELINK_TEMP
        SET cgd_process_flag = 'E',
          cgd_process_msg    = 'Error while inserting into Audit log'
        WHERE ROWID          = x.ROW_ID;
      END;
      ---------------------end inserting record in audit log-----------------
    END LOOP;
    prm_errmsg := 'OK';
  EXCEPTION --<< main exception >>--
  WHEN OTHERS THEN
    prm_errmsg := 'Main Excp from update limit-- ' || SUBSTR(SQLERRM,1,200);
  END; --<< main begin end >>--
/
SHOW ERRORS

