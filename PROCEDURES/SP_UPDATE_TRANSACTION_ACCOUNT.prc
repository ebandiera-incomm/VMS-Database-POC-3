CREATE OR REPLACE PROCEDURE VMSCMS.Sp_Update_Transaction_Account
(
prm_inst_code           NUMBER,
prm_tran_date            DATE,
prm_prod_code           VARCHAR2,
prm_prod_cattype        VARCHAR2,
prm_tran_amt            NUMBER,
prm_func_code           VARCHAR2,
prm_txn_code             VARCHAR2,
prm_tran_type           VARCHAR2,
prm_rrn                            VARCHAR2,
prm_terminal_id            VARCHAR,
prm_delivery_channel    VARCHAR2,
prm_txn_mode               VARCHAR2,
prm_card_no             VARCHAR2,
prm_fee_code            VARCHAR2,
prm_fee_amt                NUMBER,
prm_fee_cracct_no VARCHAR2,
prm_fee_dracct_no VARCHAR2,
prm_servicetax_calcflag        VARCHAR2,
prm_cess_calcflag                     VARCHAR2,
prm_servicetax_amount        NUMBER,
prm_servicetax_cracct_no    VARCHAR2,
prm_servicetax_dracct_no    VARCHAR2,
prm_cess_amount                        NUMBER,
prm_cess_cracct_no            VARCHAR2,
prm_cess_dracct_no            VARCHAR2,
prm_lupd_user                NUMBER,
prm_resp_cde  OUT    VARCHAR2,
prm_err_msg     OUT     VARCHAR2
)
IS
v_cr_gl_code            CMS_FUNC_PROD.cfp_crgl_code%TYPE;
v_crgl_catg             CMS_FUNC_PROD.cfp_crgl_catg%TYPE;
v_crsubgl_code          CMS_FUNC_PROD.cfp_crsubgl_code%TYPE;
v_cracct_no             CMS_FUNC_PROD.cfp_cracct_no%TYPE;
v_dr_gl_code            CMS_FUNC_PROD.cfp_drgl_code%TYPE;
v_drgl_catg             CMS_FUNC_PROD.cfp_drgl_catg%TYPE;
v_drsubgl_code          CMS_FUNC_PROD.cfp_drsubgl_code%TYPE;
v_dracct_no             CMS_FUNC_PROD.cfp_dracct_no%TYPE;
v_fee_cr_gl_code    CMS_PRODCATTYPE_FEES.cpf_crgl_code%TYPE;
v_fee_crgl_catg        CMS_PRODCATTYPE_FEES.cpf_crgl_catg%TYPE;
v_fee_crsubgl_code    CMS_PRODCATTYPE_FEES.cpf_crsubgl_code%TYPE;
v_fee_cracct_no        CMS_PRODCATTYPE_FEES.cpf_cracct_no%TYPE;
v_fee_dr_gl_code    CMS_PRODCATTYPE_FEES.cpf_drgl_code%TYPE;
v_fee_drgl_catg        CMS_PRODCATTYPE_FEES.cpf_drgl_catg%TYPE;
v_fee_drsubgl_code    CMS_PRODCATTYPE_FEES.cpf_drsubgl_code%TYPE;
v_fee_dracct_no        CMS_PRODCATTYPE_FEES.cpf_dracct_no%TYPE;
v_gl_errmsg                VARCHAR2(500);
v_gl_upd_flag         TRANSACTIONLOG .GL_UPD_FLAG%TYPE;
v_servicetax_cracct_no                                   CMS_PRODCATTYPE_FEES.cpf_st_cracct_no%TYPE;
v_servicetax_dracct_no                                  CMS_PRODCATTYPE_FEES.cpf_st_dracct_no%TYPE;
v_cess_cracct_no                                           CMS_PRODCATTYPE_FEES.cpf_cess_cracct_no%TYPE;
v_cess_dracct_no                                           CMS_PRODCATTYPE_FEES.cpf_cess_dracct_no%TYPE;

