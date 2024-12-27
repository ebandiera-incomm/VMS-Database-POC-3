CREATE OR REPLACE PACKAGE VMSCMS.Pack_Emboss_Ops
 IS
 PROCEDURE Sp_Mark_Batch_Status (
 INSTCODE NUMBER ,
 EVENT NUMBER,
 BATCH_ID_IN NUMBER,
 TOTAL_RECORDS NUMBER ,
 BATCH_STATUS NUMBER,
 USERPIN NUMBER,
 BATCH_ID_OUT OUT NUMBER,
-- PROCESS_DATE OUT DATE,
 ERRMSG OUT VARCHAR2);

 PROCEDURE SP_MARK_FILE_STATUS (
 INSTCODE NUMBER ,
 EVENT NUMBER,
 BATCH_ID NUMBER,
 FILE_NAME VARCHAR2,
 FILE_PATH VARCHAR2,
 RECORD_COUNT NUMBER,
 FILE_STATUS NUMBER,
 USERPIN NUMBER,
 ERRMSG OUT VARCHAR2);
 
 END Pack_Emboss_Ops;
/
show error

CREATE OR REPLACE PACKAGE BODY VMSCMS.Pack_Emboss_Ops
IS
 PROCEDURE Sp_Mark_Batch_Status (INSTCODE NUMBER,EVENT NUMBER,BATCH_ID_IN NUMBER , TOTAL_RECORDS NUMBER, BATCH_STATUS NUMBER,
 USERPIN NUMBER, BATCH_ID_OUT OUT NUMBER, /*PROCESS_DATE OUT DATE,*/ERRMSG OUT VARCHAR2)
 IS
 V_PROCESS_DATE             DATE;
 V_BATCH_ID                 NUMBER;
 V_PROCESSED_RECORDS        NUMBER;
 V_END_DATE         DATE;
 ERR_EXCEPTION              EXCEPTION;
 BATCH_START_EVENT NUMBER(1):=0;
 BATCH_END_EVENT NUMBER(1):=1;
 BEGIN
 ERRMSG := 'OK';
 V_PROCESS_DATE := SYSDATE;
    IF EVENT = BATCH_START_EVENT THEN
            DBMS_OUTPUT.PUT_LINE('START OF PROCESS');
            BEGIN
            SELECT SEQ_BATCH_ID.NEXTVAL
            INTO   V_BATCH_ID FROM DUAL;
            END;
            INSERT INTO CMS_EMBOSS_BATCH_STATUS
            (EBS_BATCH_ID ,
             EBS_TOTAL_RECORDS ,
             EBS_START_TIME ,
             EBS_INS_USER,
             EBS_INS_DATE,
             EBS_LUPD_USER,
             EBS_LUPD_DATE)
             VALUES
             (V_BATCH_ID,
              TOTAL_RECORDS,
              V_PROCESS_DATE,
              USERPIN,
              V_PROCESS_DATE,
              USERPIN,
              V_PROCESS_DATE);
      BATCH_ID_OUT := V_BATCH_ID;
      --PROCESS_DATE := V_PROCESS_DATE;
    ELSE
            IF EVENT = BATCH_END_EVENT THEN
            DBMS_OUTPUT.PUT_LINE('END OF PROCESS');
                BEGIN
                    SELECT SUM(CFS_RECORD_COUNT)
                    INTO   V_PROCESSED_RECORDS
                    FROM   CMS_EMBOSS_FILE_STATUS
                    WHERE  CFS_BATCH_ID =BATCH_ID_IN;
                EXCEPTION
                    WHEN NO_DATA_FOUND THEN
                    ERRMSG := 'NO DATA FOUND FOR BATCH ID ' || BATCH_ID_IN;
                    RAISE   ERR_EXCEPTION;
                END;
                    V_END_DATE      :=SYSDATE;
                BEGIN
                    UPDATE  CMS_EMBOSS_BATCH_STATUS
                    SET     EBS_PROCESSED_RECORDS = V_PROCESSED_RECORDS,
                    EBS_END_TIME          = V_END_DATE,
                    EBS_BATCH_STATUS      = BATCH_STATUS,
					EBS_LUPD_DATE 	  = SYSDATE,
					EBS_LUPD_USER = USERPIN
                    WHERE   EBS_BATCH_ID          = BATCH_ID_IN;
                    IF SQL%ROWCOUNT = 0 THEN
                            ERRMSG := ' Error while updating record for Batch Id ' || BATCH_ID_IN;
                            RAISE   ERR_EXCEPTION;
                    END IF;
                        END;
                            BATCH_ID_OUT    :=      BATCH_ID_IN;
                            --PROCESS_DATE    :=      V_END_DATE;
             ELSE
                    ERRMSG := 'NOT A VALID EVENT';
                    RAISE ERR_EXCEPTION;
             END IF;
    END IF;
 EXCEPTION
 WHEN ERR_EXCEPTION THEN
 ERRMSG := ERRMSG ||SUBSTR(SQLERRM,1,200);
 WHEN OTHERS THEN
 ERRMSG := SUBSTR(SQLERRM,1,300);
 END;
