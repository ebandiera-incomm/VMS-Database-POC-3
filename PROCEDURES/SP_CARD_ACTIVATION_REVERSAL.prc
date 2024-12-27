create or replace
PROCEDURE VMSCMS.SP_CARD_ACTIVATION_REVERSAL(P_INST_CODE     IN NUMBER,
                                             P_MSG_TYP       IN VARCHAR2,
                                             P_RVSL_CODE     IN VARCHAR2,
                                             P_RRN           IN VARCHAR2,
                                             P_DELV_CHNL     IN VARCHAR2,
                                             P_TERMINAL_ID   IN VARCHAR2,
                                             P_TXN_CODE      IN VARCHAR2,
                                             P_TXN_TYPE      IN VARCHAR2,
                                             P_TXN_MODE      IN VARCHAR2,
                                             P_BUSINESS_DATE IN VARCHAR2,
                                             P_BUSINESS_TIME IN VARCHAR2,
                                             P_CARD_NO       IN VARCHAR2,
                                             P_MBR_NUMB      IN VARCHAR2,
                                             P_CURR_CODE     IN VARCHAR2,
                                             P_MERCHANT_NAME IN VARCHAR2,
                                             P_MERCHANT_CITY IN VARCHAR2,
                                             P_RESP_CDE      OUT VARCHAR2,
                                             P_RESP_MSG      OUT VARCHAR2,
                                             P_DDA_NUMBER    OUT VARCHAR2 -- Added by Ramesh.A on 03/07/2012
                                             ) IS
  /**************************************************************************************************
      * Modified Date    :  09/01/2013
      * Modified Reason  : 9957 Changes which has been done for the MMPOS activation needs to update the KYC in the
                          cms_cust_mast since the activation from the CSR is checking the cms_cust_mast tablE.
      * Reviewer         :  Saravanakumar
      * Reviewed Date    : 09/01/2013
      * Release Number   : CMS3.5.1_RI0023_B0011

      * Modified By      : MageshKumar S.
      * Modified Date    : 25-Apr-2013
      * Modified Reason  : Logging of Mailing Address changes in Addr mast(DFCHOST-310)
      * Reviewer         : Dhiraj
      * Reviewed Date    :
      * Build Number     :

      * Modified By      : Sagar M.
      * Modified Date    : 17-Apr-2013
      * Modified for     : Defect 10871
      * Modified Reason  : Logging of below details in tranasctionlog
                            1) Product code,Product category code,Acct Type,drcr flag
                            2) Timestamp and Amount values logging correction
      * Reviewer         : Dhiraj
      * Reviewed Date    : 17-Apr-2013
      * Build Number     : RI0024.1_B0013

      * Modified by      :  Pankaj S.
      * Modified Reason  :  11839(Log store id)
      * Modified Date    :  01-Aug-2013
      * Reviewer         :  Dhiraj
      * Reviewed Date    :  01-Aug-2013
      * Build Number     :  RI0024.4_B0001

      * Modified by      : Sachin P.
      * Modified for     : Mantis Id -11693
      * Modified Reason  : CR_DR_FLAG in transactionlog table is incorrectly inserted for the Reversal
                           Transactions(Original transaction's CR_DR flag is inserted)
      * Modified Date    : 25-Jul-2013
      * Reviewer         : Dhiraj
      * Reviewed Date    : 19-aug-2013
      * Build Number     :  RI0024.4_B0002

      * Modified by      : Sachin P.
      * Modified for      : Mantis Id:11695
                            Mantis Id:11872
      * Modified Reason   : 11695 :-Reversal Fee details(FeePlan id,FeeCode,Fee amount
                           and FeeAttach Type) are not logged in transactionlog
                           table.
                           11872:-Transactions reversal fee is not debited
      * Modified Date     : 01.08.2013
      * Reviewer          : DHIRAJ
      * Reviewed Date     : 19-aug-2013
      * Build Number      : RI0024.4_B0002

      * Modified by       : Deepa T
      * Modified for      : Mantis Id:11872
      * Modified Reason   : 11872:-If the fee attached for the reversal transaction then
                            the response id is displayed as response code
      * Modified Date     : 11.09.2013
      * Reviewer          : dhiraj
      * Reviewed Date     : 11-sep-2013
      * Build Number      : RI0024.4_B0009

      * Modified By      : Anil Kumar
      * Modified Date    : 16-SEP-2013
      * Modified Reason  : To Update The Inventory Card Current Stock
      * Modified for     : DFCHOST-345
      * Reviewer         : SAGAR
      * Reviewed Date    : 16-SEP-2013
      * Build Number     : RI0024.4_B0015

      * Modified By      : Sai Prasad
      * Modified Date    : 23-SEP-2013
      * Modified Reason  : To Cover DFCHOST 345 Review comments
      * Modified for     : DFCHOST-345 (Review)
      * Reviewer         : Dhiraj
      * Reviewed Date    : 23-SEP-2013
      * Build Number     : RI0024.4_B0018

      * Modified By      : Anil Kumar
      * Modified Date    : 24-Oct-13
      * Modified Reason  : JH-8(Additional Changes)
      * Reviewer         : Dhiraj
      * Reviewed Date    : 25-Oct-2013
      * Build Number     : RI0024.6_B0003

      * Modified by      : SUVIN S
      * Modified for      : mantis id:0012841
      * Modified Reason   : 0012841: DEFECT:CMS:INCOMM:CR/DR flag of MMPOS card topup reversal transaction is displayed as incorrect
      * Modified Date     : 28.10.13
      * Reviewer          : Dhiraj
      * Reviewed Date     : 28.10.13
      * Build Number      : RI0024.6_B0004

      * Modified By      : SIVA KUMAR ARCOT
      * Modified Date    : 21-Nov-13
      * Modified Reason  : 12933 (Location ID value not gets its entry in Store ID field CS Desktop App )
      * Reviewer         : Dhiraj
      * Reviewed Date    : 05/DEC/2013
      * Build Number     : RI0027_B0001

      * Modified by      : SUVIN S
      * Modified for      : mantis id:0012841
      * Modified Reason   : 0012841: DEFECT:CMS:INCOMM:Transactionlog CR/DR flag of MMPOS card topup reversal and card deactivation transaction were displayed as incorrect
      * Modified Date     : 21.11.13
      * Reviewer          : Dhiraj
      * Reviewed Date     : 21.11.13
      * Build Number      : RI0027_B0002

       * Modified by       : Abdul Hameed M.A
     * Modified for      : Mantis ID 13893
     * Modified Reason   : Added card number for duplicate RRN check
     * Modified Date     : 06-Mar-2014
     * Reviewer          : Dhiraj
     * Reviewed Date     : 10-Mar-2014
     * Build Number      : RI0027.2_B0002

     * Modified By      :  Mageshkumar S
     * Modified For     :  FWR-48
     * Modified Date    :  25-July-2014
     * Modified Reason  :  GL Mapping Removal Changes.
     * Reviewer         :  SPankaj
     * Build Number     :  RI0027.3.1_B0001

     * Modified By      :  Ramesh A
     * Modified For     :  Defect id :15713
     * Modified Date    :  26-AUG-2014
     * Reviewer         :  Spankaj
     * Build Number     :  RI0027.3.1_B0006

     * Modified By      :  Ramesh A
     * Modified For     :  Defect id :15713
     * Modified Date    :  27-AUG-2014
     * Reviewer         :  Spankaj
     * Build Number     :  RI0027.3.1_B0007

     * Modified By      :  Abdul Hameed M.A
     * Modified For     :  JH-3058
     * Modified Date    :  16-OCT-2014
     * Reviewer         :  spankaj
     * Build Number     :  RI0027.4.1_B0001

     * Modified by      : Pankaj S.
     * Modified for     : Transactionlog Functional Removal
     * Modified Date    : 13-May-2015
     * Reviewer         :  Saravanankumar
     * Build Number     :VMSGPRHOAT_3.0.3_B0001

     * Modified by      : Pankaj S.
     * Modified for     : Performance changes
     * Modified Date    : 04-Aug-2016
     * Reviewer         : Saravanankumar
     * Build Number     : VMSGPRHOAT_4.7

     * Modified by      : Abdul Hameed M.A
     * Modified for     : FSS-4700
     * Modified Date    : 07-Sep-2016
     * Reviewer         : Saravanankumar
     * Build Number     : VMSGPRHOAT_4.9

    * Modified By      : UBAIDUR RAHMAN H
    * Modified Date    : 16-JAN-2018
    * Purpose          : CURRENCY CODE CHANGES FROM INST LEVEL TO BIN LEVEL.
    * Reviewer         : Vini
    * Release Number   : VMSGPRHOST18.1
	
	 * Modified By      : Sreeja D
     * Modified Date    : 25/01/2018
     * Purpose          : VMS-162
     * Reviewer         : SaravanaKumar A/Vini Pushkaran
     * Release Number   : VMSGPRHOST18.01
     
    * Modified By      : UBAIDUR RAHMAN.H
    * Modified Date    : 09-JUL-2019
    * Purpose          : VMS 960/962 - Enhance Website/middleware to 
                                support cardholder data search – phase 2.
    * Reviewer         : Saravana Kumar.A
    * Release Number   : VMSGPRHOST_R18
	
	* Modified By      : Saravana Kumar A
    * Modified Date    : 24-DEC-2021
    * Purpose          : VMS-5378 : Need to update ccm_system_generate_profile flag in Retail / Card stock flow.
    * Reviewer         : Venkat S
    * Release Number   : VMSGPRHOST_R56 Build 3
      *****************************************************************************************************/

  V_ORGNL_DELIVERY_CHANNEL TRANSACTIONLOG.DELIVERY_CHANNEL%TYPE;
  V_ORGNL_RESP_CODE        TRANSACTIONLOG.RESPONSE_CODE%TYPE;
  V_ORGNL_TERMINAL_ID      TRANSACTIONLOG.TERMINAL_ID%TYPE;
  V_ORGNL_TXN_CODE         TRANSACTIONLOG.TXN_CODE%TYPE;
  V_ORGNL_TXN_TYPE         TRANSACTIONLOG.TXN_TYPE%TYPE;
  V_ORGNL_TXN_MODE         TRANSACTIONLOG.TXN_MODE%TYPE;
  V_ORGNL_BUSINESS_DATE    TRANSACTIONLOG.BUSINESS_DATE%TYPE;
  V_ORGNL_BUSINESS_TIME    TRANSACTIONLOG.BUSINESS_TIME%TYPE;
  V_ORGNL_CUSTOMER_CARD_NO TRANSACTIONLOG.CUSTOMER_CARD_NO%TYPE;
  V_ORGNL_TOTAL_AMOUNT     TRANSACTIONLOG.AMOUNT%TYPE;
   
  V_REVERSAL_AMT           CMS_ACCT_MAST.CAM_ACCT_BAL%TYPE;
  V_ORGNL_TXN_FEECODE      CMS_FEE_MAST.CFM_FEE_CODE%TYPE;
  
  V_ORGNL_TXN_FEEATTACHTYPE  TRANSACTIONLOG.FEEATTACHTYPE%TYPE; --Modified by Deepa on sep-17-2012
   
  V_ORGNL_TXN_SERVICETAX_AMT TRANSACTIONLOG.SERVICETAX_AMT%TYPE;
  V_ORGNL_TXN_CESS_AMT       TRANSACTIONLOG.CESS_AMT%TYPE;
  V_ORGNL_TRANSACTION_TYPE   TRANSACTIONLOG.CR_DR_FLAG%TYPE;
  V_ACTUAL_DISPATCHED_AMT    TRANSACTIONLOG.AMOUNT%TYPE;
  V_RESP_CDE                 TRANSACTIONLOG.RESPONSE_ID%TYPE; 
  V_FUNC_CODE                CMS_FUNC_MAST.CFM_FUNC_CODE%TYPE;
  V_DR_CR_FLAG               TRANSACTIONLOG.CR_DR_FLAG%TYPE;
  V_ORGNL_TRANDATE           DATE;
  V_RVSL_TRANDATE            DATE;
  V_ORGNL_TERMID             TRANSACTIONLOG.TERMINAL_ID%TYPE;
  V_ORGNL_MCCCODE            TRANSACTIONLOG.MCCODE%TYPE;
  V_ERRMSG                   TRANSACTIONLOG.ERROR_MSG%TYPE;
  V_ACTUAL_FEECODE           TRANSACTIONLOG.FEECODE%TYPE;
  V_ORGNL_TRANFEE_AMT        TRANSACTIONLOG.TRANFEE_AMT%TYPE;
  V_ORGNL_SERVICETAX_AMT     TRANSACTIONLOG.SERVICETAX_AMT%TYPE;
  V_ORGNL_CESS_AMT           TRANSACTIONLOG.CESS_AMT%TYPE;
   
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
   
  V_CARD_ACCT_NO            CMS_ACCT_MAST.CAM_ACCT_NO%TYPE;
   
  V_HASH_PAN                CMS_APPL_PAN.CAP_PAN_CODE%TYPE;
  V_ENCR_PAN                CMS_APPL_PAN.CAP_PAN_CODE_ENCR%TYPE;
  V_TRAN_AMT                cms_acct_mast.cam_acct_bal%type;
  V_DELCHANNEL_CODE         VARCHAR2(2);
  V_CARD_CURR               cms_transaction_log_dtl.ctd_bill_curr%type;
   
  V_BASE_CURR               CMS_BIN_PARAM.CBP_PARAM_VALUE%TYPE;
  V_CURRCODE                cms_transaction_log_dtl.ctd_txn_curr%type;
  V_ACCT_BALANCE            cms_acct_mast.cam_acct_bal%type;
  V_LEDGER_BALANCE          cms_acct_mast.cam_ledger_bal%type;
  V_TRAN_DESC               CMS_TRANSACTION_MAST.CTM_TRAN_DESC%TYPE;
   
  V_CUST_CODE               CMS_CUST_MAST.CCM_CUST_CODE%TYPE;
  V_ADDR_LINEONE             CMS_CARDPROFILE_HIST.CCP_ADD_ONE%type;
  V_ADDR_LINETWO             CMS_CARDPROFILE_HIST.CCP_ADD_TWO%type;
  V_CITY_NAME                CMS_CARDPROFILE_HIST.CCP_CITY_NAME%type;
  V_PIN_CODE                 CMS_CARDPROFILE_HIST.CCP_PIN_CODE%type;
  V_PHONE_NO                 CMS_CARDPROFILE_HIST.CCP_PHONE_ONE%type;
  V_MOBL_NO                  CMS_CARDPROFILE_HIST.CCP_MOBL_ONE%type;
  V_EMAIL                    CMS_CARDPROFILE_HIST.CCP_EMAIL%type;
  V_STATE_CODE               CMS_CARDPROFILE_HIST.CCP_STATE_CODE%type;
  V_CTNRY_CODE               CMS_CARDPROFILE_HIST.CCP_CNTRY_CODE%type;
  V_SSN                      CMS_CARDPROFILE_HIST.CCP_SSN%type;  
  V_BIRTH_DATE               CMS_CARDPROFILE_HIST.CCP_BIRTH_DATE%type;   
  V_FIRST_NAME               CMS_CARDPROFILE_HIST.CCP_FIRST_NAME%type;
  V_MID_NAME                 CMS_CARDPROFILE_HIST.CCP_MID_NAME%type;
  V_LAST_NAME                CMS_CARDPROFILE_HIST.CCP_LAST_NAME%type;
  V_ORGNL_TXN_BUSINESS_DATE TRANSACTIONLOG.BUSINESS_DATE%TYPE;
  V_ORGNL_TXN_BUSINESS_TIME TRANSACTIONLOG.BUSINESS_TIME%TYPE;
  V_ORGNL_TXN_RRN           TRANSACTIONLOG.RRN%TYPE;
  V_ORGNL_TXN_TERMINALID    TRANSACTIONLOG.TERMINAL_ID%TYPE;
   
  V_PROXUNUMBER             CMS_APPL_PAN.CAP_PROXY_NUMBER%TYPE;
  V_ACCT_NUMBER             CMS_APPL_PAN.CAP_ACCT_NO%TYPE;
  V_RESONCODE               CMS_SPPRT_REASONS.CSR_SPPRT_RSNCODE%TYPE;
  V_REMRK                   CMS_PAN_SPPRT.CPS_FUNC_REMARK%TYPE;
  V_CAP_PROD_CATG           CMS_APPL_PAN.CAP_PROD_CATG%TYPE;
  
  V_TXN_NARRATION           CMS_STATEMENTS_LOG.CSL_TRANS_NARRRATION%TYPE;
  V_FEE_NARRATION           CMS_STATEMENTS_LOG.CSL_TRANS_NARRRATION%TYPE;
  V_APPLPAN_CARDSTAT        TRANSACTIONLOG.CARDSTATUS%TYPE;
  --Added by Deepa for the changes to include Merchant name,city and state in statements log
  V_TXN_MERCHNAME  CMS_STATEMENTS_LOG.CSL_MERCHANT_NAME%TYPE;
  V_FEE_MERCHNAME  CMS_STATEMENTS_LOG.CSL_MERCHANT_NAME%TYPE;
  V_TXN_MERCHCITY  CMS_STATEMENTS_LOG.CSL_MERCHANT_CITY%TYPE;
  V_FEE_MERCHCITY  CMS_STATEMENTS_LOG.CSL_MERCHANT_CITY%TYPE;
  V_TXN_MERCHSTATE CMS_STATEMENTS_LOG.CSL_MERCHANT_STATE%TYPE;
  V_FEE_MERCHSTATE CMS_STATEMENTS_LOG.CSL_MERCHANT_STATE%TYPE;

  V_FEE_PLAN_ID     CMS_CARD_EXCPFEE_HIST.CCE_FEE_PLAN%TYPE; --Added by Ramesh.A on 03/07/2012

  V_CAP_APPL_CODE       CMS_APPL_PAN.CAP_APPL_CODE%TYPE ;-- Added by Besky on 16-nov-12
  V_MERV_COUNT          PLS_INTEGER;        -- Added by Besky on 16-nov-12


  --V_CAP_CUST_CODE CMS_APPL_PAN.CAP_CUST_CODE%TYPE; -- Added for CR-026 on 31-DEC-2012
  V_CAP_ACCT_ID   CMS_APPL_PAN.CAP_ACCT_ID%TYPE;   -- Added for CR-026 on 31-DEC-2012
   
  v_gpr_pan       CMS_APPL_PAN.CAP_PAN_CODE%TYPE;  -- Added for CR-026 on 31-DEC-2012
  v_gpr_chk       VARCHAR2(1);                     -- Added for CR-026 on 31-DEC-2012
  v_cam_type_code   cms_acct_mast.cam_type_code%type; -- added on 17-apr-2013 for defect 10871
  v_timestamp       timestamp;                         -- Added on 17-Apr-2013 for defect 10871

  --SN  Added on 01.08.2013 for 11872
  V_TXN_TYPE  NUMBER(1);
  V_TRAN_DATE DATE;
  V_FEE_PLAN  CMS_FEE_PLAN.CFP_PLAN_ID%TYPE;
  V_FEE_AMT   cms_acct_mast.cam_acct_bal%type;
  --EN  Added on 01.08.2013 for 11872
  V_FEE_CODE           CMS_FEE_MAST.CFM_FEE_CODE%TYPE; --Added on 01.08.2013 for 11695
  V_FEEATTACH_TYPE     TRANSACTIONLOG.FEEATTACHTYPE%TYPE; --Added on 01.08.2013 for 11695

  V_Cmm_Merprodcat_Id Cms_Merinv_Merpan.Cmm_Merprodcat_Id%Type;  --Added for DFCHOST-345

