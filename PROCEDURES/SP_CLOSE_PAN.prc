CREATE OR REPLACE PROCEDURE VMSCMS.sp_close_pan (
p_instcode	IN  NUMBER ,
p_ipaddr    IN  VARCHAR2,
p_pan_code	IN  VARCHAR2 ,
p_rsncode	IN  NUMBER ,
p_remark	IN  varchar2 ,
p_lupduser	IN  NUMBER ,
p_workmode	IN NUMBER,
p_errmsg	OUT  VARCHAR2
)
AS

v_prod_catg		CMS_APPL_PAN.cap_prod_catg%type;
v_errmsg		VARCHAR2(500):='OK';
v_mbrnumb		CMS_APPL_PAN.cap_mbr_numb%type;
exp_reject_record	EXCEPTION;
v_savepoint		NUMBER	DEFAULT 0;
v_txn_code		      VARCHAR2 (2);
v_txn_type		      VARCHAR2 (2);
v_txn_mode		      VARCHAR2 (2);
v_del_channel		  VARCHAR2 (2);
v_reasondesc        cms_spprt_reasons.csr_reasondesc%TYPE;
 v_hash_pan    CMS_APPL_PAN.CAP_PAN_CODE%TYPE;
 v_encr_pan    CMS_APPL_PAN.cap_pan_code_encr%TYPE;
 v_applcode                   CMS_APPL_PAN.cap_appl_code%TYPE;
 v_acctno                     CMS_APPL_PAN.cap_acct_no%TYPE;                  
 v_prodcode                   CMS_APPL_PAN.cap_prod_code%TYPE;


BEGIN

SAVEPOINT v_savepoint;
p_errmsg  := 'OK';

--SN CREATE HASH PAN
BEGIN
    v_hash_pan := Gethash(p_pan_code);
EXCEPTION
WHEN OTHERS THEN
v_errmsg := 'Error while converting pan ' || SUBSTR(SQLERRM,1,200);
RAISE    exp_reject_record;
END;
--EN CREATE HASH PAN

--SN create encr pan
BEGIN
    v_encr_pan := Fn_Emaps_Main(p_pan_code);
EXCEPTION
WHEN OTHERS THEN
v_errmsg := 'Error while converting pan ' || SUBSTR(SQLERRM,1,200);
RAISE    exp_reject_record;
END;
--EN create encr pan


        ---------------------
        -- SN FIND PROD CATG
        --------------------
        BEGIN
            SELECT cap_prod_catg,CAP_APPL_CODE,CAP_ACCT_NO,CAP_PROD_CODE
            INTO   v_prod_catg,v_applcode, v_acctno, v_prodcode
            FROM   CMS_APPL_PAN
            WHERE  cap_pan_code  = v_hash_pan--p_pan_code
            AND    cap_inst_code = p_instcode;

        EXCEPTION

        WHEN NO_DATA_FOUND THEN
            v_errmsg := 'Product category not defined in master';
            RAISE exp_reject_record;
        WHEN OTHERS THEN
            v_errmsg := 'Error while selecting product category '|| substr(sqlerrm,1,200);
            RAISE exp_reject_record;
        END;

        --------------------
        --EN FIND PROD CATG
        --------------------
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
          WHERE cfm_func_code = 'CRDCLOSE'
          AND   cfm_inst_code = p_instcode;
    EXCEPTION
        WHEN OTHERS THEN
          v_errmsg :='Function Master Not Defined ' || SUBSTR (SQLERRM, 1, 200);
          RAISE exp_reject_record;
  END;
  ------------------------------ En get Function Master----------------------------

------------------------------Sn get reason code from support reason master----------------------------
            BEGIN
               SELECT csr_reasondesc
                 INTO  v_reasondesc
                 FROM cms_spprt_reasons
                WHERE csr_spprt_key = 'CARDCLOSE'
                  AND csr_spprt_rsncode=p_rsncode
                  AND csr_inst_code = p_instcode
                  AND ROWNUM < 2;
            EXCEPTION
               WHEN NO_DATA_FOUND
               THEN
                  v_errmsg := 'Card close reason code not present in master';
                  RAISE exp_reject_record;
               WHEN OTHERS
               THEN
                  v_errmsg :=
                        'Error while selecting reason code from master'
                     || SUBSTR (SQLERRM, 1, 200);
                  RAISE exp_reject_record;
            END;
