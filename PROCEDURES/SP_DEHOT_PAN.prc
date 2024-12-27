CREATE OR REPLACE PROCEDURE VMSCMS.SP_DEHOT_PAN  (
						   prm_instcode   IN       NUMBER,
						   prm_pancode    IN       VARCHAR2,
						   prm_remark     IN       VARCHAR2,
						   prm_rsncode    IN       NUMBER,
						   prm_lupduser   IN       NUMBER,
						   prm_workmode   IN       NUMBER,
						   prm_errmsg     OUT      VARCHAR2
						)
						AS
/*************************************************
     * VERSION			:  1.0
     * Created Date		:  27/May/2010
     * Created By		:  Chinmaya Behera
     * PURPOSE			:  To handle all card hot list
     * Modified By:		:
     * Modified Date		:
   ***********************************************/
v_prod_catg            CMS_APPL_PAN.cap_prod_catg%type;
v_errmsg            VARCHAR2(500);
v_mbrnumb            CMS_APPL_PAN.cap_mbr_numb%type;
exp_reject_record        EXCEPTION;
v_savepoint            NUMBER    DEFAULT 0;
v_txn_code        VARCHAR2 (2);
v_txn_type        VARCHAR2 (2);
v_txn_mode        VARCHAR2 (2);
v_del_channel     VARCHAR2 (2);
v_reasondesc        cms_spprt_reasons.csr_reasondesc%TYPE;
  v_hash_pan    CMS_APPL_PAN.CAP_PAN_CODE%TYPE;
 v_encr_pan    CMS_APPL_PAN.cap_pan_code_encr%TYPE;


BEGIN            --<< MAIN BEGIN >>
    v_savepoint := v_savepoint + 1;
    SAVEPOINT v_savepoint;
    prm_errmsg  := 'OK';
       --SN CREATE HASH PAN
BEGIN
    v_hash_pan := Gethash(prm_pancode);
 EXCEPTION
WHEN OTHERS THEN
prm_errmsg := 'Error while converting pan ' || SUBSTR(SQLERRM,1,200);
    RETURN;
END;
--EN CREATE HASH PAN

--SN create encr pan
BEGIN
    v_encr_pan := Fn_Emaps_Main(prm_pancode);
EXCEPTION
WHEN OTHERS THEN
prm_errmsg := 'Error while converting pan ' || SUBSTR(SQLERRM,1,200);
    RETURN;
END;
--EN create encr pan

  ----------------------------------Sn find prod catg------------------------------
        BEGIN
            SELECT cap_prod_catg
            INTO   v_prod_catg
            FROM   CMS_APPL_PAN
            WHERE  cap_pan_code  = v_hash_pan--prm_pancode
            AND    cap_inst_code = prm_instcode;
        EXCEPTION
        WHEN NO_DATA_FOUND THEN
            v_errmsg := 'Product category not defined in master';
            RAISE exp_reject_record;
        WHEN OTHERS THEN
            v_errmsg := 'Error while selecting product category '|| substr(sqlerrm,1,200);
            RAISE exp_reject_record;
        END;
   ----------------------------------En find prod catg--------------------------------

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
    WHERE cfm_func_code = 'DHTLST'
      AND cfm_inst_code= prm_instcode;
  EXCEPTION
  WHEN OTHERS THEN
    prm_errmsg :='Function Master Not Defined ' || SUBSTR (SQLERRM, 1, 200);
    --RAISE exp_loop_reject_record;
    RETURN;
  END;
  ------------------------------ En get Function Master----------------------------

  ------------------------------Sn get reason code from support reason master----------------------------
            BEGIN
               SELECT csr_reasondesc
                 INTO  v_reasondesc
                 FROM cms_spprt_reasons
                WHERE csr_spprt_key = 'DHTLST'
                  AND csr_spprt_rsncode=prm_rsncode
                  AND csr_inst_code = prm_instcode
                  AND ROWNUM < 2;
            EXCEPTION
               WHEN NO_DATA_FOUND
               THEN
                  v_errmsg := 'Dehotlist reason code not present in master';
                  RAISE exp_reject_record;
               WHEN OTHERS
               THEN
                  v_errmsg :=
                        'Error while selecting reason code from master'
                     || SUBSTR (SQLERRM, 1, 200);
                  RAISE exp_reject_record;
            END;