--Added for JH-8(Additional Changes) on 24/10/2013
   V_Loccheck_Flg           cms_prod_cattype.CPC_LOCCHECK_FLAG%Type;
   V_Cmm_Mer_Id        Cms_Merinv_Merpan.Cmm_Mer_Id%Type;
   V_Cmm_Location_Id   Cms_Merinv_Merpan.Cmm_Location_Id%Type;
--End for JH-8(Additional Changes)

   V_HASHKEY_ID                  CMS_TRANSACTION_LOG_DTL.CTD_HASHKEY_ID%type;--Added for 12933
   v_invchk_flag                 cms_prod_cattype.CPC_INVCHECK_FLAG%Type; --Added for  JH-3058
   v_cardactive_dt               cms_appl_pan.cap_active_date%TYPE;
   V_PROFILE_CODE                cms_prod_cattype.cpC_PROFILE_CODE%TYPE;
   V_ENCRYPT_ENABLE              cms_prod_cattype.cpc_encrypt_enable%TYPE;
   v_encr_addr_lineone           cms_addr_mast.CAM_ADD_ONE%type;
   v_encr_addr_linetwo           cms_addr_mast.CAM_ADD_TWO%type;
   v_encr_city                   cms_addr_mast.CAM_CITY_NAME%type;
   v_encr_email                  cms_addr_mast.CAM_EMAIL%type;
   v_encr_phone_no               cms_addr_mast.CAM_PHONE_ONE%type;
   v_encr_mob_one                cms_addr_mast.CAM_MOBL_ONE%type;
   v_encr_zip                    cms_addr_mast.CAM_PIN_CODE%type;
   v_encr_first_name             cms_cust_mast.CCM_FIRST_NAME%type; 
   v_encr_last_name              cms_cust_mast.CCM_LAST_NAME%type;
   v_encr_mid_name               cms_cust_mast.CCM_MID_NAME%type;	
   V_SYSTEM_GENERATED_PROFILE	 cms_cust_mast.CCM_SYSTEM_GENERATED_PROFILE%TYPE;
   
   EXP_RVSL_REJECT_RECORD       EXCEPTION;
   v_Retperiod  date;  --Added for VMS-5739/FSP-991
   v_Retdate  date; --Added for VMS-5739/FSP-991
BEGIN
  P_RESP_CDE := '00';
  P_RESP_MSG := 'OK';
  V_REMRK    := 'CARD ACTIVATION REVERSAL';
  V_TRAN_AMT := 0;
  SAVEPOINT V_SAVEPOINT;
  V_ERRMSG := 'OK'; -- Added for defect 10871 to log error message in successful case in Transactionlog

  v_timestamp := SYSTIMESTAMP; -- Added for defect 10871

 --added for mantis -12933

    BEGIN
           V_HASHKEY_ID := GETHASH (P_DELV_CHNL||P_TXN_CODE||P_CARD_NO||P_RRN||to_char(v_timestamp,'YYYYMMDDHH24MISSFF5'));
       EXCEPTION
        WHEN OTHERS
        THEN
        V_RESP_CDE := '21';
        V_ERRMSG :='Error while converting master data ' || SUBSTR (SQLERRM, 1, 200);
        RAISE EXP_RVSL_REJECT_RECORD;
     END;
  --end for mantid-12933

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

  --Sn get date
  BEGIN

    V_RVSL_TRANDATE := TO_DATE(SUBSTR(TRIM(P_BUSINESS_DATE), 1, 8) || ' ' ||
                         SUBSTR(TRIM(P_BUSINESS_TIME), 1, 8),
                         'yyyymmdd hh24:mi:ss');

     V_TRAN_DATE     := V_RVSL_TRANDATE; --Added on 01.08.2013 for 11872
  EXCEPTION
    WHEN OTHERS THEN
     V_RESP_CDE := '21';
     V_ERRMSG   := 'Problem while converting transaction date ' ||
                SUBSTR(SQLERRM, 1, 200);
     RAISE EXP_RVSL_REJECT_RECORD;
  END;

  --En get date

  --Sn generate auth id
  BEGIN
    -- SELECT TO_CHAR(SYSDATE, 'YYYYMMDD') INTO V_AUTHID_DATE FROM DUAL;

    SELECT LPAD(SEQ_AUTH_ID.NEXTVAL, 6, '0') INTO V_AUTH_ID FROM DUAL;

  EXCEPTION
    WHEN OTHERS THEN
     V_ERRMSG   := 'Error while generating authid ' ||
                SUBSTR(SQLERRM, 1, 300);
     V_RESP_CDE := '21'; -- Server Declined
     RAISE EXP_RVSL_REJECT_RECORD;
  END;

 
-- MODIFIED BY ABDUL HAMEED M.A ON 06-03-2014
 BEGIN
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
    END;
  --En Duplicate RRN Check




