CREATE OR REPLACE PROCEDURE VMSCMS.sp_create_city(
                                              prm_instcode IN NUMBER,
                                              prm_filename IN VARCHAR2,
                                              prm_lupduser IN VARCHAR2,
                                              prm_cntrycode IN NUMBER,
                                              prm_statecode IN NUMBER,
                                              prm_citycode  OUT NUMBER,
                                              prm_errmsg OUT VARCHAR2
                                              )
AS
CURSOR c1 IS
SELECT DISTINCT CCI_SEG12_CITY
FROM	CMS_CAF_INFO_TEMP
WHERE	cci_file_name = prm_filename
AND	CCI_SEG12_CITY NOT IN(SELECT gcm_city_name 
                           FROM gen_city_mast
                           WHERE gcm_inst_code=prm_instcode 
                           AND gcm_cntry_code= prm_cntrycode
                           AND gcm_state_code=prm_statecode);

BEGIN
	FOR x IN c1
	LOOP
    prm_errmsg:='OK';
    
    BEGIN
      SELECT MAX(gcm_city_code)+1
      INTO prm_citycode
      FROM gen_city_mast
      WHERE gcm_inst_code= prm_instcode
      AND gcm_cntry_code =prm_cntrycode
      AND gcm_state_code=prm_statecode; 
    EXCEPTION
    WHEN OTHERS THEN
      prm_errmsg:='Error while getting city code '||substr(sqlerrm,1,200);
    END;
    
    BEGIN
      INSERT INTO gen_city_mast(
                              GCM_INST_CODE,
                              GCM_CNTRY_CODE,
                              GCM_CITY_CODE,
                              GCM_STATE_CODE,
                              GCM_CITY_NAME,
                              GCM_LUPD_USER,
                              GCM_LUPD_DATE,
                              GCM_INS_DATE,
                              GCM_INS_USER
                              )
                        values(
                                prm_instcode,
                                prm_cntrycode,
                                prm_citycode,
                                prm_statecode,
                                x.CCI_SEG12_CITY,
                                prm_lupduser,
                                sysdate,
                                sysdate,
                                prm_lupduser
                              );
      EXCEPTION
      WHEN OTHERS THEN
        prm_errmsg:='Error while creating city '||substr(sqlerrm,1,200);
      END;
      
  END LOOP;
END;
/


show error