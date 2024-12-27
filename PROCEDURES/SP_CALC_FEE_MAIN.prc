CREATE OR REPLACE PROCEDURE VMSCMS.Sp_Calc_Fee_Main (
   prm_inst_code   IN       NUMBER,
   prm_lupduser    IN       NUMBER,
   prm_errmsg      OUT      VARCHAR2
)
IS
   v_calcdate           DATE;
   v_errmsg             VARCHAR2 (300)                           DEFAULT 'OK';
   v_datecnt            NUMBER;
   v_fee_code           CMS_CARD_EXCPFEE.cce_fee_code%TYPE;
   v_waivamt            NUMBER;
   v_cfm_fee_amt        CMS_FEE_MAST.cfm_fee_amt%TYPE;
   v_fee_type           CMS_FEE_MAST.cfm_feetype_code%TYPE;
   v_actualfeeamt       NUMBER;
   v_days               NUMBER;
   v_waiv_prcnt         CMS_PRODCATTYPE_WAIV.cpw_waiv_prcnt%TYPE;
   v_annual_days        NUMBER;
   v_joining_days       NUMBER;
   v_savepoint          NUMBER                                     DEFAULT 0;
   exp_reject_record    EXCEPTION;
   exp_reject_process   EXCEPTION;
   exp_succ_feecalc		EXCEPTION;
   exp_raise_feecalc	EXCEPTION;

   CURSOR cur_calc_fee (c_calcdate DATE)
   IS
      SELECT cap_prod_code, cap_card_type, cap_pan_code, cap_mbr_numb,
             cap_cust_code, cap_acct_id, cap_acct_no, cap_join_feecalc
        FROM CMS_APPL_PAN
       WHERE cap_inst_code = 1
         AND TRUNC(cap_next_bill_date) = TRUNC (c_calcdate)
         AND cap_prod_catg = 'D';
----------------------------------------Main Begin--------------------------------------
BEGIN                                                                --begin1.
   prm_errmsg := 'OK';
   v_errmsg := 'OK';

-----------------------------------------1-----------------------------------------
   BEGIN
      SELECT TO_NUMBER (cip_param_value)
        INTO v_days
        FROM CMS_INST_PARAM
       WHERE cip_inst_code = prm_inst_code AND cip_param_key = 'HIT ACCT';
   EXCEPTION
      WHEN NO_DATA_FOUND
      THEN
         v_days := 0;
      WHEN OTHERS
      THEN
         v_errmsg :=
               'Error While fatching record from inst param '
            || SUBSTR (SQLERRM, 50);
         RAISE exp_reject_process;
   END;

   BEGIN
      SELECT TO_NUMBER (cip_param_value)
        INTO v_joining_days
        FROM CMS_INST_PARAM
       WHERE cip_inst_code = prm_inst_code
         AND cip_param_key = 'JOINING_FEE_DATE';
   EXCEPTION
      WHEN NO_DATA_FOUND
      THEN
         v_days := 0;
      WHEN OTHERS
      THEN
         v_errmsg :=
               'Error While fatching record from inst param '
            || SUBSTR (SQLERRM, 50);
         RAISE exp_reject_process;
   END;

   BEGIN
      SELECT TO_NUMBER (cip_param_value)
        INTO v_annual_days
        FROM CMS_INST_PARAM
       WHERE cip_inst_code = prm_inst_code
         AND cip_param_key = 'ANNUAL_FEE_DATE';
   EXCEPTION
      WHEN NO_DATA_FOUND
      THEN
         v_days := 0;
      WHEN OTHERS
      THEN
         v_errmsg :=
               'Error While fatching record from inst param '
            || SUBSTR (SQLERRM, 50);
         RAISE exp_reject_process;
   END;

-----------------------------------------1-----------------------------------------
-----------------------------------------2-----------------------------------------
   BEGIN                                                             --begin2.
      SELECT NVL (MAX (TRUNC (cpc_last_runfordate)), '01-JAN-1995')
        INTO v_calcdate
        FROM CMS_PROC_CTRL
       WHERE cpc_proc_name = 'FEE CALC' AND cpc_succ_flag = 'Y';
   EXCEPTION
      WHEN NO_DATA_FOUND
      THEN                                              --excp of begin 1 THEN
         v_errmsg := 'No data found for last run date' || SQLERRM;
         RAISE exp_reject_process;
      WHEN OTHERS
      THEN
         v_errmsg :=
                 'error While fatching record from procedure ctrl' || SQLERRM;
         RAISE exp_reject_process;
   END;

