CREATE OR REPLACE PROCEDURE VMSCMS.SP_REVERSAL_SAF_ISO93 (P_INST_CODE           IN NUMBER,
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
                                        P_ORGNL_STAN           IN VARCHAR2,
                                        P_NETWORKID_SWITCH    IN VARCHAR2, --Added on 20130626 for the Mantis ID 11344
                                        P_NETWORKID_ACQUIRER    IN VARCHAR2,-- Added on 20130626 for the Mantis ID 11344
                                        p_network_setl_date    IN  VARCHAR2, --Added on 20130626 for the Mantis ID 11123
                                        P_CVV_VERIFICATIONTYPE IN  VARCHAR2, --Added on 18.07.2013 for the Mantis ID 11611
                                        P_TRAN_AMNT            IN VARCHAR2, --Added on 07-10-13 for the Mantis ID-12547
                                        P_PULSE_TRANSACTIONID        IN       VARCHAR2,--Added for MVHOST 926 
                                        P_VISA_TRANSACTIONID          IN       VARCHAR2,--Added for MVHOST 926
                                        P_MC_TRACEID                 IN       VARCHAR2,--Added for MVHOST 926
                                        P_CARDVERIFICATION_RESULT      IN       VARCHAR2,--Added for MVHOST 926
                                        P_MERCHANT_STATE         IN VARCHAR2, -- Added for fss-2063
                                        P_AUTH_ID            OUT VARCHAR2,
                                        P_RESP_CDE     OUT VARCHAR2,
                                        P_RESP_MSG     OUT VARCHAR2,
                                        P_LEDGER_BAL         OUT VARCHAR2,
                                        P_RESP_MSG_M24 OUT VARCHAR2,
                                        P_ISO_RESPCDE        OUT VARCHAR2 , --Added on 18.07.2013 for the Mantis ID 11612    
                                        P_REVERSAL_AMOUNT OUT VARCHAR2 --Added  for  Mantis ID 13785 for To return the reversal amount on 21/03/201
                                        ,P_MERCHANT_ID IN       VARCHAR2   DEFAULT NULL
                                        ,P_MERCHANT_CNTRYCODE IN       VARCHAR2  DEFAULT NULL
                                        --SN Added by Pankaj S. for DB time logging changes                                                                   
                                         ,P_RESP_TIME OUT VARCHAR2
                                         ,P_RESPTIME_DETAIL OUT VARCHAR2
                                         --EN Added by Pankaj S. for DB time logging changes
                     ,P_MS_PYMNT_TYPE      in     varchar2 default null
                                        ,P_MS_PYMNT_DESC      IN      VARCHAR2  DEFAULT NULL
                                        ,P_RESP_ID            OUT     VARCHAR2 --Added for sending to FSS (VMS-8018)
                                        ) IS 
   /*************************************************
      * Modified By      :  Trivikram
      * Modified Date    :  14-NOV-12
      * Modified Reason  : Modified msgtype 9220 and 9221 with 1220 and 1221
      * Reviewer         : B.Besky Anand
      * Reviewed Date    : 14-NOV-12
      * Build Number     :  CMS3.5.1_RI0021_B0008

      * Modified By      : Pankaj S.
      * Modified Date    : 09-Feb-2013
      * Modified Reason  : Product Category spend limit not being adhered to by VMS
      * Reviewer         : Dhiraj
      * Reviewed Date    :
      * Build Number     :
      
      * Modified By      : Pankaj S.
      * Modified Date    : 15-Mar-2013
      * Modified Reason  : Logging of system initiated card status change(FSS-390)
      * Reviewer         : Dhiraj
      * Reviewed Date    : 
      * Build Number     : CMS3.5.1_RI0024_B0008
      
      * Modified By      : Sachin P.
      * Modified Date    : 08-Apr-2013
      * Modified Reason  : Limit Profile not accounting for reversal                          
      * Modified For     : MVHOST-298                               
      * Reviewer         : Dhiraj
      * Reviewed Date    : 19-Apr-2013
      * Build Number     : RI0024.1_B0008
      
      * Modified by      :  Pankaj S.
      * Modified Reason  :  10871
      * Modified Date    :  22-Apr-2013
      * Reviewer         :  Dhiraj
      * Reviewed Date    :  
      * Build Number     :  RI0024.1_B0013
      
      * Modified by      :  DHINAKARAN B
      * Modified Date    :  13-Jun-13    
      * Modified For     :  OLS REVERSAL TRANSACTION with MSG type 1420,CONSIDER AS THE SAF TRANSACTION(mantis id-11265)
      * Reviewer          :  Dhiraj
      * Reviewed Date     :  26-JUN-2013
      * Build Number      :  RI0024.2_B0009    

      * Modified by      : Deepa T
      * Modified for     : Mantis ID 11344,11123
      * Modified Reason  : Log the AcquirerNetworkID received in tag 005 and TermFIID received in tag 020 ,
                           Logging of network settlement date for OLS transactions 
      * Modified Date    : 26-Jun-2013
      * Reviewer         : 
      * Reviewed Date    : 
      * Build Number     : RI0024.2_B0009
      
      * Modified by      : Sagar  
      * Modified for     : FSS-1246
      * Modified Reason  : To compare original buiness time for duplicate SAF reversal transaction               
      * Modified Date    : 08-Jul-2013
      * Reviewer         : Dhiraj
      * Reviewed Date    : 
      * Build Number     : RI0024.3_B0002  
      
      * Modified by      : Sachin P.
      * Modified for     : Mantis ID -11611,11612
      * Modified Reason  : 11611-Input parameters needs to be included for the CVV verification 
                           We are doing and it needs to be logged in transactionlog
                           11612-Output parameter needs to be included to return the cms_iso_respcde of cms_response_mast  
      * Modified Date    : 18-Jul-2013
      * Reviewer         : Sagarm
      * Reviewed Date    : 22.07.2013
      * Build Number     : RI0024.3_B0005
      
      * Modified by      : Sagar M.
      * Modified for     : MVHOST-500
      * Modified Reason  : To check message type in case of Duplicate RRN check
                           and reject if same RRN repeats with 1420 or 1421   
      * Modified Date    : 26-Jun-2013
      * Reviewer         : Dhiarj
      * Reviewed Date    : 
      * Build Number     : RI0024.3.1_B0001      
      
      * Modified by       : Sagar  
      * Modified for      : FSS-1246 Review observations 
      * Modified Reason   : Review observations               
      * Modified Date     : 24-Jul-2013
      * Reviewer          : Dhiraj
      * Reviewed Date     : 
      * Build Number      : RI0024.4_B0002     
      
      * Modified by      : Sachin P.
      * Modified for     : Mantis Id:11695
      * Modified Reason  : Reversal Fee details(FeePlan id,FeeCode,Fee amount 
                          and FeeAttach Type) are not logged in transactionlog 
                          table. 
      * Modified Date    : 30.07.2013
      * Reviewer         : Dhiraj
      * Reviewed Date    : 19-Aug-2013
      * Build Number     : RI0024.4_B0002   
      
      * Modified by      : Sagar M.
      * Modified for     : 0012198
      * Modified Reason  : To reject duplicate STAN transaction
      * Modified Date    : 29-Aug-2013
      * Reviewer         : Dhiarj
      * Reviewed Date    : 29-Aug-2013
      * Build Number     : RI0024.3.5_B0001         
      
      * Modified by      : Siva Arcot.
      * Modified for     : 0010997 and FWR-11
      * Modified Reason  : Handle For Partial Reversal transaction
      * Modified Date    : 11-Sep-2013
      * Reviewer         : Dhiarj
      * Reviewed Date    : 11-Sep-2013
      * Build Number     : RI0024.4_B0010
      
      * Modified by      : Ramesh
      * Modified for     : LYFEHOST-74
      * Modified Reason  : Modified for LYFEHOST-74 
      * Modified Date    : 19-Sep-2013
      * Reviewer         : Dhiarj
      * Reviewed Date    : 19-Sep-2013
      * Build Number     : RI0024.5_B0001
      
      
      * Modified by     : Deepa T
      * Modified for     : Mantis ID-12547  and FSS-1334
      * Modified Reason  : To include teh cahnges of 1.7.4.3(To log the recevied tran amount for the Full reversal transactions )
      * Modified Date    : 16-Oct-2013
      * Reviewer         : Dhiraj
      * Reviewed Date    : 
      * Build Number     : RI0024.5_B0005       
      
      * Modified by       :  Sagar More
      * Modified for      :  Mantis ID- 
      * Modified Reason   :  To pass international indicator and pos verfication as null for merchantdise return transactions
      * Modified Date     :  21-Nov-2013
      * Reviewer          :  dhiraj
      * Reviewed Date     :  
      * Build Number      :  RI0024.6.1_B0002

     * Modified by      :  DHINAKARAN B
     * Modified for     :  FSS-1335
     * Modified Reason  :  To logging the international indicator in transactionlog. 
     * Modified Date    :  07-JAN-2014
     * Reviewer         :  Dhiraj 
     * Reviewed Date    :  07-JAN-2014 
     * Build Number     :  RI0027_B0003
     
      * Modified by      :  Abdul Hameed M.A
      * Modified for     :  Mantis ID-13406
      * Modified Reason  :  Reversal is appended with transaction description in CSR and we are also appending RVSL in this procedure.
                            To remove the duplicate word in the transaction decription  
      * Modified Date    :  17-JAN-2014
      * Reviewer         :  Dhiraj
      * Reviewed Date    :   
      * Build Number     :  RI0027_B0004
      
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
     * Modified Reason   : Added card number for duplicate RRN check
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
     
     * Modified by       : Dhinakaran B
     * Modified for      : VISA Certtification Changes integration in 2.2.2
     * Modified Date     : 01-JUL-2014
     * Build Number      : RI0027.2.2_B0001
     
      * Modified by       : Dhinakaran B
     * Modified for      : MVHOST -976
     * Modified Date     : 18-JUL-2014
     * Build Number      :  RI0027.2.4_B0001
     
     * Modified by       : MageshKumar S.
     * Modified Date     : 25-July-14    
     * Modified For      : FWR-48
     * Modified reason   : GL Mapping removal changes
     * Reviewer          : Spankaj
     * Build Number      : RI0027.3.1_B0001
     
     * Modified by       : Abdul Hameed M.A
     * Modified for      : FSS 1876
     * Modified Date     : 19-SEP-2014
     * Reviewer          : Spankaj
     * Build Number      : RI0027.3.3_B0001
     
     * Modified by       : Dhinakaran B
     * Modified for      : MVHOST-1041
     * Modified Date     : 11-Nov-2014
     * Reviewer          : Spankaj
     * Build Number      : RI0027.4.2.1
     
     * Modified by      : Dhinakaran B
     * Modified for     : MANTIS ID-15882 
     * Modified Date    : 17-Nov-2014
   * Reviewer         :  Saravanakumar
   * Build Number     : RI0027.4.2.2_B0002
   
     * Modified Date    : 30-DEC-2014
     * Modified By      : Dhinakaran B
     * Modified for     : MVHOST-1080/To Log the Merchant id & CountryCode
     * Reviewer         : 
     * Reviewed Date    : 
     * Release Number   : 
     
     * Modified by       : Dhinakaran B
     * Modified Date     : 19-Jan-2014    
     * Modified For      : FSS-2065
     
     * Modified by       : MAGESHKUMAR S.   
     * Modified Date     : 03-FEB-2015     
     * Modified For      : FSS-2063(2.4.2.4.1 & 2.4.3.1 integration)
     * Reviewer          : PANKAJ S.
     * Build Number      : RI0027.5_B0006
     
     * Modified By      : MageshKumar S
     * Modified Date    : 11-FEB-2015
     * Modified for     : INSTCODE REMOVAL(2.4.2.4.2 & 2.4.3.1 integration)
     * Reviewer         : Spankaj
     * Release Number   : RI0027.5_B0007
     
       * Modified By      : Pankaj S.
     * Modified Date    : 26-Feb-2015
     * Modified For     : 2.4.2.4.4/2.4.3.3 PERF Changes integration
     * Reviewer         : Sarvanankumar
     * Build Number     : RI0027.5_B0009  
     
         * Modified By      :  Abdul Hameed M.A
     * Modified For     :  Mantis ID-16035
     * Modified Date    :  26-Feb-2015
     * Reviewer         :  Spankaj
     * Build Number     : RI0027.5_B0009   
     
      * Modified By      :  Abdul Hameed M.A
     * Modified For     :  DFCTNM-4
     * Modified Date    :  1-Mar-2015
     * Reviewer         :  Spankaj
     * Build Number     : RI0027.5_B0009   
     
      * Modified By      :  Abdul Hameed M.A
     * Modified For     :  DFCTNM-4
     * Modified Date    :  3-Mar-2015
     * Reviewer         :  Spankaj
     * Build Number     : RI0027.5        
     
     * Modified by      : Narayanaswamy.T
     * Modified for     : FSS-4119 - ATM withdrawal transactions should contain terminal id and city in the statement
     * Modified Date    : 01-Mar-2016
     * Reviewer         : Saravanankumar
     * Build Number     : VMSGPRHOST_4.0_B0001
     
     * Modified by          : Spankaj
     * Modified Date        : 21-Nov-2016
     * Modified For         :FSS-4762:VMS OTC Support for Instant Payroll Card
     * Reviewer             : Saravanakumar
     * Build Number         : VMSGPRHOSTCSD4.11 
     
         * Modified By      : Saravana Kumar A
    * Modified Date    : 07/07/2017
    * Purpose          : Prod code and card type logging in statements log
    * Reviewer         : Pankaj S. 
    * Release Number   : VMSGPRHOST17.07
		 * Modified by       : DHINAKARAN B
     * Modified Date     : 18-Jul-17
     * Modified For      : FSS-5172 - B2B changes
     * Reviewer          : Saravanakumar A
     * Build Number      : VMSGPRHOST_17.07
     
    * Modified By      : UBAIDUR RAHMAN H
    * Modified Date    : 16-JAN-2018
    * Purpose          : CURRENCY CODE CHANGES FROM INST LEVEL TO BIN LEVEL.
    * Reviewer         : Vini
    * Release Number   : VMSGPRHOST18.1	 
	
	* Modified By      : Karthick/Jey
    * Modified Date    : 05-20-2022
    * Purpose          : Archival changes.
    * Reviewer         : venkat Singamaneni
    * Release Number   : VMSGPRHOST64 for VMS-5739/FSP-991
    
	* Modified By      : Areshka A.
    * Modified Date    : 03-Nov-2023
    * Purpose          : VMS-8018: Added new out parameter (response id) for sending to FSS
    * Reviewer         : 
    * Release Number   : 
    
   *************************************************/
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
  V_ERRMSG                   VARCHAR2(300):='OK'; --Added for 10871
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
  V_CUTOFF_TIME              VARCHAR2(5);
  V_BUSINESS_TIME            VARCHAR2(5);
  EXP_RVSL_REJECT_RECORD EXCEPTION;
  V_ATM_USAGEAMNT           CMS_TRANSLIMIT_CHECK.CTC_ATMUSAGE_AMT%TYPE;
  V_POS_USAGEAMNT           CMS_TRANSLIMIT_CHECK.CTC_POSUSAGE_AMT%TYPE;
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
  V_LEDGER_BAL              NUMBER;
  V_TRAN_DESC               CMS_TRANSACTION_MAST.CTM_TRAN_DESC%TYPE;
  V_ATM_USAGELIMIT          CMS_TRANSLIMIT_CHECK.CTC_ATMUSAGE_LIMIT%TYPE;
  V_POS_USAGELIMIT          CMS_TRANSLIMIT_CHECK.CTC_POSUSAGE_LIMIT%TYPE;
  V_BUSINESS_DATE_TRAN      DATE;
  V_ORGNL_TXN_AMNT          TRANSACTIONLOG.AMOUNT%TYPE;
  V_SAF_TXN_COUNT           NUMBER;
  V_ORGNL_TXN_RRN           TRANSACTIONLOG.RRN%TYPE;
  V_ORGNL_TXN_BUSINESS_DATE TRANSACTIONLOG.BUSINESS_DATE%TYPE;
  V_ORGNL_TXN_BUSINESS_TIME TRANSACTIONLOG.BUSINESS_TIME%TYPE;
  V_ORGNL_TXN_TERM_ID       TRANSACTIONLOG.TERMINAL_ID%TYPE;
  V_MAX_CARD_BAL            NUMBER;
  V_MMPOS_USAGEAMNT         CMS_TRANSLIMIT_CHECK.CTC_MMPOSUSAGE_AMT%TYPE;
  V_PROXUNUMBER             CMS_APPL_PAN.CAP_PROXY_NUMBER%TYPE;
  V_ACCT_NUMBER             CMS_APPL_PAN.CAP_ACCT_NO%TYPE;
  --AUTHID_DATE          VARCHAR2(8);
  V_TXN_NARRATION CMS_STATEMENTS_LOG.CSL_TRANS_NARRRATION%TYPE;
  V_FEE_NARRATION CMS_STATEMENTS_LOG.CSL_TRANS_NARRRATION%TYPE;

  --Added by Deepa for the changes to include Merchant name,city and state in statements log
  V_TXN_MERCHNAME  CMS_STATEMENTS_LOG.CSL_MERCHANT_NAME%TYPE;
  V_FEE_MERCHNAME  CMS_STATEMENTS_LOG.CSL_MERCHANT_NAME%TYPE;
  V_TXN_MERCHCITY  CMS_STATEMENTS_LOG.CSL_MERCHANT_CITY%TYPE;
  V_FEE_MERCHCITY  CMS_STATEMENTS_LOG.CSL_MERCHANT_CITY%TYPE;
  V_TXN_MERCHSTATE CMS_STATEMENTS_LOG.CSL_MERCHANT_STATE%TYPE;
  V_FEE_MERCHSTATE CMS_STATEMENTS_LOG.CSL_MERCHANT_STATE%TYPE;

  --Added by Deepa on June 26 2012 for Reversal Txn fee
  V_FEE_AMT   NUMBER;
  V_FEE_PLAN  CMS_FEE_PLAN.CFP_PLAN_ID%TYPE;
  V_TXN_TYPE  NUMBER(1);
  V_TRAN_DATE DATE;
  --Sn Added by Pankaj S. for FSS-390
  v_chnge_crdstat   VARCHAR2(2):='N';
  v_cap_card_stat   cms_appl_pan.cap_card_stat%TYPE;
  --En Added by Pankaj S. for FSS-390  
  
  v_prfl_code        cms_appl_pan.cap_prfl_code%TYPE; --Added on 08.04.2013 for MVHOST-298   
  v_prfl_flag        cms_transaction_mast.ctm_prfl_flag%type;--Added on 08.04.2013 for MVHOST-298
  v_tran_type        cms_transaction_mast.ctm_tran_type%type;--Added on 08.04.2013 for MVHOST-298
  v_pos_verification transactionlog.pos_verification%type; --Added on 08.04.2013 for MVHOST-298
  v_internation_ind_response transactionlog.internation_ind_response %type;--Added on 08.04.2013 for MVHOST-298
  V_ORGN_FOUND NUMBER(1) := 1; --Added on 04.04.2013 for MVHOST-298
  V_ORGNL_AMNT       TRANSACTIONLOG.AMOUNT%TYPE;--Added on 04.04.2013 for MVHOST-298
  v_add_ins_date          transactionlog.add_ins_date %type;--Added on 18.04.2013 for MVHOST-298    
  --Sn Added by Pankaj S. for 10871
  v_timestamp       timestamp(3);
  v_acct_type       cms_acct_mast.cam_type_code%TYPE;
  --En Added by Pankaj S. for 10871
  
    --OLS CHANGES on 13062013 
  V_ORGNL_RRN                    transactionlog.rrn%TYPE;
  V_CMS_ISO_RESPCODE            cms_response_mast.cms_iso_respcde%TYPE;
  V_DC_CODE                     CMS_DELCHANNEL_MAST.CDM_CHANNEL_DESC%TYPE;
  --END
  V_FEE_CODE           CMS_FEE_MAST.CFM_FEE_CODE%TYPE; --Added on 30.07.2013 for 11695
  V_FEEATTACH_TYPE     VARCHAR2(2); --Added on 30.07.2013 for 11695
  V_STAN_COUNT                  NUMBER; -- Added for Duplicate Stan check 0012198
  V_ORGNL_TXN_FEE_PLAN     TRANSACTIONLOG.FEE_PLAN%TYPE; --Added for FWR-11
  v_feecap_flag VARCHAR2(1); --Added for FWR-11
  v_orgnl_fee_amt  CMS_FEE_MAST.CFM_FEE_AMT%TYPE; --Added for FWR-11
  V_REVERSAL_AMT_FLAG VARCHAR2(1) :='F';  ---Added for Mantis Id-0010997
  
  V_NETWORKIDCOUNT  number default 0; -- lyfe changes.
  
  V_INTERCHANGE_FEEAMT   number default 0;
  V_CTM_PREAUTH_FLAG CMS_TRANSACTION_MAST.CTM_PREAUTH_FLAG%type;
   V_MS_PYMNT_TYPE CMS_PAYMENT_TYPE.CPT_PAYMENT_TYPE%type;
    V_HASHKEY_ID   CMS_TRANSACTION_LOG_DTL.CTD_HASHKEY_ID%TYPE; 
 --SN Added by Pankaj S. for DB time logging changes
   v_start_time timestamp;
   v_mili VARCHAR2(100);
   --EN Added by Pankaj S. for DB time logging changes
  V_PREAUTH_TYPE           CMS_TRANSACTION_MAST.CTM_PREAUTH_TYPE%type;
  V_ORG_MSGTYPE      TRANSACTIONLOG.MSGTYPE%type;
  v_profile_code      cms_prod_cattype.cpc_profile_code%type;
  
  v_Retperiod  date;  --Added for VMS-5739/FSP-991
  v_Retdate  date; --Added for VMS-5739/FSP-991
  
  CURSOR FEEREVERSE IS
    SELECT CSL_TRANS_NARRRATION,
         CSL_MERCHANT_NAME,
         CSL_MERCHANT_CITY,
         CSL_MERCHANT_STATE,
         ROUND(CSL_TRANS_AMOUNT,2) CSL_TRANS_AMOUNT
     FROM VMSCMS.CMS_STATEMENTS_LOG_VW                   --Added for VMS-5739/FSP-991
    WHERE CSL_BUSINESS_DATE = V_ORGNL_BUSINESS_DATE AND
         CSL_BUSINESS_TIME = V_ORGNL_BUSINESS_TIME AND
         CSL_RRN = V_ORGNL_RRN AND     -- P_ORGNL_RRN AND   --OLS CHANGES on 13062013 
         CSL_DELIVERY_CHANNEL = V_ORGNL_DELIVERY_CHANNEL AND
         CSL_TXN_CODE = V_ORGNL_TXN_CODE AND
         CSL_PAN_NO = V_ORGNL_CUSTOMER_CARD_NO AND
         CSL_INST_CODE = P_INST_CODE AND TXN_FEE_FLAG = 'Y';