--Added for JH-8(Additional Changes) on 24-Oct-13
  Begin
     SELECT  cap_prod_code, cap_card_type,cap_acct_no,         --Added for getting acct no for defect id :15713
             cap_active_date,
             cap_prod_catg, cap_cust_code, cap_proxy_number,
             cap_card_stat, cap_appl_code, cap_acct_id
      INTO v_prod_code,v_card_type,v_acct_number,
             v_cardactive_dt,
             v_cap_prod_catg, v_cust_code, v_proxunumber,
             v_applpan_cardstat, v_cap_appl_code, v_cap_acct_id
      FROM   cms_appl_pan
       where cap_inst_code = p_inst_code
         And Cap_Pan_Code = V_Hash_Pan
         and cap_mbr_numb = p_mbr_numb;
         p_dda_number:=v_acct_number;
      Exception
        When No_Data_Found Then
          V_ERRMSG   := 'Error while Fetching Prod Code and Card type - No Data found' ;
          V_RESP_CDE := '21';
          Raise EXP_RVSL_REJECT_RECORD;
        When Others Then
          V_ERRMSG   := 'Error while Fetching Prod Code and Card type ' ||
                  SUBSTR(SQLERRM, 1, 200);
          V_Resp_Cde := '21';
      Raise EXP_RVSL_REJECT_RECORD;
  End;
  begin
    Select Cpc_Loccheck_Flag,CPC_INVCHECK_FLAG,CPC_PROFILE_CODE, 
             CPC_ENCRYPT_ENABLE --Added for  JH-3058
      into V_Loccheck_Flg,v_invchk_flag,V_PROFILE_CODE,V_ENCRYPT_ENABLE--Added for  JH-3058
      From Cms_Prod_Cattype
      Where Cpc_Prod_Code = V_Prod_Code And
            Cpc_Card_Type = V_Card_Type And
            Cpc_Inst_Code = P_INST_CODE;
      Exception
        When No_Data_Found Then
          V_ERRMSG   := 'Error while Fetching Location Check From ProdCattype - No Data found' ;
          V_RESP_CDE := '21';
          Raise EXP_RVSL_REJECT_RECORD;
        When Others Then
          V_ERRMSG   := 'Error while Fetching Location Check From ProdCattype ' ||
                  SUBSTR(SQLERRM, 1, 200);
          V_RESP_CDE := '21';
          Raise EXP_RVSL_REJECT_RECORD;
  End;
--End for JH-8(Additional Changes)

--Select the Delivery Channel code of MM-POS

  BEGIN

    --IF the DeliveryChannel is MMPOS then the base currency will be the txn curr
    IF P_CURR_CODE IS NULL AND V_DELCHANNEL_CODE = P_DELV_CHNL THEN
     BEGIN
 

         SELECT TRIM(cbp_param_value)
	    INTO v_base_curr
          FROM cms_bin_param
          WHERE cbp_param_name = 'Currency' AND cbp_inst_code= P_INST_CODE
          AND cbp_profile_code = V_PROFILE_CODE;

       IF V_BASE_CURR IS NULL THEN
        V_ERRMSG := 'Base currency cannot be null ';
        RAISE EXP_RVSL_REJECT_RECORD;
       END IF;
     EXCEPTION
       WHEN NO_DATA_FOUND THEN
        V_ERRMSG := 'Base currency is not defined for the bin profile ';
        RAISE EXP_RVSL_REJECT_RECORD;
       WHEN OTHERS THEN
        V_ERRMSG := 'Error while selecting base currency for bin  ' ||
                  SUBSTR(SQLERRM, 1, 200);
        RAISE EXP_RVSL_REJECT_RECORD;
     END;

     V_CURRCODE := V_BASE_CURR;
    ELSE
     V_CURRCODE := P_CURR_CODE;
    END IF;
  END;

  --Sn check msg type
  IF V_DELCHANNEL_CODE <> P_DELV_CHNL AND (P_MSG_TYP NOT IN ('0400', '0410', '0420', '0430') OR
      (P_RVSL_CODE = '00')) THEN
     V_RESP_CDE := '12';
     V_ERRMSG   := 'Not a valid reversal request';
     RAISE EXP_RVSL_REJECT_RECORD;
     
  END IF;

  --En check msg type

  --   Sn Getting the details of Card Activation Txn.Original txn details are not present in request
  BEGIN
    SELECT Z.CCP_BUSINESS_TIME,
         Z.CCP_BUSINESS_DATE,
         Z.CCP_RRN,
         Z.CCP_TERMINAL_ID,
         --SN Added for Performance changes
         Z.CCP_ADD_ONE,
         Z.CCP_ADD_TWO,
         Z.CCP_CITY_NAME,
         Z.CCP_PIN_CODE,
         Z.CCP_PHONE_ONE,
         Z.CCP_MOBL_ONE,
         Z.CCP_EMAIL,
         Z.CCP_STATE_CODE,
         Z.CCP_CNTRY_CODE,
         Z.CCP_SSN,
         Z.CCP_BIRTH_DATE,
         Z.CCP_FIRST_NAME,
         Z.CCP_MID_NAME,
         Z.CCP_LAST_NAME
         --EN Added for Performance changes
     INTO V_ORGNL_TXN_BUSINESS_TIME,
         V_ORGNL_TXN_BUSINESS_DATE,
         V_ORGNL_TXN_RRN,
         V_ORGNL_TXN_TERMINALID,
         --SN Added for Performance changes
         V_ADDR_LINEONE,
         V_ADDR_LINETWO,
         V_CITY_NAME,
         V_PIN_CODE,
         V_PHONE_NO,
         V_MOBL_NO,
         V_EMAIL,
         V_STATE_CODE,
         V_CTNRY_CODE,
         V_SSN,
         V_BIRTH_DATE,
         V_FIRST_NAME,
         V_MID_NAME,
         V_LAST_NAME
         --EN Added for Performance changes
     FROM (SELECT CCP_BUSINESS_TIME,
                CCP_BUSINESS_DATE,
                CCP_RRN,
                CCP_TERMINAL_ID,
                --SN Added for Performance changes
                CCP_ADD_ONE,
                CCP_ADD_TWO,
                CCP_CITY_NAME,
                CCP_PIN_CODE,
                CCP_PHONE_ONE,
                CCP_MOBL_ONE,
                CCP_EMAIL,
                CCP_STATE_CODE,
                CCP_CNTRY_CODE,
                CCP_SSN,
                CCP_BIRTH_DATE,
                CCP_FIRST_NAME,
                CCP_MID_NAME,
                CCP_LAST_NAME
                --EN Added for Performance changes
            FROM CMS_CARDPROFILE_HIST
           WHERE CCP_PAN_CODE = V_HASH_PAN AND CCP_INST_CODE = P_INST_CODE AND
                CCP_MBR_NUMB = P_MBR_NUMB
           ORDER BY CCP_INS_DATE DESC) Z
    WHERE ROWNUM = 1;
  EXCEPTION
    WHEN NO_DATA_FOUND THEN
     V_RESP_CDE := '23';
     V_ERRMSG   := 'No Card Activation has done';
     RAISE EXP_RVSL_REJECT_RECORD;
    WHEN OTHERS THEN
     V_RESP_CDE := '21';
     V_ERRMSG   := 'Cannot get the activation details';
     RAISE EXP_RVSL_REJECT_RECORD;
  END;

  --   Sn Getting the details of Card Activation Txn.

  --Sn check orginal transaction    (-- Amount is missing in reversal request)
  BEGIN
  --Added for VMS-5739/FSP-991
 select (add_months(trunc(sysdate,'MM'),'-'||RETENTION_PERIOD))
       INTO   v_Retperiod 
       FROM DBA_OPERATIONS.ARCHIVE_MGMNT_CTL 
       WHERE  OPERATION_TYPE='ARCHIVE' 
       AND OBJECT_NAME='TRANSACTIONLOG_EBR';
       
       v_Retdate := TO_DATE(SUBSTR(TRIM(V_ORGNL_TXN_BUSINESS_DATE), 1, 8), 'yyyymmdd');


IF (v_Retdate>v_Retperiod)

    THEN

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
         GL_UPD_FLAG
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
         V_GL_UPD_FLAG
     FROM TRANSACTIONLOG
    WHERE RRN = V_ORGNL_TXN_RRN AND
         BUSINESS_DATE = V_ORGNL_TXN_BUSINESS_DATE AND
         BUSINESS_TIME = V_ORGNL_TXN_BUSINESS_TIME AND
         CUSTOMER_CARD_NO = V_HASH_PAN --P_card_no
         AND INSTCODE = P_INST_CODE AND DELIVERY_CHANNEL = P_DELV_CHNL; --Added by ramkumar.Mk on 25 march 2012
         --AND TERMINAL_ID = V_ORGNL_TXN_TERMINALID;    Commented For JH-8(Additional Changes)
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
         FEEATTACHTYPE, -- card level / prod cattype level
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
         GL_UPD_FLAG
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
         V_GL_UPD_FLAG
     FROM VMSCMS_HISTORY.TRANSACTIONLOG_HIST --Added for VMS-5733/FSP-991
    WHERE RRN = V_ORGNL_TXN_RRN AND
         BUSINESS_DATE = V_ORGNL_TXN_BUSINESS_DATE AND
         BUSINESS_TIME = V_ORGNL_TXN_BUSINESS_TIME AND
         CUSTOMER_CARD_NO = V_HASH_PAN --P_card_no
         AND INSTCODE = P_INST_CODE AND DELIVERY_CHANNEL = P_DELV_CHNL; --Added by ramkumar.Mk on 25 march 2012
         --AND TERMINAL_ID = V_ORGNL_TXN_TERMINALID;    Commented For JH-8(Additional Changes)
END IF;		 

    IF V_ORGNL_RESP_CODE <> '00' THEN
     V_RESP_CDE := '23';
     V_ERRMSG   := ' The original transaction was not successful';
     RAISE EXP_RVSL_REJECT_RECORD;
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
     V_RESP_CDE := '21';
     V_ERRMSG   := 'Matching transaction not found';
     RAISE EXP_RVSL_REJECT_RECORD;
    WHEN TOO_MANY_ROWS THEN
     V_RESP_CDE := '21';
     V_ERRMSG   := 'More than one matching record found in the master';
     RAISE EXP_RVSL_REJECT_RECORD;
    WHEN OTHERS THEN
     V_RESP_CDE := '21';
     V_ERRMSG   := 'Error while selecting master data' ||
                SUBSTR(SQLERRM, 1, 200);
     RAISE EXP_RVSL_REJECT_RECORD;
  END;

  --En check orginal transaction

  ---Sn check card number
  --IF v_orgnl_customer_card_no <> P_card_no THEN
  IF V_ORGNL_CUSTOMER_CARD_NO <> V_HASH_PAN THEN
    V_RESP_CDE := '21';
    V_ERRMSG   := 'Customer card number is not matching in reversal and orginal transaction';
    RAISE EXP_RVSL_REJECT_RECORD;
  END IF;

  --En check card number

  --Sn Convert Original Txn date
  BEGIN
    V_ORGNL_TRANDATE := TO_DATE(SUBSTR(TRIM(V_ORGNL_TXN_BUSINESS_DATE),
                                1,
                                8) || ' ' ||
                          SUBSTR(TRIM(V_ORGNL_TXN_BUSINESS_TIME),
                                1,
                                8),
                          'yyyymmdd hh24:mi:ss');
  EXCEPTION
    WHEN OTHERS THEN
     V_RESP_CDE := '21';
     V_ERRMSG   := 'Problem while converting Original transaction date ' ||
                SUBSTR(SQLERRM, 1, 200);
     RAISE EXP_RVSL_REJECT_RECORD;
  END;

  --En Convert Original Txn date

  --Sn Check for the txns using this card after card Activation

 

   IF v_cardactive_dt IS NULL
   THEN
      v_resp_cde := '28';
      v_errmsg :=
         'Card Activation Reversal Cannot be done., Activation Not done for this card';
      RAISE exp_rvsl_reject_record;
   END IF;
  --En Modified for Transactionlog Functional Removal

  --En Check for the txns using this card after card Activation

  --Sn find the converted tran amt
  IF (V_TRAN_AMT >= 0) THEN
    BEGIN
     SP_CONVERT_CURR(P_INST_CODE,
                  V_CURRCODE,
                  P_CARD_NO,
                  V_TRAN_AMT,
                  V_RVSL_TRANDATE,
                  V_TRAN_AMT,
                  V_CARD_CURR,
                  V_ERRMSG,
                  v_prod_code,
                  v_card_type
                  );

     IF V_ERRMSG <> 'OK' THEN
       V_RESP_CDE := '21';
       RAISE EXP_RVSL_REJECT_RECORD;
     END IF;
    EXCEPTION
     WHEN EXP_RVSL_REJECT_RECORD THEN
       RAISE;
     WHEN OTHERS THEN
       V_RESP_CDE := '69'; -- Server Declined -220509
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

  --Sn check amount with orginal transaction
  IF (V_TRAN_AMT IS NULL OR V_TRAN_AMT = 0) THEN
    V_ACTUAL_DISPATCHED_AMT := 0;
  ELSE
    V_ACTUAL_DISPATCHED_AMT := V_TRAN_AMT;
  END IF;

  --En check amount with orginal transaction
  V_REVERSAL_AMT := V_ORGNL_TOTAL_AMOUNT - V_ACTUAL_DISPATCHED_AMT;

  --Sn find the type of orginal txn (credit or debit)
  BEGIN
    SELECT CTM_CREDIT_DEBIT_FLAG, CTM_TRAN_DESC,
            TO_NUMBER(DECODE(CTM_TRAN_TYPE, 'N', '0', 'F', '1')) --Added on 01.08.2013 for 11872
     INTO V_DR_CR_FLAG, V_TRAN_DESC,
          V_TXN_TYPE   --Added on 01.08.2013 for 11872
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
  IF V_DR_CR_FLAG = 'NA' THEN
    V_RESP_CDE := '21';
    V_ERRMSG   := 'Not a valid orginal transaction for reversal';
    RAISE EXP_RVSL_REJECT_RECORD;
  END IF;
