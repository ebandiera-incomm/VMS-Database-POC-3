CREATE OR REPLACE PROCEDURE VMSCMS.Sp_Group_Renew_Pan (
   instcode   IN       NUMBER,
   remark     IN       VARCHAR2,
   indate     IN       DATE,
   binlist    IN       VARCHAR2,
   frombran   IN       VARCHAR2,
   tobran     IN       VARCHAR2,
   --locncode   IN       NUMBER,
   lupduser   IN       NUMBER,
   errmsg     OUT      VARCHAR2
)
AS
   v_expiryparam         NUMBER;
   v_renew_param         NUMBER;
   renew_cnt             NUMBER                                    := 0;
   v_rencaf_fname        CMS_RENCAF_HEADER.crh_rencaf_fname%TYPE;
   v_pan                 CMS_APPL_PAN.cap_pan_code%TYPE;
   v_errmsg              VARCHAR2 (500);
   v_date1               DATE;
   v_date2               DATE;
   v_date3               DATE;
   v_binlist             VARCHAR2 (500);
   v_from_bran           VARCHAR2 (50);
  -- v_to_bran             VARCHAR2 (50);
   v_binflag             VARCHAR2 (1);
   v_branflag            VARCHAR2 (1);
   v_number_of_bins      NUMBER;
   v_prod_code           CMS_APPL_PAN.cap_prod_code%TYPE;
   start_point           NUMBER;
   acctcnt               NUMBER;
   dum                   NUMBER;
   v_filter              VARCHAR2 (1);
   v_filter_count        NUMBER;
   v_hsm_mode            VARCHAR2 (1);
   v_emboss_flag         VARCHAR2 (1);
   --embosgen              cms_locn_mast.clm_embos_gen%TYPE;
   noaccountsexception   EXCEPTION;
   rencafexception       EXCEPTION;
   filterpan             EXCEPTION;
   inactivecards         EXCEPTION;
   exp_prepaid           EXCEPTION;
   record_exist          NUMBER;
   v_cardstat            CHAR (1);
   v_errflag			 CHAR(1);
   v_succ_flag			 CHAR(1);
   --gets the cards that are expiring in the month on which this procedure is executed.
   CURSOR c1 (p_date1 DATE, p_date2 DATE)
   IS
      SELECT cap_pan_code, cap_mbr_numb, cap_prod_catg, cap_acct_no,
             cap_disp_name, cap_expry_date, cap_card_stat, cap_prod_code,
             cap_appl_bran
        FROM CMS_APPL_PAN, CMS_BRAN_MAST
       WHERE cap_expry_date >= p_date1
         AND cap_expry_date <= p_date2
         AND cbm_inst_code = instcode
         AND cbm_bran_code = cap_appl_bran;
