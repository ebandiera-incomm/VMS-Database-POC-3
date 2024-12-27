CREATE OR REPLACE PROCEDURE VMSCMS.sp_csr_melissa_addr_override(
    prm_instcode         IN NUMBER,
    prm_msg_type         IN VARCHAR2,
    prm_remark           IN VARCHAR2,
    prm_pan_code         IN VARCHAR2,
    prm_mbrnumb          IN VARCHAR2,
    prm_rrn              IN VARCHAR2, 
    prm_stan             IN VARCHAR2,
    prm_txn_code         IN VARCHAR2,
    prm_txn_mode         IN VARCHAR2,
    prm_delivery_channel IN VARCHAR2,
    prm_trandate         IN VARCHAR2,
    prm_trantime         IN VARCHAR2,
    prm_currcode         IN VARCHAR2,
    prm_rvsl_code        IN VARCHAR2,
    prm_ins_user         IN NUMBER,
    prm_call_id          IN NUMBER,
    PRM_IPADDRESS        IN VARCHAR2,
    PRM_AVQ_ID           IN VARCHAR2,
    PRM_RESP_CODE OUT VARCHAR2,
    prm_resp_msg OUT VARCHAR2 )
IS
  /*******************************************************************************
  * Created Date                 : 20/Dec/2014.
  * Created By                   : Abdul Hameed M.A
  * Purpose                      : Melissa Address Override
  * Build Number                 : RI0027.5_B0002
  
  * Modified Date                : 31/Dec/2014.
  * Modified By                  : Sai
  * Build Number                 : RI0027.5_B0004
  
  * Modified By      : venkat Singamaneni
  * Modified Date    : 3-18-2022
  * Purpose          : Archival changes.
  * Reviewer         : Saravana Kumar A
  * Release Number   : VMSGPRHOST60 for VMS-5733/FSP-991
  ********************************************************************************/
  v_cust_code cms_appl_pan.cap_cust_code%TYPE;
  v_cust_name cms_appl_pan.CAP_DISP_NAME%TYPE;
  v_hash_pan cms_appl_pan.cap_pan_code%TYPE;
  v_mbrnumb cms_appl_pan.cap_mbr_numb%TYPE;
  v_proxynumber cms_appl_pan.cap_proxy_number%TYPE;
  v_encr_pan cms_appl_pan.cap_pan_code_encr%TYPE;
  v_prodcatg cms_appl_pan.cap_prod_catg%TYPE;
  v_prod_cattype cms_appl_pan.cap_card_type%TYPE;
  v_prod_code cms_appl_pan.cap_prod_code%TYPE;
  v_capture_date DATE;
  v_auth_id   NUMBER;
  v_rrn_count NUMBER (3);
  v_respcode  VARCHAR2 (5);
  v_errmsg transactionlog.ERROR_MSG%type;
  exp_reject_txn EXCEPTION;
  v_acct_balance cms_acct_mast.cam_acct_bal%TYPE;
  v_ledger_balance cms_acct_mast.cam_ledger_bal%TYPE;
  v_cnt      NUMBER (2);
  V_CALL_SEQ number (3);
  --v_date_format cms_inst_param.cip_param_value%TYPE;
  v_spnd_acctno cms_appl_pan.cap_acct_no%TYPE;
  V_TRANS_DESC CMS_TRANSACTION_MAST.CTM_TRAN_DESC%type;
  V_ACCT_TYPE CMS_ACCT_MAST.CAM_TYPE_CODE%type;
  v_Retperiod  date; --Added for VMS-5733/FSP-991
  v_Retdate  date; --Added for VMS-5733/FSP-991
  
