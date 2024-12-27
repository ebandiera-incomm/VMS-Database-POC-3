CREATE OR REPLACE PROCEDURE VMSCMS.Sp_Create_Prodrulegroup	(	instcode		IN	NUMBER	,
								prodcode		IN	VARCHAR2	,
								rulegroupcode		IN	VARCHAR2	,
								validfrom		IN	DATE		,
								validto		IN	DATE		,
								lupduser		IN	NUMBER	,
								errmsg		OUT	 VARCHAR2	)
AS
newdate				DATE;
mesg				VARCHAR2(500);
CURSOR c1 IS
SELECT	ppr_rulegroup_code, ppr_valid_to, ppr_valid_from
FROM	PCMS_PROD_RULEGROUP a , RULEGROUPING b
WHERE	a.ppr_inst_code		=	instcode
AND		a.ppr_rulegroup_code		=	b.rulegroupid
AND		a.ppr_prod_code		=	prodcode
AND		(TRUNC(validfrom)		BETWEEN TRUNC(ppr_valid_from) AND TRUNC(ppr_valid_to)
		OR TRUNC(validfrom)	<TRUNC(ppr_valid_from));
CURSOR c2 IS
SELECT  cpc_card_type
FROM	CMS_PROD_CATTYPE
WHERE	cpc_inst_code		=	instcode
AND	cpc_prod_code	=	prodcode;
BEGIN		--main begin starts
errmsg := 'OK';
		BEGIN		--begin 2
		FOR x IN c1
		LOOP		--loop of cursor c1
			IF errmsg != 'OK' THEN	--if 2
				EXIT;
			END IF;				--if 2
			IF	TRUNC(validfrom) <= TRUNC(x.ppr_valid_from) THEN	--if 3
						--insert into shadow and then delete
						INSERT INTO PCMS_ATTCHRULEGROUP_HIST(	PAH_INST_CODE			,
													PAH_RULEGROUP_CODE			,
													PAH_OLD_FROMDATE		,
													PAH_OLD_TODATE		,
													PAH_CHANGE_LEVEL		,
													PAH_PROD_CODE		,
													PAH_CHANGE_SOURCE	,
													PAH_ACTION_TAKEN		,
													PAH_CHANGE_USER		)
											VALUES(	instcode		,
													rulegroupcode		,
													x.ppr_valid_from,
													x.ppr_valid_to	,
													'P'			,
													prodcode		,
													'P'			,
													'DELETE'	,
													lupduser	);
						DELETE	 FROM	PCMS_PROD_RULEGROUP
						WHERE			ppr_inst_code		=	instcode
						AND				ppr_prod_code	=	prodcode
						AND				ppr_rulegroup_code		=	x.ppr_rulegroup_code
						AND				TRUNC(ppr_valid_from) =	 TRUNC(x.ppr_valid_from)
						AND				TRUNC(ppr_valid_to)	=	TRUNC(x.ppr_valid_to);
						IF SQL%ROWCOUNT = 1 THEN	--if 4
							errmsg := 'OK';
						ELSE						--else 4
							errmsg	:= 'Problem in deletion of rulegroup code '||x.ppr_rulegroup_code ||' and valid from date is '||x.ppr_valid_from||' .'	;
						END IF;						--if 4
							--Now perform the changes for waiver
					ELSE											--else 3
						--insert into shadow and then update
						INSERT INTO PCMS_ATTCHRULEGROUP_HIST(	PAH_INST_CODE			,
													PAH_RULEGROUP_CODE			,
													PAH_OLD_FROMDATE		,
													PAH_OLD_TODATE		,
													PAH_CHANGE_LEVEL		,
													PAH_PROD_CODE		,
													PAH_CHANGE_SOURCE	,
													PAH_ACTION_TAKEN		,
													PAH_CHANGE_USER		)
											VALUES(	instcode		,
													rulegroupcode		,
													x.ppr_valid_from,
													x.ppr_valid_to	,
													'P'			,
													prodcode		,
													'P'			,
													'DELETE'	,
													lupduser	);
						newdate					:=	TRUNC(validfrom)-1;
						UPDATE PCMS_PROD_RULEGROUP
						SET		ppr_valid_to		=	newdate,
								ppr_lupd_user		=	lupduser
						WHERE	ppr_inst_code		=	instcode
						AND		ppr_prod_code	=	prodcode
						AND		ppr_rulegroup_code		=	x.ppr_rulegroup_code
						AND		TRUNC(ppr_valid_from)=	TRUNC(x.ppr_valid_from)
						AND		TRUNC(ppr_valid_to)	=	TRUNC(x.ppr_valid_to);
						IF SQL%ROWCOUNT = 1 THEN	--if 5
							errmsg := 'OK';
						ELSE						--else 5
							errmsg	:= 'Problem in  updation of rulegroup code '||x.ppr_rulegroup_code ||'  and valid from date is '||x.ppr_valid_from||' .'	;								--else 7
						END IF;						--if 5
					END IF;							--if 3
		EXIT WHEN c1%NOTFOUND;
		END LOOP;	--loop of cursor c1
		EXCEPTION	--excp of begin 2
			WHEN OTHERS THEN
			errmsg := 'Excp 2 -- '||SQLERRM;
		END;		--end of begin 2
			IF errmsg = 'OK' THEN	--if 6
			BEGIN --begin 3
			INSERT INTO PCMS_PROD_RULEGROUP	(PPR_INST_CODE		,
										PPR_PROD_CODE	,
										PPR_RULEGROUP_CODE		,
										PPR_VALID_FROM	,
										PPR_VALID_TO		,
										PPR_INS_USER		,
										PPR_LUPD_USER		)
							VALUES	(	instcode	,
										prodcode	,
										rulegroupcode	,
										TRUNC(validfrom),
										TRUNC(validto),
										lupduser	,
										lupduser	);
			EXCEPTION	--Excp of begin 3
			WHEN OTHERS THEN
			errmsg := 'Excp 3 -- '||SQLERRM;
			END;		--end begin 3
			END IF;				--if 6
					IF errmsg = 'OK' THEN	--if 7	 --flowdown logic
					FOR y IN c2
					LOOP
						BEGIN		--Begin 4--flowdown logic
							IF	errmsg = 'OK' THEN	--if 8
								  Sp_Create_Prodcattyperulegroup(instcode,prodcode,y.cpc_card_type,rulegroupcode,validfrom,validto,'P',lupduser,mesg);
								IF mesg != 'OK' THEN	--if 9
									errmsg := 'From sp_prodcattyperulegroup for cat type  '||y.cpc_card_type||'  '||mesg;
								ELSE
									errmsg := mesg;
								END IF;				--if 9
							END IF;				--if 8
						EXCEPTION	--excp of begin 4
							WHEN OTHERS THEN
							errmsg := 'Excp 4 -- '||SQLERRM;
						END;		--Begin 4 ends
						EXIT WHEN c2%NOTFOUND;
					END LOOP;
					END IF;				--if 7
EXCEPTION	--Excp of main begin
WHEN OTHERS THEN
errmsg := 'Main Exception -- '||SQLERRM;
END;		--End main begin
/
show error