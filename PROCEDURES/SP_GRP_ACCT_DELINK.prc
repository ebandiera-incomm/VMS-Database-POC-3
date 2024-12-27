CREATE OR REPLACE PROCEDURE VMSCMS.sp_grp_acct_delink
  (
    prm_instcode IN NUMBER,
   -- prm_rsncode  IN NUMBER,
   prm_ipaddr    IN VARCHAR2,
    prm_lupduser IN VARCHAR2,
    prm_workmode IN NUMBER,
    prm_errmsg OUT VARCHAR2 )
AS
  v_remark CMS_PAN_SPPRT.cps_func_remark%TYPE;
  v_cardstat CMS_APPL_PAN.cap_card_stat%TYPE;
  v_resoncode CMS_SPPRT_REASONS.csr_spprt_rsncode%TYPE;
  v_cardstatdesc    VARCHAR2 (10);
  v_mbrnumb         VARCHAR2 (3) DEFAULT '000';
  v_rrn             VARCHAR2 (12);
  v_stan            VARCHAR2 (12);
  v_authmsg         VARCHAR2 (300);
  v_card_curr       VARCHAR2 (3);
  v_errmsg          VARCHAR2 (300);
  v_delinksavepoint NUMBER (9) DEFAULT 99;
  v_errflag         CHAR (1);
  v_txn_code        VARCHAR2 (2);
  v_txn_type        VARCHAR2 (2);
  v_txn_mode        VARCHAR2 (2);
  v_del_channel     VARCHAR2 (2);
  v_succ_flag       VARCHAR2 (1);
  --v_act_position    VARCHAR2(5);
  v_custcode		CMS_APPL_PAN.cap_cust_code%type;
  v_acct_id cms_acct_mast.cam_acct_id%type;
  v_prod_catg CMS_APPL_PAN.cap_prod_catg%TYPE;
  v_reasondesc CMS_SPPRT_REASONS.CSR_REASONDESC%TYPE;
  v_decr_pan    CMS_APPL_PAN.cap_pan_code_encr%TYPE;
  v_applcode                   CMS_APPL_PAN.cap_appl_code%TYPE;
  v_acctno                     CMS_APPL_PAN.cap_acct_no%TYPE;                  
  v_prodcode                   CMS_APPL_PAN.cap_prod_code%TYPE;
  exp_loop_reject_record EXCEPTION;
  CURSOR c1
  IS
    SELECT ROWID ROW_ID,
      cgd_card_no,
      cgd_old_acct_no,
      cgd_process_flag,
      cgd_ins_date ,
      cgd_file_name,
      cgd_process_msg,
      cgd_mbr_numb,
      cgd_remarks,
      cgd_card_no_encr
    FROM cms_group_acctdelink_temp
    WHERE cgd_process_flag = 'N' 
    AND cgd_inst_code=prm_instcode;
