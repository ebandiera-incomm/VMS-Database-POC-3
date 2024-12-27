CREATE OR REPLACE PROCEDURE VMSCMS.Sp_Online_Pinchange_Reversal
(
prm_inst_code        IN        NUMBER,
prm_msg_typ        IN        VARCHAR2,
prm_rvsl_code        IN        VARCHAR2,
prm_rrn            IN        VARCHAR2,
prm_delv_chnl        IN        VARCHAR2,
prm_terminal_id        IN        VARCHAR2,
prm_merc_id        IN        VARCHAR2,
prm_txn_code        IN        VARCHAR2,
prm_txn_type        IN        VARCHAR2,
prm_txn_mode        IN        VARCHAR2,
prm_business_date    IN        VARCHAR2,
prm_business_time    IN        VARCHAR2,
prm_card_no        IN        VARCHAR2,
prm_bank_code        IN        VARCHAR2,
prm_stan        IN        VARCHAR2,
prm_expry_date        IN        VARCHAR2,
prm_orgnl_business_date    IN        VARCHAR2,
prm_orgnl_business_time    IN        VARCHAR2,
prm_orgnl_rrn        IN        VARCHAR2,
prm_mbr_numb         IN        VARCHAR2,
prm_orgnl_terminal_id      IN   VARCHAR2,
prm_resp_cde        OUT        VARCHAR2,
prm_resp_msg        OUT        VARCHAR2,
prm_resp_msg_m24    OUT        VARCHAR2
)
AS
v_orgnl_delivery_channel        TRANSACTIONLOG.delivery_channel%TYPE;
v_orgnl_resp_code            TRANSACTIONLOG.response_code%TYPE;
v_orgnl_terminal_id            TRANSACTIONLOG.terminal_id%TYPE;
v_orgnl_txn_code            TRANSACTIONLOG.txn_code%TYPE;
v_orgnl_txn_type            TRANSACTIONLOG.txn_type%TYPE;
v_orgnl_txn_mode            TRANSACTIONLOG.txn_mode%TYPE;
v_orgnl_business_date            TRANSACTIONLOG.business_date%TYPE;
v_orgnl_business_time            TRANSACTIONLOG.business_time%TYPE;
v_orgnl_customer_card_no        TRANSACTIONLOG.customer_card_no%TYPE;
v_orgnl_total_amount            TRANSACTIONLOG.amount%TYPE;
v_actual_amt                NUMBER(9,2);
v_reversal_amt                NUMBER(9,2);
v_orgnl_txn_feecode            CMS_FEE_MAST.cfm_fee_code%TYPE;
v_orgnl_txn_feeattachtype        VARCHAR2(1);
v_orgnl_txn_totalfee_amt        TRANSACTIONLOG.tranfee_amt%TYPE;
v_orgnl_txn_servicetax_amt        TRANSACTIONLOG.servicetax_amt%TYPE;
v_orgnl_txn_cess_amt            TRANSACTIONLOG.cess_amt%TYPE;
v_orgnl_transaction_type        TRANSACTIONLOG.cr_dr_flag%TYPE;
v_actual_dispatched_amt            TRANSACTIONLOG.amount%TYPE;
v_resp_cde                 VARCHAR2(3);
v_func_code                CMS_FUNC_MAST.cfm_func_code%TYPE;
v_dr_cr_flag                TRANSACTIONLOG.CR_DR_FLAG%TYPE;
v_orgnl_trandate            DATE;
v_rvsl_trandate                DATE;
v_orgnl_termid                TRANSACTIONLOG.terminal_id%TYPE;
v_orgnl_mcccode                TRANSACTIONLOG.MCCODE%TYPE;
v_errmsg                VARCHAR2(300);
v_actual_feecode            TRANSACTIONLOG.feecode%TYPE;
v_orgnl_tranfee_amt            TRANSACTIONLOG.TRANFEE_AMT%TYPE        ;
v_orgnl_servicetax_amt            TRANSACTIONLOG.SERVICETAX_AMT%TYPE    ;
v_orgnl_cess_amt            TRANSACTIONLOG.CESS_AMT%TYPE        ;
v_orgnl_cr_dr_flag            TRANSACTIONLOG.CR_DR_FLAG%TYPE        ;
v_orgnl_tranfee_cr_acctno        TRANSACTIONLOG.TRANFEE_CR_ACCTNO%TYPE    ;
v_orgnl_tranfee_dr_acctno        TRANSACTIONLOG.TRANFEE_DR_ACCTNO%TYPE    ;
v_orgnl_st_calc_flag            TRANSACTIONLOG.TRAN_ST_CALC_FLAG%TYPE    ;
v_orgnl_cess_calc_flag            TRANSACTIONLOG.TRAN_CESS_CALC_FLAG%TYPE    ;
v_orgnl_st_cr_acctno            TRANSACTIONLOG.TRAN_ST_CR_ACCTNO%TYPE    ;
v_orgnl_st_dr_acctno            TRANSACTIONLOG.TRAN_ST_DR_ACCTNO%TYPE    ;
v_orgnl_cess_cr_acctno            TRANSACTIONLOG.TRAN_CESS_CR_ACCTNO%TYPE    ;
v_orgnl_cess_dr_acctno            TRANSACTIONLOG.TRAN_CESS_DR_ACCTNO%TYPE    ;
v_prod_code                CMS_APPL_PAN.cap_prod_code%TYPE;
v_card_type                CMS_APPL_PAN.cap_card_type%TYPE;
v_gl_upd_flag                TRANSACTIONLOG.gl_upd_flag%TYPE;
v_tran_reverse_flag            TRANSACTIONLOG.tran_reverse_flag%TYPE;
v_savepoint                    NUMBER DEFAULT 1;
v_curr_code                    TRANSACTIONLOG.CURRENCYCODE%TYPE;
v_auth_id                    VARCHAR2(6);
v_oldpin_offset                CMS_APPL_PAN .cap_pin_off%TYPE;
v_terminal_indicator        PCMS_TERMINAL_MAST.ptm_terminal_indicator%TYPE;
EXP_RVSL_REJECT_RECORD     EXCEPTION;
v_card_acct_no             NUMBER;
  v_hash_pan             cms_appl_pan.cap_pan_code%TYPE;
   v_encr_pan             cms_appl_pan.cap_pan_code_encr%TYPE;