/*CURSOR C IS
            SELECT  cfm_fee_code fee_code,cfm_fee_amt fee_amt,
                cpf_crgl_code,cpf_crgl_catg,cpf_crsubgl_code,cpf_cracct_no,
                cpf_drgl_code,cpf_drgl_catg,cpf_drsubgl_code,cpf_dracct_no
            FROM    CMS_FEE_MAST,CMS_PRODCATTYPE_FEES
            WHERE    cpf_func_code = prm_func_code
            AND    cpf_prod_code = prm_prod_code
            AND    cpf_card_type = prm_prod_cattype
            AND    cfm_inst_code  = cpf_inst_code
            AND    cfm_fee_code  = cpf_fee_code;  */


BEGIN
             prm_resp_cde := '1';
            prm_err_msg   := 'OK';

            IF prm_tran_type IN ( 'CR'  , 'DR') THEN
        --Sn find tran type and update the concern acct for transaction amount
                  --SN select gl entries
                  BEGIN
                                SELECT  cfp_crgl_code,
                                        cfp_crgl_catg,
                                        cfp_crsubgl_code,
                                        cfp_cracct_no,
                                        cfp_drgl_code,
                                        cfp_drgl_catg,
                                        cfp_drsubgl_code,
                                        cfp_dracct_no
                                INTO
                                        v_cr_gl_code  ,
                                        v_crgl_catg   ,
                                        v_crsubgl_code,
                                        v_cracct_no   ,
                                        v_dr_gl_code  ,
                                        v_drgl_catg   ,
                                        v_drsubgl_code,
                                        v_dracct_no
                                FROM    CMS_FUNC_PROD
                                WHERE  CFP_INST_CODE = prm_inst_code AND  CFP_FUNC_CODE = prm_func_code
                                AND           CFP_PROD_CODE = prm_prod_code
                                AND           CFP_PROD_CATTYPE =  prm_prod_cattype  ;
                                IF trim(v_cracct_no) IS NULL AND trim(v_dracct_no) IS NULL THEN
                                                        prm_resp_cde := '999';
                                                     prm_err_msg := 'Both credit and debit account cannot be null for a transaction code ' || prm_txn_code || ' Function code ' ||  prm_func_code;
                                                     RETURN;
                                END IF;
                                IF TRIM(v_cracct_no) IS NULL THEN
                                                        v_cracct_no := prm_card_no;
                                END IF;
                                IF  TRIM(v_dracct_no) IS NULL THEN
                                        v_dracct_no :=  prm_card_no ;
                                END IF;

                                IF trim(v_cracct_no) = trim(v_dracct_no)    THEN
                                           prm_resp_cde := '21';
                                        prm_err_msg := 'Both debit and credit account cannot be same';
                                        RETURN;
                                END IF;

                   EXCEPTION
                                WHEN    NO_DATA_FOUND THEN
                                        prm_resp_cde := '21';
                                        prm_err_msg := 'DEBIT AND CREDIT GL not defined';
                                        RETURN;
                                        WHEN    OTHERS THEN
                                        prm_resp_cde := '21';
                                        prm_err_msg := 'Problem while processing transaction amount' || SUBSTR ( SQLERRM, 1, 250);
                                        RETURN;
                       END;
                 --En select gl entries

                                --SN CREDIT THE CONCERN ACCOUNT
                                IF  v_cracct_no = prm_card_no THEN
                                        BEGIN
                                                /*UPDATE CMS_ACCT_MAST
                                                SET    cam_acct_bal  = cam_acct_bal + prm_tran_amt
                                                WHERE  cam_inst_code = prm_inst_code
                                                AND    cam_acct_no   =  v_cracct_no;*/
                                                
                                                UPDATE CMS_ACCT_MAST
                                                SET    cam_acct_bal  = cam_acct_bal + prm_tran_amt,
                                                -- LEdger balance updated, as the card can be loaded at the time of issuance itself -- changes done on 4th July 2011
                                                       CAM_LEDGER_BAL = CAM_LEDGER_BAL + prm_tran_amt 
                                                WHERE  cam_inst_code = prm_inst_code
                                                AND    cam_acct_no   =
                                        /*  Get the account number from the PAN master table using the card number. 
                                        *   This subquery needs to be removed to have account number from the input. 
                                        *   So that at the time of transaction the accoutn numebr will be passed
                                        */                                                  
                                                (select cap_acct_no from cms_appl_pan where cap_pan_code = gethash(v_cracct_no));   
                                                
                                                IF SQL%ROWCOUNT = 0 THEN
                                                                 prm_resp_cde := '21';
                                                                 prm_err_msg := 'Problem while updating in account master for transaction tran type ' || prm_tran_type ;
                                                                   RETURN;
                                                END IF;
                                             END ;
                                ELSE
                                                --Sn insert a record into EODUPDATE_ACCT
                                                BEGIN

                                                        sp_ins_eodupdate_acct  
                                                        (
                                                        prm_rrn ,
                                                        prm_terminal_id ,
                                                        prm_delivery_channel,
                                                        prm_txn_code,
                                                        prm_txn_mode ,
                                                        prm_tran_date,
                                                        prm_card_no ,
                                                        v_cracct_no,
                                                        prm_tran_amt ,
                                                        'C',
                                                        prm_inst_code,
                                                    --    prm_lupd_user,
                                                        --prm_tran_date,    
                                                        prm_err_msg
                                                        
                                                        );

                                                        IF prm_err_msg <> 'OK' THEN
                                                                  prm_resp_cde := '21';
                                                                RETURN;
                                                        END IF;

                                                END;

                                END IF;
                                                --En  insert a record into EODUPDATE_ACCT

                                --EN CREDIT THE CONCERN ACCOUNT
                        --SN DEBIT THE  CONCERN ACCOUNT
                        IF  v_dracct_no = prm_card_no THEN
                                    BEGIN
                                                        UPDATE CMS_ACCT_MAST
                                                        SET    cam_acct_bal  =  cam_acct_bal - prm_tran_amt,
                                                        -- LEdger balance updated, as the card can be loaded at the time of issuance itself -- changes done on 4th July 2011
                                                               CAM_LEDGER_BAL = CAM_LEDGER_BAL - prm_tran_amt 
                                                        WHERE  cam_inst_code =  prm_inst_code
                                                        AND    cam_acct_no   =  --v_dracct_no;
                                        /*  Get the account number from the PAN master table using the card number. 
                                        *   This subquery needs to be removed to have account number from the input. 
                                        *   So that at the time of transaction the accoutn numebr will be passed
                                        */                                                  
                                                (select cap_acct_no from cms_appl_pan where cap_pan_code = gethash(v_dracct_no));
                                                          IF SQL%ROWCOUNT = 0 THEN
                                                           prm_resp_cde := '21';
                                                           prm_err_msg := 'Problem while updating in account master for transaction tran type ' || prm_tran_type;
                                                           RETURN;
                                                           END IF;
                                    END;
                        ELSE
                                                --Sn insert a record into EODUPDATE_ACCT
                                    BEGIN

                                                        sp_ins_eodupdate_acct
                                                        (
                                                        prm_rrn ,
                                                        prm_terminal_id ,
                                                        prm_delivery_channel,
                                                        prm_txn_code,
                                                        prm_txn_mode ,
                                                        prm_tran_date,
                                                        prm_card_no ,
                                                        v_dracct_no,
                                                        prm_tran_amt ,
                                                        'D',
                                                        prm_inst_code,
--                                                        prm_lupd_user,
--                                                        prm_tran_date    ,
                                                        prm_err_msg
                                                        );

                                                        IF prm_err_msg <> 'OK' THEN
                                                                  prm_resp_cde := '21';
                                                                RETURN;
                                                        END IF;

                                                END;

                                --EN DEBIT THE  CONCERN ACCOUNT
                END IF;

                END IF;

        --En find tran type and update the concern acct for transaction amount
 IF   prm_fee_amt     <> 0 THEN
        BEGIN        --<< FEE begin >>
            v_fee_cracct_no := prm_fee_cracct_no;
            v_fee_dracct_no := prm_fee_dracct_no;

                IF trim(v_fee_cracct_no) IS NULL AND trim(v_fee_dracct_no) IS NULL THEN
                prm_resp_cde := '21';
                                prm_err_msg := 'Both credit and debit account cannot be null for a fee ' || prm_fee_code || ' Function code ' || prm_func_code;
                RETURN;
                                END IF;
                                IF TRIM(v_fee_cracct_no) IS NULL THEN
                        v_fee_cracct_no := prm_card_no;
                END IF;
                IF  TRIM(v_fee_dracct_no) IS NULL THEN
                    v_fee_dracct_no :=  prm_card_no ;
                END IF;

                                IF trim(v_fee_cracct_no) = trim(v_fee_dracct_no)    THEN
                                           prm_resp_cde := '21';
                                        prm_err_msg := 'Both debit and credit fee account cannot be same';
                                        RETURN;
                                END IF;

            IF v_fee_dracct_no =  prm_card_no THEN
                --SN DEBIT THE  CONCERN FEE  ACCOUNT
                      BEGIN
                                    UPDATE CMS_ACCT_MAST
                                    SET    cam_acct_bal  = cam_acct_bal - prm_fee_amt,
                                    -- LEdger balance updated, as the card can be loaded at the time of issuance itself -- changes done on 4th July 2011
                                           CAM_LEDGER_BAL = CAM_LEDGER_BAL - prm_fee_amt 
                                    WHERE  cam_inst_code = prm_inst_code
                                    AND    cam_acct_no   =--v_fee_dracct_no ;
                          /*  Get the account number from the PAN master table using the card number. 
                           *   This subquery needs to be removed to have account number from the input. 
                           *   So that at the time of transaction the accoutn numebr will be passed
                           */                                                  
                                    (select cap_acct_no from cms_appl_pan where cap_pan_code = gethash(v_dracct_no));
                                    IF SQL%ROWCOUNT = 0 THEN
                                    prm_resp_cde := '21';
                                    prm_err_msg := 'Problem while updating in account master for transaction for transaction tran type ' || prm_tran_type;
                                    RETURN;
                                    END IF;
                        END;

                ELSE
                                                --Sn insert a record into EODUPDATE_ACCT
                                    BEGIN

                                                        sp_ins_eodupdate_acct
                                                        (
                                                        prm_rrn ,
                                                        prm_terminal_id ,
                                                        prm_delivery_channel,
                                                        prm_txn_code,
                                                        prm_txn_mode ,
                                                        prm_tran_date,
                                                        prm_card_no ,
                                                        v_fee_dracct_no,
                                                        prm_fee_amt ,
                                                        'D',
                                                        prm_inst_code,
--                                                        prm_lupd_user,
--                                                        prm_tran_date    ,
                                                        prm_err_msg
                                                        );

                                                        IF prm_err_msg <> 'OK' THEN
                                                                  prm_resp_cde := '21';
                                                                RETURN;
                                                        END IF;

                                                END;
                                    --En insert a record into EODUPDATE_ACCT
                    END IF;
                --EN DEBIT THE  CONCERN FEE  ACCOUNT
                --SN CREDIT THE CONCERN FEE ACCOUNT
                IF v_fee_cracct_no =  prm_card_no THEN
                            BEGIN
                            UPDATE CMS_ACCT_MAST
                            SET    cam_acct_bal  = cam_acct_bal + prm_fee_amt,
                            -- LEdger balance updated, as the card can be loaded at the time of issuance itself -- changes done on 4th July 2011
                                   CAM_LEDGER_BAL = CAM_LEDGER_BAL + prm_fee_amt 
                            WHERE  cam_inst_code = prm_inst_code
                                AND    cam_acct_no   =  --v_fee_cracct_no;
                            /*  Get the account number from the PAN master table using the card number. 
                             *   This subquery needs to be removed to have account number from the input. 
                             *   So that at the time of transaction the accoutn numebr will be passed
                             */                                                  
                                (select cap_acct_no from cms_appl_pan where cap_pan_code = gethash(v_fee_cracct_no));    
                            IF SQL%ROWCOUNT = 0 THEN
                            prm_resp_cde := '21';
                            prm_err_msg := 'Problem while updating in account master  for transaction tran type ' || prm_tran_type;
                            RETURN;
                            END IF;
                             END;
                ELSE
                                                --Sn insert a record into EODUPDATE_ACCT
                                    BEGIN

                                                        sp_ins_eodupdate_acct
                                                        (
                                                        prm_rrn ,
                                                        prm_terminal_id ,
                                                        prm_delivery_channel,
                                                        prm_txn_code,
                                                        prm_txn_mode ,
                                                        prm_tran_date,
                                                        prm_card_no ,
                                                        v_fee_cracct_no,
                                                        prm_fee_amt ,
                                                        'C',
                                                        prm_inst_code,
--                                                        prm_lupd_user,
--                                                        prm_tran_date    ,
                                                        prm_err_msg
                                                        );

                                                        IF prm_err_msg <> 'OK' THEN
                                                                  prm_resp_cde := '21';
                                                                RETURN;
                                                        END IF;

                                                END;
                                    --En insert a record into EODUPDATE_ACCT
                    END IF;
                --EN CREDIT THE CONCERN FEE ACCOUNT

                ----SN service tax---
        IF         prm_servicetax_calcflag    = '1' THEN
                v_servicetax_cracct_no                                   :=    prm_servicetax_cracct_no     ;
                v_servicetax_dracct_no                                  :=    prm_servicetax_dracct_no    ;

                IF trim(v_servicetax_cracct_no) IS NULL AND trim(v_servicetax_dracct_no) IS NULL THEN
                                   prm_resp_cde := '21';
                                prm_err_msg := 'Both credit and debit account cannot be null for a fee ' || prm_fee_code || ' Function code ' || prm_func_code;
                RETURN;
                END IF;
                                    IF TRIM(v_servicetax_cracct_no) IS NULL THEN
                                                        v_servicetax_cracct_no := prm_card_no;
                                END IF;

                                IF  TRIM(v_servicetax_dracct_no) IS NULL THEN
                                        v_servicetax_dracct_no :=  prm_card_no ;
                                END IF;

                                IF TRIM(v_servicetax_cracct_no)  = TRIM(v_servicetax_dracct_no)     THEN
                                           prm_resp_cde := '21';
                                        prm_err_msg := 'Both debit and credit service tax account cannot be same';
                                        RETURN;
                                END IF;

                IF v_servicetax_dracct_no =  prm_card_no THEN
                        --SN  debit service tax amount from cmncern account
                                    BEGIN
                                                UPDATE CMS_ACCT_MAST
                                                SET    cam_acct_bal  = cam_acct_bal - prm_servicetax_amount,
                                                -- LEdger balance updated, as the card can be loaded at the time of issuance itself -- changes done on 4th July 2011
                                                       CAM_LEDGER_BAL = CAM_LEDGER_BAL - prm_servicetax_amount
                                                WHERE  cam_inst_code = prm_inst_code
                                                AND    cam_acct_no   = --v_servicetax_dracct_no ;
                                      /*  Get the account number from the PAN master table using the card number. 
                                       *   This subquery needs to be removed to have account number from the input. 
                                       *   So that at the time of transaction the accoutn numebr will be passed
                                       */                                                  
                                               (select cap_acct_no from cms_appl_pan where cap_pan_code = gethash(v_servicetax_dracct_no));          
                                                IF SQL%ROWCOUNT = 0 THEN
                                                prm_resp_cde := '21';
                                                prm_err_msg := 'Problem while updating in account master for transaction for transaction tran type ' || prm_tran_type;
                                                RETURN;
                                                END IF;
                                    END;

                        ELSE
                                                --Sn insert a record into EODUPDATE_ACCT
                                    BEGIN

                                                        sp_ins_eodupdate_acct
                                                        (
                                                        prm_rrn ,
                                                        prm_terminal_id ,
                                                        prm_delivery_channel,
                                                        prm_txn_code,
                                                        prm_txn_mode ,
                                                        prm_tran_date,
                                                        prm_card_no ,
                                                        v_servicetax_dracct_no,
                                                        prm_servicetax_amount     ,
                                                        'D',
                                                        prm_inst_code,
--                                                        prm_lupd_user,
--                                                        prm_tran_date    ,
                                                        prm_err_msg
                                                        );

                                                        IF prm_err_msg <> 'OK' THEN
                                                                  prm_resp_cde := '21';
                                                                RETURN;
                                                        END IF;

                                                END;
                                    --En insert a record into EODUPDATE_ACCT
                    END IF;

                --En debit the service tax amount from cmncern account
                IF v_servicetax_cracct_no =  prm_card_no THEN
                --SN  credit service tax amount from cmncern account
                        BEGIN
                                     UPDATE CMS_ACCT_MAST
                                    SET    cam_acct_bal  = cam_acct_bal + prm_servicetax_amount,
                                    -- LEdger balance updated, as the card can be loaded at the time of issuance itself -- changes done on 4th July 2011
                                           CAM_LEDGER_BAL = CAM_LEDGER_BAL + prm_servicetax_amount
                                    WHERE  cam_inst_code = prm_inst_code
                                    AND    cam_acct_no   = --v_servicetax_cracct_no ;
                                    /*  Get the account number from the PAN master table using the card number. 
                                       *   This subquery needs to be removed to have account number from the input. 
                                       *   So that at the time of transaction the accoutn numebr will be passed
                                       */                                                  
                                               (select cap_acct_no from cms_appl_pan where cap_pan_code = gethash(v_servicetax_cracct_no));
                                    IF SQL%ROWCOUNT = 0 THEN
                                    prm_resp_cde := '21';
                                    prm_err_msg := 'Problem while updating in account master for transaction for transaction tran type ' || prm_tran_type;
                                    RETURN;
                                    END IF;
                        END;

                ELSE
                                                --Sn insert a record into EODUPDATE_ACCT
                                    BEGIN

                                                        sp_ins_eodupdate_acct
                                                        (
                                                        prm_rrn ,
                                                        prm_terminal_id ,
                                                        prm_delivery_channel,
                                                        prm_txn_code,
                                                        prm_txn_mode ,
                                                        prm_tran_date,
                                                        prm_card_no ,
                                                        v_servicetax_cracct_no,
                                                        prm_servicetax_amount     ,
                                                        'C',
                                                        prm_inst_code,
--                                                        prm_lupd_user,
--                                                        prm_tran_date    ,
                                                        prm_err_msg
                                                        );

                                                        IF prm_err_msg <> 'OK' THEN
                                                                  prm_resp_cde := '21';
                                                                RETURN;
                                                        END IF;

                                                END;
                --En insert a record into EODUPDATE_ACCT
                END IF;
                --En credit  the service tax amount from cmncern account

                ----SN CESS---
                IF prm_cess_calcflag     = '1' THEN
                v_cess_cracct_no    :=         prm_cess_cracct_no;
                v_cess_dracct_no   :=       prm_cess_dracct_no;


                IF trim(v_cess_cracct_no) IS NULL AND trim(v_cess_dracct_no) IS NULL THEN
                                   prm_resp_cde := '21';
                                prm_err_msg := 'Both credit and debit account cannot be null for a fee ' || prm_fee_code || ' Function code ' || prm_func_code;
                RETURN;
                END IF;
                                    IF TRIM(v_cess_cracct_no) IS NULL THEN
                                                       v_cess_cracct_no  := prm_card_no;
                                END IF;
                                IF  TRIM(v_cess_dracct_no) IS NULL THEN
                                        v_cess_dracct_no   :=  prm_card_no ;
                                END IF;

                                IF trim(v_cess_cracct_no) = trim(v_cess_dracct_no)    THEN
                                           prm_resp_cde := '21';
                                        prm_err_msg := 'Both debit and credit account cannot be same';
                                        RETURN;
                                END IF;


                --SN  debit cess amount from cmncern account
                IF v_cess_dracct_no = prm_card_no THEN
                        BEGIN
                                     UPDATE CMS_ACCT_MAST
                                    SET    cam_acct_bal  = cam_acct_bal - prm_cess_amount,
                                    -- LEdger balance updated, as the card can be loaded at the time of issuance itself -- changes done on 4th July 2011
                                           CAM_LEDGER_BAL = CAM_LEDGER_BAL - prm_cess_amount
                                    WHERE  cam_inst_code = prm_inst_code
                                    AND    cam_acct_no   = --v_cess_dracct_no ;
                                    /*  Get the account number from the PAN master table using the card number. 
                                     *   This subquery needs to be removed to have account number from the input. 
                                     *   So that at the time of transaction the accoutn numebr will be passed
                                     */                                                  
                                     (select cap_acct_no from cms_appl_pan where cap_pan_code = gethash(v_cess_dracct_no));
                                    IF SQL%ROWCOUNT = 0 THEN
                                    prm_resp_cde := '21';
                                    prm_err_msg := 'Problem while updating in account master for transaction for transaction tran type ' || prm_tran_type;
                                    RETURN;
                                    END IF;
                        END;
                ELSE
                                                --Sn insert a record into EODUPDATE_ACCT
                                    BEGIN

                                                        sp_ins_eodupdate_acct
                                                        (
                                                        prm_rrn ,
                                                        prm_terminal_id ,
                                                        prm_delivery_channel,
                                                        prm_txn_code,
                                                        prm_txn_mode ,
                                                        prm_tran_date,
                                                        prm_card_no ,
                                                        v_cess_dracct_no,
                                                        prm_cess_amount ,
                                                        'D',
                                                        prm_inst_code,
--                                                        prm_lupd_user,
--                                                        prm_tran_date    ,
                                                        prm_err_msg
                                                        );

                                                        IF prm_err_msg <> 'OK' THEN
                                                                  prm_resp_cde := '21';
                                                                RETURN;
                                                        END IF;

                                                END;
                --En insert a record into EODUPDATE_ACCT
                END IF;
                --En debit the cess amount from cmncern account

                --SN  credit cess  amount from cmncern account
                IF v_cess_cracct_no = prm_card_no THEN
                BEGIN
                             UPDATE CMS_ACCT_MAST
                            SET    cam_acct_bal  = cam_acct_bal +prm_cess_amount,
                            -- LEdger balance updated, as the card can be loaded at the time of issuance itself -- changes done on 4th July 2011
                                   CAM_LEDGER_BAL = CAM_LEDGER_BAL + prm_cess_amount
                            WHERE  cam_inst_code = prm_inst_code
                            AND    cam_acct_no   = --v_cess_cracct_no ;
                            /*  Get the account number from the PAN master table using the card number. 
                             *   This subquery needs to be removed to have account number from the input. 
                             *   So that at the time of transaction the accoutn numebr will be passed
                             */                                                  
                             (select cap_acct_no from cms_appl_pan where cap_pan_code = gethash(v_cess_cracct_no));
                            
                            IF SQL%ROWCOUNT = 0 THEN
                            prm_resp_cde := '21';
                            prm_err_msg := 'Problem while updating in account master for transaction for transaction tran type ' || prm_tran_type;
                            RETURN;
                            END IF;
                END;
                ELSE
                                                --Sn insert a record into EODUPDATE_ACCT
                                    BEGIN

                                                        sp_ins_eodupdate_acct
                                                        (
                                                        prm_rrn ,
                                                        prm_terminal_id ,
                                                        prm_delivery_channel,
                                                        prm_txn_code,
                                                        prm_txn_mode ,
                                                        prm_tran_date,
                                                        prm_card_no ,
                                                        v_cess_cracct_no,
                                                        prm_cess_amount     ,
                                                        'C',
                                                        prm_inst_code,
--                                                        prm_lupd_user,
--                                                        prm_tran_date    ,
                                                        prm_err_msg
                                                        );

                                                        IF prm_err_msg <> 'OK' THEN
                                                                  prm_resp_cde := '21';
                                                                RETURN;
                                                        END IF;

                                                END;
                --En insert a record into EODUPDATE_ACCT
                END IF;

                --En credit  the cess amount from concern account
                END IF;

                ----EN CESS---


                END IF;
                ----EN service tax---



        EXCEPTION                 --<< FEE exception >>
            WHEN OTHERS THEN
            prm_resp_cde := '21';
                        prm_err_msg := 'Problem while processing fee for transaction ';
        END;                            --<< FEE end >>
END IF;
    --END LOOP;
    --Sn check any fees attached if so credit or debit the acct
    --En check any fees attached if so credit or debit the acct
EXCEPTION
    WHEN OTHERS THEN
    prm_resp_cde := '21';
        prm_err_msg  := 'Error main ' || 'Problem while processing amount ';
END;
/


