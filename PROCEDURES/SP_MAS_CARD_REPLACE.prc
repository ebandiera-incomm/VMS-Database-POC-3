create or replace
PROCEDURE          VMSCMS.SP_MAS_CARD_REPLACE(P_INST_CODE        IN NUMBER,
                                        P_MSG              IN VARCHAR2,
                                        P_RRN              VARCHAR2,
                                        P_DELIVERY_CHANNEL VARCHAR2,
                                        P_TERM_ID          VARCHAR2,
                                        P_TXN_CODE         VARCHAR2,
                                        P_TXN_MODE         VARCHAR2,
                                        P_TRAN_DATE        VARCHAR2,
                                        P_TRAN_TIME        VARCHAR2,
                                        P_CARD_NO          VARCHAR2,
                                        P_BANK_CODE        VARCHAR2,
                                        P_TXN_AMT          NUMBER,
                                        P_MCC_CODE         VARCHAR2,                                                                          
                                        P_EXPRY_DATE       IN VARCHAR2,
                                        P_STAN             IN VARCHAR2,
                                        P_MBR_NUMB         IN VARCHAR2,
                                        P_RVSL_CODE        IN NUMBER,                                        
                                        P_MEDAGATEREFID    IN VARCHAR2,
                                        P_NEW_CARD_NO      IN VARCHAR2,                                       
                                        P_NEW_CARD_STATUS  IN NUMBER,
                                        P_AUTH_ID          OUT VARCHAR2,
                                        P_RESP_CODE        OUT VARCHAR2,
                                        P_RESP_MSG         OUT VARCHAR2,
                                        P_CAPTURE_DATE     OUT DATE,
                                         P_ACCT_BAL       OUT VARCHAR2,--ADDED BY ABDUL HAMEED M.A. FOR EEP2.1
                                         P_LEDGER_BAL       OUT VARCHAR2,--ADDED BY ABDUL HAMEED M.A. FOR EEP2.1
                                        P_FEE_FLAG         IN  VARCHAR2 DEFAULT 'Y'  
                                                                                       
                                        ) IS

  /*****************************************************************************
   * Added by          : Ramesh A
   * Added Date        : 10-Jan-13
   * Added For         : MVHOST-385 : Card Replacement in MedaGate
   * Reviewer          : Dhiraj
   * Reviewed Date     : 25-06-2013
   * Build Number      : RI0024.2_B0008
   
   * Modified by       : Ramesh A
   * Modified Date     : 26-Jan-13
   * Modified For      : Defect id : 11413 proxy number not updated for new card   
   * Reviewer          : Dhiraj
   * Reviewed Date     : 27-06-2013
   * Build Number      : RI0024.2_B0009
   
   * Modified by       : Ramesh A
   * Modified Date     : 12-July-13
   * Modified For      : Defect id : 11450 Added active date for replacement new card
   * Reviewer          : 
   * Reviewed Date     : 
   * Build Number      : RI0024.3_B0003
   
   * Modified by       : Ramesh A
   * Modified Date     : 25-July-13
   * Modified For      : Defect id : 11745 Not able to Card Replacement in Metagate Server 
                         Card Replacement declined since there were two entries in cms_smsandemail_alert for same card number
   * Reviewer          : Sagar M.
   * Reviewed Date     : 25-July-13
   * Build Number      : RI0024.3_B0006
   
    * Modified by      : MageshKumar.S 
   * Modified Reason  : JH-6(Fast50 and Fedral And State Tax Refund Alerts) 
   * Modified Date    : 19-09-2013
   * Reviewer         : Dhiraj
   * Reviewed Date    : 19-Sep-2013
   * Build Number     : RI0024.5_B0001
   
   * Modified By      : Pankaj S.
   * Modified Date    : 19-Dec-2013
   * Modified Reason  : Logging issue changes(Mantis ID-13160)
   * Reviewer         : Dhiraj
   * Reviewed Date    : 
   * Build Number     :
   
   * Modified by       : Abdul Hameed M.A
   * Modified for      : EEP2.1
   * Modified Reason   : To return the ledger balance and available balance for medagate
   * Modified Date     : 05-Mar-2014
   * Reviewer          : Dhiraj
   * Reviewed Date     : 13-Mar-2014
   * Build Number      : RI0027.2_B0002 
   
    * Modified By      : Raja Gopal G
   * Modified Date    : 30-Jul-2014
   * Modified Reason  : Check Deposit Pending ,Accepted And Rejected Alerts(FR 3.2)           
   * Reviewer         : Spankaj
   * Build Number     : RI0027.3.1_B0002
   
     * Modified By      : Siva kumar M.
     * Modified Date    : 13-Nov-2014
     * Modified For     : Defect id:15857
     * Modified Reason  : package id and prod id impact changes.
     * Reviewer         :Spankaj
     * Build Number     : RI0027.4.3_B0004
     
     * Modified by      : Ramesh A.
     * Modified for     : FWR-59 : SMA and Email Alerts
     * Modified Date    : 13-Aug-2015
     * Reviewer         : Pankaj S
     * Build Number     : VMSGPRHOST_3.1     
     
     * Modified by      : Pankaj S.
     * Modified for     : To audit SMS and Email Alerts changes
     * Modified Date  : 21-Mar-2016
     * Reviewer          : Saravanan
     * Build Number  : VMSGPRHOST_4.0     
	 
    * Modified By      : UBAIDUR RAHMAN H
    * Modified Date    : 16-JAN-2018
    * Purpose          : CURRENCY CODE CHANGES FROM INST LEVEL TO BIN LEVEL.
    * Reviewer         : Vini
    * Release Number   : VMSGPRHOST18.1
	
	* Modified By      : Vini Pushkaran
    * Modified Date    : 14-MAY-2018
    * Purpose          : VMS 207 - Added new field to VMS_AUDITTXN_DTLS.
    * Reviewer         : Vini
    * Release Number   : VMSGPRHOST_R01
   ******************************************************************************/
  V_ACCT_BALANCE     NUMBER;
  V_LEDGER_BAL       NUMBER;
  V_TRAN_AMT         NUMBER;
  V_AUTH_ID          TRANSACTIONLOG.AUTH_ID%TYPE;
  V_TOTAL_AMT        NUMBER;
  V_TRAN_DATE        DATE;
  V_PROD_CODE        CMS_PROD_MAST.CPM_PROD_CODE%TYPE;
  V_PROD_CATTYPE     CMS_PROD_CATTYPE.CPC_CARD_TYPE%TYPE;
  V_FEE_AMT          NUMBER;
  V_TOTAL_FEE        NUMBER;
  V_UPD_AMT          NUMBER;
  V_UPD_LEDGER_AMT   NUMBER;
  V_NARRATION        VARCHAR2(50);
  V_FEE_OPENING_BAL  NUMBER;
  V_RESP_CDE         VARCHAR2(5);
  V_EXPRY_DATE       DATE;
  V_DR_CR_FLAG       VARCHAR2(2);
  V_OUTPUT_TYPE      VARCHAR2(2);
  V_APPLPAN_CARDSTAT CMS_APPL_PAN.CAP_CARD_STAT%TYPE; 
  V_ERR_MSG          VARCHAR2(500);   
  V_GL_UPD_FLAG        TRANSACTIONLOG.GL_UPD_FLAG%TYPE;
  V_GL_ERR_MSG         VARCHAR2(500);
  V_SAVEPOINT          NUMBER := 0;
  V_TRAN_FEE           NUMBER;
  V_ERROR              VARCHAR2(500);
  V_BUSINESS_DATE_TRAN DATE;
  V_BUSINESS_TIME      VARCHAR2(5);
  V_CUTOFF_TIME        VARCHAR2(5);
  V_CARD_CURR          VARCHAR2(5);
  V_FEE_CODE           CMS_FEE_MAST.CFM_FEE_CODE%TYPE;
  V_FEE_CRGL_CATG      CMS_PRODCATTYPE_FEES.CPF_CRGL_CATG%TYPE;
  V_FEE_CRGL_CODE      CMS_PRODCATTYPE_FEES.CPF_CRGL_CODE%TYPE;
  V_FEE_CRSUBGL_CODE   CMS_PRODCATTYPE_FEES.CPF_CRSUBGL_CODE%TYPE;
  V_FEE_CRACCT_NO      CMS_PRODCATTYPE_FEES.CPF_CRACCT_NO%TYPE;
  V_FEE_DRGL_CATG      CMS_PRODCATTYPE_FEES.CPF_DRGL_CATG%TYPE;
  V_FEE_DRGL_CODE      CMS_PRODCATTYPE_FEES.CPF_DRGL_CODE%TYPE;
  V_FEE_DRSUBGL_CODE   CMS_PRODCATTYPE_FEES.CPF_DRSUBGL_CODE%TYPE;
  V_FEE_DRACCT_NO      CMS_PRODCATTYPE_FEES.CPF_DRACCT_NO%TYPE;
  --st AND cess
  V_SERVICETAX_PERCENT CMS_INST_PARAM.CIP_PARAM_VALUE%TYPE;
  V_CESS_PERCENT       CMS_INST_PARAM.CIP_PARAM_VALUE%TYPE;
  V_SERVICETAX_AMOUNT  NUMBER;
  V_CESS_AMOUNT        NUMBER;
  V_ST_CALC_FLAG       CMS_PRODCATTYPE_FEES.CPF_ST_CALC_FLAG%TYPE;
  V_CESS_CALC_FLAG     CMS_PRODCATTYPE_FEES.CPF_CESS_CALC_FLAG%TYPE;
  V_ST_CRACCT_NO       CMS_PRODCATTYPE_FEES.CPF_ST_CRACCT_NO%TYPE;
  V_ST_DRACCT_NO       CMS_PRODCATTYPE_FEES.CPF_ST_DRACCT_NO%TYPE;
  V_CESS_CRACCT_NO     CMS_PRODCATTYPE_FEES.CPF_CESS_CRACCT_NO%TYPE;
  V_CESS_DRACCT_NO     CMS_PRODCATTYPE_FEES.CPF_CESS_DRACCT_NO%TYPE;
  --
  V_WAIV_PERCNT     CMS_PRODCATTYPE_WAIV.CPW_WAIV_PRCNT%TYPE;
  V_ERR_WAIV        VARCHAR2(300);
  V_LOG_ACTUAL_FEE  NUMBER;
  V_LOG_WAIVER_AMT  NUMBER;
  V_AUTH_SAVEPOINT  NUMBER DEFAULT 0;
  V_BUSINESS_DATE   DATE;
  V_TXN_TYPE        NUMBER(1);
  V_MINI_TOTREC     NUMBER(2);
  V_MINISTMT_ERRMSG VARCHAR2(500);
  V_MINISTMT_OUTPUT VARCHAR2(900);
  EXP_REJECT_RECORD EXCEPTION;   
    EXP_AUTH_REJECT_RECORD EXCEPTION;
  V_CARD_ACCT_NO             VARCHAR2(20);  
  V_HASH_PAN                 CMS_APPL_PAN.CAP_PAN_CODE%TYPE;
  V_ENCR_PAN                 CMS_APPL_PAN.CAP_PAN_CODE_ENCR%TYPE;
  V_RRN_COUNT                NUMBER;
  V_TRAN_TYPE                VARCHAR2(2);
  V_DATE                     DATE;
  V_TIME                     VARCHAR2(10);
  V_MAX_CARD_BAL             NUMBER;
  V_CURR_DATE                DATE;
  V_PROXUNUMBER              CMS_APPL_PAN.CAP_PROXY_NUMBER%TYPE;
  V_ACCT_NUMBER              CMS_APPL_PAN.CAP_ACCT_NO%TYPE;
  V_CAP_CARD_STAT            VARCHAR2(10);
  CRDSTAT_CNT                VARCHAR2(10);
  V_CRO_OLDCARD_REISSUE_STAT VARCHAR2(10);
  NEW_CARD_NO                VARCHAR2(100);
  V_CAP_PROD_CATG            VARCHAR2(100);
  V_CUST_CODE                VARCHAR2(100);
  P_REMRK                    VARCHAR2(100);
  V_RESONCODE                CMS_SPPRT_REASONS.CSR_SPPRT_RSNCODE%TYPE;
  V_STATUS_CHK               NUMBER;

  --Added by Deepa On June 19 2012 for Fees Changes
  V_FEEAMNT_TYPE CMS_FEE_MAST.CFM_FEEAMNT_TYPE%TYPE;
  V_PER_FEES     CMS_FEE_MAST.CFM_PER_FEES%TYPE;
  V_FLAT_FEES    CMS_FEE_MAST.CFM_FEE_AMT%TYPE;
  V_CLAWBACK     CMS_FEE_MAST.CFM_CLAWBACK_FLAG%TYPE;
  V_FEE_PLAN     CMS_FEE_FEEPLAN.CFF_FEE_PLAN%TYPE;  
  V_STARTERCARD_FLAG CMS_APPL_PAN.CAP_STARTERCARD_FLAG%TYPE; 
  v_dup_check                  NUMBER (3); 
  v_cam_lupd_date              cms_addr_mast.cam_lupd_date%TYPE;
  V_NEW_HASH_PAN               CMS_APPL_PAN.CAP_PAN_CODE%TYPE;
  V_APPL_CODE                  CMS_APPL_PAN.CAP_APPL_CODE%TYPE; 
  v_cam_type_code   cms_acct_mast.cam_type_code%type; 
  v_timestamp       timestamp;                         
  
  V_OLD_STARTERCARD_FLAG  CMS_APPL_PAN.CAP_STARTERCARD_FLAG%TYPE; 
  V_NEW_ENCR_PAN          CMS_APPL_PAN.CAP_PAN_CODE_ENCR%TYPE;
  V_NEW_STARTERCARD_FLAG  CMS_APPL_PAN.CAP_STARTERCARD_FLAG%TYPE;  
  v_appln_status           VARCHAR2(20);
  V_NEW_PROD_CODE          VARCHAR2(100);
  V_NEW_CARD_STAT          VARCHAR2(100); 
   V_LOG_COUNT            NUMBER;            
   V_NEW_CARD_STATUS      NUMBER default 0;
   V_ACCT_ID              CMS_APPL_PAN.CAP_ACCT_ID%TYPE;
   V_PROD_ID  CMS_PROD_CATTYPE.CPC_PROD_ID%TYPE;  
  V_NEW_CARD_TYPE CMS_APPL_PAN.CAP_CARD_TYPE%TYPE;
    V_BASE_CURR          CMS_BIN_PARAM.CBP_PARAM_VALUE%TYPE;
    V_CURR_CODE          CMS_INST_PARAM.CIP_PARAM_VALUE%TYPE;
    V_BILL_ADDR          CMS_APPL_PAN.CAP_BILL_ADDR%TYPE;
    v_lmtprfl                cms_prdcattype_lmtprfl.cpl_lmtprfl_id%TYPE;
   v_profile_level          cms_appl_pan.cap_prfl_levl%TYPE;
   
   --St: Added for Defect id : 11745 on 25-07-2013
   V_CELLPHONECARRIER    CMS_SMSANDEMAIL_ALERT.CSA_CELLPHONECARRIER%type;
   V_LOADORCREDIT_FLAG   CMS_SMSANDEMAIL_ALERT.CSA_LOADORCREDIT_FLAG%type; 
   V_LOWBAL_FLAG         CMS_SMSANDEMAIL_ALERT.CSA_LOWBAL_FLAG%type;
   V_LOWBAL_AMT          CMS_SMSANDEMAIL_ALERT.CSA_LOWBAL_AMT%type;
   V_NEGBAL_FLAG         CMS_SMSANDEMAIL_ALERT.CSA_NEGBAL_FLAG%type;
   V_HIGHAUTHAMT         CMS_SMSANDEMAIL_ALERT.CSA_HIGHAUTHAMT%type;
   V_HIGHAUTHAMT_FLAG    CMS_SMSANDEMAIL_ALERT.CSA_HIGHAUTHAMT_FLAG%type;
   V_DAILYBAL_FLAG       CMS_SMSANDEMAIL_ALERT.CSA_DAILYBAL_FLAG%type;
   V_BEGIN_TIME          CMS_SMSANDEMAIL_ALERT.CSA_BEGIN_TIME%type;
   V_END_TIME            CMS_SMSANDEMAIL_ALERT.CSA_END_TIME%type;
   V_INSUFF_FLAG         CMS_SMSANDEMAIL_ALERT.CSA_INSUFF_FLAG%type;
   V_INCORRPIN_FLAG      CMS_SMSANDEMAIL_ALERT.CSA_INCORRPIN_FLAG%type;
   --En: Added for Defect id : 11745 on 25-07-2013 
   V_FAST50_FLAG         CMS_SMSANDEMAIL_ALERT.CSA_FAST50_FLAG%Type; --Added on 19.09.2013 by MageshKumar.S for JH-6
   V_FEDERAL_STATE_FLAG  CMS_SMSANDEMAIL_ALERT.CSA_FEDTAX_REFUND_FLAG%Type; --Added on 19.09.2013 by MageshKumar.S for JH-6
   V_CHK_DEP_PENDING_FLAG   CMS_SMSANDEMAIL_ALERT.CSA_DEPPENDING_FLAG %Type;  --Added by Raja Gopal G on 30/07/2014 fro FR 3.2
   V_CHK_DEP_ACCEPTED_FLAG  CMS_SMSANDEMAIL_ALERT.CSA_DEPACCEPTED_FLAG %Type;  -- Added by Raja Gopal G on 30/07/2014 fro FR 3.2
   V_CHK_DEP_REJECTED_FLAG  CMS_SMSANDEMAIL_ALERT.CSA_DEPREJECTED_FLAG %Type ;-- Added by Raja Gopal G on 30/07/2014 fro FR 3.2       
   V_CARD_ID            CMS_PROD_CATTYPE.CPC_CARD_ID%TYPE; -- ADDED for Mantis id:15857
   L_ALERT_LANG_ID  CMS_SMSANDEMAIL_ALERT.CSA_ALERT_LANG_ID%TYPE; --Added for FWR-59
   V_PROFILE_CODE   CMS_PROD_CATTYPE.CPC_PROFILE_CODE%TYPE;
   v_Retperiod  date;  --Added for VMS-5739/FSP-991
   v_Retdate  date; --Added for VMS-5739/FSP-991
