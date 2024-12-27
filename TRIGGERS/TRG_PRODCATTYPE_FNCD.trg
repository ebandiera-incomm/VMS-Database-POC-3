CREATE OR REPLACE TRIGGER VMSCMS.TRG_PRODCATTYPE_FNCD
BEFORE INSERT  ON VMSCMS.CMS_PRODCATTYPE_FEES FOR EACH ROW
DECLARE

v_delivery_channel  CMS_FEE_MAST.CFM_DELIVERY_CHANNEL%TYPE; 
v_tran_code CMS_FEE_MAST.CFM_TRAN_CODE%TYPE;
v_tran_mode  CMS_FEE_MAST.CFM_TRAN_MODE%TYPE;

v_fun_code  CMS_FUNC_MAST.CFM_FUNC_CODE%TYPE;
 
BEGIN    --SN Trigger body begins                 
     
     BEGIN                 
                                
        IF (TRIM(:NEW.CPF_FEE_CODE) IS NOT NULL)  THEN
            BEGIN
                           SELECT  CFM_DELIVERY_CHANNEL, CFM_TRAN_CODE, CFM_TRAN_MODE
                           INTO v_delivery_channel, v_tran_code, v_tran_mode
                           FROM CMS_FEE_MAST
                           WHERE CFM_FEE_CODE = :NEW.CPF_FEE_CODE;
            EXCEPTION
            WHEN NO_DATA_FOUND THEN
            :NEW.CPF_FUNC_CODE := 'DEF';
            WHEN OTHERS THEN
            :NEW.CPF_FUNC_CODE := 'DEF';
            END;       
                 
            BEGIN
                             SELECT CFM_FUNC_CODE
                             INTO  v_fun_code 
                             FROM CMS_FUNC_MAST
                             WHERE CFM_TXN_CODE = v_tran_code
                             AND CFM_TXN_MODE =  v_tran_mode
                             AND CFM_DELIVERY_CHANNEL = v_delivery_channel ;
                             
                             :NEW.CPF_FUNC_CODE := v_fun_code;
            EXCEPTION
            WHEN NO_DATA_FOUND THEN
            :NEW.CPF_FUNC_CODE := 'DEF';
            WHEN OTHERS THEN
            :NEW.CPF_FUNC_CODE := 'DEF';
            END;     
     ELSE
            :NEW.CPF_FUNC_CODE := 'DEF';
    END IF;
                       
       EXCEPTION         
       WHEN OTHERS THEN
      :NEW.CPF_FUNC_CODE := 'DEF';
       END;         
EXCEPTION
WHEN OTHERS THEN
RAISE_APPLICATION_ERROR(-20001, 'Error While generating function code '||SQLERRM);
END;        --E
/


