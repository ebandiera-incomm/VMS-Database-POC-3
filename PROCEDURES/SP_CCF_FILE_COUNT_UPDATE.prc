create or replace
PROCEDURE        VMSCMS.SP_CCF_FILE_COUNT_UPDATE as

/*************************************************
     * Created By      :  Ramesh
     * Created Date    :  28-SEP-2014
     * Created Reason  :  MVHOST-389 : CCF file count update for SourceOne and CPI
     * Reviewer        :  spankaj
     * Build Number    :  RI0027.4_B0002          
*************************************************/
filename_source varchar2(20);
filename_cpi varchar2(20);
V_FILE_LEN  NUMBER(3);
V_FILE_CNT  VARCHAR2(100);

begin

     begin
      filename_source :='SourceOne_CCF';
      V_FILE_LEN := LENGTH(filename_source);
      
      SELECT NVL(MAX(TO_NUMBER(SUBSTR(CEC_EMB_FNAME, 13 + 10,3))),0)
      INTO V_FILE_CNT
      FROM CMS_EMBOS_CTRL
      WHERE CEC_INST_CODE = 1 AND
		  SUBSTR(CEC_EMB_FNAME, 1, V_FILE_LEN) = filename_source AND
		  TRUNC(CEC_CREATE_DATE) = TRUNC(SYSDATE);
      
      update CMS_EMBOS_CTRL set CEC_FILE_COUNT=V_FILE_CNT, CEC_VENDOR_NAME='SourceOne'
      where CEC_INST_CODE = 1 
      AND SUBSTR(CEC_EMB_FNAME, 1, V_FILE_LEN) = filename_source 
      AND TRUNC(CEC_CREATE_DATE) = TRUNC(SYSDATE);
                 
      EXCEPTION
       WHEN OTHERS THEN
        DBMS_OUTPUT.PUT_LINE('Exeption while updating file count(SourceOne) --'|| SUBSTR (SQLERRM, 1, 200));
 
    end;
      
    begin
      filename_cpi :='CPI_VMS';
      V_FILE_LEN := LENGTH(filename_cpi);
      
      SELECT NVL(SUBSTR(SUBSTR(MAX(CEC_EMB_FNAME), 9),1, LENGTH(SUBSTR(MAX(CEC_EMB_FNAME), 8)) - 19),0) INTO V_FILE_CNT
      FROM CMS_EMBOS_CTRL
      WHERE CEC_INST_CODE = 1 
      AND SUBSTR(CEC_EMB_FNAME, 1, V_FILE_LEN) = filename_cpi 
      AND CEC_CREATE_DATE =
		   (SELECT MAX(CEC_CREATE_DATE)
		    FROM CMS_EMBOS_CTRL
		    WHERE SUBSTR(CEC_EMB_FNAME, 1, V_FILE_LEN) = filename_cpi);        
 
      update CMS_EMBOS_CTRL set CEC_FILE_COUNT=V_FILE_CNT , CEC_VENDOR_NAME='CPI'
      where CEC_INST_CODE = 1 
      AND SUBSTR(CEC_EMB_FNAME, 1, V_FILE_LEN) = filename_cpi 
      AND TRUNC(CEC_CREATE_DATE) = (SELECT MAX(trunc(CEC_CREATE_DATE))
		    FROM CMS_EMBOS_CTRL
		    WHERE SUBSTR(CEC_EMB_FNAME, 1, V_FILE_LEN) = filename_cpi);
        
          IF SQL%ROWCOUNT = 0 THEN
              DBMS_OUTPUT.PUT_LINE('File count not updated for CPI --');                
          END IF;
                  
       EXCEPTION
       WHEN OTHERS THEN
        DBMS_OUTPUT.PUT_LINE('Exeption while updating file count(CPI) --'|| SUBSTR (SQLERRM, 1, 200));
 
      end;
      
 EXCEPTION
    WHEN OTHERS THEN
    DBMS_OUTPUT.PUT_LINE('Main Exeption while updating file count -- '|| SUBSTR (SQLERRM, 1, 200));
end;
/
SHOW ERROR