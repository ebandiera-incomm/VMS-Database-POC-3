CREATE OR REPLACE PROCEDURE VMSCMS.SP_HOTLIST_PAN
 (
 prm_instcode IN NUMBER,
 prm_pan_code IN VARCHAR2,
 prm_remark   IN VARCHAR2,
 prm_rsncode  IN NUMBER,
 prm_lupduser IN NUMBER,
 prm_workmode IN NUMBER,
 prm_errmsg   out VARCHAR2
 )
IS
/*************************************************
     * VERSION             :  1.0
     * Created Date        :  27/May/2010
     * Created By          :  Chinmaya Behera
     * PURPOSE             :  To handle all card hot list
     * Modified By:        :
     * Modified Date       :
   ***********************************************/
v_prod_catg  CMS_APPL_PAN.cap_prod_catg%type;
v_errmsg  VARCHAR2(500);
v_mbrnumb  CMS_APPL_PAN.cap_mbr_numb%type;
exp_reject_record EXCEPTION;
v_savepoint  NUMBER DEFAULT 0;
 v_txn_code               VARCHAR2 (2);
   v_txn_type               VARCHAR2 (2);
   v_txn_mode               VARCHAR2 (2);
   v_del_channel            VARCHAR2 (2);
   v_reason_desc   CMS_SPPRT_REASONS.csr_reasondesc%type;
    v_hash_pan    CMS_APPL_PAN.CAP_PAN_CODE%TYPE;
 v_encr_pan    CMS_APPL_PAN.cap_pan_code_encr%TYPE;

BEGIN   --<< MAIN BEGIN >>
 v_savepoint := v_savepoint + 1;
 SAVEPOINT v_savepoint;
 prm_errmsg  := 'OK';


--SN CREATE HASH PAN
BEGIN
    v_hash_pan := Gethash(prm_pan_code);
EXCEPTION
WHEN OTHERS THEN
v_errmsg := 'Error while converting pan ' || SUBSTR(SQLERRM,1,200);
RAISE    exp_reject_record;
END;
--EN CREATE HASH PAN

--SN create encr pan
BEGIN
    v_encr_pan := Fn_Emaps_Main(prm_pan_code);