BEGIN --<< Main begin starts >>--
  prm_errmsg := 'OK';
  --v_remark   := 'GROUP ACCOUNT DELINK';
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
    WHERE cfm_func_code = 'DLINK1'
    AND cfm_inst_code= prm_instcode;
  EXCEPTION
  WHEN OTHERS THEN
    prm_errmsg :='Function Master Not Defined ' || SUBSTR (SQLERRM, 1, 200);
    --RAISE exp_loop_reject_record;
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
    WHERE csr_spprt_key = 'DLINK1'
    AND csr_inst_code=prm_instcode
    AND ROWNUM          < 2;
  EXCEPTION
  WHEN VALUE_ERROR THEN
    prm_errmsg := 'Account Delink reason code not present in master ';
    --RAISE exp_loop_reject_record;
    RETURN;
  WHEN NO_DATA_FOUND THEN
    prm_errmsg := 'Account Delink  reason code not present in master';
    --RAISE exp_loop_reject_record;
    RETURN;
  WHEN OTHERS THEN
    prm_errmsg := 'Error while selecting reason code from master' || SUBSTR (SQLERRM, 1, 200);
    --RAISE exp_loop_reject_record;
    RETURN;
  END;
  ------------------------------En get reason code from support reason master---------------------
  FOR X IN c1
  LOOP
    BEGIN --<< LOOP I BEGIN >>--
      v_errmsg          := 'OK';
      v_delinksavepoint := v_delinksavepoint + 1 ;
      SAVEPOINT v_delinksavepoint ;
      prm_errmsg  := 'OK';
      v_prod_catg := NULL;
      v_cardstat  := NULL;
      --------start to find account id------------------
      BEGIN
        SELECT cam_acct_id
        INTO v_acct_id
        FROM cms_acct_mast
        WHERE cam_inst_code= prm_instcode
        AND cam_acct_no    =x.cgd_old_acct_no;
      EXCEPTION
      WHEN no_data_found THEN
        v_errmsg:='No account id for given account no';
        RAISE exp_loop_reject_record;
      WHEN OTHERS THEN
        v_errmsg :='Error while getting records from acct mast table '|| SUBSTR (SQLERRM, 1, 200);
        RAISE exp_loop_reject_record;
      END;
      --------end to find account id--------------------
      --------start to find prodct category and card status--------------
      BEGIN
        SELECT cap_prod_catg,
               cap_card_stat,CAP_APPL_CODE,CAP_ACCT_NO,CAP_PROD_CODE,
			   cap_cust_code
        INTO v_prod_catg,
             v_cardstat,v_applcode, v_acctno, v_prodcode,
			 v_custcode
        FROM CMS_APPL_PAN
        WHERE cap_pan_code = x.cgd_card_no
        AND cap_mbr_numb   = x.cgd_mbr_numb
        AND cap_inst_code  = prm_instcode;
			IF v_prod_catg IS NULL OR v_cardstat IS NULL THEN
				v_errmsg := 'Product category or card status is not defined for the card';
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
      IF v_cardstat<>1 THEN
        v_errmsg :='Card is not open for delinking';
        RAISE exp_loop_reject_record;
      END IF;
      
       --SN create decr pan
BEGIN
    v_decr_pan := Fn_dmaps_Main(x.cgd_card_no_encr);
