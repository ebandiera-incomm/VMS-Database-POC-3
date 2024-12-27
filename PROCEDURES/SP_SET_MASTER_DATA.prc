CREATE OR REPLACE PROCEDURE VMSCMS."SP_SET_MASTER_DATA"
  (
    prm_instcode         IN NUMBER,
    prm_instname         IN VARCHAR2,
    prm_superuser        IN NUMBER,
    prm_defcurrency_code IN VARCHAR2,
    prm_defcntry_name    IN VARCHAR2,
    prm_defstate_name    IN VARCHAR2,
    prm_switch_stat_name IN VARCHAR2,
    prm_defcity_name     IN VARCHAR2,
    prm_group_name       IN VARCHAR2,
    prm_brancode         IN VARCHAR2,
    prm_fiid             IN VARCHAR2,
    prm_micrno           IN VARCHAR2,
    prm_branloc          IN VARCHAR2,
    prm_addr1            IN VARCHAR2,
    prm_pincode          IN NUMBER,
    prm_phone1           IN VARCHAR2,
    prm_contprsn         IN VARCHAR2,
    prm_bran_cntct_email IN VARCHAR2,
    --prm_brancatg  IN VARCHAR2,
    --prm_brantype  IN VARCHAR2,
    --prm_saletrans  IN VARCHAR2,
    --prm_group_name  IN VARCHAR2,
    prm_usercode IN VARCHAR2,
    prm_username IN VARCHAR2,
    prm_errmsg OUT VARCHAR2 )
AS
  v_cntry_code NUMBER(3);
  v_state_code NUMBER(3);
  v_catg_code  VARCHAR2(5);
  v_city_code  NUMBER(5,0);
  groupcode    NUMBER;
