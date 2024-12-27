CREATE OR REPLACE PROCEDURE VMSCMS.Sp_Update_Inventory_new (instcode IN NUMBER,request IN VARCHAR2,lupduser IN NUMBER, errmsg OUT VARCHAR2)
AS
CURSOR c1 IS
SELECT pil_request_id, pil_branch_code, pil_quantity_receive
FROM PCMS_INVENTORY_LOG
WHERE trim(pil_request_id) = trim(request)
AND  pil_status = 'P';
v_pancount NUMBER(10);
BEGIN
errmsg :='OK';
FOR x IN c1
LOOP
v_pancount:=0;
BEGIN
SELECT COUNT(1)
INTO v_pancount
FROM CMS_APPL_PAN
WHERE cap_cafgen_flag = 'Y'
AND cap_pin_flag = 'N'
AND cap_embos_flag = 'N'
AND cap_issue_flag = 'N'
AND cap_request_id = x.pil_request_id;
EXCEPTION
WHEN NO_DATA_FOUND THEN
v_pancount:=0;
END;
UPDATE PCMS_INVENTORY_LOG
SET pil_quantity_return = v_pancount,
pil_status = 'O'
WHERE pil_request_id = x.pil_request_id;
END LOOP;
EXCEPTION
WHEN OTHERS THEN
errmsg:='Exception while updating inventory quantity';
END;
/


SHOW ERRORS