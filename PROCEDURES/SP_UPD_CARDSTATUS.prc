CREATE OR REPLACE PROCEDURE VMSCMS.Sp_Upd_Cardstatus(
	instcode IN NUMBER,
      	lupduser IN NUMBER,
      	errmsg OUT VARCHAR2) IS

  CURSOR C1 IS SELECT
	TBDL_PAN,
	TBDL_MBR,
	TBDL_STAT
  FROM 	TO_BE_DROPPED_LOGGER;

  v_ctr NUMBER(10) := 1;

--changed by PANKAJ on 220405 tuning


BEGIN

errmsg:='OK';
   FOR X IN C1
    LOOP
    UPDATE CMS_APPL_PAN
    	SET CAP_CARD_STAT=X.TBDL_STAT ,
 	CAP_LUPD_USER = lupduser
    WHERE  CAP_PAN_CODE=X.TBDL_PAN
    AND    CAP_MBR_NUMB = X.TBDL_MBR;

--changed by PANkAJ on 220405 tuning start
    IF v_ctr >= 10000 THEN
	v_ctr := 1;
        COMMIT;
    ELSE
	v_ctr := v_ctr+1;
    END IF;
--changed by PANkAJ on 220405 tuning end

    END LOOP;

  COMMIT;
-- This change has been done to replace delete by truncate statement

    Sp_Trunc_Tab('TO_BE_DROPPED_LOGGER',errmsg );

EXCEPTION
  WHEN OTHERS THEN
    Sp_Trunc_Tab('TO_BE_DROPPED_LOGGER',errmsg );
  errmsg:='EXCP-'||SQLCODE||':-'||SQLERRM;
END;
/


