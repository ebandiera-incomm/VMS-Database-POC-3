CREATE OR REPLACE PROCEDURE VMSCMS.sp_pop_ttum	(	instcode		IN		NUMBER	,
							popforloyl		IN		CHAR	,--F = population for fees, L = population for loyalty
							lupduser		IN		NUMBER	,
							errmsg			OUT		VARCHAR2)
AS
ttum_rows	NUMBER(6)	;
filename	VARCHAR2(18)	;
file_type	CHAR(1)		;
totrows		NUMBER (6)	;
extn		VARCHAR2(3)	;
unusedfile	CHAR(1)		;

--picks up data from charges table
CURSOR c1 IS
SELECT	a.ccd_fee_trans,a.ccd_acct_no, a.ccd_calc_amt, a.ccd_pan_code,c.cft_feetype_desc,a.ccd_fee_freq
FROM	CMS_CHARGE_DTL a,CMS_FEE_MAST b,CMS_FEE_TYPES c
WHERE	a.ccd_inst_code		=	b.cfm_inst_code
AND	a.ccd_fee_code		=	b.cfm_fee_code
AND	b.cfm_inst_code		=	c.cft_inst_code
AND	b.cfm_feetype_code	=	c.cft_feetype_code
AND	a.ccd_inst_code		=	instcode
AND	TRUNC(a.ccd_file_date)  <=	TRUNC(SYSDATE)--the date on which these records are supposed to go into the ttum file
AND	a.ccd_file_name		=	'N';--only those records which are not yet populated into the ttum upload table

--picks up branches to limit the c3 cursor size
CURSOR c2 IS
SELECT cbm_bran_code
FROM	CMS_BRAN_MAST
WHERE	cbm_inst_code		=	instcode;

--picks up data from redeemed loyalties table
CURSOR c3(c_brancode IN VARCHAR2) IS
SELECT	crl_acct_no,crl_calc_amt,crl_loyl_ind,crl_parti_cular
FROM	CMS_REDEEM_LOYL
WHERE	crl_inst_code		=	instcode
AND	crl_curr_bran		=	c_brancode
AND	crl_file_name		=	'N'	;

--1. Local procedure to select the no of rows parameter from the parameter table for the ttum file
PROCEDURE lp1_find_rows_param(ttum_rows OUT NUMBER,lperr1 OUT VARCHAR2)
IS
BEGIN		--begin lp1
lperr1 := 'OK';
SELECT cip_param_value
INTO	ttum_rows
FROM	CMS_INST_PARAM
WHERE	cip_inst_code = instcode
AND	cip_param_key = 'TTUM ROWS';
--ttum_rows	:=	ttum_rows -1; commented on 10/10/2002  because earlier, one row was reserved for the bank row  which is not the case now
EXCEPTION	--excp of lp1
WHEN NO_DATA_FOUND THEN
lperr1	:= 'Please set the rows per file parameter for ttum file';
WHEN OTHERS THEN
lperr1	:= 'LP1 Excp -- '||SQLERRM;
END;		--end lp1

--2. Local procedure to find out the file name in use or to create the new file if none is in use
PROCEDURE lp2_ttum_file_name(filetype IN CHAR, v_ctc_file_name OUT VARCHAR2,v_ctc_tot_rows OUT NUMBER,lperr2 OUT VARCHAR2)
IS

BEGIN		--begin lp2
lperr2	:=	'OK'	;
unusedfile :=	'N'	;
	SELECT	ctc_file_name, ctc_tot_rows
	INTO	v_ctc_file_name, v_ctc_tot_rows
	FROM	CMS_TTUM_CTRL
	WHERE	ctc_inst_code	= instcode
	AND	ctc_file_type	= filetype
	AND	ctc_file_inuse	= 'Y';
	dbms_output.put_line('1. Name of existing inuse file = '||v_ctc_file_name);
	dbms_output.put_line('2. No of rows in existing inuse file = '||v_ctc_tot_rows);
	IF v_ctc_tot_rows = 0 THEN
	unusedfile := 'Y';--tot rows  = 0 means that the file is generated but not used ...
	END IF;

	IF v_ctc_tot_rows >= ttum_rows  THEN--means that the file can still be used for populating more records untill the counter reaches the ttum_rows -1(1 more row for reverse entry)
	--time to create new file and update the old one as closed
	dbms_output.put_line('in the doubt full condition');
	UPDATE	CMS_TTUM_CTRL
	SET	ctc_file_inuse	= 'N'
	WHERE	ctc_inst_code	= instcode
	AND	ctc_file_name	= v_ctc_file_name
	AND	ctc_file_type	= filetype;
	RAISE  NO_DATA_FOUND;
	END IF;