-----------------------------------------2-----------------------------------------
-----------------------------------------3-----------------------------------------
   BEGIN                                                            --begin22.
      SELECT NVL (TRUNC (SYSDATE) - TRUNC (v_calcdate), 0)
        INTO v_datecnt
        FROM DUAL;
   EXCEPTION
      WHEN OTHERS
      THEN
         v_errmsg := 'error while fatching date count ' || SQLERRM;
         RAISE exp_reject_process;
   END;                                                             --begin22.

-----------------------------------------3-----------------------------------------
   FOR i IN 1 .. v_datecnt                                      -- For Loop i.
   LOOP
      v_calcdate := v_calcdate + 1  ;

-----------------------------------------4-----------------------------------------
      BEGIN                                                        --begin 3.
         FOR j IN cur_calc_fee (v_calcdate)                    -- For Loop J.
         LOOP
-----------------------------------------5-----------------------------------------
            BEGIN                                                       --AB.
			   v_savepoint := v_savepoint + 1;
               SAVEPOINT v_savepoint;
               

               IF j.cap_join_feecalc = 'N'
               THEN                                  -- condi for Joining fee
--********************************************************************************************************
-----------------------------------------6-----------------------------------------
                  BEGIN                                                   --A
                     SELECT   cce_fee_code, cce_fee_type
                         INTO v_fee_code, v_fee_type
                         FROM CMS_CARD_EXCPFEE
                        WHERE cce_inst_code = prm_inst_code
                          AND v_calcdate >= cce_valid_from
                          AND v_calcdate <= cce_valid_to
                          AND cce_fee_type = 4
                          AND cce_pan_code = j.cap_pan_code
                          AND cce_mbr_numb = j.cap_mbr_numb
                     ORDER BY cce_pan_code, cce_fee_code;

-----------------------------------------12-----------------------------------------
                     BEGIN                                           --begin 2
                        SELECT cce_waiv_prcnt
                          INTO v_waiv_prcnt
                          FROM CMS_CARD_EXCPWAIV
                         WHERE cce_inst_code = prm_inst_code
                           AND cce_pan_code = j.cap_pan_code
                           AND cce_mbr_numb = j.cap_mbr_numb
                           AND cce_fee_code = v_fee_code
                           AND v_calcdate >= cce_valid_from
                           AND v_calcdate <= cce_valid_to;
                     EXCEPTION
                        WHEN NO_DATA_FOUND
                        THEN
                           v_waiv_prcnt := 0;
                        WHEN OTHERS
                        THEN
                           v_errmsg :=
                              'Valid Join waiver is not attached as on calcdate';
                           RAISE exp_reject_record;
                     END;                                            --begin 2
-----------------------------------------12-----------------------------------------
                  EXCEPTION
                     WHEN exp_reject_record
                     THEN
                        RAISE;
                     WHEN TOO_MANY_ROWS
                     THEN
                        v_errmsg :=
                           'Valid Join fee is not attached more then one time on calcdate';
                        RAISE exp_reject_record;
                     WHEN NO_DATA_FOUND
                     THEN
--------------------------Call Product Fee calculation in side No datat found of card fee-----------------------
                        -----------------------------------------7-----------------------------------------
                        BEGIN                                           --AC.
-----------------------------------------8-----------------------------------------
                           BEGIN                                   --begin 5.
                              SELECT   cpf_fee_code, cpf_fee_type
                                  INTO v_fee_code, v_fee_type
                                  FROM CMS_PRODCATTYPE_FEES
                                 WHERE cpf_inst_code = prm_inst_code
                                   AND v_calcdate >= cpf_valid_from
                                   AND v_calcdate <= cpf_valid_to
                                   AND cpf_fee_type = 4
                                   AND cpf_prod_code = j.cap_prod_code
                                   AND cpf_card_type = j.cap_card_type
                              ORDER BY cpf_fee_code;
                           EXCEPTION
                              WHEN TOO_MANY_ROWS
                              THEN
                                 v_errmsg :=
                                    'Valid Join prodcattype fee is not attached more then one time on calcdate';
                                 RAISE exp_reject_record;
                              WHEN NO_DATA_FOUND
                              THEN
                                 v_errmsg :=
                                    'Valid Join prodcattype fee is not attached as on calcdate';
                                 RAISE exp_reject_record;
                              WHEN OTHERS
                              THEN
                                 v_errmsg :=
                                       'Valid Join fee is not attached as on calcdate'
                                    || SQLERRM;
                                 RAISE exp_reject_record;
                           END;                                     --begin 5.

