CREATE OR REPLACE PROCEDURE VMSCMS.Prc_User_Prepswdchk
( prm_Login_id  IN VARCHAR2,
  prm_login_pswd  IN VARCHAR2,
  prm_trans_pswd  IN VARCHAR2,
  prm_err_msg  OUT VARCHAR2
)
AS
/*************************************************
     * VERSION             :  1.0
     * Created Date       : 10/Dec/2009..
     * Created By        : Mahesh.P.
     * PURPOSE          : Previous Password Check.
     * Modified By:    :   Ewan Drego
     * Modified Date  : Monday, June 07, 2010 12:46:18 PM
     * Reviewer      :
 *************************************************/

 v_inst  NUMBER := 1;
 v_passhist   NUMBER;


CURSOR cur_login_pswd(v_passhis NUMBER) IS 
SELECT CPH_OLD_PSWD FROM
(SELECT CPH_OLD_PSWD
  FROM
  CMS_PSWD_HIST,CMS_USERDETL_MAST
  WHERE
  CPH_USER_CODE=CUM_USER_CODE
  AND CUM_LGIN_CODE=prm_Login_id
  AND CPH_PSWD_TYPE=1
  ORDER BY CPH_INS_DATE DESC
)WHERE ROWNUM<=v_passhist  ;

CURSOR cur_trans_pswd(v_passhis NUMBER) IS 
SELECT CPH_OLD_PSWD FROM
(SELECT CPH_OLD_PSWD
  FROM
  CMS_PSWD_HIST,CMS_USERDETL_MAST
  WHERE
  CPH_USER_CODE=CUM_USER_CODE
  AND CUM_LGIN_CODE=prm_Login_id
  AND CPH_PSWD_TYPE=2
  ORDER BY CPH_INS_DATE DESC
)WHERE ROWNUM<=v_passhist  ;

 BEGIN
prm_err_msg:='OK';


--sn : Password History Count Check Based on FI Level Parameters : Defect Id :    0004746  , Modified by : Ewan Drego,Date :Monday, June 07, 2010 12:46:18 PM
BEGIN

BEGIN
              SELECT  TO_NUMBER(parmmast.CIP_PARAM_VALUE )   INTO v_passhist
        FROM          cms_INST_PARAM parmmast ,    cms_USER_INST userinst ,
                      cms_USERDETL_MAST usermast , cms_INST_MAST instmast
        WHERE            parmmast.CIP_PARAM_KEY = 'PREVPASSWORD'
        AND              usermast.CUM_LGIN_CODE = prm_Login_id
        AND              parmmast.CIP_INST_CODE = userinst.CUI_INST_CODE
        AND              userinst.CUI_USER_CODE  =usermast.CUM_USER_CODE
        AND              instmast.CIM_INST_CODE = userinst.CUI_INST_CODE
        --AND              instmast.cgi_INST_STUS  = 1
        AND              userinst.CUI_DFLT_INST = 1;
EXCEPTION
         WHEN NO_DATA_FOUND THEN
                SELECT      TO_NUMBER(parmmast.CIP_PARAM_VALUE )  INTO v_passhist
                FROM         cms_INST_PARAM parmmast , cms_INST_MAST instmast
                WHERE        parmmast.CIP_PARAM_KEY = 'PREVPASSWORD'
                --AND          instmast.cgi_DEFT_INST = 1
                AND          instmast.CIM_INST_CODE = parmmast.CIP_INST_CODE ;
        END ;



--en : Password History Count Check Based on FI Level Parameters : Defect Id :    0004746  , Modified by : Ewan Drego,Date :Monday, June 07, 2010 12:46:18 PM

      IF prm_login_pswd IS NOT NULL
                THEN
                      FOR i IN cur_login_pswd(v_passhist)
                      LOOP
                      BEGIN
                           IF prm_login_pswd=i.CPH_OLD_PSWD
                           THEN
                           prm_err_msg:='PresentinLoginList_'  || v_passhist;
                           RETURN;
                           END IF;
                      EXCEPTION

                               WHEN OTHERS
                               THEN prm_err_msg:='DataBaseError';
                      END;
                      END LOOP;
                END IF;
         IF prm_trans_pswd IS NOT NULL
                THEN
                      FOR i IN cur_trans_pswd(v_passhist)
                      LOOP
                      BEGIN
                      IF prm_trans_pswd=i.CPH_OLD_PSWD
                      THEN
                      prm_err_msg:='PresentinTransactionList_'  ||  v_passhist;
                      RETURN;
                      END IF;
                      EXCEPTION

                               WHEN OTHERS
                               THEN prm_err_msg:='DataBaseError';
                      END;
                      END LOOP;
         END IF;

EXCEPTION
                       WHEN OTHERS
                       THEN prm_err_msg:='DataBaseError';
END;

END;
/


