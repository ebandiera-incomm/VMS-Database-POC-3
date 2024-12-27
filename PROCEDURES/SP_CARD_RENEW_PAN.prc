CREATE OR REPLACE PROCEDURE VMSCMS.sp_card_renew_pan
  (
    prm_inst_code    IN         NUMBER,
    prm_ins_date     IN         DATE,
    prm_pancode      IN         VARCHAR2,
    prm_remark       IN         VARCHAR2,
    --prm_bin_list              renew_bin_array,
    --prm_branch_list           renew_branch_array,
    prm_rsncode      IN         NUMBER,
    prm_workmode     IN         VARCHAR2,
    prm_terminalid   IN         VARCHAR2,
    prm_source       IN         VARCHAR2,
    prm_lupd_user    IN         NUMBER,
    prm_errmsg OUT              VARCHAR2
    )
AS
   v_errmsg            VARCHAR2 (500);
   v_mbrnumb           cms_appl_pan.cap_mbr_numb%TYPE;
   v_cap_prod_catg     cms_appl_pan.cap_prod_catg%TYPE;
   v_cap_card_stat     cms_appl_pan.cap_card_stat%TYPE;
   v_cap_acct_no       cms_appl_pan.cap_acct_no%TYPE;
   v_cap_appl_bran     cms_appl_pan.cap_appl_bran%TYPE;
   v_cap_disp_name     cms_appl_pan.cap_disp_name%TYPE;
   v_cap_expry_date    cms_appl_pan.cap_expry_date%TYPE;
   exp_reject_record   EXCEPTION;
   v_savepoint         NUMBER    DEFAULT 0;
   v_txn_code          VARCHAR2 (2);
   v_txn_type          VARCHAR2 (2);
   v_txn_mode          VARCHAR2 (2);
   v_del_channel       VARCHAR2 (2);
   
    v_hash_pan    CMS_APPL_PAN.CAP_PAN_CODE%TYPE;  
 v_encr_pan    CMS_APPL_PAN.cap_pan_code_encr%TYPE;
BEGIN                                                 --<< main begin start >>--
v_savepoint := v_savepoint + 1;
SAVEPOINT v_savepoint;
prm_errmsg := 'OK';

--SN CREATE HASH PAN 
BEGIN
    v_hash_pan := Gethash(prm_pancode);
EXCEPTION
WHEN OTHERS THEN
v_errmsg := 'Error while converting pan ' || SUBSTR(SQLERRM,1,200);
 RAISE exp_reject_record;
END;
--EN CREATE HASH PAN

--SN create encr pan
BEGIN
    v_encr_pan := Fn_Emaps_Main(prm_pancode);
EXCEPTION
WHEN OTHERS THEN
v_errmsg := 'Error while converting pan ' || SUBSTR(SQLERRM,1,200);
 RAISE exp_reject_record;
END;
--EN create encr pan

-- find product catg start
   BEGIN
      SELECT cap_prod_catg, cap_card_stat, cap_acct_no, cap_appl_bran, cap_disp_name, cap_expry_date
        INTO v_cap_prod_catg,v_cap_card_stat,v_cap_acct_no,v_cap_appl_bran,v_cap_disp_name,v_cap_expry_date
        FROM cms_appl_pan
       WHERE cap_pan_code = v_hash_pan-- prm_pancode 
       AND cap_inst_code = prm_inst_code;
   EXCEPTION
      WHEN NO_DATA_FOUND
      THEN
         v_errmsg := 'Product category not defined in the master';
         RAISE exp_reject_record;
      WHEN OTHERS
      THEN
         v_errmsg :='Error while selecting the product catagory'|| SUBSTR (SQLERRM, 1, 300);
         RAISE exp_reject_record;
   END;
-- find product catg end;

-------------------------------- Sn get Function Master----------------------------
   BEGIN
      SELECT cfm_txn_code, cfm_txn_mode, cfm_delivery_channel, cfm_txn_type
        INTO v_txn_code, v_txn_mode, v_del_channel, v_txn_type
        FROM cms_func_mast
       WHERE cfm_func_code = 'RENEW'
        AND  cfm_inst_code=prm_inst_code;
   EXCEPTION
      WHEN OTHERS
      THEN
         v_errmsg :='Function Master Not Defined ' || SUBSTR (SQLERRM, 1, 200);
         RAISE exp_reject_record;
   END;
------------------------------ En get Function Master----------------------------

 ------------------------------find member number start-------------------------
   BEGIN
      SELECT cip_param_value
        INTO v_mbrnumb
        FROM cms_inst_param
       WHERE cip_inst_code = prm_inst_code AND cip_param_key = 'MBR_NUMB';
   EXCEPTION
      WHEN NO_DATA_FOUND
      THEN
         v_errmsg := 'member number not defined in the master';
         RAISE exp_reject_record;
      WHEN OTHERS
      THEN
         v_errmsg :='Error while selecting the member number'|| SUBSTR (SQLERRM, 1.300);
         RAISE exp_reject_record;
   END;
