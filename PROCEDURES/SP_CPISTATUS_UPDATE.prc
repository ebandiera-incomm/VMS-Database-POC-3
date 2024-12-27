create or replace PROCEDURE               VMSCMS.SP_CPISTATUS_UPDATE(
   prm_fileName   IN  VARCHAR2,
   prm_error      OUT   VARCHAR2,
   prm_rows_upd   OUT   NUMBER
)
IS
/**********************************************************************************************************
   * Created Date                 : 29/March/2012.
   * Created By                   : Dhiraj M.G.
   * Purpose                      : CPI Status update
   * Last Modification Done by    : sagar more
   * Last Modification Date       : 20-Aug-2012
   * Mofication Reason            : product id validation is removed  from code and hash column values of pan_code
                                    compared between cms_appl_pan and cms_cardissuanace_status table instead of
                                    encrypted pan while validating proxy number for performance tunning purpose
   * Build Number                 : RI0014 B0008

   * Modified Date     : 26-Mar-2013
   * Modified By       : Sachin P.
   * Modified For      : FSS-390
   * Purpose           : Logging of system initiated card status change(FSS-390)
   * Reviewer          : Dhiraj
   * Reviewed Date     :
   * Build Number      : RI0024_B0009

   * Modified By      : Ramesh
   * Modified Date    : 29-MAR-2014
   * Modified Reason  : Defect id :14434: validating serial number already mapped or not for proxy number
   * Reviewer         : spankaj
   * Reviewed Date    : 29-April-2014
   * Build Number     : RI0027.1.3_B0003

   * Modified By      : Ramesh
   * Modified Date    : 28-FEB-2014
   * Modified Reason  : MVCSD-4121 and FWR-43 : Logging of shipped date when application status changed to 15
   * Reviewer         : Dhiraj
   * Reviewed Date    : 10-Mar-2014
   * Build Number     : RI0027.2_B0002

   * Modified By      : Ramesh
   * Modified Date    : 20-MAY-2014
   * Modified Reason  : Integration the change Defect id :14434 to 2.2.1 release
   * Reviewer         : spankaj
   * Reviewed Date    : 21-May-2014
   * Build Number     : RI0027.2.1_B0001

   * Modified By      : Spankaj
   * Modified Date    : 30-Apr-2015
   * Modified Reason  : Performance changes
   * Reviewer         : Sarvanakumar
   * Build Number     : 3.0.1_B0003

    * Modified By      : Spankaj
   * Modified Date    : 29-July-2015
   * Modified Reason  : 16120: CPIFileUploadProcessJob Statusue to session timeout the flag is not updated in Batch Upload Param
   * Reviewer         : Sarvanakumar
   * Build Number     : 3.0.4

    * Modified by      : Pankaj S.
    * Modified Date    : 14-Sep-16
    * Modified For     : FSS-4779
    * Modified reason  : Card Generation Performance changes
    * Reviewer         : Saravanakumar
    * Build Number     : 4.2.5

    * Modified by      : Sai Prasad
    * Modified Date    : 30-May-2016
    * Modified For     : FSS-551
    * Modified reason  : Card Generation Performance changes
    * Reviewer         : Saravanakumar
    * Build Number     : 17.05


    * Modified by      : DHINAKRAN B
    * Modified Date    : 24-APR-2018
    * Modified For     : VMS-299
    * Modified reason  : VAN 16/19
    * Reviewer         : Saravanakumar
    * Build Number     : RG01

    * Modified by      : Raja Gopal
    * Modified Date    : 24-Jan-2019
    * Modified For     : VMS-688
    * Modified reason  : Process the records based on file name
    * Reviewer         : Saravanakumar
    * Build Number     : R12_B0000
	
	* Modified by      : Raj Devkota
    * Modified Date    : 06-Oct-2021
    * Modified For     : VMS-4096
    * Modified reason  : Remove transaction logging for Card Issuance Status update to Shipped
    * Reviewer         : Ubaidur
    * Build Number     : R53_B3

**********************************************************************************************************/
   CURSOR cur_file_data
   IS
      SELECT ROWID row_id, ccd_inst_code, ccd_magic_number,
             ccd_serial_number,CCD_VIRTUALACCT_NUMBER,ccd_parent_serial_number
        FROM cms_cpifile_data_temp where CCD_FILE_NAME =  prm_fileName;

   v_cap_pan_code      cms_appl_pan.cap_pan_code%TYPE;
   v_pan_code_encr     cms_appl_pan.cap_pan_code_encr%TYPE;
   v_respcode          VARCHAR2 (5);
   v_serial_count      NUMBER;
   v_error             VARCHAR2 (1000);
   v_bulk_coll_limit   NUMBER                                := 1000;

   TYPE type_cpi_file IS TABLE OF cur_file_data%ROWTYPE;

   cpi_file_data       type_cpi_file;
   main_exception      EXCEPTION;
   --SN Added for stock issu performance changes
   v_startercard_flag  cms_appl_pan.cap_startercard_flag%TYPE;
   v_cust_code           cms_appl_pan.cap_cust_code%TYPE;
   v_acct_id                 cms_appl_pan.cap_acct_id%TYPE;
   v_txn_log_flag       cms_transaction_mast.ctm_txn_log_flag%TYPE;
   --EN Added for stock issu performance changes
