create or replace PROCEDURE                                                  VMSCMS.SP_GEN_PAN_PREPAID_CMS(P_INSTCODE IN NUMBER,
                                        P_APPLCODE IN NUMBER,
                                        P_LUPDUSER IN NUMBER,
                                        PRM_PRXY_GENFLAG IN VARCHAR2,
                                        P_PAN             OUT VARCHAR2,
                                        P_APPLPROCESS_MSG OUT VARCHAR2,
                                        P_ERRMSG          OUT VARCHAR2) AS

  /*************************************************
      * Created By       :  NA
      * Created Date     :  NA
      * Modified By      : Saravanakumar
      * Modified reason  :  For CR-38 DFC- CCF Changes
      * Modified On      : 28-Dec-2012
      * Reviewer         :
      * Reviewed Date    :
      * Modified By      : Sagar
      * Modified reason  : 1) For SSN validations
                           2) v_resp_cde datatype change
      * Modified On      : 12-Feb-2013
      * Reviewer         : Dhiarj
      * Reviewed Date    : 13-Feb-2013
      * Build Number     : RI0023.2_B0001

      * Modified By       : Pankaj S.
      * Modified Date     : 27-Feb-2013
      * Modified For      : DFCHOST-249
      * Modified Reason   : Update the proxy number of starter card - success proxy msg for GPR card
      * Reviewer          : Dhiraj
      * Reviewed Date     :
      * Release Number    : CMS3.5.1_RI0023.2_B00011

      * Modified By      : Sagar
      * Modified reason  : Performance Issue
      * Modified On      : 25-Mar-2013
      * Reviewer         : Dhiraj
      * Reviewed Date    : 25-Mar-2013
      * Build Number     : CMS3.5.1_RI0024.1_B0002

      * Modified By      : Pankaj S.
      * Modified reason  : Performance Issue(mantis ID-11048)
      * Modified On      : 08-May-2013
      * Reviewer         : Dhiraj
      * Reviewed Date    :
      * Build Number     : CMS3.5.1_RI0024.1_B0017

      * Modified By      :  Siva Arcot
      * Modified reason  :  MVHOST-552
      * Modified On      :  03/09/2013
      * Modified For     :
      * Reviewer         : Dhiraj
      * Reviewed Date    : 03/09/2013
      * Build Number     : RI0024.3.6_B0002

      * Modified by      : MageshKumar.S
      * Modified Reason  : JH-6(Fast50 - Fedral And State Tax Refund Alerts)
      * Modified Date    : 19-09-2013
      * Reviewer         : Dhiraj
      * Reviewed Date    : 19-Sep-2013
      * Build Number     : RI0024.5_B0001

      * Modified by      : MageshKumar S.
      * Modified Date    : 25-July-14
      * Modified For     : FWR-48
      * Modified reason  : GL Mapping removal changes
      * Reviewer         : Spankaj
      * Build Number     : RI0027.3.1_B0001

      * Modified By      : Raja Gopal G
      * Modified Date    : 30-Jul-2014
      * Modified Reason  : Check Deposit Pending ,Accepted And Rejected Alerts(FR 3.2)
      * Reviewer         : Spankaj
      * Build Number     : RI0027.3.1_B0002

      * Modified By      : Ramesh A
      * Modified Date    : 28-Oct-2014
      * Modified Reason  : Defect id : 15848
      * Reviewer         :
      * Build Number     :

    * Modified By      : MAGESHKUMAR S
      * Modified Date    : 16-JAN-2015
      * Modified Reason  : FSS-2072
      * Reviewer         :
      * Build Number     :

    * Modified by                  : MageshKumar S.
    * Modified Date                : 23-June-15
    * Modified For                 : MVCAN-77
    * Modified reason              : Canada account limit check(removed because already handled from  java side)
    * Reviewer                     : Spankaj
    * Build Number                 : VMSGPRHOSTCSD3.1_B0001

    * Modified by                  : Siva Kumar M
    * Modified Date                : 14-Aug-15
    * Modified For                 : FSS-2125
    * Modified reason              : B2B Production Solution
    * Reviewer                     : Spankaj/Saravana Kumar
    * Build Number                 : VMSGPRHOSTCSD3.1_B0002

    * Modified by      : Saravana Kumar A
    * Modified Date    : 23-SEP-15
    * Modified reason  : Card Expiry date logic changes
    * Reviewer         : Spankaj
    * Build Number     : VMSGPRHOST3.2_B0002

    * Modified by                  : Siva Kumar M
    * Modified Date                : 08-Feb-16
    * Modified For                 : DFCTNM-109
    * Modified reason              : Proxy number is not set for gpr card
    * Reviewer                     : Spankaj/Saravana Kumar
    * Build Number                 : VMSGPRHOSTCSD_3.3.2_B0001

       * Modified by       :Siva kumar
       * Modified Date    : 22-Mar-16
       * Modified For     : MVHOST-1323
       * Reviewer         : Saravanankumar/Pankaj
       * Build Number     : VMSGPRHOSTCSD_4.0_B006

    * Modified by                  : MageshKumar S.
    * Modified Date                : 14-June-16
    * Modified For                 : FSS-3927
    * Modified reason              : Canada account limit check
    * Reviewer                     : Saravanakumar/Spankaj
    * Build Number                 : VMSGPRHOSTCSD4.2_B0002

    * Modified By      : MageshKumar S
    * Modified Date    : 18/07/2017
    * Purpose          : FSS-5157
    * Reviewer         : Saravanan/Pankaj S.
    * Release Number   : VMSGPRHOST17.07

     * Modified By      : Pankaj S.
     * Modified Date    : 19-July-2017
     * Purpose          : FSS-5157 (PAN Inventory Changes)
     * Reviewer         : Saravanakumar
     * Release Number   : VMSGPRHOST17.07

     * Modified By      : Akhil
     * Modified Date    : 22-Jan-2018
     * Purpose          : VMS-185
     * Reviewer         : Saravanakumar
     * Release Number   : VMSGPRHOST18.01

     * Modified By      : UBAIDUR RAHMAN.H
     * Modified Date    : 25-JAN-2018
     * Purpose          : VMS-162 (encryption changes)
     * Reviewer         : Vini.P
     * Release Number   : VMSGPRHOST18.01

	 * Modified By      : Vini Pushkaran
     * Modified Date    : 27-Feb-2018
     * Purpose          : VMS-161
     * Reviewer         : Saravanakumar
     * Release Number   : VMSGPRHOST18.02

     * Modified By      : UBAIDUR RAHMAN
     * Modified Date    : 30-July-2018
     * Purpose          : VMS-469
     * Reviewer         : Saravanakumar
     * Release Number   : VMSGPRHOST_R04_B005

     * Modified By      : UBAIDUR RAHMAN
     * Modified Date    : 26-Feb-2020
     * Purpose          : VMS- 1831.
     * Reviewer         : Saravanakumar
     * Release Number   : VMSGPRHOST_R27_B002

     * Modified By      : Pankaj S.
     * Modified Date    : 15-Feb-2023
     * Purpose          : VMS-6655,6843
     * Reviewer         : Venkat S.
     * Release Number   : R78

	 * Modified By      : Bhavani E
     * Modified Date    : 14-Aug-2023
     * Purpose          : VMS-7341
     * Reviewer         : Pankaj S.
     * Release Number   : R84
     
     * Modified By      : Shanmugavel
     * Modified Date    : 23/01/2024
     * Purpose          : VMS-8219-Remove the Default Status in the Product Category Profile Screen on the Host UI
     * Reviewer         : Venkat/John/Pankaj
     * Release Number   : VMSGPRHOSTR92
  *************************************************/

  V_INST_CODE            CMS_APPL_MAST.CAM_INST_CODE%TYPE;
  V_ASSO_CODE            CMS_APPL_MAST.CAM_ASSO_CODE%TYPE;
  V_INST_TYPE            CMS_APPL_MAST.CAM_INST_TYPE%TYPE;
  V_PROD_CODE            CMS_APPL_MAST.CAM_PROD_CODE%TYPE;
  V_APPL_BRAN            CMS_APPL_MAST.CAM_APPL_BRAN%TYPE;
  V_CUST_CODE            CMS_APPL_MAST.CAM_CUST_CODE%TYPE;
  V_CARD_TYPE            CMS_APPL_MAST.CAM_CARD_TYPE%TYPE;
  V_CUST_CATG            CMS_APPL_MAST.CAM_CUST_CATG%TYPE;
  V_DISP_NAME            CMS_APPL_MAST.CAM_DISP_NAME%TYPE;
  V_ACTIVE_DATE          CMS_APPL_MAST.CAM_ACTIVE_DATE%TYPE;
  V_EXPRY_DATE           CMS_APPL_MAST.CAM_EXPRY_DATE%TYPE;
  --V_EXPIRY_DATE          DATE;
  V_ADDON_STAT           CMS_APPL_MAST.CAM_ADDON_STAT%TYPE;
  V_TOT_ACCT             CMS_APPL_MAST.CAM_TOT_ACCT%TYPE;
  V_CHNL_CODE            CMS_APPL_MAST.CAM_CHNL_CODE%TYPE;
  V_LIMIT_AMT            CMS_APPL_MAST.CAM_LIMIT_AMT%TYPE;
  V_USE_LIMIT            CMS_APPL_MAST.CAM_USE_LIMIT%TYPE;
  V_BILL_ADDR            CMS_APPL_MAST.CAM_BILL_ADDR%TYPE;
  V_REQUEST_ID           CMS_APPL_MAST.CAM_REQUEST_ID%TYPE;
  V_APPL_STAT            CMS_APPL_MAST.CAM_APPL_STAT%TYPE;
  V_STARTER_CARD         CMS_APPL_MAST.CAM_STARTER_CARD%TYPE;
  V_BIN                  CMS_BIN_MAST.CBM_INST_BIN%TYPE;
  V_PROFILE_CODE         CMS_PROD_CATTYPE.CPC_PROFILE_CODE%TYPE;
  V_ERRMSG               VARCHAR2(500);
  V_HSM_MODE             CMS_INST_PARAM.CIP_PARAM_VALUE%TYPE;
  V_PINGEN_FLAG          VARCHAR2(1);
  V_EMBOSS_FLAG          VARCHAR2(1);
  V_LOOP_CNT             NUMBER DEFAULT 0;
  V_LOOP_MAX_CNT         NUMBER;
  V_TMP_PAN              CMS_APPL_PAN.CAP_PAN_CODE%TYPE;
  V_NOOF_PAN_PARAM       NUMBER;
  V_INST_BIN             CMS_PROD_BIN.CPB_INST_BIN%TYPE;
  V_SERIAL_INDEX         NUMBER;
  V_SERIAL_MAXLENGTH     NUMBER(2);
  V_SERIAL_NO            NUMBER;
  V_CHECK_DIGIT          NUMBER;
  V_PAN                  CMS_APPL_PAN.CAP_PAN_CODE%TYPE;
  V_ACCT_ID              CMS_ACCT_MAST.CAM_ACCT_ID%TYPE;
  V_ACCT_NUM             CMS_ACCT_MAST.CAM_ACCT_NO%TYPE;
  V_ADONLINK             CMS_APPL_PAN.CAP_PAN_CODE%TYPE;
  V_MBRLINK              CMS_APPL_PAN.CAP_MBR_NUMB%TYPE;
  V_CAM_ADDON_LINK       CMS_APPL_MAST.CAM_ADDON_LINK%TYPE;
  V_PROD_PREFIX          CMS_PROD_CATTYPE.CPC_PROD_PREFIX%TYPE;
 -- V_PROD_PREFIX_GPR          CMS_PROD_CATTYPE.CPC_PROD_PREFIX%TYPE;
  V_CARD_STAT            CMS_APPL_PAN.CAP_CARD_STAT%TYPE;
  V_OFFLINE_ATM_LIMIT    CMS_APPL_PAN.CAP_ATM_OFFLINE_LIMIT%TYPE;
  V_ONLINE_ATM_LIMIT     CMS_APPL_PAN.CAP_ATM_ONLINE_LIMIT%TYPE;
  V_ONLINE_POS_LIMIT     CMS_APPL_PAN.CAP_POS_ONLINE_LIMIT%TYPE;
  V_OFFLINE_POS_LIMIT    CMS_APPL_PAN.CAP_POS_OFFLINE_LIMIT%TYPE;
  V_OFFLINE_AGGR_LIMIT   CMS_APPL_PAN.CAP_OFFLINE_AGGR_LIMIT%TYPE;
  V_ONLINE_AGGR_LIMIT    CMS_APPL_PAN.CAP_ONLINE_AGGR_LIMIT%TYPE;
  V_CPM_CATG_CODE        CMS_PROD_MAST.CPM_CATG_CODE%TYPE;
  V_ISSUEFLAG            VARCHAR2(1);
  V_INITIAL_TOPUP_AMOUNT CMS_APPL_MAST.CAM_INITIAL_TOPUP_AMOUNT%TYPE;
  /*V_FUNC_CODE            CMS_FUNC_MAST.CFM_FUNC_CODE%TYPE;
  V_FUNC_DESC            CMS_FUNC_MAST.CFM_FUNC_DESC%TYPE;
  V_CR_GL_CODE           CMS_FUNC_PROD.CFP_CRGL_CODE%TYPE;
  V_CRGL_CATG            CMS_FUNC_PROD.CFP_CRGL_CATG%TYPE;
  V_CRSUBGL_CODE         CMS_FUNC_PROD.CFP_CRSUBGL_CODE%TYPE;
  V_CRACCT_NO            CMS_FUNC_PROD.CFP_CRACCT_NO%TYPE;
  V_DR_GL_CODE           CMS_FUNC_PROD.CFP_DRGL_CODE%TYPE;
  V_DRGL_CATG            CMS_FUNC_PROD.CFP_DRGL_CATG%TYPE;
  V_DRSUBGL_CODE         CMS_FUNC_PROD.CFP_DRSUBGL_CODE%TYPE;
  V_DRACCT_NO            CMS_FUNC_PROD.CFP_DRACCT_NO%TYPE;
  V_GL_CHECK             NUMBER(1);
  V_SUBGL_DESC           VARCHAR2(30);
  V_TRAN_CODE            CMS_FUNC_MAST.CFM_TXN_CODE%TYPE;
  V_TRAN_MODE            CMS_FUNC_MAST.CFM_TXN_MODE%TYPE;
  V_DELV_CHNL            CMS_FUNC_MAST.CFM_DELIVERY_CHANNEL%TYPE;
  V_TRAN_TYPE            CMS_FUNC_MAST.CFM_TXN_TYPE%TYPE; */ --commented for fwr-48
  --V_EXPRYPARAM           CMS_BIN_PARAM.CBP_PARAM_VALUE%TYPE;
  --V_VALIDITY_PERIOD      CMS_BIN_PARAM.CBP_PARAM_VALUE%TYPE;
  V_SAVEPOINT            NUMBER DEFAULT 1;
  V_EMP_ID               CMS_CUST_MAST.CCM_EMP_ID%TYPE;
  V_CORP_CODE            CMS_CUST_MAST.CCM_CORP_CODE%TYPE;
  V_APPL_DATA            TYPE_APPL_REC_ARRAY;
  V_MBRNUMB              CMS_APPL_PAN.CAP_MBR_NUMB%TYPE;
  --V_PROXY_NUMBER         CMS_APPL_PAN.CAP_PROXY_NUMBER%TYPE;-- Commented for CR -38 DFC- CCF Changes
  --ADded For MMPOS limits
  V_ONLINE_MMPOS_LIMIT  CMS_APPL_PAN.CAP_MMPOS_ONLINE_LIMIT%TYPE;
  V_OFFLINE_MMPOS_LIMIT CMS_APPL_PAN.CAP_MMPOS_OFFLINE_LIMIT%TYPE;
  V_HASH_PAN            CMS_APPL_PAN.CAP_PAN_CODE%TYPE; --aded on 030111
  V_ENCR_PAN            CMS_APPL_PAN.CAP_PAN_CODE_ENCR%TYPE;
  V_GETSEQNO            VARCHAR2(200); --T.Narayanan added for program id
  V_PROGRAMID           VARCHAR2(4); --T.Narayanan added for program id
  V_PROGRAMID_REQ       CMS_PROD_CATTYPE.CPC_PROGRAMID_REQ%type;   -- D.Sreeja added for program id
  V_CHECK_DIGIT_REQ     CMS_PROD_CATTYPE.CPC_CHECK_DIGIT_REQ%TYPE;
  V_ROW_ID              ROWID;        -- D.Sreeja added for program id
  V_SEQNO               CMS_PROGRAM_ID_CNT.CPI_SEQUENCE_NO%TYPE; --T.Narayanan added for program id
  V_PROXYLENGTH         CMS_PROD_MAST.CPM_PROXY_LENGTH%TYPE; -- Commented for CR -38 DFC- CCF Changes
  V_MASK_PAN            CMS_APPL_PAN.CAP_MASK_PAN%TYPE; -- Added by sagar on 06Aug2012 for Pan masking changes
  V_CPC_SERL_FLAG       CMS_PROD_CATTYPE.CPC_SERL_FLAG%TYPE; -- Added by Dhiraj Gaikwad  for Serial Number CR  20022012
  V_DONOT_MARK_ERROR    NUMBER(10) DEFAULT 0;
  V_CAM_FILE_NAME       CMS_APPL_MAST.CAM_FILE_NAME%TYPE;
  V_STARTERGPR_TYPE     CMS_PROD_CATTYPE.CPC_STARTERGPR_ISSUE%TYPE; --Added by T.Narayanan. for gpr card type changes
  V_GPR_CARD_TYPE       CMS_APPL_PAN.CAP_CARD_TYPE%TYPE; --Added by T.Narayanan. for gpr card type changes
  V_STARTER_CARD_FLG    CMS_APPL_PAN.CAP_STARTERCARD_FLAG%TYPE; --Added by T.Narayanan. for gpr card type changes
  V_APPL_COUNT          NUMBER;
  v_proxy_number           cms_appl_pan.cap_proxy_number%TYPE; --added by Pankaj S; on 27_Feb_2013 for DFCHOST-249
  p_shflcntrl_no           NUMBER (9);
  v_pan_inventory_flag     cms_prod_cattype.cpc_pan_inventory_flag%TYPE;  --Added for 17.07 PAN Inventory Changes

   V_TRAN_CODE             VARCHAR2(2) DEFAULT 'IL' ; -- Added for fwr - 48
   V_TRAN_MODE             VARCHAR2(1) DEFAULT '0' ; -- Added for fwr - 48
   V_DELV_CHNL             VARCHAR2(2) DEFAULT '05' ; -- Added for fwr - 48
   V_TRAN_TYPE             VARCHAR2(1) DEFAULT '1' ; -- Added for fwr - 48
   V_FLDOB_HASHKEY_ID      CMS_CUST_MAST.CCM_FLNAMEDOB_HASHKEY%TYPE;  --Added for MVCAN-77 OF 3.1 RELEASE
   v_user_identify_type    cms_prod_cattype.cpc_user_identify_type%type;
   v_ccf_serial_flag       cms_prod_cattype.cpc_ccf_serial_flag%type;
   v_product_id            cms_prod_cattype.cpc_product_id%type;
   v_serial                shuffle_array_typ;
   v_serial_number         cms_appl_pan.cap_serial_number%type;
   v_sweep_flag            cms_prod_cattype.cpc_sweep_flag%type; --Added for Wrong Expiry Date Calc VISA TO MASTER MIGR
   v_expry_arry EXPRY_ARRAY_TYP := EXPRY_ARRAY_TYP (); -- Added for VMS-7341
   v_isexpry_randm          cms_prod_cattype.cpc_expdate_randomization%type; -- Added for VMS-7341