-- comented on 28.10.13 for
 

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
    SELECT CAM_ACCT_NO,
          CAM_TYPE_CODE        -- Added on 17-Apr-2013 for defect 10871
          ,cam_acct_bal,cam_ledger_bal
     INTO V_CARD_ACCT_NO,
          v_cam_type_code      -- Added on 17-Apr-2013 for defect 10871
          , V_ACCT_BALANCE, V_LEDGER_BALANCE
     from cms_acct_mast
    where cam_acct_no = v_acct_number   AND
         CAM_INST_CODE = P_INST_CODE
      FOR UPDATE ; --NOWAIT;
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
  IF  V_REVERSAL_AMT <> V_ACCT_BALANCE THEN
    V_RESP_CDE := '263';
    V_ERRMSG   := 'Card successfully loaded and load amount has been redeemed';
    RAISE EXP_RVSL_REJECT_RECORD;
  END IF;
  BEGIN

--Added for VMS-5739/FSP-991
 select (add_months(trunc(sysdate,'MM'),'-'||RETENTION_PERIOD))
       INTO   v_Retperiod 
       FROM DBA_OPERATIONS.ARCHIVE_MGMNT_CTL 
       WHERE  OPERATION_TYPE='ARCHIVE' 
       AND OBJECT_NAME='CMS_STATEMENTS_LOG_EBR';
       
       v_Retdate := TO_DATE(SUBSTR(TRIM(V_ORGNL_BUSINESS_DATE), 1, 8), 'yyyymmdd');


IF (v_Retdate>v_Retperiod)
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
         CSL_RRN = V_ORGNL_TXN_RRN AND
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
     FROM VMSCMS_HISTORY.CMS_STATEMENTS_LOG_HIST --Added for VMS-5733/FSP-991
    WHERE CSL_BUSINESS_DATE = V_ORGNL_BUSINESS_DATE AND
         CSL_BUSINESS_TIME = V_ORGNL_BUSINESS_TIME AND
         CSL_RRN = V_ORGNL_TXN_RRN AND
         CSL_DELIVERY_CHANNEL = V_ORGNL_DELIVERY_CHANNEL AND
         CSL_TXN_CODE = V_ORGNL_TXN_CODE AND
         CSL_PAN_NO = V_ORGNL_CUSTOMER_CARD_NO AND
         CSL_INST_CODE = P_INST_CODE AND TXN_FEE_FLAG = 'N';
END IF;		 

    IF V_ORGNL_TRANFEE_AMT > 0 THEN

     BEGIN
		
--Added for VMS-5739/FSP-991
 select (add_months(trunc(sysdate,'MM'),'-'||RETENTION_PERIOD))
       INTO   v_Retperiod 
       FROM DBA_OPERATIONS.ARCHIVE_MGMNT_CTL 
       WHERE  OPERATION_TYPE='ARCHIVE' 
       AND OBJECT_NAME='CMS_STATEMENTS_LOG_EBR';
       
       v_Retdate := TO_DATE(SUBSTR(TRIM(V_ORGNL_BUSINESS_DATE), 1, 8), 'yyyymmdd');


IF (v_Retdate>v_Retperiod)
    THEN
       SELECT CSL_TRANS_NARRRATION,
            CSL_MERCHANT_NAME,
            CSL_MERCHANT_CITY,
            CSL_MERCHANT_STATE
        INTO V_FEE_NARRATION,
            V_FEE_MERCHNAME,
            V_FEE_MERCHCITY,
            V_FEE_MERCHSTATE --Mofified by Deepa on 09-May-2012 to include Merchant name,city and state in statements log
        FROM CMS_STATEMENTS_LOG
        WHERE CSL_BUSINESS_DATE = V_ORGNL_BUSINESS_DATE AND
            CSL_BUSINESS_TIME = V_ORGNL_BUSINESS_TIME AND
            CSL_RRN = V_ORGNL_TXN_RRN AND
            CSL_DELIVERY_CHANNEL = V_ORGNL_DELIVERY_CHANNEL AND
            CSL_TXN_CODE = V_ORGNL_TXN_CODE AND
            CSL_PAN_NO = V_ORGNL_CUSTOMER_CARD_NO AND
            CSL_INST_CODE = P_INST_CODE AND TXN_FEE_FLAG = 'Y';
ELSE
SELECT CSL_TRANS_NARRRATION,
            CSL_MERCHANT_NAME,
            CSL_MERCHANT_CITY,
            CSL_MERCHANT_STATE
        INTO V_FEE_NARRATION,
            V_FEE_MERCHNAME,
            V_FEE_MERCHCITY,
            V_FEE_MERCHSTATE --Mofified by Deepa on 09-May-2012 to include Merchant name,city and state in statements log
        FROM VMSCMS_HISTORY.CMS_STATEMENTS_LOG_HIST --Added for VMS-5733/FSP-991
        WHERE CSL_BUSINESS_DATE = V_ORGNL_BUSINESS_DATE AND
            CSL_BUSINESS_TIME = V_ORGNL_BUSINESS_TIME AND
            CSL_RRN = V_ORGNL_TXN_RRN AND
            CSL_DELIVERY_CHANNEL = V_ORGNL_DELIVERY_CHANNEL AND
            CSL_TXN_CODE = V_ORGNL_TXN_CODE AND
            CSL_PAN_NO = V_ORGNL_CUSTOMER_CARD_NO AND
            CSL_INST_CODE = P_INST_CODE AND TXN_FEE_FLAG = 'Y';
END IF;			

     EXCEPTION
       WHEN NO_DATA_FOUND THEN
        V_FEE_NARRATION := NULL;
       WHEN OTHERS THEN
        V_FEE_NARRATION := NULL;
     END;
    END IF;
  EXCEPTION
    WHEN NO_DATA_FOUND THEN
     V_TXN_NARRATION := NULL;
    WHEN OTHERS THEN
     V_TXN_NARRATION := NULL;
  END;

  --En find narration

  --Sn reverse the amount
  BEGIN
    SP_REVERSE_CARD_AMOUNT(P_INST_CODE,
                      V_FUNC_CODE,
                      P_RRN,
                      P_DELV_CHNL,
                      V_ORGNL_TXN_TERMINALID,
                      NULL,
                      --P_TXN_CODE, --Commented for Defect id :15713
                      V_ORGNL_TXN_CODE, --Added for Defect id :15713
                      V_RVSL_TRANDATE,
                      P_TXN_MODE,
                      P_CARD_NO,
                      V_REVERSAL_AMT,
                      V_ORGNL_TXN_RRN,
                      V_CARD_ACCT_NO,
                      P_BUSINESS_DATE,
                      P_BUSINESS_TIME,
                      V_AUTH_ID,
                      V_TXN_NARRATION,
                      V_ORGNL_BUSINESS_DATE,
                      V_ORGNL_BUSINESS_TIME,
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
  --Sn reverse the fee
  BEGIN
    SP_REVERSE_FEE_AMOUNT(P_INST_CODE,
                     P_RRN,
                     P_DELV_CHNL,
                     V_ORGNL_TXN_TERMINALID,
                     NULL,
                      --P_TXN_CODE, --Commented for Defect id :15713
                      V_ORGNL_TXN_CODE, --Added for Defect id :15713
                     V_RVSL_TRANDATE,
                     P_TXN_MODE,
                     V_ORGNL_TRANFEE_AMT,
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
                     V_ORGNL_TXN_RRN,
                     V_CARD_ACCT_NO,
                     P_BUSINESS_DATE,
                     P_BUSINESS_TIME,
                     V_AUTH_ID,
                     V_FEE_NARRATION,
                     V_FEE_MERCHNAME, --Added by Deepa on 09-May-2012 to include Merchant name,city and state in statements log
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

  
  END IF;
  --En reverse the GL entries
  --SN Added on 01.08.2013 for 11872
   --Sn reversal Fee Calculation
   V_RESP_CDE := '1';
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
                     V_FEE_CODE,      --Added on 01.08.2013 for 11695
                     V_FEEATTACH_TYPE --Added on 01.08.2013 for 11695
                     );

    IF V_ERRMSG <> 'OK' THEN
     RAISE EXP_RVSL_REJECT_RECORD;
    END IF;
  END;
  --EN reversal Fee Calculation
 --EN Added on 01.08.2013 for 11872



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
        CTD_INST_CODE,
        CTD_CUSTOMER_CARD_NO_ENCR,
        CTD_CUST_ACCT_NUMBER,
        CTD_LOCATION_ID,     -- ADDED FOR 12933
        CTD_HASHKEY_ID    -- ADDED FOR 12933
        )
     VALUES
       (P_DELV_CHNL,
        P_TXN_CODE,
        P_TXN_TYPE,
        P_MSG_TYP,
        P_TXN_MODE,
        P_BUSINESS_DATE,
        P_BUSINESS_TIME,
        V_HASH_PAN,
        V_TRAN_AMT,
        V_CURRCODE,
        V_TRAN_AMT,
        V_REVERSAL_AMT,
        V_CARD_CURR,
        'Y',
        'Successful',
        P_RRN,
        P_INST_CODE,
        V_ENCR_PAN,
        V_ACCT_NUMBER,
        P_TERMINAL_ID,   -- ADDED FOR 12933
        V_HASHKEY_ID     -- ADDED FOR 12933
        );
    END IF;
    --Added the 5 empty values for CMS_TRANSACTION_LOG_DTL in cms
  EXCEPTION
    WHEN OTHERS THEN
     V_ERRMSG   := 'Problem while inserting data in to CMS_TRANSACTION_LOG_DTL ' ||
                SUBSTR(SQLERRM, 1, 300);
     V_RESP_CDE := '21';
     RAISE EXP_RVSL_REJECT_RECORD;
  END;

  --En create a entry for successful


       -------------------------------------
       --SN:Added for CR-026 on 31-DEC-2012
       -------------------------------------
 

      Begin

          select cap_pan_code
          into   v_gpr_pan
          from   cms_appl_pan
          where  cap_inst_code = p_inst_code
          and    cap_cust_code = v_cust_code--v_cap_cust_code
          and    cap_acct_id   = v_cap_acct_id
          and    cap_startercard_flag = 'N';

          v_gpr_chk := 'Y';

      Exception when no_data_found
      then

         v_gpr_chk := 'N';

      when others
      then

         V_ERRMSG   := 'Problem while fetching gpr card ' ||SUBSTR(SQLERRM, 1, 100);
         V_RESP_CDE := '21';
         RAISE EXP_RVSL_REJECT_RECORD;

      End;

  -------------------------------------
  --EN:Added for CR-026 on 31-DEC-2012
  -------------------------------------




  BEGIN

     if v_gpr_chk = 'N' --If condition Added on 31-Dec-2012 for CR-026
     then

         Begin

            UPDATE CMS_APPL_PAN
              SET CAP_CARD_STAT       = 0,
                 CAP_FIRSTTIME_TOPUP = 'N',
                 CAP_PIN_OFF         = '',
                 CAP_PIN_FLAG        = 'Y', --T.Narayanan added pin offset updation as null for reverting the SSN pin changes on 08/10/2012
                 cap_active_date = NULL
            WHERE CAP_INST_CODE = P_INST_CODE
            AND CAP_PAN_CODE = V_HASH_PAN;

            if sql%rowcount = 0
            then

                 V_ERRMSG   := 'Starer card not updated to inactive status';
                 V_RESP_CDE := '21';
                 RAISE EXP_RVSL_REJECT_RECORD;

            end if;

          exception when  EXP_RVSL_REJECT_RECORD
          then
              raise;

          when others
          then

             V_ERRMSG   := 'Problem while updating starter card to inactive '||substr(sqlerrm,1,100);
             V_RESP_CDE := '21';
             RAISE EXP_RVSL_REJECT_RECORD;

         End;

     elsif v_gpr_chk ='Y' --If condition Added on 31-Dec-2012 for CR-026
     then

          Begin

            UPDATE CMS_APPL_PAN
            SET CAP_CARD_STAT       = 9
            WHERE CAP_INST_CODE     = P_INST_CODE
            AND CAP_PAN_CODE        = V_HASH_PAN;

            if sql%rowcount = 0
            then

                 V_ERRMSG   := 'Starer card not updated to close status';
                 V_RESP_CDE := '21';
                 RAISE EXP_RVSL_REJECT_RECORD;

            end if;

          exception when  EXP_RVSL_REJECT_RECORD
          then
              raise;

          when others
          then

             V_ERRMSG   := 'Problem while updating starter card '||substr(sqlerrm,1,100);
             V_RESP_CDE := '21';
             RAISE EXP_RVSL_REJECT_RECORD;

          End;

          Begin

            UPDATE CMS_APPL_PAN
            SET CAP_CARD_STAT       = 9
            WHERE CAP_INST_CODE     = P_INST_CODE
            AND CAP_PAN_CODE        = v_gpr_pan;

            if sql%rowcount = 0
            then

                 V_ERRMSG   := 'GPR card not updated to close status';
                 V_RESP_CDE := '21';
                 RAISE EXP_RVSL_REJECT_RECORD;

            end if;

          exception when  EXP_RVSL_REJECT_RECORD
          then
              raise;

          when others
          then

             V_ERRMSG   := 'Problem while updating GPR card '||substr(sqlerrm,1,100);
             V_RESP_CDE := '21';
             RAISE EXP_RVSL_REJECT_RECORD;

          End;

     end if;

