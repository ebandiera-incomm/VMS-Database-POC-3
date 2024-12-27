create or replace PROCEDURE vmscms.sp_login_checks_callcenter (
   INSTCODE        IN       NUMBER,
   USERCODE        IN       VARCHAR2,
   
   LOGINPSWD       IN       VARCHAR2,
  
   
   DATEFORMATE     IN       VARCHAR2,
   LASTLOGINTIME   OUT      VARCHAR2,
   FLAGINT         OUT      NUMBER,

   ERRMSG          OUT      VARCHAR2
)
AS
   DUM                NUMBER (3);
   DAYS               NUMBER (3);
   V_CUM_USER_SUSP    CHAR (1);
   V_CUM_USER_CODE    CMS_USER_MAST_CALLCENTER.CUM_USER_CODE%TYPE;
   V_CUM_ENCR_PSWD    CMS_USER_MAST_CALLCENTER.CUM_ENCR_PSWD%TYPE;
   V_WRONG_LOGINS     CMS_INST_PARAM.CIP_PARAM_VALUE%TYPE;
   V_PSWD_CHANGE      CMS_INST_PARAM.CIP_PARAM_VALUE%TYPE;
   USERPIN            CMS_USER_MAST_CALLCENTER.CUM_USER_PIN%TYPE;
   V_CUM_VALID_FRDT   DATE;
   V_CUM_VALID_TODT   DATE;
   V_CUG_GROUP_CODE   CMS_USER_GROUP.CUG_GROUP_CODE%TYPE;
   V_CUG_GROUP_NAME   CMS_USER_GROUP.CUG_GROUP_NAME%TYPE;
   V_FORCE_PSWD       CMS_USER_MAST.CUM_FORCE_PSWD%TYPE;

BEGIN                                                             
   ERRMSG := 'OK';
   FLAGINT := 0;

   
   SELECT CUM_USER_SUSP, CUM_USER_CODE, CUM_USER_PIN, CUM_ENCR_PSWD,
          TRUNC (SYSDATE) - TRUNC (CUM_PSWD_DATE), CUM_VALID_FRDT,
          CUM_VALID_TODT,
          TO_CHAR (NVL (TO_DATE (CUM_LAST_LOGINTIME, 'dd-mon-yyyy hh24:mi:ss'),
                        SYSDATE
                       ),
                   DATEFORMATE || 'hh24:mi:ss'
                  ),
          CUM_FORCE_PSWD
                                        
     
   INTO   V_CUM_USER_SUSP, V_CUM_USER_CODE, USERPIN, V_CUM_ENCR_PSWD,
          DAYS, V_CUM_VALID_FRDT,
          V_CUM_VALID_TODT,
          LASTLOGINTIME,
          V_FORCE_PSWD
     FROM CMS_USER_MAST_CALLCENTER
    WHERE CUM_INST_CODE = INSTCODE

          AND UPPER (CUM_USER_CODE) = UPPER (USERCODE);

   IF ERRMSG = 'OK'
   THEN                                                                
      BEGIN                                                         
         SELECT CIP_PARAM_VALUE
           INTO V_WRONG_LOGINS
           FROM CMS_INST_PARAM
          WHERE CIP_INST_CODE = INSTCODE AND CIP_PARAM_KEY = 'WRONG PSWDS';

         SELECT CIP_PARAM_VALUE
           INTO V_PSWD_CHANGE
           FROM CMS_INST_PARAM
          WHERE CIP_INST_CODE = INSTCODE AND CIP_PARAM_KEY = 'PSWD CHANGE';

         IF LOGINPSWD != V_CUM_ENCR_PSWD
         THEN
            
            
            
            UPDATE CMS_TRACK_LOGIN
               SET CTL_WRONG_LOGINCNT = CTL_WRONG_LOGINCNT + 1,
                   CTL_LOGIN_DATE = SYSDATE
             WHERE CTL_INST_CODE = INSTCODE AND CTL_USER_PIN = USERPIN;

            ERRMSG := 'Wrong password, try one more time';
            FLAGINT := 0;
          
                SELECT CTL_WRONG_LOGINCNT
                  INTO DUM
                  FROM CMS_TRACK_LOGIN
                 WHERE CTL_INST_CODE = INSTCODE AND CTL_USER_PIN = USERPIN;

            
            





           
           
                   IF DUM >= V_WRONG_LOGINS
                   THEN
                      ERRMSG :=
                            V_WRONG_LOGINS
                         || ' continuous wrong passwords. User id is locked. Contact System Administrator';

                      UPDATE  CMS_USER_MAST_CALLCENTER
                         SET CUM_USER_SUSP = 'L',
                             
                             CUM_LUPD_USER = USERPIN
                       WHERE CUM_INST_CODE = INSTCODE AND CUM_USER_PIN = USERPIN;
                   ELSIF DUM = V_WRONG_LOGINS - 1
                   THEN
                      ERRMSG :=
                         'Your user id will be locked if you enter one more invalid password';
                   END IF;
               
            
            
          
         ELSE
      

    





            
            
               
          

            IF V_CUM_USER_SUSP = 'Y'
            THEN
               ERRMSG := 'User Already Logged on';
               FLAGINT := 1;
            ELSIF V_CUM_USER_SUSP = 'H'
            THEN
               ERRMSG := 'User on Hold';
               FLAGINT := 1;
            ELSIF V_CUM_USER_SUSP = 'L'
            THEN
               ERRMSG := 'User locked';
               FLAGINT := 1;
            ELSIF V_CUM_USER_SUSP = 'S'
            THEN
               ERRMSG := 'User is Suspended ';
               FLAGINT := 1;
            END IF;

            IF TRUNC (SYSDATE) NOT BETWEEN TRUNC (V_CUM_VALID_FRDT)
                                       AND TRUNC (V_CUM_VALID_TODT)
            THEN
               ERRMSG := 'User validity over';
               FLAGINT := 1;
            END IF;

            IF ERRMSG = 'OK'
            THEN
               UPDATE CMS_TRACK_LOGIN
                  SET CTL_WRONG_LOGINCNT = 0,
                      CTL_LOGIN_DATE = SYSDATE
                WHERE CTL_INST_CODE = INSTCODE AND CTL_USER_PIN = USERPIN;

              














                                         
            END IF;
         END IF;
    
      EXCEPTION                                                       
         WHEN OTHERS
         THEN
            ERRMSG := 'Excp 1 -- ' || SQLERRM;
            FLAGINT := 1;
      END;
     END IF; 
      IF ERRMSG = 'OK' THEN
      BEGIN
         UPDATE CMS_USER_MAST_CALLCENTER
            SET CUM_USER_SUSP = 'Y',
                CUM_LAST_LOGINTIME =
                TO_CHAR (SYSDATE, 'DD-MON-YYYY HH24:MI:SS')
                WHERE CUM_USER_PIN = USERPIN;
        EXCEPTION 
         WHEN OTHERS THEN
            ERRMSG := 'Excp 2 -- ' || SQLERRM;
            FLAGINT := 1;
         END; 
        END IF    ;   
          
EXCEPTION 
WHEN NO_DATA_FOUND THEN
  ERRMSG  := 'Wrong User Name\password, try one more time';
  FLAGINT := 1;
WHEN OTHERS THEN
  ERRMSG := 'Main Excp -- ' || SQLERRM;
END; 
/
show error