CREATE OR REPLACE PROCEDURE VMSCMS.SP_CSR_CREATE_USER(
    prm_instcode       IN NUMBER,
    prm_login_code     IN VARCHAR2,
    prm_grp_code       IN NUMBER,
    prm_encr_pswd      IN VARCHAR2,
    prm_user_name      IN VARCHAR2,
    prm_validfrom_date IN VARCHAR2,
    prm_validto_date   IN VARCHAR2,
    prm_email          IN VARCHAR2,
    prm_mobile_no      IN VARCHAR2,
    prm_dob            IN VARCHAR2,
    prm_source         IN NUMBER,
    prm_termial_prev   IN NUMBER,
    prm_user_status    IN NUMBER,
    prm_ins_user       IN NUMBER,
    prm_mask_flag      IN VARCHAR2,
    PRM_BIN_LIST       IN VARCHAR2,
    prm_regen_pwd_flag IN VARCHAR2, --added by amit on 05-Oct-2012
    prm_regen_pwd_resn IN VARCHAR2, --added by amit on 05-Oct-2012    
    prm_user_flag      in varchar2, --added by amit on 05-Oct-2012
    prm_emailchange_flag out varchar2, --added by on 10-Oct-2012
    prm_errmsg         out varchar2 
    )
IS
  /**********************************************************************************************
  * VERSION                    :  1.0
  * DATE OF CREATION           : 06/Sep/2012
  * PURPOSE                    : User creation
  * CREATED BY                 : Sagar More
  * MODIFICATION REASON        : To autdit Newly added and updated user in CMS_USERDETL_AUDT table
  * LAST MODIFICATION DONE FOR : Data separation CR
  * LAST MODIFICATION DATE     : 21-DEC-2012
  * Build Number               : RI0023
  **************************************************************************************************/
  v_errmsg          VARCHAR2(500);
  exp_reject_record EXCEPTION;
  v_user_pin        NUMBER;
  v_cnt             NUMBER;
  V_LOGIN_PSWD CMS_USER_MAST.CUM_ENCR_PSWD%TYPE;
  V_OLD_PWD CMS_USERDETL_MAST.CUM_LGIN_PSWD%TYPE;    --added by amit on 05-Oct-2012
  V_USER_CODE CMS_USERDETL_MAST.CUM_USER_CODE%TYPE;  --added by amit on 05-Oct-2012
  v_user_email CMS_USERDETL_MAST.CUM_USER_EMAL%TYPE; --added by amit on 05-Oct-2012
