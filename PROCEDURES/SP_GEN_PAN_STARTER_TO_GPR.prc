create or replace PROCEDURE                                                        VMSCMS.SP_GEN_PAN_STARTER_TO_GPR(P_INSTCODE IN NUMBER,
                                         P_APPLCODE IN NUMBER,
                                         P_LUPDUSER IN NUMBER,
                                         P_PAN             OUT VARCHAR2,
                                         P_APPLPROCESS_MSG OUT VARCHAR2,
                                         P_ERRMSG          OUT VARCHAR2) AS


/*********************************************************************************
     * Created By        :  NA
     * Created Date      :  NA
     * Modified By       : Saravanakumar
     * Modified Date     : 28-Dec-2012
     * Modified Reason   :  For CR-38 DFC- CCF Changes
     * Reviewer          :
     * Reviewed Date     :
     * Release Number    :

     * Modified By       : Sagar
     * Modified Date     : 26-Feb-2013
     * Modified For      : FSS-756
     * Modified Reason   : To Set alerts of starter card to GPR card
     * Reviewer          : Dhiraj
     * Reviewed Date     : 26-Feb-2013
     * Release Number    : RI0023.2_B0008

     * Modified By      : Pankaj S.
     * Modified Date     : 27-Feb-2013
     * Modified For      : DFCHOST-249
     * Modified Reason   : To update the proxy number of starter card for GPR card record in cms_appl_pan table.
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
     * Modified reason  : Performance Issue (Mantis ID-11048)
     * Modified On      : 08-May-2013
     * Reviewer         : Dhiraj
     * Reviewed Date    :
     * Build Number     : CMS3.5.1_RI0024.1_B0017

     * Modified By      : Siva Arcot
     * Modified reason  : MVHOST-552
     * Modified On      : 03/09/2013
     * Modified For     :
     * Reviewer         : Dhiraj
     * Reviewed Date    : 03/09/2013
     * Build Number     : RI0024.3.6_B0002

     * Modified by      : MageshKumar.S
     * Modified Reason  : JH-6(Fast50 -Fedral And State Tax Refund Alerts)
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

     * Modified By      : Saravanakumar
     * Modified Date    : 322-oct-2015
     * Modified Reason  : expiry date changes
     * Reviewer         : Spankaj
     * Build Number     : VMSGPRHOST3.2_B0007
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

     * Modified By      : Pankaj S.
     * Modified Date    : 15-Feb-2023
     * Purpose          : VMS-6655,6843
     * Reviewer         : Venkat S.
     * Release Number   : R78

	 * Modified By      : BHavani E
     * Modified Date    : 14-Aug-2023
     * Purpose          : VMS-7341
     * Reviewer         : Pankaj S.
     * Release Number   : R84
     
     * Modified By      : Shanmugavel
     * Modified Date    : 23/01/2024
     * Purpose          : VMS-8219-Remove the Default Status in the Product Category Profile Screen on the Host UI
     * Reviewer         : Venkat/John/Pankaj
     * Release Number   : VMSGPRHOSTR92
************************************************************************************/

  V_INST_CODE            CMS_APPL_MAST.CAM_INST_CODE%TYPE;
  V_ASSO_CODE            CMS_APPL_MAST.CAM_ASSO_CODE%TYPE;
  V_INST_TYPE            CMS_APPL_MAST.CAM_INST_TYPE%TYPE;
  V_PROD_CODE            CMS_APPL_MAST.CAM_PROD_CODE%TYPE;
  V_APPL_BRAN            CMS_APPL_MAST.CAM_APPL_BRAN%TYPE;
  V_CUST_CODE            CMS_APPL_MAST.CAM_CUST_CODE%TYPE;
  V_CARD_TYPE            CMS_APPL_MAST.CAM_CARD_TYPE%TYPE;
  V_GPR_CARD_TYPE        CMS_PROD_CATTYPE.CPC_STARTERGPR_CRDTYPE%TYPE;
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
  V_EXPRYPARAM           CMS_BIN_PARAM.CBP_PARAM_VALUE%TYPE;
  V_VALIDITY_PERIOD      CMS_BIN_PARAM.CBP_PARAM_VALUE%TYPE;
  V_SAVEPOINT            NUMBER DEFAULT 1;
  V_EMP_ID               CMS_CUST_MAST.CCM_EMP_ID%TYPE;
  V_CORP_CODE            CMS_CUST_MAST.CCM_CORP_CODE%TYPE;
  V_APPL_DATA            TYPE_APPL_REC_ARRAY;
  V_MBRNUMB              CMS_APPL_PAN.CAP_MBR_NUMB%TYPE;
 -- V_PROXY_NUMBER         CMS_APPL_PAN.CAP_PROXY_NUMBER%TYPE;--Commented for CR-38 DFC- CCF Changes
  --ADded For MMPOS limits
  V_ONLINE_MMPOS_LIMIT  CMS_APPL_PAN.CAP_MMPOS_ONLINE_LIMIT%TYPE;
  V_OFFLINE_MMPOS_LIMIT CMS_APPL_PAN.CAP_MMPOS_OFFLINE_LIMIT%TYPE;
  V_HASH_PAN CMS_APPL_PAN.CAP_PAN_CODE%TYPE;
  V_ENCR_PAN CMS_APPL_PAN.CAP_PAN_CODE_ENCR%TYPE;
  V_GETSEQNO VARCHAR2(200);
  V_PROGRAMID  VARCHAR2(4);
  V_SEQNO      CMS_PROGRAM_ID_CNT.CPI_SEQUENCE_NO%TYPE;
  --V_PROXYLENGTH    cms_prod_mast.cpm_proxy_length%type;--Commented for CR-38 DFC- CCF Changes
     v_mask_pan                cms_appl_pan.cap_mask_pan%TYPE; -- Added by sagar on 13Aug2012 for Pan masking changes
     V_CPC_SERL_FLAG CMS_PROD_CATTYPE.CPC_SERL_FLAG%type; -- Added by Dhiraj Gaikwad  for Serial Number CR  20022012
     V_CAM_FILE_NAME  CMS_APPL_MAST.CAM_FILE_NAME%TYPE ;
     V_DONOT_MARK_ERROR NUMBER(10) DEFAULT 0 ;
     v_cap_starter_card      CMS_APPL_PAN.CAP_PAN_CODE%TYPE; -- Added for FSS-756
     V_PROXY_NUMBER         CMS_APPL_PAN.CAP_PROXY_NUMBER%TYPE; --added by Pankaj S; on 27_Feb_2013 for DFCHOST-249
     p_shflcntrl_no           NUMBER (9);

     V_TRAN_CODE            VARCHAR2(2) DEFAULT 'IL' ; -- Added for fwr - 48
     V_TRAN_MODE            VARCHAR2(1) DEFAULT '0' ; -- Added for fwr - 48
     V_DELV_CHNL            VARCHAR2(2) DEFAULT '05' ; -- Added for fwr - 48
     V_TRAN_TYPE            VARCHAR2(1) DEFAULT '1' ; -- Added for fwr - 48
     v_exp_date_exemption     cms_prod_cattype.cpc_exp_date_exemption%TYPE;
     v_sweep_flag              cms_prod_cattype.cpc_sweep_flag%type;
     v_expry_arry EXPRY_ARRAY_TYP := EXPRY_ARRAY_TYP (); -- Added for VMS-7341
     v_isexpry_randm          cms_prod_cattype.cpc_expdate_randomization%type; -- Added for VMS-7341
     v_catg_profile_code       cms_prod_cattype.cpc_profile_code%type;
     v_pan_inventory_flag    cms_prod_cattype.cpc_pan_inventory_flag%TYPE;  --Added for 17.07 PAN Inventory Changes
     v_user_identify_type cms_prod_cattype.cpc_user_identify_type%type;
     v_prod_suffix             cms_prod_cattype.cpc_prod_suffix%TYPE;
     v_card_start              cms_prod_cattype.cpc_start_card_no%TYPE;
     v_card_end                cms_prod_cattype.cpc_end_card_no%TYPE;
     v_prodprefx_index         NUMBER;
     v_prefix                  VARCHAR2(10);
     v_toggle_value           cms_inst_param.cip_param_value%TYPE;  --Added for VMS-6655,6843
