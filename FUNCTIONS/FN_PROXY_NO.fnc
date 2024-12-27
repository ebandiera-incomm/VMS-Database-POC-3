create or replace
FUNCTION               vmscms.FN_PROXY_NO(BIN        IN VARCHAR2,
							    PRODCATG   IN VARCHAR2,
							    PROG_ID    IN VARCHAR2, --T.Narayanan added for program id
							    SEQNO      IN NUMBER,
							    INSTCODE   IN NUMBER,
							    UPDATEUSER IN VARCHAR2,
                  check_digit_request in varchar2 ,
                  proxy_length in number ) -- T.NARAYANAN added FOR PRG ID 
 RETURN VARCHAR2 AS
  PROXY_NO      CMS_APPL_PAN.CAP_PROXY_NUMBER%type; -- T.NARAYANAN CHANGED FOR PRG ID 
  DUP_COUNT     NUMBER(1) := 0;
  V_CHECK_DIGIT NUMBER(1); -- T.NARAYANAN added FOR PRG ID 
  SEQ_NO_UPDATE VARCHAR2(200); -- T.NARAYANAN added FOR PRG ID 
  SEQ_NUMBER    NUMBER(10); -- T.NARAYANAN added FOR PRG ID 

BEGIN
  -- main begin
  SEQ_NUMBER := SEQNO;
  LOOP
    -- SELECT    SUBSTR (bin, 1, 6)|| LPAD (prodcatg, 2, 0)|| SUBSTR (LPAD ((ABS (DBMS_RANDOM.random)||seq_proxyno.NEXTVAL),11,0),1,11)
    /*  SELECT SUBSTR(BIN, 1, 6) || LPAD(PRODCATG, 2, 0) ||
         SUBSTR(ABS(DBMS_RANDOM.RANDOM), 1, 4)
    INTO PROXY_NO
    FROM DUAL;*/
    -- T.NARAYANAN added FOR PRG ID BEG
    
    
    SEQ_NUMBER := SEQ_NUMBER + 1;
    
        if check_digit_request='Y' then
             SELECT LPAD(PROG_ID, 4, 0) ||
             LPAD(SEQ_NUMBER, proxy_length, 0)
            INTO PROXY_NO
            FROM DUAL; 
            
            SP_CHK_DIGIT_CALC(PROXY_NO, V_CHECK_DIGIT);
            PROXY_NO := PROXY_NO || V_CHECK_DIGIT;
            
         elsif check_digit_request='N' then
            SELECT LPAD(PROG_ID, 4, 0) ||
            LPAD(SEQ_NUMBER, proxy_length, 0)
            INTO PROXY_NO
            FROM DUAL;
            
        end if;
        
    SELECT COUNT(*)
	 INTO DUP_COUNT
	 FROM CMS_APPL_PAN
	WHERE CAP_PROXY_NUMBER = PROXY_NO;
    -- T.NARAYANAN added FOR PRG ID END
    EXIT WHEN DUP_COUNT = 0;
  END LOOP;
  SEQ_NO_UPDATE := 'UPDATE CMS_PROGRAM_ID_CNT SET CPI_SEQUENCE_NO=' ||
			    SEQ_NUMBER || ',CPI_LUPD_USER=' || UPDATEUSER ||
			    ',CPI_LUPD_DATE=SYSDATE WHERE  CPI_PROGRAM_ID=' ||
			    CHR(39) || PROG_ID || CHR(39) || 'AND CPI_INST_CODE=' ||
			    INSTCODE;

  EXECUTE IMMEDIATE SEQ_NO_UPDATE;

  RETURN PROXY_NO;
EXCEPTION
  WHEN OTHERS THEN
    RETURN('0');
END; -- main end
/
show error