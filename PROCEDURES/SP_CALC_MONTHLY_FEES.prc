CREATE OR REPLACE PROCEDURE VMSCMS.SP_CALC_MONTHLY_FEES (P_INSTCODE IN NUMBER,
                                        P_LUPDUSER IN NUMBER,
                                        P_ERRMSG   OUT VARCHAR2) AS

V_DEBIT_AMNT NUMBER;
V_FEE_AMOUNT  CMS_FEE_MAST.CFM_FEE_AMT%TYPE; --Modified for FWR-11
V_ERR_MSG    VARCHAR2(900) := 'OK';
EXP_REJECT_RECORD EXCEPTION;
V_MONFEE_CARDCNT NUMBER;
V_WAIVAMT        NUMBER;
V_CPW_WAIV_PRCNT NUMBER;
V_FEEAMT         NUMBER;
V_UPD_REC_CNT    NUMBER := 0;
V_RRN1           NUMBER(10) DEFAULT 0;
V_RRN2           VARCHAR2(15);
V_CFM_FEE_AMT    NUMBER(15, 2);
V_WAIV_FLAG     VARCHAR2(1 BYTE); --Added for JH-13
v_cam_type_code    cms_acct_mast.cam_type_code%type; -- added on 17-apr-2013 for defect 10871
v_timestamp        timestamp;                         -- Added on 17-Apr-2013 for defect 10871
V_DR_CR_FLAG       CMS_TRANSACTION_MAST.CTM_CREDIT_DEBIT_FLAG%type;
V_NEXT_MB_DATE     CMS_APPL_PAN.CAP_NEXT_MB_DATE%TYPE; -- Added for Defect HOST-328
v_card_cnt         NUMBER;  --Added on 03.09.2013 for DFCHOST-340
v_prdcatg_cnt      NUMBER;--Added on 03.09.2013 for DFCHOST-340
v_txn_mode         CMS_FUNC_MAST.CFM_TXN_MODE%TYPE DEFAULT '0';
v_delivery_channel CMS_FUNC_MAST.CFM_DELIVERY_CHANNEL%TYPE DEFAULT '05';
v_txn_code         CMS_FUNC_MAST.CFM_TXN_CODE%TYPE DEFAULT '16';
v_business_date      VARCHAR2 (10);
v_business_time      VARCHAR2 (10);
v_auth_id            transactionlog.auth_id%TYPE;
v_tran_desc          cms_transaction_mast.ctm_tran_desc%TYPE;
v_acct_bal           cms_acct_mast.cam_acct_bal%TYPE;
v_ledger_bal         cms_acct_mast.cam_ledger_bal%TYPE;
v_first_load_date        cms_acct_mast.cam_first_load_date%TYPE;
v_monthlyfee_counter     cms_acct_mast.cam_monthlyfee_counter%TYPE;
v_month_diff             NUMBER;
v_free_txn               VARCHAR(2);
v_tot_clwbck_count CMS_FEE_MAST.cfm_clawback_count%TYPE; -- Added for FWR 64
V_CHRG_DTL_CNT    number;     -- Added for FWR 64
V_COUNT          NUMBER;
v_old_active_date  cms_appl_pan.cap_active_date%TYPE;
old_next_mb_date   cms_appl_pan.cap_next_mb_date%TYPE;
v_max_validto    DATE;   --Added for multiple monthly fee issue
V_FEE_FLAG		VARCHAR2(1); 	--/* Added for VMS-2183 State Restriction logic for monthly fee calculation*/ 




/******************************************************************************************************
      * Created By      :  Besky
      * Created Date    :  20-June-2012
      * Purpose         :  Fee changes
      * Modified By     :  Deepa T
      * Modified Date   :  22--OCT-2012
      * Modified Reason :  To log the Fee details in transactionlog,cms_tarnsaction_log_dtl table.
      * Reviewer        : Saravanakumar
      * Reviewed Date   : 31-OCT-12
      * Build Number    : CMS3.5.1_RI0021_B0001

      * Modified By      : Sagar M.
      * Modified Date    : 17-Apr-2013
      * Modified for     : Defect 10871
      * Modified Reason  : Logging of below details in tranasctionlog and statementlog table
                           1) ledger balance in statementlog
                           2) Product code,Product category code,Card status,Acct Type,drcr flag
                           3) Timestamp and Amount values logging correction
     * Reviewer         : Dhiraj
     * Reviewed Date    : 17-Apr-2013
     * Build Number     : RI0024.1_B0010

     * Modified By      : Sagar M.
     * Modified reason  : To handle fee calculation incase of scheduler fails
     * Modified for     : HOST-328
     * Modified On      : 27-May-2013
     * Reviewer         : Dhiraj
     * Reviewed Date    :
     * Build Number     : RI0024.1.3_B0002

     * Modified By      : Sai Prasad.
     * Modified reason  : To handle fee calculation for existing monthly fee issue inventory cards.
     * Modified for     : HOST-328
     * Modified On      : 07-Jun-2013
     * Reviewer         : Dhiraj
     * Reviewed Date    : 07-Jun-2013
     * Build Number     : RI0024.1.3_B0003

     * Modified By      : Sai Prasad K S
     * Modified Date    : 16-Aug-2013
     * Modified Reason  : FWR-11
     * Reviewer         : Dhiraj
     * Reviewed Date    : 16-Aug-2013
     * Build Number     : RI0024.4_B0004

     * Modified By      : RAVI N.
     * Modified reason  : TransFee logging in transactionlog since Enable clawback fee.
     * Modified for     : DFCCSD-84
     * Modified On      : 03-SEP-2013
     * Reviewer         : Dhiraj
     * Reviewed Date    : 03-SEP-2013
     * Build Number     : RI0024.3.6_B0002

      * Modified By      : Sachin P.
      * Modified Date    : 03-Sep-2013
      * Modified for     : DFCHOST-340
      * Modified Reason  : Momentum Production Testing - Loading test card with $20.00
      * Reviewer         : Dhiraj
      * Reviewed Date    : 03-SEP-2013
      * Build Number     : RI0024.3.6_B0002

      * Modified By      : Sachin P.
      * Modified Date    : 03-Sep-2013
      * Modified for     : DFCHOST-340(review)
      * Modified Reason  : Review changes
      * Reviewer         : Dhiraj
      * Reviewed Date    : 11-sep_2013
      * Build Number     : RI0024.4_B0009

      * Modified By      : RAVI N
      * Modified Date    : 25-Sep-2013
      * Modified for     : FOR JH-13
      * Reviewer         : Dhiraj
      * Reviewed Date    : 19-09-2013
      * Build Number     : RI0024.5_B0001

      * Modified By      : RAVI N
      * Modified Date    : 21-NOV-2013
      * Modified for     : 0012744 0012745
      * Modified Reason  : Differniate Monthly Fee and Waiver By change description as MONTHLY FEE- WAIVER
      * Reviewer         : Dhiraj
      * Reviewed Date    : 05/DEC/2013
      * Build Number     : RI0024.7_B0001

      * Modified By      : Pankaj S.
      * Modified Date    : 03-Jan-2014
      * Modified for     : JH - Monthly Fee Waiver changes
      * Reviewer         : Dhiraj
      * Reviewed Date    : 03-Jan-2014
      * Build Number     : RI0027_B0003

      * Modified By      : RAVI N.
      * Modified Date    : 03-FEB-2014
      * Modified for     : Narration Changes
      * Reviewer         : Dhiraj
      * Reviewed Date    :
      * Build Number     : RI0027.1_B0001

      * Modified By      : Ramesh.A
      * Modified Date    : 04-Apr-2014
      * Modified for     : DFCCSD-101 to log teh cap_cafgen_date in cms_appl_pan table
      * Reviewer         : spankaj
      * Reviewed Date    : 07-April-2014
      * Build Number     : CMS3.5.1_RI0027.2_B0004

     * Modified By      : Revathi D
     * Modified Date    : 02-APR-2014
     * Modified for     :
     * Modified Reason  : 1.Round functions added upto 2nd decimal for amount columns in CMS_CHARGE_DTL,CMS_ACCTCLAWBACK_DTL,
                          CMS_ACCT_MAST,CMS_STATEMENTS_LOG,TRANSACTIONLOG.

     * Reviewer         : Pankaj S.
     * Reviewed Date    : 03-APR-2014
     * Build Number     : CMS3.5.1_RI0027.1.2_B0001

     * Modified By      : Pankaj S.
     * Modified Date    : 30-Jul-2014
     * Modified for     : FSS-1762 - Commit should be happened at row level in Monthly Fee job
     * Build Number     : VMS_Package_1.5

    * modified by   : Amudhan S
    * modified Date     : 23-may-14
    * modified for      : FWR 64
    * modified reason   : To restrict clawback fee entries as per the configuration done by user.
    * Reviewer          : Spankaj
    * Build Number      : RI0027.3_B0001

    * modified by       : Ramesh A
    * modified Date     : 21-July-14
    * modified for      : 15544
    * modified reason   : Fees entries not logging in activity tab after the claw back count has been reached
    * Reviewer          : spankaj
    * Build Number      : RI0027.3_B0005

    * modified by       : Saravana Kumar
    * modified reason   : Modified for Balance issue
    * Reviewer          : Spankaj
    * Build Number      : RI0027.3.3_B0001

    * modified by       : Saravana Kumar
    * modified reason   : Modified for JIRA FSS - 2030
    * Build Number      : RI0027.4.3_B0012

    * Modified By      : A.Sivakaminathan
    * Modified Date    : 25-Mar-2015
    * Modified Reason  : DFCTNM-32 Monthly Fee Assessment - First Fee in First Month / Clawback MaxAmt Limit
    * Reviewer         :
    * Build Number     : VMSGPRHOSTCSD_3.0

    * modified by       : Saravana Kumar
    * modified reason   : To calculate monthly fee for inactive replaced card
    * Reviewer          : Pankaj salunkhe
    * Build Number      : VMS_RSJ001

    * modified by       : Pankaj S.
    * modified reason   :  instead of ins date use valid from date to calculate the pending months from the activation date..
    * Reviewer          : Saravana Kumar
    * Build Number      : VMS_RSJ001.1

    * modified by       : Saravana Kumar
    * modified reason   : FSS-4125
    * Reviewer          : Pankaj salunkhe
    * Build Number      : VMS_RSJ001.2

    * Modified by      : Pankaj S.
    * Modified Date    : 07/Oct/2016
    * PURPOSE          : FSS-4755
    * Review           : Saravana
    * Build Number     : VMSGPRHOST_4.10
    * Modified By      : UBAIDUR RAHMAN H
    * Modified Date    : 16-JAN-2018
    * Purpose          : CURRENCY CODE CHANGES FROM INST LEVEL TO BIN LEVEL.
    * Reviewer         : Vini
    * Release Number   : VMSGPRHOST18.1
	
    * Modified By      : UBAIDUR RAHMAN H
    * Modified Date    : 17-MAR-2020
    * Purpose          : VMS - 2183 -- State Restriction logic for monthly fee calculation.
    * Reviewer         : Saravanakumar
    * Release Number   : VMSGPRHOST_R28_B2
	
	* Modified By      : PUVANESH N
    * Modified Date    : 27-DEC-2021
    * Purpose          : VMS - 5340 : Remove the monthly fee counter update in monthly fee 
									  calculation job for the accounts having balance less than zero
    * Reviewer         : Saravanakumar
    * Release Number   : VMSGPRHOST_R56_B2
***********************************************************************************************************/

CURSOR CARDFEE IS
    SELECT CFM_FEE_CODE,
         CFM_FEE_AMT,
         CCE_PAN_CODE,
         CCE_PAN_CODE_ENCR,
         CCE_CRGL_CATG,
         CCE_CRGL_CODE,
         CCE_CRSUBGL_CODE,
         CCE_CRACCT_NO,
         CCE_DRGL_CATG,
         CCE_DRGL_CODE,
         CCE_DRSUBGL_CODE,
         CCE_DRACCT_NO,
         CFF_FEE_PLAN,
         CAP_ACTIVE_DATE,
         CCE_INS_DATE,
         CFM_DATE_ASSESSMENT,
         CFM_CLAWBACK_FLAG,
         CFM_PRORATION_FLAG,
         CFT_FEE_FREQ,
         CFT_FEETYPE_CODE,
         CAP_NEXT_MB_DATE,
         CAP_CARD_STAT,
         CFM_FEECAP_FLAG,
         CAP_ACCT_NO ,
         cap_repl_flag,
         CAP_PROD_CODE,CAP_CARD_TYPE,
         cap_acct_id,
         CFM_FREE_TXNCNT,CFM_TXNFREE_AMT,CFM_FEEAMNT_TYPE,
         cfm_crfree_txncnt,cfm_max_limit,
         CFM_FEE_DESC,
         NVL(cfm_clawback_count,0) cfm_clawback_count,
         NVL(CFM_CLAWBACK_TYPE,'N') CFM_CLAWBACK_TYPE,
         NVL(CFM_CLAWBACK_MAXAMT,0) CFM_CLAWBACK_MAXAMT,
         NVL(CFM_ASSESSED_DAYS,0) CFM_ASSESSED_DAYS,
         cce_valid_from,
         cfm_ins_date,
	 NVL(CPC_STATE_RESTRICT,'N') STATERESTFLAG,
	 CAP_CUST_CODE  	--/* Added for VMS-2183 State Restriction logic for monthly fee calculation*/ 
     FROM CMS_FEE_MAST,
         CMS_CARD_EXCPFEE,
         CMS_FEE_TYPES,
         CMS_FEE_FEEPLAN,
         CMS_APPL_PAN,
	 CMS_PROD_CATTYPE 
    WHERE CFM_INST_CODE = P_INSTCODE AND CFM_INST_CODE = CCE_INST_CODE
         AND CCE_FEE_PLAN = CFF_FEE_PLAN AND CFF_FEE_CODE = CFM_FEE_CODE AND
       ((CCE_VALID_TO IS NOT NULL AND (TRUNC(SYSDATE) between cce_valid_from and CCE_VALID_TO))
            OR (CCE_VALID_TO IS NULL AND TRUNC(SYSDATE) >= cce_valid_from)) AND
         CFM_FEETYPE_CODE = CFT_FEETYPE_CODE AND
         CFT_INST_CODE = CFM_INST_CODE
         AND CAP_CARD_STAT NOT IN ('9')
         AND CFT_FEE_FREQ = 'M' AND CFT_FEE_TYPE = 'M' AND
         CAP_PAN_CODE = CCE_PAN_CODE
         --Modifed by saravanakumar on 22-Jul-2015
	 AND CAP_PROD_CODE=CPC_PROD_CODE 
         AND CAP_CARD_TYPE=CPC_CARD_TYPE 
	 AND CAP_INST_CODE=CPC_INST_CODE --/* Added for VMS-2183 State Restriction logic for monthly fee calculation*/ 
         AND (cap_active_date IS NOT NULL or ( cap_active_date is null and (cap_repl_flag<>0 or cfm_date_assessment = 'FLI')))
         and (cap_next_mb_date is null or trunc(cap_next_mb_date) <= trunc(sysdate));

CURSOR PRODCATGFEE IS
    SELECT CFM_FEE_CODE,
         CFM_FEE_AMT,
         CPF_PROD_CODE,
         CPF_CARD_TYPE,
         CPF_CRGL_CATG,
         CPF_CRGL_CODE,
         CPF_CRSUBGL_CODE,
         CPF_CRACCT_NO,
         CPF_DRGL_CATG,
         CPF_DRGL_CODE,
         CPF_DRSUBGL_CODE,
         CPF_DRACCT_NO,
         CFF_FEE_PLAN,
         CFM_DATE_ASSESSMENT,
         CFM_CLAWBACK_FLAG,
         CFM_PRORATION_FLAG,
         CFT_FEE_FREQ,
         CFT_FEETYPE_CODE,
         CAP_PAN_CODE,
         CAP_PAN_CODE_ENCR,
         CAP_ACTIVE_DATE,
         CPF_INS_DATE,
         CAP_NEXT_MB_DATE,
         CAP_CARD_STAT,
         cap_repl_flag,
         CFM_FEECAP_FLAG,
         CAP_ACCT_NO ,
         CAP_PROD_CODE,CAP_CARD_TYPE ,
         cap_acct_id,
         CFM_FREE_TXNCNT,CFM_TXNFREE_AMT,CFM_FEEAMNT_TYPE,
         cfm_crfree_txncnt,cfm_max_limit,
         CFM_FEE_DESC,
         NVL(cfm_clawback_count,0) cfm_clawback_count,
         NVL(CFM_CLAWBACK_TYPE,'N') CFM_CLAWBACK_TYPE,
         NVL(CFM_CLAWBACK_MAXAMT,0) CFM_CLAWBACK_MAXAMT,
         NVL(CFM_ASSESSED_DAYS,0) CFM_ASSESSED_DAYS,
         cpf_valid_from ,
         cfm_ins_date,
	 NVL(CPC_STATE_RESTRICT,'N') STATERESTFLAG, 
	 CAP_CUST_CODE      		--/* Added for VMS-2183 State Restriction logic for monthly fee calculation*/ 
     FROM CMS_FEE_MAST,
         CMS_PRODCATTYPE_FEES,
         CMS_FEE_TYPES,
         CMS_FEE_FEEPLAN,
         CMS_APPL_PAN,
	 CMS_PROD_CATTYPE 		--/* Added for VMS-2183 State Restriction logic for monthly fee calculation*/ 
    WHERE CFM_INST_CODE = P_INSTCODE AND CFM_INST_CODE = CPF_INST_CODE
         AND CFF_FEE_PLAN = CPF_FEE_PLAN AND CFF_FEE_CODE = CFM_FEE_CODE AND
        ((cpf_valid_to IS NOT NULL AND (TRUNC(SYSDATE) between cpf_valid_from and cpf_valid_to))
            OR (cpf_valid_to IS NULL AND TRUNC(SYSDATE) >= cpf_valid_from)) AND
         CFM_FEETYPE_CODE = CFT_FEETYPE_CODE AND
         CFT_INST_CODE = CFM_INST_CODE AND CAP_PROD_CODE = CPF_PROD_CODE AND
         CAP_CARD_TYPE = CPF_CARD_TYPE AND CAP_INST_CODE = CPF_INST_CODE
         AND CAP_CARD_STAT NOT IN ('9')
         AND CFT_FEE_FREQ = 'M' AND CFT_FEE_TYPE = 'M'
	 AND CAP_PROD_CODE=CPC_PROD_CODE 
         AND CAP_CARD_TYPE=CPC_CARD_TYPE 
	 AND CAP_INST_CODE=CPC_INST_CODE 	--/* Added for VMS-2183 State Restriction logic for monthly fee calculation*/ 
         --Modifed by saravanakumar on 22-Jul-2015
         AND (cap_active_date IS NOT NULL or ( cap_active_date is null and (cap_repl_flag<>0 or cfm_date_assessment = 'FLI')))
         and (cap_next_mb_date is null or trunc(cap_next_mb_date) <= trunc(sysdate));