--  TYPE REC_PAN_CONSTRUCT IS RECORD(
--    CPC_PROFILE_CODE CMS_PAN_CONSTRUCT.CPC_PROFILE_CODE%TYPE,
--    CPC_FIELD_NAME   CMS_PAN_CONSTRUCT.CPC_FIELD_NAME%TYPE,
--    CPC_START_FROM   CMS_PAN_CONSTRUCT.CPC_START_FROM%TYPE,
--    CPC_START        CMS_PAN_CONSTRUCT.CPC_START%TYPE,
--    CPC_LENGTH       CMS_PAN_CONSTRUCT.CPC_LENGTH%TYPE,
--    CPC_FIELD_VALUE  VARCHAR2(30));
--
--
--
--  TYPE TABLE_PAN_CONSTRUCT IS TABLE OF REC_PAN_CONSTRUCT INDEX BY BINARY_INTEGER;
--
--  V_TABLE_PAN_CONSTRUCT TABLE_PAN_CONSTRUCT;
  EXP_REJECT_RECORD EXCEPTION;
  V_ENCRYPT_ENABLE          CMS_PROD_CATTYPE.CPC_ENCRYPT_ENABLE%TYPE;

  -------------------------------------------------
  --SN: Added for SSN validation on 12-Feb-2013
  -------------------------------------------------

 -- v_prfl_status           cms_bin_param.cbp_param_value%TYPE;
  v_check_status            NUMBER (3);
  v_ssn_crddtls             varchar2(4000);
  v_resp_cde                VARCHAR2(5);
  v_ssn                     cms_cust_mast.ccm_ssn%type;

  -------------------------------------------------
  --EN: Added for SSN validation on 12-Feb-2013
  -------------------------------------------------

  v_prod_suffix             cms_prod_cattype.cpc_prod_suffix%TYPE;
  v_card_start              cms_prod_cattype.cpc_start_card_no%TYPE;
  v_card_end                cms_prod_cattype.cpc_end_card_no%TYPE;
  v_prodprefx_index         NUMBER;
  v_prefix                  VARCHAR2(10);
  v_toggle_value     cms_inst_param.cip_param_value%TYPE; --VMS-6414 Changes
--  CURSOR C(P_PROFILE_CODE IN VARCHAR2) IS
--    SELECT CPC_PROFILE_CODE,
--         CPC_FIELD_NAME,
--         CPC_START_FROM,
--         CPC_LENGTH,
--         CPC_START
--     FROM CMS_PAN_CONSTRUCT
--    WHERE CPC_PROFILE_CODE = P_PROFILE_CODE AND CPC_INST_CODE = P_INSTCODE
--    ORDER BY CPC_START_FROM DESC;

  CURSOR C1(APPL_CODE IN NUMBER) IS
    SELECT CAD_ACCT_ID, CAD_ACCT_POSN
     FROM CMS_APPL_DET
    WHERE CAD_APPL_CODE = P_APPLCODE AND CAD_INST_CODE = P_INSTCODE;

  --SN    LOCAL PROCEDURES
  PROCEDURE LP_PAN_BIN(P_INSTCODE  IN NUMBER,
                   P_INSTTYPE  IN NUMBER,
                   P_PROD_CODE IN VARCHAR2,
                   P_PAN_BIN   OUT NUMBER,
                   P_ERRMSG    OUT VARCHAR2) IS
  BEGIN
    SELECT CPB_INST_BIN
     INTO P_PAN_BIN
     FROM CMS_PROD_BIN
    WHERE CPB_INST_CODE = P_INSTCODE AND CPB_PROD_CODE = P_PROD_CODE AND
         CPB_ACTIVE_BIN = 'Y';

    P_ERRMSG := 'OK';
  EXCEPTION
    WHEN NO_DATA_FOUND THEN
     P_ERRMSG := 'Excp1 LP1 -- No prefix  found for combination of Institution ' ||
               P_INSTCODE || ' and product ' || P_PROD_CODE;
    WHEN OTHERS THEN
     P_ERRMSG := 'Excp1 LP1 -- ' || SQLERRM;
  END LP_PAN_BIN;

--  PROCEDURE LP_PAN_SRNO(P_INSTCODE   IN NUMBER,
--                    P_LUPDUSER   IN NUMBER,
--                    P_TMP_PAN    IN VARCHAR2,
--                    P_MAX_LENGTH IN NUMBER,
--                    P_SRNO       OUT VARCHAR2,
--                    P_ERRMSG     OUT VARCHAR2) IS
--    V_CTRLNUMB      NUMBER;
--    V_MAX_SERIAL_NO NUMBER;
--    --Sn Added by Pankaj S. on 08_May_2013 for mantis ID-11048
--    excp_reject        EXCEPTION;
--    resource_busy      EXCEPTION;
--    PRAGMA EXCEPTION_INIT (resource_busy, -30006);
--    PRAGMA AUTONOMOUS_TRANSACTION;
--    --En Added by Pankaj S. on 08_May_2013 for mantis ID-11048
--  BEGIN
--    P_ERRMSG := 'OK';
--
--    SELECT CPC_CTRL_NUMB, CPC_MAX_SERIAL_NO
--     INTO V_CTRLNUMB, V_MAX_SERIAL_NO
--     FROM CMS_PAN_CTRL
--    WHERE CPC_PAN_PREFIX = P_TMP_PAN AND CPC_INST_CODE = P_INSTCODE
--    FOR UPDATE WAIT 1; --Modified by Pankaj S. on 08_May_2013 for mantis ID-11048 --Added "For update" for locking select query until update script will execute
--
--    -- IF V_CTRLNUMB > V_MAX_SERIAL_NO THEN
--    IF V_CTRLNUMB > LPAD('9', P_MAX_LENGTH, 9) THEN --Modified by Ramkumar.Mk, check the condition max serial number length
--     P_ERRMSG := 'Maximum serial number reached';
--     RAISE excp_reject; --RETURN; --Modified by Pankaj S. on 08_May_2013 for mantis ID-11048
--    END IF;
--
--    P_SRNO := V_CTRLNUMB;
--
--    --Sn Modified by Pankaj S. on 08_May_2013 for mantis ID-11048
--     BEGIN
--       UPDATE cms_pan_ctrl
--          SET cpc_ctrl_numb = v_ctrlnumb + 1
--        WHERE cpc_pan_prefix = p_tmp_pan AND cpc_inst_code =p_instcode;
--
--       IF SQL%ROWCOUNT = 0
--       THEN
--          p_errmsg := 'Error while updating serial no';
--          RAISE excp_reject;
--       END IF;
--
--       COMMIT;
--    EXCEPTION
--       WHEN excp_reject
--       THEN
--          RAISE;
--       WHEN OTHERS
--       THEN
--          p_errmsg := 'Error While Updating Serial Number ' || SQLERRM;
--          RAISE excp_reject;
--    END;
--    --En Modified by Pankaj S. on 08_May_2013  for mantis ID-11048
--
--  EXCEPTION
--   --Sn Added by Pankaj S. on 08_May_2013 for mantis ID-11048
--    WHEN resource_busy THEN
--      p_errmsg := 'PLEASE TRY AFTER SOME TIME';
--      ROLLBACK;
--    WHEN excp_reject THEN
--      ROLLBACK;
--    --En Added by Pankaj S. on 08_May_2013 for mantis ID-11048
--    WHEN NO_DATA_FOUND THEN
--     INSERT INTO CMS_PAN_CTRL
--       (CPC_INST_CODE, CPC_PAN_PREFIX, CPC_CTRL_NUMB, CPC_MAX_SERIAL_NO)
--     VALUES
--       (P_INSTCODE, P_TMP_PAN, 2, LPAD('9', P_MAX_LENGTH, 9)); --P_INSTCODE added by Pankaj S. on 08_May_2013 for mantis ID-11048
--
--     V_CTRLNUMB := 1;
--     P_SRNO     := V_CTRLNUMB;
--     COMMIT; --Added by Pankaj S. on 08_May_2013 for mantis ID-11048
--    WHEN OTHERS THEN
--     P_ERRMSG := 'Excp1 LP2 -- ' || SQLERRM;
--  END LP_PAN_SRNO;

  PROCEDURE LP_PAN_CHKDIG(P_TMPPAN IN VARCHAR2, P_CHECKDIG OUT NUMBER) IS
    V_CEILABLE_SUM NUMBER := 0;
    V_CEILED_SUM   NUMBER;
    V_TEMP_PAN     NUMBER;
    V_LEN_PAN      NUMBER(3);
    V_RES          NUMBER(3);
    V_MULT_IND     NUMBER(1);
    V_DIG_SUM      NUMBER(2);
    V_DIG_LEN      NUMBER(1);
  BEGIN
    V_TEMP_PAN := P_TMPPAN;
    V_LEN_PAN  := LENGTH(V_TEMP_PAN);
    V_MULT_IND := 2;

    FOR I IN REVERSE 1 .. V_LEN_PAN LOOP
     V_RES     := SUBSTR(V_TEMP_PAN, I, 1) * V_MULT_IND;
     V_DIG_LEN := LENGTH(V_RES);

     IF V_DIG_LEN = 2 THEN
       V_DIG_SUM := SUBSTR(V_RES, 1, 1) + SUBSTR(V_RES, 2, 1);
     ELSE
       V_DIG_SUM := V_RES;
     END IF;

     V_CEILABLE_SUM := V_CEILABLE_SUM + V_DIG_SUM;

     IF V_MULT_IND = 2 THEN
       --IF 2
       V_MULT_IND := 1;
     ELSE
       --Else of If 2
       V_MULT_IND := 2;
     END IF; --End of IF 2
    END LOOP;

    V_CEILED_SUM := V_CEILABLE_SUM;

    IF MOD(V_CEILABLE_SUM, 10) != 0 THEN
     LOOP
       V_CEILED_SUM := V_CEILED_SUM + 1;
       EXIT WHEN MOD(V_CEILED_SUM, 10) = 0;
     END LOOP;
    END IF;

    P_CHECKDIG := V_CEILED_SUM - V_CEILABLE_SUM;
  END LP_PAN_CHKDIG;
PROCEDURE lp_get_proxy (p_programid_in                 VARCHAR2,
                      p_proxylen_in                  VARCHAR2,
                      p_check_digit_request_in       VARCHAR2,
                      p_programid_req_in             VARCHAR2,
                      p_proxy_out                OUT VARCHAR2,
                      p_errmsg_out               OUT VARCHAR2)
AS
 l_seq_no   cms_program_id_cnt.cpi_sequence_no%TYPE;
 l_row_id   ROWID;
 l_excption EXCEPTION;
 PRAGMA AUTONOMOUS_TRANSACTION;