------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------
------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------
 PROCEDURE SP_MARK_FILE_STATUS (INSTCODE NUMBER,EVENT IN NUMBER,BATCH_ID NUMBER,FILE_NAME VARCHAR2,FILE_PATH VARCHAR2,
 RECORD_COUNT NUMBER,FILE_STATUS NUMBER,USERPIN NUMBER, ERRMSG OUT VARCHAR2)
 IS
 V_PROCESS_DATE		DATE;
 ERR_EXCEPTION 		EXCEPTION;
 FILE_START_EVENT NUMBER(1):=0;
 FILE_END_EVENT NUMBER(1):=1;
 BEGIN 	--MAIN BEGIN
 ERRMSG := 'OK';
	IF EVENT = FILE_START_EVENT THEN
		V_PROCESS_DATE := SYSDATE;
		INSERT INTO CMS_EMBOSS_FILE_STATUS
			( 
 			CFS_BATCH_ID,           
			CFS_FILE_NAME,
 			CFS_FILE_PATH,          
 			CFS_INS_USER,
 			CFS_INS_DATE,
 			CFS_LUPD_USER,
 			CFS_LUPD_DATE)
		VALUES
			(BATCH_ID,
			FILE_NAME,
			FILE_PATH,
			USERPIN,
			V_PROCESS_DATE,
			USERPIN,
			V_PROCESS_DATE);
	ELSE
		IF EVENT = FILE_END_EVENT THEN
			BEGIN
				UPDATE CMS_EMBOSS_FILE_STATUS
				SET 
				CFS_RECORD_COUNT  = RECORD_COUNT,     
				CFS_FILE_STATUS   = FILE_STATUS,
				CFS_LUPD_DATE	  = SYSDATE,
				CFS_LUPD_USER=USERPIN
				WHERE
				CFS_BATCH_ID	  = BATCH_ID 
				AND CFS_FILE_NAME= FILE_NAME;
			    IF SQL%ROWCOUNT = 0 THEN
				ERRMSG := 'ERROR WHILE UPDATING FOR BATCH ID ' || BATCH_ID;
				RAISE ERR_EXCEPTION;
			    END IF;
			END;
		--END IF;
		ELSE
		ERRMSG := ' NOT A VALID EVENT';
		RAISE 	ERR_EXCEPTION;
		END IF;
	END IF;
 EXCEPTION
 WHEN ERR_EXCEPTION THEN
 ERRMSG := ERRMSG || SUBSTR(SQLERRM,1,200);
 WHEN OTHERS THEN
 ERRMSG := SUBSTR(SQLERRM,1,300);
 END;   --MAIN END;
 
END Pack_Emboss_Ops;
-------------------------------------------------------------------------------------------------------------
/
show error

