create or replace
TRIGGER VMSCMS.TRG_PROD_AUTHPROCESS_STD 
AFTER INSERT ON vmscms.cms_auth_process
FOR EACH ROW
DECLARE
V_EXEC_ORDER number(4);
CURSOR c1 IS 
        SELECT CPC_PROD_CODE,CPC_CARD_TYPE FROM CMS_PROD_CATTYPE WHERE 
        Cpc_INST_CODE=:new.CAP_INST_CODE;

BEGIN --main begin
        
 FOR I IN c1 LOOP
        
        BEGIN
 
        SELECT to_number(max(vpp_order_execution))
                INTO   V_EXEC_ORDER
                FROM  vms_prod_auth_process where vpp_inst_code= :new.cap_inst_code and 
               vpp_prod_code=i.cpc_prod_code and vpp_card_type=i.cpc_card_type;
               
             IF V_EXEC_ORDER IS NULL THEN
                V_EXEC_ORDER:=1;
             ELSE
                V_EXEC_ORDER:=V_EXEC_ORDER+1;
            END IF;
        
        END;
        
        
        Insert into vms_prod_auth_process
                           (vpp_inst_code,
                            VPP_PROD_CODE,
                            VPP_CARD_TYPE,
                            vpp_process_key,
                            vpp_enable_flag,
                            vpp_class_process,
                            vpp_order_execution,
                            vpp_ins_date,
                            vpp_ins_user
                            )
                         Values
                           (:new.cap_INST_CODE,
                           i.CPC_PROD_CODE,
                           i.CPC_CARD_TYPE,
                           :new.CAP_PROCESS_KEY,
                           'N',
                           :new.CAP_CLASS_PROCESS,
                           V_EXEC_ORDER,
                           SYSDATE,
                           1
                            );
END LOOP;
END; --main end


/
show error;