BEGIN
  SAVEPOINT V_AUTH_SAVEPOINT;
  V_RESP_CDE := '1';
  V_ERR_MSG  := 'OK';
  P_RESP_MSG := 'OK';
  P_REMRK    := 'Online Order Replacement Card';
  
     
  BEGIN
        --SN CREATE HASH PAN
        --Gethash is used to hash the original Pan no
        BEGIN
         V_HASH_PAN := GETHASH(P_CARD_NO);
        EXCEPTION
         WHEN OTHERS THEN
           V_ERR_MSG := 'Error while converting into hash value ' ||fn_mask(P_CARD_NO,'X',7,6)
                     ||' '||SUBSTR(SQLERRM, 1, 200);
           RAISE EXP_REJECT_RECORD;
        END;
      
        --EN CREATE HASH PAN
      
        --SN create encr pan
        --Fn_Emaps_Main is used for Encrypt the original Pan no
        BEGIN
         V_ENCR_PAN := FN_EMAPS_MAIN(P_CARD_NO);
        EXCEPTION
         WHEN OTHERS THEN
           V_ERR_MSG := 'Error while converting into encrypted value '||fn_mask(P_CARD_NO,'X',7,6)
                     ||' '||SUBSTR(SQLERRM, 1, 200);
           RAISE EXP_REJECT_RECORD;
        END;    
        --EN create encr pan  
        
          --SN CREATE HASH PAN
        --Gethash is used to hash the original Pan no
        BEGIN
         V_NEW_HASH_PAN := GETHASH(P_NEW_CARD_NO);
        EXCEPTION
         WHEN OTHERS THEN
           V_ERR_MSG := 'Error while converting into hash value ' ||fn_mask(P_NEW_CARD_NO,'X',7,6)
                     ||' '||SUBSTR(SQLERRM, 1, 200);
           RAISE EXP_REJECT_RECORD;
        END;
      
        --EN CREATE HASH PAN
      
        --SN create encr pan
        --Fn_Emaps_Main is used for Encrypt the original Pan no
        BEGIN
         V_NEW_ENCR_PAN := FN_EMAPS_MAIN(P_NEW_CARD_NO);
        EXCEPTION
         WHEN OTHERS THEN
           V_ERR_MSG := 'Error while converting into encrypted value '||fn_mask(P_NEW_CARD_NO,'X',7,6)
                     ||' '||SUBSTR(SQLERRM, 1, 200);
           RAISE EXP_REJECT_RECORD;
        END;
     
        --EN create encr pan  
        
          --Sn Duplicate RRN Check
        BEGIN
		--Added for VMS-5739/FSP-991
	 select (add_months(trunc(sysdate,'MM'),'-'||RETENTION_PERIOD))
		   INTO   v_Retperiod 
		   FROM DBA_OPERATIONS.ARCHIVE_MGMT_CTL 
		   WHERE  OPERATION_TYPE='ARCHIVE' 
		   AND OBJECT_NAME='TRANSACTIONLOG_EBR';
		   
		   v_Retdate := TO_DATE(SUBSTR(TRIM(P_TRAN_DATE), 1, 8), 'yyyymmdd');


	IF (v_Retdate>v_Retperiod)
		THEN
			 SELECT COUNT(1)
			   INTO V_RRN_COUNT
			   FROM TRANSACTIONLOG
			  WHERE RRN = P_RRN AND --Changed for admin dr cr.
				   BUSINESS_DATE = P_TRAN_DATE AND
				   DELIVERY_CHANNEL = P_DELIVERY_CHANNEL; --Added by ramkumar.Mk on 25 march 2012
	ELSE
			SELECT COUNT(1)
			   INTO V_RRN_COUNT
			   FROM VMSCMS_HISTORY.TRANSACTIONLOG_HIST --Added for VMS-5733/FSP-991
			  WHERE RRN = P_RRN AND --Changed for admin dr cr.
				   BUSINESS_DATE = P_TRAN_DATE AND
				   DELIVERY_CHANNEL = P_DELIVERY_CHANNEL; --Added by ramkumar.Mk on 25 march 2012
	END IF;			   
               
             IF V_RRN_COUNT > 0 THEN
               V_RESP_CDE := '22';
               V_ERR_MSG  := 'Duplicate RRN from the Terminal on ' || P_TRAN_DATE;
               RAISE EXP_REJECT_RECORD;
             END IF;
             
        END;
        --En Duplicate RRN Check
       
        
        BEGIN
         V_BUSINESS_DATE := TO_DATE(SUBSTR(TRIM(P_TRAN_DATE), 1, 8) || ' ' ||
                            SUBSTR(TRIM(P_TRAN_TIME), 1, 10),
                            'yyyymmdd hh24:mi:ss');
        EXCEPTION
         WHEN OTHERS THEN
           V_RESP_CDE := '32'; -- Server Declined -220509
           V_ERR_MSG  := 'Problem while converting transaction date time ' ||
                      SUBSTR(SQLERRM, 1, 200);
           RAISE EXP_REJECT_RECORD;
        END;
        
     
          --Sn find debit and credit flag
        BEGIN
         SELECT CTM_CREDIT_DEBIT_FLAG,
               CTM_OUTPUT_TYPE,
               TO_NUMBER(DECODE(CTM_TRAN_TYPE, 'N', '0', 'F', '1')),
               CTM_TRAN_TYPE
           INTO V_DR_CR_FLAG, V_OUTPUT_TYPE, V_TXN_TYPE, V_TRAN_TYPE
           FROM CMS_TRANSACTION_MAST
          WHERE CTM_TRAN_CODE = P_TXN_CODE AND
               CTM_DELIVERY_CHANNEL = P_DELIVERY_CHANNEL AND
               CTM_INST_CODE = P_INST_CODE;
        EXCEPTION
         WHEN NO_DATA_FOUND THEN
           V_RESP_CDE := '12'; --Ineligible Transaction
           V_ERR_MSG  := 'Transflag  not defined for txn code ' || P_TXN_CODE ||
                      ' and delivery channel ' || P_DELIVERY_CHANNEL;
           RAISE EXP_REJECT_RECORD;
         WHEN OTHERS THEN
           V_RESP_CDE := '21'; --Ineligible Transaction
           V_ERR_MSG  := 'Error while selecting transaction details';
           RAISE EXP_REJECT_RECORD;
        END;
      
        --En find debit and credit flag  
      
       --Sn Added by Pankaj S. on 12-Feb-2013 for Duplicate card Replacement check (FSS-391)
      BEGIN
         SELECT COUNT (1)
           INTO v_dup_check
           FROM cms_htlst_reisu
          WHERE chr_inst_code = p_inst_code
            AND chr_pan_code = v_hash_pan
            AND chr_reisu_cause = 'R'
            AND chr_new_pan IS NOT NULL;

         IF v_dup_check > 0
         THEN
            v_resp_cde := '159';
            v_err_msg := 'Card already Replaced';
            RAISE exp_reject_record;
         END IF;
      END;

      --En Added by Pankaj S. on 12-Feb-2013 for Duplicate card Replacement check (FSS-391)       
      
        --St :Added for getting new pan details
        BEGIN
         SELECT CAP_PROD_CATG, CAP_CARD_STAT, CAP_ACCT_NO, CAP_CUST_CODE,
                CAP_APPL_CODE ,CAP_STARTERCARD_FLAG,CAP_ACCT_ID,CAP_BILL_ADDR,CAP_PROXY_NUMBER, --Added proxy number for defect id :11413 on 20/06/2013
                cap_prod_code,cap_card_type  --Added by Pankaj S. for logging changes(Mantis ID-13160)
           INTO V_CAP_PROD_CATG, V_CAP_CARD_STAT, V_ACCT_NUMBER, V_CUST_CODE,
                V_APPL_CODE  , V_OLD_STARTERCARD_FLAG,V_ACCT_ID,V_BILL_ADDR,V_PROXUNUMBER,  --Added proxy number for defect id :11413 on 20/06/2013
                v_prod_code,v_prod_cattype  --Added by Pankaj S. for logging changes(Mantis ID-13160)
           FROM CMS_APPL_PAN
          WHERE CAP_PAN_CODE = V_HASH_PAN AND CAP_INST_CODE = P_INST_CODE;
        EXCEPTION
         WHEN NO_DATA_FOUND THEN
           V_ERR_MSG  := 'Old Pan not found in master';
           V_RESP_CDE := '21';
           RAISE EXP_REJECT_RECORD;
         WHEN OTHERS THEN
           V_ERR_MSG  := 'Error while selecting data from appl pan ' ||
                      SUBSTR(SQLERRM, 1, 200);
           V_RESP_CDE := '21';
           RAISE EXP_REJECT_RECORD;
        END;
       --End :Added for getting new pan details
    
        --St :Added for checking valid card status
        BEGIN
         SELECT COUNT(*)
           INTO CRDSTAT_CNT
           FROM CMS_REISSUE_VALIDSTAT
          WHERE CRV_INST_CODE = P_INST_CODE AND
               CRV_VALID_CRDSTAT = V_CAP_CARD_STAT AND CRV_PROD_CATG IN ('P');
         IF CRDSTAT_CNT = 0 THEN
           V_ERR_MSG  := 'Not a valid card status. Card cannot be reissued';
           V_RESP_CDE := '12';
           RAISE EXP_REJECT_RECORD;
         END IF;
                        
        END;
        --End :Added for checking valid card status
       
        --St :Added for checking (old card)starter card flag  for replacement
        IF V_OLD_STARTERCARD_FLAG NOT IN ('Y') THEN
            V_ERR_MSG  := 'Old Card should be Starter Card for Replacement';
            V_RESP_CDE := '182';
           RAISE EXP_REJECT_RECORD;
        END IF;
      --End :Added for checking starter card flag  for replacement
   
        
      --Sn added for getting new pan details
        
        BEGIN
         SELECT CAP_PROD_CODE, CAP_CARD_STAT, CAP_STARTERCARD_FLAG , 
                cap_card_type,cap_prfl_code,cap_prfl_levl
           INTO V_NEW_PROD_CODE, V_NEW_CARD_STAT,  V_NEW_STARTERCARD_FLAG,
                V_NEW_CARD_TYPE , v_lmtprfl , v_profile_level
           FROM CMS_APPL_PAN
          WHERE CAP_PAN_CODE= v_new_hash_pan AND CAP_INST_CODE = P_INST_CODE;
        EXCEPTION
         WHEN NO_DATA_FOUND THEN
           V_ERR_MSG  := 'New Pan not found in master';
           V_RESP_CDE := '21';
           RAISE EXP_REJECT_RECORD;
         WHEN OTHERS THEN
           V_ERR_MSG  := 'Error while selecting data from appl pan ' ||
                      SUBSTR(SQLERRM, 1, 200);
           V_RESP_CDE := '21';
           RAISE EXP_REJECT_RECORD;
        END;
       --En added for getting new pan details

      --St :Added for checking (New card)starter card flag  for replacement
        IF V_NEW_STARTERCARD_FLAG NOT IN ('Y') THEN
            V_ERR_MSG  := 'New Card should be Starter Card for Replacement';
            V_RESP_CDE := '183';
           RAISE EXP_REJECT_RECORD;
        END IF;
      --En :Added for checking (New card)starter card flag  for replacement
      
    
      --St :Added for check new card is in inactive status
      IF V_NEW_CARD_STAT <> 0 THEN
            V_ERR_MSG  := 'Replacement Card should be in InActive status';
            V_RESP_CDE := '184';
           RAISE EXP_REJECT_RECORD;
      END IF;
      --En :Added for check new card is in inactive status

      
      --St :Added for get the applicationd details for new card
      BEGIN
      
      select ccs_card_status into v_appln_status from cms_cardissuance_status 
      where ccs_pan_code=V_NEW_HASH_PAN and ccs_inst_code=P_INST_CODE;
      
      
       EXCEPTION
         WHEN NO_DATA_FOUND THEN
           V_ERR_MSG  := 'Applcation status not found for new pan';
           V_RESP_CDE := '21';
           RAISE EXP_REJECT_RECORD;
         WHEN OTHERS THEN
           V_ERR_MSG  := 'Error while selecting data from appln status ' ||
                      SUBSTR(SQLERRM, 1, 200);
           V_RESP_CDE := '21';
           RAISE EXP_REJECT_RECORD;           
      END;
       --En :Added for get the applicationd details for new card
      
      --St added for checking application status for new card
      if v_appln_status not in('3','15') then
            V_ERR_MSG  := 'Replacement Card should be Printer sent or Shipped Status';
            V_RESP_CDE := '185';
           RAISE EXP_REJECT_RECORD;
      end if;
      --En added for checking application status for new card
     
      --St added for checking new card already is used or not
       BEGIN
      
            select count(1) INTO V_LOG_COUNT from VMSCMS.TRANSACTIONLOG_VW		--Added for VMS-5733/FSP-991
			where delivery_channel not in('05')
            and txn_code not in('07') and customer_card_no=V_NEW_HASH_PAN and instcode=P_INST_CODE;
      
            IF V_LOG_COUNT > 0 THEN
               V_ERR_MSG  := 'Replacement Card Already in use';
               V_RESP_CDE := '186';
               RAISE EXP_REJECT_RECORD;
            END IF;
            
      
       EXCEPTION      
        WHEN EXP_REJECT_RECORD THEN
        RAISE;
         WHEN OTHERS THEN
           V_ERR_MSG  := 'Error while selecting data from appln status ' ||
                      SUBSTR(SQLERRM, 1, 200);
           V_RESP_CDE := '21';
           RAISE EXP_REJECT_RECORD;           
      END;
      --En added for checking new card already is used or not
     
           BEGIN
                                    
                 SELECT CPC_CARD_ID,CPC_PROFILE_CODE
                   INTO V_CARD_ID,V_PROFILE_CODE
                   FROM CMS_PROD_CATTYPE
                   WHERE CPC_PROD_CODE=V_NEW_PROD_CODE
                     AND CPC_CARD_TYPE=V_NEW_CARD_TYPE
                     AND CPC_INST_CODE= p_inst_code;


             EXCEPTION
               WHEN OTHERS THEN
                 v_err_msg   := 'Error while selecting PROD_ID ' ||
                       SUBSTR(SQLERRM, 1, 200);
                 v_resp_cde := '21';
                RAISE exp_reject_record;
           END;     
     
     
      
  BEGIN
