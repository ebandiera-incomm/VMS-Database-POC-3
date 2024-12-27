CREATE OR REPLACE PROCEDURE VMSCMS.MIGR_TXNLOG_DATA_LOAD (
   prm_file_name   IN       VARCHAR2,
   prm_errmsg      OUT      VARCHAR2,
   prm_seqno       IN       number
)
AS
   v_file_handle                  UTL_FILE.file_type;
   v_filebuffer                   VARCHAR2 (32767);
   v_header                       VARCHAR2 (50);
   v_header_file                  VARCHAR2 (30);
   v_header_cnt                   NUMBER (20);
   v_record_numb                  VARCHAR2 (19);
   v_mesg_type                    VARCHAR2 (10);
   v_rrn                          VARCHAR2 (20); --Modified By Dhiraj Gaikwad RRN Length Increased from 15 to 20
   v_delivery_channel             VARCHAR2 (2);
   v_terminal_id                  VARCHAR2 (21);--Modified By Dhiraj Gaikwad RRN Length Increased from 20 to 21
   v_transaction_code             VARCHAR2 (2);
   v_transaction_type             VARCHAR2 (2);
   v_transaction_mode             VARCHAR2 (2);
   v_response_code                VARCHAR2 (7);
   v_business_date                VARCHAR2 (8);
   v_business_time                VARCHAR2 (10);
   v_card_no                      VARCHAR2 (19);
   v_beneficiary_card_no          VARCHAR2 (19);
   v_total_amount                 VARCHAR2 (20);
   v_merchant_name                VARCHAR2 (30);
   v_merchant_city                VARCHAR2 (30);
   v_mcccode                      VARCHAR2 (4);
   v_currency_code                VARCHAR2 (4);
   v_atm_namelocation             VARCHAR2 (40);
   v_amount                       VARCHAR2 (40);
   v_preauth_datetime             VARCHAR2 (19);
   v_stan                         VARCHAR2 (12);
   v_tranfee_amount               VARCHAR2 (30);--Modified By Dhiraj Gaikwad RRN Length Increased from 8 to30
   v_servicetax_amount            VARCHAR2 (8);
   v_tran_rev_flag                VARCHAR2 (1);
   v_account_number               VARCHAR2 (30);
   v_orgnl_cardnumber             VARCHAR2 (19);
   v_orgnl_rrn                    VARCHAR2 (15);
   v_orgnl_businessdate           VARCHAR2 (8);
   v_orgnl_businesstime           VARCHAR2 (10);
   v_orgnl_terminalid             VARCHAR2 (21);--Modified By Dhiraj Gaikwad RRN Length Increased from 20 to 21
   v_reversal_code                VARCHAR2 (4);
   v_proxy_number                 VARCHAR2 (19);
   v_account_balance              VARCHAR2 (22);
   v_ledger_balance               VARCHAR2 (22);
   v_ach_filename                 VARCHAR2 (40);
   v_return_achfilename           VARCHAR2 (40);
   v_odfi                         VARCHAR2 (30);
   v_rdfi                         VARCHAR2 (30);
   v_sec_codes                    VARCHAR2 (30);
   v_imp_date                     VARCHAR2 (30);
   v_process_date                 VARCHAR2 (30);
   v_effective_date               VARCHAR2 (30);
   v_auth_id                      VARCHAR2 (14);
   v_beforetxn_ledger_bal         VARCHAR2 (22);
   v_beforetxn_avail_bal          VARCHAR2 (22);
   v_ach_transactiontype_id       VARCHAR2 (20);
   v_incoming_crfile_id           VARCHAR2 (20);
   v_ind_idnum                    VARCHAR2 (15);
   v_ind_name                     VARCHAR2 (25);
   v_ach_id                       VARCHAR2 (10);
   v_ipaddress                    VARCHAR2 (15);
   v_ani                          VARCHAR2 (12);
   v_dni                          VARCHAR2 (12);
   v_card_status                  VARCHAR2 (3);
   v_waiver_amount                VARCHAR2 (22);
   v_international_ind            VARCHAR2 (1);
   v_crdr_flag                    VARCHAR2 (1);
   v_incremental_ind              VARCHAR2 (1);
   v_partialauth_ind              VARCHAR2 (1);
   v_completion_count             VARCHAR2 (2);
   v_lastcompletion_ind           VARCHAR2 (1);
   v_preauth_expryperiod          VARCHAR2 (3);
   v_merc_floorlimit_ind          VARCHAR2 (1);
   v_addr_verification_ind        VARCHAR2 (1);
   v_narration                    VARCHAR2 (300);
   v_dispute_flag                 VARCHAR2 (1);
   v_reason_code                  VARCHAR2 (3);
   v_remark                       VARCHAR2 (800);
   v_dispute_reason               VARCHAR2 (100);
   v_dispute_remark               VARCHAR2 (800);
   n                              NUMBER             := 0;
   i                              NUMBER             := 0;
   v_succ_cnt                     NUMBER (6)         := 0;
   v_err_cnt                      NUMBER (6)         := 0;
   exp_file_name                  EXCEPTION;
   v_error_flag                   NUMBER (5);         --modified by Pankaj S.
   v_errmsg                       VARCHAR2 (32767);
   PRAGMA EXCEPTION_INIT (exp_file_name, -29283);
   exp_loop_reject_record         EXCEPTION;
   exp_reject_record              EXCEPTION;
   v_file_chk                     NUMBER (2);
   v_matchcomp_flag               VARCHAR2 (1);
   v_c2ctxn_status                VARCHAR2 (1);
   v_posted_date                  VARCHAR2 (17);
   v_beftxn_topupcard_ledgerbal   VARCHAR2 (22);
   v_topupcard_ledgerbal          VARCHAR2 (22);
   v_beftxn_topupcard_acctbal     VARCHAR2 (22);
   v_topupcard_acctbal            VARCHAR2 (22);
   v_preauth_expry_date           VARCHAR2 (15);      --modified by Pankaj S.
   v_topup_acctno                 VARCHAR2 (20); 
   v_preauth_validflag            VARCHAR2 (1);
   v_expiry_flag                  VARCHAR2 (1);
   v_completion_flag              VARCHAR2 (1);
   v_pend_holdamt                 VARCHAR2 (22);
   v_transaction_flag             VARCHAR2 (3 BYTE);
   v_length_check                 VARCHAR2 (1000);
   v_chk_date                     DATE;
   v_chk_time                     DATE;
   v_chk_datetime                 DATE;
   v_chk_num                      NUMBER;
   v_chk_amt                      NUMBER;
   v_chk_char                     VARCHAR2 (10);
   v_sqlerr                       CLOB;
   v_orgnl_delv_chnl              varchar2(2);
   v_orgnl_tran_code              VARCHAR2 (10 Byte);
   v_reverse_fee_amt              NUMBER (6,2);

   --SN Parameters Added By Dhiraj Gaikwad
   v_timestamp varchar2(19) ;
   v_mobile_number varchar2(40);
   v_device_id  varchar2(40);
   v_chk_timestamp timestamp ;
   v_customer_username       VARCHAR2 (50);

	v_store_address1 cms_transaction_log_dtl.ctd_store_address1%type;
	v_store_address2 cms_transaction_log_dtl.ctd_store_address2%type;
	v_store_city     cms_transaction_log_dtl.ctd_store_city%type;
	v_store_state    cms_transaction_log_dtl.ctd_store_state%type;
	v_store_zip      cms_transaction_log_dtl.ctd_store_zip%type;
	v_optn_phno2     cms_transaction_log_dtl.ctd_optn_phno2%type;
	v_email          cms_transaction_log_dtl.ctd_email%type;
	v_optn_email     cms_transaction_log_dtl.ctd_optn_email%type;

	V_TAXPREPARE_ID      cms_transaction_log_dtl.CTD_TAXPREPARE_ID%type;
    V_MMPOSREASON_CODE        cms_transaction_log_dtl.CTD_REASON_CODE%type;
    V_MMPOS_ALERT_OPTIN  cms_transaction_log_dtl.CTD_ALERT_OPTIN%type;
	V_STORE_ID    transactionlog.STORE_ID%type ;
	V_CVV_VERIFICATIONTYPE    transactionlog.CVV_VERIFICATIONTYPE%type ;
	V_REQ_RESP_CODE cms_transaction_log_dtl.CTD_REQ_RESP_CODE%type;
	V_COUNTRY_CODE varchar2(4);
   --EN Parameters Added By Dhiraj Gaikwad
BEGIN
   prm_errmsg := 'OK';

   --Sn Modified on 02_Aug_2013
   --IF SUBSTR (prm_file_name, 1, INSTR (prm_file_name, '_', 1)) <> 'TRAN_'
   IF SUBSTR (prm_file_name, INSTR (prm_file_name, '_', 1)+1, (INSTR (prm_file_name, '_', 1,2)-INSTR (prm_file_name, '_', 1))) <> 'TRAN_'
   --En Modified on 02_Aug_2013
   THEN
      prm_errmsg := 'Invalid file for Transaction data.';
      RAISE exp_reject_record;
   END IF;

   BEGIN
      SELECT COUNT (1)
        INTO v_file_chk
        FROM migr_file_detl
       WHERE mfd_file_name = prm_file_name AND mfd_file_load_flag = 'S';

      IF v_file_chk != 0
      THEN
         prm_errmsg := 'File already processed.';
         RAISE exp_reject_record;
      END IF;
   EXCEPTION
      WHEN exp_reject_record
      THEN
         RAISE;
      WHEN OTHERS
      THEN
         prm_errmsg :=
               'Error while selecting file name ' || SUBSTR (SQLERRM, 1, 200);
         RAISE exp_reject_record;
   END;

   IF UTL_FILE.is_open (v_file_handle)
   THEN
      UTL_FILE.fclose (v_file_handle);
   END IF;

   v_file_handle := UTL_FILE.fopen ('DIR_TRAN', prm_file_name, 'R',32767);
   UTL_FILE.get_line (v_file_handle, v_filebuffer);            --to get header
   v_header := v_filebuffer;
   v_header_cnt :=
                  SUBSTR (v_filebuffer, INSTR (v_filebuffer, '_', -1, 1) + 1,
                          8);
                                             ---to get count present in header
--  dbms_output.put_line(v_header_cnt);
   v_header_file :=
      SUBSTR (SUBSTR (v_filebuffer, INSTR (v_filebuffer, '_', 1) + 1),
              1,
                INSTR (SUBSTR (v_filebuffer, INSTR (v_filebuffer, '_', 1) + 1),
                       '_',
                       -1
                      )
              - 1
             );                             --to extract file name from header

   IF SUBSTR (prm_file_name, 1, INSTR (prm_file_name, '_', 1,2) - 1) <>  --modified on 02_Aug_2013
                                                                 v_header_file
   THEN
      prm_errmsg := 'filename and header not matched';

      IF UTL_FILE.is_open (v_file_handle)
      THEN
         UTL_FILE.fclose (v_file_handle);
      END IF;

      RAISE exp_reject_record;
   END IF;

   ---Sn to count number lines in file excluding header and footer
   LOOP
      UTL_FILE.get_line (v_file_handle, v_filebuffer);
      EXIT WHEN SUBSTR (v_filebuffer, 1, 3) = 'FF_';
      n := n + 1;
