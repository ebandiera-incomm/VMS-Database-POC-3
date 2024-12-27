CREATE OR REPLACE PROCEDURE VMSCMS.Sp_Ins_Base2rpi   (ERRMSG        OUT             VARCHAR2)
AS
BEGIN
        errmsg:= 'OK';
	UPDATE REC_CTF_RECO_TEMP SET rcr_purch_date=SUBSTR(rcr_ctf_file ,5,2)||SUBSTR(rcr_ctf_file ,3,2) ,
	rcr_purch_year = SUBSTR(rcr_ctf_file,7,2)||SUBSTR(rcr_ctf_file ,5,2)||SUBSTR(rcr_ctf_file ,3,2) WHERE rcr_purch_date='0000';
   UPDATE REC_CTF_RECO_TEMP SET rcr_auth_code = LPAD(trim(rcr_auth_code),6,'0'),RCR_PAN_NUMB=TRIM(RCR_PAN_NUMB);
	INSERT INTO CHG_BASE2_RPI
	(SELECT  a.*,NULL,NULL,NULL,NULL,NULL
	FROM REC_CTF_RECO_TEMP a
	WHERE RCR_TRAN_CODE IN ('05','07')
AND rcr_usage_code='2' );
EXCEPTION
        WHEN OTHERS THEN
                ERRMSG:= 'Exep Main ......'||SQLERRM;
END;
/


