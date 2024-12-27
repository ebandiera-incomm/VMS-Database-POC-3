CREATE OR REPLACE PROCEDURE VMSCMS.Sp_Create_Prodcattyperulegroup(	instcode		IN	NUMBER	,
									prodcode		IN	VARCHAR2	,
									cardtype		IN	NUMBER	,
									rulegroupcode		IN	NUMBER	,
									validfrom		IN	DATE		,
									validto		IN	DATE		,
									flowsource	IN	VARCHAR2	,
									lupduser		IN	NUMBER	,
									errmsg		OUT	 VARCHAR2	)
AS
v_flowsource			VARCHAR2(3);
newdate				DATE;
mesg				VARCHAR2(500);
CURSOR c1 IS
SELECT	ppr_rulegroup_code, ppr_valid_to, ppr_valid_from
FROM	PCMS_PRODCATTYPE_RULEGROUP a , RULEGROUPING b
WHERE	a.ppr_inst_code		=	instcode
AND		a.ppr_rulegroup_code		=	b.rulegroupid
AND		a.ppr_prod_code		=	prodcode
AND		a.ppr_card_type		=	cardtype
AND		(TRUNC(validfrom)		BETWEEN TRUNC(ppr_valid_from) AND TRUNC(ppr_valid_to)
		OR TRUNC(validfrom)	< TRUNC(ppr_valid_from));
CURSOR c2 IS
SELECT  cpc_cust_catg
FROM	CMS_PROD_CCC
WHERE	cpc_inst_code		=	instcode
AND		cpc_prod_code	=	prodcode
AND		cpc_card_type	=	cardtype;
BEGIN		--Main begin
errmsg := 'OK' ;
IF flowsource = 'EXP' THEN--this means that the procedure is explicitly called
	v_flowsource := 'PCT';
ELSE	--this means that the procedure is called from some level above PCT. i.e. from product level(P)
	v_flowsource := flowsource;
END IF;
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
													PAH_CAT_TYPE			,
													PAH_CHANGE_SOURCE	,
													PAH_ACTION_TAKEN		,
													PAH_CHANGE_USER		)
											VALUES(	instcode		,
													rulegroupcode		,
													x.ppr_valid_from,
													x.ppr_valid_to	,
													'PCT'		,
													prodcode		,
													cardtype		,
													v_flowsource	,
													'DELETE'	,
													lupduser	);
						DELETE	 FROM	PCMS_PRODCATTYPE_RULEGROUP
						WHERE			ppr_inst_code		=	instcode
						AND				ppr_prod_code	=	prodcode
						AND				ppr_card_type		=	cardtype
						AND				ppr_rulegroup_code		=	x.ppr_rulegroup_code
						AND				TRUNC(ppr_valid_from) =	 TRUNC(x.ppr_valid_from)
						AND				TRUNC(ppr_valid_to)	=	TRUNC(x.ppr_valid_to);
						IF SQL%ROWCOUNT = 1 THEN	--if 4
								errmsg := 'OK';
						ELSE						--else 4
							IF v_flowsource = 'PCT' THEN--tells us from which level this proc is called so thet the error message can be customised		--if 5
								errmsg	:= 'Problem in deletion of fee code '||x.ppr_rulegroup_code ||' and valid from date is '||x.ppr_valid_from||' .'	;
							ELSE																							--else 5
								errmsg	:= 'From sp_create_prodcattypefee -- Problem in deletion of fee code '||x.ppr_rulegroup_code ||'and valid from date is '||x.ppr_valid_from||'  .'	;
							END IF;																							--if 5
						END IF;						--if 4
					ELSE											--else 3
						--insert into shadow and then update
						INSERT INTO PCMS_ATTCHRULEGROUP_HIST(	PAH_INST_CODE			,
													PAH_RULEGROUP_CODE			,
													PAH_OLD_FROMDATE		,
													PAH_OLD_TODATE		,
													PAH_CHANGE_LEVEL		,
													PAH_PROD_CODE		,
													PAH_CAT_TYPE			,
													PAH_CHANGE_SOURCE	,
													PAH_ACTION_TAKEN		,
													PAH_CHANGE_USER		)
											VALUES(	instcode		,
													rulegroupcode		,
													x.ppr_valid_from,
													x.ppr_valid_to	,
													'PCT'		,
													prodcode		,
													cardtype		,
													v_flowsource	,
													'DELETE'	,
													lupduser	);
						newdate					:=	TRUNC(validfrom)-1;
						UPDATE PCMS_PRODCATTYPE_RULEGROUP
						SET		ppr_valid_to		=	newdate,
								ppr_lupd_user		=	lupduser
						WHERE	ppr_inst_code		=	instcode
						AND		ppr_prod_code	=	prodcode
						AND		ppr_card_type		=	cardtype
						AND		ppr_rulegroup_code		=	x.ppr_rulegroup_code
						AND		TRUNC(ppr_valid_from)=	TRUNC(x.ppr_valid_from)
						AND		TRUNC(ppr_valid_to)	=	TRUNC(x.ppr_valid_to);
						IF SQL%ROWCOUNT = 1 THEN	--if 6
							errmsg := 'OK';
						ELSE						--else 6
							IF v_flowsource = 'PCT' THEN--tells us from which level this proc is called so thet the error message can be customised	--if 7
								errmsg	:= 'Problem in  updation of rulegroup code '||x.ppr_rulegroup_code ||'  and valid from date is '||x.ppr_valid_from||' .'	;								--else 7
							ELSE
								errmsg	:= 'From sp_create_prodcattyperulegroup -- Problem in updation of rulegroup code '||x.ppr_rulegroup_code ||' and valid from date is '||x.ppr_valid_from||' .'	;	--if 7
							END IF;
						END IF;						--if 6
					END IF;							--if 3
		EXIT WHEN c1%NOTFOUND;
		END LOOP;	--loop of cursor c1
		EXCEPTION	--excp of begin 2
			WHEN OTHERS THEN
			errmsg := 'Excp 2 -- '||SQLERRM;
		END;		--end of begin 2
		IF errmsg = 'OK' THEN	--if 8
		BEGIN --begin 3
		INSERT INTO PCMS_PRODCATTYPE_RULEGROUP	(	PPR_INST_CODE		,
											PPR_PROD_CODE	,
											PPR_CARD_TYPE		,
											PPR_RULEGROUP_CODE		,
											PPR_VALID_FROM	,
											PPR_VALID_TO		,
											PPR_FLOW_SOURCE	,
											PPR_INS_USER		,
											PPR_LUPD_USER		)
								VALUES	(	instcode			,
											prodcode			,
											cardtype			,
											rulegroupcode			,
											TRUNC(validfrom)	,
											TRUNC(validto)		,
											v_flowsource		,
											lupduser			,
											lupduser	);
		EXCEPTION	--excp of begin 3
			WHEN OTHERS THEN
			errmsg := 'Excp 3 -- '||SQLERRM;
		END;		--end begin 3
		END IF;				--if 8
EXCEPTION	--Excp of main begin
	WHEN OTHERS THEN
	errmsg := 'Main Exception -- '||SQLERRM;
END;		--End main begin
/
show error