--  TYPE REC_PAN_CONSTRUCT IS RECORD(
--    CPC_PROFILE_CODE CMS_PAN_CONSTRUCT.CPC_PROFILE_CODE%TYPE,
--    CPC_FIELD_NAME   CMS_PAN_CONSTRUCT.CPC_FIELD_NAME%TYPE,
--    CPC_START_FROM   CMS_PAN_CONSTRUCT.CPC_START_FROM%TYPE,
--    CPC_START        CMS_PAN_CONSTRUCT.CPC_START%TYPE,
--    CPC_LENGTH       CMS_PAN_CONSTRUCT.CPC_LENGTH%TYPE,
--    CPC_FIELD_VALUE  VARCHAR2(30));
--
--  TYPE TABLE_PAN_CONSTRUCT IS TABLE OF REC_PAN_CONSTRUCT INDEX BY BINARY_INTEGER;
--
--  V_TABLE_PAN_CONSTRUCT TABLE_PAN_CONSTRUCT;
  EXP_REJECT_RECORD EXCEPTION;

  CURSOR C(P_PROFILE_CODE IN VARCHAR2) IS
    SELECT CPC_PROFILE_CODE,
         CPC_FIELD_NAME,
         CPC_START_FROM,
         CPC_LENGTH,
         CPC_START
     FROM CMS_PAN_CONSTRUCT
    WHERE CPC_PROFILE_CODE = P_PROFILE_CODE AND
         CPC_INST_CODE = P_INSTCODE
    ORDER BY CPC_START_FROM DESC;

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
--      FOR UPDATE WAIT 1; --Modified by Pankaj S. on 08_May_2013 for mantis ID-11048  --Added "For update" for locking select query until update script will execute
--
--    IF V_CTRLNUMB > V_MAX_SERIAL_NO THEN
--     P_ERRMSG := 'Maximum serial number reached';
--     RAISE excp_reject; --RETURN; --Modified by Pankaj S. on 08_May_2013 for mantis ID-11048
--    END IF;
--
--    P_SRNO := V_CTRLNUMB;
--    --Sn Modified by Pankaj S. on 08_May_2013 for mantis ID-11048
--     BEGIN
--       UPDATE cms_pan_ctrl
--          SET cpc_ctrl_numb = v_ctrlnumb + 1
--        WHERE cpc_pan_prefix = p_tmp_pan AND cpc_inst_code = p_instcode;
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
--    --En Modified by Pankaj S. on 08_May_2013 for mantis ID-11048
--
--  EXCEPTION
--    --Sn Added by Pankaj S. on 08_May_2013 for mantis ID-11048
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

  PROCEDURE LP_PAN_CHKDIG(
                     P_TMPPAN   IN VARCHAR2,
                     P_CHECKDIG OUT NUMBER) IS
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
       V_MULT_IND := 1;
     ELSE
       V_MULT_IND := 2;
     END IF;
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

