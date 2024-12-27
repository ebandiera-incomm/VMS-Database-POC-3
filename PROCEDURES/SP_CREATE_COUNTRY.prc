CREATE OR REPLACE PROCEDURE VMSCMS.sp_create_country(
                                              prm_instcode IN NUMBER,
                                              prm_filename IN VARCHAR2,
                                              prm_lupduser IN VARCHAR2,
                                              prm_errmsg OUT VARCHAR2
                                              )
AS
CURSOR c1 IS
SELECT cci_seg12_country_code
FROM	CMS_CAF_INFO_TEMP
WHERE	cci_file_name = prm_filename
AND	cci_seg12_country_code NOT IN(
                                  SELECT gcm_curr_code 
                                  FROM GEN_CURR_MAST 
                                  where gcm_inst_code= prm_instcode);
v_cntry number:=0;
v_cntrycode number;
exp_reject_record exception;
BEGIN
	FOR x IN c1
	LOOP
    BEGIN
      prm_errmsg:='OK';
      v_cntry:=v_cntry+1;
      savepoint v_cntry;
      
      BEGIN
        SELECT MAX(gcm_cntry_code)+1
        INTO v_cntrycode
        FROM GEN_CNTRY_MAST
        WHERE gcm_inst_code= prm_instcode
        AND gcm_curr_code=x.cci_seg12_country_code;
      EXCEPTION 
      WHEN NO_DATA_FOUND THEN
        v_cntrycode:=1;
      WHEN OTHERS THEN
        prm_errmsg:='Error while getting country code '||substr(sqlerrm,1,200);
        RAISE exp_reject_record;
      END;
    
      BEGIN
        INSERT INTO GEN_CURR_MAST(GCM_CURR_CODE ,
              GCM_CURR_NAME  ,
              GCM_CURR_DESC  ,
              GCM_LUPD_USER  )
            VALUES(	x.cci_seg12_country_code,
              x.cci_seg12_country_code||' - DFLT',
              'DEFAULT DESC',
              prm_lupduser);
      EXCEPTION 
      WHEN OTHERS THEN
        prm_errmsg:='Error while creating currency '||substr(sqlerrm,1,200);
        RAISE exp_reject_record;
      END;
    
      BEGIN
         INSERT INTO GEN_CNTRY_MAST(GCM_CNTRY_CODE,
              GCM_CURR_CODE  ,
              GCM_CNTRY_NAME,
              GCM_LUPD_USER  )
            VALUES(v_cntrycode,
              x.cci_seg12_country_code,
              x.cci_seg12_country_code||' - DFLT',
              prm_lupduser); 
      EXCEPTION 
      WHEN OTHERS THEN
        prm_errmsg:='Error while creating country code '||substr(sqlerrm,1,200);
        RAISE exp_reject_record;
      END;
      
    EXCEPTION 
    WHEN exp_reject_record THEN
      ROLLBACK to v_cntry;
    WHEN OTHERS THEN
      ROLLBACK to v_cntry;
    END;
  END LOOP;
END;
/
show error