--Added for DFCHOST-345
  If V_Errmsg = 'OK' And V_Gpr_Chk = 'N' THEN
    if V_Loccheck_Flg = 'Y' Then  --Added for JH-8(Additional Changes)
    BEGIN
     SELECT  CMM_MERPRODCAT_ID
       INTO
           V_Cmm_Merprodcat_Id
       From Cms_Merinv_Merpan
      Where Cmm_Pan_Code = V_Hash_Pan And
            Cmm_Inst_Code = P_INST_CODE And
            CMM_LOCATION_ID = V_ORGNL_TXN_TERMINALID;
    EXCEPTION
     When No_Data_Found Then
       V_ERRMSG   := 'Error while Fetching ProdCat From MERPAN 1' ; --Modified for DFHOST (Review)
                  --Substr(Sqlerrm, 1, 200);
       V_RESP_CDE := '21';
       Raise EXP_RVSL_REJECT_RECORD;
     When Others Then
       V_ERRMSG   := 'Error while Fetching Pan From MERPAN ' ||
                  Substr(Sqlerrm, 1, 200);
       V_RESP_CDE := '21';
       Raise EXP_RVSL_REJECT_RECORD;
    End;

      BEGIN
       UPDATE CMS_MERINV_MERPAN
         SET CMM_ACTIVATION_FLAG = 'M'
        WHERE CMM_PAN_CODE = V_HASH_PAN and
         Cmm_Inst_Code = P_INST_CODE And
         CMM_LOCATION_ID = V_ORGNL_TXN_TERMINALID;

       IF SQL%ROWCOUNT = 0 THEN
        V_ERRMSG   := 'Error while Updating Card Activation Flag in MERPAN 1' ; --Modified for DFHOST (Review)
                    --SUBSTR(SQLERRM, 1, 200);
        V_RESP_CDE := '21';
        RAISE EXP_RVSL_REJECT_RECORD;
       END IF;
     EXCEPTION
     WHEN EXP_RVSL_REJECT_RECORD THEN --ADDed for DFHOST (Review)
     RAISE EXP_RVSL_REJECT_RECORD;
       WHEN OTHERS THEN
        V_ERRMSG   := 'Error while Updating Card Activation Flag in MERPAN ' ||
                    SUBSTR(SQLERRM, 1, 200);
        V_RESP_CDE := '21';
        RAISE EXP_RVSL_REJECT_RECORD;
     END;

  BEGIN
       Update Cms_Merinv_Stock
         SET CMS_CURR_STOCK = (CMS_CURR_STOCK + 1)
        WHERE CMS_INST_CODE = P_INST_CODE AND
            CMS_MERPRODCAT_ID = V_CMM_MERPRODCAT_ID AND
            CMS_LOCATION_ID = V_ORGNL_TXN_TERMINALID;

       IF SQL%ROWCOUNT = 0 THEN
        V_ERRMSG   := 'Error while Updating current stock in MERSTOCK ' ; --Modified for DFHOST (Review)
                  --  Substr(Sqlerrm, 1, 200);
        V_RESP_CDE := '21';
        RAISE EXP_RVSL_REJECT_RECORD;
       END IF;
     EXCEPTION
      WHEN EXP_RVSL_REJECT_RECORD THEN --ADDed for DFHOST (Review)
     RAISE EXP_RVSL_REJECT_RECORD;
       When Others Then
        V_ERRMSG   := 'Error while Updating current stock in MERSTOCK' ||
                    Substr(Sqlerrm, 1, 200);
        V_RESP_CDE := '21';
        RAISE EXP_RVSL_REJECT_RECORD;
  End;
--Added for JH-8(Additional Changes)
  --else
   Elsif v_invchk_flag = 'Y' THEN --Modified for  JH-3058
     BEGIN
     SELECT  CMM_MER_ID, CMM_LOCATION_ID, CMM_MERPRODCAT_ID
       INTO V_CMM_MER_ID,
           V_CMM_LOCATION_ID,
           V_CMM_MERPRODCAT_ID
       FROM CMS_MERINV_MERPAN
      WHERE CMM_PAN_CODE = V_HASH_PAN and cmm_inst_code = p_inst_code;
    EXCEPTION
     When No_Data_Found Then
       V_ERRMSG   := 'Error while Fetching Pan From MERPAN  - No Data found' ;
       V_RESP_CDE := '21';
       Raise EXP_RVSL_REJECT_RECORD;
     WHEN OTHERS THEN
       V_ERRMSG   := 'Error while Fetching Pan From MERPAN ' ||
                  SUBSTR(SQLERRM, 1, 200);
       V_RESP_CDE := '21';
       Raise EXP_RVSL_REJECT_RECORD;
    End;

    BEGIN
       UPDATE CMS_MERINV_MERPAN
         SET CMM_ACTIVATION_FLAG = 'M'
        WHERE CMM_PAN_CODE = V_HASH_PAN and cmm_inst_code = p_inst_code;

       IF SQL%ROWCOUNT = 0 THEN
        V_ERRMSG   := 'Error while Updating Card Activation Flag in MERPAN 1' ;
        V_RESP_CDE := '21';
        RAISE EXP_RVSL_REJECT_RECORD;
       END IF;
     EXCEPTION
       WHEN OTHERS THEN
        V_ERRMSG   := 'Error while Updating Card Activation Flag in MERPAN 2' ||
                    SUBSTR(SQLERRM, 1, 200);
        V_RESP_CDE := '21';
        RAISE EXP_RVSL_REJECT_RECORD;
     END;

     BEGIN
       UPDATE CMS_MERINV_STOCK
         SET CMS_CURR_STOCK = (CMS_CURR_STOCK + 1)
        WHERE CMS_INST_CODE = p_inst_code AND
            CMS_MERPRODCAT_ID = V_CMM_MERPRODCAT_ID AND
            CMS_LOCATION_ID = V_CMM_LOCATION_ID;

       IF SQL%ROWCOUNT = 0 THEN
        V_ERRMSG   := 'Error while Updating current stock in CMS_MERINV_STOCK 1 ';
        V_RESP_CDE := '21';
        RAISE EXP_RVSL_REJECT_RECORD;
       END IF;
     EXCEPTION
       WHEN OTHERS THEN
        V_ERRMSG   := 'Error while Updating current stock in CMS_MERINV_STOCK 2' ||
                    SUBSTR(SQLERRM, 1, 200);
        V_RESP_CDE := '21';
        Raise Exp_Rvsl_Reject_Record;
     END;
  end if;
--End for JH-8(Additional Changes)
 End If;
--End for DFCHOST-345
    --SN Commented for performance changes
   /* SELECT Z.CCP_ADD_ONE,
         Z.CCP_ADD_TWO,
         Z.CCP_CITY_NAME,
         Z.CCP_PIN_CODE,
         Z.CCP_PHONE_ONE,
         Z.CCP_MOBL_ONE,
         Z.CCP_EMAIL,
         Z.CCP_STATE_CODE,
         Z.CCP_CNTRY_CODE,
         Z.CCP_SSN,
         Z.CCP_BIRTH_DATE,
         Z.CCP_FIRST_NAME,
         Z.CCP_MID_NAME,
         Z.CCP_LAST_NAME
     INTO V_ADDR_LINEONE,
         V_ADDR_LINETWO,
         V_CITY_NAME,
         V_PIN_CODE,
         V_PHONE_NO,
         V_MOBL_NO,
         V_EMAIL,
         V_STATE_CODE,
         V_CTNRY_CODE,
         V_SSN,
         V_BIRTH_DATE,
         V_FIRST_NAME,
         V_MID_NAME,
         V_LAST_NAME
     FROM (SELECT CCP_ADD_ONE,
                CCP_ADD_TWO,
                CCP_CITY_NAME,
                CCP_PIN_CODE,
                CCP_PHONE_ONE,
                CCP_MOBL_ONE,
                CCP_EMAIL,
                CCP_STATE_CODE,
                CCP_CNTRY_CODE,
                CCP_SSN,
                CCP_BIRTH_DATE,
                CCP_FIRST_NAME,
                CCP_MID_NAME,
                CCP_LAST_NAME
            FROM CMS_CARDPROFILE_HIST
           WHERE ROWNUM = 1 AND CCP_PAN_CODE = V_HASH_PAN AND
                CCP_INST_CODE = P_INST_CODE AND CCP_MBR_NUMB = P_MBR_NUMB
           ORDER BY CCP_INS_DATE DESC) Z;*/
    --EN Commented for performance changes