------------------------------En get reason code from support reason master-------

  -------------------------------Sn find default member number---------------------
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
  --------------------------------En find default member number---------------------
  --------------------------------Sn check product catg-----------------------------
    IF v_prod_catg = 'P' THEN
    --Sn dehotlist for prepaid
        Sp_dehot_Pan_Debit (
                    prm_instcode,
                    prm_pancode,
                    v_mbrnumb   ,
                    prm_remark  ,
                    prm_rsncode ,
                    prm_lupduser,
                    prm_workmode ,
                    v_errmsg
                        );
    --En dehotlist for prepaid
    ELSIF v_prod_catg in('D','A') THEN
        --Sn dehotlist for debit
        Sp_dehot_Pan_Debit (
                    prm_instcode,
                    prm_pancode,
                    v_mbrnumb   ,
                    prm_remark  ,
                    prm_rsncode ,
                    prm_lupduser,
                    prm_workmode ,
                    v_errmsg
                        );
    --En de hotlist for debit
    ELSE
        v_errmsg := 'Not a valid product category for hot list';
        RAISE exp_reject_record;
    END IF;

        IF v_errmsg <> 'OK' THEN
            RAISE exp_reject_record;
        ELSE
           --Sn create successful records
            BEGIN
            INSERT INTO    CMS_DEHOTLIST_DETAIL
                    (cdd_inst_code,
                     cdd_card_no,
                    cdd_file_name,
                    cdd_remarks,
                    cdd_msg24_flag,
                    cdd_process_flag,
                    cdd_process_msg,
                    cdd_process_mode,
                    cdd_ins_user,
                    cdd_ins_date,
                    cdd_lupd_user,
                    cdd_lupd_date,
           cdd_card_no_encr
                    )
                   VALUES ( prm_instcode,
                        --prm_pancode
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
                        sysdate,v_encr_pan
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
                     pal_spprt_type,pal_card_no_encr
                    )
                      VALUES
                    (prm_instcode,
                     --prm_pancode
           v_hash_pan,
                     'Dehotlist',
                     v_txn_code,
                     v_del_channel,
                     0,
                     'HOST',
                     'S',
                     prm_lupduser,
                     sysdate,
                     'Successful',
                     v_reasondesc,
                     prm_remark,
                     'S',v_encr_pan
                     );
            EXCEPTION
             WHEN OTHERS THEN
             prm_errmsg := 'Error while creating record in detail table ' || substr(sqlerrm,1,150);
             RETURN;
            END;
         --En Create audit log records
        END IF;
    ---------------------------------En check product catg-----------------------------
EXCEPTION        --<<MAIN EXCEPTION >>
WHEN exp_reject_record THEN
ROLLBACK TO v_savepoint;
    sp_dehotlist_support_log
            (
             prm_instcode,
             prm_pancode,
             NULL,
             prm_remark,
             'N',
             'E',
             v_errmsg,
             'S',
             prm_lupduser,
             SYSDATE,
         'Dehotlist',
             v_txn_code,
             v_del_channel,
             0,
             'HOST',
             v_reasondesc,
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
    sp_dehotlist_support_log
            (
             prm_instcode,
             prm_pancode,
             NULL,
             prm_remark,
             'N',
             'E',
             v_errmsg,
             'S',
             prm_lupduser,
             SYSDATE,
         'Dehotlist',
             v_txn_code,
             v_del_channel,
             0,
            'HOST',
             v_reasondesc,
             'S',
             prm_errmsg
           );
    IF prm_errmsg <> 'OK' THEN
       RETURN;
    ELSE
       prm_errmsg := v_errmsg;
    END IF;
END;            --<< MAIN END >>
/


show error