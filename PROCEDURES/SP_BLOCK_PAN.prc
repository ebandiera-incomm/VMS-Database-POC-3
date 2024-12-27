CREATE OR REPLACE PROCEDURE VMSCMS.sp_block_pan (
   prm_instcode     IN       NUMBER,
   prm_pancode      IN       VARCHAR2,
   -- prm_mbrnumb    IN       VARCHAR2,
   prm_remark       IN       VARCHAR2,
   prm_rsncode      IN       NUMBER,
   prm_workmode     IN       NUMBER,
   prm_terminalid   IN       VARCHAR2,
   prm_source       IN       VARCHAR2,
   prm_lupduser     IN       NUMBER,
   prm_errmsg       OUT      VARCHAR2
)
AS
   v_errmsg            VARCHAR2 (500);
   v_mbrnumb           cms_appl_pan.cap_mbr_numb%TYPE;
   v_cap_prod_catg     cms_appl_pan.cap_prod_catg%TYPE;
   exp_reject_record   EXCEPTION;
   v_savepoint         NUMBER                            DEFAULT 0;
   v_txn_code          VARCHAR2 (2);
   v_txn_type          VARCHAR2 (2);
   v_txn_mode          VARCHAR2 (2);
   v_del_channel       VARCHAR2 (2);
   v_reasondesc        cms_spprt_reasons.csr_reasondesc%TYPE;
       v_hash_pan    CMS_APPL_PAN.CAP_PAN_CODE%TYPE;
 v_encr_pan    CMS_APPL_PAN.cap_pan_code_encr%TYPE;


BEGIN                                              --<< main begin starts >>--
   v_savepoint := v_savepoint + 1;
   SAVEPOINT v_savepoint;
   prm_errmsg := 'OK';

--SN CREATE HASH PAN
BEGIN
    v_hash_pan := Gethash(prm_pancode);
EXCEPTION
WHEN OTHERS THEN
v_errmsg := 'Error while converting pan ' || SUBSTR(SQLERRM,1,200);
RAISE    exp_reject_record;
END;
--EN CREATE HASH PAN

--SN create encr pan
BEGIN
    v_encr_pan := Fn_Emaps_Main(prm_pancode);
EXCEPTION
WHEN OTHERS THEN
v_errmsg := 'Error while converting pan ' || SUBSTR(SQLERRM,1,200);
RAISE    exp_reject_record;
END;
--EN create encr pan


   -- find product catg start
   BEGIN
      SELECT cap_prod_catg
        INTO v_cap_prod_catg
        FROM cms_appl_pan
       WHERE cap_pan_code = v_hash_pan --prm_pancode
        AND cap_inst_code = prm_instcode;
   EXCEPTION
      WHEN NO_DATA_FOUND
      THEN
         v_errmsg := 'Product category not defined in the master';
         RAISE exp_reject_record;
      WHEN OTHERS
      THEN
         v_errmsg :=
               'Error while selecting the product catagory'
            || SUBSTR (SQLERRM, 1, 300);
         RAISE exp_reject_record;
   END;

   -- find product catg end;

   -------------------------------- Sn get Function Master----------------------------
   BEGIN
      SELECT cfm_txn_code, cfm_txn_mode, cfm_delivery_channel, cfm_txn_type
        INTO v_txn_code, v_txn_mode, v_del_channel, v_txn_type
        FROM cms_func_mast
       WHERE cfm_func_code = 'BLOCK'
        AND  cfm_inst_code= prm_instcode;
   EXCEPTION
      WHEN OTHERS
      THEN
         prm_errmsg :=
                   'Function Master Not Defined ' || SUBSTR (SQLERRM, 1, 200);
         --RAISE exp_loop_reject_record;
         RETURN;
   END;

   ------------------------------ En get Function Master----------------------------

   ------------------------------Sn get reason code from support reason master----------------------------
            BEGIN
               SELECT csr_reasondesc
                 INTO  v_reasondesc
                 FROM cms_spprt_reasons
                WHERE csr_spprt_key = 'BLOCK'
                  AND csr_spprt_rsncode=prm_rsncode
                  AND csr_inst_code = prm_instcode
                  AND ROWNUM < 2;
            EXCEPTION
               WHEN NO_DATA_FOUND
               THEN
                  v_errmsg := 'BLOCK  reason code not present in master';
                  RAISE exp_reject_record;
               WHEN OTHERS
               THEN
                  v_errmsg :=
                        'Error while selecting reason code from master'
                     || SUBSTR (SQLERRM, 1, 200);
                  RAISE exp_reject_record;
            END;
