create or replace PROCEDURE                      VMSCMS.SP_ORDER_REISSUEPAN_CMS(PRM_INSTCODE     IN NUMBER,
                                          PRM_PANCODE      IN NUMBER,
                                          PRM_NEW_PRODCODE IN VARCHAR2,
                                          PRM_NEW_CARDTYPE IN VARCHAR2,
                                          PRM_NEW_DISPNAME IN VARCHAR2,
                                          PRM_LUPDUSER     IN NUMBER,
                                          PRM_PAN          OUT VARCHAR2,
                                          --  prm_applprocess_msg   OUT      VARCHAR2,
                                          PRM_ERRMSG OUT VARCHAR2) AS

  /*************************************************************************************
    * VERSION          : 1.0
    * Created Date     : 25/APR/2009
    * Created By       : Kaustubh.Dave
    * Modified By      : Dhiraj Gaikwad
    * Modified Date    : 27-Sep-12
    * Modified Reason  : Updating Serial number is used against prod and prod catagory
    * Reviewer         : B.Besky Anand.
    * Reviewed Date    : 31-Aug-2012
    * Release Number   : CMS3.5.1_RI0016

    * Modified By      : Pankaj S.
    * Modified Date    : 27-Feb-2013
    * Modified For     : DFCHOST-249
    * Modified Reason  : Update Success message in cms_appl_pan table for the reissued card..
    * Reviewer         : Dhiraj
    * Reviewed Date    :
    * Release Number   : CMS3.5.1_RI0023.2_B00011

    * Modified By      : Sagar
    * Modified Date    : 26-Mar-2013
    * Modified For     : NA
    * Modified Reason  : Performance Issue
    * Reviewer         : Dhiraj
    * Reviewed Date    :
    * Release Number   : CMS3.5.1_RI0024.1_B0002

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
	* Reviewer         :  Dhiraj
	* Reviewed Date    :  03/09/2013
	* Build Number     :  RI0024.3.6_B0002


	 * Modified by      : Saravana Kumar A
	 * Modified Date    : 23-SEP-15
	 * Modified reason  : Card Expiry date logic changes
	 * Reviewer         : Spankaj
	 * Build Number     : VMSGPRHOST3.2_B0002
   
   
   * Modified by      : Saravana Kumar A
* Modified Date    : 07-Jan-17
* Modified reason  : Card Expiry date logic changes
* Reviewer         : Spankaj
* Build Number     : VMSGPRHOST17.1



 * Modified by      : Saravana Kumar A
 * Modified Date    : 10-Apr-17
 * Modified reason  : sweep changes
 * Reviewer         : Spankaj
 * Build Number     : VMSGPRHOST17.04
 
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
	 
	 * Modified By      : Vini Pushkaran
     * Modified Date    : 27-Feb-2018
     * Purpose          : VMS-161
     * Reviewer         : Saravanakumar
     * Release Number   : VMSGPRHOST18.02
     
     * Modified By      : Bhavani E
     * Modified Date    : 23-SEP-2022
     * Purpose          : VMS-5349
     * Reviewer         : Venkat S
     * Release Number   : VMSGPRHOST_R69
     
     * Modified By      : Pankaj S.
     * Modified Date    : 15-Feb-2023
     * Purpose          : VMS-6656
     * Reviewer         : Venkat S.
     * Release Number   : R78
     
     * Modified By      : Shanmugavel
     * Modified Date    : 23/01/2024
     * Purpose          : VMS-8219-Remove the Default Status in the Product Category Profile Screen on the Host UI
     * Reviewer         : Venkat/John/Pankaj
     * Release Number   : VMSGPRHOSTR92

  *************************************************************************************/

  V_INST_CODE             CMS_APPL_PAN.CAP_INST_CODE%TYPE;
  V_ASSO_CODE             CMS_APPL_PAN.CAP_ASSO_CODE%TYPE;
  V_INST_TYPE             CMS_APPL_PAN.CAP_INST_TYPE%TYPE;
  V_PROD_CODE             CMS_APPL_PAN.CAP_PROD_CODE%TYPE;
  V_APPL_BRAN             CMS_APPL_PAN.CAP_APPL_BRAN%TYPE;
  V_CUST_CODE             CMS_APPL_PAN.CAP_CUST_CODE%TYPE;
  V_CARD_TYPE             CMS_APPL_PAN.CAP_CARD_TYPE%TYPE;
  V_CUST_CATG             CMS_APPL_PAN.CAP_CUST_CATG%TYPE;
  V_DISP_NAME             CMS_APPL_PAN.CAP_DISP_NAME%TYPE;
  V_ACTIVE_DATE           CMS_APPL_PAN.CAP_ACTIVE_DATE%TYPE;
  V_EXPRY_DATE            CMS_APPL_PAN.CAP_EXPRY_DATE%TYPE;
  V_ADDON_STAT            CMS_APPL_PAN.CAP_ADDON_STAT%TYPE;
  V_TOT_ACCT              CMS_APPL_PAN.CAP_TOT_ACCT%TYPE;
  V_CHNL_CODE             CMS_APPL_PAN.CAP_CHNL_CODE%TYPE;
  V_LIMIT_AMT             CMS_APPL_PAN.CAP_LIMIT_AMT%TYPE;
  V_USE_LIMIT             CMS_APPL_PAN.CAP_USE_LIMIT%TYPE;
  V_BILL_ADDR             CMS_APPL_PAN.CAP_BILL_ADDR%TYPE;
  V_REQUEST_ID            CMS_APPL_PAN.CAP_REQUEST_ID%TYPE;
  V_CAP_ADDON_LINK        CMS_APPL_PAN.CAP_ADDON_LINK%TYPE;
  V_TMP_PAN               CMS_APPL_PAN.CAP_PAN_CODE%TYPE;
  V_ADONLINK              CMS_APPL_PAN.CAP_PAN_CODE%TYPE;
  V_MBRLINK               CMS_APPL_PAN.CAP_MBR_NUMB%TYPE;
  V_CARD_STAT             CMS_APPL_PAN.CAP_CARD_STAT%TYPE;
  V_OFFLINE_ATM_LIMIT     CMS_APPL_PAN.CAP_ATM_OFFLINE_LIMIT%TYPE;
  V_ONLINE_ATM_LIMIT      CMS_APPL_PAN.CAP_ATM_ONLINE_LIMIT%TYPE;
  V_ONLINE_POS_LIMIT      CMS_APPL_PAN.CAP_POS_ONLINE_LIMIT%TYPE;
  V_OFFLINE_POS_LIMIT     CMS_APPL_PAN.CAP_POS_OFFLINE_LIMIT%TYPE;
  V_OFFLINE_AGGR_LIMIT    CMS_APPL_PAN.CAP_OFFLINE_AGGR_LIMIT%TYPE;
  V_ONLINE_AGGR_LIMIT     CMS_APPL_PAN.CAP_ONLINE_AGGR_LIMIT%TYPE;
  V_PAN                   CMS_APPL_PAN.CAP_PAN_CODE%TYPE;
  V_CAP_FIRSTTIME_TOPUP   CMS_APPL_PAN.CAP_FIRSTTIME_TOPUP%TYPE;
  V_APPL_STAT             CMS_APPL_MAST.CAM_APPL_STAT%TYPE;
  V_BIN                   CMS_BIN_MAST.CBM_INST_BIN%TYPE;
  V_PROFILE_CODE          CMS_PROD_CATTYPE.CPC_PROFILE_CODE%TYPE;
  V_ERRMSG                VARCHAR2(500);
  V_HSM_MODE              CMS_INST_PARAM.CIP_PARAM_VALUE%TYPE;
  V_PINGEN_FLAG           VARCHAR2(1);
  V_EMBOSS_FLAG           VARCHAR2(1);
  V_LOOP_CNT              NUMBER DEFAULT 0;
  V_LOOP_MAX_CNT          NUMBER;
  V_NOOF_PAN_PARAM        NUMBER;
  V_INST_BIN              CMS_PROD_BIN.CPB_INST_BIN%TYPE;
  V_SERIAL_INDEX          NUMBER;
  V_SERIAL_MAXLENGTH      NUMBER(2);
  V_SERIAL_NO             NUMBER;
  V_CHECK_DIGIT           NUMBER;
  V_ACCT_ID               CMS_APPL_PAN.CAP_ACCT_ID%TYPE;
  V_ACCT_NUM              CMS_APPL_PAN.CAP_ACCT_NO%TYPE;
  V_HOLD_COUNT            CMS_ACCT_MAST.CAM_HOLD_COUNT%TYPE;
  V_CURR_BRAN             CMS_ACCT_MAST.CAM_CURR_BRAN%TYPE;
  V_CAM_BILL_ADDR         CMS_ACCT_MAST.CAM_BILL_ADDR%TYPE;
  V_TYPE_CODE             CMS_ACCT_MAST.CAM_TYPE_CODE%TYPE;
  V_STAT_CODE             CMS_ACCT_MAST.CAM_STAT_CODE%TYPE;
  V_ACCT_BAL              CMS_ACCT_MAST.CAM_ACCT_BAL%TYPE;
  V_CAM_ADDON_LINK        CMS_APPL_MAST.CAM_ADDON_LINK%TYPE;
  V_PROD_PREFIX           CMS_PROD_CATTYPE.CPC_PROD_PREFIX%TYPE;
  V_CPM_CATG_CODE         CMS_PROD_MAST.CPM_CATG_CODE%TYPE;
  V_ISSUEFLAG             VARCHAR2(1);
  V_INITIAL_TOPUP_AMOUNT  CMS_APPL_MAST.CAM_INITIAL_TOPUP_AMOUNT%TYPE;
  V_FUNC_CODE             CMS_FUNC_MAST.CFM_FUNC_CODE%TYPE;
  V_FUNC_DESC             CMS_FUNC_MAST.CFM_FUNC_DESC%TYPE;
  V_CR_GL_CODE            CMS_FUNC_PROD.CFP_CRGL_CODE%TYPE;
  V_CRGL_CATG             CMS_FUNC_PROD.CFP_CRGL_CATG%TYPE;
  V_CRSUBGL_CODE          CMS_FUNC_PROD.CFP_CRSUBGL_CODE%TYPE;
  V_CRACCT_NO             CMS_FUNC_PROD.CFP_CRACCT_NO%TYPE;
  V_DR_GL_CODE            CMS_FUNC_PROD.CFP_DRGL_CODE%TYPE;
  V_DRGL_CATG             CMS_FUNC_PROD.CFP_DRGL_CATG%TYPE;
  V_DRSUBGL_CODE          CMS_FUNC_PROD.CFP_DRSUBGL_CODE%TYPE;
  V_DRACCT_NO             CMS_FUNC_PROD.CFP_DRACCT_NO%TYPE;
  V_GL_CHECK              NUMBER(1);
  V_SUBGL_DESC            VARCHAR2(30);
  V_TRAN_CODE             CMS_FUNC_MAST.CFM_TXN_CODE%TYPE;
  V_TRAN_MODE             CMS_FUNC_MAST.CFM_TXN_MODE%TYPE;
  V_DELV_CHNL             CMS_FUNC_MAST.CFM_DELIVERY_CHANNEL%TYPE;
  V_TRAN_TYPE             CMS_FUNC_MAST.CFM_TXN_TYPE%TYPE;
  V_EXPRYPARAM            CMS_BIN_PARAM.CBP_PARAM_VALUE%TYPE;
  V_MBRNUMB               CMS_APPL_PAN.CAP_MBR_NUMB%TYPE;
  V_NEXT_BILL_DATE        DATE;
  V_PBFGEN_FLAG           CHAR(1);
  V_NEXT_MB_DATE          DATE;
  V_ACCTID_NEW            NUMBER;
  V_HOLDPOSN              NUMBER;
  V_HOST_PROC             CMS_INST_PARAM.CIP_PARAM_VALUE%TYPE;
  V_DUP_FLAG              CHAR(1);
  V_OLD_GL_CATG           CMS_GL_ACCT_MAST.CGA_GLCATG_CODE%TYPE;
  V_OLD_GL_CODE           CMS_GL_ACCT_MAST.CGA_GL_CODE%TYPE;
  V_OLD_SUB_GL_CODE       CMS_GL_ACCT_MAST.CGA_SUBGL_CODE%TYPE;
  V_OLD_ACCT_DESC         CMS_GL_ACCT_MAST.CGA_ACCT_DESC%TYPE;
  V_SAVEPOINT             NUMBER DEFAULT 1;
  V_ACCT_NUMB             CMS_ACCT_MAST.CAM_ACCT_NO%TYPE;
  V_CARDTYPE_PROFILE_CODE CMS_PROD_CATTYPE.CPC_PROFILE_CODE%TYPE;
  V_APPL_DATA             TYPE_APPL_REC_ARRAY;
  V_CHECK_CARDTYPE        NUMBER(1);
  V_CHECK_CUSTCARG        NUMBER(1);
  V_HASH_PAN              CMS_APPL_PAN.CAP_PAN_CODE%TYPE;
  V_HASH_NEW_PAN          CMS_APPL_PAN.CAP_PAN_CODE%TYPE;
  V_ENCR_NEW_PAN          CMS_APPL_PAN.CAP_PAN_CODE%TYPE;
  -- added for reissue  new pan number  26042012
    v_validity_period             CMS_BIN_PARAM.cbp_param_value%type;
  -- added for reissue new pan number  26042012

  v_mask_pan                cms_appl_pan.cap_mask_pan%TYPE; -- Added by sagar on 13Aug2012 for Pan masking changes
  V_CPC_SERL_FLAG CMS_PROD_CATTYPE.CPC_SERL_FLAG%type; -- Added by Dhiraj Gaikwad  for Serial Number CR  20022012
  p_shflcntrl_no           NUMBER (9);
  v_exp_date_exemption     cms_prod_cattype.cpc_exp_date_exemption%TYPE;
  v_sweep_flag              cms_prod_cattype.cpc_sweep_flag%type;
  v_pan_inventory_flag    cms_prod_cattype.cpc_pan_inventory_flag%TYPE;  --Added for 17.07 PAN Inventory Changes
  v_user_identify_type cms_prod_cattype.cpc_user_identify_type%type;
  v_prod_suffix  cms_prod_cattype.cpc_prod_suffix%TYPE;
  v_card_start  cms_prod_cattype.cpc_start_card_no%TYPE;
  v_card_end cms_prod_cattype.cpc_end_card_no%TYPE;
  v_prodprefx_index         NUMBER;
  v_prefix                  VARCHAR2(10);
  v_starter_card    cms_prod_cattype.cpc_starter_card%TYPE;