CURSOR PRODFEE IS
    SELECT CFM_FEE_CODE,
         CFM_FEE_AMT,
         CPF_PROD_CODE,
         CPF_CRGL_CATG,
         CPF_CRGL_CODE,
         CPF_CRSUBGL_CODE,
         CPF_CRACCT_NO,
         CPF_DRGL_CATG,
         CPF_DRGL_CODE,
         CPF_DRSUBGL_CODE,
         CPF_DRACCT_NO,
         CFF_FEE_PLAN,
         CFM_DATE_ASSESSMENT,
         CFM_CLAWBACK_FLAG,
         CFM_PRORATION_FLAG,
         CFT_FEE_FREQ,
         CFT_FEETYPE_CODE,
         CAP_PAN_CODE,
         CAP_PAN_CODE_ENCR,
         CAP_ACTIVE_DATE,
         CPF_INS_DATE,
         CAP_NEXT_MB_DATE,
         CAP_CARD_STAT,
         CFM_FEECAP_FLAG,
         CAP_ACCT_NO,
         cap_card_type,
         CAP_PROD_CODE,
         cap_acct_id,
         cap_repl_flag,
         CFM_FREE_TXNCNT,CFM_TXNFREE_AMT,CFM_FEEAMNT_TYPE,
         cfm_crfree_txncnt,cfm_max_limit,
         CFM_FEE_DESC,
         NVL(cfm_clawback_count,0) cfm_clawback_count,
         NVL(CFM_CLAWBACK_TYPE,'N') CFM_CLAWBACK_TYPE,
         NVL(CFM_CLAWBACK_MAXAMT,0) CFM_CLAWBACK_MAXAMT,
         NVL(CFM_ASSESSED_DAYS,0) CFM_ASSESSED_DAYS,
         cpf_valid_from  ,
         cfm_ins_date,
	 NVL(CPC_STATE_RESTRICT,'N') STATERESTFLAG, 		
	 CAP_CUST_CODE 						--/* Added for VMS-2183 State Restriction logic for monthly fee calculation*/ 
     FROM CMS_FEE_MAST,
         CMS_PROD_FEES,
         CMS_FEE_TYPES,
         CMS_FEE_FEEPLAN,
         CMS_APPL_PAN,
	 CMS_PROD_CATTYPE					--/* Added for VMS-2183 State Restriction logic for monthly fee calculation*/ 
    WHERE CFM_INST_CODE = P_INSTCODE AND CFM_INST_CODE = CPF_INST_CODE AND
         CFF_FEE_PLAN = CPF_FEE_PLAN AND CFF_FEE_CODE = CFM_FEE_CODE AND
        ((cpf_valid_to IS NOT NULL AND (TRUNC(SYSDATE) between cpf_valid_from and cpf_valid_to))
            OR (cpf_valid_to IS NULL AND TRUNC(SYSDATE) >= cpf_valid_from)) AND
         CFM_FEETYPE_CODE = CFT_FEETYPE_CODE AND
         CFT_INST_CODE = CFM_INST_CODE AND CAP_PROD_CODE = CPF_PROD_CODE AND
         CAP_INST_CODE = CPF_INST_CODE
         AND CAP_CARD_STAT NOT IN ('9')
         AND CFT_FEE_FREQ = 'M' AND CFT_FEE_TYPE = 'M'
	 AND CAP_PROD_CODE=CPC_PROD_CODE 
         AND CAP_CARD_TYPE=CPC_CARD_TYPE 
	 AND CAP_INST_CODE=CPC_INST_CODE 			--/* Added for VMS-2183 State Restriction logic for monthly fee calculation*/ 
         --Modifed by saravanakumar on 22-Jul-2015
         AND (cap_active_date IS NOT NULL or ( cap_active_date is null and (cap_repl_flag<>0 or cfm_date_assessment = 'FLI')))
         and (cap_next_mb_date is null or trunc(cap_next_mb_date) <= trunc(sysdate));

PROCEDURE LP_MONTHLY_FEE_CALC(P_DATE_ASSESSMENT IN VARCHAR2,
                          P_PRORATION       IN VARCHAR2,
                          P_FEE_AMNT        IN NUMBER,
                          P_CALC_DATE       IN DATE,
                          P_PAN_CODE        IN VARCHAR2,
                          P_INST_CODE       IN NUMBER,
                          P_CAPACTIVE_DATE  IN DATE,
                          P_INS_DATE        IN DATE,
                          P_ASSESSED_DAYS   IN NUMBER,
                          P_FEEAMOUNT       OUT NUMBER,
                          P_ERRMSG          OUT VARCHAR2) AS

V_FEE_AMNT       CMS_ACCT_MAST.CAM_ACCT_BAL%TYPE;
V_FIRST_DATE     DATE;
V_TOT_DAYS       NUMBER;
V_ACTIVATIONDATE NUMBER;
V_MONFEE_CARDCNT NUMBER;
V_CALC_DATE      DATE;
V_ASSESSED_DATE  date;
v_active_dt      DATE; --Added for multiple monthly fee issue
BEGIN

    P_ERRMSG := 'OK';


    --SN:Added for multiple monthly fee issue
    IF P_CAPACTIVE_DATE<P_INS_DATE THEN
       v_active_dt:=P_INS_DATE;
    ELSE
       v_active_dt:=P_CAPACTIVE_DATE;
    END IF;
    --EN:Added for multiple monthly fee issue


    IF P_CALC_DATE IS NULL OR P_CALC_DATE < v_active_dt THEN --  Added next mb date < active date to handle existing inventory cards which are activated for defect Host-328.

        IF P_DATE_ASSESSMENT = 'AD' OR P_DATE_ASSESSMENT = 'AL' OR P_DATE_ASSESSMENT = 'FLI' THEN  --P_DATE_ASSESSMENT = 'AL' condition added by Pankaj S. for JH - Monthly Fee Waiver changes
          IF (P_DATE_ASSESSMENT = 'AD' OR P_DATE_ASSESSMENT = 'FLI') AND P_ASSESSED_DAYS > 0 THEN  --DFCTNM-32 first monthly fee assessed after configured X days from card activation date
             V_ASSESSED_DATE := v_active_dt + P_ASSESSED_DAYS;
               V_CALC_DATE := V_ASSESSED_DATE;
          ELSE
                  V_CALC_DATE := ADD_MONTHS(v_active_dt, 1);
          END IF;
        ELSIF P_DATE_ASSESSMENT = 'FD' THEN
            V_CALC_DATE := LAST_DAY(v_active_dt) + 1;
        END IF;

    ELSIF  P_CALC_DATE = v_active_dt THEN
        V_CALC_DATE := ADD_MONTHS(SYSDATE, 1); -- This is handle not to collect monthly fee for not activated inventory card. for defect Host-328
    ELSE
        V_CALC_DATE := P_CALC_DATE;
    END IF;

    --SN:Commented for multiple monthly fee issue
    /*IF V_CALC_DATE IS NOT NULL AND P_INS_DATE IS NOT NULL THEN

        LOOP
               IF TRUNC(V_CALC_DATE) >= TRUNC(ADD_MONTHS(P_INS_DATE,1)) THEN --modified on 25-02-2016
                     EXIT;
                ELSE
                     V_CALC_DATE := ADD_MONTHS(V_CALC_DATE,1);
               END IF;
        END LOOP;

    END IF;*/
    --EN:Commented for multiple monthly fee issue

    V_NEXT_MB_DATE := ADD_MONTHS(V_CALC_DATE, 1);

	--SN Changes for FSS-5283

	  IF V_NEXT_MB_DATE IS NOT NULL THEN
		   LOOP
		       IF trunc(V_NEXT_MB_DATE) <= trunc(SYSDATE) THEN
				      V_NEXT_MB_DATE := ADD_MONTHS(V_NEXT_MB_DATE,1);
			     ELSE
              EXIT;
           END IF;
		   END LOOP;
	  END IF;

    IF TRUNC(LAST_DAY(V_NEXT_MB_DATE)) = TRUNC(LAST_DAY(SYSDATE)) THEN
       V_NEXT_MB_DATE := ADD_MONTHS(V_NEXT_MB_DATE,1);
    END IF;

	--EN Changes for FSS-5283

        IF P_DATE_ASSESSMENT = 'AD' OR P_DATE_ASSESSMENT = 'AL' OR P_DATE_ASSESSMENT = 'FLI' THEN  --P_DATE_ASSESSMENT = 'AL' condition added by Pankaj S. for JH - Monthly Fee Waiver changes
            IF TRUNC(V_CALC_DATE) <= TRUNC(SYSDATE) THEN   --  less than equal to (<=) added instead of equal to (=) for defect Host-328
                P_ERRMSG    := 'OK';
                P_FEEAMOUNT := P_FEE_AMNT;
            ELSE
                P_ERRMSG    := 'NO FEES';
                P_FEEAMOUNT := 0;
            END IF;

        ELSIF P_DATE_ASSESSMENT = 'FD' THEN

            SELECT TO_CHAR(LAST_DAY(ADD_MONTHS(SYSDATE, -1)), 'DD'),TRUNC(SYSDATE, 'MM'),
            TO_CHAR(to_date(v_active_dt,'dd-mm-yyyy'), 'DD')
            INTO V_TOT_DAYS, V_FIRST_DATE, V_ACTIVATIONDATE
            FROM DUAL;

            IF  TRUNC(V_CALC_DATE) <= TRUNC(V_FIRST_DATE) THEN  --  less than equal to (<=) added instead of equal to (=) for defect Host-328

                IF P_PRORATION = 'Y' AND (P_CALC_DATE IS NULL OR P_CALC_DATE < v_active_dt) THEN
                    V_FEE_AMNT := ((P_FEE_AMNT / 30) * (V_TOT_DAYS - V_ACTIVATIONDATE));
                ELSE
                    V_FEE_AMNT := P_FEE_AMNT;
                END IF;

                P_ERRMSG := 'OK';
            ELSE
                P_ERRMSG   := 'NO FEES';
                V_FEE_AMNT := 0;
            END IF;

            P_FEEAMOUNT := V_FEE_AMNT;

        END IF;

EXCEPTION
    WHEN OTHERS THEN
        P_ERRMSG := 'Error in LP_MONTHLY_FEE_CALC ' || SUBSTR(SQLERRM, 1, 200);
END LP_MONTHLY_FEE_CALC;


PROCEDURE LP_TRANSACTION_LOG(P_INSTCODE IN NUMBER,
                        P_HASHPAN           IN VARCHAR2,
                        P_ENCRPAN           IN VARCHAR2,
                        P_RRN               IN VARCHAR2,
                        P_DELIVERY_CHANNEL  IN VARCHAR2,
                        P_BUSINESS_DATE     IN VARCHAR2,
                        P_BUSINESS_TIME     IN VARCHAR2,
                        P_ACCT_NUMBER       IN VARCHAR2,
                        P_ACCT_BAL          IN VARCHAR2,
                        P_LEDGER_BAL        IN VARCHAR2,
                        P_FEE_AMNT          IN VARCHAR2,
                        P_AUTH_ID           IN VARCHAR2,
                        P_TRAN_DESC         IN VARCHAR2,
                        P_TRAN_CODE         IN VARCHAR2,
                        P_RESPONSE_ID       IN  VARCHAR2,
                        P_CARD_CURR         IN     VARCHAR2,
                        P_WAIV_AMNT         IN NUMBER,
                        P_FEE_CODE          IN VARCHAR2,
                        P_FEE_PLAN          IN VARCHAR2,
                        P_CR_ACCTNO         IN VARCHAR2,
                        P_DR_ACCTNO         IN VARCHAR2,
                        P_ATTACH_TYPE       IN VARCHAR2,
                        P_CARD_STAT         IN VARCHAR2,
                        P_CAM_TYPE_CODE     IN VARCHAR2,   -- Added on 17-Apr-2013 for defect 10871
                        P_timestamp         IN timestamp,  -- Added on 17-Apr-2013 for defect 10871
                        P_PROD_CODE         IN VARCHAR2,   -- Added on 17-Apr-2013 for defect 10871
                        P_PROD_CATTYPE      IN VARCHAR2,   -- Added on 17-Apr-2013 for defect 10871
                        P_DR_CR_FLAG        IN VARCHAR2,    -- Added on 17-Apr-2013 for defect 10871
                        P_ERR_MSG           IN OUT VARCHAR2    --Modified for JIRA FSS - 2030 by Saravanakumar
                        ) AS
BEGIN
    BEGIN
        INSERT INTO TRANSACTIONLOG
                            (MSGTYPE,
                            RRN,
                            DELIVERY_CHANNEL,
                            DATE_TIME,
                            TXN_CODE,
                            TXN_TYPE,
                            TXN_STATUS,
                            RESPONSE_CODE,
                            BUSINESS_DATE,
                            BUSINESS_TIME,
                            CUSTOMER_CARD_NO,
                            BANK_CODE,
                            TOTAL_AMOUNT,
                            AUTH_ID,
                            TRANS_DESC,
                            AMOUNT,               -- Uncomented on 17-apr-2013 for defect 10871
                            INSTCODE,
                            CUSTOMER_CARD_NO_ENCR,
                            CUSTOMER_ACCT_NO,
                            ACCT_BALANCE,
                            LEDGER_BALANCE,
                            RESPONSE_ID,
                            TXN_MODE,
                            CURRENCYCODE  ,
                            TRANFEE_AMT ,
                            FEEATTACHTYPE,FEE_PLAN,FEECODE,TRANFEE_CR_ACCTNO,TRANFEE_DR_ACCTNO ,
                            CARDSTATUS,
                            ACCT_TYPE,    -- Added on 17-Apr-2013 for defect 10871
                            TIME_STAMP,   -- Added on 17-Apr-2013 for defect 10871
                            PRODUCTID,    -- Added on 17-Apr-2013 for defect 10871
                            CATEGORYID,   -- Added on 17-Apr-2013 for defect 10871
                            CR_DR_FLAG,   -- Added on 17-Apr-2013 for defect 10871
                            error_msg     -- Added on 17-Apr-2013 for defect 10871
                            )
        VALUES
                            ('0200',
                            P_RRN,
                            P_DELIVERY_CHANNEL,
                            sysdate,
                            P_TRAN_CODE,
                            '1',
                            DECODE(P_RESPONSE_ID,'1','C','F'),
                            DECODE(P_RESPONSE_ID,'1','00','89') ,
                            P_BUSINESS_DATE,
                            P_BUSINESS_TIME,
                            P_HASHPAN,
                            P_INSTCODE,
                            TRIM(TO_CHAR((nvl(P_FEE_AMNT,0)-nvl(P_WAIV_AMNT,0)), '999999999999999990.99')),   -- NVL added on 17-Apr-2013 for defect 10871   --For logging 0.00 instead .00 for regarding 0012744
                            P_AUTH_ID,
                            P_TRAN_DESC,
                            '0.00',       --added on 17-Apr-2013 for defect 10871
                            P_INSTCODE,
                            P_ENCRPAN,
                            P_ACCT_NUMBER,
                            ROUND(nvl(P_ACCT_BAL,0),2),     -- NVL,to_char added on 17-Apr-2013 for defect 10871   --Modified by Revathi on 02-APR-2014 for 3decimal place issue
                            ROUND(nvl(P_LEDGER_BAL,0),2),    -- NVL,to_char added on 17-Apr-2013 for defect 10871   --Modified by Revathi on 02-APR-2014 for 3decimal place issue
                            P_RESPONSE_ID,
                            0    ,
                            P_CARD_CURR ,
                            TRIM(TO_CHAR((nvl(P_FEE_AMNT,0)-nvl(P_WAIV_AMNT,0)), '99999999999999999.99')) , -- NVL added on 17-Apr-2013 for defect 10871
                            P_ATTACH_TYPE,
                            P_FEE_PLAN,
                            P_FEE_CODE,
                            P_CR_ACCTNO,
                            P_DR_ACCTNO,
                            P_CARD_STAT,
                            P_CAM_TYPE_CODE,  -- Added on 17-Apr-2013 for defect 10871
                            SYSTIMESTAMP,      -- Added on 17-Apr-2013 for defect 10871
                            P_PROD_CODE,      -- Added on 17-Apr-2013 for defect 10871
                            P_PROD_CATTYPE,   -- Added on 17-Apr-2013 for defect 10871
                            P_DR_CR_FLAG,     -- Added on 17-Apr-2013 for defect 10871
                            P_ERR_MSG         -- Added on 17-Apr-2013 for defect 10871
                            );
        EXCEPTION
            WHEN OTHERS THEN
                P_ERRMSG:='Error while insertg in transactionlog'||SUBSTR(SQLERRM, 1, 200);
        END ;

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
                            CTD_TXN_CURR,
                            CTD_FEE_AMOUNT,
                            CTD_WAIVER_AMOUNT,
                            CTD_BILL_CURR,
                            CTD_PROCESS_FLAG,
                            CTD_PROCESS_MSG,
                            CTD_RRN,
                            CTD_INST_CODE,
                            CTD_CUSTOMER_CARD_NO_ENCR,
                            CTD_CUST_ACCT_NUMBER
                            )
        VALUES
                            (P_DELIVERY_CHANNEL,
                            P_TRAN_CODE,
                            '1',
                            '0200',
                            0,
                            P_BUSINESS_DATE,
                            P_BUSINESS_TIME,
                            P_HASHPAN,
                            P_CARD_CURR,
                            P_FEE_AMNT,
                            P_WAIV_AMNT,
                            P_CARD_CURR,
                            DECODE(P_RESPONSE_ID,'1','Y','F'),
                            DECODE(P_RESPONSE_ID,'1','Successful',P_ERRMSG),
                            P_RRN,
                            P_INSTCODE,
                            P_ENCRPAN,
                            P_ACCT_NUMBER
                            );
    EXCEPTION
        WHEN OTHERS THEN
            P_ERRMSG:='Error while insertg in cms_transaction_log_dtl'||SUBSTR(SQLERRM, 1, 200);
    END;
END LP_TRANSACTION_LOG;

PROCEDURE LP_FEE_UPDATE_LOG(P_INSTCODE IN NUMBER,
                        P_HASHPAN  IN VARCHAR2,
                        P_ENCRPAN  IN VARCHAR2,
                        P_FEE_CODE IN NUMBER,
                        P_FEE_AMNT IN NUMBER,
                        P_FEE_PLAN IN VARCHAR2,
                        P_CR_GLCATG    IN VARCHAR2,
                        P_CR_GLCODE    IN VARCHAR2,
                        P_CR_SUBGLCODE IN VARCHAR2,
                        P_CR_ACCTNO    IN VARCHAR2,
                        P_DR_GLCATG    IN VARCHAR2,
                        P_DR_GLCODE    IN VARCHAR2,
                        P_DR_SUBGLCODE IN VARCHAR2,
                        P_DR_ACCTNO    IN VARCHAR2,
                        P_CLAWBACK     IN VARCHAR2,
                        P_FEE_FREQ     IN VARCHAR2,
                        P_FEETYPE_CODE IN VARCHAR2,
                        P_LUPDUSER     IN VARCHAR2,
                        P_WAIV_AMNT    IN NUMBER,
                        P_ATTACH_TYPE   IN VARCHAR2,
                        P_CARD_STAT     IN VARCHAR2,
                        P_ACCT_NO       IN VARCHAR2, --Added on 06.09.2013 for DFCHOST-340(review)
                        P_PROD_CODE     IN       VARCHAR2,--Added on 06.09.2013 for DFCHOST-340(review)
                        P_CARD_TYPE     IN       NUMBER, --Added on 06.09.2013 for DFCHOST-340(review)
                        P_WAIV_FLAG     IN VARCHAR2,    --Add on 26/09/13 For regarding JH-13
                        p_free_txn     IN VARCHAR2,--Added by Pankaj S. for JH - Monthly Fee Waiver
                        P_FEE_DESC     IN VARCHAR2,--Added on 03/02/14 for MVCSD-4471
                        P_CLAWBACK_TYPE     IN VARCHAR2,--DFCTNM-32
                        P_CLAWBACK_MAXAMT     IN NUMBER,--DFCTNM-32
                        P_ERRMSG       OUT VARCHAR2) AS