--      IF   LENGTH (TRIM(v_filebuffer))
--         - LENGTH (TRIM (REPLACE (v_filebuffer, '|', ''))) <> 84
   END LOOP;

   ---En to count number lines in file excluding header and footer
   IF n <> TO_NUMBER (v_header_cnt, 999999)
   THEN
      prm_errmsg := 'Record count not matched';

      IF UTL_FILE.is_open (v_file_handle)
      THEN
         UTL_FILE.fclose (v_file_handle);
      END IF;

      RAISE exp_reject_record;
   END IF;

   v_file_handle := UTL_FILE.fopen ('DIR_TRAN', prm_file_name, 'R',32767);
   UTL_FILE.get_line (v_file_handle, v_filebuffer);

   ---Sn to create records in migration table
   LOOP
      v_mesg_type := NULL;
      v_rrn := NULL;
      v_delivery_channel := NULL;
      v_terminal_id := NULL;
      v_transaction_code := NULL;
      v_transaction_type := NULL;
      v_transaction_mode := NULL;
      v_response_code := NULL;
      v_business_date := NULL;
      v_business_time := NULL;
      v_card_no := NULL;
      v_beneficiary_card_no := NULL;
      v_total_amount := NULL;
      v_merchant_name := NULL;
      v_merchant_city := NULL;
      v_mcccode := NULL;
      v_currency_code := NULL;
      v_atm_namelocation := NULL;
      v_amount := NULL;
      v_preauth_datetime := NULL;
      v_stan := NULL;
      v_tranfee_amount := NULL;
      v_servicetax_amount := NULL;
      v_tran_rev_flag := NULL;
      v_account_number := NULL;
      v_orgnl_cardnumber := NULL;
      v_orgnl_rrn := NULL;
      v_orgnl_businessdate := NULL;
      v_orgnl_businesstime := NULL;
      v_orgnl_terminalid := NULL;
      v_reversal_code := NULL;
      v_proxy_number := NULL;
      v_account_balance := NULL;
      v_ledger_balance := NULL;
      v_ach_filename := NULL;
      v_return_achfilename := NULL;
      v_odfi := NULL;
      v_rdfi := NULL;
      v_sec_codes := NULL;
      v_imp_date := NULL;
      v_process_date := NULL;
      v_effective_date := NULL;
      v_auth_id := NULL;
      v_beforetxn_ledger_bal := NULL;
      v_beforetxn_avail_bal := NULL;
      v_ach_transactiontype_id := NULL;
      v_incoming_crfile_id := NULL;
      v_ind_idnum := NULL;
      v_ind_name := NULL;
      v_ach_id := NULL;
      v_ipaddress := NULL;
      v_ani := NULL;
      v_dni := NULL;
      v_card_status := NULL;
      v_waiver_amount := NULL;
      v_international_ind := NULL;
      v_crdr_flag := NULL;
      v_incremental_ind := NULL;
      v_partialauth_ind := NULL;
      v_completion_count := NULL;
      v_lastcompletion_ind := NULL;
      v_preauth_expryperiod := NULL;
      v_merc_floorlimit_ind := NULL;
      v_addr_verification_ind := NULL;
      v_narration := NULL;
      v_dispute_flag := NULL;
      v_reason_code := NULL;
      v_remark := NULL;
      v_dispute_reason := NULL;
      v_dispute_remark := NULL;
      v_matchcomp_flag := NULL;
      v_c2ctxn_status := NULL;
      v_posted_date := NULL;
      v_beftxn_topupcard_ledgerbal := NULL;
      v_topupcard_ledgerbal := NULL;
      v_beftxn_topupcard_acctbal := NULL;
      v_topupcard_acctbal := NULL;
      v_preauth_expry_date := NULL;
      v_topup_acctno := NULL;
      v_preauth_validflag := NULL;
      v_expiry_flag := NULL;
      v_completion_flag := NULL;
      v_pend_holdamt := NULL;
      v_transaction_flag := NULL;
      v_orgnl_delv_chnl  := NULL;
      v_orgnl_tran_code  := NULL;
      v_reverse_fee_amt  := NULL;
      v_errmsg := 'OK';
      v_length_check := NULL;
	  V_MMPOSREASON_CODE:=NULL;
       --SN Parameters Added By Dhiraj Gaikwad
        v_timestamp :=NULL ;
       --EN Parameters Added By Dhiraj Gaikwad
      UTL_FILE.get_line (v_file_handle, v_filebuffer);
      EXIT WHEN SUBSTR (v_filebuffer, 1, 3) = 'FF_';
      i := i + 1;

      BEGIN
         SELECT mct_ctrl_numb
           INTO v_record_numb
           FROM migr_ctrl_table
          WHERE mct_ctrl_key = 'TRANSACTION_DATA' AND mct_inst_code = 1;
      EXCEPTION
         WHEN NO_DATA_FOUND
         THEN
            prm_errmsg := 'Control number not defined for transaction data.';
            RAISE exp_reject_record;
         WHEN OTHERS
         THEN
            prm_errmsg :=
                  'Error while getting control number '
               || SUBSTR (SQLERRM, 1, 200);
            RAISE exp_reject_record;
      END;

      BEGIN
            -- transactionlog
         --dbms_output.put_line(i);
         --dbms_output.put_line(v_filebuffer);
         IF LENGTH (TRIM (v_filebuffer)) = 0
         THEN
            v_errmsg := 'No Record Found At Line no ' || v_record_numb;
            RAISE exp_loop_reject_record;
         END IF;

         IF regexp_count (v_filebuffer, '[|]', 1) <> 106         THEN
            v_errmsg :=
                   'Invalid number of columns at record no ' || v_record_numb;
            RAISE exp_loop_reject_record;
         END IF;

         v_error_flag := 1;

         BEGIN
            v_length_check :=
               TRIM (SUBSTR (v_filebuffer, 1, INSTR (v_filebuffer, '|', 1) - 1)
                    );

            IF v_length_check IS NULL
            THEN
               v_errmsg :=
                       v_errmsg || '--' || 'Transaction message type is NULL';
            --RAISE exp_loop_reject_record;
            ELSE
               IF LENGTH (v_length_check) > 10
               THEN
                  v_errmsg :=
                        v_errmsg
                     || '--'
                     || 'Transaction message type length is invalid';
               ELSE
                  /*----- Message Type -------*/
                  v_mesg_type := v_length_check;
               /*----- Message Type -------*/
               END IF;

               IF REGEXP_LIKE (v_length_check, '[A-Z,a-z]')
               THEN
                  v_errmsg :=
                        v_errmsg
                     || '-- '
                     || 'Invalid value for message type '
                     || v_length_check;
               END IF;
            END IF;
         EXCEPTION
            WHEN OTHERS
            THEN
               v_errmsg :=
                         v_errmsg || '--' || 'message type validation failed';
               v_sqlerr :=
                     v_sqlerr
                  || '-- '
                  || 'Data validation failed for field no '
                  || v_error_flag
                  || ' with tech error '
                  || SUBSTR (SQLERRM, 1, 100);
         END;

         v_error_flag := 2;

                     BEGIN
                        v_length_check :=
                           TRIM (SUBSTR (v_filebuffer,
                                         INSTR (v_filebuffer, '|', 1) + 1,
                                           (INSTR (v_filebuffer, '|', 1, 2) - 1
                                           )
                                         - INSTR (v_filebuffer, '|', 1)
                                        )
                                );

                        IF v_length_check IS NULL
                        THEN
                           v_errmsg := v_errmsg || '-- ' || 'Transaction RRN is NULL';
                        --RAISE exp_loop_reject_record;
                        ELSE
                           IF LENGTH (v_length_check) > 20
                           THEN
                              v_errmsg :=
                                 v_errmsg || '-- ' || 'Transaction RRN length is invalid';
                           ELSE
                              /*----- RRN -------*/
                              v_rrn := v_length_check;
                           /*----- RRN -------*/
                           END IF;
                        END IF;
                     EXCEPTION
                        WHEN OTHERS
                        THEN
                           v_errmsg := v_errmsg || '--' || 'RRN validation failed';
                           v_sqlerr :=
                                 v_sqlerr
                              || '-- '
                              || 'Data validation failed for field no '
                              || v_error_flag
                              || ' with tech error '
                              || SUBSTR (SQLERRM, 1, 100);
                     END;

         v_error_flag := 3;

         BEGIN
            v_length_check :=
               TRIM (SUBSTR (v_filebuffer,
                             INSTR (v_filebuffer, '|', 1, 2) + 1,
                               (INSTR (v_filebuffer, '|', 1, 3) - 1
                               )
                             - INSTR (v_filebuffer, '|', 1, 2)
                            )
                    );

            IF v_length_check IS NULL
            THEN
               v_errmsg :=
                  v_errmsg || '-- ' || 'Transaction Delivery Channel is NULL';
            --RAISE exp_loop_reject_record;
            ELSE
               IF LENGTH (v_length_check) > 2
               THEN
                  v_errmsg :=
                        v_errmsg
                     || '-- '
                     || 'Transaction Delivery Channel length is invalid';
               ELSE
                  /*----- Delivery Channel -------*/
                  v_delivery_channel := v_length_check;
               /*----- Delivery Channel -------*/
               END IF;

               IF REGEXP_LIKE (v_length_check, '[A-Z,a-z]')
               THEN
                  v_errmsg :=
                        v_errmsg
                     || '-- '
                     || 'Invalid value for deliery channel '
                     || v_length_check;
               END IF;
            END IF;
         EXCEPTION
            WHEN OTHERS
            THEN
               v_errmsg :=
                      v_errmsg || '--' || 'Deliery channel validation failed';
               v_sqlerr :=
                     v_sqlerr
                  || '-- '
                  || 'Data validation failed for field no '
                  || v_error_flag
                  || ' with tech error '
                  || SUBSTR (SQLERRM, 1, 100);
         END;

         v_error_flag := 4;

         BEGIN
            v_length_check :=
               TRIM (SUBSTR (v_filebuffer,
                             INSTR (v_filebuffer, '|', 1, 3) + 1,
                               (INSTR (v_filebuffer, '|', 1, 4) - 1
                               )
                             - INSTR (v_filebuffer, '|', 1, 3)
                            )
                    );

            IF v_length_check IS NOT NULL
            THEN
              IF v_delivery_channel = '11' THEN
			  IF LENGTH (v_length_check) > 21
               THEN
                  v_errmsg :=
                         v_errmsg || '-- ' || 'Terminal Id length is invalid';
               ELSE
                  /*----- Termnal id -------*/
                  v_terminal_id := v_length_check;
               /*----- Termnal id -------*/
               END IF;
			   ELSE
			    IF LENGTH (v_length_check) > 20
               THEN
                  v_errmsg :=
                         v_errmsg || '-- ' || 'Terminal Id length is invalid';
               ELSE
                  /*----- Termnal id -------*/
                  v_terminal_id := v_length_check;
               /*----- Termnal id -------*/
               END IF;
			   END IF  ;
            END IF;
         EXCEPTION
            WHEN OTHERS
            THEN
               v_errmsg :=
                          v_errmsg || '--' || 'Terminal Id validation failed';
               v_sqlerr :=
                     v_sqlerr
                  || '-- '
                  || 'Data validation failed for field no '
                  || v_error_flag
                  || ' with tech error '
                  || SUBSTR (SQLERRM, 1, 100);
         END;

         v_error_flag := 5;

         BEGIN
            v_length_check :=
               TRIM (SUBSTR (v_filebuffer,
                             INSTR (v_filebuffer, '|', 1, 4) + 1,
                               (INSTR (v_filebuffer, '|', 1, 5) - 1
                               )
                             - INSTR (v_filebuffer, '|', 1, 4)
                            )
                    );

            IF v_length_check IS NULL
            THEN
               v_errmsg := v_errmsg || '-- ' || 'Transaction Code is NULL';
            --RAISE exp_loop_reject_record;
            ELSE
               IF LENGTH (v_length_check) > 2
               THEN
                  v_errmsg :=
                     v_errmsg || '-- '
                     || 'Transaction Code length is invalid';
               ELSE
                  /*----- Transaction code -------*/
                  v_transaction_code := v_length_check;
               /*----- Transaction code -------*/
               END IF;
            END IF;
         EXCEPTION
            WHEN OTHERS
            THEN
               v_errmsg :=
                     v_errmsg || '--' || 'Transaction Code validation failed';
               v_sqlerr :=
                     v_sqlerr
                  || '-- '
                  || 'Data validation failed for field no '
                  || v_error_flag
                  || ' with tech error '
                  || SUBSTR (SQLERRM, 1, 100);
         END;

         v_error_flag := 6;

         BEGIN
            v_length_check :=
               TRIM (SUBSTR (v_filebuffer,
                             INSTR (v_filebuffer, '|', 1, 5) + 1,
                               (INSTR (v_filebuffer, '|', 1, 6) - 1
                               )
                             - INSTR (v_filebuffer, '|', 1, 5)
                            )
                    );

            IF v_length_check IS NULL
            THEN
               v_errmsg := v_errmsg || '-- ' || 'Transaction Type is NULL';
            --RAISE exp_loop_reject_record;
            ELSE
               IF LENGTH (v_length_check) > 2
               THEN
                  v_errmsg :=
                     v_errmsg || '-- '
                     || 'Transaction Type length is invalid';
               ELSE
                  /*----- Transaction Type -------*/
                  v_transaction_type := v_length_check;
               /*----- Transaction Type -------*/
               END IF;

               IF REGEXP_LIKE (v_length_check, '[A-Z,a-z]')
               THEN
                  v_errmsg :=
                        v_errmsg
                     || '-- '
                     || 'Invalid value for transaction type '
                     || v_length_check;
               END IF;
            END IF;
         EXCEPTION
            WHEN OTHERS
            THEN
               v_errmsg :=
                     v_errmsg || '--' || 'Transaction Type validation failed';
               v_sqlerr :=
                     v_sqlerr
                  || '-- '
                  || 'Data validation failed for field no '
                  || v_error_flag
                  || ' with tech error '
                  || SUBSTR (SQLERRM, 1, 100);
         END;

         v_error_flag := 7;

         BEGIN
            v_length_check :=
               TRIM (SUBSTR (v_filebuffer,
                             INSTR (v_filebuffer, '|', 1, 6) + 1,
                               (INSTR (v_filebuffer, '|', 1, 7) - 1
                               )
                             - INSTR (v_filebuffer, '|', 1, 6)
                            )
                    );

            IF v_length_check IS NULL
            THEN
               v_errmsg := v_errmsg || '-- ' || 'Transaction Mode is NULL';
            --RAISE exp_loop_reject_record;
            ELSE
               IF LENGTH (v_length_check) > 2
               THEN
                  v_errmsg :=
                     v_errmsg || '-- '
                     || 'Transaction Mode length is invalid';
               ELSE
                  /*----- Transaction Mode -------*/
                  v_transaction_mode := v_length_check;
               /*----- Transaction Mode -------*/
               END IF;

               IF REGEXP_LIKE (v_length_check, '[A-Z,a-z]')
               THEN
                  v_errmsg :=
                        v_errmsg
                     || '-- '
                     || 'Invalid value for transaction mode '
                     || v_length_check;
               END IF;
            END IF;
         EXCEPTION
            WHEN OTHERS
            THEN
               v_errmsg :=
                     v_errmsg || '--' || 'Transaction Mode validation failed';
               v_sqlerr :=
                     v_sqlerr
                  || '-- '
                  || 'Data validation failed for field no '
                  || v_error_flag
                  || ' with tech error '
                  || SUBSTR (SQLERRM, 1, 100);
         END;

         v_error_flag := 8;

         BEGIN
            v_length_check :=
               TRIM (SUBSTR (v_filebuffer,
                             INSTR (v_filebuffer, '|', 1, 7) + 1,
                               (INSTR (v_filebuffer, '|', 1, 8) - 1
                               )
                             - INSTR (v_filebuffer, '|', 1, 7)
                            )
                    );

            IF v_length_check IS NULL
            THEN
               v_errmsg := v_errmsg || '-- ' || 'Response Code is NULL';
            --RAISE exp_loop_reject_record;
            ELSE
               IF LENGTH (v_length_check) > 7
               THEN
                  v_errmsg :=
                       v_errmsg || '-- ' || 'Response Code length is invalid';
               ELSE
                  /*----- Response Code -------*/
                  v_response_code := v_length_check;
               /*----- Response Code -------*/
               END IF;
            END IF;
         EXCEPTION
            WHEN OTHERS
            THEN
               v_errmsg :=
                        v_errmsg || '--' || 'Response Code validation failed';
               v_sqlerr :=
                     v_sqlerr
                  || '-- '
                  || 'Data validation failed for field no '
                  || v_error_flag
                  || ' with tech error '
                  || SUBSTR (SQLERRM, 1, 100);
         END;

         v_error_flag := 9;

         BEGIN
            v_length_check :=
               TRIM (SUBSTR (v_filebuffer,
                             INSTR (v_filebuffer, '|', 1, 8) + 1,
                               (INSTR (v_filebuffer, '|', 1, 9) - 1
                               )
                             - INSTR (v_filebuffer, '|', 1, 8)
                            )
                    );

            IF v_length_check IS NULL
            THEN
               v_errmsg := v_errmsg || '-- ' || 'Business Date is NULL';
            --RAISE exp_loop_reject_record;
            ELSE
               IF LENGTH (v_length_check) > 8
               THEN
                  v_errmsg :=
                       v_errmsg || '-- ' || 'Business Date length is invalid';
               ELSE
                  /*----- Business Date -------*/
                  v_business_date := v_length_check;
               /*----- Business Date -------*/
               END IF;
            END IF;

            IF v_length_check IS NOT NULL
            THEN
               BEGIN
                  v_chk_date := TO_DATE (v_length_check, 'yyyymmdd');
               EXCEPTION
                  WHEN OTHERS
                  THEN
                     v_errmsg :=
                           v_errmsg
                        || '-- '
                        || 'Invalid date format for Business Date '
                        || v_length_check;
               END;
            END IF;
         EXCEPTION
            WHEN OTHERS
            THEN
               v_errmsg :=
                        v_errmsg || '--' || 'Business Date validation failed';
               v_sqlerr :=
                     v_sqlerr
                  || '-- '
                  || 'Data validation failed for field no '
                  || v_error_flag
                  || ' with tech error '
                  || SUBSTR (SQLERRM, 1, 100);
         END;

         v_error_flag := 10;

         BEGIN
            v_length_check :=
               TRIM (SUBSTR (v_filebuffer,
                             INSTR (v_filebuffer, '|', 1, 9) + 1,
                               (INSTR (v_filebuffer, '|', 1, 10) - 1
                               )
                             - INSTR (v_filebuffer, '|', 1, 9)
                            )
                    );

            IF v_length_check IS NULL
            THEN
               v_errmsg := v_errmsg || '-- ' || 'Business Time is NULL';
            --RAISE exp_loop_reject_record;
            ELSE
               IF LENGTH (v_length_check) > 10
               THEN
                  v_errmsg :=
                       v_errmsg || '-- ' || 'Business Time length is invalid';
               ELSE
                  /*----- Business Time -------*/
                  v_business_time := v_length_check;
               /*----- Business Time -------*/
               END IF;
            END IF;

            IF v_length_check IS NOT NULL
            THEN
               BEGIN
                  v_chk_time := TO_DATE (v_length_check, 'hh24miss');
               EXCEPTION
                  WHEN OTHERS
                  THEN
                     v_errmsg :=
                           v_errmsg
                        || '-- '
                        || 'Invalid time format for Business time '
                        || v_length_check;
               END;
            END IF;
         EXCEPTION
            WHEN OTHERS
            THEN
               v_errmsg :=
                        v_errmsg || '--' || 'Business time validation failed';
               v_sqlerr :=
                     v_sqlerr
                  || '-- '
                  || 'Data validation failed for field no '
                  || v_error_flag
                  || ' with tech error '
                  || SUBSTR (SQLERRM, 1, 100);
         END;

         v_error_flag := 11;

         BEGIN
            v_length_check :=
               TRIM (SUBSTR (v_filebuffer,
                             INSTR (v_filebuffer, '|', 1, 10) + 1,
                               (INSTR (v_filebuffer, '|', 1, 11) - 1
                               )
                             - INSTR (v_filebuffer, '|', 1, 10)
                            )
                    );

            IF v_length_check IS NULL
            THEN
               v_errmsg := v_errmsg || '-- ' || 'Card Number is NULL';
            --RAISE exp_loop_reject_record;
            ELSE
               IF LENGTH (v_length_check) > 19
               THEN
                  v_errmsg :=
                         v_errmsg || '-- ' || 'Card Number length is invalid';
               ELSE
                  /*----- Card Number -------*/
                  v_card_no := v_length_check;
               /*----- Card Number-------*/
               END IF;

               IF REGEXP_LIKE (v_length_check, '[A-Z,a-z]')
               THEN
                  v_errmsg :=
                        v_errmsg
                     || '-- '
                     || 'Invalid value for card number '
                     || v_length_check;
               END IF;
            END IF;
         EXCEPTION
            WHEN OTHERS
            THEN
               v_errmsg :=
                         v_errmsg || '--' || 'card number validation failed';
               v_sqlerr :=
                     v_sqlerr
                  || '-- '
                  || 'Data validation failed for field no '
                  || v_error_flag
                  || ' with tech error '
                  || SUBSTR (SQLERRM, 1, 100);
         END;

         v_error_flag := 12;

         BEGIN
            v_length_check :=
               TRIM (SUBSTR (v_filebuffer,
                             INSTR (v_filebuffer, '|', 1, 11) + 1,
                               (INSTR (v_filebuffer, '|', 1, 12) - 1
                               )
                             - INSTR (v_filebuffer, '|', 1, 11)
                            )
                    );

            IF v_length_check IS NOT NULL
            THEN
               IF LENGTH (v_length_check) > 19
               THEN
                  v_errmsg :=
                        v_errmsg
                     || '--'
                     || 'Topup card number length is invalid'; --Error message modified by Pankaj S. on 25-Sep-2013
               ELSE
                  /*----- Beneficiary Card Number -------*/
                  v_beneficiary_card_no := v_length_check;
               /*----- Beneficiary Card Number-------*/
               END IF;

               IF REGEXP_LIKE (v_length_check, '[A-Z,a-z]')
               THEN
                  v_errmsg :=
                        v_errmsg
                     || '-- '
                     || 'Invalid value for Topup card number '
                     || v_length_check;
               END IF;
            END IF;
         EXCEPTION
            WHEN OTHERS
            THEN
               v_errmsg :=
                   v_errmsg || '--' || 'Topup card number validation failed';
               v_sqlerr :=
                     v_sqlerr
                  || '-- '
                  || 'Data validation failed for field no '
                  || v_error_flag
                  || ' with tech error '
                  || SUBSTR (SQLERRM, 1, 100);
         END;

         v_error_flag := 13;

         BEGIN
            v_length_check :=
               TRIM (SUBSTR (v_filebuffer,
                             INSTR (v_filebuffer, '|', 1, 12) + 1,
                               (INSTR (v_filebuffer, '|', 1, 13) - 1
                               )
                             - INSTR (v_filebuffer, '|', 1, 12)
                            )
                    );

            IF v_length_check IS NULL
            THEN
               v_errmsg := v_errmsg || '-- ' || 'Total Amount is NULL';
            --RAISE exp_loop_reject_record;
            ELSE
               IF LENGTH (v_length_check) > 21
               THEN
                  v_errmsg :=
                         v_errmsg || '--' || 'Total Amount length is invalid'; --Error message modified by Pankaj S. on 25-Sep-2013
               ELSE
                  /*----- Total Amount -------*/
                  v_total_amount := v_length_check;
               /*----- Total Amount -------*/
               END IF;
            END IF;

            IF v_length_check IS NOT NULL
            THEN
               BEGIN
                  v_chk_amt := TO_NUMBER (v_length_check);
               EXCEPTION
                  WHEN OTHERS
                  THEN
                     v_errmsg :=
                           v_errmsg
                        || '-- '
                        || 'Invalid amount value for total amount '
                        || v_length_check;
               END;

               BEGIN
                  v_chk_amt :=
                            TO_NUMBER (v_length_check, 999999999999999999.99);
               EXCEPTION
                  WHEN OTHERS
                  THEN
                     v_errmsg :=
                        v_errmsg || '--' || 'total amount precision exceeded';
               END;
            END IF;
         EXCEPTION
            WHEN OTHERS
            THEN
               v_errmsg :=
                         v_errmsg || '--' || 'total amount validation failed';
               v_sqlerr :=
                     v_sqlerr
                  || '-- '
                  || 'Data validation failed for field no '
                  || v_error_flag
                  || ' with tech error '
                  || SUBSTR (SQLERRM, 1, 100);
         END;

         v_error_flag := 14;

         BEGIN
            v_length_check :=
               TRIM (SUBSTR (v_filebuffer,
                             INSTR (v_filebuffer, '|', 1, 13) + 1,
                               (INSTR (v_filebuffer, '|', 1, 14) - 1
                               )
                             - INSTR (v_filebuffer, '|', 1, 13)
                            )
                    );

            IF v_length_check IS NOT NULL
            THEN
               IF LENGTH (v_length_check) > 30
               THEN
                  v_errmsg :=
                        v_errmsg || '--' || 'Merchant name length is invalid'; --Error message modified by Pankaj S. on 25-Sep-2013
               ELSE
                  /*----- Merchant Name -------*/
                  v_merchant_name := v_length_check;
               /*----- Merchant Name -------*/
               END IF;
            END IF;
         EXCEPTION
            WHEN OTHERS
            THEN
               v_errmsg :=
                        v_errmsg || '--' || 'Merchant name validation failed'; --Error message modified by Pankaj S. on 25-Sep-2013
               v_sqlerr :=
                     v_sqlerr
                  || '-- '
                  || 'Data validation failed for field no '
                  || v_error_flag
                  || ' with tech error '
                  || SUBSTR (SQLERRM, 1, 100);
         END;

         v_error_flag := 15;

         BEGIN
            v_length_check :=
               TRIM (SUBSTR (v_filebuffer,
                             INSTR (v_filebuffer, '|', 1, 14) + 1,
                               (INSTR (v_filebuffer, '|', 1, 15) - 1
                               )
                             - INSTR (v_filebuffer, '|', 1, 14)
                            )
                    );

            IF v_length_check IS NOT NULL
            THEN
               IF LENGTH (v_length_check) > 30
               THEN
                  v_errmsg :=
                        v_errmsg || '--' || 'Merchant city lenght is invalid'; --Error message modified by Pankaj S. on 25-Sep-2013
               ELSE
                  /*----- Merchant City -------*/
                  v_merchant_city := v_length_check;
               /*----- Merchant City -------*/
               END IF;
            END IF;
         EXCEPTION
            WHEN OTHERS
            THEN
               v_errmsg :=
                        v_errmsg || '--' || 'Merchant city validation failed';
               v_sqlerr :=
                     v_sqlerr
                  || '-- '
                  || 'Data validation failed for field no '
                  || v_error_flag
                  || ' with tech error '
                  || SUBSTR (SQLERRM, 1, 100);
         END;

         v_error_flag := 16;

         BEGIN
            v_length_check :=
               TRIM (SUBSTR (v_filebuffer,
                             INSTR (v_filebuffer, '|', 1, 15) + 1,
                               (INSTR (v_filebuffer, '|', 1, 16) - 1
                               )
                             - INSTR (v_filebuffer, '|', 1, 15)
                            )
                    );

            IF v_length_check IS NOT NULL
            THEN
               IF LENGTH (v_length_check) > 4
               THEN
                  v_errmsg := v_errmsg || '--' || 'MCCCODE lenght is invalid';
               ELSE
                  /*----- MCC Code -------*/
                  v_mcccode := v_length_check;
               /*----- MCC Code -------*/
               END IF;
            END IF;
         EXCEPTION
            WHEN OTHERS
            THEN
               v_errmsg := v_errmsg || '--' || 'MCCCODE validation failed';
               v_sqlerr :=
                     v_sqlerr
                  || '-- '
                  || 'Data validation failed for field no '
                  || v_error_flag
                  || ' with tech error '
                  || SUBSTR (SQLERRM, 1, 100);
         END;

         v_error_flag := 17;

         BEGIN
            v_length_check :=
               TRIM (SUBSTR (v_filebuffer,
                             INSTR (v_filebuffer, '|', 1, 16) + 1,
                               (INSTR (v_filebuffer, '|', 1, 17) - 1
                               )
                             - INSTR (v_filebuffer, '|', 1, 16)
                            )
                    );

            IF v_length_check IS NOT NULL
            THEN
               IF LENGTH (v_length_check) > 4
               THEN
                  v_errmsg :=
                        v_errmsg || '--' || 'Currency code length is invalid';  --Error message modified by Pankaj S. on 25-Sep-2013
               ELSE
                  /*----- Currency Code -------*/
                  v_currency_code := v_length_check;
               /*----- Currency Code -------*/
               END IF;

               IF REGEXP_LIKE (v_length_check, '[A-Z,a-z]')
               THEN
                  v_errmsg :=
                        v_errmsg
                     || '-- '
                     || 'Invalid value for currency code '
                     || v_length_check;
               END IF;
            END IF;
         EXCEPTION
            WHEN OTHERS
            THEN
               v_errmsg :=
                        v_errmsg || '--' || 'currency code validation failed';
               v_sqlerr :=
                     v_sqlerr
                  || '-- '
                  || 'Data validation failed for field no '
                  || v_error_flag
                  || ' with tech error '
                  || SUBSTR (SQLERRM, 1, 100);
         END;

         v_error_flag := 18;

         BEGIN
            v_length_check :=
               TRIM (SUBSTR (v_filebuffer,
                             INSTR (v_filebuffer, '|', 1, 17) + 1,
                               (INSTR (v_filebuffer, '|', 1, 18) - 1
                               )
                             - INSTR (v_filebuffer, '|', 1, 17)
                            )
                    );

            IF v_length_check IS NOT NULL
            THEN
               IF LENGTH (v_length_check) > 40
               THEN
                  v_errmsg :=
                     v_errmsg || '--' || 'ATM_NAMELOCATION length is invalid';  --Error message modified by Pankaj S. on 25-Sep-2013
               ELSE
                  /*----- ATM Name Location-------*/
                  v_atm_namelocation := v_length_check;
               /*----- ATM Name Location -------*/
               END IF;
            END IF;
         EXCEPTION
            WHEN OTHERS
            THEN
               v_errmsg :=
                     v_errmsg || '--' || 'ATM_NAMELOCATION validation failed';
               v_sqlerr :=
                     v_sqlerr
                  || '-- '
                  || 'Data validation failed for field no '
                  || v_error_flag
                  || ' with tech error '
                  || SUBSTR (SQLERRM, 1, 100);
         END;

         v_error_flag := 19;

         BEGIN
            v_length_check :=
               TRIM (SUBSTR (v_filebuffer,
                             INSTR (v_filebuffer, '|', 1, 18) + 1,
                               (INSTR (v_filebuffer, '|', 1, 19) - 1
                               )
                             - INSTR (v_filebuffer, '|', 1, 18)
                            )
                    );

            IF v_length_check IS NULL
            THEN
               v_errmsg :=
                     v_errmsg || '-- ' || 'Actual Transaction Amount is NULL';
            --RAISE exp_loop_reject_record;
            ELSE
               IF LENGTH (v_length_check) > 21
               THEN
                  v_errmsg :=
                     v_errmsg || '--'
                     || 'Transaction Amount length is invalid';  --Error message modified by Pankaj S. on 25-Sep-2013
               ELSE
                  /*----- Amount -------*/
                  v_amount := v_length_check;
               /*----- Amount -------*/
               END IF;

               BEGIN
                  v_chk_amt := TO_NUMBER (v_length_check);
               EXCEPTION
                  WHEN OTHERS
                  THEN
                     v_errmsg :=
                           v_errmsg
                        || '-- '
                        || 'Invalid amount value for txn amount '
                        || v_length_check;
               END;

               BEGIN
                  v_chk_amt :=
                            TO_NUMBER (v_length_check, 999999999999999999.99);
               EXCEPTION
                  WHEN OTHERS
                  THEN
                     v_errmsg :=
                              v_errmsg || '--' || 'Amount precision exceeded';
               END;
            END IF;
         EXCEPTION
            WHEN OTHERS
            THEN
               v_errmsg := v_errmsg || '--' || 'amount validation failed';
               v_sqlerr :=
                     v_sqlerr
                  || '-- '
                  || 'Data validation failed for field no '
                  || v_error_flag
                  || ' with tech error '
                  || SUBSTR (SQLERRM, 1, 100);
         END;

         v_error_flag := 20;

         BEGIN
            v_length_check :=
               TRIM (SUBSTR (v_filebuffer,
                             INSTR (v_filebuffer, '|', 1, 19) + 1,
                               (INSTR (v_filebuffer, '|', 1, 20) - 1
                               )
                             - INSTR (v_filebuffer, '|', 1, 19)
                            )
                    );

            IF v_length_check IS NOT NULL
            THEN
               IF LENGTH (v_length_check) > 19
               THEN
                  v_errmsg :=
                     v_errmsg || '--' || 'Preauth datetime length is invalid';  --Error message modified by Pankaj S. on 25-Sep-2013
               ELSE
                  /*----- Preauth Date Time -------*/
                  v_preauth_datetime := v_length_check;
               /*----- Preauth Date Time -------*/
               END IF;

               BEGIN
                  v_chk_datetime :=
                              TO_DATE (v_length_check, 'yyyymmdd hh24:mi:ss');
               EXCEPTION
                  WHEN OTHERS
                  THEN
                     v_errmsg :=
                           v_errmsg
                        || '-- '
                        || 'Invalid date time format for preauth date time '
                        || v_length_check;
               END;
            END IF;
         EXCEPTION
            WHEN OTHERS
            THEN
               v_errmsg :=
                    v_errmsg || '--' || 'preauth date time validation failed';
               v_sqlerr :=
                     v_sqlerr
                  || '-- '
                  || 'Data validation failed for field no '
                  || v_error_flag
                  || ' with tech error '
                  || SUBSTR (SQLERRM, 1, 100);
         END;

         v_error_flag := 21;

         BEGIN
            v_length_check :=
               TRIM (SUBSTR (v_filebuffer,
                             INSTR (v_filebuffer, '|', 1, 20) + 1,
                               (INSTR (v_filebuffer, '|', 1, 21) - 1
                               )
                             - INSTR (v_filebuffer, '|', 1, 20)
                            )
                    );

            IF v_length_check IS NOT NULL
            THEN
               IF LENGTH (v_length_check) > 12
               THEN
                  v_errmsg := v_errmsg || '--' || 'STAN length is invalid'; --Error message modified by Pankaj S. on 25-Sep-2013
               ELSE
                  /*----- Stan -------*/
                  v_stan := v_length_check;
               /*----- Stan -------*/
               END IF;
            END IF;
         EXCEPTION
            WHEN OTHERS
            THEN
               v_errmsg := v_errmsg || '--' || 'STAN validation failed';
               v_sqlerr :=
                     v_sqlerr
                  || '-- '
                  || 'Data validation failed for field no '
                  || v_error_flag
                  || ' with tech error '
                  || SUBSTR (SQLERRM, 1, 100);
         END;

         v_error_flag := 22;

         BEGIN
            v_length_check :=
               TRIM (SUBSTR (v_filebuffer,
                             INSTR (v_filebuffer, '|', 1, 21) + 1,
                               (INSTR (v_filebuffer, '|', 1, 22) - 1
                               )
                             - INSTR (v_filebuffer, '|', 1, 21)
                            )
                    );

            IF v_length_check IS NULL
            THEN
               v_errmsg :=
                        v_errmsg || '-- ' || 'Transaction Fee Amount is NULL';
            --RAISE exp_loop_reject_record;
            ELSE
               IF LENGTH (v_length_check) > 30
               THEN
                  v_errmsg :=
                       v_errmsg || '--' || 'TRANFEE_AMOUNT length is invalid'; --Error message modified by Pankaj S. on 25-Sep-2013
               ELSE
                  /*----- Transaction Fee Amount -------*/
                  v_tranfee_amount := v_length_check;
               /*----- Transaction Fee Amount -------*/
               END IF;

               BEGIN
                  v_chk_amt := TO_NUMBER (v_length_check);
               EXCEPTION
                  WHEN OTHERS
                  THEN
                     v_errmsg :=
                           v_errmsg
                        || '-- '
                        || 'Invalid amount value for txn fee amount '
                        || v_length_check;
               END;

               BEGIN
                  v_chk_amt :=
                            TO_NUMBER (v_length_check, 999999999999999999.99);
               EXCEPTION
                  WHEN OTHERS
                  THEN
                     v_errmsg :=
                           v_errmsg
                        || '-- '
                        || 'txn fee amount precision exceeded';
               END;
            END IF;
         EXCEPTION
            WHEN OTHERS
            THEN
               v_errmsg :=
                       v_errmsg || '--' || 'txn fee amount validation failed';
               v_sqlerr :=
                     v_sqlerr
                  || '-- '
                  || 'Data validation failed for field no '
                  || v_error_flag
                  || ' with tech error '
                  || SUBSTR (SQLERRM, 1, 100);
         END;

         v_error_flag := 23;

         BEGIN
            v_length_check :=
               TRIM (SUBSTR (v_filebuffer,
                             INSTR (v_filebuffer, '|', 1, 22) + 1,
                               (INSTR (v_filebuffer, '|', 1, 23) - 1
                               )
                             - INSTR (v_filebuffer, '|', 1, 22)
                            )
                    );

            IF v_length_check IS NULL
            THEN
               --SN:Modified for Galileo changes //Default value of $0 to be used for servicetax_amount
               --v_errmsg := v_errmsg || '-- ' || 'Service Tax Amount is NULL';
                 v_length_check :=0;
               --EN:Modified for Galileo changes //Default value of $0 to be used for servicetax_amount
            --RAISE exp_loop_reject_record;
            --ELSE
            END IF;
            
               IF LENGTH (v_length_check) > 7
               THEN
                  v_errmsg :=
                     v_errmsg || '--'
                     || 'Service Tax Amount length is invalid';  --Error message modified by Pankaj S. on 25-Sep-2013
               ELSE
                  /*----- Service Tax Fee Amount -------*/
                  v_servicetax_amount := v_length_check;
               /*----- Service Tax Fee Amount -------*/
               END IF;

               BEGIN
                  v_chk_amt := TO_NUMBER (v_length_check);
               EXCEPTION
                  WHEN OTHERS
                  THEN
                     v_errmsg :=
                           v_errmsg
                        || '-- '
                        || 'Invalid amount value for service tax '
                        || v_length_check;
               END;

               BEGIN
                  v_chk_amt :=
                            TO_NUMBER (v_length_check, 999999999999999999.99);
               EXCEPTION
                  WHEN OTHERS
                  THEN
                     v_errmsg :=
                           v_errmsg
                        || '--'
                        || 'service tax amount precision exceeded';
               END;
            --END IF;
         EXCEPTION
            WHEN OTHERS
            THEN
               v_errmsg :=
                   v_errmsg || '--' || 'service tax amount validation failed';
               v_sqlerr :=
                     v_sqlerr
                  || '-- '
                  || 'Data validation failed for field no '
                  || v_error_flag
                  || ' with tech error '
                  || SUBSTR (SQLERRM, 1, 100);
         END;

         v_error_flag := 24;

         BEGIN
            v_length_check :=
               TRIM (SUBSTR (v_filebuffer,
                             INSTR (v_filebuffer, '|', 1, 23) + 1,
                               (INSTR (v_filebuffer, '|', 1, 24) - 1
                               )
                             - INSTR (v_filebuffer, '|', 1, 23)
                            )
                    );

            IF v_length_check IS NOT NULL
            THEN
               IF LENGTH (v_length_check) > 1
               THEN
                  v_errmsg :=
                        v_errmsg || '--' || 'Transaction reversal flag length is invalid';  --Error message modified by Pankaj S. on 25-Sep-2013
               ELSE
                  /*----- Tran Reversal Flag -------*/
                  v_tran_rev_flag := v_length_check;
               /*----- Tran Reversal Flag -------*/
               END IF;

               BEGIN
                  v_chk_num := TO_NUMBER (v_length_check);
               EXCEPTION
                  WHEN OTHERS
                  THEN
                     v_errmsg :=
                           v_errmsg
                        || '-- '
                        || 'Invalid value for reversal flag '
                        || v_length_check;
               END;
            END IF;
         EXCEPTION
            WHEN OTHERS
            THEN
               v_errmsg :=
                        v_errmsg || '--' || 'reversal flag validation failed';
               v_sqlerr :=
                     v_sqlerr
                  || '-- '
                  || 'Data validation failed for field no '
                  || v_error_flag
                  || ' with tech error '
                  || SUBSTR (SQLERRM, 1, 100);
         END;

         v_error_flag := 25;

         BEGIN
            v_length_check :=
               TRIM (SUBSTR (v_filebuffer,
                             INSTR (v_filebuffer, '|', 1, 24) + 1,
                               (INSTR (v_filebuffer, '|', 1, 25) - 1
                               )
                             - INSTR (v_filebuffer, '|', 1, 24)
                            )
                    );

            IF v_length_check IS NULL
            THEN
               v_errmsg := v_errmsg || '-- ' || 'Account Number is NULL';
            --RAISE exp_loop_reject_record;
            ELSE
               IF LENGTH (v_length_check) > 30
               THEN
                  v_errmsg :=
                       v_errmsg || '--' || 'Account number length is invalid'; --Error message modified by Pankaj S. on 25-Sep-2013
               ELSE
                  /*----- Account Number -------*/
                  v_account_number := v_length_check;
               /*----- Account Number -------*/
               END IF;

               IF REGEXP_LIKE (v_length_check, '[A-Z,a-z]')
               THEN
                  v_errmsg :=
                        v_errmsg
                     || '-- '
                     || 'Invalid value for account number '
                     || v_length_check;
               END IF;
            END IF;
         EXCEPTION
            WHEN OTHERS
            THEN
               v_errmsg :=
                       v_errmsg || '--' || 'account number validation failed';
               v_sqlerr :=
                     v_sqlerr
                  || '-- '
                  || 'Data validation failed for field no '
                  || v_error_flag
                  || ' with tech error '
                  || SUBSTR (SQLERRM, 1, 100);
         END;

         v_error_flag := 26;

         BEGIN
            v_length_check :=
               TRIM (SUBSTR (v_filebuffer,
                             INSTR (v_filebuffer, '|', 1, 25) + 1,
                               (INSTR (v_filebuffer, '|', 1, 26) - 1
                               )
                             - INSTR (v_filebuffer, '|', 1, 25)
                            )
                    );

            IF v_length_check IS NOT NULL
            THEN
               IF LENGTH (v_length_check) > 19
               THEN
                  v_errmsg :=
                     v_errmsg || '--' || 'ORGNL_CARDNUMBER lenght is invalid';
               ELSE
                  /*----- Original Card Number -------*/
                  v_orgnl_cardnumber := v_length_check;
               /*----- Original Card Number-------*/
               END IF;

               IF REGEXP_LIKE (v_length_check, '[A-Z,a-z]')
               THEN
                  v_errmsg :=
                        v_errmsg
                     || '-- '
                     || 'Invalid value for ORGNL card number '
                     || v_length_check;
               END IF;
            END IF;
         EXCEPTION
            WHEN OTHERS
            THEN
               v_errmsg :=
                    v_errmsg || '--' || 'ORGNL card number validation failed';
               v_sqlerr :=
                     v_sqlerr
                  || '-- '
                  || 'Data validation failed for field no '
                  || v_error_flag
                  || ' with tech error '
                  || SUBSTR (SQLERRM, 1, 100);
         END;

         v_error_flag := 27;

         BEGIN
            v_length_check :=
               TRIM (SUBSTR (v_filebuffer,
                             INSTR (v_filebuffer, '|', 1, 26) + 1,
                               (INSTR (v_filebuffer, '|', 1, 27) - 1
                               )
                             - INSTR (v_filebuffer, '|', 1, 26)
                            )
                    );

            IF v_length_check IS NOT NULL
            THEN
               IF LENGTH (v_length_check) > 15
               THEN
                  v_errmsg :=
                            v_errmsg || '--' || 'ORGNL_RRN length is invalid';  --Error message modified by Pankaj S. on 25-Sep-2013
               ELSE
                  /*----- Original RRN -------*/
                  v_orgnl_rrn := v_length_check;
               /*----- Original RRN -------*/
               END IF;
            END IF;
         EXCEPTION
            WHEN OTHERS
            THEN
               v_errmsg := v_errmsg || '--' || 'ORGNL_RRN validation failed';
               v_sqlerr :=
                     v_sqlerr
                  || '-- '
                  || 'Data validation failed for field no '
                  || v_error_flag
                  || ' with tech error '
                  || SUBSTR (SQLERRM, 1, 100);
         END;

         v_error_flag := 28;

         BEGIN
            v_length_check :=
               TRIM (SUBSTR (v_filebuffer,
                             INSTR (v_filebuffer, '|', 1, 27) + 1,
                               (INSTR (v_filebuffer, '|', 1, 28) - 1
                               )
                             - INSTR (v_filebuffer, '|', 1, 27)
                            )
                    );

            IF v_length_check IS NOT NULL
            THEN
               IF LENGTH (v_length_check) > 8
               THEN
                  v_errmsg :=
                     v_errmsg || '--'
                     || 'ORGNL_BUSINESS DATE length is invalid'; --Error message modified by Pankaj S. on 25-Sep-2013
               ELSE
                  /*----- Original Business date  -------*/
                  v_orgnl_businessdate := v_length_check;
               /*----- Original Business date -------*/
               END IF;

               BEGIN
                  v_chk_date := TO_DATE (v_length_check, 'yyyymmdd');
               EXCEPTION
                  WHEN OTHERS
                  THEN
                     v_errmsg :=
                           v_errmsg
                        || '-- '
                        || 'Invalid date format for ORGNL Business date '
                        || v_length_check;
               END;
            END IF;
         EXCEPTION
            WHEN OTHERS
            THEN
               v_errmsg :=
                  v_errmsg || '--' || 'ORGNL Business date validation failed';
               v_sqlerr :=
                     v_sqlerr
                  || '-- '
                  || 'Data validation failed for field no '
                  || v_error_flag
                  || ' with tech error '
                  || SUBSTR (SQLERRM, 1, 100);
         END;

         v_error_flag := 29;

         BEGIN
            v_length_check :=
               TRIM (SUBSTR (v_filebuffer,
                             INSTR (v_filebuffer, '|', 1, 28) + 1,
                               (INSTR (v_filebuffer, '|', 1, 29) - 1
                               )
                             - INSTR (v_filebuffer, '|', 1, 28)
                            )
                    );

            IF v_length_check IS NOT NULL
            THEN
               IF LENGTH (v_length_check) > 10
               THEN
                  v_errmsg :=
                     v_errmsg || '--'
                     || 'ORGNL_BUSINESS TIME length is invalid'; --Error message modified by Pankaj S. on 25-Sep-2013
               ELSE
                  /*----- Original Business Time  -------*/
                  v_orgnl_businesstime := v_length_check;
               /*----- Original Business Time -------*/
               END IF;

               BEGIN
                  v_chk_time := TO_DATE (v_length_check, 'hh24miss');
               EXCEPTION
                  WHEN OTHERS
                  THEN
                     v_errmsg :=
                           v_errmsg
                        || '-- '
                        || 'Invalid time format for ORGNL Business time '
                        || v_length_check;
               END;
            END IF;
         EXCEPTION
            WHEN OTHERS
            THEN
               v_errmsg :=
                  v_errmsg || '--' || 'ORGNL Business time validation failed';
               v_sqlerr :=
                     v_sqlerr
                  || '-- '
                  || 'Data validation failed for field no '
                  || v_error_flag
                  || ' with tech error '
                  || SUBSTR (SQLERRM, 1, 100);
         END;

         v_error_flag := 30;

         BEGIN
            v_length_check :=
               TRIM (SUBSTR (v_filebuffer,
                             INSTR (v_filebuffer, '|', 1, 29) + 1,
                               (INSTR (v_filebuffer, '|', 1, 30) - 1
                               )
                             - INSTR (v_filebuffer, '|', 1, 29)
                            )
                    );

            IF v_length_check IS NOT NULL
            THEN
               IF LENGTH (v_length_check) > 21
               THEN
                  v_errmsg :=
                     v_errmsg || '--' || 'ORGNL_TERMINALID length is invalid';  --Error message modified by Pankaj S. on 25-Sep-2013
               ELSE
                  /*----- Original Termindal Id  -------*/
                  v_orgnl_terminalid := v_length_check;
               /*----- Original Termindal Id  -------*/
               END IF;
            END IF;
         EXCEPTION
            WHEN OTHERS
            THEN
               v_errmsg :=
                     v_errmsg || '--' || 'ORGNL TERMINALID validation failed';
               v_sqlerr :=
                     v_sqlerr
                  || '-- '
                  || 'Data validation failed for field no '
                  || v_error_flag
                  || ' with tech error '
                  || SUBSTR (SQLERRM, 1, 100);
         END;

         v_error_flag := 31;

         BEGIN
            v_length_check :=
               TRIM (SUBSTR (v_filebuffer,
                             INSTR (v_filebuffer, '|', 1, 30) + 1,
                               (INSTR (v_filebuffer, '|', 1, 31) - 1
                               )
                             - INSTR (v_filebuffer, '|', 1, 30)
                            )
                    );

            IF v_length_check IS NULL
            THEN
               v_errmsg := v_errmsg || '-- ' || 'Reversal Code is NULL';
            --RAISE exp_loop_reject_record;
            ELSE
               IF LENGTH (v_length_check) > 4 -- Changed from 3 to 4 , as we are receiving reversal code as 0400 -- 02-AUG-2013
               THEN
                  v_errmsg :=
                        v_errmsg || '--' || 'REVERSAL_CODE length is invalid'; --Error message modified by Pankaj S. on 25-Sep-2013
               ELSE
                  /*----- Reversal Code -------*/
                  v_reversal_code := v_length_check;
               /*----- Reversal Code  -------*/
               END IF;

               BEGIN
                  v_chk_num := TO_NUMBER (v_length_check);
               EXCEPTION
                  WHEN OTHERS
                  THEN
                     v_errmsg :=
                           v_errmsg
                        || '-- '
                        || 'Invalid value for reversal code '
                        || v_length_check;
               END;
            END IF;
         EXCEPTION
            WHEN OTHERS
            THEN
               v_errmsg :=
                        v_errmsg || '--' || 'reversal code validation failed';
               v_sqlerr :=
                     v_sqlerr
                  || '-- '
                  || 'Data validation failed for field no '
                  || v_error_flag
                  || ' with tech error '
                  || SUBSTR (SQLERRM, 1, 100);
         END;

         v_error_flag := 32;

         BEGIN
            v_length_check :=
               TRIM (SUBSTR (v_filebuffer,
                             INSTR (v_filebuffer, '|', 1, 31) + 1,
                               (INSTR (v_filebuffer, '|', 1, 32) - 1
                               )
                             - INSTR (v_filebuffer, '|', 1, 31)
                            )
                    );

            IF v_length_check IS NOT NULL
            THEN
               IF LENGTH (v_length_check) > 19
               THEN
                  v_errmsg :=
                         v_errmsg || '--' || 'PROXY_NUMBER length is invalid';  --Error message modified by Pankaj S. on 25-Sep-2013
               ELSE
                  /*----- PROXY_NUMBER  -------*/
                  v_proxy_number := v_length_check;
               /*----- PROXY_NUMBER  -------*/
               END IF;

               IF REGEXP_LIKE (v_length_check, '[A-Z,a-z]')
               THEN
                  v_errmsg :=
                        v_errmsg
                     || '-- '
                     || 'Invalid  value for proxy number '
                     || v_length_check;
               END IF;
            END IF;
         EXCEPTION
            WHEN OTHERS
            THEN
               v_errmsg :=
                         v_errmsg || '--' || 'proxy number validation failed';
               v_sqlerr :=
                     v_sqlerr
                  || '-- '
                  || 'Data validation failed for field no '
                  || v_error_flag
                  || ' with tech error '
                  || SUBSTR (SQLERRM, 1, 100);
         END;

         v_error_flag := 33;

         BEGIN
            v_length_check :=
               TRIM (SUBSTR (v_filebuffer,
                             INSTR (v_filebuffer, '|', 1, 32) + 1,
                               (INSTR (v_filebuffer, '|', 1, 33) - 1
                               )
                             - INSTR (v_filebuffer, '|', 1, 32)
                            )
                    );

            IF v_length_check IS NULL
            THEN
               v_errmsg := v_errmsg || '-- ' || 'Account Balance is NULL';
            --RAISE exp_loop_reject_record;
            ELSE
               IF LENGTH (v_length_check) > 21
               THEN
                  v_errmsg :=
                      v_errmsg || '--' || 'Account balance length is invalid'; --Error message modified by Pankaj S. on 25-Sep-2013
               ELSE
                  /*----- Account Balance  -------*/
                  v_account_balance := v_length_check;
               /*----- Account Balance  -------*/
               END IF;

               BEGIN
                  v_chk_amt := TO_NUMBER (v_length_check);
               EXCEPTION
                  WHEN OTHERS
                  THEN
                     v_errmsg :=
                           v_errmsg
                        || '-- '
                        || 'Invalid value for account balance '
                        || v_length_check;
               END;

               BEGIN
                  v_chk_amt :=
                            TO_NUMBER (v_length_check, 999999999999999999.99);
               EXCEPTION
                  WHEN OTHERS
                  THEN
                     v_errmsg :=
                           v_errmsg
                        || '--'
                        || 'account balance precision exceeded';
               END;
            END IF;
         EXCEPTION
            WHEN OTHERS
            THEN
               v_errmsg :=
                      v_errmsg || '--' || 'account balance validation failed';
               v_sqlerr :=
                     v_sqlerr
                  || '-- '
                  || 'Data validation failed for field no '
                  || v_error_flag
                  || ' with tech error '
                  || SUBSTR (SQLERRM, 1, 100);
         END;

         v_error_flag := 34;

         BEGIN
            v_length_check :=
               TRIM (SUBSTR (v_filebuffer,
                             INSTR (v_filebuffer, '|', 1, 33) + 1,
                               (INSTR (v_filebuffer, '|', 1, 34) - 1
                               )
                             - INSTR (v_filebuffer, '|', 1, 33)
                            )
                    );

            IF v_length_check IS NULL
            THEN
               v_errmsg := v_errmsg || '-- ' || 'Ledger Balance is NULL';
            --RAISE exp_loop_reject_record;
            ELSE
               IF LENGTH (v_length_check) > 21
               THEN
                  v_errmsg :=
                       v_errmsg || '--' || 'Ledger Balance length is invalid'; --Error message modified by Pankaj S. on 25-Sep-2013
               ELSE
                  /*----- Ledger Balance  -------*/
                  v_ledger_balance := v_length_check;
               /*----- Ledger Balance -------*/
               END IF;

               BEGIN
                  v_chk_amt := TO_NUMBER (v_length_check);
               EXCEPTION
                  WHEN OTHERS
                  THEN
                     v_errmsg :=
                           v_errmsg
                        || '-- '
                        || 'Invalid value for ledger balance '
                        || v_length_check;
               END;

               BEGIN
                  v_chk_amt :=
                            TO_NUMBER (v_length_check, 999999999999999999.99);
               EXCEPTION
                  WHEN OTHERS
                  THEN
                     v_errmsg :=
                        v_errmsg || '--'
                        || 'ledger balance precision exceeded';
               END;
            END IF;
         EXCEPTION
            WHEN OTHERS
            THEN
               v_errmsg :=
                       v_errmsg || '--' || 'ledger balance validation failed';
               v_sqlerr :=
                     v_sqlerr
                  || '-- '
                  || 'Data validation failed for field no '
                  || v_error_flag
                  || ' with tech error '
                  || SUBSTR (SQLERRM, 1, 100);
         END;

         v_error_flag := 35;

         BEGIN
            v_length_check :=
               TRIM (SUBSTR (v_filebuffer,
                             INSTR (v_filebuffer, '|', 1, 34) + 1,
                               (INSTR (v_filebuffer, '|', 1, 35) - 1
                               )
                             - INSTR (v_filebuffer, '|', 1, 34)
                            )
                    );

            IF v_length_check IS NOT NULL
            THEN
               IF LENGTH (v_length_check) > 40
               THEN
                  v_errmsg :=
                         v_errmsg || '--' || 'ACH_FILENAME length is invalid'; --Error message modified by Pankaj S. on 25-Sep-2013
               ELSE
                  /*----- ACH_FILENAME  -------*/
                  v_ach_filename := v_length_check;
               /*----- ACH_FILENAME  -------*/
               END IF;
            END IF;
         EXCEPTION
            WHEN OTHERS
            THEN
               v_errmsg :=
                         v_errmsg || '--' || 'ACH_FILENAME validation failed';
               v_sqlerr :=
                     v_sqlerr
                  || '-- '
                  || 'Data validation failed for field no '
                  || v_error_flag
                  || ' with tech error '
                  || SUBSTR (SQLERRM, 1, 100);
         END;

         v_error_flag := 36;

         BEGIN
            v_return_achfilename :=
               TRIM (SUBSTR (v_filebuffer,
                             INSTR (v_filebuffer, '|', 1, 35) + 1,
                               (INSTR (v_filebuffer, '|', 1, 36) - 1
                               )
                             - INSTR (v_filebuffer, '|', 1, 35)
                            )
                    );

            IF v_length_check IS NOT NULL
            THEN
               IF LENGTH (v_length_check) > 40
               THEN
                  v_errmsg :=
                     v_errmsg || '--'
                     || 'RETURN_ACHFILENAME length is invalid'; --Error message modified by Pankaj S. on 25-Sep-2013
               ELSE
                  /*----- RETURN_ACHFILENAME  -------*/
                  v_return_achfilename := v_length_check;
               /*----- RETURN_ACHFILENAME  -------*/
               END IF;
            END IF;
         EXCEPTION
            WHEN OTHERS
            THEN
               v_errmsg :=
                   v_errmsg || '--' || 'RETURN_ACHFILENAME validation failed';
               v_sqlerr :=
                     v_sqlerr
                  || '-- '
                  || 'Data validation failed for field no '
                  || v_error_flag
                  || ' with tech error '
                  || SUBSTR (SQLERRM, 1, 100);
         END;

         v_error_flag := 37;

         BEGIN
            v_length_check :=
               TRIM (SUBSTR (v_filebuffer,
                             INSTR (v_filebuffer, '|', 1, 36) + 1,
                               (INSTR (v_filebuffer, '|', 1, 37) - 1
                               )
                             - INSTR (v_filebuffer, '|', 1, 36)
                            )
                    );

            IF v_length_check IS NOT NULL
            THEN
               IF LENGTH (v_length_check) > 30
               THEN
                  v_errmsg := v_errmsg || '--' || 'ODFI length is invalid'; --Error message modified by Pankaj S. on 25-Sep-2013
               ELSE
                  /*----- ODFI  -------*/
                  v_odfi := v_length_check;
               /*----- ODFI  -------*/
               END IF;
            END IF;
         EXCEPTION
            WHEN OTHERS
            THEN
               v_errmsg := v_errmsg || '--' || 'ODFI validation failed';
               v_sqlerr :=
                     v_sqlerr
                  || '-- '
                  || 'Data validation failed for field no '
                  || v_error_flag
                  || ' with tech error '
                  || SUBSTR (SQLERRM, 1, 100);
         END;

         v_error_flag := 38;

         BEGIN
            v_length_check :=
               TRIM (SUBSTR (v_filebuffer,
                             INSTR (v_filebuffer, '|', 1, 37) + 1,
                               (INSTR (v_filebuffer, '|', 1, 38) - 1
                               )
                             - INSTR (v_filebuffer, '|', 1, 37)
                            )
                    );

            IF v_length_check IS NOT NULL
            THEN
               IF LENGTH (v_length_check) > 30
               THEN
                  v_errmsg := v_errmsg || '--' || 'RDFI length is invalid'; --Error message modified by Pankaj S. on 25-Sep-2013
               ELSE
                  /*----- RDFI  -------*/
                  v_rdfi := v_length_check;
               /*----- RDFI  -------*/
               END IF;
            END IF;
         EXCEPTION
            WHEN OTHERS
            THEN
               v_errmsg := v_errmsg || '--' || 'RDFI validation failed';
               v_sqlerr :=
                     v_sqlerr
                  || '-- '
                  || 'Data validation failed for field no '
                  || v_error_flag
                  || ' with tech error '
                  || SUBSTR (SQLERRM, 1, 100);
         END;

         v_error_flag := 39;

         BEGIN
            v_length_check :=
               TRIM (SUBSTR (v_filebuffer,
                             INSTR (v_filebuffer, '|', 1, 38) + 1,
                               (INSTR (v_filebuffer, '|', 1, 39) - 1
                               )
                             - INSTR (v_filebuffer, '|', 1, 38)
                            )
                    );

            IF v_length_check IS NOT NULL
            THEN
               IF LENGTH (v_length_check) > 30
               THEN
                  v_errmsg :=
                            v_errmsg || '--' || 'SEC_CODES length is invalid'; --Error message modified by Pankaj S. on 25-Sep-2013
               ELSE
                  /*----- SEC_CODES  -------*/
                  v_sec_codes := v_length_check;
               /*----- SEC_CODES  -------*/
               END IF;
            END IF;
         EXCEPTION
            WHEN OTHERS
            THEN
               v_errmsg := v_errmsg || '--' || 'SEC_CODES validation failed';
               v_sqlerr :=
                     v_sqlerr
                  || '-- '
                  || 'Data validation failed for field no '
                  || v_error_flag
                  || ' with tech error '
                  || SUBSTR (SQLERRM, 1, 100);
         END;

         v_error_flag := 40;

         BEGIN
            v_length_check :=
               TRIM (SUBSTR (v_filebuffer,
                             INSTR (v_filebuffer, '|', 1, 39) + 1,
                               (INSTR (v_filebuffer, '|', 1, 40) - 1
                               )
                             - INSTR (v_filebuffer, '|', 1, 39)
                            )
                    );

            IF v_length_check IS NOT NULL
            THEN
               IF LENGTH (v_length_check) > 30
               THEN
                  v_errmsg :=
                             v_errmsg || '--' || 'IMP_DATE length is invalid';
               ELSE
                  /*----- IMP_DATE  -------*/
                  v_imp_date := v_length_check;
               /*----- IMP_DATE  -------*/
               END IF;

               BEGIN
                  v_chk_date := TO_DATE (v_length_check, 'yyyymmdd');
               EXCEPTION
                  WHEN OTHERS
                  THEN
                     v_errmsg :=
                           v_errmsg
                        || '-- '
                        || 'Invalid date format for IMP Date '
                        || v_length_check;
               END;
            END IF;
         EXCEPTION
            WHEN OTHERS
            THEN
               v_errmsg := v_errmsg || '--' || 'IMP Date validation failed';
               v_sqlerr :=
                     v_sqlerr
                  || '-- '
                  || 'Data validation failed for field no '
                  || v_error_flag
                  || ' with tech error '
                  || SUBSTR (SQLERRM, 1, 100);
         END;

         v_error_flag := 41;

         BEGIN
            v_process_date :=
               (SUBSTR (v_filebuffer,
                        INSTR (v_filebuffer, '|', 1, 40) + 1,
                          (INSTR (v_filebuffer, '|', 1, 41) - 1
                          )
                        - INSTR (v_filebuffer, '|', 1, 40)
                       )
               );

            IF v_length_check IS NOT NULL
            THEN
               IF LENGTH (v_length_check) > 30
               THEN
                  v_errmsg :=
                         v_errmsg || '--' || 'Process date length is invalid';  --Error message modified by Pankaj S. on 25-Sep-2013
               ELSE
                  /*----- PROCESS_DATE  -------*/
                  v_process_date := v_length_check;
               /*----- PROCESS_DATE  -------*/
               END IF;

               BEGIN
                  v_chk_date := TO_DATE (v_length_check, 'yyyymmdd');
               EXCEPTION
                  WHEN OTHERS
                  THEN
                     v_errmsg :=
                           v_errmsg
                        || '-- '
                        || 'Invalid date format for Process Date '
                        || v_length_check;
               END;
            END IF;
         EXCEPTION
            WHEN OTHERS
            THEN
               v_errmsg :=
                         v_errmsg || '--' || 'Process Date validation failed';
               v_sqlerr :=
                     v_sqlerr
                  || '-- '
                  || 'Data validation failed for field no '
                  || v_error_flag
                  || ' with tech error '
                  || SUBSTR (SQLERRM, 1, 100);
         END;

         v_error_flag := 42;

         BEGIN
            v_length_check :=
               TRIM (SUBSTR (v_filebuffer,
                             INSTR (v_filebuffer, '|', 1, 41) + 1,
                               (INSTR (v_filebuffer, '|', 1, 42) - 1
                               )
                             - INSTR (v_filebuffer, '|', 1, 41)
                            )
                    );

            IF v_length_check IS NOT NULL
            THEN
               IF LENGTH (v_length_check) > 30
               THEN
                  v_errmsg :=
                       v_errmsg || '--' || 'Effective date length is invalid'; --Error message modified by Pankaj S. on 25-Sep-2013
               ELSE
                  /*----- PROCESS_DATE  -------*/
                  v_effective_date := v_length_check;
               /*----- PROCESS_DATE  -------*/
               END IF;

               BEGIN
                  v_chk_date := TO_DATE (v_length_check, 'yyyymmdd');
               EXCEPTION
                  WHEN OTHERS
                  THEN
                     v_errmsg :=
                           v_errmsg
                        || '-- '
                        || 'Invalid date format for Effective Date '
                        || v_length_check;
               END;
            END IF;
         EXCEPTION
            WHEN OTHERS
            THEN
               v_errmsg :=
                       v_errmsg || '--' || 'Effective Date validation failed';
               v_sqlerr :=
                     v_sqlerr
                  || '-- '
                  || 'Data validation failed for field no '
                  || v_error_flag
                  || ' with tech error '
                  || SUBSTR (SQLERRM, 1, 100);
         END;


         v_error_flag := 43;

           BEGIN                                   -- Added on 02-Aug-2013 as per discussion

              SELECT LPAD
                        (seq_auth_id.NEXTVAL, 6, '0')
                INTO v_auth_id
                FROM DUAL;
           EXCEPTION
              WHEN OTHERS
              THEN
                 v_errmsg := v_errmsg || '--' ||'Authid generation failed ';

                 v_sqlerr := v_sqlerr || '--' ||'Error while generating authid ' || SUBSTR (SQLERRM, 1, 300);

           END;                                  -- Added on 02-Aug-2013 as per discussion


       /*                   -- Commented on 02-Aug-2013 as per discussion
         BEGIN
            v_length_check :=
               TRIM (SUBSTR (v_filebuffer,
                             INSTR (v_filebuffer, '|', 1, 42) + 1,
                               (INSTR (v_filebuffer, '|', 1, 43) - 1
                               )
                             - INSTR (v_filebuffer, '|', 1, 42)
                            )
                    );

            IF v_length_check IS NULL
            THEN
               v_errmsg := v_errmsg || '-- ' || 'Auth Id is NULL';
            --RAISE exp_loop_reject_record;
            ELSE
               IF LENGTH (v_length_check) > 14
               THEN
                  v_errmsg := v_errmsg || '--' || 'AUTH_ID lenght is invalid';
               ELSE
                  ----- AUTH_ID  -------
                  v_auth_id := v_length_check;
                ----- AUTH_ID  -------
               END IF;
            END IF;
         EXCEPTION
            WHEN OTHERS
            THEN
               v_errmsg := v_errmsg || '--' || 'AUTH_ID validation failed';
               v_sqlerr :=
                     v_sqlerr
                  || '-- '
                  || 'Data validation failed for field no '
                  || v_error_flag
                  || ' with tech error '
                  || SUBSTR (SQLERRM, 1, 100);
         END;
        */                   -- Commented on 02-Aug-2013 as per discussion

        /*                  -- Commented as per discussion 02-Aug-2013
         v_error_flag := 44;

         BEGIN
            v_length_check :=
               TRIM (SUBSTR (v_filebuffer,
                             INSTR (v_filebuffer, '|', 1, 43) + 1,
                               (INSTR (v_filebuffer, '|', 1, 44) - 1
                               )
                             - INSTR (v_filebuffer, '|', 1, 43)
                            )
                    );

            IF v_length_check IS NULL
            THEN
               v_errmsg :=
                     v_errmsg
                  || '-- '
                  || 'Ledger Balance before transaction is NULL';
            --RAISE exp_loop_reject_record;
            ELSE
               IF LENGTH (v_length_check) > 21
               THEN
                  v_errmsg :=
                        v_errmsg
                     || '--'
                     || 'BEFORETXN_LEDGER_BAL lenght is invalid';
               ELSE
                  ----- BEFORETXN_LEDGER_BAL  -------
                  v_beforetxn_ledger_bal := v_length_check;
               ----- BEFORETXN_LEDGER_BAL  -------
               END IF;

               BEGIN
                  v_chk_amt := TO_NUMBER (v_length_check);
               EXCEPTION
                  WHEN OTHERS
                  THEN
                     v_errmsg :=
                           v_errmsg
                        || '-- '
                        || 'Invalid amount value for Before Txn ledger balance '
                        || v_length_check;
               END;

               BEGIN
                  v_chk_amt :=
                            TO_NUMBER (v_length_check, 999999999999999999.99);
               EXCEPTION
                  WHEN OTHERS
                  THEN
                     v_errmsg :=
                           v_errmsg
                        || '--'
                        || 'Before Txn ledger balance precision exceeded';
               END;
            END IF;
         EXCEPTION
            WHEN OTHERS
            THEN
               v_errmsg :=
                     v_errmsg
                  || '--'
                  || 'Before Txn ledger balance validation failed';
               v_sqlerr :=
                     v_sqlerr
                  || '-- '
                  || 'Data validation failed for field no '
                  || v_error_flag
                  || ' with tech error '
                  || SUBSTR (SQLERRM, 1, 100);
         END;

        */        -- Commented as per discussion 02-Aug-2013

        /*        -- Commented as per discussion 02-Aug-2013
         v_error_flag := 45;

         BEGIN
            v_length_check :=
               TRIM (SUBSTR (v_filebuffer,
                             INSTR (v_filebuffer, '|', 1, 44) + 1,
                               (INSTR (v_filebuffer, '|', 1, 45) - 1
                               )
                             - INSTR (v_filebuffer, '|', 1, 44)
                            )
                    );

            IF v_length_check IS NULL
            THEN
               v_errmsg :=
                     v_errmsg
                  || '-- '
                  || 'Available Balance before transaction is NULL';
            --RAISE exp_loop_reject_record;
            ELSE
               IF LENGTH (v_length_check) > 21
               THEN
                  v_errmsg :=
                        v_errmsg
                     || '--'
                     || 'BEFORETXN_AVAIL_BAL lenght is invalid';
               ELSE
                  ----- BEFORETXN_AVAIL_BAL  -------
                  v_beforetxn_avail_bal := v_length_check;
               ----- BEFORETXN_AVAIL_BAL  -------
               END IF;

               BEGIN
                  v_chk_amt := TO_NUMBER (v_length_check);
               EXCEPTION
                  WHEN OTHERS
                  THEN
                     v_errmsg :=
                           v_errmsg
                        || '-- '
                        || 'Invalid amount value for Before Txn account balance '
                        || v_length_check;
               END;

               BEGIN
                  v_chk_amt :=
                            TO_NUMBER (v_length_check, 999999999999999999.99);
               EXCEPTION
                  WHEN OTHERS
                  THEN
                     v_errmsg :=
                           v_errmsg
                        || '--'
                        || 'Before Txn account balance precision exceeded';
               END;
            END IF;
         EXCEPTION
            WHEN OTHERS
            THEN
               v_errmsg :=
                     v_errmsg
                  || '--'
                  || 'Before Txn account balance validation failed';
               v_sqlerr :=
                     v_sqlerr
                  || '-- '
                  || 'Data validation failed for field no '
                  || v_error_flag
                  || ' with tech error '
                  || SUBSTR (SQLERRM, 1, 100);
         END;
        */        -- Commented as per discussion 02-Aug-2013

         v_error_flag := 46;

         BEGIN
            v_length_check :=
               TRIM (SUBSTR (v_filebuffer,
                             INSTR (v_filebuffer, '|', 1, 45) + 1,
                               (INSTR (v_filebuffer, '|', 1, 46) - 1
                               )
                             - INSTR (v_filebuffer, '|', 1, 45)
                            )
                    );

            IF v_length_check IS NOT NULL
            THEN
               IF LENGTH (v_length_check) > 20
               THEN
                  v_errmsg :=
                        v_errmsg
                     || '--'
                     || 'ACH_TRANSACTIONTYPE_ID length is invalid';
               ELSE
                  /*----- ACH_TRANSACTIONTYPE_ID  -------*/
                  v_ach_transactiontype_id := v_length_check;
               /*----- ACH_TRANSACTIONTYPE_ID  -------*/
               END IF;
            END IF;
         EXCEPTION
            WHEN OTHERS
            THEN
               v_errmsg :=
                     v_errmsg
                  || '--'
                  || 'ACH TRANSACTIONTYPE ID validation failed';
               v_sqlerr :=
                     v_sqlerr
                  || '-- '
                  || 'Data validation failed for field no '
                  || v_error_flag
                  || ' with tech error '
                  || SUBSTR (SQLERRM, 1, 100);
         END;

         v_error_flag := 47;

         BEGIN
            v_length_check :=
               TRIM (SUBSTR (v_filebuffer,
                             INSTR (v_filebuffer, '|', 1, 46) + 1,
                               (INSTR (v_filebuffer, '|', 1, 47) - 1
                               )
                             - INSTR (v_filebuffer, '|', 1, 46)
                            )
                    );

            IF v_length_check IS NOT NULL
            THEN
               IF LENGTH (v_length_check) > 20
               THEN
                  v_errmsg :=
                     v_errmsg || '--'
                     || 'INCOMING_CRFILE_ID length is invalid';
               ELSE
                  /*----- INCOMING_CRFILE_ID  -------*/
                  v_incoming_crfile_id := v_length_check;
               /*----- INCOMING_CRFILE_ID  -------*/
               END IF;
            END IF;
         EXCEPTION
            WHEN OTHERS
            THEN
               v_errmsg :=
                   v_errmsg || '--' || 'INCOMING CRFILE ID validation failed';
               v_sqlerr :=
                     v_sqlerr
                  || '-- '
                  || 'Data validation failed for field no '
                  || v_error_flag
                  || ' with tech error '
                  || SUBSTR (SQLERRM, 1, 100);
         END;

         v_error_flag := 48;

         BEGIN
            v_length_check :=
               TRIM (SUBSTR (v_filebuffer,
                             INSTR (v_filebuffer, '|', 1, 47) + 1,
                               (INSTR (v_filebuffer, '|', 1, 48) - 1
                               )
                             - INSTR (v_filebuffer, '|', 1, 47)
                            )
                    );

            IF v_length_check IS NOT NULL
            THEN
               IF LENGTH (v_length_check) > 15
               THEN
                  v_errmsg :=
                            v_errmsg || '--' || 'IND_IDNUM length is invalid';
               ELSE
                  /*----- IND_IDNUM  -------*/
                  v_ind_idnum := v_length_check;
               /*----- IND_IDNUM  -------*/
               END IF;
            END IF;
         EXCEPTION
            WHEN OTHERS
            THEN
               v_errmsg := v_errmsg || '--' || 'IND_IDNUM validation failed';
               v_sqlerr :=
                     v_sqlerr
                  || '-- '
                  || 'Data validation failed for field no '
                  || v_error_flag
                  || ' with tech error '
                  || SUBSTR (SQLERRM, 1, 100);
         END;

         v_error_flag := 49;

         BEGIN
            v_length_check :=
               TRIM (SUBSTR (v_filebuffer,
                             INSTR (v_filebuffer, '|', 1, 48) + 1,
                               (INSTR (v_filebuffer, '|', 1, 49) - 1
                               )
                             - INSTR (v_filebuffer, '|', 1, 48)
                            )
                    );

            IF v_length_check IS NOT NULL
            THEN
               IF LENGTH (v_length_check) > 25
               THEN
                  v_errmsg :=
                             v_errmsg || '--' || 'IND_NAME length is invalid';
               ELSE
                  /*----- IND_NAME  -------*/
                  v_ind_name := v_length_check;
               /*----- IND_NAME  -------*/
               END IF;
            END IF;
         EXCEPTION
            WHEN OTHERS
            THEN
               v_errmsg := v_errmsg || '--' || 'IND_NAME validation failed';
               v_sqlerr :=
                     v_sqlerr
                  || '-- '
                  || 'Data validation failed for field no '
                  || v_error_flag
                  || ' with tech error '
                  || SUBSTR (SQLERRM, 1, 100);
         END;

         v_error_flag := 50;

         BEGIN
            v_length_check :=
               TRIM (SUBSTR (v_filebuffer,
                             INSTR (v_filebuffer, '|', 1, 49) + 1,
                               (INSTR (v_filebuffer, '|', 1, 50) - 1
                               )
                             - INSTR (v_filebuffer, '|', 1, 49)
                            )
                    );

            IF v_length_check IS NOT NULL
            THEN
               IF LENGTH (v_length_check) > 10
               THEN
                  v_errmsg := v_errmsg || '--' || 'ACH_ID length is invalid';
               ELSE
                  /*----- ACH_ID  -------*/
                  v_ach_id := v_length_check;
               /*----- ACH_ID  -------*/
               END IF;
            END IF;
         EXCEPTION
            WHEN OTHERS
            THEN
               v_errmsg := v_errmsg || '--' || 'ACH_ID validation failed';
               v_sqlerr :=
                     v_sqlerr
                  || '-- '
                  || 'Data validation failed for field no '
                  || v_error_flag
                  || ' with tech error '
                  || SUBSTR (SQLERRM, 1, 100);
         END;

         v_error_flag := 51;

         BEGIN
            v_ipaddress :=
               TRIM (SUBSTR (v_filebuffer,
                             INSTR (v_filebuffer, '|', 1, 50) + 1,
                               (INSTR (v_filebuffer, '|', 1, 51) - 1
                               )
                             - INSTR (v_filebuffer, '|', 1, 50)
                            )
                    );

            IF v_length_check IS NOT NULL
            THEN
               IF LENGTH (v_length_check) > 15
               THEN
                  v_errmsg :=
                            v_errmsg || '--' || 'IPADDRESS length is invalid'; --Error message modified by Pankaj S. on 25-Sep-2013
               ELSE
                  /*----- IPADDRESS  -------*/
                  v_ipaddress := v_length_check;
               /*----- IPADDRESS  -------*/
               END IF;
            END IF;
         EXCEPTION
            WHEN OTHERS
            THEN
               v_errmsg := v_errmsg || '--' || 'IPADDRESS validation failed';
               v_sqlerr :=
                     v_sqlerr
                  || '-- '
                  || 'Data validation failed for field no '
                  || v_error_flag
                  || ' with tech error '
                  || SUBSTR (SQLERRM, 1, 100);
         END;

         v_error_flag := 52;

         BEGIN
            v_length_check :=
               TRIM (SUBSTR (v_filebuffer,
                             INSTR (v_filebuffer, '|', 1, 51) + 1,
                               (INSTR (v_filebuffer, '|', 1, 52) - 1
                               )
                             - INSTR (v_filebuffer, '|', 1, 51)
                            )
                    );

            IF v_length_check IS NOT NULL
            THEN
               IF LENGTH (v_length_check) > 12
               THEN
                  v_errmsg := v_errmsg || '--' || 'ANI length is invalid';
               ELSE
                  /*----- ANI  -------*/
                  v_ani := v_length_check;
               /*----- ANI  -------*/
               END IF;
            END IF;
         EXCEPTION
            WHEN OTHERS
            THEN
               v_errmsg := v_errmsg || '--' || 'ANI validation failed';
               v_sqlerr :=
                     v_sqlerr
                  || '-- '
                  || 'Data validation failed for field no '
                  || v_error_flag
                  || ' with tech error '
                  || SUBSTR (SQLERRM, 1, 100);
         END;

         v_error_flag := 53;

         BEGIN
            v_length_check :=
               TRIM (SUBSTR (v_filebuffer,
                             INSTR (v_filebuffer, '|', 1, 52) + 1,
                               (INSTR (v_filebuffer, '|', 1, 53) - 1
                               )
                             - INSTR (v_filebuffer, '|', 1, 52)
                            )
                    );

            IF v_length_check IS NOT NULL
            THEN
               IF LENGTH (v_length_check) > 12
               THEN
                  v_errmsg := v_errmsg || '--' || 'DNI length is invalid';
               ELSE
                  /*----- DNI  -------*/
                  v_dni := v_length_check;
               /*----- DNI  -------*/
               END IF;
            END IF;
         EXCEPTION
            WHEN OTHERS
            THEN
               v_errmsg := v_errmsg || '--' || 'DNI validation failed';
               v_sqlerr :=
                     v_sqlerr
                  || '-- '
                  || 'Data validation failed for field no '
                  || v_error_flag
                  || ' with tech error '
                  || SUBSTR (SQLERRM, 1, 100);
         END;

         v_error_flag := 54;

         BEGIN
            v_length_check :=
               TRIM (SUBSTR (v_filebuffer,
                             INSTR (v_filebuffer, '|', 1, 53) + 1,
                               (INSTR (v_filebuffer, '|', 1, 54) - 1
                               )
                             - INSTR (v_filebuffer, '|', 1, 53)
                            )
                    );

            --SN:Modified for Galileo changes //To marked cardstatus as optional
            --IF v_length_check IS NULL
            --THEN              
              -- v_errmsg := v_errmsg || '-- ' || 'Card Status is NULL';
            --RAISE exp_loop_reject_record;
            --ELSE
            --EN:Modified for Galileo changes //To marked cardstatus as optional
               IF LENGTH (v_length_check) > 3
               THEN
                  v_errmsg :=
                          v_errmsg || '--' || 'Card status length is invalid'; --Error message modified by Pankaj S. on 25-Sep-2013
               ELSE
                  /*----- CARD_STATUS  -------*/
                  v_card_status := v_length_check;
               /*----- CARD_STATUS  -------*/
               END IF;

               BEGIN
                  v_chk_num := TO_NUMBER (v_length_check);
               EXCEPTION
                  WHEN OTHERS
                  THEN
                     v_errmsg :=
                           v_errmsg
                        || '-- '
                        || 'Invalid value for card status '
                        || v_length_check;
               END;
            --END IF;  --Modified for Galileo changes //To marked cardstatus as optional
         EXCEPTION
            WHEN OTHERS
            THEN
               v_errmsg :=
                          v_errmsg || '--' || 'card status validation failed';
               v_sqlerr :=
                     v_sqlerr
                  || '-- '
                  || 'Data validation failed for field no '
                  || v_error_flag
                  || ' with tech error '
                  || SUBSTR (SQLERRM, 1, 100);
         END;

         v_error_flag := 55;

         BEGIN
            v_length_check :=
               TRIM (SUBSTR (v_filebuffer,
                             INSTR (v_filebuffer, '|', 1, 54) + 1,
                               (INSTR (v_filebuffer, '|', 1, 55) - 1
                               )
                             - INSTR (v_filebuffer, '|', 1, 54)
                            )
                    );

            --SN:Modified for Galileo changes //To marked waiver amount as optional
            --IF v_length_check IS NULL
            --THEN
              -- v_errmsg := v_errmsg || '-- ' || 'Waiver Amount is NULL';
            --RAISE exp_loop_reject_record;
            --ELSE
            --EN:Modified for Galileo changes //To marked waiver amount as optional
               IF LENGTH (v_length_check) > 21
               THEN
                  v_errmsg :=
                       v_errmsg || '-- ' || 'Waiver Amount length is invalid';
               ELSE
                  /*----- CARD_STATUS  -------*/
                  v_waiver_amount := v_length_check;
               /*----- CARD_STATUS  -------*/
               END IF;

               BEGIN
                  v_chk_amt := TO_NUMBER (v_length_check);
               EXCEPTION
                  WHEN OTHERS
                  THEN
                     v_errmsg :=
                           v_errmsg
                        || '-- '
                        || 'Invalid amount value for waiver amount '
                        || v_length_check;
               END;

               BEGIN
                  v_chk_amt :=
                            TO_NUMBER (v_length_check, 999999999999999999.99);
               EXCEPTION
                  WHEN OTHERS
                  THEN
                     v_errmsg :=
                        v_errmsg || '-- '
                        || 'waiver amount precision exceeded';
               END;
            --END IF; --Modified for Galileo changes //To marked waiver amount as optional
         EXCEPTION
            WHEN OTHERS
            THEN
               v_errmsg :=
                        v_errmsg || '--' || 'waiver amount validation failed';
               v_sqlerr :=
                     v_sqlerr
                  || '-- '
                  || 'Data validation failed for field no '
                  || v_error_flag
                  || ' with tech error '
                  || SUBSTR (SQLERRM, 1, 100);
         END;

         v_error_flag := 56;

         BEGIN
            v_length_check :=
               TRIM (SUBSTR (v_filebuffer,
                             INSTR (v_filebuffer, '|', 1, 55) + 1,
                               (INSTR (v_filebuffer, '|', 1, 56) - 1
                               )
                             - INSTR (v_filebuffer, '|', 1, 55)
                            )
                    );

            IF v_length_check IS NOT NULL
            THEN
               IF LENGTH (v_length_check) > 1
               THEN
                  v_errmsg :=
                     v_errmsg || '--'
                     || 'international indicator length is invalid'; --Error message modified by Pankaj S. on 25-Sep-2013
               ELSE
                  /*----- INTERNATIONAL_IND  -------*/
                  v_international_ind := v_length_check;
               /*----- INTERNATIONAL_IND  -------*/
               END IF;

               BEGIN
                  v_chk_num := TO_NUMBER (v_length_check);
               EXCEPTION
                  WHEN OTHERS
                  THEN
                     v_errmsg :=
                           v_errmsg
                        || '-- '
                        || 'Invalid value for international indicator '
                        || v_length_check;
               END;
            END IF;
         EXCEPTION
            WHEN OTHERS
            THEN
               v_errmsg :=
                     v_errmsg
                  || '--'
                  || 'international indicator validation failed';
               v_sqlerr :=
                     v_sqlerr
                  || '-- '
                  || 'Data validation failed for field no '
                  || v_error_flag
                  || ' with tech error '
                  || SUBSTR (SQLERRM, 1, 100);
         END;

         v_error_flag := 57;

         BEGIN
            v_length_check :=
               TRIM (SUBSTR (v_filebuffer,
                             INSTR (v_filebuffer, '|', 1, 56) + 1,
                               (INSTR (v_filebuffer, '|', 1, 57) - 1
                               )
                             - INSTR (v_filebuffer, '|', 1, 56)
                            )
                    );

            IF v_length_check IS NULL
            THEN
               v_errmsg := v_errmsg || '-- ' || 'Credit Debit Flag is NULL';
            --RAISE exp_loop_reject_record;
            ELSE
               IF LENGTH (v_length_check) > 1
               THEN
                  v_errmsg :=
                            v_errmsg || '--' || 'Credit Debit Flag length is invalid'; --Error message modified by Pankaj S. on 25-Sep-2013
               ELSE
                  /*----- CRDR_FLAG  -------*/
                  v_crdr_flag := v_length_check;
               /*----- CRDR_FLAG  -------*/
               END IF;

               BEGIN
                  v_chk_num := TO_NUMBER (v_length_check);
               EXCEPTION
                  WHEN OTHERS
                  THEN
                     v_errmsg :=
                           v_errmsg
                        || '-- '
                        || 'Invalid value for CR-DR flag '
                        || v_length_check;
               END;
            END IF;
         EXCEPTION
            WHEN OTHERS
            THEN
               v_errmsg := v_errmsg || '--' || 'CR-DR flag validation failed'; --Error message modified by Pankaj S. on 25-Sep-2013
               v_sqlerr :=
                     v_sqlerr
                  || '-- '
                  || 'Data validation failed for field no '
                  || v_error_flag
                  || ' with tech error '
                  || SUBSTR (SQLERRM, 1, 100);
         END;

         v_error_flag := 58;

         BEGIN
            v_length_check :=
               TRIM (SUBSTR (v_filebuffer,
                             INSTR (v_filebuffer, '|', 1, 57) + 1,
                               (INSTR (v_filebuffer, '|', 1, 58) - 1
                               )
                             - INSTR (v_filebuffer, '|', 1, 57)
                            )
                    );

            IF v_length_check IS NOT NULL
            THEN
               IF LENGTH (v_length_check) > 1
               THEN
                  v_errmsg :=
                      v_errmsg || '--' || 'incremantal indicator flag length is invalid';  --Error message modified by Pankaj S. on 25-Sep-2013
               ELSE
                  /*----- INCREMENTAL_IND  -------*/
                  v_incremental_ind := v_length_check;
               /*----- INCREMENTAL_IND  -------*/
               END IF;

               BEGIN
                  v_chk_num := TO_NUMBER (v_length_check);
               EXCEPTION
                  WHEN OTHERS
                  THEN
                     v_errmsg :=
                           v_errmsg
                        || '-- '
                        || 'Invalid value for incremantal indicator flag '
                        || v_length_check;
               END;
            END IF;
         EXCEPTION
            WHEN OTHERS
            THEN
               v_errmsg :=
                     v_errmsg
                  || '--'
                  || 'incremantal indicator flag validation failed';
               v_sqlerr :=
                     v_sqlerr
                  || '-- '
                  || 'Data validation failed for field no '
                  || v_error_flag
                  || ' with tech error '
                  || SUBSTR (SQLERRM, 1, 100);
         END;

         v_error_flag := 59;

         BEGIN
            v_length_check :=
               TRIM (SUBSTR (v_filebuffer,
                             INSTR (v_filebuffer, '|', 1, 58) + 1,
                               (INSTR (v_filebuffer, '|', 1, 59) - 1
                               )
                             - INSTR (v_filebuffer, '|', 1, 58)
                            )
                    );

            IF v_length_check IS NOT NULL
            THEN
               IF LENGTH (v_length_check) > 1
               THEN
                  v_errmsg :=
                      v_errmsg || '--' || 'partial preauth indicator flag length is invalid';   --Error message modified by Pankaj S. on 25-Sep-2013
               ELSE
                  /*----- PARTIALAUTH_IND  -------*/
                  v_partialauth_ind := v_length_check;
               /*----- PARTIALAUTH_IND  -------*/
               END IF;

               BEGIN
                  v_chk_num := TO_NUMBER (v_length_check);
               EXCEPTION
                  WHEN OTHERS
                  THEN
                     v_errmsg :=
                           v_errmsg
                        || '-- '
                        || 'Invalid value for partial preauth indicator flag '  --Error message modified by Pankaj S. on 25-Sep-2013
                        || v_length_check;
               END;
            END IF;
         EXCEPTION
            WHEN OTHERS
            THEN
               v_errmsg :=
                  v_errmsg || '--'
                  || 'partial preauth indicator flag validation failed';  --Error message modified by Pankaj S. on 25-Sep-2013
               v_sqlerr :=
                     v_sqlerr
                  || '-- '
                  || 'Data validation failed for field no '
                  || v_error_flag
                  || ' with tech error '
                  || SUBSTR (SQLERRM, 1, 100);
         END;

         v_error_flag := 60;

         BEGIN
            v_length_check :=
               TRIM (SUBSTR (v_filebuffer,
                             INSTR (v_filebuffer, '|', 1, 59) + 1,
                               (INSTR (v_filebuffer, '|', 1, 60) - 1
                               )
                             - INSTR (v_filebuffer, '|', 1, 59)
                            )
                    );

            IF v_length_check IS NOT NULL
            THEN
               IF LENGTH (v_length_check) > 2
               THEN
                  v_errmsg :=
                     v_errmsg || '--' || 'Completion count length is invalid'; --Error message modified by Pankaj S. on 25-Sep-2013
               ELSE
                  /*----- COMPLETION_COUNT  -------*/
                  v_completion_count := v_length_check;
               /*----- COMPLETION_COUNT  -------*/
               END IF;

               BEGIN
                  v_chk_num := TO_NUMBER (v_length_check);
               EXCEPTION
                  WHEN OTHERS
                  THEN
                     v_errmsg :=
                           v_errmsg
                        || '-- '
                        || 'Invalid value for completion count '
                        || v_length_check;
               END;
            END IF;
         EXCEPTION
            WHEN OTHERS
            THEN
               v_errmsg :=
                     v_errmsg || '--' || 'completion count validation failed';
               v_sqlerr :=
                     v_sqlerr
                  || '-- '
                  || 'Data validation failed for field no '
                  || v_error_flag
                  || ' with tech error '
                  || SUBSTR (SQLERRM, 1, 100);
         END;

         v_error_flag := 61;

         BEGIN
            v_length_check :=
               TRIM (SUBSTR (v_filebuffer,
                             INSTR (v_filebuffer, '|', 1, 60) + 1,
                               (INSTR (v_filebuffer, '|', 1, 61) - 1
                               )
                             - INSTR (v_filebuffer, '|', 1, 60)
                            )
                    );

            IF v_length_check IS NOT NULL
            THEN
               IF LENGTH (v_length_check) > 1
               THEN
                  v_errmsg :=
                     v_errmsg || '--'
                     || 'last completion indicator length is invalid'; --Error message modified by Pankaj S. on 25-Sep-2013
               ELSE
                  /*----- LASTCOMPLETION_IND  -------*/
                  v_lastcompletion_ind := v_length_check;
               /*----- LASTCOMPLETION_IND  -------*/
               END IF;

               IF REGEXP_LIKE (v_length_check, '[0-9]')
               THEN
                  v_errmsg :=
                        v_errmsg
                     || '-- '
                     || 'Invalid value for last completion indicator '
                     || v_length_check;
               END IF;
            END IF;
         EXCEPTION
            WHEN OTHERS
            THEN
               v_errmsg :=
                  v_errmsg || '--'
                  || 'completion indicator validation failed';
               v_sqlerr :=
                     v_sqlerr
                  || '-- '
                  || 'Data validation failed for field no '
                  || v_error_flag
                  || ' with tech error '
                  || SUBSTR (SQLERRM, 1, 100);
         END;

         v_error_flag := 62;

         BEGIN
            v_length_check :=
               TRIM (SUBSTR (v_filebuffer,
                             INSTR (v_filebuffer, '|', 1, 61) + 1,
                               (INSTR (v_filebuffer, '|', 1, 62) - 1
                               )
                             - INSTR (v_filebuffer, '|', 1, 61)
                            )
                    );

            IF v_length_check IS NOT NULL
            THEN
               IF LENGTH (v_length_check) > 3
               THEN
                  v_errmsg :=
                        v_errmsg
                     || '--'
                     || 'preauth expiry period length is invalid'; --Error message modified by Pankaj S. on 25-Sep-2013
               ELSE
                  /*----- PREAUTH_EXPRYPERIOD  -------*/
                  v_preauth_expryperiod := v_length_check;
               /*----- PREAUTH_EXPRYPERIOD  -------*/
               END IF;

               IF REGEXP_LIKE (v_length_check, '[A-Z,a-z]')
               THEN
                  v_errmsg :=
                        v_errmsg
                     || '-- '
                     || 'Invalid value for preauth expiry period '
                     || v_length_check;
               END IF;
            END IF;
         EXCEPTION
            WHEN OTHERS
            THEN
               v_errmsg :=
                  v_errmsg || '--'
                  || 'preauth expiry period validation failed';
               v_sqlerr :=
                     v_sqlerr
                  || '-- '
                  || 'Data validation failed for field no '
                  || v_error_flag
                  || ' with tech error '
                  || SUBSTR (SQLERRM, 1, 100);
         END;

         v_error_flag := 63;

         BEGIN
            v_length_check :=
               TRIM (SUBSTR (v_filebuffer,
                             INSTR (v_filebuffer, '|', 1, 62) + 1,
                               (INSTR (v_filebuffer, '|', 1, 63) - 1
                               )
                             - INSTR (v_filebuffer, '|', 1, 62)
                            )
                    );

            IF v_length_check IS NOT NULL
            THEN
               IF LENGTH (v_length_check) > 1
               THEN
                  v_errmsg :=
                        v_errmsg
                     || '--'
                     || 'Merch floor limit indicator length is invalid'; --Error message modified by Pankaj S. on 25-Sep-2013
               ELSE
                  /*----- MERC_FLOORLIMIT_IND  -------*/
                  v_merc_floorlimit_ind := v_length_check;
               /*----- MERC_FLOORLIMIT_IND  -------*/
               END IF;

               IF REGEXP_LIKE (v_length_check, '[0-9]')
               THEN
                  v_errmsg :=
                        v_errmsg
                     || '-- '
                     || 'Invalid value for Merch Floor limit indicator ' --Error message modified by Pankaj S. on 25-Sep-2013
                     || v_length_check;
               END IF;
            END IF;
         EXCEPTION
            WHEN OTHERS
            THEN
               v_errmsg :=
                  v_errmsg || '--'
                  || 'Merch Floor limit indicator validation failed'; --Error message modified by Pankaj S. on 25-Sep-2013
               v_sqlerr :=
                     v_sqlerr
                  || '-- '
                  || 'Data validation failed for field no '
                  || v_error_flag
                  || ' with tech error '
                  || SUBSTR (SQLERRM, 1, 100);
         END;

         v_error_flag := 64;

         BEGIN
            v_length_check :=
               TRIM (SUBSTR (v_filebuffer,
                             INSTR (v_filebuffer, '|', 1, 63) + 1,
                               (INSTR (v_filebuffer, '|', 1, 64) - 1
                               )
                             - INSTR (v_filebuffer, '|', 1, 63)
                            )
                    );

            IF v_length_check IS NOT NULL
            THEN
               IF LENGTH (v_length_check) > 1
               THEN
                  v_errmsg :=
                        v_errmsg
                     || '--'
                     || 'Addr verification indicator length is invalid'; --Error message modified by Pankaj S. on 25-Sep-2013
               ELSE
                  /*----- addr_verification_ind  -------*/
                  v_addr_verification_ind := v_length_check;
               /*----- addr_verification_ind  -------*/
               END IF;

               IF REGEXP_LIKE (v_length_check, '[0-9]')
               THEN
                  v_errmsg :=
                        v_errmsg
                     || '-- '
                     || 'Invalid value for Addr verification indicator ' --Error message modified by Pankaj S. on 25-Sep-2013
                     || v_length_check;
               END IF;
            END IF;
         EXCEPTION
            WHEN OTHERS
            THEN
               v_errmsg :=
                  v_errmsg || '--'
                  || 'Addr verification indicator validation failed';
               v_sqlerr :=
                     v_sqlerr
                  || '-- '
                  || 'Data validation failed for field no '
                  || v_error_flag
                  || ' with tech error '
                  || SUBSTR (SQLERRM, 1, 100);
         END;

         v_error_flag := 65;

         BEGIN
            v_length_check :=
               TRIM (SUBSTR (v_filebuffer,
                             INSTR (v_filebuffer, '|', 1, 64) + 1,
                               (INSTR (v_filebuffer, '|', 1, 65) - 1
                               )
                             - INSTR (v_filebuffer, '|', 1, 64)
                            )
                    );

            IF v_length_check IS NOT NULL
            THEN
               IF LENGTH (v_length_check) > 300
               THEN
                  v_errmsg :=
                            v_errmsg || '--' || 'NARRATION length is invalid';
               --RAISE exp_loop_reject_record;
               ELSE
                  v_narration := v_length_check;
               END IF;
            END IF;
         EXCEPTION
            WHEN OTHERS
            THEN
               v_errmsg := v_errmsg || '--' || 'NARRATION validation failed';
               v_sqlerr :=
                     v_sqlerr
                  || '-- '
                  || 'Data validation failed for field no '
                  || v_error_flag
                  || ' with tech error '
                  || SUBSTR (SQLERRM, 1, 100);
         END;

         v_error_flag := 66;

         BEGIN
            v_length_check :=
               TRIM (SUBSTR (v_filebuffer,
                             INSTR (v_filebuffer, '|', 1, 65) + 1,
                               (INSTR (v_filebuffer, '|', 1, 66) - 1
                               )
                             - INSTR (v_filebuffer, '|', 1, 65)
                            )
                    );

            IF v_length_check IS NOT NULL
            THEN
               IF LENGTH (v_length_check) > 1
               THEN
                  v_errmsg :=
                         v_errmsg || '--' || 'Dispute Flag length is invalid';
               --RAISE exp_loop_reject_record;
               ELSE
                  v_dispute_flag := v_length_check;
               END IF;

               IF REGEXP_LIKE (v_length_check, '[A-Z,a-z]')
               THEN
                  v_errmsg :=
                        v_errmsg
                     || '-- '
                     || 'Invalid value for Dispute Flag '
                     || v_length_check;
               END IF;
            END IF;
         EXCEPTION
            WHEN OTHERS
            THEN
               v_errmsg :=
                         v_errmsg || '--' || 'Dispute Flag validation failed';
               v_sqlerr :=
                     v_sqlerr
                  || '-- '
                  || 'Data validation failed for field no '
                  || v_error_flag
                  || ' with tech error '
                  || SUBSTR (SQLERRM, 1, 100);
         END;

         v_error_flag := 67;

         BEGIN
            v_length_check :=
               TRIM (SUBSTR (v_filebuffer,
                             INSTR (v_filebuffer, '|', 1, 66) + 1,
                               (INSTR (v_filebuffer, '|', 1, 67) - 1
                               )
                             - INSTR (v_filebuffer, '|', 1, 66)
                            )
                    );


           IF     v_delivery_channel = '03'
              AND v_transaction_code IN
                     ('13', '14', '37', '19', '20', '12', '11', '74', '76', '75',
                      '78', '83', '84', '85', '86', '87')
           THEN
              IF v_length_check IS NULL
              THEN
                 v_errmsg :=
                       v_errmsg
                    || '--'
                    || 'Reason Code is mandatory in CSR for transaction code ' --Error message modified by Pankaj S. on 25-Sep-2013
                    || v_transaction_code;
              END IF;
           END IF;


            IF v_length_check IS NOT NULL
            THEN

               IF LENGTH (v_length_check) > 3
               THEN
                  v_errmsg :=
                          v_errmsg || '--' || 'Reason Code length is invalid';
               --RAISE exp_loop_reject_record;
               ELSE
                  v_reason_code := v_length_check;
               END IF;

               IF REGEXP_LIKE (v_length_check, '[A-Z,a-z]')
               THEN
                  v_errmsg :=
                        v_errmsg
                     || '-- '
                     || 'Invalid value for reason code '
                     || v_length_check;
               END IF;
            END IF;
         EXCEPTION
            WHEN OTHERS
            THEN
               v_errmsg :=
                          v_errmsg || '--' || 'Reason Code validation failed';
               v_sqlerr :=
                     v_sqlerr
                  || '-- '
                  || 'Data validation failed for field no '
                  || v_error_flag
                  || ' with tech error '
                  || SUBSTR (SQLERRM, 1, 100);
         END;

         v_error_flag := 68;

         BEGIN
            v_length_check :=
               TRIM (SUBSTR (v_filebuffer,
                             INSTR (v_filebuffer, '|', 1, 67) + 1,
                               (INSTR (v_filebuffer, '|', 1, 68) - 1
                               )
                             - INSTR (v_filebuffer, '|', 1, 67)
                            )
                    );

            IF v_length_check IS NOT NULL
            THEN
               IF LENGTH (v_length_check) > 800
               THEN
                  v_errmsg := v_errmsg || '--' || 'REMARK length is invalid';
               --RAISE exp_loop_reject_record;
               ELSE
                  v_remark := v_length_check;
               END IF;
            END IF;
         EXCEPTION
            WHEN OTHERS
            THEN
               v_errmsg := v_errmsg || '--' || 'REMARK validation failed';
               v_sqlerr :=
                     v_sqlerr
                  || '-- '
                  || 'Data validation failed for field no '
                  || v_error_flag
                  || ' with tech error '
                  || SUBSTR (SQLERRM, 1, 100);
         END;

         v_error_flag := 69;

         BEGIN
            v_length_check :=
               TRIM (SUBSTR (v_filebuffer,
                             INSTR (v_filebuffer, '|', 1, 68) + 1,
                               (INSTR (v_filebuffer, '|', 1, 69) - 1
                               )
                             - INSTR (v_filebuffer, '|', 1, 68)
                            )
                    );

            IF v_length_check IS NOT NULL
            THEN
               IF LENGTH (v_length_check) > 100
               THEN
                  v_errmsg :=
                       v_errmsg || '--' || 'Dispute Reason length is invalid';
               --RAISE exp_loop_reject_record;
               ELSE
                  v_dispute_reason := v_length_check;
               END IF;
            END IF;
         EXCEPTION
            WHEN OTHERS
            THEN
               v_errmsg :=
                       v_errmsg || '--' || 'Dispute Reason validation failed';
               v_sqlerr :=
                     v_sqlerr
                  || '-- '
                  || 'Data validation failed for field no '
                  || v_error_flag
                  || ' with tech error '
                  || SUBSTR (SQLERRM, 1, 100);
         END;

         /*
          v_error_flag := 70;
          v_dispute_remark :=
             TRIM (SUBSTR (v_filebuffer,
                           INSTR (v_filebuffer, '|', 1, 69) + 1,
                             (INSTR (v_filebuffer, '|', 1, 70) - 1
                             )
                           - INSTR (v_filebuffer, '|', 1, 69)
                          )
                  );
          */
         v_error_flag := 70;

         BEGIN
            v_length_check :=
               TRIM (SUBSTR (v_filebuffer,
                             INSTR (v_filebuffer, '|', 1, 69) + 1,
                               (INSTR (v_filebuffer, '|', 1, 70) - 1
                               )
                             - INSTR (v_filebuffer, '|', 1, 69)
                            )
                    );

            IF v_length_check IS NOT NULL
            THEN
               IF LENGTH (v_length_check) > 800
               THEN
                  v_errmsg :=
                       v_errmsg || '--' || 'Dispute Remark length is invalid';
               --RAISE exp_loop_reject_record;
               ELSE
                  v_dispute_remark := v_length_check;
               END IF;
            END IF;
         EXCEPTION
            WHEN OTHERS
            THEN
               v_errmsg :=
                       v_errmsg || '--' || 'Dispute Remark validation failed';
               v_sqlerr :=
                     v_sqlerr
                  || '-- '
                  || 'Data validation failed for field no '
                  || v_error_flag
                  || ' with tech error '
                  || SUBSTR (SQLERRM, 1, 100);
         END;

         v_error_flag := 71;

         BEGIN
            v_length_check :=
               TRIM (SUBSTR (v_filebuffer,
                             INSTR (v_filebuffer, '|', 1, 70) + 1,
                               (INSTR (v_filebuffer, '|', 1, 71) - 1
                               )
                             - INSTR (v_filebuffer, '|', 1, 70)
                            )
                    );
                    
            --SN:Modified for Galileo changes //Default value of 'N' to be used for match completion flag
            IF v_length_check IS NULL
            THEN
              v_length_check:='N';
            END IF;
            --EN:Modified for Galileo changes //Default value of 'N' to be used for match completion flag

            IF v_length_check IS NOT NULL
            THEN
               IF LENGTH (v_length_check) > 1
               THEN
                  v_errmsg :=
                       v_errmsg || '--' || 'Match Completion Flag length is invalid';
               --RAISE exp_loop_reject_record;
               ELSE
                  v_matchcomp_flag := v_length_check;
               END IF;

               IF REGEXP_LIKE (v_length_check, '[0-9]')
               THEN
                  v_errmsg :=
                        v_errmsg
                     || '-- '
                     || 'Invalid value for Match Completion Flag '
                     || v_length_check;
               END IF;
            END IF;
         EXCEPTION
            WHEN OTHERS
            THEN
               v_errmsg :=
                      v_errmsg || '--' || 'Match Completion Flag validation failed';
               v_sqlerr :=
                     v_sqlerr
                  || '-- '
                  || 'Data validation failed for field no '
                  || v_error_flag
                  || ' with tech error '
                  || SUBSTR (SQLERRM, 1, 100);
         END;

         v_error_flag := 72;

         BEGIN
            v_length_check :=
               TRIM (SUBSTR (v_filebuffer,
                             INSTR (v_filebuffer, '|', 1, 71) + 1,
                               (INSTR (v_filebuffer, '|', 1, 72) - 1
                               )
                             - INSTR (v_filebuffer, '|', 1, 71)
                            )
                    );

            IF v_length_check IS NOT NULL
            THEN
               IF LENGTH (v_length_check) > 1
               THEN
                  v_errmsg :=
                        v_errmsg || '--' || 'C2C txn status length is invalid'; --Error message modified by Pankaj S. on 25-Sep-2013
               --RAISE exp_loop_reject_record;
               ELSE
                  v_c2ctxn_status := v_length_check;
               END IF;

               IF REGEXP_LIKE (v_length_check, '[0-9]')
               THEN
                  v_errmsg :=
                        v_errmsg
                     || '-- '
                     || 'Invalid value for C2C txn status '
                     || v_length_check;
               END IF;
            END IF;
         EXCEPTION
            WHEN OTHERS
            THEN
               v_errmsg :=
                       v_errmsg || '--' || 'C2C txn status validation failed'; --Error message modified by Pankaj S. on 25-Sep-2013
               v_sqlerr :=
                     v_sqlerr
                  || '-- '
                  || 'Data validation failed for field no '
                  || v_error_flag
                  || ' with tech error '
                  || SUBSTR (SQLERRM, 1, 100);
         END;

         v_error_flag := 73;

         BEGIN
            v_length_check :=
               TRIM (SUBSTR (v_filebuffer,
                             INSTR (v_filebuffer, '|', 1, 72) + 1,
                               (INSTR (v_filebuffer, '|', 1, 73) - 1
                               )
                             - INSTR (v_filebuffer, '|', 1, 72)
                            )
                    );

            IF v_length_check IS NOT NULL
            THEN
               IF LENGTH (v_length_check) > 17
               THEN
                  v_errmsg :=
                          v_errmsg || '--' || 'Posted Date length is invalid';
               --RAISE exp_loop_reject_record;
               ELSE
                  v_posted_date := v_length_check;
               END IF;

               BEGIN
                  v_chk_date := TO_DATE (v_length_check, 'yyyymmdd hh24miss');
               EXCEPTION
                  WHEN OTHERS
                  THEN
                     v_errmsg :=
                           v_errmsg
                        || '-- '
                        || 'Invalid date format for Posted Date '
                        || v_length_check;
               END;
            END IF;
         EXCEPTION
            WHEN OTHERS
            THEN
               v_errmsg :=
                          v_errmsg || '--' || 'Posted Date validation failed';
               v_sqlerr :=
                     v_sqlerr
                  || '-- '
                  || 'Data validation failed for field no '
                  || v_error_flag
                  || ' with tech error '
                  || SUBSTR (SQLERRM, 1, 100);
         END;

        /*       --Commented as per discussion 02-Aug-2013

         v_error_flag := 74;

         BEGIN
            v_length_check :=
               TRIM (SUBSTR (v_filebuffer,
                             INSTR (v_filebuffer, '|', 1, 73) + 1,
                               (INSTR (v_filebuffer, '|', 1, 74) - 1
                               )
                             - INSTR (v_filebuffer, '|', 1, 73)
                            )
                    );

            IF v_length_check IS NOT NULL
            THEN
               IF LENGTH (v_length_check) > 21
               THEN
                  v_errmsg :=
                        v_errmsg
                     || '--'
                     || 'Beftxn Topupcard Ledger balance lenght is invalid';
               --RAISE exp_loop_reject_record;
               ELSE
                  v_beftxn_topupcard_ledgerbal := v_length_check;
               END IF;

               BEGIN
                  v_chk_amt := TO_NUMBER (v_length_check);
               EXCEPTION
                  WHEN OTHERS
                  THEN
                     v_errmsg :=
                           v_errmsg
                        || '-- '
                        || 'Invalid amount value for Beftxn Topupcard Ledger balance '
                        || v_length_check;
               END;

               BEGIN
                  v_chk_amt :=
                            TO_NUMBER (v_length_check, 999999999999999999.99);
               EXCEPTION
                  WHEN OTHERS
                  THEN
                     v_errmsg :=
                           v_errmsg
                        || '-- '
                        || 'Beftxn Topupcard Ledger balance precision exceeded';
               END;
            END IF;
         EXCEPTION
            WHEN OTHERS
            THEN
               v_errmsg :=
                     v_errmsg
                  || '--'
                  || 'Topupcard Ledger balance validation failed';
               v_sqlerr :=
                     v_sqlerr
                  || '-- '
                  || 'Data validation failed for field no '
                  || v_error_flag
                  || ' with tech error '
                  || SUBSTR (SQLERRM, 1, 100);
         END;

        */       --Commented as per discussion 02-Aug-2013

         v_error_flag := 75;

         BEGIN
            v_length_check :=
               TRIM (SUBSTR (v_filebuffer,
                             INSTR (v_filebuffer, '|', 1, 74) + 1,
                               (INSTR (v_filebuffer, '|', 1, 75) - 1
                               )
                             - INSTR (v_filebuffer, '|', 1, 74)
                            )
                    );

            IF v_length_check IS NOT NULL
            THEN
               IF LENGTH (v_length_check) > 21
               THEN
                  v_errmsg :=
                        v_errmsg
                     || '--'
                     || 'Topupcard Ledger balance length is invalid'; --Error message modified by Pankaj S. on 25-Sep-2013
               --RAISE exp_loop_reject_record;
               ELSE
                  v_topupcard_ledgerbal := v_length_check;
               END IF;

               BEGIN
                  v_chk_amt := TO_NUMBER (v_length_check);
               EXCEPTION
                  WHEN OTHERS
                  THEN
                     v_errmsg :=
                           v_errmsg
                        || '-- '
                        || 'Invalid amount value for After Txn Topupcard Ledger balance '
                        || v_length_check;
               END;

               BEGIN
                  v_chk_amt :=
                            TO_NUMBER (v_length_check, 999999999999999999.99);
               EXCEPTION
                  WHEN OTHERS
                  THEN
                     v_errmsg :=
                           v_errmsg
                        || '-- '
                        || 'After Txn Topupcard Ledger balance precision exceeded';
               END;
            END IF;
         EXCEPTION
            WHEN OTHERS
            THEN
               v_errmsg :=
                     v_errmsg
                  || '--'
                  || 'After Txn Topupcard Ledger balance validation failed';

               v_sqlerr :=
                     v_sqlerr
                  || '-- '
                  || 'Data validation failed for field no '
                  || v_error_flag
                  || ' with tech error '
                  || SUBSTR (SQLERRM, 1, 100);
         END;


        /*       --Commented as per discussion 02-Aug-2013
         v_error_flag := 76;

         BEGIN
            v_length_check :=
               TRIM (SUBSTR (v_filebuffer,
                             INSTR (v_filebuffer, '|', 1, 75) + 1,
                               (INSTR (v_filebuffer, '|', 1, 76) - 1
                               )
                             - INSTR (v_filebuffer, '|', 1, 75)
                            )
                    );

            IF v_length_check IS NOT NULL
            THEN
               IF LENGTH (v_length_check) > 21
               THEN
                  v_errmsg :=
                        v_errmsg
                     || '--'
                     || 'Before Txn Topupcard Account balance lenght is invalid';
               --RAISE exp_loop_reject_record;
               ELSE
                  v_beftxn_topupcard_acctbal := v_length_check;
               END IF;

               BEGIN
                  v_chk_amt := TO_NUMBER (v_length_check);
               EXCEPTION
                  WHEN OTHERS
                  THEN
                     v_errmsg :=
                           v_errmsg
                        || '-- '
                        || 'Invalid amount value for Before Txn Topupcard Account balance '
                        || v_length_check;
               END;

               BEGIN
                  v_chk_amt :=
                            TO_NUMBER (v_length_check, 999999999999999999.99);
               EXCEPTION
                  WHEN OTHERS
                  THEN
                     v_errmsg :=
                           v_errmsg
                        || '-- '
                        || 'Before Txn Topupcard Account balance precision exceeded';
               END;
            END IF;
         EXCEPTION
            WHEN OTHERS
            THEN
               v_errmsg :=
                     v_errmsg
                  || '--'
                  || 'Before Txn Topupcard Account balance validation failed';
               v_sqlerr :=
                     v_sqlerr
                  || '-- '
                  || 'Data validation failed for field no '
                  || v_error_flag
                  || ' with tech error '
                  || SUBSTR (SQLERRM, 1, 100);
         END;

        */       --Commented as per discussion 02-Aug-2013

         v_error_flag := 77;

         BEGIN
            v_length_check :=
               TRIM (SUBSTR (v_filebuffer,
                             INSTR (v_filebuffer, '|', 1, 76) + 1,
                               (INSTR (v_filebuffer, '|', 1, 77) - 1
                               )
                             - INSTR (v_filebuffer, '|', 1, 76)
                            )
                    );

            IF v_length_check IS NOT NULL
            THEN
               IF LENGTH (v_length_check) > 21
               THEN
                  v_errmsg :=
                     v_errmsg || '--'
                     || 'Topupcard acct balance length is invalid'; --Error message modified by Pankaj S. on 25-Sep-2013
               --RAISE exp_loop_reject_record;
               ELSE
                  v_topupcard_acctbal := v_length_check;
               END IF;

               BEGIN
                  v_chk_amt := TO_NUMBER (v_length_check);
               EXCEPTION
                  WHEN OTHERS
                  THEN
                     v_errmsg :=
                           v_errmsg
                        || '-- '
                        || 'Invalid amount value for After Txn Topupcard acct balance ' --Error message modified by Pankaj S. on 25-Sep-2013
                        || v_length_check;
               END;

               BEGIN
                  v_chk_amt :=
                            TO_NUMBER (v_length_check, 999999999999999999.99);
               EXCEPTION
                  WHEN OTHERS
                  THEN
                     v_errmsg :=
                           v_errmsg
                        || '-- '
                        || 'After Txn Topupcard acct balance precision exceeded'; --Error message modified by Pankaj S. on 25-Sep-2013
               END;
            END IF;
         EXCEPTION
            WHEN OTHERS
            THEN
               v_errmsg :=
                     v_errmsg
                  || '--'
                  || 'After Txn Topupcard acct balance validation failed'; --Error message modified by Pankaj S. on 25-Sep-2013
               v_sqlerr :=
                     v_sqlerr
                  || '-- '
                  || 'Data validation failed for field no '
                  || v_error_flag
                  || ' with tech error '
                  || SUBSTR (SQLERRM, 1, 100);
         END;

         v_error_flag := 78;

         BEGIN
            v_length_check :=
               TRIM (SUBSTR (v_filebuffer,
                             INSTR (v_filebuffer, '|', 1, 77) + 1,
                               (INSTR (v_filebuffer, '|', 1, 78) - 1
                               )
                             - INSTR (v_filebuffer, '|', 1, 77)
                            )
                    );

            IF v_length_check IS NOT NULL
            THEN
               IF LENGTH (v_length_check) > 17
               THEN
                  v_errmsg :=
                     v_errmsg || '--'
                     || 'Preauth Expiry date length is invalid'; --Error message modified by Pankaj S. on 25-Sep-2013
               --RAISE exp_loop_reject_record;
               ELSE
                  v_preauth_expry_date := v_length_check;
               END IF;

               BEGIN
                  v_chk_date := TO_DATE (v_length_check, 'yyyymmdd hh24miss');
               EXCEPTION
                  WHEN OTHERS
                  THEN
                     v_errmsg :=
                           v_errmsg
                        || '-- '
                        || 'Invalid time format for Preauth Expiry date '
                        || v_length_check;
               END;
            END IF;
         EXCEPTION
            WHEN OTHERS
            THEN
               v_errmsg :=
                  v_errmsg || '--' || 'Preauth Expiry date validation failed';
               v_sqlerr :=
                     v_sqlerr
                  || '-- '
                  || 'Data validation failed for field no '
                  || v_error_flag
                  || ' with tech error '
                  || SUBSTR (SQLERRM, 1, 100);
         END;

         v_error_flag := 79;

         BEGIN
            v_length_check :=
               TRIM (SUBSTR (v_filebuffer,
                             INSTR (v_filebuffer, '|', 1, 78) + 1,
                               (INSTR (v_filebuffer, '|', 1, 79) - 1
                               )
                             - INSTR (v_filebuffer, '|', 1, 78)
                            )
                    );

            IF v_length_check IS NOT NULL
            THEN
               IF LENGTH (v_length_check) > 20
               THEN
                  v_errmsg :=
                         v_errmsg || '--' || 'Topup account number length is invalid';
               --RAISE exp_loop_reject_record;
               ELSE
                  v_topup_acctno := v_length_check;
               END IF;

               IF REGEXP_LIKE (v_length_check, '[A-Z,a-z]')
               THEN
                  v_errmsg :=
                        v_errmsg
                     || '-- '
                     || 'Invalid value for Topup account number '
                     || v_length_check;
               END IF;
            END IF;
         EXCEPTION
            WHEN OTHERS
            THEN
               v_errmsg :=
                  v_errmsg || '--'
                  || 'Topup account number validation failed';
               v_sqlerr :=
                     v_sqlerr
                  || '-- '
                  || 'Data validation failed for field no '
                  || v_error_flag
                  || ' with tech error '
                  || SUBSTR (SQLERRM, 1, 100);
         END;

        /*       --Commented as per discussion 02-Aug-2013

         v_error_flag := 80;

         BEGIN
            v_length_check :=
               TRIM (SUBSTR (v_filebuffer,
                             INSTR (v_filebuffer, '|', 1, 79) + 1,
                               (INSTR (v_filebuffer, '|', 1, 80) - 1
                               )
                             - INSTR (v_filebuffer, '|', 1, 79)
                            )
                    );

            IF v_length_check IS NOT NULL
            THEN
               IF LENGTH (v_length_check) > 1
               THEN
                  v_errmsg :=
                     v_errmsg || '--'
                     || 'Preauth valid flag lenght is invalid';
               --RAISE exp_loop_reject_record;
               ELSE
                  v_preauth_validflag := v_length_check;
               END IF;

               IF REGEXP_LIKE (v_length_check, '[0-9]')
               THEN
                  v_errmsg :=
                        v_errmsg
                     || '-- '
                     || 'Invalid value for Preauth valid flag '
                     || v_length_check;
               END IF;
            END IF;
         EXCEPTION
            WHEN OTHERS
            THEN
               v_errmsg :=
                  v_errmsg || '--' || ' Preauth valid flag validation failed';
               v_sqlerr :=
                     v_sqlerr
                  || '-- '
                  || 'Data validation failed for field no '
                  || v_error_flag
                  || ' with tech error '
                  || SUBSTR (SQLERRM, 1, 100);
         END;

         v_error_flag := 81;

         BEGIN
            v_length_check :=
               TRIM (SUBSTR (v_filebuffer,
                             INSTR (v_filebuffer, '|', 1, 80) + 1,
                               (INSTR (v_filebuffer, '|', 1, 81) - 1
                               )
                             - INSTR (v_filebuffer, '|', 1, 80)
                            )
                    );

            IF v_length_check IS NOT NULL
            THEN
               IF LENGTH (v_length_check) > 1
               THEN
                  v_errmsg :=
                          v_errmsg || '--' || 'Expiry Flag lenght is invalid';
               --RAISE exp_loop_reject_record;
               ELSE
                  v_expiry_flag := v_length_check;
               END IF;

               IF REGEXP_LIKE (v_length_check, '[0-9]')
               THEN
                  v_errmsg :=
                        v_errmsg
                     || '-- '
                     || 'Invalid value for Preauth Expiry Flag '
                     || v_length_check;
               END IF;
            END IF;
         EXCEPTION
            WHEN OTHERS
            THEN
               v_errmsg :=
                  v_errmsg || '--'
                  || ' Preauth Expiry flag validation failed';
               v_sqlerr :=
                     v_sqlerr
                  || '-- '
                  || 'Data validation failed for field no '
                  || v_error_flag
                  || ' with tech error '
                  || SUBSTR (SQLERRM, 1, 100);
         END;

         v_error_flag := 82;

         BEGIN
            v_length_check :=
               TRIM (SUBSTR (v_filebuffer,
                             INSTR (v_filebuffer, '|', 1, 81) + 1,
                               (INSTR (v_filebuffer, '|', 1, 82) - 1
                               )
                             - INSTR (v_filebuffer, '|', 1, 81)
                            )
                    );

            IF v_length_check IS NOT NULL
            THEN
               IF LENGTH (v_length_check) > 1
               THEN
                  v_errmsg :=
                      v_errmsg || '--' || 'Preauth Completion Flag lenght is invalid';
               --RAISE exp_loop_reject_record;
               ELSE
                  v_completion_flag := v_length_check;
               END IF;

               IF REGEXP_LIKE (v_length_check, '[0-9]')
               THEN
                  v_errmsg :=
                        v_errmsg
                     || '-- '
                     || 'Invalid value for Preauth Completion Flag '
                     || v_length_check;
               END IF;
            END IF;
         EXCEPTION
            WHEN OTHERS
            THEN
               v_errmsg :=
                     v_errmsg
                  || '--'
                  || ' Preauth Expiry Completion validation failed';
               v_sqlerr :=
                     v_sqlerr
                  || '-- '
                  || 'Data validation failed for field no '
                  || v_error_flag
                  || ' with tech error '
                  || SUBSTR (SQLERRM, 1, 100);
         END;

        */       --Commented as per discussion 02-Aug-2013

         v_error_flag := 83;

         BEGIN
            v_length_check :=
               TRIM (SUBSTR (v_filebuffer,
                             INSTR (v_filebuffer, '|', 1, 82) + 1,
                               (INSTR (v_filebuffer, '|', 1, 83) - 1
                               )
                             - INSTR (v_filebuffer, '|', 1, 82)
                            )
                    );

            IF v_length_check IS NOT NULL
            THEN
               IF LENGTH (v_length_check) > 20
               THEN
                  v_errmsg :=
                         v_errmsg || '--' || 'Preauth Pending Hold Amount length is invalid';
               --RAISE exp_loop_reject_record;
               ELSE
                  v_pend_holdamt := v_length_check;
               END IF;

               BEGIN
                  v_chk_amt := TO_NUMBER (v_length_check);
               EXCEPTION
                  WHEN OTHERS
                  THEN
                     v_errmsg :=
                           v_errmsg
                        || '-- '
                        || 'Invalid amount value for Preauth Pending Hold Amount '
                        || v_length_check;
               END;

               BEGIN
                  v_chk_amt :=
                            TO_NUMBER (v_length_check, 999999999999999999.99);
               EXCEPTION
                  WHEN OTHERS
                  THEN
                     v_errmsg :=
                           v_errmsg
                        || '-- '
                        || 'preauth pending hold amount precision exceeded';
               END;
            END IF;
         EXCEPTION
            WHEN OTHERS
            THEN
               v_errmsg :=
                     v_errmsg
                  || '--'
                  || ' Preauth pending hold amount validation failed';
               v_sqlerr :=
                     v_sqlerr
                  || '-- '
                  || 'Data validation failed for field no '
                  || v_error_flag
                  || ' with tech error '
                  || SUBSTR (SQLERRM, 1, 100);
         END;

        /*       --Commented as per discussion 02-Aug-2013

         v_error_flag := 84;

         BEGIN
            v_length_check :=
               TRIM (SUBSTR (v_filebuffer,
                             INSTR (v_filebuffer, '|', 1, 83) + 1,
                               (INSTR (v_filebuffer, '|', 1, 84) - 1
                               )
                             - INSTR (v_filebuffer, '|', 1, 83)
                            )
                    );

            IF v_length_check IS NOT NULL
            THEN
               IF LENGTH (v_length_check) > 1
               THEN
                  v_errmsg :=
                     v_errmsg || '--' || 'Preauth Transaction Flag lenght is invalid';
               --RAISE exp_loop_reject_record;
               ELSE
                  v_transaction_flag := v_length_check;
               END IF;

               IF REGEXP_LIKE (v_length_check, '[0-9]')
               THEN
                  v_errmsg :=
                        v_errmsg
                     || '-- '
                     || 'Invalid value for Preauth Transaction Flag '
                     || v_length_check;
               END IF;
            END IF;
         EXCEPTION
            WHEN OTHERS
            THEN
               v_sqlerr :=
                     v_sqlerr
                  || '-- '
                  || 'Data validation failed for field no '
                  || v_error_flag
                  || ' with tech error '
                  || SUBSTR (SQLERRM, 1, 100);
         END;

        */       --Commented as per discussion 02-Aug-2013

        v_error_flag := 129;

         BEGIN
            v_length_check :=
               TRIM (SUBSTR (v_filebuffer,
                             INSTR (v_filebuffer, '|', 1, 84) + 1,
                               (INSTR (v_filebuffer, '|', 1, 85) - 1
                               )
                             - INSTR (v_filebuffer, '|', 1, 84)
                            )
                    );

            IF v_length_check IS NULL and v_dispute_flag = 1
            THEN
               v_errmsg :=
                  v_errmsg || '-- ' || 'Original Delivery Channel is NULL For Dispute Txn';
            --RAISE exp_loop_reject_record;
            ELSE
               IF LENGTH (v_length_check) > 2
               THEN
                  v_errmsg :=
                        v_errmsg
                     || '-- '
                     || 'Original Delivery Channel length is invalid';
               ELSE
                  /*-----Original Delivery Channel -------*/
                  v_orgnl_delv_chnl := v_length_check;
               /*-----Original Delivery Channel -------*/
               END IF;

               IF REGEXP_LIKE (v_length_check, '[A-Z,a-z]')
               THEN
                  v_errmsg :=
                        v_errmsg
                     || '-- '
                     || 'Invalid value for Original deliery channel '
                     || v_length_check;
               END IF;
            END IF;
         EXCEPTION
            WHEN OTHERS
            THEN
               v_sqlerr :=
                     v_sqlerr
                  || '-- '
                  || 'Data validation failed for field no '
                  || v_error_flag
                  || ' with tech error '
                  || SUBSTR (SQLERRM, 1, 100);
         END;


         v_error_flag := 130;

         BEGIN
            v_length_check :=
               TRIM (SUBSTR (v_filebuffer,
                             INSTR (v_filebuffer, '|', 1, 85) + 1,
                               (INSTR (v_filebuffer, '|', 1, 86) - 1
                               )
                             - INSTR (v_filebuffer, '|', 1, 85)
                            )
                    );

            IF v_length_check IS NULL and v_dispute_flag = 1
            THEN
               v_errmsg := v_errmsg || '-- ' || 'Original Transaction Code is NULL For Dispute Txn';
            --RAISE exp_loop_reject_record;
            ELSE
               IF LENGTH (v_length_check) > 2
               THEN
                  v_errmsg :=
                     v_errmsg || '-- '
                     || 'Original Transaction Code length is invalid';
               ELSE
                  /*-----Original Transaction code -------*/
                  v_orgnl_tran_code := v_length_check;
               /*-----Original Transaction code -------*/
               END IF;
            END IF;
         EXCEPTION
            WHEN OTHERS
            THEN
               v_errmsg :=
                     v_errmsg || '--' || 'Original Transaction Code validation failed';
               v_sqlerr :=
                     v_sqlerr
                  || '-- '
                  || 'Data validation failed for field no '
                  || v_error_flag
                  || ' with tech error '
                  || SUBSTR (SQLERRM, 1, 100);
         END;


         v_error_flag := 131;

         BEGIN
            v_length_check :=
               TRIM (SUBSTR (v_filebuffer,
                             INSTR (v_filebuffer, '|', 1, 86) + 1,
                               (INSTR (v_filebuffer, '|', 1, 87) - 1
                               )
                             - INSTR (v_filebuffer, '|', 1, 86)
                            )
                    );

            IF v_length_check IS NULL
            THEN
               v_errmsg :=
                        v_errmsg || '-- ' || 'Transaction Reversal Fee Amount is NULL';
            --RAISE exp_loop_reject_record;
            ELSE
               IF LENGTH (v_length_check) > 7
               THEN
                  v_errmsg :=
                       v_errmsg || '--' || 'Reversal Fee Amount length is invalid';
               ELSE
                  /*----- reversal Fee Amount -------*/
                  v_reverse_fee_amt := v_length_check;
               /*----- reversal Fee Amount -------*/
               END IF;

               BEGIN
                  v_chk_amt := TO_NUMBER (v_length_check);
               EXCEPTION
                  WHEN OTHERS
                  THEN
                     v_errmsg :=
                           v_errmsg
                        || '-- '
                        || 'Invalid amount value for reversal fee amount '
                        || v_length_check;
               END;

               BEGIN
                  v_chk_amt :=
                            TO_NUMBER (v_length_check, 999999999999999999.99);
               EXCEPTION
                  WHEN OTHERS
                  THEN
                     v_errmsg :=
                           v_errmsg
                        || '-- '
                        || 'reversal fee amount precision exceeded';
               END;
            END IF;
         EXCEPTION
            WHEN OTHERS
            THEN
               v_errmsg :=
                       v_errmsg || '--' || 'reversal fee amount validation failed';
               v_sqlerr :=
                     v_sqlerr
                  || '-- '
                  || 'Data validation failed for field no '
                  || v_error_flag
                  || ' with tech error '
                  || SUBSTR (SQLERRM, 1, 100);
         END;

