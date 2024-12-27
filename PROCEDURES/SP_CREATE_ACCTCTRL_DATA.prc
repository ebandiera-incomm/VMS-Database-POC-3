CREATE OR REPLACE PROCEDURE VMSCMS.Sp_Create_Acctctrl_Data(	instcode	IN	NUMBER	,
							brancode	IN	VARCHAR2,
							insuser	IN	NUMBER	,
                            insdate IN  DATE,
							lupduser	IN	NUMBER	,
                            lupddate IN  DATE,
							errmsg		OUT	VARCHAR2)
AS
dum NUMBER(5) ;
v_pslno NUMBER(10) ;


BEGIN	--main begin
	errmsg := 'OK';
			IF brancode IS NOT NULL THEN
			
				BEGIN -- begin 2

					-- check whether record exists for the combination of
					-- Branch.
					SELECT 1
					INTO dum
					FROM CMS_ACCT_CTRL
					WHERE cac_inst_code = instcode AND
					      cac_bran_code = brancode;
						  
				EXCEPTION
				WHEN NO_DATA_FOUND THEN
					 -- If No Record Exist in CMS_ACCT_CTRL add new.

					 INSERT INTO CMS_ACCT_CTRL(
					 			 CAC_INST_CODE ,
						 		 CAC_BRAN_CODE ,
								 CAC_CTRL_NUMB  ,
								 CAC_MAX_SERIAL_NO ,
								 CAC_LUPD_DATE,
								 CAC_LUPD_USER,
                                 CAC_INS_DATE ,
								 CAC_INS_USER
								  )
 						 VALUES( instcode	,
								 brancode	,
								 '1'	,
								 '99999'	,
								 lupddate,
								 lupduser	,
                                 insdate,
								 insuser	);
				END ; --end  2
		ELSE
			errmsg := 'Expected Branch Code.';
		END IF;
	--END IF;
EXCEPTION
WHEN OTHERS THEN	--excp of main begin
errmsg := 'Main Excp -- '||SQLERRM;
END;	--end main begin
/


