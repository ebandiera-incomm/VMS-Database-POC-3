create or replace
PROCEDURE        VMSCMS.SP_TRANS_PREAUTH_REVERSAL_SAF (P_INST_CODE           IN NUMBER,
                                               P_MSG_TYP             IN VARCHAR2,
                                               P_RVSL_CODE           IN VARCHAR2,
                                               P_RRN                 IN VARCHAR2,
                                               P_DELV_CHNL           IN VARCHAR2,
                                               P_TERMINAL_ID         IN VARCHAR2,
                                               P_MERC_ID             IN VARCHAR2,
                                               P_TXN_CODE            IN VARCHAR2,
                                               P_TXN_TYPE            IN VARCHAR2,
                                               P_TXN_MODE            IN VARCHAR2,
                                               P_BUSINESS_DATE       IN VARCHAR2,
                                               P_BUSINESS_TIME       IN VARCHAR2,
                                               P_CARD_NO             IN VARCHAR2,
                                               P_ACTUAL_AMT          IN NUMBER,
                                               P_BANK_CODE           IN VARCHAR2,
                                               P_STAN                IN VARCHAR2,
                                               P_EXPRY_DATE          IN VARCHAR2,
                                               P_TOCUST_CARD_NO      IN VARCHAR2,
                                               P_TOCUST_EXPRY_DATE   IN VARCHAR2,
                                               P_ORGNL_BUSINESS_DATE IN VARCHAR2,
                                               P_ORGNL_BUSINESS_TIME IN VARCHAR2,
                                               P_ORGNL_RRN           IN VARCHAR2,
                                               P_MBR_NUMB            IN VARCHAR2,
                                               P_ORGNL_TERMINAL_ID   IN VARCHAR2,
                                               P_CURR_CODE           IN VARCHAR2,
                                               P_MERCHANT_NAME       IN VARCHAR2,
                                               P_MERCHANT_CITY       IN VARCHAR2,
                                               /* Start Added by Dhiraj G on 31052012 for Pre - Auth Parameter changes  */
                                               P_NETWORK_ID         IN VARCHAR2,
                                               P_INTERCHANGE_FEEAMT IN NUMBER,
                                               P_MERCHANT_ZIP       IN VARCHAR2,
                                               /* End Added by Dhiraj G on 31052012 for Pre - Auth Parameter changes  */
                                               P_NETWORK_SETL_DATE   IN VARCHAR2,  -- Added on 201112 for logging N/W settlement date in transactionlog
                                               P_MERCHANT_ID         IN VARCHAR2,  -- Added on 19-Mar-2013 for FSS-970
                                               P_MERCHANT_STATE         IN VARCHAR2, -- Added on 21.03.2013 for Merchant Logging Info for the Reversal Txn 
                                               P_NETWORKID_SWITCH    IN VARCHAR2, --Added on 20130626 for the Mantis ID 11344
                                               P_RESP_CDE     OUT VARCHAR2,
                                               P_RESP_MSG     OUT VARCHAR2,
                                               P_RESP_MSG_M24 OUT VARCHAR2,
                                               P_REVERSAL_AMOUNT OUT VARCHAR2 --Added  for  Mantis ID 13785 for To return the reversal amount on 21/03/201
                                               ,P_RESP_ID        OUT VARCHAR2 --Added for sending to FSS (VMS-8018)
                                               ) IS
                                               
   /**********************************************************************************
     * Created Date     :  10-Dec-2012
     * Created By       :  Srinivasu
     * PURPOSE          :  For preauth reversal
     * Modified By      :  Sagar M.
     * Modified Date    :  24-Jan-2013
     * Modified For     :  Defect 10123
     * Modified Reason  :  Insert added for CMS_PREAUTH_TRANS_HIST table
     * Reviewer         :  Dhiraj
     * Reviewed Date    :  25-Jan-2013
     * Release Number   :  RI0023.1_B0008
     
     * Modified By      : Sagar M.
     * Modified Date    : 15-Feb-2013
     * Modified For     : Defect 10296   
     * Modified Reason  : To ignore P_ORGNL_TERMINAL_ID while checking for original preauth transaction
     * Reviewer         : Dhiraj
     * Reviewed Date    : 18-Feb-2013
     * Build Number     : CMS3.5.1_RI0023.2_B0013
     
     * Modified By      : Sagar M.
     * Modified Date    : 19-Mar-2013
     * Modified Reason  : Logging of input merchant id in Transactionlog and 
                          cms_transaction_log_dtl 
     * Modified For     : FSS-970                              
     * Reviewer         : Dhiraj
     * Reviewed Date    : 19-Mar-2013
     * Build Number     : RI0024_B0004   

     * Modified By      : Pankaj S.
     * Modified Date    : 15-Mar-2013
     * Modified Reason  : Logging of system initiated card status change(FSS-390)
     * Reviewer         : Dhiraj
     * Reviewed Date    : 
     * Build Number     : CMS3.5.1_RI0024_B0008        
     
     * Modified By      : Sachin P.
     * Modified Date    : 21-Mar-2013
     * Modified Reason  : Merchant Logging Info for the Reversal Txn                          
     * Modified For     : FSS-1077                                
     * Reviewer         : Dhiraj
     * Reviewed Date    : 
     * Build Number     : CMS3.5.1_RI0024_B0008
     
     * Modified By      : Sagar M.
     * Modified Date    : 24-Mar-2013
     * Modified Reason  : To approve transaction without impacting balance in caseof Unmatched reversal                          
     * Modified For     : FSS-1145                              
     * Reviewer         : Dhiraj
     * Reviewed Date    : 
     * Build Number     : CMS3.5.1_RI0024.0.1_B0001
     
     * Modified By      : Sagar M.
     * Modified Date    : 24-Mar-2013
     * Modified Reason  : To approve transaction without impacting balance in caseof Unmatched reversal   a                       
     * Modified For     : FSS-1145                              
     * Reviewer         : Dhiraj
     * Reviewed Date    : 
     * Build Number     : CMS3.5.1_RI0024.0.1_B0002
     
     * Modified By      : Sagar M.
     * Modified Date    : 26-Apr-2013
     * Modified Reason  : Identification added for un-matched reversal cases in MATCH_RULE column of transactionlog
     * Modified For     : FSS-1145
     * Reviewer         : Dhiraj
     * Reviewed Date    :
     * Build Number     : CMS3.5.1_RI0024.0.1_B0003


     * Modified By      : Sagar M.
     * Modified Date    : 04-Apr-2013
     * Modified Reason  : To log after transaction account balance in Transactionlog
     * Modified For     : Defect 0010784
     * Reviewer         : Dhiraj
     * Reviewed Date    : 10-Apr-2013
     * Build Number     : RI0024.1_B0003

     
     * Modified by      :  Pankaj S.
     * Modified Reason  :  10871 
     * Modified Date    :  19-Apr-2013
     * Reviewer         :  Dhiraj
     * Reviewed Date    :  
     * Build Number     :  RI0024.1_B0013
     
     * Modified by      : Deepa T
     * Modified for     : Mantis ID 11344
     * Modified Reason  : Log the Network ID as ELAN             
     * Modified Date    : 26-Jun-2013
     * Reviewer         : Dhiraj
     * Reviewed Date    : 27-06-2013
     * Build Number     : RI0024.2_B0009
     
     * Modified by      : Sagar  
     * Modified for     : FSS-1246
     * Modified Reason  : To check and reject duplicate SAF preauth reversal transaction               
     * Modified Date    : 08-Jul-2013
     * Reviewer         : Dhiraj
     * Reviewed Date    : 
     * Build Number     : RI0024.3_B0004     
     
     * Modified by      : Sagar  
     * Modified for     : FSS-1246 Review observations 
     * Modified Reason  : Review observations               
     * Modified Date    : 24-Jul-2013
     * Reviewer         : Dhiraj
     * Reviewed Date    : 
     * Build Number     : RI0024.4_B0002
     
     * Modified by      : Sachin P.
     * Modified for     : Mantis Id:11695
     * Modified Reason  : Reversal Fee details(FeePlan id,FeeCode,Fee amount 
                         and FeeAttach Type) are not logged in transactionlog 
                         table. 
     * Modified Date    : 30.07.2013
     * Reviewer         : Dhiraj
     * Reviewed Date    : 19-aug-2013
     * Build Number     : RI0024.4_B0002
     
     * Modified by      : SIVA ARCOT.
     * Modified for     : Mantis Id:10997 & FWR-11
     * Modified Reason  : Handle for Partial Reversal Transaction
     * Modified Date    : 11.09.2013
     * Reviewer         : Dhiraj
     * Reviewed Date    : 11.09.2013
     * Build Number     : RI0024.4_B0010
     
      * Modified by       :  Pankaj S.
     * Modified Reason   :  Enabling Limit configuration and validation for Preauth(1.7.3.9 changes integrate)
     * Modified Date     :  23-Oct-2013
     * Reviewer          :  Dhiraj
     * Reviewed Date     :  
     * Build Number      : RI0024.5.2_B0001

     * Modified by      :  DHINAKARAN B
     * Modified for     :  FSS-1335
     * Modified Reason  :  To logging the international indicator in transactionlog. 
     * Modified Date    :  07-JAN-2014
     * Reviewer         :  Dhiraj
     * Reviewed Date    :  07-JAN-2014 
     * Build Number     :  RI0027_B0003
        
     * Modified by       : Sagar
     * Modified for      : 
     * Modified Reason   : Concurrent Processsing Issue 
                            (1.7.6.7 changes integarted)
     * Modified Date     : 04-Mar-2014
     * Reviewer          : Dhiarj
     * Reviewed Date     : 06-Mar-2014
     * Build Number      : RI0027.1.1_B0001      

 * Modified by       : Abdul Hameed M.A
     * Modified for      : Mantis ID 13893
     * Modified Reason   : Added card number,txncode and msgtype for duplicate RRN check
     * Modified Date     : 06-Mar-2014
     * Reviewer          : Dhiraj
     * Reviewed Date     : 06-Mar-2014
     * Build Number      : RI0027.2_B0002
     
      * Modified by       : Abdul Hameed M.A
     * Modified for      : Mantis ID 13785
     * Modified Reason   : To return the reversal amount
     * Modified Date     : 21-Mar-2014

     * Reviewer         : Pankaj S.
     * Reviewed Date    : 02-April-2014
     * Build Number     : RI0027.2_B0003

     * Modified by       : siva Kumar M
     * Modified for      : FSS-837
     * Modified Reason   : To hold the preauth completion fee at the time preauth
     * Modified Date     : 25-Jun-2014
     * Reviewer          : Spankaj
     * Build Number      : RI0027.3_B0001
     
     * Modified by       : MageshKumar S.
     * Modified Date     : 25-July-14    
     * Modified For      : FWR-48
     * Modified reason   : GL Mapping removal changes
     * Reviewer          : Spankaj
     * Build Number      : RI0027.3.1_B0001
     
     * Modified by          : Spankaj
     * Modified Date        : 21-Nov-2016
     * Modified For         :FSS-4762:VMS OTC Support for Instant Payroll Card
     * Reviewer             : Saravanakumar
     * Build Number         : VMSGPRHOSTCSD4.11
	 
	 
	  * Modified by          : Saravanakumara a
     * Modified Date        : 03-07-2016
     * Modified For         :Fee free count issue
     * Reviewer             : Saravanakumar
     * Build Number         : VMSGPRHOSTCSD17.06  
       
                * Modified By      : Saravana Kumar A
    * Modified Date    : 07/07/2017
    * Purpose          : Prod code and card type logging in statements log
    * Reviewer         : Pankaj S. 
    * Release Number   : VMSGPRHOST17.07
    
    * Modified By      : MageshKumar S
    * Modified Date    : 18/07/2017
    * Purpose          : FSS-5157
    * Reviewer         : Saravanan/Pankaj S. 
    * Release Number   : VMSGPRHOST17.07
    
    * Modified By      : UBAIDUR RAHMAN H
    * Modified Date    : 16-JAN-2018
    * Purpose          : CURRENCY CODE CHANGES FROM INST LEVEL TO BIN LEVEL.
    * Reviewer         : Vini
    * Release Number   : VMSGPRHOST18.1	 
    
    * Modified By      : Areshka A.
    * Modified Date    : 03-Nov-2023
    * Purpose          : VMS-8018: Added new out parameter (response id) for sending to FSS
    * Reviewer         : 
    * Release Number   : 
  ***********************************************************************************/
  
  V_ORGNL_DELIVERY_CHANNEL   TRANSACTIONLOG.DELIVERY_CHANNEL%TYPE;
  V_ORGNL_RESP_CODE          TRANSACTIONLOG.RESPONSE_CODE%TYPE;
  V_ORGNL_TERMINAL_ID        TRANSACTIONLOG.TERMINAL_ID%TYPE;
  V_ORGNL_TXN_CODE           TRANSACTIONLOG.TXN_CODE%TYPE;
  V_ORGNL_TXN_TYPE           TRANSACTIONLOG.TXN_TYPE%TYPE;
  V_ORGNL_TXN_MODE           TRANSACTIONLOG.TXN_MODE%TYPE;
  V_ORGNL_BUSINESS_DATE      TRANSACTIONLOG.BUSINESS_DATE%TYPE;
  V_ORGNL_BUSINESS_TIME      TRANSACTIONLOG.BUSINESS_TIME%TYPE;
  V_ORGNL_CUSTOMER_CARD_NO   TRANSACTIONLOG.CUSTOMER_CARD_NO%TYPE;
  V_ORGNL_TOTAL_AMOUNT       TRANSACTIONLOG.AMOUNT%TYPE;
  V_ACTUAL_AMT               NUMBER(9, 2);
  V_REVERSAL_AMT             NUMBER(9, 2);
  V_ORGNL_TXN_FEECODE        CMS_FEE_MAST.CFM_FEE_CODE%TYPE;
  --V_ORGNL_TXN_FEEATTACHTYPE  VARCHAR2(1);
  V_ORGNL_TXN_FEEATTACHTYPE  TRANSACTIONLOG.FEEATTACHTYPE%TYPE;--Modified by Deepa on sep-17-2012
  V_ORGNL_TXN_TOTALFEE_AMT   TRANSACTIONLOG.TRANFEE_AMT%TYPE;
  V_ORGNL_TXN_SERVICETAX_AMT TRANSACTIONLOG.SERVICETAX_AMT%TYPE;
  V_ORGNL_TXN_CESS_AMT       TRANSACTIONLOG.CESS_AMT%TYPE;
  V_ORGNL_TRANSACTION_TYPE   TRANSACTIONLOG.CR_DR_FLAG%TYPE;
  V_ACTUAL_DISPATCHED_AMT    TRANSACTIONLOG.AMOUNT%TYPE;
  V_RESP_CDE                 VARCHAR2(3);
  V_FUNC_CODE                CMS_FUNC_MAST.CFM_FUNC_CODE%TYPE;
  V_DR_CR_FLAG               TRANSACTIONLOG.CR_DR_FLAG%TYPE;
  V_ORGNL_TRANDATE           DATE;
  V_RVSL_TRANDATE            DATE;
  V_ORGNL_TERMID             TRANSACTIONLOG.TERMINAL_ID%TYPE;
  V_ORGNL_MCCCODE            TRANSACTIONLOG.MCCODE%TYPE;
  V_ERRMSG                   VARCHAR2(300):='OK'; 
  V_ACTUAL_FEECODE           TRANSACTIONLOG.FEECODE%TYPE;
  V_ORGNL_TRANFEE_AMT        TRANSACTIONLOG.TRANFEE_AMT%TYPE;
  V_ORGNL_SERVICETAX_AMT     TRANSACTIONLOG.SERVICETAX_AMT%TYPE;
  V_ORGNL_CESS_AMT           TRANSACTIONLOG.CESS_AMT%TYPE;
  V_ORGNL_CR_DR_FLAG         TRANSACTIONLOG.CR_DR_FLAG%TYPE;
  V_ORGNL_TRANFEE_CR_ACCTNO  TRANSACTIONLOG.TRANFEE_CR_ACCTNO%TYPE;
  V_ORGNL_TRANFEE_DR_ACCTNO  TRANSACTIONLOG.TRANFEE_DR_ACCTNO%TYPE;
  V_ORGNL_ST_CALC_FLAG       TRANSACTIONLOG.TRAN_ST_CALC_FLAG%TYPE;
  V_ORGNL_CESS_CALC_FLAG     TRANSACTIONLOG.TRAN_CESS_CALC_FLAG%TYPE;
  V_ORGNL_ST_CR_ACCTNO       TRANSACTIONLOG.TRAN_ST_CR_ACCTNO%TYPE;
  V_ORGNL_ST_DR_ACCTNO       TRANSACTIONLOG.TRAN_ST_DR_ACCTNO%TYPE;
  V_ORGNL_CESS_CR_ACCTNO     TRANSACTIONLOG.TRAN_CESS_CR_ACCTNO%TYPE;
  V_ORGNL_CESS_DR_ACCTNO     TRANSACTIONLOG.TRAN_CESS_DR_ACCTNO%TYPE;
  V_PROD_CODE                CMS_APPL_PAN.CAP_PROD_CODE%TYPE;
  V_CARD_TYPE                CMS_APPL_PAN.CAP_CARD_TYPE%TYPE;
  V_GL_UPD_FLAG              TRANSACTIONLOG.GL_UPD_FLAG%TYPE;
  V_TRAN_REVERSE_FLAG        TRANSACTIONLOG.TRAN_REVERSE_FLAG%TYPE;
  V_SAVEPOINT                NUMBER DEFAULT 1;
  V_CURR_CODE                TRANSACTIONLOG.CURRENCYCODE%TYPE;
  V_AUTH_ID                  TRANSACTIONLOG.AUTH_ID%TYPE;
  V_TERMINAL_INDICATOR       PCMS_TERMINAL_MAST.PTM_TERMINAL_INDICATOR%TYPE;
  V_CUTOFF_TIME              VARCHAR2(5);
  V_BUSINESS_TIME            VARCHAR2(5);
  EXP_RVSL_REJECT_RECORD EXCEPTION;
  V_CARD_ACCT_NO            VARCHAR2(20);
  V_TRAN_SYSDATE            DATE;
  V_TRAN_CUTOFF             DATE;
  V_HASH_PAN                CMS_APPL_PAN.CAP_PAN_CODE%TYPE;
  V_ENCR_PAN                CMS_APPL_PAN.CAP_PAN_CODE_ENCR%TYPE;
  V_TRAN_AMT                NUMBER;
  V_DELCHANNEL_CODE         VARCHAR2(2);
  V_CARD_CURR               VARCHAR2(5);
  V_RRN_COUNT               NUMBER;
  V_BASE_CURR               CMS_INST_PARAM.CIP_PARAM_VALUE%TYPE;
  V_CURRCODE                VARCHAR2(3);
  V_ACCT_BALANCE            NUMBER;
  V_TRAN_DESC               CMS_TRANSACTION_MAST.CTM_TRAN_DESC%TYPE;
--  V_ATM_USAGEAMNT           CMS_TRANSLIMIT_CHECK.CTC_ATMUSAGE_AMT%TYPE;
--  V_POS_USAGEAMNT           CMS_TRANSLIMIT_CHECK.CTC_POSUSAGE_AMT%TYPE;
--  V_ATM_USAGELIMIT          CMS_TRANSLIMIT_CHECK.CTC_ATMUSAGE_LIMIT%TYPE;
--  V_POS_USAGELIMIT          CMS_TRANSLIMIT_CHECK.CTC_POSUSAGE_LIMIT%TYPE;
  V_BUSINESS_DATE_TRAN      DATE;
  V_HOLD_AMOUNT             NUMBER;
  V_UPD_HOLD_AMOUNT         NUMBER;
  V_PREAUTH_USAGE_LIMIT     NUMBER;
  V_SAF_TXN_COUNT           NUMBER;
  V_ORGNL_TXN_RRN           TRANSACTIONLOG.RRN%TYPE;
  V_ORGNL_TXN_BUSINESS_DATE TRANSACTIONLOG.BUSINESS_DATE%TYPE;
  V_ORGNL_TXN_BUSINESS_TIME TRANSACTIONLOG.BUSINESS_TIME%TYPE;
  V_ORGNL_TXN_TERM_ID       TRANSACTIONLOG.TERMINAL_ID%TYPE;
  V_LEDGER_BAL              NUMBER;
  V_MAX_CARD_BAL            NUMBER;
  V_ORGNL_TXN               VARCHAR2(20);
  V_ORGNL_RRN               VARCHAR2(25);