BEGIN

  P_RESP_CDE := '00';
  P_RESP_MSG := 'OK';
   v_start_time := systimestamp;   --Added by Pankaj S. for DB time logging changes
V_MS_PYMNT_TYPE:=P_MS_PYMNT_TYPE;
    V_TIMESTAMP:=systimestamp; 
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
 --Start Generate HashKEY value 
       BEGIN
           V_HASHKEY_ID := GETHASH (P_DELV_CHNL||P_TXN_CODE||P_CARD_NO||P_RRN||to_char(V_TIMESTAMP,'YYYYMMDDHH24MISSFF5'));
       EXCEPTION
        WHEN OTHERS
        THEN
        V_RESP_CDE := '21';
        V_ERRMSG :='Error while converting master data ' || SUBSTR (SQLERRM, 1, 200);
        RAISE EXP_RVSL_REJECT_RECORD;
     end;
   --End Generate HashKEY value 

  --Sn find the type of orginal txn (credit or debit)
  BEGIN
    SELECT CTM_CREDIT_DEBIT_FLAG,
         CTM_TRAN_DESC,
         TO_NUMBER(DECODE(CTM_TRAN_TYPE, 'N', '0', 'F', '1')), --Added By Deepa on June 26 2012 for Narration of reversal fee
         CTM_PRFL_FLAG,CTM_TRAN_TYPE --Added on 04.04.2013 for MVHOST-298
         ,CTM_PREAUTH_FLAG,CTM_PREAUTH_TYPE
     INTO V_DR_CR_FLAG, V_TRAN_DESC, V_TXN_TYPE,
          V_PRFL_FLAG,V_TRAN_TYPE --Added on 04.04.2013 for MVHOST-298
          ,V_CTM_PREAUTH_FLAG,V_PREAUTH_TYPE
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

if V_MS_PYMNT_TYPE is not null then
     if(  V_PREAUTH_TYPE='D') then
                -- V_TRAN_DESC:='MoneySend'||' '||V_TRAN_DESC;
                 V_TRAN_DESC:='MoneySend Funding Settlement';
                 END IF;
   
   if V_MS_PYMNT_TYPE='P' then
   V_MS_PYMNT_TYPE:=null;
   end if;
   end if;
  --Sn generate auth id
  BEGIN
    --SELECT TO_CHAR(SYSDATE, 'YYYYMMDD') INTO AUTHID_DATE FROM DUAL;

    --    SELECT TO_CHAR(SYSDATE, 'YYYYMMDD')  || LPAD(SEQ_AUTH_ID.NEXTVAL, 6, '0')
    SELECT LPAD(SEQ_AUTH_ID.NEXTVAL, 6, '0') INTO V_AUTH_ID FROM DUAL;

  EXCEPTION
    WHEN OTHERS THEN
     V_ERRMSG   := 'Error while generating authid ' ||
                SUBSTR(SQLERRM, 1, 300);
     V_RESP_CDE := '21'; -- Server Declined
     RAISE EXP_RVSL_REJECT_RECORD;
  END;

  --En generate auth id

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

  --Sn get date
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
  --En get date
  /*
  ---------------------------------------------
  --SN: Added for Duplicate STAN check 0012198
  ---------------------------------------------
if (P_MSG_TYP <> '1421') then   --Added for FSS 1876
  BEGIN

    SELECT COUNT(1)
     INTO V_STAN_COUNT
     FROM TRANSACTIONLOG
    WHERE INSTCODE = P_INST_CODE
    and   CUSTOMER_CARD_NO  = V_HASH_PAN
    AND   BUSINESS_DATE = P_BUSINESS_DATE 
    AND   DELIVERY_CHANNEL = P_DELV_CHNL
    AND   SYSTEM_TRACE_AUDIT_NO = P_STAN; 

    IF V_STAN_COUNT > 0 THEN

     V_RESP_CDE := '191';
     V_ERRMSG   := 'Duplicate Stan from the Treminal' || P_TERMINAL_ID || 'on' ||
                P_BUSINESS_DATE;
     RAISE EXP_RVSL_REJECT_RECORD;

    END IF;
    
    
  EXCEPTION WHEN EXP_RVSL_REJECT_RECORD 
  THEN
        RAISE EXP_RVSL_REJECT_RECORD;
            
  WHEN OTHERS THEN
      
   V_RESP_CDE := '21';
   V_ERRMSG  := 'Error while checking duplicate STAN ' ||SUBSTR(SQLERRM,1,200);
   RAISE EXP_RVSL_REJECT_RECORD;

  END;
      
  ---------------------------------------------
  --SN: Added for Duplicate STAN check 0012198
  ---------------------------------------------
  

  --Sn Duplicate RRN Check

 /* BEGIN

    SELECT COUNT(1)
     INTO V_RRN_COUNT
     FROM TRANSACTIONLOG
    WHERE 
    --TERMINAL_ID = P_TERMINAL_ID   --OLS CHANGES on 13062013  
         RRN = P_RRN AND
         BUSINESS_DATE = P_BUSINESS_DATE AND
         DELIVERY_CHANNEL = P_DELV_CHNL --Added by ramkumar.Mk on 25 march 2012
         AND MSGTYPE IN ('1420','1421')    --Added for MVHOST-500
         AND TXN_CODE =   P_TXN_CODE  ; --Added for MVHOST-500 on 02.08.2013
         
    IF V_RRN_COUNT > 0 THEN

     V_RESP_CDE := '22';
     V_ERRMSG   := 'Duplicate RRN from the Treminal' || P_TERMINAL_ID || 'on' ||
                P_BUSINESS_DATE;
     RAISE EXP_RVSL_REJECT_RECORD;

    END IF;

  END;
*/
-- MODIFIED BY ABDUL HAMEED M.A ON 06-03-2014
/* BEGIN
      sp_dup_rrn_check (v_hash_pan, p_rrn, P_BUSINESS_DATE, P_DELV_CHNL, P_MSG_TYP, p_txn_code, V_ERRMSG );
      IF V_ERRMSG <> 'OK' THEN
        v_resp_cde := '22';
        RAISE EXP_RVSL_REJECT_RECORD;
      END IF;
    EXCEPTION
    WHEN EXP_RVSL_REJECT_RECORD THEN
      RAISE;
    WHEN OTHERS THEN
      v_resp_cde := '22';
      V_ERRMSG  := 'Error while checking RRN' || SUBSTR (SQLERRM, 1, 200);
      RAISE EXP_RVSL_REJECT_RECORD;
    END;*/
  --En Duplicate RRN Check