V_ACCT_BAL         CMS_ACCT_MAST.CAM_ACCT_BAL%TYPE;
V_LEDGER_BAL       CMS_ACCT_MAST.CAM_LEDGER_BAL%TYPE;
V_ACCT_NUMBER      CMS_APPL_PAN.CAP_ACCT_NO%TYPE;
V_AUTH_ID          TRANSACTIONLOG.AUTH_ID%TYPE;
V_BUSINESS_DATE    VARCHAR2(10);
V_BUSINESS_TIME    VARCHAR2(10);
V_TXN_MODE         CMS_FUNC_MAST.CFM_TXN_MODE%TYPE DEFAULT '0';
V_DELIVERY_CHANNEL CMS_FUNC_MAST.CFM_DELIVERY_CHANNEL%TYPE DEFAULT '05';
V_TXN_CODE         CMS_FUNC_MAST.CFM_TXN_CODE%TYPE DEFAULT '16';
V_TRAN_DESC        CMS_TRANSACTION_MAST.CTM_TRAN_DESC%TYPE;
V_NARRATION        CMS_STATEMENTS_LOG.CSL_TRANS_NARRRATION%TYPE;
V_PAN_CODE         VARCHAR2(19);
V_CLAWBACK_AMNT    CMS_ACCT_MAST.CAM_ACCT_BAL%TYPE;
V_FILE_STATUS      CMS_CHARGE_DTL.CCD_FILE_STATUS%TYPE DEFAULT 'N';
V_CLAWBACK_COUNT   NUMBER;
V_FEE_AMNT         CMS_ACCT_MAST.CAM_ACCT_BAL%TYPE;
v_bin_curr          CMS_BIN_PARAM.CBP_PARAM_VALUE%TYPE;
V_CARD_CURR        TRANSACTIONLOG.CURRENCYCODE%TYPE;
v_chrg_dtl_amt_sum    NUMBER;--DFCTNM-32
V_CLAWBACK_MAXAMT_CHECK  BOOLEAN;--DFCTNM-32

BEGIN
    P_ERRMSG := 'OK';
    V_CLAWBACK_MAXAMT_CHECK := FALSE;--DFCTNM-32

    BEGIN
        SELECT TO_CHAR(SYSDATE, 'YYYYMMDD'), TO_CHAR(SYSDATE, 'HH24MISS')
        INTO V_BUSINESS_DATE, V_BUSINESS_TIME
        FROM DUAL;
    EXCEPTION
        WHEN OTHERS THEN
            P_ERRMSG := 'Error while selecting date' || SUBSTR(SQLERRM, 1, 200);
            RAISE EXP_REJECT_RECORD;
    END;

    V_RRN1     := V_RRN1 + 1;
    V_RRN2     := 'MF' || TO_CHAR(SYSDATE, 'YYMMDD') || V_RRN1;--Modified by Saravanakumar for rrn issue on 28-Oct-2014
    V_PAN_CODE := FN_DMAPS_MAIN(P_ENCRPAN);

    BEGIN

        SELECT CAM_ACCT_BAL, CAM_LEDGER_BAL, CAM_ACCT_NO, CAM_TYPE_CODE -- Added on 17-Apr-2013 for defect 10871
        INTO V_ACCT_BAL, V_LEDGER_BAL, V_ACCT_NUMBER,V_CAM_TYPE_CODE
        FROM CMS_ACCT_MAST
        WHERE CAM_INST_CODE = P_INSTCODE AND
        CAM_ACCT_NO =    P_ACCT_NO
        FOR UPDATE NOWAIT;
    EXCEPTION
        WHEN OTHERS THEN
            P_ERRMSG := 'Error while selecting data from Account Master' || SUBSTR(SQLERRM, 1, 200);
            RAISE EXP_REJECT_RECORD;
    END;

    IF P_WAIV_FLAG='Y' OR P_FEE_AMNT=0 THEN
        V_FEE_AMNT:=0.00;
    ELSE
        V_FEE_AMNT:=P_FEE_AMNT-P_WAIV_AMNT;
    END IF;

    V_PAN_CODE := FN_DMAPS_MAIN(P_ENCRPAN);

    BEGIN
--        select cip_param_value into bin_curr from cms_inst_param
--        where cip_inst_code=P_INSTCODE and cip_param_key ='CURRENCY';
	 SELECT TRIM (cbp_param_value) 
	  INTO v_bin_curr 
	 FROM cms_bin_param 
	 WHERE cbp_param_name = 'Currency' AND cbp_inst_code= p_instcode
	 AND cbp_profile_code = (select  cpc_profile_code from 
	 cms_prod_cattype where cpc_prod_code = P_PROD_CODE
	 and cpc_card_type = p_card_type  and cpc_inst_code=p_instcode);			 
    EXCEPTION
        WHEN OTHERS THEN
            P_ERRMSG  := 'Error in selecting bin currency ' || SUBSTR(SQLERRM, 1, 200);
            RAISE EXP_REJECT_RECORD;
    END;

    BEGIN
        SELECT CTM_TRAN_DESC ,ctm_credit_debit_flag
        INTO V_TRAN_DESC,v_dr_cr_flag
        FROM CMS_TRANSACTION_MAST
        WHERE CTM_TRAN_CODE = V_TXN_CODE AND
        CTM_DELIVERY_CHANNEL = V_DELIVERY_CHANNEL AND
        CTM_INST_CODE = P_INSTCODE;
    EXCEPTION
        WHEN OTHERS  THEN
        p_errmsg :=  'Error while selecting narration and CR/DR flag'|| SUBSTR (SQLERRM, 1, 200);
        RAISE exp_reject_record;
    END;

    BEGIN
        SP_CONVERT_CURR(P_INSTCODE,
                        v_bin_curr,
                        V_PAN_CODE,
                        V_FEE_AMNT,
                        sysdate,
                        V_FEE_AMNT,
                        V_CARD_CURR,
                        P_ERRMSG,
                        p_prod_code,
                        p_card_type
                        );

        IF p_errmsg <> 'OK' THEN
            P_ERRMSG  := 'Error in SP_CONVERT_CURR ' || P_ERRMSG;
            RAISE exp_reject_record;
        END IF;

    EXCEPTION
        WHEN EXP_REJECT_RECORD THEN
            RAISE;
        WHEN OTHERS THEN
            P_ERRMSG  := 'Error from currency conversion ' ||SUBSTR(SQLERRM, 1, 200);
            RAISE EXP_REJECT_RECORD;
    END;

    IF P_CLAWBACK = 'N' THEN

        IF V_ACCT_BAL > 0 THEN
            IF (V_ACCT_BAL >= V_FEE_AMNT) THEN
                V_DEBIT_AMNT := V_FEE_AMNT;
            ELSE
                V_DEBIT_AMNT := V_ACCT_BAL;
            END IF;
        ELSE
            V_DEBIT_AMNT := 0;
        END IF;

        V_CLAWBACK_AMNT := 0;
    ELSE
        IF V_ACCT_BAL > 0 THEN
            IF (V_ACCT_BAL >= V_FEE_AMNT) THEN
                V_DEBIT_AMNT    := V_FEE_AMNT;
                V_CLAWBACK_AMNT := 0;
            ELSE
                V_DEBIT_AMNT    := V_ACCT_BAL;
                V_CLAWBACK_AMNT := V_FEE_AMNT - V_DEBIT_AMNT;
            END IF;
        ELSE
            V_CLAWBACK_AMNT := V_FEE_AMNT;
            V_DEBIT_AMNT    := 0;
        END IF;

    END IF;


    IF (V_DEBIT_AMNT > 0) THEN

        BEGIN
            UPDATE CMS_ACCT_MAST
            SET CAM_ACCT_BAL   = ROUND(CAM_ACCT_BAL - V_DEBIT_AMNT,2),  --Modified by Revathi on 02-APR-2014 for 3decimal place issue
            CAM_LEDGER_BAL = ROUND(CAM_LEDGER_BAL - V_DEBIT_AMNT,2)
            WHERE CAM_ACCT_NO = V_ACCT_NUMBER AND CAM_INST_CODE = P_INSTCODE;

            IF SQL%ROWCOUNT = 0 THEN
                P_ERRMSG := 'Balance is not updated' ;
                RAISE EXP_REJECT_RECORD;
            END IF;

        EXCEPTION
            WHEN EXP_REJECT_RECORD THEN
                RAISE;
            WHEN OTHERS THEN
                P_ERRMSG := 'Error while updating balance' || SUBSTR(SQLERRM, 1, 200);
                RAISE EXP_REJECT_RECORD;
        END;
    END IF;

    v_timestamp := systimestamp;

    IF (V_DEBIT_AMNT > 0) OR (P_CLAWBACK = 'Y') OR  (P_WAIV_FLAG='Y') OR p_free_txn='Y' THEN --p_free_txn='Y' condition added by Pankaj S. for JH- monthly fee waiver changes

        BEGIN
            SELECT LPAD(SEQ_AUTH_ID.NEXTVAL, 6, '0') INTO V_AUTH_ID FROM DUAL;
        EXCEPTION
            WHEN OTHERS THEN
                P_ERRMSG := 'Error while generating authid ' ||SUBSTR(SQLERRM, 1, 200);
                RAISE EXP_REJECT_RECORD;
        END;

        BEGIN
            V_NARRATION :=P_FEE_DESC;

            IF P_WAIV_FLAG='Y' OR p_free_txn='Y' THEN
                V_NARRATION :='Waived Monthly Fee';
                V_TRAN_DESC :='Waived Monthly Fee';
            END IF;

        EXCEPTION
            WHEN OTHERS THEN
                P_ERRMSG := 'Error while selecting narration' ||SUBSTR(SQLERRM, 1, 200);
                RAISE EXP_REJECT_RECORD;
        END;

        BEGIN
            INSERT INTO CMS_STATEMENTS_LOG
                                (CSL_PAN_NO,
                                CSL_ACCT_NO,
                                CSL_OPENING_BAL,
                                CSL_TRANS_AMOUNT,
                                CSL_TRANS_TYPE,
                                CSL_TRANS_DATE,
                                CSL_CLOSING_BALANCE,
                                CSL_TRANS_NARRRATION,
                                CSL_PAN_NO_ENCR,
                                CSL_RRN,
                                CSL_AUTH_ID,
                                CSL_BUSINESS_DATE,
                                CSL_BUSINESS_TIME,
                                TXN_FEE_FLAG,
                                CSL_DELIVERY_CHANNEL,
                                CSL_INST_CODE,
                                CSL_TXN_CODE,
                                CSL_INS_DATE,
                                CSL_INS_USER,
                                CSL_PANNO_LAST4DIGIT,
                                CSL_ACCT_TYPE,         -- Added on 17-Apr-2013 for defect 10871
                                CSL_TIME_STAMP,        -- Added on 17-Apr-2013 for defect 10871
                                csl_prod_code          -- Added on 17-Apr-2013 for defect 10871
                                )
            VALUES
                                (P_HASHPAN,
                                V_ACCT_NUMBER,
                                ROUND(V_LEDGER_BAL,2),          -- V_ACCT_BALANCE removed to use V_LEDGER_BAL on 17-Apr-2013 for defect 10871   --Modified by Revathi on 02-APR-2014 for 3decimal place issue
                                ROUND(V_DEBIT_AMNT,2),   --Modified by Revathi on 02-APR-2014 for 3decimal place issue
                                'DR',
                                SYSDATE,
                                ROUND(V_LEDGER_BAL - V_DEBIT_AMNT,2),   -- V_ACCT_BALANCE removed to use V_LEDGER_BAL on 17-Apr-2013 for defect 10871   --Modified by Revathi on 02-APR-2014 for 3decimal place issue
                                V_NARRATION, -- for JH - Monthly Fee Waiver
                                P_ENCRPAN,
                                V_RRN2,
                                V_AUTH_ID,
                                V_BUSINESS_DATE,
                                V_BUSINESS_TIME,
                                'Y',
                                V_DELIVERY_CHANNEL,
                                P_INSTCODE,
                                V_TXN_CODE,
                                SYSDATE,
                                1,
                                (SUBSTR(V_PAN_CODE, LENGTH(V_PAN_CODE) - 3, LENGTH(V_PAN_CODE))),
                                v_cam_type_code,   -- added on 17-apr-2013 for defect 10871
                                SYSTIMESTAMP,       -- Added on 17-Apr-2013 for defect 10871
                                p_prod_code ---Commented and modified on 06.09.2013 for DFCHOST-340(review)
                                );

        EXCEPTION
            WHEN OTHERS THEN
                P_ERRMSG := 'Error creating entry in statement log ' ||SUBSTR(SQLERRM, 1, 200);
                RAISE EXP_REJECT_RECORD;
        END;


        V_UPD_REC_CNT := V_UPD_REC_CNT + 1;
    END IF;


    IF P_CLAWBACK = 'Y' AND V_CLAWBACK_AMNT > 0 THEN

        V_FILE_STATUS := 'C';

        BEGIN
            SELECT COUNT (*),NVL(SUM(ccd_clawback_amnt),0)
            INTO v_chrg_dtl_cnt,v_chrg_dtl_amt_sum
            FROM cms_charge_dtl
            WHERE      ccd_inst_code = p_instcode
            AND ccd_delivery_channel = v_delivery_channel
            AND ccd_txn_code = v_txn_code
            --AND ccd_pan_code = P_HASHPAN --Commented for FSS-4577
            AND ccd_acct_no = v_acct_number and CCD_FEE_CODE=P_FEE_CODE
            and ccd_clawback ='Y';
        EXCEPTION
            WHEN OTHERS   THEN
                P_ERRMSG :=  'Error occured while fetching count from cms_charge_dtl'|| SUBSTR (SQLERRM, 1, 100);
                RAISE EXP_REJECT_RECORD;
        END;

      IF (v_tot_clwbck_count =0 AND P_CLAWBACK_MAXAMT = 0) THEN -- FWR-64  If clawback count 0, then system should not clawback any fees
          V_CLAWBACK_AMNT := 0;
      ELSIF (v_tot_clwbck_count > 0 AND P_CLAWBACK_MAXAMT = 0) THEN
          IF NOT(v_chrg_dtl_cnt < v_tot_clwbck_count)  THEN -- Validate only value configured count, If 0 is configured as clawback max amount
             V_CLAWBACK_AMNT := 0;
          END IF;
      ELSIF (v_tot_clwbck_count = 0 AND P_CLAWBACK_MAXAMT > 0)  THEN -- Validate only value configured amount ,If 0 is configured as clawback count
          IF (v_chrg_dtl_amt_sum < P_CLAWBACK_MAXAMT)  THEN
             V_CLAWBACK_MAXAMT_CHECK := TRUE;
          ELSE
              V_CLAWBACK_AMNT := 0;
          END IF;
      ELSIF (v_tot_clwbck_count > 0 AND P_CLAWBACK_MAXAMT > 0) THEN
          IF P_CLAWBACK_TYPE = 'O' THEN -- No clawback ,if either configured number of count or max amount exceeds
             IF (NOT(v_chrg_dtl_cnt < v_tot_clwbck_count) or NOT(v_chrg_dtl_amt_sum < P_CLAWBACK_MAXAMT)) THEN
                V_CLAWBACK_AMNT := 0;
             ELSE
                V_CLAWBACK_MAXAMT_CHECK := TRUE;
             END IF;
          ELSIF P_CLAWBACK_TYPE = 'A' THEN -- No clawback ,if both configured number of count and max amount exceeds
             IF (NOT(v_chrg_dtl_cnt < v_tot_clwbck_count) AND NOT(v_chrg_dtl_amt_sum < P_CLAWBACK_MAXAMT)) THEN
                  V_CLAWBACK_AMNT := 0;
             ELSE
                V_CLAWBACK_MAXAMT_CHECK := TRUE;
               END IF;
          ELSE
              V_CLAWBACK_AMNT := 0;
        END IF;
      ELSE
          V_CLAWBACK_AMNT := 0;
      END IF;

      IF V_CLAWBACK_MAXAMT_CHECK  THEN -- if sum of clawback amount exceeds configured clawback max amount,then clawback diff amt only
         IF (v_chrg_dtl_amt_sum < P_CLAWBACK_MAXAMT AND v_chrg_dtl_amt_sum+V_CLAWBACK_AMNT  > P_CLAWBACK_MAXAMT ) THEN
            V_CLAWBACK_AMNT := P_CLAWBACK_MAXAMT - v_chrg_dtl_amt_sum;
         END IF;
      END IF;
    IF V_CLAWBACK_AMNT > 0 THEN
        BEGIN

            SELECT COUNT(*)
            INTO V_CLAWBACK_COUNT
            FROM CMS_ACCTCLAWBACK_DTL
            WHERE CAD_INST_CODE = P_INSTCODE AND
            CAD_DELIVERY_CHANNEL = V_DELIVERY_CHANNEL AND
            CAD_TXN_CODE = V_TXN_CODE AND CAD_PAN_CODE = P_HASHPAN AND
            CAD_ACCT_NO = V_ACCT_NUMBER;

            IF V_CLAWBACK_COUNT = 0 THEN

                BEGIN
                    INSERT INTO CMS_ACCTCLAWBACK_DTL
                                        (CAD_INST_CODE,
                                        CAD_ACCT_NO,
                                        CAD_PAN_CODE,
                                        CAD_PAN_CODE_ENCR,
                                        CAD_CLAWBACK_AMNT,
                                        CAD_RECOVERY_FLAG,
                                        CAD_INS_DATE,
                                        CAD_LUPD_DATE,
                                        CAD_DELIVERY_CHANNEL,
                                        CAD_TXN_CODE,
                                        CAD_INS_USER,
                                        CAD_LUPD_USER)
                    VALUES
                                        (P_INSTCODE,
                                        V_ACCT_NUMBER,
                                        P_HASHPAN,
                                        P_ENCRPAN,
                                        ROUND(V_CLAWBACK_AMNT,2),  --Modified by Revathi on 02-APR-2014 for 3decimal place issue
                                        'N',
                                        SYSDATE,
                                        SYSDATE,
                                        V_DELIVERY_CHANNEL,
                                        V_TXN_CODE,
                                        '1',
                                        '1');
                EXCEPTION
                    WHEN OTHERS THEN
                        P_ERRMSG := 'Error while inserting Account ClawBack details' || SUBSTR(SQLERRM, 1, 200);
                        RAISE EXP_REJECT_RECORD;
                END;

                  ELSE
                BEGIN
                    UPDATE CMS_ACCTCLAWBACK_DTL
                    SET CAD_CLAWBACK_AMNT = ROUND(CAD_CLAWBACK_AMNT + V_CLAWBACK_AMNT,2),  --Modified by Revathi on 02-APR-2014 for 3decimal place issue
                    CAD_RECOVERY_FLAG = 'N',
                    CAD_LUPD_DATE     = SYSDATE
                    WHERE CAD_INST_CODE = P_INSTCODE AND
                    CAD_ACCT_NO = V_ACCT_NUMBER AND CAD_PAN_CODE = P_HASHPAN AND
                    CAD_DELIVERY_CHANNEL = V_DELIVERY_CHANNEL AND
                    CAD_TXN_CODE = V_TXN_CODE;

                    IF SQL%ROWCOUNT =0 THEN
                        P_ERRMSG := 'No records updated in ACCTCLAWBACK_DTL for pan='||P_HASHPAN;
                        RAISE EXP_REJECT_RECORD;
                    END IF;

                    EXCEPTION
                        WHEN EXP_REJECT_RECORD THEN
                            RAISE;
                        WHEN OTHERS THEN
                            P_ERRMSG := 'Error while Updating ACCTCLAWBACK_DTL' ||SUBSTR(SQLERRM, 1, 200);
                            RAISE EXP_REJECT_RECORD;
                END;

            END IF;
        EXCEPTION
            WHEN EXP_REJECT_RECORD THEN
                RAISE;
            WHEN OTHERS THEN
                P_ERRMSG := 'Error while inserting Account ClawBack details' || SUBSTR(SQLERRM, 1, 200);
                RAISE EXP_REJECT_RECORD;
        END;

         BEGIN
            INSERT INTO CMS_CHARGE_DTL
                            (CCD_INST_CODE,
                            CCD_PAN_CODE,
                            CCD_MBR_NUMB,
                            CCD_ACCT_NO,
                            CCD_FEE_FREQ,
                            CCD_FEETYPE_CODE,
                            CCD_FEE_CODE,
                            CCD_CALC_AMT,
                            CCD_EXPCALC_DATE,
                            CCD_CALC_DATE,
                            CCD_FILE_NAME,
                            CCD_FILE_DATE,
                            CCD_INS_USER,
                            CCD_LUPD_USER,
                            CCD_FILE_STATUS,
                            CCD_RRN,
                            CCD_DEBITED_AMNT,
                            CCD_PROCESS_MSG,
                            CCD_CLAWBACK_AMNT,
                            CCD_CLAWBACK,
                            CCD_FEE_PLAN,
                            CCD_PAN_CODE_ENCR,
                            CCD_GL_ACCT_NO,
                            CCD_DELIVERY_CHANNEL,
                            CCD_TXN_CODE,
                            CCD_FEEATTACHTYPE,
                            ccd_process_id)
            VALUES
                            (P_INSTCODE,
                            P_HASHPAN,
                            '000',
                            V_ACCT_NUMBER,
                            P_FEE_FREQ,
                            P_FEETYPE_CODE,
                            P_FEE_CODE,
                            ROUND(P_FEE_AMNT,2),  --Modified by Revathi on 02-APR-2014 for 3decimal place issue
                            SYSDATE,
                            SYSDATE,
                            'N',
                            SYSDATE,
                            P_LUPDUSER,
                            P_LUPDUSER,
                            V_FILE_STATUS,
                            V_RRN2,
                            ROUND(V_DEBIT_AMNT,2),  --Modified by Revathi on 02-APR-2014 for 3decimal place issue
                            P_ERRMSG,
                            ROUND(V_CLAWBACK_AMNT,2),  --Modified by Revathi on 02-APR-2014 for 3decimal place issue
                            P_CLAWBACK,
                            P_FEE_PLAN,
                            P_ENCRPAN,
                            P_CR_ACCTNO,
                            V_DELIVERY_CHANNEL,
                            V_TXN_CODE,
                            P_ATTACH_TYPE,
                            to_char(add_months(v_next_mb_date,-1),'MM'));
        EXCEPTION
            WHEN EXP_REJECT_RECORD THEN
                RAISE;
            WHEN OTHERS THEN
                P_ERRMSG := 'Error while inserting Fee details' || SUBSTR(SQLERRM, 1, 200);
                RAISE EXP_REJECT_RECORD;
        END;
        ELSE   --Added for Defect id : 15544
        P_ERRMSG :='CLAW BLACK WAIVED';
        END IF;
    end if;
    
    IF V_DEBIT_AMNT > 0 THEN

    LP_TRANSACTION_LOG(P_INSTCODE,
                        P_HASHPAN,
                        P_ENCRPAN,
                        V_RRN2    ,
                        V_DELIVERY_CHANNEL ,
                        V_BUSINESS_DATE,
                        V_BUSINESS_TIME,
                        V_ACCT_NUMBER   ,
                        V_ACCT_BAL - V_DEBIT_AMNT    ,
                        V_LEDGER_BAL - V_DEBIT_AMNT  ,
                        V_DEBIT_AMNT,  --Added by by RAVI N on 03-SEP-13 for regarding DFCCSD-84
                        V_AUTH_ID  ,
                        V_TRAN_DESC,
                        V_TXN_CODE,
                        1,
                        V_CARD_CURR ,
                        P_WAIV_AMNT,
                        P_FEE_CODE,
                        P_FEE_PLAN,
                        P_CR_ACCTNO,
                        P_DR_ACCTNO,
                        P_ATTACH_TYPE,
                        P_CARD_STAT,
                        V_CAM_TYPE_CODE,   -- Added on 17-Apr-2013 for defect 10871
                        v_timestamp,       -- Added on 17-Apr-2013 for defect 10871
                        p_prod_code,---Commented and modified on 06.09.2013 for DFCHOST-340(review)
                        P_CARD_TYPE ,---Commented and modified on 06.09.2013 for DFCHOST-340(review)
                        V_DR_CR_FLAG,      -- Added on 17-Apr-2013 for defect 10871
                        P_ERRMSG           -- Added on 17-Apr-2013 for defect 10871
                        );
        END IF;

