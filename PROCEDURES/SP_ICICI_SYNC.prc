CREATE OR REPLACE PROCEDURE VMSCMS.SP_ICICI_SYNC IS

	x_holder					VARCHAR2(1);
	v_prod_code				VARCHAR2(6);
	v_card_type				NUMBER(2);
	v_cust_catg				NUMBER(5);
	v_cust_code				NUMBER(10);
	v_bill_addr				NUMBER(10);
	v_cat_type_code		NUMBER(3);
	v_cas_stat_code		NUMBER(3);
	lupduser					NUMBER(1) := 1;
	v_acctid					NUMBER(10);
	v_lperr						VARCHAR2(1000);
	v_holdposn				NUMBER(2);
	v_cpa_acct_posn		NUMBER(3);
	v_cam_acct_id			NUMBER(10);
	ctr 							NUMBER(5);
	v_ccc_catg_code		NUMBER(5);
	v_hd_card_type		NUMBER(1);
	v_cpb_prod_code		VARCHAR2(6);
	v_catgcode				NUMBER(5);
	v_cap_acct_no			VARCHAR2(20);
	v_cap_acct_id			NUMBER(10);
	v_acct_posn				NUMBER;
	tbl_index					NUMBER;
	loop_ctr					NUMBER;

	v_loop_acct_no		VARCHAR2(20);
	v_loop_posn				NUMBER;
	v_loop_acctid			NUMBER(10);

	p_acct_id					NUMBER(10);
	v_match 					CHAR(1);

	TYPE rec_acct_data IS RECORD (
		acct_no					VARCHAR2(20),
		acct_posn				NUMBER,
		acct_id					NUMBER(10));

	TYPE tbl_acct_data IS TABLE OF rec_acct_data
		INDEX BY BINARY_INTEGER;

	v_tbl_acct_data		tbl_acct_data;
	v_tbl_refresh			tbl_acct_data;
	v_except					EXCEPTION;

	/*Cursor cur_base_data picks up data from temp table which is extracted by BASE-24*/

	CURSOR	cur_base_data	IS
	SELECT	cci_seg12_cardholder_title,
					cci_seg12_name_line1,	--custmast part
					cci_seg12_addr_line1,
					cci_seg12_addr_line2,
					cci_seg12_name_line2,
					cci_seg12_city,
					cci_seg12_state,
					cci_seg12_postal_code,
					cci_seg12_country_code,
					cci_seg12_open_text1,	--address part
					cci_fiid,
					cci_crd_typ,
					cci_pan_code,
					cci_mbr_numb,
					cci_seg12_issue_dat,
					cci_exp_dat,
					cci_crd_stat,
					cci_seg12_branch_num,	 --customer category comes in this field
					cci_seg31_num,
					cci_seg31_typ,
					cci_seg31_stat,	--primary account number for the card
					cci_seg31_num1,
					cci_seg31_typ1,
					cci_seg31_stat1,--2nd account attached to the card
					cci_seg31_num2,
					cci_seg31_typ2,
					cci_seg31_stat2,--3rd account attached to the card
					cci_seg31_num3,
					cci_seg31_typ3,
					cci_seg31_stat3,--4th account attached to the card
					cci_seg31_num4,
					cci_seg31_typ4,
					cci_seg31_stat4,--5th account attached to the card
					cci_seg31_num5,
					cci_seg31_typ5,
					cci_seg31_stat5,--6th account attached to the card
					cci_seg31_num6,
					cci_seg31_typ6,
					cci_seg31_stat6,--7th account attached to the card
					cci_seg31_num7,
					cci_seg31_typ7,
					cci_seg31_stat7,--8th account attached to the card
					cci_seg31_num8,
					cci_seg31_typ8,
					cci_seg31_stat8,--9th account attached to the card
					cci_seg31_num9,
					cci_seg31_typ9,
					cci_seg31_stat9--10th account attached to the card
	FROM		CMS_CAF_INFO_CARDBASE;

	CURSOR 	cur_pan_acct (p_pan_code VARCHAR2) IS
	SELECT	cpa_acct_id
	FROM 		CMS_PAN_ACCT
	WHERE		cpa_inst_code = 1
	AND			cpa_pan_code = p_pan_code;

BEGIN
	ctr := 0;

  FOR a IN cur_base_data
  LOOP

  v_acct_posn	 			:= 2;
  tbl_index					:= 0;
	v_tbl_acct_data		:= v_tbl_refresh;
	loop_ctr 					:= 0;

  ctr := ctr+1;
  IF ctr >= 10000 THEN
  	ctr := 0;
  	COMMIT;
  END IF;

  BEGIN
  	BEGIN
  		SELECT 	cap_prod_code,
  						cap_card_type,
  						cap_cust_catg,
  						cap_cust_code,
  						cap_bill_addr
  		INTO		v_prod_code,
  						v_card_type,
  						v_cust_catg,
  						v_cust_code,
  						v_bill_addr
  		FROM		CMS_APPL_PAN
  		WHERE		cap_pan_code = a.cci_pan_code;
		EXCEPTION
  		WHEN NO_DATA_FOUND THEN
				sp_auton(	a.cci_fiid,
									a.cci_pan_code,
									'NO DATA FOUND IN APPL_PAN'||SQLERRM);
				RAISE v_except;
  		WHEN TOO_MANY_ROWS THEN
				sp_auton(	a.cci_fiid,
									a.cci_pan_code,
									'TOO MANY ROWS IN APPL_PAN'||SQLERRM);
				RAISE v_except;
  		WHEN OTHERS THEN
				sp_auton(	a.cci_fiid,
									a.cci_pan_code,
									SQLERRM);
				RAISE v_except;
		END;
-------------------------------------------------------	acct1 part	starts
		IF a.cci_seg31_num IS NOT NULL THEN
  	BEGIN
  		SELECT 	cam_acct_id
  		INTO		v_cam_acct_id
  		FROM		CMS_ACCT_MAST
  		WHERE		cam_inst_code = 1
  		AND			cam_acct_no 	= a.cci_seg31_num;
--------------------------------------------------------checks acct1 mast entry
			BEGIN
				SELECT 	cpa_acct_posn
				INTO		v_cpa_acct_posn
				FROM 		CMS_PAN_ACCT
				WHERE 	cpa_inst_code = 1
				AND			cpa_pan_code  = a.cci_pan_code
				AND 		cpa_mbr_numb	= a.cci_mbr_numb
				AND 		cpa_acct_id		= v_cam_acct_id;

				IF NOT	(v_cpa_acct_posn = 1  AND a.cci_seg31_stat = '3') THEN

					UPDATE 	CMS_PAN_ACCT
					SET 		cpa_acct_posn = DECODE(a.cci_seg31_stat, '3', 1, v_acct_posn)----put variable....
					WHERE 	cpa_inst_code = 1
					AND			cpa_pan_code  = a.cci_pan_code
					AND 		cpa_mbr_numb	= a.cci_mbr_numb
					AND 		cpa_acct_id		= v_cam_acct_id;

					IF a.cci_seg31_stat = '3' THEN
						v_tbl_acct_data(tbl_index).acct_no 		:= a.cci_seg31_num;
						v_tbl_acct_data(tbl_index).acct_posn 	:= 1;
						v_tbl_acct_data(tbl_index).acct_id		:= v_cam_acct_id;
					ELSE
						v_tbl_acct_data(tbl_index).acct_no 		:= a.cci_seg31_num;
						v_tbl_acct_data(tbl_index).acct_posn 	:= v_acct_posn;
						v_tbl_acct_data(tbl_index).acct_id		:= v_cam_acct_id;
						v_acct_posn := v_acct_posn+1;
					END IF;
					tbl_index := tbl_index+1;
				END IF;

			EXCEPTION	-----acct_pan exception
				WHEN NO_DATA_FOUND THEN
					BEGIN
						SELECT 	'x'
						INTO		x_holder
						FROM 		CMS_CUST_ACCT
						WHERE 	cca_inst_code = 1
						AND 		cca_cust_code = v_cust_code
						AND 		cca_acct_id  	= v_cam_acct_id;
					EXCEPTION ----holder exception
						WHEN NO_DATA_FOUND THEN
							sp_create_holder( 1,
																v_cust_code,
																v_cam_acct_id,
																NULL,
																lupduser,
																v_holdposn,
																v_lperr)	;
							IF NOT v_lperr = 'OK' THEN
								sp_auton(	a.cci_fiid,
													a.cci_pan_code,
													'CREATE HOLDER'||a.cci_seg31_num||v_lperr);
								RAISE v_except;
							END IF;
					END; 	--holder exception ends

					INSERT INTO CMS_PAN_ACCT(	CPA_INST_CODE		,
											CPA_CUST_CODE		,
											CPA_ACCT_ID		,
											CPA_ACCT_POSN		,
											CPA_PAN_CODE		,
											CPA_MBR_NUMB		,
											CPA_INS_USER		,
											CPA_LUPD_USER		)
					VALUES(			1,
											v_cust_code,
											v_cam_acct_id,
											DECODE(a.cci_seg31_stat, '3', 1, v_acct_posn),--------changes made
											a.cci_pan_code		,
											a.cci_mbr_numb		,
											lupduser	,
											lupduser	);

						IF a.cci_seg31_stat = '3' THEN
							v_tbl_acct_data(tbl_index).acct_no 		:= a.cci_seg31_num;
							v_tbl_acct_data(tbl_index).acct_posn 	:= 1;
							v_tbl_acct_data(tbl_index).acct_id		:= v_cam_acct_id;
						ELSE
							v_tbl_acct_data(tbl_index).acct_no 		:= a.cci_seg31_num;
							v_tbl_acct_data(tbl_index).acct_posn 	:= v_acct_posn;
							v_tbl_acct_data(tbl_index).acct_id		:= v_cam_acct_id;
							v_acct_posn := v_acct_posn+1;
						END IF;
						tbl_index := tbl_index+1;

			END ;

  	EXCEPTION---acct mast exception
  		WHEN NO_DATA_FOUND THEN
				BEGIN
					SELECT 	cat_type_code
					INTO		v_cat_type_code
					FROM		CMS_ACCT_TYPE
					WHERE		cat_inst_code		=	1
					AND			cat_switch_type		=	a.cci_seg31_typ;
				EXCEPTION----cat type exception
					WHEN NO_DATA_FOUND THEN
					v_cat_type_code := 1;
				END;
				BEGIN
					SELECT	cas_stat_code
					INTO		v_cas_stat_code
					FROM		CMS_ACCT_STAT
					WHERE		cas_inst_code		= 1
					AND			cas_switch_statcode	= a.cci_seg31_stat;
				EXCEPTION	----stat code exception
					WHEN NO_DATA_FOUND THEN
					sp_auton(	a.cci_fiid,
									a.cci_pan_code,
									'NO DATA FOUND IN CMS_ACCT_STAT FOR'||a.cci_seg31_stat);
					RAISE v_except;
				END;
				sp_create_acct(	1,
												a.cci_seg31_num,
												1,
												a.cci_fiid,
												v_bill_addr,
												v_cat_type_code,
												v_cas_stat_code,
												lupduser,
												v_acctid,
												v_lperr)	;

				IF NOT v_lperr = 'OK' THEN
					sp_auton(	a.cci_fiid,
										a.cci_pan_code,
										'CREATE ACCT'||a.cci_seg31_num||v_lperr);
					RAISE v_except;
				ELSE
					sp_create_holder( 1,
														v_cust_code,
														v_acctid,
														NULL,
														lupduser,
														v_holdposn,
														v_lperr)	;
					IF NOT v_lperr = 'OK' THEN
						sp_auton(	a.cci_fiid,
											a.cci_pan_code,
											'CREATE HOLDER'||a.cci_seg31_num||v_lperr);
						RAISE v_except;
					ELSE
						INSERT INTO CMS_PAN_ACCT(	CPA_INST_CODE		,
												CPA_CUST_CODE		,
												CPA_ACCT_ID		,
												CPA_ACCT_POSN		,
												CPA_PAN_CODE		,
												CPA_MBR_NUMB		,
												CPA_INS_USER		,
												CPA_LUPD_USER		)
						VALUES(			1,
												v_cust_code,
												v_acctid,
												DECODE(v_cas_stat_code, 8, 1, v_acct_posn),---updated the acct position
												a.cci_pan_code		,
												a.cci_mbr_numb		,
												lupduser	,
												lupduser	);

						IF v_cas_stat_code = 8 THEN
							v_tbl_acct_data(tbl_index).acct_no 		:= a.cci_seg31_num;
							v_tbl_acct_data(tbl_index).acct_posn 	:= 1;
							v_tbl_acct_data(tbl_index).acct_id		:= v_acctid;
						ELSE
							v_tbl_acct_data(tbl_index).acct_no 		:= a.cci_seg31_num;
							v_tbl_acct_data(tbl_index).acct_posn 	:= v_acct_posn;
							v_tbl_acct_data(tbl_index).acct_id		:= v_acctid;
							v_acct_posn := v_acct_posn+1;
						END IF;
						tbl_index := tbl_index+1;

					END IF;
				END IF;
  		WHEN OTHERS THEN
				sp_auton(	a.cci_fiid,
									a.cci_pan_code,
									SQLERRM);
				RAISE v_except;
  	END;		------acct mast exception ends
		END IF;
