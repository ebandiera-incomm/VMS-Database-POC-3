CREATE OR REPLACE PROCEDURE VMSCMS.SP_REVERSE_FEE_AMOUNT 
(
p_inst_code           IN    NUMBER,
p_rrn                 IN    VARCHAR2,
p_delv_chnl           IN    VARCHAR2,
p_terminal_id         IN    VARCHAR2,
p_merc_id             IN    VARCHAR2,
p_txn_code            IN    VARCHAR2,
p_tran_date           IN    DATE,
p_txn_mode            IN    VARCHAR2,
p_tranfee_total_amt   IN    NUMBER,
p_card_no             IN    VARCHAR2,
p_fee_code            IN    VARCHAR2,
p_tranfee_amt         IN    NUMBER,
p_fee_cr_acctno       IN    VARCHAR2,
p_fee_dr_acctno       IN    VARCHAR2,
p_st_calc_flag        IN    VARCHAR2,
p_servicetax_amt      IN    NUMBER,
p_st_cr_acctno        IN    VARCHAR2,
p_st_dr_acctno        IN    VARCHAR2,
p_cess_calc_flag      IN    VARCHAR2,
p_cess_amt            IN    NUMBER,
p_cess_cr_acctno      IN    VARCHAR2,
p_cess_dr_acctno      IN    VARCHAR2,
p_orgnl_rrn           IN    VARCHAR2,
p_card_acct_no        IN    varchar2,
p_TXN_DATE            IN    VARCHAR2,
p_TRAN_TIME           IN    VARCHAR2,
p_AUTH_ID             IN    VARCHAR2,
p_NARRATION           IN    VARCHAR2,
P_MERC_NAME           IN    VARCHAR2,--Added by Deepa on 09-May-2012 to include Merchant name,city and state in statements log
P_MERC_CITY           IN    VARCHAR2,
P_MERC_STATE          IN    VARCHAR2,
p_err_code            OUT   VARCHAR2,
p_err_msg             OUT   VARCHAR2
)
IS
/*************************************************
     * Modified By      :  Trivikram
     * Modified Date    :  23-MAY-2012
     * Modified Reason  :  Looging last 4 digit of the card number in statement log incase of fees relative txn
     * Reviewer         :  Nandakumar
     * Reviewed Date    :  23-May-2012
     * Release Number   :    CMS3.4.4_RI0008_B00013(CMS3.4.3_RI0006.3_B0009)
     
     * Modified by      : Sankar S
    * Modified for      : Mantis ID 11326
    * Modified Reason   : To Insert Ledger Balanace For Fee Transaction 
    * Modified Date     : 26-Jun-2013
    * Reviewer          : Sagar M
    * Reviewed Date     : 
    * Build Number      : RI0024.3_B0007 
    
    * Modified by       : Ramesh.A
    * Modified for      : Mantis ID 12213
    * Modified Reason   : Fee maximum limit not validates for reversal transactions 
    * Modified Date     : 04-Sep-2013
    * Reviewer          : Dhiraj
    * Reviewed Date     : 04-Sep-2013
    * Build Number      : RI0024.4_B0008
    
    * Modified by       : Ramesh.A
    * Modified for      : FSS-1586
    * Modified Reason   : Logging account type in csl_acct_type
    * Modified Date     : 11-June-2013
    * Reviewer          : Spankaj 
    * Build Number      : RI0027.3_B0001
    
    * Modified by       : MageshKumar S.
    * Modified Date     : 25-July-14    
    * Modified For      : FWR-48
    * Modified reason   : GL Mapping removal changes
    * Reviewer          : SPankaj
    * Build Number      : RI0027.3.1_B0001
    
    * Modified by       : Abdul Hameed M.A
    * Modified Date     : 05-Nov-14    
    * Modified For      : FSS-1906
    * Modified reason   : Logging csl_prod_code in statments log
    * Reviewer          : 
    * Build Number      : 
    
    
    
    * Modified By      : Saravana Kumar A
    * Modified Date    : 07/07/2017
    * Purpose          : Prod code and card type logging in statements log
    * Reviewer         : Pankaj S. 
    * Release Number   : VMSGPRHOST17.07
	
    * Modified By      : Baskar Krishnan
    * Modified Date    : 16-Aug-2019.
    * Purpose          : VMS-1038-VMS Fee Descriptions for statements/transaction history.
    * Reviewer         : Saravana Kumar A 
    * Release Number   : VMSGPRHOSTR19

 *************************************************/