--  V_MMPOS_USAGEAMNT         CMS_TRANSLIMIT_CHECK.CTC_MMPOSUSAGE_AMT%TYPE;
  V_PROXUNUMBER             CMS_APPL_PAN.CAP_PROXY_NUMBER%TYPE;
  V_ACCT_NUMBER             CMS_APPL_PAN.CAP_ACCT_NO%TYPE;
  V_AUTHID_DATE             VARCHAR2(8);
  V_TXN_NARRATION           CMS_STATEMENTS_LOG.CSL_TRANS_NARRRATION%TYPE;
  V_FEE_NARRATION           CMS_STATEMENTS_LOG.CSL_TRANS_NARRRATION%TYPE;
  V_TOT_FEE_AMOUNT          TRANSACTIONLOG.TRANFEE_AMT%TYPE;
  V_TOT_AMOUNT              TRANSACTIONLOG.AMOUNT%TYPE;
  V_TXN_TYPE                NUMBER(1);
  V_TRAN_PREAUTH_FLAG       CMS_TRANSACTION_MAST.CTM_PREAUTH_FLAG%TYPE;
  --Added by Deepa for the changes to include Merchant name,city and state in statements log
  V_FEE_MERCHNAME  CMS_STATEMENTS_LOG.CSL_MERCHANT_NAME%TYPE;
  V_FEE_MERCHCITY  CMS_STATEMENTS_LOG.CSL_MERCHANT_CITY%TYPE;
  V_FEE_MERCHSTATE CMS_STATEMENTS_LOG.CSL_MERCHANT_STATE%TYPE;

  --Added by Deepa on June 26 2012 for Reversal Txn fee
  V_FEE_AMT        NUMBER;
  V_FEE_PLAN       CMS_FEE_PLAN.CFP_PLAN_ID%TYPE;
  V_TXN_MERCHNAME  CMS_STATEMENTS_LOG.CSL_MERCHANT_NAME%TYPE;
  V_TXN_MERCHCITY  CMS_STATEMENTS_LOG.CSL_MERCHANT_CITY%TYPE;
  V_TXN_MERCHSTATE CMS_STATEMENTS_LOG.CSL_MERCHANT_STATE%TYPE;
  V_NARRATION      VARCHAR2(300);

  V_TRAN_DATE DATE;
  --Sn Added by Pankaj S. for FSS-390
  v_chnge_crdstat   VARCHAR2(2):='N';
  v_cap_card_stat   cms_appl_pan.cap_card_stat%TYPE;
  --En Added by Pankaj S. for FSS-390  
  v_acct_id         cms_acct_mast.cam_acct_id%type; --Added for FSS-1145 / Defect 0010784
  --Sn Added by Pankaj S. for 10871
  v_acct_type   cms_acct_mast.cam_type_code%TYPE;
  v_timestamp   timestamp(3); 
  --En Added by Pankaj S. for 10871 
  V_FEE_CODE           CMS_FEE_MAST.CFM_FEE_CODE%TYPE; --Added on 29.07.2013 for 11695
  V_FEEATTACH_TYPE     VARCHAR2(2); --Added on 29.07.2013 for 11695
  
  V_SAF_TRAN_COUNT NUMBER(5); -- Added for FSS-1246
    V_ORGNL_TXN_FEE_PLAN     TRANSACTIONLOG.FEE_PLAN%TYPE; --Added for FWR-11
  v_feecap_flag VARCHAR2(1); --Added for FWR-11
  v_orgnl_fee_amt  CMS_FEE_MAST.CFM_FEE_AMT%TYPE; --Added for FWR-11
  V_REVERSAL_AMT_FLAG VARCHAR2(1):='F';  ---Added for Mantis Id-0010997
  
  --Sn Added by Pankaj S. for enabling limit validation
  v_prfl_code                cms_appl_pan.cap_prfl_code%TYPE; 
  v_prfl_flag                cms_transaction_mast.ctm_prfl_flag%type;
  v_tran_type                cms_transaction_mast.ctm_tran_type%type;
  v_pos_verification         transactionlog.pos_verification%type; 
  v_internation_ind_response transactionlog.internation_ind_response %type;
  v_add_ins_date             transactionlog.add_ins_date %type;
  v_orgn_found NUMBER(1) := 1; 
  --En Added by Pankaj S. for enabling limit validation
  
  --FSS -837 changes..
 
   v_completion_txn_code       VARCHAR2(2);
   v_comp_fee_code             cms_fee_mast.cfm_fee_code%TYPE;
   v_comp_fee_crgl_catg        cms_prodcattype_fees.cpf_crgl_catg%TYPE;
   v_comp_fee_crgl_code        cms_prodcattype_fees.cpf_crgl_code%TYPE;
   v_comp_fee_crsubgl_code     cms_prodcattype_fees.cpf_crsubgl_code%TYPE;
   v_comp_fee_cracct_no        cms_prodcattype_fees.cpf_cracct_no%TYPE;
   v_comp_fee_drgl_catg        cms_prodcattype_fees.cpf_drgl_catg%TYPE;
   v_comp_fee_drgl_code        cms_prodcattype_fees.cpf_drgl_code%TYPE;
   v_comp_fee_drsubgl_code     cms_prodcattype_fees.cpf_drsubgl_code%TYPE;
   v_comp_fee_dracct_no        cms_prodcattype_fees.cpf_dracct_no%TYPE;
   v_comp_servicetax_percent   cms_inst_param.cip_param_value%TYPE;
   v_comp_cess_percent         cms_inst_param.cip_param_value%TYPE;
   v_comp_servicetax_amount    NUMBER;
   v_comp_cess_amount          NUMBER;
   v_comp_st_calc_flag         cms_prodcattype_fees.cpf_st_calc_flag%TYPE;
   v_comp_cess_calc_flag       cms_prodcattype_fees.cpf_cess_calc_flag%TYPE;
   v_comp_st_cracct_no         cms_prodcattype_fees.cpf_st_cracct_no%TYPE;
   v_comp_st_dracct_no         cms_prodcattype_fees.cpf_st_dracct_no%TYPE;
   v_comp_cess_cracct_no       cms_prodcattype_fees.cpf_cess_cracct_no%TYPE;
   v_comp_cess_dracct_no       cms_prodcattype_fees.cpf_cess_dracct_no%TYPE;
   v_comp_waiv_percnt          cms_prodcattype_waiv.cpw_waiv_prcnt%TYPE;
   v_comp_feeamnt_type         cms_fee_mast.cfm_feeamnt_type%TYPE;
   v_comp_per_fees             cms_fee_mast.cfm_per_fees%TYPE;
   v_comp_flat_fees            cms_fee_mast.cfm_fee_amt%TYPE;
   v_comp_clawback             cms_fee_mast.cfm_clawback_flag%TYPE;
   v_comp_fee_plan             cms_fee_feeplan.cff_fee_plan%TYPE;
   v_comp_freetxn_exceed       VARCHAR2 (1);
   v_comp_duration             VARCHAR2 (20);
   v_comp_feeattach_type       VARCHAR2 (2);
   v_comp_fee_amt              NUMBER;
   v_comp_err_waiv             VARCHAR2 (300);
   V_COMP_FEE_DESC             cms_fee_mast.cfm_fee_desc%TYPE;
   v_comp_error                VARCHAR2 (500);
   v_comp_total_fee            NUMBER:=0;
   v_reverse_compl_fee         NUMBER;
   v_completion_fee            cms_preauth_transaction.cpt_completion_fee%TYPE;
   v_comp_fee                  NUMBER;
   v_complfee_increment_type   varchar2(1);
   v_complfree_flag   cms_preauth_transaction.cpt_complfree_flag%TYPE;
   V_PROFILE_CODE      CMS_PROD_CATTYPE.CPC_PROFILE_CODE%TYPE; 
   
  
  CURSOR FEEREVERSE IS
    SELECT CSL_TRANS_NARRRATION,
         CSL_MERCHANT_NAME,
         CSL_MERCHANT_CITY,
         CSL_MERCHANT_STATE,
         CSL_TRANS_AMOUNT
     FROM CMS_STATEMENTS_LOG
    WHERE CSL_BUSINESS_DATE = V_ORGNL_BUSINESS_DATE AND
         CSL_BUSINESS_TIME = V_ORGNL_BUSINESS_TIME AND
         CSL_RRN = P_ORGNL_RRN AND
         CSL_DELIVERY_CHANNEL = V_ORGNL_DELIVERY_CHANNEL AND
         CSL_TXN_CODE = V_ORGNL_TXN_CODE AND
         CSL_PAN_NO = V_ORGNL_CUSTOMER_CARD_NO AND
         CSL_INST_CODE = P_INST_CODE AND TXN_FEE_FLAG = 'Y';

