create or replace PROCEDURE                 VMSCMS.SP_CLOSE_SAVINGS_ACCT(P_INST_CODE        IN NUMBER,
                                         P_PAN_CODE         IN NUMBER,
                                          P_SVG_ACCT_NO      IN VARCHAR2,
                                          P_DELIVERY_CHANNEL IN VARCHAR2,
                                          P_TXN_CODE         IN VARCHAR2,
                                          P_RRN              IN VARCHAR2,
                                          P_TXN_MODE         IN VARCHAR2,
                                          P_TRAN_DATE        IN VARCHAR2,
                                          P_TRAN_TIME        IN VARCHAR2,
                                          P_ANI              IN VARCHAR2,
                                          P_DNI              IN VARCHAR2,
                                          P_IPADDRESS        IN VARCHAR2,
                                          P_BANK_CODE        IN VARCHAR2, --Added by Ramesh.A on 08/03/2012
                                          P_CURR_CODE        IN VARCHAR2, --Added by Ramesh.A on 08/03/2012
                                          P_RVSL_CODE        IN VARCHAR2, --Added by Ramesh.A on 08/03/2012
                                          P_MSG              IN VARCHAR2, --Added by Ramesh.A on 08/03/2012
                                          P_MOB_NO           IN VARCHAR2, --Added For regarding FSS-1144
                                          P_DEVICE_ID        IN VARCHAR2, --Added For regarding FSS-1144
                                          P_RESP_CODE        OUT VARCHAR2,
                                          P_RESMSG           OUT VARCHAR2,
                                          P_SPEND_ACCT_BAL   OUT NUMBER) AS --Added for CR - 40 in release 23.1.1
  /*********************************************************************************************************************************
      * Created Date     :  20-Feb-2012
      * Created By       :  Sivakumar
      * PURPOSE          :  Saving account
      * modified by      : Saravanakumar
      * modified Date    : 11-Feb-2013
      * modified reason  : For CR - 40 in release 23.1.1
      * Reviewer         : Sachin
      * Reviewed Date    :  13-Feb-2013
      * Build Number     : CMS3.5.1_RI0023.1.1_B0004
      * modified by      : Ramesh.A
      * modified Date    : 22-Apr-2013
      * modified reason  : Added condition for delivery channel 13 and txn code 12 for MOB savings account close with balance transfer txn for MOB-26
      * Reviewer         : dhiraj
      * Reviewed Date    :
      * Build Number     : RI0024.1_B0011

      * Modified by      :  Shweta
      * Modified Reason  :  DFCCSD-70
      * Modified Date    :  05-Jun-2013
      * Reviewer         :  Sachin P.
      * Reviewed Date    :  18-Jun-2013
      * Build Number     :  RI0024.2_B0004

      * Modified by      :  S Ramkumar
      * Modified Reason  :  Mantis Id - 11357
      * Modified Date    :  25-Jun-2013
      * Reviewer         :  Dhiraj
      * Reviewed Date    :  26-Jun-13
      * Build Number     :  RI0024.2_B0009

      * Modified by      :  Pankaj S.
      * Modified Reason  :  DFCCSD-70
      * Modified Date    :  23-Aug-2013
      * Reviewer         :  Dhiraj
      * Reviewed Date    :  23-Aug-2013
      * Build Number     :  RI0024.4_B0004

	  * modified by      :  MageshKumar.S
      * modified Date    :  29-AUG-13
      * modified reason  :  FSS-1144
      * Reviewer         :  Dhiraj
      * Reviewed Date    :  29-AUG-13
      * Build Number     :  RI0024.4_B0009

     * Modified By      : Sai Prasad
     * Modified Date    : 11-Sep-2013
     * Modified For     : Mantis ID: 0012275 (JIRA FSS-1144)
     * Modified Reason  : ANI & DNI is not logged in transactionlog table.
     * Reviewer         : Dhiraj
     * Reviewed Date    : 11-Sep-2013
     * Build Number     : RI0024.4_B0010

     * Modified Date    : 10-Dec-2013
     * Modified By      : Sagar More
     * Modified for     : Defect ID 13160
     * Modified reason  : To log below details in transactinlog if applicable
                          Product code,cardtype,cr_dr_flag
     * Reviewer         : Dhiraj
     * Reviewed Date    : 10-Dec-2013
     * Release Number   : RI0024.7_B0001

     * Modified By      : Siva Kumar M
     * Modified For     : FSS-2279(MVCSD-5614)
     * Modified Date    : 26-AUGUST-2015
     * Modified Reason  : Changes done for accounts close while card close
     * Build Number     : VMSGPRHOSTCSD3.1_B0006

     * Modified by      : A.Sivakaminathan
     * Modified Date    : 31-Dec-2015
     * Modified for     : MVHOST-1249	Enhancement	Closure of saving account on seventh transfer
     * Reviewer         : Pankaj Salunkhe
     * Build Number     : VMSGPRHOSTCSD_3.3

        * Modified by       : Siva Kumar M
        * Modified Date     : 18-Jul-17
        * Modified For      : FSS-5172 - B2B changes
        * Reviewer          : Saravanakumar A
        * Build Number      : VMSGPRHOST_17.07

     * Modified by       : John G
     * Modified Date     : 14-Feb-2023
     * Modified For      : VMS-7004:  CPRDVMS1 Sequence Alert -SEQ_ACCT_ID    sequence
     * Reviewer          :
     * Build Number      : VMSGPRHOST R76

  *************************************************************************************************************************************/
  V_SAVING_ACCTNO     VARCHAR2(20);
  V_TRAN_DATE         DATE;
  V_CARDSTAT          VARCHAR2(5);
  V_CARDEXP           DATE;
  --V_AUTH_SAVEPOINT    NUMBER DEFAULT 0;--Commented for CR-40
  V_COUNT             NUMBER;
  V_ACCTID            CMS_ACCT_MAST.CAM_ACCT_ID%TYPE;
  V_RRN_COUNT         NUMBER;
  V_BRANCH_CODE       VARCHAR2(5);
  V_ERRMSG            VARCHAR2(500);
  --V_MAXNO_TRAN        NUMBER(4); Commended for defect id 10186
  V_SAVINNGS_BAL      CMS_ACCT_MAST.CAM_ACCT_BAL%TYPE;
  V_WITHDRAWL_COUNT   NUMBER(4);
  V_SAVING_STAT       NUMBER(4);
  V_HASH_PAN          CMS_APPL_PAN.CAP_PAN_CODE%TYPE;
  V_ENCR_PAN_FROM     CMS_APPL_PAN.CAP_PAN_CODE_ENCR%TYPE;
  V_CUST_CODE         CMS_PAN_ACCT.CPA_CUST_CODE%TYPE;
  V_SPND_ACCT_NO      CMS_ACCT_MAST.CAM_ACCT_NO%TYPE;
  V_ACCT_TYPE         CMS_ACCT_TYPE.CAT_TYPE_CODE%TYPE;
  V_ACCT_STAT         CMS_ACCT_MAST.CAM_STAT_CODE%TYPE;
  V_ACCT_STATS        CMS_ACCT_MAST.CAM_STAT_CODE%TYPE;
  V_TXN_TYPE          TRANSACTIONLOG.TXN_TYPE%TYPE;
  V_SWITCH_ACCT_TYPE  CMS_ACCT_TYPE.CAT_SWITCH_TYPE%TYPE DEFAULT '22';
  V_SWITCH_ACCT_STAT  CMS_ACCT_STAT.CAS_SWITCH_STATCODE%TYPE DEFAULT '3';
  V_SWITCH_ACCT_STATS CMS_ACCT_STAT.CAS_SWITCH_STATCODE%TYPE DEFAULT '2';
  V_SVENACCTBAL              NUMBER;  --Added by Besky for CR-40 ON 04/01/2013
  V_SVENACCTLEDGBAL          NUMBER;   --Added by Besky for CR-40 ON 04/01/2013
  V_Saving_acct_txn_count    NUMBER;    --Added by Besky for CR-40 ON 04/01/2013
  V_Saving_acct_rem_count    NUMBER;    --Added by Besky for CR-40 ON 04/01/2013


  --St:Added by Ramesh.A on 08/03/2012
  V_CARD_EXPRY   VARCHAR2(20);
  V_STAN         VARCHAR2(20);
  V_CAPTURE_DATE DATE;
  V_TERM_ID      VARCHAR2(20);
  V_MCC_CODE     VARCHAR2(20);
  V_TXN_AMT      NUMBER;
  V_ACCT_NUMBER  NUMBER;

  V_DR_CR_FLAG  VARCHAR2(2);
  V_OUTPUT_TYPE VARCHAR2(2);
  V_TRAN_TYPE   VARCHAR2(2);

  V_AUTH_ID TRANSACTIONLOG.AUTH_ID%TYPE;
  EXP_AUTH_REJECT_RECORD EXCEPTION;
  --End: Added by Ramesh.A on 08/03/2012
  V_TRANS_DESC CMS_TRANSACTION_MAST.CTM_TRAN_DESC%TYPE; --Added for transaction detail report on 210812

  EXP_REJECT_RECORD EXCEPTION;
  EXP_REJECT_SAVING EXCEPTION;--Added for CR-40
  v_respcode               VARCHAR2 (5);    --   Added for Mantis Id - 11357

  --Sn Added by Pankaj S. for DFCCSD-70 changes
  v_acct_bal         cms_acct_mast.cam_acct_bal%TYPE;
  v_ledger_bal       cms_acct_mast.cam_ledger_bal%TYPE;
  v_spd_acct_type    cms_acct_mast.cam_type_code%TYPE;
  v_auth_flag        VARCHAR2(2);
  --En Added by Pankaj S. for DFCCSD-70 changes

   v_timestamp              timestamp(3); -- Added  on 29-08-2013 for  FSS-1144
   V_HASHKEY_ID   CMS_TRANSACTION_LOG_DTL.CTD_HASHKEY_ID%TYPE; -- Added  on 29-08-2013 for  FSS-1144

   --Added on 13160
   v_prod_code     cms_appl_pan.cap_prod_code%type;
   v_card_type     cms_appl_pan.cap_card_type%type;
   --Added on 13160
   v_max_svg_trns_limt      cms_dfg_param.cdp_param_key%TYPE;
v_Retperiod  date;  --Added for VMS-5739/FSP-991
v_Retdate  date; --Added for VMS-5739/FSP-991
  --Main Begin Block Starts Here
