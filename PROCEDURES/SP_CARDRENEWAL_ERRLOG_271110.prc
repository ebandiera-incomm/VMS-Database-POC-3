CREATE OR REPLACE PROCEDURE VMSCMS.Sp_Cardrenewal_Errlog_271110
  (
    instcode     IN NUMBER,
    pancode      IN NUMBER,
    dispname     IN VARCHAR2,
    acctno       IN VARCHAR2,
    cardstat     IN VARCHAR2,
    exprydate    IN DATE,
    applbran     IN VARCHAR2,
    process_mode IN CHAR,
    flag         IN CHAR,
    txn_code     IN VARCHAR2,
    del_channel  IN VARCHAR2,
    errmsg       IN VARCHAR2 ,
    lupduser     IN NUMBER)
                 IS
  PRAGMA AUTONOMOUS_TRANSACTION;
BEGIN
  INSERT
  INTO CMS_REN_TEMP VALUES
    (
      pancode,
      applbran,
      cardstat,
      SUBSTR(pancode,1,6),
      flag,
      TO_CHAR(exprydate,'MON-YYYY'),
      SYSDATE,
      1,
      lupduser,
      SYSDATE,
      lupduser,
      'Renew'
    );
  INSERT
  INTO CMS_CARDRENEWAL_ERRLOG
    (
      cce_inst_code,
      cce_pan_code,
      cce_disp_name ,
      cce_acct_no ,
      cce_card_stat,
      cce_expry_date ,
      cce_error_mesg ,
      cce_ins_user
    )
    VALUES
    (
      instcode ,
      pancode ,
      dispname ,
      acctno ,
      cardstat ,
      exprydate ,
      errmsg ,
      lupduser
    ) ;
  INSERT
  INTO CMS_RENEW_DETAIL
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
      crd_lupd_date
    )
    VALUES
    (
      instcode,
      pancode,
      NULL,
      'Renew',
      'N',
      flag,
      errmsg,
      process_mode,
      lupduser,
      SYSDATE,
      lupduser,
      SYSDATE
    );
  INSERT
  INTO PROCESS_AUDIT_LOG
    (
      pal_card_no,
      pal_activity_type,
      pal_transaction_code,
      pal_delv_chnl,
      pal_tran_amt,
      pal_source,
      PAL_PROCESS_MSG,
      pal_success_flag,
      PAL_INST_CODE,
      pal_ins_user,
      pal_ins_date
    )
    VALUES
    (
      pancode,
      'Renew',
      txn_code,
      del_channel,
      0,
      'HOST',
      errmsg,
      flag,
      instcode,
      lupduser,
      SYSDATE
    );
  COMMIT;
END;
/


