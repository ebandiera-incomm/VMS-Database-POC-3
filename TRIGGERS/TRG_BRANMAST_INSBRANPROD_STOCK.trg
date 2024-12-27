CREATE OR REPLACE TRIGGER VMSCMS.TRG_BRANMAST_INSBRANPROD_STOCK
AFTER INSERT
ON VMSCMS.CMS_BRAN_MAST FOR EACH ROW
DECLARE
 CURSOR c1 IS
        select CPC_INST_CODE,CPC_PROD_SNAME,CPC_INS_USER
        FROM   CMS_PROD_CCC;
V_REORDER_LEVEL         cms_inst_param.cip_param_value%type;
BEGIN --main begin
        --Sn select reorder level
          BEGIN
                SELECT cip_param_value
                INTO   V_REORDER_LEVEL
                FROM  CMS_INST_PARAM
                WHERE  cip_param_key = 'REORDER LEVEL'
                AND cip_inst_code=:new.cbm_inst_code;
          EXCEPTION
          WHEN NO_DATA_FOUND THEN
          RAISE_APPLICATION_ERROR(-20003,'REORDERLEVEL NOT DEFINED');
          END;
        --En select reorder level
 FOR I IN c1 LOOP
        Insert into CMS_BRANPROD_STOCK
                           (CBS_INST_CODE,
                            CBS_PROD_SNAME,
                            CBS_BRAN_CODE,
                            CBS_STOCK,
                            CBS_REORDER_LEVEL,
                            CBS_INS_USER,
                            CBS_LUPD_USER)
                         Values
                           (I.CPC_INST_CODE,
                            I.CPC_PROD_SNAME,
                            :new.cbm_bran_code,
                            NULL,
                            V_REORDER_LEVEL,
                            I.CPC_INS_USER,
                            I.CPC_INS_USER
                            );
END LOOP;
END; --main end
/


