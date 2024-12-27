CREATE OR REPLACE TRIGGER VMSCMS.TRG_BINMASTAUTHPROCESS_STD
AFTER INSERT
ON VMSCMS.CMS_BIN_MAST REFERENCING NEW AS NEW OLD AS OLD
FOR EACH ROW
DECLARE
V_EXEC_ORDER number(4);
V_PROCESS_KEY varchar2(20);
V_PROCESS_VALUE varchar2(100);
CURSOR c1 IS
        SELECT CAP_PROCESS_KEY,CAP_CLASS_PROCESS FROM CMS_AUTH_PROCESS WHERE CAP_INST_CODE=:new.CBM_INST_CODE;

BEGIN --main begin

 FOR I IN c1 LOOP

        BEGIN

        SELECT to_number(max(cbp_order_execution))
                INTO   V_EXEC_ORDER
                FROM  cms_binauth_process where cbp_inst_code= :new.cbm_inst_code and cbp_bin=:new.CBM_INST_BIN;
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
                           (:new.CBM_INST_CODE,
                           :new.CBM_INST_BIN,
                           I.CAP_PROCESS_KEY,
                           'N',I.CAP_CLASS_PROCESS,
                           V_EXEC_ORDER,
                           SYSDATE,
                           SYSDATE
                            );
END LOOP;
END; --main end
/