v_err_code                          VARCHAR2(3);
v_err_msg                           TRANSACTIONLOG.ERROR_MSG%TYPE;
v_reversal_fee_cr_acctno            CMS_FUNC_PROD.cfp_cracct_no%TYPE;
v_reversal_fee_dr_acctno            CMS_FUNC_PROD.cfp_cracct_no%TYPE;
v_servicetax_cracct_no              CMS_PRODCATTYPE_FEES.cpf_st_cracct_no%TYPE;
v_servicetax_dracct_no              CMS_PRODCATTYPE_FEES.cpf_st_dracct_no%TYPE;
v_rvsl_servicetax_cracct_no         CMS_PRODCATTYPE_FEES.cpf_st_cracct_no%TYPE;
v_rvsl_servicetax_dracct_no         CMS_PRODCATTYPE_FEES.cpf_st_dracct_no%TYPE;
v_cess_cracct_no                    CMS_PRODCATTYPE_FEES.cpf_cess_cracct_no%TYPE;
v_cess_dracct_no                    CMS_PRODCATTYPE_FEES.cpf_cess_dracct_no%TYPE;
v_rvsl_cess_cracct_no               CMS_PRODCATTYPE_FEES.cpf_cess_cracct_no%TYPE;
v_rvsl_cess_dracct_no               CMS_PRODCATTYPE_FEES.cpf_cess_cracct_no%TYPE;
v_credit_acct_bal                   CMS_ACCT_MAST.cam_acct_bal%TYPE;
v_debit_acct_bal                    CMS_ACCT_MAST.cam_acct_bal%TYPE;
v_credit_ledger_bal                 CMS_ACCT_MAST.cam_ledger_bal%TYPE;  --Added by Sankar S  for Mantis ID 11326
v_debit_ledger_bal                  CMS_ACCT_MAST.cam_ledger_bal%TYPE;    --Added by Sankar S  for Mantis ID 11326
V_HASH_PAN                          CMS_APPL_PAN.CAP_PAN_CODE%TYPE;
V_ENCR_PAN                          CMS_APPL_PAN.CAP_PAN_CODE_ENCR%TYPE;
V_ACCT_ID                           CMS_ACCT_MAST.CAM_ACCT_ID%TYPE; --Added for Mantis ID : 12213 on 04/09/2013
v_dr_cr_flag                        CMS_TRANSACTION_MAST.CTM_CREDIT_DEBIT_FLAG%TYPE;
V_ACCT_TYPE                         CMS_ACCT_MAST.CAM_TYPE_CODE%type; --Added for FSS-1586
V_prod_code                         CMS_APPL_PAN.CAP_PROD_CODE%TYPE; --Added for FSS-1906
v_card_type                         cms_prod_cattype.cpc_card_type%type;
v_narration                         cms_statements_log.csl_trans_narrration%TYPE;
exp_reversal_fee_excp               EXCEPTION;

BEGIN

     v_err_code := '00';
     v_err_msg  := 'OK';

     --SN CREATE HASH PAN
  BEGIN
    V_HASH_PAN := GETHASH(p_CARD_NO);
  EXCEPTION
    WHEN OTHERS THEN
     v_err_msg := 'Error while converting pan ' || SUBSTR(SQLERRM, 1, 200);
     RAISE exp_reversal_fee_excp;
  END;

  --EN CREATE HASH PAN

  --SN create encr pan
  BEGIN
    V_ENCR_PAN := FN_EMAPS_MAIN(p_CARD_NO);
  EXCEPTION
    WHEN OTHERS THEN
     v_err_msg := 'Error while converting pan ' || SUBSTR(SQLERRM, 1, 200);
     RAISE exp_reversal_fee_excp;
  END;

  --EN create encr pan
  
  --Sn Added for FSS-1906
  
BEGIN
  SELECT cap_prod_code,cap_card_type
  INTO v_prod_code,v_card_type
  FROM cms_appl_pan
  WHERE CAP_PAN_CODE = V_HASH_PAN
  AND CAP_INST_CODE  = P_INST_CODE;
EXCEPTION
when NO_DATA_FOUND then
  V_ERR_CODE := '21';
  V_ERR_MSG                   := 'Prod Code is not found in the pan master table ';
  RAISE exp_reversal_fee_excp;
WHEN OTHERS THEN
  V_ERR_CODE := '21';
  v_err_msg  := 'Error while getting  prod code ' || SUBSTR(SQLERRM, 1, 200);
  RAISE exp_reversal_fee_excp;
end;

  --En Added for FSS-1906
  
  
   -- get fee Description  VMS-1038
    v_narration :=p_NARRATION;
   IF P_FEE_CODE IS NOT NULL THEN
      BEGIN
         SELECT CFM_FEE_DESC ||'  Reversal'
          into v_narration
           from CMS_FEE_MAST
          WHERE CFM_FEE_CODE = p_fee_code and CFM_INST_CODE=p_inst_code;
      EXCEPTION
         WHEN NO_DATA_FOUND
         THEN
            V_ERR_CODE := '49';
            v_err_msg :=
                  'Fee detail is not found in master for reversal txn ';
              
            RAISE exp_reversal_fee_excp;
         WHEN OTHERS
         THEN
            V_ERR_CODE := '21';
            v_err_msg :=
                  'Problem while selecting Fee Description for reversal txn'
               || SUBSTR (SQLERRM, 1, 100);
            RAISE exp_reversal_fee_excp;
    END; 
      