BEGIN
  V_TXN_TYPE := '1';
  P_RESMSG   := '';
  v_timestamp :=SYSTIMESTAMP; -- Added on 29-08-2013 for FSS-1144
  --SAVEPOINT V_AUTH_SAVEPOINT;--Commented for CR-40

  -- Get the HashPan
  BEGIN
    V_HASH_PAN := GETHASH(P_PAN_CODE);
  EXCEPTION
    WHEN OTHERS THEN
     P_RESP_CODE := '12';
     V_ERRMSG    := 'Error while converting pan ' ||
                 SUBSTR(SQLERRM, 1, 200);
     RAISE EXP_REJECT_RECORD;
  END;

  --SN create encr pan
  BEGIN
    V_ENCR_PAN_FROM := FN_EMAPS_MAIN(P_PAN_CODE);
  EXCEPTION
    WHEN OTHERS THEN
     P_RESP_CODE := '12';
     V_ERRMSG    := 'Error while converting pan ' ||
                 SUBSTR(SQLERRM, 1, 200);
     RAISE EXP_REJECT_RECORD;
  END;
   -- Start Generate HashKEY value for FSS-1144
       BEGIN
           V_HASHKEY_ID := GETHASH (P_DELIVERY_CHANNEL||P_TXN_CODE||P_PAN_CODE||P_RRN||to_char(v_timestamp,'YYYYMMDDHH24MISSFF5'));
       EXCEPTION
        WHEN OTHERS
        THEN
        p_resp_code := '12';
        p_resmsg :='Error while converting master data ' || SUBSTR (SQLERRM, 1, 200);
        RAISE EXP_REJECT_RECORD;
     END;
    --End Generate HashKEY value for FSS-1144

  --Sn find debit and credit flag

  BEGIN
    SELECT CTM_CREDIT_DEBIT_FLAG,
         CTM_OUTPUT_TYPE,
         TO_NUMBER(DECODE(CTM_TRAN_TYPE, 'N', '0', 'F', '1')),
         CTM_TRAN_TYPE,
         CTM_TRAN_DESC
     INTO V_DR_CR_FLAG,
         V_OUTPUT_TYPE,
         V_TXN_TYPE,
         V_TRAN_TYPE,
         V_TRANS_DESC
     FROM CMS_TRANSACTION_MAST
    WHERE CTM_TRAN_CODE = P_TXN_CODE AND
         CTM_DELIVERY_CHANNEL = P_DELIVERY_CHANNEL AND
         CTM_INST_CODE = P_INST_CODE;
  EXCEPTION
    WHEN NO_DATA_FOUND THEN
     P_RESP_CODE := '12'; --Ineligible Transaction
     V_ERRMSG    := 'Transflag  not defined for txn code ' || P_TXN_CODE ||
                 ' and delivery channel ' || P_DELIVERY_CHANNEL;
     RAISE EXP_REJECT_RECORD;
    WHEN OTHERS THEN
     P_RESP_CODE := '21'; --Ineligible Transaction
     V_ERRMSG    := 'Error while selecting transaction details';
     RAISE EXP_REJECT_RECORD;
  END;

  --En find debit and credit flag

  --Sn Duplicate RRN Check
  BEGIN
	--Added for VMS-5739/FSP-991
 select (add_months(trunc(sysdate,'MM'),'-'||RETENTION_PERIOD))
       INTO   v_Retperiod 
       FROM DBA_OPERATIONS.ARCHIVE_MGMNT_CTL 
       WHERE  OPERATION_TYPE='ARCHIVE' 
       AND OBJECT_NAME='TRANSACTIONLOG_EBR';
       
       v_Retdate := TO_DATE(SUBSTR(TRIM(P_TRAN_DATE), 1, 8), 'yyyymmdd');