BEGIN -- begin 001 starts here
  V_ERRMSG   := 'OK';
  v_respcode := '1';
  --SN CREATE HASH PAN
  BEGIN
    v_hash_pan := gethash (prm_pan_code);
  EXCEPTION
  WHEN OTHERS THEN
    v_respcode := '21';
    v_errmsg   := 'Error while converting in hashpan ' || SUBSTR (SQLERRM, 1, 100);
    RAISE exp_reject_txn;
  END;
  --EN CREATE HASH PAN
  --SN create encr pan
  BEGIN
    v_encr_pan := fn_emaps_main (prm_pan_code);
  EXCEPTION
  WHEN OTHERS THEN
    v_respcode := '12';
    v_errmsg   := 'Error while converting encrpan ' || SUBSTR (SQLERRM, 1, 200);
    RAISE exp_reject_txn;
  END;
  BEGIN
    SELECT ctm_tran_desc
    INTO v_trans_desc
    FROM cms_transaction_mast
    WHERE ctm_inst_code      = prm_instcode
    AND ctm_tran_code        = prm_txn_code
    AND ctm_delivery_channel =prm_delivery_channel ;
  EXCEPTION
  WHEN NO_DATA_FOUND THEN
    v_errmsg   := 'Error while fetching transaction description';
    v_respcode := '21';
    RAISE exp_reject_txn;
  WHEN OTHERS THEN
    v_errmsg   :='Error while fetching transaction description '|| SUBSTR (SQLERRM, 1, 100);
    V_RESPCODE := '21';
    RAISE EXP_REJECT_TXN;
  END;
  --EN create encr pan
  BEGIN
  
  v_Retdate := TO_DATE(SUBSTR(TRIM(prm_trandate), 1, 8), 'yyyymmdd');

       select (add_months(trunc(sysdate,'MM'),'-'||RETENTION_PERIOD))
       INTO   v_Retperiod 
       FROM DBA_OPERATIONS.ARCHIVE_MGMNT_CTL 
       WHERE  OPERATION_TYPE='ARCHIVE' 
       AND OBJECT_NAME='TRANSACTIONLOG_EBR';