------------------------------En get reason code from support reason master-------

        ----------------------------------
        --SN FIND DEFAULT MEMBER NUMBER
        ----------------------------------

        BEGIN

            SELECT cip_param_value
            INTO   v_mbrnumb
            FROM   CMS_INST_PARAM
            WHERE  cip_inst_code = p_instcode
            AND    cip_param_key = 'MBR_NUMB';

        EXCEPTION

            WHEN NO_DATA_FOUND THEN
                v_errmsg := 'memeber number not defined in master';
                RAISE exp_reject_record;
            WHEN OTHERS THEN
                v_errmsg := 'Error while selecting memeber number '|| substr(sqlerrm,1,200);
                RAISE exp_reject_record;
        END;

        --------------------------------
        --EN FIND DEFAULT MEMBER NUMBER
        ---------------------------------
        ------------------------
        --SN CHECK PRODUCT CATG
        -------------------------
        IF v_prod_catg = 'P' THEN
        ------------------------------
        --SN: CARD CLOSE FOR PREPAID
        -------------------------------

        sp_close_pan_debit (
                    p_instcode,
                    p_pan_code,
                    v_mbrnumb,
                    p_rsncode,
                    p_remark,
                    p_lupduser,
                    p_workmode,
                    v_errmsg
                )    ;


        -------------------------------
        --EN: CARD CLOSE FOR PREPAID
        -------------------------------

        ELSIF v_prod_catg in('D','A') THEN

        -------------------------------
        --SN: CARD CLOSE FOR DEBIT
        -------------------------------

        sp_close_pan_debit (
                    p_instcode,
                    p_pan_code,
                    v_mbrnumb,
                    p_rsncode,
                    p_remark,
                    p_lupduser,
                    p_workmode,
                    v_errmsg
                )    ;
        ELSE
            v_errmsg := 'NOT A VALID PRODUCT CATEGORY FOR CARD CLOSE';

            RAISE exp_reject_record;

        END IF;

        ------------------------
        --EN CHECK PRODUCT CATG
        -------------------------



            IF v_errmsg <> 'OK' THEN

                v_errmsg := 'ERROR WHILE CLOSING DEBIT CARD ' || v_errmsg ;

                RAISE exp_reject_record;
            ELSE

                -------------------------------
                --SN CREATE SUCCESSFUL RECORDS
                -------------------------------

                BEGIN
                INSERT INTO cms_crdclose_detail
                        (
                        ccd_inst_code   ,
                        ccd_card_no     ,
                        ccd_file_name   ,
                        ccd_remarks     ,
                        ccd_msg24_flag  ,
                        ccd_process_flag,
                        ccd_process_msg ,
                        ccd_process_mode,
                        ccd_ins_user    ,
                        ccd_ins_date    ,
                        ccd_lupd_user   ,
                        ccd_lupd_date,ccd_card_no_encr
                        )
                       VALUES ( p_instcode,
                            --p_pan_code
                v_hash_pan,
                            NULL,
                            p_remark,
                            'N',
                            'S',
                            'SUCCESSFUL',
                            'S',
                            p_lupduser,
                            sysdate,
                            p_lupduser,
                            sysdate,
                v_encr_pan
                  );
                EXCEPTION

                WHEN OTHERS THEN

                     ROLLBACK TO v_savepoint;

                     p_errmsg := 'ERROR WHILE LOGGING SUCCESSFUL RECORDS ' || substr(sqlerrm,1,150);
                     RETURN;
                END;

                -------------------------------
                --EN CREATE SUCCESSFUL RECORDS
                -------------------------------
                    --siva mar 24 2011
        --start for audit log success
      IF v_errmsg = 'OK'
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
                 VALUES (p_instcode, v_applcode, v_acctno,
                         v_hash_pan, v_prodcode, 'GROUP CARD CLOSE',
                         'INSERT', 'SUCCESS', p_ipaddr,
                         'CMS_PAN_SPPRT', '', v_encr_pan,
                         p_lupduser, SYSDATE
                        );
         EXCEPTION
            --excp of begin 3
            WHEN OTHERS
            THEN
               v_errmsg :=
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
                 VALUES (p_instcode, v_applcode, v_acctno,
                         v_hash_pan, v_prodcode, 'GROUP CARD CLOSE',
                         'INSERT', 'FAILURE', p_ipaddr,
                         'CMS_PAN_SPPRT', '', v_encr_pan,
                         p_lupduser, SYSDATE
                        );
         EXCEPTION
            --excp of begin 3
            WHEN OTHERS
            THEN
               v_errmsg :=
                     'Error while inserting records for audit log process'
                  || SUBSTR (SQLERRM, 1, 200);
               RETURN;
         END;
      --end insert audit table
      END IF;

      --end for failure status record
          --siva end mar 24 2011
                -------------------------------
                --SN CREATE AUDIT LOG RECORDS
                -------------------------------

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
                        (p_instcode,
                         --p_pan_code
             v_hash_pan,
                         'Card close',
                         v_txn_code,
                         v_del_channel,
                         0,
                         'HOST',
                         'S',
                         p_lupduser,
                         sysdate,
                         'SUCCESSFUL',
                         v_reasondesc,
                         p_remark,
                         'S',
             v_encr_pan
                     );
                EXCEPTION

                    WHEN OTHERS THEN

                        ROLLBACK TO v_savepoint;

                        p_errmsg := 'Error while LOGGING AUDIT FOR SUCCESS RECORDS ' || substr(sqlerrm,1,150);
                        RETURN;
                END;

                ------------------------------
                --EN CREATE AUDIT LOG RECORDS
                ------------------------------

            END IF;

            -------------------------------
            --EN ACCOUNT LINK FOR DEBIT
            -------------------------------


EXCEPTION        --<<MAIN EXCEPTION >>

WHEN exp_reject_record THEN
ROLLBACK TO v_savepoint;

p_errmsg :=    v_errmsg    ;

    sp_crdclose_support_log
            (
             p_instcode,
             p_pan_code,
             NULL,
             p_remark,
             'N',
             'E',
             v_errmsg,
             'S',
             p_lupduser,
             SYSDATE,
         'Card close',
             v_txn_code,
         v_del_channel,
             0,
            'HOST',
             v_reasondesc,
             'S',
             p_errmsg
           );

   IF p_errmsg <> 'OK' THEN
       RETURN;
    ELSE
       p_errmsg := v_errmsg;
    END IF;

WHEN OTHERS THEN

    v_errmsg := ' ERROR FROM MAIN ' || substr(sqlerrm,1,200);

    p_errmsg :=    v_errmsg    ;

    sp_crdclose_support_log
            (
             p_instcode,
             p_pan_code,
             NULL,
             p_remark,
             'N',
             'E',
             v_errmsg,
             'S',
             p_lupduser,
             SYSDATE,
         'Card close',
             v_txn_code,
         v_del_channel,
             0,
            'HOST',
             v_reasondesc,
             'S',
             p_errmsg
           );

    IF p_errmsg <> 'OK' THEN
       RETURN;
    ELSE
       p_errmsg := v_errmsg;
    END IF;
END;            --<< MAIN END >>
/


show error