CREATE OR REPLACE PROCEDURE VMSCMS.sp_create_payment_pcms(instcode IN VARCHAR2,applcode IN NUMBER, cust IN NUMBER,
paymode IN VARCHAR2, instrno IN VARCHAR2, amount IN VARCHAR2, insuser IN NUMBER, insdate IN DATE,
errmsg OUT VARCHAR2)
IS
BEGIN
errmsg:='OK';
INSERT INTO PCMS_PAYMENT_MASTER
VALUES(
instcode,
applcode,
cust,
paymode,
instrno,
amount,
insuser,
insdate,
insuser,
insdate);
EXCEPTION
WHEN OTHERS THEN
errmsg:='CANNOT INSERT INTO PAYMENT MASTER';
END;
/


show error