-------Dhiraj Gaikwad -------
       v_error_flag := 142;

         BEGIN
            v_length_check :=
               TRIM (SUBSTR (v_filebuffer,
                             INSTR (v_filebuffer, '|', 1, 87) + 1,
                               (INSTR (v_filebuffer, '|', 1, 88) - 1
                               )
                             - INSTR (v_filebuffer, '|', 1, 87)
                            )
                    );

            IF v_length_check IS NULL
            THEN
               v_errmsg :=
                        v_errmsg || '-- ' || 'Transaction Time Stamp is NULL';
            --RAISE exp_loop_reject_record;
            ELSE
               IF LENGTH (v_length_check) > 19
               THEN
                  v_errmsg :=
                       v_errmsg || '--' || '  Transaction Time Stamp length is invalid';
               ELSE
                  /*-----  Transaction Time Stamp -------*/
                  v_timestamp := v_length_check;
               /*----- Transaction Time Stamp ------*/
               END IF;

               BEGIN
                  v_chk_num := TO_NUMBER (v_length_check);
               EXCEPTION
                  WHEN OTHERS
                  THEN
                     v_errmsg :=
                           v_errmsg
                        || '-- '
                        || 'Invalid value for Transaction Time Stamp should have numbers only'
                        || v_length_check;
               END;

                 BEGIN
                  v_chk_timestamp := to_timestamp (v_length_check,'YYYYMMDDHH24MISSFF5');
               EXCEPTION
                  WHEN OTHERS
                  THEN
                     v_errmsg :=
                           v_errmsg
                        || '-- '
                        || 'Invalid value for Transaction Time Stamp '
                        || v_length_check;
               END;

            END IF;
         EXCEPTION
            WHEN OTHERS
            THEN
               v_errmsg :=
                       v_errmsg || '--' || ' Transaction Time Stamp validation failed';
               v_sqlerr :=
                     v_sqlerr
                  || '-- '
                  || 'Data validation failed for field no '
                  || v_error_flag
                  || ' with tech error '
                  || SUBSTR (SQLERRM, 1, 100);
         END;



     v_error_flag := 143;

         BEGIN
            v_length_check :=
               TRIM (SUBSTR (v_filebuffer,
                             INSTR (v_filebuffer, '|', 1, 88) + 1,
                               (INSTR (v_filebuffer, '|', 1, 89) - 1
                               )
                             - INSTR (v_filebuffer, '|', 1, 88)
                            )
                    );

            IF v_length_check IS NOT  NULL
            THEN

               IF LENGTH (v_length_check) >40
               THEN
                  v_errmsg :=
                       v_errmsg || '--' || '  Mobile Number length is invalid';
               ELSE
                  /*-----  Mobile Number -------*/
                  v_mobile_number := v_length_check;
         /*-----  Mobile Number -------*/
               END IF;

               BEGIN
                  v_chk_num := TO_NUMBER (v_length_check);
               EXCEPTION
                  WHEN OTHERS
                  THEN
                     v_errmsg :=
                           v_errmsg
                        || '-- '
                        || 'Invalid value for Mobile Number '
                        || v_length_check;
               END;


            END IF;
         EXCEPTION
            WHEN OTHERS
            THEN
               v_errmsg :=
                       v_errmsg || '--' || ' Mobile Number validation failed';
               v_sqlerr :=
                     v_sqlerr
                  || '-- '
                  || 'Data validation failed for field no '
                  || v_error_flag
                  || ' with tech error '
                  || SUBSTR (SQLERRM, 1, 100);
         END;


        v_error_flag := 144;

         BEGIN
            v_length_check :=
               TRIM (SUBSTR (v_filebuffer,
                             INSTR (v_filebuffer, '|', 1, 89) + 1,
                               (INSTR (v_filebuffer, '|', 1,90) - 1
                               )
                             - INSTR (v_filebuffer, '|', 1, 89)
                            )
                    );

            IF v_length_check IS NOT  NULL
            THEN

               IF LENGTH (v_length_check) >40
               THEN
                  v_errmsg :=
                       v_errmsg || '--' || '  Device ID  length is invalid';
               ELSE
                  /*-----  Device ID -------*/
                  v_device_id := v_length_check;
               /*-----  Device ID -------*/
               END IF;

               BEGIN
                  v_chk_num := TO_NUMBER (v_length_check);
               EXCEPTION
                  WHEN OTHERS
                  THEN
                     v_errmsg :=
                           v_errmsg
                        || '-- '
                        || 'Invalid value for  Device ID  '
                        || v_length_check;
               END;


            END IF;
         EXCEPTION
            WHEN OTHERS
            THEN
               v_errmsg :=
                       v_errmsg || '--' || '  Device ID  validation failed';
               v_sqlerr :=
                     v_sqlerr
                  || '-- '
                  || 'Data validation failed for field no '
                  || v_error_flag
                  || ' with tech error '
                  || SUBSTR (SQLERRM, 1, 100);
         END;

  /*       IF     v_delivery_channel = '13'
         THEN
          v_error_flag := 145;

            IF v_mobile_number IS NULL
            THEN
               v_errmsg :=
                     v_errmsg
                  || '--'
                  || 'Mobile Number is null for Mobile transaction';
            --RAISE exp_loop_reject_record;
            END IF;

              v_error_flag := 146;

            IF v_device_id IS NULL
            THEN
               v_errmsg :=
                     v_errmsg
                  || '--'
                  || ' Device ID is null for Mobile transaction';
            --RAISE exp_loop_reject_record;
            END IF;

       END IF  ;
*/
       BEGIN
            v_error_flag := 147;
            v_length_check :=
               TRIM (SUBSTR (v_filebuffer,
                             INSTR (v_filebuffer, '|', 1, 90) + 1,
                               (INSTR (v_filebuffer, '|', 1, 91) - 1
                               )
                             - INSTR (v_filebuffer, '|', 1, 90)
                            )
                    );

            IF v_length_check IS NOT NULL AND LENGTH (v_length_check) > 15
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
                       v_errmsg || '--' || ' Customer Username validation failed';
               v_sqlerr :=
                     v_sqlerr
                  || '-- '
                  || 'Data validation failed for field no '
                  || v_error_flag
                  || ' with tech error '
                  || SUBSTR (SQLERRM, 1, 100);
         END;

	   /*   IF (( v_delivery_channel  = '06'  and  v_transaction_code = '04'   )
            OR ( v_delivery_channel = '13'  and  v_transaction_code = '01'   )
			OR ( v_delivery_channel = '13'  and  v_transaction_code = '08'   )
			OR ( v_delivery_channel = '13'  and  v_transaction_code = '09'   )
			OR ( v_delivery_channel = '13'  and  v_transaction_code = '10'   )
			OR ( v_delivery_channel = '10'  and  v_transaction_code = '23'   )
			OR ( v_delivery_channel = '10'  and  v_transaction_code = '24'   )
			OR ( v_delivery_channel = '10'  and  v_transaction_code = '27'   )
			OR ( v_delivery_channel = '10'  and  v_transaction_code = '28'   )
			OR ( v_delivery_channel = '10'  and  v_transaction_code = '29'   )
			OR ( v_delivery_channel = '10'  and  v_transaction_code = '30'   )
			OR ( v_delivery_channel = '10'  and  v_transaction_code = '37'   ))
         THEN
          v_error_flag := 148;
            IF v_customer_username IS NULL
            THEN
               v_errmsg :=
                     v_errmsg
                  || '--'
                  || ' Customer Username is Null For Transaction';
            --RAISE exp_loop_reject_record;
            END IF;
		 END IF ;
		*/
		  v_error_flag := 149;

         BEGIN
            v_length_check :=
               TRIM (SUBSTR (v_filebuffer,
                             INSTR (v_filebuffer, '|', 1, 91) + 1,
                               (INSTR (v_filebuffer, '|', 1, 92) - 1
                               )
                             - INSTR (v_filebuffer, '|', 1, 91)
                            )
                    );

            IF v_length_check IS NOT  NULL
            THEN

               IF LENGTH (v_length_check) >50
               THEN
                  v_errmsg :=
                       v_errmsg || '--' || ' Target Store Address One length is invalid';
               ELSE
                  /*-----  Target Store Address One -------*/
                  v_store_address1 := v_length_check;
         /*-----  Target Store Address One -------*/
               END IF;

            END IF;
         EXCEPTION
            WHEN OTHERS
            THEN
               v_errmsg :=
                       v_errmsg || '--' || ' Target Store Address One validation failed';
               v_sqlerr :=
                     v_sqlerr
                  || '-- '
                  || 'Data validation failed for field no '
                  || v_error_flag
                  || ' with tech error '
                  || SUBSTR (SQLERRM, 1, 100);
         END;
	 v_error_flag := 150;

         BEGIN
            v_length_check :=
               TRIM (SUBSTR (v_filebuffer,
                             INSTR (v_filebuffer, '|', 1, 92) + 1,
                               (INSTR (v_filebuffer, '|', 1, 93) - 1
                               )
                             - INSTR (v_filebuffer, '|', 1, 92)
                            )
                    );

            IF v_length_check IS NOT  NULL
            THEN

               IF LENGTH (v_length_check) >50
               THEN
                  v_errmsg :=
                       v_errmsg || '--' || ' Target Store Address two length is invalid';
               ELSE
                  /*----- Target Store Address Two-------*/
                  v_store_address2 := v_length_check;
         /*-----  Target Store Address Two -------*/
               END IF;

            END IF;
         EXCEPTION
            WHEN OTHERS
            THEN
               v_errmsg :=
                       v_errmsg || '--' || ' Target Store Address two validation failed';
               v_sqlerr :=
                     v_sqlerr
                  || '-- '
                  || 'Data validation failed for field no '
                  || v_error_flag
                  || ' with tech error '
                  || SUBSTR (SQLERRM, 1, 100);
         END;
 v_error_flag := 151;

         BEGIN
            v_length_check :=
               TRIM (SUBSTR (v_filebuffer,
                             INSTR (v_filebuffer, '|', 1, 93) + 1,
                               (INSTR (v_filebuffer, '|', 1, 94) - 1
                               )
                             - INSTR (v_filebuffer, '|', 1, 93)
                            )
                    );

            IF v_length_check IS NOT  NULL
            THEN

               IF LENGTH (v_length_check) >40
               THEN
                  v_errmsg :=
                       v_errmsg || '--' || ' Target Store City length is invalid';
               ELSE
                  /*-----  Target Store City -------*/
                  v_store_city := v_length_check;
         /*-----  Target Store City-------*/
               END IF;

            END IF;
         EXCEPTION
            WHEN OTHERS
            THEN
               v_errmsg :=
                       v_errmsg || '--' || ' Target Store City validation failed';
               v_sqlerr :=
                     v_sqlerr
                  || '-- '
                  || 'Data validation failed for field no '
                  || v_error_flag
                  || ' with tech error '
                  || SUBSTR (SQLERRM, 1, 100);
         END;

