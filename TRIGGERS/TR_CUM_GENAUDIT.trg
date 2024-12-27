CREATE OR REPLACE TRIGGER VMSCMS.TR_CUM_GENAUDIT
AFTER  INSERT OR UPDATE OR DELETE ON VMSCMS.CMS_USER_MAST FOR EACH ROW
DECLARE

/************************************************************************************************************

    * Modified by      : Venkata Naga Sai.S
    * Modified Date    : 02-April-2019
    * Modified For     : VMS-843
    * Reviewer         : Saravanankumar
    * Build Number     : VMSR14_B0002 
	
*****************************************************************************************************************/

 ------------------------------------------------------------------------------------------------
 	ERRMSG  VARCHAR2(300) := '0K';
	v_seq_no NUMBER;
	v_tab_id   NUMBER(5);
	v_table_nm VARCHAR2(60);
	error_excption EXCEPTION;
	v_old_susp VARCHAR2(20); -- Sn added on 11 Sep 08 for proper status eg loged on / not logged on etc
	v_new_susp VARCHAR2(20);
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
				v_table_nm := 'CMS_USER_MAST';
        
        IF INSERTING THEN 
          v_inst_code:=:new.CUM_INST_CODE;
        ELSE
          v_inst_code:=:old.CUM_INST_CODE;
        END IF;
			-- Sn Check whether the table is present in audit master.
			BEGIN
				SELECT CGM_TABLE_ID INTO v_tab_id FROM CMS_GENAUDIT_MAST
				WHERE CGM_TABLE_NAME =  v_table_nm
				and   cgm_inst_code  = v_inst_code;
			EXCEPTION
			WHEN OTHERS THEN
		    ERRMSG  := 'Table '||v_table_nm|| ' not found in audit master '|| SUBSTR(SQLERRM,1,200);
			RAISE error_excption;
			END;
			-- En Check whether the table is present in audit master.
P_DTL_INFO(1).COL_NAME := 'CUM_USER_CODE'; -- NOT USED
P_DTL_INFO(2).COL_NAME := 'CUM_USER_NAME';
P_DTL_INFO(3).COL_NAME := 'CUM_BRAN_CODE';
P_DTL_INFO(4).COL_NAME := 'CUM_VALID_FRDT';
P_DTL_INFO(5).COL_NAME := 'CUM_VALID_TODT';
P_DTL_INFO(6).COL_NAME := 'CUM_MAXM_SESS';  -- NOT USED
P_DTL_INFO(7).COL_NAME := 'CUM_CURR_SESS'; -- NOT USED
P_DTL_INFO(8).COL_NAME := 'CUM_USER_SUSP';
P_DTL_INFO(9).COL_NAME := 'CUM_PSWD_DATE';
P_DTL_INFO(10).COL_NAME := 'CUM_INS_USER';
P_DTL_INFO(11).COL_NAME := 'CUM_INS_DATE';
P_DTL_INFO(12).COL_NAME := 'CUM_LUPD_USER';
P_DTL_INFO(13).COL_NAME := 'CUM_LUPD_DATE';
P_DTL_INFO(14).COL_NAME := 'CUM_LAST_LOGINTIME';
P_DTL_INFO(15).COL_NAME := 'CUM_ACCESS_FLAG';
P_DTL_INFO(16).COL_NAME := 'CUM_USER_EMAIL';
P_DTL_INFO(1).OLD_VAL := :OLD.CUM_USER_CODE;
P_DTL_INFO(2).OLD_VAL := :OLD.CUM_USER_NAME;
P_DTL_INFO(3).OLD_VAL := :OLD.CUM_BRAN_CODE;
P_DTL_INFO(4).OLD_VAL := :OLD.CUM_VALID_FRDT;
P_DTL_INFO(5).OLD_VAL := :OLD.CUM_VALID_TODT;
P_DTL_INFO(6).OLD_VAL := :OLD.CUM_MAXM_SESS;
P_DTL_INFO(7).OLD_VAL := :OLD.CUM_CURR_SESS;
SELECT DECODE (:OLD.cum_user_susp,
               'N', 'Not Logged On',
               'Y', 'Logged On/Suspended',
               'L', 'LOCKED',
               'H', 'On Hold',
			   'D', 'Deleted',
               :OLD.cum_user_susp
              )
			  INTO v_old_susp
  FROM DUAL;