end if;
 
      -- end

 --START Changes for Mantis ID : 12213 on 04/09/2013
IF P_FEE_CODE IS NOT NULL THEN

    BEGIN
        SELECT CAM_ACCT_ID,CAM_TYPE_CODE --Added for FSS-1586
        INTO V_ACCT_ID,v_acct_type --Added for FSS-1586
        FROM CMS_ACCT_MAST      
        WHERE  CAM_INST_CODE=P_INST_CODE 
        AND CAM_ACCT_NO = p_card_acct_no;
    
    EXCEPTION
    WHEN NO_DATA_FOUND THEN
        V_ERR_CODE := '21';
        v_err_msg  := 'Account no not found in master ' || p_card_acct_no ;
    RAISE exp_reversal_fee_excp;
    WHEN OTHERS THEN
        V_ERR_CODE := '21';
        v_err_msg  := 'Error while selecting acct id for acct ' || p_card_acct_no || SUBSTR(SQLERRM,1,200) ;
    RAISE exp_reversal_fee_excp;
    END;
  

    BEGIN
    
        UPDATE CMS_ACCTLVL_FEELIMIT 
        SET CAF_MAX_LIMIT = CAF_MAX_LIMIT -1
        WHERE CAF_ACCT_ID = V_ACCT_ID
        AND CAF_FEE_CODE = P_FEE_CODE
        AND CAF_INST_CODE = P_INST_CODE;           
    
    EXCEPTION
    WHEN OTHERS THEN
     V_ERR_CODE := '21';
     v_err_msg := p_TXN_DATE||'ERROR  WHILE UPDATING MAXLIMIT IN CMS_ACCTLVL_FEELIMIT ' || SUBSTR(SQLERRM,1,200);
    RAISE exp_reversal_fee_excp;
    END;