--end if;  --Added for FSS 1876

    --Sn get the product code
      BEGIN
        SELECT CAP_PROD_CODE, CAP_CARD_TYPE,CAP_ACCT_NO,     --Added by Besky on 09-nov-12
               cap_card_stat,
               cap_prfl_code --Added on 04.04.2013 for MVHOST-298
         INTO V_PROD_CODE, V_CARD_TYPE,V_ACCT_NUMBER,   --Added by Besky on 09-nov-12
              v_cap_card_stat,
              v_prfl_code --Added on 04.04.2013 for MVHOST-298
         FROM CMS_APPL_PAN
        WHERE --CAP_INST_CODE = P_INST_CODE AND  --For Instcode removal of 2.4.2.4.2 release
        CAP_PAN_CODE = V_HASH_PAN;
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
 --OLS CHANGES on 13062013 
     IF P_DELV_CHNL = '02' THEN
     V_DC_CODE := 'POS';
    ELSIF P_DELV_CHNL = '01' THEN
     V_DC_CODE := 'ATM';
    END IF;
    SELECT CDM_CHANNEL_CODE
     INTO V_DELCHANNEL_CODE
     FROM CMS_DELCHANNEL_MAST
    WHERE CDM_CHANNEL_DESC = V_DC_CODE AND CDM_INST_CODE = P_INST_CODE;
    --IF the DeliveryChannel is MMPOS then the base currency will be the txn curr

    IF P_CURR_CODE IS NULL AND V_DELCHANNEL_CODE = P_DELV_CHNL THEN

     BEGIN
       SELECT TRIM(CBP_PARAM_VALUE)
        INTO V_BASE_CURR
        FROM CMS_BIN_PARAM
        WHERE CBP_INST_CODE = P_INST_CODE AND CBP_PARAM_NAME = 'Currency'
        AND CBP_PROFILE_CODE = v_profile_code;

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
    WHEN NO_DATA_FOUND THEN
     V_ERRMSG := 'Deleivery cahnnel is not defined for the institution ';
     RAISE EXP_RVSL_REJECT_RECORD;
    WHEN OTHERS THEN
     V_ERRMSG := 'Error while selecting deleivery channel' ||
               SUBSTR(SQLERRM, 1, 200);
     RAISE EXP_RVSL_REJECT_RECORD;
  END;

  --Sn check msg type   --OLS CHANGES on 13062013 
  IF V_DELCHANNEL_CODE <> P_DELV_CHNL THEN

    IF (P_MSG_TYP NOT IN ('1420', '1421')) OR (P_RVSL_CODE = '00') THEN

     V_RESP_CDE := '12';
     V_ERRMSG   := 'Not a valid reversal request';
     RAISE EXP_RVSL_REJECT_RECORD;

    END IF;
  END IF;
  --En check msg type

  --Sn check orginal transaction    (-- Amount is missing in reversal request)
  BEGIN
  
       --Added for VMS-5739/FSP-991
       select (add_months(trunc(sysdate,'MM'),'-'||RETENTION_PERIOD))
       INTO   v_Retperiod 
       FROM DBA_OPERATIONS.ARCHIVE_MGMNT_CTL  
       WHERE  OPERATION_TYPE='ARCHIVE' 
       AND OBJECT_NAME='TRANSACTIONLOG_EBR';
       
       v_Retdate := TO_DATE(SUBSTR(TRIM(P_ORGNL_BUSINESS_DATE), 1, 8), 'yyyymmdd');
	 
    IF (v_Retdate>v_Retperiod) THEN	                             --Added for VMS-5739/FSP-991
	
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
         AMOUNT,
         pos_verification,--Added on 04.04.2013 for MVHOST-298
         internation_ind_response,--Added on 04.04.2013 for MVHOST-298
         add_ins_date,         --Added on 18.04.2013 for MVHOST-298
          RRN                   --OLS CHANGES on 13062013
          ,NVL(INTERCHANGE_FEEAMT,0) 
          ,msgtype
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
         V_ORGNL_TXN_AMNT,
         v_pos_verification,--Added on 04.04.2013 for MVHOST-298
         v_internation_ind_response,--Added on 04.04.2013 for MVHOST-298
         v_add_ins_date,          --Added on 18.04.2013 for MVHOST-298
         V_ORGNL_RRN       --OLS CHANGES on 13062013
         ,V_INTERCHANGE_FEEAMT
         ,v_org_msgtype
      FROM TRANSACTIONLOG
      WHERE SYSTEM_TRACE_AUDIT_NO=P_ORGNL_STAN  
--         RRN = P_ORGNL_RRN           --OLS CHANGES on 13062013 
         AND BUSINESS_DATE = P_ORGNL_BUSINESS_DATE AND
         BUSINESS_TIME = P_ORGNL_BUSINESS_TIME AND
         CUSTOMER_CARD_NO = V_HASH_PAN --P_card_no
        -- AND INSTCODE = P_INST_CODE AND --For Instcode removal of 2.4.2.4.2 release
        -- TERMINAL_ID = P_ORGNL_TERMINAL_ID AND RESPONSE_CODE = '00'
         AND  DELIVERY_CHANNEL = P_DELV_CHNL --Added by ramkumar.Mk on 25 march 2012
         AND RESPONSE_CODE = '00'        --OLS CHANGES on 13062013 
         ORDER BY ADD_INS_DATE DESC; 

    ELSE

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
         AMOUNT,
         pos_verification,--Added on 04.04.2013 for MVHOST-298
         internation_ind_response,--Added on 04.04.2013 for MVHOST-298
         add_ins_date,         --Added on 18.04.2013 for MVHOST-298
          RRN                   --OLS CHANGES on 13062013
          ,NVL(INTERCHANGE_FEEAMT,0) 
          ,msgtype
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
         V_ORGNL_TXN_AMNT,
         v_pos_verification,--Added on 04.04.2013 for MVHOST-298
         v_internation_ind_response,--Added on 04.04.2013 for MVHOST-298
         v_add_ins_date,          --Added on 18.04.2013 for MVHOST-298
         V_ORGNL_RRN       --OLS CHANGES on 13062013
         ,V_INTERCHANGE_FEEAMT
         ,v_org_msgtype
       FROM VMSCMS_HISTORY.TRANSACTIONLOG_HIST                         --Added for VMS-5739/FSP-991
       WHERE SYSTEM_TRACE_AUDIT_NO=P_ORGNL_STAN  
--         RRN = P_ORGNL_RRN           --OLS CHANGES on 13062013 
         AND BUSINESS_DATE = P_ORGNL_BUSINESS_DATE AND
         BUSINESS_TIME = P_ORGNL_BUSINESS_TIME AND
         CUSTOMER_CARD_NO = V_HASH_PAN --P_card_no
        -- AND INSTCODE = P_INST_CODE AND --For Instcode removal of 2.4.2.4.2 release
        -- TERMINAL_ID = P_ORGNL_TERMINAL_ID AND RESPONSE_CODE = '00'
         AND  DELIVERY_CHANNEL = P_DELV_CHNL --Added by ramkumar.Mk on 25 march 2012
         AND RESPONSE_CODE = '00'        --OLS CHANGES on 13062013 
         ORDER BY ADD_INS_DATE DESC; 



    END IF;	
       
    IF V_MS_PYMNT_TYPE        IS NOT NULL THEN
  IF( V_PREAUTH_TYPE       ='D') THEN
    IF( v_org_msgtype     IS NOT NULL) THEN
      IF (V_ORG_MSGTYPE   IN ('1220','1221')) THEN
        V_TRAN_DESC      :='MoneySend Funding Settlement';
      elsif v_org_msgtype IN ('1200','1201') THEN
        V_TRAN_DESC      :='MoneySend Funding';
      END IF;
    ELSE
      V_TRAN_DESC :='MoneySend Funding Settlement';
    END IF;
  ELSIF ( V_PREAUTH_TYPE ='C') THEN
    IF( v_org_msgtype   IS NOT NULL) THEN
      IF (v_org_msgtype IN ('1200','1201')) THEN
        V_TRAN_DESC    :='MoneySend Payment';
      END IF;
    END IF;
  end if;