BEGIN            --<<MAIN BEGIN >>
     prm_resp_cde        := '00';
     prm_resp_msg        := 'OK';
    SAVEPOINT v_savepoint;

      --SN CREATE HASH PAN
        BEGIN
            v_hash_pan := Gethash(prm_card_no);
        EXCEPTION
        WHEN OTHERS THEN
        v_errmsg := 'Error while converting pan ' || SUBSTR(SQLERRM,1,200);
        RAISE	exp_rvsl_reject_record;
        END;
        --EN CREATE HASH PAN

        --SN create encr pan
        BEGIN
            v_encr_pan := Fn_Emaps_Main(prm_card_no);
        EXCEPTION
        WHEN OTHERS THEN
        v_errmsg := 'Error while converting pan ' || SUBSTR(SQLERRM,1,200);
        RAISE	exp_rvsl_reject_record;
        END;
        --EN create encr pan

    --Sn check msg type
    IF (prm_msg_typ NOT IN ('0400','0410','0420','0430') ) OR ( prm_rvsl_code = '00') THEN
        v_resp_cde := '34';
        v_errmsg := 'Not a valid reversal request';
        RAISE    exp_rvsl_reject_record;
    END IF;
    --En check msg type
    --Sn find the orginal record
    -- Amount is missing in reversal request)
    BEGIN
        SELECT
              DELIVERY_CHANNEL
            , TERMINAL_ID,
              RESPONSE_CODE,
              TXN_CODE,
              TXN_TYPE,
              TXN_MODE,
              BUSINESS_DATE,
              BUSINESS_TIME,
              CUSTOMER_CARD_NO,
              AMOUNT,                --Transaction amount
              FEECODE    ,
              FEEATTACHTYPE,            -- card level / prod cattype level
                TRANFEE_AMT ,                --Tranfee  Total    amount
                SERVICETAX_AMT ,            --Tran servicetax amount
              CESS_AMT,                --Tran cess amount
              CR_DR_FLAG,
              TERMINAL_ID,
              MCCODE,
              FEECODE,
              TRANFEE_AMT,
              SERVICETAX_AMT,
              CESS_AMT,
              TRANFEE_CR_ACCTNO,
              TRANFEE_DR_ACCTNO,
              TRAN_ST_CALC_FLAG,
              TRAN_CESS_CALC_FLAG,
              TRAN_ST_CR_ACCTNO,
              TRAN_ST_DR_ACCTNO,
              TRAN_CESS_CR_ACCTNO,
              TRAN_CESS_DR_ACCTNO,
              CURRENCYCODE,
              TRAN_REVERSE_FLAG,
              GL_UPD_FLAG
        INTO
              v_orgnl_delivery_channel,
              v_orgnl_terminal_id,
              v_orgnl_resp_code,
              v_orgnl_txn_code,
              v_orgnl_txn_type,
              v_orgnl_txn_mode,
              v_orgnl_business_date,
              v_orgnl_business_time,
              v_orgnl_customer_card_no,
              v_orgnl_total_amount,
              v_orgnl_txn_feecode,
              v_orgnl_txn_feeattachtype,
              v_orgnl_txn_totalfee_amt,
              v_orgnl_txn_servicetax_amt,
              v_orgnl_txn_cess_amt,
              v_orgnl_transaction_type,
              v_orgnl_termid,
              v_orgnl_mcccode,
              v_actual_feecode,
              v_orgnl_tranfee_amt,
              v_orgnl_servicetax_amt,
              v_orgnl_cess_amt,
              v_orgnl_tranfee_cr_acctno,
              v_orgnl_tranfee_dr_acctno,
              v_orgnl_st_calc_flag,
              v_orgnl_cess_calc_flag,
              v_orgnl_st_cr_acctno,
              v_orgnl_st_dr_acctno,
              v_orgnl_cess_cr_acctno,
              v_orgnl_cess_dr_acctno,
              v_curr_code,
              v_tran_reverse_flag,
              v_gl_upd_flag
        FROM      TRANSACTIONLOG
        WHERE      rrn            = prm_orgnl_rrn
        AND      business_date        = prm_orgnl_business_date
        AND      business_time        = prm_orgnl_business_time
        AND      customer_card_no  =v_hash_pan-- prm_card_no
        AND     instcode = prm_inst_code
        AND      TERMINAL_ID        = prm_orgnl_terminal_id;
        --AND      MCCODE            = prm_merc_id;
        IF      v_orgnl_resp_code <> '00' THEN
            v_resp_cde := '26';
            v_errmsg := ' The original transaction was not successful';
            RAISE    exp_rvsl_reject_record;
        END IF;
        IF      v_tran_reverse_flag = 'Y' THEN
            v_resp_cde := '51';
            v_errmsg := 'The reversal already done for the orginal transaction';
            RAISE    exp_rvsl_reject_record;
        END IF;
    EXCEPTION
        WHEN    exp_rvsl_reject_record THEN
        RAISE;
        WHEN NO_DATA_FOUND THEN
            v_resp_cde := '21';
            v_errmsg := 'Matching transaction not found';
            RAISE    exp_rvsl_reject_record;
        WHEN TOO_MANY_ROWS THEN
            v_resp_cde := '21';
            v_errmsg := 'More than one matching record found in the master';
            RAISE    exp_rvsl_reject_record;
        WHEN OTHERS THEN
            v_resp_cde := '21';
            v_errmsg := 'Error while selecting master data' || SUBSTR(SQLERRM,1,200);
            RAISE    exp_rvsl_reject_record;
    END;
    --En find the orginal record
    --Sn check orgnl merchant with reversal merchant
     /*IF ((prm_merc_id = v_orgnl_mcccode)  AND (prm_terminal_id = v_orgnl_termid )) THEN
         NULL;
         ELSE
             v_resp_cde := '21';
            v_errmsg := ' The original transaction merchant and terminal detail is not matching with reversal request';
            RAISE    exp_rvsl_reject_record;
         END IF;*/
    --En check orgnl merchant with reversal merchant
    ---Sn check card number
    --IF v_orgnl_customer_card_no <> prm_card_no THEN
     IF v_orgnl_customer_card_no <> v_hash_pan THEN
      v_resp_cde := '21';
      v_errmsg := 'Customer card number is not matching in reversal and orginal transaction';
      RAISE    exp_rvsl_reject_record;
    END IF;
    --En check card number
    --Sn find the orginal func code
        BEGIN
                 SELECT     cfm_func_code
                 INTO       v_func_code
                 FROM       CMS_FUNC_MAST
                 WHERE      cfm_txn_code    = v_orgnl_txn_code
                 AND        cfm_txn_mode    = v_orgnl_txn_mode
                 AND        cfm_delivery_channel = v_orgnl_delivery_channel
                 AND        cfm_inst_code = prm_inst_code;
                 --TXN mode and delivery channel we need to attach
                --bkz txn code may be same for all type of channels
        EXCEPTION
                WHEN NO_DATA_FOUND THEN
                v_resp_cde := '21';   --Ineligible Transaction
                v_errmsg := 'Function code not defined for txn code ' || prm_txn_code;
                RAISE exp_rvsl_reject_record;
                WHEN TOO_MANY_ROWS THEN
                v_resp_cde  := '21';
                v_errmsg := 'More than one function defined for txn code ' || prm_txn_code;
                RAISE exp_rvsl_reject_record;
        END;

    --Sn update the amount

     --Sn find prod code and card type and available balance for the card number
      BEGIN
         SELECT     cam_acct_no
               INTO v_card_acct_no
               FROM cms_acct_mast
              WHERE cam_acct_no =(select cap_acct_no from cms_appl_pan
              where cap_pan_code=v_hash_pan --prm_card_no
              and cap_inst_code=prm_inst_code and cap_mbr_numb=prm_mbr_numb)
              AND cam_inst_code = prm_inst_code
         FOR UPDATE NOWAIT;
      EXCEPTION
         WHEN NO_DATA_FOUND
         THEN
            v_resp_cde := '14';                      --Ineligible Transaction
            v_errmsg := 'Invalid Card ';
            RAISE exp_rvsl_reject_record;
         WHEN OTHERS
         THEN
            v_resp_cde := '12';
            v_errmsg :=
                  'Error while selecting data from card Master for card number '
               || prm_card_no;
            RAISE exp_rvsl_reject_record;
      END;

      --En find prod code and card type for the card number

      --Sn get date
            BEGIN
            v_orgnl_trandate :=  TO_DATE (SUBSTR(TRIM(prm_orgnl_business_date),1,8) || ' '|| SUBSTR(TRIM(prm_orgnl_business_time),1,10) ,  'yyyymmdd hh24:mi:ss');
            v_rvsl_trandate     :=  TO_DATE (SUBSTR(TRIM(prm_business_date),1,8) || ' '|| SUBSTR(TRIM(prm_business_time),1,10) ,  'yyyymmdd hh24:mi:ss');
                            /*IF TRIM(v_tran_date) IS NULL THEN
                            prm_resp_code  := '999';
                            prm_resp_msg:= 'Invalid transaction date' || SUBSTR(SQLERRM,1,300);
                            RETURN;
                            END IF;  */
            EXCEPTION
            WHEN OTHERS THEN
            v_resp_cde  := '21';
            v_errmsg  := 'Problem while converting transaction date ' || SUBSTR(SQLERRM,1 ,200);
            RAISE exp_rvsl_reject_record;
            END;
    --En get date
    ---------------Sn check transaction amount --------------
    IF v_orgnl_tranfee_amt  > 0 THEN
       v_resp_cde  := '25';
       v_errmsg := 'Invalid amount for a pin change' ;
       RAISE exp_rvsl_reject_record;
    END IF;
    ---------------En check transaction amount ---------------

    --Sn reverse the fee
    IF v_orgnl_tranfee_amt > 0 THEN
    BEGIN
                 Sp_Reverse_Fee_Amount
                (
                  prm_inst_code,
                 prm_rrn,
                 prm_delv_chnl,
                 prm_orgnl_terminal_id,
                 prm_merc_id,
                 prm_txn_code,
                 v_rvsl_trandate,
                 prm_txn_mode,
                 v_orgnl_txn_totalfee_amt,
                 prm_card_no,
                 v_actual_feecode,
                 v_orgnl_tranfee_amt,
                 v_orgnl_tranfee_cr_acctno,
                   v_orgnl_tranfee_dr_acctno,
                 v_orgnl_st_calc_flag,
                 v_orgnl_servicetax_amt,
                 v_orgnl_st_cr_acctno,
                   v_orgnl_st_dr_acctno,
                 v_orgnl_cess_calc_flag,
                 v_orgnl_cess_amt,
                 v_orgnl_cess_cr_acctno,
                   v_orgnl_cess_dr_acctno,
                 prm_orgnl_rrn,
                 v_card_acct_no,
                 v_resp_cde,
                 v_errmsg
                 );

         IF v_resp_cde  <> '00' OR  v_errmsg <> 'OK' THEN
             RAISE exp_rvsl_reject_record;
         END IF;



    EXCEPTION
     WHEN exp_rvsl_reject_record THEN
     RAISE;

     WHEN OTHERS THEN
     v_resp_cde := '21';
     v_errmsg  := 'Error while reversing the fee amount ' || SUBSTR(SQLERRM,1,200);
     RAISE exp_rvsl_reject_record;
    END;
    --Sn get the product code
         BEGIN

         SELECT cap_prod_code,
                 cap_card_type
         INTO    v_prod_code,
                v_card_type
         FROM    CMS_APPL_PAN
         WHERE  cap_inst_code = prm_inst_code
         AND    cap_pan_code  = v_hash_pan ; --prm_card_no;
         EXCEPTION
         WHEN NO_DATA_FOUND THEN
          v_resp_cde := '21';
          v_errmsg  := prm_card_no ||' Card no not in master';
          RAISE exp_rvsl_reject_record;

         WHEN OTHERS THEN
          v_resp_cde := '21';
          v_errmsg  := 'Error while retriving card detail ' || SUBSTR(SQLERRM,1,200);
          RAISE exp_rvsl_reject_record;

         END;
        IF v_gl_upd_flag = 'Y' THEN
    --En get the product code
             Sp_Reverse_Gl_Entries (
                             prm_inst_code ,
                             v_rvsl_trandate,
                          v_prod_code,
                          v_card_type,
                          v_reversal_amt,
                          v_func_code,
                          prm_txn_code,
                          v_dr_cr_flag,
                          prm_card_no,
                          v_actual_feecode,
                          v_orgnl_txn_totalfee_amt,
                          v_orgnl_tranfee_cr_acctno,
                          v_orgnl_tranfee_dr_acctno,
                          v_card_acct_no,
                          prm_rvsl_code,
                          prm_msg_typ,
                          prm_delv_chnl,
                          v_resp_cde,
                          v_gl_upd_flag,
                          v_errmsg
                          );
        IF v_gl_upd_flag <> 'Y' THEN
           v_resp_cde := '21';
            v_errmsg  := 'Error while retriving gl detail ' || SUBSTR(SQLERRM,1,200);
            RAISE exp_rvsl_reject_record;
        END IF;

        END IF;
        --En reverse the GL entries


    END IF;
    --En reverse the fee


    --Sn check the orginal pin offset
    BEGIN
        SELECT crh_old_pin_off
        INTO   v_oldpin_offset
        FROM   CMS_REPIN_HIST
        WHERE  CRH_PAN_CODE           =  v_hash_pan -- prm_card_no
        AND       CRH_RRN                =    prm_orgnl_rrn
        AND       CRH_BUSINESS_DATE    =    prm_orgnl_business_date
        AND       CRH_BUSINESS_TIME    =    prm_orgnl_business_time
        AND CRH_MBR_NUMB =prm_mbr_numb;

    EXCEPTION
       WHEN NO_DATA_FOUND THEN
               v_resp_cde := '21';
                v_errmsg  := 'Old pin offset not found in master ';
             RAISE exp_rvsl_reject_record;

       WHEN TOO_MANY_ROWS THEN
               v_resp_cde := '21';
                v_errmsg  := 'More than one record found in repin hist detail ';
             RAISE exp_rvsl_reject_record;

       WHEN OTHERS THEN
              v_resp_cde := '21';
            v_errmsg  := 'Error while getting old pin offset ' || SUBSTR(SQLERRM,1,200);
            RAISE exp_rvsl_reject_record;
    END;
    --En check the orginal pin offset


    --Sn change the orginal pin offset
    BEGIN
         UPDATE CMS_APPL_PAN
         SET    cap_pin_off  = v_oldpin_offset
         WHERE  cap_pan_code = v_hash_pan --prm_card_no
         AND cap_inst_code=prm_inst_code;

         IF SQL%rowcount = 0 THEN
             v_resp_cde := '21';
             v_errmsg  := 'Error while updating old pin offset ' || SUBSTR(SQLERRM,1,200);
             RAISE exp_rvsl_reject_record;
         END IF;

    EXCEPTION

       WHEN OTHERS THEN
              v_resp_cde := '21';
            v_errmsg  := 'Error while updating old pin offset ' || SUBSTR(SQLERRM,1,200);
            RAISE exp_rvsl_reject_record;
    END;
    --En change the orginal pin offset

    --Sn create a entry for successful
      BEGIN

        IF v_errmsg='OK' THEN

         INSERT INTO cms_transaction_log_dtl
                     (ctd_delivery_channel, ctd_txn_code, ctd_txn_type,ctd_msg_type,
                      ctd_txn_mode, ctd_business_date, ctd_business_time,
                      ctd_customer_card_no, ctd_process_flag,
                      ctd_process_msg, ctd_rrn, ctd_system_trace_audit_no,ctd_inst_code,CTD_CUSTOMER_CARD_NO_ENCR
                     )
              VALUES (prm_delv_chnl, prm_txn_code, prm_txn_type,prm_msg_typ,
                      prm_txn_mode, prm_business_date, prm_business_time,
                      v_hash_pan, 'Y',
                      'Successful', prm_rrn, prm_stan,prm_inst_code,v_encr_pan
                     );
          END IF;



      EXCEPTION
         WHEN OTHERS
         THEN
            v_errmsg :=
                  'Problem while selecting data from response master '
               || SUBSTR (SQLERRM, 1, 300);
            v_resp_cde := '32';
            RAISE exp_rvsl_reject_record;
      END;

      --En create a entry for successful


    -- Sn create a entry in GL

    --Sn generate auth id
     BEGIN
           SELECT LPAD(SEQ_AUTH_ID.NEXTVAL,6,'0')
          INTO     v_auth_id
          FROM DUAL;


     EXCEPTION
           WHEN OTHERS THEN
              v_resp_cde := '21';
            v_errmsg := 'Error while generating authid ' || SUBSTR(SQLERRM,1,200);
            RAISE    exp_rvsl_reject_record;
     END;