--  
--  TYPE REC_PAN_CONSTRUCT IS RECORD(
--    CPC_PROFILE_CODE CMS_PAN_CONSTRUCT.CPC_PROFILE_CODE%TYPE,
--    CPC_FIELD_NAME   CMS_PAN_CONSTRUCT.CPC_FIELD_NAME%TYPE,
--    CPC_START_FROM   CMS_PAN_CONSTRUCT.CPC_START_FROM%TYPE,
--    CPC_START        CMS_PAN_CONSTRUCT.CPC_START%TYPE,
--    CPC_LENGTH       CMS_PAN_CONSTRUCT.CPC_LENGTH%TYPE,
--    CPC_FIELD_VALUE  VARCHAR2(30));
--  TYPE TABLE_PAN_CONSTRUCT IS TABLE OF REC_PAN_CONSTRUCT INDEX BY BINARY_INTEGER;
  --Account related data
--  V_SEG31ACCTNUM_DATA   TYPE_ACCT_REC_ARRAY;
--  V_TABLE_PAN_CONSTRUCT TABLE_PAN_CONSTRUCT;
  EXP_REJECT_RECORD EXCEPTION;
  v_param_val cms_inst_param.cip_param_value%type; --added for VMS-5349 By Bhavani 
  V_PROXY_NUMBER CMS_APPL_PAN.CAP_PROXY_NUMBER%TYPE;
  V_APPL_CODE    CMS_APPL_PAN.CAP_APPL_CODE%TYPE;
  v_toggle_value  cms_inst_param.cip_param_value%TYPE;  --Added for VMS-6656
--  CURSOR C(P_PROFILE_CODE IN VARCHAR2) IS
--    SELECT CPC_PROFILE_CODE,
--         CPC_FIELD_NAME,
--         CPC_START_FROM,
--         CPC_LENGTH,
--         CPC_START
--     FROM CMS_PAN_CONSTRUCT
--    WHERE CPC_PROFILE_CODE = P_PROFILE_CODE AND
--         CPC_INST_CODE = PRM_INSTCODE
--    ORDER BY CPC_START_FROM DESC;
  --CURSOR C1(PAN_CODE IN NUMBER) IS  -- Commented by sagar as PAN_CODE is not used in cursor query
    CURSOR C1 IS                      -- Added by sagar as PAN_CODE is not used in cursor query
    SELECT CPA_ACCT_ID, CPA_ACCT_POSN
     FROM CMS_PAN_ACCT
    WHERE CPA_PAN_CODE = V_HASH_PAN --prm_pancode
         AND CPA_INST_CODE = PRM_INSTCODE;
  -----------------------------------------SN   LOCAL PROCEDURES  ----------------------------------------
  PROCEDURE LP_PAN_BIN(L_INSTCODE  IN NUMBER,
                   L_INSTTYPE  IN NUMBER,
                   L_PROD_CODE IN VARCHAR2,
                   L_PAN_BIN   OUT NUMBER,
                   L_ERRMSG    OUT VARCHAR2) IS
  BEGIN
    SELECT CPB_INST_BIN
     INTO L_PAN_BIN
     FROM CMS_PROD_BIN
    WHERE CPB_INST_CODE = L_INSTCODE AND CPB_PROD_CODE = L_PROD_CODE AND
         CPB_MARC_PRODBIN_FLAG = 'N' AND CPB_ACTIVE_BIN = 'Y';
    L_ERRMSG := 'OK';
  EXCEPTION
    WHEN NO_DATA_FOUND THEN
     L_ERRMSG := 'Excp1 LP1 -- No prefix  found for combination of Institution ' ||
               L_INSTCODE || ' and product ' || L_PROD_CODE;
    WHEN OTHERS THEN
     L_ERRMSG := 'Excp1 LP1 -- ' || SQLERRM;
  END;
  ------------------------------------EN   LOCAL PROCEDURES  ----------------------------------
