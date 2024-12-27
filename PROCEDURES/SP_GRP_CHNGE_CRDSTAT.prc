CREATE OR REPLACE PROCEDURE VMSCMS.sp_grp_chnge_crdstat
(
    prm_instcode IN NUMBER,
    prm_ipaddr   IN VARCHAR2,
    prm_lupduser IN NUMBER,
    prm_errmsg OUT VARCHAR2
)
as
  v_remark            CMS_PAN_SPPRT.cps_func_remark%TYPE;
  v_cardstat          CMS_APPL_PAN.cap_card_stat%TYPE;
  v_resoncode         CMS_SPPRT_REASONS.csr_spprt_rsncode%TYPE;
  v_cardstatdesc      VARCHAR2 (10);
  v_mbrnumb           VARCHAR2 (3) DEFAULT '000';
  v_rrn               VARCHAR2 (12);
  v_stan              VARCHAR2 (12);
  v_authmsg           VARCHAR2 (300);
  v_card_curr         VARCHAR2 (3);
  v_errmsg            VARCHAR2 (300);
  v_chngstatsavepoint NUMBER (9) DEFAULT 99;
  v_errflag           CHAR (1);
  v_txn_code          VARCHAR2 (2);
  v_txn_type          VARCHAR2 (2);
  v_txn_mode          VARCHAR2 (2);
  v_del_channel       VARCHAR2 (2);
  v_succ_flag         VARCHAR2 (1);
  v_prod_catg CMS_APPL_PAN.cap_prod_catg%TYPE;
  v_reasondesc CMS_SPPRT_REASONS.CSR_REASONDESC%TYPE;
  exp_loop_reject_record EXCEPTION;
  v_decr_pan    CMS_APPL_PAN.cap_pan_code_encr%TYPE;
  v_applcode                   CMS_APPL_PAN.cap_appl_code%TYPE;
  v_acctno                     CMS_APPL_PAN.cap_acct_no%TYPE;                  
  v_prodcode                   CMS_APPL_PAN.cap_prod_code%TYPE;
  
cursor c1
is 
  select
  ROWID ROW_ID,
  CGC_CARD_NO,
  CGC_FILE_NAME,
  CGC_NEW_STAT,
  CGC_REMARK,
  CGC_MBR_NUMB,
  CGC_INS_USER,
  CGC_INS_DATE,
  CGC_PROCESS_FLAG,
  CGC_PROCESS_MSG,CGC_CARD_NO_encr
  from cms_grp_change_crdstat_temp
  where CGC_process_flag='N'
  AND cgc_inst_code= prm_instcode;
begin                                   --<< main begin starts >>--
  prm_errmsg:='OK';
  
  -------------------------------- Sn get Function Master----------------------------
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
          WHERE cfm_func_code = 'CHGSTA'
      AND cfm_inst_code=prm_instcode;
    EXCEPTION
        WHEN OTHERS THEN
          prm_errmsg:='Function Master Not Defined for change card status ' || SUBSTR (SQLERRM, 1, 200);
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
    WHERE csr_spprt_key = 'CHGSTA'
    AND csr_inst_code=prm_instcode
    AND ROWNUM < 2;
  EXCEPTION
  WHEN VALUE_ERROR THEN
    prm_errmsg := 'Change card status reason code not present in master ';
    RETURN;
  WHEN NO_DATA_FOUND THEN
    prm_errmsg := 'Change card status  reason code not present in master';
    RETURN;
  WHEN OTHERS THEN
    prm_errmsg := 'Error while selecting reason code from master' || SUBSTR (SQLERRM, 1, 200);
    RETURN;
  END;
   ------------------------------En get reason code from support reason master--------------------
  FOR x in c1
  LOOP
  BEGIN                                                 --<< loop main begin start >>--
      v_errmsg := 'OK';
      v_chngstatsavepoint := v_chngstatsavepoint + 1 ;
      SAVEPOINT v_chngstatsavepoint ;
      prm_errmsg  := 'OK';
      v_prod_catg := NULL;
      v_cardstat  := NULL;
               
  

--SN create decr pan
BEGIN
    v_decr_pan := Fn_dmaps_Main(x.CGC_CARD_NO_ENCR);
