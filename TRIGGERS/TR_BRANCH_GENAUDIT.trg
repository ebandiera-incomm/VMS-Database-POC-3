CREATE OR REPLACE TRIGGER VMSCMS.TR_BRANCH_GENAUDIT
AFTER  INSERT OR UPDATE OR DELETE ON VMSCMS.CMS_BRAN_MAST FOR EACH ROW
DECLARE
 ------------------------------------------------------------------------------------------------
	ERRMSG  VARCHAR2(300) := '0K';
	v_seq_no NUMBER;
	v_tab_id   NUMBER(5);
	v_table_nm VARCHAR2(60);
	error_excption EXCEPTION;

 ------------------------------------------------------------------------------------------------

	TYPE REC_TR_INFO IS RECORD (
	COL_NAME   VARCHAR2(60),
	OLD_VAL       VARCHAR2(60),
	NEW_VAL      VARCHAR2(60) );
  v_inst_code   NUMBER(5);
	TYPE TAB_DTL_INFO IS TABLE OF REC_TR_INFO
	INDEX BY BINARY_INTEGER;

	P_DTL_INFO    TAB_DTL_INFO;
---***********************************************************--SN Trigger body begins
BEGIN
        -- SN Initialize all table variables before itself

		v_table_nm := 'CMS_BRAN_MAST' ;
    
    IF INSERTING THEN
      v_inst_code := :NEW.CBM_INST_CODE;
    ELSE
      v_inst_code := :OLD.CBM_INST_CODE;
    END IF;
		-- Sn Check whether the table is present in audit master.
		BEGIN
			SELECT CGM_TABLE_ID INTO v_tab_id FROM CMS_GENAUDIT_MAST
			WHERE CGM_TABLE_NAME =  v_table_nm
      AND cgm_inst_code    =  v_inst_code;
		EXCEPTION
		WHEN OTHERS THEN
		ERRMSG  := 'Table '||v_table_nm|| ' not found in audit master '|| SUBSTR(SQLERRM,1,200);
		RAISE error_excption;
		END;
		-- En Check whether the table is present in audit master.


P_DTL_INFO(1).COL_NAME := 'CBM_CNTRY_CODE';
P_DTL_INFO(2).COL_NAME := 'CBM_STATE_CODE';
P_DTL_INFO(3).COL_NAME := 'CBM_BRAN_CODE';
P_DTL_INFO(4).COL_NAME := 'CBM_BRAN_FIID';
P_DTL_INFO(5).COL_NAME := 'CBM_MICR_NO';
P_DTL_INFO(6).COL_NAME := 'CBM_BRAN_LOCN';
P_DTL_INFO(7).COL_NAME := 'CBM_ADDR_ONE';
P_DTL_INFO(8).COL_NAME := 'CBM_ADDR_TWO';
P_DTL_INFO(9).COL_NAME := 'CBM_ADDR_THREE';
P_DTL_INFO(10).COL_NAME := 'CBM_CITY_CODE';
P_DTL_INFO(11).COL_NAME := 'CBM_PIN_CODE';
P_DTL_INFO(12).COL_NAME := 'CBM_PHON_ONE';
P_DTL_INFO(13).COL_NAME := 'CBM_PHON_TWO';
P_DTL_INFO(14).COL_NAME := 'CBM_PHON_THREE';
P_DTL_INFO(15).COL_NAME := 'CBM_CONT_PRSN';
P_DTL_INFO(16).COL_NAME := 'CBM_FAX_NO';
P_DTL_INFO(17).COL_NAME := 'CBM_EMAIL_ID';
P_DTL_INFO(18).COL_NAME := 'CBM_INS_USER';
P_DTL_INFO(19).COL_NAME := 'CBM_INS_DATE';
P_DTL_INFO(20).COL_NAME := 'CBM_LUPD_USER';
P_DTL_INFO(21).COL_NAME := 'CBM_LUPD_DATE';
--P_DTL_INFO(22).COL_NAME := 'CBM_LOCN_CODE';