BEGIN
  v_errmsg       := 'OK';
  V_LOGIN_PSWD   := FN_EMAPS_MAIN('admin1234');
  prm_emailchange_flag := 'N';
  
  IF prm_user_flag='A' ---added by amit on 05-Oct-2012
  THEN
  
    BEGIN
      SELECT COUNT(1)
      INTO v_cnt
      FROM cms_user_mast
      WHERE cum_inst_code = prm_instcode
      AND cum_user_code   = prm_login_Code;
      
      IF v_cnt           >= 1 THEN
        v_errmsg         := 'Login code already exists';
        raise exp_reject_record;
      END IF;
      
      BEGIN
        SELECT COUNT(1)
        INTO v_cnt
        FROM cms_userdetl_mast
        WHERE cum_lgin_code = prm_login_code;
        
        IF v_cnt           >= 1 THEN
          v_errmsg         := 'Login code already exists';
          raise exp_reject_record;
        END IF;
        
      EXCEPTION
      WHEN exp_reject_record THEN
        raise;
      WHEN OTHERS THEN
        v_errmsg := 'Error whille validting Login code in CSR'||SUBSTR(sqlerrm,1,100);
        raise exp_reject_record;
      END;
      
      
    EXCEPTION
    WHEN exp_reject_record THEN
      raise;
    WHEN OTHERS THEN
      v_errmsg := 'Error whille validting Login code in HOST '||SUBSTR(sqlerrm,1,100);
      raise exp_reject_record;
    END;
    
    
      /*
        BEGIN

          SELECT NVL(MAX(cum_user_pin),0) + 1 INTO v_user_pin FROM cms_user_mast;

        EXCEPTION
        WHEN OTHERS THEN
          v_errmsg := 'while geeting max value for userpin '||SUBSTR(sqlerrm,1,100);
          raise exp_reject_record;
        END;
       */ 
   
       --SN: Added on 30NOV12 to generate user pin by sequence instead of control number
       
        SELECT  seq_user_pin.NEXTVAL
        INTO    v_user_pin
        FROM    dual;
        
       --EN: Added on 30NOV12 to generate user pin by sequence instead of control number        

    
    BEGIN
    
      INSERT
      INTO cms_user_mast
        (
          CUM_USER_PIN,
          CUM_INST_CODE,
          CUM_USER_CODE,
          CUM_ENCR_PSWD,
          CUM_USER_NAME,
          CUM_BRAN_CODE,
          CUM_VALID_FRDT,
          CUM_VALID_TODT,
          CUM_USER_SUSP,
          CUM_PSWD_DATE,
          CUM_INS_USER,
          CUM_INS_DATE,
          CUM_LUPD_USER,
          CUM_LUPD_DATE,
          CUM_LAST_LOGINTIME,
          CUM_USER_EMAIL,
          CUM_USER_TYPE
        )
        VALUES
        (
          v_user_pin,
          prm_instcode,
          prm_login_code,
          v_login_pswd,
          prm_user_name,
          'DEF',
          TO_DATE(prm_validfrom_date,'mm/dd/yyyy'),
          TO_DATE(prm_validto_date,'mm/dd/yyyy'),
          'L',
          sysdate,
          prm_ins_user,
          sysdate,
          prm_ins_user,
          sysdate,
          sysdate,
          prm_email,
          '2'
        );
        
      BEGIN
      
        INSERT
        INTO cms_track_login
          (
            CTL_INST_CODE,
            CTL_USER_PIN,
            CTL_WRONG_LOGINCNT,
            CTL_LOGIN_DATE,
            CTL_INS_USER,
            CTL_INS_DATE
          )
          VALUES
          (
            prm_instcode,
            v_user_pin,
            0,
            SYSDATE,
            prm_ins_user,
            SYSDATE
          );
      EXCEPTION
      WHEN OTHERS THEN
        v_errmsg := 'Error while inserting into tracklogin '||SUBSTR(sqlerrm,1,100);
        raise exp_reject_record;
      END;
      
      BEGIN
      
        INSERT
        INTO CMS_PREV_PSWDS
          (
            CPP_INST_CODE,
            CPP_USER_PIN,
            CPP_PREV_PSWD,
            CPP_PSWD_DATE,
            CPP_INS_USER,
            CPP_INS_DATE
          )
          VALUES
          (
            prm_instcode,
            v_user_pin,
            v_login_pswd,
            SYSDATE,
            prm_ins_user,
            SYSDATE
          );
      EXCEPTION
      WHEN OTHERS THEN
        v_errmsg := 'Error while inserting into prev pswds '||SUBSTR(sqlerrm,1,100);
        raise exp_reject_record;
      END;
      
      
    EXCEPTION
    WHEN exp_reject_record THEN
      RAISE;
    WHEN OTHERS THEN
      v_errmsg := 'Error while inserting into user_mast '||SUBSTR(sqlerrm,1,100);
      raise exp_reject_record;
    END;
    
    
    BEGIN
    
      INSERT
      INTO cms_userdetl_mast
        (
          cum_user_code,
          cum_lgin_code,
          cum_lgin_pswd,
          cum_user_name,
          cum_vald_frdt,
          cum_vald_todt,
          cum_user_emal,
          cum_user_mobl,
          cum_user_dofb,
          cum_frtx_pswd,
          cum_frlg_pswd,
          cum_hrtx_blck,
          cum_lgpw_rsfl,
          cum_lgpw_rsdt,
          cum_lgpw_date,
          cum_txpw_rsfl,
          cum_inpt_srce,
          cum_trpf_priv,
          cum_user_stus,
          cum_ins_user,
          cum_ins_date,
          cum_usermask_flag,
          cum_auth_bin
        )
        VALUES
        (
          v_user_pin,
          prm_login_code,
          prm_encr_pswd,
          prm_user_name,
          TO_DATE(prm_validfrom_date,'mm/dd/yyyy'),
          TO_DATE(prm_validto_date,'mm/dd/yyyy'),
          prm_email,
          prm_mobile_no,
          TO_DATE(prm_dob,'mm/dd/yyyy'),
          1,
          1,
          0,
          0,
          sysdate,
          sysdate,
          '-1',
          prm_source,
          prm_termial_prev,
          prm_user_status,
          prm_ins_user,
          sysdate ,
          prm_mask_flag,
          prm_bin_list
        );
    EXCEPTION
    WHEN OTHERS THEN
      v_errmsg := 'Error while inserting into userdetl_mast '||SUBSTR(sqlerrm,1,100);
      raise exp_reject_record;
    END;
    
    BEGIN
      INSERT
      INTO CMS_USGPDETL_MAST
        (
          CUM_INST_CODE,
          CUM_USER_CODE,
          CUM_GRUP_CODE,
          CUM_USGP_STUS,
          CUM_INS_USER,
          CUM_INS_DATE
        )
        VALUES
        (
          prm_instcode,
          v_user_pin,
          prm_grp_code,
          1 ,
          prm_ins_user,
          sysdate
        );
    EXCEPTION
    WHEN OTHERS THEN
      v_errmsg := 'Error while inserting into usergroup '||SUBSTR(sqlerrm,1,100);
      raise exp_reject_record;
    END;
    BEGIN
      INSERT
      INTO CMS_USER_INST
        (
          CUI_INST_CODE,
          CUI_USER_CODE,
          CUI_DFLT_INST,
          CUI_USIN_STUS,
          CUI_INS_USER,
          CUI_INS_DATE
        )
        VALUES
        (
          prm_instcode,
          v_user_pin ,
          1,--Changed by Dnyaneshwar J on 22 Oct 2012
          1,
          prm_ins_user,
          sysdate
        );
    EXCEPTION
    WHEN OTHERS THEN
      v_errmsg := 'Error while inserting into user institution '||SUBSTR(sqlerrm,1,100);
      raise exp_reject_record;
    END;
    
    BEGIN
      INSERT
      INTO CMS_TRACKDETL_LGIN
        (
          CTL_INST_CODE,
          CTL_USER_CODE,
          CTL_PSWD_TYPE,
          CTL_INVL_LGIN,
          CTL_INS_USER,
          CTL_INS_DATE
        )
        VALUES
        (
          prm_instcode,
          v_user_pin,
          1,
          0,
          prm_ins_user,
          sysdate
        );
    EXCEPTION
    WHEN OTHERS THEN
      v_errmsg := 'Error while inserting into tracklogin '||SUBSTR(sqlerrm,1,100);
      raise exp_reject_record;
    END;
    
    BEGIN
    
      INSERT
      INTO CMS_USERDETL_AUDT
        (
          cua_user_code,
          cua_lgin_code,
          cua_lgin_pswd,
          cua_user_name,
          cua_vald_frdt,
          cua_vald_todt,
          cua_user_emal,
          cua_user_mobl,
          cua_user_dofb,
          cua_frtx_pswd,
          cua_frlg_pswd,
          cua_hrtx_blck,
          cua_lgpw_rsfl,
          cua_lgpw_rsdt,
          cua_lgpw_date,
          cua_txpw_rsfl,
          cua_inpt_srce,
          cua_trpf_priv,
          cua_user_stus,
          cua_ins_user,
          cua_ins_date,
          cua_usermask_flag,
          cua_auth_bin,
		  cua_audt_flag
        )
        VALUES
        (
          v_user_pin,
          prm_login_code,
          prm_encr_pswd,
          prm_user_name,
          TO_DATE(prm_validfrom_date,'mm/dd/yyyy'),
          TO_DATE(prm_validto_date,'mm/dd/yyyy'),
          prm_email,
          prm_mobile_no,
          TO_DATE(prm_dob,'mm/dd/yyyy'),
          1,
          1,
          0,
          0,
          sysdate,
          sysdate,
          '-1',
          prm_source,
          prm_termial_prev,
          prm_user_status,
          prm_ins_user,
          sysdate ,
          prm_mask_flag,
          prm_bin_list,
		  'A'
        );
    EXCEPTION
    WHEN OTHERS THEN
      v_errmsg := 'Error while inserting into userdetl Audit mast for flag A '||SUBSTR(sqlerrm,1,100);
      raise exp_reject_record;
    END;    
    
    
  ELSIF PRM_USER_FLAG='E' 
  THEN
  
    BEGIN
      SELECT cum_user_code,
        cum_user_emal,
        cum_lgin_pswd
      INTO v_user_code,
        v_user_email,
        v_old_pwd
      FROM CMS_USERDETL_MAST
      WHERE cum_lgin_code=prm_login_code;
    EXCEPTION
    WHEN no_data_found THEN
      v_errmsg:='User not defined in the master.';
      raise exp_reject_record;
    when others then
      v_errmsg:='Error while fetching user details -'||substr(sqlerrm,1,100);
      raise exp_reject_record;
    END;
    
    if v_user_email <> PRM_EMAIL
    then
    
         prm_emailchange_flag := 'Y';
    
    end if;
    
    
    --Sn to edit user details------
    BEGIN
      UPDATE CMS_USERDETL_MAST
      SET CUM_USER_NAME   = prm_user_name ,
        CUM_VALD_FRDT     = TO_DATE(PRM_VALIDFROM_DATE,'mm/dd/yyyy'),
        cum_vald_todt     = to_date(prm_validto_date,'mm/dd/yyyy'),
        CUM_PREV_EMAL     = v_user_email,
        CUM_USER_EMAL     = PRM_EMAIL ,
        CUM_USER_MOBL     = prm_mobile_no ,
        CUM_USER_DOFB     = TO_DATE(prm_dob,'mm/dd/yyyy'),
        cum_user_stus     = prm_user_status ,
        CUM_AUTH_BIN      = PRM_BIN_LIST,
        CUM_USERMASK_FLAG = PRM_MASK_FLAG,
        CUM_LUPD_USER     = prm_ins_user ,
        cum_lupd_date     = sysdate
      WHERE cum_user_code = v_user_code;
      
      IF sql%rowcount     =0 THEN
        v_errmsg         :='User not found in master.';
        raise exp_reject_record;
      END IF;
      
      IF PRM_REGEN_PWD_FLAG= 'T'   --if regenerate password is true
      THEN
        BEGIN
          UPDATE CMS_USERDETL_MAST
          SET CUM_LGIN_PSWD = prm_encr_pswd,  
              CUM_LGPW_RSDT = SYSDATE, 
              CUM_LGPW_RSFL = 1
          WHERE CUM_USER_CODE = V_USER_CODE;
        EXCEPTION
        WHEN OTHERS THEN
          V_ERRMSG := 'Error while updating password details '||SUBSTR(SQLERRM,1,100);
          raise exp_reject_record;
        END;
        
        --Sn to save password history------
        BEGIN
          INSERT INTO CMS_PSWD_HIST(CPH_USER_CODE, 
                                    CPH_PSWD_TYPE,  
                                    CPH_OLD_PSWD,  
                                    CPH_NEW_PSWD, 
                                    CPH_INS_USER, 
                                    CPH_INS_DATE,  
                                    CPH_PWCH_RESN
                                    )
                              VALUES(V_USER_CODE, 
                                     1,  --need to ask        
                                     V_OLD_PWD, 
                                     prm_encr_pswd, 
                                     prm_ins_user,
                                     SYSDATE,
                                     prm_regen_pwd_resn
                                     );
        EXCEPTION
        WHEN OTHERS
        THEN
             V_ERRMSG := 'Error while creating user-user group '||SUBSTR(SQLERRM,1,100);
             RAISE EXP_REJECT_RECORD;
        END;
        --En to save password history------        
        
      END IF;
    EXCEPTION
    WHEN exp_reject_record THEN
      RAISE;
    WHEN OTHERS THEN
      v_errmsg := 'Error while editing user details '||SUBSTR(SQLERRM,1,100);
      raise exp_reject_record;
    END;
    --En to edit user details------
      
    --Sn to edit group details-----
    BEGIN
        DELETE FROM CMS_USGPDETL_MAST  WHERE CUM_USER_CODE = V_USER_CODE;
    EXCEPTION
    WHEN OTHERS
    THEN
       V_ERRMSG := 'Error while deleting user group-'||SUBSTR(SQLERRM,1,100);
       raise exp_reject_record;
    END;
      
      BEGIN
        INSERT INTO  CMS_USGPDETL_MAST (CUM_INST_CODE, 
                                        CUM_USER_CODE, 
                                        CUM_GRUP_CODE, 
                                        CUM_USGP_STUS , 
                                        CUM_INS_USER , 
                                        CUM_INS_DATE 
                                        ) 
                                VALUES  (PRM_INSTCODE,
                                         V_USER_CODE,
                                         PRM_GRP_CODE,
                                         1, 
                                         prm_ins_user,
                                         SYSDATE 
                                         );
      EXCEPTION 
      WHEN OTHERS
      THEN
        V_ERRMSG := 'Error while mapping user-user group '||SUBSTR(SQLERRM,1,100);
         RAISE EXP_REJECT_RECORD;
      END;
    --En to edit group details-----
    
    --Sn to edit USER inst details
    BEGIN
      delete from cms_user_inst   
      where cui_user_code =v_user_code;
    EXCEPTION
    WHEN OTHERS
    then
       v_errmsg := 'Error while deleting user inst-'||substr(sqlerrm,1,100);
       raise exp_reject_record;
    end;
    
    begin
      INSERT  INTO  CMS_USER_INST(CUI_INST_CODE,
                                  CUI_USER_CODE, 
                                  CUI_DFLT_INST,
                                  CUI_USIN_STUS, 
                                  CUI_INS_USER,
                                  CUI_INS_DATE
                                  ) 
                          VALUES (PRM_INSTCODE,
                                  V_USER_CODE,
                                  1,
                                  1,
                                  prm_ins_user,
                                  sysdate 
                                  );
     EXCEPTION 
      WHEN OTHERS
      THEN
        V_ERRMSG := 'Error while creating user-user inst '||SUBSTR(SQLERRM,1,100);
         RAISE EXP_REJECT_RECORD;
    END;
    --En to edit USER inst details----- 
    
    Begin
    
        update cms_trackdetl_lgin 
        set ctl_invl_lgin = 0,
            ctl_lupd_user = prm_ins_user,
            ctl_lupd_date = sysdate  
        where ctl_pswd_type = decode(prm_user_status,1,1,2)
        and ctl_user_code = v_user_code and ctl_inst_code = PRM_INSTCODE;
        
     EXCEPTION 
      WHEN OTHERS
      THEN
        V_ERRMSG := 'Error while updating trackdetl while edit user '||SUBSTR(SQLERRM,1,100);
        RAISE EXP_REJECT_RECORD;
    end;
    
   
    Begin 
        
    INSERT INTO CMS_USERDETL_AUDT
            (
              CUA_USER_CODE,    
              CUA_LGIN_CODE,    
              CUA_LGIN_PSWD,  
              CUA_TXN_PSWD , 
              CUA_USER_NAME,
              CUA_VALD_FRDT,   
              CUA_VALD_TODT,    
              CUA_USER_EMAL,    
              CUA_USER_MOBL,    
              CUA_USER_DOFB,    
              CUA_FRTX_PSWD,    
              CUA_FRLG_PSWD,    
              CUA_HRTX_BLCK,    
              CUA_PREV_EMAL,    
              CUA_LGPW_RSFL,    
              CUA_LGPW_RSDT,    
              CUA_LGPW_DATE,    
              CUA_TXPW_RSFL,    
              CUA_TXPW_RSDT,    
              CUA_TXPW_DATE,    
              CUA_INPT_SRCE,    
              CUA_TRPF_PRIV,    
              CUA_USER_STUS,    
              CUA_INS_USER ,    
              CUA_INS_DATE ,    
              CUA_LAST_LGDT,    
              CUA_SESN_PSWD,    
              CUA_USER_UUID,    
              CUA_UUID_DATE,    
              CUA_USERMASK_FLAG,
              CUA_AUTH_BIN,     
              CUA_AUDT_FLAG    
            )
    select 
            CUM_USER_CODE,    
            CUM_LGIN_CODE,    
            CUM_LGIN_PSWD,  
            CUM_TXN_PSWD , 
            CUM_USER_NAME,
            CUM_VALD_FRDT,   
            CUM_VALD_TODT,    
            CUM_USER_EMAL,    
            CUM_USER_MOBL,    
            CUM_USER_DOFB,    
            CUM_FRTX_PSWD,    
            CUM_FRLG_PSWD,    
            CUM_HRTX_BLCK,    
            CUM_PREV_EMAL,    
            CUM_LGPW_RSFL,    
            CUM_LGPW_RSDT,    
            CUM_LGPW_DATE,    
            CUM_TXPW_RSFL,    
            CUM_TXPW_RSDT,    
            CUM_TXPW_DATE,    
            CUM_INPT_SRCE,    
            CUM_TRPF_PRIV,    
            CUM_USER_STUS,    
            CUM_LUPD_USER ,    
            CUM_LUPD_DATE ,    
            CUM_LAST_LGDT,    
            CUM_SESN_PSWD,    
            CUM_USER_UUID,    
            CUM_UUID_DATE,    
            CUM_USERMASK_FLAG,
            CUM_AUTH_BIN,     
            'E'    
    from cms_userdetl_mast
    where cum_lgin_code=prm_login_code;    
        
        
    EXCEPTION
    WHEN OTHERS THEN
      v_errmsg := 'Error while inserting into userdetl Audit mast for flag E '||SUBSTR(sqlerrm,1,100);
      raise exp_reject_record;
    END;   

  END IF;
  
  PRM_ERRMSG      := V_ERRMSG;
  
EXCEPTION
WHEN exp_reject_record THEN
  prm_errmsg := v_errmsg;
WHEN OTHERS THEN
  prm_errmsg := 'Main Exception '||SUBSTR(sqlerrm,1,100);
END;
/
show error;