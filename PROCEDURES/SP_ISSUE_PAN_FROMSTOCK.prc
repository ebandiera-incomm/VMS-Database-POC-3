CREATE OR REPLACE PROCEDURE VMSCMS.Sp_Issue_Pan_Fromstock (	instcode	IN	NUMBER	,
												pancode	 	IN	VARCHAR2	,
												mbrnumb		IN	VARCHAR2	,
												remark		IN	VARCHAR2	,
												newdisp		IN	VARCHAR2	,--new display name, if null, keep the old display name
												newprodcode IN	VARCHAR2,--shyamjith 18 jan 05 --- cr 97 change of bin during reissue
												newprodcat  IN  VARCHAR2, --shyamjith
												rsncode		IN	NUMBER	,
												lupduser	IN	NUMBER	,
												--newpan	OUT	VARCHAR2	,
												newpan	     IN	VARCHAR2	,--sandip we hav new pan already
												errmsg	     OUT   VARCHAR2)
AS
v_cap_prod_catg	VARCHAR2(2)	;
v_mbrnumb		VARCHAR2(3)	;
dum				NUMBER(1)	;
v_cap_cafgen_flag	CHAR(1)		;
v_cap_card_stat CHAR(1);
software_pin_gen	CHAR(1)		;
/*
CURSOR c1 IS	--this cursor finds the addon cards which were attached to the previousPAN so that they can be pointed towards the PAN being reissued
SELECT	cap_pan_code,cap_mbr_numb
FROM	CMS_APPL_PAN
WHERE	cap_addon_link	=	pancode
AND		cap_mbr_numb	=	mbrnumb
AND		cap_addon_stat = 'A'      ;
*/
BEGIN		--Main begin starts
IF	mbrnumb IS NULL  THEN
	v_mbrnumb := '000';
ELSE
   v_mbrnumb:=mbrnumb;
END IF;
errmsg := 'OK';
	IF errmsg = 'OK' THEN
		BEGIN		--begin 1 starts
-- this is to carry forward the important details of the old card to the new one...
		SELECT cap_prod_catg, cap_cafgen_flag, cap_card_stat
		INTO	v_cap_prod_catg, v_cap_cafgen_flag, v_cap_card_stat
		FROM	CMS_APPL_PAN
		WHERE	cap_pan_code	=	pancode   --old pan code
		AND		cap_mbr_numb	=	v_mbrnumb;
		EXCEPTION	--excp of begin 1
		WHEN NO_DATA_FOUND THEN
		errmsg := 'Old PAN Not found.';
		WHEN OTHERS THEN
		errmsg := ' Exception while Fetching Old Pan Dtls';
		--errmsg := 'Excp 1 -- '||SQLERRM;
		END;		--begin 1 ends
	END IF;