EXCEPTION
WHEN OTHERS THEN
v_errmsg := 'Error while converting pan ' || SUBSTR(SQLERRM,1,200);
RAISE    exp_loop_reject_record;
END;
--EN create decr pan
  

                                   
      --------start to find prodct category and card status--------------
      BEGIN
          SELECT cap_prod_catg,
                cap_card_stat,CAP_APPL_CODE,CAP_ACCT_NO,CAP_PROD_CODE
                INTO v_prod_catg,
                v_cardstat,v_applcode, v_acctno, v_prodcode
                FROM CMS_APPL_PAN
                WHERE cap_pan_code = x.cgc_card_no
                AND cap_mbr_numb   = x.cgc_mbr_numb
                AND cap_inst_code  =prm_instcode;
                
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
      
      IF v_cardstat NOT IN ('1','4','0') THEN
        v_errmsg :='Card is not available as open or restricted or Inactive';
        RAISE exp_loop_reject_record;
      END IF;
      
      IF v_prod_catg = 'P' THEN
        ------start account delink for prepaid
        NULL;
        ------end account delink for prepaid
      elsif v_prod_catg in('D','A') THEN
        ------start account delink for debit------------
        sp_chnge_crdstat_debit(
                                 prm_instcode ,  
                                 --x.CGC_CARD_NO
                                v_decr_pan,
                               -- Fn_dmaps_Main(x.CGC_CARD_NO_ENCR),
                                 x.CGC_MBR_NUMB,                                       
                                 x.CGC_REMARK,
                                 v_resoncode,
                                 0,
                                 x.CGC_NEW_STAT,
                                 x.CGC_INS_USER,
                                 v_errmsg
                                 );
        IF v_errmsg<>'OK' THEN
          v_succ_flag:='E';
          RAISE exp_loop_reject_record;
        ELSIF v_errmsg = 'OK' THEN
          v_errflag   := 'S';
          v_succ_flag := 'S';
          v_errmsg    := 'Successful';
          BEGIN
            UPDATE cms_grp_change_crdstat_temp
            SET cgc_process_flag = 'S',
                cgc_process_msg    = 'SUCCESSFULL'
            WHERE ROWID          = x.ROW_ID;
          EXCEPTION
          WHEN OTHERS THEN
            v_errmsg := 'Error while updating record in grp acctdlink temp table' || SUBSTR(sqlerrm,1,150);
            RAISE exp_loop_reject_record;
          END;
        END IF;
        BEGIN
          insert into cms_change_cardstat_detail(
                                              CCD_INST_CODE,
                                              CCD_CARD_NO,
                                              CCD_FILE_NAME,
                                              CCD_OLD_CARDSTAT,
                                              CCD_NEW_CARDSTAT,
                                              CCD_REMARKS,
                                              CCD_MSG24_FLAG,
                                              CCD_PROCESS_FLAG,
                                              CCD_PROCESS_MSG,
                                              CCD_PROCESS_MODE,
                                              CCD_INS_USER,
                                              CCD_INS_DATE,
                                              CCD_LUPD_USER,
                                              CCD_LUPD_DATE,
                                              CCD_CARD_NO_encr
                                            )
                                      VALUES(
                                              prm_instcode,
                                              x.CGC_CARD_NO ,
                                              x.CGC_FILE_NAME,
                                              v_cardstat,
                                              x.CGC_NEW_STAT,
                                              x.CGC_REMARK,
                                              'N',
                                              v_succ_flag,
                                              v_errmsg,
                                              'G',
                                              prm_lupduser,
                                              x.CGC_INS_DATE,
                                              prm_lupduser,
                                              x.CGC_INS_DATE    ,
                                              x.CGC_CARD_NO_encr                            
                                        );
        EXCEPTION
        WHEN VALUE_ERROR THEN
          v_errmsg := ' Error while inserting in to CMS ACT_DELINK DETAIL';
          RAISE exp_loop_reject_record;
        WHEN OTHERS THEN
          v_errmsg :='Error while inserting records CMS ACT_DELINK DETAIL from master'|| SUBSTR(SQLERRM, 1, 200);
          RAISE exp_loop_reject_record;
        END;
        ------end account delink for debit-------------
      END IF;
  EXCEPTION WHEN exp_loop_reject_record then      --<< loop main exception >>--
    ROLLBACK TO v_chngstatsavepoint;
    v_succ_flag := 'E';
    UPDATE cms_grp_change_crdstat_temp
    SET cgc_process_flag = 'E',
        cgc_process_msg  = v_errmsg
    WHERE ROWID = x.ROW_ID;
    insert into cms_change_cardstat_detail(
                                              CCD_INST_CODE,
                                              CCD_CARD_NO,
                                              CCD_FILE_NAME,
                                              CCD_OLD_CARDSTAT,
                                              CCD_NEW_CARDSTAT,
                                              CCD_REMARKS,
                                              CCD_MSG24_FLAG,
                                              CCD_PROCESS_FLAG,
                                              CCD_PROCESS_MSG,
                                              CCD_PROCESS_MODE,
                                              CCD_INS_USER,
                                              CCD_INS_DATE,
                                              CCD_LUPD_USER,
                                              CCD_LUPD_DATE,
                                                CCD_CARD_NO_encr
                                            )
                                      VALUES(
                                              prm_instcode,
                                              x.CGC_CARD_NO ,
                                              x.CGC_FILE_NAME,
                                              v_cardstat,
                                              x.CGC_NEW_STAT,
                                              x.CGC_REMARK,
                                              'N',
                                              v_succ_flag,
                                              v_errmsg,
                                              'G',
                                              prm_lupduser,
                                              x.CGC_INS_DATE,
                                              prm_lupduser,
                                              x.CGC_INS_DATE        ,
                                               x.CGC_CARD_NO_encr                        
                                        );
    WHEN OTHERS THEN
      ROLLBACK TO v_chngstatsavepoint;
      v_succ_flag := 'E';
      v_errmsg    := 'Error while processing group card stat change in loop ' || SUBSTR(sqlerrm,1,200);
      UPDATE cms_grp_change_crdstat_temp
      SET cgc_process_flag = 'E',
          cgc_process_msg  = v_errmsg
      WHERE ROWID = x.ROW_ID;
      insert into cms_change_cardstat_detail(
                                              CCD_INST_CODE,
                                              CCD_CARD_NO,
                                              CCD_FILE_NAME,
                                              CCD_OLD_CARDSTAT,
                                              CCD_NEW_CARDSTAT,
                                              CCD_REMARKS,
                                              CCD_MSG24_FLAG,
                                              CCD_PROCESS_FLAG,
                                              CCD_PROCESS_MSG,
                                              CCD_PROCESS_MODE,
                                              CCD_INS_USER,
                                              CCD_INS_DATE,
                                              CCD_LUPD_USER,
                                              CCD_LUPD_DATE,
                                               CCD_CARD_NO_encr
                                            )
                                      VALUES(
                                              prm_instcode,
                                              x.CGC_CARD_NO ,
                                              x.CGC_FILE_NAME,
                                              v_cardstat,
                                              x.CGC_NEW_STAT,
                                              x.CGC_REMARK,
                                              'N',
                                              v_succ_flag,
                                              v_errmsg,
                                              'G',
                                              prm_lupduser,
                                              x.CGC_INS_DATE,
                                              prm_lupduser,
                                              x.CGC_INS_DATE        ,
                                              x.CGC_CARD_NO_encr                        
                                        );
  END;                                   --<< loop main begin ends >>--
  
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
                         x.CGC_CARD_NO, v_prodcode, 'GROUP CARD STATUS CHANGE',
                         'INSERT', 'SUCCESS', prm_ipaddr,
                         'CMS_PAN_SPPRT', '', x.CGC_CARD_NO_ENCR,
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
                         x.CGC_CARD_NO, v_prodcode, 'GROUP CARD STATUS CHANGE',
                         'INSERT', 'FAILURE', prm_ipaddr,
                         'CMS_PAN_SPPRT', '', x.CGC_CARD_NO_ENCR,
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
          pal_inst_code,
          pal_card_no_encr
        )
        VALUES
        (
          x.cgc_card_no,
          'Group card stat change',
          v_txn_code,
          v_del_channel,
          0,
          'HOST',
          v_succ_flag,
          prm_lupduser,
          SYSDATE,
          v_errmsg,
          v_reasondesc,
          x.cgc_remark,
          'G',
          prm_instcode,
           x.cgc_card_no_encr
        );
    EXCEPTION
    WHEN OTHERS THEN
      UPDATE cms_grp_change_crdstat_temp
      SET cgc_process_flag = 'E',
        cgc_process_msg    = 'Error while inserting into Audit log'
      WHERE ROWID          = x.ROW_ID;
    END;
  END LOOP;
  prm_errmsg := 'OK';
exception                               --<< main exception >>--
  WHEN OTHERS THEN
  prm_errmsg := 'Main Excp from group card stat change -- ' || SUBSTR(SQLERRM,1,200);
end;                                   
--<< main begin end >>--
/
SHOW ERRORS

