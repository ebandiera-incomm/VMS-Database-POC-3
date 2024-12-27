create or replace
PACKAGE BODY        VMSCMS.VMSPRODUCT
IS

PROCEDURE  PRODUCT_PROFILE_TEMPCOPY (
   p_instcode_in            IN       NUMBER,
   p_ins_user_in            IN       NUMBER,
   p_prod_code_in           IN       VARCHAR2,
   p_prod_catg_in           IN       VARCHAR2,
   p_errmsg_out             OUT      VARCHAR2
)
IS

/**********************************************************************************************


  * Created by                  : MageshKumar S.
  * Created Date                : 01-MAR-16
  * Created For                 : HOSTCC-57
  * Created reason              : PRODUCT PROFILE COPY PROGRAM
  * Reviewer                    : SARAVANAKUMAR/SPANKAJ
  * Build Number                : VMSGPRHOSTCSD4.0_B0001


  * Modified by                  : Saravanakumar A
  * Modified Date                : 20-Sep-16
  * Modified For                 : Proper exception Handling
    * Reviewer                   : SPANKAJ
  * Build Number                : VMSGPRHOSTCSD4.7.2
  
  * Modified by      : Saravana Kumar A
  * Modified Date    : 07-Jan-17
  * Modified reason  : Card Expiry date logic changes
  * Reviewer         : Spankaj
  * Build Number     : VMSGPRHOST17.1

  	 * Modified by       : DHINAKARAN B
     * Modified Date     : 18-Jul-17
     * Modified For      : FSS-5172 - B2B changes
     * Reviewer          : Saravanakumar A
     * Build Number      : VMSGPRHOST_17.07

**************************************************************************************************/
--l_savepoint           NUMBER                              DEFAULT 1;

l_profile_code     cms_profile_mast.cpm_profile_code%TYPE;
l_profile_name     cms_profile_mast.cpm_profile_name%TYPE;
l_profile_level    cms_profile_mast.cpm_profile_level%TYPE;
EXP_REJECT_RECORD  EXCEPTION;

CURSOR PROD_PIN_EMBOSS_INFO(l_profile_code IN VARCHAR2)
IS
SELECT
CBP_PROFILE_CODE,CBP_PARAM_TYPE,CBP_PARAM_NAME,CBP_PARAM_VALUE
FROM CMS_BIN_PARAM,CMS_PROFILE_MAST
WHERE CBP_PROFILE_CODE=CPM_PROFILE_CODE
AND CBP_PROFILE_CODE=l_profile_code
AND CPM_PROFILE_LEVEL='P';

CURSOR PAN_CONSTRUCT(l_profile_code IN VARCHAR2)
IS
SELECT
CPC_PROFILE_CODE,CPC_FIELD_NAME,CPC_START,CPC_LENGTH,
CPC_VALUE,CPC_ORDER_BY,CPC_START_FROM
FROM CMS_PAN_CONSTRUCT
WHERE CPC_PROFILE_CODE=l_profile_code;

CURSOR ACCT_CONSTRUCT(l_profile_code IN VARCHAR2)
IS
SELECT
CAC_PROFILE_CODE,CAC_FIELD_NAME,CAC_START,CAC_LENGTH,
CAC_VALUE,CAC_ORDER_BY,CAC_START_FROM
FROM CMS_ACCT_CONSTRUCT
WHERE CAC_PROFILE_CODE=l_profile_code;

CURSOR SAl_ACCT_CONSTRUCT(l_profile_code IN VARCHAR2)
IS
SELECT
CSC_PROFILE_CODE,CSC_FIELD_NAME,CSC_START,CSC_LENGTH,
CSC_VALUE,CSC_TOT_LENGTH,CSC_ORDER_BY,CSC_START_FROM
FROM CMS_SAVINGSACCT_CONSTRUCT
WHERE CSC_PROFILE_CODE=l_profile_code;

ref_cur_profile sys_refcursor;
BEGIN

 p_errmsg_out  := 'OK';
 --SAVEPOINT l_savepoint;
 open ref_cur_profile for 'SELECT  CPM_PROFILE_CODE,
      CPM_PROFILE_NAME,
      CPM_PROFILE_LEVEL
    FROM CMS_PROFILE_MAST
      WHERE CPM_PROFILE_CODE IN(SELECT CPC_PROFILE_CODE FROM CMS_PROD_CATTYPE WHERE CPC_PROD_CODE='''||p_prod_code_in||''' and CPC_CARD_TYPE IN ('||p_prod_catg_in||'))';
    loop
        fetch ref_cur_profile into l_profile_code,l_profile_name,l_profile_level;
        exit when ref_cur_profile%notfound;

 BEGIN

  INSERT INTO VMS_PROFILE_MAST_STAG
   (VPM_PROFILE_CODE,
      VPM_PROFILE_NAME,
      VPM_INS_USER,
      VPM_INS_DATE,
      VPM_LUPD_USER,
      VPM_LUPD_DATE,
      VPM_INST_CODE,
      VPM_PROFILE_LEVEL)
    VALUES(
    l_profile_code,
    l_profile_name,
    p_ins_user_in,
    sysdate,
    p_ins_user_in,
    sysdate,
    p_instcode_in,
    l_profile_level
    );
   EXCEPTION
            WHEN OTHERS
            THEN
               p_errmsg_out :=
                     'ERROR WHILE INSERTING INTO VMS_PROFILE_MAST_STAG:'
                  || SUBSTR (SQLERRM, 1, 300);
               RAISE EXP_REJECT_RECORD;

 END;

  BEGIN
            FOR l_row_indx IN PROD_PIN_EMBOSS_INFO(l_profile_code)
            LOOP
            INSERT INTO VMS_BIN_PARAM_STAG(
                    VBP_PROFILE_CODE,
                    VBP_PARAM_TYPE,
                    VBP_PARAM_NAME,
                    VBP_PARAM_VALUE,
                    VBP_INS_USER,
                    VBP_INS_DATE,
                    VBP_LUPD_USER,
                    VBP_LUPD_DATE,
                    VBP_INST_CODE)
                    VALUES(
                    l_profile_code,
                    l_row_indx.CBP_PARAM_TYPE,
                    l_row_indx.CBP_PARAM_NAME,
                    l_row_indx.CBP_PARAM_VALUE,
                    p_ins_user_in,
                    SYSDATE,
                    p_ins_user_in,
                    SYSDATE,
                    p_instcode_in
                    );

            END LOOP;
            EXCEPTION
            WHEN OTHERS
            THEN
               P_ERRMSG_OUT :=
                     'ERROR WHILE INSERTING INTO VMS_BIN_PARAM_STAG:'
                  || SUBSTR (SQLERRM, 1, 300);
               RAISE EXP_REJECT_RECORD;

 END;

 BEGIN
            FOR l_row_indx IN PAN_CONSTRUCT(l_profile_code)
            LOOP
            INSERT INTO VMS_PAN_CONSTRUCT_STAG(
                    VPC_INST_CODE,
                    VPC_PROFILE_CODE,
                    VPC_FIELD_NAME,
                    VPC_START,
                    VPC_LENGTH,
                    VPC_VALUE,
                    VPC_ORDER_BY,
                    VPC_START_FROM,
                    VPC_LUPD_DATE,
                    VPC_LUPD_USER,
                    VPC_INS_DATE,
                    VPC_INS_USER)
                    VALUES(
                    p_instcode_in,
                    l_profile_code,
                    l_row_indx.CPC_FIELD_NAME,
                    l_row_indx.CPC_START,
                    l_row_indx.CPC_LENGTH,
                    l_row_indx.CPC_VALUE,
                    l_row_indx.CPC_ORDER_BY,
                    l_row_indx.CPC_START_FROM,
                    SYSDATE,
                    p_ins_user_in,
                    SYSDATE,
                    p_ins_user_in
                    );

            END LOOP;
            EXCEPTION
            WHEN OTHERS
            THEN
               p_errmsg_out :=
                     'ERROR WHILE INSERTING INTO VMS_PAN_CONSTRUCT_STAG:'
                  || SUBSTR (SQLERRM, 1, 300);
               RAISE EXP_REJECT_RECORD;

 END;

  BEGIN
            FOR l_row_indx IN ACCT_CONSTRUCT(l_profile_code)
            LOOP
            INSERT INTO VMS_ACCT_CONSTRUCT_STAG(
                    VAC_INST_CODE,
                    VAC_PROFILE_CODE,
                    VAC_FIELD_NAME,
                    VAC_START,
                    VAC_LENGTH,
                    VAC_VALUE,
                    VAC_ORDER_BY,
                    VAC_START_FROM,
                    VAC_LUPD_DATE,
                    VAC_LUPD_USER,
                    VAC_INS_DATE,
                    VAC_INS_USER)
                    VALUES(
                    p_instcode_in,
                    l_profile_code,
                    l_row_indx.CAC_FIELD_NAME,
                    l_row_indx.CAC_START,
                    l_row_indx.CAC_LENGTH,
                    l_row_indx.CAC_VALUE,
                    l_row_indx.CAC_ORDER_BY,
                    l_row_indx.CAC_START_FROM,
                    SYSDATE,
                    p_ins_user_in,
                    SYSDATE,
                    p_ins_user_in
                    );

            END LOOP;
            EXCEPTION
            WHEN OTHERS
            THEN
               p_errmsg_out :=
                     'ERROR WHILE INSERTING INTO VMS_ACCT_CONSTRUCT_STAG:'
                  || SUBSTR (SQLERRM, 1, 300);
               RAISE EXP_REJECT_RECORD;

 END;

 BEGIN
            FOR l_row_indx IN SAl_ACCT_CONSTRUCT(l_profile_code)
            LOOP
            INSERT INTO VMS_SAVINGSACCT_CONSTRUCT_STAG(
                    VSC_INST_CODE,
                    VSC_PROFILE_CODE,
                    VSC_FIELD_NAME,
                    VSC_START,
                    VSC_LENGTH,
                    VSC_VALUE,
                    VSC_TOT_LENGTH,
                    VSC_ORDER_BY,
                    VSC_START_FROM,
                    VSC_LUPD_DATE,
                    VSC_LUPD_USER,
                    VSC_INS_DATE,
                    VSC_INS_USER)
                    VALUES(
                    p_instcode_in,
                    l_profile_code,
                    l_row_indx.CSC_FIELD_NAME,
                    l_row_indx.CSC_START,
                    l_row_indx.CSC_LENGTH,
                    l_row_indx.CSC_VALUE,
                    l_row_indx.CSC_TOT_LENGTH,
                    l_row_indx.CSC_ORDER_BY,
                    l_row_indx.CSC_START_FROM,
                    SYSDATE,
                    p_ins_user_in,
                    SYSDATE,
                    p_ins_user_in
                    );

            END LOOP;
            EXCEPTION
            WHEN OTHERS
            THEN
               p_errmsg_out :=
                     'ERROR WHILE INSERTING INTO VMS_SAVINGSACCT_CONSTRUCT_STAG:'
                  || SUBSTR (SQLERRM, 1, 300);
               RAISE EXP_REJECT_RECORD;

 END;
  end loop;

  EXCEPTION
    WHEN EXP_REJECT_RECORD THEN
    ROLLBACK ;--TO l_savepoint;
  WHEN OTHERS THEN
    ROLLBACK;-- TO l_savepoint;
    p_errmsg_out := 'Exception while copying PRODUCT_PROFILE_TEMPCOPY:' ||p_errmsg_out || SUBSTR(SQLERRM, 1, 200);

END;

-- end of product profile copy

--start product category profile copy

--PROCEDURE  PRODCATG_PROFILE_TEMPCOPY (
--   p_instcode_in            IN       NUMBER,
--   p_ins_user_in            IN       NUMBER,
--   p_prod_code_in           IN       VARCHAR2,
--   p_prod_catg_in           IN       VARCHAR2,
--   p_errmsg_out             OUT      VARCHAR2
--)
--IS
--
--/**********************************************************************************************
--
--
--  * Created by                  : MageshKumar S.
--  * Created Date                : 01-MAR-16
--  * Created For                 : HOSTCC-57
--  * Created reason              : PRODUCT CATEGORY PROFILE COPY PROGRAM
--  * Reviewer                    : SARAVANAKUMAR/SPANKAJ
--  * Build Number                : VMSGPRHOSTCSD4.0_B0001
--
--**************************************************************************************************/
----l_savepoint           NUMBER                              DEFAULT 1;
--EXP_REJECT_RECORD EXCEPTION;
--l_profile_code     cms_profile_mast.cpm_profile_code%type;
--l_profile_name     cms_profile_mast.cpm_profile_name%TYPE;
--l_profile_level    cms_profile_mast.cpm_profile_level%type;
--l_param_type       cms_bin_param.cbp_param_type%type;
--l_param_name       cms_bin_param.cbp_param_name%type;
--l_param_value       cms_bin_param.cbp_param_value%type;
--
--
--ref_cur_prodcatg_profile   sys_refcursor;
--ref_cur_prodcatg_binparam  sys_refcursor;
--
--
--BEGIN
--
-- p_errmsg_out  := 'OK';
-- --SAVEPOINT l_savepoint;
--
-- BEGIN
--
--    OPEN ref_cur_prodcatg_profile FOR
--    'SELECT  CPM_PROFILE_CODE,CPM_PROFILE_NAME, CPM_PROFILE_LEVEL
--     FROM CMS_PROFILE_MAST
--     WHERE CPM_PROFILE_CODE IN(SELECT distinct CPC_PROFILE_CODE FROM CMS_PROD_CATTYPE
--     WHERE CPC_PROD_CODE='''||p_prod_code_in||''' AND CPC_CARD_TYPE IN('||p_prod_catg_in||'))';
--    LOOP
--    FETCH ref_cur_prodcatg_profile INTO l_profile_code,l_profile_name,l_profile_level;
--    EXIT WHEN ref_cur_prodcatg_profile%NOTFOUND;
--
--    INSERT INTO VMS_PROFILE_MAST_STAG
--   (VPM_PROFILE_CODE,
--      VPM_PROFILE_NAME,
--      VPM_INS_USER,
--      vpm_ins_date,
--      VPM_LUPD_USER,
--      vpm_lupd_date,
--      vpm_inst_code,
--      VPM_PROFILE_LEVEL)
--    VALUES(
--    l_profile_code,
--    l_profile_name,
--    p_ins_user_in,
--    sysdate,
--    p_ins_user_in,
--    sysdate,
--    p_instcode_in,
--    l_profile_level);
--
--
--   END LOOP;
--
--   EXCEPTION
--            WHEN OTHERS
--            THEN
--               p_errmsg_out :=
--                     'ERROR WHILE INSERTING INTO VMS_PROFILE_MAST_STAG:'
--                  || SUBSTR (SQLERRM, 1, 300);
--               RAISE EXP_REJECT_RECORD;
--
-- END;
--
--
-- BEGIN
--
--    OPEN ref_cur_prodcatg_binparam FOR
--    'SELECT  CPM_PROFILE_CODE,
--     CBP_PARAM_TYPE,CBP_PARAM_NAME,CBP_PARAM_VALUE
--     FROM CMS_BIN_PARAM,CMS_PROFILE_MAST
--     WHERE CBP_PROFILE_CODE=CPM_PROFILE_CODE
--     AND CBP_PROFILE_CODE IN(SELECT CPC_PROFILE_CODE FROM CMS_PROD_CATTYPE
--     WHERE CPC_PROD_CODE='''||p_prod_code_in||''' AND CPC_CARD_TYPE IN('||p_prod_catg_in||')) AND CPM_PROFILE_LEVEL=''PC''';
--    LOOP
--    FETCH ref_cur_prodcatg_binparam INTO l_profile_code,l_param_type,l_param_name,l_param_value;
--    EXIT WHEN ref_cur_prodcatg_binparam%NOTFOUND;
--
--    INSERT INTO VMS_BIN_PARAM_STAG(
--                    VBP_PROFILE_CODE,
--                    VBP_PARAM_TYPE,
--                    VBP_PARAM_NAME,
--                    VBP_PARAM_VALUE,
--                    VBP_INS_USER,
--                    VBP_INS_DATE,
--                    VBP_LUPD_USER,
--                    VBP_LUPD_DATE,
--                    VBP_INST_CODE)
--                    VALUES(
--                    l_profile_code,
--                    l_param_type,
--                    l_param_name,
--                    l_param_value,
--                    p_ins_user_in,
--                    SYSDATE,
--                    p_ins_user_in,
--                    SYSDATE,
--                    p_instcode_in
--                    );
--
--    END LOOP;
--
--   EXCEPTION
--            WHEN OTHERS
--            THEN
--               p_errmsg_out :=
--                     'ERROR WHILE INSERTING INTO VMS_BIN_PARAM_STAG:'
--                  || SUBSTR (SQLERRM, 1, 300);
--               RAISE EXP_REJECT_RECORD;
--
-- END;
--
--
-- EXCEPTION
--  WHEN EXP_REJECT_RECORD THEN
--  ROLLBACK;-- TO l_savepoint;
--  WHEN OTHERS THEN
--  ROLLBACK;-- TO l_savepoint;
--  p_errmsg_out := 'Exception while copying PRODCATG_PROFILE_TEMPCOPY:' ||p_errmsg_out || SUBSTR(SQLERRM, 1, 200);
--
--END;

--end of product category profile copy


--start product parameter copy

PROCEDURE  PRODUCT_PARAMETER_TEMPCOPY (
   p_instcode_in            IN       NUMBER,
   p_ins_user_in            IN       NUMBER,
   p_bin_in                 IN       VARCHAR2,
   p_prod_code_in           IN       VARCHAR2,
   p_errmsg_out             OUT      VARCHAR2
)
IS

/**********************************************************************************************


  * Created by                  : MageshKumar S.
  * Created Date                : 01-MAR-16
  * Created For                 : HOSTCC-57
  * Created reason              : PRODUCT PARAMETER COPY PROGRAM
  * Reviewer                    : SARAVANAKUMAR/SPANKAJ
  * Build Number                : VMSGPRHOSTCSD4.0_B0001

   * Modified by      : Sivakumar M
   * Modified For     : CLVMS-124
   * Modified Date    : 08-JUNE-2016
   * Reviewer         : Saravanan/Spankaj
   * Build Number     : VMSGPRHOSTCSD4.2_B0001

   * Modified by      : Renuka T
   * Modified For     : FSS-5157 - B2B Gift Card - Phase 2
   * Modified Date    : 20-JUNE-2017
   * Reviewer         : Saravanan/Spankaj
   * Build Number     : 17.07_B0001
   
   * Modified by      : Narayana
   * Modified For     : VMS-1048 (VMS Host Configure new product in Dev A to replicate to other lower environments)
   * Modified Date    : 13-AUG-2019
   * Reviewer         : Saravanakumar
   * Build Number     : R19_B0002  

**************************************************************************************************/
--l_savepoint           NUMBER                              DEFAULT 1;
EXP_REJECT_RECORD EXCEPTION;
l_prof_code            cms_profile_mast.cpm_profile_code%TYPE;
l_profile_name         cms_profile_mast.cpm_profile_name%TYPE;
L_PROFILE_LEVEL        CMS_PROFILE_MAST.CPM_PROFILE_LEVEL%TYPE;
l_interchange_code     cms_bin_mast.cbm_interchange_code%TYPE;
l_association_code     cms_prod_mast.CPM_ASSO_CODE%TYPE;
l_inst_type            cms_prod_mast.CPM_INST_TYPE%TYPE;
l_catg_code            cms_prod_mast.CPM_CATG_CODE%TYPE;
l_prod_desc            cms_prod_mast.CPM_PROD_DESC%TYPE;
l_switch_prod          cms_prod_mast.CPM_SWITCH_PROD%TYPE;
l_validity_period      cms_prod_mast.CPM_VALIDITY_PERIOD%TYPE;
--l_val_flag             cms_prod_mast.CPM_VAR_FLAG%TYPE;
L_RULEGRP_CODE         CMS_PROD_MAST.CPM_RULEGROUP_CODE%TYPE;
--l_profile_code         cms_prod_mast.CPM_PROFILE_CODE%TYPE;
l_marcprod_flag        cms_prod_mast.CPM_MARC_PROD_FLAG%TYPE;
l_prodmast_param       cms_prod_mast.CPM_PRODMAST_PARAM1%TYPE;
--l_prog_id              cms_prod_mast.CPM_PROGRAM_ID%TYPE;
l_preauthexp_period    cms_prod_mast.CPM_PRE_AUTH_EXP_DATE%TYPE;
--l_proxy_len            cms_prod_mast.CPM_PROXY_LENGTH%TYPE;
L_ROUT_NUM             CMS_PROD_MAST.CPM_ROUT_NUM%TYPE;
l_issu_bank            cms_prod_mast.CPM_ISSU_BANK%TYPE;
l_ica                  cms_prod_mast.CPM_ICA%TYPE;
L_OLSEXPRY_FLAG        CMS_PROD_MAST.CPM_OLS_EXPIRY_FLAG%TYPE;
l_stmt_footer          cms_prod_mast.CPM_STATEMENT_FOOTER%TYPE;
l_passive_flag         cms_prod_mast.CPM_PASSIVE_FLAG%TYPE;
l_olsresp_flag         cms_prod_mast.CPM_OLSRESP_FLAG%TYPE;
l_emv_flag             cms_prod_mast.CPM_EMV_FLAG%TYPE;
l_inst_id              cms_prod_mast.CPM_INSTITUTION_ID%TYPE;
l_transit_num          cms_prod_mast.CPM_TRANSIT_NUMBER%TYPE;
l_random_pin           cms_prod_mast.CPM_RANDOM_PIN%TYPE;
l_pinchange_flag       cms_prod_mast.CPM_PINCHANGE_FLAG%TYPE;
l_ctc_bin              cms_prod_mast.CPM_CTC_BIN%TYPE;
l_poa_prod             cms_prod_mast.CPM_POA_PROD%TYPE;
l_issubank_addr        cms_prod_mast.CPM_ISSU_BANK_ADDR%TYPE;
l_onusexpry_flag       cms_prod_mast.CPM_ONUS_AUTH_EXPIRY%TYPE;
l_prod_threshold       CMS_PROD_THRESHOLD.CPT_PROD_THRESHOLD%TYPE;
l_email_id             cms_product_param.cpp_email_id%TYPE;
l_fromemail_id         cms_product_param.CPP_FROMEMAIL_ID%TYPE;
l_app_name             cms_product_param.CPP_APP_NAME%TYPE;
l_appnty_type          cms_product_param.CPP_APPNTY_TYPE%TYPE;
l_kycverify_flag       cms_product_param.CPP_KYCVERIFY_FLAG%TYPE;
l_networkacq_flag      cms_product_param.CPP_NETWORKACQID_FLAG%TYPE;
l_short_code           cms_product_param.CPP_SHORT_CODE%TYPE;
l_cip_intvl            cms_product_param.CPP_CIP_INTVL%TYPE;
--l_renewprod_code       cms_product_param.CPP_RENEW_PRODCODE%TYPE;
--l_renewcard_type       cms_product_param.CPP_RENEW_CARDTYPE%TYPE;
l_dup_ssnchk           cms_product_param.CPP_DUP_SSNCHK%TYPE;
l_dup_timeperiod       cms_product_param.CPP_DUP_TIMEPERIOD%TYPE;
l_dup_timeout          cms_product_param.CPP_DUP_TIMEUNT%TYPE;
l_gprflag_achtxn       cms_product_param.CPP_GPRFLAG_ACHTXN%TYPE;
l_acctunlock_duration  cms_product_param.CPP_ACCTUNLOCK_DURATION%TYPE;
l_wrong_logoncnt       cms_product_param.CPP_WRONG_LOGONCOUNT%TYPE;
l_partner_id           cms_product_param.CPP_PARTNER_ID%TYPE;
l_mmpos_feeplan        cms_product_param.CPP_MMPOS_FEEPLAN%TYPE;
l_renew_pinmigration   cms_product_param.CPP_RENEWAL_PINMIGRATION%TYPE;
l_achblkexpry_period   cms_product_param.CPP_ACHBLCKEXPRY_PERIOD%TYPE;
l_federalchk_flag      cms_product_param.CPP_FEDERALCHECK_FLAG%TYPE;
l_preauth_prodflag     cms_product_param.CPP_PREAUTH_PRODFLAG%TYPE;
l_aggregator_id        cms_product_param.CPP_AGGREGATOR_ID%TYPE;
l_tandc_version        cms_product_param.CPP_TANDC_VERSION%TYPE;
l_b2bcard_stat         cms_product_param.CPP_B2BCARD_STAT%TYPE;
l_b2b_lmtprfl          cms_product_param.CPP_B2B_LMTPRFL%TYPE;
l_hostflr_lmt          cms_product_param.CPP_HOSTFLOOR_LIMIT%TYPE;
l_spd_flag             cms_product_param.CPP_SPD_FLAG%TYPE;
l_upc                  cms_product_param.CPP_UPC%TYPE;
l_b2bfname_flag        cms_product_param.CPP_B2BFLNAME_FLAG%TYPE;
l_clawback_desc        cms_product_param.CPP_CLAWBACK_DESC%TYPE;
l_product_type         cms_product_param.CPP_PRODUCT_TYPE%TYPE;
l_webauthmapping_id    CMS_PRODUCT_PARAM.cpp_webauthmapping_id%TYPE;
l_ivrauthmapping_id    CMS_PRODUCT_PARAM.cpp_ivrauthmapping_id%TYPE;
l_subbin_length        CMS_PRODUCT_PARAM.CPP_SUBBIN_LENGTH%TYPE;
L_BIN CMS_PROD_BIN.CPB_INST_BIN%TYPE;
l_prod_threshold_count PLS_INTEGER;

CURSOR PRODNETWORKID_MAPPING(l_prod_code_in IN VARCHAR)
IS
SELECT CPM_NETWORK_ID
FROM CMS_PRODNETWORKID_MAPPING WHERE CPM_PROD_CODE=l_prod_code_in;

CURSOR PRODUCT_CARDPACK(l_prod_code_in IN VARCHAR)
IS
SELECT CPC_CARD_DETAILS,CPC_PRINT_VENDOR,CPC_INST_REPLACEMENT_FLAG,CPC_CARD_ID
FROM CMS_PROD_CARDPACK WHERE CPC_PROD_CODE=l_prod_code_in;

CURSOR SCORECARD_PRODMAPPING(l_prod_code_in IN VARCHAR)
IS
SELECT CSP_SCORECARD_ID,
CSP_DELIVERY_CHANNEL,CSP_CIPCARD_STAT,CSP_AVQ_FLAG
FROM CMS_SCORECARD_PRODMAPPING WHERE CSP_PROD_CODE=l_prod_code_in;

BEGIN

 p_errmsg_out  := 'OK';
-- SAVEPOINT l_savepoint;



 BEGIN

 IF trim(P_BIN_IN) IS NULL or  P_BIN_IN='NS' THEN
  SELECT CPB_INST_BIN INTO L_BIN FROM CMS_PROD_BIN WHERE CPB_PROD_CODE=P_PROD_CODE_IN;
  ELSE
  L_BIN := P_BIN_IN;
 END IF;



 SELECT CBM_INTERCHANGE_CODE INTO l_interchange_code
 FROM CMS_BIN_MAST WHERE CBM_INST_BIN=L_BIN;

   EXCEPTION
            WHEN OTHERS
            THEN
               P_ERRMSG_OUT :=
                     'ERROR WHILE SELECTING DETAILS FROM  CMS_BIN_MAST value :'
                  || SUBSTR (SQLERRM, 1, 300);
               RAISE EXP_REJECT_RECORD;

 END;

  BEGIN

SELECT count(*) INTO l_prod_threshold_count FROM CMS_PROD_THRESHOLD WHERE CPT_PROD_CODE=p_prod_code_in;
    if l_prod_threshold_count>0 then
         SELECT CPT_PROD_THRESHOLD INTO l_prod_threshold FROM CMS_PROD_THRESHOLD WHERE CPT_PROD_CODE=p_prod_code_in;
    else  
         SELECT CIP_PARAM_VALUE INTO l_prod_threshold FROM CMS_INST_PARAM WHERE CIP_PARAM_KEY='PRODUCT_THRESHOLD';
    END IF;

   EXCEPTION
   WHEN NO_DATA_FOUND
            then
            null;
            WHEN OTHERS
            THEN
               p_errmsg_out :=
                     'ERROR WHILE SELECTING DETAILS FROM  CMS_PROD_THRESHOLD:'
                  || SUBSTR (SQLERRM, 1, 300);
               RAISE EXP_REJECT_RECORD;

 END;

  BEGIN

  SELECT CPM_ASSO_CODE,CPM_INST_TYPE,CPM_CATG_CODE,CPM_PROD_DESC,
        CPM_SWITCH_PROD,CPM_VALIDITY_PERIOD,--CPM_VAR_FLAG,
        CPM_RULEGROUP_CODE,--CPM_PROFILE_CODE,
        CPM_MARC_PROD_FLAG,CPM_PRODMAST_PARAM1,--CPM_PROGRAM_ID,
        CPM_PRE_AUTH_EXP_DATE,--CPM_PROXY_LENGTH,
        CPM_ROUT_NUM,CPM_ISSU_BANK,
        CPM_ICA,CPM_OLS_EXPIRY_FLAG,CPM_STATEMENT_FOOTER,CPM_PASSIVE_FLAG,
        CPM_OLSRESP_FLAG,CPM_EMV_FLAG,CPM_INSTITUTION_ID,CPM_TRANSIT_NUMBER,
        CPM_RANDOM_PIN,CPM_PINCHANGE_FLAG,CPM_CTC_BIN,CPM_POA_PROD,CPM_ISSU_BANK_ADDR,CPM_ONUS_AUTH_EXPIRY
    INTO l_association_code,l_inst_type,l_catg_code,l_prod_desc,
         L_SWITCH_PROD,L_VALIDITY_PERIOD,--l_val_flag,
         L_RULEGRP_CODE,--L_PROF_CODE,
         L_MARCPROD_FLAG,L_PRODMAST_PARAM,--l_prog_id,
         L_PREAUTHEXP_PERIOD,--L_PROXY_LEN,
         l_rout_num,l_issu_bank,
         l_ica,l_olsexpry_flag,l_stmt_footer,l_passive_flag,
         l_olsresp_flag,l_emv_flag,l_inst_id,l_transit_num,
         l_random_pin,l_pinchange_flag,l_ctc_bin,l_poa_prod,l_issubank_addr,l_onusexpry_flag
    FROM CMS_PROD_MAST
    WHERE CPM_PROD_CODE=p_prod_code_in;

    EXCEPTION
     WHEN NO_DATA_FOUND
            THEN
               p_errmsg_out :=
                     'PRODUCT DETAILS NOT FOUND FROM CMS_PROD_MAST FOR PRODUCT CODE: '|| p_prod_code_in;
               RAISE EXP_REJECT_RECORD;
          WHEN OTHERS
         THEN
            p_errmsg_out := 'ERROR WHILE SELECTING PRODUCT DETAILS:'|| SUBSTR (SQLERRM, 1, 200);
            RAISE EXP_REJECT_RECORD;
  END;

 BEGIN

  INSERT INTO VMS_PROD_MAST_STAG(VPM_INST_CODE,VPM_PROD_CODE,VPM_ASSO_CODE,VPM_INST_TYPE,VPM_INTERCHANGE_CODE,
                                VPM_CATG_CODE,VPM_PROD_DESC,VPM_SWITCH_PROD,VPM_FROM_DATE,VPM_TO_DATE,VPM_INS_USER,
                                VPM_INS_DATE,VPM_LUPD_USER,VPM_LUPD_DATE,VPM_VALIDITY_PERIOD,--VPM_VAR_FLAG,
                                VPM_RULEGROUP_CODE,--VPM_PROFILE_CODE,
                                VPM_MARC_PROD_FLAG,VPM_PRODMAST_PARAM1,--VPM_PROGRAM_ID,
                                VPM_PRE_AUTH_EXP_DATE,--VPM_PROXY_LENGTH,
                                VPM_ROUT_NUM,
                                VPM_ISSU_BANK,VPM_ICA,VPM_OLS_EXPIRY_FLAG,VPM_STATEMENT_FOOTER,
                                VPM_PASSIVE_FLAG,VPM_OLSRESP_FLAG,VPM_EMV_FLAG,VPM_INSTITUTION_ID,VPM_TRANSIT_NUMBER,
                                VPM_RANDOM_PIN,VPM_PINCHANGE_FLAG,VPM_CTC_BIN,VPM_POA_PROD,VPM_ISSU_BANK_ADDR,VPM_ONUS_AUTH_EXPIRY)
                                VALUES(
                                p_instcode_in,p_prod_code_in,l_association_code,l_inst_type,l_interchange_code,
                                l_catg_code,l_prod_desc,l_switch_prod,sysdate,sysdate,p_ins_user_in,
                                SYSDATE,P_INS_USER_IN,SYSDATE,L_VALIDITY_PERIOD,--l_val_flag,
                                L_RULEGRP_CODE,--L_PROF_CODE,
                                L_MARCPROD_FLAG,L_PRODMAST_PARAM,--l_prog_id,
                                L_PREAUTHEXP_PERIOD,--L_PROXY_LEN,
                                l_rout_num,
                                l_issu_bank,l_ica,l_olsexpry_flag,l_stmt_footer,
                                l_passive_flag,l_olsresp_flag,l_emv_flag,l_inst_id,l_transit_num,
                                l_random_pin,l_pinchange_flag,l_ctc_bin,l_poa_prod,l_issubank_addr,l_onusexpry_flag);

   EXCEPTION
            WHEN OTHERS
            THEN
               p_errmsg_out :=
                     'ERROR WHILE INSERTING INTO VMS_PROD_MAST_STAG:'
                  || SUBSTR (SQLERRM, 1, 300);
               RAISE EXP_REJECT_RECORD;

 END;



 BEGIN

        INSERT INTO VMS_PROD_BIN_STAG(VPB_INST_CODE,
                    VPB_PROD_CODE,
                    VPB_INTERCHANGE_CODE,
                    VPB_INST_BIN,
                    VPB_ACTIVE_BIN,
                    VPB_INS_USER,
                    VPB_INS_DATE,
          VPB_LUPD_USER,
          VPB_LUPD_DATE
          )
                VALUES(p_instcode_in,
                         p_prod_code_in,
                         l_interchange_code,
                         L_BIN,
                         'Y',
                         p_ins_user_in,
               SYSDATE,
                         p_ins_user_in,
               SYSDATE);


    EXCEPTION
            WHEN OTHERS
            THEN
               p_errmsg_out :=
                     'ERROR WHILE INSERTING INTO VMS_PROD_BIN_STAG:'
                  || SUBSTR (SQLERRM, 1, 300);
               RAISE EXP_REJECT_RECORD;

    END;

  BEGIN

        INSERT INTO VMS_PROD_THRESHOLD_STAG(VPT_INST_CODE,
                                        VPT_PROD_CODE,
                                        VPT_PROD_THRESHOLD,
                                        VPT_INS_USER,
                                        VPT_INS_DATE,
                                        VPT_LUPD_USER,
                                        VPT_LUPD_DATE)
                                  VALUES(p_instcode_in,
                                         p_prod_code_in,
                                         l_prod_threshold,
                                         p_ins_user_in,
                                         SYSDATE,
                                         p_ins_user_in,
                                         SYSDATE);

    EXCEPTION
            WHEN OTHERS
            THEN
               p_errmsg_out :=
                     'ERROR WHILE INSERTING INTO VMS_PROD_THRESHOLD_STAG:'
                  || SUBSTR (SQLERRM, 1, 300);
               RAISE EXP_REJECT_RECORD;

    END;

  BEGIN

  SELECT
        CPP_EMAIL_ID,CPP_FROMEMAIL_ID,CPP_APP_NAME,CPP_APPNTY_TYPE,
        CPP_KYCVERIFY_FLAG,CPP_NETWORKACQID_FLAG,CPP_SHORT_CODE,CPP_CIP_INTVL,
        --CPP_RENEW_PRODCODE,CPP_RENEW_CARDTYPE,
        CPP_DUP_SSNCHK,CPP_DUP_TIMEPERIOD,
        CPP_DUP_TIMEUNT,CPP_GPRFLAG_ACHTXN,CPP_ACCTUNLOCK_DURATION,
        CPP_WRONG_LOGONCOUNT,CPP_PARTNER_ID,CPP_MMPOS_FEEPLAN,CPP_RENEWAL_PINMIGRATION,
        CPP_ACHBLCKEXPRY_PERIOD,CPP_FEDERALCHECK_FLAG,CPP_PREAUTH_PRODFLAG,CPP_AGGREGATOR_ID,
        CPP_TANDC_VERSION,CPP_B2BCARD_STAT,CPP_B2B_LMTPRFL,CPP_HOSTFLOOR_LIMIT,
        CPP_SPD_FLAG,CPP_UPC,CPP_B2BFLNAME_FLAG,CPP_CLAWBACK_DESC,CPP_PRODUCT_TYPE,cpp_webauthmapping_id,cpp_ivrauthmapping_id,CPP_SUBBIN_LENGTH

   INTO  l_email_id,l_fromemail_id,l_app_name,l_appnty_type,
         l_kycverify_flag,l_networkacq_flag,l_short_code,l_cip_intvl,
--         l_renewprod_code,l_renewcard_type,
         l_dup_ssnchk,l_dup_timeperiod,
         l_dup_timeout,l_gprflag_achtxn,l_acctunlock_duration,
         l_wrong_logoncnt,l_partner_id,l_mmpos_feeplan,l_renew_pinmigration,
         l_achblkexpry_period,l_federalchk_flag,l_preauth_prodflag,l_aggregator_id,
         l_tandc_version,l_b2bcard_stat,l_b2b_lmtprfl,l_hostflr_lmt,
         l_spd_flag,l_upc,l_b2bfname_flag,l_clawback_desc,l_product_type,l_webauthmapping_id,l_ivrauthmapping_id,l_subbin_length

    FROM CMS_PRODUCT_PARAM
    WHERE CPP_PROD_CODE=p_prod_code_in;

    EXCEPTION
     WHEN NO_DATA_FOUND
            THEN
               p_errmsg_out :=
                     'PRODUCT DETAILS NOT FOUND FROM CMS_PRODUCT_PARAM FOR PRODUCT CODE: '|| p_prod_code_in;
               RAISE EXP_REJECT_RECORD;
          WHEN OTHERS
         THEN
            p_errmsg_out := 'ERROR WHILE SELECTING PRODUCT DETAILS FROM CMS_PRODUCT_PARAM:'|| SUBSTR (SQLERRM, 1, 200);
            RAISE EXP_REJECT_RECORD;
  END;

  BEGIN

  INSERT INTO VMS_PRODUCT_PARAM_STAG(
                                VPP_INST_CODE,VPP_PROD_CODE,VPP_EMAIL_ID,VPP_INS_USER,
                                VPP_INS_DATE,VPP_LUPD_USER,VPP_LUPD_DATE,VPP_FROMEMAIL_ID,
                                VPP_APP_NAME,VPP_APPNTY_TYPE,VPP_KYCVERIFY_FLAG,VPP_NETWORKACQID_FLAG,
                                VPP_SHORT_CODE,VPP_CIP_INTVL,
                                --VPP_RENEW_PRODCODE,VPP_RENEW_CARDTYPE,
                                VPP_DUP_SSNCHK,VPP_DUP_TIMEPERIOD,VPP_DUP_TIMEUNT,
                                VPP_GPRFLAG_ACHTXN,VPP_ACCTUNLOCK_DURATION,VPP_WRONG_LOGONCOUNT,
                                VPP_PARTNER_ID,VPP_MMPOS_FEEPLAN,VPP_RENEWAL_PINMIGRATION,
                                VPP_ACHBLCKEXPRY_PERIOD,VPP_FEDERALCHECK_FLAG,VPP_PREAUTH_PRODFLAG,VPP_AGGREGATOR_ID,
                                VPP_TANDC_VERSION,VPP_B2BCARD_STAT,VPP_B2B_LMTPRFL,VPP_HOSTFLOOR_LIMIT,
                                VPP_SPD_FLAG,VPP_UPC,VPP_B2BFLNAME_FLAG,VPP_CLAWBACK_DESC,VPP_PRODUCT_TYPE,VPP_WEBAUTHMAPPING_ID,VPP_IVRAUTHMAPPING_ID,VPP_SUBBIN_LENGTH

                                )
                                VALUES(
                                p_instcode_in,p_prod_code_in,l_email_id,p_ins_user_in,
                                sysdate,p_ins_user_in,sysdate,l_fromemail_id,
                                l_app_name,l_appnty_type,l_kycverify_flag,l_networkacq_flag,
                                l_short_code,l_cip_intvl,
                                --l_renewprod_code,l_renewcard_type,
                                l_dup_ssnchk,l_dup_timeperiod,l_dup_timeout,
                                l_gprflag_achtxn,l_acctunlock_duration,l_wrong_logoncnt,
                                l_partner_id,l_mmpos_feeplan,l_renew_pinmigration,
                                l_achblkexpry_period,l_federalchk_flag,l_preauth_prodflag,l_aggregator_id,
                                l_tandc_version,l_b2bcard_stat,l_b2b_lmtprfl,l_hostflr_lmt,
                                l_spd_flag,l_upc,l_b2bfname_flag,l_clawback_desc,l_product_type,l_webauthmapping_id,l_ivrauthmapping_id,l_subbin_length

                                );

   EXCEPTION
            WHEN OTHERS
            THEN
               p_errmsg_out :=
                     'ERROR WHILE INSERTING INTO VMS_PRODUCT_PARAM_STAG:'
                  || SUBSTR (SQLERRM, 1, 300);
               RAISE EXP_REJECT_RECORD;

 END;

BEGIN
            FOR l_row_indx IN PRODUCT_CARDPACK(p_prod_code_in)
            LOOP
            INSERT INTO VMS_PROD_CARDPACK_STAG(
                    VPC_INST_CODE,
                    VPC_PROD_CODE,
                    VPC_CARD_DETAILS,
                    VPC_PRINT_VENDOR,
                    VPC_INST_REPLACEMENT_FLAG,
                    VPC_CARD_ID)
                    VALUES(
                    p_instcode_in,
                    p_prod_code_in,
                    l_row_indx.CPC_CARD_DETAILS,
                    l_row_indx.CPC_PRINT_VENDOR,
                    L_ROW_INDX.CPC_INST_REPLACEMENT_FLAG,
                    l_row_indx.CPC_CARD_ID);                    
            END LOOP;
			
            INSERT INTO VMS_PACKAGEID_MAST_STAG(VPM_PACKAGE_ID,
            VPM_PACKAGE_DESC,VPM_REPLACEMENT_PACKAGE_ID,VPM_VENDOR_ID,VPM_SHIP_METHODS,VPM_INS_DATE,
            VPM_INS_USER,VPM_LUPD_DATE,VPM_LUPD_USER,VPM_EXP_REPLACESHIPMETHOD,VPM_REPLACE_SHIPMETHOD)
            (SELECT VPM_PACKAGE_ID,VPM_PACKAGE_DESC,VPM_REPLACEMENT_PACKAGE_ID,VPM_VENDOR_ID,VPM_SHIP_METHODS,
            VPM_INS_DATE,VPM_INS_USER,VPM_LUPD_DATE,VPM_LUPD_USER,VPM_EXP_REPLACESHIPMETHOD,VPM_REPLACE_SHIPMETHOD 
            FROM VMS_PACKAGEID_MAST WHERE VPM_PACKAGE_ID IN (SELECT VPC_CARD_DETAILS FROM VMS_PROD_CARDPACK_STAG));
            
            INSERT INTO VMS_PACKAGEID_DETL_STAG(VPD_PACKAGE_ID,VPD_FIELD_KEY,VPD_FIELD_VALUE,VPD_INS_DATE,VPD_INS_USER,VPD_LUPD_DATE,VPD_LUPD_USER)
            (SELECT VPD_PACKAGE_ID,VPD_FIELD_KEY,VPD_FIELD_VALUE,VPD_INS_DATE,VPD_INS_USER,VPD_LUPD_DATE,VPD_LUPD_USER
            FROM VMS_PACKAGEID_DETL WHERE VPD_PACKAGE_ID IN (SELECT VPC_CARD_DETAILS FROM VMS_PROD_CARDPACK_STAG));
			
            EXCEPTION
            WHEN OTHERS
            THEN
              p_errmsg_out  :=
                     'ERROR WHILE INSERTING INTO CMS_PROD_CARDPACK:'
                  || SUBSTR (SQLERRM, 1, 300);
               RAISE EXP_REJECT_RECORD;

 END;
  BEGIN
            FOR l_row_indx IN PRODNETWORKID_MAPPING(p_prod_code_in)
            LOOP
            INSERT INTO VMS_PRODNETWORKID_MAPPING_STAG(
                    VPM_INST_CODE,
                    VPM_PROD_CODE,
                    VPM_NETWORK_ID,
                    VPM_INS_USER_ID,
                    VPM_INS_DATE,
                    VPM_LUPD_USER,
                    VPM_LUPD_DATE)
                    VALUES(
                    p_instcode_in,
                    p_prod_code_in,
                    l_row_indx.CPM_NETWORK_ID,
                    p_ins_user_in,
                    SYSDATE,
                    p_ins_user_in,
                    SYSDATE);

            END LOOP;
            EXCEPTION
            WHEN OTHERS
            THEN
               p_errmsg_out :=
                     'ERROR WHILE INSERTING INTO VMS_PRODNETWORKID_MAPPING_STAG:'
                  || SUBSTR (SQLERRM, 1, 300);
               RAISE EXP_REJECT_RECORD;

 END;

 BEGIN
            FOR l_row_indx IN SCORECARD_PRODMAPPING(p_prod_code_in)
            LOOP

            INSERT INTO VMS_SCORECARD_PRODMAPPING_STAG(
                    VSP_INST_CODE,
                    VSP_SCORECARD_ID,
                    VSP_PROD_CODE,
                    VSP_DELIVERY_CHANNEL,
                    VSP_CIPCARD_STAT,
                    VSP_AVQ_FLAG,
                    VSP_INS_USER,
                    VSP_INS_DATE,
                    VSP_LUPD_USER,
                    VSP_LUPD_DATE)
                    VALUES(
                    p_instcode_in,
                    l_row_indx.CSP_SCORECARD_ID,
                    p_prod_code_in,
                    l_row_indx.CSP_DELIVERY_CHANNEL,
                    l_row_indx.CSP_CIPCARD_STAT,
                    l_row_indx.CSP_AVQ_FLAG,
                    p_ins_user_in,
                    SYSDATE,
                    p_ins_user_in,
                    SYSDATE);

            END LOOP;
            EXCEPTION
            WHEN OTHERS
            THEN
               p_errmsg_out :=
                     'ERROR WHILE INSERTING INTO VMS_SCORECARD_PRODMAPPING_STAG:'
                  || SUBSTR (SQLERRM, 1, 300);
               RAISE EXP_REJECT_RECORD;

 END;

 EXCEPTION
  WHEN EXP_REJECT_RECORD THEN
  ROLLBACK;-- TO l_savepoint;
  WHEN OTHERS THEN
  ROLLBACK;-- TO l_savepoint;
  p_errmsg_out := 'Exception while copying PRODUCT_PARAMETER_TEMPCOPY:' ||p_errmsg_out || SUBSTR(SQLERRM, 1, 200);


END;

--end product parameter copy

--start product category copy

PROCEDURE  PRODCATG_PARAMETER_TEMPCOPY (
   p_instcode_in            IN       NUMBER,
   P_INS_USER_IN            IN       NUMBER,
   p_prod_code_in           IN       VARCHAR2,
   P_PROD_CATG_IN           IN       VARCHAR2,
   P_COPY_OPTION            IN       VARCHAR2,
   P_ENV_OPTION            IN       VARCHAR2,
   p_errmsg_out             OUT      VARCHAR2
)
IS

/**********************************************************************************************


  * Created by                  : MageshKumar S.
  * Created Date                : 01-MAR-16
  * Created For                 : HOSTCC-57
  * Created reason              : PRODUCT CATEGORYS COPY PROGRAM
  * Reviewer                    : SARAVANAKUMAR/SPANKAJ
  * Build Number                : VMSGPRHOSTCSD4.0_B0001

  * Created by                  : Siva Kumar M.
  * Created Date                : 25-May-16
  * Created For                 : MVHOST-1346
  * Created reason              : Product Category Configuration for Starter Card
  * Reviewer                    : SARAVANAKUMAR/SPANKAJ
  * Build Number                : VMSGPRHOSTCSD4.1_B0001

  * Modified by      : MageshKumar S
   * Modified For     : CLVMS-124
   * Modified Date    : 08-JUNE-2016
   * Reviewer         : Saravanan/Spankaj
   * Build Number     : VMSGPRHOSTCSD4.2_B0001

    * Modified by      : Siva Kumar M
     * Modified For     : FSS-4423
     * Modified Date    : 25-May-2016
     * Modified reason  : Changes for tokenization
     * Reviewer         : Saravankumar/Spankaj
     * Build Number     : VMSGPRHOST4.4_B0001

    * Modified by      : Siva Kumar M
     * Modified For     : FSS-4423
     * Modified Date    : 07-July-2016
     * Modified reason  : Tokenization Changes
     * Reviewer         : Saravankumar/Spankaj
     * Build Number     : VMSGPRHOST4.5_B0002

     * Modified by      : MageshKumar S
     * Modified For     : FSS-4782
     * Modified Date    : 30-SEP-2016
     * Reviewer         : Saravanan/Spankaj
     * Build Number     : VMSGPRHOSTCSD4.2.5_B0001

      * Modified by      : Veneetha C
     * Modified For     : FSS-4647
     * Modified Date    : 09-MAR-2017
     * Reviewer         : Saravanan/Spankaj
     * Build Number     : VMSGPRHOSTCSD17.03_B0001

     * Modified by      : Sreeja T
     * Modified For     : FSS-5323
     * Modified Date    : 10-nov-2017
     * Modified reason  : Recurring Transaction Flag
     * Reviewer         : Saravankumar/Spankaj
     * Build Number     : VMSGPRHOSTCSD17.11_B0001
     
     * Modified by      : Mageshkumar 
     * Modified For     : VMS-180
     * Modified Date    : 23-JAN-2018
     * Reviewer         : Saravankumar
     * Build Number     : VMSGPRHOSTCSD18.01
     
     * Modified by      : Siva Kumar M
     * Modified For     : VMS-354
     * Modified Date    : 02-July-2018
     * Reviewer         : Saravankumar
     * Build Number     : R03
     
   * Modified by      : Narayana
   * Modified For     : VMS-1048 (VMS Host Configure new product in Dev A to replicate to other lower environments)
   * Modified Date    : 13-AUG-2019
   * Reviewer         : Saravanakumar
   * Build Number     : R19_B0002  
   
   * Modified by      : Ubaidur Rahman.H
   * Modified For     : VMS-1127.
   * Modified Date    : 09-OCT-2019
   * Reviewer         : Saravanakumar
   * Build Number     : R20_B0003

**************************************************************************************************/


--l_savepoint           NUMBER                              DEFAULT 1;
EXP_REJECT_RECORD EXCEPTION;
l_card_type            cms_prod_cattype.CPC_CARD_TYPE%type;
l_cardtype_desc        cms_prod_cattype.CPC_CARDTYPE_DESC%type;
l_vendor               cms_prod_cattype.CPC_VENDOR%type;
l_stock                cms_prod_cattype.CPC_STOCK%type;
l_cardtype_sname       cms_prod_cattype.CPC_CARDTYPE_SNAME%type;
l_prod_prefix          cms_prod_cattype.CPC_PROD_PREFIX%type;
l_rulegroup_code       cms_prod_cattype.CPC_RULEGROUP_CODE%type;
l_profile_code         cms_prod_cattype.CPC_PROFILE_CODE%type;
l_prod_id              cms_prod_cattype.CPC_PROD_ID%type;
l_package_id           cms_prod_cattype.CPC_PACKAGE_ID%type;
l_achtxn_flg           cms_prod_cattype.CPC_ACHTXN_FLG%type;
l_achtxn_cnt           cms_prod_cattype.CPC_ACHTXN_CNT%type;
l_achtxn_amt           cms_prod_cattype.CPC_ACHTXN_AMT%type;
l_achtxn_deposit       cms_prod_cattype.CPC_ACHTXN_DEPOSIT%type;
l_sec_code             cms_prod_cattype.CPC_SEC_CODE%type;
l_min_agekyc           cms_prod_cattype.CPC_MIN_AGE_KYC%type;
l_passive_time         cms_prod_cattype.CPC_PASSIVE_TIME%type;
l_achtxn_daycnt        cms_prod_cattype.CPC_ACHTXN_DAYCNT%type;
l_achtxn_dayamt        cms_prod_cattype.CPC_ACHTXN_DAYMAXAMT%type;
l_achtxn_weekcnt       cms_prod_cattype.CPC_ACHTXN_WEEKCNT%type;
l_achtxn_weekmaxamt    cms_prod_cattype.CPC_ACHTXN_WEEKMAXAMT%type;
l_achtxn_moncnt        cms_prod_cattype.CPC_ACHTXN_MONCNT%type;
l_achtxn_monmaxamt     cms_prod_cattype.CPC_ACHTXN_MONMAXAMT%type;
l_achtxn_maxtranamt    cms_prod_cattype.CPC_ACHTXN_MAXTRANAMT%type;
l_achtxn_mintranamt    cms_prod_cattype.CPC_ACHTXN_MINTRANAMT%type;
l_starter_card         cms_prod_cattype.CPC_STARTER_CARD%type;
l_starter_minload      cms_prod_cattype.CPC_STARTER_MINLOAD%type;
l_starter_maxload      cms_prod_cattype.CPC_STARTER_MAXLOAD%type;
l_startergpr_cardtype  cms_prod_cattype.CPC_STARTERGPR_CRDTYPE%type;
l_strgpr_issue         cms_prod_cattype.CPC_STARTERGPR_ISSUE%type;
l_acctprod_prefix      cms_prod_cattype.CPC_ACCT_PROD_PREFIX%type;
l_serl_flag            cms_prod_cattype.CPC_SERL_FLAG%type;
l_del_met              cms_prod_cattype.CPC_DEL_MET%type;
l_achmin_iniload       cms_prod_cattype.CPC_ACHMIN_INITIAL_LOAD%type;
l_url                  cms_prod_cattype.CPC_URL%type;
l_pin_app              cms_prod_cattype.CPC_PIN_APPLICABLE%type;
l_dfltpin_flag         cms_prod_cattype.CPC_DFLTPIN_FLAG%type;
l_locchk_flag          cms_prod_cattype.CPC_LOCCHECK_FLAG%type;
l_scorecard_id         cms_prod_cattype.CPC_SCORECARD_ID%type;
l_ach_loadamtchk       cms_prod_cattype.CPC_ACH_LOADAMNT_CHECK%type;
l_crdexp_pend          cms_prod_cattype.CPC_CRDEXP_PENDING%type;
l_repl_period          cms_prod_cattype.CPC_REPL_PERIOD%type;
l_invchk_flag          cms_prod_cattype.CPC_INVCHECK_FLAG%type;
l_sec_code1            cms_prod_catsec.cpc_sec_code%type;
l_tran_code            cms_prod_catsec.cpc_tran_code%type;
l_strcrd_dispname      CMS_PROD_CATTYPE.CPC_STARTERCARD_DISPNAME%type;
l_strrepl_option       CMS_PROD_CATTYPE.CPC_STARTER_REPLACEMENT%type;
l_repl_prodcatg        CMS_PROD_CATTYPE.CPC_REPLACEMENT_CATTYPE%type;
l_token_eligible       CMS_PROD_CATTYPE.CPC_TOKEN_ELIGIBILITY%TYPE;
l_token_prov_retrymax  cms_prod_cattype.CPC_TOKEN_PROVISION_RETRY_MAX%TYPE;
l_tokenretain_period   cms_prod_cattype.CPC_TOKEN_RETAIN_PERIOD%TYPE;
l_TOKEN_CUSTUPDDURATION   cms_prod_cattype.CPC_TOKEN_CUST_UPD_DURATION%TYPE;
--l_token_custupddur_frny   cms_prod_cattype.CPC_TOKEN_CUST_UPD_FREQUENCY%TYPE;
l_default_pin_selected CMS_PROD_CATTYPE.CPC_DEFAULT_PIN_OPTION%type;
l_exp_date_exemption cms_prod_cattype.cpc_exp_date_exemption%type;
l_redemptiondelay_flag  cms_prod_cattype.CPC_REDEMPTION_DELAY_FLAG%type;--added for FSS-4647
l_CVVPLUS_ELIGIBILITY   cms_prod_cattype.CPC_CVVPLUS_ELIGIBILITY%type;--added for cvvplus
l_CVVPlus_Short_Name    cms_prod_cattype.CPC_CVVPlus_Short_Name%type;--added for cvvplus
l_SWEEP_PERIOD          cms_prod_cattype.CPC_ADDL_SWEEP_PERIOD%type;--added for FSS-4619 SWEEP
l_SWEEP_FLAG            CMS_PROD_CATTYPE.CPC_SWEEP_FLAG%TYPE;--ADDED FOR FSS-4619 SWEEP
l_b2b_Flag              CMS_PROD_CATTYPE.CPC_B2B_FLAG%TYPE;--ADDED FOR B2b Config
l_b2b_cardstat          CMS_prod_cattype.CPC_B2BCARD_STAT%TYPE;--ADDED FOR B2B CONFIG
l_b2b_actCode           CMS_prod_cattype.CPC_B2B_ACTIVATION_CODE%TYPE;--ADDED FOR B2B CONFIG
l_b2b_lmtprof           CMS_prod_cattype.CPC_B2B_LMTPRFL%TYPE;--ADDED FOR B2B CONFIG
l_b2b_regmatch          CMS_prod_cattype.CPC_B2BFLNAME_FLAG%TYPE;--ADDED FOR B2B CONFIG
l_InactivetoknretainPer  CMS_prod_cattype.CPC_INACTIVETOKEN_RETAINPERIOD%TYPE;--ADDED FOR master card
l_kyc_flag               CMS_prod_cattype.CPC_KYC_FLAG%TYPE;
l_cvv2_verification_flag    CMS_prod_cattype.CPC_CVV2_VERIFICATION_FLAG%TYPE;
l_expiry_date_check_flag      CMS_prod_cattype.CPC_EXPIRY_DATE_CHECK_FLAG%TYPE;
l_acct_balance_check_flag     CMS_prod_cattype.CPC_ACCT_BALANCE_CHECK_FLAG%TYPE;
l_replacement_provision_flag   CMS_prod_cattype.CPC_REPLACEMENT_PROVISION_FLAG%TYPE;
l_acct_balance_check_type   CMS_prod_cattype.CPC_ACCT_BAL_CHECK_TYPE%TYPE;
l_acct_balance_check_value   CMS_prod_cattype.CPC_ACCT_BAL_CHECK_VALUE%TYPE;
l_issu_prodconfig_id      CMS_prod_cattype.CPC_ISSU_PRODCONFIG_ID%TYPE;
l_consumed_flag           CMS_prod_cattype.CPC_CONSUMED_FLAG%TYPE;
l_consumed_card_stat      CMS_prod_cattype.CPC_CONSUMED_CARD_STAT%TYPE;
l_renew_replace_option    CMS_prod_cattype.CPC_RENEW_REPLACE_OPTION%TYPE;
l_renew_replace_prodcode    CMS_prod_cattype.CPC_RENEW_REPLACE_PRODCODE%TYPE;
l_renew_replace_cardtype    CMS_prod_cattype.CPC_RENEW_REPLACE_CARDTYPE%TYPE;

l_REGISTRATION_TYPE         CMS_PROD_CATTYPE.CPC_USER_IDENTIFY_TYPE%TYPE;

l_RELOADABLE_FLAG           CMS_PROD_CATTYPE.CPC_RELOADABLE_FLAG%TYPE;
l_PROD_SUFFIX               CMS_PROD_CATTYPE.CPC_PROD_SUFFIX%TYPE;
l_START_CARD_NO              CMS_PROD_CATTYPE.CPC_START_CARD_NO%TYPE;
L_END_CARD_NO               CMS_PROD_CATTYPE.CPC_END_CARD_NO%TYPE;
l_CCF_FORMAT_VERSION        CMS_PROD_CATTYPE.CPC_CCF_FORMAT_VERSION %type;
l_DCMS_ID                   CMS_PROD_CATTYPE.CPC_DCMS_ID %TYPE;
l_PRODUCT_UPC               CMS_PROD_CATTYPE.CPC_PRODUCT_UPC %TYPE;
l_PACKING_UPC               CMS_PROD_CATTYPE.CPC_PACKING_UPC %TYPE;
l_PROD_DENOM                CMS_PROD_CATTYPE.CPC_PROD_DENOM %TYPE;
l_PDENOM_MIN                CMS_PROD_CATTYPE.CPC_PDENOM_MIN %TYPE;
l_PDENOM_MAX                CMS_PROD_CATTYPE.CPC_PDENOM_MAX %TYPE;
l_PDENOM_FIX                CMS_PROD_CATTYPE.CPC_PDENOM_FIX %TYPE;
l_ISSU_BANK                 CMS_PROD_CATTYPE.CPC_ISSU_BANK %TYPE;
l_ICA	                      CMS_PROD_CATTYPE.CPC_ICA	 %TYPE;
l_ISSU_BANK_ADDR            CMS_PROD_CATTYPE.CPC_ISSU_BANK_ADDR %TYPE;
l_CARDPROD_ACCEPT           CMS_PROD_CATTYPE.CPC_CARDPROD_ACCEPT %TYPE;
l_STATE_RESTRICT             CMS_PROD_CATTYPE.CPC_STATE_RESTRICT %TYPE;
l_PIF_SIA_CASE               CMS_PROD_CATTYPE.CPC_PIF_SIA_CASE %TYPE;
L_DISABLE_REPL_FLAG          CMS_PROD_CATTYPE.CPC_DISABLE_REPL_FLAG %TYPE;
l_DISABLE_REPL_EXPRYDAYS     CMS_PROD_CATTYPE.CPC_DISABLE_REPL_EXPRYDAYS %TYPE;
l_DISABLE_REPL_MINBAL        CMS_PROD_CATTYPE.CPC_DISABLE_REPL_MINBAL %TYPE;
l_PAN_INVENTORY_FLAG         CMS_PROD_CATTYPE.CPC_PAN_INVENTORY_FLAG %TYPE;
l_ACCTUNLOCK_DURATION       CMS_PROD_CATTYPE.CPC_ACCTUNLOCK_DURATION %TYPE;
l_WRONG_LOGONCOUNT           CMS_PROD_CATTYPE.CPC_WRONG_LOGONCOUNT %TYPE;
l_ACHBLCKEXPRY_PERIOD        CMS_PROD_CATTYPE.CPC_ACHBLCKEXPRY_PERIOD %TYPE;
l_RENEWAL_PINMIGRATION       CMS_PROD_CATTYPE.CPC_RENEWAL_PINMIGRATION %TYPE;
l_FEDERALCHECK_FLAG          CMS_PROD_CATTYPE.CPC_FEDERALCHECK_FLAG %TYPE;
l_TANDC_VERSION              CMS_PROD_CATTYPE.CPC_TANDC_VERSION %TYPE;
l_CLAWBACK_DESC              CMS_PROD_CATTYPE.CPC_CLAWBACK_DESC %TYPE;
l_WEBAUTHMAPPING_ID          CMS_PROD_CATTYPE.CPC_WEBAUTHMAPPING_ID %TYPE;
l_IVRAUTHMAPPING_ID          CMS_PROD_CATTYPE.CPC_IVRAUTHMAPPING_ID %TYPE;
l_EMAIL_ID                   CMS_PROD_CATTYPE.CPC_EMAIL_ID %TYPE;
l_FROMEMAIL_ID               CMS_PROD_CATTYPE.CPC_FROMEMAIL_ID %TYPE;
l_APP_NAME                   CMS_PROD_CATTYPE.CPC_APP_NAME %TYPE;
l_APPNTY_TYPE                CMS_PROD_CATTYPE.CPC_APPNTY_TYPE %TYPE;
l_KYCVERIFY_FLAG             CMS_PROD_CATTYPE.CPC_KYCVERIFY_FLAG %TYPE;
l_NETWORKACQID_FLAG          CMS_PROD_CATTYPE.CPC_NETWORKACQID_FLAG %TYPE;
l_SHORT_CODE                 CMS_PROD_CATTYPE.CPC_SHORT_CODE %TYPE;
l_CIP_INTVL                  CMS_PROD_CATTYPE.CPC_CIP_INTVL %TYPE;
l_DUP_SSNCHK                 CMS_PROD_CATTYPE.CPC_DUP_SSNCHK %TYPE;
l_PINCHANGE_FLAG             CMS_PROD_CATTYPE.CPC_PINCHANGE_FLAG %TYPE;
l_OLSRESP_FLAG               CMS_PROD_CATTYPE.CPC_OLSRESP_FLAG %TYPE;
l_EMV_FLAG                   CMS_PROD_CATTYPE.CPC_EMV_FLAG %TYPE;
l_INSTITUTION_ID             CMS_PROD_CATTYPE.CPC_INSTITUTION_ID %TYPE;
l_TRANSIT_NUMBER             CMS_PROD_CATTYPE.CPC_TRANSIT_NUMBER %TYPE;
l_RANDOM_PIN                 CMS_PROD_CATTYPE.CPC_RANDOM_PIN %TYPE;
l_ONUS_AUTH_EXPIRY           CMS_PROD_CATTYPE.CPC_ONUS_AUTH_EXPIRY %TYPE;
l_FROM_DATE                  CMS_PROD_CATTYPE.CPC_FROM_DATE %TYPE;
l_POA_PROD                   CMS_PROD_CATTYPE.CPC_POA_PROD %TYPE;
l_ROUT_NUM                   CMS_PROD_CATTYPE.CPC_ROUT_NUM %TYPE;
l_OLS_EXPIRY_FLAG            CMS_PROD_CATTYPE.CPC_OLS_EXPIRY_FLAG %TYPE;
l_STATEMENT_FOOTER           CMS_PROD_CATTYPE.CPC_STATEMENT_FOOTER %TYPE;
l_DUP_TIMEPERIOD             CMS_PROD_CATTYPE.CPC_DUP_TIMEPERIOD %TYPE;
l_DUP_TIMEUNT                CMS_PROD_CATTYPE.CPC_DUP_TIMEUNT %TYPE;
l_GPRFLAG_ACHTXN             CMS_PROD_CATTYPE.CPC_GPRFLAG_ACHTXN %TYPE;
L_DISABLE_REPL_MESSAGE       CMS_PROD_CATTYPE.CPC_DISABLE_REPL_MESSAGE %TYPE;
L_PRODCAT_THRESHOLD1          VMS_PRODCAT_THRESHOLD.VPT_PROD_THRESHOLD%TYPE;
l_CCF_SERIAL_FLAG            cms_prod_cattype.CPC_CCF_SERIAL_FLAG%type;
l_network_id               VMS_PRODCAT_NETWORKID_MAPPING.VPN_NETWORK_ID%type;
l_delivery_channel         VMS_SCORECARD_PRODCAT_MAPPING.VSP_DELIVERY_CHANNEL%type;
--l_scorecard_id            VMS_SCORECARD_PRODCAT_MAPPING.VSP_SCORECARD_ID%type;
l_cipcard_stat           VMS_SCORECARD_PRODCAT_MAPPING.VSP_CIPCARD_STAT%type;
l_avq_flag            VMS_SCORECARD_PRODCAT_MAPPING.VSP_AVQ_FLAG%type;
l_pden_val           VMS_PRODCAT_DENO_MAST. VPD_PDEN_VAL%type;
L_DENO_STATUS       VMS_PRODCAT_DENO_MAST.VPD_DENO_STATUS%TYPE;
L_PROG_ID              CMS_PROD_CATTYPE.CPC_PROGRAM_ID%TYPE;
L_PROXY_LEN            CMS_PROD_CATTYPE.CPC_PROXY_LENGTH%TYPE;
L_ISCHCEK_REQ          CMS_PROD_CATTYPE.CPC_CHECK_DIGIT_REQ%type;
L_ISPRG_ID_REQ          CMS_PROD_CATTYPE.CPC_PROGRAMID_REQ%TYPE;
L_DEF_COND_APPR_FLAG CMS_PROD_CATTYPE.CPC_DEF_COND_APPR%TYPE;
L_CUSTOMER_CARE_NUM  CMS_PROD_CATTYPE.CPC_CUSTOMER_CARE_NUM%TYPE;
l_UPGRADE_ELIGIBLE_FLAG CMS_PROD_CATTYPE.CPC_UPGRADE_ELIGIBLE_FLAG%TYPE;
l_CCF_3DIGCSCREQ    CMS_PROD_CATTYPE.CPC_CCF_3DIGCSCREQ%TYPE;
l_DEFAULT_PARTIAL_INDR    CMS_PROD_CATTYPE.CPC_DEFAULT_PARTIAL_INDR%TYPE;
l_SERIALNO_FILEPATH  CMS_PROD_CATTYPE.CPC_SERIALNO_FILEPATH%TYPE;
l_RETAIL_ACTIVATION  CMS_PROD_CATTYPE.CPC_RETAIL_ACTIVATION%TYPE;
l_AVS_REQUIRED       CMS_PROD_CATTYPE.CPC_ADDR_VERIFICATION_CHECK%TYPE;
L_ADDR_VERIF_RESP    CMS_PROD_CATTYPE.CPC_ADDR_VERIFICATION_RESPONSE%TYPE;
l_RECURRING_TRAN_FLAG  CMS_PROD_CATTYPE.CPC_RECURRING_TRAN_FLAG%TYPE;
L_International_Tran   Cms_Prod_Cattype.Cpc_International_Check%Type;
L_Emv_Fallback         Cms_Prod_Cattype.Cpc_Emv_Fallback%Type;
L_Fund_Mcc         Cms_Prod_Cattype.Cpc_Fund_Mcc%Type;
L_Settl_Mcc         Cms_Prod_Cattype.Cpc_Settl_Mcc%Type;
L_Badcrd_Flag       Cms_Prod_Cattype.Cpc_Badcredit_Flag%Type;
L_Badcr_Transgrp    Cms_Prod_Cattype.Cpc_Badcredit_Transgrpid%Type;
l_encrypt_enable    cms_prod_Cattype.cpc_encrypt_enable%type;
l_alert_card_stat   cms_prod_Cattype.CPC_ALERT_CARD_STAT%type;
l_alert_card_amnt   cms_prod_Cattype.CPC_ALERT_CARD_AMOUNT%type;
l_alert_card_days   cms_prod_Cattype.CPC_ALERT_CARD_DURATION%type;
l_src_app           cms_prod_Cattype.CPC_SRC_APP%type;
L_Src_App_Flag          Cms_Prod_Cattype.Cpc_Src_App_Flag%Type;
L_Valins_Act_Flag       Cms_Prod_Cattype.Cpc_Valins_Act_Flag %Type;
L_Deactivation_Closed   Cms_Prod_Cattype.Cpc_Deactivation_Closed % Type;
l_DOUBLEOPTINNTY_TYPE  Cms_Prod_Cattype.CPC_DOUBLEOPTINNTY_TYPE  % Type;
l_PRODUCT_FUNDING      Cms_Prod_Cattype.CPC_PRODUCT_FUNDING  % Type;
l_FUND_AMOUNT          Cms_Prod_Cattype.CPC_FUND_AMOUNT  % Type;
L_Instore_Replacement  Cms_Prod_Cattype.Cpc_Instore_Replacement % Type;
l_Packageid_Check  cms_prod_cattype.Cpc_Packageid_Check % Type;
l_mallid_check    cms_prod_cattype.CPC_MALLID_CHECK % Type;
l_malllocation_check   cms_prod_cattype.CPC_MALLLOCATION_CHECK % Type;
l_OFAC_CHECK        cms_prod_cattype.cpc_OFAC_CHECK % Type;
l_PARTNER_ID        cms_prod_cattype.CPC_PARTNER_ID % Type;
l_DOB_MANDATORY_FLAG  CMS_PROD_CATTYPE.CPC_DOB_MANDATORY%TYPE;
L_STANDINGAUTH_TRAN_FLAG CMS_PROD_CATTYPE.CPC_STNGAUTH_FLAG%TYPE;
L_BYPASS_INITIAL_LOADCHK CMS_PROD_CATTYPE.CPC_BYPASS_LOADCHECK%TYPE;
REF_CUR_PRODCATG_CARDID  SYS_REFCURSOR;
REF_CUR_PRODCATG SYS_REFCURSOR;
REF_CUR_PRODCATG_SECCODE SYS_REFCURSOR;
ref_cur_prodcatg_threshold sys_refcursor;
ref_cur_prodcat_netmap sys_refcursor;
ref_cur_scorecd_prodcat_map sys_refcursor;
ref_cur_prodcat_deno sys_refcursor;
l_card_id              VMS_PRODCAT_CARDPACK_STAG.VPC_CARD_ID%type;
l_defcard_id           VMS_PRODCAT_CARDPACK_STAG.VPC_CARD_ID%type;
l_issuer_guid          VMS_PRODCAT_CARDPACK_STAG.VPC_ISSUER_GUID%type;
l_art_guid             VMS_PRODCAT_CARDPACK_STAG.VPC_ART_GUID%type;
l_tc_guid              VMS_PRODCAT_CARDPACK_STAG.VPC_TC_GUID%type;
L_prdcat_card_id    	VMS_PRODCAT_CARDPACK_STAG.VPC_CARD_ID%type;
L_ISSUBANK_ID			CMS_PROD_CATTYPE.CPC_ISSUBANK_ID%type;
L_EVENT_NOTIFICATION	CMS_PROD_CATTYPE.CPC_EVENT_NOTIFICATION%type;
L_PARTNER_NAME			CMS_PROD_CATTYPE.CPC_PARTNER_NAME%type;
L_PIN_RESET_OPTION		CMS_PROD_CATTYPE.CPC_PIN_RESET_OPTION%type;
L_PRODUCT_PORTFOLIO        CMS_PROD_CATTYPE.CPC_PRODUCT_PORTFOLIO%type;
BEGIN

 p_errmsg_out  := 'OK';
 --SAVEPOINT l_savepoint;

  BEGIN

   OPEN ref_cur_prodcatg FOR
   'SELECT CPC_CARD_TYPE,CPC_CARDTYPE_DESC,CPC_VENDOR,CPC_STOCK,
    CPC_CARDTYPE_SNAME,CPC_PROD_PREFIX,CPC_RULEGROUP_CODE,CPC_PROFILE_CODE,
    CPC_PROD_ID,CPC_PACKAGE_ID,CPC_ACHTXN_FLG,CPC_ACHTXN_CNT,
    CPC_ACHTXN_AMT,CPC_ACHTXN_DEPOSIT,CPC_SEC_CODE,CPC_MIN_AGE_KYC,
    CPC_PASSIVE_TIME,CPC_ACHTXN_DAYCNT,CPC_ACHTXN_DAYMAXAMT,CPC_ACHTXN_WEEKCNT,
    CPC_ACHTXN_WEEKMAXAMT,CPC_ACHTXN_MONCNT,CPC_ACHTXN_MONMAXAMT,CPC_ACHTXN_MAXTRANAMT,
    CPC_ACHTXN_MINTRANAMT,CPC_STARTER_CARD,CPC_STARTER_MINLOAD,CPC_STARTER_MAXLOAD,
    CPC_STARTERGPR_CRDTYPE,CPC_STARTERGPR_ISSUE,CPC_ACCT_PROD_PREFIX,CPC_SERL_FLAG,
    CPC_DEL_MET,CPC_ACHMIN_INITIAL_LOAD,CPC_URL,CPC_PIN_APPLICABLE,
    CPC_DFLTPIN_FLAG,CPC_LOCCHECK_FLAG,CPC_SCORECARD_ID,CPC_ACH_LOADAMNT_CHECK,
    CPC_CRDEXP_PENDING,CPC_REPL_PERIOD,CPC_INVCHECK_FLAG,CPC_STARTERCARD_DISPNAME,CPC_STARTER_REPLACEMENT,CPC_REPLACEMENT_CATTYPE,CPC_TOKEN_ELIGIBILITY,CPC_TOKEN_PROVISION_RETRY_MAX,CPC_TOKEN_RETAIN_PERIOD,CPC_TOKEN_CUST_UPD_DURATION,
    CPC_DEFAULT_PIN_OPTION,cpc_exp_date_exemption,CPC_REDEMPTION_DELAY_FLAG,CPC_CVVPLUS_ELIGIBILITY,CPC_CVVPlus_Short_Name,CPC_SWEEP_FLAG,CPC_ADDL_SWEEP_PERIOD,
    CPC_B2B_FLAG,CPC_B2BCARD_STAT,CPC_B2B_ACTIVATION_CODE,CPC_B2B_LMTPRFL,CPC_B2BFLNAME_FLAG,CPC_INACTIVETOKEN_RETAINPERIOD,CPC_KYC_FLAG,
    CPC_CVV2_VERIFICATION_FLAG,CPC_EXPIRY_DATE_CHECK_FLAG,CPC_ACCT_BALANCE_CHECK_FLAG,CPC_REPLACEMENT_PROVISION_FLAG,CPC_ACCT_BAL_CHECK_TYPE,CPC_ACCT_BAL_CHECK_VALUE,CPC_ISSU_PRODCONFIG_ID,CPC_CONSUMED_FLAG,CPC_CONSUMED_CARD_STAT,CPC_RENEW_REPLACE_OPTION,CPC_RENEW_REPLACE_PRODCODE,CPC_RENEW_REPLACE_CARDTYPE,
    CPC_USER_IDENTIFY_TYPE,CPC_RELOADABLE_FLAG,CPC_PROD_SUFFIX,CPC_START_CARD_NO,CPC_END_CARD_NO,CPC_CCF_FORMAT_VERSION,CPC_DCMS_ID,CPC_PRODUCT_UPC,CPC_PACKING_UPC,CPC_PROD_DENOM,CPC_PDENOM_MIN,CPC_PDENOM_MAX,CPC_PDENOM_FIX,CPC_ISSU_BANK ,
   CPC_ICA ,CPC_ISSU_BANK_ADDR,CPC_CARDPROD_ACCEPT,CPC_STATE_RESTRICT,CPC_PIF_SIA_CASE,CPC_DISABLE_REPL_FLAG,CPC_DISABLE_REPL_EXPRYDAYS,
   CPC_DISABLE_REPL_MINBAL,CPC_DISABLE_REPL_MESSAGE,CPC_PAN_INVENTORY_FLAG,CPC_ACCTUNLOCK_DURATION,CPC_WRONG_LOGONCOUNT,CPC_ACHBLCKEXPRY_PERIOD,
   CPC_RENEWAL_PINMIGRATION,CPC_FEDERALCHECK_FLAG,CPC_TANDC_VERSION,CPC_CLAWBACK_DESC,CPC_WEBAUTHMAPPING_ID,
   CPC_IVRAUTHMAPPING_ID,CPC_EMAIL_ID,CPC_FROMEMAIL_ID,CPC_APP_NAME,CPC_APPNTY_TYPE,CPC_KYCVERIFY_FLAG,CPC_NETWORKACQID_FLAG,CPC_SHORT_CODE,CPC_CIP_INTVL,CPC_DUP_SSNCHK,CPC_PINCHANGE_FLAG,CPC_OLSRESP_FLAG,CPC_EMV_FLAG,CPC_INSTITUTION_ID,CPC_TRANSIT_NUMBER,CPC_RANDOM_PIN
   ,CPC_POA_PROD,CPC_ONUS_AUTH_EXPIRY,CPC_FROM_DATE,CPC_ROUT_NUM
   ,CPC_OLS_EXPIRY_FLAG,CPC_STATEMENT_FOOTER,CPC_DUP_TIMEPERIOD,CPC_DUP_TIMEUNT,CPC_GPRFLAG_ACHTXN,CPC_CCF_SERIAL_FLAG,CPC_PROGRAM_ID,CPC_PROXY_LENGTH,CPC_CHECK_DIGIT_REQ,CPC_PROGRAMID_REQ,CPC_DEF_COND_APPR,CPC_CUSTOMER_CARE_NUM,CPC_UPGRADE_ELIGIBLE_FLAG,CPC_CCF_3DIGCSCREQ,CPC_DEFAULT_PARTIAL_INDR,CPC_SERIALNO_FILEPATH, CPC_RETAIL_ACTIVATION, CPC_ADDR_VERIFICATION_CHECK,CPC_RECURRING_TRAN_FLAG,CPC_INTERNATIONAL_CHECK,Cpc_Emv_Fallback,Cpc_Fund_Mcc,Cpc_Settl_Mcc,Cpc_Badcredit_Flag,CPC_BADCREDIT_TRANSGRPID,cpc_encrypt_enable,
   CPC_ALERT_CARD_STAT,CPC_ALERT_CARD_AMOUNT,CPC_ALERT_CARD_DURATION,CPC_SRC_APP,CPC_SRC_APP_FLAG,CPC_ADDR_VERIFICATION_RESPONSE,CPC_VALINS_ACT_FLAG,CPC_DEACTIVATION_CLOSED,CPC_DOUBLEOPTINNTY_TYPE,CPC_PRODUCT_FUNDING,CPC_FUND_AMOUNT,CPC_INSTORE_REPLACEMENT,Cpc_Packageid_Check,CPC_MALLID_CHECK,CPC_MALLLOCATION_CHECK,cpc_OFAC_CHECK,CPC_PARTNER_ID,CPC_DOB_MANDATORY,CPC_STNGAUTH_FLAG,CPC_BYPASS_LOADCHECK,CPC_CARD_ID,CPC_ISSUBANK_ID,CPC_EVENT_NOTIFICATION,CPC_PARTNER_NAME,CPC_PIN_RESET_OPTION,CPC_PRODUCT_PORTFOLIO
    FROM CMS_PROD_CATTYPE
    WHERE CPC_PROD_CODE='''||p_prod_code_in||''' AND CPC_CARD_TYPE IN('||p_prod_catg_in||')';--added CPC_REDEMPTION_DELAY_FLAG for FSS-4647
    LOOP
    FETCH ref_cur_prodcatg INTO l_card_type,l_cardtype_desc,l_vendor,l_stock,
    l_cardtype_sname,l_prod_prefix,l_rulegroup_code,
    l_profile_code,l_prod_id,l_package_id,l_achtxn_flg,l_achtxn_cnt,
    l_achtxn_amt,l_achtxn_deposit,l_sec_code,l_min_agekyc,
    l_passive_time,l_achtxn_daycnt,l_achtxn_dayamt,l_achtxn_weekcnt,
    l_achtxn_weekmaxamt,l_achtxn_moncnt,l_achtxn_monmaxamt,l_achtxn_maxtranamt,
    l_achtxn_mintranamt,l_starter_card,l_starter_minload,l_starter_maxload,
    l_startergpr_cardtype,l_strgpr_issue,l_acctprod_prefix,l_serl_flag,
    l_del_met,l_achmin_iniload,l_url,l_pin_app,
    l_dfltpin_flag,l_locchk_flag,l_scorecard_id,l_ach_loadamtchk,
    L_CRDEXP_PEND,L_REPL_PERIOD,L_INVCHK_FLAG,L_STRCRD_DISPNAME,
    l_strrepl_option,l_repl_prodcatg,l_token_eligible,l_token_prov_retrymax,l_tokenretain_period,l_token_custupdduration,l_default_pin_selected,l_exp_date_exemption,l_redemptiondelay_flag,l_CVVPLUS_ELIGIBILITY,l_CVVPlus_Short_Name,l_SWEEP_FLAG,l_SWEEP_PERIOD
    ,l_b2b_Flag,l_b2b_cardstat,l_b2b_actCode,l_b2b_lmtprof,l_b2b_regmatch,l_InactivetoknretainPer,l_kyc_flag,
    L_CVV2_VERIFICATION_FLAG,L_EXPIRY_DATE_CHECK_FLAG,L_ACCT_BALANCE_CHECK_FLAG,L_REPLACEMENT_PROVISION_FLAG,L_ACCT_BALANCE_CHECK_TYPE,L_ACCT_BALANCE_CHECK_VALUE,L_ISSU_PRODCONFIG_ID,L_CONSUMED_FLAG,L_CONSUMED_CARD_STAT,L_RENEW_REPLACE_OPTION,L_RENEW_REPLACE_PRODCODE,L_RENEW_REPLACE_CARDTYPE,
    l_REGISTRATION_TYPE,l_RELOADABLE_FLAG,l_PROD_SUFFIX,l_START_CARD_NO,l_END_CARD_NO,l_CCF_FORMAT_VERSION,l_DCMS_ID,l_PRODUCT_UPC,l_PACKING_UPC,l_PROD_DENOM,
    L_PDENOM_MIN,L_PDENOM_MAX,L_PDENOM_FIX,L_ISSU_BANK,L_ICA,L_ISSU_BANK_ADDR,L_CARDPROD_ACCEPT,L_STATE_RESTRICT,L_PIF_SIA_CASE,L_DISABLE_REPL_FLAG,
    l_DISABLE_REPl_EXPRYDAYS,l_DISABLE_REPl_MINBAL,l_DISABLE_REPL_MESSAGE,l_PAN_INVENTORY_FLAG,l_ACCTUNLOCK_DURATION,l_WRONG_LOGONCOUNT,l_ACHBLCKEXPRY_PERIOD,
    l_RENEWAl_PINMIGRATION,l_FEDERALCHECK_FLAG,l_TANDC_VERSION,l_CLAWBACK_DESC,l_WEBAUTHMAPPING_ID,l_IVRAUTHMAPPING_ID,l_EMAIl_ID,l_FROMEMAIl_ID,
    L_APP_NAME,L_APPNTY_TYPE,L_KYCVERIFY_FLAG,L_NETWORKACQID_FLAG,L_SHORT_CODE,L_CIP_INTVL,L_DUP_SSNCHK,L_PINCHANGE_FLAG,L_OLSRESP_FLAG,L_EMV_FLAG,
    L_Institution_Id,L_Transit_Number,L_Random_Pin ,L_Poa_Prod,L_Onus_Auth_Expiry,L_From_Date,L_Rout_Num,L_Ols_Expiry_Flag,L_Statement_Footer,
    L_Dup_Timeperiod,L_Dup_Timeunt,L_Gprflag_Achtxn,L_Ccf_Serial_Flag,L_Prog_Id,L_Proxy_Len,L_Ischcek_Req,L_Isprg_Id_Req,L_Def_Cond_Appr_Flag,L_Customer_Care_Num,L_Upgrade_Eligible_Flag,L_Ccf_3digcscreq,L_Default_Partial_Indr,L_Serialno_Filepath,L_Retail_Activation,L_Avs_Required,L_Recurring_Tran_Flag,L_International_Tran,L_Emv_Fallback,L_Fund_Mcc,L_Settl_Mcc,L_Badcrd_Flag,L_Badcr_Transgrp,L_Encrypt_Enable,
    l_alert_card_stat,l_alert_card_amnt,l_alert_card_days,l_src_app,l_src_app_flag,L_ADDR_VERIF_RESP,l_VALINS_ACT_FLAG,l_DEACTIVATION_CLOSED,l_DOUBLEOPTINNTY_TYPE,l_PRODUCT_FUNDING,l_FUND_AMOUNT,l_INSTORE_REPLACEMENT,l_Packageid_Check,l_mallid_check,l_malllocation_check,l_OFAC_CHECK,l_PARTNER_ID,l_DOB_MANDATORY_FLAG,L_STANDINGAUTH_TRAN_FLAG,L_BYPASS_INITIAL_LOADCHK,
	L_prdcat_card_id,L_ISSUBANK_ID,L_EVENT_NOTIFICATION,L_PARTNER_NAME,L_PIN_RESET_OPTION,L_PRODUCT_PORTFOLIO;
    EXIT WHEN ref_cur_prodcatg%NOTFOUND;
  BEGIN
  INSERT INTO VMS_PROD_CATTYPE_STAG (
    VPC_INST_CODE,VPC_PROD_CODE,VPC_CARD_TYPE,VPC_CARDTYPE_DESC,
    VPC_INS_USER,VPC_INS_DATE,VPC_LUPD_USER,VPC_LUPD_DATE,
    VPC_VENDOR,VPC_STOCK,VPC_CARDTYPE_SNAME,VPC_PROD_PREFIX,VPC_RULEGROUP_CODE,
    VPC_PROFILE_CODE,VPC_PROD_ID,VPC_PACKAGE_ID,VPC_ACHTXN_FLG,VPC_ACHTXN_CNT,
    VPC_ACHTXN_AMT,VPC_ACHTXN_DEPOSIT,VPC_SEC_CODE,VPC_MIN_AGE_KYC,
    VPC_PASSIVE_TIME,VPC_ACHTXN_DAYCNT,VPC_ACHTXN_DAYMAXAMT,VPC_ACHTXN_WEEKCNT,
    VPC_ACHTXN_WEEKMAXAMT,VPC_ACHTXN_MONCNT,VPC_ACHTXN_MONMAXAMT,VPC_ACHTXN_MAXTRANAMT,
    VPC_ACHTXN_MINTRANAMT,VPC_STARTER_CARD,VPC_STARTER_MINLOAD,VPC_STARTER_MAXLOAD,
    VPC_STARTERGPR_CRDTYPE,VPC_STARTERGPR_ISSUE,VPC_ACCT_PROD_PREFIX,VPC_SERL_FLAG,
    VPC_DEL_MET,VPC_ACHMIN_INITIAL_LOAD,VPC_URL,VPC_PIN_APPLICABLE,
    VPC_DFLTPIN_FLAG,VPC_LOCCHECK_FLAG,VPC_SCORECARD_ID,VPC_ACH_LOADAMNT_CHECK,
    VPC_CRDEXP_PENDING,VPC_REPL_PERIOD,VPC_INVCHECK_FLAG,VPC_STARTERCARD_DISPNAME,
    VPC_STARTER_REPLACEMENT,VPC_REPLACEMENT_CATTYPE,VPC_TOKEN_ELIGIBILITY,VPC_TOKEN_PROVISION_RETRY_MAX,VPC_TOKEN_RETAIN_PERIOD,VPC_TOKEN_CUST_UPD_DURATION,VPC_DEFAULT_PIN_OPTION,vpc_exp_date_exemption,VPC_REDEMPTION_DELAY_FLAG,--ADDED for FSS-4647
    VPC_CVVPLUS_ELIGIBILITY,VPC_CVVPlus_Short_Name,--added for cvvplus
    VPC_SWEEP_FLAG,VPC_ADDL_SWEEP_PERIOD,--ADDED FOR FSS-4619 SWEEP
    VPC_B2B_FLAG,VPC_B2BCARD_STAT,VPC_B2B_ACTIVATION_CODE,VPC_B2B_LMTPRFL,VPC_B2BFLNAME_FLAG,VPC_INACTIVETOKEN_RETAINPERIOD,
    VPC_KYC_FLAG,VPC_CVV2_VERIFICATION_FLAG,VPC_EXPIRY_DATE_CHECK_FLAG,VPC_ACCT_BALANCE_CHECK_FLAG,VPC_REPLACEMENT_PROVISION_FLAG,VPC_ACCT_BAL_CHECK_TYPE,VPC_ACCT_BAL_CHECK_VALUE,VPC_ISSU_PRODCONFIG_ID,VPC_CONSUMED_FLAG,VPC_CONSUMED_CARD_STAT,
    VPC_RENEW_REPLACE_OPTION,VPC_RENEW_REPLACE_PRODCODE,VPC_RENEW_REPLACE_CARDTYPE,VPC_USER_IDENTIFY_TYPE,VPC_RELOADABLE_FLAG,VPC_PROD_SUFFIX,VPC_START_CARD_NO,VPC_END_CARD_NO,VPC_CCF_FORMAT_VERSION,VPC_DCMS_ID,VPC_PRODUCT_UPC,VPC_PACKING_UPC,VPC_PROD_DENOM,VPC_PDENOM_MIN,VPC_PDENOM_MAX,VPC_PDENOM_FIX,VPC_ISSU_BANK ,
   VPC_ICA ,VPC_ISSU_BANK_ADDR,VPC_CARDPROD_ACCEPT,VPC_STATE_RESTRICT,VPC_PIF_SIA_CASE,VPC_DISABLE_REPL_FLAG,VPC_DISABLE_REPL_EXPRYDAYS,
   VPC_DISABLE_REPL_MINBAL,VPC_DISABLE_REPL_MESSAGE,VPC_PAN_INVENTORY_FLAG,VPC_ACCTUNLOCK_DURATION,VPC_WRONG_LOGONCOUNT,VPC_ACHBLCKEXPRY_PERIOD,
   VPC_RENEWAL_PINMIGRATION,VPC_FEDERALCHECK_FLAG,VPC_TANDC_VERSION,VPC_CLAWBACK_DESC,VPC_WEBAUTHMAPPING_ID,
   VPC_IVRAUTHMAPPING_ID,VPC_EMAIL_ID,VPC_FROMEMAIL_ID,VPC_APP_NAME,VPC_APPNTY_TYPE,VPC_KYCVERIFY_FLAG,VPC_NETWORKACQID_FLAG,VPC_SHORT_CODE,VPC_CIP_INTVL,VPC_DUP_SSNCHK,VPC_PINCHANGE_FLAG,VPC_OLSRESP_FLAG,VPC_EMV_FLAG,VPC_INSTITUTION_ID,VPC_TRANSIT_NUMBER,VPC_RANDOM_PIN
   ,Vpc_Poa_Prod,Vpc_Onus_Auth_Expiry,Vpc_From_Date,Vpc_Rout_Num
   ,Vpc_Ols_Expiry_Flag,Vpc_Statement_Footer,Vpc_Dup_Timeperiod,Vpc_Dup_Timeunt,Vpc_Gprflag_Achtxn,Vpc_Ccf_Serial_Flag,Vpc_Program_Id,Vpc_Proxy_Length,Vpc_Check_Digit_Req,Vpc_Programid_Req,Vpc_Def_Cond_Appr,Vpc_Customer_Care_Num,Vpc_Upgrade_Eligible_Flag,Vpc_Ccf_3digcscreq,Vpc_Default_Partial_Indr,Vpc_Serialno_Filepath,Vpc_Retail_Activation,Vpc_Addr_Verification_Check,Vpc_Recurring_Tran_Flag,Vpc_International_Check,Vpc_Emv_Fallback,Vpc_Fund_Mcc,Vpc_Settl_Mcc,Vpc_Badcredit_Flag,Vpc_Badcredit_Transgrpid,Vpc_Encrypt_Enable,Vpc_Alert_Card_Stat,Vpc_Alert_Card_Amount,Vpc_Alert_Card_Duration,Vpc_Src_App,Vpc_Src_App_Flag,Vpc_Addr_Verification_Response
 	,VPC_VALINS_ACT_FLAG,VPC_DEACTIVATION_CLOSED,VPC_DOUBLEOPTINNTY_TYPE,VPC_PRODUCT_FUNDING,VPC_FUND_AMOUNT,VPC_INSTORE_REPLACEMENT,vpc_Packageid_Check,VPC_MALLID_CHECK,VPC_MALLLOCATION_CHECK,vpc_OFAC_CHECK,VPC_PARTNER_ID,VPC_DOB_MANDATORY,VPC_STNGAUTH_FLAG,VPC_BYPASS_LOADCHECK,VPC_CARD_ID,
	VPC_ISSUBANK_ID,VPC_EVENT_NOTIFICATION,VPC_PARTNER_NAME,VPC_PIN_RESET_OPTION,VPC_PRODUCT_PORTFOLIO)--added for b2b and mastercard

    VALUES(
    p_instcode_in,p_prod_code_in,l_card_type,l_cardtype_desc,
    p_ins_user_in,sysdate,p_ins_user_in,sysdate,
    l_vendor,l_stock,l_cardtype_sname,l_prod_prefix,l_rulegroup_code,
    l_profile_code,l_prod_id,l_package_id,l_achtxn_flg,l_achtxn_cnt,
    l_achtxn_amt,l_achtxn_deposit,l_sec_code,l_min_agekyc,
    l_passive_time,l_achtxn_daycnt,l_achtxn_dayamt,l_achtxn_weekcnt,
    l_achtxn_weekmaxamt,l_achtxn_moncnt,l_achtxn_monmaxamt,l_achtxn_maxtranamt,
    l_achtxn_mintranamt,l_starter_card,l_starter_minload,l_starter_maxload,
    l_startergpr_cardtype,l_strgpr_issue,l_acctprod_prefix,l_serl_flag,
    l_del_met,l_achmin_iniload,l_url,l_pin_app,
    l_dfltpin_flag,l_locchk_flag,l_scorecard_id,l_ach_loadamtchk,
    l_crdexp_pend,l_repl_period,l_invchk_flag,l_strcrd_dispname,
    NULL,NULL,l_token_eligible,l_token_prov_retrymax,l_tokenretain_period,l_token_custupdduration,l_default_pin_selected,l_exp_date_exemption,l_redemptiondelay_flag,l_CVVPLUS_ELIGIBILITY,l_CVVPlus_Short_Name,l_SWEEP_FLAG,l_SWEEP_PERIOD,
    L_B2B_FLAG,L_B2B_CARDSTAT,L_B2B_ACTCODE,L_B2B_LMTPROF,L_B2B_REGMATCH,L_INACTIVETOKNRETAINPER,L_KYC_FLAG,
    l_cvv2_verification_flag,l_expiry_date_check_flag,l_acct_balance_check_flag,l_replacement_provision_flag,l_acct_balance_check_type,l_acct_balance_check_value,l_issu_prodconfig_id,l_consumed_flag,l_consumed_card_stat,l_renew_replace_option,l_renew_replace_prodcode,l_renew_replace_cardtype,l_REGISTRATION_TYPE,l_RELOADABLE_FLAG,l_PROD_SUFFIX,l_START_CARD_NO,l_END_CARD_NO,l_CCF_FORMAT_VERSION,l_DCMS_ID,l_PRODUCT_UPC,l_PACKING_UPC,l_PROD_DENOM,
    L_PDENOM_MIN,L_PDENOM_MAX,L_PDENOM_FIX,L_ISSU_BANK,L_ICA,L_ISSU_BANK_ADDR,L_CARDPROD_ACCEPT,L_STATE_RESTRICT,L_PIF_SIA_CASE,L_DISABLE_REPL_FLAG,
    l_DISABLE_REPl_EXPRYDAYS,l_DISABLE_REPl_MINBAL,l_DISABLE_REPL_MESSAGE,l_PAN_INVENTORY_FLAG,l_ACCTUNLOCK_DURATION,l_WRONG_LOGONCOUNT,l_ACHBLCKEXPRY_PERIOD,
    l_RENEWAl_PINMIGRATION,l_FEDERALCHECK_FLAG,l_TANDC_VERSION,l_CLAWBACK_DESC,l_WEBAUTHMAPPING_ID,l_IVRAUTHMAPPING_ID,l_EMAIl_ID,l_FROMEMAIl_ID,
    L_APP_NAME,L_APPNTY_TYPE,L_KYCVERIFY_FLAG,L_NETWORKACQID_FLAG,L_SHORT_CODE,L_CIP_INTVL,L_DUP_SSNCHK,L_PINCHANGE_FLAG,L_OLSRESP_FLAG,L_EMV_FLAG,
    L_Institution_Id,L_Transit_Number,L_Random_Pin ,L_Poa_Prod,L_Onus_Auth_Expiry,L_From_Date,L_Rout_Num,L_Ols_Expiry_Flag,L_Statement_Footer,
    L_Dup_Timeperiod,L_Dup_Timeunt,L_Gprflag_Achtxn,L_Ccf_Serial_Flag,L_Prog_Id,L_Proxy_Len,L_Ischcek_Req,L_Isprg_Id_Req,L_Def_Cond_Appr_Flag,L_Customer_Care_Num,L_Upgrade_Eligible_Flag,L_Ccf_3digcscreq,L_Default_Partial_Indr,L_Serialno_Filepath,L_Retail_Activation,L_Avs_Required,L_Recurring_Tran_Flag,L_International_Tran,L_Emv_Fallback,L_Fund_Mcc,L_Settl_Mcc,L_Badcrd_Flag,L_Badcr_Transgrp,L_Encrypt_Enable,L_Alert_Card_Stat,L_Alert_Card_Amnt,L_Alert_Card_Days,L_Src_App,L_Src_App_Flag,L_Addr_Verif_Resp,L_Valins_Act_Flag,
    l_DEACTIVATION_CLOSED,l_DOUBLEOPTINNTY_TYPE,l_PRODUCT_FUNDING,l_FUND_AMOUNT,l_INSTORE_REPLACEMENT,l_Packageid_Check,l_mallid_check,l_malllocation_check,l_OFAC_CHECK,l_PARTNER_ID,l_DOB_MANDATORY_FLAG,L_STANDINGAUTH_TRAN_FLAG,L_BYPASS_INITIAL_LOADCHK,L_prdcat_card_id,
	L_ISSUBANK_ID,L_EVENT_NOTIFICATION,L_PARTNER_NAME,L_PIN_RESET_OPTION,L_PRODUCT_PORTFOLIO);

    EXCEPTION
            WHEN OTHERS
            THEN
               p_errmsg_out :=
                     'ERROR WHILE INSERTING INTO VMS_PROD_CATTYPE_STAG:'
                  || SUBSTR (SQLERRM, 1, 300);
               RAISE EXP_REJECT_RECORD;

    END;

    BEGIN
    INSERT INTO VMS_PRODCATG_COPY_INFO (
                              VPC_PROFILE_CODE,VPC_CARDTYPE_DESC,VPC_PROD_CODE,VPC_CATG_CODE,VPC_COPY_OPTION,VPC_ENV_OPTION,VPC_DFG_PARAM_UPDFLAG,VPC_EMBOSS_FORMAT_UPDFLAG,
                              VPC_INS_USER,VPC_INS_DATE,VPC_LUPD_USER,VPC_LUPD_DATE,VPC_INST_CODE,VPC_STRGPR_TYPE)
                              VALUES(
                              L_PROFILE_CODE,L_CARDTYPE_DESC,P_PROD_CODE_IN,L_CARD_TYPE,P_COPY_OPTION,P_ENV_OPTION,'N','N',
                              p_ins_user_in,sysdate,p_ins_user_in,sysdate,p_instcode_in,l_starter_card);
   EXCEPTION
            WHEN OTHERS
            THEN
               p_errmsg_out :=
                     'ERROR WHILE INSERTING INTO VMS_PRODCATG_COPY_INFO:'
                  || SUBSTR (SQLERRM, 1, 300);
                 RAISE EXP_REJECT_RECORD;
   END;


  END LOOP;

   EXCEPTION
            when EXP_REJECT_RECORD then
                raise;
            WHEN OTHERS
            THEN
               p_errmsg_out :=
                     'ERROR WHILE INSERTING INTO VMS_PROD_CATTYPE_STAG AND VMS_PRODCATG_COPY_INFO:'
                  || SUBSTR (SQLERRM, 1, 300);
               RAISE EXP_REJECT_RECORD;

 END;


 BEGIN

  OPEN ref_cur_prodcatg_seccode FOR
  'SELECT CPC_SEC_CODE,CPC_CARD_TYPE,CPC_TRAN_CODE
   FROM CMS_PROD_CATSEC
   WHERE CPC_PROD_CODE='''||p_prod_code_in||''' AND CPC_CARD_TYPE IN('||p_prod_catg_in||')';
  LOOP
  FETCH ref_cur_prodcatg_seccode INTO l_sec_code1,l_card_type,l_tran_code;
  EXIT WHEN ref_cur_prodcatg_seccode%NOTFOUND;

  INSERT INTO VMS_PROD_CATSEC_STAG (
                              VPC_INST_CODE,VPC_PROD_CODE,VPC_SEC_CODE,
                              VPC_INS_USER,VPC_INS_DATE,VPC_LUPD_USER,VPC_LUPD_DATE,
                              VPC_CARD_TYPE,VPC_TRAN_CODE)
                              VALUES(
                              p_instcode_in,p_prod_code_in,l_sec_code1,
                              p_ins_user_in,sysdate,p_ins_user_in,sysdate,
                              l_card_type,l_tran_code);


  END LOOP;

   EXCEPTION
            WHEN OTHERS
            THEN
               p_errmsg_out :=
                     'ERROR WHILE INSERTING INTO VMS_PROD_CATTYPE_STAG:'
                  || SUBSTR (SQLERRM, 1, 300);
               RAISE EXP_REJECT_RECORD;

 END;



  BEGIN
    open ref_cur_prodcatg_threshold for
    'SELECT VPT_PROD_THRESHOLD,vpt_card_type  FROM VMS_PRODCAT_THRESHOLD WHERE
    VPT_PROD_CODE='''||p_prod_code_in||''' AND VPT_CARD_TYPE IN ('||p_prod_catg_in||')';
    LOOP
    FETCH ref_cur_prodcatg_threshold INTO L_PRODCAT_THRESHOLD1,l_card_type;
     exit when ref_cur_prodcatg_threshold%notfound;
      begin

        INSERT INTO VMS_PRODCAT_THRESHOLD_STAG(VPT_INST_CODE,
                                        VPT_PROD_CODE,
                                        VPT_CARD_TYPE,
                                        VPT_PROD_THRESHOLD,
                                        VPT_INS_USER,
                                        VPT_INS_DATE,
                                        VPT_LUPD_USER,
                                        VPT_LUPD_DATE)
                                  VALUES(p_instcode_in,
                                         P_PROD_CODE_IN,
                                         l_card_type,
                                         L_PRODCAT_THRESHOLD1,
                                         p_ins_user_in,
                                         SYSDATE,
                                         p_ins_user_in,
                                        SYSDATE);

          EXCEPTION
            WHEN OTHERS
            THEN
               P_ERRMSG_OUT :=
                'ERROR WHILE SELECTING DETAILS FROM  VMS_PRODCAT_THRESHOLD:'||p_prod_catg_in
                  || SUBSTR (SQLERRM, 1, 300);
               RAISE EXP_REJECT_RECORD;

			   END;
        end loop;

    EXCEPTION
            WHEN OTHERS
            THEN
               p_errmsg_out :=
                     'ERROR WHILE INSERTING INTO VMS_PRODCAT_THRESHOLD_STAG:'
                  || SUBSTR (SQLERRM, 1, 300);
               RAISE EXP_REJECT_RECORD;

    END;

	  BEGIN
    open ref_cur_prodcat_netmap for
    'SELECT VPN_NETWORK_ID,vpn_card_type  FROM VMS_PRODCAT_NETWORKID_MAPPING WHERE
    VPN_PROD_CODE='''||P_PROD_CODE_IN||'''AND VPN_CARD_TYPE IN ('||p_prod_catg_in||')';
    loop
      fetch ref_cur_prodcat_netmap into l_network_id,l_card_type;
       EXIT WHEN ref_cur_prodcat_netmap%NOTFOUND;
      begin
            INSERT INTO VMS_PRODCAT_NETWORKID_MAP_STAG(
                    VPN_INST_CODE,
                    VPN_PROD_CODE,
                    VPN_CARD_TYPE,
                    VPN_NETWORK_ID,
                    VPN_INS_USER,
                    VPN_INS_DATE,
                    VPN_LUPD_USER,
                    VPN_LUPD_DATE)
                    VALUES(
                    p_instcode_in,
                    P_PROD_CODE_IN,
                    l_card_type,
                    l_network_id,
                    p_ins_user_in,
                    SYSDATE,
                    p_ins_user_in,
                    SYSDATE);
                      EXCEPTION
            WHEN OTHERS
            THEN
               p_errmsg_out :=
                     'ERROR WHILE INSERTING INTO VMS_PRODCAT_NETWORKID_MAP_STAG:'
                  || SUBSTR (SQLERRM, 1, 300);
               RAISE EXP_REJECT_RECORD;
               end;
            END LOOP;
            EXCEPTION
            WHEN OTHERS
            THEN
               p_errmsg_out :=
                     'ERROR WHILE INSERTING INTO VMS_PRODCAT_NETWORKID_MAP_STAG:'
                  || SUBSTR (SQLERRM, 1, 300);
               RAISE EXP_REJECT_RECORD;

 END;

 BEGIN
        open ref_cur_scorecd_prodcat_map for 'SELECT VSP_SCORECARD_ID,
            VSP_DELIVERY_CHANNEL,VSP_CIPCARD_STAT,VSP_AVQ_FLAG,vsp_card_type
            FROM VMS_SCORECARD_PRODCAT_MAPPING WHERE
            VSP_PROD_CODE='''||P_PROD_CODE_IN||''' AND VSP_CARD_TYPE IN ('||p_prod_catg_in||')';
        loop
        fetch ref_cur_scorecd_prodcat_map into l_scorecard_id,l_delivery_channel,
                                          L_CIPCARD_STAT,L_AVQ_FLAG,L_CARD_TYPE;
        EXIT WHEN REF_CUR_SCORECD_PRODCAT_MAP%NOTFOUND;
         begin
            INSERT INTO VMS_SCORECARD_PRODCAT_MAP_STAG(
                    VSP_INST_CODE,
                    VSP_SCORECARD_ID,
                    VSP_PROD_CODE,
                    VSP_CARD_TYPE,
                    VSP_DELIVERY_CHANNEL,
                    VSP_CIPCARD_STAT,
                    VSP_AVQ_FLAG,
                    VSP_INS_USER,
                    VSP_INS_DATE,
                    VSP_LUPD_USER,
                    VSP_LUPD_DATE)
                    VALUES(
                    p_instcode_in,
                    l_scorecard_id,
                    P_PROD_CODE_IN,
                    l_card_type,
                    l_delivery_channel,
                    l_cipcard_stat,
                    l_avq_flag,
                    p_ins_user_in,
                    SYSDATE,
                    p_ins_user_in,
                    SYSDATE);
                      EXCEPTION
            WHEN OTHERS
            THEN
               p_errmsg_out :=
                     'ERROR WHILE INSERTING INTO VMS_SCORECARD_PRODCAT_MAP_STAG:'
                  || SUBSTR (SQLERRM, 1, 300);
               RAISE EXP_REJECT_RECORD;
               end;

            END LOOP;
            EXCEPTION
            WHEN OTHERS
            THEN
               p_errmsg_out :=
                     'ERROR WHILE INSERTING INTO VMS_SCORECARD_PRODCAT_MAP_STAG:'
                  || SUBSTR (SQLERRM, 1, 300);
               RAISE EXP_REJECT_RECORD;

 END;

BEGIN

  OPEN ref_cur_prodcatg_cardid FOR
  'SELECT CPC_CATG_CODE,CPC_CARD_ID,CPC_ISSUER_GUID,CPC_ART_GUID,CPC_TC_GUID
   FROM CMS_PRODCAT_CARDPACK
   WHERE CPC_PROD_CODE='''||p_prod_code_in||''' AND CPC_CATG_CODE IN('||p_prod_catg_in||')';
  LOOP
  FETCH ref_cur_prodcatg_cardid INTO l_card_type,l_card_id,l_issuer_guid,l_art_guid,l_tc_guid;
  EXIT WHEN ref_cur_prodcatg_cardid%NOTFOUND;

  INSERT INTO VMS_PRODCAT_CARDPACK_STAG (
                              VPC_INST_CODE,
                              VPC_PROD_CODE,
                              VPC_CATG_CODE,
                              VPC_CARD_ID,
                              VPC_ISSUER_GUID,
                              VPC_ART_GUID,
                              VPC_TC_GUID)
                              VALUES(
                              p_instcode_in,
                              P_PROD_CODE_IN,
                              l_card_type,
                              l_card_id,
                              l_issuer_guid,
                              l_art_guid,
                              l_tc_guid);


  END LOOP;

   EXCEPTION
            WHEN OTHERS
            THEN
               p_errmsg_out :=
                     'ERROR WHILE INSERTING INTO VMS_PRODCAT_CARDPACK_STAG :'
                  || SUBSTR (SQLERRM, 1, 300);
               RAISE EXP_REJECT_RECORD;

 END;

  Begin
          open ref_cur_prodcat_deno for 'SELECT VPD_PDEN_VAL,VPD_DENO_STATUS,VPD_CARD_TYPE
                 FROM VMS_PRODCAT_DENO_MAST
                  WHERE
            VPD_PROD_CODE='''||P_PROD_CODE_IN||''' AND VPD_CARD_TYPE IN ('||p_prod_catg_in||')';
          LOOP
          FETCH REF_CUR_PRODCAT_DENO INTO L_PDEN_VAL,L_DENO_STATUS,L_CARD_TYPE;
           EXIT WHEN REF_CUR_PRODCAT_DENO%NOTFOUND;
           begin
            INSERT INTO VMS_PRODCAT_DENO_MAST_STAG(
                    Vpd_Inst_Code,
                    Vpd_Prod_Code,
                    Vpd_Card_Type,
                    Vpd_Pden_Val,
                    Vpd_Deno_Status,
                    Vpd_Ins_User,
                    Vpd_Ins_Date,
                    Vpd_Lupd_User,
                    Vpd_Lupd_Date)
                    Values(
                    P_Instcode_In,
                    P_Prod_Code_In,
                    l_card_type,
                    l_pden_val,
                    l_deno_status,
                    P_Ins_User_In,
                    Sysdate,
                    P_Ins_User_In,
                    Sysdate);
                      EXCEPTION
            WHEN OTHERS
            THEN
               p_errmsg_out :=
                     'ERROR WHILE INSERTING INTO VMS_PRODCAT_DENO_MAST:'
                  || SUBSTR (SQLERRM, 1, 300);
               RAISE EXP_REJECT_RECORD;
               end;

            END LOOP;
              EXCEPTION
            WHEN OTHERS
            THEN
               p_errmsg_out :=
                     'ERROR WHILE INSERTING INTO VMS_PRODCAT_DENO_MAST:'
                  || SUBSTR (SQLERRM, 1, 300);
               RAISE EXP_REJECT_RECORD;
            End;
 Exception
  When Exp_Reject_Record Then
  Rollback;-- TO l_savepoint;
  When Others Then
  Rollback;-- TO l_savepoint;
  P_Errmsg_Out := 'Exception while copying PRODCATG_PARAMETER_TEMPCOPY:' ||P_Errmsg_Out || Substr(Sqlerrm, 1, 200);

End;


--end of product category copy


--start savings account parameter copy

PROCEDURE  PRODUCT_SAVINGSPARAM_TEMPCOPY (
   p_instcode_in            IN       NUMBER,
   p_ins_user_in            IN       NUMBER,
   p_prod_code_in           IN       VARCHAR2,
   p_prod_catg_in           IN       VARCHAR2,
   p_errmsg_out             OUT      VARCHAR2
)
IS

/**********************************************************************************************


  * Created by                  : MageshKumar S.
  * Created Date                : 01-MAR-16
  * Created For                 : HOSTCC-57
  * Created reason              : SAVINGS ACCOUNT PARAMETERE COPY PROGRAM
  * Reviewer                    : SARAVANAKUMAR/SPANKAJ
  * Build Number                : VMSGPRHOSTCSD4.0_B0001

**************************************************************************************************/
--l_savepoint           NUMBER                              DEFAULT 1;
L_PARAM_KEY       VMS_DFG_PARAM_STAG.VDP_PARAM_KEY%TYPE;
L_PARAM_VALUE      VMS_DFG_PARAM_STAG.VDP_PARAM_VALUE%TYPE;
l_mandatory_flag   VMS_DFG_PARAM_STAG.VDP_MANDARORY_FLAG%TYPE;
l_card_type            VMS_DFG_PARAM_STAG.VDP_CARD_TYPE%type;

EXP_REJECT_RECORD EXCEPTION;
REF_PROD_SAVINGSACCT_INFO  SYS_REFCURSOR;
BEGIN

 p_errmsg_out  := 'OK';
 SAVEPOINT l_savepoint;

 BEGIN

  OPEN REF_PROD_SAVINGSACCT_INFO FOR
          ' SELECT    CDP_PARAM_KEY,CDP_PARAM_VALUE,CDP_MANDARORY_FLAG,CDP_CARD_TYPE
            FROM CMS_DFG_PARAM
            WHERE CDP_PROD_CODE='''||p_prod_code_in||''' AND CDP_CARD_TYPE IN('||p_prod_catg_in||')';

  LOOP
  FETCH REF_PROD_SAVINGSACCT_INFO INTO l_param_key,l_param_value,l_mandatory_flag,l_card_type;
  EXIT WHEN REF_PROD_SAVINGSACCT_INFO%NOTFOUND;

 INSERT INTO VMS_DFG_PARAM_STAG
   (VDP_INST_CODE,
    VDP_PARAM_KEY,
    VDP_PARAM_VALUE,
    VDP_INST_USER,
    VDP_INS_DATE,
    VDP_LUPD_USER,
    VDP_LUPD_DATE,
    VDP_MANDARORY_FLAG,
    VDP_PROD_CODE,
    VDP_CARD_TYPE)
    VALUES(
    p_instcode_in,
    l_param_key,
    l_param_value,
    p_ins_user_in,
    sysdate,
    p_ins_user_in,
    sysdate,
    l_mandatory_flag,
    p_prod_code_in,
    l_card_type);


  END LOOP;

 EXCEPTION
            WHEN OTHERS
            THEN
               p_errmsg_out :=
                     'ERROR WHILE INSERTING INTO VMS_DFG_PARAM_STAG:'
                  || SUBSTR (SQLERRM, 1, 300);
               RAISE EXP_REJECT_RECORD;

 END;

--EXP_REJECT_RECORD EXCEPTION;


--CURSOR PROD_SAVINGSACCT_INFO(l_prod_code_in IN VARCHAR,l_prod_catg_in IN VARCHAR)
--IS
--SELECT
--CDP_PARAM_KEY,CDP_PARAM_VALUE,CDP_MANDARORY_FLAG
--FROM CMS_DFG_PARAM
--WHERE CDP_PROD_CODE=l_prod_code_in and CDP_CARD_TYPE IN ('|| l_prod_catg_in ||');
--
--
--BEGIN
--
-- p_errmsg_out  := 'OK';
---- SAVEPOINT l_savepoint;
--
-- BEGIN
--
--  FOR l_row_indx IN PROD_SAVINGSACCT_INFO(p_prod_code_in,p_prod_catg_in)
--  LOOP
--  INSERT INTO VMS_DFG_PARAM_STAG
--   (VDP_INST_CODE,
--    VDP_PARAM_KEY,
--    VDP_PARAM_VALUE,
--    VDP_INST_USER,
--    VDP_INS_DATE,
--    VDP_LUPD_USER,
--    VDP_LUPD_DATE,
--    VDP_MANDARORY_FLAG,
--    VDP_PROD_CODE,
--    VDP_CARD_TYPE)
--    VALUES(
--    p_instcode_in,
--    l_row_indx.CDP_PARAM_KEY,
--    l_row_indx.CDP_PARAM_VALUE,
--    p_ins_user_in,
--    sysdate,
--    p_ins_user_in,
--    sysdate,
--    l_row_indx.CDP_MANDARORY_FLAG,
--    p_prod_code_in,
--    p_prod_catg_in);
--
--  END LOOP;
--
--   EXCEPTION
--            WHEN OTHERS
--            THEN
--               p_errmsg_out :=
--                     'ERROR WHILE INSERTING INTO VMS_DFG_PARAM_STAG:'
--                  || SUBSTR (SQLERRM, 1, 300);
--               RAISE EXP_REJECT_RECORD;
--
-- END;

  EXCEPTION
  WHEN EXP_REJECT_RECORD THEN
  ROLLBACK;-- TO l_savepoint;
  WHEN OTHERS THEN
  ROLLBACK;-- TO l_savepoint;
  p_errmsg_out := 'Exception while copying PRODUCT_SAVINGSPARAM_TEMPCOPY:' ||p_errmsg_out || SUBSTR(SQLERRM, 1, 200);


END;


--end savings account parameter copy

--start emboss file format copy


PROCEDURE  PRODUCT_EMBOSSFORMAT_TEMPCOPY (
   p_instcode_in            IN       NUMBER,
   p_ins_user_in            IN       NUMBER,
   p_prod_code_in           IN       VARCHAR2,
   p_prod_catg_in           IN       VARCHAR2,
   p_errmsg_out             OUT      VARCHAR2
)
IS

/**********************************************************************************************


  * Created by                  : MageshKumar S.
  * Created Date                : 01-MAR-16
  * Created For                 : HOSTCC-57
  * Created reason              : EMBOSS FILE FORMAT COPY PROGRAM
  * Reviewer                    : SARAVANAKUMAR/SPANKAJ
  * Build Number                : VMSGPRHOSTCSD4.0_B0001

**************************************************************************************************/

EXP_REJECT_RECORD EXCEPTION;
l_profile_code            cms_profile_mast.cpm_profile_code%TYPE;
l_emb_line1               CMS_EMBOSS_FILE_FORMAT.CEFF_EMBOSS_LINE1%TYPE;
l_emb_line2               CMS_EMBOSS_FILE_FORMAT.CEFF_EMBOSS_LINE2%TYPE;
l_emb_line3               CMS_EMBOSS_FILE_FORMAT.CEFF_EMBOSS_LINE3%TYPE;
l_emb_line4               CMS_EMBOSS_FILE_FORMAT.CEFF_EMBOSS_LINE4%TYPE;
l_track1_data             CMS_EMBOSS_FILE_FORMAT.CEFF_TRACK1_DATA%TYPE;
l_track2_data             CMS_EMBOSS_FILE_FORMAT.CEFF_TRACK2_DATA%TYPE;
l_indent_line             CMS_EMBOSS_FILE_FORMAT.CEFF_INDENT_LINE%TYPE;
l_del_flag                CMS_EMBOSS_FILE_FORMAT.CEFF_DEL_FLAG%TYPE;
l_ptrack2_data            CMS_EMBOSS_FILE_FORMAT.CEFF_PTRACK2_DATA%TYPE;
l_format_flag             CMS_EMBOSS_FILE_FORMAT.CEFF_FORMAT_FLAG%TYPE;
l_track2_pattern          CMS_EMBOSS_FILE_FORMAT.CEFF_TRACK2_PATTERN%TYPE;
l_track1_pattern          CMS_EMBOSS_FILE_FORMAT.CEFF_TRACK1_PATTERN%TYPE;
l_alttrack1_pattern       CMS_EMBOSS_FILE_FORMAT.CEFF_ALTTRACK1_PATTERN%TYPE;
l_alttrack1_data          CMS_EMBOSS_FILE_FORMAT.CEFF_ALTTRACK1_DATA%TYPE;
l_alttrack2_pattern       CMS_EMBOSS_FILE_FORMAT.CEFF_ALTTRACK2_PATTERN%TYPE;
L_ALTTRACK2_DATA          CMS_EMBOSS_FILE_FORMAT.CEFF_ALTTRACK2_DATA%TYPE;
REF_CUR_EMBOSSE_TEMP_STAG SYS_REFCURSOR;

BEGIN

 p_errmsg_out  := 'OK';




 open REF_CUR_EMBOSSE_TEMP_STAG for '  SELECT  CPM_PROFILE_CODE
    FROM CMS_PROFILE_MAST
    WHERE CPM_PROFILE_CODE IN(SELECT CPC_PROFILE_CODE FROM CMS_PROD_CATTYPE WHERE CPC_PROD_CODE='''||P_PROD_CODE_IN||''' AND CPC_CARD_TYPE IN ('|| p_prod_catg_in ||'))';
    loop
        FETCH REF_CUR_EMBOSSE_TEMP_STAG INTO L_PROFILE_CODE;
        exit when REF_CUR_EMBOSSE_TEMP_STAG%notfound;
-- BEGIN
--
--  SELECT  CPM_PROFILE_CODE
--    INTO l_profile_code
--    FROM CMS_PROFILE_MAST
--    WHERE CPM_PROFILE_CODE IN(SELECT CPC_PROFILE_CODE FROM CMS_PROD_CATTYPE WHERE CPC_PROD_CODE=p_prod_code_in AND CPC_CARD_TYPE IN ('|| p_prod_catg_in ||'));
--
--    EXCEPTION
--     WHEN NO_DATA_FOUND
--            THEN
--               p_errmsg_out :=
--                     'PROFILE DETAILS NOT FOUND FROM PROCESS PRODUCT_EMBOSSFORMAT_TEMPCOPY:'|| p_prod_code_in;
--               RAISE EXP_REJECT_RECORD;
--          WHEN OTHERS
--         THEN
--            p_errmsg_out := 'ERROR WHILE SELECTING PRODUCT PROFILE DETAILS FROM PRODUCT_EMBOSSFORMAT_TEMPCOPY:'|| SUBSTR (SQLERRM, 1, 200);
--            RAISE EXP_REJECT_RECORD;
--  END;
--
   BEGIN

  SELECT
        CEFF_EMBOSS_LINE1,CEFF_EMBOSS_LINE2,CEFF_EMBOSS_LINE3,
        CEFF_EMBOSS_LINE4,CEFF_TRACK1_DATA,CEFF_TRACK2_DATA,
        CEFF_INDENT_LINE,CEFF_DEL_FLAG,CEFF_PTRACK2_DATA,CEFF_FORMAT_FLAG,
        CEFF_TRACK2_PATTERN,CEFF_TRACK1_PATTERN,CEFF_ALTTRACK1_PATTERN,
        CEFF_ALTTRACK1_DATA,CEFF_ALTTRACK2_PATTERN,CEFF_ALTTRACK2_DATA
  INTO l_emb_line1,l_emb_line2,l_emb_line3,
       l_emb_line4,l_track1_data,l_track2_data,
       l_indent_line,l_del_flag,l_ptrack2_data,l_format_flag,
       l_track2_pattern,l_track1_pattern,l_alttrack1_pattern,
       l_alttrack1_data,l_alttrack2_pattern,l_alttrack2_data
    FROM CMS_EMBOSS_FILE_FORMAT
    WHERE CEFF_PROFILE_CODE=l_profile_code;

    EXCEPTION
       WHEN NO_DATA_FOUND
            then
            null;
            WHEN OTHERS

         THEN
            p_errmsg_out := 'ERROR WHILE SELECTING EMBOSS FILE FORMAT DETAILS:'|| SUBSTR (SQLERRM, 1, 200);
            RAISE EXP_REJECT_RECORD;
  END;


 BEGIN

  INSERT INTO VMS_EMBOSS_FILE_FORMAT_STAG(
    VEFF_PROFILE_CODE,
    VEFF_EMBOSS_LINE1,
    VEFF_EMBOSS_LINE2,
    VEFF_EMBOSS_LINE3,
    VEFF_EMBOSS_LINE4,
    VEFF_TRACK1_DATA,
    VEFF_TRACK2_DATA,
    VEFF_INDENT_LINE,
    VEFF_INS_USER,
    VEFF_INS_DATE,
    VEFF_DEL_FLAG,
    VEF_LUPD_DATE,
    VEF_INST_CODE,
    VEF_LUPD_USER,
    VEFF_PTRACK2_DATA,
    VEFF_FORMAT_FLAG,
    VEFF_TRACK2_PATTERN,
    VEFF_TRACK1_PATTERN,
    VEFF_ALTTRACK1_PATTERN,
    VEFF_ALTTRACK1_DATA,
    VEFF_ALTTRACK2_PATTERN,
    VEFF_ALTTRACK2_DATA)
    VALUES(
    l_profile_code,
    l_emb_line1,
    l_emb_line2,
    l_emb_line3,
    l_emb_line4,
    l_track1_data,
    l_track2_data,
    l_indent_line,
    p_ins_user_in,
    sysdate,
    l_del_flag,
    sysdate,
    p_instcode_in,
    p_ins_user_in,
    l_ptrack2_data,
    l_format_flag,
    l_track2_pattern,
    l_track1_pattern,
    l_alttrack1_pattern,
    l_alttrack1_data,
    l_alttrack2_pattern,
    l_alttrack2_data);
   EXCEPTION
            WHEN OTHERS
            THEN
               p_errmsg_out :=
                     'ERROR WHILE INSERTING INTO VMS_EMBOSS_FILE_FORMAT_STAG:'
                  || SUBSTR (SQLERRM, 1, 300);
               RAISE EXP_REJECT_RECORD;

 END;
 end loop;
 EXCEPTION
  WHEN EXP_REJECT_RECORD THEN
  ROLLBACK;
  WHEN OTHERS THEN
  ROLLBACK;
  p_errmsg_out := 'Exception while copying PRODUCT_EMBOSSFORMAT_TEMPCOPY:' ||p_errmsg_out || SUBSTR(SQLERRM, 1, 200);


END;


--end emboss file format copy


--start ACH file process copy

PROCEDURE  PRODUCT_ACHCONFIG_TEMPCOPY (
   p_instcode_in            IN       NUMBER,
   p_ins_user_in            IN       NUMBER,
   p_prod_code_in           IN       VARCHAR2,
   p_errmsg_out             OUT      VARCHAR2
)
IS

/**********************************************************************************************


  * Created by                  : MageshKumar S.
  * Created Date                : 01-MAR-16
  * Created For                 : HOSTCC-57
  * Created reason              : ACH CONFIGURATION COPY PROGRAM
  * Reviewer                    : SARAVANAKUMAR/SPANKAJ
  * Build Number                : VMSGPRHOSTCSD4.0_B0001

**************************************************************************************************/
--l_savepoint           NUMBER                              DEFAULT 1;
EXP_REJECT_RECORD EXCEPTION;


CURSOR ACH_BLACKLIST_INFO(l_prod_code_in IN VARCHAR)
IS
SELECT
CBS_SOURCE_NAME,
CBS_VALIDFROM_DATE,CBS_VALIDTO_DATE
FROM CMS_BLACKLIST_SOURCES
WHERE CBS_PROD_CODE=l_prod_code_in;


BEGIN

 p_errmsg_out  := 'OK';
 --SAVEPOINT l_savepoint;

 BEGIN

  FOR l_row_indx IN ACH_BLACKLIST_INFO(p_prod_code_in)
  LOOP
  INSERT INTO VMS_BLACKLIST_SOURCES_STAG (
    VBS_INST_CODE,
    VBS_SOURCE_NAME,
    VBS_INS_DATE,
    VBS_INS_USER,
    VBS_PROD_CODE,
    VBS_VALIDFROM_DATE,
    VBS_VALIDTO_DATE,
    VBS_LIPD_USER,
    VBS_LUPD_DATE)
    VALUES(
    p_instcode_in,
    l_row_indx.CBS_SOURCE_NAME,
    sysdate,
    p_ins_user_in,
    p_prod_code_in,
    l_row_indx.CBS_VALIDFROM_DATE,
    l_row_indx.CBS_VALIDTO_DATE,
    p_ins_user_in,
    sysdate);

  END LOOP;

   EXCEPTION
            WHEN OTHERS
            THEN
               p_errmsg_out :=
                     'ERROR WHILE INSERTING INTO VMS_BLACKLIST_SOURCES_STAG:'
                  || SUBSTR (SQLERRM, 1, 300);
               RAISE EXP_REJECT_RECORD;

 END;

  EXCEPTION
  WHEN EXP_REJECT_RECORD THEN
  ROLLBACK;-- TO l_savepoint;
  WHEN OTHERS THEN
  ROLLBACK;-- TO l_savepoint;
  p_errmsg_out := 'Exception while copying PRODUCT_ACHCONFIG_TEMPCOPY:' ||p_errmsg_out || SUBSTR(SQLERRM, 1, 200);

END;


--end ACH file process copy

    PROCEDURE sp_copy_fees (p_inst_code_in       NUMBER,
                            p_prod_code_in       VARCHAR2,
                            p_prodcatg_in        NUMBER,
                            p_feeplan_in         NUMBER,
                            p_valid_to_in        DATE,
                            p_flow_src_in        VARCHAR2,
                            p_respmsg_out    OUT VARCHAR2,
                            p_exist_flag         NUMBER DEFAULT 0)
    IS
    BEGIN
       p_respmsg_out := 'OK';

       BEGIN
          INSERT INTO vms_feeplan_dtls_stag (vfd_inst_code, vfd_fee_plan,vfd_prod_code,
                                  vfd_card_type, vfd_flow_src, vfd_valid_to)
               VALUES (p_inst_code_in, p_feeplan_in, p_prod_code_in,
                       p_prodcatg_in, p_flow_src_in, p_valid_to_in);
       EXCEPTION
          WHEN OTHERS
          THEN
             p_respmsg_out :='Error while inserting feeplan dtls into vms_feeplan_dtls_stag:'
                || SUBSTR (SQLERRM, 1, 200);
             RETURN;
       END;

       IF p_exist_flag = 0
       THEN
          BEGIN
             INSERT INTO vms_fee_feeplan_stag (vff_inst_code, vff_fee_code,
                                               vff_fee_plan, vff_fee_freq)
                SELECT cff_inst_code, cff_fee_code,
                       cff_fee_plan, cff_fee_freq
                  FROM cms_fee_feeplan
                 WHERE cff_fee_plan = p_feeplan_in
                       AND cff_inst_code = p_inst_code_in;
          EXCEPTION
             WHEN OTHERS
             THEN
                p_respmsg_out :='Error while inserting feeplan dtls into vms_fee_feeplan_stag:'
                   || SUBSTR (SQLERRM, 1, 200);
                RETURN;
          END;

          BEGIN
             INSERT INTO vms_fee_mast_stag (vfm_inst_code, vfm_feetype_code, vfm_fee_code,
                                            vfm_fee_amt, vfm_fee_desc, vfm_delivery_channel,
                                            vfm_tran_type, vfm_tran_code, vfm_tran_mode,
                                            vfm_consodium_code, vfm_partner_code, vfm_currency_code,
                                            vfm_per_fees, vfm_min_fees, vfm_spprt_key,
                                            vfm_merc_code, vfm_date_assessment, vfm_clawback_flag,
                                            vfm_proration_flag, vfm_duration, vfm_feeamnt_type,
                                            vfm_free_txncnt, vfm_intl_indicator, vfm_approve_status,
                                            vfm_pin_sign, vfm_normal_rvsl, vfm_date_start,
                                            vfm_feecap_flag, vfm_max_limit, vfm_maxlmt_freq,
                                            vfm_txnfree_amt, vfm_cap_amt, vfm_crfree_txncnt,
                                            vfm_clawback_count, vfm_clawback_type, vfm_clawback_maxamt,
                                            vfm_assessed_days, vfm_duration_change)
                SELECT cfm_inst_code, cfm_feetype_code, cfm_fee_code,
                       cfm_fee_amt, cfm_fee_desc, cfm_delivery_channel,
                       cfm_tran_type, cfm_tran_code, cfm_tran_mode,
                       cfm_consodium_code, cfm_partner_code, cfm_currency_code,
                       cfm_per_fees, cfm_min_fees, cfm_spprt_key,
                       cfm_merc_code, cfm_date_assessment, cfm_clawback_flag,
                       cfm_proration_flag, cfm_duration, cfm_feeamnt_type,
                       cfm_free_txncnt, cfm_intl_indicator, cfm_approve_status,
                       cfm_pin_sign, cfm_normal_rvsl, cfm_date_start,
                       cfm_feecap_flag, cfm_max_limit, cfm_maxlmt_freq,
                       cfm_txnfree_amt, cfm_cap_amt, cfm_crfree_txncnt,
                       cfm_clawback_count, cfm_clawback_type, cfm_clawback_maxamt,
                       cfm_assessed_days, cfm_duration_change
                  FROM cms_fee_mast
                 WHERE (cfm_inst_code, cfm_fee_code) IN
                          (SELECT cff_inst_code, cff_fee_code
                             FROM cms_fee_feeplan
                            WHERE cff_fee_plan = p_feeplan_in
                                  AND cff_inst_code = p_inst_code_in);
          EXCEPTION
             WHEN OTHERS
             THEN
                p_respmsg_out :='Error while inserting feeplan dtls into vms_fee_mast_stag:'
                   || SUBSTR (SQLERRM, 1, 200);
                RETURN;
          END;
       END IF;
    EXCEPTION
       WHEN OTHERS
       THEN
          p_respmsg_out := 'Main Excp sp_copy_fees:' || SUBSTR (SQLERRM, 1, 200);
    END sp_copy_fees;


    PROCEDURE sp_paste_fees (p_inst_code_in         NUMBER,
                                               p_prod_code_in         VARCHAR2,
                                               p_to_prodcode_in       VARCHAR2,
                                               p_ins_user_in          NUMBER,
                                               p_respmsg_out      OUT VARCHAR2)
    AS
       l_feeplan_id     cms_fee_plan.cfp_plan_id%TYPE;
       l_feeplan_desc   cms_fee_plan.cfp_plan_desc%TYPE;
       l_feecode        cms_fee_mast.cfm_fee_code%TYPE;
       l_exist               VARCHAR2(2);

       TYPE feeplan_typ IS TABLE OF NUMBER
                               INDEX BY PLS_INTEGER;

       feeplan_dtls    feeplan_typ;
    BEGIN
       p_respmsg_out := 'OK';

       FOR l_idx IN (SELECT *
                       FROM vms_feeplan_dtls_stag
                      WHERE vfd_prod_code = p_prod_code_in)
       LOOP
        l_exist:='N';
          IF l_idx.vfd_flow_src = 'P'
          THEN
              BEGIN
                 SELECT seq_plan_id.NEXTVAL INTO l_feeplan_id FROM DUAL;
              EXCEPTION
                 WHEN OTHERS
                 THEN
                    p_respmsg_out :=
                       'Error while getting feeplan seq:' || SUBSTR (SQLERRM, 1, 200);
                    RETURN;
              END;

             BEGIN
                SELECT SUBSTR (cpm_prod_desc, 0, 25) || ' FEE PLAN'
                  INTO l_feeplan_desc
                  FROM cms_prod_mast
                 WHERE cpm_inst_code = p_inst_code_in
                       AND cpm_prod_code = p_prod_code_in;
             EXCEPTION
                WHEN OTHERS
                THEN
                   p_respmsg_out :=
                         'Error while getting product desc:'
                      || p_prod_code_in
                      || '-'
                      || SUBSTR (SQLERRM, 1, 200);
                   RETURN;
             END;

             feeplan_dtls (l_idx.vfd_fee_plan) := l_feeplan_id;

             BEGIN
                INSERT INTO cms_prod_fees (cpf_inst_code,
                                           cpf_prod_code,
                                           cpf_valid_from,
                                           cpf_valid_to,
                                           cpf_flow_source,
                                           cpf_ins_user,
                                           cpf_lupd_user,
                                           cpf_fee_plan,
                                           cpf_ins_date)
                     VALUES (p_inst_code_in,
                             p_to_prodcode_in,
                             TRUNC (SYSDATE),
                             l_idx.vfd_valid_to,
                             'P',
                             p_ins_user_in,
                             p_ins_user_in,
                             l_feeplan_id,
                             SYSDATE);
             EXCEPTION
                WHEN OTHERS
                THEN
                   p_respmsg_out :=
                      'Error while attaching feeplan to product :'
                      || SUBSTR (SQLERRM, 1, 200);
                   RETURN;
             END;
          ELSE
            IF feeplan_dtls.EXISTS (l_idx.vfd_fee_plan) THEN
                l_feeplan_id:=feeplan_dtls (l_idx.vfd_fee_plan);
                l_exist:='Y';
            ELSE
               feeplan_dtls (l_idx.vfd_fee_plan) := l_feeplan_id;
              BEGIN
                 SELECT seq_plan_id.NEXTVAL INTO l_feeplan_id FROM DUAL;
              EXCEPTION
                 WHEN OTHERS
                 THEN
                    p_respmsg_out :=
                       'Error while getting feeplan seq:' || SUBSTR (SQLERRM, 1, 200);
                    RETURN;
              END;
             BEGIN
                SELECT SUBSTR (vpc_cardtype_desc, 0, 25) || ' FEE PLAN'
                  INTO l_feeplan_desc
                  FROM vms_prodcatg_copy_info
                 WHERE vpc_prod_code = p_prod_code_in
                       AND vpc_catg_code = l_idx.vfd_card_type;
             EXCEPTION
                WHEN OTHERS
                THEN
                   p_respmsg_out :=
                         'Error while getting product desc:'
                      || p_prod_code_in
                      || '-'
                      || SUBSTR (SQLERRM, 1, 200);
                   RETURN;
             END;
            END IF;

             BEGIN
                INSERT INTO cms_prodcattype_fees (cpf_inst_code,
                                                  cpf_prod_code,
                                                  cpf_card_type,
                                                  cpf_valid_from,
                                                  cpf_valid_to,
                                                  cpf_flow_source,
                                                  cpf_ins_user,
                                                  cpf_lupd_user,
                                                  cpf_fee_plan,
                                                  cpf_ins_date)
                     VALUES (p_inst_code_in,
                             p_to_prodcode_in,
                             l_idx.vfd_card_type,
                             TRUNC (SYSDATE),
                             l_idx.vfd_valid_to,
                             'PC',
                             p_ins_user_in,
                             p_ins_user_in,
                             l_feeplan_id,
                             SYSDATE);
             EXCEPTION
                WHEN OTHERS
                THEN
                   p_respmsg_out :=
                      'Error while attaching feeplan to product category :'
                      || SUBSTR (SQLERRM, 1, 200);
                   RETURN;
             END;
          END IF;

          IF l_exist='Y'
          THEN
             CONTINUE;
          END IF;

          BEGIN
             INSERT INTO cms_fee_plan (cfp_inst_code,
                                       cfp_plan_id,
                                       cfp_plan_desc,
                                       cfp_ins_user,
                                       cfp_ins_date,
                                       cfp_lupd_date)
                  VALUES (p_inst_code_in,
                          l_feeplan_id,
                          l_feeplan_desc,
                          p_ins_user_in,
                          SYSDATE,
                          SYSDATE);
          EXCEPTION
             WHEN OTHERS
             THEN
                p_respmsg_out :=
                   'Error while inserting feeplan in cms_fee_plan:'
                   || SUBSTR (SQLERRM, 1, 200);
                RETURN;
          END;

          BEGIN
             INSERT INTO cms_feeplan_prod_mapg (cfm_inst_code,
                                                cfm_plan_id,
                                                cfm_prod_code,
                                                cfm_ins_user,
                                                cfm_ins_date)
                  VALUES (p_inst_code_in,
                          l_feeplan_id,
                          p_to_prodcode_in,
                          p_ins_user_in,
                          SYSDATE);
          EXCEPTION
             WHEN OTHERS
             THEN
                p_respmsg_out :=
                   'Error while inserting feeplan mapp in cms_feeplan_prod_mapg'
                   || SUBSTR (SQLERRM, 1, 200);
                RETURN;
          END;

        FOR l_idx_1 IN (SELECT * FROM vms_fee_feeplan_stag WHERE vff_fee_plan = l_idx.vfd_fee_plan)
         LOOP
          BEGIN
             SELECT cct_ctrl_numb
               INTO l_feecode
               FROM cms_ctrl_table
              WHERE cct_ctrl_code = TO_CHAR (p_inst_code_in)
                    AND cct_ctrl_key = 'FEE CODE'
             FOR UPDATE;
          EXCEPTION
             WHEN NO_DATA_FOUND
             THEN
                p_respmsg_out := 'control number not defined for Fee code';
                RETURN;
             WHEN OTHERS
             THEN
                p_respmsg_out :=
                   'Error while Selecting fee control number: '
                   || SUBSTR (SQLERRM, 1, 200);
                RETURN;
          END;

          BEGIN
             INSERT INTO cms_fee_feeplan (cff_inst_code,
                                          cff_fee_code,
                                          cff_fee_plan,
                                          cff_fee_freq,
                                          cff_ins_user,
                                          cff_lupd_user)
                VALUES( p_inst_code_in,
                       l_feecode,
                       l_feeplan_id,
                       l_idx_1.vff_fee_freq,
                       p_ins_user_in,
                       p_ins_user_in);
          EXCEPTION
             WHEN OTHERS
             THEN
                p_respmsg_out :=
                   'Error while inserting feeplan dtls into cms_fee_feeplan:'
                   || SUBSTR (SQLERRM, 1, 200);
                RETURN;
          END;

          BEGIN
             INSERT INTO cms_fee_mast (cfm_inst_code,
                                       cfm_feetype_code,
                                       cfm_fee_code,
                                       cfm_fee_amt,
                                       cfm_fee_desc,
                                       cfm_delivery_channel,
                                       cfm_tran_type,
                                       cfm_tran_code,
                                       cfm_tran_mode,
                                       cfm_consodium_code,
                                       cfm_partner_code,
                                       cfm_currency_code,
                                       cfm_per_fees,
                                       cfm_min_fees,
                                       cfm_spprt_key,
                                       cfm_merc_code,
                                       cfm_date_assessment,
                                       cfm_clawback_flag,
                                       cfm_proration_flag,
                                       cfm_duration,
                                       cfm_feeamnt_type,
                                       cfm_free_txncnt,
                                       cfm_intl_indicator,
                                       cfm_approve_status,
                                       cfm_pin_sign,
                                       cfm_normal_rvsl,
                                       cfm_date_start,
                                       cfm_feecap_flag,
                                       cfm_max_limit,
                                       cfm_maxlmt_freq,
                                       cfm_txnfree_amt,
                                       cfm_cap_amt,
                                       cfm_crfree_txncnt,
                                       cfm_clawback_count,
                                       cfm_clawback_type,
                                       cfm_clawback_maxamt,
                                       cfm_assessed_days,
                                       cfm_duration_change,
                                       cfm_ins_user,
                                       cfm_lupd_user)
                SELECT p_inst_code_in,
                       vfm_feetype_code,
                       l_feecode,
                       vfm_fee_amt,
                       vfm_fee_desc,
                       vfm_delivery_channel,
                       vfm_tran_type,
                       vfm_tran_code,
                       vfm_tran_mode,
                       vfm_consodium_code,
                       vfm_partner_code,
                       vfm_currency_code,
                       vfm_per_fees,
                       vfm_min_fees,
                       vfm_spprt_key,
                       vfm_merc_code,
                       vfm_date_assessment,
                       vfm_clawback_flag,
                       vfm_proration_flag,
                       vfm_duration,
                       vfm_feeamnt_type,
                       vfm_free_txncnt,
                       vfm_intl_indicator,
                       vfm_approve_status,
                       vfm_pin_sign,
                       vfm_normal_rvsl,
                       vfm_date_start,
                       vfm_feecap_flag,
                       vfm_max_limit,
                       vfm_maxlmt_freq,
                       vfm_txnfree_amt,
                       vfm_cap_amt,
                       vfm_crfree_txncnt,
                       vfm_clawback_count,
                       vfm_clawback_type,
                       vfm_clawback_maxamt,
                       vfm_assessed_days,
                       vfm_duration_change,
                       p_ins_user_in,
                       p_ins_user_in
                  FROM vms_fee_mast_stag
                 WHERE vfm_fee_code = l_idx_1.vff_fee_code;
          EXCEPTION
             WHEN OTHERS
             THEN
                p_respmsg_out :=
                   'Error while inserting feeplan dtls into sms_fee_mast:'
                   || SUBSTR (SQLERRM, 1, 200);
                RETURN;
          END;

          BEGIN
             UPDATE cms_ctrl_table
                SET cct_ctrl_numb = cct_ctrl_numb + 1,
                    cct_lupd_user = p_ins_user_in
              WHERE cct_ctrl_code = TO_CHAR (p_inst_code_in)
                    AND cct_ctrl_key = 'FEE CODE';
          EXCEPTION
             WHEN OTHERS
             THEN
                p_respmsg_out :=
                   'Error while updaing fee control number: '
                   || SUBSTR (SQLERRM, 1, 200);
                RETURN;
          END;
         END LOOP;
       END LOOP;
    EXCEPTION
       WHEN OTHERS
       THEN
          p_respmsg_out := 'Main Excp sp_paste_fees:' || SUBSTR (SQLERRM, 1, 200);
    END sp_paste_fees;

--Start fees copy

PROCEDURE SP_FEES_COPY (
   p_instcode_in        IN       NUMBER,
   p_prod_code_in       IN       VARCHAR2,
   p_prod_catg_in       IN       VARCHAR2,
   p_toprod_code_in     IN       VARCHAR2,
   p_ins_user_in        IN       NUMBER,
   p_resp_msg_out       OUT      VARCHAR2
)
IS
   /*************************************************
   * Created Date          :  07-Mar-2016
   * Created By            :  Mageshkumar.S
   * PURPOSE               :  HOSTCC-57
   * Created reason        :  FEES COPY PROGRAM
   * Reviewer              :  SARAVANAKUMAR/SPANKAJ
   * Build Number          :  VMSGPRHOSTCSD4.0_B0001

   * Modified Date         :  24-Mar-2016
   * Modified By           :  Mageshkumar.S
   * PURPOSE               :  MantisId:0016322
   * Reviewer              :  SARAVANAKUMAR/SPANKAJ
   * Build Number          :  VMSGPRHOSTCSD4.0_B0007
   *************************************************/

 --  l_savepoint           NUMBER                              DEFAULT 1;
   exp_reject_record     EXCEPTION;
   --l_tofee_plan          cms_fee_feeplan.cff_fee_plan%TYPE;
   l_count               NUMBER;
   --l_cardtype_cnt        NUMBER;
   --l_to_feeplan          cms_fee_feeplan.cff_fee_plan%TYPE;
   --l_toprod_desc         cms_prod_mast.cpm_prod_desc%type;
   l_from_feeplan        cms_fee_feeplan.cff_fee_plan%TYPE;
   l_valid_todate        cms_prod_fees.CPF_VALID_TO%type;
   l_card_type           CMS_PRODCATTYPE_FEES.CPF_CARD_TYPE%type;
   REF_CURSOR_PRODCATTYPE sys_refcursor;
   --l_fee_plan    cms_fee_feeplan.cff_fee_plan%TYPE;


   /*  TYPE fee_plan_rec IS TABLE OF NUMBER
        INDEX BY PLS_INTEGER;

      fee_plan_dtls    fee_plan_rec;*/
      l_chk_feeplan  NUMBER;

BEGIN
   p_resp_msg_out := 'OK';
 --  SAVEPOINT l_savepoint;


   BEGIN

    SELECT COUNT(1),CPF_FEE_PLAN,CPF_VALID_TO INTO l_count, l_from_feeplan,l_valid_todate
    FROM CMS_PROD_FEES
    WHERE CPF_PROD_CODE = p_prod_code_in
     AND ((cpf_valid_to IS NOT NULL AND (trunc(sysdate) between cpf_valid_from and cpf_valid_to))
    OR (cpf_valid_to IS NULL AND trunc(sysdate) >= cpf_valid_from))
    GROUP BY CPF_FEE_PLAN,CPF_VALID_TO;
    EXCEPTION
    WHEN NO_DATA_FOUND THEN
    NULL;
    WHEN OTHERS THEN
        p_resp_msg_out := 'ERROR WHILE SELECTING FEEPLAN DETAILS FROM CMS_PROD_FEES' ||
                           SUBSTR(SQLERRM, 1, 200);
        RAISE exp_reject_record;

   END;


  IF l_count > 0 THEN

        BEGIN
           sp_copy_fees (p_instcode_in,
                         p_prod_code_in,
                         NULL,
                         l_from_feeplan,
                         l_valid_todate,
                         'P',
                         p_resp_msg_out);

           IF p_resp_msg_out <> 'OK'
           THEN
              RAISE exp_reject_record;
           END IF;
        EXCEPTION
           WHEN exp_reject_record
           THEN
              RAISE;
           WHEN OTHERS
           THEN
              p_resp_msg_out :=
                 'Error while calling sp_copy_fees process:'
                 || SUBSTR (SQLERRM, 1, 200);
              RAISE exp_reject_record;
        END;

       BEGIN

          OPEN REF_CURSOR_PRODCATTYPE FOR
          'SELECT CPF_FEE_PLAN,CPF_VALID_TO,CPF_CARD_TYPE
          FROM CMS_PRODCATTYPE_FEES
          WHERE CPF_PROD_CODE = '''||p_prod_code_in||'''
          AND cpf_card_type IN('||p_prod_catg_in||')
          AND CPF_VALID_TO IS NULL OR CPF_VALID_TO > SYSDATE';
          LOOP
          FETCH REF_CURSOR_PRODCATTYPE INTO l_from_feeplan,l_valid_todate,l_card_type;
          EXIT WHEN REF_CURSOR_PRODCATTYPE%NOTFOUND;

                BEGIN
                   SELECT COUNT (1)
                     INTO l_chk_feeplan
                     FROM vms_feeplan_dtls_stag
                    WHERE vfd_fee_plan = l_from_feeplan;
                EXCEPTION
                   WHEN OTHERS
                   THEN
                      p_resp_msg_out :=
                         'Error while checking feeplan count:' || SUBSTR (SQLERRM, 1, 200);
                      RAISE exp_reject_record;
                END;

                BEGIN
                   sp_copy_fees (p_instcode_in,
                                 p_prod_code_in,
                                 l_card_type,
                                 l_from_feeplan,
                                 l_valid_todate,
                                 'PC',
                                 p_resp_msg_out,
                                 l_chk_feeplan);

                   IF p_resp_msg_out <> 'OK'
                   THEN
                      RAISE exp_reject_record;
                   END IF;
                EXCEPTION
                   WHEN exp_reject_record
                   THEN
                      RAISE;
                   WHEN OTHERS
                   THEN
                      p_resp_msg_out :=
                         'Error while calling sp_copy_fees process:'
                         || SUBSTR (SQLERRM, 1, 200);
                      RAISE exp_reject_record;
                END;
          END LOOP;
          EXCEPTION
 --         WHEN NO_DATA_FOUND THEN
 --         NULL;
              when EXP_REJECT_RECORD then
                RAISE;
              WHEN OTHERS THEN
              p_resp_msg_out := 'ERROR WHILE SELECTING FEEPLAN DETAILS FROM CMS_PRODCATTYPE_FEES' || p_resp_msg_out ||
                                 SUBSTR(SQLERRM, 1, 200);
              RAISE exp_reject_record;

         END;


 END IF;

EXCEPTION --<< MAIN EXCEPTION >>
   WHEN exp_reject_record
   THEN
      ROLLBACK;-- TO l_savepoint;
   WHEN OTHERS THEN
     p_resp_msg_out := 'Main Excp--'|| SUBSTR (SQLERRM, 1, 200);
END;

--End fees copy

    PROCEDURE sp_copy_lmts (
       p_instcode_in        NUMBER,
       p_prod_code_in       VARCHAR2,
       p_prodcatg_in        NUMBER,
       p_lmt_prfl           VARCHAR2,
       p_lmt_name           VARCHAR2,
       p_lmt_flag           VARCHAR2,
       p_flow_src_in        VARCHAR2,
       p_respmsg_out    OUT VARCHAR2,
       p_exist_flag         NUMBER DEFAULT 0)
    IS
    BEGIN
       p_respmsg_out := 'OK';

       BEGIN
          INSERT INTO vms_lmtprfl_dtls_stag (vld_inst_code,
                                             vld_lmt_prfl,
                                             vld_lmtprfl_name,
                                             vld_lmtact_flag,
                                             vld_prod_code,
                                             vld_card_type,
                                             vld_flow_src)
               VALUES (p_instcode_in,
                       p_lmt_prfl,
                       p_lmt_name,
                       p_lmt_flag,
                       p_prod_code_in,
                       p_prodcatg_in,
                       p_flow_src_in);
       EXCEPTION
          WHEN OTHERS
          THEN
             p_respmsg_out :=
                'Error while inserting lmtprfl dtls into vms_lmtprfl_dtls_stag:'
                || SUBSTR (SQLERRM, 1, 200);
             RETURN;
       END;

       IF p_exist_flag = 0
       THEN
          BEGIN
             INSERT INTO vms_limit_prfl_stag (vlp_inst_code,
                                              vlp_lmtprfl_id,
                                              vlp_dlvr_chnl,
                                              vlp_tran_code,
                                              vlp_tran_type,
                                              vlp_intl_flag,
                                              vlp_pnsign_flag,
                                              vlp_mcc_code,
                                              vlp_trfr_crdacnt,
                                              vlp_pertxn_minamnt,
                                              vlp_pertxn_maxamnt,
                                              vlp_dmax_txncnt,
                                              vlp_dmax_txnamnt,
                                              vlp_wmax_txncnt,
                                              vlp_wmax_txnamnt,
                                              vlp_mmax_txncnt,
                                              vlp_mmax_txnamnt,
                                              vlp_ymax_txncnt,
                                              vlp_ymax_txnamnt,
                                              vlp_payment_type)
                SELECT p_instcode_in,
                       clp_lmtprfl_id,
                       clp_dlvr_chnl,
                       clp_tran_code,
                       clp_tran_type,
                       clp_intl_flag,
                       clp_pnsign_flag,
                       clp_mcc_code,
                       clp_trfr_crdacnt,
                       clp_pertxn_minamnt,
                       clp_pertxn_maxamnt,
                       clp_dmax_txncnt,
                       clp_dmax_txnamnt,
                       clp_wmax_txncnt,
                       clp_wmax_txnamnt,
                       clp_mmax_txncnt,
                       clp_mmax_txnamnt,
                       clp_ymax_txncnt,
                       clp_ymax_txnamnt,
                       clp_payment_type
                  FROM cms_limit_prfl
                 WHERE clp_lmtprfl_id = p_lmt_prfl;
          EXCEPTION
             WHEN OTHERS
             THEN
                p_respmsg_out :=
                   'Error while inserting lmtprfl into vms_limit_prfl_stag:'
                   || SUBSTR (SQLERRM, 1, 200);
                RETURN;
          END;

          BEGIN
             INSERT INTO vms_group_limit_stag (vgl_inst_code,
                                               vgl_lmtprfl_id,
                                               vgl_group_code,
                                               vgl_group_name,
                                               vgl_pertxn_minamnt,
                                               vgl_pertxn_maxamnt,
                                               vgl_dmax_txncnt,
                                               vgl_dmax_txnamnt,
                                               vgl_wmax_txncnt,
                                               vgl_wmax_txnamnt,
                                               vgl_mmax_txncnt,
                                               vgl_mmax_txnamnt,
                                               vgl_ymax_txncnt,
                                               vgl_ymax_txnamnt)
                SELECT p_instcode_in,
                       cgl_lmtprfl_id,
                       cgm_limitgl_code,
                       SUBSTR (cgm_limitgl_name, 1, 40),
                       cgl_pertxn_minamnt,
                       cgl_pertxn_maxamnt,
                       cgl_dmax_txncnt,
                       cgl_dmax_txnamnt,
                       cgl_wmax_txncnt,
                       cgl_wmax_txnamnt,
                       cgl_mmax_txncnt,
                       cgl_mmax_txnamnt,
                       cgl_ymax_txncnt,
                       cgl_ymax_txnamnt
                  FROM cms_group_limit, cms_grplmt_mast
                 WHERE cgl_group_code = cgm_limitgl_code
                       AND cgl_lmtprfl_id = p_lmt_prfl;
          EXCEPTION
             WHEN OTHERS
             THEN
                p_respmsg_out :=
                   'Error while inserting grp lmtprfl dtls into vms_group_limit_stag:'
                   || SUBSTR (SQLERRM, 1, 200);
                RETURN;
          END;

          BEGIN
             INSERT INTO vms_grplmt_param_stag (vgp_inst_code,
                                                vgp_group_code,
                                                vgp_limit_prfl,
                                                vgp_dlvr_chnl,
                                                vgp_tran_code,
                                                vgp_intl_flag,
                                                vgp_pnsign_flag,
                                                vgp_mcc_code,
                                                vgp_trfr_crdacnt,
                                                vgp_payment_type)
                SELECT p_instcode_in,
                       cgp_group_code,
                       cgp_limit_prfl,
                       cgp_dlvr_chnl,
                       cgp_tran_code,
                       cgp_intl_flag,
                       cgp_pnsign_flag,
                       cgp_mcc_code,
                       cgp_trfr_crdacnt,
                       cgp_payment_type
                  FROM cms_grplmt_param
                 WHERE cgp_limit_prfl = p_lmt_prfl
                       AND cgp_group_code IN (SELECT cgl_group_code
                                                FROM cms_group_limit
                                               WHERE cgl_lmtprfl_id = p_lmt_prfl);
          END;
       END IF;
    EXCEPTION
       WHEN OTHERS
       THEN
          p_respmsg_out := 'Main Excp sp_copy_fees:' || SUBSTR (SQLERRM, 1, 200);
    END sp_copy_lmts;

    PROCEDURE sp_paste_lmts (p_inst_code_in         NUMBER,
                                               p_prod_code_in         VARCHAR2,
                                               p_to_prodcode_in       VARCHAR2,
                                               p_ins_user_in          NUMBER,
                                               p_respmsg_out      OUT VARCHAR2)
    AS
       l_limit_prfl     cms_lmtprfl_mast.clm_lmtprfl_id%TYPE;
       l_lmtgrup_code   cms_grplmt_mast.cgm_limitgl_code%TYPE;
       l_tran_type      cms_transaction_mast.ctm_tran_type%TYPE;
        l_exist              VARCHAR2(2);

       TYPE lmtprfl_typ IS TABLE OF NUMBER
                              INDEX BY PLS_INTEGER;

       lmtprfl_dtls     lmtprfl_typ;
    BEGIN
       p_respmsg_out := 'OK';

       FOR l_idx IN (SELECT *
                       FROM vms_lmtprfl_dtls_stag
                      WHERE vld_prod_code = p_prod_code_in)
       LOOP
        l_exist:='N';
          IF l_idx.vld_flow_src = 'P'
          THEN
             BEGIN
                SELECT 'L' || SUBSTR (seq_profile_code.NEXTVAL, 2, 4)
                  INTO l_limit_prfl
                  FROM DUAL;
             EXCEPTION
                WHEN OTHERS
                THEN
                   p_respmsg_out :=
                      'Error while getting lmtprfl seq:'
                      || SUBSTR (SQLERRM, 1, 200);
                   RETURN;
             END;

             lmtprfl_dtls (l_idx.vld_lmt_prfl) := l_limit_prfl;

             BEGIN
                INSERT INTO cms_lmtprfl_mast (clm_inst_code,
                                              clm_lmtprfl_id,
                                              clm_lmtprfl_name,
                                              clm_active_flag,
                                              clm_lupd_date,
                                              clm_lupd_user,
                                              clm_ins_date,
                                              clm_ins_user)
                     VALUES (p_inst_code_in,
                             l_limit_prfl,
                             l_idx.vld_lmtprfl_name || '-' || l_limit_prfl,
                             l_idx.vld_lmtact_flag,
                             SYSDATE,
                             p_ins_user_in,
                             SYSDATE,
                             p_ins_user_in);
             EXCEPTION
                WHEN OTHERS
                THEN
                   p_respmsg_out :=
                      'Error while inserting lmtprfl in cms_lmtprfl_mast:'
                      || SUBSTR (SQLERRM, 1, 200);
                   RETURN;
             END;

             BEGIN
                INSERT INTO cms_prod_lmtprfl (cpl_inst_code,
                                              cpl_prod_code,
                                              cpl_lmtprfl_id,
                                              cpl_lupd_date,
                                              cpl_lupd_user,
                                              cpl_ins_date,
                                              cpl_ins_user)
                     VALUES (p_inst_code_in,
                             p_to_prodcode_in,
                             l_limit_prfl,
                             SYSDATE,
                             p_ins_user_in,
                             SYSDATE,
                             p_ins_user_in);
             EXCEPTION
                WHEN OTHERS
                THEN
                   p_respmsg_out :=
                      'Error while attaching lmtprfl to product :'
                      || SUBSTR (SQLERRM, 1, 200);
                   RETURN;
             END;
          ELSE
             IF lmtprfl_dtls.EXISTS (l_idx.vld_lmt_prfl)
             THEN
                l_limit_prfl:=lmtprfl_dtls (l_idx.vld_lmt_prfl);
                l_exist:='Y';
             ELSE
                lmtprfl_dtls (l_idx.vld_lmt_prfl) := l_limit_prfl;

                BEGIN
                   INSERT INTO cms_lmtprfl_mast (clm_inst_code,
                                                 clm_lmtprfl_id,
                                                 clm_lmtprfl_name,
                                                 clm_active_flag,
                                                 clm_lupd_date,
                                                 clm_lupd_user,
                                                 clm_ins_date,
                                                 clm_ins_user)
                        VALUES (p_inst_code_in,
                                l_limit_prfl,
                                l_idx.vld_lmtprfl_name || '-' || l_limit_prfl,
                                l_idx.vld_lmtact_flag,
                                SYSDATE,
                                p_ins_user_in,
                                SYSDATE,
                                p_ins_user_in);
                EXCEPTION
                   WHEN OTHERS
                   THEN
                      p_respmsg_out :=
                         'Error while inserting lmtprfl in cms_lmtprfl_mast:'
                         || SUBSTR (SQLERRM, 1, 200);
                      RETURN;
                END;

                BEGIN
                   SELECT 'L' || SUBSTR (seq_profile_code.NEXTVAL, 2, 4)
                     INTO l_limit_prfl
                     FROM DUAL;
                EXCEPTION
                   WHEN OTHERS
                   THEN
                      p_respmsg_out :=
                         'Error while getting lmtprfl seq:'
                         || SUBSTR (SQLERRM, 1, 200);
                      RETURN;
                END;
             END IF;

             BEGIN
                INSERT INTO cms_prdcattype_lmtprfl (cpl_inst_code,
                                                    cpl_prod_code,
                                                    cpl_card_type,
                                                    cpl_lmtprfl_id,
                                                    cpl_lupd_date,
                                                    cpl_lupd_user,
                                                    cpl_ins_date,
                                                    cpl_ins_user)
                     VALUES (p_inst_code_in,
                             p_to_prodcode_in,
                             l_idx.vld_card_type,
                             l_limit_prfl,
                             SYSDATE,
                             p_ins_user_in,
                             SYSDATE,
                             p_ins_user_in);
             EXCEPTION
                WHEN OTHERS
                THEN
                   p_respmsg_out :=
                      'Error while attaching lmtprfl to product category :'
                      || SUBSTR (SQLERRM, 1, 200);
                   RETURN;
             END;
          END IF;

          IF l_exist='Y'
          THEN
             CONTINUE;
          END IF;

          BEGIN
             INSERT INTO cms_limit_prfl (clp_inst_code,
                                         clp_lmtprfl_id,
                                         clp_dlvr_chnl,
                                         clp_tran_code,
                                         clp_tran_type,
                                         clp_intl_flag,
                                         clp_pnsign_flag,
                                         clp_mcc_code,
                                         clp_trfr_crdacnt,
                                         clp_comb_hash,
                                         clp_pertxn_minamnt,
                                         clp_pertxn_maxamnt,
                                         clp_dmax_txncnt,
                                         clp_dmax_txnamnt,
                                         clp_wmax_txncnt,
                                         clp_wmax_txnamnt,
                                         clp_mmax_txncnt,
                                         clp_mmax_txnamnt,
                                         clp_ymax_txncnt,
                                         clp_ymax_txnamnt,
                                         clp_lupd_date,
                                         clp_lupd_user,
                                         clp_ins_date,
                                         clp_ins_user,
                                         clp_payment_type)
                SELECT p_inst_code_in,
                       l_limit_prfl,
                       vlp_dlvr_chnl,
                       vlp_tran_code,
                       vlp_tran_type,
                       vlp_intl_flag,
                       vlp_pnsign_flag,
                       vlp_mcc_code,
                       vlp_trfr_crdacnt,
                       gethash (
                             l_limit_prfl
                          || vlp_dlvr_chnl
                          || vlp_tran_code
                          || vlp_tran_type
                          || vlp_intl_flag
                          || vlp_pnsign_flag
                          || vlp_mcc_code
                          || vlp_trfr_crdacnt
                          || vlp_payment_type),
                       vlp_pertxn_minamnt,
                       vlp_pertxn_maxamnt,
                       vlp_dmax_txncnt,
                       vlp_dmax_txnamnt,
                       vlp_wmax_txncnt,
                       vlp_wmax_txnamnt,
                       vlp_mmax_txncnt,
                       vlp_mmax_txnamnt,
                       vlp_ymax_txncnt,
                       vlp_ymax_txnamnt,
                       SYSDATE,
                       p_ins_user_in,
                       SYSDATE,
                       p_ins_user_in,
                       vlp_payment_type
                  FROM vms_limit_prfl_stag
                 WHERE vlp_lmtprfl_id = l_idx.vld_lmt_prfl;
          EXCEPTION
             WHEN OTHERS
             THEN
                p_respmsg_out :=
                   'Error while inserting lmtprfl into cms_limit_prfl:'
                   || SUBSTR (SQLERRM, 1, 200);
                RETURN;
          END;

          FOR l_idx_1 IN (SELECT *
                            FROM vms_group_limit_stag
                           WHERE vgl_lmtprfl_id = l_idx.vld_lmt_prfl)
          LOOP
             BEGIN
                SELECT 'LG' || SUBSTR (seq_transactiongroup_code.NEXTVAL, 1, 3)
                  INTO l_lmtgrup_code
                  FROM DUAL;
             EXCEPTION
                WHEN OTHERS
                THEN
                   p_respmsg_out :=
                      'Error while getting group seq:'
                      || SUBSTR (SQLERRM, 1, 300);
                   RETURN;
             END;

             BEGIN
                INSERT INTO cms_grplmt_mast (cgm_inst_code,
                                             cgm_limitgl_code,
                                             cgm_limitgl_name,
                                             cgm_ins_date,
                                             cgm_ins_user)
                     VALUES (p_inst_code_in,
                             l_lmtgrup_code,
                             l_idx_1.vgl_group_name || '-' || l_lmtgrup_code,
                             SYSDATE,
                             p_ins_user_in);
             EXCEPTION
                WHEN OTHERS
                THEN
                   p_respmsg_out :=
                      'Error while inserting into cms_grplmt_mast:'
                      || SUBSTR (SQLERRM, 1, 200);
                   RETURN;
             END;

             BEGIN
                INSERT INTO cms_group_limit (cgl_inst_code,
                                             cgl_lmtprfl_id,
                                             cgl_group_code,
                                             cgl_grplmt_hash,
                                             cgl_pertxn_minamnt,
                                             cgl_pertxn_maxamnt,
                                             cgl_dmax_txncnt,
                                             cgl_dmax_txnamnt,
                                             cgl_wmax_txncnt,
                                             cgl_wmax_txnamnt,
                                             cgl_mmax_txncnt,
                                             cgl_mmax_txnamnt,
                                             cgl_ymax_txncnt,
                                             cgl_ymax_txnamnt,
                                             cgl_lupd_date,
                                             cgl_lupd_user,
                                             cgl_ins_date,
                                             cgl_ins_user)
                     VALUES (p_inst_code_in,
                             l_limit_prfl,
                             l_lmtgrup_code,
                             gethash (l_lmtgrup_code || l_limit_prfl),
                             l_idx_1.vgl_pertxn_minamnt,
                             l_idx_1.vgl_pertxn_maxamnt,
                             l_idx_1.vgl_dmax_txncnt,
                             l_idx_1.vgl_dmax_txnamnt,
                             l_idx_1.vgl_wmax_txncnt,
                             l_idx_1.vgl_wmax_txnamnt,
                             l_idx_1.vgl_mmax_txncnt,
                             l_idx_1.vgl_mmax_txnamnt,
                             l_idx_1.vgl_ymax_txncnt,
                             l_idx_1.vgl_ymax_txnamnt,
                             SYSDATE,
                             p_ins_user_in,
                             SYSDATE,
                             p_ins_user_in);
             EXCEPTION
                WHEN OTHERS
                THEN
                   p_respmsg_out :=
                      'Error while inserting into cms_group_limit:'
                      || SUBSTR (SQLERRM, 1, 200);
                   RETURN;
             END;
          END LOOP;

          FOR l_idx_2 IN (SELECT *
                            FROM vms_grplmt_param_stag
                           WHERE vgp_limit_prfl = l_idx.vld_lmt_prfl)
          LOOP
             BEGIN
                SELECT ctm_tran_type
                  INTO l_tran_type
                  FROM cms_transaction_mast
                 WHERE     ctm_delivery_channel = l_idx_2.vgp_dlvr_chnl
                       AND ctm_tran_code = l_idx_2.vgp_tran_code
                       AND ctm_inst_code = p_inst_code_in;
             EXCEPTION
                WHEN OTHERS
                THEN
                   p_respmsg_out :=
                      'Error while selecting from transaction detls:'
                      || SUBSTR (SQLERRM, 1, 300);
                   RETURN;
             END;

             BEGIN
                INSERT INTO cms_grplmt_param (cgp_inst_code,
                                              cgp_group_code,
                                              cgp_limit_prfl,
                                              cgp_dlvr_chnl,
                                              cgp_tran_code,
                                              cgp_intl_flag,
                                              cgp_pnsign_flag,
                                              cgp_mcc_code,
                                              cgp_trfr_crdacnt,
                                              cgp_grpcomb_hash,
                                              cgp_lupd_date,
                                              cgp_lupd_user,
                                              cgp_ins_date,
                                              cgp_ins_user,
                                              cgp_payment_type)
                     VALUES (
                               p_inst_code_in,
                               l_idx_2.vgp_group_code,
                               l_limit_prfl,
                               l_idx_2.vgp_dlvr_chnl,
                               l_idx_2.vgp_tran_code,
                               l_idx_2.vgp_intl_flag,
                               l_idx_2.vgp_pnsign_flag,
                               l_idx_2.vgp_mcc_code,
                               l_idx_2.vgp_trfr_crdacnt,
                               GETHASH (
                                     l_limit_prfl
                                  || l_idx_2.vgp_dlvr_chnl
                                  || l_idx_2.vgp_tran_code
                                  || l_tran_type
                                  || l_idx_2.vgp_intl_flag
                                  || l_idx_2.vgp_pnsign_flag
                                  || l_idx_2.vgp_mcc_code
                                  || l_idx_2.vgp_trfr_crdacnt
                                  || DECODE (l_idx_2.vgp_payment_type,
                                             'NA', '',
                                             l_idx_2.vgp_payment_type)),
                               SYSDATE,
                               p_ins_user_in,
                               SYSDATE,
                               p_ins_user_in,
                               l_idx_2.vgp_payment_type);
             EXCEPTION
                WHEN OTHERS
                THEN
                   p_respmsg_out :=
                      'Error while inserting into cms_grplmt_param:'
                      || SUBSTR (SQLERRM, 1, 300);
                   RETURN;
             END;
          END LOOP;
       END LOOP;
    EXCEPTION
       WHEN OTHERS
       THEN
          p_respmsg_out := 'Main Excp sp_paste_lmts:' || SUBSTR (SQLERRM, 1, 200);
    END sp_paste_lmts;
--Start limit profile copy

PROCEDURE SP_LMTPRFL_COPY (
   p_instcode_in        IN       NUMBER,
   p_lmtprfl_id         IN       VARCHAR2,
   p_new_lmtprfl_id     IN       VARCHAR2,
   p_ins_user_in        IN       NUMBER,
   p_resp_msg_out       OUT      VARCHAR2
)
IS
   /*************************************************
   * Created Date          :  07-Mar-2016
   * Created By            :  Mageshkumar.S
   * PURPOSE               :  HOSTCC-57
   * Created reason        :  LIMITS COPY PROGRAM
   * Reviewer              :  SARAVANAKUMAR/SPANKAJ
   * Build Number          :  VMSGPRHOSTCSD4.0_B0001
   *************************************************/

 --  l_savepoint           NUMBER                              DEFAULT 1;
   exp_reject_record     EXCEPTION;
   l_prod_lmtprfl_id     CMS_PROD_LMTPRFL.CPL_LMTPRFL_ID%type;
   l_count               PLS_INTEGER;
   l_newprfl_code        CMS_PROD_LMTPRFL.CPL_LMTPRFL_ID%type;
   l_lmtprfl_name        CMS_LMTPRFL_MAST.CLM_LMTPRFL_NAME%type;
   l_lmtact_flag         CMS_LMTPRFL_MAST.CLM_ACTIVE_FLAG%type;
   l_grup_code           cms_grplmt_mast.cgm_limitgl_code%type;
   l_tran_type           cms_transaction_mast.ctm_tran_type%type;
   l_card_type           cms_prdcattype_lmtprfl.cpl_card_type%type;
   REF_CURSOR_PRODCATG_LMTPRFL SYS_REFCURSOR;

   CURSOR C1(l_prod_lmtprfl_id IN VARCHAR2)
   IS
   SELECT
   CLP_LMTPRFL_ID,CLP_DLVR_CHNL,CLP_TRAN_CODE,CLP_TRAN_TYPE,
   CLP_INTL_FLAG,CLP_PNSIGN_FLAG,CLP_MCC_CODE,CLP_TRFR_CRDACNT,
   CLP_PERTXN_MINAMNT,CLP_PERTXN_MAXAMNT,CLP_DMAX_TXNCNT,
   CLP_DMAX_TXNAMNT,CLP_WMAX_TXNCNT,CLP_WMAX_TXNAMNT,CLP_MMAX_TXNCNT,
   CLP_MMAX_TXNAMNT,CLP_YMAX_TXNCNT,CLP_YMAX_TXNAMNT,CLP_PAYMENT_TYPE
   FROM CMS_LIMIT_PRFL
   WHERE CLP_LMTPRFL_ID = l_prod_lmtprfl_id;

   CURSOR C2(l_prod_lmtprfl_id IN VARCHAR2)
   IS
    SELECT  CGM_LIMITGL_CODE,substr(CGM_LIMITGL_NAME,1,40) CGM_LIMITGL_NAME,
            CGL_PERTXN_MINAMNT,CGL_PERTXN_MAXAMNT,CGL_DMAX_TXNCNT,CGL_DMAX_TXNAMNT,
            CGL_WMAX_TXNCNT,CGL_WMAX_TXNAMNT,CGL_MMAX_TXNCNT,
            CGL_MMAX_TXNAMNT,CGL_YMAX_TXNCNT,CGL_YMAX_TXNAMNT
            FROM CMS_GROUP_LIMIT,CMS_GRPLMT_MAST
            WHERE CGL_GROUP_CODE = CGM_LIMITGL_CODE
            AND CGL_LMTPRFL_ID = l_prod_lmtprfl_id;

    CURSOR C3(l_prod_lmtprfl_id IN VARCHAR2,l_grup_code IN VARCHAR2)
    IS
    SELECT
          CGP_GROUP_CODE,CGP_LIMIT_PRFL,
          CGP_DLVR_CHNL,CGP_TRAN_CODE,CGP_INTL_FLAG,CGP_PNSIGN_FLAG,
          CGP_MCC_CODE,CGP_TRFR_CRDACNT,CGP_GRPCOMB_HASH,CGP_PAYMENT_TYPE
          FROM CMS_GRPLMT_PARAM
          WHERE CGP_LIMIT_PRFL = l_prod_lmtprfl_id
         AND CGP_GROUP_CODE = l_grup_code;


BEGIN
   p_resp_msg_out := 'OK';
 --  SAVEPOINT l_savepoint;



       BEGIN
                FOR l_row_indx IN C1(p_lmtprfl_id)
                LOOP
                INSERT INTO CMS_LIMIT_PRFL(
                        CLP_INST_CODE,
                        CLP_LMTPRFL_ID,CLP_DLVR_CHNL,CLP_TRAN_CODE,CLP_TRAN_TYPE,
                        CLP_INTL_FLAG,CLP_PNSIGN_FLAG,CLP_MCC_CODE,CLP_TRFR_CRDACNT,
                        CLP_COMB_HASH,CLP_PERTXN_MINAMNT,CLP_PERTXN_MAXAMNT,CLP_DMAX_TXNCNT,
                        CLP_DMAX_TXNAMNT,CLP_WMAX_TXNCNT,CLP_WMAX_TXNAMNT,CLP_MMAX_TXNCNT,
                        CLP_MMAX_TXNAMNT,CLP_YMAX_TXNCNT,CLP_YMAX_TXNAMNT,CLP_LUPD_DATE,
                        CLP_LUPD_USER,CLP_INS_DATE,CLP_INS_USER,CLP_PAYMENT_TYPE)
                        VALUES(
                        p_instcode_in,p_new_lmtprfl_id,l_row_indx.CLP_DLVR_CHNL,
                        l_row_indx.CLP_TRAN_CODE,l_row_indx.CLP_TRAN_TYPE,l_row_indx.CLP_INTL_FLAG,
                        l_row_indx.CLP_PNSIGN_FLAG,l_row_indx.CLP_MCC_CODE,l_row_indx.CLP_TRFR_CRDACNT,
                        gethash(p_new_lmtprfl_id||l_row_indx.CLP_DLVR_CHNL||l_row_indx.CLP_TRAN_CODE||l_row_indx.CLP_TRAN_TYPE
                        ||l_row_indx.CLP_INTL_FLAG||l_row_indx.CLP_PNSIGN_FLAG||l_row_indx.CLP_MCC_CODE||l_row_indx.CLP_TRFR_CRDACNT
                        ||l_row_indx.CLP_PAYMENT_TYPE),
                        l_row_indx.CLP_PERTXN_MINAMNT,
                        l_row_indx.CLP_PERTXN_MAXAMNT,l_row_indx.CLP_DMAX_TXNCNT,l_row_indx.CLP_DMAX_TXNAMNT,
                        l_row_indx.CLP_WMAX_TXNCNT,l_row_indx.CLP_WMAX_TXNAMNT,l_row_indx.CLP_MMAX_TXNCNT,
                        l_row_indx.CLP_MMAX_TXNAMNT,l_row_indx.CLP_YMAX_TXNCNT,l_row_indx.CLP_YMAX_TXNAMNT,
                        SYSDATE,p_ins_user_in,SYSDATE,p_ins_user_in,l_row_indx.CLP_PAYMENT_TYPE);

                END LOOP;
                EXCEPTION
                WHEN OTHERS
                THEN
                   p_resp_msg_out :=
                         'ERROR WHILE INSERTING INTO CMS_LIMIT_PRFL:'
                      || SUBSTR (SQLERRM, 1, 300);
                   RAISE EXP_REJECT_RECORD;

     END;

 --l_grup_code varchar;

  BEGIN

            FOR l_row_indx IN C2(p_lmtprfl_id)
            LOOP

            BEGIN

            SELECT 'LG'||SUBSTR(SEQ_TRANSACTIONGROUP_CODE.nextval,1,3) INTO l_grup_code from dual;
            EXCEPTION
            WHEN OTHERS THEN
            p_resp_msg_out :='ERROR WHILE GETTING GROUP SEQ:'
                  || SUBSTR (SQLERRM, 1, 300);
            RAISE EXP_REJECT_RECORD;

            END;

            BEGIN

            INSERT INTO CMS_GRPLMT_MAST(CGM_INST_CODE,
                                        CGM_LIMITGL_CODE,
                                        CGM_LIMITGL_NAME,
                                        CGM_INS_DATE,
                                        CGM_INS_USER)
                                        VALUES(p_instcode_in,
                                        l_grup_code,
                                        l_row_indx.CGM_LIMITGL_NAME||'-'||l_grup_code,
                                        SYSDATE,
                                        p_ins_user_in);
            EXCEPTION
            WHEN OTHERS THEN
            p_resp_msg_out :='ERROR WHILE INSERTING CMS_GRPLMT_MAST:'
                  || SUBSTR (SQLERRM, 1, 300);
            RAISE EXP_REJECT_RECORD;

            END;

            BEGIN

            INSERT INTO CMS_GROUP_LIMIT(
                                        CGL_INST_CODE,CGL_LMTPRFL_ID,
                                        CGL_GROUP_CODE,CGL_GRPLMT_HASH,CGL_PERTXN_MINAMNT,CGL_PERTXN_MAXAMNT,
                                        CGL_DMAX_TXNCNT,CGL_DMAX_TXNAMNT,CGL_WMAX_TXNCNT,CGL_WMAX_TXNAMNT,
                                        CGL_MMAX_TXNCNT,CGL_MMAX_TXNAMNT,CGL_YMAX_TXNCNT,CGL_YMAX_TXNAMNT,
                                        CGL_LUPD_DATE,CGL_LUPD_USER,CGL_INS_DATE,CGL_INS_USER)
                                        VALUES(
                                        p_instcode_in,p_new_lmtprfl_id,
                                        l_grup_code,
                                        GETHASH(l_grup_code||p_new_lmtprfl_id),
                                        l_row_indx.CGL_PERTXN_MINAMNT,
                                        l_row_indx.CGL_PERTXN_MAXAMNT,
                                        l_row_indx.CGL_DMAX_TXNCNT,
                                        l_row_indx.CGL_DMAX_TXNAMNT,
                                        l_row_indx.CGL_WMAX_TXNCNT,
                                        l_row_indx.CGL_WMAX_TXNAMNT,
                                        l_row_indx.CGL_MMAX_TXNCNT,
                                        l_row_indx.CGL_MMAX_TXNAMNT,
                                        l_row_indx.CGL_YMAX_TXNCNT,
                                        l_row_indx.CGL_YMAX_TXNAMNT,
                                        SYSDATE,p_ins_user_in,SYSDATE,p_ins_user_in);
            EXCEPTION
            WHEN OTHERS THEN
            p_resp_msg_out :='ERROR WHILE INSERTING CMS_GROUP_LIMIT:'
                  || SUBSTR (SQLERRM, 1, 300);
            RAISE EXP_REJECT_RECORD;

            END;


          BEGIN

           FOR l_grp_lmtparam IN C3(p_lmtprfl_id,l_row_indx.CGM_LIMITGL_CODE)
            LOOP

            BEGIN

            SELECT ctm_tran_type INTO l_tran_type from cms_transaction_mast,CMS_GRPLMT_PARAM
            WHERE ctm_delivery_channel = cgp_dlvr_chnl AND ctm_tran_code =cgp_tran_code
            AND ctm_inst_code = cgp_inst_code  and --cgp_group_code=l_row_indx.CGM_LIMITGL_CODE/*l_grup_code*/ and
       --     cgp_group_code=l_grp_lmtparam.cgp_group_code AND
            CGP_LIMIT_PRFL =p_lmtprfl_id
            and CGP_GRPCOMB_HASH=l_grp_lmtparam.CGP_GRPCOMB_HASH;
            EXCEPTION
            WHEN OTHERS THEN
            p_resp_msg_out :='ERROR WHILE SELECTING FROM TRANSACTION DETLS:'
                  || SUBSTR (SQLERRM, 1, 300);
            RAISE EXP_REJECT_RECORD;


            END;

            BEGIN

            INSERT INTO CMS_GRPLMT_PARAM(CGP_INST_CODE,
                                        CGP_GROUP_CODE,
                                        CGP_LIMIT_PRFL,
                                        CGP_DLVR_CHNL,
                                        CGP_TRAN_CODE,
                                        CGP_INTL_FLAG,
                                        CGP_PNSIGN_FLAG,
                                        CGP_MCC_CODE,
                                        CGP_TRFR_CRDACNT,
                                        CGP_GRPCOMB_HASH,
                                        CGP_LUPD_DATE,
                                        CGP_LUPD_USER,
                                        CGP_INS_DATE,
                                        CGP_INS_USER,
                                        CGP_PAYMENT_TYPE)
                                        VALUES(p_instcode_in,
                                        l_grup_code,
                                        p_new_lmtprfl_id,
                                        l_grp_lmtparam.CGP_DLVR_CHNL,
                                        l_grp_lmtparam.CGP_TRAN_CODE,
                                        l_grp_lmtparam.CGP_INTL_FLAG,
                                        l_grp_lmtparam.CGP_PNSIGN_FLAG,
                                        l_grp_lmtparam.CGP_MCC_CODE,
                                        l_grp_lmtparam.CGP_TRFR_CRDACNT,
                                        GETHASH(p_new_lmtprfl_id||l_grp_lmtparam.CGP_DLVR_CHNL||l_grp_lmtparam.CGP_TRAN_CODE
                                        ||l_tran_type||l_grp_lmtparam.CGP_INTL_FLAG||l_grp_lmtparam.CGP_PNSIGN_FLAG||l_grp_lmtparam.CGP_MCC_CODE
                                        ||l_grp_lmtparam.CGP_TRFR_CRDACNT
                                        ||decode(l_grp_lmtparam.CGP_PAYMENT_TYPE,'NA','',l_grp_lmtparam.CGP_PAYMENT_TYPE)),
                                        SYSDATE,
                                        p_ins_user_in,
                                        SYSDATE,
                                        p_ins_user_in,
                                        l_grp_lmtparam.CGP_PAYMENT_TYPE);

            exception
             WHEN OTHERS THEN
                   p_resp_msg_out :='ERROR WHILE Inserting into CMS_GRPLMT_PARAM'
                  || SUBSTR (SQLERRM, 1, 300);
                  RAISE EXP_REJECT_RECORD;
            END;

            END LOOP;
            EXCEPTION
            when EXP_REJECT_RECORD then
                raise;
            WHEN OTHERS THEN
            p_resp_msg_out :='ERROR WHILE INSERTING FROM CMS_GRPLMT_PARAM:'||p_resp_msg_out
                  || SUBSTR (SQLERRM, 1, 300);
            RAISE EXP_REJECT_RECORD;

  END;

     END LOOP;
            EXCEPTION
            when EXP_REJECT_RECORD then
                raise;
            WHEN OTHERS THEN
            p_resp_msg_out :='ERROR WHILE SELECTING FROM CMS_GROUP_LIMIT:'||p_resp_msg_out
                  || SUBSTR (SQLERRM, 1, 300);
            RAISE EXP_REJECT_RECORD;

    END;



 EXCEPTION --<< MAIN EXCEPTION >>
   WHEN exp_reject_record
   THEN
      ROLLBACK;-- TO l_savepoint;
   WHEN OTHERS THEN
     p_resp_msg_out := 'Main Excp--'|| SUBSTR (SQLERRM, 1, 200);
END;


--End limit profile copy

--Start limits copy

PROCEDURE SP_LIMITS_COPY (
   p_instcode_in        IN       NUMBER,
   p_prod_code_in       IN       VARCHAR2,
   p_prod_catg_in       IN       VARCHAR2,
   p_toprod_code_in     IN       VARCHAR2,
   p_ins_user_in        IN       NUMBER,
   p_resp_msg_out       OUT      VARCHAR2
)
IS
   /*************************************************
   * Created Date          :  07-Mar-2016
   * Created By            :  Mageshkumar.S
   * PURPOSE               :  HOSTCC-57
   * Created reason        :  LIMITS COPY PROGRAM
   * Reviewer              :  SARAVANAKUMAR/SPANKAJ
   * Build Number          :  VMSGPRHOSTCSD4.0_B0001
   *************************************************/

 --  l_savepoint           NUMBER                              DEFAULT 1;
   exp_reject_record     EXCEPTION;
   l_prod_lmtprfl_id     CMS_PROD_LMTPRFL.CPL_LMTPRFL_ID%type;
   l_count               PLS_INTEGER;
   --l_newprfl_code        CMS_PROD_LMTPRFL.CPL_LMTPRFL_ID%type;
   l_lmtprfl_name        CMS_LMTPRFL_MAST.CLM_LMTPRFL_NAME%type;
   l_lmtact_flag         CMS_LMTPRFL_MAST.CLM_ACTIVE_FLAG%type;
  -- l_grup_code           cms_grplmt_mast.cgm_limitgl_code%type;
   --l_tran_type           cms_transaction_mast.ctm_tran_type%type;
   l_card_type           cms_prdcattype_lmtprfl.cpl_card_type%type;

   REF_CURSOR_PRODCATG_LMTPRFL SYS_REFCURSOR;
  l_limit_prfl   CMS_PROD_LMTPRFL.CPL_LMTPRFL_ID%type;
  l_chk_lmtprfl    PLS_INTEGER;


--     TYPE limit_prfl_rec IS TABLE OF VARCHAR2(10)
--        INDEX BY VARCHAR2(10);
--
--      limit_prfl_dtls    limit_prfl_rec;

BEGIN
   p_resp_msg_out := 'OK';
 --  SAVEPOINT l_savepoint;


    BEGIN

    SELECT COUNT(1)
    INTO l_count FROM CMS_PROD_LMTPRFL
    WHERE  CPL_PROD_CODE=p_prod_code_in;
    EXCEPTION
    WHEN OTHERS THEN
    p_resp_msg_out := 'ERROR WHILE SELECTING LIMIT PROFILE DETAILS FROM PRODUCT LEVEL--'|| SUBSTR (SQLERRM, 1, 200);
    RAISE EXP_REJECT_RECORD;

    END;

   IF l_count > 0 THEN

   BEGIN
        BEGIN
           SELECT clm_lmtprfl_id, SUBSTR (clm_lmtprfl_name, 1, 40), clm_active_flag
             INTO l_prod_lmtprfl_id, l_lmtprfl_name, l_lmtact_flag
             FROM cms_lmtprfl_mast
            WHERE clm_lmtprfl_id IN (SELECT cpl_lmtprfl_id
                                       FROM cms_prod_lmtprfl
                                      WHERE cpl_prod_code = p_prod_code_in);
        EXCEPTION
           WHEN NO_DATA_FOUND
           THEN
              RAISE exp_reject_record;
           WHEN OTHERS
           THEN
              p_resp_msg_out :=
                 'Error while selecting limit profile details from product level:'
                 || SUBSTR (SQLERRM, 1, 200);
              RAISE exp_reject_record;
        END;

        BEGIN
           sp_copy_lmts (p_instcode_in,
                         p_prod_code_in,
                         p_prod_catg_in,
                         l_prod_lmtprfl_id,
                         l_lmtprfl_name,
                         l_lmtact_flag,
                         'P',
                         p_resp_msg_out);

           IF p_resp_msg_out <> 'OK'
           THEN
              RAISE exp_reject_record;
           END IF;
        EXCEPTION
           WHEN exp_reject_record
           THEN
              RAISE;
           WHEN OTHERS
           THEN
              p_resp_msg_out :=
                 'Error while calling sp_copy_fees process:'
                 || SUBSTR (SQLERRM, 1, 200);
              RAISE exp_reject_record;
        END;
 EXCEPTION
    WHEN EXP_REJECT_RECORD THEN
               RAISE;
    when OTHERS then
            P_RESP_MSG_OUT :='Error while copying limits'|| SUBSTR (SQLERRM, 1, 200);
            RAISE EXP_REJECT_RECORD;
 END;



 BEGIN

    OPEN REF_CURSOR_PRODCATG_LMTPRFL FOR
    'SELECT CPL_CARD_TYPE,CPL_LMTPRFL_ID
    FROM CMS_PRDCATTYPE_LMTPRFL
    WHERE CPL_PROD_CODE = '''||p_prod_code_in||'''
    AND CPL_CARD_TYPE IN('||p_prod_catg_in||')';
    LOOP
    FETCH REF_CURSOR_PRODCATG_LMTPRFL INTO l_card_type,l_prod_lmtprfl_id;
    EXIT WHEN REF_CURSOR_PRODCATG_LMTPRFL%NOTFOUND;

        BEGIN
           SELECT vld_lmtprfl_name, vld_lmtact_flag
             INTO l_lmtprfl_name, l_lmtact_flag
             FROM vms_lmtprfl_dtls_stag
            WHERE vld_lmt_prfl = l_prod_lmtprfl_id;

           l_chk_lmtprfl := 1;
        EXCEPTION
           WHEN NO_DATA_FOUND
           THEN
              l_chk_lmtprfl := 0;
           WHEN OTHERS
           THEN
              p_resp_msg_out :=
                 'Error while checking lmtprfl:' || SUBSTR (SQLERRM, 1, 200);
              RAISE exp_reject_record;
        END;

      IF l_chk_lmtprfl=0 THEN
        BEGIN
           SELECT  SUBSTR (clm_lmtprfl_name, 1, 40), clm_active_flag
             INTO l_lmtprfl_name, l_lmtact_flag
             FROM cms_lmtprfl_mast
            WHERE clm_inst_code = p_instcode_in AND clm_lmtprfl_id=l_prod_lmtprfl_id;
        EXCEPTION
           WHEN NO_DATA_FOUND
           THEN
              RAISE exp_reject_record;
           WHEN OTHERS
           THEN
              p_resp_msg_out :=
                 'Error while selecting limit profile details from product level:'
                 || SUBSTR (SQLERRM, 1, 200);
              RAISE exp_reject_record;
        END;
      END IF;

        BEGIN
           sp_copy_lmts (p_instcode_in,
                         p_prod_code_in,
                         l_card_type,
                         l_prod_lmtprfl_id,
                         l_lmtprfl_name,
                         l_lmtact_flag,
                         'PC',
                         p_resp_msg_out,
                         l_chk_lmtprfl);

           IF p_resp_msg_out <> 'OK'
           THEN
              RAISE exp_reject_record;
           END IF;
        EXCEPTION
           WHEN exp_reject_record
           THEN
              RAISE;
           WHEN OTHERS
           THEN
              p_resp_msg_out :=
                 'Error while calling sp_copy_fees process:'
                 || SUBSTR (SQLERRM, 1, 200);
              RAISE exp_reject_record;
        END;
    END LOOP;
    EXCEPTION
 --   WHEN NO_DATA_FOUND THEN
   -- NULL;
        when exp_reject_record then
            raise;
        WHEN OTHERS THEN
        p_resp_msg_out := 'ERROR WHILE SELECTING LIMIT DETAILS FROM CMS_PRDCATTYPE_LMTPRFL' ||p_resp_msg_out||
                           SUBSTR(SQLERRM, 1, 200);
        RAISE exp_reject_record;

   END;

   END IF;


EXCEPTION --<< MAIN EXCEPTION >>
   WHEN exp_reject_record
   THEN
      ROLLBACK;-- TO l_savepoint;
   WHEN OTHERS THEN
     p_resp_msg_out := 'Main Excp--'|| SUBSTR (SQLERRM, 1, 200);
END;

--End limits copy

--Start product copy program

PROCEDURE   PRODUCTCOPY_PROGRAMTEMP (
   p_instcode_in            IN       NUMBER,
   p_bin_in                 IN       VARCHAR2,
   p_prod_code_in           IN       VARCHAR2,
   P_PROD_CATG_IN           IN       VARCHAR2,
   P_PROD_COPY_IN           IN       VARCHAR2,
   P_COPY_OPTION            IN       VARCHAR2,
   P_ENV_OPTION             IN       VARCHAR2,
   p_ins_user_in            IN       NUMBER,
   p_resp_code_out          OUT      VARCHAR2,
   p_errmsg_out             OUT      VARCHAR2
)
IS

/**********************************************************************************************

  * Created by                  : MageshKumar S.
  * Created Date                : 01-MAR-16
  * Created For                 : HOSTCC-57
  * Created reason              : PRODUCT COPY PROGRAM
  * Reviewer                    : SARAVANAKUMAR/SPANKAJ
  * Build Number                : VMSGPRHOSTCSD4.0_B0001

**************************************************************************************************/

--l_savepoint           NUMBER                              DEFAULT 1;
EXP_REJECT_RECORD EXCEPTION;

BEGIN
 p_errmsg_out  := 'OK';
 p_resp_code_out := '00';
 --SAVEPOINT l_savepoint;



BEGIN

  PRODUCT_PROFILE_TEMPCOPY(p_instcode_in,
                           p_ins_user_in,
                           p_prod_code_in,
                           p_prod_catg_in,
                           p_errmsg_out);

        IF p_errmsg_out <> 'OK'
        THEN
             RAISE EXP_REJECT_RECORD;
        END IF;

        EXCEPTION
        WHEN EXP_REJECT_RECORD
        THEN
        RAISE;
        WHEN OTHERS THEN
             p_errmsg_out :=
                'ERROR WHILE CALLING PRODUCT_PROFILE_TEMPCOPY PROCESS:'
                || SUBSTR (SQLERRM, 1, 200);
                RAISE EXP_REJECT_RECORD;

END;


--BEGIN
--
--  PRODCATG_PROFILE_TEMPCOPY(p_instcode_in,
--                            p_ins_user_in,
--                            p_prod_code_in,
--                            p_prod_catg_in,
--                            p_errmsg_out);
--
--          IF p_errmsg_out <> 'OK'
--            THEN
--               RAISE EXP_REJECT_RECORD;
--            END IF;
--         EXCEPTION
--            WHEN EXP_REJECT_RECORD
--            THEN
--               RAISE;
--            WHEN OTHERS
--            THEN
--               p_errmsg_out :=
--                  'ERROR WHILE CALLING PRODCATG_PROFILE_TEMPCOPY PROCESS:'
--                  || SUBSTR (SQLERRM, 1, 200);
--               RAISE EXP_REJECT_RECORD;
--
--END;

BEGIN

  PRODUCT_PARAMETER_TEMPCOPY(p_instcode_in,
                             p_ins_user_in,
                             p_bin_in,
                             p_prod_code_in,
                             p_errmsg_out);

          IF p_errmsg_out <> 'OK'
            THEN
               RAISE EXP_REJECT_RECORD;
            END IF;
         EXCEPTION
            WHEN EXP_REJECT_RECORD
            THEN
               RAISE;
            WHEN OTHERS
            THEN
               p_errmsg_out :=
                  'ERROR WHILE CALLING PRODUCT_PARAMETER_TEMPCOPY PROCESS:'
                  || SUBSTR (SQLERRM, 1, 200);
               RAISE EXP_REJECT_RECORD;

END;


BEGIN

  PRODCATG_PARAMETER_TEMPCOPY(p_instcode_in,
                              p_ins_user_in,
                              p_prod_code_in,
                              P_PROD_CATG_IN,
                              P_COPY_OPTION,
                              P_ENV_OPTION,
                              p_errmsg_out);

          IF p_errmsg_out <> 'OK'
            THEN
               RAISE EXP_REJECT_RECORD;
            END IF;
         EXCEPTION
            WHEN EXP_REJECT_RECORD
            THEN
               RAISE;
            WHEN OTHERS
            THEN
               p_errmsg_out :=
                  'ERROR WHILE CALLING PRODCATG_PARAMETER_TEMPCOPY PROCESS:'
                  || SUBSTR (SQLERRM, 1, 200);
               RAISE EXP_REJECT_RECORD;

END;


IF (INSTR(p_prod_copy_in,6)>0) THEN
BEGIN

  PRODUCT_SAVINGSPARAM_TEMPCOPY(p_instcode_in,
                                p_ins_user_in,
                                p_prod_code_in,
                                p_prod_catg_in,
                                p_errmsg_out);

          IF p_errmsg_out <> 'OK'
            THEN
               RAISE EXP_REJECT_RECORD;
            END IF;
         EXCEPTION
            WHEN EXP_REJECT_RECORD
            THEN
               RAISE;
            WHEN OTHERS
            THEN
               p_errmsg_out :=
                  'ERROR WHILE CALLING PRODUCT_SAVINGS_TEMPCOPY PROCESS:'
                  || SUBSTR (SQLERRM, 1, 200);
               RAISE EXP_REJECT_RECORD;

END;
END IF;

IF (INSTR(p_prod_copy_in,5)>0) THEN
BEGIN

  PRODUCT_EMBOSSFORMAT_TEMPCOPY(p_instcode_in,
                                p_ins_user_in,
                                p_prod_code_in,
                                p_prod_catg_in,
                                p_errmsg_out);

          IF p_errmsg_out <> 'OK'
            THEN
               RAISE EXP_REJECT_RECORD;
            END IF;
         EXCEPTION
            WHEN EXP_REJECT_RECORD
            THEN
               RAISE;
            WHEN OTHERS
            THEN
               p_errmsg_out :=
                  'ERROR WHILE CALLING PRODUCT_EMBOSSFORMAT_TEMPCOPY PROCESS:'
                  || SUBSTR (SQLERRM, 1, 200);
               RAISE EXP_REJECT_RECORD;

END;
END IF;

IF (INSTR(p_prod_copy_in,7)>0) THEN
BEGIN

  PRODUCT_ACHCONFIG_TEMPCOPY(p_instcode_in,
                                p_ins_user_in,
                                p_prod_code_in,
                                p_errmsg_out);

          IF p_errmsg_out <> 'OK'
            THEN
               RAISE EXP_REJECT_RECORD;
            END IF;
         EXCEPTION
            WHEN EXP_REJECT_RECORD
            THEN
               RAISE;
            WHEN OTHERS
            THEN
               p_errmsg_out :=
                  'ERROR WHILE CALLING PRODUCT_ACHCONFIG_TEMPCOPY PROCESS:'
                  || SUBSTR (SQLERRM, 1, 200);
               RAISE EXP_REJECT_RECORD;

END;
END IF;

IF (INSTR(p_prod_copy_in,10)>0) THEN
        BEGIN
           sp_fees_copy (p_instcode_in,
                         p_prod_code_in,
                         p_prod_catg_in,
                         NULL,
                         p_ins_user_in,
                         p_errmsg_out
                         );

           IF p_errmsg_out <> 'OK'
           THEN
              RAISE exp_reject_record;
           END IF;
        EXCEPTION
           WHEN exp_reject_record
           THEN
              RAISE;
           WHEN OTHERS
           THEN
              p_errmsg_out :='Error while calling sp_fees_copy process:'|| SUBSTR (SQLERRM, 1, 200);
              RAISE exp_reject_record;
        END;
END IF;

IF (INSTR(p_prod_copy_in,11)>0) THEN
        BEGIN
           sp_limits_copy (p_instcode_in,
                         p_prod_code_in,
                         p_prod_catg_in,
                         NULL,
                         p_ins_user_in,
                         p_errmsg_out);

           IF p_errmsg_out <> 'OK'
           THEN
              RAISE exp_reject_record;
           END IF;
        EXCEPTION
           WHEN exp_reject_record
           THEN
              RAISE;
           WHEN OTHERS
           THEN
              p_errmsg_out :='Error while calling sp_limits_copy process:'|| SUBSTR (SQLERRM, 1, 200);
              RAISE exp_reject_record;
        END;
END IF;

EXCEPTION
  WHEN EXP_REJECT_RECORD THEN
  ROLLBACK;-- TO l_savepoint;
  WHEN OTHERS THEN
  ROLLBACK;-- TO l_savepoint;
  p_resp_code_out := '21';
  p_errmsg_out := 'Exception while copying PRODUCTCOPY_PROGRAMTEMP:' ||p_errmsg_out || SUBSTR(SQLERRM, 1, 200);

END;
--End product copy program


--Start product profile temp to mast


PROCEDURE  PRODUCT_PROFILE_MAST (
   p_instcode_in            IN       NUMBER,
   p_ins_user_in            IN       NUMBER,
   p_prod_code_in           IN       VARCHAR2,
   p_card_type_in           IN       VARCHAR2,
   p_toprod_profilecode_out OUT      VARCHAR2,
   p_errmsg_out             OUT      VARCHAR2
)
IS

/**********************************************************************************************


  * Created by                  : MageshKumar S.
  * Created Date                : 07-MAR-16
  * Created For                 : HOSTCC-57
  * Created reason              : PRODUCT PROFILE TEMP TO MAST COPY PROGRAM
  * Reviewer                    : SARAVANAKUMAR/SPANKAJ
  * Build Number                : VMSGPRHOSTCSD4.0_B0001

**************************************************************************************************/
--l_savepoint           NUMBER                              DEFAULT 1;
EXP_REJECT_RECORD EXCEPTION;
l_profile_code     cms_profile_mast.cpm_profile_code%TYPE;
l_profile_name     cms_profile_mast.cpm_profile_name%TYPE;
l_profile_level    cms_profile_mast.cpm_profile_level%TYPE;
l_old_profile_code     cms_profile_mast.cpm_profile_code%TYPE;

CURSOR PROD_PIN_EMBOSS_INFO(l_profile_code IN VARCHAR2)
IS
SELECT
VBP_PROFILE_CODE,VBP_PARAM_TYPE,VBP_PARAM_NAME,VBP_PARAM_VALUE
FROM VMS_BIN_PARAM_STAG,VMS_PROFILE_MAST_STAG
WHERE VBP_PROFILE_CODE=VPM_PROFILE_CODE
AND VBP_PROFILE_CODE=l_profile_code
AND VPM_PROFILE_LEVEL='P';

CURSOR PAN_CONSTRUCT(l_profile_code IN VARCHAR2)
IS
SELECT
VPC_PROFILE_CODE,VPC_FIELD_NAME,VPC_START,VPC_LENGTH,
VPC_VALUE,VPC_ORDER_BY,VPC_START_FROM
FROM VMS_PAN_CONSTRUCT_STAG
WHERE VPC_PROFILE_CODE=l_profile_code;

CURSOR ACCT_CONSTRUCT(l_profile_code IN VARCHAR2)
IS
SELECT
VAC_PROFILE_CODE,VAC_FIELD_NAME,VAC_START,VAC_LENGTH,
VAC_VALUE,VAC_ORDER_BY,VAC_START_FROM
FROM VMS_ACCT_CONSTRUCT_STAG
WHERE VAC_PROFILE_CODE=l_profile_code;

CURSOR SAl_ACCT_CONSTRUCT(l_profile_code IN VARCHAR2)
IS
SELECT
VSC_PROFILE_CODE,VSC_FIELD_NAME,VSC_START,VSC_LENGTH,
VSC_VALUE,VSC_TOT_LENGTH,VSC_ORDER_BY,VSC_START_FROM
FROM VMS_SAVINGSACCT_CONSTRUCT_STAG
WHERE VSC_PROFILE_CODE=L_PROFILE_CODE;

REF_CUR_PROFILE_TEMP SYS_REFCURSOR;

BEGIN

 p_errmsg_out  := 'OK';
-- SAVEPOINT l_savepoint;


 BEGIN
 
 SELECT 'P'||seq_profile.nextval INTO l_profile_code  FROM DUAL;
 EXCEPTION
 WHEN OTHERS
         THEN
            p_errmsg_out := 'ERROR WHILE GETTING PROFILE SEQ:'|| SUBSTR (SQLERRM, 1, 200);
            RAISE EXP_REJECT_RECORD;
 END;
 P_TOPROD_PROFILECODE_OUT:=L_PROFILE_CODE;

 open ref_cur_profile_temp for 'SELECT
     VPM_PROFILE_NAME,
     VPM_PROFILE_LEVEL,vpm_profile_code
     FROM VMS_PROFILE_MAST_STAG     WHERE VPM_PROFILE_CODE IN(SELECT VPC_PROFILE_CODE FROM VMS_PROD_CATTYPE_STAG WHERE VPC_PROD_CODE='''||p_prod_code_in||''' AND VPC_CARD_TYPE IN ('|| p_card_type_in ||'))';
    loop
        FETCH ref_cur_profile_temp INTO l_profile_name,l_profile_level,l_old_profile_code;
        exit when ref_cur_profile_temp%notfound;
 --BEGIN

--  SELECT
--      VPM_PROFILE_NAME,
--      VPM_PROFILE_LEVEL,vpm_profile_code
--    INTO
--    l_profile_name,l_profile_level,l_old_profile_code
--    FROM VMS_PROFILE_MAST_STAG
--    WHERE VPM_PROFILE_CODE IN(SELECT VPC_PROFILE_CODE FROM VMS_PROD_CATTYPE_STAG WHERE VPC_PROD_CODE=p_prod_code_in AND VPC_CARD_TYPE IN ('|| p_card_type_in ||'));

--    EXCEPTION
--     WHEN NO_DATA_FOUND
--            THEN
--               p_errmsg_out :=
--                     'TEMP PROFILE DETAILS NOT FOUND FOR PRODUCT CODE: '|| p_prod_code_in;
--               RAISE EXP_REJECT_RECORD;
--        WHEN OTHERS
--         THEN
--            p_errmsg_out := 'ERROR WHILE SELECTING TEMP PRODUCT PROFILE DETAILS:'|| SUBSTR (SQLERRM, 1, 200)|| p_prod_code_in;
--            RAISE EXP_REJECT_RECORD;
--  END;
--
BEGIN

 SELECT 'P'||seq_profile.nextval INTO l_profile_code  FROM DUAL;
 EXCEPTION
 WHEN OTHERS
         THEN
            p_errmsg_out := 'ERROR WHILE GETTING PROFILE SEQ:'|| SUBSTR (SQLERRM, 1, 200);
            RAISE EXP_REJECT_RECORD;

 END;
 P_TOPROD_PROFILECODE_OUT:=L_PROFILE_CODE;

  BEGIN
        UPDATE VMS_PRODCATG_COPY_INFO SET VPC_NEWPROF_CODE=l_profile_code WHERE
        VPC_PROFILE_CODE=l_old_profile_code;

        IF SQL%ROWCOUNT =0 THEN
               p_errmsg_out := 'No records updated in VMS_PRODCATG_COPY_INFO table';
              RAISE EXP_REJECT_RECORD;
            END IF;
    EXCEPTION
        when EXP_REJECT_RECORD then
          RAISE;
        WHEN OTHERS THEN
           P_ERRMSG_OUT :=
                     'ERROR WHILE Updating VMS_PRODCATG_COPY_INFO :'
                  || SUBSTR (SQLERRM, 1, 300);
               RAISE EXP_REJECT_RECORD;
    END;

 BEGIN

  INSERT INTO CMS_PROFILE_MAST
   (CPM_PROFILE_CODE,
      CPM_PROFILE_NAME,
      CPM_INS_USER,
      CPM_INS_DATE,
      CPM_LUPD_USER,
      CPM_LUPD_DATE,
      CPM_INST_CODE,
      CPM_PROFILE_LEVEL)
    VALUES(
    l_profile_code,
    l_profile_name,
    p_ins_user_in,
    sysdate,
    p_ins_user_in,
    sysdate,
    p_instcode_in,
    l_profile_level
    );
   EXCEPTION
            WHEN OTHERS
            THEN
               p_errmsg_out :=
                     'ERROR WHILE INSERTING INTO CMS_PROFILE_MAST:'
                  || SUBSTR (SQLERRM, 1, 300);
               RAISE EXP_REJECT_RECORD;

 END;

  BEGIN
            FOR l_row_indx IN PROD_PIN_EMBOSS_INFO(l_old_profile_code)
            LOOP
            INSERT INTO CMS_BIN_PARAM(
                    CBP_PROFILE_CODE,
                    CBP_PARAM_TYPE,
                    CBP_PARAM_NAME,
                    CBP_PARAM_VALUE,
                    CBP_INS_USER,
                    CBP_INS_DATE,
                    CBP_LUPD_USER,
                    CBP_LUPD_DATE,
                    CBP_INST_CODE)
                    VALUES(
                    l_profile_code,
                    l_row_indx.VBP_PARAM_TYPE,
                    l_row_indx.VBP_PARAM_NAME,
                    l_row_indx.VBP_PARAM_VALUE,
                    p_ins_user_in,
                    SYSDATE,
                    p_ins_user_in,
                    SYSDATE,
                    p_instcode_in
                    );

            END LOOP;
            EXCEPTION
            WHEN OTHERS
            THEN
               p_errmsg_out :=
                     'ERROR WHILE INSERTING INTO CMS_BIN_PARAM:'
                  || SUBSTR (SQLERRM, 1, 300);
               RAISE EXP_REJECT_RECORD;

 END;

 BEGIN
            FOR l_row_indx IN PAN_CONSTRUCT(l_old_profile_code)
            LOOP
            INSERT INTO CMS_PAN_CONSTRUCT(
                    CPC_INST_CODE,
                    CPC_PROFILE_CODE,
                    CPC_FIELD_NAME,
                    CPC_START,
                    CPC_LENGTH,
                    CPC_VALUE,
                    CPC_ORDER_BY,
                    CPC_START_FROM,
                    CPC_LUPD_DATE,
                    CPC_LUPD_USER,
                    CPC_INS_DATE,
                    CPC_INS_USER)
                    VALUES(
                    p_instcode_in,
                    l_profile_code,
                    l_row_indx.VPC_FIELD_NAME,
                    l_row_indx.VPC_START,
                    l_row_indx.VPC_LENGTH,
                    l_row_indx.VPC_VALUE,
                    l_row_indx.VPC_ORDER_BY,
                    l_row_indx.VPC_START_FROM,
                    SYSDATE,
                    p_ins_user_in,
                    SYSDATE,
                    p_ins_user_in
                    );

            END LOOP;
            EXCEPTION
            WHEN OTHERS
            THEN
               p_errmsg_out :=
                     'ERROR WHILE INSERTING INTO CMS_PAN_CONSTRUCT:'
                  || SUBSTR (SQLERRM, 1, 300);
               RAISE EXP_REJECT_RECORD;

 END;

  BEGIN
            FOR l_row_indx IN ACCT_CONSTRUCT(l_old_profile_code)
            LOOP
            INSERT INTO CMS_ACCT_CONSTRUCT(
                    CAC_INST_CODE,
                    CAC_PROFILE_CODE,
                    CAC_FIELD_NAME,
                    CAC_START,
                    CAC_LENGTH,
                    CAC_VALUE,
                    CAC_ORDER_BY,
                    CAC_START_FROM,
                    CAC_LUPD_DATE,
                    CAC_LUPD_USER,
                    CAC_INS_DATE,
                    CAC_INS_USER)
                    VALUES(
                    p_instcode_in,
                    l_profile_code,
                    l_row_indx.VAC_FIELD_NAME,
                    l_row_indx.VAC_START,
                    l_row_indx.VAC_LENGTH,
                    l_row_indx.VAC_VALUE,
                    l_row_indx.VAC_ORDER_BY,
                    l_row_indx.VAC_START_FROM,
                    SYSDATE,
                    p_ins_user_in,
                    SYSDATE,
                    p_ins_user_in
                    );

            END LOOP;
            EXCEPTION
            WHEN OTHERS
            THEN
               p_errmsg_out:=
                     'ERROR WHILE INSERTING INTO CMS_ACCT_CONSTRUCT:'
                  || SUBSTR (SQLERRM, 1, 300);
               RAISE EXP_REJECT_RECORD;

 END;

 BEGIN
            FOR l_row_indx IN SAl_ACCT_CONSTRUCT(l_old_profile_code)
            LOOP
            INSERT INTO CMS_SAVINGSACCT_CONSTRUCT(
                    CSC_INST_CODE,
                    CSC_PROFILE_CODE,
                    CSC_FIELD_NAME,
                    CSC_START,
                    CSC_LENGTH,
                    CSC_VALUE,
                    CSC_TOT_LENGTH,
                    CSC_ORDER_BY,
                    CSC_START_FROM,
                    CSC_LUPD_DATE,
                    CSC_LUPD_USER,
                    CSC_INS_DATE,
                    CSC_INS_USER)
                    VALUES(
                    p_instcode_in,
                    l_profile_code,
                    l_row_indx.VSC_FIELD_NAME,
                    l_row_indx.VSC_START,
                    l_row_indx.VSC_LENGTH,
                    l_row_indx.VSC_VALUE,
                    l_row_indx.VSC_TOT_LENGTH,
                    l_row_indx.VSC_ORDER_BY,
                    l_row_indx.VSC_START_FROM,
                    SYSDATE,
                    p_ins_user_in,
                    SYSDATE,
                    p_ins_user_in
                    );

            END LOOP;
            EXCEPTION
            WHEN OTHERS
            THEN
                p_errmsg_out  :=
                     'ERROR WHILE INSERTING INTO CMS_SAVINGSACCT_CONSTRUCT:'
                  || SUBSTR (SQLERRM, 1, 300);
               RAISE EXP_REJECT_RECORD;

 END;
 end loop;

  EXCEPTION
  WHEN EXP_REJECT_RECORD THEN
  ROLLBACK;-- TO l_savepoint;
  WHEN OTHERS THEN
  ROLLBACK;-- TO l_savepoint;
  p_errmsg_out := 'Exception while copying PRODUCT_PROFILE_MAST:' ||p_errmsg_out || SUBSTR(SQLERRM, 1, 200);

END;


--End product profile temp to mast


--Start product category profile temp to mast

--PROCEDURE  PRODCATG_PROFILE_MAST (
--   p_instcode_in            IN       NUMBER,
--   p_ins_user_in            IN       NUMBER,
--   p_prod_code_in           IN       VARCHAR2,
--   p_prod_catg_in           IN       VARCHAR2,
--   p_errmsg_out             OUT      VARCHAR2
--)
--IS
--
--/**********************************************************************************************
--
--
--  * Created by                  : MageshKumar S.
--  * Created Date                : 07-MAR-16
--  * Created For                 : HOSTCC-57
--  * Created reason              : PRODUCT CATEGORY PROFILE TEMP TO MAST COPY PROGRAM
--  * Reviewer                    : SARAVANAKUMAR/SPANKAJ
--  * Build Number                : VMSGPRHOSTCSD4.0_B0001
--
--**************************************************************************************************/
----l_savepoint           NUMBER                              DEFAULT 1;
--EXP_REJECT_RECORD EXCEPTION;
--l_profile_code     cms_profile_mast.cpm_profile_code%type;
--l_profile_name     cms_profile_mast.cpm_profile_name%TYPE;
--l_profile_level    cms_profile_mast.cpm_profile_level%type;
--
--l_param_type       cms_bin_param.cbp_param_type%type;
--l_param_name       cms_bin_param.cbp_param_name%type;
--l_param_value      cms_bin_param.cbp_param_value%type;
--
--l_newprof_code    vms_profile_mast_stag.vpm_profile_code%type;
--l_oldprof_code    vms_profile_mast_stag.vpm_profile_code%type;
--
--ref_cur_prodcatg_profile   sys_refcursor;
--ref_cur_prodcatg_binparam  sys_refcursor;
--
--
--BEGIN
--
-- p_errmsg_out  := 'OK';
---- SAVEPOINT l_savepoint;
--
-- BEGIN
--
--    OPEN ref_cur_prodcatg_profile FOR
--    'SELECT ''P''||seq_profile.nextval,VPM_PROFILE_CODE,VPM_PROFILE_NAME,VPM_PROFILE_LEVEL
--     FROM VMS_PROFILE_MAST_STAG
--     WHERE VPM_PROFILE_CODE IN(SELECT VPC_PROFILE_CODE FROM VMS_PROD_CATTYPE_STAG
--     WHERE VPC_PROD_CODE='''||p_prod_code_in||''' AND VPC_CARD_TYPE IN  ('||p_prod_catg_in||'))';
--    LOOP
--    FETCH ref_cur_prodcatg_profile INTO l_newprof_code,l_oldprof_code,l_profile_name,l_profile_level;
--    EXIT WHEN ref_cur_prodcatg_profile%NOTFOUND;
--
--    BEGIN
--    INSERT INTO CMS_PROFILE_MAST
--   (CPM_PROFILE_CODE,
--      CPM_PROFILE_NAME,
--      CPM_INS_USER,
--      CPM_INS_DATE,
--      CPM_LUPD_USER,
--      CPM_LUPD_DATE,
--      CPM_INST_CODE,
--      CPM_PROFILE_LEVEL)
--    VALUES(
--    l_newprof_code,
--    l_profile_name,
--    p_ins_user_in,
--    sysdate,
--    p_ins_user_in,
--    sysdate,
--    p_instcode_in,
--    l_profile_level);
--
--    EXCEPTION
--            WHEN OTHERS
--            THEN
--               p_errmsg_out :=
--                     'ERROR WHILE INSERTING INTO CMS_PROFILE_MAST1 :'
--                  || SUBSTR (SQLERRM, 1, 300);
--               RAISE EXP_REJECT_RECORD;
--    END;
--
--    BEGIN
--        UPDATE VMS_PRODCATG_COPY_INFO SET VPC_NEWPROF_CODE=l_newprof_code WHERE
--        VPC_PROFILE_CODE=l_oldprof_code;
--
--        IF SQL%ROWCOUNT =0 THEN
--               p_errmsg_out := 'No records updated in VMS_PRODCATG_COPY_INFO table';
--              RAISE EXP_REJECT_RECORD;
--            END IF;
--    EXCEPTION
--        when EXP_REJECT_RECORD then
--          RAISE;
--        WHEN OTHERS THEN
--           P_ERRMSG_OUT :=
--                     'ERROR WHILE Updating VMS_PRODCATG_COPY_INFO :'
--                  || SUBSTR (SQLERRM, 1, 300);
--               RAISE EXP_REJECT_RECORD;
--
--
--    END;
--
--   END LOOP;
--
--   EXCEPTION
--           when EXP_REJECT_RECORD then
--            raise;
--            WHEN OTHERS
--            THEN
--               p_errmsg_out :=
--                     'ERROR WHILE INSERTING INTO CMS_PROFILE_MAST2 :'||p_errmsg_out
--                  || SUBSTR (SQLERRM, 1, 300);
--               RAISE EXP_REJECT_RECORD;
--
-- END;
--
--
-- BEGIN
--
--    OPEN ref_cur_prodcatg_binparam FOR
--    'SELECT  DISTINCT VPC_NEWPROF_CODE,
--     VBP_PARAM_TYPE,VBP_PARAM_NAME,VBP_PARAM_VALUE
--     FROM VMS_BIN_PARAM_STAG,VMS_PROFILE_MAST_STAG,VMS_PRODCATG_COPY_INFO
--     WHERE VBP_PROFILE_CODE=VPM_PROFILE_CODE
--     AND VPC_PROFILE_CODE=VPM_PROFILE_CODE
--     AND VBP_PROFILE_CODE IN(SELECT VPC_PROFILE_CODE FROM VMS_PROD_CATTYPE_STAG
--     WHERE VPC_PROD_CODE='''||p_prod_code_in||''' AND VPC_CARD_TYPE IN('||p_prod_catg_in||')) AND VPM_PROFILE_LEVEL=''PC''';
--    LOOP
--    FETCH ref_cur_prodcatg_binparam INTO l_profile_code,l_param_type,l_param_name,l_param_value;
--    exit WHEN ref_cur_prodcatg_binparam%NOTFOUND;
--
--    INSERT INTO CMS_BIN_PARAM(
--                    CBP_PROFILE_CODE,
--                    CBP_PARAM_TYPE,
--                    CBP_PARAM_NAME,
--                    CBP_PARAM_VALUE,
--                    CBP_INS_USER,
--                    CBP_INS_DATE,
--                    CBP_LUPD_USER,
--                    CBP_LUPD_DATE,
--                    CBP_INST_CODE)
--                    VALUES(
--                    l_profile_code,
--                    l_param_type,
--                    l_param_name,
--                    l_param_value,
--                    p_ins_user_in,
--                    SYSDATE,
--                    p_ins_user_in,
--                    SYSDATE,
--                    p_instcode_in
--                    );
--
--
--    END LOOP;
--
--   EXCEPTION
--            WHEN OTHERS
--            THEN
--               p_errmsg_out :=
--                     'ERROR WHILE INSERTING INTO CMS_BIN_PARAM :'
--                  || SUBSTR (SQLERRM, 1, 300);
--               RAISE EXP_REJECT_RECORD;
--
-- END;
--
--
-- EXCEPTION
--  WHEN EXP_REJECT_RECORD THEN
--  ROLLBACK;-- TO l_savepoint;
--  WHEN OTHERS THEN
--  ROLLBACK;-- TO l_savepoint;
--  p_errmsg_out := 'Exception while copying PRODCATG_PROFILE_MAST:' ||p_errmsg_out || SUBSTR(SQLERRM, 1, 200);
--
--END;


--End product category profile temp to mast

--Start product parameter temp to mast

PROCEDURE  PRODUCT_PARAMETER_MAST (
   p_instcode_in            IN       NUMBER,
   p_ins_user_in            IN       NUMBER,
   p_prod_code_in           IN       VARCHAR2,
   p_toprod_profilecode_in  IN       VARCHAR2,
   p_prod_code_out          OUT      VARCHAR2,
   p_errmsg_out             OUT      VARCHAR2
)
IS

/**********************************************************************************************


  * Created by                  : MageshKumar S.
  * Created Date                : 07-MAR-16
  * Created For                 : HOSTCC-57
  * Created reason              : PRODUCT PARAMETER TEMP TO MAST COPY PROGRAM
  * Reviewer                    : SARAVANAKUMAR/SPANKAJ
  * Build Number                : VMSGPRHOSTCSD4.0_B0001

  * Modified by      : Sivakumar M
  * Modified For     : CLVMS-124
  * Modified Date    : 08-JUNE-2016
  * Reviewer         : Saravanan/Spankaj
  * Build Number     : VMSGPRHOSTCSD4.2_B0001
  
   * Modified by      : Narayana
   * Modified For     : VMS-1048 (VMS Host Configure new product in Dev A to replicate to other lower environments)
   * Modified Date    : 13-AUG-2019
   * Reviewer         : Saravanakumar
   * Build Number     : R19_B0002  
   
   * Modified by      : Baskar Krishnan
   * Modified For     : VMS-1573 (Adding a new product is failing in Setup > Product > Product Parameters screen)
   * Modified Date    : 17-DEC-2019
   * Reviewer         : Saravanakumar
   * Build Number     : R24_B0001  


**************************************************************************************************/
--l_savepoint           NUMBER                              DEFAULT 1;
EXP_REJECT_RECORD EXCEPTION;
l_prof_code            cms_profile_mast.cpm_profile_code%TYPE;
l_profile_name         cms_profile_mast.cpm_profile_name%TYPE;
l_profile_level        cms_profile_mast.cpm_profile_level%TYPE;
l_interchange_code     cms_bin_mast.cbm_interchange_code%TYPE;
l_association_code     cms_prod_mast.CPM_ASSO_CODE%TYPE;
l_inst_type            cms_prod_mast.CPM_INST_TYPE%TYPE;
l_catg_code            cms_prod_mast.CPM_CATG_CODE%TYPE;
l_prod_desc            cms_prod_mast.CPM_PROD_DESC%TYPE;
l_switch_prod          cms_prod_mast.CPM_SWITCH_PROD%TYPE;
l_validity_period      cms_prod_mast.CPM_VALIDITY_PERIOD%TYPE;
--l_val_flag             cms_prod_mast.CPM_VAR_FLAG%TYPE;
l_rulegrp_code         cms_prod_mast.CPM_RULEGROUP_CODE%TYPE;
--l_profile_code         cms_prod_mast.CPM_PROFILE_CODE%TYPE;
l_marcprod_flag        cms_prod_mast.CPM_MARC_PROD_FLAG%TYPE;
L_PRODMAST_PARAM       CMS_PROD_MAST.CPM_PRODMAST_PARAM1%TYPE;
--l_prog_id              cms_prod_mast.CPM_PROGRAM_ID%TYPE;
l_preauthexp_period    cms_prod_mast.CPM_PRE_AUTH_EXP_DATE%TYPE;
--l_proxy_len            cms_prod_mast.CPM_PROXY_LENGTH%TYPE;
l_rout_num             cms_prod_mast.CPM_ROUT_NUM%TYPE;
l_issu_bank            cms_prod_mast.CPM_ISSU_BANK%TYPE;
l_ica                  cms_prod_mast.CPM_ICA%TYPE;
l_olsexpry_flag        cms_prod_mast.CPM_OLS_EXPIRY_FLAG%TYPE;
l_stmt_footer          cms_prod_mast.CPM_STATEMENT_FOOTER%TYPE;
l_passive_flag         cms_prod_mast.CPM_PASSIVE_FLAG%TYPE;
l_olsresp_flag         cms_prod_mast.CPM_OLSRESP_FLAG%TYPE;
L_EMV_FLAG             CMS_PROD_MAST.CPM_EMV_FLAG%TYPE;
l_inst_id              cms_prod_mast.CPM_INSTITUTION_ID%TYPE;
l_transit_num          cms_prod_mast.CPM_TRANSIT_NUMBER%TYPE;
l_random_pin           cms_prod_mast.CPM_RANDOM_PIN%TYPE;
l_pinchange_flag       cms_prod_mast.CPM_PINCHANGE_FLAG%TYPE;
l_ctc_bin              cms_prod_mast.CPM_CTC_BIN%TYPE;
l_poa_prod             cms_prod_mast.CPM_POA_PROD%TYPE;
l_issubank_addr        cms_prod_mast.CPM_ISSU_BANK_ADDR%TYPE;
l_onusexpry_flag       cms_prod_mast.CPM_ONUS_AUTH_EXPIRY%TYPE;
l_prod_threshold       CMS_PROD_THRESHOLD.CPT_PROD_THRESHOLD%TYPE;
l_email_id             cms_product_param.cpp_email_id%TYPE;
l_fromemail_id         cms_product_param.CPP_FROMEMAIL_ID%TYPE;
l_app_name             cms_product_param.CPP_APP_NAME%TYPE;
l_appnty_type          cms_product_param.CPP_APPNTY_TYPE%TYPE;
l_kycverify_flag       cms_product_param.CPP_KYCVERIFY_FLAG%TYPE;
l_networkacq_flag      cms_product_param.CPP_NETWORKACQID_FLAG%TYPE;
l_short_code           cms_product_param.CPP_SHORT_CODE%TYPE;
l_cip_intvl            cms_product_param.CPP_CIP_INTVL%TYPE;
--l_renewprod_code       cms_product_param.CPP_RENEW_PRODCODE%TYPE;
--l_renewcard_type       cms_product_param.CPP_RENEW_CARDTYPE%TYPE;
l_dup_ssnchk           cms_product_param.CPP_DUP_SSNCHK%TYPE;
l_dup_timeperiod       cms_product_param.CPP_DUP_TIMEPERIOD%TYPE;
l_dup_timeout          cms_product_param.CPP_DUP_TIMEUNT%TYPE;
l_gprflag_achtxn       cms_product_param.CPP_GPRFLAG_ACHTXN%TYPE;
l_acctunlock_duration  cms_product_param.CPP_ACCTUNLOCK_DURATION%TYPE;
l_wrong_logoncnt       cms_product_param.CPP_WRONG_LOGONCOUNT%TYPE;
l_partner_id           cms_product_param.CPP_PARTNER_ID%TYPE;
l_mmpos_feeplan        cms_product_param.CPP_MMPOS_FEEPLAN%TYPE;
l_renew_pinmigration   cms_product_param.CPP_RENEWAL_PINMIGRATION%TYPE;
l_achblkexpry_period   cms_product_param.CPP_ACHBLCKEXPRY_PERIOD%TYPE;
l_federalchk_flag      cms_product_param.CPP_FEDERALCHECK_FLAG%TYPE;
l_preauth_prodflag     cms_product_param.CPP_PREAUTH_PRODFLAG%TYPE;
l_aggregator_id        cms_product_param.CPP_AGGREGATOR_ID%TYPE;
l_tandc_version        cms_product_param.CPP_TANDC_VERSION%TYPE;
l_b2bcard_stat         cms_product_param.CPP_B2BCARD_STAT%TYPE;
l_b2b_lmtprfl          cms_product_param.CPP_B2B_LMTPRFL%TYPE;
l_hostflr_lmt          cms_product_param.CPP_HOSTFLOOR_LIMIT%TYPE;
l_spd_flag             cms_product_param.CPP_SPD_FLAG%TYPE;
l_upc                  cms_product_param.CPP_UPC%TYPE;
l_b2bfname_flag        cms_product_param.CPP_B2BFLNAME_FLAG%TYPE;
l_clawback_desc        cms_product_param.CPP_CLAWBACK_DESC%TYPE;
l_product_type         cms_product_param.CPP_PRODUCT_TYPE%TYPE;
l_webauthmapping_id    CMS_PRODUCT_PARAM.cpp_webauthmapping_id%TYPE;
l_ivrauthmapping_id    CMS_PRODUCT_PARAM.cpp_ivrauthmapping_id%TYPE;
l_subbin_length        CMS_PRODUCT_PARAM.CPP_SUBBIN_LENGTH%TYPE;
l_CCT_CTRL_NUMB        VARCHAR2(100);
l_GET_SEQ_QUERY   VARCHAR2(500);
l_SEQ_NO        PLS_INTEGER;
l_bin         vms_prod_bin_stag.vpb_inst_bin%type;
L_FROM_DATE   CMS_PROD_MAST.CPM_FROM_DATE %TYPE;
L_PACK_ID_CNT PLS_INTEGER;
L_PROD_COUNT PLS_INTEGER;
l_prod_threshold_count PLS_INTEGER;

CURSOR PRODNETWORKID_MAPPING(l_prod_code_in IN VARCHAR)
IS
SELECT VPM_NETWORK_ID
FROM VMS_PRODNETWORKID_MAPPING_STAG WHERE VPM_PROD_CODE=l_prod_code_in;

CURSOR PRODUCT_CARDPACK_STAG(l_prod_code_in IN VARCHAR)
IS
SELECT VPC_CARD_DETAILS,
VPC_PRINT_VENDOR,VPC_INST_REPLACEMENT_FLAG,
VPC_CARD_ID
FROM VMS_PROD_CARDPACK_STAG WHERE VPC_PROD_CODE=l_prod_code_in;

CURSOR SCORECARD_PRODMAPPING(l_prod_code_in IN VARCHAR)
IS
SELECT VSP_SCORECARD_ID,
VSP_DELIVERY_CHANNEL,VSP_CIPCARD_STAT,VSP_AVQ_FLAG
FROM VMS_SCORECARD_PRODMAPPING_STAG WHERE VSP_PROD_CODE=l_prod_code_in;

BEGIN

 p_errmsg_out  := 'OK';
-- SAVEPOINT l_savepoint;

  BEGIN

 SELECT VPB_INST_BIN INTO l_bin FROM VMS_PROD_BIN_STAG WHERE VPB_PROD_CODE=p_prod_code_in;

   EXCEPTION
            WHEN OTHERS
            THEN
               p_errmsg_out  :=
                     'ERROR WHILE GETTING DETAILS FROM  VMS_PROD_BIN_STAG:'||p_prod_code_in
                  || SUBSTR (SQLERRM, 1, 300);
               RAISE EXP_REJECT_RECORD;

 END;

  BEGIN
    SELECT count(*) INTO l_prod_threshold_count FROM VMS_PROD_THRESHOLD_STAG WHERE VPT_PROD_CODE=p_prod_code_in;
    if l_prod_threshold_count>0 then
         SELECT VPT_PROD_THRESHOLD INTO l_prod_threshold FROM VMS_PROD_THRESHOLD_STAG WHERE VPT_PROD_CODE=p_prod_code_in;
    else  
         SELECT CIP_PARAM_VALUE INTO l_prod_threshold FROM CMS_INST_PARAM WHERE CIP_PARAM_KEY='PRODUCT_THRESHOLD';
    END IF;

   EXCEPTION
            WHEN OTHERS
            THEN
               p_errmsg_out  :=
                     'ERROR WHILE SELECTING DETAILS FROM  VMS_PROD_THRESHOLD_STAG:'
                  || SUBSTR (SQLERRM, 1, 300);
               RAISE EXP_REJECT_RECORD;

 END;



  BEGIN

  SELECT VPM_ASSO_CODE,VPM_INST_TYPE,VPM_CATG_CODE,VPM_PROD_DESC,
        VPM_SWITCH_PROD,VPM_VALIDITY_PERIOD,--VPM_VAR_FLAG,
        VPM_RULEGROUP_CODE,
        VPM_MARC_PROD_FLAG,VPM_PRODMAST_PARAM1,--VPM_PROGRAM_ID,
        VPM_PRE_AUTH_EXP_DATE,--VPM_PROXY_LENGTH,
        VPM_ROUT_NUM,VPM_ISSU_BANK,
        VPM_ICA,VPM_OLS_EXPIRY_FLAG,VPM_STATEMENT_FOOTER,VPM_PASSIVE_FLAG,
        VPM_OLSRESP_FLAG,VPM_EMV_FLAG,VPM_INSTITUTION_ID,VPM_TRANSIT_NUMBER,
        VPM_RANDOM_PIN,VPM_PINCHANGE_FLAG,VPM_CTC_BIN,VPM_POA_PROD,VPM_ISSU_BANK_ADDR,VPM_ONUS_AUTH_EXPIRY,VPM_INTERCHANGE_CODE,VPM_FROM_DATE
    INTO l_association_code,l_inst_type,l_catg_code,l_prod_desc,
         l_switch_prod,l_validity_period,--l_val_flag,
         L_RULEGRP_CODE,
         L_MARCPROD_FLAG,L_PRODMAST_PARAM,--l_prog_id,
         L_PREAUTHEXP_PERIOD,--L_PROXY_LEN,
         l_rout_num,l_issu_bank,
         l_ica,l_olsexpry_flag,l_stmt_footer,l_passive_flag,
         l_olsresp_flag,l_emv_flag,l_inst_id,l_transit_num,
         l_random_pin,l_pinchange_flag,l_ctc_bin,l_poa_prod,l_issubank_addr,l_onusexpry_flag,l_interchange_code,l_from_date
    FROM VMS_PROD_MAST_STAG
    WHERE VPM_PROD_CODE=p_prod_code_in;

    EXCEPTION
     WHEN NO_DATA_FOUND
            THEN
               p_errmsg_out :=
                     'PRODUCT DETAILS NOT FOUND FROM VMS_PROD_MAST_STAG FOR PRODUCT CODE: '|| p_prod_code_in;
               RAISE EXP_REJECT_RECORD;
          WHEN OTHERS
         THEN
            p_errmsg_out := 'ERROR WHILE SELECTING PRODUCT DETAILS:'|| SUBSTR (SQLERRM, 1, 200);
            RAISE EXP_REJECT_RECORD;
  END;

    BEGIN
   SELECT lpad(cct_ctrl_numb, DECODE(length(cct_ctrl_numb), 1, 2, length(cct_ctrl_numb)), 0)
     INTO l_CCT_CTRL_NUMB
     FROM CMS_CTRL_TABLE
    WHERE SUBSTR(CCT_CTRL_CODE, 0, 2) =
         LTRIM(RTRIM(l_interchange_code || l_catg_code)) AND
         CCT_CTRL_KEY = 'PROD CODE'
      FOR UPDATE;   

     p_prod_code_out := l_interchange_code || l_catg_code || l_CCT_CTRL_NUMB;             
         
    SELECT COUNT(*) INTO L_PROD_COUNT FROM CMS_PROD_MAST WHERE CPM_PROD_CODE=p_prod_code_out;
    IF L_PROD_COUNT>0 THEN    
        SELECT MAX(TO_NUMBER(SUBSTR(CPM_PROD_CODE,3,4))) INTO l_CCT_CTRL_NUMB FROM CMS_PROD_MAST WHERE CPM_INTERCHANGE_CODE=l_interchange_code;
        p_prod_code_out := l_interchange_code || l_catg_code || l_CCT_CTRL_NUMB;    
    END IF;
    
     UPDATE CMS_CTRL_TABLE
      SET CCT_CTRL_NUMB = CCT_CTRL_NUMB + 1, CCT_LUPD_USER = p_ins_user_in
    WHERE SUBSTR(CCT_CTRL_CODE, 0, 2) =
         LTRIM(RTRIM(l_interchange_code || l_catg_code)) AND
         CCT_CTRL_KEY = 'PROD CODE';
    
  EXCEPTION
    WHEN NO_DATA_FOUND THEN
     p_prod_code_out := l_interchange_code || l_catg_code || '001';

     INSERT INTO CMS_CTRL_TABLE
       (CCT_CTRL_CODE,
        CCT_CTRL_KEY,
        CCT_CTRL_NUMB,
        CCT_CTRL_DESC,
        CCT_INS_USER,
        CCT_LUPD_USER)
     VALUES
       (LTRIM(RTRIM(p_prod_code_out)),
        'PROD CODE',
        2,
        'Latest prod type for interchange ' || l_interchange_code ||
        ' and category ' || l_catg_code || p_ins_user_in,
        p_ins_user_in,
        p_ins_user_in);
    when others then
         p_errmsg_out  :=
                     'ERROR WHILE selecting/updating  CMS_CTRL_TABLE:'
                  || SUBSTR (SQLERRM, 1, 300);
               RAISE EXP_REJECT_RECORD;

  END;

 BEGIN

  INSERT INTO CMS_PROD_MAST(CPM_INST_CODE,CPM_PROD_CODE,CPM_ASSO_CODE,CPM_INST_TYPE,CPM_INTERCHANGE_CODE,
                                CPM_CATG_CODE,CPM_PROD_DESC,CPM_SWITCH_PROD,CPM_FROM_DATE,CPM_TO_DATE,CPM_INS_USER,
                                CPM_INS_DATE,CPM_LUPD_USER,CPM_LUPD_DATE,CPM_VALIDITY_PERIOD,--CPM_VAR_FLAG,
                                CPM_RULEGROUP_CODE,--CPM_PROFILE_CODE,
                                CPM_MARC_PROD_FLAG,CPM_PRODMAST_PARAM1,-- CPM_PROGRAM_ID,
                               CPM_PRE_AUTH_EXP_DATE,--CPM_PROXY_LENGTH,
                               CPM_ROUT_NUM,
                                CPM_ISSU_BANK,CPM_ICA,CPM_OLS_EXPIRY_FLAG,CPM_STATEMENT_FOOTER,
                                CPM_PASSIVE_FLAG,CPM_OLSRESP_FLAG,CPM_EMV_FLAG,CPM_INSTITUTION_ID,CPM_TRANSIT_NUMBER,
                                CPM_RANDOM_PIN,CPM_PINCHANGE_FLAG,CPM_CTC_BIN,CPM_POA_PROD,CPM_ISSU_BANK_ADDR,CPM_ONUS_AUTH_EXPIRY)
                                VALUES(
                                p_instcode_in,p_prod_code_out,l_association_code,l_inst_type,l_interchange_code,
                                l_catg_code,l_prod_desc,l_switch_prod,l_from_date,TO_DATE('01-JAN-9999', 'DD_MON_YYYY'),p_ins_user_in,
                                SYSDATE,P_INS_USER_IN,SYSDATE,L_VALIDITY_PERIOD,--l_val_flag,
                                L_RULEGRP_CODE,--P_TOPROD_PROFILECODE_IN,
                                L_MARCPROD_FLAG,L_PRODMAST_PARAM,--l_prog_id,
                                L_PREAUTHEXP_PERIOD,--L_PROXY_LEN,
                                l_rout_num,
                                l_issu_bank,l_ica,l_olsexpry_flag,l_stmt_footer,
                                l_passive_flag,l_olsresp_flag,l_emv_flag,l_inst_id,l_transit_num,
                                l_random_pin,l_pinchange_flag,l_ctc_bin,l_poa_prod,l_issubank_addr,l_onusexpry_flag);

   EXCEPTION
            WHEN OTHERS
            THEN
              p_errmsg_out  :=
                     'ERROR WHILE INSERTING INTO CMS_PROD_MAST:'
                  || SUBSTR (SQLERRM, 1, 300);
               RAISE EXP_REJECT_RECORD;

 END;

-- BEGIN
--     l_GET_SEQ_QUERY := 'SELECT COUNT(*)  FROM CMS_PROGRAM_ID_CNT CPI WHERE CPI.CPI_PROGRAM_ID=' ||
--                   CHR(39) || l_prog_id || CHR(39) || ' AND CPI_INST_CODE=' ||
--                   p_instcode_in;
--     EXECUTE IMMEDIATE l_GET_SEQ_QUERY
--       INTO l_SEQ_NO;
--     IF l_SEQ_NO = 0 THEN
--       INSERT INTO CMS_PROGRAM_ID_CNT
--        (CPI_INST_CODE,
--         CPI_PROGRAM_ID,
--         CPI_SEQUENCE_NO,
--         CPI_INS_USER,
--         CPI_INS_DATE)
--       VALUES
--        (p_instcode_in, l_prog_id, 0, '', SYSDATE);
--     END IF;
--    EXCEPTION
--     WHEN OTHERS THEN
--       P_ERRMSG_OUT := 'Error when inserting into  CMS_PROGRAM_ID_CNT ' ||SQLERRM;
--       RAISE EXP_REJECT_RECORD;
--    END;



 BEGIN

        INSERT INTO CMS_PROD_BIN(
          CPB_INST_CODE,
                    CPB_PROD_CODE,
                    CPB_INTERCHANGE_CODE,
                    CPB_INST_BIN,
                    CPB_ACTIVE_BIN,
                    CPB_INS_USER,
                    CPB_INS_DATE,
          CPB_LUPD_USER,
          CPB_LUPD_DATE
          )
                VALUES(p_instcode_in,
                         p_prod_code_out,
                         l_interchange_code,
                         l_bin,
                         'Y',
                         p_ins_user_in,
               SYSDATE,
                         p_ins_user_in,
               SYSDATE);


    EXCEPTION
            WHEN OTHERS
            THEN
               p_errmsg_out  :=
                     'ERROR WHILE INSERTING INTO CMS_PROD_BIN:'
                  || SUBSTR (SQLERRM, 1, 300);
               RAISE EXP_REJECT_RECORD;

    END;

  BEGIN

        INSERT INTO CMS_PROD_THRESHOLD(CPT_INST_CODE,
                                        CPT_PROD_CODE,
                                        CPT_PROD_THRESHOLD,
                                        CPT_INS_USER,
                                        CPT_INS_DATE,
                                        CPT_LUPD_USER,
                                        CPT_LUPD_DATE)
                                  VALUES(p_instcode_in,
                                         p_prod_code_out,
                                         l_prod_threshold,
                                         p_ins_user_in,
                                         SYSDATE,
                                         p_ins_user_in,
                                         SYSDATE);

    EXCEPTION
            WHEN OTHERS
            THEN
              p_errmsg_out  :=
                     'ERROR WHILE INSERTING INTO CMS_PROD_THRESHOLD:'
                  || SUBSTR (SQLERRM, 1, 300);
               RAISE EXP_REJECT_RECORD;

    END;

   BEGIN

  SELECT
        VPP_EMAIL_ID,VPP_FROMEMAIL_ID,VPP_APP_NAME,VPP_APPNTY_TYPE,
        VPP_KYCVERIFY_FLAG,VPP_NETWORKACQID_FLAG,VPP_SHORT_CODE,VPP_CIP_INTVL,
        --VPP_RENEW_PRODCODE,VPP_RENEW_CARDTYPE,
        VPP_DUP_SSNCHK,VPP_DUP_TIMEPERIOD,
        VPP_DUP_TIMEUNT,VPP_GPRFLAG_ACHTXN,VPP_ACCTUNLOCK_DURATION,
        VPP_WRONG_LOGONCOUNT,VPP_PARTNER_ID,VPP_MMPOS_FEEPLAN,VPP_RENEWAL_PINMIGRATION,
        VPP_ACHBLCKEXPRY_PERIOD,VPP_FEDERALCHECK_FLAG,VPP_PREAUTH_PRODFLAG,VPP_AGGREGATOR_ID,
        VPP_TANDC_VERSION,VPP_B2BCARD_STAT,VPP_B2B_LMTPRFL,VPP_HOSTFLOOR_LIMIT,
        VPP_SPD_FLAG,VPP_UPC,VPP_B2BFLNAME_FLAG,VPP_CLAWBACK_DESC,VPP_PRODUCT_TYPE,VPP_WEBAUTHMAPPING_ID,VPP_IVRAUTHMAPPING_ID,vpp_subbin_length
   INTO  l_email_id,l_fromemail_id,l_app_name,l_appnty_type,
         l_kycverify_flag,l_networkacq_flag,l_short_code,l_cip_intvl,
         --l_renewprod_code,l_renewcard_type,
         l_dup_ssnchk,l_dup_timeperiod,
         l_dup_timeout,l_gprflag_achtxn,l_acctunlock_duration,
         l_wrong_logoncnt,l_partner_id,l_mmpos_feeplan,l_renew_pinmigration,
         l_achblkexpry_period,l_federalchk_flag,l_preauth_prodflag,l_aggregator_id,
         l_tandc_version,l_b2bcard_stat,l_b2b_lmtprfl,l_hostflr_lmt,
         l_spd_flag,l_upc,l_b2bfname_flag,l_clawback_desc,l_product_type,l_webauthmapping_id,l_ivrauthmapping_id,l_subbin_length
    FROM VMS_PRODUCT_PARAM_STAG
    WHERE VPP_PROD_CODE=p_prod_code_in;

    EXCEPTION
     WHEN NO_DATA_FOUND
            THEN
               p_errmsg_out :=
                     'PRODUCT DETAILS NOT FOUND FROM VMS_PRODUCT_PARAM_STAG FOR PRODUCT CODE: '|| p_prod_code_in;
               RAISE EXP_REJECT_RECORD;
          WHEN OTHERS
         THEN
            p_errmsg_out := 'ERROR WHILE SELECTING PRODUCT DETAILS FROM VMS_PRODUCT_PARAM_STAG:'|| SUBSTR (SQLERRM, 1, 200);
            RAISE EXP_REJECT_RECORD;
  END;

  BEGIN

  INSERT INTO CMS_PRODUCT_PARAM(
                                CPP_INST_CODE,CPP_PROD_CODE,CPP_EMAIL_ID,CPP_INS_USER,
                                CPP_INS_DATE,CPP_LUPD_USER,CPP_LUPD_DATE,CPP_FROMEMAIL_ID,
                                CPP_APP_NAME,CPP_APPNTY_TYPE,CPP_KYCVERIFY_FLAG,CPP_NETWORKACQID_FLAG,
                                CPP_SHORT_CODE,CPP_CIP_INTVL,
                                --CPP_RENEW_PRODCODE,CPP_RENEW_CARDTYPE,
                                CPP_DUP_SSNCHK,CPP_DUP_TIMEPERIOD,CPP_DUP_TIMEUNT,
                                CPP_GPRFLAG_ACHTXN,CPP_ACCTUNLOCK_DURATION,CPP_WRONG_LOGONCOUNT,
                                CPP_PARTNER_ID,CPP_MMPOS_FEEPLAN,CPP_RENEWAL_PINMIGRATION,
                                CPP_ACHBLCKEXPRY_PERIOD,CPP_FEDERALCHECK_FLAG,CPP_PREAUTH_PRODFLAG,CPP_AGGREGATOR_ID,
                                CPP_TANDC_VERSION,CPP_B2BCARD_STAT,CPP_B2B_LMTPRFL,CPP_HOSTFLOOR_LIMIT,
                                CPP_SPD_FLAG,CPP_UPC,CPP_B2BFLNAME_FLAG,CPP_CLAWBACK_DESC,CPP_PRODUCT_TYPE,CPP_WEBAUTHMAPPING_ID,CPP_IVRAUTHMAPPING_ID,CPP_SUBBIN_LENGTH
                                )
                                VALUES(
                                p_instcode_in,p_prod_code_out,l_email_id,p_ins_user_in,
                                sysdate,p_ins_user_in,sysdate,l_fromemail_id,
                                l_app_name,l_appnty_type,l_kycverify_flag,l_networkacq_flag,
                                l_short_code,l_cip_intvl,
                                --l_renewprod_code,l_renewcard_type,
                                l_dup_ssnchk,l_dup_timeperiod,l_dup_timeout,
                                l_gprflag_achtxn,l_acctunlock_duration,l_wrong_logoncnt,
                                l_partner_id,l_mmpos_feeplan,l_renew_pinmigration,
                                l_achblkexpry_period,l_federalchk_flag,l_preauth_prodflag,l_aggregator_id,
                                l_tandc_version,l_b2bcard_stat,l_b2b_lmtprfl,l_hostflr_lmt,
                                l_spd_flag,l_upc,l_b2bfname_flag,l_clawback_desc,l_product_type,l_webauthmapping_id,l_ivrauthmapping_id,l_subbin_length
                                );

   EXCEPTION
            WHEN OTHERS
            THEN
             p_errmsg_out   :=
                     'ERROR WHILE INSERTING INTO CMS_PRODUCT_PARAM:'
                  || SUBSTR (SQLERRM, 1, 300);
               RAISE EXP_REJECT_RECORD;

 END;


  BEGIN
            FOR l_row_indx IN PRODNETWORKID_MAPPING(p_prod_code_in)
            LOOP
            INSERT INTO CMS_PRODNETWORKID_MAPPING(
                    CPM_INST_CODE,
                    CPM_PROD_CODE,
                    CPM_NETWORK_ID,
                    CPM_INS_USER_ID,
                    CPM_INS_DATE,
                    CPM_LUPD_USER,
                    CPM_LUPD_DATE)
                    VALUES(
                    p_instcode_in,
                    p_prod_code_out,
                    l_row_indx.VPM_NETWORK_ID,
                    p_ins_user_in,
                    SYSDATE,
                    p_ins_user_in,
                    SYSDATE);

            END LOOP;
            EXCEPTION
            WHEN OTHERS
            THEN
              p_errmsg_out  :=
                     'ERROR WHILE INSERTING INTO CMS_PRODNETWORKID_MAPPING:'
                  || SUBSTR (SQLERRM, 1, 300);
               RAISE EXP_REJECT_RECORD;

 END;

 BEGIN
            FOR l_row_indx IN PRODUCT_CARDPACK_STAG(p_prod_code_in)
            LOOP
            SELECT COUNT(*) INTO L_PACK_ID_CNT FROM VMS_PACKAGEID_MAST WHERE VPM_PACKAGE_ID=l_row_indx.VPC_CARD_DETAILS;
            IF L_PACK_ID_CNT = 0 THEN
                 INSERT INTO VMS_PACKAGEID_MAST(VPM_PACKAGE_ID,
                VPM_PACKAGE_DESC,VPM_REPLACEMENT_PACKAGE_ID,VPM_VENDOR_ID,VPM_SHIP_METHODS,VPM_INS_DATE,
                VPM_INS_USER,VPM_LUPD_DATE,VPM_LUPD_USER,VPM_EXP_REPLACESHIPMETHOD,VPM_REPLACE_SHIPMETHOD)
                (SELECT VPM_PACKAGE_ID,VPM_PACKAGE_DESC,VPM_REPLACEMENT_PACKAGE_ID,VPM_VENDOR_ID,VPM_SHIP_METHODS,
                VPM_INS_DATE,VPM_INS_USER,VPM_LUPD_DATE,VPM_LUPD_USER,VPM_EXP_REPLACESHIPMETHOD,VPM_REPLACE_SHIPMETHOD 
                FROM VMS_PACKAGEID_MAST_STAG WHERE VPM_PACKAGE_ID=l_row_indx.VPC_CARD_DETAILS);
                
                INSERT INTO VMS_PACKAGEID_DETL(VPD_PACKAGE_ID,VPD_FIELD_KEY,VPD_FIELD_VALUE,VPD_INS_DATE,VPD_INS_USER,VPD_LUPD_DATE,VPD_LUPD_USER)
                (SELECT VPD_PACKAGE_ID,VPD_FIELD_KEY,VPD_FIELD_VALUE,VPD_INS_DATE,VPD_INS_USER,VPD_LUPD_DATE,VPD_LUPD_USER
                FROM VMS_PACKAGEID_DETL_STAG WHERE VPD_PACKAGE_ID=l_row_indx.VPC_CARD_DETAILS);
            END IF;
            
            INSERT INTO CMS_PROD_CARDPACK(
                    CPC_INST_CODE,
                    CPC_PROD_CODE,
                    CPC_CARD_DETAILS,
                    CPC_PRINT_VENDOR,
                    CPC_INST_REPLACEMENT_FLAG,
                    CPC_CARD_ID)
                    VALUES(
                    p_instcode_in,
                    p_prod_code_out,
                    l_row_indx.VPC_CARD_DETAILS,
                    l_row_indx.VPC_PRINT_VENDOR,
                    L_ROW_INDX.VPC_INST_REPLACEMENT_FLAG,
                    SEQ_CARD_PACKAGE_ID.nextval);
            END LOOP;
            EXCEPTION
            WHEN OTHERS
            THEN
              p_errmsg_out  :=
                     'ERROR WHILE INSERTING INTO CMS_PROD_CARDPACK:'
                  || SUBSTR (SQLERRM, 1, 300);
               RAISE EXP_REJECT_RECORD;

 END;

 BEGIN
            FOR l_row_indx IN SCORECARD_PRODMAPPING(p_prod_code_in)
            LOOP

            INSERT INTO CMS_SCORECARD_PRODMAPPING(
                    CSP_INST_CODE,
                    CSP_SCORECARD_ID,
                    CSP_PROD_CODE,
                    CSP_DELIVERY_CHANNEL,
                    CSP_CIPCARD_STAT,
                    CSP_AVQ_FLAG,
                    CSP_INS_USER,
                    CSP_INS_DATE,
                    CSP_LUPD_USER,
                    CSP_LUPD_DATE)
                    VALUES(
                    p_instcode_in,
                    l_row_indx.VSP_SCORECARD_ID,
                    p_prod_code_out,
                    l_row_indx.VSP_DELIVERY_CHANNEL,
                    l_row_indx.VSP_CIPCARD_STAT,
                    l_row_indx.VSP_AVQ_FLAG,
                    p_ins_user_in,
                    SYSDATE,
                    p_ins_user_in,
                    SYSDATE);

            END LOOP;
            EXCEPTION
            WHEN OTHERS
            THEN
              p_errmsg_out  :=
                     'ERROR WHILE INSERTING INTO CMS_SCORECARD_PRODMAPPING:'
                  || SUBSTR (SQLERRM, 1, 300);
               RAISE EXP_REJECT_RECORD;

 END;

 EXCEPTION
  WHEN EXP_REJECT_RECORD THEN
  ROLLBACK;-- TO l_savepoint;
  WHEN OTHERS THEN
  ROLLBACK;-- TO l_savepoint;
  p_errmsg_out := 'Exception while copying PRODUCT_PARAMETER_MAST:' ||p_errmsg_out || SUBSTR(SQLERRM, 1, 200);


END;

--End product parameter temp to mast

--Start product categpry temp to mast

PROCEDURE  PRODCATG_PARAMETER_MAST (
   p_instcode_in            IN       NUMBER,
   p_ins_user_in            IN       NUMBER,
   p_prod_code_in           IN       VARCHAR2,
   p_prod_catg_in           IN       VARCHAR2,
   p_toprod_code_in          IN       VARCHAR2,
   p_errmsg_out             OUT      VARCHAR2
)
IS

/**********************************************************************************************


  * Created by                  : MageshKumar S.
  * Created Date                : 07-MAR-16
  * Created For                 : HOSTCC-57
  * Created reason              : PRODUCT CATEGORY TEMP TO MAST COPY PROGRAM
  * Reviewer                    : SARAVANAKUMAR/SPANKAJ
  * Build Number                : VMSGPRHOSTCSD4.0_B0001

  * Created by                  : Siva Kumar M.
  * Created Date                : 25-May-16
  * Created For                 : MVHOST-1346
  * Created reason              : Product Category Configuration for Starter Card
  * Reviewer                    : SARAVANAKUMAR/SPANKAJ
  * Build Number                : VMSGPRHOSTCSD4.1_B0001

  * Modified by      : MageshKumar S
   * Modified For     : CLVMS-124
   * Modified Date    : 08-JUNE-2016
   * Reviewer         : Saravanan/Spankaj
   * Build Number     : VMSGPRHOSTCSD4.2_B0001

     * Modified by      : Siva Kumar M
     * Modified For     : FSS-4423
     * Modified Date    : 25-May-2016
     * Modified reason  : Changes for tokenization
     * Reviewer         : Saravankumar/Spankaj
     * Build Number     : VMSGPRHOST4.4_B0001

    * Modified by      : Siva Kumar M
     * Modified For     : FSS-4423
     * Modified Date    : 07-July-2016
     * Modified reason  : Tokenization Changes
     * Reviewer         : Saravankumar/Spankaj
     * Build Number     : VMSGPRHOST4.5_B0002

     * Modified by      : MageshKumar S
     * Modified For     : FSS-4782
     * Modified Date    : 30-SEP-2016
     * Reviewer         : Saravanan/Spankaj
     * Build Number     : VMSGPRHOSTCSD4.2.5_B0001

     * Modified by      : Sreeja T
     * Modified For     : FSS-5323
     * Modified Date    : 10-nov-2017
     * Modified reason  : Recurring Transaction Flag
     * Reviewer         : Saravankumar/Spankaj
     * Build Number     : VMSGPRHOSTCSD17.11_B0001
     
     * Modified by      : Mageshkumar 
     * Modified For     : VMS-180
     * Modified Date    : 23-JAN-2018
     * Reviewer         : Saravankumar
     * Build Number     : VMSGPRHOSTCSD18.01
     
     * Modified by      : Siva Kumar M
     * Modified For     : VMS-354
     * Modified Date    : 02-July-2018
     * Reviewer         : Saravankumar
     * Build Number     : R03
     
   * Modified by      : Narayana
   * Modified For     : VMS-1048 (VMS Host Configure new product in Dev A to replicate to other lower environments)
   * Modified Date    : 13-AUG-2019
   * Reviewer         : Saravanakumar
   * Build Number     : R19_B0002  
   
   * Modified by      : Ubaidur Rahman.H
   * Modified For     : VMS-1127.
   * Modified Date    : 09-OCT-2019
   * Reviewer         : Saravanakumar
   * Build Number     : R20_B0003

**************************************************************************************************/
--l_savepoint           NUMBER                              DEFAULT 1;
EXP_REJECT_RECORD EXCEPTION;
l_card_type            cms_prod_cattype.CPC_CARD_TYPE%type;
l_cardtype_desc        cms_prod_cattype.CPC_CARDTYPE_DESC%type;
l_vendor               cms_prod_cattype.CPC_VENDOR%type;
l_stock                cms_prod_cattype.CPC_STOCK%type;
l_cardtype_sname       cms_prod_cattype.CPC_CARDTYPE_SNAME%type;
l_prod_prefix          cms_prod_cattype.CPC_PROD_PREFIX%type;
l_rulegroup_code       cms_prod_cattype.CPC_RULEGROUP_CODE%type;
l_profile_code         cms_prod_cattype.CPC_PROFILE_CODE%type;
l_prod_id              cms_prod_cattype.CPC_PROD_ID%type;
l_package_id           cms_prod_cattype.CPC_PACKAGE_ID%type;
l_achtxn_flg           cms_prod_cattype.CPC_ACHTXN_FLG%type;
l_achtxn_cnt           cms_prod_cattype.CPC_ACHTXN_CNT%type;
l_achtxn_amt           cms_prod_cattype.CPC_ACHTXN_AMT%type;
l_achtxn_deposit       cms_prod_cattype.CPC_ACHTXN_DEPOSIT%type;
l_sec_code             cms_prod_cattype.CPC_SEC_CODE%type;
l_min_agekyc           cms_prod_cattype.CPC_MIN_AGE_KYC%type;
l_passive_time         cms_prod_cattype.CPC_PASSIVE_TIME%type;
l_achtxn_daycnt        cms_prod_cattype.CPC_ACHTXN_DAYCNT%type;
l_achtxn_dayamt        cms_prod_cattype.CPC_ACHTXN_DAYMAXAMT%type;
l_achtxn_weekcnt       cms_prod_cattype.CPC_ACHTXN_WEEKCNT%type;
l_achtxn_weekmaxamt    cms_prod_cattype.CPC_ACHTXN_WEEKMAXAMT%type;
l_achtxn_moncnt        cms_prod_cattype.CPC_ACHTXN_MONCNT%type;
l_achtxn_monmaxamt     cms_prod_cattype.CPC_ACHTXN_MONMAXAMT%type;
l_achtxn_maxtranamt    cms_prod_cattype.CPC_ACHTXN_MAXTRANAMT%type;
l_achtxn_mintranamt    cms_prod_cattype.CPC_ACHTXN_MINTRANAMT%type;
l_starter_card         cms_prod_cattype.CPC_STARTER_CARD%type;
l_starter_minload      cms_prod_cattype.CPC_STARTER_MINLOAD%type;
l_starter_maxload      cms_prod_cattype.CPC_STARTER_MAXLOAD%type;
l_startergpr_cardtype  cms_prod_cattype.CPC_STARTERGPR_CRDTYPE%type;
l_strgpr_issue         cms_prod_cattype.CPC_STARTERGPR_ISSUE%type;
l_acctprod_prefix      cms_prod_cattype.CPC_ACCT_PROD_PREFIX%type;
l_serl_flag            cms_prod_cattype.CPC_SERL_FLAG%type;
l_del_met              cms_prod_cattype.CPC_DEL_MET%type;
l_achmin_iniload       cms_prod_cattype.CPC_ACHMIN_INITIAL_LOAD%type;
l_url                  cms_prod_cattype.CPC_URL%type;
L_PIN_APP              CMS_PROD_CATTYPE.CPC_PIN_APPLICABLE%TYPE;
l_dfltpin_flag         cms_prod_cattype.CPC_DFLTPIN_FLAG %type;
l_locchk_flag          cms_prod_cattype.CPC_LOCCHECK_FLAG%type;
l_scorecard_id         cms_prod_cattype.CPC_SCORECARD_ID%type;
l_ach_loadamtchk       cms_prod_cattype.CPC_ACH_LOADAMNT_CHECK%type;
l_crdexp_pend          cms_prod_cattype.CPC_CRDEXP_PENDING%type;
l_repl_period          cms_prod_cattype.CPC_REPL_PERIOD%type;
l_invchk_flag          cms_prod_cattype.CPC_INVCHECK_FLAG%type;
l_sec_code1            cms_prod_catsec.cpc_sec_code%type;
l_tran_code            cms_prod_catsec.cpc_tran_code%type;
l_ctrl_no              PLS_INTEGER default 0;
l_card_id              VMS_PRODCAT_CARDPACK_STAG.VPC_CARD_ID%type;
l_defcard_id           VMS_PRODCAT_CARDPACK_STAG.VPC_CARD_ID%type;
l_issuer_guid          VMS_PRODCAT_CARDPACK_STAG.VPC_ISSUER_GUID%type;
l_art_guid             VMS_PRODCAT_CARDPACK_STAG.VPC_ART_GUID%type;
l_tc_guid              VMS_PRODCAT_CARDPACK_STAG.VPC_TC_GUID%type;
l_strcrd_dispname      VMS_PROD_CATTYPE_STAG.VPC_STARTERCARD_DISPNAME%type;
l_strrepl_option       VMS_PROD_CATTYPE_STAG.VPC_STARTER_REPLACEMENT%type;
l_repl_prodcatg        VMS_PROD_CATTYPE_STAG.VPC_REPLACEMENT_CATTYPE%type;
l_token_eligible       vms_prod_cattype_stag.VPC_TOKEN_ELIGIBILITY%type;
l_prov_retrymax        vms_prod_cattype_stag.VPC_TOKEN_PROVISION_RETRY_MAX%type;
l_token_retainperiod   vms_prod_cattype_stag.VPC_TOKEN_RETAIN_PERIOD%type;
l_TOKEN_CUSTUPDDURATION   vms_prod_cattype_stag.VPC_TOKEN_CUST_UPD_DURATION%TYPE;
--l_token_custupd_frncy   vms_prod_cattype_stag.VPC_TOKEN_CUST_UPD_FREQUENCY%TYPE;
l_default_pin_selected CMS_PROD_CATTYPE.CPC_DEFAULT_PIN_OPTION%type;
l_exp_date_exemption cms_prod_cattype.cpc_exp_date_exemption%type;
l_logo_id            cms_prod_cattype.cpc_logo_id%type;
l_redemption_delay    cms_prod_cattype.CPC_REDEMPTION_DELAY_FLAG%type;--added for FSS-4647
l_CVVPLUS_ELIGIBILITY cms_prod_cattype.CPC_CVVPLUS_ELIGIBILITY%type;--added for cvvplus
l_CVVPlus_Short_Name  cms_prod_cattype.CPC_CVVPlus_Short_Name%type;--added for cvvplus
l_SWEEP_PERIOD        cms_prod_cattype.CPC_ADDL_SWEEP_PERIOD%type;--added for FSS-4619 sweep
l_SWEEP_FLAG          CMS_PROD_CATTYPE.CPC_SWEEP_FLAG%TYPE;--added for FSS-4619 sweep
l_b2b_Flag              CMS_PROD_CATTYPE.CPC_B2B_FLAG%TYPE;--ADDED FOR B2b Config
l_b2b_cardstat          CMS_prod_cattype.CPC_B2BCARD_STAT%TYPE;--ADDED FOR B2B CONFIG
l_b2b_actCode           CMS_prod_cattype.CPC_B2B_ACTIVATION_CODE%TYPE;--ADDED FOR B2B CONFIG
l_b2b_lmtprof           CMS_prod_cattype.CPC_B2B_LMTPRFL%TYPE;--ADDED FOR B2B CONFIG
l_b2b_regmatch          CMS_prod_cattype.CPC_B2BFLNAME_FLAG%TYPE;--ADDED FOR B2B CONFIG
l_InactivetoknretainPer  CMS_prod_cattype.CPC_INACTIVETOKEN_RETAINPERIOD%TYPE;--ADDED FOR master card
l_kyc_flag               CMS_prod_cattype.CPC_KYC_FLAG%TYPE;
l_cvv2_verification_flag    CMS_prod_cattype.CPC_CVV2_VERIFICATION_FLAG%TYPE;
l_expiry_date_check_flag      CMS_prod_cattype.CPC_EXPIRY_DATE_CHECK_FLAG%TYPE;
l_acct_balance_check_flag     CMS_prod_cattype.CPC_ACCT_BALANCE_CHECK_FLAG%TYPE;
l_replacement_provision_flag   CMS_prod_cattype.CPC_REPLACEMENT_PROVISION_FLAG%TYPE;
l_acct_balance_check_type   CMS_prod_cattype.CPC_ACCT_BAL_CHECK_TYPE%TYPE;
l_acct_balance_check_value   CMS_prod_cattype.CPC_ACCT_BAL_CHECK_VALUE%TYPE;
l_issu_prodconfig_id      CMS_prod_cattype.CPC_ISSU_PRODCONFIG_ID%TYPE;
l_consumed_flag           CMS_prod_cattype.CPC_CONSUMED_FLAG%TYPE;
l_consumed_card_stat      CMS_prod_cattype.CPC_CONSUMED_CARD_STAT%TYPE;
l_renew_replace_option    CMS_prod_cattype.CPC_RENEW_REPLACE_OPTION%TYPE;
l_renew_replace_prodcode    CMS_prod_cattype.CPC_RENEW_REPLACE_PRODCODE%TYPE;
L_RENEW_REPLACE_CARDTYPE    CMS_PROD_CATTYPE.CPC_RENEW_REPLACE_CARDTYPE%TYPE;
l_REGISTRATION_TYPE         CMS_PROD_CATTYPE.CPC_USER_IDENTIFY_TYPE%TYPE;
l_RELOADABLE_FLAG           CMS_PROD_CATTYPE.CPC_RELOADABLE_FLAG%TYPE;
l_PROD_SUFFIX               CMS_PROD_CATTYPE.CPC_PROD_SUFFIX%TYPE;
l_START_CARD_NO              CMS_PROD_CATTYPE.CPC_START_CARD_NO%TYPE;
l_END_CARD_NO               CMS_PROD_CATTYPE.CPC_END_CARD_NO%TYPE;
L_CCF_FORMAT_VERSION        CMS_PROD_CATTYPE.CPC_CCF_FORMAT_VERSION %TYPE;
l_DCMS_ID                   CMS_PROD_CATTYPE.CPC_DCMS_ID %TYPE;
l_PRODUCT_UPC               CMS_PROD_CATTYPE.CPC_PRODUCT_UPC %TYPE;
l_PACKING_UPC               CMS_PROD_CATTYPE.CPC_PACKING_UPC %TYPE;
l_PROD_DENOM                CMS_PROD_CATTYPE.CPC_PROD_DENOM %TYPE;
l_PDENOM_MIN                CMS_PROD_CATTYPE.CPC_PDENOM_MIN %TYPE;
l_PDENOM_MAX                CMS_PROD_CATTYPE.CPC_PDENOM_MAX %TYPE;
l_PDENOM_FIX                CMS_PROD_CATTYPE.CPC_PDENOM_FIX %TYPE;
l_ISSU_BANK                 CMS_PROD_CATTYPE.CPC_ISSU_BANK %TYPE;
l_ICA	                      CMS_PROD_CATTYPE.CPC_ICA	 %TYPE;
l_ISSU_BANK_ADDR            CMS_PROD_CATTYPE.CPC_ISSU_BANK_ADDR %TYPE;
l_CARDPROD_ACCEPT           CMS_PROD_CATTYPE.CPC_CARDPROD_ACCEPT %TYPE;
l_STATE_RESTRICT             CMS_PROD_CATTYPE.CPC_STATE_RESTRICT %TYPE;
l_PIF_SIA_CASE               CMS_PROD_CATTYPE.CPC_PIF_SIA_CASE %TYPE;
L_DISABLE_REPL_FLAG          CMS_PROD_CATTYPE.CPC_DISABLE_REPL_FLAG %TYPE;
l_DISABLE_REPL_EXPRYDAYS     CMS_PROD_CATTYPE.CPC_DISABLE_REPL_EXPRYDAYS %TYPE;
l_DISABLE_REPL_MINBAL        CMS_PROD_CATTYPE.CPC_DISABLE_REPL_MINBAL %TYPE;
l_PAN_INVENTORY_FLAG         CMS_PROD_CATTYPE.CPC_PAN_INVENTORY_FLAG %TYPE;
l_ACCTUNLOCK_DURATION       CMS_PROD_CATTYPE.CPC_ACCTUNLOCK_DURATION %TYPE;
l_WRONG_LOGONCOUNT           CMS_PROD_CATTYPE.CPC_WRONG_LOGONCOUNT %TYPE;
l_ACHBLCKEXPRY_PERIOD        CMS_PROD_CATTYPE.CPC_ACHBLCKEXPRY_PERIOD %TYPE;
l_RENEWAL_PINMIGRATION       CMS_PROD_CATTYPE.CPC_RENEWAL_PINMIGRATION %TYPE;
l_FEDERALCHECK_FLAG          CMS_PROD_CATTYPE.CPC_FEDERALCHECK_FLAG %TYPE;
l_TANDC_VERSION              CMS_PROD_CATTYPE.CPC_TANDC_VERSION %TYPE;
l_CLAWBACK_DESC              CMS_PROD_CATTYPE.CPC_CLAWBACK_DESC %TYPE;
l_WEBAUTHMAPPING_ID          CMS_PROD_CATTYPE.CPC_WEBAUTHMAPPING_ID %TYPE;
l_IVRAUTHMAPPING_ID          CMS_PROD_CATTYPE.CPC_IVRAUTHMAPPING_ID %TYPE;
l_EMAIL_ID                   CMS_PROD_CATTYPE.CPC_EMAIL_ID %TYPE;
l_FROMEMAIL_ID               CMS_PROD_CATTYPE.CPC_FROMEMAIL_ID %TYPE;
l_APP_NAME                   CMS_PROD_CATTYPE.CPC_APP_NAME %TYPE;
l_APPNTY_TYPE                CMS_PROD_CATTYPE.CPC_APPNTY_TYPE %TYPE;
l_KYCVERIFY_FLAG             CMS_PROD_CATTYPE.CPC_KYCVERIFY_FLAG %TYPE;
l_NETWORKACQID_FLAG          CMS_PROD_CATTYPE.CPC_NETWORKACQID_FLAG %TYPE;
l_SHORT_CODE                 CMS_PROD_CATTYPE.CPC_SHORT_CODE %TYPE;
l_CIP_INTVL                  CMS_PROD_CATTYPE.CPC_CIP_INTVL %TYPE;
l_DUP_SSNCHK                 CMS_PROD_CATTYPE.CPC_DUP_SSNCHK %TYPE;
l_PINCHANGE_FLAG             CMS_PROD_CATTYPE.CPC_PINCHANGE_FLAG %TYPE;
l_OLSRESP_FLAG               CMS_PROD_CATTYPE.CPC_OLSRESP_FLAG %TYPE;
l_EMV_FLAG                   CMS_PROD_CATTYPE.CPC_EMV_FLAG %TYPE;
l_INSTITUTION_ID             CMS_PROD_CATTYPE.CPC_INSTITUTION_ID %TYPE;
l_TRANSIT_NUMBER             CMS_PROD_CATTYPE.CPC_TRANSIT_NUMBER %TYPE;
l_RANDOM_PIN                 CMS_PROD_CATTYPE.CPC_RANDOM_PIN %TYPE;
l_ONUS_AUTH_EXPIRY           CMS_PROD_CATTYPE.CPC_ONUS_AUTH_EXPIRY %TYPE;
l_FROM_DATE                  CMS_PROD_CATTYPE.CPC_FROM_DATE %TYPE;
l_POA_PROD                   CMS_PROD_CATTYPE.CPC_POA_PROD %TYPE;
l_ROUT_NUM                   CMS_PROD_CATTYPE.CPC_ROUT_NUM %TYPE;
l_OLS_EXPIRY_FLAG            CMS_PROD_CATTYPE.CPC_OLS_EXPIRY_FLAG %TYPE;
l_STATEMENT_FOOTER           CMS_PROD_CATTYPE.CPC_STATEMENT_FOOTER %TYPE;
l_DUP_TIMEPERIOD             CMS_PROD_CATTYPE.CPC_DUP_TIMEPERIOD %TYPE;
l_DUP_TIMEUNT                CMS_PROD_CATTYPE.CPC_DUP_TIMEUNT %TYPE;
l_GPRFLAG_ACHTXN             CMS_PROD_CATTYPE.CPC_GPRFLAG_ACHTXN %TYPE;
L_DISABLE_REPL_MESSAGE       CMS_PROD_CATTYPE.CPC_DISABLE_REPL_MESSAGE %TYPE;
L_CCF_SERIAL_FLAG            CMS_PROD_CATTYPE.CPC_CCF_SERIAL_FLAG %TYPE;
L_PRODCAT_THRESHOLD1          VMS_PRODCAT_THRESHOLD.VPT_PROD_THRESHOLD%TYPE;
l_network_id               VMS_PRODCAT_NETWORKID_MAPPING.VPN_NETWORK_ID%type;
l_delivery_channel         VMS_SCORECARD_PRODCAT_MAPPING.VSP_DELIVERY_CHANNEL%type;
l_cipcard_stat           VMS_SCORECARD_PRODCAT_MAPPING.VSP_CIPCARD_STAT%type;
l_avq_flag            VMS_SCORECARD_PRODCAT_MAPPING.VSP_AVQ_FLAG%type;
l_pden_val           VMS_PRODCAT_DENO_MAST. VPD_PDEN_VAL%type;
L_DENO_STATUS       VMS_PRODCAT_DENO_MAST.VPD_DENO_STATUS%TYPE;
L_PROG_ID             CMS_PROD_CATTYPE.CPC_PROGRAM_ID %TYPE;
L_PROXY_LEN            CMS_PROD_CATTYPE.CPC_PROXY_LENGTH%TYPE;
L_ISCHCEK_REQ          CMS_PROD_CATTYPE.CPC_CHECK_DIGIT_REQ%type;
l_ISPRG_ID_REQ        CMS_PROD_CATTYPE.CPC_PROGRAMID_REQ%type;
l_GET_SEQ_QUERY   VARCHAR2(500);
l_DEF_COND_APPR_FLAG             CMS_PROD_CATTYPE.CPC_DEF_COND_APPR%TYPE;
L_SEQ_NO        PLS_INTEGER;
L_CUSTOMER_CARE_NUM   CMS_PROD_CATTYPE.CPC_CUSTOMER_CARE_NUM%TYPE;
l_UPGRADE_ELIGIBLE_FLAG CMS_PROD_CATTYPE.CPC_UPGRADE_ELIGIBLE_FLAG%TYPE;
l_CCF_3DIGCSCREQ           CMS_PROD_CATTYPE.CPC_CCF_3DIGCSCREQ%TYPE;
l_DEFAULT_PARTIAL_INDR           CMS_PROD_CATTYPE.CPC_DEFAULT_PARTIAL_INDR%TYPE;
l_SERIALNO_FILEPATH        CMS_PROD_CATTYPE.CPC_SERIALNO_FILEPATH%TYPE;
l_RETAIL_ACTIVATION            CMS_PROD_CATTYPE.CPC_RETAIL_ACTIVATION%TYPE;
l_AVS_REQUIRED           CMS_PROD_CATTYPE.CPC_ADDR_VERIFICATION_CHECK%TYPE;
L_ADDR_VERIF_RESP        CMS_PROD_CATTYPE.CPC_ADDR_VERIFICATION_RESPONSE%TYPE;
l_RECURRING_TRAN_FLAG        CMS_PROD_CATTYPE.CPC_RECURRING_TRAN_FLAG%TYPE;
l_INTERNATIONAL_TRAN      CMS_PROD_CATTYPE.CPC_INTERNATIONAL_CHECK%TYPE;
L_Emv_Fallback         Cms_Prod_Cattype.Cpc_Emv_Fallback%Type;
L_Fund_Mcc         Cms_Prod_Cattype.Cpc_Fund_Mcc%Type;
L_Settl_Mcc         Cms_Prod_Cattype.Cpc_Settl_Mcc%Type;
L_Badcrd_Flag       Cms_Prod_Cattype.Cpc_Badcredit_Flag%Type;
L_Badcr_Transgrp    Cms_Prod_Cattype.Cpc_Badcredit_Transgrpid%Type;
l_encrypt_enable     cms_prod_cattype.cpc_encrypt_enable%type;
REF_CUR_PRODCATG SYS_REFCURSOR;
REF_CUR_PRODCATG_SECCODE SYS_REFCURSOR;
REF_CUR_PRODCATG_CARDID  SYS_REFCURSOR;
ref_cur_prodcatg_threshold sys_refcursor;
REF_CUR_PRODCAT_NETMAP SYS_REFCURSOR;
REF_CUR_SCORECD_PRODCAT_MAP SYS_REFCURSOR;
REF_CUR_PRODCAT_DENO SYS_REFCURSOR;

l_alert_card_stat   cms_prod_Cattype.CPC_ALERT_CARD_STAT%type;
l_alert_card_amnt   cms_prod_Cattype.CPC_ALERT_CARD_AMOUNT%type;
l_alert_card_days   cms_prod_Cattype.CPC_ALERT_CARD_DURATION%type;
l_src_app           cms_prod_Cattype.CPC_SRC_APP%type;
l_src_app_flag      cms_prod_Cattype.CPC_SRC_APP_FLAG%type;
L_Valins_Act_Flag       Cms_Prod_Cattype.Cpc_Valins_Act_Flag %Type;
L_Deactivation_Closed   Cms_Prod_Cattype.Cpc_Deactivation_Closed % Type;
l_DOUBLEOPTINNTY_TYPE  Cms_Prod_Cattype.CPC_DOUBLEOPTINNTY_TYPE  % Type;
l_PRODUCT_FUNDING      Cms_Prod_Cattype.CPC_PRODUCT_FUNDING  % Type;
l_FUND_AMOUNT          Cms_Prod_Cattype.CPC_FUND_AMOUNT  % Type;
L_Instore_Replacement  Cms_Prod_Cattype.Cpc_Instore_Replacement % Type;
l_Packageid_Check       Cms_Prod_Cattype.cpc_Packageid_Check % Type;
l_mallid_check    cms_prod_cattype.CPC_MALLID_CHECK % Type;
l_malllocation_check   cms_prod_cattype.CPC_MALLLOCATION_CHECK % Type;
l_OFAC_CHECK            Cms_Prod_Cattype.cpc_OFAC_CHECK % Type;
l_PARTNER_ID            cms_prod_cattype.CPC_PARTNER_ID % Type;
l_DOB_MANDATORY_FLAG  CMS_PROD_CATTYPE.CPC_DOB_MANDATORY%TYPE;
L_STANDINGAUTH_TRAN_FLAG CMS_PROD_CATTYPE.CPC_STNGAUTH_FLAG%TYPE;
L_BYPASS_INITIAL_LOADCHK CMS_PROD_CATTYPE.CPC_BYPASS_LOADCHECK%TYPE;
L_ISSUBANK_ID			VMS_PROD_CATTYPE_STAG.VPC_ISSUBANK_ID%type;
L_EVENT_NOTIFICATION	VMS_PROD_CATTYPE_STAG.VPC_EVENT_NOTIFICATION%type;
L_PARTNER_NAME			VMS_PROD_CATTYPE_STAG.VPC_PARTNER_NAME%type;
L_PIN_RESET_OPTION		VMS_PROD_CATTYPE_STAG.VPC_PIN_RESET_OPTION%type;
L_PRODUCT_PORTFOLIO        VMS_PROD_CATTYPE_STAG.VPC_PRODUCT_PORTFOLIO%type;
BEGIN

 p_errmsg_out  := 'OK';
-- SAVEPOINT l_savepoint;

--  BEGIN
--                 SELECT lpad(SEQ_PRODUCT_ID.nextval,5,0) INTO l_product_id FROM DUAL;
--              EXCEPTION
--                 WHEN OTHERS
--                 THEN
--                    P_ERRMSG_OUT :=
--                       'Error while getting product id seq:' || SUBSTR (SQLERRM, 1, 200);
--                    RETURN;
--              END;
  BEGIN

   OPEN ref_cur_prodcatg FOR
   'SELECT A.VPC_CARD_TYPE,A.VPC_CARDTYPE_DESC,A.VPC_VENDOR,VPC_STOCK,
    A.VPC_CARDTYPE_SNAME,A.VPC_PROD_PREFIX,A.VPC_RULEGROUP_CODE,B.VPC_NEWPROF_CODE,
    A.VPC_PROD_ID,A.VPC_PACKAGE_ID,A.VPC_ACHTXN_FLG,A.VPC_ACHTXN_CNT,
    A.VPC_ACHTXN_AMT,A.VPC_ACHTXN_DEPOSIT,A.VPC_SEC_CODE,A.VPC_MIN_AGE_KYC,
    A.VPC_PASSIVE_TIME,A.VPC_ACHTXN_DAYCNT,A.VPC_ACHTXN_DAYMAXAMT,A.VPC_ACHTXN_WEEKCNT,
    A.VPC_ACHTXN_WEEKMAXAMT,A.VPC_ACHTXN_MONCNT,A.VPC_ACHTXN_MONMAXAMT,A.VPC_ACHTXN_MAXTRANAMT,
    A.VPC_ACHTXN_MINTRANAMT,A.VPC_STARTER_CARD,A.VPC_STARTER_MINLOAD,A.VPC_STARTER_MAXLOAD,
    A.VPC_STARTERGPR_CRDTYPE,A.VPC_STARTERGPR_ISSUE,A.VPC_ACCT_PROD_PREFIX,A.VPC_SERL_FLAG,
    A.VPC_DEL_MET,A.VPC_ACHMIN_INITIAL_LOAD,A.VPC_URL,A.VPC_PIN_APPLICABLE,
    A.VPC_DFLTPIN_FLAG,A.VPC_LOCCHECK_FLAG,A.VPC_SCORECARD_ID,A.VPC_ACH_LOADAMNT_CHECK,
    A.VPC_CRDEXP_PENDING,A.VPC_REPL_PERIOD,A.VPC_INVCHECK_FLAG,A.vpc_card_id,A.VPC_STARTERCARD_DISPNAME,
    A.VPC_STARTER_REPLACEMENT,A.VPC_REPLACEMENT_CATTYPE,A.VPC_TOKEN_ELIGIBILITY,A.VPC_TOKEN_PROVISION_RETRY_MAX,A.VPC_TOKEN_RETAIN_PERIOD,A.VPC_TOKEN_CUST_UPD_DURATION,A.VPC_DEFAULT_PIN_OPTION,a.vpc_exp_date_exemption,a.vpc_logo_id,a.VPC_REDEMPTION_DELAY_FLAG,a.VPC_CVVPLUS_ELIGIBILITY,a.VPC_CVVPlus_Short_Name,a.VPC_SWEEP_FLAG,a.VPC_ADDL_SWEEP_PERIOD,
    A.VPC_B2B_FLAG, A.VPC_B2BCARD_STAT, A.VPC_B2B_ACTIVATION_CODE, A.VPC_B2B_LMTPRFL,A.VPC_B2BFLNAME_FLAG,A.VPC_INACTIVETOKEN_RETAINPERIOD,
    A.VPC_KYC_FLAG,A.VPC_CVV2_VERIFICATION_FLAG,A.VPC_EXPIRY_DATE_CHECK_FLAG,A.VPC_ACCT_BALANCE_CHECK_FLAG,A.VPC_REPLACEMENT_PROVISION_FLAG,
    A.VPC_ACCT_BAL_CHECK_TYPE,A.VPC_ACCT_BAL_CHECK_VALUE,A.VPC_ISSU_PRODCONFIG_ID,A.VPC_CONSUMED_FLAG,A.VPC_CONSUMED_CARD_STAT,A.VPC_RENEW_REPLACE_OPTION,A.VPC_RENEW_REPLACE_PRODCODE,A.VPC_RENEW_REPLACE_CARDTYPE,
    A.VPC_USER_IDENTIFY_TYPE,A.VPC_RELOADABLE_FLAG,A.VPC_PROD_SUFFIX,A.VPC_START_CARD_NO,A.VPC_END_CARD_NO,A.VPC_CCF_FORMAT_VERSION,
    A.VPC_DCMS_ID,
    A.VPC_PRODUCT_UPC,A.VPC_PACKING_UPC, A.VPC_PROD_DENOM, A.VPC_PDENOM_MIN,  A.VPC_PDENOM_MAX,  A.VPC_PDENOM_FIX	, A.VPC_ISSU_BANK,
    A.VPC_ICA,A.VPC_ISSU_BANK_ADDR,A.VPC_CARDPROD_ACCEPT,A.VPC_STATE_RESTRICT,A.VPC_PIF_SIA_CASE, A.VPC_DISABLE_REPL_FLAG, A.VPC_DISABLE_REPL_EXPRYDAYS,
    A.VPC_DISABLE_REPL_MINBAL, A.VPC_DISABLE_REPL_MESSAGE, A.VPC_PAN_INVENTORY_FLAG, A.VPC_ACCTUNLOCK_DURATION,
    A.VPC_WRONG_LOGONCOUNT, A.VPC_ACHBLCKEXPRY_PERIOD, A.VPC_RENEWAL_PINMIGRATION, A.VPC_FEDERALCHECK_FLAG	, A.VPC_TANDC_VERSION, A.VPC_CLAWBACK_DESC,
    A.VPC_WEBAUTHMAPPING_ID, A.VPC_IVRAUTHMAPPING_ID, A.VPC_EMAIL_ID, A.VPC_FROMEMAIL_ID, A.VPC_APP_NAME, A.VPC_APPNTY_TYPE, A.VPC_KYCVERIFY_FLAG,
    A.VPC_NETWORKACQID_FLAG, A.VPC_SHORT_CODE, A.VPC_CIP_INTVL, A.VPC_DUP_SSNCHK, A.VPC_PINCHANGE_FLAG, A.VPC_OLSRESP_FLAG, A.VPC_EMV_FLAG,
    A.VPC_INSTITUTION_ID, A.VPC_TRANSIT_NUMBER, A.VPC_RANDOM_PIN	, A.VPC_POA_PROD, A.VPC_ONUS_AUTH_EXPIRY, A.VPC_FROM_DATE, A.VPC_ROUT_NUM,
    A.VPC_OLS_EXPIRY_FLAG, A.VPC_STATEMENT_FOOTER, A.VPC_DUP_TIMEPERIOD, A.VPC_DUP_TIMEUNT, A.VPC_GPRFLAG_ACHTXN,A.VPC_CCF_SERIAL_FLAG,A.VPC_PROGRAM_ID,A.VPC_PROXY_LENGTH,A.VPC_CHECK_DIGIT_REQ,A.VPC_PROGRAMID_REQ,A.VPC_DEF_COND_APPR,A.VPC_CUSTOMER_CARE_NUM,A.VPC_UPGRADE_ELIGIBLE_FLAG,A.VPC_CCF_3DIGCSCREQ,A.VPC_DEFAULT_PARTIAL_INDR,A.VPC_SERIALNO_FILEPATH,A.VPC_RETAIL_ACTIVATION,A.VPC_ADDR_VERIFICATION_CHECK,A.VPC_RECURRING_TRAN_FLAG, A.VPC_INTERNATIONAL_CHECK,A.vpc_Emv_Fallback,A.vpc_Fund_Mcc,A.vpc_Settl_Mcc,A.vpc_Badcredit_Flag,A.VPC_BADCREDIT_TRANSGRPID,A.vpc_encrypt_enable,
    A.VPC_ALERT_CARD_STAT,A.VPC_ALERT_CARD_AMOUNT,A.VPC_ALERT_CARD_DURATION,A.VPC_SRC_APP,A.VPC_SRC_APP_FLAG,A.VPC_ADDR_VERIFICATION_RESPONSE,A.VPC_VALINS_ACT_FLAG,A.VPC_DEACTIVATION_CLOSED,A.VPC_DOUBLEOPTINNTY_TYPE,A.VPC_PRODUCT_FUNDING,A.VPC_FUND_AMOUNT,A.VPC_INSTORE_REPLACEMENT,A.VPC_Packageid_Check,A.VPC_MALLID_CHECK,A.VPC_MALLLOCATION_CHECK,A.VPC_OFAC_CHECK,A.VPC_PARTNER_ID,A.VPC_DOB_MANDATORY,A.VPC_STNGAUTH_FLAG,A.VPC_BYPASS_LOADCHECK,
    A.VPC_ISSUBANK_ID,A.VPC_EVENT_NOTIFICATION,A.VPC_PARTNER_NAME,A.VPC_PIN_RESET_OPTION,A.VPC_PRODUCT_PORTFOLIO
    FROM VMS_PROD_CATTYPE_STAG A,VMS_PRODCATG_COPY_INFO B
    WHERE A.VPC_PROFILE_CODE = B.VPC_PROFILE_CODE
    AND A.VPC_PROD_CODE = B.VPC_PROD_CODE
    AND A.VPC_CARD_TYPE = B.VPC_CATG_CODE
    AND A.VPC_PROD_CODE='''||p_prod_code_in||''' AND A.VPC_CARD_TYPE IN('||p_prod_catg_in||')';
    LOOP
    FETCH ref_cur_prodcatg INTO l_card_type,l_cardtype_desc,l_vendor,l_stock,
    l_cardtype_sname,l_prod_prefix,l_rulegroup_code,
    l_profile_code,l_prod_id,l_package_id,l_achtxn_flg,l_achtxn_cnt,
    l_achtxn_amt,l_achtxn_deposit,l_sec_code,l_min_agekyc,
    l_passive_time,l_achtxn_daycnt,l_achtxn_dayamt,l_achtxn_weekcnt,
    l_achtxn_weekmaxamt,l_achtxn_moncnt,l_achtxn_monmaxamt,l_achtxn_maxtranamt,
    l_achtxn_mintranamt,l_starter_card,l_starter_minload,l_starter_maxload,
    l_startergpr_cardtype,l_strgpr_issue,l_acctprod_prefix,l_serl_flag,
    l_del_met,l_achmin_iniload,l_url,l_pin_app,
    l_dfltpin_flag,l_locchk_flag,l_scorecard_id,l_ach_loadamtchk,
    l_crdexp_pend,l_repl_period,l_invchk_flag,l_defcard_id,l_strcrd_dispname,
    l_strrepl_option,l_repl_prodcatg,l_token_eligible,l_prov_retrymax,l_token_retainperiod,l_TOKEN_CUSTUPDDURATION,l_default_pin_selected,l_exp_date_exemption,l_logo_id,l_redemption_delay,l_CVVPLUS_ELIGIBILITY,l_CVVPlus_Short_Name,l_SWEEP_FLAG,l_SWEEP_PERIOD
    ,l_b2b_Flag,l_b2b_cardstat,l_b2b_actCode,l_b2b_lmtprof,l_b2b_regmatch,l_InactivetoknretainPer,l_kyc_flag,
    l_cvv2_verification_flag,l_expiry_date_check_flag,l_acct_balance_check_flag,l_replacement_provision_flag,l_acct_balance_check_type,l_acct_balance_check_value
    ,L_ISSU_PRODCONFIG_ID,L_CONSUMED_FLAG,L_CONSUMED_CARD_STAT,L_RENEW_REPLACE_OPTION,L_RENEW_REPLACE_PRODCODE,L_RENEW_REPLACE_CARDTYPE,
    L_REGISTRATION_TYPE,L_RELOADABLE_FLAG,L_PROD_SUFFIX,L_START_CARD_NO,L_END_CARD_NO,L_CCF_FORMAT_VERSION,l_DCMS_ID,l_PRODUCT_UPC,l_PACKING_UPC,l_PROD_DENOM,
    L_PDENOM_MIN,L_PDENOM_MAX,L_PDENOM_FIX,L_ISSU_BANK,L_ICA,L_ISSU_BANK_ADDR,L_CARDPROD_ACCEPT,L_STATE_RESTRICT,L_PIF_SIA_CASE,L_DISABLE_REPL_FLAG,
    l_DISABLE_REPl_EXPRYDAYS,l_DISABLE_REPl_MINBAL,l_DISABLE_REPL_MESSAGE,l_PAN_INVENTORY_FLAG,l_ACCTUNLOCK_DURATION,l_WRONG_LOGONCOUNT,l_ACHBLCKEXPRY_PERIOD,
    l_RENEWAl_PINMIGRATION,l_FEDERALCHECK_FLAG,l_TANDC_VERSION,l_CLAWBACK_DESC,l_WEBAUTHMAPPING_ID,l_IVRAUTHMAPPING_ID,l_EMAIl_ID,l_FROMEMAIl_ID,
    L_APP_NAME,L_APPNTY_TYPE,L_KYCVERIFY_FLAG,L_NETWORKACQID_FLAG,L_SHORT_CODE,L_CIP_INTVL,L_DUP_SSNCHK,L_PINCHANGE_FLAG,L_OLSRESP_FLAG,L_EMV_FLAG,
    L_Institution_Id,L_Transit_Number,L_Random_Pin ,L_Poa_Prod,L_Onus_Auth_Expiry,L_From_Date,L_Rout_Num,L_Ols_Expiry_Flag,L_Statement_Footer,
    L_Dup_Timeperiod,L_Dup_Timeunt,L_Gprflag_Achtxn,L_Ccf_Serial_Flag,L_Prog_Id,L_Proxy_Len,L_Ischcek_Req,L_Isprg_Id_Req,L_Def_Cond_Appr_Flag,L_Customer_Care_Num,L_Upgrade_Eligible_Flag,L_Ccf_3digcscreq,L_Default_Partial_Indr,L_Serialno_Filepath,L_Retail_Activation,L_Avs_Required,L_Recurring_Tran_Flag,L_International_Tran,L_Emv_Fallback,L_Fund_Mcc,L_Settl_Mcc,L_Badcrd_Flag,L_Badcr_Transgrp,L_Encrypt_Enable,
    l_alert_card_stat,l_alert_card_amnt,l_alert_card_days,l_src_app,l_src_app_flag,L_ADDR_VERIF_RESP,L_VALINS_ACT_FLAG,L_DEACTIVATION_CLOSED,l_DOUBLEOPTINNTY_TYPE,l_PRODUCT_FUNDING,l_FUND_AMOUNT,l_INSTORE_REPLACEMENT,l_Packageid_Check,l_mallid_check,l_malllocation_check,l_OFAC_CHECK,l_PARTNER_ID,l_DOB_MANDATORY_FLAG,L_STANDINGAUTH_TRAN_FLAG,L_BYPASS_INITIAL_LOADCHK,
    L_ISSUBANK_ID,L_EVENT_NOTIFICATION,L_PARTNER_NAME,L_PIN_RESET_OPTION,L_PRODUCT_PORTFOLIO;
    EXIT WHEN ref_cur_prodcatg%NOTFOUND;
  begin
  INSERT INTO CMS_PROD_CATTYPE (
    CPC_INST_CODE,CPC_PROD_CODE,CPC_CARD_TYPE,CPC_CARDTYPE_DESC,
    CPC_INS_USER,CPC_INS_DATE,CPC_LUPD_USER,CPC_LUPD_DATE,
    CPC_VENDOR,CPC_STOCK,CPC_CARDTYPE_SNAME,CPC_PROD_PREFIX,CPC_RULEGROUP_CODE,
    CPC_PROFILE_CODE,CPC_PROD_ID,CPC_PACKAGE_ID,CPC_ACHTXN_FLG,CPC_ACHTXN_CNT,
    CPC_ACHTXN_AMT,CPC_ACHTXN_DEPOSIT,CPC_SEC_CODE,CPC_MIN_AGE_KYC,
    CPC_PASSIVE_TIME,CPC_ACHTXN_DAYCNT,CPC_ACHTXN_DAYMAXAMT,CPC_ACHTXN_WEEKCNT,
    CPC_ACHTXN_WEEKMAXAMT,CPC_ACHTXN_MONCNT,CPC_ACHTXN_MONMAXAMT,CPC_ACHTXN_MAXTRANAMT,
    CPC_ACHTXN_MINTRANAMT,CPC_STARTER_CARD,CPC_STARTER_MINLOAD,CPC_STARTER_MAXLOAD,
    CPC_STARTERGPR_CRDTYPE,CPC_STARTERGPR_ISSUE,CPC_ACCT_PROD_PREFIX,CPC_SERL_FLAG,
    CPC_DEL_MET,CPC_ACHMIN_INITIAL_LOAD,CPC_URL,CPC_PIN_APPLICABLE,
    CPC_DFLTPIN_FLAG,CPC_LOCCHECK_FLAG,CPC_SCORECARD_ID,CPC_ACH_LOADAMNT_CHECK,
    CPC_CRDEXP_PENDING,CPC_REPL_PERIOD,CPC_INVCHECK_FLAG,cpc_card_id,CPC_STARTERCARD_DISPNAME,
    CPC_STARTER_REPLACEMENT,CPC_REPLACEMENT_CATTYPE,CPC_TOKEN_ELIGIBILITY,CPC_TOKEN_PROVISION_RETRY_MAX,CPC_TOKEN_RETAIN_PERIOD,CPC_TOKEN_CUST_UPD_DURATION,CPC_DEFAULT_PIN_OPTION,cpc_exp_date_exemption,cpc_logo_id,CPC_REDEMPTION_DELAY_FLAG,CPC_CVVPLUS_ELIGIBILITY,CPC_CVVPlus_Short_Name,CPC_SWEEP_FLAG,CPC_ADDL_SWEEP_PERIOD,
    CPC_B2B_FLAG,CPC_B2BCARD_STAT,CPC_B2B_ACTIVATION_CODE,CPC_B2B_LMTPRFL,CPC_B2BFLNAME_FLAG,CPC_INACTIVETOKEN_RETAINPERIOD,CPC_KYC_FLAG,
    CPC_CVV2_VERIFICATION_FLAG,CPC_EXPIRY_DATE_CHECK_FLAG,CPC_ACCT_BALANCE_CHECK_FLAG,CPC_REPLACEMENT_PROVISION_FLAG,CPC_ACCT_BAL_CHECK_TYPE,CPC_ACCT_BAL_CHECK_VALUE,CPC_ISSU_PRODCONFIG_ID,CPC_CONSUMED_FLAG,CPC_CONSUMED_CARD_STAT,CPC_RENEW_REPLACE_OPTION,CPC_RENEW_REPLACE_PRODCODE,CPC_RENEW_REPLACE_CARDTYPE,
    CPC_USER_IDENTIFY_TYPE,CPC_RELOADABLE_FLAG,CPC_PROD_SUFFIX,CPC_START_CARD_NO,CPC_END_CARD_NO,CPC_CCF_FORMAT_VERSION,CPC_DCMS_ID,CPC_PRODUCT_UPC,CPC_PACKING_UPC,CPC_PROD_DENOM,CPC_PDENOM_MIN,CPC_PDENOM_MAX,CPC_PDENOM_FIX,CPC_ISSU_BANK ,
   CPC_ICA ,CPC_ISSU_BANK_ADDR,CPC_CARDPROD_ACCEPT,CPC_STATE_RESTRICT,CPC_PIF_SIA_CASE,CPC_DISABLE_REPL_FLAG,CPC_DISABLE_REPL_EXPRYDAYS,
   CPC_DISABLE_REPL_MINBAL,CPC_DISABLE_REPL_MESSAGE,CPC_PAN_INVENTORY_FLAG,CPC_ACCTUNLOCK_DURATION,CPC_WRONG_LOGONCOUNT,CPC_ACHBLCKEXPRY_PERIOD,
   CPC_RENEWAL_PINMIGRATION,CPC_FEDERALCHECK_FLAG,CPC_TANDC_VERSION,CPC_CLAWBACK_DESC,CPC_WEBAUTHMAPPING_ID,
   CPC_IVRAUTHMAPPING_ID,CPC_EMAIL_ID,CPC_FROMEMAIL_ID,CPC_APP_NAME,CPC_APPNTY_TYPE,CPC_KYCVERIFY_FLAG,CPC_NETWORKACQID_FLAG,CPC_SHORT_CODE,CPC_CIP_INTVL,CPC_DUP_SSNCHK,CPC_PINCHANGE_FLAG,CPC_OLSRESP_FLAG,CPC_EMV_FLAG,CPC_INSTITUTION_ID,CPC_TRANSIT_NUMBER,CPC_RANDOM_PIN
   ,CPC_POA_PROD,CPC_ONUS_AUTH_EXPIRY,CPC_FROM_DATE,CPC_ROUT_NUM
   ,Cpc_Ols_Expiry_Flag,Cpc_Statement_Footer,Cpc_Dup_Timeperiod,Cpc_Dup_Timeunt,Cpc_Gprflag_Achtxn,Cpc_Ccf_Serial_Flag,Cpc_Product_Id,Cpc_Program_Id,Cpc_Proxy_Length,Cpc_Check_Digit_Req,Cpc_Programid_Req,Cpc_Def_Cond_Appr,Cpc_Customer_Care_Num,Cpc_Upgrade_Eligible_Flag,Cpc_Ccf_3digcscreq,Cpc_Default_Partial_Indr,Cpc_Serialno_Filepath,Cpc_Retail_Activation,Cpc_Addr_Verification_Check,Cpc_Recurring_Tran_Flag,Cpc_International_Check,
   Cpc_Emv_Fallback,Cpc_Fund_Mcc,Cpc_Settl_Mcc,Cpc_Badcredit_Flag,CPC_BADCREDIT_TRANSGRPID,cpc_encrypt_enable,CPC_ALERT_CARD_STAT,CPC_ALERT_CARD_AMOUNT,CPC_ALERT_CARD_DURATION,CPC_SRC_APP,CPC_SRC_APP_FLAG,CPC_ADDR_VERIFICATION_RESPONSE,CPC_VALINS_ACT_FLAG,CPC_DEACTIVATION_CLOSED,CPC_DOUBLEOPTINNTY_TYPE,CPC_PRODUCT_FUNDING,CPC_FUND_AMOUNT,CPC_INSTORE_REPLACEMENT,cpc_Packageid_Check,CPC_MALLID_CHECK,CPC_MALLLOCATION_CHECK,cpc_OFAC_CHECK,CPC_PARTNER_ID,CPC_DOB_MANDATORY,CPC_STNGAUTH_FLAG,CPC_BYPASS_LOADCHECK,
   CPC_ISSUBANK_ID,CPC_EVENT_NOTIFICATION,CPC_PARTNER_NAME,CPC_PIN_RESET_OPTION,CPC_PRODUCT_PORTFOLIO
    )--added for b2b and mastercard)
    VALUES(
    p_instcode_in,p_toprod_code_in,l_card_type,l_cardtype_desc,
    p_ins_user_in,sysdate,p_ins_user_in,sysdate,
    l_vendor,l_stock,l_cardtype_sname,l_prod_prefix,l_rulegroup_code,
    l_profile_code,l_prod_id,l_package_id,l_achtxn_flg,l_achtxn_cnt,
    l_achtxn_amt,l_achtxn_deposit,l_sec_code,l_min_agekyc,
    l_passive_time,l_achtxn_daycnt,l_achtxn_dayamt,l_achtxn_weekcnt,
    l_achtxn_weekmaxamt,l_achtxn_moncnt,l_achtxn_monmaxamt,l_achtxn_maxtranamt,
    l_achtxn_mintranamt,l_starter_card,l_starter_minload,l_starter_maxload,
    l_startergpr_cardtype,l_strgpr_issue,l_acctprod_prefix,l_serl_flag,
    l_del_met,l_achmin_iniload,l_url,l_pin_app,
    l_dfltpin_flag,l_locchk_flag,l_scorecard_id,l_ach_loadamtchk,
    l_crdexp_pend,l_repl_period,l_invchk_flag,
    (SELECT B.CPC_CARD_ID FROM CMS_PROD_CARDPACK B WHERE B.CPC_CARD_DETAILS=l_package_id AND B.CPC_PROD_CODE=p_toprod_code_in AND ROWNUM=1),
    l_strcrd_dispname,
    l_strrepl_option,l_repl_prodcatg,l_token_eligible,l_prov_retrymax,l_token_retainperiod,l_TOKEN_CUSTUPDDURATION,l_default_pin_selected,l_exp_date_exemption,l_logo_id,l_redemption_delay,l_CVVPLUS_ELIGIBILITY,l_CVVPlus_Short_Name,l_SWEEP_FLAG,l_SWEEP_PERIOD
    ,l_b2b_Flag,l_b2b_cardstat,l_b2b_actCode,l_b2b_lmtprof,l_b2b_regmatch,l_InactivetoknretainPer,l_kyc_flag,
    L_CVV2_VERIFICATION_FLAG,L_EXPIRY_DATE_CHECK_FLAG,L_ACCT_BALANCE_CHECK_FLAG,L_REPLACEMENT_PROVISION_FLAG,L_ACCT_BALANCE_CHECK_TYPE,L_ACCT_BALANCE_CHECK_VALUE,
    L_ISSU_PRODCONFIG_ID,L_CONSUMED_FLAG,L_CONSUMED_CARD_STAT,L_RENEW_REPLACE_OPTION,L_RENEW_REPLACE_PRODCODE,L_RENEW_REPLACE_CARDTYPE,L_REGISTRATION_TYPE,L_RELOADABLE_FLAG,L_PROD_SUFFIX,L_START_CARD_NO,L_END_CARD_NO,L_CCF_FORMAT_VERSION
    ,l_DCMS_ID,l_PRODUCT_UPC,l_PACKING_UPC,l_PROD_DENOM, L_PDENOM_MIN,L_PDENOM_MAX,L_PDENOM_FIX,L_ISSU_BANK,L_ICA,L_ISSU_BANK_ADDR,L_CARDPROD_ACCEPT,L_STATE_RESTRICT,L_PIF_SIA_CASE,L_DISABLE_REPL_FLAG,
    l_DISABLE_REPl_EXPRYDAYS,l_DISABLE_REPl_MINBAL,l_DISABLE_REPL_MESSAGE,l_PAN_INVENTORY_FLAG,l_ACCTUNLOCK_DURATION,l_WRONG_LOGONCOUNT,l_ACHBLCKEXPRY_PERIOD,
    l_RENEWAl_PINMIGRATION,l_FEDERALCHECK_FLAG,l_TANDC_VERSION,l_CLAWBACK_DESC,l_WEBAUTHMAPPING_ID,l_IVRAUTHMAPPING_ID,l_EMAIl_ID,l_FROMEMAIl_ID,
    L_APP_NAME,L_APPNTY_TYPE,L_KYCVERIFY_FLAG,L_NETWORKACQID_FLAG,L_SHORT_CODE,L_CIP_INTVL,L_DUP_SSNCHK,L_PINCHANGE_FLAG,L_OLSRESP_FLAG,L_EMV_FLAG,
    L_Institution_Id,L_Transit_Number,L_Random_Pin ,L_Poa_Prod,L_Onus_Auth_Expiry,L_From_Date,L_Rout_Num,L_Ols_Expiry_Flag,L_Statement_Footer,
    L_Dup_Timeperiod,L_Dup_Timeunt,L_Gprflag_Achtxn,L_Ccf_Serial_Flag,Lpad(Seq_Product_Id.Nextval,5,0),L_Prog_Id,L_Proxy_Len,L_Ischcek_Req,L_Isprg_Id_Req,L_Def_Cond_Appr_Flag,L_Customer_Care_Num,L_Upgrade_Eligible_Flag,L_Ccf_3digcscreq,L_Default_Partial_Indr,L_Serialno_Filepath,L_Retail_Activation,L_Avs_Required,L_Recurring_Tran_Flag,L_International_Tran,
    L_Emv_Fallback,L_Fund_Mcc,L_Settl_Mcc,L_Badcrd_Flag,l_badcr_transgrp,l_encrypt_enable,l_alert_card_stat,l_alert_card_amnt,l_alert_card_days,l_src_app,l_src_app_flag,L_ADDR_VERIF_RESP,l_VALINS_ACT_FLAG,l_DEACTIVATION_CLOSED,l_DOUBLEOPTINNTY_TYPE,l_PRODUCT_FUNDING,l_FUND_AMOUNT,l_INSTORE_REPLACEMENT,l_Packageid_Check,l_mallid_check,l_malllocation_check,l_OFAC_CHECK,l_PARTNER_ID,l_DOB_MANDATORY_FLAG,L_STANDINGAUTH_TRAN_FLAG,L_BYPASS_INITIAL_LOADCHK,
    L_ISSUBANK_ID,L_EVENT_NOTIFICATION,L_PARTNER_NAME,L_PIN_RESET_OPTION,L_PRODUCT_PORTFOLIO);
    exception
        when others then
             P_ERRMSG_OUT :=
                     'ERROR WHILE INSERTING INTO CMS_PROD_CATTYPE1 :'
   || SUBSTR (SQLERRM, 1, 300);
               RAISE EXP_REJECT_RECORD;
    end;

     BEGIN
     l_GET_SEQ_QUERY := 'SELECT COUNT(*)  FROM CMS_PROGRAM_ID_CNT CPI WHERE CPI.CPI_PROGRAM_ID=' ||
                   CHR(39) || l_prog_id || CHR(39) || ' AND CPI_INST_CODE=' ||
                   p_instcode_in;
     EXECUTE IMMEDIATE l_GET_SEQ_QUERY
       INTO l_SEQ_NO;
     IF l_SEQ_NO = 0 THEN
       INSERT INTO CMS_PROGRAM_ID_CNT
        (CPI_INST_CODE,
         CPI_PROGRAM_ID,
         CPI_SEQUENCE_NO,
         CPI_INS_USER,
         CPI_INS_DATE)
       VALUES
        (p_instcode_in, l_prog_id, 0, '', SYSDATE);
     END IF;
    EXCEPTION
     WHEN OTHERS THEN
       P_ERRMSG_OUT := 'Error when inserting into  CMS_PROGRAM_ID_CNT ' ||SQLERRM;
       RAISE EXP_REJECT_RECORD;
    END;

    begin
          for i in 1..12 loop
                insert into vms_expiry_mast(
                                  Vem_PROD_CODE,
                                  Vem_PROD_CATTYPE,
                                  Vem_MONTH_ID,
                                  Vem_MONTH_VALUE,
                                  Vem_INS_USER,
                                  vem_ins_date)
                      select p_toprod_code_in,l_card_type,Vem_MONTH_ID,
                             vem_month_value,p_ins_user_in,sysdate
                             from vms_expiry_mast
                             where vem_month_id=lpad(i,2,'0')
                             and vem_prod_code='0' and vem_prod_cattype=0;
          end loop;
     exception
        when others then
           p_errmsg_out :=
                     'ERROR WHILE INSERTING INTO vms_expiry_mast :'
                  || SUBSTR (SQLERRM, 1, 300);
               RAISE EXP_REJECT_RECORD;
     end;


    IF l_ctrl_no < l_card_type then
    l_ctrl_no := l_card_type;
    END IF;

    begin
       INSERT INTO CMS_PROD_CCC(CPC_INST_CODE, CPC_CUST_CATG , CPC_CARD_TYPE ,
                          CPC_PROD_CODE,CPC_INS_USER , CPC_LUPD_USER)
                      VALUES(p_instcode_in, 1, l_card_type,p_toprod_code_in,
                           p_ins_user_in,p_ins_user_in);
    exception
        when others then
             p_errmsg_out :=
                     'ERROR WHILE INSERTING INTO CMS_PROD_CCC :'
                  || SUBSTR (SQLERRM, 1, 300);
               RAISE EXP_REJECT_RECORD;
    end;

  END LOOP;

   EXCEPTION
            when EXP_REJECT_RECORD then
                raise;
            WHEN OTHERS
            THEN
               p_errmsg_out :=
                     'ERROR WHILE INSERTING INTO CMS_PROD_CATTYPE2 :'
                  || SUBSTR (SQLERRM, 1, 300);
               RAISE EXP_REJECT_RECORD;

 END;

 BEGIN

 INSERT INTO CMS_CTRL_TABLE
                        (CCT_CTRL_CODE,
                        CCT_CTRL_KEY,
                        CCT_CTRL_NUMB,
                        CCT_CTRL_DESC,
                        CCT_INS_USER,
                        CCT_LUPD_USER)
                        VALUES
                        (p_instcode_in || LTRIM(RTRIM(p_toprod_code_in)),
                        'PROD CATTYPE',
                        l_ctrl_no+1,
                        'Latest card type for Inst ' || p_instcode_in || ' and interchange ' ||
                        p_toprod_code_in || '.',
                        p_ins_user_in,
                        p_ins_user_in);
        EXCEPTION
        WHEN OTHERS THEN
            p_errmsg_out:='Error while inserting into CMS_CTRL_TABLE '|| SUBSTR (SQLERRM, 1, 300);
            RAISE EXP_REJECT_RECORD;

 END;


 BEGIN

  OPEN ref_cur_prodcatg_seccode FOR
  'SELECT VPC_SEC_CODE,VPC_CARD_TYPE,VPC_TRAN_CODE
   FROM VMS_PROD_CATSEC_STAG
   WHERE VPC_PROD_CODE='''||p_prod_code_in||''' AND VPC_CARD_TYPE IN('||p_prod_catg_in||')';
  LOOP
  FETCH ref_cur_prodcatg_seccode INTO l_sec_code1,l_card_type,l_tran_code;
  EXIT WHEN ref_cur_prodcatg_seccode%NOTFOUND;

  INSERT INTO CMS_PROD_CATSEC (
                              CPC_INST_CODE,CPC_PROD_CODE,CPC_SEC_CODE,
                              CPC_INS_USER,CPC_INS_DATE,CPC_LUPD_USER,CPC_LUPD_DATE,
                              CPC_CARD_TYPE,CPC_TRAN_CODE)
                              VALUES(
                              p_instcode_in,p_toprod_code_in,l_sec_code1,
                              p_ins_user_in,sysdate,p_ins_user_in,sysdate,
                              l_card_type,l_tran_code);


  END LOOP;

   EXCEPTION
            WHEN OTHERS
            THEN
               p_errmsg_out :=
                     'ERROR WHILE INSERTING INTO CMS_PROD_CATSEC :'
                  || SUBSTR (SQLERRM, 1, 300);
               RAISE EXP_REJECT_RECORD;

 END;

  BEGIN
    open ref_cur_prodcatg_threshold for
    'SELECT VPT_PROD_THRESHOLD,vpt_card_type  FROM VMS_PRODCAT_THRESHOLD_STAG WHERE
    VPT_PROD_CODE='''||p_prod_code_in||''' AND VPT_CARD_TYPE IN ('||p_prod_catg_in||')';
    LOOP
    FETCH ref_cur_prodcatg_threshold INTO L_PRODCAT_THRESHOLD1,l_card_type;
     exit when ref_cur_prodcatg_threshold%notfound;
      begin

        INSERT INTO VMS_PRODCAT_THRESHOLD(VPT_INST_CODE,
                                        VPT_PROD_CODE,
                                        VPT_CARD_TYPE,
                                        VPT_PROD_THRESHOLD,
                                        VPT_INS_USER,
                                        VPT_INS_DATE,
                                        VPT_LUPD_USER,
                                        VPT_LUPD_DATE)
                                  VALUES(p_instcode_in,
                                         p_toprod_code_in,
                                         l_card_type,
                                         L_PRODCAT_THRESHOLD1,
                                         p_ins_user_in,
                                         SYSDATE,
                                         p_ins_user_in,
                                        SYSDATE);

          EXCEPTION
            WHEN OTHERS
            THEN
               P_ERRMSG_OUT :=
                'ERROR WHILE SELECTING DETAILS FROM  VMS_PRODCAT_THRESHOLD:'||p_prod_catg_in
                  || SUBSTR (SQLERRM, 1, 300);
               RAISE EXP_REJECT_RECORD;

			   END;
        end loop;

    EXCEPTION
            WHEN OTHERS
            THEN
               P_ERRMSG_OUT :=
                     'ERROR WHILE INSERTING INTO VMS_PRODCAT_THRESHOLD:'||L_PRODCAT_THRESHOLD1||'l_card_type:'||l_card_type
                  || SUBSTR (SQLERRM, 1, 300);
               RAISE EXP_REJECT_RECORD;

    END;

	  BEGIN
    OPEN REF_CUR_PRODCAT_NETMAP FOR 'SELECT VPN_NETWORK_ID,vpn_card_type
        FROM VMS_PRODCAT_NETWORKID_MAP_STAG WHERE VPN_PROD_CODE='''||P_PROD_CODE_IN||'''AND VPN_CARD_TYPE IN ('||p_prod_catg_in||')';
    LOOP
      FETCH REF_CUR_PRODCAT_NETMAP INTO L_NETWORK_ID,L_CARD_TYPE;
       EXIT WHEN REF_CUR_PRODCAT_NETMAP%NOTFOUND;
       begin
            INSERT INTO VMS_PRODCAT_NETWORKID_MAPPING(
                    VPN_INST_CODE,
                    VPN_PROD_CODE,
                    VPN_CARD_TYPE,
                    VPN_NETWORK_ID,
                    VPN_INS_USER,
                    VPN_INS_DATE,
                    VPN_LUPD_USER,
                    VPN_LUPD_DATE)
                    VALUES(
                    p_instcode_in,
                    p_toprod_code_in,
                    l_card_type,
                    l_network_id,
                    p_ins_user_in,
                    SYSDATE,
                    p_ins_user_in,
                    SYSDATE);

           EXCEPTION
            WHEN OTHERS
            THEN
               P_ERRMSG_OUT :=
                'ERROR WHILE INSERTING DETAILS FROM  VMS_PRODCAT_NETWORKID_MAPPING:'||p_prod_catg_in
                  || SUBSTR (SQLERRM, 1, 300);
               RAISE EXP_REJECT_RECORD;

			   END;
        end loop;

            EXCEPTION
            WHEN OTHERS
            THEN
               p_errmsg_out :=
                     'ERROR WHILE INSERTING INTO VMS_PRODCAT_NETWORKID_MAPPING:'
                  || SUBSTR (SQLERRM, 1, 300);
               RAISE EXP_REJECT_RECORD;

 END;

 BEGIN
        open ref_cur_scorecd_prodcat_map for 'SELECT VSP_SCORECARD_ID,
            VSP_DELIVERY_CHANNEL,VSP_CIPCARD_STAT,VSP_AVQ_FLAG,vsp_card_type
            FROM VMS_SCORECARD_PRODCAT_MAP_STAG WHERE
            VSP_PROD_CODE='''||P_PROD_CODE_IN||'''AND VSP_CARD_TYPE IN ('||p_prod_catg_in||')';
        loop
        fetch ref_cur_scorecd_prodcat_map into l_scorecard_id,l_delivery_channel,
                                          L_CIPCARD_STAT,L_AVQ_FLAG,L_CARD_TYPE;
        EXIT WHEN REF_CUR_SCORECD_PRODCAT_MAP%NOTFOUND;
        begin
            INSERT INTO VMS_SCORECARD_PRODCAT_MAPPING(
                    VSP_INST_CODE,
                    VSP_SCORECARD_ID,
                    VSP_PROD_CODE,
                    VSP_CARD_TYPE,
                    VSP_DELIVERY_CHANNEL,
                    VSP_CIPCARD_STAT,
                    VSP_AVQ_FLAG,
                    VSP_INS_USER,
                    VSP_INS_DATE,
                    VSP_LUPD_USER,
                    VSP_LUPD_DATE)
                    VALUES(
                    p_instcode_in,
                    l_scorecard_id,
                    p_toprod_code_in,
                    l_card_type,
                    l_delivery_channel,
                    l_cipcard_stat,
                    l_avq_flag,
                    p_ins_user_in,
                    SYSDATE,
                    p_ins_user_in,
                    SYSDATE);
                      EXCEPTION
            WHEN OTHERS
            THEN
               P_ERRMSG_OUT :=
                'ERROR WHILE INSERTING DETAILS FROM  VMS_SCORECARD_PRODCAT_MAPPING:'||p_prod_catg_in
                  || SUBSTR (SQLERRM, 1, 300);
               RAISE EXP_REJECT_RECORD;

			   END;

            END LOOP;
            EXCEPTION
            WHEN OTHERS
            THEN
               p_errmsg_out :=
                     'ERROR WHILE INSERTING INTO VMS_SCORECARD_PRODCAT_MAPPING:'
                  || SUBSTR (SQLERRM, 1, 300);
               RAISE EXP_REJECT_RECORD;

 END;


  Begin
          open ref_cur_prodcat_deno for 'SELECT VPD_PDEN_VAL,VPD_DENO_STATUS,VPD_CARD_TYPE
                 FROM VMS_PRODCAT_DENO_MAST_STAG
                  WHERE
            VPD_PROD_CODE='''||P_PROD_CODE_IN||'''AND VPD_CARD_TYPE IN ('||p_prod_catg_in||')';
          LOOP
          fetch ref_cur_prodcat_deno into l_pden_val,l_deno_status,l_card_type;
           EXIT WHEN REF_CUR_PRODCAT_DENO%NOTFOUND;
           begin
            Insert Into VMS_PRODCAT_DENO_MAST(
                    Vpd_Inst_Code,
                    Vpd_Prod_Code,
                    Vpd_Card_Type,
                    Vpd_Pden_Val,
                    Vpd_Deno_Status,
                    Vpd_Ins_User,
                    Vpd_Ins_Date,
                    Vpd_Lupd_User,
                    Vpd_Lupd_Date)
                    Values(
                    P_Instcode_In,
                    p_toprod_code_in,
                    l_card_type,
                    l_pden_val,
                    l_deno_status,
                    P_Ins_User_In,
                    Sysdate,
                    P_Ins_User_In,
                    Sysdate);
                      EXCEPTION
            WHEN OTHERS
            THEN
               P_ERRMSG_OUT :=
                'ERROR WHILE INSERTING DETAILS FROM  VMS_PRODCAT_DENO_MAST:'||p_prod_catg_in
                  || SUBSTR (SQLERRM, 1, 300);
               RAISE EXP_REJECT_RECORD;

			   END;
            END LOOP;
      EXCEPTION
            WHEN OTHERS
            THEN
               p_errmsg_out :=
                     'ERROR WHILE INSERTING INTO VMS_PRODCAT_DENO_MAST:'
                  || SUBSTR (SQLERRM, 1, 300);
               RAISE EXP_REJECT_RECORD;

 end;
 BEGIN

  OPEN REF_CUR_PRODCATG_CARDID FOR
  'SELECT VPC_CATG_CODE,VPC_CARD_ID,VPC_ISSUER_GUID,VPC_ART_GUID,VPC_TC_GUID
   FROM VMS_PRODCAT_CARDPACK_STAG
   WHERE VPC_PROD_CODE='''||p_prod_code_in||''' AND VPC_CATG_CODE IN('||p_prod_catg_in||')';
  LOOP
  FETCH REF_CUR_PRODCATG_CARDID INTO l_card_type,l_card_id,l_issuer_guid,l_art_guid,l_tc_guid;
  EXIT WHEN REF_CUR_PRODCATG_CARDID%NOTFOUND;

  INSERT INTO CMS_PRODCAT_CARDPACK (
                              CPC_INST_CODE,
                              CPC_PROD_CODE,
                              CPC_CATG_CODE,
                              CPC_CARD_ID,
                              CPC_ISSUER_GUID,
                              CPC_ART_GUID,
                              CPC_TC_GUID)
                              VALUES(
                              p_instcode_in,
                              p_toprod_code_in,
                              l_card_type,
                              (SELECT B.CPC_CARD_ID FROM CMS_PROD_CARDPACK B WHERE B.CPC_CARD_DETAILS=
                              (SELECT VPC_CARD_DETAILS FROM vms_prod_cardpack_stag WHERE VPC_CARD_ID=l_card_id AND VPC_PROD_CODE=p_prod_code_in)
                              AND B.CPC_PROD_CODE=p_toprod_code_in AND ROWNUM=1),
                              l_issuer_guid,
                              l_art_guid,
                              l_tc_guid);


  END LOOP;

   EXCEPTION
            WHEN OTHERS
            THEN
               p_errmsg_out :=
                     'ERROR WHILE INSERTING INTO CMS_PRODCAT_CARDPACK :'
                  || SUBSTR (SQLERRM, 1, 300);
               RAISE EXP_REJECT_RECORD;

 END;

 EXCEPTION
  WHEN EXP_REJECT_RECORD THEN
  ROLLBACK;-- TO l_savepoint;
  WHEN OTHERS THEN
  ROLLBACK;-- TO l_savepoint;
  p_errmsg_out := 'Exception while copying PRODCATG_PARAMETER_MAST:' ||p_errmsg_out || SUBSTR(SQLERRM, 1, 200);

END;

--End product categpry temp to mast

--start savings account parameter temp to mast

PROCEDURE  PRODUCT_SAVINGSPARAM_MAST (
   p_instcode_in            IN       NUMBER,
   p_ins_user_in            IN       NUMBER,
   p_prod_code_in           IN       VARCHAR2,
   p_toprod_code_in         IN       VARCHAR2,
   p_card_type_in           IN       VARCHAR2,
   p_errmsg_out             OUT      VARCHAR2
)
IS

/**********************************************************************************************


  * Created by                  : MageshKumar S.
  * Created Date                : 07-MAR-16
  * Created For                 : HOSTCC-57
  * Created reason              : SAVINGS ACCOUNT PARAMETERE TEMP TO MAST COPY PROGRAM
  * Reviewer                    : SARAVANAKUMAR/SPANKAJ
  * Build Number                : VMSGPRHOSTCSD4.0_B0001

**************************************************************************************************/
--l_savepoint           NUMBER                              DEFAULT 1;
L_PARAM_KEY       VMS_DFG_PARAM_STAG.VDP_PARAM_KEY%TYPE;
L_PARAM_VALUE      VMS_DFG_PARAM_STAG.VDP_PARAM_VALUE%TYPE;
l_mandatory_flag   VMS_DFG_PARAM_STAG.VDP_MANDARORY_FLAG%TYPE;
l_card_type            VMS_DFG_PARAM_STAG.VDP_CARD_TYPE%type;

EXP_REJECT_RECORD EXCEPTION;
REF_PROD_SAVINGSACCT_INFO  SYS_REFCURSOR;
BEGIN

 p_errmsg_out  := 'OK';
 SAVEPOINT l_savepoint;

 BEGIN

  OPEN REF_PROD_SAVINGSACCT_INFO FOR
          ' SELECT    VDP_PARAM_KEY,VDP_PARAM_VALUE,VDP_MANDARORY_FLAG,VDP_CARD_TYPE
            FROM VMS_DFG_PARAM_STAG
            WHERE VDP_PROD_CODE='''||p_prod_code_in||''' AND VDP_CARD_TYPE IN('||p_card_type_in||')';

  LOOP
  FETCH REF_PROD_SAVINGSACCT_INFO INTO l_param_key,l_param_value,l_mandatory_flag,l_card_type;
  EXIT WHEN REF_PROD_SAVINGSACCT_INFO%NOTFOUND;

 INSERT INTO CMS_DFG_PARAM
   (CDP_INST_CODE,
    CDP_PARAM_KEY,
    CDP_PARAM_VALUE,
    CDP_INST_USER,
    CDP_INS_DATE,
    CDP_LUPD_USER,
    CDP_LUPD_DATE,
    CDP_MANDARORY_FLAG,
    CDP_PROD_CODE,
    CDP_CARD_TYPE)
    VALUES(
    p_instcode_in,
    l_param_key,
    l_param_value,
    p_ins_user_in,
    sysdate,
    p_ins_user_in,
    sysdate,
    l_mandatory_flag,
    p_toprod_code_in,
    l_card_type);

  END LOOP;

 EXCEPTION
            WHEN OTHERS
            THEN
               p_errmsg_out :=
                     'ERROR WHILE INSERTING INTO CMS_DFG_PARAM:'
                  || SUBSTR (SQLERRM, 1, 300);
               RAISE EXP_REJECT_RECORD;

 END;


--CURSOR PROD_SAVINGSACCT_INFO(l_prod_code_in IN VARCHAR,l_card_type_in IN VARCHAR)
--IS
--SELECT
--VDP_PARAM_KEY,VDP_PARAM_VALUE,VDP_MANDARORY_FLAG,VDP_CARD_TYPE
--FROM VMS_DFG_PARAM_STAG
--WHERE VDP_PROD_CODE=l_prod_code_in AND VDP_CARD_TYPE IN ('|| l_card_type_in ||');
--
--
--BEGIN
--
-- p_errmsg_out  := 'OK';
---- SAVEPOINT l_savepoint;
--
-- BEGIN
--
--  FOR l_row_indx IN PROD_SAVINGSACCT_INFO(p_prod_code_in,p_card_type_in)
--  LOOP
--  INSERT INTO CMS_DFG_PARAM
--   (CDP_INST_CODE,
--    CDP_PARAM_KEY,
--    CDP_PARAM_VALUE,
--    CDP_INST_USER,
--    CDP_INS_DATE,
--    CDP_LUPD_USER,
--    CDP_LUPD_DATE,
--    CDP_MANDARORY_FLAG,
--    CDP_PROD_CODE,
--    CDP_CARD_TYPE)
--    VALUES(
--    p_instcode_in,
--    l_row_indx.VDP_PARAM_KEY,
--    l_row_indx.VDP_PARAM_VALUE,
--    p_ins_user_in,
--    sysdate,
--    p_ins_user_in,
--    sysdate,
--    l_row_indx.VDP_MANDARORY_FLAG,
--    p_toprod_code_in,
--    p_card_type_in);
--
--  END LOOP;
--
--   EXCEPTION
--            WHEN OTHERS
--            THEN
--               p_errmsg_out :=
--                     'ERROR WHILE INSERTING INTO CMS_DFG_PARAM:'
--                  || SUBSTR (SQLERRM, 1, 300);
--               RAISE EXP_REJECT_RECORD;
--
-- END;

  EXCEPTION
  WHEN EXP_REJECT_RECORD THEN
  ROLLBACK;-- TO l_savepoint;
  WHEN OTHERS THEN
  ROLLBACK;-- TO l_savepoint;
  p_errmsg_out := 'Exception while copying PRODUCT_SAVINGSPARAM_MAST:' ||p_errmsg_out || SUBSTR(SQLERRM, 1, 200);


END;


--end savings account parameter temp to mast

--start emboss file format temp to mast


PROCEDURE  PRODUCT_EMBOSSFORMAT_MAST (
   p_instcode_in            IN       NUMBER,
   p_ins_user_in            IN       NUMBER,
   p_prod_code_in           IN       VARCHAR2,
   p_toprod_code_in         IN       VARCHAR2,
   p_toprod_profilecode_in  IN       VARCHAR2,
   p_card_type_in           IN       VARCHAR2,
   p_errmsg_out             OUT      VARCHAR2
)
IS

/**********************************************************************************************


  * Created by                  : MageshKumar S.
  * Created Date                : 07-MAR-16
  * Created For                 : HOSTCC-57
  * Created reason              : EMBOSS FILE FORMAT TEMP TO MAST COPY PROGRAM
  * Reviewer                    : SARAVANAKUMAR/SPANKAJ
  * Build Number                : VMSGPRHOSTCSD4.0_B0001

**************************************************************************************************/

EXP_REJECT_RECORD EXCEPTION;
l_profile_code            cms_profile_mast.cpm_profile_code%TYPE;
l_emb_line1               CMS_EMBOSS_FILE_FORMAT.CEFF_EMBOSS_LINE1%TYPE;
l_emb_line2               CMS_EMBOSS_FILE_FORMAT.CEFF_EMBOSS_LINE2%TYPE;
l_emb_line3               CMS_EMBOSS_FILE_FORMAT.CEFF_EMBOSS_LINE3%TYPE;
l_emb_line4               CMS_EMBOSS_FILE_FORMAT.CEFF_EMBOSS_LINE4%TYPE;
l_track1_data             CMS_EMBOSS_FILE_FORMAT.CEFF_TRACK1_DATA%TYPE;
l_track2_data             CMS_EMBOSS_FILE_FORMAT.CEFF_TRACK2_DATA%TYPE;
l_indent_line             CMS_EMBOSS_FILE_FORMAT.CEFF_INDENT_LINE%TYPE;
l_del_flag                CMS_EMBOSS_FILE_FORMAT.CEFF_DEL_FLAG%TYPE;
l_ptrack2_data            CMS_EMBOSS_FILE_FORMAT.CEFF_PTRACK2_DATA%TYPE;
l_format_flag             CMS_EMBOSS_FILE_FORMAT.CEFF_FORMAT_FLAG%TYPE;
l_track2_pattern          CMS_EMBOSS_FILE_FORMAT.CEFF_TRACK2_PATTERN%TYPE;
l_track1_pattern          CMS_EMBOSS_FILE_FORMAT.CEFF_TRACK1_PATTERN%TYPE;
l_alttrack1_pattern       CMS_EMBOSS_FILE_FORMAT.CEFF_ALTTRACK1_PATTERN%TYPE;
l_alttrack1_data          CMS_EMBOSS_FILE_FORMAT.CEFF_ALTTRACK1_DATA%TYPE;
l_alttrack2_pattern       CMS_EMBOSS_FILE_FORMAT.CEFF_ALTTRACK2_PATTERN%TYPE;
l_alttrack2_data          CMS_EMBOSS_FILE_FORMAT.CEFF_ALTTRACK2_DATA%TYPE;
--l_toprofile_code          cms_profile_mast.cpm_profile_code%TYPE;
L_FOUND_FLAG  VARCHAR2(1) DEFAULT 'Y';
REF_CUR_PROFILE_TEMP_STAG SYS_REFCURSOR;
BEGIN

 p_errmsg_out  := 'OK';

 open REF_CUR_PROFILE_TEMP_STAG for 'SELECT
     VPM_PROFILE_CODE

     FROM VMS_PROFILE_MAST_STAG     WHERE VPM_PROFILE_CODE IN(SELECT VPC_PROFILE_CODE FROM VMS_PROD_CATTYPE_STAG WHERE VPC_PROD_CODE='''||p_prod_code_in||''' AND VPC_CARD_TYPE IN ('|| p_card_type_in ||'))';
    loop
        FETCH REF_CUR_PROFILE_TEMP_STAG INTO l_profile_code;
        exit when REF_CUR_PROFILE_TEMP_STAG%notfound;
-- BEGIN
--
--  SELECT  VPM_PROFILE_CODE
--    INTO l_profile_code
--    FROM VMS_PROFILE_MAST_STAG
--    WHERE VPM_PROFILE_CODE IN(SELECT VPC_PROFILE_CODE FROM VMS_PROD_CATTYPE_STAG WHERE VPC_PROD_CODE=p_prod_code_in AND VPC_CARD_TYPE IN ('|| p_card_type_in ||'));
--
--    EXCEPTION
--     WHEN NO_DATA_FOUND
--            THEN
--               p_errmsg_out :=
--                     'PROFILE DETAILS NOT FOUND FROM PROCESS PRODUCT_EMBOSSFORMAT_MAST:'|| p_prod_code_in;
--               RAISE EXP_REJECT_RECORD;
--          WHEN OTHERS
--         THEN
--            p_errmsg_out := 'ERROR WHILE SELECTING PRODUCT PROFILE DETAILS FROM PRODUCT_EMBOSSFORMAT_MAST:'|| SUBSTR (SQLERRM, 1, 200);
--            RAISE EXP_REJECT_RECORD;
--  END;

   BEGIN

  SELECT
        VEFF_EMBOSS_LINE1,VEFF_EMBOSS_LINE2,VEFF_EMBOSS_LINE3,
        VEFF_EMBOSS_LINE4,VEFF_TRACK1_DATA,VEFF_TRACK2_DATA,
        VEFF_INDENT_LINE,VEFF_DEL_FLAG,VEFF_PTRACK2_DATA,VEFF_FORMAT_FLAG,
        VEFF_TRACK2_PATTERN,VEFF_TRACK1_PATTERN,VEFF_ALTTRACK1_PATTERN,
        VEFF_ALTTRACK1_DATA,VEFF_ALTTRACK2_PATTERN,VEFF_ALTTRACK2_DATA
  INTO l_emb_line1,l_emb_line2,l_emb_line3,
       l_emb_line4,l_track1_data,l_track2_data,
       l_indent_line,l_del_flag,l_ptrack2_data,l_format_flag,
       l_track2_pattern,l_track1_pattern,l_alttrack1_pattern,
       l_alttrack1_data,l_alttrack2_pattern,l_alttrack2_data
    FROM VMS_EMBOSS_FILE_FORMAT_STAG
    WHERE VEFF_PROFILE_CODE=l_profile_code AND VEFF_FORMAT_FLAG='N';

    EXCEPTION
     WHEN NO_DATA_FOUND
            THEN
             /*  p_errmsg_out :=
                     'VMS_EMBOSS_FILE_FORMAT_STAG DETAILS NOT FOUND FOR PROFILE CODE: '|| l_profile_code;
               RAISE EXP_REJECT_RECORD;*/
               l_found_flag:='N';
          WHEN OTHERS
         THEN
            p_errmsg_out := 'ERROR WHILE SELECTING EMBOSS FILE FORMAT DETAILS:'|| SUBSTR (SQLERRM, 1, 200);
            RAISE EXP_REJECT_RECORD;
  END;


 IF l_found_flag = 'Y' THEN
 BEGIN

  INSERT INTO CMS_EMBOSS_FILE_FORMAT(
    CEFF_PROFILE_CODE,
    CEFF_EMBOSS_LINE1,
    CEFF_EMBOSS_LINE2,
    CEFF_EMBOSS_LINE3,
    CEFF_EMBOSS_LINE4,
    CEFF_TRACK1_DATA,
    CEFF_TRACK2_DATA,
    CEFF_INDENT_LINE,
    CEFF_INS_USER,
    CEFF_INS_DATE,
    CEFF_DEL_FLAG,
    CEF_LUPD_DATE,
    CEF_INST_CODE,
    CEF_LUPD_USER,
    CEFF_PTRACK2_DATA,
    CEFF_FORMAT_FLAG,
    CEFF_TRACK2_PATTERN,
    CEFF_TRACK1_PATTERN,
    CEFF_ALTTRACK1_PATTERN,
    CEFF_ALTTRACK1_DATA,
    CEFF_ALTTRACK2_PATTERN,
    CEFF_ALTTRACK2_DATA)
    VALUES(
    p_toprod_profilecode_in,
    l_emb_line1,
    l_emb_line2,
    l_emb_line3,
    l_emb_line4,
    l_track1_data,
    l_track2_data,
    l_indent_line,
    p_ins_user_in,
    sysdate,
    l_del_flag,
    sysdate,
    p_instcode_in,
    p_ins_user_in,
    l_ptrack2_data,
    l_format_flag,
    l_track2_pattern,
    l_track1_pattern,
    l_alttrack1_pattern,
    l_alttrack1_data,
    l_alttrack2_pattern,
    l_alttrack2_data);

   EXCEPTION
            WHEN OTHERS
            THEN
               p_errmsg_out :=
                     'ERROR WHILE INSERTING INTO CMS_EMBOSS_FILE_FORMAT :'
                  || SUBSTR (SQLERRM, 1, 300);
               RAISE EXP_REJECT_RECORD;

 END;
 END IF;
 end loop;
 EXCEPTION
  WHEN EXP_REJECT_RECORD THEN
  ROLLBACK;
  WHEN OTHERS THEN
 ROLLBACK;
  p_errmsg_out := 'Exception while copying PRODUCT_EMBOSSFORMAT_MAST:' ||p_errmsg_out || SUBSTR(SQLERRM, 1, 200);


END;


--end emboss file format temp to mast


--start ACH file process temp to mast

PROCEDURE  PRODUCT_ACHCONFIG_MAST (
   p_instcode_in            IN       NUMBER,
   p_ins_user_in            IN       NUMBER,
   p_prod_code_in           IN       VARCHAR2,
   p_toprod_code_in          IN       VARCHAR2,
   p_errmsg_out             OUT      VARCHAR2
)
IS

/**********************************************************************************************


  * Created by                  : MageshKumar S.
  * Created Date                : 07-MAR-16
  * Created For                 : HOSTCC-57
  * Created reason              : ACH CONFIGURATION TEMP TO MAST COPY PROGRAM
  * Reviewer                    : SARAVANAKUMAR/SPANKAJ
  * Build Number                : VMSGPRHOSTCSD4.0_B0001

**************************************************************************************************/
--l_savepoint           NUMBER                              DEFAULT 1;
EXP_REJECT_RECORD EXCEPTION;


CURSOR ACH_BLACKLIST_INFO(l_prod_code_in IN VARCHAR)
IS
SELECT
VBS_SOURCE_NAME,
VBS_VALIDFROM_DATE,VBS_VALIDTO_DATE
FROM VMS_BLACKLIST_SOURCES_STAG
WHERE VBS_PROD_CODE=l_prod_code_in;


BEGIN

 p_errmsg_out  := 'OK';
-- SAVEPOINT l_savepoint;

 BEGIN

  FOR l_row_indx IN ACH_BLACKLIST_INFO(p_prod_code_in)
  LOOP
  INSERT INTO CMS_BLACKLIST_SOURCES (
    CBS_INST_CODE,
    CBS_SOURCE_NAME,
    CBS_INS_DATE,
    CBS_INS_USER,
    CBS_PROD_CODE,
    CBS_VALIDFROM_DATE,
    CBS_VALIDTO_DATE,
    CBS_LUPD_USER,
    CBS_LUPD_DATE)
    VALUES(
    p_instcode_in,
    l_row_indx.VBS_SOURCE_NAME,
    sysdate,
    p_ins_user_in,
    p_toprod_code_in,
    l_row_indx.VBS_VALIDFROM_DATE,
    l_row_indx.VBS_VALIDTO_DATE,
    p_ins_user_in,
    sysdate);

  END LOOP;

   EXCEPTION
            WHEN OTHERS
            THEN
               p_errmsg_out :=
                     'ERROR WHILE INSERTING INTO CMS_BLACKLIST_SOURCES:'
                  || SUBSTR (SQLERRM, 1, 300);
               RAISE EXP_REJECT_RECORD;

 END;

  EXCEPTION
  WHEN EXP_REJECT_RECORD THEN
  ROLLBACK;-- TO l_savepoint;
  WHEN OTHERS THEN
  ROLLBACK;-- TO l_savepoint;
  p_errmsg_out := 'Exception while copying PRODUCT_ACHCONFIG_MAST:' ||p_errmsg_out || SUBSTR(SQLERRM, 1, 200);

END;


--end ACH file process temp to mast

--Start card status copy


PROCEDURE        SP_CARDSTAT_COPY (
   p_instcode_in          IN       NUMBER,
   p_prod_code_in         IN       VARCHAR2,
   p_prod_catg_in         IN       VARCHAR2,
   p_toprod_code_in       IN       VARCHAR2,
   p_ins_user_in          IN       NUMBER,
   p_errmsg_out           OUT      VARCHAR2
)
IS
   /*************************************************
   * Created Date          :  07-Mar-2016
   * Created By            :  Mageshkumar.S
   * PURPOSE               :  HOSTCC-57
   * Created reason        : CARD STATUS COPY PROGRAM
   * Reviewer              : SARAVANAKUMAR/SPANKAJ
   * Build Number          : VMSGPRHOSTCSD4.0_B0001
   *************************************************/
--   l_savepoint           NUMBER                                     DEFAULT 1;
   exp_reject_record     EXCEPTION;
   total_product_cat     PLS_INTEGER;
   total_toproduct_cat   PLS_INTEGER;
   l_inst_code           gpr_valid_cardstat.gvc_inst_code%TYPE;
   l_card_stat           gpr_valid_cardstat.gvc_card_stat%TYPE;
   l_tran_code           gpr_valid_cardstat.gvc_tran_code%TYPE;
   l_ins_user            gpr_valid_cardstat.gvc_ins_user%TYPE;
   l_ins_date            gpr_valid_cardstat.gvc_ins_date%TYPE;
   l_lupd_date           gpr_valid_cardstat.gvc_lupd_date%TYPE;
   l_lupd_user           gpr_valid_cardstat.gvc_lupd_user%TYPE;
   l_delivery_channel    gpr_valid_cardstat.gvc_delivery_channel%TYPE;
   l_msg_type            gpr_valid_cardstat.gvc_msg_type%TYPE;
   l_stat_flag           gpr_valid_cardstat.gvc_stat_flag%TYPE;
   l_prod_code           gpr_valid_cardstat.gvc_prod_code%TYPE;
   l_prod_catg           gpr_valid_cardstat.gvc_card_type%TYPE;
   l_approve_txn         gpr_valid_cardstat.gvc_approve_txn%TYPE;
   l_int_ind             gpr_valid_cardstat.gvc_int_ind%TYPE;
   l_pinsign             gpr_valid_cardstat.gvc_pinsign%TYPE;
   l_mcc_id              gpr_valid_cardstat.gvc_mcc_id%TYPE;
   l_count               PLS_INTEGER;
  ref_cur_cardstat       sys_refcursor;


BEGIN
   p_errmsg_out := 'OK';
--   SAVEPOINT l_savepoint;

   IF p_prod_catg_in IS NOT NULL
   THEN
      BEGIN
         OPEN ref_cur_cardstat FOR
      'SELECT gvc_inst_code, gvc_card_stat, gvc_tran_code, gvc_ins_user,
             SYSDATE, SYSDATE, gvc_lupd_user, gvc_delivery_channel,
             gvc_msg_type, gvc_stat_flag, '''|| p_toprod_code_in||''', gvc_card_type,
             gvc_approve_txn, gvc_int_ind, gvc_pinsign, gvc_mcc_id
        FROM gpr_valid_cardstat
       WHERE gvc_prod_code ='''|| p_prod_code_in||'''
         AND gvc_card_type IN ('||p_prod_catg_in||')
         AND gvc_inst_code ='|| p_instcode_in;

         LOOP
            FETCH ref_cur_cardstat
             INTO l_inst_code, l_card_stat, l_tran_code, l_ins_user,
                  l_ins_date, l_lupd_date, l_lupd_user, l_delivery_channel,
                  l_msg_type, l_stat_flag, l_prod_code, l_prod_catg,
                  l_approve_txn, l_int_ind, l_pinsign, l_mcc_id;

            EXIT WHEN ref_cur_cardstat%NOTFOUND;

                IF l_mcc_id IS NOT NULL
                THEN
                   SELECT COUNT (*)
                     INTO l_count
                     FROM gpr_valid_cardstat
                    WHERE gvc_delivery_channel = l_delivery_channel
                      AND gvc_msg_type = l_msg_type
                      AND gvc_card_stat = l_card_stat
                      AND gvc_stat_flag = l_stat_flag
                      AND gvc_tran_code = l_tran_code
                      AND gvc_int_ind = l_int_ind
                      AND gvc_pinsign = l_pinsign
                      AND gvc_mcc_id IS NOT NULL
                      AND gvc_prod_code = l_prod_code
                      AND gvc_card_type = l_prod_catg
                      AND gvc_inst_code = l_inst_code;
                ELSE
                   SELECT COUNT (*)
                     INTO l_count
                     FROM gpr_valid_cardstat
                    WHERE gvc_delivery_channel = l_delivery_channel
                      AND gvc_msg_type = l_msg_type
                      AND gvc_card_stat = l_card_stat
                      AND gvc_stat_flag = l_stat_flag
                      AND gvc_tran_code = l_tran_code
                      AND gvc_int_ind = l_int_ind
                      AND gvc_pinsign = l_pinsign
                      AND gvc_mcc_id IS NULL
                      AND gvc_prod_code = l_prod_code
                      AND gvc_card_type = l_prod_catg
                      AND gvc_inst_code = l_inst_code;
                END IF;

            IF (l_count = 0)
            THEN
               BEGIN
                  IF l_mcc_id IS NOT NULL
                  THEN
                     BEGIN
                        SELECT seq_mcc_id.NEXTVAL
                          into L_MCC_ID
                          FROM DUAL;
                     EXCEPTION
                        WHEN OTHERS
                        THEN
                           p_errmsg_out := 'Error While generating MCC ID';
                           RAISE exp_reject_record;
                     END;
                  END IF;

                  BEGIN
                     INSERT INTO gpr_valid_cardstat
                                 (gvc_inst_code, gvc_card_stat,
                                  gvc_tran_code, gvc_ins_user, gvc_ins_date,
                                  gvc_lupd_date, gvc_lupd_user,
                                  gvc_delivery_channel, gvc_msg_type,
                                  gvc_stat_flag, gvc_prod_code,
                                  gvc_card_type, gvc_approve_txn,
                                  gvc_int_ind, gvc_pinsign, gvc_mcc_id
                                 )
                          VALUES (l_inst_code, l_card_stat,
                                  l_tran_code, l_ins_user, l_ins_date,
                                  l_lupd_date, l_lupd_user,
                                  l_delivery_channel, l_msg_type,
                                  l_stat_flag, l_prod_code,
                                  l_prod_catg, l_approve_txn,
                                  l_int_ind, l_pinsign, l_mcc_id
                                 );
                  EXCEPTION
                     WHEN OTHERS
                     THEN
                        p_errmsg_out :=
                           'Error on copy card status from product to to product';
                        RAISE exp_reject_record;
                  END;

                  BEGIN
                     IF l_mcc_id IS NOT NULL
                     THEN
                        INSERT INTO cms_mcc_tran
                                    (cmt_inst_code, cmt_mcc_id,
                                     cmt_mcc_code, cmt_ins_user,
                                     cmt_lupd_user, cmt_ins_date,
                                     cmt_lupd_date
                                    )
                             VALUES (l_inst_code, l_mcc_id,
                                     '6010', l_ins_user,
                                     l_lupd_user, SYSDATE,
                                     SYSDATE
                                    );
                     END IF;
                  EXCEPTION
                     WHEN OTHERS
                     then
                        p_errmsg_out := 'Error While inserting MCC Data'||SUBSTR(SQLERRM, 1, 200);
                        RAISE exp_reject_record;
                  END;
               END;
            END IF;
         END LOOP;
      EXCEPTION
        when EXP_REJECT_RECORD then
          raise;
         WHEN OTHERS
         THEN
            p_errmsg_out :=
                       'Error on copy card status from product to to product' || SUBSTR (SQLERRM, 1, 300);
            RAISE exp_reject_record;
      END;
   END IF;



EXCEPTION
   --<< MAIN EXCEPTION >>
   WHEN exp_reject_record
   THEN
      ROLLBACK;-- TO l_savepoint;
   WHEN OTHERS THEN
    ROLLBACK;-- TO l_savepoint;
    p_errmsg_out := 'Exception while copying card status' ||p_errmsg_out || SUBSTR(SQLERRM, 1, 200);
END;

--End card status copy

--Start SMS and Email copy

PROCEDURE SP_SMSEMAIL_ALERTS_COPY (
   p_instcode_in        IN       NUMBER,
   p_prod_code_in       IN       VARCHAR2,
   p_prod_catg_in       IN       VARCHAR2,
   p_toprod_code_in     IN       VARCHAR2,
   p_ins_user_in        IN       NUMBER,
   p_resp_msg_out       OUT      VARCHAR2
)
IS
   /*************************************************
   * Created Date          :  07-Mar-2016
   * Created By            :  Mageshkumar.S
   * PURPOSE               :  HOSTCC-57
   * Created reason        :  SMS AND EMAIL ALERTS COPY PROGRAM
   * Reviewer              :  SARAVANAKUMAR/SPANKAJ
   * Build Number          :  VMSGPRHOSTCSD4.0_B0001
   *************************************************/
--    l_savepoint          NUMBER   DEFAULT 1;
    exp_reject_record    EXCEPTION;
    l_card_type          CMS_PRODCATG_SMSEMAIL_ALERTS.CPS_CARD_TYPE%type;
    l_config_flag        CMS_PRODCATG_SMSEMAIL_ALERTS.CPS_CONFIG_FLAG%type;
    l_loadcr_flag        CMS_PRODCATG_SMSEMAIL_ALERTS.CPS_LOADCREDIT_FLAG%type;
    l_lowbal_flag        CMS_PRODCATG_SMSEMAIL_ALERTS.CPS_LOWBAL_FLAG%type;
    l_negbal_flag        CMS_PRODCATG_SMSEMAIL_ALERTS.CPS_NEGATIVEBAL_FLAG%type;
    l_highauthamt_flag   CMS_PRODCATG_SMSEMAIL_ALERTS.CPS_HIGHAUTHAMT_FLAG%type;
    l_dalybal_flag       CMS_PRODCATG_SMSEMAIL_ALERTS.CPS_DAILYBAL_FLAG%type;
    l_insuff_flag        CMS_PRODCATG_SMSEMAIL_ALERTS.CPS_INSUFFUND_FLAG%type;
    l_incorrpin_flag     CMS_PRODCATG_SMSEMAIL_ALERTS.CPS_INCORRECTPIN_FLAG%type;
    l_welcome_flag       CMS_PRODCATG_SMSEMAIL_ALERTS.CPS_WELCOME_FLAG%type;
    l_welcome_msg        CMS_PRODCATG_SMSEMAIL_ALERTS.CPS_WELCOME_MSG%type;
    l_loadcr_msg         CMS_PRODCATG_SMSEMAIL_ALERTS.CPS_LOADCREDIT_MSG%type;
    l_lowbal_msg         CMS_PRODCATG_SMSEMAIL_ALERTS.CPS_LOWBAL_MSG%type;
    l_negbal_msg         CMS_PRODCATG_SMSEMAIL_ALERTS.CPS_NEGATIVEBAL_MSG%type;
    l_highauthamt_msg    CMS_PRODCATG_SMSEMAIL_ALERTS.CPS_HIGHAUTHAMT_MSG%type;
    l_dalybal_msg        CMS_PRODCATG_SMSEMAIL_ALERTS.CPS_DAILYBAL_MSG%type;
    l_insuff_msg         CMS_PRODCATG_SMSEMAIL_ALERTS.CPS_INSUFFUND_MSG%type;
    l_incorrpin_msg      CMS_PRODCATG_SMSEMAIL_ALERTS.CPS_INCORRECTPIN_MSG%type;
    l_incorrpin_ivrmsg   CMS_PRODCATG_SMSEMAIL_ALERTS.CPS_INCORRECTPIN_IVR_MSG%type;
    l_incorrpin_chwmsg   CMS_PRODCATG_SMSEMAIL_ALERTS.CPS_INCORRECTPIN_CHW_MSG%type;
    l_c2c_transflag      CMS_PRODCATG_SMSEMAIL_ALERTS.CPS_CARDTOCARD_TRANS_FLAG%type;
    l_c2c_transmsg       CMS_PRODCATG_SMSEMAIL_ALERTS.CPS_CARDTOCARD_TRANS_MSG%type;
    l_fast50_flag        CMS_PRODCATG_SMSEMAIL_ALERTS.CPS_FAST50_FLAG%type;
    l_ftr_flag           CMS_PRODCATG_SMSEMAIL_ALERTS.CPS_FEDTAX_REFUND_FLAG%type;
    l_fast50_msg         CMS_PRODCATG_SMSEMAIL_ALERTS.CPS_FAST50_MSG%type;
    l_ftr_msg            CMS_PRODCATG_SMSEMAIL_ALERTS.CPS_FEDTAX_REFUND_MSG%type;
    l_optinout_stat      CMS_PRODCATG_SMSEMAIL_ALERTS.CPS_OPTINOPTOUT_STATUS%type;
    l_declalt_flag       CMS_PRODCATG_SMSEMAIL_ALERTS.CPS_DECLINEALTMSG_FLAG%type;
    l_declalt_msg        CMS_PRODCATG_SMSEMAIL_ALERTS.CPS_DECLINEALT_MSG%type;
    l_mobupdate_flag     CMS_PRODCATG_SMSEMAIL_ALERTS.CPS_MOBUPDATE_FLAG%type;
    l_mobupdate_msg      CMS_PRODCATG_SMSEMAIL_ALERTS.CPS_MOBUPDATE_MSG%type;
    l_kycfail_flag       CMS_PRODCATG_SMSEMAIL_ALERTS.CPS_KYCFAIL_FLAG%type;
    l_kycfail_msg        CMS_PRODCATG_SMSEMAIL_ALERTS.CPS_KYCFAIL_MSG%type;
    l_kycsucc_flag       CMS_PRODCATG_SMSEMAIL_ALERTS.CPS_KYCSUCCESS_FLAG%type;
    l_kycsucc_msg        CMS_PRODCATG_SMSEMAIL_ALERTS.CPS_KYCSUCCESS_MSG%type;
    l_kycfail_intvl      CMS_PRODCATG_SMSEMAIL_ALERTS.CPS_KYCFAIL_INTERVAL%type;
    l_renewalt_flag      CMS_PRODCATG_SMSEMAIL_ALERTS.CPS_RENEWALALT_FLAG%type;
    l_renewalt_msg       CMS_PRODCATG_SMSEMAIL_ALERTS.CPS_RENEWALALT_MSG%type;
    l_chkpend_flag       CMS_PRODCATG_SMSEMAIL_ALERTS.CPS_CHKPENDING_FLAG%type;
    l_chkpend_msg        CMS_PRODCATG_SMSEMAIL_ALERTS.CPS_CHKPENDING_MSG%type;
    l_chkappr_flag       CMS_PRODCATG_SMSEMAIL_ALERTS.CPS_CHKAPPROVED_FLAG%type;
    l_chkappr_msg        CMS_PRODCATG_SMSEMAIL_ALERTS.CPS_CHKAPPROVED_MSG%type;
    l_chkrej_flag        CMS_PRODCATG_SMSEMAIL_ALERTS.CPS_CHKREJECTED_FLAG%type;
    l_chkrej_msg         CMS_PRODCATG_SMSEMAIL_ALERTS.CPS_CHKREJECTED_MSG%type;
    l_alert_id           CMS_PRODCATG_SMSEMAIL_ALERTS.CPS_ALERT_ID%type;
    l_altlang_id         CMS_PRODCATG_SMSEMAIL_ALERTS.CPS_ALERT_LANG_ID%type;
    l_dfltalt_langflag   CMS_PRODCATG_SMSEMAIL_ALERTS.CPS_DEFALERT_LANG_FLAG%type;
    l_alt_msg            CMS_PRODCATG_SMSEMAIL_ALERTS.CPS_ALERT_MSG%type;

    REF_CURSOR_SMEMAILALERTS sys_refcursor;

BEGIN
   p_resp_msg_out := 'OK';
--   SAVEPOINT l_savepoint;

 BEGIN

    OPEN REF_CURSOR_SMEMAILALERTS FOR
           'SELECT CPS_CARD_TYPE,CPS_CONFIG_FLAG, CPS_LOADCREDIT_FLAG,CPS_LOWBAL_FLAG,CPS_NEGATIVEBAL_FLAG,
            CPS_HIGHAUTHAMT_FLAG,CPS_DAILYBAL_FLAG,CPS_INSUFFUND_FLAG,CPS_INCORRECTPIN_FLAG,
            CPS_WELCOME_FLAG,CPS_WELCOME_MSG,CPS_LOADCREDIT_MSG,CPS_LOWBAL_MSG,
            CPS_NEGATIVEBAL_MSG,CPS_HIGHAUTHAMT_MSG,CPS_DAILYBAL_MSG,CPS_INSUFFUND_MSG,
            CPS_INCORRECTPIN_MSG,CPS_INCORRECTPIN_IVR_MSG,CPS_INCORRECTPIN_CHW_MSG,CPS_CARDTOCARD_TRANS_FLAG,
            CPS_CARDTOCARD_TRANS_MSG,CPS_FAST50_FLAG,CPS_FEDTAX_REFUND_FLAG,CPS_FAST50_MSG,
            CPS_FEDTAX_REFUND_MSG,CPS_OPTINOPTOUT_STATUS,CPS_DECLINEALTMSG_FLAG,CPS_DECLINEALT_MSG,
            CPS_MOBUPDATE_FLAG,CPS_MOBUPDATE_MSG,CPS_KYCFAIL_FLAG,CPS_KYCFAIL_MSG,
            CPS_KYCSUCCESS_FLAG,CPS_KYCSUCCESS_MSG,CPS_KYCFAIL_INTERVAL,CPS_RENEWALALT_FLAG,
            CPS_RENEWALALT_MSG,CPS_CHKPENDING_FLAG,CPS_CHKPENDING_MSG,CPS_CHKAPPROVED_FLAG,
            CPS_CHKAPPROVED_MSG,CPS_CHKREJECTED_FLAG,CPS_CHKREJECTED_MSG,CPS_ALERT_ID,
            CPS_ALERT_LANG_ID,CPS_DEFALERT_LANG_FLAG,CPS_ALERT_MSG
            FROM CMS_PRODCATG_SMSEMAIL_ALERTS
            WHERE CPS_PROD_CODE = '''||p_prod_code_in||'''
            AND cps_alert_lang_id <> 0 AND CPS_CARD_TYPE IN('||p_prod_catg_in||')';
            LOOP
            fetch REF_CURSOR_SMEMAILALERTS into l_card_type,l_config_flag,l_loadcr_flag,l_lowbal_flag,l_negbal_flag,
            l_highauthamt_flag,l_dalybal_flag,l_insuff_flag,l_incorrpin_flag,
            l_welcome_flag,l_welcome_msg,l_loadcr_msg,l_lowbal_msg,
            l_negbal_msg,l_highauthamt_msg,l_dalybal_msg,l_insuff_msg,
            l_incorrpin_msg,l_incorrpin_ivrmsg,l_incorrpin_chwmsg,l_c2c_transflag,
            l_c2c_transmsg,l_fast50_flag,l_ftr_flag,l_fast50_msg,
            l_ftr_msg,l_optinout_stat,l_declalt_flag,l_declalt_msg,
            l_mobupdate_flag,l_mobupdate_msg,l_kycfail_flag,l_kycfail_msg,
            l_kycsucc_flag,l_kycsucc_msg,l_kycfail_intvl,l_renewalt_flag,
            l_renewalt_msg,l_chkpend_flag,l_chkpend_msg,l_chkappr_flag,
            l_chkappr_msg,l_chkrej_flag,l_chkrej_msg,l_alert_id,
            l_altlang_id,l_dfltalt_langflag,l_alt_msg;
            exit WHEN REF_CURSOR_SMEMAILALERTS%NOTFOUND;

    BEGIN
            UPDATE  CMS_PRODCATG_SMSEMAIL_ALERTS
            SET
            CPS_CARD_TYPE = l_card_type,CPS_CONFIG_FLAG = l_config_flag,
            CPS_LOADCREDIT_FLAG = l_loadcr_flag,CPS_LOWBAL_FLAG = l_lowbal_flag,
            CPS_NEGATIVEBAL_FLAG = l_negbal_flag,CPS_HIGHAUTHAMT_FLAG = l_highauthamt_flag,
            CPS_DAILYBAL_FLAG = l_dalybal_flag,CPS_INSUFFUND_FLAG = l_insuff_flag,CPS_INCORRECTPIN_FLAG = l_incorrpin_flag,
            CPS_INS_USER = p_ins_user_in,CPS_INS_DATE = sysdate,CPS_LUPD_USER = p_ins_user_in,CPS_LUPD_DATE = sysdate,
            CPS_WELCOME_FLAG = l_welcome_flag,CPS_WELCOME_MSG = l_welcome_msg,
            CPS_LOADCREDIT_MSG = l_loadcr_msg,CPS_LOWBAL_MSG = l_lowbal_msg,
            CPS_NEGATIVEBAL_MSG = l_negbal_msg,CPS_HIGHAUTHAMT_MSG = l_highauthamt_msg,
            CPS_DAILYBAL_MSG = l_dalybal_msg,CPS_INSUFFUND_MSG = l_insuff_msg,
            CPS_INCORRECTPIN_MSG = l_incorrpin_msg,CPS_INCORRECTPIN_IVR_MSG = l_incorrpin_ivrmsg,
            CPS_INCORRECTPIN_CHW_MSG = l_incorrpin_chwmsg,CPS_CARDTOCARD_TRANS_FLAG = l_c2c_transflag,
            CPS_CARDTOCARD_TRANS_MSG = l_c2c_transmsg,CPS_FAST50_FLAG = l_fast50_flag,
            CPS_FEDTAX_REFUND_FLAG = l_ftr_flag,CPS_FAST50_MSG = l_fast50_msg,
            CPS_FEDTAX_REFUND_MSG = l_ftr_msg,CPS_OPTINOPTOUT_STATUS = l_optinout_stat,
            CPS_DECLINEALTMSG_FLAG = l_declalt_flag,CPS_DECLINEALT_MSG = l_declalt_msg,
            CPS_MOBUPDATE_FLAG = l_mobupdate_flag,CPS_MOBUPDATE_MSG = l_mobupdate_msg,
            CPS_KYCFAIL_FLAG = l_kycfail_flag,CPS_KYCFAIL_MSG = l_kycfail_msg,
            CPS_KYCSUCCESS_FLAG = l_kycsucc_flag,CPS_KYCSUCCESS_MSG = l_kycsucc_msg,
            CPS_KYCFAIL_INTERVAL = l_kycfail_intvl,CPS_RENEWALALT_FLAG = l_renewalt_flag,
            CPS_RENEWALALT_MSG = l_renewalt_msg,CPS_CHKPENDING_FLAG =l_chkpend_flag,
            CPS_CHKPENDING_MSG = l_chkpend_msg,CPS_CHKAPPROVED_FLAG = l_chkappr_flag,
            CPS_CHKAPPROVED_MSG = l_chkappr_msg,CPS_CHKREJECTED_FLAG = l_chkrej_flag,
            CPS_CHKREJECTED_MSG = l_chkrej_msg,CPS_ALERT_ID = l_alert_id,
            CPS_ALERT_LANG_ID = l_altlang_id,CPS_DEFALERT_LANG_FLAG = l_dfltalt_langflag,
            CPS_ALERT_MSG = l_alt_msg
            WHERE
            CPS_PROD_CODE = p_toprod_code_in
            AND CPS_CARD_TYPE = l_card_type
            AND  CPS_ALERT_LANG_ID = l_altlang_id
            AND CPS_ALERT_ID = l_alert_id;

        IF SQL%ROWCOUNT =0 THEN
           p_resp_msg_out := 'No records updated in CMS_PRODCATG_SMSEMAIL_ALERTS table for prod code-'||p_toprod_code_in;
          -- ||SUBSTR(SQLERRM, 1, 200);
          RAISE EXP_REJECT_RECORD;
        END IF;
            EXCEPTION
--    WHEN NO_DATA_FOUND THEN
--    NULL;
    WHEN exp_reject_record
      THEN
      RAISE;
   --   ROLLBACK;-- TO l_savepoint;
        WHEN OTHERS THEN
        p_resp_msg_out := p_resp_msg_out || 'ERROR WHILE COPYING SMS AND EMAIL ALERTS:' ||
                           SUBSTR(SQLERRM, 1, 200);
        RAISE exp_reject_record;

    END;

    END LOOP;
    EXCEPTION
        when EXP_REJECT_RECORD then
        RAISE;
        WHEN OTHERS THEN
        p_resp_msg_out := p_resp_msg_out || 'ERROR WHILE COPYING SMS AND EMAIL ALERTS:' ||
                           SUBSTR(SQLERRM, 1, 200);
        RAISE exp_reject_record;

   END;

EXCEPTION --<< MAIN EXCEPTION >>
   WHEN exp_reject_record
   THEN
      ROLLBACK;-- TO l_savepoint;
   WHEN OTHERS THEN
     p_resp_msg_out := 'Main Excp--'|| SUBSTR (SQLERRM, 1, 200);
END;

--End SMS and Email copy

--Start rule copy program

PROCEDURE SP_RULE_COPY (
   p_instcode_in        IN       NUMBER,
   p_prod_code_in       IN       VARCHAR2,
   p_prod_catg_in       IN       VARCHAR2,
   p_toprod_code_in     IN       VARCHAR2,
   p_ins_user_in        IN       NUMBER,
   p_resp_msg_out       OUT      VARCHAR2
)
IS
   /*************************************************
   * Created Date          :  07-Mar-2016
   * Created By            :  Mageshkumar.S
   * PURPOSE               :  HOSTCC-57
   * Created reason        :  RULE COPY PROGRAM
   * Reviewer              :  SARAVANAKUMAR/SPANKAJ
   * Build Number          :  VMSGPRHOSTCSD4.0_B0001
   *************************************************/
 --   l_savepoint          NUMBER   DEFAULT 1;
    exp_reject_record    EXCEPTION;
    l_card_type          CMS_PRODCATG_SMSEMAIL_ALERTS.CPS_CARD_TYPE%type;
    l_rulegrp_code       PCMS_PROD_RULEGROUP.PPR_RULEGROUP_CODE%TYPE;
    l_valid_to           PCMS_PROD_RULEGROUP.PPR_VALID_TO%TYPE;
    l_flow_src           PCMS_PRODCATTYPE_RULEGROUP.PPR_FLOW_SOURCE%type;
    l_active_flag        PCMS_PRODCATTYPE_RULEGROUP.PPR_ACTIVE_FLAG%type;
    l_permrule_flag      PCMS_PRODCATTYPE_RULEGROUP.PPR_PERMRULE_FLAG%type;

    REF_CURSOR_PRODRULECOPY sys_refcursor;
    REF_CURSOR_PRODCATGRULECOPY sys_refcursor;

BEGIN
   p_resp_msg_out := 'OK';
 --  SAVEPOINT l_savepoint;

 BEGIN

    OPEN REF_CURSOR_PRODRULECOPY FOR
           'SELECT PPR_RULEGROUP_CODE,PPR_VALID_TO
            FROM PCMS_PROD_RULEGROUP
            WHERE PPR_PROD_CODE = '''||p_prod_code_in||''' AND PPR_VALID_TO >=SYSDATE';
            LOOP
            FETCH REF_CURSOR_PRODRULECOPY INTO l_rulegrp_code,l_valid_to;
            exit WHEN REF_CURSOR_PRODRULECOPY%NOTFOUND;

            INSERT INTO PCMS_PROD_RULEGROUP(PPR_INST_CODE,
                                            PPR_PROD_CODE,
                                            PPR_RULEGROUP_CODE,
                                            PPR_VALID_FROM,
                                            PPR_VALID_TO,
                                            PPR_INS_USER,
                                            PPR_INS_DATE,
                                            PPR_LUPD_USER,
                                            PPR_LUPD_DATE)
                                            VALUES(
                                            p_instcode_in,
                                            p_toprod_code_in,
                                            l_rulegrp_code,
                                            SYSDATE,
                                            l_valid_to,
                                            p_ins_user_in,
                                            SYSDATE,
                                            p_ins_user_in,
                                            SYSDATE);



    END LOOP;
    EXCEPTION
   -- WHEN NO_DATA_FOUND THEN
   -- NULL;
        WHEN OTHERS THEN
        p_resp_msg_out := 'ERROR WHILE COPYING PRODUCT RULE COPY:' ||
                           SUBSTR(SQLERRM, 1, 200);
        RAISE exp_reject_record;

   END;

   BEGIN

    OPEN REF_CURSOR_PRODCATGRULECOPY FOR
           'SELECT PPR_CARD_TYPE,PPR_RULEGROUP_CODE,
            PPR_VALID_TO,PPR_FLOW_SOURCE,PPR_ACTIVE_FLAG,PPR_PERMRULE_FLAG
            FROM PCMS_PRODCATTYPE_RULEGROUP
            WHERE PPR_PROD_CODE = '''||p_prod_code_in||'''
            and PPR_CARD_TYPE IN ('||p_prod_catg_in||') AND PPR_VALID_TO >=SYSDATE';
            LOOP
            FETCH REF_CURSOR_PRODCATGRULECOPY INTO l_card_type,l_rulegrp_code,l_valid_to,
            l_flow_src,l_active_flag,l_permrule_flag;
            exit WHEN REF_CURSOR_PRODCATGRULECOPY%NOTFOUND;


            INSERT INTO PCMS_PRODCATTYPE_RULEGROUP(PPR_INST_CODE,
                                            PPR_PROD_CODE,
                                            PPR_CARD_TYPE,
                                            PPR_RULEGROUP_CODE,
                                            PPR_VALID_FROM,
                                            PPR_VALID_TO,
                                            PPR_FLOW_SOURCE,
                                            PPR_ACTIVE_FLAG,
                                            PPR_PERMRULE_FLAG,
                                            PPR_INS_USER,
                                            PPR_INS_DATE,
                                            PPR_LUPD_USER,
                                            PPR_LUPD_DATE)
                                            VALUES(
                                            p_instcode_in,
                                            p_toprod_code_in,
                                            l_card_type,
                                            l_rulegrp_code,
                                            SYSDATE,
                                            l_valid_to,
                                            l_flow_src,
                                            l_active_flag,
                                            l_permrule_flag,
                                            p_ins_user_in,
                                            SYSDATE,
                                            p_ins_user_in,
                                            SYSDATE);
    END LOOP;
    EXCEPTION
 --   WHEN NO_DATA_FOUND THEN
 --   NULL;
        WHEN OTHERS THEN
        p_resp_msg_out := 'ERROR WHILE COPYING PRODUCT CATEGORY RULE COPY:' ||
                           SUBSTR(SQLERRM, 1, 200);
        RAISE exp_reject_record;

   END;

EXCEPTION --<< MAIN EXCEPTION >>
   WHEN exp_reject_record
   THEN
      ROLLBACK;-- TO l_savepoint;
   WHEN OTHERS THEN
     p_resp_msg_out := 'Main Excp--'|| SUBSTR (SQLERRM, 1, 200);
END;

--End rule copy program



PROCEDURE   PRODUCTCOPY_PROGRAMMAST (
   p_instcode_in            IN       NUMBER,
   p_prod_code_in           IN       VARCHAR2,
   p_card_type_in           IN       VARCHAR2,
   p_ins_user_in            IN       NUMBER,
   p_prod_code_out          OUT      VARCHAR2,
   p_resp_code_out          OUT      VARCHAR2,
   p_errmsg_out             OUT      VARCHAR2
)
IS

/**********************************************************************************************

  * Created by                  : MageshKumar S.
  * Created Date                : 07-MAR-16
  * Created For                 : HOSTCC-57
  * Created reason              : PRODUCT COPY PROGRAM TEMP TO MAST
  * Reviewer                    : SARAVANAKUMAR/SPANKAJ
  * Build Number                : VMSGPRHOSTCSD4.0_B0001

**************************************************************************************************/

--l_savepoint           NUMBER                              DEFAULT 1;
EXP_REJECT_RECORD EXCEPTION;
p_toprod_profilecode_out  VARCHAR2(5);
l_enable_flag VARCHAR2(50);

BEGIN
 p_errmsg_out  := 'OK';
 p_resp_code_out := '00';
-- SAVEPOINT l_savepoint;

 BEGIN


  SELECT listagg(VPC_COPY_ID,',') within group(ORDER BY VPC_COPY_ID) INTO l_enable_flag  from  VMS_PRODPARAM_COPY where vpm_enable_flag='Y' and vpc_copy_id in ('8','9','10','11','12');
  EXCEPTION
  WHEN OTHERS THEN
  p_errmsg_out := 'ERROR WHILE SELECTING ENABLE FLAG FROM VMS_PRODPARAM_COPY:'|| SUBSTR (SQLERRM, 1, 200);
  RAISE EXP_REJECT_RECORD;

 END;



BEGIN

  PRODUCT_PROFILE_MAST(p_instcode_in,
                       p_ins_user_in,
                       p_prod_code_in,
                       p_card_type_in,
                       p_toprod_profilecode_out,
                       p_errmsg_out);

          IF p_errmsg_out <> 'OK'
            THEN
               RAISE EXP_REJECT_RECORD;
            END IF;
         EXCEPTION
            WHEN EXP_REJECT_RECORD
            THEN
               RAISE;
            WHEN OTHERS
            THEN
               p_errmsg_out :=
                  'ERROR WHILE CALLING PRODUCT_PROFILE_MAST PROCESS:'
                  || SUBSTR (SQLERRM, 1, 200);
               RAISE EXP_REJECT_RECORD;

END;


--BEGIN
--
--  PRODCATG_PROFILE_MAST(p_instcode_in,
--                        p_ins_user_in,
--                        p_prod_code_in,
--                        p_card_type_in,
--                        p_errmsg_out);
--
--          IF p_errmsg_out <> 'OK'
--            THEN
--               RAISE EXP_REJECT_RECORD;
--            END IF;
--         EXCEPTION
--            WHEN EXP_REJECT_RECORD
--            THEN
--               RAISE;
--            WHEN OTHERS
--            THEN
--               p_errmsg_out :=
--                  'ERROR WHILE CALLING PRODCATG_PROFILE_MAST PROCESS:'
--                  || SUBSTR (SQLERRM, 1, 200);
--               RAISE EXP_REJECT_RECORD;
--
--END;

BEGIN

  PRODUCT_PARAMETER_MAST(p_instcode_in,
                         p_ins_user_in,
                         p_prod_code_in,
                         p_toprod_profilecode_out,
                         p_prod_code_out,
                         p_errmsg_out);

          IF p_errmsg_out <> 'OK'
            THEN
               RAISE EXP_REJECT_RECORD;
            END IF;
         EXCEPTION
            WHEN EXP_REJECT_RECORD
            THEN
               RAISE;
            WHEN OTHERS
            THEN
               p_errmsg_out :=
                  'ERROR WHILE CALLING PRODUCT_PARAMETER_MAST PROCESS:'
                  || SUBSTR (SQLERRM, 1, 200);
               RAISE EXP_REJECT_RECORD;

END;


BEGIN

  PRODCATG_PARAMETER_MAST(p_instcode_in,
                          p_ins_user_in,
                          p_prod_code_in,
                          p_card_type_in,
                          p_prod_code_out,
                          p_errmsg_out);

          IF p_errmsg_out <> 'OK'
            THEN
               RAISE EXP_REJECT_RECORD;
            END IF;
         EXCEPTION
            WHEN EXP_REJECT_RECORD
            THEN
               RAISE;
            WHEN OTHERS
            THEN
               p_errmsg_out :=
                  'ERROR WHILE CALLING PRODCATG_PARAMETER_MAST PROCESS:'
                  || SUBSTR (SQLERRM, 1, 200);
               RAISE EXP_REJECT_RECORD;

END;




BEGIN

  PRODUCT_SAVINGSPARAM_MAST(p_instcode_in,
                            p_ins_user_in,
                            p_prod_code_in,
                            p_prod_code_out,
                            p_card_type_in,
                            p_errmsg_out);

          IF p_errmsg_out <> 'OK'
            THEN
               RAISE EXP_REJECT_RECORD;
            END IF;
         EXCEPTION
            WHEN EXP_REJECT_RECORD
            THEN
               RAISE;
            WHEN OTHERS
            THEN
               p_errmsg_out :=
                  'ERROR WHILE CALLING PRODUCT_SAVINGSPARAM_MAST PROCESS:'
                  || SUBSTR (SQLERRM, 1, 200);
               RAISE EXP_REJECT_RECORD;

END;

BEGIN

  PRODUCT_EMBOSSFORMAT_MAST(p_instcode_in,
                            p_ins_user_in,
                            p_prod_code_in,
                            p_prod_code_out,
                            p_toprod_profilecode_out,
                            p_card_type_in,
                            p_errmsg_out);

          IF p_errmsg_out <> 'OK'
            THEN
               RAISE EXP_REJECT_RECORD;
            END IF;
         EXCEPTION
            WHEN EXP_REJECT_RECORD
            THEN
               RAISE;
            WHEN OTHERS
            THEN
               p_errmsg_out :=
                  'ERROR WHILE CALLING PRODUCT_EMBOSSFORMAT_MAST PROCESS:'
                  || SUBSTR (SQLERRM, 1, 200);
               RAISE EXP_REJECT_RECORD;

END;

BEGIN

  PRODUCT_ACHCONFIG_MAST(p_instcode_in,
                         p_ins_user_in,
                         p_prod_code_in,
                         p_prod_code_out,
                         p_errmsg_out);

          IF p_errmsg_out <> 'OK'
            THEN
               RAISE EXP_REJECT_RECORD;
            END IF;
         EXCEPTION
            WHEN EXP_REJECT_RECORD
            THEN
               RAISE;
            WHEN OTHERS
            THEN
               p_errmsg_out :=
                  'ERROR WHILE CALLING PRODUCT_ACHCONFIG_MAST PROCESS:'
                  || SUBSTR (SQLERRM, 1, 200);
               RAISE EXP_REJECT_RECORD;

END;

IF (INSTR(l_enable_flag,8)>0) THEN
BEGIN

   SP_CARDSTAT_COPY (p_instcode_in,
                       p_prod_code_in,
                       p_card_type_in,
                       p_prod_code_out,
                       p_ins_user_in,
                       p_errmsg_out);

            IF p_errmsg_out <> 'OK'
                        THEN
                           RAISE EXP_REJECT_RECORD;
                        END IF;
                     EXCEPTION
                        WHEN EXP_REJECT_RECORD
                        THEN
                           RAISE;
                        WHEN OTHERS
                        THEN
                           p_errmsg_out :=
                              'ERROR WHILE CALLING SP_CARDSTAT_COPY PROCESS:'
                              || SUBSTR (SQLERRM, 1, 200);
                           RAISE EXP_REJECT_RECORD;

END;
END IF;

IF (INSTR(l_enable_flag,9)>0) THEN
BEGIN

     SP_SMSEMAIL_ALERTS_COPY(p_instcode_in,
                             p_prod_code_in,
                             p_card_type_in,
                             p_prod_code_out,
                             p_ins_user_in,
                             p_errmsg_out);

                  IF p_errmsg_out <> 'OK'
                              THEN
                                 RAISE EXP_REJECT_RECORD;
                              END IF;
                           EXCEPTION
                              WHEN EXP_REJECT_RECORD
                              THEN
                                 RAISE;
                              WHEN OTHERS
                              THEN
                                 p_errmsg_out :=
                                    'ERROR WHILE CALLING SP_SMSEMAIL_ALERTS_COPY PROCESS:'
                                    || SUBSTR (SQLERRM, 1, 200);
                                 RAISE EXP_REJECT_RECORD;

END;
END IF;

IF (INSTR(l_enable_flag,10)>0) THEN
BEGIN
   sp_paste_fees (p_instcode_in,
                  p_prod_code_in,
                  p_prod_code_out,
                  p_ins_user_in,
                  p_errmsg_out);

   IF p_errmsg_out <> 'OK'
   THEN
      RAISE exp_reject_record;
   END IF;
EXCEPTION
   WHEN exp_reject_record
   THEN
      RAISE;
   WHEN OTHERS
   THEN
      p_errmsg_out :=
         'Error while calling sp_paste_fees process:'
         || SUBSTR (SQLERRM, 1, 200);
      RAISE exp_reject_record;
END;
END IF;

IF (INSTR(l_enable_flag,11)>0) THEN
BEGIN
   sp_paste_lmts (p_instcode_in,
                  p_prod_code_in,
                  p_prod_code_out,
                  p_ins_user_in,
                  p_errmsg_out);

   IF p_errmsg_out <> 'OK'
   THEN
      RAISE exp_reject_record;
   END IF;
EXCEPTION
   WHEN exp_reject_record
   THEN
      RAISE;
   WHEN OTHERS
   THEN
      p_errmsg_out :=
         'Error while calling sp_paste_lmts process:'
         || SUBSTR (SQLERRM, 1, 200);
      RAISE exp_reject_record;
END;
END IF;


IF (INSTR(l_enable_flag,12)>0) THEN
BEGIN

          SP_RULE_COPY(p_instcode_in,
                       p_prod_code_in,
                       p_card_type_in,
                       p_prod_code_out,
                       p_ins_user_in,
                       p_errmsg_out);

            IF p_errmsg_out <> 'OK'
                        THEN
                           RAISE EXP_REJECT_RECORD;
                        END IF;
                     EXCEPTION
                        WHEN EXP_REJECT_RECORD
                        THEN
                           RAISE;
                        WHEN OTHERS
                        THEN
                           p_errmsg_out :=
                              'ERROR WHILE CALLING SP_RULE_COPY PROCESS:'
                              || SUBSTR (SQLERRM, 1, 200);
                           RAISE EXP_REJECT_RECORD;

END;
END IF;

BEGIN

          VMSPRODUCT.SP_CLEAR_COPY(p_instcode_in,
                                   p_ins_user_in,
                                   p_errmsg_out);

            IF p_errmsg_out <> 'OK'
                        THEN
                           RAISE EXP_REJECT_RECORD;
                        END IF;
                     EXCEPTION
                        WHEN EXP_REJECT_RECORD
                        THEN
                           RAISE;
                        WHEN OTHERS
                        THEN
                           p_errmsg_out :=
                              'ERROR WHILE CALLING SP_CLEAR_COPY PROCESS:'
                              || SUBSTR (SQLERRM, 1, 200);
                           RAISE EXP_REJECT_RECORD;

END;

BEGIN

  INSERT INTO VMS_COPYPROD_INFO(VPC_SRCPROD_CODE,
                                VPC_DESTPROD_CODE,
                                VPC_INS_USER,
                                VPC_INS_DATE)
                                VALUES(p_prod_code_in,
                                p_prod_code_out,
                                p_ins_user_in,
                                SYSDATE);
    EXCEPTION
    WHEN OTHERS THEN
    p_errmsg_out :='ERROR WHILE INSERTING DETAILS IN VMS_COPYPROD_INFO TABLE:'|| SUBSTR (SQLERRM, 1, 200);
    RAISE EXP_REJECT_RECORD;

END;



EXCEPTION
  WHEN EXP_REJECT_RECORD THEN
  ROLLBACK; --;TO l_savepoint;
  WHEN OTHERS THEN
  ROLLBACK;-- TO l_savepoint;
  p_resp_code_out := '21';
  p_errmsg_out := 'Exception while copying PRODUCTCOPY_PROGRAMMAST:' ||p_errmsg_out || SUBSTR(SQLERRM, 1, 200);

END;


--End product copy temp to mast

--Start clear temp table

PROCEDURE SP_CLEAR_COPY (
   p_instcode_in        IN       NUMBER,
   p_ins_user_in        IN       NUMBER,
   p_resp_msg_out       OUT      VARCHAR2
)
IS
   /*************************************************
   * Created Date          :  07-Mar-2016
   * Created By            :  Mageshkumar.S
   * PURPOSE               :  HOSTCC-57
   * Created reason        :  CLEAR TEMP TABLE
   * Reviewer              :  SARAVANAKUMAR/SPANKAJ
   * Build Number          :  VMSGPRHOSTCSD4.0_B0001
   
   * Modified by      : Narayana
   * Modified For     : VMS-1048 (VMS Host Configure new product in Dev A to replicate to other lower environments)
   * Modified Date    : 13-AUG-2019
   * Reviewer         : Saravanakumar
   * Build Number     : R19_B0002  
   *************************************************/

  --  exp_reject_record    EXCEPTION;


BEGIN
   p_resp_msg_out := 'OK';


 BEGIN

    truncate_tab_ebr ('VMS_PROFILE_MAST_STAG');
    truncate_tab_ebr ('VMS_PAN_CONSTRUCT_STAG');
    truncate_tab_ebr ('VMS_ACCT_CONSTRUCT_STAG');
    truncate_tab_ebr ('VMS_SAVINGSACCT_CONSTRUCT_STAG');
    truncate_tab_ebr ('VMS_BIN_PARAM_STAG');
    truncate_tab_ebr ('VMS_PROD_MAST_STAG');
    truncate_tab_ebr ('VMS_PROD_BIN_STAG');
    truncate_tab_ebr ('VMS_PROD_THRESHOLD_STAG');
    truncate_tab_ebr ('VMS_PRODUCT_PARAM_STAG');
    truncate_tab_ebr ('VMS_PROD_CARDPACK_STAG');
    truncate_tab_ebr ('VMS_PACKAGEID_MAST_STAG');
    truncate_tab_ebr ('VMS_PACKAGEID_DETL_STAG');
    truncate_tab_ebr ('VMS_PRODNETWORKID_MAPPING_STAG');
    truncate_tab_ebr ('VMS_SCORECARD_PRODMAPPING_STAG');
    truncate_tab_ebr ('VMS_DFG_PARAM_STAG');
    truncate_tab_ebr ('VMS_EMBOSS_FILE_FORMAT_STAG');
    truncate_tab_ebr ('VMS_BLACKLIST_SOURCES_STAG');
    truncate_tab_ebr ('VMS_COMPANY_NAME_STAG');
    truncate_tab_ebr ('VMS_PROD_CATTYPE_STAG');
    truncate_tab_ebr ('VMS_PROD_CATSEC_STAG');
    truncate_tab_ebr ('VMS_PRODCAT_CARDPACK_STAG');
    truncate_tab_ebr ('VMS_PRODCATG_COPY_INFO');
    truncate_tab_ebr ('VMS_FEEPLAN_DTLS_STAG');
    truncate_tab_ebr ('VMS_FEE_FEEPLAN_STAG');
    truncate_tab_ebr ('VMS_FEE_MAST_STAG');
    truncate_tab_ebr ('VMS_LMTPRFL_DTLS_STAG');
    truncate_tab_ebr ('VMS_LIMIT_PRFL_STAG');
    truncate_tab_ebr ('VMS_GROUP_LIMIT_STAG');
    truncate_tab_ebr ('VMS_GRPLMT_PARAM_STAG');
    truncate_tab_ebr ('VMS_PRODCAT_THRESHOLD_STAG');
    truncate_tab_ebr ('VMS_PRODCAT_DENO_MAST_STAG');
    truncate_tab_ebr ('VMS_PRODCAT_NETWORKID_MAP_STAG');
    truncate_tab_ebr ('VMS_SCORECARD_PRODCAT_MAP_STAG');
 EXCEPTION
 --  WHEN exp_reject_record
  ---- THEN
 --     ROLLBACK;
   WHEN OTHERS THEN
     p_resp_msg_out := 'ERROR WHILE CLEARING TEMP TABLES-'|| SUBSTR (SQLERRM, 1, 200);


 END;


EXCEPTION --<< MAIN EXCEPTION >>
  -- WHEN exp_reject_record
 --  THEN
  --    ROLLBACK;-- TO l_savepoint;
   WHEN OTHERS THEN
     p_resp_msg_out := 'Main Excp--'|| SUBSTR (SQLERRM, 1, 200);
END;

--End clear temp table


PROCEDURE tbl_to_xml (p_xmldata_out OUT XMLTYPE, p_respmsg_out OUT VARCHAR2)
/**************************************************************************************************
 
   * Modified by      : Narayana
   * Modified For     : VMS-1048 (VMS Host Configure new product in Dev A to replicate to other lower environments)
   * Modified Date    : 13-AUG-2019
   * Reviewer         : Saravanakumar
   * Build Number     : R19_B0002  

**************************************************************************************************/

AS
   l_xmldata    XMLTYPE;
   l_xml_data   CLOB;

   TYPE typ_tbl_list IS VARRAY (35) OF VARCHAR2 (35);

   l_tbl_list   typ_tbl_list;
BEGIN
   p_respmsg_out:='OK';
   l_tbl_list :=
      typ_tbl_list ('VMS_PRODCATG_COPY_INFO',
                    'VMS_PROFILE_MAST_STAG',
                    'VMS_PAN_CONSTRUCT_STAG',
                    'VMS_ACCT_CONSTRUCT_STAG',
                    'VMS_SAVINGSACCT_CONSTRUCT_STAG',
                    'VMS_BIN_PARAM_STAG',
                    'VMS_PROD_MAST_STAG',
                    'VMS_PROD_BIN_STAG',
                    'VMS_PROD_THRESHOLD_STAG',
                    'VMS_PRODUCT_PARAM_STAG',
                    'VMS_PROD_CARDPACK_STAG',
                    'VMS_PACKAGEID_MAST_STAG',
                    'VMS_PACKAGEID_DETL_STAG',
                    'VMS_PRODNETWORKID_MAPPING_STAG',
                    'VMS_SCORECARD_PRODMAPPING_STAG',
                    'VMS_DFG_PARAM_STAG',
                    'VMS_EMBOSS_FILE_FORMAT_STAG',
                    'VMS_BLACKLIST_SOURCES_STAG',
                    'VMS_COMPANY_NAME_STAG',
                    'VMS_PROD_CATTYPE_STAG',
                    'VMS_PROD_CATSEC_STAG',
                    'VMS_PRODCAT_CARDPACK_STAG',
                    'VMS_FEEPLAN_DTLS_STAG',
                    'VMS_FEE_FEEPLAN_STAG',
                    'VMS_FEE_MAST_STAG',
                    'VMS_LMTPRFL_DTLS_STAG',
                    'VMS_LIMIT_PRFL_STAG',
                    'VMS_GROUP_LIMIT_STAG',
                    'VMS_GRPLMT_PARAM_STAG',
                    'VMS_PRODCAT_THRESHOLD_STAG',
                    'VMS_PRODCAT_DENO_MAST_STAG',
                    'VMS_PRODCAT_NETWORKID_MAP_STAG',
                    'VMS_SCORECARD_PRODCAT_MAP_STAG');

   --Start for xml
   l_xml_data := '<?xml version="1.0"?> <TABLES>';

   FOR i IN 1 .. l_tbl_list.COUNT
   LOOP
      BEGIN
         SELECT XMLELEMENT (
                   "TABLE",
                   XMLELEMENT (
                      EVALNAME ('' || l_tbl_list (i) || ''),
                      DBMS_XMLGEN.GETXMLTYPE (
                         '' || 'SELECT * FROM ' || l_tbl_list (i) || '')))
           INTO l_xmldata
           FROM DUAL;
      EXCEPTION
         WHEN OTHERS
         THEN
            p_respmsg_out :=
               'Error while generating xml:' || SUBSTR (SQLERRM, 1, 200);
            RETURN;
      END;

      l_xml_data := l_xml_data || l_xmldata.getClobVal;
   END LOOP;

   p_xmldata_out := XMLTYPE.createxml (l_xml_data ||  '</TABLES>');
--End for xml
EXCEPTION
   WHEN OTHERS
   THEN
      p_respmsg_out := 'Main Excp:' || SUBSTR (SQLERRM, 1, 200);
END tbl_to_xml;

PROCEDURE xml_to_tbl (p_prod_code_out OUT VARCHAR2, p_respmsg_out   OUT VARCHAR2)
/**************************************************************************************************
 
   * Modified by      : Narayana
   * Modified For     : VMS-1048 (VMS Host Configure new product in Dev A to replicate to other lower environments)
   * Modified Date    : 13-AUG-2019
   * Reviewer         : Saravanakumar
   * Build Number     : R19_B0002  

**************************************************************************************************/
AS
   l_xmldata    XMLTYPE;
   l_str        VARCHAR2 (32767);
   l_chk_data   PLS_INTEGER;

   TYPE typ_tbl_list IS VARRAY (35) OF VARCHAR2 (35);

   l_tbl_list   typ_tbl_list;
BEGIN
p_respmsg_out:='OK';
SELECT vcx_xml_data INTO l_xmldata FROM vms_copyprod_xml;

   l_tbl_list :=
      typ_tbl_list ('VMS_PRODCATG_COPY_INFO',
                    'VMS_PROFILE_MAST_STAG',
                    'VMS_PAN_CONSTRUCT_STAG',
                    'VMS_ACCT_CONSTRUCT_STAG',
                    'VMS_SAVINGSACCT_CONSTRUCT_STAG',
                    'VMS_BIN_PARAM_STAG',
                    'VMS_PROD_MAST_STAG',
                    'VMS_PROD_BIN_STAG',
                    'VMS_PROD_THRESHOLD_STAG',
                    'VMS_PRODUCT_PARAM_STAG',
                    'VMS_PROD_CARDPACK_STAG',
                    'VMS_PACKAGEID_MAST_STAG',
                    'VMS_PACKAGEID_DETL_STAG',
                    'VMS_PRODNETWORKID_MAPPING_STAG',
                    'VMS_SCORECARD_PRODMAPPING_STAG',
                    'VMS_DFG_PARAM_STAG',
                    'VMS_EMBOSS_FILE_FORMAT_STAG',
                    'VMS_BLACKLIST_SOURCES_STAG',
                    'VMS_COMPANY_NAME_STAG',
                    'VMS_PROD_CATTYPE_STAG',
                    'VMS_PROD_CATSEC_STAG',
                    'VMS_PRODCAT_CARDPACK_STAG',
                    'VMS_FEEPLAN_DTLS_STAG',
                    'VMS_FEE_FEEPLAN_STAG',
                    'VMS_FEE_MAST_STAG',
                    'VMS_LMTPRFL_DTLS_STAG',
                    'VMS_LIMIT_PRFL_STAG',
                    'VMS_GROUP_LIMIT_STAG',
                    'VMS_GRPLMT_PARAM_STAG',
                    'VMS_PRODCAT_THRESHOLD_STAG',
                    'VMS_PRODCAT_DENO_MAST_STAG',
                    'VMS_PRODCAT_NETWORKID_MAP_STAG',
                    'VMS_SCORECARD_PRODCAT_MAP_STAG');

   FOR i IN 1 .. l_tbl_list.COUNT
   LOOP
      BEGIN
         EXECUTE IMMEDIATE
               'SELECT count(*) FROM table (xmlsequence (extract (:1,'
            || ''''
            || 'TABLES/TABLE/'
            || l_tbl_list (i)
            || '/ROWSET/ROW'
            || ''''
            || ')))'
            INTO l_chk_data
            USING l_xmldata;

         IF l_chk_data = 0
         THEN
            CONTINUE;
         END IF;
      EXCEPTION
         WHEN OTHERS
         THEN
            p_respmsg_out :=
               'Error while checking count:' || SUBSTR (SQLERRM, 1, 200);
            RETURN;
      END;

      l_str := ' INSERT INTO ' || l_tbl_list (i) || ' SELECT ';

      FOR j IN (  SELECT column_id, column_name
                    FROM cols
                   WHERE table_name = l_tbl_list (i)
                ORDER BY column_id)
      LOOP
         IF j.column_id > 1
         THEN
            l_str := l_str || ',';
         END IF;

         l_str :=
               l_str
            || ' extractvalue (value (p),'
            || ''''
            || 'ROW/'
            || j.column_name
            || '/text()'
            || ''''
            || ') as '
            || j.column_name;
      END LOOP;

      l_str :=
            l_str
         || ' FROM table (xmlsequence (extract (:1,'
         || ''''
         || 'TABLES/TABLE/'
         || l_tbl_list (i)
         || '/ROWSET/ROW'
         || ''''
         || '))) p';

      BEGIN
         --dbms_output.put_line( l_str);
         EXECUTE IMMEDIATE l_str USING l_xmldata;
      EXCEPTION
         WHEN OTHERS
         THEN
            ROLLBACK;
            p_respmsg_out :=
                  'Error occured during data insertion for table'
               || l_tbl_list (i)
               || ':'
               || SUBSTR (SQLERRM, 1, 200);
            RETURN;
      END;
   END LOOP;

    BEGIN
       SELECT vpm_prod_code INTO p_prod_code_out FROM VMS_PROD_MAST_STAG;
    EXCEPTION
       WHEN OTHERS
       THEN
          p_respmsg_out :='Error while selcting prod code:' || SUBSTR (SQLERRM, 1, 200);
    END;

EXCEPTION
   WHEN OTHERS
   THEN
      p_respmsg_out := 'Main Excp:' || SUBSTR (SQLERRM, 1, 400);
END xml_to_tbl;

PROCEDURE ROLLBACK_TRANSACTION_CONFIG(p_instcode_in            IN       NUMBER,
                                      p_audit_id               IN       VARCHAR2,
                                      p_ins_user_in            IN       NUMBER,
                                      p_errmsg_out             OUT      VARCHAR2
                                     )
IS

/**********************************************************************************************


  * Created by                  : Sivakumar M
  * Created Date                : 09-July-19
  * Created For                 : VMS-871 and VMS-887
  * Reviewer                    : SARAVANAKUMAR
  * Build Number                : R18

***********************************************************************************************/
  EXP_REJECT_RECORD   EXCEPTION;
  V_AUDIT_ID GPR_VALIDCARDSTAT_AUDIT.GVA_AUDIT_ID%TYPE;
  V_DATE              DATE;
  V_AUDIT_KEY   GPR_VALIDCARDSTAT_AUDIT.GVA_AUDIT_KEY%TYPE;
  V_PROD_CODE   GPR_VALIDCARDSTAT_AUDIT.GVA_PROD_CODE%TYPE; 
  V_CARD_TYPE   GPR_VALIDCARDSTAT_AUDIT.GVA_CARD_TYPE%TYPE;
  V_CONFIG_TYPE   GPR_VALIDCARDSTAT_AUDIT.GVA_CONFIG_TYPE%TYPE;
  V_MCC_ID      GPR_VALID_CARDSTAT.GVC_MCC_ID%TYPE;
BEGIN
p_errmsg_out := 'OK';

         BEGIN

                V_AUDIT_ID :=SEQ_CARDSTAT_AUDITID.NEXTVAL;
                V_DATE:=SYSDATE;
              EXCEPTION
              WHEN OTHERS THEN
                p_errmsg_out := 'Error While generating AUDIT ID'||SQLERRM;
                RAISE EXP_REJECT_RECORD;
          END;

for C in(SELECT  DISTINCT GVA_AUDIT_KEY,GVA_PROD_CODE,GVA_CARD_TYPE,GVA_STAT_FLAG,GVA_CARD_STAT,
               GVA_DELIVERY_CHANNEL,GVA_INT_IND,GVA_PINSIGN,GVA_MCC_ID FROM GPR_VALIDCARDSTAT_AUDIT 
                                            WHERE GVA_AUDIT_ID=p_audit_id)
  loop

 BEGIN
  INSERT
          INTO GPR_VALIDCARDSTAT_AUDIT
            ( GVA_SEQ_NO,
              GVA_AUDIT_ID,
              GVA_AUDIT_USER,
              GVA_AUDIT_KEY,
              GVA_AUDIT_DATE,
              GVA_RECORD_TYPE,
              GVA_INST_CODE,
              GVA_CARD_STAT,
              GVA_TRAN_CODE,
              GVA_INS_USER,
              GVA_INS_DATE,
              GVA_LUPD_DATE,
              GVA_LUPD_USER,
              GVA_DELIVERY_CHANNEL,
              GVA_MSG_TYPE,
              GVA_STAT_FLAG,
              GVA_PROD_CODE,
              GVA_CARD_TYPE,
              GVA_APPROVE_TXN,
              GVA_INT_IND,
              GVA_PINSIGN,
              GVA_MCC_ID,
              GVA_CONFIG_TYPE
            )
            ( SELECT SEQ_CARDSTAT_SEQNO.NEXTVAL,
              V_AUDIT_ID,
              p_ins_user_in,
              (GVC_PROD_CODE || '~' || GVC_CARD_TYPE || '~' || GVC_STAT_FLAG || '~' || GVC_CARD_STAT || '~' ||
               GVC_DELIVERY_CHANNEL || '~' || GVC_INT_IND || '~' || GVC_PINSIGN || '~' || (SELECT CMT_MCC_CODE from CMS_MCC_TRAN where CMT_MCC_ID = GVC_MCC_ID)),
              V_DATE,
              'O',
              GVC_INST_CODE,
              GVC_CARD_STAT,
              GVC_TRAN_CODE,
              GVC_INS_USER,
              GVC_INS_DATE,
              GVC_LUPD_DATE,
              GVC_LUPD_USER,
              GVC_DELIVERY_CHANNEL,
              GVC_MSG_TYPE,
              GVC_STAT_FLAG,
              GVC_PROD_CODE,
              GVC_CARD_TYPE,
              GVC_APPROVE_TXN,
              GVC_INT_IND,
              GVC_PINSIGN,
              (SELECT CMT_MCC_CODE from CMS_MCC_TRAN where CMT_MCC_ID = GVC_MCC_ID),
              'R' 
              FROM GPR_VALID_CARDSTAT
              WHERE 
              GVC_PROD_CODE = c.GVA_PROD_CODE AND 
              GVC_CARD_TYPE = c.GVA_CARD_TYPE AND 
              GVC_STAT_FLAG = c.GVA_STAT_FLAG AND 
              GVC_CARD_STAT = c.GVA_CARD_STAT AND 
              GVC_DELIVERY_CHANNEL = c.GVA_DELIVERY_CHANNEL AND 
              GVC_INT_IND = c.GVA_INT_IND AND 
              GVC_PINSIGN = c.GVA_PINSIGN AND 
              DECODE(GVC_MCC_ID,NULL,0,1) =DECODE(c.GVA_MCC_ID,NULL,0,1) AND
              GVC_INST_CODE   = p_instcode_in);
               
           /*   (GVC_PROD_CODE || '~' || GVC_CARD_TYPE || '~' || GVC_STAT_FLAG || '~' || GVC_CARD_STAT || '~' ||
               GVC_DELIVERY_CHANNEL || '~' || GVC_INT_IND || '~' || GVC_PINSIGN || '~' || 
               (SELECT CMT_MCC_CODE from CMS_MCC_TRAN where CMT_MCC_ID = GVC_MCC_ID))=c.GVA_AUDIT_KEY
                AND GVC_INST_CODE   = p_instcode_in);*/

        EXCEPTION
        WHEN OTHERS THEN
          p_errmsg_out := 'Error on copy card status from GPR_VALID_CARDSTAT to GPR_VALID_CARDSTAT table'||SQLERRM;
          RAISE EXP_REJECT_RECORD;
        END;


   BEGIN
      --Deleting existing 'to product category' records
        DELETE
        FROM CMS_MCC_TRAN
        WHERE cmt_mcc_id IN
          (SELECT gvc_mcc_id
          FROM GPR_VALID_CARDSTAT
          WHERE GVC_PROD_CODE = c.GVA_PROD_CODE AND 
              GVC_CARD_TYPE = c.GVA_CARD_TYPE AND 
              GVC_STAT_FLAG = c.GVA_STAT_FLAG AND 
              GVC_CARD_STAT = c.GVA_CARD_STAT AND 
              GVC_DELIVERY_CHANNEL = c.GVA_DELIVERY_CHANNEL AND 
              GVC_INT_IND = c.GVA_INT_IND AND 
              GVC_PINSIGN = c.GVA_PINSIGN AND 
              DECODE(GVC_MCC_ID,NULL,0,1) =DECODE(c.GVA_MCC_ID,NULL,0,1) AND
              GVC_INST_CODE   = p_instcode_in);
      EXCEPTION
      WHEN OTHERS THEN
        p_errmsg_out := 'Error on Delete CMS_MCC_TRAN:'||SQLERRM;
        RAISE EXP_REJECT_RECORD;
      END;

      BEGIN
       --Deleting existing 'to product category' records
        DELETE
        FROM GPR_VALID_CARDSTAT
        WHERE GVC_PROD_CODE = c.GVA_PROD_CODE AND 
              GVC_CARD_TYPE = c.GVA_CARD_TYPE AND 
              GVC_STAT_FLAG = c.GVA_STAT_FLAG AND 
              GVC_CARD_STAT = c.GVA_CARD_STAT AND 
              GVC_DELIVERY_CHANNEL = c.GVA_DELIVERY_CHANNEL AND 
              GVC_INT_IND = c.GVA_INT_IND AND 
              GVC_PINSIGN = c.GVA_PINSIGN AND 
              DECODE(GVC_MCC_ID,NULL,0,1) =DECODE(c.GVA_MCC_ID,NULL,0,1) AND
              GVC_INST_CODE   = p_instcode_in;
      EXCEPTION
      WHEN OTHERS THEN
        p_errmsg_out := 'Error on Delete GPR_VALID_CARDSTAT:'||SQLERRM;
        RAISE EXP_REJECT_RECORD;
      END;

   FOR C1 IN
      (SELECT GVA_INST_CODE,
        GVA_CARD_STAT,
        GVA_TRAN_CODE,
        GVA_INS_USER,
        SYSDATE GVA_INS_DATE,
        SYSDATE GVA_LUPD_DATE,
        GVA_LUPD_USER,
        GVA_DELIVERY_CHANNEL,
        GVA_MSG_TYPE,
        GVA_STAT_FLAG,
        GVA_PROD_CODE,
        GVA_CARD_TYPE,
        GVA_APPROVE_TXN,
        GVA_INT_IND,
        GVA_PINSIGN,
        GVA_MCC_ID
      FROM GPR_VALIDCARDSTAT_AUDIT
      WHERE GVA_AUDIT_KEY=c.GVA_AUDIT_KEY
      and GVA_AUDIT_ID=p_audit_id
      and gva_record_type='O'
      AND GVa_INST_CODE   = p_instcode_in)
      LOOP
      
      
        IF c1.GVA_MCC_ID IS NOT NULL THEN
        --generating mcc id
          BEGIN
            V_MCC_ID :=SEQ_MCC_ID.NEXTVAL;
          EXCEPTION
          WHEN OTHERS THEN
            p_errmsg_out := 'Error While generating MCC ID'||SQLERRM;
            RAISE EXP_REJECT_RECORD;
          END;
        ELSE
          V_MCC_ID :=NULL;
        END IF;

        BEGIN
        --Creating new records for 'to product category'
          INSERT
          INTO GPR_VALID_CARDSTAT
            ( GVC_INST_CODE,
              GVC_CARD_STAT,
              GVC_TRAN_CODE,
              GVC_INS_USER,
              GVC_INS_DATE,
              GVC_LUPD_DATE,
              GVC_LUPD_USER,
              GVC_DELIVERY_CHANNEL,
              GVC_MSG_TYPE,
              GVC_STAT_FLAG,
              GVC_PROD_CODE,
              GVC_CARD_TYPE,
              GVC_APPROVE_TXN,
              GVC_INT_IND,
              GVC_PINSIGN,
              GVC_MCC_ID)
            VALUES
            (C1.GVA_INST_CODE,
              C1.GVA_CARD_STAT,
              C1.GVA_TRAN_CODE,
              p_ins_user_in,
              C1.GVA_INS_DATE,
              C1.GVA_LUPD_DATE,
              p_ins_user_in,
              C1.GVA_DELIVERY_CHANNEL,
              C1.GVA_MSG_TYPE,
              C1.GVA_STAT_FLAG,
              C1.GVA_PROD_CODE,
              C1.GVA_CARD_TYPE,
              C1.GVA_APPROVE_TXN,
              C1.GVA_INT_IND,
              C1.GVA_PINSIGN,
              V_MCC_ID);
        EXCEPTION
        WHEN OTHERS THEN
          p_errmsg_out := 'Error on copy card status from product to product'||C1.GVA_MCC_ID||SQLERRM;
          RAISE EXP_REJECT_RECORD;
        END;

  BEGIN
          IF V_MCC_ID IS NOT NULL THEN
          --Creating new records for 'to product category' mcc id
            INSERT
            INTO CMS_MCC_TRAN
              ( CMT_INST_CODE,
                CMT_MCC_ID,
                CMT_MCC_CODE,
                CMT_INS_USER,
                CMT_LUPD_USER,
                CMT_INS_DATE,
                CMT_LUPD_DATE)
              VALUES
              (C1.GVA_INST_CODE,
               V_MCC_ID,
               C1.GVA_MCC_ID,
               C1.GVA_INS_USER,
               C1.GVA_LUPD_USER,
               SYSDATE,
               SYSDATE);
          END IF;
        EXCEPTION
        WHEN OTHERS THEN
          p_errmsg_out := 'Error While inserting MCC Data'||SQLERRM;
          RAISE EXP_REJECT_RECORD;
        END;

        BEGIN
        --Copying Existing Records of 'to product category' from GPR_VALID_CARDSTAT to GPR_VALIDCARDSTAT_AUDIT table
          INSERT
          INTO GPR_VALIDCARDSTAT_AUDIT
            ( GVA_SEQ_NO,
              GVA_AUDIT_ID,
              GVA_AUDIT_USER,
              GVA_AUDIT_KEY,
              GVA_AUDIT_DATE,
              GVA_RECORD_TYPE,
              GVA_INST_CODE,
              GVA_CARD_STAT,
              GVA_TRAN_CODE,
              GVA_INS_USER,
              GVA_INS_DATE,
              GVA_LUPD_DATE,
              GVA_LUPD_USER,
              GVA_DELIVERY_CHANNEL,
              GVA_MSG_TYPE,
              GVA_STAT_FLAG,
              GVA_PROD_CODE,
              GVA_CARD_TYPE,
              GVA_APPROVE_TXN,
              GVA_INT_IND,
              GVA_PINSIGN,
              GVA_MCC_ID,
              GVA_CONFIG_TYPE
            )
            VALUES
            (SEQ_CARDSTAT_SEQNO.NEXTVAL,
              V_AUDIT_ID,
              p_ins_user_in,
              (C1.GVA_PROD_CODE || '~' || C1.GVA_CARD_TYPE || '~' || c1.GVA_STAT_FLAG || '~' || c1.GVA_CARD_STAT || '~' ||
               c1.GVA_DELIVERY_CHANNEL || '~' || c1.GVA_INT_IND || '~' || c1.GVA_PINSIGN || '~' || (SELECT CMT_MCC_CODE from CMS_MCC_TRAN 
               where CMT_MCC_ID = V_MCC_ID)),
               V_DATE,
               'N',
              c1.GVA_INST_CODE,
              c1.GVA_CARD_STAT,
              c1.GVA_TRAN_CODE,
              c1.GVA_INS_USER,
              c1.GVA_INS_DATE,
              c1.GVA_LUPD_DATE,
              c1.GVA_LUPD_USER,
              c1.GVA_DELIVERY_CHANNEL,
              c1.GVA_MSG_TYPE,
              c1.GVA_STAT_FLAG,
              c1.GVA_PROD_CODE,
              c1.GVA_CARD_TYPE,
              c1.GVA_APPROVE_TXN,
              c1.GVA_INT_IND,
              c1.GVA_PINSIGN,
              c1.GVA_MCC_ID,
              'R'
            );
        EXCEPTION
        WHEN OTHERS THEN
          p_errmsg_out := 'Error on copy card status from GPR_VALID_CARDSTAT to GPR_VALIDCARDSTAT_AUDIT table'||SQLERRM;
          RAISE EXP_REJECT_RECORD;
        END;
      END LOOP;
 end loop;
EXCEPTION
  WHEN EXP_REJECT_RECORD THEN
  --p_errmsg_out := 'EXP_REJECT_RECORD';
  ROLLBACK;
 WHEN OTHERS
   THEN 
    p_errmsg_out := 'Main Excp:' || SUBSTR (SQLERRM, 1, 400);
          
      
END ROLLBACK_TRANSACTION_CONFIG;


END VMSPRODUCT;
/
show error