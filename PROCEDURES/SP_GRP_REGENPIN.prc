CREATE OR REPLACE PROCEDURE VMSCMS.Sp_Grp_Regenpin
  (
    prm_instcode IN NUMBER,
    prm_ipaddr   IN VARCHAR2,
    prm_lupduser IN NUMBER,
    prm_errmsg OUT VARCHAR2 )
AS
  v_count          NUMBER (1);
  v_card_curr      VARCHAR2 (3);
  v_rec_cnt        NUMBER (9);
  v_errflag        VARCHAR2 (1);
  v_errmsg         VARCHAR2 (300) := 'OK';
  v_authmsg        VARCHAR2 (300);
  v_rrn            VARCHAR2 (12);
  v_stan           VARCHAR2 (12);
  v_resoncode      NUMBER (9);
  v_repinsavepoint NUMBER (9) DEFAULT 0;
 -- init_savepoint  NUMBER (9) DEFAULT 0;
  v_txn_code          VARCHAR2 (2);
  v_txn_type          VARCHAR2 (2);
  v_txn_mode      VARCHAR2 (2);
  v_del_channel   VARCHAR2 (2);
  v_succ_flag     VARCHAR2 (1);
  v_remark           CMS_PAN_SPPRT.cps_func_remark%TYPE;
  v_prod_catg       CMS_APPL_PAN.cap_card_stat%TYPE;
  v_acct_id       CMS_APPL_PAN.cap_acct_id%TYPE;
  v_oldpinoff       CMS_APPL_PAN.cap_pin_off%TYPE;
  v_pingen_date   CMS_APPL_PAN.cap_pingen_date%TYPE;
  v_reasondesc       CMS_SPPRT_REASONS.CSR_REASONDESC%TYPE;
  v_cardstat       CMS_APPL_PAN.cap_card_stat%TYPE;
  exp_loop_reject_record EXCEPTION;
  --exp_main_reject_record EXCEPTION;
   v_decr_pan    CMS_APPL_PAN.cap_pan_code_encr%TYPE;
   v_applcode                   CMS_APPL_PAN.cap_appl_code%TYPE;
   v_acctno                     CMS_APPL_PAN.cap_acct_no%TYPE;                  
   v_prodcode                   CMS_APPL_PAN.cap_prod_code%TYPE;

  CURSOR c1
  IS
    SELECT cgt_card_no,
      cgt_file_name,
      cgt_remarks,
      cgt_process_flag,
      cgt_process_msg,
      cgt_mbr_numb,cgt_card_no_encr,
      ROWID r
    FROM CMS_GROUP_REGENPIN_TEMP
    WHERE cgt_process_flag = 'N'
    AND cgt_inst_code= prm_instcode;