--
--PROCEDURE lp_shuffle_srno (                                              --Added on 26-Mar-2013 for performace issue
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


BEGIN

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
         CAM_STARTER_CARD ,CAM_FILE_NAME
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
     V_ERRMSG := 'No row found for application code' || P_APPLCODE;
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

  --Sn sivapragasam Added on June 05 2012 to select GPR product Category for starter card

   BEGIN

    SELECT CPC_STARTERGPR_CRDTYPE
    INTO V_GPR_CARD_TYPE
    FROM CMS_PROD_CATTYPE
    WHERE CPC_PROD_CODE= V_PROD_CODE AND CPC_INST_CODE= P_INSTCODE
    and CPC_STARTER_CARD != 'N' AND CPC_CARD_TYPE=V_CARD_TYPE;


    IF V_GPR_CARD_TYPE != 0 THEN

        V_CARD_TYPE :=V_GPR_CARD_TYPE;

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

  --En sivapragasam Added on June 05 2012 to select GPR product Category

  --Sn find profile code attached to cardtype
  BEGIN

    SELECT CPM_PROFILE_CODE,
           cpc_profile_code,
           CPM_CATG_CODE,
           CPC_PROD_PREFIX,
           CPC_PROGRAM_ID, --T.Narayanan added for prg id
           --CPM_PROXY_LENGTH ,--Commented for CR-38 DFC- CCF Changes
            /* Start Serial No Chnges added by Dhiraj Gaikwad 20082012 */
          CPC_SERL_FLAG,cpc_exp_date_exemption,
          nvl(cpc_sweep_flag,'N'),
          /* End Serial No Chnges added by Dhiraj Gaikwad 20082012 */
          NVL(cpc_pan_inventory_flag, 'N'), --Added for 17.07 PAN Inventory Changes
          cpc_user_identify_type,
          cpc_prod_suffix,
          cpc_start_card_no,
          cpc_end_card_no,
          NVL(cpc_expdate_randomization,'N') --Added for VMS-7341
     INTO V_PROFILE_CODE,
          v_catg_profile_code,
          V_CPM_CATG_CODE,
          V_PROD_PREFIX,
          V_PROGRAMID, --T.Narayanan added for prg id
          --V_PROXYLENGTH, --Commented for CR-38 DFC- CCF Changes
           /* Start Serial No Chnges added by Dhiraj Gaikwad 20082012 */
          V_CPC_SERL_FLAG ,
          /* End Serial No Chnges added by Dhiraj Gaikwad 20082012 */
          v_exp_date_exemption,
          v_sweep_flag,
          v_pan_inventory_flag,  --Added for 17.07 PAN Inventory Changes
          v_user_identify_type,
          v_prod_suffix,
          v_card_start,
          v_card_end,
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

  -- Added by Trivkram on 08 June 2012 , If not configure PAN Product Category Prefix with Product Category level it will take from Instistute level

            IF V_PROD_PREFIX IS NULL
            THEN
             BEGIN
                 SELECT CIP_PARAM_VALUE
                 INTO V_PROD_PREFIX
                 FROM CMS_INST_PARAM
                WHERE CIP_INST_CODE = P_INSTCODE AND
                     CIP_PARAM_KEY = 'PANPRODCATPREFIX';
                EXCEPTION
                WHEN OTHERS THEN
                V_ERRMSG  := 'Error while selecting PAN Product Category Prefix from CMS_INST_PARAM ' ||
                        SUBSTR(SQLERRM, 1, 300);
                RAISE EXP_REJECT_RECORD;
             END;
            END IF;

  --En find profile code attached to cardtype
 IF v_pan_inventory_flag='N' THEN    --Added for 17.07 PAN Inventory Changes
--  --Sn find pan construct details based on profile code
--  BEGIN
--    V_LOOP_CNT := 0;
--
--    FOR I IN C(v_catg_profile_code) LOOP
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
--  END;
--
--  --En built the pan gen logic based on the value
--
--  --Sn generate the serial no
--  FOR I IN 1 .. V_LOOP_MAX_CNT LOOP
--    FOR J IN 1 .. V_LOOP_MAX_CNT LOOP
--     IF V_TABLE_PAN_CONSTRUCT(J)
--     .CPC_START_FROM = I AND V_TABLE_PAN_CONSTRUCT(J)
--     .CPC_FIELD_NAME <> 'Serial Number' THEN
--       V_TMP_PAN := V_TMP_PAN || V_TABLE_PAN_CONSTRUCT(J).CPC_FIELD_VALUE;
--       EXIT;
--     END IF;
--    END LOOP;
--  END LOOP;
--
--  --Sn get  index value of serial no from PL/SQL table
--  FOR I IN 1 .. V_TABLE_PAN_CONSTRUCT.COUNT LOOP
--    IF V_TABLE_PAN_CONSTRUCT(I).CPC_FIELD_NAME = 'Serial Number' THEN
--     V_SERIAL_INDEX := I;
--    END IF;
--  END LOOP;
--
--  --En get  index value of serial no from PL/SQL table
--  IF V_SERIAL_INDEX IS NOT NULL THEN
--    V_SERIAL_MAXLENGTH := V_TABLE_PAN_CONSTRUCT(V_SERIAL_INDEX).CPC_LENGTH;
--       IF V_CPC_SERL_FLAG =1 THEN
--
--
--             BEGIN                                  --Added on 26-Mar-2013 for performace issue
--                lp_shuffle_srno (p_instcode,
--                                 v_prod_code,
--                                 v_card_type,
--                                 p_lupduser,
--                                 p_shflcntrl_no,
--                                 v_serial_no,
--                                 v_errmsg
--                                );
--
--                IF v_errmsg <> 'OK'
--                THEN
--                   v_donot_mark_error := 1;
--                   RAISE exp_reject_record;
--                END IF;
--
--             EXCEPTION when exp_reject_record
--             then
--                 raise;
--
--             WHEN OTHERS
--             THEN
--                   v_errmsg :=
--                         'Error while calling LP_SHUFFLE_SRNO '
--                      || SUBSTR (SQLERRM, 1, 300);
--                   RAISE exp_reject_record;
--             END;
--
--
--          BEGIN
--               UPDATE cms_shfl_serl
--               SET    css_serl_flag = 1
--               WHERE CSS_SERL_NUMB = V_SERIAL_NO
--               AND     css_inst_code       = P_INSTCODE
--                 AND css_prod_code = V_PROD_CODE --Added on 27092012 Dhiraj Gaikwad
--                AND css_prod_catg = V_CARD_TYPE --Added on 27092012 Dhiraj Gaikwad
--                AND css_shfl_cntrl = p_shflcntrl_no --Added on 26-Mar-2013 for performace issue
--                AND css_serl_flag = 0 ;  --Added on 27092012 Dhiraj Gaikwad
--               IF SQL%ROWCOUNT = 0 THEN
--               V_ERRMSG := 'Error updating Serial  control data, record not updated successfully';
--                RAISE EXP_REJECT_RECORD;
--               END IF;
--
--          EXCEPTION
--           WHEN OTHERS THEN
--              V_ERRMSG := 'Error updating control data ' || substr(sqlerrm,1,150);
--            RAISE EXP_REJECT_RECORD;
--           END;
--         /* End  Serial No Chnges added by Dhiraj Gaikwad 20082012 */
--      ELSE
--
--       BEGIN
--        LP_PAN_SRNO(P_INSTCODE,
--                 P_LUPDUSER,
--                 V_TMP_PAN,
--                 V_SERIAL_MAXLENGTH,
--                 V_SERIAL_NO,
--                 V_ERRMSG);
--
--        IF V_ERRMSG <> 'OK' THEN
--         RAISE EXP_REJECT_RECORD;
--        END IF;
--      EXCEPTION
--      WHEN  EXP_REJECT_RECORD THEN
--         RAISE  ;
--      WHEN OTHERS THEN
--           V_ERRMSG := 'Error while calling LP_PAN_SRNO ' || SUBSTR(SQLERRM, 1, 300);
--         RAISE EXP_REJECT_RECORD;
--      END;
--      END IF ;
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
--
--  --En generate the serial no
--   --Sn generate temp pan for check digit
--  V_TMP_PAN := NULL;
--
--  FOR I IN 1 .. V_LOOP_MAX_CNT LOOP
--    FOR J IN 1 .. V_LOOP_MAX_CNT LOOP
--     IF V_TABLE_PAN_CONSTRUCT(J).CPC_START_FROM = I THEN
--       V_TMP_PAN := V_TMP_PAN || V_TABLE_PAN_CONSTRUCT(J).CPC_FIELD_VALUE;
--       EXIT;
--     END IF;
--    END LOOP;
--  END LOOP;
--
--  --En generate temp pan for check digit
 --SN: Modified/Added for VMS-6655,6843
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
       WHEN EXP_REJECT_RECORD THEN
       RAISE;
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
              WHERE cpc_profile_code = v_catg_profile_code
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

   BEGIN
      v_mask_pan := fn_getmaskpan (v_pan);
   EXCEPTION
      WHEN OTHERS
      THEN
         v_errmsg :=
                    'Error while converting into mask pan ' || SUBSTR (SQLERRM, 1, 200);
         RAISE exp_reject_record;
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
           WHERE CAD_INST_CODE = P_INSTCODE AND
                CAD_APPL_CODE = P_APPLCODE AND CAD_ACCT_POSN = 1);
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
    END;
  ELSIF V_ADDON_STAT = 'P' THEN
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
--    WHERE CBP_INST_CODE = P_INSTCODE AND
--         CBP_PROFILE_CODE = v_catg_profile_code AND CBP_PARAM_NAME = 'Status';
--
--    IF V_CARD_STAT IS NULL THEN
--     V_ERRMSG := 'Status is null for profile code ' || v_catg_profile_code;
--     RAISE EXP_REJECT_RECORD;
--    END IF;
--  EXCEPTION
--    WHEN EXP_REJECT_RECORD THEN
--     RAISE;
--    WHEN NO_DATA_FOUND THEN
--     V_ERRMSG := 'Status is not defined for profile code ' ||
--               v_catg_profile_code;
--     RAISE EXP_REJECT_RECORD;
--    WHEN OTHERS THEN
--     V_ERRMSG := 'Error while selecting card status ' ||
--               SUBSTR(SQLERRM, 1, 200);
--     RAISE EXP_REJECT_RECORD;
--  END;

  --En find card status and limit parameter for the profile


