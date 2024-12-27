CREATE OR REPLACE PROCEDURE VMSCMS.sp_create_groupprog	(instcode		IN	NUMBER	,
												groupcode	IN	NUMBER	,
												progcode		IN	NUMBER	,
												lupduser		IN	NUMBER	,
												errmsg		OUT	 VARCHAR2	 )
AS
dum		NUMBER (3);
err		NUMBER (3) :=0	;
v_cpm_menu_link	CMS_PROG_MAST.cpm_menu_link%TYPE;
v_cpm_menu_link1	CMS_PROG_MAST.cpm_menu_link%TYPE;
BEGIN		--Main Begin Block Starts Here

/*	-- begin 0 added on 17-06-02 to find out the user group of the user allocating the programs to check that the user belonging to a group cannot allocate programs to his own group
	BEGIN
		SELECT cug_group_code
		INTO	v_cug_group_code
		FROM	cms_user_groupmast
		WHERE	cug_inst_code			=	instcode
		AND		cug_user_code		=
	EXCEPTION
		WHEN NO_DATA_FOUND THEN
		errmsg	:= '';
		WHEN OTHERS THEN
		errmsg	:= 'Excp 0 -- '||SQLERRM;
	END;*/


			BEGIN	--begin 1
				SELECT	cpm_menu_link
				INTO	v_cpm_menu_link
				FROM	CMS_PROG_MAST
				WHERE	cpm_prog_code  =  progcode
				AND cpm_inst_code = instcode;
			EXCEPTION	--excp of begin 1
				WHEN NO_DATA_FOUND THEN
				errmsg := 'No such program code in program master';
				err	:=	err+1;
				WHEN OTHERS THEN
				errmsg := 'Excp 1 -- '||SQLERRM;
				err	:=	err+1;
			END;	--end of begin 1

			IF	err = 0 THEN
			BEGIN	--begin 2
				SELECT COUNT(*)
				INTO	dum
				FROM	CMS_GROUP_PROG
				WHERE	cgp_inst_code		=	instcode
				AND		cgp_group_code	=	groupcode
				AND		cgp_prog_code	=	v_cpm_menu_link;

					IF	dum = 0 THEN
						INSERT INTO CMS_GROUP_PROG
						(	CGP_INST_CODE		,
							CGP_GROUP_CODE	,
							CGP_PROG_CODE	,
							CGP_INS_USER		,
							CGP_LUPD_USER	)
						VALUES(	instcode			,
								groupcode		,
								v_cpm_menu_link	,
								lupduser			,
								lupduser		);
					END IF;
			EXCEPTION	--excp of begin 2
				WHEN OTHERS THEN
				errmsg := 'Excp 2 -- '||SQLERRM;
				err	:=	err+1;
			END;	--end of begin 2
			END IF;




			BEGIN	--begin 3
				SELECT	cpm_menu_link
				INTO	v_cpm_menu_link1
				FROM	CMS_PROG_MAST
				WHERE	cpm_prog_code  =  v_cpm_menu_link
				AND cpm_inst_code = instcode;
			EXCEPTION	--excp of begin 3
				WHEN NO_DATA_FOUND THEN
				errmsg := 'No such program code in program master';
				err	:=	err+1;
				WHEN OTHERS THEN
				errmsg := 'Excp 3 -- '||SQLERRM;
				err	:=	err+1;
			END;	--end of begin 3

			IF	err = 0 THEN
			BEGIN	--begin 4
				SELECT COUNT(*)
				INTO	dum
				FROM	CMS_GROUP_PROG
				WHERE	cgp_inst_code		=	instcode
				AND		cgp_group_code	=	groupcode
				AND		cgp_prog_code	=	v_cpm_menu_link1;

					IF	dum = 0 THEN
						INSERT INTO CMS_GROUP_PROG
						(	CGP_INST_CODE		,
							CGP_GROUP_CODE	,
							CGP_PROG_CODE	,
							CGP_INS_USER		,
							CGP_LUPD_USER	)
						VALUES(	instcode			,
								groupcode		,
								v_cpm_menu_link1	,
								lupduser			,
								lupduser		);
					END IF;
			EXCEPTION	--excp of begin 4
				WHEN OTHERS THEN
				errmsg := 'Excp 4 -- '||SQLERRM;
				err	:=	err+1;
			END;	--end of begin 4
			END IF;




				IF err = 0 THEN
				INSERT INTO CMS_GROUP_PROG
					(	CGP_INST_CODE		,
						CGP_GROUP_CODE	,
						CGP_PROG_CODE	,
						CGP_INS_USER		,
						CGP_LUPD_USER	)
				VALUES(	instcode		,
						groupcode	,
						progcode	 	,
						lupduser		,
						lupduser		);
				END IF;
	IF err = 0 THEN
		errmsg := 'OK';
	END IF;
EXCEPTION	--Main block Exception
	WHEN OTHERS THEN
	errmsg := 'Main Exception -- '||SQLERRM;
END;		--Main Begin Block Ends Here
/
show error