v_error_flag := 152;

         BEGIN
            v_length_check :=
               TRIM (SUBSTR (v_filebuffer,
                             INSTR (v_filebuffer, '|', 1, 94) + 1,
                               (INSTR (v_filebuffer, '|', 1, 95) - 1
                               )
                             - INSTR (v_filebuffer, '|', 1, 94)
                            )
                    );

            IF v_length_check IS NOT  NULL
            THEN

               IF LENGTH (v_length_check) >3
               THEN
                  v_errmsg :=
                       v_errmsg || '--' || ' Target Store State length is invalid';
               ELSE
                  /*----- Target Store State-------*/
                  v_store_state := v_length_check;
         /*-----  Target Store State -------*/
               END IF;

            END IF;
         EXCEPTION
            WHEN OTHERS
            THEN
               v_errmsg :=
                       v_errmsg || '--' || ' Target Store State validation failed';
               v_sqlerr :=
                     v_sqlerr
                  || '-- '
                  || 'Data validation failed for field no '
                  || v_error_flag
                  || ' with tech error '
                  || SUBSTR (SQLERRM, 1, 100);
         END;

		 v_error_flag := 153;

         BEGIN
            v_length_check :=
               TRIM (SUBSTR (v_filebuffer,
                             INSTR (v_filebuffer, '|', 1, 95) + 1,
                               (INSTR (v_filebuffer, '|', 1, 96) - 1
                               )
                             - INSTR (v_filebuffer, '|', 1, 95)
                            )
                    );

            IF v_length_check IS NOT  NULL
            THEN

               IF LENGTH (v_length_check) >15
               THEN
                  v_errmsg :=
                       v_errmsg || '--' || ' Target Store ZipCode length is invalid';
               ELSE
                  /*-----  Target Store ZipCode -------*/
                  v_store_zip := v_length_check;
                /*----- Target Store ZipCode -------*/
               END IF;

            END IF;
         EXCEPTION
            WHEN OTHERS
            THEN
               v_errmsg :=
                       v_errmsg || '--' || ' Target Store ZipCode validation failed';
               v_sqlerr :=
                     v_sqlerr
                  || '-- '
                  || 'Data validation failed for field no '
                  || v_error_flag
                  || ' with tech error '
                  || SUBSTR (SQLERRM, 1, 100);
         END;


		 v_error_flag := 154;

         BEGIN
            v_length_check :=
               TRIM (SUBSTR (v_filebuffer,
                             INSTR (v_filebuffer, '|', 1, 96) + 1,
                               (INSTR (v_filebuffer, '|', 1, 97) - 1
                               )
                             - INSTR (v_filebuffer, '|', 1, 96)
                            )
                    );

            IF v_length_check IS NOT  NULL
            THEN

               IF LENGTH (v_length_check) >1
               THEN
                  v_errmsg :=
                       v_errmsg || '--' || ' Target Optn Phone2 Indicator length is invalid';
               ELSE
                  /*-----  Target Optn Phone2 Indicator -------*/
                  v_optn_phno2 := v_length_check;
                /*----- Target Optn Phone2 Indicator -------*/
               END IF;

            END IF;
         EXCEPTION
            WHEN OTHERS
            THEN
               v_errmsg :=
                       v_errmsg || '--' || ' Target Optn Phone2 validation failed';
               v_sqlerr :=
                     v_sqlerr
                  || '-- '
                  || 'Data validation failed for field no '
                  || v_error_flag
                  || ' with tech error '
                  || SUBSTR (SQLERRM, 1, 100);
         END;
       v_error_flag := 155;

         BEGIN
            v_length_check :=
               TRIM (SUBSTR (v_filebuffer,
                             INSTR (v_filebuffer, '|', 1, 97) + 1,
                               (INSTR (v_filebuffer, '|', 1, 98) - 1
                               )
                             - INSTR (v_filebuffer, '|', 1, 97)
                            )
                    );

            IF v_length_check IS NOT  NULL
            THEN

               IF LENGTH (v_length_check) >30
               THEN
                  v_errmsg :=
                       v_errmsg || '--' || ' Target Customer Email length is invalid';
               ELSE
                  /*----- Target Customer Email -------*/
                  v_email := v_length_check;
                /*-----  Target Customer Email -------*/
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
                     || 'Target Customer Email ID does not contain @ character ';
               END IF;

            END IF;
         EXCEPTION
            WHEN OTHERS
            THEN
               v_errmsg :=
                       v_errmsg || '--' || ' Target Customer Email validation failed';
               v_sqlerr :=
                     v_sqlerr
                  || '-- '
                  || 'Data validation failed for field no '
                  || v_error_flag
                  || ' with tech error '
                  || SUBSTR (SQLERRM, 1, 100);
         END;

		  v_error_flag := 156;

         BEGIN
            v_length_check :=
               TRIM (SUBSTR (v_filebuffer,
                             INSTR (v_filebuffer, '|', 1, 98) + 1,
                               (INSTR (v_filebuffer, '|', 1, 99) - 1
                               )
                             - INSTR (v_filebuffer, '|', 1, 98)
                            )
                    );

            IF v_length_check IS NOT  NULL
            THEN

               IF LENGTH (v_length_check) >1
               THEN
                  v_errmsg :=
                       v_errmsg || '--' || ' Target Optn Email Indicator length is invalid';
               ELSE
                  /*----- Target Optn Email Indicator -------*/
                  v_email := v_length_check;
                /*-----  Target Optn Email Indicator -------*/
               END IF;
	        END IF;
         EXCEPTION
            WHEN OTHERS
            THEN
               v_errmsg :=
                       v_errmsg || '--' || ' Target Optn Email Indicator validation failed';
               v_sqlerr :=
                     v_sqlerr
                  || '-- '
                  || 'Data validation failed for field no '
                  || v_error_flag
                  || ' with tech error '
                  || SUBSTR (SQLERRM, 1, 100);
         END;
                /*
                IF v_transaction_code = '30' AND v_delivery_channel = '08'
                   THEN
                      v_error_flag := 157;

                      IF v_store_address1 IS NULL
                      THEN
                         v_errmsg :=
                            v_errmsg || '--'
                            || 'Store Address One is null for SPIL TARGET REGISTRATION transaction';
                      END IF;

                      v_error_flag := 158;

                      IF v_store_address2 IS NULL
                      THEN
                         v_errmsg :=
                            v_errmsg || '--'
                            || 'Store Address Two is null for SPIL TARGET REGISTRATION transaction';
                      END IF;

                      v_error_flag := 159;

                      IF v_store_city IS NULL
                      THEN
                         v_errmsg :=
                               v_errmsg
                            || '--'
                            || 'Store City is null for SPIL TARGET REGISTRATION transaction';
                      END IF;

                      v_error_flag := 160;

                      IF v_store_state IS NULL
                      THEN
                         v_errmsg :=
                               v_errmsg
                            || '--'
                            || 'Store State is null for SPIL TARGET REGISTRATION transaction';
                      END IF;

                      v_error_flag := 161;

                      IF v_store_zip IS NULL
                      THEN
                         v_errmsg :=
                            v_errmsg || '--'
                            || 'Store ZipCode is null for SPIL TARGET REGISTRATION transaction';
                      END IF;

                      v_error_flag := 162;

                      IF v_optn_phno2 IS NULL
                      THEN
                         v_errmsg :=
                            v_errmsg || '--'
                            || 'Optn Phone2 Indicator is null for SPIL TARGET REGISTRATION transaction';
                      END IF;

                      v_error_flag := 163;

                      IF v_email IS NULL
                      THEN
                         v_errmsg :=
                               v_errmsg
                            || '--'
                            || 'Email is null for SPIL TARGET REGISTRATION transaction';
                      END IF;

                      v_error_flag := 164;

                      IF v_optn_email IS NULL
                      THEN
                         v_errmsg :=
                            v_errmsg || '--'
                            || 'Optn Email Indicator is null for SPIL TARGET REGISTRATION transaction';
                      END IF;
                   END IF;
                */
	  v_error_flag := 165;

         BEGIN
            v_length_check :=
               TRIM (SUBSTR (v_filebuffer,
                             INSTR (v_filebuffer, '|', 1, 99) + 1,
                               (INSTR (v_filebuffer, '|', 1, 100) - 1
                               )
                             - INSTR (v_filebuffer, '|', 1, 99)
                            )
                    );

            IF v_length_check IS NOT  NULL
            THEN

               IF LENGTH (v_length_check) >6
               THEN
                  v_errmsg :=
                       v_errmsg || '--' || ' MMPOS TaxPrepare ID length is invalid';
               ELSE
                  /*----- MMPOS TaxPrepare ID -------*/
                  V_TAXPREPARE_ID := v_length_check;
                /*-----  MMPOS TaxPrepare ID -------*/
               END IF;
            END IF;
         EXCEPTION
            WHEN OTHERS
            THEN
               v_errmsg :=
                       v_errmsg || '--' || ' MMPOS TaxPrepare ID validation failed';
               v_sqlerr :=
                     v_sqlerr
                  || '-- '
                  || 'Data validation failed for field no '
                  || v_error_flag
                  || ' with tech error '
                  || SUBSTR (SQLERRM, 1, 100);
         END;


         v_error_flag := 166;

         BEGIN
            v_length_check :=
               TRIM (SUBSTR (v_filebuffer,
                             INSTR (v_filebuffer, '|', 1, 100) + 1,
                               (INSTR (v_filebuffer, '|', 1, 101) - 1
                               )
                             - INSTR (v_filebuffer, '|', 1, 100)
                            )
                    );

            IF v_length_check IS NOT  NULL
            THEN

               IF LENGTH (v_length_check) >6
               THEN
                  v_errmsg :=
                       v_errmsg || '--' || ' MMPOS Reason Code length is invalid';
               ELSE
                  /*----- MMPOS Reason Code -------*/
                   V_MMPOSREASON_CODE:= v_length_check;
                /*-----  MMPOS Reason Code -------*/
               END IF;
            END IF;
         EXCEPTION
            WHEN OTHERS
            THEN
               v_errmsg :=
                       v_errmsg || '--' || ' MMPOS Reason Code validation failed';
               v_sqlerr :=
                     v_sqlerr
                  || '-- '
                  || 'Data validation failed for field no '
                  || v_error_flag
                  || ' with tech error '
                  || SUBSTR (SQLERRM, 1, 100);
         END;


        v_error_flag := 167;

         BEGIN
            v_length_check :=
               TRIM (SUBSTR (v_filebuffer,
                             INSTR (v_filebuffer, '|', 1, 101) + 1,
                               (INSTR (v_filebuffer, '|', 1, 102) - 1
                               )
                             - INSTR (v_filebuffer, '|', 1, 101)
                            )
                    );

            IF v_length_check IS NOT  NULL
            THEN

               IF LENGTH (v_length_check) >1
               THEN
                  v_errmsg :=
                       v_errmsg || '--' || ' MMPOS Alert Optn Indicator length is invalid';
               ELSE
                  /*----- MMPOS Alert Optn Indicator -------*/
                  V_MMPOS_ALERT_OPTIN := v_length_check;
                /*-----  MMPOS Alert Optn Indicator -------*/
               END IF;
            END IF;
         EXCEPTION
            WHEN OTHERS
            THEN
               v_errmsg :=
                       v_errmsg || '--' || ' MMPOS Alert Optn Indicator validation failed';
               v_sqlerr :=
                     v_sqlerr
                  || '-- '
                  || 'Data validation failed for field no '
                  || v_error_flag
                  || ' with tech error '
                  || SUBSTR (SQLERRM, 1, 100);
         END;

                    /*  IF v_transaction_code = '68' AND v_delivery_channel = '04'
                       THEN
                          v_error_flag := 168;

                          IF V_MMPOS_ALERT_OPTIN IS NULL
                          THEN
                             v_errmsg :=
                                v_errmsg || '--'
                                || 'MMPOS Alert Optn Indicator  is null for Activation Transaction';
                          END IF;

                          v_error_flag := 169;

                          IF V_TAXPREPARE_ID IS NULL
                          THEN
                             v_errmsg :=
                                   v_errmsg
                                || '--'
                                || ' MMPOS TaxPrepare ID  is null for Activation Transaction';
                          END IF;

                          v_error_flag := 170;

                          IF V_MMPOSREASON_CODE IS NULL
                          THEN
                             v_errmsg :=
                                   v_errmsg
                                || '--'
                                || ' MMPOS Reason Code  is null for Activation Transaction';
                          END IF;


                       END IF;


                       IF (   (v_transaction_code = '80' AND v_delivery_channel = '04')
                           OR (v_transaction_code = '82' AND v_delivery_channel = '04')
                           OR (v_transaction_code = '88' AND v_delivery_channel = '04')
                           OR (v_transaction_code = '85' AND v_delivery_channel = '04'))
                       THEN
                          v_error_flag := 171;

                          IF V_MMPOSREASON_CODE IS NULL
                          THEN
                             v_errmsg :=
                                   v_errmsg
                                || '--'
                                || ' MMPOS Reason Code  is null for TOPUP Transaction';
                          END IF;
                       END IF;
                    */
	 v_error_flag := 172;

         BEGIN
            v_length_check :=
               TRIM (SUBSTR (v_filebuffer,
                             INSTR (v_filebuffer, '|', 1, 102) + 1,
                               (INSTR (v_filebuffer, '|', 1, 103) - 1
                               )
                             - INSTR (v_filebuffer, '|', 1, 102)
                            )
                    );

            IF v_length_check IS NOT  NULL
            THEN

               IF LENGTH (v_length_check) >7
               THEN
                  v_errmsg :=
                       v_errmsg || '--' || ' Preauth Adjustment Transaction Request Response Code length is invalid';
               ELSE
                  /*----- Preauth Adjustment Transaction Request Response Code -------*/
                  V_REQ_RESP_CODE := v_length_check;
                /*-----  Preauth Adjustment Transaction Request Response Code -------*/
               END IF;
	        END IF;
         EXCEPTION
            WHEN OTHERS
            THEN
               v_errmsg :=
                       v_errmsg || '--' || ' Preauth Adjustment Transaction Request Response Code validation failed';
               v_sqlerr :=
                     v_sqlerr
                  || '-- '
                  || 'Data validation failed for field no '
                  || v_error_flag
                  || ' with tech error '
                  || SUBSTR (SQLERRM, 1, 100);
         END;

  v_error_flag := 173;

         BEGIN
            v_length_check :=
               TRIM (SUBSTR (v_filebuffer,
                             INSTR (v_filebuffer, '|', 1, 103) + 1,
                               (INSTR (v_filebuffer, '|', 1, 104) - 1
                               )
                             - INSTR (v_filebuffer, '|', 1, 103)
                            )
                    );

            IF v_length_check IS NOT  NULL
            THEN

               IF LENGTH (v_length_check) >4
               THEN
                  v_errmsg :=
                       v_errmsg || '--' || ' Preauth Transaction Country Code length is invalid';
               ELSE
                  /*----- Preauth Transaction Country Code -------*/
                  V_COUNTRY_CODE := v_length_check;
                /*-----  Preauth Transaction Country Code -------*/
               END IF;
	        END IF;
         EXCEPTION
            WHEN OTHERS
            THEN
               v_errmsg :=
                       v_errmsg || '--' || ' Preauth Transaction Country Code validation failed';
               v_sqlerr :=
                     v_sqlerr
                  || '-- '
                  || 'Data validation failed for field no '
                  || v_error_flag
                  || ' with tech error '
                  || SUBSTR (SQLERRM, 1, 100);
         END;




 /* IF v_transaction_code='24' AND v_delivery_channel = '02' THEN
       v_error_flag := 174;
      IF V_REQ_RESP_CODE IS NULL
      THEN
         v_errmsg :=
            v_errmsg || '--'
            || ' Request Response Code is null for Preauth Adjustment Transaction';
      END IF;
	 v_error_flag := 175;
	  IF V_COUNTRY_CODE IS NULL
      THEN
         v_errmsg :=
            v_errmsg || '--'
            || ' Country Code is null for Preauth Adjustment Transaction';
      END IF;

   END IF ;
*/
	    v_error_flag := 176;

         BEGIN
            v_length_check :=
               TRIM (SUBSTR (v_filebuffer,
                             INSTR (v_filebuffer, '|', 1, 104) + 1,
                               (INSTR (v_filebuffer, '|', 1, 105) - 1
                               )
                             - INSTR (v_filebuffer, '|', 1, 104)
                            )
                    );

            IF v_length_check IS NOT  NULL
            THEN

               IF LENGTH (v_length_check) >64
               THEN
                  v_errmsg :=
                       v_errmsg || '--' || ' Store ID length is invalid';
               ELSE
                  /*----- Store ID -------*/
                  V_STORE_ID := v_length_check;
                /*-----  Store ID -------*/
               END IF;
	        END IF;
         EXCEPTION
            WHEN OTHERS
            THEN
               v_errmsg :=
                       v_errmsg || '--' || ' Store ID validation failed';
               v_sqlerr :=
                     v_sqlerr
                  || '-- '
                  || 'Data validation failed for field no '
                  || v_error_flag
                  || ' with tech error '
                  || SUBSTR (SQLERRM, 1, 100);
         END;

	/*	IF  v_delivery_channel = '08' THEN
       v_error_flag := 177;
      IF V_STORE_ID IS NULL
      THEN
         v_errmsg :=
            v_errmsg || '--'
            || ' Store ID is null for SPIL  Transaction';
      END IF;
		END IF ;
		*/
		 v_error_flag := 178;

         BEGIN
            v_length_check :=
               TRIM (SUBSTR (v_filebuffer,
                             INSTR (v_filebuffer, '|', 1, 105) + 1,
                               (INSTR (v_filebuffer, '|', 1, 106) - 1
                               )
                             - INSTR (v_filebuffer, '|', 1, 105)
                            )
                    );

            IF v_length_check IS NOT  NULL
            THEN

               IF LENGTH (v_length_check) >1
               THEN
                  v_errmsg :=
                       v_errmsg || '--' || ' CVV Verification Type length is invalid';
               ELSE
                  /*----- Store ID -------*/
                  V_CVV_VERIFICATIONTYPE := v_length_check;
                /*-----  Store ID -------*/
               END IF;
	        END IF;
         EXCEPTION
            WHEN OTHERS
            THEN
               v_errmsg :=
                       v_errmsg || '--' || ' CVV Verification Type  validation failed';
               v_sqlerr :=
                     v_sqlerr
                  || '-- '
                  || 'Data validation failed for field no '
                  || v_error_flag
                  || ' with tech error '
                  || SUBSTR (SQLERRM, 1, 100);
         END;