--SN Added for VMS-7341
    IF v_isexpry_randm = 'Y' AND v_sweep_flag<>'Y' THEN
       BEGIN
        vmsfunutilities.get_expiry_date (P_INSTCODE,
                                         V_PROD_CODE,
                                         v_card_type,
                                         v_catg_profile_code,
                                         1,
                                         v_expry_arry,
                                         V_ERRMSG);
           IF V_ERRMSG <> 'OK' THEN
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
    ELSIF v_sweep_flag<>'Y' then
     BEGIN
            vmsfunutilities.get_expiry_date(P_INSTCODE,V_PROD_CODE,
            v_card_type,v_catg_profile_code,v_expry_date,V_ERRMSG);

            if V_ERRMSG<>'OK' then
             RAISE EXP_REJECT_RECORD;

             END IF;

     EXCEPTION
       WHEN EXP_REJECT_RECORD THEN
        RAISE;
       WHEN OTHERS THEN
                V_ERRMSG:='Error while calling vmsfunutilities.get_expiry_date'||substr(sqlerrm,1,200);
        RAISE EXP_REJECT_RECORD;
     END;

    END IF;
         --En added for card expiry date logic chages.

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


    --Sn added by Pankaj S. on 27_Feb_2013 for DFCHOST-249
      BEGIN
    SELECT CAP_PAN_CODE,CAP_PROXY_NUMBER
      INTO V_CAP_STARTER_CARD,V_PROXY_NUMBER from
      (SELECT CAP_PAN_CODE,CAP_PROXY_NUMBER
      FROM CMS_APPL_PAN
     WHERE CAP_INST_CODE=P_INSTCODE
       AND CAP_APPL_CODE=P_APPLCODE
       AND CAP_STARTERCARD_FLAG = 'Y' order by cap_pangen_date desc) where rownum=1;
    EXCEPTION
    WHEN NO_DATA_FOUND THEN
    V_ERRMSG := 'No starter card found for application code-' || P_APPLCODE;
    RAISE EXP_REJECT_RECORD;
    WHEN OTHERS THEN
    V_ERRMSG := 'Error while selecting starter card details-'||
           SUBSTR(SQLERRM, 1, 200);
    RAISE EXP_REJECT_RECORD;
    END;
    --En added by Pankaj S. on 27_Feb_2013 for DFCHOST-249
  --Sn create a record in appl_pan
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
      CAP_NEXT_MB_DATE , --added for monthly fees calc on 24012012
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
      CAP_PROXY_NUMBER, --Uncommented by Pankaj S. on 27_Feb_2013 for DFCHOST-249  <<--Commented for CR-38 DFC- CCF Changes-->>
      CAP_MMPOS_ONLINE_LIMIT,
      CAP_MMPOS_OFFLINE_LIMIT,
      CAP_STARTERCARD_FLAG, --Modified by Sivapragasam on Feb 20 2012 for Starter Card
      CAP_INACTIVE_FEECALC_DATE, --Added by Deepa on June 13 2012 for Inactive Fee Calculation
      CAP_MASK_PAN ,              -- Added by sagar on 13Aug2012 for Pan masking changes
      CAP_PROXY_MSG,  --Added by Pankaj S. on 27_Feb_2013 for DFCHOST-249
      cap_user_identify_type
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
      NULL,--Modified by Deepa on June 22 2012
      NULL,--Modified by Deepa on June 22 2012
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
      V_PROXY_NUMBER,   --Uncommented by Pankaj S. on 27_Feb_2013 for DFCHOST-249  <<--Commented for CR-38 DFC- CCF Changes-->>
      V_ONLINE_MMPOS_LIMIT,
      V_OFFLINE_MMPOS_LIMIT,
      V_STARTER_CARD, --Modified by Sivapragasam on Feb 20 2012 for Starter Card
      NULL,            --Modified by Deepa on June 22 2012
      v_mask_pan,       -- Added by sagar on 13Aug2012 for Pan masking changes
      'Success', --Added by Pankaj S. on 27_Feb_2013 for DFCHOST-249
      v_user_identify_type
      );
  EXCEPTION
    WHEN DUP_VAL_ON_INDEX THEN
     V_ERRMSG := 'Pan ' || V_PAN ||
               ' is already present in the Pan_master';
     RAISE EXP_REJECT_RECORD;
    WHEN OTHERS THEN
     V_ERRMSG := 'Error while inserting records into pan master ' ||
               SUBSTR(SQLERRM, 1, 200);
     RAISE EXP_REJECT_RECORD;
  END;


  --Inserting in card issuance status table
  BEGIN
   insert into cms_cardissuance_status (CCS_INST_CODE,
                                        CCS_PAN_CODE,
                                        CCS_CARD_STATUS,
                                        CCS_INS_USER,
                                        CCS_LUPD_USER,
                                        CCS_PAN_CODE_ENCR,
                                        CCS_LUPD_DATE,
                                        ccs_appl_code
                                        )
                             values    (P_INSTCODE,
                                        V_HASH_PAN,
                                        2,
                                        P_LUPDUSER,
                                        P_LUPDUSER,
                                        V_ENCR_PAN,
                                        sysdate,
                                        P_APPLCODE
                                        );
    EXCEPTION
    WHEN OTHERS THEN
     V_ERRMSG := 'Error while Inserting in Card status Table ' || SUBSTR(SQLERRM, 1, 200);
     RAISE EXP_REJECT_RECORD;
  end;



     BEGIN
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
                                 CSA_FAST50_FLAG, -- Added by MageshKumar.S on 19/09/2013 for JH-6
                                 CSA_FEDTAX_REFUND_FLAG, -- Added by MageshKumar.S on 19/09/2013 for JH-6
                                 CSA_DEPPENDING_FLAG,CSA_DEPACCEPTED_FLAG,CSA_DEPREJECTED_FLAG, -- Added by Raja Gopal G on 30/07/2014 fro FR 3.2
                                 CSA_INS_USER,
                                 CSA_INS_DATE,
                                 CSA_LUPD_USER,
                                 CSA_LUPD_DATE
                                 )
                        (SELECT P_INSTCODE,
                               V_HASH_PAN,
                               V_ENCR_PAN,
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
                               CSA_FAST50_FLAG, -- Added by MageshKumar.S on 19/09/2013 for JH-6
                               CSA_FEDTAX_REFUND_FLAG, -- Added by MageshKumar.S on 19/09/2013 for JH-6
                               CSA_DEPPENDING_FLAG,CSA_DEPACCEPTED_FLAG,CSA_DEPREJECTED_FLAG, -- Added by Raja Gopal G on 30/07/2014 fro FR 3.2
                               P_LUPDUSER,
                               SYSDATE,
                               P_LUPDUSER,
                               SYSDATE
                           FROM CMS_SMSANDEMAIL_ALERT
                          WHERE csa_inst_code = p_instcode
                          AND csa_pan_code    = v_cap_starter_card
                          );

       IF SQL%ROWCOUNT != 1 THEN
        V_ERRMSG  := 'Error while Entering sms email alert detail ';
        RAISE EXP_REJECT_RECORD;
       END IF;

     EXCEPTION
	 when DUP_VAL_ON_INDEX then null;
	 when EXP_REJECT_RECORD
     then
         raise;

       WHEN OTHERS THEN
        V_ERRMSG  := 'Error while Entering sms email alert detail ' ||
                    SUBSTR(SQLERRM, 1, 100);
        RAISE EXP_REJECT_RECORD;

     END;

  -------------------------------------------------------------------------------
  --EN:Added on 26-FEB-2013 for FSS-756 to set alerts of starter card to GPR card
  --------------------------------------------------------------------------------


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
                V_PAN || 'acct id ' || X.CAD_ACCT_ID;
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
      SET PCC_PAN_NO      = V_HASH_PAN
        ,
         PCC_PAN_NO_ENCR = V_ENCR_PAN
    WHERE PCC_INST_CODE = P_INSTCODE AND PCC_PAN_NO = V_ACCT_NUM ;
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
    WHERE PCC_INST_CODE = P_INSTCODE AND PCC_PAN_NO = V_ACCT_NUM  ;
  EXCEPTION
    WHEN EXP_REJECT_RECORD THEN
     RAISE;
    WHEN OTHERS THEN
     V_ERRMSG := 'Error while updating corporate_card account number ' ||
               SUBSTR(SQLERRM, 1, 200);
     RAISE EXP_REJECT_RECORD;
  END;

  --En update acct_mast for pan


  -- Sn Create a entry for initial load
  IF V_INITIAL_TOPUP_AMOUNT > 0 THEN


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
    null,--V_CR_GL_CODE, --commented for fwr-48
    null,--V_CRSUBGL_CODE,--commented for fwr-48
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
  --<< MAIN EXCEPTION >>
  WHEN EXP_REJECT_RECORD THEN
    ROLLBACK TO V_SAVEPOINT;
    P_ERRMSG := V_ERRMSG;
