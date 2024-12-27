CREATE OR REPLACE TRIGGER VMSCMS."TRG_PRODCCC_INSBRANPROD_STOCK" 
AFTER INSERT
ON VMSCMS.CMS_PROD_CCC FOR EACH ROW
DECLARE
 CURSOR c1 IS
        select CBM_INST_CODE,CBM_BRAN_CODE,CBM_INS_USER,
               CBM_LUPD_USER
        FROM   CMS_BRAN_MAST
        WHERE  cbm_inst_code = :NEW.cpc_inst_code  ;
V_REORDER_LEVEL         cms_inst_param.cip_param_value%type;
BEGIN --main begin
        --Sn select reorder level
          BEGIN
                SELECT cip_param_value
                INTO   V_REORDER_LEVEL
                FROM  CMS_INST_PARAM
                WHERE  cip_param_key = 'REORDER LEVEL'
                AND    cip_inst_code = :NEW.cpc_inst_code;
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
                           (I.CBM_INST_CODE,
                            :new.cpc_prod_sname,
                            I.CBM_BRAN_CODE,
                            NULL,
                            V_REORDER_LEVEL,
                            I.CBM_INS_USER,
                            I.CBM_INS_USER
                            );
END LOOP;
END; --main end
/