EXCEPTION
WHEN OTHERS THEN
v_errmsg := 'Error while converting pan ' || SUBSTR(SQLERRM,1,200);
RAISE    exp_reject_record;
END;
--EN create encr pan



 -- Sn find prod catg
  BEGIN
   SELECT cap_prod_catg
   INTO   v_prod_catg
   FROM   CMS_APPL_PAN
   WHERE  cap_pan_code  = v_hash_pan --prm_pan_code
   AND    cap_inst_code = prm_instcode;
  EXCEPTION
  WHEN NO_DATA_FOUND THEN
   v_errmsg := 'Product category not defined in master';
   RAISE exp_reject_record;
  WHEN OTHERS THEN
   v_errmsg := 'Error while selecting product category '|| substr(sqlerrm,1,200);
   RAISE exp_reject_record;
  END;
 --En find prod catg
  ------------------------------ Sn get Function Master----------------------------
   BEGIN
      SELECT cfm_txn_code, cfm_txn_mode, cfm_delivery_channel, cfm_txn_type
        INTO v_txn_code, v_txn_mode, v_del_channel, v_txn_type
        FROM CMS_FUNC_MAST
       WHERE cfm_func_code = 'HTLST'
         AND cfm_inst_code= prm_instcode;
   EXCEPTION
      WHEN OTHERS
      THEN
         prm_errmsg :=
                   'Function Master Not Defined ' || SUBSTR (SQLERRM, 1, 200);
         --RAISE exp_loop_reject_record;
         RETURN;
   END;
   ------------------------------ En get Function Master----------------------------
 --Sn find default member number
  BEGIN
  SELECT cip_param_value
  INTO   v_mbrnumb
  FROM   CMS_INST_PARAM
  WHERE  cip_inst_code = prm_instcode
  AND    cip_param_key = 'MBR_NUMB';
  EXCEPTION
  WHEN NO_DATA_FOUND THEN
   v_errmsg := 'memeber number not defined in master';
   RAISE exp_reject_record;
  WHEN OTHERS THEN
   v_errmsg := 'Error while selecting memeber number '|| substr(sqlerrm,1,200);
   RAISE exp_reject_record;
  END;
 --En find default member number
 --Sn find the support reasons
 BEGIN
  SELECT CSR_REASONDESC
  INTO   v_reason_desc
  FROM   CMS_SPPRT_REASONS
  WHERE  csr_inst_code    = prm_instcode
  AND    csr_spprt_rsncode = prm_rsncode;
 EXCEPTION
   WHEN NO_DATA_FOUND THEN
  v_reason_desc := 'Card Lost';
  WHEN OTHERS THEN
  v_errmsg := 'Error while selecting hotlist reason detail '|| substr(sqlerrm,1,200);
     RAISE exp_reject_record;
  END;

 --En find support reasons


 --Sn check product catg
 IF v_prod_catg = 'P' THEN
 --Sn hotlist for prepaid
  Sp_Hotlist_Pan_Debit (
     prm_instcode,
     prm_pan_code,
     v_mbrnumb   ,
     prm_remark  ,
     prm_rsncode ,
     prm_lupduser,
     prm_workmode ,
     v_errmsg
               );
 --En hotlist for prepaid
 ELSIF v_prod_catg in('D','A') THEN
 --Sn hotlist for debit
  Sp_Hotlist_Pan_Debit (
     prm_instcode,
     prm_pan_code,
     v_mbrnumb   ,
     prm_remark  ,
     prm_rsncode ,
     prm_lupduser,
     prm_workmode ,
     v_errmsg
               );
 --En hotlist for debit
 ELSE
  v_errmsg := 'Not a valid product category for hot list';
  RAISE exp_reject_record;
 END IF;

  IF v_errmsg <> 'OK' THEN
   RAISE exp_reject_record;
  ELSE
     --Sn create successful records
   BEGIN
   INSERT INTO CMS_HOTLIST_DETAIL
     (chd_inst_code,
      chd_card_no,
     chd_file_name,
     chd_remarks,
     chd_msg24_flag,
     chd_process_flag,
     chd_process_msg,
     chd_process_mode,
     chd_ins_user,
     chd_ins_date,
     chd_lupd_user,
     chd_lupd_date,
     chd_card_no_encr
     )
       VALUES ( prm_instcode,
         --prm_pan_code
         v_hash_pan,
         NULL,
         prm_remark,
         'N',
         'S',
         'SUCCESSFUL',
         'S',
         prm_lupduser,
         sysdate,
         prm_lupduser,
         sysdate,
         v_encr_pan
     );
   EXCEPTION
   WHEN OTHERS THEN
     prm_errmsg := 'Error while creating record in detail table ' || substr(sqlerrm,1,150);
     RETURN;
   END;
   --En create successful records
   --Sn Create audit log records
      BEGIN
     INSERT INTO PROCESS_AUDIT_LOG
     (
      pal_inst_code,
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
     (prm_instcode,
      --prm_pan_code
      v_hash_pan,
      'Hotlist',
      v_txn_code,
      v_del_channel,
      0,
      'HOST',
      'S',
      prm_lupduser,
      sysdate,
      'Successful',
      v_reason_desc,
      prm_remark,
      'S',
      v_encr_pan
               );
   EXCEPTION
    WHEN OTHERS THEN
    prm_errmsg := 'Error while creating record in detail table ' || substr(sqlerrm,1,150);
    RETURN;
   END;
   --En Create audit log records
  END IF;
 --En check product catg
EXCEPTION  --<<MAIN EXCEPTION >>
WHEN exp_reject_record THEN
ROLLBACK TO v_savepoint;
 sp_hotlist_support_log
      (
       prm_instcode,
       prm_pan_code,
       NULL,
       prm_remark,
       'N',
       'E',
       v_errmsg,
       'S',
       prm_lupduser,
       SYSDATE,
             'Hotlist',
       v_txn_code,
       v_del_channel,
       0,
      'HOST',
       v_reason_desc,
       'S',
       prm_errmsg
     );
 IF prm_errmsg <> 'OK' THEN
    RETURN;
 ELSE
    prm_errmsg := v_errmsg;
 END IF;
WHEN OTHERS THEN
 v_errmsg := ' Error from main ' || substr(sqlerrm,1,200);
 sp_hotlist_support_log
      (
       prm_instcode,
       prm_pan_code,
       NULL,
       prm_remark,
       'N',
       'E',
       v_errmsg,
       'S',
       prm_lupduser,
       SYSDATE,
             'Hotlist',
       v_txn_code,
       v_del_channel,
       0,
      'HOST',
       v_reason_desc,
       'S',
       prm_errmsg
     );
 IF prm_errmsg <> 'OK' THEN
    RETURN;
 ELSE
    prm_errmsg := v_errmsg;
 END IF;
END;   --<< MAIN END >>
/
SHOW ERRORS