-------------Dhiraj Gaikwad -------

        IF v_dispute_flag = '1'                              -- REVERSE TXNS
         THEN
            v_error_flag := 132;

            IF v_orgnl_cardnumber IS NULL
            THEN
               v_errmsg :=
                     v_errmsg
                  || '--'
                  || 'orignal card number is null for dispute transaction';
            --RAISE exp_loop_reject_record;
            END IF;

            v_error_flag := 133;

            IF v_orgnl_rrn IS NULL
            THEN
               v_errmsg :=
                     v_errmsg
                  || '--'
                  || 'orignal RRN is null for dispute transaction'; --Error message modified by Pankaj S. on 25-Sep-2013
            --RAISE exp_loop_reject_record;
            END IF;

            v_error_flag := 134;

            IF v_orgnl_businessdate IS NULL
            THEN
               v_errmsg :=
                     v_errmsg
                  || '--'
                  || 'orignal business date is null for dispute transaction';
            --RAISE exp_loop_reject_record;
            END IF;

            v_error_flag := 135;

            IF v_orgnl_businesstime IS NULL
            THEN
               v_errmsg :=
                     v_errmsg
                  || '--'
                  || 'orignal business time is null for dispute transaction';
            --RAISE exp_loop_reject_record;
            END IF;

            v_error_flag := 136;

            if v_orgnl_delv_chnl is null
            then

               v_errmsg :=
                     v_errmsg
                  || '--'
                  || 'orignal delivery channel is null for dispute transaction';

            end if;

            v_error_flag := 137;

            if v_orgnl_tran_code is null
            then

               v_errmsg :=
                     v_errmsg
                  || '--'
                  || 'orignal txn code is null for dispute transaction';

            end if;

        END IF;


        IF     v_transaction_code = '11'
            AND v_delivery_channel = '03'                 --PREAUTH COMPLETION
         THEN
            v_error_flag := 138;

            IF v_orgnl_cardnumber IS NULL
            THEN
               v_errmsg :=
                     v_errmsg
                  || '--'
                  || 'orignal card number is null for preauth hold release';
            --RAISE exp_loop_reject_record;
            END IF;

            v_error_flag := 139;

            IF v_orgnl_rrn IS NULL
            THEN
               v_errmsg :=
                     v_errmsg
                  || '--'
                  || 'orignal RRN is null for preauth hold release'; --Error message modified by Pankaj S. on 25-Sep-2013
            --RAISE exp_loop_reject_record;
            END IF;

            v_error_flag := 140;

            IF v_orgnl_businessdate IS NULL
            THEN
               v_errmsg :=
                     v_errmsg
                  || '--'
                  || 'orignal business date is null for preauth hold release';
            --RAISE exp_loop_reject_record;
            END IF;

            v_error_flag := 141;

            IF v_orgnl_businesstime IS NULL
            THEN
               v_errmsg :=
                     v_errmsg
                  || '--'
                  || 'orignal business time is null for preauth hold release';
            --RAISE exp_loop_reject_record;
            END IF;


        END IF;

        -----------------------------------------------------------------------------------------------------------------------------
         IF v_tran_rev_flag = '0'                              -- REVERSE TXNS
         THEN
            v_error_flag := 85;

            IF v_orgnl_cardnumber IS NULL
            THEN
               v_errmsg :=
                     v_errmsg
                  || '--'
                  || 'orignal card number is null for reversal transaction';
            --RAISE exp_loop_reject_record;
            END IF;

            v_error_flag := 86;

            IF v_orgnl_rrn IS NULL
            THEN
               v_errmsg :=
                     v_errmsg
                  || '--'
                  || 'orignal RRN is null for reversal transaction';  --Error message modified by Pankaj S. on 25-Sep-2013
            --RAISE exp_loop_reject_record;
            END IF;

            v_error_flag := 87;

            IF v_orgnl_businessdate IS NULL
            THEN
               v_errmsg :=
                     v_errmsg
                  || '--'
                  || 'orignal business date is null for reversal transaction';
            --RAISE exp_loop_reject_record;
            END IF;

            v_error_flag := 88;

            IF v_orgnl_businesstime IS NULL
            THEN
               v_errmsg :=
                     v_errmsg
                  || '--'
                  || 'orignal business time is null for reversal transaction';
            --RAISE exp_loop_reject_record;
            END IF;

            v_error_flag := 89;

            IF v_orgnl_terminalid IS NULL
            THEN
               v_errmsg :=
                     v_errmsg
                  || '--'
                  || 'orignal terminal is null for reversal transaction';
            --RAISE exp_loop_reject_record;
            END IF;
         END IF;

         IF     v_transaction_code = '12'
            AND v_delivery_channel = '02'                 --PREAUTH COMPLETION
         THEN

            /*                    --Commented on 02-Aug-2013 as per discussion

            v_error_flag := 90;

            IF v_completion_count IS NULL
            THEN
               v_errmsg :=
                     v_errmsg
                  || '--'
                  || 'completion count is null for preauth completion transaction';
            --RAISE exp_loop_reject_record;
            END IF;

           */                       -- Commented on 02-Aug-2013 as per discussion

            v_error_flag := 91;

            IF v_orgnl_cardnumber IS NULL
            THEN
               v_errmsg :=
                     v_errmsg
                  || '--'
                  || 'orignal cardnumber is null for preauth completion transaction';
            --RAISE exp_loop_reject_record;
            END IF;

            v_error_flag := 92;

            IF v_orgnl_rrn IS NULL
            THEN
               v_errmsg :=
                     v_errmsg
                  || '--'
                  || 'orignal RRN is null for preauth completion transaction'; --Error message modified by Pankaj S. on 25-Sep-2013
            --RAISE exp_loop_reject_record;
            END IF;

            v_error_flag := 93;

            --SN:Modified for Galileo changes //To marked match completion Flag as optional
            /*IF v_matchcomp_flag IS NULL
            THEN
               v_errmsg :=
                     v_errmsg
                  || '--'
                  || 'Match Completion flag is null for preauth completion transaction';
            --RAISE exp_loop_reject_record;
            END IF;*/
            --EN:Modified for Galileo changes //To marked match completion Flag as optional
            

            /*                  -- Commented on 02-Aug-2013 as per discussion

            v_error_flag := 94;

            IF v_lastcompletion_ind IS NULL
            THEN
               v_errmsg :=
                     v_errmsg
                  || '--'
                  || 'last completion indicator is null for preauth completion transaction';
            --RAISE exp_loop_reject_record;
            END IF;

            */              -- Commented on 02-Aug-2013 as per discussion

         END IF;

        IF     v_transaction_code = '11'
            AND v_delivery_channel = '02'                       --PREAUTH TXNS
         THEN
         --SN Dhiraj GAikwad
	   /*      v_error_flag := 176;
	  IF V_COUNTRY_CODE IS NULL
      THEN
         v_errmsg :=
            v_errmsg || '--'
            || ' Country Code is null for Preauth  Transaction';
      END IF;
*/
		 --EN Dhiraj GAikwad
           /*                   --Commented on 02-Aug-2013 as per discussion
            v_error_flag := 95;

            IF v_incremental_ind IS NULL
            THEN
               v_errmsg :=
                     v_errmsg
                  || '--'
                  || 'increment indicator is null for preauth transaction';
            --RAISE exp_loop_reject_record;
            END IF;
           */                  --Commented on 02-Aug-2013 as per discussion

           /*
            v_error_flag := 96;

            IF v_merc_floorlimit_ind IS NULL
            THEN
               v_errmsg :=
                     v_errmsg
                  || '--'
                  || 'Merchant floor limit indicator is null for preauth transaction';
            --RAISE exp_loop_reject_record;
            END IF;
           */
            v_error_flag := 97;

            IF v_preauth_expry_date IS NULL
            THEN
               v_errmsg :=
                     v_errmsg
                  || '--'
                  || 'Preauth expiry date is null for preauth transaction';
            --RAISE exp_loop_reject_record;
            END IF;


           /*                   -- Commented on 02-Aug-2013 as per discussion
            v_error_flag := 98;

            IF v_preauth_validflag IS NULL
            THEN
               v_errmsg :=
                     v_errmsg
                  || '--'
                  || 'Preauth valid flag is null for preauth transaction';
            --RAISE exp_loop_reject_record;
            END IF;

            v_error_flag := 99;

            IF v_expiry_flag IS NULL
            THEN
               v_errmsg :=
                     v_errmsg
                  || '--'
                  || 'Preauth expiry flag is null for preauth transaction';
            --RAISE exp_loop_reject_record;
            END IF;

            v_error_flag := 100;

            IF v_completion_flag IS NULL
            THEN
               v_errmsg :=
                     v_errmsg
                  || '--'
                  || 'Preauth completion flag is null for preauth transaction';
            --RAISE exp_loop_reject_record;
            END IF;

           */           -- Commented on 02-Aug-2013 as per discussion

            v_error_flag := 101;

            IF v_pend_holdamt IS NULL
            THEN
               v_errmsg :=
                     v_errmsg
                  || '--'
                  || 'Preauth pending hold amount is null for preauth transaction';
            --RAISE exp_loop_reject_record;
            END IF;

            /*           -- Commented on 02-Aug-2013 as per discussion
            v_error_flag := 102;

            IF v_transaction_flag IS NULL
            THEN
               v_errmsg :=
                     v_errmsg
                  || '--'
                  || 'Preauth transaction flag is null for preauth transaction';
            --RAISE exp_loop_reject_record;
            END IF;
           */           -- Commented on 02-Aug-2013 as per discussion

         END IF;

         IF v_transaction_type = 1
         THEN
            v_error_flag := 103;

            IF v_narration IS NULL
            THEN
               v_errmsg :=
                     v_errmsg
                  || '--'
                  || 'narration is null for financial transaction';
            --RAISE exp_loop_reject_record;
            END IF;
         END IF;

         --SN:Modified for Galileo changes //To marked fields as optional
         /*IF v_delivery_channel = '11'                                    --ACH
         THEN
            v_error_flag := 104;

            IF v_ach_filename IS NULL
            THEN
               v_errmsg :=
                     v_errmsg
                  || '--'
                  || 'Ach filename is null for ACH transaction';
            --RAISE exp_loop_reject_record;
            END IF;

            v_error_flag := 105;

            IF v_return_achfilename IS NULL
            THEN
               v_errmsg :=
                     v_errmsg
                  || '--'
                  || 'Return_ach filename is null for ACH transaction';
            --RAISE exp_loop_reject_record;
            END IF;

            v_error_flag := 106;

            IF v_odfi IS NULL
            THEN
               v_errmsg :=
                       v_errmsg || '--' || 'ODFI is null for ACH transaction';
            --RAISE exp_loop_reject_record;
            END IF;

            v_error_flag := 107;

            IF v_rdfi IS NULL
            THEN
               v_errmsg :=
                       v_errmsg || '--' || 'RDFI is null for ACH transaction';
            --RAISE exp_loop_reject_record;
            END IF;

            v_error_flag := 108;

            IF v_sec_codes IS NULL
            THEN
               v_errmsg :=
                   v_errmsg || '--' || 'sec_code is null for ACH transaction';
            --RAISE exp_loop_reject_record;
            END IF;

            v_error_flag := 109;

            IF v_imp_date IS NULL
            THEN
               v_errmsg :=
                   v_errmsg || '--' || 'IMP DATE is null for ACH transaction';
            --RAISE exp_loop_reject_record;
            END IF;

            v_error_flag := 110;

            IF v_process_date IS NULL
            THEN
               v_errmsg :=
                     v_errmsg
                  || '--'
                  || 'PROCESS_DATE is null for ACH transaction';
            --RAISE exp_loop_reject_record;
            END IF;

            v_error_flag := 111;

            IF v_effective_date IS NULL
            THEN
               v_errmsg :=
                     v_errmsg
                  || '--'
                  || 'EFFECTIVE DATE is null for ACH transaction';
            --RAISE exp_loop_reject_record;
            END IF;

            v_error_flag := 112;

            IF v_ach_transactiontype_id IS NULL
            THEN
               v_errmsg :=
                     v_errmsg
                  || '--'
                  || 'Ach Transactiontype Id is null for ACH transaction';
            --RAISE exp_loop_reject_record;
            END IF;

            v_error_flag := 113;

            IF v_incoming_crfile_id IS NULL
            THEN
               v_errmsg :=
                     v_errmsg
                  || '--'
                  || 'Incoming Crfile Id is null for ACH transaction';
            --RAISE exp_loop_reject_record;
            END IF;

            v_error_flag := 114;

            IF v_ind_idnum IS NULL
            THEN
               v_errmsg :=
                  v_errmsg || '--' || 'Ind Idnum is null for ACH transaction';
            --RAISE exp_loop_reject_record;
            END IF;

            v_error_flag := 115;

            IF v_ind_name IS NULL
            THEN
               v_errmsg :=
                   v_errmsg || '--' || 'Ind Name is null for ACH transaction';
            --RAISE exp_loop_reject_record;
            END IF;

            v_error_flag := 116;

            IF v_ach_id IS NULL
            THEN
               v_errmsg :=
                     v_errmsg || '--' || 'ACH ID is null for ACH transaction';
            --RAISE exp_loop_reject_record;
            END IF;
         END IF; */
         --EN:Modified for Galileo changes //To marked fields as optional

         --SN:Modified for Galileo changes //To marked fields as optional
         /*IF v_delivery_channel IN ('10', '03')                       --CHW/CSR
         THEN
            v_error_flag := 117;

            IF v_ipaddress IS NULL
            THEN
               v_errmsg :=
                     v_errmsg
                  || '--'
                  || 'IPADDRESS is null for CHW/CSR transaction';
            --RAISE exp_loop_reject_record;
            END IF;
         END IF;*/
         --EN:Modified for Galileo changes //To marked fields as optional

         --SN:Modified for Galileo changes //To marked fields as optional
         /*IF v_delivery_channel = '07'                                    --IVR
         THEN
            v_error_flag := 118;

            IF v_ani IS NULL
            THEN
               v_errmsg :=
                        v_errmsg || '--' || 'ANI is null for IVR transaction';
            --RAISE exp_loop_reject_record;
            END IF;

            v_error_flag := 119;

            IF v_dni IS NULL
            THEN
               v_errmsg :=
                        v_errmsg || '--' || 'DNI is null for IVR transaction';
            --RAISE exp_loop_reject_record;
            END IF;
         END IF;*/
         --EN:Modified for Galileo changes //To marked fields as optional

         IF    (v_delivery_channel = '03' AND v_transaction_code = 38)
            OR (v_delivery_channel = '07' AND v_transaction_code = 07)
            OR (v_delivery_channel = '10' AND v_transaction_code = 07
               )                                                 --CSR/CHW/IVR
         THEN

           /*          --Commented as per discussion 02-Aug-2013
            v_error_flag := 120;

            IF v_beftxn_topupcard_ledgerbal IS NULL
            THEN
               v_errmsg :=
                     v_errmsg
                  || '--'
                  || 'Before txn Topupcard ledgerbal is null for C2C transaction';
            --RAISE exp_loop_reject_record;
            END IF;

            v_error_flag := 121;

            IF v_beftxn_topupcard_acctbal IS NULL
            THEN
               v_errmsg :=
                     v_errmsg
                  || '--'
                  || 'Before txn Topupcard acctbal is null for C2C transaction';
            --RAISE exp_loop_reject_record;
            END IF;

            */          --Commented as per discussion 02-Aug-2013

            v_error_flag := 122;

            IF v_topupcard_ledgerbal IS NULL
            THEN
               v_errmsg :=
                     v_errmsg
                  || '--'
                  || 'After txn Topupcard ledger balance is null for C2C transaction';
            --RAISE exp_loop_reject_record;
            END IF;

            v_error_flag := 123;

            IF v_topupcard_acctbal IS NULL
            THEN
               v_errmsg :=
                     v_errmsg
                  || '--'
                  || 'After txn Topupcard acct balance is null for C2C transaction';
            --RAISE exp_loop_reject_record;
            END IF;

            v_error_flag := 124;

            IF     v_delivery_channel = '03'
               AND v_transaction_code = '38'
               AND v_c2ctxn_status IS NULL
            THEN
               v_errmsg :=
                     v_errmsg
                  || '--'
                  || 'Status of card to card transfer transaction is null';
            --RAISE exp_loop_reject_record;
            END IF;

            v_error_flag := 125;

            IF v_beneficiary_card_no IS NULL
            THEN
               v_errmsg :=
                  v_errmsg || '--'
                  || 'Topup card is null for C2C transaction';
            --RAISE exp_loop_reject_record;
            END IF;
         END IF;

         v_error_flag := 126;

         IF v_posted_date IS NULL
         THEN
            v_errmsg :=
                    v_errmsg || '--' || 'Posted date is null for transaction';
         --RAISE exp_loop_reject_record;
         END IF;

         v_error_flag := 127;

         IF     (   (    v_delivery_channel = '07'
                     AND v_transaction_code IN ('10', '11')
                    )
                 OR (    v_delivery_channel = '13'
                     AND v_transaction_code IN ('04', '14')
                    )
                 OR (    v_delivery_channel = '10'
                     AND v_transaction_code IN ('19', '20')
                    )
                )
            AND TRIM (v_topup_acctno) IS NULL
         THEN
            v_errmsg :=
                  v_errmsg
               || '--'
               || 'Topup account is null for savingstospening or spendingtosaving transfer txn';
         --RAISE exp_loop_reject_record;
         END IF;

         --****
         v_error_flag := 128;

         IF v_delivery_channel IN ('01', '02') AND v_international_ind IS NULL
         THEN
            v_errmsg :=
                  v_errmsg
               || '--'
               || 'International indicator is null for ATM/POS delivery channel';
         --RAISE exp_loop_reject_record;
         END IF;



         IF v_errmsg <> 'OK'
         THEN
            RAISE exp_loop_reject_record;
         END IF;