END IF;   
    
         
    IF V_ORGNL_RESP_CODE <> '00' THEN

     IF P_MSG_TYP NOT IN ('1420', '1421') THEN -- Modified msgtype 9220 and 9221 with 1220 and 1221  by Trivikram on 14/Nov/2012 , 
                                                 --Change the msgtype for OLS CHANGES on 13062013 
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
     V_ORGN_FOUND := 0; --Added on 18.04.2013 for MVHOST-298
    -- IF P_MSG_TYP NOT IN ('1420', '1421') THEN -- Modified msgtype 9220 and 9221 with 1220 and 1221  by Trivikram on 14/Nov/2012 ,
                                                --Change the msgtype for OLS CHANGES on 13062013
       --Commented For MVHOST -976                                                 
       V_RESP_CDE := '53';
       V_ERRMSG   := 'Matching transaction not found';
       RAISE EXP_RVSL_REJECT_RECORD;

   --  END IF;
    WHEN TOO_MANY_ROWS THEN

     IF P_MSG_TYP NOT IN ('1420', '1421') THEN  -- Modified msgtype 9220 and 9221 with 1220 and 1221  by Trivikram on 14/Nov/2012 ,
                                                --Change the msgtype for OLS CHANGES on 13062013 
       V_RESP_CDE := '21';
       V_ERRMSG   := 'More than one matching record found in the master';
       RAISE EXP_RVSL_REJECT_RECORD;
     END IF;

    WHEN OTHERS THEN

     IF P_MSG_TYP NOT IN ('1420', '1421') THEN -- Modified msgtype 9220 and 9221 with 1220 and 1221  by Trivikram on 14/Nov/2012 ,
                                                --Change the msgtype for OLS CHANGES on 13062013 
       V_RESP_CDE := '21';
       V_ERRMSG   := 'Error while selecting master data' ||
                  SUBSTR(SQLERRM, 1, 200);
       RAISE EXP_RVSL_REJECT_RECORD;

     END IF;
  END;
  
  --En check orginal transaction
  
    ---Sn check card number  --OLS CHANGES on 13062013 
  IF V_ORGNL_CUSTOMER_CARD_NO <> V_HASH_PAN THEN

    V_RESP_CDE := '21';
    V_ERRMSG   := 'Customer card number is not matching in reversal and orginal transaction';
    RAISE EXP_RVSL_REJECT_RECORD;

  END IF;
  --En check card number
 
  IF P_MSG_TYP = '1421' AND V_CTM_PREAUTH_FLAG <>  'Y' THEN      --Change the msgtype for OLS CHANGES on 13062013 

       --Added for VMS-5739/FSP-991
       select (add_months(trunc(sysdate,'MM'),'-'||RETENTION_PERIOD))
       INTO   v_Retperiod 
       FROM DBA_OPERATIONS.ARCHIVE_MGMNT_CTL  
       WHERE  OPERATION_TYPE='ARCHIVE' 
       AND OBJECT_NAME='TRANSACTIONLOG_EBR';
       
       v_Retdate := TO_DATE(SUBSTR(TRIM(P_BUSINESS_DATE), 1, 8), 'yyyymmdd');
	
    IF (v_Retdate>v_Retperiod) THEN	                            --Added for VMS-5739/FSP-991
	
     SELECT COUNT(*)
     INTO V_SAF_TXN_COUNT
     FROM TRANSACTIONLOG
     WHERE RRN = P_RRN AND BUSINESS_DATE = P_BUSINESS_DATE AND
         CUSTOMER_CARD_NO = V_HASH_PAN AND --INSTCODE = P_INST_CODE AND --For Instcode removal of 2.4.2.4.2 release
        --TERMINAL_ID = P_ORGNL_TERMINAL_ID AND
         RESPONSE_CODE = '00' AND MSGTYPE = '1420'  --Change the msgtype for OLS CHANGES on 13062013 
         AND TXN_CODE = P_TXN_CODE; --Added for MVHOST-500  on 02.08.2013
		 
	ELSE
	 
	 SELECT COUNT(*)
     INTO V_SAF_TXN_COUNT
     FROM VMSCMS_HISTORY.TRANSACTIONLOG_HIST                  --Added for VMS-5739/FSP-991
     WHERE RRN = P_RRN AND BUSINESS_DATE = P_BUSINESS_DATE AND
         CUSTOMER_CARD_NO = V_HASH_PAN AND --INSTCODE = P_INST_CODE AND --For Instcode removal of 2.4.2.4.2 release
        --TERMINAL_ID = P_ORGNL_TERMINAL_ID AND
         RESPONSE_CODE = '00' AND MSGTYPE = '1420'  --Change the msgtype for OLS CHANGES on 13062013 
         AND TXN_CODE = P_TXN_CODE; --Added for MVHOST-500  on 02.08.2013
	
	
	END IF;

    IF V_SAF_TXN_COUNT > 0 THEN

     V_RESP_CDE := '52';
     V_ERRMSG   := 'Successful SAF Transaction has already done' ||
                SUBSTR(SQLERRM, 1, 200);
     RAISE EXP_RVSL_REJECT_RECORD;

    END IF;

  END IF;

  --Added by srinivasu
  

  IF (P_MSG_TYP = '1421' OR P_MSG_TYP = '1420') AND V_CTM_PREAUTH_FLAG <>  'Y' THEN  --Change the msgtype for OLS CHANGES on 13062013 

       --Added for VMS-5739/FSP-991
       select (add_months(trunc(sysdate,'MM'),'-'||RETENTION_PERIOD))
       INTO   v_Retperiod 
       FROM DBA_OPERATIONS.ARCHIVE_MGMNT_CTL  
       WHERE  OPERATION_TYPE='ARCHIVE' 
       AND OBJECT_NAME='TRANSACTIONLOG_EBR';
       
       v_Retdate := TO_DATE(SUBSTR(TRIM(P_ORGNL_BUSINESS_DATE), 1, 8), 'yyyymmdd');
	 
    IF (v_Retdate>v_Retperiod) THEN	                                            --Added for VMS-5739/FSP-991
	
     SELECT COUNT(*)
     INTO V_SAF_TXN_COUNT
     FROM TRANSACTIONLOG
     WHERE --ORGNL_RRN = P_ORGNL_RRN AND                     --Commented for FSS-1246
         ORIGINAL_STAN = P_ORGNL_STAN AND             --Added for FSS-1246
         ORGNL_BUSINESS_DATE = P_ORGNL_BUSINESS_DATE AND
         CUSTOMER_CARD_NO = V_HASH_PAN --P_card_no
        -- AND INSTCODE = P_INST_CODE AND --For Instcode removal of 2.4.2.4.2 release
        --ORGNL_TERMINAL_ID = P_ORGNL_TERMINAL_ID
         AND RESPONSE_CODE = '00' AND MSGTYPE IN ('1420', '1421')
         AND ORGNL_BUSINESS_TIME = P_ORGNL_BUSINESS_TIME;     --Added for FSS-1246
		 
    ELSE
	 
	 SELECT COUNT(*)
     INTO V_SAF_TXN_COUNT
     FROM VMSCMS_HISTORY.TRANSACTIONLOG_HIST                              --Added for VMS-5739/FSP-991
     WHERE --ORGNL_RRN = P_ORGNL_RRN AND                     --Commented for FSS-1246
         ORIGINAL_STAN = P_ORGNL_STAN AND             --Added for FSS-1246
         ORGNL_BUSINESS_DATE = P_ORGNL_BUSINESS_DATE AND
         CUSTOMER_CARD_NO = V_HASH_PAN --P_card_no
        -- AND INSTCODE = P_INST_CODE AND --For Instcode removal of 2.4.2.4.2 release
        --ORGNL_TERMINAL_ID = P_ORGNL_TERMINAL_ID
         AND RESPONSE_CODE = '00' AND MSGTYPE IN ('1420', '1421')
         AND ORGNL_BUSINESS_TIME = P_ORGNL_BUSINESS_TIME;     --Added for FSS-1246
	
	
	END IF;

    IF V_SAF_TXN_COUNT > 0 THEN

     V_RESP_CDE := '155'; --Changed from 52 to 168 for FSS-1246
     V_ERRMSG   := 'Successful SAF Reversal Transaction has already done';
     
     RAISE EXP_RVSL_REJECT_RECORD;

    END IF;

  END IF;
  --SN: Query shifted above before acct mast query

 --EN: Query shifted above before acct mast query

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
    V_RESP_CDE := '43';
    V_ERRMSG   := 'INVALID AMOUNT';
    RAISE EXP_RVSL_REJECT_RECORD;
  END IF;

  --En find the  converted tran amt

  --Sn Find the reversal amount based on dispensed amount and Oringinal txn amount
  BEGIN

    IF (V_TRAN_AMT IS NULL OR V_TRAN_AMT = 0) THEN

     V_ACTUAL_DISPATCHED_AMT := 0;

    ELSE
     V_ACTUAL_DISPATCHED_AMT := V_TRAN_AMT;

    END IF;

    IF (V_ORGNL_TOTAL_AMOUNT IS NULL) THEN

     V_REVERSAL_AMT := V_ACTUAL_DISPATCHED_AMT;
    ELSE

     V_REVERSAL_AMT := V_ORGNL_TOTAL_AMOUNT - V_ACTUAL_DISPATCHED_AMT;

    END IF;
    IF V_REVERSAL_AMT < V_ORGNL_TOTAL_AMOUNT THEN   ---Modified For Mantis id-0010997  
      V_REVERSAL_AMT_FLAG :='P';
    END IF;

  END;
  --En Find the reversal amount based on dispensed amount and Oringinal txn amount

  
    







  --Sn find prod code and card type and available balance for the card number
  BEGIN
    SELECT CAM_ACCT_BAL, CAM_LEDGER_BAL,
           cam_type_code  --added by Pankaj S. for 10871
     INTO V_ACCT_BALANCE, V_LEDGER_BAL,
          v_acct_type  --added by Pankaj S. for 10871
     FROM CMS_ACCT_MAST
    WHERE CAM_ACCT_NO = V_ACCT_NUMBER           --V_ACCT_NUMBER Added instead of subquery
    --         (SELECT CAP_ACCT_NO
    --            FROM CMS_APPL_PAN
    --           WHERE CAP_PAN_CODE = V_HASH_PAN AND CAP_MBR_NUMB = P_MBR_NUMB AND
    --                CAP_INST_CODE = P_INST_CODE) 
         AND CAM_INST_CODE = P_INST_CODE
        FOR UPDATE;                           -- Added for Concurrent Processsing Issue
        --FOR UPDATE NOWAIT;                     -- Commented for Concurrent Processsing Issue  EXCEPTION
  EXCEPTION  WHEN NO_DATA_FOUND THEN
     V_RESP_CDE := '14'; --Ineligible Transaction
     V_ERRMSG   := 'Invalid Card ';
     RAISE EXP_RVSL_REJECT_RECORD;
    WHEN OTHERS THEN
     V_RESP_CDE := '12';
     V_ERRMSG   := 'Error while selecting data from card Master for card number ' ||
                SQLERRM;
     RAISE EXP_RVSL_REJECT_RECORD;
  END;

  --En find prod code and card type for the card number
      --SN Added by Pankaj S. for DB time logging changes
    SELECT (  EXTRACT (DAY FROM SYSTIMESTAMP - v_start_time) * 86400
            + EXTRACT (HOUR FROM SYSTIMESTAMP - v_start_time) * 3600
            + EXTRACT (MINUTE FROM SYSTIMESTAMP - v_start_time) * 60
            + EXTRACT (SECOND FROM SYSTIMESTAMP - v_start_time) * 1000)
      INTO v_mili
      FROM DUAL;
      
    P_RESPTIME_DETAIL := '1: ' || v_mili ;
    --EN Added by Pankaj S. for DB time logging changes
  
   ------------------------------------------------------
        --Sn Added for Concurrent Processsing Issue
    ------------------------------------------------------        
    --SN Commented by Pankaj S. for PERF Changes
 /*if (P_MSG_TYP <> '1421') then  --Added for FSS 1876
      BEGIN

        SELECT COUNT(1)
         INTO V_STAN_COUNT
         FROM TRANSACTIONLOG
        WHERE --INSTCODE = P_INST_CODE and   --For Instcode removal of 2.4.2.4.2 release
        CUSTOMER_CARD_NO  = V_HASH_PAN
        AND   BUSINESS_DATE = P_BUSINESS_DATE 
        AND   DELIVERY_CHANNEL = P_DELV_CHNL
        AND   ADD_INS_DATE BETWEEN TRUNC(SYSDATE-1)  AND SYSDATE
        AND   SYSTEM_TRACE_AUDIT_NO = P_STAN; 

        IF V_STAN_COUNT > 0 THEN

         V_RESP_CDE := '191';
         V_ERRMSG   := 'Duplicate Stan from the Treminal' || P_TERMINAL_ID || 'on' ||
                    P_BUSINESS_DATE;
         RAISE EXP_RVSL_REJECT_RECORD;

        END IF;
        
        
      EXCEPTION WHEN EXP_RVSL_REJECT_RECORD 
      THEN
            RAISE EXP_RVSL_REJECT_RECORD;
                
      WHEN OTHERS THEN
          
       V_RESP_CDE := '21';
       V_ERRMSG  := 'Error while checking duplicate STAN ' ||SUBSTR(SQLERRM,1,200);
       RAISE EXP_RVSL_REJECT_RECORD;

      END;*/  --Commented by Pankaj S. for PERF Changes
      
      --Sn Duplicate RRN Check

     /* BEGIN

        SELECT COUNT(1)
         INTO V_RRN_COUNT
         FROM TRANSACTIONLOG
        WHERE RRN = P_RRN AND
             BUSINESS_DATE = P_BUSINESS_DATE AND
             DELIVERY_CHANNEL = P_DELV_CHNL 
             AND MSGTYPE IN ('1420','1421') 
             AND TXN_CODE =   P_TXN_CODE  ; 
             
        IF V_RRN_COUNT > 0 THEN

         V_RESP_CDE := '22';
         V_ERRMSG   := 'Duplicate RRN from the Treminal' || P_TERMINAL_ID || 'on' ||
                    P_BUSINESS_DATE;
         RAISE EXP_RVSL_REJECT_RECORD;

        END IF;

      END;
*/

-- MODIFIED BY ABDUL HAMEED M.A ON 06-03-2014
 /*BEGIN
      sp_dup_rrn_check (v_hash_pan, p_rrn, P_BUSINESS_DATE, P_DELV_CHNL, P_MSG_TYP, p_txn_code, V_ERRMSG );
      IF V_ERRMSG <> 'OK' THEN
        v_resp_cde := '22';
        RAISE EXP_RVSL_REJECT_RECORD;
      END IF;
    EXCEPTION
    WHEN EXP_RVSL_REJECT_RECORD THEN
      RAISE;
    WHEN OTHERS THEN
      v_resp_cde := '22';
      V_ERRMSG  := 'Error while checking RRN' || SUBSTR (SQLERRM, 1, 200);
      RAISE EXP_RVSL_REJECT_RECORD;
    end;*/