END IF;
--END Changes for Mantis ID : 12213  on 04/09/2013

  IF p_tranfee_amt <> 0 THEN
    --Sn update fee amount in acct mast
    --Sn commented for fwr-48
     /*   IF trim(p_fee_cr_acctno) IS NULL AND trim(p_fee_dr_acctno) IS NULL THEN
            v_err_code    := '21';
                        v_err_msg    := 'Both credit and debit fee account cannot be null' ;
            RAISE exp_reversal_fee_excp;
                END IF;
        IF TRIM(p_fee_cr_acctno) IS NULL THEN
            v_fee_cr_acctno := p_card_acct_no;
        ELSE
            v_fee_cr_acctno := TRIM(p_fee_cr_acctno);
        END IF;

        IF  TRIM(p_fee_dr_acctno) IS NULL THEN
            v_fee_dr_acctno :=  p_card_acct_no ;
        ELSE
            v_fee_dr_acctno :=  TRIM(p_fee_dr_acctno);
        END IF; */
        --En commented for fwr-48
        
       -- v_reversal_fee_cr_acctno := v_fee_dr_acctno ; --commented for fwr-48
       -- v_reversal_fee_dr_acctno := v_fee_cr_acctno ; --commented for fwr-48
       
        v_reversal_fee_cr_acctno := p_card_acct_no ; --modified for fwr-48
        v_reversal_fee_dr_acctno := null ; --modified for fwr-48
       
         --SN CREDIT THE CONCERN FEE ACCOUNT
            IF v_reversal_fee_cr_acctno = p_card_acct_no THEN

                         --Sn get the opening balance
                          BEGIN

                              SELECT cam_acct_bal,cam_ledger_bal
                              INTO     v_credit_acct_bal,v_credit_ledger_bal       -- Added 'cam_ledger_bal' by Sankar S  for Mantis ID 11326
                              FROM      CMS_ACCT_MAST
                              WHERE  cam_inst_code = p_inst_code
                              AND     cam_acct_no   = v_reversal_fee_cr_acctno;
                          EXCEPTION
                                WHEN NO_DATA_FOUND THEN
                                      v_err_code := '21';
                                      v_err_msg  := 'Account no not found in master ' || v_reversal_fee_cr_acctno ;
                                    RAISE exp_reversal_fee_excp;
                              WHEN OTHERS THEN
                                      v_err_code := '21';
                                      v_err_msg  := 'Error while selecting acct data for acct ' || v_reversal_fee_cr_acctno || SUBSTR(SQLERRM,1,200) ;
                                      RAISE exp_reversal_fee_excp;
                          END;

                      --En get the opening balance

                        BEGIN
                                UPDATE CMS_ACCT_MAST
                                SET    cam_acct_bal  = cam_acct_bal + p_tranfee_amt,
                                cam_ledger_bal=cam_ledger_bal + p_tranfee_amt
                                WHERE  cam_inst_code = p_inst_code
                                AND    cam_acct_no   =  v_reversal_fee_cr_acctno;
                                IF SQL%ROWCOUNT = 0 THEN
                                      v_err_code := '21';
                                      v_err_msg  := 'Problem while updating in account master for acct ' || v_reversal_fee_cr_acctno ;
                                    RAISE exp_reversal_fee_excp;
                                END IF;
                        EXCEPTION
                                WHEN exp_reversal_fee_excp THEN
                                RAISE;
                                WHEN OTHERS THEN
                                v_err_code := '21';
                                v_err_msg  := 'Error while updating acct master for acct ' || v_reversal_fee_cr_acctno || SUBSTR(SQLERRM,1,200);
                                RAISE exp_reversal_fee_excp;
                        END ;

                         --Sn create a entry in statement log
                               v_dr_cr_flag := 'CR';
                             BEGIN
                                    INSERT INTO CMS_STATEMENTS_LOG
                                    (
                                    CSL_PAN_NO,
                                    CSL_OPENING_BAL,
                                    CSL_TRANS_AMOUNT,
                                    CSL_TRANS_TYPE,
                                    CSL_TRANS_DATE,
                                    CSL_CLOSING_BALANCE,
                                    CSL_TRANS_NARRRATION,
                                    CSL_INST_CODE,
                                    CSL_PAN_NO_ENCR,
                                    CSL_RRN,
                                    CSL_AUTH_ID,
                                    CSL_BUSINESS_DATE,
                                    CSL_BUSINESS_TIME,
                                    TXN_FEE_FLAG,
                                    CSL_DELIVERY_CHANNEL,
                                    CSL_TXN_CODE,
                                    CSL_ACCT_NO,--Added by Deepa to log the account number ,INS_DATE and INS_USER
                                    CSL_INS_USER,
                                    CSL_INS_DATE,
                                    CSL_MERCHANT_NAME,--Added by Deepa on 09-May-2012 to include Merchant name,city and state in statements log
                                    CSL_MERCHANT_CITY,
                                    CSL_MERCHANT_STATE,
                                    CSL_PANNO_LAST4DIGIT, --Added by Trivikram on 22-May-2012 to log last 4 Digit of the card number
                                    CSL_ACCT_TYPE  --Added for FSS-1586
                                    ,csl_prod_code,csl_card_type,csl_time_stamp)   --Added for FSS-1906
                                    VALUES
                                    (
                                    V_HASH_PAN,
                                    v_credit_ledger_bal,         --Modified by Sankar S  for Mantis ID 11326
                                    p_tranfee_total_amt ,
                                    v_dr_cr_flag,
                                    p_tran_date,
                                    DECODE(v_dr_cr_flag,
                                            'DR',v_credit_ledger_bal -  p_tranfee_total_amt , 
                                            'CR',v_credit_ledger_bal +  p_tranfee_total_amt ,
                                            'NA',v_credit_ledger_bal),        --Modified by Sankar S  for Mantis ID 11326
                                    v_narration,p_inst_code,V_ENCR_PAN,
                                    p_rrn,
                                    p_AUTH_ID ,
                                    p_TXN_DATE,
                                    p_TRAN_TIME ,
                                    'Y',
                                    p_DELV_CHNL,
                                    p_TXN_CODE,
                                    p_card_acct_no,--Added by Deepa to log the account number ,INS_DATE and INS_USER
                                    1,
                                    sysdate,
                                    P_MERC_NAME,--Added by Deepa on 09-May-2012 to include Merchant name,city and state in statements log
                                    P_MERC_CITY,
                                    P_MERC_STATE,
                                    (SUBSTR(P_CARD_NO, length(P_CARD_NO) -3,length(P_CARD_NO))),--Added by Trivikam on 22-May-2012 to log Last 4 Digit of the card number
                                    V_ACCT_TYPE   --Added for FSS-1586
                                    ,v_prod_code,v_card_type,systimestamp);   --Added for FSS-1906
                            EXCEPTION
                                WHEN OTHERS THEN
                                    v_err_code  := '21';
                                    v_err_msg := 'Problem while inserting into statement log for tran amt ' || SUBSTR(SQLERRM,1 ,200);
                                    RAISE exp_reversal_fee_excp;
                            END;

                      --En create a entry in statement log


             /*   ELSE
                                --Sn insert a record into EODUPDATE_ACCT
                                BEGIN
                                        Sp_Ins_Eodupdate_Acct
                                        (
                                        p_rrn ,
                                        p_terminal_id ,
                                        p_delv_chnl,
                                        p_txn_code,
                                        p_txn_mode ,
                                        p_tran_date,
                                        p_card_acct_no ,
                                        v_reversal_fee_cr_acctno,
                                        p_tranfee_amt ,
                                        'C',
                                        p_inst_code,
                                        v_err_msg
                                        );
                                        IF p_err_msg <> 'OK' THEN
                                                  v_err_code := '21';
                                                 v_err_msg  := 'Error from credit eod update acct ' || v_err_msg;
                                               RAISE exp_reversal_fee_excp;
                                        END IF;
                                END;*/--review changes for fwr-48
                END IF;
                                --En  insert a record into EODUPDATE_ACCT
         --EN CREDIT THE CONCERN FEE ACCOUNT
     --SN DEBIT THE CONCERN FEE ACCOUNT
        IF v_reversal_fee_dr_acctno = p_card_acct_no THEN

                      --Sn get the opening balance
                      BEGIN

                              SELECT cam_acct_bal
                              INTO     v_debit_acct_bal
                              FROM      CMS_ACCT_MAST
                              WHERE  cam_inst_code = p_inst_code
                              AND     cam_acct_no   = v_reversal_fee_dr_acctno;
                          EXCEPTION
                                WHEN NO_DATA_FOUND THEN
                                      v_err_code := '21';
                                      v_err_msg  := 'Account no not found in master ' || v_reversal_fee_dr_acctno ;
                                    RAISE exp_reversal_fee_excp;
                              WHEN OTHERS THEN
                                      v_err_code := '21';
                                      v_err_msg  := 'Error while selecting acct data for acct ' || v_reversal_fee_dr_acctno || SUBSTR(SQLERRM,1,200) ;
                                      RAISE exp_reversal_fee_excp;
                          END;

                      --En get the opening balance

                       BEGIN
                               UPDATE CMS_ACCT_MAST
                                SET    cam_acct_bal  = cam_acct_bal - p_tranfee_amt,
                                cam_ledger_bal = cam_ledger_bal - p_tranfee_amt
                                WHERE  cam_inst_code = p_inst_code
                                AND    cam_acct_no   =  v_reversal_fee_dr_acctno;
                                IF SQL%ROWCOUNT = 0 THEN
                                      v_err_code := '21';
                                      v_err_msg  := 'Problem while updating in account master for acct ' || v_reversal_fee_dr_acctno ;
                                    RAISE exp_reversal_fee_excp;
                                END IF;
                       EXCEPTION
                                WHEN exp_reversal_fee_excp THEN
                                RAISE;
                                WHEN OTHERS THEN
                                v_err_code := '21';
                                v_err_msg  := 'Error while updating acct master for acct ' || v_reversal_fee_dr_acctno || SUBSTR(SQLERRM,1,200);
                                RAISE exp_reversal_fee_excp;
                        END ;

                        --Sn create a entry in statement log
                               v_dr_cr_flag := 'DR';
                             BEGIN
                                    INSERT INTO CMS_STATEMENTS_LOG
                                    (
                                    CSL_PAN_NO,
                                    CSL_OPENING_BAL,
                                    CSL_TRANS_AMOUNT,
                                    CSL_TRANS_TYPE,
                                    CSL_TRANS_DATE,
                                    CSL_CLOSING_BALANCE,
                                    CSL_TRANS_NARRRATION,
                                    CSL_INST_CODE,CSL_PAN_NO_ENCR,
                                    CSL_RRN,
                                    CSL_AUTH_ID,
                                    CSL_BUSINESS_DATE,
                                    CSL_BUSINESS_TIME,
                                    TXN_FEE_FLAG,
                                    CSL_DELIVERY_CHANNEL,
                                    CSL_TXN_CODE,
                                    CSL_ACCT_NO,--Added by Deepa to log the account number ,INS_DATE and INS_USER
                                    CSL_INS_USER,
                                    CSL_INS_DATE,
                                    CSL_MERCHANT_NAME,--Added by Deepa on 09-May-2012 to include Merchant name,city and state in statements log
                                    CSL_MERCHANT_CITY,
                                    CSL_MERCHANT_STATE,
                                    CSL_PANNO_LAST4DIGIT, --Added by Trivikram on 22-May-2012 to log last 4 Digit of the card number
                                    CSL_ACCT_TYPE,  --Added for FSS-1586
                                    csl_prod_code,csl_time_stamp)   --Added for FSS-1906
                                    VALUES
                                    (
                                    V_HASH_PAN,
                                    v_debit_ledger_bal,       --Modified by Sankar S  for Mantis ID 11326
                                    p_tranfee_total_amt,
                                    v_dr_cr_flag,
                                     p_tran_date,
                                     DECODE(v_dr_cr_flag,
                                            'DR',v_debit_ledger_bal -  p_tranfee_total_amt, 
                                            'CR',v_debit_ledger_bal +  p_tranfee_total_amt,
                                            'NA',v_debit_ledger_bal),         --Modified by Sankar S  for Mantis ID 11326
                                    v_narration,p_inst_code,V_ENCR_PAN,
                                    p_rrn,
                                    p_AUTH_ID ,
                                    p_TXN_DATE,
                                    p_TRAN_TIME ,
                                    'Y',
                                    p_DELV_CHNL,
                                    p_TXN_CODE,
                                    p_card_acct_no,--Added by Deepa to log the account number ,INS_DATE and INS_USER
                                    1,
                                    sysdate,
                                    P_MERC_NAME,--Added by Deepa on 09-May-2012 to include Merchant name,city and state in statements log
                                    P_MERC_CITY,
                                    P_MERC_STATE,
                                    (SUBSTR(P_CARD_NO, length(P_CARD_NO) -3,length(P_CARD_NO))),--Added by Trivikam on 22-May-2012 to log Last 4 Digit of the card number
                                    V_ACCT_TYPE  --Added for FSS-1586
                                    ,v_prod_code,systimestamp);  --Added for FSS-1906
                            EXCEPTION
                                WHEN OTHERS THEN
                                    v_err_code := '21';
                                    v_err_msg := 'Problem while inserting into statement log for tran amt ' || SUBSTR(SQLERRM,1 ,200);
                                    RAISE exp_reversal_fee_excp;
                            END;

                      --En create a entry in statement log


     /*   ELSE
                                --Sn insert a record into EODUPDATE_ACCT
                                BEGIN
                                        Sp_Ins_Eodupdate_Acct
                                        (
                                        p_rrn ,
                                        p_terminal_id ,
                                        p_delv_chnl,
                                        p_txn_code,
                                        p_txn_mode ,
                                        p_tran_date,
                                        p_card_acct_no ,
                                        v_reversal_fee_dr_acctno,
                                        p_tranfee_amt ,
                                        'D',
                                        p_inst_code,
                                        v_err_msg
                                        );
                                        IF p_err_msg <> 'OK' THEN
                                                  v_err_code := '21';
                                                 v_err_msg  := 'Error from credit eod update acct ' || v_err_msg;
                                               RAISE exp_reversal_fee_excp;
                                        END IF;
                                END;*/--review changes for fwr-48
        END IF;
     --EN DEBIT THE CONCERN FEE ACCOUNT
    --En update fee amount in acct mast
    --Sn check st calc flag and reverse the st amount
        IF    p_st_calc_flag = 1 THEN    --Service tax was populated
            v_servicetax_cracct_no := p_st_cr_acctno;
            v_servicetax_dracct_no := p_st_dr_acctno;
                IF trim(v_servicetax_cracct_no) IS NULL AND trim(v_servicetax_dracct_no) IS NULL THEN
                    v_err_code := '21';
                    v_err_msg  := 'Both credit and debit account cannot be null for a fee ' || p_fee_code ;
                    RAISE exp_reversal_fee_excp;
                END IF;

                    IF TRIM(v_servicetax_cracct_no) IS NULL THEN
                        v_servicetax_cracct_no := p_card_acct_no;

                    END IF;

                    IF  TRIM(v_servicetax_dracct_no) IS NULL THEN
                        v_servicetax_dracct_no :=  p_card_acct_no ;
                    END IF;
                    IF TRIM(v_servicetax_cracct_no)  = TRIM(v_servicetax_dracct_no)     THEN
                        v_err_code := '21';
                        v_err_msg  := 'Both debit and credit service tax account cannot be same';
                                        RAISE exp_reversal_fee_excp;
                    END IF;
            --Sn set the reversal service tax account
                    v_rvsl_servicetax_cracct_no := v_servicetax_dracct_no;
                    v_rvsl_servicetax_dracct_no := v_servicetax_cracct_no;
            --En set the reversal service tax account
            IF v_rvsl_servicetax_dracct_no =  p_card_acct_no THEN
                --SN  debit service tax amount from cmncern account
                          BEGIN
                              UPDATE CMS_ACCT_MAST
                              SET    cam_acct_bal  = cam_acct_bal - p_servicetax_amt,
                              cam_ledger_bal = cam_ledger_bal - p_servicetax_amt
                              WHERE  cam_inst_code = p_inst_code
                              AND    cam_acct_no   = v_rvsl_servicetax_dracct_no ;
                              IF SQL%ROWCOUNT = 0 THEN
                                 v_err_code  := '21';
                                 v_err_msg   := 'Problem while updating in account master for transaction acct ' || v_rvsl_servicetax_dracct_no ;
                                 RAISE exp_reversal_fee_excp;
                              END IF;
                        EXCEPTION
                                WHEN exp_reversal_fee_excp THEN
                                RAISE;
                                WHEN OTHERS THEN
                                v_err_code := '21';
                                v_err_msg  := 'Error while updating acct master for acct ' || v_rvsl_servicetax_dracct_no || SUBSTR(SQLERRM,1,200);
                                RAISE exp_reversal_fee_excp;
                        END;
            /*    ELSE
                                        --Sn insert a record into EODUPDATE_ACCT
                            BEGIN
                                Sp_Ins_Eodupdate_Acct
                                (
                                p_rrn ,
                                p_terminal_id ,
                                p_delv_chnl,
                                p_txn_code,
                                p_txn_mode ,
                                p_tran_date,
                                p_card_acct_no ,
                                v_rvsl_servicetax_dracct_no,
                                p_servicetax_amt     ,
                                'D',
                                p_inst_code,
                                v_err_msg
                                );
                                IF v_err_msg <> 'OK' THEN
                                   v_err_code := '21';
                                   RAISE exp_reversal_fee_excp;
                                END IF;
                            END;*/--review changes for fwr-48
                                    --En insert a record into EODUPDATE_ACCT
            END IF;
            IF v_rvsl_servicetax_cracct_no =  p_card_acct_no THEN
                --SN  debit service tax amount from cmncern account
                    BEGIN
                          UPDATE CMS_ACCT_MAST
                          SET    cam_acct_bal  = cam_acct_bal + p_servicetax_amt,
                          cam_ledger_bal = cam_ledger_bal + p_servicetax_amt
                          WHERE  cam_inst_code = p_inst_code
                          AND    cam_acct_no   = v_rvsl_servicetax_cracct_no ;
                          IF SQL%ROWCOUNT = 0 THEN
                             v_err_code  := '21';
                             v_err_msg   := 'Problem while updating in account master for transaction account ' || v_rvsl_servicetax_cracct_no;
                             RAISE exp_reversal_fee_excp;
                          END IF;

                    EXCEPTION
                          WHEN exp_reversal_fee_excp THEN
                          RAISE;
                          WHEN OTHERS THEN
                                v_err_code := '21';
                                v_err_msg  := 'Error while updating acct master for acct ' || v_rvsl_servicetax_cracct_no || SUBSTR(SQLERRM,1,200);
                                RAISE exp_reversal_fee_excp;
                    END;
            /*    ELSE
                                        --Sn insert a record into EODUPDATE_ACCT
                            BEGIN
                                Sp_Ins_Eodupdate_Acct
                                (
                                p_rrn ,
                                p_terminal_id ,
                                p_delv_chnl,
                                p_txn_code,
                                p_txn_mode ,
                                p_tran_date,
                                p_card_acct_no ,
                                v_rvsl_servicetax_cracct_no,
                                p_servicetax_amt,
                                'C',
                                p_inst_code,
                                v_err_msg
                                );
                                IF v_err_msg <> 'OK' THEN
                                   v_err_code := '21';
                                   RAISE exp_reversal_fee_excp;
                                END IF;
                            END;*/--review changes for fwr-48
                                    --En insert a record into EODUPDATE_ACCT
            END IF;
            ----SN CESS---
                IF p_cess_calc_flag     = '1' THEN
                v_cess_cracct_no    :=      p_cess_cr_acctno;
                v_cess_dracct_no    :=       p_cess_dr_acctno;
                    IF trim(v_cess_cracct_no) IS NULL AND trim(v_cess_dracct_no) IS NULL THEN
                        v_err_code := '21';
                        v_err_msg  := 'Both credit and debit account cannot be null for a fee ' || p_fee_code ;
                        RAISE exp_reversal_fee_excp;
                    END IF;
                        IF TRIM(v_cess_cracct_no) IS NULL THEN
                                v_cess_cracct_no  := p_card_acct_no;
                        END IF;
                        IF  TRIM(v_cess_dracct_no) IS NULL THEN
                            v_cess_dracct_no   :=  p_card_acct_no ;
                        END IF;
                        IF trim(v_cess_cracct_no) = trim(v_cess_dracct_no)    THEN
                               v_err_code := '21';
                            v_err_msg  := 'Both debit and credit account cannot be same';
                        RAISE exp_reversal_fee_excp;
                        END IF;
                --Sn assign reversal cess acct no
                    v_rvsl_cess_dracct_no := v_cess_cracct_no;
                    v_rvsl_cess_cracct_no := v_cess_dracct_no;
                --En assign reversal cess acct no
                --SN  debit cess amount from concern account
                IF v_rvsl_cess_dracct_no = p_card_acct_no THEN
                        BEGIN
                                     UPDATE CMS_ACCT_MAST
                                    SET    cam_acct_bal  = cam_acct_bal - p_cess_amt,
                                    cam_ledger_bal=cam_ledger_bal - p_cess_amt
                                    WHERE  cam_inst_code = p_inst_code
                                    AND    cam_acct_no   = v_rvsl_cess_dracct_no ;
                                    IF SQL%ROWCOUNT = 0 THEN
                                    v_err_code := '21';
                                    v_err_msg  := 'Problem while updating in account master for transaction ' || v_rvsl_cess_dracct_no;
                                    RAISE exp_reversal_fee_excp;
                                    END IF;
                        EXCEPTION
                                WHEN exp_reversal_fee_excp THEN
                                RAISE;
                                WHEN OTHERS THEN
                                v_err_code := '21';
                                v_err_msg  := 'Error while updating acct master for acct ' || v_rvsl_cess_dracct_no|| SUBSTR(SQLERRM,1,200);
                                RAISE exp_reversal_fee_excp;
                        END;
            /*    ELSE
                                                --Sn insert a record into EODUPDATE_ACCT
                                                BEGIN
                                                        Sp_Ins_Eodupdate_Acct
                                                        (
                                                        p_rrn ,
                                                        p_terminal_id ,
                                                        p_delv_chnl,
                                                        p_txn_code,
                                                        p_txn_mode ,
                                                        p_tran_date,
                                                        p_card_acct_no ,
                                                        v_rvsl_cess_dracct_no,
                                                        p_cess_amt ,
                                                        'D',
                                                        p_inst_code,
                                                        v_err_msg
                                                        );
                                                        IF v_err_msg <> 'OK' THEN
                                                           v_err_code  := '21';
                                                             RAISE exp_reversal_fee_excp;
                                                        END IF;
                                                END;*/--review changes for fwr-48
                --En insert a record into EODUPDATE_ACCT
                END IF;
                --En debit the cess amount from cmncern account
                --SN  credit cess  amount from cmncern account
                IF v_rvsl_cess_cracct_no = p_card_acct_no THEN
                   BEGIN
                            UPDATE CMS_ACCT_MAST
                            SET    cam_acct_bal  = cam_acct_bal + p_cess_amt,
                            cam_ledger_bal = cam_ledger_bal + p_cess_amt
                            WHERE  cam_inst_code = p_inst_code
                            AND    cam_acct_no   = v_rvsl_cess_cracct_no ;
                            IF SQL%ROWCOUNT = 0 THEN
                            v_err_code := '21';
                            v_err_msg  := 'Problem while updating in account master for transaction acct ' || v_rvsl_cess_cracct_no ;
                            RAISE exp_reversal_fee_excp;
                            END IF;
                    EXCEPTION
                          WHEN exp_reversal_fee_excp THEN
                          RAISE;
                          WHEN OTHERS THEN
                                v_err_code := '21';
                                v_err_msg  := 'Error while updating acct master for acct ' || v_rvsl_cess_cracct_no || SUBSTR(SQLERRM,1,200);
                                RAISE exp_reversal_fee_excp;

                    END;
           /*     ELSE
                                                --Sn insert a record into EODUPDATE_ACCT
                                            BEGIN
                                                Sp_Ins_Eodupdate_Acct
                                                (
                                                p_rrn ,
                                                p_terminal_id ,
                                                p_delv_chnl,
                                                p_txn_code,
                                                p_txn_mode ,
                                                p_tran_date,
                                                p_card_acct_no ,
                                                v_rvsl_cess_cracct_no,
                                                p_cess_amt     ,
                                                'C',
                                                p_inst_code,
                                                v_err_msg
                                                );
                                                IF v_err_msg <> 'OK' THEN
                                                    v_err_code := '21';
                                                    RAISE exp_reversal_fee_excp;
                                                END IF;
                                            END;*/--review changes for fwr-48
                --En insert a record into EODUPDATE_ACCT
                END IF;
                --En credit  the cess amount from concern account
                END IF;
                ----EN CESS---
        END IF;
                        --En  eif service tax  -Service tax was populated
    --En check st calc flag and reverse the st amount
END IF;

    p_err_code    := '00';
    p_err_msg        :=  'OK';
EXCEPTION
    WHEN exp_reversal_fee_excp THEN
    p_err_code    := v_err_code;
    p_err_msg    := v_err_msg;
    WHEN OTHERS THEN
    p_err_code    := '21';
    p_err_msg        := 'Error from main ' || SUBSTR(SQLERRM,1,200);
END;
/
show error
