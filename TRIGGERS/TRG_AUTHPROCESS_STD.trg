CREATE OR REPLACE TRIGGER VMSCMS.trg_authprocess_std
AFTER INSERT ON cms_auth_process
FOR EACH ROW
DECLARE
V_EXEC_ORDER number(4);
CURSOR c1 IS 
        SELECT CBM_INST_BIN FROM CMS_BIN_MAST WHERE CBM_INST_CODE=:new.CAP_INST_CODE;

BEGIN --main begin
        
 FOR I IN c1 LOOP
        
        BEGIN
 
        SELECT to_number(max(cbp_order_execution))
                INTO   V_EXEC_ORDER
                FROM  cms_binauth_process where cbp_inst_code= :new.cap_inst_code and cbp_bin=I.CBM_INST_BIN;
             IF V_EXEC_ORDER IS NULL THEN
                V_EXEC_ORDER:=1;
             ELSE
                V_EXEC_ORDER:=V_EXEC_ORDER+1;
            END IF;
        
        END;
        Insert into cms_binauth_process
                           (cbp_inst_code,
                            cbp_bin,
                            cbp_process_key,
                            cbp_enable_flag,
                            cbp_class_process,
                            cbp_order_execution,
                            cbp_ins_date,cbp_lupd_date)
                         Values
                           (:new.cap_inst_code,
                           I.CBM_INST_BIN,
                           :new.cap_process_key,
                           'N',:new.cap_class_process,
                           V_EXEC_ORDER,
                           SYSDATE,
                           SYSDATE
                            );
END LOOP;
END; --main end
/


