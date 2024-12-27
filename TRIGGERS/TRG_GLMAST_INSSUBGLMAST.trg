CREATE OR REPLACE TRIGGER VMSCMS.TRG_GLMAST_INSSUBGLMAST
AFTER INSERT
ON VMSCMS.CMS_GL_MAST FOR EACH ROW
DISABLE
DECLARE
 CURSOR c1 IS
        select CPC_INST_CODE,CPC_PROD_SNAME
        FROM   CMS_PROD_CCC;
V_SUBGL_CODE         cms_inst_param.cip_param_value%type;
BEGIN --main begin
        --Sn select reorder level
          BEGIN
                SELECT NVL(MAX(CSM_SUBGL_CODE),0) + 1
                INTO   V_SUBGL_CODE
                FROM  CMS_SUB_GL_MAST
                WHERE  CSM_GL_CODE    = :NEW.CGM_GL_CODE
                AND    CSM_GLCATG_CODE =:NEW.CGM_CATG_CODE ;
          EXCEPTION
          WHEN NO_DATA_FOUND THEN        
          RAISE_APPLICATION_ERROR(-20003,'GL CODE IS ' ||:NEW.CGM_GL_CODE || 'Is not defined in Master' );
          END;
        --En select reorder level
 FOR I IN c1 LOOP
        Insert into CMS_SUB_GL_MAST
                           (CSM_INST_CODE,
                            CSM_GL_CODE,
                            CSM_GLCATG_CODE,
                            CSM_SUBGL_CODE,
                            CSM_SUBGL_DESC,
                            CSM_INS_DATE,
                            CSM_LUPD_USER,
                            CSM_LUPD_DATE--,
                            --CSM_CHILD_FLAG 
                            )
                         Values
                           (I.CPC_INST_CODE,
                            :NEW.CGM_GL_CODE,
                            :NEW.CGM_CATG_CODE,
                            V_SUBGL_CODE ,
                            I.CPC_PROD_SNAME,                            
                            :NEW.CGM_INS_DATE,
                            :NEW.CGM_LUPD_USER,
                           -- :NEW.CGM_LUPD_DATE--,
                           sysdate
--                            :NEW.CGM_CHILD_FLAG 
                            );
                            
                            V_SUBGL_CODE := V_SUBGL_CODE + 1;
END LOOP;
END; --main endAddFuncCode.jsp
/