IF errmsg = 'OK' AND v_cap_cafgen_flag = 'N' THEN	--cafgen if
errmsg := 'CAF has to be generated atleast once for OLD pan';
ELSE
	--now update the status of the old card as closed
	-- shyamjith 04-aug-05 as bank's request open cards should also be reissued and old open cards should not be closed
	-- CR 162 --CARDS WITH STAT 1 NEED TO  REISSUED
	/*
	IF errmsg = 'OK'  	   --AND v_cap_card_stat != '1'
	THEN
	BEGIN			--begin 5 starts
	dbms_output.put_line('BEFORE UPDATING CMS_APPL_PAN-Issue_pan');
	UPDATE CMS_APPL_PAN
	SET		cap_card_stat		= 9,
			cap_lupd_user	= lupduser
	WHERE	cap_inst_code		= instcode
	AND		cap_pan_code	= pancode
	AND		cap_mbr_numb	= v_mbrnumb;
	IF SQL%ROWCOUNT != 1 THEN
	errmsg := 'Problem in updation of status for pan '||pancode||'.';
	END IF;
	EXCEPTION		--excp of begin 4
	WHEN OTHERS THEN
	errmsg := 'Problem while Update of Status for Pan ';
	--errmsg := 'Excp 5 -- '||SQLERRM;
	END;			--begin 5 ends
	END IF;
*/
	IF	errmsg = 'OK' THEN
		BEGIN		--begin 2 starts
		Sp_Pan_Update_Fromstock(pancode,v_mbrnumb,lupduser,newdisp,newprodcode,newprodcat,newpan,errmsg);    --sandip Cr 162
		-- the exra paramaters in the above line have been added for the purpose of re-issuing
		-- the card as a separate product
		IF errmsg != 'OK' THEN
		errmsg :=errmsg;
			-- SN Shekar Jan.12.2006, error hadler to stop process on exception.
    			ROLLBACK;
         		RETURN;
			-- EN Shekar Jan.12.2006, error hadler to stop process on exception.
        dbms_output.put_line('pt 1 errmsg '||errmsg);
		--errmsg := 'Error while Updation of New Pan Details ';
		--errmsg := 'From Sp_pan_update_fromStock -- '||errmsg;
		END IF;
					--Caf Refresh for new pan
					software_pin_gen := 'N'; --means that the software pin generation will be out of the system so generate caf here itself
										--to be parameterinsed at the inst level.
					IF software_pin_gen = 'N' THEN	--soft_pin_gen_if
					IF errmsg = 'OK' THEN
					BEGIN		--Begin 6
					SELECT COUNT(*)
					INTO	dum
					FROM	CMS_CAF_INFO
					WHERE	cci_inst_code				=	instcode
					AND		cci_pan_code		=	RPAD(newpan,19,' ')
					AND		cci_mbr_numb			=	v_mbrnumb;
					IF dum = 1 THEN--that means there is a row in cafinfo for that pan but file is not generated
					DELETE FROM CMS_CAF_INFO
					WHERE	cci_inst_code				=	instcode
					AND		cci_pan_code		=	RPAD(newpan,19,' ')
					AND		cci_mbr_numb			=	v_mbrnumb;
					END IF;
					--call the procedure to insert into cafinfo
					-- The support funnction name has to be changed *************************** add in CAF-RFRSH also
					  dbms_output.put_line('Before calling Sp_Caf_Rfrsh for new pan');
					Sp_Caf_Rfrsh(instcode,newpan,v_mbrnumb,SYSDATE,'C',remark,'LINK',lupduser,errmsg);
					dbms_output.put_line('After calling Sp_Caf_Rfrsh for new pan');
					IF errmsg != 'OK' THEN
					   --errmsg := 'Error After caf refresh for new pan-- '||errmsg;
					   errmsg := 'Error While caf refresh for new pan-- '||substr(errmsg,1,200);
			-- SN Shekar Jan.12.2006, error hadler to stop process on exception.
    			ROLLBACK;
         		RETURN;
			-- EN Shekar Jan.12.2006, error hadler to stop process on exception.
					END IF;
					EXCEPTION	--Excp 6
					WHEN OTHERS THEN
					errmsg := 'Error After caf refresh for new pan-- '||errmsg;
					--errmsg := 'Excp 6 -- '||SQLERRM;
					END;		--End of begin 6
					END IF;
					END IF ;--soft_pin_gen_if
					--Caf Refresh for old(closed) pan
	-- shyamjith 04-aug-05 as bank's request open cards should also be reissued and old open cards should not be closed
					IF errmsg = 'OK'  THEN -- AND v_cap_card_stat != '1' THEN
					BEGIN		--Begin 7
			--added  on 21012008 by soniya to get the files in sync with UAT
					UPDATE CMS_CAF_INFO
					SET cci_crd_stat = '1'  --Prajakta 21/01/08
					WHERE cci_inst_code				=	instcode
					AND		cci_pan_code		=	RPAD(newpan,19,' ')
					AND		cci_mbr_numb			=	v_mbrnumb;
			 --added to get the files in sync with UAT
					SELECT COUNT(*)
					INTO	dum
					FROM	CMS_CAF_INFO
					WHERE	cci_inst_code				=	instcode
					AND		cci_pan_code		=	RPAD(pancode,19,' ')
					AND		cci_mbr_numb			=	v_mbrnumb;
					IF dum = 1 THEN--that means there is a row in cafinfo for that pan but file is not generated
					DELETE FROM CMS_CAF_INFO
					WHERE	cci_inst_code				=	instcode
					AND		cci_pan_code		=	RPAD(pancode,19,' ')
					AND		cci_mbr_numb			=	v_mbrnumb;
					END IF;
					--call the procedure to insert into cafinfo
					    dbms_output.put_line('Before calling Sp_Caf_Rfrsh for old pan');
					Sp_Caf_Rfrsh(instcode,pancode,v_mbrnumb,SYSDATE,'C',remark,'REISU',lupduser,errmsg)		;
					  dbms_output.put_line('after calling Sp_Caf_Rfrsh for old pan');
					IF errmsg != 'OK' THEN
					--errmsg := 'Error while caf refresh for old pan -- '||errmsg;
					errmsg := 'Error while caf refresh for old pan -- '||substr(errmsg,1,200);
			-- SN Shekar Jan.12.2006, error hadler to stop process on exception.
    			ROLLBACK;
         		RETURN;
			-- EN Shekar Jan.12.2006, error hadler to stop process on exception.
					END IF;
					EXCEPTION	--Excp 7
					WHEN OTHERS THEN
					errmsg := 'Error while caf refresh for old pan --- '||substr(errmsg,1,200);
					--errmsg := 'Excp 7 -- '||SQLERRM;
					END;		--End of begin 7
					END IF;
		EXCEPTION	--excp of begin 2
		WHEN OTHERS THEN
		errmsg := 'Error while caf refresh for pan -- '||substr(errmsg,1,200);
		--errmsg := 'Excp 2 -- '||SQLERRM;
		END;		--begin 2 ends
	END IF;
	IF errmsg = 'OK' THEN
		BEGIN		--Begin 3 starts
		INSERT INTO CMS_PAN_SPPRT	(	CPS_INST_CODE		,
										CPS_PAN_CODE		,
										CPS_MBR_NUMB		,
										CPS_PROD_CATG	,
										CPS_SPPRT_KEY		,
										CPS_FUNC_REMARK	,
										CPS_SPPRT_RSNCODE,
										CPS_INS_USER		,
										CPS_LUPD_USER		)
							VALUES(		instcode		,
										pancode		,
										v_mbrnumb		,
										v_cap_prod_catg,
										'REISU'		,
										remark		,
										rsncode		,
										lupduser		,
										lupduser		);
		EXCEPTION	--excp of begin 3
		WHEN OTHERS THEN
		errmsg := 'Excption - Card Details Updation Error '||SQLERRM;
		--errmsg := 'Excp 3 -- '||SQLERRM;
		END;		--begin 3 ends
	END IF;
	IF errmsg = 'OK'  THEN
		BEGIN			--begin 4 starts
			INSERT INTO CMS_HTLST_REISU	(	CHR_INST_CODE		,
											CHR_PAN_CODE		,
											CHR_MBR_NUMB		,
											CHR_NEW_PAN		,
											CHR_NEW_MBR		,
											CHR_REISU_CAUSE	,
											CHR_INS_USER		,
											CHR_LUPD_USER	)
								VALUES	(	instcode		,
											pancode		,
											v_mbrnumb	,
											newpan		,
											'000'			,
											'H'			,--hardcoded temporarily...to be removed once reissue after expiry is decided
											lupduser		,
											lupduser		);
		EXCEPTION		--excp of begin 4
			WHEN OTHERS THEN
			errmsg := ' Given Pan is already reissued once ';
			--errmsg := 'Excp 4 -- Given Pan is already reissued once '||SQLERRM;
		END;			--begin 4 ends
	END IF;
END IF;	--cafgen if
EXCEPTION	--Excp of main begin
	WHEN OTHERS THEN
	errmsg := 'Main Exception while Reissuing Pan - Details not Found';
	--errmsg := 'Main Exception -- '||SQLERRM;
END;		--Main begin ends
/