EXCEPTION	--excp of lp2
WHEN NO_DATA_FOUND THEN
	SELECT LPAD(seq_ttum_extn.NEXTVAL,3,0)
	INTO	extn
	FROM	dual;
	SELECT TO_CHAR(SYSDATE,'ddmmyy_')||extn||'.ttum',0
	INTO	v_ctc_file_name,v_ctc_tot_rows
	FROM	dual		;
WHEN OTHERS THEN
lperr2	:= 'LP2 Excp -- '||SQLERRM;
END;		--end lp2


--3. Local procedure to populate the cms_ttum_upload, update cms_ttum_ctrl and cms_charge_dtl tables
PROCEDURE lp3_ins_upd_main_oprn(filename IN VARCHAR2,filetype IN CHAR,totrows IN NUMBER,acctno IN VARCHAR2,amount IN NUMBER,particulars IN VARCHAR2,feetrans IN NUMBER,bran IN VARCHAR2, lperr3 OUT VARCHAR2)
IS
rec_source	VARCHAR2(6);
amt_ind		CHAR(1)	;
BEGIN		--begin lp3
lperr3	:=	'OK';
dbms_output.put_line('11/10/2002---> 1 '||filename);

	IF feetrans IS NULL THEN
		rec_source := 'LOYL';
		amt_ind	    :=	 'C'	;
	ELSE
		rec_source := 'FEES';
		amt_ind	   := 'D';
	END IF;
	BEGIN	--begin lp3 1
		INSERT INTO CMS_TTUM_UPLOAD	(	CTU_INST_CODE		,
							CTU_FILE_NAME		,
							CTU_ROW_ID		,
							CTU_REC_SOURCE		,
							CTU_ACCT_NO		,
							CTU_CURR_CODE		,
							CTU_SOLID_CODE		,
							CTU_TRAN_TYPE		,
							CTU_TRANS_AMT		,
							CTU_PARTI_CULAR		,
							CTU_FEE_TRANS		,
							CTU_INS_USER		,
							CTU_LUPD_USER		)
					VALUES	(	instcode		,
							filename		,
							totrows			,
							rec_source		,
							RPAD(acctno,16,' ')	,
							'INR'			,
							RPAD(SUBSTR(acctno,1,4),8,' '),
							amt_ind			,
							LPAD(TO_CHAR(amount),15,' ')	,--01-08-02 amount converted to char to enable rpad
							RPAD(feetrans||'-'||particulars,83,' '),
							feetrans		,
							lupduser		,
							lupduser		);

		EXCEPTION		--excp of begin lp3 1
		WHEN OTHERS THEN
		lperr3 := 'Lp3 Excp 1--'||SQLERRM;
		END;			--end begin lp3 1

		IF lperr3 = 'OK' THEN
			UPDATE CMS_TTUM_CTRL
			SET		ctc_tot_rows	=	totrows,
					ctc_tot_amt	=	ctc_tot_amt+amount,
					ctc_file_type	=	filetype,
					ctc_lupd_user	=	lupduser
			WHERE	ctc_inst_code	=	instcode
			AND	ctc_file_name	=	filename;

			IF feetrans IS NOT NULL THEN --that means input params is from fee
				UPDATE	CMS_CHARGE_DTL
				SET	ccd_file_name		=	filename,
					ccd_lupd_user		=	lupduser
				WHERE	ccd_inst_code		=	instcode
				AND	ccd_fee_trans		=	feetrans;
			ELSIF feetrans IS NULL THEN	--that means input params is from loyl redeem
				--delete stmt commented on 31-08-02, instead update the rows with the filename
				/*DELETE FROM cms_redeem_loyl
				WHERE		crl_inst_code		=	instcode
				AND			crl_curr_bran		=	bran
				AND			crl_acct_no		=	acctno;*/
				--u can use the where current of clause
				UPDATE	CMS_REDEEM_LOYL
				SET	crl_file_name	=	filename,
					crl_lupd_user	=	lupduser
				WHERE	crl_curr_bran	=	bran
				AND	crl_acct_no	=	acctno
				AND	crl_file_name	=	'N'	;

			END IF;
		END IF;