--end if;  --Added for FSS 1876 --Commented by Pankaj S. for PERF Changes

    
      IF P_MSG_TYP = '1421' AND V_CTM_PREAUTH_FLAG <>  'Y'  THEN      

        v_Retdate := TO_DATE(SUBSTR(TRIM(P_BUSINESS_DATE), 1, 8), 'yyyymmdd');  --Added for VMS-5739/FSP-991
		
	  IF (v_Retdate>v_Retperiod) THEN                      --Added for VMS-5739/FSP-991
	  
        SELECT COUNT(*)
         INTO V_SAF_TXN_COUNT
         FROM TRANSACTIONLOG
        WHERE RRN = P_RRN AND BUSINESS_DATE = P_BUSINESS_DATE AND
             CUSTOMER_CARD_NO = V_HASH_PAN AND --INSTCODE = P_INST_CODE AND --For Instcode removal of 2.4.2.4.2 release
             RESPONSE_CODE = '00' AND MSGTYPE = '1420' 
             AND TXN_CODE = P_TXN_CODE; 

      ELSE
	  
	     SELECT COUNT(*)
         INTO V_SAF_TXN_COUNT
         FROM VMSCMS_HISTORY.TRANSACTIONLOG_HIST              --Added for VMS-5739/FSP-991
         WHERE RRN = P_RRN AND BUSINESS_DATE = P_BUSINESS_DATE AND
             CUSTOMER_CARD_NO = V_HASH_PAN AND --INSTCODE = P_INST_CODE AND --For Instcode removal of 2.4.2.4.2 release
             RESPONSE_CODE = '00' AND MSGTYPE = '1420' 
             AND TXN_CODE = P_TXN_CODE; 
	  	  
	  END IF;
        IF V_SAF_TXN_COUNT > 0 THEN

         V_RESP_CDE := '52';
         V_ERRMSG   := 'Successful SAF Transaction has already done' ||
                    SUBSTR(SQLERRM, 1, 200);
         RAISE EXP_RVSL_REJECT_RECORD;

        END IF;

      END IF;


      IF P_MSG_TYP = '1421' OR P_MSG_TYP = '1420' AND V_CTM_PREAUTH_FLAG <>  'Y'  THEN  

        v_Retdate := TO_DATE(SUBSTR(TRIM(P_ORGNL_BUSINESS_DATE), 1, 8), 'yyyymmdd');  --Added for VMS-5739/FSP-991
		
	  IF (v_Retdate>v_Retperiod) THEN                        --Added for VMS-5739/FSP-991
	  
        SELECT COUNT(*)
         INTO V_SAF_TXN_COUNT
         FROM TRANSACTIONLOG
        WHERE ORIGINAL_STAN = P_ORGNL_STAN AND             
             ORGNL_BUSINESS_DATE = P_ORGNL_BUSINESS_DATE AND
             CUSTOMER_CARD_NO = V_HASH_PAN 
             --AND INSTCODE = P_INST_CODE AND --For Instcode removal of 2.4.2.4.2 release
             AND RESPONSE_CODE = '00' AND MSGTYPE IN ('1420', '1421')
             AND ORGNL_BUSINESS_TIME = P_ORGNL_BUSINESS_TIME;  
       ELSE

         SELECT COUNT(*)
         INTO V_SAF_TXN_COUNT
         FROM VMSCMS_HISTORY.TRANSACTIONLOG_HIST       --Added for VMS-5739/FSP-991
         WHERE ORIGINAL_STAN = P_ORGNL_STAN AND             
             ORGNL_BUSINESS_DATE = P_ORGNL_BUSINESS_DATE AND
             CUSTOMER_CARD_NO = V_HASH_PAN 
             --AND INSTCODE = P_INST_CODE AND --For Instcode removal of 2.4.2.4.2 release
             AND RESPONSE_CODE = '00' AND MSGTYPE IN ('1420', '1421')
             AND ORGNL_BUSINESS_TIME = P_ORGNL_BUSINESS_TIME; 

        END IF;	   

        IF V_SAF_TXN_COUNT > 0 THEN

         V_RESP_CDE := '155'; 
         V_ERRMSG   := 'Successful SAF Reversal Transaction has already done';
         
         RAISE EXP_RVSL_REJECT_RECORD;

        END IF;

      END IF;
       
 
     ------------------------------------------------------
        --En Added for Concurrent Processsing Issue
    ------------------------------------------------------    

     /*                                          -- SN:Query placed above acct_mast query so remove subquery   
       --Sn get the product code
      BEGIN

        SELECT CAP_PROD_CODE, CAP_CARD_TYPE,CAP_ACCT_NO,     --Added by Besky on 09-nov-12
               cap_card_stat,
               cap_prfl_code --Added on 04.04.2013 for MVHOST-298
         INTO V_PROD_CODE, V_CARD_TYPE,V_ACCT_NUMBER,   --Added by Besky on 09-nov-12
              v_cap_card_stat,
              v_prfl_code --Added on 04.04.2013 for MVHOST-298
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
    */                             -- EN:Query placed above acct_mast query so remove subquery  

  -- Check for maximum card balance configured for the product profile.
  BEGIN
    --Sn Added on 09-Feb-2013 for max card balance check based on product category
      SELECT TO_NUMBER (cbp_param_value)
        INTO v_max_card_bal
        FROM cms_bin_param
       WHERE cbp_inst_code = p_inst_code
         AND cbp_param_name = 'Max Card Balance'
         AND cbp_profile_code = v_profile_code;
    --En Added on 09-Feb-2013 for max card balance check based on product category
   --Sn Commented on 09-Feb-2013 for max card balance check based on product category
    /*SELECT TO_NUMBER(CBP_PARAM_VALUE)
     INTO V_MAX_CARD_BAL
     FROM CMS_BIN_PARAM
    WHERE CBP_INST_CODE = P_INST_CODE AND
         CBP_PARAM_NAME = 'Max Card Balance' AND
         CBP_PROFILE_CODE IN
         (SELECT CPM_PROFILE_CODE
            FROM CMS_PROD_MAST
           WHERE CPM_PROD_CODE = V_PROD_CODE);*/
    --En Commented on 09-Feb-2013 for max card balance check based on product category
  EXCEPTION
    WHEN OTHERS THEN
     V_RESP_CDE := '21';
     V_ERRMSG   := 'ERROR IN FETCHING CARD BALANCE CONFIGURATION FOR THE PRODUCT PROFILE ' ||
                SUBSTR(SQLERRM, 1, 200);
     RAISE EXP_RVSL_REJECT_RECORD;

  END;

  --Sn check balance

  IF ((V_ACCT_BALANCE + V_REVERSAL_AMT) > V_MAX_CARD_BAL) OR
    ((V_LEDGER_BAL + V_REVERSAL_AMT) > V_MAX_CARD_BAL) THEN
      IF v_cap_card_stat<>'12' THEN  --added for FSS-390

        BEGIN
          
            UPDATE CMS_APPL_PAN
              SET CAP_CARD_STAT = '12'
            WHERE CAP_PAN_CODE = V_HASH_PAN AND CAP_INST_CODE = P_INST_CODE;
                
            IF SQL%ROWCOUNT = 0 THEN

             V_ERRMSG   := 'Error while updating the card status';
             V_RESP_CDE := '21';
             RAISE EXP_RVSL_REJECT_RECORD;
            END IF;
            
        EXCEPTION WHEN EXP_RVSL_REJECT_RECORD   --SN Exception block added as per review observation for FSS-1246
        THEN  
            RAISE;
        
        WHEN OTHERS
        THEN
        V_RESP_CDE := '21';
        V_ERRMSG   := 'Error Occured While Updating Card Status In Pan Master'||
                SUBSTR(SQLERRM, 1, 200);
         RAISE EXP_RVSL_REJECT_RECORD;         
        
        END;                                    --EN Exception block added as per review observation for FSS-1246
        
        
        --Sn added for FSS-390
        v_chnge_crdstat:='Y';  
      END IF;
      --En added for FSS-390
  END IF;

  --En check balance**/


  IF V_DR_CR_FLAG = 'NA' THEN
    V_RESP_CDE := '21';
    V_ERRMSG   := 'Not a valid  transaction for reversal';
    RAISE EXP_RVSL_REJECT_RECORD;
  END IF;

  --Sn reverse the amount
  
  --Sn - commeneted for fwr-48

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
  
  --En - commeneted for fwr-48

  --Sn update the amount

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

  BEGIN
    SELECT CAM_ACCT_NO
     INTO V_CARD_ACCT_NO
     FROM CMS_ACCT_MAST
    WHERE CAM_ACCT_NO = V_ACCT_NUMBER           --V_ACCT_NUMBER Added instead of subquery
  --         (SELECT CAP_ACCT_NO
  --             FROM CMS_APPL_PAN
  --           WHERE CAP_PAN_CODE = V_HASH_PAN AND CAP_MBR_NUMB = P_MBR_NUMB AND
  --                CAP_INST_CODE = P_INST_CODE) 
    AND  CAM_INST_CODE = P_INST_CODE;
      --FOR UPDATE NOWAIT;                                                        -- Commented for Concurrent Processsing Issue
  EXCEPTION
    WHEN NO_DATA_FOUND THEN
     V_RESP_CDE := '14'; --Ineligible Transaction
     V_ERRMSG   := 'Invalid Card ';
     RAISE EXP_RVSL_REJECT_RECORD;
    WHEN OTHERS THEN
     V_RESP_CDE := '12';
     V_ERRMSG   := 'Error while selecting data from card Master for card number ' ||
                P_CARD_NO;
     RAISE EXP_RVSL_REJECT_RECORD;
  END;

  --Sn find narration

  BEGIN
  
    --Added for VMS-5739/FSP-991
       select (add_months(trunc(sysdate,'MM'),'-'||RETENTION_PERIOD))
       INTO   v_Retperiod 
       FROM DBA_OPERATIONS.ARCHIVE_MGMNT_CTL  
       WHERE  OPERATION_TYPE='ARCHIVE' 
       AND OBJECT_NAME='CMS_STATEMENTS_LOG_EBR';
       
       v_Retdate := TO_DATE(SUBSTR(TRIM(P_ORGNL_BUSINESS_DATE), 1, 8), 'yyyymmdd');
	   
	IF (v_Retdate>v_Retperiod)                                           --Added for VMS-5739/FSP-991
    THEN
	
      SELECT CSL_TRANS_NARRRATION,
         CSL_MERCHANT_NAME,
         CSL_MERCHANT_CITY,
         CSL_MERCHANT_STATE
      INTO V_TXN_NARRATION,
         V_TXN_MERCHNAME,
         V_TXN_MERCHCITY,
         V_TXN_MERCHSTATE --Mofified by Deepa on 09-May-2012 to include Merchant name,city and state in statements log
      FROM CMS_STATEMENTS_LOG
      WHERE CSL_BUSINESS_DATE = V_ORGNL_BUSINESS_DATE AND
         CSL_BUSINESS_TIME = V_ORGNL_BUSINESS_TIME AND
         CSL_RRN = V_ORGNL_RRN  AND --P_ORGNL_RRN    --OLS CHANGES on 13062013 
         CSL_DELIVERY_CHANNEL = V_ORGNL_DELIVERY_CHANNEL AND
         CSL_TXN_CODE = V_ORGNL_TXN_CODE AND
         CSL_PAN_NO = V_ORGNL_CUSTOMER_CARD_NO AND
         CSL_INST_CODE = P_INST_CODE AND TXN_FEE_FLAG = 'N';
		 
	ELSE
	
	     SELECT CSL_TRANS_NARRRATION,
         CSL_MERCHANT_NAME,
         CSL_MERCHANT_CITY,
         CSL_MERCHANT_STATE
      INTO V_TXN_NARRATION,
         V_TXN_MERCHNAME,
         V_TXN_MERCHCITY,
         V_TXN_MERCHSTATE --Mofified by Deepa on 09-May-2012 to include Merchant name,city and state in statements log
      FROM VMSCMS_HISTORY.cms_statements_log_HIST                                  --Added for VMS-5739/FSP-991
      WHERE CSL_BUSINESS_DATE = V_ORGNL_BUSINESS_DATE AND
         CSL_BUSINESS_TIME = V_ORGNL_BUSINESS_TIME AND
         CSL_RRN = V_ORGNL_RRN  AND --P_ORGNL_RRN    --OLS CHANGES on 13062013 
         CSL_DELIVERY_CHANNEL = V_ORGNL_DELIVERY_CHANNEL AND
         CSL_TXN_CODE = V_ORGNL_TXN_CODE AND
         CSL_PAN_NO = V_ORGNL_CUSTOMER_CARD_NO AND
         CSL_INST_CODE = P_INST_CODE AND TXN_FEE_FLAG = 'N';
	
	
	
	
	
	
	END IF;

  EXCEPTION
    WHEN NO_DATA_FOUND THEN
     V_TXN_NARRATION := V_TRAN_DESC;  --OLS CHANGES on 13062013 
    WHEN OTHERS THEN
     V_TXN_NARRATION := V_TRAN_DESC;   --OLS CHANGES on 13062013 

  END;

  --En find narration
 -- v_timestamp:=systimestamp; --added by Pankaj S. for 10871
  --Sn reverse  the amount

  BEGIN
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
                      V_REVERSAL_AMT,
                      --P_ORGNL_RRN,  --OLS CHANGES on 13062013 
                      V_ORGNL_RRN,
                      V_CARD_ACCT_NO,
                      P_BUSINESS_DATE,
                      P_BUSINESS_TIME,
                      V_AUTH_ID,
                      V_TXN_NARRATION,
                      P_ORGNL_BUSINESS_DATE,
                      P_ORGNL_BUSINESS_TIME,
                      V_TXN_MERCHNAME, --Added by Deepa on 09-May-2012 to include Merchant name,city and state in statements log
                      V_TXN_MERCHCITY,
                      V_TXN_MERCHSTATE,
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
     V_ERRMSG   := 'Error while reversing the amount ' ||
                SUBSTR(SQLERRM, 1, 200);
     RAISE EXP_RVSL_REJECT_RECORD;
  END;
  --En reverse the amount
  --Added by Deepa For Reversal Fees on June 27 2012
  IF V_REVERSAL_AMT_FLAG <>'P' THEN   --Modified For Mantis Id-0010997
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
                        --  P_ORGNL_RRN,
                          V_ORGNL_RRN,         --OLS CHANGES on 13062013 
                          V_CARD_ACCT_NO,
                          P_BUSINESS_DATE,
                          P_BUSINESS_TIME,
                          V_AUTH_ID,
                          C1.CSL_TRANS_NARRRATION,
                          C1.CSL_MERCHANT_NAME,
                          C1.CSL_MERCHANT_CITY,
                          C1.CSL_MERCHANT_STATE,
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
                       --P_ORGNL_RRN,
                        V_ORGNL_RRN,  --OLS CHANGES on 13062013 
                       V_CARD_ACCT_NO,
                       P_BUSINESS_DATE,
                       P_BUSINESS_TIME,
                       V_AUTH_ID,
                       V_FEE_NARRATION,
                       V_FEE_MERCHNAME,
                       V_FEE_MERCHCITY,
                       V_FEE_MERCHSTATE,
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
  END IF; ----Added For Mantis-Id-0010997

  --En reverse the fee

  IF V_GL_UPD_FLAG = 'Y' THEN

    --Sn find business date
    V_BUSINESS_TIME := TO_CHAR(V_RVSL_TRANDATE, 'HH24:MI');
    IF V_BUSINESS_TIME > V_CUTOFF_TIME THEN
     V_RVSL_TRANDATE := TRUNC(V_RVSL_TRANDATE) + 1;
    ELSE
     V_RVSL_TRANDATE := TRUNC(V_RVSL_TRANDATE);
    END IF;
    --En find businesses date
    
    --Sn - commeneted for fwr-48

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
    END IF; */
    
    --En - commeneted for fwr-48

  END IF;
  --En reverse the GL entries

  --Added by Deepa for Narration of Reversal Txn Fee

  IF V_TXN_NARRATION IS NULL THEN

    IF TRIM(V_TRAN_DESC) IS NOT NULL THEN

     V_TXN_NARRATION := V_TRAN_DESC || '/';

    END IF;

    IF TRIM(V_TXN_MERCHNAME) IS NOT NULL THEN

     V_TXN_NARRATION := V_TXN_NARRATION || V_TXN_MERCHNAME || '/';

    END IF;
    
     -- Changed for FSS-4119
    IF TRIM(P_TERMINAL_ID) IS NOT NULL THEN

     V_TXN_NARRATION := V_TXN_NARRATION || P_TERMINAL_ID || '/';

    END IF;   
    
    IF TRIM(V_TXN_MERCHCITY) IS NOT NULL THEN

     V_TXN_NARRATION := V_TXN_NARRATION || V_TXN_MERCHCITY || '/';

    END IF;    

    IF TRIM(P_BUSINESS_DATE) IS NOT NULL THEN

     V_TXN_NARRATION := V_TXN_NARRATION || P_BUSINESS_DATE || '/';

    END IF;

    IF TRIM(V_AUTH_ID) IS NOT NULL THEN

     V_TXN_NARRATION := V_TXN_NARRATION || V_AUTH_ID;

    END IF;

  END IF;

  V_RESP_CDE := '1';
  --Added by Deepa on June 26 2012 for Reversal Fee Calculation


 IF P_DELV_CHNL = '01' THEN
        BEGIN
             
           SELECT COUNT(*) 
          INTO V_NETWORKIDCOUNT
          FROM CMS_PROD_CATTYPE prodCat,
          VMS_PRODCAT_NETWORKID_MAPPING MAPP
          WHERE prodCat.CPC_INST_CODE=MAPP.VPN_INST_CODE
          AND prodCat.CPC_INST_CODE=p_inst_code
          AND prodCat.CPC_NETWORKACQID_FLAG='Y'
          and prodCat.CPC_PROD_CODE=MAPP.VPN_PROD_CODE
          and upper(MAPP.VPN_NETWORK_ID)=UPPER(p_networkid_acquirer)
		  AND prodCat.CPC_CARD_TYPE= v_card_type
		  AND prodCat.CPC_CARD_TYPE= MAPP.VPN_CARD_TYPE
          and MAPP.VPN_PROD_CODE=v_prod_code;
        
        EXCEPTION 
        WHEN OTHERS THEN
         V_RESP_CDE := '21';
            v_ERRMSG :=
                'Error while selecting product network id ' || SUBSTR (SQLERRM, 1, 200);
            RAISE EXP_RVSL_REJECT_RECORD;
        
        END;
      
      END IF;
      
                --SN Added by Pankaj S. for DB time logging changes
    SELECT (  EXTRACT (DAY FROM SYSTIMESTAMP - v_start_time) * 86400
            + EXTRACT (HOUR FROM SYSTIMESTAMP - v_start_time) * 3600
            + EXTRACT (MINUTE FROM SYSTIMESTAMP - v_start_time) * 60
            + EXTRACT (SECOND FROM SYSTIMESTAMP - v_start_time) * 1000)
      INTO v_mili
      FROM DUAL;
      
    P_RESPTIME_DETAIL :=  P_RESPTIME_DETAIL || ' 2: ' || v_mili ;
    --EN Added by Pankaj S. for DB time logging changes
     
     IF V_NETWORKIDCOUNT <> 1 THEN
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
                     V_TXN_MERCHNAME,
                     V_TXN_MERCHCITY,
                     V_AUTH_ID,
                     V_FEE_MERCHSTATE,
                     P_RVSL_CODE,
                     V_TXN_NARRATION,
                     V_TXN_TYPE,
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
  ELSE
      V_FEE_AMT :=0;
  END IF;

  --En reversal Fee Calculation
  
  --Sn added by Pankaj S. for 10871
     BEGIN
	 
	    --Added for VMS-5739/FSP-991
       select (add_months(trunc(sysdate,'MM'),'-'||RETENTION_PERIOD))
       INTO   v_Retperiod 
       FROM DBA_OPERATIONS.ARCHIVE_MGMNT_CTL  
       WHERE  OPERATION_TYPE='ARCHIVE' 
       AND OBJECT_NAME='CMS_STATEMENTS_LOG_EBR';
       
       v_Retdate := TO_DATE(SUBSTR(TRIM(p_business_date), 1, 8), 'yyyymmdd');
	
	IF (v_Retdate>v_Retperiod)                                                --Added for VMS-5739/FSP-991      
    THEN
	   
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
		   
	ELSE
	    
		   UPDATE VMSCMS_HISTORY.cms_statements_log_HIST                 --Added for VMS-5739/FSP-991                  
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
	
	END IF;
	
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
       v_resp_cde := '1';
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
        CTD_MERCHANT_ZIP,CTD_INTERNATION_IND_RESPONSE
        ,CTD_PULSE_TRANSACTIONID,CTD_VISA_TRANSACTIONID,CTD_MC_TRACEID,
        CTD_CARDVERIFICATION_RESULT
        /* End Added by Dhiraj G on 31052012 for Pre - Auth Parameter changes  */
        ,CTD_MERCHANT_ID,CTD_COUNTRY_CODE,CTD_PAYMENT_TYPE,ctd_hashkey_id
        )
     VALUES
       (P_DELV_CHNL,
        P_TXN_CODE,
        -- P_TXN_TYPE,
        V_TXN_TYPE, --Modified by Deepa on June 26 2012 As the value is passed as NULL
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
        P_MERCHANT_ZIP,v_internation_ind_response
        , P_PULSE_TRANSACTIONID,--Added for MVHOST 926
        P_VISA_TRANSACTIONID,--Added for MVHOST 926
        P_MC_TRACEID,--Added for MVHOST 926
        P_CARDVERIFICATION_RESULT--Added for MVHOST 926
        /* End  Added by Dhiraj G on 31052012 for Pre - Auth Parameter changes  */
        ,P_MERCHANT_ID,P_MERCHANT_CNTRYCODE,P_MS_PYMNT_DESC,V_HASHKEY_ID
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

    --En to Get the Account balance
    BEGIN
     SELECT CAM_ACCT_BAL, CAM_LEDGER_BAL
       INTO V_ACCT_BALANCE, V_LEDGER_BAL
       FROM CMS_ACCT_MAST
      WHERE CAM_ACCT_NO =V_ACCT_NUMBER
           /*(SELECT CAP_ACCT_NO
             FROM CMS_APPL_PAN
            WHERE CAP_PAN_CODE = V_HASH_PAN AND
                 CAP_INST_CODE = P_INST_CODE)*/ AND
           CAM_INST_CODE = P_INST_CODE;
    EXCEPTION
     WHEN OTHERS THEN
       V_ACCT_BALANCE  := 0;
       V_LEDGER_BAL := 0;
    END;
    
  --En create a entry for successful

  --Sn generate response code

  -- V_RESP_CDE := '1';
  P_RESP_ID := V_RESP_CDE; --Added for VMS-8018
  BEGIN
    SELECT CMS_B24_RESPCDE, --Changed  CMS_ISO_RESPCDE to  CMS_B24_RESPCDE for HISO SPECIFIC Response codes
     cms_iso_respcde    --OLS CHANGES on 13062013 
     INTO P_RESP_CDE,
     --V_CMS_ISO_RESPCODE
          P_ISO_RESPCDE --Commented and replaced  on 18.07.2013 for the Mantis ID 11612
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
      MERCHANT_STATE, -- Added FOR MERCHANT DETAILS LOGGED IN TRANSACTIONLOG TABLE on 07-Sep-2012
      --Sn added by Pankaj S. fro 10871
      cr_dr_flag,
      cardstatus,
      acct_type,
      error_msg,
      time_stamp,
      --En added by Pankaj S. fro 10871
      ORIGINAL_STAN,
      NETWORKID_SWITCH, --Added on 20130626 for the Mantis ID 11344
      NETWORKID_ACQUIRER, --Added on 20130626 for the Mantis ID 11344
      NETWORK_SETTL_DATE, --Added on 20130626 for the Mantis ID 11123
      CVV_VERIFICATIONTYPE  --Added on 18.07.2013 for the Mantis ID 11611
      ,INTERNATION_IND_RESPONSE   
      ,merchant_id
      )
    VALUES
     (P_MSG_TYP,
      P_RRN,
      P_DELV_CHNL,
      P_TERMINAL_ID,
      V_RVSL_TRANDATE,
      P_TXN_CODE,
      -- P_TXN_TYPE,
      V_TXN_TYPE, --Modified by Deepa on June 26 2012 As the value is passed as NULL
      P_TXN_MODE,
      --DECODE(V_CMS_ISO_RESPCODE, '00', 'C', 'F'),
      DECODE(P_ISO_RESPCDE , '00', 'C', 'F'),--Commented and replaced  on 18.07.2013 for the Mantis ID 11612
      --V_CMS_ISO_RESPCODE,
      P_ISO_RESPCDE , --Commented and replaced  on 18.07.2013 for the Mantis ID 11612
      P_BUSINESS_DATE,
      SUBSTR(P_BUSINESS_TIME, 1, 6),
      V_HASH_PAN,
      NULL,
      NULL, --P_topup_acctno    ,
      NULL, --P_topup_accttype,
      P_INST_CODE,
      TRIM(TO_CHAR(V_REVERSAL_AMT, '999999999999999990.99')) --formatted for 10871
      -- reversal amount will be passed in the table as the same is used in the recon report.
     ,
      NULL,
      NULL,
      P_MERC_ID,
      V_CURR_CODE,
      V_PROD_CODE,
      V_CARD_TYPE,
--      0,
      nvl(V_FEE_AMT,0), -- Added on 19.07.2013 for the Mantis ID 11613
      '0.00', --modified for 10871
      NULL,
      NULL,
      V_AUTH_ID,
    --  'RVSL-'|| --commented for Mantis id 13406 on 17.1.2014
      V_TRAN_DESC,
      TRIM(TO_CHAR(V_REVERSAL_AMT, '999999999999999990.99')), -- reversal amount will be passed in the table as the same is used in the recon report.
      P_MERCHANT_CNTRYCODE, --modified for 10871 --- PRE AUTH AMOUNT
      '0.00', --modified for 10871 -- Partial amount (will be given for partial txn)
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
      --P_ORGNL_RRN,
      V_ORGNL_RRN,
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
      V_TXN_MERCHNAME, -- Added FOR MERCJANT DETAILS LOGGED IN TRANSACTIONLOG TABLE on 07-Sep-2012
      V_TXN_MERCHCITY, -- Added FOR MERCJANT DETAILS LOGGED IN TRANSACTIONLOG TABLE on 07-Sep-2012
      V_TXN_MERCHSTATE, -- Added FOR MERCJANT DETAILS LOGGED IN TRANSACTIONLOG TABLE on 07-Sep-2012
      --Sn added by Pankaj S. for 10871
      decode(v_dr_cr_flag,'CR','DR','DR','CR',v_dr_cr_flag),
      v_cap_card_stat,
      v_acct_type,
      v_errmsg,
      v_timestamp,
      --En added by Pankaj S. for 10871
      P_ORGNL_STAN, --OLS CHANGES on 13062013 
      P_NETWORKID_SWITCH , --Added on 20130626 for the Mantis ID 11344
      P_NETWORKID_ACQUIRER,-- Added on 20130626 for the Mantis ID 11344
      p_network_setl_date,  --Added on 20130626 for the Mantis ID 11123
      NVL(P_CVV_VERIFICATIONTYPE,'N')  --Added on 18.07.2013 for the Mantis ID 11611
      ,v_internation_ind_response 
      ,P_MERCHANT_ID
      );

    BEGIN
	
	   --Added for VMS-5739/FSP-991
       select (add_months(trunc(sysdate,'MM'),'-'||RETENTION_PERIOD))
       INTO   v_Retperiod 
       FROM DBA_OPERATIONS.ARCHIVE_MGMNT_CTL  
       WHERE  OPERATION_TYPE='ARCHIVE' 
       AND OBJECT_NAME='TRANSACTIONLOG_EBR';
       
       v_Retdate := TO_DATE(SUBSTR(TRIM(P_ORGNL_BUSINESS_DATE), 1, 8), 'yyyymmdd');
	   
	IF (v_Retdate>v_Retperiod)                                                         --Added for VMS-5739/FSP-991
    THEN

      UPDATE TRANSACTIONLOG
        SET TRAN_REVERSE_FLAG = 'Y'
      WHERE RRN = V_ORGNL_RRN AND BUSINESS_DATE = P_ORGNL_BUSINESS_DATE AND
           BUSINESS_TIME = P_ORGNL_BUSINESS_TIME AND
           CUSTOMER_CARD_NO = V_HASH_PAN AND INSTCODE = P_INST_CODE AND
           SYSTEM_TRACE_AUDIT_NO=P_ORGNL_STAN   --OLS CHANGES on 13062013
            AND NVL(TRAN_REVERSE_FLAG,'N') <> 'Y'; -- duplicate reversal fix
          -- TERMINAL_ID = P_ORGNL_TERMINAL_ID;
		  
	ELSE
	  
	    UPDATE VMSCMS_HISTORY.TRANSACTIONLOG_HIST                     --Added for VMS-5739/FSP-991
        SET TRAN_REVERSE_FLAG = 'Y'
        WHERE RRN = V_ORGNL_RRN AND BUSINESS_DATE = P_ORGNL_BUSINESS_DATE AND
           BUSINESS_TIME = P_ORGNL_BUSINESS_TIME AND
           CUSTOMER_CARD_NO = V_HASH_PAN AND INSTCODE = P_INST_CODE AND
           SYSTEM_TRACE_AUDIT_NO=P_ORGNL_STAN   --OLS CHANGES on 13062013
            AND NVL(TRAN_REVERSE_FLAG,'N') <> 'Y'; -- duplicate reversal fix
          -- TERMINAL_ID = P_ORGNL_TERMINAL_ID;
		
	END IF;

     IF SQL%ROWCOUNT = 0 THEN
      --OLS CHANGES on 13062013 
       --IF P_MSG_TYP NOT IN ('1420', '1421') THEN
       -- V_RESP_CDE := '21';
        --V_ERRMSG   := 'Reverse flag is not updated ';
         V_RESP_CDE := '52';
          V_ERRMSG   := 'The reversal already done for the orginal transaction';
        RAISE EXP_RVSL_REJECT_RECORD;
       --END IF;
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
    
    
      /*                                --Sn:Commented as per review observation for FSS-1246 
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
           V_ERRMSG   := 'Error while selecting 1 CMS_TRANSLIMIT_CHECK' ||
                      SUBSTR(SQLERRM, 1, 200);
           V_RESP_CDE := '21';
           RAISE EXP_RVSL_REJECT_RECORD;
        END;

        BEGIN

         --Sn Limit and amount check for ATM
         IF P_DELV_CHNL = '01' THEN

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

            IF SQL%ROWCOUNT = 0 THEN
              V_ERRMSG   := 'Problem while updating data in CMS_TRANSLIMIT_CHECK';
              V_RESP_CDE := '21';
              RAISE EXP_RVSL_REJECT_RECORD;
            END IF;

           ELSE
            IF P_ORGNL_BUSINESS_DATE = P_BUSINESS_DATE THEN

              IF V_REVERSAL_AMT IS NULL THEN
                V_ATM_USAGEAMNT := V_ATM_USAGEAMNT;
              ELSE
                V_ATM_USAGEAMNT := V_ATM_USAGEAMNT -
                               TRIM(TO_CHAR(V_REVERSAL_AMT,
                                         '999999999999.99'));
              END IF;

              UPDATE CMS_TRANSLIMIT_CHECK
                SET CTC_POSUSAGE_AMT = V_ATM_USAGEAMNT
               WHERE CTC_INST_CODE = P_INST_CODE AND
                    CTC_PAN_CODE = V_HASH_PAN AND CTC_MBR_NUMB = P_MBR_NUMB;

              IF SQL%ROWCOUNT = 0 THEN
                V_ERRMSG   := 'Problem while updating data in CMS_TRANSLIMIT_CHECK' ||
                           SUBSTR(SQLERRM, 1, 300);
                V_RESP_CDE := '21';
                RAISE EXP_RVSL_REJECT_RECORD;
              END IF;

            END IF;
           END IF;
         END IF;
         --En Limit and amount check for ATM

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

            IF SQL%ROWCOUNT = 0 THEN
              V_ERRMSG   := 'Problem while updating data in CMS_TRANSLIMIT_CHECK' ||
                         SUBSTR(SQLERRM, 1, 300);
              V_RESP_CDE := '21';
              RAISE EXP_RVSL_REJECT_RECORD;
            END IF;

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

              IF SQL%ROWCOUNT = 0 THEN
                V_ERRMSG   := 'Problem while updating data in CMS_TRANSLIMIT_CHECK' ||
                           SUBSTR(SQLERRM, 1, 300);
                V_RESP_CDE := '21';
                RAISE EXP_RVSL_REJECT_RECORD;
              END IF;

            END IF;
           END IF;
         END IF;

         --En Limit and amount check for POS

         --Sn Limit and amount check for MMPOS

         IF P_DELV_CHNL = '04' THEN

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

            IF SQL%ROWCOUNT = 0 THEN
              V_ERRMSG   := 'Problem while updating data in CMS_TRANSLIMIT_CHECK' ||
                         SUBSTR(SQLERRM, 1, 300);
              V_RESP_CDE := '21';
              RAISE EXP_RVSL_REJECT_RECORD;
            END IF;

           ELSE
            IF P_ORGNL_BUSINESS_DATE = P_BUSINESS_DATE THEN

              IF V_REVERSAL_AMT IS NULL THEN
                V_MMPOS_USAGEAMNT := V_MMPOS_USAGEAMNT;

              ELSE

                IF V_DR_CR_FLAG = 'CR' THEN

                 V_MMPOS_USAGEAMNT := V_MMPOS_USAGEAMNT;
                ELSE
                 V_MMPOS_USAGEAMNT := V_MMPOS_USAGEAMNT -
                                  TRIM(TO_CHAR(V_REVERSAL_AMT,
                                            '999999999999.99'));
                END IF;

              END IF;

              UPDATE CMS_TRANSLIMIT_CHECK
                SET CTC_POSUSAGE_AMT = V_MMPOS_USAGEAMNT
               WHERE CTC_INST_CODE = P_INST_CODE AND
                    CTC_PAN_CODE = V_HASH_PAN AND CTC_MBR_NUMB = P_MBR_NUMB;

              IF SQL%ROWCOUNT = 0 THEN
                V_ERRMSG   := 'Problem while updating data in CMS_TRANSLIMIT_CHECK' ||
                           SUBSTR(SQLERRM, 1, 300);
                V_RESP_CDE := '21';
                RAISE EXP_RVSL_REJECT_RECORD;
              END IF;

            END IF;
           END IF;
         END IF;

         --En Limit and amount check for MMPOS
        EXCEPTION
         WHEN OTHERS THEN
           V_ERRMSG   := 'Error while updating 1 CMS_TRANSLIMIT_CHECK' ||
                      SUBSTR(SQLERRM, 1, 200);
           V_RESP_CDE := '21';
           RAISE EXP_RVSL_REJECT_RECORD;
        END;
       */                               --En:Commented as per review observation for FSS-1246
     

    IF V_ERRMSG = 'OK' THEN

     --Sn find prod code and card type and available balance for the card number
     BEGIN
       SELECT CAM_ACCT_BAL, CAM_LEDGER_BAL
        INTO V_ACCT_BALANCE, V_LEDGER_BAL
        FROM CMS_ACCT_MAST
        WHERE CAM_ACCT_NO =V_ACCT_NUMBER
           /* (SELECT CAP_ACCT_NO
               FROM CMS_APPL_PAN
              WHERE CAP_PAN_CODE = V_HASH_PAN AND
                   CAP_MBR_NUMB = P_MBR_NUMB AND
                   CAP_INST_CODE = P_INST_CODE)*/ AND
            CAM_INST_CODE = P_INST_CODE;
         --FOR UPDATE NOWAIT;                                                        -- Commented for Concurrent Processsing Issue
     EXCEPTION
       WHEN NO_DATA_FOUND THEN
        V_RESP_CDE := '14'; --Ineligible Transaction
        V_ERRMSG   := 'Invalid Card ';
        RAISE EXP_RVSL_REJECT_RECORD;
       WHEN OTHERS THEN
        V_RESP_CDE := '12';
        V_ERRMSG   := 'Error while selecting data from card Master for card number ' ||
                    SQLERRM;
        RAISE EXP_RVSL_REJECT_RECORD;
     END;

     --En find prod code and card type for the card number
     P_RESP_MSG := TO_CHAR(V_ACCT_BALANCE);
     P_LEDGER_BAL := TO_CHAR(V_LEDGER_BAL);  --OLS CHANGES on 13062013 
     P_AUTH_ID    := V_AUTH_ID; 

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
  
        --SN Added by Pankaj S. for DB time logging changes
    SELECT (  EXTRACT (DAY FROM SYSTIMESTAMP - v_start_time) * 86400
            + EXTRACT (HOUR FROM SYSTIMESTAMP - v_start_time) * 3600
            + EXTRACT (MINUTE FROM SYSTIMESTAMP - v_start_time) * 60
            + EXTRACT (SECOND FROM SYSTIMESTAMP - v_start_time) * 1000)
      INTO v_mili
      FROM DUAL;
      
    P_RESPTIME_DETAIL :=  P_RESPTIME_DETAIL || ' 3: ' || v_mili ;
    --EN Added by Pankaj S. for DB time logging changes
    
      IF v_orgnl_txn_totalfee_amt=0 AND v_orgnl_txn_feecode IS NOT NULL AND v_reversal_amt_flag='F' THEN
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

   --SN Added on 04.04.2013 for MVHOST-298
   BEGIN
         IF v_add_ins_date is not null and  v_prfl_code IS NOT NULL AND v_prfl_flag = 'Y'
         and V_ORGN_FOUND = 1
         THEN
         
         SELECT DECODE(V_ORGNL_TOTAL_AMOUNT,NULL,V_REVERSAL_AMT,V_ORGNL_TOTAL_AMOUNT)
         INTO V_ORGNL_AMNT
         from dual;
         
               pkg_limits_check.sp_limitcnt_rever_reset
                              (P_INST_CODE,
                                null,
                                null,
                                V_ORGNL_MCCCODE,
                                P_TXN_CODE,
                                V_TRAN_TYPE,
                                case when p_delv_chnl ='02' and (p_txn_code ='25' or p_txn_code ='35' or p_txn_code ='37') -- Case added for  defect
                                then null else V_INTERNATION_IND_RESPONSE end,
                                case when p_delv_chnl ='02' and (p_txn_code ='25' or p_txn_code ='35' or p_txn_code ='37') -- Case added for  defect
                                then null else v_pos_verification end,
                                v_prfl_code,                              
                                V_REVERSAL_AMT  ,
                                V_ORGNL_AMNT,                             
                                P_DELV_CHNL,
                                v_hash_pan,
                                v_add_ins_date,
                                V_RESP_CDE,
                                V_ERRMSG,
                               V_MS_PYMNT_TYPE 
                              );      


         END IF;

         IF V_ERRMSG <> 'OK'
         THEN            
            V_ERRMSG := V_ERRMSG;   
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
                'Error from Limit count reveer Process ' || SUBSTR (SQLERRM, 1, 200);
            RAISE EXP_RVSL_REJECT_RECORD;
   END;
  --EN Added on 04.04.2013 for MVHOST-298
     P_REVERSAL_AMOUNT := V_REVERSAL_AMT ;--Added  for  Mantis ID 13785 for To return the reversal amount on 21/03/201
     
         --SN Added by Pankaj S. for DB time logging changes
    SELECT (  EXTRACT (DAY FROM SYSTIMESTAMP - v_start_time) * 86400
            + EXTRACT (HOUR FROM SYSTIMESTAMP - v_start_time) * 3600
            + EXTRACT (MINUTE FROM SYSTIMESTAMP - v_start_time) * 60
            + EXTRACT (SECOND FROM SYSTIMESTAMP - v_start_time) * 1000)
      INTO v_mili
      FROM DUAL;
      
    P_RESPTIME_DETAIL :=  P_RESPTIME_DETAIL || ' 4: ' || v_mili ;
     P_RESP_TIME := v_mili;
    --EN Added by Pankaj S. for DB time logging changes