---------------------------------------------------------------------------------  acct1 finished
-------------------------------------------------------	acct2 part	starts
		IF a.cci_seg31_num1 IS NOT NULL THEN
  	BEGIN
  		SELECT 	cam_acct_id
  		INTO		v_cam_acct_id
  		FROM		CMS_ACCT_MAST
  		WHERE		cam_inst_code = 1
  		AND			cam_acct_no 	= a.cci_seg31_num1;
--------------------------------------------------------checks acct mast entry
			BEGIN
				SELECT 	cpa_acct_posn
				INTO		v_cpa_acct_posn
				FROM 		CMS_PAN_ACCT
				WHERE 	cpa_inst_code = 1
				AND			cpa_pan_code  = a.cci_pan_code
				AND 		cpa_mbr_numb	= a.cci_mbr_numb
				AND 		cpa_acct_id		= v_cam_acct_id;

				IF NOT	(v_cpa_acct_posn = 1  AND a.cci_seg31_stat1 = '3') THEN

					UPDATE 	CMS_PAN_ACCT
					SET 		cpa_acct_posn = DECODE(a.cci_seg31_stat1, '3', 1, v_acct_posn)
					WHERE 	cpa_inst_code = 1
					AND			cpa_pan_code  = a.cci_pan_code
					AND 		cpa_mbr_numb	= a.cci_mbr_numb
					AND 		cpa_acct_id		= v_cam_acct_id;

					IF a.cci_seg31_stat1 = '3' THEN
						v_tbl_acct_data(tbl_index).acct_no 		:= a.cci_seg31_num1;
						v_tbl_acct_data(tbl_index).acct_posn 	:= 1;
						v_tbl_acct_data(tbl_index).acct_id		:= v_cam_acct_id;
					ELSE
						v_tbl_acct_data(tbl_index).acct_no 		:= a.cci_seg31_num1;
						v_tbl_acct_data(tbl_index).acct_posn 	:= v_acct_posn;
						v_tbl_acct_data(tbl_index).acct_id		:= v_cam_acct_id;
						v_acct_posn := v_acct_posn+1;
					END IF;
					tbl_index := tbl_index+1;

				END IF;

			EXCEPTION	-----acct_pan exception
				WHEN NO_DATA_FOUND THEN
					BEGIN
						SELECT 	'x'
						INTO		x_holder
						FROM 		CMS_CUST_ACCT
						WHERE 	cca_inst_code = 1
						AND 		cca_cust_code = v_cust_code
						AND 		cca_acct_id  	= v_cam_acct_id;
					EXCEPTION ----holder exception
						WHEN NO_DATA_FOUND THEN
							sp_create_holder( 1,
																v_cust_code,
																v_cam_acct_id,
																NULL,
																lupduser,
																v_holdposn,
																v_lperr)	;
							IF NOT v_lperr = 'OK' THEN
								sp_auton(	a.cci_fiid,
													a.cci_pan_code,
													'CREATE HOLDER'||a.cci_seg31_num1||v_lperr);
								RAISE v_except;
							END IF;
					END; 	--holder exception ends

					INSERT INTO CMS_PAN_ACCT(	CPA_INST_CODE		,
											CPA_CUST_CODE		,
											CPA_ACCT_ID		,
											CPA_ACCT_POSN		,
											CPA_PAN_CODE		,
											CPA_MBR_NUMB		,
											CPA_INS_USER		,
											CPA_LUPD_USER		)
					VALUES(			1,
											v_cust_code,
											v_cam_acct_id,
											DECODE(a.cci_seg31_stat1, '3', 1, v_acct_posn),
											a.cci_pan_code		,
											a.cci_mbr_numb		,
											lupduser	,
											lupduser	);

						IF a.cci_seg31_stat1 = '3' THEN
							v_tbl_acct_data(tbl_index).acct_no 		:= a.cci_seg31_num1;
							v_tbl_acct_data(tbl_index).acct_posn 	:= 1;
							v_tbl_acct_data(tbl_index).acct_id		:= v_cam_acct_id;
						ELSE
							v_tbl_acct_data(tbl_index).acct_no 		:= a.cci_seg31_num1;
							v_tbl_acct_data(tbl_index).acct_posn 	:= v_acct_posn;
							v_tbl_acct_data(tbl_index).acct_id		:= v_cam_acct_id;
							v_acct_posn := v_acct_posn+1;
						END IF;
						tbl_index := tbl_index+1;

			END ;

  	EXCEPTION---acct mast exception
  		WHEN NO_DATA_FOUND THEN
				BEGIN
					SELECT 	cat_type_code
					INTO		v_cat_type_code
					FROM		CMS_ACCT_TYPE
					WHERE		cat_inst_code		=	1
					AND			cat_switch_type		=	a.cci_seg31_typ1;
				EXCEPTION----cat type exception
					WHEN NO_DATA_FOUND THEN
					v_cat_type_code := 1;
				END;
				BEGIN
					SELECT	cas_stat_code
					INTO		v_cas_stat_code
					FROM		CMS_ACCT_STAT
					WHERE		cas_inst_code		= 1
					AND			cas_switch_statcode	= a.cci_seg31_stat1;
				EXCEPTION	----stat code exception
					WHEN NO_DATA_FOUND THEN
					sp_auton(	a.cci_fiid,
									a.cci_pan_code,
									'NO DATA FOUND IN CMS_ACCT_STAT FOR'||a.cci_seg31_stat1);
					RAISE v_except;
				END;
				sp_create_acct(	1,
												a.cci_seg31_num1,
												1,
												a.cci_fiid,
												v_bill_addr,
												v_cat_type_code,
												v_cas_stat_code,
												lupduser,
												v_acctid,
												v_lperr)	;

				IF NOT v_lperr = 'OK' THEN
					sp_auton(	a.cci_fiid,
										a.cci_pan_code,
										'CREATE ACCT'||a.cci_seg31_num1||v_lperr);
					RAISE v_except;
				ELSE
					sp_create_holder( 1,
														v_cust_code,
														v_acctid,
														NULL,
														lupduser,
														v_holdposn,
														v_lperr)	;
					IF NOT v_lperr = 'OK' THEN
						sp_auton(	a.cci_fiid,
											a.cci_pan_code,
											'CREATE HOLDER'||a.cci_seg31_num1||v_lperr);
						RAISE v_except;
					ELSE
						INSERT INTO CMS_PAN_ACCT(	CPA_INST_CODE		,
												CPA_CUST_CODE		,
												CPA_ACCT_ID		,
												CPA_ACCT_POSN		,
												CPA_PAN_CODE		,
												CPA_MBR_NUMB		,
												CPA_INS_USER		,
												CPA_LUPD_USER		)
						VALUES(			1,
												v_cust_code,
												v_acctid,
												DECODE(v_cas_stat_code, 8, 1, v_acct_posn),
												a.cci_pan_code		,
												a.cci_mbr_numb		,
												lupduser	,
												lupduser	);

						IF v_cas_stat_code = 8 THEN
							v_tbl_acct_data(tbl_index).acct_no 		:= a.cci_seg31_num1;
							v_tbl_acct_data(tbl_index).acct_posn 	:= 1;
							v_tbl_acct_data(tbl_index).acct_id		:= v_acctid;
						ELSE
							v_tbl_acct_data(tbl_index).acct_no 		:= a.cci_seg31_num1;
							v_tbl_acct_data(tbl_index).acct_posn 	:= v_acct_posn;
							v_tbl_acct_data(tbl_index).acct_id		:= v_acctid;
							v_acct_posn := v_acct_posn+1;
						END IF;
						tbl_index := tbl_index+1;

					END IF;
				END IF;
  		WHEN OTHERS THEN
				sp_auton(	a.cci_fiid,
									a.cci_pan_code,
									SQLERRM);
				RAISE v_except;
  	END;		------acct mast exception ends
		END IF;
---------------------------------------------------------------------------------  acct2 finished
-------------------------------------------------------	acct3 part	starts
		IF a.cci_seg31_num2 IS NOT NULL THEN
  	BEGIN
  		SELECT 	cam_acct_id
  		INTO		v_cam_acct_id
  		FROM		CMS_ACCT_MAST
  		WHERE		cam_inst_code = 1
  		AND			cam_acct_no 	= a.cci_seg31_num2;
