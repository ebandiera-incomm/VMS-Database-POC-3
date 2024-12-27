create or replace PROCEDURE        vmscms.SP_ENTRY_NEWCAF_PCMS_ROWID(P_INSTCODE IN NUMBER,
                                            P_ROWID    IN VARCHAR2,
                                            P_LUPDUSER IN NUMBER,
                                            P_ERRMSG   OUT VARCHAR2) IS

  /*************************************************
      * Created Date     :  10-Dec-2012
      * Created By       :  Narayana Swamy T
      * PURPOSE          :  Generate Pan
      * Modified By      :  Sagar M.
      * Modified Date    :  16-Aug-2012
      * Modified Reason  :  For new KYC changes
      * Reviewer         :  Saravanakumar
      * Reviewed Date    :  16_Apr-2012
      * Build Number     :  RI0015_B0002

      * Modified By      :  Pankaj S.
      * Modified Date    :  13-Feb-2013
      * Modified Reason  :  To pass SSN/Other ID for Customer Registration based on ID type
      * Reviewer         :  Dhiraj
      * Reviewed Date    :  26/FEB/2013
      * Build Number     :  CMS3.5.1_RI0023.2_B0008
      
      * Modified By      :  Pankaj S.
      * Modified Date    :  07-Mar-2013
      * Modified Reason  :  To update id type iin customer mast(Mantis ID-10549)
      * Reviewer         :  Dhiraj
      * Reviewed Date    :  07/Mar/2013
      * Build Number     :  CMS3.5.1_RI0023.2_B0018
      
      * Modified By      :  Ramesh A
      * Modified Date    :  17-Jun-2014
      * Modified Reason  :  FSS-1710 - Performance issue in GPR Card generation transaction.needs to fine tune the process
      * Reviewer         :  spankaj
      * Build Number     :  RI0027.1.9_B0001
      
      * Modified by      : MageshKumar S.
      * Modified Date    : 25-July-14    
      * Modified For     : FWR-48
      * Modified reason  : GL Mapping removal changes
      * Reviewer         : Spankaj    
      * Build Number     : RI0027.3.1_B0001
      
      * Modified by      : Pankaj S.
      * Modified Date    : 18-Aug-2015    
      * Modified reason  : Partner ID Changes
      * Reviewer         : Sarvanankumar 
      * Build Number     :   
      
       * Modified by           : Abdul Hameed M.A
      * Modified Date         : 07-Sep-15
      * Modified For          : FSS-3509 & FSS-1817
      * Reviewer              : Saravanankumar
      * Build Number          : VMSGPRHOSTCSD3.2     
      
      
       * Modified by           : Siva Kumar 
      * Modified Date         : 18-Mar-16
      * Modified For          : MVHOST-16
      * Reviewer              : Saravanankumar/pankaj
      * Build Number          : VMSGPRHOSTCSD_4.0_b0006
      
      * Modified by      : Saravana Kumar A
      * Modified Date    : 07-Jan-17
      * Modified reason  : Card Expiry date logic changes
      * Reviewer         : Spankaj
      * Build Number     : VMSGPRHOST17.1
      
       * Modified by      : Saravana Kumar A
      * Modified Date    : 26-Apr-17
      * Modified reason  : Card Expiry date logic changes
      * Reviewer         : Spankaj
      * Build Number     : VMSGPRHOST17.04
      
      * Modified By      : MageshKumar S
      * Modified Date    : 18/07/2017
      * Purpose          : FSS-5157
      * Reviewer         : Saravanan/Pankaj S. 
      * Release Number   : VMSGPRHOST17.07
	  
	  * Modified by      :  Vini Pushkaran
      * Modified Date    :  02-Feb-2018
      * Modified For     :  VMS-162
      * Reviewer         :  Saravanankumar
      * Build Number     :  VMSGPRHOSTCSD_18.01
  *************************************************/

  V_CUST_CODE           CMS_CUST_MAST.CCM_CUST_CODE%TYPE;
  V_GCM_CNTRY_CODE      GEN_CNTRY_MAST.GCM_CNTRY_CODE%TYPE;
  V_COMM_ADDR_LIN1      CMS_CAF_INFO_ENTRY.CCI_SEG12_ADDR_LINE1%TYPE;
  V_COMM_ADDR_LIN2      CMS_CAF_INFO_ENTRY.CCI_SEG12_ADDR_LINE2%TYPE;
  V_COMM_POSTAL_CODE    CMS_CAF_INFO_ENTRY.CCI_SEG12_POSTAL_CODE%TYPE;
  V_COMM_HOMEPHONE_NO   CMS_CAF_INFO_ENTRY.CCI_SEG12_HOMEPHONE_NO%TYPE;
  V_COMM_MOBILENO       CMS_CAF_INFO_ENTRY.CCI_SEG12_MOBILENO%TYPE;
  V_COMM_EMAILID        CMS_CAF_INFO_ENTRY.CCI_SEG12_EMAILID%TYPE;
  V_COMM_CITY           CMS_CAF_INFO_ENTRY.CCI_SEG12_CITY%TYPE;
  V_COMM_STATE          CMS_CAF_INFO_ENTRY.CCI_SEG12_STATE%TYPE;
  V_OTHER_ADDR_LIN1     CMS_CAF_INFO_ENTRY.CCI_SEG13_ADDR_LINE1%TYPE;
  V_OTHER_ADDR_LIN2     CMS_CAF_INFO_ENTRY.CCI_SEG13_ADDR_LINE2%TYPE;
  V_OTHER_POSTAL_CODE   CMS_CAF_INFO_ENTRY.CCI_SEG13_POSTAL_CODE%TYPE;
  V_OTHER_HOMEPHONE_NO  CMS_CAF_INFO_ENTRY.CCI_SEG13_HOMEPHONE_NO%TYPE;
  V_OTHER_MOBILENO      CMS_CAF_INFO_ENTRY.CCI_SEG13_MOBILENO%TYPE;
  V_OTHER_EMAILID       CMS_CAF_INFO_ENTRY.CCI_SEG13_EMAILID%TYPE;
  V_OTHER_CITY          CMS_CAF_INFO_ENTRY.CCI_SEG13_CITY%TYPE;
  V_OTHER_STATE         CMS_CAF_INFO_ENTRY.CCI_SEG12_STATE%TYPE;
  V_COMM_ADDRCODE       CMS_ADDR_MAST.CAM_ADDR_CODE%TYPE;
  V_OTHER_ADDRCODE      CMS_ADDR_MAST.CAM_ADDR_CODE%TYPE;
  V_SWITCH_ACCT_TYPE    CMS_ACCT_TYPE.CAT_SWITCH_TYPE%TYPE DEFAULT '11';
  V_SWITCH_ACCT_STAT    CMS_ACCT_STAT.CAS_SWITCH_STATCODE%TYPE DEFAULT '3';
  V_ACCT_TYPE           CMS_ACCT_TYPE.CAT_TYPE_CODE%TYPE;
  V_ACCT_STAT           CMS_ACCT_MAST.CAM_STAT_CODE%TYPE;
  V_ACCT_NUMB           CMS_ACCT_MAST.CAM_ACCT_NO%TYPE;
  V_ACCT_ID             CMS_ACCT_MAST.CAM_ACCT_ID%TYPE;
  V_DUP_FLAG            VARCHAR2(1);
  V_PROD_CODE           CMS_PROD_MAST.CPM_PROD_CODE%TYPE;
  V_PROD_CATTYPE        CMS_PROD_CATTYPE.CPC_CARD_TYPE%TYPE;
  V_INST_BIN            CMS_PROD_BIN.CPB_INST_BIN%TYPE;
  V_PROD_CCC            CMS_PROD_CCC.CPC_PROD_SNAME%TYPE;
  V_CUSTCATG            CMS_PROD_CCC.CPC_CUST_CATG%TYPE;
  V_APPL_CODE           CMS_APPL_MAST.CAM_APPL_CODE%TYPE;
  V_ERRMSG              VARCHAR2(500);
  V_SAVEPOINT           NUMBER DEFAULT 1;
  V_GENDER              VARCHAR2(1);
  V_EXPRYPARAM          CMS_BIN_PARAM.CBP_PARAM_VALUE%TYPE;
  V_HOLDPOSN            CMS_CUST_ACCT.CCA_HOLD_POSN%TYPE;
  V_BRANCHECK           NUMBER(1);
 -- V_FUNC_CODE           CMS_FUNC_MAST.CFM_FUNC_CODE%TYPE; --comented for fwr-48
 -- V_SPPRT_FUNCCODE      CMS_FUNC_MAST.CFM_FUNC_CODE%TYPE; --comented for fwr-48
 -- V_FUNC_DESC           CMS_FUNC_MAST.CFM_FUNC_DESC%TYPE; --comented for fwr-48
 -- V_SPPRTFUNC_DESC      CMS_FUNC_MAST.CFM_FUNC_DESC%TYPE; --comented for fwr-48
  V_CATG_CODE           CMS_PROD_MAST.CPM_CATG_CODE%TYPE;
 -- V_CHECK_FUNCCODE      NUMBER(1); --comented for fwr-48
 -- V_CHECK_SPPRTFUNCCODE NUMBER(1); --comented for fwr-48
 -- V_INITIAL_SPPRTFLAG   VARCHAR2(1); --comented for fwr-48
  V_KYC_FLAG            VARCHAR2(1);
  V_INSTRUMENT_REALISED VARCHAR2(1);
  V_KYC_ERROR_LOG       NUMBER(1);
  V_INSTREAL_ERROR_LOG  NUMBER(1);
  V_COMM_TYPE           CHAR(1);
  V_CUST_DATA           TYPE_CUST_REC_ARRAY;
  V_ADDR_DATA1          TYPE_ADDR_REC_ARRAY;
  V_ADDR_DATA2          TYPE_ADDR_REC_ARRAY;
  V_APPL_DATA           TYPE_APPL_REC_ARRAY;
  V_SEG31ACCTNUM_DATA   TYPE_ACCT_REC_ARRAY;
  EXP_REJECT_RECORD EXCEPTION;
  EXP_PROCESS_RECORD EXCEPTION;
  V_COMM_OFFICENO       CMS_CAF_INFO_ENTRY.CCI_SEG12_OFFICEPHONE_NO%TYPE;
  V_COMM_CNTRYCODE      CMS_CAF_INFO_ENTRY.CCI_SEG12_COUNTRY_CODE%TYPE;
  V_OTHER_OFFICENO      CMS_CAF_INFO_ENTRY.CCI_SEG13_OFFICEPHONE_NO%TYPE;
  V_OTHER_CNTRYCODE     CMS_CAF_INFO_ENTRY.CCI_SEG12_COUNTRY_CODE%TYPE;
  V_GCM_OTHERCNTRY_CODE GEN_CNTRY_MAST.GCM_CNTRY_CODE%TYPE;
  T_ACCT_NUM            CMS_ACCT_MAST.CAM_ACCT_NO%TYPE;
  V_PROFILE_CODE        CMS_PROD_CATTYPE.CPC_PROFILE_CODE%TYPE;
  V_CPM_CATG_CODE       CMS_PROD_MAST.CPM_CATG_CODE%TYPE;
  V_PROD_PREFIX         CMS_PROD_CATTYPE.CPC_PROD_PREFIX%TYPE;
  V_PROGRAMID           VARCHAR2(4);
  V_EXPRY_DATE          DATE;
  V_VALIDITY_PERIOD     CMS_BIN_PARAM.CBP_PARAM_VALUE%type;
  V_IDVALUE             CMS_CAF_INFO_ENTRY.CCI_ID_NUMBER%TYPE;  --Added by Pankaj S. on 13-Feb-2013 during Multiple SSN check changes
  V_EXP_DATE_EXEMPTION     CMS_PROD_CATTYPE.CPC_EXP_DATE_EXEMPTION%type;
  v_encrypt_enable           CMS_PROD_CATTYPE.CPC_ENCRYPT_ENABLE%TYPE;
  v_encr_firstname           CMS_CAF_INFO_ENTRY.CCI_SEG12_NAME_LINE1%TYPE;     
  v_encr_lastname            CMS_CAF_INFO_ENTRY.CCI_SEG12_NAME_LINE2%TYPE;     
  v_encr_p_add_one           CMS_CAF_INFO_ENTRY.CCI_SEG12_ADDR_LINE1%TYPE; 
  v_encr_p_add_two           CMS_CAF_INFO_ENTRY.CCI_SEG12_ADDR_LINE2%TYPE;  
  v_encr_m_add_one           CMS_CAF_INFO_ENTRY.CCI_SEG13_ADDR_LINE1%TYPE;                                     
  v_encr_mothers_name        CMS_CAF_INFO_ENTRY.CCI_MOTHERS_MAIDEN_NAME%TYPE;   
  
  CURSOR C IS
    SELECT CCI_INST_CODE,
         CCI_FILE_NAME,
         CCI_ROW_ID,
         CCI_APPL_CODE,
         CCI_APPL_NO,
         CCI_PAN_CODE,
         CCI_MBR_NUMB,
         CCI_CRD_STAT,
         CCI_EXP_DAT,
         CCI_REC_TYP,
         CCI_CRD_TYP,
         CCI_REQUESTER_NAME,
         CCI_PROD_CODE,
         CCI_CARD_TYPE,
         CCI_SEG12_BRANCH_NUM,
         CCI_FIID,
         CCI_TITLE,
         CCI_SEG12_NAME_LINE1,
         CCI_SEG12_NAME_LINE2,
         CCI_BIRTH_DATE,
         CCI_MOTHERS_MAIDEN_NAME,
         CCI_SSN,
         CCI_SSN_encr,
         CCI_HOBBIES,
         CCI_CUST_ID,
         CCI_COMM_TYPE,
         CCI_SEG12_ADDR_LINE1,
         CCI_SEG12_ADDR_LINE2,
         CCI_SEG12_CITY,
         CCI_SEG12_STATE,
         CCI_SEG12_POSTAL_CODE,
         CCI_SEG12_COUNTRY_CODE,
         CCI_SEG12_MOBILENO,
         CCI_SEG12_HOMEPHONE_NO,
         CCI_SEG12_OFFICEPHONE_NO,
         CCI_SEG12_EMAILID,
         CCI_SEG13_ADDR_LINE1,
         CCI_SEG13_ADDR_LINE2,
         CCI_SEG13_CITY,
         CCI_SEG13_STATE,
         CCI_SEG13_POSTAL_CODE,
         CCI_SEG13_COUNTRY_CODE,
         CCI_SEG13_MOBILENO,
         CCI_SEG13_HOMEPHONE_NO,
         CCI_SEG13_OFFICEPHONE_NO,
         CCI_SEG13_EMAILID,
         CCI_SEG31_LGTH,
         CCI_SEG31_ACCT_CNT,
         CCI_SEG31_TYP,
         CCI_SEG31_NUM,
         CCI_SEG31_STAT,
         CCI_PROD_AMT,
         CCI_FEE_AMT,
         CCI_TOT_AMT,
         CCI_PAYMENT_MODE,
         CCI_INSTRUMENT_NO,
         CCI_INSTRUMENT_AMT,
         CCI_DRAWN_DATE,
         CCI_PAYREF_NO,
         CCI_EMP_ID,
         CCI_KYC_REASON,
         CCI_KYC_FLAG,
         CCI_ADDON_FLAG,
         CCI_VIRTUAL_ACCT,
         CCI_DOCUMENT_VERIFY,
         CCI_EXCHANGE_RATE,
         CCI_UPLD_STAT,
         CCI_APPROVED,
         CCI_MAKER_USER_ID,
         CCI_MAKER_DATE,
         CCI_CHECKER_USER_ID,
         CCI_CHEKER_DATE,
         CCI_AUTH_USER_ID,
         CCI_AUTH_DATE,
         CCI_INS_USER,
         CCI_INS_DATE,
         CCI_LUPD_USER,
         CCI_CUST_CATG,
         --Sn Customer generic data
         CCI_CUSTOMER_PARAM1,
         CCI_CUSTOMER_PARAM2,
         CCI_CUSTOMER_PARAM3,
         CCI_CUSTOMER_PARAM4,
         CCI_CUSTOMER_PARAM5,
         CCI_CUSTOMER_PARAM6,
         CCI_CUSTOMER_PARAM7,
         CCI_CUSTOMER_PARAM8,
         CCI_CUSTOMER_PARAM9,
         CCI_CUSTOMER_PARAM10,
         --En customer generic data
         --Sn select addrss seg12 detail
         CCI_SEG12_ADDR_PARAM1,
         CCI_SEG12_ADDR_PARAM2,
         CCI_SEG12_ADDR_PARAM3,
         CCI_SEG12_ADDR_PARAM4,
         CCI_SEG12_ADDR_PARAM5,
         CCI_SEG12_ADDR_PARAM6,
         CCI_SEG12_ADDR_PARAM7,
         CCI_SEG12_ADDR_PARAM8,
         CCI_SEG12_ADDR_PARAM9,
         CCI_SEG12_ADDR_PARAM10,

         --En select ddrss seg12 detail
         --Sn select addrss seg12 detail
         CCI_SEG13_ADDR_PARAM1,
         CCI_SEG13_ADDR_PARAM2,
         CCI_SEG13_ADDR_PARAM3,
         CCI_SEG13_ADDR_PARAM4,
         CCI_SEG13_ADDR_PARAM5,
         CCI_SEG13_ADDR_PARAM6,
         CCI_SEG13_ADDR_PARAM7,
         CCI_SEG13_ADDR_PARAM8,
         CCI_SEG13_ADDR_PARAM9,
         CCI_SEG13_ADDR_PARAM10,

         --Sn select acct data
         CCI_SEG31_NUM_PARAM1,
         CCI_SEG31_NUM_PARAM2,
         CCI_SEG31_NUM_PARAM3,
         CCI_SEG31_NUM_PARAM4,
         CCI_SEG31_NUM_PARAM5,
         CCI_SEG31_NUM_PARAM6,
         CCI_SEG31_NUM_PARAM7,
         CCI_SEG31_NUM_PARAM8,
         CCI_SEG31_NUM_PARAM9,
         CCI_SEG31_NUM_PARAM10,

         --Sn select appl data
         CCI_CUSTAPPL_PARAM1,
         CCI_CUSTAPPL_PARAM2,
         CCI_CUSTAPPL_PARAM3,
         CCI_CUSTAPPL_PARAM4,
         CCI_CUSTAPPL_PARAM5,
         CCI_CUSTAPPL_PARAM6,
         CCI_CUSTAPPL_PARAM7,
         CCI_CUSTAPPL_PARAM8,
         CCI_CUSTAPPL_PARAM9,
         --Sn Added by Pankaj S. on 13-Feb-2013 during Multiple SSN check changes
         CCI_ID_NUMBER,
         CCI_ID_NUMBER_ENCR,
         CCI_ID_ISSUER,
         CCI_ID_ISSUANCE_DATE,
         CCI_ID_EXPIRY_DATE,
         --En Added by Pankaj S. on 13-Feb-2013 during Multiple SSN check changes
         CCI_LUPD_DATE,
         CCI_COMMENTS,
         ROWID R
     FROM CMS_CAF_INFO_ENTRY
    WHERE CCI_APPROVED = 'A' AND CCI_INST_CODE = P_INSTCODE AND
         CCI_UPLD_STAT = 'P' AND CCI_ROW_ID = P_ROWID
         AND CCI_KYC_FLAG IN ('Y','P','O','I'); -- In condition added by sagar on 16Aug2012 for KYC changes
