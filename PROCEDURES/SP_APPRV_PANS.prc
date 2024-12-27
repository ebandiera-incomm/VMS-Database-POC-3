CREATE OR REPLACE PROCEDURE VMSCMS."SP_APPRV_PANS" (instCode IN NUMBER, filename IN VARCHAR2, lupdUser IN NUMBER, errmsg OUT VARCHAR2)
AS
/* Commented because this cursor presently will not return any values...jimmy 11th May 2005
CURSOR c1 IS
SELECT  ctp_appl_code
FROM cms_tobeapprv_pans
WHERE ctp_file_name = filename ;
*/

BEGIN
errmsg := 'OK';
-- FOR x IN c1
-- LOOP
-- Forcing the index on the appl_mast table -- jimmy 11th May 2005
  UPDATE  /*+INDEX(CMS_APPL_MAST INDX_APPLMAST_APPLSTAT)*/ CMS_APPL_MAST
  SET  cam_appl_stat = 'R'--reject applications coming from the file
  WHERE cam_inst_code = instCode
--  and cam_appl_code = x.ctp_appl_code; -- creating a sub query -- jimmy 11th May 2005
	AND cam_appl_code IN  (SELECT  ctp_appl_code
	FROM CMS_TOBEAPPRV_PANS
	WHERE ctp_file_name = filename);
-- END LOOP;

-- not required bcoz PBF is not being generated at ICICI...jimmy 11th May 2005
--Imran 9th Jun 2003 begins
/*
update cms_appl_pan
set CAP_PBFGEN_FLAG='D'
where cap_appl_code
 in (SELECT  cam_appl_code
 from cms_appl_mast
WHERE  cam_inst_code = instCode
 AND cam_appl_stat = 'D');
*/
--Imran 9th Jun 2003  ends

 UPDATE  CMS_APPL_MAST
 SET cam_appl_stat = 'A'  --Approve all unrejected pans in pans...
WHERE  cam_inst_code = instCode
 AND cam_appl_stat = 'D';
EXCEPTION
WHEN OTHERS THEN
errmsg := 'Main Excp -- '||errmsg;
END;
/