EXCEPTION
  -- << MAIN EXCEPTION>>
  WHEN EXP_RVSL_REJECT_RECORD THEN
    ROLLBACK TO V_SAVEPOINT;
     --SN Commented here & used below by Pankaj S. for PERF changes
    /*BEGIN
     SELECT CAM_ACCT_BAL, CAM_LEDGER_BAL,
            cam_type_code  --added by Pankaj S. for 10871
       INTO V_ACCT_BALANCE, V_LEDGER_BAL,
            v_acct_type  --added by Pankaj S. for 10871
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
    END;*/
     --EN Commented here & used below by Pankaj S. for PERF changes
    BEGIN
     SELECT CMS_B24_RESPCDE,CMS_ISO_RESPCDE --Changed  CMS_ISO_RESPCDE to  CMS_B24_RESPCDE for HISO SPECIFIC Response codes
       INTO P_RESP_CDE,
       --V_CMS_ISO_RESPCODE
            P_ISO_RESPCDE --Commented and replaced  on 18.07.2013 for the Mantis ID 11612
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
       P_RESP_CDE := '89';
       P_RESP_ID  := '89'; --Added for VMS-8018
    END;

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
      WHERE CTC_PAN_CODE = TRIM(V_HASH_PAN) AND
           CTC_INST_CODE = P_INST_CODE AND
           CTC_MBR_NUMB = TRIM(P_MBR_NUMB);
    EXCEPTION
     WHEN NO_DATA_FOUND THEN
       V_ERRMSG   := 'Cannot get the Transaction Limit Details of the Card' ||
                  V_RESP_CDE || SUBSTR(SQLERRM, 1, 300);
       V_RESP_CDE := '21';
       RAISE EXP_RVSL_REJECT_RECORD;
     WHEN OTHERS THEN
       V_ERRMSG   := 'Error while selecting 2 CMS_TRANSLIMIT_CHECK' ||
                  SUBSTR(SQLERRM, 1, 200);
       V_RESP_CDE := '21';
       RAISE EXP_RVSL_REJECT_RECORD;
    END;
   */                --En:Commented as per review observation for FSS-1246

   /*               --Sn:Commented as per review observation for FSS-1246 
    BEGIN

     --Sn limit update for ATM

     IF P_DELV_CHNL = '01' THEN

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

        IF SQL%ROWCOUNT = 0 THEN
          V_ERRMSG   := 'Problem while updating data in CMS_TRANSLIMIT_CHECK' ||
                     SUBSTR(SQLERRM, 1, 300);
          V_RESP_CDE := '21';
          RAISE EXP_RVSL_REJECT_RECORD;
        END IF;

       END IF;
     END IF;

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

        IF SQL%ROWCOUNT = 0 THEN
          V_ERRMSG   := 'Problem while updating data in CMS_TRANSLIMIT_CHECK' ||
                     SUBSTR(SQLERRM, 1, 300);
          V_RESP_CDE := '21';
          RAISE EXP_RVSL_REJECT_RECORD;
        END IF;

       END IF;
     END IF;

     --Sn limit update for MMPOS
     IF P_DELV_CHNL = '04' THEN

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

        IF SQL%ROWCOUNT = 0 THEN
          V_ERRMSG   := 'Problem while updating data in CMS_TRANSLIMIT_CHECK' ||
                     SUBSTR(SQLERRM, 1, 300);
          V_RESP_CDE := '21';
          RAISE EXP_RVSL_REJECT_RECORD;
        END IF;

       END IF;
     END IF;
    EXCEPTION
     WHEN OTHERS THEN
       V_ERRMSG   := 'Error while updating 2 CMS_TRANSLIMIT_CHECK' ||
                  SUBSTR(SQLERRM, 1, 200);
       V_RESP_CDE := '21';
       RAISE EXP_RVSL_REJECT_RECORD;
    END;
   */                --En:Commented as per review observation for FSS-1246 
    
       --Sn added by Pankaj S. for 10871 
      IF v_dr_cr_flag IS NULL THEN
      BEGIN  
        select  CTM_CREDIT_DEBIT_FLAG,CTM_TRAN_DESC,
                to_number(decode(ctm_tran_type, 'N', '0', 'F', '1')),CTM_PREAUTH_TYPE
          INTO v_dr_cr_flag, v_tran_desc, v_txn_type,V_PREAUTH_TYPE
          FROM cms_transaction_mast
         WHERE ctm_tran_code = p_txn_code
           AND ctm_delivery_channel = p_delv_chnl
           AND ctm_inst_code = p_inst_code;                    
      EXCEPTION
         WHEN OTHERS THEN
            NULL;
      END;
        IF V_MS_PYMNT_TYPE        IS NOT NULL THEN
  IF( V_PREAUTH_TYPE       ='D') THEN
    IF( v_org_msgtype     IS NOT NULL) THEN
      IF (V_ORG_MSGTYPE   IN ('1220','1221')) THEN
        V_TRAN_DESC      :='MoneySend Funding Settlement';
      elsif v_org_msgtype IN ('1200','1201') THEN
        V_TRAN_DESC      :='MoneySend Funding';
      END IF;
    ELSE
      V_TRAN_DESC :='MoneySend Funding Settlement';
    END IF;
  ELSIF ( V_PREAUTH_TYPE ='C') THEN
    IF( v_org_msgtype   IS NOT NULL) THEN
      IF (v_org_msgtype IN ('1200','1201')) THEN
        V_TRAN_DESC    :='MoneySend Payment';
      END IF;
    END IF;
  end if;