-----------------------------------------8-----------------------------------------

                           -----------------------------------------10-----------------------------------------
                           BEGIN                                     --begin 2
                              SELECT cpw_waiv_prcnt
                                INTO v_waiv_prcnt
                                FROM CMS_PRODCATTYPE_WAIV
                               WHERE cpw_inst_code = prm_inst_code
                                 AND cpw_prod_code = j.cap_prod_code
                                 AND cpw_card_type = j.cap_card_type
                                 AND cpw_fee_code = v_fee_code
                                 AND v_calcdate >= cpw_valid_from
                                 AND v_calcdate <= cpw_valid_to;
                           EXCEPTION
                              WHEN NO_DATA_FOUND
                              THEN
                                 v_waiv_prcnt := 0;
                              WHEN OTHERS
                              THEN
                                 v_errmsg :=
                                       'Error while gatting prod cattype waiver'
                                    || SQLERRM;
                                 RAISE exp_reject_record;
                           END;
-----------------------------------------10-----------------------------------------
                        EXCEPTION
                           WHEN exp_reject_record
                           THEN
                              RAISE;
                           WHEN OTHERS
                           THEN
                              v_errmsg :=
                                    'Error while gatting prod cattype Fee'
                                 || SQLERRM;
                              RAISE exp_reject_record;
                        END;                                             --AC.
-----------------------------------------7-----------------------------------------
  --------------------------Call Product Fee calculation in side Npo datatfound of card fee-----------------------
                     WHEN OTHERS
                     THEN
                        RAISE exp_reject_record;
                  END;                                                     --A

