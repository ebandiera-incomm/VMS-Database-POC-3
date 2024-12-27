CREATE OR REPLACE TRIGGER VMSCMS.TR_FEE_PRODCATG_GENAUDIT
AFTER  INSERT OR UPDATE OR DELETE ON VMSCMS.CMS_PRODCATTYPE_FEES FOR EACH ROW
DECLARE
 ------------------------------------------------------------------------------------------------
	ERRMSG  VARCHAR2(300) := '0K';
	v_seq_no NUMBER;
	v_tab_id   NUMBER(5);
	v_table_nm VARCHAR2(60);
	error_excption EXCEPTION;
  v_inst_code NUMBER(5);
 ------------------------------------------------------------------------------------------------
	TYPE REC_TR_INFO IS RECORD (
	COL_NAME   VARCHAR2(60),
	OLD_VAL       VARCHAR2(60),
	NEW_VAL      VARCHAR2(60) );
	TYPE TAB_DTL_INFO IS TABLE OF REC_TR_INFO
	INDEX BY BINARY_INTEGER;
	P_DTL_INFO    TAB_DTL_INFO;
---***********************************************************--SN Trigger body begins
BEGIN
        -- SN Initialize all table variables before itself
		v_table_nm := 'CMS_PRODCATTYPE_FEES'  ;
    
    IF INSERTING THEN
      v_inst_code := :new.CPF_INST_CODE;
    ELSE
     v_inst_code := :old.CPF_INST_CODE;
    END IF;
    
		-- Sn Check whether the table is present in audit master.
		BEGIN
			SELECT CGM_TABLE_ID INTO v_tab_id FROM CMS_GENAUDIT_MAST
			WHERE CGM_TABLE_NAME =  v_table_nm 
			AND   CGM_INST_CODE  = v_inst_code;
		EXCEPTION
		WHEN OTHERS THEN
		ERRMSG  := 'Table '||v_table_nm|| ' not found in audit master '|| SUBSTR(SQLERRM,1,200);
		RAISE error_excption;
		END;
		-- En Check whether the table is present in audit master.
P_DTL_INFO(1).COL_NAME := 'CPF_PROD_CODE';
P_DTL_INFO(2).COL_NAME := 'CPF_CARD_TYPE';
P_DTL_INFO(3).COL_NAME := 'CPF_FEE_CODE';
P_DTL_INFO(4).COL_NAME := 'CPF_VALID_FROM';
P_DTL_INFO(5).COL_NAME := 'CPF_VALID_TO';
P_DTL_INFO(6).COL_NAME := 'CPF_INS_USER';
P_DTL_INFO(7).COL_NAME := 'CPF_INS_DATE';
P_DTL_INFO(8).COL_NAME := 'CPF_LUPD_USER';
P_DTL_INFO(9).COL_NAME := 'CPF_LUPD_DATE';
P_DTL_INFO(1).OLD_VAL := :OLD.CPF_PROD_CODE;
P_DTL_INFO(2).OLD_VAL := :OLD.CPF_CARD_TYPE;
P_DTL_INFO(3).OLD_VAL := :OLD.CPF_FEE_CODE;
P_DTL_INFO(4).OLD_VAL := :OLD.CPF_VALID_FROM;
P_DTL_INFO(5).OLD_VAL := :OLD.CPF_VALID_TO;
P_DTL_INFO(6).OLD_VAL := :OLD.CPF_INS_USER;
P_DTL_INFO(7).OLD_VAL := :OLD.CPF_INS_DATE;
P_DTL_INFO(8).OLD_VAL := :OLD.CPF_LUPD_USER;
P_DTL_INFO(9).OLD_VAL := :OLD.CPF_LUPD_DATE;
P_DTL_INFO(1).NEW_VAL := :NEW.CPF_PROD_CODE;
P_DTL_INFO(2).NEW_VAL := :NEW.CPF_CARD_TYPE;
P_DTL_INFO(3).NEW_VAL := :NEW.CPF_FEE_CODE;
P_DTL_INFO(4).NEW_VAL := :NEW.CPF_VALID_FROM;
P_DTL_INFO(5).NEW_VAL := :NEW.CPF_VALID_TO;
P_DTL_INFO(6).NEW_VAL := :NEW.CPF_INS_USER;
P_DTL_INFO(7).NEW_VAL := :NEW.CPF_INS_DATE;
P_DTL_INFO(8).NEW_VAL := :NEW.CPF_LUPD_USER;
P_DTL_INFO(9).NEW_VAL := :NEW.CPF_LUPD_DATE;
	 -- EN Initialize all table variables before itself