IF (v_Retdate>v_Retperiod)
    THEN
    SELECT COUNT (1)
    INTO v_rrn_count
    FROM transactionlog
    WHERE instcode       = prm_instcode
    AND customer_card_no = v_hash_pan
    AND rrn              = prm_rrn
    AND delivery_channel = prm_delivery_channel
    AND txn_code         = prm_txn_code
    AND business_date    = prm_trandate
    AND business_time    = prm_trantime
    AND delivery_channel = prm_delivery_channel;
    ELSE
    SELECT COUNT (1)
    INTO v_rrn_count
    FROM VMSCMS_HISTORY.TRANSACTIONLOG_HIST --Added for VMS-5733/FSP-991
    WHERE instcode       = prm_instcode
    AND customer_card_no = v_hash_pan
    AND rrn              = prm_rrn
    AND delivery_channel = prm_delivery_channel
    AND txn_code         = prm_txn_code
    AND business_date    = prm_trandate
    AND business_time    = prm_trantime
    AND delivery_channel = prm_delivery_channel;
    END IF;
    
    IF v_rrn_count       > 0 
    THEN
      v_respcode        := '22';
      v_errmsg          := 'Duplicate RRN found';
      RAISE exp_reject_txn;
    END IF;
  EXCEPTION
  WHEN exp_reject_txn THEN
    RAISE;
  WHEN OTHERS THEN
    v_errmsg   := 'while getting rrn count ' || SUBSTR (SQLERRM, 1, 100);
    v_respcode := '21';
    RAISE exp_reject_txn;
  END;
  BEGIN
    sp_authorize_txn_cms_auth (prm_instcode, prm_msg_type, prm_rrn, prm_delivery_channel, NULL, prm_txn_code, prm_txn_mode, prm_trandate, prm_trantime, prm_pan_code, NULL, 0, NULL, NULL, NULL, prm_currcode, NULL, NULL, NULL, NULL, NULL, NULL, NULL, NULL, NULL, NULL, NULL, NULL, NULL, prm_stan, prm_mbrnumb, prm_rvsl_code, NULL, v_auth_id, v_respcode, v_errmsg, v_capture_date );
    IF v_respcode <> '00' THEN
      BEGIN
      
      IF (v_Retdate>v_Retperiod)
    THEN
        UPDATE transactionlog
        SET remark           = prm_remark,
          ipaddress          = prm_ipaddress,
          add_ins_user       = prm_ins_user,
          add_lupd_user      = prm_ins_user
        WHERE instcode       = prm_instcode
        AND customer_card_no = v_hash_pan
        AND rrn              = prm_rrn
        AND business_date    = prm_trandate
        AND business_time    = prm_trantime
        AND delivery_channel = prm_delivery_channel
        AND txn_code         = prm_txn_code;
      ELSE
         UPDATE VMSCMS_HISTORY.TRANSACTIONLOG_HIST --Added for VMS-5733/FSP-991
        SET remark           = prm_remark,
          ipaddress          = prm_ipaddress,
          add_ins_user       = prm_ins_user,
          add_lupd_user      = prm_ins_user
        WHERE instcode       = prm_instcode
        AND customer_card_no = v_hash_pan
        AND rrn              = prm_rrn
        AND business_date    = prm_trandate
        AND business_time    = prm_trantime
        AND delivery_channel = prm_delivery_channel
        AND txn_code         = prm_txn_code;
       END IF;   
        IF SQL%ROWCOUNT      = 0 THEN
          v_respcode        := '21';
          v_errmsg          := 'Auth Fail - Txn not updated in transactiolog for remark ';
          RAISE exp_reject_txn;
        END IF;
      EXCEPTION
      WHEN exp_reject_txn THEN
        RAISE;
      WHEN OTHERS THEN
        v_respcode := '21';
        v_errmsg   := 'Auth Fail - Error while updating into transactiolog ' || SUBSTR (SQLERRM, 1, 200);
        RAISE exp_reject_txn;
      END;
      prm_resp_code := v_respcode;
      prm_resp_msg  := v_errmsg;
      RETURN;
    END IF;
  EXCEPTION
  WHEN exp_reject_txn THEN
    raise;
  WHEN OTHERS THEN
    v_respcode := '21';
    v_errmsg   := 'problem while call to sp_authorize_txn_cmsauth ' || SUBSTR (SQLERRM, 1, 100);
    RAISE exp_reject_txn;
  END;
  BEGIN
    SELECT cap_cust_code,
      cap_mbr_numb,
      cap_proxy_number,
      cap_prod_code,
      CAP_PROD_CATG,
      cap_card_type,cap_acct_no,CAP_DISP_NAME
    INTO v_cust_code,
      v_mbrnumb,
      v_proxynumber,
      v_prod_code,
      V_PRODCATG,
      v_prod_cattype,v_spnd_acctno,v_cust_name
    FROM cms_appl_pan
    WHERE cap_inst_code = prm_instcode
    AND cap_pan_code    = v_hash_pan;
  EXCEPTION
  WHEN NO_DATA_FOUND THEN
    v_errmsg   := 'Pan not found in master';
    v_respcode := '16';
    RAISE exp_reject_txn;
  WHEN OTHERS THEN
    v_errmsg   := 'from pan master ' || SUBSTR (SQLERRM, 1, 100);
    v_respcode := '21';
    RAISE exp_reject_txn;
  end;
 /* BEGIN
    SELECT cap_acct_no
    INTO v_spnd_acctno
    FROM cms_appl_pan
    WHERE cap_pan_code = v_hash_pan
    AND cap_inst_code  = prm_instcode
    AND cap_mbr_numb   = prm_mbrnumb;
  EXCEPTION
  WHEN EXP_REJECT_TXN THEN
    RAISE;
  WHEN NO_DATA_FOUND THEN
    v_respcode := '21';
    v_errmsg   := 'Spending Account Number Not Found For the Card in PAN Master ';
    RAISE exp_reject_txn;
  WHEN OTHERS THEN
    v_respcode := '21';
    v_errmsg   := 'Error While Selecting Spending account Number for Card ' || SUBSTR (SQLERRM, 1, 100);
    RAISE EXP_REJECT_TXN;
  END;*/
  BEGIN
    UPDATE CMS_CARDISSUANCE_STATUS
    SET CCS_CARD_STATUS='2'
    WHERE CCS_INST_CODE=PRM_INSTCODE
    AND CCS_PAN_CODE   =V_HASH_PAN
    AND CCS_CARD_STATUS='17';
    IF SQL%ROWCOUNT    =0 THEN
      V_RESPCODE      := '21';
      V_ERRMSG        :='Card Issuance status is not updated ';
      RAISE exp_reject_txn;
    END IF;
  EXCEPTION
   when EXP_REJECT_TXN then
    RAISE;
 /* WHEN NO_DATA_FOUND THEN
    v_respcode := '21';
    V_ERRMSG   := 'Data not found in Card Issuance table ';
    RAISE exp_reject_txn;*/
  WHEN OTHERS THEN
    v_respcode := '21';
    V_ERRMSG   := 'Error While updating the  Card Issuance status' || SUBSTR (SQLERRM, 1, 100);
    RAISE EXP_REJECT_TXN;
  END;
  BEGIN
    UPDATE CMS_AVQ_STATUS
    SET CAS_Avq_FLAG   ='O'
    WHERE CAS_INST_CODE=PRM_INSTCODE
    AND CAS_PAN_CODE   =V_HASH_PAN
    AND CAS_AVQSTAT_ID =PRM_AVQ_ID;
    IF SQL%ROWCOUNT    =0 THEN
      v_respcode      := '21';
      V_ERRMSG        :='AVQ flag is not updated ';
      RAISE exp_reject_txn;
    END IF;
  EXCEPTION
  WHEN EXP_REJECT_TXN THEN
    RAISE;
 /* WHEN NO_DATA_FOUND THEN
    v_respcode := '21';
    V_ERRMSG   := 'Data not found in AVQ flag ';
    RAISE exp_reject_txn;*/
  WHEN OTHERS THEN
    v_respcode := '21';
    V_ERRMSG   := 'Error While updating the  AVQ flag' || SUBSTR (SQLERRM, 1, 100);
    RAISE EXP_REJECT_TXN;
  END;
  BEGIN
    SELECT NVL (MAX (ccd_call_seq), 0) + 1
    INTO v_call_seq
    FROM cms_calllog_details
    WHERE ccd_inst_code = ccd_inst_code
    AND ccd_call_id     = prm_call_id
    AND ccd_pan_code    = v_hash_pan;
  EXCEPTION
  WHEN NO_DATA_FOUND THEN
    v_errmsg   := 'record is not present in cms_calllog_details  ';
    v_respcode := '16';
    RAISE exp_reject_txn;
  WHEN OTHERS THEN
    v_errmsg   := 'Error while selecting frmo cms_calllog_details ' || SUBSTR (SQLERRM, 1, 100);
    v_respcode := '21';
    RAISE exp_reject_txn;
  END;
  BEGIN
    INSERT
    INTO cms_calllog_details
      (
        ccd_inst_code,
        ccd_call_id,
        ccd_pan_code,
        ccd_call_seq,
        ccd_rrn,
        ccd_devl_chnl,
        ccd_txn_code,
        ccd_tran_date,
        ccd_tran_time,
        ccd_comments,
        ccd_ins_user,
        ccd_ins_date,
        ccd_lupd_user,
        ccd_lupd_date,
        ccd_acct_no
      )
      VALUES
      (
        prm_instcode,
        prm_call_id,
        v_hash_pan,
        v_call_seq,
        prm_rrn,
        prm_delivery_channel,
        prm_txn_code,
        prm_trandate,
        prm_trantime,
        prm_remark,
        prm_ins_user,
        SYSDATE,
        prm_ins_user,
        SYSDATE,
        v_spnd_acctno
      );
  EXCEPTION