BEGIN
  V_ERRMSG            := 'OK';
  V_CUST_DATA         := TYPE_CUST_REC_ARRAY();
  V_ADDR_DATA1        := TYPE_ADDR_REC_ARRAY();
  V_ADDR_DATA2        := TYPE_ADDR_REC_ARRAY();
  V_APPL_DATA         := TYPE_APPL_REC_ARRAY();
  V_SEG31ACCTNUM_DATA := TYPE_ACCT_REC_ARRAY();
  --SN  Loop for record pending for processing
 -- DELETE FROM PCMS_UPLOAD_LOG; -- Commented for not required on FSS-1710

  FOR I IN C LOOP
    --Initialize the common loop variable
    V_ERRMSG := 'OK';
    V_CUST_DATA.DELETE;
    V_ADDR_DATA1.DELETE;
    V_ADDR_DATA2.DELETE;
    V_SEG31ACCTNUM_DATA.DELETE;
    V_APPL_DATA.DELETE;
    SAVEPOINT V_SAVEPOINT;

    BEGIN
     --Sn  Check product , prodtype  catg

     -- Sn Check KYC first is N or not
     --if kyc show en error then also we will process the record
     BEGIN
       SELECT CCI_KYC_FLAG
        INTO V_KYC_FLAG
        FROM CMS_CAF_INFO_ENTRY
        WHERE CCI_INST_CODE = P_INSTCODE AND CCI_ROW_ID = I.CCI_ROW_ID;
       IF V_KYC_FLAG = 'N' THEN
        V_KYC_ERROR_LOG := 1;
        V_ERRMSG        := 'KYC is pending for approval ';
        RAISE EXP_PROCESS_RECORD;
       END IF;
     EXCEPTION
       WHEN OTHERS THEN
        V_KYC_ERROR_LOG := 1;
        V_ERRMSG        := 'Error while selecting KYC flag ' ||
                        SUBSTR(SQLERRM, 1, 200);
        RAISE EXP_PROCESS_RECORD;
     END;

     --En check kyc first is N or Not

     -- Sn find prod
     BEGIN
       SELECT CPM_PROD_CODE
        INTO V_PROD_CODE
        FROM CMS_PROD_MAST
        WHERE CPM_INST_CODE = P_INSTCODE AND
            CPM_PROD_CODE = I.CCI_PROD_CODE AND CPM_MARC_PROD_FLAG = 'N';
     EXCEPTION
       WHEN NO_DATA_FOUND THEN
        V_ERRMSG := 'Product code' || I.CCI_PROD_CODE ||
                  'is not defined in the master';
        RAISE EXP_REJECT_RECORD;
       WHEN OTHERS THEN
        V_ERRMSG := 'Error while selecting product ' ||
                  SUBSTR(SQLERRM, 1, 200);
        RAISE EXP_REJECT_RECORD;
     END;

     -- En find prod
     -- Sn check in prod bin
     BEGIN
       SELECT CPB_INST_BIN
        INTO V_INST_BIN
        FROM CMS_PROD_BIN
        WHERE CPB_INST_CODE = P_INSTCODE AND
            CPB_PROD_CODE = I.CCI_PROD_CODE AND
            CPB_MARC_PRODBIN_FLAG = 'N' AND CPB_ACTIVE_BIN = 'Y';
     EXCEPTION
       WHEN NO_DATA_FOUND THEN
        V_ERRMSG := 'Product code' || I.CCI_PROD_CODE ||
                  'is not attached to BIN' || I.CCI_PAN_CODE;
        RAISE EXP_REJECT_RECORD;
       WHEN OTHERS THEN
        V_ERRMSG := 'Error while selecting product and bin dtl ' ||
                  SUBSTR(SQLERRM, 1, 200);
        RAISE EXP_REJECT_RECORD;
     END;

     -- En check in prod bin
     -- Sn find prod cattype
     BEGIN
       SELECT CPC_CARD_TYPE
        INTO V_PROD_CATTYPE
        FROM CMS_PROD_CATTYPE
        WHERE CPC_INST_CODE = P_INSTCODE AND
            CPC_PROD_CODE = I.CCI_PROD_CODE AND
            CPC_CARD_TYPE = I.CCI_CARD_TYPE;
     EXCEPTION
       WHEN NO_DATA_FOUND THEN
        V_ERRMSG := 'Product code' || I.CCI_PROD_CODE ||
                  'is not attached to cattype' || I.CCI_CARD_TYPE;
        RAISE EXP_REJECT_RECORD;
       WHEN OTHERS THEN
        V_ERRMSG := 'Error while selecting product cattype ' ||
                  SUBSTR(SQLERRM, 1, 200);
        RAISE EXP_REJECT_RECORD;
     END;

     -- En find prod cattype
     --Sn find the default cust catg
     BEGIN
       SELECT CCC_CATG_CODE
        INTO V_CUSTCATG
        FROM CMS_CUST_CATG
        WHERE CCC_INST_CODE = P_INSTCODE AND
            CCC_CATG_SNAME = I.CCI_CUST_CATG;
     EXCEPTION
       WHEN NO_DATA_FOUND THEN
        V_ERRMSG := 'Catg code is not defined ' || 'DEF';
        RAISE EXP_REJECT_RECORD;
       WHEN OTHERS THEN
        V_ERRMSG := 'Error while selecting custcatg from master ' ||
                  SUBSTR(SQLERRM, 1, 200);
        RAISE EXP_REJECT_RECORD;
     END;

     --En find the default cust
     -- Sn find entry in prod ccc
     BEGIN
       SELECT CPC_PROD_SNAME
        INTO V_PROD_CCC
        FROM CMS_PROD_CCC
        WHERE CPC_INST_CODE = P_INSTCODE AND
            CPC_PROD_CODE = I.CCI_PROD_CODE AND
            CPC_CARD_TYPE = I.CCI_CARD_TYPE AND
            CPC_CUST_CATG = V_CUSTCATG;
     EXCEPTION
       WHEN NO_DATA_FOUND THEN
        BEGIN
          INSERT INTO CMS_PROD_CCC
            (CPC_INST_CODE,
            CPC_CUST_CATG,
            CPC_CARD_TYPE,
            CPC_PROD_CODE,
            CPC_INS_USER,
            CPC_INS_DATE,
            CPC_LUPD_USER,
            CPC_LUPD_DATE,
            CPC_VENDOR,
            CPC_STOCK,
            CPC_PROD_SNAME)
          VALUES
            (P_INSTCODE,
            V_CUSTCATG,
            I.CCI_CARD_TYPE,
            I.CCI_PROD_CODE,
            P_LUPDUSER,
            SYSDATE,
            P_LUPDUSER,
            SYSDATE,
            '1',
            '1',
            'Default');
        EXCEPTION
          WHEN OTHERS THEN
            V_ERRMSG := 'Error while creating a entry in prod_ccc';
            RAISE EXP_REJECT_RECORD;
        END;
       WHEN OTHERS THEN
        V_ERRMSG := 'Error while selecting prodccc detail from master ' ||
                  SUBSTR(SQLERRM, 1, 200);
        RAISE EXP_REJECT_RECORD;
     END;

     -- En find entry in prod ccc

     --En Check Product , prod type  catg

     -- Sn find prod
     BEGIN
       SELECT CPM_CATG_CODE
        INTO V_CATG_CODE
        FROM CMS_PROD_MAST
        WHERE CPM_INST_CODE = P_INSTCODE AND
            CPM_PROD_CODE = I.CCI_PROD_CODE AND CPM_MARC_PROD_FLAG = 'N';
     EXCEPTION
       WHEN NO_DATA_FOUND THEN
        V_ERRMSG := 'Product code' || I.CCI_PROD_CODE ||
                  'is not defined in the master';
        RAISE EXP_REJECT_RECORD;
       WHEN OTHERS THEN
        V_ERRMSG := 'Error while selecting product ' ||
                  SUBSTR(SQLERRM, 1, 200);
        RAISE EXP_REJECT_RECORD;
     END;

     --msiva added on Jul 25 2011 for Expiry date calculation Sn

     BEGIN

       SELECT CPC_PROFILE_CODE,
            CPM_CATG_CODE,
            CPC_PROD_PREFIX,
            CPC_PROGRAM_ID,CPC_EXP_DATE_EXEMPTION, CPC_ENCRYPT_ENABLE
        into V_PROFILE_CODE, V_CPM_CATG_CODE, V_PROD_PREFIX, V_PROGRAMID,V_EXP_DATE_EXEMPTION,--,v_sweep_flag
		     V_ENCRYPT_ENABLE
        FROM CMS_PROD_CATTYPE, CMS_PROD_MAST
        WHERE CPC_INST_CODE = P_INSTCODE AND
            CPC_INST_CODE = CPM_INST_CODE AND
            CPC_PROD_CODE = I.CCI_PROD_CODE AND
            CPC_CARD_TYPE = I.CCI_CARD_TYPE AND
            CPM_PROD_CODE = CPC_PROD_CODE;
     EXCEPTION
       WHEN NO_DATA_FOUND THEN
        V_ERRMSG := 'Profile code not defined for product code ' ||
                  I.CCI_PROD_CODE || 'card type ' || I.CCI_CARD_TYPE;
        RAISE EXP_REJECT_RECORD;
       WHEN OTHERS THEN
        V_ERRMSG := 'Error while selecting applcode from applmast' ||
                  SUBSTR(SQLERRM, 1, 300);
        RAISE EXP_REJECT_RECORD;
     END;

     BEGIN
            vmsfunutilities.get_expiry_date(p_instcode,i.cci_prod_code,
            i.cci_card_type,V_PROFILE_CODE,v_expry_date,V_ERRMSG);

            if V_ERRMSG<>'OK' then
            RAISE EXP_REJECT_RECORD;
       END IF;
       
      EXCEPTION
          WHEN EXP_REJECT_RECORD THEN
            RAISE;
          WHEN OTHERS THEN
       


    
    
         
         
         
                p_errmsg:='Error while calling vmsfunutilities.get_expiry_date'||substr(sqlerrm,1,200);
                                RAISE EXP_REJECT_RECORD;
                        END;
    

     IF V_CATG_CODE = 'P' THEN
       -- Sn Check KYC first is N or not
       BEGIN
        V_INSTREAL_ERROR_LOG := 0;

        SELECT CCI_INSTRUMENT_REALISED
          INTO V_INSTRUMENT_REALISED
          FROM CMS_CAF_INFO_ENTRY
         WHERE CCI_INST_CODE = P_INSTCODE AND CCI_ROW_ID = I.CCI_ROW_ID AND
              CCI_INSTRUMENT_REALISED = 'Y';
       EXCEPTION
        WHEN NO_DATA_FOUND THEN
          V_ERRMSG := 'Instrument Realised ' ||
                    'is pending for approval ';
          RAISE EXP_PROCESS_RECORD;
        WHEN OTHERS THEN
          V_INSTREAL_ERROR_LOG := 1;
          V_ERRMSG             := 'Error while selecting Instrument Realised ' ||
                             SUBSTR(SQLERRM, 1, 200);
          RAISE EXP_PROCESS_RECORD;
       END;

       --En check instrument_realised first is N or Not
       --Sn commented for fwr-48
       --Sn Check card issuance attached to product
    /*   BEGIN
        SELECT CFM_FUNC_CODE, CFM_FUNC_DESC
          INTO V_FUNC_CODE, V_FUNC_DESC
          FROM CMS_FUNC_MAST
         WHERE CFM_INST_CODE = P_INSTCODE AND CFM_TXN_CODE = 'CI' AND
              CFM_TXN_MODE = '0' AND CFM_DELIVERY_CHANNEL = '05';
       EXCEPTION
        WHEN NO_DATA_FOUND THEN
          V_ERRMSG := 'Master data is not available for card issuance';
          RAISE EXP_REJECT_RECORD;
        WHEN OTHERS THEN
          V_ERRMSG := 'Error while selecting funccode detail from master ' ||
                    SUBSTR(SQLERRM, 1, 200);
          RAISE EXP_REJECT_RECORD;
       END;

       BEGIN
        SELECT 1
          INTO V_CHECK_FUNCCODE
          FROM CMS_FUNC_PROD
         WHERE CFP_INST_CODE = P_INSTCODE AND
              CFP_PROD_CODE = I.CCI_PROD_CODE AND
              CFP_PROD_CATTYPE = I.CCI_CARD_TYPE AND
              CFP_FUNC_CODE = V_FUNC_CODE;
       EXCEPTION
        WHEN NO_DATA_FOUND THEN
          V_ERRMSG := V_FUNC_DESC || ' is not attached to product code ' ||
                    I.CCI_PROD_CODE || ' card type ' || I.CCI_CARD_TYPE;
          RAISE EXP_REJECT_RECORD;
        WHEN OTHERS THEN
          V_ERRMSG := 'Error while verifing  funccode attachment to Product code  type ' ||
                    SUBSTR(SQLERRM, 1, 200);
          RAISE EXP_REJECT_RECORD;
       END;

       --En Check card issuance attached to product

       --Sn check card amount and initial load spprt function
       IF I.CCI_PROD_AMT > 0 THEN
        --Sn check initial load spprt func
        BEGIN
          SELECT CFM_FUNC_CODE, CFM_FUNC_DESC
            INTO V_SPPRT_FUNCCODE, V_SPPRTFUNC_DESC
            FROM CMS_FUNC_MAST
           WHERE CFM_INST_CODE = P_INSTCODE AND CFM_TXN_CODE = 'IL' AND
                CFM_TXN_MODE = '0' AND CFM_DELIVERY_CHANNEL = '05';
        EXCEPTION
          WHEN NO_DATA_FOUND THEN
            V_ERRMSG := 'Master data is not available for initial load';
            RAISE EXP_REJECT_RECORD;
          WHEN OTHERS THEN
            V_ERRMSG := 'Error while selecting funccode detail from master for initial load ' ||
                     SUBSTR(SQLERRM, 1, 200);
            RAISE EXP_REJECT_RECORD;
        END;

        --En check initial load spprt function

        --Sn Check card initial load attached to product
        BEGIN
          SELECT 1
            INTO V_CHECK_SPPRTFUNCCODE
            FROM CMS_FUNC_PROD
           WHERE CFP_INST_CODE = P_INSTCODE AND
                CFP_PROD_CODE = I.CCI_PROD_CODE AND
                CFP_PROD_CATTYPE = I.CCI_CARD_TYPE AND
                CFP_FUNC_CODE = V_SPPRT_FUNCCODE;

          V_INITIAL_SPPRTFLAG := 'Y';
        EXCEPTION
          WHEN NO_DATA_FOUND THEN
            V_ERRMSG := V_SPPRTFUNC_DESC ||
                     ' is not attached to product code ' ||
                     I.CCI_PROD_CODE || ' card type ' ||
                     I.CCI_CARD_TYPE;
            RAISE EXP_REJECT_RECORD;
          WHEN OTHERS THEN
            V_ERRMSG := 'Error while verifing  funccode attachment to Product code  type for initial load' ||
                     SUBSTR(SQLERRM, 1, 200);
            RAISE EXP_REJECT_RECORD;
        END;
        --En Check card initial load attached to product
       END IF;*/
       --En commented for fwr-48
     END IF;

     --En check card amount and initial load spprt function

     --Sn find Branch
     BEGIN
       SELECT 1
        INTO V_BRANCHECK
        FROM CMS_BRAN_MAST
        WHERE CBM_INST_CODE = P_INSTCODE AND CBM_BRAN_CODE = I.CCI_FIID;
     EXCEPTION
       WHEN NO_DATA_FOUND THEN
        V_ERRMSG := 'Branch code not defined for  ' || I.CCI_FIID;
        RAISE EXP_REJECT_RECORD;
       WHEN OTHERS THEN
        V_ERRMSG := 'Error while selecting branch code for  ' ||
                  I.CCI_FIID || '  ' || SUBSTR(SQLERRM, 1, 200);
        RAISE EXP_REJECT_RECORD;
     END;

     --En find Branch
    IF v_encrypt_enable = 'Y' THEN
		 v_encr_firstname := fn_dmaps_main(I.CCI_SEG12_NAME_LINE1);                
         v_encr_lastname := fn_dmaps_main(I.CCI_SEG12_NAME_LINE2);                 
 		 v_encr_p_add_one := fn_dmaps_main(I.CCI_SEG12_ADDR_LINE1);          
		 v_encr_m_add_one := fn_dmaps_main(I.CCI_SEG13_ADDR_LINE1);                                               
		 v_encr_mothers_name := fn_dmaps_main(I.CCI_MOTHERS_MAIDEN_NAME);                                           
	ELSE
		 v_encr_firstname := I.CCI_SEG12_NAME_LINE1;                
         v_encr_lastname := I.CCI_SEG12_NAME_LINE2;                
 		 v_encr_p_add_one := I.CCI_SEG12_ADDR_LINE1;         
		 v_encr_m_add_one := I.CCI_SEG13_ADDR_LINE1;                                               
		 v_encr_mothers_name := I.CCI_MOTHERS_MAIDEN_NAME;                                           
	END IF;
     --Sn find customer
     BEGIN
       SELECT CCM_CUST_CODE
        INTO V_CUST_CODE
        FROM CMS_CUST_MAST
        WHERE CCM_INST_CODE = P_INSTCODE
            AND CCM_CUST_ID = I.CCI_CUST_ID;

       BEGIN
        SELECT CAM_ADDR_CODE
          INTO V_COMM_ADDRCODE
          FROM CMS_ADDR_MAST
         WHERE CAM_INST_CODE = P_INSTCODE AND
              CAM_CUST_CODE = V_CUST_CODE AND CAM_ADDR_FLAG = 'P';
       EXCEPTION
        WHEN NO_DATA_FOUND THEN
          RAISE EXP_REJECT_RECORD;
        WHEN TOO_MANY_ROWS THEN
          RAISE EXP_REJECT_RECORD;
        WHEN OTHERS THEN
          RAISE EXP_REJECT_RECORD;
       END;
     EXCEPTION
       WHEN NO_DATA_FOUND THEN
        --------------------If customer is not Found in table then we create Customer and address (As discussed with Shyamjit on 020909)------

        --Sn assign records to customer gen variable
        BEGIN
          SELECT TYPE_CUST_REC_ARRAY(I.CCI_CUSTOMER_PARAM1,
                                I.CCI_CUSTOMER_PARAM2,
                                I.CCI_CUSTOMER_PARAM3,
                                I.CCI_CUSTOMER_PARAM4,
                                I.CCI_CUSTOMER_PARAM5,
                                I.CCI_CUSTOMER_PARAM6,
                                I.CCI_CUSTOMER_PARAM7,
                                I.CCI_CUSTOMER_PARAM8,
                                I.CCI_CUSTOMER_PARAM9,
                                I.CCI_CUSTOMER_PARAM10)
            INTO V_CUST_DATA
            FROM DUAL;
        EXCEPTION
          WHEN OTHERS THEN
            V_ERRMSG := 'Error while cutomer gen data ' ||
                     SUBSTR(SQLERRM, 1, 200);
            RAISE EXP_REJECT_RECORD;
        END;

        --En assign records to customer gen variable

        --Sn create customer
        BEGIN
          SELECT DECODE(I.CCI_TITLE,
                     'Mr.',
                     'M',
                     'Mrs.',
                     'F',
                     'Miss.',
                     'F',
                     'Dr.',
                     'D'), decode(I.CCI_DOCUMENT_VERIFY,'SSN',NVL(fn_dmaps_main(I.CCI_SSN_ENCR),I.CCI_SSN),NVL(fn_dmaps_main(I.CCI_ID_NUMBER_ENCR),I.CCI_ID_NUMBER)) --Added by Pankaj S. on 13-Feb-2013 during Multiple SSN check changes
            INTO V_GENDER,V_IDVALUE
            FROM DUAL;

          SP_CREATE_CUST(P_INSTCODE,
                      1,
                      0,
                      'Y',
                      I.CCI_TITLE,
                      v_encr_firstname,
                      NULL,
                      --BEGIN changes by T.Narayanan for  Last Name  not stored in CMS_CUST_MAST
                      v_encr_lastname,
                      --END changes by T.Narayanan for  Last Name  not stored in CMS_CUST_MAST
                      I.CCI_BIRTH_DATE,
                      V_GENDER,
                      NULL,
                      NULL,
                      NULL,
                      NULL,
                      NULL,
                      NULL,
                      P_LUPDUSER,
                      V_IDVALUE, --Added by Pankaj S. on 13-Feb-2013 during Multiple SSN check changes
                      v_encr_mothers_name,
                      I.CCI_HOBBIES,
                      I.CCI_EMP_ID,
                      V_CATG_CODE,
                      I.CCI_CUST_ID,
                      V_CUST_DATA,
                      i.cci_prod_code,  --Added for Partner ID Changes
                      i.cci_card_type,
                      V_CUST_CODE,
                      V_ERRMSG);

          IF V_ERRMSG <> 'OK' THEN
            V_ERRMSG := 'Error from create cutomer ' || V_ERRMSG;
            RAISE EXP_REJECT_RECORD;
          END IF;
          --Sn Added by Pankaj S. on 13-Feb-2013 during Multiple SSN check changes
          BEGIN 
          IF I.CCI_DOCUMENT_VERIFY = 'SSN' THEN   --Modified for (Mantis ID-10549)
          UPDATE CMS_CUST_MAST
             SET CCM_ID_TYPE = I.CCI_DOCUMENT_VERIFY
           WHERE CCM_INST_CODE=P_INSTCODE
             AND CCM_CUST_CODE=V_CUST_CODE;
          ELSE 
          UPDATE CMS_CUST_MAST
             SET CCM_ID_TYPE = I.CCI_DOCUMENT_VERIFY,
                 CCM_ID_ISSUER = I.CCI_ID_ISSUER,
                 CCM_IDISSUENCE_DATE = I.CCI_ID_ISSUANCE_DATE,
                 CCM_IDEXPRY_DATE = I.CCI_ID_EXPIRY_DATE
           WHERE CCM_INST_CODE=P_INSTCODE
             AND CCM_CUST_CODE=V_CUST_CODE;
          END IF;   
          EXCEPTION
          WHEN OTHERS THEN
            V_ERRMSG := 'Error while updating customer ID details ' ||
                     SUBSTR(SQLERRM, 1, 200);
            RAISE EXP_REJECT_RECORD;
            END;
           
           --En Added by Pankaj S. on 13-Feb-2013 during Multiple SSN check changes
        EXCEPTION
          WHEN EXP_REJECT_RECORD THEN
            RAISE;
          WHEN OTHERS THEN
            V_ERRMSG := 'Error while create customer ' ||
                     SUBSTR(SQLERRM, 1, 200);
            RAISE EXP_REJECT_RECORD;
        END;

        --En create customer
        --Sn create communication address
        SELECT DECODE(I.CCI_COMM_TYPE,
                    '0',
                    decode(V_ENCRYPT_ENABLE,'Y', fn_dmaps_main(I.CCI_SEG12_ADDR_LINE1),I.CCI_SEG12_ADDR_LINE1),
                    decode(V_ENCRYPT_ENABLE,'Y', fn_dmaps_main(I.CCI_SEG13_ADDR_LINE1),I.CCI_SEG13_ADDR_LINE1)),
              DECODE(I.CCI_COMM_TYPE,
                    '0',
                    decode(V_ENCRYPT_ENABLE,'Y', fn_dmaps_main(I.CCI_SEG12_ADDR_LINE2),I.CCI_SEG12_ADDR_LINE2),
                    decode(V_ENCRYPT_ENABLE,'Y', fn_dmaps_main(I.CCI_SEG13_ADDR_LINE2),I.CCI_SEG13_ADDR_LINE2)),
              DECODE(I.CCI_COMM_TYPE,
                    '0',
                    decode(V_ENCRYPT_ENABLE,'Y', fn_dmaps_main(I.CCI_SEG12_POSTAL_CODE),I.CCI_SEG12_POSTAL_CODE),
                    decode(V_ENCRYPT_ENABLE,'Y', fn_dmaps_main(I.CCI_SEG13_HOMEPHONE_NO),I.CCI_SEG13_HOMEPHONE_NO)),
              DECODE(I.CCI_COMM_TYPE,
                    '0',
                    decode(V_ENCRYPT_ENABLE,'Y', fn_dmaps_main(I.CCI_SEG12_HOMEPHONE_NO),I.CCI_SEG12_HOMEPHONE_NO),
                    decode(V_ENCRYPT_ENABLE,'Y', fn_dmaps_main(I.CCI_SEG13_HOMEPHONE_NO),I.CCI_SEG13_HOMEPHONE_NO)),
              DECODE(I.CCI_COMM_TYPE,
                    '0',
                    decode(V_ENCRYPT_ENABLE,'Y', fn_dmaps_main(I.CCI_SEG12_MOBILENO),I.CCI_SEG12_MOBILENO),
                    decode(V_ENCRYPT_ENABLE,'Y', fn_dmaps_main(I.CCI_SEG13_MOBILENO),I.CCI_SEG13_MOBILENO)),
              DECODE(I.CCI_COMM_TYPE,
                    '0',
                    I.CCI_SEG12_OFFICEPHONE_NO,
                    I.CCI_SEG13_OFFICEPHONE_NO),
              DECODE(I.CCI_COMM_TYPE,
                    '0',
                    decode(V_ENCRYPT_ENABLE,'Y', fn_dmaps_main(I.CCI_SEG12_EMAILID),I.CCI_SEG12_EMAILID),
                    decode(V_ENCRYPT_ENABLE,'Y', fn_dmaps_main(I.CCI_SEG13_EMAILID),I.CCI_SEG13_EMAILID)),
              DECODE(I.CCI_COMM_TYPE,
                    '0',
                    decode(V_ENCRYPT_ENABLE,'Y', fn_dmaps_main(I.CCI_SEG12_CITY),I.CCI_SEG12_CITY),
                    decode(V_ENCRYPT_ENABLE,'Y', fn_dmaps_main(I.CCI_SEG13_CITY),I.CCI_SEG13_CITY)),
              DECODE(I.CCI_COMM_TYPE,
                    '0',
                    I.CCI_SEG12_STATE,
                    I.CCI_SEG13_STATE),
              DECODE(I.CCI_COMM_TYPE,
                    '0',
                    I.CCI_SEG12_COUNTRY_CODE,
                    I.CCI_SEG13_COUNTRY_CODE),
              --Sn assign other gen comm adddress
              TYPE_ADDR_REC_ARRAY(DECODE(I.CCI_COMM_TYPE,
                                    '0',
                                    I.CCI_SEG12_ADDR_PARAM1,
                                    I.CCI_SEG13_ADDR_PARAM1),
                              DECODE(I.CCI_COMM_TYPE,
                                    '0',
                                    I.CCI_SEG12_ADDR_PARAM2,
                                    I.CCI_SEG13_ADDR_PARAM2),
                              DECODE(I.CCI_COMM_TYPE,
                                    '0',
                                    I.CCI_SEG12_ADDR_PARAM3,
                                    I.CCI_SEG13_ADDR_PARAM3),
                              DECODE(I.CCI_COMM_TYPE,
                                    '0',
                                    I.CCI_SEG12_ADDR_PARAM4,
                                    I.CCI_SEG13_ADDR_PARAM4),
                              DECODE(I.CCI_COMM_TYPE,
                                    '0',
                                    I.CCI_SEG12_ADDR_PARAM5,
                                    I.CCI_SEG13_ADDR_PARAM5),
                              DECODE(I.CCI_COMM_TYPE,
                                    '0',
                                    I.CCI_SEG12_ADDR_PARAM6,
                                    I.CCI_SEG13_ADDR_PARAM6),
                              DECODE(I.CCI_COMM_TYPE,
                                    '0',
                                    I.CCI_SEG12_ADDR_PARAM7,
                                    I.CCI_SEG13_ADDR_PARAM7),
                              DECODE(I.CCI_COMM_TYPE,
                                    '0',
                                    I.CCI_SEG12_ADDR_PARAM8,
                                    I.CCI_SEG13_ADDR_PARAM8),
                              DECODE(I.CCI_COMM_TYPE,
                                    '0',
                                    I.CCI_SEG12_ADDR_PARAM9,
                                    I.CCI_SEG13_ADDR_PARAM9),
                              DECODE(I.CCI_COMM_TYPE,
                                    '0',
                                    I.CCI_SEG12_ADDR_PARAM10,
                                    I.CCI_SEG13_ADDR_PARAM10)),
              --En assign other gen comm address
              DECODE(I.CCI_COMM_TYPE,
                    '0',
                    decode(V_ENCRYPT_ENABLE,'Y', fn_dmaps_main(I.CCI_SEG13_ADDR_LINE1),I.CCI_SEG13_ADDR_LINE1),
                    decode(V_ENCRYPT_ENABLE,'Y', fn_dmaps_main(I.CCI_SEG12_ADDR_LINE1),I.CCI_SEG12_ADDR_LINE1)),
              DECODE(I.CCI_COMM_TYPE,
                    '0',
                    decode(V_ENCRYPT_ENABLE,'Y', fn_dmaps_main(I.CCI_SEG13_ADDR_LINE2),I.CCI_SEG13_ADDR_LINE2),
                    decode(V_ENCRYPT_ENABLE,'Y', fn_dmaps_main(I.CCI_SEG12_ADDR_LINE2),I.CCI_SEG12_ADDR_LINE2)),
              DECODE(I.CCI_COMM_TYPE,
                    '0',
                    decode(V_ENCRYPT_ENABLE,'Y', fn_dmaps_main(I.CCI_SEG13_POSTAL_CODE),I.CCI_SEG13_POSTAL_CODE),
                    decode(V_ENCRYPT_ENABLE,'Y', fn_dmaps_main(I.CCI_SEG12_POSTAL_CODE),I.CCI_SEG12_POSTAL_CODE)),
              DECODE(I.CCI_COMM_TYPE,
                    '0',
                    decode(V_ENCRYPT_ENABLE,'Y', fn_dmaps_main(I.CCI_SEG13_HOMEPHONE_NO),I.CCI_SEG13_HOMEPHONE_NO),
                    decode(V_ENCRYPT_ENABLE,'Y', fn_dmaps_main(I.CCI_SEG12_HOMEPHONE_NO),I.CCI_SEG12_HOMEPHONE_NO)),
              DECODE(I.CCI_COMM_TYPE,
                    '0',
                    decode(V_ENCRYPT_ENABLE,'Y', fn_dmaps_main(I.CCI_SEG13_MOBILENO),I.CCI_SEG13_MOBILENO),
                    decode(V_ENCRYPT_ENABLE,'Y', fn_dmaps_main(I.CCI_SEG12_MOBILENO),I.CCI_SEG12_MOBILENO)),
              DECODE(I.CCI_COMM_TYPE,
                    '0',
                    I.CCI_SEG13_OFFICEPHONE_NO,
                    I.CCI_SEG12_OFFICEPHONE_NO),
              DECODE(I.CCI_COMM_TYPE,
                    '0',
                    decode(V_ENCRYPT_ENABLE,'Y', fn_dmaps_main(I.CCI_SEG13_EMAILID),I.CCI_SEG13_EMAILID),
                    decode(V_ENCRYPT_ENABLE,'Y', fn_dmaps_main(I.CCI_SEG12_EMAILID),I.CCI_SEG12_EMAILID)),
              DECODE(I.CCI_COMM_TYPE,
                    '0',
                    decode(V_ENCRYPT_ENABLE,'Y', fn_dmaps_main(I.CCI_SEG13_CITY),I.CCI_SEG13_CITY),
                    decode(V_ENCRYPT_ENABLE,'Y', fn_dmaps_main(I.CCI_SEG12_CITY),I.CCI_SEG12_CITY)),
              DECODE(I.CCI_COMM_TYPE,
                    '0',
                    I.CCI_SEG13_STATE,
                    I.CCI_SEG12_STATE),
              DECODE(I.CCI_COMM_TYPE,
                    '0',
                    I.CCI_SEG13_COUNTRY_CODE,
                    I.CCI_SEG12_COUNTRY_CODE),
              --Sn assign other gen comm adddress
              TYPE_ADDR_REC_ARRAY(DECODE(I.CCI_COMM_TYPE,
                                    '0',
                                    I.CCI_SEG13_ADDR_PARAM1,
                                    I.CCI_SEG12_ADDR_PARAM1),
                              DECODE(I.CCI_COMM_TYPE,
                                    '0',
                                    I.CCI_SEG13_ADDR_PARAM2,
                                    I.CCI_SEG12_ADDR_PARAM2),
                              DECODE(I.CCI_COMM_TYPE,
                                    '0',
                                    I.CCI_SEG13_ADDR_PARAM3,
                                    I.CCI_SEG12_ADDR_PARAM3),
                              DECODE(I.CCI_COMM_TYPE,
                                    '0',
                                    I.CCI_SEG13_ADDR_PARAM4,
                                    I.CCI_SEG12_ADDR_PARAM4),
                              DECODE(I.CCI_COMM_TYPE,
                                    '0',
                                    I.CCI_SEG13_ADDR_PARAM5,
                                    I.CCI_SEG12_ADDR_PARAM5),
                              DECODE(I.CCI_COMM_TYPE,
                                    '0',
                                    I.CCI_SEG13_ADDR_PARAM6,
                                    I.CCI_SEG12_ADDR_PARAM6),
                              DECODE(I.CCI_COMM_TYPE,
                                    '0',
                                    I.CCI_SEG13_ADDR_PARAM7,
                                    I.CCI_SEG12_ADDR_PARAM7),
                              DECODE(I.CCI_COMM_TYPE,
                                    '0',
                                    I.CCI_SEG13_ADDR_PARAM8,
                                    I.CCI_SEG12_ADDR_PARAM8),
                              DECODE(I.CCI_COMM_TYPE,
                                    '0',
                                    I.CCI_SEG13_ADDR_PARAM9,
                                    I.CCI_SEG12_ADDR_PARAM9),
                              DECODE(I.CCI_COMM_TYPE,
                                    '0',
                                    I.CCI_SEG13_ADDR_PARAM10,
                                    I.CCI_SEG12_ADDR_PARAM10))
        --En assign other gen comm address
          INTO V_COMM_ADDR_LIN1,
              V_COMM_ADDR_LIN2,
              V_COMM_POSTAL_CODE,
              V_COMM_HOMEPHONE_NO,
              V_COMM_MOBILENO,
              V_COMM_OFFICENO,
              V_COMM_EMAILID,
              V_COMM_CITY,
              V_COMM_STATE,
              V_COMM_CNTRYCODE,
              V_ADDR_DATA1,
              V_OTHER_ADDR_LIN1,
              V_OTHER_ADDR_LIN2,
              V_OTHER_POSTAL_CODE,
              V_OTHER_HOMEPHONE_NO,
              V_OTHER_MOBILENO,
              V_OTHER_OFFICENO,
              V_OTHER_EMAILID,
              V_OTHER_CITY,
              V_OTHER_STATE,
              V_OTHER_CNTRYCODE,
              V_ADDR_DATA2
          FROM DUAL;

        IF V_COMM_ADDR_LIN1 IS NOT NULL THEN
          IF V_COMM_ADDR_LIN1 = v_encr_p_add_one THEN
            V_COMM_TYPE := 'R';
          ELSIF V_COMM_ADDR_LIN1 = v_encr_m_add_one THEN
            V_COMM_TYPE := 'O';
          END IF;

          BEGIN

            SELECT GCM_CNTRY_CODE
             INTO V_GCM_CNTRY_CODE
             FROM GEN_CNTRY_MAST
            WHERE GCM_CNTRY_CODE = V_COMM_CNTRYCODE AND
                 GCM_INST_CODE = P_INSTCODE;

            SP_CREATE_ADDR(P_INSTCODE,
                        V_CUST_CODE,
                        V_COMM_ADDR_LIN1,
                        V_COMM_ADDR_LIN2,
                        NULL,
                        V_COMM_POSTAL_CODE,
                        V_COMM_HOMEPHONE_NO,
                        V_COMM_MOBILENO,
                        V_COMM_OFFICENO,
                        V_COMM_EMAILID,
                        V_GCM_CNTRY_CODE,
                        V_COMM_CITY,
                        V_COMM_STATE,
                        NULL,
                        'P',
                        V_COMM_TYPE,
                        P_LUPDUSER,
                        V_ADDR_DATA1,
                        V_COMM_ADDRCODE,
                        V_ERRMSG);

            IF V_ERRMSG <> 'OK' THEN
             V_ERRMSG := 'Error from create communication address ' ||
                       V_ERRMSG;
             RAISE EXP_REJECT_RECORD;
            END IF;
          EXCEPTION
            WHEN EXP_REJECT_RECORD THEN
             RAISE;
            WHEN OTHERS THEN
             V_ERRMSG := 'Error while create communication address ' ||
                       SUBSTR(SQLERRM, 1, 200);
             RAISE EXP_REJECT_RECORD;
          END;
        END IF;

        --En create communication address
        --Sn create other address
        IF V_OTHER_ADDR_LIN1 IS NOT NULL THEN
          IF V_COMM_ADDR_LIN1 = v_encr_p_add_one THEN
            V_COMM_TYPE := 'R';
          ELSIF V_COMM_ADDR_LIN1 = v_encr_m_add_one THEN
            V_COMM_TYPE := 'O';
          END IF;

          BEGIN

            SELECT GCM_CNTRY_CODE
             INTO V_GCM_OTHERCNTRY_CODE
             FROM GEN_CNTRY_MAST
            WHERE GCM_CNTRY_CODE = V_OTHER_CNTRYCODE AND
                 GCM_INST_CODE = P_INSTCODE;

            SP_CREATE_ADDR(P_INSTCODE,
                        V_CUST_CODE,
                        V_OTHER_ADDR_LIN1,
                        V_OTHER_ADDR_LIN2,
                        NULL,
                        V_OTHER_POSTAL_CODE,
                        V_OTHER_HOMEPHONE_NO,
                        V_OTHER_MOBILENO,
                        V_OTHER_OFFICENO,
                        V_OTHER_EMAILID,
                        V_GCM_OTHERCNTRY_CODE,
                        V_OTHER_CITY,
                        V_OTHER_STATE,
                        NULL,
                        'O',
                        V_COMM_TYPE,
                        P_LUPDUSER,
                        V_ADDR_DATA2,
                        V_OTHER_ADDRCODE,
                        V_ERRMSG);

            IF V_ERRMSG <> 'OK' THEN
             V_ERRMSG := 'Error from create communication address ' ||
                       V_ERRMSG;
             RAISE EXP_REJECT_RECORD;
            END IF;
          EXCEPTION
            WHEN EXP_REJECT_RECORD THEN
             RAISE;
            WHEN OTHERS THEN
             V_ERRMSG := 'Error while create communication address ' ||
                       SUBSTR(SQLERRM, 1, 200);
             RAISE EXP_REJECT_RECORD;
          END;
        END IF;
        --En create other address
       WHEN EXP_REJECT_RECORD THEN
        V_ERRMSG := 'Error while selecting customer from master ' ||
                  SUBSTR(SQLERRM, 1, 200);
        RAISE;
       WHEN OTHERS THEN
        V_ERRMSG := 'Error while selecting customer from master ' ||
                  SUBSTR(SQLERRM, 1, 200);
        RAISE EXP_REJECT_RECORD;
     END;

     --En find customer

     -- Sn create account
     --Sn select acct type
     BEGIN
       SELECT CAT_TYPE_CODE
        INTO V_ACCT_TYPE
        FROM CMS_ACCT_TYPE
        WHERE CAT_INST_CODE = P_INSTCODE AND
            CAT_SWITCH_TYPE = V_SWITCH_ACCT_TYPE;
     EXCEPTION
       WHEN NO_DATA_FOUND THEN
        V_ERRMSG := 'Acct type not defined in master';
        RAISE EXP_REJECT_RECORD;
       WHEN OTHERS THEN
        V_ERRMSG := 'Error while selecting accttype ' ||
                  SUBSTR(SQLERRM, 1, 200);
        RAISE EXP_REJECT_RECORD;
     END;

     --En select acct type
     --Sn select acct stat
     BEGIN
       SELECT CAS_STAT_CODE
        INTO V_ACCT_STAT
        FROM CMS_ACCT_STAT
        WHERE CAS_INST_CODE = P_INSTCODE AND
            CAS_SWITCH_STATCODE = V_SWITCH_ACCT_STAT;
     EXCEPTION
       WHEN NO_DATA_FOUND THEN
        V_ERRMSG := 'Acct stat not defined for  master';
        RAISE EXP_REJECT_RECORD;
       WHEN OTHERS THEN
        V_ERRMSG := 'Error while selecting accttype ' ||
                  SUBSTR(SQLERRM, 1, 200);
        RAISE EXP_REJECT_RECORD;
     END;

     --En select acct stat

     IF V_CATG_CODE = 'P' THEN
       --v_acct_numb := NULL;
       --Added one more argument for card type
       SP_ACCOUNT_CONSTRUCT(P_INSTCODE,
                        I.CCI_FIID,
                        I.CCI_PROD_CODE,
                        P_LUPDUSER,
                        V_PROD_CATTYPE, --Added by ram.Mk
                        T_ACCT_NUM,
                        V_ERRMSG);
       IF V_ERRMSG <> 'OK' THEN
        V_ERRMSG := 'Error from create acct ' || V_ERRMSG;
        RAISE EXP_REJECT_RECORD;

       ELSE

        V_ACCT_NUMB := T_ACCT_NUM;

       END IF;

     ELSIF V_CATG_CODE = 'D' THEN
       V_ACCT_NUMB := I.CCI_SEG31_NUM;
     END IF;

     --Sn create acct
     BEGIN
       SP_CREATE_ACCT_PCMS(P_INSTCODE,
                       V_ACCT_NUMB,
                       0,
                       I.CCI_FIID,
                       V_COMM_ADDRCODE,
                       V_ACCT_TYPE,
                       V_ACCT_STAT,
                       P_LUPDUSER,
                       i.cci_prod_code,
                       i.cci_card_type,
                       V_DUP_FLAG,
                       V_ACCT_ID,
                       V_ERRMSG);

       IF V_ERRMSG <> 'OK' THEN
        V_ERRMSG := 'Error from create acct ' || V_ERRMSG;
        RAISE EXP_REJECT_RECORD;
       END IF;
     EXCEPTION
       WHEN EXP_REJECT_RECORD THEN
        RAISE;
       WHEN OTHERS THEN
        V_ERRMSG := 'Error while create acct ' || SUBSTR(SQLERRM, 1, 200);
        RAISE EXP_REJECT_RECORD;
     END;

     --En create acct

     --Sn create a entry in cms_cust_acct
     BEGIN
       UPDATE CMS_ACCT_MAST
         SET CAM_HOLD_COUNT = CAM_HOLD_COUNT + 1,
            CAM_LUPD_USER  = P_LUPDUSER
        WHERE CAM_INST_CODE = P_INSTCODE AND CAM_ACCT_ID = V_ACCT_ID;

       IF SQL%ROWCOUNT = 0 THEN
        V_ERRMSG := 'Error while update acct ' || SUBSTR(SQLERRM, 1, 200);
        RAISE EXP_REJECT_RECORD;
       END IF;
     END;

     SP_CREATE_HOLDER(P_INSTCODE,
                   V_CUST_CODE,
                   V_ACCT_ID,
                   NULL,
                   P_LUPDUSER,
                   V_HOLDPOSN,
                   V_ERRMSG);

     IF V_ERRMSG <> 'OK' THEN
       V_ERRMSG := 'Error from create entry cust_acct ' || V_ERRMSG;
       RAISE EXP_REJECT_RECORD;
     END IF;

     ---En create a entry in cms_cust_acct

     -- En create account
     -- Sn create Application

     -- Sn find expry param

    IF v_encrypt_enable = 'Y' THEN
	    v_encr_firstname := SUBSTR(fn_dmaps_main(I.CCI_SEG12_NAME_LINE1), 1, 30);     
    ELSE
        v_encr_firstname := SUBSTR(I.CCI_SEG12_NAME_LINE1, 1, 30);     
    END IF;	
     -- Sn Appl
     BEGIN
       SP_CREATE_APPL_PCMS(P_INSTCODE,
                       1,
                       1,
                       I.CCI_APPL_NO,
                       SYSDATE,
                       SYSDATE,
                       V_CUST_CODE,
                       I.CCI_FIID,
                       V_PROD_CODE,
                       V_PROD_CATTYPE,
                       V_CUSTCATG, --customer category
                       SYSDATE,
                       V_EXPRY_DATE,
                       v_encr_firstname,
                       0,
                       'N',
                       NULL,
                       1,
                       --total account count  = 1 since in upload a card is associated with only one account
                       'P', --addon status always a primary application
                       0, --addon link 0 means that the appln is for promary pan
                       V_COMM_ADDRCODE, --billing address
                       NULL, --channel code
                       NULL,
                       I.CCI_PAYREF_NO,
                       P_LUPDUSER,
                       P_LUPDUSER,
                       TO_NUMBER(I.CCI_PROD_AMT),
                       V_APPL_CODE, --out param
                       V_ERRMSG);

       IF V_ERRMSG <> 'OK' THEN
        V_ERRMSG := 'Error from create appl ' || V_ERRMSG;
        RAISE EXP_REJECT_RECORD;
       END IF;
     EXCEPTION
       WHEN EXP_REJECT_RECORD THEN
        RAISE;
       WHEN OTHERS THEN
        V_ERRMSG := 'Error while create appl ' || SUBSTR(SQLERRM, 1, 200);
        RAISE EXP_REJECT_RECORD;
     END;

     -- En Appl
     -- Sn create entry in appl_det
     BEGIN
       SP_CREATE_APPLDET(P_INSTCODE,
                     V_APPL_CODE,
                     V_ACCT_ID,
                     1,
                     P_LUPDUSER,
                     V_ERRMSG);

       IF V_ERRMSG <> 'OK' THEN
        V_ERRMSG := 'Error from create appl det ' || V_ERRMSG;
        RAISE EXP_REJECT_RECORD;
       END IF;
     EXCEPTION
       WHEN EXP_REJECT_RECORD THEN
        RAISE;
       WHEN OTHERS THEN
        V_ERRMSG := 'Error while create appl det ' ||
                  SUBSTR(SQLERRM, 1, 200);
        RAISE EXP_REJECT_RECORD;
     END;

     -- En create entry in appl_det
     --En create Application

     --Sn mark the record as successful
     UPDATE CMS_CAF_INFO_ENTRY
        SET CCI_APPROVED    = 'O',
           CCI_UPLD_STAT   = 'O',
           CCI_APPL_CODE   = to_char(V_APPL_CODE), --changed from number to varchar
           CCI_PROCESS_MSG = 'Successful'
      WHERE CCI_INST_CODE = P_INSTCODE AND ROWID = I.R;
    /* -- Commented for not required on FSS-1710
     --Sn insert error message in upload log for KYC Flag Approved
     BEGIN
       INSERT INTO PCMS_UPLOAD_LOG
        (PUL_INST_CODE,
         PUL_FILE_NAME,
         PUL_APPL_NO,
         PUL_UPLD_STAT,
         PUL_APPROVE_STAT,
         PUL_INS_DATE,
         PUL_ROW_ID,
         PUL_PROCESS_MESSAGE)
       VALUES
        (P_INSTCODE,
         I.CCI_FILE_NAME,
         I.CCI_APPL_NO,
         'O',
         'O',
         SYSDATE,
         I.CCI_ROW_ID,
         'Successful');

       IF SQL%ROWCOUNT = 0 THEN
        V_ERRMSG := 'Error While inserting record in log table';
        ROLLBACK TO V_SAVEPOINT;
       END IF;
     EXCEPTION
       WHEN OTHERS THEN
        V_ERRMSG := 'Error While inserting record in log table';
        ROLLBACK TO V_SAVEPOINT;
     END;
     --En insert error message in upload log for instrument realization
     */
     V_SAVEPOINT := V_SAVEPOINT + 1;
    EXCEPTION
     WHEN EXP_PROCESS_RECORD THEN
       ROLLBACK TO V_SAVEPOINT;

       UPDATE CMS_CAF_INFO_ENTRY
         SET CCI_APPROVED    = 'A',
            CCI_UPLD_STAT   = 'P',
            CCI_PROCESS_MSG = V_ERRMSG
        WHERE CCI_INST_CODE = P_INSTCODE AND ROWID = I.R;
      /* -- Commented for not required on FSS-1710
       BEGIN
        INSERT INTO PCMS_UPLOAD_LOG
          (PUL_INST_CODE,
           PUL_FILE_NAME,
           PUL_APPL_NO,
           PUL_UPLD_STAT,
           PUL_APPROVE_STAT,
           PUL_INS_DATE,
           PUL_ROW_ID,
           PUL_PROCESS_MESSAGE)
        VALUES
          (P_INSTCODE,
           I.CCI_FILE_NAME,
           I.CCI_APPL_NO,
           'E',
           'A',
           SYSDATE,
           I.CCI_ROW_ID,
           V_ERRMSG);

        IF SQL%ROWCOUNT = 0 THEN
          V_ERRMSG := 'Error While inserting record in log table';
          ROLLBACK TO V_SAVEPOINT;
        END IF;
       EXCEPTION
        WHEN OTHERS THEN
          V_ERRMSG := 'Error While inserting record in log table';
          ROLLBACK TO V_SAVEPOINT;
       END;
       */
     WHEN EXP_REJECT_RECORD THEN
       ROLLBACK TO V_SAVEPOINT;

       UPDATE CMS_CAF_INFO_ENTRY
         SET CCI_APPROVED    = 'A',
            CCI_UPLD_STAT   = 'E',
            CCI_PROCESS_MSG = V_ERRMSG
        WHERE CCI_INST_CODE = P_INSTCODE AND ROWID = I.R;
      /* -- Commented for not required on FSS-1710
       BEGIN
        INSERT INTO PCMS_UPLOAD_LOG
          (PUL_INST_CODE,
           PUL_FILE_NAME,
           PUL_APPL_NO,
           PUL_UPLD_STAT,
           PUL_APPROVE_STAT,
           PUL_INS_DATE,
           PUL_ROW_ID,
           PUL_PROCESS_MESSAGE)
        VALUES
          (P_INSTCODE,
           I.CCI_FILE_NAME,
           I.CCI_APPL_NO,
           'E',
           'A',
           SYSDATE,
           I.CCI_ROW_ID,
           V_ERRMSG);

        IF SQL%ROWCOUNT = 0 THEN
          V_ERRMSG := 'Error While inserting record in log table';
          ROLLBACK TO V_SAVEPOINT;
        END IF;
       EXCEPTION
        WHEN OTHERS THEN
          V_ERRMSG := 'Error While inserting record in log table';
          ROLLBACK TO V_SAVEPOINT;
       END;
       */
     WHEN OTHERS THEN
       /* Added By kaustubh 23-04-09 for inserting record into log table*/
       ROLLBACK TO V_SAVEPOINT;

       UPDATE CMS_CAF_INFO_ENTRY
         SET CCI_APPROVED    = 'A',
            CCI_UPLD_STAT   = 'E',
            CCI_PROCESS_MSG = V_ERRMSG
        WHERE CCI_INST_CODE = P_INSTCODE AND ROWID = I.R;
      /* -- Commented for not required on FSS-1710
       BEGIN
        INSERT INTO PCMS_UPLOAD_LOG
          (PUL_INST_CODE,
           PUL_FILE_NAME,
           PUL_APPL_NO,
           PUL_UPLD_STAT,
           PUL_APPROVE_STAT,
           PUL_INS_DATE,
           PUL_ROW_ID,
           PUL_PROCESS_MESSAGE)
        VALUES
          (P_INSTCODE,
           I.CCI_FILE_NAME,
           I.CCI_APPL_NO,
           'E',
           'A',
           SYSDATE,
           I.CCI_ROW_ID,
           V_ERRMSG);

        IF SQL%ROWCOUNT = 0 THEN
          V_ERRMSG := 'Error While inserting record in log table';
          ROLLBACK TO V_SAVEPOINT;
        END IF;
       EXCEPTION
        WHEN OTHERS THEN
          V_ERRMSG := 'Error While inserting record in log table';
          ROLLBACK TO V_SAVEPOINT;
       END;
       */
    END;
  --En  Loop for record pending for processing
  END LOOP;

  P_ERRMSG := V_ERRMSG;

EXCEPTION

  WHEN OTHERS THEN
    P_ERRMSG := 'Exception from Main ' || SUBSTR(SQLERRM, 1, 300);
END;
/
show error