--------------------------------------------------------checks acct mast entry
			BEGIN
				SELECT 	cpa_acct_posn
				INTO		v_cpa_acct_posn
				FROM 		CMS_PAN_ACCT
				WHERE 	cpa_inst_code = 1
				AND			cpa_pan_code  = a.cci_pan_code
				AND 		cpa_mbr_numb	= a.cci_mbr_numb
				AND 		cpa_acct_id		= v_cam_acct_id;

				IF NOT	(v_cpa_acct_posn = 1  AND a.cci_seg31_stat2 = '3') THEN

					UPDATE 	CMS_PAN_ACCT
					SET 		cpa_acct_posn = DECODE(a.cci_seg31_stat2, '3', 1, v_acct_posn)
					WHERE 	cpa_inst_code = 1
					AND			cpa_pan_code  = a.cci_pan_code
					AND 		cpa_mbr_numb	= a.cci_mbr_numb
					AND 		cpa_acct_id		= v_cam_acct_id;

					IF a.cci_seg31_stat2 = '3' THEN
						v_tbl_acct_data(tbl_index).acct_no 		:= a.cci_seg31_num2;
						v_tbl_acct_data(tbl_index).acct_posn 	:= 1;
						v_tbl_acct_data(tbl_index).acct_id		:= v_cam_acct_id;
					ELSE
						v_tbl_acct_data(tbl_index).acct_no 		:= a.cci_seg31_num2;
						v_tbl_acct_data(tbl_index).acct_posn 	:= v_acct_posn;
						v_tbl_acct_data(tbl_index).acct_id		:= v_cam_acct_id;
						v_acct_posn := v_acct_posn+1;
					END IF;
					tbl_index := tbl_index+1;

				END IF;

			EXCEPTION	-----acct_pan exception
				WHEN NO_DATA_FOUND THEN
					BEGIN
						SELECT 	'x'
						INTO		x_holder
						FROM 		CMS_CUST_ACCT
						WHERE 	cca_inst_code = 1
						AND 		cca_cust_code = v_cust_code
						AND 		cca_acct_id  	= v_cam_acct_id;
					EXCEPTION ----holder exception
						WHEN NO_DATA_FOUND THEN
							sp_create_holder( 1,
																v_cust_code,
																v_cam_acct_id,
																NULL,
																lupduser,
																v_holdposn,
																v_lperr)	;
							IF NOT v_lperr = 'OK' THEN
								sp_auton(	a.cci_fiid,
													a.cci_pan_code,
													'CREATE HOLDER'||a.cci_seg31_num2||v_lperr);
								RAISE v_except;
							END IF;
					END; 	--holder exception ends

					INSERT INTO CMS_PAN_ACCT(	CPA_INST_CODE		,
											CPA_CUST_CODE		,
											CPA_ACCT_ID		,
											CPA_ACCT_POSN		,
											CPA_PAN_CODE		,
											CPA_MBR_NUMB		,
											CPA_INS_USER		,
											CPA_LUPD_USER		)
					VALUES(			1,
											v_cust_code,
											v_cam_acct_id,
											DECODE(a.cci_seg31_stat2, '3', 1, v_acct_posn),
											a.cci_pan_code		,
											a.cci_mbr_numb		,
											lupduser	,
											lupduser	);

						IF a.cci_seg31_stat2 = '3' THEN
							v_tbl_acct_data(tbl_index).acct_no 		:= a.cci_seg31_num2;
							v_tbl_acct_data(tbl_index).acct_posn 	:= 1;
							v_tbl_acct_data(tbl_index).acct_id		:= v_cam_acct_id;
						ELSE
							v_tbl_acct_data(tbl_index).acct_no 		:= a.cci_seg31_num2;
							v_tbl_acct_data(tbl_index).acct_posn 	:= v_acct_posn;
							v_tbl_acct_data(tbl_index).acct_id		:= v_cam_acct_id;
							v_acct_posn := v_acct_posn+1;
						END IF;
						tbl_index := tbl_index+1;

			END ;

  	EXCEPTION---acct mast exception
  		WHEN NO_DATA_FOUND THEN
				BEGIN
					SELECT 	cat_type_code
					INTO		v_cat_type_code
					FROM		CMS_ACCT_TYPE
					WHERE		cat_inst_code		=	1
					AND			cat_switch_type		=	a.cci_seg31_typ2;
				EXCEPTION----cat type exception
					WHEN NO_DATA_FOUND THEN
					v_cat_type_code := 1;
				END;
				BEGIN
					SELECT	cas_stat_code
					INTO		v_cas_stat_code
					FROM		CMS_ACCT_STAT
					WHERE		cas_inst_code		= 1
					AND			cas_switch_statcode	= a.cci_seg31_stat2;
				EXCEPTION	----stat code exception
					WHEN NO_DATA_FOUND THEN
					sp_auton(	a.cci_fiid,
									a.cci_pan_code,
									'NO DATA FOUND IN CMS_ACCT_STAT FOR'||a.cci_seg31_stat2);
					RAISE v_except;
				END;
				sp_create_acct(	1,
												a.cci_seg31_num2,
												1,
												a.cci_fiid,
												v_bill_addr,
												v_cat_type_code,
												v_cas_stat_code,
												lupduser,
												v_acctid,
												v_lperr)	;

				IF NOT v_lperr = 'OK' THEN
					sp_auton(	a.cci_fiid,
										a.cci_pan_code,
										'CREATE ACCT'||a.cci_seg31_num2||v_lperr);
					RAISE v_except;
				ELSE
					sp_create_holder( 1,
														v_cust_code,
														v_acctid,
														NULL,
														lupduser,
														v_holdposn,
														v_lperr)	;
					IF NOT v_lperr = 'OK' THEN
						sp_auton(	a.cci_fiid,
											a.cci_pan_code,
											'CREATE HOLDER'||a.cci_seg31_num2||v_lperr);
						RAISE v_except;
					ELSE
						INSERT INTO CMS_PAN_ACCT(	CPA_INST_CODE		,
												CPA_CUST_CODE		,
												CPA_ACCT_ID		,
												CPA_ACCT_POSN		,
												CPA_PAN_CODE		,
												CPA_MBR_NUMB		,
												CPA_INS_USER		,
												CPA_LUPD_USER		)
						VALUES(			1,
												v_cust_code,
												v_acctid,
												DECODE(v_cas_stat_code, 8, 1, v_acct_posn),
												a.cci_pan_code		,
												a.cci_mbr_numb		,
												lupduser	,
												lupduser	);

						IF v_cas_stat_code = 8 THEN
							v_tbl_acct_data(tbl_index).acct_no 		:= a.cci_seg31_num2;
							v_tbl_acct_data(tbl_index).acct_posn 	:= 1;
							v_tbl_acct_data(tbl_index).acct_id		:= v_acctid;
						ELSE
							v_tbl_acct_data(tbl_index).acct_no 		:= a.cci_seg31_num2;
							v_tbl_acct_data(tbl_index).acct_posn 	:= v_acct_posn;
							v_tbl_acct_data(tbl_index).acct_id		:= v_acctid;
							v_acct_posn := v_acct_posn+1;
						END IF;
						tbl_index := tbl_index+1;

					END IF;
				END IF;
  		WHEN OTHERS THEN
				sp_auton(	a.cci_fiid,
									a.cci_pan_code,
									SQLERRM);
				RAISE v_except;
  	END;		------acct mast exception ends
		END IF;
---------------------------------------------------------------------------------  acct3 finished
-------------------------------------------------------	acct4 part	starts
		IF a.cci_seg31_num3 IS NOT NULL THEN
  	BEGIN
  		SELECT 	cam_acct_id
  		INTO		v_cam_acct_id
  		FROM		CMS_ACCT_MAST
  		WHERE		cam_inst_code = 1
  		AND			cam_acct_no 	= a.cci_seg31_num3;
--------------------------------------------------------checks acct mast entry
			BEGIN
				SELECT 	cpa_acct_posn
				INTO		v_cpa_acct_posn
				FROM 		CMS_PAN_ACCT
				WHERE 	cpa_inst_code = 1
				AND			cpa_pan_code  = a.cci_pan_code
				AND 		cpa_mbr_numb	= a.cci_mbr_numb
				AND 		cpa_acct_id		= v_cam_acct_id;

				IF NOT	(v_cpa_acct_posn = 1  AND a.cci_seg31_stat3 = '3') THEN

					UPDATE 	CMS_PAN_ACCT
					SET 		cpa_acct_posn = DECODE(a.cci_seg31_stat3, '3', 1, 2)
					WHERE 	cpa_inst_code = 1
					AND			cpa_pan_code  = a.cci_pan_code
					AND 		cpa_mbr_numb	= a.cci_mbr_numb
					AND 		cpa_acct_id		= v_cam_acct_id;

					IF a.cci_seg31_stat3 = '3' THEN
						v_tbl_acct_data(tbl_index).acct_no 		:= a.cci_seg31_num3;
						v_tbl_acct_data(tbl_index).acct_posn 	:= 1;
						v_tbl_acct_data(tbl_index).acct_id		:= v_cam_acct_id;
					ELSE
						v_tbl_acct_data(tbl_index).acct_no 		:= a.cci_seg31_num3;
						v_tbl_acct_data(tbl_index).acct_posn 	:= v_acct_posn;
						v_tbl_acct_data(tbl_index).acct_id		:= v_cam_acct_id;
						v_acct_posn := v_acct_posn+1;
					END IF;
					tbl_index := tbl_index+1;

				END IF;

			EXCEPTION	-----acct_pan exception
				WHEN NO_DATA_FOUND THEN
					BEGIN
						SELECT 	'x'
						INTO		x_holder
						FROM 		CMS_CUST_ACCT
						WHERE 	cca_inst_code = 1
						AND 		cca_cust_code = v_cust_code
						AND 		cca_acct_id  	= v_cam_acct_id;
					EXCEPTION ----holder exception
						WHEN NO_DATA_FOUND THEN
							sp_create_holder( 1,
																v_cust_code,
																v_cam_acct_id,
																NULL,
																lupduser,
																v_holdposn,
																v_lperr)	;
							IF NOT v_lperr = 'OK' THEN
								sp_auton(	a.cci_fiid,
													a.cci_pan_code,
													'CREATE HOLDER'||a.cci_seg31_num3||v_lperr);
								RAISE v_except;
							END IF;
					END; 	--holder exception ends

					INSERT INTO CMS_PAN_ACCT(	CPA_INST_CODE		,
											CPA_CUST_CODE		,
											CPA_ACCT_ID		,
											CPA_ACCT_POSN		,
											CPA_PAN_CODE		,
											CPA_MBR_NUMB		,
											CPA_INS_USER		,
											CPA_LUPD_USER		)
					VALUES(			1,
											v_cust_code,
											v_cam_acct_id,
											DECODE(a.cci_seg31_stat3, '3', 1, v_acct_posn),
											a.cci_pan_code		,
											a.cci_mbr_numb		,
											lupduser	,
											lupduser	);

						IF a.cci_seg31_stat3 = '3' THEN
							v_tbl_acct_data(tbl_index).acct_no 		:= a.cci_seg31_num3;
							v_tbl_acct_data(tbl_index).acct_posn 	:= 1;
							v_tbl_acct_data(tbl_index).acct_id		:= v_cam_acct_id;
						ELSE
							v_tbl_acct_data(tbl_index).acct_no 		:= a.cci_seg31_num3;
							v_tbl_acct_data(tbl_index).acct_posn 	:= v_acct_posn;
							v_tbl_acct_data(tbl_index).acct_id		:= v_cam_acct_id;
							v_acct_posn := v_acct_posn+1;
						END IF;
						tbl_index := tbl_index+1;

			END ;

  	EXCEPTION---acct mast exception
  		WHEN NO_DATA_FOUND THEN
				BEGIN
					SELECT 	cat_type_code
					INTO		v_cat_type_code
					FROM		CMS_ACCT_TYPE
					WHERE		cat_inst_code		=	1
					AND			cat_switch_type		=	a.cci_seg31_typ3;
				EXCEPTION----cat type exception
					WHEN NO_DATA_FOUND THEN
					v_cat_type_code := 1;
				END;
				BEGIN
					SELECT	cas_stat_code
					INTO		v_cas_stat_code
					FROM		CMS_ACCT_STAT
					WHERE		cas_inst_code		= 1
					AND			cas_switch_statcode	= a.cci_seg31_stat3;
				EXCEPTION	----stat code exception
					WHEN NO_DATA_FOUND THEN
					sp_auton(	a.cci_fiid,
									a.cci_pan_code,
									'NO DATA FOUND IN CMS_ACCT_STAT FOR'||a.cci_seg31_stat3);
					RAISE v_except;
				END;
				sp_create_acct(	1,
												a.cci_seg31_num3,
												1,
												a.cci_fiid,
												v_bill_addr,
												v_cat_type_code,
												v_cas_stat_code,
												lupduser,
												v_acctid,
												v_lperr)	;

				IF NOT v_lperr = 'OK' THEN
					sp_auton(	a.cci_fiid,
										a.cci_pan_code,
										'CREATE ACCT'||a.cci_seg31_num3||v_lperr);
					RAISE v_except;
				ELSE
					sp_create_holder( 1,
														v_cust_code,
														v_acctid,
														NULL,
														lupduser,
														v_holdposn,
														v_lperr)	;
					IF NOT v_lperr = 'OK' THEN
						sp_auton(	a.cci_fiid,
											a.cci_pan_code,
											'CREATE HOLDER'||a.cci_seg31_num3||v_lperr);
						RAISE v_except;
					ELSE
						INSERT INTO CMS_PAN_ACCT(	CPA_INST_CODE		,
												CPA_CUST_CODE		,
												CPA_ACCT_ID		,
												CPA_ACCT_POSN		,
												CPA_PAN_CODE		,
												CPA_MBR_NUMB		,
												CPA_INS_USER		,
												CPA_LUPD_USER		)
						VALUES(			1,
												v_cust_code,
												v_acctid,
												DECODE(v_cas_stat_code, 8, 1, v_acct_posn),
												a.cci_pan_code		,
												a.cci_mbr_numb		,
												lupduser	,
												lupduser	);

						IF v_cas_stat_code = 8 THEN
							v_tbl_acct_data(tbl_index).acct_no 		:= a.cci_seg31_num3;
							v_tbl_acct_data(tbl_index).acct_posn 	:= 1;
							v_tbl_acct_data(tbl_index).acct_id		:= v_acctid;
						ELSE
							v_tbl_acct_data(tbl_index).acct_no 		:= a.cci_seg31_num3;
							v_tbl_acct_data(tbl_index).acct_posn 	:= v_acct_posn;
							v_tbl_acct_data(tbl_index).acct_id		:= v_acctid;
							v_acct_posn := v_acct_posn+1;
						END IF;
						tbl_index := tbl_index+1;

					END IF;
				END IF;
  		WHEN OTHERS THEN
				sp_auton(	a.cci_fiid,
									a.cci_pan_code,
									SQLERRM);
				RAISE v_except;
  	END;		------acct mast exception ends
		END IF;