--	IF V_ENCRYPT_ENABLE = 'Y' THEN
--    v_encr_addr_lineone := fn_emaps_main(V_ADDR_LINEONE);
--		v_encr_addr_linetwo := fn_emaps_main(V_ADDR_LINETWO);
--		v_encr_city         := fn_emaps_main(V_CITY_NAME);
--		v_encr_zip          := fn_emaps_main(V_PIN_CODE);
--		v_encr_phone_no     := fn_emaps_main(V_PHONE_NO);
--		v_encr_mob_one      := fn_emaps_main(V_MOBL_NO);
--		v_encr_email        := fn_emaps_main(V_EMAIL);
--		v_encr_first_name   := fn_emaps_main(V_FIRST_NAME);
--		v_encr_last_name    := fn_emaps_main(V_LAST_NAME);
--		v_encr_mid_name     := fn_emaps_main(V_MID_NAME);
--  ELSE
--     v_encr_addr_lineone := V_ADDR_LINEONE;
--		v_encr_addr_linetwo := V_ADDR_LINETWO;
--		v_encr_city         := V_CITY_NAME;
--		v_encr_zip          := V_PIN_CODE;
--		v_encr_phone_no     := V_PHONE_NO;
--		v_encr_mob_one      := V_MOBL_NO;
--		v_encr_email        := V_EMAIL;
--		v_encr_first_name   := V_FIRST_NAME;
--		v_encr_last_name    := V_LAST_NAME;
--		v_encr_mid_name     := V_MID_NAME;
--     END IF;
	

    UPDATE CMS_ADDR_MAST
      SET CAM_ADD_ONE   = V_ADDR_LINEONE,
         CAM_ADD_TWO    = V_ADDR_LINETWO,
         CAM_CITY_NAME  = V_CITY_NAME,
         CAM_PIN_CODE   = V_PIN_CODE,
         CAM_PHONE_ONE  = V_PHONE_NO,
         CAM_MOBL_ONE   = V_MOBL_NO,
         CAM_EMAIL      = V_EMAIL,
         CAM_STATE_CODE = V_STATE_CODE,
         CAM_CNTRY_CODE = V_CTNRY_CODE,
		     CAM_ADD_ONE_ENCR = decode(V_ENCRYPT_ENABLE,'Y',V_ADDR_LINEONE,fn_emaps_main(V_ADDR_LINEONE)),
         CAM_ADD_TWO_ENCR =  decode(V_ENCRYPT_ENABLE,'Y',V_ADDR_LINETWO,fn_emaps_main(V_ADDR_LINETWO)),
         CAM_CITY_NAME_ENCR =  decode(V_ENCRYPT_ENABLE,'Y',V_CITY_NAME,fn_emaps_main(V_CITY_NAME)),
         CAM_PIN_CODE_ENCR =  decode(V_ENCRYPT_ENABLE,'Y',V_PIN_CODE,fn_emaps_main(V_PIN_CODE)),
         CAM_EMAIL_ENCR =  decode(V_ENCRYPT_ENABLE,'Y',V_EMAIL,fn_emaps_main(V_EMAIL))
    WHERE CAM_CUST_CODE = V_CUST_CODE AND CAM_INST_CODE = P_INST_CODE AND
         CAM_ADDR_FLAG = 'P';
		
	IF FN_DMAPS_MAIN(V_ADDR_LINEONE) <> '*' THEN
		V_SYSTEM_GENERATED_PROFILE := 'N';
	ELSE
		V_SYSTEM_GENERATED_PROFILE := 'Y';
	END IF;

		 
		 	  ---- Added for Performance issue
    
	--- DELETE from CMS_ADDR_MAST   WHERE CAM_CUST_CODE = V_CUST_CODE
    --- AND CAM_INST_CODE = P_INST_CODE
    --- AND CAM_ADDR_FLAG = 'O'; -- Added by Magesh on 26-Apr-2013 for DFCHOST-310 changes
	

	
				UPDATE CMS_ADDR_MAST 
			SET 
				  CAM_CUST_CODE = NULL,
				  CAM_ADD_TWO = NULL,
				  CAM_ADD_THREE = NULL,
				  CAM_PIN_CODE = NULL,
				  CAM_PHONE_ONE = NULL,
				  CAM_PHONE_TWO = NULL,
				  CAM_MOBL_ONE = NULL,
				  CAM_EMAIL = NULL,
				  CAM_FAX_ONE = NULL,
				  CAM_STATE_CODE = NULL,
				  CAM_STATE_SWITCH = NULL,
				  CAM_ADD_ONE_ENCR = NULL,
				  CAM_ADD_TWO_ENCR = NULL,
				  CAM_CITY_NAME_ENCR = NULL,
				  CAM_PIN_CODE_ENCR = NULL,
				  CAM_EMAIL_ENCR = NULL 
			WHERE CAM_CUST_CODE = V_CUST_CODE
			AND CAM_INST_CODE = P_INST_CODE
			AND CAM_ADDR_FLAG = 'O';
	

    UPDATE CMS_CUST_MAST
      SET CCM_SSN        = V_SSN,
         CCM_BIRTH_DATE = V_BIRTH_DATE,
         CCM_FIRST_NAME = V_FIRST_NAME,
         CCM_MID_NAME   = V_MID_NAME,
         CCM_LAST_NAME  = V_LAST_NAME,
		 CCM_FIRST_NAME_ENCR = decode(V_ENCRYPT_ENABLE,'Y',V_FIRST_NAME,fn_emaps_main(V_FIRST_NAME)),
         CCM_LAST_NAME_ENCR  = decode(V_ENCRYPT_ENABLE,'Y',V_LAST_NAME,fn_emaps_main(V_LAST_NAME)),
		 CCM_SYSTEM_GENERATED_PROFILE = V_SYSTEM_GENERATED_PROFILE
    WHERE CCM_CUST_CODE = V_CUST_CODE AND CCM_INST_CODE = P_INST_CODE;

  EXCEPTION WHEN EXP_RVSL_REJECT_RECORD -- Added by sagar on 31-dec-2012
  THEN
       RAISE;

  WHEN OTHERS THEN
     V_ERRMSG   := 'Customer details are not reversed' || V_RESP_CDE ||
                SUBSTR(SQLERRM, 1, 300);
     V_RESP_CDE := '21';
     RAISE EXP_RVSL_REJECT_RECORD;
  END;

  BEGIN   /*Added by Besky on 16-nov-12*/

    SELECT COUNT(*)
    INTO V_MERV_COUNT
    FROM CMS_MERINV_MERPAN
    WHERE CMM_INST_CODE=P_INST_CODE  AND CMM_APPL_CODE=V_CAP_APPL_CODE
    AND CMM_PAN_CODE=V_HASH_PAN;

    IF V_MERV_COUNT =1 THEN

       BEGIN

         UPDATE CMS_CAF_INFO_ENTRY SET CCI_KYC_FLAG='N'
         WHERE  CCI_APPL_CODE=to_char(V_CAP_APPL_CODE) --changed from number to varchar
         AND CCI_INST_CODE=P_INST_CODE;

         update cms_cust_mast set ccm_kyc_flag='N'      --Added by Besky on 09/01/2013 to update the KYC flag in CMS_CUST_MAST table for FSS-9957.
         WHERE CCM_CUST_CODE=v_cust_code --V_CAP_CUST_CODE
         AND CCM_INST_CODE=P_INST_CODE;
       END ;

    END IF;

   EXCEPTION
    WHEN OTHERS THEN
     V_RESP_CDE := '09';
     V_ERRMSG   := 'ERROR WHILE UPDATING CMS_CAF_INFO_ENTRY' || '--' || SUBSTR(SQLERRM, 1, 200);
     RAISE EXP_RVSL_REJECT_RECORD;

  END ;

  --Sn Selecting Reason code for Initial Load
  BEGIN
    SELECT CSR_SPPRT_RSNCODE
     INTO V_RESONCODE
     FROM CMS_SPPRT_REASONS
    WHERE CSR_INST_CODE = P_INST_CODE AND CSR_SPPRT_KEY = 'INILOAD';

  EXCEPTION
    WHEN NO_DATA_FOUND THEN
     V_RESP_CDE := '21';
     V_ERRMSG   := 'Initial load reason code is present in master';
     RAISE EXP_RVSL_REJECT_RECORD;
    WHEN OTHERS THEN
     V_RESP_CDE := '21';
     V_ERRMSG   := 'Error while selecting reason code from master' ||
                SUBSTR(SQLERRM, 1, 200);
     RAISE EXP_RVSL_REJECT_RECORD;
  END;

  --Sn create a record in pan spprt
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
     (P_INST_CODE, --P_acctno
      V_HASH_PAN,
      P_MBR_NUMB,
      V_CAP_PROD_CATG,
      'INLOAD',
      V_RESONCODE,
      V_REMRK,
      '1',
      '1',
      0,
      V_ENCR_PAN);
  EXCEPTION
    WHEN OTHERS THEN
     V_ERRMSG := 'Error while inserting records into card support master' ||
               SUBSTR(SQLERRM, 1, 200);
     RAISE EXP_RVSL_REJECT_RECORD;
  END;
  --En create a record in pan spprt

  --Sn generate response code
  V_RESP_CDE := '1';

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

  --v_timestamp := SYSTIMESTAMP; -- Added for defect 10871
  --Added for getting acct no for defect id :15713
   --Sn find prod code and card type and available balance for the card number
     BEGIN

       --Updated by Ramesh.A on 03/07/2012
       SELECT CAM_ACCT_BAL, CAM_LEDGER_BAL
        INTO V_ACCT_BALANCE, V_LEDGER_BALANCE
        FROM CMS_ACCT_MAST
        WHERE CAM_ACCT_NO = P_DDA_NUMBER AND CAM_INST_CODE = P_INST_CODE
         FOR UPDATE NOWAIT;

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
      CURRENCYCODE,
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
      INSTCODE,
      FEECODE,
      FEEATTACHTYPE,
      TRAN_REVERSE_FLAG,
      CUSTOMER_CARD_NO_ENCR,
      TOPUP_CARD_NO_ENCR,
      PROXY_NUMBER,
      REVERSAL_CODE,
      CUSTOMER_ACCT_NO,
      ACCT_BALANCE,
      LEDGER_BALANCE,
      RESPONSE_ID,
      CARDSTATUS, --Added cardstatus insert in transactionlog by srinivasu.k
      ACCT_TYPE,        -- Added on 17-Apr-2013 for defect 10871
      TIME_STAMP,       -- Added on 17-Apr-2013 for defect 10871
      CR_DR_FLAG,        -- Added on 17-Apr-2013 for defect 10871
      error_msg,         -- Added on 17-Apr-2013 for defect 10871,
      STORE_ID,  --Added by Pankaj S. for Mantis id-11839
      --SN Added on 01.08.2013 for 11695
      FEE_PLAN,
      TRANFEE_AMT
     --EN Added on 01.08.2013 for 11695
      )
    VALUES
     (P_MSG_TYP,
      P_RRN,
      P_DELV_CHNL,
      P_TERMINAL_ID,
      V_RVSL_TRANDATE,
      P_TXN_CODE,
      P_TXN_TYPE,
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
      TRIM(TO_CHAR(nvl(V_REVERSAL_AMT,0), '99999999999999990.99')), -- NVL added for defect 10871
      NULL,
      NULL,
      V_CURR_CODE,
      V_PROD_CODE,
      V_CARD_TYPE,
      '0.00',        -- Changed from 0 to 0.00 on 17-apr-2013 for defect 10871
      NULL,
      NULL,
      V_AUTH_ID,
      V_TRAN_DESC,
      TRIM(TO_CHAR(nvl(V_REVERSAL_AMT,0), '99999999999999990.99')), -- NVL added for defect 10871
      '0.00',  -- NULL replaced by 0.00 , on 17-Apr-2013 for defect 10871
      '0.00', -- Partial amount (will be given for partial txn) -- NULL replaced by 0.00 , on 17-Apr-2013 for defect 10871
      NULL,
      NULL,
      NULL,
      NULL,
      NULL,
      'Y',
      P_INST_CODE,
      --NULL,
      V_FEE_CODE, --Added on 01.08.2013 for 11695
      --NULL,
      V_FEEATTACH_TYPE, --Added on 01.08.2013 for 11695
      'N',
      V_ENCR_PAN,
      NULL,
      V_PROXUNUMBER,
      P_RVSL_CODE,
      V_ACCT_NUMBER,
      TRIM(TO_CHAR(nvl(V_ACCT_BALANCE,0), '99999999999999990.99')),     -- to_char(nvl)) added on 17-Apr-2013 for defect 10871
      TRIM(TO_CHAR(nvl(V_LEDGER_BALANCE,0), '99999999999999990.99')),   -- to_char(nvl)) added on 17-Apr-2013 for defect 10871
      V_RESP_CDE,
      V_APPLPAN_CARDSTAT, --Added cardstatus insert in transactionlog by srinivasu.k
      v_cam_type_code,   -- Added on 17-Apr-2013 for defect 10871
      v_timestamp,       -- Added on 17-Apr-2013 for defect 10871
     -- V_DR_CR_FLAG,      -- Added on 17-Apr-2013 for defect 10871--Commented and modified on 25.07.2013 for 11693
      decode(P_DELV_CHNL,'04',v_dr_cr_flag,decode(v_dr_cr_flag,'CR','DR','DR','CR',v_dr_cr_flag)),--modified for mantis id 0012841: DEFECT:CMS:INCOMM:Transactionlog CR/DR flag of MMPOS
      --card topup reversal and card deactivation transaction were displayed as incorrect
      v_ERRMSG ,         -- Added on 17-Apr-2013 for defect 10871
      NULL, --MODIFIED FOR 12933 --Added by Pankaj S. for Mantis id-11839
      --SN Added on 01.08.2013 for 11695
      V_FEE_PLAN,
      V_FEE_AMT
      --EN Added on 01.08.2013 for 11695
      );

    --Sn update reverse flag
    BEGIN
	--Added for VMS-5739/FSP-991
 select (add_months(trunc(sysdate,'MM'),'-'||RETENTION_PERIOD))
       INTO   v_Retperiod 
       FROM DBA_OPERATIONS.ARCHIVE_MGMNT_CTL 
       WHERE  OPERATION_TYPE='ARCHIVE' 
       AND OBJECT_NAME='TRANSACTIONLOG_EBR';
       
       v_Retdate := TO_DATE(SUBSTR(TRIM(V_ORGNL_TXN_BUSINESS_DATE), 1, 8), 'yyyymmdd');


