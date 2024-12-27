CREATE OR REPLACE PROCEDURE VMSCMS.sp_acct_delink
(
   p_instcode   IN       NUMBER,
   p_acctid     IN       NUMBER,
   p_pancode    IN       VARCHAR2,
   --p_mbrnumb    IN       VARCHAR2,
   p_rsncode    IN       NUMBER,
   p_remark     IN       VARCHAR2,
   p_lupduser   IN       NUMBER,
   p_workmode   IN       NUMBER,
   --p_acctposn   out     VARCHAR2,
   p_errmsg     OUT      VARCHAR2
)
IS
v_prod_catg				 CMS_APPL_PAN.cap_prod_catg%type;
v_errmsg				 VARCHAR2(500);
v_mbrnumb				 CMS_APPL_PAN.cap_mbr_numb%type;
v_txn_code               VARCHAR2 (2);
v_txn_type               VARCHAR2 (2);
v_txn_mode               VARCHAR2 (2);
v_del_channel            VARCHAR2 (2);
v_card_stat                 CMS_APPL_PAN.cap_card_stat%type;
v_chk_panacct             number(1);
v_cafgen_flag             CMS_APPL_PAN.cap_cafgen_flag%type;
v_cust_code                 CMS_APPL_PAN.cap_cust_code%type;
v_cap_acctno             CMS_APPL_PAN.cap_acct_no%type;
exp_reject_record         EXCEPTION;
v_savepoint                 NUMBER    DEFAULT 0;
v_reasondesc        cms_spprt_reasons.csr_reasondesc%TYPE;
 v_hash_pan    CMS_APPL_PAN.CAP_PAN_CODE%TYPE;  
 v_encr_pan    CMS_APPL_PAN.cap_pan_code_encr%TYPE;
BEGIN            --<< MAIN BEGIN >>

v_savepoint := v_savepoint + 1;
SAVEPOINT v_savepoint;
p_errmsg  := 'OK';


--SN CREATE HASH PAN 
BEGIN
    v_hash_pan := Gethash(p_pancode);
EXCEPTION
WHEN OTHERS THEN
v_errmsg := 'Error while converting pan ' || SUBSTR(SQLERRM,1,200);
RAISE    exp_reject_record;
END;
--EN CREATE HASH PAN

--SN create encr pan
BEGIN
    v_encr_pan := Fn_Emaps_Main(p_pancode);
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
            SELECT cap_prod_catg , cap_card_stat,cap_cafgen_flag,cap_cust_code
            INTO   v_prod_catg , v_card_stat,v_cafgen_flag,v_cust_code
            FROM   CMS_APPL_PAN
            WHERE  cap_pan_code  =v_hash_pan-- p_pancode
            AND    cap_inst_code = p_instcode;
            
            IF v_prod_catg IS NULL THEN
            
               v_errmsg := 'Product category not defined in master';
               RAISE exp_reject_record;
            
            END IF;

        EXCEPTION

        WHEN NO_DATA_FOUND THEN
            v_errmsg := 'Pan not found in master';
            RAISE exp_reject_record;
        WHEN OTHERS THEN
            v_errmsg := 'Error while selecting product category '|| substr(sqlerrm,1,200);
            RAISE exp_reject_record;
        END;

        --------------------
        --EN FIND PROD CATG
        --------------------
        IF v_card_stat <> '1' THEN
            v_errmsg := 'Card status in not open, cannot be delinked';
            RAISE exp_reject_record;
        END IF;
        
        
        
        
        ------------------------------ Sn get Function Master----------------------------
   BEGIN
        SELECT  cfm_txn_code, 
                cfm_txn_mode, 
                cfm_delivery_channel, 
                cfm_txn_type
        INTO    v_txn_code, 
                v_txn_mode, 
                v_del_channel, 
                v_txn_type
        FROM    CMS_FUNC_MAST
        WHERE      cfm_func_code = 'DLINK1'
        AND     cfm_inst_code = p_instcode;
   EXCEPTION
      WHEN OTHERS
      THEN
         p_errmsg :=
                   'Function Master Not Defined for Delink' || SUBSTR (SQLERRM, 1, 200);
         --RAISE exp_loop_reject_record;
         RETURN;
   END;
   ------------------------------ En get Function Master----------------------------
   
   ------------------------------Sn get reason code from support reason master----------------------------
            BEGIN
               SELECT csr_reasondesc
                 INTO  v_reasondesc
                 FROM cms_spprt_reasons
                WHERE csr_spprt_key = 'DLINK1'
                  AND csr_spprt_rsncode=p_rsncode 
                  AND csr_inst_code = p_instcode
                  AND ROWNUM < 2;
            EXCEPTION
               WHEN NO_DATA_FOUND
               THEN
                  v_errmsg := 'Delink reason code not present in master';
                  RAISE exp_reject_record;
               WHEN OTHERS
               THEN
                  v_errmsg :=
                        'Error while selecting reason code from master'
                     || SUBSTR (SQLERRM, 1, 200);
                  RAISE exp_reject_record;
            END;
