CREATE OR REPLACE PROCEDURE VMSCMS.SP_GRP_CHNGESTAT
  (
    instcode IN NUMBER,
    lupduser IN NUMBER,
    errmsg OUT VARCHAR2 )
AS
  v_mbrnumb VARCHAR2(3);
  v_remark CMS_PAN_SPPRT.cps_func_remark%TYPE;
  v_spprtrsn CMS_PAN_SPPRT.cps_spprt_rsncode%TYPE;
  v_workmode NUMBER;
  CURSOR c1
  IS
    SELECT TRIM(cgc_pan_code) cgc_pan_code ,
      cgc_new_stat,
      cgc_remark,
      ROWID
    FROM CMS_GROUP_CHNGESTAT
    WHERE cgc_pin_chngestat = 'N';
BEGIN
  errmsg     := 'OK';
  v_remark   := 'Group Change Status';
  v_spprtrsn := 1;
  v_workmode :=0;
  FOR x      IN c1
  LOOP
    BEGIN
      sp_upld_chg_crdstat(instcode,x.cgc_pan_code,v_mbrnumb,v_spprtrsn,X.cgc_remark,v_workmode,x.cgc_new_stat,lupduser,errmsg);
      IF ERRMSG = 'OK' THEN
        UPDATE CMS_GROUP_CHNGESTAT
        SET CGC_PIN_CHNGESTAT = 'Y' ,
          cgc_result          = 'SUCCESSFULL'
        WHERE ROWID           = X.ROWID;
      ELSE
        UPDATE CMS_GROUP_CHNGESTAT
        SET CGC_PIN_CHNGESTAT = 'E' ,
          cgc_result          = errmsg
        WHERE ROWID           = X.ROWID;
        
        sp_auton( NULL, x.cgc_pan_code, ERRMSG) ;
      END IF;
    EXCEPTION
    WHEN OTHERS THEN
      errmsg :=SQLERRM;
      UPDATE CMS_GROUP_CHNGESTAT
      SET CGC_PIN_CHNGESTAT = 'E' ,
        cgc_result          = errmsg
      WHERE ROWID           = X.ROWID;
      
      sp_auton( NULL, x.cgc_pan_code, ERRMSG) ;
    END;
  END LOOP;
  ERRMSG := 'OK';
EXCEPTION
WHEN OTHERS THEN
  errmsg := 'Main Excp -- '||SQLERRM;
END;
/