-----------------------------------------------------------------------------------------------------------------------------
         BEGIN
            INSERT INTO migr_transactionlog_temp
                        (mtt_mesg_type, mtt_rrn, mtt_delivery_channel,
                         mtt_terminal_id, mtt_transaction_code,
                         mtt_transaction_type, mtt_transaction_mode,
                         mtt_response_code, mtt_business_date,
                         mtt_business_time, mtt_card_no,
                         mtt_beneficiary_card_no, mtt_total_amount,
                         mtt_merchant_name, mtt_merchant_city, mtt_mcccode,
                         mtt_currency_code, mtt_atm_namelocation,
                         mtt_amount, mtt_preauth_datetime, mtt_stan,
                         mtt_tranfee_amount, mtt_servicetax_amount,
                         mtt_tran_rev_flag, mtt_account_number,
                         mtt_orgnl_cardnumber, mtt_orgnl_rrn,
                         mtt_orgnl_businessdate, mtt_orgnl_businesstime,
                         mtt_orgnl_terminalid, mtt_reversal_code,
                         mtt_proxy_number, mtt_account_balance,
                         mtt_ledger_balance, mtt_ach_filename,
                         mtt_return_achfilename, mtt_odfi, mtt_rdfi,
                         mtt_sec_codes, mtt_imp_date, mtt_process_date,
                         mtt_effective_date, mtt_auth_id,
                         mtt_beforetxn_ledger_bal, mtt_beforetxn_avail_bal,
                         mtt_ach_transactiontype_id, mtt_incoming_crfile_id,
                         mtt_ind_idnum, mtt_ind_name, mtt_ach_id,
                         mtt_ipaddress, mtt_ani, mtt_dni, mtt_card_status,
                         mtt_waiver_amount, mtt_international_ind,
                         mtt_crdr_flag, mtt_incremental_ind,
                         mtt_partialauth_ind, mtt_completion_count,
                         mtt_lastcompletion_ind, mtt_preauth_expryperiod,
                         mtt_merc_floorlimit_ind, mtt_addr_verification_ind,
                         mtt_narration, mtt_dispute_flag, mtt_reasoncode,
                         mtt_remark, mtt_disp_reason, mtt_disp_remark,
                         mtt_file_name, mtt_record_number,
                         mtt_matchcomp_flag, mtt_c2ctxn_status,
                         mtt_posted_date, mtt_beftxn_topupcard_ledgerbal,
                         mtt_topupcard_ledgerbal,
                         mtt_beftxn_topupcard_acctbal,
                         mtt_topupcard_acctbal, mtt_preauth_expry_date,
                         mtt_topup_acctno, mtt_preauth_validflag,
                         mtt_expiry_flag, mtt_completion_flag,
                         mtt_pend_holdamt, mtt_transaction_flag,
                         mtt_migr_seqno,                         --Added on 12-JUL-2013
                         mtt_orgnl_delv_chnl,
                         mtt_orgnl_tran_code,
                         mtt_reverse_fee_amt ,
                         --Added by Dhiraj Gaikwad
                         mtt_time_stamp,mtt_mobile_number,mtt_device_id,
                            MTT_CUSTOMER_USERNAME,      
                            MTT_STORE_ADDRESS1    ,     
                            MTT_STORE_ADDRESS2     ,    
                            MTT_STORE_CITY          ,   
                            MTT_STORE_STATE          ,  
                            MTT_STORE_ZIP             , 
                            MTT_OPTN_PHNO2             ,
                            MTT_EMAIL                  ,
                            MTT_OPTN_EMAIL             ,
                            MTT_TAXPREPARE_ID          ,
                            MTT_REASON_CODE            ,
                            MTT_ALERT_OPTIN            ,
                            MTT_REQ_RESP_CODE           ,  
                            MTT_COUNTRY_CODE            ,
                            MTT_STORE_ID               ,
                            MTT_CVV_VERIFICATIONTYPE   
                         --Added by Dhiraj Gaikwad
                        )
                 VALUES (v_mesg_type, v_rrn, v_delivery_channel,
                         v_terminal_id, v_transaction_code,
                         v_transaction_type, v_transaction_mode,
                         v_response_code, v_business_date,
                         v_business_time, v_card_no,
                         v_beneficiary_card_no, v_total_amount,
                         v_merchant_name, v_merchant_city, v_mcccode,
                         v_currency_code, v_atm_namelocation,
                         v_amount, v_preauth_datetime, v_stan,
                         v_tranfee_amount, v_servicetax_amount,
                         v_tran_rev_flag, v_account_number,
                         v_orgnl_cardnumber, v_orgnl_rrn,
                         v_orgnl_businessdate, v_orgnl_businesstime,
                         v_orgnl_terminalid, v_reversal_code,
                         v_proxy_number, v_account_balance,
                         v_ledger_balance, v_ach_filename,
                         v_return_achfilename, v_odfi, v_rdfi,
                         v_sec_codes, v_imp_date, v_process_date,
                         v_effective_date, v_auth_id,
                         --v_beforetxn_ledger_bal,          --Commented as per discssion 02-Aug-2013
                         '0.00',                            --Added as per discssion 02-Aug-2013
                         --v_beforetxn_avail_bal,           --Commented as per discssion 02-Aug-2013
                         '0.00',                            --Added as per discssion 02-Aug-2013
                         v_ach_transactiontype_id, v_incoming_crfile_id,
                         v_ind_idnum, v_ind_name, v_ach_id,
                         v_ipaddress, v_ani, v_dni, v_card_status,
                         v_waiver_amount, v_international_ind,
                         v_crdr_flag, v_incremental_ind,
                         v_partialauth_ind, v_completion_count,
                         v_lastcompletion_ind, v_preauth_expryperiod,
                         v_merc_floorlimit_ind, v_addr_verification_ind,
                         v_narration, v_dispute_flag, v_reason_code,
                         v_remark, v_dispute_reason, v_dispute_remark,
                         prm_file_name, v_record_numb,
                         v_matchcomp_flag, v_c2ctxn_status,
                         v_posted_date,
                         --v_beftxn_topupcard_ledgerbal,    --Commented as per discssion 02-Aug-2013
                         '0.00',                            --Added as per discssion 02-Aug-2013
                         v_topupcard_ledgerbal,
                         --v_beftxn_topupcard_acctbal,      --Added as per discssion 02-Aug-2013
                         '0.00',                            --Added as per discssion 02-Aug-2013
                         v_topupcard_acctbal, v_preauth_expry_date,
                         v_topup_acctno, v_preauth_validflag,
                         v_expiry_flag, v_completion_flag,
                         v_pend_holdamt, v_transaction_flag,
                         prm_seqno,                         --Added on 12-JUL-2013
                         v_orgnl_delv_chnl,                 --Added on 18-JUL-2013
                         v_orgnl_tran_code,                 --Added on 18-JUL-2013
                         v_reverse_fee_amt  ,                --Added on 18-JUL-2013
                          --Added by Dhiraj Gaikwad
                        to_timestamp( v_timestamp,'YYYYMMDDHH24MISSFF5'),
                        v_mobile_number,
                        v_device_id,
                        V_CUSTOMER_USERNAME,      
                        V_STORE_ADDRESS1    ,     
                        V_STORE_ADDRESS2     ,    
                        V_STORE_CITY          ,   
                        V_STORE_STATE          ,  
                        V_STORE_ZIP             , 
                        V_OPTN_PHNO2             ,
                        V_EMAIL                  ,
                        V_OPTN_EMAIL             ,
                        V_TAXPREPARE_ID          ,
                        V_MMPOSREASON_CODE            ,
                        V_MMPOS_ALERT_OPTIN            ,
                        V_REQ_RESP_CODE           ,  
                        V_COUNTRY_CODE            ,
                        V_STORE_ID               ,
                        V_CVV_VERIFICATIONTYPE   
                            --Added by Dhiraj Gaikwad
                        );
         EXCEPTION
            WHEN OTHERS
            THEN
               v_errmsg :=
                     'Error while inserting into transaction temp table ' --Error message modified by Pankaj S. on 25-Sep-2013
                  || SUBSTR (SQLERRM, 1, 200);
               RAISE exp_loop_reject_record;
         END;

         IF v_errmsg <> 'OK'
         THEN
            RAISE exp_loop_reject_record;
         END IF;

         v_succ_cnt := v_succ_cnt + 1;

         IF MOD (i, 1000) = 0
         THEN                                            --commit 1000 records
            COMMIT;
         END IF;
      EXCEPTION
         WHEN exp_loop_reject_record
         THEN
            SELECT DECODE (SUBSTR (v_errmsg, 1, 2),
                           'OK', SUBSTR (v_errmsg, 5),
                           SUBSTR (v_errmsg, 2)
                          )
              INTO v_errmsg
              FROM DUAL;

            sp_migr_log_excp_txns (prm_file_name,
                                   v_record_numb,
                                   v_card_no,
                                   v_rrn,
                                   v_business_date,
                                   v_business_time,
                                   v_transaction_code,
                                   v_delivery_channel,
                                   v_amount,
                                   'E',
                                   v_errmsg
                                  );
            v_err_cnt := v_err_cnt + 1;
         WHEN OTHERS
         THEN
            v_errmsg :=
                  v_errmsg
               || '-- '
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

            sp_migr_log_excp_txns (prm_file_name,
                                   v_record_numb,
                                   v_card_no,
                                   v_rrn,
                                   v_business_date,
                                   v_business_time,
                                   v_transaction_code,
                                   v_delivery_channel,
                                   v_amount,
                                   'E',
                                   v_errmsg
                                  );
            v_err_cnt := v_err_cnt + 1;
      END;

      BEGIN
         UPDATE migr_ctrl_table
            SET mct_ctrl_numb = mct_ctrl_numb + 1
          WHERE mct_ctrl_key = 'TRANSACTION_DATA' AND mct_inst_code = 1;
      EXCEPTION
         WHEN OTHERS
         THEN
            prm_errmsg :=
                  'Error while updating cotrol number '
               || SUBSTR (SQLERRM, 1, 200);
            RAISE exp_reject_record;
      END;
   END LOOP;

   COMMIT;                                 --Added by Pankaj S. on 11_Jun_2013
   ---En to create records in migration table
   UTL_FILE.fclose (v_file_handle);

   BEGIN
      UPDATE migr_ctrl_table                           --reset control number
         SET mct_ctrl_numb = 1
       WHERE mct_ctrl_key = 'TRANSACTION_DATA' AND mct_inst_code = 1;
   EXCEPTION
      WHEN OTHERS
      THEN
         prm_errmsg :=
            'Error while resetting cotrol number '
            || SUBSTR (SQLERRM, 1, 200);
         RAISE exp_reject_record;
   END;

   --Sn to create log for files
   BEGIN
      sp_migr_file_detl ('TXNLOG_DATA_MIGR',
                         prm_file_name,
                         v_header,
                         n,
                         v_succ_cnt,
                         v_err_cnt,
                         'S',
                         'Successfull'
                        );
   END;
--En to create log for files
EXCEPTION
   WHEN exp_reject_record
   THEN
      -- ROLLBACK;
      sp_migr_file_detl ('TXNLOG_DATA_MIGR',
                         prm_file_name,
                         v_header,
                         n,
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
      prm_errmsg := 'Main exception ' || SUBSTR (SQLERRM, 1, 200);

      IF UTL_FILE.is_open (v_file_handle)
      THEN
         UTL_FILE.fclose (v_file_handle);
      END IF;
END;
/
SHOW ERROR;