END IF; 
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
     SELECT CAM_ACCT_BAL, CAM_LEDGER_BAL,
            cam_type_code  --added by Pankaj S. for 10871
       INTO V_ACCT_BALANCE, V_LEDGER_BAL,
            v_acct_type  --added by Pankaj S. for 10871
       FROM CMS_ACCT_MAST
      WHERE CAM_ACCT_NO =v_acct_number
         AND CAM_INST_CODE = P_INST_CODE;
    EXCEPTION
     WHEN OTHERS THEN
       V_ACCT_BALANCE := 0;
       V_LEDGER_BAL   := 0;
    END;

    --Sn create a entry in txn log
    IF V_RESP_CDE NOT IN ('45', '32') THEN--Added by Deepa on Apr-23-2012 not to log the Invalid transaction Date and Time
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
        MERCHANT_STATE, -- Added FOR MERCHANT DETAILS LOGGED IN TRANSACTIONLOG TABLE on 07-Sep-2012
        --Sn added by Pankaj S. for 10871
        productid,
        cr_dr_flag,
        cardstatus,
        acct_type,
        error_msg,
        time_stamp,   
        --En added by Pankaj S. for 10871
        ORIGINAL_STAN,
        NETWORKID_SWITCH, --Added on 20130626 for the Mantis ID 11344
        NETWORKID_ACQUIRER, --Added on 20130626 for the Mantis ID 11344
        NETWORK_SETTL_DATE, --Added on 20130626 for the Mantis ID 11123
        CVV_VERIFICATIONTYPE,--Added on 18.07.2013 for the Mantis ID 11611
        --SN Added on 30.07.2013 for 11695
        FEE_PLAN,
        FEECODE,
        TRANFEE_AMT,
        FEEATTACHTYPE
        --EN Added on 30.07.2013 for 11695
        ,INTERNATION_IND_RESPONSE   
        ,SYSTEM_TRACE_AUDIT_NO   --Added during concurrent processing issue changes
        ,merchant_id               
        )
       VALUES
        (P_MSG_TYP,
         P_RRN,
         P_DELV_CHNL,
         P_TERMINAL_ID,
         V_RVSL_TRANDATE,
         P_TXN_CODE,
         -- P_TXN_TYPE,
         V_TXN_TYPE, --Modified by Deepa on June 26 2012 As the value is passed as NULL
         P_TXN_MODE,
         --DECODE(V_CMS_ISO_RESPCODE, '00', 'C', 'F'),
         DECODE(P_ISO_RESPCDE, '00', 'C', 'F'),--Commented and replaced  on 18.07.2013 for the Mantis ID 11612
         --V_CMS_ISO_RESPCODE,
         P_ISO_RESPCDE, --Commented and replaced  on 18.07.2013 for the Mantis ID 11612
         P_BUSINESS_DATE,
         SUBSTR(P_BUSINESS_TIME, 1, 10),
         V_HASH_PAN,
         NULL,
         NULL,
         NULL,
         P_INST_CODE,
         TRIM(TO_CHAR(nvl(V_TRAN_AMT,0), '999999999999999990.99')),  --modified for 10871
         V_CURRCODE,
         NULL,         
         v_card_type, --added for 10871
         P_TERMINAL_ID,
         V_AUTH_ID,
       --TRIM(TO_CHAR(nvl(V_TRAN_AMT,0), '999999999999999990.99')),  --modified for 10871
         TRIM(TO_CHAR(nvl(P_TRAN_AMNT,0), '999999999999999990.99')),  --modified for 10871,Modified on 07-10-13 for the Mantis ID-12547
         P_MERCHANT_CNTRYCODE, --modified for 10871
         '0.00', --modified for 10871
         P_INST_CODE,
         V_ENCR_PAN,
         V_ENCR_PAN,
         V_ENCR_PAN,
         V_ORGNL_RRN,
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
        -- 'RVSL-'|| --commented for Mantis id 13406 on 17.1.2014
        V_TRAN_DESC,
         P_MERCHANT_NAME,  -- added for fss-2063 
         P_MERCHANT_CITY,  -- added for fss-2063 
         P_MERCHANT_STATE, -- added for fss-2063  commented the below v_txn_merchantname,v_txn_merchantcity,v_txn_merchantstate.
         --V_TXN_MERCHNAME, -- Added FOR MERCJANT DETAILS LOGGED IN TRANSACTIONLOG TABLE on 07-Sep-2012
        -- V_TXN_MERCHCITY, -- Added FOR MERCJANT DETAILS LOGGED IN TRANSACTIONLOG TABLE on 07-Sep-2012
         --V_TXN_MERCHSTATE, -- Added FOR MERCJANT DETAILS LOGGED IN TRANSACTIONLOG TABLE on 07-Sep-2012
         --Sn added by Pankaj S. for 10871
         v_prod_code,
         decode(v_dr_cr_flag,'CR','DR','DR','CR',v_dr_cr_flag),
         v_cap_card_stat,
         v_acct_type,
         v_errmsg,
         nvl(v_timestamp,systimestamp),   
         --En added by Pankaj S. for 10871
         P_ORGNL_STAN,
         P_NETWORKID_SWITCH , --Added on 20130626 for the Mantis ID 11344
         P_NETWORKID_ACQUIRER,-- Added on 20130626 for the Mantis ID 11344
         p_network_setl_date , --Added on 20130626 for the Mantis ID 11123
         NVL(P_CVV_VERIFICATIONTYPE,'N'),  --Added on 18.07.2013 for the Mantis ID 11611
         --SN Added on 30.07.2013 for 11695
         V_FEE_PLAN,
         V_FEE_CODE,
         V_FEE_AMT,
         V_FEEATTACH_TYPE
         --EN Added on 30.07.2013 for 11695
         ,v_internation_ind_response        
         ,P_STAN    --Added during concurrent processing issue changes 
         ,P_MERCHANT_ID               
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
        CTD_MERCHANT_ZIP,CTD_INTERNATION_IND_RESPONSE
        ,  CTD_PULSE_TRANSACTIONID,CTD_VISA_TRANSACTIONID,CTD_MC_TRACEID,
        CTD_CARDVERIFICATION_RESULT
        /* End Added by Dhiraj G on 31052012 for Pre - Auth Parameter changes  */
        ,CTD_MERCHANT_ID,CTD_COUNTRY_CODE,CTD_PAYMENT_TYPE,ctd_hashkey_id
        )
     VALUES
       (P_DELV_CHNL,
        P_TXN_CODE,
        -- P_TXN_TYPE,
        V_TXN_TYPE, --Modified by Deepa on June 26 2012 As the value is passed as NULL
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
        P_MERCHANT_ZIP,v_internation_ind_response
        ,P_PULSE_TRANSACTIONID,--Added for MVHOST 926
        P_VISA_TRANSACTIONID,--Added for MVHOST 926
        P_MC_TRACEID,--Added for MVHOST 926
        P_CARDVERIFICATION_RESULT--Added for MVHOST 926
        /* End  Added by Dhiraj G on 31052012 for Pre - Auth Parameter changes  */
        ,P_MERCHANT_ID,P_MERCHANT_CNTRYCODE,P_MS_PYMNT_DESC,V_HASHKEY_ID
        );
    EXCEPTION
     WHEN OTHERS THEN
       P_RESP_MSG := 'Problem while inserting data into transaction log  dtl' ||
                  SUBSTR(SQLERRM, 1, 300);
       P_RESP_CDE := '89'; -- Server Decline Response 220509
       P_RESP_ID  := '89'; --Added for VMS-8018
       ROLLBACK;
       RETURN;
    END;
    
            --SN Added by Pankaj S. for DB time logging changes
    SELECT (  EXTRACT (DAY FROM SYSTIMESTAMP - v_start_time) * 86400
            + EXTRACT (HOUR FROM SYSTIMESTAMP - v_start_time) * 3600
            + EXTRACT (MINUTE FROM SYSTIMESTAMP - v_start_time) * 60
            + EXTRACT (SECOND FROM SYSTIMESTAMP - v_start_time) * 1000)
      INTO v_mili
      FROM DUAL;
      
    P_RESPTIME_DETAIL :=  P_RESPTIME_DETAIL || ' 4: ' || v_mili ;
     P_RESP_TIME := v_mili;
    --EN Added by Pankaj S. for DB time logging changes

    P_RESP_MSG := V_ERRMSG;
  WHEN OTHERS THEN
    ROLLBACK TO V_SAVEPOINT;
    BEGIN
     SELECT CMS_B24_RESPCDE,CMS_ISO_RESPCDE --Changed  CMS_ISO_RESPCDE to  CMS_B24_RESPCDE for HISO SPECIFIC Response codes
       INTO P_RESP_CDE,
            --V_CMS_ISO_RESPCODE
            P_ISO_RESPCDE --Commented and replaced  on 18.07.2013 for the Mantis ID 11612
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

     --Sn limit update for ATM

     IF P_DELV_CHNL = '01' THEN

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

        IF SQL%ROWCOUNT = 0 THEN
          V_ERRMSG   := 'Problem while updating data in CMS_TRANSLIMIT_CHECK' ||
                     SUBSTR(SQLERRM, 1, 300);
          V_RESP_CDE := '21';
          RAISE EXP_RVSL_REJECT_RECORD;
        END IF;

       END IF;
     END IF;

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

        IF SQL%ROWCOUNT = 0 THEN
          V_ERRMSG   := 'Problem while updating data in CMS_TRANSLIMIT_CHECK' ||
                     SUBSTR(SQLERRM, 1, 300);
          V_RESP_CDE := '21';
          RAISE EXP_RVSL_REJECT_RECORD;
        END IF;

       END IF;
     END IF;

     --Sn limit update for MMPOS
     IF P_DELV_CHNL = '04' THEN

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

        IF SQL%ROWCOUNT = 0 THEN
          V_ERRMSG   := 'Problem while updating data in CMS_TRANSLIMIT_CHECK' ||
                     SUBSTR(SQLERRM, 1, 300);
          V_RESP_CDE := '21';
          RAISE EXP_RVSL_REJECT_RECORD;
        END IF;

       END IF;
     END IF;
    EXCEPTION
     WHEN OTHERS THEN
       V_ERRMSG   := 'Error while updating 3 CMS_TRANSLIMIT_CHECK' ||
                  SUBSTR(SQLERRM, 1, 200);
       V_RESP_CDE := '21';
       RAISE EXP_RVSL_REJECT_RECORD;
    END;
    */          --En:Commented as per review observation for FSS-1246

    --Sn create a entry in txn log
    IF V_RESP_CDE NOT IN ('45', '32') THEN--Added by Deepa on Apr-23-2012 not to log the Invalid transaction Date and Time
    
      --Sn added by Pankaj S. for 10871 
      IF v_dr_cr_flag IS NULL THEN
      BEGIN  
        select  CTM_CREDIT_DEBIT_FLAG,CTM_TRAN_DESC,
                TO_NUMBER(DECODE(CTM_TRAN_TYPE, 'N', '0', 'F', '1')),CTM_PREAUTH_TYPE
          INTO v_dr_cr_flag, v_tran_desc, v_txn_type,V_PREAUTH_TYPE
          FROM cms_transaction_mast
         WHERE ctm_tran_code = p_txn_code
           AND ctm_delivery_channel = p_delv_chnl
           AND ctm_inst_code = p_inst_code;                    
      EXCEPTION
         WHEN OTHERS THEN
            NULL;
      END;
          IF V_MS_PYMNT_TYPE        IS NOT NULL THEN
  IF( V_PREAUTH_TYPE       ='D') THEN
    IF( v_org_msgtype     IS NOT NULL) THEN
      IF (V_ORG_MSGTYPE   IN ('1220','1221')) THEN
        V_TRAN_DESC      :='MoneySend Funding Settlement';
      elsif v_org_msgtype IN ('1200','1201') THEN
        V_TRAN_DESC      :='MoneySend Funding';
      END IF;
    ELSE
      V_TRAN_DESC :='MoneySend Funding Settlement';
    END IF;
  ELSIF ( V_PREAUTH_TYPE ='C') THEN
    IF( v_org_msgtype   IS NOT NULL) THEN
      IF (v_org_msgtype IN ('1200','1201')) THEN
        V_TRAN_DESC    :='MoneySend Payment';
      END IF;
    END IF;
  end if;