-----------------------------------------6-----------------------------------------

                  -----------------------------------------11-----------------------------------------
           /*       BEGIN                                                   --1.
                     SELECT cfm_fee_amt
                       INTO v_cfm_fee_amt
                       FROM CMS_FEE_MAST
                      WHERE cfm_inst_code = prm_inst_code
                        AND cfm_fee_code = v_fee_code;
                  EXCEPTION
                     WHEN NO_DATA_FOUND
                     THEN
                        v_errmsg :=
                            'No Fee amount attache on fee code' || v_fee_code;
                        RAISE exp_reject_record;
                     WHEN OTHERS
                     THEN
                        v_errmsg :=
                              'Error while fetchng Fee amount attach on fee code'
                           || v_fee_code
                           || SQLERRM;
                        RAISE exp_reject_record;
                  END;                                                    --1.

-----------------------------------------11-----------------------------------------
                  BEGIN
                     IF v_cfm_fee_amt IS NOT NULL
                     THEN
                        v_waivamt := (v_waiv_prcnt / 100) * v_cfm_fee_amt;
                        v_actualfeeamt := v_cfm_fee_amt - v_waivamt;
                     END IF;
                  EXCEPTION
                     WHEN OTHERS
                     THEN
                        v_errmsg :=
                           'Error while calculate fees and waivers'
                           || SQLERRM;
                        RAISE exp_reject_record;
                  END;

------------------------------------------14-----------------------------------------
                  BEGIN
                     INSERT INTO CMS_CHARGE_DTL
                                 (ccd_inst_code, ccd_pan_code,
                                  ccd_mbr_numb, ccd_cust_code,
                                  ccd_acct_id, ccd_acct_no, ccd_fee_freq,
                                  ccd_feetype_code, ccd_fee_code,
                                  ccd_calc_amt, ccd_expcalc_date,
                                  ccd_calc_date, ccd_file_name,
                                  ccd_file_date, ccd_ins_user,
                                  ccd_lupd_user
                                 )
                          VALUES (prm_inst_code, j.cap_pan_code,
                                  j.cap_mbr_numb, j.cap_cust_code,
                                  j.cap_acct_id, j.cap_acct_no, 'O',
                                  v_fee_type, v_fee_code,
                                  v_actualfeeamt, v_calcdate,
                                  SYSDATE, 'N',
                                  SYSDATE + v_days, prm_lupduser,
                                  prm_lupduser
                                 );

                     IF SQL%ROWCOUNT = 0
                     THEN
                        RAISE exp_reject_record;
                     END IF;
                  EXCEPTION
                     WHEN exp_reject_record
                     THEN
                        v_errmsg :=
                               'Error while insertig record in charge detail';
                        RAISE;
                     WHEN OTHERS
                     THEN
                        v_errmsg :=
                              'Error while insertig record in charge detail'
                           || SQLERRM;
                        RAISE exp_reject_record;
                  END;

------------------------------------------14-----------------------------------------
------------------------------------------15-----------------------------------------
                  BEGIN
                     UPDATE CMS_APPL_PAN
                        SET cap_join_feecalc = 'Y',
                            cap_next_bill_date =
                               ADD_MONTHS (cap_next_bill_date, v_joining_days)
                      WHERE cap_pan_code = j.cap_pan_code
                        AND cap_inst_code = prm_inst_code;

                     IF SQL%ROWCOUNT = 0
                     THEN
                        RAISE exp_reject_record;
                     END IF;
                  EXCEPTION
                     WHEN exp_reject_record
                     THEN
                        v_errmsg := 'Error while updating record in appl pan';
                        RAISE;
                     WHEN OTHERS
                     THEN
                        v_errmsg :=
                              'Error while updating record in appl pan'
                           || SQLERRM;
                        RAISE exp_reject_record;
                  END;

------------------------------------------15-----------------------------------------
------------------------------------------25-----------------------------------------
                  BEGIN
                     INSERT INTO CMS_FEE_PROCESSLOG
                                 (cfp_inst_code, cfp_pan_code,
                                  cfp_prod_code, cfp_card_type,
                                  cfp_process_flag, cfp_process_msg,
                                  cfp_fee_type
                                 )
                          VALUES (prm_inst_code, j.cap_pan_code,
                                  j.cap_prod_code, j.cap_card_type,
                                  'S', 'Successful',
                                  v_fee_type
                                 );

                     IF SQL%ROWCOUNT = 0
                     THEN
                        RAISE exp_reject_record;
                     END IF;
                  EXCEPTION
                     WHEN exp_reject_record
                     THEN
                        v_errmsg :=
                           'error While Insertimg joining fee record in Error Log';
                        RAISE;
                     WHEN OTHERS
                     THEN
                        v_errmsg :=
                              'error While Insertimg joining fee record in Error Log'
                           || SQLERRM;
                        RAISE exp_reject_record;
                  END;*/
------------------------------------------25-----------------------------------------

               --********************************************************************************************************
               ELSE                                    -- Annual Fee Condition
-----------------------------------------16-----------------------------------------
                  BEGIN                                                   --A
                     SELECT   cce_fee_code, cce_fee_type
                         INTO v_fee_code, v_fee_type
                         FROM CMS_CARD_EXCPFEE
                        WHERE cce_inst_code = prm_inst_code
                          AND v_calcdate >= cce_valid_from
                          AND v_calcdate <= cce_valid_to
                          AND cce_fee_type = 10
                          AND cce_pan_code = j.cap_pan_code
                          AND cce_mbr_numb = j.cap_mbr_numb
                     ORDER BY cce_pan_code, cce_fee_code;

------------------------------------------17-----------------------------------------
                     BEGIN
                        SELECT cce_waiv_prcnt
                          INTO v_waiv_prcnt
                          FROM CMS_CARD_EXCPWAIV
                         WHERE cce_inst_code = prm_inst_code
                           AND cce_pan_code = j.cap_pan_code
                           AND cce_mbr_numb = j.cap_mbr_numb
                           AND cce_fee_code = v_fee_code
                           AND v_calcdate >= cce_valid_from
                           AND v_calcdate <= cce_valid_to;
                     EXCEPTION
                        WHEN NO_DATA_FOUND
                        THEN
                           v_waiv_prcnt := 0;
                        WHEN OTHERS
                        THEN
                           v_errmsg :=
                                 'Error while Fetching records from a waiver'
                              || SQLERRM;
                           RAISE exp_reject_record;
                     END;                                            --begin 2
------------------------------------------17-----------------------------------------
                  EXCEPTION
                     WHEN exp_reject_record
                     THEN
                        RAISE;
                     WHEN TOO_MANY_ROWS
                     THEN
                        v_errmsg :=
                           'Valid Annual prodcattype fee is not attached more then one time on calcdate';
                        RAISE exp_reject_record;
                     WHEN NO_DATA_FOUND
                     THEN