BEGIN                                                             --1.1 --Main
   errmsg := 'OK';

   -- Gets the Validity period from the Parameter table.
   BEGIN
      SELECT cip_param_value
        INTO v_hsm_mode
        FROM CMS_INST_PARAM
       WHERE cip_param_key = 'HSM_MODE';

      IF v_hsm_mode = 'Y'
      THEN
         v_emboss_flag := 'Y';                 -- i.e. generate embossa file.
      ELSE
         v_emboss_flag := 'N';           -- i.e. don't generate embossa file.
      END IF;
   EXCEPTION
      WHEN NO_DATA_FOUND
      THEN
         v_hsm_mode := 'N';
         v_emboss_flag := 'N';           -- i.e. don't generate embossa file.
   END;

   SELECT TO_NUMBER (cip_param_value)
     INTO v_renew_param
     FROM CMS_INST_PARAM
    WHERE cip_param_key = 'RENEWCAF';

   v_date1 :=
      TO_DATE (TO_CHAR (indate, 'yyyy-mm-dd') || ' 00:00:00',
               'yyyy-mm-dd hh24:mi:ss'
              );
   v_date2 :=
      LAST_DAY (TO_DATE (TO_CHAR (indate, 'yyyy-mm-dd') || ' 23:59:59',
                         'yyyy-mm-dd hh24:mi:ss'
                        )
               );
   v_from_bran := frombran;
   --v_to_bran := tobran;
   v_binlist := binlist;
   v_binflag := 'N';

   IF (v_binlist != 'ALL')
   THEN
      v_number_of_bins := LENGTH (v_binlist) / 6;
   END IF;

   FOR x IN c1 (v_date1, v_date2)
   LOOP
      BEGIN                                                             --1.2
         IF x.cap_prod_catg = 'D'
         THEN
            BEGIN                                          --begin new 1.4.11
               SELECT cpm_validity_period
                 INTO v_expiryparam
                 FROM CMS_PROD_MAST
                WHERE cpm_inst_code = instcode
                  AND cpm_prod_code = x.cap_prod_code;
            EXCEPTION                                      --excp of new 1.4.1
               WHEN NO_DATA_FOUND
               THEN
                  v_expiryparam := 120;
            END;                                           --end of new 1.4.11

            v_date3 := LAST_DAY (ADD_MONTHS (indate, v_expiryparam));
            v_binflag := 'N';
            v_branflag := 'N';
            dum := 0;

            IF (v_binlist = 'ALL')
            THEN
               v_binflag := 'Y';
            ELSE
               BEGIN
                  start_point := 1;

                  FOR i IN 1 .. v_number_of_bins
                  LOOP
                     IF ((TO_NUMBER (SUBSTR (v_binlist, start_point, 6))) =
                                  (TO_NUMBER (SUBSTR (x.cap_pan_code, 1, 6))
                                  )
                        )
                     THEN
                        v_binflag := 'Y';
                        EXIT;
                     END IF;

                     start_point := start_point + 6;
                  END LOOP;
               END;
            END IF;

            IF (    NVL (LENGTH (TRIM (v_from_bran)), 0) = 0
                --AND NVL (LENGTH (TRIM (v_to_bran)), 0) = 0
               )
            THEN
               v_branflag := 'Y';
            END IF;

            DBMS_OUTPUT.put_line ('Before cond');

            IF (    NVL (LENGTH (TRIM (v_from_bran)), 0) != 0
                --AND NVL (LENGTH (TRIM (v_to_bran)), 0) = 0
               )
            THEN
               DBMS_OUTPUT.put_line ('After cond');

               BEGIN
                  SELECT COUNT (1)
                    INTO dum
                    FROM CMS_BRANCH_REGION
                   WHERE cbr_inst_code = instcode
                     AND cbr_region_id = v_from_bran
                     AND cbr_bran_code = x.cap_appl_bran;

                  IF (dum = 0)
                  THEN
                     v_branflag := 'N';
                  ELSE
                     v_branflag := 'Y';
                  END IF;
               END;
            END IF;

            IF (    NVL (LENGTH (TRIM (v_from_bran)), 0) != 0
                --AND NVL (LENGTH (TRIM (v_to_bran)), 0) != 0
               )
            THEN
               IF (    (TO_NUMBER (x.cap_appl_bran) >= TO_NUMBER (v_from_bran)
                       )
                  -- AND (TO_NUMBER (x.cap_appl_bran) <= TO_NUMBER (v_to_bran))
                  )
               THEN
                  v_branflag := 'Y';
               END IF;
            END IF;

            IF (v_branflag = 'Y' AND v_binflag = 'Y')
            THEN
               IF (x.cap_card_stat != '1')
               THEN
                  RAISE inactivecards;
               END IF;

               IF renew_cnt = 0
               THEN
                  --generate new file here and store it in a variable and use the filename below
                  Sp_Create_Rencaffname (instcode,
                                         lupduser,
                                         v_rencaf_fname,
                                         errmsg
                                        );

                  IF errmsg != 'OK'
                  THEN
                     errmsg := 'Error while creating filename -- ' || errmsg;
                     RAISE rencafexception;
                  END IF;
               END IF;

               /*BEGIN
                  SELECT COUNT (1)
                    INTO v_filter_count
                    FROM cms_ren_pan_temp
                   WHERE crp_pan_code = x.cap_pan_code;

                  IF v_filter_count > 0
                  THEN
                     RAISE filterpan;
                  END IF;
               EXCEPTION
                  WHEN NO_DATA_FOUND
                  THEN
                     NULL;
               END;*/

               BEGIN
                  SELECT DISTINCT cpa_pan_code
                             INTO v_pan
                             FROM CMS_PAN_ACCT
                            WHERE cpa_inst_code = instcode
                              AND cpa_pan_code = x.cap_pan_code;
               EXCEPTION
                  WHEN NO_DATA_FOUND
                  THEN
                     RAISE noaccountsexception;
               END;

               --Renews the card by updating its Expiry date.
               IF (v_hsm_mode = 'N')
               THEN
                  UPDATE CMS_APPL_PAN
                     SET cap_expry_date = v_date3,
                         cap_lupd_date = SYSDATE
                   WHERE cap_pan_code = x.cap_pan_code
                     AND cap_mbr_numb = x.cap_mbr_numb;
               ELSE
                  UPDATE CMS_APPL_PAN
                     SET cap_expry_date = v_date3,
                         cap_lupd_date = SYSDATE,
                         cap_embos_flag = 'Y'
                   WHERE cap_pan_code = x.cap_pan_code
                     AND cap_mbr_numb = x.cap_mbr_numb;
               END IF;
			   IF errmsg = 'OK' THEN
			   	  		   v_errflag := 'S';
			               errmsg := 'Successful';
						   v_succ_flag := 'S';
			   
			               INSERT INTO CMS_GROUP_RENEW_TEMP
						   (CGT_INST_CODE, CGT_CARD_NO, CGT_FILE_NAME, CGT_REMARKS, 
						   CGT_PROCESS_FLAG, CGT_PROCESS_MSG, CGT_INS_USER, 
						   CGT_INS_DATE, CGT_MBR_NUMB)
			               VALUES (instcode,x.cap_pan_code, NULL, remark
			               ,v_succ_flag,errmsg,lupduser, SYSDATE,'000' );
						   INSERT INTO CMS_RENEW_DETAIL
			                        (crd_inst_code, crd_card_no, crd_file_name,
			                         crd_remarks, crd_msg24_flag, crd_process_flag,
			                         crd_process_msg, crd_process_mode, crd_ins_user,
			                         crd_ins_date, crd_lupd_user, crd_lupd_date
			                        )
			                 VALUES (instcode, x.cap_pan_code, NULL,
			                         remark, 'N', 'S',
			                         errmsg, 'G', lupduser,
			                         SYSDATE, lupduser, SYSDATE
			                        );
			   ELSE 
			   INSERT INTO CMS_RENEW_DETAIL
                        (crd_inst_code, crd_card_no, crd_file_name,
                         crd_remarks, crd_msg24_flag, crd_process_flag,
                         crd_process_msg, crd_process_mode, crd_ins_user,
                         crd_ins_date, crd_lupd_user, crd_lupd_date
                        )
                 VALUES (instcode, x.cap_pan_code, NULL,
                         remark, 'N', 'E',
                         errmsg, 'G', lupduser,
                         SYSDATE, lupduser, SYSDATE
                        );
			   END IF;
			   
						   
			  
               --now log the support function into cms_pan_spprt
               INSERT INTO CMS_PAN_SPPRT
                           (cps_inst_code, cps_pan_code, cps_mbr_numb,
                            cps_prod_catg, cps_spprt_key, cps_spprt_rsncode,
                            cps_func_remark, cps_ins_user, cps_lupd_user
                           )
                    VALUES (instcode, x.cap_pan_code, x.cap_mbr_numb,
                            x.cap_prod_catg, 'RENEW', 1,
                            remark, lupduser, lupduser
                           );

               record_exist := 1;

               BEGIN
                  SELECT cci_crd_stat
                    INTO v_cardstat
                    FROM CMS_CAF_INFO
                   WHERE cci_inst_code = instcode
                     AND cci_pan_code = DECODE(LENGTH(x.cap_pan_code), 16,x.cap_pan_code || '   ',
                                      19,x.cap_pan_code)--RPAD (x.cap_pan_code, 19, ' ')
                     AND cci_mbr_numb = x.cap_mbr_numb
                     AND cci_file_gen = 'N';
               EXCEPTION
                  WHEN NO_DATA_FOUND
                  THEN
                     record_exist := 0;
               END;

               --Before insert into into cms_caf_info, delete the row from cms_caf_info
               DELETE FROM CMS_CAF_INFO
                     WHERE cci_inst_code = instcode
                       AND cci_pan_code = DECODE(LENGTH(x.cap_pan_code), 16,x.cap_pan_code || '   ',
                                      	  								 19,x.cap_pan_code)--RPAD (x.cap_pan_code, 19)
                       AND cci_mbr_numb = x.cap_mbr_numb;

               Sp_Caf_Rfrsh (instcode,
                             x.cap_pan_code,
                             NULL,
                             SYSDATE,
                             'C',
                             NULL,
                             'RENEW',
                             lupduser,
                             errmsg
                            );

               IF errmsg != 'OK'
               THEN
                  errmsg := 'From Caf Refresh -- ' || errmsg;
               ELSE
                  renew_cnt := renew_cnt + 1;

                  IF renew_cnt = v_renew_param
                  THEN
                     renew_cnt := 0;
                  END IF;

                  IF record_exist = 1
                  THEN
                     UPDATE CMS_CAF_INFO
                        SET cci_crd_stat = v_cardstat,
                            cci_file_name = v_rencaf_fname
                      WHERE cci_inst_code = instcode
                        AND cci_pan_code = DECODE(LENGTH(x.cap_pan_code), 16,x.cap_pan_code || '   ',
                                      	   								  19,x.cap_pan_code)--RPAD (x.cap_pan_code, 19, ' ')
                        AND cci_mbr_numb = x.cap_mbr_numb;
                  ELSE
                     UPDATE CMS_CAF_INFO
                        SET cci_file_name = v_rencaf_fname
                      WHERE cci_inst_code = instcode
                        AND cci_pan_code = DECODE(LENGTH(x.cap_pan_code), 16,x.cap_pan_code || '   ',
                                      	   								  19,x.cap_pan_code)--RPAD (x.cap_pan_code, 19, ' ')
                        AND cci_mbr_numb = x.cap_mbr_numb;
                  END IF;
               END IF;
            END IF;
			  BEGIN														 --8.
		         INSERT INTO PCMS_AUDIT_LOG
		                     (pal_card_no, pal_activity_type, pal_transaction_code,
		                      pal_delv_chnl, pal_tran_amt, pal_source,
		                      pal_success_flag, pal_ins_user, pal_ins_date
		                     )
		              VALUES (x.cap_pan_code, remark, NULL,
		                      NULL, 0, 'HOST',
		                      'S', lupduser, SYSDATE
		                     );
		      EXCEPTION
		         WHEN OTHERS
		         THEN
		            errmsg := 'Pan Not Found in Master';
		            
		      END;	
         ELSIF x.cap_prod_catg = 'P'
         THEN
            BEGIN
               Sp_Group_Renew_Pan2 (instcode,
                                    x.cap_pan_code,
                                    x.cap_mbr_numb,
                                    remark,
                                    lupduser,
                                    errmsg
                                   );

               IF errmsg != 'OK'
               THEN
                  errmsg := 'Error from prepaid card proc' || errmsg;
                  RAISE exp_prepaid;
               END IF;
            EXCEPTION
               WHEN exp_prepaid
               THEN
                  RAISE;
               WHEN OTHERS
               THEN
                  RAISE exp_prepaid;
            END;
         END IF;
      EXCEPTION
         WHEN inactivecards
         THEN
            v_errmsg := 'The PAN is not in active state ...';
         WHEN filterpan
         THEN
            v_errmsg := 'The PAN is filtered for the process ...';
         WHEN noaccountsexception
         THEN
            v_errmsg := 'Account not Present in Masters';
         WHEN rencafexception
         THEN
            v_errmsg := 'Problem in creating rencaf filename';
         WHEN exp_prepaid
         THEN
            v_errmsg := 'problem in prepaid card renewal' || errmsg;
         WHEN OTHERS
         THEN
            v_errmsg := 'EXCP 1.2 ' || SQLERRM;
      END;                                                               --1.2
   END LOOP;

   COMMIT;
EXCEPTION
   WHEN OTHERS
   THEN
      errmsg := 'Main Excp -- ' || v_errmsg || SQLERRM;
      ROLLBACK;
END;
/