END IF; 
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
       SELECT CAM_ACCT_BAL, CAM_LEDGER_BAL,cam_type_code
       INTO V_ACCT_BALANCE, V_LEDGER_BAL, v_acct_type 
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
         MERCHANT_STATE ,-- Added FOR MERCHANT DETAILS LOGGED IN TRANSACTIONLOG TABLE on 07-Sep-2012
         --Sn added by Pankaj S. for 10871
         productid,
         cr_dr_flag,
         cardstatus,
         acct_type,
         error_msg,
         time_stamp,   
         --En added by Pankaj S. for 10871
         ORIGINAL_STAN,
         NETWORKID_SWITCH, --Added on 20130626 for the Mantis ID 11344
         NETWORKID_ACQUIRER, --Added on 20130626 for the Mantis ID 11344
         NETWORK_SETTL_DATE ,--Added on 20130626 for the Mantis ID 11123
         CVV_VERIFICATIONTYPE,  --Added on 18.07.2013 for the Mantis ID 11611
          --SN Added on 30.07.2013 for 11695
         FEE_PLAN,
         FEECODE,
         TRANFEE_AMT,
         FEEATTACHTYPE
         --EN Added on 30.07.2013 for 11695
         ,INTERNATION_IND_RESPONSE 
         ,merchant_id         
         )
       VALUES
        (P_MSG_TYP,
         P_RRN,
         P_DELV_CHNL,
         P_TERMINAL_ID,
         V_RVSL_TRANDATE,
         P_TXN_CODE,
         -- P_TXN_TYPE,
         V_TXN_TYPE, --Modified by Deepa on June 26 2012 As the value is passed as NULL
         P_TXN_MODE,
         --DECODE(V_CMS_ISO_RESPCODE, '00', 'C', 'F'),
        DECODE(P_ISO_RESPCDE , '00', 'C', 'F'),--Commented and replaced  on 18.07.2013 for the Mantis ID 11612
         --V_CMS_ISO_RESPCODE,
         P_ISO_RESPCDE, --Commented and replaced  on 18.07.2013 for the Mantis ID 11612
         P_BUSINESS_DATE,
         SUBSTR(P_BUSINESS_TIME, 1, 10),
         V_HASH_PAN,
         NULL,
         NULL,
         NULL,
         P_INST_CODE,
         TRIM(TO_CHAR(nvl(V_TRAN_AMT,0), '999999999999999990.99')),  --modified for 10871
         V_CURRCODE,
         NULL,
         v_card_type, --added for 10871
         P_TERMINAL_ID,
         V_AUTH_ID,
       --TRIM(TO_CHAR(nvl(V_TRAN_AMT,0), '999999999999999990.99')),  --modified for 10871
         TRIM(TO_CHAR(nvl(P_TRAN_AMNT,0), '999999999999999990.99')),  --modified for 10871,Modified on 07-10-13 for the Mantis ID-12547
         P_MERCHANT_CNTRYCODE, --modified for 10871
         '0.00', --modified for 10871
         P_INST_CODE,
         V_ENCR_PAN,
         V_ENCR_PAN,
         V_ENCR_PAN,
         V_ORGNL_RRN,
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
        --'RVSL-'||  --commented for Mantis id 13406 on 17.1.2014
        V_TRAN_DESC,
         /* End Added by Dhiraj G on 31052012 for Pre - Auth Parameter changes  */
         P_MERCHANT_NAME,  -- added for fss-2063 
         P_MERCHANT_CITY,  -- added for fss-2063 
         P_MERCHANT_STATE, -- added for fss-2063  commented the below v_txn_merchantname,v_txn_merchantcity,v_txn_merchantstate.
        -- V_TXN_MERCHNAME, -- Added FOR MERCJANT DETAILS LOGGED IN TRANSACTIONLOG TABLE on 07-Sep-2012
        -- V_TXN_MERCHCITY, -- Added FOR MERCJANT DETAILS LOGGED IN TRANSACTIONLOG TABLE on 07-Sep-2012
        -- V_TXN_MERCHSTATE, -- Added FOR MERCJANT DETAILS LOGGED IN TRANSACTIONLOG TABLE on 07-Sep-2012
         --Sn added by Pankaj S. for 10871
         v_prod_code,
          decode(v_dr_cr_flag,'CR','DR','DR','CR',v_dr_cr_flag),
         v_cap_card_stat,
         v_acct_type,
         v_errmsg,
         nvl(v_timestamp,systimestamp),   
          --En added by Pankaj S. for 10871
         P_ORGNL_STAN,
         P_NETWORKID_SWITCH , --Added on 20130626 for the Mantis ID 11344
         P_NETWORKID_ACQUIRER,-- Added on 20130626 for the Mantis ID 11344
         p_network_setl_date , --Added on 20130626 for the Mantis ID 11123
         NVL(P_CVV_VERIFICATIONTYPE,'N'),  --Added on 18.07.2013 for the Mantis ID 11611
            --SN Added on 30.07.2013 for 11695
         V_FEE_PLAN,
         V_FEE_CODE,
         V_FEE_AMT,
         V_FEEATTACH_TYPE
         --EN Added on 30.07.2013 for 11695
         ,v_internation_ind_response 
         ,P_MERCHANT_ID                      
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
        CTD_MERCHANT_ZIP,CTD_INTERNATION_IND_RESPONSE
        ,CTD_PULSE_TRANSACTIONID,CTD_VISA_TRANSACTIONID,CTD_MC_TRACEID,
        --CTD_MEDAGATE_RESPVERBIAGE)--Added for MVHOST 926
        CTD_CARDVERIFICATION_RESULT
        /* End Added by Dhiraj G on 31052012 for Pre - Auth Parameter changes  */
        ,CTD_MERCHANT_ID,CTD_COUNTRY_CODE,CTD_PAYMENT_TYPE,ctd_hashkey_id
        )
     VALUES
       (P_DELV_CHNL,
        P_TXN_CODE,
        -- P_TXN_TYPE,
        V_TXN_TYPE, --Modified by Deepa on June 26 2012 As the value is passed as NULL
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
        P_MERCHANT_ZIP,v_internation_ind_response
        ,P_PULSE_TRANSACTIONID,--Added for MVHOST 926
        P_VISA_TRANSACTIONID,--Added for MVHOST 926
        P_MC_TRACEID,--Added for MVHOST 926
        P_CARDVERIFICATION_RESULT
        /* End  Added by Dhiraj G on 31052012 for Pre - Auth Parameter changes  */
        ,P_MERCHANT_ID,P_MERCHANT_CNTRYCODE,P_MS_PYMNT_DESC,V_HASHKEY_ID
        );
    EXCEPTION
     WHEN OTHERS THEN
       P_RESP_MSG := 'Problem while inserting data into transaction log  dtl' ||
                  SUBSTR(SQLERRM, 1, 300);
       P_RESP_CDE := '89'; -- Server Decline Response 220509
       P_RESP_ID  := '89'; --Added for VMS-8018
       ROLLBACK;
       RETURN;
    END;
    
            --SN Added by Pankaj S. for DB time logging changes
    SELECT (  EXTRACT (DAY FROM SYSTIMESTAMP - v_start_time) * 86400
            + EXTRACT (HOUR FROM SYSTIMESTAMP - v_start_time) * 3600
            + EXTRACT (MINUTE FROM SYSTIMESTAMP - v_start_time) * 60
            + EXTRACT (SECOND FROM SYSTIMESTAMP - v_start_time) * 1000)
      INTO v_mili
      FROM DUAL;
      
    P_RESPTIME_DETAIL :=  P_RESPTIME_DETAIL || ' 4: ' || v_mili ;
     P_RESP_TIME := v_mili;
    --EN Added by Pankaj S. for DB time logging changes

    P_RESP_MSG_M24 := V_ERRMSG;
END;

/
show error;