---------------------------------------------------------------------------------  acct4 finished
-------------------------------------------------------	acct5 part	starts
		IF a.cci_seg31_num4 IS NOT NULL THEN
  	BEGIN
  		SELECT 	cam_acct_id
  		INTO		v_cam_acct_id
  		FROM		CMS_ACCT_MAST
  		WHERE		cam_inst_code = 1
  		AND			cam_acct_no 	= a.cci_seg31_num4;
--------------------------------------------------------checks acct mast entry
			BEGIN
				SELECT 	cpa_acct_posn
				INTO		v_cpa_acct_posn
				FROM 		CMS_PAN_ACCT
				WHERE 	cpa_inst_code = 1
				AND			cpa_pan_code  = a.cci_pan_code
				AND 		cpa_mbr_numb	= a.cci_mbr_numb
				AND 		cpa_acct_id		= v_cam_acct_id;

				IF NOT	(v_cpa_acct_posn = 1  AND a.cci_seg31_stat4 = '3') THEN

					UPDATE 	CMS_PAN_ACCT
					SET 		cpa_acct_posn = DECODE(a.cci_seg31_stat4, '3', 1, v_acct_posn)
					WHERE 	cpa_inst_code = 1
					AND			cpa_pan_code  = a.cci_pan_code
					AND 		cpa_mbr_numb	= a.cci_mbr_numb
					AND 		cpa_acct_id		= v_cam_acct_id;

					IF a.cci_seg31_stat4 = '3' THEN
						v_tbl_acct_data(tbl_index).acct_no 		:= a.cci_seg31_num4;
						v_tbl_acct_data(tbl_index).acct_posn 	:= 1;
						v_tbl_acct_data(tbl_index).acct_id		:= v_cam_acct_id;
					ELSE
						v_tbl_acct_data(tbl_index).acct_no 		:= a.cci_seg31_num4;
						v_tbl_acct_data(tbl_index).acct_posn 	:= v_acct_posn;
						v_tbl_acct_data(tbl_index).acct_id		:= v_cam_acct_id;
						v_acct_posn := v_acct_posn+1;
					END IF;
					tbl_index := tbl_index+1;

				END IF;

			EXCEPTION	-----acct_pan exception
				WHEN NO_DATA_FOUND THEN
					BEGIN
						SELECT 	'x'
						INTO		x_holder
						FROM 		CMS_CUST_ACCT
						WHERE 	cca_inst_code = 1
						AND 		cca_cust_code = v_cust_code
						AND 		cca_acct_id  	= v_cam_acct_id;
					EXCEPTION ----holder exception
						WHEN NO_DATA_FOUND THEN
							sp_create_holder( 1,
																v_cust_code,
																v_cam_acct_id,
																NULL,
																lupduser,
																v_holdposn,
																v_lperr)	;
							IF NOT v_lperr = 'OK' THEN
								sp_auton(	a.cci_fiid,
													a.cci_pan_code,
													'CREATE HOLDER'||a.cci_seg31_num4||v_lperr);
								RAISE v_except;
							END IF;
					END; 	--holder exception ends

					INSERT INTO CMS_PAN_ACCT(	CPA_INST_CODE		,
											CPA_CUST_CODE		,
											CPA_ACCT_ID		,
											CPA_ACCT_POSN		,
											CPA_PAN_CODE		,
											CPA_MBR_NUMB		,
											CPA_INS_USER		,
											CPA_LUPD_USER		)
					VALUES(			1,
											v_cust_code,
											v_cam_acct_id,
											DECODE(a.cci_seg31_stat4, '3', 1, v_acct_posn),
											a.cci_pan_code		,
											a.cci_mbr_numb		,
											lupduser	,
											lupduser	);

						IF a.cci_seg31_stat4 = '3' THEN
							v_tbl_acct_data(tbl_index).acct_no 		:= a.cci_seg31_num4;
							v_tbl_acct_data(tbl_index).acct_posn 	:= 1;
							v_tbl_acct_data(tbl_index).acct_id		:= v_cam_acct_id;
						ELSE
							v_tbl_acct_data(tbl_index).acct_no 		:= a.cci_seg31_num4;
							v_tbl_acct_data(tbl_index).acct_posn 	:= v_acct_posn;
							v_tbl_acct_data(tbl_index).acct_id		:= v_cam_acct_id;
							v_acct_posn := v_acct_posn+1;
						END IF;
						tbl_index := tbl_index+1;

			END ;

  	EXCEPTION---acct mast exception
  		WHEN NO_DATA_FOUND THEN
				BEGIN
					SELECT 	cat_type_code
					INTO		v_cat_type_code
					FROM		CMS_ACCT_TYPE
					WHERE		cat_inst_code		=	1
					AND			cat_switch_type		=	a.cci_seg31_typ4;
				EXCEPTION----cat type exception
					WHEN NO_DATA_FOUND THEN
					v_cat_type_code := 1;
				END;
				BEGIN
					SELECT	cas_stat_code
					INTO		v_cas_stat_code
					FROM		CMS_ACCT_STAT
					WHERE		cas_inst_code		= 1
					AND			cas_switch_statcode	= a.cci_seg31_stat4;
				EXCEPTION	----stat code exception
					WHEN NO_DATA_FOUND THEN
					sp_auton(	a.cci_fiid,
									a.cci_pan_code,
									'NO DATA FOUND IN CMS_ACCT_STAT FOR'||a.cci_seg31_stat4);
					RAISE v_except;
				END;
				sp_create_acct(	1,
												a.cci_seg31_num4,
												1,
												a.cci_fiid,
												v_bill_addr,
												v_cat_type_code,
												v_cas_stat_code,
												lupduser,
												v_acctid,
												v_lperr)	;

				IF NOT v_lperr = 'OK' THEN
					sp_auton(	a.cci_fiid,
										a.cci_pan_code,
										'CREATE ACCT'||a.cci_seg31_num4||v_lperr);
					RAISE v_except;
				ELSE
					sp_create_holder( 1,
														v_cust_code,
														v_acctid,
														NULL,
														lupduser,
														v_holdposn,
														v_lperr)	;
					IF NOT v_lperr = 'OK' THEN
						sp_auton(	a.cci_fiid,
											a.cci_pan_code,
											'CREATE HOLDER'||a.cci_seg31_num4||v_lperr);
						RAISE v_except;
					ELSE
						INSERT INTO CMS_PAN_ACCT(	CPA_INST_CODE		,
												CPA_CUST_CODE		,
												CPA_ACCT_ID		,
												CPA_ACCT_POSN		,
												CPA_PAN_CODE		,
												CPA_MBR_NUMB		,
												CPA_INS_USER		,
												CPA_LUPD_USER		)
						VALUES(			1,
												v_cust_code,
												v_acctid,
												DECODE(v_cas_stat_code, 8, 1, v_acct_posn),
												a.cci_pan_code		,
												a.cci_mbr_numb		,
												lupduser	,
												lupduser	);

						IF v_cas_stat_code = 8 THEN
							v_tbl_acct_data(tbl_index).acct_no 		:= a.cci_seg31_num4;
							v_tbl_acct_data(tbl_index).acct_posn 	:= 1;
							v_tbl_acct_data(tbl_index).acct_id		:= v_acctid;
						ELSE
							v_tbl_acct_data(tbl_index).acct_no 		:= a.cci_seg31_num4;
							v_tbl_acct_data(tbl_index).acct_posn 	:= v_acct_posn;
							v_tbl_acct_data(tbl_index).acct_id		:= v_acctid;
							v_acct_posn := v_acct_posn+1;
						END IF;
						tbl_index := tbl_index+1;

					END IF;
				END IF;
  		WHEN OTHERS THEN
				sp_auton(	a.cci_fiid,
									a.cci_pan_code,
									SQLERRM);
				RAISE v_except;
  	END;		------acct mast exception ends
		END IF;
