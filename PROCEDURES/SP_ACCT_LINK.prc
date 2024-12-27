CREATE OR REPLACE PROCEDURE VMSCMS.sp_acct_link
(
prm_instcode	IN NUMBER,
prm_pan_code	IN VARCHAR2,
prm_new_acct_no IN VARCHAR2,
prm_remark	IN VARCHAR2,
prm_rsncode	IN NUMBER,
prm_lupduser	IN NUMBER,
prm_workmode	IN NUMBER,
prm_errmsg	out VARCHAR2
)
IS
v_prod_catg		CMS_APPL_PAN.cap_prod_catg%type;
v_errmsg		VARCHAR2(500);
v_mbrnumb		CMS_APPL_PAN.cap_mbr_numb%type;
v_tran_code		   CMS_FUNC_MAST.cfm_txn_code%TYPE;
v_tran_mode		   CMS_FUNC_MAST.cfm_txn_mode%TYPE;
v_delv_chnl		   CMS_FUNC_MAST.cfm_delivery_channel%TYPE;
exp_reject_record	EXCEPTION;
v_savepoint        NUMBER    DEFAULT 0;
v_reasondesc        cms_spprt_reasons.csr_reasondesc%TYPE;

 v_hash_pan    CMS_APPL_PAN.CAP_PAN_CODE%TYPE;  
 v_encr_pan    CMS_APPL_PAN.cap_pan_code_encr%TYPE;

 
BEGIN            --<< MAIN BEGIN >>

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


        ---------------------
        -- SN FIND PROD CATG
        --------------------
        BEGIN
            SELECT cap_prod_catg
            INTO   v_prod_catg
            FROM   CMS_APPL_PAN
            WHERE  cap_pan_code  =v_hash_pan -- prm_pan_code
            AND    cap_inst_code = prm_instcode;

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


        ----------------------------------
        --SN FIND DEFAULT MEMBER NUMBER
        ----------------------------------

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

        --------------------------------
        --EN FIND DEFAULT MEMBER NUMBER
        ---------------------------------
        ------Sn account link
        
        BEGIN
           SELECT 
               cfm_txn_code,
               cfm_txn_mode,
               cfm_delivery_channel
        INTO   v_tran_code,
               v_tran_mode,
               v_delv_chnl
        FROM   CMS_FUNC_MAST
        WHERE  cfm_inst_code = prm_instcode 
        AND       cfm_func_code = 'LINK';
   EXCEPTION
           WHEN NO_DATA_FOUND THEN
        v_errmsg :=
            'Support function acct close not defined in master ' ;
         RAISE exp_reject_record;
        WHEN TOO_MANY_ROWS THEN
        v_errmsg :=
            'More than one record found in master for acct close support func ' ;
         RAISE exp_reject_record;
         
        WHEN OTHERS
      THEN
         v_errmsg :=
            'Error while selecting acct close function detail ' || SUBSTR (SQLERRM, 1, 200);
         RAISE exp_reject_record;
      
   END;
     --En get tran code
        
        ------------------------------Sn get reason code from support reason master----------------------------
            BEGIN
               SELECT csr_reasondesc
                 INTO  v_reasondesc
                 FROM cms_spprt_reasons
                WHERE csr_spprt_key = 'LINK'
                  AND csr_spprt_rsncode=prm_rsncode 
                  AND csr_inst_code = prm_instcode
                  AND ROWNUM < 2;
            EXCEPTION
               WHEN NO_DATA_FOUND
               THEN
                  v_errmsg := 'Link reason code not present in master';
                  RAISE exp_reject_record;
               WHEN OTHERS
               THEN
                  v_errmsg :=
                        'Error while selecting reason code from master'
                     || SUBSTR (SQLERRM, 1, 200);
                  RAISE exp_reject_record;
            END;
------------------------------En get reason code from support reason master-------
        

        ------------------------
        --SN CHECK PRODUCT CATG
        -------------------------
        IF v_prod_catg = 'P' THEN
        ------------------------------
        --SN: ACCOUNT LINK FOR PREPAID
        -------------------------------

            null;

        -------------------------------
        --EN: ACCOUNT LINK FOR PREPAID
        -------------------------------

        ELSIF v_prod_catg in('D','A') THEN

        -------------------------------
        --SN: ACCOUNT LINK FOR DEBIT
        -------------------------------

        sp_acct_link_debit (
                    prm_instcode,
                    prm_rsncode,
                    prm_lupduser,
                    prm_pan_code,
                    prm_new_acct_no,
                    prm_remark  ,
                    v_mbrnumb   ,
                    prm_workmode  ,
                    v_errmsg
                        );
            IF v_errmsg <> 'OK' THEN
                RAISE exp_reject_record;
            ELSE

                -------------------------------
                --SN CREATE SUCCESSFUL RECORDS
                -------------------------------

                BEGIN
                INSERT INTO CMS_ACCT_LINK_DETAIL (
                        cad_inst_code   ,
                        cad_card_no     ,
                        cad_newacct_no  ,
                        cad_file_name   ,
                        cad_remarks     ,
                        cad_msg24_flag  ,
                        cad_process_flag,
                        cad_process_msg ,
                        cad_process_mode,
                        cad_ins_user    ,
                        cad_ins_date    ,
                        cad_lupd_user   ,
                        cad_lupd_date ,CAD_CARD_NO_ENCR
              )
                       VALUES ( prm_instcode,
                            --prm_pan_code
                v_hash_pan,
                            prm_new_acct_no,
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

                --     ROLLBACK TO v_savepoint;

                     v_errmsg := 'ERROR WHILE LOGGING SUCCESSFUL RECORDS ' || substr(sqlerrm,1,150);
                     RAISE exp_reject_record;
                END;

                -------------------------------
                --EN CREATE SUCCESSFUL RECORDS
                -------------------------------

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
                        (prm_instcode,
                         --prm_pan_code
             v_hash_pan,
                         'Account link',
                         v_tran_code,
                         v_delv_chnl,
                         0,
                         'HOST',
                         'S',
                         prm_lupduser,
                         sysdate,
                         'SUCCESSFUL',
                         v_reasondesc,
                         prm_remark,
                         'S',
             v_encr_pan
                     );
                EXCEPTION

                    WHEN OTHERS THEN

                    --    ROLLBACK TO v_savepoint;

                        v_errmsg := 'Error while LOGGING AUDIT FOR SUCCESS RECORDS ' || substr(sqlerrm,1,150);
                        RAISE exp_reject_record;
                END;

                ------------------------------
                --EN CREATE AUDIT LOG RECORDS
                ------------------------------

            END IF;

            -------------------------------
            --EN ACCOUNT LINK FOR DEBIT
            -------------------------------

        ELSE
            v_errmsg := 'NOT A VALID PRODUCT CATEGORY FOR ACCT LINK';
            RAISE exp_reject_record;

        END IF;

        ------------------------
        --EN CHECK PRODUCT CATG
        -------------------------

EXCEPTION        --<<MAIN EXCEPTION >>

WHEN exp_reject_record THEN
ROLLBACK TO v_savepoint;

prm_errmsg :=    v_errmsg    ;

    sp_actlink_support_log
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
          'Account link',
             v_tran_code,
             v_delv_chnl,
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

    v_errmsg := ' ERROR FROM MAIN ' || substr(sqlerrm,1,200);

    prm_errmsg :=    v_errmsg    ;
    ROLLBACK TO v_savepoint;

    sp_actlink_support_log
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
          'Account link',
             v_tran_code,
             v_delv_chnl,
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