BEGIN                                                 --<< MAIN BEGIN >>
  prm_errmsg := 'OK';
  v_remark   := 'Group Repin';
  --Sn check for pending records
  BEGIN
    SELECT 1
    INTO v_rec_cnt
    FROM CMS_GROUP_REGENPIN_TEMP
    WHERE cgt_process_flag = 'N'
    AND cgt_inst_code= prm_instcode
    AND ROWNUM < 2;
  EXCEPTION
  WHEN NO_DATA_FOUND THEN
    prm_errmsg := 'No record found for card Regenpin processing';
    --RAISE exp_main_reject_record;
    RETURN;
  WHEN OTHERS THEN
    prm_errmsg := 'Error while getting records from table ' || SUBSTR (SQLERRM, 1, 200);
   -- RAISE exp_main_reject_record;
   RETURN;
  END;
  --En check for pending records
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
    WHERE cfm_func_code = 'REPIN'
    AND cfm_inst_code   = prm_instcode;
  EXCEPTION
  WHEN NO_DATA_FOUND THEN
         prm_errmsg := 'Function Master Not Defined for REPIN' ;
       RETURN;
  WHEN OTHERS THEN
    prm_errmsg := 'Function Master Not Defined ' || SUBSTR (SQLERRM, 1, 200);
    RETURN;
  END;
  ------------------------------ En get Function Master----------------------------
  ------------------------------------Sn create a record in pan spprt ----------------------------------
  ------Sn get reason code from support reason master------
  BEGIN
    SELECT csr_spprt_rsncode,
      CSR_REASONDESC
    INTO v_resoncode,
      v_reasondesc
    FROM CMS_SPPRT_REASONS
    WHERE csr_spprt_key = 'REPIN'
    AND ROWNUM          < 2
    AND csr_inst_code   = prm_instcode;
  EXCEPTION
  WHEN NO_DATA_FOUND THEN
    prm_errmsg := 'Repin reason code is not present in support master';
    --RAISE exp_main_reject_record;
    RETURN;
  WHEN OTHERS THEN
    prm_errmsg := 'Error while selecting reason code from support master' || SUBSTR (SQLERRM, 1, 200);
    --RAISE exp_main_reject_record;
    RETURN;
  END;
  ------En get reason code from support reason master------
  
  FOR i IN c1
  LOOP
    v_repinsavepoint := v_repinsavepoint + 1;
    SAVEPOINT v_repinsavepoint;
    v_errmsg    :='OK';
    v_prod_catg := NULL;
    v_cardstat  := NULL;
    
    /*
--SN create decr pan
BEGIN
    v_decr_pan := Fn_dmaps_Main(i.cgt_card_no);
    --v_decr_pan := Fn_dmaps_Main(i.cgt_card_no_encr);
EXCEPTION
WHEN OTHERS THEN
v_errmsg := 'Error while converting pan ' || SUBSTR(SQLERRM,1,200);
RAISE    exp_loop_reject_record;
END;
--EN create decr pan     */


    BEGIN                                                 --<< LOOP I BEGIN >>--
      ---------------------------------Sn Find product catg for the card---------------------
      BEGIN
        SELECT cap_prod_catg,
          cap_acct_id,
          cap_pin_off,
          cap_pingen_date,
          cap_card_stat,CAP_APPL_CODE,CAP_ACCT_NO,CAP_PROD_CODE
        INTO v_prod_catg,
          v_acct_id,
          v_oldpinoff,
          v_pingen_date,
          v_cardstat,v_applcode, v_acctno, v_prodcode
        FROM CMS_APPL_PAN
        WHERE cap_pan_code = i.cgt_card_no
        AND cap_mbr_numb   = i.cgt_mbr_numb
        AND cap_inst_code  = prm_instcode;
      EXCEPTION
      WHEN NO_DATA_FOUND THEN
        v_errmsg := 'No product category defined for the card';
        RAISE exp_loop_reject_record;
      WHEN OTHERS THEN
        v_errmsg := 'Error while getting records from table ' || SUBSTR (SQLERRM, 1, 200);
        RAISE exp_loop_reject_record;
      END;
      ---------------------------------En Find product catg for the card---------------------
      IF v_cardstat <>1 THEN
        v_errmsg   :='Card is not open to Regenerate Pin';
        RAISE exp_loop_reject_record;
      END IF;
      IF v_prod_catg = 'P' THEN
        NULL;
        /*-----------start repin for prepaid card------------------
        -- Sn get rrn
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
        prm_errmsg := v_errmsg;
        RETURN;
        END;
        -- En get rrn
        -- Sn get STAN
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
        prm_errmsg := v_errmsg;
        RETURN;
        END;
        --En get STAN
        ----Sn get card currency ----------------------------
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
        --En get card currency--------------------------------
        -- Sn call to procedure
        Sp_Regenpin_Pcms (prm_instcode,
        v_rrn,
        'offline',
        v_stan,
        TO_CHAR (SYSDATE, 'YYYYMMDD'),
        TO_CHAR (SYSDATE, 'HH24:MI:SS'),
        i.cgt_card_no,
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
        v_succ_flag := 'E';
        v_errmsg := v_authmsg;
        END IF;
        IF v_errmsg = 'OK' AND v_authmsg = 'OK'
        THEN
        v_errflag := 'S';
        v_errmsg := 'Successful';
        v_succ_flag := 'S';
        UPDATE CMS_GROUP_REGENPIN_TEMP
        SET cgt_process_flag = 'S',
        cgt_process_msg = v_errmsg
        WHERE ROWID = i.r;
        END IF;
        INSERT INTO CMS_REGENPIN_DETAIL
        (crd_inst_code, crd_card_no, crd_file_name,
        crd_remarks, crd_msg24_flag, crd_process_flag,
        crd_process_msg, crd_process_mode, crd_ins_user,
        crd_ins_date, crd_lupd_user, crd_lupd_date
        )
        VALUES (prm_instcode, i.cgt_card_no, i.cgt_file_name,
        i.cgt_remarks, 'N', v_errflag,
        v_errmsg, 'G', prm_lupduser,
        SYSDATE, prm_lupduser, SYSDATE
        );
        ----------------- End repin for prepaid card-------------------------*/
        
      ELSIF v_prod_catg in('D','A') THEN
        --------------- Sn repin for debit card--------------------
        Sp_Regen_Pin_Debit (prm_instcode,
                          --  i.cgt_card_no
                            --v_decr_pan,
                            Fn_dmaps_Main(i.cgt_card_no_encr),
                            i.cgt_mbr_numb,
                            v_oldpinoff,
                            v_pingen_date,
                            i.cgt_remarks,
                            v_resoncode,
                            0,
                            'G',
                            prm_lupduser,
                            v_errmsg
                            );
        IF v_errmsg   <> 'OK' THEN
          v_succ_flag := 'E';
          RAISE exp_loop_reject_record;
        elsif v_errmsg = 'OK' THEN
          v_errflag   := 'S';
          v_errmsg    := 'Successful';
          v_succ_flag := 'S';
          BEGIN
            UPDATE CMS_GROUP_REGENPIN_TEMP
            SET cgt_process_flag = 'S',
              cgt_process_msg    = v_errmsg
            WHERE ROWID          = i.r;
          EXCEPTION
          WHEN OTHERS THEN
            v_errmsg := 'Error while updating record in grp regenpin temp table' || SUBSTR(sqlerrm,1,150);
            RAISE exp_loop_reject_record;
          END;
        END IF;
        BEGIN
          INSERT
          INTO CMS_REGENPIN_DETAIL
            (
              crd_inst_code,
              crd_card_no,
              crd_file_name,
              crd_remarks,
              crd_msg24_flag,
              crd_process_flag,
              crd_process_msg,
              crd_process_mode,
              crd_ins_user,
              crd_ins_date,
              crd_lupd_user,
              crd_lupd_date,crd_card_no_encr
            )
            VALUES
            (
              prm_instcode,
              i.cgt_card_no,
              i.cgt_file_name,
              i.cgt_remarks,
              'N',
              v_errflag,
              v_errmsg,
              'G',
              prm_lupduser,
              SYSDATE,
              prm_lupduser,
              SYSDATE,
              i.cgt_card_no_encr              
            );
        EXCEPTION
        WHEN VALUE_ERROR THEN
          v_errmsg := 'Some value Error while inserting in to CMS ACT_DELINK DETAIL';
          RAISE exp_loop_reject_record;
        WHEN OTHERS THEN
          v_errmsg :='Error while inserting records CMS  DETAIL from master'|| SUBSTR
          (
            SQLERRM, 1, 200
          )
          ;
          RAISE exp_loop_reject_record;
        END;
        --------------- End repin for debit card--------------------
      END IF;
    EXCEPTION
    WHEN exp_loop_reject_record THEN                    --<< LOOP I EXCEPTION>>--
      ROLLBACK TO v_repinsavepoint;
      v_succ_flag := 'E';
      UPDATE CMS_GROUP_REGENPIN_TEMP
      SET cgt_process_flag = 'E',
        cgt_process_msg    = v_errmsg
      WHERE ROWID          = i.r;
      INSERT
      INTO CMS_REGENPIN_DETAIL
        (
          crd_inst_code,
          crd_card_no,
          crd_file_name,
          crd_remarks,
          crd_msg24_flag,
          crd_process_flag,
          crd_process_msg,
          crd_process_mode,
          crd_ins_user,
          crd_ins_date,
          crd_lupd_user,
          crd_lupd_date,crd_card_no_encr
        )
        VALUES
        (
          prm_instcode,
          i.cgt_card_no,
          i.cgt_file_name,
          i.cgt_remarks,
          'N',
          'E',
          v_errmsg,
          'G',
          prm_lupduser,
          SYSDATE,
          prm_lupduser,
          SYSDATE, i.cgt_card_no_encr
        );
    WHEN OTHERS THEN
      ROLLBACK TO v_repinsavepoint;
      v_succ_flag := 'E';
      v_errmsg    := 'From main ' || SUBSTR(SQLERRM, 1, 200);
      UPDATE CMS_GROUP_REGENPIN_TEMP
      SET cgt_process_flag = 'E',
        cgt_process_msg    = v_errmsg
      WHERE ROWID          = i.r;
      INSERT
      INTO CMS_REGENPIN_DETAIL
        (
          crd_inst_code,
          crd_card_no,
          crd_file_name,
          crd_remarks,
          crd_msg24_flag,
          crd_process_flag,
          crd_process_msg,
          crd_process_mode,
          crd_ins_user,
          crd_ins_date,
          crd_lupd_user,
          crd_lupd_date,crd_card_no_encr
        )
        VALUES
        (
          prm_instcode,
          i.cgt_card_no,
          i.cgt_file_name,
          i.cgt_remarks,
          'N',
          'E',
          v_errmsg,
          'G',
          prm_lupduser,
          SYSDATE,
          prm_lupduser,
          SYSDATE,
          i.cgt_card_no_encr
        );
      -- Sn to reset the error value
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
                         i.cgt_card_no, v_prodcode, 'GROUP REGENERATE PIN',
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
                         i.cgt_card_no, v_prodcode, 'GROUP REGENERATE PIN',
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
          
    --------start inserting record in audit log--------
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
          pal_inst_code, pal_card_no_encr
        )
        VALUES
        (
          i.cgt_card_no,
          v_remark,
          v_txn_code,
          v_del_channel,
          0,
          'HOST',
          v_succ_flag,
          prm_lupduser,
          SYSDATE,
          v_errmsg,
          v_reasondesc,
          i.cgt_remarks,
          'G',
          prm_instcode, i.cgt_card_no_encr
        );
    EXCEPTION
    WHEN OTHERS THEN
      --prm_errmsg := 'Pan Not Found in Master';
      UPDATE CMS_GROUP_REGENPIN_TEMP
      SET CGT_PROCESS_FLAG = 'E',
        CGT_PROCESS_MSG    = 'Error while inserting into Audit log'
      WHERE ROWID          = i.r;
    END;
    --------end inserting record in audit log--------
  END LOOP;                                           --<< LOOP I END >>
  --v_errmsg := 'OK';
  prm_errmsg := 'OK';
EXCEPTION                                             --<< MAIN EXCEPTION>>
/*WHEN exp_main_reject_record THEN
  prm_errmsg := v_errmsg;*/
WHEN OTHERS THEN
  prm_errmsg := ' Error from main ' || SUBSTR (SQLERRM, 1, 200);
END; --<< MAIN END>>
/
SHOW ERRORS