BEGIN
 p_errmsg_out := 'OK';

 IF  p_programid_req_in = 'Y'
 THEN
    BEGIN
       SELECT cpi_sequence_no
         INTO l_seq_no
         FROM cms_program_id_cnt
        WHERE cpi_program_id = p_programid_in
       FOR UPDATE;
    EXCEPTION
       WHEN OTHERS THEN
          p_errmsg_out :='Error while selecting cms_program_id_cnt:'|| SUBSTR (SQLERRM, 1, 200);
          RAISE l_excption;
    END;

    BEGIN
       p_proxy_out :=
          fn_proxy_no (
             NULL,
             NULL,
             p_programid_in,
             l_seq_no,
             p_instcode,
             p_lupduser,
             p_check_digit_request_in,
             p_proxylen_in);
       IF p_proxy_out = '0' THEN
          p_errmsg_out := 'error in proxy number generation';
          RAISE l_excption;
       END IF;
    EXCEPTION
       WHEN OTHERS THEN
          p_errmsg_out :='Error while generating Proxy number:'|| SUBSTR (SQLERRM, 1, 200);
          RAISE l_excption;
    END;
 ELSIF  p_programid_req_in = 'N' THEN
    BEGIN
     SELECT ROWID,LPAD (cpc_prxy_cntrlno, p_proxylen_in, 0)
         INTO l_row_id,p_proxy_out
         FROM cms_prxy_cntrl
        WHERE  cpc_inst_code = p_instcode
              AND cpc_prxy_key = DECODE(p_proxylen_in,7,'PRXYCTRL7',
                                                      8,'PRXYCTRL8',
                                                      9,'PRXYCTRL',
                                                      10,'PRXYCTRL10',
                                                      11,'PRXYCTRL11',
                                                      12,'PRXYCTRL12')
     FOR UPDATE;
    EXCEPTION
       WHEN NO_DATA_FOUND THEN
          p_errmsg_out :='Proxy number not defined for institution: '|| p_instcode;
          RAISE l_excption;
       WHEN OTHERS THEN
          p_errmsg_out :='Error while selecting cms_prxy_cntrl:'|| SUBSTR (SQLERRM, 1, 200);
          RAISE l_excption;
    END;

    BEGIN
       UPDATE cms_prxy_cntrl
          SET cpc_prxy_cntrlno = cpc_prxy_cntrlno + 1,
              cpc_lupd_user = p_lupduser,
              cpc_lupd_date = SYSDATE
        WHERE ROWID =  l_row_id;

       IF SQL%ROWCOUNT = 0 THEN
          p_errmsg_out := 'Proxy number is not updated successfully';
          RAISE l_excption;
       END IF;
    EXCEPTION
       WHEN l_excption THEN
         RAISE;
       WHEN OTHERS THEN
         p_errmsg_out :='Error while updating cms_prxy_cntrl:'|| SUBSTR (SQLERRM, 1, 200);
        RAISE l_excption;
    END;
 END IF;
 COMMIT;
EXCEPTION
 WHEN l_excption THEN
   ROLLBACK;
 WHEN OTHERS THEN
   ROLLBACK;
   p_errmsg_out :='Main Excp:'|| SUBSTR (SQLERRM, 1, 200);
END lp_get_proxy;

--   PROCEDURE lp_shuffle_srno (                                              --Added on 26-Mar-2013 for performace issue
--      p_instcode       IN       NUMBER,
--      p_prod_code               cms_appl_mast.cam_prod_code%TYPE,
--      p_card_type               cms_appl_mast.cam_card_type%TYPE,
--      p_lupduser       IN       NUMBER,
--      p_shflcntrl_no   OUT      VARCHAR2,
--      v_serial_no      OUT      number,
--      p_errmsg         OUT      VARCHAR2
--   )
--   IS
--      v_csc_shfl_cntrl   NUMBER    := 0;
--      excp_reject        EXCEPTION;
--      resource_busy      EXCEPTION;
--      PRAGMA EXCEPTION_INIT (resource_busy, -30006);
--      PRAGMA AUTONOMOUS_TRANSACTION;
--   BEGIN
--      p_errmsg := 'OK';
--
--      BEGIN
--
--         SELECT  csc_shfl_cntrl
--               INTO v_csc_shfl_cntrl
--               FROM cms_shfl_cntrl
--              WHERE csc_inst_code = p_instcode
--                AND csc_prod_code = v_prod_code
--                AND csc_card_type = v_card_type
--         FOR UPDATE WAIT 1;
--
--
--         BEGIN
--
--            SELECT css_serl_numb -- Added on 25-Mar-2013
--              INTO v_serial_no
--              FROM cms_shfl_serl
--             WHERE css_inst_code = p_instcode
--               AND css_prod_code = v_prod_code
--               AND css_prod_catg = v_card_type
--               AND css_shfl_cntrl = v_csc_shfl_cntrl
--               AND css_serl_flag = 0;
--
--
--         EXCEPTION
--            WHEN NO_DATA_FOUND
--            THEN
--               p_errmsg :=
--                  'Shuffle Serial Number Not Found For Product And Product Catagory ';
--               RAISE excp_reject;
--            WHEN OTHERS
--            THEN
--               p_errmsg :=
--                      'Error While Finding Shuffle Serial Number ' || SQLERRM;
--               RAISE excp_reject;
--         END;
--
--
--         BEGIN
--            UPDATE cms_shfl_cntrl
--               SET csc_shfl_cntrl = v_csc_shfl_cntrl + 1
--             WHERE csc_inst_code = p_instcode
--               AND csc_prod_code = v_prod_code
--               AND csc_card_type = v_card_type;
--
--            IF SQL%ROWCOUNT = 0
--            THEN
--               p_errmsg :=
--                  'Shuffle Control Number Not Configuerd For Prodcut and Card Type';
--               RAISE excp_reject;
--               ROLLBACK ;
--            END IF;
--            COMMIT ;
--         EXCEPTION
--            WHEN excp_reject
--            THEN
--               RAISE;
--            WHEN OTHERS
--            THEN
--               p_errmsg :=
--                    'Error While Updating Shuffle Control Number ' || SQLERRM;
--                    ROLLBACK ;
--               RAISE excp_reject;
--
--         END;
--      EXCEPTION
--         WHEN excp_reject
--         THEN
--            RAISE;
--         WHEN NO_DATA_FOUND
--         THEN
--
--            BEGIN
--               INSERT INTO cms_shfl_cntrl
--                           (csc_inst_code, csc_prod_code, csc_card_type,
--                            csc_shfl_cntrl, csc_ins_user
--                           )
--                    VALUES (1, p_prod_code, p_card_type,
--                            2, 1 -- Modified for MVHOST-552 csc_shfl_cntrl is inserted as 2 instead of 1
--                           );
--
--               v_csc_shfl_cntrl := 1;
--               COMMIT;
--            EXCEPTION
--               WHEN OTHERS
--               THEN
--                  p_errmsg :=
--                        'While Inserting into CMS_SHFL_CNTRL  -- ' || SQLERRM;
--                  ROLLBACK;
--            END;
--
--
--            BEGIN
--
--                SELECT css_serl_numb -- Added on 25-Mar-2013
--                  INTO v_serial_no
--                  FROM cms_shfl_serl
--                 WHERE css_inst_code = p_instcode
--                   AND css_prod_code = v_prod_code
--                   AND css_prod_catg = v_card_type
--                   AND css_shfl_cntrl = v_csc_shfl_cntrl
--                   AND css_serl_flag = 0;
--
--
--            EXCEPTION
--                WHEN NO_DATA_FOUND
--                THEN
--                   p_errmsg :=
--                      'Shuffle Serial Number Not Found For Product And Product Catagory ';
--                   RAISE excp_reject;
--                WHEN OTHERS
--                THEN
--                   p_errmsg :=
--                          'Error While Finding Shuffle Serial Number ' || SQLERRM;
--                   RAISE excp_reject;
--            END;
--
--         WHEN resource_busy
--         THEN
--            p_errmsg := 'PLEASE TRY AFTER SOME TIME';
--            RAISE excp_reject;
--         WHEN OTHERS
--         THEN
--            p_errmsg :=
--                    'Error While Fetching Shuffle Control Number ' || SQLERRM;
--            RAISE excp_reject;
--      END;
--
--      p_shflcntrl_no := v_csc_shfl_cntrl;
--   EXCEPTION
--      WHEN excp_reject
--      THEN
--         p_errmsg := p_errmsg;
--         ROLLBACK;
--      WHEN OTHERS
--      THEN
--         p_errmsg := 'Main Exception From LP_SHUFFLE_SRNO ' || SQLERRM;
--         ROLLBACK;
--   END lp_shuffle_srno;
--

  --EN    LOCAL PROCEDURES
BEGIN
  --<< MAIN BEGIN >>
  P_APPLPROCESS_MSG := 'OK';
  P_ERRMSG          := 'OK';

  --Sn generate savepoint number
  BEGIN
    SELECT SEQ_PANGEN_SAVEPOINT.NEXTVAL INTO V_SAVEPOINT FROM DUAL;
  EXCEPTION
    WHEN OTHERS THEN
     V_ERRMSG := 'Error from sequence pangen ' || SUBSTR(SQLERRM, 1, 200);
     RAISE EXP_REJECT_RECORD;
  END;

  --En generate savepoint number
  SAVEPOINT V_SAVEPOINT;

  --Sn find hsm mode
  BEGIN
    SELECT CIP_PARAM_VALUE
     INTO V_HSM_MODE
     FROM CMS_INST_PARAM
    WHERE CIP_PARAM_KEY = 'HSM_MODE' AND CIP_INST_CODE = P_INSTCODE;

    IF V_HSM_MODE = 'Y' THEN
     V_PINGEN_FLAG := 'Y'; -- i.e. generate pin
     V_EMBOSS_FLAG := 'Y'; -- i.e. generate embossa file.
    ELSE
     V_PINGEN_FLAG := 'N'; -- i.e. don't generate pin
     V_EMBOSS_FLAG := 'N'; -- i.e. don't generate embossa file.
    END IF;
  EXCEPTION
    WHEN NO_DATA_FOUND THEN
     V_HSM_MODE    := 'N';
     V_PINGEN_FLAG := 'N'; -- i.e. don't generate pin
     V_EMBOSS_FLAG := 'N'; -- i.e. don't generate embossa file.
  END;

  --En find hsm mode
  --Sn fetch all details from appl_mast
  BEGIN
    --Begin 1 Block Starts Here
    SELECT CAM_INST_CODE,
         CAM_ASSO_CODE,
         CAM_INST_TYPE,
         CAM_PROD_CODE,
         CAM_APPL_BRAN,
         CAM_CUST_CODE,
         CAM_CARD_TYPE,
         CAM_CUST_CATG,
         CAM_DISP_NAME,
         CAM_ACTIVE_DATE,
         CAM_EXPRY_DATE,
         CAM_ADDON_STAT,
         CAM_TOT_ACCT,
         CAM_CHNL_CODE,
         CAM_LIMIT_AMT,
         CAM_USE_LIMIT,
         CAM_BILL_ADDR,
         CAM_REQUEST_ID,
         CAM_APPL_STAT,
         CAM_INITIAL_TOPUP_AMOUNT,
         TYPE_APPL_REC_ARRAY(CAM_APPL_PARAM1,
                         CAM_APPL_PARAM2,
                         CAM_APPL_PARAM3,
                         CAM_APPL_PARAM4,
                         CAM_APPL_PARAM5,
                         CAM_APPL_PARAM6,
                         CAM_APPL_PARAM7,
                         CAM_APPL_PARAM8,
                         CAM_APPL_PARAM9,
                         CAM_APPL_PARAM10),
         CAM_STARTER_CARD,
         CAM_FILE_NAME
    -- Modified By Sivapragasam on Feb 20 2012 for Starter card
     INTO V_INST_CODE,
         V_ASSO_CODE,
         V_INST_TYPE,
         V_PROD_CODE,
         V_APPL_BRAN,
         V_CUST_CODE,
         V_CARD_TYPE,
         V_CUST_CATG,
         V_DISP_NAME,
         V_ACTIVE_DATE,
         V_EXPRY_DATE,
         V_ADDON_STAT,
         V_TOT_ACCT,
         V_CHNL_CODE,
         V_LIMIT_AMT,
         V_USE_LIMIT,
         V_BILL_ADDR,
         V_REQUEST_ID,
         V_APPL_STAT,
         V_INITIAL_TOPUP_AMOUNT,
         V_APPL_DATA,
         V_STARTER_CARD,
         V_CAM_FILE_NAME
     FROM CMS_APPL_MAST
    WHERE CAM_INST_CODE = P_INSTCODE AND CAM_APPL_CODE = P_APPLCODE AND
         CAM_APPL_STAT = 'A';
  EXCEPTION
    --Exception of Begin 1 Block
    WHEN NO_DATA_FOUND THEN
     V_ERRMSG := 'No row found for application code 2' || P_APPLCODE;
     RAISE EXP_REJECT_RECORD;
    WHEN OTHERS THEN
     V_ERRMSG := 'Error while selecting applcode from applmast' ||
               SUBSTR(SQLERRM, 1, 300);
     RAISE EXP_REJECT_RECORD;
  END;
  --En fetch all details from  appl_mast

  --Sn find the bin for the product code
  BEGIN
    LP_PAN_BIN(V_INST_CODE, V_INST_TYPE, V_PROD_CODE, V_BIN, V_ERRMSG);

    IF V_ERRMSG <> 'OK' THEN
     RAISE EXP_REJECT_RECORD;
    END IF;
  EXCEPTION
    WHEN EXP_REJECT_RECORD THEN
     RAISE;
    WHEN OTHERS THEN
     V_ERRMSG := 'Error while selecting bin from binmast' ||
               SUBSTR(SQLERRM, 1, 300);
     RAISE EXP_REJECT_RECORD;
  END;

  --En find the bin for the product code



  --Sn find profile code attached to cardtype
  BEGIN

    SELECT CPC_PROFILE_CODE,
         CPM_CATG_CODE,
         CPC_PROD_PREFIX,
         CPC_PROGRAM_ID, --T.Narayanan added for prg id
         CPC_PROXY_LENGTH, --Commented for CR -38 DFC- CCF Changes
         /* Start Serial No Chnges added by Dhiraj Gaikwad 20082012 */
         CPC_SERL_FLAG,
         CPC_STARTERGPR_ISSUE, --Added by T.Narayanan. for gpr card type changes
         CPC_STARTER_CARD, --Added by T.Narayanan. for gpr card type changes
    /* End Serial No Chnges added by Dhiraj Gaikwad 20082012 */
         NVL(CPC_PAN_INVENTORY_FLAG, 'N'),--Added for 17.07 PAN Inventory Changes
         CPC_PROGRAMID_REQ,
         CPC_CHECK_DIGIT_REQ,
         CPC_ENCRYPT_ENABLE,
         cpc_prod_suffix,
         cpc_start_card_no,
         cpc_end_card_no,
         cpc_ccf_serial_flag,
         cpc_product_id,
		 NVL(CPC_SWEEP_FLAG,'N'), -- Added for Wrong Expiry Date Calc VISA TO MASTER MIGR
         NVL(cpc_expdate_randomization,'N') --Added for VMS-7341
     INTO V_PROFILE_CODE,
         V_CPM_CATG_CODE,
         V_PROD_PREFIX,
         V_PROGRAMID, --T.Narayanan added for prg id
         V_PROXYLENGTH, --Commented for CR -38 DFC- CCF Changes
         /* Start Serial No Chnges added by Dhiraj Gaikwad 20082012 */
         V_CPC_SERL_FLAG,
         V_STARTERGPR_TYPE, --Added by T.Narayanan. for gpr card type changes
         V_STARTER_CARD_FLG, --Added by T.Narayanan. for gpr card type changes
    /* End Serial No Chnges added by Dhiraj Gaikwad 20082012 */
         V_PAN_INVENTORY_FLAG,  --Added for 17.07 PAN Inventory Changes
          V_PROGRAMID_REQ  ,
          V_CHECK_DIGIT_REQ,
          V_ENCRYPT_ENABLE,
          v_prod_suffix,
          v_card_start,
          v_card_end,
		  v_ccf_serial_flag,
		  v_product_id,
		  V_SWEEP_FLAG,  --Added for Wrong Expiry Date Calc VISA TO MASTER MIGR
          v_isexpry_randm --Added for VMS-7341
     FROM CMS_PROD_CATTYPE, CMS_PROD_MAST
    WHERE CPC_INST_CODE = P_INSTCODE AND CPC_INST_CODE = CPM_INST_CODE AND
         CPC_PROD_CODE = V_PROD_CODE AND CPC_CARD_TYPE = V_CARD_TYPE AND
         CPM_PROD_CODE = CPC_PROD_CODE;
  EXCEPTION
    WHEN NO_DATA_FOUND THEN
     V_ERRMSG := 'Profile code not defined for product code ' ||
               V_PROD_CODE || 'card type ' || V_CARD_TYPE;
     RAISE EXP_REJECT_RECORD;
    WHEN OTHERS THEN
     V_ERRMSG := 'Error while selecting applcode from applmast' ||
               SUBSTR(SQLERRM, 1, 300);
     RAISE EXP_REJECT_RECORD;
  END;

  --T.Narayanan changed for the product category changes for gpr card

  -- T.Narayanan added one more if condition for starter card generation card type issue on 05/10/2012

  BEGIN

    SELECT COUNT(*)
     INTO V_APPL_COUNT
     FROM CMS_APPL_PAN
    WHERE CAP_APPL_CODE = P_APPLCODE AND CAP_INST_CODE = P_INSTCODE;

  EXCEPTION
    WHEN NO_DATA_FOUND THEN
     NULL;

  END;

  IF V_APPL_COUNT > 0 THEN
    IF V_STARTER_CARD_FLG = 'Y' THEN
     IF V_STARTERGPR_TYPE = 'M' THEN
       BEGIN

        SELECT CPC_STARTERGPR_CRDTYPE
          INTO V_GPR_CARD_TYPE
          FROM CMS_PROD_CATTYPE
         WHERE CPC_PROD_CODE = V_PROD_CODE AND CPC_INST_CODE = P_INSTCODE AND
              CPC_STARTER_CARD != 'N' AND CPC_CARD_TYPE = V_CARD_TYPE;

        IF V_GPR_CARD_TYPE != 0 THEN

          V_CARD_TYPE := V_GPR_CARD_TYPE;

        END IF;

       EXCEPTION
        WHEN NO_DATA_FOUND THEN
          V_ERRMSG := 'GPR Product Category not found for product code ' ||
                    V_PROD_CODE || 'card type ' || V_CARD_TYPE;
          RAISE EXP_REJECT_RECORD;
        WHEN OTHERS THEN
          V_ERRMSG := 'Error while selecting GPR Product Category from cms_prod_cattype' ||
                    SUBSTR(SQLERRM, 1, 300);
          RAISE EXP_REJECT_RECORD;
       END;
       --ST :Added for generating GPR card on 27/10/14 Defect id : 15848
        BEGIN

         SELECT  CPC_SERL_FLAG,CPC_PROD_PREFIX,cpc_user_identify_type, --Added for FSS:2072 on 16-JAN-2015
         cpc_prod_suffix, cpc_start_card_no, cpc_end_card_no
         INTO V_CPC_SERL_FLAG,V_PROD_PREFIX,v_user_identify_type, --Added for FSS:2072 on 16-JAN-2015
          v_prod_suffix, v_card_start, v_card_end
         FROM CMS_PROD_CATTYPE
         WHERE CPC_INST_CODE = P_INSTCODE
         AND CPC_PROD_CODE = V_PROD_CODE AND CPC_CARD_TYPE = V_CARD_TYPE;

         EXCEPTION
            WHEN NO_DATA_FOUND THEN
             V_ERRMSG := 'Serial flag not defined for product code ' ||
                       V_PROD_CODE || 'card type ' || V_CARD_TYPE;
             RAISE EXP_REJECT_RECORD;
            WHEN OTHERS THEN
             V_ERRMSG := 'Error while selecting serial flag from prodcat table' ||
                       SUBSTR(SQLERRM, 1, 300);
             RAISE EXP_REJECT_RECORD;
        END;
        --END:Added for generating GPR card on 27/10/14 Defect id : 15848
     END IF;
    END IF;
  END IF;
  -- T.Narayanan added one more if condition for starter card generation card type issue
  --T.Narayanan changed for the product category changes for gpr card

  -- Added by Trivkram on 08 June 2012 , If not configure PAN Product Category Prefix with Product Category level it will take from Instistute level

  IF V_PROD_PREFIX IS NULL THEN
    BEGIN
     SELECT CIP_PARAM_VALUE
       INTO V_PROD_PREFIX
       FROM CMS_INST_PARAM
      WHERE CIP_INST_CODE = P_INSTCODE AND
           CIP_PARAM_KEY = 'PANPRODCATPREFIX';
    EXCEPTION
     WHEN OTHERS THEN
       V_ERRMSG := 'Error while selecting PAN Product Category Prefix from CMS_INST_PARAM ' ||
                SUBSTR(SQLERRM, 1, 300);
       RAISE EXP_REJECT_RECORD;
    END;
  END IF;

  --En find profile code attached to cardtype