---------------------------------------------------------------------------------  acct5 finished
-------------------------------------------------------	acct6 part	starts
		IF a.cci_seg31_num5 IS NOT NULL THEN
  	BEGIN
  		SELECT 	cam_acct_id
  		INTO		v_cam_acct_id
  		FROM		CMS_ACCT_MAST
  		WHERE		cam_inst_code = 1
  		AND			cam_acct_no 	= a.cci_seg31_num5;
--------------------------------------------------------checks acct mast entry
			BEGIN
				SELECT 	cpa_acct_posn
				INTO		v_cpa_acct_posn
				FROM 		CMS_PAN_ACCT
				WHERE 	cpa_inst_code = 1
				AND			cpa_pan_code  = a.cci_pan_code
				AND 		cpa_mbr_numb	= a.cci_mbr_numb
				AND 		cpa_acct_id		= v_cam_acct_id;

				IF NOT	(v_cpa_acct_posn = 1  AND a.cci_seg31_stat5 = '3') THEN

					UPDATE 	CMS_PAN_ACCT
					SET 		cpa_acct_posn = DECODE(a.cci_seg31_stat5, '3', 1, v_acct_posn)
					WHERE 	cpa_inst_code = 1
					AND			cpa_pan_code  = a.cci_pan_code
					AND 		cpa_mbr_numb	= a.cci_mbr_numb
					AND 		cpa_acct_id		= v_cam_acct_id;

					IF a.cci_seg31_stat5 = '3' THEN
						v_tbl_acct_data(tbl_index).acct_no 		:= a.cci_seg31_num5;
						v_tbl_acct_data(tbl_index).acct_posn 	:= 1;
						v_tbl_acct_data(tbl_index).acct_id		:= v_cam_acct_id;
					ELSE
						v_tbl_acct_data(tbl_index).acct_no 		:= a.cci_seg31_num5;
						v_tbl_acct_data(tbl_index).acct_posn 	:= v_acct_posn;
						v_tbl_acct_data(tbl_index).acct_id		:= v_cam_acct_id;
						v_acct_posn := v_acct_posn+1;
					END IF;
					tbl_index := tbl_index+1;

				END IF;

			EXCEPTION	-----acct_pan exception
				WHEN NO_DATA_FOUND THEN
					BEGIN
						SELECT 	'x'
						INTO		x_holder
						FROM 		CMS_CUST_ACCT
						WHERE 	cca_inst_code = 1
						AND 		cca_cust_code = v_cust_code
						AND 		cca_acct_id  	= v_cam_acct_id;
					EXCEPTION ----holder exception
						WHEN NO_DATA_FOUND THEN
							sp_create_holder( 1,
																v_cust_code,
																v_cam_acct_id,
																NULL,
																lupduser,
																v_holdposn,
																v_lperr)	;
							IF NOT v_lperr = 'OK' THEN
								sp_auton(	a.cci_fiid,
													a.cci_pan_code,
													'CREATE HOLDER'||a.cci_seg31_num5||v_lperr);
								RAISE v_except;
							END IF;
					END; 	--holder exception ends

					INSERT INTO CMS_PAN_ACCT(	CPA_INST_CODE		,
											CPA_CUST_CODE		,
											CPA_ACCT_ID		,
											CPA_ACCT_POSN		,
											CPA_PAN_CODE		,
											CPA_MBR_NUMB		,
											CPA_INS_USER		,
											CPA_LUPD_USER		)
					VALUES(			1,
											v_cust_code,
											v_cam_acct_id,
											DECODE(a.cci_seg31_stat5, '3', 1, v_acct_posn),
											a.cci_pan_code		,
											a.cci_mbr_numb		,
											lupduser	,
											lupduser	);

						IF a.cci_seg31_stat5 = '3' THEN
							v_tbl_acct_data(tbl_index).acct_no 		:= a.cci_seg31_num5;
							v_tbl_acct_data(tbl_index).acct_posn 	:= 1;
							v_tbl_acct_data(tbl_index).acct_id		:= v_cam_acct_id;
						ELSE
							v_tbl_acct_data(tbl_index).acct_no 		:= a.cci_seg31_num5;
							v_tbl_acct_data(tbl_index).acct_posn 	:= v_acct_posn;
							v_tbl_acct_data(tbl_index).acct_id		:= v_cam_acct_id;
							v_acct_posn := v_acct_posn+1;
						END IF;
						tbl_index := tbl_index+1;

			END ;

  	EXCEPTION---acct mast exception
  		WHEN NO_DATA_FOUND THEN
				BEGIN
					SELECT 	cat_type_code
					INTO		v_cat_type_code
					FROM		CMS_ACCT_TYPE
					WHERE		cat_inst_code		=	1
					AND			cat_switch_type		=	a.cci_seg31_typ5;
				EXCEPTION----cat type exception
					WHEN NO_DATA_FOUND THEN
					v_cat_type_code := 1;
				END;
				BEGIN
					SELECT	cas_stat_code
					INTO		v_cas_stat_code
					FROM		CMS_ACCT_STAT
					WHERE		cas_inst_code		= 1
					AND			cas_switch_statcode	= a.cci_seg31_stat5;
				EXCEPTION	----stat code exception
					WHEN NO_DATA_FOUND THEN
					sp_auton(	a.cci_fiid,
									a.cci_pan_code,
									'NO DATA FOUND IN CMS_ACCT_STAT FOR'||a.cci_seg31_stat5);
					RAISE v_except;
				END;
				sp_create_acct(	1,
												a.cci_seg31_num5,
												1,
												a.cci_fiid,
												v_bill_addr,
												v_cat_type_code,
												v_cas_stat_code,
												lupduser,
												v_acctid,
												v_lperr)	;

				IF NOT v_lperr = 'OK' THEN
					sp_auton(	a.cci_fiid,
										a.cci_pan_code,
										'CREATE ACCT'||a.cci_seg31_num5||v_lperr);
					RAISE v_except;
				ELSE
					sp_create_holder( 1,
														v_cust_code,
														v_acctid,
														NULL,
														lupduser,
														v_holdposn,
														v_lperr)	;
					IF NOT v_lperr = 'OK' THEN
						sp_auton(	a.cci_fiid,
											a.cci_pan_code,
											'CREATE HOLDER'||a.cci_seg31_num5||v_lperr);
						RAISE v_except;
					ELSE
						INSERT INTO CMS_PAN_ACCT(	CPA_INST_CODE		,
												CPA_CUST_CODE		,
												CPA_ACCT_ID		,
												CPA_ACCT_POSN		,
												CPA_PAN_CODE		,
												CPA_MBR_NUMB		,
												CPA_INS_USER		,
												CPA_LUPD_USER		)
						VALUES(			1,
												v_cust_code,
												v_acctid,
												DECODE(v_cas_stat_code, 8, 1, v_acct_posn),
												a.cci_pan_code		,
												a.cci_mbr_numb		,
												lupduser	,
												lupduser	);

						IF v_cas_stat_code = 8 THEN
							v_tbl_acct_data(tbl_index).acct_no 		:= a.cci_seg31_num5;
							v_tbl_acct_data(tbl_index).acct_posn 	:= 1;
							v_tbl_acct_data(tbl_index).acct_id		:= v_acctid;
						ELSE
							v_tbl_acct_data(tbl_index).acct_no 		:= a.cci_seg31_num5;
							v_tbl_acct_data(tbl_index).acct_posn 	:= v_acct_posn;
							v_tbl_acct_data(tbl_index).acct_id		:= v_acctid;
							v_acct_posn := v_acct_posn+1;
						END IF;
						tbl_index := tbl_index+1;

					END IF;
				END IF;
  		WHEN OTHERS THEN
				sp_auton(	a.cci_fiid,
									a.cci_pan_code,
									SQLERRM);
				RAISE v_except;
  	END;		------acct mast exception ends
		END IF;
---------------------------------------------------------------------------------  acct6 finished
-------------------------------------------------------	acct7 part	starts
		IF a.cci_seg31_num6 IS NOT NULL THEN
  	BEGIN
  		SELECT 	cam_acct_id
  		INTO		v_cam_acct_id
  		FROM		CMS_ACCT_MAST
  		WHERE		cam_inst_code = 1
  		AND			cam_acct_no 	= a.cci_seg31_num6;