--------------------------Call PRoduct Fee calculation in side No datatfound of card fee-----------------------

                        -----------------------------------------18-----------------------------------------
                        BEGIN                                           --AC.
-----------------------------------------19-----------------------------------------
                           BEGIN                                   --begin 5.
                              SELECT   cpf_fee_code, cpf_fee_type
                                  INTO v_fee_code, v_fee_type
                                  FROM CMS_PRODCATTYPE_FEES
                                 WHERE cpf_inst_code = prm_inst_code
                                   AND v_calcdate >= cpf_valid_from
                                   AND v_calcdate <= cpf_valid_to
                                   AND cpf_fee_type = 10
                                   AND cpf_prod_code = j.cap_prod_code
                                   AND cpf_card_type = j.cap_card_type
                              ORDER BY cpf_fee_code;
                           EXCEPTION
                              WHEN TOO_MANY_ROWS
                              THEN
                                 v_errmsg :=
                                    'Valid Annual prodcattype fee is not attached more then one time on calcdate';
                                 RAISE exp_reject_record;
                              WHEN NO_DATA_FOUND
                              THEN
                                 v_errmsg :=
                                    'Valid Annual prodcattype fee is not attached on calcdate';
                                 RAISE exp_reject_record;
                              WHEN OTHERS
                              THEN
                                 v_errmsg :=
                                    'Valid Annual prodcattype fee is not attached on calcdate';
                                 RAISE exp_reject_record;
                           END;                                     --begin 5.

-----------------------------------------19-----------------------------------------
                          -----------------------------------------20-----------------------------------------
                           BEGIN                                     --begin 2
                              SELECT cpw_waiv_prcnt
                                INTO v_waiv_prcnt
                                FROM CMS_PRODCATTYPE_WAIV
                               WHERE cpw_inst_code = prm_inst_code
                                 AND cpw_prod_code = j.cap_prod_code
                                 AND cpw_card_type = j.cap_card_type
                                 AND cpw_fee_code = v_fee_code
                                 AND v_calcdate >= cpw_valid_from
                                 AND v_calcdate <= cpw_valid_to;
                           EXCEPTION
                              WHEN NO_DATA_FOUND
                              THEN
                                 v_waiv_prcnt := 0;
                              WHEN OTHERS
                              THEN
                                 v_errmsg :=
                                       'Error While Fetching record from prod waiver'
                                    || SQLERRM;
                                 RAISE exp_reject_record;
                           END;
-----------------------------------------20-----------------------------------------
                        EXCEPTION
                           WHEN exp_reject_record
                           THEN
                              RAISE;
                           WHEN OTHERS
                           THEN
                              v_errmsg :=
                                    'Error While Fetching record from prod cattype'
                                 || SQLERRM;
                              RAISE exp_reject_record;
                        END;                                             --AC.
-----------------------------------------18-----------------------------------------
  --------------------------Call Product Fee calculation in side Npo datatfound of card fee-----------------------
                     WHEN OTHERS
                     THEN
                        RAISE exp_reject_record;
                  END; 
				  
				  
				                                                    --A