IF v_pan_inventory_flag='N' THEN    --Added for 17.07 PAN Inventory Changes
  --Sn find pan construct details based on profile code
  --BEGIN
    --V_LOOP_CNT := 0;
--    FOR I IN C(V_PROFILE_CODE) LOOP
--     V_LOOP_CNT := V_LOOP_CNT + 1;
--
--     SELECT I.CPC_PROFILE_CODE,
--           I.CPC_FIELD_NAME,
--           I.CPC_START_FROM,
--           I.CPC_LENGTH,
--           I.CPC_START
--       INTO V_TABLE_PAN_CONSTRUCT(V_LOOP_CNT).CPC_PROFILE_CODE,
--           V_TABLE_PAN_CONSTRUCT(V_LOOP_CNT).CPC_FIELD_NAME,
--           V_TABLE_PAN_CONSTRUCT(V_LOOP_CNT).CPC_START_FROM,
--           V_TABLE_PAN_CONSTRUCT(V_LOOP_CNT).CPC_LENGTH,
--           V_TABLE_PAN_CONSTRUCT(V_LOOP_CNT).CPC_START
--       FROM DUAL;
--    END LOOP;
--  EXCEPTION
--    WHEN OTHERS THEN
--     V_ERRMSG := 'Error while selecting profile detail from profile mast ' ||
--               SUBSTR(SQLERRM, 1, 300);
--     RAISE EXP_REJECT_RECORD;
--  END;
--
--  --En find pan construct details based on profile code
--  --Sn built the pan gen logic based on the value (except serial no)
--  BEGIN
--    V_LOOP_MAX_CNT := V_TABLE_PAN_CONSTRUCT.COUNT;
--    V_TMP_PAN      := NULL;
--
--    FOR I IN 1 .. V_LOOP_MAX_CNT LOOP
--
--     IF V_TABLE_PAN_CONSTRUCT(I).CPC_FIELD_NAME = 'Card Type' THEN
--       V_TABLE_PAN_CONSTRUCT(I).CPC_FIELD_VALUE := LPAD(SUBSTR(TRIM(V_CARD_TYPE),
--                                                    V_TABLE_PAN_CONSTRUCT(I)
--                                                    .CPC_START,
--                                                    V_TABLE_PAN_CONSTRUCT(I)
--                                                    .CPC_LENGTH),
--                                              V_TABLE_PAN_CONSTRUCT(I)
--                                              .CPC_LENGTH,
--                                              '0');
--     ELSIF V_TABLE_PAN_CONSTRUCT(I).CPC_FIELD_NAME = 'Branch' THEN
--       V_TABLE_PAN_CONSTRUCT(I).CPC_FIELD_VALUE := LPAD(SUBSTR(TRIM(V_APPL_BRAN),
--                                                    V_TABLE_PAN_CONSTRUCT(I)
--                                                    .CPC_START,
--                                                    V_TABLE_PAN_CONSTRUCT(I)
--                                                    .CPC_LENGTH),
--                                              V_TABLE_PAN_CONSTRUCT(I)
--                                              .CPC_LENGTH,
--                                              '0');
--     ELSIF V_TABLE_PAN_CONSTRUCT(I).CPC_FIELD_NAME = 'BIN / PREFIX' THEN
--       V_TABLE_PAN_CONSTRUCT(I).CPC_FIELD_VALUE := LPAD(SUBSTR(TRIM(V_BIN),
--                                                    V_TABLE_PAN_CONSTRUCT(I)
--                                                    .CPC_START,
--                                                    V_TABLE_PAN_CONSTRUCT(I)
--                                                    .CPC_LENGTH),
--                                              V_TABLE_PAN_CONSTRUCT(I)
--                                              .CPC_LENGTH,
--                                              '0');
--     ELSIF V_TABLE_PAN_CONSTRUCT(I)
--     .CPC_FIELD_NAME = 'PAN Product Category Prefix' THEN
--       -- Modified by Trivikram on 06 June 2012 to distinguish Product Category Prefix of Account and PAN
----       V_TABLE_PAN_CONSTRUCT(I).CPC_FIELD_VALUE := LPAD(SUBSTR(TRIM(V_PROD_PREFIX),
----                                                    V_TABLE_PAN_CONSTRUCT(I)
----                                                    .CPC_START,
----                                                    V_TABLE_PAN_CONSTRUCT(I)
----                                                    .CPC_LENGTH),
----                                              V_TABLE_PAN_CONSTRUCT(I)
----                                              .CPC_LENGTH,
----                                              '0');

--     ELSE
--       IF V_TABLE_PAN_CONSTRUCT(I).CPC_FIELD_NAME <> 'Serial Number' THEN
--        V_ERRMSG := 'Pan construct ' || V_TABLE_PAN_CONSTRUCT(I)
--                 .CPC_FIELD_NAME || ' not exist ';
--        RAISE EXP_REJECT_RECORD;
--       END IF;
--     END IF;
--    END LOOP;
--  EXCEPTION
--    WHEN EXP_REJECT_RECORD THEN
--     RAISE;
--    WHEN OTHERS THEN
--     V_ERRMSG := 'Error from pangen process ' || SUBSTR(SQLERRM, 1, 300);
--     RAISE EXP_REJECT_RECORD;
--  END;
--
--  --En built the pan gen logic based on the value
--
--  --Sn generate the serial no
----  FOR I IN 1 .. V_LOOP_MAX_CNT LOOP
----    --<< i loop >>
----    FOR J IN 1 .. V_LOOP_MAX_CNT LOOP
----     --<< j  loop >>
----     IF V_TABLE_PAN_CONSTRUCT(J)
----     .CPC_START_FROM = I AND V_TABLE_PAN_CONSTRUCT(J)
----     .CPC_FIELD_NAME <> 'Serial Number' THEN
----       V_TMP_PAN := V_TMP_PAN || V_TABLE_PAN_CONSTRUCT(J).CPC_FIELD_VALUE;
----       EXIT;
----     END IF;
----    END LOOP; --<< j  end loop >>
----  END LOOP; --<< i end loop >>
--
--  --Sn get  index value of serial no from PL/SQL table
--  FOR I IN 1 .. V_TABLE_PAN_CONSTRUCT.COUNT LOOP
--    IF V_TABLE_PAN_CONSTRUCT(I).CPC_FIELD_NAME = 'Serial Number' THEN
--     V_SERIAL_INDEX := I;

--    END IF;
--  END LOOP;
--
--  --En get  index value of serial no from PL/SQL table
--
--
--
--  IF V_SERIAL_INDEX IS NOT NULL THEN
--    V_SERIAL_MAXLENGTH := V_TABLE_PAN_CONSTRUCT(V_SERIAL_INDEX).CPC_LENGTH;
----
--    --IF V_CPC_SERL_FLAG = 1 THEN
--
--
--         BEGIN                                  --Added on 26-Mar-2013 for performace issue
--            lp_shuffle_srno (p_instcode,
--                             v_prod_code,
--                             v_card_type,
--                             p_lupduser,
--                             p_shflcntrl_no,
--                             v_serial_no,
--                             v_errmsg
--                            );
--
--            IF v_errmsg <> 'OK'
--            THEN
--               v_donot_mark_error := 1;
--               RAISE exp_reject_record;
--            END IF;
--
--         EXCEPTION when exp_reject_record
--         then
--             raise;
--
--         WHEN OTHERS
--         THEN
--               v_errmsg :=
--                     'Error while calling LP_SHUFFLE_SRNO '
--                  || SUBSTR (SQLERRM, 1, 300);
--               RAISE exp_reject_record;
--         END;
--
--        /*
--         BEGIN
--
--            --   SELECT CSS_SERL_NUMB into V_SERIAL_NO
--            --   FROM cms_shfl_serl
--            --  WHERE css_inst_code = P_INSTCODE
--            --  AND css_prod_code = V_PROD_CODE
--            --  AND css_prod_catg = V_CARD_TYPE
--            --  AND css_serl_flag = 0 and rownum<2 FOR UPDATE  ;
--
--           SELECT CSS_SERL_NUMB
--            INTO V_SERIAL_NO
--            FROM (SELECT CSS_SERL_NUMB
--                   FROM CMS_SHFL_SERL
--                  WHERE CSS_INST_CODE = P_INSTCODE AND
--                       CSS_PROD_CODE = V_PROD_CODE AND
--                       CSS_PROD_CATG = V_CARD_TYPE AND CSS_SERL_FLAG = 0
--                  ORDER BY DBMS_RANDOM.VALUE)
--            WHERE ROWNUM < 2;
--
--         EXCEPTION
--           WHEN NO_DATA_FOUND THEN
--            V_ERRMSG           := 'Shuffle Serial Number Not Found For Product And Product Catagory ';
--            V_DONOT_MARK_ERROR := 1;
--
--            RAISE EXP_REJECT_RECORD;
--
--           WHEN OTHERS THEN
--            V_ERRMSG := 'Error While Finding Shuffle Serial Number ' ||
--                      SQLERRM;
--            RAISE EXP_REJECT_RECORD;
--
--         END;
--         */
--
--         BEGIN
--           UPDATE CMS_SHFL_SERL
--             SET CSS_SERL_FLAG = 1
--            WHERE CSS_SERL_NUMB = V_SERIAL_NO AND CSS_INST_CODE = P_INSTCODE AND
--                CSS_PROD_CODE = V_PROD_CODE --Added on 27092012 Dhiraj Gaikwad
--                AND CSS_PROD_CATG = V_CARD_TYPE --Added on 27092012 Dhiraj Gaikwad
--                AND css_shfl_cntrl = p_shflcntrl_no --Added on 26-Mar-2013 for performace issue
--                AND CSS_SERL_FLAG = 0; --Added on 27092012 Dhiraj Gaikwad
--           IF SQL%ROWCOUNT = 0 THEN
--            V_ERRMSG := 'Error updating Serial  control data, record not updated successfully';
--            RAISE EXP_REJECT_RECORD;
--           END IF;
--
--         EXCEPTION
--           WHEN OTHERS THEN
--            V_ERRMSG := 'Error updating control data ' ||
--                      SUBSTR(SQLERRM, 1, 150);
--            RAISE EXP_REJECT_RECORD;
--         END;
--         /* End  Serial No Chnges added by Dhiraj Gaikwad 20082012 */
--    ELSE