EXCEPTION
    WHEN EXP_REJECT_RECORD THEN
        P_ERRMSG := 'Error in LP_FEE_UPDATE_LOG ' || P_ERRMSG;
    WHEN OTHERS THEN
        P_ERRMSG := 'Error in LP_FEE_UPDATE_LOG ' || SUBSTR(SQLERRM, 1, 200);
END LP_FEE_UPDATE_LOG;

--Added for regarding JH-13
PROCEDURE LP_CALC_CR_FREETXN (  P_INST_CODE  IN NUMBER,
                         P_NEXT_MB_DATE IN DATE,
                         P_ACTIV_DATE IN DATE,
                         P_PAN_NO     IN VARCHAR2,
                         P_FREE_TXNCNT IN NUMBER,
                         P_TXNFREE_AMT IN NUMBER,
                         P_FEEAMNT_TYPE IN VARCHAR2,
                         V_CFM_FEE_AMT    IN OUT NUMBER,
                         P_WAIV_FLAG    OUT VARCHAR2,
                         P_ERRMSG IN OUT VARCHAR2 ) AS

V_FROM_DATE DATE;
V_TO_DATE DATE;
V_FREE_TXNCNT CMS_FEE_MAST.CFM_FREE_TXNCNT%TYPE ;
V_TXNFREE_AMT CMS_FEE_MAST.CFM_TXNFREE_AMT%TYPE;

BEGIN

    P_ERRMSG := 'OK';
    P_WAIV_FLAG:='N';

    IF (P_FEEAMNT_TYPE IN ('A','O')) THEN
    IF P_NEXT_MB_DATE IS NOT NULL  THEN
        V_FROM_DATE :=ADD_MONTHS (P_NEXT_MB_DATE,-1);
        V_TO_DATE   :=P_NEXT_MB_DATE;
    ELSE
        V_FROM_DATE :=P_ACTIV_DATE;
        V_TO_DATE   :=ADD_MONTHS (P_ACTIV_DATE,1);
    END IF;

    BEGIN
        SELECT COUNT(*),SUM(AMOUNT)
        INTO V_FREE_TXNCNT,V_TXNFREE_AMT
        FROM  TRANSACTIONLOG WHERE
        CR_DR_FLAG ='CR' and response_code = '00' and   NVL(TRAN_REVERSE_FLAG,'N') = 'N'
        and ((DELIVERY_CHANNEL ='08' and TXN_CODE = '22')
        or
        ((DELIVERY_CHANNEL ='11' and TXN_Code in ('22', '32')) and NVL(ach_exception_queue_flag,'N') <>'FD'))
        and  CUSTOMER_CARD_NO =P_PAN_NO
        AND INSTCODE= P_INST_CODE
        and ADD_INS_DATE between V_FROM_DATE and V_TO_DATE;
    EXCEPTION
        WHEN NO_DATA_FOUND THEN
            P_WAIV_FLAG:='N';
            P_ERRMSG := 'OK';
        WHEN OTHERS THEN
            P_WAIV_FLAG:='N';
            P_ERRMSG := 'ERROR Whiling in CR transaction check ' || SUBSTR(SQLERRM, 1, 200);
    END;
    IF(V_FREE_TXNCNT=0) THEN
    V_FREE_TXNCNT :=-1; -- to restrict free waiver in case of amount only configured
    END IF;
    BEGIN
        IF(P_FEEAMNT_TYPE='A') THEN

            IF(V_FREE_TXNCNT >=P_FREE_TXNCNT     AND V_TXNFREE_AMT  >=P_TXNFREE_AMT ) THEN
                V_CFM_FEE_AMT:=0;
                P_WAIV_FLAG:='Y';
            ELSE
                P_WAIV_FLAG:='N';
            END IF;

        ELSIF (P_FEEAMNT_TYPE='O') THEN

            IF(V_FREE_TXNCNT >=P_FREE_TXNCNT  OR V_TXNFREE_AMT  >=P_TXNFREE_AMT  ) THEN
                V_CFM_FEE_AMT:=0;
                P_WAIV_FLAG:='Y';
            ELSE
                P_WAIV_FLAG:='N';
            END IF;

        ELSE
            P_WAIV_FLAG:='N';
        END IF;
    Exception
        When others then
            P_ERRMSG := 'ERROR While calculating in waiver logic ' || SUBSTR(SQLERRM, 1, 200);
    END;
    END IF;
Exception
    When others then
        P_ERRMSG := 'ERROR in LP_CALC_CR_FREETXN ' || SUBSTR(SQLERRM, 1, 200);
END LP_CALC_CR_FREETXN;

PROCEDURE LP_UPDATE_NEXT_MB_DATE(P_PAN_CODE IN  CMS_APPL_PAN.CAP_PAN_CODE%TYPE) AS
    BEGIN
     UPDATE CMS_APPL_PAN
        SET CAP_NEXT_MB_DATE = V_NEXT_MB_DATE, -- ADD_MONTHS(SYSDATE, 1) -- Changed for defect HOST-328
        cap_cafgen_date=sysdate --added for DFCCSD-101 on 04/04/14
        WHERE CAP_PAN_CODE = P_PAN_CODE AND
        CAP_CARD_STAT NOT IN ('9') AND CAP_INST_CODE = P_INSTCODE;
        
        --SN Commented and modified on 06.09.2013 for DFCHOST-340(review)
        IF SQL%ROWCOUNT =0 THEN
            V_ERR_MSG := 'No records updated in APPL_PAN for pan 1.0 ='||P_PAN_CODE;
            RAISE EXP_REJECT_RECORD;
        END IF;

    EXCEPTION
        WHEN  EXP_REJECT_RECORD THEN
            RAISE;
        WHEN OTHERS THEN
            V_ERR_MSG := 'Error while upadating APPL_PAN 1.0 ' || SUBSTR(SQLERRM, 1, 200);
            RAISE EXP_REJECT_RECORD;
END LP_UPDATE_NEXT_MB_DATE;

--/* Added for VMS-2183 State Restriction logic for monthly fee calculation*/  STARTS

PROCEDURE LP_STATE_RESTRICT_CHK(P_PROD_CODE 	IN VARCHAR2,
								P_CARD_TYPE 	IN NUMBER,
								P_CUST_CODE 	IN NUMBER,
								P_PAN_CODE		IN VARCHAR2,
								P_FEE_FLAG  	OUT VARCHAR2,
								P_ERRMSG		OUT VARCHAR2
								) AS

V_STRULE_NOT_CONFIG  VARCHAR2(1) DEFAULT 'Y';
V_STATE_COUNT 		PLS_INTEGER DEFAULT 0;
V_ADD_STATE_CODE	GEN_STATE_MAST.GSM_STATE_CODE%TYPE;
V_ERRMSG			VARCHAR2(1000);
EXP_REJECT			EXCEPTION;

BEGIN
	P_FEE_FLAG := 'Y';
	P_ERRMSG   := 'OK';

			
			BEGIN
				SELECT GSM_STATE_CODE
				INTO	
					   V_ADD_STATE_CODE
				FROM
				(
				SELECT
						GSM_STATE_CODE	
				FROM
						VMS_ORDER_DETAILS,
						VMS_LINE_ITEM_DTL,
						GEN_STATE_MAST
				WHERE
						VOD_ORDER_ID = VLI_ORDER_ID
						AND VOD_PARTNER_ID = VLI_PARTNER_ID
						AND GSM_SWITCH_STATE_CODE = FN_DMAPS_MAIN(VOD_STATE)
						AND VLI_PAN_CODE = P_PAN_CODE
						ORDER BY VOD_INS_DATE DESC
				)
				WHERE ROWNUM = 1;
			EXCEPTION
				WHEN NO_DATA_FOUND THEN
					BEGIN
						SELECT 
							GSM_STATE_CODE
						INTO	
							V_ADD_STATE_CODE
						FROM
							CMS_ADDR_MAST,
							GEN_STATE_MAST
						WHERE
						FN_DMAPS_MAIN(CAM_STATE_SWITCH) = GSM_SWITCH_STATE_CODE
						AND CAM_INST_CODE = GSM_INST_CODE
						AND CAM_CUST_CODE = P_CUST_CODE
						AND CAM_ADDR_FLAG = 'O';
					EXCEPTION
						WHEN NO_DATA_FOUND THEN
							BEGIN
								SELECT 
									GSM_STATE_CODE
								INTO	
									V_ADD_STATE_CODE
								FROM
									CMS_ADDR_MAST,
									GEN_STATE_MAST
								WHERE
								FN_DMAPS_MAIN(CAM_STATE_SWITCH) = GSM_SWITCH_STATE_CODE
								AND CAM_INST_CODE = GSM_INST_CODE
								AND CAM_CUST_CODE = P_CUST_CODE
								AND CAM_ADDR_FLAG = 'P';
							EXCEPTION
								WHEN NO_DATA_FOUND THEN
									V_STRULE_NOT_CONFIG := 'N';
								WHEN OTHERS THEN
									V_ERRMSG := 'Error while selecting physical address ' || SUBSTR (SQLERRM, 1, 200);
									RAISE EXP_REJECT;
							END;
						WHEN OTHERS THEN
							V_ERRMSG := 'Error while selecting mailing address ' || SUBSTR (SQLERRM, 1, 200);
							RAISE EXP_REJECT;
					END;
				WHEN OTHERS THEN
					V_ERRMSG := 'Error while selecting order address ' || SUBSTR (SQLERRM, 1, 200);
					RAISE EXP_REJECT;
			END;
			
			IF V_STRULE_NOT_CONFIG = 'Y' THEN 
			BEGIN
				SELECT 	COUNT(1) 
				INTO	V_STATE_COUNT
				FROM	VMS_STATE_RESTRICTION
				WHERE	vsr_prod_code = P_PROD_CODE
				AND 	vsr_card_type = P_CARD_TYPE
				AND 	VSR_FEE_TYPE  = 'M'
				AND 	VSR_RULE_BASED = 'N'
				AND 	VSR_STATE_CODE = V_ADD_STATE_CODE;
				
			EXCEPTION
				WHEN OTHERS THEN
					V_ERRMSG := 'Error while selecting state restriction rule ' || SUBSTR (SQLERRM, 1, 200);
					RAISE EXP_REJECT;
			END;
					
			
				IF  V_STATE_COUNT <> 0 THEN
					P_FEE_FLAG:='N';
				END IF;
			END IF;

      EXCEPTION  
		 WHEN EXP_REJECT THEN
			P_ERRMSG := V_ERRMSG;
         WHEN  OTHERS  THEN
            P_ERRMSG :=
                'Error while selecting state restriction rule ' || SUBSTR (SQLERRM, 1, 200);
END LP_STATE_RESTRICT_CHK;

--/* Added for VMS-2183 State Restriction logic for monthly fee calculation*/  ENDS