IF V_DONOT_MARK_ERROR<>1 THEN
    UPDATE CMS_APPL_MAST
      SET CAM_APPL_STAT   = 'E',
         CAM_PROCESS_MSG = V_ERRMSG,
         CAM_LUPD_USER   = P_LUPDUSER
    WHERE CAM_INST_CODE = P_INSTCODE AND CAM_APPL_CODE = P_APPLCODE;
   ELSIF V_DONOT_MARK_ERROR=1 THEN

      INSERT INTO cms_serl_error
                                 (cse_inst_code, cse_prod_code,
                                  cse_prod_catg, cse_ordr_rfrno,
                                  cse_err_mseg
                                 )
                          VALUES (P_INSTCODE, V_PROD_CODE,
                                  V_CARD_TYPE, V_CAM_FILE_NAME,
                                  V_ERRMSG
                                 );
                                 END  IF ;

    P_APPLPROCESS_MSG := V_ERRMSG;
    P_ERRMSG          := 'OK';
  WHEN OTHERS THEN
    ROLLBACK TO V_SAVEPOINT;
    -- P_errmsg := 'Error while processing application for pan gen ' || SUBSTR(SQLERRM,1,200);
    P_APPLPROCESS_MSG := 'Error while processing application for pan gen ' ||
                      SUBSTR(SQLERRM, 1, 200);
    V_ERRMSG            := 'Error while processing application for pan gen ' ||
                      SUBSTR(SQLERRM, 1, 200);

    UPDATE CMS_APPL_MAST
      SET CAM_APPL_STAT   = 'E',
         CAM_PROCESS_MSG = V_ERRMSG,
         CAM_LUPD_USER   = P_LUPDUSER
    WHERE CAM_INST_CODE = P_INSTCODE AND CAM_APPL_CODE = P_APPLCODE;

    P_ERRMSG := 'OK';
END;
/
Show error;