--       LP_PAN_SRNO(P_INSTCODE,
--                P_LUPDUSER,
--                V_TMP_PAN,
--                V_SERIAL_MAXLENGTH,
--                V_SERIAL_NO,
--                V_ERRMSG);
--
--    END IF;
--   V_TABLE_PAN_CONSTRUCT(v_prodprefx_index).CPC_FIELD_VALUE := LPAD(SUBSTR(TRIM(v_tmp_pan),
--                                                           V_TABLE_PAN_CONSTRUCT(v_prodprefx_index)
--                                                           .CPC_START,
--                                                           V_TABLE_PAN_CONSTRUCT(v_prodprefx_index)
--                                                           .CPC_LENGTH),
--                                                     V_TABLE_PAN_CONSTRUCT(v_prodprefx_index)
--                                                     .CPC_LENGTH,
--                                                     '0');
--
--    V_TABLE_PAN_CONSTRUCT(V_SERIAL_INDEX).CPC_FIELD_VALUE := LPAD(SUBSTR(TRIM(V_SERIAL_NO),
--                                                           V_TABLE_PAN_CONSTRUCT(V_SERIAL_INDEX)
--                                                           .CPC_START,
--                                                           V_TABLE_PAN_CONSTRUCT(V_SERIAL_INDEX)
--                                                           .CPC_LENGTH),
--                                                     V_TABLE_PAN_CONSTRUCT(V_SERIAL_INDEX)
--                                                     .CPC_LENGTH,
--                                                     '0');
--  END IF;

  --En generate the serial no



  --Sn generate temp pan for check digit


--  FOR I IN 1 .. V_LOOP_MAX_CNT LOOP
--    FOR J IN 1 .. V_LOOP_MAX_CNT LOOP
--     IF V_TABLE_PAN_CONSTRUCT(J).CPC_START_FROM = I THEN
--       V_TMP_PAN := V_TMP_PAN || V_TABLE_PAN_CONSTRUCT(J).CPC_FIELD_VALUE;
--       EXIT;
--     END IF;
--    END LOOP;
--  END LOOP;

    --SN: Modified/Added for VMS-6656,6843
    BEGIN
     SELECT UPPER(TRIM(NVL(cip_param_value,'Y')))
       INTO v_toggle_value
       FROM cms_inst_param
      WHERE cip_inst_code = 1
        AND cip_param_key = 'RETL_GPR_MULTIBIN_TOGGLE';
    EXCEPTION
     WHEN NO_DATA_FOUND THEN
       v_toggle_value := 'Y';
    END;

    BEGIN
    IF v_toggle_value = 'N' THEN
    vmscard.get_pan_srno (p_instcode,
                          v_prod_code,
                          v_card_type,
                          v_prod_prefix,
                          v_prod_suffix,
                          v_card_start,
                          v_card_end,
                          v_cpc_serl_flag,
                          v_prefix,
                          v_serial_no,
                          v_errmsg);
    ELSE
    vmscard.get_pan_srno (p_instcode,
                          v_prod_code,
                          v_card_type,
                          v_starter_card,
                          v_cpc_serl_flag,
                          v_bin,
                          v_prefix,
                          v_serial_no,
                          v_errmsg);
    END IF;
    --EN: Modified/Added for VMS-6655,6843

       IF V_ERRMSG <> 'OK' THEN
        RAISE EXP_REJECT_RECORD;
       END IF;
     EXCEPTION
       --Sn added by Pankaj S. on 08_May_2013 for mantis ID-11048
       WHEN EXP_REJECT_RECORD THEN
       RAISE;
       --En added by Pankaj S. 0n 08_May_2013 for mantis ID-11048
       WHEN OTHERS THEN
        V_ERRMSG := 'Error while calling get_pan_srno ' ||
                  SUBSTR(SQLERRM, 1, 300);
        RAISE EXP_REJECT_RECORD;
     END;

	  V_TMP_PAN := NULL;
 BEGIN
  FOR I
         IN (SELECT cpc_profile_code,
                    cpc_field_name,
                    cpc_start_from,
                    cpc_length,
                    cpc_start
               FROM cms_pan_construct
              WHERE cpc_profile_code = V_PROFILE_CODE
                    AND cpc_inst_code = P_INSTCODE
                    order by cpc_start_from)
      LOOP
         IF i.cpc_field_name = 'Card Type'
         THEN
            V_TMP_PAN := V_TMP_PAN || LPAD ( SUBSTR (TRIM (V_CARD_TYPE), I.CPC_START, I.CPC_LENGTH), I.CPC_LENGTH,'0');
          ELSIF i.cpc_field_name = 'Branch'
         THEN
            V_TMP_PAN := V_TMP_PAN || LPAD ( SUBSTR (TRIM (V_APPL_BRAN), I.CPC_START, I.CPC_LENGTH),  I.CPC_LENGTH, '0');
        ELSIF i.cpc_field_name = 'BIN / PREFIX'
         THEN
            V_TMP_PAN := V_TMP_PAN || LPAD ( SUBSTR (TRIM (V_BIN), I.CPC_START, I.CPC_LENGTH),  I.CPC_LENGTH, '0');
         ELSIF i.cpc_field_name = 'PAN Product Category Prefix'
         THEN
            V_TMP_PAN := V_TMP_PAN || LPAD ( SUBSTR (TRIM (V_PREFIX), I.CPC_START, I.CPC_LENGTH),  I.CPC_LENGTH, '0');
         ELSIF i.cpc_field_name = 'Serial Number'
         THEN
            V_TMP_PAN := V_TMP_PAN || LPAD ( SUBSTR (TRIM (V_SERIAL_NO), I.CPC_START, I.CPC_LENGTH),  I.CPC_LENGTH, '0');
         END IF;
      END LOOP;
   EXCEPTION
      WHEN OTHERS
      THEN
         V_ERRMSG :=
            'Error while getting temp PAN:' || SUBSTR (SQLERRM, 1, 200);
   END;
  --En generate temp pan for check digit
  --Sn generate for check digit
  LP_PAN_CHKDIG(V_TMP_PAN, V_CHECK_DIGIT);
  V_PAN := V_TMP_PAN || V_CHECK_DIGIT;

  --En generate for check digit
 --SN:Added for 17.07 PAN Inventory Changes
 ELSE
       vmscard.get_card_no (v_prod_code,
                            v_card_type,
                            v_pan,
                            v_errmsg);

       IF v_errmsg <> 'OK' THEN
          v_errmsg := 'Error from get_card_no-' || v_errmsg;
          RAISE exp_reject_record;
       END IF;
 END IF;
 --EN:Added for 17.07 PAN Inventory Changes
  --SN CREATE HASH PAN
  BEGIN
    V_HASH_PAN := GETHASH(V_PAN);
  EXCEPTION
    WHEN OTHERS THEN
     V_ERRMSG := 'Error while converting pan ' || SUBSTR(SQLERRM, 1, 200);
     RAISE EXP_REJECT_RECORD;
  END;

  --EN CREATE HASH PAN

  --SN create encr pan
  BEGIN
    V_ENCR_PAN := FN_EMAPS_MAIN(V_PAN);
  EXCEPTION
    WHEN OTHERS THEN
     V_ERRMSG := 'Error while converting pan ' || SUBSTR(SQLERRM, 1, 200);
     RAISE EXP_REJECT_RECORD;
  END;

  --EN create encr pan

  --SN create Mask PAN  -- Added by sagar on 06Aug2012 for Pan masking changes
  BEGIN
    V_MASK_PAN := fn_getmaskpan(V_PAN);
  EXCEPTION
    WHEN OTHERS THEN
     V_ERRMSG := 'Error while converting into mask pan ' ||
               SUBSTR(SQLERRM, 1, 200);
     RAISE EXP_REJECT_RECORD;
  END;

  -- Sn find primary acct no for the pan
  BEGIN
    SELECT CAM_ACCT_ID, CAM_ACCT_NO
     INTO V_ACCT_ID, V_ACCT_NUM
     FROM CMS_ACCT_MAST
    WHERE CAM_INST_CODE = P_INSTCODE AND
         CAM_ACCT_ID =
         (SELECT CAD_ACCT_ID
            FROM CMS_APPL_DET
           WHERE CAD_INST_CODE = P_INSTCODE AND CAD_APPL_CODE = P_APPLCODE AND
                CAD_ACCT_POSN = 1);
  EXCEPTION
    WHEN NO_DATA_FOUND THEN
     V_ERRMSG := 'No account primary  defined for appl code ' ||
               P_APPLCODE;
     RAISE EXP_REJECT_RECORD;
    WHEN OTHERS THEN
     V_ERRMSG := 'Error while selecting acct detail for pan ' ||
               SUBSTR(SQLERRM, 1, 200);
     RAISE EXP_REJECT_RECORD;
  END;

  --En find primary acct no for the pan

  --Sn entry for addon stat
  IF V_ADDON_STAT = 'A' THEN
    BEGIN
     --begin 1.1
     SELECT CAM_ADDON_LINK
       INTO V_CAM_ADDON_LINK
       FROM CMS_APPL_MAST
      WHERE CAM_INST_CODE = P_INSTCODE AND CAM_APPL_CODE = P_APPLCODE;

     SELECT CAP_PAN_CODE, CAP_MBR_NUMB
       INTO V_ADONLINK, V_MBRLINK
       FROM CMS_APPL_PAN
      WHERE CAP_INST_CODE = P_INSTCODE AND
           CAP_APPL_CODE = V_CAM_ADDON_LINK;
    EXCEPTION
     --excp 1.1
     WHEN NO_DATA_FOUND THEN
       V_ERRMSG := 'Parent PAN not generated for ' || P_APPLCODE;
       RAISE EXP_REJECT_RECORD;
     WHEN OTHERS THEN
       V_ERRMSG := 'Excp1.1 -- ' || SQLERRM;
       RAISE EXP_REJECT_RECORD;
    END; --end of begin 1.1
  ELSIF V_ADDON_STAT = 'P' THEN
    --v_adonlink    :=    v_pan;
    V_ADONLINK := V_HASH_PAN;
    V_MBRLINK  := '000';
  END IF;

V_CARD_STAT := '0';  -- VMS-8219
  --En entry for addon stat
  --Sn find card status and limit parameter for the profile
