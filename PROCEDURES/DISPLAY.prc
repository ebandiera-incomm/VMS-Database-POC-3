CREATE OR REPLACE PROCEDURE VMSCMS.display AS
v_ccm_cust_code NUMBER(10);
v_ccm_first_name VARCHAR2(30);
v_ccm_last_name VARCHAR2(30);

CURSOR c1 IS
SELECT ccm_cust_code,ccm_first_name,ccm_last_name
FROM CMS_CUST_MAST;

BEGIN
FOR x IN c1
LOOP
UPDATE CMS_APPL_PAN
SET cap_disp_name=x.ccm_first_name||' '||x.ccm_last_name
WHERE cap_cust_code=x.ccm_cust_code;
END LOOP;

END;
/


show error