--------------------------------------------------------checks acct mast entry
			BEGIN
				SELECT 	cpa_acct_posn
				INTO		v_cpa_acct_posn
				FROM 		CMS_PAN_ACCT
				WHERE 	cpa_inst_code = 1
				AND			cpa_pan_code  = a.cci_pan_code
				AND 		cpa_mbr_numb	= a.cci_mbr_numb
				AND 		cpa_acct_id		= v_cam_acct_id;

				IF NOT	(v_cpa_acct_posn = 1  AND a.cci_seg31_stat6 = '3') THEN

					UPDATE 	CMS_PAN_ACCT
					SET 		cpa_acct_posn = DECODE(a.cci_seg31_stat6, '3', 1, v_acct_posn)
					WHERE 	cpa_inst_code = 1
					AND			cpa_pan_code  = a.cci_pan_code
					AND 		cpa_mbr_numb	= a.cci_mbr_numb
					AND 		cpa_acct_id		= v_cam_acct_id;

					IF a.cci_seg31_stat6 = '3' THEN
						v_tbl_acct_data(tbl_index).acct_no 		:= a.cci_seg31_num6;
						v_tbl_acct_data(tbl_index).acct_posn 	:= 1;
						v_tbl_acct_data(tbl_index).acct_id		:= v_cam_acct_id;
					ELSE
						v_tbl_acct_data(tbl_index).acct_no 		:= a.cci_seg31_num6;
						v_tbl_acct_data(tbl_index).acct_posn 	:= v_acct_posn;
						v_tbl_acct_data(tbl_index).acct_id		:= v_cam_acct_id;
						v_acct_posn := v_acct_posn+1;
					END IF;
					tbl_index := tbl_index+1;

				END IF;

			EXCEPTION	-----acct_pan exception
				WHEN NO_DATA_FOUND THEN
					BEGIN
						SELECT 	'x'
						INTO		x_holder
						FROM 		CMS_CUST_ACCT
						WHERE 	cca_inst_code = 1
						AND 		cca_cust_code = v_cust_code
						AND 		cca_acct_id  	= v_cam_acct_id;
					EXCEPTION ----holder exception
						WHEN NO_DATA_FOUND THEN
							sp_create_holder( 1,
																v_cust_code,
																v_cam_acct_id,
																NULL,
																lupduser,
																v_holdposn,
																v_lperr)	;
							IF NOT v_lperr = 'OK' THEN
								sp_auton(	a.cci_fiid,
													a.cci_pan_code,
													'CREATE HOLDER'||a.cci_seg31_num6||v_lperr);
								RAISE v_except;
							END IF;
					END; 	--holder exception ends

					INSERT INTO CMS_PAN_ACCT(	CPA_INST_CODE		,
											CPA_CUST_CODE		,
											CPA_ACCT_ID		,
											CPA_ACCT_POSN		,
											CPA_PAN_CODE		,
											CPA_MBR_NUMB		,
											CPA_INS_USER		,
											CPA_LUPD_USER		)
					VALUES(			1,
											v_cust_code,
											v_cam_acct_id,
											DECODE(a.cci_seg31_stat6, '3', 1, v_acct_posn),
											a.cci_pan_code		,
											a.cci_mbr_numb		,
											lupduser	,
											lupduser	);

						IF a.cci_seg31_stat6 = '3' THEN
							v_tbl_acct_data(tbl_index).acct_no 		:= a.cci_seg31_num6;
							v_tbl_acct_data(tbl_index).acct_posn 	:= 1;
							v_tbl_acct_data(tbl_index).acct_id		:= v_cam_acct_id;
						ELSE
							v_tbl_acct_data(tbl_index).acct_no 		:= a.cci_seg31_num6;
							v_tbl_acct_data(tbl_index).acct_posn 	:= v_acct_posn;
							v_tbl_acct_data(tbl_index).acct_id		:= v_cam_acct_id;
							v_acct_posn := v_acct_posn+1;
						END IF;
						tbl_index := tbl_index+1;

			END ;

  	EXCEPTION---acct mast exception
  		WHEN NO_DATA_FOUND THEN
				BEGIN
					SELECT 	cat_type_code
					INTO		v_cat_type_code
					FROM		CMS_ACCT_TYPE
					WHERE		cat_inst_code		=	1
					AND			cat_switch_type		=	a.cci_seg31_typ6;
				EXCEPTION----cat type exception
					WHEN NO_DATA_FOUND THEN
					v_cat_type_code := 1;
				END;
				BEGIN
					SELECT	cas_stat_code
					INTO		v_cas_stat_code
					FROM		CMS_ACCT_STAT
					WHERE		cas_inst_code		= 1
					AND			cas_switch_statcode	= a.cci_seg31_stat6;
				EXCEPTION	----stat code exception
					WHEN NO_DATA_FOUND THEN
					sp_auton(	a.cci_fiid,
									a.cci_pan_code,
									'NO DATA FOUND IN CMS_ACCT_STAT FOR'||a.cci_seg31_stat6);
					RAISE v_except;
				END;
				sp_create_acct(	1,
												a.cci_seg31_num6,
												1,
												a.cci_fiid,
												v_bill_addr,
												v_cat_type_code,
												v_cas_stat_code,
												lupduser,
												v_acctid,
												v_lperr)	;

				IF NOT v_lperr = 'OK' THEN
					sp_auton(	a.cci_fiid,
										a.cci_pan_code,
										'CREATE ACCT'||a.cci_seg31_num6||v_lperr);
					RAISE v_except;
				ELSE
					sp_create_holder( 1,
														v_cust_code,
														v_acctid,
														NULL,
														lupduser,
														v_holdposn,
														v_lperr)	;
					IF NOT v_lperr = 'OK' THEN
						sp_auton(	a.cci_fiid,
											a.cci_pan_code,
											'CREATE HOLDER'||a.cci_seg31_num6||v_lperr);
						RAISE v_except;
					ELSE
						INSERT INTO CMS_PAN_ACCT(	CPA_INST_CODE		,
												CPA_CUST_CODE		,
												CPA_ACCT_ID		,
												CPA_ACCT_POSN		,
												CPA_PAN_CODE		,
												CPA_MBR_NUMB		,
												CPA_INS_USER		,
												CPA_LUPD_USER		)
						VALUES(			1,
												v_cust_code,
												v_acctid,
												DECODE(v_cas_stat_code, 8, 1, v_acct_posn),
												a.cci_pan_code		,
												a.cci_mbr_numb		,
												lupduser	,
												lupduser	);

						IF v_cas_stat_code = 8 THEN
							v_tbl_acct_data(tbl_index).acct_no 		:= a.cci_seg31_num6;
							v_tbl_acct_data(tbl_index).acct_posn 	:= 1;
							v_tbl_acct_data(tbl_index).acct_id		:= v_acctid;
						ELSE
							v_tbl_acct_data(tbl_index).acct_no 		:= a.cci_seg31_num6;
							v_tbl_acct_data(tbl_index).acct_posn 	:= v_acct_posn;
							v_tbl_acct_data(tbl_index).acct_id		:= v_acctid;
							v_acct_posn := v_acct_posn+1;
						END IF;
						tbl_index := tbl_index+1;

					END IF;
				END IF;
  		WHEN OTHERS THEN
				sp_auton(	a.cci_fiid,
									a.cci_pan_code,
									SQLERRM);
				RAISE v_except;
  	END;		------acct mast exception ends
		END IF;
---------------------------------------------------------------------------------  acct7 finished
-------------------------------------------------------	acct8 part	starts
		IF a.cci_seg31_num7 IS NOT NULL THEN
  	BEGIN
  		SELECT 	cam_acct_id
  		INTO		v_cam_acct_id
  		FROM		CMS_ACCT_MAST
  		WHERE		cam_inst_code = 1
  		AND			cam_acct_no 	= a.cci_seg31_num7;
--------------------------------------------------------checks acct mast entry
			BEGIN
				SELECT 	cpa_acct_posn
				INTO		v_cpa_acct_posn
				FROM 		CMS_PAN_ACCT
				WHERE 	cpa_inst_code = 1
				AND			cpa_pan_code  = a.cci_pan_code
				AND 		cpa_mbr_numb	= a.cci_mbr_numb
				AND 		cpa_acct_id		= v_cam_acct_id;

				IF NOT	(v_cpa_acct_posn = 1  AND a.cci_seg31_stat7 = '3') THEN

					UPDATE 	CMS_PAN_ACCT
					SET 		cpa_acct_posn = DECODE(a.cci_seg31_stat7, '3', 1, v_acct_posn)
					WHERE 	cpa_inst_code = 1
					AND			cpa_pan_code  = a.cci_pan_code
					AND 		cpa_mbr_numb	= a.cci_mbr_numb
					AND 		cpa_acct_id		= v_cam_acct_id;

					IF a.cci_seg31_stat7 = '3' THEN
						v_tbl_acct_data(tbl_index).acct_no 		:= a.cci_seg31_num7;
						v_tbl_acct_data(tbl_index).acct_posn 	:= 1;
						v_tbl_acct_data(tbl_index).acct_id		:= v_cam_acct_id;
					ELSE
						v_tbl_acct_data(tbl_index).acct_no 		:= a.cci_seg31_num7;
						v_tbl_acct_data(tbl_index).acct_posn 	:= v_acct_posn;
						v_tbl_acct_data(tbl_index).acct_id		:= v_cam_acct_id;
						v_acct_posn := v_acct_posn+1;
					END IF;
					tbl_index := tbl_index+1;

				END IF;

			EXCEPTION	-----acct_pan exception
				WHEN NO_DATA_FOUND THEN
					BEGIN
						SELECT 	'x'
						INTO		x_holder
						FROM 		CMS_CUST_ACCT
						WHERE 	cca_inst_code = 1
						AND 		cca_cust_code = v_cust_code
						AND 		cca_acct_id  	= v_cam_acct_id;
					EXCEPTION ----holder exception
						WHEN NO_DATA_FOUND THEN
							sp_create_holder( 1,
																v_cust_code,
																v_cam_acct_id,
																NULL,
																lupduser,
																v_holdposn,
																v_lperr)	;
							IF NOT v_lperr = 'OK' THEN
								sp_auton(	a.cci_fiid,
													a.cci_pan_code,
													'CREATE HOLDER'||a.cci_seg31_num7||v_lperr);
								RAISE v_except;
							END IF;
					END; 	--holder exception ends

					INSERT INTO CMS_PAN_ACCT(	CPA_INST_CODE		,
											CPA_CUST_CODE		,
											CPA_ACCT_ID		,
											CPA_ACCT_POSN		,
											CPA_PAN_CODE		,
											CPA_MBR_NUMB		,
											CPA_INS_USER		,
											CPA_LUPD_USER		)
					VALUES(			1,
											v_cust_code,
											v_cam_acct_id,
											DECODE(a.cci_seg31_stat7, '3', 1, v_acct_posn),
											a.cci_pan_code		,
											a.cci_mbr_numb		,
											lupduser	,
											lupduser	);

						IF a.cci_seg31_stat7 = '3' THEN
							v_tbl_acct_data(tbl_index).acct_no 		:= a.cci_seg31_num7;
							v_tbl_acct_data(tbl_index).acct_posn 	:= 1;
							v_tbl_acct_data(tbl_index).acct_id		:= v_cam_acct_id;
						ELSE
							v_tbl_acct_data(tbl_index).acct_no 		:= a.cci_seg31_num7;
							v_tbl_acct_data(tbl_index).acct_posn 	:= v_acct_posn;
							v_tbl_acct_data(tbl_index).acct_id		:= v_cam_acct_id;
							v_acct_posn := v_acct_posn+1;
						END IF;
						tbl_index := tbl_index+1;

			END ;

  	EXCEPTION---acct mast exception
  		WHEN NO_DATA_FOUND THEN
				BEGIN
					SELECT 	cat_type_code
					INTO		v_cat_type_code
					FROM		CMS_ACCT_TYPE
					WHERE		cat_inst_code		=	1
					AND			cat_switch_type		=	a.cci_seg31_typ7;
				EXCEPTION----cat type exception
					WHEN NO_DATA_FOUND THEN
					v_cat_type_code := 1;
				END;
				BEGIN
					SELECT	cas_stat_code
					INTO		v_cas_stat_code
					FROM		CMS_ACCT_STAT
					WHERE		cas_inst_code		= 1
					AND			cas_switch_statcode	= a.cci_seg31_stat7;
				EXCEPTION	----stat code exception
					WHEN NO_DATA_FOUND THEN
					sp_auton(	a.cci_fiid,
									a.cci_pan_code,
									'NO DATA FOUND IN CMS_ACCT_STAT FOR'||a.cci_seg31_stat7);
					RAISE v_except;
				END;
				sp_create_acct(	1,
												a.cci_seg31_num7,
												1,
												a.cci_fiid,
												v_bill_addr,
												v_cat_type_code,
												v_cas_stat_code,
												lupduser,
												v_acctid,
												v_lperr)	;

				IF NOT v_lperr = 'OK' THEN
					sp_auton(	a.cci_fiid,
										a.cci_pan_code,
										'CREATE ACCT'||a.cci_seg31_num7||v_lperr);
					RAISE v_except;
				ELSE
					sp_create_holder( 1,
														v_cust_code,
														v_acctid,
														NULL,
														lupduser,
														v_holdposn,
														v_lperr)	;
					IF NOT v_lperr = 'OK' THEN
						sp_auton(	a.cci_fiid,
											a.cci_pan_code,
											'CREATE HOLDER'||a.cci_seg31_num7||v_lperr);
						RAISE v_except;
					ELSE
						INSERT INTO CMS_PAN_ACCT(	CPA_INST_CODE		,
												CPA_CUST_CODE		,
												CPA_ACCT_ID		,
												CPA_ACCT_POSN		,
												CPA_PAN_CODE		,
												CPA_MBR_NUMB		,
												CPA_INS_USER		,
												CPA_LUPD_USER		)
						VALUES(			1,
												v_cust_code,
												v_acctid,
												DECODE(v_cas_stat_code, 8, 1, v_acct_posn),
												a.cci_pan_code		,
												a.cci_mbr_numb		,
												lupduser	,
												lupduser	);

						IF v_cas_stat_code = 8 THEN
							v_tbl_acct_data(tbl_index).acct_no 		:= a.cci_seg31_num7;
							v_tbl_acct_data(tbl_index).acct_posn 	:= 1;
							v_tbl_acct_data(tbl_index).acct_id		:= v_acctid;
						ELSE
							v_tbl_acct_data(tbl_index).acct_no 		:= a.cci_seg31_num7;
							v_tbl_acct_data(tbl_index).acct_posn 	:= v_acct_posn;
							v_tbl_acct_data(tbl_index).acct_id		:= v_acctid;
							v_acct_posn := v_acct_posn+1;
						END IF;
						tbl_index := tbl_index+1;

					END IF;
				END IF;
  		WHEN OTHERS THEN
				sp_auton(	a.cci_fiid,
									a.cci_pan_code,
									SQLERRM);
				RAISE v_except;
  	END;		------acct mast exception ends
		END IF;