/*  WHEN exp_reject_txn THEN
    RAISE;*/
  WHEN OTHERS THEN
    v_respcode := '21';
    v_errmsg   := ' Error while inserting into cms_calllog_details ' || SQLERRM;
    RAISE exp_reject_txn;
  END;
  BEGIN
    select CAM_ACCT_BAL,
      cam_ledger_bal,cam_type_code
    into V_ACCT_BALANCE,
      v_ledger_balance,v_acct_type
    FROM cms_acct_mast
    WHERE cam_inst_code = prm_instcode
    AND cam_acct_no     = v_spnd_acctno;
  EXCEPTION
  WHEN NO_DATA_FOUND THEN
    v_errmsg   := 'account not found in master';
    v_respcode := '16';
    RAISE exp_reject_txn;
  WHEN OTHERS THEN
    v_errmsg   := 'from account master ' || SUBSTR (SQLERRM, 1, 100);
    v_respcode := '21';
    RAISE exp_reject_txn;
  end;
  /*BEGIN
    SELECT cip_param_value
    INTO v_date_format
    FROM cms_inst_param
    WHERE cip_inst_code = '1'
    AND cip_param_key   = 'CSRDATEFORMAT';
  EXCEPTION
  WHEN NO_DATA_FOUND THEN
    v_errmsg   := 'Date format value not found in master';
    v_respcode := '49';
    RAISE exp_reject_txn;
  WHEN OTHERS THEN
    v_errmsg   := 'While fetching date format from master ' || SUBSTR (SQLERRM, 1, 100);
    v_respcode := '21';
    RAISE exp_reject_txn;
  END;*/
  BEGIN
    SELECT cms_iso_respcde
    INTO prm_resp_code
    FROM cms_response_mast
    WHERE cms_inst_code      = prm_instcode
    AND cms_delivery_channel = prm_delivery_channel
    AND cms_response_id      = v_respcode;
    DBMS_OUTPUT.put_line (v_respcode);
    prm_resp_msg := v_errmsg;
  EXCEPTION
  WHEN OTHERS THEN
    prm_resp_msg  := 'Problem while selecting data from response master1 ' || v_respcode || SUBSTR (SQLERRM, 1, 100);
    PRM_RESP_CODE := '89';
    raise exp_reject_txn;
  END;
  BEGIN
  IF (v_Retdate>v_Retperiod)
    THEN
    UPDATE transactionlog
    SET CUSTFIRSTNAME = substr(v_cust_name,1,40), 
        CUSTOMERLASTNAME = substr(v_cust_name,40,50),
       remark           = prm_remark,
      ipaddress          = prm_ipaddress,
      add_ins_user       = prm_ins_user,
      add_lupd_user      = prm_ins_user
    WHERE instcode       = prm_instcode
    AND customer_card_no = v_hash_pan
    AND rrn              = prm_rrn
    AND business_date    = prm_trandate
    AND business_time    = prm_trantime
    AND delivery_channel = prm_delivery_channel
    AND txn_code         = prm_txn_code;
   else
    UPDATE VMSCMS_HISTORY.TRANSACTIONLOG_HIST --Added for VMS-5733/FSP-991
    SET CUSTFIRSTNAME = substr(v_cust_name,1,40), 
        CUSTOMERLASTNAME = substr(v_cust_name,40,50),
       remark           = prm_remark,
      ipaddress          = prm_ipaddress,
      add_ins_user       = prm_ins_user,
      add_lupd_user      = prm_ins_user
    WHERE instcode       = prm_instcode
    AND customer_card_no = v_hash_pan
    AND rrn              = prm_rrn
    AND business_date    = prm_trandate
    AND business_time    = prm_trantime
    AND delivery_channel = prm_delivery_channel
    AND txn_code         = prm_txn_code;
   end if;  
    IF SQL%ROWCOUNT      = 0 THEN
      v_respcode        := '21';
      v_errmsg          := 'Txn not updated in transactiolog for remark';
      RAISE exp_reject_txn;
    END IF;
  EXCEPTION
  WHEN exp_reject_txn THEN
    RAISE;
  WHEN OTHERS THEN
    v_respcode := '21';
    v_errmsg   := 'Error while updating into transactiolog ' || SUBSTR (SQLERRM, 1, 200);
    RAISE exp_reject_txn;
  END;
  --<<MAIN EXCEPTION>>
