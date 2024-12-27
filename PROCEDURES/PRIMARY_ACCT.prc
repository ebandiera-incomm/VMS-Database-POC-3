CREATE OR REPLACE PROCEDURE VMSCMS.primary_acct IS
CURSOR C1 IS
SELECT DISTINCT cap_pan_code
FROM   CMS_APPL_PAN , CMS_PAN_ACCT
WHERE  cap_inst_code = cpa_inst_code
AND    cap_pan_code  = cpa_pan_code
AND    cap_mbr_numb  = cpa_mbr_numb
AND    cpa_acct_posn > 1
AND    cap_sync_flag = 'Y'
MINUS
SELECT cap_pan_code
FROM   CMS_APPL_PAN , CMS_PAN_ACCT
WHERE  cap_inst_code = cpa_inst_code
AND    cap_pan_code  = cpa_pan_code
AND    cap_mbr_numb  = cpa_mbr_numb
AND    cpa_acct_posn = 1
AND    cap_sync_flag = 'Y';
v_pri_acct_no  VARCHAR2(20);
v_pri_acct_id  NUMBER(10);
BEGIN
  FOR a IN C1
  LOOP
  BEGIN
     UPDATE CMS_PAN_ACCT
     SET    cpa_acct_posn = cpa_acct_posn-1
     WHERE  cpa_inst_code = 1
     AND    cpa_pan_code = a.cap_pan_code;
     SELECT cam_acct_no, cam_acct_id
     INTO   v_pri_acct_no, v_pri_acct_id
     FROM CMS_ACCT_MAST
     WHERE cam_inst_code = 1
     AND  cam_acct_id = (SELECT cpa_acct_id FROM CMS_PAN_ACCT
     WHERE cpa_inst_code = 1
     AND cpa_pan_code = a.cap_pan_code
     AND cpa_acct_posn = 1);
     UPDATE CMS_APPL_PAN
     SET    cap_acct_id = v_pri_acct_id,
     cap_acct_no = v_pri_acct_no
     WHERE  cap_pan_code = a.cap_pan_code;
  EXCEPTION
 WHEN OTHERS THEN
 sp_auton( 101,
   a.cap_pan_code,
   'PRIMARY A/C UPDATION'||SQLERRM);
  END;
  END LOOP;
END;
/


show error