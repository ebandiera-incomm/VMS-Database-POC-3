create or replace
TRIGGER VMSCMS.TRG_PRODAUTHPROCESS_STD 
AFTER INSERT
ON vmscms.cms_prod_cattype
REFERENCING NEW AS NEW OLD AS OLD
FOR EACH ROW
DECLARE
V_EXEC_ORDER number(4);
V_PROCESS_KEY varchar2(20);
V_PROCESS_VALUE varchar2(100);
CURSOR c1 IS
        SELECT CAP_PROCESS_KEY,CAP_CLASS_PROCESS FROM CMS_AUTH_PROCESS WHERE CAP_INST_CODE=:new.CPC_INST_CODE;

BEGIN --main begin

 FOR I IN c1 LOOP

        BEGIN

        SELECT to_number(max(VPP_order_execution))
                INTO   V_EXEC_ORDER
                FROM  vms_prod_auth_process where VPP_inst_code= :new.CPC_INST_CODE and VPP_PROD_CODE=:new.CPC_PROD_CODE and VPP_CARD_TYPE=:new.CPC_CARD_TYPE;
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
                           (:new.CPC_INST_CODE,
                           :new.CPC_PROD_CODE,
                           :new.CPC_CARD_TYPE,
                           I.CAP_PROCESS_KEY,
                           'N',
                           I.CAP_CLASS_PROCESS,
                           V_EXEC_ORDER,
                           SYSDATE,
                           :new.CPC_INS_USER
                            );
END LOOP;
END; --main end 

/
show error;