-----------------------------------------16-----------------------------------------

                  -----------------------------------------21-----------------------------------------
               /*   BEGIN                                                   --1.
                     SELECT cfm_fee_amt
                       INTO v_cfm_fee_amt
                       FROM CMS_FEE_MAST
                      WHERE cfm_inst_code = prm_inst_code
                        AND cfm_fee_code = v_fee_code;
                  EXCEPTION
                     WHEN NO_DATA_FOUND
                     THEN
                        v_errmsg :=
                                'No Fee is defined on fee code' || v_fee_code;
                        RAISE exp_reject_record;
                     WHEN OTHERS
                     THEN
                        v_errmsg :=
                              'No Fee is defined on fee code'
                           || v_fee_code
                           || SQLERRM;
                        RAISE exp_reject_record;
                  END;                                                    --1.

-----------------------------------------21-----------------------------------------
                  BEGIN
                     IF v_cfm_fee_amt IS NOT NULL
                     THEN
                        v_waivamt := (v_waiv_prcnt / 100) * v_cfm_fee_amt;
                        v_actualfeeamt := v_cfm_fee_amt - v_waivamt;
                     END IF;
                  EXCEPTION
                     WHEN OTHERS
                     THEN
                        v_errmsg :=
                              'Error while calculate Annual fees and waivers'
                           || SQLERRM;
                        RAISE exp_reject_record;
                  END;

------------------------------------------22-----------------------------------------
                  BEGIN
                     INSERT INTO CMS_CHARGE_DTL
                                 (ccd_inst_code, ccd_pan_code,
                                  ccd_mbr_numb, ccd_cust_code,
                                  ccd_acct_id, ccd_acct_no, ccd_fee_freq,
                                  ccd_feetype_code, ccd_fee_code,
                                  ccd_calc_amt, ccd_expcalc_date,
                                  ccd_calc_date, ccd_file_name,
                                  ccd_file_date, ccd_ins_user,
                                  ccd_lupd_user
                                 )
                          VALUES (prm_inst_code, j.cap_pan_code,
                                  j.cap_mbr_numb, j.cap_cust_code,
                                  j.cap_acct_id, j.cap_acct_no, 'O',
                                  v_fee_type, v_fee_code,
                                  v_actualfeeamt, v_calcdate,
                                  SYSDATE, 'N',
                                  SYSDATE + v_days, prm_lupduser,
                                  prm_lupduser
                                 );

                     IF SQL%ROWCOUNT = 0
                     THEN
                        RAISE exp_reject_record;
                     END IF;
                  EXCEPTION
                     WHEN exp_reject_record
                     THEN
                        v_errmsg :=
                           'Error while insertig record in charge detail for annual fee';
                        RAISE;
                     WHEN OTHERS
                     THEN
                        v_errmsg :=
                              'Error while insertig record in charge detail for annual fee'
                           || SQLERRM;
                        RAISE exp_reject_record;
                  END;

------------------------------------------22-----------------------------------------
------------------------------------------23-----------------------------------------
                  BEGIN
                     UPDATE CMS_APPL_PAN
                        SET cap_join_feecalc = 'Y',
                            cap_next_bill_date =
                                ADD_MONTHS (cap_next_bill_date, v_annual_days)
                      WHERE cap_pan_code = j.cap_pan_code
                        AND cap_inst_code = prm_inst_code;

                     IF SQL%ROWCOUNT = 0
                     THEN
                        RAISE exp_reject_record;
                     END IF;
                  EXCEPTION
                     WHEN exp_reject_record
                     THEN
                        RAISE;
                     WHEN OTHERS
                     THEN
                        RAISE exp_reject_record;
                  END;

------------------------------------------23-----------------------------------------
------------------------------------------24-----------------------------------------
                  BEGIN
                     INSERT INTO CMS_FEE_PROCESSLOG
                                 (cfp_inst_code, cfp_pan_code,
                                  cfp_prod_code, cfp_card_type,
                                  cfp_process_flag, cfp_process_msg,
                                  cfp_fee_type
                                 )
                          VALUES (prm_inst_code, j.cap_pan_code,
                                  j.cap_prod_code, j.cap_card_type,
                                  'S', 'Successful',
                                  v_fee_type
                                 );

                     IF SQL%ROWCOUNT = 0
                     THEN
                        RAISE exp_reject_record;
                     END IF;
                  EXCEPTION
                     WHEN exp_reject_record
                     THEN
                        v_errmsg :=
                           'error While Insertimg annusl fee record in Error Log';
                        RAISE;
                     WHEN OTHERS
                     THEN
                        v_errmsg :=
                           'error While Insertimg annusl fee record in Error Log';
                        RAISE exp_reject_record;
                  END;*/
------------------------------------------24-----------------------------------------
               END IF;                 -- Joining and Annual fee condition End
			   
			   IF   TRIM(v_fee_code) IS NOT NULL THEN
				  
				  RAISE exp_succ_feecalc;
				  
			   END IF;
