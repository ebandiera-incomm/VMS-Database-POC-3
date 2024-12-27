CREATE OR REPLACE PROCEDURE VMSCMS.sp_pop_cobrand_details( instcode IN NUMBER,
       assocode IN NUMBER,
       acqid  IN VARCHAR2,
       termid  IN VARCHAR2,
       lupduser IN NUMBER,
       errmsg  OUT VARCHAR2 )
AS
fk_excp EXCEPTION;
PRAGMA EXCEPTION_INIT(fk_excp,-02291);
BEGIN --main begin
errmsg := 'OK';
 INSERT INTO CMS_COBRAND_DETAILS(CCD_INST_CODE ,
     CCD_ASSO_CODE ,
     CCD_ACQ_ID    ,
     CCD_TERM_ID   ,
     CCD_INS_USER  ,
     CCD_LUPD_USER )
 VALUES    (instcode ,
     assocode ,
     acqid  ,
     termid  ,
     lupduser ,
     lupduser );
EXCEPTION --main exception
WHEN fk_excp THEN
IF INSTR(SQLERRM,'ASSOMAST')>0 THEN
 errmsg := 'No such associate in the association master.';
ELSIF INSTR(SQLERRM,'INSTMAST')>0 THEN
 errmsg := 'No such institute in the institution master.';
END IF;
WHEN OTHERS THEN
errmsg := 'Main Exception -- '||SQLERRM;
END; --end main begin
/
SHOW ERRORS