BEGIN

  P_RESP_CDE := '00';
  P_RESP_MSG := 'OK';

  SAVEPOINT V_SAVEPOINT;

  --SN CREATE HASH PAN
  BEGIN
    V_HASH_PAN := GETHASH(P_CARD_NO);
  EXCEPTION
    WHEN OTHERS THEN
     V_ERRMSG := 'Error while converting pan ' || SUBSTR(SQLERRM, 1, 200);
     RAISE EXP_RVSL_REJECT_RECORD;
  END;
  --EN CREATE HASH PAN

  --SN create encr pan
  BEGIN
    V_ENCR_PAN := FN_EMAPS_MAIN(P_CARD_NO);
  EXCEPTION
    WHEN OTHERS THEN
     V_ERRMSG := 'Error while converting pan ' || SUBSTR(SQLERRM, 1, 200);
     RAISE EXP_RVSL_REJECT_RECORD;
  END;
  --EN create encr pan

  --Sn find the type of orginal txn (credit or debit)
  BEGIN
    SELECT CTM_CREDIT_DEBIT_FLAG,
         CTM_TRAN_DESC,
         TO_NUMBER(DECODE(CTM_TRAN_TYPE, 'N', '0', 'F', '1')),
         CTM_PREAUTH_FLAG,
         ctm_prfl_flag,ctm_tran_type --Added by Pankaj S. for enabling limit validation
     INTO V_DR_CR_FLAG, V_TRAN_DESC, V_TXN_TYPE, V_TRAN_PREAUTH_FLAG,
          v_prfl_flag,v_tran_type --Added by Pankaj S. for enabling limit validation
     FROM CMS_TRANSACTION_MAST
    WHERE CTM_TRAN_CODE = P_TXN_CODE AND
         CTM_DELIVERY_CHANNEL = P_DELV_CHNL AND
         CTM_INST_CODE = P_INST_CODE;
  EXCEPTION
    WHEN NO_DATA_FOUND THEN
     V_RESP_CDE := '21';
     V_ERRMSG   := 'Transaction detail is not found in master for orginal txn code' ||
                P_TXN_CODE || 'delivery channel ' || P_DELV_CHNL;
     RAISE EXP_RVSL_REJECT_RECORD;
    WHEN OTHERS THEN
     V_RESP_CDE := '21';
     V_ERRMSG   := 'Problem while selecting debit/credit flag ' ||
                SUBSTR(SQLERRM, 1, 200);
     RAISE EXP_RVSL_REJECT_RECORD;
  END;

  --En find the type of orginal txn (credit or debit)

  -- Sn txn date conversion(to check the txn date)

  BEGIN
    V_ORGNL_TRANDATE := TO_DATE(SUBSTR(TRIM(P_ORGNL_BUSINESS_DATE), 1, 8),
                          'yyyymmdd');
    V_RVSL_TRANDATE  := TO_DATE(SUBSTR(TRIM(P_BUSINESS_DATE), 1, 8),
                          'yyyymmdd');

  EXCEPTION
    WHEN OTHERS THEN
     V_RESP_CDE := '45';
     V_ERRMSG   := 'Problem while converting transaction date ' ||
                SUBSTR(SQLERRM, 1, 200);
     RAISE EXP_RVSL_REJECT_RECORD;
  END;

  -- En  txn date conversion

  --Sn generate auth id
  BEGIN
    --    SELECT TO_CHAR(SYSDATE, 'YYYYMMDD') INTO V_AUTHID_DATE FROM DUAL;

    --SELECT V_AUTHID_DATE || LPAD(SEQ_AUTH_ID.NEXTVAL, 6, '0')
    SELECT LPAD(SEQ_AUTH_ID.NEXTVAL, 6, '0') INTO V_AUTH_ID FROM DUAL;

  EXCEPTION
    WHEN OTHERS THEN
     V_ERRMSG   := 'Error while generating authid ' ||
                SUBSTR(SQLERRM, 1, 300);
     V_RESP_CDE := '21'; -- Server Declined
     RAISE EXP_RVSL_REJECT_RECORD;
  END;

  --En generate auth id

  --Sn Txn date conversion

  BEGIN
    V_ORGNL_TRANDATE := TO_DATE(SUBSTR(TRIM(P_ORGNL_BUSINESS_DATE), 1, 8) || ' ' ||
                          SUBSTR(TRIM(P_ORGNL_BUSINESS_TIME), 1, 8),
                          'yyyymmdd hh24:mi:ss');
    V_RVSL_TRANDATE  := TO_DATE(SUBSTR(TRIM(P_BUSINESS_DATE), 1, 8) || ' ' ||
                          SUBSTR(TRIM(P_BUSINESS_TIME), 1, 8),
                          'yyyymmdd hh24:mi:ss');
    V_TRAN_DATE      := V_RVSL_TRANDATE;

  EXCEPTION
    WHEN OTHERS THEN
     V_RESP_CDE := '32';
     V_ERRMSG   := 'Problem while converting transaction Time ' ||
                SUBSTR(SQLERRM, 1, 200);
     RAISE EXP_RVSL_REJECT_RECORD;
  END;

  --En Txn date conversion

  --Sn Duplicate RRN Check

  BEGIN

    SELECT COUNT(1)
     INTO V_RRN_COUNT
     FROM TRANSACTIONLOG
    WHERE TERMINAL_ID = P_TERMINAL_ID AND RRN = P_RRN AND
         BUSINESS_DATE = P_BUSINESS_DATE AND
         DELIVERY_CHANNEL = P_DELV_CHNL --Added by ramkumar.Mk on 25 march 2012
         AND CUSTOMER_CARD_NO = V_HASH_PAN --ADDED BY ABDUL HAMEED M.A ON 06-03-2014
             AND TXN_CODE        = P_TXN_CODE--ADDED BY ABDUL HAMEED M.A ON 06-03-2014
            AND MSGTYPE         = P_MSG_TYP;--ADDED BY ABDUL HAMEED M.A ON 06-03-2014

    IF V_RRN_COUNT > 0 THEN

     V_RESP_CDE := '22';
     V_ERRMSG   := 'Duplicate RRN from the Treminal' || P_TERMINAL_ID || 'on' ||
                P_BUSINESS_DATE;
     RAISE EXP_RVSL_REJECT_RECORD;

    END IF;

  END;

  --En Duplicate RRN Check
    
    --Sn get the product code
  BEGIN

    SELECT CAP_PROD_CODE, CAP_CARD_TYPE, CAP_PROXY_NUMBER, CAP_ACCT_NO,cap_card_stat,
           cap_prfl_code  --Added by Pankaj S. for enabling limit validation
     INTO V_PROD_CODE, V_CARD_TYPE, V_PROXUNUMBER, V_ACCT_NUMBER,v_cap_card_stat,  --v_cap_card_stat added for FSS-390
          v_prfl_code  --Added by Pankaj S. for enabling limit validation
     FROM CMS_APPL_PAN
    WHERE CAP_INST_CODE = P_INST_CODE AND CAP_PAN_CODE = V_HASH_PAN;
  EXCEPTION
    WHEN NO_DATA_FOUND THEN
     V_RESP_CDE := '21';
     V_ERRMSG   := P_CARD_NO || ' Card no not in master';
     RAISE EXP_RVSL_REJECT_RECORD;
    WHEN OTHERS THEN
     V_RESP_CDE := '21';
     V_ERRMSG   := 'Error while retriving card detail ' ||
                SUBSTR(SQLERRM, 1, 200);
     RAISE EXP_RVSL_REJECT_RECORD;
  END;
  ----En get the product code 
   --Sn get the profile code for product
      BEGIN
        SELECT cpc_profile_code 
         INTO v_profile_code
         FROM CMS_PROD_CATTYPE 
         WHERE CPC_INST_CODE =P_INST_CODE AND 
               CPC_PROD_CODE = V_PROD_CODE AND CPC_CARD_TYPE = V_CARD_TYPE;
        
      EXCEPTION
        WHEN NO_DATA_FOUND THEN
         V_RESP_CDE := '21';
         RAISE EXP_RVSL_REJECT_RECORD;
        WHEN OTHERS THEN
         V_RESP_CDE := '21';
         V_ERRMSG   := 'Error while retriving profile detail ' ||
                    SUBSTR(SQLERRM, 1, 200);
         RAISE EXP_RVSL_REJECT_RECORD;
      END;
      ----En get the product code
    
  --Select the Delivery Channel code of MM-POS
  BEGIN

    SELECT CDM_CHANNEL_CODE
     INTO V_DELCHANNEL_CODE
     FROM CMS_DELCHANNEL_MAST
    WHERE CDM_CHANNEL_DESC = 'MMPOS' AND CDM_INST_CODE = P_INST_CODE;

    IF P_CURR_CODE IS NULL AND V_DELCHANNEL_CODE = P_DELV_CHNL THEN

     BEGIN
       SELECT trim(CBP_PARAM_VALUE)
        INTO V_BASE_CURR
        FROM CMS_BIN_PARAM
        WHERE CBP_INST_CODE = P_INST_CODE AND CBP_PARAM_NAME = 'Currency'
        and CBP_PROFILE_CODE = V_PROFILE_CODE;

       IF V_BASE_CURR IS NULL THEN
        V_ERRMSG := 'Base currency cannot be null ';
        RAISE EXP_RVSL_REJECT_RECORD;
       END IF;
     EXCEPTION
       WHEN NO_DATA_FOUND THEN
        V_ERRMSG := 'Base currency is not defined for the  BIN PROFILE  ';
        RAISE EXP_RVSL_REJECT_RECORD;
       WHEN OTHERS THEN
        V_ERRMSG := 'Error while selecting base currency for BIN ' ||
                  SUBSTR(SQLERRM, 1, 200);
        RAISE EXP_RVSL_REJECT_RECORD;
     END;

     V_CURRCODE := V_BASE_CURR;

    ELSE
     V_CURRCODE := P_CURR_CODE;

    END IF;
  EXCEPTION
    WHEN OTHERS THEN
     V_ERRMSG := 'Error while CMS_DELCHANNEL_MAST  ' ||
               SUBSTR(SQLERRM, 1, 200);
     RAISE EXP_RVSL_REJECT_RECORD;
  END;

  --Sn check msg type
  IF V_DELCHANNEL_CODE <> P_DELV_CHNL THEN

    IF (P_MSG_TYP NOT IN ('0400', '0410', '0420', '0430', '9220', '9221')) OR
      (P_RVSL_CODE = '00') THEN

     V_RESP_CDE := '12';
     V_ERRMSG   := 'Not a valid reversal request';
     RAISE EXP_RVSL_REJECT_RECORD;

    END IF;
  END IF;
  --En check msg type

  --Sn check orginal transaction    (-- Amount is missing in reversal request)
  BEGIN
    SELECT DELIVERY_CHANNEL,
         TERMINAL_ID,
         RESPONSE_CODE,
         TXN_CODE,
         TXN_TYPE,
         TXN_MODE,
         BUSINESS_DATE,
         BUSINESS_TIME,
         CUSTOMER_CARD_NO,
         AMOUNT, --Transaction amount
         FEECODE,
           FEE_PLAN, --Added for FWR-11
         FEEATTACHTYPE, -- card level / prod cattype level
         TRANFEE_AMT, --Tranfee  Total    amount
         SERVICETAX_AMT, --Tran servicetax amount
         CESS_AMT, --Tran cess amount
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
         GL_UPD_FLAG,
         --Sn Added by Pankaj S. for enabling limit validation
         pos_verification,
         internation_ind_response,
         add_ins_date 
         --En Added by Pankaj S. for enabling limit validation
     INTO V_ORGNL_DELIVERY_CHANNEL,
         V_ORGNL_TERMINAL_ID,
         V_ORGNL_RESP_CODE,
         V_ORGNL_TXN_CODE,
         V_ORGNL_TXN_TYPE,
         V_ORGNL_TXN_MODE,
         V_ORGNL_BUSINESS_DATE,
         V_ORGNL_BUSINESS_TIME,
         V_ORGNL_CUSTOMER_CARD_NO,
         V_ORGNL_TOTAL_AMOUNT,
         V_ORGNL_TXN_FEECODE,
         V_ORGNL_TXN_FEE_PLAN, --Added for FWR-11
         V_ORGNL_TXN_FEEATTACHTYPE,
         V_ORGNL_TXN_TOTALFEE_AMT,
         V_ORGNL_TXN_SERVICETAX_AMT,
         V_ORGNL_TXN_CESS_AMT,
         V_ORGNL_TRANSACTION_TYPE,
         V_ORGNL_TERMID,
         V_ORGNL_MCCCODE,
         V_ACTUAL_FEECODE,
         V_ORGNL_TRANFEE_AMT,
         V_ORGNL_SERVICETAX_AMT,
         V_ORGNL_CESS_AMT,
         V_ORGNL_TRANFEE_CR_ACCTNO,
         V_ORGNL_TRANFEE_DR_ACCTNO,
         V_ORGNL_ST_CALC_FLAG,
         V_ORGNL_CESS_CALC_FLAG,
         V_ORGNL_ST_CR_ACCTNO,
         V_ORGNL_ST_DR_ACCTNO,
         V_ORGNL_CESS_CR_ACCTNO,
         V_ORGNL_CESS_DR_ACCTNO,
         V_CURR_CODE,
         V_TRAN_REVERSE_FLAG,
         V_GL_UPD_FLAG,
          --Sn Added by Pankaj S. for enabling limit validation
         v_pos_verification,
         v_internation_ind_response,
         v_add_ins_date
         --En Added by Pankaj S. for enabling limit validation
     FROM TRANSACTIONLOG
    WHERE RRN = P_ORGNL_RRN AND BUSINESS_DATE = P_ORGNL_BUSINESS_DATE AND
         BUSINESS_TIME = P_ORGNL_BUSINESS_TIME AND
         CUSTOMER_CARD_NO = V_HASH_PAN --P_card_no
         AND INSTCODE = P_INST_CODE 
         --AND TERMINAL_ID = P_ORGNL_TERMINAL_ID        -- Commented on 15-Feb-2013 for defect 10296
         AND DELIVERY_CHANNEL = P_DELV_CHNL; --Added by ramkumar.Mk on 25 march 2012

    IF V_ORGNL_RESP_CODE <> '00' THEN

     IF P_MSG_TYP NOT IN ('9220', '9221') THEN

       V_RESP_CDE := '23';
       V_ERRMSG   := ' The original transaction was not successful';
       RAISE EXP_RVSL_REJECT_RECORD;

     END IF;
    END IF;

    IF V_TRAN_REVERSE_FLAG = 'Y' THEN

     V_RESP_CDE := '52';
     V_ERRMSG   := 'The reversal already done for the orginal transaction';
     RAISE EXP_RVSL_REJECT_RECORD;

    END IF;

  EXCEPTION
    WHEN EXP_RVSL_REJECT_RECORD THEN
     RAISE;
    WHEN NO_DATA_FOUND THEN
     V_ORGNL_TXN := 'NO ORGNL TXN';
      V_ORGN_FOUND := 0; --Added by Pankaj S. for enabling limit validation
     IF P_MSG_TYP NOT IN ('9220', '9221') THEN

       V_RESP_CDE := '53';
       V_ERRMSG   := 'Matching transaction not found';
       RAISE EXP_RVSL_REJECT_RECORD;

     END IF;
    WHEN TOO_MANY_ROWS THEN
     IF P_MSG_TYP IN ('9220', '9221') THEN
       BEGIN
        SELECT SUM(TRANFEE_AMT), SUM(AMOUNT)
          INTO V_TOT_FEE_AMOUNT, V_TOT_AMOUNT
          FROM TRANSACTIONLOG
         WHERE RRN = P_ORGNL_RRN AND
              BUSINESS_DATE = P_ORGNL_BUSINESS_DATE AND
              BUSINESS_TIME = P_ORGNL_BUSINESS_TIME AND
              CUSTOMER_CARD_NO = V_HASH_PAN --P_card_no
              AND INSTCODE = P_INST_CODE 
              --AND TERMINAL_ID = P_ORGNL_TERMINAL_ID -- Commented on 15-Feb-2013 for defect 10296 
              AND RESPONSE_CODE = '00';
       EXCEPTION
        WHEN OTHERS THEN
          V_RESP_CDE := '21';
          V_ERRMSG   := 'Error while selecting TRANSACTIONLOG ' ||
                     SUBSTR(SQLERRM, 1, 200);
          RAISE EXP_RVSL_REJECT_RECORD;
       END;
       IF (V_TOT_FEE_AMOUNT IS NULL) AND (V_TOT_AMOUNT IS NULL) THEN

        V_ORGNL_TXN := 'NO ORGNL TXN';

       ELSIF V_TOT_FEE_AMOUNT > 0 THEN
        BEGIN
          SELECT DELIVERY_CHANNEL,
                TERMINAL_ID,
                RESPONSE_CODE,
                TXN_CODE,
                TXN_TYPE,
                TXN_MODE,
                BUSINESS_DATE,
                BUSINESS_TIME,
                CUSTOMER_CARD_NO,
                AMOUNT, --Transaction amount
                FEECODE,
                FEEATTACHTYPE, -- card level / prod cattype level
                TRANFEE_AMT, --Tranfee  Total    amount
                SERVICETAX_AMT, --Tran servicetax amount
                CESS_AMT, --Tran cess amount
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
                GL_UPD_FLAG,
                --Sn Added by Pankaj S. for enabling limit validation
                pos_verification,
                internation_ind_response,
                add_ins_date 
                --En Added by Pankaj S. for enabling limit validation
            INTO V_ORGNL_DELIVERY_CHANNEL,
                V_ORGNL_TERMINAL_ID,
                V_ORGNL_RESP_CODE,
                V_ORGNL_TXN_CODE,
                V_ORGNL_TXN_TYPE,
                V_ORGNL_TXN_MODE,
                V_ORGNL_BUSINESS_DATE,
                V_ORGNL_BUSINESS_TIME,
                V_ORGNL_CUSTOMER_CARD_NO,
                V_ORGNL_TOTAL_AMOUNT,
                V_ORGNL_TXN_FEECODE,
                V_ORGNL_TXN_FEEATTACHTYPE,
                V_ORGNL_TXN_TOTALFEE_AMT,
                V_ORGNL_TXN_SERVICETAX_AMT,
                V_ORGNL_TXN_CESS_AMT,
                V_ORGNL_TRANSACTION_TYPE,
                V_ORGNL_TERMID,
                V_ORGNL_MCCCODE,
                V_ACTUAL_FEECODE,
                V_ORGNL_TRANFEE_AMT,
                V_ORGNL_SERVICETAX_AMT,
                V_ORGNL_CESS_AMT,
                V_ORGNL_TRANFEE_CR_ACCTNO,
                V_ORGNL_TRANFEE_DR_ACCTNO,
                V_ORGNL_ST_CALC_FLAG,
                V_ORGNL_CESS_CALC_FLAG,
                V_ORGNL_ST_CR_ACCTNO,
                V_ORGNL_ST_DR_ACCTNO,
                V_ORGNL_CESS_CR_ACCTNO,
                V_ORGNL_CESS_DR_ACCTNO,
                V_CURR_CODE,
                V_TRAN_REVERSE_FLAG,
                V_GL_UPD_FLAG,
                --Sn Added by Pankaj S. for enabling limit validation
                v_pos_verification,
                v_internation_ind_response,
                v_add_ins_date
                --En Added by Pankaj S. for enabling limit validation
            FROM TRANSACTIONLOG
           WHERE RRN = P_ORGNL_RRN AND
                BUSINESS_DATE = P_ORGNL_BUSINESS_DATE AND
                BUSINESS_TIME = P_ORGNL_BUSINESS_TIME AND
                CUSTOMER_CARD_NO = V_HASH_PAN AND INSTCODE = P_INST_CODE 
                --AND TERMINAL_ID = P_ORGNL_TERMINAL_ID                     -- Commented on 15-Feb-2013 for defect 10296 
                AND RESPONSE_CODE = '00' AND DELIVERY_CHANNEL = P_DELV_CHNL --Added by ramkumar.Mk on 25 march 2012
                AND TRANFEE_CR_ACCTNO IS NOT NULL AND ROWNUM = 1;

          V_ORGNL_TOTAL_AMOUNT     := V_TOT_AMOUNT;
          V_ORGNL_TXN_TOTALFEE_AMT := V_TOT_FEE_AMOUNT;
          V_ORGNL_TRANFEE_AMT      := V_TOT_FEE_AMOUNT;
        EXCEPTION
          WHEN OTHERS THEN
            V_RESP_CDE := '21';
            V_ERRMSG   := 'Error while selecting TRANSACTIONLOG1 ' ||
                       SUBSTR(SQLERRM, 1, 200);
            RAISE EXP_RVSL_REJECT_RECORD;
        END;

        --Added to check the reversal already done or not for Incremental preauth by deepa
        IF V_TRAN_REVERSE_FLAG = 'Y' THEN

          V_RESP_CDE := '52';
          V_ERRMSG   := 'The reversal already done for the orginal transaction';
          RAISE EXP_RVSL_REJECT_RECORD;

        END IF;
       ELSE
        BEGIN
          SELECT DELIVERY_CHANNEL,
                TERMINAL_ID,
                RESPONSE_CODE,
                TXN_CODE,
                TXN_TYPE,
                TXN_MODE,
                BUSINESS_DATE,
                BUSINESS_TIME,
                CUSTOMER_CARD_NO,
                AMOUNT, --Transaction amount
                FEECODE,
                FEEATTACHTYPE, -- card level / prod cattype level
                TRANFEE_AMT, --Tranfee  Total    amount
                SERVICETAX_AMT, --Tran servicetax amount
                CESS_AMT, --Tran cess amount
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
                GL_UPD_FLAG,
                --Sn Added by Pankaj S. for enabling limit validation
                pos_verification,
                internation_ind_response,
                add_ins_date 
               --En Added by Pankaj S. for enabling limit validation
            INTO V_ORGNL_DELIVERY_CHANNEL,
                V_ORGNL_TERMINAL_ID,
                V_ORGNL_RESP_CODE,
                V_ORGNL_TXN_CODE,
                V_ORGNL_TXN_TYPE,
                V_ORGNL_TXN_MODE,
                V_ORGNL_BUSINESS_DATE,
                V_ORGNL_BUSINESS_TIME,
                V_ORGNL_CUSTOMER_CARD_NO,
                V_ORGNL_TOTAL_AMOUNT,
                V_ORGNL_TXN_FEECODE,
                V_ORGNL_TXN_FEEATTACHTYPE,
                V_ORGNL_TXN_TOTALFEE_AMT,
                V_ORGNL_TXN_SERVICETAX_AMT,
                V_ORGNL_TXN_CESS_AMT,
                V_ORGNL_TRANSACTION_TYPE,
                V_ORGNL_TERMID,
                V_ORGNL_MCCCODE,
                V_ACTUAL_FEECODE,
                V_ORGNL_TRANFEE_AMT,
                V_ORGNL_SERVICETAX_AMT,
                V_ORGNL_CESS_AMT,
                V_ORGNL_TRANFEE_CR_ACCTNO,
                V_ORGNL_TRANFEE_DR_ACCTNO,
                V_ORGNL_ST_CALC_FLAG,
                V_ORGNL_CESS_CALC_FLAG,
                V_ORGNL_ST_CR_ACCTNO,
                V_ORGNL_ST_DR_ACCTNO,
                V_ORGNL_CESS_CR_ACCTNO,
                V_ORGNL_CESS_DR_ACCTNO,
                V_CURR_CODE,
                V_TRAN_REVERSE_FLAG,
                V_GL_UPD_FLAG,
                 --Sn Added by Pankaj S. for enabling limit validation
                v_pos_verification,
                v_internation_ind_response,
                v_add_ins_date
                --En Added by Pankaj S. for enabling limit validation
            FROM TRANSACTIONLOG
           WHERE RRN = P_ORGNL_RRN AND
                BUSINESS_DATE = P_ORGNL_BUSINESS_DATE AND
                BUSINESS_TIME = P_ORGNL_BUSINESS_TIME AND
                CUSTOMER_CARD_NO = V_HASH_PAN --P_card_no
                AND INSTCODE = P_INST_CODE 
                --AND TERMINAL_ID = P_ORGNL_TERMINAL_ID                     -- Commented on 15-Feb-2013 for defect 10296 
                AND RESPONSE_CODE = '00' AND DELIVERY_CHANNEL = P_DELV_CHNL --Added by ramkumar.Mk on 25 march 2012
                AND ROWNUM = 1;

          V_ORGNL_TOTAL_AMOUNT     := V_TOT_AMOUNT;
          V_ORGNL_TXN_TOTALFEE_AMT := V_TOT_FEE_AMOUNT;
          V_ORGNL_TRANFEE_AMT      := V_TOT_FEE_AMOUNT;
        EXCEPTION
          WHEN OTHERS THEN
            V_RESP_CDE := '21';
            V_ERRMSG   := 'Error while selecting TRANSACTIONLOG2 ' ||
                       SUBSTR(SQLERRM, 1, 200);
            RAISE EXP_RVSL_REJECT_RECORD;
        END;
        --Added to check the reversal already done or not  for Incremental preauth by deepa
        IF V_TRAN_REVERSE_FLAG = 'Y' THEN

          V_RESP_CDE := '52';
          V_ERRMSG   := 'The reversal already done for the orginal transaction';
          RAISE EXP_RVSL_REJECT_RECORD;

        END IF;

       END IF;
     END IF;

    WHEN OTHERS THEN
     V_ORGNL_TXN := 'NO ORGNL TXN';
     IF P_MSG_TYP NOT IN ('9220', '9221') THEN
       V_RESP_CDE := '21';
       V_ERRMSG   := 'Error while selecting master data' ||
                  SUBSTR(SQLERRM, 1, 200);
       RAISE EXP_RVSL_REJECT_RECORD;

     END IF;
  END;
  --En check orginal transaction

  IF P_MSG_TYP = '9221' THEN

    SELECT COUNT(*)
     INTO V_SAF_TXN_COUNT
     FROM TRANSACTIONLOG
    WHERE RRN = P_RRN AND BUSINESS_DATE = P_BUSINESS_DATE AND
         CUSTOMER_CARD_NO = V_HASH_PAN --P_card_no
         AND INSTCODE = P_INST_CODE 
         --AND TERMINAL_ID = P_ORGNL_TERMINAL_ID                -- Commented on 15-Feb-2013 for defect 10296 
         AND RESPONSE_CODE = '00' AND MSGTYPE = '9220';

    IF V_SAF_TXN_COUNT > 0 THEN

     V_RESP_CDE := '38';
     V_ERRMSG   := 'Successful SAF Transaction has already done' ||
                SUBSTR(SQLERRM, 1, 200);
     RAISE EXP_RVSL_REJECT_RECORD;

    END IF;

  END IF;
  
  ------------------------
  --SN Added for FSS-1246 
  ------------------------  
  
  IF P_MSG_TYP in('9221','9220') THEN

    SELECT COUNT(*)
     INTO V_SAF_TRAN_COUNT
     FROM TRANSACTIONLOG
    WHERE ORGNL_RRN = P_ORGNL_RRN AND
         ORGNL_BUSINESS_DATE = P_ORGNL_BUSINESS_DATE AND
         CUSTOMER_CARD_NO = V_HASH_PAN 
         AND INSTCODE = P_INST_CODE 
         AND RESPONSE_CODE = '00' AND
         MSGTYPE IN ('9220', '9221')
         AND ORGNL_BUSINESS_TIME = P_ORGNL_BUSINESS_TIME; 

    IF V_SAF_TRAN_COUNT > 0 THEN

     V_RESP_CDE := '155'; --New response id FSS-1246 
     V_ERRMSG   := 'Successful SAF Preauth transaction has already done' ;  
     RAISE EXP_RVSL_REJECT_RECORD;

    END IF;

  END IF;
  
  ------------------------
  --EN Added for FSS-1246 
  ------------------------


  --Sn find the converted tran amt
  V_TRAN_AMT := P_ACTUAL_AMT;

  IF (P_ACTUAL_AMT >= 0) THEN

    BEGIN
     SP_CONVERT_CURR(P_INST_CODE,
                  V_CURRCODE,
                  P_CARD_NO,
                  P_ACTUAL_AMT,
                  V_RVSL_TRANDATE,
                  V_TRAN_AMT,
                  V_CARD_CURR,
                  V_ERRMSG,
                  V_PROD_CODE, 
                  V_CARD_TYPE);

     IF V_ERRMSG <> 'OK' THEN
       V_RESP_CDE := '44';
       RAISE EXP_RVSL_REJECT_RECORD;
     END IF;
    EXCEPTION
     WHEN EXP_RVSL_REJECT_RECORD THEN
       RAISE;
     WHEN OTHERS THEN
       V_RESP_CDE := '44'; -- Server Declined -220509
       V_ERRMSG   := 'Error from currency conversion ' ||
                  SUBSTR(SQLERRM, 1, 200);
       RAISE EXP_RVSL_REJECT_RECORD;
    END;
  ELSE
    -- If transaction Amount is zero - Invalid Amount -220509

    V_RESP_CDE := '13';
    V_ERRMSG   := 'INVALID AMOUNT';
    RAISE EXP_RVSL_REJECT_RECORD;

  END IF;

  --En find the  converted tran amt

  BEGIN

    SELECT CPT_TOTALHOLD_AMT,cpt_completion_fee,nvl(cpt_complfree_flag,'N')
     INTO V_HOLD_AMOUNT,v_completion_fee, v_complfree_flag
     FROM CMS_PREAUTH_TRANSACTION
    WHERE CPT_RRN = P_ORGNL_RRN AND CPT_TXN_DATE = P_ORGNL_BUSINESS_DATE AND
         CPT_INST_CODE = P_INST_CODE
          AND CPT_CARD_NO = V_HASH_PAN;--ADDED BY ABDUL HAMEED M.A ON 06-03-2014


  EXCEPTION
    WHEN NO_DATA_FOUND THEN

     BEGIN

       SELECT CPT_TOTALHOLD_AMT,cpt_completion_fee
        INTO V_HOLD_AMOUNT,v_completion_fee
        FROM CMS_PREAUTH_TRANSACTION
        WHERE CPT_RRN = P_ORGNL_RRN AND CPT_INST_CODE = P_INST_CODE AND
            CPT_CARD_NO = V_HASH_PAN;

     EXCEPTION
       WHEN NO_DATA_FOUND THEN
        V_HOLD_AMOUNT := -1; --If the original Preauth txn is not found
        V_ORGNL_TXN   := 'NO ORGNL TXN';
       WHEN OTHERS THEN
        V_HOLD_AMOUNT := -1; --If the original Preauth txn is not found
        V_ORGNL_TXN   := 'NO ORGNL TXN';
     END;
  END;

  --Sn Find the reversal amount based on dispensed amount based on Hold amount

  BEGIN
    IF (V_TRAN_AMT IS NULL OR V_TRAN_AMT = 0) THEN

     V_ACTUAL_DISPATCHED_AMT := 0;

    ELSE
     V_ACTUAL_DISPATCHED_AMT := V_TRAN_AMT;

    END IF;

    IF (V_HOLD_AMOUNT IS NULL OR V_HOLD_AMOUNT = 0) THEN

     V_REVERSAL_AMT := 0;

    ELSIF (V_HOLD_AMOUNT = -1) THEN

     V_REVERSAL_AMT := V_ACTUAL_DISPATCHED_AMT;

    ELSE

     V_REVERSAL_AMT := V_HOLD_AMOUNT - V_ACTUAL_DISPATCHED_AMT;

     IF V_REVERSAL_AMT < 0 THEN

       V_REVERSAL_AMT := V_HOLD_AMOUNT;

     END IF;

    END IF;
    
    IF V_REVERSAL_AMT < V_HOLD_AMOUNT THEN   ---Modified For Mantis id-0010997  
      V_REVERSAL_AMT_FLAG :='P';
    END IF;

  END;
  --En Find the reversal amount based on dispensed amount based on Hold amountnt








  --Sn find prod code and card type and available balance for the card number
  BEGIN
    SELECT CAM_ACCT_BAL, CAM_LEDGER_BAL, CAM_ACCT_NO,
           CAM_ACCT_ID,                                  --Added for FSS-1145/0010784
           cam_type_code --added by Pankaj S. for 10871 
     INTO  V_ACCT_BALANCE, V_LEDGER_BAL, V_CARD_ACCT_NO,
           V_ACCT_ID ,                                   --Added for FSS-1145/0010784
           v_acct_type --added by Pankaj S. for 10871
     FROM CMS_ACCT_MAST
    WHERE CAM_ACCT_NO = V_ACCT_NUMBER       --V_ACCT_NUMBER ued instead of subquery as per review observation for FSS-1246
    --         (SELECT CAP_ACCT_NO
    --            FROM CMS_APPL_PAN
    --           WHERE CAP_PAN_CODE = V_HASH_PAN AND CAP_MBR_NUMB = P_MBR_NUMB AND
    --                CAP_INST_CODE = P_INST_CODE) 
         AND CAM_INST_CODE = P_INST_CODE
        FOR UPDATE;                           -- Added for Concurrent Processsing Issue
        --FOR UPDATE NOWAIT;                     -- Commented for Concurrent Processsing Issue      
  EXCEPTION
    WHEN NO_DATA_FOUND THEN
     V_RESP_CDE := '14'; --Ineligible Transaction
     V_ERRMSG   := 'Invalid Card ';
     RAISE EXP_RVSL_REJECT_RECORD;
    WHEN OTHERS THEN
     V_RESP_CDE := '21';
     V_ERRMSG   := 'Error while selecting data from card Master for card number ' ||
                SQLERRM;
     RAISE EXP_RVSL_REJECT_RECORD;
  END;

  --En find prod code and card type for the card number
  
   ------------------------------------------------------
        --Sn Added for Concurrent Processsing Issue
    ------------------------------------------------------   
    
      BEGIN

        SELECT COUNT(1)
         INTO V_RRN_COUNT
         FROM TRANSACTIONLOG
        WHERE TERMINAL_ID = P_TERMINAL_ID AND RRN = P_RRN AND
             BUSINESS_DATE = P_BUSINESS_DATE AND
             DELIVERY_CHANNEL = P_DELV_CHNL
             AND CUSTOMER_CARD_NO = V_HASH_PAN --ADDED BY ABDUL HAMEED M.A ON 06-03-2014
             AND TXN_CODE        = P_TXN_CODE--ADDED BY ABDUL HAMEED M.A ON 06-03-2014
            AND MSGTYPE         = P_MSG_TYP;--ADDED BY ABDUL HAMEED M.A ON 06-03-2014

        IF V_RRN_COUNT > 0 THEN

         V_RESP_CDE := '22';
         V_ERRMSG   := 'Duplicate RRN from the Treminal' || P_TERMINAL_ID || 'on' ||
                    P_BUSINESS_DATE;
         RAISE EXP_RVSL_REJECT_RECORD;

        END IF;

      END;

      IF P_MSG_TYP = '9221' THEN

        SELECT COUNT(*)
         INTO V_SAF_TXN_COUNT
         FROM TRANSACTIONLOG
        WHERE RRN = P_RRN AND BUSINESS_DATE = P_BUSINESS_DATE AND
             CUSTOMER_CARD_NO = V_HASH_PAN 
             AND INSTCODE = P_INST_CODE 
             AND RESPONSE_CODE = '00' AND MSGTYPE = '9220';

        IF V_SAF_TXN_COUNT > 0 THEN

         V_RESP_CDE := '38';
         V_ERRMSG   := 'Successful SAF Transaction has already done' ||
                    SUBSTR(SQLERRM, 1, 200);
         RAISE EXP_RVSL_REJECT_RECORD;

        END IF;

      END IF;
      
      
      IF P_MSG_TYP in('9221','9220') THEN

        SELECT COUNT(*)
         INTO V_SAF_TRAN_COUNT
         FROM TRANSACTIONLOG
        WHERE ORGNL_RRN = P_ORGNL_RRN AND
             ORGNL_BUSINESS_DATE = P_ORGNL_BUSINESS_DATE AND
             CUSTOMER_CARD_NO = V_HASH_PAN 
             AND INSTCODE = P_INST_CODE 
             AND RESPONSE_CODE = '00' AND
             MSGTYPE IN ('9220', '9221')
             AND ORGNL_BUSINESS_TIME = P_ORGNL_BUSINESS_TIME; 

        IF V_SAF_TRAN_COUNT > 0 THEN

         V_RESP_CDE := '155'; 
         V_ERRMSG   := 'Successful SAF Preauth transaction has already done' ;  
         RAISE EXP_RVSL_REJECT_RECORD;

        END IF;

      END IF;    
    
    ------------------------------------------------------
        --En Added for Concurrent Processsing Issue
    ------------------------------------------------------      

 /* -- Query shifted above to remove subquery in CMS_ACCT_MAST as per review observation for FSS-1246
 
  --Sn get the product code
  BEGIN

    SELECT CAP_PROD_CODE, CAP_CARD_TYPE, CAP_PROXY_NUMBER, CAP_ACCT_NO,cap_card_stat
     INTO V_PROD_CODE, V_CARD_TYPE, V_PROXUNUMBER, V_ACCT_NUMBER,v_cap_card_stat  --v_cap_card_stat added for FSS-390
     FROM CMS_APPL_PAN
    WHERE CAP_INST_CODE = P_INST_CODE AND CAP_PAN_CODE = V_HASH_PAN;

  EXCEPTION
    WHEN NO_DATA_FOUND THEN
     V_RESP_CDE := '21';
     V_ERRMSG   := P_CARD_NO || ' Card no not in master';
     RAISE EXP_RVSL_REJECT_RECORD;

    WHEN OTHERS THEN
     V_RESP_CDE := '21';
     V_ERRMSG   := 'Error while retriving card detail ' ||
                SUBSTR(SQLERRM, 1, 200);
     RAISE EXP_RVSL_REJECT_RECORD;

  END;
  ----En get the product code
  
 */ -- Query shifted above to remove subquery in CMS_ACCT_MAST as per review observation for FSS-1246 

  -- Check for maximum card balance configured for the product profile.
  BEGIN

    SELECT TO_NUMBER(CBP_PARAM_VALUE)
     INTO V_MAX_CARD_BAL
     FROM CMS_BIN_PARAM
    WHERE CBP_INST_CODE = P_INST_CODE AND
         CBP_PARAM_NAME = 'Max Card Balance' AND
         CBP_PROFILE_CODE = V_PROFILE_CODE;

  EXCEPTION
    WHEN OTHERS THEN
     V_RESP_CDE := '21';
     V_ERRMSG   := 'ERROR IN FETCHING CARD BALANCE CONFIGURATION FOR THE PRODUCT CATTYPE PROFILE ' ||
                SUBSTR(SQLERRM, 1, 200);
     RAISE EXP_RVSL_REJECT_RECORD;

  END;

  --Sn check balance

    /*                                          --Commented for FSS-1145
      IF V_ORGNL_TXN = 'NO ORGNL TXN' THEN

        V_LEDGER_BAL := V_LEDGER_BAL + V_REVERSAL_AMT;

      END IF;
    */    
    
   IF nvl(V_ORGNL_TXN,'1') <> 'NO ORGNL TXN' THEN -- IF condition Added for FSS-1145
    
      IF ((V_ACCT_BALANCE + V_REVERSAL_AMT) > V_MAX_CARD_BAL) OR
        (V_LEDGER_BAL > V_MAX_CARD_BAL) THEN

        BEGIN
            IF v_cap_card_stat<>'12' THEN --Added for FSS-390
             UPDATE CMS_APPL_PAN
                SET CAP_CARD_STAT = '12'
              WHERE CAP_PAN_CODE = V_HASH_PAN AND CAP_INST_CODE = P_INST_CODE;
             IF SQL%ROWCOUNT = 0 THEN

               V_ERRMSG   := 'Error while updating the card status';
               V_RESP_CDE := '21';
               RAISE EXP_RVSL_REJECT_RECORD;
             END IF;
             --Sn Added for FSS-390
            v_chnge_crdstat:='Y';
            END IF;
            --En Added for FSS-390 
        EXCEPTION
         WHEN OTHERS THEN
           V_RESP_CDE := '21';
           V_ERRMSG   := 'Error while updating cms_appl_pan ' ||
                      SUBSTR(SQLERRM, 1, 200);
           RAISE EXP_RVSL_REJECT_RECORD;
        END;
        
      END IF;
      
   end if;   

  --En check balance

  --Sn Check the Flag for Reversal transaction

  IF V_TRAN_PREAUTH_FLAG != 'Y' THEN

    IF V_DR_CR_FLAG = 'NA' THEN
     V_RESP_CDE := '21';
     V_ERRMSG   := 'Not a valid orginal transaction for reversal';
     RAISE EXP_RVSL_REJECT_RECORD;
    END IF;

  END IF;

  --En Check the Flag for Reversal transaction

  --Sn Check the transaction type with Original txn type

  IF V_DR_CR_FLAG <> V_ORGNL_TRANSACTION_TYPE THEN
    V_RESP_CDE := '21';
    V_ERRMSG   := 'Orginal transaction type is not matching with actual transaction type';
    RAISE EXP_RVSL_REJECT_RECORD;
  END IF;

  --En Check the transaction type
  
  --Sn-commented for fwr-48

  --Sn find the orginal func code
 /* BEGIN
    SELECT CFM_FUNC_CODE
     INTO V_FUNC_CODE
     FROM CMS_FUNC_MAST
    WHERE CFM_TXN_CODE = P_TXN_CODE AND CFM_TXN_MODE = P_TXN_MODE AND
         CFM_DELIVERY_CHANNEL = P_DELV_CHNL AND
         CFM_INST_CODE = P_INST_CODE;
    --TXN mode and delivery channel we need to attach
    --bkz txn code may be same for all type of channels
  EXCEPTION
    WHEN NO_DATA_FOUND THEN

     V_RESP_CDE := '69'; --Ineligible Transaction
     V_ERRMSG   := 'Function code not defined for txn code ' || P_TXN_CODE;
     RAISE EXP_RVSL_REJECT_RECORD;

    WHEN TOO_MANY_ROWS THEN

     V_RESP_CDE := '69';
     V_ERRMSG   := 'More than one function defined for txn code ' ||
                P_TXN_CODE;
     RAISE EXP_RVSL_REJECT_RECORD;

    WHEN OTHERS THEN

     V_RESP_CDE := '69';
     V_ERRMSG   := 'Problem while selecting function code from function mast  ' ||
                SUBSTR(SQLERRM, 1, 200);
     RAISE EXP_RVSL_REJECT_RECORD;
  END;*/

  --En find the orginal func code

 --En-commented for fwr-48
  ---Sn find cutoff time
  BEGIN
    SELECT CIP_PARAM_VALUE
     INTO V_CUTOFF_TIME
     FROM CMS_INST_PARAM
    WHERE CIP_PARAM_KEY = 'CUTOFF' AND CIP_INST_CODE = P_INST_CODE;

  EXCEPTION
    WHEN NO_DATA_FOUND THEN
     V_CUTOFF_TIME := 0;
     V_RESP_CDE    := '21';
     V_ERRMSG      := 'Cutoff time is not defined in the system';
     RAISE EXP_RVSL_REJECT_RECORD;

    WHEN OTHERS THEN

     V_RESP_CDE := '21';
     V_ERRMSG   := 'Error while selecting cutoff  dtl  from system ';
     RAISE EXP_RVSL_REJECT_RECORD;

  END;
  ---En find cutoff time
  
    v_timestamp:=systimestamp;  --added by Pankaj S. for 10871

  BEGIN

    IF V_ORGNL_TXN = 'NO ORGNL TXN' THEN

     V_ORGNL_RRN := 'N:' || P_ORGNL_RRN;
    ELSE

     V_ORGNL_RRN := 'Y:' || P_ORGNL_RRN;

    END IF;

    /*IF V_ORGNL_TXN_TOTALFEE_AMT > 0 THEN

     BEGIN

      SELECT csl_trans_narrration,CSL_MERCHANT_NAME,CSL_MERCHANT_CITY,CSL_MERCHANT_STATE
      INTO V_FEE_NARRATION,V_FEE_MERCHNAME,V_FEE_MERCHCITY,V_FEE_MERCHSTATE--Mofified by Deepa on 09-May-2012 to include Merchant name,city and state in statements log
         FROM cms_statements_log
         WHERE csl_business_date = V_ORGNL_BUSINESS_DATE
         AND csl_business_time = V_ORGNL_BUSINESS_TIME
         AND csl_rrn = P_ORGNL_RRN
         AND csl_delivery_channel = V_ORGNL_DELIVERY_CHANNEL
         AND csl_txn_code = V_ORGNL_TXN_CODE
         AND csl_pan_no = V_ORGNL_CUSTOMER_CARD_NO
         AND csl_inst_code = P_INST_CODE
         AND TXN_FEE_FLAG='Y' AND rownum=1;

         EXCEPTION
             WHEN NO_DATA_FOUND THEN
             V_FEE_NARRATION:=NULL;
             WHEN OTHERS THEN
             V_FEE_NARRATION:=NULL;
     END;
    END IF;*/

    --En find narration
    
    IF nvl(V_ORGNL_TXN,'1') <> 'NO ORGNL TXN' -- IF condition Added for FSS-1145
    THEN
     
       -- FSS - 837 changes
        BEGIN
          
           SELECT cpt_compl_txncode
          INTO v_completion_txn_code
          FROM cms_preauthcomp_txncode
           WHERE cpt_inst_code = p_inst_code AND cpt_preauth_txncode = p_txn_code;
          
        EXCEPTION
            WHEN OTHERS THEN
           V_RESP_CDE := '21';
           V_ERRMSG  := 'Error while selecting data for Completion transaction code ' ||
                      SQLERRM;
           RAISE EXP_RVSL_REJECT_RECORD;
         END;
         
      IF(V_HOLD_AMOUNT <> V_REVERSAL_AMT) THEN
         
           BEGIN

         sp_tran_fees_cmsauth (p_inst_code,
                               p_card_no,
                               P_DELV_CHNL,
                               '1',
                               V_ORGNL_TXN_MODE,
                               v_completion_txn_code,
                               p_curr_code,
                               NULL,
                               null,
                               v_tran_amt,
                               v_tran_date,
                               v_internation_ind_response,
                               v_pos_verification,
                               '1',
                               '0200',
                               '00',
                               V_ORGNL_MCCCODE,
                               v_comp_fee_amt,
                               v_comp_error,
                               v_comp_fee_code,
                               v_comp_fee_crgl_catg,
                               v_comp_fee_crgl_code,
                               v_comp_fee_crsubgl_code,
                               v_comp_fee_cracct_no,
                               v_comp_fee_drgl_catg,
                               v_comp_fee_drgl_code,
                               v_comp_fee_drsubgl_code,
                               v_comp_fee_dracct_no,
                               v_comp_st_calc_flag,
                               v_comp_cess_calc_flag,
                               v_comp_st_cracct_no,
                               v_comp_st_dracct_no,
                               v_comp_cess_cracct_no,
                               v_comp_cess_dracct_no,
                               v_comp_feeamnt_type,
                               v_comp_clawback,
                               v_comp_fee_plan,
                               v_comp_per_fees,
                               v_comp_flat_fees,
                               v_comp_freetxn_exceed,
                               v_comp_duration,
                               v_comp_feeattach_type,
                               V_COMP_FEE_DESC  
                              );

         IF v_comp_error <> 'OK'
         THEN
            v_resp_cde := '21';
            V_ERRMSG := v_comp_error;
            RAISE EXP_RVSL_REJECT_RECORD;
         END IF;

        EXCEPTION
         WHEN EXP_RVSL_REJECT_RECORD
         THEN
            RAISE;
         WHEN OTHERS
         THEN
            v_resp_cde := '21';
            V_ERRMSG :=
                   'Error from fee calc process ' || SUBSTR (SQLERRM, 1, 200);
            RAISE EXP_RVSL_REJECT_RECORD;

        END;

     
     --Sn calculate waiver on the fee
        BEGIN
         sp_calculate_waiver (p_inst_code,
                              p_card_no,
                              '000',
                              v_prod_code,
                              V_CARD_TYPE,
                              v_comp_fee_code,
                              v_comp_fee_plan,
                              v_tran_date,
                              v_comp_waiv_percnt,
                              v_comp_err_waiv
                             );

         IF v_comp_err_waiv <> 'OK'
         THEN
            v_resp_cde := '21';
            V_ERRMSG := v_comp_err_waiv;
            RAISE EXP_RVSL_REJECT_RECORD;
         END IF;
       EXCEPTION
         WHEN EXP_RVSL_REJECT_RECORD
         THEN
            RAISE;
         WHEN OTHERS
         THEN
            v_resp_cde := '21';
            V_ERRMSG :=
                'Error from waiver calc process ' || SUBSTR (SQLERRM, 1, 200);
            RAISE EXP_RVSL_REJECT_RECORD;
       END;

      --En calculate waiver on the fee

      --Sn apply waiver on fee amount
      v_comp_fee_amt := ROUND (v_comp_fee_amt - ((v_comp_fee_amt * v_comp_waiv_percnt) / 100), 2);

      --En apply waiver on fee amount

      --Sn apply service tax and cess
          IF v_comp_st_calc_flag = 1
          THEN
             v_comp_servicetax_amount := (v_comp_fee_amt * v_comp_servicetax_percent) / 100;
          ELSE
             v_comp_servicetax_amount := 0;
          END IF;

        IF v_comp_cess_calc_flag = 1
        THEN
         v_comp_cess_amount := (v_comp_servicetax_amount * v_comp_cess_percent) / 100;
        ELSE
         v_comp_cess_amount := 0;
        END IF;

      v_comp_total_fee :=
                    ROUND (v_comp_fee_amt + v_comp_servicetax_amount + v_comp_cess_amount, 2);
     END IF;
     
     
     
     IF(v_comp_total_fee=v_completion_fee) THEN
        v_reverse_compl_fee:=0;
        v_comp_fee:=0;
        v_complfee_increment_type:='N';
        ELSIF(v_comp_total_fee > v_completion_fee) THEN
        v_reverse_compl_fee:=0;
        v_comp_fee:=v_comp_total_fee-v_completion_fee;
        v_complfee_increment_type:='D';
        ELSE
        IF(v_comp_total_fee < v_completion_fee) THEN
        v_reverse_compl_fee:=v_completion_fee-v_comp_total_fee;
        v_comp_fee:=v_reverse_compl_fee;
        v_complfee_increment_type:='C';
        END IF;
        END IF;
           
    ELSE 
       
       v_reverse_compl_fee:=v_completion_fee;
        v_comp_fee:=v_completion_fee;
        v_complfee_increment_type:='C';
        
    END IF;
    
     
      IF v_complfree_flag='Y' AND v_completion_fee=0 THEN
    SELECT ctd_compfee_code
      INTO v_comp_fee_code
      FROM cms_transaction_log_dtl
     WHERE     ctd_rrn = p_orgnl_rrn
           AND ctd_business_date = p_orgnl_business_date
           AND ctd_business_time = p_orgnl_business_time
           AND ctd_customer_card_no = v_hash_pan
           AND ctd_inst_code = p_inst_code
           and ctd_txn_code=v_orgnl_txn_code
           AND ctd_delivery_channel = p_delv_chnl;
   BEGIN
       vmsfee.fee_freecnt_reverse (v_card_acct_no, v_comp_fee_code, v_errmsg);
    
       IF v_errmsg <> 'OK' THEN
          v_resp_cde := '21';
          RAISE exp_rvsl_reject_record;
       END IF;
    EXCEPTION
       WHEN exp_rvsl_reject_record THEN
          RAISE;
       WHEN OTHERS THEN
          v_resp_cde := '21';
          v_errmsg :='Error while reversing complfree count-'|| SUBSTR (SQLERRM, 1, 200);
          RAISE exp_rvsl_reject_record;
    END;
  END IF;
     
    IF nvl(V_ORGNL_TXN,'1') <> 'NO ORGNL TXN' -- IF condition Added for FSS-1145
    THEN
     
     
        SP_REVERSE_CARD_AMOUNT(P_INST_CODE,
                          V_FUNC_CODE,
                          P_RRN,
                          P_DELV_CHNL,
                          P_ORGNL_TERMINAL_ID,
                          P_MERC_ID,
                          P_TXN_CODE,
                          V_RVSL_TRANDATE,
                          P_TXN_MODE,
                          P_CARD_NO,
                          V_REVERSAL_AMT+v_reverse_compl_fee,
                          V_ORGNL_RRN,
                          V_CARD_ACCT_NO,
                          P_BUSINESS_DATE,
                          P_BUSINESS_TIME,
                          V_AUTH_ID,
                          V_TXN_NARRATION,
                          P_ORGNL_BUSINESS_DATE,
                          P_ORGNL_BUSINESS_TIME,
                          /*NULL, --Added by Deepa on 09-May-2012 to include Merchant name,city and state in statements log
                          NULL,
                          NULL,*/
                          --Commented and modified on 21.03.2013 for Merchant Logging Info for the Reversal Txn
                          P_MERCHANT_NAME,
                          P_MERCHANT_CITY,
                          P_MERCHANT_STATE,      
                          V_RESP_CDE,
                          V_ERRMSG);
                          
        IF V_RESP_CDE <> '00' OR V_ERRMSG <> 'OK' THEN
         RAISE EXP_RVSL_REJECT_RECORD;
        END IF;
      
    END IF;
     
    
  EXCEPTION
    WHEN EXP_RVSL_REJECT_RECORD THEN
     RAISE;
    WHEN OTHERS THEN
     V_RESP_CDE := '21';
     V_ERRMSG   := 'Error while reversing the amount ' ||
                SUBSTR(SQLERRM, 1, 200);
     RAISE EXP_RVSL_REJECT_RECORD;
  END;
  --En reverse the amount
  --Added by Deepa For Reversal Fees on June 27 2012
  IF V_REVERSAL_AMT_FLAG <>'P' THEN   --Modified For Mantis Id-0010997
  IF nvl(V_ORGNL_TXN,'1') <> 'NO ORGNL TXN' -- IF condition Added for FSS-1145
  THEN   

      IF V_ORGNL_TXN_TOTALFEE_AMT > 0 or V_ORGNL_TXN_FEECODE is not null  THEN --Modified for FWR-11
      -- SN Added for FWR-11
       Begin 
         select CFM_FEECAP_FLAG,CFM_FEE_AMT into v_feecap_flag,v_orgnl_fee_amt from CMS_FEE_MAST 
         where CFM_INST_CODE = P_INST_CODE and CFM_FEE_CODE = V_ORGNL_TXN_FEECODE;
        EXCEPTION
          WHEN NO_DATA_FOUND THEN
                v_feecap_flag := '';
          WHEN OTHERS THEN
              V_ERRMSG := 'Error in feecap flag fetch ' || SUBSTR(SQLERRM, 1, 200);
              RAISE EXP_RVSL_REJECT_RECORD;
        End;
        -- EN Added for FWR-11

        BEGIN

         FOR C1 IN FEEREVERSE LOOP
      -- SN Added for FWR-11
      V_ORGNL_TRANFEE_AMT := C1.CSL_TRANS_AMOUNT;
    
        if v_feecap_flag = 'Y' then 
        BEGIN
            SP_TRAN_FEES_REVCAPCHECK(P_INST_CODE,
                    V_ACCT_NUMBER,
                    V_ORGNL_BUSINESS_DATE,
                    V_ORGNL_TRANFEE_AMT,
                    v_orgnl_fee_amt,
                    V_ORGNL_TXN_FEE_PLAN,
                    V_ORGNL_TXN_FEECODE,
                    V_ERRMSG                 
                  ); -- Added for FWR-11
          EXCEPTION
          WHEN OTHERS THEN
          V_RESP_CDE := '21';
          V_ERRMSG   := 'Error while reversing the fee Cap amount ' ||
                     SUBSTR(SQLERRM, 1, 200);
          RAISE EXP_RVSL_REJECT_RECORD;
       END;
      End if;
    -- EN Added for FWR-11
           BEGIN
            SP_REVERSE_FEE_AMOUNT(P_INST_CODE,
                              P_RRN,
                              P_DELV_CHNL,
                              P_ORGNL_TERMINAL_ID,
                              P_MERC_ID,
                              P_TXN_CODE,
                              V_RVSL_TRANDATE,
                              P_TXN_MODE,
                               -- C1.CSL_TRANS_AMOUNT,
                               V_ORGNL_TRANFEE_AMT, -- Modified for FWR-11
                              P_CARD_NO,
                              V_ACTUAL_FEECODE,
                               -- C1.CSL_TRANS_AMOUNT,
                                V_ORGNL_TRANFEE_AMT, -- Modified for FWR-11
                              V_ORGNL_TRANFEE_CR_ACCTNO,
                              V_ORGNL_TRANFEE_DR_ACCTNO,
                              V_ORGNL_ST_CALC_FLAG,
                              V_ORGNL_SERVICETAX_AMT,
                              V_ORGNL_ST_CR_ACCTNO,
                              V_ORGNL_ST_DR_ACCTNO,
                              V_ORGNL_CESS_CALC_FLAG,
                              V_ORGNL_CESS_AMT,
                              V_ORGNL_CESS_CR_ACCTNO,
                              V_ORGNL_CESS_DR_ACCTNO,
                              P_ORGNL_RRN,
                              V_CARD_ACCT_NO,
                              P_BUSINESS_DATE,
                              P_BUSINESS_TIME,
                              V_AUTH_ID,
                              C1.CSL_TRANS_NARRRATION,
                              /*C1.CSL_MERCHANT_NAME,
                              C1.CSL_MERCHANT_CITY,
                              C1.CSL_MERCHANT_STATE,*/--Commented and modified on 21.03.2013 for Merchant Logging Info for the Reversal Txn
                              P_MERCHANT_NAME,
                              P_MERCHANT_CITY,
                              P_MERCHANT_STATE,                          
                              V_RESP_CDE,
                              V_ERRMSG);

            V_FEE_NARRATION := C1.CSL_TRANS_NARRRATION;

            IF V_RESP_CDE <> '00' OR V_ERRMSG <> 'OK' THEN
              RAISE EXP_RVSL_REJECT_RECORD;
            END IF;

           EXCEPTION
            WHEN EXP_RVSL_REJECT_RECORD THEN
              RAISE;

            WHEN OTHERS THEN
              V_RESP_CDE := '21';
              V_ERRMSG   := 'Error while reversing the fee amount ' ||
                         SUBSTR(SQLERRM, 1, 200);
              RAISE EXP_RVSL_REJECT_RECORD;
           END;

         END LOOP;

        EXCEPTION
         WHEN NO_DATA_FOUND THEN
           V_FEE_NARRATION := NULL;
         WHEN OTHERS THEN
           V_FEE_NARRATION := NULL;

        END;

      END IF;
 
   

      --Added by Deepa For Reversal Fees on June 27 2012
      IF V_FEE_NARRATION IS NULL THEN
      --SN Added for FWR-11
           if v_feecap_flag = 'Y' then 
        BEGIN
            SP_TRAN_FEES_REVCAPCHECK(P_INST_CODE,
                    V_ACCT_NUMBER,
                    V_ORGNL_BUSINESS_DATE,
                    V_ORGNL_TRANFEE_AMT,
                    v_orgnl_fee_amt,
                    V_ORGNL_TXN_FEE_PLAN,
                    V_ORGNL_TXN_FEECODE,
                    V_ERRMSG                 
                  ); -- Added for FWR-11
        EXCEPTION
          WHEN OTHERS THEN
          V_RESP_CDE := '21';
          V_ERRMSG   := 'Error while reversing the fee Cap amount ' ||
                     SUBSTR(SQLERRM, 1, 200);
          RAISE EXP_RVSL_REJECT_RECORD;
       END;
       End if;
       --EN Added for FWR-11
        BEGIN
         SP_REVERSE_FEE_AMOUNT(P_INST_CODE,
                           P_RRN,
                           P_DELV_CHNL,
                           P_ORGNL_TERMINAL_ID,
                           P_MERC_ID,
                           P_TXN_CODE,
                           V_RVSL_TRANDATE,
                           P_TXN_MODE,
                           V_ORGNL_TXN_TOTALFEE_AMT,
                           P_CARD_NO,
                           V_ACTUAL_FEECODE,
                           V_ORGNL_TRANFEE_AMT,
                           V_ORGNL_TRANFEE_CR_ACCTNO,
                           V_ORGNL_TRANFEE_DR_ACCTNO,
                           V_ORGNL_ST_CALC_FLAG,
                           V_ORGNL_SERVICETAX_AMT,
                           V_ORGNL_ST_CR_ACCTNO,
                           V_ORGNL_ST_DR_ACCTNO,
                           V_ORGNL_CESS_CALC_FLAG,
                           V_ORGNL_CESS_AMT,
                           V_ORGNL_CESS_CR_ACCTNO,
                           V_ORGNL_CESS_DR_ACCTNO,
                           P_ORGNL_RRN,
                           V_CARD_ACCT_NO,
                           P_BUSINESS_DATE,
                           P_BUSINESS_TIME,
                           V_AUTH_ID,
                           V_FEE_NARRATION,
                           /*V_FEE_MERCHNAME,
                           V_FEE_MERCHCITY,
                           V_FEE_MERCHSTATE,*/--Commented and modified on 21.03.2013 for Merchant Logging Info for the Reversal Txn
                           P_MERCHANT_NAME, 
                           P_MERCHANT_CITY,
                           P_MERCHANT_STATE,                                             
                           V_RESP_CDE,
                           V_ERRMSG);

         IF V_RESP_CDE <> '00' OR V_ERRMSG <> 'OK' THEN
           RAISE EXP_RVSL_REJECT_RECORD;
         END IF;

        EXCEPTION
         WHEN EXP_RVSL_REJECT_RECORD THEN
           RAISE;

         WHEN OTHERS THEN
           V_RESP_CDE := '21';
           V_ERRMSG   := 'Error while reversing the fee amount ' ||
                      SUBSTR(SQLERRM, 1, 200);
           RAISE EXP_RVSL_REJECT_RECORD;
        END;

      END IF;

  END IF;
  END IF; ----Added For Mantis-Id-0010997

  --En reverse the fee

  IF V_GL_UPD_FLAG = 'Y' AND nvl(V_ORGNL_TXN,'1') <> 'NO ORGNL TXN' -- AND V_ORGNL_TXN <> 'NO ORGNL TXN'condition Added for FSS-1145
  THEN

    --Sn find business date
    V_BUSINESS_TIME := TO_CHAR(V_RVSL_TRANDATE, 'HH24:MI');
    IF V_BUSINESS_TIME > V_CUTOFF_TIME THEN
     V_RVSL_TRANDATE := TRUNC(V_RVSL_TRANDATE) + 1;
    ELSE
     V_RVSL_TRANDATE := TRUNC(V_RVSL_TRANDATE);
    END IF;
    --En find businesses date
    
    --Sn-commented for fwr-48

  /*  SP_REVERSE_GL_ENTRIES(P_INST_CODE,
                     V_RVSL_TRANDATE,
                     V_PROD_CODE,
                     V_CARD_TYPE,
                     V_REVERSAL_AMT,
                     V_FUNC_CODE,
                     P_TXN_CODE,
                     V_DR_CR_FLAG,
                     P_CARD_NO,
                     V_ACTUAL_FEECODE,
                     V_ORGNL_TXN_TOTALFEE_AMT,
                     V_ORGNL_TRANFEE_CR_ACCTNO,
                     V_ORGNL_TRANFEE_DR_ACCTNO,
                     V_CARD_ACCT_NO,
                     P_RVSL_CODE,
                     P_MSG_TYP,
                     P_DELV_CHNL,
                     V_RESP_CDE,
                     V_GL_UPD_FLAG,
                     V_ERRMSG);
    IF V_GL_UPD_FLAG <> 'Y' THEN
     V_RESP_CDE := '21';
     V_ERRMSG   := V_ERRMSG || 'Error while retriving gl detail ' ||
                SUBSTR(SQLERRM, 1, 200);
     RAISE EXP_RVSL_REJECT_RECORD;
    END IF;*/ --En - commented for fwr-48

  END IF;
  --En reverse the GL entries
  
  --Sn Logging of system initiated card status change(FSS-390)
    IF v_chnge_crdstat='Y' THEN 
    BEGIN
       sp_log_cardstat_chnge (p_inst_code,
                              v_hash_pan,
                              v_encr_pan,
                              v_auth_id,
                              '03',
                              p_rrn,
                              p_business_date,
                              p_business_time,
                              v_resp_cde,
                              v_errmsg
                             );

       IF v_resp_cde <> '00' AND v_errmsg <> 'OK'
       THEN
          RAISE exp_rvsl_reject_record;
       END IF;
    EXCEPTION
       WHEN exp_rvsl_reject_record
       THEN
          RAISE;
       WHEN OTHERS
       THEN
          v_resp_cde := '21';
          v_errmsg :=
                'Error while logging system initiated card status change '
             || SUBSTR (SQLERRM, 1, 200);
          RAISE exp_rvsl_reject_record;
    END;
    END IF;
    --En Logging of system initiated card status change(FSS-390) 

  --Sn create a entry for successful
  BEGIN

    IF V_ERRMSG = 'OK' THEN

     INSERT INTO CMS_TRANSACTION_LOG_DTL
       (CTD_DELIVERY_CHANNEL,
        CTD_TXN_CODE,
        CTD_TXN_TYPE,
        CTD_MSG_TYPE,
        CTD_TXN_MODE,
        CTD_BUSINESS_DATE,
        CTD_BUSINESS_TIME,
        CTD_CUSTOMER_CARD_NO,
        CTD_TXN_AMOUNT,
        CTD_TXN_CURR,
        CTD_ACTUAL_AMOUNT,
        CTD_BILL_AMOUNT,
        CTD_BILL_CURR,
        CTD_PROCESS_FLAG,
        CTD_PROCESS_MSG,
        CTD_RRN,
        CTD_SYSTEM_TRACE_AUDIT_NO,
        CTD_INST_CODE,
        CTD_CUSTOMER_CARD_NO_ENCR,
        CTD_CUST_ACCT_NUMBER,
        /* Start Added by Dhiraj G on 31052012 for Pre - Auth Parameter changes  */
        CTD_NETWORK_ID,
        CTD_INTERCHANGE_FEEAMT,
        CTD_MERCHANT_ZIP,
        /* End Added by Dhiraj G on 31052012 for Pre - Auth Parameter changes  */
        CTD_MERCHANT_ID     --Added on 19-Mar-2013 for FSS-970
        ,CTD_INTERNATION_IND_RESPONSE,
        ctd_completion_fee,ctd_complfee_increment_type 
        )
     VALUES
       (P_DELV_CHNL,
        P_TXN_CODE,
        V_TXN_TYPE,
        P_MSG_TYP,
        P_TXN_MODE,
        P_BUSINESS_DATE,
        P_BUSINESS_TIME,
        V_HASH_PAN,
        P_ACTUAL_AMT,
        V_CURRCODE,
        V_TRAN_AMT,
        V_REVERSAL_AMT,
        V_CARD_CURR,
        'Y',
        'Successful',
        P_RRN,
        P_STAN,
        P_INST_CODE,
        V_ENCR_PAN,
        V_ACCT_NUMBER,
        /* Start Added by Dhiraj G on 31052012 for Pre - Auth Parameter changes  */
        P_NETWORK_ID,
        P_INTERCHANGE_FEEAMT,
        P_MERCHANT_ZIP,
        /* End  Added by Dhiraj G on 31052012 for Pre - Auth Parameter changes  */
        P_MERCHANT_ID  --Added on 19-Mar-2013 for FSS-970
        ,v_internation_ind_response,
        v_comp_fee,v_complfee_increment_type
        );
    END IF;

    --Added the 5 empty values for CMS_TRANSACTION_LOG_DTL in cms
  EXCEPTION
    WHEN OTHERS THEN
     V_ERRMSG   := 'Problem while selecting data from response master ' ||
                SUBSTR(SQLERRM, 1, 300);
     V_RESP_CDE := '21';
     RAISE EXP_RVSL_REJECT_RECORD;
  END;

  --En create a entry for successful
  --Sn generate response code

  V_RESP_CDE := '1';

  --Added By Deepa for the Narration of Transaction Fee
  --Sn getting the Merchant details of Original txn
  BEGIN
    SELECT CPH_MERCHANT_NAME, CPH_MERCHANT_CITY, CPH_MERCHANT_STATE
     INTO V_TXN_MERCHNAME, V_TXN_MERCHCITY, V_TXN_MERCHSTATE
     FROM CMS_PREAUTH_TRANS_HIST
    WHERE CPH_RRN = P_ORGNL_RRN AND CPH_CARD_NO = V_HASH_PAN AND
         CPH_MBR_NO = P_MBR_NUMB AND CPH_TXN_DATE = P_ORGNL_BUSINESS_DATE AND
         CPH_INST_CODE = P_INST_CODE AND
         CPH_TRANSACTION_FLAG IN ('N', 'I') AND ROWNUM = 1;

  EXCEPTION
    WHEN NO_DATA_FOUND THEN
     NULL;
    WHEN OTHERS THEN
     NULL;
  END;
  --En getting the Merchant details of Original txn

  IF TRIM(V_TRAN_DESC) IS NOT NULL THEN

    V_NARRATION := V_TRAN_DESC || '/';

  END IF;

  IF TRIM(V_TXN_MERCHNAME) IS NOT NULL THEN

    V_NARRATION := V_NARRATION || V_TXN_MERCHNAME || '/';

  END IF;

  IF TRIM(V_TXN_MERCHCITY) IS NOT NULL THEN

    V_NARRATION := V_NARRATION || V_TXN_MERCHCITY || '/';

  END IF;

  IF TRIM(P_BUSINESS_DATE) IS NOT NULL THEN

    V_NARRATION := V_NARRATION || P_BUSINESS_DATE || '/';

  END IF;

  IF TRIM(V_AUTH_ID) IS NOT NULL THEN

    V_NARRATION := V_NARRATION || V_AUTH_ID;

  END IF;

  --Added by Deepa on June 26 2012 for Reversal Fee Calculation

   IF nvl(V_ORGNL_TXN,'1') <> 'NO ORGNL TXN' -- AND V_ORGNL_TXN <> 'NO ORGNL TXN'condition Added for FSS-1145
   THEN
      --Sn reversal Fee Calculation
      BEGIN

        SP_TRAN_REVERSAL_FEES(P_INST_CODE,
                         P_CARD_NO,
                         P_DELV_CHNL,
                         V_ORGNL_TXN_MODE,
                         P_TXN_CODE,
                         P_CURR_CODE,
                         NULL,
                         NULL,
                         V_REVERSAL_AMT,
                         P_BUSINESS_DATE,
                         P_BUSINESS_TIME,
                         NULL,
                         NULL,
                         V_RESP_CDE,
                         P_MSG_TYP,
                         P_MBR_NUMB,
                         P_RRN,
                         P_TERMINAL_ID,
                         /*V_TXN_MERCHNAME,
                         V_TXN_MERCHCITY,*/--Commented and modified on 21.03.2013 for Merchant Logging Info for the Reversal Txn
                         P_MERCHANT_NAME,
                         P_MERCHANT_CITY,                                          
                         V_AUTH_ID,
                         --V_FEE_MERCHSTATE,--Commented and modified on 21.03.2013 for Merchant Logging Info for the Reversal Txn
                         P_MERCHANT_STATE,
                         P_RVSL_CODE,
                         V_TXN_NARRATION,
                         V_ORGNL_TXN_TYPE,
                         V_TRAN_DATE,
                         V_ERRMSG,
                         V_RESP_CDE,
                         V_FEE_AMT,
                         V_FEE_PLAN,
                         V_FEE_CODE,      --Added on 30.07.2013 for 11695
                         V_FEEATTACH_TYPE --Added on 30.07.2013 for 11695 
                         );

        IF V_ERRMSG <> 'OK' THEN
         RAISE EXP_RVSL_REJECT_RECORD;
        END IF;
      END;

      ---------------------------------------
      --SN:Added on 24-Jan-2013 Defect 10123
      ---------------------------------------
  
      BEGIN
        INSERT INTO CMS_PREAUTH_TRANS_HIST
         (CPH_CARD_NO,
          CPH_MBR_NO,
          CPH_INST_CODE,
          CPH_CARD_NO_ENCR,
          CPH_PREAUTH_VALIDFLAG,
          CPH_COMPLETION_FLAG,
          CPH_TXN_AMNT,
          CPH_RRN,
          CPH_TXN_DATE,
          CPH_TXN_TIME,
          CPH_ORGNL_RRN,
          CPH_ORGNL_TXN_DATE,
          CPH_ORGNL_TXN_TIME,
          CPH_ORGNL_CARD_NO,
          CPH_TERMINALID,
          CPH_ORGNL_TERMINALID,
          CPH_TRANSACTION_FLAG,
          CPH_MERCHANT_NAME, 
          CPH_MERCHANT_CITY,
          CPH_MERCHANT_STATE,
          CPH_DELIVERY_CHANNEL,
          CPH_TRAN_CODE,
          CPH_PANNO_LAST4DIGIT,
          CPH_INS_DATE,
          CPH_LUPD_DATE,
          CPH_ACCT_NO) 
        VALUES
         (V_HASH_PAN,
          P_MBR_NUMB,
          P_INST_CODE,
          V_ENCR_PAN,
          'N',
          'C',
          P_ACTUAL_AMT,
          P_RRN,
          P_BUSINESS_DATE,
          P_BUSINESS_TIME,
          P_ORGNL_RRN,
          P_ORGNL_BUSINESS_DATE,
          P_ORGNL_BUSINESS_TIME,
          V_HASH_PAN,
          P_TERMINAL_ID,
          P_ORGNL_TERMINAL_ID,
          'R',
          /*V_FEE_MERCHNAME,
          V_FEE_MERCHCITY,
          V_FEE_MERCHSTATE,*/--Commented and modified on 21.03.2013 for Merchant Logging Info for the Reversal Txn
          P_MERCHANT_NAME,
          P_MERCHANT_CITY,
          P_MERCHANT_STATE,  
          P_DELV_CHNL,
          P_TXN_CODE,
          (SUBSTR(P_CARD_NO, LENGTH(P_CARD_NO) - 3, LENGTH(P_CARD_NO))),
          SYSDATE,
          SYSDATE,
          V_CARD_ACCT_NO
          ); 
      EXCEPTION
        WHEN OTHERS THEN
         V_ERRMSG   := 'Error while inserting  CMS_PREAUTH_TRANS_HIST' ||
                    SUBSTR(SQLERRM, 1, 300);
         V_RESP_CDE := '21';
         RAISE EXP_RVSL_REJECT_RECORD;
      END;
  
      ---------------------------------------
      --EN:Added on 24-Jan-2013  Defect 10123
      ---------------------------------------
      
    --Sn added by Pankaj S. for 10871
     BEGIN
        UPDATE cms_statements_log
           SET csl_prod_code = v_prod_code,
               csl_card_type=v_card_type,
               csl_acct_type = v_acct_type,
               csl_time_stamp = v_timestamp
         WHERE csl_inst_code = p_inst_code
           AND csl_pan_no = v_hash_pan
           AND csl_rrn = p_rrn
           AND csl_txn_code = p_txn_code
           AND csl_delivery_channel = p_delv_chnl
           AND csl_business_date = p_business_date
           AND csl_business_time = p_business_time;
       IF SQL%ROWCOUNT =0
       THEN
         NULL;
       END IF;   
       EXCEPTION
       WHEN OTHERS
       THEN
          v_resp_cde := '21';
          v_errmsg :=
               'Error while updating timestamp in statementlog-' || SUBSTR (SQLERRM, 1, 200);
          RAISE exp_rvsl_reject_record;
    END;
    --Sn added by Pankaj S. for 10871   

      --Sn Updation of Hold amount by matching the Original RRN  and Business Date OR RRN and Card number

      BEGIN

        SELECT CPT_TOTALHOLD_AMT
         INTO V_HOLD_AMOUNT
         FROM CMS_PREAUTH_TRANSACTION
        WHERE CPT_RRN = P_ORGNL_RRN AND CPT_TXN_DATE = P_ORGNL_BUSINESS_DATE AND
             CPT_INST_CODE = P_INST_CODE;

        V_UPD_HOLD_AMOUNT := V_HOLD_AMOUNT - V_REVERSAL_AMT;

        IF V_UPD_HOLD_AMOUNT <= 0 THEN

         V_UPD_HOLD_AMOUNT := 0;

         UPDATE CMS_PREAUTH_TRANSACTION
            SET CPT_TOTALHOLD_AMT     = TRIM(TO_CHAR(V_UPD_HOLD_AMOUNT, '999999999999999990.99')), --Mosdified for 10871
               CPT_PREAUTH_VALIDFLAG = 'N',
               CPT_TRANSACTION_FLAG  = 'R',
               cpt_completion_fee=v_comp_total_fee
          WHERE CPT_RRN = P_ORGNL_RRN AND CPT_TXN_DATE = P_ORGNL_BUSINESS_DATE AND
               CPT_INST_CODE = P_INST_CODE;

        ELSE

         UPDATE CMS_PREAUTH_TRANSACTION
            SET CPT_TOTALHOLD_AMT    = TRIM(TO_CHAR(V_UPD_HOLD_AMOUNT, '999999999999999990.99')), --Mosdified for 10871
               CPT_TRANSACTION_FLAG = 'R',
               cpt_completion_fee=v_comp_total_fee
          WHERE CPT_RRN = P_ORGNL_RRN AND CPT_TXN_DATE = P_ORGNL_BUSINESS_DATE AND
               CPT_INST_CODE = P_INST_CODE;

        END IF;

        IF SQL%ROWCOUNT = 0 THEN
         V_ERRMSG   := 'Error while updating the CMS_PREAUTH_TRANSACTION table';
         V_RESP_CDE := '21';
         RAISE EXP_RVSL_REJECT_RECORD;
        END IF;

      EXCEPTION
        WHEN NO_DATA_FOUND THEN

         BEGIN

           SELECT CPT_TOTALHOLD_AMT
            INTO V_HOLD_AMOUNT
            FROM CMS_PREAUTH_TRANSACTION
            WHERE CPT_RRN = P_ORGNL_RRN AND CPT_INST_CODE = P_INST_CODE AND
                CPT_CARD_NO = V_HASH_PAN;

           V_UPD_HOLD_AMOUNT := V_HOLD_AMOUNT - V_REVERSAL_AMT;

           IF V_UPD_HOLD_AMOUNT <= 0 THEN

            V_UPD_HOLD_AMOUNT := 0;

            UPDATE CMS_PREAUTH_TRANSACTION
               SET CPT_TOTALHOLD_AMT     = TRIM(TO_CHAR(V_UPD_HOLD_AMOUNT, '999999999999999990.99')), --Mosdified for 10871
                  CPT_PREAUTH_VALIDFLAG = 'N',
                  CPT_TRANSACTION_FLAG  = 'R',
                  cpt_completion_fee=v_comp_total_fee
             WHERE CPT_RRN = P_ORGNL_RRN AND CPT_INST_CODE = P_INST_CODE AND
                  CPT_CARD_NO = V_HASH_PAN;

           ELSE

            UPDATE CMS_PREAUTH_TRANSACTION
               SET CPT_TOTALHOLD_AMT    = TRIM(TO_CHAR(V_UPD_HOLD_AMOUNT, '999999999999999990.99')), --Mosdified for 10871
                  CPT_TRANSACTION_FLAG = 'R',
                  cpt_completion_fee=v_comp_total_fee
             WHERE CPT_RRN = P_ORGNL_RRN AND CPT_INST_CODE = P_INST_CODE AND
                  CPT_CARD_NO = V_HASH_PAN;

           END IF;

           IF SQL%ROWCOUNT = 0 THEN
            V_ERRMSG   := 'Error while updating the CMS_PREAUTH_TRANSACTION table';
            V_RESP_CDE := '21';
            RAISE EXP_RVSL_REJECT_RECORD;
           END IF;

         EXCEPTION
           WHEN NO_DATA_FOUND THEN
            V_UPD_HOLD_AMOUNT := 0;
           WHEN OTHERS THEN
            V_UPD_HOLD_AMOUNT := 0;
         END;
        WHEN OTHERS THEN
         V_UPD_HOLD_AMOUNT := 0;
      END;

      --En Updation of Hold amount if the Original RRN  and Card No or Card No and Txn Amount are matching
   END IF;   
      
    BEGIN                               --Added for FSS-1145/0010784
    
     SELECT CAM_ACCT_BAL, CAM_LEDGER_BAL
       INTO V_ACCT_BALANCE, V_LEDGER_BAL
       FROM CMS_ACCT_MAST
      WHERE CAM_ACCT_ID  = V_ACCT_ID
      AND   CAM_INST_CODE = P_INST_CODE;
      
    EXCEPTION
     WHEN OTHERS THEN
       V_ACCT_BALANCE := 0;
       V_LEDGER_BAL   := 0;
    END;                               --Added for FSS-1145 /0010784
   

  P_RESP_ID := V_RESP_CDE; --Added for VMS-8018
  BEGIN
    SELECT CMS_ISO_RESPCDE
     INTO P_RESP_CDE
     FROM CMS_RESPONSE_MAST
    WHERE CMS_INST_CODE = P_INST_CODE AND
         CMS_DELIVERY_CHANNEL = P_DELV_CHNL AND
         CMS_RESPONSE_ID = TO_NUMBER(V_RESP_CDE);
  EXCEPTION
    WHEN OTHERS THEN
     V_ERRMSG   := 'Problem while selecting data from response master for respose code' ||
                V_RESP_CDE || SUBSTR(SQLERRM, 1, 300);
     V_RESP_CDE := '69';
     RAISE EXP_RVSL_REJECT_RECORD;
  END;

  --En generate response code

  -- Sn create a entry in GL
  BEGIN
    INSERT INTO TRANSACTIONLOG
     (MSGTYPE,
      RRN,
      DELIVERY_CHANNEL,
      TERMINAL_ID,
      DATE_TIME,
      TXN_CODE,
      TXN_TYPE,
      TXN_MODE,
      TXN_STATUS,
      RESPONSE_CODE,
      BUSINESS_DATE,
      BUSINESS_TIME,
      CUSTOMER_CARD_NO,
      TOPUP_CARD_NO,
      TOPUP_ACCT_NO,
      TOPUP_ACCT_TYPE,
      BANK_CODE,
      TOTAL_AMOUNT,
      RULE_INDICATOR,
      RULEGROUPID,
      MCCODE,
      CURRENCYCODE,
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
      TRAN_REVERSE_FLAG,
      CUSTOMER_CARD_NO_ENCR,
      TOPUP_CARD_NO_ENCR,
      ORGNL_CARD_NO,
      ORGNL_RRN,
      ORGNL_BUSINESS_DATE,
      ORGNL_BUSINESS_TIME,
      ORGNL_TERMINAL_ID,
      PROXY_NUMBER,
      REVERSAL_CODE,
      CUSTOMER_ACCT_NO,
      ACCT_BALANCE,
      LEDGER_BALANCE,
      RESPONSE_ID,
      /* Start Added by Dhiraj G on 31052012 for Pre - Auth Parameter changes  */
      NETWORK_ID,
      INTERCHANGE_FEEAMT,
      MERCHANT_ZIP,
      /* End Added by Dhiraj G on 31052012 for Pre - Auth Parameter changes  */
      FEE_PLAN, --Added by Deepa on June 26 2012 for fee plan
        MERCHANT_NAME,-- Added FOR MERCHANT DETAILS LOGGED IN TRANSACTIONLOG TABLE on 07-Sep-2012
      MERCHANT_CITY,-- Added FOR MERCHANT DETAILS LOGGED IN TRANSACTIONLOG TABLE on 07-Sep-2012
      MERCHANT_STATE,  -- Added FOR MERCHANT DETAILS LOGGED IN TRANSACTIONLOG TABLE on 07-Sep-2012
      NETWORK_SETTL_DATE,  -- Added on 201112 for logging N/W settlement date in transactionlog
      MERCHANT_ID ,         --Added on 19-Mar-2013 for FSS-970
      MATCH_RULE, --added for FSS-1145 
      --Sn added by Pankaj S. for 10871
      cardstatus,
      cr_dr_flag,
      error_msg,
      acct_type,
      time_stamp,
      --En added by Pankaj S. for 10871
       NETWORKID_SWITCH   --Added on 20130626 for the Mantis ID 11344   
       ,INTERNATION_IND_RESPONSE 
      )
    VALUES
     (P_MSG_TYP,
      P_RRN,
      P_DELV_CHNL,
      P_TERMINAL_ID,
      V_RVSL_TRANDATE,
      P_TXN_CODE,
      V_TXN_TYPE,
      P_TXN_MODE,
      DECODE(P_RESP_CDE, '00', 'C', 'F'),
      P_RESP_CDE,
      P_BUSINESS_DATE,
      SUBSTR(P_BUSINESS_TIME, 1, 6),
      V_HASH_PAN,
      NULL,
      NULL, --P_topup_acctno    ,
      NULL, --P_topup_accttype,
      P_INST_CODE,
      TRIM(TO_CHAR(V_REVERSAL_AMT, '999999999999999990.99')), --formated for 10871
      -- reversal amount will be passed in the table as the same is used in the recon report.
      NULL,
      NULL,
      P_MERC_ID,
      V_CURR_CODE,
      V_PROD_CODE,
      V_CARD_TYPE,
      V_FEE_AMT, --Added by Deepa on June 26 2012 for logging fee
      '0.00', --modified by Pankaj S. for 10871
      NULL,
      NULL,
      V_AUTH_ID,
      V_TRAN_DESC,
      TRIM(TO_CHAR(V_REVERSAL_AMT, '999999999999999990.99')), --formated for 10871
      -- reversal amount will be passed in the table as the same is used in the recon report.
      '0.00', --modified by Pankaj S. for 10871 --- PRE AUTH AMOUNT
      '0.00', --modified by Pankaj S. for 10871 -- Partial amount (will be given for partial txn)
      NULL,
      NULL,
      NULL,
      NULL,
      NULL,
      'Y',
      P_STAN,
      P_INST_CODE,
       --NULL,
      V_FEE_CODE, --Added on 30.07.2013 for 11695
      --NULL,
      V_FEEATTACH_TYPE, --Added on 30.07.2013 for 11695
      'N',
      V_ENCR_PAN,
      NULL,
      V_ENCR_PAN,
      P_ORGNL_RRN,
      P_ORGNL_BUSINESS_DATE,
      P_ORGNL_BUSINESS_TIME,
      P_ORGNL_TERMINAL_ID,
      V_PROXUNUMBER,
      P_RVSL_CODE,
      V_ACCT_NUMBER,
      V_ACCT_BALANCE,
      V_LEDGER_BAL,
      V_RESP_CDE,
      /* Start Added by Dhiraj G on 31052012 for Pre - Auth Parameter changes  */
      P_NETWORK_ID,
      P_INTERCHANGE_FEEAMT,
      P_MERCHANT_ZIP,
      /* End Added by Dhiraj G on 31052012 for Pre - Auth Parameter changes  */
      V_FEE_PLAN, --Added by Deepa on June 26 2012 for fee plan
      /*V_TXN_MERCHNAME, -- Added FOR MERCHANT DETAILS LOGGED IN TRANSACTIONLOG TABLE on 07-Sep-2012
      V_TXN_MERCHCITY,-- Added FOR MERCHANT DETAILS LOGGED IN TRANSACTIONLOG TABLE on 07-Sep-2012
      V_TXN_MERCHSTATE, -- Added FOR MERCHANT DETAILS LOGGED IN TRANSACTIONLOG TABLE on 07-Sep-2012*/
      --Commented and modified on 21.03.2013 for Merchant Logging Info for the Reversal Txn
      P_MERCHANT_NAME,
      P_MERCHANT_CITY,
      P_MERCHANT_STATE,
      P_NETWORK_SETL_DATE,  -- Added on 201112 for logging N/W settlement date in transactionlog
      P_MERCHANT_ID ,        --Added on 19-Mar-2013 for FSS-970
      decode(V_ORGNL_TXN,'NO ORGNL TXN','U'), --added for FSS-1145
      --Sn added by Pankaj S. for 10871
      v_cap_card_stat,
      v_dr_cr_flag,
      v_errmsg,
      v_acct_type,
      v_timestamp,
      --En added by Pankaj S. for 10871    
      P_NETWORKID_SWITCH  --Added on 20130626 for the Mantis ID 11344
      ,v_internation_ind_response           
      );

   IF nvl(V_ORGNL_TXN,'1') <> 'NO ORGNL TXN' -- AND V_ORGNL_TXN <> 'NO ORGNL TXN'condition Added for FSS-1145
   THEN
        BEGIN
         UPDATE TRANSACTIONLOG
            SET TRAN_REVERSE_FLAG = 'Y'
          WHERE RRN = P_ORGNL_RRN AND BUSINESS_DATE = P_ORGNL_BUSINESS_DATE AND
               BUSINESS_TIME = P_ORGNL_BUSINESS_TIME AND
               CUSTOMER_CARD_NO = V_HASH_PAN 
               AND INSTCODE = P_INST_CODE; 
               --AND TERMINAL_ID = P_ORGNL_TERMINAL_ID;                 -- Commented on 15-Feb-2013 for defect 10296

         IF SQL%ROWCOUNT = 0 THEN

           IF P_MSG_TYP NOT IN ('9220', '9221') THEN
            V_RESP_CDE := '21';
            V_ERRMSG   := 'Reverse flag is not updated ';
            RAISE EXP_RVSL_REJECT_RECORD;
           END IF;
         END IF;

        EXCEPTION
         WHEN EXP_RVSL_REJECT_RECORD THEN
           RAISE;
         WHEN OTHERS THEN
           V_RESP_CDE := '21';
           V_ERRMSG   := 'Error while updating gl flag ' ||
                      SUBSTR(SQLERRM, 1, 200);
           RAISE EXP_RVSL_REJECT_RECORD;

        END;
        --En update reverse flag
   END IF; 
        
       /*           --Sn:Commented as per review observation for FSS-1246   
        BEGIN

         SELECT CTC_ATMUSAGE_AMT,
               CTC_POSUSAGE_AMT,
               CTC_BUSINESS_DATE,
               CTC_MMPOSUSAGE_AMT
           INTO V_ATM_USAGEAMNT,
               V_POS_USAGEAMNT,
               V_BUSINESS_DATE_TRAN,
               V_MMPOS_USAGEAMNT
           FROM CMS_TRANSLIMIT_CHECK
          WHERE CTC_INST_CODE = P_INST_CODE AND CTC_PAN_CODE = V_HASH_PAN AND
               CTC_MBR_NUMB = P_MBR_NUMB;
        EXCEPTION
         WHEN NO_DATA_FOUND THEN
           V_ERRMSG   := 'Cannot get the Transaction Limit Details of the Card' ||
                      V_RESP_CDE || SUBSTR(SQLERRM, 1, 300);
           V_RESP_CDE := '21';
           RAISE EXP_RVSL_REJECT_RECORD;
         WHEN OTHERS THEN
           V_ERRMSG   := 'Error while selecting CMS_TRANSLIMIT_CHECK ' ||
                      V_RESP_CDE || SUBSTR(SQLERRM, 1, 300);
           V_RESP_CDE := '21';
           RAISE EXP_RVSL_REJECT_RECORD;
        END;

        BEGIN

         --Sn Limit and amount check for POS

         IF P_DELV_CHNL = '02' THEN

           IF V_RVSL_TRANDATE > V_BUSINESS_DATE_TRAN THEN

            UPDATE CMS_TRANSLIMIT_CHECK
               SET CTC_POSUSAGE_AMT       = 0,
                  CTC_POSUSAGE_LIMIT     = 0,
                  CTC_ATMUSAGE_AMT       = 0,
                  CTC_ATMUSAGE_LIMIT     = 0,
                  CTC_BUSINESS_DATE      = TO_DATE(P_BUSINESS_DATE ||
                                            '23:59:59',
                                            'yymmdd' || 'hh24:mi:ss'),
                  CTC_PREAUTHUSAGE_LIMIT = 0,
                  CTC_MMPOSUSAGE_AMT     = 0,
                  CTC_MMPOSUSAGE_LIMIT   = 0
             WHERE CTC_INST_CODE = P_INST_CODE AND CTC_PAN_CODE = V_HASH_PAN AND
                  CTC_MBR_NUMB = P_MBR_NUMB;
           ELSE
            IF P_ORGNL_BUSINESS_DATE = P_BUSINESS_DATE THEN

              IF V_REVERSAL_AMT IS NULL THEN
                V_POS_USAGEAMNT := V_POS_USAGEAMNT;

              ELSE
                V_POS_USAGEAMNT := V_POS_USAGEAMNT -
                               TRIM(TO_CHAR(V_REVERSAL_AMT,
                                         '999999999999.99'));
              END IF;

              UPDATE CMS_TRANSLIMIT_CHECK
                SET CTC_POSUSAGE_AMT = V_POS_USAGEAMNT
               WHERE CTC_INST_CODE = P_INST_CODE AND
                    CTC_PAN_CODE = V_HASH_PAN AND CTC_MBR_NUMB = P_MBR_NUMB;
            END IF;
           END IF;
         END IF;

         IF SQL%ROWCOUNT = 0 THEN
           V_ERRMSG   := 'Error while updating the CMS_TRANSLIMIT_CHECK';
           V_RESP_CDE := '21';
           RAISE EXP_RVSL_REJECT_RECORD;
         END IF;

         --En Limit and amount check for POS
        EXCEPTION
         WHEN OTHERS THEN
           V_ERRMSG   := 'Error while updating CMS_TRANSLIMIT_CHECK ' ||
                      V_RESP_CDE || SUBSTR(SQLERRM, 1, 300);
           V_RESP_CDE := '21';
           RAISE EXP_RVSL_REJECT_RECORD;
        END;
      */ --En:Commented as per review observation for FSS-1246  

    IF V_ERRMSG = 'OK' THEN

     --Sn find prod code and card type and available balance for the card number
     BEGIN
       SELECT CAM_ACCT_BAL, CAM_LEDGER_BAL
        INTO V_ACCT_BALANCE, V_LEDGER_BAL
        FROM CMS_ACCT_MAST
        WHERE CAM_ACCT_NO =
            (SELECT CAP_ACCT_NO
               FROM CMS_APPL_PAN
              WHERE CAP_PAN_CODE = V_HASH_PAN AND
                   CAP_MBR_NUMB = P_MBR_NUMB AND
                   CAP_INST_CODE = P_INST_CODE) AND
            CAM_INST_CODE = P_INST_CODE;
          --FOR UPDATE NOWAIT;                                                   -- Commented for concurrent processing issue
     EXCEPTION
       WHEN NO_DATA_FOUND THEN
        V_RESP_CDE := '14'; --Ineligible Transaction
        V_ERRMSG   := 'Invalid Card ';
        RAISE EXP_RVSL_REJECT_RECORD;
       WHEN OTHERS THEN
        V_RESP_CDE := '21';
        V_ERRMSG   := 'Error while selecting data from card Master for card number ' ||
                    SQLERRM;
        RAISE EXP_RVSL_REJECT_RECORD;
     END;

     --En find prod code and card type for the card number
     P_RESP_MSG := TO_CHAR(V_ACCT_BALANCE);

    ELSE

     P_RESP_MSG := V_ERRMSG;

    END IF;

  EXCEPTION
    WHEN EXP_RVSL_REJECT_RECORD THEN
     RAISE;

    WHEN OTHERS THEN
     V_RESP_CDE := '21';
     V_ERRMSG   := 'Error while inserting records in transaction log ' ||
                SUBSTR(SQLERRM, 1, 200);
     RAISE EXP_RVSL_REJECT_RECORD;
  END;
  --En  create a entry in GL
  
    IF v_orgnl_txn_totalfee_amt=0 AND v_orgnl_txn_feecode IS NOT NULL THEN
    BEGIN
       vmsfee.fee_freecnt_reverse (v_acct_number, v_orgnl_txn_feecode, v_errmsg);
    
       IF v_errmsg <> 'OK' THEN
          v_resp_cde := '21';
          RAISE exp_rvsl_reject_record;
       END IF;
    EXCEPTION
       WHEN exp_rvsl_reject_record THEN
          RAISE;
       WHEN OTHERS THEN
          v_resp_cde := '21';
          v_errmsg :='Error while reversing freefee count-'|| SUBSTR (SQLERRM, 1, 200);
          RAISE exp_rvsl_reject_record;
    END;
  END IF;
  
  --Sn Added by Pankaj S. for enabling limit validation
   IF v_add_ins_date IS NOT NULL AND v_prfl_code IS NOT NULL AND v_prfl_flag = 'Y'
     AND V_ORGN_FOUND = 1 
     THEN  
          BEGIN
          
                pkg_limits_check.sp_limitcnt_rever_reset (p_inst_code,
                                                          NULL,
                                                          NULL,
                                                          v_orgnl_mcccode,
                                                          p_txn_code,
                                                          v_tran_type,
                                                          v_internation_ind_response,
                                                          v_pos_verification,
                                                          v_prfl_code,
                                                          v_reversal_amt,
                                                          v_hold_amount,
                                                          p_delv_chnl,
                                                          v_hash_pan,
                                                          v_add_ins_date,
                                                          v_resp_cde,
                                                          v_errmsg
                                                          );
                                                          
                   IF v_errmsg <> 'OK' THEN
                      RAISE exp_rvsl_reject_record;
                   END IF;                                         
           
            
          EXCEPTION
             WHEN exp_rvsl_reject_record THEN
                RAISE;
             WHEN OTHERS THEN
                v_resp_cde := '21';
                v_errmsg :='Error from Limit count rever Process ' || SUBSTR (SQLERRM, 1, 200);
                RAISE exp_rvsl_reject_record;
          END;
  
   END IF;
  --En Added by Pankaj S. for enabling limit validation
   --SN Added  for  Mantis ID 13785 for To return the reversal amount on 21/03/201
  IF nvl(V_ORGNL_TXN,'1') <> 'NO ORGNL TXN' 
    THEN
   P_REVERSAL_AMOUNT := V_REVERSAL_AMT ;    
         ELSE
        P_REVERSAL_AMOUNT:=0;     
 END IF;
  --EN Added  for  Mantis ID 13785 for To return the reversal amount on 21/03/201