---------------------------------------------------------------------------------  acct8 finished
-------------------------------------------------------	acct9 part	starts
		IF a.cci_seg31_num8 IS NOT NULL THEN
  	BEGIN
  		SELECT 	cam_acct_id
  		INTO		v_cam_acct_id
  		FROM		CMS_ACCT_MAST
  		WHERE		cam_inst_code = 1
  		AND			cam_acct_no 	= a.cci_seg31_num8;
--------------------------------------------------------checks acct mast entry
			BEGIN
				SELECT 	cpa_acct_posn
				INTO		v_cpa_acct_posn
				FROM 		CMS_PAN_ACCT
				WHERE 	cpa_inst_code = 1
				AND			cpa_pan_code  = a.cci_pan_code
				AND 		cpa_mbr_numb	= a.cci_mbr_numb
				AND 		cpa_acct_id		= v_cam_acct_id;

				IF NOT	(v_cpa_acct_posn = 1  AND a.cci_seg31_stat8 = '3') THEN

					UPDATE 	CMS_PAN_ACCT
					SET 		cpa_acct_posn = DECODE(a.cci_seg31_stat8, '3', 1, v_acct_posn)
					WHERE 	cpa_inst_code = 1
					AND			cpa_pan_code  = a.cci_pan_code
					AND 		cpa_mbr_numb	= a.cci_mbr_numb
					AND 		cpa_acct_id		= v_cam_acct_id;

					IF a.cci_seg31_stat8 = '3' THEN
						v_tbl_acct_data(tbl_index).acct_no 		:= a.cci_seg31_num8;
						v_tbl_acct_data(tbl_index).acct_posn 	:= 1;
						v_tbl_acct_data(tbl_index).acct_id		:= v_cam_acct_id;
					ELSE
						v_tbl_acct_data(tbl_index).acct_no 		:= a.cci_seg31_num8;
						v_tbl_acct_data(tbl_index).acct_posn 	:= v_acct_posn;
						v_tbl_acct_data(tbl_index).acct_id		:= v_cam_acct_id;
						v_acct_posn := v_acct_posn+1;
					END IF;
					tbl_index := tbl_index+1;

				END IF;

			EXCEPTION	-----acct_pan exception
				WHEN NO_DATA_FOUND THEN
					BEGIN
						SELECT 	'x'
						INTO		x_holder
						FROM 		CMS_CUST_ACCT
						WHERE 	cca_inst_code = 1
						AND 		cca_cust_code = v_cust_code
						AND 		cca_acct_id  	= v_cam_acct_id;
					EXCEPTION ----holder exception
						WHEN NO_DATA_FOUND THEN
							sp_create_holder( 1,
																v_cust_code,
																v_cam_acct_id,
																NULL,
																lupduser,
																v_holdposn,
																v_lperr)	;
							IF NOT v_lperr = 'OK' THEN
								sp_auton(	a.cci_fiid,
													a.cci_pan_code,
													'CREATE HOLDER'||a.cci_seg31_num8||v_lperr);
								RAISE v_except;
							END IF;
					END; 	--holder exception ends

					INSERT INTO CMS_PAN_ACCT(	CPA_INST_CODE		,
											CPA_CUST_CODE		,
											CPA_ACCT_ID		,
											CPA_ACCT_POSN		,
											CPA_PAN_CODE		,
											CPA_MBR_NUMB		,
											CPA_INS_USER		,
											CPA_LUPD_USER		)
					VALUES(			1,
											v_cust_code,
											v_cam_acct_id,
											DECODE(a.cci_seg31_stat8, '3', 1, v_acct_posn),
											a.cci_pan_code		,
											a.cci_mbr_numb		,
											lupduser	,
											lupduser	);

						IF a.cci_seg31_stat8 = '3' THEN
							v_tbl_acct_data(tbl_index).acct_no 		:= a.cci_seg31_num8;
							v_tbl_acct_data(tbl_index).acct_posn 	:= 1;
							v_tbl_acct_data(tbl_index).acct_id		:= v_cam_acct_id;
						ELSE
							v_tbl_acct_data(tbl_index).acct_no 		:= a.cci_seg31_num8;
							v_tbl_acct_data(tbl_index).acct_posn 	:= v_acct_posn;
							v_acct_posn := v_acct_posn+1;
							v_tbl_acct_data(tbl_index).acct_id		:= v_cam_acct_id;
						END IF;
						tbl_index := tbl_index+1;

			END ;

  	EXCEPTION---acct mast exception
  		WHEN NO_DATA_FOUND THEN
				BEGIN
					SELECT 	cat_type_code
					INTO		v_cat_type_code
					FROM		CMS_ACCT_TYPE
					WHERE		cat_inst_code		=	1
					AND			cat_switch_type		=	a.cci_seg31_typ8;
				EXCEPTION----cat type exception
					WHEN NO_DATA_FOUND THEN
					v_cat_type_code := 1;
				END;
				BEGIN
					SELECT	cas_stat_code
					INTO		v_cas_stat_code
					FROM		CMS_ACCT_STAT
					WHERE		cas_inst_code		= 1
					AND			cas_switch_statcode	= a.cci_seg31_stat8;
				EXCEPTION	----stat code exception
					WHEN NO_DATA_FOUND THEN
					sp_auton(	a.cci_fiid,
									a.cci_pan_code,
									'NO DATA FOUND IN CMS_ACCT_STAT FOR'||a.cci_seg31_stat8);
					RAISE v_except;
				END;
				sp_create_acct(	1,
												a.cci_seg31_num8,
												1,
												a.cci_fiid,
												v_bill_addr,
												v_cat_type_code,
												v_cas_stat_code,
												lupduser,
												v_acctid,
												v_lperr)	;

				IF NOT v_lperr = 'OK' THEN
					sp_auton(	a.cci_fiid,
										a.cci_pan_code,
										'CREATE ACCT'||a.cci_seg31_num8||v_lperr);
					RAISE v_except;
				ELSE
					sp_create_holder( 1,
														v_cust_code,
														v_acctid,
														NULL,
														lupduser,
														v_holdposn,
														v_lperr)	;
					IF NOT v_lperr = 'OK' THEN
						sp_auton(	a.cci_fiid,
											a.cci_pan_code,
											'CREATE HOLDER'||a.cci_seg31_num8||v_lperr);
						RAISE v_except;
					ELSE
						INSERT INTO CMS_PAN_ACCT(	CPA_INST_CODE		,
												CPA_CUST_CODE		,
												CPA_ACCT_ID		,
												CPA_ACCT_POSN		,
												CPA_PAN_CODE		,
												CPA_MBR_NUMB		,
												CPA_INS_USER		,
												CPA_LUPD_USER		)
						VALUES(			1,
												v_cust_code,
												v_acctid,
												DECODE(v_cas_stat_code, 8, 1, v_acct_posn),
												a.cci_pan_code		,
												a.cci_mbr_numb		,
												lupduser	,
												lupduser	);

						IF v_cas_stat_code = 8 THEN
							v_tbl_acct_data(tbl_index).acct_no 		:= a.cci_seg31_num8;
							v_tbl_acct_data(tbl_index).acct_posn 	:= 1;
							v_tbl_acct_data(tbl_index).acct_id		:= v_acctid;
						ELSE
							v_tbl_acct_data(tbl_index).acct_no 		:= a.cci_seg31_num8;
							v_tbl_acct_data(tbl_index).acct_posn 	:= v_acct_posn;
							v_acct_posn := v_acct_posn+1;
							v_tbl_acct_data(tbl_index).acct_id		:= v_acctid;
						END IF;
						tbl_index := tbl_index+1;

					END IF;
				END IF;
  		WHEN OTHERS THEN
				sp_auton(	a.cci_fiid,
									a.cci_pan_code,
									SQLERRM);
				RAISE v_except;
  	END;		------acct mast exception ends
		END IF;
---------------------------------------------------------------------------------  acct9 finished
-------------------------------------------------------	acct10 part	starts
		IF a.cci_seg31_num9 IS NOT NULL THEN
  	BEGIN
  		SELECT 	cam_acct_id
  		INTO		v_cam_acct_id
  		FROM		CMS_ACCT_MAST
  		WHERE		cam_inst_code = 1
  		AND			cam_acct_no 	= a.cci_seg31_num9;
