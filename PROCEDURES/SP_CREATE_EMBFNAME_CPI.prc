create or replace
PROCEDURE        VMSCMS.SP_CREATE_EMBFNAME_CPI(P_INSTCODE IN NUMBER,
										 P_FILENAME IN VARCHAR2,
                                         P_TYPEOFORDER  IN VARCHAR2,  --Added for MVHOST-389
                                         P_VENDER   IN VARCHAR2,	--Added for MVHOST-389
										 P_BIN      IN  VARCHAR2,   -- added for FSS-2161
                                         P_LUPDUSER IN NUMBER,
                                         P_EMBFNAME OUT VARCHAR2,
										 P_ERRMSG   OUT VARCHAR2) AS

  /*************************************************
     * Created  By      :  T.Narayanan
     * Created Date     :  08-May-2012
     * Created Reason   :  to generate different file name for CPI file CR_003
     * Reviewer         :  B.Besky Anand.
     * Reviewed Date    :  11_May-2012
     * Release Number   :  CMS3.4.3_RI0006.3_B0001
     
    * Modified By       : Ramesh
	* Modified Date     : 30-Sep-2014
	* Modified For      : MFCHOST-389
	* Reviewer          : Spankaj
	* Release Number    : RI0027.4_B0002
    
    * Modified By       : siva kumar M
	* Modified Date     : 12-Feb-2015
	* Modified For      : FSS-2161
	* Reviewer          : Savaravana A
	* Release Number    : RI0027.5_B0007
    * Modified By       : Ramesh
	* Modified Date     : 19-FEB-2015
	* Modified For      : FSS-2236
	* Reviewer          : Pankaj S
	* Release Number    : RI0027.5_B0008
   *************************************************/

  V_CURR_DATE VARCHAR2(8);
  V_FILE_CNT  VARCHAR2(100);
  V_FILE_LEN  NUMBER(3);
  v_program_name cms_prod_mast.cpm_prod_desc%TYPE;

BEGIN
  BEGIN
    SELECT TO_CHAR(SYSDATE, 'mmddyyyy') INTO V_CURR_DATE FROM DUAL;

    V_FILE_LEN := LENGTH(P_FILENAME);

/* Commented for MVHOST-389
    SELECT NVL(SUBSTR(SUBSTR(MAX(CEC_EMB_FNAME), 9),
				  1,
				  LENGTH(SUBSTR(MAX(CEC_EMB_FNAME), 8)) - 19),
			0) + 1
	 INTO V_FILE_CNT
	 FROM CMS_EMBOS_CTRL
	WHERE CEC_INST_CODE = P_INSTCODE AND
		 SUBSTR(CEC_EMB_FNAME, 1, V_FILE_LEN) = P_FILENAME AND
		 CEC_CREATE_DATE =
		 (SELECT MAX(CEC_CREATE_DATE)
		    FROM CMS_EMBOS_CTRL
		   WHERE SUBSTR(CEC_EMB_FNAME, 1, V_FILE_LEN) = P_FILENAME);
       */
       --Added for MVHOST-389
     select NVL(MAX(CEC_FILE_COUNT)+1,0) INTO V_FILE_CNT 
     from CMS_EMBOS_CTRL WHERE CEC_INST_CODE = P_INSTCODE AND
		 CEC_VENDOR_NAME = P_VENDER AND
		 TRUNC(CEC_CREATE_DATE) = (SELECT MAX(trunc(CEC_CREATE_DATE))
		    FROM CMS_EMBOS_CTRL
		   WHERE CEC_VENDOR_NAME = P_VENDER);              
 
    --T.Narayanan Changed on 14/05/2012 for the file name issue end
    
      -- added for FSS-2161
      begin
        select cpb_prod_code 
        into v_program_name 
        from cms_prod_bin 
        where cpb_inst_bin=P_BIN 
        AND cpb_inst_code=p_INSTCODE;
        
        exception 
        when OTHERS then
             P_ERRMSG := 'Exeption Prod -- ' || SQLCODE || '--' || SQLERRM;
        
        end;
    
    
    --Modified for MVHOST-389
    P_EMBFNAME := P_FILENAME ||'_'||v_program_name|| '_' ||P_TYPEOFORDER||'_'||  V_FILE_CNT || '_0000_' || V_CURR_DATE || '.csv';

    BEGIN
	 INSERT INTO CMS_EMBOS_CTRL
	   (CEC_INST_CODE,
	    CEC_EMB_FNAME,
	    CEC_CREATE_TOT,
	    CEC_CREATE_DATE,
	    CEC_INS_USER,
	    CEC_INS_DATE,
	    CEC_LUPD_USER,
	    CEC_LUPD_DATE,
      CEC_FILE_COUNT,	--Added for MVHOST-389
      CEC_VENDOR_NAME)	--Added for MVHOST-389
	 VALUES
	   (P_INSTCODE,
	    P_EMBFNAME,
	    0,
	    SYSDATE,
	    P_LUPDUSER,
	    SYSDATE,
	    P_LUPDUSER,
	    SYSDATE,
      V_FILE_CNT,	--Added for MVHOST-389
      P_VENDER);        --Added for MVHOST-389 -- Modified for FSS-2236
	 P_ERRMSG := 'OK';
    EXCEPTION
	 WHEN OTHERS THEN
	   P_ERRMSG := 'Exception 2 --' || SQLCODE || '--' || SQLERRM;
    END;

  EXCEPTION
    WHEN OTHERS THEN
	 P_ERRMSG := 'Exeption KK 1 -- ' || SQLCODE || '--' || SQLERRM;
  END;

EXCEPTION
  WHEN OTHERS THEN
    P_ERRMSG := 'Exeption Main -- ' || SQLCODE || '--' || SQLERRM;
END;
/
SHOW ERROR