P_DTL_INFO(8).OLD_VAL := v_old_susp ;
P_DTL_INFO(9).OLD_VAL := :OLD.CUM_PSWD_DATE;
P_DTL_INFO(10).OLD_VAL := :OLD.CUM_INS_USER;
P_DTL_INFO(11).OLD_VAL := :OLD.CUM_INS_DATE;
P_DTL_INFO(12).OLD_VAL := :OLD.CUM_LUPD_USER;
P_DTL_INFO(13).OLD_VAL := :OLD.CUM_LUPD_DATE;
P_DTL_INFO(14).OLD_VAL := :OLD.CUM_LAST_LOGINTIME;
P_DTL_INFO(15).OLD_VAL := :OLD.CUM_ACCESS_FLAG;
P_DTL_INFO(16).OLD_VAL := :OLD.CUM_USER_EMAIL;
P_DTL_INFO(1).NEW_VAL := :NEW.CUM_USER_CODE;
P_DTL_INFO(2).NEW_VAL := :NEW.CUM_USER_NAME;
P_DTL_INFO(3).NEW_VAL := :NEW.CUM_BRAN_CODE;
P_DTL_INFO(4).NEW_VAL := :NEW.CUM_VALID_FRDT;
P_DTL_INFO(5).NEW_VAL := :NEW.CUM_VALID_TODT;
P_DTL_INFO(6).NEW_VAL := :NEW.CUM_MAXM_SESS;
P_DTL_INFO(7).NEW_VAL := :NEW.CUM_CURR_SESS;
SELECT DECODE (:NEW.cum_user_susp,
               'N', 'Not Logged On',
               'Y', 'Logged On/Suspended',
               'L', 'LOCKED',
               'H', 'On Hold',
			   'D', 'Deleted',
               :NEW.cum_user_susp
              )
			  INTO v_new_susp
  FROM DUAL;
P_DTL_INFO(8).NEW_VAL := v_new_susp;
P_DTL_INFO(9).NEW_VAL := :NEW.CUM_PSWD_DATE;
P_DTL_INFO(10).NEW_VAL := :NEW.CUM_INS_USER;
P_DTL_INFO(11).NEW_VAL := :NEW.CUM_INS_DATE;
P_DTL_INFO(12).NEW_VAL := :NEW.CUM_LUPD_USER;
P_DTL_INFO(13).NEW_VAL := :NEW.CUM_LUPD_DATE;
P_DTL_INFO(14).NEW_VAL := :NEW.CUM_LAST_LOGINTIME;
P_DTL_INFO(15).NEW_VAL := :NEW.CUM_ACCESS_FLAG;
P_DTL_INFO(16).NEW_VAL := :NEW.CUM_USER_EMAIL;
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
				:NEW.CUM_INS_USER,
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
     IF (        ---Sn Check for Login Logout condition
				        (
						      (trim(:OLD.CUM_USER_SUSP) = 'N' AND trim(:NEW.CUM_USER_SUSP) = 'Y')            --- Sn  while Login status changes from 'N' to 'Y'
						       AND          --- Sn   last login time changes                                            Also if new user is added  last login time  is NULL  which changes on  login
					          ((:OLD.CUM_LAST_LOGINTIME <> :NEW.CUM_LAST_LOGINTIME)   OR  (:OLD.CUM_LAST_LOGINTIME IS NULL AND :NEW.CUM_LAST_LOGINTIME IS NOT NULL))
			             )
 		             OR
    				        ( (trim(:OLD.CUM_USER_SUSP) = 'Y' AND trim(:NEW.CUM_USER_SUSP) = 'N')           --- Sn  while Logout status changes from 'Y' to 'N'
				            AND (:OLD.CUM_LAST_LOGINTIME = :NEW.CUM_LAST_LOGINTIME) )                         --- Sn   last login time remains same
					) THEN
						 NULL;                  -- In the above case do nothing else log the changes
	ELSE
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
				:NEW.CUM_LUPD_USER ,
				'UPDATE',
				v_seq_no,
				ERRMSG );
			    IF ERRMSG <> 'OK' THEN
				ERRMSG  := 'From Upadte '|| ERRMSG;
			    RAISE error_excption;
			    END IF;
     END LOOP;
        -- En Loop based on PL/SQL Table for all the above mentioned columns
     END IF;    ---En Check for Login Logout condition
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
				:OLD.CUM_LUPD_USER,
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