--En generate auth id



    BEGIN
         INSERT INTO TRANSACTIONLOG
         (                MSGTYPE,
                          RRN,
                          DELIVERY_CHANNEL,
                          TERMINAL_ID,
                          DATE_TIME,
                          TXN_CODE,
                          TXN_TYPE,
                          TXN_MODE
                          ,
                     TXN_STATUS,
                     RESPONSE_CODE,
                          BUSINESS_DATE,
                      BUSINESS_TIME
                      ,
                          CUSTOMER_CARD_NO,
                          TOPUP_CARD_NO,
                          TOPUP_ACCT_NO,
                          TOPUP_ACCT_TYPE,
                          BANK_CODE,
                          TOTAL_AMOUNT
                          ,
                         RULE_INDICATOR
                         ,
                          RULEGROUPID,
                          MCCODE,
                         CURRENCYCODE,
                        --  ADDCHARGE
                        --  ,
                          PRODUCTID,
                          CATEGORYID,
                        TRANFEE_AMT,
                         TIPS,
                         DECLINE_RULEID,
                          ATM_NAME_LOCATION,
                          AUTH_ID,
                         TRANS_DESC,
                          AMOUNT,
                         PREAUTHAMOUNT,
                         PARTIALAMOUNT,
                          MCCODEGROUPID,
                           CURRENCYCODEGROUPID,
                          TRANSCODEGROUPID,
                           RULES,
                           PREAUTH_DATE,
                           GL_UPD_FLAG,
                           SYSTEM_TRACE_AUDIT_NO,
                           INSTCODE,
                          FEECODE,
                           FEEATTACHTYPE,
                          TRAN_REVERSE_FLAG,CUSTOMER_CARD_NO_ENCR,RESPONSE_ID
    )
    VALUES
          (
                             prm_msg_typ,
                          prm_rrn,
                           prm_delv_chnl,
                           prm_terminal_id,
                          v_rvsl_trandate,
                           prm_txn_code,
                           prm_txn_type,
                           prm_txn_mode
                          ,
                         'C',
                          '00',
                         prm_business_date,
                      SUBSTR( prm_business_time,1,10)
                     ,
                           --prm_card_no
                           v_hash_pan,
                          NULL,
                        --prm_topup_cardno,
                          NULL ,--prm_topup_acctno    ,
                          NULL, --prm_topup_accttype,
                          prm_inst_code,
                          0,
                          NULL
                          ,
                         NULL,
                          prm_merc_id,
                          v_curr_code,
                          --  prm_add_charge,
                         v_prod_code,
                           v_card_type,
                         0 ,
                         0    ,
                         NULL,
                         NULL    ,
                          v_auth_id ,
                         'PIN CHANGE REVERSAL',
                          0,
                         NULL,                        --- PRE AUTH AMOUNT
                      NULL,                      -- Partial amount (will be given for partial txn)
                      NULL    ,
                       NULL    ,
                       NULL    ,
                       NULL,
                      NULL,
                      'Y',
                      prm_stan    ,
                     prm_inst_code    ,
                         NULL,
                        NULL,

                     'N',v_encr_pan,V_RESP_CDE
            );

            --prm_resp_cde := '00';
            --Sn update reverse flag
            BEGIN
                UPDATE TRANSACTIONLOG
                SET       TRAN_REVERSE_FLAG = 'Y'
                WHERE      rrn            = prm_orgnl_rrn
                AND      business_date        = prm_orgnl_business_date
                AND      business_time        = prm_orgnl_business_time
                AND      customer_card_no  = v_hash_pan --prm_card_no
                AND     instcode = prm_inst_code
                AND      terminal_id    = prm_orgnl_terminal_id;

                IF SQL%rowcount = 0  THEN

                   v_resp_cde := '21';
                       v_errmsg  := 'Reverse flag is not updated ';
                       RAISE exp_rvsl_reject_record;
                END IF;
            EXCEPTION
                WHEN OTHERS THEN
                v_resp_cde := '21';
                    v_errmsg  := 'Error while updating gl flag ' || SUBSTR(SQLERRM,1,200);
                    RAISE exp_rvsl_reject_record;

            END;
            --En update reverse flag


            --prm_resp_msg_m24 :=  IS PENDING
    EXCEPTION
             WHEN OTHERS THEN
             v_resp_cde := '21';
             v_errmsg := 'Error while inserting records in transaction log ' || SUBSTR(SQLERRM,1,200);
             RAISE exp_rvsl_reject_record;
    END;
    --En  create a entry in GL


        v_resp_cde := '1';
    BEGIN
        SELECT CMS_ISO_RESPCDE
        INTO   prm_resp_cde
        FROM   CMS_RESPONSE_MAST
        WHERE  CMS_INST_CODE        = prm_inst_code
        AND    CMS_DELIVERY_CHANNEL    = prm_delv_chnl
        AND    CMS_RESPONSE_ID        = TO_NUMBER(v_resp_cde);
    EXCEPTION
        WHEN OTHERS THEN
        v_errmsg   := 'Problem while selecting data from response master for respose code'|| v_resp_cde || SUBSTR(SQLERRM,1,300);
        v_resp_cde := '21';
        RAISE exp_rvsl_reject_record;
    END;

    --En generate response code
    prm_resp_msg := 'OK';

    --Sn message 24 format -----------
         --Sn terminal Indicator find
                                /*   BEGIN
                                          SELECT ptm_terminal_indicator
                                        INTO v_terminal_indicator
                                        FROM PCMS_TERMINAL_MAST
                                        WHERE ptm_terminal_id = prm_terminal_id
                                        AND ptm_inst_code = prm_inst_code;
                                   EXCEPTION
                                  WHEN NO_DATA_FOUND
                                      THEN
                                           v_resp_cde := '21';
                                         v_errmsg :=
                                               'Terminal indicator is not declared for terminal id'
                                            || prm_terminal_id;
                                         RAISE exp_rvsl_reject_record;

                                  WHEN OTHERS
                                       THEN
                                           v_resp_cde := '21';
                                         v_errmsg :=
                                               'Terminal indicator is not declared for terminal id'
                                            || SQLERRM
                                            || ' '
                                            || SQLCODE;
                                         RAISE exp_rvsl_reject_record;
                                   END;
                         --En terminal Indicator find

                                 IF v_terminal_indicator IS NOT NULL AND v_auth_id IS NOT NULL THEN
                                         prm_resp_msg_m24:= RPAD (v_auth_id,'6', ' ')||RPAD (v_terminal_indicator,'1', ' ');

                                 ELSE
                                      v_resp_cde := '21';
                                      v_errmsg := ' Error while crating response message :- Either terminal indicator or authid is null ' ;
                                      RAISE exp_rvsl_reject_record;

                                 END IF;*/



    --En message 24 format -----------


