CREATE OR REPLACE PROCEDURE VMSCMS.sp_create_employee (instcode IN NUMBER,orgname IN VARCHAR2, empcode IN VARCHAR2, empname IN VARCHAR2, custcode IN NUMBER, userid IN NUMBER, errmsg OUT VARCHAR2)
AS
v_code PCMS_CORPORATE_MASTER.pcm_organization_code%TYPE;
BEGIN
errmsg:='OK';
BEGIN
SELECT pcm_organization_code
INTO v_code
FROM PCMS_CORPORATE_MASTER
WHERE pcm_short_name = SUBSTR(orgname,1,3);
EXCEPTION
WHEN NO_DATA_FOUND THEN
errmsg := 'Corporate not present in system';
END;
IF errmsg = 'OK' THEN
INSERT INTO PCMS_EMPLOYEE_MASTER
VALUES(
instcode,
v_code,
empcode,
empname,
userid,
SYSDATE,
userid,
SYSDATE,
0,
custcode);
END IF;
EXCEPTION
WHEN OTHERS THEN
errmsg:='Error in adding employee'||SQLERRM;
END;
/


