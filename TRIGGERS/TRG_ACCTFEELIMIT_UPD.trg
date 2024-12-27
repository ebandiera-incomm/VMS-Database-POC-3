create or replace TRIGGER VMSCMS.TRG_ACCTFEELIMIT_UPD 
BEFORE  UPDATE OF CAF_LMT_RESETDATE ON VMSCMS.CMS_ACCTLVL_FEELIMIT 
FOR EACH ROW

 /*************************************************
      * Created By       : Ramesh
      * Created Date     : 29-June-2012
	  * Build Number     : RI0024.4_B0004
 *************************************************/
	  
DECLARE
v_acct_no VARCHAR2(20);
v_fee_code NUMBER(3);
v_maxlimit NUMBER(5);
v_inst_code  NUMBER(3);
v_fm_max_limit  NUMBER(5);
v_fm_maxlimit_freq VARCHAR2(1);
err  NUMBER (2);
BEGIN

  BEGIN
    SELECT CFM_MAX_LIMIT,CFM_MAXLMT_FREQ
       INTO v_fm_max_limit,v_fm_maxlimit_freq
       FROM CMS_FEE_MAST
       WHERE CFM_FEE_CODE = :OLD.CAF_FEE_CODE
       AND CFM_INST_CODE = :OLD.CAF_INST_CODE;
    
      EXCEPTION 
         WHEN NO_DATA_FOUND
         THEN
         err :=0;
         WHEN OTHERS
         THEN
          raise_application_error(-20001,'ERROR IN DATA SELECTION '|| SQLERRM );
  END;
  
  BEGIN
  
        INSERT INTO CMS_ACCTLVL_FEELIMIT_HIST(CAH_ACCT_ID,
                                              CAH_FEE_CODE,
                                              CAH_LIMIT_USED,
                                              CAH_MAX_LIMIT,
                                              CAH_FREQ_TYPE,
                                              CAH_INS_DATE,
                                              CAH_INST_CODE)
                                        VALUES(:OLD.CAF_ACCT_ID,
                                                :OLD.CAF_FEE_CODE,
                                                :OLD.CAF_MAX_LIMIT,
                                                v_fm_max_limit,
                                                v_fm_maxlimit_freq,
                                                SYSDATE,
                                                :OLD.CAF_INST_CODE);
           EXCEPTION 
              WHEN OTHERS
               THEN
                raise_application_error(-20001,'ERROR IN DATA SELECTION' );
  
  END;
 
END;
/
SHOW ERROR;