EXCEPTION
WHEN OTHERS THEN
v_errmsg := 'Error while converting pan ' || SUBSTR(SQLERRM,1,200);
RAISE    exp_loop_reject_record;
END;
--EN create decr pan

      IF v_prod_catg = 'P' THEN
        ------start account delink for prepaid
        NULL;
        ------end account delink for prepaid
      elsif v_prod_catg in('D','A') THEN
        ------start account delink for debit-------------
        Sp_Delink_acct_Debit(prm_instcode,
							 v_acct_id, 
							-- x.cgd_card_no,
                            v_decr_pan,
							 x.cgd_old_acct_no, 
							 x.cgd_mbr_numb, 
							 v_resoncode, 
							 x.cgd_remarks, 
							 prm_lupduser, 
							 prm_workmode, 
							 v_custcode,
							 v_errmsg );
        IF v_errmsg   <> 'OK' THEN
          v_succ_flag := 'E';
          RAISE exp_loop_reject_record;
        ELSIF v_errmsg = 'OK' THEN
          v_errflag   := 'S';
          v_succ_flag := 'S';
          v_errmsg    := 'Successful';
          BEGIN
            UPDATE cms_group_acctdelink_temp
            SET cgd_process_flag = 'S',
              cgd_process_msg    = 'SUCCESSFULL'
            WHERE ROWID          = x.ROW_ID;
          EXCEPTION
          WHEN OTHERS THEN
            v_errmsg := 'Error while updating record in grp acctdlink temp table' || SUBSTR(sqlerrm,1,150);
            RAISE exp_loop_reject_record;
          END;
        END IF;
        BEGIN
          INSERT
          INTO CMS_ACT_DELINK_DETAIL
            (
              cad_inst_code ,
              cad_card_no ,
              cad_old_acc_no,
              cad_file_name ,
              cad_remarks ,
              cad_msg24_flag ,
              cad_process_flag,
              cad_process_msg ,
              cad_process_mode,
              cad_ins_user ,
              cad_ins_date ,
              cad_lupd_user ,
              cad_lupd_date
            )
            VALUES
            (
              prm_instcode,
              x.cgd_card_no,
              x.cgd_old_acct_no,
              x.cgd_file_name,
              x.cgd_remarks,
              'N',
              'S',
              'SUCCESSFUL',
              'G',
              prm_lupduser,
              sysdate,
              prm_lupduser,
              sysdate
            );
        EXCEPTION
        WHEN VALUE_ERROR THEN
          v_errmsg := ' Error while inserting in to CMS ACT_DELINK DETAIL';
          RAISE exp_loop_reject_record;
        WHEN OTHERS THEN
          v_errmsg :='Error while inserting records CMS ACT_DELINK DETAIL from master'|| SUBSTR
          (
            SQLERRM, 1, 200
          )
          ;
          RAISE exp_loop_reject_record;
        END;
      END IF;
      ------end account delink for debit-------------
    EXCEPTION --<< LOOP I EXCEPTION >>
    WHEN exp_loop_reject_record THEN
      ROLLBACK TO v_delinksavepoint;
      v_succ_flag := 'E';
      UPDATE cms_group_acctdelink_temp
      SET cgd_process_flag = 'E',
        cgd_process_msg    = v_errmsg
      WHERE ROWID          = x.ROW_ID;
      INSERT
      INTO CMS_ACT_DELINK_DETAIL
        (
          cad_inst_code ,
          cad_card_no ,
          cad_old_acc_no,
          cad_file_name ,
          cad_remarks ,
          cad_msg24_flag ,
          cad_process_flag,
          cad_process_msg ,
          cad_process_mode,
          cad_ins_user ,
          cad_ins_date ,
          cad_lupd_user ,
          cad_lupd_date
        )
        VALUES
        (
          prm_instcode,
          x.cgd_card_no,
          x.cgd_old_acct_no,
          x.cgd_file_name,
          x.cgd_remarks,
          'N',
          'E',
          v_errmsg,
          'G',
          prm_lupduser,
          sysdate,
          prm_lupduser,
          sysdate
        );
    WHEN OTHERS THEN
      ROLLBACK TO v_delinksavepoint;
      v_succ_flag := 'E';
      v_errmsg    := 'Error while processing group acct delink ' || SUBSTR
      (
        sqlerrm,1,150
      )
      ;
      UPDATE CMS_GROUP_ACCTDELINK_TEMP
      SET cgd_process_flag = 'E',
        cgd_process_msg    = v_errmsg
      WHERE ROWID          = x.ROW_ID;
      INSERT
      INTO CMS_ACT_DELINK_DETAIL
        (
          cad_inst_code ,
          cad_card_no ,
          cad_old_acc_no ,
          cad_file_name ,
          cad_remarks ,
          cad_msg24_flag ,
          cad_process_flag,
          cad_process_msg ,
          cad_process_mode,
          cad_ins_user ,
          cad_ins_date ,
          cad_lupd_user ,
          cad_lupd_date
        )
        VALUES
        (
          prm_instcode,
          x.cgd_card_no,
          x.cgd_old_acct_no,
          x.cgd_file_name,
          x.cgd_remarks,
          'N',
          'E',
          v_errmsg,
          'G',
          prm_lupduser,
          sysdate,
          prm_lupduser,
          sysdate
        );
    END; --<< LOOP I END >>
    
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
                         x.cgd_card_no, v_prodcode, 'GROUP ACCOUNT DELINK',
                         'INSERT', 'SUCCESS', prm_ipaddr,
                         'CMS_PAN_SPPRT', '', x.cgd_card_no_encr,
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
                         x.cgd_card_no, v_prodcode, 'GROUP ACCOUNT DELINK',
                         'INSERT', 'FAILURE', prm_ipaddr,
                         'CMS_PAN_SPPRT', '', x.cgd_card_no_encr,
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
          pal_inst_code
        )
        VALUES
        (
          x.cgd_card_no,
          'Group Delink',
          v_txn_code,
          v_del_channel,
          0,
          'HOST',
          v_succ_flag,
          prm_lupduser,
          SYSDATE,
          v_errmsg,
          v_reasondesc,
          x.cgd_remarks,
          'G'
          ,
          prm_instcode
        );
    EXCEPTION
    WHEN OTHERS THEN
      --prm_errmsg := 'Pan Not Found in Master';
      UPDATE CMS_GROUP_ACCTDELINK_TEMP
      SET cgd_process_flag = 'E',
        cgd_process_msg    = 'Error while inserting into Audit log'
      WHERE ROWID          = x.ROW_ID;
    END;
    --------end inserting record in audit log--------
  END LOOP;
  prm_errmsg := 'OK';
EXCEPTION --<< MAIN EXCEPTION >>--
WHEN OTHERS THEN
  prm_errmsg := 'Main Excp from dlink acct  -- ' || SUBSTR(SQLERRM,1,200);
END; --<< MAIN END >>--
/
SHOW ERRORS