--********************************************************************************************************
            EXCEPTION
				WHEN exp_succ_feecalc THEN
				------------------------------
				BEGIN						  					--<< BEGIN exp_succ_flag >>
				
							 BEGIN                                                   --1.
		                        SELECT cfm_fee_amt
		                        INTO v_cfm_fee_amt
		                        FROM CMS_FEE_MAST
		                        WHERE cfm_inst_code = prm_inst_code
		                        AND cfm_fee_code = v_fee_code;
		                    EXCEPTION
		                        WHEN NO_DATA_FOUND
							                      THEN
								--ROLLBACK TO v_savepoint;
		                         v_errmsg :=
		                                'No Fee is defined on fee code' || v_fee_code;
								 RAISE exp_raise_feecalc;
		                      
		                       WHEN OTHERS
		                         THEN
		                          v_errmsg :=
		                              'No Fee is defined on fee code'
		                           || v_fee_code
		                           || SUBSTR(SQLERRM,1,200);
								 RAISE exp_raise_feecalc;
		                    END;                                                    --1.

-----------------------------------------21-----------------------------------------
                  			BEGIN
			                     IF v_cfm_fee_amt IS NOT NULL
			                     THEN
			                        v_waivamt := (v_waiv_prcnt / 100) * v_cfm_fee_amt;
			                        v_actualfeeamt := v_cfm_fee_amt - v_waivamt;
			                     END IF;
                            EXCEPTION
                                 WHEN OTHERS
                                     THEN
					   -- ROLLBACK TO v_savepoint;
                               v_errmsg :=
                                   'Error while calculate Annual fees and waivers';
						       RAISE exp_raise_feecalc;
                       
                            END;

------------------------------------------22-----------------------------------------
			                  BEGIN
			                     INSERT INTO CMS_CHARGE_DTL
			                                 (ccd_inst_code, ccd_pan_code,
			                                  ccd_mbr_numb, ccd_cust_code,
			                                  ccd_acct_id, ccd_acct_no, ccd_fee_freq,
			                                  ccd_feetype_code, ccd_fee_code,
			                                  ccd_calc_amt, ccd_expcalc_date,
			                                  ccd_calc_date, ccd_file_name,
			                                  ccd_file_date, ccd_ins_user,
			                                  ccd_lupd_user
			                                 )
			                          VALUES (prm_inst_code, j.cap_pan_code,
			                                  j.cap_mbr_numb, j.cap_cust_code,
			                                  j.cap_acct_id, j.cap_acct_no, 'O',
			                                  v_fee_type, v_fee_code,
			                                  v_actualfeeamt, v_calcdate,
			                                  SYSDATE, 'N',
			                                  SYSDATE + v_days, prm_lupduser,
			                                  prm_lupduser
			                                 );
			
			                     IF SQL%ROWCOUNT = 0
			                     THEN
								    v_errmsg :=
			                           'Error while insertig record in charge detail for annual fee';
			                        RAISE exp_raise_feecalc;
			                     END IF;
			                  EXCEPTION
			                     WHEN exp_raise_feecalc
			                     THEN
								    RAISE;
			                     WHEN OTHERS
			                     THEN
			                        v_errmsg :=
			                              'Error while insertig record in charge detail for annual fee'
			                           || SQLERRM;
			                        RAISE exp_raise_feecalc;
										  
			                  END;

------------------------------------------22-----------------------------------------
------------------------------------------23-----------------------------------------
			                  BEGIN
			                     UPDATE CMS_APPL_PAN
			                        SET cap_join_feecalc = 'Y',
			                            cap_next_bill_date =
			                                ADD_MONTHS (cap_next_bill_date, v_annual_days)
			                      WHERE cap_pan_code = j.cap_pan_code
			                        AND cap_inst_code = prm_inst_code;
			
			                     IF SQL%ROWCOUNT = 0
			                     THEN
								     v_errmsg :=
			                           'Error while updating record in pan master for   fee';
			                        RAISE exp_raise_feecalc;
			                     END IF;
			                  EXCEPTION
			                     WHEN exp_raise_feecalc
			                     THEN
			                       RAISE;
			                     WHEN OTHERS
			                     THEN
			                        v_errmsg :=
			                           'Error while updating record in pan master for   fee'|| SUBSTR(SQLERRM,1,200);
									RAISE exp_raise_feecalc;
			                  END;