IF (v_Retdate>v_Retperiod)
    THEN
     UPDATE TRANSACTIONLOG
        SET TRAN_REVERSE_FLAG = 'Y'
      WHERE RRN = V_ORGNL_TXN_RRN AND
           BUSINESS_DATE = V_ORGNL_TXN_BUSINESS_DATE AND
           BUSINESS_TIME = V_ORGNL_TXN_BUSINESS_TIME AND
           CUSTOMER_CARD_NO = V_HASH_PAN --P_card_no;
           AND INSTCODE = P_INST_CODE;
           --And TERMINAL_ID = V_ORGNL_TXN_TERMINALID; Commented for JH-8(Additional Changes)
ELSE
		UPDATE VMSCMS_HISTORY.TRANSACTIONLOG_HIST --Added for VMS-5733/FSP-991
        SET TRAN_REVERSE_FLAG = 'Y'
      WHERE RRN = V_ORGNL_TXN_RRN AND
           BUSINESS_DATE = V_ORGNL_TXN_BUSINESS_DATE AND
           BUSINESS_TIME = V_ORGNL_TXN_BUSINESS_TIME AND
           CUSTOMER_CARD_NO = V_HASH_PAN --P_card_no;
           AND INSTCODE = P_INST_CODE;
           --And TERMINAL_ID = V_ORGNL_TXN_TERMINALID; Commented for JH-8(Additional Changes)
END IF;		   

     IF SQL%ROWCOUNT = 0 THEN
       V_RESP_CDE := '21';
       V_ERRMSG   := 'Reverse flag is not updated ';
       RAISE EXP_RVSL_REJECT_RECORD;
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


   ------------------------------------------------------
      --SN:updating latest timestamp value for defect 10871
      ------------------------------------------------------

        Begin
		--Added for VMS-5739/FSP-991
 select (add_months(trunc(sysdate,'MM'),'-'||RETENTION_PERIOD))
       INTO   v_Retperiod 
       FROM DBA_OPERATIONS.ARCHIVE_MGMNT_CTL 
       WHERE  OPERATION_TYPE='ARCHIVE' 
       AND OBJECT_NAME='CMS_STATEMENTS_LOG_EBR';
       
       v_Retdate := TO_DATE(SUBSTR(TRIM(P_BUSINESS_DATE), 1, 8), 'yyyymmdd');


IF (v_Retdate>v_Retperiod)
    THEN
          update cms_statements_log
          set csl_time_stamp = v_timestamp
          where csl_pan_no = v_hash_pan
          and   csl_rrn = p_rrn
          and   csl_delivery_channel=P_DELV_CHNL
          and   csl_txn_code = p_txn_code
          and   csl_business_date = P_BUSINESS_DATE
          and   csl_business_time = P_BUSINESS_TIME;
ELSE
		update VMSCMS_HISTORY.CMS_STATEMENTS_LOG_HIST --Added for VMS-5733/FSP-991
          set csl_time_stamp = v_timestamp
          where csl_pan_no = v_hash_pan
          and   csl_rrn = p_rrn
          and   csl_delivery_channel=P_DELV_CHNL
          and   csl_txn_code = p_txn_code
          and   csl_business_date = P_BUSINESS_DATE
          and   csl_business_time = P_BUSINESS_TIME;
