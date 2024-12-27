CREATE OR REPLACE PROCEDURE VMSCMS.MIGR_CUST_DATA_LOAD (
   prm_instcode    IN       NUMBER,
   prm_file_name   IN       VARCHAR2,
   prm_errmsg      OUT      VARCHAR2,
   prm_seqno       IN       number
)
AS
   v_file_handle             UTL_FILE.file_type;
   v_filebuffer              VARCHAR2 (32767);
   v_header                  VARCHAR2 (50);
   v_header_file             VARCHAR2 (30);
   v_header_cnt              NUMBER (20);
   v_record_numb             VARCHAR2 (19);
   v_title                   VARCHAR2 (5);
   v_first_name              VARCHAR2 (40);
   v_last_name               VARCHAR2 (40);
   v_ssn                     VARCHAR2 (40);
   v_init_topup_amt          VARCHAR2 (11);
   v_birth_date              VARCHAR2 (8);
   v_perm_addr_line1         VARCHAR2 (50);
   v_perm_addr_line2         VARCHAR2 (50);
   v_perm_addr_city          VARCHAR2 (40);
   v_perm_addr_state_code    VARCHAR2 (3);
   v_perm_addr_cntry_code    VARCHAR2 (50);
   v_perm_addr_postal_code   VARCHAR2 (15);
   v_perm_addr_phone         VARCHAR2 (20);
   v_perm_addr_mobile        VARCHAR2 (40);--Modified length from 20 to 40 Dhiraj Gaikwad
   v_mail_addr_line1         VARCHAR2 (50);
   v_mail_addr_line2         VARCHAR2 (50);
   v_mail_addr_city          VARCHAR2 (40);
   v_mail_addr_state_code    VARCHAR2 (3);
   v_mail_addr_cntry_code    VARCHAR2 (50);
   v_mail_addr_postal_code   VARCHAR2 (15);
   v_mail_addr_phone         VARCHAR2 (40);
   v_mail_addr_mobile        VARCHAR2 (40);--Modified length from 20 to 40 Dhiraj Gaikwad
   v_email_address           VARCHAR2 (50);
   v_prod_code               VARCHAR2 (6);
   v_prod_catg_code          VARCHAR2 (2);
   v_branch_id               VARCHAR2 (6);
   --v_cust_id                 VARCHAR2 (30);
   v_card_number             VARCHAR2 (25);
   v_card_no_already_present VARCHAR2 (25);
   v_card_stat               VARCHAR2 (5);
   v_proxy_number            VARCHAR2 (12);
   v_starter_card_flag       VARCHAR2 (1);
   v_active_date             VARCHAR2 (17);
   v_expiry_date             VARCHAR2 (17);
   v_pangen_date             VARCHAR2 (17);
   v_atm_offline_limit       VARCHAR2 (10);
   v_atm_online_limit        VARCHAR2 (10);
   v_pos_offline_limit       VARCHAR2 (10);
   v_pos_online_limit        VARCHAR2 (10);
   v_offline_aggr_limit      VARCHAR2 (10);
   v_online_aggr_limit       VARCHAR2 (10);
   v_mmpos_online_limit      VARCHAR2 (10);
   v_mmpos_offline_limit     VARCHAR2 (10);
   v_pin_offset              VARCHAR2 (10);
   v_next_bill_date          VARCHAR2 (8);
   v_next_mb_date            VARCHAR2 (8);
   v_emboss_gendate          VARCHAR2 (17);
   v_emboss_genflag          VARCHAR2 (1);
   v_pin_gendate             VARCHAR2 (17);
   v_pin_genflag             VARCHAR2 (1);
   v_ccf_file_name           VARCHAR2 (50);
   v_kyc_flag                VARCHAR2 (1);
   v_tot_accts               VARCHAR2 (1);
   v_acct_numb1              VARCHAR2 (20);
   v_acct_numb2              VARCHAR2 (20);
   v_acct_numb3              VARCHAR2 (20);
   v_acct_numb4              VARCHAR2 (20);
   v_acct_numb5              VARCHAR2 (20);
   v_savig_acct_numb         VARCHAR2 (20);   
   v_serial_numb             VARCHAR2 (40);
   v_initial_load_flag       VARCHAR2 (1);
   v_security_quest1         VARCHAR2 (200);
   v_security_ans1           VARCHAR2 (100);
   v_security_quest2         VARCHAR2 (200);
   v_security_ans2           VARCHAR2 (100);
   v_security_quest3         VARCHAR2 (200);
   v_security_ans3           VARCHAR2 (100);
   v_customer_username       VARCHAR2 (50);
   v_customer_password       VARCHAR2 (100);
   v_sms_alert_flag          VARCHAR2 (1);
   v_email_alert_flag        VARCHAR2 (1);
   v_email_check             VARCHAR2 (1);
   v_check                   NUMBER             := 0;
   v_cnt                     NUMBER             := 0;
   v_succ_cnt                NUMBER (6)         := 0;
   v_err_cnt                 NUMBER (6)         := 0;
   exp_file_name             EXCEPTION;
   v_errmsg                  VARCHAR2 (32767);
   exp_reject_loop_record    EXCEPTION;
   exp_reject_record_main    EXCEPTION;
   v_file_chk                NUMBER (2);
   v_error_flag              NUMBER (2);
   v_commit_param            NUMBER (5);
   PRAGMA EXCEPTION_INIT (exp_file_name, -29283);
   --Sn Added by Pankaj S. for check digit check
   v_tmppan                  VARCHAR2 (20);
   v_maxserl                 VARCHAR2 (5);
   v_ceilable_sum            NUMBER;
   v_ceiled_sum              NUMBER;
   v_temp_pan                NUMBER;
   v_len_pan                 VARCHAR2 (3);
   v_res                     VARCHAR2 (3);
   v_mult_ind                VARCHAR2 (1);
   v_dig_sum                 VARCHAR2 (2);
   v_dig_len                 VARCHAR2 (1);
   v_checkdig                VARCHAR2 (1);
   --En Added by Pankaj S. for check digit check
   --Sn added by Pankaj S. on 11_Jun_2013
   v_store_id                VARCHAR2 (15);
   v_id_type                 VARCHAR2 (5);
   v_dum                     NUMBER (1);
--En added by Pankaj S. on 11_Jun_2013
   v_numchk                  NUMBER;
   v_datechk                 DATE;
   v_merchant_id             VARCHAR2 (15);           -- Added on 20-JUN-2013
   v_inv_flag                VARCHAR2 (1);            -- Added on 20-JUN-2013
   v_length_check            VARCHAR2 (1000);
   v_sqlerr                  VARCHAR2 (32767);
   v_id_issuer               VARCHAR2 (40);
   v_idissuence_date         VARCHAR2 (17);
   v_idexpry_date            VARCHAR2 (17);
   v_cam_reg_date            VARCHAR2 (17);           -- Added on 09-OCT-2013
   V_PACKAGE_TYPE  CMS_CAF_INFO_ENTRY.CCI_PACKAGE_TYPE%TYPE; --Dhiraj Gaikwad
BEGIN
   prm_errmsg := 'OK';

   --Sn Modified on 02_Aug_2013
   --IF SUBSTR (prm_file_name, 1, INSTR (prm_file_name, '_', 1)) <> 'CUST_'
   IF SUBSTR (prm_file_name, INSTR (prm_file_name, '_', 1)+1, (INSTR (prm_file_name, '_',1, 2)-INSTR (prm_file_name, '_', 1))) <> 'CUST_'
   --En Modified on 02_Aug_2013
   THEN
      prm_errmsg := 'Invalid file for Customer data.';
      RAISE exp_reject_record_main;
   END IF;

   BEGIN
      SELECT COUNT (1)
        INTO v_file_chk
        FROM migr_file_detl
       WHERE mfd_file_name = prm_file_name AND mfd_file_load_flag = 'S';

      IF v_file_chk != 0
      THEN
         prm_errmsg := 'File already processed.';
         RAISE exp_reject_record_main;
      END IF;
   EXCEPTION
      WHEN exp_reject_record_main
      THEN
         RAISE;
      WHEN OTHERS
      THEN
         prm_errmsg :=
               'Error while selecting file name ' || SUBSTR (SQLERRM, 1, 200);
         RAISE exp_reject_record_main;
   END;

   BEGIN
      SELECT mct_ctrl_numb
        INTO v_commit_param
        FROM migr_ctrl_table
       WHERE mct_ctrl_key = 'COMMIT_PARAM';
   EXCEPTION
      WHEN NO_DATA_FOUND
      THEN
         prm_errmsg := 'Commit Paramter not defined in master.';
         RAISE exp_reject_record_main;
      WHEN OTHERS
      THEN
         prm_errmsg :=
               'Error while getting commit parameter '
            || SUBSTR (SQLERRM, 1, 200);
         RAISE exp_reject_record_main;
   END;

   IF UTL_FILE.is_open (v_file_handle)
   THEN
      UTL_FILE.fclose (v_file_handle);
   END IF;

   v_file_handle := UTL_FILE.fopen ('DIR_CUST', prm_file_name, 'R', 32767);
   UTL_FILE.get_line (v_file_handle, v_filebuffer);            --to get header
   v_header := v_filebuffer;
   v_header_cnt :=
                  SUBSTR (v_filebuffer, INSTR (v_filebuffer, '_', -1, 1) + 1,
                          8);                ---to get count present in header
--  dbms_output.put_line(v_header_cnt);
   v_header_file :=                         --to extract file name from header
      SUBSTR (SUBSTR (v_filebuffer, INSTR (v_filebuffer, '_', 1) + 1),
              1,
                INSTR (SUBSTR (v_filebuffer, INSTR (v_filebuffer, '_', 1) + 1),
                       '_',
                       -1
                      )
              - 1
             );

   IF SUBSTR (prm_file_name, 1, INSTR (prm_file_name, '_', 1,2) - 1) <>  --modified on 02_Aug_2013
                                                                 v_header_file
   THEN
      prm_errmsg := 'filename and header not matched';

      IF UTL_FILE.is_open (v_file_handle)
      THEN
         UTL_FILE.fclose (v_file_handle);
      END IF;

      RAISE exp_reject_record_main;
   END IF;

   ---Sn to count number lines in file excluding header and footer
   LOOP
      UTL_FILE.get_line (v_file_handle, v_filebuffer);
      EXIT WHEN SUBSTR (v_filebuffer, 1, 3) = 'FF_';
      v_check := v_check + 1;