EXCEPTION	--excp lp3
WHEN OTHERS THEN
lperr3	:= 'LP3 Excp -- '||SQLERRM;
END;		--end lp3

/*Main procedure body begins here*/
BEGIN		--main begin
errmsg := 'OK';
	/*Fee Part*/
	IF popforloyl  = 'F' THEN	 --pop if ... means that ttum population is to be done for fee
	file_type := 'D';	--filetype ='D' because in fees, we will be debiting the customers account
	--first find the no of rows for ttum parameter
	lp1_find_rows_param(ttum_rows,errmsg);
	IF errmsg != 'OK' THEN
		errmsg := 'From lp_find_rows_param -- '||errmsg;
	END IF;
	--now find whether any file is in use and find out the no. of rows used in that file
	IF errmsg = 'OK' THEN
	lp2_ttum_file_name(file_type,filename, totrows, errmsg);
	IF SUBSTR(filename,1,1) != 'N' THEN	--if condition tells us that if its a already used file then dont append N...use the filename as it is
	--its a bad way actually...it should be taken care of in lp2 but cant help...time constraint
	filename := 'N'||filename;  --added on 8/10/2002 N means normal file(fresh file)
	END IF;
		IF errmsg != 'OK' THEN
			errmsg := 'From lp_find_rows_param -- '||errmsg;
		END IF;
	END IF;

	--now if the new file is generated above then insert the rows into cms_ttum_ctrl table
	IF errmsg = 'OK' AND totrows = 0 THEN
	BEGIN		--begin 1
	IF unusedfile = 'N' THEN		--unusedfile  = 'Y' means there is already a row into ttum_ctrl for this file so no need to insert into ttum_ctrl
	INSERT INTO CMS_TTUM_CTRL(			CTC_INST_CODE		,
							CTC_FILE_NAME		,
							CTC_FILE_TYPE		,
							CTC_TOT_ROWS		,
							CTC_TOT_AMT		,
							CTC_FILE_INUSE		,
							CTC_FILE_GEN		,
							CTC_INS_USER		,
							CTC_LUPD_USER		)
					VALUES(		instcode		,
							filename		,
							file_type		,
							totrows			,
							0			,
							'Y'			,
							'N'			,
							lupduser		,
							lupduser		)	;
	END IF;
	EXCEPTION		--excp of begin1
	WHEN OTHERS THEN
	errmsg := '1 Excp 1 -- '||SQLERRM;
	END	 ;		--end begin 1
	END IF;

	IF errmsg = 'OK' THEN

	FOR x IN c1

	LOOP
	totrows := totrows+1;
	IF errmsg = 'OK' THEN	--ok if
		IF totrows <= ttum_rows THEN
			lp3_ins_upd_main_oprn(filename,file_type,totrows,x.ccd_acct_no,x.ccd_calc_amt,x.cft_feetype_desc,x.ccd_fee_trans,NULL,errmsg);
			IF errmsg != 'OK' THEN
				errmsg := 'From lp3_ins_upd_main_oprn -- '||errmsg;
			END IF;

		ELSIF totrows > ttum_rows THEN	--it means that the parameter limit for rows per ttum file has been reached

					UPDATE	CMS_TTUM_CTRL
					SET	ctc_file_inuse		=	'N',
						ctc_lupd_user		=	lupduser
					WHERE	ctc_inst_code		=	instcode
					AND	ctc_file_name		=	filename
					AND	ctc_file_type		=	file_type;

					--now find generate a new filename
					IF errmsg = 'OK' THEN
					lp2_ttum_file_name(file_type,filename, totrows, errmsg);
					IF SUBSTR(filename,1,1) != 'N' THEN	--if condition tells us that if its a already used file then dont append N...use the filename as it is
					--its a bad way actually...it should be taken care of in lp2 but cant help...time constraint
					filename := 'N'||filename;  --added on 8/10/2002 N means normal file(fresh file)
					END IF;
						IF errmsg != 'OK' THEN
							errmsg := '2 From lp_find_rows_param -- '||errmsg;
						END IF;
					END IF;
					--now the new file is generated , insert the rows into cms_ttum_ctrl table
					BEGIN		--begin 1
					INSERT INTO CMS_TTUM_CTRL(CTC_INST_CODE		,
											CTC_FILE_NAME		,
											CTC_FILE_TYPE		,
											CTC_TOT_ROWS		,
											CTC_TOT_AMT		,
											CTC_FILE_INUSE		,
											CTC_FILE_GEN		,
											CTC_INS_USER		,
											CTC_LUPD_USER		)
									VALUES(	instcode		,
											filename	,
											file_type	,
											totrows		,
											0			,
											'Y'			,
											'N'			,
											lupduser		,
											lupduser		)	;
	totrows := totrows+1;
	lp3_ins_upd_main_oprn(filename,file_type,totrows,x.ccd_acct_no,x.ccd_calc_amt,x.cft_feetype_desc,x.ccd_fee_trans,NULL,errmsg);
	IF errmsg != 'OK' THEN
		errmsg := 'From lp3_ins_upd_main_oprn -- '||errmsg;
	END IF;
					EXCEPTION		--excp of begin1
					WHEN OTHERS THEN
					errmsg := '2 Excp 1 -- '||SQLERRM;
					END	 ;		--end begin 1
		END IF;
	END IF;	--ok if
	EXIT WHEN c1%NOTFOUND;
	END LOOP;
	END IF;