------------------------------En get reason code from support reason master-------

   -- find member number start
   BEGIN
      SELECT cip_param_value
        INTO v_mbrnumb
        FROM cms_inst_param
       WHERE cip_inst_code = prm_instcode AND cip_param_key = 'MBR_NUMB';
   EXCEPTION
      WHEN NO_DATA_FOUND
      THEN
         v_errmsg := 'member number not defined in the master';
         RAISE exp_reject_record;
      WHEN OTHERS
      THEN
         v_errmsg :=
               'Error while selecting the member number'
            || SUBSTR (SQLERRM, 1.300);
         RAISE exp_reject_record;
   END;

   -- find member number end
   IF v_cap_prod_catg = 'P'
   THEN
      --start block pan for prepaid card
      sp_block_pan_debit (prm_instcode,
                          prm_pancode,
                          v_mbrnumb,
                          prm_remark,
                          prm_rsncode,
                          prm_lupduser,
                          prm_workmode,
                          v_errmsg
                         );
   --end block pan for prepaid card
   ELSIF v_cap_prod_catg in('D','A')
   THEN
      --start block pan for debit card
      sp_block_pan_debit (prm_instcode,
                          prm_pancode,
                          v_mbrnumb,
                          prm_remark,
                          prm_rsncode,
                          prm_lupduser,
                          prm_workmode,
                          v_errmsg
                         );

   --end of block pan for debit card
   ELSE
      v_errmsg := 'Not a valid product category to Block PAN';
      RAISE exp_reject_record;
   END IF;


      IF v_errmsg <> 'OK'
      THEN
         RAISE exp_reject_record;
      ELSE
         --start create succesfull records
         BEGIN
            INSERT INTO cms_block_detail
                        (cbd_inst_code, cbd_card_no, cbd_file_name,
                         cbd_remarks, cbd_msg24_flag, cbd_process_flag,
                         cbd_process_msg, cbd_process_mode, cbd_ins_user,
                         cbd_ins_date, cbd_lupd_user, cbd_lupd_date,cbd_card_no_encr
                        )
                 VALUES (prm_instcode, --prm_pancode
                 v_hash_pan, NULL,
                         prm_remark, 'N', 'S',
                         'Successful', 'S', prm_lupduser,
                         SYSDATE, prm_lupduser, SYSDATE,v_encr_pan
                        );
         EXCEPTION
            WHEN OTHERS
            THEN
               prm_errmsg :=
                     'Error while creating record in BLOCK PAN detail table '
                  || SUBSTR (SQLERRM, 1, 150);
               RETURN;
         END;

         --end create succesfull records
         --start create audit logs records
         BEGIN
            INSERT INTO process_audit_log
                        (pal_inst_code, pal_card_no, pal_activity_type,
                         pal_transaction_code, pal_delv_chnl, pal_tran_amt,
                         pal_source, pal_success_flag, pal_ins_user,
                         pal_ins_date, pal_process_msg, pal_reason_desc,
                         pal_remarks, pal_spprt_type,pal_card_no_encr
                        )
                 VALUES (prm_instcode,-- prm_pancode
                 v_hash_pan, 'Block',
                         v_txn_code, v_del_channel, 0,
                         prm_source, 'S', prm_lupduser,
                         SYSDATE, 'Successful', v_reasondesc,
                         prm_remark, 'S',v_encr_pan
                        );
         EXCEPTION
            WHEN OTHERS
            THEN
               prm_errmsg :=
                     'Error while creating record in Audit Log table '
                  || SUBSTR (SQLERRM, 1, 150);
               RETURN;
         END;
      --end create audit logs records
      END IF;
EXCEPTION                                                   --main exception--
   WHEN exp_reject_record
   THEN
      ROLLBACK TO v_savepoint;
      sp_blockpan_support_log (prm_instcode,
                               prm_pancode,
                               NULL,
                               prm_remark,
                               'N',
                               'E',
                               v_errmsg,
                               'S',
                               prm_lupduser,
                               SYSDATE,
                               'Block',
                               v_txn_code,
                               v_del_channel,
                               0,
                               prm_source,
                               v_reasondesc,
                               'S',
                               prm_errmsg
                              );

      IF prm_errmsg <> 'OK'
      THEN
         RETURN;
      ELSE
         prm_errmsg := v_errmsg;
      END IF;
   WHEN OTHERS
   THEN
      v_errmsg := ' Error from main ' || SUBSTR (SQLERRM, 1, 200);
      sp_blockpan_support_log (prm_instcode,
                               prm_pancode,
                               NULL,
                               prm_remark,
                               'N',
                               'E',
                               v_errmsg,
                               'S',
                               prm_lupduser,
                               SYSDATE,
                               'Block',
                               v_txn_code,
                               v_del_channel,
                               0,
                               prm_source,
                               v_reasondesc,
                               'S',
                               prm_errmsg
                              );

      IF prm_errmsg <> 'OK'
      THEN
         RETURN;
      ELSE
         prm_errmsg := v_errmsg;
      END IF;
END;                                                        --<< main end >>--
/


show error