--  ---------------------------------------SN   LOCAL PROCEDURES  ----------------------------------
--  PROCEDURE LP_PAN_SRNO(L_INSTCODE   IN NUMBER,
--                    L_LUPDUSER   IN NUMBER,
--                    L_TMP_PAN    IN VARCHAR2,
--                    L_MAX_LENGTH IN NUMBER,
--                    L_SRNO       OUT VARCHAR2,
--                    L_ERRMSG     OUT VARCHAR2) IS
--    V_CTRLNUMB      NUMBER;
--    V_MAX_SERIAL_NO NUMBER;
--    --Sn Added by Pankaj S. on 08_May_2013 for mantis ID-11048
--    excp_reject        EXCEPTION;
--    resource_busy      EXCEPTION;
--    PRAGMA EXCEPTION_INIT (resource_busy, -30006);
--    PRAGMA AUTONOMOUS_TRANSACTION;
--    --En Added by Pankaj S. on 08_May_2013 for mantis ID-11048
--  BEGIN
--    L_ERRMSG := 'OK';
--    SELECT CPC_CTRL_NUMB, CPC_MAX_SERIAL_NO
--     INTO V_CTRLNUMB, V_MAX_SERIAL_NO
--     FROM CMS_PAN_CTRL
--    WHERE CPC_PAN_PREFIX = L_TMP_PAN AND CPC_INST_CODE = L_INSTCODE
--    FOR UPDATE WAIT 1; --Added by Pankaj S. on 08_May_2013 for mantis ID-11048
--
--    IF V_CTRLNUMB > V_MAX_SERIAL_NO THEN
--     L_ERRMSG := 'Maximum serial number reached';
--      RAISE excp_reject; --RETURN; --Modified by Pankaj S. on 08_May_2013 for mantis ID-11048
--    END IF;
--
--    L_SRNO := V_CTRLNUMB;
--
--    --Sn Modified by Pankaj S. on 08_May_2013 for mantis ID-11048
--     BEGIN
--       UPDATE cms_pan_ctrl
--          SET cpc_ctrl_numb = v_ctrlnumb + 1
--        WHERE cpc_pan_prefix = l_tmp_pan AND cpc_inst_code = l_instcode;
--
--       IF SQL%ROWCOUNT = 0
--       THEN
--          l_errmsg := 'Error while updating serial no';
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
--          l_errmsg := 'Error While Updating Serial Number ' || SQLERRM;
--          RAISE excp_reject;
--    END;
--    --En Modified by Pankaj S. on 08_May_2013 for mantis ID-11048
--
--  EXCEPTION
--    --Sn Added by Pankaj S. on 08_May_2013 for mantis ID-11048
--    WHEN resource_busy THEN
--      l_errmsg := 'PLEASE TRY AFTER SOME TIME';
--      ROLLBACK;
--    WHEN excp_reject THEN
--      ROLLBACK;
--    --En Added by Pankaj S. on 08_May_2013 for mantis ID-11048
--    WHEN NO_DATA_FOUND THEN
--     INSERT INTO CMS_PAN_CTRL
--       (CPC_INST_CODE, CPC_PAN_PREFIX, CPC_CTRL_NUMB, CPC_MAX_SERIAL_NO)
--     VALUES
--       (L_INSTCODE, L_TMP_PAN, 2, LPAD('9', L_MAX_LENGTH, 9));
--     V_CTRLNUMB := 1;
--     L_SRNO     := V_CTRLNUMB;
--     COMMIT; --Added by Pankaj S. on 08_May_2013 for mantis ID-11048
--    WHEN OTHERS THEN
--     L_ERRMSG := 'Excp1 LP2 -- ' || SQLERRM;
--  END;
--  -----------------------------------EN   LOCAL PROCEDURES  ----------------------------------
  ---------------------------------SN   LOCAL PROCEDURES  ----------------------------------
  PROCEDURE LP_PAN_CHKDIG( --l_prfx IN NUMBER,
                     -- l_prod_prefix IN VARCHAR2,
                     -- l_srno IN VARCHAR2,
                     L_TMPPAN   IN VARCHAR2,
                     L_CHECKDIG OUT NUMBER) IS
    CEILABLE_SUM NUMBER := 0;
    CEILED_SUM   NUMBER;
    TEMP_PAN     NUMBER;
    LEN_PAN      NUMBER(3);
    RES          NUMBER(3);
    MULT_IND     NUMBER(1);
    DIG_SUM      NUMBER(2);
    DIG_LEN      NUMBER(1);
  BEGIN
    -- DBMS_OUTPUT.put_line ('In check digit gen logic');
    --temp_pan  := l_prfx||l_prod_prefix||l_srno ;
    --len_pan      := LENGTH(temp_pan);
    TEMP_PAN := L_TMPPAN;
    LEN_PAN  := LENGTH(TEMP_PAN);
    MULT_IND := 2;
    FOR I IN REVERSE 1 .. LEN_PAN LOOP
     RES     := SUBSTR(TEMP_PAN, I, 1) * MULT_IND;
     DIG_LEN := LENGTH(RES);
     IF DIG_LEN = 2 THEN
       DIG_SUM := SUBSTR(RES, 1, 1) + SUBSTR(RES, 2, 1);
     ELSE
       DIG_SUM := RES;
     END IF;
     CEILABLE_SUM := CEILABLE_SUM + DIG_SUM;
     IF MULT_IND = 2 THEN
       --IF 2
       MULT_IND := 1;
     ELSE
       --Else of If 2
       MULT_IND := 2;
     END IF; --End of IF 2
    END LOOP;
    CEILED_SUM := CEILABLE_SUM;
    IF MOD(CEILABLE_SUM, 10) != 0 THEN
     LOOP
       CEILED_SUM := CEILED_SUM + 1;
       EXIT WHEN MOD(CEILED_SUM, 10) = 0;
     END LOOP;
    END IF;
    L_CHECKDIG := CEILED_SUM - CEILABLE_SUM;
    --dbms_output.put_line('FROM LOCAL CHK GEN---->'||l_checkdig);
  END;
