CREATE OR REPLACE PROCEDURE VMSCMS.sp_attach_custcatgloyl(	instcode		IN	NUMBER	,
							custcatg		IN	NUMBER	,
							loylcode		IN	NUMBER	,
							fromdate		IN	DATE		,
							todate			IN	DATE		,
							flowsource		IN	VARCHAR2	,
							lupduser		IN	NUMBER	,
							errmsg			OUT	 VARCHAR2)
AS

v_clc_catg_sname		CMS_LOYL_CATG.clc_catg_sname%TYPE;
cnt				NUMBER := 0;
CURSOR c1 IS
SELECT cpc_prod_code,cpc_card_type
FROM	CMS_PROD_CCC
WHERE	cpc_inst_code = instcode
AND		cpc_cust_catg = custcatg
ORDER BY cpc_prod_code,cpc_card_type ;

BEGIN		--main begin
errmsg := 'OK';

	BEGIN
	SELECT clc_catg_sname
	INTO	v_clc_catg_sname
	FROM	CMS_LOYL_CATG
	WHERE	clc_inst_code = instcode
	AND	clc_catg_code =		(	SELECT	clm_loyl_catg
						FROM	CMS_LOYL_MAST
						WHERE	clm_inst_code	=	instcode
						AND	clm_loyl_code	=	loylcode);
	IF v_clc_catg_sname != 'CCAT' THEN
	errmsg := 'Allowed only for Customer category based loyalty';
	END IF;
	EXCEPTION
	WHEN OTHERS THEN
	errmsg := 'Excp 1 -- '||SQLERRM;
	END;

	IF errmsg = 'OK' THEN
	BEGIN		--begin 2
		FOR x IN c1
		LOOP
		IF errmsg != 'OK' THEN
		EXIT;
		END IF;
			--call the loyalty attachment procedure at the PCCC level
			pack_cms_loylattach.sp_create_prodcccloyl(instcode,custcatg,x.cpc_prod_code,x.cpc_card_type,loylcode,fromdate,todate,'EXP',lupduser,errmsg);
			IF errmsg != 'OK' THEN
			errmsg := 'From attachment proc for product '||x.cpc_prod_code ||' and prod cattype '||x.cpc_card_type||' --'||errmsg;
			END IF;
			cnt := cnt+1;
		EXIT WHEN c1%NOTFOUND;
		END LOOP;
	EXCEPTION	--excp of begin2
	WHEN OTHERS THEN
	errmsg := 'Excp 2-- '||SQLERRM;
	END;		--begin 2 ends
	END IF;

	IF errmsg = 'OK' AND cnt = 0 THEN
	errmsg := 'Customer category not attached with any of the existing product category';
	END IF;

EXCEPTION	-- excp of main begin
WHEN OTHERS THEN
errmsg := 'Main Excp --'||SQLERRM;
END;		--main begin ends
/


show error