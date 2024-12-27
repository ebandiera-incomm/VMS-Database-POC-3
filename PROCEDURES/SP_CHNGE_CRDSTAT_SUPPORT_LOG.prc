CREATE OR REPLACE PROCEDURE VMSCMS.sp_chnge_crdstat_support_log
(
   prm_instcode  IN NUMBER,
   prm_cardno  IN VARCHAR2,
   prm_file_name  IN VARCHAR2,
   prm_old_cardstat IN VARCHAR2,
   prm_new_cardstat IN VARCHAR2,
   prm_remarks  IN VARCHAR2,
   prm_msg24_flag  IN VARCHAR2,
   prm_processs_flag IN VARCHAR2,
   prm_process_msg IN VARCHAR2,
   prm_process_mode IN VARCHAR2,
   prm_ins_user  IN VARCHAR2,
   prm_ins_date  IN DATE,
-----------------Audit log details------------
  prm_activity_type IN VARCHAR2,
  prm_tran_code  IN VARCHAR2,
  prm_delv_chnl  IN VARCHAR2,
  prm_tran_amt  IN NUMBER,
  prm_source  IN VARCHAR2,
  prm_reason_desc  IN VARCHAR2,
  prm_support_type IN VARCHAR2,
  prm_errmsg  OUT VARCHAR2
        )
is
  v_hash_pan    CMS_APPL_PAN.CAP_PAN_CODE%TYPE;  
v_encr_pan    CMS_APPL_PAN.cap_pan_code_encr%TYPE;

pragma Autonomous_transaction;
BEGIN
 prm_errmsg := 'OK';
--SN CREATE HASH PAN 
BEGIN
    v_hash_pan := Gethash(prm_cardno);
EXCEPTION
WHEN OTHERS THEN
prm_errmsg := 'Error while converting pan ' || SUBSTR(SQLERRM,1,200);
 RETURN;
END;
--EN CREATE HASH PAN

--SN create encr pan
BEGIN
    v_encr_pan := Fn_Emaps_Main(prm_cardno);
EXCEPTION
WHEN OTHERS THEN
prm_errmsg := 'Error while converting pan ' || SUBSTR(SQLERRM,1,200);
 RETURN;
END;
--EN create encr pan


 --Sn insert into reissue detail
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
                ccd_card_no_encr
                                )
                            VALUES(
                                prm_instcode,
                            --    prm_cardno
              v_hash_pan,
                                NULL,
                                prm_old_cardstat,
                                prm_new_cardstat,
                                prm_remarks,
                                prm_msg24_flag,
                                prm_processs_flag,
                                prm_process_msg,
                                prm_process_mode,
                                prm_ins_user,
                                prm_ins_date,
                                prm_ins_user,
                                prm_ins_date,
                v_encr_pan                        
                                );
--En create record u
 EXCEPTION
 WHEN OTHERS THEN
 prm_errmsg := 'Error while creating record in card stat detail table ' || substr(sqlerrm,1,150);
 RETURN;
 END;
 --En insert into reissue detail
 --Sn insert in audit log
 BEGIN
   INSERT INTO PROCESS_AUDIT_LOG
   (pal_inst_code,
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
    pal_card_no_encr
   )
              VALUES
    (
      prm_instcode,
      --prm_cardno
      v_hash_pan,
      prm_activity_type,
      prm_tran_code,
      prm_delv_chnl,
      prm_tran_amt,
      prm_source,
      prm_processs_flag,
      prm_ins_user,
      prm_ins_date,
      prm_process_msg,
      prm_reason_desc,
      prm_remarks,
      prm_support_type,
      v_encr_pan
                     );
 EXCEPTION
  WHEN OTHERS THEN
  prm_errmsg := 'Error while creating record in audit log table ' || substr(sqlerrm,1,150);
  RETURN;
 END;
 --En insert into audit log
   commit;
EXCEPTION
WHEN OTHERS THEN
prm_errmsg := 'Error while creating record in log table ' || substr(sqlerrm,1,150);
RETURN;
END;
/


show error