--    SELECT CIP_PARAM_VALUE
--     INTO V_BASE_CURR
--     FROM CMS_INST_PARAM
--    WHERE CIP_INST_CODE = P_INST_CODE AND CIP_PARAM_KEY = 'CURRENCY';

           SELECT TRIM (cbp_param_value) 
		   INTO v_base_curr 
		   FROM cms_bin_param 
            WHERE cbp_param_name = 'Currency' AND cbp_inst_code= P_INST_CODE
            AND cbp_profile_code =V_PROFILE_CODE ;

  
    IF V_BASE_CURR IS NULL THEN
     V_ERR_MSG := 'Base currency cannot be null ';
      V_RESP_CDE := '21';
     RAISE EXP_REJECT_RECORD;
    END IF;
    
     V_CURR_CODE := V_BASE_CURR;
     
  EXCEPTION
    WHEN EXP_REJECT_RECORD 
    THEN
     RAISE;
    WHEN NO_DATA_FOUND THEN
     V_ERR_MSG := 'Base currency is not defined for the BIN PROFILE ';
     V_RESP_CDE := '21';
     RAISE EXP_REJECT_RECORD;
    WHEN OTHERS THEN
     V_ERR_MSG := 'Error while selecting base currency  for bin' ||
               SUBSTR(SQLERRM, 1, 200);
     V_RESP_CDE := '21';
     RAISE EXP_REJECT_RECORD;
  END;
  
  
   
          BEGIN                                 
               sp_authorize_txn_cms_auth (P_INST_CODE,
                                        P_MSG,
                                        P_RRN,
                                        P_DELIVERY_CHANNEL,
                                        P_TERM_ID,                          --P_TERM_ID
                                        P_TXN_CODE,
                                        P_TXN_MODE,
                                        P_TRAN_DATE,
                                        P_TRAN_TIME,
                                        P_CARD_NO,
                                        P_INST_CODE,
                                        --P_TXN_AMT,                           --AMT--Commented and modified on 07.06.2013 for MVHOST-363
                                        V_TRAN_AMT,
                                        NULL,                      --MERCHANT NAME
                                        NULL,                      --MERCHANT CITY
                                        P_MCC_CODE,                         --P_MCC_CODE
                                        V_CURR_CODE,
                                        NULL,                          --P_PROD_ID
                                        NULL,                          --P_CATG_ID
                                        NULL,                          --P_TIP_AMT
                                        NULL,                       --P_TO_ACCT_NO
                                        NULL,                      --P_ATMNAME_LOC
                                        NULL,                  --P_MCCCODE_GROUPID
                                        NULL,                 --P_CURRCODE_GROUPID
                                        NULL,                --P_TRANSCODE_GROUPID
                                        NULL,                            --P_RULES
                                        NULL,                     --P_PREAUTH_DATE
                                        NULL,                   --P_CONSODIUM_CODE
                                        NULL,                     --P_PARTNER_CODE
                                        P_EXPRY_DATE,                       --P_EXPRY_DATE
                                        P_STAN,
                                        P_MBR_NUMB,
                                        P_RVSL_CODE,
                                        --P_TXN_AMT,                --P_CURR_CONVERT_AMNT --Commented and modified on 07.06.2013 for MVHOST-363
                                        V_TRAN_AMT,  
                                        P_AUTH_ID,
                                        V_RESP_CDE,
                                        V_ERR_MSG,
                                        P_CAPTURE_DATE,
                                        P_FEE_FLAG
                                       );
                                     
             IF V_RESP_CDE <> '00' AND V_ERR_MSG <> 'OK'
             THEN
                 RAISE EXP_AUTH_REJECT_RECORD;
            END IF;
    
            EXCEPTION
              WHEN EXP_AUTH_REJECT_RECORD THEN
               RAISE;            
            --Removed  EXP_REJECT_RECORD on 20/06/2013
            WHEN OTHERS THEN
               V_RESP_CDE := '21';
                V_ERR_MSG   := 'Error from Card authorization' || SUBSTR(SQLERRM, 1, 200);
              RAISE EXP_REJECT_RECORD;
         END;
        
        --Sn To audit SMS and Email Alerts changes
        BEGIN
           INSERT INTO VMS_AUDITTXN_DTLS (vad_rrn, vad_del_chnnl, vad_txn_code, vad_cust_code, vad_action_user)
                VALUES (p_rrn, p_delivery_channel, p_txn_code, v_cust_code, 1);
        EXCEPTION
           WHEN OTHERS THEN
              v_resp_cde := '21';
              v_err_msg :='Error while inserting audit dtls- ' || SUBSTR (SQLERRM, 1, 200);
              RAISE exp_reject_record;
        END;
        --En To audit SMS and Email Alerts changes     
  
        --St added for getting reissue card status
        BEGIN
         SELECT CRO_OLDCARD_REISSUE_STAT
           INTO V_CRO_OLDCARD_REISSUE_STAT
           FROM CMS_REISSUE_OLDCARDSTAT
          WHERE CRO_INST_CODE = P_INST_CODE AND
               CRO_OLDCARD_STAT = V_CAP_CARD_STAT AND CRO_SPPRT_KEY = 'R';
        EXCEPTION
         WHEN NO_DATA_FOUND THEN
           V_ERR_MSG  := 'Default old card status nor defined for institution ' 
                      ;
           V_RESP_CDE := '12';
           RAISE EXP_REJECT_RECORD;
         WHEN OTHERS THEN
           V_ERR_MSG  := 'Error while getting default old card status for institution ' ||
                      SUBSTR(SQLERRM, 1, 200);
           V_RESP_CDE := '21';
           RAISE EXP_REJECT_RECORD;
        END;
         --En added for getting reissue card status
         
           IF p_new_card_status is not null then
              v_new_card_status := p_new_card_status;
          end if;
      
          if v_new_card_status = 1 then          
            V_CRO_OLDCARD_REISSUE_STAT := 9;          
          end if;
          
          
       --St added for update the old card status
        BEGIN
        
         UPDATE CMS_APPL_PAN
            SET CAP_CARD_STAT = V_CRO_OLDCARD_REISSUE_STAT,
               CAP_LUPD_USER = P_BANK_CODE
          WHERE CAP_INST_CODE = P_INST_CODE AND CAP_PAN_CODE = V_HASH_PAN;
         IF SQL%ROWCOUNT != 1 THEN
           V_ERR_MSG  := 'Problem in updation of status for pan ' ||
                      V_HASH_PAN;
           V_RESP_CDE := '12';
           RAISE EXP_REJECT_RECORD;
         END IF;
        EXCEPTION
          WHEN EXP_REJECT_RECORD THEN
        RAISE;
         WHEN OTHERS THEN
           V_ERR_MSG  := 'Error while updating CMS_APPL_PAN' ||
                      SUBSTR(SQLERRM, 1, 200);
           V_RESP_CDE := '21';
           RAISE EXP_REJECT_RECORD;
        END;
       --En added for update the old card status
        
        
         IF v_lmtprfl IS NULL OR v_profile_level IS NULL -- Added on 30102012 Dhiraj
   THEN
      /* START   Added by Dhiraj G on 12072012 for Pre - LIMITS BRD   */
      BEGIN
         SELECT cpl_lmtprfl_id
           INTO v_lmtprfl
           FROM cms_prdcattype_lmtprfl
          WHERE cpl_inst_code = P_INST_CODE
            AND cpl_prod_code = V_NEW_PROD_CODE
            AND cpl_card_type = V_NEW_CARD_TYPE;

         v_profile_level := 2;
      EXCEPTION
         WHEN NO_DATA_FOUND
         THEN
            BEGIN
               SELECT cpl_lmtprfl_id
                 INTO v_lmtprfl
                 FROM cms_prod_lmtprfl
                WHERE cpl_inst_code = P_INST_CODE
                  AND cpl_prod_code = V_NEW_PROD_CODE;

               v_profile_level := 3;
            EXCEPTION
               WHEN NO_DATA_FOUND
               THEN
                  NULL;
               WHEN OTHERS
               THEN
                  v_resp_cde := '21';
                  v_err_msg :=
                        'Error while selecting Limit Profile At Product Level'||
                     SUBSTR(SQLERRM, 1, 200);
                  RAISE exp_reject_record;
            END;
         WHEN OTHERS
         THEN
            v_resp_cde := '21';
            v_err_msg :=
                  'Error while selecting Limit Profile At Product Catagory Level'
               || SUBSTR(SQLERRM, 1, 200);
            RAISE exp_reject_record;
      END;
   END IF;                                         -- Added on 30102012 Dhiraj

   IF v_lmtprfl IS NOT NULL
   THEN                                            -- Added on 30102012 Dhiraj
      BEGIN
         UPDATE cms_appl_pan
            SET cap_prfl_code = v_lmtprfl,
                --Added by Dhiraj G on 12072012 for  - LIMITS BRD
                cap_prfl_levl = v_profile_level
          --Added by Dhiraj G on 12072012 for  - LIMITS BRD
         WHERE  cap_inst_code = P_INST_CODE AND cap_pan_code = v_new_hash_pan;

         IF SQL%ROWCOUNT = 0
         THEN
            v_resp_cde := '21';
            v_err_msg := 'Limit Profile not updated for :' || v_hash_pan;
            RAISE exp_reject_record;
         END IF;
      EXCEPTION
         WHEN exp_reject_record
         THEN
            RAISE exp_reject_record;
         WHEN OTHERS
         THEN
            v_resp_cde := '21';
            v_err_msg :=
               'Error while Limit profile Update '
               || SUBSTR (SQLERRM, 1, 200);
            RAISE exp_reject_record;
      END;
   END IF;  
   
        --St added for update the old card status in log the card status in log table
        IF V_CRO_OLDCARD_REISSUE_STAT='9' THEN      
        BEGIN
           sp_log_cardstat_chnge (p_inst_code,
                                  v_hash_pan,
                                  v_encr_pan,
                                  p_auth_id,
                                  '02',
                                  p_rrn,
                                  p_tran_date,
                                  p_tran_time,
                                  v_resp_cde,
                                  v_err_msg
                                 );

           IF v_resp_cde <> '00' AND v_err_msg <> 'OK'
           THEN
              RAISE exp_reject_record;
           END IF;
        EXCEPTION
           WHEN exp_reject_record
           THEN
              RAISE;
           WHEN OTHERS
           THEN
              v_resp_cde := '21';
              v_err_msg :=
                    'Error while logging system initiated card status change '
                 || SUBSTR (SQLERRM, 1, 200);
              RAISE exp_reject_record;
        END;       
       END IF;    
    --En added for update the old card status
    
      
      --St added for update teh card status , account number , proxy number and cust_code of old card to new card
            BEGIN
               UPDATE cms_appl_pan
                  SET CAP_CARD_STAT = v_new_card_status,cap_cust_code = v_cust_code ,
                  cap_acct_no= v_acct_number,cap_acct_id=v_acct_id,
                  cap_proxy_number= v_proxunumber,
               CAP_LUPD_USER = P_BANK_CODE , cap_repl_flag = 1 ,
               cap_bill_addr=V_BILL_ADDR , cap_appl_code= v_appl_code
                WHERE cap_inst_code = p_inst_code AND cap_pan_code = V_NEW_HASH_PAN;

               IF SQL%ROWCOUNT = 0 
               THEN
                  v_err_msg :=
                        'Problem in updation of replacement flag for pan '
                     || fn_mask (new_card_no, 'X', 7, 6);
                  v_resp_cde := '21';
                  RAISE exp_reject_record;
               END IF;
            EXCEPTION
              WHEN EXP_REJECT_RECORD THEN
                 RAISE;
               WHEN OTHERS
               THEN
                  v_err_msg :=
                          'Error while updating CMS_APPL_PAN' || SUBSTR (SQLERRM, 1, 200);
                  v_resp_cde := '21';
                  RAISE exp_reject_record;
            END;      
       
      --En added for update teh card status , account number , proxy number and cust_code of old card to new card 
      
      --St addd for application status for new card status is 1 only
        if v_new_card_status =1 then
            BEGIN
              UPDATE CMS_APPL_PAN
               SET CAP_FIRSTTIME_TOPUP='Y' , CAP_ACTIVE_DATE=sysdate --Added for defect id :11450 on 04/06/2013
               WHERE CAP_INST_CODE = p_inst_code AND CAP_PAN_CODE = V_NEW_HASH_PAN ;
                          
                 IF SQL%ROWCOUNT !=1 THEN
                 
                  v_resp_cde := '21';
                  v_err_msg   := 'Problem in updation of first time topup flag'||SUBSTR(SQLERRM, 1, 200);
                  RAISE exp_reject_record;
                          
                 END IF;
          EXCEPTION
                      
              WHEN exp_reject_record THEN
                 RAISE;
                
             WHEN OTHERS THEN
                v_resp_cde := '21';
                v_err_msg   := 'Error ocurs while updating first time topup flag ' ||
                                   SUBSTR(SQLERRM, 1, 200);
                RAISE exp_reject_record;
                         
             
          END;   
                      
           


       --  IF V_PROD_ID is NOT NULL THEN         COMMENTED FOR PACKAGE ID /PROD ID IMPACT CHANGES.
            IF  V_CARD_ID IS NOT NULL THEN

             BEGIN
               UPDATE CMS_CARDISSUANCE_STATUS
               SET CCS_CARD_STATUS='15'
               WHERE CCS_PAN_CODE=V_NEW_HASH_PAN
               AND CCS_INST_CODE=p_inst_code;
               
                IF SQL%ROWCOUNT =0 THEN
                 
                  v_resp_cde := '21';
                  v_err_msg   := 'Updation not happen for  KYC  flag.';
                  RAISE exp_reject_record;
                          
                END IF;
                 
             EXCEPTION
             WHEN exp_reject_record THEN
             RAISE;
              WHEN OTHERS THEN
                    v_resp_cde := '21';
                    v_err_msg   := 'Error ocurs while updating applicationn status ' ||
                                   SUBSTR(SQLERRM, 1, 200);
                    RAISE exp_reject_record;
             END;
             
         END IF;
        
        end if;
        
     
    IF V_ERR_MSG = 'OK' THEN
     
         BEGIN
           INSERT INTO CMS_HTLST_REISU
            (CHR_INST_CODE,
             CHR_PAN_CODE,
             CHR_MBR_NUMB,
             CHR_NEW_PAN,
             CHR_NEW_MBR,
             CHR_REISU_CAUSE,
             CHR_INS_USER,
             CHR_LUPD_USER,
             CHR_PAN_CODE_ENCR,
             CHR_NEW_PAN_ENCR,            
             CHR_INS_DATE)
           VALUES
            (P_INST_CODE,
             V_HASH_PAN,
             P_MBR_NUMB,
             V_NEW_HASH_PAN,
             P_MBR_NUMB,
             'R',
             P_BANK_CODE,
             P_BANK_CODE,
             V_ENCR_PAN,
             V_NEW_ENCR_PAN,            
             sysdate);
         EXCEPTION
           --excp of begin 4
           WHEN OTHERS THEN
            V_ERR_MSG  := 'Error while creating  reissuue record ' ||
                        SUBSTR(SQLERRM, 1, 200);
            V_RESP_CDE := '21';
            RAISE EXP_REJECT_RECORD;
         END;
        
        --St: Added for Defect id : 11745 on 25-07-2013 for getting sms and email details of Old card
         BEGIN
         
                SELECT CSA_CELLPHONECARRIER ,CSA_LOADORCREDIT_FLAG,CSA_LOWBAL_FLAG,CSA_LOWBAL_AMT,CSA_NEGBAL_FLAG,CSA_HIGHAUTHAMT,
                 CSA_HIGHAUTHAMT_FLAG,CSA_DAILYBAL_FLAG,CSA_BEGIN_TIME,CSA_END_TIME ,CSA_INSUFF_FLAG,CSA_INCORRPIN_FLAG,
                 CSA_FAST50_FLAG,CSA_FEDTAX_REFUND_FLAG,CSA_DEPPENDING_FLAG, CSA_DEPACCEPTED_FLAG,CSA_DEPREJECTED_FLAG, -- Added on 19-09-2013 for JH-6
                 CSA_ALERT_LANG_ID --Added for FWR-59
                 INTO V_CELLPHONECARRIER,V_LOADORCREDIT_FLAG,V_LOWBAL_FLAG,V_LOWBAL_AMT,V_NEGBAL_FLAG,V_HIGHAUTHAMT,
                 V_HIGHAUTHAMT_FLAG,V_DAILYBAL_FLAG,V_BEGIN_TIME,V_END_TIME,V_INSUFF_FLAG,V_INCORRPIN_FLAG,
                 V_FAST50_FLAG,V_FEDERAL_STATE_FLAG, -- Added on 19-09-2013 for JH-6
                 V_CHK_DEP_PENDING_FLAG,V_CHK_DEP_ACCEPTED_FLAG,V_CHK_DEP_REJECTED_FLAG,  -- Added by Raja Gopal G on 30/07/2014 fro FR 3.2
                 L_ALERT_LANG_ID  --Added for FWR-59
                 FROM CMS_SMSANDEMAIL_ALERT
                 WHERE CSA_INST_CODE = P_INST_CODE AND CSA_PAN_CODE = V_HASH_PAN;
                 
           EXCEPTION
           WHEN NO_DATA_FOUND THEN
              V_ERR_MSG  := 'No data found in sms and email details for old card';
              V_RESP_CDE := '12';
           RAISE EXP_REJECT_RECORD;
           WHEN OTHERS THEN
              V_ERR_MSG  := 'Error while selecting sms and email details ' ||SUBSTR(SQLERRM, 1, 200);
              V_RESP_CDE := '21';
            RAISE EXP_REJECT_RECORD;
       END;
      --En: Added for Defect id : 11745 on 25-07-2013 for getting sms and email details of Old card     
           
      --St: Added for Defect id : 11745 on 25-07-2013 for updating sms and email alert details To New card
        BEGIN
        
            UPDATE CMS_SMSANDEMAIL_ALERT 
            SET CSA_CELLPHONECARRIER=NVL(V_CELLPHONECARRIER, 0), CSA_LOADORCREDIT_FLAG=V_LOADORCREDIT_FLAG,
                CSA_LOWBAL_FLAG=V_LOWBAL_FLAG,CSA_LOWBAL_AMT=NVL(V_LOWBAL_AMT, 0),
                CSA_NEGBAL_FLAG=V_NEGBAL_FLAG,CSA_HIGHAUTHAMT_FLAG=V_HIGHAUTHAMT_FLAG,
                CSA_HIGHAUTHAMT=NVL(V_HIGHAUTHAMT, 0), CSA_DAILYBAL_FLAG=V_DAILYBAL_FLAG,
                CSA_BEGIN_TIME=V_BEGIN_TIME, CSA_END_TIME=V_END_TIME,
                CSA_INSUFF_FLAG=V_INSUFF_FLAG, CSA_INCORRPIN_FLAG=V_INCORRPIN_FLAG,
                CSA_FAST50_FLAG=V_FAST50_FLAG,CSA_FEDTAX_REFUND_FLAG=V_FEDERAL_STATE_FLAG, -- Added on 19-09-2013 for JH-6
                CSA_DEPPENDING_FLAG = V_CHK_DEP_PENDING_FLAG,CSA_DEPACCEPTED_FLAG = V_CHK_DEP_ACCEPTED_FLAG,
                CSA_DEPREJECTED_FLAG = V_CHK_DEP_REJECTED_FLAG,
                CSA_LUPD_USER=P_BANK_CODE,CSA_LUPD_DATE=SYSDATE,
                CSA_ALERT_LANG_ID=L_ALERT_LANG_ID  --Added for FWR-59
                WHERE CSA_INST_CODE = P_INST_CODE AND CSA_PAN_CODE = V_NEW_HASH_PAN;
                
      ----En: Added for Defect id : 11745 on 25-07-2013 for updating sms and email alert details To New card
      
         /*   Comment for Defect id : 11745 on 25-07-2013
           INSERT INTO CMS_SMSANDEMAIL_ALERT
            (CSA_INST_CODE,
             CSA_PAN_CODE,
             CSA_PAN_CODE_ENCR,
             CSA_CELLPHONECARRIER,
             CSA_LOADORCREDIT_FLAG,
             CSA_LOWBAL_FLAG,
             CSA_LOWBAL_AMT,
             CSA_NEGBAL_FLAG,
             CSA_HIGHAUTHAMT_FLAG,
             CSA_HIGHAUTHAMT,
             CSA_DAILYBAL_FLAG,
             CSA_BEGIN_TIME,
             CSA_END_TIME,
             CSA_INSUFF_FLAG,
             CSA_INCORRPIN_FLAG,
             CSA_INS_USER,
             CSA_INS_DATE,
             CSA_LUPD_USER,
             CSA_LUPD_DATE)
            (SELECT P_INST_CODE,
                   V_NEW_HASH_PAN,
                   V_NEW_ENCR_PAN,
                   NVL(CSA_CELLPHONECARRIER, 0),
                   CSA_LOADORCREDIT_FLAG,
                   CSA_LOWBAL_FLAG,
                   NVL(CSA_LOWBAL_AMT, 0),
                   CSA_NEGBAL_FLAG,
                   CSA_HIGHAUTHAMT_FLAG,
                   NVL(CSA_HIGHAUTHAMT, 0),
                   CSA_DAILYBAL_FLAG,
                   NVL(CSA_BEGIN_TIME, 0),
                   NVL(CSA_END_TIME, 0),
                   CSA_INSUFF_FLAG,
                   CSA_INCORRPIN_FLAG,
                   P_BANK_CODE,
                   SYSDATE,
                   P_BANK_CODE,
                   SYSDATE
               FROM CMS_SMSANDEMAIL_ALERT
              WHERE CSA_INST_CODE = P_INST_CODE AND CSA_PAN_CODE = V_HASH_PAN);
              */
           IF SQL%ROWCOUNT = 0 THEN -- modified by Raja Gopal G on FR 3.2
            V_ERR_MSG  := 'Update not happen in CMS_SMSANDEMAIL_ALERT';  --Modified error mag on 26/06/2013
            V_RESP_CDE := '21';
            RAISE EXP_REJECT_RECORD;
           END IF;
           
         EXCEPTION
         WHEN EXP_REJECT_RECORD THEN
         RAISE;
           WHEN OTHERS THEN
            V_ERR_MSG  := 'Error while Entering sms email alert detail ' ||
                        SUBSTR(SQLERRM, 1, 200);
            V_RESP_CDE := '21';
            RAISE EXP_REJECT_RECORD;
         END;
         
    
    END IF;
    P_RESP_MSG := NEW_CARD_NO;
     
  
   
    
         IF V_RESP_CDE = '1' OR  V_RESP_CDE='00' THEN  --MODIFIEDBY ABDUL HAMEED M.A. FOR EEP2.1
         
          
           --Sn find prod code and card type and available balance for the card number
           BEGIN
            SELECT CAM_ACCT_BAL,CAM_LEDGER_BAL
              INTO V_ACCT_BALANCE,V_LEDGER_BAL
              FROM CMS_ACCT_MAST
             WHERE CAM_ACCT_NO =
                  (SELECT CAP_ACCT_NO
                    FROM CMS_APPL_PAN
                    WHERE CAP_PAN_CODE = V_HASH_PAN AND
                        CAP_MBR_NUMB = P_MBR_NUMB AND
                        CAP_INST_CODE = P_INST_CODE) AND
                  CAM_INST_CODE = P_INST_CODE
               FOR UPDATE NOWAIT;
           EXCEPTION
            WHEN NO_DATA_FOUND THEN
              V_RESP_CDE := '12'; --Ineligible Transaction
              V_ERR_MSG  := 'Invalid Card ';
              RAISE EXP_REJECT_RECORD;
            WHEN OTHERS THEN
              V_RESP_CDE := '12';
              V_ERR_MSG  := 'Error while selecting data from card Master for card number ' ||
                         SUBSTR(SQLERRM, 1, 200);
              RAISE EXP_REJECT_RECORD;
           END;
         
           --En find prod code and card type for the card number
         
         END IF;
                     
    
         --Sn Selecting Reason code for Initial Load
         BEGIN
           SELECT CSR_SPPRT_RSNCODE
            INTO V_RESONCODE
            FROM CMS_SPPRT_REASONS
            WHERE CSR_INST_CODE = P_INST_CODE AND CSR_SPPRT_KEY = 'REISSUE' AND
                ROWNUM < 2;
         
         EXCEPTION
           WHEN NO_DATA_FOUND THEN
            V_RESP_CDE := '21';
            V_ERR_MSG  := 'Order Replacement card reason code is present in master';
            RAISE EXP_REJECT_RECORD;
           WHEN OTHERS THEN
            V_RESP_CDE := '21';
            V_ERR_MSG  := 'Error while selecting reason code from master' ||
                        SUBSTR(SQLERRM, 1, 200);
            RAISE EXP_REJECT_RECORD;
         END;
    
         BEGIN
           INSERT INTO CMS_PAN_SPPRT
            (CPS_INST_CODE,
             CPS_PAN_CODE,
             CPS_MBR_NUMB,
             CPS_PROD_CATG,
             CPS_SPPRT_KEY,
             CPS_SPPRT_RSNCODE,
             CPS_FUNC_REMARK,
             CPS_INS_USER,
             CPS_LUPD_USER,
             CPS_CMD_MODE,
             CPS_PAN_CODE_ENCR)
           VALUES
            (P_INST_CODE,
             V_HASH_PAN,
             P_MBR_NUMB,
             V_CAP_PROD_CATG,
             'REISSUE',
             V_RESONCODE,
             P_REMRK,
             P_BANK_CODE,
             P_BANK_CODE,
             0,
             V_ENCR_PAN);
         EXCEPTION
           WHEN OTHERS THEN
            V_RESP_CDE := '21';
            V_ERR_MSG  := 'Error while inserting records into card support master' ||
                        SUBSTR(SQLERRM, 1, 200);
           
            RAISE EXP_REJECT_RECORD;
         END;
         --En create a record in pan spprt    
            
    
    V_RESP_CDE := '1';
  
    ---En Updation of Usage limit and amount
    BEGIN
     SELECT CMS_ISO_RESPCDE
       INTO P_RESP_CODE
       FROM CMS_RESPONSE_MAST
      WHERE CMS_INST_CODE = P_INST_CODE AND
           CMS_DELIVERY_CHANNEL = P_DELIVERY_CHANNEL AND
           CMS_RESPONSE_ID = TO_NUMBER(V_RESP_CDE);
    EXCEPTION
     WHEN OTHERS THEN
       V_ERR_MSG  := 'Problem while selecting data from response master for respose code' ||
                  V_RESP_CDE || SUBSTR(SQLERRM, 1, 300);
       V_RESP_CDE := '21';
       RAISE EXP_REJECT_RECORD;
    END;
    --0010762
    BEGIN
		--Added for VMS-5739/FSP-991
	 select (add_months(trunc(sysdate,'MM'),'-'||RETENTION_PERIOD))
		   INTO   v_Retperiod 
		   FROM DBA_OPERATIONS.ARCHIVE_MGMT_CTL 
		   WHERE  OPERATION_TYPE='ARCHIVE' 
		   AND OBJECT_NAME='TRANSACTIONLOG_EBR';
		   
		   v_Retdate := TO_DATE(SUBSTR(TRIM(P_TRAN_DATE), 1, 8), 'yyyymmdd');


	IF (v_Retdate>v_Retperiod)
		THEN
		   UPDATE TRANSACTIONLOG
			 SET MEDAGATEREF_ID=P_MEDAGATEREFID , cardstatus=V_CRO_OLDCARD_REISSUE_STAT
			WHERE RRN = P_RRN AND BUSINESS_DATE = P_TRAN_DATE AND
				TXN_CODE = P_TXN_CODE AND MSGTYPE = P_MSG AND
				BUSINESS_TIME = P_TRAN_TIME AND 
				DELIVERY_CHANNEL = P_DELIVERY_CHANNEL;
	ELSE
			UPDATE VMSCMS_HISTORY.TRANSACTIONLOG_HIST --Added for VMS-5733/FSP-991
			 SET MEDAGATEREF_ID=P_MEDAGATEREFID , cardstatus=V_CRO_OLDCARD_REISSUE_STAT
			WHERE RRN = P_RRN AND BUSINESS_DATE = P_TRAN_DATE AND
				TXN_CODE = P_TXN_CODE AND MSGTYPE = P_MSG AND
				BUSINESS_TIME = P_TRAN_TIME AND 
				DELIVERY_CHANNEL = P_DELIVERY_CHANNEL;
	END IF;			
     EXCEPTION
       WHEN OTHERS THEN
        V_RESP_CDE := '69';
        V_ERR_MSG  := 'Problem while inserting data into transaction log' ||
                    SUBSTR(SQLERRM, 1, 300);
        RAISE EXP_REJECT_RECORD;   --Added exception  on 26/06/2013
     END;
    
    --ADDED BY ABDUL
    
 P_ACCT_BAL:=V_ACCT_BALANCE;--ADDED BY ABDUL HAMEED M.A. FOR EEP2.1
 P_LEDGER_BAL:=V_LEDGER_BAL; --ADDED BY ABDUL HAMEED M.A. FOR EEP2.1
 
  EXCEPTION
    --<< MAIN EXCEPTION >>
    WHEN EXP_AUTH_REJECT_RECORD THEN
    --ROLLBACK;
  
    P_RESP_MSG    := V_ERR_MSG;
    P_RESP_CODE := V_RESP_CDE; 
    
    WHEN EXP_REJECT_RECORD THEN
     P_RESP_MSG := V_ERR_MSG;
     ROLLBACK TO V_AUTH_SAVEPOINT;
     
       
         BEGIN
           SELECT CAM_ACCT_BAL, CAM_LEDGER_BAL,
                  CAM_TYPE_CODE,CAM_ACCT_NO     -- Added on 18-Apr-2013 for defect 10871
            INTO V_ACCT_BALANCE, V_LEDGER_BAL,
                  V_CAM_TYPE_CODE,V_ACCT_NUMBER -- Added on 18-Apr-2013 for defect 10871    
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
		 --Added for VMS-5739/FSP-991
	 select (add_months(trunc(sysdate,'MM'),'-'||RETENTION_PERIOD))
		   INTO   v_Retperiod 
		   FROM DBA_OPERATIONS.ARCHIVE_MGMT_CTL 
		   WHERE  OPERATION_TYPE='ARCHIVE' 
		   AND OBJECT_NAME='TRANSACTIONLOG_EBR';
		   
		   v_Retdate := TO_DATE(SUBSTR(TRIM(P_TRAN_DATE), 1, 8), 'yyyymmdd');


	IF (v_Retdate>v_Retperiod)
		THEN
			   UPDATE TRANSACTIONLOG
				 SET MEDAGATEREF_ID=P_MEDAGATEREFID
				WHERE RRN = P_RRN AND BUSINESS_DATE = P_TRAN_DATE AND
					TXN_CODE = P_TXN_CODE AND MSGTYPE = P_MSG AND
					BUSINESS_TIME = P_TRAN_TIME AND
					DELIVERY_CHANNEL = P_DELIVERY_CHANNEL;
	ELSE
				UPDATE VMSCMS_HISTORY.TRANSACTIONLOG_HIST --Added for VMS-5733/FSP-991
				 SET MEDAGATEREF_ID=P_MEDAGATEREFID
				WHERE RRN = P_RRN AND BUSINESS_DATE = P_TRAN_DATE AND
					TXN_CODE = P_TXN_CODE AND MSGTYPE = P_MSG AND
					BUSINESS_TIME = P_TRAN_TIME AND
					DELIVERY_CHANNEL = P_DELIVERY_CHANNEL;
	END IF;				
         EXCEPTION
           WHEN OTHERS THEN
            V_RESP_CDE := '69';
            V_ERR_MSG  := 'Problem while inserting data into transaction log  dtl' ||
                        SUBSTR(SQLERRM, 1, 300);
         END;
         
       
         
         --Sn select response code and insert record into txn log dtl
         BEGIN
           P_RESP_CODE := V_RESP_CDE;
           P_RESP_MSG  := V_ERR_MSG;
           -- Assign the response code to the out parameter
           SELECT CMS_ISO_RESPCDE
            INTO P_RESP_CODE
            FROM CMS_RESPONSE_MAST
            WHERE CMS_INST_CODE = P_INST_CODE AND
                CMS_DELIVERY_CHANNEL = P_DELIVERY_CHANNEL AND
                CMS_RESPONSE_ID = V_RESP_CDE;
         EXCEPTION
           WHEN OTHERS THEN
            P_RESP_MSG  := 'Problem while selecting data from response master ' ||
                        V_RESP_CDE || SUBSTR(SQLERRM, 1, 300);
            P_RESP_CODE := '69';
            ---ISO MESSAGE FOR DATABASE ERROR Server Declined
            ROLLBACK;
         END;
     
    
         BEGIN
           IF V_RRN_COUNT > 0 THEN
            IF TO_NUMBER(P_DELIVERY_CHANNEL) = 8 THEN
              BEGIN
                SELECT RESPONSE_CODE
                 INTO V_RESP_CDE
                 FROM VMSCMS.TRANSACTIONLOG_VW  A,		--Added for VMS-5733/FSP-991
                     (SELECT MIN(ADD_INS_DATE) MINDATE
                        FROM VMSCMS.TRANSACTIONLOG_VW --Added for VMS-5733/FSP-991
                       WHERE RRN = P_RRN) B
                WHERE A.ADD_INS_DATE = MINDATE AND RRN = P_RRN;
              
                P_RESP_CODE := V_RESP_CDE;
                SELECT CAM_ACCT_BAL
                 INTO V_ACCT_BALANCE
                 FROM CMS_ACCT_MAST
                WHERE CAM_ACCT_NO =
                     (SELECT CAP_ACCT_NO
                        FROM CMS_APPL_PAN
                       WHERE CAP_PAN_CODE = V_HASH_PAN AND
                            CAP_MBR_NUMB = P_MBR_NUMB AND
                            CAP_INST_CODE = P_INST_CODE) AND
                     CAM_INST_CODE = P_INST_CODE
                  FOR UPDATE NOWAIT;
                V_ERR_MSG := TO_CHAR(V_ACCT_BALANCE);
              
              EXCEPTION
                WHEN OTHERS THEN
                
                 V_ERR_MSG   := 'Problem in selecting the response detail of Original transaction' ||
                             SUBSTR(SQLERRM, 1, 300);
                 P_RESP_CODE := '89'; -- Server Declined
                 ROLLBACK;
                 RETURN;
              END;
            
            END IF;
           END IF;
         END;

      
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
             CTD_CUST_ACCT_NUMBER)
           VALUES
            (P_DELIVERY_CHANNEL,
             P_TXN_CODE,
             V_TXN_TYPE,
             P_MSG,
             P_TXN_MODE,
             P_TRAN_DATE,
             P_TRAN_TIME,
             V_HASH_PAN,
            -- P_TXN_AMT, --Commented and modified on 07.06.2013 for MVHOST-363
             V_TRAN_AMT,
             V_CURR_CODE,
             V_TRAN_AMT,
             NULL,
             NULL,
             NULL,
             NULL,
             V_TOTAL_AMT,
             V_CARD_CURR,
             'E',
             V_ERR_MSG,
             P_RRN,
             P_STAN,
             P_INST_CODE,
             V_ENCR_PAN,
             V_ACCT_NUMBER);
         
           P_RESP_MSG := V_ERR_MSG;
         EXCEPTION
           WHEN OTHERS THEN
            P_RESP_MSG  := 'Problem while inserting data into transaction log  dtl' ||
                        SUBSTR(SQLERRM, 1, 300);
            P_RESP_CODE := '69'; -- Server Declined
            ROLLBACK;
            RETURN;
         END;
    
     -----------------------------------------------
     --SN: Added on 18-Apr-2013 for defect 10871
     -----------------------------------------------     
     
         v_timestamp := systimestamp;         -- Added on 18-Apr-2013 for defect 10871
     
         IF V_PROD_CODE IS NULL THEN  --Added by Pankaj S. during logging changes(Mantis ID-13160)
         BEGIN
         
             SELECT CAP_PROD_CODE,
                    CAP_CARD_TYPE,
                    CAP_CARD_STAT,
                    CAP_ACCT_NO
               INTO V_PROD_CODE,
                    V_PROD_CATTYPE,
                    V_APPLPAN_CARDSTAT,
                    V_ACCT_NUMBER
               FROM CMS_APPL_PAN
              WHERE CAP_INST_CODE = P_INST_CODE AND CAP_PAN_CODE = V_HASH_PAN; --P_card_no;
         EXCEPTION 
         WHEN OTHERS THEN
          
         NULL; 

         END;
         END IF;
          
     -----------------------------------------------
     --EN: Added on 18-Apr-2013 for defect 10871
     -----------------------------------------------
     
     --Sn Added by Pankaj S. for logging changes(Mantis ID-13160)
     IF V_DR_CR_FLAG IS NULL THEN
        BEGIN
           SELECT ctm_credit_debit_flag,
                  TO_NUMBER (DECODE (ctm_tran_type, 'N', '0', 'F', '1')),
                  ctm_tran_type
             INTO v_dr_cr_flag,
                  v_txn_type,
                  v_tran_type
             FROM cms_transaction_mast
            WHERE ctm_tran_code = p_txn_code
              AND ctm_delivery_channel = p_delivery_channel
              AND ctm_inst_code = p_inst_code;
        EXCEPTION
           WHEN OTHERS
           THEN
              NULL;
        END;     
     END IF;                   
     --En Added by Pankaj S. for logging changes(Mantis ID-13160)

    --Sn create a entry in txn log
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
          ADDCHARGE,
          PRODUCTID,
          CATEGORYID,
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
          TRANFEE_AMT,
          SERVICETAX_AMT,
          CESS_AMT,
          CR_DR_FLAG,
          TRANFEE_CR_ACCTNO,
          TRANFEE_DR_ACCTNO,
          TRAN_ST_CALC_FLAG,
          TRAN_CESS_CALC_FLAG,
          TRAN_ST_CR_ACCTNO,
          TRAN_ST_DR_ACCTNO,
          TRAN_CESS_CR_ACCTNO,
          TRAN_CESS_DR_ACCTNO,
          CUSTOMER_CARD_NO_ENCR,
          TOPUP_CARD_NO_ENCR,
          PROXY_NUMBER,
          REVERSAL_CODE,
          CUSTOMER_ACCT_NO,
          ACCT_BALANCE,
          LEDGER_BALANCE,
          RESPONSE_ID,
          MEDAGATEREF_ID,
          CARDSTATUS, --Added cardstatus insert in transactionlog by srinivasu.k
          FEE_PLAN, --Added by Deepa for Fee Plan on June 10 2012
          CSR_ACHACTIONTAKEN,
          error_msg,
          PROCESSES_FLAG,
          ACCT_TYPE,         -- Added on 18-Apr-2013 for defect 10871
          TIME_STAMP         -- Added on 18-Apr-2013 for defect 10871
          )
        VALUES
         (P_MSG,
          P_RRN,
          P_DELIVERY_CHANNEL,
          P_TERM_ID,
          V_BUSINESS_DATE,
          P_TXN_CODE,
          V_TXN_TYPE,
          P_TXN_MODE,
          DECODE(P_RESP_CODE, '00', 'C', 'F'),
          P_RESP_CODE,
          P_TRAN_DATE,
          SUBSTR(P_TRAN_TIME, 1, 10),
          V_HASH_PAN,
          NULL,
          NULL, --P_topup_acctno    ,
          NULL, --P_topup_accttype,
          P_BANK_CODE,
          TRIM(TO_CHAR(NVL(V_TOTAL_AMT,0), '99999999999999990.99')),  -- NVL added on 18-Apr-2013 for defect 10871 , 99999999999999999.99 changed to 99999999999999990.99
          '',
          '',
          P_MCC_CODE,
          V_CURR_CODE,
          NULL, -- P_add_charge,
          V_PROD_CODE,
          V_PROD_CATTYPE,
          0,                                -- NULL replaced by 0,on 18-Apr-2013 for defect 10871
          '',
          '',
          V_AUTH_ID,
          V_NARRATION,
          TRIM(TO_CHAR(NVL(V_TRAN_AMT,0), '99999999999999990.99')),   -- NVL added on 18-Apr-2013 for defect 10871, 99999999999999999.99 changed to 99999999999999990.99
          '0.00',   -- NULL replaced by 0.00 , on 18-Apr-2013 for defect 10871
          '0.00', -- Partial amount (will be given for partial txn)  -- NULL replaced by 0.00 , on 18-Apr-2013 for defect 10871
          '',
          '',
          '',
          '',
          '',
          V_GL_UPD_FLAG,
          P_STAN,
          P_INST_CODE,
          V_FEE_CODE,
          NVL(V_FEE_AMT,0),
          NVL(V_SERVICETAX_AMOUNT,0),
          NVL(V_CESS_AMOUNT,0),
          V_DR_CR_FLAG,
          V_FEE_CRACCT_NO,
          V_FEE_DRACCT_NO,
          V_ST_CALC_FLAG,
          V_CESS_CALC_FLAG,
          V_ST_CRACCT_NO,
          V_ST_DRACCT_NO,
          V_CESS_CRACCT_NO,
          V_CESS_DRACCT_NO,
          V_ENCR_PAN,
          NULL,
          V_PROXUNUMBER,
          P_RVSL_CODE,
          V_ACCT_NUMBER,
          NVL(V_ACCT_BALANCE,0),
          NVL(V_LEDGER_BAL,0),
          V_RESP_CDE,
          P_MEDAGATEREFID,
          V_APPLPAN_CARDSTAT, --Added cardstatus insert in transactionlog by srinivasu.k
          V_FEE_PLAN, --Added by Deepa for Fee Plan on June 10 2012
          P_FEE_FLAG,
          V_ERR_MSG,
          'E',
           v_cam_type_code,   -- Added on 18-Apr-2013 for defect 10871
           v_timestamp        -- Added on 18-Apr-2013 for defect 10871          
          );
      
        P_CAPTURE_DATE := V_BUSINESS_DATE;
        P_AUTH_ID      := V_AUTH_ID;
      EXCEPTION
        WHEN OTHERS THEN
         ROLLBACK;
         P_RESP_CODE := '69'; -- Server Declione
         P_RESP_MSG  := 'Problem while inserting data into transaction log  ' ||
                     SUBSTR(SQLERRM, 1, 300);
         return;             
      END;

      --En create a entry in txn log         
         
  WHEN OTHERS THEN
  ROLLBACK TO V_AUTH_SAVEPOINT;
  

         BEGIN
           SELECT CAM_ACCT_BAL, CAM_LEDGER_BAL,
                  CAM_TYPE_CODE,CAM_ACCT_NO     -- Added on 18-Apr-2013 for defect 10871
            INTO V_ACCT_BALANCE, V_LEDGER_BAL,
                  V_CAM_TYPE_CODE,V_ACCT_NUMBER -- Added on 18-Apr-2013 for defect 10871    
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

    
     
    
       --Sn select response code and insert record into txn log dtl
         BEGIN
           SELECT CMS_ISO_RESPCDE
            INTO P_RESP_CODE
            FROM CMS_RESPONSE_MAST
            WHERE CMS_INST_CODE = P_INST_CODE AND
                CMS_DELIVERY_CHANNEL = P_DELIVERY_CHANNEL AND
                CMS_RESPONSE_ID = V_RESP_CDE;
         
           P_RESP_MSG := V_ERR_MSG;
         EXCEPTION
           WHEN OTHERS THEN
            P_RESP_MSG  := 'Problem while selecting data from response master ' ||
                        V_RESP_CDE || SUBSTR(SQLERRM, 1, 300);
            P_RESP_CODE := '69'; -- Server Declined
            ROLLBACK;
            -- RETURN;
         END;
       
    
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
             CTD_CUST_ACCT_NUMBER)
           VALUES
            (P_DELIVERY_CHANNEL,
             P_TXN_CODE,
             V_TXN_TYPE,
             P_MSG,
             P_TXN_MODE,
             P_TRAN_DATE,
             P_TRAN_TIME,
             V_HASH_PAN,
             --P_TXN_AMT,--Commented and modified on 07.06.2013 for MVHOST-363
             V_TRAN_AMT,
             V_CURR_CODE,
             V_TRAN_AMT,
             NULL,
             NULL,
             NULL,
             NULL,
             V_TOTAL_AMT,
             V_CARD_CURR,
             'E',
             V_ERR_MSG,
             P_RRN,
             P_STAN,
             P_INST_CODE,
             V_ENCR_PAN,
             V_ACCT_NUMBER);
         EXCEPTION
           WHEN OTHERS THEN
            P_RESP_MSG  := 'Problem while inserting data into transaction log  dtl' ||
                        SUBSTR(SQLERRM, 1, 300);
            P_RESP_CODE := '69'; -- Server Decline Response 220509
            ROLLBACK;
            RETURN;
         END;
         --En select response code and insert record into txn log dtl
         
    -----------------------------------------------
     --SN: Added on 18-Apr-2013 for defect 10871
     -----------------------------------------------     
     
         v_timestamp := systimestamp;         -- Added on 18-Apr-2013 for defect 10871
         IF V_PROD_CODE IS NULL THEN  --Added by Pankaj S. during logging changes(Mantis ID-13160)
         BEGIN
         
             SELECT CAP_PROD_CODE,
                    CAP_CARD_TYPE,
                    CAP_CARD_STAT,
                    CAP_ACCT_NO
               INTO V_PROD_CODE,
                    V_PROD_CATTYPE,
                    V_APPLPAN_CARDSTAT,
                    V_ACCT_NUMBER
               FROM CMS_APPL_PAN
              WHERE CAP_INST_CODE = P_INST_CODE AND CAP_PAN_CODE = V_HASH_PAN; --P_card_no;
         EXCEPTION 
         WHEN OTHERS THEN
          
         NULL; 

         END;
         END IF;
              
      

     -----------------------------------------------
     --EN: Added on 18-Apr-2013 for defect 10871
     -----------------------------------------------         
     
          --Sn Added by Pankaj S. for logging changes(Mantis ID-13160)
     IF V_DR_CR_FLAG IS NULL THEN
        BEGIN
           SELECT ctm_credit_debit_flag,
                  TO_NUMBER (DECODE (ctm_tran_type, 'N', '0', 'F', '1')),
                  ctm_tran_type
             INTO v_dr_cr_flag,
                  v_txn_type,
                  v_tran_type
             FROM cms_transaction_mast
            WHERE ctm_tran_code = p_txn_code
              AND ctm_delivery_channel = p_delivery_channel
              AND ctm_inst_code = p_inst_code;
        EXCEPTION
           WHEN OTHERS
           THEN
              NULL;
        END;     
     END IF;                   
     --En Added by Pankaj S. for logging changes(Mantis ID-13160)
     
    --Sn create a entry in txn log
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
          ADDCHARGE,
          PRODUCTID,
          CATEGORYID,
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
          TRANFEE_AMT,
          SERVICETAX_AMT,
          CESS_AMT,
          CR_DR_FLAG,
          TRANFEE_CR_ACCTNO,
          TRANFEE_DR_ACCTNO,
          TRAN_ST_CALC_FLAG,
          TRAN_CESS_CALC_FLAG,
          TRAN_ST_CR_ACCTNO,
          TRAN_ST_DR_ACCTNO,
          TRAN_CESS_CR_ACCTNO,
          TRAN_CESS_DR_ACCTNO,
          CUSTOMER_CARD_NO_ENCR,
          TOPUP_CARD_NO_ENCR,
          PROXY_NUMBER,
          REVERSAL_CODE,
          CUSTOMER_ACCT_NO,
          ACCT_BALANCE,
          LEDGER_BALANCE,
          RESPONSE_ID,
          MEDAGATEREF_ID,
          CARDSTATUS, --Added cardstatus insert in transactionlog by srinivasu.k
          FEE_PLAN, --Added by Deepa for Fee Plan on June 10 2012
          CSR_ACHACTIONTAKEN,
          ERROR_MSG,
          PROCESSES_FLAG,
          ACCT_TYPE,        -- Added on 18-Apr-2013 for defect 10871
          TIME_STAMP        -- Added on 18-Apr-2013 for defect 10871     
          )
        VALUES
         (P_MSG,
          P_RRN,
          P_DELIVERY_CHANNEL,
          P_TERM_ID,
          V_BUSINESS_DATE,
          P_TXN_CODE,
          V_TXN_TYPE,
          P_TXN_MODE,
          DECODE(P_RESP_CODE, '00', 'C', 'F'),
          P_RESP_CODE,
          P_TRAN_DATE,
          SUBSTR(P_TRAN_TIME, 1, 10),
          V_HASH_PAN,
          NULL,
          NULL, --P_topup_acctno    ,
          NULL, --P_topup_accttype,
          P_BANK_CODE,
          TRIM(TO_CHAR(NVL(V_TOTAL_AMT,0), '99999999999999999.99')),    -- NVL added on 18-Apr-2013 for defect 10871
          '',
          '',
          P_MCC_CODE,
          V_CURR_CODE,
          NULL, -- P_add_charge,
          V_PROD_CODE,
          V_PROD_CATTYPE,
          0,                -- NULL replaced by 0,on 18-Apr-2013 for defect 10871
          '',
          '',
          V_AUTH_ID,
          V_NARRATION,
          TRIM(TO_CHAR(NVL(V_TRAN_AMT,0), '99999999999999999.99')),      -- NVL added on 18-Apr-2013 for defect 10871
          '0.00', -- NULL replaced by 0.00 , on 18-Apr-2013 for defect 10871
          '0.00', -- Partial amount (will be given for partial txn) -- NULL replaced by 0.00 , on 18-Apr-2013 for defect 10871
          '',
          '',
          '',
          '',
          '',
          V_GL_UPD_FLAG,
          P_STAN,
          P_INST_CODE,
          V_FEE_CODE,
          NVL(V_FEE_AMT,0),             -- NVL added on 18-Apr-2013 for defect 10871
          NVL(V_SERVICETAX_AMOUNT,0),   -- NVL added on 18-Apr-2013 for defect 10871
          NVL(V_CESS_AMOUNT,0),         -- NVL added on 18-Apr-2013 for defect 10871
          V_DR_CR_FLAG,
          V_FEE_CRACCT_NO,
          V_FEE_DRACCT_NO,
          V_ST_CALC_FLAG,
          V_CESS_CALC_FLAG,
          V_ST_CRACCT_NO,
          V_ST_DRACCT_NO,
          V_CESS_CRACCT_NO,
          V_CESS_DRACCT_NO,
          V_ENCR_PAN,
          NULL,
          V_PROXUNUMBER,
          P_RVSL_CODE,
          V_ACCT_NUMBER,
          NVL(V_ACCT_BALANCE,0),    -- NVL added on 18-Apr-2013 for defect 10871
          NVL(V_LEDGER_BAL,0),      -- NVL added on 18-Apr-2013 for defect 10871
          V_RESP_CDE,
          P_MEDAGATEREFID,
          V_APPLPAN_CARDSTAT, --Added cardstatus insert in transactionlog by srinivasu.k
          V_FEE_PLAN, --Added by Deepa for Fee Plan on June 10 2012
          P_FEE_FLAG,
          V_ERR_MSG,
          'E',
          v_cam_type_code,   -- Added on 18-Apr-2013 for defect 10871
          v_timestamp        -- Added on 18-Apr-2013 for defect 10871   
          );
      
        P_CAPTURE_DATE := V_BUSINESS_DATE;
        P_AUTH_ID      := V_AUTH_ID;
      EXCEPTION
        WHEN OTHERS THEN
         ROLLBACK;
         P_RESP_CODE := '69'; -- Server Declione
         P_RESP_MSG  := 'Problem while inserting data into transaction log  ' ||
                     SUBSTR(SQLERRM, 1, 300);
         return;             
                     
      END;

      --En create a entry in txn log         
  
      
END;
EXCEPTION
  WHEN OTHERS THEN
    ROLLBACK;
    P_RESP_CODE := '69'; -- Server Declined
    P_RESP_MSG  := 'Main exception from  authorization ' ||
                SUBSTR(SQLERRM, 1, 300);
END;
/
SHOW ERROR;