------------------------------------------23-----------------------------------------
------------------------------------------24-----------------------------------------
			                  BEGIN
			                     INSERT INTO CMS_FEE_PROCESSLOG
			                                 (cfp_inst_code, cfp_pan_code,
			                                  cfp_prod_code, cfp_card_type,
			                                  cfp_process_flag, cfp_process_msg,
			                                  cfp_fee_type
			                                 )
			                          VALUES (prm_inst_code, j.cap_pan_code,
			                                  j.cap_prod_code, j.cap_card_type,
			                                  'S', 'Successful',
			                                  v_fee_type
			                                 );
			
			                     IF SQL%ROWCOUNT = 0
			                     THEN
								    v_errmsg :=
			                           'error While Insertimg annusl fee record in Error Log';
			                        RAISE exp_raise_feecalc;
			                     END IF;
			                  EXCEPTION
			                     WHEN exp_raise_feecalc
			                     THEN
			                       RAISE;
			                     WHEN OTHERS
			                     THEN
			                        v_errmsg :=
			                           'error While Insertimg annusl fee record in Error Log';
									 RAISE exp_raise_feecalc;
			                  END;
					EXCEPTION
					 WHEN exp_raise_feecalc
                     THEN
							    ROLLBACK TO v_savepoint;
		                        v_errmsg :=
		                           'Error while insertig record in charge detail for annual fee';
								   
		                        INSERT INTO CMS_FEE_PROCESSLOG
		                              (cfp_inst_code, cfp_pan_code,
		                               cfp_prod_code, cfp_card_type,
		                               cfp_process_flag, cfp_process_msg,
		                               cfp_fee_type
		                              )
		                       VALUES (prm_inst_code, j.cap_pan_code,
		                               j.cap_prod_code, j.cap_card_type,
		                               'E', v_errmsg,
		                               v_fee_type
		                              );
							 WHEN OTHERS
		                     THEN
							 	ROLLBACK TO v_savepoint;
		                        v_errmsg :=
		                           'error While Insertimg annual fee record in Error Log';
								   
		                        INSERT INTO CMS_FEE_PROCESSLOG
		                              (cfp_inst_code, cfp_pan_code,
		                               cfp_prod_code, cfp_card_type,
		                               cfp_process_flag, cfp_process_msg,
		                               cfp_fee_type
		                              )
		                       VALUES (prm_inst_code, j.cap_pan_code,
		                               j.cap_prod_code, j.cap_card_type,
		                               'E', v_errmsg,
		                               v_fee_type
		                              );
			
			
			         END;
			
				
               WHEN exp_reject_record
               THEN
                  v_errmsg := 'In Side Loop' || v_errmsg;
                  ROLLBACK TO v_savepoint;

                  INSERT INTO CMS_FEE_PROCESSLOG
                              (cfp_inst_code, cfp_pan_code,
                               cfp_prod_code, cfp_card_type,
                               cfp_process_flag, cfp_process_msg,
                               cfp_fee_type
                              )
                       VALUES (prm_inst_code, j.cap_pan_code,
                               j.cap_prod_code, j.cap_card_type,
                               'E', v_errmsg,
                               v_fee_type
                              );
               WHEN OTHERS
               THEN
                  v_errmsg := 'In Side Loop' || v_errmsg || SQLERRM;
                  ROLLBACK TO v_savepoint;

                  INSERT INTO CMS_FEE_PROCESSLOG
                              (cfp_inst_code, cfp_pan_code,
                               cfp_prod_code, cfp_card_type,
                               cfp_process_flag, cfp_process_msg,
                               cfp_fee_type
                              )
                       VALUES (prm_inst_code, j.cap_pan_code,
                               j.cap_prod_code, j.cap_card_type,
                               'E', v_errmsg,
                               v_fee_type
                              );
            END;                                                         --AB.

            v_errmsg := 'OK';
-----------------------------------------5-----------------------------------------
         END LOOP;
		 
		 INSERT INTO CMS_PROC_CTRL
		                           (cpc_proc_name, cpc_last_rundate, cpc_succ_flag,
		                            cpc_last_runfordate
		                           )
		                    VALUES ('FEE CALC', SYSDATE, 'Y',
		                            v_calcdate
		                           );  
								    
      EXCEPTION
         WHEN exp_reject_process
         THEN
            v_errmsg := 'Main Error ' || v_errmsg;
         WHEN OTHERS
         THEN                                                   -- For Loop J.
            v_errmsg := 'Main Error ' || v_errmsg || SQLERRM;
      END;                                                          --begin 3.
-----------------------------------------4-----------------------------------------
   END LOOP;                                                    -- For Loop i.
EXCEPTION
   WHEN OTHERS
   THEN
      prm_errmsg := 'main errmag' || SQLERRM;
END;
----------------------------------------Main Begin--------------------------------------
/


show error