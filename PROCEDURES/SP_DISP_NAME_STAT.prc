CREATE OR REPLACE PROCEDURE VMSCMS.sp_disp_name_stat IS
  CURSOR cur_from_caf IS
	SELECT 	cci_pan_code,
		cci_mbr_numb,
		cci_crd_stat,
		cci_seg12_name_line1
	FROM	CMS_CAF_INFO_CARDBASE;
	ctr 		NUMBER := 0;
	v_cust_code	NUMBER(10);
BEGIN
  FOR X IN cur_from_caf
  LOOP
  IF ctr >= 10000 THEN
    COMMIT;
    ctr := 0;
  ELSE
    ctr := ctr+1;
  END IF;
    BEGIN
     SELECT cap_cust_code
     INTO   v_cust_code
     FROM   CMS_APPL_PAN
     WHERE  cap_pan_code = x.cci_pan_code;
     UPDATE CMS_APPL_PAN
     SET    cap_disp_name = x.cci_seg12_name_line1,
     	    cap_card_stat = x.cci_crd_stat
     WHERE  cap_pan_code = x.cci_pan_code;
     UPDATE CMS_CUST_MAST
     SET    ccm_first_name = x.cci_seg12_name_line1
     WHERE  ccm_inst_code  = 1
     AND    ccm_cust_code  = v_cust_code;
    EXCEPTION
	WHEN NO_DATA_FOUND THEN
		sp_auton('0', x.cci_pan_code, SQLERRM);
	WHEN OTHERS THEN
		sp_auton('0', x.cci_pan_code, SQLERRM);
    END;
  END LOOP;
END;
/


show error