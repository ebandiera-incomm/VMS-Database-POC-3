CREATE OR REPLACE PROCEDURE VMSCMS.sp_check_cardstat
(prm_instcode IN NUMBER,
prm_acctno IN VARCHAR2,
prm_defcardstat IN VARCHAR2,
prm_cardstat OUT CHAR,
prm_errmsg OUT VARCHAR2)
as
begin
prm_errmsg:='OK';
 if substr(prm_acctno,5,12)='SMILECRD' THEN
    prm_cardstat:='0';
 else
   prm_cardstat:=prm_defcardstat;
 end if;
exception when others then
prm_errmsg:='Errorw while checking the status for card '||substr(sqlerrm,1,200);
return;
end;
/
SHOW ERROR