--------------------------------------------------------checks acct mast entry
			BEGIN
				SELECT 	cpa_acct_posn
				INTO		v_cpa_acct_posn
				FROM 		CMS_PAN_ACCT
				WHERE 	cpa_inst_code = 1
				AND			cpa_pan_code  = a.cci_pan_code
				AND 		cpa_mbr_numb	= a.cci_mbr_numb
				AND 		cpa_acct_id		= v_cam_acct_id;

				IF NOT	(v_cpa_acct_posn = 1  AND a.cci_seg31_stat9 = '3') THEN

					UPDATE 	CMS_PAN_ACCT
					SET 		cpa_acct_posn = DECODE(a.cci_seg31_stat9, '3', 1, v_acct_posn)
					WHERE 	cpa_inst_code = 1
					AND			cpa_pan_code  = a.cci_pan_code
					AND 		cpa_mbr_numb	= a.cci_mbr_numb
					AND 		cpa_acct_id		= v_cam_acct_id;

					IF a.cci_seg31_stat9 = '3' THEN
						v_tbl_acct_data(tbl_index).acct_no 		:= a.cci_seg31_num9;
						v_tbl_acct_data(tbl_index).acct_posn 	:= 1;
						v_tbl_acct_data(tbl_index).acct_id		:= v_cam_acct_id;
					ELSE
						v_tbl_acct_data(tbl_index).acct_no 		:= a.cci_seg31_num9;
						v_tbl_acct_data(tbl_index).acct_posn 	:= v_acct_posn;
						v_tbl_acct_data(tbl_index).acct_id		:= v_cam_acct_id;
						v_acct_posn := v_acct_posn + 1;
					END IF;

				END IF;

			EXCEPTION	-----acct_pan exception
				WHEN NO_DATA_FOUND THEN
					BEGIN
						SELECT 	'x'
						INTO		x_holder
						FROM 		CMS_CUST_ACCT
						WHERE 	cca_inst_code = 1
						AND 		cca_cust_code = v_cust_code
						AND 		cca_acct_id  	= v_cam_acct_id;
					EXCEPTION ----holder exception
						WHEN NO_DATA_FOUND THEN
							sp_create_holder( 1,
																v_cust_code,
																v_cam_acct_id,
																NULL,
																lupduser,
																v_holdposn,
																v_lperr)	;
							IF NOT v_lperr = 'OK' THEN
								sp_auton(	a.cci_fiid,
													a.cci_pan_code,
													'CREATE HOLDER'||a.cci_seg31_num9||v_lperr);
								RAISE v_except;
							END IF;
					END; 	--holder exception ends

					INSERT INTO CMS_PAN_ACCT(	CPA_INST_CODE		,
											CPA_CUST_CODE		,
											CPA_ACCT_ID		,
											CPA_ACCT_POSN		,
											CPA_PAN_CODE		,
											CPA_MBR_NUMB		,
											CPA_INS_USER		,
											CPA_LUPD_USER		)
					VALUES(			1,
											v_cust_code,
											v_cam_acct_id,
											DECODE(a.cci_seg31_stat9, '3', 1, v_acct_posn),
											a.cci_pan_code		,
											a.cci_mbr_numb		,
											lupduser	,
											lupduser	);

						IF a.cci_seg31_stat9 = '3' THEN
							v_tbl_acct_data(tbl_index).acct_no 		:= a.cci_seg31_num9;
							v_tbl_acct_data(tbl_index).acct_posn 	:= 1;
							v_tbl_acct_data(tbl_index).acct_id		:= v_cam_acct_id;
						ELSE
							v_tbl_acct_data(tbl_index).acct_no 		:= a.cci_seg31_num9;
							v_tbl_acct_data(tbl_index).acct_posn 	:= v_acct_posn;
							v_acct_posn := v_acct_posn+1;
							v_tbl_acct_data(tbl_index).acct_id		:= v_cam_acct_id;
						END IF;
						tbl_index := tbl_index+1;

			END ;

  	EXCEPTION---acct mast exception
  		WHEN NO_DATA_FOUND THEN
				BEGIN
					SELECT 	cat_type_code
					INTO		v_cat_type_code
					FROM		CMS_ACCT_TYPE
					WHERE		cat_inst_code		=	1
					AND			cat_switch_type		=	a.cci_seg31_typ9;
				EXCEPTION----cat type exception
					WHEN NO_DATA_FOUND THEN
					v_cat_type_code := 1;
				END;
				BEGIN
					SELECT	cas_stat_code
					INTO		v_cas_stat_code
					FROM		CMS_ACCT_STAT
					WHERE		cas_inst_code		= 1
					AND			cas_switch_statcode	= a.cci_seg31_stat9;
				EXCEPTION	----stat code exception
					WHEN NO_DATA_FOUND THEN
					sp_auton(	a.cci_fiid,
									a.cci_pan_code,
									'NO DATA FOUND IN CMS_ACCT_STAT FOR'||a.cci_seg31_stat9);
					RAISE v_except;
				END;
				sp_create_acct(	1,
												a.cci_seg31_num9,
												1,
												a.cci_fiid,
												v_bill_addr,
												v_cat_type_code,
												v_cas_stat_code,
												lupduser,
												v_acctid,
												v_lperr)	;

				IF NOT v_lperr = 'OK' THEN
					sp_auton(	a.cci_fiid,
										a.cci_pan_code,
										'CREATE ACCT'||a.cci_seg31_num9||v_lperr);
					RAISE v_except;
				ELSE
					sp_create_holder( 1,
														v_cust_code,
														v_acctid,
														NULL,
														lupduser,
														v_holdposn,
														v_lperr)	;
					IF NOT v_lperr = 'OK' THEN
						sp_auton(	a.cci_fiid,
											a.cci_pan_code,
											'CREATE HOLDER'||a.cci_seg31_num9||v_lperr);
						RAISE v_except;
					ELSE
						INSERT INTO CMS_PAN_ACCT(	CPA_INST_CODE		,
												CPA_CUST_CODE		,
												CPA_ACCT_ID		,
												CPA_ACCT_POSN		,
												CPA_PAN_CODE		,
												CPA_MBR_NUMB		,
												CPA_INS_USER		,
												CPA_LUPD_USER		)
						VALUES(			1,
												v_cust_code,
												v_acctid,
												DECODE(v_cas_stat_code, 8, 1, v_acct_posn),
												a.cci_pan_code		,
												a.cci_mbr_numb		,
												lupduser	,
												lupduser	);

						IF v_cas_stat_code = 8 THEN
							v_tbl_acct_data(tbl_index).acct_no 		:= a.cci_seg31_num9;
							v_tbl_acct_data(tbl_index).acct_posn 	:= 1;
							v_tbl_acct_data(tbl_index).acct_id		:= v_acctid;

						ELSE
							v_tbl_acct_data(tbl_index).acct_no 		:= a.cci_seg31_num9;
							v_tbl_acct_data(tbl_index).acct_posn 	:= v_acct_posn;
						v_tbl_acct_data(tbl_index).acct_id		:= v_acctid;

							v_acct_posn := v_acct_posn+1;
						END IF;
						tbl_index := tbl_index+1;

					END IF;
				END IF;
  		WHEN OTHERS THEN
				sp_auton(	a.cci_fiid,
									a.cci_pan_code,
									SQLERRM);
				RAISE v_except;
  	END;		------acct mast exception ends
		END IF;
---------------------------------------------------------------------------------  acct10 finished
/*checking extra accounts attached to PAN in DCMS*/

	IF NOT cur_pan_acct%ISOPEN THEN
		OPEN cur_pan_acct(a.cci_pan_code);
	END IF;
	LOOP
	FETCH cur_pan_acct INTO p_acct_id;
	EXIT WHEN cur_pan_acct%NOTFOUND	;
	v_match := 'N';
		FOR loop_ctr IN 0..10
		LOOP
		BEGIN
			v_loop_acctid		:= v_tbl_acct_data(loop_ctr).acct_id;
--			v_loop_acct_no	:= v_tbl_acct_data(loop_ctr).acct_no;
			IF v_loop_acctid = p_acct_id THEN
				v_match := 'Y';
				EXIT;
			END IF;
		EXCEPTION
			WHEN NO_DATA_FOUND THEN
				NULL;
			WHEN OTHERS THEN
				NULL;
		END;
	END LOOP;
	IF v_match = 'N' THEN
		UPDATE		CMS_PAN_ACCT
		SET 			cpa_del_flag = 'Y'
		WHERE 		cpa_inst_code = 1
		AND				cpa_pan_code  = a.cci_pan_code
		AND				cpa_mbr_numb 	= '000'
		AND				cpa_acct_id  	= p_acct_id;
	END IF;
	END LOOP;
	CLOSE cur_pan_acct;
---------------------------------------------------------------------------------
  BEGIN
  	SELECT 	ccc_catg_code
  	INTO		v_ccc_catg_code
  	FROM 		CMS_CUST_CATG
  	WHERE 	ccc_catg_sname = DECODE(a.cci_seg12_branch_num, '*', 'DEF', a.cci_seg12_branch_num);
  EXCEPTION
  	WHEN NO_DATA_FOUND THEN
  		sp_create_custcatg(	1,
  												a.cci_seg12_branch_num,
  												a.cci_seg12_branch_num,
  												lupduser,
  												v_ccc_catg_code,
  												v_lperr);
			IF NOT v_lperr = 'OK' THEN
				sp_auton(	a.cci_fiid,
									a.cci_pan_code,
									'CREATE CUST CATG'||a.cci_seg12_branch_num||v_lperr);
				RAISE v_except;
  		END IF;
  	WHEN OTHERS THEN
				sp_auton(	a.cci_fiid,
									a.cci_pan_code,
									'CREATE CUST CATG'||a.cci_seg12_branch_num||v_lperr);
				RAISE v_except;
  END;

  BEGIN
		SELECT 	cpb_prod_code
		INTO		v_cpb_prod_code
		FROM 		CMS_PROD_BIN
		WHERE		cpb_inst_bin = TO_NUMBER(SUBSTR(a.cci_pan_code, 1, 6));
  EXCEPTION
  	WHEN OTHERS THEN
				sp_auton(	a.cci_fiid,
									a.cci_pan_code,
									'SELECT PROD'||a.cci_seg12_branch_num||v_lperr);
				RAISE v_except;
	END;

	IF 			TO_NUMBER(SUBSTR(a.cci_pan_code, 1, 6))  = 466706 AND a.cci_seg12_branch_num = 'HNI' THEN
					v_hd_card_type := 2;
	ELSE
					v_hd_card_type := 1;
	END IF;

	IF NOT (TO_NUMBER(SUBSTR(a.cci_pan_code, 1, 6)) = 504642 AND v_card_type = 2) THEN
		IF NOT v_ccc_catg_code = v_cust_catg THEN

			BEGIN
				SELECT 	'x'
				INTO		x_holder
				FROM		CMS_PROD_CCC
				WHERE		cpc_inst_code = 1
				AND 		cpc_cust_catg = v_ccc_catg_code
				AND			cpc_prod_code	= v_cpb_prod_code
				AND			cpc_card_type = v_hd_card_type;
			EXCEPTION
				WHEN NO_DATA_FOUND THEN
					INSERT INTO CMS_PROD_CCC(CPC_INST_CODE	,
								CPC_CUST_CATG ,
								CPC_CARD_TYPE ,
								CPC_PROD_CODE,
								CPC_INS_USER  ,
								CPC_LUPD_USER)
					VALUES(	 1,
								 v_ccc_catg_code,
								 v_hd_card_type,
								 v_cpb_prod_code,
								 lupduser,
								 lupduser);
			END	;
		END IF;

		UPDATE	CMS_APPL_PAN
		SET			cap_active_date = TO_DATE(a.cci_seg12_issue_dat, 'YYMMDD'),
						cap_expry_date	= LAST_DAY(TO_DATE(a.cci_exp_dat, 'YYMM')),
						cap_sync_flag  	= 'Y',
						cap_acct_id			= v_cap_acct_id,
						cap_acct_no			=	v_cap_acct_no
		WHERE		cap_pan_code		= a.cci_pan_code
		AND			cap_mbr_numb		= a.cci_mbr_numb;

	END IF;

  EXCEPTION
		WHEN v_except THEN
			sp_auton(	a.cci_fiid,
								a.cci_pan_code,
								'MAIN EXCEPTION'||a.cci_pan_code);
  END;
  END LOOP;
	COMMIT;
  EXCEPTION
		WHEN OTHERS THEN
			sp_auton(	1,
								1,
								'MASTER EXCEPTION'||SQLERRM);
END;
/