--$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$
---***********************  trigger  for INSERT ***************
IF INSERTING  THEN
    -- SELECT  NVL(MAX(seq),0)+1 INTO v_seq_no  FROM CMS_AUDIT_INFO;
	SELECT SEQ_AUDIT_NO.NEXTVAL INTO  v_seq_no FROM dual;
             -- Sn Loop based on PL/SQL Table for all the above mentioned columns
	 FOR T IN 1 .. P_DTL_INFO.COUNT
     LOOP
	            Sp_Populate_Audit
				(v_inst_code,
        v_tab_id,
				P_DTL_INFO(T).COL_NAME ,
				NULL  ,
				P_DTL_INFO(T).NEW_VAL ,
				:NEW.CPF_INS_USER ,
				'INSERT',
				v_seq_no,
				ERRMSG );
			    IF ERRMSG <> 'OK' THEN
				ERRMSG  := 'From Insert '|| ERRMSG;
			    RAISE error_excption;
			    END IF;
     END LOOP;
        -- En Loop based on PL/SQL Table for all the above mentioned columns
END IF;
---*********************** trigger  for INSERT ***************
---***********************  trigger  for UPDATE ***************
IF UPDATING THEN
     --SELECT  NVL(MAX(seq),0)+1 INTO v_seq_no  FROM CMS_AUDIT_INFO;
	 	SELECT SEQ_AUDIT_NO.NEXTVAL INTO  v_seq_no FROM dual;
             -- Sn Loop based on PL/SQL Table for all the above mentioned columns
	 FOR T IN 1 .. P_DTL_INFO.COUNT
     LOOP
	            Sp_Populate_Audit
				(v_inst_code,
        v_tab_id,
				P_DTL_INFO(T).COL_NAME ,
				P_DTL_INFO(T).OLD_VAL ,
				P_DTL_INFO(T).NEW_VAL ,
				:NEW.CPF_LUPD_USER,
				'UPDATE',
				v_seq_no,
				ERRMSG );
			    IF ERRMSG <> 'OK' THEN
				ERRMSG  := 'From Upadte '|| ERRMSG;
			    RAISE error_excption;
			    END IF;
     END LOOP;
        -- En Loop based on PL/SQL Table for all the above mentioned columns
END IF;
---***********************  trigger  for UPDATE ***************
---***********************  trigger  for DELETE ***************
IF DELETING  THEN
     --SELECT  NVL(MAX(seq),0)+1 INTO v_seq_no  FROM CMS_AUDIT_INFO;
	 	SELECT SEQ_AUDIT_NO.NEXTVAL INTO  v_seq_no FROM dual;
             -- Sn Loop based on PL/SQL Table for all the above mentioned columns
	 FOR T IN 1 .. P_DTL_INFO.COUNT
     LOOP
	            Sp_Populate_Audit
				(v_inst_code,
        v_tab_id,
				P_DTL_INFO(T).COL_NAME ,
				P_DTL_INFO(T).OLD_VAL   ,
				NULL ,
				:OLD.CPF_LUPD_USER,
				'DELETE',
				v_seq_no,
				ERRMSG );
			    IF ERRMSG <> 'OK' THEN
				ERRMSG  := 'From Delete '|| ERRMSG;
			    RAISE error_excption;
			    END IF;
     END LOOP;
        -- En Loop based on PL/SQL Table for all the above mentioned columns
END IF;
---***********************  trigger  for DELETE ***************
--$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$
----***********************************************************--SN Trigger body ENDS
EXCEPTION
WHEN error_excption THEN
RAISE_APPLICATION_ERROR(-20001, 'Error - '|| ERRMSG);
WHEN OTHERS THEN
ERRMSG  := 'Main Error  - '||SUBSTR(SQLERRM,1,250);
RAISE_APPLICATION_ERROR(-20002, ERRMSG);
END;
/