--  BEGIN
--    SELECT CBP_PARAM_VALUE
--     INTO V_CARD_STAT
--     FROM CMS_BIN_PARAM
--    WHERE CBP_INST_CODE = P_INSTCODE AND CBP_PROFILE_CODE = V_PROFILE_CODE AND
--         CBP_PARAM_NAME = 'Status';
--
--    IF V_CARD_STAT IS NULL THEN
--     V_ERRMSG := 'Status is null for profile code ' || V_PROFILE_CODE;
--     RAISE EXP_REJECT_RECORD;
--    END IF;
--  EXCEPTION
--    WHEN EXP_REJECT_RECORD THEN
--     RAISE;
--    WHEN NO_DATA_FOUND THEN
--     V_ERRMSG := 'Status is not defined for profile code ' ||
--               V_PROFILE_CODE;
--     RAISE EXP_REJECT_RECORD;
--    WHEN OTHERS THEN
--    -- V_ERRMSG := 'Error'|| V_PROFILE_CODE||' selecting card status ' ||
--      --         SUBSTR(SQLERRM, 1, 200);
--                    V_ERRMSG := 'Error'|| V_PROFILE_CODE||' selecting card status @';
--     RAISE EXP_REJECT_RECORD;
--  END;

  --En find card status and limit parameter for the profile

  --Sn atm off  line limit
  BEGIN
    SELECT CBP_PARAM_VALUE
     INTO V_OFFLINE_ATM_LIMIT
     FROM CMS_BIN_PARAM
    WHERE CBP_INST_CODE = P_INSTCODE AND CBP_PROFILE_CODE = V_PROFILE_CODE AND
         CBP_PARAM_NAME = 'Offline ATM Limit';

    IF V_CARD_STAT IS NULL THEN
     V_OFFLINE_ATM_LIMIT := 0;
    END IF;
  EXCEPTION
    WHEN NO_DATA_FOUND THEN
     V_OFFLINE_ATM_LIMIT := 0;
    WHEN OTHERS THEN
     V_ERRMSG := 'Error while selecting offline ATM limit ' ||
               SUBSTR(SQLERRM, 1, 200);
     RAISE EXP_REJECT_RECORD;
  END;

  --En atm off  line limit
  --Sn atm on  line limit
  BEGIN
    SELECT CBP_PARAM_VALUE
     INTO V_ONLINE_ATM_LIMIT
     FROM CMS_BIN_PARAM
    WHERE CBP_INST_CODE = P_INSTCODE AND CBP_PROFILE_CODE = V_PROFILE_CODE AND
         CBP_PARAM_NAME = 'Online ATM Limit';

    IF V_CARD_STAT IS NULL THEN
     V_OFFLINE_ATM_LIMIT := 0;
    END IF;
  EXCEPTION
    WHEN NO_DATA_FOUND THEN
     V_ONLINE_ATM_LIMIT := 0;
    WHEN OTHERS THEN
     V_ERRMSG := 'Error while selecting online ATM limit ' ||
               SUBSTR(SQLERRM, 1, 200);
     RAISE EXP_REJECT_RECORD;
  END;

  --En atm on  line limit
  --Sn pos  on  line limit
  BEGIN
    SELECT CBP_PARAM_VALUE
     INTO V_ONLINE_POS_LIMIT
     FROM CMS_BIN_PARAM
    WHERE CBP_INST_CODE = P_INSTCODE AND CBP_PROFILE_CODE = V_PROFILE_CODE AND
         CBP_PARAM_NAME = 'Online POS Limit';

    IF V_CARD_STAT IS NULL THEN
     V_ONLINE_POS_LIMIT := 0;
    END IF;
  EXCEPTION
    WHEN NO_DATA_FOUND THEN
     V_ONLINE_POS_LIMIT := 0;
    WHEN OTHERS THEN
     V_ERRMSG := 'Error while selecting online POS limit ' ||
               SUBSTR(SQLERRM, 1, 200);
     RAISE EXP_REJECT_RECORD;
  END;

  --En pos on  line limit

  --Sn pos off  line limit
  BEGIN
    SELECT CBP_PARAM_VALUE
     INTO V_OFFLINE_POS_LIMIT
     FROM CMS_BIN_PARAM
    WHERE CBP_INST_CODE = P_INSTCODE AND CBP_PROFILE_CODE = V_PROFILE_CODE AND
         CBP_PARAM_NAME = 'Offline POS Limit';

    IF V_CARD_STAT IS NULL THEN
     V_OFFLINE_POS_LIMIT := 0;
    END IF;
  EXCEPTION
    WHEN NO_DATA_FOUND THEN
     V_OFFLINE_POS_LIMIT := 0;
    WHEN OTHERS THEN
     V_ERRMSG := 'Error while selecting offline POS limit ' ||
               SUBSTR(SQLERRM, 1, 200);
     RAISE EXP_REJECT_RECORD;
  END;

  --En pos  off  line limit

  --Sn MMPOS off  line limit
  BEGIN
    SELECT CBP_PARAM_VALUE
     INTO V_OFFLINE_MMPOS_LIMIT
     FROM CMS_BIN_PARAM
    WHERE CBP_INST_CODE = P_INSTCODE AND CBP_PROFILE_CODE = V_PROFILE_CODE AND
         CBP_PARAM_NAME = 'Offline MMPOS Limit';

    IF V_CARD_STAT IS NULL THEN
     V_OFFLINE_MMPOS_LIMIT := 0;
    END IF;
  EXCEPTION
    WHEN NO_DATA_FOUND THEN
     V_OFFLINE_MMPOS_LIMIT := 0;
    WHEN OTHERS THEN
     V_ERRMSG := 'Error while selecting offline POS limit ' ||
               SUBSTR(SQLERRM, 1, 200);
     RAISE EXP_REJECT_RECORD;
  END;

  --En MMPOS off  line limit

  --Sn MMPOS  on  line limit
  BEGIN
    SELECT CBP_PARAM_VALUE
     INTO V_ONLINE_MMPOS_LIMIT
     FROM CMS_BIN_PARAM
    WHERE CBP_INST_CODE = P_INSTCODE AND CBP_PROFILE_CODE = V_PROFILE_CODE AND
         CBP_PARAM_NAME = 'Online MMPOS Limit';

    IF V_CARD_STAT IS NULL THEN
     V_ONLINE_MMPOS_LIMIT := 0;
    END IF;
  EXCEPTION
    WHEN NO_DATA_FOUND THEN
     V_ONLINE_MMPOS_LIMIT := 0;
    WHEN OTHERS THEN
     V_ERRMSG := 'Error while selecting online POS limit ' ||
               SUBSTR(SQLERRM, 1, 200);
     RAISE EXP_REJECT_RECORD;
  END;

  --En MMPOS  on  line limit

  --Commented for changing the Aggregate limit based on ATM,POS and MMPOS limits

  V_OFFLINE_AGGR_LIMIT := V_OFFLINE_ATM_LIMIT + V_OFFLINE_POS_LIMIT +
                     V_OFFLINE_MMPOS_LIMIT;
  V_ONLINE_AGGR_LIMIT  := V_ONLINE_ATM_LIMIT + V_ONLINE_POS_LIMIT +
                     V_ONLINE_MMPOS_LIMIT;

  --msiva sn added for Expiry date calculate


  --Sn get validity from profile
 /* BEGIN
    SELECT CBP_PARAM_VALUE
     INTO V_EXPRYPARAM
     FROM CMS_BIN_PARAM
    WHERE CBP_PROFILE_CODE = V_PROFILE_CODE AND
         CBP_PARAM_NAME = 'Validity' AND CBP_INST_CODE = P_INSTCODE;

    IF V_EXPRYPARAM IS NULL THEN
     RAISE NO_DATA_FOUND;
    ELSE
     --Sn find validity period
     BEGIN
       SELECT CBP_PARAM_VALUE
        INTO V_VALIDITY_PERIOD
        FROM CMS_BIN_PARAM
        WHERE CBP_PROFILE_CODE = V_PROFILE_CODE AND
            CBP_PARAM_NAME = 'Validity Period' AND
            CBP_INST_CODE = P_INSTCODE;
     EXCEPTION
       WHEN NO_DATA_FOUND THEN
        V_ERRMSG := 'Validity period is not defined for product cattype profile ';
        RAISE EXP_REJECT_RECORD;
       WHEN OTHERS THEN
        V_ERRMSG := 'Error while selecting  CBP_PARAM_VALUE' ||
                  SUBSTR(SQLERRM, 1, 200);
        RAISE EXP_REJECT_RECORD;
     END;
     --En find validitty period
    END IF;
    --   v_expry_date := LAST_DAY (ADD_MONTHS (SYSDATE, v_expryparam - 1));
  EXCEPTION
    WHEN EXP_REJECT_RECORD THEN
     RAISE;
    WHEN NO_DATA_FOUND THEN
     BEGIN
       SELECT CBP_PARAM_VALUE
        INTO V_EXPRYPARAM
        FROM CMS_BIN_PARAM
        WHERE CBP_PROFILE_CODE = V_PROFILE_CODE AND
            CBP_PARAM_NAME = 'Validity' AND CBP_INST_CODE = P_INSTCODE;

       IF V_EXPRYPARAM IS NULL THEN
        RAISE NO_DATA_FOUND;
       ELSE
        --Sn find validity period
        BEGIN
          SELECT CBP_PARAM_VALUE
            INTO V_VALIDITY_PERIOD
            FROM CMS_BIN_PARAM
           WHERE CBP_PROFILE_CODE = V_PROFILE_CODE AND
                CBP_PARAM_NAME = 'Validity Period' AND
                CBP_INST_CODE = P_INSTCODE;
        EXCEPTION
          WHEN NO_DATA_FOUND THEN
            V_ERRMSG := 'Validity period is not defined for product profile ';
            RAISE EXP_REJECT_RECORD;
          WHEN OTHERS THEN
            V_ERRMSG := 'Error while selecting CMS_BIN_PARAM ' ||
                     SUBSTR(SQLERRM, 1, 200);
            RAISE EXP_REJECT_RECORD;
        END;
        --En find validitty period
       END IF;
       --v_expry_date := LAST_DAY (ADD_MONTHS (SYSDATE, v_expryparam - 1));
     EXCEPTION
       WHEN EXP_REJECT_RECORD THEN
        RAISE;
       WHEN NO_DATA_FOUND THEN
        V_ERRMSG := 'No validity data found either product/product type profile ';
        RAISE EXP_REJECT_RECORD;
       WHEN OTHERS THEN
        V_ERRMSG := 'Error while selecting validity data ' ||
                  SUBSTR(SQLERRM, 1, 200);
        RAISE EXP_REJECT_RECORD;
     END;
    WHEN OTHERS THEN
     V_ERRMSG := 'Error while selecting offline POS limit ' ||
               SUBSTR(SQLERRM, 1, 200);
     RAISE EXP_REJECT_RECORD;
  END;*/ -- Entire block is not used for anything and commented

  --En get validity from profile

  --SN commented the unused code

  /*IF V_VALIDITY_PERIOD = 'Hour' THEN
    V_EXPIRY_DATE := SYSDATE + V_EXPRYPARAM / 24;
  ELSIF V_VALIDITY_PERIOD = 'Day' THEN
    V_EXPIRY_DATE := SYSDATE + V_EXPRYPARAM;
  ELSIF V_VALIDITY_PERIOD = 'Week' THEN
    V_EXPIRY_DATE := SYSDATE + (7 * V_EXPRYPARAM);
  ELSIF V_VALIDITY_PERIOD = 'Month' THEN
    V_EXPIRY_DATE := LAST_DAY(ADD_MONTHS(SYSDATE, V_EXPRYPARAM - 1));
  ELSIF V_VALIDITY_PERIOD = 'Year' THEN
    V_EXPIRY_DATE := LAST_DAY(ADD_MONTHS(SYSDATE, (12 * V_EXPRYPARAM) - 1));
  END IF;*/

  --EN commented the unused code



  --msiva en added for Expiry date calculate

  IF V_REQUEST_ID IS NOT NULL THEN
    V_ISSUEFLAG := 'N';
  ELSE
    V_ISSUEFLAG := 'Y';
  END IF;

  -- If card is corporate then we need emp id  and corp id from cust_mast.
  BEGIN
    SELECT CCM_EMP_ID, CCM_CORP_CODE
     INTO V_EMP_ID, V_CORP_CODE
     FROM CMS_CUST_MAST
    WHERE CCM_INST_CODE = P_INSTCODE AND CCM_CUST_CODE = V_CUST_CODE;
  EXCEPTION
    WHEN NO_DATA_FOUND THEN
     V_ERRMSG := 'Customer code not found in master';
     RAISE EXP_REJECT_RECORD;
    WHEN OTHERS THEN
     V_ERRMSG := 'Error while selecting customer code from master' ||
               SUBSTR(SQLERRM, 1, 150);
     RAISE EXP_REJECT_RECORD;
  END;

  --Sn get member number from master
  BEGIN
    SELECT CIP_PARAM_VALUE
     INTO V_MBRNUMB
     FROM CMS_INST_PARAM
    WHERE CIP_INST_CODE = P_INSTCODE AND CIP_PARAM_KEY = 'MBR_NUMB';
  EXCEPTION
    WHEN NO_DATA_FOUND THEN
     V_ERRMSG := 'memeber number not defined in master';
     RAISE EXP_REJECT_RECORD;
    WHEN OTHERS THEN
     V_ERRMSG := 'Error while selecting memeber number ' ||
               SUBSTR(SQLERRM, 1, 200);
     RAISE EXP_REJECT_RECORD;
  END;

  --En get member number from master

--Sn proxy number
--Sn Commented for CR -38 DFC- CCF Changes
 IF  PRM_PRXY_GENFLAG  IS NOT NULL AND  PRM_PRXY_GENFLAG ='P' THEN
 --SN: VMS-6414 Changes
  BEGIN
  SELECT UPPER(TRIM(NVL(cip_param_value,'Y')))
    INTO v_toggle_value
    FROM vmscms.cms_inst_param
   WHERE cip_inst_code = 1
     AND cip_param_key = 'VMS_6414_TOGGLE';
  EXCEPTION
   WHEN NO_DATA_FOUND THEN
      v_toggle_value := 'Y';
  END;

  IF v_toggle_value = 'Y' THEN
    BEGIN
        lp_get_proxy (v_programid,v_proxylength,v_check_digit_req,v_programid_req,v_proxy_number,v_errmsg);

        IF v_errmsg != 'OK' THEN
            RAISE EXP_REJECT_RECORD;
        END IF;
    EXCEPTION
      WHEN OTHERS THEN
          v_errmsg :='Error while calling lp_get_proxy :'|| SUBSTR (SQLERRM, 1, 200);
          RAISE EXP_REJECT_RECORD;
    END;
  ELSE
  --EN: VMS-6414 Changes
  IF V_PROGRAMID_REQ = 'Y'
   THEN

    BEGIN
     --T.Narayanan added for program id generation beg
      SELECT cpi_sequence_no
                 INTO V_SEQNO
                 FROM cms_program_id_cnt
                WHERE cpi_program_id = V_PROGRAMID
               FOR UPDATE;

     V_PROXY_NUMBER :=
      fn_proxy_no (
                     NULL,
                     NULL,
                     V_PROGRAMID,
                     V_SEQNO,
                     P_INSTCODE,
                     P_LUPDUSER,
                     V_CHECK_DIGIT_REQ,
                     V_PROXYLENGTH);
       --T.Narayanan added for program id generation end
     IF V_PROXY_NUMBER = '0' THEN

       V_ERRMSG := 'Error while gen Proxy number ' ||
                SUBSTR(SQLERRM, 1, 200);
       RAISE EXP_REJECT_RECORD;
     END IF;
    EXCEPTION
     WHEN OTHERS THEN
       V_ERRMSG := 'Error while Proxy number ' || SUBSTR(SQLERRM, 1, 200);
       RAISE EXP_REJECT_RECORD;
    END;

  ELSIF V_PROGRAMID_REQ = 'N' THEN
      begin
	    SELECT ROWID,LPAD (CPC_PRXY_CNTRLNO, V_PROXYLENGTH, 0)
                 INTO V_ROW_ID,V_PROXY_NUMBER
                 FROM CMS_PRXY_CNTRL
                WHERE  CPC_INST_CODE = P_INSTCODE
                      AND CPC_PRXY_KEY = DECODE(V_PROXYLENGTH,7,'PRXYCTRL7',
                                                              8,'PRXYCTRL8',
                                                              9,'PRXYCTRL',
                                                              10,'PRXYCTRL10',
                                                              11,'PRXYCTRL11',
                                                              12,'PRXYCTRL12')
             FOR UPDATE;

    EXCEPTION
       WHEN OTHERS THEN
       V_ERRMSG := 'Error While Fetching Proxy Number' ||
                SUBSTR(SQLERRM, 1, 200);
       RAISE EXP_REJECT_RECORD;
    END;

    BEGIN
	    UPDATE CMS_PRXY_CNTRL
        SET CPC_PRXY_CNTRLNO = CPC_PRXY_CNTRLNO + 1,
        CPC_LUPD_USER    = P_LUPDUSER,
        CPC_LUPD_DATE    = SYSDATE
        WHERE ROWID =  V_ROW_ID ;
     IF SQL%ROWCOUNT = 0 THEN
       V_ERRMSG := 'Error updating Proxy  control data, record not updated successfully';
       RAISE EXP_REJECT_RECORD;
     END IF;

    EXCEPTION
     WHEN OTHERS THEN
       V_ERRMSG := 'Error updating control data ' ||
                SUBSTR(SQLERRM, 1, 150);
       RAISE EXP_REJECT_RECORD;
    END;
   -- End  Serial No Chnges added by Dhiraj Gaikwad 20082012

  END IF;
  --En proxy number
 END IF;
 END IF;