END IF;		  

          if sql%rowcount = 0
          then

              NULL;

          end if;

        exception when others
        then

             V_RESP_CDE := '21';
             V_ERRMSG  := 'Error while updating timestamp in statement log '||substr(sqlerrm,1,100);
             RAISE EXP_RVSL_REJECT_RECORD;
        end;

      -----------------------------------------------------
      --SN:updating latest timestamp value for defect 10871
      -----------------------------------------------------

 
    --EN Commented for performance changes

    IF V_ERRMSG = 'OK' THEN

      if v_gpr_chk = 'N' --If condition Added on 31-Dec-2012 for CR-026
      then


        --Added by Ramesh.A on 03/07/2012
        --St Get the fee pla id from hist table
         BEGIN

           SELECT CCE_FEE_PLAN
            INTO V_FEE_PLAN_ID
            FROM CMS_CARD_EXCPFEE_HIST
            WHERE CCE_INST_CODE = P_INST_CODE AND CCE_PAN_CODE = V_HASH_PAN AND
                ROWNUM = 1
            ORDER BY CCE_LUPD_DATE DESC;

         EXCEPTION
           WHEN NO_DATA_FOUND THEN
            V_RESP_CDE := '21';
            V_ERRMSG   := 'Fee Plan Id not Found in hist table ';
            RAISE EXP_RVSL_REJECT_RECORD;
           WHEN OTHERS THEN
            V_RESP_CDE := '21';
            V_ERRMSG   := 'Error while selecting fee plan id from fee hist table  ' ||
                        SQLERRM;
            RAISE EXP_RVSL_REJECT_RECORD;

         END;
         --En Get the fee pla id from hist table
         --St Updates the fee plan id to card  // Added by Ramesh.A on 03/07/2012
         BEGIN
           
           UPDATE CMS_CARD_EXCPFEE
             SET CCE_FEE_PLAN  = V_FEE_PLAN_ID,
                CCE_LUPD_USER = 1,
                CCE_LUPD_DATE = SYSDATE
            WHERE CCE_INST_CODE = P_INST_CODE AND CCE_PAN_CODE = V_HASH_PAN
          AND ((CCE_VALID_TO IS NOT NULL AND (V_RVSL_TRANDATE between cce_valid_from and CCE_VALID_TO))  --Added by Ramesh.A on 11/10/2012 for defect 9332
                OR (CCE_VALID_TO IS NULL AND sysdate >= cce_valid_from));

           IF SQL%ROWCOUNT = 0 THEN
            V_ERRMSG   := 'updating FEE PLAN ID IS NOT HAPPENED';
            V_RESP_CDE := '21';
            RAISE EXP_RVSL_REJECT_RECORD;
           END IF;

         EXCEPTION
           WHEN EXP_RVSL_REJECT_RECORD THEN
            RAISE EXP_RVSL_REJECT_RECORD;
           WHEN OTHERS THEN
            V_ERRMSG   := 'Error while updating FEE PLAN ID ' ||
                        SUBSTR(SQLERRM, 1, 200);
            V_RESP_CDE := '21';
            RAISE EXP_RVSL_REJECT_RECORD;
         END;
         --En Updates the fee plan id to card // Added by Ramesh.A on 03/07/2012

      End if;
 
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
EXCEPTION
  -- << MAIN EXCEPTION>>
  WHEN EXP_RVSL_REJECT_RECORD THEN
    ROLLBACK TO V_SAVEPOINT;
 

    BEGIN
     SELECT CMS_ISO_RESPCDE
       INTO P_RESP_CDE
       FROM CMS_RESPONSE_MAST
      WHERE CMS_INST_CODE = P_INST_CODE AND
           CMS_DELIVERY_CHANNEL = P_DELV_CHNL AND
           CMS_RESPONSE_ID = TO_NUMBER(V_RESP_CDE);

     P_RESP_MSG := V_ERRMSG;
    EXCEPTION
     WHEN OTHERS THEN
       P_RESP_MSG := 'Problem while selecting data from response master ' ||
                  V_RESP_CDE || SUBSTR(SQLERRM, 1, 300);
       P_RESP_CDE := '69';
    END;



     -----------------------------------------------
     --SN: Added on 17-Apr-2013 for defect 10871
     -----------------------------------------------

     if V_PROD_CODE is null
     then

         BEGIN

             SELECT CAP_PROD_CODE,
                    CAP_CARD_TYPE,
                    CAP_CARD_STAT,
                    CAP_ACCT_NO
               INTO V_PROD_CODE,
                    V_CARD_TYPE,
                    V_APPLPAN_CARDSTAT,
                    V_ACCT_NUMBER
               FROM CMS_APPL_PAN
              WHERE CAP_INST_CODE = P_INST_CODE AND CAP_PAN_CODE = V_HASH_PAN; --P_card_no;
         EXCEPTION
         WHEN OTHERS THEN

         NULL;

         END;

     END IF;

     BEGIN
     SELECT CAM_ACCT_BAL, CAM_LEDGER_BAL,
            CAM_TYPE_CODE                       -- Added on 17-apr-2013 for defect 10871
       INTO V_ACCT_BALANCE, V_LEDGER_BALANCE,
            V_CAM_TYPE_CODE                     -- Added on 17-apr-2013 for defect 10871
       FROM CMS_ACCT_MAST
      WHERE CAM_ACCT_NO =V_ACCT_NUMBER AND
           CAM_INST_CODE = P_INST_CODE;
    EXCEPTION
     WHEN OTHERS THEN
       V_ACCT_BALANCE   := 0;
       V_LEDGER_BALANCE := 0;
    END;


     if V_DR_CR_FLAG is null
     then

        BEGIN

             SELECT CTM_CREDIT_DEBIT_FLAG
               INTO V_DR_CR_FLAG
               FROM CMS_TRANSACTION_MAST
              WHERE CTM_TRAN_CODE = P_TXN_CODE
              AND   CTM_DELIVERY_CHANNEL = P_DELV_CHNL
              AND   CTM_INST_CODE = P_INST_CODE;

        EXCEPTION
         WHEN OTHERS THEN

         NULL;

        END;

     end if;

     -----------------------------------------------
     --EN: Added on 17-Apr-2013 for defect 10871
     -----------------------------------------------

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
        CURRENCYCODE,
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
        INSTCODE,
        FEECODE,
        FEEATTACHTYPE,
        TRAN_REVERSE_FLAG,
        CUSTOMER_CARD_NO_ENCR,
        TOPUP_CARD_NO_ENCR,
        PROXY_NUMBER,
        REVERSAL_CODE,
        CUSTOMER_ACCT_NO,
        ACCT_BALANCE,
        LEDGER_BALANCE,
        RESPONSE_ID,
        CARDSTATUS, --Added cardstatus insert in transactionlog by srinivasu.k
        ERROR_MSG, --Added by Ramesh.A on 03/07/2012
        ACCT_TYPE,        -- Added on 17-Apr-2013 for defect 10871
        TIME_STAMP,        -- Added on 17-Apr-2013 for defect 10871
        CR_DR_FLAG ,       -- Added on 17-Apr-2013 for defect 10871
        STORE_ID,  --Added by Pankaj S. for Mantis id-11839
        --SN Added on 01.08.2013 for 11695
        FEE_PLAN,
        TRANFEE_AMT
        --EN Added on 01.08.2013 for 11695
        )
     VALUES
       (P_MSG_TYP,
        P_RRN,
        P_DELV_CHNL,
        P_TERMINAL_ID,
        V_RVSL_TRANDATE,
        P_TXN_CODE,
        P_TXN_TYPE,
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
        TRIM(TO_CHAR(nvl(V_REVERSAL_AMT,0), '99999999999999990.99')), -- NVL added on 17-Apr-2013 for defect 10871
        NULL,
        NULL,
        V_CURR_CODE,
        V_PROD_CODE,
        V_CARD_TYPE,
        '0.00',        -- Changed from 0 to 0.00 on 17-apr-2013 for defect 10871
        NULL,
        NULL,
        V_AUTH_ID,
        V_TRAN_DESC,
        TRIM(TO_CHAR(nvl(V_REVERSAL_AMT,0), '99999999999999990.99')), -- NVL added on 17-Apr-2013 for defect 10871
        '0.00', --- PRE AUTH AMOUNT -- Added for defect 10871
        '0.00', -- Added for defect 10871
        NULL,
        NULL,
        NULL,
        NULL,
        NULL,
        'Y',
        P_INST_CODE,
          --NULL,
        V_FEE_CODE, --Added on 01.08.2013 for 11695
        --NULL,
        V_FEEATTACH_TYPE, --Added on 01.08.2013 for 11695
        'N',
        V_ENCR_PAN,
        NULL,
        V_PROXUNUMBER,
        P_RVSL_CODE,
        V_ACCT_NUMBER,
        TRIM(TO_CHAR(nvl(V_ACCT_BALANCE,0), '99999999999999990.99')),    -- NVL added on 17-Apr-2013 for defect 10871
        TRIM(TO_CHAR(nvl(V_LEDGER_BALANCE,0), '99999999999999990.99')),  -- NVL added on 17-Apr-2013 for defect 10871
        V_RESP_CDE,
        V_APPLPAN_CARDSTAT, --Added cardstatus insert in transactionlog by srinivasu.k
        V_ERRMSG, --Added by Ramesh.A on 03/07/2012
        v_cam_type_code,   -- Added on 17-Apr-2013 for defect 10871
        nvl(v_timestamp,systimestamp),       -- Added on 17-Apr-2013 for defect 10871
       -- V_DR_CR_FLAG       -- Added on 17-Apr-2013 for defect 10871--Commented and modified on 25.07.2013 for 11693
        decode(P_DELV_CHNL,'04',v_dr_cr_flag,decode(v_dr_cr_flag,'CR','DR','DR','CR',v_dr_cr_flag)),--modified for mantis id 0012841: DEFECT:CMS:INCOMM:Transactionlog CR/DR flag of MMPOS
        --card topup reversal and card deactivation transaction were displayed as incorrect
        null, --MODIFIED FOR 12933  --Added by Pankaj S. for Mantis id-11839
         --SN Added on 01.08.2013 for 11695
         V_FEE_PLAN,
         V_FEE_AMT
         --EN Added on 01.08.2013 for 11695
        );
    EXCEPTION
     WHEN OTHERS THEN
       P_RESP_MSG := 'Problem while inserting data into transaction log  dtl' ||
                  SUBSTR(SQLERRM, 1, 300);
       P_RESP_CDE := '69'; -- Server Declined
       ROLLBACK;
       RETURN;
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
        CTD_INST_CODE,
        CTD_CUSTOMER_CARD_NO_ENCR,
        CTD_CUST_ACCT_NUMBER,
        CTD_LOCATION_ID,     --ADDED FOR 12933
        ctd_hashkey_id  --ADDED FOR 12933
        )
     VALUES
       (P_DELV_CHNL,
        P_TXN_CODE,
        P_TXN_TYPE,
        P_MSG_TYP,
        P_TXN_MODE,
        P_BUSINESS_DATE,
        P_BUSINESS_TIME,
        V_HASH_PAN,
        V_TRAN_AMT,
        V_CURRCODE,
        V_TRAN_AMT,
        NULL,
        NULL,
        NULL,
        NULL,
        V_TRAN_AMT,
        V_CARD_CURR,
        'E',
        V_ERRMSG,
        P_RRN,
        P_INST_CODE,
        V_ENCR_PAN,
        V_ACCT_NUMBER,
        P_TERMINAL_ID,   --ADDED FOR 12933
        V_HASHKEY_ID  --ADDED FOR 12933
        );
    EXCEPTION
     WHEN OTHERS THEN
       P_RESP_MSG := 'Problem while inserting data into transaction log  dtl' ||
                  SUBSTR(SQLERRM, 1, 300);
       P_RESP_CDE := '69'; -- Server Decline Response 220509
       ROLLBACK;
       RETURN;
    END;

    P_RESP_MSG := V_ERRMSG;
   -- P_RESP_CDE := V_RESP_CDE; --Added Ramesh.A on 03/07/2012 --Commented  for 11872 by Deepa on Sep-11
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
     --P_RESP_CDE := V_RESP_CDE; --Added Ramesh.A on 03/07/2012 --Commented  for 11872 by Deepa on Sep-11
    EXCEPTION
     WHEN OTHERS THEN
       P_RESP_MSG := 'Problem while selecting data from response master ' ||
                  V_RESP_CDE || SUBSTR(SQLERRM, 1, 300);
       P_RESP_CDE := '69';
    END;



 -----------------------------------------------
     --SN: Added on 17-Apr-2013 for defect 10871
     -----------------------------------------------

     if V_PROD_CODE is null
     then

         BEGIN

             SELECT CAP_PROD_CODE,
                    CAP_CARD_TYPE,
                    CAP_CARD_STAT,
                    CAP_ACCT_NO
               INTO V_PROD_CODE,
                    V_CARD_TYPE,
                    V_APPLPAN_CARDSTAT,
                    V_ACCT_NUMBER
               FROM CMS_APPL_PAN
              WHERE CAP_INST_CODE = P_INST_CODE AND CAP_PAN_CODE = V_HASH_PAN; --P_card_no;
         EXCEPTION
         WHEN OTHERS THEN

         NULL;

         END;

     end if;

      BEGIN
     SELECT CAM_ACCT_BAL, CAM_LEDGER_BAL,
            CAM_TYPE_CODE                       -- Added on 17-apr-2013 for defect 10871
       INTO V_ACCT_BALANCE, V_LEDGER_BALANCE,
            V_CAM_TYPE_CODE                     -- Added on 17-apr-2013 for defect 10871
       FROM CMS_ACCT_MAST
      WHERE CAM_ACCT_NO =V_ACCT_NUMBER AND
           CAM_INST_CODE = P_INST_CODE;
    EXCEPTION
     WHEN OTHERS THEN
       V_ACCT_BALANCE   := 0;
       V_LEDGER_BALANCE := 0;
    END;


     if V_DR_CR_FLAG is null
     then

        BEGIN

             SELECT CTM_CREDIT_DEBIT_FLAG
               INTO V_DR_CR_FLAG
               FROM CMS_TRANSACTION_MAST
              WHERE CTM_TRAN_CODE = P_TXN_CODE
              AND   CTM_DELIVERY_CHANNEL = P_DELV_CHNL
              AND   CTM_INST_CODE = P_INST_CODE;

        EXCEPTION
         WHEN OTHERS THEN

         NULL;

        END;

     end if;

     -----------------------------------------------
     --EN: Added on 17-Apr-2013 for defect 10871
     -----------------------------------------------


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
        CURRENCYCODE,
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
        INSTCODE,
        FEECODE,
        FEEATTACHTYPE,
        TRAN_REVERSE_FLAG,
        CUSTOMER_CARD_NO_ENCR,
        TOPUP_CARD_NO_ENCR,
        PROXY_NUMBER,
        REVERSAL_CODE,
        CUSTOMER_ACCT_NO,
        ACCT_BALANCE,
        LEDGER_BALANCE,
        RESPONSE_ID,
        CARDSTATUS, --Added cardstatus insert in transactionlog by srinivasu.k
        ERROR_MSG, --Added by Ramesh.A on 03/07/2012
        ACCT_TYPE,        -- Added on 17-Apr-2013 for defect 10871
        TIME_STAMP,        -- Added on 17-Apr-2013 for defect 10871
        CR_DR_FLAG,        -- Added on 17-Apr-2013 for defect 10871
        STORE_ID,  --Added by Pankaj S. for Mantis id-11839
         --SN Added on 01.08.2013 for 11695
        FEE_PLAN,
        TRANFEE_AMT
        --EN Added on 01.08.2013 for 11695
        )
     VALUES
       (P_MSG_TYP,
        P_RRN,
        P_DELV_CHNL,
        P_TERMINAL_ID,
        V_RVSL_TRANDATE,
        P_TXN_CODE,
        P_TXN_TYPE,
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
        TRIM(TO_CHAR(nvl(V_REVERSAL_AMT,0), '99999999999999990.99')),   -- NVL added on 17-Apr-2013 for defect 10871
        NULL,
        NULL,
        V_CURR_CODE,
        V_PROD_CODE,
        V_CARD_TYPE,
        '0.00',        -- Changed from 0 to 0.00 on 17-apr-2013 for defect 10871
        NULL,
        NULL,
        V_AUTH_ID,
        V_TRAN_DESC,
        TRIM(TO_CHAR(nvl(V_REVERSAL_AMT,0), '99999999999999990.99')),   -- NVL added on 17-Apr-2013 for defect 10871
        '0.00', --- PRE AUTH AMOUNT -- NULL replaced by 0.00 , on 17-Apr-2013 for defect 10871
        '0.00', -- NULL replaced by 0.00 , on 17-Apr-2013 for defect 10871
        NULL,
        NULL,
        NULL,
        NULL,
        NULL,
        'Y',
        P_INST_CODE,
       --NULL,
        V_FEE_CODE, --Added on 01.08.2013 for 11695
       --NULL,
        V_FEEATTACH_TYPE, --Added on 01.08.2013 for 11695
        'N',
        V_ENCR_PAN,
        NULL,
        V_PROXUNUMBER,
        P_RVSL_CODE,
        V_ACCT_NUMBER,
        nvl(V_ACCT_BALANCE,0),    -- to_char(nvl)) added on 17-Apr-2013 for defect 10871
        nvl(V_LEDGER_BALANCE,0),  -- to_char(nvl)) added on 17-Apr-2013 for defect 10871
        V_RESP_CDE,
        V_APPLPAN_CARDSTAT, --Added cardstatus insert in transactionlog by srinivasu.k
        V_ERRMSG, --Added by Ramesh.A on 03/07/2012
        v_cam_type_code,   -- Added on 17-Apr-2013 for defect 10871
        nvl(v_timestamp,systimestamp),       -- Added on 17-Apr-2013 for defect 10871
        --V_DR_CR_FLAG       -- Added on 17-Apr-2013 for defect 10871--Commented and modified on 25.07.2013 for 11693
        decode(P_DELV_CHNL,'04',v_dr_cr_flag,decode(v_dr_cr_flag,'CR','DR','DR','CR',v_dr_cr_flag)), --modified for mantis id 0012841: DEFECT:CMS:INCOMM:Transactionlog CR/DR flag of MMPOS
        --card topup reversal and card deactivation transaction were displayed as incorrect
        null, --MODIFIED FOR 12933 --Added by Pankaj S. for Mantis id-11839
        --SN Added on 01.08.2013 for 11695
         V_FEE_PLAN,
         V_FEE_AMT
         --EN Added on 01.08.2013 for 11695
        );
    EXCEPTION
     WHEN OTHERS THEN
       P_RESP_MSG := 'Problem while inserting data into transaction log  dtl' ||
                  SUBSTR(SQLERRM, 1, 300);
       P_RESP_CDE := '69'; -- Server Declined
       ROLLBACK;
       RETURN;
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
        CTD_INST_CODE,
        CTD_CUSTOMER_CARD_NO_ENCR,
        CTD_CUST_ACCT_NUMBER,
        CTD_LOCATION_ID,     --ADDED FOR 12933
        ctd_hashkey_id  --ADDED FOR 12933
        )
     VALUES
       (P_DELV_CHNL,
        P_TXN_CODE,
        P_TXN_TYPE,
        P_MSG_TYP,
        P_TXN_MODE,
        P_BUSINESS_DATE,
        P_BUSINESS_TIME,
        V_HASH_PAN,
        V_TRAN_AMT,
        V_CURRCODE,
        V_TRAN_AMT,
        NULL,
        NULL,
        NULL,
        NULL,
        V_TRAN_AMT,
        V_CARD_CURR,
        'E',
        V_ERRMSG,
        P_RRN,
        P_INST_CODE,
        V_ENCR_PAN,
        V_ACCT_NUMBER,
        P_TERMINAL_ID,   --ADDED FOR 12933
        V_HASHKEY_ID -- ADDED FOR 12933
        );
    EXCEPTION
     WHEN OTHERS THEN
       P_RESP_MSG := 'Problem while inserting data into transaction log  dtl' ||
                  SUBSTR(SQLERRM, 1, 300);
       P_RESP_CDE := '69'; -- Server Decline Response 220509
       ROLLBACK;
       RETURN;
    END;
END;

/
show error;