BEGIN--Main begin

    BEGIN
        FOR C1 IN CARDFEE
        LOOP
		
		  BEGIN

                v_err_msg:='OK';
                v_free_txn:='N';
                v_count:=1;
				V_FEE_FLAG := 'Y';

                --Start Added by Saravanankumar on 22-Jul-2015
                --SN:Modified for multiple monthly fee issue
                --if c1.cap_active_date is null then
		
		--/* Added for VMS-2183 State Restriction logic for monthly fee calculation.
				
		IF C1.STATERESTFLAG = 'Y' THEN
			LP_STATE_RESTRICT_CHK	(C1.CAP_PROD_CODE,
						C1.CAP_CARD_TYPE,   
						C1.CAP_CUST_CODE,
						C1.CCE_PAN_CODE,
						V_FEE_FLAG,
						V_ERR_MSG
						);
			
			IF V_ERR_MSG <> 'OK' THEN
				RAISE EXP_REJECT_RECORD;
			END IF;
			
		END IF;
			
		IF V_FEE_FLAG = 'Y' THEN
		
		--/* Added for VMS-2183 State Restriction logic for monthly fee calculation*/ STARTS
                    begin
                        SELECT SUM(decode(cap_card_stat,'9',0,1)), MAX(cap_next_mb_date)
                        INTO v_count, c1.cap_next_mb_date
                        FROM cms_appl_pan
                        WHERE cap_inst_code=p_instcode
                          AND cap_acct_no=c1.cap_acct_no;
                          --AND cap_card_stat <>'9';
                        IF c1.cap_active_date IS NOT NULL THEN
                           v_count:=1;
                        END IF;
                     EXCEPTION
                        WHEN OTHERS THEN
                           P_ERRMSG := 'Error in getting the count ' || SUBSTR(SQLERRM, 1, 200);
                    end;

                --end if;
                 --EN:Modified for multiple monthly fee issue

                --End Added by Saravanankumar on 22-Jul-2015

                IF v_count=1 then-- Added by Saravanankumar on 22-Jul-2015
                    --Start Added by Saravanankumar on 22-Jul-2015

                    --SN:Modified for multiple monthly fee issue
                    IF c1.cap_repl_flag<>0 then

                        BEGIN
                            SELECT min(cap_active_date)--,cap_next_mb_date
                            INTO v_old_active_date--,old_next_mb_date
                            FROM CMS_APPL_PAN
                            WHERE cap_acct_no=c1.cap_acct_no
                            and cap_startercard_flag='N';
                            /*CAP_PAN_CODE = (SELECT chr_pan_code
                                                   FROM cms_htlst_reisu
                                                   WHERE chr_new_pan=c1.cce_pan_code);*/

                            IF v_old_active_date IS NULL AND c1.cap_active_date IS NULL AND c1.cfm_date_assessment <> 'FLI' THEN
                               CONTINUE;
                            ELSIF ( V_OLD_ACTIVE_DATE IS NOT NULL AND C1.CAP_NEXT_MB_DATE IS NOT NULL) OR
                            (v_old_active_date IS NOT NULL AND trunc(ADD_MONTHS(v_old_active_date,1)) >= trunc(SYSDATE) AND c1.cap_next_mb_date IS NULL) THEN
                               c1.cap_active_date :=v_old_active_date;
                            END IF;
                            /*if c1.cap_next_mb_date is null then
                                c1.cap_next_mb_date:=old_next_mb_date;
                            end if;*/

                        EXCEPTION
                            WHEN no_data_found THEN
                                null;
                            WHEN others THEN
                                P_ERRMSG := 'Error in getting old card active date ' || SUBSTR(SQLERRM, 1, 200);
                        end;

                        /*IF c1.cap_next_mb_date IS NOT NULL THEN
                            c1.cap_active_date := v_old_active_date;
                        ELSE
                            IF add_months(c1.cap_active_date,1) >= SYSDATE THEN
                                c1.cap_active_date := v_old_active_date;
                            END IF;
                        END IF;*/
                    END IF;
                    --EN:Modified for multiple monthly fee issue

                    --End Added by Saravanankumar on 22-Jul-2015
                    BEGIN
                        SELECT cam_type_code, cam_acct_bal, cam_ledger_bal,
                        cam_first_load_date,cam_monthlyfee_counter --Added by Pankaj S. for JH - Monthly Fee Waiver changes
                        INTO v_cam_type_code, v_acct_bal, v_ledger_bal,
                        v_first_load_date,v_monthlyfee_counter
                        FROM cms_acct_mast
                        WHERE cam_inst_code = p_instcode
                        AND cam_acct_id = c1.cap_acct_id;
                    EXCEPTION
                       WHEN OTHERS THEN
                            v_err_msg :='Error occured while fetching acct dtls 1.0 -'|| c1.cap_acct_id|| SUBSTR (SQLERRM, 1, 100);
                            RAISE EXP_REJECT_RECORD;
                    end;


                    IF c1.cfm_max_limit=0 OR v_monthlyfee_counter < c1.cfm_max_limit  THEN  --Added by Pankaj S. for JH - Monthly Fee Waiver

                        IF c1.cfm_date_assessment='AL' OR c1.cfm_date_assessment ='FLI' THEN

                            IF v_first_load_date IS NULL THEN

                                IF c1.cap_next_mb_date IS NULL THEN
                                    BEGIN
                                        SELECT MIN (add_ins_date)
                                        INTO v_first_load_date
                                        FROM transactionlog
                                        WHERE instcode=p_instcode
                                        AND customer_card_no = c1.cce_pan_code
                                        AND ((delivery_channel = '04' AND txn_code IN ('68', '80', '82', '85', '88'))
                                        OR (delivery_channel = '08' AND txn_code IN ('22', '26'))
                                        OR (delivery_channel = '11' AND txn_code = '22'))
                                        AND amount > 0
                                        AND (tran_reverse_flag IS NULL OR tran_reverse_flag='N');
                                    EXCEPTION
                                        WHEN OTHERS THEN
                                            v_err_msg := 'Error while fetching first_load_date_1.0 -' || SUBSTR(SQLERRM, 1, 200);
                                            RAISE EXP_REJECT_RECORD;
                                    END;
                                ELSE
                                    v_first_load_date:=c1.cap_active_date;
                               END IF;

                                BEGIN
                                    UPDATE cms_acct_mast
                                    SET cam_first_load_date =v_first_load_date
                                    WHERE cam_inst_code = p_instcode
                                    AND cam_acct_id = c1.cap_acct_id;

                                    IF SQL%ROWCOUNT = 0 THEN
                                        v_err_msg :='No records updated in Acct_mast for first_load_date_1.0 -';
                                        RAISE EXP_REJECT_RECORD;
                                    END IF;

                                EXCEPTION
                                    WHEN  EXP_REJECT_RECORD THEN
                                        RAISE;
                                    WHEN OTHERS THEN
                                        v_err_msg :='Error while upadating first_load_date_1.0 -' || SUBSTR (SQLERRM, 1, 200);
                                        RAISE EXP_REJECT_RECORD;
                                END;
                            END IF;

                            BEGIN
                                SELECT  CASE WHEN ROUND(MONTHS_BETWEEN (nvl(c1.cap_next_mb_date,v_first_load_date),v_first_load_date)) < 0
                                        THEN 1
                                        ELSE ROUND(MONTHS_BETWEEN (nvl(c1.cap_next_mb_date,v_first_load_date),v_first_load_date)) +1 END
                                INTO v_month_diff
                                FROM DUAL;
                            EXCEPTION
                                WHEN OTHERS THEN
                                    v_err_msg :='Error while finding month_diff_1.0 -' || SUBSTR (SQLERRM, 1, 200);
                                    RAISE EXP_REJECT_RECORD;
                            END;
                        ELSE
                            BEGIN
                                 SELECT  CASE WHEN ROUND(MONTHS_BETWEEN (nvl(c1.cap_next_mb_date,c1.cap_active_date),c1.cap_active_date)) < 0
                                        THEN 1
                                        ELSE ROUND(MONTHS_BETWEEN (nvl(c1.cap_next_mb_date,c1.cap_active_date),c1.cap_active_date)) +1 END
                                INTO v_month_diff
                                FROM DUAL;
                            EXCEPTION
                                WHEN OTHERS THEN
                                    v_err_msg :='Error while finding month_diff_1.1 -' || SUBSTR (SQLERRM, 1, 200);
                                    RAISE EXP_REJECT_RECORD;
                            END;
                        END IF;

                        BEGIN
                            LP_MONTHLY_FEE_CALC(C1.CFM_DATE_ASSESSMENT,
                                                C1.CFM_PRORATION_FLAG,
                                                C1.CFM_FEE_AMT,
                                                C1.CAP_NEXT_MB_DATE,
                                                C1.CCE_PAN_CODE,
                                                P_INSTCODE,
                                                case when c1.cfm_date_assessment IN ('AL', 'FLI') then v_first_load_date else C1.CAP_ACTIVE_DATE end,--Added by Pankaj S. for JH - Monthly Fee Waiver
                                                greatest(C1.cce_valid_from,c1.cfm_ins_date), --CCE_INS_DATE,
                                                C1.CFM_ASSESSED_DAYS,--DFCTNM-32
                                                V_CFM_FEE_AMT,
                                                V_ERR_MSG);

                            IF V_ERR_MSG <> 'OK' and V_ERR_MSG <> 'NO FEES' THEN
                                v_err_msg :='Error in LP_MONTHLY_FEE_CALC -' || V_ERR_MSG;
                                RAISE EXP_REJECT_RECORD;
                            END IF;

                        EXCEPTION
                            WHEN EXP_REJECT_RECORD THEN
                                RAISE;
                            WHEN OTHERS THEN
                                v_err_msg :='Error while finding month_diff_1.1 -' || SUBSTR (SQLERRM, 1, 200);
                                RAISE EXP_REJECT_RECORD;
                        END;

                        IF V_ERR_MSG <> 'NO FEES' THEN --Added by Saravanakumar for logging issue on 28-Oct-2014
                        --Sn Added by Pankaj S. for JH - Monthly Fee Waiver
                            IF c1.cfm_free_txncnt >= v_month_diff THEN
                                v_cfm_fee_amt := 0;
                                v_free_txn:='Y';
                            END IF;

                            LP_UPDATE_NEXT_MB_DATE(C1.CCE_PAN_CODE);
                        --En Added by Pankaj S. for JH - Monthly Fee Waiver

                            IF v_free_txn='N' THEN --v_free_txn condition Added by Pankaj S. for JH - Monthly Fee Waiver
                                BEGIN
                                    LP_CALC_CR_FREETXN(P_INSTCODE,
                                                        C1.CAP_NEXT_MB_DATE,
                                                        case when c1.cfm_date_assessment IN ('AL', 'FLI')  then v_first_load_date else C1.CAP_ACTIVE_DATE end, --Added by Pankaj S. for JH - Monthly Fee Waiver
                                                        C1.CCE_PAN_CODE,
                                                        c1.cfm_crfree_txncnt,--C1.CFM_FREE_TXNCNT, --Modified by Pankaj S. for JH-monthly fee waiver
                                                        C1.CFM_TXNFREE_AMT,
                                                        C1.CFM_FEEAMNT_TYPE,
                                                        V_CFM_FEE_AMT,
                                                        V_WAIV_FLAG,
                                                        V_ERR_MSG);

                                    IF V_ERR_MSG <> 'OK' THEN
                                        v_err_msg :='Error in LP_CALC_CR_FREETXN -' || V_ERR_MSG;
                                        RAISE EXP_REJECT_RECORD;
                                    END IF;

                                EXCEPTION
                                    WHEN EXP_REJECT_RECORD THEN
                                        RAISE;
                                    WHEN OTHERS THEN
                                        v_err_msg :='Error while calling LP_CALC_CR_FREETXN -' || SUBSTR (SQLERRM, 1, 200);
                                        RAISE EXP_REJECT_RECORD;
                                END;

                                -- SN Modified for FWR-11
                                IF C1.CFM_FEECAP_FLAG ='Y' then
                                    BEGIN
                                        SP_TRAN_FEES_CAP(P_INSTCODE,
                                                        C1.CAP_ACCT_NO,
                                                        TRUNC(SYSDATE),
                                                        V_CFM_FEE_AMT,
                                                        C1.CFF_FEE_PLAN,
                                                        C1.CFM_FEE_CODE,
                                                        V_ERR_MSG
                                                        ); -- Added for FWR-11

                                        IF V_ERR_MSG <> 'OK' THEN
                                            v_err_msg :='Error in SP_TRAN_FEES_CAP -' || V_ERR_MSG;
                                            RAISE EXP_REJECT_RECORD;
                                        END IF;

                                    EXCEPTION
                                        WHEN EXP_REJECT_RECORD THEN
                                            RAISE;
                                        WHEN OTHERS THEN
                                            v_err_msg :='Error while calling SP_TRAN_FEES_CAP -' || SUBSTR (SQLERRM, 1, 200);
                                            RAISE EXP_REJECT_RECORD;
                                    END;
                                END IF;
                           -- END IF; --Added for JH-13

                             BEGIN
                                SELECT CCE_WAIV_PRCNT
                                INTO V_CPW_WAIV_PRCNT
                                FROM CMS_CARD_EXCPWAIV
                                WHERE CCE_INST_CODE = P_INSTCODE AND
                                CCE_PAN_CODE = C1.CCE_PAN_CODE AND
                                CCE_FEE_CODE = C1.CFM_FEE_CODE AND
                                CCE_FEE_PLAN = C1.CFF_FEE_PLAN AND
                                ((CCE_VALID_TO IS NOT NULL AND (SYSDATE between cce_valid_from and CCE_VALID_TO))
                                OR (CCE_VALID_TO IS NULL AND SYSDATE >= cce_valid_from));

                                V_WAIVAMT := (V_CPW_WAIV_PRCNT / 100) * V_CFM_FEE_AMT;
                            EXCEPTION
                                WHEN OTHERS THEN
                                    V_WAIVAMT := 0;
                            END;

                            BEGIN
                                v_tot_clwbck_count := C1.cfm_clawback_count;
                                LP_FEE_UPDATE_LOG(P_INSTCODE,
                                                C1.CCE_PAN_CODE,
                                                C1.CCE_PAN_CODE_ENCR,
                                                C1.CFM_FEE_CODE,
                                                V_CFM_FEE_AMT,
                                                C1.CFF_FEE_PLAN,
                                                C1.CCE_CRGL_CATG,
                                                C1.CCE_CRGL_CODE,
                                                C1.CCE_CRSUBGL_CODE,
                                                C1.CCE_CRACCT_NO,
                                                C1.CCE_DRGL_CATG,
                                                C1.CCE_DRGL_CODE,
                                                C1.CCE_DRSUBGL_CODE,
                                                C1.CCE_DRACCT_NO,
                                                C1.CFM_CLAWBACK_FLAG,
                                                C1.CFT_FEE_FREQ,
                                                C1.CFT_FEETYPE_CODE,
                                                P_LUPDUSER,
                                                V_WAIVAMT,
                                                'C',
                                                C1.CAP_CARD_STAT,
                                                C1.CAP_ACCT_NO,--Added on 06.09.2013 for DFCHOST-340(review)
                                                C1.CAP_PROD_CODE,--Added on 06.09.2013 for DFCHOST-340(review)
                                                C1.CAP_CARD_TYPE,--Added on 06.09.2013 for DFCHOST-340(review)
                                                V_WAIV_FLAG, --Add on 26/09/13 For regarding JH-13
                                                v_free_txn,   --Added by Pankaj S. for JH - Monthly Fee Waiver
                                                C1.CFM_FEE_DESC,-- Added 02/03/14 for regarding MVCSD-4471
                                                --DFCTNM-32
                                                C1.CFM_CLAWBACK_TYPE,
                                                C1.CFM_CLAWBACK_MAXAMT,
                                                V_ERR_MSG);
                                IF V_ERR_MSG <> 'OK'  and V_ERR_MSG <> 'CLAW BLACK WAIVED' THEN
                                    v_err_msg :='Error in LP_FEE_UPDATE_LOG -' || V_ERR_MSG;
                                    RAISE EXP_REJECT_RECORD;
                                END IF;

                            EXCEPTION
                                WHEN EXP_REJECT_RECORD THEN
                                    RAISE;
                                WHEN OTHERS THEN
                                    v_err_msg :='Error while calling LP_FEE_UPDATE_LOG -' || SUBSTR (SQLERRM, 1, 200);
                                    RAISE EXP_REJECT_RECORD;
                            END;

                           --Sn Added by Pankaj S. for JH - Monthly Fee Waiver
                           -- IF v_free_txn = 'N' THEN
                           
                           
                             IF V_DEBIT_AMNT > 0 THEN
                                BEGIN
                                    UPDATE cms_acct_mast
                                    SET cam_monthlyfee_counter =cam_monthlyfee_counter+1
                                    WHERE cam_inst_code = p_instcode
                                    AND cam_acct_id = c1.cap_acct_id;

                                    IF SQL%ROWCOUNT = 0 THEN
                                        V_ERR_MSG :='No records updated in Acct_mast for acct 1.0 -';
                                        RAISE EXP_REJECT_RECORD;
                                    END IF;

                                EXCEPTION
                                    WHEN EXP_REJECT_RECORD THEN
                                        RAISE ;
                                    WHEN OTHERS THEN
                                        V_ERR_MSG :='Error while upadating Acct_mast 1.0 -' || SUBSTR (SQLERRM, 1, 200);
                                        RAISE EXP_REJECT_RECORD;
                                END;
                              END IF;
                            END IF;

                            --SN Added on 10.09.2013 for DFCHOST-340(review)
                            COMMIT;  --Added for FSS-1762 - Commit should be happened at row level in Monthly Fee job
                        END IF;
                    END IF;--Added by Pankaj S. for JH - Monthly Fee Waiver
                END IF; -- Added by Saravanankumar on 22-Jul-2015
		END IF; --/* Added for VMS-2183 State Restriction logic for monthly fee calculation*/ ENDS
            EXCEPTION--Main excetpion
                WHEN EXP_REJECT_RECORD THEN
                    ROLLBACK;

                    BEGIN
                        INSERT INTO CMS_CHARGE_DTL
                                        (CCD_INST_CODE,
                                        CCD_PAN_CODE,
                                        CCD_MBR_NUMB,
                                        CCD_ACCT_NO,
                                        CCD_FEE_FREQ,
                                        CCD_FEETYPE_CODE,
                                        CCD_FEE_CODE,
                                        CCD_CALC_AMT,
                                        CCD_EXPCALC_DATE,
                                        CCD_CALC_DATE,
                                        CCD_FILE_NAME,
                                        CCD_FILE_DATE,
                                        CCD_INS_USER,
                                        CCD_LUPD_USER,
                                        CCD_FILE_STATUS,
                                        CCD_RRN,
                                        CCD_PROCESS_MSG,
                                        CCD_FEE_PLAN,
                                        CCD_PAN_CODE_ENCR,
                                        CCD_GL_ACCT_NO,
                                        CCD_DELIVERY_CHANNEL,
                                        CCD_TXN_CODE)
                        VALUES
                                        (P_INSTCODE,
                                        C1.CCE_PAN_CODE,
                                        '000',
                                        C1.CAP_ACCT_NO,
                                        C1.CFT_FEE_FREQ,
                                        C1.CFT_FEETYPE_CODE,
                                        C1.CFM_FEE_CODE,
                                        ROUND(V_CFM_FEE_AMT,2),  --Modified by Revathi on 02-APR-2014 for 3decimal place issue
                                        SYSDATE,
                                        SYSDATE,
                                        'N',
                                        SYSDATE,
                                        P_LUPDUSER,
                                        P_LUPDUSER,
                                        'E',
                                        V_RRN2, --Modified by Deepa on July 02 2012 for the error record to have different status
                                        V_ERR_MSG,
                                        C1.CFF_FEE_PLAN,
                                        C1.CCE_PAN_CODE_ENCR,
                                        C1.CCE_CRACCT_NO,
                                        V_DELIVERY_CHANNEL,
                                        V_TXN_CODE);
                    EXCEPTION
                        WHEN OTHERS THEN
                            P_ERRMSG := 'Error while inserting into CHARGE_DTL 1.0 ' || SUBSTR(SQLERRM, 1, 200);
                    END;

                    BEGIN
                        LP_TRANSACTION_LOG(p_instcode,
                                            c1.cce_pan_code,
                                            c1.cce_pan_code_encr,
                                            v_rrn2,
                                            v_delivery_channel,
                                            v_business_date,
                                            v_business_time,
                                            c1.cap_acct_no,
                                            v_acct_bal,
                                            v_ledger_bal,
                                            null,
                                            v_auth_id,
                                            v_tran_desc,
                                            v_txn_code,
                                            21,
                                            NULL ,
                                            NULL,
                                            c1.cfm_fee_code,
                                            c1.cff_fee_plan,
                                            c1.cce_cracct_no,
                                            c1.cce_dracct_no,
                                            'C',
                                            c1.cap_card_stat,
                                            v_cam_type_code,
                                            v_timestamp  ,
                                            c1.cap_prod_code,
                                            c1.cap_card_type,
                                            V_DR_CR_FLAG,
                                            v_err_msg
                                            );
                    EXCEPTION
                        WHEN OTHERS THEN
                            V_ERR_MSG :='Error while calling LP_TRANSACTION_LOG-' || SUBSTR (SQLERRM, 1, 200);
                    END;
                    COMMIT;
                WHEN OTHERS THEN
                    ROLLBACK;
                    V_ERR_MSG :='Error in main loop -' || SUBSTR (SQLERRM, 1, 200);

                    BEGIN
                        INSERT INTO CMS_CHARGE_DTL
                                        (CCD_INST_CODE,
                                        CCD_PAN_CODE,
                                        CCD_MBR_NUMB,
                                        CCD_ACCT_NO,
                                        CCD_FEE_FREQ,
                                        CCD_FEETYPE_CODE,
                                        CCD_FEE_CODE,
                                        CCD_CALC_AMT,
                                        CCD_EXPCALC_DATE,
                                        CCD_CALC_DATE,
                                        CCD_FILE_NAME,
                                        CCD_FILE_DATE,
                                        CCD_INS_USER,
                                        CCD_LUPD_USER,
                                        CCD_FILE_STATUS,
                                        CCD_RRN,
                                        CCD_PROCESS_MSG,
                                        CCD_FEE_PLAN,
                                        CCD_PAN_CODE_ENCR,
                                        CCD_GL_ACCT_NO,
                                        CCD_DELIVERY_CHANNEL,
                                        CCD_TXN_CODE)
                        VALUES
                                        (P_INSTCODE,
                                        C1.CCE_PAN_CODE,
                                        '000',
                                        C1.CAP_ACCT_NO,
                                        C1.CFT_FEE_FREQ,
                                        C1.CFT_FEETYPE_CODE,
                                        C1.CFM_FEE_CODE,
                                        ROUND(V_CFM_FEE_AMT,2),  --Modified by Revathi on 02-APR-2014 for 3decimal place issue
                                        SYSDATE,
                                        SYSDATE,
                                        'N',
                                        SYSDATE,
                                        P_LUPDUSER,
                                        P_LUPDUSER,
                                        'E',
                                        V_RRN2, --Modified by Deepa on July 02 2012 for the error record to have different status
                                        V_ERR_MSG,
                                        C1.CFF_FEE_PLAN,
                                        C1.CCE_PAN_CODE_ENCR,
                                        C1.CCE_CRACCT_NO,
                                        V_DELIVERY_CHANNEL,
                                        V_TXN_CODE);
                    EXCEPTION
                        WHEN OTHERS THEN
                            P_ERRMSG := 'Error while inserting into CHARGE_DTL 1.0 ' || SUBSTR(SQLERRM, 1, 200);
                    END;

                    BEGIN
                        LP_TRANSACTION_LOG(p_instcode,
                                            c1.cce_pan_code,
                                            c1.cce_pan_code_encr,
                                            v_rrn2,
                                            v_delivery_channel,
                                            v_business_date,
                                            v_business_time,
                                            c1.cap_acct_no,
                                            v_acct_bal,
                                            v_ledger_bal,
                                            null,
                                            v_auth_id,
                                            v_tran_desc,
                                            v_txn_code,
                                            21,
                                            NULL ,
                                            NULL,
                                            c1.cfm_fee_code,
                                            c1.cff_fee_plan,
                                            c1.cce_cracct_no,
                                            c1.cce_dracct_no,
                                            'C',
                                            c1.cap_card_stat,
                                            v_cam_type_code,
                                            v_timestamp  ,
                                            c1.cap_prod_code,
                                            c1.cap_card_type,
                                            V_DR_CR_FLAG,
                                            v_err_msg
                                            );
                    EXCEPTION
                        WHEN OTHERS THEN
                            V_ERR_MSG :='Error while calling LP_TRANSACTION_LOG-' || SUBSTR (SQLERRM, 1, 200);
                    END;
                    COMMIT;
            END;
        END LOOP;
    END;
  --En InActivity Fee Calculation for the Card

  --Sn InActivity Fee Calculation for the Product Category
    BEGIN
        FOR C2 IN PRODCATGFEE
        LOOP
            BEGIN

                v_err_msg:='OK';
                v_free_txn:='N';
                v_count := 1;
				V_FEE_FLAG := 'Y';
			
	--/* Modified for VMS-2183 State Restriction logic for monthly fee calculation*/
		IF C2.STATERESTFLAG = 'Y' THEN
			LP_STATE_RESTRICT_CHK	(C2.CAP_PROD_CODE,
						C2.CAP_CARD_TYPE,   
						C2.CAP_CUST_CODE,
						C2.CAP_PAN_CODE,
						V_FEE_FLAG,
						V_ERR_MSG
						);
			
			IF V_ERR_MSG <> 'OK' THEN
				RAISE EXP_REJECT_RECORD;
			END IF;
			
		END IF;
			
	    IF V_FEE_FLAG = 'Y' THEN
	--/* Added for VMS-2183 State Restriction logic for monthly fee calculation*/ STARTS

                --SN:Modified for multiple monthly fee issue
                --if c2.cap_active_date is null then

                    begin
                        SELECT SUM(decode(cap_card_stat,'9',0,1)), MAX(cap_next_mb_date)
                        INTO v_count, c2.cap_next_mb_date
                        FROM cms_appl_pan
                        WHERE cap_inst_code=p_instcode
                          AND cap_acct_no=c2.cap_acct_no;
                        --AND cap_card_stat <>'9';

                        IF c2.cap_active_date IS NOT NULL THEN
                            v_count := 1;
                        END IF;
                     EXCEPTION
                            WHEN OTHERS THEN
                               P_ERRMSG := 'Error in getting the count ' || SUBSTR(SQLERRM, 1, 200);
                      end;

                --end if;
                --EN:Modified for multiple monthly fee issue

                IF v_count=1 then

                    --SN:Modified for multiple monthly fee issue
                    IF c2.cap_repl_flag<>0 then
                        BEGIN
                            SELECT min(cap_active_date)--,cap_next_mb_date
                            INTO v_old_active_date--,old_next_mb_date
                            FROM CMS_APPL_PAN
                            WHERE cap_acct_no=c2.cap_acct_no
                            and cap_startercard_flag='N';
                            /*CAP_PAN_CODE = (SELECT chr_pan_code
                                                   FROM cms_htlst_reisu
                                                   WHERE chr_new_pan=c2.cce_pan_code);*/

                            IF v_old_active_date IS NULL AND c2.cap_active_date IS NULL THEN
                               CONTINUE;
                            ELSIF ( V_OLD_ACTIVE_DATE IS NOT NULL AND C2.CAP_NEXT_MB_DATE IS NOT NULL) OR
                            (v_old_active_date IS NOT NULL AND trunc(ADD_MONTHS(v_old_active_date,1)) >= trunc(SYSDATE) AND c2.cap_next_mb_date IS NULL) THEN
                               c2.cap_active_date :=v_old_active_date;
                            END IF;
                                  /*if c2.cap_next_mb_date is null then
                                c2.cap_next_mb_date:=old_next_mb_date;
                            end if;*/

                        EXCEPTION
                           WHEN no_data_found THEN
                                null;
                            WHEN others THEN
                                P_ERRMSG := 'Error in getting old card active date ' || SUBSTR(SQLERRM, 1, 200);
                        END;

                        /*IF c2.cap_next_mb_date IS NOT NULL THEN
                            c2.cap_active_date := v_old_active_date;
                        ELSE
                            IF add_months(c2.cap_active_date,1) >= SYSDATE THEN
                                c2.cap_active_date := v_old_active_date;
                            END IF;
                        END IF;*/

                    END IF;
                    --EN:Modified for multiple monthly fee issue


                    --SN Added on 03.09.2013 for DFCHOST-340
                    BEGIN
                        select COUNT(CASE WHEN  (cce_valid_to IS NOT NULL AND (trunc(sysdate) between cce_valid_from and cce_valid_to))
                        OR (cce_valid_to IS NULL AND trunc(sysdate) >= cce_valid_from)   THEN
                        1 END), MAX(cce_valid_to)
                        into   v_card_cnt, v_max_validto
                        from  cms_card_excpfee
                        where cce_inst_code = p_instcode
                        and   cce_pan_code = c2.cap_pan_code ;
                    EXCEPTION
                        WHEN OTHERS THEN
                            v_card_cnt := 0;
                    END;
                    --EN Added on 03.09.2013 for DFCHOST-340

                    --SN:Added for multiple monthly fee issue
                    IF v_max_validto IS NOT NULL AND v_max_validto>C2.cpf_valid_from THEN
                       C2.cpf_valid_from:=v_max_validto;
                    END IF;
                    --EN:Added for multiple monthly fee issue

                    IF v_card_cnt = 0 THEN --Added on 03.09.2013 for DFCHOST-340
                     --Sn Commented below and added here during JH - Monthly Fee Waiver changes
                        BEGIN
                            SELECT cam_type_code, cam_acct_bal, cam_ledger_bal,
                            cam_first_load_date,cam_monthlyfee_counter --Added by Pankaj S. for JH - Monthly Fee Waiver changes
                            INTO v_cam_type_code, v_acct_bal, v_ledger_bal,
                            v_first_load_date,v_monthlyfee_counter     --Added by Pankaj S. for JH - Monthly Fee Waiver changes
                            FROM cms_acct_mast
                            WHERE cam_inst_code = p_instcode
                            AND cam_acct_id = c2.cap_acct_id;
                        EXCEPTION
                            WHEN OTHERS THEN
                                v_err_msg :='Error occured while fetching acct dtls 1.0 -'|| c2.cap_acct_id|| SUBSTR (SQLERRM, 1, 100);
                                RAISE EXP_REJECT_RECORD;
                        END;


                        IF c2.cfm_max_limit=0 OR v_monthlyfee_counter < c2.cfm_max_limit THEN --Added by Pankaj S. for JH - Monthly Fee Waiver

                            IF c2.cfm_date_assessment='AL' OR c2.cfm_date_assessment='FLI' THEN

                                IF v_first_load_date IS NULL THEN

                                    IF c2.cap_next_mb_date IS NULL THEN

                                        BEGIN
                                            SELECT MIN (add_ins_date)
                                            INTO v_first_load_date
                                            FROM transactionlog
                                            WHERE instcode=p_instcode
                                            AND customer_card_no = c2.cap_pan_code
                                            AND ((delivery_channel = '04' AND txn_code IN ('68', '80', '82', '85', '88'))
                                            OR (delivery_channel = '08' AND txn_code IN ('22', '26'))
                                            OR (delivery_channel = '11' AND txn_code = '22'))
                                            AND amount > 0
                                            AND (tran_reverse_flag IS NULL OR tran_reverse_flag='N');
                                        EXCEPTION
                                            WHEN OTHERS THEN
                                                v_err_msg := 'Error while fetching first_load_date_2.0 -' || SUBSTR(SQLERRM, 1, 200);
                                                RAISE EXP_REJECT_RECORD;
                                        END;
                                    ELSE
                                        v_first_load_date:=c2.cap_active_date;
                                    END IF;

                                    BEGIN
                                        UPDATE cms_acct_mast
                                        SET cam_first_load_date =v_first_load_date
                                        WHERE cam_inst_code = p_instcode
                                        AND cam_acct_id = c2.cap_acct_id;

                                        IF SQL%ROWCOUNT = 0 THEN
                                            v_err_msg :='No records updated in Acct_mast for first_load_date_2.0 -';
                                            RAISE EXP_REJECT_RECORD;
                                        END IF;

                                    EXCEPTION
                                        WHEN  EXP_REJECT_RECORD THEN
                                            RAISE;
                                        WHEN OTHERS THEN
                                            v_err_msg :='Error while upadating first_load_date_2.0 -' || SUBSTR (SQLERRM, 1, 200);
                                            RAISE EXP_REJECT_RECORD;
                                    END;
                                END IF;

                                BEGIN
                                    SELECT  CASE WHEN ROUND(MONTHS_BETWEEN (nvl(c2.cap_next_mb_date,v_first_load_date),v_first_load_date)) < 0
                                            THEN 1
                                            ELSE ROUND(MONTHS_BETWEEN (nvl(c2.cap_next_mb_date,v_first_load_date),v_first_load_date)) +1 END
                                    INTO v_month_diff
                                    FROM DUAL;
                                EXCEPTION
                                    WHEN OTHERS THEN
                                        v_err_msg :='Error while finding month_diff_2.0 -' || SUBSTR (SQLERRM, 1, 200);
                                        RAISE EXP_REJECT_RECORD;
                                END;

                            ELSE
                                BEGIN
                                    SELECT  CASE WHEN ROUND(MONTHS_BETWEEN (nvl(c2.cap_next_mb_date,c2.cap_active_date),c2.cap_active_date)) < 0
                                            THEN 1
                                            ELSE ROUND(MONTHS_BETWEEN (nvl(c2.cap_next_mb_date,c2.cap_active_date),c2.cap_active_date)) +1 END
                                    INTO v_month_diff
                                    FROM DUAL;
                                EXCEPTION
                                    WHEN OTHERS THEN
                                        v_err_msg :='Error while finding month_diff_2.1 -' || SUBSTR (SQLERRM, 1, 200);
                                        RAISE EXP_REJECT_RECORD;
                                END;
                            END IF;


                            BEGIN
                                LP_MONTHLY_FEE_CALC(C2.CFM_DATE_ASSESSMENT,
                                                    C2.CFM_PRORATION_FLAG,
                                                    C2.CFM_FEE_AMT,
                                                    C2.CAP_NEXT_MB_DATE,
                                                    C2.CAP_PAN_CODE,
                                                    P_INSTCODE,
                                                    case when C2.CFM_DATE_ASSESSMENT IN ('AL', 'FLI')  then v_first_load_date else C2.CAP_ACTIVE_DATE end, --Added by Pankaj S. for JH - Monthly Fee Waiver
                                                    greatest(C2.cpf_valid_from,c2.cfm_ins_date),--CPF_INS_DATE,
                                                    C2.CFM_ASSESSED_DAYS,--DFCTNM-32
                                                    V_CFM_FEE_AMT,
                                                    V_ERR_MSG);

                                IF V_ERR_MSG <> 'OK' and V_ERR_MSG <> 'NO FEES' THEN
                                    v_err_msg :='Error in LP_MONTHLY_FEE_CALC -' || V_ERR_MSG;
                                    RAISE EXP_REJECT_RECORD;
                                END IF;

                            EXCEPTION
                                WHEN EXP_REJECT_RECORD THEN
                                    RAISE;
                                WHEN OTHERS THEN
                                    v_err_msg :='Error while finding month_diff_2.1 -' || SUBSTR (SQLERRM, 1, 200);
                                    RAISE EXP_REJECT_RECORD;
                            END;

                            IF V_ERR_MSG <> 'NO FEES' THEN --Added by Saravanakumar for logging issue on 28-Oct-2014
                                --Sn Added by Pankaj S. for JH - Monthly Fee Waiver
                                IF c2.cfm_free_txncnt >= v_month_diff THEN
                                    v_cfm_fee_amt := 0;
                                    v_free_txn:='Y';
                                END IF;

                                 LP_UPDATE_NEXT_MB_DATE(C2.CAP_PAN_CODE);
                            --En Added by Pankaj S. for JH - Monthly Fee Waiver

                                IF v_free_txn='N'  THEN--v_free_txn condition Added by Pankaj S. for JH - Monthly Fee Waiver
                                    BEGIN
                                        LP_CALC_CR_FREETXN(P_INSTCODE,
                                                            C2.CAP_NEXT_MB_DATE,
                                                            case when C2.CFM_DATE_ASSESSMENT IN ('AL', 'FLI') then v_first_load_date else C2.CAP_ACTIVE_DATE end, --Added by Pankaj S. for JH - Monthly Fee Waiver
                                                            C2.CAP_PAN_CODE,
                                                            c2.cfm_crfree_txncnt,--C2.CFM_FREE_TXNCNT, --Modified by Pankaj S. for JH-monthly fee waiver
                                                            C2.CFM_TXNFREE_AMT,
                                                            C2.CFM_FEEAMNT_TYPE,
                                                            V_CFM_FEE_AMT,
                                                            V_WAIV_FLAG,
                                                            V_ERR_MSG);
                                        IF V_ERR_MSG <> 'OK' THEN
                                            v_err_msg :='Error in LP_CALC_CR_FREETXN -' || V_ERR_MSG;
                                            RAISE EXP_REJECT_RECORD;
                                        END IF;
                                    EXCEPTION
                                        WHEN EXP_REJECT_RECORD THEN
                                            RAISE;
                                        WHEN OTHERS THEN
                                            v_err_msg :='Error while calling LP_CALC_CR_FREETXN -' || SUBSTR (SQLERRM, 1, 200);
                                            RAISE EXP_REJECT_RECORD;
                                    END;

                                    -- SN Modified for FWR-11
                                    IF C2.CFM_FEECAP_FLAG ='Y' AND v_free_txn='N' THEN --v_free_txn condition Added by Pankaj S. for JH - Monthly Fee Waiver
                                        BEGIN
                                            SP_TRAN_FEES_CAP(P_INSTCODE,
                                                                C2.CAP_ACCT_NO,
                                                                TRUNC(SYSDATE),
                                                                -- V_FEE_AMOUNT,--For Variable correction regarding Mantis:0012744
                                                                V_CFM_FEE_AMT,
                                                                C2.CFF_FEE_PLAN,
                                                                C2.CFM_FEE_CODE,
                                                                V_ERR_MSG
                                                                ); -- Added for FWR-11

                                        IF V_ERR_MSG <> 'OK' THEN
                                            v_err_msg :='Error in SP_TRAN_FEES_CAP -' || V_ERR_MSG;
                                            RAISE EXP_REJECT_RECORD;
                                        END IF;

                                        EXCEPTION
                                        WHEN EXP_REJECT_RECORD THEN
                                            RAISE;
                                            WHEN OTHERS THEN
                                            v_err_msg :='Error while calling SP_TRAN_FEES_CAP -' || SUBSTR (SQLERRM, 1, 200);
                                            RAISE EXP_REJECT_RECORD;
                                        END;
                                    END IF;
                                        -- EN Modified for FWR-11

                                    BEGIN
                                        SELECT CPW_WAIV_PRCNT
                                            INTO V_CPW_WAIV_PRCNT
                                            FROM CMS_PRODCATTYPE_WAIV
                                            WHERE CPW_INST_CODE = P_INSTCODE AND
                                            CPW_PROD_CODE = C2.CPF_PROD_CODE AND
                                            CPW_CARD_TYPE = C2.CPF_CARD_TYPE AND
                                            CPW_FEE_CODE = C2.CFM_FEE_CODE AND
                                            SYSDATE >= CPW_VALID_FROM AND SYSDATE <= CPW_VALID_TO;

                                            V_WAIVAMT := (V_CPW_WAIV_PRCNT / 100) * V_CFM_FEE_AMT;

                                    EXCEPTION
                                        WHEN OTHERS THEN
                                            V_WAIVAMT := 0;
                                    END;

                                    BEGIN
                                        v_tot_clwbck_count := C2.cfm_clawback_count;
                                        LP_FEE_UPDATE_LOG(P_INSTCODE,
                                                            C2.CAP_PAN_CODE,
                                                            C2.CAP_PAN_CODE_ENCR,
                                                            C2.CFM_FEE_CODE,
                                                            V_CFM_FEE_AMT,
                                                            C2.CFF_FEE_PLAN,
                                                            -- c2.cpf_card_type,
                                                            C2.CPF_CRGL_CATG,
                                                            C2.CPF_CRGL_CODE,
                                                            C2.CPF_CRSUBGL_CODE,
                                                            C2.CPF_CRACCT_NO,
                                                            C2.CPF_DRGL_CATG,
                                                            C2.CPF_DRGL_CODE,
                                                            C2.CPF_DRSUBGL_CODE,
                                                            C2.CPF_DRACCT_NO,
                                                            C2.CFM_CLAWBACK_FLAG,
                                                            C2.CFT_FEE_FREQ,
                                                            C2.CFT_FEETYPE_CODE,
                                                            P_LUPDUSER,
                                                            V_WAIVAMT,
                                                            'PC',
                                                            C2.CAP_CARD_STAT,
                                                            C2.CAP_ACCT_NO,--Added on 06.09.2013 for DFCHOST-340(review)
                                                            C2.CAP_PROD_CODE,--Added on 06.09.2013 for DFCHOST-340(review)
                                                            C2.CAP_CARD_TYPE,--Added on 06.09.2013 for DFCHOST-340(review)
                                                            V_WAIV_FLAG,--Add on 26/09/13 For regarding JH-13
                                                            v_free_txn,   --Added by Pankaj S. for JH - Monthly Fee Waiver
                                                            C2.CFM_FEE_DESC,-- Added 02/03/14 for regarding MVCSD-4471
                                                            --DFCTNM-32
                                                            C2.CFM_CLAWBACK_TYPE,
                                                            C2.CFM_CLAWBACK_MAXAMT,
                                                            V_ERR_MSG);

                                        IF V_ERR_MSG <> 'OK'  and V_ERR_MSG <> 'CLAW BLACK WAIVED' THEN
                                            v_err_msg :='Error in LP_FEE_UPDATE_LOG -' || V_ERR_MSG;
                                            RAISE EXP_REJECT_RECORD;
                                        END IF;

                                    EXCEPTION
                                        WHEN EXP_REJECT_RECORD THEN
                                            RAISE;
                                        WHEN OTHERS THEN
                                            v_err_msg :='Error while calling LP_FEE_UPDATE_LOG -' || SUBSTR (SQLERRM, 1, 200);
                                            RAISE EXP_REJECT_RECORD;
                                    END;

                                  --Sn Added by Pankaj S. for JH - Monthly Fee Waiver
                                  --  IF v_free_txn='N' THEN
                                  IF V_DEBIT_AMNT > 0 THEN
                                        BEGIN
                                            UPDATE cms_acct_mast
                                            SET cam_monthlyfee_counter =cam_monthlyfee_counter+1
                                            WHERE cam_inst_code = p_instcode
                                            AND cam_acct_id = c2.cap_acct_id;

                                            IF SQL%ROWCOUNT = 0 THEN
                                            V_ERR_MSG :='No records updated in Acct_mast for acct 1.0 -';
                                            RAISE EXP_REJECT_RECORD;
                                            END IF;

                                        EXCEPTION
                                        WHEN EXP_REJECT_RECORD THEN
                                            RAISE ;
                                            WHEN OTHERS THEN
                                            V_ERR_MSG :='Error while upadating Acct_mast 1.0 -' || SUBSTR (SQLERRM, 1, 200);
                                            RAISE EXP_REJECT_RECORD;
                                        END;
                                   END IF;
                                END IF;
                                    --En Added by Pankaj S. for JH - Monthly Fee Waiver
                                COMMIT;  --Added for FSS-1762 - Commit should be happened at row level in Monthly Fee job
                            END IF;
                        END IF;--Added by Pankaj S. for JH - Monthly Fee Waiver
                    END IF;
                END IF;
	END IF; 	--/* Added for VMS-2183 State Restriction logic for monthly fee calculation*/ ENDS
            EXCEPTION--Main excetpion
                WHEN EXP_REJECT_RECORD THEN
                    ROLLBACK;

                    BEGIN
                        INSERT INTO CMS_CHARGE_DTL
                                        (CCD_INST_CODE,
                                        CCD_PAN_CODE,
                                        CCD_MBR_NUMB,
                                        CCD_ACCT_NO,
                                        CCD_FEE_FREQ,
                                        CCD_FEETYPE_CODE,
                                        CCD_FEE_CODE,
                                        CCD_CALC_AMT,
                                        CCD_EXPCALC_DATE,
                                        CCD_CALC_DATE,
                                        CCD_FILE_NAME,
                                        CCD_FILE_DATE,
                                        CCD_INS_USER,
                                        CCD_LUPD_USER,
                                        CCD_FILE_STATUS,
                                        CCD_RRN,
                                        CCD_PROCESS_MSG,
                                        CCD_FEE_PLAN,
                                        CCD_PAN_CODE_ENCR,
                                        CCD_GL_ACCT_NO,
                                        CCD_DELIVERY_CHANNEL,
                                        CCD_TXN_CODE)
                        VALUES
                                        (P_INSTCODE,
                                        C2.CAP_PAN_CODE,
                                        '000',
                                        C2.CAP_ACCT_NO,
                                        C2.CFT_FEE_FREQ,
                                        C2.CFT_FEETYPE_CODE,
                                        C2.CFM_FEE_CODE,
                                        ROUND(V_CFM_FEE_AMT,2),  --Modified by Revathi on 02-APR-2014 for 3decimal place issue
                                        SYSDATE,
                                        SYSDATE,
                                        'N',
                                        SYSDATE,
                                        P_LUPDUSER,
                                        P_LUPDUSER,
                                        'E',
                                        V_RRN2, --Modified by Deepa on July 02 2012 for the error record to have different status
                                        V_ERR_MSG,
                                        C2.CFF_FEE_PLAN,
                                        C2.CAP_PAN_CODE_ENCR,
                                        C2.CPF_CRACCT_NO,
                                        V_DELIVERY_CHANNEL,
                                        V_TXN_CODE);
                    EXCEPTION
                        WHEN OTHERS THEN
                            P_ERRMSG := 'Error while inserting into CHARGE_DTL 1.0 ' || SUBSTR(SQLERRM, 1, 200);
                    END;


                    BEGIN
                        LP_TRANSACTION_LOG(p_instcode,
                                            C2.cap_pan_code,
                                            C2.cap_pan_code_encr,
                                            v_rrn2,
                                            v_delivery_channel,
                                            v_business_date,
                                            v_business_time,
                                            C2.cap_acct_no,
                                            v_acct_bal,
                                            v_ledger_bal,
                                            null,
                                            v_auth_id,
                                            v_tran_desc,
                                            v_txn_code,
                                            21,
                                            NULL ,
                                            NULL,
                                            C2.cfm_fee_code,
                                            C2.cff_fee_plan,
                                            C2.cpf_cracct_no,
                                            C2.cpf_dracct_no,
                                            'C',
                                            C2.cap_card_stat,
                                            v_cam_type_code,
                                            v_timestamp  ,
                                            C2.cap_prod_code,
                                            C2.cap_card_type,
                                            V_DR_CR_FLAG,
                                            v_err_msg
                                            );
                    EXCEPTION
                        WHEN OTHERS THEN
                            V_ERR_MSG :='Error while calling LP_TRANSACTION_LOG-' || SUBSTR (SQLERRM, 1, 200);
                    END;
                    COMMIT;
                WHEN OTHERS THEN
                    ROLLBACK;
                    V_ERR_MSG :='Error in main loop -' || SUBSTR (SQLERRM, 1, 200);

                     BEGIN
                        INSERT INTO CMS_CHARGE_DTL
                                        (CCD_INST_CODE,
                                        CCD_PAN_CODE,
                                        CCD_MBR_NUMB,
                                        CCD_ACCT_NO,
                                        CCD_FEE_FREQ,
                                        CCD_FEETYPE_CODE,
                                        CCD_FEE_CODE,
                                        CCD_CALC_AMT,
                                        CCD_EXPCALC_DATE,
                                        CCD_CALC_DATE,
                                        CCD_FILE_NAME,
                                        CCD_FILE_DATE,
                                        CCD_INS_USER,
                                        CCD_LUPD_USER,
                                        CCD_FILE_STATUS,
                                        CCD_RRN,
                                        CCD_PROCESS_MSG,
                                        CCD_FEE_PLAN,
                                        CCD_PAN_CODE_ENCR,
                                        CCD_GL_ACCT_NO,
                                        CCD_DELIVERY_CHANNEL,
                                        CCD_TXN_CODE)
                        VALUES
                                        (P_INSTCODE,
                                        C2.CAP_PAN_CODE,
                                        '000',
                                        C2.CAP_ACCT_NO,
                                        C2.CFT_FEE_FREQ,
                                        C2.CFT_FEETYPE_CODE,
                                        C2.CFM_FEE_CODE,
                                        ROUND(V_CFM_FEE_AMT,2),  --Modified by Revathi on 02-APR-2014 for 3decimal place issue
                                        SYSDATE,
                                        SYSDATE,
                                        'N',
                                        SYSDATE,
                                        P_LUPDUSER,
                                        P_LUPDUSER,
                                        'E',
                                        V_RRN2, --Modified by Deepa on July 02 2012 for the error record to have different status
                                        V_ERR_MSG,
                                        C2.CFF_FEE_PLAN,
                                        C2.CAP_PAN_CODE_ENCR,
                                        C2.CPF_CRACCT_NO,
                                        V_DELIVERY_CHANNEL,
                                        V_TXN_CODE);
                    EXCEPTION
                        WHEN OTHERS THEN
                            P_ERRMSG := 'Error while inserting into CHARGE_DTL 1.0 ' || SUBSTR(SQLERRM, 1, 200);
                    END;

                    BEGIN
                        LP_TRANSACTION_LOG(p_instcode,
                                            C2.cap_pan_code,
                                            C2.cap_pan_code_encr,
                                            v_rrn2,
                                            v_delivery_channel,
                                            v_business_date,
                                            v_business_time,
                                            C2.cap_acct_no,
                                            v_acct_bal,
                                            v_ledger_bal,
                                            null,
                                            v_auth_id,
                                            v_tran_desc,
                                            v_txn_code,
                                            21,
                                            NULL ,
                                            NULL,
                                            C2.cfm_fee_code,
                                            C2.cff_fee_plan,
                                            C2.cpf_cracct_no,
                                            C2.cpf_dracct_no,
                                            'C',
                                            C2.cap_card_stat,
                                            v_cam_type_code,
                                            v_timestamp  ,
                                            C2.cap_prod_code,
                                            C2.cap_card_type,
                                            V_DR_CR_FLAG,
                                            v_err_msg
                                            );
                    EXCEPTION
                        WHEN OTHERS THEN
                            V_ERR_MSG :='Error while calling LP_TRANSACTION_LOG-' || SUBSTR (SQLERRM, 1, 200);
                    END;
                    COMMIT;
            END;
        END LOOP;
    END;
    --En InActivity Fee Calculation for the Product Category