------------------------------En get reason code from support reason master-------
   
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
                v_errmsg := 'member number not defined in master';
                RAISE exp_reject_record;
            WHEN OTHERS THEN
                v_errmsg := 'Error while selecting member number '|| substr(sqlerrm,1,200);
                RAISE exp_reject_record;
        END;

        --------------------------------
        --EN FIND DEFAULT MEMBER NUMBER
        
        --Sn check in pan acct
        BEGIN
             SELECT 1
             INTO   v_chk_panacct
             FROM    CMS_PAN_ACCT
             WHERE  cpa_inst_code = p_instcode
             AND    cpa_pan_code  =v_hash_pan-- p_pancode
             AND    cpa_acct_id      = p_acctid
             and    cpa_mbr_numb  = v_mbrnumb;
        
        
        EXCEPTION 
             WHEN NO_DATA_FOUND THEN
                v_errmsg := 'Card is not related to account number';
                RAISE exp_reject_record;
             WHEN TOO_MANY_ROWS THEN
                v_errmsg := 'More than one record found for card and acct';
                RAISE exp_reject_record;
            WHEN OTHERS THEN
                v_errmsg := 'Error while selecting card acct relation '|| substr(sqlerrm,1,200);
                RAISE exp_reject_record;  
        END;
        --En check in pan acct
    
    ---------Sn to fetch acct no------------- /*added by amit on 24Sep'10*/
    BEGIN
      SELECT cam_acct_no
      into v_cap_acctno
      from cms_acct_mast
      where cam_inst_code= p_instcode
      and cam_acct_id= p_acctid;      
    EXCEPTION WHEN OTHERS THEN
      v_errmsg:='Error while selecting acct no. '||substr(sqlerrm,1,200);
      RAISE exp_reject_record;  
    END;
    ---------En to fetch acct no-------------
    
        ------------------------
        --SN CHECK PRODUCT CATG
        -------------------------
        IF v_prod_catg = 'P' THEN
        ------------------------------
        --SN: ACCOUNT DELINK FOR PREPAID
        -------------------------------

            null;

        -------------------------------
        --EN: ACCOUNT DELINK FOR PREPAID
        -------------------------------

        ELSIF v_prod_catg in('D','A') THEN
        
              IF v_cafgen_flag = 'N' THEN
              v_errmsg := 'CAF has to be generated atleast once for this pan';
              RAISE exp_reject_record;  
              END IF;
              

        -------------------------------
        --SN: ACCOUNT DELINK FOR DEBIT
        -------------------------------

        Sp_Delink_Acct_debit (
                    p_instcode,
                    p_acctid  ,
                    p_pancode ,
                    v_cap_acctno,
                    v_mbrnumb ,
                    p_rsncode ,
                    p_remark  ,
                    p_lupduser,
                    p_workmode,
                    v_cust_code,
                    --p_acctposn,
                    v_errmsg
                        );

            IF v_errmsg <> 'OK' THEN

                RAISE exp_reject_record;
            ELSE

                -------------------------------
                --SN CREATE SUCCESSFUL RECORDS
                -------------------------------

                BEGIN
                INSERT INTO CMS_ACT_DELINK_DETAIL (
                        cad_inst_code   ,
                        cad_card_no     ,
            cad_old_acc_no  ,
                        cad_file_name   ,
                        cad_remarks     ,
                        cad_msg24_flag  ,
                        cad_process_flag,
                        cad_process_msg ,
                        cad_process_mode,
                        cad_ins_user    ,
                        cad_ins_date    ,
                        cad_lupd_user   ,
                        cad_lupd_date ,
            cad_card_no_encr  )
                       VALUES ( p_instcode,
                            --p_pancode
                v_hash_pan,
                v_cap_acctno,
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

                    -- ROLLBACK TO v_savepoint;

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
                        (p_instcode,
                         --p_pancode
             v_hash_pan,
                         'Account Delink',
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

                        --ROLLBACK TO v_savepoint;
                           v_errmsg := 'ERROR WHILE LOGGING AUDIT FOR SUCCESS RECORDS ' || substr(sqlerrm,1,150);
                        RAISE exp_reject_record;
                END;

                ------------------------------
                --EN CREATE AUDIT LOG RECORDS
                ------------------------------

            END IF;

            -------------------------------
            --EN ACCOUNT DE LINK FOR DEBIT
            -------------------------------

        ELSE
            v_errmsg := 'NOT A VALID PRODUCT CATEGORY FOR ACCT DELINK';
            RAISE exp_reject_record;

        END IF;

        ------------------------
        --EN CHECK PRODUCT CATG
        -------------------------

EXCEPTION        --<<MAIN EXCEPTION >>

WHEN exp_reject_record THEN
ROLLBACK TO v_savepoint;

p_errmsg :=    v_errmsg    ;

    sp_act_delink_support_log
            (
             p_instcode,
             p_pancode,
             NULL,
             p_remark,
             'N',
             'E',
             v_errmsg,
             'S',
             p_lupduser,
             SYSDATE,
         'Account Delink',
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
    ROLLBACK TO v_savepoint;
    v_errmsg := ' ERROR FROM MAIN ' || substr(sqlerrm,1,200);

    p_errmsg :=    v_errmsg    ;

    sp_act_delink_support_log
            (
             p_instcode,
             p_pancode,
             NULL,
             p_remark,
             'N',
             'E',
             v_errmsg,
             'S',
             p_lupduser,
             SYSDATE,
         'Account Delink',
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