BEGIN
   prm_error := 'OK';
 
   BEGIN
      OPEN cur_file_data;

      LOOP
         FETCH cur_file_data
         BULK COLLECT INTO cpi_file_data LIMIT v_bulk_coll_limit;

         EXIT WHEN cpi_file_data.COUNT () = 0;

         FOR i IN 1 .. cpi_file_data.COUNT ()
         LOOP
            BEGIN
               v_error := 'OK';
               v_respcode := '00';

               BEGIN
                  SELECT cap_pan_code, cap_pan_code_encr,
                                 cap_startercard_flag, cap_cust_code, cap_acct_id  --Added for stock issu performance changes
                    INTO v_cap_pan_code, v_pan_code_encr,
                               v_startercard_flag, v_cust_code, v_acct_id --Added for stock issu performance changes
                    FROM cms_appl_pan, cms_cardissuance_status
                   WHERE cap_inst_code = ccs_inst_code
                     AND cap_pan_code = ccs_pan_code
                     AND cap_inst_code = cpi_file_data (i).ccd_inst_code
                     AND cap_proxy_number = cpi_file_data (i).ccd_magic_number
                     AND ((ccs_card_status = '3'
                     AND cap_card_stat = '0')
                     OR ( ccs_card_status = '21' AND cap_card_stat='3'));
               EXCEPTION
                  WHEN NO_DATA_FOUND THEN
                     v_error :='Proxy number not found inactive card with application status printer sent';
                     RAISE main_exception;
                  WHEN OTHERS THEN
                     v_error :='Error while selecting proxy number-'|| SUBSTR (SQLERRM, 1, 200);
                     RAISE main_exception;
               END;

               IF cpi_file_data (i).ccd_serial_number IS NOT NULL AND cpi_file_data (i).ccd_serial_number <> ' ' THEN
                  BEGIN
                     SELECT COUNT (1)
                       INTO v_serial_count
                       FROM cms_appl_pan
                      WHERE cap_inst_code = cpi_file_data (i).ccd_inst_code
                        AND cap_proxy_number <> cpi_file_data (i).ccd_magic_number
                        AND cap_serial_number = cpi_file_data (i).ccd_serial_number
                        AND cap_form_factor IS NULL;

                     IF v_serial_count <> 0 THEN
                        v_error :='Duplicate Serial Number not allowed for Proxy number '|| cpi_file_data (i).ccd_magic_number;
                        RAISE main_exception;
                     END IF;
                  EXCEPTION
                     WHEN main_exception THEN
                        RAISE;
                     WHEN OTHERS THEN
                        v_error :='Error while selecting serial number count-'|| SUBSTR (SQLERRM, 1, 200);
                        RAISE main_exception;
                  END;
               ELSE
                  v_error :='Serial number is empty for Proxy number '|| cpi_file_data (i).ccd_magic_number;
                  RAISE main_exception;
               END IF;

               BEGIN
                  UPDATE cms_appl_pan
                     SET cap_serial_number = cpi_file_data (i).ccd_serial_number
                     ,cap_van_number=cpi_file_data (i).CCD_VIRTUALACCT_NUMBER,CAP_PANMAST_PARAM2=cpi_file_data (i).CCD_PARENT_SERIAL_NUMBER
                   WHERE cap_inst_code = cpi_file_data (i).ccd_inst_code
                     AND cap_pan_code = v_cap_pan_code;
                     --AND cap_proxy_number = cpi_file_data (i).ccd_magic_number;

                  IF SQL%ROWCOUNT = 0 THEN
                     v_error := 'Serial number not updated';
                     RAISE main_exception;
                  END IF;
               EXCEPTION
                  WHEN main_exception THEN
                     RAISE;
                  WHEN OTHERS THEN
                     v_error :='Error while updating serial number-'|| SUBSTR (SQLERRM, 1, 200);
                     RAISE main_exception;
               END;

               BEGIN
                  UPDATE cms_cardissuance_status
                     SET ccs_card_status = '15',
                         ccs_shipped_date = SYSDATE
                   WHERE ccs_inst_code = cpi_file_data (i).ccd_inst_code
                     AND ccs_pan_code = v_cap_pan_code;

                  IF SQL%ROWCOUNT = 0 THEN
                     v_error := 'Card issuance status not updated';
                     RAISE main_exception;
                  END IF;
               EXCEPTION
                  WHEN main_exception THEN
                     RAISE;
                  WHEN OTHERS THEN
                     v_error :='Error while updating card issuance status-'|| SUBSTR (SQLERRM, 1, 200);
                     RAISE main_exception;
               END;

               --SN Added for stock issu performance changes
               IF v_startercard_flag='Y' THEN
                    BEGIN
                       INSERT INTO cms_smsandemail_alert (csa_inst_code, csa_pan_code, csa_pan_code_encr, csa_loadorcredit_flag,
                                                          csa_lowbal_flag, csa_negbal_flag, csa_highauthamt_flag, csa_dailybal_flag,
                                                          csa_insuff_flag, csa_incorrpin_flag, csa_fast50_flag, csa_fedtax_refund_flag,
                                                          csa_deppending_flag, csa_depaccepted_flag, csa_deprejected_flag, csa_ins_user, csa_ins_date)
                            VALUES (cpi_file_data (i).ccd_inst_code, v_cap_pan_code, v_pan_code_encr, 0,
                                             0, 0, 0, 0,
                                             0, 0, 0, 0,
                                             0, 0, 0, 1, SYSDATE);
                    EXCEPTION
					 WHEN DUP_VAL_ON_INDEX THEN NULL;
                       WHEN OTHERS THEN
                          v_error := 'Error while inserting records into SMS_EMAIL ALERT ' || SUBSTR (SQLERRM, 1, 200);
                          RAISE main_exception;
                    END;

                    BEGIN
                         INSERT INTO CMS_PAN_ACCT
                                     (cpa_inst_code, cpa_cust_code, cpa_acct_id,
                                      cpa_acct_posn, cpa_pan_code, cpa_mbr_numb,
                                      cpa_ins_user, cpa_lupd_user, cpa_pan_code_encr
                                     )
                              VALUES (cpi_file_data (i).ccd_inst_code, v_cust_code, v_acct_id,
                                      1, v_cap_pan_code, '000',
                                      1, 1, v_pan_code_encr
                                     );
                    EXCEPTION
                    WHEN DUP_VAL_ON_INDEX THEN
                      NULL;
                     WHEN OTHERS THEN
                        v_error :='Error while inserting records into pan acct  master '|| SUBSTR (SQLERRM, 1, 200);
                        RAISE main_exception;
                    END;
               END IF;
               --EN Added for stock issu performance changes

               BEGIN
                  UPDATE cms_cpifile_data_temp
                     SET ccd_process_flag = 'P',
                         ccd_error_desc = 'SUCCESSFUL'
                   WHERE ROWID = cpi_file_data (i).row_id;
               EXCEPTION
                  WHEN OTHERS THEN
                     prm_error := 'Error while updating flag p for successful record-'|| SUBSTR (SQLERRM, 1, 200);
                     RAISE main_exception;
               END;
               
			   ---- Added for vms-4096 remove transaction logging for Card Issuance Status update to Shipped
                BEGIN
                  SELECT nvl(ctm_txn_log_flag,'T')
                    INTO v_txn_log_flag
                    FROM cms_transaction_mast
                   WHERE ctm_inst_code = 1
                     AND ctm_tran_code = '06'
                     AND ctm_delivery_channel = '05';
               EXCEPTION
                  WHEN OTHERS
                  THEN                    
                     v_error :=
                         'Error while selecting txn details-' || SUBSTR (SQLERRM, 1, 200);
                     RAISE main_exception;
               END;
               
               IF v_txn_log_flag = 'T'				--- Modified for vms-4096  
               THEN 
               
                   sp_log_cardstat_chnge (cpi_file_data (i).ccd_inst_code, v_cap_pan_code, v_pan_code_encr, NULL, '06', NULL, NULL,
                                          NULL, v_respcode, v_error );
    
                   IF v_respcode <> '00' AND v_error <> 'OK' THEN
                      INSERT INTO cms_statupd_log_failure
                                  (csf_inst_code, csf_pan_code_encr, ccs_pan_code, csf_ins_date, csf_failure_reason )
                           VALUES (cpi_file_data (i).ccd_inst_code, v_pan_code_encr, v_cap_pan_code, SYSDATE, v_error );
                   END IF;
               
               END IF;

            EXCEPTION
               WHEN main_exception
               THEN
                  UPDATE cms_cpifile_data_temp
                     SET ccd_process_flag = 'E',
                         ccd_error_desc = v_error
                   WHERE ROWID = cpi_file_data (i).row_id;
               WHEN OTHERS THEN
                  v_error :='Error while updating flag card status-'|| SUBSTR (SQLERRM, 1, 200);

                  UPDATE cms_cpifile_data_temp
                     SET ccd_process_flag = 'E',
                         ccd_error_desc = v_error
                   WHERE ROWID = cpi_file_data (i).row_id;
            END;
         END LOOP;
         COMMIT;
      END LOOP;

      CLOSE cur_file_data;
   END;

   BEGIN
      INSERT INTO cms_cpifile_data
         SELECT * FROM cms_cpifile_data_temp where CCD_FILE_NAME =  prm_fileName;
   EXCEPTION
      WHEN OTHERS THEN
         prm_error :='Error while moving data to history table-'|| SUBSTR (SQLERRM, 1, 200);
   END;

--    BEGIN
--       UPDATE cms_batchupload_param
--          SET cbp_param_value = 'Y'
--        WHERE cbp_inst_code = 1 AND cbp_param_key = 'CPIUPLOAD_PROCESS_STATUS';
--    EXCEPTION
--       WHEN OTHERS THEN
--          prm_error :='Error while updating cms_batchupload_param-'|| SUBSTR (SQLERRM, 1, 200);
--    END;
    COMMIT;
EXCEPTION
   WHEN OTHERS THEN
      prm_error := ' Main Exception ' || SUBSTR (SQLERRM, 1, 200);
END;
/
show error