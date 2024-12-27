CREATE OR REPLACE PROCEDURE VMSCMS.SP_CREATE_USER (    instcode    IN         NUMBER        ,
                                                 usercode    IN         VARCHAR2    ,
                                                pswd        IN         VARCHAR2    ,
                                                username    IN         VARCHAR2    ,
                                                brancode    IN         VARCHAR2    ,
                                                validfrom    IN         DATE        ,
                                                validto        IN         DATE        ,
                                                usersusp    IN         CHAR        ,
                                                prm_user_type        VARCHAR2,
                                                prm_callcenter_id    VARCHAR2,
                                                prm_corp_id             VARCHAR2,
                                                email        IN         VARCHAR2    ,
                                                prm_access_flag IN    VARCHAR2    ,
                                                lupduser    IN         NUMBER        ,
                                                errmsg        OUT         VARCHAR2     )
AS
  userpin             NUMBER (5) ;
  v_cip_param_value     NUMBER  ;
  v_count              NUMBER(3) ;
BEGIN        --Main Begin Block Starts Here
            errmsg := 'OK';
            
IF    instcode IS NOT NULL AND usercode IS NOT NULL AND pswd IS NOT NULL AND username IS NOT NULL THEN
--IF 1

    SELECT     seq_user_pin.NEXTVAL
    INTO    userpin
    FROM    dual;

    /*SELECT cip_pswd_change
    INTO    v_cip_pswd_change
    FROM    cms_inst_param
    WHERE    cip_inst_code        =    instcode    ;*/
    --select the parameter which indicates the no. of days after which the users have to change their passwords
    BEGIN

            SELECT    cip_param_value
            INTO    v_cip_param_value
            FROM    CMS_INST_PARAM
            WHERE    cip_inst_code        =    instcode
            AND        cip_param_key    =    'PSWD CHANGE';
    EXCEPTION
    WHEN NO_DATA_FOUND THEN
        
    v_cip_param_value := '15';
    INSERT INTO cms_inst_param
            (cip_inst_code, cip_param_key, cip_param_desc, cip_param_value,
             cip_ins_user, cip_ins_date, cip_lupd_user,
             cip_lupd_date, cip_mandatory_flag,
             cip_display_flag, cip_param_unit, cip_param_disp_type,
             cip_multiling_desc, cip_validation_type
            )
     VALUES (instcode, 'PSWD CHANGE', 'Password Change Interval', '15',
             lupduser, SYSDATE, lupduser,
             SYSDATE, 'Y',
             'Y', 'Days', 'TEXT',
             'cms.parameters.s14.textPwdChangeInt', 'N'
            );
            
            
    INSERT INTO cms_inst_param
            (cip_inst_code, cip_param_key, cip_param_desc, cip_param_value,
             cip_ins_user, cip_ins_date, cip_lupd_user,
             cip_lupd_date, cip_mandatory_flag,
             cip_display_flag, cip_param_unit, cip_param_disp_type,
             cip_multiling_desc, cip_validation_type
            )
     VALUES (instcode, 'NEW PSWD', 'Password History Counts', '10',
             lupduser, SYSDATE, lupduser,
             SYSDATE, 'Y',
             'Y', 'Nos.', 'TEXT',
             'cms.parameters.s14.textPwdHist', 'N'
            );
            
            
    INSERT INTO cms_inst_param
            (cip_inst_code, cip_param_key, cip_param_desc, cip_param_value,
             cip_ins_user, cip_ins_date, cip_lupd_user,
             cip_lupd_date, cip_mandatory_flag,
             cip_display_flag, cip_param_unit, cip_param_disp_type,
             cip_multiling_desc, cip_validation_type
            )
     VALUES (instcode, 'WRONG PSWDS', 'Allowable Wrong Logins', '3',
             lupduser, SYSDATE, lupduser,
             SYSDATE, 'Y',
             'Y', 'Nos.', 'TEXT',
             'cms.parameters.s14.textAllWrngLog', 'N'
            );
            
    Insert into CMS_USER_LICENSE
       (CMU_INST_CODE, CMU_MAX_USERS)
    Values
       (instcode, 99999);    
       
           
    when others then
    
        errmsg := 'Error while checking password change interval ' || substr(sqlerrm,1,200);
        RETURN;
    
    END;

            BEGIN  --Added by Abhijit on 09-FEb-05
                IF prm_user_type in(0,2) THEN

                        SELECT COUNT(1) INTO v_count FROM CMS_USER_MAST --Added By Abhijit for duplicate check
                        --WHERE cum_user_name=username;
                        WHERE UPPER(CUM_USER_CODE)=UPPER(usercode)
                        AND   CUM_INST_CODE       = instcode;
        
                            IF v_count > 0 THEN
                                     errmsg := 'User Id '''|| usercode ||''' already exists ';
                                   RETURN;
        
                            ELSE  --Added by Abhijit on 09-FEB-05
        
                                INSERT INTO CMS_USER_MAST
                                        (    CUM_USER_PIN        ,
                                            CUM_INST_CODE         ,
                                            CUM_USER_CODE       ,
                                            CUM_ENCR_PSWD    ,
                                            CUM_USER_NAME    ,
                                            CUM_BRAN_CODE       ,
                                            CUM_VALID_FRDT    ,
                                            CUM_VALID_TODT    ,
                                            CUM_MAXM_SESS    ,
                                            CUM_CURR_SESS    ,
                                            CUM_USER_SUSP    ,
                                            CUM_PSWD_DATE    ,
                                            CUM_USER_EMAIL     ,
                                            CUM_USER_TYPE,
                                            CUM_CORP_CODE, 
                                            CUM_CALLCENTER_CODE,
                                            CUM_ACCESS_FLAG ,
                                            CUM_INS_USER        ,
                                            CUM_LUPD_USER      )
                                VALUES    (    userpin,
                                            instcode,
                                            usercode,
                                            pswd,
                                            username,
                                            brancode,
                                            validfrom,
                                            validto,
                                            1,
                                            0,
                                            usersusp,
                                            SYSDATE-(v_cip_param_value+1),    --added on 03-07-02... (v_cip_param_value+1) days reduced from sysdate beacuse at the first login, the difference between login date
                                            email,
                                            prm_user_type,        
                                            prm_callcenter_id    ,
                                            prm_corp_id        ,
                                            prm_access_flag ,
                                            lupduser,                        --and the password date should turn out to be greater than or equal to the parameter value
                                            lupduser);    
                                END IF;    
                                            
                                                                            --so as to pop up a message to change the password
                ELSIF prm_user_type = 1 THEN

                        SELECT COUNT(1) INTO v_count FROM CMS_USER_MAST_CORPORATE --Added By Abhijit for duplicate check
                        WHERE cum_user_name=username;
                        
        
                            IF v_count > 0 THEN
                                     errmsg := 'User Id '''|| usercode ||''' already exists ';
                                   RETURN;
        
                            ELSE  --Added by Abhijit on 09-FEB-05
        
                                INSERT INTO CMS_USER_MAST_CORPORATE
                                        (    CUM_USER_PIN        ,
                                            CUM_INST_CODE         ,
                                            CUM_USER_CODE       ,
                                            CUM_ENCR_PSWD    ,
                                            CUM_USER_NAME    ,
                                            --CUM_BRAN_CODE       ,
                                            CUM_VALID_FRDT    ,
                                            CUM_VALID_TODT    ,
                                            CUM_MAXM_SESS    ,
                                            CUM_CURR_SESS    ,
                                            CUM_USER_SUSP    ,
                                            CUM_PSWD_DATE    ,
                                            CUM_USER_EMAIL     ,
                                            CUM_USER_TYPE,
                                            CUM_CORP_CODE, 
                                            CUM_INS_USER        ,
                                            CUM_LUPD_USER      )
                                VALUES    (    userpin,
                                            instcode,
                                            usercode,
                                            pswd,
                                            username,
                                            --brancode,
                                            validfrom,
                                            validto,
                                            1,
                                            0,
                                            usersusp,
                                            SYSDATE-(v_cip_param_value+1),    --added on 03-07-02... (v_cip_param_value+1) days reduced from sysdate beacuse at the first login, the difference between login date
                                            email,
                                            prm_user_type,        
                                            prm_corp_id        ,
                                            lupduser,                        --and the password date should turn out to be greater than or equal to the parameter value
                                            lupduser);    
                            END IF;
                                
                    
                    -----------------------------------------------------------------------------------------------------------------
                    -- SN: commented on 21-OCT-2011 for creating call center users in user_mast instead of user_mast_callcenter table
                    -----------------------------------------------------------------------------------------------------------------                            
                 /*                
                 ELSIF prm_user_type = 2 THEN

                        SELECT COUNT(1) INTO v_count FROM CMS_USER_MAST_CALLCENTER --Added By Abhijit for duplicate check
                        WHERE cum_user_name=username;
                        
        
                            IF v_count > 0 THEN
                                     errmsg :='User Id '''|| usercode ||''' already exists ';
                                   RETURN;
        
                            ELSE  --Added by Abhijit on 09-FEB-05
        
                                INSERT INTO CMS_USER_MAST_CALLCENTER
                                        (    CUM_USER_PIN        ,
                                            CUM_INST_CODE         ,
                                            CUM_USER_CODE       ,
                                            CUM_ENCR_PSWD    ,
                                            CUM_USER_NAME    ,
                                            --CUM_BRAN_CODE       ,
                                            CUM_VALID_FRDT    ,
                                            CUM_VALID_TODT    ,
                                            CUM_MAXM_SESS    ,
                                            CUM_CURR_SESS    ,
                                            CUM_USER_SUSP    ,
                                            CUM_PSWD_DATE    ,
                                            CUM_USER_EMAIL     ,
                                            CUM_USER_TYPE,
                                            CUM_CALLCENTER_CODE,
                                            CUM_INS_USER        ,
                                            CUM_LUPD_USER      )
                                VALUES    (    userpin,
                                            instcode,
                                            usercode,
                                            pswd,
                                            username,
                                            --brancode,
                                            validfrom,
                                            validto,
                                            1,
                                            0,
                                            usersusp,
                                            SYSDATE-(v_cip_param_value+1),    --added on 03-07-02... (v_cip_param_value+1) days reduced from sysdate beacuse at the first login, the difference between login date
                                            email,
                                            prm_user_type,        
                                            prm_callcenter_id    ,
                                            lupduser,                        --and the password date should turn out to be greater than or equal to the parameter value
                                            lupduser);    
                            END IF;
                            
                    */ 
                    -----------------------------------------------------------------------------------------------------------------
                    -- EN: commented on 21-OCT-2011 for creating call center users in user_mast instead of user_mast_callcenter table
                    -----------------------------------------------------------------------------------------------------------------         
                                
                    ELSIF prm_user_type = 3 THEN

                        SELECT COUNT(1) INTO v_count FROM CMS_USER_MAST_MERCHANT --Added By Abhijit for duplicate check
                        WHERE cum_user_name=username;
                        
        
                            IF v_count > 0 THEN
                                     errmsg :='User Id '''|| usercode ||''' already exists ';
                                   RETURN;
        
                            ELSE  --Added by Abhijit on 09-FEB-05
        
                                INSERT INTO CMS_USER_MAST_MERCHANT
                                        (    CUM_USER_PIN        ,
                                            CUM_INST_CODE         ,
                                            CUM_USER_CODE       ,
                                            CUM_ENCR_PSWD    ,
                                            CUM_USER_NAME    ,
                                            CUM_VALID_FRDT    ,
                                            CUM_VALID_TODT    ,
                                            CUM_MAXM_SESS    ,
                                            CUM_CURR_SESS    ,
                                            CUM_USER_SUSP    ,
                                            CUM_PSWD_DATE    ,
                                            CUM_INS_DATE, 
                                            CUM_LUPD_DATE,
                                            CUM_USER_EMAIL     ,
                                            CUM_USER_TYPE,
                                            CUM_BRAN_CODE,
                                            CUM_INS_USER        ,
                                            CUM_LUPD_USER)
                                VALUES    (    userpin,
                                            instcode,
                                            usercode,
                                            pswd,
                                            username,
                                            validfrom,
                                            validto,
                                            1,
                                            0,
                                            usersusp,
                                            SYSDATE-(v_cip_param_value+1),    --added on 03-07-02... (v_cip_param_value+1) days reduced from sysdate beacuse at the first login, the difference between login date
                                            SYSDATE,
                                            SYSDATE,
                                            email,
                                            prm_user_type,    
                                            brancode,    
                                            lupduser,                        --and the password date should turn out to be greater than or equal to the parameter value
                                            lupduser);    
                            END IF;
                ELSE
                                errmsg := 'Not a valid user type';
                                RETURN;
                END IF;
                     
                    IF     errmsg = 'OK' THEN    

                    --insert into the tables cms_track_login which tracks erong logins
                            INSERT INTO CMS_TRACK_LOGIN
                                  (    CTL_INST_CODE        ,
                                     CTL_USER_PIN        ,
                                    CTL_WRONG_LOGINCNT    ,
                                    CTL_LOGIN_DATE ,
                                    CTL_INS_USER,
                                    CTL_INS_DATE    )
                         VALUES     (    instcode            ,
                                      userpin                ,
                                    0                    ,
                                    SYSDATE        ,
                                    lupduser,
                                    SYSDATE        );

                      --insert the encrypted password into the table cms_prev_pswds so as to keep a track of the previous passwords

                           INSERT INTO CMS_PREV_PSWDS
                                  (    CPP_INST_CODE        ,
                                     CPP_USER_PIN        ,
                                    CPP_PREV_PSWD        ,
                                    CPP_PSWD_DATE    ,
                                    CPP_INS_USER,
                                    CPP_INS_DATE    )
                         VALUES  (    instcode            ,
                                     userpin                ,
                                    pswd        ,
                                    SYSDATE        ,
                                    lupduser,
                                    SYSDATE        );


                        errmsg := 'OK';
                    END IF; --Added by Abhijit on 09-FEB-05

            EXCEPTION    --Main block Exception
                WHEN OTHERS THEN
                errmsg := ' Error Message '||SQLCODE||'---'||SQLERRM;
            END; --Added by Abhijit on 09-FEB-05

ELSE    --ELSE of If 1
    errmsg := 'Invalid input parameter';
    RETURN;
END IF;    --IF 1
EXCEPTION    --Main block Exception
    WHEN OTHERS THEN
    errmsg := 'Main Exception '||SQLCODE||'---'||SQLERRM;
END;        --Main Begin Block Ends Here /
/