--      IF   LENGTH (TRIM(v_filebuffer))
--         - LENGTH (TRIM (REPLACE (v_filebuffer, '|', ''))) <> 74
   END LOOP;

   ---En to count number lines in file excluding header and footer
   IF v_check <> TO_NUMBER (v_header_cnt, 999999)
   THEN
      prm_errmsg := 'Record count not matched';

      IF UTL_FILE.is_open (v_file_handle)
      THEN
         UTL_FILE.fclose (v_file_handle);
      END IF;

      RAISE exp_reject_record_main;
   END IF;

   v_file_handle := UTL_FILE.fopen ('DIR_CUST', prm_file_name, 'R', 32767);
   UTL_FILE.get_line (v_file_handle, v_filebuffer);

   ---Sn to create records in migration table
   LOOP
      BEGIN
         v_title := NULL;
         v_first_name := NULL;
         v_last_name := NULL;
         v_ssn := NULL;
         v_init_topup_amt := NULL;
         v_birth_date := NULL;
         v_perm_addr_line1 := NULL;
         v_perm_addr_line2 := NULL;
         v_perm_addr_city := NULL;
         v_perm_addr_state_code := NULL;
         v_perm_addr_cntry_code := NULL;
         v_perm_addr_postal_code := NULL;
         v_perm_addr_phone := NULL;
         v_perm_addr_mobile := NULL;
         v_mail_addr_line1 := NULL;
         v_mail_addr_line2 := NULL;
         v_mail_addr_city := NULL;
         v_mail_addr_state_code := NULL;
         v_mail_addr_cntry_code := NULL;
         v_mail_addr_postal_code := NULL;
         v_mail_addr_phone := NULL;
         v_mail_addr_mobile := NULL;
         v_email_address := NULL;
         v_prod_code := NULL;
         v_prod_catg_code := NULL;
         v_branch_id := NULL;
         --v_cust_id := NULL;
         v_card_number := NULL;
         v_card_stat := NULL;
         v_proxy_number := NULL;
         v_starter_card_flag := NULL;
         v_active_date := NULL;
         v_expiry_date := NULL;
         v_pangen_date := NULL;
         v_atm_offline_limit := NULL;
         v_atm_online_limit := NULL;
         v_pos_offline_limit := NULL;
         v_pos_online_limit := NULL;
         v_offline_aggr_limit := NULL;
         v_online_aggr_limit := NULL;
         v_mmpos_online_limit := NULL;
         v_mmpos_offline_limit := NULL;
         v_pin_offset := NULL;
         v_next_bill_date := NULL;
         v_ccf_file_name := NULL;
         v_kyc_flag := NULL;
         v_tot_accts := NULL;
         v_acct_numb1 := NULL;
         v_acct_numb2 := NULL;
         v_acct_numb3 := NULL;
         v_acct_numb4 := NULL;
         v_acct_numb5 := NULL;
         v_savig_acct_numb := NULL;
         v_serial_numb := NULL;
         v_initial_load_flag := NULL;
         v_security_quest1 := NULL;
         v_security_ans1 := NULL;
         v_security_quest2 := NULL;
         v_security_ans2 := NULL;
         v_security_quest3 := NULL;
         v_security_ans3 := NULL;
         v_customer_username := NULL;
         v_customer_password := NULL;
         v_sms_alert_flag := NULL;
         v_email_alert_flag := NULL;
         v_error_flag := NULL;
         v_email_check := NULL;
         v_ceilable_sum := 0;                            --Added by Pankaj S.
         v_store_id := NULL;              --Added by Pankaj S. on 11_Jun_2013
         v_id_type := NULL;               --Added by Pankaj S. on 11_Jun_2013
         v_merchant_id := NULL;                       -- Added on 20-JUN-2013
         v_inv_flag := 'N';                           -- Added on 20-JUN-2013
         v_cam_reg_date := NULL;                      -- Added on 09-OCT-2013
         v_length_check := NULL;
         v_errmsg := 'OK';
         v_sqlerr := 'OK';
		 V_PACKAGE_TYPE:=NULL; --Dhiraj Gaikwad
         UTL_FILE.get_line (v_file_handle, v_filebuffer);
         EXIT WHEN SUBSTR (v_filebuffer, 1, 3) = 'FF_';
         v_cnt := v_cnt + 1;

         --dbms_output.put_line(i);
         --dbms_output.put_line(v_filebuffer);
         BEGIN
            SELECT mct_ctrl_numb
              INTO v_record_numb
              FROM migr_ctrl_table
             WHERE mct_ctrl_key = 'CUSTOMER_DATA' AND mct_inst_code = 1;
         EXCEPTION
            WHEN NO_DATA_FOUND
            THEN
               prm_errmsg := 'Control number not defined for customer data.';
               RAISE exp_reject_record_main;
            WHEN OTHERS
            THEN
               prm_errmsg :=
                     'Error while getting control number '
                  || SUBSTR (SQLERRM, 1, 200);
               RAISE exp_reject_record_main;
         END;

         IF LENGTH (TRIM (v_filebuffer)) = 0
         THEN
            v_errmsg := 'No Record Found At Line no' || v_record_numb;
            RAISE exp_reject_loop_record;
         END IF;

         IF regexp_count (v_filebuffer, '[|]', 1) <> 77
         THEN
            --prm_errmsg :=
            v_errmsg :=v_errmsg || '--' ||'Invalid number of columns at record no ' || v_record_numb;  --Modified by Pankaj S. on 05_Jully_2013
            RAISE exp_reject_loop_record;
         END IF;

         BEGIN
            v_error_flag := 28;
            v_length_check :=
               TRIM ((SUBSTR (v_filebuffer,
                              INSTR (v_filebuffer, '|', 1, 27) + 1,
                                (INSTR (v_filebuffer, '|', 1, 28) - 1
                                )
                              - INSTR (v_filebuffer, '|', 1, 27)
                             )
                     )
                    );

            IF v_length_check IS NOT NULL
            THEN
               IF LENGTH (v_length_check) NOT IN ('13', '16', '19')
               THEN
                  v_errmsg :=
                             v_errmsg || '--' || 'Invalid card number length';
               ELSE
                  BEGIN
                     v_dum := 0;

                     SELECT 1
                       INTO v_dum
                       FROM cms_appl_pan
                      WHERE cap_inst_code = prm_instcode
                        AND cap_pan_code = gethash (v_length_check);

                     IF v_dum = 1
                     THEN
                        v_errmsg :=
                           v_errmsg || '--' || 'Card Already Present in CMS ';
                           v_card_no_already_present := v_length_check;
                     END IF;
                  EXCEPTION
                     WHEN NO_DATA_FOUND
                     THEN
                        v_errmsg := 'OK';
                     WHEN OTHERS
                     THEN
                        v_errmsg :=
                              v_errmsg
                           || '--'
                           || 'Error while Searching For card '
                           || v_card_number
                           || ' as -'
                           || SUBSTR (SQLERRM, 1, 100);
                  END;
               END IF;
            ELSE
               v_errmsg := v_errmsg || '--' || 'Card Number is NULL ';
            END IF;

            IF v_length_check IS NOT NULL
            THEN
               BEGIN
                  v_numchk := TO_NUMBER (v_length_check);
               EXCEPTION
                  WHEN OTHERS
                  THEN
                     v_errmsg :=
                           v_errmsg
                        || '--'
                        || 'Numberic value expected for card number ';
               END;
            END IF;

            v_card_number := v_length_check;
         EXCEPTION
            WHEN OTHERS
            THEN
               v_errmsg :=
                          v_errmsg || '--' || 'card number validation failed';
               v_sqlerr :=
                     v_sqlerr
                  || ' -- '
                  || 'Data validation failed for field no '
                  || v_error_flag
                  || ' with tech error '
                  || SUBSTR (SQLERRM, 1, 100);
         END;

         BEGIN
            v_error_flag := 29;
            v_length_check :=
               TRIM ((SUBSTR (v_filebuffer,
                              INSTR (v_filebuffer, '|', 1, 28) + 1,
                                (INSTR (v_filebuffer, '|', 1, 29) - 1
                                )
                              - INSTR (v_filebuffer, '|', 1, 28)
                             )
                     )
                    );

            IF v_length_check IS NULL
            THEN
               v_errmsg := v_errmsg || '--' || 'Card Status is NULL ';
            END IF;

            IF v_length_check IS NOT NULL AND LENGTH (v_length_check) > 2
            THEN
               v_errmsg :=
                          v_errmsg || '--' || 'Card Status length is invalid';
            ELSE
               /*----- Card Status -------*/
               v_card_stat := v_length_check;
            /*----- Card Status -------*/
            END IF;

            IF v_length_check IS NOT NULL
            THEN
               BEGIN
                  v_numchk := TO_NUMBER (v_length_check);
               EXCEPTION
                  WHEN OTHERS
                  THEN
                     v_errmsg :=
                           v_errmsg
                        || '--'
                        || 'Numberic value expected for card status ';
               END;
            END IF;
         EXCEPTION
            WHEN OTHERS
            THEN
               v_errmsg :=
                          v_errmsg || '--' || 'card status validation failed';
               v_sqlerr :=
                     v_sqlerr
                  || ' -- '
                  || 'Data validation failed for field no '
                  || v_error_flag
                  || ' with tech error '
                  || SUBSTR (SQLERRM, 1, 100);
         END;

         BEGIN
            v_error_flag := 31;
            v_length_check :=
               TRIM ((SUBSTR (v_filebuffer,
                              INSTR (v_filebuffer, '|', 1, 30) + 1,
                                (INSTR (v_filebuffer, '|', 1, 31) - 1
                                )
                              - INSTR (v_filebuffer, '|', 1, 30)
                             )
                     )
                    );

            IF v_length_check IS NULL
            THEN
               v_errmsg := v_errmsg || '--' || 'Starter Card Flag is NULL ';
            END IF;

            IF v_length_check IS NOT NULL AND LENGTH (v_length_check) > 1
            THEN
               v_errmsg :=
                    v_errmsg || '--' || 'Starter card flag length is invalid';
            ELSE
               /*-----Starter Card Flag-------*/
               v_starter_card_flag := v_length_check;
            /*-----Starter Card Flag-------*/
            END IF;

            --Sn Modified by Pankaj S. on 04_Jully_2013
            IF v_length_check IS NOT NULL
            THEN
               BEGIN
                  v_numchk := TO_NUMBER (v_length_check);
               EXCEPTION
                  WHEN OTHERS
                  THEN
                     v_errmsg :=
                           v_errmsg
                        || '--'
                        || ' Starter card flag value should be numeric';
               END;


                IF NVL (v_length_check, '9') NOT IN ('0', '1')
                THEN
                   v_errmsg :=
                        v_errmsg || '--' || 'invalid value for Starter card flag';
                END IF;
            END IF;
            --En Modified by Pankaj S. on 04_Jully_2013
         EXCEPTION
            WHEN OTHERS
            THEN
               v_errmsg :=
                    v_errmsg || '--' || 'Starter Card Flag validation failed';
               v_sqlerr :=
                     v_sqlerr
                  || ' -- '
                  || 'Data validation failed for field no '
                  || v_error_flag
                  || ' with tech error '
                  || SUBSTR (SQLERRM, 1, 100);
         END;

         BEGIN
            v_error_flag := 1;
            v_length_check :=
               TRIM ((SUBSTR (v_filebuffer, 1,
                              INSTR (v_filebuffer, '|', 1) - 1)
                     )
                    );
           /* -- 131025 sachin 
            IF v_length_check IS NULL
            THEN
               v_errmsg := v_errmsg || '--' || 'Cardholder Title is NULL ';
            END IF;
            */
            IF v_length_check IS NOT NULL
            THEN
               IF LENGTH (v_length_check) > 1
               THEN
                  v_errmsg :=
                     v_errmsg || '--' || 'Cardholder Title length is invalid';
               ELSE
                  /*----- Title-------*/
                  v_title := v_length_check;
               /*----- Title-------*/
               END IF;
                
               
                IF v_length_check IS NOT NULL then
                
              --Sn added by Pankaj S. on 04_Jully_2013
               BEGIN
                  v_numchk := TO_NUMBER (v_length_check);
               EXCEPTION
                  WHEN OTHERS
                  THEN
                     v_errmsg :=v_errmsg|| '--'|| ' Cardholder Title value should be numeric';
               END;
               --En added by Pankaj S. on 04_Jully_2013

               IF v_length_check NOT IN ('0', '1', '2', '3','4')
               THEN
                  v_errmsg := v_errmsg || '--' || 'Invalid Cardholder Title ';
               END IF;
               
               end if;
            END IF;
         EXCEPTION
            WHEN OTHERS
            THEN
               v_errmsg :=
                     v_errmsg || '--' || 'Cardholder Title validation failed';
               v_sqlerr :=
                     v_sqlerr
                  || ' -- '
                  || 'Data validation failed for field no '
                  || v_error_flag
                  || ' with tech error '
                  || SUBSTR (SQLERRM, 1, 100);
         END;

         BEGIN
            v_error_flag := 2;
            v_length_check :=
               TRIM ((SUBSTR (v_filebuffer,
                              INSTR (v_filebuffer, '|', 1) + 1,
                                (INSTR (v_filebuffer, '|', 1, 2) - 1
                                )
                              - INSTR (v_filebuffer, '|', 1)
                             )
                     )
                    );

            IF v_length_check IS NULL
            THEN
               v_errmsg :=
                    v_errmsg || '--' || 'FIRST NAME OF THE CUSTOMER IS NULL ';
            END IF;

            IF v_length_check IS NOT NULL AND LENGTH (v_length_check) > 40
            THEN
               v_errmsg := v_errmsg || '--' || 'First name length is invalid';
            ELSE
               /*----- First Name -------*/
               v_first_name := v_length_check;
            /*----- First Name -------*/
            END IF;
         EXCEPTION
            WHEN OTHERS
            THEN
               v_errmsg := v_errmsg || '--' || 'First name validation failed';
               v_sqlerr :=
                     v_sqlerr
                  || ' -- '
                  || 'Data validation failed for field no '
                  || v_error_flag
                  || ' with tech error '
                  || SUBSTR (SQLERRM, 1, 100);
         END;

         BEGIN
            v_error_flag := 3;
            v_length_check :=
               TRIM ((SUBSTR (v_filebuffer,
                              INSTR (v_filebuffer, '|', 1, 2) + 1,
                                (INSTR (v_filebuffer, '|', 1, 3) - 1
                                )
                              - INSTR (v_filebuffer, '|', 1, 2)
                             )
                     )
                    );

            IF v_length_check IS NOT NULL AND LENGTH (v_length_check) > 40
            THEN
               v_errmsg := v_errmsg || '--' || 'Last name length is invalid';
            ELSE
               /*----- Last Name -------*/
               v_last_name := v_length_check;
            /*----- Last Name -------*/
            END IF;
         EXCEPTION
            WHEN OTHERS
            THEN
               v_errmsg := v_errmsg || '--' || 'Last name validation failed';
               v_sqlerr :=
                     v_sqlerr
                  || ' -- '
                  || 'Data validation failed for field no '
                  || v_error_flag
                  || ' with tech error '
                  || SUBSTR (SQLERRM, 1, 100);
         END;

         BEGIN
            v_error_flag := 72;
            v_length_check :=
               TRIM ((SUBSTR (v_filebuffer,
                              INSTR (v_filebuffer, '|', 1, 71) + 1,
                                (INSTR (v_filebuffer, '|', 1, 72) - 1
                                )
                              - INSTR (v_filebuffer, '|', 1, 71)
                             )
                     )
                    );

            IF v_length_check IS NULL
            THEN
               IF v_starter_card_flag = '1'
               THEN
                  v_errmsg := v_errmsg || '--' || 'ID type is NULL';
               END IF;
            ELSE
               IF LENGTH (v_length_check) > 5
               THEN
                  v_errmsg := v_errmsg || '--' || 'ID type length is invalid';
               ELSE
                  /*-----ID Type------*/
                  v_id_type := v_length_check;
               /*-----ID Type------*/
               END IF;
            END IF;
         EXCEPTION
            WHEN OTHERS
            THEN
               v_errmsg := v_errmsg || '--' || 'ID type validation failed';
               v_sqlerr :=
                     v_sqlerr
                  || ' -- '
                  || 'Data validation failed for field no '
                  || v_error_flag
                  || ' with tech error '
                  || SUBSTR (SQLERRM, 1, 100);
         END;

         BEGIN
            v_error_flag := 4;
            v_length_check :=
               TRIM ((SUBSTR (v_filebuffer,
                              INSTR (v_filebuffer, '|', 1, 3) + 1,
                                (INSTR (v_filebuffer, '|', 1, 4) - 1
                                )
                              - INSTR (v_filebuffer, '|', 1, 3)
                             )
                     )
                    );

            IF v_length_check IS NULL AND v_starter_card_flag = '1'
            THEN
               v_errmsg := v_errmsg || '--' || 'SSN OF THE CUSTOMER IS NULL ';
            END IF;

            IF v_length_check IS NOT NULL  -- AND LENGTH (v_length_check) > 40
            THEN
               IF length(v_length_check) > 40
               THEN
                  v_errmsg := v_errmsg || '--' || 'SSN length is invalid';
               ELSE
                  /*----- SSN-------*/
                  v_ssn := v_length_check;
               /*----- SSN-------*/
               END IF;
            END IF;
         EXCEPTION
            WHEN OTHERS
            THEN
               v_errmsg := v_errmsg || '--' || 'SSN validation failed';
               v_sqlerr :=
                     v_sqlerr
                  || ' -- '
                  || 'Data validation failed for field no '
                  || v_error_flag
                  || ' with tech error '
                  || SUBSTR (SQLERRM, 1, 100);
         END;

         BEGIN
            v_error_flag := 5;
            v_length_check :=
               TRIM ((SUBSTR (v_filebuffer,
                              INSTR (v_filebuffer, '|', 1, 4) + 1,
                                (INSTR (v_filebuffer, '|', 1, 5) - 1
                                )
                              - INSTR (v_filebuffer, '|', 1, 4)
                             )
                     )
                    );

            IF v_length_check IS NULL
            THEN
               --SN:Modified for Galileo changes //Default value of $22 to be used for initial topup amount
               --v_errmsg :=v_errmsg || '--' || 'Initial Top Up amount is NULL ';
               v_length_check:='22';
               --EN:Modified for Galileo changes //Default value of $22 to be used for initial topup amount
            END IF;

            IF v_length_check IS NOT NULL AND LENGTH (v_length_check) > 10
            THEN
               v_errmsg :=
                  v_errmsg || '--'
                  || 'Initial Top Up amount length is invalid';
            ELSE
               /*----- Initial TopUp Amount-------*/
               v_init_topup_amt := v_length_check;
            /*----- Initial TopUp Amount-------*/
            END IF;

            IF v_length_check IS NOT NULL
            THEN
               BEGIN
                  v_numchk := TO_NUMBER (v_length_check);
               EXCEPTION
                  WHEN OTHERS
                  THEN
                     v_errmsg :=
                           v_errmsg
                        || '--'
                        || 'Numberic value expected for top up amount ';
               END;

               BEGIN
                  v_numchk :=
                            TO_NUMBER (v_length_check, 999999999999999999.99);
               EXCEPTION
                  WHEN OTHERS
                  THEN
                     v_errmsg :=
                           v_errmsg
                        || '--'
                        || 'Top up amount value is expected upto maximum two decimal points ';
               END;
            END IF;
         EXCEPTION
            WHEN OTHERS
            THEN
               v_errmsg :=
                  v_errmsg || '--'
                  || 'Initial Top Up amount validation failed';
               v_sqlerr :=
                     v_sqlerr
                  || ' -- '
                  || 'Data validation failed for field no '
                  || v_error_flag
                  || ' with tech error '
                  || SUBSTR (SQLERRM, 1, 100);
         END;

         BEGIN
            v_error_flag := 6;
            v_length_check :=
               TRIM ((SUBSTR (v_filebuffer,
                              INSTR (v_filebuffer, '|', 1, 5) + 1,
                                (INSTR (v_filebuffer, '|', 1, 6) - 1
                                )
                              - INSTR (v_filebuffer, '|', 1, 5)
                             )
                     )
                    );

            IF v_length_check IS NULL
            THEN
               --SN:Modified for Galileo changes //Default value of 19000101 to be used for DOB
               --v_errmsg :=v_errmsg || '--' || 'Birth Date For The Customer Is Null ';
               v_length_check:='19000101';
               --EN:Modified for Galileo changes //Default value of 19000101 to be used for DOB
            END IF;

            IF v_length_check IS NOT NULL AND LENGTH (v_length_check) > 8
            THEN
               v_errmsg := v_errmsg || '--' || 'Birth Date length is invalid';
            ELSE
               /*----- Initial TopUp Amount-------*/
               v_birth_date := v_length_check;
            /*----- Initial TopUp Amount-------*/
            END IF;

            IF v_length_check IS NOT NULL
            THEN
               BEGIN
                  v_datechk := TO_DATE (v_length_check, 'YYYYMMDD');
               EXCEPTION
                  WHEN OTHERS
                  THEN
                     v_errmsg :=
                           v_errmsg
                        || '--'
                        || 'Birth date is expected in YYYYMMDD format ';
               END;
            END IF;
         EXCEPTION
            WHEN OTHERS
            THEN
               v_errmsg := v_errmsg || '--' || 'Birth Date validation failed';
               v_sqlerr :=
                     v_sqlerr
                  || ' -- '
                  || 'Data validation failed for field no '
                  || v_error_flag
                  || ' with tech error '
                  || SUBSTR (SQLERRM, 1, 100);
         END;

         BEGIN
            v_error_flag := 7;
            v_length_check :=
               TRIM ((SUBSTR (v_filebuffer,
                              INSTR (v_filebuffer, '|', 1, 6) + 1,
                                (INSTR (v_filebuffer, '|', 1, 7) - 1
                                )
                              - INSTR (v_filebuffer, '|', 1, 6)
                             )
                     )
                    );

            IF v_length_check IS NULL
            THEN
               v_errmsg :=
                      v_errmsg || '--' || 'Permanant Address line 1 IS NULL ';
            END IF;

            IF v_length_check IS NOT NULL AND LENGTH (v_length_check) > 50
            THEN
               v_errmsg :=
                       v_errmsg || '--' || 'Permanant address-1 length is invalid';
            ELSE
               /*----- Permanent Address Line1-------*/
               v_perm_addr_line1 := v_length_check;
            /*----- Permanent Address Line1-------*/
            END IF;
         EXCEPTION
            WHEN OTHERS
            THEN
               v_errmsg :=
                     v_errmsg
                  || '--'
                  || 'Permanant Address line 1 validation failed';
               v_sqlerr :=
                     v_sqlerr
                  || ' -- '
                  || 'Data validation failed for field no '
                  || v_error_flag
                  || ' with tech error '
                  || SUBSTR (SQLERRM, 1, 100);
         END;

         --En Added by Pankaj S. for length validation
         BEGIN
            v_error_flag := 8;
            v_length_check :=
               TRIM ((SUBSTR (v_filebuffer,
                              INSTR (v_filebuffer, '|', 1, 7) + 1,
                                (INSTR (v_filebuffer, '|', 1, 8) - 1
                                )
                              - INSTR (v_filebuffer, '|', 1, 7)
                             )
                     )
                    );

            IF v_length_check IS NOT NULL AND LENGTH (v_length_check) > 50
            THEN
               v_errmsg :=
                       v_errmsg || '--' || 'Permanant address-2 length is invalid';
            ELSE
               /*----- Permanent Address Line2-------*/
               v_perm_addr_line2 := v_length_check;
            /*----- Permanent Address Line2-------*/
            END IF;
         EXCEPTION
            WHEN OTHERS
            THEN
               v_errmsg :=
                     v_errmsg
                  || '--'
                  || 'Permanant Address line 2 validation failed';
               v_sqlerr :=
                     v_sqlerr
                  || ' -- '
                  || 'Data validation failed for field no '
                  || v_error_flag
                  || ' with tech error '
                  || SUBSTR (SQLERRM, 1, 100);
         END;

         BEGIN
            v_error_flag := 9;
            v_length_check :=
               TRIM ((SUBSTR (v_filebuffer,
                              INSTR (v_filebuffer, '|', 1, 8) + 1,
                                (INSTR (v_filebuffer, '|', 1, 9) - 1
                                )
                              - INSTR (v_filebuffer, '|', 1, 8)
                             )
                     )
                    );

            IF v_length_check IS NULL
            THEN
               v_errmsg :=
                        v_errmsg || '--' || 'Permanant Address City IS NULL ';
            END IF;

            IF v_length_check IS NOT NULL AND LENGTH (v_length_check) > 40
            THEN
               v_errmsg := v_errmsg || '--' || 'Permanant city length is invalid';
            ELSE
               /*----- Permanent Address City-------*/
               v_perm_addr_city := v_length_check;
            /*----- Permanent Address City------*/
            END IF;
         EXCEPTION
            WHEN OTHERS
            THEN
               v_errmsg :=
                     v_errmsg
                  || '--'
                  || 'Permanant Address City validation failed';
               v_sqlerr :=
                     v_sqlerr
                  || ' -- '
                  || 'Data validation failed for field no '
                  || v_error_flag
                  || ' with tech error '
                  || SUBSTR (SQLERRM, 1, 100);
         END;

         BEGIN
            v_error_flag := 10;
            v_length_check :=
               TRIM ((SUBSTR (v_filebuffer,
                              INSTR (v_filebuffer, '|', 1, 9) + 1,
                                (INSTR (v_filebuffer, '|', 1, 10) - 1
                                )
                              - INSTR (v_filebuffer, '|', 1, 9)
                             )
                     )
                    );

            IF v_length_check IS NULL
            THEN
               v_errmsg :=
                  v_errmsg || '--' || 'Permanant Address State code IS NULL ';
            END IF;

            IF v_length_check IS NOT NULL AND LENGTH (v_length_check) > 3
            THEN
               v_errmsg :=
                      v_errmsg || '--' || 'Permanant state code length is invalid';
            ELSE
               IF REGEXP_LIKE (v_length_check, '[0-9]')
               THEN
                  v_errmsg :=
                        v_errmsg
                     || '--'
                     || 'perm state code expects character value only';
               ELSE
                  /*----- Permanent Address State------*/
                  v_perm_addr_state_code := v_length_check;
               /*----- Permanent Address State------*/
               END IF;
            END IF;
         EXCEPTION
            WHEN OTHERS
            THEN
               v_errmsg :=
                     v_errmsg
                  || '--'
                  || 'Permanant Address State code validation failed';
               v_sqlerr :=
                     v_sqlerr
                  || ' -- '
                  || 'Data validation failed for field no '
                  || v_error_flag
                  || ' with tech error '
                  || SUBSTR (SQLERRM, 1, 100);
         END;

         BEGIN
            v_error_flag := 11;
            v_length_check :=
               TRIM ((SUBSTR (v_filebuffer,
                              INSTR (v_filebuffer, '|', 1, 10) + 1,
                                (INSTR (v_filebuffer, '|', 1, 11) - 1
                                )
                              - INSTR (v_filebuffer, '|', 1, 10)
                             )
                     )
                    );

            IF TRIM (v_length_check) IS NULL
            THEN
               v_errmsg :=
                  v_errmsg || '--'
                  || 'Permanant Address Country code IS NULL ';
            END IF;

            IF v_length_check IS NOT NULL AND LENGTH (v_length_check) > 50 --changed to 50 from 3 during galileo migration changes
            THEN
               v_errmsg :=
                    v_errmsg || '--' || 'Permanant country code length is invalid';
            ELSE
               IF REGEXP_LIKE (v_length_check, '[0-9]')
               THEN
                  v_errmsg :=
                        v_errmsg
                     || '--'
                     || 'Permanant country code expects character value only';
               ELSE
                  /*----- Permanent Address Country-------*/
                  v_perm_addr_cntry_code := v_length_check;
               /*----- Permanent Address Country-------*/
               END IF;
            END IF;
         EXCEPTION
            WHEN OTHERS
            THEN
               v_errmsg :=
                     v_errmsg
                  || '--'
                  || 'Permanant Address country code validation failed';
               v_sqlerr :=
                     v_sqlerr
                  || ' -- '
                  || 'Data validation failed for field no '
                  || v_error_flag
                  || ' with tech error '
                  || SUBSTR (SQLERRM, 1, 100);
         END;

         BEGIN
            v_error_flag := 12;
            v_length_check :=
               TRIM ((SUBSTR (v_filebuffer,
                              INSTR (v_filebuffer, '|', 1, 11) + 1,
                                (INSTR (v_filebuffer, '|', 1, 12) - 1
                                )
                              - INSTR (v_filebuffer, '|', 1, 11)
                             )
                     )
                    );

            IF v_length_check IS NULL
            THEN
               v_errmsg :=
                  v_errmsg || '--'
                  || 'Permanant Address Postal code IS NULL ';
            END IF;

            IF     v_length_check IS NOT NULL
               AND LENGTH (TRIM (v_length_check)) > 15
            THEN
               v_errmsg :=
                     v_errmsg || '--' || 'Permanant postal code length is invalid';
            ELSE
               /*----- Permanent Address Postal Code-------*/
               v_perm_addr_postal_code := v_length_check;
            /*----- Permanent Address Postal Code-------*/
            END IF;
         EXCEPTION
            WHEN OTHERS
            THEN
               v_errmsg :=
                     v_errmsg
                  || '--'
                  || 'Permanant Address Postal code validation failed';
               v_sqlerr :=
                     v_sqlerr
                  || ' -- '
                  || 'Data validation failed for field no '
                  || v_error_flag
                  || ' with tech error '
                  || SUBSTR (SQLERRM, 1, 100);
         END;

         BEGIN
            v_error_flag := 13;
            v_length_check :=
               TRIM ((SUBSTR (v_filebuffer,
                              INSTR (v_filebuffer, '|', 1, 12) + 1,
                                (INSTR (v_filebuffer, '|', 1, 13) - 1
                                )
                              - INSTR (v_filebuffer, '|', 1, 12)
                             )
                     )
                    );

            IF v_length_check IS NOT NULL AND LENGTH (v_length_check) > 20
            -- As per disscussion earlier its 40
            THEN
               v_errmsg :=
                        v_errmsg || '--' || 'Permanant phone no length is invalid';
            ELSE
               IF REGEXP_LIKE (v_length_check, '[A-Z,a-z]')
               THEN
                  v_errmsg :=
                        v_errmsg
                     || '--'
                     || 'Permanant phone no should not contain characters ';
               ELSE
                  /*----- Permanent Address Phone-------*/
                  v_perm_addr_phone := v_length_check;
               /*----- Permanent Address Phone-------*/
               END IF;
            END IF;
         EXCEPTION
            WHEN OTHERS
            THEN
               v_errmsg :=
                     v_errmsg
                  || '--'
                  || 'Permanant Address phone validation failed';
               v_sqlerr :=
                     v_sqlerr
                  || ' -- '
                  || 'Data validation failed for field no '
                  || v_error_flag
                  || ' with tech error '
                  || SUBSTR (SQLERRM, 1, 100);
         END;

         BEGIN
            v_error_flag := 14;
            v_length_check :=
               TRIM ((SUBSTR (v_filebuffer,
                              INSTR (v_filebuffer, '|', 1, 13) + 1,
                                (INSTR (v_filebuffer, '|', 1, 14) - 1
                                )
                              - INSTR (v_filebuffer, '|', 1, 13)
                             )
                     )
                    );

            IF v_length_check IS NOT NULL AND LENGTH (v_length_check) > 20
            THEN
               v_errmsg :=
                       v_errmsg || '--' || 'Permanant mobile no length is invalid';
            ELSE
               IF REGEXP_LIKE (v_length_check, '[A-Z,a-z]')
               THEN
                  v_errmsg :=
                        v_errmsg
                     || '--'
                     || 'Permanant mobile no should not contain characters ';
               ELSE
                  /*----- Permanent Mobile-------*/
                  v_perm_addr_mobile := v_length_check;
               /*----- Permanent Mobile-------*/
               END IF;
            END IF;
         EXCEPTION
            WHEN OTHERS
            THEN
               v_errmsg :=
                     v_errmsg
                  || '--'
                  || 'Permanant Address mobile validation failed';
               v_sqlerr :=
                     v_sqlerr
                  || ' -- '
                  || 'Data validation failed for field no '
                  || v_error_flag
                  || ' with tech error '
                  || SUBSTR (SQLERRM, 1, 100);
         END;

         BEGIN
            v_error_flag := 15;
            v_length_check :=
               TRIM ((SUBSTR (v_filebuffer,
                              INSTR (v_filebuffer, '|', 1, 14) + 1,
                                (INSTR (v_filebuffer, '|', 1, 15) - 1
                                )
                              - INSTR (v_filebuffer, '|', 1, 14)
                             )
                     )
                    );

            /* mandotory in case of GPR */
            --SN:Modified for Galileo changes //To mark mailing address as optional
            /*IF v_starter_card_flag = '1' AND v_length_check IS NULL
            THEN
               v_errmsg := v_errmsg || '--' || 'Mailing address-1 is NULL';
            END IF;*/
            --EN:Modified for Galileo changes //Default value of $22 to be used for initial topup amount            

            /* mandotory in case of GPR */
            IF v_length_check IS NOT NULL AND LENGTH (v_length_check) > 50
            THEN
               v_errmsg :=
                    v_errmsg || '--' || 'Mailing address-1 length is invalid';
            ELSE
               /*-----Mailing address Line1------*/
               v_mail_addr_line1 := v_length_check;
            /*-----Mailing address Line1------*/
            END IF;
         EXCEPTION
            WHEN OTHERS
            THEN
               v_errmsg :=
                    v_errmsg || '--' || 'Mailing address-1 validation failed';
               v_sqlerr :=
                     v_sqlerr
                  || ' -- '
                  || 'Data validation failed for field no '
                  || v_error_flag
                  || ' with tech error '
                  || SUBSTR (SQLERRM, 1, 100);
         END;

         BEGIN
            v_error_flag := 16;
            v_length_check :=
               TRIM ((SUBSTR (v_filebuffer,
                              INSTR (v_filebuffer, '|', 1, 15) + 1,
                                (INSTR (v_filebuffer, '|', 1, 16) - 1
                                )
                              - INSTR (v_filebuffer, '|', 1, 15)
                             )
                     )
                    );

           /* -- As discuused we have commented below validation on 16-sep-2013

            IF v_starter_card_flag = '1' AND v_length_check IS NULL
            THEN
               v_errmsg := v_errmsg || '--' || 'Mailing address-2 is NULL';
            END IF;

           */ -- As discuused we have commented below validation on 16-sep-2013

            IF v_length_check IS NOT NULL AND LENGTH (v_length_check) > 50
            THEN
               v_errmsg :=
                    v_errmsg || '--' || 'Mailing address-2 length is invalid';
            ELSE
               /*-----Mailing address Line2------*/
               v_mail_addr_line2 := v_length_check;
            /*-----Mailing address Line2------*/
            END IF;
         EXCEPTION
            WHEN OTHERS
            THEN
               v_errmsg :=
                    v_errmsg || '--' || 'Mailing address-2 validation failed';
               v_sqlerr :=
                     v_sqlerr
                  || ' -- '
                  || 'Data validation failed for field no '
                  || v_error_flag
                  || ' with tech error '
                  || SUBSTR (SQLERRM, 1, 100);
         END;

         BEGIN
            v_error_flag := 17;
            v_length_check :=
               TRIM ((SUBSTR (v_filebuffer,
                              INSTR (v_filebuffer, '|', 1, 16) + 1,
                                (INSTR (v_filebuffer, '|', 1, 17) - 1
                                )
                              - INSTR (v_filebuffer, '|', 1, 16)
                             )
                     )
                    );

            --SN:Modified for Galileo changes //To mark mailing address as optional
            /*IF v_starter_card_flag = '1' AND v_length_check IS NULL
            THEN
               v_errmsg := v_errmsg || '--' || 'Mailing address city is NULL';
            END IF;*/
            --EN:Modified for Galileo changes //To mark mailing address as optional

            IF v_length_check IS NOT NULL AND LENGTH (v_length_check) > 40
            THEN
               v_errmsg :=
                         v_errmsg || '--' || 'Mailing address city length is invalid';
            ELSE
               /*-----Mailing address City------*/
               v_mail_addr_city := v_length_check;
            /*-----Mailing address City------*/
            END IF;
         EXCEPTION
            WHEN OTHERS
            THEN
               v_errmsg :=
                  v_errmsg || '--'
                  || 'Mailing address city validation failed';
               v_sqlerr :=
                     v_sqlerr
                  || ' -- '
                  || 'Data validation failed for field no '
                  || v_error_flag
                  || ' with tech error '
                  || SUBSTR (SQLERRM, 1, 100);
         END;

         BEGIN
            v_error_flag := 18;
            v_length_check :=
               TRIM ((SUBSTR (v_filebuffer,
                              INSTR (v_filebuffer, '|', 1, 17) + 1,
                                (INSTR (v_filebuffer, '|', 1, 18) - 1
                                )
                              - INSTR (v_filebuffer, '|', 1, 17)
                             )
                     )
                    );

            --SN:Modified for Galileo changes //To mark mailing address as optional
            /*IF v_starter_card_flag = '1' AND v_length_check IS NULL
            THEN
               v_errmsg :=
                     v_errmsg || '--' || 'Mailing address state code is NULL';
            END IF;*/
            --EN:Modified for Galileo changes //To mark mailing address as optional

            IF v_length_check IS NOT NULL
               AND LENGTH (TRIM (v_length_check)) > 3
            THEN
               v_errmsg :=
                   v_errmsg || '--' || 'Mailing state code length is invalid';
            ELSE
               IF REGEXP_LIKE (v_length_check, '[0-9]')
               THEN
                  v_errmsg :=
                        v_errmsg
                     || '--'
                     || 'mailing state code expects character value only';
               ELSE
                  /*-----Mailing address State------*/
                  v_mail_addr_state_code := v_length_check;
               /*-----Mailing address State------*/
               END IF;
            END IF;
         EXCEPTION
            WHEN OTHERS
            THEN
               v_errmsg :=
                     v_errmsg
                  || '--'
                  || 'Mailing address state code validation failed';
               v_sqlerr :=
                     v_sqlerr
                  || ' -- '
                  || 'Data validation failed for field no '
                  || v_error_flag
                  || ' with tech error '
                  || SUBSTR (SQLERRM, 1, 100);
         END;

         BEGIN
            v_error_flag := 19;
            v_length_check :=
               TRIM ((SUBSTR (v_filebuffer,
                              INSTR (v_filebuffer, '|', 1, 18) + 1,
                                (INSTR (v_filebuffer, '|', 1, 19) - 1
                                )
                              - INSTR (v_filebuffer, '|', 1, 18)
                             )
                     )
                    );

            --SN:Modified for Galileo changes //To mark mailing address as optional
            /*IF v_starter_card_flag = '1' AND v_length_check IS NULL
            THEN
               v_errmsg :=
                   v_errmsg || '--' || 'Mailing address country code is NULL';
            END IF;*/
			--EN:Modified for Galileo changes //To mark mailing address as optional

            /*
            its mandotory only in case of GPR

            IF v_length_check IS NULL
             THEN
                v_errmsg := v_errmsg || '--' || 'Mailing country code is NULL';
             END IF ;
             */
            IF v_length_check IS NOT NULL
               AND LENGTH (TRIM (v_length_check)) > 50 --changed to 50 from 3 during galileo migration changes
            THEN
               v_errmsg :=
                  v_errmsg || '--'
                  || 'Mailing country code length is invalid';
            ELSE
               IF REGEXP_LIKE (v_length_check, '[0-9]')
               THEN
                  v_errmsg :=
                        v_errmsg
                     || '--'
                     || 'mailing country code expects character value only';
               ELSE
                  /*-----Mailing address Country------*/
                  v_mail_addr_cntry_code := v_length_check;
               /*-----Mailing address Country------*/
               END IF;
            END IF;
         EXCEPTION
            WHEN OTHERS
            THEN
               v_errmsg :=
                     v_errmsg
                  || '--'
                  || 'Mailing address country code validation failed';
               v_sqlerr :=
                     v_sqlerr
                  || ' -- '
                  || 'Data validation failed for field no '
                  || v_error_flag
                  || ' with tech error '
                  || SUBSTR (SQLERRM, 1, 100);
         END;

         BEGIN
            v_error_flag := 20;
            v_length_check :=
               TRIM ((SUBSTR (v_filebuffer,
                              INSTR (v_filebuffer, '|', 1, 19) + 1,
                                (INSTR (v_filebuffer, '|', 1, 20) - 1
                                )
                              - INSTR (v_filebuffer, '|', 1, 19)
                             )
                     )
                    );

            --SN:Modified for Galileo changes //To mark mailing address as optional
            /*IF v_starter_card_flag = '1' AND v_length_check IS NULL
            THEN
               v_errmsg :=
                    v_errmsg || '--' || 'Mailing address postal code is NULL';
            END IF;*/
            --EN:Modified for Galileo changes //To mark mailing address as optional            

            IF v_length_check IS NOT NULL AND LENGTH (v_length_check) > 15
            THEN
               v_errmsg :=
                  v_errmsg || '--' || 'Mailing postal code length is invalid';
            ELSE
               /*-----Mailing address Postal Code------*/
               v_mail_addr_postal_code := v_length_check;
            /*-----Mailing address Postal Code------*/
            END IF;
         EXCEPTION
            WHEN OTHERS
            THEN
               v_errmsg :=
                     v_errmsg
                  || '--'
                  || 'Mailing address postal code validation failed';
               v_sqlerr :=
                     v_sqlerr
                  || ' -- '
                  || 'Data validation failed for field no '
                  || v_error_flag
                  || ' with tech error '
                  || SUBSTR (SQLERRM, 1, 100);
         END;

         BEGIN
            v_error_flag := 21;
            v_length_check :=
               TRIM ((SUBSTR (v_filebuffer,
                              INSTR (v_filebuffer, '|', 1, 20) + 1,
                                (INSTR (v_filebuffer, '|', 1, 21) - 1
                                )
                              - INSTR (v_filebuffer, '|', 1, 20)
                             )
                     )
                    );

           /*   -- Commented on 23-sep-2013
            IF v_starter_card_flag = '1' AND v_length_check IS NULL
            THEN
               v_errmsg :=
                       v_errmsg || '--' || 'Mailing address phone no is NULL';
            END IF;
            */  -- Commented on 23-sep-2013

            IF v_length_check IS NOT NULL AND LENGTH (v_length_check) > 40
            THEN
               v_errmsg :=
                     v_errmsg || '--' || 'Mailing phone no length is invalid';
            ELSE
               IF REGEXP_LIKE (v_length_check, '[A-Z,a-z]')
               THEN
                  v_errmsg :=
                        v_errmsg
                     || '--'
                     || 'mailing phone no should not contain characters ';
               ELSE
                  /*-----Mailing address Phone------*/
                  v_mail_addr_phone := v_length_check;
               /*-----Mailing address Phone------*/
               END IF;
            END IF;
         EXCEPTION
            WHEN OTHERS
            THEN
               v_errmsg :=
                  v_errmsg || '--'
                  || 'Mailing address phone validation failed';
               v_sqlerr :=
                     v_sqlerr
                  || ' -- '
                  || 'Data validation failed for field no '
                  || v_error_flag
                  || ' with tech error '
                  || SUBSTR (SQLERRM, 1, 100);
         END;

         BEGIN
            v_error_flag := 22;
            v_length_check :=
               TRIM ((SUBSTR (v_filebuffer,
                              INSTR (v_filebuffer, '|', 1, 21) + 1,
                                (INSTR (v_filebuffer, '|', 1, 22) - 1
                                )
                              - INSTR (v_filebuffer, '|', 1, 21)
                             )
                     )
                    );

           /*  -- Commented on 23-sep-2013
            IF v_starter_card_flag = '1' AND v_length_check IS NULL
            THEN
               v_errmsg :=
                      v_errmsg || '--' || 'Mailing address mobile no is NULL';
            END IF;
           */  -- Commented on 23-sep-2013

            IF v_length_check IS NOT NULL AND LENGTH (v_length_check) > 20
            THEN
               v_errmsg :=
                    v_errmsg || '--' || 'Mailing mobile no length is invalid';
            ELSE
               IF REGEXP_LIKE (v_length_check, '[A-Z,a-z]')
               THEN
                  v_errmsg :=
                        v_errmsg
                     || '--'
                     || 'mailing mobile no should not contain characters ';
               ELSE
                  /*-----Mailing address Mobile------*/
                  v_mail_addr_mobile := v_length_check;
               /*-----Mailing address Mobile------*/
               END IF;
            END IF;
         EXCEPTION
            WHEN OTHERS
            THEN
               v_errmsg :=
                     v_errmsg
                  || '--'
                  || 'Mailing address mobile validation failed';
               v_sqlerr :=
                     v_sqlerr
                  || ' -- '
                  || 'Data validation failed for field no '
                  || v_error_flag
                  || ' with tech error '
                  || SUBSTR (SQLERRM, 1, 100);
         END;

         BEGIN
            v_error_flag := 23;
            v_length_check :=
               TRIM ((SUBSTR (v_filebuffer,
                              INSTR (v_filebuffer, '|', 1, 22) + 1,
                                (INSTR (v_filebuffer, '|', 1, 23) - 1
                                )
                              - INSTR (v_filebuffer, '|', 1, 22)
                             )
                     )
                    );

            IF v_length_check IS NOT NULL
            THEN
               IF LENGTH (v_length_check) > 50
               THEN
                  v_errmsg := v_errmsg || '--' || 'Email length is invalid';
               ELSE
                  /*-----Email Address ------*/
                  v_email_address := v_length_check;
               /*-----Email Address ------*/
               END IF;

               SELECT DECODE (NVL (INSTR (v_length_check, '@'), 0),
                              0, 'N',
                              'Y'
                             )
                 INTO v_length_check
                 FROM DUAL;

               IF v_length_check = 'N'
               THEN
                  v_errmsg :=
                        v_errmsg
                     || '--'
                     || 'Email ID does not contain @ character ';
               END IF;
            END IF;
         EXCEPTION
            WHEN OTHERS
            THEN
               v_errmsg := v_errmsg || '--' || 'Email ID validation failed';
               v_sqlerr :=
                     v_sqlerr
                  || ' -- '
                  || 'Data validation failed for field no '
                  || v_error_flag
                  || ' with tech error '
                  || SUBSTR (SQLERRM, 1, 100);
         END;

         BEGIN
            v_error_flag := 24;
            v_length_check :=
               TRIM ((SUBSTR (v_filebuffer,
                              INSTR (v_filebuffer, '|', 1, 23) + 1,
                                (INSTR (v_filebuffer, '|', 1, 24) - 1
                                )
                              - INSTR (v_filebuffer, '|', 1, 23)
                             )
                     )
                    );

            IF v_length_check IS NULL
            THEN
               v_errmsg := v_errmsg || '--' || 'Product code IS NULL ';
            END IF;

            IF v_length_check IS NOT NULL AND LENGTH (v_length_check) > 6
            THEN
               v_errmsg :=
                         v_errmsg || '--' || 'Product code length is invalid';
            ELSE
               /*-----Product Code------*/
               v_prod_code := v_length_check;
            /*-----Product Code------*/
            END IF;
         EXCEPTION
            WHEN OTHERS
            THEN
               v_errmsg :=
                         v_errmsg || '--' || 'Product code validation failed';
               v_sqlerr :=
                     v_sqlerr
                  || ' -- '
                  || 'Data validation failed for field no '
                  || v_error_flag
                  || ' with tech error '
                  || SUBSTR (SQLERRM, 1, 100);
         END;

         BEGIN
            v_error_flag := 25;
            v_length_check :=
               TRIM ((SUBSTR (v_filebuffer,
                              INSTR (v_filebuffer, '|', 1, 24) + 1,
                                (INSTR (v_filebuffer, '|', 1, 25) - 1
                                )
                              - INSTR (v_filebuffer, '|', 1, 24)
                             )
                     )
                    );

            IF v_length_check IS NULL
            THEN
               v_errmsg :=
                         v_errmsg || '--' || 'Product catagory code IS NULL ';
            END IF;

            IF v_length_check IS NOT NULL
            THEN
               IF LENGTH (v_length_check) > 2
               THEN
                  v_errmsg :=
                     v_errmsg || '--' || 'Product category length is invalid';
               ELSE
                  /*-----Product Catagory Code------*/
                  v_prod_catg_code := v_length_check;
               /*-----Product Catagory Code------*/
               END IF;

               BEGIN
                  v_numchk := TO_NUMBER (v_length_check);
               EXCEPTION
                  WHEN OTHERS
                  THEN
                     v_errmsg :=
                           v_errmsg
                        || '--'
                        || 'Product category code should be numeric';
               END;
            END IF;
         EXCEPTION
            WHEN OTHERS
            THEN
               v_errmsg :=
                     v_errmsg || '--' || 'Product category validation failed';
               v_sqlerr :=
                     v_sqlerr
                  || ' -- '
                  || 'Data validation failed for field no '
                  || v_error_flag
                  || ' with tech error '
                  || SUBSTR (SQLERRM, 1, 100);
         END;

         BEGIN
            v_error_flag := 26;
            v_length_check :=
               TRIM ((SUBSTR (v_filebuffer,
                              INSTR (v_filebuffer, '|', 1, 25) + 1,
                                (INSTR (v_filebuffer, '|', 1, 26) - 1
                                )
                              - INSTR (v_filebuffer, '|', 1, 25)
                             )
                     )
                    );

            IF v_length_check IS NULL
            THEN
               v_errmsg := v_errmsg || '--' || 'Branch Id is NULL ';
            END IF;

            IF v_length_check IS NOT NULL AND LENGTH (v_length_check) > 6
            THEN
               v_errmsg := v_errmsg || '--' || 'Branch ID length is invalid';
            ELSE
               /*-----Branch ID------*/
               v_branch_id := v_length_check;
            /*-----Branch ID------*/
            END IF;
         EXCEPTION
            WHEN OTHERS
            THEN
               v_errmsg := v_errmsg || '--' || 'Branch ID validation failed';
               v_sqlerr :=
                     v_sqlerr
                  || ' -- '
                  || 'Data validation failed for field no '
                  || v_error_flag
                  || ' with tech error '
                  || SUBSTR (SQLERRM, 1, 100);
         END;

         BEGIN
            v_error_flag := 27;
            --v_cust_id :=     -- Commented on 20-JUN-2013 since cust id to be removed from customer file. utilised this field for newly added field merchant id
            v_length_check :=
               TRIM ((SUBSTR (v_filebuffer,
                              INSTR (v_filebuffer, '|', 1, 26) + 1,
                                (INSTR (v_filebuffer, '|', 1, 27) - 1
                                )
                              - INSTR (v_filebuffer, '|', 1, 26)
                             )
                     )
                    );

            IF v_length_check IS NOT NULL
            THEN
               IF LENGTH (v_length_check) > 15
               THEN
                  v_errmsg :=
                          v_errmsg || '--' || 'Merchant ID length is invalid';
               END IF;

               BEGIN
                  SELECT 1
                    INTO v_dum
                    FROM cms_merinv_mast
                   WHERE cmm_inst_code = prm_instcode
                     AND cmm_mer_id = v_length_check;

                  /*-----Merchant  ID------*/
                  v_merchant_id := v_length_check;
               /*-----Merchant  ID------*/
               EXCEPTION
                  WHEN NO_DATA_FOUND
                  THEN
                     v_errmsg :=
                        v_errmsg || '--' || 'merchant id not found in master';
                  WHEN OTHERS
                  THEN
                     v_errmsg :=
                           v_errmsg
                        || '--'
                        || ' error while validating merchant id with master as '
                        || SUBSTR (SQLERRM, 1, 100);
               END;

               BEGIN
                  v_numchk := TO_NUMBER (v_length_check);
               EXCEPTION
                  WHEN OTHERS
                  THEN
                     v_errmsg :=
                           v_errmsg
                        || '--'
                        || 'Numberic value expected for merchant id ';
               END;
            END IF;
         EXCEPTION
            WHEN OTHERS
            THEN
               v_errmsg :=
                          v_errmsg || '--' || 'Merchant id validation failed';
               v_sqlerr :=
                     v_sqlerr
                  || ' -- '
                  || 'Data validation failed for field no '
                  || v_error_flag
                  || ' with tech error '
                  || SUBSTR (SQLERRM, 1, 100);
         END;

         /* Commented on 19-JUN-2013 as per excel sheet

          IF v_cust_id IS NULL
          THEN
             v_errmsg := v_errmsg || '--' || 'Customer Id is NULL ';
            -- RAISE exp_reject_loop_record;
          --Sn Added by Pankaj S. for length validation
          END IF;
         */
         BEGIN
            v_error_flag := 30;
            v_length_check :=
               TRIM ((SUBSTR (v_filebuffer,
                              INSTR (v_filebuffer, '|', 1, 29) + 1,
                                (INSTR (v_filebuffer, '|', 1, 30) - 1
                                )
                              - INSTR (v_filebuffer, '|', 1, 29)
                             )
                     )
                    );

           /*                           -- Commented on 02-Aug-2013 as per discussion

            IF v_length_check IS NULL
            THEN
               v_errmsg := v_errmsg || '--' || 'Proxy Number is NULL ';
            END IF;

            */                          -- Commented on 02-Aug-2013 as per discussion

            IF v_length_check IS NOT NULL
            THEN
               IF LENGTH (v_length_check) NOT IN ('9', '12')
               THEN
                  v_errmsg :=
                         v_errmsg || '--' || 'Proxy number length is invalid';
               ELSE
                  /*-----Proxy Number ------*/
                  v_proxy_number := v_length_check;
               /*-----Proxy Number ------*/
               END IF;

               BEGIN
                  v_numchk := TO_NUMBER (v_length_check);
               EXCEPTION
                  WHEN OTHERS
                  THEN
                     v_errmsg :=
                           v_errmsg
                        || '--'
                        || 'Numberic value expected for proxy no ';
               END;
            END IF;
         EXCEPTION
            WHEN OTHERS
            THEN
               v_errmsg :=
                         v_errmsg || '--' || 'Proxy number validation failed';
               v_sqlerr :=
                     v_sqlerr
                  || ' -- '
                  || 'Data validation failed for field no '
                  || v_error_flag
                  || ' with tech error '
                  || SUBSTR (SQLERRM, 1, 100);
         END;

         BEGIN
            v_error_flag := 32;
            v_length_check :=
               TRIM ((SUBSTR (v_filebuffer,
                              INSTR (v_filebuffer, '|', 1, 31) + 1,
                                (INSTR (v_filebuffer, '|', 1, 32) - 1
                                )
                              - INSTR (v_filebuffer, '|', 1, 31)
                             )
                     )
                    );

            IF v_length_check IS NULL AND v_card_stat <> '0'
            THEN
               v_errmsg :=
                          v_errmsg || '--' || 'Card Activation Date is NULL ';
            END IF;

            IF v_length_check IS NOT NULL
            THEN
               IF LENGTH (v_length_check) > 17
               THEN
                  v_errmsg :=
                      v_errmsg || '--' || 'Activation Date length is invalid';
               ELSE
                  /*-----Activation Date------*/
                  v_active_date := v_length_check;
               /*-----Activation Date------*/
               END IF;

               BEGIN
                  v_datechk :=
                              TO_DATE (v_length_check, 'YYYYMMDD HH24:MI:SS');
               EXCEPTION
                  WHEN OTHERS
                  THEN
                     v_errmsg :=
                        v_errmsg || '--' || 'Card activation date is invalid';
               END;
            END IF;
         EXCEPTION
            WHEN OTHERS
            THEN
               v_errmsg :=
                      v_errmsg || '--' || 'Activation Date validation failed';
               v_sqlerr :=
                     v_sqlerr
                  || ' -- '
                  || 'Data validation failed for field no '
                  || v_error_flag
                  || ' with tech error '
                  || SUBSTR (SQLERRM, 1, 100);
         END;

         BEGIN
            v_error_flag := 33;
            v_length_check :=
               TRIM ((SUBSTR (v_filebuffer,
                              INSTR (v_filebuffer, '|', 1, 32) + 1,
                                (INSTR (v_filebuffer, '|', 1, 33) - 1
                                )
                              - INSTR (v_filebuffer, '|', 1, 32)
                             )
                     )
                    );

            IF v_length_check IS NULL
            THEN
               v_errmsg := v_errmsg || '--' || 'Card Expiry Date is NULL ';
            END IF;

            IF v_length_check IS NOT NULL
            THEN
               IF LENGTH (v_length_check) > 8
               THEN
                  v_errmsg :=
                          v_errmsg || '--' || 'Expiry Date length is invalid';
               ELSE
                  /*-----Expiry Date------*/
                  v_expiry_date := v_length_check;
               /*-----Expiry Date------*/
               END IF;

               BEGIN
                  v_datechk := TO_DATE (v_length_check, 'YYYYMMDD');
               EXCEPTION
                  WHEN OTHERS
                  THEN
                     v_errmsg :=
                            v_errmsg || '--' || 'Card expiry date is invalid';
               END;
            END IF;
         EXCEPTION
            WHEN OTHERS
            THEN
               v_errmsg :=
                     v_errmsg || '--' || 'Card expiry date validation failed';
               v_sqlerr :=
                     v_sqlerr
                  || ' -- '
                  || 'Data validation failed for field no '
                  || v_error_flag
                  || ' with tech error '
                  || SUBSTR (SQLERRM, 1, 100);
         END;

         BEGIN
            v_error_flag := 34;
            v_length_check :=
               TRIM ((SUBSTR (v_filebuffer,
                              INSTR (v_filebuffer, '|', 1, 33) + 1,
                                (INSTR (v_filebuffer, '|', 1, 34) - 1
                                )
                              - INSTR (v_filebuffer, '|', 1, 33)
                             )
                     )
                    );

            IF v_length_check IS NULL
            THEN
               v_errmsg :=v_errmsg || '--' || 'PAN Generation Date is NULL ';               
            END IF;

            IF v_length_check IS NOT NULL
            THEN
               IF LENGTH (v_length_check) > 17
               THEN
                  v_errmsg :=
                          v_errmsg || '--' || 'Pangen Date length is invalid';
               ELSE
                  /*-----Pan Generation Date------*/
                  v_pangen_date := v_length_check;
               /*-----Pan Generation Date------*/
               END IF;

               BEGIN
                  v_datechk :=
                              TO_DATE (v_length_check, 'YYYYMMDD HH24:MI:SS');
               EXCEPTION
                  WHEN OTHERS
                  THEN
                     v_errmsg := v_errmsg || '--' || 'Pangen date is invalid';
               END;
            END IF;
         EXCEPTION
            WHEN OTHERS
            THEN
               v_errmsg :=
                          v_errmsg || '--' || 'Pangen Date validation failed';
               v_sqlerr :=
                     v_sqlerr
                  || ' -- '
                  || 'Data validation failed for field no '
                  || v_error_flag
                  || ' with tech error '
                  || SUBSTR (SQLERRM, 1, 100);
         END;

         BEGIN
            v_error_flag := 35;
            v_length_check :=
               TRIM ((SUBSTR (v_filebuffer,
                              INSTR (v_filebuffer, '|', 1, 34) + 1,
                                (INSTR (v_filebuffer, '|', 1, 35) - 1
                                )
                              - INSTR (v_filebuffer, '|', 1, 34)
                             )
                     )
                    );

            IF v_length_check IS NOT NULL AND LENGTH (v_length_check) > 10
            THEN
               v_errmsg :=
                    v_errmsg || '--' || 'ATM Offline Limit length is invalid';
            ELSE
               /*-----ATM Offline Limit-----*/
               v_atm_offline_limit := v_length_check;
            /*-----ATM Offline Limit-----*/
            END IF;

            IF v_length_check IS NOT NULL
            THEN
               BEGIN
                  v_numchk := TO_NUMBER (v_length_check);
               EXCEPTION
                  WHEN OTHERS
                  THEN
                     v_errmsg :=
                           v_errmsg
                        || '--'
                        || 'Numberic value expected for ATM Offline Limit ';
               END;

               BEGIN
                  v_numchk := TO_NUMBER (v_length_check, 9999999999);
               EXCEPTION
                  WHEN OTHERS
                  THEN
                     v_errmsg :=
                           v_errmsg
                        || '--'
                        || 'ATM Offline Limit value should be whole number';
               END;
            END IF;
         EXCEPTION
            WHEN OTHERS
            THEN
               v_errmsg :=
                    v_errmsg || '--' || 'ATM Offline Limit validation failed';
               v_sqlerr :=
                     v_sqlerr
                  || ' -- '
                  || 'Data validation failed for field no '
                  || v_error_flag
                  || ' with tech error '
                  || SUBSTR (SQLERRM, 1, 100);
         END;

         BEGIN
            v_error_flag := 36;
            v_length_check :=
               TRIM ((SUBSTR (v_filebuffer,
                              INSTR (v_filebuffer, '|', 1, 35) + 1,
                                (INSTR (v_filebuffer, '|', 1, 36) - 1
                                )
                              - INSTR (v_filebuffer, '|', 1, 35)
                             )
                     )
                    );
                           --Sn Commented by Pankaj S. on 20_Sep_2013 to make it Non mandatory
            --            IF v_length_check IS NULL
            --            THEN
            --               v_errmsg := v_errmsg || '--' || 'ATM Online Limit is NULL ';
            --            END IF;
                          --En Commented by Pankaj S. on 20_Sep_2013 to make it Non mandatory

            IF v_length_check IS NOT NULL AND LENGTH (v_length_check) > 10
            THEN
               v_errmsg :=
                     v_errmsg || '--' || 'ATM Online Limit length is invalid';
            ELSE
               /*-----ATM Online Limit-----*/
               v_atm_online_limit := v_length_check;
            /*-----ATM Online Limit-----*/
            END IF;

            IF v_length_check IS NOT NULL
            THEN
               BEGIN
                  v_numchk := TO_NUMBER (v_length_check);
               EXCEPTION
                  WHEN OTHERS
                  THEN
                     v_errmsg :=
                           v_errmsg
                        || '--'
                        || 'Numberic value expected for ATM Online Limit ';
               END;

               BEGIN
                  v_numchk := TO_NUMBER (v_length_check, 9999999999);
               EXCEPTION
                  WHEN OTHERS
                  THEN
                     v_errmsg :=
                           v_errmsg
                        || '--'
                        || 'ATM Online Limit value should be whole number';
               END;
            END IF;
         EXCEPTION
            WHEN OTHERS
            THEN
               v_errmsg :=
                     v_errmsg || '--' || 'ATM Online Limit validation failed';
               v_sqlerr :=
                     v_sqlerr
                  || ' -- '
                  || 'Data validation failed for field no '
                  || v_error_flag
                  || ' with tech error '
                  || SUBSTR (SQLERRM, 1, 100);
         END;

         BEGIN
            v_error_flag := 37;
            v_length_check :=
               TRIM ((SUBSTR (v_filebuffer,
                              INSTR (v_filebuffer, '|', 1, 36) + 1,
                                (INSTR (v_filebuffer, '|', 1, 37) - 1
                                )
                              - INSTR (v_filebuffer, '|', 1, 36)
                             )
                     )
                    );

            IF v_length_check IS NOT NULL AND LENGTH (v_length_check) > 10
            THEN
               v_errmsg :=
                    v_errmsg || '--' || 'POS Offline Limit length is invalid';
            ELSE
               /*-----POS Offline Limit-----*/
               v_pos_offline_limit := v_length_check;
            /*-----POS Offline Limit-----*/
            END IF;

            IF v_length_check IS NOT NULL
            THEN
               BEGIN
                  v_numchk := TO_NUMBER (v_length_check);
               EXCEPTION
                  WHEN OTHERS
                  THEN
                     v_errmsg :=
                           v_errmsg
                        || '--'
                        || 'Numberic value expected for POS Offline Limit ';
               END;

               BEGIN
                  v_numchk := TO_NUMBER (v_length_check, 9999999999);
               EXCEPTION
                  WHEN OTHERS
                  THEN
                     v_errmsg :=
                           v_errmsg
                        || '--'
                        || 'POS Offline Limit value should be whole number';
               END;
            END IF;
         EXCEPTION
            WHEN OTHERS
            THEN
               v_errmsg :=
                    v_errmsg || '--' || 'POS Offline Limit validation failed';
               v_sqlerr :=
                     v_sqlerr
                  || ' -- '
                  || 'Data validation failed for field no '
                  || v_error_flag
                  || ' with tech error '
                  || SUBSTR (SQLERRM, 1, 100);
         END;

         BEGIN
            v_error_flag := 38;
            v_length_check :=
               TRIM ((SUBSTR (v_filebuffer,
                              INSTR (v_filebuffer, '|', 1, 37) + 1,
                                (INSTR (v_filebuffer, '|', 1, 38) - 1
                                )
                              - INSTR (v_filebuffer, '|', 1, 37)
                             )
                     )
                    );

           /*                           -- Commented on 02-Aug-2013 as per discussion
            IF v_length_check IS NULL
            THEN
               v_errmsg := v_errmsg || '--' || 'POS Online Limit is NULL ';
            -- RAISE exp_reject_loop_record;
            END IF;
           */                           -- Commented on 02-Aug-2013 as per discussion

            IF v_length_check IS NOT NULL AND LENGTH (v_length_check) > 10
            THEN
               v_errmsg :=
                     v_errmsg || '--' || 'POS Online Limit length is invalid';
            ELSE
               /*-----POS Online Limit-----*/
               v_pos_online_limit := v_length_check;
            /*-----POS Online Limit-----*/
            END IF;

            IF v_length_check IS NOT NULL
            THEN
               BEGIN
                  v_numchk := TO_NUMBER (v_length_check);
               EXCEPTION
                  WHEN OTHERS
                  THEN
                     v_errmsg :=
                           v_errmsg
                        || '--'
                        || 'Numberic value expected for POS Online Limit';
               END;

               BEGIN
                  v_numchk := TO_NUMBER (v_length_check, 9999999999);
               EXCEPTION
                  WHEN OTHERS
                  THEN
                     v_errmsg :=
                           v_errmsg
                        || '--'
                        || 'POS Online Limit value should be whole number';
               END;
            END IF;
         EXCEPTION
            WHEN OTHERS
            THEN
               v_errmsg :=
                     v_errmsg || '--' || 'POS Online Limit validation failed';
               v_sqlerr :=
                     v_sqlerr
                  || ' -- '
                  || 'Data validation failed for field no '
                  || v_error_flag
                  || ' with tech error '
                  || SUBSTR (SQLERRM, 1, 100);
         END;

         BEGIN
            v_error_flag := 39;
            v_length_check :=
               TRIM ((SUBSTR (v_filebuffer,
                              INSTR (v_filebuffer, '|', 1, 38) + 1,
                                (INSTR (v_filebuffer, '|', 1, 39) - 1
                                )
                              - INSTR (v_filebuffer, '|', 1, 38)
                             )
                     )
                    );

            IF v_length_check IS NOT NULL AND LENGTH (v_length_check) > 10
            THEN
               v_errmsg :=
                     v_errmsg
                  || '--'
                  || 'Offline Aggregate Limit length is invalid';
            ELSE
               /*-----Offline Aggregate Limit-----*/
               v_offline_aggr_limit := v_length_check;
            /*-----Offline Aggregate Limit-----*/
            END IF;

            IF v_length_check IS NOT NULL
            THEN
               BEGIN
                  v_numchk := TO_NUMBER (v_length_check);
               EXCEPTION
                  WHEN OTHERS
                  THEN
                     v_errmsg :=
                           v_errmsg
                        || '--'
                        || 'Numberic value expected for Offline Aggregate Limit';
               END;

               BEGIN
                  v_numchk := TO_NUMBER (v_length_check, 9999999999);
               EXCEPTION
                  WHEN OTHERS
                  THEN
                     v_errmsg :=
                           v_errmsg
                        || '--'
                        || 'Offline Aggregate Limit value should be whole number';
               END;
            END IF;
         EXCEPTION
            WHEN OTHERS
            THEN
               v_errmsg :=
                     v_errmsg
                  || '--'
                  || 'Offline Aggregate Limit validation failed';
               v_sqlerr :=
                     v_sqlerr
                  || ' -- '
                  || 'Data validation failed for field no '
                  || v_error_flag
                  || ' with tech error '
                  || SUBSTR (SQLERRM, 1, 100);
         END;

         BEGIN
            v_error_flag := 40;
            v_length_check :=
               TRIM ((SUBSTR (v_filebuffer,
                              INSTR (v_filebuffer, '|', 1, 39) + 1,
                                (INSTR (v_filebuffer, '|', 1, 40) - 1
                                )
                              - INSTR (v_filebuffer, '|', 1, 39)
                             )
                     )
                    );

           /*                               -- Commented on 02-Aug-2013 as per discussion
            IF v_length_check IS NULL
            THEN
               v_errmsg :=
                        v_errmsg || '--' || 'Online Aggregate Limit is NULL ';
            END IF;
           */                               -- Commented on 02-Aug-2013 as per discussion


            IF v_length_check IS NOT NULL AND LENGTH (v_length_check) > 10
            THEN
               v_errmsg :=
                     v_errmsg
                  || '--'
                  || 'Online Aggregate Limit length is invalid';
            ELSE
               /*-----Online Aggregate Limit-----*/
               v_online_aggr_limit := v_length_check;
            /*-----Online Aggregate Limit-----*/
            END IF;

            IF v_length_check IS NOT NULL
            THEN
               BEGIN
                  v_numchk := TO_NUMBER (v_length_check);
               EXCEPTION
                  WHEN OTHERS
                  THEN
                     v_errmsg :=
                           v_errmsg
                        || '--'
                        || 'Numberic value expected for Online Aggregate Limit';
               END;

               BEGIN
                  v_numchk := TO_NUMBER (v_length_check, 9999999999);
               EXCEPTION
                  WHEN OTHERS
                  THEN
                     v_errmsg :=
                           v_errmsg
                        || '--'
                        || 'Online Aggregate Limit value should be whole number';
               END;
            END IF;
         EXCEPTION
            WHEN OTHERS
            THEN
               v_errmsg :=
                     v_errmsg
                  || '--'
                  || 'Online Aggregate Limit validation failed';
               v_sqlerr :=
                     v_sqlerr
                  || ' -- '
                  || 'Data validation failed for field no '
                  || v_error_flag
                  || ' with tech error '
                  || SUBSTR (SQLERRM, 1, 100);
         END;

         BEGIN
            v_error_flag := 41;
            v_length_check :=
               TRIM ((SUBSTR (v_filebuffer,
                              INSTR (v_filebuffer, '|', 1, 40) + 1,
                                (INSTR (v_filebuffer, '|', 1, 41) - 1
                                )
                              - INSTR (v_filebuffer, '|', 1, 40)
                             )
                     )
                    );

           /*                               -- Commented on 02-Aug-2013 as per discussion
            IF v_length_check IS NULL
            THEN
               v_errmsg := v_errmsg || '--' || 'MMPOS Online Limit is NULL ';
            END IF;
           */                               -- Commented on 02-Aug-2013 as per discussion

            IF v_length_check IS NOT NULL AND LENGTH (v_length_check) > 10
            THEN
               v_errmsg :=
                   v_errmsg || '--' || 'MMPOS Online Limit length is invalid';
            ELSE
               /*-----MMPOS Online Limit-----*/
               v_mmpos_online_limit := v_length_check;
            /*-----MMPOS Online Limit-----*/
            END IF;

            IF v_length_check IS NOT NULL
            THEN
               BEGIN
                  v_numchk := TO_NUMBER (v_length_check);
               EXCEPTION
                  WHEN OTHERS
                  THEN
                     v_errmsg :=
                           v_errmsg
                        || '--'
                        || 'Numberic value expected for MMPOS Online Limit';
               END;

               BEGIN
                  v_numchk := TO_NUMBER (v_length_check, 9999999999);
               EXCEPTION
                  WHEN OTHERS
                  THEN
                     v_errmsg :=
                           v_errmsg
                        || '--'
                        || 'MMPOS Online Limit value should be whole number';
               END;
            END IF;
         EXCEPTION
            WHEN OTHERS
            THEN
               v_errmsg :=
                   v_errmsg || '--' || 'MMPOS Online Limit validation failed';
               v_sqlerr :=
                     v_sqlerr
                  || ' -- '
                  || 'Data validation failed for field no '
                  || v_error_flag
                  || ' with tech error '
                  || SUBSTR (SQLERRM, 1, 100);
         END;

         BEGIN
            v_error_flag := 42;
            v_length_check :=
               TRIM ((SUBSTR (v_filebuffer,
                              INSTR (v_filebuffer, '|', 1, 41) + 1,
                                (INSTR (v_filebuffer, '|', 1, 42) - 1
                                )
                              - INSTR (v_filebuffer, '|', 1, 41)
                             )
                     )
                    );

            IF v_length_check IS NOT NULL AND LENGTH (v_length_check) > 10
            THEN
               v_errmsg :=
                  v_errmsg || '--' || 'MMPOS Offline Limit length is invalid';
            ELSE
               /*-----MMPOS Offline Limit-----*/
               v_mmpos_offline_limit := v_length_check;
            /*-----MMPOS Offline Limit-----*/
            END IF;

            IF v_length_check IS NOT NULL
            THEN
               BEGIN
                  v_numchk := TO_NUMBER (v_length_check);
               EXCEPTION
                  WHEN OTHERS
                  THEN
                     v_errmsg :=
                           v_errmsg
                        || '--'
                        || 'Numberic value expected for MMPOS Offline Limit';
               END;

               BEGIN
                  v_numchk := TO_NUMBER (v_length_check, 9999999999);
               EXCEPTION
                  WHEN OTHERS
                  THEN
                     v_errmsg :=
                           v_errmsg
                        || '--'
                        || 'MMPOS Offline Limit value should be whole number';
               END;
            END IF;
         EXCEPTION
            WHEN OTHERS
            THEN
               v_errmsg :=
                  v_errmsg || '--' || 'MMPOS Offline Limit validation failed';
               v_sqlerr :=
                     v_sqlerr
                  || ' -- '
                  || 'Data validation failed for field no '
                  || v_error_flag
                  || ' with tech error '
                  || SUBSTR (SQLERRM, 1, 100);
         END;

         BEGIN
            v_error_flag := 43;
            v_length_check :=
               TRIM ((SUBSTR (v_filebuffer,
                              INSTR (v_filebuffer, '|', 1, 42) + 1,
                                (INSTR (v_filebuffer, '|', 1, 43) - 1
                                )
                              - INSTR (v_filebuffer, '|', 1, 42)
                             )
                     )
                    );

            IF v_length_check IS NULL                  --AND v_card_stat = '1'
            THEN
               v_errmsg := v_errmsg || '--' || 'PIN Offset is NULL ';
            END IF;

            IF v_length_check IS NOT NULL AND LENGTH (v_length_check) > 10
            THEN
               v_errmsg :=
                          v_errmsg || '--' || 'PIN Offset length is invalid ';
            ELSE
               /*-----PIN Offset-----*/
               v_pin_offset := v_length_check;
            /*-----PIN Offset-----*/
            END IF;
         EXCEPTION
            WHEN OTHERS
            THEN
               v_errmsg :=
                     v_errmsg || '--' || 'PIN Offset validation failed'; --Error message modified by Pankaj S. on 25-Sep-2013
               v_sqlerr :=
                     v_sqlerr
                  || ' -- '
                  || 'Data validation failed for field no '
                  || v_error_flag
                  || ' with tech error '
                  || SUBSTR (SQLERRM, 1, 100);
         END;

         BEGIN
            v_error_flag := 44;
            v_length_check :=
               TRIM ((SUBSTR (v_filebuffer,
                              INSTR (v_filebuffer, '|', 1, 43) + 1,
                                (INSTR (v_filebuffer, '|', 1, 44) - 1
                                )
                              - INSTR (v_filebuffer, '|', 1, 43)
                             )
                     )
                    );

            IF v_length_check IS NOT NULL
            THEN
               IF LENGTH (v_length_check) > 8
               THEN
                  v_errmsg :=
                      v_errmsg || '--' || 'Next Bill Date length is invalid ';
               ELSE
                  /*-----Next Bill Date----*/
                  v_next_bill_date := v_length_check;
               /*-----Next Bill Date----*/
               END IF;

               BEGIN
                  v_datechk := TO_DATE (v_length_check, 'YYYYMMDD');
               EXCEPTION
                  WHEN OTHERS
                  THEN
                     v_errmsg :=
                              v_errmsg || '--' || 'Next Bill date is invalid';
               END;
            END IF;
         EXCEPTION
            WHEN OTHERS
            THEN
               v_errmsg :=
                       v_errmsg || '--' || 'Next Bill Date validation failed';
               v_sqlerr :=
                     v_sqlerr
                  || ' -- '
                  || 'Data validation failed for field no '
                  || v_error_flag
                  || ' with tech error '
                  || SUBSTR (SQLERRM, 1, 100);
         END;

         BEGIN
            v_error_flag := 45;
            v_length_check :=
               TRIM ((SUBSTR (v_filebuffer,
                              INSTR (v_filebuffer, '|', 1, 44) + 1,
                                (INSTR (v_filebuffer, '|', 1, 45) - 1
                                )
                              - INSTR (v_filebuffer, '|', 1, 44)
                             )
                     )
                    );

            IF v_length_check IS NOT NULL
            THEN
               IF LENGTH (v_length_check) > 8
               THEN
                  v_errmsg :=
                        v_errmsg
                     || '--'
                     || 'Next Month Bill Date length is invalid ';
               ELSE
                  /*-----Next Month Bill Date----*/
                  v_next_mb_date := v_length_check;
               /*-----Next Month Bill Date----*/
               END IF;

               BEGIN
                  v_datechk := TO_DATE (v_length_check, 'YYYYMMDD');
               EXCEPTION
                  WHEN OTHERS
                  THEN
                     v_errmsg :=
                        v_errmsg || '--' || 'Next Month Bill date is invalid';
               END;
            END IF;
         EXCEPTION
            WHEN OTHERS
            THEN
               v_errmsg :=
                  v_errmsg || '--'
                  || 'Next Month Bill Date validation failed';
               v_sqlerr :=
                     v_sqlerr
                  || ' -- '
                  || 'Data validation failed for field no '
                  || v_error_flag
                  || ' with tech error '
                  || SUBSTR (SQLERRM, 1, 100);
         END;

         BEGIN
            v_error_flag := 46;
            v_length_check :=
               TRIM ((SUBSTR (v_filebuffer,
                              INSTR (v_filebuffer, '|', 1, 45) + 1,
                                (INSTR (v_filebuffer, '|', 1, 46) - 1
                                )
                              - INSTR (v_filebuffer, '|', 1, 45)
                             )
                     )
                    );

            /* IF v_length_check IS NULL
             THEN
                v_errmsg := v_errmsg || '--' || 'Emboss Generation Date is NULL ';

             END IF;

             As per excel disscussion

             */
            IF v_length_check IS NOT NULL
            THEN
               IF LENGTH (v_length_check) > 17
               THEN
                  v_errmsg :=
                        v_errmsg
                     || '--'
                     || 'Emboss Generation Date length is invalid ';
               ELSE
                  /*-----Emboss Generation Date----*/
                  v_emboss_gendate := v_length_check;
               /*-----Emboss Generation Date----*/
               END IF;

               BEGIN
                  v_datechk :=
                              TO_DATE (v_length_check, 'YYYYMMDD HH24:MI:SS');
               EXCEPTION
                  WHEN OTHERS
                  THEN
                     v_errmsg := v_errmsg || '--' || 'Emboss date is invalid';
               END;
            END IF;
         EXCEPTION
            WHEN OTHERS
            THEN
               v_errmsg :=
                     v_errmsg
                  || '--'
                  || 'Emboss Generation Date validation failed';
               v_sqlerr :=
                     v_sqlerr
                  || ' -- '
                  || 'Data validation failed for field no '
                  || v_error_flag
                  || ' with tech error '
                  || SUBSTR (SQLERRM, 1, 100);
         END;

         BEGIN
            v_error_flag := 47;
            v_length_check :=
               TRIM ((SUBSTR (v_filebuffer,
                              INSTR (v_filebuffer, '|', 1, 46) + 1,
                                (INSTR (v_filebuffer, '|', 1, 47) - 1
                                )
                              - INSTR (v_filebuffer, '|', 1, 46)
                             )
                     )
                    );

            --SN:Modified for Galileo changes //To marked Emboss generation Flag as optional
            /*IF v_length_check IS NULL
            THEN
               v_errmsg :=
                        v_errmsg || '--' || 'Emboss Generation Flag is NULL ';
            END IF;*/
            --EN:Modified for Galileo changes //To marked Emboss generation Flag as optional

            IF v_length_check IS NOT NULL AND LENGTH (v_length_check) > 1
            THEN
               v_errmsg :=
                     v_errmsg
                  || '--'
                  || 'Emboss Generation Flag length is invalid ';
            ELSE
               /*-----Emboss Generation Flag----*/
               v_emboss_genflag := v_length_check;
            /*-----Emboss Generation Flag----*/
            END IF;

            IF v_length_check IS NOT NULL
            THEN
               BEGIN
                  v_numchk := TO_NUMBER (v_length_check);
               EXCEPTION
                  WHEN OTHERS
                  THEN
                     v_errmsg :=
                           v_errmsg
                        || '--'
                        || 'EMBOSS gen flag should be numeric ';
               END;
            --END IF;  --Modified for Galileo changes //To marked Emboss generation Flag as optional

            IF v_length_check NOT IN ('0', '1')
            THEN
               v_errmsg :=
                         v_errmsg || '--' || 'Invalid Emboss Generation Flag';
            END IF;
            
            END IF; --Modified for Galileo changes //To marked Emboss generation Flag as optional
         EXCEPTION
            WHEN OTHERS
            THEN
               v_errmsg :=
                     v_errmsg
                  || '--'
                  || 'Emboss Generation Flag validation failed';
               v_sqlerr :=
                     v_sqlerr
                  || ' -- '
                  || 'Data validation failed for field no '
                  || v_error_flag
                  || ' with tech error '
                  || SUBSTR (SQLERRM, 1, 100);
         END;

         BEGIN
            v_error_flag := 48;
            v_length_check :=
               TRIM ((SUBSTR (v_filebuffer,
                              INSTR (v_filebuffer, '|', 1, 47) + 1,
                                (INSTR (v_filebuffer, '|', 1, 48) - 1
                                )
                              - INSTR (v_filebuffer, '|', 1, 47)
                             )
                     )
                    );

            /*   IF v_pin_gendate IS NULL
               THEN
                  v_errmsg := v_errmsg || '--' || 'Pin Generation Date is NULL ';
               --RAISE exp_reject_loop_record;
               END IF;
                As per excel disscussion

            */
            IF v_length_check IS NOT NULL
            THEN
               IF LENGTH (v_length_check) > 17
               THEN
                  v_errmsg :=
                        v_errmsg
                     || '--'
                     || 'PIN Generation Date length is invalid ';
               ELSE
                  /*-----PIN Generation Date----*/
                  v_pin_gendate := v_length_check;
               /*-----PIN Generation Date----*/
               END IF;

               BEGIN
                  v_datechk := TO_DATE (v_pin_gendate, 'YYYYMMDD HH24:MI:SS');
               EXCEPTION
                  WHEN OTHERS
                  THEN
                     v_errmsg :=
                         v_errmsg || '--' || 'PIN Generation Date is invalid';
               END;
            END IF;
         EXCEPTION
            WHEN OTHERS
            THEN
               v_errmsg :=
                  v_errmsg || '--' || 'PIN Generation Date validation failed';
               v_sqlerr :=
                     v_sqlerr
                  || ' -- '
                  || 'Data validation failed for field no '
                  || v_error_flag
                  || ' with tech error '
                  || SUBSTR (SQLERRM, 1, 100);
         END;

         BEGIN
            v_error_flag := 49;
            v_length_check :=
               TRIM ((SUBSTR (v_filebuffer,
                              INSTR (v_filebuffer, '|', 1, 48) + 1,
                                (INSTR (v_filebuffer, '|', 1, 49) - 1
                                )
                              - INSTR (v_filebuffer, '|', 1, 48)
                             )
                     )
                    );

            IF v_length_check IS NULL
            THEN
               v_errmsg := v_errmsg || '--' || 'Pin Generation Flag is NULL';
            END IF;

            IF v_length_check IS NOT NULL AND LENGTH (v_length_check) > 1
            THEN
               v_errmsg :=
                  v_errmsg || '--'
                  || 'Pin Generation Flag length is invalid ';
            ELSE
               /*-----PIN Generation Flag----*/
               v_pin_genflag := v_length_check;
            /*-----PIN Generation Flag----*/
            END IF;

            IF v_length_check IS NOT NULL
            THEN
               BEGIN
                  v_numchk := TO_NUMBER (v_length_check);
               EXCEPTION
                  WHEN OTHERS
                  THEN
                     v_errmsg :=
                           v_errmsg
                        || '--'
                        || 'PIN gen flag should be numeric ';
               END;
            END IF;

            IF v_length_check NOT IN ('0', '1')
            THEN
               v_errmsg := v_errmsg || '--' || 'Invalid Pin Generation Flag';
            END IF;
         EXCEPTION
            WHEN OTHERS
            THEN
               v_errmsg :=
                  v_errmsg || '--' || 'Pin Generation Flag validation failed';
               v_sqlerr :=
                     v_sqlerr
                  || ' -- '
                  || 'Data validation failed for field no '
                  || v_error_flag
                  || ' with tech error '
                  || SUBSTR (SQLERRM, 1, 100);
         END;

         BEGIN
            v_error_flag := 50;
            v_length_check :=
               TRIM ((SUBSTR (v_filebuffer,
                              INSTR (v_filebuffer, '|', 1, 49) + 1,
                                (INSTR (v_filebuffer, '|', 1, 50) - 1
                                )
                              - INSTR (v_filebuffer, '|', 1, 49)
                             )
                     )
                    );

            IF v_length_check IS NOT NULL AND LENGTH (v_length_check) > 50
            THEN
               v_errmsg :=
                       v_errmsg || '--' || 'CCF file name length is invalid ';
            ELSE
               /*-----CCF File Name----*/
               v_ccf_file_name := v_length_check;
            /*-----CCF File Name----*/
            END IF;
         EXCEPTION
            WHEN OTHERS
            THEN
               v_errmsg :=
                        v_errmsg || '--' || 'CCF file name validation failed';
               v_sqlerr :=
                     v_sqlerr
                  || ' -- '
                  || 'Data validation failed for field no '
                  || v_error_flag
                  || ' with tech error '
                  || SUBSTR (SQLERRM, 1, 100);
         END;

        /*                              -- Commented on 02-Aug-2013 as per discussion
         BEGIN
            v_error_flag := 51;
            v_length_check :=
               TRIM ((SUBSTR (v_filebuffer,
                              INSTR (v_filebuffer, '|', 1, 50) + 1,
                                (INSTR (v_filebuffer, '|', 1, 51) - 1
                                )
                              - INSTR (v_filebuffer, '|', 1, 50)
                             )
                     )
                    );

            IF v_length_check IS NULL
            THEN
               v_errmsg := v_errmsg || '--' || 'KYC Flag is NULL ';
            END IF;

            IF v_length_check IS NOT NULL AND LENGTH (v_length_check) > 1
            THEN
               v_errmsg := v_errmsg || '--' || 'KYC Flag length is invalid ';
            ELSE
               -----KYC Flag----
               --v_kyc_flag := v_length_check;
            -----KYC Flag----
            --END IF;

            IF v_length_check IS NOT NULL
            THEN
               BEGIN
                  v_numchk := TO_NUMBER (v_length_check);
               EXCEPTION
                  WHEN OTHERS
                  THEN
                     v_errmsg :=
                        v_errmsg || '--'
                        || 'KYC flag field shold be numeric ';
               END;
            END IF;

            IF v_length_check NOT IN ('0', '1', '2', '3', '4', '5')
            THEN
               v_errmsg := v_errmsg || '--' || 'Invalid KYC Flag ';
            END IF;
         EXCEPTION
            WHEN OTHERS
            THEN
               v_errmsg := v_errmsg || '--' || 'KYC flag validation failed';
               v_sqlerr :=
                     v_sqlerr
                  || ' -- '
                  || 'Data validation failed for field no '
                  || v_error_flag
                  || ' with tech error '
                  || SUBSTR (SQLERRM, 1, 100);
         END;
       */                               -- Commented on 02-Aug-2013 as per discussion


         BEGIN
            v_error_flag := 52;
            v_length_check :=
               TRIM ((SUBSTR (v_filebuffer,
                              INSTR (v_filebuffer, '|', 1, 51) + 1,
                                (INSTR (v_filebuffer, '|', 1, 52) - 1
                                )
                              - INSTR (v_filebuffer, '|', 1, 51)
                             )
                     )
                    );

            IF v_length_check IS NULL
            THEN
               v_errmsg := v_errmsg || '--' || 'Total no of accounts is NULL';
            END IF;

            IF v_length_check IS NOT NULL AND LENGTH (v_length_check) > 1
            THEN
               v_errmsg :=
                  v_errmsg || '--'
                  || 'Total No Of Accounts length is invalid ';
            ELSE
               /*-----Total no of accounts----*/
               v_tot_accts := v_length_check;
            /*-----Total no of accounts----*/
            END IF;

            IF v_length_check IS NOT NULL
            THEN
               BEGIN
                  v_numchk := TO_NUMBER (v_length_check);

                  IF (v_length_check NOT BETWEEN 1 AND 6)
                  THEN
                     v_errmsg :=
                           v_errmsg
                        || '--'
                        || 'Total no of accounts should be between 1 and 6 ';
                  END IF;
               EXCEPTION
                  WHEN OTHERS
                  THEN
                     v_errmsg :=
                           v_errmsg
                        || '--'
                        || 'Total no of account field should be numeric ';
               END;
            END IF;
         EXCEPTION
            WHEN OTHERS
            THEN
               v_errmsg :=
                  v_errmsg || '--'
                  || 'Total no of accounts validation failed';
               v_sqlerr :=
                     v_sqlerr
                  || ' -- '
                  || 'Data validation failed for field no '
                  || v_error_flag
                  || ' with tech error '
                  || SUBSTR (SQLERRM, 1, 100);
         END;

         BEGIN
            v_error_flag := 53;
            v_length_check :=
               TRIM ((SUBSTR (v_filebuffer,
                              INSTR (v_filebuffer, '|', 1, 52) + 1,
                                (INSTR (v_filebuffer, '|', 1, 53) - 1
                                )
                              - INSTR (v_filebuffer, '|', 1, 52)
                             )
                     )
                    );

            IF v_length_check IS NULL
            THEN
               v_errmsg := v_errmsg || '--' || 'Account Number 1 is NULL ';
            END IF;

            IF v_length_check IS NOT NULL AND LENGTH (v_length_check) > 20
            THEN
               v_errmsg :=
                     v_errmsg || '--' || 'Account Number 1 length is invalid';
            ELSE
               /*-----Account No1----*/
               v_acct_numb1 := v_length_check;
            /*-----Account No1----*/
            END IF;

            IF v_length_check IS NOT NULL
            THEN
               BEGIN
                  v_numchk := TO_NUMBER (v_length_check);
               EXCEPTION
                  WHEN OTHERS
                  THEN
                     v_errmsg :=
                           v_errmsg
                        || '--'
                        || 'Account number 1 should be numeric ';
               END;
            END IF;
         EXCEPTION
            WHEN OTHERS
            THEN
               v_errmsg :=
                     v_errmsg || '--' || 'Account Number 1 validation failed';
               v_sqlerr :=
                     v_sqlerr
                  || ' -- '
                  || 'Data validation failed for field no '
                  || v_error_flag
                  || ' with tech error '
                  || SUBSTR (SQLERRM, 1, 100);
         END;

         BEGIN
            v_error_flag := 54;
            v_length_check :=
               TRIM ((SUBSTR (v_filebuffer,
                              INSTR (v_filebuffer, '|', 1, 53) + 1,
                                (INSTR (v_filebuffer, '|', 1, 54) - 1
                                )
                              - INSTR (v_filebuffer, '|', 1, 53)
                             )
                     )
                    );

            IF v_length_check IS NOT NULL AND LENGTH (v_length_check) > 20
            THEN
               v_errmsg :=
                     v_errmsg || '--' || 'Account Number 2 length is invalid';
            ELSE
               /*-----Account No2----*/
               v_acct_numb2 := v_length_check;
            /*-----Account No2---*/
            END IF;

            IF v_length_check IS NOT NULL
            THEN
               BEGIN
                  v_numchk := TO_NUMBER (v_length_check);
               EXCEPTION
                  WHEN OTHERS
                  THEN
                     v_errmsg :=
                           v_errmsg
                        || '--'
                        || 'Account number 2 should be numeric ';
               END;
            END IF;
         EXCEPTION
            WHEN OTHERS
            THEN
               v_errmsg :=
                     v_errmsg || '--' || 'Account Number 2 validation failed';
               v_sqlerr :=
                     v_sqlerr
                  || ' -- '
                  || 'Data validation failed for field no '
                  || v_error_flag
                  || ' with tech error '
                  || SUBSTR (SQLERRM, 1, 100);
         END;

         BEGIN
            v_error_flag := 55;
            v_length_check :=
               TRIM ((SUBSTR (v_filebuffer,
                              INSTR (v_filebuffer, '|', 1, 54) + 1,
                                (INSTR (v_filebuffer, '|', 1, 55) - 1
                                )
                              - INSTR (v_filebuffer, '|', 1, 54)
                             )
                     )
                    );

            IF v_length_check IS NOT NULL AND LENGTH (v_length_check) > 20
            THEN
               v_errmsg :=
                     v_errmsg || '--' || 'Account Number 3 length is invalid';
            ELSE
               /*-----Account No3----*/
               v_acct_numb3 := v_length_check;
            /*-----Account No3---*/
            END IF;

            IF v_length_check IS NOT NULL
            THEN
               BEGIN
                  v_numchk := TO_NUMBER (v_length_check);
               EXCEPTION
                  WHEN OTHERS
                  THEN
                     v_errmsg :=
                           v_errmsg
                        || '--'
                        || 'Account number 3 should be numeric ';
               END;
            END IF;
         EXCEPTION
            WHEN OTHERS
            THEN
               v_errmsg :=
                     v_errmsg || '--' || 'Account Number 3 validation failed';
               v_sqlerr :=
                     v_sqlerr
                  || ' -- '
                  || 'Data validation failed for field no '
                  || v_error_flag
                  || ' with tech error '
                  || SUBSTR (SQLERRM, 1, 100);
         END;

         BEGIN
            v_error_flag := 56;
            v_length_check :=
               TRIM ((SUBSTR (v_filebuffer,
                              INSTR (v_filebuffer, '|', 1, 55) + 1,
                                (INSTR (v_filebuffer, '|', 1, 56) - 1
                                )
                              - INSTR (v_filebuffer, '|', 1, 55)
                             )
                     )
                    );

            --Sn Added by Pankaj S. for length validation
            IF v_length_check IS NOT NULL AND LENGTH (v_length_check) > 20
            THEN
               v_errmsg :=
                     v_errmsg || '--' || 'Account Number 4 length is invalid';
            -- RAISE exp_reject_loop_record;
            ELSE
               /*-----Account No4----*/
               v_acct_numb4 := v_length_check;
            /*-----Account No4---*/
            END IF;

            IF v_length_check IS NOT NULL
            THEN
               BEGIN
                  v_numchk := TO_NUMBER (v_length_check);
               EXCEPTION
                  WHEN OTHERS
                  THEN
                     v_errmsg :=
                           v_errmsg
                        || '--'
                        || 'Account number 4 should be numeric ';
               END;
            END IF;
         EXCEPTION
            WHEN OTHERS
            THEN
               v_errmsg :=
                     v_errmsg || '--' || 'Account Number 4 validation failed';
               v_sqlerr :=
                     v_sqlerr
                  || ' -- '
                  || 'Data validation failed for field no '
                  || v_error_flag
                  || ' with tech error '
                  || SUBSTR (SQLERRM, 1, 100);
         END;

         BEGIN
            v_error_flag := 57;
            v_length_check :=
               TRIM ((SUBSTR (v_filebuffer,
                              INSTR (v_filebuffer, '|', 1, 56) + 1,
                                (INSTR (v_filebuffer, '|', 1, 57) - 1
                                )
                              - INSTR (v_filebuffer, '|', 1, 56)
                             )
                     )
                    );

            IF v_length_check IS NOT NULL AND LENGTH (v_length_check) > 20
            THEN
               v_errmsg :=
                     v_errmsg || '--' || 'Account Number 5 length is invalid';
            ELSE
               /*-----Account No5----*/
               v_acct_numb5 := v_length_check;
            /*-----Account No5---*/
            END IF;

            IF v_length_check IS NOT NULL
            THEN
               BEGIN
                  v_numchk := TO_NUMBER (v_length_check);
               EXCEPTION
                  WHEN OTHERS
                  THEN
                     v_errmsg :=
                           v_errmsg
                        || '--'
                        || 'Account number 5 should be numeric ';
               END;
            END IF;
         EXCEPTION
            WHEN OTHERS
            THEN
               v_errmsg :=
                     v_errmsg || '--' || 'Account Number 5 validation failed';
               v_sqlerr :=
                     v_sqlerr
                  || ' -- '
                  || 'Data validation failed for field no '
                  || v_error_flag
                  || ' with tech error '
                  || SUBSTR (SQLERRM, 1, 100);
         END;

         BEGIN
            v_error_flag := 58;
            v_length_check :=
               TRIM ((SUBSTR (v_filebuffer,
                              INSTR (v_filebuffer, '|', 1, 57) + 1,
                                (INSTR (v_filebuffer, '|', 1, 58) - 1
                                )
                              - INSTR (v_filebuffer, '|', 1, 57)
                             )
                     )
                    );

            IF v_length_check IS NOT NULL AND LENGTH (v_length_check) > 20
            THEN
               v_errmsg :=
                  v_errmsg || '--'
                  || 'Saving Account Number length is invalid';
            ELSE
               /*-----Savings Account---*/
               v_savig_acct_numb := v_length_check;
            /*-----Savings Account---*/
            END IF;

            IF v_length_check IS NOT NULL
            THEN
               BEGIN
                  v_numchk := TO_NUMBER (v_length_check);
               EXCEPTION
                  WHEN OTHERS
                  THEN
                     v_errmsg :=
                           v_errmsg
                        || '--'
                        || 'Saving Account number should be numeric ';
               END;
            END IF;
         EXCEPTION
            WHEN OTHERS
            THEN
               v_errmsg :=
                  v_errmsg || '--'
                  || 'Saving Accoun Number validation failed';
               v_sqlerr :=
                     v_sqlerr
                  || ' -- '
                  || 'Data validation failed for field no '
                  || v_error_flag
                  || ' with tech error '
                  || SUBSTR (SQLERRM, 1, 100);
         END;

         BEGIN
            v_error_flag := 59;
            v_length_check :=
               TRIM ((SUBSTR (v_filebuffer,
                              INSTR (v_filebuffer, '|', 1, 58) + 1,
                                (INSTR (v_filebuffer, '|', 1, 59) - 1
                                )
                              - INSTR (v_filebuffer, '|', 1, 58)
                             )
                     )
                    );

            IF v_length_check IS NOT NULL AND LENGTH (v_length_check) > 40
            THEN
               v_errmsg :=
                        v_errmsg || '--' || 'Serial Number length is invalid';
            ELSE
               /*-----Serial Number---*/
               v_serial_numb := v_length_check;
            /*-----Serial Number---*/
            END IF;

            IF v_length_check IS NOT NULL
            THEN
               BEGIN
                  v_numchk := TO_NUMBER (v_length_check);
               EXCEPTION
                  WHEN OTHERS
                  THEN
                     v_errmsg :=
                        v_errmsg || '--'
                        || 'Serial number should be numeric ';
               END;
            END IF;
         EXCEPTION
            WHEN OTHERS
            THEN
               v_errmsg :=
                        v_errmsg || '--' || 'Serial Number validation failed';
               v_sqlerr :=
                     v_sqlerr
                  || ' -- '
                  || 'Data validation failed for field no '
                  || v_error_flag
                  || ' with tech error '
                  || SUBSTR (SQLERRM, 1, 100);
         END;

         BEGIN
            v_error_flag := 60;
            v_length_check :=
               TRIM ((SUBSTR (v_filebuffer,
                              INSTR (v_filebuffer, '|', 1, 59) + 1,
                                (INSTR (v_filebuffer, '|', 1, 60) - 1
                                )
                              - INSTR (v_filebuffer, '|', 1, 59)
                             )
                     )
                    );

            IF v_length_check IS NULL
            THEN
               v_errmsg := v_errmsg || '--' || 'Initial Load Flag is NULL ';
            END IF;

            IF v_length_check IS NOT NULL AND LENGTH (v_length_check) > 1
            THEN
               v_errmsg :=
                    v_errmsg || '--' || 'Initial Load Flag length is invalid';
            ELSE
               /*-----Initial Load Flag---*/
               v_initial_load_flag := v_length_check;
            /*-----Initial Load Flag---*/
            END IF;

            IF v_length_check NOT IN ('Y', 'N')
            THEN
               v_errmsg := v_errmsg || '--' || 'Invalid Initial Load Flag ';
            END IF;
         EXCEPTION
            WHEN OTHERS
            THEN
               v_errmsg :=
                    v_errmsg || '--' || 'Initial Load Flag validation failed';
               v_sqlerr :=
                     v_sqlerr
                  || ' -- '
                  || 'Data validation failed for field no '
                  || v_error_flag
                  || ' with tech error '
                  || SUBSTR (SQLERRM, 1, 100);
         END;

         BEGIN
            v_error_flag := 61;
            v_length_check :=
               TRIM ((SUBSTR (v_filebuffer,
                              INSTR (v_filebuffer, '|', 1, 60) + 1,
                                (INSTR (v_filebuffer, '|', 1, 61) - 1
                                )
                              - INSTR (v_filebuffer, '|', 1, 60)
                             )
                     )
                    );

            --SN:Modified for Galileo changes //To mark Security Question 1 as optional
			/*IF v_starter_card_flag = '1' AND v_length_check IS NULL
            THEN
               v_errmsg := v_errmsg || '--' || 'Security Question 1 is NULL ';
            END IF;*/
			--EN:Modified for Galileo changes //To mark Security Question 1 as optional

            IF v_length_check IS NOT NULL AND LENGTH (v_length_check) > 200
            THEN
               v_errmsg :=
                   v_errmsg || '--' || 'security question1 length is invalid';
            ELSE
               /*-----Sequrity Question 1---*/
               v_security_quest1 := v_length_check;
            /*-----Sequrity Question 1---*/
            END IF;
         EXCEPTION
            WHEN OTHERS
            THEN
               v_errmsg :=
                  v_errmsg || '--' || 'Security Question 1 validation failed';
               v_sqlerr :=
                     v_sqlerr
                  || ' -- '
                  || 'Data validation failed for field no '
                  || v_error_flag
                  || ' with tech error '
                  || SUBSTR (SQLERRM, 1, 100);
         END;

         BEGIN
            v_error_flag := 62;
            v_length_check :=
               TRIM ((SUBSTR (v_filebuffer,
                              INSTR (v_filebuffer, '|', 1, 61) + 1,
                                (INSTR (v_filebuffer, '|', 1, 62) - 1
                                )
                              - INSTR (v_filebuffer, '|', 1, 61)
                             )
                     )
                    );

            --SN:Modified for Galileo changes //To mark Security Answer 1  as optional
			/*IF v_starter_card_flag = '1' AND v_length_check IS NULL
            THEN
               v_errmsg := v_errmsg || '--' || 'Security Answer 1 is NULL ';
            END IF;*/
			--EN:Modified for Galileo changes //To mark Security Answer 1  as optional

            IF v_length_check IS NOT NULL AND LENGTH (v_length_check) > 100
            THEN
               v_errmsg :=
                     v_errmsg || '--' || 'security answer1 length is invalid';
            ELSE
               /*-----Sequrity Answer 1---*/
               v_security_ans1 := v_length_check;
            /*-----Sequrity Answer 1---*/
            END IF;
         EXCEPTION
            WHEN OTHERS
            THEN
               v_errmsg :=
                    v_errmsg || '--' || 'Security Answer 1 validation failed';
               v_sqlerr :=
                     v_sqlerr
                  || ' -- '
                  || 'Data validation failed for field no '
                  || v_error_flag
                  || ' with tech error '
                  || SUBSTR (SQLERRM, 1, 100);
         END;

         BEGIN
            v_error_flag := 63;
            v_length_check :=
               TRIM ((SUBSTR (v_filebuffer,
                              INSTR (v_filebuffer, '|', 1, 62) + 1,
                                (INSTR (v_filebuffer, '|', 1, 63) - 1
                                )
                              - INSTR (v_filebuffer, '|', 1, 62)
                             )
                     )
                    );

           /*                                   -- Commented on 02-Aug-2013 as per discussion

            IF v_starter_card_flag = '1' AND v_length_check IS NULL
            THEN
               v_errmsg := v_errmsg || '--' || 'Security Question 2 is NULL ';
            END IF;

           */                                   -- Commented on 02-Aug-2013 as per discussion

            IF v_length_check IS NOT NULL AND LENGTH (v_length_check) > 200
            THEN
               v_errmsg :=
                   v_errmsg || '--' || 'Security Question 2 length is invalid';
            ELSE
               /*-----Sequrity Question 2---*/
               v_security_quest2 := v_length_check;
            /*-----Sequrity Question 2---*/
            END IF;
         EXCEPTION
            WHEN OTHERS
            THEN
               v_errmsg :=
                  v_errmsg || '--' || 'Security Question 2 validation failed';
               v_sqlerr :=
                     v_sqlerr
                  || ' -- '
                  || 'Data validation failed for field no '
                  || v_error_flag
                  || ' with tech error '
                  || SUBSTR (SQLERRM, 1, 100);
         END;

         BEGIN
            v_error_flag := 64;
            v_length_check :=
               TRIM ((SUBSTR (v_filebuffer,
                              INSTR (v_filebuffer, '|', 1, 63) + 1,
                                (INSTR (v_filebuffer, '|', 1, 64) - 1
                                )
                              - INSTR (v_filebuffer, '|', 1, 63)
                             )
                     )
                    );
            /*                                   -- Commented on 02-Aug-2013 as per discussion

            IF v_starter_card_flag = '1' AND v_length_check IS NULL
            THEN
               v_errmsg := v_errmsg || '--' || 'Security Answer 2 is NULL ';
            END IF;

           */                                   -- Commented on 02-Aug-2013 as per discussion

            IF v_length_check IS NOT NULL AND LENGTH (v_length_check) > 100
            THEN
               v_errmsg :=
                     v_errmsg || '--' || 'Security Answer 2 length is invalid';
            ELSE
               /*-----Sequrity Answer 2---*/
               v_security_ans2 := v_length_check;
            /*-----Sequrity Answer 2---*/
            END IF;
         EXCEPTION
            WHEN OTHERS
            THEN
               v_errmsg :=
                    v_errmsg || '--' || 'Security Answer 2 validation failed';
               v_sqlerr :=
                     v_sqlerr
                  || ' -- '
                  || 'Data validation failed for field no '
                  || v_error_flag
                  || ' with tech error '
                  || SUBSTR (SQLERRM, 1, 100);
         END;

         BEGIN
            v_error_flag := 65;
            v_length_check :=
               TRIM ((SUBSTR (v_filebuffer,
                              INSTR (v_filebuffer, '|', 1, 64) + 1,
                                (INSTR (v_filebuffer, '|', 1, 65) - 1
                                )
                              - INSTR (v_filebuffer, '|', 1, 64)
                             )
                     )
                    );

           /*                                   -- Commented on 02-Aug-2013 as per discussion

            IF v_starter_card_flag = '1' AND v_length_check IS NULL
            THEN
               v_errmsg := v_errmsg || '--' || 'Security Question 3 is NULL ';
            END IF;

           */                                   -- Commented on 02-Aug-2013 as per discussion

            IF v_length_check IS NOT NULL AND LENGTH (v_length_check) > 200
            THEN
               v_errmsg :=
                   v_errmsg || '--' || 'Security Question 3 length is invalid';
            ELSE
               /*-----Sequrity Question 3---*/
               v_security_quest3 := v_length_check;
            /*-----Sequrity Question 3---*/
            END IF;
         EXCEPTION
            WHEN OTHERS
            THEN
               v_errmsg :=
                  v_errmsg || '--' || 'Security Question 3 validation failed';
               v_sqlerr :=
                     v_sqlerr
                  || ' -- '
                  || 'Data validation failed for field no '
                  || v_error_flag
                  || ' with tech error '
                  || SUBSTR (SQLERRM, 1, 100);
         END;

         BEGIN
            v_error_flag := 66;
            v_length_check :=
               TRIM ((SUBSTR (v_filebuffer,
                              INSTR (v_filebuffer, '|', 1, 65) + 1,
                                (INSTR (v_filebuffer, '|', 1, 66) - 1
                                )
                              - INSTR (v_filebuffer, '|', 1, 65)
                             )
                     )
                    );

            /*                                   -- Commented on 02-Aug-2013 as per discussion

            IF v_starter_card_flag = '1' AND v_length_check IS NULL
            THEN
               v_errmsg := v_errmsg || '--' || 'Security Answer 3 is NULL ';
            END IF;

            */                                   -- Commented on 02-Aug-2013 as per discussion

            IF v_length_check IS NOT NULL AND LENGTH (v_length_check) > 100
            THEN
               v_errmsg :=
                     v_errmsg || '--' || 'Security Answer 3 length is invalid';
            ELSE
               /*-----Sequrity Answer 3---*/
               v_security_ans3 := v_length_check;
            /*-----Sequrity Answer 3--*/
            END IF;
         EXCEPTION
            WHEN OTHERS
            THEN
               v_errmsg :=
                    v_errmsg || '--' || 'Security Answer 3 validation failed';
               v_sqlerr :=
                     v_sqlerr
                  || ' -- '
                  || 'Data validation failed for field no '
                  || v_error_flag
                  || ' with tech error '
                  || SUBSTR (SQLERRM, 1, 100);
         END;

         BEGIN
            v_error_flag := 67;
            v_length_check :=
               TRIM ((SUBSTR (v_filebuffer,
                              INSTR (v_filebuffer, '|', 1, 66) + 1,
                                (INSTR (v_filebuffer, '|', 1, 67) - 1
                                )
                              - INSTR (v_filebuffer, '|', 1, 66)
                             )
                     )
                    );

            /*                                   -- Commented on 02-Aug-2013 as per discussion

            IF v_starter_card_flag = '1' AND v_length_check IS NULL
            THEN
               v_errmsg := v_errmsg || '--' || 'Customer Username is NULL ';
            END IF;

            */                                   -- Commented on 02-Aug-2013 as per discussion

            IF v_length_check IS NOT NULL AND LENGTH (v_length_check) > 15 --Modified length from 50 to 15 Dhiraj Gaikwad
            THEN
               v_errmsg :=
                    v_errmsg || '--' || 'Customer Username length is invalid';
            ELSE
               /*-----Customer UserName---*/
               v_customer_username := v_length_check;
            /*-----Customer UserName---*/
            END IF;
         EXCEPTION
            WHEN OTHERS
            THEN
               v_errmsg :=
                    v_errmsg || '--' || 'Customer Username validation failed';
               v_sqlerr :=
                     v_sqlerr
                  || ' -- '
                  || 'Data validation failed for field no '
                  || v_error_flag
                  || ' with tech error '
                  || SUBSTR (SQLERRM, 1, 100);
         END;

         BEGIN
            v_error_flag := 68;
            v_length_check :=
               TRIM ((SUBSTR (v_filebuffer,
                              INSTR (v_filebuffer, '|', 1, 67) + 1,
                                (INSTR (v_filebuffer, '|', 1, 68) - 1
                                )
                              - INSTR (v_filebuffer, '|', 1, 67)
                             )
                     )
                    );

            /*IF v_customer_password IS NULL
            THEN
               v_errmsg := v_errmsg || '--' || 'Customer Password is NULL ';

            END IF;

            As per excel Nonmandotory

            */
            IF v_length_check IS NOT NULL AND LENGTH (v_length_check) > 100
            THEN
               v_errmsg :=
                    v_errmsg || '--' || 'Customer password length is invalid';
            ELSE
               /*-----Customer Password---*/
               v_customer_password := v_length_check;
            /*-----Customer Password---*/
            END IF;
         EXCEPTION
            WHEN OTHERS
            THEN
               v_errmsg :=
                    v_errmsg || '--' || 'Customer password validation failed';
               v_sqlerr :=
                     v_sqlerr
                  || ' -- '
                  || 'Data validation failed for field no '
                  || v_error_flag
                  || ' with tech error '
                  || SUBSTR (SQLERRM, 1, 100);
         END;

         BEGIN
            v_error_flag := 69;
            v_length_check :=
               TRIM ((SUBSTR (v_filebuffer,
                              INSTR (v_filebuffer, '|', 1, 68) + 1,
                                (INSTR (v_filebuffer, '|', 1, 69) - 1
                                )
                              - INSTR (v_filebuffer, '|', 1, 68)
                             )
                     )
                    );

            IF v_length_check IS NULL  --OR v_sms_alert_flag NOT IN ('0', '1')
            THEN
               v_errmsg := v_errmsg || '--' || 'SMS Alert Flag is NULL ';
            END IF;

            IF v_length_check IS NOT NULL AND LENGTH (v_length_check) > 1
            THEN
               v_errmsg :=
                       v_errmsg || '--' || 'SMS Alert Flag length is invalid';
            ELSE
               /*-----SMS Alert Flag--*/
               v_sms_alert_flag := v_length_check;
            /*-----SMS Alert Flag--*/
            END IF;

            --Sn Modified by Pankaj S. on 04_Jully_2013
            IF v_length_check IS NOT NULL
            THEN
               BEGIN
                  v_numchk := TO_NUMBER (v_length_check);
               EXCEPTION
                  WHEN OTHERS
                  THEN
                     v_errmsg :=
                        v_errmsg || '--'
                        || 'SMS Alert Flag should be numeric ';
               END;

                IF v_length_check NOT IN ('0', '1')
                THEN
                   v_errmsg := v_errmsg || '--' || 'Invalid SMS Alert Flag ';
                END IF;
            END IF;
            --En Modified by Pankaj S. on 04_Jully_2013
         EXCEPTION
            WHEN OTHERS
            THEN
               v_errmsg :=
                       v_errmsg || '--' || 'SMS Alert Flag validation failed';
               v_sqlerr :=
                     v_sqlerr
                  || ' -- '
                  || 'Data validation failed for field no '
                  || v_error_flag
                  || ' with tech error '
                  || SUBSTR (SQLERRM, 1, 100);
         END;

         BEGIN
            v_error_flag := 70;
            v_length_check :=
               TRIM ((SUBSTR (v_filebuffer,
                              INSTR (v_filebuffer, '|', 1, 69) + 1,
                                (INSTR (v_filebuffer, '|', 1, 70) - 1
                                )
                              - INSTR (v_filebuffer, '|', 1, 69)
                             )
                     )
                    );

            IF v_length_check IS NULL
            --OR v_email_alert_flag NOT IN ('Y', 'N')
            THEN
               v_errmsg := v_errmsg || '--' || 'EMAIL Alert Flag is NULL ';
            END IF;

            IF v_length_check IS NOT NULL AND LENGTH (v_length_check) > 1
            THEN
               v_errmsg :=
                     v_errmsg || '--' || 'EMAIL Alert Flag length is invalid';
            ELSE
               /*-----Email Alert Flag--*/
               v_email_alert_flag := v_length_check;
            /*-----Email Alert Flag--*/
            END IF;

            --Sn Modified by Pankaj S. on 04_Jully_2013
            IF v_length_check IS NOT NULL
            THEN
               BEGIN
                  v_numchk := TO_NUMBER (v_length_check);
               EXCEPTION
                  WHEN OTHERS
                  THEN
                     v_errmsg :=
                           v_errmsg
                        || '--'
                        || 'EMAIL Alert Flag should be numeric ';
               END;

               IF v_length_check NOT IN ('0', '1')
               THEN
                v_errmsg := v_errmsg || '--' || 'Invalid EMAIL Alert Flag ';
               END IF;
            END IF;
            --En Modified by Pankaj S. on 04_Jully_2013
         EXCEPTION
            WHEN OTHERS
            THEN
               v_errmsg :=
                     v_errmsg || '--' || 'EMAIL Alert Flag validation failed';
               v_sqlerr :=
                     v_sqlerr
                  || ' -- '
                  || 'Data validation failed for field no '
                  || v_error_flag
                  || ' with tech error '
                  || SUBSTR (SQLERRM, 1, 100);
         END;

         BEGIN
            v_error_flag := 71;
            v_length_check :=
               TRIM ((SUBSTR (v_filebuffer,
                              INSTR (v_filebuffer, '|', 1, 70) + 1,
                                (INSTR (v_filebuffer, '|', 1, 71) - 1
                                )
                              - INSTR (v_filebuffer, '|', 1, 70)
                             )
                     )
                    );

            IF v_length_check IS NOT NULL AND LENGTH (v_length_check) > 15
            THEN
               v_errmsg :=
                    v_errmsg || '--' || 'location/store id length is invalid';
            ELSE
               /*-----Store ID------*/
               v_store_id := v_length_check;
            /*-----Store ID------*/
            END IF;

            IF v_merchant_id IS NOT NULL
            THEN
               IF v_length_check IS NOT NULL
               THEN
                  BEGIN
                     SELECT 1
                       INTO v_dum
                       FROM cms_merinv_location
                      WHERE cml_inst_code = prm_instcode
                        AND cml_mer_id = v_merchant_id
                        AND cml_location_id = v_length_check;

                     v_inv_flag := 'Y';
                  EXCEPTION
                     WHEN NO_DATA_FOUND
                     THEN
                        v_errmsg :=
                              v_errmsg
                           || '--'
                           || 'location/store ID not present in master';
                     WHEN OTHERS
                     THEN
                        v_errmsg :=
                              v_errmsg
                           || '--'
                           || 'error while validating location/store id with master as '
                           || SUBSTR (SQLERRM, 1, 200);
                  END;
               ELSE
                  v_errmsg := v_errmsg || '--' || 'location/store ID is NULL';
               END IF;

               BEGIN
                  v_numchk := TO_NUMBER (v_length_check);
               EXCEPTION
                  WHEN OTHERS
                  THEN
                     v_errmsg :=
                           v_errmsg
                        || '--'
                        || 'Location/Store ID should be numeric ';
               END;
            END IF;
         EXCEPTION
            WHEN OTHERS
            THEN
               v_errmsg := v_errmsg || '--' || 'Store Id validation failed';
               v_sqlerr :=
                     v_sqlerr
                  || ' -- '
                  || 'Data validation failed for field no '
                  || v_error_flag
                  || ' with tech error '
                  || SUBSTR (SQLERRM, 1, 100);
         END;

         BEGIN
            v_error_flag := 72;
            v_length_check :=
               TRIM ((SUBSTR (v_filebuffer,
                              INSTR (v_filebuffer, '|', 1, 71) + 1,
                                (INSTR (v_filebuffer, '|', 1, 72) - 1
                                )
                              - INSTR (v_filebuffer, '|', 1, 71)
                             )
                     )
                    );

            IF v_length_check IS NOT NULL AND LENGTH (v_length_check) > 5
            THEN
               v_errmsg := v_errmsg || '--' || 'ID type length is invalid';
            ELSE
               /*-----ID Type------*/
               v_id_type := v_length_check;
            /*-----ID Type------*/
            END IF;
         EXCEPTION
            WHEN OTHERS
            THEN
               v_errmsg := v_errmsg || '--' || 'ID type validation failed';
               v_sqlerr :=
                     v_sqlerr
                  || ' -- '
                  || 'Data validation failed for field no '
                  || v_error_flag
                  || ' with tech error '
                  || SUBSTR (SQLERRM, 1, 100);
         END;

         BEGIN
            v_error_flag := 75;
            v_length_check :=
               TRIM ((SUBSTR (v_filebuffer,
                              INSTR (v_filebuffer, '|', 1, 72) + 1,
                                (INSTR (v_filebuffer, '|', 1, 73) - 1
                                )
                              - INSTR (v_filebuffer, '|', 1, 72)
                             )
                     )
                    );

            IF v_length_check IS NOT NULL
            THEN
               IF LENGTH (v_length_check) > 40
               THEN
                  v_errmsg :=
                            v_errmsg || '--' || 'ID issuer length is invalid';
               --RAISE exp_reject_loop_record;
               ELSE
                  /*----- ID ISSUER ------*/
                  v_id_issuer := v_length_check;
               /*----- ID ISSUER ------*/
               END IF;
            ELSE
               IF v_id_type <> 'SSN'
               THEN
                  v_errmsg := v_errmsg || '--' || 'ID issuer is NULL';
               END IF;
            END IF;
         EXCEPTION
            WHEN OTHERS
            THEN
               v_errmsg := v_errmsg || '--' || 'ID issuer validation failed';
               v_sqlerr :=
                     v_sqlerr
                  || ' -- '
                  || 'Data validation failed for field no '
                  || v_error_flag
                  || ' with tech error '
                  || SUBSTR (SQLERRM, 1, 100);
         END;

         BEGIN
            v_error_flag := 76;
            v_length_check :=
               TRIM ((SUBSTR (v_filebuffer,
                              INSTR (v_filebuffer, '|', 1, 73) + 1,
                                (INSTR (v_filebuffer, '|', 1, 74) - 1
                                )
                              - INSTR (v_filebuffer, '|', 1, 73)
                             )
                     )
                    );

            IF v_id_type <> 'SSN' AND v_length_check IS NULL
            THEN
               v_errmsg := v_errmsg || '--' || 'ID issuence date is NULL';
            END IF;

            IF v_length_check IS NOT NULL
            THEN
               IF LENGTH (v_length_check) > 17
               THEN
                  v_errmsg :=
                     v_errmsg || '--' || 'ID issuence date length is invalid';
               --RAISE exp_reject_loop_record;
               ELSE
                  /*----- ID ISSUENCE DATE ------*/
                  v_idissuence_date := v_length_check;
               /*----- ID ISSUENCE DATE ------*/
               END IF;

               BEGIN
                  v_datechk := TO_DATE (v_pin_gendate, 'YYYYMMDD HH24:MI:SS');
               EXCEPTION
                  WHEN OTHERS
                  THEN
                     v_errmsg :=
                            v_errmsg || '--' || 'ID issuence date is invalid';
               END;
            ELSE
               IF v_id_type <> 'SSN'
               THEN
                  v_errmsg := v_errmsg || '--' || 'ID issuence date is NULL';
               END IF;
            END IF;
         EXCEPTION
            WHEN OTHERS
            THEN
               v_errmsg :=
                     v_errmsg || '--' || 'ID issuence date validation failed';
               v_sqlerr :=
                     v_sqlerr
                  || ' -- '
                  || 'Data validation failed for field no '
                  || v_error_flag
                  || ' with tech error '
                  || SUBSTR (SQLERRM, 1, 100);
         END;

         BEGIN
            v_error_flag := 77;
            v_length_check :=
               TRIM ((SUBSTR (v_filebuffer,
                              INSTR (v_filebuffer, '|', 1, 74) + 1,
                                (INSTR (v_filebuffer, '|', 1, 75) - 1
                                )
                              - INSTR (v_filebuffer, '|', 1, 74)
                             )
                     )
                    );

            IF v_length_check IS NOT NULL
            THEN
               IF LENGTH (v_length_check) > 17
               THEN
                  v_errmsg :=
                       v_errmsg || '--' || 'ID expiry date length is invalid';
               --RAISE exp_reject_loop_record;
               ELSE
                  /*----- ID EXPIRY DATE ------*/
                  v_idexpry_date := v_length_check;
               /*----- ID EXPIRY DATE ------*/
               END IF;

               BEGIN
                  v_datechk := TO_DATE (v_pin_gendate, 'YYYYMMDD HH24:MI:SS');
               EXCEPTION
                  WHEN OTHERS
                  THEN
                     v_errmsg :=
                              v_errmsg || '--' || 'ID expiry date is invalid';
               END;
            ELSE
               IF v_id_type <> 'SSN'
               THEN
                  v_errmsg := v_errmsg || '--' || 'ID expiry date is NULL';
               END IF;
            END IF;
         EXCEPTION
            WHEN OTHERS
            THEN
               v_errmsg :=
                       v_errmsg || '--' || 'ID expiry date validation failed';
               v_sqlerr :=
                     v_sqlerr
                  || ' -- '
                  || 'Data validation failed for field no '
                  || v_error_flag
                  || ' with tech error '
                  || SUBSTR (SQLERRM, 1, 100);
         END;

         -- EN Added on 20-JUN-2013


        --SN : Added on 09-Oct-2013

         BEGIN
            v_error_flag := 78;
            v_length_check :=
               TRIM ((SUBSTR (v_filebuffer,
                              INSTR (v_filebuffer, '|', 1, 75) + 1,
                                (INSTR (v_filebuffer, '|', 1, 76) - 1
                                )
                              - INSTR (v_filebuffer, '|', 1, 75)
                             )
                     )
                    );

            IF v_length_check IS NOT NULL
            THEN
               IF LENGTH (v_length_check) > 17
               THEN
                  v_errmsg :=
                       v_errmsg || '--' || 'Registration date length is invalid';
               --RAISE exp_reject_loop_record;
               ELSE
                  /*----- Regisatration DATE ------*/
                  v_cam_reg_date := v_length_check;
               /*----- Regisatration DATE ------*/
               END IF;

            else
               v_errmsg := v_errmsg || '--' || 'Regisatration date is null';
            END IF;
         EXCEPTION
            WHEN OTHERS
            THEN
               v_errmsg :=
                       v_errmsg || '--' || 'Regisatration date validation failed';
               v_sqlerr :=
                     v_sqlerr
                  || ' -- '
                  || 'Data validation failed for field no '
                  || v_error_flag
                  || ' with tech error '
                  || SUBSTR (SQLERRM, 1, 100);
         END;

         --EN : Added on 09-Oct-2013

		 --SN Dhiraj Gaikwad
		 BEGIN
            v_error_flag := 79;
            v_length_check :=
               TRIM ((SUBSTR (v_filebuffer,
                              INSTR (v_filebuffer, '|', 1, 76) + 1,
                                (INSTR (v_filebuffer, '|', 1, 77) - 1
                                )
                              - INSTR (v_filebuffer, '|', 1, 76)
                             )
                     )
                    );

            IF v_length_check IS NOT NULL
            THEN
               IF LENGTH (v_length_check) > 4
               THEN
                  v_errmsg :=
                       v_errmsg || '--' || 'Package Type length is invalid';
               --RAISE exp_reject_loop_record;
               ELSE
                  /*----- Package Type ------*/
                  V_PACKAGE_TYPE := v_length_check;
               /*----- Package Type ------*/
               END IF;
            END IF;
         EXCEPTION
            WHEN OTHERS
            THEN
               v_errmsg :=
                       v_errmsg || '--' || 'Package Typ validation failed';
               v_sqlerr :=
                     v_sqlerr
                  || ' -- '
                  || 'Data validation failed for field no '
                  || v_error_flag
                  || ' with tech error '
                  || SUBSTR (SQLERRM, 1, 100);
         END;
       --EN Dhiraj Gaikwad
		   

         -- SN : Added for MOD(10) check

         BEGIN
            /*migr_find_binprefix (prm_instcode,
                                 v_prod_code,
                                 v_prod_catg_code,
                                 v_branch_id,
                                 v_tmppan,
                                 v_maxserl,
                                 v_errmsg
                                );

            IF v_errmsg <> 'OK'
            THEN
               v_errmsg := 'Error while finding TempPAN-' || v_errmsg;
               RAISE exp_reject_loop_record;
            END IF;*/
            v_temp_pan :=
                         SUBSTR (v_card_number, 1, LENGTH (v_card_number) - 1);
            v_len_pan := LENGTH (v_temp_pan);
            v_mult_ind := 2;

            FOR i IN REVERSE 1 .. v_len_pan
            LOOP
               v_res := SUBSTR (v_temp_pan, i, 1) * v_mult_ind;
               v_dig_len := LENGTH (v_res);

               IF v_dig_len = 2
               THEN
                  v_dig_sum := SUBSTR (v_res, 1, 1) + SUBSTR (v_res, 2, 1);
               ELSE
                  v_dig_sum := v_res;
               END IF;

               v_ceilable_sum := v_ceilable_sum + v_dig_sum;

               IF v_mult_ind = 2
               THEN
                  v_mult_ind := 1;
               ELSE
                  v_mult_ind := 2;
               END IF;
            END LOOP;

            v_ceiled_sum := v_ceilable_sum;

            IF MOD (v_ceilable_sum, 10) != 0
            THEN
               LOOP
                  v_ceiled_sum := v_ceiled_sum + 1;
                  EXIT WHEN MOD (v_ceiled_sum, 10) = 0;
               END LOOP;
            END IF;

            v_checkdig := v_ceiled_sum - v_ceilable_sum;

            IF SUBSTR (v_card_number, -1) <> v_checkdig
            THEN
               v_errmsg :=
                   v_errmsg || '--' || 'Invalid PAN - Check digit check failed';
            --RAISE exp_reject_loop_record;
            END IF;

         EXCEPTION
            /*  WHEN exp_reject_loop_record
              THEN
                 RAISE; */
            WHEN OTHERS
            THEN
               v_errmsg :=
                     v_errmsg
                  || '--'
                  || 'Error while check digit check-'
                  || SUBSTR (SQLERRM, 1, 200);
         -- RAISE exp_reject_loop_record;
         END;
         --EN : Added for MOD(10) check



         IF v_errmsg <> 'OK'
         THEN
            RAISE exp_reject_loop_record;
         END IF;


         BEGIN
            INSERT INTO migr_caf_info_entry
                        (mci_title, mci_seg12_name_line1,
                         mci_seg12_name_line2, mci_ssn, mci_prod_amt,
                         mci_birth_date, mci_seg12_addr_line1,
                         mci_seg12_addr_line2, mci_seg12_city,
                         mci_seg12_state, mci_seg12_country_code,
                         mci_seg12_postal_code, mci_seg12_homephone_no,
                         mci_seg12_mobileno, mci_seg13_addr_line1,
                         mci_seg13_addr_line2, mci_seg13_city,
                         mci_seg13_state, mci_seg13_country_code,
                         mci_seg13_postal_code, mci_seg13_homephone_no,
                         mci_seg13_mobileno, mci_seg12_emailid,
                         mci_prod_code, mci_card_type, mci_fiid,
                         --mci_cust_id,     -- Commented on 20-JUN-2013
                         mci_pan_code, mci_crd_stat, mci_proxy_numb,
                         mci_starter_crd_flag,
                         mci_pan_active_date, mci_pan_expiry_date,
                         mci_pan_gen_date, mci_atm_offline_limit,
                         mci_atm_online_limit, mci_pos_offline_limit,
                         mci_pos_online_limit, mci_offline_aggr_limit,
                         mci_online_aggr_limit, mci_mmpos_online_limit,
                         mci_mmpos_offline_limit, mci_pin_offset,
                         mci_next_bill_date, mci_ccf_file_name,
                         mci_kyc_flag, mci_seg31_acct_cnt, mci_seg31_num,
                         mci_seg31_num2, mci_seg31_num3, mci_seg31_num4,
                         mci_seg31_num5, mci_savigs_acct_number,
                         mci_serial_number, mci_init_load_flag,
                         mci_question_one, mci_answer_one,
                         mci_question_two, mci_answer_two,
                         mci_question_three, mci_answer_three,
                         mci_customer_username, mci_customer_password,
                         mci_sms_alert_flag,
                         mci_email_alert_flag,
                         mci_file_name, mci_rec_num,
                         mci_next_month_bill_date,
                         mci_pin_flag,
                         mci_emboss_flag,
                         mci_emboss_gen_date, mci_pin_gen_date,
                         mci_store_id,
                         mci_id_type       --added by Pankaj S. on 11_Jun_2013
                                    ,
                         mci_merc_id                   -- Added on 20-JUN-2013
                                    , mci_inv_flag,
                         mci_id_issuer,                -- Added on 25-JUN-2013
                                       mci_id_issuance_date,
                         -- Added on 25-JUN-2013
                         mci_id_expiry_date,           -- Added on 25-JUN-2013
                                            mci_inst_code,
                                            mci_migr_seqno,   --Added on 12-JUL-2013
                                            mci_reg_date,      -- Added on 09-Oct-2013
											MCI_HASH_PAN ,      --Added on 09-Oct-2013
											MCI_PACKAGE_TYPE --Dhiraj Gaikwad
                        )
                 VALUES (v_title, v_first_name,
                         v_last_name, v_ssn, v_init_topup_amt,
                         v_birth_date, v_perm_addr_line1,
                         v_perm_addr_line2, v_perm_addr_city,
                         v_perm_addr_state_code, v_perm_addr_cntry_code,
                         v_perm_addr_postal_code, v_perm_addr_phone,
                         v_perm_addr_mobile,--DMG
						 --SN:Modified for Galileo changes //If mailing address is null then physical will be considered as mailing
             NVL(v_mail_addr_line1,v_perm_addr_line1),
                         NVL(v_mail_addr_line2, v_perm_addr_line2), NVL(v_mail_addr_city, v_perm_addr_city),
                         NVL(v_mail_addr_state_code, v_perm_addr_state_code), NVL(v_mail_addr_cntry_code, v_perm_addr_cntry_code),
                         NVL(v_mail_addr_postal_code, v_perm_addr_postal_code), NVL(v_mail_addr_phone, v_perm_addr_phone),
                         NVL(v_mail_addr_mobile, v_perm_addr_mobile), --DMG
             --SN:Modified for Galileo changes //If mailing address is null then physical will be considered as mailing
						 v_email_address,
                         v_prod_code, v_prod_catg_code, v_branch_id,
                         --v_cust_id,       -- Commented on 20-JUN-2013
                         v_card_number, v_card_stat, v_proxy_number,
                         DECODE (v_starter_card_flag, '0', 'Y', '1', 'N'),
                         v_active_date, v_expiry_date,
                         v_pangen_date, v_atm_offline_limit,
                         v_atm_online_limit, v_pos_offline_limit,
                         v_pos_online_limit, v_offline_aggr_limit,
                         v_online_aggr_limit, v_mmpos_online_limit,
                         v_mmpos_offline_limit, v_pin_offset,
                         v_next_bill_date, v_ccf_file_name,
                         1,--v_kyc_flag -- Commented and hardcoded 1 on 02-Aug-2013 as per discussion
                         v_tot_accts, v_acct_numb1,
                         v_acct_numb2, v_acct_numb3, v_acct_numb4,
                         v_acct_numb5, v_savig_acct_numb,
                         v_serial_numb, v_initial_load_flag,
                         v_security_quest1, v_security_ans1,
                         v_security_quest2, v_security_ans2,
                         v_security_quest3, v_security_ans3,
                         v_customer_username, v_customer_password,
                         DECODE (v_sms_alert_flag, '0', 'Y', '1', 'N'),
                         DECODE (v_email_alert_flag, '0', 'Y', '1', 'N'),
                         prm_file_name, v_record_numb,
                         v_next_mb_date,
                         DECODE (v_pin_genflag, '0', 'Y', '1', 'N'),
                         DECODE (v_emboss_genflag, '0', 'Y', '1', 'N'),
                         v_emboss_gendate, v_pin_gendate,
                         v_store_id,
                         v_id_type         --added by Pankaj S. on 11_Jun_2013
                                  ,
                         v_merchant_id                 -- Added on 20-JUN-2013
                                      , v_inv_flag,
                         v_id_issuer,                  -- Added on 25-JUN-2013
                                     v_idexpry_date,   -- Added on 25-JUN-2013
                         v_idissuence_date,            -- Added on 25-JUN-2013
                                           prm_instcode,
                                           prm_seqno,                                --Added on 12-JUL-2013
                                           v_cam_reg_date,  -- Added on 09-oct-2013
										   GETHASH(V_CARD_NUMBER)    ,            --Added on 05092013 for performance
										   V_PACKAGE_TYPE
                        );
         EXCEPTION
         WHEN DUP_VAL_ON_INDEX THEN

              v_errmsg :=
                     v_errmsg
                  || '--'
                  || 'Duplicate Card Found While Loading Files';

                v_sqlerr :=
                     v_sqlerr
                  || ' -- '
                  || 'Data validation failed for field no '
                  || v_error_flag
                  || ' with tech error '
                  || SUBSTR (SQLERRM, 1, 100);

          WHEN OTHERS
            THEN
               v_errmsg :=
                     v_errmsg
                  || '--'
                  || 'Error while inserting into customer data segment ';

                v_sqlerr :=
                     v_sqlerr
                  || ' -- '
                  || 'Error while inserting into customer data segment '
                  || v_error_flag
                  || ' with tech error '
                  || SUBSTR (SQLERRM, 1, 100);

         --  RAISE exp_reject_loop_record;
         END;

         IF v_errmsg <> 'OK'
         THEN
            RAISE exp_reject_loop_record;
         END IF;

         v_succ_cnt := v_succ_cnt + 1;

         IF MOD (v_cnt, v_commit_param) = 0
         THEN         --commit after number of records defined at master level
            COMMIT;
         END IF;
      EXCEPTION
         WHEN exp_reject_loop_record
         THEN
            SELECT DECODE (SUBSTR (v_errmsg, 1, 2),
                           'OK', SUBSTR (v_errmsg, 5),
                           SUBSTR (v_errmsg, 2)
                          )
              INTO v_errmsg
              FROM DUAL;

            if v_dum = 1
            then

              v_card_number := v_card_no_already_present;

            end if;

            DBMS_OUTPUT.put_line (v_errmsg);
            sp_migr_log_excp_custdata (prm_file_name,
                                       v_record_numb,
                                       v_card_number,
                                       'E',
                                       v_errmsg,
                                       v_sqlerr
                                      );
            v_err_cnt := v_err_cnt + 1;
         WHEN OTHERS
         THEN
            v_errmsg :=
                  v_errmsg
               || 'Error while fetching data at posn '
               || v_error_flag
               || '-'
               || SUBSTR (SQLERRM, 1, 200);

            SELECT DECODE (SUBSTR (v_errmsg, 1, 2),
                           'OK', SUBSTR (v_errmsg, 5),
                           SUBSTR (v_errmsg, 2)
                          )
              INTO v_errmsg
              FROM DUAL;

            if v_dum = 1
            then

              v_card_number := v_card_no_already_present;


            end if;

            DBMS_OUTPUT.put_line (v_errmsg);
            sp_migr_log_excp_custdata (prm_file_name,
                                       v_record_numb,
                                       v_card_number,
                                       'E',
                                       v_errmsg,
                                       v_sqlerr
                                      );
            v_err_cnt := v_err_cnt + 1;
      END;

      BEGIN
         UPDATE migr_ctrl_table
            SET mct_ctrl_numb = mct_ctrl_numb + 1
          WHERE mct_ctrl_key = 'CUSTOMER_DATA' AND mct_inst_code = 1;
      EXCEPTION
         WHEN OTHERS
         THEN
            prm_errmsg :=
                  'Error while updating cotrol number '
               || SUBSTR (SQLERRM, 1, 200);
            RAISE exp_reject_record_main;
      END;
   END LOOP;

   COMMIT;                                 --Added by Pankaj S. on 11_Jun_2013
   ---En to create records in migration table
   UTL_FILE.fclose (v_file_handle);

   BEGIN                                            --resetting control number
      UPDATE migr_ctrl_table
         SET mct_ctrl_numb = 1
       WHERE mct_ctrl_key = 'CUSTOMER_DATA' AND mct_inst_code = 1;
   EXCEPTION
      WHEN OTHERS
      THEN
         prm_errmsg :=
            'Error while updating cotrol number ' || SUBSTR (SQLERRM, 1, 200);
         RAISE exp_reject_record_main;
   END;

   --Sn to create log for files
   BEGIN
      sp_migr_file_detl ('CUSTOMER_DATA_MIGR',
                         prm_file_name,
                         v_header,
                         v_cnt,
                         v_succ_cnt,
                         v_err_cnt,
                         'S',
                         'Successful'
                        );
   END;
--En to create log for files
EXCEPTION
   WHEN exp_reject_record_main
   THEN
      --   ROLLBACK;
      sp_migr_file_detl ('CUSTOMER_DATA_MIGR',
                         prm_file_name,
                         v_header,
                         v_check,
                         v_succ_cnt,
                         v_err_cnt,
                         'E',
                         prm_errmsg
                        );

      IF UTL_FILE.is_open (v_file_handle)
      THEN
         UTL_FILE.fclose (v_file_handle);
      END IF;
   WHEN exp_file_name
   THEN
      prm_errmsg :=
         'An attempt was made to read from a file or directory that does not exist, or file or directory access was denied by the operating system.';

      IF UTL_FILE.is_open (v_file_handle)
      THEN
         UTL_FILE.fclose (v_file_handle);
      END IF;
   WHEN OTHERS
   THEN
      DBMS_OUTPUT.put_line (v_cnt || ' ' || v_card_number);
      prm_errmsg := 'Main exception ' || SUBSTR (SQLERRM, 1, 200);

      IF UTL_FILE.is_open (v_file_handle)
      THEN
         UTL_FILE.fclose (v_file_handle);
      END IF;

      COMMIT;
END;
/
SHOW ERROR