--  Sn InActivity Fee Calculation for the Product
   BEGIN
        FOR C3 IN PRODFEE
        LOOP
            BEGIN

                v_err_msg:='OK';
                v_free_txn:='N';
                v_count := 1;
				V_FEE_FLAG := 'Y';

                --SN:Modified for multiple monthly fee issue
                --if c3.cap_active_date is null then
		
	    --/*Added for VMS-2183 State Restriction logic for monthly fee calculation*/ 
				
		IF C3.STATERESTFLAG = 'Y' THEN
			LP_STATE_RESTRICT_CHK	(C3.CAP_PROD_CODE,
						C3.CAP_CARD_TYPE,   
						C3.CAP_CUST_CODE,
						C3.CAP_PAN_CODE,
						V_FEE_FLAG,
						V_ERR_MSG
						);
			
			IF V_ERR_MSG <> 'OK' THEN
				RAISE EXP_REJECT_RECORD;
			END IF;
			
		END IF;
			
	    IF V_FEE_FLAG = 'Y' THEN
	    
	    --/* Added for VMS-2183 State Restriction logic for monthly fee calculation*/  STARTS

                    begin
                        SELECT SUM(decode(cap_card_stat,'9',0,1)), MAX(cap_next_mb_date)
                        INTO v_count, c3.cap_next_mb_date
                        FROM cms_appl_pan
                        WHERE cap_inst_code = p_instcode
                          AND cap_acct_no=c3.cap_acct_no;
                          --AND cap_card_stat <>'9';

                        IF c3.cap_active_date IS NOT NULL THEN
                           v_count := 1;
                        END IF;
                     EXCEPTION
                            WHEN OTHERS THEN
                               P_ERRMSG := 'Error in getting the count ' || SUBSTR(SQLERRM, 1, 200);
                      end;

                --end if;
                --EN:Modified for multiple monthly fee issue

                IF v_count=1 then

                    --SN:Modified for multiple monthly fee issue
                    IF c3.cap_repl_flag<>0 then

                        BEGIN
                            SELECT min(cap_active_date)--,cap_next_mb_date
                            INTO v_old_active_date--,old_next_mb_date
                            FROM CMS_APPL_PAN
                            WHERE cap_acct_no=c3.cap_acct_no
                            and cap_startercard_flag='N';
                            /*CAP_PAN_CODE = (SELECT chr_pan_code
                                                   FROM cms_htlst_reisu
                                                   WHERE chr_new_pan=c3.cce_pan_code);*/

                            IF v_old_active_date IS NULL AND c3.cap_active_date IS NULL THEN
                               CONTINUE;
                            ELSIF ( V_OLD_ACTIVE_DATE IS NOT NULL AND C3.CAP_NEXT_MB_DATE IS NOT NULL) OR
                            (v_old_active_date IS NOT NULL AND trunc(ADD_MONTHS(v_old_active_date,1)) >= trunc(SYSDATE) AND c3.cap_next_mb_date IS NULL) THEN
                               c3.cap_active_date :=v_old_active_date;
                            END IF;
                                  /*if c3.cap_next_mb_date is null then
                                c3.cap_next_mb_date:=old_next_mb_date;
                            end if;*/


                        EXCEPTION
                           WHEN no_data_found THEN
                                null;
                            WHEN others THEN
                                P_ERRMSG := 'Error in getting old card active date ' || SUBSTR(SQLERRM, 1, 200);
                        END;

                        /*IF c3.cap_next_mb_date IS NOT NULL THEN
                            c3.cap_active_date := v_old_active_date;
                        ELSE
                            IF add_months(c3.cap_active_date,1) >= SYSDATE THEN
                                c3.cap_active_date := v_old_active_date;

                            END IF;
                        END IF;*/

                    END IF;
                    --EN:Modified for multiple monthly fee issue


                    BEGIN
                        select COUNT(CASE WHEN  (cce_valid_to IS NOT NULL AND (trunc(sysdate) between cce_valid_from and cce_valid_to))
                        OR (cce_valid_to IS NULL AND trunc(sysdate) >= cce_valid_from)   THEN
                        1 END), MAX(cce_valid_to)
                        into   v_card_cnt, v_max_validto
                        from  cms_card_excpfee
                        where cce_inst_code = p_instcode
                        and   cce_pan_code = c3.cap_pan_code ;
                    EXCEPTION
                        WHEN OTHERS THEN
                            v_card_cnt := 0;
                    END;

                    --SN:Added for multiple monthly fee issue
                    IF v_max_validto IS NOT NULL AND v_max_validto >c3.cpf_valid_from THEN
                       c3.cpf_valid_from:=v_max_validto;
                    END IF;
                    --EN:Added for multiple monthly fee issue

                    IF v_card_cnt = 0 THEN
                        BEGIN
                            SELECT count (case when ((cpf_valid_to IS NOT NULL AND TRUNC(sysdate) between cpf_valid_from and cpf_valid_to))
                            OR (cpf_valid_to IS NULL AND TRUNC(sysdate) >= cpf_valid_from)then 1 end), MAX(cpf_valid_to)
                            INTO v_prdcatg_cnt, v_max_validto
                            FROM cms_prodcattype_fees
                            WHERE cpf_inst_code = p_instcode
                            AND cpf_prod_code   = c3.cpf_prod_code
                            AND cpf_card_type   = c3.cap_card_type;
                        EXCEPTION
                            WHEN OTHERS THEN
                                v_prdcatg_cnt := 0;
                        END;
                    END IF;

                     --SN:Added for multiple monthly fee issue
                    IF v_max_validto IS NOT NULL AND v_max_validto >c3.cpf_valid_from THEN
                       c3.cpf_valid_from:=v_max_validto;
                    END IF;
                    --EN:Added for multiple monthly fee issue


                    IF v_card_cnt = 0 AND v_prdcatg_cnt = 0 THEN --Added on 03.09.2013 for DFCHOST-340

                        BEGIN
                            SELECT cam_type_code, cam_acct_bal, cam_ledger_bal,
                            cam_first_load_date,cam_monthlyfee_counter --Added by Pankaj S. for JH - Monthly Fee Waiver changes
                            INTO v_cam_type_code, v_acct_bal, v_ledger_bal,
                            v_first_load_date,v_monthlyfee_counter
                            FROM cms_acct_mast
                            WHERE cam_inst_code = p_instcode AND cam_acct_id = c3.cap_acct_id;
                        EXCEPTION
                            WHEN OTHERS THEN
                                v_err_msg :='Error occured while fetching acct dtls 3.0 -'|| c3.cap_acct_id|| SUBSTR (SQLERRM, 1, 100);
                                RAISE EXP_REJECT_RECORD;
                        END;


                        IF c3.cfm_max_limit=0 OR v_monthlyfee_counter < c3.cfm_max_limit THEN --Added by Pankaj S. for JH - Monthly Fee Waiver

                            IF c3.cfm_date_assessment='AL' OR c3.cfm_date_assessment='FLI' THEN

                                IF v_first_load_date IS NULL THEN

                                    IF c3.cap_next_mb_date IS NULL THEN
                                        BEGIN
                                            SELECT MIN (add_ins_date)
                                            INTO v_first_load_date
                                            FROM transactionlog
                                            WHERE instcode=p_instcode
                                            AND customer_card_no = c3.cap_pan_code
                                            AND ((delivery_channel = '04' AND txn_code IN ('68', '80', '82', '85', '88'))
                                            OR (delivery_channel = '08' AND txn_code IN ('22', '26'))
                                            OR (delivery_channel = '11' AND txn_code = '22'))
                                            AND amount > 0
                                            AND (tran_reverse_flag IS NULL OR tran_reverse_flag='N');
                                        EXCEPTION
                                            WHEN OTHERS THEN
                                                v_err_msg := 'Error while fetching first_load_date_3.0 -' || SUBSTR(SQLERRM, 1, 200);
                                                RAISE EXP_REJECT_RECORD;
                                        END;
                                    ELSE
                                        v_first_load_date:=c3.cap_active_date;
                                    END IF;

                                    BEGIN
                                        UPDATE cms_acct_mast
                                        SET cam_first_load_date =v_first_load_date
                                        WHERE cam_inst_code = p_instcode
                                        AND cam_acct_id = c3.cap_acct_id;

                                        IF SQL%ROWCOUNT = 0 THEN
                                            v_err_msg :='No records updated in Acct_mast for first_load_date_3.0 -';
                                            RAISE EXP_REJECT_RECORD;
                                        END IF;

                                    EXCEPTION
                                        WHEN  EXP_REJECT_RECORD THEN
                                            RAISE;
                                        WHEN OTHERS THEN
                                            v_err_msg :='Error while upadating first_load_date_3.0 -' || SUBSTR (SQLERRM, 1, 200);
                                            RAISE EXP_REJECT_RECORD;
                                    END;

                                END IF;

                                BEGIN
                                    SELECT  CASE WHEN ROUND(MONTHS_BETWEEN (nvl(c3.cap_next_mb_date,v_first_load_date),v_first_load_date)) < 0
                                            THEN 1
                                            ELSE ROUND(MONTHS_BETWEEN (nvl(c3.cap_next_mb_date,v_first_load_date),v_first_load_date)) +1 END
                                    INTO v_month_diff
                                    FROM DUAL;
                                EXCEPTION
                                    WHEN OTHERS THEN
                                        v_err_msg :='Error while finding month_diff_3.0 -' || SUBSTR (SQLERRM, 1, 200);
                                        RAISE EXP_REJECT_RECORD;
                                END;
                            ELSE
                                BEGIN
                                    SELECT  CASE WHEN ROUND(MONTHS_BETWEEN (nvl(c3.cap_next_mb_date,c3.cap_active_date),c3.cap_active_date)) < 0
                                            THEN 1
                                            ELSE ROUND(MONTHS_BETWEEN (nvl(c3.cap_next_mb_date,c3.cap_active_date),c3.cap_active_date)) +1 END
                                    INTO v_month_diff
                                    FROM DUAL;
                                EXCEPTION
                                    WHEN OTHERS THEN
                                        v_err_msg :='Error while finding month_diff_3.1 -' || SUBSTR (SQLERRM, 1, 200);
                                        RAISE EXP_REJECT_RECORD;
                                END;
                            END IF;

                            BEGIN
                                LP_MONTHLY_FEE_CALC(C3.CFM_DATE_ASSESSMENT,
                                                    C3.CFM_PRORATION_FLAG,
                                                    C3.CFM_FEE_AMT,
                                                    C3.CAP_NEXT_MB_DATE,
                                                    C3.CAP_PAN_CODE,
                                                    P_INSTCODE,
                                                    case when C3.CFM_DATE_ASSESSMENT IN ('AL', 'FLI') THEN v_first_load_date else C3.CAP_ACTIVE_DATE end, --Added by Pankaj S. for JH - Monthly Fee Waiver
                                                    greatest(C3.cpf_valid_from,c3.cfm_ins_date),--CPF_INS_DATE,
                                                    C3.CFM_ASSESSED_DAYS,--DFCTNM-32
                                                    V_CFM_FEE_AMT,
                                                    V_ERR_MSG);

                                IF V_ERR_MSG <> 'OK' and V_ERR_MSG <> 'NO FEES' THEN
                                    v_err_msg :='Error in LP_MONTHLY_FEE_CALC -' || V_ERR_MSG;
                                    RAISE EXP_REJECT_RECORD;
                                END IF;

                            EXCEPTION
                                WHEN EXP_REJECT_RECORD THEN
                                    RAISE;
                                WHEN OTHERS THEN
                                    v_err_msg :='Error while finding month_diff_2.1 -' || SUBSTR (SQLERRM, 1, 200);
                                    RAISE EXP_REJECT_RECORD;
                            END;

                            IF V_ERR_MSG <> 'NO FEES' THEN --Added by Saravanakumar for logging issue on 28-Oct-2014
                                --Sn Added by Pankaj S. for JH - Monthly Fee Waiver
                                IF c3.cfm_free_txncnt >= v_month_diff THEN
                                        v_cfm_fee_amt := 0;
                                        v_free_txn:='Y';
                                END IF;

                                 LP_UPDATE_NEXT_MB_DATE(C3.CAP_PAN_CODE);
                            --En Added by Pankaj S. for JH - Monthly Fee Waiver

                                --Added for JH-13
                                IF v_free_txn='N' THEN --v_free_txn condition Added by Pankaj S. for JH - Monthly Fee Waiver
                                    BEGIN
                                        LP_CALC_CR_FREETXN(P_INSTCODE,
                                                            C3.CAP_NEXT_MB_DATE,
                                                            case when C3.CFM_DATE_ASSESSMENT IN ('AL', 'FLI') THEN v_first_load_date else C3.CAP_ACTIVE_DATE end, --Added by Pankaj S. for JH - Monthly Fee Waiver
                                                            C3.CAP_PAN_CODE,
                                                            c3.cfm_crfree_txncnt,--C3.CFM_FREE_TXNCNT, --Modified by Pankaj S. for JH-monthly fee waiver
                                                            C3.CFM_TXNFREE_AMT,
                                                            C3.CFM_FEEAMNT_TYPE,
                                                            V_CFM_FEE_AMT,
                                                            V_WAIV_FLAG,
                                                            V_ERR_MSG);

                                        IF V_ERR_MSG <> 'OK' THEN
                                            v_err_msg :='Error in LP_CALC_CR_FREETXN -' || V_ERR_MSG;
                                            RAISE EXP_REJECT_RECORD;
                                        END IF;

                                    EXCEPTION
                                        WHEN EXP_REJECT_RECORD THEN
                                            RAISE;
                                        WHEN OTHERS THEN
                                            v_err_msg :='Error while calling LP_CALC_CR_FREETXN -' || SUBSTR (SQLERRM, 1, 200);
                                            RAISE EXP_REJECT_RECORD;
                                    END;




                                    IF C3.CFM_FEECAP_FLAG ='Y' AND v_free_txn='N'  THEN--v_free_txn condition Added by Pankaj S. for JH - Monthly Fee Waiver
                                        BEGIN
                                            SP_TRAN_FEES_CAP(P_INSTCODE,
                                                            C3.CAP_ACCT_NO,
                                                            TRUNC(SYSDATE),
                                                            V_CFM_FEE_AMT,--For Variable correction regarding Mantis:0012744
                                                            -- V_FEE_AMOUNT,
                                                            C3.CFF_FEE_PLAN,
                                                            C3.CFM_FEE_CODE,
                                                            V_ERR_MSG
                                                            ); -- Added for FWR-11

                                            IF V_ERR_MSG <> 'OK' THEN
                                                v_err_msg :='Error in SP_TRAN_FEES_CAP -' || V_ERR_MSG;
                                                RAISE EXP_REJECT_RECORD;
                                            END IF;

                                        EXCEPTION
                                            WHEN EXP_REJECT_RECORD THEN
                                                RAISE;
                                            WHEN OTHERS THEN
                                                v_err_msg :='Error while calling SP_TRAN_FEES_CAP -' || SUBSTR (SQLERRM, 1, 200);
                                                RAISE EXP_REJECT_RECORD;
                                        END;
                                    END IF;
                                -- EN Modified for FWR-11

                                    BEGIN
                                        SELECT CPW_WAIV_PRCNT
                                        INTO V_CPW_WAIV_PRCNT
                                        FROM CMS_PRODCCC_WAIV
                                        WHERE CPW_INST_CODE = P_INSTCODE AND
                                        CPW_PROD_CODE = C3.CPF_PROD_CODE AND
                                        CPW_FEE_CODE = C3.CFM_FEE_CODE AND
                                        SYSDATE >= CPW_VALID_FROM AND SYSDATE <= CPW_VALID_TO;

                                        V_WAIVAMT := (V_CPW_WAIV_PRCNT / 100) * V_CFM_FEE_AMT;

                                    EXCEPTION
                                        WHEN OTHERS THEN
                                            V_WAIVAMT := 0;
                                    END;

                                    BEGIN
                                        v_tot_clwbck_count := C3.cfm_clawback_count;
                                        LP_FEE_UPDATE_LOG(P_INSTCODE,
                                                            C3.CAP_PAN_CODE,
                                                            C3.CAP_PAN_CODE_ENCR,
                                                            C3.CFM_FEE_CODE,
                                                            V_CFM_FEE_AMT,
                                                            C3.CFF_FEE_PLAN,
                                                            --  I2.cap_card_type,
                                                            C3.CPF_CRGL_CATG,
                                                            C3.CPF_CRGL_CODE,
                                                            C3.CPF_CRSUBGL_CODE,
                                                            C3.CPF_CRACCT_NO,
                                                            C3.CPF_DRGL_CATG,
                                                            C3.CPF_DRGL_CODE,
                                                            C3.CPF_DRSUBGL_CODE,
                                                            C3.CPF_DRACCT_NO,
                                                            C3.CFM_CLAWBACK_FLAG,
                                                            C3.CFT_FEE_FREQ,
                                                            C3.CFT_FEETYPE_CODE,
                                                            P_LUPDUSER,
                                                            V_WAIVAMT,
                                                            'P',
                                                            C3.CAP_CARD_STAT,
                                                            C3.CAP_ACCT_NO,--Added on 06.09.2013 for DFCHOST-340(review)
                                                            C3.CAP_PROD_CODE,--Added on 06.09.2013 for DFCHOST-340(review)
                                                            C3.CAP_CARD_TYPE,--Added on 06.09.2013 for DFCHOST-340(review)
                                                            V_WAIV_FLAG, --Add on 26/09/13 For regarding JH-13
                                                            v_free_txn,   --Added by Pankaj S. for JH - Monthly Fee Waiver
                                                            C3.CFM_FEE_DESC,-- Added 02/03/14 for regarding MVCSD-4471
                                                            --DFCTNM-32
                                                            C3.CFM_CLAWBACK_TYPE,
                                                            C3.CFM_CLAWBACK_MAXAMT,
                                                            V_ERR_MSG);

                                            IF V_ERR_MSG <> 'OK'  and V_ERR_MSG <> 'CLAW BLACK WAIVED' THEN
                                                v_err_msg :='Error in LP_FEE_UPDATE_LOG -' || V_ERR_MSG;
                                                RAISE EXP_REJECT_RECORD;
                                            END IF;

                                    EXCEPTION
                                        WHEN EXP_REJECT_RECORD THEN
                                            RAISE;
                                        WHEN OTHERS THEN
                                            v_err_msg :='Error while calling LP_FEE_UPDATE_LOG -' || SUBSTR (SQLERRM, 1, 200);
                                            RAISE EXP_REJECT_RECORD;
                                    END;

                                    --IF v_free_txn = 'N' THEN
                                    IF V_DEBIT_AMNT > 0 THEN
                                        BEGIN
                                            UPDATE cms_acct_mast
                                            SET cam_monthlyfee_counter = cam_monthlyfee_counter+1
                                            WHERE cam_inst_code = p_instcode
                                            AND cam_acct_id = c3.cap_acct_id;

                                            IF SQL%ROWCOUNT = 0 THEN
                                                V_ERR_MSG :='No records updated in Acct_mast for acct 1.0 -';
                                                RAISE EXP_REJECT_RECORD;
                                            END IF;

                                        EXCEPTION
                                            WHEN EXP_REJECT_RECORD THEN
                                                RAISE ;
                                            WHEN OTHERS THEN
                                                V_ERR_MSG :='Error while upadating Acct_mast 1.0 -' || SUBSTR (SQLERRM, 1, 200);
                                                RAISE EXP_REJECT_RECORD;
                                        END;
                                   END IF;
                                END IF;

                                COMMIT;  --Added for FSS-1762 - Commit should be happened at row level in Monthly Fee job
                            END IF;
                        END IF;--Added by Pankaj S. for JH - Monthly Fee Waiver
                    END IF;
                END IF;
	    END IF;   --/* Added for VMS-2183 State Restriction logic for monthly fee calculation*/  ENDS
            EXCEPTION--Main excetpion
                WHEN EXP_REJECT_RECORD THEN
                    ROLLBACK;

                     BEGIN
                        INSERT INTO CMS_CHARGE_DTL
                                        (CCD_INST_CODE,
                                        CCD_PAN_CODE,
                                        CCD_MBR_NUMB,
                                        CCD_ACCT_NO,
                                        CCD_FEE_FREQ,
                                        CCD_FEETYPE_CODE,
                                        CCD_FEE_CODE,
                                        CCD_CALC_AMT,
                                        CCD_EXPCALC_DATE,
                                        CCD_CALC_DATE,
                                        CCD_FILE_NAME,
                                        CCD_FILE_DATE,
                                        CCD_INS_USER,
                                        CCD_LUPD_USER,
                                        CCD_FILE_STATUS,
                                        CCD_RRN,
                                        CCD_PROCESS_MSG,
                                        CCD_FEE_PLAN,
                                        CCD_PAN_CODE_ENCR,
                                        CCD_GL_ACCT_NO,
                                        CCD_DELIVERY_CHANNEL,
                                        CCD_TXN_CODE)
                        VALUES
                                        (P_INSTCODE,
                                        C3.CAP_PAN_CODE,
                                        '000',
                                        C3.CAP_ACCT_NO,
                                        C3.CFT_FEE_FREQ,
                                        C3.CFT_FEETYPE_CODE,
                                        C3.CFM_FEE_CODE,
                                        ROUND(V_CFM_FEE_AMT,2),  --Modified by Revathi on 02-APR-2014 for 3decimal place issue
                                        SYSDATE,
                                        SYSDATE,
                                        'N',
                                        SYSDATE,
                                        P_LUPDUSER,
                                        P_LUPDUSER,
                                        'E',
                                        V_RRN2, --Modified by Deepa on July 02 2012 for the error record to have different status
                                        V_ERR_MSG,
                                        C3.CFF_FEE_PLAN,
                                        C3.CAP_PAN_CODE_ENCR,
                                        C3.CPF_CRACCT_NO,
                                        V_DELIVERY_CHANNEL,
                                        V_TXN_CODE);
                    EXCEPTION
                        WHEN OTHERS THEN
                            P_ERRMSG := 'Error while inserting into CHARGE_DTL 1.0 ' || SUBSTR(SQLERRM, 1, 200);
                    END;

                    BEGIN
                        LP_TRANSACTION_LOG(p_instcode,
                                            C3.cap_pan_code,
                                            C3.cap_pan_code_encr,
                                            v_rrn2,
                                            v_delivery_channel,
                                            v_business_date,
                                            v_business_time,
                                            C3.cap_acct_no,
                                            v_acct_bal,
                                            v_ledger_bal,
                                            null,
                                            v_auth_id,
                                            v_tran_desc,
                                            v_txn_code,
                                            21,
                                            NULL ,
                                            NULL,
                                            C3.cfm_fee_code,
                                            C3.cff_fee_plan,
                                            C3.cpf_cracct_no,
                                            C3.cpf_dracct_no,
                                            'C',
                                            C3.cap_card_stat,
                                            v_cam_type_code,
                                            v_timestamp  ,
                                            C3.cap_prod_code,
                                            C3.cap_card_type,
                                            V_DR_CR_FLAG,
                                            v_err_msg
                                            );
                    EXCEPTION
                        WHEN OTHERS THEN
                            V_ERR_MSG :='Error while calling LP_TRANSACTION_LOG-' || SUBSTR (SQLERRM, 1, 200);
                    END;
                    COMMIT;
                WHEN OTHERS THEN
                    ROLLBACK;
                    V_ERR_MSG :='Error in main loop -' || SUBSTR (SQLERRM, 1, 200);

                    BEGIN
                        INSERT INTO CMS_CHARGE_DTL
                                        (CCD_INST_CODE,
                                        CCD_PAN_CODE,
                                        CCD_MBR_NUMB,
                                        CCD_ACCT_NO,
                                        CCD_FEE_FREQ,
                                        CCD_FEETYPE_CODE,
                                        CCD_FEE_CODE,
                                        CCD_CALC_AMT,
                                        CCD_EXPCALC_DATE,
                                        CCD_CALC_DATE,
                                        CCD_FILE_NAME,
                                        CCD_FILE_DATE,
                                        CCD_INS_USER,
                                        CCD_LUPD_USER,
                                        CCD_FILE_STATUS,
                                        CCD_RRN,
                                        CCD_PROCESS_MSG,
                                        CCD_FEE_PLAN,
                                        CCD_PAN_CODE_ENCR,
                                        CCD_GL_ACCT_NO,
                                        CCD_DELIVERY_CHANNEL,
                                        CCD_TXN_CODE)
                        VALUES
                                        (P_INSTCODE,
                                        C3.CAP_PAN_CODE,
                                        '000',
                                        C3.CAP_ACCT_NO,
                                        C3.CFT_FEE_FREQ,
                                        C3.CFT_FEETYPE_CODE,
                                        C3.CFM_FEE_CODE,
                                        ROUND(V_CFM_FEE_AMT,2),  --Modified by Revathi on 02-APR-2014 for 3decimal place issue
                                        SYSDATE,
                                        SYSDATE,
                                        'N',
                                        SYSDATE,
                                        P_LUPDUSER,
                                        P_LUPDUSER,
                                        'E',
                                        V_RRN2, --Modified by Deepa on July 02 2012 for the error record to have different status
                                        V_ERR_MSG,
                                        C3.CFF_FEE_PLAN,
                                        C3.CAP_PAN_CODE_ENCR,
                                        C3.CPF_CRACCT_NO,
                                        V_DELIVERY_CHANNEL,
                                        V_TXN_CODE);
                    EXCEPTION
                        WHEN OTHERS THEN
                            P_ERRMSG := 'Error while inserting into CHARGE_DTL 1.0 ' || SUBSTR(SQLERRM, 1, 200);
                    END;

                    BEGIN
                        LP_TRANSACTION_LOG(p_instcode,
                                            C3.cap_pan_code,
                                            C3.cap_pan_code_encr,
                                            v_rrn2,
                                            v_delivery_channel,
                                            v_business_date,
                                            v_business_time,
                                            C3.cap_acct_no,
                                            v_acct_bal,
                                            v_ledger_bal,
                                            null,
                                            v_auth_id,
                                            v_tran_desc,
                                            v_txn_code,
                                            21,
                                            NULL ,
                                            NULL,
                                            C3.cfm_fee_code,
                                            C3.cff_fee_plan,
                                            C3.cpf_cracct_no,
                                            C3.cpf_dracct_no,
                                            'C',
                                            C3.cap_card_stat,
                                            v_cam_type_code,
                                            v_timestamp  ,
                                            C3.cap_prod_code,
                                            C3.cap_card_type,
                                            V_DR_CR_FLAG,
                                            v_err_msg
                                            );
                    EXCEPTION
                        WHEN OTHERS THEN
                            V_ERR_MSG :='Error while calling LP_TRANSACTION_LOG-' || SUBSTR (SQLERRM, 1, 200);
                    END;
                    COMMIT;
            END;
        END LOOP;
    END;

    P_ERRMSG := 'Monthly Fee Calculated for ' || V_UPD_REC_CNT || ' Cards';
EXCEPTION
    WHEN OTHERS THEN
        P_ERRMSG := 'Error in sp_calc_monthly_fees ' || SUBSTR(SQLERRM, 1, 200);
END SP_CALC_MONTHLY_FEES;
/
show error