P_DTL_INFO(1).OLD_VAL := :OLD.CBM_CNTRY_CODE;
P_DTL_INFO(2).OLD_VAL := :OLD.CBM_STATE_CODE;
P_DTL_INFO(3).OLD_VAL := :OLD.CBM_BRAN_CODE;
P_DTL_INFO(4).OLD_VAL := :OLD.CBM_BRAN_FIID;
P_DTL_INFO(5).OLD_VAL := :OLD.CBM_MICR_NO;
P_DTL_INFO(6).OLD_VAL := :OLD.CBM_BRAN_LOCN;
P_DTL_INFO(7).OLD_VAL := :OLD.CBM_ADDR_ONE;
P_DTL_INFO(8).OLD_VAL := :OLD.CBM_ADDR_TWO;
P_DTL_INFO(9).OLD_VAL := :OLD.CBM_ADDR_THREE;
P_DTL_INFO(10).OLD_VAL := :OLD.CBM_CITY_CODE;
P_DTL_INFO(11).OLD_VAL := :OLD.CBM_PIN_CODE;
P_DTL_INFO(12).OLD_VAL := :OLD.CBM_PHON_ONE;
P_DTL_INFO(13).OLD_VAL := :OLD.CBM_PHON_TWO;
P_DTL_INFO(14).OLD_VAL := :OLD.CBM_PHON_THREE;
P_DTL_INFO(15).OLD_VAL := :OLD.CBM_CONT_PRSN;
P_DTL_INFO(16).OLD_VAL := :OLD.CBM_FAX_NO;
P_DTL_INFO(17).OLD_VAL := :OLD.CBM_EMAIL_ID;
P_DTL_INFO(18).OLD_VAL := :OLD.CBM_INS_USER;
P_DTL_INFO(19).OLD_VAL := :OLD.CBM_INS_DATE;
P_DTL_INFO(20).OLD_VAL := :OLD.CBM_LUPD_USER;
P_DTL_INFO(21).OLD_VAL := :OLD.CBM_LUPD_DATE;
--P_DTL_INFO(22).OLD_VAL := :OLD.CBM_LOCN_CODE;



P_DTL_INFO(1).NEW_VAL := :NEW.CBM_CNTRY_CODE;
P_DTL_INFO(2).NEW_VAL := :NEW.CBM_STATE_CODE;
P_DTL_INFO(3).NEW_VAL := :NEW.CBM_BRAN_CODE;
P_DTL_INFO(4).NEW_VAL := :NEW.CBM_BRAN_FIID;
P_DTL_INFO(5).NEW_VAL := :NEW.CBM_MICR_NO;
P_DTL_INFO(6).NEW_VAL := :NEW.CBM_BRAN_LOCN;
P_DTL_INFO(7).NEW_VAL := :NEW.CBM_ADDR_ONE;
P_DTL_INFO(8).NEW_VAL := :NEW.CBM_ADDR_TWO;
P_DTL_INFO(9).NEW_VAL := :NEW.CBM_ADDR_THREE;
P_DTL_INFO(10).NEW_VAL := :NEW.CBM_CITY_CODE;
P_DTL_INFO(11).NEW_VAL := :NEW.CBM_PIN_CODE;
P_DTL_INFO(12).NEW_VAL := :NEW.CBM_PHON_ONE;
P_DTL_INFO(13).NEW_VAL := :NEW.CBM_PHON_TWO;
P_DTL_INFO(14).NEW_VAL := :NEW.CBM_PHON_THREE;
P_DTL_INFO(15).NEW_VAL := :NEW.CBM_CONT_PRSN;
P_DTL_INFO(16).NEW_VAL := :NEW.CBM_FAX_NO;
P_DTL_INFO(17).NEW_VAL := :NEW.CBM_EMAIL_ID;
P_DTL_INFO(18).NEW_VAL := :NEW.CBM_INS_USER;
P_DTL_INFO(19).NEW_VAL := :NEW.CBM_INS_DATE;
P_DTL_INFO(20).NEW_VAL := :NEW.CBM_LUPD_USER;
P_DTL_INFO(21).NEW_VAL := :NEW.CBM_LUPD_DATE;
--P_DTL_INFO(22).NEW_VAL := :NEW.CBM_LOCN_CODE;


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
				:NEW.CBM_INS_USER ,
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
				:NEW.CBM_LUPD_USER,
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
				:OLD.CBM_LUPD_USER,
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