--En Commented for CR -38 DFC- CCF Changes
  --Sn create a record in appl_pan



  -------------------------------------------------
  --SN: Added for SSN validation on 12-Feb-2013
  -------------------------------------------------

      BEGIN


        /* SELECT cbp_param_value
           INTO v_prfl_status
           FROM cms_prod_mast, cms_bin_param
          WHERE cpm_inst_code = cbp_inst_code
            AND cpm_profile_code = cbp_profile_code
            AND cpm_inst_code = P_INSTCODE
            AND cpm_prod_code = v_prod_code
            AND UPPER (cbp_param_name) = 'STATUS';*/

         SELECT COUNT (1)
           INTO v_check_status
           FROM cms_ssn_cardstat
          WHERE csc_card_stat = V_CARD_STAT AND csc_stat_flag = 'Y';


      EXCEPTION
         WHEN OTHERS
         THEN
            v_errmsg :='Error while selecting profile status -'|| SUBSTR (SQLERRM, 1, 300);
            RAISE exp_reject_record;
      END;

     IF v_check_status > 0
     THEN

       BEGIN

          SELECT nvl(fn_dmaps_main(ccm_ssn_encr),ccm_ssn),
          gethash(decode(v_encrypt_enable,'Y',fn_dmaps_main(upper(ccm_first_name)),upper(ccm_first_name))||
                  decode(v_encrypt_enable,'Y',fn_dmaps_main(upper(ccm_last_name)),upper(ccm_last_name))||ccm_birth_date) --Added for MVCAN-77 of 3.1 release
            INTO v_ssn,V_FLDOB_HASHKEY_ID --Added for MVCAN-77 of 3.1 release
            FROM cms_cust_mast
           WHERE ccm_inst_code = P_INSTCODE AND ccm_cust_code = v_cust_code;

          sp_check_ssn_threshold (P_INSTCODE,
                                  v_ssn,
                                  V_PROD_CODE,
                                  v_card_type,
                                  null,               --Starter To GPR flag
                                  v_ssn_crddtls,
                                  v_resp_cde,
                                  v_errmsg,
                                  V_FLDOB_HASHKEY_ID);--Added for MVCAN-77 of 3.1 release

          IF v_errmsg <> 'OK'
          THEN
             --v_resp_cde := '157';
             RAISE EXP_REJECT_RECORD;

          END IF;

       EXCEPTION
          WHEN EXP_REJECT_RECORD
          THEN
             RAISE;
          WHEN OTHERS
          THEN
             --v_resp_cde := '21';
             v_errmsg := 'Error from SSN check- ' || SUBSTR (SQLERRM, 1, 200);
             RAISE EXP_REJECT_RECORD;
       END;

     END IF;

  -------------------------------------------------
  --EN: Added for SSN validation on 12-Feb-2013
  -------------------------------------------------

  --Sn added by Pankaj S. on 27_Feb_2013 for DFCHOST-249
   --IF  PRM_PRXY_GENFLAG  IS NOT NULL AND  PRM_PRXY_GENFLAG <> 'P' THEN
   IF  PRM_PRXY_GENFLAG  IS NOT NULL AND  PRM_PRXY_GENFLAG  = 'P' THEN

    V_PROXY_NUMBER := V_PROXY_NUMBER;

   ELSE

      BEGIN
    SELECT CAP_PROXY_NUMBER
      INTO V_PROXY_NUMBER from
      (SELECT CAP_PROXY_NUMBER
      FROM CMS_APPL_PAN
     WHERE CAP_INST_CODE=P_INSTCODE
       AND CAP_APPL_CODE=P_APPLCODE
       AND CAP_STARTERCARD_FLAG = 'Y'
       order by cap_pangen_date desc) where rownum=1;
    EXCEPTION
    WHEN NO_DATA_FOUND THEN
    V_PROXY_NUMBER:=NULL;
    WHEN OTHERS THEN
    V_ERRMSG := 'Error while selecting starter card details-'||
           SUBSTR(SQLERRM, 1, 200);
    RAISE EXP_REJECT_RECORD;
    END;
    --En added by Pankaj S. on 27_Feb_2013 for DFCHOST-249

    END IF;

	  IF PRM_PRXY_GENFLAG  = 'P'  AND V_CCF_SERIAL_FLAG = 'Y' THEN
            VMSB2BAPI.get_serials (v_product_id,
                                   1,
                                   v_serial,
                                   v_errmsg);

		    v_serial_number := v_serial(1);

		    IF v_errmsg <> 'OK'
            THEN
               RAISE EXP_REJECT_RECORD;
            END IF;
      END IF;


        --SN Added for VMS-7341
        IF v_isexpry_randm = 'Y' AND v_sweep_flag<>'Y' THEN
        BEGIN
        vmsfunutilities.get_expiry_date (P_INSTCODE,
                                         V_PROD_CODE,
                                         v_card_type,
                                         V_PROFILE_CODE,
                                         1,
                                         v_expry_arry,
                                         V_ERRMSG);
           IF V_ERRMSG<>'OK' THEN
			   RAISE EXP_REJECT_RECORD;
		   END IF;
		   
           v_expry_date:=v_expry_arry(1);
        EXCEPTION
			WHEN EXP_REJECT_RECORD THEN
			 RAISE;
			WHEN OTHERS THEN
                V_ERRMSG:='Error while calling vmsfunutilities.get_expiry_date-'||SUBSTR(SQLERRM,1,200);
				RAISE EXP_REJECT_RECORD;
        END;      
        --EN Added for VMS-7341
     --- Added for VMS- 1831 - Wrong Expiry Date Calc VISA TO MASTER MIGR

	  ELSIF V_SWEEP_FLAG<>'Y' THEN
		BEGIN
			VMSFUNUTILITIES.GET_EXPIRY_DATE(P_INSTCODE,
							V_PROD_CODE,
							V_CARD_TYPE,
							V_PROFILE_CODE,
							V_EXPRY_DATE,
							V_ERRMSG);

				IF V_ERRMSG<>'OK' THEN
					RAISE EXP_REJECT_RECORD;
				END IF;

		EXCEPTION
			WHEN EXP_REJECT_RECORD THEN
				RAISE;
			WHEN OTHERS THEN
                V_ERRMSG:='ERROR WHILE CALLING VMSFUNUTILITIES.GET_EXPIRY_DATE'||SUBSTR(SQLERRM,1,200);
				RAISE EXP_REJECT_RECORD;
		END;

     END IF;


  BEGIN

    INSERT INTO CMS_APPL_PAN
     (CAP_APPL_CODE,
      CAP_INST_CODE,
      CAP_ASSO_CODE,
      CAP_INST_TYPE,
      CAP_PROD_CODE,
      CAP_PROD_CATG,
      CAP_CARD_TYPE,
      CAP_CUST_CATG,
      CAP_PAN_CODE,
      CAP_MBR_NUMB,
      CAP_CARD_STAT,
      CAP_CUST_CODE,
      CAP_DISP_NAME,
      CAP_LIMIT_AMT,
      CAP_USE_LIMIT,
      CAP_APPL_BRAN,
      --CAP_ACTIVE_DATE,//Ramkumar.MK, active date not inserted when pan generate
      CAP_EXPRY_DATE,
      CAP_ADDON_STAT,
      CAP_ADDON_LINK,
      CAP_MBR_LINK,
      CAP_ACCT_ID,
      CAP_ACCT_NO,
      CAP_TOT_ACCT,
      CAP_BILL_ADDR,
      CAP_CHNL_CODE,
      CAP_PANGEN_DATE,
      CAP_PANGEN_USER,
      CAP_CAFGEN_FLAG,
      CAP_PIN_FLAG,
      CAP_EMBOS_FLAG,
      CAP_PHY_EMBOS,
      CAP_JOIN_FEECALC,
      CAP_NEXT_BILL_DATE,
      CAP_NEXT_MB_DATE, --added for monthly fees calc on 24012012
      CAP_REQUEST_ID,
      CAP_ISSUE_FLAG,
      CAP_INS_USER,
      CAP_LUPD_USER,
      CAP_ATM_OFFLINE_LIMIT,
      CAP_ATM_ONLINE_LIMIT,
      CAP_POS_OFFLINE_LIMIT,
      CAP_POS_ONLINE_LIMIT,
      CAP_OFFLINE_AGGR_LIMIT,
      CAP_ONLINE_AGGR_LIMIT,
      CAP_EMP_ID,
      CAP_FIRSTTIME_TOPUP,
      CAP_PANMAST_PARAM1,
      CAP_PANMAST_PARAM2,
      CAP_PANMAST_PARAM3,
      CAP_PANMAST_PARAM4,
      CAP_PANMAST_PARAM5,
      CAP_PANMAST_PARAM6,
      CAP_PANMAST_PARAM7,
      CAP_PANMAST_PARAM8,
      CAP_PANMAST_PARAM9,
      CAP_PANMAST_PARAM10,
      CAP_PAN_CODE_ENCR,
      CAP_PROXY_NUMBER,    --Uncommented by Pankaj S. on 27_Feb_2013 for DFCHOST-249  <<--Commented for CR -38 DFC- CCF Changes>>
      CAP_MMPOS_ONLINE_LIMIT,
      CAP_MMPOS_OFFLINE_LIMIT,
      CAP_STARTERCARD_FLAG, --Modified by Sivapragasam on Feb 20 2012 for Starter Card
      CAP_INACTIVE_FEECALC_DATE, --Added by Deepa on June 13 2012 for Inactive Fee Calculation
      CAP_MASK_PAN, -- Added by sagar on 06Aug2012 for Pan masking changes
      CAP_PROXY_MSG, --added by Pankaj S. on 27_Feb_2013 for DFCHOST-249
      CAP_USER_IDENTIFY_TYPE,
	  CAP_SERIAL_NUMBER
       )
    VALUES
     (P_APPLCODE,
      P_INSTCODE,
      V_ASSO_CODE,
      V_INST_TYPE,
      V_PROD_CODE,
      V_CPM_CATG_CODE,
      V_CARD_TYPE,
      V_CUST_CATG,
      V_HASH_PAN,
      V_MBRNUMB,
      V_CARD_STAT,
      V_CUST_CODE,
      V_DISP_NAME,
      V_LIMIT_AMT,
      V_USE_LIMIT,
      V_APPL_BRAN,
      -- V_ACTIVE_DATE,//Ramkumar.MK, active date not inserted when pan generate
      V_EXPRY_DATE,
      V_ADDON_STAT,
      V_ADONLINK,
      V_MBRLINK,
      V_ACCT_ID,
      V_ACCT_NUM, -- Account number is passed. Since the account nunber and the card numebr will be differnt -- changes done on 4th July 2011
      V_TOT_ACCT,
      V_BILL_ADDR,
      V_CHNL_CODE,
      SYSDATE,
      P_LUPDUSER,
      'Y',
      V_PINGEN_FLAG, -- PIN FLAG
      V_EMBOSS_FLAG, -- EMBOSS FLAG
      'N',
      'N',
      NULL, --Modified by Deepa on June 22nd
      NULL, --Modified by Deepa on June 22nd
      --added on 11/10/2002 ...next bill date is sysdate because amc for a card should be calc on the day it is gen
      V_REQUEST_ID,
      V_ISSUEFLAG,
      P_LUPDUSER,
      P_LUPDUSER,
      V_OFFLINE_ATM_LIMIT,
      V_ONLINE_ATM_LIMIT,
      V_OFFLINE_POS_LIMIT,
      V_ONLINE_POS_LIMIT,
      V_OFFLINE_AGGR_LIMIT,
      V_ONLINE_AGGR_LIMIT,
      V_EMP_ID,
      'N',
      V_APPL_DATA(1),
      V_APPL_DATA(2),
      V_APPL_DATA(3),
      V_APPL_DATA(4),
      V_APPL_DATA(5),
      V_APPL_DATA(6),
      V_APPL_DATA(7),
      V_APPL_DATA(8),
      V_APPL_DATA(9),
      V_APPL_DATA(10),
      V_ENCR_PAN,
      V_PROXY_NUMBER,--Uncommented by Pankaj S. on 27_Feb_2013 for DFCHOST-249  <<---Commented for CR -38 DFC- CCF Changes>>
      V_ONLINE_MMPOS_LIMIT,
      V_OFFLINE_MMPOS_LIMIT,
      V_STARTER_CARD, --Modified by Sivapragasam on Feb 20 2012 for Starter Card
      NULL, --Modified by Deepa on June 22nd
      V_MASK_PAN, -- Added by sagar on 06Aug2012 for Pan masking changes
      DECODE(NVL(V_PROXY_NUMBER,0),0,NULL,'Success'), --added by Pankaj S. on 27_Feb_2013 for DFCHOST-249
      V_USER_IDENTIFY_TYPE,
	  V_SERIAL_NUMBER
      );

  EXCEPTION
    WHEN DUP_VAL_ON_INDEX THEN
     V_ERRMSG := 'Pan ' || fn_getmaskpan(V_PAN) -- Masked pan will be returned if error occures instead of clear pan (Sagar-30-Aug-2012)
               || ' is already present in the Pan_master';
     RAISE EXP_REJECT_RECORD;
    WHEN OTHERS THEN
     V_ERRMSG := 'Error while inserting records into pan master ' ||
               SUBSTR(SQLERRM, 1, 200);
     RAISE EXP_REJECT_RECORD;
  END;



  --Inserting in card issuance status table
  BEGIN
    INSERT INTO CMS_CARDISSUANCE_STATUS
     (CCS_INST_CODE,
      CCS_PAN_CODE,
      CCS_CARD_STATUS,
      CCS_INS_USER,
      CCS_LUPD_USER,
      CCS_PAN_CODE_ENCR,
      CCS_LUPD_DATE,
      CCS_APPL_CODE)
    VALUES
     (P_INSTCODE,
      V_HASH_PAN,
      2,
      P_LUPDUSER,
      P_LUPDUSER,
      V_ENCR_PAN,
      SYSDATE,
      P_APPLCODE);
  EXCEPTION
    WHEN OTHERS THEN
     V_ERRMSG := 'Error while Inserting in Card status Table ' ||
               SUBSTR(SQLERRM, 1, 200);
     RAISE EXP_REJECT_RECORD;
  END;

  --End

  --En create a record in appl_pan
  BEGIN
    INSERT INTO CMS_SMSANDEMAIL_ALERT
     (CSA_INST_CODE,
      CSA_PAN_CODE,
      CSA_PAN_CODE_ENCR,
      CSA_LOADORCREDIT_FLAG,
      CSA_LOWBAL_FLAG,
      CSA_NEGBAL_FLAG,
      CSA_HIGHAUTHAMT_FLAG,
      CSA_DAILYBAL_FLAG,
      CSA_INSUFF_FLAG,
      CSA_INCORRPIN_FLAG,
      CSA_FAST50_FLAG, -- Added by MageshKumar.S on 19/09/2013 for JH-6
      CSA_FEDTAX_REFUND_FLAG, -- Added by MageshKumar.S on 19/09/2013 for JH-6
      CSA_DEPPENDING_FLAG,CSA_DEPACCEPTED_FLAG,CSA_DEPREJECTED_FLAG, -- Added by Raja Gopal G on 30/07/2014 fro FR 3.2
      CSA_INS_USER,
      CSA_INS_DATE)
    VALUES
     (P_INSTCODE,
      V_HASH_PAN,
      V_ENCR_PAN,
      0,
      0,
      0,
      0,
      0,
      0,
      0,
      0, -- Added by MageshKumar.S on 19/09/2013 for JH-6
      0, -- Added by MageshKumar.S on 19/09/2013 for JH-6
       0, 0, 0, -- Added by Raja Gopal G on 30/07/2014 fro FR 3.2
      P_LUPDUSER,
      SYSDATE);
  exception
  WHEN DUP_VAL_ON_INDEX then null;
    WHEN OTHERS THEN
     V_ERRMSG := 'Error while inserting records into SMS_EMAIL ALERT ' ||
               SUBSTR(SQLERRM, 1, 200);
     RAISE EXP_REJECT_RECORD;
  END;



  --Sn create record in pan_acct
  FOR X IN C1(P_APPLCODE) LOOP
    BEGIN
     INSERT INTO CMS_PAN_ACCT
       (CPA_INST_CODE,
        CPA_CUST_CODE,
        CPA_ACCT_ID,
        CPA_ACCT_POSN,
        CPA_PAN_CODE,
        CPA_MBR_NUMB,
        CPA_INS_USER,
        CPA_LUPD_USER,
        CPA_PAN_CODE_ENCR)
     VALUES
       (P_INSTCODE,
        V_CUST_CODE,
        X.CAD_ACCT_ID,
        X.CAD_ACCT_POSN,
        --v_pan            ,
        V_HASH_PAN,
        V_MBRNUMB,
        P_LUPDUSER,
        P_LUPDUSER,
        V_ENCR_PAN);

     EXIT WHEN C1%NOTFOUND;
    EXCEPTION
     WHEN DUP_VAL_ON_INDEX THEN
       V_ERRMSG := 'Duplicate record exist  in pan acct master for pan  ' ||
                fn_getmaskpan(V_PAN) -- Masked pan will be returned if error occures instead of clear pan (Sagar-30-Aug-2012)
                || 'acct id ' || X.CAD_ACCT_ID;
       RAISE EXP_REJECT_RECORD;
     WHEN OTHERS THEN
       V_ERRMSG := 'Error while inserting records into pan acct  master ' ||
                SUBSTR(SQLERRM, 1, 200);
       RAISE EXP_REJECT_RECORD;
    END;
  END LOOP;

  --En create record in pan_acct



  --Sn update Corporate Card for pan.
  BEGIN
    UPDATE CMS_CORPORATE_CARDS
      SET PCC_PAN_NO      = V_HASH_PAN --v_pan
        ,
         PCC_PAN_NO_ENCR = V_ENCR_PAN
    WHERE PCC_INST_CODE = P_INSTCODE AND PCC_PAN_NO = V_ACCT_NUM;
  EXCEPTION
    WHEN EXP_REJECT_RECORD THEN
     RAISE;
    WHEN OTHERS THEN
     V_ERRMSG := 'Error while updating corporate_card account number ' ||
               SUBSTR(SQLERRM, 1, 200);
     RAISE EXP_REJECT_RECORD;
  END;

  --En update acct_mast for pan

  --Sn update Corporate Card for pan.
  BEGIN
    UPDATE CMS_MERCHANT_CARDS
      SET PCC_PAN_NO      = V_HASH_PAN --v_pan
        ,
         PCC_PAN_NO_ENCR = V_ENCR_PAN
    WHERE PCC_INST_CODE = P_INSTCODE AND PCC_PAN_NO = V_ACCT_NUM;
  EXCEPTION
    WHEN EXP_REJECT_RECORD THEN
     RAISE;
    WHEN OTHERS THEN
     V_ERRMSG := 'Error while updating corporate_card account number ' ||
               SUBSTR(SQLERRM, 1, 200);
     RAISE EXP_REJECT_RECORD;
  END;
  --En update acct_mast for pan

  --SN - Commented for fwr-48

  --Sn find the GL  detail for the func code
 /* BEGIN
    SELECT CFP_CRGL_CODE,
         CFP_CRGL_CATG,
         CFP_CRSUBGL_CODE,
         CFP_CRACCT_NO,
         CFP_DRGL_CODE,
         CFP_DRGL_CATG,
         CFP_DRSUBGL_CODE,
         CFP_DRACCT_NO
     INTO V_CR_GL_CODE,
         V_CRGL_CATG,
         V_CRSUBGL_CODE,
         V_CRACCT_NO,
         V_DR_GL_CODE,
         V_DRGL_CATG,
         V_DRSUBGL_CODE,
         V_DRACCT_NO
     FROM CMS_FUNC_PROD
    WHERE CFP_INST_CODE = P_INSTCODE AND CFP_FUNC_CODE = 'CRDISS' AND
         CFP_PROD_CODE = V_PROD_CODE AND CFP_PROD_CATTYPE = V_CARD_TYPE;
  EXCEPTION
    WHEN NO_DATA_FOUND THEN
     V_ERRMSG := 'GL detail is not defined for func code  Card Issuance  prod code ' ||
               V_PROD_CODE || 'card type ' || V_CARD_TYPE;
     RAISE EXP_REJECT_RECORD;
    WHEN OTHERS THEN
     V_ERRMSG := 'Error while selecting gl details for card issuance ' ||
               SUBSTR(SQLERRM, 1, 200);
     RAISE EXP_REJECT_RECORD;
  END;

  --En find the GL  detail for the func code
  IF V_CR_GL_CODE IS NULL OR V_CRSUBGL_CODE IS NULL THEN
    V_ERRMSG := 'Credit GL or SUB  GL cannot be null for card issuance';
    RAISE EXP_REJECT_RECORD;
  END IF;

  -- Sn create a record in GL_ACCT mast
  BEGIN
    SELECT 1
     INTO V_GL_CHECK
     FROM CMS_GL_MAST
    WHERE CGM_INST_CODE = P_INSTCODE AND CGM_GL_CODE = V_CR_GL_CODE;
  EXCEPTION
    WHEN NO_DATA_FOUND THEN
     V_ERRMSG := 'GL code is not defined for txn code ' || V_CR_GL_CODE;
     RAISE EXP_REJECT_RECORD;
    WHEN OTHERS THEN
     V_ERRMSG := 'Error while selecting gl code from master ' ||
               SUBSTR(SQLERRM, 1, 300);
     RAISE EXP_REJECT_RECORD;
  END;

  BEGIN
    SELECT CSM_SUBGL_DESC
     INTO V_SUBGL_DESC
     FROM CMS_SUB_GL_MAST
    WHERE CSM_INST_CODE = P_INSTCODE AND CSM_GL_CODE = V_CR_GL_CODE AND
         CSM_SUBGL_CODE = V_CRSUBGL_CODE;
  EXCEPTION
    WHEN NO_DATA_FOUND THEN
     V_ERRMSG := 'Sub gl code is not defined for txn code ' ||
               V_CR_GL_CODE;
     RAISE EXP_REJECT_RECORD;
    WHEN OTHERS THEN
     V_ERRMSG := 'Error while selecting sub gl code from master ' ||
               SUBSTR(SQLERRM, 1, 300);
     RAISE EXP_REJECT_RECORD;
  END;

  BEGIN
    INSERT INTO CMS_GL_ACCT_MAST
     (CGA_INST_CODE,
      CGA_GLCATG_CODE,
      CGA_GL_CODE,
      CGA_SUBGL_CODE,
      CGA_ACCT_CODE,
      CGA_ACCT_DESC,
      CGA_TRAN_AMT,
      CGA_GLSUBGLACCT_FLAG,
      CGA_INS_DATE,
      CGA_LUPD_USER,
      CGA_LUPD_DATE)
    VALUES
     (P_INSTCODE,
      SUBSTR(V_CRGL_CATG, 1, 1),
      V_CR_GL_CODE,
      V_CRSUBGL_CODE,
      --V_PAN,
      V_ACCT_NUM, --Modified by Ramkumar.Mk on 21 Aug, Acctnum inserted
      V_SUBGL_DESC || 'acct',
      0,
      'Y', --Modified by Ramkumar.mK on 21 Aug, when card generated, glsubglacct flag will be Y
      SYSDATE,
      P_LUPDUSER,
      SYSDATE);
  EXCEPTION
    WHEN DUP_VAL_ON_INDEX THEN */ --EN - Commented for fwr-48
     --T.Narayanan. commented for reason no need to raise exception if dup val index found. begin
     /*     V_ERRMSG := 'Problem while inserting records into glacctmast duplicate record found for acct code ' ||
                V_CRACCT_NO;
      RAISE EXP_REJECT_RECORD;*/
  /*   NULL; --SN - Commented for fwr-48
     --T.Narayanan. commented for reason no need to raise exception if dup val index found. end
    WHEN OTHERS THEN
     V_ERRMSG := 'Error while selecting sub gl code from master ' ||
               SUBSTR(SQLERRM, 1, 300);
     RAISE EXP_REJECT_RECORD;
  END; */

  -- En create a record in GL_ACCT mast

  --EN - Commented for fwr-48

  -- Sn Create a entry for initial load
  IF V_INITIAL_TOPUP_AMOUNT > 0 THEN

  --SN - Commented for fwr-48
    --Sn find f to txn code , type, delchannel attached to function code
  /*  BEGIN
     SELECT CFM_TXN_CODE,
           CFM_TXN_MODE,
           CFM_DELIVERY_CHANNEL,
           CFM_TXN_TYPE,
           CFM_FUNC_DESC
       INTO V_TRAN_CODE,
           V_TRAN_MODE,
           V_DELV_CHNL,
           V_TRAN_TYPE,
           V_FUNC_DESC
       FROM CMS_FUNC_MAST
      WHERE CFM_FUNC_CODE = 'INILOAD' AND CFM_INST_CODE = P_INSTCODE;
    EXCEPTION
     WHEN NO_DATA_FOUND THEN
       V_ERRMSG := V_FUNC_DESC ||
                'Function code not defined for txn code ';
       RAISE EXP_REJECT_RECORD;
     WHEN TOO_MANY_ROWS THEN
       V_ERRMSG := 'More than one function defined for txn code ' ||
                V_TRAN_CODE;
       RAISE EXP_REJECT_RECORD;
     WHEN OTHERS THEN
       V_ERRMSG := 'Error while selecting func code from master ' ||
                SUBSTR(SQLERRM, 1, 300);
       RAISE EXP_REJECT_RECORD;
    END; */

    --En find function code attached to txn code

    --EN - Commented for fwr-48

    BEGIN
     --Sn create gl data
     SP_CREATE_ISSUANCE_GL_DATA -- FOR INITIAL LOAD
     (P_INSTCODE,
      SYSDATE,
      V_TRAN_CODE,
      V_TRAN_MODE,
      V_TRAN_TYPE,
      V_DELV_CHNL,
      V_PAN,
      V_PROD_CODE,
      V_CARD_TYPE,
      null,-- V_CR_GL_CODE, -- Commented for fwr-48
      null,-- V_CRSUBGL_CODE, -- Commented for fwr-48
      V_INITIAL_TOPUP_AMOUNT,
      P_LUPDUSER,
      V_ERRMSG);

     --En create gl data
     IF (V_ERRMSG <> 'OK') THEN
       RAISE EXP_REJECT_RECORD;
     END IF;
     --Sn update flag in appl_pan for initial load
    EXCEPTION
     WHEN OTHERS THEN
       V_ERRMSG := 'Error while calling SP_CREATE_ISSUANCE_GL_DATA ' ||
                SUBSTR(SQLERRM, 1, 300);
       RAISE EXP_REJECT_RECORD;
    END;

    --En update flag in appl_pan for initial load
  END IF;
  --En create entry for initial load

  --Sn update flag in appl_mast
  BEGIN
    UPDATE CMS_APPL_MAST
      SET CAM_APPL_STAT   = 'O',
         CAM_LUPD_USER   = P_LUPDUSER,
         CAM_PROCESS_MSG = 'SUCCESSFUL'
    WHERE CAM_INST_CODE = P_INSTCODE AND CAM_APPL_CODE = P_APPLCODE;
  EXCEPTION
    WHEN OTHERS THEN
     V_ERRMSG := 'Error while updating records in appl mast  ' ||
               SUBSTR(SQLERRM, 1, 200);
     RAISE EXP_REJECT_RECORD;
  END;

  --En update flag in appl_mast
  /* T.NARAYANAN. ADDED - AUDIT LOG REPORT  BEG*/
  BEGIN
    INSERT INTO CMS_AUDIT_LOG_PROCESS
     (CAL_INST_CODE,
      CAL_APPL_NO,
      CAL_ACCT_NO,
      CAL_PAN_NO,
      CAL_PROD_CODE,
      CAL_PRG_NAME,
      CAL_ACTION,
      CAL_STATUS,
      CAL_REF_TAB_NAME,
      CAL_REF_TAB_ROWID,
      CAL_PAN_ENCR,
      CAL_INS_USER,
      CAL_INS_DATE)
    VALUES
     (P_INSTCODE,
      P_APPLCODE,
      V_ACCT_NUM,
      V_HASH_PAN,
      (SELECT CPM.CPM_PROD_DESC
        FROM CMS_PROD_MAST CPM
        WHERE CPM.CPM_PROD_CODE = V_PROD_CODE),
      'PAN GENERATION',
      'INSERT',
      DECODE(V_ERRMSG, 'OK', 'SUCCESS', 'FAILURE'),
      --                   P_ip_addr,
      'CMS_APPL_PAN',
      '',
      FN_EMAPS_MAIN(V_PAN),
      P_LUPDUSER,
      SYSDATE);
  EXCEPTION
    WHEN OTHERS THEN
     V_ERRMSG := 'Error while inserting CMS_AUDIT_LOG_PROCESS ' ||
               SUBSTR(SQLERRM, 1, 200);
     RAISE EXP_REJECT_RECORD;
  END;

  /* T.NARAYANAN. ADDED - AUDIT LOG REPORT  END*/
  P_ERRMSG          := 'OK';
  P_APPLPROCESS_MSG := 'OK';