EXCEPTION        --<<MAIN EXCEPTION>>
WHEN exp_rvsl_reject_record THEN
    ROLLBACK TO v_savepoint;
    BEGIN
        SELECT CMS_ISO_RESPCDE
        INTO   prm_resp_cde
        FROM   CMS_RESPONSE_MAST
        WHERE  CMS_INST_CODE        = prm_inst_code
        AND    CMS_DELIVERY_CHANNEL    = prm_delv_chnl
        AND    CMS_RESPONSE_ID        = TO_NUMBER(v_resp_cde);
        prm_resp_msg := v_errmsg ;
    EXCEPTION
        WHEN OTHERS THEN
        prm_resp_msg  := 'Problem while selecting data from response master ' || v_resp_cde ||SUBSTR(SQLERRM,1,300);
        prm_resp_cde  := '99';
        --RETURN;
    END;
    prm_resp_msg := v_errmsg;
WHEN OTHERS THEN
     ROLLBACK TO v_savepoint;
     BEGIN
        SELECT CMS_ISO_RESPCDE
        INTO   prm_resp_cde
        FROM   CMS_RESPONSE_MAST
        WHERE  CMS_INST_CODE        = prm_inst_code
        AND    CMS_DELIVERY_CHANNEL    = prm_delv_chnl
        AND    CMS_RESPONSE_ID        = TO_NUMBER(v_resp_cde);
         BEGIN
            INSERT INTO cms_transaction_log_dtl
                        (ctd_delivery_channel, ctd_txn_code, ctd_txn_type,ctd_msg_type,
                         ctd_txn_mode, ctd_business_date, ctd_business_time,
                         ctd_customer_card_no, ctd_fee_amount,ctd_waiver_amount, ctd_servicetax_amount,
                         ctd_cess_amount, ctd_process_flag, ctd_process_msg, ctd_rrn,
                         ctd_system_trace_audit_no,ctd_inst_code,CTD_CUSTOMER_CARD_NO_ENCR
                        )
                 VALUES ( prm_delv_chnl, prm_txn_code, prm_txn_type,prm_msg_typ,
                      prm_txn_mode, prm_business_date, prm_business_time,
                      v_hash_pan,  NULL, NULL, NULL, NULL,
                         'E', v_errmsg, prm_rrn,
                         prm_stan,prm_inst_code,v_encr_pan
                        );
         EXCEPTION
            WHEN OTHERS
            THEN
               prm_resp_msg :=
                     'Problem while inserting data into transaction log  dtl'
                  || SUBSTR (SQLERRM, 1, 300);
               prm_resp_cde := '69';        -- Server Decline Response 220509
               ROLLBACK;
               RETURN;
         END;
        prm_resp_msg := v_errmsg ;
    EXCEPTION
        WHEN OTHERS THEN
        prm_resp_msg  := 'Problem while selecting data from response master ' || v_resp_cde ||SUBSTR(SQLERRM,1,300);
        prm_resp_cde  := '99';
       -- RETURN;
    END;
     BEGIN
            INSERT INTO cms_transaction_log_dtl
                        (ctd_delivery_channel, ctd_txn_code, ctd_txn_type,ctd_msg_type,
                         ctd_txn_mode, ctd_business_date, ctd_business_time,
                         ctd_customer_card_no, ctd_fee_amount,ctd_waiver_amount, ctd_servicetax_amount,
                         ctd_cess_amount, ctd_process_flag, ctd_process_msg, ctd_rrn,
                         ctd_system_trace_audit_no,ctd_inst_code,CTD_CUSTOMER_CARD_NO_ENCR
                        )
                 VALUES ( prm_delv_chnl, prm_txn_code, prm_txn_type,prm_msg_typ,
                      prm_txn_mode, prm_business_date, prm_business_time,
                      v_hash_pan,  NULL, NULL, NULL, NULL,
                         'E', v_errmsg, prm_rrn,
                         prm_stan,prm_inst_code,v_encr_pan
                        );
         EXCEPTION
            WHEN OTHERS
            THEN
               prm_resp_msg :=
                     'Problem while inserting data into transaction log  dtl'
                  || SUBSTR (SQLERRM, 1, 300);
               prm_resp_cde := '69';        -- Server Decline Response 220509
               ROLLBACK;
               RETURN;
         END;
    prm_resp_msg := v_errmsg;
END;            --<<MAIN END >>
/