IF (v_Retdate>v_Retperiod)
    THEN
    SELECT COUNT(1)
     INTO V_RRN_COUNT
     FROM VMSCMS.TRANSACTIONLOG
    WHERE RRN = P_RRN AND BUSINESS_DATE = P_TRAN_DATE AND
         DELIVERY_CHANNEL = P_DELIVERY_CHANNEL; --Added by ramkumar.Mk on 25 march 2012
		 ELSE
		 SELECT COUNT(1)
     INTO V_RRN_COUNT
     FROM VMSCMS_HISTORY.TRANSACTIONLOG_HIST
    WHERE RRN = P_RRN AND BUSINESS_DATE = P_TRAN_DATE AND
         DELIVERY_CHANNEL = P_DELIVERY_CHANNEL; --Added by ramkumar.Mk on 25 march 2012
		 END IF;
    IF V_RRN_COUNT > 0 THEN
     P_RESP_CODE := '22';
     V_ERRMSG    := 'Duplicate RRN on ' || P_TRAN_DATE;

     RAISE EXP_REJECT_RECORD;
    END IF;
  --Sn added by Pankaj S. during DFCCSD-70(Review) changes to handled exception
  EXCEPTION
   WHEN exp_reject_record THEN
    RAISE;
   WHEN OTHERS THEN
    p_resp_code := '21';
    v_errmsg :='Error while checking  duplicate RRN-'|| SUBSTR(SQLERRM, 1, 200);
    RAISE exp_reject_record;
  --En added by Pankaj S. during DFCCSD-70(Review) changes to handled exception
  END;
  --En Duplicate RRN Check
  --Sn get date
  BEGIN
    V_TRAN_DATE := TO_DATE(SUBSTR(TRIM(P_TRAN_DATE), 1, 8) || ' ' ||
                      SUBSTR(TRIM(P_TRAN_TIME), 1, 8),
                      'yyyymmdd hh24:mi:ss');
  EXCEPTION
    WHEN OTHERS THEN
     P_RESP_CODE := '21';
     V_ERRMSG    := 'Problem while converting transaction date ' ||
                 SUBSTR(SQLERRM, 1, 200);
     RAISE EXP_REJECT_RECORD;
  END;
  --En get date
  BEGIN
    SELECT CAP_CARD_STAT, CAP_EXPRY_DATE, CAP_ACCT_NO,
           cap_cust_code  --Added by Pankaj S. during DFCCSD-70(Review) changes
		   ,cap_prod_code,cap_card_type
     INTO V_CARDSTAT, V_CARDEXP, V_SPND_ACCT_NO,
          V_CUST_CODE    --Added by Pankaj S. during DFCCSD-70(Review) changes
		  ,v_prod_code,v_card_type
     FROM CMS_APPL_PAN
    WHERE CAP_INST_CODE = P_INST_CODE AND CAP_PAN_CODE = V_HASH_PAN;

  EXCEPTION
    WHEN NO_DATA_FOUND THEN
     P_RESP_CODE := '16'; --Ineligible Transaction
     V_ERRMSG    := 'Card number not found ';
     RAISE EXP_REJECT_RECORD;
    WHEN OTHERS THEN
     P_RESP_CODE := '12';
     V_ERRMSG    := 'Problem while selecting card detail' ||
                 SUBSTR(SQLERRM, 1, 200);
     RAISE EXP_REJECT_RECORD;
  END;

  IF( P_DELIVERY_CHANNEL ='05' AND P_TXN_CODE='47')  THEN
		BEGIN
			 SELECT  cdp_param_value
			 INTO  v_max_svg_trns_limt
			 FROM cms_dfg_param
			 WHERE cdp_param_key = 'MaxNoTrans'
			 AND  cdp_inst_code = p_inst_code
			 AND cdp_prod_code = v_prod_code
       and cdp_card_type = v_card_type;
			 V_TRANS_DESC := 'Saving Account Closure due to '||v_max_svg_trns_limt||'th Transfer';
		EXCEPTION
			WHEN OTHERS THEN
				 p_resp_code:= '12';
				 v_errmsg := 'Error while selecting Savings Max Tran Limit ' ||
							SUBSTR(SQLERRM, 1, 200);
				RAISE exp_reject_record;
		END;
  END IF;

  /*--Sn Check Delivery Channel  Commented by Besky on 10/01/2013 for CR-40

  IF P_DELIVERY_CHANNEL NOT IN ('10', '07') THEN
    V_ERRMSG    := 'Not a valid delivery channel  for ' ||
                ' Savings account close';
    P_RESP_CODE := '21'; ---ISO MESSAGE FOR DATABASE ERROR
    RAISE EXP_REJECT_RECORD;
  END IF;
  --En Check Delivery Channel
  --Sn Check Transaction code.
  IF P_TXN_CODE NOT IN ('21', '12') THEN
      ----Txncode...........
    V_ERRMSG    := 'Not a valid transaction code for ' ||
                ' saving account close';
    P_RESP_CODE := '21'; ---ISO MESSAGE FOR DATABASE ERROR
    RAISE EXP_REJECT_RECORD;
  END IF;*/

  --En Check Transaction code.
  --Sn select acct type
  BEGIN
    SELECT CAT_TYPE_CODE
     INTO V_ACCT_TYPE
     FROM CMS_ACCT_TYPE
    WHERE CAT_INST_CODE = P_INST_CODE AND
         CAT_SWITCH_TYPE = V_SWITCH_ACCT_TYPE;
  EXCEPTION
    WHEN NO_DATA_FOUND THEN
     P_RESP_CODE := '21'; --Added by Ramesh.A on 08/03/2012
     V_ERRMSG    := 'Acct type not defined in master';
     RAISE EXP_REJECT_RECORD;
    WHEN OTHERS THEN
     P_RESP_CODE := '21'; --Added by Ramesh.A on 08/03/2012
     V_ERRMSG    := 'Error while selecting accttype ' ||
                 SUBSTR(SQLERRM, 1, 200);
     RAISE EXP_REJECT_RECORD;
  END;

  --Sn Commented below block here & used above query to get customer code during DFCCSD-70(Review) changes
  -- Sn Get cust code from master.
  /*BEGIN
    SELECT CAP_CUST_CODE
     INTO V_CUST_CODE
     FROM CMS_APPL_PAN
    WHERE CAP_PAN_CODE = V_HASH_PAN AND CAP_INST_CODE = P_INST_CODE;
  EXCEPTION
    WHEN NO_DATA_FOUND THEN
     P_RESP_CODE := '21'; --Added by Ramesh.A on 08/03/2012
     V_ERRMSG    := 'Cust code Not Found';
     RAISE EXP_REJECT_RECORD;
    WHEN OTHERS THEN
     P_RESP_CODE := '12';
     V_ERRMSG    := 'Error while getting  cust code from master ' ||
                 SUBSTR(SQLERRM, 1, 200);
  END;
  --En Get  cust code from master*/
  --En Commented below block here & used above query to get customer code during DFCCSD-70(Review) changes

  --Sn select acct stat
  BEGIN
    SELECT CAS_STAT_CODE
     INTO V_ACCT_STAT
     FROM CMS_ACCT_STAT
    WHERE CAS_INST_CODE = P_INST_CODE AND
         CAS_SWITCH_STATCODE = V_SWITCH_ACCT_STAT;
  EXCEPTION
    WHEN NO_DATA_FOUND THEN
     P_RESP_CODE := '21'; --Added by Ramesh.A on 08/03/2012
     V_ERRMSG    := 'Acct stats not defined for  master';
     RAISE EXP_REJECT_RECORD;
    WHEN OTHERS THEN
     P_RESP_CODE := '21'; --Added by Ramesh.A on 08/03/2012
     V_ERRMSG    := 'Error while selecting accttype ' ||
                 SUBSTR(SQLERRM, 1, 200);
     RAISE EXP_REJECT_RECORD;
  END;
  --En select acct stat

  --Sn Commented below block here & used below query during DFCCSD-70(Review) changes
  /*--Sn check whether the Saving Account already created or not
  BEGIN
    SELECT COUNT(1)
     INTO V_COUNT
     FROM CMS_ACCT_MAST
    WHERE CAM_ACCT_ID IN
         (SELECT CCA_ACCT_ID
            FROM CMS_CUST_ACCT
           WHERE CCA_CUST_CODE = V_CUST_CODE AND
                CCA_INST_CODE = P_INST_CODE) AND
         CAM_TYPE_CODE = V_ACCT_TYPE AND CAM_INST_CODE = P_INST_CODE;

    IF V_COUNT = 0 THEN
     V_ERRMSG    := 'Savings account not created for this card';
     P_RESP_CODE := '105';
     RAISE EXP_REJECT_RECORD;
    END IF;

  EXCEPTION
    --Added by Ramesh.A on 08/03/2012
    WHEN EXP_REJECT_RECORD THEN
     --Added by Ramesh.A on 08/03/2012
     RAISE EXP_REJECT_RECORD;
    WHEN OTHERS THEN
     P_RESP_CODE := '21'; --Added by Ramesh.A on 08/03/2012
     V_ERRMSG    := 'Error while checking savinnd account ' ||
                 SUBSTR(SQLERRM, 1, 200);
     RAISE EXP_REJECT_RECORD;
  END;
  --En check whether the Saving Account already created or not*/
  --En Commented below block here & used below query during DFCCSD-70(Review) changes

  --SN CHECK SAVINGS ACCOUNT IS VALID OR NOT.

  BEGIN
    SELECT CAM_ACCT_NO,
           cam_stat_code,cam_acct_bal,cam_ledger_bal  --Added by Pankaj S. during DFCCSD-70(Review) changes
     INTO V_SAVING_ACCTNO,
          v_saving_stat,v_savinngs_bal,v_svenacctledgbal   --Added by Pankaj S. during DFCCSD-70(Review) changes
     FROM CMS_ACCT_MAST
    WHERE CAM_ACCT_ID IN
         (SELECT CCA_ACCT_ID
            FROM CMS_CUST_ACCT
           WHERE CCA_CUST_CODE = V_CUST_CODE AND
                CCA_INST_CODE = P_INST_CODE) AND
         CAM_TYPE_CODE = V_ACCT_TYPE AND CAM_INST_CODE = P_INST_CODE;

    IF V_SAVING_ACCTNO <> P_SVG_ACCT_NO THEN
     V_ERRMSG    := 'Invalid Savings account number';
     P_RESP_CODE := '109';
     RAISE EXP_REJECT_RECORD;
    END IF;
  EXCEPTION
    WHEN EXP_REJECT_RECORD THEN
     --Added by Ramesh.A on 08/03/2012
     RAISE EXP_REJECT_RECORD;
    --Sn added by Pankaj S. during DFCCSD-70(Review) changes
    WHEN NO_DATA_FOUND THEN
     V_ERRMSG    := 'Savings account not created for this card';
     P_RESP_CODE := '105';
     RAISE EXP_REJECT_RECORD;
    --En added by Pankaj S. during DFCCSD-70(Review) changes
    WHEN OTHERS THEN
     P_RESP_CODE := '21'; --Added by Ramesh.A on 08/03/2012
     V_ERRMSG    := 'Error while selecting CMS_ACCT_MAST ' ||
                 SUBSTR(SQLERRM, 1, 200);
     RAISE EXP_REJECT_RECORD;
  END;
  --EN CHECK SAVINGS ACCOUNT IS VALID OR NOT.
  --STATUS
  BEGIN
    SELECT CAS_STAT_CODE
     INTO V_ACCT_STATS
     FROM CMS_ACCT_STAT
    WHERE CAS_INST_CODE = P_INST_CODE AND
         CAS_SWITCH_STATCODE = V_SWITCH_ACCT_STATS;
  EXCEPTION
    WHEN NO_DATA_FOUND THEN
     P_RESP_CODE := '21'; --Added by Ramesh.A on 08/03/2012
     V_ERRMSG    := 'Acct stat not defined for  master';
     RAISE EXP_REJECT_RECORD;
    WHEN OTHERS THEN
     P_RESP_CODE := '21'; --Added by Ramesh.A on 08/03/2012
     V_ERRMSG    := 'Error while selecting accttype ' ||
                 SUBSTR(SQLERRM, 1, 200);
     RAISE EXP_REJECT_RECORD;
  END;
  --EN STATUS.

  --Sn Modified by Pankaj During DFCCSD-70(Review) changes

  --CHECKING SAVINGS ACCOUNT IS OPEN OR NOT.
  /*BEGIN
    SELECT CAM_STAT_CODE
     INTO V_SAVING_STAT
     FROM CMS_ACCT_MAST
    WHERE CAM_ACCT_ID IN
         (SELECT CCA_ACCT_ID
            FROM CMS_CUST_ACCT
           WHERE CCA_CUST_CODE = V_CUST_CODE AND
                CCA_INST_CODE = P_INST_CODE) AND
         CAM_TYPE_CODE = V_ACCT_TYPE AND CAM_INST_CODE = P_INST_CODE;*/

    IF V_ACCT_STATS = V_SAVING_STAT THEN
     V_ERRMSG    := 'SAVINGS ACCOUNT ALREADY CLOSED';
     P_RESP_CODE := '106';
     RAISE EXP_REJECT_RECORD;
    END IF;
 /* EXCEPTION
    WHEN EXP_REJECT_RECORD THEN
     --Added by Ramesh.A on 08/03/2012
     RAISE EXP_REJECT_RECORD;
    WHEN OTHERS THEN
     P_RESP_CODE := '21'; --Added by Ramesh.A on 08/03/2012
     V_ERRMSG    := 'Error while selecting CMS_ACCT_MAST1 ' ||
                 SUBSTR(SQLERRM, 1, 200);
     RAISE EXP_REJECT_RECORD;
  END;*/
  --END CHECKING SAVINGS ACCOUNT IS OPEN NOT.

  --En Modified by Pankaj During DFCCSD-70(Review) changes

  -- BALANCE CHECKING
  BEGIN

    --Sn Commented by Pankaj During DFCCSD-70(Review) changes
    /*SELECT CAM_ACCT_BAL,
           cam_ledger_bal  --added by Pankaj S. for DFCCSD-70 changes
     INTO  V_SAVINNGS_BAL,
           v_svenacctledgbal --added by Pankaj S. for DFCCSD-70 changes
     FROM CMS_ACCT_MAST
    WHERE CAM_ACCT_ID IN
         (SELECT CCA_ACCT_ID
            FROM CMS_CUST_ACCT
           WHERE CCA_CUST_CODE = V_CUST_CODE AND
                CCA_INST_CODE = P_INST_CODE) AND
         CAM_TYPE_CODE = V_ACCT_TYPE AND CAM_INST_CODE = P_INST_CODE;*/
    --En Commented by Pankaj During DFCCSD-70(Review) changes

    IF V_SAVINNGS_BAL > 0 THEN

         --Sn Added by Besky for CR-40 If saving account balance is grater than zero while closing saving account.
         --we have to transfer the balance amount from saving account to spending account and close the saving account.
         --Added P_DELIVERY_CHANNEL ='13' AND P_TXN_CODE='12' by Ramesh.A on 22/04/2013 for defect MOB-26
       IF   (( P_DELIVERY_CHANNEL ='05' AND P_TXN_CODE='47') OR
	   ( P_DELIVERY_CHANNEL ='07' AND P_TXN_CODE='21') OR ( P_DELIVERY_CHANNEL ='10' AND P_TXN_CODE='40') OR (P_DELIVERY_CHANNEL ='13' AND P_TXN_CODE='12') OR ( P_DELIVERY_CHANNEL ='05' AND P_TXN_CODE='40'))  THEN   --Added by B.Besky  on 04/01/2013 for CR->40 To retsrict the condition for these Transaction codes and delivery channel.

           BEGIN

                       sp_savingstospendingtransfer(P_BANK_CODE,
                                                   P_PAN_CODE,
                                                   p_msg,
                                                   V_SPND_ACCT_NO,
                                                   P_SVG_ACCT_NO,
                                                   P_DELIVERY_CHANNEL,
                                                   P_TXN_CODE,
                                                   P_RRN,
                                                   V_SAVINNGS_BAL,
                                                   P_TXN_MODE,
                                                   p_bank_code,
                                                   P_CURR_CODE,
                                                   P_RVSL_CODE,
                                                   p_tran_date,
                                                   p_tran_time,
                                                   p_ipaddress,
                                                   p_ani,
                                                   p_dni,
                                                   p_resp_code,
                                                   v_errmsg,
                                                   v_svenacctbal,
                                                   v_svenacctledgbal,
                                                   v_saving_acct_txn_count,
                                                   v_saving_acct_rem_count
                                                   );
                    if p_resp_code <>'00' then
                        RAISE EXP_REJECT_SAVING;
                    end if;

           EXCEPTION
           when  EXP_REJECT_SAVING then
                RAISE EXP_REJECT_SAVING;
           WHEN OTHERS THEN
                 P_RESP_CODE := '21';
                 V_ERRMSG    := 'Error from  sp_savingstospendingtransfer' ||   SUBSTR(SQLERRM, 1, 200);
           RAISE EXP_REJECT_RECORD;
           END;

       ELSE

         V_ERRMSG    := 'Savings account balance is greater than zero. Please move the savings account balance manually ';
         P_RESP_CODE := '107';
         RAISE EXP_REJECT_RECORD;

       END IF;

    ELSE --Added by Ramesh.A on 22/04/2013 for logging two entries in log table.

     --ST :  Added by Ramesh.A on 08/03/2012
     --Sn call to authorize procedure
      BEGIN
        SP_AUTHORIZE_TXN_CMS_AUTH(P_INST_CODE,
                        P_MSG,
                        P_RRN,
                        P_DELIVERY_CHANNEL,
                        V_TERM_ID,
                        P_TXN_CODE,
                        P_TXN_MODE,
                        P_TRAN_DATE,
                        P_TRAN_TIME,
                        P_PAN_CODE,
                        P_BANK_CODE,
                        V_TXN_AMT,
                        NULL,
                        NULL,
                        V_MCC_CODE,
                        P_CURR_CODE,
                        NULL,
                        NULL,
                        NULL,
                        V_ACCT_NUMBER,
                        NULL,
                        NULL,
                        NULL,
                        NULL,
                        NULL,
                        NULL,
                        NULL,
                        NULL,
                        V_CARD_EXPRY,
                        V_STAN,
                        '000',
                        P_RVSL_CODE,
                        V_TXN_AMT,
                        V_AUTH_ID,
                        P_RESP_CODE,
                        V_ERRMSG,
                        V_CAPTURE_DATE);
        IF P_RESP_CODE <> '00' AND V_ERRMSG <> 'OK' THEN
         --P_RESP_CODE := '21'; Commented by Besky on 06-nov-12
         --V_ERRMSG    := 'Error from auth process' || V_ERRMSG;
           P_RESMSG := 'Error from auth process' || V_ERRMSG;

            --Sn added by Pankaj S. for DFCCSD-70 changes
            IF (( P_DELIVERY_CHANNEL ='07' AND P_TXN_CODE='21') OR ( P_DELIVERY_CHANNEL ='10' AND P_TXN_CODE='40') OR (P_DELIVERY_CHANNEL ='13' AND P_TXN_CODE='12')) THEN
            BEGIN
               SELECT cam_acct_bal, cam_ledger_bal, cam_type_code
                 INTO v_acct_bal, v_ledger_bal, v_spd_acct_type
                 FROM cms_acct_mast
                WHERE cam_inst_code = p_inst_code AND cam_acct_no = v_spnd_acct_no;
            EXCEPTION
               WHEN OTHERS
               THEN
                  p_resp_code := '12';
                  v_errmsg :=
                        'Error while selecting spending acct balance-'
                     || SUBSTR (SQLERRM, 1, 200);
                  RAISE exp_reject_record;
            END;

            BEGIN
			--Added for VMS-5739/FSP-991
 select (add_months(trunc(sysdate,'MM'),'-'||RETENTION_PERIOD))
       INTO   v_Retperiod 
       FROM DBA_OPERATIONS.ARCHIVE_MGMNT_CTL 
       WHERE  OPERATION_TYPE='ARCHIVE' 
       AND OBJECT_NAME='TRANSACTIONLOG_EBR';
       
       v_Retdate := TO_DATE(SUBSTR(TRIM(p_tran_date), 1, 8), 'yyyymmdd');