--
--PROCEDURE lp_shuffle_srno (
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
--      --v_serial_no        cms_shfl_serl.css_serl_numb%type;
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
--                AND csc_prod_code = p_prod_code
--                AND csc_card_type = p_card_type
--         FOR UPDATE WAIT 1;
--
--
--         BEGIN
--
--            SELECT css_serl_numb -- Added on 25-Mar-2013
--              INTO v_serial_no
--              FROM cms_shfl_serl
--             WHERE css_inst_code = p_instcode
--               AND css_prod_code = p_prod_code
--               AND css_prod_catg = p_card_type
--               AND css_shfl_cntrl = v_csc_shfl_cntrl
--               AND css_serl_flag = 0;
--
--
--         EXCEPTION
--            WHEN NO_DATA_FOUND
--            THEN
--               p_errmsg :=
--                  'Shuffle Serial Number Not Found For Product And Product Catagory ';
--
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
--               AND csc_prod_code = p_prod_code
--               AND csc_card_type = p_card_type;
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
--                   AND css_prod_code = p_prod_code
--                   AND css_prod_catg = p_card_type
--                   AND css_shfl_cntrl = v_csc_shfl_cntrl
--                   AND css_serl_flag = 0;
--
--
--            EXCEPTION
--                WHEN NO_DATA_FOUND
--                THEN
--                   p_errmsg :=
--                      'Shuffle Serial Number Not Found For Product And Product Catagory ';
--
--
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
--
--    INSERT INTO cms_serl_error
--                 (cse_inst_code, cse_prod_code,
--                  cse_prod_catg, cse_ordr_rfrno,
--                  cse_err_mseg
--                 )
--          VALUES (Prm_INSTCODE, p_PROD_CODE,
--                  p_CARD_TYPE, V_APPL_CODE,
--                  p_errmsg
--                 );
--
--      WHEN OTHERS
--      THEN
--         p_errmsg := 'Main Exception From LP_SHUFFLE_SRNO ' || SQLERRM;
--         ROLLBACK;
--
--    INSERT INTO cms_serl_error
--                 (cse_inst_code, cse_prod_code,
--                  cse_prod_catg, cse_ordr_rfrno,
--                  cse_err_mseg
--                 )
--          VALUES (Prm_INSTCODE, p_PROD_CODE,
--                  p_CARD_TYPE, V_APPL_CODE,
--                  p_errmsg
--                 );
--
--   END lp_shuffle_srno;
--  -------------------------------------EN   LOCAL PROCEDURES ----------------------------------
  /*================================================================================================================*/
BEGIN
  --<< MAIN BEGIN >>
  -- prm_applprocess_msg := 'OK';
  PRM_ERRMSG  := 'OK';
  V_ISSUEFLAG := 'Y';

  --SN CREATE HASH PAN
  BEGIN
    V_HASH_PAN := GETHASH(PRM_PANCODE);
  EXCEPTION
    WHEN OTHERS THEN
     V_ERRMSG := 'Error while converting pan ' || SUBSTR(SQLERRM, 1, 200);
     RAISE EXP_REJECT_RECORD;
  END;
  --EN CREATE HASH PAN

  ---------------------------------------Sn generate savepoint number-------------------------------------
  --    BEGIN                                                             --    B1
  --       SELECT seq_pangen_savepoint.NEXTVAL
  --         INTO v_savepoint
  --         FROM DUAL;
  --    EXCEPTION
  --       WHEN OTHERS
  --       THEN
  --          v_errmsg :=
  --                     'Error from sequence pangen ' || SUBSTR (SQLERRM, 1, 200);
  --          RAISE exp_reject_record;
  --    END;                                                                --   B1
  ---------------------------------------En generate savepoint number-------------------------------------
  --  SAVEPOINT v_savepoint;
  ---------------------------------------Sn find hsm mode-------------------------------------
  BEGIN
    --   B2
    SELECT CIP_PARAM_VALUE
     INTO V_HSM_MODE
     FROM CMS_INST_PARAM
    WHERE CIP_PARAM_KEY = 'HSM_MODE' AND CIP_INST_CODE = PRM_INSTCODE;
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
  END; --    B2
  ---------------------------------------En find hsm mode-------------------------------------
  ---------------------------------------Sn fetch all details from appl_mast-------------------------------------
  BEGIN
    --Begin 1 Block Starts Here       --    B3
    SELECT CAP_INST_CODE,
         CAP_ASSO_CODE,
         CAP_INST_TYPE,
         CAP_PROD_CODE,
         CAP_APPL_BRAN,
         CAP_CUST_CODE,
         CAP_CARD_TYPE,
         NVL(CAP_CUST_CATG,1),
         CAP_CARD_STAT,
         CAP_DISP_NAME,
         CAP_APPL_BRAN,
         CAP_ACTIVE_DATE,
         CAP_EXPRY_DATE,
         CAP_ADDON_STAT,
         CAP_TOT_ACCT,
         CAP_CHNL_CODE,
         CAP_LIMIT_AMT,
         CAP_USE_LIMIT,
         CAP_BILL_ADDR,
         CAP_NEXT_BILL_DATE,
         CAP_PBFGEN_FLAG,
         CAP_NEXT_MB_DATE,
         CAP_ATM_OFFLINE_LIMIT,
         CAP_ATM_ONLINE_LIMIT,
         CAP_POS_OFFLINE_LIMIT,
         CAP_POS_ONLINE_LIMIT,
         CAP_OFFLINE_AGGR_LIMIT,
         CAP_ONLINE_AGGR_LIMIT,
         'N',
         CAP_MBR_NUMB,
         TYPE_APPL_REC_ARRAY(CAP_PANMAST_PARAM1,
                         CAP_PANMAST_PARAM2,
                         CAP_PANMAST_PARAM3,
                         CAP_PANMAST_PARAM4,
                         CAP_PANMAST_PARAM5,
                         CAP_PANMAST_PARAM6,
                         CAP_PANMAST_PARAM7,
                         CAP_PANMAST_PARAM8,
                         CAP_PANMAST_PARAM9,
                         CAP_PANMAST_PARAM10),
         CAP_ACCT_NO,
         CAP_ACCT_ID,
         CAP_PROXY_NUMBER,
         CAP_APPL_CODE
     INTO V_INST_CODE,
         V_ASSO_CODE,
         V_INST_TYPE,
         V_PROD_CODE,
         V_APPL_BRAN,
         V_CUST_CODE,
         V_CARD_TYPE,
         V_CUST_CATG,
         V_CARD_STAT,
         V_DISP_NAME,
         V_APPL_BRAN,
         V_ACTIVE_DATE,
         V_EXPRY_DATE,
         V_ADDON_STAT,
         V_TOT_ACCT,
         V_CHNL_CODE,
         V_LIMIT_AMT,
         V_USE_LIMIT,
         V_BILL_ADDR,
         V_NEXT_BILL_DATE,
         V_PBFGEN_FLAG,
         V_NEXT_MB_DATE,
         V_OFFLINE_ATM_LIMIT,
         V_ONLINE_ATM_LIMIT,
         V_OFFLINE_POS_LIMIT,
         V_ONLINE_POS_LIMIT,
         V_OFFLINE_AGGR_LIMIT,
         V_ONLINE_AGGR_LIMIT,
         V_CAP_FIRSTTIME_TOPUP,
         V_MBRNUMB,
         V_APPL_DATA,
         V_ACCT_NUM,
         V_ACCT_ID,
         V_PROXY_NUMBER,
         V_APPL_CODE
     FROM CMS_APPL_PAN
    WHERE CAP_PAN_CODE = V_HASH_PAN -- prm_pancode
         AND CAP_INST_CODE = PRM_INSTCODE;
  EXCEPTION
    --Exception of Begin 1 Block
    WHEN NO_DATA_FOUND THEN
     V_ERRMSG := 'No row found for pan code' || fn_getmaskpan (PRM_PANCODE); -- Instead of clear pan mask pan will be retuned in error msg Sagar 14-Sep-2012
     RAISE EXP_REJECT_RECORD;
    WHEN OTHERS THEN
     V_ERRMSG := 'Error while selecting pan code from applpan' ||
               SUBSTR(SQLERRM, 1, 300);
     RAISE EXP_REJECT_RECORD;
  END; --    B3
  ---------------------------------------En fetch all details from  appl_mast-------------------------------------
  IF TRIM(PRM_NEW_PRODCODE) IS NOT NULL THEN
    V_PROD_CODE := TRIM(PRM_NEW_PRODCODE);
    V_CARD_TYPE := TRIM(PRM_NEW_CARDTYPE);
  END IF;

  IF TRIM(PRM_NEW_DISPNAME) IS NOT NULL THEN

    V_DISP_NAME := TRIM(PRM_NEW_DISPNAME);

  END IF;
  --Sn check product and cardtype relationship

  BEGIN
    SELECT 1
     INTO V_CHECK_CARDTYPE
     FROM CMS_PROD_CATTYPE
    WHERE CPC_PROD_CODE = V_PROD_CODE AND CPC_CARD_TYPE = V_CARD_TYPE AND
         CPC_INST_CODE = PRM_INSTCODE;
  EXCEPTION
    WHEN NO_DATA_FOUND THEN
     V_ERRMSG := 'Product is not related to cardtype';
     RAISE EXP_REJECT_RECORD;
    WHEN OTHERS THEN
     V_ERRMSG := 'Error while selecting product and cardtype relationship' ||
               SUBSTR(SQLERRM, 1, 200);
     RAISE EXP_REJECT_RECORD;

  END;

  --En check product and cardtype relationship
  --Sn check product and cardtype relationship and customer catg relationship
  BEGIN
    SELECT 1
     INTO V_CHECK_CUSTCARG
     FROM CMS_PROD_CCC
    WHERE CPC_PROD_CODE = V_PROD_CODE AND CPC_CARD_TYPE = V_CARD_TYPE AND
         CPC_CUST_CATG = V_CUST_CATG AND CPC_INST_CODE = PRM_INSTCODE;
  EXCEPTION
    WHEN NO_DATA_FOUND THEN
     BEGIN
       SP_ATTACH_CUSTCATG(PRM_INSTCODE,
                      V_CUST_CATG,
                      V_PROD_CODE,
                      V_CARD_TYPE,
                      PRM_LUPDUSER,
                      V_ERRMSG);
       IF V_ERRMSG <> 'OK' THEN
        RAISE EXP_REJECT_RECORD;
       END IF;

     EXCEPTION
	   WHEN EXP_REJECT_RECORD THEN
	   RAISE ;
       WHEN OTHERS THEN
        V_ERRMSG := 'Error while creating a product and customer category relation ' ||
                  SUBSTR(SQLERRM, 1, 150);
        RAISE EXP_REJECT_RECORD;
     END;

    --          v_errmsg :=
    --                'Product is not related to custcatg';
    --                 RAISE exp_reject_record;
    WHEN OTHERS THEN
     V_ERRMSG := 'Error while selecting product and custcatg relationship' ||
               SUBSTR(SQLERRM, 1, 200);
     RAISE EXP_REJECT_RECORD;
  END;

  --En check product and cardtype relationship and customer catg relationship
  ---------------------------------------Sn find the bin for the product code-------------------------------------
  BEGIN
    --    B4
    LP_PAN_BIN(V_INST_CODE, V_INST_TYPE, V_PROD_CODE, V_BIN, V_ERRMSG);
    -- dbms_output.put_line('test Main test for error v_bin---------- '||v_bin);
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
  END; --    B4
  ---------------------------------------En find the bin for the product code-------------------------------------
  ---------------------------------------Sn find profile code attached to cardtype-------------------------------------
  BEGIN
    --dbms_output.put_line('test Main test for error 123');                                                      --  B5
    SELECT CPM_PROFILE_CODE,
         CPM_CATG_CODE,
         CPC_PROD_PREFIX,
         CPC_PROFILE_CODE ,
            /* Start Serial No Chnges added by Dhiraj Gaikwad 20082012 */
          CPC_SERL_FLAG,
          /* End Serial No Chnges added by Dhiraj Gaikwad 20082012 */
          cpc_exp_date_exemption,
          nvl(cpc_sweep_flag,'N'),
          NVL(cpc_pan_inventory_flag, 'N'), --Added for 17.07 PAN Inventory Changes,
          cpc_user_identify_type,
          cpc_prod_suffix,
          cpc_start_card_no,
          cpc_end_card_no,
          cpc_starter_card
     INTO V_PROFILE_CODE,
         V_CPM_CATG_CODE,
         V_PROD_PREFIX,
         V_CARDTYPE_PROFILE_CODE ,
          /* Start Serial No Chnges added by Dhiraj Gaikwad 20082012 */
          V_CPC_SERL_FLAG,
          /* End Serial No Chnges added by Dhiraj Gaikwad 20082012 */
          v_exp_date_exemption,
          v_sweep_flag,
          v_pan_inventory_flag, --Added for 17.07 PAN Inventory Changes,
          v_user_identify_type,
          v_prod_suffix,
          v_card_start,
          v_card_end,
          v_starter_card
     FROM CMS_PROD_CATTYPE, CMS_PROD_MAST
    WHERE CPC_INST_CODE = PRM_INSTCODE AND CPC_PROD_CODE = V_PROD_CODE AND
         CPC_CARD_TYPE = V_CARD_TYPE AND CPM_PROD_CODE = CPC_PROD_CODE;

 --   IF V_PROFILE_CODE IS NULL THEN

 --    V_ERRMSG := 'Product profile is not attached to product';

 --    RAISE EXP_REJECT_RECORD;

 --   END IF;

    IF V_CARDTYPE_PROFILE_CODE IS NULL THEN

     V_ERRMSG := 'Profile is not attached to product cattype';

     RAISE EXP_REJECT_RECORD;

    END IF;
    --dbms_output.put_line('v_profile_code'||v_profile_code||'   v_cpm_catg_code'||v_cpm_catg_code|| '   v_prod_prefix'||v_prod_prefix);
  EXCEPTION
    WHEN NO_DATA_FOUND THEN
     V_ERRMSG := 'Profile code not defined for product code ' ||
               V_PROD_CODE || 'card type ' || V_CARD_TYPE;
     RAISE EXP_REJECT_RECORD;

    WHEN EXP_REJECT_RECORD THEN
     RAISE;

    WHEN OTHERS THEN
     V_ERRMSG := 'Error while selecting Profile code ' ||
               SUBSTR(SQLERRM, 1, 300);
     RAISE EXP_REJECT_RECORD;
  END; --  B5

  -- Added by Trivkram on 08 June 2012 , If not configure PAN Product Category Prefix with Product Category level it will take from Instistute level

             IF V_PROD_PREFIX IS NULL THEN
              BEGIN
                 SELECT CIP_PARAM_VALUE
                 INTO V_PROD_PREFIX
                 FROM CMS_INST_PARAM
                WHERE CIP_INST_CODE = PRM_INSTCODE AND
                     CIP_PARAM_KEY = 'PANPRODCATPREFIX';
                EXCEPTION
                WHEN OTHERS THEN
                V_ERRMSG  := 'Error while selecting PAN Product Category Prefix from CMS_INST_PARAM ' ||
                        SUBSTR(SQLERRM, 1, 300);
                RAISE EXP_REJECT_RECORD;
             END;
            END IF;

    if v_sweep_flag<>'Y' then


    BEGIN
            vmsfunutilities.get_expiry_date(PRM_INSTCODE,v_prod_code,
           v_card_type,V_CARDTYPE_PROFILE_CODE,v_expry_date,V_ERRMSG);
            if V_ERRMSG<>'OK' then
            raise EXP_REJECT_RECORD;
             END IF;

      EXCEPTION
            when EXP_REJECT_RECORD then
                raise;
                           
            WHEN OTHERS THEN
                V_ERRMSG:='Error while calling vmsfunutilities.get_expiry_date'||substr(sqlerrm,1,200);
                raise EXP_REJECT_RECORD;
     
      END;
    -- SN added for VMS-5349 By Bhavani 
      ELSE
        BEGIN
        SELECT CIP_PARAM_VALUE into v_param_val
          FROM VMSCMS.cms_inst_param 
         WHERE CIP_INST_CODE= PRM_INSTCODE
           AND CIP_PARAM_KEY='SWEEP_ELIGIBLE_RPLC_EXPIRY';
         
          IF v_expry_date <= (sysdate + to_number(v_param_val)) then
             V_ERRMSG:='Declining Sweep Card Replacement And Card Expire Date is '||v_expry_date;
             RAISE EXP_REJECT_RECORD;
          END IF;
        EXCEPTION
            WHEN EXP_REJECT_RECORD THEN
                RAISE;  
              WHEN OTHERS THEN
                V_ERRMSG:='Error while Sweep replacement Expiry Param'||substr(sqlerrm,1,200);
                raise EXP_REJECT_RECORD;
        END;                
    -- EN added for VMS-5349 By Bhavani    
    END IF;   
	--En added for card expiry date logic chages.
IF v_pan_inventory_flag='N' THEN    --Added for 17.07 PAN Inventory Changes

-- ---------------------------------------Sn find pan construct details based on profile code-------------------------------------
--  BEGIN
--    --  B6
--    V_LOOP_CNT := 0;
--    --dbms_output.put_line('test Main test for error 3450000');
--    FOR I IN C(v_cardtype_profile_code) LOOP
--     V_LOOP_CNT := V_LOOP_CNT + 1;
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
--     --dbms_output.put_line('i.cpc_profile_code'||i.cpc_profile_code);
--    END LOOP;
--    /* IF c%ROWCOUNT = 0 THEN
--    v_errmsg :=
--               'No data found for the profile code from profile mast '
--            || SUBSTR (SQLERRM, 1, 300);
--         RAISE exp_reject_record;
--    END IF;*/
--  EXCEPTION
--    WHEN OTHERS THEN
--     V_ERRMSG := 'Error while selecting profile detail from profile mast ' ||
--               SUBSTR(SQLERRM, 1, 300);
--     RAISE EXP_REJECT_RECORD;
--  END; --  B6
--  ---------------------------------------En find pan construct details based on profile code-------------------------------------
--  ---------------------------------------Sn built the pan gen logic based on the value (except serial no)-------------------------------------
--  BEGIN
--    --  B7
--    V_LOOP_MAX_CNT := V_TABLE_PAN_CONSTRUCT.COUNT;
--    V_TMP_PAN      := NULL;
--    FOR I IN 1 .. V_LOOP_MAX_CNT LOOP
--     /*DBMS_OUTPUT.put_line (   'IFIELD NAME '
--       || i
--       || v_table_pan_construct (i).cpc_field_name
--      );*/
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
--       -- DBMS_OUTPUT.put_line (' loop indicator ' || i);
--       V_TABLE_PAN_CONSTRUCT(I).CPC_FIELD_VALUE := LPAD(SUBSTR(TRIM(V_BIN),
--                                                    V_TABLE_PAN_CONSTRUCT(I)
--                                                    .CPC_START,
--                                                    V_TABLE_PAN_CONSTRUCT(I)
--                                                    .CPC_LENGTH),
--                                              V_TABLE_PAN_CONSTRUCT(I)
--                                              .CPC_LENGTH,
--                                              '0');
--     ELSIF V_TABLE_PAN_CONSTRUCT(I)
--     .CPC_FIELD_NAME = 'PAN Product Category Prefix' THEN -- Modified by Trivikram on 06 June 2012 to distinguish Product Category Prefix of Account and PAN
--       V_TABLE_PAN_CONSTRUCT(I).CPC_FIELD_VALUE := LPAD(SUBSTR(TRIM(V_PROD_PREFIX),
--                                                    V_TABLE_PAN_CONSTRUCT(I)
--                                                    .CPC_START,
--                                                    V_TABLE_PAN_CONSTRUCT(I)
--                                                    .CPC_LENGTH),
--                                              V_TABLE_PAN_CONSTRUCT(I)
--                                              .CPC_LENGTH,
--                                              '0');
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
--  END; --    B7
--  ---------------------------------------En built the pan gen logic based on the value-------------------------------------
--
--  FOR I IN 1 .. V_LOOP_MAX_CNT LOOP
--    --<< i loop >>
--    FOR J IN 1 .. V_LOOP_MAX_CNT LOOP
--     --<< j  loop >>
--     /* DBMS_OUTPUT.put_line (   ' j start from '
--       || v_table_pan_construct (j).cpc_start_from
--      );*/
--     IF V_TABLE_PAN_CONSTRUCT(J)
--     .CPC_START_FROM = I AND V_TABLE_PAN_CONSTRUCT(J)
--     .CPC_FIELD_NAME <> 'Serial Number' THEN
--       /* DBMS_OUTPUT.put_line (   'FIELD VALUE I '
--         || v_table_pan_construct (j).cpc_field_value
--        );*/
--       V_TMP_PAN := V_TMP_PAN || V_TABLE_PAN_CONSTRUCT(J).CPC_FIELD_VALUE;
--       ---  DBMS_OUTPUT.put_line (v_tmp_pan);
--       EXIT;
--     END IF;
--    END LOOP; --<< j  end loop >>
--  END LOOP; --<< i end loop >>
--  ---------------------------------------Sn get  index value of serial no from PL/SQL table-------------------------------------
--  FOR I IN 1 .. V_TABLE_PAN_CONSTRUCT.COUNT LOOP
--    IF V_TABLE_PAN_CONSTRUCT(I).CPC_FIELD_NAME = 'Serial Number' THEN
--     V_SERIAL_INDEX := I;
--    END IF;
--  END LOOP;
--  ---------------------------------------En get  index value of serial no from PL/SQL table-------------------------------------
--  IF V_SERIAL_INDEX IS NOT NULL THEN
--    V_SERIAL_MAXLENGTH := V_TABLE_PAN_CONSTRUCT(V_SERIAL_INDEX).CPC_LENGTH;
--    --DBMS_OUTPUT.put_line ('SERIAL MAX LENGTH ' || v_serial_maxlength);
--
--      IF V_CPC_SERL_FLAG =1 THEN
--
--
--         BEGIN                                    --Added on 25-Mar-2013 for control number addition
--                lp_shuffle_srno (Prm_instcode,
--                                 v_prod_code,
--                                 v_card_type,
--                                 Prm_lupduser,
--                                 p_shflcntrl_no,
--                                 v_serial_no,
--                                 v_errmsg
--                                );
--
--                IF v_errmsg <> 'OK'
--                THEN
--                   --v_donot_mark_error := 1;
--                   RAISE exp_reject_record;
--                END IF;
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
--        /*                   --Commented on 25-Mar-2013 for control number addition
--            BEGIN
--
--             -- SELECT CSS_SERL_NUMB into V_SERIAL_NO
--             --      FROM cms_shfl_serl
--             --     WHERE css_inst_code = PRM_INSTCODE
--             --       AND css_prod_code = V_PROD_CODE
--             --       AND css_prod_catg = V_CARD_TYPE
--             --       AND css_serl_flag = 0 and rownum<2 FOR UPDATE  ;
--
--             select css_serl_numb into V_SERIAL_NO
--             from  ( SELECT     css_serl_numb
--                     FROM cms_shfl_serl
--                     WHERE css_inst_code = PRM_INSTCODE
--                     AND css_prod_code = V_PROD_CODE
--                     AND css_prod_catg = V_CARD_TYPE
--                     AND css_serl_flag = 0
--                     ORDER BY DBMS_RANDOM.VALUE
--                   )
--              where rownum<2 ;
--
--
--            EXCEPTION WHEN NO_DATA_FOUND THEN
--             V_ERRMSG:= 'Shuffle Serial Number Not Found For Product And Product Catagory ' ;
--                            INSERT INTO cms_serl_error
--                                         (cse_inst_code, cse_prod_code,
--                                          cse_prod_catg, cse_ordr_rfrno,
--                                          cse_err_mseg
--                                         )
--                                  VALUES (Prm_INSTCODE, V_PROD_CODE,
--                                          V_CARD_TYPE, V_APPL_CODE,
--                                          V_ERRMSG
--                                         );
--             RAISE EXP_REJECT_RECORD;
--             WHEN OTHERS THEN
--             V_ERRMSG:= 'Error While Finding Shuffle Serial Number '||SQLERRM ;
--             RAISE EXP_REJECT_RECORD;
--
--            END;
--         */
--
--          BEGIN
--               UPDATE cms_shfl_serl
--               SET    css_serl_flag = 1
--               WHERE CSS_SERL_NUMB  = V_SERIAL_NO
--               AND  css_inst_code   = Prm_INSTCODE
--               AND css_prod_code    = V_PROD_CODE --Added on 27092012 Dhiraj Gaikwad
--               AND css_prod_catg    = V_CARD_TYPE --Added on 27092012 Dhiraj Gaikwad
--               AND css_shfl_cntrl = p_shflcntrl_no --Added on 25-Mar-2013
--               AND css_serl_flag    = 0 ;  --Added on 27092012 Dhiraj Gaikwad
--
--               IF SQL%ROWCOUNT = 0
--               THEN
--               V_ERRMSG := 'Error updating Serial  control data, record not updated successfully';
--                RAISE EXP_REJECT_RECORD;
--               END IF;
--
--          EXCEPTION
--               WHEN OTHERS THEN
--                  V_ERRMSG := 'Error updating control data ' || substr(sqlerrm,1,150);
--                RAISE EXP_REJECT_RECORD;
--          END;
--         /* End  Serial No Chnges added by Dhiraj Gaikwad 20082012 */
--      ELSE
--
--          BEGIN
--
--            LP_PAN_SRNO(PRM_INSTCODE,
--                     PRM_LUPDUSER,
--                     V_TMP_PAN,
--                     V_SERIAL_MAXLENGTH,
--                     V_SERIAL_NO,
--                     V_ERRMSG);
--            --DBMS_OUTPUT.put_line ('SERIAL No ' || v_serial_no);
--            IF V_ERRMSG <> 'OK' THEN
--             RAISE EXP_REJECT_RECORD;
--            END IF;
--             EXCEPTION
--          WHEN  EXP_REJECT_RECORD THEN
--             RAISE  ;
--          WHEN OTHERS THEN
--               V_ERRMSG := 'Error while calling LP_PAN_SRNO ' || SUBSTR(SQLERRM, 1, 300);
--             RAISE EXP_REJECT_RECORD;
--          END;
--
--      END IF ;
--
--
--    V_TABLE_PAN_CONSTRUCT(V_SERIAL_INDEX).CPC_FIELD_VALUE := LPAD(SUBSTR(TRIM(V_SERIAL_NO),
--                                                           V_TABLE_PAN_CONSTRUCT(V_SERIAL_INDEX)
--                                                           .CPC_START,
--                                                           V_TABLE_PAN_CONSTRUCT(V_SERIAL_INDEX)
--                                                           .CPC_LENGTH),
--                                                     V_TABLE_PAN_CONSTRUCT(V_SERIAL_INDEX)
--                                                     .CPC_LENGTH,
--                                                     '0');
--    /* DBMS_OUTPUT.put_line
--    (   'SERIAL NO '
--     || v_table_pan_construct (v_serial_index).cpc_field_value
--    );*/
--  END IF;
--
--  V_TMP_PAN := NULL;
--  FOR I IN 1 .. V_LOOP_MAX_CNT LOOP
--    FOR J IN 1 .. V_LOOP_MAX_CNT LOOP
--     IF V_TABLE_PAN_CONSTRUCT(J).CPC_START_FROM = I THEN
--       V_TMP_PAN := V_TMP_PAN || V_TABLE_PAN_CONSTRUCT(J).CPC_FIELD_VALUE;
--       ---   DBMS_OUTPUT.put_line ('Inside'||v_tmp_pan);
--       EXIT;
--     END IF;
--    END LOOP;
--  END LOOP;
--  ---------------------------------------En generate temp pan for check digit-------------------------------------
--  -- DBMS_OUTPUT.put_line ('v_pan test eng'||v_tmp_pan);
  ---------------------------------------Sn generate for check digit-------------------------------------
   --SN: Modified/Added for VMS-6656
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
    vmscard.get_pan_srno (prm_instcode,
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
    vmscard.get_pan_srno (prm_instcode,
                          v_prod_code,
                          v_card_type,
                          v_starter_card,
                          v_cpc_serl_flag,
                          v_bin,
                          v_prefix,
                          v_serial_no,
                          v_errmsg); 
    END IF;
    --EN: Modified/Added for VMS-6656

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
              WHERE cpc_profile_code = V_CARDTYPE_PROFILE_CODE
                    AND cpc_inst_code = PRM_INSTCODE
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
   
  
  IF V_TMP_PAN IS NOT NULL THEN
    LP_PAN_CHKDIG(V_TMP_PAN, V_CHECK_DIGIT);
    V_PAN := V_TMP_PAN || V_CHECK_DIGIT;
    --DBMS_OUTPUT.put_line ('Vtemp_pan'||v_pan);
   END IF;
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
     PRM_PAN := V_PAN;
 --EN:Added for 17.07 PAN Inventory Changes  
    --DBMS_OUTPUT.put_line (prm_pan);

    --SN CREATE HASH PAN
    BEGIN
     V_HASH_NEW_PAN := GETHASH(V_PAN);
    EXCEPTION
     WHEN OTHERS THEN
       V_ERRMSG := 'Error while converting pan ' ||
                SUBSTR(SQLERRM, 1, 200);
       RAISE EXP_REJECT_RECORD;
    END;
    --EN CREATE HASH PAN

    --SN create encr pan
    BEGIN
     V_ENCR_NEW_PAN := FN_EMAPS_MAIN(V_PAN);
    EXCEPTION
     WHEN OTHERS THEN
       V_ERRMSG := 'Error while converting pan ' ||
                SUBSTR(SQLERRM, 1, 200);
       RAISE EXP_REJECT_RECORD;
    END;
    --EN create encr pan

   --SN create Mask PAN  -- Added by sagar on 13Aug2012 for Pan masking changes
   BEGIN
      v_mask_pan := fn_getmaskpan (v_pan);
   EXCEPTION
      WHEN OTHERS
      THEN
         v_errmsg :=
                    'Error while converting into mask pan ' || SUBSTR (SQLERRM, 1, 200);
         RAISE exp_reject_record;
   END;

  ---------------------------------------En generate for check digit-------------------------------------

  ---------------------------------------Sn entry for addon stat-------------------------------------
  IF V_ADDON_STAT = 'A' THEN
    BEGIN
     --dbms_output.put_line('test Main test for error 345222');                                              ----   B10
     SELECT CAP_ADDON_LINK
       INTO V_CAP_ADDON_LINK
       FROM CMS_APPL_PAN
      WHERE CAP_APPL_CODE = V_HASH_PAN --prm_pancode
           AND CAP_INST_CODE = PRM_INSTCODE;
     SELECT CAP_PAN_CODE, CAP_MBR_NUMB
       INTO V_ADONLINK, V_MBRLINK
       FROM CMS_APPL_PAN
      WHERE CAP_PAN_CODE = V_CAP_ADDON_LINK AND
           CAP_INST_CODE = PRM_INSTCODE;
    EXCEPTION
     --excp 1.1
     WHEN NO_DATA_FOUND THEN
       V_ERRMSG := 'Parent PAN not generated for ' || fn_getmaskpan (PRM_PANCODE);  -- Instead of clear pan mask pan will be retuned in error msg Sagar 14-Sep-2012
       RAISE EXP_REJECT_RECORD;
     WHEN OTHERS THEN
       V_ERRMSG := 'Error while selecting addon detail ' ||
                SUBSTR(SQLERRM, 1, 150);
       RAISE EXP_REJECT_RECORD;
    END; --end of begin 1.1      --  B10
  ELSIF V_ADDON_STAT = 'P' THEN
    V_ADONLINK := V_HASH_NEW_PAN; --v_pan;
    V_MBRLINK  := V_MBRNUMB;
  END IF;
  ---------------------------------------En entry for addon stat-------------------------------------
  -----------------------------------------Sn find card status and limit parameter for the profile---------------------------------------
  --Sn find card status and limit parameter for the profile
  V_CARD_STAT := '0';  -- VMS-8219
--  BEGIN
--    SELECT CBP_PARAM_VALUE
--     INTO V_CARD_STAT
--     FROM CMS_BIN_PARAM
--    WHERE CBP_INST_CODE = PRM_INSTCODE AND
--         CBP_PROFILE_CODE = v_cardtype_profile_code AND CBP_PARAM_NAME = 'Status';
--  EXCEPTION
--    WHEN OTHERS THEN
--     V_ERRMSG := 'Error while selecting carad status data ' ||
--               SUBSTR(SQLERRM, 1, 200);
--     RAISE EXP_REJECT_RECORD;
--  END;

  BEGIN
    --dbms_output.put_line('test Main test for error 3458787');
    IF V_CPM_CATG_CODE = 'P' THEN
     --  B17
     INSERT INTO CMS_APPL_PAN
       (CAP_INST_CODE,
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
         -- CAP_ACTIVE_DATE,  Modified by Ramkumar.MK on 10 Aug 2012,
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
        CAP_INS_USER,
        CAP_LUPD_USER,
        CAP_PBFGEN_FLAG,
        CAP_NEXT_MB_DATE,
        CAP_ATM_OFFLINE_LIMIT,
        CAP_ATM_ONLINE_LIMIT,
        CAP_POS_OFFLINE_LIMIT,
        CAP_POS_ONLINE_LIMIT,
        CAP_OFFLINE_AGGR_LIMIT,
        CAP_ONLINE_AGGR_LIMIT,
        CAP_FIRSTTIME_TOPUP,
        CAP_ISSUE_FLAG,
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
        CAP_PROXY_NUMBER,
        CAP_APPL_CODE,
        CAP_MASK_PAN, -- Added by sagar on 13Aug2012 for Pan masking changes
        CAP_PROXY_MSG,  --Added by Pankaj S. on 27_Feb_2013 for DFCHOST-249
        cap_user_identify_type
        )
     VALUES
       (PRM_INSTCODE,
        V_ASSO_CODE,
        V_INST_TYPE,
        V_PROD_CODE,
        V_CPM_CATG_CODE,
        V_CARD_TYPE,
        V_CUST_CATG,
        V_HASH_NEW_PAN, --v_pan
        V_MBRNUMB,
        V_CARD_STAT,
        V_CUST_CODE,
        V_DISP_NAME,
        V_LIMIT_AMT,
        V_USE_LIMIT,
        V_APPL_BRAN,
        --SYSDATE,  Modiifed by Ramkumar.MK on 10 Aug 2012
        --v_active_date,  Commented as Active Date for New should go as Sysdate
        V_EXPRY_DATE,
        V_ADDON_STAT,
        V_ADONLINK,
        V_MBRLINK,
        V_ACCT_ID,
        V_ACCT_NUM,
        V_TOT_ACCT,
        V_BILL_ADDR,
        V_CHNL_CODE,
        SYSDATE,
        PRM_LUPDUSER,
        'Y',
        V_PINGEN_FLAG,
        V_EMBOSS_FLAG,
        'N',
        'N',
        V_NEXT_BILL_DATE,
        PRM_LUPDUSER,
        PRM_LUPDUSER,
        'R',
        V_NEXT_MB_DATE,
        V_OFFLINE_ATM_LIMIT,
        V_ONLINE_ATM_LIMIT,
        V_OFFLINE_POS_LIMIT,
        V_ONLINE_POS_LIMIT,
        V_OFFLINE_AGGR_LIMIT,
        V_ONLINE_AGGR_LIMIT,
        'N',
        V_ISSUEFLAG,
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
        V_ENCR_NEW_PAN,
        V_PROXY_NUMBER,
        V_APPL_CODE,
        --'N' Commented as FirstTime Topup Not Needed For New Card in Reissue
        v_mask_pan, -- Added by sagar on 13Aug2012 for Pan masking changes
        'Success',--Added by Pankaj S. on 27_Feb_2013 for DFCHOST-249
        v_user_identify_type
        );
    END IF;
    IF V_CPM_CATG_CODE IN ('D', 'A') THEN
     --  B17
     INSERT INTO CMS_APPL_PAN
       (CAP_INST_CODE,
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
        -- CAP_ACTIVE_DATE,  Modified by Ramkumar.MK on 10 Aug 2012
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
        CAP_INS_USER,
        CAP_LUPD_USER,
        CAP_PBFGEN_FLAG,
        CAP_NEXT_MB_DATE,
        CAP_ATM_OFFLINE_LIMIT,
        CAP_ATM_ONLINE_LIMIT,
        CAP_POS_OFFLINE_LIMIT,
        CAP_POS_ONLINE_LIMIT,
        CAP_OFFLINE_AGGR_LIMIT,
        CAP_ONLINE_AGGR_LIMIT,
        CAP_FIRSTTIME_TOPUP,
        CAP_ISSUE_FLAG,
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
        CAP_PROXY_NUMBER,
        CAP_APPL_CODE,
        CAP_MASK_PAN, -- Added by sagar on 13Aug2012 for Pan masking changes
        CAP_PROXY_MSG  --Added by Pankaj S. on 27_Feb_2013 for DFCHOST-249
        )
     VALUES
       (PRM_INSTCODE,
        V_ASSO_CODE,
        V_INST_TYPE,
        V_PROD_CODE,
        V_CPM_CATG_CODE,
        V_CARD_TYPE,
        V_CUST_CATG,
        V_HASH_NEW_PAN, --v_pan
        V_MBRNUMB,
        V_CARD_STAT,
        V_CUST_CODE,
        V_DISP_NAME,
        V_LIMIT_AMT,
        V_USE_LIMIT,
        V_APPL_BRAN,
        --  SYSDATE, Modified by Ramkumar.Mk on 10 Aug 2012
        --v_active_date,--Commented as Active Date for New should go as Sysdate Not in case of debit card
        V_EXPRY_DATE,
        V_ADDON_STAT,
        V_ADONLINK,
        V_MBRLINK,
        V_ACCT_ID,
        V_ACCT_NUM,
        V_TOT_ACCT,
        V_BILL_ADDR,
        V_CHNL_CODE,
        SYSDATE,
        PRM_LUPDUSER,
        'Y',
        V_PINGEN_FLAG,
        V_EMBOSS_FLAG,
        'N',
        'N',
        V_NEXT_BILL_DATE,
        PRM_LUPDUSER,
        PRM_LUPDUSER,
        'R',
        V_NEXT_MB_DATE,
        V_OFFLINE_ATM_LIMIT,
        V_ONLINE_ATM_LIMIT,
        V_OFFLINE_POS_LIMIT,
        V_ONLINE_POS_LIMIT,
        V_OFFLINE_AGGR_LIMIT,
        V_ONLINE_AGGR_LIMIT,
        'Y',
        V_ISSUEFLAG,
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
        V_ENCR_NEW_PAN,
        V_PROXY_NUMBER,
        V_APPL_CODE,
        --'N' Commented as FirstTime Topup Not Needed For New Card in Reissue
        v_mask_pan, -- Added by sagar on 13Aug2012 for Pan masking changes
        'Success'--Added by Pankaj S. on 27_Feb_2013 for DFCHOST-249
        );
    END IF;
  EXCEPTION
    WHEN VALUE_ERROR THEN
     V_ERRMSG := 'Pan ' || fn_getmaskpan (V_PAN) || -- mask pan will be returned in error msg sagar 14-Sep-2012
               ' Error while inserting records into pan master  VALUE_ERROR';
     RAISE EXP_REJECT_RECORD;
    WHEN DUP_VAL_ON_INDEX THEN
     V_ERRMSG := 'Pan ' || fn_getmaskpan (V_PAN) || -- mask pan will be returned in error msg sagar 14-Sep-2012
               ' is already present in the Pan_master';
     RAISE EXP_REJECT_RECORD;
    WHEN OTHERS THEN
     V_ERRMSG := 'Error while inserting records into pan master ' ||
               SUBSTR(SQLERRM, 1, 200);
     RAISE EXP_REJECT_RECORD;
  END; --  B17
  -----------------------------------------En create a record in appl_pan---------------------------------------
  -----------------------------------------Sn create record in pan_acct---------------------------------------
  IF V_CPM_CATG_CODE IN ('D', 'A') THEN
    --FOR X IN C1(PRM_PANCODE) LOOP  -- Commented by sagar as PAN_CODE is not used in cursor query
    FOR X IN C1 LOOP                 -- Added by sagar as PAN_CODE is not used in cursor query
     BEGIN
       -- dbms_output.put_line('test Main test for error 3488885');                                                    --  B18
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
        (PRM_INSTCODE,
         V_CUST_CODE,
         V_ACCT_ID,
         X.CPA_ACCT_POSN, --v_pan
         V_HASH_NEW_PAN,
         V_MBRNUMB,
         PRM_LUPDUSER,
         PRM_LUPDUSER,
         V_ENCR_NEW_PAN);
       EXIT WHEN C1%NOTFOUND;
     EXCEPTION
       WHEN VALUE_ERROR THEN
        V_ERRMSG := 'Duplicate record exist  in pan acct master for pan  VALUE_ERROR' ||
                  fn_getmaskpan (V_PAN) || 'acct id ' || X.CPA_ACCT_ID; -- mask pan will be returned in error msg sagar 14-Sep-2012
        RAISE EXP_REJECT_RECORD;
       WHEN DUP_VAL_ON_INDEX THEN
        V_ERRMSG := 'Duplicate record exist  in pan acct master for pan  ' ||
                  fn_getmaskpan (V_PAN) || 'acct id ' || X.CPA_ACCT_ID; -- mask pan will be returned in error msg sagar 14-Sep-2012
        RAISE EXP_REJECT_RECORD;
       WHEN OTHERS THEN
        V_ERRMSG := 'Error while inserting records into pan acct  master ' ||
                  SUBSTR(SQLERRM, 1, 200);
        RAISE EXP_REJECT_RECORD;
     END; --  B18
    END LOOP;
  ELSIF V_CPM_CATG_CODE = 'P' THEN
    -- v_acctid_new:=v_acctid_new;
    BEGIN
     -- dbms_output.put_line('test Main test for error 3488885');                                                    --  B18
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
       (PRM_INSTCODE,
        V_CUST_CODE,
        V_ACCT_ID,
        1, --v_pan
        V_HASH_NEW_PAN,
        V_MBRNUMB,
        PRM_LUPDUSER,
        PRM_LUPDUSER,
        V_ENCR_NEW_PAN);

    EXCEPTION
     WHEN VALUE_ERROR THEN
       V_ERRMSG := 'Duplicate record exist  in pan acct master for pan  VALUE_ERROR' ||
                fn_getmaskpan (V_PAN) || 'acct id ' || V_ACCT_ID; -- mask pan will be returned in error msg sagar 14-Sep-2012
       RAISE EXP_REJECT_RECORD;
     WHEN DUP_VAL_ON_INDEX THEN
       V_ERRMSG := 'Duplicate record exist  in pan acct master for pan  ' ||
                fn_getmaskpan (V_PAN) || 'acct id ' || V_ACCT_ID; -- mask pan will be returned in error msg sagar 14-Sep-2012
       RAISE EXP_REJECT_RECORD;
     WHEN OTHERS THEN
       V_ERRMSG := 'Error while inserting records into pan acct  master ' ||
                SUBSTR(SQLERRM, 1, 200);
       RAISE EXP_REJECT_RECORD;
    END;

  END IF;

  -----------------------------------------En create record in pan_acct---------------------------------------
  -----------------------------------------Sn update acct_mast for  pan---------------------------------------

  -----------------------------------------En update acct_mast for pan---------------------------------------
  --Sn create a entry in gl acct mast
  --Sn find the old gl entries of old card -------------

  --Sn Check Condition For Debit or prepaid.--------------------


  --IF V_CPM_CATG_CODE = 'P' THEN -- IF condtion Commented by sagar on 14-Sep-2012

      /*       -- Commented by sagar on 14-Sep-2012
        BEGIN
         SELECT CGA_GLCATG_CODE, CGA_GL_CODE, CGA_SUBGL_CODE, CGA_ACCT_DESC
           INTO V_OLD_GL_CATG,
               V_OLD_GL_CODE,
               V_OLD_SUB_GL_CODE,
               V_OLD_ACCT_DESC
           FROM CMS_GL_ACCT_MAST
         WHERE CGA_ACCT_CODE = V_ACCT_NUM --PRM_PANCODE  Chanegs done by sagar as discussed with saravana to compare Account number instead of Pan code on 22-Aug-2012
         AND CGA_INST_CODE = PRM_INSTCODE;
        EXCEPTION
         WHEN NO_DATA_FOUND THEN
           V_ERRMSG := 'Error while selecting old card GL detail ' ||
                    ' Account not found';
           RAISE EXP_REJECT_RECORD;
         WHEN OTHERS THEN
           V_ERRMSG := 'Error while selecting old card GL detail ' ||
                    SUBSTR(SQLERRM, 1, 200);
           RAISE EXP_REJECT_RECORD;
        END;
        --En find the old gl entries of old card -------------
       */     -- Commented by sagar on 14-Sep-2012


    --Sn create a entry in gl_acct_mast ------------------
    --Ramkumar.MK on 30 Aug 2012, No need to insert the cms_gl_acct_mast when we reissue the card
    /*BEGIN
     INSERT INTO CMS_GL_ACCT_MAST
       (CGA_INST_CODE,
        CGA_GLCATG_CODE,
        CGA_GL_CODE,
        CGA_SUBGL_CODE,
        CGA_ACCT_CODE,
        CGA_ACCT_DESC,
        CGA_TRAN_AMT,
        CGA_INS_DATE,
        CGA_LUPD_USER,
        CGA_LUPD_DATE)
     VALUES
       (PRM_INSTCODE,
        V_OLD_GL_CATG,
        V_OLD_GL_CODE,
        V_OLD_SUB_GL_CODE,
        V_ACCT_NUM,--V_PAN, Chanegs done by sagar as discussed with saravana to insert Account number instead of Pan code on 22-Aug-2012
        V_OLD_ACCT_DESC,
        0,
        SYSDATE,
        PRM_LUPDUSER,
        SYSDATE);
    EXCEPTION
     WHEN DUP_VAL_ON_INDEX THEN
       V_ERRMSG := 'Error while inserting record in gl_acct_mast ' ||
                ' Duplicate record found';
       RAISE EXP_REJECT_RECORD;
     WHEN OTHERS THEN
       V_ERRMSG := 'Error while inserting record in gl_acct_mast ' ||
                SUBSTR(SQLERRM, 1, 200);
       RAISE EXP_REJECT_RECORD;
    END;*/
 -- END IF; -- IF condtion Commented by sagar on 14-Sep-2012
  --En create a entry in gl_acct_mast ------------------


  --En create a entry in gl acct mast
  PRM_ERRMSG := 'OK';
  -- prm_applprocess_msg := 'OK';
EXCEPTION
  --<< MAIN EXCEPTION >>
  WHEN EXP_REJECT_RECORD THEN
    PRM_ERRMSG := V_ERRMSG;
    -- ROLLBACK TO v_savepoint;
  -- prm_applprocess_msg := v_errmsg;
  --       --dbms_output.put_line('test Main test for error 345222222222');
  --       UPDATE cms_appl_mast
  --          SET cam_appl_stat = 'E',
  --              cam_process_msg = v_errmsg,
  --              cam_lupd_user = prm_lupduser
  --        WHERE cam_appl_code = prm_pancode
  --        AND   cam_inst_code = prm_instcode;
  --       prm_applprocess_msg := v_errmsg;
  --       prm_errmsg := 'OK';
  WHEN OTHERS THEN
    --  ROLLBACK TO v_savepoint;
    --dbms_output.put_line('test Main test for error 345000000');
    PRM_ERRMSG := 'Error while processing application for pan gen ' ||
               SUBSTR(SQLERRM, 1, 200);
    --       prm_applprocess_msg :=
  --             'Error while processing application for pan gen '
  --          || SUBSTR (SQLERRM, 1, 200);
END; --<< MAIN BEGIN >>
/
show error