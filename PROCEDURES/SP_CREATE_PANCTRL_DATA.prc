CREATE OR REPLACE PROCEDURE VMSCMS.Sp_Create_Panctrl_Data(	instcode	IN	NUMBER	,
							prodcode	IN	VARCHAR2,
							prodPrefix IN VARCHAR2,
							source_pointer	IN	VARCHAR2,-- Card Type.
							lupduser	IN	NUMBER	,
							errmsg		OUT	VARCHAR2)
AS
dum NUMBER(5) ;
v_pslno NUMBER(10) ;

v_cbm_inst_bin	CMS_PROD_BIN.cpb_inst_bin%TYPE;
BEGIN	--main begin
	errmsg := 'OK';
	IF source_pointer = 'PRODCATTYPE' THEN
		IF prodcode IS NOT NULL THEN
			BEGIN	--begin 2
				-- Select Bin Attached to the Product.
				SELECT CPB_INST_BIN
				INTO v_cbm_inst_bin
				FROM CMS_PROD_BIN
				WHERE CPB_PROD_CODE = prodcode;

				BEGIN -- begin 3

					-- check whether record exists for the combination of
					-- Bin and Product-Prefix.
					SELECT 1
					INTO dum
					FROM CMS_PANGEN_CTRL
					WHERE cpc_inst_code = instcode AND
					      cpc_ctrl_prod = LPAD(prodPrefix, 2,'0')	 AND
						  cpc_ctrl_bin = v_cbm_inst_bin AND
						  CPC_CTRL_CATG = 'NORMAL';
				EXCEPTION
				WHEN NO_DATA_FOUND THEN
					 -- If No Record Exist in CMS_PANGEN_CTRL add new.

					 INSERT INTO CMS_PANGEN_CTRL(
					 			 CPC_INST_CODE ,
						 		 CPC_CTRL_PROD ,
								 CPC_CTRL_BIN  ,
								 CPC_CTRL_BRAN ,
								 CPC_CTRL_CATG ,
								 CPC_CTRL_NUMB ,
								 CPC_INS_USER  ,
								 CPC_LUPD_USER )
 						 VALUES( instcode	,
								 LPAD(prodPrefix, 2,'0')	,
								 v_cbm_inst_bin	,
								 '899999'	,
								 'NORMAL'	,
								 '1',
								 lupduser	,
								 lupduser	);
				END ; --end  3
			EXCEPTION	--excp of begin 2
			WHEN NO_DATA_FOUND THEN
				errmsg := 'Excp 2 for Interchange '||prodcode||' No Bin Found';
			WHEN OTHERS THEN
				errmsg := 'Excp 2 for Interchange '||prodcode||' -- '||SQLERRM;
			END;	--end of begin 2
		ELSE
			errmsg := 'Expected Product Code.';
		END IF;
	END IF;
EXCEPTION
WHEN OTHERS THEN	--excp of main begin
errmsg := 'Main Excp -- '||SQLERRM;
END;	--end main begin
/
show error