BEGIN
  prm_errmsg:='OK';
  --Sn create inst type
  BEGIN
    INSERT INTO CMS_INST_TYPE
    SELECT cit_type_code,
      cit_type_desc,
      prm_superuser,
      SYSDATE, --2 is superuser
      prm_superuser,
      SYSDATE,
      prm_instcode
    FROM CMS_INST_TYPE
    WHERE cit_inst_code =1;
  EXCEPTION
  WHEN OTHERS THEN
    prm_errmsg := 'Error while inserting data into CMS_INST_TYPE ' || SUBSTR(sqlerrm,1,200);
    RETURN;
  END;
  --Sn create a record in currency mast
  BEGIN
    INSERT INTO GEN_CURR_MAST
    SELECT GCM_CURR_CODE ,
      GCM_CURR_NAME ,
      GCM_CURR_DESC ,
      GCM_BUYING_RATE ,
      GCM_SELLING_RATE ,
      prm_superuser ,
      SYSDATE ,
      prm_instcode ,
      SYSDATE ,
      prm_superuser
    FROM GEN_CURR_MAST
    WHERE GCM_INST_CODE =1;
  EXCEPTION
  WHEN OTHERS THEN
    prm_errmsg := 'Error while inserting data into GEN CURR MAST ' || SUBSTR(sqlerrm,1,200);
    RETURN;
  END;
  --En create a record into currency mast
  --Sn create institute mast
  BEGIN
    INSERT INTO CMS_INST_MAST
    SELECT prm_instcode,
      prm_instname,
      cim_pan_offset,
      cim_pan_length,
      cim_pad_char,
      cim_deci_value,
      cim_pvt_key,
      cim_pin_length,
      cim_pan_vrfy,
      prm_superuser,
      SYSDATE,
      prm_superuser,
      SYSDATE,
      cim_card_vv1,
      cim_card_vv2,
      cim_mbr_numb,
      CIM_INST_SHORTNAME
    FROM CMS_INST_MAST
    WHERE CIM_INST_CODE = 1;
  EXCEPTION
  WHEN OTHERS THEN
    prm_errmsg := 'Error while inserting data into CMS_INST_MAST ' || SUBSTR(sqlerrm,1,200);
    RETURN;
  END;
  --Sn create record in inst param
  BEGIN
    INSERT
    INTO cms_inst_param
      (
        CIP_INST_CODE,
        CIP_PARAM_KEY,
        CIP_PARAM_VALUE,
        CIP_PARAM_DESC,
        CIP_INS_USER,
        CIP_INS_DATE,
        CIP_LUPD_USER,
        CIP_LUPD_DATE,
        CIP_ALLOWED_VALUES,
        CIP_MANDATORY_FLAG,
        CIP_DISPLAY_FLAG,
        CIP_PARAM_UNIT,
        CIP_PARAM_DISP_TYPE,
        CIP_MULTILING_DESC,
        CIP_VALIDATION_TYPE
      )
    SELECT prm_instcode,
      CIP_PARAM_KEY,
      CIP_PARAM_VALUE,
      CIP_PARAM_DESC,
      prm_superuser,
      SYSDATE,
      prm_superuser,
      SYSDATE,
      CIP_ALLOWED_VALUES,
      CIP_MANDATORY_FLAG,
      CIP_DISPLAY_FLAG,
      CIP_PARAM_UNIT,
      CIP_PARAM_DISP_TYPE,
      CIP_MULTILING_DESC,
      CIP_VALIDATION_TYPE
    FROM cms_inst_param
    WHERE cip_inst_code    =1
    AND cip_param_key NOT IN ('PSWD CHANGE','WRONG PSWDS','NEW PSWD') ;
  EXCEPTION
  WHEN OTHERS THEN
    prm_errmsg := 'Error while inserting data into CMS_INST_PARAM ' || SUBSTR(sqlerrm,1,200);
    RETURN;
  END;
  --En create record in inst param
  --Sn create records in gen mast
  BEGIN
    INSERT
    INTO cms_genaudit_mast
      (
        CGM_TABLE_ID,
        CGM_INST_CODE,
        CGM_TABLE_NAME,
        CGM_TABLE_ALIAS,
        CGM_INS_USER,
        CGM_INS_DATE,
        CGM_LUPD_USER,
        CGM_LUPD_DATE
      )
    SELECT CGM_TABLE_ID,
      prm_instcode,
      CGM_TABLE_NAME,
      CGM_TABLE_ALIAS,
      prm_superuser,
      CGM_INS_DATE,
      prm_superuser,
      CGM_LUPD_DATE
    FROM cms_genaudit_mast
    WHERE cgm_inst_code=1;
  EXCEPTION
  WHEN OTHERS THEN
    prm_errmsg := 'Error while inserting data into cms_genaudit_mast ' || SUBSTR(sqlerrm,1,200);
    RETURN;
  END;
  --En create reocrds in gen mast
  --Sn create reocrds in gen audit table
  BEGIN
    INSERT
    INTO cms_genaudit_table
      (
        CGT_INST_CODE,
        CGT_TABLE_ID,
        CGT_COLUMN_NAME,
        CGT_COLUMN_ALIAS,
        CGT_COLUMN_FLAG,
        CGT_INS_USER,
        CGT_INS_DATE,
        CGT_LUPD_USER,
        CGT_LUPD_DATE,
        CGT_MASTER_TABLE,
        CGT_MASTER_COLUMN,
        CGT_MASTER_COMPARE,
        CGT_MASTER_COMPARE1
      )
    SELECT prm_instcode,
      CGT_TABLE_ID,
      CGT_COLUMN_NAME,
      CGT_COLUMN_ALIAS,
      CGT_COLUMN_FLAG,
      prm_superuser,
      SYSDATE,
      prm_superuser,
      SYSDATE,
      CGT_MASTER_TABLE,
      CGT_MASTER_COLUMN,
      CGT_MASTER_COMPARE,
      CGT_MASTER_COMPARE1
    FROM cms_genaudit_table
    WHERE cgt_inst_code=1;
  EXCEPTION
  WHEN OTHERS THEN
    prm_errmsg := 'Error while inserting data into cms_genaudit_table ' || SUBSTR(sqlerrm,1,200);
    RETURN;
  END;
  --En create records in gen audit
  --SN GET CNTRY CODE
  SELECT MAX(GCM_CNTRY_CODE) + 1
  INTO v_cntry_code
  FROM GEN_CNTRY_MAST
  WHERE gcm_inst_code = prm_instcode;
  IF v_cntry_code    IS NULL THEN
    v_cntry_code     := 1;
  END IF;
  --sN CHECK CNTRY CODE
  BEGIN
    INSERT
    INTO GEN_CNTRY_MAST
      (
        GCM_CNTRY_CODE,
        GCM_CURR_CODE,
        GCM_CNTRY_NAME,
        GCM_LUPD_USER,
        GCM_LUPD_DATE,
        GCM_INST_CODE,
        GCM_INS_DATE,
        GCM_INS_USER
      )
      VALUES
      (
        v_cntry_code,
        prm_defcurrency_code,
        prm_defcntry_name,
        prm_superuser,
        SYSDATE,
        prm_instcode,
        SYSDATE,
        prm_superuser
      );
  EXCEPTION
  WHEN OTHERS THEN
    prm_errmsg := 'Error while inserting data into GEN_CNTRY_MAST ' || SUBSTR
    (
      sqlerrm,1,200
    )
    ;
    RETURN;
  END;
  --sN CREATE STATE CODE
  SELECT MAX(gsm_state_code)+1
  INTO v_state_code
  FROM GEN_STATE_MAST
  WHERE gsm_inst_code=prm_instcode
  AND gsm_cntry_code = v_cntry_code;
  IF v_state_code   IS NULL THEN
    v_state_code    :=1;
  END IF;
  BEGIN
    INSERT
    INTO GEN_STATE_MAST
      (
        GSM_INST_CODE,
        GSM_CNTRY_CODE,
        GSM_STATE_CODE,
        GSM_STATE_NAME,
        GSM_LUPD_USER,
        GSM_LUPD_DATE,
        GSM_INS_USER,
        GSM_INS_DATE,
        GSM_SWITCH_STATE_CODE
      )
      VALUES
      (
        prm_instcode,
        v_cntry_code,
        v_state_code,
        prm_defstate_name,
        prm_superuser,
        SYSDATE,
        prm_superuser,
        SYSDATE,
        prm_switch_stat_name
      );
  EXCEPTION
  WHEN OTHERS THEN
    prm_errmsg := 'Error while inserting data into GEN_STATE_MAST ' || SUBSTR
    (
      sqlerrm,1,200
    )
    ;
    RETURN;
  END;
  --sN CREATE CITY CODE
  SELECT MAX(gcm_city_code)+1
  INTO v_city_code
  FROM GEN_CITY_MAST
  WHERE gcm_inst_code= prm_instcode
  AND gcm_cntry_code = v_cntry_code
  AND gcm_state_code = v_state_code;
  IF v_city_code    IS NULL THEN
    v_city_code     :=1;
  END IF;
  BEGIN
    INSERT
    INTO GEN_CITY_MAST
      (
        GCM_INST_CODE,
        GCM_CNTRY_CODE,
        GCM_CITY_CODE,
        GCM_STATE_CODE,
        GCM_CITY_NAME,
        GCM_LUPD_USER,
        GCM_LUPD_DATE,
        GCM_INS_USER,
        GCM_INS_DATE
      )
      VALUES
      (
        prm_instcode,
        v_cntry_code,
        v_city_code,
        v_state_code,
        prm_defcity_name,
        prm_superuser,
        SYSDATE,
        prm_superuser,
        SYSDATE
      );
  EXCEPTION
  WHEN OTHERS THEN
    prm_errmsg := 'Error while inserting data into GEN_CITY_MAST ' || SUBSTR
    (
      sqlerrm,1,200
    )
    ;
    RETURN;
  END;
  --En CREATE CITY CODE
  --Sn btran catg
  BEGIN
    INSERT
    INTO CMS_BRANCH_CATG
      (
        CBC_INST_CODE,
        CBC_CATG_CODE,
        CBC_CATG_DESC,
        CBC_LUPD_DATE,
        CBC_LUPD_USER,
        CBC_INS_DATE,
        CBC_INS_USER,
        CBC_CATG_FOR_PROD
      )
    SELECT prm_instcode,
      CBC_CATG_CODE,
      CBC_CATG_DESC,
      SYSDATE,
      prm_superuser,
      SYSDATE,
      prm_superuser,
      CBC_CATG_FOR_PROD
    FROM cms_branch_catg
    WHERE CBC_INST_CODE=1;
  EXCEPTION
  WHEN OTHERS THEN
    prm_errmsg := 'Error while inserting data into CMS_BRANCH_CATG ' || SUBSTR(sqlerrm,1,200);
    RETURN;
  END;
  --Sn bran type
  BEGIN
    INSERT
    INTO CMS_BRANCH_TYPE
      (
        CBT_INST_CODE,
        CBT_TYPE_CODE,
        CBT_CATG_CODE,
        CBT_TYPE_DESC,
        CBT_REPORTING_BRAN,
        CBT_INS_USER,
        CBT_INS_DATE,
        CBT_LUPD_USER,
        CBT_LUPD_DATE
      )
    SELECT prm_instcode,
      CBT_TYPE_CODE,
      CBT_CATG_CODE,
      CBT_TYPE_DESC,
      CBT_REPORTING_BRAN,
      prm_superuser,
      SYSDATE,
      prm_superuser,
      SYSDATE
    FROM CMS_BRANCH_TYPE
    WHERE CBT_INST_CODE=1;
  EXCEPTION
  WHEN OTHERS THEN
    prm_errmsg := 'Error while inserting data into CMS_BRANCH_TYPE ' || SUBSTR(sqlerrm,1,200);
    RETURN;
  END;
  --En bran type
  --Sn create default branch
  BEGIN
    sp_create_branch( prm_instcode, v_cntry_code , v_state_code, v_city_code , prm_brancode, prm_fiid, prm_micrno, prm_branloc, prm_addr1, NULL, NULL, prm_pincode, prm_phone1, NULL, NULL , prm_contprsn, NULL , prm_bran_cntct_email, '1', '2', NULL, NULL, NULL, NULL, NULL, NULL, NULL, 1, NULL, prm_superuser, prm_errmsg );
    IF prm_errmsg<>'OK' THEN
      prm_errmsg :='Error occurs while creating branch'||SUBSTR(sqlerrm,1,200);
      RETURN;
    END IF;
  END;
  --En create default branch
  --Sn default usergroup
  BEGIN
    SELECT cct_ctrl_numb
    INTO groupcode
    FROM CMS_CTRL_TABLE
    WHERE cct_ctrl_code = TO_CHAR(prm_instcode)
    AND cct_ctrl_key    = 'USERGROUP CODE'
    AND cct_inst_code   = prm_instcode FOR UPDATE;
  EXCEPTION
  WHEN no_data_found THEN
    groupcode:=1;
    INSERT
    INTO cms_ctrl_table
      (
        CCT_CTRL_CODE,
        CCT_CTRL_KEY,
        CCT_CTRL_NUMB,
        CCT_CTRL_DESC,
        CCT_INS_USER,
        CCT_INS_DATE,
        CCT_LUPD_USER,
        CCT_LUPD_DATE,
        CCT_INST_CODE
      )
      VALUES
      (
        prm_instcode,
        'USERGROUP CODE',
        1,
        'Latest user group code for institution '
        ||prm_instcode,
        1,
        SYSDATE,
        prm_superuser,
        SYSDATE,
        prm_instcode
      );
  END;
  BEGIN
    sp_create_usergroup
    (
      prm_instcode, prm_group_name, 'Y', prm_superuser, prm_errmsg
    )
    ;
    IF prm_errmsg <>'OK' THEN
      prm_errmsg  :='Error While creating user groups'||SUBSTR
      (
        sqlerrm,1,200
      )
      ;
      RETURN;
    END IF;
  END;
  --En default usergroup
  --Sn default user
  BEGIN
    SP_CREATE_USER
    (
      prm_instcode, prm_usercode, 'e5Aub/Hbn1YEQ/IEiXT9fThpdbA=', --default password is admin123
      prm_username, prm_brancode, SYSDATE, add_months(sysdate,12), 'N', '0', NULL, NULL, NULL, 'Y', prm_superuser, prm_errmsg
    )
    ;
    IF prm_errmsg <>'OK' THEN
      prm_errmsg  :='Error while creating user '||SUBSTR
      (
        sqlerrm,1,200
      )
      ;
      RETURN;
    END IF;
  END;
  --En default user
  --Sn default usergroup reln
  BEGIN
    INSERT
    INTO CMS_USER_GROUPMAST
      (
        CUG_INST_CODE,
        CUG_GROUP_CODE,
        CUG_USER_CODE,
        CUG_USER_STAT,
        CUG_INS_USER,
        CUG_INS_DATE,
        CUG_LUPD_USER,
        CUG_LUPD_DATE
      )
      VALUES
      (
        prm_instcode,
        groupcode,
        prm_usercode,
        'Y',
        prm_superuser,
        SYSDATE,
        prm_superuser,
        SYSDATE
      );
    IF sql%rowcount = 0 THEN
      prm_errmsg   := 'User group reln is not attached';
      RETURN;
    END IF;
  EXCEPTION
  WHEN OTHERS THEN
    prm_errmsg:='Error while inserting record in CMS_USER_GROUPMAST '||SUBSTR
    (
      SQLERRM,1,200
    )
    ;
    RETURN;
  END;
  --En default usergroup reln
  BEGIN
    INSERT
    INTO cms_func_mast
      (
        CFM_INST_CODE,
        CFM_FUNC_CODE,
        CFM_FUNC_DESC,
        CFM_INST_DATE,
        CFM_LUPD_USER,
        CFM_LUPD_DATE,
        CFM_SCREEN_CODE,
        CFM_ONLINE_OFFLINE_FLAG,
        CFM_TXN_CODE,
        CFM_TXN_MODE,
        CFM_DELIVERY_CHANNEL,
        CFM_TXN_TYPE,
        CFM_INS_USER
      )
    SELECT prm_instcode,
      CFM_FUNC_CODE,
      CFM_FUNC_DESC,
      SYSDATE,
      prm_superuser,
      SYSDATE,
      CFM_SCREEN_CODE,
      CFM_ONLINE_OFFLINE_FLAG,
      CFM_TXN_CODE,
      CFM_TXN_MODE,
      CFM_DELIVERY_CHANNEL,
      CFM_TXN_TYPE,
      prm_superuser
    FROM cms_func_mast
    WHERE cfm_inst_code=1;
  EXCEPTION
  WHEN OTHERS THEN
    prm_errmsg := 'Error while inserting data into CMS_FUNC_MAST ' || SUBSTR(sqlerrm,1,200);
    RETURN;
  END;
  BEGIN
    INSERT
    INTO cms_prog_mast
      (
        CPM_INST_CODE,
        CPM_PROG_CODE,
        CPM_TAB_TYPE,
        CPM_MENU_LINK,
        CPM_PROG_NAME,
        CPM_MENU_PATH,
        CPM_MENU_DESC,
        CPM_PROG_ORDER,
        CPM_PROG_STAT,
        CPM_INS_USER,
        CPM_INS_DATE,
        CPM_LUPD_USER,
        CPM_LUPD_DATE,
        CPM_ADMIN_MENU
      )
    SELECT prm_instcode,
      CPM_PROG_CODE,
      CPM_TAB_TYPE,
      CPM_MENU_LINK,
      CPM_PROG_NAME,
      CPM_MENU_PATH,
      CPM_MENU_DESC,
      CPM_PROG_ORDER,
      CPM_PROG_STAT,
      prm_superuser,
      SYSDATE,
      prm_superuser,
      SYSDATE,
      CPM_ADMIN_MENU
    FROM cms_prog_mast
    WHERE CPM_INST_CODE=1;
  EXCEPTION
  WHEN OTHERS THEN
    prm_errmsg := 'Error while inserting data into CMS_PROG_MAST ' || SUBSTR(sqlerrm,1,200);
    RETURN;
  END;
  BEGIN
    INSERT
    INTO cms_group_prog
      (
        CGP_INST_CODE,
        CGP_GROUP_CODE,
        CGP_PROG_CODE,
        CGP_INSR_ALLOW,
        CGP_DELE_ALLOW,
        CGP_UPDT_ALLOW,
        CGP_INS_USER,
        CGP_INS_DATE,
        CGP_LUPD_USER,
        CGP_LUPD_DATE
      )
    SELECT prm_instcode,
      groupcode,
      CGP_PROG_CODE,
      CGP_INSR_ALLOW,
      CGP_DELE_ALLOW,
      CGP_UPDT_ALLOW,
      prm_superuser,
      SYSDATE,
      prm_superuser,
      SYSDATE
    FROM cms_prog_mast,
      cms_group_prog
    WHERE CPM_INST_CODE= CGP_INST_CODE
    AND CPM_PROG_CODE  = CGP_PROG_CODE
    AND CPM_INST_CODE  =1
    AND CGP_GROUP_CODE =21
    AND CPM_ADMIN_MENU ='Y';
  EXCEPTION
  WHEN OTHERS THEN
    prm_errmsg := 'Error while inserting data into CMS_GROUP_PROG ' || SUBSTR(sqlerrm,1,200);
    RETURN;
  END;
  BEGIN
    INSERT
    INTO cms_prod_catg
      (
        CPC_INST_CODE,
        CPC_CATG_CODE,
        CPC_CATG_APPL,
        CPC_CATG_NAME,
        CPC_INS_USER,
        CPC_INS_DATE,
        CPC_LUPD_USER,
        CPC_LUPD_DATE
      )
    SELECT prm_instcode,
      CPC_CATG_CODE,
      CPC_CATG_APPL,
      CPC_CATG_NAME,
      prm_superuser,
      SYSDATE,
      prm_superuser,
      SYSDATE
    FROM cms_prod_catg
    WHERE cpc_inst_code=1;
  EXCEPTION
  WHEN OTHERS THEN
    prm_errmsg := 'Error while inserting data into CMS_PROD_CATG ' || SUBSTR(sqlerrm,1,200);
    RETURN;
  END;
  BEGIN
    INSERT
    INTO cms_asso_mast
      (
        CAM_ASSO_CODE,
        CAM_ASSO_DESC,
        CAM_INS_USER,
        CAM_INS_DATE,
        CAM_LUPD_USER,
        CAM_LUPD_DATE,
        CAM_INST_CODE
      )
    SELECT CAM_ASSO_CODE,
      CAM_ASSO_DESC,
      prm_superuser,
      SYSDATE,
      prm_superuser,
      SYSDATE,
      prm_instcode
    FROM cms_asso_mast
    WHERE cam_inst_code=1;
  EXCEPTION
  WHEN OTHERS THEN
    prm_errmsg := 'Error while inserting data into CMS_ASSO_MAST ' || SUBSTR(sqlerrm,1,200);
    RETURN;
  END;
  INSERT
  INTO cms_cbd_rel
    (
      CCR_INST_CODE,
      CCR_ASSO_CODE,
      CCR_INST_TYPE,
      CCR_MAP_CODE,
      CCR_INST_STATUS,
      CCR_INS_USER,
      CCR_INS_DATE,
      CCR_LUPD_USER,
      CCR_LUPD_DATE
    )
  SELECT prm_instcode,
    CCR_ASSO_CODE,
    CCR_INST_TYPE,
    prm_instcode
    ||'_1_1',
    CCR_INST_STATUS,
    CCR_INS_USER,
    SYSDATE,
    CCR_LUPD_USER,
    SYSDATE
  FROM cms_cbd_rel
  WHERE CCR_INST_CODE=1;
  /*insert into cms_inst_type(
  CIT_TYPE_CODE,
  CIT_TYPE_DESC,
  CIT_INS_USER,
  CIT_INS_DATE,
  CIT_LUPD_USER,
  CIT_LUPD_DATE,
  CIT_INST_CODE
  )
  select  CIT_TYPE_CODE,
  CIT_TYPE_DESC,
  CIT_INS_USER,
  CIT_INS_DATE,
  CIT_LUPD_USER,
  CIT_LUPD_DATE,
  prm_instcode
  from cms_inst_type
  where cit_inst_code=1;*/
  BEGIN
    INSERT
    INTO cms_acct_stat
      (
        CAS_INST_CODE,
        CAS_STAT_CODE,
        CAS_STAT_DESC,
        CAS_SWITCH_STATCODE,
        CAS_INS_USER,
        CAS_INS_DATE,
        CAS_LUPD_USER,
        CAS_LUPD_DATE
      )
    SELECT prm_instcode,
      CAS_STAT_CODE,
      CAS_STAT_DESC,
      CAS_SWITCH_STATCODE,
      prm_superuser,
      SYSDATE,
      prm_superuser,
      SYSDATE
    FROM cms_acct_stat
    WHERE cas_inst_code=1;
  EXCEPTION
  WHEN OTHERS THEN
    prm_errmsg := 'Error while inserting data into CMS_ACCT_STAT ' || SUBSTR(sqlerrm,1,200);
    RETURN;
  END;
  BEGIN
    INSERT
    INTO cms_acct_type
      (
        CAT_INST_CODE,
        CAT_TYPE_CODE,
        CAT_TYPE_DESC,
        CAT_SWITCH_TYPE,
        CAT_INS_USER,
        CAT_INS_DATE,
        CAT_LUPD_USER,
        CAT_LUPD_DATE
      )
    SELECT prm_instcode,
      CAT_TYPE_CODE,
      CAT_TYPE_DESC,
      CAT_SWITCH_TYPE,
      prm_superuser,
      SYSDATE,
      prm_superuser,
      SYSDATE
    FROM cms_acct_type
    WHERE cat_inst_code=1;
  EXCEPTION
  WHEN OTHERS THEN
    prm_errmsg := 'Error while inserting data into CMS_ACCT_TYPE ' || SUBSTR(sqlerrm,1,200);
    RETURN;
  END;
  --  BEGIN
  --  insert into cms_cust_group(
  --                             CCG_INST_CODE,
  --                             CCG_GROUP_CODE,
  --                             CCG_GROUP_DESC,
  --                             CCG_INS_USER,
  --                             CCG_INS_DATE,
  --                             CCG_LUPD_USER,
  --                             CCG_LUPD_DATE
  --                            )
  --                      select prm_instcode,
  --                             CCG_GROUP_CODE,
  --                             CCG_GROUP_DESC,
  --                             prm_superuser,
  --                             SYSDATE,
  --                             prm_superuser,
  --                             SYSDATE
  --                             from cms_cust_group
  --                             where ccg_inst_code=1;
  --  EXCEPTION
  --      WHEN OTHERS THEN
  --      prm_errmsg := 'Error while inserting data into CMS_CUST_GROUP ' || substr(sqlerrm,1,200);
  --      return;
  --  END;
  BEGIN
    INSERT
    INTO cms_cust_type
      (
        CCT_INST_CODE,
        CCT_TYPE_CODE,
        CCT_TYPE_DESC,
        CCT_CUST_PROP,
        CCT_INS_USER,
        CCT_INS_DATE,
        CCT_LUPD_USER,
        CCT_LUPD_DATE
      )
    SELECT prm_instcode,
      CCT_TYPE_CODE,
      CCT_TYPE_DESC,
      CCT_CUST_PROP,
      prm_superuser,
      SYSDATE,
      prm_superuser,
      SYSDATE
    FROM cms_cust_type
    WHERE cct_inst_code=1;
  EXCEPTION
  WHEN OTHERS THEN
    prm_errmsg := 'Error while inserting data into CMS_CUST_TYPE ' || SUBSTR(sqlerrm,1,200);
    RETURN;
  END;
  /*insert into gen_cntry_mast(
  GCM_CNTRY_CODE,
  GCM_CURR_CODE,
  GCM_CNTRY_NAME,
  GCM_LUPD_USER,
  GCM_LUPD_DATE,
  GCM_INST_CODE,
  GCM_INS_DATE,
  GCM_INS_USER
  )
  select GCM_CNTRY_CODE,
  GCM_CURR_CODE,
  GCM_CNTRY_NAME,
  GCM_LUPD_USER,
  GCM_LUPD_DATE,
  prm_instcode,
  GCM_INS_DATE,
  GCM_INS_USER
  from gen_cntry_mast
  where gcm_inst_code=1;
  insert into gen_state_mast(
  GSM_CNTRY_CODE,
  GSM_STATE_CODE,
  GSM_STATE_NAME,
  GSM_LUPD_USER,
  GSM_LUPD_DATE,
  GSM_INST_CODE,
  GSM_INS_DATE,
  GSM_INS_USER,
  GSM_SWITCH_STATE_CODE
  )
  select GSM_CNTRY_CODE,
  GSM_STATE_CODE,
  GSM_STATE_NAME,
  GSM_LUPD_USER,
  GSM_LUPD_DATE,
  prm_instcode,
  GSM_INS_DATE,
  GSM_INS_USER,
  GSM_SWITCH_STATE_CODE
  from gen_state_mast
  where gsm_inst_code=1;
  /*insert into gen_city_mast(
  GCM_CNTRY_CODE,
  GCM_CITY_CODE,
  GCM_STATE_CODE,
  GCM_CITY_NAME,
  GCM_LUPD_USER,
  GCM_LUPD_DATE,
  GCM_INST_CODE,
  GCM_INS_DATE,
  GCM_INS_USER
  )
  select GCM_CNTRY_CODE,
  GCM_CITY_CODE,
  GCM_STATE_CODE,
  GCM_CITY_NAME,
  GCM_LUPD_USER,
  GCM_LUPD_DATE,
  prm_instcode,
  GCM_INS_DATE,
  GCM_INS_USER
  from gen_city_mast
  where gcm_inst_code=1;*/
  BEGIN
    INSERT
    INTO cms_acct_stat_b24
      (
        CAS_INST_CODE,
        CAS_ACCT_STAT,
        CAS_ACCT_STAT_B24,
        CAS_LUPD_DATE,
        CAS_LUPD_USER,
        CAS_INS_DATE,
        CAS_INS_USER
      )
    SELECT prm_instcode,
      CAS_ACCT_STAT,
      CAS_ACCT_STAT_B24,
      SYSDATE,
      prm_superuser,
      SYSDATE,
      prm_superuser
    FROM cms_acct_stat_b24
    WHERE cas_inst_code=1;
  EXCEPTION
  WHEN OTHERS THEN
    prm_errmsg := 'Error while inserting data into CMS_ACCT_STAT_B24 ' || SUBSTR(sqlerrm,1,200);
    RETURN;
  END;
  BEGIN
    INSERT
    INTO cms_caf_b24
      (
        CCB_INST_CODE,
        CCB_PART_FULL,
        CCB_REF_GROUP,
        CCB_B24_VER,
        CCB_LOGI_NTWK,
        CCB_IMPAC_REF,
        CCB_PREAUTH_HOLD,
        CCB_CVV_VALUE,
        CCB_SERVICE_CODE,
        CCB_INS_USER,
        CCB_INS_DATE,
        CCB_LUPD_USER,
        CCB_LUPD_DATE
      )
    SELECT prm_instcode,
      CCB_PART_FULL,
      CCB_REF_GROUP,
      CCB_B24_VER,
      CCB_LOGI_NTWK,
      CCB_IMPAC_REF,
      CCB_PREAUTH_HOLD,
      CCB_CVV_VALUE,
      CCB_SERVICE_CODE,
      prm_superuser,
      SYSDATE,
      prm_superuser,
      SYSDATE
    FROM cms_caf_b24
    WHERE ccb_inst_code=1;
  EXCEPTION
  WHEN OTHERS THEN
    prm_errmsg := 'Error while inserting data into CMS_CAF_B24 ' || SUBSTR(sqlerrm,1,200);
    RETURN;
  END;
  BEGIN
    INSERT
    INTO cms_caf_struct
      (
        CCS_INST_CODE,
        CCS_FIELD_NAME,
        CCS_FIELD_CAPTION,
        CCS_MAX_SIXE,
        CCS_FROM_POSN,
        CCS_TO_POSN,
        CCS_INS_USER,
        CCS_INS_DATE,
        CCS_LUPD_USER,
        CCS_LUPD_DATE,
        CCS_SAMPLE_DATA,
        CCS_FIELD_VALIDATOR,
        CCS_CAF_REC_TYPE
      )
    SELECT prm_instcode,
      CCS_FIELD_NAME,
      CCS_FIELD_CAPTION,
      CCS_MAX_SIXE,
      CCS_FROM_POSN,
      CCS_TO_POSN,
      prm_superuser,
      SYSDATE,
      prm_superuser,
      SYSDATE,
      CCS_SAMPLE_DATA,
      CCS_FIELD_VALIDATOR,
      CCS_CAF_REC_TYPE
    FROM cms_caf_struct
    WHERE ccs_inst_code=1;
  EXCEPTION
  WHEN OTHERS THEN
    prm_errmsg := 'Error while inserting data into CMS_CAF_STRUCT ' || SUBSTR(sqlerrm,1,200);
    RETURN;
  END;
  /*insert into cms_inst_param(
  CIP_INST_CODE,
  CIP_PARAM_KEY,
  CIP_PARAM_VALUE,
  CIP_PARAM_DESC,
  CIP_INS_USER,
  CIP_INS_DATE,
  CIP_LUPD_USER,
  CIP_LUPD_DATE,
  CIP_ALLOWED_VALUES,
  CIP_MANDATORY_FLAG,
  CIP_DISPLAY_FLAG,
  CIP_PARAM_UNIT,
  CIP_PARAM_DISP_TYPE,
  CIP_MULTILING_DESC,
  CIP_VALIDATION_TYPE
  )
  select prm_instcode,
  CIP_PARAM_KEY,
  CIP_PARAM_VALUE,
  CIP_PARAM_DESC,
  CIP_INS_USER,
  CIP_INS_DATE,
  CIP_LUPD_USER,
  CIP_LUPD_DATE,
  CIP_ALLOWED_VALUES,
  CIP_MANDATORY_FLAG,
  CIP_DISPLAY_FLAG,
  CIP_PARAM_UNIT,
  CIP_PARAM_DISP_TYPE,
  CIP_MULTILING_DESC,
  CIP_VALIDATION_TYPE
  from cms_inst_param
  where cip_inst_code=1;*/
  BEGIN
    INSERT
    INTO cms_prodtype_map
      (
        CPM_INST_CODE,
        CPM_INTERCHANGE_CODE,
        CPM_PROD_CATG,
        CPM_PROD_B24,
        CPM_INS_USER,
        CPM_INS_DATE,
        CPM_LUPD_USER,
        CPM_LUPD_DATE
      )
    SELECT prm_instcode,
      CPM_INTERCHANGE_CODE,
      CPM_PROD_CATG,
      CPM_PROD_B24,
      prm_superuser,
      SYSDATE,
      prm_superuser,
      SYSDATE
    FROM cms_prodtype_map
    WHERE cpm_inst_code=1;
  EXCEPTION
  WHEN OTHERS THEN
    prm_errmsg := 'Error while inserting data into CMS_PRODTYPE_MAP ' || SUBSTR(sqlerrm,1,200);
    RETURN;
  END;
  BEGIN
    INSERT
    INTO cms_prod_b24
      (
        CPB_INST_CODE,
        CPB_B24_PRODCODE,
        CPB_PROD_DESC,
        CPB_LUPD_DATE,
        CPB_LUPD_USER,
        CPB_INS_DATE,
        CPB_INS_USER
      )
    SELECT prm_instcode,
      CPB_B24_PRODCODE,
      CPB_PROD_DESC,
      SYSDATE,
      prm_superuser,
      SYSDATE,
      prm_superuser
    FROM cms_prod_b24
    WHERE cpb_inst_code=1;
  EXCEPTION
  WHEN OTHERS THEN
    prm_errmsg := 'Error while inserting data into CMS_PROD_B24 ' || SUBSTR(sqlerrm,1,200);
    RETURN;
  END;
  BEGIN
    INSERT
    INTO cms_spprt_funcs
      (
        CSF_SPPRT_KEY,
        CSF_SPPRT_DESC,
        CSF_LUPD_DATE,
        CSF_INST_CODE,
        CSF_LUPD_USER,
        CSF_INS_DATE,
        CSF_INS_USER,
        CSF_TRAN_CODE
      )
    SELECT CSF_SPPRT_KEY,
      CSF_SPPRT_DESC,
      SYSDATE,
      prm_instcode,
      prm_superuser,
      SYSDATE,
      prm_superuser,
      CSF_TRAN_CODE
    FROM cms_spprt_funcs
    WHERE csf_inst_code=1;
  EXCEPTION
  WHEN OTHERS THEN
    prm_errmsg := 'Error while inserting data into CMS_SPPRT_FUNCS ' || SUBSTR(sqlerrm,1,200);
    RETURN;
  END;
  BEGIN
    INSERT
    INTO cms_spprt_reasons
      (
        CSR_INST_CODE,
        CSR_SPPRT_RSNCODE,
        CSR_SPPRT_KEY,
        CSR_REASONDESC,
        CSR_INS_USER,
        CSR_INS_DATE,
        CSR_LUPD_USER,
        CSR_LUPD_DATE
      )
    SELECT prm_instcode,
      CSR_SPPRT_RSNCODE,
      CSR_SPPRT_KEY,
      CSR_REASONDESC,
      prm_superuser,
      SYSDATE,
      prm_superuser,
      SYSDATE
    FROM cms_spprt_reasons
    WHERE CSR_INST_CODE=1;
  EXCEPTION
  WHEN OTHERS THEN
    prm_errmsg := 'Error while inserting data into CMS_SPPRT_REASONS ' || SUBSTR(sqlerrm,1,200);
    RETURN;
  END;
  BEGIN
    INSERT
    INTO cms_spprt_catg
      (
        CSC_INST_CODE,
        CSC_PROD_CATG,
        CSC_SPPRT_KEY,
        CSC_LUPD_DATE,
        CSC_LUPD_USER,
        CSC_INS_DATE,
        CSC_INS_USER
      )
    SELECT prm_instcode,
      CSC_PROD_CATG,
      CSC_SPPRT_KEY,
      SYSDATE,
      prm_superuser,
      SYSDATE,
      prm_superuser
    FROM cms_spprt_catg
    WHERE csc_inst_code=1;
  EXCEPTION
  WHEN OTHERS THEN
    prm_errmsg := 'Error while inserting data into CMS_SPPRT_CATG ' || SUBSTR(sqlerrm,1,200);
    RETURN;
  END;
  BEGIN
    INSERT
    INTO cms_table_param
      (
        CTP_PARAM_KEY,
        CTP_PARAM_TYPE,
        CTP_PARAM_VALUE,
        CTP_PARAM_DESC,
        CTP_INS_USER,
        CTP_INS_DATE,
        CTP_LUPD_USER,
        CTP_LUPD_DATE,
        CTP_INST_CODE
      )
    SELECT CTP_PARAM_KEY,
      CTP_PARAM_TYPE,
      CTP_PARAM_VALUE,
      CTP_PARAM_DESC,
      prm_superuser,
      SYSDATE,
      prm_superuser,
      SYSDATE,
      prm_instcode
    FROM cms_table_param
    WHERE ctp_inst_code=1;
  EXCEPTION
  WHEN OTHERS THEN
    prm_errmsg := 'Error while inserting data into CMS_TABLE_PARAM ' || SUBSTR(sqlerrm,1,200);
    RETURN;
  END;
  BEGIN
    INSERT
    INTO cms_bran_refreshgrp
      (
        CBR_INST_CODE,
        CBR_BRAN_CODE,
        CBR_RFRSH_GRP,
        CBR_INS_USER,
        CBR_INS_DATE,
        CBR_LUPD_USER,
        CBR_LUPD_DATE
      )
    SELECT prm_instcode,
      CBR_BRAN_CODE,
      CBR_RFRSH_GRP,
      prm_superuser,
      SYSDATE,
      prm_superuser,
      SYSDATE
    FROM cms_bran_refreshgrp
    WHERE cbr_inst_code=1;
  EXCEPTION
  WHEN OTHERS THEN
    prm_errmsg := 'Error while inserting data into CMS_BRAN_REFRESHGRP ' || SUBSTR(sqlerrm,1,200);
    RETURN;
  END;
  BEGIN
    INSERT
    INTO cms_card_stat
      (
        CCS_STAT_CODE,
        CCS_STAT_DESC,
        CCS_LUPD_DATE,
        CCS_INST_CODE,
        CCS_LUPD_USER,
        CCS_INS_DATE,
        CCS_INS_USER
      )
    SELECT CCS_STAT_CODE,
      CCS_STAT_DESC,
      SYSDATE,
      prm_instcode,
      prm_superuser,
      SYSDATE,
      prm_superuser
    FROM cms_card_stat
    WHERE ccs_inst_code=1;
  EXCEPTION
  WHEN OTHERS THEN
    prm_errmsg := 'Error while inserting data into CMS_CARD_STAT ' || SUBSTR(sqlerrm,1,200);
    RETURN;
  END;
  /*insert into cms_branch_catg(
  CBC_CATG_CODE,
  CBC_CATG_DESC,
  CBC_LUPD_DATE,
  CBC_INST_CODE,
  CBC_LUPD_USER,
  CBC_INS_DATE,
  CBC_INS_USER,
  CBC_CATG_FOR_PROD
  )
  select CBC_CATG_CODE,
  CBC_CATG_DESC,
  CBC_LUPD_DATE,
  prm_instcode,
  CBC_LUPD_USER,
  CBC_INS_DATE,
  CBC_INS_USER,
  CBC_CATG_FOR_PROD
  from cms_branch_catg
  where cbc_inst_code=1;*/
  /*insert into cms_branch_type(
  CBT_TYPE_CODE,
  CBT_CATG_CODE,
  CBT_TYPE_DESC,
  CBT_REPORTING_BRAN,
  CBT_INS_USER,
  CBT_INS_DATE,
  CBT_LUPD_USER,
  CBT_LUPD_DATE,
  CBT_INST_CODE
  )
  select CBT_TYPE_CODE,
  CBT_CATG_CODE,
  CBT_TYPE_DESC,
  CBT_REPORTING_BRAN,
  CBT_INS_USER,
  CBT_INS_DATE,
  CBT_LUPD_USER,
  CBT_LUPD_DATE,
  prm_instcode
  from cms_branch_type
  where cbt_inst_code=1;*/
  BEGIN
    INSERT
    INTO cms_chnl_mast
      (
        CCM_INST_CODE,
        CCM_CHNL_CODE,
        CCM_CHNL_DESC,
        CCM_INS_USER,
        CCM_INS_DATE,
        CCM_LUPD_USER,
        CCM_LUPD_DATE
      )
    SELECT prm_instcode,
      CCM_CHNL_CODE,
      CCM_CHNL_DESC,
      prm_superuser,
      SYSDATE,
      prm_superuser,
      SYSDATE
    FROM cms_chnl_mast
    WHERE ccm_inst_code=1;
  EXCEPTION
  WHEN OTHERS THEN
    prm_errmsg := 'Error while inserting data into CMS_CHNL_MAST ' || SUBSTR(sqlerrm,1,200);
    RETURN;
  END;
  BEGIN
    INSERT
    INTO cms_gen_col_mapping
      (
        CGM_INST_CODE,
        CGM_TABLE_NAME,
        CGM_COLUMN_NAME,
        CGM_COLUMN_DATA,
        CGM_COLUMN_DATATYPE,
        CGM_COLUMN_DATAFORMAT,
        CGM_INS_USER,
        CGM_INS_DATE,
        CGM_LUPD_USER,
        CGM_LUPD_DATE
      )
    SELECT prm_instcode,
      CGM_TABLE_NAME,
      CGM_COLUMN_NAME,
      CGM_COLUMN_DATA,
      CGM_COLUMN_DATATYPE,
      CGM_COLUMN_DATAFORMAT,
      prm_superuser,
      SYSDATE,
      prm_superuser,
      SYSDATE
    FROM cms_gen_col_mapping
    WHERE cgm_inst_code=1;
  EXCEPTION
  WHEN OTHERS THEN
    prm_errmsg := 'Error while inserting data into CMS_GEN_COL_MAPPING ' || SUBSTR(sqlerrm,1,200);
    RETURN;
  END;
  BEGIN
    INSERT
    INTO cms_pan_fields
      (
        CPC_INST_CODE,
        CPC_FIELD_NAME,
        CPC_START_FROM,
        CPC_LENGTH,
        CPC_VALUE,
        CPC_LUPD_DATE,
        CPC_LUPD_USER,
        CPC_INS_DATE,
        CPC_INS_USER
      )
    SELECT prm_instcode,
      CPC_FIELD_NAME,
      CPC_START_FROM,
      CPC_LENGTH,
      CPC_VALUE,
      SYSDATE,
      prm_superuser,
      SYSDATE,
      prm_superuser
    FROM cms_pan_fields
    WHERE cpc_inst_code=1;
  EXCEPTION
  WHEN OTHERS THEN
    prm_errmsg := 'Error while inserting data into CMS_PAN_FIELDS ' || SUBSTR(sqlerrm,1,200);
    RETURN;
  END;
  BEGIN
    INSERT
    INTO cms_transaction_mast
      (
        CTM_INST_CODE,
        CTM_TRAN_CODE,
        CTM_TRAN_DESC,
        CTM_CREDIT_DEBIT_FLAG,
        CTM_DELIVERY_CHANNEL,
        CTM_OUTPUT_TYPE,
        CTM_TRAN_TYPE,
        CTM_SUPPORT_TYPE,
        CTM_LUPD_DATE,
        CTM_LUPD_USER,
        CTM_INS_DATE,
        CTM_INS_USER,
        CTM_SUPPORT_CATG
      )
    SELECT prm_instcode,
      CTM_TRAN_CODE,
      CTM_TRAN_DESC,
      CTM_CREDIT_DEBIT_FLAG,
      CTM_DELIVERY_CHANNEL,
      CTM_OUTPUT_TYPE,
      CTM_TRAN_TYPE,
      CTM_SUPPORT_TYPE,
      SYSDATE,
      prm_superuser,
      SYSDATE,
      prm_superuser,
      CTM_SUPPORT_CATG
    FROM cms_transaction_mast
    WHERE ctm_inst_code=1;
  EXCEPTION
  WHEN OTHERS THEN
    prm_errmsg := 'Error while inserting data into CMS_TRANSACTION_MAST ' || SUBSTR(sqlerrm,1,200);
    RETURN;
  END;
  BEGIN
    INSERT
    INTO cms_ctrl_table
      (
        CCT_CTRL_CODE,
        CCT_CTRL_KEY,
        CCT_CTRL_NUMB,
        CCT_CTRL_DESC,
        CCT_INS_USER,
        CCT_INS_DATE,
        CCT_LUPD_USER,
        CCT_LUPD_DATE,
        CCT_INST_CODE
      )
      VALUES
      (
        prm_instcode,
        'SLAB CODE',
        1,
        'Latest SLAB CODE for institution '
        ||prm_instcode,
        prm_superuser,
        SYSDATE,
        prm_superuser,
        SYSDATE,
        prm_instcode
      );
  EXCEPTION
  WHEN OTHERS THEN
    prm_errmsg:='Error occurs during the inserts statement for SLAB CODE '||SUBSTR
    (
      sqlerrm,1,200
    )
    ;
    RETURN;
  END;
  BEGIN
    INSERT
    INTO cms_ctrl_table
      (
        CCT_CTRL_CODE,
        CCT_CTRL_KEY,
        CCT_CTRL_NUMB,
        CCT_CTRL_DESC,
        CCT_INS_USER,
        CCT_INS_DATE,
        CCT_LUPD_USER,
        CCT_LUPD_DATE,
        CCT_INST_CODE
      )
      VALUES
      (
        prm_instcode,
        'CUST CATG',
        1,
        'Latest CUST CATG for institution '
        ||prm_instcode,
        prm_superuser,
        SYSDATE,
        prm_superuser,
        SYSDATE,
        prm_instcode
      );
  EXCEPTION
  WHEN OTHERS THEN
    prm_errmsg:='Error occurs during the inserts statement for CUST CATG '||SUBSTR
    (
      sqlerrm,1,200
    )
    ;
    RETURN;
  END;
  BEGIN
    INSERT
    INTO cms_ctrl_table
      (
        CCT_CTRL_CODE,
        CCT_CTRL_KEY,
        CCT_CTRL_NUMB,
        CCT_CTRL_DESC,
        CCT_INS_USER,
        CCT_INS_DATE,
        CCT_LUPD_USER,
        CCT_LUPD_DATE,
        CCT_INST_CODE
      )
      VALUES
      (
        prm_instcode,
        'CUSTCODE',
        1,
        'Latest CUSTCODE for institution '
        ||prm_instcode,
        prm_superuser,
        SYSDATE,
        prm_superuser,
        SYSDATE,
        prm_instcode
      );
  EXCEPTION
  WHEN OTHERS THEN
    prm_errmsg:='Error occurs during the inserts statement for CUSTOCDE '||SUBSTR
    (
      sqlerrm,1,200
    )
    ;
    RETURN;
  END;
  BEGIN
    INSERT
    INTO cms_ctrl_table
      (
        CCT_CTRL_CODE,
        CCT_CTRL_KEY,
        CCT_CTRL_NUMB,
        CCT_CTRL_DESC,
        CCT_INS_USER,
        CCT_INS_DATE,
        CCT_LUPD_USER,
        CCT_LUPD_DATE,
        CCT_INST_CODE
      )
      VALUES
      (
        prm_instcode,
        'CHANNEL',
        1,
        'Latest CHANNEL for institution '
        ||prm_instcode,
        prm_superuser,
        SYSDATE,
        prm_superuser,
        SYSDATE,
        prm_instcode
      );
  EXCEPTION
  WHEN OTHERS THEN
    prm_errmsg:='Error occurs during the inserts statement for CHANNEL '||SUBSTR
    (
      sqlerrm,1,200
    )
    ;
    RETURN;
  END;
  BEGIN
    INSERT
    INTO cms_ctrl_table
      (
        CCT_CTRL_CODE,
        CCT_CTRL_KEY,
        CCT_CTRL_NUMB,
        CCT_CTRL_DESC,
        CCT_INS_USER,
        CCT_INS_DATE,
        CCT_LUPD_USER,
        CCT_LUPD_DATE,
        CCT_INST_CODE
      )
      VALUES
      (
        prm_instcode,
        'FEE TYPE CODE',
        1,
        'Latest FEE TYPE CODE for institution '
        ||prm_instcode,
        prm_superuser,
        SYSDATE,
        prm_superuser,
        SYSDATE,
        prm_instcode
      );
  EXCEPTION
  WHEN OTHERS THEN
    prm_errmsg:='Error occurs during the inserts statement for FEE TYPE CODE '||SUBSTR
    (
      sqlerrm,1,200
    )
    ;
    RETURN;
  END;
  BEGIN
    INSERT
    INTO cms_ctrl_table
      (
        CCT_CTRL_CODE,
        CCT_CTRL_KEY,
        CCT_CTRL_NUMB,
        CCT_CTRL_DESC,
        CCT_INS_USER,
        CCT_INS_DATE,
        CCT_LUPD_USER,
        CCT_LUPD_DATE,
        CCT_INST_CODE
      )
      VALUES
      (
        prm_instcode,
        'FEE CODE',
        1,
        'Latest FEE CODE for institution '
        ||prm_instcode,
        prm_superuser,
        SYSDATE,
        prm_superuser,
        SYSDATE,
        prm_instcode
      );
  EXCEPTION
  WHEN OTHERS THEN
    prm_errmsg:='Error occurs during the inserts statement for FEE CODE '||SUBSTR
    (
      sqlerrm,1,200
    )
    ;
    RETURN;
  END;
EXCEPTION
WHEN OTHERS THEN
  prm_errmsg:='Error while inserting data in the tables '||SUBSTR
  (
    sqlerrm,1,200
  )
  ;
  ROLLBACK;
END;
/


