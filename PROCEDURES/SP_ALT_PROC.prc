CREATE OR REPLACE PROCEDURE VMSCMS.Sp_Alt_Proc
AS
tempno  NUMBER(10);
BEGIN
	SELECT seq_test.NEXTVAL-1  INTO tempno FROM dual;
	EXECUTE IMMEDIATE 'Alter sequence seq_test increment by ' || -tempno ;
	SELECT seq_test.NEXTVAL INTO tempno FROM dual;
	EXECUTE IMMEDIATE 'Alter sequence seq_test increment by ' || 1 ;
END;
/