END IF;
	/*End Fee Part*/



	/*Loyalty part	*/
	IF popforloyl  = 'L' THEN	 --pop if ... means that ttum population is to be done for loyalty points also(it will be on a particular date parameterised)
	--first find the no of rows for ttum parameter
	file_type := 'C';	--filetype ='C' because in loyalty we will be crediting the customers account
	lp1_find_rows_param(ttum_rows,errmsg);
	dbms_output.put_line('From loyl part 1. parameter rows = '||ttum_rows);
	IF errmsg != 'OK' THEN
		errmsg := 'From lp_find_rows_param for loyl-- '||errmsg;
	END IF;
	--now find whether any file is in use and find out the no. of rows used in that file
	IF errmsg = 'OK' THEN
	lp2_ttum_file_name(file_type,filename, totrows, errmsg);
	IF SUBSTR(filename,1,1) != 'N' THEN	--if condition tells us that if its a already used file then dont append N...use the filename as it is
	--its a bad way actually...it should be taken care of in lp2 but cant help...time constraint
	filename := 'N'||filename;  --added on 8/10/2002 N means normal file(fresh file)
	END IF;
	dbms_output.put_line('From loyl part 2. file name = '||filename|| '  rows = '||totrows);
		IF errmsg != 'OK' THEN
			errmsg := 'From lp_find_rows_param for loyl-- '||errmsg;
		END IF;
	END IF;

	--now if the new file is generated above then insert the rows into cms_ttum_ctrl table
	IF errmsg = 'OK' AND totrows = 0 THEN
	BEGIN		--begin 1
	IF unusedfile = 'N' THEN--unusedfile  = 'Y' means there is already a row into ttum_ctrl for this file so no need to insert into ttum_ctrl
	INSERT INTO CMS_TTUM_CTRL(CTC_INST_CODE		,
							CTC_FILE_NAME		,
							CTC_FILE_TYPE		,
							CTC_TOT_ROWS		,
							CTC_TOT_AMT		,
							CTC_FILE_INUSE		,
							CTC_FILE_GEN		,
							CTC_INS_USER		,
							CTC_LUPD_USER		)
					VALUES(	instcode		,
							filename	,
							file_type	,
							totrows		,
							0			,
							'Y'			,
							'N'			,
							lupduser		,
							lupduser		)	;
	END IF;
	EXCEPTION		--excp of begin1
	WHEN OTHERS THEN
	errmsg := '1 Excp 1 for loyl-- '||SQLERRM;
	END	 ;		--end begin 1
	END IF;

	IF errmsg = 'OK' THEN
	FOR y IN c2
	LOOP
	FOR z IN c3(y.cbm_bran_code)

	LOOP
	totrows := totrows+1;
	IF errmsg = 'OK' THEN	--ok if
		IF totrows <= ttum_rows THEN
			lp3_ins_upd_main_oprn(filename,file_type,totrows,z.crl_acct_no,z.crl_calc_amt,z.crl_parti_cular,NULL,y.cbm_bran_code,errmsg);
			IF errmsg != 'OK' THEN
				errmsg := 'From lp3_ins_upd_main_oprn for loyl -- '||errmsg;
			END IF;

		ELSIF totrows > ttum_rows THEN	--it means that the parameter limit for rows per ttum file has been reached

					UPDATE	CMS_TTUM_CTRL
					SET	ctc_file_inuse	=	'N',
						ctc_lupd_user	=	lupduser
					WHERE	ctc_inst_code	=	instcode
					AND	ctc_file_name	=	filename
					AND	ctc_file_type	=	file_type;

					--now find generate a new filename
					IF errmsg = 'OK' THEN
					lp2_ttum_file_name(file_type,filename, totrows, errmsg);
					IF SUBSTR(filename,1,1) != 'N' THEN	--if condition tells us that if its a already used file then dont append N...use the filename as it is
					--its a bad way actually...it should be taken care of in lp2 but cant help...time constraint
					filename := 'N'||filename;  --added on 8/10/2002 N means normal file(fresh file)
					END IF;
						IF errmsg != 'OK' THEN
							errmsg := '2 From lp_find_rows_param for loyl -- '||errmsg;
						END IF;
					END IF;

					--now the new file is generated , insert the rows into cms_ttum_ctrl table
					BEGIN		--begin 1
					INSERT INTO CMS_TTUM_CTRL(CTC_INST_CODE		,
											CTC_FILE_NAME		,
											CTC_FILE_TYPE		,
											CTC_TOT_ROWS		,
											CTC_TOT_AMT		,
											CTC_FILE_INUSE		,
											CTC_FILE_GEN		,
											CTC_INS_USER		,
											CTC_LUPD_USER		)
									VALUES(	instcode		,
											filename	,
											file_type	,
											totrows		,
											0			,
											'Y'			,
											'N'			,
											lupduser		,
											lupduser		)	;
	totrows := totrows+1;
	lp3_ins_upd_main_oprn(filename,file_type,totrows,z.crl_acct_no,z.crl_calc_amt,z.crl_parti_cular,NULL,y.cbm_bran_code,errmsg);
	IF errmsg != 'OK' THEN
		errmsg := 'From lp3_ins_upd_main_oprn for loyl -- '||errmsg;
	END IF;
					EXCEPTION		--excp of begin1
					WHEN OTHERS THEN
					errmsg := '2 Excp 1 for loyl -- '||SQLERRM;
					END	 ;		--end begin 1
		END IF;
	END IF;	--ok if
	EXIT WHEN c3%NOTFOUND;
	END LOOP;

	EXIT WHEN c2%NOTFOUND;
	END LOOP;

	END IF;
	END IF;	 --end pop if
	/*end loyalty part*/

EXCEPTION	--main excp
WHEN OTHERS THEN
errmsg := 'Main Excp --'||SQLERRM;
END;		--end main
/
SHOW ERRORS

