CREATE OR REPLACE PROCEDURE VMSCMS.sp_gen_insta_check
(
prm_acctno   IN VARCHAR2,
prm_cardstat IN CHAR DEFAULT '0',
prm_errmsg   OUT VARCHAR2
)
as
begin
prm_errmsg:='OK';
IF substr(prm_acctno,5,12)='SMILECRD' and prm_cardstat='0' 
THEN
    prm_errmsg:='Can not perform support function on instant card before reissue to any customer. ';
END IF;
END;
/
SHOW ERRORS