------------------------------find member number start-------------------------

IF v_cap_card_stat!=1 THEN
  v_errmsg:='Card is not open for renew';
  RAISE exp_reject_record;
END IF;

IF v_cap_prod_catg='P' THEN
-------Start renew prepaid card----------
  sp_card_renew_pan_debit(
                            prm_inst_code,   
                            prm_ins_date,  
                            prm_pancode,
                            v_mbrnumb,
                            --v_cap_disp_name,
                            prm_remark,    
                            prm_rsncode,     
                            prm_workmode,    
                            prm_lupd_user,
                            v_errmsg
                          );
-------End renew prepaid card----------

-------Start renew Debit card----------
ELSIF v_cap_prod_catg in('D','A') THEN
  sp_card_renew_pan_debit(
                            prm_inst_code,   
                            prm_ins_date,  
                            prm_pancode,
                            v_mbrnumb,
                            --v_cap_disp_name,
                            prm_remark,    
                            prm_rsncode,     
                            prm_workmode,    
                            prm_lupd_user,
                            v_errmsg
                          );
ELSE
v_errmsg := 'Not a valid product category to renew PAN';
RAISE exp_reject_record;
END IF;
                          
  IF v_errmsg <> 'OK'
      THEN
         RAISE exp_reject_record;
      ELSE
      -------Start create successful records in detail table-----------------
           BEGIN
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
                crd_lupd_date,crd_card_no_encr
              )
              VALUES
              (
                prm_inst_code,
--                prm_pancode
                v_hash_pan,
                NULL,
                prm_remark,
                'N',
                'S',
                'Successful',
                'S',
                prm_lupd_user,
                SYSDATE,
                prm_lupd_user,
                SYSDATE,
                v_encr_pan
              );
          EXCEPTION
          WHEN OTHERS THEN
            v_errmsg := 'Error while inserting record in renew detail'|| SUBSTR(sqlerrm,1,200);
            RAISE exp_reject_record;
          END;
      --------------Start create successful records in detail table-----------------
      -------------------Start create a record in audit log---------------------
          BEGIN
            INSERT
            INTO PROCESS_AUDIT_LOG
              (
                pal_inst_code,
                pal_card_no,
                pal_activity_type,
                pal_transaction_code,
                pal_delv_chnl,
                pal_tran_amt,
                pal_source,
                pal_success_flag,
                PAL_PROCESS_MSG,
                pal_ins_user,
                pal_ins_date,pal_card_no_encr
              )
              VALUES
              (
                prm_inst_code,
                --prm_pancode
                v_hash_pan,
                'Renew',
                v_txn_code,
                v_del_channel,
                0,
                'HOST',
                'S',
                'Successful',
                prm_lupd_user,
                SYSDATE,v_encr_pan
              );
          EXCEPTION
          WHEN OTHERS THEN
            v_errmsg := 'Error while inserting record in audit detail'|| SUBSTR(sqlerrm,1,200);
            RAISE exp_reject_record;
          END;
      -------------------Start create a record in audit log---------------------
      END IF;
-------Start renew Debit card----------              
EXCEPTION             --<< main exception >>--
WHEN exp_reject_record then
   ROLLBACK TO v_savepoint;
   Sp_Cardrenewal_Errlog(
                          prm_inst_code,
                          prm_pancode ,
                          'Renew',
                          prm_remark,
                          v_cap_disp_name,
                          v_cap_acct_no,
                          v_cap_card_stat ,
                          v_cap_expry_date ,
                          v_cap_appl_bran,
                          'S',
                          'E',
                          v_txn_code,
                          v_del_channel,
                          v_errmsg ,
                          prm_lupd_user
                        );
      prm_errmsg:= v_errmsg;
WHEN OTHERS THEN
   v_errmsg := ' Error from main ' || SUBSTR (SQLERRM, 1, 200);
   ROLLBACK TO v_savepoint;
   Sp_Cardrenewal_Errlog(
                          prm_inst_code,
                          prm_pancode ,
                          'Renew',
                          prm_remark,                  
                          v_cap_disp_name,
                          v_cap_acct_no,
                          v_cap_card_stat ,
                          v_cap_expry_date ,
                          v_cap_appl_bran,
                          'S',
                          'E',
                          v_txn_code,
                          v_del_channel,
                          v_errmsg ,
                          prm_lupd_user
                        );
        prm_errmsg:= v_errmsg;
END;
/


show error