EXCEPTION
WHEN exp_reject_txn THEN
  ROLLBACK;
  BEGIN
    SELECT cms_iso_respcde
    INTO prm_resp_code
    FROM cms_response_mast
    WHERE cms_inst_code      = prm_instcode
    AND cms_delivery_channel = prm_delivery_channel
    AND cms_response_id      = v_respcode;
    prm_resp_msg            := v_errmsg;
  EXCEPTION
  WHEN NO_DATA_FOUND THEN
    prm_resp_msg  := 'Problem while selecting data from response master2 ' || v_respcode || SUBSTR (SQLERRM, 1, 100);
    PRM_RESP_CODE := '89';
  WHEN OTHERS THEN
    prm_resp_msg  := 'Problem while selecting data from response master2 ' || v_respcode || SUBSTR (SQLERRM, 1, 100);
    PRM_RESP_CODE := '89';
  END;
  BEGIN
    INSERT
    INTO cms_transaction_log_dtl
      (
        ctd_delivery_channel,
        ctd_txn_code,
        ctd_txn_type,
        ctd_txn_mode,
        ctd_business_date,
        ctd_business_time,
        ctd_customer_card_no,
        ctd_txn_amount,
        ctd_txn_curr,
        ctd_actual_amount,
        ctd_fee_amount,
        ctd_waiver_amount,
        ctd_servicetax_amount,
        ctd_cess_amount,
        ctd_bill_amount,
        ctd_bill_curr,
        ctd_process_flag,
        ctd_process_msg,
        ctd_rrn,
        ctd_system_trace_audit_no,
        ctd_customer_card_no_encr,
        ctd_msg_type,
        ctd_cust_acct_number,
        ctd_inst_code
      )
      VALUES
      (
        prm_delivery_channel,
        prm_txn_code,
        NULL,
        prm_txn_mode,
        prm_trandate,
        prm_trantime,
        v_hash_pan,
        NULL,
        prm_currcode,
        NULL,
        NULL,
        NULL,
        NULL,
        NULL,
        NULL,
        NULL,
        'E',
        v_errmsg,
        prm_rrn,
        prm_stan,
        v_encr_pan,
        prm_msg_type,
        v_spnd_acctno,
        prm_instcode
      );
    v_cnt           := SQL%ROWCOUNT;
    IF v_cnt         = 0 THEN
      prm_resp_code := '89';
      prm_resp_msg  := 'unsucessful records inserted in transactionlog detail 1';
    END IF;
  EXCEPTION
  WHEN OTHERS THEN
    prm_resp_code := '89';
    prm_resp_msg  := 'Problem while inserting data into transaction log1  dtl' || SUBSTR (SQLERRM, 1, 300);
  END;
  --Sn create a entry in txn log
  BEGIN
    INSERT
    INTO transactionlog
      (
        msgtype,
        rrn,
        delivery_channel,
        date_time,
        txn_code,
        txn_type,
        txn_mode,
        txn_status,
        response_code,
        business_date,
        business_time,
        customer_card_no,
        total_amount,
        currencycode,
        productid,
        categoryid,
        auth_id,
        trans_desc,
        amount,
        system_trace_audit_no,
        instcode,
        cr_dr_flag,
        customer_card_no_encr,
        proxy_number,
        reversal_code,
        customer_acct_no,
        acct_balance,
        ledger_balance,
        response_id,
        error_msg,
        add_ins_user,
        add_lupd_user,
        IPADDRESS,
        remark,time_stamp,acct_type
      )
      VALUES
      (
        prm_msg_type,
        prm_rrn,
        prm_delivery_channel,
        TO_DATE (prm_trandate
        || ' '
        || prm_trantime, 'yyyymmdd hh24miss' ),
        prm_txn_code,
        NULL,
        prm_txn_mode,
        DECODE (prm_resp_code, '00', 'C', 'F'),
        prm_resp_code,
        prm_trandate,
        prm_trantime,
        v_hash_pan,
        TRIM (TO_CHAR (0, '99999999999999990.99')),
        prm_currcode,
        v_prod_code,
        v_prod_cattype,
        v_auth_id,
        v_trans_desc,
        TRIM (TO_CHAR (0, '999999999999999990.99')),
        prm_stan,
        prm_instcode,
        'NA',
        v_encr_pan,
        v_proxynumber,
        prm_rvsl_code,
        v_spnd_acctno,
        v_acct_balance,
        v_ledger_balance,
        v_respcode,
        prm_resp_msg,
        prm_ins_user,
        prm_ins_user,
        PRM_IPADDRESS,
        prm_remark,systimestamp,v_acct_type
      );
    v_cnt           := SQL%ROWCOUNT;
    IF v_cnt         = 0 THEN
      prm_resp_code := '89';
      PRM_RESP_MSG  := 'Problem while inserting data into transaction log ';
    END IF;
  EXCEPTION
  WHEN OTHERS THEN
    ROLLBACK;
    prm_resp_code := '89';
    prm_resp_msg  := 'Problem while inserting data into transaction log ' || SUBSTR (SQLERRM, 1, 300);
  END;
  --En create a entry in txn log
END;
/
SHOW ERROR