IF (v_Retdate>v_Retperiod)
    THEN
               UPDATE transactionlog
                  SET topup_card_no = v_hash_pan,
                      topup_card_no_encr = v_encr_pan_from,
                      topup_acct_no = v_spnd_acct_no,
                      topup_acct_type = v_spd_acct_type,
                      topup_acct_balance = v_acct_bal,
                      topup_ledger_balance = v_ledger_bal,
                      customer_acct_no = v_saving_acctno,
                      acct_type = v_acct_type,
                      acct_balance = v_savinngs_bal,
                      ledger_balance =v_svenacctledgbal,
                      ANI = P_ANI, --Added for mantis id 0012275(FSS-1144)
                      DNI = P_DNI --Added for mantis id 0012275(FSS-1144
                WHERE instcode = p_inst_code
                  AND rrn = p_rrn
                  AND delivery_channel = p_delivery_channel
                  AND txn_code = p_txn_code
                  AND business_date = p_tran_date
                  AND business_time = p_tran_time
                  AND msgtype = p_msg;
				  ELSE
				   UPDATE VMSCMS_HISTORY.transactionlog_HIST
                  SET topup_card_no = v_hash_pan,
                      topup_card_no_encr = v_encr_pan_from,
                      topup_acct_no = v_spnd_acct_no,
                      topup_acct_type = v_spd_acct_type,
                      topup_acct_balance = v_acct_bal,
                      topup_ledger_balance = v_ledger_bal,
                      customer_acct_no = v_saving_acctno,
                      acct_type = v_acct_type,
                      acct_balance = v_savinngs_bal,
                      ledger_balance =v_svenacctledgbal,
                      ANI = P_ANI, --Added for mantis id 0012275(FSS-1144)
                      DNI = P_DNI --Added for mantis id 0012275(FSS-1144
                WHERE instcode = p_inst_code
                  AND rrn = p_rrn
                  AND delivery_channel = p_delivery_channel
                  AND txn_code = p_txn_code
                  AND business_date = p_tran_date
                  AND business_time = p_tran_time
                  AND msgtype = p_msg;
				  END IF;

               IF SQL%ROWCOUNT = 0 THEN
                  v_errmsg := 'ERROR WHILE UPDATING TRANSACTIONLOG';
                  p_resp_code := '21';
                  RAISE exp_reject_record;
               END IF;
            EXCEPTION
               WHEN exp_reject_record THEN
                  RAISE exp_reject_record;
               WHEN OTHERS THEN
                  p_resp_code := '21';
                  v_errmsg :=
                        'Problem on updated Transactionlog-'|| SUBSTR (SQLERRM, 1, 200);
                  RAISE exp_reject_record;
            END;

            BEGIN
			--Added for VMS-5739/FSP-991
 select (add_months(trunc(sysdate,'MM'),'-'||RETENTION_PERIOD))
       INTO   v_Retperiod 
       FROM DBA_OPERATIONS.ARCHIVE_MGMNT_CTL 
       WHERE  OPERATION_TYPE='ARCHIVE' 
       AND OBJECT_NAME='CMS_TRANSACTION_LOG_DTL_EBR';
       
       v_Retdate := TO_DATE(SUBSTR(TRIM(P_TRAN_DATE), 1, 8), 'yyyymmdd');


IF (v_Retdate>v_Retperiod)
    THEN
              UPDATE VMSCMS.CMS_TRANSACTION_LOG_DTL
              SET ctd_cust_acct_number=v_saving_acctno,
              CTD_MOBILE_NUMBER=P_MOB_NO, --Added for regarding FSS_1144
              CTD_DEVICE_ID=P_DEVICE_ID   --Added for regarding FSS_1144
              WHERE CTD_RRN=P_RRN AND CTD_BUSINESS_DATE=P_TRAN_DATE
              AND CTD_BUSINESS_TIME=P_TRAN_TIME
              AND CTD_DELIVERY_CHANNEL=P_DELIVERY_CHANNEL
              AND CTD_TXN_CODE=P_TXN_CODE
              AND CTD_MSG_TYPE=P_MSG
              AND CTD_INST_CODE=P_INST_CODE;
			  ELSE
			    UPDATE VMSCMS_HISTORY.CMS_TRANSACTION_LOG_DTL_HIST
              SET ctd_cust_acct_number=v_saving_acctno,
              CTD_MOBILE_NUMBER=P_MOB_NO, --Added for regarding FSS_1144
              CTD_DEVICE_ID=P_DEVICE_ID   --Added for regarding FSS_1144
              WHERE CTD_RRN=P_RRN AND CTD_BUSINESS_DATE=P_TRAN_DATE
              AND CTD_BUSINESS_TIME=P_TRAN_TIME
              AND CTD_DELIVERY_CHANNEL=P_DELIVERY_CHANNEL
              AND CTD_TXN_CODE=P_TXN_CODE
              AND CTD_MSG_TYPE=P_MSG
              AND CTD_INST_CODE=P_INST_CODE;
			  END IF;

             IF SQL%ROWCOUNT = 0 THEN
                V_ERRMSG  := 'ERROR WHILE UPDATING CMS_TRANSACTION_LOG_DTL ';
                P_RESP_CODE := '21';
              RAISE EXP_REJECT_RECORD;
             END IF;
             EXCEPTION
             WHEN EXP_REJECT_RECORD THEN
             RAISE EXP_REJECT_RECORD;
             WHEN OTHERS THEN
                P_RESP_CODE := '21';
                V_ERRMSG  := 'Problem on updated cms_Transaction_log_dtl ' ||
                SUBSTR(SQLERRM, 1, 200);
               RAISE EXP_REJECT_RECORD;
            END;
            END IF;
            --En Added by Pankaj S. for DFCCSD-70 changes


           RETURN;
         --RAISE EXP_AUTH_REJECT_RECORD;
        ELSE
          --Sn Added by Pankaj S. for DFCCSD-70 changes
          IF (( P_DELIVERY_CHANNEL ='05' AND P_TXN_CODE='47') OR ( P_DELIVERY_CHANNEL ='07' AND P_TXN_CODE='21') OR ( P_DELIVERY_CHANNEL ='10' AND P_TXN_CODE='40') OR (P_DELIVERY_CHANNEL ='13' AND P_TXN_CODE='12')) THEN
          v_auth_flag:='Y';
          END IF;
          --En Added by Pankaj S. for DFCCSD-70 changes
        END IF;
      EXCEPTION
       /*WHEN EXP_AUTH_REJECT_RECORD THEN  Commented by Besky on 06-nov-12
        RAISE EXP_REJECT_RECORD;*/
      WHEN OTHERS THEN
        P_RESP_CODE := '21';
        V_ERRMSG    := 'Error from Card authorization' ||
                 SUBSTR(SQLERRM, 1, 200);
        RAISE EXP_REJECT_RECORD;
    END;
    --En call to authorize procedure
    --End :  Added by Ramesh.A on 08/03/2012

  END IF;

        --End for CR-40

  EXCEPTION
    WHEN EXP_REJECT_RECORD THEN
     --Added by Ramesh.A on 08/03/2012
     RAISE EXP_REJECT_RECORD;

  WHEN EXP_REJECT_SAVING THEN -- added for defect 0010163
  RAISE EXP_REJECT_SAVING;

  WHEN OTHERS THEN
     P_RESP_CODE := '21'; --Added by Ramesh.A on 08/03/2012
     V_ERRMSG    := 'Error while selecting CMS_ACCT_MAST2 ' ||
                 SUBSTR(SQLERRM, 1, 200);
     RAISE EXP_REJECT_RECORD;
  END;
  --END BALANCE CHECKING.
--Sn Commended for defect id 10186
/*
  BEGIN
    SELECT CDP_PARAM_VALUE
     INTO V_MAXNO_TRAN
     FROM CMS_DFG_PARAM
    WHERE CDP_PARAM_KEY = 'MaxNoTrans';
  EXCEPTION
    WHEN NO_DATA_FOUND THEN
     V_ERRMSG := 'Max No of Transfer not defined';
     RAISE EXP_REJECT_RECORD;
    WHEN OTHERS THEN
     P_RESP_CODE := '21'; --Added by Ramesh.A on 08/03/2012
     V_ERRMSG    := 'Error while getting Max No of Transfers' ||
                 SUBSTR(SQLERRM, 1, 200);
     RAISE EXP_REJECT_RECORD;
  END;
  --WITHDRAWL CHECKING...
  BEGIN

    SELECT COUNT(*)
     INTO V_WITHDRAWL_COUNT
     FROM TRANSACTIONLOG
       WHERE ((delivery_channel='07' AND  txn_code IN('11','21') ) or (delivery_channel='10' AND  txn_code IN ('20','40') ) or (delivery_channel='13' AND  txn_code='11' ))-- Modified by Besky on 04/01/2013 for CR-40
         and BUSINESS_DATE BETWEEN
         TO_CHAR(TRUNC(SYSDATE, 'MONTH'), 'YYYYMMDD') AND
         TO_CHAR(LAST_DAY(SYSDATE), 'YYYYMMDD') AND RESPONSE_CODE = '00' AND
         CUSTOMER_CARD_NO = V_HASH_PAN AND
         CUSTOMER_ACCT_NO = V_SAVING_ACCTNO ;--AND TXN_CODE IN (20, 11);

    IF  V_WITHDRAWL_COUNT = V_MAXNO_TRAN  THEN
    IF  NOT (( P_DELIVERY_CHANNEL ='07' AND P_TXN_CODE='21') OR ( P_DELIVERY_CHANNEL ='10' AND P_TXN_CODE='40'))  THEN --Added by B.Besky  on 04/01/2013 for CR->40 not require this check for close saving account with balance.
     V_ERRMSG    := 'Maximum number of transaction reached for the calendar month. Please wait for next calendar month to close the savings account';
     P_RESP_CODE := '108';
     RAISE EXP_REJECT_RECORD;
     END IF;
    END IF;
  EXCEPTION
    --Added by Ramesh.A on 08/03/2012
    WHEN EXP_REJECT_RECORD THEN
     --Added by Ramesh.A on 08/03/2012
     RAISE EXP_REJECT_RECORD;
    WHEN OTHERS THEN
     P_RESP_CODE := '21'; --Added by Ramesh.A on 08/03/2012
     V_ERRMSG    := 'Error while selecting WITHDRAWL_COUNT ' ||
                 SUBSTR(SQLERRM, 1, 200);
     RAISE EXP_REJECT_RECORD;

  END;
  -- EN WITHDRAWL CHECKING.
*/
--En Commended for defect id 10186

 /*  --Commented by Ramesh.A on 22/04/2013 for logging two entries in log table.
 --ST :  Added by Ramesh.A on 08/03/2012
     --Sn call to authorize procedure
      BEGIN
        SP_AUTHORIZE_TXN_CMS_AUTH(P_INST_CODE,
                        P_MSG,
                        P_RRN,
                        P_DELIVERY_CHANNEL,
                        V_TERM_ID,
                        P_TXN_CODE,
                        P_TXN_MODE,
                        P_TRAN_DATE,
                        P_TRAN_TIME,
                        P_PAN_CODE,
                        P_BANK_CODE,
                        V_TXN_AMT,
                        NULL,
                        NULL,
                        V_MCC_CODE,
                        P_CURR_CODE,
                        NULL,
                        NULL,
                        NULL,
                        V_ACCT_NUMBER,
                        NULL,
                        NULL,
                        NULL,
                        NULL,
                        NULL,
                        NULL,
                        NULL,
                        NULL,
                        V_CARD_EXPRY,
                        V_STAN,
                        '000',
                        P_RVSL_CODE,
                        V_TXN_AMT,
                        V_AUTH_ID,
                        P_RESP_CODE,
                        V_ERRMSG,
                        V_CAPTURE_DATE);
        IF P_RESP_CODE <> '00' AND V_ERRMSG <> 'OK' THEN
         --P_RESP_CODE := '21'; Commented by Besky on 06-nov-12
         --V_ERRMSG    := 'Error from auth process' || V_ERRMSG;
           P_RESMSG := 'Error from auth process' || V_ERRMSG;
           RETURN;
         --RAISE EXP_AUTH_REJECT_RECORD;
        END IF;
      EXCEPTION
       --WHEN EXP_AUTH_REJECT_RECORD THEN  Commented by Besky on 06-nov-12
       -- RAISE EXP_REJECT_RECORD;
      WHEN OTHERS THEN
        P_RESP_CODE := '21';
        V_ERRMSG    := 'Error from Card authorization' ||
                 SUBSTR(SQLERRM, 1, 200);
        RAISE EXP_REJECT_RECORD;
    END;
    --En call to authorize procedure
    --End :  Added by Ramesh.A on 08/03/2012
    */

  --Sn update savings account status.
  BEGIN
    UPDATE CMS_ACCT_MAST
      SET CAM_STAT_CODE = V_ACCT_STATS, CAM_INTEREST_AMOUNT = 0 --Updated by Ramesh.A on 23/04/2012
    WHERE CAM_ACCT_NO = V_SAVING_ACCTNO AND CAM_TYPE_CODE = V_ACCT_TYPE AND
         CAM_INST_CODE = P_INST_CODE;

    IF SQL%ROWCOUNT = 0 THEN
     P_RESP_CODE := '21';
     V_ERRMSG    := 'EXCEPTION WHILE UPDATING SAVINGS ACCOUNT STATUS ' ||
                 SQLCODE || '---' || SQLERRM;
     RAISE EXP_REJECT_RECORD;
    END IF;
  EXCEPTION
    WHEN EXP_REJECT_RECORD THEN
     --Added by Ramesh.A on 08/03/2012
     RAISE EXP_REJECT_RECORD;
    WHEN OTHERS THEN
     P_RESP_CODE := '12';
     V_ERRMSG    := 'EXCEPTION WHILE UPDATING SAVINGS ACCOUNT STATUS ' ||
                 SQLCODE || '---' || SQLERRM;
     RAISE EXP_REJECT_RECORD;
  END;

  IF (P_DELIVERY_CHANNEL ='05' AND P_TXN_CODE='47') THEN
  BEGIN
  --Added for VMS-5739/FSP-991
 select (add_months(trunc(sysdate,'MM'),'-'||RETENTION_PERIOD))
       INTO   v_Retperiod 
       FROM DBA_OPERATIONS.ARCHIVE_MGMNT_CTL 
       WHERE  OPERATION_TYPE='ARCHIVE' 
       AND OBJECT_NAME='TRANSACTIONLOG_EBR';
       
       v_Retdate := TO_DATE(SUBSTR(TRIM(p_tran_date), 1, 8), 'yyyymmdd');


IF (v_Retdate>v_Retperiod)
    THEN
    UPDATE VMSCMS.transactionlog
          SET trans_desc = v_trans_desc
        WHERE rrn = p_rrn
          AND delivery_channel = p_delivery_channel
          AND txn_code = p_txn_code
          AND business_date = p_tran_date
          AND business_time = p_tran_time
          AND msgtype = p_msg
          AND customer_card_no = v_hash_pan
          AND instcode = p_inst_code;
		  ELSE
		   UPDATE VMSCMS_HISTORY.transactionlog_HIST
          SET trans_desc = v_trans_desc
        WHERE rrn = p_rrn
          AND delivery_channel = p_delivery_channel
          AND txn_code = p_txn_code
          AND business_date = p_tran_date
          AND business_time = p_tran_time
          AND msgtype = p_msg
          AND customer_card_no = v_hash_pan
          AND instcode = p_inst_code;
		  END IF;
           IF SQL%ROWCOUNT = 0 THEN
                V_ERRMSG  := 'ERROR WHILE UPDATING transactionlog ';
                P_RESP_CODE := '21';
              RAISE EXP_REJECT_RECORD;
             END IF;
             EXCEPTION
             WHEN EXP_REJECT_RECORD THEN
             RAISE EXP_REJECT_RECORD;
             WHEN OTHERS THEN
                P_RESP_CODE := '21';
                V_ERRMSG  := 'Problem on updated transactionlog ' ||
                SUBSTR(SQLERRM, 1, 200);
               RAISE EXP_REJECT_RECORD;
            END;

  END IF;

-- Sn Added for CR - 40 in release 23.1.1

            --Sn Added by Pankaj S. for DFCCSD-70 changes
            IF v_auth_flag='Y' THEN
            BEGIN
			--Added for VMS-5739/FSP-991
 select (add_months(trunc(sysdate,'MM'),'-'||RETENTION_PERIOD))
       INTO   v_Retperiod 
       FROM DBA_OPERATIONS.ARCHIVE_MGMNT_CTL 
       WHERE  OPERATION_TYPE='ARCHIVE' 
       AND OBJECT_NAME='CMS_TRANSACTION_LOG_DTL_EBR';
       
       v_Retdate := TO_DATE(SUBSTR(TRIM(p_tran_date), 1, 8), 'yyyymmdd');


IF (v_Retdate>v_Retperiod)
    THEN
                UPDATE VMSCMS.cms_transaction_log_dtl
                   SET ctd_cust_acct_number =v_saving_acctno,
                   CTD_MOBILE_NUMBER=P_MOB_NO, --Added for regarding FSS_1144
                   CTD_DEVICE_ID=P_DEVICE_ID   --Added for regarding FSS_1144
                 WHERE ctd_rrn = p_rrn
                   AND ctd_business_date = p_tran_date
                   AND ctd_business_time = p_tran_time
                   AND ctd_delivery_channel = p_delivery_channel
                   AND ctd_txn_code = p_txn_code
                   AND ctd_msg_type = p_msg
                   AND ctd_inst_code = p_inst_code;
				   ELSE
				    UPDATE VMSCMS_HISTORY.cms_transaction_log_dtl_HIST
                   SET ctd_cust_acct_number =v_saving_acctno,
                   CTD_MOBILE_NUMBER=P_MOB_NO, --Added for regarding FSS_1144
                   CTD_DEVICE_ID=P_DEVICE_ID   --Added for regarding FSS_1144
                 WHERE ctd_rrn = p_rrn
                   AND ctd_business_date = p_tran_date
                   AND ctd_business_time = p_tran_time
                   AND ctd_delivery_channel = p_delivery_channel
                   AND ctd_txn_code = p_txn_code
                   AND ctd_msg_type = p_msg
                   AND ctd_inst_code = p_inst_code;
				   END IF;
             IF SQL%ROWCOUNT = 0 THEN
                V_ERRMSG  := 'ERROR WHILE UPDATING CMS_TRANSACTION_LOG_DTL ';
                P_RESP_CODE := '21';
              RAISE EXP_REJECT_RECORD;
             END IF;
             EXCEPTION
             WHEN EXP_REJECT_RECORD THEN
             RAISE EXP_REJECT_RECORD;
             WHEN OTHERS THEN
                P_RESP_CODE := '21';
                V_ERRMSG  := 'Problem on updated cms_Transaction_log_dtl ' ||
                SUBSTR(SQLERRM, 1, 200);
               RAISE EXP_REJECT_RECORD;
            END;
            END IF;
            --En Added by Pankaj S. for DFCCSD-70 changes
       --Start Logging into cms_Transactionlog_dtl table for  regarding FSS-1144
            BEGIN
			--Added for VMS-5739/FSP-991
 select (add_months(trunc(sysdate,'MM'),'-'||RETENTION_PERIOD))
       INTO   v_Retperiod 
       FROM DBA_OPERATIONS.ARCHIVE_MGMNT_CTL 
       WHERE  OPERATION_TYPE='ARCHIVE' 
       AND OBJECT_NAME='CMS_TRANSACTION_LOG_DTL_EBR';
       
       v_Retdate := TO_DATE(SUBSTR(TRIM(p_tran_date), 1, 8), 'yyyymmdd');


IF (v_Retdate>v_Retperiod)
    THEN
                UPDATE VMSCMS.cms_transaction_log_dtl
                   SET
                   CTD_MOBILE_NUMBER=P_MOB_NO, --Added for regarding FSS_1144
                   CTD_DEVICE_ID=P_DEVICE_ID   --Added for regarding FSS_1144
                 WHERE ctd_rrn = p_rrn
                   AND ctd_business_date = p_tran_date
                   AND ctd_business_time = p_tran_time
                   AND ctd_delivery_channel = p_delivery_channel
                   AND ctd_txn_code = p_txn_code
                   AND ctd_msg_type = p_msg
                   AND ctd_inst_code = p_inst_code;
				   ELSE
				    UPDATE VMSCMS_HISTORY.cms_transaction_log_dtl_HIST
                   SET
                   CTD_MOBILE_NUMBER=P_MOB_NO, --Added for regarding FSS_1144
                   CTD_DEVICE_ID=P_DEVICE_ID   --Added for regarding FSS_1144
                 WHERE ctd_rrn = p_rrn
                   AND ctd_business_date = p_tran_date
                   AND ctd_business_time = p_tran_time
                   AND ctd_delivery_channel = p_delivery_channel
                   AND ctd_txn_code = p_txn_code
                   AND ctd_msg_type = p_msg
                   AND ctd_inst_code = p_inst_code;
				   END IF;
             IF SQL%ROWCOUNT = 0 THEN
                V_ERRMSG  := 'ERROR WHILE UPDATING CMS_TRANSACTION_LOG_DTL ';
                P_RESP_CODE := '21';
              RAISE EXP_REJECT_RECORD;
             END IF;
             EXCEPTION
             WHEN EXP_REJECT_RECORD THEN
             RAISE EXP_REJECT_RECORD;
             WHEN OTHERS THEN
                P_RESP_CODE := '21';
                V_ERRMSG  := 'Problem on updated cms_Transaction_log_dtl ' ||
                SUBSTR(SQLERRM, 1, 200);
               RAISE EXP_REJECT_RECORD;
            END;
           --End Logging into cms_Transactionlog_dtl table for  regarding FSS-1144

    BEGIN
        select CAM_ACCT_BAL,
               cam_ledger_bal,cam_type_code  --added by Pankaj S. for DFCCSD-70 changes
        INTO P_SPEND_ACCT_BAL,
             v_ledger_bal,v_spd_acct_type --added by Pankaj S. for DFCCSD-70 changes
        from CMS_ACCT_MAST
        where CAM_ACCT_NO=V_SPND_ACCT_NO
        and CAM_INST_CODE=P_INST_CODE;
    EXCEPTION
        WHEN NO_DATA_FOUND THEN
        P_SPEND_ACCT_BAL:=NULL;
        WHEN OTHERS THEN
            P_RESP_CODE := '12';
            V_ERRMSG    := 'Error while selecting P_SPEND_ACCT_BAL ' ||substr(SQLERRM,1,200);
            RAISE EXP_REJECT_RECORD;
    END;
--En Added for CR - 40 in release 23.1.1
  P_RESP_CODE := '1';
  P_RESMSG    := '';
  --en update savings account status
  --ST Get responce code fomr master
  BEGIN
    SELECT CMS_ISO_RESPCDE
     INTO P_RESP_CODE
     FROM CMS_RESPONSE_MAST
    WHERE CMS_INST_CODE = P_INST_CODE AND
         CMS_DELIVERY_CHANNEL = P_DELIVERY_CHANNEL AND
         CMS_RESPONSE_ID = P_RESP_CODE;

  EXCEPTION
    WHEN NO_DATA_FOUND THEN
     P_RESP_CODE := '12'; --Added by Ramesh.A on 08/03/2012
     V_ERRMSG    := 'Responce code not found ' || P_RESP_CODE;
     RAISE EXP_REJECT_RECORD;
    WHEN OTHERS THEN
     P_RESP_CODE := '69'; ---ISO MESSAGE FOR DATABASE ERROR
     V_ERRMSG    := 'Problem while selecting data from response master ' ||
                 P_RESP_CODE || SUBSTR(SQLERRM, 1, 300);
    RAISE EXP_REJECT_RECORD; --Added by Pankaj S. during DFCCSD-70(Review) changes
  END;
  --En Get responce code fomr master

  --Sn update topup card number details in translog
  BEGIN
    --Sn added by Pankaj S. for DFCCSD-70 changes
    IF v_auth_flag='Y' THEN
	--Added for VMS-5739/FSP-991
 select (add_months(trunc(sysdate,'MM'),'-'||RETENTION_PERIOD))
       INTO   v_Retperiod 
       FROM DBA_OPERATIONS.ARCHIVE_MGMNT_CTL 
       WHERE  OPERATION_TYPE='ARCHIVE' 
       AND OBJECT_NAME='TRANSACTIONLOG_EBR';
       
       v_Retdate := TO_DATE(SUBSTR(TRIM(p_tran_date), 1, 8), 'yyyymmdd');


IF (v_Retdate>v_Retperiod)
    THEN
    UPDATE VMSCMS.transactionlog
          SET topup_card_no = v_hash_pan,
              topup_card_no_encr = v_encr_pan_from,
              topup_acct_no = v_spnd_acct_no,
              topup_acct_type = v_spd_acct_type,
              topup_acct_balance = p_spend_acct_bal,
              topup_ledger_balance = v_ledger_bal,
              customer_acct_no = v_saving_acctno,
              acct_type = v_acct_type,
              acct_balance = v_savinngs_bal,
              ledger_balance = v_svenacctledgbal,
              ANI = P_ANI, --Added for mantis id 0012275(FSS-1144)
              DNI = P_DNI --Added for mantis id 0012275(FSS-1144
        WHERE rrn = p_rrn
          AND delivery_channel = p_delivery_channel
          AND txn_code = p_txn_code
          AND business_date = p_tran_date
          AND business_time = p_tran_time
          AND msgtype = p_msg
          AND customer_card_no = v_hash_pan
          AND instcode = p_inst_code;
	ELSE
	UPDATE VMSCMS_HISTORY.transactionlog_HIST
          SET topup_card_no = v_hash_pan,
              topup_card_no_encr = v_encr_pan_from,
              topup_acct_no = v_spnd_acct_no,
              topup_acct_type = v_spd_acct_type,
              topup_acct_balance = p_spend_acct_bal,
              topup_ledger_balance = v_ledger_bal,
              customer_acct_no = v_saving_acctno,
              acct_type = v_acct_type,
              acct_balance = v_savinngs_bal,
              ledger_balance = v_svenacctledgbal,
              ANI = P_ANI, --Added for mantis id 0012275(FSS-1144)
              DNI = P_DNI --Added for mantis id 0012275(FSS-1144
        WHERE rrn = p_rrn
          AND delivery_channel = p_delivery_channel
          AND txn_code = p_txn_code
          AND business_date = p_tran_date
          AND business_time = p_tran_time
          AND msgtype = p_msg
          AND customer_card_no = v_hash_pan
          AND instcode = p_inst_code;
END IF;	
    ELSE
	--Added for VMS-5739/FSP-991
 select (add_months(trunc(sysdate,'MM'),'-'||RETENTION_PERIOD))
       INTO   v_Retperiod 
       FROM DBA_OPERATIONS.ARCHIVE_MGMNT_CTL 
       WHERE  OPERATION_TYPE='ARCHIVE' 
       AND OBJECT_NAME='TRANSACTIONLOG_EBR';
       
       v_Retdate := TO_DATE(SUBSTR(TRIM(P_TRAN_DATE), 1, 8), 'yyyymmdd');


IF (v_Retdate>v_Retperiod)
    THEN
    --En added by Pankaj S. for DFCCSD-70 changes
    UPDATE VMSCMS.TRANSACTIONLOG
      SET --RESPONSE_ID   = P_RESP_CODE,  --commented by Pankaj S. during DFCCSD-70(Review) changes
         ADD_LUPD_DATE = SYSDATE,
         ADD_LUPD_USER = 1,
         ERROR_MSG     = V_ERRMSG,
         ANI = P_ANI, --Added for mantis id 0012275(FSS-1144)
         DNI = P_DNI --Added for mantis id 0012275(FSS-1144
    WHERE RRN = P_RRN AND DELIVERY_CHANNEL = P_DELIVERY_CHANNEL AND
         TXN_CODE = P_TXN_CODE AND BUSINESS_DATE = P_TRAN_DATE AND
         BUSINESS_TIME = P_TRAN_TIME AND MSGTYPE = P_MSG AND
         CUSTOMER_CARD_NO = V_HASH_PAN AND INSTCODE = P_INST_CODE;
		 ELSE
		 UPDATE VMSCMS_HISTORY.TRANSACTIONLOG_HIST
      SET --RESPONSE_ID   = P_RESP_CODE,  --commented by Pankaj S. during DFCCSD-70(Review) changes
         ADD_LUPD_DATE = SYSDATE,
         ADD_LUPD_USER = 1,
         ERROR_MSG     = V_ERRMSG,
         ANI = P_ANI, --Added for mantis id 0012275(FSS-1144)
         DNI = P_DNI --Added for mantis id 0012275(FSS-1144
    WHERE RRN = P_RRN AND DELIVERY_CHANNEL = P_DELIVERY_CHANNEL AND
         TXN_CODE = P_TXN_CODE AND BUSINESS_DATE = P_TRAN_DATE AND
         BUSINESS_TIME = P_TRAN_TIME AND MSGTYPE = P_MSG AND
         CUSTOMER_CARD_NO = V_HASH_PAN AND INSTCODE = P_INST_CODE;
		 END IF;
    END IF;

    IF SQL%ROWCOUNT =0 THEN
     P_RESP_CODE := '21';
     V_ERRMSG    := 'Error while updating transactionlog ' ||
                 'no valid records ';
     RAISE EXP_REJECT_RECORD;
    END IF;

  EXCEPTION
    WHEN EXP_REJECT_RECORD THEN
     --Added by Ramesh.A on 08/03/2012
     RAISE EXP_REJECT_RECORD;
    WHEN OTHERS THEN
     P_RESP_CODE := '21';
     V_ERRMSG    := 'Error while updating transactionlog ' ||
                 SUBSTR(SQLERRM, 1, 200);
     RAISE EXP_REJECT_RECORD;
  END;
  --En update topup card number details in translog

  -- TransactionLog  has been removed by ramesh on 12/03/2012

  --Sn Handle EXP_REJECT_RECORD execption
EXCEPTION
    WHEN EXP_REJECT_SAVING THEN --Added by Besky for CR-40
        P_RESMSG:=V_ERRMSG;
  WHEN EXP_REJECT_RECORD THEN
    --ROLLBACK TO V_AUTH_SAVEPOINT;--Commented for CR-40
    ROLLBACK;
  P_RESMSG:=V_ERRMSG;
    --Sn Get responce code fomr master
    BEGIN
     SELECT CMS_ISO_RESPCDE
       --INTO P_RESP_CODE
       --Modified to set response code      --      Mantis Id - 11357       25th, June 2013
       INTO v_respcode
       FROM CMS_RESPONSE_MAST
      WHERE CMS_INST_CODE = P_INST_CODE AND
           CMS_DELIVERY_CHANNEL = P_DELIVERY_CHANNEL AND
           CMS_RESPONSE_ID = P_RESP_CODE;

    EXCEPTION
     WHEN OTHERS THEN
       V_ERRMSG    := 'Problem while selecting data from response master ' ||
                   P_RESP_CODE || SUBSTR(SQLERRM, 1, 300);
       P_RESP_CODE := '69';
    END;
    --En Get responce code fomr master

    --Sn Added by Pankaj S. for DFCCSD-70 changes
    IF ((P_DELIVERY_CHANNEL ='07' AND P_TXN_CODE='21') OR ( P_DELIVERY_CHANNEL ='10' AND P_TXN_CODE='40') OR (P_DELIVERY_CHANNEL ='13' AND P_TXN_CODE='12')) THEN
        BEGIN
           SELECT cam_acct_bal, cam_ledger_bal, cam_type_code
             INTO v_savinngs_bal, v_svenacctledgbal, v_acct_type
             FROM cms_acct_mast
            WHERE cam_inst_code = p_inst_code AND cam_acct_no = p_svg_acct_no;
        EXCEPTION
           WHEN OTHERS
           THEN
              v_savinngs_bal := 0;
              v_svenacctledgbal := 0;
        END;
    ELSE
        IF v_spnd_acct_no IS NULL THEN
        BEGIN
           SELECT cap_card_stat, cap_acct_no,cap_prod_code,cap_card_type
             INTO v_cardstat, v_spnd_acct_no,v_prod_code,v_card_type
             FROM cms_appl_pan
            WHERE cap_inst_code = p_inst_code AND cap_pan_code = v_hash_pan;
        EXCEPTION
           WHEN OTHERS
           THEN
              NULL;
        END;
        END IF;
        BEGIN
           SELECT cam_acct_bal, cam_ledger_bal, cam_type_code
             INTO v_acct_bal, v_ledger_bal, v_spd_acct_type
             FROM cms_acct_mast
            WHERE cam_inst_code = p_inst_code AND cam_acct_no = v_spnd_acct_no;
        EXCEPTION
           WHEN OTHERS
           THEN
              v_savinngs_bal := 0;
              v_svenacctledgbal := 0;
        END;
    END IF;
    --En Added by Pankaj S. for DFCCSD-70 changes

    --SN :- Added for 13160

   if V_DR_CR_FLAG is null
   then

      BEGIN
        SELECT CTM_CREDIT_DEBIT_FLAG
         INTO V_DR_CR_FLAG
         FROM CMS_TRANSACTION_MAST
        WHERE CTM_TRAN_CODE = P_TXN_CODE AND
             CTM_DELIVERY_CHANNEL = P_DELIVERY_CHANNEL AND
             CTM_INST_CODE = P_INST_CODE;
      EXCEPTION
      WHEN OTHERS
      THEN
            null;
      END;

   end if;

   if  v_prod_code is null
   then

    BEGIN
       SELECT cap_card_stat, cap_prod_code,cap_card_type
         INTO v_cardstat, v_prod_code,v_card_type
         FROM cms_appl_pan
        WHERE cap_inst_code = p_inst_code AND cap_pan_code = v_hash_pan;
    EXCEPTION
       WHEN OTHERS
       THEN
          NULL;
    END;

   end if;


   --EN :- Added for 13160


    --Sn Inserting data in transactionlog

     IF ((P_DELIVERY_CHANNEL ='07' AND P_TXN_CODE='21') OR ( P_DELIVERY_CHANNEL ='10' AND P_TXN_CODE='40')
          OR (P_DELIVERY_CHANNEL ='13' AND P_TXN_CODE='12')) THEN    --Condition added by Pankaj S. for DFCCSD-70 changes
     BEGIN
     INSERT INTO TRANSACTIONLOG
       (MSGTYPE,
        RRN,
        DELIVERY_CHANNEL,
        DATE_TIME,
        TXN_CODE,
        TXN_TYPE,
        TXN_MODE,
        TXN_STATUS,
        RESPONSE_CODE,
        BUSINESS_DATE,
        BUSINESS_TIME,
        CUSTOMER_CARD_NO,
        INSTCODE,
        CUSTOMER_CARD_NO_ENCR,
        CUSTOMER_ACCT_NO,
        ERROR_MSG,
        IPADDRESS,
        ANI,
        DNI,
        CARDSTATUS, --Added CARDSTATUS insert in transactionlog by srinivasu.k
        TRANS_DESC, -- FOR Transaction detail report issue
        RESPONSE_ID,
        ACCT_TYPE,  --Shweta on 18June13 for defect ID DFCCSD-70
        --Sn Added by Pankaj S. for DFCCSD-70 changes
        acct_balance,
        ledger_balance,time_stamp, -- Added on 29-08-2013 for FSS-1144
        --En Added by Pankaj S. for DFCCSD-70 changes
        --Added for 13160
        productid,
        Categoryid,
        cr_dr_flag
        --Added for 13160
        ) --shweta on 03June13)
     VALUES
       (P_MSG,
        P_RRN,
        P_DELIVERY_CHANNEL,
        SYSDATE,
        P_TXN_CODE,
        V_TXN_TYPE,
        P_TXN_MODE,
        'F',
        v_respcode,--Modified to set response code      --      Mantis Id - 11357       25th, June 2013
        P_TRAN_DATE,
        P_TRAN_TIME,
        V_HASH_PAN,
        P_INST_CODE,
        V_ENCR_PAN_FROM,
       -- V_SAVING_ACCTNO,
        P_SVG_ACCT_NO,--Shweta on 06June13 for defect ID DFCCSD-70
        V_ERRMSG,
        P_IPADDRESS,
        P_ANI,
        P_DNI,
        V_CARDSTAT, --Added CARDSTATUS insert in transactionlog by srinivasu.k
        V_TRANS_DESC, -- FOR Transaction detail report issue
        P_RESP_CODE,
        v_acct_type,  --Shweta on 18June13 for defect ID DFCCSD-70
        --Sn Added by Pankaj S. for DFCCSD-70 changes
        nvl(v_savinngs_bal,0),  --modified for 13160
        nvl(v_svenacctledgbal,0),   --modified for 13160
        v_timestamp,-- Added on 29-08-2013 for FSS-1144
        --En Added by Pankaj S. for DFCCSD-70 changes
        --Added for 13160
        v_prod_code,
        v_card_type,
        v_dr_cr_flag
        --Added for 13160
        );
      EXCEPTION
     WHEN OTHERS THEN
       P_RESP_CODE := '12';
       V_ERRMSG    := 'Exception while inserting to transaction log ' ||SUBSTR(SQLERRM, 1, 300);
     END;
       --Sn Added by Pankaj S. for DFCCSD-70 changes
       ELSE
      BEGIn
       INSERT INTO TRANSACTIONLOG
       (MSGTYPE,
        RRN,
        DELIVERY_CHANNEL,
        DATE_TIME,
        TXN_CODE,
        TXN_TYPE,
        TXN_MODE,
        TXN_STATUS,
        RESPONSE_CODE,
        BUSINESS_DATE,
        BUSINESS_TIME,
        CUSTOMER_CARD_NO,
        INSTCODE,
        CUSTOMER_CARD_NO_ENCR,
        CUSTOMER_ACCT_NO,
        ERROR_MSG,
        IPADDRESS,
        ANI,
        DNI,
        CARDSTATUS, --Added CARDSTATUS insert in transactionlog by srinivasu.k
        TRANS_DESC, -- FOR Transaction detail report issue
        RESPONSE_ID,
        ACCT_TYPE,  --Shweta on 18June13 for defect ID DFCCSD-70
        --Sn Added by Pankaj S. for DFCCSD-70 changes
        acct_balance,
        ledger_balance,time_stamp, -- Added on 29-08-2013 for FSS-1144
        --En Added by Pankaj S. for DFCCSD-70 changes
        --Added for 13160
        productid,
        Categoryid,
        cr_dr_flag
        --Added for 13160
        ) --shweta on 03June13)
     VALUES
       (P_MSG,
        P_RRN,
        P_DELIVERY_CHANNEL,
        SYSDATE,
        P_TXN_CODE,
        V_TXN_TYPE,
        P_TXN_MODE,
        'F',
        v_respcode,
        P_TRAN_DATE,
        P_TRAN_TIME,
        V_HASH_PAN,
        P_INST_CODE,
        V_ENCR_PAN_FROM,
        v_spnd_acct_no,
        V_ERRMSG,
        P_IPADDRESS,
        P_ANI,
        P_DNI,
        V_CARDSTAT,
        V_TRANS_DESC,
        P_RESP_CODE,
        v_spd_acct_type,
        nvl(v_acct_bal,0),  --modified for 13160
        nvl(v_ledger_bal,0),    --modified for 13160
        v_timestamp,-- Added on 29-08-2013 for FSS-1144
        --Added for 13160
        v_prod_code,
        v_card_type,
        v_dr_cr_flag
        --Added for 13160
        );
      EXCEPTION
     WHEN OTHERS THEN
       P_RESP_CODE := '12';
       V_ERRMSG    := 'Exception while inserting to transaction log ' ||SUBSTR(SQLERRM, 1, 300);
     END;
      END IF;
      --En Added by Pankaj S. for DFCCSD-70 changes

    --En Inserting data in transactionlog

    --Sn Inserting data in transactionlog dtl
    BEGIN

     INSERT INTO CMS_TRANSACTION_LOG_DTL
       (CTD_DELIVERY_CHANNEL,
        CTD_TXN_CODE,
        CTD_TXN_TYPE,
        CTD_TXN_MODE,
        CTD_BUSINESS_DATE,
        CTD_BUSINESS_TIME,
        CTD_CUSTOMER_CARD_NO,
        CTD_FEE_AMOUNT,
        CTD_WAIVER_AMOUNT,
        CTD_SERVICETAX_AMOUNT,
        CTD_CESS_AMOUNT,
        CTD_PROCESS_FLAG,
        CTD_PROCESS_MSG,
        CTD_RRN,
        CTD_INST_CODE,
        CTD_INS_DATE,
        CTD_CUSTOMER_CARD_NO_ENCR,
        CTD_MSG_TYPE,
        REQUEST_XML,
        CTD_CUST_ACCT_NUMBER,
        CTD_ADDR_VERIFY_RESPONSE,
        CTD_MOBILE_NUMBER, --Added for regarding FSS_1144
        CTD_DEVICE_ID,   --Added for regarding FSS_1144
        CTD_HASHKEY_ID --Added  on 29-08-2013 for Fss-1144
        )
     VALUES
       (P_DELIVERY_CHANNEL,
        P_TXN_CODE,
        V_TXN_TYPE,
        P_TXN_MODE,
        P_TRAN_DATE,
        P_TRAN_TIME,
        V_HASH_PAN,
        NULL,
        NULL,
        NULL,
        NULL,
        'E',
        V_ERRMSG,
        P_RRN,
        P_INST_CODE,
        SYSDATE,
        V_ENCR_PAN_FROM,
        P_MSG,
        '',
        --V_SAVING_ACCTNO,
        --Sn Modified by Pankaj S. for DFCCSD-70 changes
        CASE WHEN ((P_DELIVERY_CHANNEL ='07' AND P_TXN_CODE='21') OR ( P_DELIVERY_CHANNEL ='10' AND P_TXN_CODE='40') OR (P_DELIVERY_CHANNEL ='13' AND P_TXN_CODE='12')) THEN
         P_SVG_ACCT_NO--Shweta on 06June13 for defect ID DFCCSD-70
        ELSE
         v_spnd_acct_no
        END,
        --En Modified by Pankaj S. for DFCCSD-70 changes
        '',P_MOB_NO,P_DEVICE_ID,V_HASHKEY_ID  --Added  on 29-08-2013 for Fss-1144
        );
    EXCEPTION
     WHEN OTHERS THEN
       P_RESMSG--V_ERRMSG  --Modified by Pankaj S. during DFCCSD-70(Review) changes
        := 'Problem while inserting data into transaction log  dtl' ||
                   SUBSTR(SQLERRM, 1, 300);
       P_RESP_CODE := '69';
      RETURN;
    END;
    --En Inserting data in transactionlog dtl

    P_RESP_CODE := v_respcode;      -- Added to assign Response code in OUT parameter   --Mantis Id - 11357     --  25th, June 2013
  --En Handle EXP_REJECT_RECORD execption

  --Sn Handle OTHERS Execption
  WHEN OTHERS THEN
    P_RESP_CODE := '21';
    V_ERRMSG    := 'Main Exception ' || SQLCODE || '---' || SQLERRM;
    --ROLLBACK TO V_AUTH_SAVEPOINT;--Commented for CR-40
    ROLLBACK;
  P_RESMSG:=V_ERRMSG;
    --Sn Get responce code fomr master
    BEGIN
     SELECT CMS_ISO_RESPCDE
       --INTO P_RESP_CODE
       --Modified to set response code      --      Mantis Id - 11357       25th, June 2013
       INTO v_respcode
       FROM CMS_RESPONSE_MAST
      WHERE CMS_INST_CODE = P_INST_CODE AND
           CMS_DELIVERY_CHANNEL = P_DELIVERY_CHANNEL AND
           CMS_RESPONSE_ID = P_RESP_CODE;

    EXCEPTION
     WHEN OTHERS THEN
       V_ERRMSG    := 'Problem while selecting data from response master ' ||
                   P_RESP_CODE || SUBSTR(SQLERRM, 1, 300);
       P_RESP_CODE := '69';
    END;
    --En Get responce code fomr master

    --Sn Added by Pankaj S. for DFCCSD-70 changes
    IF ((P_DELIVERY_CHANNEL ='07' AND P_TXN_CODE='21') OR ( P_DELIVERY_CHANNEL ='10' AND P_TXN_CODE='40') OR (P_DELIVERY_CHANNEL ='13' AND P_TXN_CODE='12')) THEN
        BEGIN
           SELECT cam_acct_bal, cam_ledger_bal, cam_type_code
             INTO v_savinngs_bal, v_svenacctledgbal, v_acct_type
             FROM cms_acct_mast
            WHERE cam_inst_code = p_inst_code AND cam_acct_no = p_svg_acct_no;
        EXCEPTION
           WHEN OTHERS
           THEN
              v_savinngs_bal := 0;
              v_svenacctledgbal := 0;
        END;
    ELSE
        IF v_spnd_acct_no IS NULL THEN
        BEGIN
           SELECT cap_card_stat, cap_acct_no,cap_prod_code,cap_card_type
             INTO v_cardstat, v_spnd_acct_no,v_prod_code,v_card_type
             FROM cms_appl_pan
            WHERE cap_inst_code = p_inst_code AND cap_pan_code = v_hash_pan;
        EXCEPTION
           WHEN OTHERS
           THEN
              NULL;
        END;
        END IF;
        BEGIN
           SELECT cam_acct_bal, cam_ledger_bal, cam_type_code
             INTO v_acct_bal, v_ledger_bal, v_spd_acct_type
             FROM cms_acct_mast
            WHERE cam_inst_code = p_inst_code AND cam_acct_no = v_spnd_acct_no;
        EXCEPTION
           WHEN OTHERS
           THEN
              v_savinngs_bal := 0;
              v_svenacctledgbal := 0;
        END;
    END IF;
    --En Added by Pankaj S. for DFCCSD-70 changes

--SN :- Added for 13160

   if V_DR_CR_FLAG is null
   then

      BEGIN
        SELECT CTM_CREDIT_DEBIT_FLAG
         INTO V_DR_CR_FLAG
         FROM CMS_TRANSACTION_MAST
        WHERE CTM_TRAN_CODE = P_TXN_CODE AND
             CTM_DELIVERY_CHANNEL = P_DELIVERY_CHANNEL AND
             CTM_INST_CODE = P_INST_CODE;
      EXCEPTION
      WHEN OTHERS
      THEN
            null;
      END;

   end if;


   --EN :- Added for 13160


    --Sn Inserting data in transactionlog

     IF ((P_DELIVERY_CHANNEL ='07' AND P_TXN_CODE='21') OR ( P_DELIVERY_CHANNEL ='10' AND P_TXN_CODE='40')
          OR (P_DELIVERY_CHANNEL ='13' AND P_TXN_CODE='12')) THEN  --condition added by Pankaj S. for DFCCSD-70 changes
     BEGIN
     INSERT INTO TRANSACTIONLOG
       (MSGTYPE,
        RRN,
        DELIVERY_CHANNEL,
        DATE_TIME,
        TXN_CODE,
        TXN_TYPE,
        TXN_MODE,
        TXN_STATUS,
        RESPONSE_CODE,
        BUSINESS_DATE,
        BUSINESS_TIME,
        CUSTOMER_CARD_NO,
        INSTCODE,
        CUSTOMER_CARD_NO_ENCR,
        CUSTOMER_ACCT_NO,
        ERROR_MSG,
        IPADDRESS,
        ANI,
        DNI,
        CARDSTATUS, --Added CARDSTATUS insert in transactionlog by srinivasu.k
        TRANS_DESC, -- FOR Transaction detail report issue
        RESPONSE_ID,
        ACCT_TYPE,  --Shweta on 18June13 for defect ID DFCCSD-70
        --Sn Added by Pankaj S. for DFCCSD-70 changes
        acct_balance,
        ledger_balance,time_stamp, -- Added on 29-08-2013 for FSS-1144
        --En Added by Pankaj S. for DFCCSD-70 changes
        --Added for 13160
        productid,
        Categoryid,
        cr_dr_flag
        --Added for 13160
        )
     VALUES
       (P_MSG,
        P_RRN,
        P_DELIVERY_CHANNEL,
        SYSDATE,
        P_TXN_CODE,
        V_TXN_TYPE,
        P_TXN_MODE,
        'F',
        v_respcode,
        P_TRAN_DATE,
        P_TRAN_TIME,
        V_HASH_PAN,
        P_INST_CODE,
        V_ENCR_PAN_FROM,
       -- V_SAVING_ACCTNO,
        P_SVG_ACCT_NO,--Shweta on 06June13 for defect ID DFCCSD-70
        V_ERRMSG,
        P_IPADDRESS,
        P_ANI,
        P_DNI,
        V_CARDSTAT, --Added CARDSTATUS insert in transactionlog by srinivasu.k
        V_TRANS_DESC, -- FOR Transaction detail report issue
        P_RESP_CODE,
        v_acct_type,  --Shweta on 06June13 for defect ID DFCCSD-70
        --Sn Added by Pankaj S. for DFCCSD-70 changes
        nvl(v_savinngs_bal,0),                          --modified for 13160
        nvl(v_svenacctledgbal,0),v_timestamp,-- Added on 29-08-2013 for FSS-1144 --modified for 13160
        --En Added by Pankaj S. for DFCCSD-70 changes
        --Added for 13160
        v_prod_code,
        v_card_type,
        v_dr_cr_flag
        --Added for 13160
        );
     EXCEPTION
     WHEN OTHERS THEN
       P_RESP_CODE := '12';
       V_ERRMSG    := 'Exception while inserting to transaction log ' ||SUBSTR(SQLERRM, 1, 300);
     END;
       --Sn Added by Pankaj S. for DFCCSD-70 changes
       ELSE
       BEGIN
       INSERT INTO TRANSACTIONLOG
       (MSGTYPE,
        RRN,
        DELIVERY_CHANNEL,
        DATE_TIME,
        TXN_CODE,
        TXN_TYPE,
        TXN_MODE,
        TXN_STATUS,
        RESPONSE_CODE,
        BUSINESS_DATE,
        BUSINESS_TIME,
        CUSTOMER_CARD_NO,
        INSTCODE,
        CUSTOMER_CARD_NO_ENCR,
        CUSTOMER_ACCT_NO,
        ERROR_MSG,
        IPADDRESS,
        ANI,
        DNI,
        CARDSTATUS, --Added CARDSTATUS insert in transactionlog by srinivasu.k
        TRANS_DESC, -- FOR Transaction detail report issue
        RESPONSE_ID,
        ACCT_TYPE,  --Shweta on 18June13 for defect ID DFCCSD-70
        --Sn Added by Pankaj S. for DFCCSD-70 changes
        acct_balance,
        ledger_balance,time_stamp, -- Added on 29-08-2013 for FSS-1144
        --En Added by Pankaj S. for DFCCSD-70 changes
        --Added for 13160
        productid,
        Categoryid,
        cr_dr_flag
        --Added for 13160
        ) --shweta on 03June13)
     VALUES
       (P_MSG,
        P_RRN,
        P_DELIVERY_CHANNEL,
        SYSDATE,
        P_TXN_CODE,
        V_TXN_TYPE,
        P_TXN_MODE,
        'F',
        v_respcode,
        P_TRAN_DATE,
        P_TRAN_TIME,
        V_HASH_PAN,
        P_INST_CODE,
        V_ENCR_PAN_FROM,
        v_spnd_acct_no,
        V_ERRMSG,
        P_IPADDRESS,
        P_ANI,
        P_DNI,
        V_CARDSTAT,
        V_TRANS_DESC,
        P_RESP_CODE,
        v_spd_acct_type,
        nvl(v_acct_bal,0), --modified for 13160
        nvl(v_ledger_bal,0),    --modified for 13160
        v_timestamp,-- Added on 29-08-2013 for FSS-1144
        --Added for 13160
        v_prod_code,
        v_card_type,
        v_dr_cr_flag
        --Added for 13160
        );
     EXCEPTION
     WHEN OTHERS THEN
       P_RESP_CODE := '12';
       V_ERRMSG    := 'Exception while inserting to transaction log ' ||SUBSTR(SQLERRM, 1, 300);
     END;
      END IF;
      --En Added by Pankaj S. for DFCCSD-70 changes
        --En Inserting data in transactionlog

    --Sn Inserting data in transactionlog dtl
    BEGIN
     INSERT INTO CMS_TRANSACTION_LOG_DTL
       (CTD_DELIVERY_CHANNEL,
        CTD_TXN_CODE,
        CTD_TXN_TYPE,
        CTD_TXN_MODE,
        CTD_BUSINESS_DATE,
        CTD_BUSINESS_TIME,
        CTD_CUSTOMER_CARD_NO,
        CTD_FEE_AMOUNT,
        CTD_WAIVER_AMOUNT,
        CTD_SERVICETAX_AMOUNT,
        CTD_CESS_AMOUNT,
        CTD_PROCESS_FLAG,
        CTD_PROCESS_MSG,
        CTD_RRN,
        CTD_INST_CODE,
        CTD_INS_DATE,
        CTD_CUSTOMER_CARD_NO_ENCR,
        CTD_MSG_TYPE,
        REQUEST_XML,
        CTD_CUST_ACCT_NUMBER,
        CTD_ADDR_VERIFY_RESPONSE,
        CTD_MOBILE_NUMBER, --Added for regarding FSS_1144
        CTD_DEVICE_ID,   --Added for regarding FSS_1144
        CTD_HASHKEY_ID --Added  on 29-08-2013 for Fss-1144
        )
     VALUES
       (P_DELIVERY_CHANNEL,
        P_TXN_CODE,
        V_TXN_TYPE,
        P_TXN_MODE,
        P_TRAN_DATE,
        P_TRAN_TIME,
        V_HASH_PAN,
        NULL,
        NULL,
        NULL,
        NULL,
        'E',
        V_ERRMSG,
        P_RRN,
        P_INST_CODE,
        SYSDATE,
        V_ENCR_PAN_FROM,
        P_MSG,
        '',
        --V_SAVING_ACCTNO,
        --Sn Modified by Pankaj S. for DFCCSD-70 changes
        CASE WHEN ((P_DELIVERY_CHANNEL ='07' AND P_TXN_CODE='21') OR ( P_DELIVERY_CHANNEL ='10' AND P_TXN_CODE='40') OR (P_DELIVERY_CHANNEL ='13' AND P_TXN_CODE='12')) THEN
         P_SVG_ACCT_NO--Shweta on 06June13 for defect ID DFCCSD-70
        ELSE
         v_spnd_acct_no
        END,
        --En Modified by Pankaj S. for DFCCSD-70 changes
        '',P_MOB_NO,P_DEVICE_ID,V_HASHKEY_ID --Added  on 29-08-2013 for Fss-1144
        );
    EXCEPTION
     WHEN OTHERS THEN
       P_RESMSG--V_ERRMSG  --Modified by Pankaj S. during DFCCSD-70(Review) changes
        := 'Problem while inserting data into transaction log  dtl' ||
                   SUBSTR(SQLERRM, 1, 300);
       P_RESP_CODE := '69';

       RETURN;
    END;
    --En Inserting data in transactionlog dtl
  --En Handle OTHERS Execption
  P_RESP_CODE := v_respcode;      -- Added to assign Response code in OUT parameter   --Mantis Id - 11357     --  25th, June 2013

END;
/
SHOW ERROR;