EXCEPTION
  WHEN EXP_REJECT_RECORD THEN
    ROLLBACK TO V_SAVEPOINT;
    P_ERRMSG := V_ERRMSG;

    IF V_DONOT_MARK_ERROR <> 1 THEN
     UPDATE CMS_APPL_MAST
        SET CAM_APPL_STAT   = 'E',
           CAM_PROCESS_MSG = V_ERRMSG,
           CAM_LUPD_USER   = P_LUPDUSER
      WHERE CAM_INST_CODE = P_INSTCODE AND CAM_APPL_CODE = P_APPLCODE;
    ELSIF V_DONOT_MARK_ERROR = 1 THEN
     INSERT INTO CMS_SERL_ERROR
       (CSE_INST_CODE,
        CSE_PROD_CODE,
        CSE_PROD_CATG,
        CSE_ORDR_RFRNO,
        CSE_ERR_MSEG)
     VALUES
       (P_INSTCODE, V_PROD_CODE, V_CARD_TYPE, V_CAM_FILE_NAME, V_ERRMSG);
    END IF;
    P_APPLPROCESS_MSG := V_ERRMSG;
    P_ERRMSG          := 'OK';
  WHEN OTHERS THEN
    ROLLBACK TO V_SAVEPOINT;
    P_APPLPROCESS_MSG := 'Error while processing application for pan gen ' ||
                    SUBSTR(SQLERRM, 1, 200);
    V_ERRMSG          := 'Error while processing application for pan gen ' ||
                    SUBSTR(SQLERRM, 1, 200);

    UPDATE CMS_APPL_MAST
      SET CAM_APPL_STAT   = 'E',
         CAM_PROCESS_MSG = V_ERRMSG,
         CAM_LUPD_USER   = P_LUPDUSER
    WHERE CAM_INST_CODE = P_INSTCODE AND CAM_APPL_CODE = P_APPLCODE;

    P_ERRMSG := 'OK';
END;
/
show error;