EXCEPTION
  -- << MAIN EXCEPTION>>
  WHEN EXP_RVSL_REJECT_RECORD THEN
    ROLLBACK TO V_SAVEPOINT;
    BEGIN
     SELECT CAM_ACCT_BAL, CAM_LEDGER_BAL,
            cam_type_code --added by Pankaj S. for 10871
       INTO V_ACCT_BALANCE, V_LEDGER_BAL,
            v_acct_type --added by Pankaj S. for 10871
       FROM CMS_ACCT_MAST
      WHERE CAM_ACCT_NO =
           (SELECT CAP_ACCT_NO
             FROM CMS_APPL_PAN
            WHERE CAP_PAN_CODE = V_HASH_PAN AND
                 CAP_INST_CODE = P_INST_CODE) AND
           CAM_INST_CODE = P_INST_CODE;
    EXCEPTION
     WHEN OTHERS THEN
       V_ACCT_BALANCE := 0;
       V_LEDGER_BAL   := 0;
    END;
    BEGIN
     SELECT CMS_ISO_RESPCDE
       INTO P_RESP_CDE
       FROM CMS_RESPONSE_MAST
      WHERE CMS_INST_CODE = P_INST_CODE AND
           CMS_DELIVERY_CHANNEL = P_DELV_CHNL AND
           CMS_RESPONSE_ID = TO_NUMBER(V_RESP_CDE);
     P_RESP_MSG := V_ERRMSG;
     P_RESP_ID  := V_RESP_CDE; --Added for VMS-8018
    EXCEPTION
     WHEN OTHERS THEN
       P_RESP_MSG := 'Problem while selecting data from response master ' ||
                  V_RESP_CDE || SUBSTR(SQLERRM, 1, 300);
       P_RESP_CDE := '69';
       P_RESP_ID  := '69'; --Added for VMS-8018
    END;
    
    
   /*       --Sn:Commented as per review observation for FSS-1246  
    BEGIN

     SELECT CTC_ATMUSAGE_AMT,
           CTC_POSUSAGE_AMT,
           CTC_BUSINESS_DATE,
           CTC_MMPOSUSAGE_AMT
       INTO V_ATM_USAGEAMNT,
           V_POS_USAGEAMNT,
           V_BUSINESS_DATE_TRAN,
           V_MMPOS_USAGEAMNT
       FROM CMS_TRANSLIMIT_CHECK
      WHERE CTC_INST_CODE = P_INST_CODE AND CTC_PAN_CODE = V_HASH_PAN AND
           CTC_MBR_NUMB = P_MBR_NUMB;
    EXCEPTION
     WHEN NO_DATA_FOUND THEN
       V_ERRMSG   := 'Cannot get the Transaction Limit Details of the Card' ||
                  V_RESP_CDE || SUBSTR(SQLERRM, 1, 300);
       V_RESP_CDE := '21';
       RAISE EXP_RVSL_REJECT_RECORD;
     WHEN OTHERS THEN
       V_ERRMSG   := 'Error while selecting CMS_TRANSLIMIT_CHECK 5' ||
                  V_RESP_CDE || SUBSTR(SQLERRM, 1, 300);
       V_RESP_CDE := '21';
       RAISE EXP_RVSL_REJECT_RECORD;
    END;

    BEGIN
     --Sn limit update for POS

     IF P_DELV_CHNL = '02' THEN

       IF V_RVSL_TRANDATE > V_BUSINESS_DATE_TRAN THEN

        UPDATE CMS_TRANSLIMIT_CHECK
           SET CTC_POSUSAGE_AMT       = 0,
              CTC_POSUSAGE_LIMIT     = 0,
              CTC_ATMUSAGE_AMT       = 0,
              CTC_ATMUSAGE_LIMIT     = 0,
              CTC_BUSINESS_DATE      = TO_DATE(P_BUSINESS_DATE ||
                                        '23:59:59',
                                        'yymmdd' || 'hh24:mi:ss'),
              CTC_PREAUTHUSAGE_LIMIT = 0,
              CTC_MMPOSUSAGE_AMT     = 0,
              CTC_MMPOSUSAGE_LIMIT   = 0
         WHERE CTC_INST_CODE = P_INST_CODE AND CTC_PAN_CODE = V_HASH_PAN AND
              CTC_MBR_NUMB = P_MBR_NUMB;
       END IF;
     END IF;

     IF SQL%ROWCOUNT = 0 THEN
       V_ERRMSG   := 'Error while updating the CMS_TRANSLIMIT_CHECK';
       V_RESP_CDE := '21';
       RAISE EXP_RVSL_REJECT_RECORD;
     END IF;

    EXCEPTION
     WHEN OTHERS THEN
       V_ERRMSG   := 'Error while updating CMS_TRANSLIMIT_CHECK 5' ||
                  V_RESP_CDE || SUBSTR(SQLERRM, 1, 300);
       V_RESP_CDE := '21';
       RAISE EXP_RVSL_REJECT_RECORD;
    END;
   */       --En:Commented as per review observation for FSS-1246   
    
    --Sn create a entry in txn log
    IF V_RESP_CDE NOT IN ('45', '32') THEN--Added by Deepa on Apr-23-2012 not to log the Invalid transaction Date and Time
    
          --Sn added by Pankaj S. for 10871 
      IF v_dr_cr_flag IS NULL THEN
      BEGIN  
        SELECT ctm_credit_debit_flag, ctm_tran_desc,
               TO_NUMBER (DECODE (ctm_tran_type, 'N', '0', 'F', '1'))
          INTO v_dr_cr_flag, v_tran_desc,
               v_txn_type
          FROM cms_transaction_mast
         WHERE ctm_tran_code = p_txn_code
           AND ctm_delivery_channel = p_delv_chnl
           AND ctm_inst_code = p_inst_code;      
      EXCEPTION
         WHEN OTHERS THEN
            NULL;
      END;
      END IF;
      
      IF v_prod_code is NULL THEN
      BEGIN  
        SELECT cap_prod_code, cap_card_type, cap_card_stat,cap_acct_no
          INTO v_prod_code, v_card_type, v_cap_card_stat,v_acct_number
          FROM cms_appl_pan
         WHERE cap_inst_code = p_inst_code
           AND cap_pan_code = gethash (p_card_no);
      EXCEPTION
         WHEN OTHERS THEN
            NULL;
      END;
      END IF;
      --En added by Pankaj S. for 10871 


     BEGIN

       INSERT INTO TRANSACTIONLOG
        (MSGTYPE,
         RRN,
         DELIVERY_CHANNEL,
         TERMINAL_ID,
         DATE_TIME,
         TXN_CODE,
         TXN_TYPE,
         TXN_MODE,
         TXN_STATUS,
         RESPONSE_CODE,
         BUSINESS_DATE,
         BUSINESS_TIME,
         CUSTOMER_CARD_NO,
         TOPUP_CARD_NO,
         TOPUP_ACCT_NO,
         TOPUP_ACCT_TYPE,
         BANK_CODE,
         TOTAL_AMOUNT,
         CURRENCYCODE,
         ADDCHARGE,
         CATEGORYID,
         ATM_NAME_LOCATION,
         AUTH_ID,
         AMOUNT,
         PREAUTHAMOUNT,
         PARTIALAMOUNT,
         INSTCODE,
         CUSTOMER_CARD_NO_ENCR,
         TOPUP_CARD_NO_ENCR,
         ORGNL_CARD_NO,
         ORGNL_RRN,
         ORGNL_BUSINESS_DATE,
         ORGNL_BUSINESS_TIME,
         ORGNL_TERMINAL_ID,
         PROXY_NUMBER,
         REVERSAL_CODE,
         CUSTOMER_ACCT_NO,
         ACCT_BALANCE,
         LEDGER_BALANCE,
         RESPONSE_ID,
         /* Start Added by Dhiraj G on 31052012 for Pre - Auth Parameter changes  */
         NETWORK_ID,
         INTERCHANGE_FEEAMT,
         MERCHANT_ZIP,
         /* End Added by Dhiraj G on 31052012 for Pre - Auth Parameter changes  */
         TRANS_DESC,
        MERCHANT_NAME,-- Added FOR MERCHANT DETAILS LOGGED IN TRANSACTIONLOG TABLE on 07-Sep-2012
        MERCHANT_CITY,-- Added FOR MERCHANT DETAILS LOGGED IN TRANSACTIONLOG TABLE on 07-Sep-2012
        MERCHANT_STATE,  -- Added FOR MERCHANT DETAILS LOGGED IN TRANSACTIONLOG TABLE on 07-Sep-2012
        NETWORK_SETTL_DATE,  -- Added on 201112 for logging N/W settlement date in transactionlog
        MERCHANT_ID ,         --Added on 19-Mar-2013 for FSS-970
        MATCH_RULE, --Added for FSS-1145
        --Sn added by Pankaj S. for 10871
        productid,
        cardstatus,
        cr_dr_flag,
        acct_type,
        error_msg,
        time_stamp,
        --En added by Pankaj S. for 10871  
        NETWORKID_SWITCH,   --Added on 20130626 for the Mantis ID 11344
        --SN Added on 30.07.2013 for 11695
        FEE_PLAN,
        FEECODE,
        TRANFEE_AMT,
        FEEATTACHTYPE
        --EN Added on 30.07.2013 for 11695
        ,INTERNATION_IND_RESPONSE  
         )
       VALUES
        (P_MSG_TYP,
         P_RRN,
         P_DELV_CHNL,
         P_TERMINAL_ID,
         V_RVSL_TRANDATE,
         P_TXN_CODE,
         V_TXN_TYPE,
         P_TXN_MODE,
         DECODE(P_RESP_CDE, '00', 'C', 'F'),
         P_RESP_CDE,
         P_BUSINESS_DATE,
         SUBSTR(P_BUSINESS_TIME, 1, 10),
         V_HASH_PAN,
         NULL,
         NULL,
         NULL,
         P_INST_CODE,
         TRIM(TO_CHAR(nvl(V_TRAN_AMT,0), '999999999999999990.99')),--Modified by Pankaj S. for 10871
         V_CURRCODE,
         NULL,
         v_card_type, --added by Pankaj S. for 10871
         P_TERMINAL_ID,
         V_AUTH_ID,
         TRIM(TO_CHAR(nvl(V_TRAN_AMT,0), '999999999999999990.99')),--Modified by Pankaj S. for 10871
         '0.00', --Modified by Pankaj S. for 10871
         '0.00', --Modified by Pankaj S. for 10871
         P_INST_CODE,
         V_ENCR_PAN,
         V_ENCR_PAN,
         V_ENCR_PAN,
         P_ORGNL_RRN,
         P_ORGNL_BUSINESS_DATE,
         P_ORGNL_BUSINESS_TIME,
         P_ORGNL_TERMINAL_ID,
         V_PROXUNUMBER,
         P_RVSL_CODE,
         V_ACCT_NUMBER,
         V_ACCT_BALANCE,
         V_LEDGER_BAL,
         V_RESP_CDE,
         /* Start Added by Dhiraj G on 31052012 for Pre - Auth Parameter changes  */
         P_NETWORK_ID,
         P_INTERCHANGE_FEEAMT,
         P_MERCHANT_ZIP,
         /* End Added by Dhiraj G on 31052012 for Pre - Auth Parameter changes  */
         V_TRAN_DESC,
        /* V_TXN_MERCHNAME, -- Added FOR MERCHANT DETAILS LOGGED IN TRANSACTIONLOG TABLE on 07-Sep-2012
        V_TXN_MERCHCITY,-- Added FOR MERCHANT DETAILS LOGGED IN TRANSACTIONLOG TABLE on 07-Sep-2012
        V_TXN_MERCHSTATE, -- Added FOR MERCHANT DETAILS LOGGED IN TRANSACTIONLOG TABLE on 07-Sep-2012*/
        --Commented and modified on 21.03.2013 for Merchant Logging Info for the Reversal Txn
        P_MERCHANT_NAME,
        P_MERCHANT_CITY,
        P_MERCHANT_STATE,
        P_NETWORK_SETL_DATE,  -- Added on 201112 for logging N/W settlement date in transactionlog
        P_MERCHANT_ID ,        --Added on 19-Mar-2013 for FSS-970
        decode(V_ORGNL_TXN,'NO ORGNL TXN','U'), --added for FSS-1145
        --Sn added by Pankaj S. for 10871
        v_prod_code,
        v_cap_card_stat,
        v_dr_cr_flag,
        v_acct_type,
        v_errmsg,
        nvl(systimestamp,v_timestamp),
        --En added by Pankaj S. for 10871
        P_NETWORKID_SWITCH,  --Added on 20130626 for the Mantis ID 11344
        --SN Added on 30.07.2013 for 11695
        V_FEE_PLAN,
        V_FEE_CODE,
        V_FEE_AMT,
        V_FEEATTACH_TYPE
        --EN Added on 30.07.2013 for 11695
        ,v_internation_ind_response   
      );

     EXCEPTION
       WHEN OTHERS THEN

        P_RESP_CDE := '89';
        P_RESP_ID  := '89'; --Added for VMS-8018
        P_RESP_MSG := 'Problem while inserting data into transaction log  dtl' ||
                    SUBSTR(SQLERRM, 1, 300);
     END;
    END IF;
    --En create a entry in txn log

    BEGIN
     INSERT INTO CMS_TRANSACTION_LOG_DTL
       (CTD_DELIVERY_CHANNEL,
        CTD_TXN_CODE,
        CTD_TXN_TYPE,
        CTD_MSG_TYPE,
        CTD_TXN_MODE,
        CTD_BUSINESS_DATE,
        CTD_BUSINESS_TIME,
        CTD_CUSTOMER_CARD_NO,
        CTD_TXN_AMOUNT,
        CTD_TXN_CURR,
        CTD_ACTUAL_AMOUNT,
        CTD_FEE_AMOUNT,
        CTD_WAIVER_AMOUNT,
        CTD_SERVICETAX_AMOUNT,
        CTD_CESS_AMOUNT,
        CTD_BILL_AMOUNT,
        CTD_BILL_CURR,
        CTD_PROCESS_FLAG,
        CTD_PROCESS_MSG,
        CTD_RRN,
        CTD_SYSTEM_TRACE_AUDIT_NO,
        CTD_INST_CODE,
        CTD_CUSTOMER_CARD_NO_ENCR,
        CTD_CUST_ACCT_NUMBER,
        /* Start Added by Dhiraj G on 31052012 for Pre - Auth Parameter changes  */
        CTD_NETWORK_ID,
        CTD_INTERCHANGE_FEEAMT,
        CTD_MERCHANT_ZIP,
        /* End Added by Dhiraj G on 31052012 for Pre - Auth Parameter changes  */
        CTD_MERCHANT_ID          --Added on 19-Mar-2013 for FSS-970
        ,CTD_INTERNATION_IND_RESPONSE,
        ctd_completion_fee,ctd_complfee_increment_type
        )
     VALUES
       (P_DELV_CHNL,
        P_TXN_CODE,
        V_TXN_TYPE,
        P_MSG_TYP,
        P_TXN_MODE,
        P_BUSINESS_DATE,
        P_BUSINESS_TIME,
        V_HASH_PAN,
        P_ACTUAL_AMT,
        V_CURRCODE,
        V_TRAN_AMT,
        NULL,
        NULL,
        NULL,
        NULL,
        P_ACTUAL_AMT,
        V_CARD_CURR,
        'E',
        V_ERRMSG,
        P_RRN,
        P_STAN,
        P_INST_CODE,
        V_ENCR_PAN,
        V_ACCT_NUMBER,
        /* Start Added by Dhiraj G on 31052012 for Pre - Auth Parameter changes  */
        P_NETWORK_ID,
        P_INTERCHANGE_FEEAMT,
        P_MERCHANT_ZIP,
        /* End  Added by Dhiraj G on 31052012 for Pre - Auth Parameter changes  */
        P_MERCHANT_ID         --Added on 19-Mar-2013 for FSS-970
        ,v_internation_ind_response,
        v_comp_fee,v_complfee_increment_type
        );
    EXCEPTION
     WHEN OTHERS THEN
       P_RESP_MSG := 'Problem while inserting data into transaction log  dtl' ||
                  SUBSTR(SQLERRM, 1, 300);
       P_RESP_CDE := '69'; -- Server Decline Response 220509
       P_RESP_ID  := '69'; --Added for VMS-8018
       ROLLBACK;
       RETURN;
    END;

    P_RESP_MSG := V_ERRMSG;
  WHEN OTHERS THEN
    ROLLBACK TO V_SAVEPOINT;
    BEGIN
     SELECT CMS_ISO_RESPCDE
       INTO P_RESP_CDE
       FROM CMS_RESPONSE_MAST
      WHERE CMS_INST_CODE = P_INST_CODE AND
           CMS_DELIVERY_CHANNEL = P_DELV_CHNL AND
           CMS_RESPONSE_ID = TO_NUMBER(V_RESP_CDE);
     P_RESP_MSG := V_ERRMSG;
     P_RESP_ID  := V_RESP_CDE; --Added for VMS-8018
    EXCEPTION
     WHEN OTHERS THEN
       P_RESP_MSG := 'Problem while selecting data from response master ' ||
                  V_RESP_CDE || SUBSTR(SQLERRM, 1, 300);
       P_RESP_CDE := '69';
       P_RESP_ID  := '69'; --Added for VMS-8018
    END;

   /*                   --Sn:Commented as per review observation for FSS-1246  
    BEGIN

     SELECT CTC_ATMUSAGE_AMT,
           CTC_POSUSAGE_AMT,
           CTC_BUSINESS_DATE,
           CTC_MMPOSUSAGE_AMT
       INTO V_ATM_USAGEAMNT,
           V_POS_USAGEAMNT,
           V_BUSINESS_DATE_TRAN,
           V_MMPOS_USAGEAMNT
       FROM CMS_TRANSLIMIT_CHECK
      WHERE CTC_INST_CODE = P_INST_CODE AND CTC_PAN_CODE = V_HASH_PAN AND
           CTC_MBR_NUMB = P_MBR_NUMB;
    EXCEPTION
     WHEN NO_DATA_FOUND THEN
       V_ERRMSG   := 'Cannot get the Transaction Limit Details of the Card' ||
                  V_RESP_CDE || SUBSTR(SQLERRM, 1, 300);
       V_RESP_CDE := '21';
       RAISE EXP_RVSL_REJECT_RECORD;
     WHEN OTHERS THEN
       V_ERRMSG   := 'Error while selecting 3 CMS_TRANSLIMIT_CHECK' ||
                  SUBSTR(SQLERRM, 1, 200);
       V_RESP_CDE := '21';
       RAISE EXP_RVSL_REJECT_RECORD;
    END;

    BEGIN
     --Sn limit update for POS

     IF P_DELV_CHNL = '02' THEN

       IF V_RVSL_TRANDATE > V_BUSINESS_DATE_TRAN THEN

        UPDATE CMS_TRANSLIMIT_CHECK
           SET CTC_POSUSAGE_AMT       = 0,
              CTC_POSUSAGE_LIMIT     = 0,
              CTC_ATMUSAGE_AMT       = 0,
              CTC_ATMUSAGE_LIMIT     = 0,
              CTC_BUSINESS_DATE      = TO_DATE(P_BUSINESS_DATE ||
                                        '23:59:59',
                                        'yymmdd' || 'hh24:mi:ss'),
              CTC_PREAUTHUSAGE_LIMIT = 0,
              CTC_MMPOSUSAGE_AMT     = 0,
              CTC_MMPOSUSAGE_LIMIT   = 0
         WHERE CTC_INST_CODE = P_INST_CODE AND CTC_PAN_CODE = V_HASH_PAN AND
              CTC_MBR_NUMB = P_MBR_NUMB;
       END IF;
     END IF;

     IF SQL%ROWCOUNT = 0 THEN
       V_ERRMSG   := 'Error while updating the CMS_TRANSLIMIT_CHECK';
       V_RESP_CDE := '21';
       RAISE EXP_RVSL_REJECT_RECORD;
     END IF;

    EXCEPTION
     WHEN OTHERS THEN
       V_ERRMSG   := 'Error while updating 3 CMS_TRANSLIMIT_CHECK' ||
                  SUBSTR(SQLERRM, 1, 200);
       V_RESP_CDE := '21';
       RAISE EXP_RVSL_REJECT_RECORD;
    END;
   */   --En:Commented as per review observation for FSS-1246   

    --Sn create a entry in txn log
    IF V_RESP_CDE NOT IN ('45', '32') THEN --Added by Deepa on Apr-23-2012 not to log the Invalid transaction Date and Time
    
      --Sn added by Pankaj S. for 10871 
      IF v_dr_cr_flag IS NULL THEN
      BEGIN  
        SELECT ctm_credit_debit_flag, ctm_tran_desc,
               TO_NUMBER (DECODE (ctm_tran_type, 'N', '0', 'F', '1'))
          INTO v_dr_cr_flag, v_tran_desc,
               v_txn_type
          FROM cms_transaction_mast
         WHERE ctm_tran_code = p_txn_code
           AND ctm_delivery_channel = p_delv_chnl
           AND ctm_inst_code = p_inst_code;      
      EXCEPTION
         WHEN OTHERS THEN
            NULL;
      END;
      END IF;
      
      IF v_prod_code is NULL THEN
      BEGIN  
        SELECT cap_prod_code, cap_card_type, cap_card_stat,cap_acct_no
          INTO v_prod_code, v_card_type, v_cap_card_stat,v_acct_number
          FROM cms_appl_pan
         WHERE cap_inst_code = p_inst_code
           AND cap_pan_code = gethash (p_card_no);
      EXCEPTION
         WHEN OTHERS THEN
            NULL;
      END;
      END IF;
      
      IF v_acct_type IS NULL THEN
      BEGIN  
        SELECT cam_type_code
          INTO v_acct_type
          FROM cms_acct_mast
         WHERE cam_inst_code = p_inst_code
           AND cam_acct_no = v_acct_number;
      EXCEPTION
         WHEN OTHERS THEN
            NULL;
      END;
      END IF;
      --En added by Pankaj S. for 10871 

    
     BEGIN
       INSERT INTO TRANSACTIONLOG
        (MSGTYPE,
         RRN,
         DELIVERY_CHANNEL,
         TERMINAL_ID,
         DATE_TIME,
         TXN_CODE,
         TXN_TYPE,
         TXN_MODE,
         TXN_STATUS,
         RESPONSE_CODE,
         BUSINESS_DATE,
         BUSINESS_TIME,
         CUSTOMER_CARD_NO,
         TOPUP_CARD_NO,
         TOPUP_ACCT_NO,
         TOPUP_ACCT_TYPE,
         BANK_CODE,
         TOTAL_AMOUNT,
         CURRENCYCODE,
         ADDCHARGE,
         CATEGORYID,
         ATM_NAME_LOCATION,
         AUTH_ID,
         AMOUNT,
         PREAUTHAMOUNT,
         PARTIALAMOUNT,
         INSTCODE,
         CUSTOMER_CARD_NO_ENCR,
         TOPUP_CARD_NO_ENCR,
         ORGNL_CARD_NO,
         ORGNL_RRN,
         ORGNL_BUSINESS_DATE,
         ORGNL_BUSINESS_TIME,
         ORGNL_TERMINAL_ID,
         PROXY_NUMBER,
         REVERSAL_CODE,
         CUSTOMER_ACCT_NO,
         ACCT_BALANCE,
         LEDGER_BALANCE,
         RESPONSE_ID,
         /* Start Added by Dhiraj G on 31052012 for Pre - Auth Parameter changes  */
         NETWORK_ID,
         INTERCHANGE_FEEAMT,
         MERCHANT_ZIP,
         /* End Added by Dhiraj G on 31052012 for Pre - Auth Parameter changes  */
         TRANS_DESC,
          MERCHANT_NAME,-- Added FOR MERCHANT DETAILS LOGGED IN TRANSACTIONLOG TABLE on 07-Sep-2012
        MERCHANT_CITY,-- Added FOR MERCHANT DETAILS LOGGED IN TRANSACTIONLOG TABLE on 07-Sep-2012
        MERCHANT_STATE,  -- Added FOR MERCHANT DETAILS LOGGED IN TRANSACTIONLOG TABLE on 07-Sep-2012
        NETWORK_SETTL_DATE,  -- Added on 201112 for logging N/W settlement date in transactionlog
        MERCHANT_ID ,         --Added on 19-Mar-2013 for FSS-970
        MATCH_RULE, --Added for FSS-1145
        --Sn added by Pankaj S. for 10871
        productid,
        cardstatus,
        cr_dr_flag,
        acct_type,
        error_msg,
        time_stamp,
        --En added by Pankaj S. for 10871
        NETWORKID_SWITCH ,  --Added on 20130626 for the Mantis ID 11344
        --SN Added on 30.07.2013 for 11695
        FEE_PLAN,
        FEECODE,
        TRANFEE_AMT,
        FEEATTACHTYPE
         --EN Added on 30.07.2013 for 11695
         ,INTERNATION_IND_RESPONSE   
         )
       VALUES
        (P_MSG_TYP,
         P_RRN,
         P_DELV_CHNL,
         P_TERMINAL_ID,
         V_RVSL_TRANDATE,
         P_TXN_CODE,
         V_TXN_TYPE,
         P_TXN_MODE,
         DECODE(P_RESP_CDE, '00', 'C', 'F'),
         P_RESP_CDE,
         P_BUSINESS_DATE,
         SUBSTR(P_BUSINESS_TIME, 1, 10),
         V_HASH_PAN,
         NULL,
         NULL,
         NULL,
         P_INST_CODE,
         TRIM(TO_CHAR(nvl(V_TRAN_AMT,0), '999999999999999990.99')),--Modified for 10871
         V_CURRCODE,
         NULL,
         v_card_type,  --Added by Pankaj S. for 10871
         P_TERMINAL_ID,
         V_AUTH_ID,
         TRIM(TO_CHAR(nvl(V_TRAN_AMT,0), '999999999999999990.99')),  --Modified for 10871
         '0.00', --Modified by Pankaj S. for 10871
         '0.00', --Modified by Pankaj S. for 10871
         P_INST_CODE,
         V_ENCR_PAN,
         V_ENCR_PAN,
         V_ENCR_PAN,
         P_ORGNL_RRN,
         P_ORGNL_BUSINESS_DATE,
         P_ORGNL_BUSINESS_TIME,
         P_ORGNL_TERMINAL_ID,
         V_PROXUNUMBER,
         P_RVSL_CODE,
         V_ACCT_NUMBER,
         V_ACCT_BALANCE,
         V_LEDGER_BAL,
         V_RESP_CDE,
         /* Start Added by Dhiraj G on 31052012 for Pre - Auth Parameter changes  */
         P_NETWORK_ID,
         P_INTERCHANGE_FEEAMT,
         P_MERCHANT_ZIP,
         /* End Added by Dhiraj G on 31052012 for Pre - Auth Parameter changes  */
         V_TRAN_DESC,
         /*V_TXN_MERCHNAME, -- Added FOR MERCHANT DETAILS LOGGED IN TRANSACTIONLOG TABLE on 07-Sep-2012
        V_TXN_MERCHCITY,-- Added FOR MERCHANT DETAILS LOGGED IN TRANSACTIONLOG TABLE on 07-Sep-2012
        V_TXN_MERCHSTATE, -- Added FOR MERCHANT DETAILS LOGGED IN TRANSACTIONLOG TABLE on 07-Sep-2012*/
        --Commented and modified on 21.03.2013 for Merchant Logging Info for the Reversal Txn
        P_MERCHANT_NAME,
        P_MERCHANT_CITY,
        P_MERCHANT_STATE,
        P_NETWORK_SETL_DATE,  -- Added on 201112 for logging N/W settlement date in transactionlog
        P_MERCHANT_ID ,        --Added on 19-Mar-2013 for FSS-970
        decode(V_ORGNL_TXN,'NO ORGNL TXN','U'), --added for FSS-1145
        --Sn added by Pankaj S. for 10871
        v_prod_code,
        v_cap_card_stat,
        v_dr_cr_flag,
        v_acct_type,
        v_errmsg,
        nvl(systimestamp,v_timestamp),
        --En added by Pankaj S. for 10871     
         P_NETWORKID_SWITCH,  --Added on 20130626 for the Mantis ID 11344
         --SN Added on 30.07.2013 for 11695
        V_FEE_PLAN,
        V_FEE_CODE,
        V_FEE_AMT,
        V_FEEATTACH_TYPE
        --EN Added on 30.07.2013 for 11695
        ,v_internation_ind_response    
      );



     EXCEPTION
       WHEN OTHERS THEN

        P_RESP_CDE := '89';
        P_RESP_ID  := '89'; --Added for VMS-8018
        P_RESP_MSG := 'Problem while inserting data into transaction log  dtl' ||
                    SUBSTR(SQLERRM, 1, 300);
     END;
    END IF;
    --En create a entry in txn log
    BEGIN
     INSERT INTO CMS_TRANSACTION_LOG_DTL
       (CTD_DELIVERY_CHANNEL,
        CTD_TXN_CODE,
        CTD_TXN_TYPE,
        CTD_MSG_TYPE,
        CTD_TXN_MODE,
        CTD_BUSINESS_DATE,
        CTD_BUSINESS_TIME,
        CTD_CUSTOMER_CARD_NO,
        CTD_TXN_AMOUNT,
        CTD_TXN_CURR,
        CTD_ACTUAL_AMOUNT,
        CTD_FEE_AMOUNT,
        CTD_WAIVER_AMOUNT,
        CTD_SERVICETAX_AMOUNT,
        CTD_CESS_AMOUNT,
        CTD_BILL_AMOUNT,
        CTD_BILL_CURR,
        CTD_PROCESS_FLAG,
        CTD_PROCESS_MSG,
        CTD_RRN,
        CTD_SYSTEM_TRACE_AUDIT_NO,
        CTD_INST_CODE,
        CTD_CUSTOMER_CARD_NO_ENCR,
        CTD_CUST_ACCT_NUMBER,
        /* Start Added by Dhiraj G on 31052012 for Pre - Auth Parameter changes  */
        CTD_NETWORK_ID,
        CTD_INTERCHANGE_FEEAMT,
        CTD_MERCHANT_ZIP,
        /* End Added by Dhiraj G on 31052012 for Pre - Auth Parameter changes  */
        CTD_MERCHANT_ID          --Added on 19-Mar-2013 for FSS-970
        ,CTD_INTERNATION_IND_RESPONSE,
        ctd_completion_fee,ctd_complfee_increment_type
        )
     VALUES
       (P_DELV_CHNL,
        P_TXN_CODE,
        V_TXN_TYPE,
        P_MSG_TYP,
        P_TXN_MODE,
        P_BUSINESS_DATE,
        P_BUSINESS_TIME,
        V_HASH_PAN,
        P_ACTUAL_AMT,
        V_CURRCODE,
        V_TRAN_AMT,
        NULL,
        NULL,
        NULL,
        NULL,
        P_ACTUAL_AMT,
        V_CARD_CURR,
        'E',
        V_ERRMSG,
        P_RRN,
        P_STAN,
        P_INST_CODE,
        V_ENCR_PAN,
        V_ACCT_NUMBER,
        /* Start Added by Dhiraj G on 31052012 for Pre - Auth Parameter changes  */
        P_NETWORK_ID,
        P_INTERCHANGE_FEEAMT,
        P_MERCHANT_ZIP,
        /* End  Added by Dhiraj G on 31052012 for Pre - Auth Parameter changes  */
        P_MERCHANT_ID         --Added on 19-Mar-2013 for FSS-970
        ,v_internation_ind_response,
        v_comp_fee,v_complfee_increment_type
        );
    EXCEPTION
     WHEN OTHERS THEN
       P_RESP_MSG := 'Problem while inserting data into transaction log  dtl' ||
                  SUBSTR(SQLERRM, 1, 300);
       P_RESP_CDE := '69'; -- Server Decline Response 220509
       P_RESP_ID  := '69'; --Added for VMS-8018
       ROLLBACK;
       RETURN;
    END;
    P_RESP_MSG_M24 := V_ERRMSG;
END;

/

show error